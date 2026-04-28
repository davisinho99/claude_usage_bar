#!/usr/bin/env bash
# pre-tool-use.sh — fired on every tool invocation
# Updates terminal title with usage bar using cached data
# Must be FAST — runs on every tool call

_usage_file="${CLAUDE_SESSION_DIR:-/tmp}/claude-usage.json"

_update_title() {
    local pct="${1:-0}"
    local input_tokens="${2:-0}"
    local cache_read="${3:-0}"
    local cache_write="${4:-0}"

    # Guard against non-numeric pct
    if ! [[ "$pct" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        pct=0
    fi
    # Guard against non-numeric tokens
    if ! [[ "$input_tokens" =~ ^[0-9]+$ ]] || \
       ! [[ "$cache_read" =~ ^[0-9]+$ ]] || \
       ! [[ "$cache_write" =~ ^[0-9]+$ ]]; then
        input_tokens=0
        cache_read=0
        cache_write=0
    fi

    # Build bar: ████░░░░░░░░░░░░ (20 chars)
    local bar_len=20
    local filled=$(( pct * bar_len / 100 ))
    [[ $filled -gt $bar_len ]] && filled=$bar_len
    [[ $filled -lt 0 ]] && filled=0
    local empty=$(( bar_len - filled ))

    local bar=""
    local i=0
    while [[ $i -lt $filled ]]; do bar+="█"; ((i++)); done
    i=0
    while [[ $i -lt $empty ]]; do bar+="░"; ((i++)); done

    # Color: green <60%, yellow 60-84%, red ≥85%
    local color reset
    if [[ $pct -ge 85 ]]; then
        color="\033[1;31m"
    elif [[ $pct -ge 60 ]]; then
        color="\033[1;33m"
    else
        color="\033[1;32m"
    fi
    reset="\033[0m"

    # Token summary
    local tokens_str=""
    if [[ ${input_tokens:-0} -gt 0 ]]; then
        tokens_str=" | In:${input_tokens} CR:${cache_read} CW:${cache_write}"
    fi

    # Write terminal title
    local title="${color}[${bar}]${reset} ${pct}%${tokens_str} | claude"
    printf '\033]0;%s\007' "$title"
}

# Read from cache file (instant — no subprocess)
if [[ -f "$_usage_file" ]]; then
    # Note: no 'local' — these are global vars used by the python3 calls below

    if command -v python3 &>/dev/null; then
        pct=$(python3 -c "import json; d=json.load(open('$_usage_file')); print(d.get('remaining_percentage', 0))" 2>/dev/null || echo "0")
        inp=$(python3 -c "import json; d=json.load(open('$_usage_file')); print(d.get('total_input_tokens', 0))" 2>/dev/null || echo "0")
        cache_r=$(python3 -c "import json; d=json.load(open('$_usage_file')); print(d.get('cache_read_tokens', 0))" 2>/dev/null || echo "0")
        cache_w=$(python3 -c "import json; d=json.load(open('$_usage_file')); print(d.get('cache_write_tokens', 0))" 2>/dev/null || echo "0")
    else
        # Fallback: grep from JSON (no python needed)
        pct=$(grep -oP '"remaining_percentage":\s*\K[0-9.]+' "$_usage_file" 2>/dev/null | head -1 || echo "0")
        inp=$(grep -oP '"total_input_tokens":\s*\K[0-9]+' "$_usage_file" 2>/dev/null | head -1 || echo "0")
        cache_r=$(grep -oP '"cache_read_tokens":\s*\K[0-9]+' "$_usage_file" 2>/dev/null | head -1 || echo "0")
        cache_w=$(grep -oP '"cache_write_tokens":\s*\K[0-9]+' "$_usage_file" 2>/dev/null | head -1 || echo "0")
    fi

    _update_title "${pct:-0}" "${inp:-0}" "${cache_r:-0}" "${cache_w:-0}"
else
    # No cache yet — show neutral bar
    _update_title "?" "?" "?" "?"
fi
