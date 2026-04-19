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

### Repository Scaffolding

Add the lightweight repository scaffolding needed for more disciplined future
work.

Current likely scope:

- `editorconfig`
- `pre-commit`
- commit-message tooling if it still feels worth the added friction
- a top-level `CHANGELOG` once the scaffolding around change tracking is in
  place

Why this is top-level:

- it affects the repository workflow rather than one module

### Documentation And Policy Polish

Add any remaining repo-wide policy/documentation notices that should exist once
the project shape is more stable.

Current candidate:

- an explicit AI-use disclaimer in the top-level docs if it still feels useful
  after the current documentation cleanup
- a future `CHANGELOG` policy once release/versioning expectations are clearer

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
- shared visual polish such as smoother/delayed compact bar behavior across
  modules like `lxmedia` and `lxdisplay`
- dependency pre-flight checks with graceful fallback and user-visible failure
  handling where that improves startup/runtime behavior

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
