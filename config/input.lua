local awful = require("awful")
local platform = require("config.platform")

local M = {}

local function shell_escape(value)
    return "'" .. tostring(value or ""):gsub("'", "'\\''") .. "'"
end

local function nonempty_string(value)
    return type(value) == "string" and value ~= ""
end

local function keyboard_settings(settings)
    return (settings or {}).keyboard or {}
end

local function apply_x11_keyboard(settings)
    local keyboard = keyboard_settings(settings)
    if not nonempty_string(keyboard.layout) then
        return
    end

    local args = {
        "setxkbmap",
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

local function apply_somewm_keyboard(settings)
    local keyboard = keyboard_settings(settings)
    local awful_input = require("awful.input")

    if nonempty_string(keyboard.layout) then
        awful_input.xkb_layout = keyboard.layout
    end

    if keyboard.variant ~= nil then
        awful_input.xkb_variant = tostring(keyboard.variant or "")
    end

    if keyboard.options ~= nil then
        awful_input.xkb_options = tostring(keyboard.options or "")
    end
end

function M.apply(settings)
    if platform.effective_target() == "somewm" or platform.is_wayland() then
        apply_somewm_keyboard(settings)
    else
        apply_x11_keyboard(settings)
    end
end

function M.preflight_command(settings)
    local keyboard = keyboard_settings(settings)
    if not nonempty_string(keyboard.layout) then
        return nil
    end

    if platform.effective_target() == "somewm" or platform.is_wayland() then
        return nil
    end

    return "setxkbmap " .. shell_escape(keyboard.layout)
end

return M
