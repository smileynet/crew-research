# planted-review fixture

A small TypeScript user-directory service with 10 deliberately planted defects,
ground-truth in `manifest.yaml`. Used to e2e-validate the dispatch-review
multi-model matrix (ticket 130): does each model catch the planted bugs, and does
consensus tiering improve precision?

## Layout

```
project/
  src/users.ts        B1 SQL-injection (T1, security), B2 int-overflow×schema.sql (T3)
  src/schema.sql      (cross-file half of B2)
  src/auth.ts         B3 inverted authz (T2, security), B4 swallowed exception (T1)
  src/pagination.ts   B5 off-by-one (T1), B6 mutable default bucket (T2)
  src/storage.ts      B7 TOCTOU race (T3), B8 handle leak on early return (T2)
  test/auth.test.ts   B9 over-mock masks auth bug (T3), B10 test theater (T1)
manifest.yaml         expected_findings ground truth (file/line/category/severity/type)
```

Bugs use NOVEL framing (a project-specific business rule, a custom pagination
convention) rather than textbook patterns, to resist model memorization. The
Type3 bugs (B2/B7/B9) span files or require concurrency/contract reasoning — they
discriminate reviewers that reason from those that pattern-match.

## Running the e2e (ticket 130)

matrix.sh reviews a git worktree at `--target <sha>`, so the fixture must be a git
repo with a tip commit. It is NOT committed as a nested repo inside crew-research;
instead, stage a throwaway copy at run time:

```bash
# 1. stage a throwaway git repo from the fixture project
TMP=$(mktemp -d); cp -r project/* "$TMP"/
git -C "$TMP" init -q && git -C "$TMP" add -A && git -C "$TMP" commit -qm "fixture"
TARGET=$(git -C "$TMP" rev-parse HEAD)

# 2. fan out (Git Bash on Windows — opencode is native there, not WSL)
bash tools/review/matrix.sh --run-id <uuid> --target "$TARGET" --dir "$TMP"

# 3. fan-in (main context): read .scratch/review/<uuid>/*.md, dedup, tier,
#    score against manifest.yaml (same_file ∧ line±5 ∧ category), report
#    recall/precision/hallucination per model + per consensus tier.
```

## Scoring

A reported finding is CONFIRMED (TP) when `same_file ∧ line_within_±5 ∧
category_eq` matches a manifest entry (one-to-one). Unmatched-but-real =
PLAUSIBLE (excluded from FP). Unmatched-not-real = FABRICATED (hallucination).
Report recall, precision, hallucination-rate (FDR); expect honest frontier recall
~15-47% — 90%+ means the fixture is too easy or memorized.
