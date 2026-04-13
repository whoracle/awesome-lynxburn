Local machine-specific overrides live in this directory.

Supported local override files:

- `settings.lua`
- `programs.lua`
- `theme.lua`
- `screens.lua`
- `rules.lua`
- `keys.lua`
- `lxrunner_aliases.lua`

These `.lua` files are git-ignored. The tracked `*.example.lua` files show the
expected structure and can be copied to the matching local filename.

`keys.lua` supports declarative replacement of named key specs. Existing
bindings can be changed in place by overriding the matching spec name or
setting `disabled = true`, as shown in `keys.example.lua`.
