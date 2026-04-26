local popup_placement = require("lxcommon.popup_placement")
local popup_controller = require("lxcommon.popup_controller")

local controller = {}

---Attach popup session-control methods to the lxpower instance method table.
function controller.extend(instance_methods)
    popup_controller.extend(instance_methods, {
        actions = {
            Right = function(self)
                self:pin_selected_profile()
            end,
            Left = function(self)
                self:set_pinned(false)
            end,
        },
        prepare_opts = function(self, popup_opts)
            if popup_opts.placement == nil then
                popup_opts.placement = popup_placement.normalize(self:_theme_value("lxpower_popup_placement", "center"), "center")
            end

            popup_opts.bg = popup_opts.bg or self:_theme_value("lxpower_popup_bg", "#222222")
            popup_opts.width = popup_opts.width or self:_theme_value("lxpower_popup_width", 360)
            return popup_opts
        end,
    })
end

return controller
