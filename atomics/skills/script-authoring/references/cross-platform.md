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


## Bash parsing pitfalls

### IFS and empty fields

`IFS=$'\t' read -r` (and any whitespace IFS) **collapses consecutive delimiters**. Empty fields between two tabs vanish silently:

```bash
# BROKEN: empty field 3 disappears, field 4 lands in var 3
input="a\tb\t\td"
IFS=$'\t' read -r v1 v2 v3 v4 <<< "$(printf '%b' "$input")"
# v1=a, v2=b, v3=d, v4=""  ← WRONG

# FIX: use a non-whitespace delimiter
input="a|b||d"
IFS="|" read -r v1 v2 v3 v4 <<< "$input"
# v1=a, v2=b, v3="", v4=d  ← CORRECT
```

When using `yq` to extract multiple fields for shell consumption: use `join("|")` with `IFS="|"`, not `@tsv` with `IFS=$'\t'`. Any field that can be empty will cause silent misalignment with `@tsv`.

Incident: ticket 65 (2026-07-27) — skill names landed in the adapters variable, causing 30/39 defs to incorrectly SKIP during dry-run.
