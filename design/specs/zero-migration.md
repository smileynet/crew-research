---
kind: constraint
id: zero-migration
from_patterns:
  - "pattern:intersection-contract"
confidence: "★★"
protects_experience: "exp-same-everywhere"
user_story: "Every ticket written before tkt existed is a first-class ticket after — nobody migrates anything."
check:
  method: script
  command: |
    for f in .tickets/*.md; do
      b=${f##*/}
      if [ "$(grep -c "^-\{3\}$" "$f")" -lt 2 ]; then echo "$b: no closed frontmatter fence"; continue; fi
      fm=$(sed -n "2,/^-\{3\}$/p" "$f")
      id=$(printf %s "$fm" | sed -n "s/^id: *\"\{0,1\}\([0-9][0-9-]*\)\"\{0,1\}.*/\1/p" | head -1)
      st=$(printf %s "$fm" | sed -n "s/^status: *//p" | head -1)
      printf %s "$fm" | grep -q "^title:" || echo "$b: missing title"
      printf %s "$fm" | grep -q "^blocked_by:" || echo "$b: missing blocked_by"
      [ -n "$id" ] || echo "$b: missing id"
      case "$st" in open|done|in_progress) ;; *) echo "$b: status not in contract vocabulary: $st" ;; esac
      case "$b" in "$id"-*) ;; *) echo "$b: id/filename mismatch (id=$id)" ;; esac
    done
    ls .tickets/*.md | sed "s|.tickets/||; s|-.*||" | sort | uniq -d | sed "s/^/duplicate id: /"
    for f in .tickets/*.md; do
      for dep in $(sed -n "s/^blocked_by: *\[\(.*\)\]/\1/p" "$f" | tr -d "\" " | tr "," "\n"); do
        [ -n "$dep" ] && ls .tickets/"$dep"-*.md >/dev/null 2>&1 || { [ -n "$dep" ] && echo "${f##*/}: dangling blocked_by ref: $dep"; }
      done
    done
  expect: absent
links:
  - target: "contract:frontmatter-contract"
    type: constrains
---

# Zero Migration: Existing Corpus Valid Under the Contract

## Rule

Every existing `.tickets/*.md` parses under the frontmatter contract: closed fence, required fields, contract status vocabulary, id↔filename match, no duplicate ids, no dangling `blocked_by` references.

## Rationale

intersection-contract's Therefore claims the contract is "the verified intersection" — this check IS the verification, kept running so contract drift (or a hand-written ticket that breaks the contract) surfaces immediately. Runs against the live corpus today, pre-implementation.

## Violations Look Like

```
42-new-thing.md: status not in contract vocabulary: closed
43-other.md: dangling blocked_by ref: 99
```

## Correct Usage

Every ticket carries `id`/`title`/`status: open|in_progress|done`/`blocked_by` with the id matching the filename prefix.
