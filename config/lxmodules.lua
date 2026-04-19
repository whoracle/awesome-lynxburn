local M = {}
local config_data = require("config.config_data")

local function lxmodules()
    return config_data.lxmodules()
end

local function bar_module_settings(id)
    local modules = (lxmodules().lxbar or {}).modules or {}
    local module_settings = modules[id]

    if type(module_settings) ~= "table" then
        return {}
    end

    return module_settings
end

local function runtime_module_settings(id)
    local module_settings = lxmodules()["lx" .. id]

    if type(module_settings) ~= "table" then
        return {}
    end

    return module_settings
end

function M.order()
    local order = (lxmodules().lxbar or {}).order

    if type(order) ~= "table" then
        return {}
    end

    return order
end

function M.popup_side()
    local side = (lxmodules().lxbar or {}).popup_side

    if side == "left" or side == "right" then
        return side
    end

    return "right"
end

function M.enabled(id, default)
    local order = M.order()

    for _, configured_id in ipairs(order) do
        if configured_id == id then
            return true
        end
    end

    return default ~= false
end

function M.cycle_enabled(id, default)
    local module_settings = bar_module_settings(id)

    if module_settings.cycle ~= nil then
        return module_settings.cycle ~= false
    end

    return default ~= false
end

function M.options(id)
    local module_settings = runtime_module_settings(id)
    local options = {}

    for key, value in pairs(module_settings) do
        options[key] = value
    end

    return options
end

return M
