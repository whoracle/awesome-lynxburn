# Roadmap

This file tracks planned work.

`SPEC.md` files describe scope and explicit non-goals. They should not be the
main backlog.

## Priority Order

Use this order for the next fresh session unless new bugs force a
reprioritization:

1. `lxsecrets` UX polish
2. `lxdisplay` UX refinements only if daily-driving reveals real friction
3. `themes/lynxburn` follow-up polish
4. future systray / non-`lx*` widget hosting in `lxbar`
5. `lxnotify` browser/web-app action hardening
6. `lxrunner` history-weighted result ordering

Rationale:

- `lxsecrets` now works end-to-end and the next value is making its popup and
  state presentation feel as polished as the older modules
- `lxdisplay` already covers the core workflow and should now evolve from real
  usage feedback, not speculation
- theme cleanup already landed the larger split/pruning work, so what remains
  is follow-up polish rather than structural cleanup
- systray/non-`lx*` hosting is still underspecified and likely to churn config
  shape
- `lxnotify` hardening stays deliberately late until daily-driver evidence says
  it matters
- `lxrunner` history weighting is useful, but lower urgency than the current
  popup/theme/module finish work

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

- keep popup cycling strictly derived from final top-level widget order
- support future optional systray-style non-`lx*` widget integration once the
  config shape is clear enough

### `lxmedia`

- keep the combined audio/device/media-control model stable
- keep the two-popup model:
  - primary popup for playback streams and transport
  - secondary popup for devices and routing
- continue smoothing top-level bar show/hide behavior

### `lxnotify`

- keep grouped notification handling, keyboard navigation, and popup cycling
  stable

### `lxrunner`

- keep the keyboard-first launcher flow stable
- add left-click launch on result rows later so mouse usage is possible without
  changing the rest of the runner model
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
- consider making startup default-profile application state-aware so `lxdisplay`
  skips the apply step when the already-live XRandR state matches the chosen
  default profile closely enough

### `lxsecrets`

- keep the native provider runtime stable for GitLab and Vault
- continue polishing popup card layout, sorting, and state presentation
- keep secret definitions in `config.lua`
- support VPN-gated refresh/login flows where required
- surface failures in `~/.xsession-errors` and via notifications
- define a pragmatic plugin API for adding more secret providers later
- consider delaying `at_start` refresh runs by a small configurable startup
  grace period so the first pass does not race NetworkManager or other session
  services

### `themes/lynxburn`

- keep the structural-vs-color-scheme split stable and well-documented
- add at least one second bundled color scheme once there is appetite to pick
  real colors
- continue normalizing explicit theme keys so modules rely less on generic
  Awesome fallbacks
- align popup/action button border treatment across modules during the theme
  split pass; some current buttons still mix orange and gray border behavior
- keep these as theme-owned unless the repo shape changes materially:
  - wallpaper application
  - wibar assembly
  - tasklist/taglist/layout switcher composition
  - systray / clock / date placement

### Proposed `lxmenu`

- consider a future `lxmenu` module as the replacement home for the current
  theme-owned power menu popup and similar session/menu actions
- keep this proposal late until there is a clearer decision on scope:
  - just session/power actions
  - or a broader launcher/menu surface
