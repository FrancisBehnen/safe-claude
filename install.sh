#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"
BACKUP_FILE="$HOME/.claude/settings.json.bak"
RULES_DIR="$HOME/.claude/rules/common"

green()  { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
red()    { printf '\033[31m%s\033[0m\n' "$1"; }

# --- Prerequisites ---

if ! command -v jq &>/dev/null; then
  red "jq is required but not installed."
  if command -v brew &>/dev/null; then
    read -rp "Install jq via Homebrew? [Y/n] " ans
    if [[ "${ans:-Y}" =~ ^[Yy]$ ]]; then
      brew install jq
    else
      red "Aborting. Please install jq and re-run." && exit 1
    fi
  else
    red "Please install jq (https://jqlang.github.io/jq/) and re-run." && exit 1
  fi
fi

# --- Install rm-safely ---

if command -v rm-safely &>/dev/null; then
  green "rm-safely is already installed."
else
  HAS_NPM=$(command -v npm &>/dev/null && echo 1 || echo 0)
  HAS_BREW=$(command -v brew &>/dev/null && echo 1 || echo 0)

  if [[ "$HAS_NPM" == "1" && "$HAS_BREW" == "1" ]]; then
    echo "Install rm-safely via:"
    echo "  1) npm (recommended)"
    echo "  2) brew"
    read -rp "Choice [1/2]: " choice
    case "${choice:-1}" in
      2) brew install rm-safely ;;
      *) npm install -g rm-safely ;;
    esac
  elif [[ "$HAS_NPM" == "1" ]]; then
    npm install -g rm-safely
  elif [[ "$HAS_BREW" == "1" ]]; then
    brew install rm-safely
  else
    red "Neither npm nor brew found. Please install rm-safely manually:"
    red "  https://github.com/zdk/rm-safely"
    exit 1
  fi

  if command -v rm-safely &>/dev/null; then
    green "rm-safely installed successfully."
  else
    yellow "rm-safely was installed but may not be on PATH yet. Check your shell config."
  fi
fi

# --- Copy rules ---

mkdir -p "$RULES_DIR"
cp "$SCRIPT_DIR/rules/common/sandbox.md" "$RULES_DIR/sandbox.md"
green "Copied sandbox rules to $RULES_DIR/sandbox.md"

# --- Merge settings.json ---

mkdir -p "$HOME/.claude"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo '{}' > "$SETTINGS_FILE"
  yellow "Created new $SETTINGS_FILE"
fi

cp "$SETTINGS_FILE" "$BACKUP_FILE"
yellow "Backed up settings to $BACKUP_FILE"

MERGED=$(jq -s '
  .[0] as $existing | .[1] as $overlay |
  $existing
  | .permissions.allow = (($existing.permissions.allow // []) + ($overlay.permissions.allow // []) | unique)
  | .permissions.ask = (($existing.permissions.ask // []) + ($overlay.permissions.ask // []) | unique)
  | .permissions.deny = (($existing.permissions.deny // []) + ($overlay.permissions.deny // []) | unique)
  | .sandbox = $overlay.sandbox
' "$SETTINGS_FILE" "$SCRIPT_DIR/settings-overlay.json")

echo "$MERGED" > "$SETTINGS_FILE"
green "Merged security settings into $SETTINGS_FILE"

# --- Done ---

echo ""
green "safe-claude installed successfully!"
echo "  - Sandbox config and permissions merged into settings.json"
echo "  - Sandbox avoidance rules installed"
echo "  - rm-safely protects against accidental deletion"
echo ""
echo "Restart Claude Code for changes to take effect."
