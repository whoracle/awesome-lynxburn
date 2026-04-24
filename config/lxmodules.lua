local M = {}
local config_data = require("config.config_data")

local function lxmodules()
    return config_data.lxmodules()
end

local function bar_module_settings(id)
    local modules = (lxmodules().lxbar or {}).modules or {}
    local module_settings = modules["lx" .. id]

    if type(module_settings) ~= "table" then
        module_settings = modules[id]
    end

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

local function normalize_bar_module_id(id)
    if type(id) ~= "string" or id == "" then
        return nil
    end

    if id:match("^custom:[%w_%-]+$") then
        return id
    end

    if id:match("^lx[%w_]+$") then
        return id:gsub("^lx", "")
    end

    return id
end

function M.order()
    local order = (lxmodules().lxbar or {}).order

    if type(order) ~= "table" then
        return {}
    end

    local normalized = {}

    for _, id in ipairs(order) do
        local normalized_id = normalize_bar_module_id(id)
        if normalized_id then
            normalized[#normalized + 1] = normalized_id
        end
    end

    return normalized
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

function M.custom_widgets()
    local custom_widgets = ((lxmodules().lxbar or {}).custom_widgets)

    if type(custom_widgets) ~= "table" then
        return {}
    end

    return custom_widgets
end

function M.screen_enabled(screen_obj)
    local screens = (lxmodules().lxbar or {}).screens

    if type(screens) ~= "table" then
        return true
    end

    local monitors = (config_data.settings() or {}).monitors or {}

    for _, screen_name in ipairs(screens) do
        if monitors[screen_name] == screen_obj.index then
            return true
        end
    end

    return false
end

return M
