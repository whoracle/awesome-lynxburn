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
- fix the current partial popup key fallback path; global shortcuts still do not
  reliably work while popups are open
- make popup keyboard interaction available even when a popup was opened via
  mouse, not just via explicit keyboard-navigation entry points
- when a popup opened via mouse is also keyboard-active, keep it from closing
  immediately just because the pointer is not hovering the popup; hover-close
  and keyboard-focus need a cleaner coexistence model
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
- fix right click on notifications inside a group so it reliably triggers the
  secondary action (`dismiss`) instead of sometimes firing the primary action
- consider auto-pausing popups while a screen share is active, if there is a
  reliable detection path that is not too environment-specific

### `lxrunner`

- keep the keyboard-first launcher flow stable
- add left-click launch on result rows later so mouse usage is possible without
  changing the rest of the runner model
- continue shrinking `init.lua` into thin entry-point/public API code
- harden notification action invocation for browser/web-app edge cases if
  daily-driving proves it worthwhile
- consider a way for aliases/actions to request targeted module refreshes so
  one-shot commands like starting a VPN can update the relevant `lx*` widget
  immediately without globally increasing poll frequency

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
- write back `expiry_date` metadata reliably even when the original keyring
  entry did not already contain that attribute
- consider changing the default refresh contract away from periodic polling:
  either make `interval` default to a no-op/off state or otherwise reduce the
  amount of background refresh by default
- improve startup refresh behavior so the first pass waits for usable network
  availability instead of relying only on a blind timer delay
- add a secondary card action to open the corresponding secret in a keyring UI
  such as Seahorse
- define plugin scaffolding for providers, then migrate the current GitLab and
  Vault implementations onto that plugin interface once the contract is stable

### `themes/lynxburn`

- keep the structural-vs-color-scheme split stable and well-documented
- continue normalizing explicit theme keys so modules rely less on generic
  Awesome fallbacks
- align popup/action button border treatment across modules during the theme
  split pass; some current buttons still mix orange and gray border behavior
- discuss UI and maintenance feasibility before adding many more bundled color
  schemes beyond the current set
- likely future scheme candidates from daily-driving:
  - `gruvbox` (`dark`, `light`)
  - `dracula`
  - `one_dark`
  - `everforest`
  - `monokai`
  - `solarized_dark`
  - `kanagawa` (`wave`, `dragon`, `lotus`)
- consider an opt-in startup mode that picks a random bundled color scheme on
  each Awesome start as an easter egg feature
- smooth top-level widget bar reveal/hide behavior with a delayed ease-in/out
  animation instead of the current delayed pop-in
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
