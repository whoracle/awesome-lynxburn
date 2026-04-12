local M = {}

local lxaudio_instance
local lxnotify_instance

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

function M.notify()
    if not lxnotify_instance then
        lxnotify_instance = require("lxnotify").new({
            notification_denylist = {
                { app_name = "Volume OSD" },
                { app_name = "Mute Indicator" },
                { app_name = "Notification Indicator" },
                { app_name = "Calendar" },
            },
        })
    end

    return lxnotify_instance
end

return M
