local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local keygrabber = require("awful.keygrabber")

local util = require("lxmedia.util")

local password_prompt = {}

---Attach password-prompt helpers to the lxnetwork instance method table.
function password_prompt.extend(instance_methods)
    function instance_methods:_close_password_prompt()
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

    function instance_methods:_refresh_password_prompt()
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

    function instance_methods:_submit_password()
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

    function instance_methods:_show_password_prompt(target)
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
end

return password_prompt
