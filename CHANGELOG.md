## v1.4.0 (2026-04-20)

### Features

- [lxdisplay] auto-apply startup profiles with default validation and panic fallback
- [lxdisplay] make display popup opt-in via configured profiles
- [lxdisplay] add xrandr profiles and transient display popup control

### Bug Fixes

- [lxdisplay] quiet profile state tags and confirm old xrandr script is unused
- [lxdisplay] refine popup hierarchy and keyboard-target detect action
- [lxdisplay] clean up popup selection state and profile card presentation
- [lxdisplay] allow left-click brightness changes on compact bar
- [theme] widen lxdisplay compact bar end margin to match lxmedia
- [theme] add explicit compact bar end padding for display and media
- [theme] match lxdisplay compact bar width to lxmedia
- [theme] align display and media compact bar edge spacing

### Documentation

- [lxdisplay] finalize profile tag rendering and align remaining-work docs

## v1.3.0 (2026-04-20)

### Features

- [lxnetwork] add dedicated disabled wifi glyph for widget state

### Bug Fixes

- [theme] increase top-level icon presence for smaller lxmodule glyphs
- [theme] align lxbar horizontal shell with other panel widgets
- [lxpower] remove hidden top-level spacing when compact label is absent
- [lxpower] collapse empty compact label to remove trailing gap
- [lxbar] align widget hover and outer spacing with wibar surface
- [core] normalize top-level widget width and hidden bar spacing
- [core] remove glyph and hidden-spacing bias from top-level widgets
- [lxnetwork] make vpn state override widget color consistently
- [lxcommon] stop treating anchor geometry as popup options
- [lxcommon] sync popup hover with keyboard selection state

### Refactors

- [core] remove widget-local horizontal padding from top-level modules
- [core] remove widget-local vertical padding from top-level modules

### Documentation

- [core] note glyph-capable font requirement in user README

### Chores

- [theme] tweak lxnotify icon width
- [theme] adjust icon sizes to their final size
- [theme] adjust icon sizes some more
- [theme] adjust icon sizes

## v1.2.0 (2026-04-19)

### Features

- [lxbluetooth] improve popup readability and device row hierarchy
- [lxnetwork] improve popup row readability and network metadata display
- [lxrunner] show unobtrusive timestamps for history rows

### Bug Fixes

- [lxrunner] revert history timestamp row metadata
- [lxbluetooth] remove false dependency from preflight checks
- [lxrunner] make timestamp more unobtrusive and aligned correctly

### Refactors

- [lxcommon] centralize shared popup controller session logic

### Documentation

- [core] remove completed roadmap items from markdown todos
- [core] record next-session priorities and update lxcommon popup docs
- [core] drop completed network and bluetooth readability work from specs

## v1.1.0 (2026-04-19)

### Features

- [core] scope preflight checks to enabled modules and defer lain
- [core] refine preflight inventory around local overrides and bluez
- [core] add grouped startup preflight checks for missing dependencies
- [theme] shorten compact bar hover reveal delay to 0.5s
- [core] delay compact bar hover reveal for media and display widgets

### Refactors

- [lxmedia] drop wpctl and treat media tooling as required dependencies

### Documentation

- [core] document startup preflight checks across top-level and module docs

## v1.0.0 (2026-04-19)

### Features

- [core] apply flat config.lua theme overrides onto beautiful after theme load
- [lxrunner] add glyph-based alias decorations alongside image icons
- [lxrunner] support per-alias icons in launcher results and history
- [core] centralize rule overrides and remove legacy config override loaders
- [core] add top-level lxrunner alias config and sync handoff docs
- [core] add top-level key override support in config.lua
- [core] make top-level config.lua the central user config entrypoint
- [core] centralize static settings through shared config data
- [core] add central theme selection config path
- [core] add central defaults and loader for command config
- [core] add central defaults and loader for widget config
- [lxbar] add declarative widget ordering with fallback to registry order
- [lxrunner] save whole last run command instead of command search in lxrunner
- [lxprofile] make profile visible by toplevel icon, drop dGPU indication in toplevel
- [lxnetwork] show current WIFI strength
- [lxnetwork] deduplicate currently connected network
- [lxnetwork] colors
- [lxpowersave] add dGPU indication
- [theme] space icons a bit
- [lxbluetooth] close when opening bluetooth-manager
- [lxpowersave] polish
- [lxpowerprofiles] initial implementation
- [lxnetwork] initial implementation
- [lxbluetooth] initial implementation
- [lxrunner] increase history item count
- [lxaudio] do not block XF86 Media keys
- [lxnotify] add click-outside-to-dismiss functionality
- [lxaudio] add click-outside-to-dismiss functionality
- [lxaudio] change around layout of volume and mic bar some more
- [lxaudio] change around layout of volume and mic bar
- [lxaudio] allow scrolling on mic volume bar
- [lxaudio] add microphone volume bar with mouse controls to media popup
- [lxaudio] clickable volume bars and cap volume at 100%

### Bug Fixes

- [lxrunner] restore the missing awful import in history actions
- [lxnotify] restore the missing util import in popup construction
- [lxdisplay] use the local helper clamp after the theme split
- [lxpower] restore shared popup toggle wiring for cycle navigation
- [core] make lynxburn mail widget optional when IMAP config is unset
- [core] handle missing popup control options during outside-click teardown
- [lxmedia] terminate pactl subscribe listeners on awesome reload
- [core] restore per-screen tag layout cycling instead of global layout rotation
- [core] prevent empty override tables from wiping central config sections
- [lxnotify] enter actions, toplevel dismiss
- [lxnotify] try to make right dismiss instead of action
- [lxnotify] also tint notify icon red if naughty is suspended and we catch a new notification
- [lxnetwork] wifi icon fixed width 2
- [lxnetwork] wifi icon fixed width
- [theme] remove spacers again
- [lxpowersave] powersave profile
- [lxpowersave] fix profile indication
- [lxnetwork] add wifi generation to distinguish same-name WIFIs
- [lxnetwork] clear wifi list on fresh scan
- [lxnotify] fix teardown race condition
- [lxaudio] fix teardown race condition
- [lxaudio] mic volume scroll changed audio volume, too
- [lxaudio] set corret volume
- [lxaudio] handle media keys correctly in media popup

