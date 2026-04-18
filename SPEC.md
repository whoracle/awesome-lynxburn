# Desktop QoL Additions

This file is the forward-looking design and task document for this config.

It should describe:

- work that is still wanted
- the intended shape of that work
- constraints that should guide implementation
- work that is explicitly deferred or rejected, with the reason

It should not carry historical implementation notes or migration logs.

## General Direction

This repo should continue moving toward compact, Awesome-native modules rather
than a large desktop-wide settings shell.

The preferred shape remains:

- top-level `config.lua` as the user-facing config entrypoint
- `config/defaults.lua` for shipped defaults
- `theme = { ... }` for flat theme overrides
- `lxmodules.lxbar` for bar composition and popup-cycling participation
- `lxmodules.<module>` for module-owned runtime behavior
- flat `beautiful.<key>` theme contracts for visual/theme-facing values

Design constraints that still matter for future work:

- popup cycling follows `lxbar` widget order only
- popup roles are semantic: `primary`, `secondary`, `tertiary`
- non-popup actions must not participate in popup cycling
- popup placement is `"center"` or `"side"` only
- actual left/right side selection is global via `lxmodules.lxbar.popup_side`
- module-private functionality should stay with that module instead of being
  moved into generic global config buckets

## Still Wanted

### `lxnotify`

#### Goal

Make retained notification actions more reliable, especially for browsers and
 web-apps, without weakening the inbox semantics that already work for normal
 desktop applications.

#### Current Problem

The brittle path is notification invocation, not basic storage/dismissal.
Browser and web-app notifications often have less predictable action objects,
client associations, or destroy semantics than native apps.

#### Intended Direction

Action hardening should focus on:

- invoking the intended action when one exists and is meaningful
- avoiding accidental destructive side effects during dismiss paths
- degrading safely when a notification is malformed or underspecified
- preserving the distinction between:
  - dismissing a retained inbox item
  - invoking an application action

#### Constraints

- dismiss should stay safe when `naughty` is suspended
- browser/web-app oddities should not crash Awesome
- the inbox should prefer safe no-op fallback over surprising destructive
  behavior
- this should remain a compact inbox UI, not turn into a generic notification
  debugger or analytics panel

#### Secondary Polish

After action hardening, small visual polish is still wanted:

- keep the bell-only top-level widget compact
- keep popup selection and hover visuals semantically named and consistent
- avoid reintroducing generic/ambiguous notify theme keys

### `lxnetwork`

#### Goal

Polish network popup readability without expanding the module into a larger
 network-management shell.

#### Intended Change

Replace the current plain `[WiFi N]` suffix with a small styled capability
badge or similarly compact visual marker.

#### Intended Shape

The badge should:

- be compact and easy to scan
- read as supplementary metadata rather than part of the SSID text
- fit the existing popup row layout
- not make already-long network names harder to read

Likely targets for the first pass:

- WiFi generation / standard
- possibly VPN state styling if it can stay compact and visually distinct

#### Constraints

- do not bloat the row with too much secondary metadata
- keep the main SSID text dominant
- keep the popup keyboard/mouse behavior unchanged unless a clear improvement is
  needed

### `lxrunner`

#### Goal

Continue polishing `lxrunner` as a narrow Awesome-native launcher rather than a
general-purpose clone of Rofi.

#### Intended Direction

The most useful remaining work is presentation, not core capability:

- make alias-backed results easier to scan
- make glyph/image-decorated aliases feel intentional instead of bolted on
- consider light source/description metadata only if it improves result clarity

#### Preferred Shape

Keep result rows simple:

- strong primary label
- optional small secondary cue later if needed
- no heavy multi-column launcher UI

Aliases should remain:

- part of `lxmodules.lxrunner.aliases`
- searchable alongside commands and desktop entries
- narrow, local conveniences rather than a plugin ecosystem

#### Constraints

- no plugin system
- no window switcher mode
- no Rofi feature-parity chase
- no result presentation that overwhelms the compact launcher layout

### `lxdisplay`

#### Goal

Grow `lxdisplay` into the place for display-oriented QoL behavior, but stop
short of turning it into a full display manager or desktop settings center.

#### Current Intent

The next meaningful expansion is not more brightness polish. It is optional
display-profile / `xrandr` handling for common real-world workflows.

