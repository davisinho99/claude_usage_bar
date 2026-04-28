#!/usr/bin/env bash
# stop.sh — fired when session ends
# Kills background monitor and cleans up

SESSION_DIR="${CLAUDE_SESSION_DIR:-/tmp}"
PID_FILE="$SESSION_DIR/claude-usage-bar.pid"
USAGE_CACHE="$SESSION_DIR/claude-usage.json"

# Kill background monitor
if [[ -f "$PID_FILE" ]]; then
    kill "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null || true
    rm -f "$PID_FILE"
fi

# Clean up cache
rm -f "$USAGE_CACHE"
