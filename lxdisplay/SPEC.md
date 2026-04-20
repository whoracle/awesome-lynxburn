# lxdisplay Remaining Work

`lxdisplay` already exists as the local display/brightness/redshift module.

This file only tracks the remaining intended work.

## Still Wanted

- keep brightness/redshift behavior stable and predictable
  Why: this module owns display-side QoL behavior and should stay boring in the
  good sense

- refine the new profile popup after real use
  Why: profile summaries, detected-display actions, and activation feedback
  should be validated against daily-driving before broadening the feature set

- expand transient-display behavior only if needed
  Why: the first pass intentionally keeps temporary display actions narrow
  (`Detect`, `Extend`, `Mirror`, `Disable`) instead of becoming a full editor

## Explicit Non-Goals For Now

- no full display manager or settings-center behavior
  Why: the module should stay compact

- no folding hardware display-layout config into `screens`
  Why: `screens` should stay focused on Awesome concepts such as DPI, tags, and
  layouts

- no always-on output polling
  Why: transient display discovery is intentionally user-triggered through the
  popup
