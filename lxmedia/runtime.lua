local gears = require("gears")
local beautiful = require("beautiful")
local widget_feedback = require("lxcommon.widget_feedback")

local M = {}

local function audio_popup_visible(instance)
    return (instance._media_popup and instance._media_popup.visible)
        or (instance._devices_popup and instance._devices_popup.visible)
        or false
end

---Attach widget/runtime helpers to the lxmedia instance method table.
function M.extend(instance_methods)
    -- Clear cached submodules so reloads pick up on-disk changes without
    -- replacing the stable outer widget container.
    function instance_methods:_clear_modules()
        package.loaded["lxmedia.widget"] = nil
        package.loaded["lxmedia.audio"] = nil
        package.loaded["lxmedia.media"] = nil
        package.loaded["lxmedia.popup_media"] = nil
        package.loaded["lxmedia.popup_devices"] = nil
    end

    function instance_methods:_load_osd()
        if not self.opts.enable_osd then
            self._osd = nil
            return
        end

        self._osd = require("lxcommon.osd").new({
            width = self.opts.osd_width,
            height = self.opts.osd_height,
            margin = self.opts.osd_margin,
            timeout = beautiful.lxmedia_osd_timeout or 1,
            bar_bg = beautiful.bg_minimize or "#444444",
            bar_fg = beautiful.fg_normal or "#ffffff",
        })
    end

    -- Rebuild the compact widget while preserving the public `instance.widget`.
    function instance_methods:_build_widget()
        local widget_mod = require("lxmedia.widget")
        local content = widget_mod.build(self)

        self._content = content
        self.widget:set_widget(content)
    end

    -- Polling remains as a fallback even when event subscription is active.
    function instance_methods:_start_timer()
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
    function instance_methods:_start_subscription()
        if self._subscription_started then
            return
        end

        self._subscription_started = true

        local ok, audio = pcall(require, "lxmedia.audio")
        if not ok or not audio or not audio.subscribe then
            return
        end

        audio.subscribe(function()
            self:refresh()
        end)
    end

    -- Convenience wrapper for best-effort access to the audio backend.
    function instance_methods:_with_audio(callback)
        local ok, audio = pcall(require, "lxmedia.audio")
        if ok and audio then
            callback(audio)
        end
    end

    function instance_methods:_apply_widget_state()
        if not self._refs then
            return
        end

        if self._refs.icon then
            self._refs.icon.text = self.state.muted and self.opts.icon_muted or self.opts.icon_unmuted
            self._refs.icon.fg = self.state.muted
                and (beautiful.lxmedia_widget_muted_fg or beautiful.fg_minimize or "#888888")
                or (beautiful.lxmedia_widget_fg or beautiful.fg_normal or "#ffffff")
        end

        if self._refs.bar then
            self._refs.bar.value = math.max(0, math.min(1, self.state.volume))
            self._refs.bar.color = self.state.muted
                and (beautiful.lxmedia_widget_muted_fg or beautiful.fg_minimize or "#888888")
                or (beautiful.lxmedia_bar_fg or beautiful.fg_normal or "#e2ccb0")
        end

        if self._refs.mic then
            self._refs.mic.text = self.state.mic_muted and self.opts.icon_mic_muted or self.opts.icon_mic_active
            self._refs.mic.visible = self.opts.show_mic_activity and self.state.mic_active or false
            self._refs.mic.fg = self.state.mic_muted
                and (beautiful.lxmedia_widget_mic_muted_fg or beautiful.fg_minimize or "#888888")
                or (beautiful.lxmedia_widget_mic_fg or beautiful.fg_urgent or "#ff6666")
        end

        if self._refs.mic_cluster then
            self._refs.mic_cluster.visible = self.opts.show_mic_activity and self.state.mic_active or false
        end

        if self._refs.mic_bar then
            self._refs.mic_bar.value = math.max(0, math.min(1, self.state.mic_volume))
            self._refs.mic_bar.visible = self.opts.show_mic_activity and self.state.mic_active or false
            self._refs.mic_bar.color = self.state.mic_muted
                and (beautiful.lxmedia_widget_mic_muted_fg or beautiful.fg_minimize or "#888888")
                or (beautiful.lxmedia_mic_bar_fg or beautiful.lxmedia_bar_fg or beautiful.fg_normal or "#e2ccb0")
        end

        self:_sync_toplevel_bar_visibility()
    end

    function instance_methods:_sync_toplevel_bar_visibility()
        if not self._refs then
            return
        end

        local show_bars = self._widget_hovered or audio_popup_visible(self)

        if self._refs.output_bar_slot then
            self._refs.output_bar_slot.visible = show_bars
        end
        if self._refs.output_bar_margin then
            self._refs.output_bar_margin.visible = show_bars
            self._refs.output_bar_margin.forced_width = show_bars and self._refs.output_bar_shown_width or self._refs.output_bar_hidden_width
        end

        if self._refs.mic_bar_slot then
            self._refs.mic_bar_slot.visible = show_bars and (self.opts.show_mic_activity and self.state.mic_active or false)
        end
        if self._refs.mic_bar_margin then
            self._refs.mic_bar_margin.visible = show_bars and (self.opts.show_mic_activity and self.state.mic_active or false)
            self._refs.mic_bar_margin.forced_width = (show_bars and (self.opts.show_mic_activity and self.state.mic_active or false))
                and self._refs.mic_bar_shown_width
                or self._refs.mic_bar_hidden_width
        end

        widget_feedback.sync(self, function()
            return audio_popup_visible(self)
        end)
    end

    function instance_methods:_schedule_refresh(delay, opts)
        opts = opts or {}

        if self._post_action_refresh_timer then
            self._post_action_refresh_timer:stop()
            self._post_action_refresh_timer = nil
        end

        self._post_action_refresh_timer = gears.timer.start_new(delay or 0.12, function()
            self._post_action_refresh_timer = nil
            self:refresh()

            if opts.refresh_media_popup and self._media_popup and self._media_popup.visible then
                require("lxmedia.popup_media").rebuild(self)
            end

            return false
        end)
    end

    -- Refresh the cached widget state and update the compact widget refs.
    function instance_methods:refresh()
        local ok, audio = pcall(require, "lxmedia.audio")
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

        self:_apply_widget_state()
    end

    function instance_methods:_show_output_osd()
        if not self._osd then
            return
        end

        local percent = math.floor((math.max(0, math.min(1, self.state.volume or 0)) * 100) + 0.5)
        self._osd:show_progress({
            value = percent,
            icon = self.state.muted and self.opts.icon_muted or self.opts.icon_unmuted,
            app_name = "Volume OSD",
            color = beautiful.fg_normal or "#ffffff",
        })
    end

    function instance_methods:_show_mute_osd()
        if not self._osd then
            return
        end

        if self.state.muted then
            self._osd:show_text({
                text = "Muted",
                icon = self.opts.icon_muted,
                app_name = "Mute Indicator",
            })
        else
            self._osd:show_text({
                text = "Unmuted",
                icon = self.opts.icon_unmuted,
                app_name = "Mute Indicator",
            })
        end
    end

    -- Rebuild all internal modules and refresh the widget in place.
    function instance_methods:reload()
        self:_clear_modules()
        self:_load_osd()
        self:_build_widget()
        self:_start_timer()
        self:refresh()
    end
end

return M
