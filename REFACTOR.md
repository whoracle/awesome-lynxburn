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
  Current role: mixed compatibility surface that still exposes `settings.widgets`
  from the new central loader while other settings remain locally defined here.
  Later option: reduce it to non-centralized runtime settings or fold more of
  it into the central config loader once additional sections migrate.

- `config.override.settings.lua` and `config.override.programs.lua`
  Current role: backward-compatible local override paths during the central
  config migration.
  Later option: collapse overlapping user-facing override data into one clearer
  central override surface once enough sections have migrated.

- `config.override.theme.lua` versus central theme selection
  Current role: `config.theme` / central config owns top-level theme selection,
  while `config.override.theme.lua` still owns runtime theme value overrides.
  Later option: decide whether the final user-facing config keeps those as two
  layers or exposes a clearer unified theme config model.
