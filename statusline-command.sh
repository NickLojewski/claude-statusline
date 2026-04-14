#!/bin/bash
config_file="$HOME/.claude/statusline-config.txt"
if [ -f "$config_file" ]; then
  source "$config_file"
  show_dir=$SHOW_DIRECTORY
  show_branch=$SHOW_BRANCH
  show_usage=$SHOW_USAGE
  show_bar=$SHOW_PROGRESS_BAR
  show_reset=$SHOW_RESET_TIME
else
  show_dir=1
  show_branch=1
  show_usage=1
  show_bar=1
  show_reset=1
fi

input=$(cat)
current_dir_path=$(echo "$input" | grep -o '"current_dir":"[^"]*"' | sed 's/"current_dir":"//;s/"$//')
current_dir=$(basename "$current_dir_path")
BLUE=$'\033[38;5;25m'
GREEN=$'\033[38;5;64m'
YELLOW=$'\033[38;5;100m'
CYAN=$'\033[38;5;31m'
ORANGE=$'\033[38;2;210;108;75m'
ORANGE_BG=$'\033[48;2;210;108;75m'
BLACK=$'\033[38;5;232m'
GRAY=$'\033[0;90m'
RESET=$'\033[0m'

# 10-level gradient: dark green → deep red
LEVEL_1=$'\033[38;5;22m'   # dark green
LEVEL_2=$'\033[38;5;28m'   # soft green
LEVEL_3=$'\033[38;5;34m'   # medium green
LEVEL_4=$'\033[38;5;100m'  # green-yellowish dark
LEVEL_5=$'\033[38;5;142m'  # olive/yellow-green dark
LEVEL_6=$'\033[38;5;178m'  # muted yellow
LEVEL_7=$'\033[38;5;172m'  # muted yellow-orange
LEVEL_8=$'\033[38;5;166m'  # darker orange
LEVEL_9=$'\033[38;5;160m'  # dark red
LEVEL_10=$'\033[38;5;124m' # deep red

# Build components (without separators)

## CURRENT DIRECTORY ##
dir_text=""
if [ "$show_dir" = "1" ]; then
  dir_text="${ORANGE_BG}${BLACK} ${current_dir} ${RESET}"
fi

## GIT BRANCH ##
branch_text=""
if [ "$show_branch" = "1" ]; then
  if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
      if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        dirty="${ORANGE}● ${RESET}"
      else
        dirty=""
      fi
      branch_text="${dirty}${ORANGE}⎇ ${branch}${RESET}"
    fi
  fi
fi

## MODEL NAME ##
model_name=""
model_info=$(echo "$input" | jq -r '.model.display_name')
model_name=${ORANGE}${model_info}${RESET}

## CONTEXT USAGE ##
context_info=""
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
current_usage=$(echo "$input" | jq '.context_window.current_usage')

# Calculate context percentage
if [ "$current_usage" != "null" ]; then
    current_tokens=$(echo "$current_usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    context_percent=$((current_tokens * 100 / context_size))
else
    context_percent=0
fi

context_info=${ORANGE}"${context_percent}%"${RESET}

## SESSION USAGE (from stdin JSON rate_limits) ##
usage_text=""
if [ "$show_usage" = "1" ]; then
  utilization=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
  resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null)

  if [ -n "$utilization" ]; then
    # Round to integer
    utilization=$(printf "%.0f" "$utilization")

    if [ "$utilization" -le 10 ]; then
      usage_color="$LEVEL_1"
    elif [ "$utilization" -le 20 ]; then
      usage_color="$LEVEL_2"
    elif [ "$utilization" -le 30 ]; then
      usage_color="$LEVEL_3"
    elif [ "$utilization" -le 40 ]; then
      usage_color="$LEVEL_4"
    elif [ "$utilization" -le 50 ]; then
      usage_color="$LEVEL_5"
    elif [ "$utilization" -le 60 ]; then
      usage_color="$LEVEL_6"
    elif [ "$utilization" -le 70 ]; then
      usage_color="$LEVEL_7"
    elif [ "$utilization" -le 80 ]; then
      usage_color="$LEVEL_8"
    elif [ "$utilization" -le 90 ]; then
      usage_color="$LEVEL_9"
    else
      usage_color="$LEVEL_10"
    fi

    progress_bar=""

    reset_time_display=""
    if [ "$show_reset" = "1" ] && [ -n "$resets_at" ]; then
      # resets_at is a unix timestamp from the JSON
      epoch="$resets_at"
      if [ -n "$epoch" ] && [ "$epoch" != "null" ]; then
        time_format=$(defaults read -g AppleICUForce24HourTime 2>/dev/null)
        if [ "$time_format" = "1" ]; then
          reset_time=$(date -r "$epoch" "+%H:%M" 2>/dev/null)
        else
          reset_time=$(date -r "$epoch" "+%I:%M %p" 2>/dev/null)
        fi
        [ -n "$reset_time" ] && reset_time_display=$(printf " → %s" "$reset_time")
      fi
    fi

    usage_text="${usage_color}${progress_bar} ${utilization}%${reset_time_display}${RESET}"
  else
    usage_text="${YELLOW}~${RESET}"
  fi
fi

## SESSION COST ##
cost_text=""
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)
if [ -n "$total_cost" ] && [ "$total_cost" != "0" ]; then
  cost_text="${ORANGE}\$$(printf "%.2f" "$total_cost")${RESET}"
fi

output=""
separator="${ORANGE} │ ${RESET}"

[ -n "$dir_text" ] && output="${dir_text}"

if [ -n "$branch_text" ]; then
  [ -n "$output" ] && output="${output}${separator}"
  output="${output}${branch_text}"
fi

if [ -n "$model_name" ]; then
  [ -n "$output" ] && output="${output}${separator}"
  output="${output}${model_name}"
fi

if [ -n "$context_info" ]; then
  [ -n "$output" ] && output="${output}${separator}"
  output="${output}${context_info}"
fi

if [ -n "$usage_text" ]; then
  [ -n "$output" ] && output="${output}${separator}"
  output="${output}${usage_text}"
fi

if [ -n "$cost_text" ]; then
  [ -n "$output" ] && output="${output}${separator}"
  output="${output}${cost_text}"
fi

printf "%s\n" "$output"
