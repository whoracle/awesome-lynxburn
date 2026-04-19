# lxcommon Spec

This file tracks the remaining intended work for the shared helper layer.

## Planned Features

- continue moving concrete repeated popup/controller behavior into `lxcommon`
  when the duplication is still active and materially hurts maintainability

- keep popup keyboard, hover-close, outside-click, and placement behavior
  consistent across modules

- keep `lxcommon` small and utility-focused rather than letting it become a
  vague dumping ground for unrelated helpers

## Won't Do

- no `lxcommon` user-facing settings surface
  Why: user-facing knobs belong to modules or the flat theme contract

- no speculative abstraction just because two modules look similar once
  Why: extraction should only happen when it removes real drift or duplication

- no independent popup-ordering system here
  Why: popup ordering belongs to `lxbar` composition semantics
