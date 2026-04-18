# Refactor Follow-Ups

This file tracks cleanup items that are not worth interrupting current SPEC
work for, but should be revisited in the final refactor pass.

## Open Items

- `config/override/` compatibility examples and docs
  Current role: historical scaffolding now that top-level `./config.lua` is the
  intended user config entrypoint and runtime no longer reads split override
  files.
  Later option: remove or rewrite the directory once the example/documentation
  story is settled.
- `themes/lynxburn2/theme.lua` structure vs palette split
  Current role: one authoritative flat theme file with both visual structure
  defaults and concrete colors.
  Later option: split non-color theme wiring/config from the color palette so
  multiple color schemes can reuse the same sizing, icon, and module-theme
  structure.
