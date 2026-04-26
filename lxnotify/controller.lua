local popup_controller = require("lxcommon.popup_controller")
local popup_control = require("lxcommon.popup_control")

local popup = require("lxnotify.popup")

local controller = {}

local IGNORED_POPUP_MODIFIERS = {
    Lock = true,
    Mod2 = true,
    Mod3 = true,
    Mod5 = true,
}

local function current_anchor()
    if mouse and mouse.current_widget_geometry then
        local geometry = mouse.current_widget_geometry
        if geometry then
            return geometry
        end
    end

    return nil
end

function controller.extend(instance_methods)
    popup_controller.extend(instance_methods, {
        ignored_modifiers = IGNORED_POPUP_MODIFIERS,
        prepare_opts = function(self, popup_opts)
            popup_opts.bg = popup_opts.bg or self:popup_bg()
            popup_opts.placement = popup_opts.placement or self:popup_placement()
            popup_opts.width = popup_opts.width or self:popup_width()
            return popup_opts
        end,
        actions = {
            Return = function(self)
                self:activate_selected_popup_enter()
            end,
            KP_Enter = function(self)
                self:activate_selected_popup_enter()
            end,
            Right = function(self)
                self:activate_selected_popup_right()
            end,
            Left = function(self)
                if self.active_group_key then
                    self:leave_group_detail()
                else
                    self:close_popup()
                end
            end,
        },
        open = function(self, anchor, popup_opts)
            self._popup_session_opts = popup_opts
            require("lxcommon.popup_session").show(self, "_popup", anchor, function()
                return popup.build(self)
            end, popup_opts)
            return self:popup_visible()
        end,
    })

    function instance_methods:show_notification_popup(arg1, arg2)
        local opts = popup_control.normalize_popup_opts(arg1, arg2)
        if opts.hover_close == nil then
            opts.hover_close = false
        end

        self:show_popup(current_anchor(), opts)
    end

    function instance_methods:toggle_notification_popup(arg1, arg2)
        local opts = popup_control.normalize_popup_opts(arg1, arg2)
        if opts.hover_close == nil then
            opts.hover_close = false
        end

        self:toggle_popup(current_anchor(), opts)
    end

    function instance_methods:close_popups()
        self:close_popup()
    end
end

return controller
