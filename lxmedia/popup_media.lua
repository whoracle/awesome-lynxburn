local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears_surface = require("gears.surface")
local popup_shell = require("lxcommon.popup_shell")
local popup_ui = require("lxcommon.popup_ui")

local M = {}

local COLORS = {
    hover = beautiful.lxmedia_bg_hover or beautiful.bg_focus or "#140c0b",
    button_bg = beautiful.lxmedia_button_bg or beautiful.bg_minimize or "#333333",
    button_hover = beautiful.lxmedia_button_hover or beautiful.bg_urgent or "#140c0b",
}

local function make_button(label, onclick)
    local tb = wibox.widget {
        text = label,
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
    }

    local inner = wibox.widget {
        tb,
        left = 6,
        right = 6,
        top = 3,
        bottom = 3,
        widget = wibox.container.margin,
    }

    local bg = wibox.widget {
        inner,
        forced_width = 32,
        forced_height = 24,
        bg = COLORS.button_bg,
        widget = wibox.container.background,
    }

    bg:connect_signal("mouse::enter", function()
        bg.bg = COLORS.button_hover
    end)

    bg:connect_signal("mouse::leave", function()
        bg.bg = COLORS.button_bg
    end)

    bg:buttons(gears.table.join(
        awful.button({}, 1, function()
            if onclick then
                onclick()
            end
        end)
    ))

    return bg
end

local function make_info_line(text, opts)
    return popup_ui.make_info_line(text, opts)
end

local function make_click_container(child, onclick, opts)
    opts = opts or {}
    opts.hover_bg = opts.hover_bg or COLORS.hover
    return popup_ui.make_click_container(child, onclick, opts)
end

local function make_card(child)
    return popup_ui.make_card(child)
end

local function make_volume_bar(value, muted)
    return wibox.widget {
        max_value = 1,
        value = math.max(0, math.min(1, (tonumber(value) or 0) / 100)),
        forced_height = 8,
        paddings = 0,
        border_width = 0,
        background_color = beautiful.lxmedia_bar_bg or beautiful.bg_minimize or "#140c0b",
        color = muted
            and (beautiful.lxmedia_widget_muted_fg or beautiful.fg_minimize or "#888888")
            or (beautiful.lxmedia_bar_fg or beautiful.fg_normal or "#e2ccb0"),
        widget = wibox.widget.progressbar,
    }
end

local function set_sink_input_percent(audio, stream_id, percent)
    if audio.set_sink_input_volume then
        audio.set_sink_input_volume(stream_id, percent)
        return true
    end

    if audio.set_sink_input_value then
        audio.set_sink_input_value(stream_id, percent)
        return true
    end

    awful.spawn("pactl set-sink-input-volume " .. tostring(stream_id) .. " " .. tostring(percent) .. "%", false)
    if tonumber(percent) and tonumber(percent) > 0 then
        awful.spawn("pactl set-sink-input-mute " .. tostring(stream_id) .. " 0", false)
    end
    return true
end

local function set_source_output_percent(audio, source_output_id, percent)
    if audio.set_source_output_volume then
        audio.set_source_output_volume(source_output_id, percent)
        return true
    end

    if audio.set_source_output_value then
        audio.set_source_output_value(source_output_id, percent)
        return true
    end

    awful.spawn("pactl set-source-output-volume " .. tostring(source_output_id) .. " " .. tostring(percent) .. "%", false)
    if tonumber(percent) and tonumber(percent) > 0 then
        awful.spawn("pactl set-source-output-mute " .. tostring(source_output_id) .. " 0", false)
    end
    return true
end

local function make_meter_row(label, control, value_text)
    return wibox.widget {
        {
            {
                make_info_line(label, {
                    left = 0,
                    right = 0,
                    top = 0,
                    bottom = 0,
                }),
                right = 10,
                widget = wibox.container.margin,
            },
            forced_width = 60,
            strategy = "exact",
            widget = wibox.container.constraint,
        },
        {
            control,
            widget = wibox.container.background,
        },
        {
            {
                wibox.widget {
                    text = value_text,
                    align = "right",
                    valign = "center",
                    widget = wibox.widget.textbox,
                },
                left = 10,
                widget = wibox.container.margin,
            },
            forced_width = 48,
            strategy = "exact",
            widget = wibox.container.constraint,
        },
        spacing = 0,
        expand = "inside",
        layout = wibox.layout.align.horizontal,
    }
