# Tighten the Loop

A feedback loop is a product. Once you have ANY loop, tighten it until it's a debugging superpower.

## Speed (target: < 5 seconds)

- Cache setup — don't rebuild the world each run
- Skip unrelated init — focus on the code path that fails
- Narrow test scope — one assertion, not the full suite
- Inline the fixture — don't read from disk if you can hardcode the bad input

A 30-second loop is barely better than no loop. A 2-second loop is tight.

## Sharpness

- Assert on the SPECIFIC symptom, not "didn't crash"
- One bug per loop — separate interacting bugs into separate loops
- Output shows WHAT failed, not just THAT it failed
- The pass/fail criterion should be one line of output you can grep

## Determinism

- Pin time — freeze `Date.now()`, control clocks, use fake timers
- Seed RNG — same random sequence = same failure every time
- Isolate filesystem — temp dirs, clean state before each run
- Freeze network — mocks, recorded fixtures, no real HTTP
- Control concurrency — single-threaded where possible, or fixed thread count

## Non-Deterministic Bugs

Goal: raise reproduction rate until debuggable.

| Technique | When to use |
|-----------|------------|
| Loop 100× | First thing — statistics reveal what one run hides |
| Parallelise | Race conditions surface faster under contention |
| Add stress | Memory pressure, CPU saturation, disk I/O |
| Narrow timing windows | Add sleeps around suspected races |
| Amplify the flaw | If 10% flaky, add load until it's 50% flaky |

A 50%-flake is debuggable. A 1%-flake is not. Keep raising the rate.

### Still can't reproduce?

The bug is environment-dependent. Ask for:
1. Access to the reproducing environment
2. Captured artifact — HAR file, log dump, core dump, screen recording with timestamps
3. Permission to add temporary production instrumentation (structured logging, OpenTelemetry span)

Do NOT hypothesize without a loop. State what you tried and stop.
