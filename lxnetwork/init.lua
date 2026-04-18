local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local keygrabber = require("awful.keygrabber")

local popup_control = require("lxcommon.popup_control")
local popup_common = require("lxcommon.popup_ui")
local widget_feedback = require("lxcommon.widget_feedback")
local util = require("lxmedia.util")
local notify_util = require("lxnotify.util")
local popup_placement = require("lxcommon.popup_placement")

local M = {}
M.__index = M

local DEFAULTS = {
    refresh_interval = 20,
}

local function merge_defaults(opts)
    opts = opts or {}
    local merged = {}

    for key, value in pairs(DEFAULTS) do
        merged[key] = value
    end

    for key, value in pairs(opts) do
        merged[key] = value
    end

    return merged
end

local function split_nmcli_fields(line)
    local fields = {}
    local current = {}
    local escaped = false

    for index = 1, #line do
        local char = line:sub(index, index)

        if escaped then
            current[#current + 1] = char
            escaped = false
        elseif char == "\\" then
            escaped = true
        elseif char == ":" then
            fields[#fields + 1] = table.concat(current)
            current = {}
        else
            current[#current + 1] = char
        end
    end

    fields[#fields + 1] = table.concat(current)
    return fields
end

local function parse_wifi_list(stdout)
    local networks = {}

    for _, line in ipairs(util.split_lines(stdout)) do
        local fields = split_nmcli_fields(line)
        local active = fields[1]
        local ssid = fields[2]
        local bssid = fields[3]
        local security = fields[4]
        local signal = fields[5]
        local rate = fields[6]

        if bssid then
            networks[#networks + 1] = {
                active = active == "*",
                ssid = ssid ~= "" and ssid or "<hidden>",
                bssid = bssid,
                security = security,
                signal = tonumber(signal) or 0,
                rate = rate,
            }
        end
    end

    return networks
end

local function infer_wifi_standard(rate_text)
    local mbps = tonumber(tostring(rate_text or ""):match("([%d%.]+)%s*Mbit/s"))
    if not mbps then
        return nil
    end

    if mbps >= 1000 then
        return "WiFi 6"
    end

    if mbps >= 400 then
        return "WiFi 5"
    end

    if mbps >= 100 then
        return "WiFi 4"
    end

    return nil
end

local function parse_known_connections(stdout)
    local known = {}

    for _, line in ipairs(util.split_lines(stdout)) do
        local fields = split_nmcli_fields(line)
        local name = fields[1]
        local kind = fields[2]
        if name and kind == "802-11-wireless" then
            known[name] = true
        end
    end

    return known
end

local function parse_active_connection(stdout)
    local current = {
        ssid = nil,
        uuid = nil,
    }

    for _, line in ipairs(util.split_lines(stdout)) do
        local fields = split_nmcli_fields(line)
        local name = fields[1]
        local kind = fields[2]
        if name and kind == "802-11-wireless" then
            current.ssid = name
            break
        end
    end

    return current
end

local function has_active_vpn(stdout)
    for _, line in ipairs(util.split_lines(stdout)) do
        local fields = split_nmcli_fields(line)
        local kind = fields[2]
        if kind == "vpn" then
            return true
        end
    end

    return false
end

local function sort_networks(a, b)
    if a.known ~= b.known then
        return a.known
    end

    if a.active ~= b.active then
        return a.active
    end

    if a.signal ~= b.signal then
        return a.signal > b.signal
    end

    return a.ssid < b.ssid
end

local function apply_popup_geometry(instance, popup_widget, anchor)
    local target_screen = notify_util.resolve_screen(anchor)
    popup_placement.apply(
        popup_widget,
        target_screen,
        instance:_theme_value("lxnetwork_popup_placement", "side"),
        { width = math.min(instance:_theme_value("lxnetwork_popup_width", 380), target_screen.workarea.width) }
    )
end

local function make_signal_bar(instance, signal)
    return wibox.widget({
        max_value = 100,
        value = signal or 0,
        forced_width = instance:_theme_value("lxnetwork_signal_bar_width", 56),
        forced_height = 8,
        paddings = 0,
        border_width = 0,
        background_color = instance:_theme_value("lxnetwork_signal_bar_bg", beautiful.bg_minimize or "#140c0b"),
        color = instance:_theme_value("lxnetwork_signal_bar_fg", beautiful.fg_normal or "#e2ccb0"),
        widget = wibox.widget.progressbar,
    })
end

local function make_network_row(instance, network, selected, onclick)
    local name = network.ssid
    if network.standard then
        name = string.format("%s [%s]", name, network.standard)
    end
    if network.active then
        name = "● " .. name
    end
    local row_content = wibox.widget({
        {
            markup = gears.string.xml_escape(name),
            ellipsize = "end",
            widget = wibox.widget.textbox,
        },
        nil,
        {
            {
                make_signal_bar(instance, network.signal),
                right = 2,
                widget = wibox.container.margin,
            },
            halign = "right",
            widget = wibox.container.place,
        },
        expand = "inside",
        layout = wibox.layout.align.horizontal,
    })

    return popup_common.make_selectable_click_container(row_content, onclick, {
        selected = selected,
        inner_bg = instance:_theme_value("lxnetwork_popup_bg", beautiful.bg_normal or "#222222"),
        hover_bg = instance:_theme_value("lxnetwork_button_hover", beautiful.bg_focus or "#444444"),
        outer_bg = instance:_theme_value("lxnetwork_popup_bg", beautiful.bg_normal or "#222222"),
        selected_bg = instance:_theme_value("lxnetwork_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
    })
end

local function current_network_entry(instance)
    local current_ssid = instance.state.current_ssid
    if not current_ssid or current_ssid == "" then
        return nil
    end

    local best_match = nil

    for _, network in ipairs(instance.state.networks or {}) do
        if network.ssid == current_ssid then
            if not best_match or network.signal > best_match.signal then
                best_match = network
            end
        end
    end

    if best_match then
        local current = {}
        for key, value in pairs(best_match) do
            current[key] = value
        end
        current.active = false
        return current
    end

    return {
        ssid = current_ssid,
        signal = 0,
        standard = nil,
    }
end

function M:_refresh_connection_state(callback)
    awful.spawn.easy_async_with_shell("nmcli radio wifi 2>/dev/null", function(radio_stdout)
        local enabled = tostring(radio_stdout or ""):match("enabled") ~= nil

        awful.spawn.easy_async_with_shell(
            "nmcli -t -e yes -f NAME,TYPE connection show --active 2>/dev/null",
            function(active_stdout)
                local active = parse_active_connection(active_stdout)
                local vpn_active = has_active_vpn(active_stdout)

                awful.spawn.easy_async_with_shell(
                    "nmcli -t -e yes -f NAME,TYPE connection show 2>/dev/null",
                    function(known_stdout)
                        local known = parse_known_connections(known_stdout)

                        self.state.enabled = enabled
                        self.state.current_ssid = active.ssid
                        self.state.vpn_active = vpn_active

                        if callback then
                            callback(known)
                        else
                            self:_refresh_widget()
                            self:_refresh_popup()
                        end
                    end
                )
            end
        )
    end)
end

function M:_theme_value(key, fallback)
    local value = beautiful[key]
    if value == nil then
        return fallback
    end

    return value
end

function M:_refresh_widget()
    local fg = self.state.enabled
        and self:_theme_value("lxnetwork_widget_fg", beautiful.fg_normal or "#ffffff")
        or self:_theme_value("lxnetwork_widget_disabled_fg", beautiful.fg_minimize or "#888888")

    if self.state.enabled and self.state.vpn_active then
        fg = self:_theme_value("lxnetwork_widget_vpn_fg", beautiful.fg_urgent or "#d97777")
    end

    self._refs.icon.markup = string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(fg),
        gears.string.xml_escape(self:_theme_value("lxnetwork_icon", ""))
    )

    if self._refs.label then
        self._refs.label.markup = ""
    end
end

function M:_close_password_prompt()
    if self._password_popup then
        self._password_popup.visible = false
    end

    if self._password_keygrabber and self._password_keygrabber.grabber then
        self._password_keygrabber:stop()
    end

    self._password_target = nil
    self._password_input = ""

    if self._popup and self._popup.visible and self._popup_keyboard_navigation_requested then
        self:focus_popup_keyboard_navigation()
    end
end

function M:_refresh_password_prompt()
    if not self._password_refs then
        return
    end

    local masked = string.rep("•", #(self._password_input or ""))
    self._password_refs.body.markup = string.format(
        "<span foreground='%s'>Password for %s\n%s</span>",
        gears.string.xml_escape(self:_theme_value("lxnetwork_widget_fg", beautiful.fg_normal or "#ffffff")),
        gears.string.xml_escape(self._password_target and self._password_target.ssid or ""),
        gears.string.xml_escape(masked)
    )
end

function M:_submit_password()
    local target = self._password_target
    local password = self._password_input or ""

    if not target then
        return
    end

    self:_close_password_prompt()

    local command = string.format(
        "nmcli device wifi connect %s password %s >/dev/null 2>&1",
        util.shell_escape(target.bssid ~= "" and target.bssid or target.ssid),
        util.shell_escape(password)
    )

    awful.spawn.easy_async_with_shell(command, function()
        self:refresh()
    end)
end

function M:_show_password_prompt(target)
    self._password_target = target
    self._password_input = ""
    self._popup_keyboard_navigation_requested = self._popup_keyboard_navigation_active == true

    if self._popup_keyboard_navigation_requested then
        self:blur_popup_keyboard_navigation()
    end

    if not self._password_popup then
        local body = wibox.widget({
            markup = "",
            widget = wibox.widget.textbox,
        })

        self._password_popup = awful.popup({
            visible = false,
            ontop = true,
            type = "dialog",
            bg = self:_theme_value("lxnetwork_popup_bg", beautiful.bg_normal or "#222222"),
            border_width = beautiful.border_width or 1,
            border_color = beautiful.border_focus or "#666666",
            widget = {
                {
                    body,
                    margins = 12,
                    widget = wibox.container.margin,
                },
                widget = wibox.container.background,
            },
        })

        self._password_refs = {
            body = body,
        }
    end

    self:_refresh_password_prompt()
    self._password_popup.screen = awful.screen.focused()
    awful.placement.centered(self._password_popup, { honor_workarea = true })
    self._password_popup.visible = true

    if not self._password_keygrabber then
        self._password_keygrabber = keygrabber({
            stop_event = "release",
            keypressed_callback = function(_, _, key)
                if key == "Escape" then
                    self:_close_password_prompt()
                    return
                end

                if key == "BackSpace" then
                    self._password_input = self._password_input:sub(1, -2)
                    self:_refresh_password_prompt()
                    return
                end

                if key == "Return" then
                    self:_submit_password()
                    return
                end

                if #key == 1 then
                    self._password_input = self._password_input .. key
                    self:_refresh_password_prompt()
                end
            end,
        })
    end

    self._password_keygrabber:start()
end

function M:_connect_network(network)
    if network.known or network.security == "" or network.security == "--" then
        local target = network.bssid ~= "" and network.bssid or network.ssid
        local command = string.format(
            "nmcli device wifi connect %s >/dev/null 2>&1",
            util.shell_escape(target)
        )

        awful.spawn.easy_async_with_shell(command, function()
            self:refresh()
        end)
        return
    end

    self:_show_password_prompt(network)
end

function M:set_wifi_enabled(enabled)
    local desired = enabled and "on" or "off"

    awful.spawn.easy_async_with_shell("nmcli radio wifi " .. desired .. " >/dev/null 2>&1", function()
        if not enabled then
            self.state.networks = {}
            self.state.current_ssid = nil
            self.state.scan_in_progress = false
        end

        self:refresh()
    end)
end

function M:toggle_wifi_enabled()
    self:set_wifi_enabled(not self.state.enabled)
end

function M:_refresh_popup()
    if not self._popup_refs then
        return
    end

    local refs = self._popup_refs
    refs.current_header.markup = string.format(
        "<span foreground='%s'>Current</span>",
        gears.string.xml_escape(self:_theme_value("lxnetwork_meta_fg", beautiful.fg_minimize or "#999999"))
    )
    refs.current_value_container:reset()

    if not self.state.enabled then
        refs.current_value.markup = string.format(
            "<span foreground='%s'>wifi disabled</span>",
            gears.string.xml_escape(self:_theme_value("lxnetwork_widget_disabled_fg", beautiful.fg_minimize or "#888888"))
        )
        refs.current_value_container:add(refs.current_value)
    elseif self.state.scan_in_progress then
        refs.current_value.markup = string.format(
            "<span foreground='%s'>scanning...</span>",
            gears.string.xml_escape(self:_theme_value("lxnetwork_widget_fg", beautiful.fg_normal or "#ffffff"))
        )
        refs.current_value_container:add(refs.current_value)
    else
        local current_network = current_network_entry(self)
        if current_network then
            refs.current_value_container:add(make_network_row(self, current_network, false, nil))
        else
            refs.current_value.markup = string.format(
                "<span foreground='%s'>offline</span>",
                gears.string.xml_escape(self:_theme_value("lxnetwork_widget_fg", beautiful.fg_normal or "#ffffff"))
            )
            refs.current_value_container:add(refs.current_value)
        end
    end

    refs.known_list:reset()
    refs.available_list:reset()
    local known_count = 0
    local available_count = 0
    self._popup_items = {
        {
            on_enter = function()
                self:scan()
            end,
        },
        {
            on_enter = function()
                self:toggle_wifi_enabled()
            end,
        },
    }

    for _, network in ipairs(self.state.networks) do
        if network.active or (self.state.current_ssid and network.ssid == self.state.current_ssid) then
            goto continue
        end

        local selected = self._popup_selected_index == (#self._popup_items + 1)
        local row = make_network_row(self, network, selected, function()
            self:_connect_network(network)
        end)

        self._popup_items[#self._popup_items + 1] = {
            on_enter = function()
                self:_connect_network(network)
            end,
        }

        if network.known then
            refs.known_list:add(row)
            known_count = known_count + 1
        else
            refs.available_list:add(row)
            available_count = available_count + 1
        end

        ::continue::
    end

    if known_count == 0 then
        refs.known_list:add(popup_common.make_info_line(string.format(
            "<span foreground='%s'>No visible known networks.</span>",
            gears.string.xml_escape(self:_theme_value("lxnetwork_meta_fg", beautiful.fg_minimize or "#999999"))
        )))
    end

    if available_count == 0 then
        refs.available_list:add(popup_common.make_info_line(string.format(
            "<span foreground='%s'>No additional networks.</span>",
            gears.string.xml_escape(self:_theme_value("lxnetwork_meta_fg", beautiful.fg_minimize or "#999999"))
        )))
    end
end

function M:_build_popup()
    local current_header = wibox.widget({
        markup = "",
        widget = wibox.widget.textbox,
    })
    local current_value = wibox.widget({
        markup = "",
        widget = wibox.widget.textbox,
    })
    local current_value_container = wibox.layout.fixed.vertical()
    local known_list = wibox.layout.fixed.vertical()
    local available_list = wibox.layout.fixed.vertical()

    self._popup_refs = {
        current_header = current_header,
        current_value = current_value,
        current_value_container = current_value_container,
        known_list = known_list,
        available_list = available_list,
    }

    self:_refresh_popup()

    return wibox.widget({
        {
            popup_common.make_selectable_click_row("Scan WiFi", function()
                self:scan()
            end, {
                selected = self._popup_selected_index == 1,
                inner_bg = self:_theme_value("lxnetwork_popup_bg", beautiful.bg_normal or "#222222"),
                hover_bg = self:_theme_value("lxnetwork_button_hover", beautiful.bg_focus or "#444444"),
                outer_bg = self:_theme_value("lxnetwork_popup_bg", beautiful.bg_normal or "#222222"),
                selected_bg = self:_theme_value("lxnetwork_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
            }),
            popup_common.make_selectable_click_row(self.state.enabled and "Disable WiFi" or "Enable WiFi", function()
                self:toggle_wifi_enabled()
            end, {
                selected = self._popup_selected_index == 2,
                inner_bg = self:_theme_value("lxnetwork_popup_bg", beautiful.bg_normal or "#222222"),
                hover_bg = self:_theme_value("lxnetwork_button_hover", beautiful.bg_focus or "#444444"),
                outer_bg = self:_theme_value("lxnetwork_popup_bg", beautiful.bg_normal or "#222222"),
                selected_bg = self:_theme_value("lxnetwork_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
            }),
            current_header,
            current_value_container,
            popup_common.make_info_line(string.format(
                "<span foreground='%s'>Known</span>",
                gears.string.xml_escape(self:_theme_value("lxnetwork_meta_fg", beautiful.fg_minimize or "#999999"))
            )),
            known_list,
            popup_common.make_info_line(string.format(
                "<span foreground='%s'>Available</span>",
                gears.string.xml_escape(self:_theme_value("lxnetwork_meta_fg", beautiful.fg_minimize or "#999999"))
            )),
            available_list,
            spacing = 8,
            layout = wibox.layout.fixed.vertical,
        },
        margins = 10,
        widget = wibox.container.margin,
    })
end

function M:hover_close_timeout()
    return self:_theme_value("lxnetwork_hover_close_timeout", 1.5)
end

function M:hover_close_poll_interval()
    return self:_theme_value("lxnetwork_hover_close_poll_interval", 0.25)
end

function M:_ensure_popup_selection()
    local count = #(self._popup_items or {})
    if count < 1 then
        self._popup_selected_index = 1
        return
    end

    self._popup_selected_index = math.max(1, math.min(self._popup_selected_index or 1, count))
end
function M:move_popup_selection(delta)
    self:_ensure_popup_selection()
    local count = #(self._popup_items or {})
    if count < 1 then
        return
    end

    self._popup_selected_index = math.max(1, math.min((self._popup_selected_index or 1) + delta, count))
    if self._popup and self._popup.visible then
        self._popup.widget = self:_build_popup()
    end
end

function M:activate_selected_popup_item()
    self:_ensure_popup_selection()
    local item = (self._popup_items or {})[self._popup_selected_index or 1]
    if item and type(item.on_enter) == "function" then
        item.on_enter()
    end
end

function M:_handle_popup_keygrabber(_, modifiers, key, event)
    local handled = popup_control.dispatch_popup_keypress({
        event = event,
        modifiers = modifiers,
        key = key,
        is_open = function()
            return self._popup and self._popup.visible or false
        end,
        on_not_open = function()
            self:blur_popup_keyboard_navigation()
        end,
        prev_keychain = self._popup_prev_keychain,
        next_keychain = self._popup_next_keychain,
        toggle_key = self._popup_toggle_key,
        on_cycle_prev = self._popup_on_cycle_prev,
        on_cycle_next = self._popup_on_cycle_next,
        on_close = function()
            self:close_popup()
        end,
        actions = {
            Up = function()
                self:move_popup_selection(-1)
            end,
            Down = function()
                self:move_popup_selection(1)
            end,
            Return = function()
                self:activate_selected_popup_item()
            end,
            KP_Enter = function()
                self:activate_selected_popup_item()
            end,
        },
    })

    if handled then
        return
    end
end

function M:focus_popup_keyboard_navigation()
    popup_control.focus_popup_keygrabber(self, {
        handler = function(grabber, modifiers, key, event)
            self:_handle_popup_keygrabber(grabber, modifiers, key, event)
        end,
    })
end

function M:blur_popup_keyboard_navigation()
    popup_control.blur_popup_keygrabber(self)
end

function M:close_popup()
    self:_stop_hover_close_timer()
    self:_stop_popup_outside_click_dismiss()
    self:blur_popup_keyboard_navigation()
    self:_close_password_prompt()
    if self._popup then
        self._popup.visible = false
    end
    widget_feedback.sync(self, self._popup and self._popup.visible or false)
end

function M:_start_popup_outside_click_dismiss()
    popup_control.start_outside_click_dismiss(self, {
        is_open = function()
            return self._popup and self._popup.visible or false
        end,
        geometry_providers = {
            function()
                return self._popup and self._popup:geometry() or nil
            end,
            function()
                return self._password_popup and self._password_popup.visible and self._password_popup:geometry() or nil
            end,
        },
        on_outside_click = function()
            self:close_popup()
        end,
    })
end

function M:_stop_popup_outside_click_dismiss()
    popup_control.stop_outside_click_dismiss(self)
end

function M:_stop_hover_close_timer()
    popup_control.stop_hover_close_timer(self)
end

function M:_start_hover_close_timer()
    popup_control.start_hover_close_timer(self, {
        poll_interval = self:hover_close_poll_interval(),
        hover_timeout = self:hover_close_timeout(),
        is_open = function()
            return self._popup and self._popup.visible or false
        end,
        geometry_providers = {
            function()
                return self._popup and self._popup:geometry() or nil
            end,
            function()
                return self._password_popup and self._password_popup.visible and self._password_popup:geometry() or nil
            end,
        },
        on_timeout = function()
            self:close_popup()
        end,
    })
end

function M:toggle_popup(anchor, opts)
    opts = popup_control.normalize_popup_opts(anchor, opts)

    if self._popup and self._popup.visible then
        self:close_popup()
        return
    end

    self._popup_toggle_key = popup_control.normalize_popup_toggle_key(opts.toggle_key)
    self._popup_prev_keychain = popup_control.normalize_popup_toggle_key(opts.prev_keychain)
    self._popup_next_keychain = popup_control.normalize_popup_toggle_key(opts.next_keychain)
    self._popup_on_cycle_prev = opts.on_cycle_prev
    self._popup_on_cycle_next = opts.on_cycle_next

    if not self._popup then
        self._popup = awful.popup({
            visible = false,
            ontop = true,
            type = "dock",
            bg = self:_theme_value("lxnetwork_popup_bg", beautiful.bg_normal or "#222222"),
            widget = self:_build_popup(),
        })
    else
        self._popup.widget = self:_build_popup()
    end

    apply_popup_geometry(self, self._popup, anchor)
    self._popup.visible = true
    widget_feedback.sync(self, self._popup and self._popup.visible or false)
    self:_refresh_popup()
    self:_start_popup_outside_click_dismiss()

    if opts.keyboard_navigation then
        self:_stop_hover_close_timer()
        self:focus_popup_keyboard_navigation()
    else
        self:blur_popup_keyboard_navigation()
        self:_start_hover_close_timer()
    end
end

function M:scan()
    self.state.scan_in_progress = true
    self.state.networks = {}
    self:_refresh_popup()

    self:_refresh_connection_state(function(known)
        awful.spawn.easy_async_with_shell(
            "nmcli -t -e yes -f IN-USE,SSID,BSSID,SECURITY,SIGNAL,RATE device wifi list --rescan yes 2>/dev/null",
            function(list_stdout)
                local networks = parse_wifi_list(list_stdout)
                local deduped = {}

                for _, network in ipairs(networks) do
                    network.known = known[network.ssid] == true
                    network.standard = infer_wifi_standard(network.rate)

                    local key = network.ssid .. "\0" .. (network.standard or "")
                    local existing = deduped[key]

                    if not existing or network.signal > existing.signal then
                        deduped[key] = network
                    end
                end

                local ordered = {}
                for _, network in pairs(deduped) do
                    ordered[#ordered + 1] = network
                end

                table.sort(ordered, sort_networks)

                self.state.networks = ordered
                self.state.scan_in_progress = false
                self:_refresh_widget()
                self:_refresh_popup()
            end
        )
    end)
end

function M:refresh()
    self:_refresh_connection_state()
end

function M:_start_timer()
    self._timer = gears.timer({
        timeout = self.opts.refresh_interval,
        autostart = true,
        call_now = true,
        callback = function()
            self:refresh()
        end,
    })
end

function M.new(opts)
    opts = merge_defaults(opts)

    local self = setmetatable({}, M)
    self.opts = opts
    self.state = {
        enabled = false,
        current_ssid = nil,
        networks = {},
        scan_in_progress = false,
        vpn_active = false,
    }
    self._popup_selected_index = 1
    self._refs = {}

    local icon = wibox.widget({
        markup = "",
        font = self:_theme_value("lxnetwork_icon_font", beautiful.font),
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
    })
    self._refs.icon = icon

    self.widget = wibox.widget({
        {
            {
                {
                    {
                        icon,
                        halign = "center",
                        valign = "center",
                        widget = wibox.container.place,
                    },
                    forced_width = self:_theme_value("lxnetwork_icon_width", 26),
                    strategy = "exact",
                    widget = wibox.container.constraint,
                },
                layout = wibox.layout.fixed.horizontal,
            },
            left = 1,
            right = 1,
            widget = wibox.container.margin,
        },
        widget = wibox.container.background,
    })

    popup_common.attach_button_feedback(self.widget, {
        idle_bg = nil,
        hover_bg = self:_theme_value("lxnetwork_bg_hover", beautiful.bg_focus or "#444444"),
        press_bg = self:_theme_value("lxnetwork_bg_press", self:_theme_value("lxnetwork_button_hover", beautiful.bg_focus or "#666666")),
    })

    self.widget:buttons(gears.table.join(
        awful.button({}, 1, function()
            self:toggle_popup(mouse.current_widget_geometry)
        end),
        awful.button({}, 3, function()
            self:scan()
        end)
    ))

    self:_refresh_widget()
    self:_start_timer()
    return self
end

return M
