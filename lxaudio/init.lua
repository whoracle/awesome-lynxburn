local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local keygrabber = require("awful.keygrabber")

local M = {}
M.__index = M

local DEFAULTS = {
    show_mic_activity = true,
    refresh_interval = 5,
    width = 50,
    step = 0.05, -- 5%
    icon_muted = beautiful.lxaudio_icon_muted or " ",
    icon_unmuted = beautiful.lxaudio_icon_volume or " ",
    icon_mic_active = beautiful.lxaudio_icon_mic_active or "🎙",
    icon_mic_muted = beautiful.lxaudio_icon_mic_muted or "×",
    enable_osd = true,
    osd_width = 260,
    osd_height = 18,
    osd_margin = 16,
    osd_timeout = 1,
}

local function merge_defaults(opts)
    opts = opts or {}
    local merged = {}
    for k, v in pairs(DEFAULTS) do
        merged[k] = v
    end
    for k, v in pairs(opts) do
        merged[k] = v
    end
    return merged
end

local function is_geometry(value)
    return type(value) == "table" and value.x and value.y and value.width and value.height
end

local function normalize_popup_args(anchor_geo, opts)
    if type(anchor_geo) == "table" and not is_geometry(anchor_geo) and opts == nil then
        return nil, anchor_geo
    end

    return anchor_geo, opts or {}
end