end

local function make_stream_volume_control(instance, stream)
    local audio = require("lxmedia.audio")

    local bar = make_volume_bar(stream.volume, stream.muted)

    local bar_container = wibox.widget {
        bar,
        valign = "center",
        widget = wibox.container.place,
    }

    bar_container:connect_signal("button::press", function(_, lx, _, button, _, hit)
        if button ~= 1 then
            return
        end

        local width = hit and hit.width or nil
        if not width or width <= 0 then
            return
        end

        local relative_x = math.max(0, math.min(width, lx))
        local target = math.floor(((relative_x / width) * 100) + 0.5)
        set_sink_input_percent(audio, stream.id, target)

        if instance._defer_media_popup_refresh then
            instance:_defer_media_popup_refresh()
        end
    end)

    return bar_container
end

local function make_source_output_volume_control(instance, source_output)
    local audio = require("lxmedia.audio")

    local bar = wibox.widget {
        max_value = 1,
        value = math.max(0, math.min(1, (tonumber(source_output.volume) or 0) / 100)),
        forced_height = 8,
        paddings = 0,
        border_width = 0,
        background_color = beautiful.lxmedia_mic_bar_bg or beautiful.lxmedia_bar_bg or beautiful.bg_minimize or "#140c0b",
        color = source_output.muted
            and (beautiful.lxmedia_widget_mic_muted_fg or beautiful.fg_minimize or "#888888")
            or (beautiful.lxmedia_mic_bar_fg or beautiful.lxmedia_bar_fg or beautiful.fg_normal or "#e2ccb0"),
        widget = wibox.widget.progressbar,
    }

    local bar_container = wibox.widget {
        bar,
        valign = "center",
        widget = wibox.container.place,
    }

    bar_container:connect_signal("button::press", function(_, lx, _, button, _, hit)
        if button == 1 then
            local width = hit and hit.width or nil
            if not width or width <= 0 then
                return
            end

            local relative_x = math.max(0, math.min(width, lx))
            local target = math.floor(((relative_x / width) * 100) + 0.5)
            set_source_output_percent(audio, source_output.id, target)
        elseif button == 2 then
            audio.toggle_source_output_mute(source_output.id)
        elseif button == 4 then
            local current = tonumber(source_output.volume) or 0
            set_source_output_percent(audio, source_output.id, current + ((instance.opts.step or 0.05) * 100))
        elseif button == 5 then
            local current = tonumber(source_output.volume) or 0
            set_source_output_percent(audio, source_output.id, current - ((instance.opts.step or 0.05) * 100))
        else
            return
        end

        if instance._defer_media_popup_refresh then
            instance:_defer_media_popup_refresh()
        end
    end)

    return bar_container
end

local function normalize_match_value(value)
    value = tostring(value or ""):lower()
    value = value:gsub("%..*$", "")
    value = value:gsub("[^%w]", "")
    return value
end

local function find_matching_source_output(stream, source_outputs)
    if not stream or not source_outputs then
        return nil
    end

    for _, source_output in ipairs(source_outputs) do
        if stream.client_id and source_output.client_id and stream.client_id == source_output.client_id then
            return source_output
        end
    end

    local stream_keys = {
        normalize_match_value(stream.app_name),
        normalize_match_value(stream.media_name),
        normalize_match_value(stream.binary),
    }

    for _, source_output in ipairs(source_outputs) do
        local source_keys = {
            normalize_match_value(source_output.app_name),
            normalize_match_value(source_output.media_name),
            normalize_match_value(source_output.binary),
        }

        for _, stream_key in ipairs(stream_keys) do
            if stream_key ~= "" then
                for _, source_key in ipairs(source_keys) do
                    if source_key ~= "" and stream_key == source_key then
                        return source_output
                    end
                end
            end
        end
    end

    return nil
end

