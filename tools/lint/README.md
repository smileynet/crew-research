# Lint

Cross-link and consistency checks for the skill/practice ecosystem.

## Scripts

- `check-crosslinks.sh` — Verify practice↔skill frontmatter references

## Usage

```bash
./tools/lint/check-crosslinks.sh          # report broken links
./tools/lint/check-crosslinks.sh --strict  # exit 1 on any broken link
```
