#!/usr/bin/env bash
# Claude Code status line - derived from ~/.bashrc PS1
# Reads JSON input from stdin with session metadata

input=$(cat)

# -- Path: use workspace.current_dir (updates on /cd) --
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
[ -z "$cwd" ] && cwd=$(echo "$input" | jq -r '.cwd // empty')
[ -z "$cwd" ] && cwd="$(pwd)"

# -- Model --
model=$(echo "$input" | jq -r '.model.display_name // .model.id // empty')

# -- Context usage (pre-calculated percentage) --
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  if [ "$used_int" -ge 80 ]; then
    ctx_color='\033[01;31m'   # red when >= 80%
  elif [ "$used_int" -ge 50 ]; then
    ctx_color='\033[01;33m'   # yellow when >= 50%
  else
    ctx_color='\033[01;32m'   # green when < 50%
  fi
  ctx_str=$(printf "${ctx_color}ctx:%s%%\033[00m" "$used_int")
else
  ctx_str=""
fi

# -- Git branch (from cwd, skip lock) --
branch=""
if command -v git &>/dev/null; then
  branch=$(git -C "$cwd" -c core.locker=false rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# -- Rate limits (Claude.ai subscription) --
rate_str=""
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$five" ]; then
  five_int=$(printf '%.0f' "$five")
  if [ "$five_int" -ge 80 ]; then
    five_color='\033[01;31m'
  elif [ "$five_int" -ge 50 ]; then
    five_color='\033[01;33m'
  else
    five_color='\033[00m'
  fi
  rate_str=$(printf "${five_color}5h:%s%%\033[00m" "$five_int")
fi
if [ -n "$week" ]; then
  week_int=$(printf '%.0f' "$week")
  if [ "$week_int" -ge 80 ]; then
    week_color='\033[01;31m'
  elif [ "$week_int" -ge 50 ]; then
    week_color='\033[01;33m'
  else
    week_color='\033[00m'
  fi
  week_part=$(printf "${week_color}7d:%s%%\033[00m" "$week_int")
  if [ -n "$rate_str" ]; then
    rate_str="$rate_str $week_part"
  else
    rate_str="$week_part"
  fi
fi

# -- Assemble output --
# Format: user@host:cwd (branch) | model | ctx:XX% | 5h:XX% 7d:XX%
out=""

# PS1-style: green user@host : blue cwd
out=$(printf '\033[01;32m%s@%s\033[00m:\033[01;34m%s\033[00m' "$(whoami)" "$(hostname -s)" "$cwd")

# Git branch
if [ -n "$branch" ]; then
  out="$out $(printf '\033[01;33m(%s)\033[00m' "$branch")"
fi

# Separator and model
sep=" | "
if [ -n "$model" ]; then
  out="$out${sep}$(printf '\033[01;36m%s\033[00m' "$model")"
fi

# Context usage
if [ -n "$ctx_str" ]; then
  out="$out${sep}${ctx_str}"
fi

# Rate limits
if [ -n "$rate_str" ]; then
  out="$out${sep}${rate_str}"
fi

printf '%s' "$out"
