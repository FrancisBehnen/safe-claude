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

## Investigating a failed operation

When a command is blocked by the sandbox and the unsandboxed retry succeeds:

1. **Screenshot** — Take a screenshot showing both the failed (red) command and the successful (green) retry.
2. **Diagnose** — Open Claude Code in the safe-claude repo and share the screenshot. Ask it why the original command was blocked and to fix it — either by adding a pattern to `rules/common/sandbox.md` or by updating `settings-overlay.json` (e.g. adding a path to the sandbox allowlist or a permission).
3. **Sync** — Run `./sync.sh` to propagate the fix, then commit and push.

### Hidden path dependencies

Some failures aren't obvious from the command. For example, `git push` over HTTPS may fail with `could not read Username` — not because git or push is blocked, but because git's credential helper is configured in `/opt/local/etc/gitconfig`, which the sandbox denies reading (it falls under `/etc`).

To debug: run the command manually (`! git push`) — if it works, the sandbox is blocking an internal file read. Use tool-specific commands to find which config file is involved:

```bash
git config --show-origin credential.helper
# → file:/opt/local/etc/gitconfig    osxkeychain
```

Then add the specific file (not the whole directory) to `allowRead` in settings.

## Updating

After editing `~/.claude/settings.json` or `~/.claude/rules/common/sandbox.md`, run:

```bash
./sync.sh
```

This extracts `permissions` + `sandbox` from your live settings and copies the current sandbox rules into the repo, ready to commit.

## Uninstall

The installer backs up your settings to `~/.claude/settings.json.bak` before merging. To revert:

```bash
cp ~/.claude/settings.json.bak ~/.claude/settings.json
rm ~/.claude/rules/common/sandbox.md
npm uninstall -g rm-safely  # or: brew uninstall rm-safely
```
