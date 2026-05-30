# Setup

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| **Git** | Version control + bash shell (Windows) | [git-scm.com](https://git-scm.com) |
| **yq** | YAML processing (tier files, configs) | `winget install MikeFarah.yq` / `brew install yq` / `apt install yq` |
| **jq** | JSON processing (agent configs) | `winget install jqlang.jq` / `brew install jq` / `apt install jq` |
| **mise** | Task runner (optional, wraps scripts) | [mise.jdx.dev](https://mise.jdx.dev) |
| **kiro-cli** | AI coding assistant | [kiro.dev](https://kiro.dev) |

## Platform Notes

### Windows

All scripts are bash. Git for Windows includes Git Bash which provides bash + coreutils (sed, awk, grep, find, diff, etc.). Scripts run via:

```powershell
bash tools/generator/init.sh --global --tier basic
```

Or via mise (which invokes bash internally):

```powershell
mise run init -- --global --tier basic
```

### macOS / Linux

Scripts run natively. Ensure `yq` and `jq` are installed:

```bash
brew install yq jq    # macOS
apt install yq jq     # Debian/Ubuntu
```

## Verify

```bash
mise run doctor -- --project .
```

Or directly:

```bash
bash tools/generator/doctor.sh --project .
```

Doctor checks: kiro-cli, yq, jq availability + workspace health.
