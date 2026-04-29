#!/usr/bin/env bash
# stop.sh — fired when session ends
# Kills background monitor and cleans up

SESSION_DIR="${CLAUDE_SESSION_DIR:-/tmp}"
PID_FILE="$SESSION_DIR/claude-usage-bar.pid"
USAGE_CACHE="$SESSION_DIR/claude-usage.json"

# Kill background monitor
if [[ -f "$PID_FILE" ]]; then
    PID="$(cat "$PID_FILE" 2>/dev/null)"
    # Verify process exists before killing
    if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
        kill "$PID" 2>/dev/null
        # Wait for process to terminate
        for i in {1..5}; do
            if ! kill -0 "$PID" 2>/dev/null; then
                break
            fi
            sleep 0.2
        done
        # Force kill if still alive
        if kill -0 "$PID" 2>/dev/null; then
            kill -9 "$PID" 2>/dev/null
        fi
    fi
    rm -f "$PID_FILE"
fi

# Clean up cache
rm -f "$USAGE_CACHE"
