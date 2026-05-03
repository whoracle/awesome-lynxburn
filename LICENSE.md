# Licensing

SPDX-License-Identifier: GPL-2.0-or-later

## Summary

Unless otherwise noted, this repository is licensed under the GNU General
Public License, version 2 or, at your option, any later version.

Third-party code and inherited assets called out below keep their own terms.

## What This Means

In short:

- this repository is `GPL-2.0-or-later` unless specifically stated otherwise
- bundled third-party code keeps its original license
- inherited theme assets keep their original terms where known
- unclear assets are documented as best-effort provenance notes, not relicensed
- there is no warranty

## Third-Party Components

The following third-party components retain their upstream licenses:

- `lxcommon/dkjson.lua`
  Vendored from David Kolf's `dkjson`; see the header in
  [`lxcommon/dkjson.lua`](./lxcommon/dkjson.lua) for upstream attribution and
  licensing terms.

These third-party components are not relicensed by this file.

## Third-Party Assets

The active theme tree under `themes/lynxburn/` contains a mix of original work
and a small number of inherited non-code assets. This file does not relicense
those inherited assets.

- `themes/lynxburn/icons/square_sel.png` and
  `themes/lynxburn/icons/square_unsel.png`
  These taglist square assets are inherited from the Awesome Copycats lineage,
  now maintained as [`lcpz/awesome-copycats`](https://github.com/lcpz/awesome-copycats).
  The upstream project credits Luca CPZ and lists its theme assets under a
  Creative Commons ShareAlike license.
- Awesome Zenburn titlebar button assets are referenced from the installed
  Awesome theme directory, not relicensed here.
- Bundled default wallpaper, historically known as `dwallpaper`
  This wallpaper was previously distributed as `Terraform Green` /
  `Terraform-green.jpg` in GNOME backgrounds. Public GNOME history shows it was
  still present until a November 2017 cleanup removed it from the active
  background set. Older public references also describe it as part of the
  official GNOME backgrounds around the GNOME 3.2 era. Clear original
  authorship/licensing attribution has not been pinned down here. If someone
  has clean attribution for this asset, a PR is welcome.

Treat inherited or bundled non-code assets as third-party material that keeps
its existing terms where applicable.

## GPL Terms

For repository contents covered by `GPL-2.0-or-later`, you may redistribute
and/or modify it under the terms of the GNU General Public License as published
by the Free Software Foundation, either:

- version 2 of the License, or
- at your option, any later version

If you need the SPDX form of the license text, Arch and other modern systems
also ship it as `GPL-2.0-or-later`.
