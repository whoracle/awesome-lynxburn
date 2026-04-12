-- LynxBurn Theme
-- rc.lua

--
-- Required libraries
--
local awesome, client, mouse, screen, tag = awesome, client, mouse, screen, tag
local ipairs, string, os, table, tostring, tonumber, type = ipairs, string, os, table, tostring, tonumber, type

local gears         = require("gears")
local awful         = require("awful")
                      require("awful.autofocus")
local wibox         = require("wibox")
local beautiful     = require("beautiful")
local lain          = require("lain")
local freedesktop   = require("freedesktop")
local naughty       = require("naughty")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local my_table      = awful.util.table or gears.table -- 4.{0,1} compatibility

local lxaudio = require("lxaudio").new({
    show_mic_activity = true,
    refresh_interval = 5,
    width = 50,
})
local lxnotify = require("lxnotify").new({
    --debug_notifications = true,
    notification_denylist = {
        { app_name = "Volume OSD" },
        { app_name = "Mute Indicator" },
        { app_name = "Notification Indicator" },
        { app_name = "Calendar" },
    },
})
_G.lxaudio = lxaudio
_G.lxnotify = lxnotify

--
-- Error handling
--
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title  = "Oops, there were errors during startup!",
                     text   = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end

--
-- Autostart windowless processes
--
local function run_once(cmd_arr)
    for _, cmd in ipairs(cmd_arr) do
        findme     = cmd
        firstspace = cmd:find(" ")
        if firstspace then
            findme = cmd:sub(0, firstspace-1)
        end
        awful.spawn.with_shell(string.format("pgrep -u $USER -x %s > /dev/null || (%s)", findme, cmd))
    end
end

--
-- Variable definitions
--
local themes = {
    "blackburn",       -- 1
    "copland",         -- 2
    "dremora",         -- 3
    "holo",            -- 4
    "multicolor",      -- 5
    "powerarrow",      -- 6
    "powerarrow-dark", -- 7
    "rainbow",         -- 8
    "steamburn",       -- 9
    "vertex",          -- 10
    "lynxburn",        -- 11
    "lynxburn2",       -- 12
}

local chosen_theme   = themes[12]
local modkey         = "Mod4"
local altkey         = "Mod1"
local terminal       = "urxvt -fg gray -tr -sh 50"
local editor         = os.getenv("EDITOR") or "vim"
local home           = os.getenv("HOME")
local gui_editor     = "subl"
local browser        = "vivaldi-stable"
local guieditor      = "subl"
local imageeditor    = "gimp"
local imageviewer    = "sxiv"
local unclutter      = "unclutter -root"
local numlock        = "numlockx"
local scrlocker      = "i3lock -c 000000 -e -t -i ~/.wallpaper"
local scrotedit      = "sleep 0.5 && scrot ~/screenshots/%y%m%d_%H%M%S.png -e '" .. imageeditor .. " $f'"
local scrotmouse     = "sleep 0.5 && scrot ~/screenshots/%y%m%d_%H%M%S.png -s"
local scrotwin       = "sleep 0.5 && scrot ~/screenshots/%y%m%d_%H%M%S.png -ue '" .. imageviewer .. " $f'"
local xrandr         = "/home/anthrax/.xrandr"
local compton        = "compton -b --paint-on-overlay --unredir-if-possible --backend xr_glx_hybrid --glx-swap-method -1 --glx-no-stencil"
local compton        = "compton -cCGfF -o 0.38 -O 200 -I 200 -t 0 -l 0 -r 3 -D2 -m 0.88"
local conky          = "conky -c ~/.conky/conky-spotify/conky-spotify"
local nmapplet       = "nm-applet --sm-disable"
local blueman        = "blueman-applet"
local pulse          = "pasystray"
local nextcloud      = "nextcloud"
--local setdbus        = os.getenv("HOME") .. "/.config/bin/export_dbus.sh"
local screendrawer   = "gromit-mpx"
local launcher       = "/home/anthrax/.config/rofi/launchers/type-1/launcher.sh"
local filebrowser    = "thunar"
local redshift       = "redshift-gtk"
local compositor     = "picom -b --config /home/anthrax/.config/picom/picom.conf"
local volume_step    = 5
--
-- names of workspaces/tags
--
local workspaces = { "primary", "secondary", "tertiary" }

