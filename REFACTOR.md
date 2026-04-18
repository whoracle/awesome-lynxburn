# Refactor Follow-Ups

This file tracks cleanup that is still desirable, but not urgent enough to
interrupt current feature work.

## Open Items

- split `themes/lynxburn2/theme.lua` into structure/config and palette
  later
  Why: makes multiple color schemes easier without duplicating module defaults

- revisit `config/override/` as examples/docs only
  Why: runtime no longer uses it, but the directory may still deserve cleanup or
  replacement once the documentation story is final
