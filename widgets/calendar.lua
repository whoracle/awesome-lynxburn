local awful = require("awful")
local naughty = require("naughty")

local markup = require("widgets.markup")

local M = {}

local notification = nil
local current_month = nil
local current_year = nil
local preset = {}

local function getdate(month, year, offset)
    month = month + offset

    while month > 12 do
        month = month - 12
        year = year + 1
    end

    while month < 1 do
        month = month + 12
        year = year - 1
    end

    return month, year
end

local function week_number(month, year, week_start, row)
    local date = os.time({ year = year, month = month, day = 1 + row * 7 })
    local first = os.date("*t", os.time({ year = year, month = month, day = 1 }))
    local step = math.floor((row * 7 + first.wday - week_start) / 7)
    return string.format("%3d | ", os.date("%V", date + step * 7 * 24 * 60 * 60))
end

local function build(month, year, options)
    local now = os.date("*t")
    local is_current = month == now.month and year == now.year
    local today = is_current and now.day or nil
    local last = os.date("*t", os.time({ year = year, month = month + 1, day = 0 }))
    local first = os.date("*t", os.time({ year = year, month = month, day = 1 }))
    local week_start = options.week_start or 2
    local st_day = (first.wday - week_start) % 7
    local title = os.date("%B %Y", os.time({ year = year, month = month, day = 1 }))
    local rows = {
        string.format("%s%s\n", string.rep(" ", math.floor((28 - #title) / 2)), markup.bold(title)),
    }

    if options.week_number == "left" then
        rows[#rows + 1] = "     | "
    end

    for day_num = 0, 6 do
        rows[#rows + 1] = string.format("%3s ", os.date("%a", os.time({
            year = 2006,
            month = 1,
            day = day_num + week_start,
        })))
    end

    rows[#rows] = rows[#rows]:sub(1, -2) .. "\n"

    local day = 1
    for row = 0, 5 do
        local line = ""
        for col = 0, 6 do
            local cell = "   "
            if row > 0 or col >= st_day then
                if day <= last.day then
                    local text = string.format("%2d", day)
                    if day == today then
                        text = markup.bold(markup.color(options.bg or "#000000", text))
                    end
                    cell = " " .. text
                    day = day + 1
                end
            end
            line = line .. cell .. " "
        end

        if options.week_number == "left" then
            line = week_number(month, year, week_start, row) .. line
        end

        rows[#rows + 1] = line:gsub("%s+$", "") .. "\n"
        if day > last.day then
            break
        end
    end

    return table.concat(rows, ""):gsub("\n$", "")
end

function M.hide()
    if notification then
        naughty.destroy(notification)
        notification = nil
    end
end

function M.show(seconds, options, month, year, screen_obj)
    options = options or {}
    local now = os.date("*t")
    current_month = month or current_month or now.month
    current_year = year or current_year or now.year
    preset = options.notification_preset or preset or {}

    local text = build(current_month, current_year, {
        bg = preset.bg,
        week_start = options.week_start,
        week_number = options.week_number,
    })

    if notification then
        naughty.replace_text(notification, nil, text)
        return
    end

    notification = naughty.notify({
        preset = preset,
        app_name = "Calendar",
        screen = options.followtag and awful.screen.focused() or screen_obj or 1,
        timeout = type(seconds) == "number" and seconds or preset.timeout or 5,
        text = text,
    })
end

function M.move(offset, options)
    local now = os.date("*t")
    current_month = current_month or now.month
    current_year = current_year or now.year
    current_month, current_year = getdate(current_month, current_year, offset or 0)
    M.show(0, options)
end

function M.attach(widgets, options)
    options = options or {}

    for _, widget in ipairs(widgets or {}) do
        widget:connect_signal("mouse::enter", function()
            current_month = nil
            current_year = nil
            M.show(0, options)
        end)
        widget:connect_signal("mouse::leave", M.hide)
        widget:buttons(awful.util.table.join(
            awful.button({}, 1, function() M.move(-1, options) end),
            awful.button({}, 2, function() M.show(0, options) end),
            awful.button({}, 3, function() M.move(1, options) end),
            awful.button({}, 4, function() M.move(1, options) end),
            awful.button({}, 5, function() M.move(-1, options) end)
        ))
    end
end

return M