--
-- additional lain layout configs
--
lain.layout.termfair.nmaster           = 3
lain.layout.termfair.ncol              = 1
lain.layout.termfair.center.nmaster    = 3
lain.layout.termfair.center.ncol       = 1
lain.layout.cascade.tile.offset_x      = 2
lain.layout.cascade.tile.offset_y      = 32
lain.layout.cascade.tile.extra_padding = 5
lain.layout.cascade.tile.nmaster       = 5
lain.layout.cascade.tile.ncol          = 2

-- Quake-style console
-- global
local quake = lain.util.quake({
    app = "urxvt -fg gray -tr -sh 50",
    followtag = true,
})

--
-- define keyboard shortcuts and help text
--

--
-- non-awesome keybindings (sublime etc)
--
local extra_rule = {class={"sublime_text", "Sublime_text"}}

for group_name, group_data in pairs({
        ["Sublime Text 3"] = { color="#659FdF", rule_any=extra_rule }
}) do
    hotkeys_popup.group_rules[group_name] = group_data
end

local extra_hotkeys = {
    ["Sublime Text 3"] = {
        {
            modifiers = { "Mod4" },
            keys = {
                F11 = "Distraction Free Mode"
            }
        }
    }
}
hotkeys_popup.add_hotkeys(extra_hotkeys)

--
-- functions for local key bindings
--

local volume_notification = nil
local volume_box = nil

local volume_step = 5
local osd_width = 260
local osd_height = 18
local osd_margin = 16
local osd_timeout = 1

local volume_osd = {
    notification = nil,
    box = nil,
    hide_timer = nil,
}

local text_osd = {
    notification = nil,
    box = nil,
    hide_timer = nil,
}

local icon_volume = ""
local icon_muted = ""
local icon_brightness = "󰃠"
local icon_suspended = ""
local icon_resumed = ""

local osd_icon = wibox.widget {
    align  = "center",
    valign = "center",
    forced_width = 32,
    widget = wibox.widget.textbox,
}

local volume_bar = wibox.widget {
    max_value        = 100,
    value            = 0,
    forced_width     = osd_width,
    forced_height    = osd_height,
    shape            = gears.shape.rounded_bar,
    bar_shape        = gears.shape.rounded_bar,
    background_color = beautiful.bg_minimize or "#444444",
    color            = beautiful.fg_normal or "#ffffff",
    widget           = wibox.widget.progressbar,
}

local display_text = wibox.widget {
    align  = "center",
    valign = "center",
    forced_width = osd_width,
    widget = wibox.widget.textbox,
}

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

local function ensure_volume_osd(app_name)
    if volume_osd.box then
        return
    end

    volume_osd.notification = naughty.notification({
        title = "",
        message = "",
        app_name = app_name,
        timeout = 0,
        position = "bottom_middle",
        ontop = true,
        screen = awful.screen.focused(),
    })

    volume_osd.box = naughty.layout.box({
        notification = volume_osd.notification,
        position = "bottom_middle",
        screen = awful.screen.focused(),
        widget_template = {
            {
                {
                    {
                        osd_icon,
                        {
                            volume_bar,
                            widget = wibox.container.place,
                        },
                        spacing = 12,
                        layout = wibox.layout.fixed.horizontal,
                    },
                    widget = wibox.container.place,
                },
                margins = osd_margin,
                widget = wibox.container.margin,
            },
            bg = beautiful.notification_bg or beautiful.bg_normal or "#111111",
            fg = beautiful.notification_fg or beautiful.fg_normal or "#ffffff",
            shape = gears.shape.rounded_rect,
            widget = wibox.container.background,
        },
    })

    volume_osd.box.width = osd_width + (osd_margin * 2)
    volume_osd.box.visible = false

    volume_osd.notification:connect_signal("destroyed", function()
        volume_osd.notification = nil
        volume_osd.box = nil
    end)
end

