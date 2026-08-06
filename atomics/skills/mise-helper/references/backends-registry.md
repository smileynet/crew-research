# mise Backends & Registry

> https://mise.jdx.dev/dev-tools/backends/ · https://mise.jdx.dev/registry.html

## Decision Guide

```
Is it a programming language runtime?
  → Use CORE (node, python, go, ruby, rust, java, etc.)

Is it a CLI tool with prebuilt binaries?
  → `mise registry | grep <name>`
    → Found as aqua: → use shorthand or aqua:owner/repo
    → Found as github: → use github:owner/repo
    → Not found → use github:owner/repo directly

Is it a language ecosystem tool?
  → Rust crate → cargo:name
  → Python CLI → pipx:name
  → Node package → npm:name
  → Go module → go:module/path
  → Ruby gem → gem:name

Needs complex install logic or env vars?
  → vfox plugin (or asdf if no alternative)
```

## Backend Types

### Core (Built-in, Fastest)

12 tools compiled into mise binary. No plugins, no network for discovery.

**Tools:** Bun, Deno, Elixir, Erlang, Go, Java, Node.js, Python, Ruby, Rust, Swift, Zig

```toml
[tools]
node = "24"
python = "3.12"
go = "1.22"
```

> https://mise.jdx.dev/core-tools.html

### Aqua (Preferred for CLI tools)

Downloads prebuilt binaries with security verification (cosign, SLSA, minisign, checksums). Registry baked into mise — no plugins needed.

```toml
[tools]
"aqua:hashicorp/terraform" = "1.7"
"aqua:BurntSushi/ripgrep" = "latest"
terraform = "1.7"                      # shorthand via registry
```

> https://mise.jdx.dev/dev-tools/backends/aqua.html

### GitHub (Preferred when not in aqua)

Downloads from GitHub Releases directly. Provenance verification available.

```toml
[tools]
"github:cli/cli" = "latest"
"github:docker/compose" = "latest"
```

> https://mise.jdx.dev/dev-tools/backends/github.html

### Cargo (Rust Crates)

Uses `cargo install` or `cargo-binstall` (auto-detected, faster).

```toml
[tools]
"cargo:eza" = "latest"
"cargo:cargo-edit" = { version = "latest", features = "add" }
```

Requires `cargo` on PATH. Install: `mise use -g rust`

> https://mise.jdx.dev/dev-tools/backends/cargo.html

### Go

```toml
[tools]
"go:github.com/golangci/golangci-lint/cmd/golangci-lint" = "latest"
"go:github.com/DarthSim/hivemind" = "latest"
```

Requires `go` on PATH. Install: `mise use -g go`

> https://mise.jdx.dev/dev-tools/backends/go.html

### npm

Embedded aube installer — **no node/npm required** for installation.

```toml
[tools]
"npm:prettier" = "3"
"npm:@biomejs/biome" = "latest"
"npm:typescript" = "5"
```

> https://mise.jdx.dev/dev-tools/backends/npm.html

### pipx (Python CLIs)

Isolated virtualenvs via `uv tool install` (preferred) or `pipx`.

```toml
[tools]
"pipx:black" = "latest"
"pipx:ansible-core" = { version = "latest", uvx_args = "--with ansible" }
"pipx:harlequin" = { version = "latest", extras = "postgres,s3" }
```

Requires `uv` or `pipx` on PATH.

> https://mise.jdx.dev/dev-tools/backends/pipx.html

### Vfox (Modern Plugin System)

Lua-based, cross-platform (Windows!), built-in HTTP/JSON/HTML modules.

```toml
[tools]
"vfox:version-fox/vfox-cmake" = "latest"
```

Recommended over asdf for new plugins.

> https://mise.jdx.dev/dev-tools/backends/vfox.html

### asdf (Legacy)

Shell-script plugins. Still works but **not recommended for new tools** — supply chain risk.

```toml
[tools]
"asdf:owner/plugin" = "latest"
```

> https://mise.jdx.dev/dev-tools/backends/asdf.html

### Other Backends

| Backend | Purpose | Example |
|---------|---------|---------|
| conda | Conda packages (no conda needed) | `"conda:ffmpeg"` |
| dotnet | .NET tools | `"dotnet:tool"` |
| gem | Ruby gems | `"gem:bundler"` |
| gitlab | GitLab releases | `"gitlab:owner/repo"` |
| http | Direct URL downloads | `"http:flutter"` |
| spm | Swift packages | `"spm:owner/repo"` |

## The Registry

Maps short names to full backend:identifier:

```bash
mise registry                # browse all (~1000+ tools)
mise registry node           # info about specific tool
mise search ripgrep          # search
```

### Resolution Order

When multiple backends exist for a tool, priority:
1. aqua, github, gitlab (preferred — no plugins, secure)
2. conda
3. pipx, npm, gem, go, cargo, dotnet (require runtime)
4. asdf, vfox (not accepted for new entries)

### Disabling Backends

```bash
mise settings add disable_backends asdf    # disable asdf entirely
```

Override backend for specific tool:
```bash
export MISE_BACKENDS_PHP='vfox:mise-plugins/vfox-php'
```

## Performance Comparison

| Backend | Version listing | Installation | Windows |
|---------|----------------|-------------|---------|
| core | Instant (Rust) | Direct download | ✅ |
| aqua/github | HTTP call | Download + extract | ✅ |
| cargo | HTTP to crates.io | Compile/binstall | ✅ |
| npm/pipx | HTTP to registry | Install | ✅ |
| asdf | Clone + script | Clone + bash | ❌ |
| vfox | HTTP + Lua | Download via Lua | ✅ |

## Tool Options

```toml
[tools]
# OS filtering
ripgrep = { version = "latest", os = ["linux", "macos"] }

# Postinstall hooks
python = { version = "3.12", postinstall = "pip install ansible" }

# Install env vars
node = { version = "24", install_env = { CFLAGS = "-O2" } }

# Depends on another tool
"pipx:ruff" = { version = "latest", depends = ["python"] }
```
