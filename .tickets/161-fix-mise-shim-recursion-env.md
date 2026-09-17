---
id: "161"
title: "Fix mise shim recursion + usage arg non-expansion on Windows (tkt/mise run unusable via shim)"
status: in_progress
blocked_by: []
priority: high
---

# Fix mise shim recursion + usage arg non-expansion on Windows

## Intent source

Surfaced repeatedly this session (tickets 154/157/159 work). `tkt <cmd>` on PATH fails with
`mise-shim: recursive shim invocation detected for mise`; worked around all session by calling
the real binary `D:\dev-tools\cargo\bin\tkt.exe` directly. High priority: it makes the primary
ticket CLI and `mise run` unreliable from a normal shell on this machine.

## Diagnosis (verified 2026-09-17)

**Issue 1 — shim recursion (primary).** PATH ordering puts the mise SHIM dir before the real
mise binary:

```
tkt   → C:\Users\uosmi\AppData\Local\mise\shims\tkt.exe        (shim, resolves first)
        D:\dev-tools\cargo\bin\tkt.exe                          (real binary, later)
mise  → C:\Users\uosmi\AppData\Local\mise\shims\mise.exe        (shim, resolves FIRST)
        C:\Users\uosmi\AppData\Local\Microsoft\WinGet\Links\mise.exe   (real, winget 2026.8.10)
        D:\dev-tools\cargo\bin\mise.exe                          (real, cargo 2026.8.5)
```

When the `tkt` shim shells out to `mise` to resolve the real tkt, PATH finds the mise SHIM
again (not the real mise) → the recursion guard trips → the command fails. Root cause: the
shim directory precedes the real mise on PATH, so shims can't reach the real binary.

Both real binaries work directly, and the real mise resolves tkt correctly:
```
mise which tkt → D:\dev-tools\cargo\bin\tkt.exe   ✓
```

**Issue 2 — usage arg non-expansion (same layer).** `mise run generate -- kiro-cli` emitted a
literal `$usage_tool` instead of expanding it. The task uses a mise `usage` spec
(`bash tools/generator/generate.sh generate --tool ${usage_tool:-kiro-cli}`); the positional
didn't populate. Likely the same mise install/version inconsistency (two mise versions: winget
2026.8.10 vs cargo 2026.8.5). Cosmetic here (validate still passed) but symptomatic.

## What to build (environment fix — reversible)

1. **Resolve the double mise install + PATH order.** Pick ONE real mise (recommend the winget
   one, 2026.8.10 — newer) and ensure its directory (and the shims dir configured to point at
   it) resolves BEFORE the stale one. Options:
   - Reorder user PATH so the real mise binary dir precedes the shim dir, OR
   - Uninstall/remove the stale cargo mise (`D:\dev-tools\cargo\bin\mise.exe`) so only one real
     mise exists for shims to delegate to, OR
   - Re-run `mise activate` / `mise reshim` so the shims point at the correct real mise.
2. **Verify shims delegate correctly:** `tkt --version` from a fresh shell must succeed (no
   recursion error) and resolve to `D:\dev-tools\cargo\bin\tkt.exe`.
3. **Verify `mise run` arg passing:** `mise run generate -- codex` must expand `usage_tool` to
   `codex` (no literal `$usage_tool`).
4. **Document the fix** in the setup guide / tool-installation skill (Windows section) so a
   future machine with two mise installs + cargo-on-D: hits the documented recipe, not a wall.
   Note the `D:\dev-tools\cargo\bin` relocation (cargo home moved off C:) as the trigger
   condition.

## Acceptance criteria

- [ ] `tkt --version` (bare, via PATH) succeeds from a fresh shell — no recursive-shim error
- [ ] `tkt ready` works via PATH (no direct-binary workaround needed)
- [ ] `mise run generate -- codex` expands the tool arg (no literal `$usage_tool`)
- [ ] Exactly one real mise is authoritative (PATH order or stale install removed) — documented which
- [ ] Windows setup guidance updated (user-setup-guide.md or tool-installation skill) with the fix + trigger condition (double mise install / relocated cargo bin)

## Out of scope

- Any repo task-logic change (the tasks are correct; this is an env/PATH problem)
- The activation-detection harness bug (ticket 160 — separate env issue)
- Changing the `.mise.local.toml` CREW_ENV designation

## Notes

- Workaround used all session: `& "D:\dev-tools\cargo\bin\tkt.exe" <cmd>` (bypasses the shim).
- This is a machine-local environment fix; the DOC update is the only repo-tracked deliverable.
  If the fix is purely PATH/uninstall (no repo change), close with the doc update + verified
  bare `tkt`/`mise run` as evidence.
