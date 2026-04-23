# Development Notes

This file documents how the current repo is structured and how to extend or
modify existing behavior without having to reverse-engineer the codebase from
scratch.

It is intentionally focused on the current extension points. It does not try to
document a general framework for adding entirely new `lx*` modules.

## Purpose

Use this file when you want to:

- understand where a behavior lives
- change the current config surface without fighting the layering
- add or change keybinding actions
- modify an existing `lx*` module
- understand how theme overrides and service bootstrap fit together

Use the top-level `README.md` for user-facing setup and configuration. Use the
module/theme READMEs for module-local runtime behavior and exposed knobs.

## Repo Shape

High-level ownership:

- `rc.lua`
  Main Awesome entrypoint. Keeps the startup flow thin and delegates to
  `config/*`.
- `config/`
  Central maintainable config/bootstrap layer.
- `lxcommon/`
  Shared helpers for popup control, placement, widget feedback, registry, and
  OSD behavior.
- `lxcommon/dkjson.lua`
  Vendored JSON helper used by repo-owned modules so JSON support does not
  depend on `lain` internals.
- `lxbar/`
  Shared compact-widget bar integration and popup cycling.
- `lx*/`
  Existing feature modules such as media, notifications, network, power,
  display, Bluetooth, and the launcher.
- `themes/lynxburn/`
  Active bundled theme and wibar composition.

Top-level docs split:

- `README.md`
  User-facing setup/config overview.
- `DEVELOPMENT.md`
  This file.
- `SPEC.md`
  Top-level scope and non-goals.
- `ROADMAP.md`
  Current implementation backlog and priority order.
- `CHANGELOG.md`
  Repository change history generated from commit metadata.
- module/theme `README.md` and `SPEC.md`
  Module-local usage and plans.
- `MIGRATE.md`
  Temporary machine migration notes for old checkouts still anchored on the
  `migrate` tag.

## Tooling

Repository scaffolding now includes:

- `.editorconfig`
  Shared whitespace and newline rules.
- `.pre-commit-config.yaml`
  File-hygiene hooks, staged Lua syntax checks, and commit-message validation.
- `.cz.yaml`
  Commitizen config for commit prompts, changelog generation, and version bump
  rules.

Typical setup:

1. install `pre-commit` and `commitizen`
2. run `pre-commit install`
3. use `cz commit` if you want an interactive commit flow

The enforced commit format is:

`<type>: [<component>] <message>`

Exception:

`bump: <message>`

Current allowed types:

- `feature`
- `bugfix`
- `refactor`
- `docs`
- `chore`
- `break`
- `bump`

Current allowed components:

- `core`
- `theme`
- `lxbar`
- `lxbluetooth`
- `lxcommon`
- `lxdisplay`
- `lxmedia`
- `lxnetwork`
- `lxnotify`
- `lxpower`
- `lxrunner`
- `lxsecrets`

Version/changelog rules currently are:

- `break` -> major bump
- `feature` -> minor bump
- `bugfix` -> patch bump
- `bump` -> patch bump
- `refactor`, `docs`, `chore` -> no version bump

## Config Flow

The user-facing config entrypoint is top-level `config.lua`.

The layering is:

1. `config/defaults.lua`
   Base defaults tracked in git.
2. `config.example.lua`
   Example override file for users.
3. top-level `config.lua`
   Local machine-specific overrides, loaded by `config/config_data.lua`.

The main config sections are:

- `commands`
- `keys`
- `lxmodules`
- `rules`
- `screens`
- `settings`
- `theme`

General ownership rules:

- `commands`
  External commands and backend choices.
- `keys`
  User-facing keybinding overrides.
- `lxmodules.lxbar`
  Bar order, popup side, and cycle participation.
- `lxmodules.<module>`
  Existing module behavior and backend config.
- `screens`
  Monitor mapping, tag order, and per-tag layouts.
- `theme`
  Appearance overrides only.

If a change belongs in user config, prefer keeping it in the existing top-level
config surface instead of hardcoding it in module code.

## Startup And Bootstrap

The current startup order in `rc.lua` is:

1. load `config.init`
2. install error handling
3. load the active theme through `config.theme.init(beautiful)`
4. bootstrap long-lived services through `config.services.bootstrap()`
5. build OSD helpers, layouts, keymaps, mouse bindings, rules, signals, and
   screen setup
6. run `autostart_once` and plain `autostart`

Important consequence:

