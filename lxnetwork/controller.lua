local popup_controller = require("lxcommon.popup_controller")

local controller = {}

---Attach popup session-control methods to the lxnetwork instance method table.
function controller.extend(instance_methods)
    popup_controller.extend(instance_methods, {
        geometry_providers = function(self)
            return {
                function()
                    return self._popup and self._popup.visible and self._popup:geometry() or nil
                end,
                function()
                    return self._password_popup and self._password_popup.visible and self._password_popup:geometry() or nil
                end,
            }
        end,
        close_extras = function(self)
            self:_close_password_prompt()
        end,
    })
end

return controller
