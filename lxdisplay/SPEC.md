# lxdisplay Spec

Planned work lives in [`../ROADMAP.md`](../ROADMAP.md).

## Scope

- `lxdisplay` is the local display/brightness/redshift module
- it owns:
  - brightness controls
  - redshift/night-mode behavior
  - display profiles
  - narrow transient-display actions from the popup
- transient display discovery is intentionally user-triggered rather than
  always-on

## Explicit Non-Goals For Now

- no full display manager or settings-center behavior
  Why: the module should stay compact

- no folding hardware display-layout config into `screens`
  Why: `screens` should stay focused on Awesome concepts such as DPI, tags, and
  layouts

- no always-on output polling
  Why: transient display discovery is intentionally user-triggered through the
  popup
