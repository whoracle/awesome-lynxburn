local awful = require("awful")
local gears = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local helpers = require("config.helpers")

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
    local key_overrides = helpers.load_optional_module("config.override.keys", {})

    local grp_names = {
        "01. window",
        "02. desktop",
        "03. layout",
        "04. programs",
        "05. media",
        "08. awesomewm",
        "09. system",
    }

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
        lxaudio:toggle_media_popup(nil, {
            hover_close = false,
            anchor = "center",
            toggle_key = { modifiers = { settings.modkey }, key = "Prior" },
        })
    end

    local function show_notification_popup()
        lxnotify:toggle_notification_popup({
            hover_close = false,
            toggle_key = { modifiers = { settings.modkey }, key = "Next" },
        })
    end

    local function show_bluetooth_popup()
        if lxbluetooth then
            lxbluetooth:toggle_popup(nil, {
                keyboard_navigation = true,
                toggle_key = { modifiers = { settings.modkey }, key = "F10" },
            })
        end
    end

    local function show_network_popup()
        if lxnetwork then
            lxnetwork:toggle_popup(nil, {
                keyboard_navigation = true,
                toggle_key = { modifiers = { settings.modkey }, key = "F11" },
            })
        end
    end

    local function show_powerprofiles_popup()
        if lxpowerprofiles then
            lxpowerprofiles:toggle_popup(nil, {
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

    local global_spec_order = {
        "window_jump_to_urgent_client",
        "window_restore_minimized_program",
        "window_focus_next_by_index",
        "window_focus_previous_by_index",
        "window_swap_with_left_client",
        "window_swap_with_right_client",
        "window_swap_with_upper_client",
        "window_swap_with_lower_client",
        "window_focus_down",
        "window_focus_up",
        "window_focus_left",
        "window_focus_right",
        "desktop_view_previous",
        "desktop_view_next",
        "desktop_go_back",
        "layout_select_next_layout",
        "layout_select_prev_layout",
        "layout_increment_useless_gaps",
        "layout_decrement_useless_gaps",
        "programs_show_media_popup",
        "programs_show_notification_popup",
        "programs_show_bluetooth_popup",
        "programs_show_network_popup",
        "programs_show_powerprofiles_popup",
        "programs_show_calendar",
        "programs_lxrunner",
        "programs_launcher",
        "programs_terminal",
        "programs_file_browser",
        "programs_screenshot_region",
        "programs_screenshot_desktop",
        "programs_screenshot_window",
        "programs_start_awesome_on_tv",
        "programs_lock_screen_alt_ctrl_l",
        "programs_lock_screen_mod_alt_f12",
        "media_toggle_play_pause",
        "media_next_media_item",
        "media_prev_media_item",
        "media_volume_up",
        "media_volume_down",
        "media_toggle_mute",
        "media_brightness_up",
        "media_brightness_down",
        "media_display_off",
        "awesome_show_help",
        "awesome_reload_alt_ctrl_r",
        "awesome_reload_mod_ctrl_r",
        "awesome_quit",
        "system_toggle_notifications",
        "system_lock_screen",
    }

    local global_specs = {
        programs_quake_terminal = key_spec({ settings.modkey }, "dead_circumflex", "toggle_quake", "quake terminal", grp_names[4]),
        window_jump_to_urgent_client = key_spec({ settings.modkey }, "u", "jump_to_urgent_client", "jump to urgent client", grp_names[1]),
        window_restore_minimized_program = key_spec({ settings.modkey, settings.ctrlkey }, "n", "restore_minimized", "restore minimized program", grp_names[1]),
        window_focus_next_by_index = key_spec({ settings.modkey }, "Tab", "cycle_focus", "focus next by index", grp_names[1]),
        window_focus_previous_by_index = key_spec({ settings.modkey, settings.shiftkey }, "Tab", "cycle_focus", "focus previous by index", grp_names[1]),
        window_swap_with_left_client = key_spec({ settings.modkey, settings.ctrlkey }, "Right", "swap_right", "swap with left client", grp_names[1]),
        window_swap_with_right_client = key_spec({ settings.modkey, settings.ctrlkey }, "Left", "swap_left", "swap with right client", grp_names[1]),
        window_swap_with_upper_client = key_spec({ settings.modkey, settings.ctrlkey }, "Up", "swap_up", "swap with upper client", grp_names[1]),
        window_swap_with_lower_client = key_spec({ settings.modkey, settings.ctrlkey }, "Down", "swap_down", "swap with lower client", grp_names[1]),
        window_focus_down = key_spec({ settings.modkey }, "Down", "focus_down", "focus down", grp_names[1]),
        window_focus_up = key_spec({ settings.modkey }, "Up", "focus_up", "focus up", grp_names[1]),
        window_focus_left = key_spec({ settings.modkey }, "Left", "focus_left", "focus left", grp_names[1]),
        window_focus_right = key_spec({ settings.modkey }, "Right", "focus_right", "focus right", grp_names[1]),
        desktop_view_previous = key_spec({ settings.altkey, settings.ctrlkey }, "Left", "view_previous_tag", "view previous", grp_names[2]),
        desktop_view_next = key_spec({ settings.altkey, settings.ctrlkey }, "Right", "view_next_tag", "view next", grp_names[2]),
        desktop_go_back = key_spec({ settings.modkey, settings.altkey }, "Escape", "restore_tag_history", "go back", grp_names[2]),
        layout_select_next_layout = key_spec({ settings.modkey }, "space", "next_layout", "select next layout", grp_names[3]),
        layout_select_prev_layout = key_spec({ settings.modkey, settings.shiftkey }, "space", "prev_layout", "select prev layout", grp_names[3]),
        layout_increment_useless_gaps = key_spec({ settings.modkey, settings.ctrlkey }, "+", "grow_gaps", "increment useless gaps", grp_names[3]),
        layout_decrement_useless_gaps = key_spec({ settings.modkey, settings.ctrlkey }, "-", "shrink_gaps", "decrement useless gaps", grp_names[3]),
        programs_show_media_popup = key_spec({ settings.modkey }, "Prior", "show_media_popup", "show media popup", grp_names[4]),
        programs_show_notification_popup = key_spec({ settings.modkey }, "Next", "show_notification_popup", "show notification popup", grp_names[4]),
        programs_show_bluetooth_popup = key_spec({ settings.modkey }, "F10", "show_bluetooth_popup", "show bluetooth popup", grp_names[4]),
        programs_show_network_popup = key_spec({ settings.modkey }, "F11", "show_network_popup", "show network popup", grp_names[4]),
        programs_show_powerprofiles_popup = key_spec({ settings.modkey }, "F12", "show_powerprofiles_popup", "show power profiles popup", grp_names[4]),
        programs_show_calendar = key_spec({ settings.modkey }, "c", "show_calendar", "show calendar", grp_names[4]),
        programs_lxrunner = key_spec({ settings.altkey }, "F2", "toggle_lxrunner", "lxrunner", grp_names[4]),
        programs_launcher = key_spec({ settings.altkey }, "F3", "open_launcher", "launcher", grp_names[4]),
        programs_terminal = key_spec({ settings.modkey }, "q", "open_terminal", "terminal", grp_names[4]),
        programs_file_browser = key_spec({ settings.modkey }, "e", "open_file_browser", "file browser", grp_names[4]),
        programs_screenshot_region = key_spec({ settings.modkey }, "p", "screenshot_region", "screenshot of region", grp_names[4]),
        programs_screenshot_desktop = key_spec({ settings.altkey, settings.ctrlkey }, "p", "screenshot_desktop", "screenshot of desktop", grp_names[4]),
        programs_screenshot_window = key_spec({ settings.modkey, settings.ctrlkey }, "p", "screenshot_window", "screenshot of window", grp_names[4]),
        programs_start_awesome_on_tv = key_spec({ settings.modkey, settings.altkey }, "t", "start_awesome_on_tv", "start awesome on TV", grp_names[4]),
        programs_lock_screen_alt_ctrl_l = key_spec({ settings.altkey, settings.ctrlkey }, "l", "lock_screen", "lock screen", grp_names[4]),
        programs_lock_screen_mod_alt_f12 = key_spec({ settings.modkey, settings.altkey }, "F12", "lock_screen", "lock screen", grp_names[4]),
        media_toggle_play_pause = key_spec({}, "XF86AudioPlay", "media_play_pause", "toggle play/pause", grp_names[5]),
        media_next_media_item = key_spec({}, "XF86AudioNext", "media_next", "next media item", grp_names[5]),
        media_prev_media_item = key_spec({}, "XF86AudioPrev", "media_prev", "prev media item", grp_names[5]),
        media_volume_up = key_spec({}, "XF86AudioRaiseVolume", "volume_up", "volume up", grp_names[5]),
        media_volume_down = key_spec({}, "XF86AudioLowerVolume", "volume_down", "volume down", grp_names[5]),
        media_toggle_mute = key_spec({}, "XF86AudioMute", "toggle_mute", "toggle mute", grp_names[5]),
        media_brightness_up = key_spec({}, "XF86MonBrightnessUp", "brightness_up", "brightness up", grp_names[5]),
        media_brightness_down = key_spec({}, "XF86MonBrightnessDown", "brightness_down", "brightness down", grp_names[5]),
        media_display_off = key_spec({}, "XF86Display", "brightness_off", "display off", grp_names[5]),
        awesome_show_help = key_spec({ settings.modkey }, "s", "show_help", "show help", grp_names[6]),
        awesome_reload_alt_ctrl_r = key_spec({ settings.altkey, settings.ctrlkey }, "r", "awesome_reload", "reload awesome", grp_names[6]),
        awesome_reload_mod_ctrl_r = key_spec({ settings.modkey, settings.ctrlkey }, "r", "awesome_restart", "reload awesome", grp_names[6]),
        awesome_quit = key_spec({ settings.modkey, settings.shiftkey }, "q", "awesome_quit", "quit awesome", grp_names[6]),
        system_toggle_notifications = key_spec({ settings.modkey, settings.altkey, settings.ctrlkey }, "End", "toggle_notifications", "toggle notifications", grp_names[7]),
        system_lock_screen = key_spec({ settings.modkey, settings.altkey, settings.ctrlkey }, "Delete", "lock_screen", "lock screen", grp_names[7]),
    }

    local client_spec_order = {
        "client_close",
        "client_toggle_floating",
        "client_move_to_screen",
        "client_move_to_left_screen",
        "client_move_to_right_screen",
        "client_toggle_titlebar",
        "client_minimize",
        "client_maximize",
    }

    local client_specs = {
        client_close = key_spec({ settings.modkey, settings.shiftkey }, "c", "kill_client", "close", grp_names[1]),
        client_toggle_floating = key_spec({ settings.modkey, settings.ctrlkey }, "space", "toggle_floating", "toggle floating", grp_names[1]),
        client_move_to_screen = key_spec({ settings.modkey }, "o", "move_to_screen", "move to screen", grp_names[1]),
        client_move_to_left_screen = key_spec({ settings.modkey, settings.altkey }, "Left", "move_to_left_screen", "move to left screen", grp_names[1]),
        client_move_to_right_screen = key_spec({ settings.modkey, settings.altkey }, "Right", "move_to_right_screen", "move to right screen", grp_names[1]),
        client_toggle_titlebar = key_spec({ settings.modkey, settings.ctrlkey }, "t", "toggle_titlebar", "toggle titlebar", grp_names[1]),
        client_minimize = key_spec({ settings.modkey }, "n", "minimize_client", "minimize", grp_names[1]),
        client_maximize = key_spec({ settings.modkey }, "m", "maximize_client", "maximize", grp_names[1]),
    }

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

        global_specs["desktop_view_tag_" .. i] = key_spec({ settings.modkey }, "#" .. i + 9, "view_tag_" .. i, descr_view, grp_names[2])
        global_specs["desktop_toggle_tag_" .. i] = key_spec({ settings.modkey, settings.ctrlkey }, "#" .. i + 9, "toggle_tag_view_" .. i, descr_toggle, grp_names[2])
        global_specs["desktop_move_focused_to_tag_" .. i] = key_spec({ settings.modkey, settings.shiftkey }, "#" .. i + 9, "move_focused_to_tag_" .. i, descr_move, grp_names[2])
        global_specs["desktop_toggle_focused_on_tag_" .. i] = key_spec({ settings.modkey, settings.ctrlkey, settings.shiftkey }, "#" .. i + 9, "toggle_focused_on_tag_" .. i, descr_toggle_focus, grp_names[2])
    end

    if type(key_overrides.global) == "table" then
        helpers.deep_merge(global_specs, key_overrides.global)
    end

    if type(key_overrides.client) == "table" then
        helpers.deep_merge(client_specs, key_overrides.client)
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
                grp_names[4]
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
                grp_names[4]
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
