# lxdisplay Remaining Work

`lxdisplay` already exists as the local display/brightness/redshift module.

This file only tracks the remaining intended work.

## Still Wanted

- add optional `xrandr` / display-profile handling later
  Why: display hardware/profile management belongs here, but only after the
  broader config and module cleanup is finished

- keep brightness/redshift behavior stable and predictable
  Why: this module owns display-side QoL behavior and should stay boring in the
  good sense

## Explicit Non-Goals For Now

- no full display manager or settings-center behavior
  Why: the module should stay compact

- no folding hardware display-layout config into `screens`
  Why: `screens` should stay focused on Awesome concepts such as DPI, tags, and
  layouts
