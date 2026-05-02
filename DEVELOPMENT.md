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
  depend on external widget/layout helper internals.
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
- `config.minimal.example.lua`
  Small practical starter config for new checkouts.
- `config.example.lua`
  Larger commented reference catalog for available local override knobs.
- module/theme `README.md` and `SPEC.md`
  Module-local usage and plans.
- `MIGRATE.md`
  Incremental migration notes between tagged releases.

## Glossary

These terms describe repository-local concepts. They are not generic AwesomeWM
terms unless explicitly noted.

- `lxmodule`
  One repo-owned feature module such as `lxmedia`, `lxnetwork`, `lxrunner`, or
  `lxsecrets`.
- `module id`
  Public config identifier for an `lxmodule`. In user config, prefer the full
  `lx*` form such as `lxmedia` or `lxnetwork`.
- `short module id`
  Internal shorthand without the `lx` prefix, such as `media` or `network`.
  Registry and service internals may use this form, but user-facing docs should
  prefer full `lx*` ids.
- `service`
  Long-lived singleton instance created by `config.services`. Services own
  module runtime state and are shared by keybindings, bar widgets, and popup
  routing.
- `widget registry`
  Shared registry populated by `config.services` and consumed by `lxbar` to
  build the top-level compact widget row in configured order.
- `semantic popup`
  Popup handle registered by module id, popup id, and role. This lets `lxbar`
  open “the primary popup for lxnetwork” without knowing module internals.
- `popup role`
  User-facing popup intent. Current common roles are `primary` and `secondary`.
- `popup session`
  Shared `lxcommon` popup shell that owns the visible popup window while a
  module owns only the popup contents and actions.
- `custom:<name>`
  Configured non-`lx*` bar widget entry, for example `custom:systray`.
- `theme shell`
  The structural theme layer in `themes/lynxburn` that owns wibar composition,
  spacing, sizing, wallpaper application, and non-color theme defaults.

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
2. `config.minimal.example.lua`
   Small starter override file for users.
3. `config.example.lua`
   Larger commented reference file for users.
4. top-level `config.lua`
   Local machine-specific overrides, loaded by `config/config_data.lua`.

The main config sections are:

- `commands`
- `keys`
- `layouts`
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
- `layouts`
  Third-party layout registration and optional layout setup hooks.
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

### Startup Flow Map

The startup path is intentionally split by ownership. The shortest useful
mental model is:

```text
rc.lua
  -> config.init
  -> config.config_data
       loads config.defaults
       merges local config.lua sections on demand
  -> config.theme.init(beautiful)
       loads themes/<name>/theme.lua
       applies color scheme and theme overrides
  -> config.services.bootstrap()
       creates long-lived lxmodule service instances
       registers top-level widgets
       registers semantic popups
  -> config.layouts / config.keys / config.mouse / config.rules / config.signals
  -> config.screens.setup()
  -> themes/lynxburn/widgets.lua
       builds per-screen wibars
       asks lxbar for the ordered compact widget row
  -> lxbar
       consumes the widget registry
       delegates popup opens/cycling to lxcommon.popup_manager
```

The most important rule is that `config.services` sits between raw modules and
the rest of the desktop. If a keybinding, bar entry, or popup cycle needs an
`lxmodule`, it should get the shared instance from `config.services` rather than
constructing a second instance.

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

### Add Or Change An Existing lxmodule

Use this checklist when touching an existing module or adding a small new one:

1. Decide the public id first and document it as a full `lx*` id.
2. Put user-facing defaults under `config/defaults.lua`.
3. Add richer optional examples to `config.example.lua`, not to defaults.
4. Create or update the module through `config.services`.
5. Register its top-level widget in `config.services.registry`.
6. Register semantic popups in `config.services` if the module has popups.
7. Keep popup content/actions inside the module; keep popup shell/input behavior
   in `lxcommon`.
8. Add dependency checks to `config/preflight.lua` if missing binaries would
   produce confusing runtime behavior.
9. Update the module `README.md` for user-facing behavior and config knobs.
10. Update the module `SPEC.md` or `ROADMAP.md` only for future work, not for
    already-completed implementation detail.

Do not put module behavior in `themes/lynxburn/widgets.lua` just because the
module appears in the bar. The theme may place widgets, but the module should
own its behavior.

## Popup Lifecycle

Most `lx*` popup behavior goes through shared `lxcommon` infrastructure. The
point is to keep module popups visually and interactively consistent without
making every module implement its own keygrabber and shell lifecycle.

The normal path is:

```text
config.services
  registers module widget
  registers semantic popup
    -> lxcommon.popup_manager
       stores popup handles and cycle order
    -> lxbar
       opens primary/secondary popups or cycles to the next handle
    -> lxcommon.popup_controller
       asks the module for popup content and action handlers
    -> lxcommon.popup_session
       owns the shared awful.popup shell
    -> lxcommon.popup_control / popup_input_session
       owns keyboard input, outside-click close, and popup-specific actions
```

File responsibilities:

- `lxcommon.popup_manager`
  Registry of popup handles and popup cycling order.
- `lxcommon.popup_controller`
  Mixin for module methods such as `toggle_popup`, `close_popup`, selection
  movement, and descriptor-based popup opens.
- `lxcommon.popup_session`
  Shared popup window shell. Modules provide contents; this owns the actual
  visible popup instance.
- `lxcommon.popup_control`
  Key handling and global-key fallback logic for active popups.
- `lxcommon.popup_input_session`
  Lower-level active input session state for popup keyboard/mouse handling.
- `lxcommon.popup_ui`
  Reusable rows, cards, click targets, and popup visual primitives.

When changing popup behavior, first identify whether the change is about module
content, popup routing, shell lifecycle, input handling, or reusable UI. Editing
the wrong layer is the fastest way to reintroduce flicker, stale highlight
state, or inconsistent keyboard behavior.

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
