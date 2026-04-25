local M = {}

local function nonempty_string(value)
    return type(value) == "string" and value ~= ""
end

local function keyboard_settings(settings)
    return (settings or {}).keyboard or {}
end

function M.apply(settings)
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

function M.preflight_command()
    return nil
end

return M
