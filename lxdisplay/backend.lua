local platform = require("config.platform")

local M = {}

function M.resolve()
    local module_name

    if platform.effective_target() == "somewm" or platform.is_wayland() then
        module_name = "lxdisplay.backend_somewm"
    else
        module_name = "lxdisplay.backend_x11"
    end

    return require(module_name)
end

return M
