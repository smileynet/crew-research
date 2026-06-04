# Session Analyzer

Parse kiro-cli session transcripts for quantitative performance analysis.

## Scripts

- `parse.py` — Extract structured metrics from JSONL session files
- `extract_batches.py` — Produce conversation summaries for batch subagent review

## Usage

```bash
python tools/session-analyzer/parse.py --days 7 --output metrics.json
python tools/session-analyzer/extract_batches.py sessions/*.jsonl
```
