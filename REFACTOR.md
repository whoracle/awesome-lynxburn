# Refactor Follow-Ups

This file tracks cleanup items that are not worth interrupting current SPEC
work for, but should be revisited in the final refactor pass.

## Open Items

- `config/programs.lua`
  Current role: compatibility wrapper that adds terminal resolution on top of
  central command data loaded through `config.config_data`.
  Later option: fold the pure command data path fully into the central config
  layer and keep only a thinner runtime adapter if it still earns its keep.

- `config/settings.lua`
  Current role: compatibility surface over central settings/widget/theme data,
  plus runtime-derived values like `home` and `editor`.
  Later option: reduce it to a very thin runtime adapter or retire it once
  direct consumers can read the central config surfaces they actually need.

- `config/override/` compatibility examples and docs
  Current role: historical scaffolding now that top-level `./config.lua` is the
  intended user config entrypoint and runtime no longer reads split override
  files.
  Later option: remove or rewrite the directory once the example/documentation
  story is settled.
