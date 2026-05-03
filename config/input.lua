local platform = require("config.platform")

if platform.effective_target() == "somewm" or platform.is_wayland() then
    return require("config.input_somewm")
end

return require("config.input_x11")
