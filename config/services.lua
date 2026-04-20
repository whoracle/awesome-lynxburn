local M = {}

local module_config = require("config.lxmodules")
local registry = require("config.services.registry")
local state = require("config.services.state")

local function popup_visible(instance, field_name)
    return instance[field_name] and instance[field_name].visible or false
end

local function register_single_popup(module_id, instance, popup_id, popup_role, popup_field, open_fn, close_fn, opts)
    registry.register_semantic_popup(module_id, popup_id, popup_role, {
        hover_close = opts and opts.hover_close,
        open = function(popup_opts)
            open_fn(instance, popup_opts)
        end,
        close = function()
            close_fn(instance)
        end,
        is_visible = function()
            return popup_visible(instance, popup_field)
        end,
    })
end

local function runner_options()
    local options = module_config.options("runner")

    -- Aliases are loaded directly from config data inside lxrunner so the
    -- service does not need to pass a duplicated copy.
    options.aliases = nil

    return options
end

---Return the shared lxmedia instance.
---@return table
function M.media()
    return state.ensure("media", function()
        local instance = require("lxmedia").new(module_config.options("media"))

        registry.register_widget("media", instance.widget, 40)
        register_single_popup("media", instance, "default", "primary", "_media_popup", function(service, popup_opts)
            service:show_media_popup(nil, popup_opts)
        end, function(service)
            service:close_popups()
        end, {
            hover_close = false,
        })
        register_single_popup("media", instance, "devices", "secondary", "_devices_popup", function(service, popup_opts)
            service:show_devices_popup(nil, popup_opts)
        end, function(service)
            service:close_popups()
        end, {
            hover_close = false,
        })

        return instance
    end)
end

---Return the shared lxbar instance.
---@return table
function M.bar()
    local bar = state.ensure("bar", function()
        registry.configure_widget_registry()
        return require("lxbar").new()
    end)

    bar:refresh()
    return bar
end

---Return the shared lxbluetooth instance.
---@return table
function M.bluetooth()
    return state.ensure("bluetooth", function()
        local instance = require("lxbluetooth").new(module_config.options("bluetooth"))

        registry.register_widget("bluetooth", instance.widget, 10)
        register_single_popup("bluetooth", instance, "default", "primary", "_popup", function(service, popup_opts)
            service:toggle_popup(nil, popup_opts)
        end, function(service)
            service:close_popup()
        end)

        return instance
    end)
end

---Return the shared lxnotify instance.
---@return table
function M.notify()
    return state.ensure("notify", function()
        local instance = require("lxnotify").new(module_config.options("notify"))

        registry.register_widget("notify", instance.widget, 50)
        register_single_popup("notify", instance, "default", "primary", "_popup", function(service, popup_opts)
            service:show_notification_popup(popup_opts)
        end, function(service)
            service:close_popups()
        end, {
            hover_close = false,
        })

        return instance
    end)
end

---Return the shared lxdisplay instance.
---@return table
function M.display()
    return state.ensure("display", function()
        local instance = require("lxdisplay").new(module_config.options("display"))

        registry.register_widget("display", instance.widget, 60)
        if instance.xrandr_enabled and instance:xrandr_enabled() then
            register_single_popup("display", instance, "default", "secondary", "_popup", function(service, popup_opts)
                service:toggle_popup(nil, popup_opts)
            end, function(service)
                service:close_popup()
            end)
        end

        return instance
    end)
end

---Return the shared lxnetwork instance.
---@return table
function M.network()
    return state.ensure("network", function()
        local instance = require("lxnetwork").new(module_config.options("network"))

        registry.register_widget("network", instance.widget, 20)
        register_single_popup("network", instance, "default", "primary", "_popup", function(service, popup_opts)
            service:toggle_popup(nil, popup_opts)
        end, function(service)
            service:close_popup()
        end)

        return instance
    end)
end

---Return the shared lxrunner instance.
---@return table
function M.runner()
    return state.ensure("runner", function()
        return require("lxrunner").new(runner_options())
    end)
end

---Return the shared lxpower instance.
---@return table
function M.power()
    return state.ensure("power", function()
        local instance = require("lxpower").new(module_config.options("power"))

        registry.register_widget("power", instance.widget, 30)
        register_single_popup("power", instance, "default", "secondary", "_popup", function(service, popup_opts)
            service:toggle_popup(nil, popup_opts)
        end, function(service)
            service:close_popup()
        end)

        return instance
    end)
end

---Build the standard set of long-lived services after theme initialization.
---@return table
function M.bootstrap()
    return {
        media = M.media(),
        notify = M.notify(),
        runner = M.runner(),
        bar = M.bar(),
        bluetooth = M.bluetooth(),
        display = M.display(),
        network = M.network(),
        power = M.power(),
    }
end

return M
