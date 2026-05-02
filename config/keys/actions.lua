local awful = require("awful")
local calendar = require("widgets.calendar")

local M = {}

function M.build(context)
    local settings = context.settings
    local runtime = context.runtime or {}
    local commands = context.commands
    local lxnotify = context.lxnotify
    local lxmedia = context.lxmedia
    local lxbar = context.lxbar
    local lxbluetooth = context.lxbluetooth
    local lxdisplay = context.lxdisplay
    local lxnetwork = context.lxnetwork
    local lxrunner = context.lxrunner
    local lxpower = context.lxpower
    local osd = context.osd
    local layouts = context.layouts
    local hotkeys_popup = context.hotkeys_popup

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
        layouts.cycle_selected_tag(1)
    end

    local function prev_layout()
        layouts.cycle_selected_tag(-1)
    end

    local function grow_gaps()
        layouts.resize_useless_gaps(1)
    end

    local function shrink_gaps()
        layouts.resize_useless_gaps(-1)
    end

    local function show_media_popup()
        lxbar:toggle_popup_by_role("media", "primary", {
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

    local function show_power_popup()
        if lxpower then
            lxbar:toggle_popup_by_role("power", "secondary", {
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
        calendar.show(7)
    end

    local function open_launcher()
        awful.spawn(commands.launcher)
    end

    local function toggle_lxrunner()
        lxrunner:toggle()
    end

    local function open_terminal()
        awful.spawn(commands.terminal)
    end

    local function open_file_browser()
        awful.spawn(commands.filebrowser .. " " .. (runtime.home and runtime.home() or ""))
    end

    local function screenshot_region()
        awful.spawn.with_shell(commands.scrotmouse, false)
    end

    local function screenshot_desktop()
        awful.spawn.with_shell(commands.scrotedit, false)
    end

    local function screenshot_window()
        awful.spawn.with_shell(commands.scrotwin, false)
    end

    local function start_awesome_on_tv()
        os.execute("export DISPLAY=:0.1 && awesome &")
    end

    local function lock_screen()
        os.execute(commands.scrlocker)
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
        if lxmedia then
            lxmedia:volume_up(nil, { show_osd = true })
        end
    end

    local function volume_down()
        if lxmedia then
            lxmedia:volume_down(nil, { show_osd = true })
        end
    end

    local function toggle_mute()
        if lxmedia then
            lxmedia:toggle_mute({ show_osd = true })
        end
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
        show_power_popup = show_power_popup,
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

    return actions
end

function M.build_lxmedia_popup_key_actions(global_specs)
    local popup_bindings = {
        media_play_pause = true,
        media_next = true,
        media_prev = true,
        volume_up = true,
        volume_down = true,
        toggle_mute = true,
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

return M
