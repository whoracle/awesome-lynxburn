local os = os

local home = os.getenv("HOME")
local imageeditor = "gimp"
local imageviewer = "sxiv"

return {
    terminal = "urxvt -fg gray -tr -sh 50",
    browser = "vivaldi-stable",
    gui_editor = "subl",
    imageeditor = imageeditor,
    imageviewer = imageviewer,
    unclutter = "unclutter -root",
    numlock = "numlockx",
    scrlocker = "i3lock -c 000000 -e -t -i ~/.wallpaper",
    scrotedit = "sleep 0.5 && scrot ~/screenshots/%y%m%d_%H%M%S.png -e '" .. imageeditor .. " $f'",
    scrotmouse = "sleep 0.5 && scrot ~/screenshots/%y%m%d_%H%M%S.png -s",
    scrotwin = "sleep 0.5 && scrot ~/screenshots/%y%m%d_%H%M%S.png -ue '" .. imageviewer .. " $f'",
    xrandr = home .. "/.xrandr",
    compositor = "picom -b --config " .. home .. "/.config/picom/picom.conf",
    conky = "conky -c ~/.conky/conky-spotify/conky-spotify",
    nmapplet = "nm-applet --sm-disable",
    blueman = "blueman-applet",
    pulse = "pasystray",
    nextcloud = "nextcloud",
    screendrawer = "gromit-mpx",
    launcher = home .. "/.config/rofi/launchers/type-1/launcher.sh",
    filebrowser = "thunar",
    redshift = "redshift-gtk",
    brightness = {
        get = "xbacklight -get",
        up = "xbacklight -inc 5",
        down = "xbacklight -dec 5",
        off = "xset dpms force off",
    },
    autostart_once = {
        "unclutter -root",
    },
    autostart = {
        --"nextcloud",
        --"nm-applet --sm-disable",
        --"redshift-gtk",
    },
}
