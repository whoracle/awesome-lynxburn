## v1.12.0 (2026-05-07)

### Features

- [lxrunner] add fuzzy result matching

### Bug Fixes

- [lxdisplay] tolerate xrandr rate rounding
- [lxdisplay] parse xrandr rotation state
- [lxdisplay] add profile tracing debug mode
- [core] align calendar weekday spacing
- [core] align calendar weekday headers
- [core] preserve calendar row line breaks
- [core] allow nested widget markup

### Documentation

- [lxdisplay] document startup profile matching
- [core] add lxswitcher roadmap idea
- [core] add screenshots

### Chores

- [core] allow release commit markers
- [core] add some stuff to gitignore

## v1.11.0 (2026-05-03)

### Features

- [core] add shared keyboard layout config for awesome and somewm
- [somewm] add basic platform detection and split defaults

### Bug Fixes

- [core] close active popup from mouse terminal binding
- [somewm] recover visible popup state during cycling
- [somewm] handle popup cycle keys before raw key actions
- [somewm] keep popup cycling state deterministic
- [somewm] harden popup root key compatibility
- [core] make registered popup opens idempotent
- [somewm] refresh compatibility preflight and docs
- [somewm] add startup delay to profile application
- [somewm] apply lxdisplay profiles as one atomic wlr-randr command
- [somewm] retry lxdisplay applies without explicit rates and fix root button handling
- [somewm] restore popup compatibility and map lxdisplay relations to wlr-randr

### Refactors

- [core] centralize popup keyboard input ownership
- [core] lazy-load x11 and somewm paths to satisfy somewm compatibility checks
- [lxdisplay] split x11 and somewm display backends

### Documentation

- [core] Update MIGRATE.md and prepare for v1.11.0 release
- [core] align module docs with current architecture
- [core] add wayland and somewm migration plan
- [core] document architecture and starter config

## v1.10.0 (2026-05-02)

### Features

- [core] add third-party layout registration
- [lxrunner] launch result rows on left click
- [lxmedia] defer heavy popup data collection
- [core] try out ai-review against local ollama

### Bug Fixes

- [core] keep hidden quake terminal hidden on reload
- [lxcommon] clear popup feedback during shared-session cycling
- [lxcommon] bind default popup actions to instance

### Refactors

- [core] remove lain dependency
- [core] replace lain widget helpers locally
- [core] restore lain as git submodule
- [theme] replace legacy widget PNGs with glyph icons
- [lxcommon] centralize popup input ownership
- [lxrunner] store alias history by identity
- [lxrunner] store launch history as JSON

### Documentation

- [core] finalize v1.10.0 migration notes
- [core] clean up release documentation
- [core] remove stale submodule quickstart step
- [core] document layout ownership plan
- [theme] clarify remaining asset attribution
- [core] clarify post-v1.9.0 migration bucket
- [lxrunner] document JSON history migration
- [core] remove completed popup latency follow-ups
- [lxsecrets] add roadmap item
- [core] describe lxmodules in README
- [core] change baseline assumption in MIGRATE.md
- [core] add `lxsession` SPEC for later implementation

### Chores

- [core] remove unused freedesktop vendor tree

## v1.9.0 (2026-04-27)

### Features

- [lxcommon] avoid close sweep during shared popup cycling
- [lxcommon] migrate media and notify popups to shared session
- [lxcommon] introduce shared popup session for generic modules
- [lxbar] allow showing the bar only on selected configured screens
- [lxsecrets] bootstrap managed gitlab PATs from the admin selector when missing

### Bug Fixes

- [lxcommon] preserve global shortcuts in popup keygrabbers
- [lxdisplay] restore top-level widget highlight during popup cycling
- [lxsecrets] ignore empty gitlab selector overrides and fall back to canonical selectors
- [lxsecrets] include failing secret-tool operation context in provider errors
- [lxsecrets] skip gitlab bootstrap stores when admin and managed selectors are identical
- [lxsecrets] only write expiry metadata when storing replacement secret values
- [lxsecrets] wait for keyring record removal before writing expiry metadata replacements
- [lxsecrets] replace matching keyring records instead of duplicating on expiry metadata writeback

### Refactors

