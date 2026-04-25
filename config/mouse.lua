local awful = require("awful")
local gears = require("gears")
local popup_session = require("lxcommon.popup_session")

local M = {}

---Build root, client, taglist, and tasklist mouse bindings.
---@param context {my_table:any,terminal:string,modkey:string}
---@return {mousebuttons:any, clientbuttons:any}
function M.build(context)
    local my_table = context.my_table or gears.table
    local terminal = context.terminal
    local modkey = context.modkey
    local function open_terminal()
        popup_session.close_active()
        awful.spawn(terminal)
    end

    local mousebuttons = my_table.join(
        awful.button({}, 4, awful.tag.viewnext),
        awful.button({}, 5, awful.tag.viewprev),
        awful.button({}, 10, open_terminal)
    )

    local clientbuttons = my_table.join(
        awful.button({}, 1, function(c)
            client.focus = c
            c:raise()
        end),
        awful.button({ modkey }, 1, awful.mouse.client.move),
        awful.button({ modkey }, 3, awful.mouse.client.resize),
        awful.button({}, 10, open_terminal)
    )

    awful.util.taglist_buttons = my_table.join(
        awful.button({}, 1, function(t) t:view_only() end),
        awful.button({ modkey }, 1, function(t)
            if client.focus then
                client.focus:move_to_tag(t)
            end
        end),
        awful.button({}, 3, awful.tag.viewtoggle),
        awful.button({ modkey }, 3, function(t)
            if client.focus then
                client.focus:toggle_tag(t)
            end
        end),
        awful.button({}, 4, function(t) awful.tag.viewnext(t.screen) end),
        awful.button({}, 5, function(t) awful.tag.viewprev(t.screen) end)
    )

    awful.util.tasklist_buttons = my_table.join(
        awful.button({}, 1, function(c)
            if c == client.focus then
                c.minimized = true
            else
                c.minimized = false
                if not c:isvisible() and c.first_tag then
                    c.first_tag:view_only()
                end
                client.focus = c
                c:raise()
            end
        end),
        awful.button({}, 3, function()
            local instance = awful.menu.clients({ theme = { width = 250 } })
            if instance then
                instance:show()
            end
        end),
        awful.button({}, 4, function() awful.client.focus.byidx(1) end),
        awful.button({}, 5, function() awful.client.focus.byidx(-1) end)
    )

    return {
        mousebuttons = mousebuttons,
        clientbuttons = clientbuttons,
    }
end

return M
