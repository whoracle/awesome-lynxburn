local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local keygrabber = require("awful.keygrabber")

local popup_common = require("lxaudio.popup_common")
local util = require("lxaudio.util")

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

local function parse_wifi_list(stdout)
    local networks = {}

    for _, line in ipairs(util.split_lines(stdout)) do
        local active, ssid, bssid, security, signal = line:match("^([^:]*):(.*):([^:]*):([^:]*):([^:]*)$")
        if bssid then
            networks[#networks + 1] = {
                active = active == "*",
                ssid = ssid ~= "" and ssid or "<hidden>",
                bssid = bssid,
                security = security,
                signal = tonumber(signal) or 0,
            }
        end
    end

    return networks
end

local function parse_known_connections(stdout)
    local known = {}

    for _, line in ipairs(util.split_lines(stdout)) do
        local name, kind = line:match("^([^:]+):([^:]+)$")
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
        local name, kind = line:match("^([^:]+):([^:]+)$")
        if name and kind == "802-11-wireless" then
            current.ssid = name
            break
        end
    end

    return current
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

    self._refs.icon.markup = string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(fg),
        gears.string.xml_escape(self:_theme_value("lxnetwork_icon", ""))
    )

    local label = "WiFi off"
    if self.state.enabled then
        label = self.state.current_ssid and ("WiFi " .. self.state.current_ssid) or "WiFi idle"
    end

    self._refs.label.markup = string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(fg),
        gears.string.xml_escape(label)
    )
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

function M:_refresh_popup()
    if not self._popup_refs then
        return
    end

    local refs = self._popup_refs
    refs.current.markup = string.format(
        "<span foreground='%s'>Current: %s</span>",
        gears.string.xml_escape(self:_theme_value("lxnetwork_meta_fg", beautiful.fg_minimize or "#999999")),
        gears.string.xml_escape(self.state.current_ssid or "offline")
    )

    refs.known_list:reset()
    refs.available_list:reset()
    local known_count = 0
    local available_count = 0

    for _, network in ipairs(self.state.networks) do
        local label = string.format("%s  %d%%", network.ssid, network.signal)
        if network.security ~= "" and network.security ~= "--" then
            label = label .. "  [" .. network.security .. "]"
        end
        if network.active then
            label = "● " .. label
        end

        local row = popup_common.make_click_row(label, function()
            self:_connect_network(network)
        end, {
            idle_bg = self:_theme_value("lxnetwork_button_bg", beautiful.bg_minimize or "#222222"),
            hover_bg = self:_theme_value("lxnetwork_button_hover", beautiful.bg_focus or "#444444"),
        })

        if network.known then
            refs.known_list:add(row)
            known_count = known_count + 1
        else
            refs.available_list:add(row)
            available_count = available_count + 1
        end
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
    local current = wibox.widget({
        markup = "",
        widget = wibox.widget.textbox,
    })
    local known_list = wibox.layout.fixed.vertical()
    local available_list = wibox.layout.fixed.vertical()

    self._popup_refs = {
        current = current,
        known_list = known_list,
        available_list = available_list,
    }

    self:_refresh_popup()

    return wibox.widget({
        {
            popup_common.make_click_row("Scan WiFi", function()
                self:scan()
            end, {
                idle_bg = self:_theme_value("lxnetwork_button_bg", beautiful.bg_minimize or "#222222"),
                hover_bg = self:_theme_value("lxnetwork_button_hover", beautiful.bg_focus or "#444444"),
            }),
            current,
            popup_common.make_info_line(string.format(
                "<span foreground='%s'>Known</span>",
                gears.string.xml_escape(self:_theme_value("lxnetwork_widget_fg", beautiful.fg_normal or "#ffffff"))
            )),
            known_list,
            popup_common.make_info_line(string.format(
                "<span foreground='%s'>Available</span>",
                gears.string.xml_escape(self:_theme_value("lxnetwork_widget_fg", beautiful.fg_normal or "#ffffff"))
            )),
            available_list,
            spacing = 8,
            layout = wibox.layout.fixed.vertical,
        },
        margins = 10,
        widget = wibox.container.margin,
    })
end

function M:toggle_popup(anchor)
    local visible = popup_common.toggle_popup(self, "_popup", "_popup_anchor", anchor, function()
        return self:_build_popup()
    end)

    if visible then
        self:_refresh_popup()
    end
end

function M:scan()
    awful.spawn.easy_async_with_shell("nmcli device wifi list --rescan yes >/dev/null 2>&1", function()
        self:refresh()
    end)
end

function M:refresh()
    awful.spawn.easy_async_with_shell("nmcli radio wifi 2>/dev/null", function(radio_stdout)
        local enabled = tostring(radio_stdout or ""):match("enabled") ~= nil

        awful.spawn.easy_async_with_shell(
            "nmcli -t -e no -f NAME,TYPE connection show --active 2>/dev/null",
            function(active_stdout)
                local active = parse_active_connection(active_stdout)

                awful.spawn.easy_async_with_shell(
                    "nmcli -t -e no -f NAME,TYPE connection show 2>/dev/null",
                    function(known_stdout)
                        local known = parse_known_connections(known_stdout)

                        awful.spawn.easy_async_with_shell(
                            "nmcli -t -e no -f IN-USE,SSID,BSSID,SECURITY,SIGNAL device wifi list --rescan no 2>/dev/null",
                            function(list_stdout)
                                local networks = parse_wifi_list(list_stdout)
                                local deduped = {}

                                for _, network in ipairs(networks) do
                                    local key = network.ssid .. "\0" .. network.bssid
                                    if not deduped[key] then
                                        network.known = known[network.ssid] == true
                                        deduped[key] = network
                                    end
                                end

                                local ordered = {}
                                for _, network in pairs(deduped) do
                                    ordered[#ordered + 1] = network
                                end
                                table.sort(ordered, sort_networks)

                                self.state.enabled = enabled
                                self.state.current_ssid = active.ssid
                                self.state.networks = ordered
                                self:_refresh_widget()
                                self:_refresh_popup()
                            end
                        )
                    end
                )
            end
        )
    end)
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
    }
    self._refs = {}

    local icon = wibox.widget({ markup = "", widget = wibox.widget.textbox })
    local label = wibox.widget({ markup = "", widget = wibox.widget.textbox })
    self._refs.icon = icon
    self._refs.label = label

    self.widget = wibox.widget({
        {
            icon,
            label,
            spacing = 6,
            layout = wibox.layout.fixed.horizontal,
        },
        left = 8,
        right = 8,
        widget = wibox.container.margin,
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
