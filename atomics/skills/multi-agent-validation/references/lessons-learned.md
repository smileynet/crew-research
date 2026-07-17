# Multi-Agent Validation — Validated Tool Characteristics

Empirical observations from validation runs. Companion to SKILL.md.

## Tool characteristics (validated)

| Tool | Measures pixels | Reads code | Runs scripts | False positives | False negatives |
|------|----------------|------------|-------------|-----------------|-----------------|
| codex | No (visual impression) | No | No | Rare | Passes broken-but-OK-looking things |
| agy --sandbox | Yes (native Gemini multimodal) | No | No | Flags intentional styles as defects (without context) | Rare |
| agy (full) | Yes (via Python) | Yes | Yes | Can misdiagnose root causes | Rare |
| kiro | Via image read | Yes | Yes | Context bias ("I know what it should do") | May accept marginal results |

## Verified failure patterns

- **agy without toon context** → flags hard shadow edges as aliasing
- **agy code diagnosis** → correctly identifies symptoms but may misattribute root causes (verify against official docs)
- **codex on dark materials** → may PASS things that are technically below measurable thresholds
- **kiro after many iterations** → context fatigue can lower standards

## Token costs

| Operation | codex | agy |
|-----------|-------|-----|
| Single image | ~10-19K tokens | ~10-15K tokens |
| Multi-image (4) | ~20-22K tokens | ~15-20K tokens |
| Code-aware audit | N/A | ~20-30K tokens |

## Code validation examples

```bash
# codex: logic review
codex exec --sandbox read-only "Review this diff for bugs and regressions"

# agy: security/performance audit
agy -p "Audit /path/to/file.py - Check for: injection, auth bypass, N+1 queries" --print-timeout 5m

# kiro: architecture review (in conversation)
# Read the code and evaluate against project conventions
```

## Document validation examples

```bash
# codex: readability and completeness
codex exec --sandbox read-only "Review this README: is it clear? Complete? Any broken links?"

# agy: technical accuracy
agy -p "Verify claims in /path/to/doc.md against the actual codebase" --print-timeout 5m
```
