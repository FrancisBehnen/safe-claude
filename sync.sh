#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"
RULES_SRC="$HOME/.claude/rules/common/sandbox.md"

green() { printf '\033[32m%s\033[0m\n' "$1"; }
red()   { printf '\033[31m%s\033[0m\n' "$1"; }

# --- Sync settings-overlay.json ---

if [[ ! -f "$SETTINGS_FILE" ]]; then
  red "No settings file found at $SETTINGS_FILE" && exit 1
fi

jq '{
  permissions: .permissions,
  sandbox: .sandbox
}' "$SETTINGS_FILE" > "$SCRIPT_DIR/settings-overlay.json"

green "Synced settings-overlay.json from $SETTINGS_FILE"

# --- Sync sandbox.md ---

RULES_DEST="$SCRIPT_DIR/rules/common/sandbox.md"

if [[ -L "$RULES_SRC" || -L "$RULES_DEST" ]] && [[ "$(readlink -f "$RULES_SRC")" == "$(readlink -f "$RULES_DEST")" ]]; then
  green "rules/common/sandbox.md is symlinked — no copy needed"
elif [[ -f "$RULES_SRC" ]]; then
  cp "$RULES_SRC" "$RULES_DEST"
  green "Synced rules/common/sandbox.md from $RULES_SRC"
else
  red "No sandbox.md found at $RULES_SRC — skipping"
fi
