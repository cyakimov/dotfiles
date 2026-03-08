#!/usr/bin/env bash
# Claude Code status line script
# Design: project · ⎇ branch ● ↑↓ · ◆ model · ▓░ ctx% · ⬡ tokens · ⧗ elapsed · [session]

input=$(cat)

SEP=$(printf "\033[2m · \033[0m")

# --- Extract fields ---
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
model_id=$(echo "$input" | jq -r '.model.id // empty')
session_name=$(echo "$input" | jq -r '.session_name // empty')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

# --- 1. Project name ---
if [ -n "$project_dir" ]; then
  project_name=$(basename "$project_dir")
elif [ -n "$cwd" ]; then
  project_name=$(basename "$cwd")
else
  project_name="claude"
fi
part_project=$(printf "\033[1;36m%s\033[0m" "$project_name")

# --- 2. Git branch + dirty + ahead/behind ---
git_dir="${project_dir:-$cwd}"
part_git=""
if [ -n "$git_dir" ]; then
  branch=$(git -C "$git_dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    # Dirty indicator
    dirty=$(git -C "$git_dir" --no-optional-locks status --porcelain 2>/dev/null)
    if [ -n "$dirty" ]; then
      dirty_dot=$(printf " \033[33m●\033[0m")
    else
      dirty_dot=""
    fi
    # Ahead/behind upstream
    ab=$(git -C "$git_dir" --no-optional-locks rev-list --left-right --count "HEAD...@{upstream}" 2>/dev/null)
    ab_str=""
    if [ -n "$ab" ]; then
      ahead=$(echo "$ab" | awk '{print $1}')
      behind=$(echo "$ab" | awk '{print $2}')
      [ "${ahead:-0}" -gt 0 ] && ab_str="${ab_str}$(printf "\033[32m↑%s\033[0m" "$ahead")"
      [ "${behind:-0}" -gt 0 ] && ab_str="${ab_str}$(printf "\033[33m↓%s\033[0m" "$behind")"
      [ -n "$ab_str" ] && ab_str=" ${ab_str}"
    fi
    part_git=$(printf "⎇ \033[32m%s\033[0m%s%s" "$branch" "$dirty_dot" "$ab_str")
  fi
fi

# --- 3. Model short name ---
# "Claude Opus 4" → "Opus 4", strip parenthetical suffixes
model_short=$(echo "$model" | sed 's/^Claude //' | sed 's/ ([^)]*)//')
# Fallback: derive from model ID if display name is empty
if [ -z "$model_short" ] && [ -n "$model_id" ]; then
  if   echo "$model_id" | grep -qi "opus";   then model_short="Opus"
  elif echo "$model_id" | grep -qi "sonnet"; then model_short="Sonnet"
  elif echo "$model_id" | grep -qi "haiku";  then model_short="Haiku"
  else model_short="$model_id"
  fi
fi
part_model=$(printf "◆ \033[35m%s\033[0m" "$model_short")

# --- 4. Context bar (▓░, 10 wide, color by usage) ---
build_bar() {
  local pct="${1:-0}"
  local width=10
  local filled=$(printf "%.0f" "$(echo "$pct * $width / 100" | bc -l 2>/dev/null || echo 0)")
  [ "$filled" -gt "$width" ] && filled=$width
  [ "$filled" -lt 0 ]        && filled=0
  local empty=$(( width - filled ))
  local bar="" i
  for (( i=0; i<filled; i++ )); do bar="${bar}▓"; done
  for (( i=0; i<empty;  i++ )); do bar="${bar}░"; done
  echo "$bar"
}

if [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
  used_int=$(printf "%.0f" "$used_pct" 2>/dev/null || echo 0)
  if   [ "$used_int" -ge 80 ]; then bar_color="31"   # red
  elif [ "$used_int" -ge 50 ]; then bar_color="33"   # yellow
  else                               bar_color="32"   # green
  fi
  bar=$(build_bar "$used_pct")
  part_bar=$(printf "\033[%sm%s %s%%\033[0m" "$bar_color" "$bar" "$used_int")
else
  part_bar=$(printf "\033[2m%s -%%\033[0m" "$(build_bar 0)")
fi

# --- 5. Token count (cumulative input + output) ---
total_tokens=$(( total_input + total_output ))
if [ "$total_tokens" -ge 1000000 ]; then
  token_str=$(printf "%.1fM" "$(echo "scale=1; $total_tokens / 1000000" | bc -l 2>/dev/null || echo 0)")
elif [ "$total_tokens" -ge 1000 ]; then
  token_str=$(printf "%.1fk" "$(echo "scale=1; $total_tokens / 1000" | bc -l 2>/dev/null || echo 0)")
else
  token_str="$total_tokens"
fi
part_tokens=$(printf "⬡ %s" "$token_str")

# --- 6. Elapsed time (from transcript file mtime as session-start proxy) ---
part_elapsed=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  if stat --version >/dev/null 2>&1; then
    start_ts=$(stat -c %Y "$transcript_path" 2>/dev/null || echo "")  # GNU
  else
    start_ts=$(stat -f %m "$transcript_path" 2>/dev/null || echo "")  # BSD/macOS
  fi
  if [ -n "$start_ts" ]; then
    now_ts=$(date +%s)
    elapsed_sec=$(( now_ts - start_ts ))
    [ "$elapsed_sec" -lt 0 ] && elapsed_sec=0
    elapsed_h=$(( elapsed_sec / 3600 ))
    elapsed_m=$(( (elapsed_sec % 3600) / 60 ))
    elapsed_s=$(( elapsed_sec % 60 ))
    if [ "$elapsed_h" -gt 0 ]; then
      elapsed_fmt=$(printf "%dh%02dm" "$elapsed_h" "$elapsed_m")
    else
      elapsed_fmt=$(printf "%dm%02ds" "$elapsed_m" "$elapsed_s")
    fi
    part_elapsed=$(printf "\033[2m⧗ %s\033[0m" "$elapsed_fmt")
  fi
fi

# --- 7. Session name (only when set via /rename) ---
part_session=""
if [ -n "$session_name" ]; then
  part_session=$(printf "\033[1m[%s]\033[0m" "$session_name")
fi

# --- 8. Vim mode badge (only when vim mode is active) ---
part_vim=""
if [ -n "$vim_mode" ]; then
  if [ "$vim_mode" = "INSERT" ]; then
    part_vim=$(printf "\033[32mI\033[0m")
  else
    part_vim=$(printf "\033[33mN\033[0m")
  fi
fi

# --- Assemble ---
output="${part_project}"
[ -n "$part_git" ]     && output="${output}${SEP}${part_git}"
output="${output}${SEP}${part_model}"
output="${output}${SEP}${part_bar}"
output="${output}${SEP}${part_tokens}"
[ -n "$part_elapsed" ] && output="${output}${SEP}${part_elapsed}"
[ -n "$part_session" ] && output="${output}${SEP}${part_session}"
[ -n "$part_vim" ]     && output="${output}${SEP}${part_vim}"

printf "%s" "$output"
