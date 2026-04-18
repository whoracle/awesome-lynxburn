# Desktop QoL Additions

This file is the forward-looking task list for this config.

It should only describe:

- work that is still wanted
- work that is explicitly out of scope or deferred, with the reason

It should not carry historical implementation notes.

## Still Wanted

Items are grouped by area, with lower-complexity and higher-value work first.

### `lxnotify`

- Harden browser and web-app notification action invocation further.
  Why: this is still the weakest part of `lxnotify` behavior and is the most
  likely stability issue in day-to-day use.

### `lxnetwork`

- Replace the plain `[WiFi N]` suffix with a small styled capability badge.
  Why: the current text works, but it is visually clumsy compared with the rest
  of the popup.

### `lxrunner`

- Keep polishing alias presentation now that aliases support both glyphs and
  image icons.
  Why: the core behavior is there, but the result list can still become more
  readable and easier to scan.

### `lxdisplay`

- Add a later `xrandr` / display-profile layer inside `lxdisplay`.
  Why: display layout handling belongs with display UI, but it should come only
  after the current config and module cleanup is done.
  Expected direction:
  - profile-oriented
  - optional for users who do not want `lxdisplay`
  - separate from `screens`, which should remain Awesome-side screen/tag config

### `lxbar` / shared popup behavior

- Keep polishing compact top-level widget alignment and spacing across modules.
  Why: the shared config and naming cleanup is mostly done; the remaining work
  here is mainly visual consistency and small interaction polish.

- Continue extracting repeated popup/controller logic into `lxcommon` when a
  concrete duplication is still left.
  Why: shared code should only be extracted where it materially reduces drift
  and duplication; the broad direction remains correct.

### Theme / config cleanup

- Split `themes/lynxburn2/theme.lua` into non-color structure/config versus
  palette later.
  Why: that would make multiple color schemes easier without duplicating module
  sizing, icon, and layout defaults.

- Replace the current personal defaults in `config/defaults.lua` with more sane
  public-facing defaults at the end.
  Why: for now the priority is finishing behavior and config shape; default
  values can be sanitized once the structure stops moving.

### Repo cleanup

- Rewrite `README.md` after the implementation settles.
  Why: the final public-facing shape is still moving, so writing the final
  README now would just create churn.

- Add or finalize licensing documentation.
  Why: that is still missing, but it should not block feature or refactor work.

## Explicit Non-Goals / Rejected Directions

### Popup ordering

- Do not add popup ordering that is independent from `lxbar` widget order.
  Why: popup cycling should follow the visible top-level widget order exactly.

- Do not let non-popup actions participate in popup cycling.
  Why: popup cycling is for popup navigation only, not for triggering module
  side effects such as mute toggles.

- Do not expose per-popup left/right placement.
  Why: each popup should choose only between `"center"` and `"side"`, with the
  actual side controlled globally by `lxmodules.lxbar.popup_side`.

### Config shape

- Do not restore split runtime `config/override/*.lua` inputs.
  Why: top-level `config.lua` is the user-facing override surface now; the old
  override files are migration/examples only.

- Do not move module-private backend wiring into generic `commands`.
  Why: module-owned functionality such as brightness backends or redshift
  behavior belongs under `lxmodules.<module>`, not in a global command bucket.

- Do not introduce a separate `widgets = { ... }` config surface again.
  Why: bar composition now lives under `lxmodules.lxbar`, and per-module
  behavior lives under `lxmodules.<module>`.

### Scope control

- Do not turn this config into a large desktop-wide settings center.
  Why: the target is compact, high-value Awesome-native modules, not a full
  general-purpose control panel.

- Do not do systray-in-`lxbar` work yet.
  Why: the idea is still underspecified and should wait until the rest of the
  config shape and module work is done.

- Do not fold `xrandr` display-layout config into `screens`.
  Why: `screens` should stay focused on Awesome concepts such as DPI, tags, and
  layouts; display hardware/profile management belongs with `lxdisplay`.
