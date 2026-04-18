local awful = require("awful")
local gears = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local helpers = require("config.helpers")
local config_data = require("config.config_data")

local M = {}

local unpack = table.unpack or unpack

---Register a small set of non-Awesome default hotkey hints for the popup.
local function register_extra_hotkeys()
    local extra_rule = { class = { "sublime_text", "Sublime_text" } }

    hotkeys_popup.group_rules["Sublime Text 3"] = {
        color = "#659FdF",
        rule_any = extra_rule,
    }

    hotkeys_popup.add_hotkeys({
        ["Sublime Text 3"] = {
            {
                modifiers = { "Mod4" },
                keys = {
                    F11 = "Distraction Free Mode",
                },
            },
        },
    })
end

local function key_spec(modifiers, key, on_press, description, group, extra)
    local spec = {
        modifiers = modifiers,
        key = key,
        on_press = on_press,
        description = description,
        group = group,
    }

    if type(extra) == "table" then
        helpers.deep_merge(spec, extra)
    end

    return spec
end

local function resolve_modifier_alias(settings, modifier)
    if modifier == "modkey" then
        return settings.modkey
    end

    if modifier == "altkey" then
        return settings.altkey
    end

    if modifier == "ctrlkey" then
        return settings.ctrlkey
    end

    if modifier == "shiftkey" then
        return settings.shiftkey
    end

    return modifier
end

local function normalize_key_spec(settings, spec)
    if type(spec) ~= "table" then
        return spec
    end

    local normalized = {}

    for key, value in pairs(spec) do
        normalized[key] = value
    end

    if type(spec.modifiers) == "table" then
        normalized.modifiers = {}

        for index, modifier in ipairs(spec.modifiers) do
            normalized.modifiers[index] = resolve_modifier_alias(settings, modifier)
        end
    end

    return normalized
end

local function normalize_key_specs(settings, specs)
    local normalized = {}

    for name, spec in pairs(specs or {}) do
        normalized[name] = normalize_key_spec(settings, spec)
    end

    return normalized
end

