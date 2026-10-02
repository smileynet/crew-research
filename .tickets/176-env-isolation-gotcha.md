---
id: "176"
title: "Document 2.24 environment isolation (.env no longer auto-loads) in environment-gotchas"
status: open
blocked_by: []
tags: [kiro-v3]
---

# Gotcha: kiro-cli 2.24 environment isolation

## Fact

kiro-cli **2.24.0** (changelog): project `.env` files **no longer auto-load** into
chat sessions, MCP servers, or tools. Kiro inherits only the terminal env. Vars must
be exported in the shell or referenced in MCP server config.

## crew-research exposure (checked 2026-10-02)

LOW. Shipped tooling does NOT rely on `.env` passthrough — the `.env` references in
the repo are eval fixtures/results, not runtime. crush-via-Bedrock `AWS_PROFILE` /
`AWS_REGION` are shell-exported (per user-setup-guide + crush-bedrock.md), not from a
project `.env`, so they're unaffected. No action beyond documentation.

## What to build

- One entry in the environment-gotchas steering (symptom → cause → fix):
  symptom = an MCP server / tool mysteriously missing an env var it had before;
  cause = 2.24 isolation stopped auto-loading project `.env`;
  fix = export in shell or put it in the MCP server's config `env` block.
- Note it's a kiro-cli ≥ 2.24 behavior; harmless for crew-research's own runtime but
  bites any project assuming `.env` reaches chat/MCP/tools.

## Acceptance criteria

- [ ] environment-gotchas entry added (symptom/cause/fix, version-tagged ≥2.24)
- [ ] Notes crew-research's own low exposure (shell-exported, not .env-dependent)
