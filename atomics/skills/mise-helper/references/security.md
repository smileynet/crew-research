# mise Security Model

> https://mise.jdx.dev/security.html · https://mise.jdx.dev/dev-tools/mise-lock.html · https://mise.jdx.dev/paranoid.html

## Trust Model

Config files that execute code require explicit trust before mise runs them.

### What Requires Trust

- Template `exec()` / `read_file()` expressions
- Hooks (cd, enter, leave, pre/postinstall)
- `[env]` values, `_.path`, `_.file`, `_.source`
- `[shell_alias]` entries
- asdf plugin scripts

### What Does NOT Require Trust (safe configs)

- `[tools]` with plain version strings
- `[tasks]` without templates
- `min_version`

### Trust Commands

```bash
mise trust                  # trust mise.toml in current/parent dir
mise trust --all            # trust everything in tree + subdirs
mise trust --show           # check trust status
mise untrust                # revoke trust
```

### Pre-Trusting

```toml
# ~/.config/mise/config.toml
[settings]
trusted_config_paths = ["~/code", "~/work"]
# Or set to ["/"] to trust everything
```

```bash
export MISE_TRUSTED_CONFIG_PATHS="~/code:~/work"
```

### Trust Behavior

- `mise use` auto-trusts the file it creates (no prompt for your own configs)
- Global/system configs are implicitly trusted
- `monorepo_root = true` trusts all descendant configs
- Trust persists across sessions (path-based, stored locally)
- Trust shared across git worktrees (except in paranoid mode)

## Lockfile System

`mise.lock` pins exact versions + checksums + download URLs.

### Enable & Generate

```bash
mise settings lockfile=true
mise lock                           # generate/update
mise lock --bump                    # re-resolve to latest
mise lock --bump node               # bump specific tool
mise lock --platform linux-x64,macos-arm64  # cross-platform
```

### Format

```toml
# mise.lock
[[tools.node]]
version = "24.5.0"
backend = "core:node"

[tools.node.platforms.linux-x64]
checksum = "sha256:abc123..."
size = 23456789
url = "https://nodejs.org/dist/v24.5.0/node-v24.5.0-linux-x64.tar.xz"

[tools.node.platforms.macos-arm64]
checksum = "sha256:def456..."
url = "https://nodejs.org/dist/v24.5.0/node-v24.5.0-darwin-arm64.tar.gz"
```

### Strict Mode (CI)

```bash
MISE_LOCKED=1 mise install    # fail if any tool lacks lockfile URL
```

Zero external API calls — install purely from lockfile data.

### Benefits

- Reproducible builds (exact versions + checksums)
- No GitHub API rate limits (URLs cached)
- Integrity verification (SHA256)
- Faster installs (skip version resolution)

### Commit Strategy

- ✅ Commit `mise.lock`
- ✅ Commit `mise.{env}.lock`
- ❌ Gitignore `mise.local.lock`

## Paranoid Mode

Extra security hardening: `MISE_PARANOID=1`

| Feature | Normal | Paranoid |
|---------|--------|----------|
| Config trust | Path-based (once) | Content-hash (re-trust on edit) |
| Community plugins | Short-name OK | Full git URL required |
| HTTP endpoints | Allowed for non-sensitive | Always HTTPS |
| Provenance | Trust lockfile entry | Re-verify every install |
| Worktree trust sharing | ✅ Enabled | ❌ Disabled |

## Safe Mode

Hard boundary against code execution: `MISE_SAFE=1`

**Blocks (errors, not silent):**
- Template `exec()` / `read_file()`
- Hooks, tasks
- asdf plugin scripts
- Plugin installation
- `_.source`

**Ignores (from project config only):**
- `[env]`, `_.path`, `_.file`
- `[shell_alias]`
- `[settings]` from project config

**Still works:**
- Version resolution (HTTP backends)
- `mise lock`, `mise ls`
- Global/system config still applies

Use case: automation against untrusted branches:
```bash
MISE_SAFE=1 mise lock --bump --json
```

## Aqua Security Verification

All enabled by default (native Rust — no external tools):

| Method | Setting | Default |
|--------|---------|---------|
| Checksums | Always | Cannot disable |
| Cosign signatures | `aqua.cosign` | true |
| SLSA provenance | `aqua.slsa` | true |
| GitHub attestations | `aqua.github_attestations` | true |
| Minisign | `aqua.minisign` | true |

> https://mise.jdx.dev/dev-tools/backends/aqua.html#security-verification

## Minimum Release Age

Supply-chain protection — skip brand-new releases:

```toml
[settings]
minimum_release_age = "7d"    # wait 7 days (default: 24h)
```

Per-tool override:
```toml
[tools.trivy]
version = "latest"
minimum_release_age = "1d"
```

## Security Escalation Ladder

| Need | Setting |
|------|---------|
| Basic reproducibility | `lockfile = true` |
| CI determinism | + `locked = true` |
| Supply chain protection | + `minimum_release_age = "7d"` |
| High security | + `paranoid = true` |
| Untrusted config automation | `MISE_SAFE=1` |

## Best Practices for Teams

1. **Commit `mise.lock`** — everyone gets same versions
2. **Use `MISE_LOCKED=1` in CI** — deterministic, no API calls
3. **Prefer aqua backend** — security verification built-in
4. **Set `minimum_release_age`** — avoid compromised fresh releases
5. **Pin mise version in CI** — predictable behavior
6. **Use `mise.local.toml` for secrets** — keep out of git

## Threat Surface by Backend

| Backend | Checksum | Provenance | Risk |
|---------|----------|------------|------|
| aqua | ✅ | ✅ cosign/SLSA/attestations | Low |
| github | ✅ | ✅ attestations | Low |
| core (node, python) | ✅ | ✅ OpenPGP | Low |
| http | ✅ | ❌ | Medium |
| asdf | ❌ | ❌ Plugin scripts execute | Higher |
| npm, cargo, pipx | Delegated | ❌ | Medium |
