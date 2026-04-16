# Desktop QoL Additions

This file records likely future `lx*` additions that would make the config feel
more like a compact full desktop environment without drifting into a large,
general-purpose settings shell.

The goal is not to clone KDE or GNOME feature-for-feature. The goal is to add
small, high-value modules that fit the existing style:

- compact wibar widget
- popup for real interaction
- keyboard mode only where it clearly helps
- integrated replacements for tray applets where that improves daily use

## Session Handoff

This file is intended to be sufficient handoff context for a fresh Codex
session.

If starting from scratch, read this file first, then inspect the relevant code
paths directly in the repo.

Current repository direction:

- `SPEC.md` is the canonical forward-looking task/design document.
- Historical implementation notes should not be preserved separately once the
  durable decision has been merged here.
- Prefer updating this file over carrying design state in chat history.

## Open Tasks

Open work is grouped by module/area. Within each group, items are ordered by:

1. lower complexity first
2. then higher value first

Value priority is:

1. Stability
2. QoL
3. Usability for others than me
4. Polish

### `lxnetwork`

- Replace the plain `[WiFi N]` suffix with a small styled tag/badge once the
  popup visuals are stable.
  Value: Polish, QoL
  Complexity: low

### `lxnotify`

- Harden browser and web-app notification action invocation further; that path
  is still more brittle than simple dismiss behavior.
  Value: Stability
  Complexity: medium

### `lxbar` / `lxcommon`

- Make systray embedding into `lxbar` configurable instead of fixed.
  Value: QoL, Usability for others than me
  Complexity: low-medium
- Extract the neutral UI pieces still living in `lxaudio.popup_common` into
  `lxcommon`:
  - selectable popup rows
  - compact popup section/meta rows
  - shared popup spacing/margin wrappers
  - shared button-feedback wiring
  Value: Stability, Usability for others than me
  Complexity: medium
- Extract the repeated popup controller helpers into `lxcommon`:
  - popup key normalization/matching
  - pointer geometry helpers
  - outside-click dismissal plumbing
  - hover-close timer plumbing
  - shared popup keygrabber lifecycle
  Value: Stability, Usability for others than me
  Complexity: medium
- Move compact detail behavior, popup-open highlight behavior, and
  click-to-set geometry out of per-module ad-hoc logic and into a shared
  `lxbar` / `lxcommon` layer.
  Value: Stability, QoL, Polish
  Complexity: medium
- Keep keyboard contracts centralized across popups where possible rather than
  redefining semantics independently in each popup keygrabber.
  Value: Stability, Usability for others than me
  Complexity: medium
- Keep popup cycling strictly derived from `lxbar` widget order rather than
  adding a separate popup ordering surface.
  Current contract:
  - cycle order follows final top-level widget order
  - widgets can opt out of cycling while remaining visible and directly
    addressable
  - semantic popup roles are `primary`, `secondary`, `tertiary`
  - modules with multiple popups should cycle in semantic-role order at that
    widget's single bar position
  - non-popup widget actions should not participate in cycling
  Value: Stability, QoL
  Complexity: medium

### Config Surface

- Introduce one central declarative config surface:
  - `config/defaults.lua`
  - top-level `config.lua` next to `rc.lua`
  - one shared loader that deep-merges and normalizes them
  Value: Usability for others than me, Stability
  Complexity: medium
- Current implementation status:
  - top-level `config.lua` is now the intended user config entrypoint
  - `rc.lua` loads the app module tree via `require("config.init")`, leaving
    `./config.lua` free for user config data
  - centralized sections already routed through the shared loader:
    - `settings` (modifiers, monitor metadata, volume step)
    - `theme` selection
    - `theme` value overrides
    - `screens` including shared tag order and per-screen tag layouts
    - `widgets`
    - `commands`
    - `lxmodules`
    - key override data
    - rules override data
  - runtime no longer needs split `config.override.*` files for the centralized
    sections above
- Gradually move remaining user-facing values into that central config surface:
  - fonts, colors, icons, spacing
  - popup widths/timing
  - module options beyond widget enable/cycle/order
  Value: Usability for others than me
  Complexity: medium-high
- Current module-option progress:
  - `lxmodules.lxbar` now owns bar-level composition such as widget order and
    bar participation flags
  - `lxmodules.<module>` now owns per-module constructor/runtime options
  - currently centralized there:
    - `lxmodules.lxaudio` options such as `refresh_interval`, `width`,
      `step`, and OSD enablement
    - `lxmodules.lxdisplay` options such as `refresh_interval`, OSD settings,
      brightness backend wiring, and redshift settings
    - `lxmodules.lxbluetooth`, `lxmodules.lxnetwork`, and
      `lxmodules.lxpowerprofiles` refresh intervals
    - `lxmodules.lxnotify` options such as denylist rules, truncation limits,
      time formatting, and visible popup item count
    - `lxmodules.lxrunner` options and aliases
  - remaining module-specific user-facing options can continue to grow under
    `lxmodules.<module>` unless a module later needs its own clearer top-level
    config surface
