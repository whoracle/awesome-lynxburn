local os = os

local home = os.getenv("HOME")
local imageeditor = "gimp"
local imageviewer = "sxiv"

---External program definitions and command templates used by the main config.
---
---When changing command-line tools, launchers, screenshot tooling, brightness
---control, or Redshift parameters, this is usually the first file to edit.
return {
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
    pulse = "pasystray",
    nextcloud = "nextcloud",
    screendrawer = "gromit-mpx",
    launcher = home .. "/.config/rofi/launchers/type-1/launcher.sh",
    filebrowser = "thunar",
    redshift = {
        command = "redshift",
        method = "randr",
        autostart = true,
        latitude = nil,
        longitude = nil,
        temperature_day = 6500,
        temperature_night = 4500,
        transition_steps = 16,
        transition_interval = 0.05,
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
        --"nextcloud",
        --"nm-applet --sm-disable",
    },
}
