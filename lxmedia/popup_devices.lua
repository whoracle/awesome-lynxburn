local wibox = require("wibox")
local beautiful = require("beautiful")
local popup_shell = require("lxcommon.popup_shell")
local popup_ui = require("lxcommon.popup_ui")

local M = {}

local COLORS = {
    hover = beautiful.lxmedia_bg_hover or beautiful.bg_focus or "#535d6c",
    idle = beautiful.lxmedia_button_bg or beautiful.bg_minimize or "#333333",
}

local function make_card(child)
    return popup_ui.make_card(child, {
        margins = 10,
        radius = 8,
    })
end

local function make_row_card(child)
    return popup_ui.make_card(child, {
        margins = 0,
        radius = 8,
    })
end

local function selectable_card(instance, child, selected, index, onclick)
    return popup_ui.make_selectable_click_container(child, onclick, {
        selected = selected,
        inner_bg = beautiful.lxmedia_popup_bg or beautiful.bg_normal or "#222222",
        hover_bg = beautiful.lxmedia_button_hover or beautiful.bg_focus or "#444444",
        outer_bg = beautiful.lxmedia_popup_bg or beautiful.bg_normal or "#222222",
        selected_bg = beautiful.lxmedia_selected_border or beautiful.border_focus or beautiful.bg_focus or "#666666",
        on_hover = function()
            instance:set_devices_popup_selection(index)
        end,
    })
end

local function make_info_line(text, opts)
    opts = opts or {}
    opts.text_opts = opts.text_opts or {
        ellipsize = "end",
        valign = "center",
    }
    return popup_ui.make_info_line(text, opts)
end

local function make_click_row(text, onclick, opts)
    opts = opts or {}
    opts.idle_bg = opts.idle_bg or COLORS.idle
    opts.hover_bg = opts.hover_bg or COLORS.hover
    opts.text_opts = opts.text_opts or {
        ellipsize = "end",
        valign = "center",
    }
    return popup_ui.make_click_row(text, onclick, opts)
end

local function make_selectable_card_row(instance, text, selected, index, onclick, opts)
    return make_row_card(selectable_card(instance, make_info_line(text, opts), selected, index, onclick))
end

local function make_card_info_row(text, opts)
    return make_row_card(make_info_line(text, opts))
end

local function build_header(default_sink_label, default_source_label)
    local layout = wibox.widget {
        spacing = 2,
        layout = wibox.layout.fixed.vertical,
    }

    layout:add(wibox.widget {
        markup = "<b>Audio Devices</b>",
        widget = wibox.widget.textbox,
    })

    layout:add(make_info_line("Output: " .. (default_sink_label or "-"), {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
        forced_height = 18,
    }))

    layout:add(make_info_line("Input: " .. (default_source_label or "-"), {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
        forced_height = 18,
    }))

    return make_card(layout)
end

local function build_outputs_card(instance, sinks, popup_items)
    local audio = require("lxmedia.audio")

    local layout = wibox.widget {
        spacing = 1,
        layout = wibox.layout.fixed.vertical,
    }

    layout:add(make_info_line("Outputs", {
        left = 8,
        right = 8,
        top = 2,
        bottom = 4,
        forced_height = 20,
    }))

    if #sinks == 0 then
        layout:add(make_card_info_row("(none)", {
            left = 12,
            right = 8,
            top = 2,
            bottom = 2,
        }))
    else
        for _, sink in ipairs(sinks) do
            local prefix = sink.is_default and "■ " or "□ "
            local next_index = #popup_items + 1
            local row = make_selectable_card_row(instance, prefix .. (sink.label or sink.name), instance.devices_popup_selected_index == next_index, next_index, function()
                audio.set_default_sink(sink.name)
                instance:refresh()
                M.rebuild(instance)
            end, {
                left = 12,
                right = 8,
                top = 4,
                bottom = 4,
            })
            layout:add(row)
            popup_items[#popup_items + 1] = {
                widget = row,
                on_enter = function()
                    audio.set_default_sink(sink.name)
                    instance:refresh()
                    M.rebuild(instance)
                end,
            }
        end
    end

    local card = make_card(layout)
    card.forced_height = 69
    return card
