local awful = require("awful")
local gears = require("gears")

local M = {}

---Attach popup/session-control helpers to lxrunner.
function M.extend(instance_methods)
    ---Start a fresh keygrabber for the current runner session.
    function instance_methods:_start_keygrabber()
        if self._keygrabber then
            self._keygrabber:stop()
        end

        self._keygrabber = awful.keygrabber({
            auto_start = false,
            stop_event = "release",
            keypressed_callback = function(_, _, key)
                if key == "Escape" then
                    self:hide()
                    return
                end

                if key == "Up" then
                    self:_move_selection(-1)
                    return
                end

                if key == "Down" then
                    self:_move_selection(1)
                    return
                end

                if key == "BackSpace" then
                    self._input = self._input:sub(1, -2)
                    self:_refresh()
                    return
                end

                if key == "Tab" or key == "ISO_Left_Tab" then
                    self:_complete_input()
                    return
                end

                if key == "Return" or key == "KP_Enter" then
                    self:_launch_selected()
                    return
                end

                if #key == 1 then
                    self:_append_input(key)
                end
            end,
        })

        self._keygrabber:start()
    end

    ---Stop the active keygrabber, if any.
    function instance_methods:_stop_keygrabber()
        if self._keygrabber then
            self._keygrabber:stop()
            self._keygrabber = nil
        end
    end

    ---Dismiss the popup when the user clicks outside of it.
    function instance_methods:_start_mousegrabber()
        if self._mousegrabber_running then
            return
        end

        self._mousegrabber_running = true
        self._mousegrabber_armed = false
        mousegrabber.run(function(mouse_state)
            if not self.visible or not self.popup.visible then
                self._mousegrabber_running = false
                self._mousegrabber_armed = false
                return false
            end

            local button_down = mouse_state.buttons[1] or mouse_state.buttons[2] or mouse_state.buttons[3]
            if not self._mousegrabber_armed then
                if button_down then
                    return true
                end

                self._mousegrabber_armed = true
            end

            local geometry = self.popup:geometry()
            local inside = mouse_state.x >= geometry.x
                and mouse_state.x < geometry.x + geometry.width
                and mouse_state.y >= geometry.y
                and mouse_state.y < geometry.y + geometry.height

            if not inside and button_down then
                self._mousegrabber_running = false
                self._mousegrabber_armed = false
                self:hide()
                return false
            end

            return true
        end, "left_ptr")
    end

    ---Stop the outside-click mousegrabber.
    function instance_methods:_stop_mousegrabber()
        if self._mousegrabber_running then
            mousegrabber.stop()
            self._mousegrabber_running = false
            self._mousegrabber_armed = false
        end
    end

    ---Open the runner on the focused screen and reset transient state.
    function instance_methods:show()
        self.visible = true
        self._input = ""
        self._matches = {}
        self._selected_index = 1
        self:_ensure_path_commands()
        self:_load_aliases()
        self:_load_history()
        self.popup.screen = awful.screen.focused()
        self.popup.visible = true
        awful.placement.centered(self.popup, { honor_workarea = true, parent = awful.screen.focused() })
        self:_refresh()
        self:_start_keygrabber()
        gears.timer.delayed_call(function()
            if self.visible and self.popup.visible then
                self:_start_mousegrabber()
            end
        end)
    end

    ---Close the runner and tear down transient grabbers.
    function instance_methods:hide()
        self.visible = false
        self.popup.visible = false
        self:_stop_keygrabber()
        self:_stop_mousegrabber()
        self:_render_prompt()
    end

    ---Toggle the runner popup.
    function instance_methods:toggle()
        if self.popup.visible then
            self:hide()
        else
            self:show()
        end
    end
end

return M
