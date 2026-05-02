local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local popup_common = require("lxcommon.popup_ui")
local popup_placement = require("lxcommon.popup_placement")
local screen_util = require("lxcommon.screen")

local M = {}

local function apply_popup_geometry(instance, popup_widget, anchor)
    local target_screen = screen_util.resolve_screen(anchor)
    popup_placement.apply(
        popup_widget,
        target_screen,
        instance:_theme_value("lxsecrets_popup_placement", "side"),
        { width = math.min(instance:_theme_value("lxsecrets_popup_width", 380), target_screen.workarea.width) }
    )
end

local function section_header(instance, text)
    return popup_common.make_info_line(string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(instance:_theme_value("lxsecrets_meta_fg", beautiful.fg_minimize or "#999999")),
        gears.string.xml_escape(text)
    ), {
        top = 4,
        bottom = 2,
    })
end

local function status_line(instance, text)
    return popup_common.make_info_line(string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(instance:_theme_value("lxsecrets_meta_fg", beautiful.fg_minimize or "#999999")),
        gears.string.xml_escape(text)
    ))
end

local function selectable_card(instance, child, selected, index, onclick, opts)
    opts = opts or {}
    return popup_common.make_selectable_click_container(child, onclick, {
        selected = selected,
        inner_bg = instance:_theme_value("lxsecrets_popup_bg", beautiful.bg_normal or "#222222"),
        hover_bg = instance:_theme_value("lxsecrets_popup_bg", beautiful.bg_normal or "#222222"),
        outer_bg = instance:_theme_value("lxsecrets_popup_bg", beautiful.bg_normal or "#222222"),
        selected_bg = instance:_theme_value("lxsecrets_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
        on_right_click = opts.on_right_click,
        on_middle_click = opts.on_middle_click,
        on_scroll_up = opts.on_scroll_up,
        on_scroll_down = opts.on_scroll_down,
        on_hover = function()
            instance:_set_popup_selection(index)
        end,
    })
end

local function selectable_shell(instance, child, selected, index)
    local selection_margin = 2
    local selection_wrapper = wibox.widget({
        child,
        margins = selected and selection_margin or 0,
        widget = wibox.container.margin,
    })

    local outer = wibox.widget({
        selection_wrapper,
        bg = selected
            and instance:_theme_value("lxsecrets_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666")
            or instance:_theme_value("lxsecrets_popup_bg", beautiful.bg_normal or "#222222"),
        shape = gears.shape.rounded_rect,
        widget = wibox.container.background,
    })

    outer:connect_signal("mouse::enter", function()
        instance:_set_popup_selection(index)
    end)

    function outer:_lx_set_selected(value)
        selection_wrapper.margins = value and selection_margin or 0
        outer.bg = value
            and instance:_theme_value("lxsecrets_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666")
            or instance:_theme_value("lxsecrets_popup_bg", beautiful.bg_normal or "#222222")
    end

    function outer:_lx_set_feedback_active(value)
        outer:_lx_set_selected(value)
    end

    return outer
end

local function badge(label, fg)
    return wibox.widget({
        markup = string.format("<span size='x-small' foreground='%s'>[%s]</span>", fg, label),
        widget = wibox.widget.textbox,
    })
end

local function action_button(instance, label, onclick)
    local text = wibox.widget({
        text = label,
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
    })

    local button = wibox.widget({
        {
            text,
            left = 10,
            right = 10,
            top = 6,
            bottom = 6,
            widget = wibox.container.margin,
        },
        bg = instance:_theme_value("lxsecrets_button_bg", beautiful.bg_minimize or "#222222"),
        widget = wibox.container.background,
    })

    popup_common.attach_button_feedback(button, {
        idle_bg = instance:_theme_value("lxsecrets_button_bg", beautiful.bg_minimize or "#222222"),
        hover_bg = instance:_theme_value("lxsecrets_button_hover", beautiful.bg_focus or "#444444"),
    })

    button:buttons(gears.table.join(
        awful.button({}, 1, onclick)
    ))

    return button
end

local function summary_controls_row(instance, selected, index)
    local refresh_button = action_button(instance, "Refresh all", function()
        instance:refresh_all()
    end)
    local suspend_label = instance.state.suspended and "Resume checks" or "Pause checks"
    local suspend_button = action_button(instance, suspend_label, function()
        instance:toggle_suspended()
    end)

    local row = wibox.widget({
        {
            {
                refresh_button,
                suspend_button,
                spacing = 8,
                layout = wibox.layout.fixed.horizontal,
            },
            widget = wibox.container.place,
            halign = "center",
        },
        left = 12,
        right = 8,
        top = 6,
        bottom = 6,
        widget = wibox.container.margin,
    })

    return selectable_card(instance, row, selected, index, function()
        instance:refresh_all()
    end, {
        on_right_click = function()
            instance:toggle_suspended()
        end,
    })
end

local function secret_row(instance, secret, selected, selection_index, secret_index)
    local meta_fg = gears.string.xml_escape(instance:_theme_value("lxsecrets_meta_fg", beautiful.fg_minimize or "#999999"))
    local accent_fg = gears.string.xml_escape(instance:_theme_value("lxsecrets_widget_attention_fg", beautiful.fg_critical or "#d97777"))
    local normal_fg = gears.string.xml_escape(instance:_theme_value("lxsecrets_widget_fg", beautiful.fg_normal or "#ffffff"))
    local title_fg = secret.expired and accent_fg or normal_fg

    local title = wibox.widget({
        markup = string.format(
            "<span foreground='%s'>%s</span>",
            title_fg,
            gears.string.xml_escape(secret.name)
        ),
        ellipsize = "end",
        widget = wibox.widget.textbox,
    })

    local badges = wibox.layout.fixed.horizontal()
    badges.spacing = 4
    if secret.expired then
        badges:add(badge("expired", accent_fg))
    end
    if secret.vpn and secret.vpn ~= "" then
        badges:add(badge(tostring(secret.vpn), meta_fg))
    end

    local title_row = wibox.widget({
        title,
        nil,
        badges,
        expand = "inside",
        layout = wibox.layout.align.horizontal,
    })

    local info = wibox.layout.fixed.vertical()
    info.spacing = 4
    info:add(title_row)

    for _, line in ipairs(instance:secret_metadata_lines(secret)) do
        info:add(wibox.widget({
            markup = string.format("<span size='x-small' foreground='%s'>%s</span>", meta_fg, gears.string.xml_escape(line)),
            ellipsize = "end",
            widget = wibox.widget.textbox,
        }))
    end

    if secret.status == "error" and secret.last_message and secret.last_message ~= "" then
        info:add(wibox.widget({
            markup = string.format("<span size='x-small' foreground='%s'>%s</span>", accent_fg, gears.string.xml_escape(secret.last_message)),
            ellipsize = "end",
            widget = wibox.widget.textbox,
        }))
    end

    local primary_label = secret.auth_required and "Login" or "Refresh"
    local primary_action = function()
        if secret.auth_required then
            instance:login_secret(secret_index)
        else
            instance:refresh_secret(secret_index)
        end
    end

    local buttons = wibox.layout.fixed.horizontal()
    buttons.spacing = 8
    buttons:add(action_button(instance, primary_label, primary_action))

    local info_card = popup_common.make_click_container(info, function()
        primary_action()
    end, {
        left = 12,
        right = 8,
        top = 6,
        bottom = 6,
        idle_bg = instance:_theme_value("lxsecrets_popup_bg", beautiful.bg_normal or "#222222"),
        hover_bg = instance:_theme_value("lxsecrets_popup_bg", beautiful.bg_normal or "#222222"),
    })
    info_card:connect_signal("mouse::enter", function()
        instance:_set_popup_selection(selection_index)
    end)

    local content = wibox.widget({
        {
            info_card,
            {
                buttons,
                top = 8,
                left = 12,
                right = 8,
                bottom = 6,
                widget = wibox.container.margin,
            },
            spacing = 0,
            layout = wibox.layout.fixed.vertical,
        },
        bg = instance:_theme_value("lxsecrets_popup_bg", beautiful.bg_normal or "#222222"),
        widget = wibox.container.background,
    })

    local outer = popup_common.make_card({
        content,
        widget = wibox.container.background,
    }, {
        radius = 4,
    })

    return selectable_shell(instance, outer, selected, selection_index)
end

function M.extend(instance_methods)
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
            if item.widget and item.widget._lx_set_feedback_active then
                item.widget:_lx_set_feedback_active(item_index == index)
            end
        end
    end

    function instance_methods:_refresh_popup(opts)
        opts = opts or {}
        if not self._popup_refs then
            return
        end

        local refs = self._popup_refs
        refs.summary:reset()
        refs.sections:reset()
        self._popup_items = {}

        refs.summary:add(status_line(self, self:popup_summary()))

        local next_index = 1
        local refresh_row = summary_controls_row(self, self._popup_selected_index == next_index, next_index)
        refs.summary:add(refresh_row)
        self._popup_items[#self._popup_items + 1] = {
            widget = refresh_row,
            on_enter = function()
                self:refresh_all()
            end,
            on_space = function()
                self:toggle_suspended()
            end,
        }

        if not opts.immediate then
            refs.sections:add(status_line(self, "Loading secrets..."))
            gears.timer.delayed_call(function()
                if self._popup_refs == refs and self:popup_visible("_popup") then
                    self:_refresh_popup({ immediate = true })
                end
            end)
            return
        end

        local groups, order = self:provider_groups()
        if #order == 0 then
            refs.sections:add(status_line(self, "No secrets configured."))
        end

        for _, group in ipairs(order) do
            local secrets = groups[group] or {}
            refs.sections:add(section_header(self, (secrets[1] and secrets[1].provider_label) or group))

            for _, secret in ipairs(secrets) do
                local item_index = #self._popup_items + 1
                local row = secret_row(
                    self,
                    secret,
                    self._popup_selected_index == item_index,
                    item_index,
                    secret.index
                )
                refs.sections:add(row)
                self._popup_items[#self._popup_items + 1] = {
                    widget = row,
                    on_enter = function()
                        if secret.auth_required then
                            self:login_secret(secret.index)
                        else
                            self:refresh_secret(secret.index)
                        end
                    end,
                }
            end
        end

        self:_ensure_popup_selection()
        for item_index, item in ipairs(self._popup_items) do
            if item.widget and item.widget._lx_set_selected then
                item.widget:_lx_set_selected(item_index == self._popup_selected_index)
            end
            if item.widget and item.widget._lx_set_feedback_active then
                item.widget:_lx_set_feedback_active(item_index == self._popup_selected_index)
            end
        end
    end

    function instance_methods:_build_popup()
        local summary = wibox.layout.fixed.vertical()
        summary.spacing = 6
        local sections = wibox.layout.fixed.vertical()
        sections.spacing = 4

        self._popup_refs = {
            summary = summary,
            sections = sections,
        }

        self:_refresh_popup()

        return wibox.widget({
            {
                summary,
                sections,
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

    function instance_methods:activate_selected_popup_secondary()
        self:_ensure_popup_selection()
        local item = (self._popup_items or {})[self._popup_selected_index or 1]
        if item and type(item.on_space) == "function" then
            item.on_space()
        end
    end

    function instance_methods:_ensure_popup(anchor)
        if not self._popup then
            self._popup = awful.popup({
                visible = false,
                ontop = true,
                type = "dock",
                bg = self:_theme_value("lxsecrets_popup_bg", beautiful.bg_normal or "#222222"),
                widget = self:_build_popup(),
            })
        else
            self._popup.widget = self:_build_popup()
        end

        apply_popup_geometry(self, self._popup, anchor)
        return self._popup
    end
end

return M
