# Roadmap

This file tracks planned work.

`SPEC.md` files describe scope and explicit non-goals. They should not be the
main backlog.

## Priority Order

Use this order for the next fresh session unless new bugs force a
reprioritization:

1. `lxsecrets` implementation
2. `lxbar` spacing/composition polish
3. `themes/lynxburn` split / asset pruning / further ownership cleanup
4. `lxdisplay` UX refinements only if daily-driving reveals real friction
5. future systray / non-`lx*` widget hosting in `lxbar`
6. `lxnotify` browser/web-app action hardening

Rationale:

- `lxsecrets` already exists in shell form and has the highest remaining
  feature value
- `lxbar` polish is visible and useful, but lower risk than larger new module
  work
- theme cleanup is structural and best done after the most visible behavior is
  stable
- `lxdisplay` already covers the core workflow and should now evolve from real
  usage feedback, not speculation
- systray/non-`lx*` hosting is still underspecified and likely to churn config
  shape
- `lxnotify` hardening stays deliberately late until daily-driver evidence says
  it matters

## Repo-Wide Work

- finish the public-defaults pass so `config/defaults.lua` reads like shipped
  defaults instead of local machine state
- keep `config.example.lua` as an example/override file rather than a second
  defaults file
- preserve top-level `config.lua` as gitignored local machine state
- add any remaining repository-wide policy or documentation notices once the
  project shape is more stable
- do one later cleanup pass to remove stale glue, prune dead definitions, and
  tighten boundaries after feature work settles

## Module And Theme Roadmap

### `lxcommon`

- keep popup keyboard, hover-close, outside-click, and placement behavior
  consistent across modules
- keep `lxcommon` small and utility-focused rather than turning it into a
  generic dumping ground

### `lxbar`

- continue polishing top-level widget spacing and composition behavior
- keep popup cycling strictly derived from final top-level widget order
- support future optional systray-style non-`lx*` widget integration once the
  config shape is clear enough

### `lxmedia`

- keep the combined audio/device/media-control model stable
- keep the two-popup model:
  - primary popup for playback streams and transport
  - secondary popup for devices and routing
- continue smoothing top-level bar show/hide behavior
- document the popup keyboard-controls contract more clearly

### `lxnotify`

- keep grouped notification handling, keyboard navigation, and popup cycling
  stable
- continue shrinking `init.lua` into thin entry-point/public API code
- harden notification action invocation for browser/web-app edge cases if
  daily-driving proves it worthwhile

### `lxnetwork`

- keep the WiFi popup compact and scan-oriented
- preserve current/known/available network flow
- keep keyboard navigation and popup cycling aligned with shared bar semantics

### `lxbluetooth`

- keep the popup compact:
  - open external manager
  - toggle controller power
  - list paired devices
  - connect/disconnect selected device
- keep popup/session behavior aligned with the shared bar model

### `lxpower`

- keep the quick-toggle plus popup-selection model stable
- keep preferred profile memory per power source
- keep battery timing and dGPU state as compact metadata, not the main focus

### `lxdisplay`

- keep brightness/redshift behavior stable and predictable
- refine profile/detected-display UX only when real daily-driving friction
  appears
- expand transient-display behavior only if the current narrow action set
  proves insufficient

### `lxrunner`

- track invocation counts in history so sorting can consider “most used” as
  well as “last used”

### `lxsecrets`

- implement the module from the existing shell scripts
- provide:
  - a top-level widget with healthy/suspended/attention states
  - a popup grouped by upstream/provider
  - active refresh/recheck actions
  - startup and interval-based standalone refresh support
  - preflight dependency checks
- keep secret definitions in `config.lua`
- support VPN-gated refresh blocks for secrets that require them
- surface failures in `~/.xsession-errors` and via notifications
- define a pragmatic plugin API for adding more secret providers later

### `themes/lynxburn`

- split structural values from color-scheme values later
- keep moving repo-specific behavior out of `themes/lynxburn/widgets.lua`
  where that improves ownership boundaries
- prune unused inherited assets once the remaining legacy widget usage is gone
