#!/usr/bin/env bash
# stop.sh — fired when session ends
# Kills background monitor and resets terminal title

SESSION_DIR="${CLAUDE_SESSION_DIR:-/tmp}"
PID_FILE="$SESSION_DIR/claude-usage-bar.pid"
USAGE_CACHE="$SESSION_DIR/claude-usage.json"

# Kill background monitor (ignore errors — process may already be dead)
if [[ -f "$PID_FILE" ]]; then
    kill "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null || true
    rm -f "$PID_FILE"
fi

# Clean up cache
rm -f "$USAGE_CACHE"

# Reset terminal title to default
printf '\033]0;%s\007' "bash"
