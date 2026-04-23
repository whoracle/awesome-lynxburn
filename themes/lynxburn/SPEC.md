# lynxburn Spec

Planned work lives in [`../../ROADMAP.md`](../../ROADMAP.md).

## Scope

- `lynxburn` is the active bundled theme
- the theme owns colors, sizing, spacing, and other appearance-level knobs
- repo-specific business logic should not accumulate in theme code unless the
  behavior is genuinely presentation-specific

## Explicit Non-Goals For Now

- no theme refactor as part of documentation-only maintenance work
  Why: documentation updates should track the current code shape, not quietly
  change it

- no multi-theme framework yet
  Why: there is one active bundled theme and broader feature work matters more

- no nesting of theme config under per-module config trees
  Why: theme overrides are intentionally kept under the top-level `theme` key in
  `config.lua`
