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
    --     wallpaper = os.getenv("HOME") .. "/Pictures/wallpaper.png",
    --     lxrunner_width = 640,
    -- },
    -- screens = {
    --     left = {
    --         layout = "fair.horizontal",
    --         dpi = 96,
    --     },
    --     right = {
    --         layout = "floating",
    --         dpi = 110,
    --     },
    -- },
    -- widgets = {
    --     order = {
    --         "network",
    --         "audio",
    --         "notify",
    --     },
    --     modules = {
    --         network = {
    --             enabled = true,
    --             -- cycle = false,
    --         },
    --     },
    -- },
    -- commands = {
    --     terminal = "alacritty",
    -- },
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
    keys = {
        -- global = {
        --     programs_terminal = {
        --         modifiers = { "modkey" },
        --         key = "Return",
        --     },
        -- },
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
