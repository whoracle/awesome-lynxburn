# lynxburn Remaining Work

`lynxburn` is the active bundled theme and no longer a placeholder.

This file tracks what is still wanted from the theme layer.

## Still Wanted

- split the theme later into structural values and color-scheme values
  Why: the current single-file theme is workable, but palette swapping will be
  cleaner once colors and non-color theme settings are separated

- keep moving repo-specific behavior out of `themes/lynxburn/widgets.lua` and
  into dedicated modules where that produces a cleaner ownership boundary
  Why: the theme should own appearance and final composition, not accumulate
  unrelated business logic

- prune unused inherited theme assets once the remaining old widget usage is
  reduced or removed
  Why: the theme tree still contains older bundled assets that should not live
  forever if they no longer serve the current config

## Explicit Non-Goals For Now

- no theme refactor as part of documentation-only maintenance work
  Why: documentation updates should track the current code shape, not quietly
  change it

- no multi-theme framework yet
  Why: there is one active bundled theme and broader feature work matters more

- no nesting of theme config under per-module config trees
  Why: theme overrides are intentionally kept under the top-level `theme` key in
  `config.lua`
