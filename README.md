# safe-claude

Opinionated Claude Code configuration that maximizes autonomous work while maintaining security.

## Problem

Claude Code's default sandbox blocks so many harmless operations that users hit **approval fatigue** — and start blindly approving everything. This defeats the purpose of sandboxing entirely.

## Solution

Three layers working together:

1. **Sandbox configuration** — pre-approved permissions for common dev tools, sensible filesystem/network boundaries, and explicit `ask`/`deny` lists for genuinely dangerous operations.
2. **Sandbox avoidance rules** — a living document teaching Claude Code how to write commands that won't trigger unnecessary sandbox prompts (e.g. use absolute paths instead of `cd` chains).
3. **rm-safely** — replaces `rm` with a trash-based alternative so file deletion is always reversible.

## Install

```bash
git clone https://github.com/FrancisBehnen/safe-claude.git
cd safe-claude
./install.sh
```

The installer will:
- Install `rm-safely` (via npm or brew, your choice)
- Copy sandbox avoidance rules to `~/.claude/rules/common/`
- **Merge** security settings into your existing `~/.claude/settings.json` without touching your plugins, model, or other preferences

## What gets merged

| Key | Strategy |
|-----|----------|
| `permissions.allow` | Union (adds ours, keeps yours) |
| `permissions.ask` | Union |
| `permissions.deny` | Union |
| `sandbox` | Overwrites (assumes no prior sandbox config) |

Everything else (`model`, `enabledPlugins`, `statusLine`, etc.) is untouched.

## Uninstall

The installer backs up your settings to `~/.claude/settings.json.bak` before merging. To revert:

```bash
cp ~/.claude/settings.json.bak ~/.claude/settings.json
rm ~/.claude/rules/common/sandbox.md
npm uninstall -g rm-safely  # or: brew uninstall rm-safely
```
