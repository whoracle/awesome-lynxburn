local naughty = require("naughty")
local wibox = require("wibox")

local M = {}

---Create the remaining generic text OSD helpers owned by the main config.
---
---Volume and brightness OSD ownership has moved into `lxaudio` and
---`lxdisplay`. This module intentionally remains narrow.
---@param beautiful table
---@param _options table
---@return table
function M.new(beautiful, _options)
    local osd_timeout = 1

    local text_osd = {
        notification = nil,
        box = nil,
        hide_timer = nil,
    }

    local display_text = wibox.widget({
        align = "center",
        valign = "center",
        forced_width = 260,
        widget = wibox.widget.textbox,
    })

    local function destroy_osd(osd)
        if osd.hide_timer then
            osd.hide_timer:stop()
            osd.hide_timer = nil
        end

        if osd.notification then
            osd.notification:destroy()
            osd.notification = nil
        end

        osd.box = nil
    end

    local function build_box(state, widget_template, app_name)
        state.notification = naughty.notification({
            title = "",
            message = "",
            app_name = app_name,
            timeout = 0,
            position = "bottom_middle",
            ontop = true,
            screen = screen.primary,
        })

        state.box = naughty.layout.box({
            notification = state.notification,
            position = "bottom_middle",
            screen = screen.primary,
            widget_template = widget_template,
        })

        state.box.width = 260 + (16 * 2)
        state.box.visible = false

        state.notification:connect_signal("destroyed", function()
            state.notification = nil
            state.box = nil
        end)
    end

    local function ensure_text_osd(app_name)
        if text_osd.box then
            return
        end

        build_box(text_osd, {
            {
                {
                    {
                        {
                            display_text,
                            widget = wibox.container.place,
                        },
                        widget = wibox.container.place,
                    }
                },
                margins = osd_margin,
                widget = wibox.container.margin,
            },
            bg = beautiful.notification_bg or beautiful.bg_normal or "#111111",
            fg = beautiful.notification_fg or beautiful.fg_normal or "#ffffff",
            widget = wibox.container.background,
        }, app_name)
    end

    local function show_text_osd(text, app_name)
        ensure_text_osd(app_name or "")

        display_text.text = text
        text_osd.box.screen = screen.primary
        text_osd.box.visible = true

        if text_osd.hide_timer then
            text_osd.hide_timer:stop()
        end

        text_osd.hide_timer = gears.timer.start_new(osd_timeout, function()
            destroy_osd(text_osd)
            return false
        end)
    end

    return {
        show_notifications_state = function(suspended)
            if suspended then
                show_text_osd("Notifications suspended", "Notification Indicator")
            else
                show_text_osd("Notifications resumed", "Notification Indicator")
            end
        end,
    }
end

return M
