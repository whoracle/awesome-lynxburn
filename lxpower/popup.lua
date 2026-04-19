local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local popup_ui = require("lxcommon.popup_ui")

local popup = {}

---Attach popup rendering and selection-state methods to the lxpower instance.
function popup.extend(instance_methods)
    function instance_methods:_refresh_popup()
        if not self._popup_refs then
            return
        end

        local meta_fg = gears.string.xml_escape(self:_theme_value("lxpower_meta_fg", beautiful.fg_minimize or "#999999"))
        local label

        if self.state.power_source == "battery" then
            label = self.state.time_label and ("Time to empty: " .. self.state.time_label) or "Time to empty: -"
        elseif self.state.battery_status == "Charging" then
            label = self.state.time_label and ("Time to full: " .. self.state.time_label) or "Time to full: -"
        else
            label = "Time to full: -"
        end

        self._popup_refs.source.markup = string.format(
            "<span foreground='%s'>Source: %s</span>",
            meta_fg,
            gears.string.xml_escape(self.state.power_source == "ac" and "AC" or "battery")
        )
        self._popup_refs.profile.markup = string.format(
            "<span foreground='%s'>Current Profile: %s</span>",
            meta_fg,
            gears.string.xml_escape(self:profile_label(self.state.profile))
        )
        self._popup_refs.gpu.markup = string.format(
            "<span foreground='%s'>dGPU: %s</span>",
            meta_fg,
            gears.string.xml_escape(self.state.dgpu_status or "unknown")
        )
        self._popup_refs.time.markup = string.format(
            "<span foreground='%s'>%s</span>",
            meta_fg,
            gears.string.xml_escape(label)
        )
    end

    function instance_methods:_build_popup()
        local source = wibox.widget({ markup = "", widget = wibox.widget.textbox })
        local profile = wibox.widget({ markup = "", widget = wibox.widget.textbox })
        local gpu = wibox.widget({ markup = "", widget = wibox.widget.textbox })
        local time = wibox.widget({ markup = "", widget = wibox.widget.textbox })
        local status = wibox.widget({
            source,
            profile,
            gpu,
            time,
            spacing = 2,
            layout = wibox.layout.fixed.vertical,
        })
        local list = wibox.layout.fixed.vertical()
        self._popup_items = {}

        for _, profile_name in ipairs(self:all_profiles()) do
            local selected = self._popup_selected_index == (#self._popup_items + 1)
            local label = self:profile_label(profile_name)
            if self.state.pinned and self.state.profile == profile_name then
                label = self:_theme_value("lxpower_icon_pinned", "") .. " " .. label
            end

            list:add(popup_ui.make_selectable_click_row(label, function()
                self:set_profile(profile_name)
            end, {
                selected = selected,
                inner_bg = self:_theme_value("lxpower_popup_bg", beautiful.bg_normal or "#222222"),
                hover_bg = self:_theme_value("lxpower_button_hover", beautiful.bg_focus or "#444444"),
                outer_bg = self:_theme_value("lxpower_popup_bg", beautiful.bg_normal or "#222222"),
                selected_bg = self:_theme_value("lxpower_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
            }))
            self._popup_items[#self._popup_items + 1] = {
                profile = profile_name,
                on_enter = function()
                    self:set_profile(profile_name)
                end,
            }
        end

        self._popup_refs = {
            status = status,
            source = source,
            profile = profile,
            gpu = gpu,
            time = time,
            list = list,
        }

        self:_refresh_popup()

        return wibox.widget({
            {
                status,
                list,
                spacing = 8,
                layout = wibox.layout.fixed.vertical,
            },
            margins = 10,
            widget = wibox.container.margin,
        })
    end

    function instance_methods:_ensure_popup_selection()
        local count = #(self._popup_items or {})
        if count < 1 then
            self._popup_selected_index = 1
            return
        end

        self._popup_selected_index = math.max(1, math.min(self._popup_selected_index or 1, count))
    end

    function instance_methods:move_popup_selection(delta)
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

    function instance_methods:activate_selected_popup_item()
        self:_ensure_popup_selection()
        local item = (self._popup_items or {})[self._popup_selected_index or 1]
        if item and type(item.on_enter) == "function" then
            item.on_enter()
        end
    end

    function instance_methods:pin_selected_profile()
        self:_ensure_popup_selection()
        local item = (self._popup_items or {})[self._popup_selected_index or 1]
        if not (item and item.profile) then
            return
        end

        if self.state.profile == item.profile then
            self:set_pinned(true)
            return
        end

        self:set_profile(item.profile, { pin = true })
    end
end

return popup
