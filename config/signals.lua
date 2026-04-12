local awful = require("awful")
local wibox = require("wibox")

local M = {}

function M.setup(context)
    local beautiful = context.beautiful
    local my_table = context.my_table

    client.connect_signal("manage", function(c)
        if awesome.startup
            and not c.size_hints.user_position
            and not c.size_hints.program_position
        then
            awful.placement.no_offscreen(c)
        end
    end)

    client.connect_signal("request::titlebars", function(c)
        if beautiful.titlebar_fun then
            beautiful.titlebar_fun(c)
            return
        end

        local buttons = my_table.join(
            awful.button({}, 1, function()
                client.focus = c
                c:raise()
                awful.mouse.client.move(c)
            end),
            awful.button({}, 3, function()
                client.focus = c
                c:raise()
                awful.mouse.client.resize(c)
            end)
        )

        awful.titlebar(c, { size = 16 }):setup({
            {
                awful.titlebar.widget.iconwidget(c),
                buttons = buttons,
                layout = wibox.layout.fixed.horizontal,
            },
            {
                {
                    align = "center",
                    widget = awful.titlebar.widget.titlewidget(c),
                },
                buttons = buttons,
                layout = wibox.layout.flex.horizontal,
            },
            {
                awful.titlebar.widget.floatingbutton(c),
                awful.titlebar.widget.maximizedbutton(c),
                awful.titlebar.widget.stickybutton(c),
                awful.titlebar.widget.ontopbutton(c),
                awful.titlebar.widget.closebutton(c),
                layout = wibox.layout.fixed.horizontal(),
            },
            layout = wibox.layout.align.horizontal,
        })
    end)

    local function border_adjust(c)
        if c.maximized then
            c.border_width = 0
        elseif #awful.screen.focused().clients > 1 then
            c.border_width = beautiful.border_width
            c.border_color = beautiful.border_focus
        end
    end

    client.connect_signal("focus", border_adjust)
    client.connect_signal("property::maximized", border_adjust)
    client.connect_signal("unfocus", function(c)
        c.border_color = beautiful.border_normal
    end)
end

return M