### Refactors

- [core] drop unused browser key from tracked config surface
- [core] tighten shipped defaults and example config surface
- [core] consolidate config data loading and finish the bootstrap cleanup sweep
- [core] split tag and screen config helpers into focused modules
- [core] split key binding compilation, actions, and tag wiring
- [core] split service bootstrap helpers and initialize lx services after theme setup
- [lxrunner] split init.lua into a maintainable structure
- [lxdisplay] split brightness, redshift, helpers and theming into separate files
- [lxmedia] split runtime and popup orchestration out of init and fix shared popup helper boundaries
- [lxbluetooth] split bluetooth state, popup rendering and controller flow into focused modules
- [core] consolidate generic popup, screen and shell helpers under lxcommon
- [lxpower] split power state, popup rendering and controller flow into focused modules
- [lxnetwork] split wifi state, popup flow and password prompt into focused modules
- [lxnotify] split inbox state, popup control and theming into focused modules
- [core] tighten lxcommon and lxbar surfaces and add module docs
- [core] prune verified-unused config definitions from defaults and local overrides
- [core] split local config overrides from tracked defaults and examples
- [core] remove legacy theme key compatibility after lx surface cleanup
- [lxnotify] rename card hover styling to semantic theme keys
- [lxnotify] rename popup selection styling from selected_border to selected_bg
- [core] normalize lx widget hover and press theme keys across modules
- [core] remove dead lxdisplay and lxnotify theme surface during config sweep
- [core] remove legacy theme fallbacks for lxrunner sizing and lxdisplay polling
- [core] collapse popup placement to center-or-side with lxbar-owned side selection
- [core] centralize lxmodule widget feedback sync in lxcommon
- [core] centralize popup keygrabber lifecycle across lxmodules
- [core] centralize popup keyboard contracts across lxmodules
- [core] reuse shared lxcommon popup control helpers across all lxmodules
- [core] centralize shared popup control plumbing in lxcommon and reuse it across lxmodules
- [core] move shared popup row and feedback helpers from lxmedia into lxcommon
- [core] replace lynxburn theme.lua with the streamlined single-file theme and remove theme2
- [core] rename lxaudio and lxpowerprofiles modules to lxmedia and lxpower end-to-end
- [lxpowerprofiles] centralize preferred AC and battery profiles under lxmodules config
- [core] rename keybinding command group labels away from legacy programs wording
- [core] align runtime naming and docs with centralized commands and lxmodules config
- [core] rename widget config helper to lxmodules and drop stale widgets module
- [core] move bar and module config under lxmodules with lxbar-owned composition
- [core] return timeout controls to theme-owned module presentation
- [lxdisplay] move brightness and redshift config into display module settings
- [core] move lxnotify behavior limits and popup timing into centralized module config
- [core] centralize lxaudio and lxdisplay behavior options under widget module config
- [core] remove settings and programs wrappers from the active runtime path
- [core] split runtime-derived values out of config settings
- [core] move terminal resolution into central command loading
- [core] move lxrunner under lxmodules and centralize lain imap secret config
- [core] centralize more lx module and runner options in config
- [core] centralize lx module service options in widget config
- [core] fold tag order and per-screen tag layouts into screens config
- [core] centralize tag config and drop workspace naming
- [core] reshape keybindings around stable action IDs and flat config entries
- [core] centralize default keybindings into the shared config layer
- [core] retire split override runtime in favor of central config.lua
- [core] extract widget config resolution into config.widgets
- [core] inject widget order into registry from config services
- [core] flatten widget settings into per-module config
- [lxbar] group popup cycle config under widgets settings
- [core] extract shared popup adapter wiring from config services
- [core] unify popup routing around semantic roles and lxbar-ordered cycling
- [lxaudio] add keyboard navigaion to media popup
- [lxaudio] reorderr devices popup

### Documentation

- [core] finalize top-level docs and migration notes
- [core] more housekeeping
- [core] finalize top-level documentation links and consistency
- [core] add concise contributor guidance for scope, verification, and licensing
- [core] tighten migration notes and fold refactor leftovers into the theme spec
- [core] add mixed-license notice with GPL-2.0-or-later for original code
- [core] rewrite SPEC as a top-level roadmap and spec index
- [core] add development notes for config flow, existing modules, and keybinding work
- [core] rewrite README as user-facing setup and config guide
- [theme] add README and SPEC for the lynxburn theme
- [core] restore forward-looking implementation detail in SPEC
- [core] rewrite planning docs around remaining work and current config shape
- [core] note future theme structure and palette split in refactor follow-ups
- [core] define flat theme override scope and advertise common user-facing theme keys
- [core] align config and module docs with media/power renames and flat theme overrides
- [core] add notebook migration checklist for lxmodules and display config reshape
- [core] narrow migration notes to remaining live rules override
- [core] add override migration notes for top-level config.lua - desktop
- [lxdisplay] update SPEC
- [lxrunner] update SPEC
- [lxnotify] update README
- [lxaudio] update README

### Chores

- [core] commitizen
- [core] switch lua pre-commit checks to luacheck
- [theme] rename all occurences of lynxburn2 to lynxburn
- [core] delete legacy overrides directory and contents
- [core] migrate live override data into top-level config.lua
