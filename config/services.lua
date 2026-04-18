local M = {}
local widget_config = require("config.widgets")
local config_data = require("config.config_data")

local lxaudio_instance
local lxbar_instance
local lxbluetooth_instance
local lxdisplay_instance
local lxnetwork_instance
local lxnotify_instance
local lxpowerprofiles_instance
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
    require("lxcommon.registry").set_order(widget_config.order())
end

local function register_lx_widget(id, widget, default_order, opts)
    opts = opts or {}
    local include_in_popup_cycle = widget_config.cycle_enabled(id, opts.include_in_popup_cycle)

    require("lxcommon.registry").register({
        id = id,
        widget = widget,
        default_order = default_order,
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
function M.audio()
    if not lxaudio_instance then
        lxaudio_instance = require("lxaudio").new(widget_config.options("audio"))
        register_lx_widget("audio", lxaudio_instance.widget, 40)
        register_semantic_popup("audio", "default", "primary", {
            hover_close = false,
            open = function(opts)
                lxaudio_instance:show_media_popup(nil, opts)
            end,
            close = function()
                lxaudio_instance:close_popups()
            end,
            is_visible = function()
                return lxaudio_instance._media_popup and lxaudio_instance._media_popup.visible or false
            end,
        })
        register_semantic_popup("audio", "devices", "secondary", {
            hover_close = false,
            open = function(opts)
                lxaudio_instance:show_devices_popup(nil, opts)
            end,
            close = function()
                lxaudio_instance:close_popups()
            end,
            is_visible = function()
                return lxaudio_instance._devices_popup and lxaudio_instance._devices_popup.visible or false
            end,
        })
    end

    return lxaudio_instance
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
    if not widget_config.enabled("bluetooth", true) then
        return nil
    end

    if not lxbluetooth_instance then
        lxbluetooth_instance = require("lxbluetooth").new(widget_config.options("bluetooth"))
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
        lxnotify_instance = require("lxnotify").new(widget_config.options("notify"))
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
        local programs = config_data.commands()
        lxdisplay_instance = require("lxdisplay").new({
            brightness = programs.brightness,
            redshift = programs.redshift,
        })
        register_lx_widget("display", lxdisplay_instance.widget, 60)
    end

    return lxdisplay_instance
end

function M.network()
    if not widget_config.enabled("network", true) then
        return nil
    end

    if not lxnetwork_instance then
        lxnetwork_instance = require("lxnetwork").new(widget_config.options("network"))
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
        local lxmodules = config_data.lxmodules()
        local runner_config = lxmodules.lxrunner or {}
        lxrunner_instance = require("lxrunner").new(runner_config.options or {})
    end

    return lxrunner_instance
end

function M.powerprofiles()
    if not widget_config.enabled("powerprofiles", true) then
        return nil
    end

    if not lxpowerprofiles_instance then
        lxpowerprofiles_instance = require("lxpowerprofiles").new(widget_config.options("powerprofiles"))
        register_lx_widget("powerprofiles", lxpowerprofiles_instance.widget, 30)
        register_semantic_popup("powerprofiles", "default", "secondary", {
            open = function(opts)
                lxpowerprofiles_instance:toggle_popup(nil, opts)
            end,
            close = function()
                lxpowerprofiles_instance:close_popup()
            end,
            is_visible = function()
                return lxpowerprofiles_instance._popup and lxpowerprofiles_instance._popup.visible or false
            end,
        })
    end

    return lxpowerprofiles_instance
end

return M