local function sorted_extra_names(specs, ordered_names)
    local seen = {}

    for _, name in ipairs(ordered_names) do
        seen[name] = true
    end

    local extra_names = {}

    for name in pairs(specs) do
        if not seen[name] then
            extra_names[#extra_names + 1] = name
        end
    end

    table.sort(extra_names)

    return extra_names
end

local function resolve_action(actions, action_name, binding_name, phase)
    if action_name == nil then
        return nil
    end

    if type(action_name) == "function" then
        return action_name
    end

    local action = actions[action_name]

    if type(action) ~= "function" then
        error(string.format("Unknown %s action '%s' for key binding '%s'", phase, tostring(action_name), binding_name))
    end

    return action
end

local function build_key_object(binding_name, spec, actions)
    if spec.disabled then
        return nil
    end

    local metadata = {}

    for key, value in pairs(spec) do
        if key ~= "disabled"
            and key ~= "key"
            and key ~= "modifiers"
            and key ~= "on_press"
            and key ~= "on_release" then
            metadata[key] = value
        end
    end

    return awful.key(
        spec.modifiers or {},
        spec.key,
        resolve_action(actions, spec.on_press, binding_name, "press"),
        resolve_action(actions, spec.on_release, binding_name, "release"),
        metadata
    )
end

local function compile_key_specs(specs, ordered_names, actions, join)
    local keys = {}

    for _, name in ipairs(ordered_names) do
        local spec = specs[name]

        if spec then
            local key = build_key_object(name, spec, actions)

            if key then
                keys[#keys + 1] = key
            end
        end
    end

    for _, name in ipairs(sorted_extra_names(specs, ordered_names)) do
        local key = build_key_object(name, specs[name], actions)

        if key then
            keys[#keys + 1] = key
        end
    end

    return join(unpack(keys))
end

local function build_lxaudio_popup_key_actions(global_specs)
    local popup_bindings = {
        media_toggle_play_pause = true,
        media_next_media_item = true,
        media_prev_media_item = true,
        media_volume_up = true,
        media_volume_down = true,
        media_toggle_mute = true,
    }

    local popup_actions = {}

    for binding_name in pairs(popup_bindings) do
        local spec = global_specs[binding_name]
        if spec and not spec.disabled and type(spec.key) == "string" and type(spec.on_press) == "string" then
            popup_actions[spec.key] = spec.on_press
        end
    end

    return popup_actions
end

local function same_modifiers(left, right)
    if #left ~= #right then
        return false
    end

    local seen = {}

    for _, modifier in ipairs(left) do
        seen[modifier] = (seen[modifier] or 0) + 1
    end

    for _, modifier in ipairs(right) do
        if not seen[modifier] then
            return false
        end

        seen[modifier] = seen[modifier] - 1
        if seen[modifier] < 0 then
            return false
        end
    end

    return true
end

local function has_binding(specs, modifiers, key)
    for _, spec in pairs(specs) do
        if not spec.disabled
            and spec.key == key
            and same_modifiers(spec.modifiers or {}, modifiers or {}) then
            return true
        end
    end

    return false
end

---Build root and client keymaps from the shared config context.
---
---This module intentionally owns only keybinding definitions and their local
---helper functions. Application commands live in `programs.lua`, and long-lived
---widget/module state is passed in through `context`.
---@param context table
---@return {globalkeys:any, clientkeys:any}
function M.build(context)
    local my_table = context.my_table or gears.table
    local settings = context.settings
    local programs = context.programs
    local lxnotify = context.lxnotify
    local lxaudio = context.lxaudio
    local lxbar = context.lxbar
    local lxbluetooth = context.lxbluetooth
    local lxdisplay = context.lxdisplay
    local lxnetwork = context.lxnetwork
    local lxrunner = context.lxrunner
    local lxpowerprofiles = context.lxpowerprofiles
    local osd = context.osd
    local lain = context.lain
    local key_config = config_data.keys()

    register_extra_hotkeys()

    local function toggle_notifications()
        lxnotify:toggle_suspend()
        osd.show_notifications_state(require("naughty").suspended)
    end

    local function restore_minimized()
        local c = awful.client.restore()
        if c then
            client.focus = c
            c:raise()
        end
    end

    local function cycle_focus()
        awful.client.focus.byidx(-1)
        if client.focus then
            client.focus:raise()
        end
    end

    local function swap_by_direction(direction)
        return function()
            awful.client.swap.bydirection(direction)
        end
    end

    local function focus_by_direction(direction)
        return function()
            awful.client.focus.global_bydirection(direction)
            if client.focus then
                client.focus:raise()
            end
        end
    end

    local function next_layout()
        awful.layout.inc(1)
    end

    local function prev_layout()
        awful.layout.inc(-1)
    end

    local function grow_gaps()
        lain.util.useless_gaps_resize(1)
    end

    local function shrink_gaps()
        lain.util.useless_gaps_resize(-1)
    end

    local function show_media_popup()
        lxbar:toggle_popup_by_role("audio", "primary", {
            hover_close = false,
            anchor = "center",
            toggle_key = { modifiers = { settings.modkey }, key = "Prior" },
        })
    end

    local function show_notification_popup()
        lxbar:toggle_popup_by_role("notify", "primary", {
            hover_close = false,
            toggle_key = { modifiers = { settings.modkey }, key = "Next" },
        })
    end

    local function show_bluetooth_popup()
        if lxbluetooth then
            lxbar:toggle_popup_by_role("bluetooth", "primary", {
                keyboard_navigation = true,
                toggle_key = { modifiers = { settings.modkey }, key = "F10" },
            })
        end
    end

    local function show_network_popup()
        if lxnetwork then
            lxbar:toggle_popup_by_role("network", "primary", {
                keyboard_navigation = true,
                toggle_key = { modifiers = { settings.modkey }, key = "F11" },
            })
        end
    end

    local function show_powerprofiles_popup()
        if lxpowerprofiles then
            lxbar:toggle_popup_by_role("powerprofiles", "secondary", {
                keyboard_navigation = true,
                toggle_key = { modifiers = { settings.modkey }, key = "F12" },
            })
        end
    end

    local function cycle_lxbar_popups_forward()
        if lxbar then
            lxbar:cycle_popups(1, { keyboard_navigation = true })
        end
    end

    local function cycle_lxbar_popups_backward()
        if lxbar then
            lxbar:cycle_popups(-1, { keyboard_navigation = true })
        end
    end

    local function show_calendar()
        lain.widget.calendar.show(7)
    end

    local function open_launcher()
        awful.spawn(programs.launcher)
    end

    local function toggle_lxrunner()
        lxrunner:toggle()
    end

    local function open_terminal()
        awful.spawn(programs.terminal)
    end

    local function open_file_browser()
        awful.spawn(programs.filebrowser .. " " .. settings.home)
    end

    local function screenshot_region()
        awful.spawn.with_shell(programs.scrotmouse, false)
    end

    local function screenshot_desktop()
        awful.spawn.with_shell(programs.scrotedit, false)
    end

    local function screenshot_window()
        awful.spawn.with_shell(programs.scrotwin, false)
    end

    local function start_awesome_on_tv()
        os.execute("export DISPLAY=:0.1 && awesome &")
    end

    local function lock_screen()
        os.execute(programs.scrlocker)
    end

    local function media_play_pause()
        awful.spawn("playerctl play-pause", false)
    end

    local function media_next()
        awful.spawn("playerctl next", false)
    end

    local function media_prev()
        awful.spawn("playerctl previous", false)
    end

    local function volume_up()
        lxaudio:volume_up(nil, { show_osd = true })
    end

    local function volume_down()
        lxaudio:volume_down(nil, { show_osd = true })
    end

    local function toggle_mute()
        lxaudio:toggle_mute({ show_osd = true })
    end

    local function brightness_up()
        lxdisplay:brightness_up(nil, { show_osd = true })
    end

    local function brightness_down()
        lxdisplay:brightness_down(nil, { show_osd = true })
    end

    local function brightness_off()
        lxdisplay:brightness_off()
    end

    local function kill_client(c)
        c:kill()
    end

    local function move_to_screen(c)
        c:move_to_screen()
    end

    local function move_to_left_screen(c)
        c:move_to_screen(c.screen.index - 1)
    end

    local function move_to_right_screen(c)
        c:move_to_screen(c.screen.index + 1)
    end

    local function toggle_titlebar(c)
        awful.titlebar.toggle(c)
    end

    local function minimize_client(c)
        c.minimized = true
    end

    local function maximize_client(c)
        c.maximized = not c.maximized
        c:raise()
    end

    local function toggle_quake()
        context.quake:toggle()
    end

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

    local actions = {
        toggle_quake = toggle_quake,
        jump_to_urgent_client = awful.client.urgent.jumpto,
        restore_minimized = restore_minimized,
        cycle_focus = cycle_focus,
        swap_right = swap_by_direction("right"),
        swap_left = swap_by_direction("left"),
        swap_up = swap_by_direction("up"),
        swap_down = swap_by_direction("down"),
        focus_down = focus_by_direction("down"),
        focus_up = focus_by_direction("up"),
        focus_left = focus_by_direction("left"),
        focus_right = focus_by_direction("right"),
        view_previous_tag = awful.tag.viewprev,
        view_next_tag = awful.tag.viewnext,
        restore_tag_history = awful.tag.history.restore,
        next_layout = next_layout,
        prev_layout = prev_layout,
        grow_gaps = grow_gaps,
        shrink_gaps = shrink_gaps,
        show_media_popup = show_media_popup,
        show_notification_popup = show_notification_popup,
        show_bluetooth_popup = show_bluetooth_popup,
        show_network_popup = show_network_popup,
        show_powerprofiles_popup = show_powerprofiles_popup,
        cycle_lxbar_popups_forward = cycle_lxbar_popups_forward,
        cycle_lxbar_popups_backward = cycle_lxbar_popups_backward,
        show_calendar = show_calendar,
        toggle_lxrunner = toggle_lxrunner,
        open_launcher = open_launcher,
        open_terminal = open_terminal,
        open_file_browser = open_file_browser,
        screenshot_region = screenshot_region,
        screenshot_desktop = screenshot_desktop,
        screenshot_window = screenshot_window,
        start_awesome_on_tv = start_awesome_on_tv,
        lock_screen = lock_screen,
        media_play_pause = media_play_pause,
        media_next = media_next,
        media_prev = media_prev,
        volume_up = volume_up,
        volume_down = volume_down,
        toggle_mute = toggle_mute,
        brightness_up = brightness_up,
        brightness_down = brightness_down,
        brightness_off = brightness_off,
        show_help = hotkeys_popup.show_help,
        awesome_reload = awesome.restart,
        awesome_restart = awesome.restart,
        awesome_quit = awesome.quit,
        toggle_notifications = toggle_notifications,
        kill_client = kill_client,
        toggle_floating = awful.client.floating.toggle,
        move_to_screen = move_to_screen,
        move_to_left_screen = move_to_left_screen,
        move_to_right_screen = move_to_right_screen,
        toggle_titlebar = toggle_titlebar,
        minimize_client = minimize_client,
        maximize_client = maximize_client,
    }

    local global_spec_order = {}
    local client_spec_order = {}
    local global_specs = normalize_key_specs(settings, key_config.global)
    local client_specs = normalize_key_specs(settings, key_config.client)

    for _, name in ipairs(key_config.global_order or {}) do
        global_spec_order[#global_spec_order + 1] = name
    end

    for _, name in ipairs(key_config.client_order or {}) do
        client_spec_order[#client_spec_order + 1] = name
    end

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

        global_specs["desktop_view_tag_" .. i] = key_spec({ settings.modkey }, "#" .. i + 9, "view_tag_" .. i, descr_view, "02. desktop")
        global_specs["desktop_toggle_tag_" .. i] = key_spec({ settings.modkey, settings.ctrlkey }, "#" .. i + 9, "toggle_tag_view_" .. i, descr_toggle, "02. desktop")
        global_specs["desktop_move_focused_to_tag_" .. i] = key_spec({ settings.modkey, settings.shiftkey }, "#" .. i + 9, "move_focused_to_tag_" .. i, descr_move, "02. desktop")
        global_specs["desktop_toggle_focused_on_tag_" .. i] = key_spec({ settings.modkey, settings.ctrlkey, settings.shiftkey }, "#" .. i + 9, "toggle_focused_on_tag_" .. i, descr_toggle_focus, "02. desktop")
    end

    if not has_binding(global_specs, { settings.modkey, settings.altkey, settings.ctrlkey }, "Left")
        and not has_binding(client_specs, { settings.modkey, settings.altkey, settings.ctrlkey }, "Left") then
        global_spec_order[#global_spec_order + 1] = "programs_cycle_lxbar_popups_backward"
        global_specs.programs_cycle_lxbar_popups_backward =
            key_spec(
                { settings.modkey, settings.altkey, settings.ctrlkey },
                "Left",
                "cycle_lxbar_popups_backward",
                "cycle lxbar popups backward",
                "04. programs"
            )
    end

    if not has_binding(global_specs, { settings.modkey, settings.altkey, settings.ctrlkey }, "Right")
        and not has_binding(client_specs, { settings.modkey, settings.altkey, settings.ctrlkey }, "Right") then
        global_spec_order[#global_spec_order + 1] = "programs_cycle_lxbar_popups_forward"
        global_specs.programs_cycle_lxbar_popups_forward =
            key_spec(
                { settings.modkey, settings.altkey, settings.ctrlkey },
                "Right",
                "cycle_lxbar_popups_forward",
                "cycle lxbar popups forward",
                "04. programs"
            )
    end

    if lxaudio and lxaudio.set_popup_key_actions then
        lxaudio:set_popup_key_actions(build_lxaudio_popup_key_actions(global_specs))
    end

    local keymaps = {
        globalkeys = compile_key_specs(global_specs, global_spec_order, actions, my_table.join),
        clientkeys = compile_key_specs(client_specs, client_spec_order, actions, my_table.join),
    }

    return keymaps
end

return M
