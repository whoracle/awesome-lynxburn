local M = {}

local function widget_module_settings(settings, id)
    local widgets = settings.widgets or {}
    local modules = widgets.modules or {}
    local module_settings = modules[id]

    if type(module_settings) ~= "table" then
        return {}
    end

    return module_settings
end

function M.order(settings)
    local widgets = settings.widgets or {}

    if type(widgets.order) ~= "table" then
        return {}
    end

    return widgets.order
end

function M.enabled(settings, id, default)
    local module_settings = widget_module_settings(settings, id)

    if module_settings.enabled ~= nil then
        return module_settings.enabled ~= false
    end

    return default ~= false
end

function M.cycle_enabled(settings, id, default)
    local module_settings = widget_module_settings(settings, id)

    if module_settings.cycle ~= nil then
        return module_settings.cycle ~= false
    end

    return default ~= false
end

return M
