# Feature Spec Template

Copy this template to `.specs/{feature-slug}.md` for each feature.

```markdown
# Feature: [Name]

## Status
Draft | Accepted | Implemented | Reconciled | Validated

## What
One paragraph: what this feature does.

## Who / Why
Who uses it, what problem it solves for them.

## Non-Goals
What this feature explicitly does NOT do. Prevents scope creep.
- Does NOT handle [X]
- Does NOT support [Y]

## Requirements
- [ ] Functional requirement 1
- [ ] Functional requirement 2
- [ ] Non-functional (performance, security, etc.)

## Validation
How we prove it works:
- **Blackbox**: input X → expect output Y
- **Visual**: screenshot comparison, UI state check
- **Real-world**: user workflow end-to-end
- **Automated**: test commands that pass/fail

## Unresolved Questions
- Open question needing answer before/during implementation
- (Remove this section once all resolved)

## Alternatives Considered
- Option B: why we didn't choose it
- Option C: tradeoff that made it inferior
```

## Notes

- Non-Goals is mandatory for complexity 3+
- Validation must be concrete and testable — no "it works correctly"
- Unresolved Questions block progression to "Accepted" status
- After implementation, reconcile: update spec to match reality if it diverged
