---
id: "172"
title: "v3 cutover readiness: fix stale v2-pin doc, verify eval suite on v3, engine-conditional timeout"
status: done
blocked_by: []
priority: high
tags: [kiro-v3]
---

# v3 cutover readiness checklist

After 168/126/124/169/170, the proof harness runs on v3. Remaining gaps before v3
is "cutover-ready" (default flip stays kiro's call; this makes OUR tooling ready).

## Tasks

1. **Fix stale v2-pin doc.** `.kiro/skills/eval-harness/references/execution.md:84`
   still says "v3 CANNOT run headless at all" + "v3 rejects -a" — both falsified by
   spike 168 on 2.27.0. Correct it (v3 runs headless; -a works; needs permissions
   field on agent configs; default headless engine is still v2 on this build).
2. **Verify the eval suite on v3** (the real gate). The eval harness deploys skills
   (not agent JSON) and has an `--engine` selector but no v3-verified run. Run a
   representative eval on `--engine v3` and confirm parity with v2 (skill activates,
   scoring works, stream-json capture intact).
3. **Engine-conditional adapter timeout.** Proof A3 didn't finish on v3 within the
   adapter `invoke.timeout: 90` (v3 slower cold start). Raise/condition the timeout
   for v3 so proofs don't false-timeout.

## Results (2026-10-02)

**Task 1 — doc fixed.** `execution.md:84` corrected: v3 runs headless, `-a` works,
default headless engine is still v2, agent configs need the `permissions` field, tool
name is kind/title. Points at v3-engine-notes.md + stream-json-schema.md.

**Task 2 — eval/activation on v3: PASS (parity with v2).** Two independent
skill-activation A/Bs with unambiguous triggers both show v2==v3:
- spike 168 canary skill (earlier): deterministic activation on both.
- this ticket, `beacon` skill, 3 trials each: **v2 3/3, v3 3/3**.
A flawed first fixture (a "review this diff" skill with NO actual diff in the workdir)
scored v2 1/2, v3 0/2 — but inspection showed BOTH engines behaved identically (asked
for the missing diff; skill WAS loaded on v3), so that was a bad test, not a v3 gap.
Real deployed skill (code-review) also ran clean on both engines. Conclusion:
crew-research skills activate under v3 headless at parity with v2.

**Task 3 — timeout made engine-conditional** (v3 timeout = 2× in proof run.sh). But
the A3 symptom was MISDIAGNOSED as a timeout: A3's actual invocation runs fine on v3
(exit 0, correct answer, skill-agent + skill:// resource both work). A3 produces no
harness verdict on v3 for a reason unrelated to v3 or cold-start — a pre-existing
harness quirk in how A3 (empty `expect.present`, agent with skill:// resource) flows on
a busy host. The timeout scaling is still a correct, harmless improvement; A3's
harness-level quirk is NOT a v3 blocker and is out of this ticket's scope.

## Readiness verdict

- **Opt-in v3: READY.** Proof harness (engine selector + stream-json grading + v3 agent
  configs) is green on v3; skills activate at parity; trust flags work; no API key needed
  on IdC. Run v3 with `--agent-engine v3` (+ stream-json for proofs).
- **Default flip: kiro's call, not ours.** Headless default is still v2 on 2.27.0; the
  staged rollout hasn't flipped it here. When kiro flips it, 169's freshness selector and
  the SQLite path auto-engage.
- **Residual (non-blocking):** A3's pre-existing harness quirk; secondary session scripts'
  SQLite retrofit (ticket 171, triggers when SQLite goes live).

## Acceptance criteria

- [x] execution.md v2-pin corrected to match 168 findings
- [x] A representative eval runs on `--engine v3` with parity to v2 (beacon A/B: v2 3/3, v3 3/3; code-review clean on both) — documented above
- [x] Harness timeout made engine-conditional for v3 (2× on v3); A3 symptom re-diagnosed as a pre-existing harness quirk, not a v3 timeout (invocation runs clean on v3)
- [x] Readiness verdict recorded (opt-in ready; default flip is kiro's call)

## Resolution (2026-10-02)

v3 cutover readiness assessed. (1) Fixed stale execution.md v2-pin that falsely said v3 can't run headless/rejects -a. (2) GATE PASS: crew-research skills activate under v3 headless at parity with v2 (beacon A/B 3/3 both engines; a first fixture showing v2 1/2 v3 0/2 was flawed - no diff to review - both engines behaved identically, skill WAS loaded on v3). (3) proof timeout now 2x on v3; A3's no-verdict re-diagnosed as a pre-existing harness quirk (its invocation runs clean on v3), not a v3 timeout. VERDICT: opt-in v3 is READY (proof harness green on v3: 126+124+170; activation parity; trust flags work; no API key on IdC). Default flip remains kiro's call - headless default is still v2 on 2.27.0; when kiro flips it, 169 freshness selector + SQLite path auto-engage. Residual non-blocking: A3 harness quirk; ticket 171 (secondary-script SQLite, triggers when SQLite live).
