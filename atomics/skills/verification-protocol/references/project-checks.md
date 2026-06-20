# Project Check Commands

Lookup table for verification commands by project type. The agent reads this when the skill's `params.build_command` etc. are empty and needs to discover what to run.

## Discovery Order

1. Check `AGENTS.md` Commands section for explicit commands
2. Check `mise.toml` / `Makefile` / `justfile` / `package.json` scripts
3. Infer from project files (see table below)

## By Config File Present

| File | Build | Test | Lint |
|------|-------|------|------|
| `package.json` | `npm run build` | `npm test` | `npm run lint` |
| `Cargo.toml` | `cargo build` | `cargo test` | `cargo clippy` |
| `pyproject.toml` | `pip install -e .` | `pytest` | `ruff check .` |
| `go.mod` | `go build ./...` | `go test ./...` | `golangci-lint run` |
| `pom.xml` | `mvn compile` | `mvn test` | `mvn checkstyle:check` |
| `Makefile` | `make build` | `make test` | `make lint` |
| `mise.toml` | `mise run build` | `mise run test` | `mise run lint` |

## Writing Tasks

| Check | Command |
|-------|---------|
| Broken links | `grep -r '\[.*\](.*\.md)' docs/ \| while read l; do ...` or use `markdown-link-check` |
| Spelling | `cspell "docs/**/*.md"` |
| Formatting | Visual review — headers, lists, code blocks render correctly |

## Config/Infra Tasks

| Check | Command |
|-------|---------|
| YAML valid | `yq '.' file.yaml > /dev/null` |
| Terraform | `terraform validate && terraform plan` |
| Docker | `docker build --target test .` |

## Scope Check

```bash
git diff --stat          # overview of what changed
git diff --name-only    # file list for quick review
```

Changes outside the task's expected files = scope violation.
