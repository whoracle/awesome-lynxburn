local gears = require("gears")
local beautiful = require("beautiful")
local popup_placement = require("lxcommon.popup_placement")
local popup_controller = require("lxcommon.popup_controller")
local devices_popup_controller = require("lxmedia.devices_popup_controller")
local media_popup_controller = require("lxmedia.media_popup_controller")
local runtime = require("lxmedia.runtime")

local M = {}
M.__index = M

local DEFAULTS = {
    show_mic_activity = true,
    refresh_interval = 5,
    width = 50,
    step = 0.05, -- 5%
    icon_muted = beautiful.lxmedia_icon_muted or "",
    icon_unmuted = beautiful.lxmedia_icon_volume or "",
    icon_mic_active = beautiful.lxmedia_icon_mic_active or "🎙",
    icon_mic_muted = beautiful.lxmedia_icon_mic_muted or "×",
    enable_osd = true,
    osd_width = 260,
    osd_height = 18,
    osd_margin = 16,
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

runtime.extend(M)
devices_popup_controller.extend(M)
media_popup_controller.extend(M)
popup_controller.extend(M, {
    default_popup = "media",
    popups = {
        media = {
            popup_key = "_media_popup",
            opts_key = "_media_popup_opts",
            build = function(self)
                return require("lxmedia.popup_media").build(self)
            end,
            prepare_opts = function(_, popup_opts, anchor_geo)
                if popup_opts.hover_close == nil then
                    popup_opts.hover_close = false
                end
                if popup_opts.anchor == nil then
                    popup_opts.anchor = anchor_geo and "widget" or "center"
                end
                if popup_opts.placement == nil then
                    popup_opts.placement = popup_placement.normalize(beautiful.lxmedia_popup_placement_media, "center")
                end

                popup_opts.bg = popup_opts.bg or beautiful.lxmedia_popup_bg or beautiful.bg_normal or "#222222"
                popup_opts.width = popup_opts.width or beautiful.lxmedia_popup_width_media or 360
                return popup_opts
            end,
            actions = function(self)
                local actions = {
                    Up = function()
                        self:move_media_popup_selection(-1)
                    end,
                    Down = function()
                        self:move_media_popup_selection(1)
                    end,
                    Return = function()
                        self:activate_selected_media_popup_item()
                    end,
                    KP_Enter = function()
                        self:activate_selected_media_popup_item()
                    end,
                    Left = function()
                        self:change_selected_media_stream_volume(-(self.opts.step or 0.05))
                    end,
                    Right = function()
                        self:change_selected_media_stream_volume(self.opts.step or 0.05)
                    end,
                    Home = function()
                        self:set_selected_media_stream_volume(100)
                    end,
                    End = function()
                        self:toggle_selected_media_stream_mute()
                    end,
                }

                for key, action in pairs(self.opts.popup_key_actions or {}) do
                    actions[key] = function()
                        self:_handle_popup_media_action(action)
                    end
                end

                return actions
            end,
            default_actions = false,
        },
        devices = {
            popup_key = "_devices_popup",
            opts_key = "_devices_popup_opts",
            build = function(self)
                return require("lxmedia.popup_devices").build(self)
            end,
            prepare_opts = function(_, popup_opts, anchor_geo)
                if popup_opts.hover_close == nil then
                    popup_opts.hover_close = false
                end
                if popup_opts.anchor == nil then
                    popup_opts.anchor = anchor_geo and "widget" or "center"
                end
                if popup_opts.placement == nil then
                    popup_opts.placement = popup_placement.normalize(beautiful.lxmedia_popup_placement_devices, "center")
                end

                popup_opts.bg = popup_opts.bg or beautiful.lxmedia_popup_bg or beautiful.bg_normal or "#222222"
                popup_opts.width = popup_opts.width or beautiful.lxmedia_popup_width_devices or 360
                return popup_opts
            end,
            actions = {
                Up = function(self)
                    self:move_devices_popup_selection(-1)
                end,
                Down = function(self)
                    self:move_devices_popup_selection(1)
                end,
                Return = function(self)
                    self:activate_selected_devices_popup_item()
                end,
                KP_Enter = function(self)
                    self:activate_selected_devices_popup_item()
                end,
            },
            default_actions = false,
        },
    },
})

function M:toggle_media_popup(anchor_geo, opts)
    return self:toggle_named_popup("media", anchor_geo, opts)
end

function M:toggle_devices_popup(anchor_geo, opts)
    return self:toggle_named_popup("devices", anchor_geo, opts)
end

function M:show_media_popup(anchor_geo, opts)
    return self:show_named_popup("media", anchor_geo, opts)
end

function M:show_devices_popup(anchor_geo, opts)
    return self:show_named_popup("devices", anchor_geo, opts)
end

function M:close_popups()
    return self:close_all_popups()
end

-- Toggle mute on the current default output device.
function M:toggle_mute(opts)
    opts = opts or {}
    self:_with_audio(function(audio)
        if not audio.toggle_mute then
            return
        end

        self.state.muted = not self.state.muted
        self:_apply_widget_state()
        if opts.show_osd then
            self:_show_mute_osd()
        end

        audio.toggle_mute()
        self:_schedule_refresh(0.12, { refresh_media_popup = true })
    end)
end

-- Apply a signed volume delta, where `0.05` means 5 percent.
function M:change_volume(delta, opts)
    opts = opts or {}
    self:_with_audio(function(audio)
        if not audio.change_volume then
            return
        end

        self.state.volume = math.max(0, math.min(1, (self.state.volume or 0) + delta))
        self:_apply_widget_state()
        if opts.show_osd then
            self:_show_output_osd()
        end

        audio.change_volume(delta)
        self:_schedule_refresh(0.12, { refresh_media_popup = true })
    end)
end

-- Toggle mute on all non-monitor inputs.
function M:toggle_input_mute()
    self:_with_audio(function(audio)
        if not audio.toggle_input_mute then
            return
        end

        self.state.mic_muted = not self.state.mic_muted
        self:_apply_widget_state()
        audio.toggle_input_mute()
        self:_schedule_refresh(0.12, { refresh_media_popup = true })
    end)
end

-- Apply a signed input volume delta, where `0.05` means 5 percent.
function M:change_input_volume(delta)
    self:_with_audio(function(audio)
        if not audio.change_input_volume then
            return
        end

        self.state.mic_volume = math.max(0, math.min(1, (self.state.mic_volume or 0) + delta))
        self:_apply_widget_state()
        audio.change_input_volume(delta)
        self:_schedule_refresh(0.12, { refresh_media_popup = true })
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

---Create a new lxmedia instance.
---@param opts? table
---@return table
function M.new(opts)
    opts = merge_defaults(opts)

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
    self.devices_popup_selected_index = 1
    self._media_popup_items = {}
    self._devices_popup_items = {}

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

return M
