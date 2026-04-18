local M = {}
local module_config = require("config.lxmodules")
local config_data = require("config.config_data")

local lxmedia_instance
local lxbar_instance
local lxbluetooth_instance
local lxdisplay_instance
local lxnetwork_instance
local lxnotify_instance
local lxpower_instance
local lxrunner_instance

local function popup_cycle_keychains()
    local settings = config_data.settings()

    return {
        prev = {
            modifiers = { settings.modkey, settings.altkey, settings.ctrlkey },
            key = "Left",
        },
        next = {
            modifiers = { settings.modkey, settings.altkey, settings.ctrlkey },
            key = "Right",
        },
    }
end

local function popup_cycle_opts()
    local keychains = popup_cycle_keychains()

    return {
        keyboard_navigation = true,
        width = 360,
        prev_keychain = keychains.prev,
        next_keychain = keychains.next,
        on_cycle_prev = function()
            if lxbar_instance then
                lxbar_instance:cycle_popups(-1, popup_cycle_opts())
            end
        end,
        on_cycle_next = function()
            if lxbar_instance then
                lxbar_instance:cycle_popups(1, popup_cycle_opts())
            end
        end,
    }
end

local function merge_popup_opts(defaults, overrides)
    local merged = {}

    for key, value in pairs(defaults or {}) do
        merged[key] = value
    end

    for key, value in pairs(overrides or {}) do
        merged[key] = value
    end

    return merged
end

local function configure_widget_registry()
    require("lxcommon.registry").set_order(module_config.order())
end

local function register_lx_widget(id, widget, default_order, opts)
    opts = opts or {}
    local include_in_popup_cycle = module_config.cycle_enabled(id, opts.include_in_popup_cycle)

    require("lxcommon.registry").register({
        id = id,
        widget = widget,
        default_order = default_order,
        enabled = function()
            return module_config.enabled(id, false)
        end,
        include_in_popup_cycle = include_in_popup_cycle,
    })

    if lxbar_instance then
        lxbar_instance:refresh()
    end
end

local function register_popup_handle(module_id, popup_id, handle, opts)
    require("lxcommon.popup_manager").register(module_id, popup_id, handle, opts)
end

local function build_popup_handle(spec)
    return {
        open = function(opts)
            local popup_opts = merge_popup_opts(popup_cycle_opts(), opts)

            if spec.hover_close ~= nil then
                popup_opts.hover_close = spec.hover_close
            end

            spec.open(popup_opts)
        end,
        close = spec.close,
        is_visible = spec.is_visible,
    }
end

local function register_semantic_popup(module_id, popup_id, popup_role, spec)
    register_popup_handle(module_id, popup_id, build_popup_handle(spec), {
        popup_role = popup_role,
    })
end

---Shared singleton accessors for the long-lived helper modules.
---
---Services are created lazily so theme initialization can complete before
---theme-driven widget options are read.
function M.media()
    if not lxmedia_instance then
        lxmedia_instance = require("lxmedia").new(module_config.options("media"))
        register_lx_widget("media", lxmedia_instance.widget, 40)
        register_semantic_popup("media", "default", "primary", {
            hover_close = false,
            open = function(opts)
                lxmedia_instance:show_media_popup(nil, opts)
            end,
            close = function()
                lxmedia_instance:close_popups()
            end,
            is_visible = function()
                return lxmedia_instance._media_popup and lxmedia_instance._media_popup.visible or false
            end,
        })
        register_semantic_popup("media", "devices", "secondary", {
            hover_close = false,
            open = function(opts)
                lxmedia_instance:show_devices_popup(nil, opts)
            end,
            close = function()
                lxmedia_instance:close_popups()
            end,
            is_visible = function()
                return lxmedia_instance._devices_popup and lxmedia_instance._devices_popup.visible or false
            end,
        })
    end

    return lxmedia_instance
end

function M.bar()
    if not lxbar_instance then
        configure_widget_registry()
        lxbar_instance = require("lxbar").new()
    end

    lxbar_instance:refresh()
    return lxbar_instance
end

function M.bluetooth()
    if not lxbluetooth_instance then
        lxbluetooth_instance = require("lxbluetooth").new(module_config.options("bluetooth"))
        register_lx_widget("bluetooth", lxbluetooth_instance.widget, 10)
        register_semantic_popup("bluetooth", "default", "primary", {
            open = function(opts)
                lxbluetooth_instance:toggle_popup(nil, opts)
            end,
            close = function()
                lxbluetooth_instance:close_popup()
            end,
            is_visible = function()
                return lxbluetooth_instance._popup and lxbluetooth_instance._popup.visible or false
            end,
        })
    end

    return lxbluetooth_instance
end

---Return the shared lxnotify instance.
---@return table
function M.notify()
    if not lxnotify_instance then
        lxnotify_instance = require("lxnotify").new(module_config.options("notify"))
        register_lx_widget("notify", lxnotify_instance.widget, 50)
        register_semantic_popup("notify", "default", "primary", {
            hover_close = false,
            open = function(opts)
                lxnotify_instance:show_notification_popup(opts)
            end,
            close = function()
                lxnotify_instance:close_popups()
            end,
            is_visible = function()
                return lxnotify_instance._popup and lxnotify_instance._popup.visible or false
            end,
        })
    end

    return lxnotify_instance
end

---Return the shared lxdisplay instance.
---@return table
function M.display()
    if not lxdisplay_instance then
        lxdisplay_instance = require("lxdisplay").new(module_config.options("display"))
        register_lx_widget("display", lxdisplay_instance.widget, 60)
    end

    return lxdisplay_instance
end

function M.network()
    if not lxnetwork_instance then
        lxnetwork_instance = require("lxnetwork").new(module_config.options("network"))
        register_lx_widget("network", lxnetwork_instance.widget, 20)
        register_semantic_popup("network", "default", "primary", {
            open = function(opts)
                lxnetwork_instance:toggle_popup(nil, opts)
            end,
            close = function()
                lxnetwork_instance:close_popup()
            end,
            is_visible = function()
                return lxnetwork_instance._popup and lxnetwork_instance._popup.visible or false
            end,
        })
    end

    return lxnetwork_instance
end

---Return the shared lxrunner instance.
---@return table
function M.runner()
    if not lxrunner_instance then
        local runner_options = module_config.options("runner")
        runner_options.aliases = nil
        lxrunner_instance = require("lxrunner").new(runner_options)
    end

    return lxrunner_instance
end

function M.power()
    if not lxpower_instance then
        lxpower_instance = require("lxpower").new(module_config.options("power"))
        register_lx_widget("power", lxpower_instance.widget, 30)
        register_semantic_popup("power", "default", "secondary", {
            open = function(opts)
                lxpower_instance:toggle_popup(nil, opts)
            end,
            close = function()
                lxpower_instance:close_popup()
            end,
            is_visible = function()
                return lxpower_instance._popup and lxpower_instance._popup.visible or false
            end,
        })
    end

    return lxpower_instance
end

return M
