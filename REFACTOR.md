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

- `config.override.settings.lua` and `config.override.programs.lua`
  Current role: backward-compatible local override paths during the central
  config migration.
  Later option: remove them once `./config.lua` fully replaces the split
  override flow for centralized sections.

- `config.override.keys.lua`
  Current role: backward-compatible key override path now that top-level
  `config.lua.keys` exists.
  Later option: remove it once the live key overrides have been migrated.

- `config.override.lxrunner_aliases.lua`
  Current role: backward-compatible alias override path now that top-level
  `config.lua.runner.aliases` exists.
  Later option: remove it once the live alias overrides have been migrated.

- `config.override.theme.lua` versus central theme selection
  Current role: `config.theme` / central config owns top-level theme selection,
  while `config.override.theme.lua` still owns runtime theme value overrides.
  Later option: decide whether the final user-facing config keeps those as two
  layers or exposes a clearer unified theme config model.

- `config.override.config.lua`
  Current role: legacy compatibility path for early central-config work.
  Later option: remove it in favor of `./config.lua`, which is now the intended
  central user config entrypoint.

- `config.override.rules.lua`
  Current role: still-active compatibility path because rules do not yet have a
  final top-level `config.lua` shape.
  Later option: choose a central rules surface, migrate the live rule override,
  and then remove the compatibility loader.
