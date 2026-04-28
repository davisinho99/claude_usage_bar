#!/usr/bin/env bash
# statusline.sh — outputs the usage bar for Claude Code's statusLine
# This script is referenced in ~/.claude/settings.json
# It runs continuously, not just on tool calls

USAGE_FILE="${CLAUDE_SESSION_DIR:-/tmp}/claude-usage.json"

# No file = no bar yet
if [[ ! -f "$USAGE_FILE" ]]; then
    exit 0
fi

# Read and validate JSON
if command -v python3 &>/dev/null; then
    PCT=$(python3 -c "import json,sys; d=json.load(open('$USAGE_FILE')); print(d.get('pct','?'))" 2>/dev/null || echo "?")
    IN=$(python3 -c "import json,sys; d=json.load(open('$USAGE_FILE')); print(d.get('in','0'))" 2>/dev/null || echo "0")
    CR=$(python3 -c "import json,sys; d=json.load(open('$USAGE_FILE')); print(d.get('cr','0'))" 2>/dev/null || echo "0")
    CW=$(python3 -c "import json,sys; d=json.load(open('$USAGE_FILE')); print(d.get('cw','0'))" 2>/dev/null || echo "0")
else
    PCT=$(grep -oP '"pct":"\K[^"]+' "$USAGE_FILE" 2>/dev/null || echo "?")
    IN=$(grep -oP '"in":"\K[^"]+' "$USAGE_FILE" 2>/dev/null || echo "0")
    CR=$(grep -oP '"cr":"\K[^"]+' "$USAGE_FILE" 2>/dev/null || echo "0")
    CW=$(grep -oP '"cw":"\K[^"]+' "$USAGE_FILE" 2>/dev/null || echo "0")
fi

# Guard: non-numeric
if ! [[ "$PCT" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    exit 0
fi

# Build bar: ████░░░░░░░░░░░░░░ (20 chars)
BAR_LEN=20
FILLED=$(( PCT * BAR_LEN / 100 ))
[[ $FILLED -gt $BAR_LEN ]] && FILLED=$BAR_LEN
[[ $FILLED -lt 0 ]] && FILLED=0
EMPTY=$(( BAR_LEN - FILLED ))

BAR=""
i=0; while [[ $i -lt $FILLED ]]; do BAR+="█"; ((i++)); done
i=0; while [[ $i -lt $EMPTY ]]; do BAR+="░"; ((i++)); done

# Color: green <60, yellow 60-84, red >=85
if [[ $PCT -ge 85 ]]; then
    COLOR="\033[1;31m"
elif [[ $PCT -ge 60 ]]; then
    COLOR="\033[1;33m"
else
    COLOR="\033[1;32m"
fi
RESET="\033[0m"

# Token summary
TOKENS=""
if [[ ${IN:-0} -gt 0 ]]; then
    TOKENS=" In:${IN} CR:${CR} CW:${CW}"
fi

printf '%b[%b]%b %s%%%b%s' "$COLOR" "$BAR" "$RESET" "$PCT" "$COLOR" "$RESET"
