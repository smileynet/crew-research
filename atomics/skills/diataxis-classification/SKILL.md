---
name: diataxis-classification
description: "Classify documentation by audience and content type. Use when planning, auditing, or placing project documentation."
metadata:
  type: reference
  invocation: both
  practice: null
---

# Documentation Classification

Two questions: **Who reads this?** then **What do they need?**

## 1. Audience (pick one per document)

| Audience | Entry Point | Voice | Key Question |
|----------|-------------|-------|--------------|
| **Agents** | AGENTS.md | Imperative, terse, verifiable | "What do I DO?" |
| **Users** | README.md | Welcoming, progressive | "How do I USE this?" |
| **Maintainers** | CONTRIBUTING.md | Technical, explains why | "How do I CHANGE this?" |

Mixing audiences in one document serves neither. Split.

## 2. Content Mode (within each audience)

| Mode | Reader State | Structure | Example |
|------|-------------|-----------|---------|
| **Learning** (tutorial) | Beginner | Numbered steps, verify each | "Build your first widget" |
| **Doing** (how-to) | Has a problem | Goal → steps → done | "How to configure auth" |
| **Looking up** (reference) | Needs a fact NOW | Tables, alphabetical | CLI flags, API reference |
| **Understanding** (explanation) | Curious, has time | Prose, diagrams, tradeoffs | "Why event sourcing" |

## 3. Placement

| Type | Path | Litmus Test |
|------|------|-------------|
| Scratch/working notes | `.scratch/` | "Am I still working on this?" |
| Durable decisions | `.memory/adr/` | "What did we decide and why?" |
| Glossary/terms | `.memory/CONTEXT.md` | "What does this term mean?" |
| Research findings | `.scratch/research/` | "What did we learn?" (promote to .memory if lasting) |
| User-facing docs | `docs/` | "Does a USER need to read this?" (only when deliberately requested) |
| Agent skills/steering | `.kiro/skills/`, `.kiro/steering/` | "Does an AGENT need this every session?" |

**Default**: `.scratch/` (ephemeral) or `.memory/` (durable). Only `docs/` when explicitly requested for user-facing publication.

## 4. Right-Sizing

| Project Maturity | Required Docs |
|-----------------|---------------|
| Weekend hack | README.md |
| Team project (>2 weeks) | + AGENTS.md, .memory/CONTEXT.md |
| Multiple contributors | + ADRs, onboarding guide, CONTRIBUTING.md |
| Public/OSS | + docs/ with tutorials, reference, troubleshooting |

## Rules

- One audience per document (README is the exception — it routes)
- Agent docs are separate from human docs (different requirements)
- Don't create docs nobody will read — right-size to maturity
- Check existing folder conventions before placing — match what's there
