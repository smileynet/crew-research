# Cross-Platform Bash (Windows/macOS/Linux)

Companion to script-authoring SKILL.md. Scripts target bash; on Windows, Git Bash provides bash + coreutils.

## Compatibility rules

- **Prefix with `bash`** in task runners (mise, Makefiles) — Windows won't find shebangs
- **Use `/tmp/` for temp files** — Git Bash maps this correctly on all platforms
- **Avoid `sed -i` without backup suffix** — macOS sed requires `sed -i ''`, GNU doesn't. Use: `sed -i'' -e 's/...' file` or write to temp + mv
- **Use `diff -q` not `cmp`** — more portable for content comparison
- **Avoid `realpath`** — not available on macOS by default. Use `cd "$(dirname "$0")" && pwd`
- **Avoid `timeout` in user-facing scripts** — not available on macOS. Use for CI/eval only
- **Path separators**: bash on Windows handles `/` fine. Never hardcode `\`
- **Line endings**: add `.gitattributes` with `*.sh text eol=lf` to prevent CRLF corruption

## mise.toml pattern for Windows compatibility

```toml
# Passthrough tasks (user provides all args after --)
[tasks.init]
raw = true
run = "bash tools/generator/init.sh"

# Tasks with defined args (mise parses, script receives)
[tasks.generate]
usage = 'arg "[tool]" default="kiro-cli"'
run = "bash tools/generator/generate.sh ${usage_tool?}"
```
