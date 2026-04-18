return {
    -- settings = {
    --     modkey = "Mod4",
    --     monitors = {
    --         left = 1,
    --         center = 2,
    --         right = 3,
    --     },
    -- },
    -- theme = {
    --     name = "lynxburn2",
    --     -- Flat keys override `beautiful.*` values after the theme loads.
    --     wallpaper = os.getenv("HOME") .. "/Pictures/wallpaper.png",
    --     wibar_height = 24,
    --     notification_max_width = 640,
    --     lxmedia_bar_fg = "#e0b56a",
    --     lxmedia_popup_width_media = 420,
    --     lxpower_popup_width = 420,
    --     lxrunner_width = 640,
    -- },
    -- screens = {
    --     tag_order = { "primary", "secondary", "tertiary" },
    --     tag_defaults = {
    --         primary = { layout = "fair" },
    --         secondary = { layout = "centerwork" },
    --         tertiary = { layout = "centerwork.horizontal" },
    --     },
    --     left = {
    --         dpi = 96,
    --         tags = {
    --             primary = { layout = "fair.horizontal" },
    --             secondary = { layout = "centerwork" },
    --             tertiary = { layout = "floating" },
    --         },
    --     },
    --     right = {
    --         dpi = 110,
    --         tags = {
    --             primary = { layout = "floating" },
    --         },
    --     },
    --     center = {
    --         -- legacy compatibility shortcut:
    --         -- layout = "centerwork",
    --     },
    -- },
    -- commands = {
    --     terminal = "alacritty",
    --     lain = {
    --         imap_mail = "me@example.org",
    --         imap_secret = "secret-tool lookup service awesomewm-imap account me@example.org",
    --     },
    -- },
    commands = {
        autostart_once = {
            "nm-applet --sm-disable",
            "nextcloud",
        },
    },
    -- lxmodules = {
    --     lxbar = {
    --         order = {
    --             "network",
    --             "media",
    --             "notify",
    --         },
    --         modules = {
    --             network = {
    --                 -- cycle = false,
    --             },
    --         },
    --     },
    --     lxmedia = {
    --         refresh_interval = 2,
    --         width = 60,
    --         step = 0.02,
    --     },
    --     lxdisplay = {
    --         refresh_interval = 10,
    --         brightness = {
    --             get = "brightnessctl g",
    --             set = "brightnessctl s %d%%",
    --             step = 5,
    --             min = 10,
    --             off = "xset dpms force off",
    --         },
    --         redshift = {
    --             enabled = true,
    --             latitude = 47.9990,
    --             longitude = 7.8421,
    --         },
    --     },
    --     lxnotify = {
    --         notification_denylist = {
    --             { app_name = "Volume OSD" },
    --         },
    --         notification_time_format = "%H:%M",
    --         popup_visible_items = 10,
    --     },
    --     lxpower = {
    --         refresh_interval = 10,
    --         preferred_profiles = {
    --             battery = "power-saver",
    --             ac = "balanced",
    --         },
    --     },
    --     lxrunner = {
    --         width = 640,
    --         row_count = 12,
    --         history_limit = 20,
    --         aliases = {
    --             {
    --                 name = "browser",
    --                 type = "template",
    --                 glyph = "󰖟",
    --                 command = "firefox %s",
    --             },
    --         },
    --     },
    -- },
    lxmodules = {
        lxdisplay = {
            redshift = {
                latitude = 47.9990,
                longitude = 7.8421,
            },
        },
        lxrunner = {
            aliases = {
                {
                    name = "yayoff",
                    type = "shell",
                    -- icon = "/absolute/path/to/icon.svg",
                    -- glyph = "󰐥",
                    -- glyph_font = "Symbols Nerd Font 12",
                    command = [[urxvt -fg gray -tr -sh 50 -e sh -lc 'yay -Syu --noconfirm; status=$?; if [ $status -ne 0 ]; then echo; echo "yay failed with exit code $status"; echo "Shutdown was not triggered."; printf "Press Enter to close..."; read -r _; exit $status; fi; exec sudo shutdown -hP now']],
                },
            },
        },
    },
    keys = {
        -- open_terminal = {
        --     scope = "global",
        --     modifiers = { "modkey" },
        --     key = "Return",
        -- },
        volume_up = {
            scope = "global",
            on_press = "volume_down",
            description = "volume down",
        },
        volume_down = {
            scope = "global",
            on_press = "volume_up",
            description = "volume up",
        },
    },
    rules = function(context)
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
    end,
}
