# lxnetwork SPEC

Planned work lives in [`../ROADMAP.md`](../ROADMAP.md).

## Scope

- `lxnetwork` is a compact WiFi status-and-connect module, not a broad
  connection-management UI
- its popup flow stays focused on:
  - current connection
  - visible known networks
  - visible additional networks
  - inline actions for scan and WiFi enable/disable
- keyboard navigation and popup cycling stay aligned with the shared `lxbar`
  popup model

## Unplanned

- No full NetworkManager frontend.
  Reason: the module is meant to stay lightweight and popup-oriented.
- No credential storage inside `lxnetwork`.
  Reason: passwords are only collected transiently and handed to `nmcli`.
- No separate popup ordering model.
  Reason: popup participation follows `lxbar` top-level order and semantic role
  ordering.
- No expansion into wired, modem, VPN profile editing, or advanced connection
  authoring workflows right now.
  Reason: those are outside the current scope and would push the module toward
  a different class of tool.
