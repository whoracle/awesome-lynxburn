local os = os
local M = {}

local home = os.getenv("HOME")
local imageeditor = "gimp"
local imageviewer = "sxiv"

M.widgets = {
    order = {
        "network",
        "audio",
        "notify",
    },
    modules = {
        bluetooth = {
            enabled = false,
        },
        network = {
            enabled = true,
            -- cycle = false,
        },
        powerprofiles = {
            enabled = false,
        },
    },
}

M.theme = {
    name = "lynxburn2",
}

M.commands = {
    terminal = "urxvt -fg gray -tr -sh 50",
    browser = "vivaldi-stable",
    gui_editor = "subl",
    imageeditor = imageeditor,
    imageviewer = imageviewer,
    numlock = "numlockx",
    scrlocker = "i3lock -c 000000 -e -t -i ~/.wallpaper",
    scrotedit = "sleep 0.5 && scrot ~/screenshots/%y%m%d_%H%M%S.png -e '" .. imageeditor .. " $f'",
    scrotmouse = "sleep 0.5 && scrot ~/screenshots/%y%m%d_%H%M%S.png -s",
    scrotwin = "sleep 0.5 && scrot ~/screenshots/%y%m%d_%H%M%S.png -ue '" .. imageviewer .. " $f'",
    xrandr = home .. "/.xrandr",
    conky = "conky -c ~/.conky/conky-spotify/conky-spotify",
    nmapplet = "nm-applet --sm-disable",
    blueman = "blueman-applet",
    blueman_manager = "blueman-manager",
    network_manager = "nm-connection-editor",
    pulse = "pasystray",
    nextcloud = "nextcloud",
    screendrawer = "gromit-mpx",
    launcher = home .. "/.config/rofi/launchers/type-1/launcher.sh",
    filebrowser = "thunar",
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
    brightness = {
        get = "xbacklight -get",
        set = "xbacklight -set %d",
        step = 5,
        min = 10,
        off = "xset dpms force off",
    },
    autostart_once = {},
    autostart = {
        -- "nextcloud",
        -- "nm-applet --sm-disable",
    },
}

return M
