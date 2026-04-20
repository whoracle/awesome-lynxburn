local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local actions = require("lxnotify.actions")
local util = require("lxcommon.util")

local cards = {}

local URGENCY_LABELS = {
    low = "low",
    normal = "normal",
    critical = "critical",
}

local URGENCY_COLORS = {
    low = "#7aa2c9",
    normal = "#c0b18b",
    critical = "#d97777",
}

local function attach_buttons(widgets, buttons)
    local joined = gears.table.join(table.unpack(buttons))

    for _, widget in ipairs(widgets) do
        if widget then
            widget:buttons(joined)
        end
    end
end

---Build a compact card for one stored notification entry.
---@param instance table
---@param entry table
---@param opts table|nil
---@return table
function cards.build_notification_card(instance, entry, opts)
    opts = opts or {}
    local urgency = entry.urgency
    local urgency_label = URGENCY_LABELS[urgency] or urgency
    local urgency_color = util.theme_value("lxnotify_urgency_" .. urgency .. "_fg", URGENCY_COLORS[urgency] or beautiful.fg_urgent or "#d97777")
    local label_fg = instance:notification_meta_fg()
    local body_visible = entry.body ~= ""
    local title_visible = entry.title ~= ""
    local urgency_visible = urgency ~= "normal"
    local updated_visible = entry.updated_at ~= nil

    local source = wibox.widget({
        markup = string.format(
            "<span foreground='%s'>Source:</span> %s",
            gears.string.xml_escape(label_fg),
            gears.string.xml_escape(entry.source)
        ),
        align = "left",
        valign = "center",
        widget = wibox.widget.textbox,
    })

    local title = wibox.widget({
        markup = string.format(
            "<span foreground='%s'>Title:</span> %s",
            gears.string.xml_escape(label_fg),
            gears.string.xml_escape(entry.title)
        ),
        align = "left",
        valign = "top",
        widget = wibox.widget.textbox,
        visible = title_visible,
    })

    local urgency_widget = wibox.widget({
        markup = string.format(
            "<span foreground='%s'>Urgency:</span> <span foreground='%s'>%s</span>",
            gears.string.xml_escape(label_fg),
            gears.string.xml_escape(urgency_color),
            gears.string.xml_escape(urgency_label)
        ),
        align = "left",
        valign = "center",
        widget = wibox.widget.textbox,
        visible = urgency_visible,
    })

    local body = wibox.widget({
        markup = string.format(
            "<span foreground='%s'>Message:</span> %s",
            gears.string.xml_escape(label_fg),
            gears.string.xml_escape(entry.body)
        ),
        align = "left",
        valign = "top",
        widget = wibox.widget.textbox,
        visible = body_visible,
    })

    local created = wibox.widget({
        markup = string.format(
            "<span foreground='%s'>Created:</span> %s",
            gears.string.xml_escape(label_fg),
            gears.string.xml_escape(entry.created_at)
        ),
        align = "left",
        valign = "center",
        widget = wibox.widget.textbox,
    })

    local updated = wibox.widget({
        markup = string.format(
            "<span foreground='%s'>Last Updated:</span> %s",
            gears.string.xml_escape(label_fg),
            gears.string.xml_escape(entry.updated_at or "")
        ),
        align = "left",
        valign = "center",
        widget = wibox.widget.textbox,
        visible = updated_visible,
    })

    local content = wibox.widget({
        source,
        title,
        urgency_widget,
        body,
        created,
        updated,
        spacing = 4,
        layout = wibox.layout.fixed.vertical,
    })

    local row_children = {
        layout = wibox.layout.fixed.horizontal,
        spacing = 10,
    }

    if entry.icon then
        row_children[#row_children + 1] = wibox.widget({
            {
                image = entry.icon,
                resize = true,
                forced_width = instance:notification_icon_size(),
                forced_height = instance:notification_icon_size(),
                widget = wibox.widget.imagebox,
            },
            valign = "top",
            halign = "center",
            widget = wibox.container.place,
        })
    end

    row_children[#row_children + 1] = content

    local card_inner = wibox.widget({
        {
            row_children,
            widget = wibox.container.margin,
            top = 9,
            bottom = 9,
            left = 12,
            right = 12,
        },
        widget = wibox.container.background,
        bg = instance:notification_card_bg(),
    })

    local card = wibox.widget({
        {
            card_inner,
            margins = opts.selected and 2 or 0,
            widget = wibox.container.margin,
        },
        widget = wibox.container.background,
        bg = opts.selected and instance:notification_selected_bg() or instance:popup_bg(),
        shape = gears.shape.rounded_rect,
    })

    util.attach_hover_background(card_inner, instance:notification_card_bg(), instance:notification_hover_bg())

    local function dismiss()
        actions.destroy(entry.notification)
        instance:dismiss_notification(entry.id)
    end

    local function invoke()
        if actions.invoke(entry.notification) then
            instance:dismiss_notification(entry.id)
            return true
        end

        return false
    end

    local function select_card()
        if opts.selection_index and instance.popup_selected_index ~= opts.selection_index then
            instance.popup_selected_index = opts.selection_index
            instance:refresh_popup()
        end
    end

    card:connect_signal("mouse::enter", select_card)
    card_inner:connect_signal("mouse::enter", select_card)

    attach_buttons({card, card_inner}, {
        awful.button({}, 1, function()
            dismiss()
        end),
        awful.button({}, 3, function()
            select_card()
            invoke()
        end),
        table.unpack(opts.extra_buttons or {})
    })

    return {
        widget = card,
        on_space = dismiss,
        on_enter = invoke,
    }
end

---Build the burst-group summary card shown in the main inbox view.
---@param instance table
---@param group table
---@param opts table|nil
---@return table
function cards.build_group_card(instance, group, opts)
    opts = opts or {}
    local latest = group.entries[#group.entries]
    local count = #group.entries
    local latest_timestamp = latest.updated_at or latest.created_at

    local header_row = {
        spacing = 10,
        layout = wibox.layout.fixed.horizontal,
    }

    if latest.icon then
        header_row[#header_row + 1] = wibox.widget({
            {
                image = latest.icon,
                resize = true,
                forced_width = instance:notification_group_icon_size(),
                forced_height = instance:notification_group_icon_size(),
                widget = wibox.widget.imagebox,
            },
            widget = wibox.container.place,
            valign = "center",
            halign = "center",
        })
    end

    header_row[#header_row + 1] = wibox.widget({
        {
            markup = string.format(
                "<span foreground='%s'>Source:</span> %s",
                gears.string.xml_escape(instance:notification_meta_fg()),
                gears.string.xml_escape(latest.source)
            ),
            align = "left",
            widget = wibox.widget.textbox,
        },
        {
            markup = string.format("<b>%dx</b>", count),
            align = "right",
            widget = wibox.widget.textbox,
        },
        layout = wibox.layout.align.horizontal,
    })

    local header = wibox.widget({
        {
            header_row,
            {
                {
                    markup = string.format(
                        "<span foreground='%s'>Title:</span> %s",
                        gears.string.xml_escape(instance:notification_meta_fg()),
                        gears.string.xml_escape(string.format("%d notifications", count))
                    ),
                    align = "left",
                    widget = wibox.widget.textbox,
                },
                {
                    markup = string.format(
                        "<span foreground='%s'>Open</span>",
                        gears.string.xml_escape(instance:notification_meta_fg())
                    ),
                    align = "right",
                    widget = wibox.widget.textbox,
                },
                layout = wibox.layout.align.horizontal,
            },
            {
                markup = string.format(
                    "<span foreground='%s'>Message:</span> %s",
                    gears.string.xml_escape(instance:notification_meta_fg()),
                    gears.string.xml_escape(latest.body ~= "" and latest.body or latest.title)
                ),
                align = "left",
                widget = wibox.widget.textbox,
            },
            {
                markup = string.format(
                    "<span foreground='%s'>Created:</span> %s",
                    gears.string.xml_escape(instance:notification_meta_fg()),
                    gears.string.xml_escape(group.created_at)
                ),
                align = "left",
                widget = wibox.widget.textbox,
            },
            {
                markup = string.format(
                    "<span foreground='%s'>Last Updated:</span> %s",
                    gears.string.xml_escape(instance:notification_meta_fg()),
                    gears.string.xml_escape(latest_timestamp)
                ),
                align = "left",
                widget = wibox.widget.textbox,
            },
            spacing = 4,
            layout = wibox.layout.fixed.vertical,
        },
        widget = wibox.container.margin,
        top = 9,
        bottom = 9,
        left = 12,
        right = 12,
    })

    local header_inner = wibox.widget({
        header,
        widget = wibox.container.background,
        bg = instance:notification_card_bg(),
    })

    local header_bg = wibox.widget({
        {
            header_inner,
            margins = opts.selected and 2 or 0,
            widget = wibox.container.margin,
        },
        widget = wibox.container.background,
        bg = opts.selected and instance:notification_selected_bg() or instance:popup_bg(),
        shape = gears.shape.rounded_rect,
    })

    util.attach_hover_background(header_inner, instance:notification_card_bg(), instance:notification_hover_bg())

    local function enter_group()
        instance:enter_group_detail(group.key)
    end

    local function select_card()
        if opts.selection_index and instance.popup_selected_index ~= opts.selection_index then
            instance.popup_selected_index = opts.selection_index
            instance:refresh_popup()
        end
    end

    header_bg:connect_signal("mouse::enter", select_card)
    header_inner:connect_signal("mouse::enter", select_card)

    attach_buttons({header_bg, header_inner}, {
        awful.button({}, 1, function()
            select_card()
            enter_group()
        end),
        awful.button({}, 3, function()
            select_card()
            enter_group()
        end),
        table.unpack(opts.extra_buttons or {})
    })

    return {
        widget = header_bg,
        on_space = enter_group,
        on_enter = enter_group,
    }
end

return cards
