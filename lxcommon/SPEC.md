# lxcommon Spec

This file describes the intended scope of the shared helper layer.

Planned work lives in [`../ROADMAP.md`](../ROADMAP.md).

## Scope

- `lxcommon` owns shared helper code for popup behavior, registry/state
  plumbing, placement, widget feedback, and other genuinely cross-module
  infrastructure
- it should stay utility-focused rather than becoming a vague bucket for
  unrelated code

## Won't Do

- no `lxcommon` user-facing settings surface
  Why: user-facing knobs belong to modules or the flat theme contract

- no speculative abstraction just because two modules look similar once
  Why: extraction should only happen when it removes real drift or duplication

- no independent popup-ordering system here
  Why: popup ordering belongs to `lxbar` composition semantics
