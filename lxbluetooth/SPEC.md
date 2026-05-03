# lxbluetooth SPEC

Planned work lives in [`../ROADMAP.md`](../ROADMAP.md).

## Scope

- `lxbluetooth` is a compact controller/device popup rather than a full
  Bluetooth management frontend
- the popup stays focused on:
  - open external manager
  - toggle controller power
  - list paired devices
  - connect/disconnect selected device
- popup cycling and keyboard navigation stay aligned with the shared `lxbar`
  popup model

## Unplanned

- No full pairing/discovery workflow inside `lxbluetooth`.
  Reason: that would push the module beyond its quick-control scope.
- No separate popup ordering model.
  Reason: popup participation follows `lxbar` top-level order and semantic role
  ordering.
- No credential or PIN handling inside the module.
  Reason: pairing flows remain the responsibility of external tools.
