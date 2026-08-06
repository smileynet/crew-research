# mise Configuration

> https://mise.jdx.dev/configuration.html · https://mise.jdx.dev/configuration/settings.html

## Config File Locations (highest → lowest precedence within a directory)

1. `mise.local.toml` — local overrides (gitignored)
2. `mise.toml` — primary project config
3. `.mise/config.toml` or `.config/mise.toml`
4. `.config/mise/conf.d/*.toml` — fragments (alphabetical)

**Global:** `~/.config/mise/config.toml`
**System:** `/etc/mise/config.toml`

Use `mise config ls` to see what's loaded.

## Hierarchy & Merge

```
/etc/mise/config.toml         → System (all users, lowest)
~/.config/mise/config.toml    → Global (user default)
~/work/mise.toml              → Workspace
~/work/project/mise.toml      → Project
~/work/project/sub/mise.toml  → Sub-project (highest)
```

| Section | Merge strategy |
|---------|---------------|
| `[tools]` | Additive — child overrides parent for same tool |
| `[env]` | Additive — child overrides parent for same var |
| `[tasks]` | Completely replaced per task name |
| `[settings]` | Additive with overrides |

## Complete Config Example

```toml
min_version = "2024.11.1"

[tools]
node = "24"
python = { version = "3.12", postinstall = "pip install -r requirements.txt" }
"npm:prettier" = "3"
"github:BurntSushi/ripgrep" = "latest"

[env]
NODE_ENV = "development"
DATABASE_URL = "postgres://localhost/myapp"
_.file = ".env.local"
_.path = ["./node_modules/.bin"]

[tasks.dev]
run = "npm run dev"

[tasks.test]
run = "pytest"
depends = ["lint"]

[settings]
lockfile = true
idiomatic_version_file_enable_tools = ["node", "python"]

[hooks]
enter = "mise i -q"
```

## Key Settings

| Setting | Env var | Default | Purpose |
|---------|---------|---------|---------|
| `lockfile` | `MISE_LOCKFILE` | unset | Enable mise.lock |
| `locked` | `MISE_LOCKED` | false | Fail if lockfile missing URLs (CI) |
| `paranoid` | `MISE_PARANOID` | false | Content-hash trust, HTTPS-only |
| `safe` | `MISE_SAFE` | false | Block all code execution from config |
| `trusted_config_paths` | `MISE_TRUSTED_CONFIG_PATHS` | [] | Auto-trust configs under these dirs |
| `idiomatic_version_file_enable_tools` | — | [] | Read .nvmrc/.python-version |
| `minimum_release_age` | `MISE_MINIMUM_RELEASE_AGE` | "24h" | Skip brand-new releases |
| `jobs` | `MISE_JOBS` | 8 | Parallel install jobs |
| `experimental` | `MISE_EXPERIMENTAL` | false | Enable beta features |
| `auto_install` | `MISE_AUTO_INSTALL` | true | Auto-install missing tools |
| `pin` | `MISE_PIN` | false | Default `--pin` for `mise use` |

## Profiles (MISE_ENV)

Load environment-specific config alongside base:

```bash
MISE_ENV=production mise run deploy
mise -E staging run build
```

Priority (top wins):
1. `mise.{env}.local.toml`
2. `mise.local.toml`
3. `mise.{env}.toml`
4. `mise.toml`

Set default env via `.miserc.toml`:
```toml
# .miserc.toml (commit this — loaded before everything)
env = ["development"]
```

Platform auto-detection (`auto_env = true` in `.miserc.toml`):
- `mise.macos.toml`, `mise.linux-arm64.toml`, etc.

## Write Targets

`mise use`, `mise set` write to the lowest-precedence file in the highest-precedence directory:
```bash
mise use node@22                    # writes to mise.toml
mise use --env local node@20        # writes to mise.local.toml
mise use -g python@3.12             # writes to global config
```

## min_version

```toml
min_version = "2024.11.1"                        # hard error
min_version = { hard = "2024.11.1" }             # same
min_version = { soft = "2024.9.0" }              # warning only
min_version = { hard = "2024.11.1", soft = "2024.9.0" }
```

## Important MISE_* Environment Variables

| Variable | Purpose |
|----------|---------|
| `MISE_ENV` | Load env-specific config |
| `MISE_TRUSTED_CONFIG_PATHS` | Auto-trust (colon-separated) |
| `MISE_DATA_DIR` | Tool installs (`~/.local/share/mise`) |
| `MISE_CACHE_DIR` | Cache location |
| `MISE_${TOOL}_VERSION` | Override any tool version |
| `MISE_OFFLINE` | Never make HTTP requests |
| `MISE_LOG_LEVEL` | trace/debug/info/warn/error |

## Useful Commands

```bash
mise config ls            # show loaded config files + precedence
mise settings             # show all current settings
mise settings set key=val # set a setting
mise trust                # trust current config
mise fmt                  # format mise.toml files
```
