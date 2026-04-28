#!/usr/bin/env bash
# install.sh — sets up statusLine in ~/.claude/settings.json
# Run after plugin install to enable the usage bar

SETTINGS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Detect OS for shell
if [[ "$(uname)" == "Darwin" ]] || [[ -z "$OSTYPE" ]] || [[ "$OSTYPE" == "linux-gnu"* ]]; then
    SHELL_CMD="bash \"$PLUGIN_ROOT/scripts/statusline.sh\""
else
    SHELL_CMD="bash \"$PLUGIN_ROOT/scripts/statusline.sh\""
fi

STATUSLINE_CONFIG="{\"type\": \"command\", \"command\": $SHELL_CMD}"

# Ensure settings.json exists
if [[ ! -f "$SETTINGS" ]]; then
    mkdir -p "$(dirname "$SETTINGS")"
    echo '{}' > "$SETTINGS"
fi

# Check if statusLine already configured
if grep -q '"statusLine"' "$SETTINGS" 2>/dev/null; then
    echo "statusLine already configured in $SETTINGS"
    echo "No changes made."
    exit 0
fi

# Add statusLine to settings.json using python3
python3 -c "
import json, sys

settings_path = '$SETTINGS'

try:
    with open(settings_path, 'r') as f:
        settings = json.load(f)
except Exception:
    settings = {}

settings['statusLine'] = {
    'type': 'command',
    'command': '$PLUGIN_ROOT/scripts/statusline.sh'
}

with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)

print('statusLine added to $SETTINGS')
"

exit 0
