---
id: "100"
title: "Deprecate Python recall in favor of Rust rewrite (~/code/recall)"
status: open
blocked_by: []
priority: high
---

# Deprecate Python recall in favor of Rust rewrite

## Context

The Rust recall binary (`~/code/recall`, v0.2.0) is deployed, running, and fully replaces
the Python implementation at `tools/recall/`. The Python version is dead code that:
- Confuses new users (two install paths: `uv tool install ./tools/recall` vs `cargo install`)
- Creates maintenance burden (tests, deps, proofs all reference it)
- Blocks the skill import protocol (ticket 98) — recall should own its skill from its own repo

## What to build

Deprecate and remove `tools/recall/`, migrate all references to the Rust binary, and handle
deployments that still have the Python version installed.

### Phase 1: Migration detection in doctor.sh

Add a check that detects the Python recall and guides migration:

```
Known tools:
  ⚠️  recall: Python version detected (uv tool) — migrate to Rust binary
      Run: uv tool uninstall recall && cargo install --path ~/code/recall
      Or:  cargo install recall (after crates.io publish)
```

Detection: `recall --version` output. The Rust version prints `recall X.Y.Z`; the Python
version prints differently (check format). Or: detect via `which recall` → if path contains
`.local/share/uv/tools/`, it's Python.

### Phase 2: Update all references

| File | Current (Python) | New (Rust) |
|------|-----------------|------------|
| `AGENTS.md` | `tools/recall/` workspace layout, `uv run --directory tools/recall`, `uv tool install ./tools/recall` | `cargo install recall` (or `cargo install --path ~/code/recall`), remove workspace layout entries |
| `README.md` | `uv tool install ./tools/recall` | `cargo install recall` |
| `.kiro/steering/user-setup-guide.md` | Multiple `uv tool install ./tools/recall` references, Windows PowerShell paths, bashrc-hook.sh | Rust binary install (`cargo install`), recall's own hook scripts from its repo |
| `mise.toml` | `uv run --directory tools/recall` for test:recall, proof:recall, recall:ingest | Direct `recall` binary invocations |
| `tools/generator/init.sh` | Extension detection logic (checks for `recall` on PATH — this already works with Rust) | No change needed (already binary-agnostic) |

### Phase 3: Move helper scripts ownership

These scripts in `tools/recall/` should move to the recall repo:
- `ingest-all.sh` — scheduled ingestion (Linux/macOS)
- `Invoke-RecallIngestAll.ps1` — scheduled ingestion (Windows)
- `bashrc-hook.sh` — shell staleness hook (Linux/macOS)
- `profile-hook.ps1` — PowerShell staleness hook (Windows)

The Rust recall repo already has context for these (its AGENTS.md references the scheduled
task). Moving them there makes recall fully self-contained.

### Phase 4: Remove Python code

After phases 1-3 ship and soak:
1. Delete `tools/recall/` directory (pyproject.toml, recall/, tests/, uv.lock)
2. Remove `test:recall` and `proof:recall` mise tasks (tests live in recall repo now)
3. Update `compositions/tiers/` if any reference the Python recall path
4. Keep `recall:ingest` mise task but point at the binary directly

### Phase 5: Handle existing deployments

Users who installed via `uv tool install ./tools/recall`:
1. **doctor.sh detects** Python recall and prints migration instructions
2. **The Python recall still works** until they migrate (no forced breakage)
3. **Next `mise run init`** prints a one-time deprecation notice:
   ```
   ⚠️  Python recall is deprecated. The Rust binary is 10x faster and fully compatible.
       Migrate: uv tool uninstall recall && cargo install --path ~/code/recall
   ```
4. **Scheduled tasks**: Users with `RecallIngest` pointing at Python need to update.
   doctor.sh should detect and advise.
5. **Database is compatible** — Rust recall reads the same SQLite DB (same schema, same
   embeddings). No data migration needed.

## Acceptance criteria

- [ ] doctor.sh detects Python recall and prints migration guidance
- [ ] All AGENTS.md/README/steering references updated to Rust install path
- [ ] mise.toml tasks work with Rust binary (no `uv run --directory tools/recall`)
- [ ] Helper scripts (ingest-all, hooks) moved to recall repo or documented as recall-owned
- [ ] `tools/recall/` directory removed
- [ ] Existing Python recall deployments still function (graceful deprecation, not breakage)
- [ ] Scheduled task detection in doctor.sh (warns if pointing at Python)

## Migration matrix

| User state | What happens | Action needed |
|-----------|-------------|---------------|
| Python recall via `uv tool install` | doctor warns, recall still works | Run migration command |
| Rust recall via `cargo install` | ✅ No action | — |
| No recall installed | init.sh suggests `cargo install` (not uv) | Install Rust version |
| Scheduled task pointing at Python | doctor warns with fix command | Update task action |
| bashrc-hook sourcing crew-research path | Still works (script stays readable) | Update to recall-repo path eventually |

## Out of scope

- Recall feature work (ticket 36, 38, etc.)
- Publishing to crates.io (recall repo ticket 30)
- Removing recall from known-tools.yaml (it stays — it's the Rust binary now)