- theme-driven widgets should be created only after `beautiful` is initialized
- shared singleton modules should go through `config.services`, not ad-hoc
  `require(...).new(...)` calls in random places

Relevant files:

- `config/init.lua`
- `config/services.lua`
- `config/services/registry.lua`
- `config/services/state.lua`
- `config/services/popup_cycle.lua`

## Existing Module Work

For existing modules, keep ownership boundaries clear:

- shared helper logic belongs in `lxcommon` if more than one module needs it
- bar integration belongs in `config.services` plus `lxcommon.registry`
- popup registration belongs in `config.services`
- module-local state, popup rendering, controller logic, and theme lookup stay
  inside the module

Avoid re-growing giant `init.lua` files. The current preferred shape is:

- `init.lua`
  thin constructor/entrypoint
- helper/state/controller/popup/theme files
  split by responsibility

If you meaningfully reshape a module, update that module’s `README.md` and
`SPEC.md` as part of the same work cycle.

## Keybinding Workflow

This is the main intentionally documented code-level extension point.

Current ownership:

- `config/default_keys.lua`
  Default binding definitions and ordering.
- `config/keys.lua`
  Thin orchestration layer that builds the final global/client keymaps.
- `config/keys/bindings.lua`
  Binding normalization, ordering, collision checks, and `awful.key`
  compilation.
- `config/keys/actions.lua`
  Action implementations referenced by binding ids.
- `config/keys/tags.lua`
  Generated tag-related actions and bindings.

### Change an existing shortcut only

If the action already exists and you only want different keys:

- override it in top-level `config.lua` under `keys`
- keep the same action id
- do not edit `config/keys/actions.lua`

### Add a new binding for an existing action

If the action already exists but you want a new shortcut:

1. add a new binding entry under the relevant action in `config.lua`, or adjust
   `config/default_keys.lua` if it should become a tracked default
2. make sure `on_press` points at the existing action id
3. reload and test

### Add a brand-new action

If there is no existing action id for the behavior:

1. implement the action in `config/keys/actions.lua`
2. add a binding spec for it in `config/default_keys.lua` if it should be a
   tracked default, or in local `config.lua` if it should stay local
3. keep the action name and binding `on_press` string aligned
4. reload and test both the binding and any side effects

### Notes

- tag-number bindings are generated in `config/keys/tags.lua`
- popup-cycle fallback bindings are injected in `config/keys.lua` only when no
  conflicting binding already exists
- `lxmedia` popup key actions are derived from the final global binding specs,
  so media popup keyboard behavior depends on the resolved binding set

## Theme Flow

Current theme ownership:

- `config/theme.lua`
  Chooses the active theme and color scheme, then applies user overrides.
- `themes/lynxburn/theme.lua`
  Composes the structural theme layer with the selected color scheme and merges
  flat `theme = { ... }` overrides from `config.lua`.
- `themes/lynxburn/structure.lua`
  Owns non-color theme values such as spacing, sizing, placements, icon paths,
  and other layout-oriented knobs.
- `themes/lynxburn/colors/*.lua`
  Own color-scheme palette/fonts plus the color-bearing `beautiful.*` keys.
- `themes/lynxburn/widgets.lua`
  Builds the per-screen wibar composition used by the theme.

Rules of thumb:

- appearance changes belong under top-level `theme` overrides if they are
  user-facing knobs
- theme internals such as asset paths and composition stay in the theme
  directory
- do not move module behavior into the theme just because the module is shown
  there

## Conventions

- keep user-facing config in top-level `config.lua`
- keep appearance overrides under top-level `theme`
- keep module behavior under `lxmodules.<module>`
- keep bar composition under `lxmodules.lxbar`
- prefer `lxcommon` for logic shared across multiple modules
- prefer small focused helper files over giant entry files
- when split files are introduced, double-check their imports; refactors here
  have already produced missing-`require` regressions

## Testing And Debugging

The baseline workflow for code changes in this repo is:

1. run `luac -p` on the touched Lua files
2. reload Awesome
3. smoke-test the affected behavior manually

Things worth watching closely:

- async spawn callbacks after file splits
- timer lifecycle and cleanup
- keygrabber and mousegrabber teardown
- popup registration and popup cycling behavior
- stale helper references after moving functions between files

If a refactor moves logic between files, expect the most common regressions to
be:

- missing `require(...)` imports
- stale helper references
- methods still assuming old field names or old file-local state
