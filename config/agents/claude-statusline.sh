#!/usr/bin/env bash
# Claude Code status line script
# Layout: project · ⎇ branch ● ↑↓ · PR#N · ◆ model · ✦ effort · ▓░ ctx% · 5h/7d% · ❄ cache · +N/-N · elapsed · ⊞ worktree · [session] · vim

input=$(cat)

SEP=$(printf "\033[2m · \033[0m")
project_dir=""
cwd=""
model=""
model_id=""
session_name=""
used_pct=0
vim_mode=""
duration_ms=0
lines_added=0
lines_removed=0
worktree_name=""
worktree_branch=""
pr_number=""
pr_state=""
pr_kind=""
rl_5h=""
rl_7d=""
cache_warm=""
cache_observed=""
cache_cause=""

# --- Extract all fields in a single jq call ---
eval "$(echo "$input" | jq -r '
  "project_dir=" + (.workspace.project_dir // "" | @sh),
  "cwd=" + (.workspace.current_dir // "" | @sh),
  "model=" + (.model.display_name // "" | @sh),
  "model_id=" + (.model.id // "" | @sh),
  "session_name=" + (.session_name // "" | @sh),
  "used_pct=" + (.context_window.used_percentage // 0 | tostring | @sh),
  "vim_mode=" + (.vim.mode // "" | @sh),
  "duration_ms=" + (.cost.total_duration_ms // 0 | tostring | @sh),
  "lines_added=" + (.cost.total_lines_added // 0 | tostring | @sh),
  "lines_removed=" + (.cost.total_lines_removed // 0 | tostring | @sh),
  "worktree_name=" + (.worktree.name // .workspace.git_worktree // "" | @sh),
  "worktree_branch=" + (.worktree.branch // "" | @sh),
  "pr_number=" + (.pr.number // "" | tostring | @sh),
  "pr_state=" + (.pr.review_state // "open" | @sh),
  "pr_kind=" + (.pr.kind // "" | @sh),
  "rl_5h=" + (.rate_limits.five_hour.used_percentage // "" | tostring | @sh),
  "rl_7d=" + (.rate_limits.seven_day.used_percentage // "" | tostring | @sh),
  "cache_warm=" + (.prompt_cache.warm // false | tostring | @sh),
  "cache_observed=" + (.prompt_cache.caching_observed // false | tostring | @sh),
  "cache_cause=" + (.prompt_cache.last_miss_cause.causes[0] // "" | @sh)
')"

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
  # Single git call: branch, ahead/behind, dirty state via status -sb
  status_line=$(git -C "$git_dir" --no-optional-locks status -sb 2>/dev/null | head -1)
  if [ -n "$status_line" ]; then
    # Extract branch name (## branch...upstream or ## branch)
    branch=$(echo "$status_line" | sed 's/^## //' | sed 's/\.\.\..*//' | sed 's/ \[.*//')

    # Dirty: any output beyond the first line
    dirty=$(git -C "$git_dir" --no-optional-locks diff --quiet 2>/dev/null; echo $?)
    dirty_idx=$(git -C "$git_dir" --no-optional-locks diff --cached --quiet 2>/dev/null; echo $?)
    if [ "$dirty" != "0" ] || [ "$dirty_idx" != "0" ]; then
      dirty_dot=$(printf " \033[33m●\033[0m")
    else
      dirty_dot=""
    fi

    # Ahead/behind from status line [ahead N, behind N]
    ab_str=""
    ahead=$(echo "$status_line" | grep -o 'ahead [0-9]*' | grep -o '[0-9]*')
    behind=$(echo "$status_line" | grep -o 'behind [0-9]*' | grep -o '[0-9]*')
    [ -n "$ahead" ] && [ "$ahead" -gt 0 ] && ab_str="${ab_str}$(printf "\033[32m↑%s\033[0m" "$ahead")"
    [ -n "$behind" ] && [ "$behind" -gt 0 ] && ab_str="${ab_str}$(printf "\033[33m↓%s\033[0m" "$behind")"
    [ -n "$ab_str" ] && ab_str=" ${ab_str}"

    part_git=$(printf "⎇ \033[32m%s\033[0m%s%s" "$branch" "$dirty_dot" "$ab_str")
  fi
fi

# --- 2b. Open PR / MR badge ---
part_pr=""
if [ -n "$pr_number" ]; then
  if [ "$pr_kind" = "mr" ]; then
    pr_label="!${pr_number}"
  else
    pr_label="#${pr_number}"
  fi
  case "$pr_state" in
    approved)          pr_color="32" ;;  # green
    changes_requested) pr_color="31" ;;  # red
    draft)             pr_color="2"  ;;  # dim
    *)                 pr_color="33" ;;  # yellow (pending/open)
  esac
  part_pr=$(printf "\033[%sm%s\033[0m" "$pr_color" "$pr_label")
fi

# --- 3. Model short name ---
model_short=$(echo "$model" | sed 's/^Claude //' | sed 's/ ([^)]*)//')
if [ -z "$model_short" ] && [ -n "$model_id" ]; then
  if   echo "$model_id" | grep -qi "opus";   then model_short="Opus"
  elif echo "$model_id" | grep -qi "sonnet"; then model_short="Sonnet"
  elif echo "$model_id" | grep -qi "haiku";  then model_short="Haiku"
  else model_short="$model_id"
  fi
fi
part_model=$(printf "◆ \033[35m%s\033[0m" "$model_short")

# --- 3b. Thinking effort (live session value; settings default as fallback) ---
part_effort=""
effort=$(printf '%s' "$input" | jq -r '.effort.level // empty' 2>/dev/null)
[ -z "$effort" ] && effort=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)
if [ -n "$effort" ]; then
  case "$effort" in
    low)    effort_label="Low";    effort_color="32" ;;
    medium) effort_label="Medium"; effort_color="33" ;;
    high)   effort_label="High";   effort_color="35" ;;
    xhigh)  effort_label="XHigh";  effort_color="31" ;;
    max)    effort_label="Max";    effort_color="1;31" ;;
    *)      effort_label=$(printf '%s' "$effort" | awk '{ print toupper(substr($0, 1, 1)) substr($0, 2) }')
            effort_color="37" ;;
  esac
  part_effort=$(printf "\033[%sm✦ %s\033[0m" "$effort_color" "$effort_label")
fi

# --- 4. Context bar (▓░, 10 wide, color by usage) ---
used_int=$(printf "%.0f" "$used_pct" 2>/dev/null || echo 0)
filled=$(( used_int * 10 / 100 ))
[ "$filled" -gt 10 ] && filled=10
[ "$filled" -lt 0 ]  && filled=0
empty=$(( 10 - filled ))
bar=""
for (( i=0; i<filled; i++ )); do bar="${bar}▓"; done
for (( i=0; i<empty;  i++ )); do bar="${bar}░"; done

if [ "$used_int" -ge 80 ]; then bar_color="31"   # red
elif [ "$used_int" -ge 50 ]; then bar_color="33"  # yellow
else                              bar_color="32"   # green
fi
part_bar=$(printf "\033[%sm%s %s%%\033[0m" "$bar_color" "$bar" "$used_int")

# --- 5. Rate limits (5h / 7d subscription usage) ---
part_rl=""
rl_str=""
if [ -n "$rl_5h" ]; then
  five_int=$(printf "%.0f" "$rl_5h" 2>/dev/null || echo "")
  if [ -n "$five_int" ]; then
    if   [ "$five_int" -ge 90 ]; then five_color="31"
    elif [ "$five_int" -ge 70 ]; then five_color="33"
    else                              five_color="2"
    fi
    rl_str="$(printf "\033[%sm5h:%s%%\033[0m" "$five_color" "$five_int")"
  fi
fi
if [ -n "$rl_7d" ]; then
  week_int=$(printf "%.0f" "$rl_7d" 2>/dev/null || echo "")
  if [ -n "$week_int" ]; then
    if   [ "$week_int" -ge 90 ]; then week_color="31"
    elif [ "$week_int" -ge 70 ]; then week_color="33"
    else                              week_color="2"
    fi
    [ -n "$rl_str" ] && rl_str="${rl_str} "
    rl_str="${rl_str}$(printf "\033[%sm7d:%s%%\033[0m" "$week_color" "$week_int")"
  fi
fi
part_rl="$rl_str"

# --- 5b. Cold prompt-cache flag ---
part_cache=""
if [ "$cache_observed" = "true" ] && [ "$cache_warm" = "false" ]; then
  if [ -n "$cache_cause" ] && [ "$cache_cause" != "unknown" ]; then
    part_cache=$(printf "\033[34m❄ %s\033[0m" "$cache_cause")
  else
    part_cache=$(printf "\033[34m❄\033[0m")
  fi
fi

# --- 6. Lines added/removed ---
part_lines=""
la=${lines_added:-0}
lr=${lines_removed:-0}
if [ "$la" -gt 0 ] || [ "$lr" -gt 0 ]; then
  part_lines=$(printf "\033[32m+%s\033[0m/\033[31m-%s\033[0m" "$la" "$lr")
fi

# --- 7. Elapsed time (from JSON duration_ms) ---
part_elapsed=""
elapsed_sec=$(( ${duration_ms:-0} / 1000 ))
if [ "$elapsed_sec" -gt 0 ]; then
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

# --- 8. Worktree indicator ---
part_worktree=""
if [ -n "$worktree_name" ]; then
  if [ -n "$worktree_branch" ]; then
    part_worktree=$(printf "\033[36m⊞ %s\033[0m \033[2m(%s)\033[0m" "$worktree_name" "$worktree_branch")
  else
    part_worktree=$(printf "\033[36m⊞ %s\033[0m" "$worktree_name")
  fi
fi

# --- 9. Session name ---
part_session=""
if [ -n "$session_name" ]; then
  part_session=$(printf "\033[1m[%s]\033[0m" "$session_name")
fi

# --- 10. Vim mode badge ---
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
[ -n "$part_git" ]      && output="${output}${SEP}${part_git}"
[ -n "$part_pr" ]       && output="${output}${SEP}${part_pr}"
output="${output}${SEP}${part_model}"
[ -n "$part_effort" ]   && output="${output}${SEP}${part_effort}"
output="${output}${SEP}${part_bar}"
[ -n "$part_rl" ]       && output="${output}${SEP}${part_rl}"
[ -n "$part_cache" ]    && output="${output}${SEP}${part_cache}"
[ -n "$part_lines" ]    && output="${output}${SEP}${part_lines}"
[ -n "$part_elapsed" ]  && output="${output}${SEP}${part_elapsed}"
[ -n "$part_worktree" ] && output="${output}${SEP}${part_worktree}"
[ -n "$part_session" ]  && output="${output}${SEP}${part_session}"
[ -n "$part_vim" ]      && output="${output}${SEP}${part_vim}"

printf "%s" "$output"
