local popup_controller = require("lxcommon.popup_controller")

local controller = {}

---Attach popup session-control methods to the lxbluetooth instance method table.
function controller.extend(instance_methods)
    popup_controller.extend(instance_methods, {
        prepare_opts = function(self, popup_opts)
            popup_opts.bg = popup_opts.bg or self:_theme_value("lxbluetooth_popup_bg", "#222222")
            popup_opts.placement = popup_opts.placement or self:_theme_value("lxbluetooth_popup_placement", "side")
            popup_opts.width = popup_opts.width or self:_theme_value("lxbluetooth_popup_width", 360)
            return popup_opts
        end,
    })
end

return controller
