local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local popup_common = require("lxcommon.popup_ui")
local popup_placement = require("lxcommon.popup_placement")
local screen_util = require("lxcommon.screen")

local popup = {}

local function theme_value(self, key, fallback)
    local value = beautiful[key]
    if value ~= nil then
        return value
    end

    return fallback
end

local function apply_popup_geometry(self, popup_widget, anchor)
    local target_screen = screen_util.resolve_screen(anchor)
    popup_placement.apply(
        popup_widget,
        target_screen,
        theme_value(self, "lxdisplay_popup_placement", "center"),
        { width = math.min(theme_value(self, "lxdisplay_popup_width", 380), target_screen.workarea.width) }
    )
end

local function section_header(self, text)
    return popup_common.make_info_line(string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(theme_value(self, "lxdisplay_meta_fg", beautiful.fg_minimize or "#999999")),
        gears.string.xml_escape(text)
    ), {
        top = 4,
        bottom = 2,
    })
end

local function status_line(self, text)
    return popup_common.make_info_line(string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(theme_value(self, "lxdisplay_meta_fg", beautiful.fg_minimize or "#999999")),
        gears.string.xml_escape(text)
    ))
end

local function selectable_card(self, child, selected, index, onclick)
    return popup_common.make_selectable_click_container(child, onclick, {
        selected = selected,
        inner_bg = theme_value(self, "lxdisplay_popup_bg", beautiful.bg_normal or "#222222"),
        hover_bg = theme_value(self, "lxdisplay_button_hover", beautiful.bg_focus or "#444444"),
        outer_bg = theme_value(self, "lxdisplay_popup_bg", beautiful.bg_normal or "#222222"),
        selected_bg = theme_value(self, "lxdisplay_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
        on_hover = function()
            self:_set_popup_selection(index)
        end,
    })
end

local function profile_card(self, profile, index)
    local output_names = self:_profile_output_names(profile)
    local outputs_line = table.concat(output_names, " + ")
    local topology_line = self:_profile_topology_summary(profile) or "single-output layout"
    local missing = self:_profile_missing_outputs(profile, self.state.connected_output_set or {})
    local suffix = ""

    if self.state.active_profile_index == index then
        suffix = " (active)"
    elseif #missing > 0 then
        suffix = " (missing: " .. table.concat(missing, ", ") .. ")"
    end

    local card = wibox.widget({
        {
            markup = gears.string.xml_escape((profile.name or "Profile") .. suffix),
            ellipsize = "end",
            widget = wibox.widget.textbox,
        },
        {
            markup = string.format(
                "<span foreground='%s'>%s</span>",
                gears.string.xml_escape(theme_value(self, "lxdisplay_meta_fg", beautiful.fg_minimize or "#999999")),
                gears.string.xml_escape(outputs_line ~= "" and outputs_line or "no outputs configured")
            ),
            ellipsize = "end",
            widget = wibox.widget.textbox,
        },
        {
            markup = string.format(
                "<span foreground='%s'>%s</span>",
                gears.string.xml_escape(theme_value(self, "lxdisplay_meta_fg", beautiful.fg_minimize or "#999999")),
                gears.string.xml_escape(topology_line)
            ),
            ellipsize = "end",
            widget = wibox.widget.textbox,
        },
        spacing = 2,
        layout = wibox.layout.fixed.vertical,
    })

    return selectable_card(self, card, self._popup_selected_index == index, index, function()
        self:activate_profile(index)
    end)
end

local function detected_output_card(self, output, action_entries)
    local list = wibox.layout.fixed.vertical()
    list:add(wibox.widget({
        {
            markup = gears.string.xml_escape(output.name),
            widget = wibox.widget.textbox,
        },
        {
            markup = string.format(
                "<span foreground='%s'>temporary display</span>",
                gears.string.xml_escape(theme_value(self, "lxdisplay_meta_fg", beautiful.fg_minimize or "#999999"))
            ),
            widget = wibox.widget.textbox,
        },
        spacing = 2,
        layout = wibox.layout.fixed.vertical,
    }))

    local actions = {
        { label = "Extend", action = "extend" },
        { label = "Mirror", action = "mirror" },
        { label = "Disable", action = "disable" },
    }

    for _, action in ipairs(actions) do
        local next_index = #self._popup_items + 1
        local row = selectable_card(self, popup_common.make_text(action.label), self._popup_selected_index == next_index, next_index, function()
            self:configure_detected_output(output.name, action.action)
        end)
        list:add(row)
        self._popup_items[#self._popup_items + 1] = {
            widget = row,
            on_enter = function()
                self:configure_detected_output(output.name, action.action)
            end,
        }
        action_entries[#action_entries + 1] = row
    end

    return popup_common.make_card({
        list,
        margins = 0,
        widget = wibox.container.margin,
    }, {
        margins = 6,
    })
end

function popup.extend(instance_methods)
    function instance_methods:hover_close_timeout()
        return theme_value(self, "lxdisplay_hover_close_timeout", 1.5)
    end

    function instance_methods:hover_close_poll_interval()
        return theme_value(self, "lxdisplay_hover_close_poll_interval", 0.25)
    end

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

        local refs = self._popup_refs
        refs.profiles:reset()
        refs.detected:reset()
        self._popup_items = {}

        local detect_index = 1
        refs.detect_action:_lx_set_selected(self._popup_selected_index == detect_index)
        self._popup_items[#self._popup_items + 1] = {
            widget = refs.detect_action,
            on_enter = function()
                self:detect_displays()
            end,
        }

        if #self._profiles == 0 then
            refs.profiles:add(status_line(self, "No display profiles configured."))
        else
            for profile_index, profile in ipairs(self._profiles) do
                local next_index = #self._popup_items + 1
                local card = profile_card(self, profile, profile_index)
                refs.profiles:add(card)
                self._popup_items[#self._popup_items + 1] = {
                    widget = card,
                    on_enter = function()
                        self:activate_profile(profile_index)
                    end,
                }
                if self._popup_selected_index == next_index then
                    card:_lx_set_selected(true)
                end
            end
        end

        if #(self.state.detected_outputs or {}) == 0 then
            refs.detected:add(status_line(self, "No unassigned displays detected."))
        else
            for _, output in ipairs(self.state.detected_outputs or {}) do
                refs.detected:add(detected_output_card(self, output, {}))
            end
        end

        self:_ensure_popup_selection()
        self:_set_popup_selection(self._popup_selected_index)
    end

    function instance_methods:_build_popup()
        local detect_action = selectable_card(
            self,
            popup_common.make_text("Detect Displays"),
            self._popup_selected_index == 1,
            1,
            function()
                self:detect_displays()
            end
        )
        local profiles = wibox.layout.fixed.vertical()
        local detected = wibox.layout.fixed.vertical()

        self._popup_refs = {
            detect_action = detect_action,
            profiles = profiles,
            detected = detected,
        }

        self:_refresh_popup()

        return wibox.widget({
            {
                detect_action,
                section_header(self, "Profiles"),
                profiles,
                section_header(self, "Detected Displays"),
                detected,
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

    function instance_methods:_ensure_popup(anchor)
        if not self._popup then
            self._popup = awful.popup({
                visible = false,
                ontop = true,
                type = "dock",
                bg = theme_value(self, "lxdisplay_popup_bg", beautiful.bg_normal or "#222222"),
                widget = self:_build_popup(),
            })
        else
            self._popup.widget = self:_build_popup()
        end

        apply_popup_geometry(self, self._popup, anchor)
        return self._popup
    end
end

return popup
