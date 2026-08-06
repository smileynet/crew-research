# mise IDE & CI/CD Integration

> https://mise.jdx.dev/ide-integration.html · https://mise.jdx.dev/continuous-integration.html

## IDE Integration

IDEs don't use interactive shell hooks — they need **shims** to find mise-managed tools.

### Core Setup (All IDEs)

Add shims to your login profile (read by IDEs on launch):

```bash
# ~/.zprofile (macOS zsh) or ~/.bash_profile (Linux bash)
eval "$(mise activate zsh --shims)"
```

Then in interactive shell config (for hooks/env):
```bash
# ~/.zshrc
eval "$(mise activate zsh)"
```

### VSCode

**Plugin:** [mise-vscode](https://marketplace.visualstudio.com/items?itemName=hverlin.mise-vscode)
- Auto-configures extensions to use mise-managed tools
- Manages tasks, tools, env vars from VSCode
- Autocompletion for `mise.toml`

macOS automation profile (needed for tasks):
```json
{
  "terminal.integrated.automationProfile.osx": {
    "path": "/usr/bin/zsh",
    "args": ["--login"]
  }
}
```

Launch config with mise:
```json
{
  "type": "node",
  "request": "launch",
  "name": "Launch via mise",
  "program": "${file}",
  "runtimeExecutable": "mise",
  "runtimeArgs": ["exec", "--", "node"]
}
```

### JetBrains (IntelliJ, PyCharm, WebStorm, etc.)

**Plugin:** [intellij-mise](https://github.com/134130/intellij-mise)
- Auto-configures IDE to use mise-managed SDKs
- Loads env vars in run configurations

Workaround for plugins that only find asdf:
```bash
ln -s ~/.local/share/mise ~/.asdf
```

### Vim / Neovim

```vim
" Vim (~/.vimrc)
let $PATH = $HOME . '/.local/share/mise/shims:' . $PATH
```

```lua
-- Neovim (init.lua)
vim.env.PATH = vim.env.HOME .. "/.local/share/mise/shims:" .. vim.env.PATH
```

### Emacs

```elisp
;; Using mise.el (recommended)
(require 'mise)
(add-hook 'after-init-hook #'global-mise-mode)
```

> https://github.com/eki3z/mise.el

### Xcode

Add `$(SRCROOT)/mise.toml` to Input files, then in build phase:
```bash
eval "$($HOME/.local/bin/mise activate -C $SRCROOT bash --shims)"
swiftlint
```

### Shims vs PATH Activation

| Feature | `mise activate` (PATH) | `--shims` |
|---------|------------------------|-----------|
| Env vars always available | ✅ | ❌ (only when shim runs) |
| Hooks work | ✅ | ❌ |
| `which` shows real path | ✅ | ❌ (shows shim) |
| Works in IDEs/scripts | ❌ | ✅ |
| Non-interactive shells | ❌ | ✅ |

---

## CI/CD Integration

### GitHub Actions (Recommended)

> https://github.com/jdx/mise-action

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: jdx/mise-action@v4
        with:
          version: 2026.3.10       # pin mise version
          cache: true              # cache tool installs
      - run: mise run test
```

Key options:
```yaml
- uses: jdx/mise-action@v4
  with:
    version: 2026.3.10         # pin version
    install: true              # run `mise install`
    cache: true                # GitHub cache
    experimental: true         # experimental features
    env: true                  # export env vars to job
    export_path: true          # add mise PATH entries
    mise_toml: |               # inline config
      [tools]
      shellcheck = "0.11.0"
```

If `mise.lock` exists, automatically runs `mise install --locked`.

### GitLab CI

```yaml
build:
  image: debian:12-slim
  variables:
    MISE_DATA_DIR: $CI_PROJECT_DIR/.mise/data
  cache:
    key:
      prefix: mise-
      files: ["mise.toml", "mise.lock"]
    paths:
      - $MISE_DATA_DIR
  script:
    - curl https://mise.run | sh
    - export PATH="$HOME/.local/bin:$PATH"
    - mise install
    - mise exec --command 'npm test'
```

### Generic CI (Any Provider)

```bash
# Install mise + use shims
curl https://mise.run | sh
export PATH="$HOME/.local/share/mise/shims:$PATH"
mise install
npm test
```

Or explicit execution:
```bash
curl https://mise.run | sh
~/.local/bin/mise install
~/.local/bin/mise exec -- npm test
```

### Xcode Cloud

`ci_post_clone.sh`:
```bash
#!/bin/sh
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"
mise install
eval "$(mise activate bash --shims)"
swiftlint
```

### Docker

```dockerfile
FROM debian:13-slim AS builder
RUN apt-get update && apt-get install -y curl git ca-certificates
RUN curl https://mise.run | sh
ENV PATH="/root/.local/share/mise/shims:$PATH"
COPY mise.toml mise.lock ./
RUN mise install
COPY . .
RUN mise run build

# Production — no mise
FROM debian:13-slim
COPY --from=builder /app/dist /app
CMD ["/app/server"]
```

Multi-user containers:
```bash
mise install --system    # installs to /usr/local/share/mise/installs
```

### Devcontainers

```bash
mise generate devcontainer --write
# Creates .devcontainer/devcontainer.json
```

### Bootstrap Script (Committable)

```bash
mise generate bootstrap --localize --write bin/mise
# Creates ./bin/mise — self-contained, no global install needed
# CI: ./bin/mise install && ./bin/mise run test
```

---

## CI Best Practices

### 1. Commit mise.lock

```bash
mise settings lockfile=true
mise lock
git add mise.lock
```

### 2. Use Strict Mode

```yaml
env:
  MISE_LOCKED: "1"    # fail if lockfile missing entries
```

### 3. Pin mise Version

```yaml
# GitHub Actions
- uses: jdx/mise-action@v4
  with:
    version: 2026.3.10

# Generic
curl https://mise.run | MISE_VERSION=v2026.3.10 sh
```

### 4. Cache Strategy

- ✅ Cache `~/.local/share/mise/installs/` (actual tools)
- ❌ Don't cache `~/.cache/mise/` (short-lived, wastes space)
- Key by `mise.lock` hash for best invalidation

### 5. Safe Mode for Untrusted Branches

```yaml
# Bot PRs, dependency bumps
MISE_SAFE=1 mise lock --bump --json
```

### 6. Supply Chain Checklist

1. Commit `mise.lock` — reproducible, checksum-verified
2. Set `MISE_LOCKED=1` in CI — zero API calls
3. Set `minimum_release_age = "7d"` — avoid fresh compromises
4. Pin mise version — predictable behavior
5. Provide `GITHUB_TOKEN` — avoid rate limits

---

## Generation Commands

| Command | Output |
|---------|--------|
| `mise generate github-action --write --task=ci` | `.github/workflows/ci.yml` |
| `mise generate git-pre-commit --write` | `.git/hooks/pre-commit` |
| `mise generate devcontainer --write` | `.devcontainer/devcontainer.json` |
| `mise generate bootstrap --localize --write` | `./bin/mise` |
| `mise generate task-docs` | Markdown task documentation |
| `mise generate task-stubs --mise-bin ./bin/mise` | Task shim scripts |
