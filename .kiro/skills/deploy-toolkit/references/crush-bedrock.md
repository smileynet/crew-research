# Crush on AWS Bedrock (corp configuration)

Verified 2026-07-27 (ticket 31), crush v0.85.0, account 563171622587
(sabiggin-isengard), us-west-2.

## Configuration

Crush auto-detects AWS credentials — no crush-side config file needed:

```bash
export AWS_PROFILE=sabiggin-isengard   # ada-managed; cost lands on this account
export AWS_REGION=us-west-2
crush run --quiet --model "bedrock/us.anthropic.claude-haiku-4-5-20251001-v1:0" "Reply with exactly: OK"
# -> OK   (the sentinel probe)
```

## Model naming gotcha

Bedrock models require the `bedrock/` provider prefix AND the `us.` inference-profile
prefix — the bare Bedrock model id fails with `large model "..." not found`:

- ❌ `anthropic.claude-haiku-4-5-20251001-v1:0`
- ✅ `bedrock/us.anthropic.claude-haiku-4-5-20251001-v1:0`

Discover the live list: `crush models | grep '^bedrock/'` (requires AWS env set —
crush only surfaces the bedrock provider when credentials resolve).

## Available Claude family (verified via ListFoundationModels, 2026-07-27)

haiku-4.5, sonnet-4.5/4.6/5, opus-4.1/4.5/4.6/4.7/4.8/5 (+ fable-5). All
INFERENCE_PROFILE type — hence the `us.` prefix requirement above.

## Cost caveats

- **Prompt caching is DISABLED on Bedrock** (charmbracelet-crush docs
  /advanced/amazon-bedrock) — repeated-context loops (judges, eval trials) pay full
  input-token price every call. Measure before committing to a crush-bedrock judge leg
  (ticket 35's shadow study owns that decision).
- Costs land on the configured account — keep it the personal dev account, not a
  project account.

## Relation to eval harness

- The harness's crush probe/judge legs default to `--model glm-5.2` (personal-env
  GLM); on corp, pass the bedrock model explicitly via `--model`.
- The no-vision image-* defs stay personal-env: Bedrock Claude HAS vision, so the
  no-vision premise doesn't hold on corp (ticket 30).
