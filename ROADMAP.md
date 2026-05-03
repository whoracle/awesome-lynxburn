# Roadmap

This is the global backlog for the repo.

`SPEC.md` files describe scope and no-gos. They are not the main backlog. The
README files describe what exists today. This file is for known bugs, planned
work, ideas worth keeping around, and ideas that were considered but are not
planned.

## Priority Order

Use this order for the next fresh session unless a new bug is more urgent:

1. `lxsecrets` UX polish
2. `lxdisplay` refinements from real daily use
3. `themes/lynxburn` follow-up polish
4. `lxnotify` browser/web-app action hardening
5. `lxcommon` popup-input cleanup from real daily-driver evidence

## Known Bugs

- `lxcommon`: open `lx*` popups can still interfere with unrelated global
  shortcuts in some situations. Revisit popup input handling from concrete
  failures, not another speculative rewrite.
- `lxnotify`: right click on notifications inside a group should reliably run
  the secondary action (`dismiss`) instead of sometimes firing the primary
  action.
- `lxdisplay`: SomeWM/Wayland output layout handling is not reliable enough to
  use as the main monitor setup path yet. See [`WAYLAND.md`](./WAYLAND.md).

## Planned Features

- `lxsecrets`: define a pragmatic provider plugin API, then migrate the current
  GitLab and Vault providers onto it once the contract is stable.
- `lxsecrets`: add a secondary card action that opens the matching secret in a
  keyring UI such as Seahorse.
- `lxsecrets`: improve startup refresh behavior so the first pass waits for
  usable network availability instead of relying only on a blind timer delay.
- `lxsecrets`: evaluate a `last checked` field. If it is only session-local, it
  may be noisier than useful.
- `lxnotify`: consider auto-pausing popups while a screen share is active, if
  PipeWire or portal state provides a reliable signal without too much
  environment-specific code.
- `lxnetwork`: show wired-network state in the popup if it can stay
  display-oriented and avoid turning into a full NetworkManager frontend.
- `lxrunner`: harden notification action invocation for browser/web-app edge
  cases if daily-driving proves it worthwhile.
- repo-wide: consider a top-level `config.lua` toggle such as
  `titlebars = true` for floating-heavy setups. This needs proper titlebar
  styling, not just a boolean.
- repo-wide: consider an optional update-checker helper that compares a live
  config checkout against newer available tags and notifies the user. Keep it
  opt-in.
- theme: consider more bundled color schemes only if the UI maintenance cost
  stays reasonable. Possible candidates:
  - `gruvbox` (`dark`, `light`)
  - `dracula`
  - `everforest`
- theme: consider an opt-in startup mode that picks a random bundled color
  scheme on each Awesome start as an easter egg.

## Polish And Cleanup

- `lxsecrets`: polish popup card layout, sorting, and state presentation until
  it feels as mature as the older modules.
- `lxdisplay`: refine profile/detected-display UX only when daily use shows
  concrete friction.
- `themes/lynxburn`: normalize explicit theme keys so modules rely less on
  generic Awesome fallbacks.
- `themes/lynxburn`: review local replacement widgets for CPU, memory, load,
  filesystem, IMAP, calendar, and markup. Look for clearer thresholds, better
  failure reporting, and whether any should become proper `lx*` modules.
- `themes/lynxburn`: align popup/action button border treatment across modules.
- layout: clamp gap resizing to sane values instead of allowing negative gaps.
- layout: daily-drive `centerwork` and `centerwork.horizontal`, then polish
  focus, swap, and mouse-resize behavior if real friction appears.
- layout: treat `quake` as optional. Polish the local dropdown-terminal helper
  or drop it from defaults if it stops being useful.
- repo-wide: remove stale glue, prune dead definitions, and tighten boundaries
  after feature work settles.
- repo-wide: keep `config.example.lua` as an example/override file rather than
  a second defaults file.
- repo-wide: preserve top-level `config.lua` as gitignored local machine state.

## Considered But Not Now

- No broad settings-center or desktop-environment shell.
  This should stay a compact Awesome-native config, not a control-center
  project.
- No generic module framework.
  New `lx*` modules are fine, but the repo should not turn into an abstract
  plugin platform before real modules force that shape.
- No full `lx*` interaction contract for `custom:<name>` bar widgets.
  Custom widgets stay simple: no popup cycling, no implicit module behavior, and
  explicit `style = "lxbar" | "raw"` visual ownership.
- No speculative popup-input rewrite.
  Popup input still matters, but changes should come from concrete failures and
  should preserve the X11 path.
- No large batch of color schemes without UI review.
  Each scheme needs enough theme keys to look intentional across modules.

## Future Modules

### `lxsession`

Possible declarative session manager for restoring/switching named desktop
profiles. The main idea is to treat a session as desired desktop state:

- snapshot the current desktop into a rough profile
- restore/switch to named profiles such as `work`, `gaming`, or `writing`
- move existing matching clients to the configured screen/tag/geometry
- spawn missing clients from configured commands
- park, minimize, ignore, or close unrelated clients based on profile policy

This is not full application-state restore. Apps keep owning their own tabs,
documents, and internal state. `lxsession` would only manage invocation,
placement, tags, screens, and window state.

Optional later scope:

- UI picker through `lxbar`
- session/power actions if those still do not have a better home
- titlebar/floating-session helpers

Keep this narrow. It should not become a general settings center or promise
exact application-state restore.

### `lxmenu`

Possible broader menu module if `lxsession` is too narrow:

- session/power actions
- maybe a small app or command menu

This should stay late until the scope is clearer.

### `lxsnippets`

Back-of-the-napkin idea:

- expose text snippets from a git-backed snippets folder
- make snippets easy to copy into the clipboard
- maybe keep a small clipboard-paste history

### `lxupdate`

Back-of-the-napkin idea:

- notify about available Arch Linux updates through `pacman` / `yay`
- possibly make package-manager backends modular for other distros
- maybe check upstream security trackers and highlight high/critical fixes