end

local function build_inputs_card(instance, sources, popup_items)
    local audio = require("lxmedia.audio")

    local layout = wibox.widget {
        spacing = 1,
        layout = wibox.layout.fixed.vertical,
    }

    layout:add(make_info_line("Inputs", {
        left = 8,
        right = 8,
        top = 2,
        bottom = 4,
        forced_height = 20,
    }))

    if #sources == 0 then
        layout:add(make_card_info_row("(none)", {
            left = 12,
            right = 8,
            top = 2,
            bottom = 2,
        }))
    else
        for _, source in ipairs(sources) do
            local prefix = source.is_default and "● " or "○ "
            local next_index = #popup_items + 1
            local row = make_selectable_card_row(instance, prefix .. (source.label or source.name), instance.devices_popup_selected_index == next_index, next_index, function()
                audio.set_default_source(source.name)
                instance:refresh()
                M.rebuild(instance)
            end, {
                left = 12,
                right = 8,
                top = 4,
                bottom = 4,
            })
            layout:add(row)
            popup_items[#popup_items + 1] = {
                widget = row,
                on_enter = function()
                    audio.set_default_source(source.name)
                    instance:refresh()
                    M.rebuild(instance)
                end,
            }
        end
    end

    local card = make_card(layout)
    card.forced_height = 69
    return card
end

local function build_stream_route_rows(instance, stream, sinks, layout, popup_items)
    local audio = require("lxmedia.audio")

    layout:add(make_info_line("Route to:", {
        left = 12,
        right = 8,
        top = 6,
        bottom = 2,
    }))

    for _, sink in ipairs(sinks) do
        local prefix = (sink.id == stream.sink_id) and "■ " or "□ "
        local next_index = #popup_items + 1
        local row = make_selectable_card_row(instance, prefix .. (sink.label or sink.name), instance.devices_popup_selected_index == next_index, next_index, function()
            audio.move_sink_input(stream.id, sink.name)
            instance:refresh()
            M.rebuild(instance)
        end, {
            left = 20,
            right = 8,
            top = 4,
            bottom = 4,
        })
        layout:add(row)
        popup_items[#popup_items + 1] = {
            widget = row,
            on_enter = function()
                audio.move_sink_input(stream.id, sink.name)
                instance:refresh()
                M.rebuild(instance)
            end,
        }
    end
end

local function build_streams_card(instance, streams, sinks, popup_items)
    instance.ui_state = instance.ui_state or {}
    instance.ui_state.devices_stream_expanded = instance.ui_state.devices_stream_expanded or {}

    local layout = wibox.widget {
        spacing = 1,
        layout = wibox.layout.fixed.vertical,
    }

    layout:add(make_info_line("Playback Streams", {
        left = 8,
        right = 8,
        top = 2,
        bottom = 4,
        forced_height = 20,
    }))

    if #streams == 0 then
        layout:add(make_card_info_row("(none)", {
            left = 12,
            right = 8,
            top = 2,
            bottom = 2,
        }))
        return make_card(layout)
    end

    for _, stream in ipairs(streams) do
        local expanded = instance.ui_state.devices_stream_expanded[stream.id] == true
        local sublayout = wibox.widget {
            spacing = 1,
            layout = wibox.layout.fixed.vertical,
        }

        local prefix = expanded and "▼ " or "▶ "
        local muted_prefix = stream.muted and ((beautiful.lxmedia_icon_muted or "M") .. "  ") or ""
        local title = prefix .. muted_prefix .. (stream.label or ("Stream " .. tostring(stream.id)))

        local stream_index = #popup_items + 1
        local stream_row = make_selectable_card_row(instance, title, instance.devices_popup_selected_index == stream_index, stream_index, function()
            instance.ui_state.devices_stream_expanded[stream.id] = not expanded
            M.rebuild(instance)
        end, {
            left = 12,
            right = 8,
            top = 4,
            bottom = 2,
        })
        sublayout:add(stream_row)
        popup_items[#popup_items + 1] = {
            widget = stream_row,
            on_enter = function()
                instance.ui_state.devices_stream_expanded[stream.id] = not expanded
                M.rebuild(instance)
            end,
        }

        if stream.detail then
            sublayout:add(make_card_info_row(stream.detail, {
                left = 24,
                right = 8,
                top = 0,
                bottom = 0,
                forced_height = 16,
            }))
        end

        local output_line = "Output: " .. (stream.sink_label or stream.sink_name or "-")
        if stream.volume then
            output_line = output_line .. "  [" .. tostring(stream.volume) .. "%]"
        end

        sublayout:add(make_card_info_row(output_line, {
            left = 24,
            right = 8,
            top = 0,
            bottom = expanded and 2 or 4,
            forced_height = 16,
        }))

        if expanded then
            build_stream_route_rows(instance, stream, sinks, sublayout, popup_items)
        end

        layout:add(sublayout)
    end

    return make_card(layout)
