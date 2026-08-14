---
id: "104"
title: "Spike: deterministic activation checks replacing LLM-judged where possible"
status: open
blocked_by: []
env: either
priority: normal
---

# Spike: Deterministic Activation Checks

## Hypothesis

Many activation eval definitions check "did the skill activate?" — a question answerable by
string matching (did the agent's output reference the skill's name or key phrases?) rather
than LLM judging. Replacing these with deterministic checks saves ~12min per definition and
eliminates judge variance.

Inspired by mastra's `checks.includes()` pattern: deterministic assertions over output
text that don't require model inference.

## Baseline

- Current: `run-activation.sh` runs 10 tasks per definition. Each task invokes the agent,
  then an LLM judges "did the skill activate?" (~60s per judgment).
- Cost: 10 tasks × 60s judge = ~10min per definition. 35 definitions = ~6 hours.
- Problem: judge variance means the same output can get different verdicts on rerun.

## Spike design

1. **Identify deterministic candidates:** Definitions where activation = presence of skill
   name, slash command, or distinctive output phrase in the agent's response.
   
2. **Add a `check` field to activation definitions:**
   ```yaml
   activation:
     check: deterministic
     match_any:
       - "/grill-with-docs"
       - "grill session"
       - "stress-test"
     # If any match_any string appears in output → activated
   ```

3. **Fallback:** Definitions requiring judgment (nuanced activation, partial activation)
   keep `check: llm-judge` (current behavior).

4. **Measure:** Run the same definitions both ways. Compare verdicts. If agreement >95%,
   the deterministic check is equivalent.

## Validation criteria

- [ ] Audit all activation definitions: classify as deterministic-candidate vs needs-judge
- [ ] Implement deterministic check path in run-activation.sh
- [ ] Agreement rate ≥95% between deterministic and LLM-judged on same outputs
- [ ] Time savings measured (expect 10-12min per converted definition)
- [ ] No false negatives (deterministic doesn't miss activations the judge catches)

## Reject if

- Agreement <90% (deterministic is too crude for activation detection)
- Most definitions require nuanced judgment (few can be converted)
- String matching produces false positives (common words trigger activation claims)

## References

- Mastra eval checks: `.references/mastra/packages/evals/src/`
- Research: `.scratch/research/overlap-evals.md`
- Activation harness: `tools/evals/harness/run-activation.sh`
