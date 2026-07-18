# kiro-cli Agent Config Shape (verified 2026-07-18)

Minimal working specialist agent (`~/.kiro/agents/<name>.json`):

```json
{
  "name": "sa-example",
  "description": "One-line domain description",
  "mcpServers": {
    "domain-mcp": { "command": "domain-mcp", "args": [], "timeout": 60000 }
  },
  "tools": ["@builtin", "@domain-mcp", "@essential-a-mcp", "@essential-b-mcp"],
  "useLegacyMcpJson": true
}
```

Field-by-field, with the failure mode each one prevents:

| Field | Without it |
|-------|-----------|
| `tools` incl. `@builtin` | Agent loads ZERO tools — not even file/shell built-ins |
| `tools` incl. `@<own-server>` | Own mcpServers entries load but stay invisible |
| `tools` incl. `@<essential>` | Inherited global servers stay invisible (whitelist gates inheritance too) |
| `useLegacyMcpJson: true` | No inheritance of global mcp.json at all — opt-in, not default |
| `model` unset | (preference) inherits session default; pinning fragments behavior |

Notes:

- Docs mention both `includeMcpJson` and `useLegacyMcpJson`; `useLegacyMcpJson: true` is the verified-working inheritance key.
- Precedence on server-name collision: agent config > workspace mcp.json > global mcp.json.
- Config changes apply to NEW sessions only; running sessions keep loaded servers.
- Auto-approval hardening: `allowedTools` with read-glob patterns (`@server/get_*`, `@server/list_*`, `@server/search*`); writes stay prompt-gated.
- Non-interactive probes fail fast on approval prompts — pass `--trust-tools=@server/<specific-tool>` (never `--trust-all-tools`).
- kiro-cli survives SIGTERM; wrap probes in `timeout -k <grace> <limit>`.
- kiro-cli atomically rewrites `~/.kiro/settings/cli.json` every session — that file is content-managed (copy, diff), never symlinked.

Example probe (positive, with sentinel):

```bash
timeout -k 5 180 kiro-cli chat --agent sa-example --no-interactive \
  --trust-tools=@domain-mcp/health_check \
  "Call domain-mcp health_check. If it succeeds reply exactly DOMAIN_OK" \
  | grep -q DOMAIN_OK
```
