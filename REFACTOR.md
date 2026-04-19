# Refactor Follow-Ups

This file tracks cleanup that is still desirable, but not urgent enough to
interrupt current feature work.

## Open Items

- split `themes/lynxburn/theme.lua` into structure/config and palette
  later
  Why: makes multiple color schemes easier without duplicating module defaults

- revisit `config/override/` as examples/docs only
  Why: runtime no longer uses it, but the directory may still deserve cleanup or
  replacement once the documentation story is final

- scan defaults/example/local config for unused definitions and remove them
  later
  Why: several config fields no longer have runtime consumers, for example
  `conky`, and should be cleaned out during the final refactor pass

- remove needless helper locals such as `imageviewer` / `imageeditor` wiring in
  config defaults where literal values are enough
  Why: some of that scaffolding is now just leftover indirection rather than
  useful structure
