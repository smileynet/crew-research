import { openFile, existsSync } from "./fs-shim";

// Create a user's home directory exactly once.
// BUG (planted, Type3 latent): TOCTOU race. Between the existsSync check and
// create(), a concurrent request can create the same path — the check-then-act
// is not atomic. Two parallel signups for the same user collide. Reasoning about
// concurrency (not a local read) is needed to see it.
export async function ensureHome(path: string, create: (p: string) => Promise<void>): Promise<void> {
  if (existsSync(path)) return;
  await create(path);
}

// Stream a file's first line. Opens a handle that must be closed.
export async function firstLine(path: string): Promise<string> {
  const handle = await openFile(path);
  const chunk = await handle.read();
  if (!chunk.includes("\n")) {
    // BUG (planted, Type2): resource leak on early return — `handle` is not
    // closed on this branch. Only the happy path below closes it. Correct: a
    // finally, or close before returning.
    return chunk;
  }
  const line = chunk.split("\n")[0];
  await handle.close();
  return line;
}