local function ensure_text_osd(app_name)
    if text_osd.box then
        return
    end

    app_name = app_name or nil

    text_osd.notification = naughty.notification({
        title = "",
        message = "",
        app_name = app_name,
        timeout = 0,
        position = "bottom_middle",
        ontop = true,
        screen = awful.screen.focused(),
    })

    text_osd.box = naughty.layout.box({
        notification = text_osd.notification,
        position = "bottom_middle",
        screen = awful.screen.focused(),
        widget_template = {
            {
                {
                    {
                        osd_icon,
                        {
                            display_text,
                            widget = wibox.container.place,
                        },
                        spacing = 12,
                        layout = wibox.layout.fixed.horizontal,
                    },
                    widget = wibox.container.place,
                },
                margins = osd_margin,
                widget = wibox.container.margin,
            },
            bg = beautiful.notification_bg or beautiful.bg_normal or "#111111",
            fg = beautiful.notification_fg or beautiful.fg_normal or "#ffffff",
            shape = gears.shape.rounded_rect,
            widget = wibox.container.background,
        },
    })

    text_osd.box.width = osd_width + (osd_margin * 2)
    text_osd.box.visible = false

    text_osd.notification:connect_signal("destroyed", function()
        text_osd.notification = nil
        text_osd.box = nil
    end)
end

local function show_volume_osd(percent, icon, app_name)
    destroy_osd(text_osd)
    ensure_volume_osd(app_name or "")

    local value = tonumber(percent) or 0
    if value < 0 then value = 0 end
    if value > 100 then value = 100 end

    osd_icon.text = icon or icon_volume
    volume_bar.value = value
    volume_bar.color = beautiful.fg_normal or "#ffffff"

    volume_osd.box.screen = awful.screen.focused()
    volume_osd.box.visible = true

    if volume_osd.hide_timer then
        volume_osd.hide_timer:stop()
    end

    volume_osd.hide_timer = gears.timer.start_new(osd_timeout, function()
        destroy_osd(volume_osd)
        return false
    end)
end

local function show_text_osd(text, icon, app_name)
    destroy_osd(volume_osd)
    ensure_text_osd(app_name or "")

    display_text.text = text

    osd_icon.text = icon or icon_muted
    text_osd.box.screen = awful.screen.focused()
    text_osd.box.visible = true

    if text_osd.hide_timer then
        text_osd.hide_timer:stop()
    end

    text_osd.hide_timer = gears.timer.start_new(osd_timeout, function()
        destroy_osd(text_osd)
        return false
    end)
end

local function update_volume_bar_osd()
    awful.spawn.easy_async_with_shell(
        [[sh -c 'pamixer --get-volume']],
        function(stdout)
            local percent = tonumber(stdout:match("%d+")) or 0
            show_volume_osd(percent, icon_volume, "Volume OSD")
        end
    )
end

local function audio_volume_down()
    awful.spawn.easy_async("pamixer -d " .. volume_step, function()
        update_volume_bar_osd()
    end)
end

local function audio_volume_up()
    awful.spawn.easy_async("pamixer -i " .. volume_step, function()
        update_volume_bar_osd()
    end)
end

local function audio_toggle_mute()
    awful.spawn.easy_async("pamixer -t", function()
        awful.spawn.easy_async_with_shell(
            [[sh -c 'pamixer --get-mute']],
            function(stdout)
                local muted = stdout:match("true") ~= nil
                if muted then
                    show_text_osd("Muted", icon_muted, "Mute Indicator")
                else
                    show_text_osd("Unmuted", icon_volume, "Mute Indicator")
                end
            end
        )
    end)
end

local function toggle_notifications()
    lxnotify:toggle_suspend()

    if naughty.suspended then
        show_text_osd("Notifications suspended", icon_suspended, "Notification Indicator")
    else
        show_text_osd("Notifications resumed", icon_resumed, "Notification Indicator")
    end
end

--
-- global key bindings
--
-- group names
local grp_names = {
    "01. window",
    "02. desktop",
    "03. layout",
    "04. programs",
    "05. media",
    "08. awesomewm",
    "09. system",
}

gears.debug.dump(grp_names)