local function decorate_stream_card(card, selected)
    local wrapper = wibox.widget {
        {
            card,
            margins = selected and 1 or 0,
            widget = wibox.container.margin,
        },
        shape = gears.shape.rounded_rect,
        border_width = 1,
        border_color = beautiful.lxmedia_selected_border
            or beautiful.border_focus
            or beautiful.lxmedia_bar_fg
            or beautiful.fg_normal
            or "#e2ccb0",
        visible = selected,
        widget = wibox.container.background,
    }

    function wrapper:_lx_set_selected(value)
        wrapper.visible = value and true or false
        if wrapper.children and wrapper.children[1] then
            wrapper.children[1].margins = value and 1 or 0
        end
    end

    if selected then
        return wrapper
    end

    card._lx_set_selected = function(_, value)
        if value then
            wrapper.visible = true
        end
    end

    return wibox.widget {
        card,
        wrapper,
        layout = wibox.layout.stack,
    }
end

local function build_transport_row(instance, player, player_info)
    local media = require("lxmedia.media")

    local playpause_label = "⏯"
    if player_info and player_info.status == "Playing" then
        playpause_label = "⏸"
    elseif player_info and player_info.status == "Paused" then
        playpause_label = "▶"
    end

    local row = wibox.widget {
        spacing = 6,
        layout = wibox.layout.fixed.horizontal,
    }

    row:add(make_button("⏮", function()
        media.previous(player)
        M.rebuild(instance)
    end))

    row:add(make_button(playpause_label, function()
        media.play_pause(player)
        M.rebuild(instance)
    end))

    row:add(make_button("⏭", function()
        media.next(player)
        M.rebuild(instance)
    end))

    local centered = wibox.widget {
        row,
        halign = "center",
        valign = "center",
        widget = wibox.container.place,
    }

    local container = wibox.widget {
        centered,
        left = 12,
        right = 8,
        top = 4,
        bottom = 4,
        widget = wibox.container.margin,
    }

    container.forced_height = 32
    return container
end

