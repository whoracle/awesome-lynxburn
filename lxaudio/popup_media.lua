local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears_surface = require("gears.surface")
local common = require("lxaudio.popup_common")

local M = {}

local COLORS = {
    hover = beautiful.lxaudio_bg_hover or beautiful.bg_focus or "#140c0b",
    button_bg = beautiful.lxaudio_button_bg or beautiful.bg_minimize or "#333333",
    button_hover = beautiful.lxaudio_button_hover or beautiful.bg_urgent or "#140c0b",
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
    return common.make_info_line(text, opts)
end

local function make_click_container(child, onclick, opts)
    opts = opts or {}
    opts.hover_bg = opts.hover_bg or COLORS.hover
    return common.make_click_container(child, onclick, opts)
end

local function make_card(child)
    return common.make_card(child)
end

local function make_volume_bar(value, muted)
    return wibox.widget {
        max_value = 1,
        value = math.max(0, math.min(1, (tonumber(value) or 0) / 100)),
        forced_height = 8,
        paddings = 0,
        border_width = 0,
        background_color = beautiful.lxaudio_bar_bg or beautiful.bg_minimize or "#140c0b",
        color = muted
            and (beautiful.lxaudio_widget_muted_fg or beautiful.fg_minimize or "#888888")
            or (beautiful.lxaudio_bar_fg or beautiful.fg_normal or "#e2ccb0"),
        widget = wibox.widget.progressbar,
    }
end

local function decorate_stream_card(card, selected)
    if not selected then
        return card
    end

    return wibox.widget {
        {
            card,
            margins = 1,
            widget = wibox.container.margin,
        },
        shape = gears.shape.rounded_rect,
        border_width = 1,
        border_color = beautiful.lxaudio_selected_border
            or beautiful.border_focus
            or beautiful.lxaudio_bar_fg
            or beautiful.fg_normal
            or "#e2ccb0",
        widget = wibox.container.background,
    }
end

local function build_transport_row(instance, player, player_info)
    local media = require("lxaudio.media")

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

local function build_stream_card(instance, stream, default_sink_name, selected)
    local media = require("lxaudio.media")

    local matched_player = stream._matched_player or media.player_for_stream(stream)
    local player_info = matched_player and media.get_player_info(matched_player) or nil

    local layout = wibox.widget {
        spacing = 1,
        layout = wibox.layout.fixed.vertical,
    }

    local mute_prefix = stream.muted and ((beautiful.lxaudio_icon_muted or "M") .. "  ") or ""

    local function scroll_up()
        local audio = require("lxaudio.audio")
        audio.change_sink_input_volume(stream.id, instance.opts.step or 0.05)
        if instance._defer_media_popup_refresh then
            instance:_defer_media_popup_refresh()
        end
    end

    local function scroll_down()
        local audio = require("lxaudio.audio")
        audio.change_sink_input_volume(stream.id, -(instance.opts.step or 0.05))
        if instance._defer_media_popup_refresh then
            instance:_defer_media_popup_refresh()
        end
    end

    local function middle_click()
        local audio = require("lxaudio.audio")
        audio.toggle_sink_input_mute(stream.id)
        if instance._defer_media_popup_refresh then
            instance:_defer_media_popup_refresh()
        end
    end

    local info_layout = wibox.widget {
        spacing = 1,
        layout = wibox.layout.fixed.vertical,
    }

    local stream_row = make_info_line(mute_prefix .. (stream.label or ("Stream " .. tostring(stream.id))), {
        left = 0,
        right = 0,
        top = 1,
        bottom = 1,
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
                    local art_width = beautiful.lxaudio_artwork_width or 420
                    local art_max_height = beautiful.lxaudio_artwork_max_height or art_width * 2

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
            info_layout:add(meta_row)
        end

        if player_info.status then
            local status_row = make_info_line("[" .. player_info.status .. "]", {
                left = 20,
                right = 0,
                top = 0,
                bottom = 0,
            })
            status_row.forced_height = 15
            info_layout:add(status_row)
        end
    end

    if stream.volume then
        local volume_line = wibox.widget {
            {
                make_info_line("Volume: " .. tostring(stream.volume) .. "%", {
                    left = 0,
                    right = 8,
                    top = 0,
                    bottom = 0,
                }),
                forced_width = 90,
                strategy = "max",
                widget = wibox.container.constraint,
            },
            {
                make_volume_bar(stream.volume, stream.muted),
                valign = "center",
                widget = wibox.container.place,
            },
            spacing = 8,
            layout = wibox.layout.flex.horizontal,
        }

        info_layout:add(wibox.widget {
            volume_line,
            left = 20,
            right = 0,
            top = 0,
            bottom = 0,
            widget = wibox.container.margin,
        })
    end

    if stream.sink_name and default_sink_name and stream.sink_name ~= default_sink_name then
        local output_row = make_info_line("Output: " .. (stream.sink_label or stream.sink_name), {
            left = 20,
            right = 0,
            top = 0,
            bottom = 0,
        })
        output_row.forced_height = 15
        info_layout:add(output_row)
    end

    local main_clickable_layout = wibox.widget {
        spacing = 2,
        layout = wibox.layout.fixed.vertical,
    }

    if art_widget then
        main_clickable_layout:add(art_widget)
    end

    main_clickable_layout:add(info_layout)

    layout:add(make_click_container(main_clickable_layout, nil, {
        left = 1,
        right = 1,
        top = 4,
        bottom = 4,
        on_middle_click = middle_click,
        on_scroll_up = scroll_up,
        on_scroll_down = scroll_down,
    }))

    if player_info and matched_player then
        layout:add(build_transport_row(instance, matched_player, player_info))
    end

    return decorate_stream_card(make_card(layout), selected)
end

local function build_widget(instance)
    local audio = require("lxaudio.audio")
    local media = require("lxaudio.media")

    local streams = audio.list_sink_inputs() or {}
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
                list:add(build_stream_card(
                    instance,
                    stream,
                    default_sink_name,
                    #popup_items == instance.media_popup_selected_index
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
                list:add(build_stream_card(
                    instance,
                    stream,
                    default_sink_name,
                    #popup_items == instance.media_popup_selected_index
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
            forced_width = beautiful.lxaudio_popup_width_media or 420,
            strategy = "max",
            widget = wibox.container.constraint,
        },
        widget = wibox.container.background,
    }
end

function M.rebuild(instance)
    common.rebuild_popup(instance, "_media_popup", build_widget)
end

function M.show(instance, geo, opts)
    common.show_popup(instance, "_media_popup", "_media_popup_geo", geo, build_widget, opts)
end

function M.toggle(instance, geo, opts)
    return common.toggle_popup(instance, "_media_popup", "_media_popup_geo", geo, build_widget, opts)
end

return M
