local awful = require("awful")
local gears = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local helpers = require("config.helpers")

local M = {}

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
    local lxdisplay = context.lxdisplay
    local lxrunner = context.lxrunner
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
        lxaudio:toggle_media_popup(nil, { hover_close = false, anchor = "center" })
    end

    local function show_notification_popup()
        lxnotify:toggle_notification_popup({
            hover_close = false,
            toggle_key = { modifiers = { settings.altkey }, key = "Next" },
        })
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

    local globalkeys = my_table.join(
        -- window
        awful.key({ settings.modkey },                                      "u",                    awful.client.urgent.jumpto,        { description = "jump to urgent client",     group = grp_names[1] }),
        awful.key({ settings.modkey, settings.ctrlkey },                    "n",                    restore_minimized,                 { description = "restore minimized program", group = grp_names[1] }),
        awful.key({ settings.modkey },                                      "Tab",                  cycle_focus,                       { description = "focus next by index",       group = grp_names[1] }),
        awful.key({ settings.modkey, settings.shiftkey },                   "Tab",                  cycle_focus,                       { description = "focus previous by index",   group = grp_names[1] }),

        awful.key({ settings.modkey, settings.ctrlkey },                    "Right",                swap_by_direction("right"),        { description = "swap with left client",     group = grp_names[1] }),
        awful.key({ settings.modkey, settings.ctrlkey },                    "Left",                 swap_by_direction("left"),         { description = "swap with right client",    group = grp_names[1] }),
        awful.key({ settings.modkey, settings.ctrlkey },                    "Up",                   swap_by_direction("up"),           { description = "swap with upper client",    group = grp_names[1] }),
        awful.key({ settings.modkey, settings.ctrlkey },                    "Down",                 swap_by_direction("down"),         { description = "swap with lower client",    group = grp_names[1] }),

        awful.key({ settings.modkey },                                      "Down",                 focus_by_direction("down"),        { description = "focus down",                group = grp_names[1] }),
        awful.key({ settings.modkey },                                      "Up",                   focus_by_direction("up"),          { description = "focus up",                  group = grp_names[1] }),
        awful.key({ settings.modkey },                                      "Left",                 focus_by_direction("left"),        { description = "focus left",                group = grp_names[1] }),
        awful.key({ settings.modkey },                                      "Right",                focus_by_direction("right"),       { description = "focus right",               group = grp_names[1] }),

        -- desktop
        awful.key({ settings.altkey, settings.ctrlkey },                    "Left",                 awful.tag.viewprev,                { description = "view previous",             group = grp_names[2] }),
        awful.key({ settings.altkey, settings.ctrlkey },                    "Right",                awful.tag.viewnext,                { description = "view next",                 group = grp_names[2] }),
        awful.key({ settings.modkey, settings.altkey },                     "Escape",               awful.tag.history.restore,         { description = "go back",                   group = grp_names[2] }),

        -- layout
        awful.key({ settings.modkey },                                      "space",                next_layout,                       { description = "select next layout",        group = grp_names[3] }),
        awful.key({ settings.modkey, settings.shiftkey },                   "space",                prev_layout,                       { description = "select prev layout",        group = grp_names[3] }),
        awful.key({ settings.modkey, settings.ctrlkey },                    "+",                    grow_gaps,                         { description = "increment useless gaps",    group = grp_names[3] }),
        awful.key({ settings.modkey, settings.ctrlkey },                    "-",                    shrink_gaps,                       { description = "decrement useless gaps",    group = grp_names[3] }),

        -- lxtools
        awful.key({ settings.altkey },                                      "Prior",                show_media_popup,                  { description = "show media popup",          group = grp_names[4] }),
        awful.key({ settings.altkey },                                      "Next",                 show_notification_popup,           { description = "show notification popup",   group = grp_names[4] }),

        -- programs
        awful.key({ settings.altkey },                                      "c",                    show_calendar,                     { description = "show calendar",             group = grp_names[4] }),
        awful.key({ settings.altkey },                                      "F2",                   toggle_lxrunner,                   { description = "lxrunner",                  group = grp_names[4] }),
        awful.key({ settings.altkey },                                      "F3",                   open_launcher,                     { description = "launcher",                  group = grp_names[4] }),
        awful.key({ settings.modkey },                                      "q",                    open_terminal,                     { description = "terminal",                  group = grp_names[4] }),
        awful.key({ settings.modkey },                                      "e",                    open_file_browser,                 { description = "file browser",              group = grp_names[4] }),
        awful.key({ settings.modkey },                                      "p",                    screenshot_region,                 { description = "screenshot of region",      group = grp_names[4] }),
        awful.key({ settings.altkey, settings.ctrlkey },                    "p",                    screenshot_desktop,                { description = "screenshot of desktop",     group = grp_names[4] }),
        awful.key({ settings.modkey, settings.ctrlkey },                    "p",                    screenshot_window,                 { description = "screenshot of window",      group = grp_names[4] }),
        awful.key({ settings.modkey, settings.altkey },                     "t",                    start_awesome_on_tv,               { description = "start awesome on TV",       group = grp_names[4] }),
        awful.key({ settings.altkey, settings.ctrlkey },                    "l",                    lock_screen,                       { description = "lock screen",               group = grp_names[4] }),
        awful.key({ settings.modkey, settings.altkey },                     "F12",                  lock_screen,                       { description = "lock screen",               group = grp_names[4] }),

        -- media
        awful.key({},                                                       "XF86AudioPlay",        media_play_pause,                  { description = "toggle play/pause",         group = grp_names[5] }),
        awful.key({},                                                       "XF86AudioNext",        media_next,                        { description = "next media item",           group = grp_names[5] }),
        awful.key({},                                                       "XF86AudioPrev",        media_prev,                        { description = "prev media item",           group = grp_names[5] }),
        awful.key({},                                                       "XF86AudioRaiseVolume", volume_up,                         { description = "volume up",                 group = grp_names[5] }),
        awful.key({},                                                       "XF86AudioLowerVolume", volume_down,                       { description = "volume down",               group = grp_names[5] }),
        awful.key({},                                                       "XF86AudioMute",        toggle_mute,                       { description = "toggle mute",               group = grp_names[5] }),
        awful.key({},                                                       "XF86MonBrightnessUp",  brightness_up,                     { description = "brightness up",             group = grp_names[5] }),
        awful.key({},                                                       "XF86MonBrightnessDown",brightness_down,                   { description = "brightness down",           group = grp_names[5] }),
        awful.key({},                                                       "XF86Display",          brightness_off,                    { description = "display off",               group = grp_names[5] }),

        -- awesomewm
        awful.key({ settings.modkey },                                      "s",                    hotkeys_popup.show_help,           { description = "show help",                 group = grp_names[6] }),
        awful.key({ settings.altkey, settings.ctrlkey },                    "r",                    awesome.reload,                    { description = "reload awesome",            group = grp_names[6] }),
        awful.key({ settings.modkey, settings.ctrlkey },                    "r",                    awesome.restart,                   { description = "reload awesome",            group = grp_names[6] }),
        awful.key({ settings.modkey, settings.shiftkey },                   "q",                    awesome.quit,                      { description = "quit awesome",              group = grp_names[6] }),

        -- system
        awful.key({ settings.modkey, settings.altkey, settings.ctrlkey },   "End",                  toggle_notifications,              { description = "toggle notifications",      group = grp_names[7] }),
        awful.key({ settings.modkey, settings.altkey, settings.ctrlkey },   "Delete",               lock_screen,                       { description = "lock screen",               group = grp_names[7] })
    )

    local clientkeys = my_table.join(
        awful.key({ settings.modkey, settings.shiftkey },                   "c",                    kill_client,                       { description = "close",                     group = grp_names[1] }),
        awful.key({ settings.modkey, settings.ctrlkey },                    "space",                awful.client.floating.toggle,      { description = "toggle floating",           group = grp_names[1] }),
        awful.key({ settings.modkey },                                      "o",                    move_to_screen,                    { description = "move to screen",            group = grp_names[1] }),
        awful.key({ settings.modkey, settings.altkey },                     "Left",                 move_to_left_screen,               { description = "move to left screen",       group = grp_names[1] }),
        awful.key({ settings.modkey, settings.altkey },                     "Right",                move_to_right_screen,              { description = "move to right screen",      group = grp_names[1] }),
        awful.key({ settings.modkey, settings.ctrlkey },                    "t",                    toggle_titlebar,                   { description = "toggle titlebar",           group = grp_names[1] }),
        awful.key({ settings.modkey },                                      "n",                    minimize_client,                   { description = "minimize",                  group = grp_names[1] }),
        awful.key({ settings.modkey },                                      "m",                    maximize_client,                   { description = "maximize",                  group = grp_names[1] })
    )

    for i = 1, 9 do
        local descr_view
        local descr_toggle
        local descr_move
        local descr_toggle_focus

        if i == 1 or i == 9 then
            descr_view = { description = "view tag #", group = grp_names[2] }
            descr_toggle = { description = "toggle tag #", group = grp_names[2] }
            descr_move = { description = "move focused client to tag #", group = grp_names[2] }
            descr_toggle_focus = { description = "toggle focused client on tag #", group = grp_names[2] }
        end

        globalkeys = my_table.join(globalkeys,
            awful.key({ settings.modkey }, "#" .. i + 9, view_tag(i),                                 descr_view),
            awful.key({ settings.modkey, settings.ctrlkey }, "#" .. i + 9, toggle_tag_view(i),               descr_toggle),
            awful.key({ settings.modkey, settings.shiftkey }, "#" .. i + 9, move_focused_to_tag(i),             descr_move),
            awful.key({ settings.modkey, settings.ctrlkey, settings.shiftkey }, "#" .. i + 9, toggle_focused_on_tag(i), descr_toggle_focus)
        )
    end

    local keymaps = {
        globalkeys = globalkeys,
        clientkeys = clientkeys,
    }

    if type(key_overrides.global) == "function" then
        local extra_globalkeys = key_overrides.global(context)

        if extra_globalkeys then
            keymaps.globalkeys = my_table.join(keymaps.globalkeys, extra_globalkeys)
        end
    end

    if type(key_overrides.client) == "function" then
        local extra_clientkeys = key_overrides.client(context)

        if extra_clientkeys then
            keymaps.clientkeys = my_table.join(keymaps.clientkeys, extra_clientkeys)
        end
    end

    if type(key_overrides.transform) == "function" then
        keymaps = key_overrides.transform(keymaps, context) or keymaps
    end

    return keymaps
end

return M
