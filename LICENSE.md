# Licensing

SPDX-License-Identifier: GPL-2.0-or-later

## Summary

Unless otherwise noted, the original code in this repository is licensed under
the GNU General Public License, version 2 or, at your option, any later
version.

This repository is **not** a single-uniform-license tree. It contains vendored
third-party components and inherited assets that retain their own licensing
terms.

## Original Code

The following repository-owned code is intended to be covered by
`GPL-2.0-or-later`, unless a file states otherwise:

- `rc.lua`
- `config/`
- `lxbar/`
- `lxcommon/`
- `lxbluetooth/`
- `lxdisplay/`
- `lxmedia/`
- `lxnetwork/`
- `lxnotify/`
- `lxpower/`
- `lxrunner/`
- `lxsecrets/`

This code is distributed in the hope that it will be useful, but **WITHOUT ANY
WARRANTY**; without even the implied warranty of **MERCHANTABILITY** or
**FITNESS FOR A PARTICULAR PURPOSE**.

## Third-Party Components

The following vendored components retain their upstream licenses:

- `lain/`
  Upstream ships a GPL v2 license file in [`lain/LICENSE`](./lain/LICENSE).
- `freedesktop/`
  Upstream ships a GPL v2 license file in
  [`freedesktop/LICENSE`](./freedesktop/LICENSE).
- `lxcommon/dkjson.lua`
  Vendored from David Kolf's `dkjson`; see the header in
  [`lxcommon/dkjson.lua`](./lxcommon/dkjson.lua) for upstream attribution and
  licensing terms.

These vendored components are not relicensed by this file.

## Theme And Asset Notes

The active theme tree under `themes/lynxburn/` contains a mix of original work,
older inherited Awesome theme material, and bundled image assets.

Known points to treat conservatively:

- `themes/lynxburn/theme.lua` still explicitly references a "copycats-era"
  lineage in comments
- `themes/lynxburn/icons/` contains a large set of inherited icon/image assets
- `themes/lynxburn/*.jpg` and `themes/lynxburn/*.png` wallpaper/image assets may
  have different provenance than the Lua code
- Awesome Zenburn titlebar button assets are referenced from the installed
  Awesome theme directory, not relicensed here

This file therefore does **not** claim that every asset under
`themes/lynxburn/` is newly relicensed as `GPL-2.0-or-later`.

Until a finer-grained audit is done, treat inherited or bundled non-code assets
as third-party material that keeps its existing terms where applicable.

## Additional Asset Notice

At least one vendored asset subdirectory already carries its own explicit
non-GPL notice:

- `lain/icons/openweathermap/`
  See [`lain/icons/openweathermap/README.md`](./lain/icons/openweathermap/README.md),
  which references Creative Commons BY-NC-SA 2.5 for those weather icons.

## GPL Terms

For repository-owned code covered by `GPL-2.0-or-later`, you may redistribute
and/or modify it under the terms of the GNU General Public License as published
by the Free Software Foundation, either:

- version 2 of the License, or
- at your option, any later version

The GPL v2 license text is reproduced in vendored upstream copies here:

- [`lain/LICENSE`](./lain/LICENSE)
- [`freedesktop/LICENSE`](./freedesktop/LICENSE)

If you need the SPDX form of the license text, Arch and other modern systems
also ship it as `GPL-2.0-or-later`.
