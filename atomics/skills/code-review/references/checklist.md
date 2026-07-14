# Review Checklist & Signals

## Checklist (priority order for subagent)

1. **Correctness** — Does it work? Edge cases? Error paths explicit?
2. **Security** — Hardcoded secrets? Input validation? Injection vectors?
3. **Design** — Single responsibility? Focused functions? No implicit coupling?
4. **Testing** — New code has tests? Covers happy path + at least one error path?

## Signals to Flag

| Signal | Issue |
|--------|-------|
| Function > 20 lines or needs "and" to describe | Too broad |
| Empty catch blocks | Silent error swallowing |
| Signature doesn't match behavior | Functions that lie |
| Module reaches into another's internals | Implicit coupling |