local function build_stream_card(instance, stream, source_output, default_sink_name, selected, selection_index)
    local media = require("lxmedia.media")

    local matched_player = stream._matched_player or media.player_for_stream(stream)
    local player_info = matched_player and media.get_player_info(matched_player) or nil

    local layout = wibox.widget {
        spacing = 1,
        layout = wibox.layout.fixed.vertical,
    }

    local mute_prefix = stream.muted and ((beautiful.lxmedia_icon_muted or "M") .. "  ") or ""
    local function primary_click()
        local audio = require("lxmedia.audio")
        audio.toggle_sink_input_mute(stream.id)
        if instance._defer_media_popup_refresh then
            instance:_defer_media_popup_refresh()
        end
    end

    local function secondary_click()
        if not matched_player then
            return
        end

        media.play_pause(matched_player)
        if instance._defer_media_popup_refresh then
            instance:_defer_media_popup_refresh()
        else
            M.rebuild(instance)
        end
    end

    local function scroll_up()
        local audio = require("lxmedia.audio")
        audio.change_sink_input_volume(stream.id, instance.opts.step or 0.05)
        if instance._defer_media_popup_refresh then
            instance:_defer_media_popup_refresh()
        end
    end

    local function scroll_down()
        local audio = require("lxmedia.audio")
        audio.change_sink_input_volume(stream.id, -(instance.opts.step or 0.05))
        if instance._defer_media_popup_refresh then
            instance:_defer_media_popup_refresh()
        end
    end

    local function middle_click()
        local audio = require("lxmedia.audio")
        audio.toggle_sink_input_mute(stream.id)
        if instance._defer_media_popup_refresh then
            instance:_defer_media_popup_refresh()
        end
    end

    local function wrap_output_scrollable(child, opts)
        opts = opts or {}
        return make_click_container(child, opts.onclick, {
            left = opts.left or 0,
            right = opts.right or 0,
            top = opts.top or 0,
            bottom = opts.bottom or 0,
            on_right_click = opts.on_right_click,
            on_middle_click = opts.on_middle_click,
            on_scroll_up = scroll_up,
            on_scroll_down = scroll_down,
        })
    end

    local info_layout = wibox.widget {
        spacing = 1,
        layout = wibox.layout.fixed.vertical,
    }

    local stream_row = wrap_output_scrollable(make_info_line(mute_prefix .. (stream.label or ("Stream " .. tostring(stream.id))), {
        left = 0,
        right = 0,
        top = 1,
        bottom = 1,
    }), {
        onclick = primary_click,
        on_right_click = secondary_click,
        on_middle_click = middle_click,
    })
    stream_row.forced_height = 20
    info_layout:add(stream_row)

    local art_widget = nil

    if player_info then
        local meta = nil

        if player_info.artist and player_info.title then
            meta = player_info.artist .. " — " .. player_info.title
        elseif player_info.title and player_info.title ~= "" then
            meta = player_info.title
        end

        if matched_player then
            local art_url = media.get_player_art_url(matched_player)
            local art_path = art_url and art_url:match("^file://(.+)$") or nil

            if art_path then
                local surface = media.get_player_art_surface(matched_player)
                if surface then
                    local art_width = beautiful.lxmedia_artwork_width or 420
                    local art_max_height = beautiful.lxmedia_artwork_max_height or art_width * 2

                    local sw, sh = gears_surface.get_size(surface)
                    local target_w = art_width
                    local target_h = art_width

                    if sw and sh and sw > 0 and sh > 0 then
                        target_h = math.floor((art_width * sh / sw) + 0.5)
                    end

                    if target_h > art_max_height then
                        target_h = art_max_height
                    end

                    art_widget = wibox.widget {
                        image = surface,
                        resize = true,
                        upscale = true,
                        downscale = true,
                        forced_width = target_w,
                        forced_height = target_h,
                        widget = wibox.widget.imagebox,
                    }
                end
            end
        end

        if meta then
            local meta_row = make_info_line(meta, {
                left = 20,
                right = 0,
                top = 0,
                bottom = 0,
            })
            meta_row.forced_height = 15
            info_layout:add(wrap_output_scrollable(meta_row, {
                onclick = primary_click,
                on_right_click = secondary_click,
                on_middle_click = middle_click,
            }))
        end

        if player_info.status then
            local status_row = make_info_line("[" .. player_info.status .. "]", {
                left = 20,
                right = 0,
                top = 0,
                bottom = 0,
            })
            status_row.forced_height = 15
            info_layout:add(wrap_output_scrollable(status_row, {
                onclick = primary_click,
                on_right_click = secondary_click,
                on_middle_click = middle_click,
            }))
        end
    end

    if stream.volume then
        local volume_line = make_meter_row(
            "Volume",
            make_stream_volume_control(instance, stream),
            tostring(stream.volume) .. "%"
        )

        info_layout:add(wrap_output_scrollable(wibox.widget {
            volume_line,
            left = 20,
            right = 0,
            top = 0,
            bottom = 0,
            widget = wibox.container.margin,
        }, {
            onclick = primary_click,
            on_right_click = secondary_click,
            on_middle_click = middle_click,
        }))

        if source_output and source_output.volume then
            local mic_line = make_meter_row(
                "Mic",
                make_source_output_volume_control(instance, source_output),
                source_output.muted and "muted" or (tostring(source_output.volume) .. "%")
            )

            info_layout:add(wibox.widget {
                mic_line,
                left = 20,
                right = 0,
                top = 0,
                bottom = 0,
                widget = wibox.container.margin,
            })
        end
    end

    if stream.sink_name and default_sink_name and stream.sink_name ~= default_sink_name then
        local output_row = make_info_line("Output: " .. (stream.sink_label or stream.sink_name), {
            left = 20,
            right = 0,
            top = 0,
            bottom = 0,
        })
        output_row.forced_height = 15
        info_layout:add(wrap_output_scrollable(output_row, {
            onclick = primary_click,
            on_right_click = secondary_click,
            on_middle_click = middle_click,
        }))
    end

    if art_widget then
        layout:add(wrap_output_scrollable(art_widget, {
            left = 1,
            right = 1,
            top = 4,
            bottom = 2,
            onclick = primary_click,
            on_right_click = secondary_click,
            on_middle_click = middle_click,
        }))
    end

    layout:add(wibox.widget {
        info_layout,
        left = 1,
        right = 1,
        top = art_widget and 0 or 4,
        bottom = 4,
        widget = wibox.container.margin,
    })

    if player_info and matched_player then
        layout:add(wrap_output_scrollable(build_transport_row(instance, matched_player, player_info), {
            left = 0,
            right = 0,
            top = 0,
            bottom = 0,
        }))
    end

    local card = decorate_stream_card(make_card(layout), selected)
    if selection_index then
        card:connect_signal("mouse::enter", function()
            if instance.media_popup_selected_index ~= selection_index then
                instance.media_popup_selected_index = selection_index
                M.rebuild(instance)
            end
        end)
    end

    return card
