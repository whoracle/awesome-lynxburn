-- LynxBurn Theme
-- rc.lua
--
-- Main Awesome entrypoint. This file is intentionally kept thin and mostly
-- wires together the smaller config modules plus the selected theme.

local awesome, client, mouse, screen, tag = awesome, client, mouse, screen, tag
local ipairs, string, os, table, tostring, tonumber, type =
    ipairs, string, os, table, tostring, tonumber, type

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local beautiful = require("beautiful")
local lain = require("lain")
local naughty = require("naughty")

local my_table = awful.util.table or gears.table

local config = require("config")

-- Long-lived shared services are created after the theme is loaded so their
-- widgets read final `beautiful` values rather than partially initialized ones.
local lxaudio = config.services.audio()
local lxbluetooth = nil
local lxdisplay = nil
local lxnetwork = nil
local lxnotify = config.services.notify()
local lxpowerprofiles = nil
local lxrunner = nil

config.helpers.setup_error_handling(awesome, naughty)

local theme_path = string.format(
    "%s/.config/awesome/themes/%s/theme2.lua",
    os.getenv("HOME"),
    config.settings.theme_name
)
beautiful.init(theme_path)

lxrunner = config.services.runner()
lxbluetooth = config.services.bluetooth()
lxdisplay = config.services.display()
lxnetwork = config.services.network()
lxpowerprofiles = config.services.powerprofiles()

local osd_handlers = config.osd.new(beautiful, {
    volume_step = config.settings.volume_step,
})

config.layouts.setup({
    terminal = config.programs.terminal,
    workspaces = config.settings.workspaces,
})

local quake = config.layouts.create_quake(config.programs.terminal)

local keymaps = config.keys.build({
    my_table = my_table,
    settings = config.settings,
    programs = config.programs,
    lain = lain,
    lxaudio = lxaudio,
    lxbluetooth = lxbluetooth,
    lxdisplay = lxdisplay,
    lxnetwork = lxnetwork,
    lxnotify = lxnotify,
    lxpowerprofiles = lxpowerprofiles,
    lxrunner = lxrunner,
    osd = osd_handlers,
    quake = quake,
})

local mousemaps = config.mouse.build({
    my_table = my_table,
    terminal = config.programs.terminal,
    modkey = config.settings.modkey,
})

config.helpers.run_once(awful, config.programs.autostart_once)

root.buttons(mousemaps.mousebuttons)
root.keys(keymaps.globalkeys)

awful.rules.rules = config.rules.build({
    beautiful = beautiful,
    clientkeys = keymaps.clientkeys,
    clientbuttons = mousemaps.clientbuttons,
    monitors = config.settings.monitors,
})

config.signals.setup({
    beautiful = beautiful,
    my_table = my_table,
})

awful.screen.set_auto_dpi_enabled(true)
config.screens.setup(config.settings)

for _, command in ipairs(config.programs.autostart) do
    awful.spawn(command)
end
