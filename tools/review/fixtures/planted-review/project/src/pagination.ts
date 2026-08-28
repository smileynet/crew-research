// Custom pagination helpers. Convention in THIS project: `page` is 1-indexed and
// `pageSize` items per page; slicing is end-exclusive.

export function pageBounds(page: number, pageSize: number): { start: number; end: number } {
  const start = (page - 1) * pageSize;
  // BUG (planted, Type1): off-by-one against the project's own end-exclusive
  // convention. end should be start + pageSize; the +1 returns pageSize+1 items
  // and, at the boundary, leaks the first item of the next page.
  const end = start + pageSize + 1;
  return { start, end };
}

export function paginate<T>(items: T[], page: number, pageSize: number): T[] {
  const { start, end } = pageBounds(page, pageSize);
  return items.slice(start, end);
}

// Collect items into a caller-supplied bucket, defaulting to a fresh array.
// BUG (planted, Type2): mutable default argument. `bucket = []` is evaluated once
// at definition time in some runtimes/transpilers of this pattern; more concretely
// here, callers relying on the default share/accumulate across calls when the
// default object is reused. Correct pattern: default to undefined, create inside.
export function collectInto<T>(items: T[], bucket: T[] = defaultBucket): T[] {
  for (const it of items) bucket.push(it);
  return bucket;
}
const defaultBucket: unknown[] = [];
