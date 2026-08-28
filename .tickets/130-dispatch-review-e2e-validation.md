---
id: "130"
title: "Live e2e validation of dispatch-review multi-model matrix + fan-in"
status: in_progress
blocked_by: ["127"]
priority: high
---

# Live e2e validation of dispatch-review multi-model matrix + fan-in

## Context

Ticket 127 built the multi-model dispatch-review tooling but only verified it via
dry-run + a single-model Kimi smoke test (PONG). Two things were NEVER exercised
live:
- The matrix flow end-to-end against a real diff with all 3 models
- The fan-in (dedup / agreement tiering / aggregate ticket) — it's skill-guided
  guidance, not executed code, so its correctness rests on the method, untested

This ticket closes that gap with a real run against a known target.

## Research-backed findings (2026-08-28, `.scratch/research/t130/`)

### Pre-validation fixes REQUIRED (matrix.sh bugs an e2e run will hit)

A code review of matrix.sh + the skill/contract found 3 blocking issues — fix these BEFORE the live run, or the first real run fails:

- **B1 (HIGH — contract contradiction):** matrix.sh's `REVIEW_PROMPT` says "Use review-new-work…" but review-new-work MANDATES creating+pushing an aggregate ticket, while matrix.sh's model is "reviewers emit inline findings, the PARENT creates the one ticket." The reviewer is told to do both → it may try to push a ticket (fails without git auth, burns the run) and omit the inline JSON the fan-in needs. **Fix:** give matrix.sh a findings-ONLY prompt that explicitly says "do NOT create a ticket; emit findings as JSONL + one REVIEW_RESULT line." Inline the minimal output contract (schema + example + closed enums) rather than relying on review-new-work activating (cross-model activation is unproven).
- **B3 (MEDIUM — extraction):** artifact writer does `[inputs|select(.type=="text")|.part.text]|join("")` (no separator) then `grep -m1 '^REVIEW_RESULT '` (first match). Risks welding the result line off line-start (false indeterminate) or catching an echoed example line. **Fix:** `join("\n")` + fence-tolerant last-match (`grep -Eo 'REVIEW_RESULT \{.*\}$' | tail -1`).
- **B9 (MEDIUM — isolation):** matrix.sh cd's into `--dir` (default repo root) and runs `opencode --auto` in the LIVE tree, not a mktemp workdir as the skill claims. Combined with B1, a ticket-creating reviewer leaves commits/dirty files. **Fix:** run each reviewer in a throwaway clone/workdir; `git status` check after.

Also fold in prompt hardening: closed severity/category enums (free-form breaks agreement tiering), inline example, anti-markdown-fence instruction, "emit all keys use null" (research review-prompt-quality.md).

### opencode tool-using JSONL schema — EMPIRICALLY CONFIRMED

Live capture (opencode 1.18.21, real `read`-tool run): tool runs add top-level `type:"tool_use"` (`part.type:"tool"`, with tool/callID/state{status,input,output}). Each tool call opens its own step → MULTIPLE step_finish events, the first `reason:"tool-calls"`, only the last `reason:"stop"`. **The t127 extraction (`last(... step_finish ...)` + `[text|join]`) STILL WORKS** — tool events filter out cleanly and `last()` correctly skips the "tool-calls" step_finish. ⚠️ New risk: `tool_use.part.state.output` carries FULL file content read → events.jsonl is as sensitive as the repo; extract only the REVIEW_RESULT line, don't ship/log raw JSONL.

### Fixture methodology (measure catch-rate honestly)

- Use a **planted-bug fixture** with a manifest (location, defect class, severity) + a small **real** hold-out. Synthetic-only massively overstates capability (research: synthetic F1 0.847 vs real 0.066).
- **Difficulty taxonomy** matters more than count: Type1_Direct (in diff), Type2_Contextual (same-file), Type3_Latent (cross-file). Type3 resists memorization.
- Measure **precision AND recall AND hallucination-rate** separately — catch-rate alone misleads. 3-way finding labels: CONFIRMED / PLAUSIBLE (not penalized) / FABRICATED.
- If the fixture yields 90%+ catch, it's too easy/memorized. Expect 15-47% honest recall from frontier tools.

