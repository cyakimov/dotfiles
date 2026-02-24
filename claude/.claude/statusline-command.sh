#!/usr/bin/env bash
# Claude Code status line script
# Features: project name, model, progress bar, token count, cost, elapsed time

input=$(cat)

# --- Extract fields ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

# --- Project name (basename of project_dir, fallback to cwd) ---
if [ -n "$project_dir" ]; then
  project_name=$(basename "$project_dir")
elif [ -n "$cwd" ]; then
  project_name=$(basename "$cwd")
else
  project_name="unknown"
fi

# --- Model (shorten display) ---
model_short=$(echo "$model" | sed 's/Claude //' | sed 's/ (.*)//')

# --- Progress bar ---
build_bar() {
  local pct="${1:-0}"
  local width=10
  # Round to integer
  local filled=$(printf "%.0f" "$(echo "$pct * $width / 100" | bc -l 2>/dev/null || echo 0)")
  [ "$filled" -gt "$width" ] && filled=$width
  [ "$filled" -lt 0 ] && filled=0
  local empty=$(( width - filled ))
  local bar=""
  local i
  for (( i=0; i<filled; i++ )); do bar="${bar}█"; done
  for (( i=0; i<empty; i++ )); do bar="${bar}░"; done
  echo "$bar"
}

# --- Progress bar color based on used percentage ---
bar_color="32"  # green
if [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
  used_int=$(printf "%.0f" "$used_pct" 2>/dev/null || echo 0)
  if [ "$used_int" -ge 80 ]; then
    bar_color="31"  # red
  elif [ "$used_int" -ge 50 ]; then
    bar_color="33"  # yellow
  fi
  bar=$(build_bar "$used_pct")
  bar_display=$(printf "\033[%sm%s %s%%\033[0m" "$bar_color" "$bar" "$used_int")
else
  bar_display=$(printf "\033[2m%s --%%\033[0m" "$(build_bar 0)")
fi

# --- Token count (combined input+output, human-readable) ---
total_tokens=$(( total_input + total_output ))
if [ "$total_tokens" -ge 1000000 ]; then
  token_str=$(printf "%.1fM" "$(echo "scale=1; $total_tokens / 1000000" | bc -l 2>/dev/null || echo 0)")
elif [ "$total_tokens" -ge 1000 ]; then
  token_str=$(printf "%.1fk" "$(echo "scale=1; $total_tokens / 1000" | bc -l 2>/dev/null || echo 0)")
else
  token_str="${total_tokens}"
fi

# --- Cost estimate (approximate, using Sonnet 4.5 pricing as default) ---
# Input: $3/MTok, Output: $15/MTok (Claude Sonnet pricing)
cost_usd=$(echo "scale=4; ($total_input * 3 + $total_output * 15) / 1000000" | bc -l 2>/dev/null || echo "0")
if [ -n "$cost_usd" ] && [ "$cost_usd" != "0" ]; then
  # Format: show cents if < $1, else dollars
  cost_display=$(printf "\$%.3f" "$cost_usd" 2>/dev/null || echo "\$0.000")
else
  cost_display="\$0.000"
fi

# --- Session elapsed time from transcript ---
elapsed_str=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  # Get creation time of the transcript file as session start proxy
  if stat --version >/dev/null 2>&1; then
    # GNU stat
    start_ts=$(stat -c %Y "$transcript_path" 2>/dev/null || echo "")
  else
    # BSD stat (macOS)
    start_ts=$(stat -f %m "$transcript_path" 2>/dev/null || echo "")
  fi
  if [ -n "$start_ts" ]; then
    now_ts=$(date +%s)
    elapsed_sec=$(( now_ts - start_ts ))
    if [ "$elapsed_sec" -lt 0 ]; then elapsed_sec=0; fi
    elapsed_h=$(( elapsed_sec / 3600 ))
    elapsed_m=$(( (elapsed_sec % 3600) / 60 ))
    elapsed_s=$(( elapsed_sec % 60 ))
    if [ "$elapsed_h" -gt 0 ]; then
      elapsed_str=$(printf "%dh%02dm" "$elapsed_h" "$elapsed_m")
    else
      elapsed_str=$(printf "%dm%02ds" "$elapsed_m" "$elapsed_s")
    fi
  fi
fi

# --- Assemble status line ---
# Project name
part_project=$(printf "\033[1;36m%s\033[0m" "$project_name")

# Model
part_model=$(printf "\033[35m%s\033[0m" "$model_short")

# Progress bar
part_bar="$bar_display"

# Tokens
part_tokens=$(printf "\033[33m%s tok\033[0m" "$token_str")

# Cost
part_cost=$(printf "\033[33m%s\033[0m" "$cost_display")

# Elapsed time
if [ -n "$elapsed_str" ]; then
  part_elapsed=$(printf "\033[2m%s\033[0m" "$elapsed_str")
else
  part_elapsed=""
fi

# Build output
output="${part_project}  ${part_model}  ${part_bar}"
output="${output}  ${part_tokens}"
output="${output}  ${part_cost}"
[ -n "$part_elapsed" ] && output="${output}  ${part_elapsed}"

printf "%s" "$output"
