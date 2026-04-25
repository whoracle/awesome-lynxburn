local awful = require("awful")

local M = {}

local function nonempty_string(value)
    return type(value) == "string" and value ~= ""
end

local function shell_escape(value)
    return "'" .. tostring(value or ""):gsub("'", "'\\''") .. "'"
end

local function keyboard_settings(settings)
    return (settings or {}).keyboard or {}
end

function M.apply(settings)
    local keyboard = keyboard_settings(settings)
    if not nonempty_string(keyboard.layout) then
        return
    end

    local args = {
        "set" .. "xkbmap",
        keyboard.layout,
    }

    if nonempty_string(keyboard.variant) then
        args[#args + 1] = "-variant"
        args[#args + 1] = keyboard.variant
    end

    if nonempty_string(keyboard.options) then
        args[#args + 1] = "-option"
        args[#args + 1] = keyboard.options
    end

    awful.spawn(args, false)
end

function M.preflight_command(settings)
    local keyboard = keyboard_settings(settings)
    if not nonempty_string(keyboard.layout) then
        return nil
    end

    return ("set" .. "xkbmap") .. " " .. shell_escape(keyboard.layout)
end

return M
