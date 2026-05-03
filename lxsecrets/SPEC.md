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
- a narrow provider plugin API is planned so current native providers can move
  behind a stable interface without turning the whole repo into a plugin
  framework

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

## Future Provider Plugin Shape

The provider API should be small enough that a provider only implements the
secret-specific parts:

- identify whether a configured secret belongs to the provider
- read the current secret value from the keyring selectors
- check freshness/expiry
- refresh or rotate the secret when possible
- report whether an interactive login is required
- write replacement secret values and metadata back through shared helpers

Shared orchestration should stay in `lxsecrets`: VPN gating, batching, timers,
popup state, keyring helper behavior, and user-facing status handling.
