#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMAND_SOURCE="${SCRIPT_DIR}/clickup.md"
COMMAND_TARGET="$HOME/.claude/commands/clickup.md"
HELPER_SCRIPT="${SCRIPT_DIR}/scripts/clickup.sh"
HELPER_TARGET="$HOME/.claude/scripts/clickup.sh"

echo "=== ClickUp Skill Setup ==="
echo

# 1. Check / prompt for API key
if [[ -z "${CLICKUP_API_KEY:-}" ]]; then
  echo "CLICKUP_API_KEY is not set."
  read -rp "Enter your ClickUp Personal API Token (pk_...): " token
  if [[ -z "$token" ]]; then
    echo "Error: No token provided. Aborting."
    exit 1
  fi
  export CLICKUP_API_KEY="$token"

  # Append to ~/.zshrc
  if ! grep -q 'CLICKUP_API_KEY' ~/.zshrc 2>/dev/null; then
    echo "" >> ~/.zshrc
    echo "# ClickUp API Key" >> ~/.zshrc
    echo "export CLICKUP_API_KEY=\"${token}\"" >> ~/.zshrc
    echo "Added CLICKUP_API_KEY to ~/.zshrc"
  else
    echo "CLICKUP_API_KEY already in ~/.zshrc (not modified)"
  fi
else
  echo "CLICKUP_API_KEY is already set."
fi
echo

# 2. Copy helper script to well-known location
mkdir -p "$HOME/.claude/scripts"
cp "$HELPER_SCRIPT" "$HELPER_TARGET"
chmod +x "$HELPER_TARGET"
echo "Installed clickup.sh to $HELPER_TARGET"

# 3. Create commands directory and symlink
mkdir -p "$HOME/.claude/commands"
if [[ -L "$COMMAND_TARGET" ]]; then
  rm "$COMMAND_TARGET"
fi
ln -sf "$COMMAND_SOURCE" "$COMMAND_TARGET"
echo "Symlinked command: $COMMAND_TARGET -> $COMMAND_SOURCE"
echo

# 4. Test API connectivity
echo "Testing API connectivity..."
http_code=$(curl -s -o /dev/null -w '%{http_code}' \
  -H "Authorization: ${CLICKUP_API_KEY}" \
  -H "Content-Type: application/json" \
  "https://api.clickup.com/api/v2/team")

if [[ "$http_code" == "200" ]]; then
  echo "API connection successful."
else
  echo "Warning: API returned HTTP $http_code. Check your token."
fi
echo

# 5. Print permission instructions
echo "=== Setup Complete ==="
echo
echo "Usage: In Claude Code, type /clickup to use the integration."
echo
echo "To pre-approve Bash permissions, add this to ~/.claude/settings.json:"
echo '  "permissions": {'
echo '    "allow": ['
echo '      "Bash(bash *clickup.sh *)"'
echo '    ]'
echo '  }'
echo
echo "You may need to restart Claude Code for the command to appear."
