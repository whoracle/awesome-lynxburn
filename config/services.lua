local M = {}

local lxaudio_instance
local lxbluetooth_instance
local lxdisplay_instance
local lxnetwork_instance
local lxnotify_instance
local lxpowerprofiles_instance
local lxrunner_instance

---Shared singleton accessors for the long-lived helper modules.
---
---Services are created lazily so theme initialization can complete before
---theme-driven widget options are read.
function M.audio()
    if not lxaudio_instance then
        lxaudio_instance = require("lxaudio").new({
            show_mic_activity = true,
            refresh_interval = 5,
            width = 50,
        })
    end

    return lxaudio_instance
end

function M.bluetooth()
    local settings = require("config.settings")
    if settings.widgets and settings.widgets.bluetooth == false then
        return nil
    end

    if not lxbluetooth_instance then
        lxbluetooth_instance = require("lxbluetooth").new()
    end

    return lxbluetooth_instance
end

---Return the shared lxnotify instance.
---@return table
function M.notify()
    if not lxnotify_instance then
        lxnotify_instance = require("lxnotify").new({
            notification_denylist = {
                { app_name = "Volume OSD" },
                { app_name = "Mute Indicator" },
                { app_name = "Brightness OSD" },
                { app_name = "Notification Indicator" },
                { app_name = "Calendar" },
            },
        })
    end

    return lxnotify_instance
end

---Return the shared lxdisplay instance.
---@return table
function M.display()
    if not lxdisplay_instance then
        local programs = require("config.programs")
        lxdisplay_instance = require("lxdisplay").new({
            brightness = programs.brightness,
            redshift = programs.redshift,
        })
    end

    return lxdisplay_instance
end

function M.network()
    local settings = require("config.settings")
    if settings.widgets and settings.widgets.network == false then
        return nil
    end

    if not lxnetwork_instance then
        lxnetwork_instance = require("lxnetwork").new()
    end

    return lxnetwork_instance
end

---Return the shared lxrunner instance.
---@return table
function M.runner()
    if not lxrunner_instance then
        lxrunner_instance = require("lxrunner").new()
    end

    return lxrunner_instance
end

function M.powerprofiles()
    local settings = require("config.settings")
    if settings.widgets and settings.widgets.powerprofiles == false then
        return nil
    end

    if not lxpowerprofiles_instance then
        lxpowerprofiles_instance = require("lxpowerprofiles").new()
    end

    return lxpowerprofiles_instance
end

return M
