# lxrunner Spec

## Goal

`lxrunner` is a small AwesomeWM-native program launcher in the spirit of Rofi, but with a deliberately narrower scope and with visuals that match the rest of this config and theme.

It should feel like a first-class part of this Awesome setup rather than a generic external launcher.

## Initial Scope

The first implementation should focus on:

- launching commands found in `$PATH`
- supporting lxrunner-specific aliases
- searching `.desktop` entries by display name
- showing a compact launcher UI with:
  - an input field
  - a short history list under the input
  - a filtered result list while typing
- pulling colors, spacing, and general look from the Awesome theme

The first version should keep `.desktop` handling narrow: name search only, no
metadata/category search, and no alternate search mode.

## Non-Goals For V1

The following are explicitly out of scope for the first version:

- alternate search mode triggered by `Alt`
- fuzzy scoring sophistication beyond what is needed for a good basic match
- plugin architecture
- shell completion parity with Rofi
- window switching

## Core Behavior

### Input and Matching

The launcher opens as a box with a text input at the top.

Below the input:

- when the input is empty, show recent command history
- when the user types, show matching results

Matching should search:

- executable names available in `$PATH`
- lxrunner alias names
- `.desktop` entry names

For V1, all sources are searched in the same default mode.

### Search Semantics

The initial matching behavior should be practical and predictable, not overly clever.

Recommended matching order for V1:

1. exact prefix matches
2. substring matches
3. optionally simple token/word matches if easy to support cleanly

The launcher should prioritize responsiveness and understandable results over advanced fuzzy logic.

### Launch Behavior

When the user confirms a result:

- if it is a PATH command, execute it
- if it is an lxrunner alias, execute the alias target command
- if it is a desktop entry, execute its `Exec` command

The launcher should then close.

## History

The launcher should maintain a short history of recent launches.

Requirements:

- store the last 5 launched entries
- show those entries below the input when the input is empty
- selecting a history item launches it again
- aliases and normal commands should both be eligible for history

Open question for implementation:

- history should be persisted locally across sessions, not kept only in memory

History storage requirements:

- persist in a file in `$HOME`
- default file path: `~/.lxrunner_history`
- history size limit should be configurable
- each history entry should include:
  - launched name
  - launch command
  - last used timestamp

The timestamp is not required to be displayed in V1, but it should be stored so it can be used later.

## Aliases

lxrunner should support a small set of custom launcher aliases so the launcher can expose useful commands without requiring scripts or binaries in `$PATH`.

Examples:

- `vpntoggle`
- `vivaldi google.com`
- other short convenience commands defined by the user later

Requirements:

- aliases are part of lxrunner’s own configuration/data
- alias names are searchable exactly like normal commands
- aliases should support plain one-shot command execution
- aliases should also support argument-aware expansion
- alias matches should appear naturally in the same result list as PATH commands

Alias categories for V1:

1. shell aliases

These run an arbitrary shell command or script body.

Example use case:

- `vpntoggle`

This is intended for short convenience actions that would otherwise require creating a separate script in `$PATH`.

2. template aliases

These expand user input into a command template.

Example use case:

- typing `vivaldi google.com`
- alias template expands to something like `/usr/bin/vivaldi %s`

Recommended behavior:

- if the alias is declared as templated, the text after the alias name is passed into the template
- `%s` is the placeholder for the raw argument tail
- if no argument tail is present, the template alias may still run if that makes sense for the configured command

Recommended initial data shape:

- alias name
- alias type
- command string or template
- optional environment variable table
- optional description for later display

Suggested examples:

- `{ name = "vpntoggle", type = "shell", command = "..." }`
- `{ name = "vivaldi", type = "template", command = "/usr/bin/vivaldi %s" }`
- `{ name = "vault", type = "template", command = "vault kv list %s", env = { VAULT_URL = "https://some.vault.com" } }`

Execution rules:

- shell aliases should run through the shell
- template aliases should substitute the argument tail into the configured template and then execute the resulting command
- aliases may define an `env` table; those variables should be exported only for that spawned command by prefixing the shell command with `KEY=value`
- if a template alias is invoked with no placeholder in the template, it should just execute the configured command directly
- alias failures should not crash Awesome

## UI Requirements

### Visual Direction

The launcher should visually match the existing Awesome theme.

That means:

- use colors from `beautiful`
- use theme fonts where appropriate
- use theme spacing and border styling where practical
- avoid looking like a separate foreign tool

It should feel coherent with:

- the wibar
- existing notification styling
- the custom widgets already in this config