globalkeys = my_table.join(
    -- window positioning
    awful.key({ modkey,           }, "u",       awful.client.urgent.jumpto,                                                                                     {description = "jump to urgent client",         group = grp_names[1]}),
    awful.key({ modkey, "Control" }, "n",       function() local c = awful.client.restore() if c then client.focus = c c:raise() end end,                       {description = "restore minimized program",     group = grp_names[1]}),
    awful.key({ modkey,           }, "Tab",     function() awful.client.focus.byidx(-1) if client.focus then client.focus:raise() end end,                      {description = "focus next by index",           group = grp_names[1]}),
    awful.key({ modkey, "Shift"   }, "Tab",     function() awful.client.focus.byidx(-1) if client.focus then client.focus:raise() end end,                      {description = "focus previous by index",       group = grp_names[1]}),

    --[[ deprecated
    awful.key({ modkey, "Shift"   }, "Right",   function() awful.client.swap.bydirection("right") end,                                                          {description = "swap with left client",         group = grp_names[1]}),
    awful.key({ modkey, "Shift"   }, "Left",    function() awful.client.swap.bydirection("left") end,                                                           {description = "swap with right client",        group = grp_names[1]}),
    awful.key({ modkey, "Shift"   }, "Up",      function() awful.client.swap.bydirection("up") end,                                                             {description = "swap with upper client",        group = grp_names[1]}),
    awful.key({ modkey, "Shift"   }, "Down",    function() awful.client.swap.bydirection("down") end,                                                           {description = "swap with lower client",        group = grp_names[1]}),
    ]]--

    awful.key({ modkey, "Control" }, "Right",   function() awful.client.swap.bydirection("right") end,                                                          {description = "swap with left client",         group = grp_names[1]}),
    awful.key({ modkey, "Control" }, "Left",    function() awful.client.swap.bydirection("left") end,                                                           {description = "swap with right client",        group = grp_names[1]}),
    awful.key({ modkey, "Control" }, "Up",      function() awful.client.swap.bydirection("up") end,                                                             {description = "swap with upper client",        group = grp_names[1]}),
    awful.key({ modkey, "Control" }, "Down",    function() awful.client.swap.bydirection("down") end,                                                           {description = "swap with lower client",        group = grp_names[1]}),

    -- window focus - this might break awesome
    awful.key({ modkey,           }, "Down",    function() awful.client.focus.global_bydirection("down")  if client.focus then client.focus:raise() end end,    {description = "focus down",                    group = grp_names[1]}),
    awful.key({ modkey,           }, "Up",      function() awful.client.focus.global_bydirection("up")    if client.focus then client.focus:raise() end end,    {description = "focus up",                      group = grp_names[1]}),
    awful.key({ modkey,           }, "Left",    function() awful.client.focus.global_bydirection("left")  if client.focus then client.focus:raise() end end,    {description = "focus left",                    group = grp_names[1]}),
    awful.key({ modkey,           }, "Right",   function() awful.client.focus.global_bydirection("right") if client.focus then client.focus:raise() end end,    {description = "focus right",                   group = grp_names[1]}),

    -- switch virtual desktops
    awful.key({ altkey, "Control" }, "Left",    awful.tag.viewprev,                                                                                             {description = "view previous",                 group = grp_names[2]}),
    awful.key({ altkey, "Control" }, "Right",   awful.tag.viewnext,                                                                                             {description = "view next",                     group = grp_names[2]}),
    awful.key({ modkey, altkey    }, "Escape",  awful.tag.history.restore,                                                                                      {description = "go back",                       group = grp_names[2]}),

    -- layout switching
    awful.key({ modkey,           }, "space",   function() awful.layout.inc( 1) end,                                                                            {description = "select next layout",            group = grp_names[3]}),
    awful.key({ modkey, "Shift"   }, "space",   function() awful.layout.inc(-1) end,                                                                            {description = "select prev layout",            group = grp_names[3]}),
    awful.key({ modkey, "Control" }, "+",       function() lain.util.useless_gaps_resize(1) end,                                                                {description = "increment useless gaps",        group = grp_names[3]}),
    awful.key({ modkey, "Control" }, "-",       function() lain.util.useless_gaps_resize(-1) end,                                                               {description = "decrement useless gaps",        group = grp_names[3]}),

    -- user program4
    awful.key({ altkey,           }, "c",       function() lain.widget.calendar.show(7) end,                                                                    {description = "show calendar",                 group = grp_names[4]}),
    awful.key({ altkey,           }, "Prior",   function() lxaudio:toggle_media_popup(nil, {hover_close = false, anchor = "center", }) end,                     {description = "show media popup",              group = grp_names[4]}),
    awful.key({ altkey,           }, "Next",    function() lxnotify:toggle_notification_popup({hover_close = false, toggle_key = { modifiers = { altkey, }, key = "Next", }, }) end,                                {description = "show notificatino popup",       group = grp_names[4]}),

    awful.key({ altkey,           }, "F2",      function() awful.spawn(launcher) end,                                                                           {description = "launcher",                      group = grp_names[4]}),
    awful.key({ modkey,           }, "q",       function() awful.spawn(terminal) end,                                                                           {description = "terminal",                      group = grp_names[4]}),
    awful.key({ modkey,           }, "e",       function() awful.spawn(filebrowser.." "..home) end,                                                             {description = "file browser",                  group = grp_names[4]}),
    awful.key({ modkey,           }, "p",       function() awful.spawn.with_shell(scrotmouse, false) end,                                                       {description = "screenshot of region",          group = grp_names[4]}),
    awful.key({ altkey, "Control" }, "p",       function() awful.spawn.with_shell(scrotedit, false) end,                                                        {description = "screenshot of whole desktop",   group = grp_names[4]}),
    awful.key({ modkey, "Control" }, "p",       function() awful.spawn.with_shell(scrotwin, false) end,                                                         {description = "screenshot of window",          group = grp_names[4]}),
    awful.key({ modkey, altkey    }, "t",       function() os.execute("export DISPLAY=:0.1 && awesome &") end,                                                  {description = "Start Awesome on TV",           group = grp_names[4]}),
    awful.key({ altkey, "Control" }, "l",       function() os.execute(scrlocker) end,                                                                           {description = "lock screen",                   group = grp_names[4]}),
    awful.key({ modkey, altkey    }, "F12",     function() os.execute(scrlocker) end,                                                                           {description = "lock screen",                   group = grp_names[4]}),

    -- media keys
    awful.key({}, "XF86AudioPlay",              function() awful.spawn("playerctl play-pause", false) end,                                                      {description = "toggle play/pause",             group = grp_names[5]}),
    awful.key({}, "XF86AudioNext",              function() awful.spawn("playerctl next", false) end,                                                            {description = "next media item",               group = grp_names[5]}),
    awful.key({}, "XF86AudioPrev",              function() awful.spawn("playerctl previous", false) end,                                                        {description = "prev media item",               group = grp_names[5]}),
    awful.key({}, "XF86AudioRaiseVolume",       audio_volume_down,                                                                                              {description = "volume up",                     group = grp_names[5]}),
    awful.key({}, "XF86AudioLowerVolume",       audio_volume_up,                                                                                                {description = "volume down",                   group = grp_names[5]}),
    awful.key({}, "XF86AudioMute",              audio_toggle_mute,                                                                                              {description = "toggle mute",                   group = grp_names[5]}),

    -- awesome - restart, reload etc
    awful.key({ modkey,           }, "s",       hotkeys_popup.show_help,                                                                                        {description = "show help",                     group = grp_names[6]}),
    awful.key({ altkey, "Control" }, "r",       awesome.reload,                                                                                                 {description = "reload awesome",                group = grp_names[6]}),
    awful.key({ modkey, "Control" }, "r",       awesome.restart,                                                                                                {description = "reload awesome",                group = grp_names[6]}),
    awful.key({ modkey, "Shift"   }, "q",       awesome.quit,                                                                                                   {description = "quit awesome",                  group = grp_names[6]}),

    -- misc
    awful.key({ modkey, altkey, "Control" }, "End",    function() lxnotify:toggle_suspend() end,                                                       {description = "Toggle Notifications",          group = grp_names[7]}),
    awful.key({ modkey, altkey, "Control" }, "Delete", function() os.execute(scrlocker) end,                                                                    {description = "Lock Screen",                   group = grp_names[7]})
)

