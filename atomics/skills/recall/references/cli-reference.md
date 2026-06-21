# Recall CLI Reference

## Commands

```bash
recall search "query"                         # search all wings
recall search "query" --wing name             # scoped to project
recall search "query" --room decisions        # scoped to room
recall search "query" --results 10            # more results

recall add "text" --wing X --room Y --type T  # persist a fact
recall add "text" --type decision             # wing auto-detects from cwd

recall ingest ~/.kiro/sessions/cli            # auto-tag wings from cwd
recall ingest <path> --project ~/code/myapp   # filter to one project

recall prime --wing name                      # session-start context
recall status                                 # show indexed content
```

## Types for write-back

| Type | Use for |
|------|---------|
| `decision` | Choices made, options rejected, rationale |
| `fact` | Stable truths about the project |
| `lesson` | What was tried and failed, anti-patterns discovered |
| `preference` | User preferences, conventions, style choices |

## Storage

- Database: `~/.recall/recall.sqlite3`
- Config: `~/.recall/config.json` (optional, for custom topic_keywords)
- Model: `bge-base-en-v1.5` int8 ONNX (~105MB, cached in ~/.cache/huggingface/)

## Scoping

- **Wing** = project (auto-derived from cwd for `add` and `prime`; cross-project for `search`)
- **Room** = topic (auto-classified by keyword matching during ingest)
- Omit `--wing` on search to find content across all projects
- Omit `--wing` on add/prime to use cwd-based auto-detection
- Pass `--wing name` to override auto-detection
