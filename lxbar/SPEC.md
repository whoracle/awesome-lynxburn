# lxbar Spec

This file describes the intended scope of the shared bar composition layer.

Planned work lives in [`../ROADMAP.md`](../ROADMAP.md).

## Scope

- popup cycling is derived from final top-level widget order
- semantic popup-role routing is stable and limited to:
  - `primary`
  - `secondary`
  - `tertiary`
- `lxbar` owns composition of registered top-level widgets and shared popup
  routing semantics

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
