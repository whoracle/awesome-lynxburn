# lxdisplay Spec

Planned work lives in [`../ROADMAP.md`](../ROADMAP.md).

## Scope

- `lxdisplay` is the local display/brightness/redshift module
- it owns:
  - brightness controls
  - redshift/night-mode behavior
  - display profiles
  - platform-specific display-profile backends
  - narrow transient-display actions from the popup
- transient display discovery is intentionally user-triggered rather than
  always-on
- backend-specific command details stay behind the backend layer; profile
  configuration should remain as close as practical between X11 and SomeWM
- startup profile application should be a no-op when the active backend state
  already matches the selected profile closely enough to avoid display flicker

## Explicit Non-Goals For Now

- no full display manager or settings-center behavior
  Why: the module should stay compact

- no folding hardware display-layout config into `screens`
  Why: `screens` should stay focused on Awesome concepts such as DPI, tags, and
  layouts

- no always-on output polling
  Why: transient display discovery is intentionally user-triggered through the
  popup

- no ad-hoc command swapping in the main module
  Why: X11 and Wayland display tools differ enough that backend files are the
  safer boundary
