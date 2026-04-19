# lxbluetooth SPEC

## Planned

- Keep `lxbluetooth` as a compact controller/device popup rather than growing
  it into a full Bluetooth management frontend.
- Preserve the current popup shape:
  - open external manager
  - toggle controller power
  - list paired devices
  - connect/disconnect selected device
- Keep popup cycling and keyboard navigation aligned with the shared `lxbar`
  popup model.
- Continue splitting popup/session logic into dedicated files instead of
  regrowing a large `init.lua`.
- Improve visual readability only in ways that keep the popup compact.

## Unplanned

- No full pairing/discovery workflow inside `lxbluetooth`.
  Reason: that would push the module beyond its quick-control scope.
- No separate popup ordering model.
  Reason: popup participation follows `lxbar` top-level order and semantic role
  ordering.
- No credential or PIN handling inside the module.
  Reason: pairing flows remain the responsibility of external tools.
