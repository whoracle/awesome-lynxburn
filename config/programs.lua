local os = os
local ipairs = ipairs
local helpers = require("config.helpers")

local home = os.getenv("HOME")
local imageeditor = "gimp"
local imageviewer = "sxiv"

local function shell_escape(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function first_token(command)
    return tostring(command or ""):match("^(%S+)")
end

local function command_exists(binary)
    if not binary or binary == "" then
        return false
    end

    local ok = os.execute("command -v " .. shell_escape(binary) .. " >/dev/null 2>&1")

    if type(ok) == "number" then
        return ok == 0
    end

    return ok == true
end

local function resolve_terminal(command)
    local configured = tostring(command or "")

    if command_exists(first_token(configured)) then
        return configured
    end

    for _, candidate in ipairs({
        "alacritty",
        "kitty",
        "urxvt",
        "xterm",
        "x-terminal-emulator",
    }) do
        if command_exists(candidate) then
            return candidate
        end
    end

    return configured
end

---External program definitions and command templates used by the main config.
---
---When changing command-line tools, launchers, screenshot tooling, brightness
---control, or Redshift parameters, this is usually the first file to edit.
local programs = {
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
        method = nil,
        enabled = true,
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

programs = helpers.deep_merge(
    programs,
    helpers.load_optional_module("config.override.programs", {})
)

programs.terminal = resolve_terminal(programs.terminal)

return programs
