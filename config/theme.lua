local M = {}
local config_data = require("config.config_data")

function M.name()
    local theme = config_data.theme()

    if type(theme.name) == "string" and theme.name ~= "" then
        return theme.name
    end

    return "lynxburn2"
end

function M.overrides()
    local theme = config_data.theme()
    local overrides = {}

    for key, value in pairs(theme) do
        if key ~= "name" then
            overrides[key] = value
        end
    end

    return overrides
end

return M
