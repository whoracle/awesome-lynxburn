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
local naughty = require("naughty")

local my_table = awful.util.table or gears.table

local config = require("config.init")
local config_data = config.config_data
local runtime = config.runtime
local settings = config_data.settings()
local commands = config_data.commands()

local lxmedia = nil
local lxbar = nil
local lxbluetooth = nil
local lxdisplay = nil
local lxnetwork = nil
local lxnotify = nil
local lxpower = nil
local lxrunner = nil
local lxsecrets = nil

config.helpers.setup_error_handling(awesome, naughty)

config.theme.init(beautiful)

-- Long-lived shared services are created only after the theme is loaded so
-- their widgets read final `beautiful` values rather than partial defaults.
local services = config.services.bootstrap()
lxsecrets = services.secrets
lxmedia = services.media
lxnotify = services.notify
lxrunner = services.runner
lxbar = services.bar
lxbluetooth = services.bluetooth
lxdisplay = services.display
lxnetwork = services.network
lxpower = services.power

local osd_handlers = config.osd.new(beautiful, {
    volume_step = settings.volume_step,
})

config.layouts.setup({
    terminal = commands.terminal,
})
config.input.apply(settings)

local quake = config.layouts.create_quake(commands.terminal)

local keymaps = config.keys.build({
    my_table = my_table,
    settings = settings,
    runtime = runtime,
    commands = commands,
    layouts = config.layouts,
    lxmedia = lxmedia,
    lxbar = lxbar,
    lxbluetooth = lxbluetooth,
    lxdisplay = lxdisplay,
    lxnetwork = lxnetwork,
    lxnotify = lxnotify,
    lxpower = lxpower,
    lxrunner = lxrunner,
    osd = osd_handlers,
    quake = quake,
})

local mousemaps = config.mouse.build({
    my_table = my_table,
    terminal = commands.terminal,
    modkey = settings.modkey,
})

config.helpers.run_once(awful, commands.autostart_once)

root.buttons(mousemaps.mousebuttons)
root.keys(keymaps.globalkeys)

awful.rules.rules = config.rules.build({
    beautiful = beautiful,
    clientkeys = keymaps.clientkeys,
    clientbuttons = mousemaps.clientbuttons,
    monitors = settings.monitors,
    tags = runtime.tags(),
})

config.signals.setup({
    beautiful = beautiful,
    my_table = my_table,
})

awful.screen.set_auto_dpi_enabled(true)
config.screens.setup(settings)

for _, command in ipairs(commands.autostart) do
    awful.spawn(command)
end

gears.timer.delayed_call(function()
    config.preflight.run({
        naughty = naughty,
    })
end)
