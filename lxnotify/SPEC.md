# lxnotify SPEC

Planned work lives in [`../ROADMAP.md`](../ROADMAP.md).

## Scope

- `lxnotify` is the retained in-session notification inbox for this config, not
  a full replacement for every live `naughty` popup behavior
- it preserves the current split between:
  - daemon suspension (`naughty.suspended`)
  - inbox interception pause
- grouped notification handling, keyboard navigation, popup cycling
  participation, and action invocation are first-class features
- the popup model stays compact:
  - top-level grouped inbox
  - per-group detail view
  - no separate alternate popup variants
- denylist-driven filtering stays configurable from `lxmodules.lxnotify`

## Unplanned

- No numeric unread counter in the top-level widget.
  Reason: the bell state is enough, and the count adds noise to the bar.
- No independent popup ordering for `lxnotify`.
  Reason: popup cycling follows `lxbar` top-level module order and role order.
- No module-local theming surface under `lxmodules.lxnotify`.
  Reason: visual knobs belong to theme keys, not per-module config.
- No generic notification history database or persistence across Awesome restarts.
  Reason: this module is an in-session inbox, not a long-term archive.
- No attempt to normalize every third-party notification action model.
  Reason: `naughty` producers are inconsistent, so the module should stay
  pragmatic and support the common cases well.
