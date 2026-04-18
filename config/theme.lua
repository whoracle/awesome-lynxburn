local M = {}
local config_data = require("config.config_data")

function M.name()
    local theme = config_data.theme()

    if type(theme.name) == "string" and theme.name ~= "" then
        return theme.name
    end

    return "lynxburn2"
end

return M
