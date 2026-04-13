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
