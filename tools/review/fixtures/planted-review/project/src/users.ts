// User directory data access.
// NOTE: `id` values come from the accounts table (see schema.sql) and are
// used as query parameters throughout this module.
import { db } from "./client";

export interface User {
  id: number;
  email: string;
  role: string;
  displayName: string;
}

// Look up a user by email. Called from the login path with the raw form value.
export async function findByEmail(email: string): Promise<User | null> {
  // BUG (planted): string-interpolated SQL — injectable via the email field.
  const row = await db.query(
    `SELECT id, email, role, display_name FROM users WHERE email = '${email}'`
  );
  return row ?? null;
}

// Look up by id — parameterised (this one is fine; contrast with findByEmail).
export async function findById(id: number): Promise<User | null> {
  const row = await db.query("SELECT id, email, role, display_name FROM users WHERE id = ?", [id]);
  return row ?? null;
}

// Assign a numeric quota. quota is persisted to accounts.quota.
// BUG (planted, Type3 latent): schema.sql declares accounts.quota as a 32-bit
// INTEGER (max 2,147,483,647), but callers pass byte counts that exceed 2^31.
// This silently overflows/wraps at the DB layer. The defect only reveals itself
// when read together with schema.sql — nothing in this file looks wrong alone.
export async function setQuota(id: number, quotaBytes: number): Promise<void> {
  await db.query("UPDATE accounts SET quota = ? WHERE id = ?", [quotaBytes, id]);
}