--
-- per-client keyboard shortcuts
--
clientkeys = my_table.join(
    awful.key({ modkey, "Shift"   }, "c",     function (c) c:kill() end,                                {description = "close",                 group = grp_names[1]}),
    awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle,                             {description = "toggle floating",       group = grp_names[1]}),
    awful.key({ modkey            }, "o",     function (c) c:move_to_screen() end,                      {description = "move to screen",        group = grp_names[1]}),
    awful.key({ modkey, altkey    }, "Left",  function (c) c:move_to_screen(c.screen.index-1) end,      {description = "move to left screen",   group = grp_names[1]}),
    awful.key({ modkey, altkey    }, "Right", function (c) c:move_to_screen(c.screen.index+1) end,      {description = "move to right screen",  group = grp_names[1]}),
    awful.key({ modkey, "Control" }, "t",     function (c) awful.titlebar.toggle(c) end,                {description = "move to right screen",  group = grp_names[1]}),

    -- The client currently has the input focus, so it cannot be
    -- minimized, since minimized clients can't have the focus.
    awful.key({ modkey,           }, "n",     function (c) c.minimized = true end,                      {description = "minimize",              group = grp_names[1]}),
    awful.key({ modkey,           }, "m",     function (c) c.maximized = not c.maximized c:raise() end, {description = "maximize",              group = grp_names[1]})

)

