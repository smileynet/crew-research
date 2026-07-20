---
kind: constraint
id: skeleton-intersection-contract
from_patterns:
  - "pattern:intersection-contract"
confidence: "—"
protects_experience: "pf-consistent-agent-behavior"
user_story: "Every existing ticket in the repo is valid under the shared contract without edits, so agents in any repo read the same shapes."
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
  expect: absent
links:
  - target: "pattern:intersection-contract"
    type: constrains
---

# Skeleton: Existing Tickets Valid Under the Intersection Contract

## Rule

Every `.tickets/*.md` file has a closed frontmatter fence, the four core fields (id, title, status, blocked_by), a status in `open | in_progress | done`, and an id matching its filename prefix.

## Rationale

The contract's zero-migration commitment (intersection-contract Therefore) — if any existing ticket fails this, the "verified intersection" claim is wrong and the pattern's assumptions break.

## Violations Look Like

```
38-tk-like-ticket-cli.md: status not in contract vocabulary: closed
```
