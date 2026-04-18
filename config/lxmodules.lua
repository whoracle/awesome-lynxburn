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

function M.enabled(id, default)
    local module_settings = bar_module_settings(id)

    if module_settings.enabled ~= nil then
        return module_settings.enabled ~= false
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
