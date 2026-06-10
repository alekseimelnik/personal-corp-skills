#!/bin/bash
# Claude Code statusline: dir branch • model • tokens/window • [ limits ] • $cost
input=$(cat)

dir_name=$(echo "$input" | jq -r '.workspace.current_dir | split("/") | last // "?"')
model=$(echo "$input" | jq -r '.model.display_name // "?"')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
used_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
window_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

# Git branch
cwd=$(echo "$input" | jq -r '.workspace.current_dir // "."')
branch=$(cd "$cwd" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")

# Rate limits: come straight from the statusline payload (v2.1.80+, Pro/Max).
# Absent until the first API response in a session — cache last seen values.
RL_CACHE="/tmp/claude-rate-limits.json"
rl=$(echo "$input" | jq -c '.rate_limits // empty' 2>/dev/null)
if [ -n "$rl" ]; then
    echo "$rl" > "$RL_CACHE"
elif [ -f "$RL_CACHE" ]; then
    rl=$(cat "$RL_CACHE")
fi

five_used=""
week_used=""
five_reset=""
if [ -n "$rl" ]; then
    five_used=$(echo "$rl" | jq -r '.five_hour.used_percentage // empty | round' 2>/dev/null)
    week_used=$(echo "$rl" | jq -r '.seven_day.used_percentage // empty | round' 2>/dev/null)
    reset_epoch=$(echo "$rl" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
    if [ -n "$reset_epoch" ]; then
        secs_left=$(( reset_epoch - $(date +%s) ))
        if [ "$secs_left" -gt 0 ]; then
            if [ "$secs_left" -ge 3600 ]; then
                five_reset="$(( secs_left / 3600 ))h$(( (secs_left % 3600) / 60 ))m"
            else
                five_reset="$(( secs_left / 60 ))m"
            fi
        fi
    fi
fi

# Format cost
cost_fmt=$(printf "%.2f" "$cost" 2>/dev/null || echo "0.00")

# Format token counts: 255102 -> 255k, 1000000 -> 1M
fmt_tokens() {
    local n=$1
    if [ "$n" -ge 1000000 ]; then
        awk -v n="$n" 'BEGIN { v = n / 1000000; printf (v == int(v)) ? "%dM" : "%.1fM", v }'
    elif [ "$n" -ge 1000 ]; then
        printf "%dk" $((n / 1000))
    else
        printf "%d" "$n"
    fi
}
used_fmt=$(fmt_tokens "$used_tokens")
window_fmt=$(fmt_tokens "$window_size")

# Color by used percentage: dim gray when calm, yellow <80, red after.
# No green — low usage is non-information, it should recede, not glow.
used_color() {
    if [ "$1" -lt 50 ]; then
        echo "\033[2;37m"
    elif [ "$1" -lt 80 ]; then
        echo "\033[33m"
    else
        echo "\033[1;31m"
    fi
}
# Context tokens are the one thing that must always be readable: bold, never dim
ctx_color() {
    if [ "$1" -lt 50 ]; then
        echo "\033[1;97m"
    elif [ "$1" -lt 80 ]; then
        echo "\033[1;33m"
    else
        echo "\033[1;31m"
    fi
}
ctx_color=$(ctx_color "$pct")

# Build output. Hierarchy: tokens loud, limits framed in one block, the rest dim.
dim="\033[2m"
rst="\033[0m"
sep=" ${dim}•${rst} "

# Branch shown only when it's something non-default — main/master is noise
if [ -n "$branch" ] && [ "$branch" != "main" ] && [ "$branch" != "master" ]; then
    out="${dim}${dir_name} ${branch}${rst}"
else
    out="${dim}${dir_name}${rst}"
fi
out="${out}${sep}${dim}${model}${rst}"

# Context tokens — the headline
out="${out}${sep}${ctx_color}${used_fmt}/${window_fmt}${rst}"

# Rate limits — one bracketed block: [ h 27% 46m │ W 86% ]
limits=""
if [ -n "$five_used" ]; then
    five_color=$(used_color "$five_used")
    limits="${five_color}h ${five_used}%${rst}${five_reset:+ ${dim}${five_reset}${rst}}"
fi
if [ -n "$week_used" ]; then
    week_color=$(used_color "$week_used")
    [ -n "$limits" ] && limits="${limits} ${dim}│${rst} "
    limits="${limits}${week_color}W ${week_used}%${rst}"
fi
if [ -n "$limits" ]; then
    out="${out}${sep}${dim}[${rst} ${limits} ${dim}]${rst}"
fi

# Cost — trailing, least urgent
out="${out}${sep}${dim}\$${cost_fmt}${rst}"

printf '%b' "$out"
