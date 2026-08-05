#!/usr/bin/env bash
# prose-instrument-validation.sh — E-INST-1 (ticket 87).
#
# Question: can the STE linter separate shipped crew-research prose from unguided
# LLM first drafts? If the distributions overlap, the metric is a within-pair delta
# probe and never a gate (which decides ticket 84).
#
# Design: docs/development/prose-hygiene-eval-design-2026-08-05.md § E-INST-1
# Usage:  bash tools/evals/experiments/prose-instrument-validation.sh [outdir]
#         GENERATE=0 to score only (reuse cached set B)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
LINT="$REPO/.references/woosal-blog/videos/ep01-the-cure-for-ai-slop/ste-lint.py"
SAMPLES="$REPO/.references/woosal-blog/videos/ep01-the-cure-for-ai-slop/before-after-samples.md"
OUT="${1:-$REPO/tools/evals/results/prose-instrument-$(date -u +%Y-%m-%dT%H-%M-%SZ)}"
GENERATE="${GENERATE:-1}"
CACHE="$REPO/tools/evals/results/prose-instrument-cache"   # set B survives re-runs

[[ -f "$LINT" ]] || { echo "Missing linter. Clone the reference:" >&2
  echo "  git clone --depth 1 https://github.com/woosal1337/blog.git .references/woosal-blog" >&2; exit 2; }

mkdir -p "$OUT" "$CACHE/set-b"
SCORES="$OUT/scores.jsonl"; : > "$SCORES"

# --- Set A: shipped crew-research prose ------------------------------------------
# Honest label: LLM-drafted, human-reviewed, written under our style guidance.
# NOT "human-written" — that distinction matters when reading the result.
SET_A=(
  "README.md"
  "AGENTS.md"
  ".memory/adr/0010-judge-tier-policy.md"
  ".memory/adr/0002-per-project-customization.md"
  ".memory/CONTEXT.md"
  "docs/development/cross-family-judging-2026-07-27.md"
  "docs/development/model-positioning-2026-07-27.md"
  "atomics/skills/writing-style/SKILL.md"
  "atomics/skills/code-review/SKILL.md"
  "atomics/skills/verification-protocol/SKILL.md"
  "atomics/skills/handoff/SKILL.md"
  "atomics/eager-context/verification.md"
  "atomics/eager-context/workspace.md"
)

# --- Set B: unguided LLM first drafts, matched to our content types ---------------
# Prompts carry NO writing guidance: no length, tone, or style instruction.
# KIRO_HOME points at an empty dir so global steering cannot leak in (same
# isolation the eval harness uses for baseline conditions).
declare -A SET_B=(
  [readme-intro]="Write the introduction section of a README for 'fluxcache', a semantic caching library for LLM applications."
  [readme-quickstart]="Write the quick start section of a README for a CLI tool called 'tkt' that manages tickets as markdown files in a git repo."
  [error-message]="Write the user-facing error message a REST API returns when a client exceeds its rate limit of 100 requests per minute."
  [error-message-2]="Write the error message a build tool shows when a config file references an environment variable that is not set."
  [cli-help]="Write the --help output description for a command that deploys skills to a project directory."
  [changelog]="Write a changelog entry for a release that fixed a bug where cached responses were returned after their expiry time."
  [pr-description]="Write a pull request description for a change that adds retry with exponential backoff to an HTTP client."
  [adr-paragraph]="Write the context and decision sections of an architecture decision record about choosing SQLite over Postgres for a local desktop application."
  [api-docs]="Write the API reference documentation for a function 'embed(text, model)' that returns a vector embedding."
  [getting-started]="Write a getting started guide for a Python library that validates YAML configuration files against a schema."
  [deprecation]="Write a deprecation notice for a function 'get_user_by_email' that is replaced by 'find_user'."
  [design-doc]="Write the overview section of a design document for a service that ingests logs and answers questions about them."
)

clean_output() {  # strip CLI chrome, ANSI, response prefix, and code-fence wrappers
  sed 's/\x1b\[[0-9;?]*[a-zA-Z]//g' \
    | grep -vE '^Warning: creds_agent' \
    | grep -vE '^ *▸ (Credits|Time):' \
    | grep -vE '^📷' \
    | sed 's/^> //' \
    | sed -E '/^(```|`{3}[a-z]*|markdown)$/d'
}

if [[ "$GENERATE" == "1" ]]; then
  echo "Generating set B (unguided drafts, KIRO_HOME isolated)..."
  for name in "${!SET_B[@]}"; do
    target="$CACHE/set-b/$name.md"
    if [[ -s "$target" ]]; then echo "  = $name (cached)"; continue; fi
    W=$(mktemp -d -t prose-gen-XXXX); mkdir -p "$W/.kiro-empty"
    ( cd "$W" && KIRO_HOME="$W/.kiro-empty" timeout 240 \
        kiro-cli chat --no-interactive --wrap never "${SET_B[$name]}" 2>&1 ) \
      | clean_output > "$target" || true
    rm -rf "$W"
    words=$(wc -w < "$target")
    echo "  + $name ($words words)"
  done
fi

# --- Set C: the source's own quoted samples (small positive control) --------------
mkdir -p "$OUT/set-c"
python3 - "$SAMPLES" "$OUT/set-c" <<'PY'
import re, sys, os
src, out = sys.argv[1], sys.argv[2]
text = open(src).read()
# Quoted sample blocks are markdown blockquotes preceded by a BASELINE/STE label.
blocks, label, buf = [], None, []
for line in text.split("\n"):
    m = re.match(r"\*\*(BASELINE|STE)\*\*", line) or re.match(r"^(Baseline|STE) \(", line)
    if m:
        if label and buf: blocks.append((label, "\n".join(buf)))
        label, buf = m.group(1).lower(), []
        continue
    if line.startswith(">"):
        buf.append(line.lstrip("> ").rstrip())
    elif buf and not line.strip():
        continue
