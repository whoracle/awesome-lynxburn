local platform = require("config.platform")

if platform.effective_target() == "somewm" or platform.is_wayland() then
    return require("lxrunner.clipboard_somewm")
end

return require("lxrunner.clipboard_x11")
