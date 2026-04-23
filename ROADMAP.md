# Roadmap

This file tracks planned work.

`SPEC.md` files describe scope and explicit non-goals. They should not be the
main backlog.

## Priority Order

Use this order for the next fresh session unless new bugs force a
reprioritization:

1. `lxsecrets` UX polish
2. `lxbar` spacing/composition polish
3. `themes/lynxburn` ownership cleanup / asset pruning / theme-surface polish
4. `lxdisplay` UX refinements only if daily-driving reveals real friction
5. future systray / non-`lx*` widget hosting in `lxbar`
6. `lxnotify` browser/web-app action hardening

Rationale:

- `lxsecrets` now works end-to-end and the next value is making its popup and
  state presentation feel as polished as the older modules
- `lxbar` polish is visible and useful, but lower risk than larger new module
  work
- theme cleanup is now mostly ownership and surface cleanup after the structure
  vs color-scheme split landed
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
- consider an optional update-checker helper that, when the live Awesome config
  checkout is a git repo, compares the current state against newer available
  tags and notifies the user; keep it disabled by default and opt-in via
  `config.lua`
- add any remaining repository-wide policy or documentation notices once the
  project shape is more stable
- do one later cleanup pass to remove stale glue, prune dead definitions, and
  tighten boundaries after feature work settles

## Module And Theme Roadmap

### `lxcommon`

- keep popup keyboard, hover-close, outside-click, and placement behavior
  consistent across modules
- revisit popup input handling so open `lx*` popups do not block unrelated
  global shortcuts; prefer a focus-based model or otherwise preserve normal key
  bindings while popups are open
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

- keep the native provider runtime stable for GitLab and Vault
- continue polishing popup card layout, sorting, and state presentation
- keep secret definitions in `config.lua`
- support VPN-gated refresh/login flows where required
- surface failures in `~/.xsession-errors` and via notifications
- define a pragmatic plugin API for adding more secret providers later

### `themes/lynxburn`

- keep the structural-vs-color-scheme split stable and well-documented
- continue normalizing explicit theme keys so modules rely less on generic
  Awesome fallbacks
- align popup/action button border treatment across modules during the theme
  split pass; some current buttons still mix orange and gray border behavior
- keep moving repo-specific behavior out of `themes/lynxburn/widgets.lua`
  where that improves ownership boundaries
- treat these as likely future move candidates out of `widgets.lua`:
  - IMAP mail widget
  - lain CPU / sysload / memory / filesystem widgets
  - the custom power menu popup
- keep these as theme-owned unless the repo shape changes materially:
  - wallpaper application
  - wibar assembly
  - tasklist/taglist/layout switcher composition
  - systray / clock / date placement
- prune unused inherited assets once the remaining legacy widget usage is gone
