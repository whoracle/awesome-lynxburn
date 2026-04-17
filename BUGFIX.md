# Notebook Bugfix Pass

This file is no longer a forward plan. It now records the current status of the
notebook-focused bugfix pass so the larger `lxcommon` / `lxbar` rewrite can
start from an accurate baseline.

## Landed

The following fixes and polish work are now in the tree:

- `lxcommon` and `lxbar` were introduced and are live.
- `lx*` compact widgets are now composed through `lxbar` instead of being placed
  individually in the theme.
- popup cycling exists and is user-facing through `lxbar`.
- the current popup cycle bindings are `Ctrl+Mod4+Alt+Left` and
  `Ctrl+Mod4+Alt+Right`.
- reverse popup cycling now starts from the tail of the eligible popup list.
- popup placement is unified per popup with `left`, `right`, and `center`.
- shared progress/text OSD logic for audio and display moved into `lxcommon`.
- compact widget spacing was tightened across the `lx*` bar.
- audio and display inline bars are now intent-driven:
  - shown on hover
  - shown while that module's popup is open
  - hidden otherwise
- active top-level `lx*` widgets stay highlighted while their popup is open.
- `lxnotify` is back in both `lxbar` and popup cycling.
- popup widths are currently normalized to `360` across the `lx*` popups.
- `lxpowerprofiles` pinning landed with current popup keyboard semantics:
  - `Enter`: select profile
  - `Right`: select + pin
  - `Left`: unpin current pinned profile
- `lxnotify` keyboard semantics are currently:
  - notification card `Right`: dismiss
  - notification card `Enter`: invoke action / activate client
  - group `Right` / `Enter`: enter group
  - `Left`: go back from group detail or close from top-level
  - `Escape`: close popup
- `lxnotify` top-level state is now bell-only and color-driven:
  - unread always overrides to red
  - gold bell: `naughty` enabled, intercept enabled
  - grey bell: `naughty` enabled, intercept disabled
  - struck gold bell: `naughty` disabled, intercept enabled
  - struck grey bell: both disabled
- dismissing `lxnotify` entries while `naughty` is suspended now only removes
  them from `lxnotify` storage and no longer destroys the underlying
  notification object.
- `lxrunner` history now stores the canonical launched match label rather than
  the typed prefix.

## Still Open

These issues are known and intentionally not treated as resolved:

- the Wi-Fi icon clipping is still unresolved and now strongly suspected to be a
  glyph/font-rendering issue rather than layout width
- the long-term `lxcommon` extraction is still incomplete:
  - popup key helper duplication remains
  - outside-click and hover-close controller duplication remains
  - `lxaudio.popup_common` is still the main shared UI dependency
- `config/keys.lua` still contains both direct module popup bindings and shared
  `lxbar` popup actions
- declarative user-overridable `lxbar` order does not exist yet; order still
  comes from per-module default registration values in `config/services.lua`

## Deferred

These items were explicitly pushed out of the notebook bugfix pass:

- full module renames such as `lxpowersave -> lxpower`
- larger `lxcommon` architecture rewrite
- Bose headset media-key diagnosis
- deeper browser/media artwork diagnosis beyond the current known limitation
- click-to-set behavior for compact inline bars

## Current User-Facing Contract

The current expected `lxbar` order is:

1. bluetooth
2. network
3. powerprofiles
4. audio
5. display
6. notify

Display does not currently register a popup, so popup cycling skips it.

The current expected popup cycle order is therefore:

1. bluetooth
2. network
3. powerprofiles
4. audio
5. notify

## When This File Can Be Deleted

This file is still useful as long as the repo needs a compact summary of what
the notebook bugfix pass actually changed.

If a later architecture pass folds this status into `README.md` or `SPEC.md`,
this file can be deleted entirely.
