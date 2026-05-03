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
- simple custom widgets may be hosted with `custom:<name>` order entries, but
  they stay visual-only unless promoted to real `lx*` modules

## Won't Do

- no popup ordering independent from top-level widget order
  Why: popup cycling should mirror the visible bar order exactly

- no popup cycling for non-popup actions
  Why: cycling is navigation, not a trigger surface for side effects

- no per-popup left/right selection
  Why: popups should choose only `"center"` or `"side"`; actual side is global

- no `lx*` interaction guarantees for custom widgets
  Why: custom widgets are for simple hosted widgets such as systray or metrics;
  popup cycling and shared input behavior require a real module contract
