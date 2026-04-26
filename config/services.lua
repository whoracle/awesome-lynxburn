local beautiful = require("beautiful")
local gears = require("gears")
local naughty = require("naughty")
local wibox = require("wibox")

local M = {}

local module_config = require("config.lxmodules")
local registry = require("config.services.registry")
local state = require("config.services.state")

local function popup_visible(instance, field_name)
    if type(instance.popup_visible) == "function" then
        return instance:popup_visible(field_name)
    end

    return instance[field_name] and instance[field_name].visible or false
end

local function register_single_popup(module_id, instance, popup_id, popup_role, popup_field, open_fn, close_fn, opts)
    registry.register_semantic_popup(module_id, popup_id, popup_role, {
        hover_close = opts and opts.hover_close,
        shared_shell = opts and opts.shared_shell,
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
    options.service_refresh = M.refresh

    return options
end

local function wrap_custom_bar_widget(widget)
    if not widget then
        return nil
    end

    local margin = wibox.container.margin(widget)
    margin.left = beautiful.widget_padding_left or 0
    margin.top = beautiful.widget_padding_top or 0
    margin.bottom = beautiful.widget_padding_bottom or 0
    margin.right = beautiful.widget_padding_right or 0
    margin.draw_empty = false

    local background = wibox.container.background(margin)
    background.bg = beautiful.tasklist_bg_normal or beautiful.bg_normal
    background.shape = gears.shape.rectangle
    background.shape_clip = true

    return background
end

local function notify_custom_widget_failure(name, err)
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Custom lxbar widget failed",
        text = string.format("Widget: %s\nError: %s", tostring(name), tostring(err)),
    })
end

local function normalize_custom_widget_spec(name, custom_widget)
    local context = {
        beautiful = beautiful,
        gears = gears,
        services = M,
        state = state,
        wibox = wibox,
    }
    local resolved = custom_widget

    if type(custom_widget) == "function" then
        resolved = custom_widget(context)
    end

    if type(resolved) ~= "table" then
        return nil
    end

    if resolved.widget then
        if resolved.style == nil then
            resolved.style = "lxbar"
        end
        return resolved
    end

    return {
        widget = resolved,
        style = "lxbar",
    }
end

local function register_custom_widgets()
    for name, custom_widget in pairs(module_config.custom_widgets()) do
        local ok, spec_or_err = pcall(normalize_custom_widget_spec, name, custom_widget)

        if not ok then
            notify_custom_widget_failure(name, spec_or_err)
        else
            local spec = spec_or_err

            if spec and spec.widget then
                local widget = spec.widget
                local wrap_ok, wrapped_or_err = pcall(function()
                    if spec.style ~= "raw" then
                        widget = wrap_custom_bar_widget(widget)
                    end

                    if spec.width then
                        widget = wibox.container.constraint(widget, "exact", spec.width)
                    end

                    registry.register_widget("custom:" .. tostring(name), widget, spec.default_order or 1000, {
                        include_in_popup_cycle = false,
                    })
                end)

                if not wrap_ok then
                    notify_custom_widget_failure(name, wrapped_or_err)
                end
            end
        end
    end
end

local function normalize_service_id(id)
    if type(id) ~= "string" or id == "" then
        return nil
    end

    return id:gsub("^lx", "")
end

local function refresh_instance(instance)
    if not instance then
        return false
    end

    if type(instance.refresh) == "function" then
        instance:refresh()
        return true
    end

    if type(instance.refresh_all) == "function" then
        instance:refresh_all()
        return true
    end

    if type(instance.brightness_refresh) == "function" then
        instance:brightness_refresh({ show_osd = false })
        return true
    end

    if type(instance.reload) == "function" then
        instance:reload()
        return true
    end

    return false
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
        register_custom_widgets()
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
        end, {
            shared_shell = true,
        })

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
            end, {
                shared_shell = true,
            })
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
        end, {
            shared_shell = true,
        })

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

---Request an immediate refresh for one long-lived lx service.
---@param id string
---@return boolean
function M.refresh(id)
    local service_id = normalize_service_id(id)
    if not service_id then
        return false
    end

    local instance = state.get(service_id)
    if not instance then
        return false
    end

    return refresh_instance(instance)
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
        end, {
            shared_shell = true,
        })

        return instance
    end)
end

---Return the shared lxsecrets instance.
---@return table
function M.secrets()
    return state.ensure("secrets", function()
        local options = module_config.options("secrets")
        local instance = require("lxsecrets").new(options)

        registry.register_widget("secrets", instance.widget, 15, {
            include_in_popup_cycle = options.cycle_exclude ~= true,
        })
        register_single_popup("secrets", instance, "default", "primary", "_popup", function(service, popup_opts)
            service:toggle_popup(nil, popup_opts)
        end, function(service)
            service:close_popup()
        end, {
            shared_shell = true,
        })

        return instance
    end)
end

---Build the standard set of long-lived services after theme initialization.
---@return table
function M.bootstrap()
    return {
        secrets = M.secrets(),
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
