local beautiful = require("beautiful")
local gears = require("gears")

local M = {}

---Trim leading and trailing whitespace from a string.
function M.trim(s)
    if not s then
        return nil
    end

    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

---Escape one shell argument using single-quote wrapping.
function M.shell_escape(s)
    s = tostring(s or "")
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

---Return true when a command exists on PATH.
function M.command_exists(cmd)
    local ok = os.execute("command -v " .. cmd .. " >/dev/null 2>&1")
    return ok == true or ok == 0
end

---Run a command and return trimmed stdout, or nil on failure.
function M.read_command(cmd)
    local f = io.popen(cmd)
    if not f then
        return nil
    end

    local out = f:read("*a")
    f:close()
    return M.trim(out or "")
end

---Split a string into non-empty lines.
function M.split_lines(s)
    local lines = {}
    if not s or s == "" then
        return lines
    end

    for line in s:gmatch("[^\r\n]+") do
        lines[#lines + 1] = line
    end

    return lines
end

---Read a theme value with a fallback.
function M.theme_value(theme_key, fallback)
    local theme_value = beautiful[theme_key]
    if theme_value ~= nil then
        return theme_value
    end

    return fallback
end

---Attach hover/press feedback to a background widget.
function M.attach_hover_background(widget, normal_bg, hover_bg, press_bg)
    if not widget or not hover_bg or hover_bg == normal_bg then
        return
    end

    local pointer_inside = false
    local pressed = false
    local active = false

    local function sync_bg()
        if pressed then
            widget.bg = press_bg or hover_bg
        elseif pointer_inside or active then
            widget.bg = hover_bg
        else
            widget.bg = normal_bg
        end
    end

    widget:connect_signal("mouse::enter", function()
        pointer_inside = true
        sync_bg()
    end)

    widget:connect_signal("mouse::leave", function()
        pointer_inside = false
        pressed = false
        sync_bg()
    end)

    widget:connect_signal("button::press", function()
        pressed = true
        sync_bg()
    end)

    widget:connect_signal("button::release", function()
        pressed = false
        sync_bg()
    end)

    widget._lx_set_feedback_active = function(_, value)
        active = value and true or false
        sync_bg()
    end
end

---Start a delayed hover-open timer for compact widget reveals.
function M.start_delayed_hover(instance, opts)
    opts = opts or {}

    local timer_key = opts.timer_key or "_hover_open_timer"
    local state_key = opts.state_key or "_widget_hovered"
    local delay = tonumber(opts.delay) or 0
    local on_change = opts.on_change or function() end

    if instance[timer_key] then
        instance[timer_key]:stop()
        instance[timer_key] = nil
    end

    if instance[state_key] == true then
        return
    end

    if delay <= 0 then
        instance[state_key] = true
        on_change()
        return
    end

    instance[timer_key] = gears.timer.start_new(delay, function()
        instance[timer_key] = nil
        instance[state_key] = true
        on_change()
        return false
    end)
end

---Cancel delayed hover-open state and hide the compact widget immediately.
function M.stop_delayed_hover(instance, opts)
    opts = opts or {}

    local timer_key = opts.timer_key or "_hover_open_timer"
    local state_key = opts.state_key or "_widget_hovered"
    local on_change = opts.on_change or function() end

    if instance[timer_key] then
        instance[timer_key]:stop()
        instance[timer_key] = nil
    end

    if instance[state_key] ~= false then
        instance[state_key] = false
        on_change()
    end
end

return M
