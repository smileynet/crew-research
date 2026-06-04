# Per-Project Customization

## Format: `.crew-config.yaml`

Projects place a `.crew-config.yaml` at their root to customize the base compositions.

```yaml
# .crew-config.yaml — project-level customization
project: my-rust-cli
language: rust

# Which crews this project uses
crews:
  - development
  - bugfix

# Verification commands (override defaults)
verification:
  build: "cargo check"
  test: "cargo test"
  lint: "cargo clippy --all-targets -- -D warnings"

# Additional skills to add to specific archetypes
extend:
  implementer:
    skills: [rust-patterns]
  tester:
    skills: [rust-testing]

# Params injected into skills that declare them
params:
  verification-protocol:
    build_command: "cargo check"
    test_command: "cargo test"
    lint_command: "cargo clippy -- -D warnings"
  git-protocol:
    branch_strategy: "feature-branch"

# Project-specific eager-context
eager-context:
  - project-conventions
```

## Resolution Order

```
1. Local skill (project's own .kiro/skills/) — wins completely
2. Base skill + project params — substituted at generation time
3. Base skill with defaults — fallback
```

## Generator Behavior

1. Read `.crew-config.yaml` from `--project` path
2. Filter compositions to only selected `crews`
3. Apply `extend` — merge additional skills into archetypes
4. Apply `params` — substitute `{{params.X}}` in skill content
5. Apply `verification` — inject into verification-protocol params
6. Deploy `eager-context` — add project-specific always-loaded content
7. Emit tool-specific output as normal

## Minimal Example

```yaml
# Simplest possible config — just select crews and set verification
project: my-app
crews: [development]
verification:
  test: "npm test"
```