- Keybinding defaults should be surfaced in the central config, not only
  override data.
  Current direction:
  - one flat key map in `config.lua`
  - stable action IDs as keys
  - each action maps to a small declarative binding spec
  - actions with multiple invocations may map to a short array of binding specs
  - shape should stay readable and close to current defaults, e.g.:
    `action_id = { scope = "global", mods = { "Mod4" }, key = "p" }`
  - `keys.lua` keeps action definitions, validation, and compilation
  - user config chooses invocation, not backend semantics
- Expose external launch targets as `commands`, not `programs`.
  Current direction:
  - `commands.<name>` stores user-configurable external binaries or shell
    commands
  - plain strings are enough for the first pass
  - examples:
    - `commands.terminal = "alacritty"`
    - `commands.lock_screen = "i3lock"`
    - `commands.screenshot_region = "scrot -s"`
  - action implementations in Lua may invoke `commands.<name>`
  - internal Awesome / `lx*` behavior should stay out of `commands`
  - module-private backend wiring should stay with that module instead of
    being elevated into `commands`
  - examples:
    - `lxmodules.lxdisplay.brightness.*`
    - `lxmodules.lxdisplay.redshift.*`
  - `lxrunner` aliases should remain in their own alias section rather than be
    folded into generic command definitions
- Prefer a grouped top-level config surface rather than one giant nested tree,
  but keep the keybinding map itself flat within its section.
- Fully expose in the central config:
  - commands
  - tag names/order plus per-screen tag layouts
  - enabled `lx*` modules
  - `lxbar` order
  - per-module popup-cycle participation
- Keep lighter exposure for:
  - theme overrides
    - one or two example lines plus comment should be enough
  - rules
    - default should be effectively empty, with one example/docstring
  - screen layouts
    - default single-screen assumption plus a simple two-screen example
- For bar/module configuration, prefer a split structure that keeps composition
  concerns separate from per-module behavior:
  - `lxmodules.lxbar.order = { "network", "audio", ... }`
  - `lxmodules.lxbar.modules.<name> = { enabled = true/false, cycle = true/false }`
  - `lxmodules.<module> = { ...module-specific behavior... }`
  This keeps ordering declarative without making layered overrides brittle, and
  avoids mixing `lxbar` concerns with module runtime settings.
- `lxrunner` aliases should stay outside generic external `commands` and live
  under `lxmodules.lxrunner` instead.
- Keep scattered `config.override.*` files, if any remain, as migration/examples
  only rather than as active runtime config inputs.
  Value: Usability for others than me
  Complexity: low

### Current Config Direction

The current effective direction is:

- `config/defaults.lua`
  default user-facing values for centralized config sections
- top-level `config.lua`
  user-facing overrides for centralized sections
- `config/config_data.lua`
  shared loader/merge layer for centralized config data
- `config/init.lua`
  app module aggregator for internal runtime wiring
- legacy split `config.override.*`
  should be treated as historical migration/examples only, not as an active
  runtime config path

Centralized sections should prefer this merge order:

1. defaults from `config/defaults.lua`
2. top-level `config.lua`

For fresh migrations and future work, prefer adding to `config.lua`, not to new
split `config/override/*.lua` files.

### `lxrunner`

- Add per-alias icons so high-signal aliases such as reboot, update, shutdown,
  and VPN-related actions can be identified more quickly.
  Value: QoL, Polish
  Complexity: low-medium

### Top-Level Widget Polish

- Run a dedicated polish pass for compact/top-level widgets:
  - spacing consistency
  - alignment consistency
  - small layout cleanup across modules
  Value: Polish, QoL
  Complexity: low-medium
- Explore a debug / no-glyph mode that sits between plain ASCII fallback and a
  full debug mode.
  Current intent:
  - help when icon fonts/glyphs render badly
  - optionally expose clearer text/state cues during polish/debugging
  Current direction:
  - global mode
  - top-level widgets only in the first pass
  - ultra-terse replacements such as `[B]`, `[W]`, `[Pl]`
  - useful both as a polish/debug aid now and as a future fallback mode later
  Value: Stability, Usability for others than me
  Complexity: medium

### `lxdisplay`

- Add a runtime display-management layer on top of current `lxdisplay`
  behavior, focused on common output-activation workflows rather than a full
  display settings center.
  Initial target use cases:
  - notebook: plug in a meeting-room monitor/projector and quickly enable it
    as mirror or extended desktop
  - desktop: temporarily disable all but the main screen for gaming
  - desktop: enable a usually-off drawing tablet / fourth screen with a known
    predetermined layout
  Suggested scope for a first pass:
  - one popup with:
    - per-output cards for newly available / connected outputs
    - a small global preset section
  - detect newly available outputs
  - enable outputs at runtime
  - support per-output actions:
    - `mirror`
    - `extend l`
    - `extend r`
  - support a few predefined global layout presets / profiles:
    - `gaming`
    - `default`
    - `drawing`
  - keep output / `xrandr` orchestration config separate from Awesome screen
    role config:
    - `screens` should stay focused on Awesome-side roles, DPI, tag order, and
      per-screen tag layouts
    - a future `lxdisplay` config surface should own connector/output mapping,
      `xrandr` actions, and named output profiles/presets
  - no fully manual arrangement UI in the first pass
  - X11 / `xrandr` only for now
  Value: QoL
  Complexity: medium-high

