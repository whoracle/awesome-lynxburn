# Refactor Follow-Ups

This file tracks cleanup items that are not worth interrupting current SPEC
work for, but should be revisited in the final refactor pass.

## Open Items

- `config/programs.lua`
  Current role: thin compatibility adapter over central command data loaded
  through `config.config_data`.
  Later option: retire it once direct consumers can read the central command
  surface without losing readability.

- `config/settings.lua`
  Current role: thin compatibility adapter over centralized static settings.
  Runtime-derived values such as `HOME`, `EDITOR`, and derived tag names now
  live in `config/runtime.lua`.
  Later option: retire it once direct consumers can read the central settings
  surface without losing readability.

- `config/override/` compatibility examples and docs
  Current role: historical scaffolding now that top-level `./config.lua` is the
  intended user config entrypoint and runtime no longer reads split override
  files.
  Later option: remove or rewrite the directory once the example/documentation
  story is settled.
