local popup_control = require("lxcommon.popup_control")

local M = {}

local function defer_media_popup_refresh(instance)
    if instance._defer_media_popup_refresh then
        instance:_defer_media_popup_refresh()
        return
    end

    if instance._schedule_refresh then
        instance:_schedule_refresh(0.12, { refresh_media_popup = true })
        return
    end

    if instance.refresh then
        instance:refresh()
    end
end

---Attach media-popup selection and keyboard-control helpers to lxmedia.
function M.extend(instance_methods)
    function instance_methods:_ensure_media_popup_selection()
        local item_count = #(self._media_popup_items or {})
        if item_count < 1 then
            self.media_popup_selected_index = 1
            return
        end

        self.media_popup_selected_index = math.max(1, math.min(self.media_popup_selected_index or 1, item_count))
    end

    function instance_methods:move_media_popup_selection(delta)
        self:_ensure_media_popup_selection()

        local item_count = #(self._media_popup_items or {})
        if item_count < 1 then
            return
        end

        self.media_popup_selected_index = math.max(1, math.min((self.media_popup_selected_index or 1) + delta, item_count))

        if self._media_popup and self._media_popup.visible then
            require("lxmedia.popup_media").rebuild(self)
        end
    end

    function instance_methods:selected_media_popup_item()
        self:_ensure_media_popup_selection()
        return (self._media_popup_items or {})[self.media_popup_selected_index or 1]
    end

    function instance_methods:change_selected_media_stream_volume(delta)
        local stream = self:selected_media_popup_item()
        if not stream then
            return
        end

        self:_with_audio(function(audio)
            if not audio.change_sink_input_volume then
                return
            end

            audio.change_sink_input_volume(stream.id, delta)
            defer_media_popup_refresh(self)
        end)
    end

    function instance_methods:toggle_selected_media_stream_mute()
        local stream = self:selected_media_popup_item()
        if not stream then
            return
        end

        self:_with_audio(function(audio)
            if not audio.toggle_sink_input_mute then
                return
            end

            audio.toggle_sink_input_mute(stream.id)
            defer_media_popup_refresh(self)
        end)
    end

    function instance_methods:activate_selected_media_popup_item()
        self:toggle_selected_media_stream_mute()
    end

    function instance_methods:set_selected_media_stream_volume(percent)
        local stream = self:selected_media_popup_item()
        if not stream then
            return
        end

        self:_with_audio(function(audio)
            if not audio.set_sink_input_volume then
                return
            end

            audio.set_sink_input_volume(stream.id, percent)
            defer_media_popup_refresh(self)
        end)
    end

    function instance_methods:selected_media_popup_player()
        local stream = self:selected_media_popup_item()
        if not stream then
            return nil
        end

        if stream._matched_player then
            return stream._matched_player
        end

        local ok, media = pcall(require, "lxmedia.media")
        if not ok or not media or not media.player_for_stream then
            return nil
        end

        stream._matched_player = media.player_for_stream(stream)
        return stream._matched_player
    end

    function instance_methods:transport_selected_media_player(action)
        local player = self:selected_media_popup_player()
        if not player then
            return
        end

        local ok, media = pcall(require, "lxmedia.media")
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

        defer_media_popup_refresh(self)
    end

    function instance_methods:set_popup_key_actions(map)
        self.opts.popup_key_actions = map or {}
    end

    function instance_methods:_handle_popup_media_action(action)
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

    function instance_methods:_handle_media_popup_keygrabber(_, modifiers, key, event)
        local popup_key_actions = self.opts.popup_key_actions or {}
        local handled = popup_control.dispatch_popup_keypress({
            event = event,
            modifiers = modifiers,
            key = key,
            is_open = function()
                return self:popup_visible("_media_popup")
            end,
            on_not_open = function()
                self:blur_popup_keyboard_navigation()
            end,
            prev_keychain = self._media_popup_prev_keychain,
            next_keychain = self._media_popup_next_keychain,
            toggle_key = self._media_popup_toggle_key,
            on_cycle_prev = self._media_popup_on_cycle_prev,
            on_cycle_next = self._media_popup_on_cycle_next,
            on_close = function()
                self:close_popups()
            end,
            actions = {
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
            },
            blocked_global_keys = {
                "Up", "Down", "Return", "KP_Enter", "Left", "Right", "Home", "End", "Escape",
            },
            allow_global_fallback = false,
        })

        if handled then
            return
        end

        if self:_handle_popup_media_action(popup_key_actions[key]) then
            return
        end

        if popup_control.dispatch_global_keybinding(modifiers, key, {
            blocked_keys = {
                "Up", "Down", "Return", "KP_Enter", "Left", "Right", "Home", "End", "Escape",
            },
            before_dispatch = function()
                self:close_popups()
            end,
        }) then
            return
        end
    end

end

return M
