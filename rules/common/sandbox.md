# Sandbox Avoidance Patterns

Approval fatigue is a security risk. When the sandbox blocks too many harmless
operations, users start blindly approving everything — defeating the purpose of
sandboxing. This rule exists to prevent that by teaching you to write commands
the sandbox will not block.

**This is a living document.** New patterns are added whenever a previously
unknown sandbox block is encountered.

## General Principles

1. **Prefer dedicated tools over Bash** — Read, Write, Edit, Glob, Grep never
   trigger sandbox prompts.
2. **Use absolute paths** — eliminates the need for `cd` in compound commands.
3. **One concern per command** — split navigation, computation, and file I/O
   into separate sequential Bash calls when they cannot be expressed with
   absolute paths.
4. **Avoid compound expressions the sandbox cannot parse** — the sandbox
   evaluates the full command string. If it cannot prove every part is safe, it
   blocks the whole thing.

## Known Blocked Patterns

Each entry follows the format:

```
### <Short description>
Blocked: <example command that gets blocked>
Fix:     <safe alternative>
Why:     <one-line explanation of what the sandbox cannot verify>
```

---

### cd + redirection

Blocked: `cd src && echo "x" > out.txt`
Fix:     `echo "x" > /absolute/path/to/src/out.txt`
Why:     Sandbox cannot resolve the write target when `cd` changes context before a redirect.

### cd + pipe

Blocked: `cd build && cat log.txt | grep ERROR`
Fix:     `grep ERROR /absolute/path/to/build/log.txt`
Why:     Same as above — `cd` in a chain obscures the paths the sandbox needs to verify.

### $() command substitution in compound commands

Blocked: `FILE=$(find . -name "*.log") && rm "$FILE"`
Fix:     Run `find` first, then use the result in a follow-up `rm` call.
Why:     Sandbox cannot evaluate the output of `$()` at parse time, so it cannot verify the arguments to `rm`.

### Backtick substitution in compound commands

Blocked: `` DIR=`pwd` && ls "$DIR/src" ``
Fix:     `ls /absolute/path/to/src`
Why:     Same as `$()` — runtime values are opaque to the sandbox's static analysis.

### Writing to paths outside the sandbox allowlist

Blocked: `echo "data" > ~/Documents/notes.txt`
Fix:     Use the Write tool, or write to an allowed path (`$TMPDIR`, `.`, `~/.claude`, `~/.config`).
Why:     `~/Documents` is in `denyRead`/not in `allowWrite`. The sandbox blocks both read and write.

### Network access to non-whitelisted hosts

Blocked: `curl https://example.com/api`
Fix:     Use the WebFetch tool, or add the domain to `sandbox.network.allowedDomains` in settings.
Why:     Only `github.com`, `api.github.com`, and `raw.githubusercontent.com` are whitelisted.

### Nested subshells with file operations

Blocked: `(cd /tmp && tar xzf archive.tar.gz)`
Fix:     `tar xzf /tmp/archive.tar.gz -C /tmp`
Why:     Subshell `()` with `cd` creates the same opaque-path problem as `&&` chains.

### Chaining individually allowed commands with && or ;

Blocked: `git -C /path/to/repo add file.txt && git -C /path/to/repo commit -m "msg"`
Fix:     Run each command as a separate Bash call, or use `dangerouslyDisableSandbox: true`.
Why:     The sandbox evaluates the full compound command as one unit. Even if each part would pass individually, the combined string may fail static analysis.

### git commands that call getcwd()

Blocked: `git status`
Fix:     `git -C /absolute/path/to/repo status`
Why:     The sandbox intercepts the `getcwd()` syscall. Using `-C` tells git the repo path explicitly, bypassing the syscall.

---

## Adding New Patterns

When a command is blocked by the sandbox and the block was unnecessary:

1. Add a new entry below the `---` separator above, following the template.
2. Keep entries alphabetically or grouped by theme — your call.
3. If the pattern is language-specific, add it to the language rule file instead
   and reference this file.