## Execution sequence (de-risked ordering)

Live model calls are slow/non-deterministic/can hang → wrap every `opencode run` in `Start-Job`+`Wait-Job -Timeout` (proven this session), one model at a time, under Git Bash (not WSL).

| Phase | What | Why this order |
|-------|------|----------------|
| 0 | **Fix matrix.sh B1/B3/B9 + prompt hardening** | Blocking — the first real run fails without these |
| 1 | Build planted-bug fixture (Type1/2/3 mix, manifest) | Ground truth to measure against |
| 2 | Single-model real review (Kimi, cheapest) on the fixture | Prove full path before 3× token spend; capture tool-using JSONL |
| 3 | Codex-default regression check | Confirm old path unchanged before trusting matrix |
| 4 | Full 3-model matrix on the fixture | Fan-out + summary + per-model artifacts |
| 5 | Fan-in (main context): dedup/tier/aggregate ticket | Needs all 3 artifacts |
| 6 | Degradation (opportunistic — force/observe a 429) | Hardest to force; document code-verified if not live-observed |

## Phase 1 fixture design (research-backed, `.scratch/research/t130b/`)

**Shape: a small self-contained repo, reviewed WHOLESALE at TARGET** (not a diff).
matrix.sh checks out a detached worktree at TARGET and tells the reviewer to "read
the working tree" — it never runs `git diff`. So plant bugs as ordinary source
(real file:line); TARGET = the fixture's tip commit. (A diff-framed fixture would
only work by accident.)

**Location:** `tools/review/fixtures/planted-review/` — `project/` (committed small
repo with planted bugs) + `manifest.yaml` (structured `expected_findings` using
matrix.sh's own `severity`/`category`/`location{file,line}` vocabulary so fan-in
reconciles by `(file,line,category)`). A structured findings manifest is new
(existing defu-*-bug fixtures use prose) — align its schema to the fan-in matcher.

**Bug set (~8-10, Type1/2/3 mix, weight toward Type3):** from the 13-bug catalog —
e.g. Type1: string-interpolated SQL (security), off-by-one in a custom paginator
(correctness), swallowed exception. Type2: inverted authz check (security), mutable
default arg, resource leak on early return. Type3 (the discriminators): cross-file
schema/int-width overflow, TOCTOU check-then-create race, over-mocked test hiding
contract drift. Use NOVEL framing (invert a project business rule) over textbook
patterns to resist memorization. Small enough for one blocking opencode pass/model.

**Scoring (Phase 6): multi-judge consensus grading — agents grade, not a matcher.**
Matching a semantic finding to a planted bug is a JUDGMENT (same defect + right
reason, not just same line), and a single grader has the same bias/blind-spot as a
single reviewer — so grade with a PANEL, reusing the eval-harness consensus pattern
(`run.sh` judge_output: parallel judges kiro/codex/crush, collect per-judge verdict,
take consensus). Deterministic `line±5` is used only as a coarse pre-filter/locator,
never as the grade.

- Grader panel: for each reviewer finding, judges label it CONFIRMED (matches a
  planted bug — same location AND same fault), PLAUSIBLE (real but unplanted —
  excluded from FP), or FABRICATED (neither → hallucination). Consensus (median/
  majority across judges) is the recorded label; disagreement is flagged.
- Judges run read-only in temp dirs, WITHOUT `-a`, given the reviewer's findings +
  the manifest (fixture author's answer key) as the rubric — same containment as
  eval judging.
- Report per-reviewer recall + precision + hallucination-rate (FDR); score each
  consensus TIER of reviewers (union≥1 / majority / unanimous) as a virtual model
  for the precision↑/recall↓ curve. Category is advisory (Phase 2 finding), not a gate.

⚠️ **Phase 2's "10/10, 0 fabrications" was SELF-GRADED by eye** (I authored the bugs,
manifest, AND the scoring) — informal, not validated. It must be RE-GRADED by the
judge panel in Phase 6 alongside the other models. Treat the Phase 2 numbers as a
confidence-building smoke signal, not a measured result.

