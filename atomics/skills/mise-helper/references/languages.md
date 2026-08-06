# mise Language-Specific Features

> https://mise.jdx.dev/lang/

## Python

> https://mise.jdx.dev/lang/python.html

```toml
[tools]
python = "3.12"
# Multiple versions
python = ["3.11", "3.12"]
```

### Virtualenv Integration

**For uv projects** (has `uv.lock`):
```toml
[settings]
python.uv_venv_auto = "create|source"   # auto-create + activate
```

**For non-uv projects:**
```toml
[env]
_.python.venv = { path = ".venv", create = true }
# With pip seed:
_.python.venv = { path = ".venv", create = true, uv_create_args = ["--seed"] }
```

### Recommended: mise + uv

mise handles "which Python", uv handles "which packages":

```toml
[tools]
python = "3.12"
uv = "latest"

[env]
UV_PYTHON = { value = "{{ tools.python.path }}", tools = true }
```

### Key Settings

| Setting | Default | Purpose |
|---------|---------|---------|
| `python.compile` | false | Force compile vs precompiled |
| `python.uv_venv_auto` | — | Venv integration mode |
| `python.precompiled_arch` | auto | CPU architecture |
| `python.venv_stdlib` | false | Prefer stdlib venv over uv |

### Gotchas

- Precompiled binaries downloaded by default (fast). Set `python.compile=true` for custom builds.
- `uv_venv_auto = true` is deprecated → use `"source"` or `"create|source"`
- Default packages files deprecated → use `pipx:` backend or `postinstall`

---

## Node.js

> https://mise.jdx.dev/lang/node.html

```toml
[tools]
node = "24"
"npm:typescript" = "latest"
"npm:prettier" = "3"
```

### Corepack (yarn/pnpm)

```toml
[settings]
node.corepack = true    # install corepack shims after node install
```

### Idiomatic Files

Read `.nvmrc`, `.node-version`, `package.json` `devEngines`:
```bash
mise settings add idiomatic_version_file_enable_tools node
```

### Key Settings

| Setting | Default | Purpose |
|---------|---------|---------|
| `node.corepack` | false | Enable corepack shims |
| `node.compile` | false | Build from source |
| `node.mirror_url` | nodejs.org | Custom mirror |
| `node.flavor` | — | `musl`, `glibc-217` |

### Gotchas

- `nodejs` auto-renamed to `node`
- Default packages file deprecated → use `npm:` backend or `postinstall`
- Unofficial builds: set `node.mirror_url = "https://unofficial-builds.nodejs.org/download/release/"`

---

## Ruby

> https://mise.jdx.dev/lang/ruby.html

```toml
[tools]
ruby = "3.3"
"gem:bundler" = "latest"
"gem:rubocop" = "latest"
```

### Precompiled Binaries

Default — downloads from jdx/ruby. Available for macOS arm64, Linux arm64/x64.

```toml
[settings]
ruby.compile = false    # precompiled only (fail if unavailable)
# unset = try precompiled first, fall back to ruby-build
```

### Idiomatic Files

```bash
mise settings add idiomatic_version_file_enable_tools ruby
# Reads .ruby-version and Gemfile ruby version
```

### Gotchas

- Build revisions (e.g., `3.3.11-1`) — use `mise.lock` for reproducibility
- Default gems file deprecated → use `gem:` backend or `postinstall`

---

## Go

> https://mise.jdx.dev/lang/go.html

```toml
[tools]
go = "1.22"
"go:github.com/golangci/golangci-lint/cmd/golangci-lint" = "latest"
```

### GOROOT/GOBIN

```toml
[settings]
go.set_goroot = true    # auto-set GOROOT (default)
go.set_gobin = true     # override GOBIN to mise install dir
```

### Gotchas

- **Go ≤1.20:** Must use `prefix:` — `go = "prefix:1.20"` (Go released 1.20 without .0)
- Go 1.21+ works normally: `go = "1.21"`
- Default packages file deprecated → use `go:` backend or `postinstall`

---

## Rust

> https://mise.jdx.dev/lang/rust.html

Uses rustup under the hood. Toolchains live in `~/.rustup`, not mise's install dir.

```toml
[tools]
rust = "1.83"
# With components and targets
rust = { version = "1.83", components = ["rust-src", "llvm-tools"], targets = ["wasm32-unknown-unknown"] }
# Profile
rust = { version = "1.83", profile = "minimal" }
```

### Isolation

Set `MISE_RUSTUP_HOME` and `MISE_CARGO_HOME` to isolate from system rustup/cargo.

### Gotchas

- mise installs rustup if not present, then installs the toolchain
- Components added to existing toolchains on `mise install`
- `cargo:` backend tools require `cargo` on PATH (install rust first)

---

## Java

> https://mise.jdx.dev/lang/java.html

```toml
[tools]
java = "temurin-21"     # or openjdk-21, zulu-21, corretto-21
java = "21"             # uses default vendor (openjdk)
```

### Multi-vendor Support

```bash
mise use -g java@temurin-21
mise use -g java@zulu-21
mise use -g java@corretto-21
```

Change default: `mise settings java.shorthand_vendor=temurin`

### JAVA_HOME

Auto-set by `mise activate`. Requires shell activation (not shims alone).

### .sdkmanrc Support

mise reads `.sdkmanrc` and maps versions:
- `20.0.2-tem` → `temurin-20.0.2`
- `11.0.12-zulu` → `zulu-11`

### Gradle Workaround

Gradle doesn't auto-detect mise installs:
```bash
ln -s ~/.local/share/mise/installs/java ~/.asdf/installs/java
```

---

## Common Patterns Across Languages

### Backend-Based Tool Installation (Replaces Default Packages)

```toml
[tools]
"npm:typescript" = "latest"     # Node
"pipx:black" = "latest"        # Python
"gem:rubocop" = "latest"       # Ruby
"go:golang.org/x/tools/gopls" = "latest"  # Go
"cargo:ripgrep" = "latest"     # Rust
```

### Postinstall Hooks

```toml
[tools]
python = { version = "3.12", postinstall = "pip install ansible" }
node = { version = "24", postinstall = "npm install -g typescript" }
ruby = { version = "3.3", postinstall = "gem install bundler" }
```

### Sync with Existing Managers

```bash
mise sync node --nvm        # import nvm versions
mise sync python --pyenv    # import pyenv versions
mise sync ruby --rbenv      # import rbenv versions
```

### Deprecation Notice

Default package files (`~/.default-npm-packages`, `~/.default-python-packages`, `~/.default-gems`, `~/.default-go-packages`) are **deprecated**:
- 2026.11.0: warnings begin
- 2027.11.0: support removed

Migrate to backends or `postinstall` hooks.
