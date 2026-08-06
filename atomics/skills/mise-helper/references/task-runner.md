# mise Task Runner

> https://mise.jdx.dev/tasks/ · https://mise.jdx.dev/tasks/toml-tasks.html · https://mise.jdx.dev/tasks/file-tasks.html

## Two Formats

### TOML Tasks (in mise.toml)

Best for short commands tightly coupled to config:

```toml
# One-liners
[tasks]
build = "cargo build"
test = "cargo test"
lint = "cargo clippy"

# Full task
[tasks.deploy]
description = "Deploy to production"
run = "deploy.sh"
depends = ["build", "test"]
sources = ["src/**/*.rs", "Cargo.toml"]
outputs = ["target/release/myapp"]
env = { RUST_BACKTRACE = "1" }
tools = { rust = "1.80" }
confirm = "Deploy to production?"
```

### File Tasks (scripts in mise-tasks/)

Best for complex logic, any language, IDE linting:

```bash
#!/usr/bin/env bash
#MISE description="Build the CLI"
#MISE depends=["lint"]
#MISE sources=["Cargo.toml", "src/**/*.rs"]
#MISE outputs=["target/debug/mycli"]
#MISE tools={rust="1.80"}
cargo build
```

Directories searched: `mise-tasks/`, `.mise-tasks/`, `.mise/tasks/`, `.config/mise/tasks/`

Must be executable (`chmod +x`). Supports any shebang (bash, python, node, ruby, powershell).

## Task Properties

| Property | Type | Purpose |
|----------|------|---------|
| `run` | string/string[] | Command(s) to execute |
| `depends` | string[] | Run these first |
| `depends_post` | string[] | Run these after |
| `wait_for` | string[] | Wait if already running |
| `sources` | string[] | Input globs (freshness) |
| `outputs` | string[]/`{auto=true}` | Output files (skip if newer than sources) |
| `dir` | string | Working directory |
| `env` | table | Task-specific env vars |
| `tools` | table | Task-specific tool versions |
| `shell` | string | Override shell |
| `confirm` | string | User prompt before run |
| `raw` | bool | Direct stdin/stdout passthrough |
| `usage` | string | Argument spec (see below) |
| `hide` | bool | Hide from `mise tasks` listing |
| `file` | string | External/remote script path |

## Running Tasks

```bash
mise run build                      # standard
mise r build                        # alias
mise build                          # shorthand (don't use in scripts)
mise run build --release            # pass args to task
mise run lint ::: test ::: check    # parallel multiple tasks
mise run --force build              # ignore freshness
mise run --jobs 8 build             # override parallelism
mise run --affected build           # only git-changed projects (CI)
```

Default: 4 parallel jobs. Tasks without dependencies run concurrently.

## Dependencies

```toml
[tasks.ci]
depends = ["lint", "test", "build"]     # all run before ci
depends_post = ["notify"]               # runs after ci completes

[tasks.test]
depends = [
  "lint",
  { task = "build", args = ["--release"], env = { OPT = "3" } },
]

# Wildcard dependencies
[tasks.lint]
depends = ["lint:*"]    # matches lint:eslint, lint:prettier, etc.
```

## Freshness (Sources/Outputs)

```toml
[tasks.build]
run = "cargo build"
sources = ["Cargo.toml", "src/**/*.rs"]
outputs = ["target/debug/myapp"]
```

Skip execution if outputs are newer than sources. Force with `mise run --force`.

## Argument Parsing

```toml
[tasks.test]
usage = '''
arg "<file>" help="Test file" default="all"
flag "-v --verbose" help="Verbose output"
flag "--format <format>" help="Output format" default="text" {
  choices "text" "json"
}
'''
run = 'cargo test ${usage_file} --format ${usage_format}'
```

For file tasks, use `#USAGE` comments:
```bash
#!/usr/bin/env bash
#USAGE flag "-c --clean" help="Clean first"
#USAGE arg "<target>" help="Build target"
if [ "${usage_clean}" = "true" ]; then cargo clean; fi
cargo build --target "${usage_target}"
```

## Watch Mode

Requires watchexec: `mise use -g watchexec@latest`

```bash
mise watch build                    # re-run on source changes
mise watch build --exts rs          # filter by extension
mise watch serve --restart          # kill + restart on change
mise watch test --debounce 500ms    # custom debounce
mise watch build --clear            # clear screen between runs
```

## Task Grouping (Namespaces)

```
mise-tasks/
├── build
└── test/
    ├── _default       → task name: "test"
    ├── integration    → task name: "test:integration"
    └── units          → task name: "test:units"
```

## Remote/Shared Tasks

```toml
[task_config]
includes = [
  "mise-tasks",
  "tasks.toml",
  "git::https://github.com/myorg/shared-tasks.git//tasks?ref=v1.0.0",
]
```

## Vars (Shared Between Tasks)

```toml
[vars]
e2e_args = "--headless"

[tasks.test]
run = './test.sh {{vars.e2e_args}}'
```

Not passed as env vars — only accessible via `{{vars.name}}` templates.

## Environment in Tasks

Tasks inherit all `[env]` vars plus mise auto-sets:

| Variable | Value |
|----------|-------|
| `MISE_ORIGINAL_CWD` | Where `mise run` was invoked |
| `MISE_CONFIG_ROOT` | Directory containing mise.toml |
| `MISE_TASK_NAME` | Name of running task |
| `MISE_PROJECT_ROOT` | Project root |

## Comparison

| Feature | mise | Make | just | npm scripts |
|---------|------|------|------|-------------|
| Parallel deps | ✅ Auto | `-j` | ❌ | ❌ |
| Freshness skip | ✅ | ✅ | ❌ | ❌ |
| Watch mode | ✅ Built-in | ❌ | ❌ | ❌ |
| Tool versions | ✅ Built-in | ❌ | ❌ | ❌ |
| File tasks (IDE support) | ✅ | ❌ | ✅ | ❌ |
| Cross-platform | ✅ `run_windows` | ❌ | ⚠️ | ⚠️ |
| Arg parsing | ✅ usage specs | ❌ | ✅ | ❌ |

## Useful Commands

```bash
mise tasks                    # list tasks
mise tasks info build         # show task details
mise tasks deps build         # dependency tree
mise tasks add mytask -- echo "hi"  # add inline task
mise generate task-docs       # generate markdown docs
```
