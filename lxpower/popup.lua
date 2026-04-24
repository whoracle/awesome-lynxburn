local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local popup_ui = require("lxcommon.popup_ui")

local popup = {}

local function wrap_card(child)
    return popup_ui.make_card(child, {
        margins = 6,
        radius = 8,
    })
end

local function selectable_card(instance, child, selected, index, onclick, on_right_click)
    return popup_ui.make_selectable_click_container(child, onclick, {
        selected = selected,
        inner_bg = instance:_theme_value("lxpower_popup_bg", beautiful.bg_normal or "#222222"),
        hover_bg = instance:_theme_value("lxpower_button_hover", beautiful.bg_focus or "#444444"),
        outer_bg = instance:_theme_value("lxpower_popup_bg", beautiful.bg_normal or "#222222"),
        selected_bg = instance:_theme_value("lxpower_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
        on_right_click = on_right_click,
        on_hover = function()
            instance:_set_popup_selection(index)
        end,
    })
end

---Attach popup rendering and selection-state methods to the lxpower instance.
function popup.extend(instance_methods)
    function instance_methods:_set_popup_selection(index)
        local items = self._popup_items or {}
        if index == nil or index < 1 or index > #items or self._popup_selected_index == index then
            return
        end

        self._popup_selected_index = index

        for item_index, item in ipairs(items) do
            if item.widget and item.widget._lx_set_selected then
                item.widget:_lx_set_selected(item_index == index)
            end
        end
    end

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
        local status = wrap_card(wibox.widget({
            source,
            profile,
            gpu,
            time,
            spacing = 2,
            layout = wibox.layout.fixed.vertical,
        }))
        local list = wibox.layout.fixed.vertical()
        self._popup_items = {}

        for _, profile_name in ipairs(self:all_profiles()) do
            local next_index = #self._popup_items + 1
            local selected = self._popup_selected_index == next_index
            local label = self:profile_label(profile_name)
            if self.state.pinned and self.state.profile == profile_name then
                label = self:_theme_value("lxpower_icon_pinned", "") .. " " .. label
            end

            local row = selectable_card(
                self,
                popup_ui.make_text(label),
                selected,
                next_index,
                function()
                    self:set_profile(profile_name)
                end,
                function()
                    if self.state.profile == profile_name and self.state.pinned then
                        self:set_pinned(false)
                        return
                    end

                    self:set_profile(profile_name, { pin = true })
                end
            )
            list:add(row)
            self._popup_items[#self._popup_items + 1] = {
                widget = row,
                profile = profile_name,
                on_enter = function()
                    self:set_profile(profile_name)
                end,
                on_space = function()
                    if self.state.profile == profile_name and self.state.pinned then
                        self:set_pinned(false)
                        return
                    end

                    self:set_profile(profile_name, { pin = true })
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

        self:_set_popup_selection(math.max(1, math.min((self._popup_selected_index or 1) + delta, count)))
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
