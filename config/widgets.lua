local M = {}
local config_data = require("config.config_data")

local function widget_module_settings(id)
    local widgets = config_data.widgets()
    local modules = widgets.modules or {}
    local module_settings = modules[id]

    if type(module_settings) ~= "table" then
        return {}
    end

    return module_settings
end

function M.order()
    local widgets = config_data.widgets()

    if type(widgets.order) ~= "table" then
        return {}
    end

    return widgets.order
end

function M.enabled(id, default)
    local module_settings = widget_module_settings(id)

    if module_settings.enabled ~= nil then
        return module_settings.enabled ~= false
    end

    return default ~= false
end

function M.cycle_enabled(id, default)
    local module_settings = widget_module_settings(id)

    if module_settings.cycle ~= nil then
        return module_settings.cycle ~= false
    end

    return default ~= false
end

function M.options(id)
    local module_settings = widget_module_settings(id)
    local options = {}

    for key, value in pairs(module_settings) do
        if key ~= "enabled" and key ~= "cycle" then
            options[key] = value
        end
    end

    return options
end

return M
