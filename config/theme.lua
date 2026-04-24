local M = {}
local config_data = require("config.config_data")
local pairs = pairs
local string = string

local function theme_path(name)
    return string.format(
        "%s/.config/awesome/themes/%s/theme.lua",
        os.getenv("HOME"),
        name
    )
end

function M.name()
    local theme = config_data.theme()

    if type(theme.name) == "string" and theme.name ~= "" then
        return theme.name
    end

    return "lynxburn"
end

function M.color_scheme()
    local theme = config_data.theme()

    if type(theme.color_scheme) == "string" and theme.color_scheme ~= "" then
        return theme.color_scheme
    end

    if type(theme.scheme) == "string" and theme.scheme ~= "" then
        return theme.scheme
    end

    return "lynxburn"
end

function M.overrides()
    local theme = config_data.theme()
    local overrides = {}

    for key, value in pairs(theme) do
        if key ~= "name" and key ~= "color_scheme" and key ~= "scheme" then
            overrides[key] = value
        end
    end

    return overrides
end

function M.init(beautiful)
    beautiful.init(theme_path(M.name()))

    for key, value in pairs(M.overrides()) do
        beautiful[key] = value
    end
end

return M
