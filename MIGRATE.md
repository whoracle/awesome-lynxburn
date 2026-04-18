# Remaining Migration Notes

This file now tracks only the still-unresolved live migration work needed to
fully move the desktop config away from split `config/override/*.lua` files.

## Current Remaining Live Override

Observed unresolved live override in `/home/anthrax/.config/awesome/`:

- `config/override/rules.lua`

All other previously observed live override data now has a valid top-level
`./config.lua` home and should be treated as migrated or ready for deletion
once verified on the live machine.

## Live `rules.lua` Content

Current content:

```lua
return function(context)
    return {
        {
            rule = { class = "Google-chrome" },
            properties = {
                screen = context.monitors.right,
                tag = "primary",
                maximized = false,
            },
        },
    }
end
```

## What Still Needs Decision

There is not yet a final central `config.lua` surface for rules.

Open design question:

- should top-level `config.lua.rules` hold:
  - a plain list of additional rule entries
  - a function-style rule builder
  - a lighter declarative rule format that `config/rules.lua` expands

Current implementation still expects legacy rule overrides through
`config.override.rules.lua`, including function returns that receive `context`.

## Recommended Next Step

1. Decide the final central user-facing shape for rule overrides.
2. Implement that shape in the repo.
3. Migrate the live `config/override/rules.lua` into top-level `config.lua`.
4. Remove compatibility loading for `config.override.rules`.

## Handoff Note

For a fresh Codex session, this is the last known live override that still
requires a migration design rather than a straightforward data move.
