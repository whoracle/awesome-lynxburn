local wibox = require("wibox")
local beautiful = require("beautiful")
local common = require("lxcommon.popup_shell")

local M = {}

local COLORS = {
    hover = beautiful.lxmedia_bg_hover or beautiful.bg_focus or "#535d6c",
}

local function make_card(child)
    return common.make_card(child, {
        margins = 10,
        radius = 8,
    })
end

local function make_info_line(text, opts)
    opts = opts or {}
    opts.text_opts = opts.text_opts or {
        ellipsize = "end",
        valign = "center",
    }
    return common.make_info_line(text, opts)
end

local function make_click_row(text, onclick, opts)
    opts = opts or {}
    opts.hover_bg = opts.hover_bg or COLORS.hover
    opts.text_opts = opts.text_opts or {
        ellipsize = "end",
        valign = "center",
    }
    return common.make_click_row(text, onclick, opts)
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

    return layout
end

local function build_outputs_card(instance, sinks)
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
        layout:add(make_info_line("(none)", {
            left = 12,
            right = 8,
            top = 2,
            bottom = 2,
        }))
    else
        for _, sink in ipairs(sinks) do
            local prefix = sink.is_default and "■ " or "□ "
            layout:add(make_click_row(prefix .. (sink.label or sink.name), function()
                audio.set_default_sink(sink.name)
                instance:refresh()
                M.rebuild(instance)
            end, {
                left = 12,
                right = 8,
                top = 4,
                bottom = 4,
            }))
        end
    end

    local card = make_card(layout)
    card.forced_height = 69
    return card
end

local function build_inputs_card(instance, sources)
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
        layout:add(make_info_line("(none)", {
            left = 12,
            right = 8,
            top = 2,
            bottom = 2,
        }))
    else
        for _, source in ipairs(sources) do
            local prefix = source.is_default and "● " or "○ "
            layout:add(make_click_row(prefix .. (source.label or source.name), function()
                audio.set_default_source(source.name)
                instance:refresh()
                M.rebuild(instance)
            end, {
                left = 12,
                right = 8,
                top = 4,
                bottom = 4,
            }))
        end
    end

    local card = make_card(layout)
    card.forced_height = 69
    return card
end

local function build_stream_route_rows(instance, stream, sinks, layout)
    local audio = require("lxmedia.audio")

    layout:add(make_info_line("Route to:", {
        left = 12,
        right = 8,
        top = 6,
        bottom = 2,
    }))

    for _, sink in ipairs(sinks) do
        local prefix = (sink.id == stream.sink_id) and "■ " or "□ "
        layout:add(make_click_row(prefix .. (sink.label or sink.name), function()
            audio.move_sink_input(stream.id, sink.name)
            instance:refresh()
            M.rebuild(instance)
        end, {
            left = 20,
            right = 8,
            top = 4,
            bottom = 4,
        }))
    end
end

local function build_streams_card(instance, streams, sinks)
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
        layout:add(make_info_line("(none)", {
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

        sublayout:add(make_click_row(title, function()
            instance.ui_state.devices_stream_expanded[stream.id] = not expanded
            M.rebuild(instance)
        end, {
            left = 12,
            right = 8,
            top = 4,
            bottom = 2,
        }))

        if stream.detail then
            sublayout:add(make_info_line(stream.detail, {
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

        sublayout:add(make_info_line(output_line, {
            left = 24,
            right = 8,
            top = 0,
            bottom = expanded and 2 or 4,
            forced_height = 16,
        }))

        if expanded then
            build_stream_route_rows(instance, stream, sinks, sublayout)
        end

        layout:add(sublayout)
    end

    return make_card(layout)
end

local function build_advanced_card(instance)
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

    local pavucontrol_row = make_click_row("Open pavucontrol", function()
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

    local card = make_card(layout)
    card.forced_height = 69
    return card
end

local function build_widget(instance)
    local audio = require("lxmedia.audio")

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
    list:add(build_advanced_card(instance))
    list:add(build_outputs_card(instance, sinks))
    list:add(build_inputs_card(instance, sources))
    list:add(build_streams_card(instance, streams, sinks))

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
    common.rebuild_popup(instance, "_devices_popup", build_widget)
end

function M.show(instance, geo, opts)
    common.show_popup(instance, "_devices_popup", "_devices_popup_geo", geo, build_widget, opts)
end

function M.toggle(instance, geo, opts)
    return common.toggle_popup(instance, "_devices_popup", "_devices_popup_geo", geo, build_widget, opts)
end

return M
