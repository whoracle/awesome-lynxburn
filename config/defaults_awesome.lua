local M = {}

M.commands = {
    terminal = "alacritty",
    scrotedit = "sleep 0.5 && scrot ~/screenshots/%y%m%d_%H%M%S.png -e 'xdg-open $f'",
    scrotmouse = "sleep 0.5 && scrot ~/screenshots/%y%m%d_%H%M%S.png -s",
    scrotwin = "sleep 0.5 && scrot ~/screenshots/%y%m%d_%H%M%S.png -ue 'xdg-open $f'",
}

M.lxmodules = {
    lxdisplay = {
        brightness = {
            get = "xbacklight -get",
            set = "xbacklight -set %d",
            off = "xset dpms force off",
        },
        redshift = {
            command = "xrandr",
        },
    },
}

return M
