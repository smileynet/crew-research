# UI Prototype Reference

## When to Use

- "What should this page look like?"
- "I want to see a few options before committing."
- "Try a different layout for this screen."

## Sub-Shapes

### A: Adjustment to existing page (preferred)

Variants rendered on the same route, gated by `?variant=` URL param. Existing data fetching, auth, layout all stay — only the rendering swaps. Use this whenever there's a plausible existing page to host variants.

### B: New throwaway route (last resort)

Only when the thing being prototyped has no existing page to live inside. Name it obviously as a prototype. Same `?variant=` pattern.

## Floating Switcher Bar

Fixed-position bar at bottom-center:
- Left/right arrows cycle variants (wrap around)
- Shows current variant key + name (e.g. "B — Sidebar layout")
- Keyboard: ← → arrow keys also cycle (don't intercept when input focused)
- Visually distinct from page content
- Hidden in production builds (`NODE_ENV !== 'production'`)

## Variant Rules

- Variants must be **structurally different** (layout, hierarchy, affordance)
- Three slightly-tweaked card grids is NOT a prototype — it's wallpaper
- Each variant free to throw out the layout entirely
- Read-only by default; stub mutations if needed

## Cleanup

Winner identified → delete losers + switcher → fold winner into real code (rewrite properly, prototype had no tests/error handling).
