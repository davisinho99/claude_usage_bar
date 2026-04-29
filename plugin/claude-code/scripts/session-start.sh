#!/usr/bin/env bash
# session-start.sh — fired when a new Claude Code session starts
# Starts the background usage monitor that writes to the cache file.
# The statusline script reads this file continuously.

SESSION_DIR="${CLAUDE_SESSION_DIR:-/tmp}"
PID_FILE="$SESSION_DIR/claude-usage-bar.pid"
USAGE_CACHE="$SESSION_DIR/claude-usage.json"
POLL_INTERVAL=5

# Kill any previous monitor
if [[ -f "$PID_FILE" ]]; then
    kill "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null || true
    rm -f "$PID_FILE"
fi

# Reset statusline on start
printf ''

# Exit if claude CLI not available
if ! command -v claude &>/dev/null; then
    exit 0
fi

# Start background monitor
(
    # Save PID immediately (before &) to get the subshell's own PID
    echo $$ > "$PID_FILE"

    # Wait for session to warm up
    sleep 3

    while true; do
        # Get usage data (with error handling - don't exit on failure)
        USAGE_OUT=$(claude --print "/usage" 2>/dev/null) || {
            sleep "$POLL_INTERVAL"
            continue
        }

        if [[ -n "$USAGE_OUT" ]] && echo "$USAGE_OUT" | grep -qi "valid"; then
            # Parse remaining percentage
            PCT=$(echo "$USAGE_OUT" | grep -i "remaining" | grep -oE '[0-9]+%' | head -1 | tr -d '%' || echo "")

            # Parse tokens
            IN=$(echo "$USAGE_OUT" | grep -i "input" | grep -oE '[0-9,]+' | head -1 | tr -d ',' || echo "0")
            OUT=$(echo "$USAGE_OUT" | grep -i "output" | grep -oE '[0-9,]+' | head -1 | tr -d ',' || echo "0")
            CACHE_R=$(echo "$USAGE_OUT" | grep -i "cache read" | grep -oE '[0-9,]+' | head -1 | tr -d ',' || echo "0")
            CACHE_W=$(echo "$USAGE_OUT" | grep -i "cache write" | grep -oE '[0-9,]+' | head -1 | tr -d ',' || echo "0")

            # Write JSON cache
            cat > "$USAGE_CACHE" <<EOF
{"pct":"${PCT:-0}","in":"${IN:-0}","out":"${OUT:-0}","cr":"${CACHE_R:-0}","cw":"${CACHE_W:-0}"}
EOF
        fi

        sleep "$POLL_INTERVAL"
    done
) &
disown
