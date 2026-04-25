local os = os
local gears = require("gears")

local M = {}
local configured_target

local function getenv(name)
    local value = os.getenv(name)
    if type(value) == "string" and value ~= "" then
        return value
    end

    return nil
end

function M.session_type()
    local session_type = getenv("XDG_SESSION_TYPE")
    if session_type == "wayland" or session_type == "x11" then
        return session_type
    end

    if getenv("WAYLAND_DISPLAY") then
        return "wayland"
    end

    if getenv("DISPLAY") then
        return "x11"
    end

    return "unknown"
end

function M.is_wayland()
    return M.session_type() == "wayland"
end

function M.is_x11()
    return M.session_type() == "x11"
end

function M.config_dir()
    return gears.filesystem.get_configuration_dir()
end

function M.configured_target()
    if configured_target ~= nil then
        return configured_target
    end

    local config_path = M.config_dir() .. "config.lua"
    local ok, result = pcall(dofile, config_path)

    if ok and type(result) == "table" then
        local value = result.platform
        if value == "awesome" or value == "somewm" then
            configured_target = value
            return configured_target
        end
    end

    configured_target = false
    return nil
end

function M.effective_target()
    local configured = M.configured_target()
    if configured then
        return configured
    end

    if M.is_wayland() then
        return "somewm"
    end

    return "awesome"
end

return M