### Repo Hygiene

- Add a proper `LICENSE`.
  Value: Usability for others than me
  Complexity: low
- Rewrite / expand `README.md` for open-source onboarding:
  - what this project is
  - what makes it different from a generic Awesome config
  - where users should start customizing
  - what the main architecture pieces are
  Value: Usability for others than me
  Complexity: low
- Add `CONTRIBUTING.md`.
  Cover at least:
  - expected contribution style
  - how to propose changes
  - how to report issues
  - what kinds of changes should stay user-facing/config-focused vs internal
  Value: Usability for others than me
  Complexity: low
- Clarify project scope and maintenance boundaries in the public docs:
  - what the project intends to support
  - what it intentionally does not try to solve
  - which classes of bugs/issues are in scope
  - which ones are likely to be declined or treated as environment-specific
  - make the support stance explicit and blunt:
    - best-effort issue triage only
    - no guaranteed fixes
    - no liability for system breakage
  Value: Usability for others than me
  Complexity: low-medium
- Decide and document the ownership model for included `lx*` modules:
  - explicit current stance: keep modules in-tree for now
  - reconsider submodules later only if versioning pressure grows enough to
    justify the user/contributor friction
  - document the tradeoffs and intended contributor workflow
  Value: Usability for others than me
  Complexity: medium
- Add a lightweight issue-triage / support policy so adopters know what to
  expect.
  Examples:
  - supported environments vs "best effort"
  - font/glyph/rendering issues
  - machine-specific external command failures
  - requests that require hardware or proprietary-driver testing
  Explicit stance to document:
  - hard support target is effectively the maintainer's own environment:
    AwesomeWM on X11 on vanilla Arch, with PipeWire, playerctl,
    NetworkManager, and NVIDIA in the mix where applicable
  - support means best-effort issue triage only
  - no guaranteed fixes
  - no liability for system breakage
  - features or fixes outside that footprint are accepted only if they fit the
    design direction and can realistically be tested
  Value: Usability for others than me
  Complexity: medium
- Review whether any other root-level meta files are needed for open sourcing,
  such as:
  - `CODE_OF_CONDUCT.md`
  - a clearer issue template set
  - screenshots/demo assets for the README
  - installation/bootstrap notes
  Value: Usability for others than me, Polish
  Complexity: medium

### New Modules

- `lxcloud`
  Potential long-term candidate as a replacement for sync tray applets such as
  Nextcloud, with possible extension to other backends like Seafile later.
  Potential scope:
  - recent conflicts or errors
  - sync state / account status
  - pause/resume sync
  - quick open of synced folders
  First backend: Nextcloud only.
  Current priority order:
  1. errors/conflicts
  2. status visibility
  3. pause/resume
  Scope still needs later debate on whether it replaces the tray app entirely
  or remains a focused status/actions layer.
  Value: QoL
  Complexity: high

## Explicit Non-Priorities

These ideas were considered and rejected or deferred for now.

### `lxscreenshot`

Existing screenshot tooling is already sufficient.

### `lxclipboard`

Not useful for the current workflow.

### `lxmount`

Debatable, but not currently justified.

Rationale:

- USB media is rarely inserted without immediately doing file-manager work.
- Thunar already covers the relevant interaction well enough.
- Existing "safe to unplug" notifications are sufficient.

This can be revisited later, but it is not a priority now.

## Product Direction

For future `lx*` modules, prefer:

- replacements for tray applets or fragmented workflows
- modules with a clear daily-use interaction loop
- modules that benefit from consistent popup behavior and theming

Avoid:

- large settings-center style modules
- low-value informational widgets
- features that duplicate existing tools without improving the workflow

## Context Notes

These notes are intentionally non-task history-free context that helps explain
why the open items above exist.

### Shared UI Boundary

- `lxcommon` and `lxbar` already exist and are the correct long-term home for
  shared popup/widget mechanics.
- Active modules currently register compact widgets and popup handles there.
- The remaining work is mostly extraction and cleanup of duplicated logic, not
  first introduction of that architecture.
- Popup routing now uses semantic popup roles (`primary`, `secondary`,
  `tertiary`) rather than button-specific naming in the shared layer.
- `lxbar` popup cycling now follows final widget order and filters by per-widget
  cycle participation rather than maintaining a separate popup order surface.

### What Should Still Stay Module-Local

- popup content builders and row semantics
- module state refresh logic
- backend-specific command/data probing
- theme interpretation where semantics differ by module

### `lxrunner`

- `lxrunner` history now stores canonical launched labels rather than typed
  prefixes; any later history redesign should preserve that behavior.
- `lxrunner` aliases remain distinct from generic external `commands`.
- Central config direction for aliases:
  - `config.lua.lxmodules.lxrunner.aliases`
  - do not fold aliases into `commands`
  - split override files are historical migration inputs only

