# lxbar Spec

This file tracks the remaining intended work for the shared bar composition
layer.

## Planned Features

- keep popup cycling strictly derived from final top-level widget order

- keep semantic popup role routing stable:
  - `primary`
  - `secondary`
  - `tertiary`

- continue polishing top-level widget spacing and bar composition behavior once
  the individual modules stabilize

- support future optional systray-style non-`lx*` bar integration later if the
  config shape becomes clear enough

## Won't Do

- no popup ordering independent from top-level widget order
  Why: popup cycling should mirror the visible bar order exactly

- no popup cycling for non-popup actions
  Why: cycling is navigation, not a trigger surface for side effects

- no per-popup left/right selection
  Why: popups should choose only `"center"` or `"side"`; actual side is global

- no premature systray hosting work right now
  Why: that shape is still underspecified and should wait until the rest of the
  module/config surface is stable
