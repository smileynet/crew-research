# Multi-Agent Validation

Validate artifacts (images, code, documents, designs) using multiple independent AI tools. Each tool brings different strengths; disagreement surfaces real issues.

## When to Use

- Visual output validation (rendered images, UI screenshots, design mockups)
- Code review requiring multiple perspectives (logic, security, performance)
- Documentation quality checks (accuracy, completeness, clarity)
- Design decisions needing independent opinions before committing
- Any artifact requiring qualitative judgment where a single perspective has blind spots

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

### Tools

| Tool | Invocation | Role |
|------|-----------|------|
| **kiro** | Direct image inspection in conversation | Contextual judge |
| **codex** | `codex exec -i <image> --sandbox read-only "<prompt>"` | Visual inspector |
| **agy** (sandbox) | `agy -p "Analyze <image> - <prompt>" --sandbox --print-timeout 2m` | Visual inspector + native measurement |
| **agy** (full) | `agy -p "Analyze <image> - <prompt>" --print-timeout 2m` | Technical auditor (reads code) |

### Invocation Details

#### Codex CLI

```bash
# Single image
codex exec -i /path/to/render.png --sandbox read-only "Evaluate: 1. criteria 2. criteria. PASS/FAIL."

# Multiple images (A/B comparison)
codex exec -i image_a.png -i image_b.png --sandbox read-only "Compare: ..."

# With specific model
codex exec -i render.png --sandbox read-only -m gpt-5.5 "prompt"
```

**Key flags:** `-i` (image, repeatable), `--sandbox read-only` (no writes), `--skip-git-repo-check` (outside repos)

**Output:** Plain text to stdout. Use `tail -15` to get clean response after metadata.

#### agy (Antigravity CLI)

```bash
# Visual-only (sandbox mode - no code reading)
agy -p "Analyze /path/to/render.png - <criteria prompt>" --sandbox --print-timeout 2m

# Code-aware (full mode - reads source, runs scripts)
agy -p "Analyze /path/to/render.png - <criteria prompt>" --print-timeout 2m

# With specific model
agy -p "Analyze /path/to/image.png - criteria" --model "Gemini 3.5 Flash (High)" --print-timeout 2m
```

**Key difference from codex:** Image path goes IN the prompt text (no `--image` flag). agy reads it via `view_file`.

**Key flags:** `-p` (non-interactive), `--sandbox` (visual-only), `--print-timeout` (default 5m, use 2m for images)

**Output:** Plain text to stdout. No JSON envelope.

#### kiro (TUI - this agent)

```
# In conversation, read the image directly:
[use the Image read tool on the file path]

# Or dispatch a fresh session for large/many images:
kiro-cli chat --no-interactive "Analyze /path/to/image.png - criteria"
```

### Prompt Engineering

**Critical for toon/NPR/stylized renders:**
```
This is an intentional toon/cel-shaded render where hard shadow edges 
are a DESIRED feature (not a bug). PASS if [criteria]. 
FAIL only if [failure condition].
```

Without this context, tools will flag intentional stylization as defects.

**Structure prompts as checklists:**
```
For each [object]: 
1. criterion? YES/NO 
2. criterion? YES/NO 
Overall PASS/FAIL.
```

This produces structured, comparable output across tools.

## Code Validation (Extended Use Case)

```bash
# codex: logic review
codex exec --sandbox read-only "Review this diff for bugs and regressions"

# agy: security/performance audit  
agy -p "Audit /path/to/file.py - Check for: injection, auth bypass, N+1 queries" --print-timeout 5m

# kiro: architecture review (in conversation)
# Read the code and evaluate against project conventions
```

## Document Validation (Extended Use Case)

```bash
# codex: readability and completeness
codex exec --sandbox read-only "Review this README: is it clear? Complete? Any broken links?"

# agy: technical accuracy
agy -p "Verify claims in /path/to/doc.md against the actual codebase" --print-timeout 5m
```

## Lessons Learned

### Tool characteristics (validated)

| Tool | Measures pixels | Reads code | Runs scripts | False positives | False negatives |
|------|----------------|------------|-------------|-----------------|-----------------|
| codex | No (visual impression) | No | No | Rare | Passes broken-but-OK-looking things |
| agy --sandbox | Yes (native Gemini multimodal) | No | No | Flags intentional styles as defects (without context) | Rare |
| agy (full) | Yes (via Python) | Yes | Yes | Can misdiagnose root causes | Rare |
| kiro | Via image read | Yes | Yes | Context bias ("I know what it should do") | May accept marginal results |

### Verified failure patterns

- **agy without toon context** → flags hard shadow edges as aliasing
- **agy code diagnosis** → correctly identifies symptoms but may misattribute root causes (verify against official docs)
- **codex on dark materials** → may PASS things that are technically below measurable thresholds
- **kiro after many iterations** → context fatigue can lower standards

### Token costs

| Operation | codex | agy |
|-----------|-------|-----|
| Single image | ~10-19K tokens | ~10-15K tokens |
| Multi-image (4) | ~20-22K tokens | ~15-20K tokens |
| Code-aware audit | N/A | ~20-30K tokens |

## Applicability

This pattern works for any domain where:
1. Quality is partially subjective
2. No single tool catches all issues
3. False confidence from one perspective is dangerous
4. The cost of shipping a defect exceeds the cost of running 2-3 extra checks

**NOT suitable for:** purely objective checks (linting, type checking, test pass/fail) where a single authoritative tool suffices.
