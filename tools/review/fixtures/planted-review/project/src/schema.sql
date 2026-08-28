-- Account and user schema.
CREATE TABLE users (
  id            INTEGER PRIMARY KEY,
  email         TEXT NOT NULL UNIQUE,
  role          TEXT NOT NULL DEFAULT 'member',
  display_name  TEXT NOT NULL
);

CREATE TABLE accounts (
  id     INTEGER PRIMARY KEY,
  -- quota is a byte count. Declared 32-bit INTEGER (max 2,147,483,647 ≈ 2 GiB).
  -- Cross-file coupling: setQuota() in src/users.ts writes byte counts that can
  -- exceed 2^31 (e.g. a 5 GiB plan), silently overflowing this column.
  quota  INTEGER NOT NULL DEFAULT 0
);
