---
id: "77"
title: "Fix mise generate argument interpolation on Windows"
status: done
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

- [x] `mise run generate` uses its default tool successfully
- [x] `mise run generate <supported-tool>` passes the selected tool on Windows
- [x] Help text names only tools accepted by `generate.sh`
- [x] AGENTS.md command examples match the working task interface

## Resolution (2026-08-11)

Changed usage_tool? to usage_tool:-kiro-cli in mise.toml, added --tool prefix. All forms work on Windows: default, explicit tool, all. AGENTS.md updated to match.
