# lxnotify SPEC

## Planned

- Keep `lxnotify` as the retained notification inbox for this config, not a
  full replacement for every live `naughty` popup behavior.
- Preserve the current split between:
  - daemon suspension (`naughty.suspended`)
  - inbox interception pause
- Keep grouped notification handling, keyboard navigation, popup cycling
  participation, and action invocation as first-class features.
- Continue shrinking `init.lua` into a thin constructor/public entry point,
  with state, popup control, and rendering concerns split into dedicated files.
- Reduce duplicated popup/session behavior where it can move into `lxcommon`
  without making `lxcommon` notification-specific.
- Keep the popup model compact:
  - top-level grouped inbox
  - per-group detail view
  - no separate alternate popup variants
- Harden notification action invocation for browser/web-app cases where client
  matching and action objects are less predictable.
- Keep denylist-driven filtering configurable from `lxmodules.lxnotify`.

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
