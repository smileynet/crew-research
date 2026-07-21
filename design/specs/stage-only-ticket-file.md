---
kind: constraint
id: stage-only-ticket-file
from_patterns:
  - "pattern:surgical-git-side-effects"
confidence: "★★"
protects_experience: "exp-safe-parallel-work"
user_story: "A claim made from a dirty tree commits exactly one file — your in-flight work never rides along."
check:
  method: grep
  target: "tools/tkt/tkt"
  pattern: "add.,\\s*.(-A|--all|\\.).|commit.,\\s*.(-a|--all).|git add (-A|--all|\\.)|git commit (-a|--all)"
  include: ["*.py"]
  expect: absent
links:
  - target: "pattern:surgical-git-side-effects"
    type: constrains
---

# No Bulk Staging in tkt Source

## Rule

tkt source never invokes git bulk staging in either idiom: subprocess list form (`"add", "-A"` / `"add", "."` / `"add", "--all"` / `"commit", "-a"`) or shell-string form (`git add -A` etc.). Staging always takes one explicit path variable.

## Rationale

surgical-git-side-effects (operator D2a). R1 alternation analysis (2026-07-21 field fix): the original prose-form pattern (`add -A` unanchored) over-matched documentation text (gitio docstring) while under-matching the actual Python subprocess idiom (`"add", "-A"` — the comma splits the prose form). The pattern now targets both real idioms: quote-comma-quote list form and `git `-prefixed string form; docstrings describing the rule no longer trip it. Tests are outside the target (tools/tkt/tkt is the source package; fixtures legitimately construct dirty trees) — NOTE: check-tool `exclude` is documented but unimplemented (archwright#040).

## Violations Look Like

```python
run(["git", "add", "-A"])  # BAD: sweeps operator WIP into a claim commit
```

## Correct Usage

```python
run(["git", "add", "--", str(ticket_path)])  # GOOD: one explicit path
```
