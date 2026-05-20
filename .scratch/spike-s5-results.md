---
created_at: 2026-05-20T06:55:00-07:00
base_commit: 4b0db2d
---

# Spike S5 Results: Per-Project Module Customization

## Use Cases Tested

1. **Godot troubleshooting** — add Godot-specific check commands to verification-protocol
2. **Custom handoff sections** — add "Deployment State" to HANDOFF.md template for infra projects
3. **Stricter git protocol** — change from "push immediately" to "PR required" for team projects
4. **Domain-specific reasoning** — add healthcare examples to five-whys skill

## Approach A: Override Files (Sidecar)

### Mechanism
Project places override files in a known location that the generator merges with the shared module.

```
project/
└── .crew-overrides/
    └── skills/
        └── verification-protocol.yaml
```

Override file (partial, merged with shared):
```yaml
# .crew-overrides/skills/verification-protocol.yaml
append_to_section: "## Project-Specific Commands"
content: |
  - Build: `godot --headless --export-debug`
  - Test: `godot --headless --script test_runner.gd`
  - Lint: `gdlint .`
```

### Evaluation Against Use Cases

| Use Case | Works? | How |
|----------|--------|-----|
| Godot troubleshooting | ✅ | Append project-specific commands section |
| Custom handoff sections | ✅ | Append "Deployment State" section to template |
| Stricter git protocol | ⚠️ Awkward | Must override entire "Workflow" section (replace, not append) |
| Domain-specific reasoning | ✅ | Append domain examples to references/ |

### Pros/Cons
- ✅ Simple to understand (one override file per customization)
- ✅ Works without generator (just concatenate files)
- ⚠️ Append-only is limiting; replacing sections requires more complex merge logic
- ❌ No validation that override targets exist (drift risk)

---

## Approach B: Inheritance (Extends)

### Mechanism
Project creates a local skill that extends a shared one, adding or overriding content.

```
project/.kiro/skills/verification-protocol/SKILL.md
```

```yaml
---
name: verification-protocol
extends: crew-research://skills/verification-protocol
---

# Verification Protocol (Project Override)

{{base}}  # inserts the shared skill content here

## Project-Specific Commands
- Build: `godot --headless --export-debug`
- Test: `godot --headless --script test_runner.gd`
```

### Evaluation Against Use Cases

| Use Case | Works? | How |
|----------|--------|-----|
| Godot troubleshooting | ✅ | Extend with project commands |
| Custom handoff sections | ✅ | Extend template with new section |
| Stricter git protocol | ✅ | Override entire skill, replace "push immediately" with "PR required" |
| Domain-specific reasoning | ✅ | Extend with domain examples |

### Pros/Cons
- ✅ Full control (can append, replace, or restructure)
- ✅ Explicit — you can see exactly what the project gets
- ✅ Works without generator (it's just a local skill that shadows the shared one)
- ⚠️ Full copy on override means drift when shared module updates
- ❌ `{{base}}` template syntax adds complexity
- ❌ Must maintain the extended skill when upstream changes

---

## Approach C: Parameterized Templates

### Mechanism
Shared skills use variables that projects fill in via a config file.

Shared skill:
```yaml
---
name: verification-protocol
params:
  build_command: "npm run build"
  test_command: "npm test"
  lint_command: "npm run lint"
---

## Project-Specific Commands
- Build: `{{params.build_command}}`
- Test: `{{params.test_command}}`
- Lint: `{{params.lint_command}}`
```

Project config:
```yaml
# .crew-config.yaml
params:
  verification-protocol:
    build_command: "godot --headless --export-debug"
    test_command: "godot --headless --script test_runner.gd"
    lint_command: "gdlint ."
```

### Evaluation Against Use Cases

| Use Case | Works? | How |
|----------|--------|-----|
| Godot troubleshooting | ✅ | Set build/test/lint params |
| Custom handoff sections | ❌ | Can't add new sections via params alone |
| Stricter git protocol | ⚠️ | Would need `git_workflow: "pr-required"` param + conditional logic |
| Domain-specific reasoning | ❌ | Can't inject arbitrary content blocks via params |

### Pros/Cons
- ✅ Simplest for value substitution (commands, paths, names)
- ✅ No drift risk (shared module is the source of truth, params are just values)
- ✅ Easy to validate (params have a schema)
- ❌ Can't handle structural changes (new sections, replaced content)
- ❌ Requires skill authors to anticipate what's parameterizable

---

## Comparison Matrix

| Criterion | Weight | A (Sidecar) | B (Extends) | C (Params) |
|-----------|--------|:-----------:|:-----------:|:----------:|
| Simplicity for skill author | High | 4 | 3 | 5 |
| Simplicity for project customizer | High | 4 | 3 | 5 |
| Handles all 4 use cases | High | 3 | 5 | 2 |
| Drift detection | Medium | 2 | 2 | 5 |
| Works without generator | Medium | 4 | 5 | 3 |
| Composability (multiple overrides) | Low | 3 | 4 | 4 |
| **Weighted Total** | | **3.4** | **3.7** | **3.7** |

## Recommendation: Hybrid (C + B)

No single approach handles all cases well. The natural split:

- **Params (C) for simple value injection** — commands, paths, names, feature flags. Covers 80% of customization needs (use cases 1, 3). Skill authors declare params with defaults.
- **Extends (B) for structural changes** — new sections, replaced content, domain-specific additions. Covers the remaining 20% (use cases 2, 4). Project creates a local skill that shadows the shared one.

### How it works together:

1. **Default (no customization):** Shared skill used as-is with default params
2. **Simple customization:** Project provides `.crew-config.yaml` with param values → generator substitutes
3. **Structural customization:** Project creates local skill with `extends:` → local shadows shared

### Resolution order:
1. Local skill (if exists) wins completely (it's the full override)
2. Else: shared skill + project params merged

### Drift detection:
- Params: no drift possible (shared module is source of truth)
- Extends: generator can warn when upstream skill changes (compare `extends` target hash)

## Decision

**S5 PASSES with hybrid approach (Params + Extends).**

File as ADR since this is hard to reverse (affects skill authoring conventions and generator design).
