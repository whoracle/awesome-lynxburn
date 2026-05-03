local M = {}

function M.extend(instance_methods)
    function instance_methods:_ensure_devices_popup_selection()
        local item_count = #(self._devices_popup_items or {})
        if item_count < 1 then
            self.devices_popup_selected_index = 1
            return
        end

        self.devices_popup_selected_index = math.max(1, math.min(self.devices_popup_selected_index or 1, item_count))
    end

    function instance_methods:move_devices_popup_selection(delta)
        self:_ensure_devices_popup_selection()

        local item_count = #(self._devices_popup_items or {})
        if item_count < 1 then
            return
        end

        self.devices_popup_selected_index = math.max(1, math.min((self.devices_popup_selected_index or 1) + delta, item_count))

        if self._devices_popup and self._devices_popup.visible then
            require("lxmedia.popup_devices").rebuild(self)
        end
    end

    function instance_methods:activate_selected_devices_popup_item()
        self:_ensure_devices_popup_selection()
        local item = (self._devices_popup_items or {})[self.devices_popup_selected_index or 1]
        if item and type(item.on_enter) == "function" then
            item.on_enter()
        end
    end

    function instance_methods:set_devices_popup_selection(index)
        local item_count = #(self._devices_popup_items or {})
        if item_count < 1 then
            self.devices_popup_selected_index = 1
            return
        end

        self.devices_popup_selected_index = math.max(1, math.min(index or 1, item_count))

        if self._devices_popup and self._devices_popup.visible then
            require("lxmedia.popup_devices").rebuild(self)
        end
    end

end

return M