--
-- workspace shortcuts
--
for i = 1, 9 do
    local descr_view, descr_toggle, descr_move, descr_toggle_focus
    if i == 1 or i == 9 then
        descr_view =         {description = "view tag #",                       group = grp_names[2]}
        descr_toggle =       {description = "toggle tag #",                     group = grp_names[2]}
        descr_move =         {description = "move focused client to tag #",     group = grp_names[2]}
        descr_toggle_focus = {description = "toggle focused client on tag #",   group = grp_names[2]}
    end
    globalkeys = my_table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  descr_view),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  descr_toggle),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  descr_move),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  descr_toggle_focus)
    )
end

--
-- setup workspaces and tiling modes
--
awful.util.terminal  = terminal
awful.util.tagnames  = workspaces
awful.layout.layouts = {
    awful.layout.suit.fair,
    lain.layout.centerwork,
    lain.layout.centerwork.horizontal,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.floating,
    --[[ deactivated tiling modes
    lain.layout.termfair.center,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
    awful.layout.suit.corner.ne,
    awful.layout.suit.corner.sw,
    awful.layout.suit.corner.se,
    lain.layout.cascade,
    lain.layout.cascade.tile,
    lain.layout.termfair,
    --]]--
}

--
-- setup workspace list
--
awful.util.taglist_buttons = my_table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
            if client.focus then
                client.focus:move_to_tag(t)
            end
        end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
            if client.focus then
                client.focus:toggle_tag(t)
            end
        end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

--
-- setup taskbar
--
awful.util.tasklist_buttons = my_table.join(
    awful.button({ }, 1, function (c)
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

    awful.button({ }, 3, function()
        local instance = nil
        return function ()
            if instance and instance.wibox.visible then
                instance:hide()
                instance = nil
            else
                instance = awful.menu.clients({ theme = { width = 250 } })
            end
       end
    end),
    awful.button({ }, 4, function () awful.client.focus.byidx(1) end),
    awful.button({ }, 5, function () awful.client.focus.byidx(-1) end)
)

--
-- run initial stuff
--
run_once(
    {
        unclutter,
        --numlock,
        --setdbus,
    }
)

-- mouse buttons
mousebuttons = my_table.join(
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev),
    -- compatibility with logitech g500
    awful.button({  }, 10, function () awful.spawn(terminal) end)
)

--
-- initialize theme and generate screens
--
local theme_path = string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), chosen_theme)
beautiful.init(theme_path)

screen.connect_signal("property::geometry", function(s)
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end)

--
-- taskbar on each screen
--
local MONITOR_LEFT = 3
local MONITOR_CENTER = 1
local MONITOR_RIGHT = 2

