local M = {}

local lxaudio_instance
local lxdisplay_instance
local lxnotify_instance
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

---Return the shared lxrunner instance.
---@return table
function M.runner()
    if not lxrunner_instance then
        lxrunner_instance = require("lxrunner").new()
    end

    return lxrunner_instance
end

return M
