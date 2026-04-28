#!/usr/bin/env bash
# session-start.sh — fired when a new Claude Code session starts
# Starts the background usage monitor

SESSION_DIR="${CLAUDE_SESSION_DIR:-/tmp}"
PID_FILE="$SESSION_DIR/claude-usage-bar.pid"
USAGE_CACHE="$SESSION_DIR/claude-usage.json"
CONTEXT_WINDOW="${CLAUDE_CONTEXT_WINDOW:-200000}"

# Kill any previous monitor for this session
if [[ -f "$PID_FILE" ]]; then
    kill "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null || true
    rm -f "$PID_FILE"
fi

# Guard check
if ! command -v claude &>/dev/null; then
    exit 0
fi

# Reset terminal title
printf '\033]0;claude\007'

# Start background monitor
(
    sleep 3  # wait for session to warm up

    while true; do
        # Get usage data — try --print flag first (machine-readable), fallback to slash command
        USAGE_OUT=$(claude --print "/usage" 2>/dev/null) || \
                    USAGE_OUT=$(claude /usage 2>/dev/null) || \
                    USAGE_OUT=""

        if [[ -n "$USAGE_OUT" ]]; then
            # Parse remaining percentage: look for "Remaining: N%" or "N%"
            PCT=$(echo "$USAGE_OUT" | grep -i "remaining" | grep -oE '[0-9]+%' | head -1 | tr -d '%' || echo "0")

            # Parse tokens: "N input" or "input: N"
            IN=$(echo "$USAGE_OUT" | grep -i "input" | grep -oE '[0-9,]+' | head -1 | tr -d ',' || echo "0")
            OUT=$(echo "$USAGE_OUT" | grep -i "output" | grep -oE '[0-9,]+' | head -1 | tr -d ',' || echo "0")
            CACHE_READ=$(echo "$USAGE_OUT" | grep -i "cache read" | grep -oE '[0-9,]+' | head -1 | tr -d ',' || echo "0")
            CACHE_WRITE=$(echo "$USAGE_OUT" | grep -i "cache write" | grep -oE '[0-9,]+' | head -1 | tr -d ',' || echo "0")
            CTX=$(echo "$USAGE_OUT" | grep -i "context window" | grep -oE '[0-9,]+' | head -1 | tr -d ',' || echo "$CONTEXT_WINDOW")

            # Write cache JSON
            cat > "$USAGE_CACHE" <<EOF
{
  "remaining_percentage": ${PCT:-0},
  "total_input_tokens": ${IN:-0},
  "total_output_tokens": ${OUT:-0},
  "cache_read_tokens": ${CACHE_READ:-0},
  "cache_write_tokens": ${CACHE_WRITE:-0},
  "context_window_size": ${CTX:-$CONTEXT_WINDOW}
}
EOF
        fi

        sleep 5
    done
) &

echo $! > "$PID_FILE"