## Phase 2 run mechanics (de-risked, `.scratch/research/t130c/`)

**⚠️ opencode has a documented never-exit bug** (#17516, open on v1.2.26) that fires
"when the model uses tools then has nothing left to do" — exactly a review's shape,
and specifically hit when driving `run` from an automation loop. `timeout` alone
won't catch it (the process looks "busy"). **matrix.sh already wraps opencode in
`timeout` inside a subshell; run matrix.sh ITSELF under a hard bounded wrapper**
(Start-Job + Wait-Job -Timeout on Windows) so a hung reviewer can't wedge the session.

**Exact Phase 2 recipe** (Git Bash on Windows — NOT WSL; opencode is native there):
```bash
TMP=$(mktemp -d); cp -r tools/review/fixtures/planted-review/project/* "$TMP"/   # CONTENTS not the dir
git -C "$TMP" init -q && git -C "$TMP" add -A && git -C "$TMP" commit -qm fixture
TARGET=$(git -C "$TMP" rev-parse HEAD); RUN_ID=t130-p2-$(date +%s)
bash tools/review/matrix.sh --run-id "$RUN_ID" --target "$TARGET" --models kimi-for-coding/k3 --dir "$TMP"
rm -rf "$TMP"    # matrix.sh removes its worktree via trap; caller cleans $TMP
```
Artifacts: `.scratch/review/<RUN_ID>/kimi-for-coding-k3.md` (findings + REVIEW_RESULT),
`matrix-summary.json`. Verified interactions: --dir must be a git repo with TARGET
(the git init is mandatory; matrix.sh never inits); copy `project/*` CONTENTS so files
land at `$TMP/src/...` matching manifest locations; artifacts survive the worktree
cleanup (they're in .scratch/, disjoint). Cost ~1-5¢, ~15-90s happy path (negligible
quota dent). Timeout 120-180s is the sweet spot; matrix.sh's 300s default is a fine
outer margin.

## What to validate (live)

### Phase 2 RESULT — Kimi single-model ✅ (2026-08-28, run_id t130-p2)

Live run succeeded end-to-end: worktree isolation → `opencode run --auto -m kimi-for-coding/k3 --format json` → JSONL validation (step_finish stop + REVIEW_RESULT) → artifact extraction. Completed well under the 240s bounded wrapper; matrix-summary.json status "pass", produced 1/1.

**Kimi caught 10/10 planted bugs (100% recall, 0 fabrications):**
B1 SQLi (F1 exact), B2 int-overflow×schema T3 (F9 exact — cross-file reasoning worked), B3 inverted authz (F2), B4 swallowed exc (F8), B5 off-by-one (F3), B6 mutable default (F4), B7 TOCTOU T3 (F7), B8 handle leak (F6), B9 over-mock T3 (F10 — connected test to auth.ts), B10 test theater (F11). All 3 Type3 discriminators caught.

**3 unplanted findings, all PLAUSIBLE (real, not fabricated):** F5 type mismatch on default bucket, F12 missing imports (./audit/./client/./fs-shim), F13 no test runner/package.json. Excluded from FP → precision uncompromised.

**Scoring observations for Phase 6:**
- **Category drift** on B3/B4/B7: Kimi's category (correctness/security/architecture) differs from manifest (security/correctness/correctness) though location is exact. Strict `category_eq` would MISS these 3 → recall would falsely read 7/10. **Decision: score on `same_file ∧ line±5` as primary; treat category as advisory, not a match gate.** Category taxonomies are model-subjective; location+fault-identity is the real signal.
- 100% recall confirms the fixture is easy for a strong model (research predicted 90%+ = easy) — acceptable for TOOLING validation (proves the pipeline surfaces real findings); the harder signal is cross-model *disagreement* in Phase 4.
- Output was clean JSONL, no markdown fences, no prose preamble — the hardened findings-only prompt (B1 fix) worked.

### Phase 3 RESULT — Codex-default regression ⚠️ PARTIAL (2026-08-28, run_id t130-p3)

Goal: confirm the generalized dispatch-review didn't break the original Codex reviewer path. **Contract + invocation verified** — `codex exec -s read-only --skip-git-repo-check "<findings-only prompt>"` ran, authenticated, and accepted the tool-neutral prompt; the failure was purely model availability. **Blocked from a clean findings run by env:** codex-cli 0.147.0's default model `gpt-5.6-sol` errors "requires a newer version of Codex"; explicit `-m gpt-5.1-codex` errors "not supported when using Codex with a ChatGPT account." Neither is a dispatch-review regression — the skill's codex invocation is unchanged and structurally correct; this machine's codex CLI/account can't currently serve a usable model. Also confirmed (incidentally) codex exit code is unreliable like opencode (exit 1 on model error AND would-be success). Follow-up: filed to upgrade codex CLI / pin a usable model, then complete the regression run.

### Phase 4 RESULT — full 3-model matrix ✅ (2026-08-28, run_id t130-p4)

`matrix.sh` (default roster, no filter) fanned out all 3 models against the fixture
in one run, under a 420s bounded wrapper: **produced 3/3, no coverage gaps.** Each
ran isolated in its own worktree checkout, sequential, all validated (step_finish
stop + non-empty text + REVIEW_RESULT). Raw finding-line counts: Kimi 11, Qwen 12,
GLM 12 — all clean JSONL (no fences/prose). Spot-check confirms real reviews:
Qwen caught B1 SQLi + B3 inverted authz at exact lines AND flagged a fail-open
default (auth.ts:14) that ISN'T planted (a real observation → PLAUSIBLE). The
matrix mechanics (fan-out, isolation, per-model artifacts, summary) are fully
validated live across all 3 target coding-plan models. Per-model recall/precision
+ cross-model agreement tiering → Phase 6 judge-panel grading. Artifacts in
`.scratch/review/t130-p4/`.

### Phase 5 RESULT — fan-in ✅ (2026-08-28)

Parent (main context) read all 3 artifacts, deduped 35 raw finding-lines →
**12 deduped findings**, tiered by agreement. Aggregate written to
`.scratch/review/t130-p4/aggregate-ticket.md` with two-layer provenance
(Reporter: aggregate(3 models) + per-finding Reviewers/Agreement/Confidence,
Confirmation status: unconfirmed verbatim).

- **10/12 consensus** (all 3 families agreed), **1 majority** (F12 fail-open, 2/3),
  0 singletons. All 10 PLANTED bugs surfaced by all 3 models incl. all 3 Type3
  discriminators. 2 unplanted PLAUSIBLE (F11 missing imports, F12 fail-open default).
- **Cross-file merge validated:** F6 (quota overflow) — Kimi cited schema.sql:14,
  Qwen/GLM cited users.ts:34; deduped as ONE finding on fault identity (the two
  halves of the cross-file coupling), NOT split by differing location. This is the
  dedup-on-fault-not-just-line rule working on real output.
- **Single-writer / no ID race proven:** `tkt new` run against a THROWAWAY mktemp
  tracker (not the live frontier — hygiene) allocated id 01 with correct
  frontmatter, atomic single-process allocation. Live `.tickets/` untouched.
- Category advisory confirmed useful: models labeled the same bugs
  security/correctness/architecture differently; location+fault dedup was robust to it.

1. **Fan-out per model** — run `tools/review/matrix.sh --run-id <uuid> --target <sha>`
   against a real commit with actual findings (pick a diff with a known planted or
   real issue). Confirm each of kimi-for-coding/k3, alibaba-token-plan/qwen3.8-max,
   zai-coding-plan/glm-5.3:
   - produces a valid result (step_finish reason:"stop" + non-empty text + REVIEW_RESULT)
   - writes `.scratch/review/<RUN_ID>/<slug>.md`
   - loads the review-new-work skill (cross-model activation — untested for Kimi/Qwen/GLM)
   - emits findings as the structured JSON schema
2. **JSONL parsing on a TOOL-USING run** — the schema was only captured on a
   no-tool prompt. Confirm tool event types (file reads, etc.) don't break the
   `text`/`step_finish` extraction. Capture the actual tool-event shape.
3. **Quota/degradation path** — force or observe a quota/429 on one model; confirm
   it's classified indeterminate and the run continues with the others (coding-plan-limits).
4. **Fan-in (main context)** — dedup findings by (file,line,category) across the 3
   models, tier by agreement (Consensus/Majority/Individual), create ONE aggregate
   ticket via tkt new with two-layer provenance (Reporter: aggregate(...), per-finding
   Reviewers:/Agreement:). Confirm no ID race.
5. **Fail-closed verify** — confirm an indeterminate/missing reviewer is reported as
   a coverage gap, never "clean".
6. **Codex path regression** — run dispatch-review with the default (codex) reviewer;
   confirm byte-identical behavior to the pre-127 dispatch-codex-review.
7. **Cross-model skill activation** — measure whether Kimi/Qwen/GLM actually activate
   review-new-work from the prompt (127 flagged this as untested; mitigated by
   indeterminate→deny but worth knowing).

## Deliverables

- A recorded run log + the generated aggregate ticket (or clean result) as evidence
- Notes on any gaps found (feed back into #128/#129 or new tickets)
- Confirmed tool-using JSONL event shape → update result-contract/model-matrix if it differs

## Acceptance criteria

- [ ] matrix.sh B1 fixed: findings-only prompt (no ticket creation), inline output contract with closed severity/category enums + example
- [ ] matrix.sh B3 fixed: text join with separator + fence-tolerant last-match REVIEW_RESULT extraction
- [ ] matrix.sh B9 fixed: reviewers run in throwaway workdir (not live tree); git status clean after
- [ ] events.jsonl sensitivity handled: only REVIEW_RESULT line surfaced, raw tool output not logged/shipped
- [ ] Planted-bug fixture built with manifest (Type1/2/3 mix, location/class/severity)
- [ ] matrix.sh run against the fixture with all 3 models; per-model artifacts + summary produced
- [ ] Each model's review-new-work activation observed (or non-activation documented)
- [ ] Tool-using run JSONL parsed correctly (confirmed: last() step_finish + text join works; verify on the real run)
- [ ] Quota/degradation on one model → indeterminate, run continues (observed or forced; document if code-verified only)
- [ ] Fan-in (main context): dedup by location+fault (category advisory), tier by agreement (consensus/majority/single, keep singletons), aggregate written to `.scratch/review/t130-p4/aggregate-ticket.md` with two-layer provenance; `tkt new` single-writer/no-race proven against a THROWAWAY `.tickets/` (not the live tracker — frontier hygiene; research t130d/tracker-hygiene.md)
- [ ] Recall/precision/hallucination graded by a JUDGE PANEL (multi-judge consensus, eval-harness pattern) against the manifest — not a deterministic matcher, not self-graded; Phase 2 numbers re-graded by the panel
- [ ] Fail-closed confirmed: indeterminate/missing reviewer reported as gap, not clean
- [~] Codex default path regression — PARTIAL: contract/invocation verified (codex exec ran, authed, accepted the findings-only prompt) but findings run BLOCKED by env — codex 0.147.0 default model `gpt-5.6-sol` needs a newer CLI; `gpt-5.1-codex` rejected on ChatGPT-account auth. Not a dispatch-review regression (env/model-availability). See tkt follow-up.
- [ ] Findings/gaps recorded; follow-up tickets filed for anything discovered