### Layout

The launcher UI should be a popup-like box with:

1. input field on top
2. history or result list beneath it

Recommended layout characteristics:

- compact
- centered on screen
- keyboard-first
- readable without excessive ornament

### Result Presentation

Each result row should be simple and easy to scan.

For V1, each row only needs:

- displayed command or alias name

Optional for later:

- description
- source indicator such as `PATH` or `alias`

## Keyboard Interaction

The launcher should be fully usable from the keyboard.

Required behavior:

- open via an Awesome keybinding later
- type to filter
- `Enter` launches the selected entry
- `Escape` closes the launcher
- arrow keys move selection up and down

Optional but desirable if simple:

- `Tab` to accept the highlighted entry
- `Ctrl+j` / `Ctrl+k` style movement only if it does not complicate the implementation

## Data Sources

### PATH Commands

V1 should discover executable commands from `$PATH`.

Requirements:

- collect executable names from all PATH directories
- deduplicate entries if the same executable name appears multiple times
- present commands by executable name, not full path

Recommended behavior:

- cache the discovered list when the launcher opens
- do not rebuild the PATH list on every keystroke

### Desktop Entries

Desktop entries are part of the default search set.

Requirements:

- collect `.desktop` launchers from common XDG application directories
- search by launcher `Name` only
- ignore hidden and `NoDisplay=true` entries
- execute the resolved `Exec` command when launched

Still out of scope:

- metadata/category/comment search
- alternate Alt-driven source switching

## Theme Integration

`lxrunner` should pull its visual settings from the Awesome theme.

Expected theme-driven values:

- background color
- foreground color
- selected row background/foreground
- border color and width
- font
- popup width
- row height / spacing

If new theme keys are needed, they should be added in a way consistent with the existing theme naming style.

## Module Shape

`lxrunner` should be implemented as a standalone local module in the `lxrunner/` folder.

Recommended structure for implementation:

- one entry module users can `require`
- internal helpers for:
  - command discovery
  - alias management
  - history persistence
  - UI/popup rendering

The implementation should stay lean and avoid unnecessary abstraction.

## Suggested V1 API

Exact naming can change, but the module should probably expose an instance-based API similar to the other local widgets/modules.

A reasonable shape would be:

- `lxrunner.new(opts)`
- `instance:show()`
- `instance:hide()`
- `instance:toggle()`

Possible config options:

- history size
- popup width
- prompt text

The alias definition format should be simple and hand-editable.

Aliases should **not** be passed inline when creating the lxrunner instance.

Instead, aliases should be loaded from a dedicated local config file, similar in spirit to how visual values are pulled from the theme rather than passed inline everywhere.

## Persistence

V1 needs one small persisted state file for history.

Requirements:

- safe to create automatically
- plain local file is acceptable
- should not depend on external services
- default location: `~/.lxrunner_history`
- history size limit should be configurable

Recommended content:

- launched entry name
- resolved command string
- last used timestamp

Recommended behavior:

- keep entries in recency order
- trim to the configured size limit on write
- if an entry is launched again, update its timestamp and move it to the top rather than duplicating it unnecessarily

## Error Handling

The launcher should fail softly.

Requirements:

- missing or invalid alias commands should not crash Awesome
- empty PATH results should still show a functional launcher
- history read/write failures should degrade gracefully

## Future Extensions

Likely later additions:

- Alt-triggered alternate source mode
- descriptions and icons
- smarter matching
- categories or source labels
- usage-based ranking

These should not distort the initial implementation.

## Confirmed Decisions

The following design choices are now fixed for implementation:

1. Alias storage location

- aliases live in a dedicated local lxrunner config file
- they are not passed into `lxrunner.new(opts)` as ad-hoc inline data

2. Template alias parsing

- first token is the alias name
- the remainder of the input line is the argument tail
- `%s` in a template alias is replaced with that argument tail

3. Result ranking between PATH and aliases

- exact alias matches should rank very high
- alias prefix matches should also rank high
- PATH remains the default baseline source and behavior

4. Launch execution model

- aliases should launch via `awful.spawn.with_shell()`
- plain PATH commands should also use a practical execution path consistent with Awesome launcher behavior
- for now, using `awful.spawn.with_shell()` as the default launcher mechanism is acceptable

## V1 Summary

The first version of `lxrunner` should be:

- a themed Awesome popup launcher
- keyboard-driven
- focused on command and application launch
- intentionally limited to name-based source search
- augmented with custom aliases
- backed by a short persistent history
- deliberately smaller and simpler than Rofi
