local awful = require("awful")

local bindings = require("config.keys.bindings")

local M = {}

local function view_tag(i)
    return function()
        local focused_screen = awful.screen.focused()
        local selected_tag = focused_screen.tags[i]

        if selected_tag then
            selected_tag:view_only()
        end
    end
end

local function toggle_tag_view(i)
    return function()
        local focused_screen = awful.screen.focused()
        local selected_tag = focused_screen.tags[i]

        if selected_tag then
            awful.tag.viewtoggle(selected_tag)
        end
    end
end

local function move_focused_to_tag(i)
    return function()
        if client.focus then
            local selected_tag = client.focus.screen.tags[i]

            if selected_tag then
                client.focus:move_to_tag(selected_tag)
            end
        end
    end
end

local function toggle_focused_on_tag(i)
    return function()
        if client.focus then
            local selected_tag = client.focus.screen.tags[i]

            if selected_tag then
                client.focus:toggle_tag(selected_tag)
            end
        end
    end
end

function M.extend(actions, global_specs, global_spec_order, settings)
    for i = 1, 9 do
        local descr_view
        local descr_toggle
        local descr_move
        local descr_toggle_focus

        if i == 1 or i == 9 then
            descr_view = "view tag #"
            descr_toggle = "toggle tag #"
            descr_move = "move focused client to tag #"
            descr_toggle_focus = "toggle focused client on tag #"
        end

        actions["view_tag_" .. i] = view_tag(i)
        actions["toggle_tag_view_" .. i] = toggle_tag_view(i)
        actions["move_focused_to_tag_" .. i] = move_focused_to_tag(i)
        actions["toggle_focused_on_tag_" .. i] = toggle_focused_on_tag(i)

        global_spec_order[#global_spec_order + 1] = "desktop_view_tag_" .. i
        global_spec_order[#global_spec_order + 1] = "desktop_toggle_tag_" .. i
        global_spec_order[#global_spec_order + 1] = "desktop_move_focused_to_tag_" .. i
        global_spec_order[#global_spec_order + 1] = "desktop_toggle_focused_on_tag_" .. i

        global_specs["desktop_view_tag_" .. i] =
            bindings.key_spec({ settings.modkey }, "#" .. i + 9, "view_tag_" .. i, descr_view, "02. desktop")
        global_specs["desktop_toggle_tag_" .. i] =
            bindings.key_spec({ settings.modkey, settings.ctrlkey }, "#" .. i + 9, "toggle_tag_view_" .. i, descr_toggle, "02. desktop")
        global_specs["desktop_move_focused_to_tag_" .. i] =
            bindings.key_spec({ settings.modkey, settings.shiftkey }, "#" .. i + 9, "move_focused_to_tag_" .. i, descr_move, "02. desktop")
        global_specs["desktop_toggle_focused_on_tag_" .. i] =
            bindings.key_spec({ settings.modkey, settings.ctrlkey, settings.shiftkey }, "#" .. i + 9, "toggle_focused_on_tag_" .. i, descr_toggle_focus, "02. desktop")
    end
end

return M
