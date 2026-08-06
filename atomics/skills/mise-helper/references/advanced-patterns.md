# mise Advanced Patterns

> https://mise.jdx.dev/tips-and-tricks.html · https://mise.jdx.dev/tasks/monorepo.html · https://mise.jdx.dev/faq.html

## Monorepo Patterns

### Enable Monorepo Mode

```toml
# /myproject/mise.toml
monorepo_root = true

[monorepo]
config_roots = [
    "packages/frontend",
    "packages/backend",
    "services/*",
]

[tools]
node = "24"    # shared across all config_roots
```

### Task Namespacing

Tasks auto-namespace by path:
```bash
mise //packages/frontend:build      # absolute from root
mise //packages/backend:test
mise //...:test                     # run 'test' in ALL subdirectories
mise //services/...:build           # build all services
cd packages/frontend && mise :build # relative to current config_root
```

### Per-Directory Overrides

```toml
# /myproject/packages/frontend/mise.toml
[tools]
node = "22"     # overrides root's node 24

[env]
PORT = "3000"   # adds to root's env

[tasks.build]
run = "npm run build"
```

### CI: Install All Monorepo Tools

```bash
mise install --monorepo    # union of all config_roots' tools
```

---

## Team Onboarding

### Committed Bootstrap Script

```bash
mise generate bootstrap --localize --write bin/mise
mise generate task-stubs --mise-bin ./bin/mise
# Contributors run: ./bin/test (no global mise needed)
```

### Machine Bootstrapping

```toml
[bootstrap.packages]
"brew:postgresql@17" = "latest"

[bootstrap.repos]
"~/src/dotfiles" = { url = "git@github.com:me/dotfiles.git", ref = "main" }

[bootstrap.mise_shell_activate]
zshrc = "activate"
```

```bash
mise bootstrap --yes    # one command: new laptop → ready
```

### Auto-Install on Enter

```toml
[hooks]
enter = "mise i -q"    # silently install missing tools on cd
```

---

## Environment Layering

### Full Stack

```
mise.toml                    # shared base (committed)
mise.development.toml        # dev overrides (committed)
mise.production.toml         # prod config (committed)
mise.local.toml              # personal secrets (gitignored)
mise.development.local.toml  # personal dev overrides (gitignored)
```

### Secret Pattern

```toml
# mise.toml (committed)
[env]
DATABASE_URL = { required = "Set in mise.local.toml" }
API_KEY = { required = true }
```

```toml
# mise.local.toml (gitignored)
[env]
DATABASE_URL = "postgres://user:pass@host/db"
API_KEY = "sk-real-key"
```

---

## Performance Optimization

### Lockfiles Avoid API Calls

```bash
mise settings lockfile=true
mise lock
# Future installs skip GitHub/registry API calls entirely
```

### cargo-binstall (Auto-Used)

If `cargo-binstall` is installed, mise uses it for `cargo:` tools — binary download instead of compile.

### Environment Caching

```toml
[settings]
env_cache = true
env_cache_ttl = "1h"    # cache computed env to disk (encrypted)
```

### CI Cache Strategy

- ✅ Cache `~/.local/share/mise/installs/` (actual tools)
- ❌ Don't cache `~/.cache/mise/` (short-lived)
- Key by `mise.lock` hash

### Minimal Shell Latency

`mise hook-env` exits early when nothing changed (~4ms no-change). For zero latency:
```bash
eval "$(mise activate zsh --shims)"    # no per-prompt hook
```

Trade-off: no hooks, no env vars from `[env]`.

---

## Integration Patterns

### Docker (Build with mise, Deploy Without)

```dockerfile
FROM debian:13-slim AS builder
RUN curl https://mise.run | sh
ENV PATH="/root/.local/share/mise/shims:$PATH"
COPY mise.toml mise.lock ./
RUN mise install
COPY . .
RUN mise run build

FROM debian:13-slim
COPY --from=builder /app/dist /app
CMD ["/app/server"]
```

### Pre-Commit Hooks

```bash
mise generate git-pre-commit --write --task=lint
```

### Shebang Usage (No Config Needed)

```typescript
#!/usr/bin/env -S mise x node@20 -- node
console.log(`Running: ${process.version}`);
```

### direnv Coexistence

If you must use both (not recommended):
```bash
# .envrc — use mise env instead of full activation
eval "$(mise env)"
```

---

## Common Gotchas

| Gotcha | Solution |
|--------|----------|
| `mise install` doesn't activate tools | Use `mise use` (install + activate + config) |
| `mise use` writes to parent mise.toml | Use `--path mise.toml` to force current dir |
| .nvmrc/.python-version not read | `mise settings add idiomatic_version_file_enable_tools node` |
| Trust prompts annoying | `trusted_config_paths = ["~/code"]` |
| Hooks don't fire | Requires `mise activate` (not shims-only) |
| IDE can't find tools | Add `eval "$(mise activate zsh --shims)"` to `~/.zprofile` |
| `mise activate` in scripts | Won't work — use `mise exec` or `mise run` |
| `latest` = latest installed | Use `mise upgrade` to get newest remote |
| git shows mise.toml untracked | Use `mise.local.toml` (gitignored) for personal config |
| Shorthand `mise test` conflicts | Don't use in scripts — use `mise run test` |

## When NOT to Use mise

| Environment | Use instead |
|-------------|-------------|
| Production runtime | Container images |
| System libraries (libssl, zlib) | OS package manager (apt/brew) |
| Complex build DAGs | Make/just (mise can wrap them) |
| Package management | uv (Python), npm (Node), bundler (Ruby) |
| True reproducibility | Nix/Devbox |

mise handles dev tools + env + tasks. It delegates to other tools for packages, system deps, and production.

---

## Useful Diagnostic Commands

```bash
mise config ls            # show loaded configs + precedence
mise doctor               # full health check
mise env                  # resolved environment
mise ls --current         # active tool versions
mise tool ripgrep         # info about a specific tool
mise cache clear          # reset caches
```
