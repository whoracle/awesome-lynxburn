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

## Implemented

These modules were implemented and are no longer tracked here as future work:

- `lxbluetooth`
- `lxnetwork`
- `lxpowerprofiles`

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

## Later Candidates

These are valid future ideas, but not current priorities.

### `lxcloud`

Potential long-term candidate as a replacement for sync tray applets such as
Nextcloud, with possible extension to other backends like Seafile later.

Potential scope:

- sync state
- account status
- pause/resume sync
- recent conflicts or errors
- quick open of synced folders

Design note:

- if this is ever built, start with one real backend first, most likely
  Nextcloud
- only introduce a generalized backend abstraction after the useful state and
  actions are proven in practice

## Product Direction

For future `lx*` modules, prefer:

- replacements for tray applets or fragmented workflows
- modules with a clear daily-use interaction loop
- modules that benefit from consistent popup behavior and theming

Avoid:

- large settings-center style modules
- low-value informational widgets
- features that duplicate existing tools without improving the workflow

## Cleanup Notes

- Current MVP work reuses [lxaudio/popup_common.lua](/home/anthrax/tmp/awesome/lxaudio/popup_common.lua:1)
  from non-audio modules.
- That is acceptable for now to keep momentum, but it should not stay that way.
- Follow-up options:
  - duplicate the small shared popup helpers into each module if the overlap
    stays tiny
  - or extract them into a neutral `lxcommon` module if the shared surface keeps
    growing
- Preferred long-term direction: no direct inter-module dependency such as
  `lxnetwork -> lxaudio` or `lxbluetooth -> lxaudio` just for popup helpers.
- `lxnetwork` currently renders Wi-Fi generation hints as plain text suffixes
  such as `[WiFi 6]` when multiple meaningful variants of the same SSID are
  shown.
- Follow-up: replace that plain suffix with a small styled tag/badge once the
  network popup visuals are stabilized.
- Future `lxcommon` should also own popup coordination so only one `lx*` popup
  can be open at a time.
- Future `lxcommon` should also own a unified top-level widget/container for
  active `lx*` modules instead of each module being placed independently in the
  wibar.
- Rationale:
  - lets the user override module order in one place
  - uses screen real estate better on smaller displays
  - makes spacing/alignment behavior consistent across modules
  - avoids repeated per-module wrapping decisions in theme code
- Preferred shape:
  - each active module registers a compact widget handle during init
  - `lxcommon` composes those handles into one shared top-level widget
  - ordering should be user-overridable without editing each module
  - modules should still own their internal state and popup behavior; `lxcommon`
    only owns composition/order/layout
- Compact detail behavior such as volume/brightness bars should eventually be
  handled in that shared top-level widget layer as well.
- Preferred direction:
  - compact widgets default to the smallest useful persistent state
  - richer detail such as bars is revealed only when there is clear user intent
  - this should not be implemented as ad-hoc per-module hover hacks ahead of
    `lxcommon`
  - click-to-set behavior especially needs stable geometry and should be solved
    together with the unified top-level widget design
- Preferred shape:
  - each active module registers its popup handle(s) during init
  - each handle exposes at least a stable `close()` callback and ideally an
    `is_visible()` callback
  - popup-open paths notify the shared manager before showing
  - popup-close paths notify the shared manager when hidden
- This should cover both single-popup modules and modules with multiple named
  popups such as `lxaudio`.
- `config/keys.lua` should eventually stop calling popup methods on individual
  modules directly.
- Preferred direction: keys trigger `lxcommon` popup-manager actions, and the
  manager dispatches popup spawning/opening to the registered module popup
  handles.
- Optional later layer on top of that: an `lxpopup` controller that cycles
  through registered popups with one shared keybind.
- Proposed behavior:
  - if no popup is open, open the first eligible popup
  - repeated presses cycle forward through the registered popup order
  - optional reverse cycle via `Shift`
  - direct popup bindings can still remain for fast access
- This should only be explored after the shared popup manager exists; otherwise
  the interaction model will be too fragmented.

## Open Source Config UX

- For open sourcing, customization should become more discoverable than the
  current split between hardcoded defaults and multiple override files.
- Preferred direction:
  - introduce one central declarative defaults file, likely `config/defaults.lua`
  - introduce one obvious user-local override file, likely `config/user.lua`
  - keep both files table-only and readable, not code-heavy
  - load and deep-merge them through one shared config loader
- Goal:
  - common customization should not require understanding module internals
  - users should have one obvious place to start and one obvious place to
    override
  - advanced logic should remain in Lua modules, not in the user-facing config
- Good candidates for the central config surface:
  - theme selection
  - fonts, colors, icons, spacing
  - widget enable/disable flags
  - popup widths and timing
  - program paths/binaries
  - mod keys and workspace names
  - monitor metadata
  - keybinding data overrides
  - module options such as audio/display/powerprofile behavior
- Things that should remain in executable Lua rather than the declarative layer:
  - derived command construction
  - environment-sensitive fallback logic
  - callbacks, runtime behavior, and event handling
- Preferred migration path:
  - add the central config layer first
  - have existing modules consume the normalized merged config tree
  - keep scattered `config.override.*` compatibility only temporarily
  - later retire the old override pattern once the central config surface is
    complete
- YAML is not required for this goal; plain Lua tables are preferred because
  they stay dependency-free while still being readable and easy to merge.
