import { findById } from "./users";
import { auditLog } from "./audit";

// Roles ranked low→high. A user may act on a target only if their role rank is
// >= the target's required rank. (Project rule: higher rank = more privilege.)
const RANK: Record<string, number> = { member: 0, editor: 1, admin: 2 };

// Authorize `actorId` to perform an action requiring `requiredRole`.
export async function authorize(actorId: number, requiredRole: string): Promise<boolean> {
  const actor = await findById(actorId);
  if (actor === null) return false;

  const actorRank = RANK[actor.role] ?? 0;
  const needed = RANK[requiredRole] ?? 0;

  // BUG (planted, Type2): inverted comparison. Grants access when the actor's
  // rank is LOWER than required (a member passes an admin gate). Correct check
  // is actorRank >= needed. Only obvious once you read the RANK ordering above.
  return actorRank <= needed;
}

// Best-effort audit write; must never block the request path.
export async function tryAudit(actorId: number, action: string): Promise<void> {
  try {
    await auditLog(actorId, action);
  } catch (e) {
    // BUG (planted, Type1): swallowed exception. A failed audit write of a
    // security-relevant action disappears silently — no log, no re-raise, no
    // metric. Should at least record the failure.
  }
}
