# Remaining Migration Notes

All observed live split overrides now have a central top-level `./config.lua`
home in the repo.

The only remaining migration work is on the live desktop config itself:

1. copy the live `config/override/rules.lua` content into top-level
   `~/.config/awesome/config.lua` under `rules = function(context) ... end`
2. reload Awesome and verify the Chrome placement rule still works
3. delete the migrated non-example files in
   `~/.config/awesome/config/override/`

At this point, `MIGRATE.md` can be deleted once the live machine has completed
that final move.
