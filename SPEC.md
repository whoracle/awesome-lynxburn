# Top-Level Roadmap

This file tracks only repo-wide planned work.

Module-specific and theme-specific plans belong in their own `SPEC.md` files and
are linked below.

## Still Wanted

### Next Session Priority Order

Doc refactoring first:
- Move all "planned features" out of the SPEC.md files. SPEC should only describe what the tool does/doesn't going forward. So a "real" SPEC
- Create a centralized ROADMAP.md - either linking to per-module ROADMAP or have one central file
- Clear out MIGRATE.md. Going forward, Assume everyone is on tag `v1.5.0`. We will only document neccessary migrations between tags, so once you detect, say, `v1.5.1`, or, more likely `v1.6.0` we do a migration pass. Usually I'd reserve those for BREAKing changes, i.e. `v2.0.0`, but we're moving fast at the moment. Once `v2.0.0` hits we'll make sure no minors will BREAK user configs. We will keep migration steps between tags in MIGRATE.md, and always assume people will migrate incrementally and not skipping steps.

Then, use this order for the next fresh session unless new bugs force a reprioritization:

1. `lxsecrets` implementation
2. `lxbar` spacing/composition polish
3. `themes/lynxburn` split / asset pruning / further ownership cleanup
4. `lxdisplay` xrandr / display-profile handling
5. future systray / non-`lx*` widget hosting in `lxbar`
6. `lxnotify` browser/web-app action hardening

Rationale:

- `lxbar` polish is useful and visible, but still lower risk than larger
  feature work
- theme cleanup is mostly structural cleanup and later-stage polish
- `lxdisplay` is useful QoL, but broader and more disruptive to test
- systray/non-`lx*` hosting stays late because it is still underspecified and
  likely to churn config surface
- `lxnotify` hardening is intentionally deferred until after more daily-driver
  time confirms whether it is a real problem

### Final Public Defaults Pass

Finish separating public defaults from local/personal values cleanly.

This still includes:

- making `config/defaults.lua` read like sane shipped defaults rather than a
  personal machine config
- keeping `config.example.lua` as an example/override file rather than a second
  defaults file
- preserving top-level `config.lua` as gitignored local machine state

Why this is top-level:

- it affects the entire user-facing config model
- it touches defaults, examples, documentation, and migration guidance together

### Documentation And Policy Polish

Add any remaining repo-wide policy/documentation notices that should exist once
the project shape is more stable.

Current candidate:

- an explicit AI-use disclaimer in the top-level docs if it still feels useful
  after the current documentation cleanup

Why this is top-level:

- it affects repository-wide documentation and expectations rather than module
  behavior

### Remaining Cross-Module Feature Work

Continue feature work only where the work clearly spans multiple modules or the
top-level config shape.

Examples of what counts here:

- features that require changes in both a module and shared popup/bar behavior
- features that change the user-facing config surface across multiple areas
- features that require coordinated updates in modules, theme, and top-level
  docs
- `lxbar` being able to host selected non-`lx*` widgets cleanly later on
- later migration of remaining `lain` widget use into repo-owned widget/module
  surfaces where that still makes sense

Module-local features should stay in module `SPEC.md` files instead.

### Final Repo-Wide Cleanup / Refactor Pass

Do one later cleanup pass after the current feature set is in place.

This pass should focus on:

- removing stale glue and dead compatibility leftovers
- pruning unused definitions in defaults/examples where they survived earlier
  refactors
- tightening module/config/theme boundaries if feature work exposed new drift

Why this is top-level:

- it is about the final shape of the repo as a whole, not one module

## Explicit Non-Goals For Now

- no generic plugin framework
  Why: this repo is still a concrete Awesome config with local modules, not a
  framework for arbitrary third-party extensions

- no broad settings-center or desktop-environment shell
  Why: the intended direction is still compact Awesome-native modules, not a
  larger control-center project

- no distro-specific one-stop installation guide yet
  Why: dependency and packaging guidance can come later, but it should not
  distort the current documentation pass

## Module And Theme SPECs

Shared/core:

- [`lxcommon`](./lxcommon/SPEC.md)
- [`lxbar`](./lxbar/SPEC.md)

Modules:

- [`lxmedia`](./lxmedia/SPEC.md)
- [`lxnotify`](./lxnotify/SPEC.md)
- [`lxnetwork`](./lxnetwork/SPEC.md)
- [`lxbluetooth`](./lxbluetooth/SPEC.md)
- [`lxpower`](./lxpower/SPEC.md)
- [`lxdisplay`](./lxdisplay/SPEC.md)
- [`lxrunner`](./lxrunner/SPEC.md)

Theme:

- [`lynxburn`](./themes/lynxburn/SPEC.md)