end

local function build_widget(instance)
    local audio = require("lxmedia.audio")
    local media = require("lxmedia.media")

    local streams = audio.list_sink_inputs() or {}
    local source_outputs = audio.list_source_outputs() or {}
    local sinks = audio.list_sinks() or {}
    local streams_with_player = {}
    local streams_without_player = {}
    local popup_items = {}

    for _, stream in ipairs(streams) do
        local matched_player = media.player_for_stream(stream)
        if matched_player then
            stream._matched_player = matched_player
            table.insert(streams_with_player, stream)
        else
            table.insert(streams_without_player, stream)
        end
    end

    local default_sink_name = nil
    for _, sink in ipairs(sinks) do
        if sink.is_default then
            default_sink_name = sink.name
            break
        end
    end

    local total_streams = #streams_with_player + #streams_without_player
    if total_streams < 1 then
        total_streams = 1
    end

    instance.media_popup_selected_index = math.max(1, math.min(instance.media_popup_selected_index or 1, total_streams))

    local list = wibox.widget {
        spacing = 28,
        layout = wibox.layout.fixed.vertical,
    }

    if #streams == 0 then
        instance._media_popup_items = {}

        list:add(make_card(
            wibox.widget {
                make_info_line("No active playback streams", {
                    left = 8,
                    right = 8,
                    top = 6,
                    bottom = 6,
                }),
                layout = wibox.layout.fixed.vertical,
            }
        ))
    else
        if #streams_with_player > 0 then
            list:add(make_info_line("Media Players", {
                left = 0,
                right = 0,
                top = 2,
                bottom = 4,
                forced_height = 20,
            }))

            for _, stream in ipairs(streams_with_player) do
                popup_items[#popup_items + 1] = stream
                local source_output = find_matching_source_output(stream, source_outputs)
                list:add(build_stream_card(
                    instance,
                    stream,
                    source_output,
                    default_sink_name,
                    #popup_items == instance.media_popup_selected_index,
                    #popup_items
                ))
            end
        end

        if #streams_without_player > 0 then
            list:add(make_info_line("Other Streams", {
                left = 0,
                right = 0,
                top = 6,
                bottom = 4,
                forced_height = 20,
            }))

            for _, stream in ipairs(streams_without_player) do
                popup_items[#popup_items + 1] = stream
                local source_output = find_matching_source_output(stream, source_outputs)
                list:add(build_stream_card(
                    instance,
                    stream,
                    source_output,
                    default_sink_name,
                    #popup_items == instance.media_popup_selected_index,
                    #popup_items
                ))
            end
        end

        instance._media_popup_items = popup_items
    end

    return wibox.widget {
        {
            {
                list,
                margins = 10,
                widget = wibox.container.margin,
            },
            forced_width = beautiful.lxmedia_popup_width_media or 420,
            strategy = "max",
            widget = wibox.container.constraint,
        },
        widget = wibox.container.background,
    }
end

M.build = build_widget

function M.rebuild(instance)
    popup_shell.rebuild_popup(instance, "_media_popup", build_widget)
end

function M.show(instance, geo, opts)
    popup_shell.show_popup(instance, "_media_popup", "_media_popup_geo", geo, build_widget, opts)
end

function M.toggle(instance, geo, opts)
    return popup_shell.toggle_popup(instance, "_media_popup", "_media_popup_geo", geo, build_widget, opts)
end

return M
