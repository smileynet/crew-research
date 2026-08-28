import { authorize } from "../src/auth";
import { findByEmail } from "../src/users";

// Over-mocked: findById is stubbed to always return an admin, so authorize()'s
// inverted-comparison bug is masked — the test passes regardless of the real
// comparison. BUG (planted, Type3): the mock hides a real contract; the test
// gives false confidence. A reviewer must connect this to auth.ts to see it.
const fakeUsers = { findById: async () => ({ id: 1, email: "a@b.c", role: "admin", displayName: "A" }) };

export async function testAuthorizeAdmin() {
  // (pretend DI wires fakeUsers in) — asserts a member is blocked, but the mock
  // returns admin, so it never exercises the real member path.
  const ok = await authorize(1, "admin");
  assert(ok === true, "admin should pass admin gate");
}

export async function testFindByEmailShape() {
  // BUG (planted, Type1): test theater — asserts nothing meaningful. Always
  // passes even if findByEmail returns garbage or is injectable.
  await findByEmail("x@y.z");
  assert(true, "smoke");
}

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}
