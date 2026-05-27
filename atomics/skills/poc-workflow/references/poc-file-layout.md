# PoC File Organization

## Layout

```
project/
├── README.md                    # Usage instructions (created last)
├── context.md                   # Quick-reference for any session
├── proposal-plan.md             # Active implementation plan (living doc)
├── .memory/                     # Durable reference (tracked)
│   ├── decisions.md             # Architecture decisions with rationale
│   ├── requirements.md          # Customer/project requirements
│   ├── research-synthesis.md    # Synthesized research findings
│   ├── spike-N-findings.md      # Per-spike results
│   └── phase-N-findings.md      # Per-phase validation results
├── .scratch/                    # Ephemeral research (gitignored)
├── docs/
│   ├── adr/                     # Hard-to-reverse decisions only
│   └── specs/                   # Feature specs
├── infra/                       # Infrastructure as code
└── src/                         # Application code
```

## Placement Rules

| Content | Location | Tracked? |
|---------|----------|----------|
| Architecture decisions | `.memory/decisions.md` | Yes |
| Requirements | `.memory/requirements.md` | Yes |
| Research synthesis | `.memory/research-synthesis.md` | Yes |
| Spike/phase findings | `.memory/spike-N-findings.md` | Yes |
| Raw research output | `.scratch/` | No |
| Hard-to-reverse decisions | `docs/adr/NNN-title.md` | Yes |
| Feature specs | `docs/specs/` | Yes |
| Implementation plan | `proposal-plan.md` (root) | Yes |
| Quick reference | `context.md` (root) | Yes |

## ADR Criteria

Create an ADR when ALL THREE are true:
- Hard to reverse
- Surprising without context
- Has a real trade-off (rejected alternatives exist)

Otherwise → `.memory/decisions.md`

## Commit Convention

```
type(scope): description

Types: feat, fix, docs, refactor, spike
Scope: research, design, plan, build, validate
```
