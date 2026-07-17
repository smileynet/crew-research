---
name: multi-agent-validation
description: "Validate artifacts with multiple independent AI tools — images, code, documents, designs. Use when a single perspective has blind spots, for visual output validation, or when validators disagree. Trigger: multi-agent validation, independent validators, cross-check with another tool, second opinion, validation crew."
metadata:
  type: protocol
  invocation: both
  practice: null
---

# Multi-Agent Validation

Validate artifacts (images, code, documents, designs) using multiple independent AI tools. Each tool brings different strengths; disagreement surfaces real issues.

## When to Use

- Visual output validation (rendered images, UI screenshots, design mockups)
- Code review requiring multiple perspectives (logic, security, performance)
- Documentation quality checks (accuracy, completeness, clarity)
- Design decisions needing independent opinions before committing
- Any artifact requiring qualitative judgment where a single perspective has blind spots

**NOT suitable for:** purely objective checks (linting, type checking, test pass/fail) where a single authoritative tool suffices.

## The Pattern

```
1. Produce the artifact
2. Run N independent validators (minimum 2, recommended 3)
3. If ANY validator fails → investigate and fix
4. Record all verdicts with evidence
```

## Validator Roles

| Role | Strength | Weakness | Example Tools |
|------|----------|----------|---------------|
| **Visual Inspector** | "Does this look right?" Qualitative impression | Can't measure, may miss technical issues | codex, human eye |
| **Technical Auditor** | Measures actual values, reads source code | May over-report invisible issues, can misdiagnose root causes | agy, linters, static analysis |
| **Contextual Judge** | Domain knowledge, intent awareness, breaks ties | Bias toward "knowing what it should do" | kiro, domain expert |

## Disagreement Resolution

- **All agree PASS** → proceed with confidence
- **All agree FAIL** → fix before proceeding
- **Split verdict** → investigate the discrepancy:
  - Technical auditor wins on measurable criteria (pixel values, code correctness)
  - Visual inspector wins on subjective quality (does it look right to a human?)
  - Contextual judge breaks ties using domain knowledge and intent
- **Auditor finds a bug** → verify against authoritative documentation before acting (tools can misdiagnose)

## Image Validation (Primary Use Case)

| Tool | Role |
|------|------|
| **kiro** (direct image inspection in conversation) | Contextual judge |
| **codex** (`codex exec -i <image> --sandbox read-only`) | Visual inspector |
| **agy** with `--sandbox` | Visual inspector + native measurement |
| **agy** full (reads code) | Technical auditor |

Full command syntax, flags, and per-tool quirks: [references/tool-invocation.md](references/tool-invocation.md).

### Prompt Engineering

**Critical for toon/NPR/stylized renders** — without this context, tools flag intentional stylization as defects:

```
This is an intentional toon/cel-shaded render where hard shadow edges
are a DESIRED feature (not a bug). PASS if [criteria].
FAIL only if [failure condition].
```

**Structure prompts as checklists** for structured, comparable output across tools:

```
For each [object]:
1. criterion? YES/NO
2. criterion? YES/NO
Overall PASS/FAIL.
```

## Code and Document Validation

Same pattern, different prompts: codex for logic/readability review, agy for security/accuracy audits, kiro for architecture review against project conventions. Command examples: [references/lessons-learned.md](references/lessons-learned.md).

## Known Tool Behaviors

Validated characteristics, failure patterns, and token costs live in [references/lessons-learned.md](references/lessons-learned.md). Highlights:

- agy flags intentional styles as defects unless the prompt declares them desired
- agy identifies symptoms correctly but may misattribute root causes — verify against docs
- kiro's standards drift down after many iterations (context fatigue)

## Applicability

This pattern works for any domain where quality is partially subjective, no single tool catches all issues, false confidence from one perspective is dangerous, and the cost of shipping a defect exceeds the cost of 2-3 extra checks.