local function normalize_popup_toggle_key(toggle_key)
    if type(toggle_key) ~= "table" or type(toggle_key.key) ~= "string" then
        return nil
    end

    local normalized = {
        key = toggle_key.key,
        modifiers = {},
        modifier_set = {},
    }

    if type(toggle_key.modifiers) == "table" then
        for _, modifier in ipairs(toggle_key.modifiers) do
            if type(modifier) == "string" and modifier ~= "" then
                normalized.modifier_set[modifier] = true
            end
        end
    end

    for modifier in pairs(normalized.modifier_set) do
        normalized.modifiers[#normalized.modifiers + 1] = modifier
    end

    table.sort(normalized.modifiers)

    return normalized
end

local function popup_toggle_key_matches(toggle_key, modifiers, key)
    if not toggle_key or key ~= toggle_key.key then
        return false
    end

    local active_modifiers = {}
    for _, modifier in ipairs(modifiers or {}) do
        active_modifiers[modifier] = true
    end

    for modifier in pairs(active_modifiers) do
        if not toggle_key.modifier_set[modifier] then
            return false
        end
    end

    for modifier in pairs(toggle_key.modifier_set) do
        if not active_modifiers[modifier] then
            return false
        end
    end

    return true
end

local function point_in_geometry(x, y, geo)
    return geo
        and x >= geo.x and x < (geo.x + geo.width)
        and y >= geo.y and y < (geo.y + geo.height)
end

-- Clear cached submodules so reloads pick up on-disk changes without
-- replacing the stable outer widget container.
function M:_clear_modules()
    package.loaded["lxaudio.widget"] = nil
    package.loaded["lxaudio.audio"] = nil
    package.loaded["lxaudio.osd"] = nil
    package.loaded["lxaudio.media"] = nil
    package.loaded["lxaudio.popup_media"] = nil
    package.loaded["lxaudio.popup_devices"] = nil
end

function M:_load_osd()
    if not self.opts.enable_osd then
        self._osd = nil
        return
    end

    local osd_mod = require("lxaudio.osd")
    self._osd = osd_mod.new(self.opts)
end

-- Rebuild the compact widget while preserving the public `instance.widget`.
function M:_build_widget()
    local widget_mod = require("lxaudio.widget")
    local content = widget_mod.build(self)

    self._content = content
    self.widget:set_widget(content)
end

-- Polling remains as a fallback even when event subscription is active.
function M:_start_timer()
    if self._timer then
        self._timer:stop()
        self._timer = nil
    end

    self._timer = gears.timer({
        timeout = self.opts.refresh_interval,
        autostart = true,
        call_now = true,
        callback = function()
            self:refresh()
        end,
    })
end

-- Subscribe to PulseAudio-compatible events so the widget updates quickly
-- after external changes.
function M:_start_subscription()
    if self._subscription_started then
        return
    end

    self._subscription_started = true

    local ok, audio = pcall(require, "lxaudio.audio")
    if not ok or not audio or not audio.subscribe then
        return
    end

    audio.subscribe(function()
        self:refresh()
    end)
end

-- Convenience wrapper for best-effort access to the audio backend.
function M:_with_audio(callback)
    local ok, audio = pcall(require, "lxaudio.audio")
    if ok and audio then
        callback(audio)
    end
end

-- Refresh the cached widget state and update the compact widget refs.
function M:refresh()
    local ok, audio = pcall(require, "lxaudio.audio")
    if not ok then
        return
    end

    local state = audio.get_widget_state(self.opts)
    if not state then
        return
    end

    self.state.volume = state.volume or 0
    self.state.muted = state.muted or false
    self.state.mic_volume = state.mic_volume or 0
    self.state.mic_muted = state.mic_muted or false
    self.state.mic_active = state.mic_active or false

    if self._refs then
        if self._refs.icon then
            self._refs.icon.text = self.state.muted and self.opts.icon_muted or self.opts.icon_unmuted
            self._refs.icon.fg = self.state.muted
                and (beautiful.lxaudio_widget_muted_fg or beautiful.fg_minimize or "#888888")
                or (beautiful.lxaudio_widget_fg or beautiful.fg_normal or "#ffffff")
        end

        if self._refs.bar then
            self._refs.bar.value = math.max(0, math.min(1, self.state.volume))
            self._refs.bar.color = self.state.muted
                and (beautiful.lxaudio_widget_muted_fg or beautiful.fg_minimize or "#888888")
                or (beautiful.lxaudio_bar_fg or beautiful.fg_normal or "#e2ccb0")
        end

        if self._refs.mic then
            self._refs.mic.text = self.state.mic_muted and self.opts.icon_mic_muted or self.opts.icon_mic_active
            self._refs.mic.visible = self.opts.show_mic_activity and self.state.mic_active or false
            self._refs.mic.fg = self.state.mic_muted
                and (beautiful.lxaudio_widget_mic_muted_fg or beautiful.fg_minimize or "#888888")
                or (beautiful.lxaudio_widget_mic_fg or beautiful.fg_urgent or "#ff6666")
        end

        if self._refs.mic_cluster then
            self._refs.mic_cluster.visible = self.opts.show_mic_activity and self.state.mic_active or false
        end

        if self._refs.mic_bar then
            self._refs.mic_bar.value = math.max(0, math.min(1, self.state.mic_volume))
            self._refs.mic_bar.visible = self.opts.show_mic_activity and self.state.mic_active or false
            self._refs.mic_bar.color = self.state.mic_muted
                and (beautiful.lxaudio_widget_mic_muted_fg or beautiful.fg_minimize or "#888888")
                or (beautiful.lxaudio_mic_bar_fg or beautiful.lxaudio_bar_fg or beautiful.fg_normal or "#e2ccb0")
        end
    end
end

function M:_show_output_osd()
    if not self._osd then
        return
    end

    local percent = math.floor((math.max(0, math.min(1, self.state.volume or 0)) * 100) + 0.5)
    self._osd.show_volume(percent, self.state.muted and self.opts.icon_muted or self.opts.icon_unmuted, "Volume OSD")
end

function M:_show_mute_osd()
    if not self._osd then
        return
    end

    if self.state.muted then
        self._osd.show_text("Muted", self.opts.icon_muted, "Mute Indicator")
    else
        self._osd.show_text("Unmuted", self.opts.icon_unmuted, "Mute Indicator")
    end
end

function M:_defer_refresh_and_osd(show_osd, renderer)
    gears.timer.start_new(0.1, function()
        self:refresh()

        if show_osd and renderer then
            renderer(self)
        end

        return false
    end)
end

function M:_defer_media_popup_refresh()
    gears.timer.start_new(0.1, function()
        self:refresh()

        if self._media_popup and self._media_popup.visible then
            require("lxaudio.popup_media").rebuild(self)
        end

        return false
    end)
end

-- Rebuild all internal modules and refresh the widget in place.
function M:reload()
    self:_clear_modules()
    self:_load_osd()
    self:_build_widget()
    self:_start_timer()
    self:refresh()
end

function M:_ensure_media_popup_selection()
    local item_count = #(self._media_popup_items or {})
    if item_count < 1 then
        self.media_popup_selected_index = 1
        return
    end

    self.media_popup_selected_index = math.max(1, math.min(self.media_popup_selected_index or 1, item_count))
end

function M:move_media_popup_selection(delta)
    self:_ensure_media_popup_selection()

    local item_count = #(self._media_popup_items or {})
    if item_count < 1 then
        return
    end

    self.media_popup_selected_index = math.max(1, math.min((self.media_popup_selected_index or 1) + delta, item_count))

    if self._media_popup and self._media_popup.visible then
        require("lxaudio.popup_media").rebuild(self)
    end
end

function M:selected_media_popup_item()
    self:_ensure_media_popup_selection()
    return (self._media_popup_items or {})[self.media_popup_selected_index or 1]
end

function M:change_selected_media_stream_volume(delta)
    local stream = self:selected_media_popup_item()
    if not stream then
        return
    end

    self:_with_audio(function(audio)
        if not audio.change_sink_input_volume then
            return
        end

        audio.change_sink_input_volume(stream.id, delta)
        self:_defer_media_popup_refresh()
    end)
end

function M:toggle_selected_media_stream_mute()
    local stream = self:selected_media_popup_item()
    if not stream then
        return
    end

    self:_with_audio(function(audio)
        if not audio.toggle_sink_input_mute then
            return
        end

        audio.toggle_sink_input_mute(stream.id)
        self:_defer_media_popup_refresh()
    end)
end

function M:set_selected_media_stream_volume(percent)
    local stream = self:selected_media_popup_item()
    if not stream then
        return
    end

    self:_with_audio(function(audio)
        if not audio.set_sink_input_volume then
            return
        end

        audio.set_sink_input_volume(stream.id, percent)
        self:_defer_media_popup_refresh()
    end)
end

function M:selected_media_popup_player()
    local stream = self:selected_media_popup_item()
    if not stream then
        return nil
    end

    if stream._matched_player then
        return stream._matched_player
    end

    local ok, media = pcall(require, "lxaudio.media")
    if not ok or not media or not media.player_for_stream then
        return nil
    end

    stream._matched_player = media.player_for_stream(stream)
    return stream._matched_player
end

function M:transport_selected_media_player(action)
    local player = self:selected_media_popup_player()
    if not player then
        return
    end

    local ok, media = pcall(require, "lxaudio.media")
    if not ok or not media then
        return
    end

    if action == "previous" and media.previous then
        media.previous(player)
    elseif action == "play_pause" and media.play_pause then
        media.play_pause(player)
    elseif action == "next" and media.next then
        media.next(player)
    else
        return
    end

    self:_defer_media_popup_refresh()
end

function M:set_popup_key_actions(map)
    self.opts.popup_key_actions = map or {}
end

function M:_handle_popup_media_action(action)
    if action == "volume_up" then
        self:volume_up(nil, { show_osd = true })
    elseif action == "volume_down" then
        self:volume_down(nil, { show_osd = true })
    elseif action == "toggle_mute" then
        self:toggle_mute({ show_osd = true })
    elseif action == "media_prev" then
        self:transport_selected_media_player("previous")
    elseif action == "media_play_pause" then
        self:transport_selected_media_player("play_pause")
    elseif action == "media_next" then
        self:transport_selected_media_player("next")
    else
        return false
    end

    return true
end

function M:_handle_media_popup_keygrabber(_, modifiers, key, event)
    if event ~= "press" then
        return
    end

    if not (self._media_popup and self._media_popup.visible) then
        self:blur_media_popup_keyboard_navigation()
        return
    end

    if popup_toggle_key_matches(self._media_popup_toggle_key, modifiers, key) then
        self:close_popups()
        return
    end

    local popup_key_actions = self.opts.popup_key_actions or {}
    if self:_handle_popup_media_action(popup_key_actions[key]) then
        return
    end

    if key == "Escape" then
        self:close_popups()
    elseif key == "Up" then
        self:move_media_popup_selection(-1)
    elseif key == "Down" then
        self:move_media_popup_selection(1)
    elseif key == "Left" then
        self:change_selected_media_stream_volume(-(self.opts.step or 0.05))
    elseif key == "Right" then
        self:change_selected_media_stream_volume(self.opts.step or 0.05)
    elseif key == "Home" then
        self:set_selected_media_stream_volume(100)
    elseif key == "End" then
        self:toggle_selected_media_stream_mute()
    end
end

function M:focus_media_popup_keyboard_navigation()
    if not self._media_popup_keygrabber then
        self._media_popup_keygrabber = keygrabber({
            stop_callback = function()
                self._media_popup_keyboard_navigation_active = false
            end,
            keypressed_callback = function(grabber, modifiers, key, event)
                self:_handle_media_popup_keygrabber(grabber, modifiers, key, event)
            end,
        })
    end

    self._media_popup_keyboard_navigation_active = true

    if self._media_popup_keygrabber.grabber then
        return
    end

    self._media_popup_keygrabber:start()
    self:_start_media_popup_outside_click_dismiss()
end

function M:blur_media_popup_keyboard_navigation()
    self._media_popup_keyboard_navigation_active = false
    self._media_popup_toggle_key = nil
    self:_stop_media_popup_outside_click_dismiss()

    if self._media_popup_keygrabber and self._media_popup_keygrabber.grabber then
        self._media_popup_keygrabber:stop()
    end
end

function M:blur_devices_popup_keyboard_navigation()
    -- placeholder to keep popup close/open flows symmetric if devices-side
    -- keyboard navigation is added later.
end

function M:_start_media_popup_outside_click_dismiss()
    self:_stop_media_popup_outside_click_dismiss()

    self._media_popup_outside_click_handler = function()
        local popup = self._media_popup
        if not (popup and popup.visible) then
            return
        end

        local coords = mouse.coords()
        if point_in_geometry(coords.x, coords.y, popup:geometry()) then
            return
        end

        self:close_popups()
    end

    self._media_popup_outside_click_binding = awful.button({}, 1, function()
        self._media_popup_outside_click_handler()
    end)

    awful.mouse.append_global_mousebinding(self._media_popup_outside_click_binding)

    if client and client.connect_signal then
        client.connect_signal("button::press", self._media_popup_outside_click_handler)
    end

    if drawin and drawin.connect_signal then
        drawin.connect_signal("button::press", self._media_popup_outside_click_handler)
    end
end

function M:_stop_media_popup_outside_click_dismiss()
    if self._media_popup_outside_click_binding then
        awful.mouse.remove_global_mousebinding(self._media_popup_outside_click_binding)
        self._media_popup_outside_click_binding = nil
    end

    if self._media_popup_outside_click_handler then
        if client and client.disconnect_signal then
            client.disconnect_signal("button::press", self._media_popup_outside_click_handler)
        end

        if drawin and drawin.disconnect_signal then
            drawin.disconnect_signal("button::press", self._media_popup_outside_click_handler)
        end

        self._media_popup_outside_click_handler = nil
    end
end

-- Toggle mute on the current default output device.
function M:toggle_mute(opts)
    opts = opts or {}
    self:_with_audio(function(audio)
        if not audio.toggle_mute then
            return
        end

        audio.toggle_mute()
        self:_defer_refresh_and_osd(opts.show_osd, function(instance)
            instance:_show_mute_osd()
        end)
    end)
end

-- Apply a signed volume delta, where `0.05` means 5 percent.
function M:change_volume(delta, opts)
    opts = opts or {}
    self:_with_audio(function(audio)
        if not audio.change_volume then
            return
        end

        audio.change_volume(delta)
        self:_defer_refresh_and_osd(opts.show_osd, function(instance)
            instance:_show_output_osd()
        end)
    end)
end

-- Toggle mute on all non-monitor inputs.
function M:toggle_input_mute()
    self:_with_audio(function(audio)
        if not audio.toggle_input_mute then
            return
        end

        audio.toggle_input_mute()
        self:refresh()
    end)
end

-- Apply a signed input volume delta, where `0.05` means 5 percent.
function M:change_input_volume(delta)
    self:_with_audio(function(audio)
        if not audio.change_input_volume then
            return
        end

        audio.change_input_volume(delta)
        self:refresh()
    end)
end

-- Increase the default output volume by the configured step.
function M:volume_up(step, opts)
    self:change_volume(step or self.opts.step, opts)
end

-- Decrease the default output volume by the configured step.
function M:volume_down(step, opts)
    self:change_volume(-(step or self.opts.step), opts)
end

-- Increase the default input volume by the configured step.
function M:input_volume_up(step)
    self:change_input_volume(step or self.opts.step)
end

-- Decrease the default input volume by the configured step.
function M:input_volume_down(step)
    self:change_input_volume(-(step or self.opts.step))
end

---Create a new lxaudio instance.
---@param opts? table
---@return table
function M.new(opts)
    opts = merge_defaults(opts)

    opts.hover_close_timeout = opts.hover_close_timeout or beautiful.lxaudio_hover_close_timeout or 1.5
    opts.hover_close_poll_interval = opts.hover_close_poll_interval or beautiful.lxaudio_hover_close_poll_interval or 0.25

    local self = setmetatable({}, M)
    self.opts = opts
    self.state = {
        volume = 0,
        muted = false,
        mic_volume = 0,
        mic_muted = false,
        mic_active = false,
    }
    self.media_popup_selected_index = 1
    self._media_popup_items = {}

    self.ui_state = self.ui_state or {
        media_players_expanded = true,
        playback_streams_expanded = true,
        outputs_expanded = true,
        inputs_expanded = true,
    }

    -- Stable outer container so reloading only swaps internals.
    self.widget = require("wibox").container.place()
    self._refs = {}

    self:_load_osd()
    self:_build_widget()
    self:_start_timer()
    self:refresh()
    self:_start_subscription()

    return self
end

-- Toggle the media popup. Accepts either explicit geometry for mouse-driven
-- placement or an options table for keyboard-driven placement.
function M:toggle_media_popup(anchor_geo, opts)
    anchor_geo, opts = normalize_popup_args(anchor_geo, opts)
    if opts.hover_close == nil then
        opts.hover_close = true
    end
    if opts.anchor == nil then
        opts.anchor = anchor_geo and "widget" or "center"
    end

    return self:_toggle_popup("media", anchor_geo, opts)
end

-- Toggle the devices popup. Accepts either explicit geometry for mouse-driven
-- placement or an options table for keyboard-driven placement.
function M:toggle_devices_popup(anchor_geo, opts)
    anchor_geo, opts = normalize_popup_args(anchor_geo, opts)
    if opts.hover_close == nil then
        opts.hover_close = true
    end
    if opts.anchor == nil then
        opts.anchor = anchor_geo and "widget" or "center"
    end

    return self:_toggle_popup("devices", anchor_geo, opts)
end

-- Keyboard-friendly popup entrypoint. Pass `hover_close = false` to keep the
-- popup open until it is explicitly closed.
function M:show_media_popup(anchor_geo, opts)
    anchor_geo, opts = normalize_popup_args(anchor_geo, opts)
    if opts.anchor == nil then
        opts.anchor = anchor_geo and "widget" or "center"
    end
    self:_show_popup("media", anchor_geo, opts)
end

-- Keyboard-friendly popup entrypoint. Pass `hover_close = false` to keep the
-- popup open until it is explicitly closed.
function M:show_devices_popup(anchor_geo, opts)
    anchor_geo, opts = normalize_popup_args(anchor_geo, opts)
    if opts.anchor == nil then
        opts.anchor = anchor_geo and "widget" or "center"
    end
    self:_show_popup("devices", anchor_geo, opts)
end

-- Shared popup toggle flow used by the mouse-driven API.
function M:_toggle_popup(kind, anchor_geo, opts)
    opts = opts or {}

    if kind == "media" and self._devices_popup then
        self._devices_popup.visible = false
        self:blur_devices_popup_keyboard_navigation()
    elseif kind == "devices" and self._media_popup then
        self._media_popup.visible = false
        self:blur_media_popup_keyboard_navigation()
    end

    local popup_module
    local popup_ref
    if kind == "media" then
        popup_module = require("lxaudio.popup_media")
        popup_ref = "_media_popup"
    else
        popup_module = require("lxaudio.popup_devices")
        popup_ref = "_devices_popup"
    end

    local shown = popup_module.toggle(self, anchor_geo, opts)
    if shown and self[popup_ref] and self[popup_ref].visible then
        if opts.hover_close == false then
            self:_stop_hover_close_timer()
            if kind == "media" then
                self._media_popup_toggle_key = normalize_popup_toggle_key(opts.toggle_key)
                self:focus_media_popup_keyboard_navigation()
            else
                self:blur_media_popup_keyboard_navigation()
            end
        else
            if kind == "media" then
                self:blur_media_popup_keyboard_navigation()
            end
            self:_start_hover_close_timer(kind, is_geometry(anchor_geo) and anchor_geo or nil)
        end
    else
        if kind == "media" then
            self:blur_media_popup_keyboard_navigation()
        end
        self:_stop_hover_close_timer()
    end

    return shown
end

-- Shared popup show flow used by keyboard shortcuts and programmatic calls.
function M:_show_popup(kind, anchor_geo, opts)
    opts = opts or {}

    if kind == "media" and self._devices_popup then
        self._devices_popup.visible = false
        self:blur_devices_popup_keyboard_navigation()
    elseif kind == "devices" and self._media_popup then
        self._media_popup.visible = false
        self:blur_media_popup_keyboard_navigation()
    end

    local popup_module
    if kind == "media" then
        popup_module = require("lxaudio.popup_media")
    else
        popup_module = require("lxaudio.popup_devices")
    end

    popup_module.show(self, anchor_geo, opts)

    if opts.hover_close == false then
        self:_stop_hover_close_timer()
        if kind == "media" then
            self._media_popup_toggle_key = normalize_popup_toggle_key(opts.toggle_key)
            self:focus_media_popup_keyboard_navigation()
        else
            self:blur_media_popup_keyboard_navigation()
        end
    else
        if kind == "media" then
            self:blur_media_popup_keyboard_navigation()
        end
        self:_start_hover_close_timer(kind, is_geometry(anchor_geo) and anchor_geo or nil)
    end
end

function M:_stop_hover_close_timer()
    if self._hover_close_timer then
        self._hover_close_timer:stop()
        self._hover_close_timer = nil
    end
end

-- Close a popup only after the pointer leaves both the popup and its anchor
-- for a configurable amount of time.
function M:_start_hover_close_timer(kind, anchor_geo)
    self:_stop_hover_close_timer()

    local outside_ticks = 0
    local poll_interval = self.opts.hover_close_poll_interval or 0.25
    local hover_timeout = self.opts.hover_close_timeout or 1.5
    local max_outside_ticks = math.max(1, math.floor((hover_timeout / poll_interval) + 0.5))

    self._hover_close_kind = kind
    self._hover_close_anchor_geo = anchor_geo

    self._hover_close_timer = gears.timer({
        timeout = poll_interval,
        autostart = true,
        call_now = false,
        callback = function()
            local popup = nil
            if self._hover_close_kind == "media" then
                popup = self._media_popup
            elseif self._hover_close_kind == "devices" then
                popup = self._devices_popup
            end

            if not (popup and popup.visible) then
                self:_stop_hover_close_timer()
                return
            end

            local mx, my = mouse.coords().x, mouse.coords().y
            local pg = popup:geometry()
            local ag = self._hover_close_anchor_geo

            local inside_popup =
                mx >= pg.x and mx < (pg.x + pg.width) and
                my >= pg.y and my < (pg.y + pg.height)

            local inside_anchor = ag and
                mx >= ag.x and mx < (ag.x + ag.width) and
                my >= ag.y and my < (ag.y + ag.height)

            if inside_popup or inside_anchor then
                outside_ticks = 0
                return
            end

            outside_ticks = outside_ticks + 1
            if outside_ticks >= max_outside_ticks then
                popup.visible = false
                self:_stop_hover_close_timer()
            end
        end,
    })
end

-- Close all popups and stop any hover-close timer.
function M:close_popups()
    self:_stop_hover_close_timer()
    self:blur_media_popup_keyboard_navigation()
    self:blur_devices_popup_keyboard_navigation()

    if self._media_popup then
        self._media_popup.visible = false
    end

    if self._devices_popup then
        self._devices_popup.visible = false
    end
end

return M
