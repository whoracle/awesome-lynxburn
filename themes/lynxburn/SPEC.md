# lynxburn Spec

Planned work lives in [`../../ROADMAP.md`](../../ROADMAP.md).

## Scope

- `lynxburn` is the active bundled theme
- the theme owns colors, sizing, spacing, and other appearance-level knobs
- color schemes may vary palette/fonts while the `lynxburn` theme shell keeps
  structural layout, spacing, and widget composition stable
- `widgets.lua` still owns the current wibar assembly and the remaining
  non-`lx*` theme widgets until they are intentionally replaced or extracted
- repo-specific business logic should not accumulate in theme code unless the
  behavior is genuinely presentation-specific

## Explicit Non-Goals For Now

- no theme refactor as part of documentation-only maintenance work
  Why: documentation updates should track the current code shape, not quietly
  change it

- no multi-theme framework yet
  Why: multiple color schemes inside `lynxburn` are fine, but broader theme
  packaging/framework work still matters less than module behavior

- no nesting of theme config under per-module config trees
  Why: theme overrides are intentionally kept under the top-level `theme` key in
  `config.lua`
