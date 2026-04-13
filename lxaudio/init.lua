local gears = require("gears")
local beautiful = require("beautiful")

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

-- Rebuild all internal modules and refresh the widget in place.
function M:reload()
    self:_clear_modules()
    self:_load_osd()
    self:_build_widget()
    self:_start_timer()
    self:refresh()
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
    elseif kind == "devices" and self._media_popup then
        self._media_popup.visible = false
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
        else
            self:_start_hover_close_timer(kind, is_geometry(anchor_geo) and anchor_geo or nil)
        end
    else
        self:_stop_hover_close_timer()
    end

    return shown
end

-- Shared popup show flow used by keyboard shortcuts and programmatic calls.
function M:_show_popup(kind, anchor_geo, opts)
    opts = opts or {}

    if kind == "media" and self._devices_popup then
        self._devices_popup.visible = false
    elseif kind == "devices" and self._media_popup then
        self._media_popup.visible = false
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
    else
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

    if self._media_popup then
        self._media_popup.visible = false
    end

    if self._devices_popup then
        self._devices_popup.visible = false
    end
end

return M
