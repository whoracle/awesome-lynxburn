return {
    theme = {
        wallpaper = os.getenv("HOME") .. "/.wallpaper",
    },

    commands = {
        terminal = "alacritty",
        launcher = "rofi -show drun",
        filebrowser = "xdg-open",
    },

    screens = {
        tag_order = { "primary", "secondary", "tertiary" },
        tag_defaults = {
            primary = {
                layout = "fair.horizontal",
                layouts = { "fair.horizontal", "centerwork.horizontal", "floating" },
            },
            secondary = {
                layout = "centerwork",
                layouts = { "centerwork", "fair", "floating" },
            },
            tertiary = {
                layout = "floating",
                layouts = { "floating" },
            },
        },
        center = {
            dpi = 96,
        },
    },

    lxmodules = {
        lxbar = {
            order = {
                "lxnetwork",
                "lxmedia",
                "lxnotify",
                "lxdisplay",
                "lxpower",
            },
            popup_side = "right",
            modules = {
                lxnetwork = {
                    cycle = true,
                },
                lxnotify = {
                    cycle = true,
                },
            },
        },
        lxrunner = {
            width = 640,
            row_count = 10,
        },
    },
}
