local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")

local util = require("lxcommon.util")

local popup = {}

local HEADER_LABELS = {
    back = "Back",
    dismiss_group = "Dismiss",
    pause_daemon = "Silence Popups",
    resume_daemon = "Resume Popups",
    pause_interception = "Pause Capture",
    resume_interception = "Resume Capture",
}

local function build_header_button(label)
    local text = wibox.widget({
        text = label,
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
    })

    local button = wibox.widget({
        {
            text,
            widget = wibox.container.margin,
            left = 10,
            right = 10,
            top = 6,
            bottom = 6,
        },
        widget = wibox.container.background,
    })

    return button, text
end

function popup.refresh_header(instance)
    if not instance._popup_refs then
        return
    end

    local refs = instance._popup_refs
    refs.back_label.text = HEADER_LABELS.back
    refs.back_button.visible = instance.active_group_key ~= nil
    refs.dismiss_group_label.text = HEADER_LABELS.dismiss_group
    refs.dismiss_group_button.visible = instance.active_group_key ~= nil
    refs.title_label.text = instance.popup_title or "Notifications"
    refs.daemon_label.text = instance.suspended and HEADER_LABELS.resume_daemon or HEADER_LABELS.pause_daemon
    refs.interception_label.text = instance.interception_paused and HEADER_LABELS.resume_interception or HEADER_LABELS.pause_interception
    refs.daemon_button.bg = instance:button_bg()
    refs.interception_button.bg = instance:button_bg()
    refs.back_button.bg = instance:button_bg()
    refs.dismiss_group_button.bg = instance:button_bg()
    refs.body_bg.bg = instance:popup_bg()
    refs.footer_label.markup = string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(instance:notification_meta_fg()),
        gears.string.xml_escape(instance.popup_footer_text or "")
    )
    refs.footer_label.visible = instance.popup_footer_text ~= nil and instance.popup_footer_text ~= ""
end

function popup.build(instance)
    local back_button, back_label = build_header_button(HEADER_LABELS.back)
    local dismiss_group_button, dismiss_group_label = build_header_button(HEADER_LABELS.dismiss_group)
    local daemon_button, daemon_label = build_header_button(HEADER_LABELS.pause_daemon)
    local interception_button, interception_label = build_header_button(HEADER_LABELS.pause_interception)
    local title_label = wibox.widget({
        text = "Notifications",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
    })
    local footer_label = wibox.widget({
        visible = false,
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
    })

    back_button.bg = instance:button_bg()
    dismiss_group_button.bg = instance:button_bg()
    daemon_button.bg = instance:button_bg()
    interception_button.bg = instance:button_bg()
    util.attach_hover_background(back_button, instance:button_bg(), instance:button_hover_bg())
    util.attach_hover_background(dismiss_group_button, instance:button_bg(), instance:button_hover_bg())
    util.attach_hover_background(daemon_button, instance:button_bg(), instance:button_hover_bg())
    util.attach_hover_background(interception_button, instance:button_bg(), instance:button_hover_bg())

    back_button:buttons(gears.table.join(
        awful.button({}, 1, function()
            instance:leave_group_detail()
        end)
    ))

    dismiss_group_button:buttons(gears.table.join(
        awful.button({}, 1, function()
            instance:dismiss_active_group()
        end)
    ))

    daemon_button:buttons(gears.table.join(
        awful.button({}, 1, function()
            instance:toggle_daemon_pause()
        end)
    ))

    interception_button:buttons(gears.table.join(
        awful.button({}, 1, function()
            instance:toggle_interception_pause()
        end)
    ))

    local notification_list = wibox.widget({
        spacing = 8,
        layout = wibox.layout.fixed.vertical,
    })

    local scroll_area = wibox.widget({
        notification_list,
        layout = wibox.layout.fixed.vertical,
    })

    local body_bg = wibox.widget({
        {
            {
                {
                    {
                        {
                            daemon_button,
                            interception_button,
                            spacing = 8,
                            layout = wibox.layout.fixed.horizontal,
                        },
                        widget = wibox.container.place,
                        halign = "center",
                    },
                    {
                        back_button,
                        {
                            title_label,
                            widget = wibox.container.place,
                            halign = "center",
                            valign = "center",
                        },
                        dismiss_group_button,
                        layout = wibox.layout.align.horizontal,
                    },
                    scroll_area,
                    footer_label,
                    spacing = 12,
                    layout = wibox.layout.fixed.vertical,
                },
                widget = wibox.container.margin,
                top = 12,
                bottom = 12,
                left = 12,
                right = 12,
            },
            widget = wibox.container.background,
            bg = instance:popup_bg(),
        },
        widget = wibox.container.background,
        bg = instance:popup_bg(),
    })

    instance._popup_refs = {
        back_button = back_button,
        back_label = back_label,
        dismiss_group_button = dismiss_group_button,
        dismiss_group_label = dismiss_group_label,
        title_label = title_label,
        daemon_button = daemon_button,
        daemon_label = daemon_label,
        interception_button = interception_button,
        interception_label = interception_label,
        list = notification_list,
        footer_label = footer_label,
        body_bg = body_bg,
    }

    popup.refresh_header(instance)
    instance:refresh_popup()

    return body_bg
end

return popup
