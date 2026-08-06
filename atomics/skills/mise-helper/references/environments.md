# mise Environment Variables

> https://mise.jdx.dev/environments/ · https://mise.jdx.dev/templates.html · https://mise.jdx.dev/configuration/environments.html

## Basic [env] Section

```toml
[env]
# Set
NODE_ENV = "development"

# Unset
OLD_VAR = false

# Default (keep existing if set)
PORT = { default = "3000" }

# Required (fail if missing)
DATABASE_URL = { required = "Set in mise.local.toml or env" }

# Redacted (hidden from output)
SECRET = { value = "hunter2", redact = true }
```

## .env File Loading

```toml
[env]
# Single file
_.file = ".env"

# Multiple files (formats: .env, .json, .yaml, .toml)
_.file = [
    ".env",
    ".env.local",
    { path = ".secrets.env", redact = true },
]

# Load after tools are installed
_.file = { path = ".env", tools = true }
```

## PATH Manipulation

```toml
[env]
# Add directories to PATH
_.path = "./bin"
_.path = ["~/.local/bin", "{{config_root}}/node_modules/.bin", "tools/bin"]

# After tools installed (access tool env vars)
_.path = { path = ["{{env.GEM_HOME}}/bin"], tools = true }
```

Relative paths resolve against project root (config_root).

## Source Shell Scripts

```toml
[env]
_.source = "./setup-env.sh"
_.source = ["./base.sh", { path = ".secrets.sh", redact = true }]
```

Sourced as bash — exported vars and PATH changes captured.

## Tera Templates

```toml
[env]
# Shell command output
VERSION = "{{ exec(command='git describe --tags') | trim }}"
GIT_SHA = "{{ exec(command='git rev-parse HEAD', cache_key='sha', cache_duration='1h') }}"

# File content
APP_VER = "{{ read_file(path='VERSION') | trim }}"

# System info
ARCH = "{{ arch() }}"       # x64, arm64
OS = "{{ os() }}"           # linux, macos, windows
CPUS = "{{ num_cpus() }}"

# Env with default
PORT = "{{ get_env(name='PORT', default='3000') }}"

# Filters
PROJECT = "{{ cwd | basename }}"
CONFIG = "{{ [config_root, 'config.json'] | join_path }}"
SLUG = "{{ 'My Project' | kebabcase }}"
HASH = "{{ 'src/main.rs' | hash_file(len=8) }}"
```

### Template Variables

| Variable | Type | Description |
|----------|------|-------------|
| `env` | HashMap | Current environment |
| `cwd` | PathBuf | Current working directory |
| `config_root` | PathBuf | Directory containing mise.toml |
| `mise_bin` | String | Path to mise binary |
| `mise_env` | Vec | Active MISE_ENV values |
| `tools` | HashMap | Tool info (with `tools = true`) |

## Shell-Style Variable Expansion

Simpler alternative to Tera for referencing other vars:

```toml
[env]
BASE = "/opt/project"
LIB = "$BASE/lib"
PATH_EXT = "${LIB}:$LD_LIBRARY_PATH"
FALLBACK = "${MISSING:-default_value}"
```

## Tool-Dependent Values (Lazy Eval)

Access vars set by tools — evaluated after tool installation:

```toml
[env]
UV_PYTHON = { value = "{{ tools.python.path }}", tools = true }
NODE_VER = { value = "{{ tools.node.version }}", tools = true }
_.path = { path = ["{{env.GEM_HOME}}/bin"], tools = true }
```

## Profiles (MISE_ENV)

```bash
MISE_ENV=production mise run deploy
```

File priority (top wins):
1. `mise.production.local.toml`
2. `mise.local.toml`
3. `mise.production.toml`
4. `mise.toml`

Multiple: `MISE_ENV=ci,test` (last wins on conflicts).

Set default in `.miserc.toml`:
```toml
env = ["development"]
```

### Platform Auto-Detection

In `.miserc.toml`:
```toml
auto_env = true
```

Auto-loads `mise.macos.toml`, `mise.linux-arm64.toml`, etc.

## Secrets Patterns

### Pattern 1: Required + Local File (simplest)

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

### Pattern 2: sops + age (encrypted files)

```bash
mise use -g sops age
age-keygen -o ~/.config/mise/age.txt
sops encrypt -i --age "<public-key>" .env.json
```

```toml
[env]
_.file = ".env.json"    # auto-decrypted by mise
```

### Pattern 3: Redaction

```toml
[env]
SECRET = { value = "real-value", redact = true }
redactions = ["SECRET_*", "*_TOKEN"]
```

## Scoping Hierarchy

| Level | Location | Scope |
|-------|----------|-------|
| System | `/etc/mise/config.toml` | All users |
| Global | `~/.config/mise/config.toml` | All projects |
| Project | `~/project/mise.toml` | This project |
| Subdirectory | `~/project/sub/mise.toml` | This directory |
| Local | `mise.local.toml` | Machine override |

## CLI Commands

```bash
mise set NODE_ENV=production    # set var in mise.toml
mise set NODE_ENV               # read value
mise set                        # list all
mise unset NODE_ENV             # remove
mise env                        # print resolved env (shell exports)
mise env --json                 # structured output
```

## direnv Migration

| direnv | mise equivalent |
|--------|----------------|
| `export VAR=val` | `[env] VAR = "val"` |
| `dotenv .env` | `_.file = ".env"` |
| `layout python` | `[tools] python = "3.12"` + venv |
| `PATH_add ./bin` | `_.path = "./bin"` |
| `source_env ..` | Config inheritance (parent dirs) |

mise's official stance: don't use both together. mise `[env]` covers ~90% of direnv use cases.

> https://mise.jdx.dev/direnv.html