awful.screen.connect_for_each_screen(
    function(s)
        --[[
        -- debug output with screen numbers
        naughty.notify({ preset = naughty.config.presets.critical,
                     title  = "Index",
                     text   = "Monitor Index: " .. s.index .. " - check",
                     screen = s })
        ]]--
        beautiful.at_screen_connect(s)
        -- left monitor - vertical
        if s.index == MONITOR_LEFT then
            s.selected_tag.layout = lain.layout.centerwork.horizontal
            s.dpi = 96
        end
        -- center monitor - widescreen
        if s.index == MONITOR_CENTER then
            s.selected_tag.layout = lain.layout.centerwork
            s.dpi = 110
        end
        -- right monitor - 1440p 16:9
        if s.index == MONITOR_RIGHT then
            s.dpi = 110
        end
    end
)

root.buttons(mousebuttons)

--
-- bind mouse buttons to client
--
clientbuttons = my_table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize),
    awful.button({  }, 10, function () awful.spawn(terminal) end)
    ),

--
-- enable keyboard shortcuts
--
root.keys(globalkeys)

--
-- rules for different window classes
--
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     -- Spawn windows as slave
                     callback = awful.client.setslave,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
                     size_hints_honor = false
     }
    },

    -- Titlebars
    { rule_any = { type = { "dialog", "normal" } },
      properties = { titlebars_enabled = false } },

    -- Set Vivaldi to always map on the first tag on screen 1.
    --[[
    { rule = { class = "Mattermost" },
      properties = { screen = 1, tag = awful.util.tagnames[1], maximized = false } },
    { rule = { class = "retroarch" },
      properties = { titlebars_enabled = false, floating = false, maximized = true } },
    { rule = { class = "Spotify" },
      properties = { screen = MONITOR_LEFT, tag = awful.util.tagnames[1], maximized = false } },
    ]]--
    { rule = { class = "Vivaldi" },
      properties = { screen = MONITOR_CENTER, tag = awful.util.tagnames[1], maximized = false }
    },
    { rule = { class = "Sublime_text" },
      properties = { screen = MONITOR_CENTER, tag = awful.util.tagnames[1] }
    },
    { rule = { class = "Google-chrome" },
      properties = { screen = MONITOR_RIGHT, tag = awful.util.tagnames[1], maximized = false }
    },
    {
        rule = {
            class = {
                "vlc"
            }
        },
        properties = {
            titlebars_enabled = true,
            floating = true
        }
    },
    {
        rule = {
            class = {
                "xlax",
                "Gmrun"
            }
        },
        properties = {
            titlebars_enabled = true,
            floating = true,
            ontop = true
        }
    },
    {
        rule = {
            class = {
                "xfreerdp",
                "rdesktop"
            }
        },
        properties = {
            titlebars_enabled = true,
            floating = true,
            maximized = true
        }
    },
    { rule = { class = "Gimp", role = "gimp-image-window" },
          properties = { maximized = true }
    },
    -- diablo iv
    { rule = { class = "steam_app_2344520" },
      properties = { titlebars_enabled = false, floating = true, maximized = true }
    },
    -- prevent focus stealing
    {
        rule_any = {
             class = {
                "UnrealEditor"
             }
        },
        properties = {
            focus = false
        }
    },
}

--
-- Signals
--

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- Custom
    if beautiful.titlebar_fun then
        beautiful.titlebar_fun(c)
        return
    end

    -- Default
    -- buttons for the titlebar
    local buttons = my_table.join(
        awful.button({ }, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c, {size = 16}) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- No border for maximized clients
function border_adjust(c)
    if c.maximized then -- no borders if only 1 client visible
        c.border_width = 0
    elseif #awful.screen.focused().clients > 1 then
        c.border_width = beautiful.border_width
        c.border_color = beautiful.border_focus
    end
end

awful.screen.set_auto_dpi_enabled( true )

client.connect_signal("focus", border_adjust)
client.connect_signal("property::maximized", border_adjust)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

--
-- final startup programs
--
--awful.spawn(xrandr)
-- -awful.spawn(blueman)
--awful.spawn(pulse)
awful.spawn(nextcloud)
awful.spawn(nmapplet)
awful.spawn(redshift)
-- -awful.spawn(compositor)
-- -awful.spawn(compton)
-- -awful.spawn(screendrawer)
-- -awful.spawn("setxkbmap de")
