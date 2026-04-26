local popup_controller = require("lxcommon.popup_controller")

local controller = {}

---Attach popup session-control methods to the lxnetwork instance method table.
function controller.extend(instance_methods)
    popup_controller.extend(instance_methods, {
        default_popup = "main",
        popups = {
            main = {
                popup_key = "_popup",
                prepare_opts = function(self, popup_opts)
                    popup_opts.bg = popup_opts.bg or self:_theme_value("lxnetwork_popup_bg", "#222222")
                    popup_opts.placement = popup_opts.placement or self:_theme_value("lxnetwork_popup_placement", "side")
                    popup_opts.width = popup_opts.width or self:_theme_value("lxnetwork_popup_width", 380)
                    return popup_opts
                end,
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
            },
        },
    })
end

return controller
