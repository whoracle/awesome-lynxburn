# Remaining Migration Notes

The repo runtime no longer depends on split `config/override/*.lua` files.

For a live config migration, move any remaining data from non-example files in
`~/.config/awesome/config/override/` into top-level `~/.config/awesome/config.lua`
under the matching section:

1. `settings.lua` -> `settings = { ... }`
2. `programs.lua` -> `commands = { ... }`
3. `theme.lua` -> `theme = { ... }`
4. `screens.lua` -> `screens = { ... }`
5. `keys.lua` -> `keys = { ... }`
6. `rules.lua` -> `rules = function(context) ... end`
7. `lxrunner_aliases.lua` -> `runner = { aliases = { ... } }`

Once the live machine has copied over anything it still needs, the remaining
non-example files in `config/override/` can be deleted there as well.
