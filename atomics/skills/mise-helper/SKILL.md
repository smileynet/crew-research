---
name: mise-helper
description: "Configure and use mise (tool version manager + task runner + env manager). Use when writing mise.toml, adding tools, defining tasks, setting up environments, configuring CI with mise, choosing backends, or troubleshooting mise. Trigger: mise, mise.toml, tool versions, mise tasks, mise run, mise use, mise activate, mise watch, mise lock."
metadata:
  type: reference
  invocation: both
  practice: null
---

# mise Helper

mise combines tool version management + environment variables + task runner in one `mise.toml`.

## Quick Patterns

### Add a tool
```bash
mise use node@24              # local project
mise use -g python@3.12       # global
mise use --pin node@24.5.0    # exact version
```

### Define tasks
```toml
[tasks.test]
run = "pytest"
depends = ["lint"]
sources = ["src/**/*.py", "tests/**/*.py"]
```

### Set environment
```toml
[env]
NODE_ENV = "development"
_.file = ".env.local"
_.path = ["./bin"]
```

### Lockfile for reproducibility
```bash
mise settings lockfile=true
mise lock                     # generate mise.lock (commit this)
MISE_LOCKED=1 mise install    # strict mode for CI
```

## Backend Selection

| Need | Backend | Example |
|------|---------|---------|
| Language runtime | core | `node = "24"` |
| CLI tool (binary) | aqua/github | `"aqua:hashicorp/terraform" = "1.7"` |
| Rust crate | cargo | `"cargo:eza" = "latest"` |
| Python CLI | pipx | `"pipx:black" = "latest"` |
| Node package | npm | `"npm:prettier" = "3"` |
| Go module | go | `"go:github.com/user/tool" = "latest"` |

## Activation

```bash
# Interactive shells (~/.zshrc)
eval "$(mise activate zsh)"
# IDEs/scripts (~/.zprofile)
eval "$(mise activate zsh --shims)"
```

## Key Commands

| Command | Purpose |
|---------|---------|
| `mise use <tool>` | Install + activate + write config |
| `mise run <task>` | Run a task |
| `mise watch <task>` | Re-run on file changes |
| `mise doctor` | Diagnose issues |
| `mise trust` | Trust config (required for hooks/env) |
| `mise lock` | Generate/update lockfile |
| `mise ls` | List installed tools |
| `mise prune` | Remove unused versions |

## References (load as needed)

- Configuration system, settings, merge rules → [references/configuration.md](references/configuration.md)
- Task runner (TOML + file tasks, deps, watch) → [references/task-runner.md](references/task-runner.md)
- Environment variables, templates, profiles → [references/environments.md](references/environments.md)
- Backends, registry, choosing the right one → [references/backends-registry.md](references/backends-registry.md)
- Security: trust, lockfiles, paranoid/safe → [references/security.md](references/security.md)
- Language-specific (Python, Node, Ruby, Go, Rust, Java) → [references/languages.md](references/languages.md)
- IDE + CI/CD integration → [references/ide-cicd.md](references/ide-cicd.md)
- Advanced: monorepos, onboarding, performance → [references/advanced-patterns.md](references/advanced-patterns.md)

Does NOT cover: writing mise plugins from scratch, mise internals/contributing.
