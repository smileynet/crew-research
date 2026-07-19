# Q01 — Access map: which machines have which tool/model access?

**Status:** RESOLVED 2026-07-19

## Question

Is there a durable "capable machine" for deferred runs, and what exactly can each environment reach?

## Answer (user + research)

Two environments, now formally designated via gitignored `.mise.local.toml` → `CREW_ENV`:

| | corp (this machine) | personal |
|---|---|---|
| kiro-cli | ✅ | ✅ (assumed — sessions exist) |
| codex | ✅ | ✅ |
| agy | ❌ **FORBIDDEN — company policy. Remove; never deploy/run.** | ✅ |
| crush | ⚠️ via **AWS Bedrock only** (no Z.AI) | ✅ (Z.AI GLM-5.2) |

## Research findings

- **agy on corp:** binary was already absent; deploy artifacts existed (`~/.gemini/AGENTS.md`, `antigravity-cli/`, `.crew-skills-agy`) from tier deploys — REMOVED 2026-07-19. Enforcement (init.sh refusal, doctor check, harness policy-block) → ticket 36.
- **crush + Bedrock** [crush docs, verified 2026-07-19]: official support; auto-detects AWS creds; requires `AWS_REGION`/`AWS_PROFILE`; **Anthropic models only** through the native Bedrock provider; **prompt caching disabled** (higher cost per repeated-context call — relevant for judge loops). Source: charmbracelet-crush.mintlify.app/advanced/amazon-bedrock.
- **Bedrock pool in this account** [aws bedrock list-foundation-models, 2026-07-19]: Claude family incl. haiku-4.5, sonnet-4.6, sonnet-5, opus-4.5→4.8, fable-5 (all INFERENCE_PROFILE). Non-Anthropic text models exist (nova-lite/micro, glm-4.7/-flash, glm-5, deepseek-v3.2, qwen3-coder, llama3.x/4, ministral) but are NOT reachable through crush's native Bedrock provider — only via a custom provider or direct `bedrock invoke-model` (spike option, ticket 35).

## Implications applied

- Ticket 30 (image defs): birth runs stay **personal-only** — the defs' premise is GLM's missing vision; crush-on-corp runs Claude, which HAS vision, breaking the "steepest behavioral delta" design.
- Ticket 31: reworked — corp crush completeness = Bedrock configuration + probe, not just file deploy.
- Ticket 35: corp gains a real cheap-judge candidate (haiku-4.5 via crush-bedrock) and a possible aws-CLI judge leg for non-Anthropic models (spike).
- Ticket 36 (new): CREW_ENV designation + agy policy enforcement.
- All open tickets carry `env: corp | personal | either` frontmatter.
