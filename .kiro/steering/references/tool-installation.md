# Tool Installation Guide

When a required tool is missing, install it using the commands below. Detect the OS first, then use the appropriate method.

## Required Tools

| Tool | Purpose | Required by |
|------|---------|-------------|
| `kiro-cli` | AI coding assistant CLI | All deployments |
| `codex` | OpenAI Codex CLI | Codex deployments only |
| `agy` | Google Antigravity CLI | Antigravity deployments only |
| `crush` | Charm's Crush agent CLI | Adapter/judge pools (e.g., codex-runner) |
| `tk` | Minimal ticket system (lo5/tk) | Ticket-based dispatch projects |
| `yq` | YAML processor | init.sh, doctor.sh |
| `mise` | Task runner / env manager | All mise run commands |
| `jq` | JSON processor | eval harness |
| `bc` | Calculator | eval harness score math |
| `git` | Version control | Everything |

## OS Detection

```bash
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
  Darwin*) OS="macos" ;;
  Linux*) OS="linux" ;;
esac
```

## tk (all OSes — needs Go ≥ 1.25.5)

```bash
go install github.com/lo5/tk@latest
```

If Go is older than 1.25.5: `mise install go@1.25` first, then use that binary explicitly
(`~/.local/share/mise/installs/go/1.25/bin/go install ...`).

**Behind a corporate proxy** (TLS interception breaks proxy.golang.org — symptom:
`tls: failed to verify certificate: certificate is valid for <corp-host>, not proxy.golang.org`):

```bash
GOPROXY=direct GOSUMDB=off GOTOOLCHAIN=local go install github.com/lo5/tk@latest
```

`GOTOOLCHAIN=local` matters: with GOSUMDB=off, Go refuses to auto-download toolchains
("verifying module: checksum database disabled").

**Verify with `which tk`** — `go install` honors `GOBIN`, which mise-managed machines often
point at mise's go bin dir (e.g. `~/.local/share/mise/installs/go/<ver>/bin`), NOT `~/go/bin`.

## crush (Charm's Crush)

```bash
# macOS / Linux (linuxbrew)
brew install charmbracelet/tap/crush

# Windows
winget install charmbracelet.crush
# Or any OS via Go (same corporate-proxy recipe as tk if needed):
go install github.com/charmbracelet/crush@latest
```

Crush auto-detects providers from env (e.g., Bedrock via CLAUDE_CODE_USE_BEDROCK). It writes
a `.crush/` state dir into cwd on every run — gitignore it or pass `--data-dir`.


## Windows (Git Bash / MSYS2)

```bash
# kiro-cli
winget install --id Amazon.Kiro-CLI

# codex (OpenAI Codex CLI)
winget install --id OpenAI.Codex
# Or: npm install -g @openai/codex

# agy (Google Antigravity CLI)
curl -fsSL https://antigravity.google/cli/install.sh | bash
# Or from PowerShell: irm https://antigravity.google/cli/install.ps1 | iex

# yq
winget install --id MikeFarah.yq

# mise
winget install --id jdx.mise
# Then restart terminal or: eval "$(mise activate bash)"

# jq
winget install --id jqlang.jq

# bc (not in winget — use Python shim)
mkdir -p ~/.local/bin
cat > ~/.local/bin/bc << 'EOF'
#!/bin/bash
if [[ "$1" == "-l" || "$1" == "--mathlib" ]]; then shift; fi
if [[ $# -gt 0 ]]; then input="$*"; else input=$(cat); fi
python -c "
import sys, math
expr = sys.argv[1]
lines = [l.strip() for l in expr.replace(chr(59), chr(10)).split(chr(10)) if l.strip()]
scale = 2
for line in lines:
    if line.startswith('scale='):
        scale = int(line.split('=')[1])
        continue
    line = line.replace('sqrt(', 'math.sqrt(').replace('^', '**')
    try:
        result = eval(line)
        print(f'%.{scale}f' % result)
    except:
        pass
" "$input"
EOF
chmod +x ~/.local/bin/bc
# Ensure ~/.local/bin is on PATH:
grep -q '.local/bin' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# git (usually bundled with Git for Windows)
winget install --id Git.Git
```

## macOS

```bash
# kiro-cli
brew install --cask kiro-cli
# Or: curl -fsSL https://kiro.dev/install | sh

# codex
brew install openai-codex
# Or: npm install -g @openai/codex

# agy (Google Antigravity CLI)
curl -fsSL https://antigravity.google/cli/install.sh | bash

# yq
brew install yq

# mise
brew install mise
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc

# jq
brew install jq

# bc (pre-installed on macOS)

# git (pre-installed via Xcode CLT, or:)
brew install git
```

## Linux (Debian/Ubuntu)

```bash
# kiro-cli
curl -fsSL https://kiro.dev/install | sh

# codex
npm install -g @openai/codex

# agy (Google Antigravity CLI)
curl -fsSL https://antigravity.google/cli/install.sh | bash

# yq
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq

# mise
curl https://mise.run | sh
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc

# jq
sudo apt-get install -y jq

# bc
sudo apt-get install -y bc

# git
sudo apt-get install -y git
```

## Linux (Fedora/RHEL)

```bash
# yq, jq, bc, git
sudo dnf install -y yq jq bc git

# mise
curl https://mise.run | sh

# kiro-cli, codex — same as Debian
```

## Verification

After installation, verify all tools:

```bash
mise run doctor -- --project .
```

Or manually:
```bash
kiro-cli --version
codex --version
agy --version
yq --version
mise --version
jq --version
echo "1+1" | bc
git --version
```
