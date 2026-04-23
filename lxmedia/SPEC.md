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
- Introduce some kind of easing into top-level bar display/collapse

## Known issues

- pressing any key on the keyboard when a card is focused yields:
  ```lua
stack traceback:
    ...thrax/.config/awesome/lxmedia/media_popup_controller.lua:49: in local 'callback'
    /home/USER/.config/awesome/lxmedia/runtime.lua:90: in function 'lxmedia._with_audio'
    ...thrax/.config/awesome/lxmedia/media_popup_controller.lua:43: in function 'lxmedia.change_selected_media_stream_volume'
    ...thrax/.config/awesome/lxmedia/media_popup_controller.lua:180: in local 'action'
    /home/USER/.config/awesome/lxcommon/popup_control.lua:298: in function 'lxcommon.popup_control.dispatch_popup_keypress'
    ...thrax/.config/awesome/lxmedia/media_popup_controller.lua:154: in function 'lxmedia._handle_media_popup_keygrabber'
    ...thrax/.config/awesome/lxmedia/media_popup_controller.lua:208: in upvalue 'handler'
    /home/USER/.config/awesome/lxcommon/popup_control.lua:321: in field 'keypressed_callback'
    /usr/share/awesome/lib/awful/keygrabber.lua:331: in function </usr/share/awesome/lib/awful/keygrabber.lua:240>
    (...tail calls...)
    /usr/share/awesome/lib/awful/keygrabber.lua:214: in function </usr/share/awesome/lib/awful/keygrabber.lua:211>
error: ...thrax/.config/awesome/lxmedia/media_popup_controller.lua:49: attempt to call a nil value (method '_defer_media_popup_refresh')
  ```
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