end

local function build_advanced_card(instance, popup_items)
    local audio = require("lxmedia.audio")

    local layout = wibox.widget {
        spacing = 1,
        layout = wibox.layout.fixed.vertical,
    }

    layout:add(make_info_line("Advanced", {
        left = 8,
        right = 8,
        top = 2,
        bottom = 4,
        forced_height = 20,
    }))

    local next_index = #popup_items + 1
    local pavucontrol_row = make_selectable_card_row(instance, "Open pavucontrol", instance.devices_popup_selected_index == next_index, next_index, function()
        audio.open_pavucontrol()
        if instance._devices_popup then
            instance._devices_popup.visible = false
        end
    end, {
        left = 12,
        right = 8,
        top = 4,
        bottom = 4,
    })
    pavucontrol_row.forced_height = 28
    layout:add(pavucontrol_row)
    popup_items[#popup_items + 1] = {
        widget = pavucontrol_row,
        on_enter = function()
            audio.open_pavucontrol()
            if instance._devices_popup then
                instance._devices_popup.visible = false
            end
        end,
    }

    local card = make_card(layout)
    card.forced_height = 69
    return card
end

local function build_widget(instance)
    local audio = require("lxmedia.audio")
    local popup_items = {}

    local sinks = audio.list_sinks() or {}
    local sources = audio.list_sources() or {}
    local streams = audio.list_sink_inputs() or {}

    local default_sink_label = nil
    local default_source_label = nil

    for _, sink in ipairs(sinks) do
        if sink.is_default then
            default_sink_label = sink.label or sink.name
            break
        end
    end

    for _, source in ipairs(sources) do
        if source.is_default then
            default_source_label = source.label or source.name
            break
        end
    end

    local list = wibox.widget {
        spacing = 8,
        layout = wibox.layout.fixed.vertical,
    }

    list:add(build_header(default_sink_label, default_source_label))
    list:add(build_advanced_card(instance, popup_items))
    list:add(build_outputs_card(instance, sinks, popup_items))
    list:add(build_inputs_card(instance, sources, popup_items))
    list:add(build_streams_card(instance, streams, sinks, popup_items))

    instance._devices_popup_items = popup_items
    instance:_ensure_devices_popup_selection()

    return wibox.widget {
        {
            {
                list,
                left = 12,
                right = 12,
                top = 12,
                bottom = 16,
                widget = wibox.container.margin,
            },
            forced_width = beautiful.lxmedia_popup_width_devices or 420,
            strategy = "max",
            widget = wibox.container.constraint,
        },
        widget = wibox.container.background,
    }
end

function M.rebuild(instance)
    popup_shell.rebuild_popup(instance, "_devices_popup", build_widget)
end

function M.show(instance, geo, opts)
    popup_shell.show_popup(instance, "_devices_popup", "_devices_popup_geo", geo, build_widget, opts)
end

function M.toggle(instance, geo, opts)
    return popup_shell.toggle_popup(instance, "_devices_popup", "_devices_popup_geo", geo, build_widget, opts)
end

return M
