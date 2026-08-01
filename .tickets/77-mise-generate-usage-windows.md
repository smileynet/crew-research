---
id: "77"
title: "Fix mise generate argument interpolation on Windows"
status: open
blocked_by: []
---

# Fix mise generate argument interpolation on Windows

## What to build

Fix the `[tasks.generate]` usage interpolation so its optional tool argument is
passed to `tools/generator/generate.sh` on Windows. Both documented forms failed
during ticket 75 validation: the long-option form is unsupported by the mise
task, while `mise run generate codex` passed the literal `$usage_tool?` to bash.

Keep the task interface aligned with the generator's supported tools; the
generator currently accepts `kiro-cli`, `claude-code`, or `all`, not `codex`.

## Acceptance criteria

- [ ] `mise run generate` uses its default tool successfully
- [ ] `mise run generate <supported-tool>` passes the selected tool on Windows
- [ ] Help text names only tools accepted by `generate.sh`
- [ ] AGENTS.md command examples match the working task interface
