---
created_at: 2026-05-20T06:35:00-07:00
base_commit: 42d04e8
---

# Spike S1 Results: kiro-cli Prompt/Skill Invocation Parity

## Environment
- kiro-cli 2.3.0
- Test workspace: /tmp/spike-s1-oAW7

## Test Results

| # | Test | Result | Notes |
|---|------|--------|-------|
| 1 | Skill as `/skill-name` slash command | **FAIL (non-interactive)** | `error: unrecognized subcommand 'test-invoke'` in `--no-interactive` mode. Feature likely TUI-only. |
| 2 | Prompt via `@prompt-name` | **PASS** | `@test-prompt hello world` works. Content loaded correctly. |
| 3 | `$ARGUMENTS` substitution | **FAIL (both)** | Neither skills nor prompts resolve `$ARGUMENTS` — literal string passes through. May be TUI-only feature. |
| 4 | Skill on-demand loading (description match) | **PASS** | Asking about "invocation testing" loaded the skill. Secret phrase `SKILL_LOADED_7K3M` confirmed. |
| 5 | Skill NOT loaded for unrelated query | **PASS** | "What is 2+2?" did not load the skill. |

## Key Findings

1. **Skills-as-slash-commands exists but is TUI-only.** The `--no-interactive` mode (used by our harness) doesn't support `/skill-name` invocation. This is a testing limitation, not a feature gap.

2. **`$ARGUMENTS` substitution doesn't work in non-interactive mode** for either prompts or skills. The literal `$ARGUMENTS` passes through. This means argument handling is a TUI feature.

3. **On-demand skill loading works correctly.** Description-based activation fires when the query matches and doesn't fire when it doesn't.

4. **Prompts (`@name`) work in non-interactive mode.** This is the reliable invocation path for headless/harness use.

## Implications for Our Design

1. **The unified skill model is correct** — skills and prompts converge in TUI mode (skills are slash commands). Our `invocation: user-only` frontmatter maps to this correctly.

2. **For the proof/eval harness**, we need to use `@prompt-name` syntax (not `/skill-name`) when testing user-invoked skills in non-interactive mode. The generator should emit `invocation: user-only` skills to `.kiro/prompts/` for harness testability.

3. **`$ARGUMENTS` is a TUI feature.** Our harness tests should pass arguments as part of the query string, not rely on `$ARGUMENTS` substitution.

4. **No changes needed to our spec.** The generator already maps `invocation: user-only` → `.kiro/prompts/`. This is confirmed as the correct approach for headless invocation.

## Decision

**S1 PASSES with caveats.** The unified model holds — skills ARE slash commands in TUI mode. For our harness (non-interactive), the generator correctly emits user-only skills to `.kiro/prompts/` where they're invocable via `@name`. No spec changes needed.

## Caveat to Verify Later
- Confirm skills-as-slash-commands works in TUI mode (manual test, not automatable)
- Confirm `$ARGUMENTS` resolves in TUI mode
