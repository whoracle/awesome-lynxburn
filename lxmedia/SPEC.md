# lxmedia SPEC

Planned work lives in [`../ROADMAP.md`](../ROADMAP.md).

## Scope

- `lxmedia` is the combined audio widget for:
  - default output volume/mute
  - microphone activity and input volume
  - playback stream inspection
  - output/input device switching
  - basic MPRIS transport controls
- it keeps the two-popup model:
  - primary popup for playback streams and transport
  - secondary popup for devices and routing
- top-level controls stay compact and bar-friendly
- popup/session behavior stays aligned with the shared `lxbar` model
- the module may use both event subscription and polling so responsiveness does
  not depend on one backend path only

## Known issues

- README.md is missing the keyboard controls contract. Only mouse interactions and "how to spawn the widget" keybindings are documented.

## Unplanned

- No attempt to become a full mixer UI comparable to `pavucontrol`.
  Reason: the module is meant to stay popup-oriented and fast to scan.
- No per-player dedicated popups, playlist UIs, or seek controls.
  Reason: current scope is transport and routing, not full media control.
- No separate popup ordering model.
  Reason: popup participation follows `lxbar` top-level order and semantic role
  ordering.
- No remote artwork fetching.
  Reason: only local `file://` artwork is in scope right now.