- [lxcommon] track active popup deterministically
- [lxcommon] use named popup descriptors everywhere
- [lxcommon] remove legacy popup shell lifecycle

### Documentation

- [core] prepare migration notes for v1.9.0
- [core] note popup latency follow-ups for media and secrets
- [core] drop compact bar easing follow-up
- [core] note future titlebar toggle and styling work in roadmap
- [core] fix stray ` in README.md

## v1.8.0 (2026-04-24)

### Features

- [lxbar] host custom bar widgets and migrate systray out of the theme shell
- [theme] add more themes
- [theme] add color sceme `solarized_dark`
- [theme] add color sceme `kanagawa_wave`
- [theme] add color sceme `kanagawa_lotus`
- [theme] add color sceme `kanagawa_dragon`
- [lxrunner] let aliases trigger targeted lxmodule refreshes after launch
- [core] forward non-popup keys from popup grabbers to global bindings
- [theme] fall back to a flat theme wallpaper color when the configured image is invalid
- [theme] notify on unknown color schemes and fall back to lynxburn
- [theme] add color scheme `solarized_light`
- [theme] add color scheme `catpuccin`
- [theme] rename/move default palette to `lynxburn`
- [theme] add color scheme `zenburn`

### Bug Fixes

- [lxbar] fix eager lain metric callbacks in migrated custom widgets
- [lxbar] make custom widget registration non-fatal and harden bar-shell wrapping
- [lxbar] avoid recursive config loading in the imap custom widget
- [lxrunner] add delayed follow-up refresh for alias notify hooks
- [lxsecrets] delay startup refresh runs to avoid session bring-up races
- [lxsecrets] replace keyring entries when writing expiry metadata
- [core] restore popup keyboard handling on mouse open and re-dispatch global shortcuts safely
- [core] close active popups before running forwarded global shortcuts

### Refactors

- [lxbar] migrate the remaining lain metric widgets into custom bar widgets
- [lxbar] migrate the lain imap widget into custom bar widgets
- [lxbar] add explicit custom widget styling modes and host systray raw
- [core] tighten shipped defaults and move richer examples into config.example.lua
- [lxsecrets] make periodic refresh opt-in by default
- [lxsecrets] make selectors the canonical managed gitlab token selector

### Documentation

- [core] update migration notes and docs for lxbar custom widget hosting in v1.8.0
- [core] note pipewire and portal based screen-share autopause idea for lxnotify
- [core] record daily-driver bugs and follow-up ideas in roadmap
- [theme] document all color schemes

## v1.7.0 (2026-04-24)

### Features

- [theme] add a bundled nord color scheme and refresh stale roadmap/docs
- [lxdisplay] include refresh rate in startup profile match check

### Bug Fixes

- [theme] raise nord panel text contrast for tasklist and clock widgets
- [theme] restore plain tasklist labels in lynxburn
- [lxsecrets] align popup button styling and restore secondary keyboard action
- [core] fix bluetooth popup helper regression and media popup transport refresh
- [lxsecrets] restore neutral card body under full-card selection border
- [lxdisplay] skip startup profile apply when xrandr state already matches
- [lxsecrets] include action buttons inside the selected card border
- [lxsecrets] separate login button clicks from card refresh and sort attention first
- [lxsecrets] only export explicit browser overrides for vault login
- [lxrunner] sort empty history by invocation count before recency

### Refactors

- [lxsecrets] collapse per-secret actions into one stateful primary flow
- [lxsecrets] align popup primary and secondary actions with the interaction contract
- [lxdisplay] align widget and popup interactions while preserving bar brightness clicks
- [lxpower] align top-level and popup interactions with primary and secondary actions
- [lxnetwork] align top-level clicks and README with interaction contract
- [lxnotify] align card interactions with primary and secondary action semantics
- [lxmedia] align top-level and popup interactions with primary and secondary actions

### Documentation

- [core] record that no migration is required from v1.6.0 to v1.7.0
- [core] note future lxrunner mouse-launch support in roadmap
- [lxrunner] document current keyboard-first interaction model explicitly
- [lxbluetooth] document popup mouse and keyboard interaction semantics
- [lxsecrets] record partial card-border selection as known issue

## v1.6.0 (2026-04-23)

### Features

- [lxrunner] track invocation counts and use them in history ranking
- [lxsecrets] add first-pass secret refresh module with popup and provider runners
- [lxsecrets] add lxsecrets example and SPEC
- [lxrunner] also scan user XDG_DATA_DIR for .desktop files

### Bug Fixes

- [lxmedia] collapse hidden mic spacing in top-level widget row
- [lxmedia] fully collapse hidden top-level bar width to recenter icon
- [lxmedia] remove fixed device card heights and unsqueeze selectable rows
- [lxmedia] add vertical breathing room to devices popup row cards
- [lxsecrets] give action buttons a dedicated idle background
- [lxsecrets] keep secret card hover border-only to preserve button contrast
- [lxsecrets] match secret card selection structure to lxdisplay profiles
- [lxsecrets] match card hover layering and batch refreshes by vpn
- [lxsecrets] reduce secret card selection border thickness
- [lxsecrets] match secret card selection layering to lxdisplay profiles
- [lxsecrets] render hover selection as border instead of filled card
- [lxsecrets] default vault login to ambient browser resolution unless overridden
- [lxsecrets] complete interactive vault login flow and manage vpn ownership across auth
- [lxsecrets] split auth row click handling and keep vpn up for login-required refreshes
- [lxsecrets] make inline vault login action inside auth-needed cards clickable
- [lxsecrets] render vault login action as explicit inline auth-needed card row
- [lxsecrets] surface per-card vault login action after auth-needed refresh
- [core] fix shell escaping for single quotes in async commands
- [lxsecrets] show inline vault login action only when refresh requires auth
- [lxsecrets] make vpn-gated refresh fail fast without interactive nmcli
- [lxmedia] handle escape and cycle keys in devices popup modeÄ

### Refactors

- [theme] drop dead lynxburn keys and prune unused theme assets
- [lxmedia] add shared hover and keyboard selection to devices popup
- [core] align bluetooth network and power popup cards with lxdisplay
- [theme] normalize popup accents, text colors, and button backgrounds
- [theme] split lynxburn structure from swappable color schemes
- [core] vendor json support in lxcommon instead of depending on lain
- [lxsecrets] align card styling and sort secrets by vpn and expiry
- [lxsecrets] simplify secret cards around expiry badges and real action buttons
- [lxsecrets] replace shell refresh backends with native provider runtime
- [core] use explicit lxmodule ids in lxbar module config keys
- [core] use explicit lxmodule ids in lxbar order config
- [core] use explicit lxmodule ids in lxbar order config
- [lxnetwork] wrap popup entries in card-style selectable rows
- [core] restyle lxbluetooth and lxmedia device rows around popup cards

### Documentation

- [core] note lxsecrets startup delay and lxdisplay no-op profile apply ideas
- [core] refresh roadmap and migration notes for v1.6.0
- [theme] document lynxburn widget ownership and normalize remaining media theme keys
- [core] add optional git-tag update checker to roadmap
- [core] update docs for native lxsecrets runtime and vendored dkjson
- [core] record popup input and theme button-border follow-up work
- [core] split specs from roadmap and reset migration policy
- [core] update SPEC.md
- [core] update SPEC.md
- [core] Document behaviour of MIGRATE.md going forward
- [core] some more notes in SPEC
- [core] document secret-tool usage
- [lxmedia] add known issues and further todos to lxmedia and lxrunner

## v1.5.0 (2026-04-21)

### Features

- [lxdisplay] support optional profile outputs with initial state control
- [lxdisplay] render profile topology as compact bracketed spatial summaries
- [lxdisplay] support friendly output names in profile summaries

### Bug Fixes

- [lxdisplay] use explicit optional-output color for disabled profile displays
- [lxdisplay] restore stable spatial profile layout for optional outputs
- [lxdisplay] preserve spatial layout alignment in colored optional output markup
- [lxdisplay] render optional display layout from structured spatial rows
- [lxdisplay] restore spatial summary as primary layout line for optional outputs
- [lxdisplay] track optional output runtime state and toggle via single-output xrandr calls
- [lxdisplay] restore bracket summary line and color optional-off outputs red
- [lxdisplay] restore spatial layout summaries for pos-based profiles

### Documentation

- [lxdisplay] document optional output rendering and theme color key

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
