# Top-Level Roadmap

This file tracks only repo-wide planned work.

Module-specific and theme-specific plans belong in their own `SPEC.md` files and
are linked below.

## Still Wanted

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

### Final Documentation Pass

Finish the repository-wide docs so they match the current code shape.

This includes:

- top-level docs staying aligned with the current config/bootstrap flow
- module and theme docs staying aligned with the current split files
- removing stale historical wording from user-facing documentation

Why this is top-level:

- it affects the full repo rather than one module

### Remaining Cross-Module Feature Work

Continue feature work only where the work clearly spans multiple modules or the
top-level config shape.

Examples of what counts here:

- features that require changes in both a module and shared popup/bar behavior
- features that change the user-facing config surface across multiple areas
- features that require coordinated updates in modules, theme, and top-level
  docs

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