#### Intended Feature Direction

Add a later `xrandr` / profile layer inside `lxdisplay` that can cover cases
such as:

- notebook + newly plugged external display/projector
- desktop gaming profile with only the primary display enabled
- desktop drawing/tablet profile with a usually-disabled extra display

#### Preferred Shape

The first pass should be profile-oriented rather than a fully manual display
arrangement UI.

Expected model:

- `lxdisplay` owns display hardware / connector handling
- it exposes a compact popup or profile action surface
- users can enable known outputs or apply known named layouts
- output/layout management stays optional for users who do not want `lxdisplay`

Likely first-pass operations:

- enable a newly connected output
- mirror
- extend left / right
- apply a named profile such as:
  - `default`
  - `gaming`
  - `drawing`

#### Config Ownership

This work should live under `lxmodules.lxdisplay`, not under `screens`.

Expected direction:

- `screens`
  stays about Awesome concepts:
  - DPI
  - tags
  - per-screen tag layouts
- `lxmodules.lxdisplay`
  owns hardware/display profile config:
  - connector naming
  - profile definitions
  - `xrandr` actions
  - optional display presets

#### Constraints

- X11 / `xrandr` only for now
- no giant settings-center UX
- no attempt at full manual monitor arrangement in the first pass
- no folding hardware layout state into `screens`
- should degrade cleanly when users do not configure or use the feature

### `lxbar` / `lxcommon`

#### Goal

Finish the shared interaction/popup cleanup without inventing abstraction for
its own sake.

#### Still Wanted

- continue extracting repeated popup/controller code into `lxcommon` when the
  duplication is still concrete and active
- continue polishing compact top-level widget alignment and spacing across
  modules
- keep shared popup semantics centralized instead of letting modules drift into
  inconsistent behavior again

#### Areas Still Worth Watching

- compact top-level spacing/alignment consistency
- popup-open highlight behavior
- small repeated controller patterns that may still remain outside `lxcommon`
- debug / no-glyph fallback mode later, if it still feels useful after visual
  polish

#### Constraints

- do not reintroduce a separate popup order surface
- do not split shared code just because two modules happen to look similar once
- prefer extraction only where it reduces real drift or maintenance cost

### Theme / config cleanup

#### Goal

Finish the central config/theme shape cleanly before returning to broader
feature expansion.

#### Still Wanted

- later split `themes/lynxburn/theme.lua` into:
  - structure/config wiring
  - palette/colors
- replace the current personal defaults in `config/defaults.lua` with sane
  public-facing defaults once the config surface stops moving

#### Constraints

- keep the runtime theme contract flat
- keep `config.lua` as the user-facing override entrypoint
- avoid reintroducing split runtime override files
- do not prematurely optimize the theme structure before the feature surface is
  stable

### Repo docs / hygiene

#### Still Wanted

- rewrite the top-level `README.md` after the implementation settles
- add or finalize licensing documentation

#### Constraints

- `README.md` should be rewritten only after the public-facing structure is
  stable enough to avoid churn

## Deferred / Not Doing For Now

### Popup ordering and popup semantics

- do not add popup ordering independent from `lxbar` widget order
  Why: popup cycling should follow visible widget order exactly

- do not let non-popup actions participate in popup cycling
  Why: popup cycling is for popup navigation, not module side effects

- do not expose per-popup left/right placement
  Why: popup placement should stay `"center"` / `"side"` with global side
  selection

### Config shape

- do not restore split runtime `config/override/*.lua` inputs
  Why: top-level `config.lua` is the intended user override surface now

- do not reintroduce a separate `widgets = { ... }` config surface
  Why: bar composition belongs under `lxmodules.lxbar`

- do not move module-private backend wiring into generic `commands`
  Why: module-owned behavior such as brightness/redshift belongs under
  `lxmodules.<module>`

### Scope control

- do not turn this config into a large desktop-wide settings center
  Why: the target remains compact, high-value Awesome-native modules

- do not do systray-in-`lxbar` work yet
  Why: the idea is still underspecified and should wait until the rest of the
  config and module shape is settled

- do not fold hardware display-layout config into `screens`
  Why: `screens` should stay about Awesome-side roles, DPI, tags, and layouts
