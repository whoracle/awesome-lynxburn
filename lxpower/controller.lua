local popup_placement = require("lxcommon.popup_placement")
local popup_shell = require("lxcommon.popup_shell")
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

            popup_opts.width = popup_opts.width or self:_theme_value("lxpower_popup_width", 360)
            return popup_opts
        end,
        open = function(self, anchor, popup_opts)
            local visible = popup_shell.toggle_popup(self, "_popup", "_popup_anchor", anchor, function()
                return self:_build_popup()
            end, popup_opts)

            if visible and self._refresh_popup then
                self:_refresh_popup()
            end

            return visible
        end,
    })
end

return controller
