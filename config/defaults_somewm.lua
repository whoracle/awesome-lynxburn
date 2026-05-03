local M = {}

M.commands = {
    terminal = "foot",
    scrotedit = "mkdir -p \"$HOME/screenshots\" && f=\"$HOME/screenshots/$(date +%y%m%d_%H%M%S).png\" && grim \"$f\" && xdg-open \"$f\"",
    scrotmouse = "mkdir -p \"$HOME/screenshots\" && grim -g \"$(slurp)\" \"$HOME/screenshots/$(date +%y%m%d_%H%M%S).png\"",
    scrotwin = "mkdir -p \"$HOME/screenshots\" && f=\"$HOME/screenshots/$(date +%y%m%d_%H%M%S).png\" && grim \"$f\" && xdg-open \"$f\"",
}

M.lxmodules = {
    lxdisplay = {
        brightness = {
            get = "brightnessctl g",
            set = "brightnessctl s %d%%",
            off = "wlopm --off '*'",
        },
        redshift = {
            enabled = false,
        },
    },
}

return M
