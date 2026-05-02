# lxsecrets SPEC

Planned work lives in [`../ROADMAP.md`](../ROADMAP.md).

## Scope

- `lxsecrets` is the secret/token refresh helper for this config
- it owns:
  - startup refresh runs and optional periodic refresh
  - compact top-level healthy/suspended/attention state
  - a popup grouped by provider
  - per-secret refresh actions
  - interactive follow-up login when a provider requires it
  - writing refreshed secrets back into the keyring
- the module currently supports `gitlab` and `hashicorp_vault`
- VPN-gated refresh/login flows are in scope where a configured secret needs
  them

## Explicit Non-Goals For Now

- no generic secret-manager replacement UI
  Why: the module should stay focused on refresh/check workflows rather than
  becoming a full secret browser/editor

- no persistent per-secret popup state across Awesome reloads
  Why: first-pass runtime state is intentionally kept in memory only

- no hard dependency on external widget/layout helper internals for provider
  logic
  Why: `lxsecrets` should stay usable even if repo-owned code continues to
  replace external helpers with local implementations

- no broad provider matrix yet
  Why: only the providers currently used in the config should shape the module
  until the plugin surface settles
