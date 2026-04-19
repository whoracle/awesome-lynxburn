# lxmedia SPEC

## Planned

- Keep `lxmedia` as the combined audio widget for:
  - default output volume/mute
  - microphone activity and input volume
  - playback stream inspection
  - output/input device switching
  - basic MPRIS transport controls
- Preserve the two-popup model:
  - primary popup for playback streams and transport
  - secondary popup for devices and routing
- Keep top-level controls compact and bar-friendly.
- Continue using shared popup/session semantics so popup cycling and keyboard
  behavior stay aligned with the rest of the lx* modules.
- Keep `init.lua` thin by moving lifecycle/runtime helpers and popup-controller
  logic into focused files.
- Retain both event subscription and polling so the widget stays responsive
  without depending on one backend path only.

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
