local os = os
local M = {}
local default_keys = require("config.default_keys")

M.theme = {
    name = "lynxburn",
    color_scheme = "lynxburn",
}

M.screens = {
    tag_order = { "primary", "secondary", "tertiary" },
    tag_defaults = {
        primary = {
            layout = "fair",
            layouts = { "fair" },
        },
        secondary = {
            layout = "centerwork",
            layouts = { "centerwork" },
        },
        tertiary = {
            layout = "floating",
            layouts = { "floating" },
        },
    },
    center = {
        dpi = 96,
    },
}

M.settings = {
    modkey = "Mod4",
    altkey = "Mod1",
    ctrlkey = "Control",
    shiftkey = "Shift",
    volume_step = 5,
    monitors = {
        center = 1,
    },
}

M.commands = {
    terminal = "alacritty",
    scrlocker = "i3lock -c 000000",
    scrotedit = "sleep 0.5 && scrot ~/screenshots/%y%m%d_%H%M%S.png -e 'xdg-open $f'",
    scrotmouse = "sleep 0.5 && scrot ~/screenshots/%y%m%d_%H%M%S.png -s",
    scrotwin = "sleep 0.5 && scrot ~/screenshots/%y%m%d_%H%M%S.png -ue 'xdg-open $f'",
    blueman_manager = "blueman-manager",
    launcher = "rofi -show drun",
    filebrowser = "xdg-open",
    lain = {
        imap_server = nil,
        imap_mail = nil,
        imap_secret = nil,
        imap_login_options = "AUTH=LOGIN",
        imap_timeout = 60,
    },
    autostart_once = {},
    autostart = {},
}

M.lxmodules = {
    lxbar = {
        popup_side = "right",
        order = {
            "lxnetwork",
            "lxmedia",
            "lxnotify",
        },
        modules = {
            lxmedia = {},
            lxbluetooth = {},
            lxdisplay = {},
            lxnetwork = {
                -- cycle = false,
            },
            lxnotify = {},
            lxpower = {},
        },
    },
    lxmedia = {
        show_mic_activity = true,
        refresh_interval = 5,
        width = 50,
        step = 0.05,
        enable_osd = true,
        osd_width = 260,
        osd_height = 18,
        osd_margin = 16,
    },
    lxbluetooth = {
        refresh_interval = 15,
    },
    lxdisplay = {
        auto_apply = true,
        refresh_interval = 15,
        enable_osd = true,
        osd_width = 260,
        osd_height = 18,
        osd_margin = 16,
        detected = {
            extend_relative_to = "profile-primary",
            extend_direction = "left",
        },
        brightness = {
            get = "xbacklight -get",
            set = "xbacklight -set %d",
            step = 5,
            min = 10,
            off = "xset dpms force off",
        },
        redshift = {
            command = "xrandr",
            enabled = true,
            autostart = true,
            latitude = nil,
            longitude = nil,
            temperature_day = 6500,
            temperature_night = 4500,
            transition_steps = 16,
            transition_interval = 0.05,
            refresh_interval = 120,
            schedule_transition_seconds = 3600,
            day_start = "07:00",
            night_start = "19:00",
        },
    },
    lxnetwork = {
        refresh_interval = 20,
    },
    lxnotify = {
        notification_denylist = {
            { app_name = "Volume OSD" },
            { app_name = "Mute Indicator" },
            { app_name = "Brightness OSD" },
            { app_name = "Notification Indicator" },
            { app_name = "Calendar" },
        },
        notification_title_max_length = 72,
        notification_body_max_length = 140,
        notification_source_max_length = 28,
        notification_time_format = "%H:%M",
        popup_visible_items = 7,
        interception_paused = false,
        debug_notifications = false,
    },
    lxpower = {
        refresh_interval = 20,
        preferred_profiles = {
            battery = "power-saver",
            ac = "balanced",
        },
    },
    lxrunner = {
        width = 520,
        row_count = 10,
        history_limit = 10,
        prompt = "Run",
        aliases = {},
    },
    lxsecrets = {
        at_start = true,
        at_start_delay = "60s",
        interval = false,
        top_level = "always",
        cycle_exclude = true,
        browser = nil,
        vpn_timeout = "5m",
        interactive_vpn_timeout = "15m",
        thresholds = {
            gitlab = "30d",
            hashicorp_vault = "7d",
        },
        lifetimes = {
            gitlab = "365d",
        },
        secrets = {},
    },
}

M.keys = default_keys

return M
