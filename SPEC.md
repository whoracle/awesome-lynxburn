# Top-Level Spec

This file describes repo-wide scope and explicit non-goals.

Planned work lives in [`ROADMAP.md`](./ROADMAP.md).

## Scope

- this repo is a concrete AwesomeWM configuration with repo-owned `lx*`
  modules, shared popup/bar infrastructure, and a bundled theme package
- user-facing configuration lives in top-level `config.lua` and tracked shipped
  defaults/examples
- shared behavior such as popup cycling, popup-role routing, and bar ordering
  is repo-wide contract, not ad-hoc per-module behavior
- module-specific scope belongs in the respective module `SPEC.md` files

## Explicit Non-Goals For Now

- no generic plugin framework for the whole repo
  Why: this repo is still a concrete Awesome config with local modules, not a
  framework for arbitrary third-party extensions

- no broad settings-center or desktop-environment shell
  Why: the intended direction is still compact Awesome-native modules, not a
  larger control-center project

- no distro-specific one-stop installation guide yet
  Why: dependency and packaging guidance can come later, but it should not
  distort the current documentation pass

## Module And Theme SPECs

Planned work for these components belongs in [`ROADMAP.md`](./ROADMAP.md).

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
- [`lxsecrets`](./lxsecrets/SPEC.md)

Theme:

- [`lynxburn`](./themes/lynxburn/SPEC.md)
