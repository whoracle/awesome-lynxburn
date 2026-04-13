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

## Current Recommendation

Priority order:

1. `lxbluetooth`
2. `lxnetwork`

## Chosen Scope

### `lxbluetooth`

This is the strongest next candidate.

Rationale:

- On the notebook, Bluetooth devices are reused often.
- Typical use is not ad-hoc pairing of random devices, but reconnecting a small
  stable set of known devices:
  - sound bar
  - one of two headphones
  - keyboard as a rarer fourth device
- This is a repeated enough workflow that a compact integrated widget would
  likely beat `blueman-applet`.

Expected feature set:

- compact status widget in the bar
- popup showing:
  - controller power state
  - known paired devices
  - connected/disconnected state
  - battery level where available
  - quick connect/disconnect
  - quick power toggle
- optional advanced action to open an external manager if needed

Design notes:

- Optimize for reconnecting known devices, not for one-off pairing flows.
- Pairing support is still useful, but should not dominate the UI.
- Keyboard mode is worth considering here because device navigation and connect
  toggling are discrete actions.

### `lxnetwork`

This remains a good candidate, but second priority.

Rationale:

- On the notebook, network switching is not part of the daily workflow.
- VPN toggling is used daily, but that is already covered well enough via an
  `lxrunner` alias.
- When roaming between networks does happen, it happens in more intensive
  bursts such as train travel, so a better integrated popup would still be
  useful.

Expected feature set:

- compact status widget in the bar
- popup showing:
  - current connection
  - wired/wifi state
  - VPN state
  - known visible wifi networks
  - connect/disconnect actions
  - quick VPN toggle(s)
- advanced action to open `nm-connection-editor` or equivalent

Design notes:

- The main value is replacing `nm-applet` for common tasks, not exposing every
  NetworkManager feature.
- The popup should optimize for status + quick switching.
- VPN affordances matter more than full connection editing.

## Explicit Non-Priorities

These ideas were considered and rejected or deferred for now.

### `lxpowerprofiles`

Not useful enough for this setup on its own.

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

### `lxpowerprofiles`

This is a plausible later module, especially for notebook use, but should be
designed as a strongly opinionated profile switcher rather than a generic power
management cockpit.

#### Product shape

- top-level widget should expose only the two modes that make sense for the
  current power source
- the third mode remains available in the popup as an explicit override

Expected compact-widget behavior:

- on battery:
  - toggle between `powersave` and `balanced`
  - `performance` is popup-only
- on AC:
  - toggle between `balanced` and `performance`
  - `powersave` is popup-only

Rationale:

- on AC, `powersave` is rarely useful beyond unusual fan-noise or thermal cases
- on battery, `performance` is rarely useful outside short exceptional bursts
- a three-way top-level cycle would add complexity to the fast path without
  matching real usage

#### UX direction

Compact widget:

- show current power source
- show current profile
- left click toggles between the context-appropriate pair
- popup exposes all three profiles explicitly

Popup:

- show current power source
- show current active profile
- allow direct selection of:
  - `powersave`
  - `balanced`
  - `performance`

#### State policy

Preferred behavior:

- remember the normal profile choice per power source
- when switching to battery, restore the remembered battery-side choice
- when switching to AC, restore the remembered AC-side choice
- treat the third, popup-only profile as an exceptional override rather than the
  normal compact-toggle state

In practice:

- battery remembers `powersave` vs `balanced`
- AC remembers `balanced` vs `performance`
- unusual choices such as battery `performance` or AC `powersave` should be
  considered overrides, not the common fast-path default

#### Technical direction

Do not architect this primarily around `cpupower`.

Prefer a policy-driven design with layered backends:

- `powerprofilesctl` as the top-level profile interface where available
- CPU governor / EPP tuning underneath when useful
- discrete GPU state as an important notebook-specific concern
- optional custom hooks for machine-specific commands

The module should optimize for practical runtime and predictable behavior, not
for exposing every low-level power knob in the UI.

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
