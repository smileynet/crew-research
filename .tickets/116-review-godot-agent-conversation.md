---
id: "116"
title: "Review: Godot Agent provider-neutral conversation format"
status: backlog
blocked_by: []
priority: medium
validation_criteria:
  - "Canonical format documented (message structure, tool calls, tool results)"
  - "Provider conversion layer analyzed (how Anthropic→OpenAI→Gemini adapts)"
  - "ConversationStore persistence pattern documented"
  - "Agent signal decoupling pattern assessed for reusability"
  - "Recommendations: what to adopt, what to skip, where it applies"
---

# Review: Godot Agent provider-neutral conversation format

## Context

Godot Agent (https://github.com/mschunke/godot_agent) has the best architecture in the AI-integration batch from our Asset Library deep-dive. Its key pattern: store all messages in Anthropic-style block format as the canonical internal representation, convert at the transport boundary per provider.

This was identified during godot-helper's Asset Library exploration (61 repos deep-dived, 2026-08-18).

## What to review

1. **Canonical format** — Read `core/conversation.gd` and document the message structure (roles, content blocks, tool_use, tool_result)
2. **Provider adapters** — Read `providers/` (base + Anthropic, OpenAI, Gemini). Document how each converts canonical → provider-native on send, and provider-native → canonical on receive
3. **tool_schemas.gd** — How are tools defined provider-independently? How does each adapter convert schemas to its native format?
4. **ConversationStore** — How is history persisted? What format on disk? Can you switch providers mid-conversation?
5. **Agent signals** — Document the signal-based decoupling (`message_appended`, `tool_started`, `tool_finished`, `turn_started/finished`)
6. **Architecture quality** — File sizes, separation of concerns, layer boundaries

## Source

- Cloned at: `~/code/godot-helper/.references/asset-library/godot-agent/`
- GitHub: https://github.com/mschunke/godot_agent
- Asset Library: https://godotengine.org/asset-library/asset/5354

## Related

- `gdhelper-harness #10` — Spike: structured event emission for stage transitions
- `~/code/godot-helper/.memory/research/asset-library-findings.md` — full ecosystem analysis
- Pydantic AI provides equivalent model abstraction in Python (see `.memory/research/pydantic-ai-framework.md` in gdhelper-harness)

## Acceptance criteria

- [ ] Canonical message format fully documented with examples
- [ ] Provider conversion logic mapped (what changes per provider)
- [ ] ConversationStore persistence format documented
- [ ] Agent signal pattern assessed: applicable to our harness event system?
- [ ] Recommendation: adopt (with ticket), study only, or skip
