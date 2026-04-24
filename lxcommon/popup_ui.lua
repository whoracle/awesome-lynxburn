local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")

local M = {}

-- Shared popup card primitive used by multiple popup modules.
function M.make_card(child, opts)
    opts = opts or {}

    return wibox.widget({
        {
            child,
            margins = opts.margins or 0,
            widget = wibox.container.margin,
        },
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, opts.radius or 0)
        end,
        widget = wibox.container.background,
    })
end

---Create a textbox widget with shared lightweight defaults.
function M.make_text(text, opts)
    opts = opts or {}

    return wibox.widget({
        markup = text or "",
        ellipsize = opts.ellipsize,
        valign = opts.valign,
        widget = wibox.widget.textbox,
    })
end

-- Shared text row primitive with padding and optional fixed height.
function M.make_info_line(text, opts)
    opts = opts or {}

    local row = wibox.widget({
        {
            M.make_text(text, opts.text_opts),
            left = opts.left or 12,
            right = opts.right or 8,
            top = opts.top or 2,
            bottom = opts.bottom or 2,
            widget = wibox.container.margin,
        },
        widget = wibox.container.background,
    })

    row.forced_height = opts.forced_height or row.forced_height
    return row
end

---Attach hover/press/active-state feedback to a background widget.
function M.attach_button_feedback(widget, opts)
    opts = opts or {}

    if not widget then
        return
    end

    local idle_bg = opts.idle_bg
    local hover_bg = opts.hover_bg
    local press_bg = opts.press_bg or hover_bg
    local pointer_inside = false
    local pressed = false
    local active = false

    local function sync_bg()
        if pressed then
            widget.bg = press_bg
        elseif pointer_inside or active then
            widget.bg = hover_bg
        else
            widget.bg = idle_bg
        end
    end

    widget.bg = idle_bg

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

-- Shared clickable row/container primitive that supports left click, right
-- click, middle click, and scroll actions.
function M.make_click_container(child, onclick, opts)
    opts = opts or {}

    local bg = wibox.widget({
        {
            child,
            left = opts.left or 8,
            right = opts.right or 8,
            top = opts.top or 6,
            bottom = opts.bottom or 6,
            widget = wibox.container.margin,
        },
        widget = wibox.container.background,
    })

    bg.forced_height = opts.forced_height or bg.forced_height

    if not (onclick or opts.on_right_click or opts.on_middle_click or opts.on_scroll_up or opts.on_scroll_down) then
        return bg
    end

    local buttons = {}
    M.attach_button_feedback(bg, {
        idle_bg = opts.idle_bg,
        hover_bg = opts.hover_bg,
        press_bg = opts.press_bg,
    })

    if onclick then
        buttons[#buttons + 1] = awful.button({}, 1, onclick)
    end

    if opts.on_right_click then
        buttons[#buttons + 1] = awful.button({}, 3, opts.on_right_click)
    end

    if opts.on_middle_click then
        buttons[#buttons + 1] = awful.button({}, 2, opts.on_middle_click)
    end

    if opts.on_scroll_up then
        buttons[#buttons + 1] = awful.button({}, 4, opts.on_scroll_up)
    end

    if opts.on_scroll_down then
        buttons[#buttons + 1] = awful.button({}, 5, opts.on_scroll_down)
    end

    bg:buttons(gears.table.join(table.unpack(buttons)))
    return bg
end

---Build a clickable text row using the shared click-container helper.
function M.make_click_row(text, onclick, opts)
    opts = opts or {}
    return M.make_click_container(M.make_text(text, opts.text_opts), onclick, opts)
end

---Build a clickable container with separate inner hover and outer selection bg.
function M.make_selectable_click_container(child, onclick, opts)
    opts = opts or {}

    local inner = M.make_click_container(child, onclick, {
        left = opts.left,
        right = opts.right,
        top = opts.top,
        bottom = opts.bottom,
        forced_height = opts.forced_height,
        idle_bg = opts.inner_bg,
        hover_bg = opts.hover_bg,
        press_bg = opts.press_bg,
        on_right_click = opts.on_right_click,
        on_middle_click = opts.on_middle_click,
        on_scroll_up = opts.on_scroll_up,
        on_scroll_down = opts.on_scroll_down,
    })

    local selection_margin = opts.selection_margin or 2
    local selection_wrapper = wibox.widget({
        inner,
        margins = opts.selected and selection_margin or 0,
        widget = wibox.container.margin,
    })

    local outer = wibox.widget({
        selection_wrapper,
        bg = opts.selected and opts.selected_bg or opts.outer_bg,
        shape = opts.shape or gears.shape.rounded_rect,
        widget = wibox.container.background,
    })

    function outer:_lx_set_selected(selected)
        selection_wrapper.margins = selected and selection_margin or 0
        outer.bg = selected and opts.selected_bg or opts.outer_bg
    end

    if type(opts.on_hover) == "function" then
        outer:connect_signal("mouse::enter", function()
            opts.on_hover()
        end)
    end

    return outer
end

---Build a selectable clickable text row using the shared popup primitives.
function M.make_selectable_click_row(text, onclick, opts)
    opts = opts or {}
    return M.make_selectable_click_container(M.make_text(text, opts.text_opts), onclick, opts)
end

return M