if label and buf: blocks.append((label, "\n".join(buf)))
n = {}
for lab, body in blocks:
    if len(body.split()) < 40: continue      # source warns rates are noise under ~50 words
    n[lab] = n.get(lab, 0) + 1
    open(os.path.join(out, f"{lab}-{n[lab]}.md"), "w").write(body + "\n")
print(f"  set C extracted: {sum(n.values())} block(s) {n}")
PY

# --- Score everything ------------------------------------------------------------
score_file() {  # score_file <set> <label> <path>
  python3 "$LINT" < "$3" | python3 -c "
import json,sys
d=json.load(sys.stdin)
d['set']='$1'; d['label']='$2'
print(json.dumps(d))
" >> "$SCORES"
}

echo "Scoring..."
for f in "${SET_A[@]}"; do [[ -f "$REPO/$f" ]] && score_file A "$f" "$REPO/$f"; done
for f in "$CACHE/set-b"/*.md;  do [[ -s "$f" ]] && score_file B "$(basename "$f" .md)" "$f"; done
for f in "$OUT/set-c"/*.md;    do [[ -s "$f" ]] && score_file C "$(basename "$f" .md)" "$f"; done

# --- Analysis --------------------------------------------------------------------
python3 - "$SCORES" "$OUT/summary.json" <<'PY'
import json, sys, statistics as st
rows = [json.loads(l) for l in open(sys.argv[1])]
def grp(s): return [r for r in rows if r["set"] == s]
A, B, C = grp("A"), grp("B"), grp("C")
def val(r): return r["total_per100w"]

def stats(g):
    v = sorted(val(r) for r in g)
    if not v: return {}
    return {"n": len(v), "min": v[0], "median": st.median(v), "max": v[-1],
            "mean": round(st.mean(v), 2)}

# Probability of superiority (Mann-Whitney U / |A||B|): chance a random set-B doc
# scores worse than a random set-A doc. 0.5 = no discrimination, 1.0 = perfect.
def pos(a, b):
    if not a or not b: return None
    wins = ties = 0
    for x in (val(r) for r in b):
        for y in (val(r) for r in a):
            if x > y: wins += 1
            elif x == y: ties += 1
    return round((wins + 0.5 * ties) / (len(a) * len(b)), 3)

overlap = None
if A and B:
    amin, amax = min(map(val, A)), max(map(val, A))
    bmin, bmax = min(map(val, B)), max(map(val, B))
    inter = max(0.0, min(amax, bmax) - max(amin, bmin))
    union = max(amax, bmax) - min(amin, bmin)
    overlap = round(inter / union, 3) if union else 1.0
    b_above_a_max = sum(1 for r in B if val(r) > amax)

cats = {}
for r in rows:
    for k, x in r["violations"].items():
        d = cats.setdefault(k, {"A": 0, "B": 0, "C": 0, "words_A": 0, "words_B": 0, "words_C": 0})
        d[r["set"]] += x
for s, g in (("A", A), ("B", B), ("C", C)):
    for k in cats: cats[k][f"words_{s}"] = sum(r["words"] for r in g)
cat_rate = {k: {s: round(v[s] * 100.0 / max(1, v[f"words_{s}"]), 2) for s in "ABC"} for k, v in cats.items()}

p = pos(A, B)
# Length-matched re-check: the source warns per-100-word rates are noise under ~50
# words, so a verdict driven by short docs would be an artifact. >=100 words only.
A_long = [r for r in A if r["words"] >= 100]
B_long = [r for r in B if r["words"] >= 100]
p_long = pos(A_long, B_long)
verdict = ("REJECT-AS-GATE: distributions overlap; use as within-pair delta only"
           if (p is None or p < 0.75 or (overlap or 1) > 0.5)
           else "CANDIDATE-GATE: sets separate; threshold may be defensible")

summary = {
    "question": "Does the STE linter separate shipped crew-research prose (A) from unguided LLM first drafts (B)?",
    "sets": {"A_shipped": stats(A), "B_unguided": stats(B), "C_source_control": stats(C)},
    "discrimination": {"probability_of_superiority_B_over_A": p,
                       "range_overlap_fraction": overlap,
                       "B_docs_above_A_max": b_above_a_max if A and B else None},
    "length_matched_over_100w": {"A": stats(A_long), "B": stats(B_long),
                                 "probability_of_superiority_B_over_A": p_long},
    "per_category_per100w": cat_rate,
    "em_dashes": {s: sum(r["em_dash(slop-marker)"] for r in g) for s, g in (("A", A), ("B", B), ("C", C))},
    "em_dash_per100w": {s: round(sum(r["em_dash(slop-marker)"] for r in g) * 100.0
                                / max(1, sum(r["words"] for r in g)), 2)
                        for s, g in (("A", A), ("B", B), ("C", C))},
    "short_docs_under_100w": [r["label"] for r in rows if r["words"] < 100],
    "verdict": verdict,
}
json.dump(summary, open(sys.argv[2], "w"), indent=2)
print(json.dumps(summary, indent=2))
PY

echo
echo "Wrote: $SCORES"
echo "       $OUT/summary.json"
