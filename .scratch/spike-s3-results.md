---
created_at: 2026-05-20T06:45:00-07:00
base_commit: 42d04e8
---

# Spike S3 Results: Codex/Pi Skill Format Validation

## Method
Research via GitHub issues, official docs, and reference repo documentation. No live testing (no Codex/Pi installations available).

## Findings

### Codex CLI

From GitHub issue openai/codex#5291 ("Support for SKILL.md files", Oct 2025, closed):
- Codex added SKILL.md support following the Agent Skills standard
- Discovery path: `~/.codex/skills/**/SKILL.md` (recursive)
- Frontmatter: `name` and `description` required (per Agent Skills standard)
- The issue was filed as a feature request and was implemented (closed)

From nicobailon's pi-mono docs (which documents cross-tool compatibility):
- `~/.codex/skills/**/SKILL.md` (Codex CLI, recursive)
- Codex follows the same progressive disclosure model

**Unknown field tolerance: NOT CONFIRMED.** No documentation or issues found specifically addressing whether Codex strips or errors on unknown frontmatter. Given it follows the Agent Skills standard (which only specifies `name`, `description`, `license`, `compatibility`, `metadata`), unknown fields are likely ignored but this needs live testing.

### Pi

From nicobailon's pi-mono/packages/coding-agent/docs/skills.md:
- Discovery: `~/.pi/agent/skills/**/SKILL.md` (recursive)
- Required frontmatter: `name`, `description`
- Optional: `license`, `compatibility`, `metadata`, `allowed-tools`
- Name validation: lowercase a-z, 0-9, hyphens, must match directory name
- Follows Agent Skills standard (agentskills.io/specification)

**Unknown field tolerance: LIKELY SAFE.** The Agent Skills spec says `metadata` is an "arbitrary key-value mapping for additional metadata" — this suggests the standard is designed to be extensible. Pi's implementation likely ignores unknown top-level fields.

### Agent Skills Standard (agentskills.io)

The standard specifies:
- Required: `name`, `description`
- Optional: `license`, `compatibility`, `metadata`, `allowed-tools`
- The `metadata` field is explicitly for arbitrary extensions

## Compatibility Matrix

| Field | kiro-cli | Claude Code | Codex | Pi |
|-------|----------|-------------|-------|-----|
| `name` | ✅ Used | ✅ Used | ✅ Used | ✅ Used |
| `description` | ✅ Used | ✅ Used | ✅ Used | ✅ Used |
| `type` (ours) | Ignored | Stripped (harmless) | Likely ignored | Likely ignored |
| `invocation` (ours) | N/A (generator maps) | N/A (generator maps) | N/A | N/A |
| `practice` (ours) | Ignored | Stripped (harmless) | Likely ignored | Likely ignored |
| `disable-model-invocation` | ❓ Unknown | ✅ Native | ❓ Unknown | ❓ Unknown |
| `allowed-tools` | ❓ Unknown | ✅ Native | ❓ Unknown | ✅ Native |

## Decision

**S3 PARTIALLY PASSES (with deferred live testing).**

- The Agent Skills standard is designed for extensibility (`metadata` field)
- Claude Code confirmed: unknown fields stripped harmlessly
- Codex and Pi: highly likely safe based on standard compliance, but NOT confirmed with live testing
- No evidence of any tool erroring on unknown fields

## Risk Mitigation

Even if a tool rejects unknown fields, our generator can strip them during deployment. The source format is unaffected. This is a delivery concern, not a design concern.

## Remaining Work

- Live test with Codex CLI when access is available
- Live test with Pi when access is available
- Until confirmed, generator should have a `strip_unknown_frontmatter` option (disabled by default, enable per-adapter if needed)
