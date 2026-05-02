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
4. `lxnotify` browser/web-app action hardening
5. `lxcommon` popup-input cleanup from real daily-driver evidence

Rationale:

- `lxsecrets` now works end-to-end and the next value is making its popup and
  state presentation feel as polished as the older modules
- `lxdisplay` already covers the core workflow and should now evolve from real
  usage feedback, not speculation
- theme cleanup already landed the larger split/pruning work, so what remains
  is follow-up polish rather than structural cleanup
- `lxnotify` hardening stays deliberately late until daily-driver evidence says
  it matters
- popup-input cleanup still matters, but it should be driven by real failures
  rather than another speculative framework rewrite

## Repo-Wide Work

- keep `config.example.lua` as an example/override file rather than a second
  defaults file
- preserve top-level `config.lua` as gitignored local machine state
- consider a top-level `config.lua` toggle such as `titlebars = true` for
  floating-heavy setups that want Awesome titlebars enabled again
  This needs more than a boolean wire-up; it also needs titlebar styling that
  actually fits the current theme instead of looking like an unintegrated
  fallback
- consider an optional update-checker helper that, when the live Awesome config
  checkout is a git repo, compares the current state against newer available
  tags and notifies the user; keep it disabled by default and opt-in via
  `config.lua`
- add any remaining repository-wide policy or documentation notices once the
  project shape is more stable
- do one later cleanup pass to remove stale glue, prune dead definitions, and
  tighten boundaries after feature work settles

## Layout Ownership

- replace `lain.util.useless_gaps_resize` with a tiny local gap-resize helper;
  clamp gaps to sane values instead of blindly allowing negative gaps
- reimplement `centerwork` and `centerwork.horizontal` as local layouts because
  those are part of the actual daily-driver contract
- treat `quake` as optional: either drop it from defaults if unused, or
  reimplement it deliberately as a local dropdown-terminal helper instead of
  copying `lain.util.quake` verbatim
- remove currently dead `termfair` and `cascade` setup from `config.layouts`
  unless they become explicitly selectable again
- add an explicit third-party layout extension point so local configs can
  register external layouts such as `lain` layouts without editing core files;
  expose the necessary knobs in config rather than hardcoding vendor-specific
  layout setup

## Module And Theme Roadmap

### `lxcommon`

- keep popup keyboard, optional hover-close, outside-click, and placement behavior
  consistent across modules
- revisit popup input handling so open `lx*` popups do not block unrelated
  global shortcuts; prefer a focus-based model or otherwise preserve normal key
  bindings while popups are open
- keep `lxcommon` small and utility-focused rather than turning it into a
  generic dumping ground

### `lxbar`

- keep popup cycling strictly derived from final top-level widget order
- keep `custom:<name>` hosting simple:
  - no popup cycling
  - no implicit `lx*` interaction contract
  - explicit `style = "lxbar" | "raw"` visual ownership
- continue migrating remaining simple non-`lx*` bar widgets into `lxbar` where
  that makes the overall bar composition cleaner

### `lxmedia`

- keep the combined audio/device/media-control model stable
- keep the two-popup model:
  - primary popup for playback streams and transport
  - secondary popup for devices and routing

### `lxnotify`

- keep grouped notification handling, keyboard navigation, and popup cycling
  stable
- fix right click on notifications inside a group so it reliably triggers the
  secondary action (`dismiss`) instead of sometimes firing the primary action
- consider auto-pausing popups while a screen share is active, if there is a
  reliable detection path that is not too environment-specific; PipeWire or
  portal-session state is the most likely signal source to investigate

### `lxrunner`

- keep the keyboard-first launcher flow stable
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

### `lxsecrets`

- keep the native provider runtime stable for GitLab and Vault
- continue polishing popup card layout, sorting, and state presentation
- keep secret definitions in `config.lua`
- support VPN-gated refresh/login flows where required
- surface failures in `~/.xsession-errors` and via notifications
- define a pragmatic plugin API for adding more secret providers later
- keep `expiry_date` metadata writes tied to replacement-secret stores unless a
  reliable keyring-safe way to amend existing item attributes appears
- improve startup refresh behavior so the first pass waits for usable network
  availability instead of relying only on a blind timer delay
- add a secondary card action to open the corresponding secret in a keyring UI
  such as Seahorse
- define plugin scaffolding for providers, then migrate the current GitLab and
  Vault implementations onto that plugin interface once the contract is stable
- evaluate `last checked` field

### `themes/lynxburn`

- keep the structural-vs-color-scheme split stable and well-documented
- continue normalizing explicit theme keys so modules rely less on generic
  Awesome fallbacks
- review the local replacement widgets for CPU, memory, load, filesystem,
  IMAP, calendar, and markup after daily-driving; look for clearer thresholds,
  better failure reporting, and whether any of them should become proper
  `lx*` modules instead of simple custom widgets
- align popup/action button border treatment across modules during the theme
  split pass; some current buttons still mix orange and gray border behavior
- discuss UI and maintenance feasibility before adding many more bundled color
  schemes beyond the current set
- likely future scheme candidates from daily-driving:
  - `gruvbox` (`dark`, `light`)
  - `dracula`
  - `everforest`
- consider an opt-in startup mode that picks a random bundled color scheme on
  each Awesome start as an easter egg feature
- keep these as theme-owned unless the repo shape changes materially:
  - wallpaper application
  - wibar assembly
  - tasklist/taglist/layout switcher composition
  - clock / date / power-menu placement

## Proposed further lxmodules

### `lxmenu`

- consider a future `lxmenu` module as the replacement home for the current
  theme-owned power menu popup and similar session/menu actions
- keep this proposal late until there is a clearer decision on scope:
  - just session/power actions
  - or a broader launcher/menu surface

### `lxsnippets`

- have text snippets from git snippets available for copy pasting
- store clipboard pastes

### `lxsession`

see [`lxsession`](./lxsession/SPEC.md)
