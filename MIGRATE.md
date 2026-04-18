# Override Migration Notes

This file records the current state of local overrides found in the live config
at `/home/anthrax/.config/awesome/` and the intended migration path toward the
new top-level `./config.lua` model.

The goal is to remove the split `config/override/*.lua` compatibility layer once
the remaining user-facing surfaces have a clear home in `./config.lua`.

## Current Live Override State

Observed files in `/home/anthrax/.config/awesome/config/override/`:

- present as real local overrides:
  - `programs.lua`
  - `keys.lua`
  - `lxrunner_aliases.lua`
- not present as real local overrides:
  - `settings.lua`
  - `theme.lua`
  - `screens.lua`

Also present:

- top-level `/home/anthrax/.config/awesome/config.lua`
  Current state: scaffold only, no active overrides yet.

## Live Override Contents

### `config/override/programs.lua`

Current content:

- `autostart_once = { "nm-applet --sm-disable", "nextcloud" }`
- `redshift = { enabled = true, autostart = true, latitude = 47.9990, longitude = 7.8421, temperature_day = 6500, temperature_night = 4500 }`

Migration target:

```lua
return {
    commands = {
        autostart_once = {
            "nm-applet --sm-disable",
            "nextcloud",
        },
        redshift = {
            enabled = true,
            autostart = true,
            latitude = 47.9990,
            longitude = 7.8421,
            temperature_day = 6500,
            temperature_night = 4500,
        },
    },
}
```

Status:

- supported by the current central config loader
- can be moved into top-level `config.lua` immediately

### `config/override/keys.lua`

Current content:

- swaps the volume up/down actions:
  - `media_volume_up.on_press = "volume_down"`
  - `media_volume_down.on_press = "volume_up"`

Migration target:

```lua
return {
    keys = {
        global = {
            media_volume_up = {
                on_press = "volume_down",
                description = "volume down",
            },
            media_volume_down = {
                on_press = "volume_up",
                description = "volume up",
            },
        },
    },
}
```

Status:

- supported by the current central config loader
- can be moved into top-level `config.lua` immediately

### `config/override/lxrunner_aliases.lua`

Current content:

- one alias:
  - `yayoff` shell command that runs `yay -Syu --noconfirm` and shuts down on success

Migration target:

```lua
return {
    runner = {
        aliases = {
            {
                name = "yayoff",
                type = "shell",
                command = [[urxvt -fg gray -tr -sh 50 -e sh -lc 'yay -Syu --noconfirm; status=$?; if [ $status -ne 0 ]; then echo; echo "yay failed with exit code $status"; echo "Shutdown was not triggered."; printf "Press Enter to close..."; read -r _; exit $status; fi; exec sudo shutdown -hP now']],
            },
        },
    },
}
```

Status:

- supported by the current central config loader
- can be moved into top-level `config.lua` immediately

## Recommended Next Migration Order

1. Move the live `programs.lua` override into top-level `config.lua`.
2. Move the live `keys.lua` override into top-level `config.lua`.
3. Move the live `lxrunner_aliases.lua` override into top-level `config.lua`.
4. Remove compatibility loading for fully migrated split override files.

## What Can Be Removed Soon

After the live `programs.lua` override is moved into top-level `config.lua`:

- `config/override/programs.lua` no longer needs to exist locally
- compatibility loading for `config.override.programs` becomes legacy-only

After the live `keys.lua` override is moved into top-level `config.lua`:

- `config/override/keys.lua` no longer needs to exist locally
- compatibility loading for `config.override.keys` becomes legacy-only

After the live `lxrunner_aliases.lua` override is moved into top-level `config.lua`:

- `config/override/lxrunner_aliases.lua` no longer needs to exist locally
- compatibility loading for `config.override.lxrunner_aliases` becomes legacy-only

## What Should Not Be Removed Yet

- none of the currently observed live split override files, once the three
  central migrations above have been applied locally
