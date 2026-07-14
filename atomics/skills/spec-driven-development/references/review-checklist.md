# Spec Review Checklist

Validate a spec before accepting it for implementation. A spec that passes review can be implemented without further clarification.

## Review Protocol

For each spec, check these gates IN ORDER. Fail fast — stop at the first critical failure.

### Gate 1: Clarity (can someone else implement this?)

**Block if ANY requirement:**
- Uses vague qualifiers: "appropriate", "as needed", "properly", "efficiently", "user-friendly", "fast enough"
- References undefined terms without linking to glossary
- Says "etc.", "and so on", "various"
- Contains ambiguous pronouns ("it should handle this" — what is "this"?)

**Action:** List every vague term. Ask the author to replace with concrete values.

### Gate 2: Testability (can we prove it's done?)

**Block if validation section:**
- Contains only "it works" or "it functions correctly"
- Has no input→output examples
- Describes manual verification only with no automation path
- References feelings ("users feel confident")

**Action:** For each vague criterion, propose a concrete test: specific input, expected output, pass/fail condition.

### Gate 3: Scope (is it one thing?)

**Block if:**
- The "What" section uses "and" to connect distinct capabilities
- Requirements span 3+ unrelated concerns
- Non-Goals section is empty or says "None"
- You can draw a line splitting requirements into two independent features

**Action:** Identify the split point. Propose decomposition into focused specs.

### Gate 4: Boundaries (what won't it do?)

**Block if:**
- Non-Goals is missing or trivial
- There's no upper bound on what the feature handles
- Adjacent functionality is mentioned but not explicitly excluded

**Action:** Propose 3-5 Non-Goals based on what adjacent features might leak in.

## Output Format

```
## Spec Review: {name}

### Verdict: PASS | BLOCK (Gate N)

### Findings:
1. [GATE] Issue — proposed fix
2. ...

### Blocking Questions (if BLOCK):
- Question 1
- Question 2
```

## Rules

- Be adversarial. Your job is to find problems, not approve specs.
- One blocking issue is enough to BLOCK. Don't soft-pedal.
- Propose fixes, not just problems. Show what "good" looks like.
- NEVER say "looks good" without checking every gate.
- A spec that passes all 4 gates can be implemented by any competent developer without asking follow-up questions.
