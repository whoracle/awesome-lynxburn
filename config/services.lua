local M = {}

local lxaudio_instance
local lxbar_instance
local lxbluetooth_instance
local lxdisplay_instance
local lxnetwork_instance
local lxnotify_instance
local lxpowerprofiles_instance
local lxrunner_instance

local function popup_cycle_keychains()
    local settings = require("config.settings")

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

local function register_lx_widget(id, widget, default_order)
    require("lxcommon.registry").register({
        id = id,
        widget = widget,
        default_order = default_order,
    })

    if lxbar_instance then
        lxbar_instance:refresh()
    end
end

local function register_popup_handle(module_id, popup_id, handle)
    require("lxcommon.popup_manager").register(module_id, popup_id, handle)
end

---Shared singleton accessors for the long-lived helper modules.
---
---Services are created lazily so theme initialization can complete before
---theme-driven widget options are read.
function M.audio()
    if not lxaudio_instance then
        lxaudio_instance = require("lxaudio").new({
            show_mic_activity = true,
            refresh_interval = 5,
            width = 50,
        })
        register_lx_widget("audio", lxaudio_instance.widget, 40)
        register_popup_handle("audio", "default", {
            open = function(opts)
                local popup_opts = popup_cycle_opts()
                popup_opts.hover_close = false
                popup_opts.placement = opts and opts.placement or nil
                lxaudio_instance:show_media_popup(nil, popup_opts)
            end,
            close = function()
                lxaudio_instance:close_popups()
            end,
            is_visible = function()
                return lxaudio_instance._media_popup and lxaudio_instance._media_popup.visible or false
            end,
        })
        register_popup_handle("audio", "devices", {
            open = function(opts)
                local popup_opts = popup_cycle_opts()
                popup_opts.hover_close = false
                popup_opts.placement = opts and opts.placement or nil
                lxaudio_instance:show_devices_popup(nil, popup_opts)
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
        lxbar_instance = require("lxbar").new()
    end

    lxbar_instance:refresh()
    return lxbar_instance
end

function M.bluetooth()
    local settings = require("config.settings")
    if settings.widgets and settings.widgets.bluetooth == false then
        return nil
    end

    if not lxbluetooth_instance then
        lxbluetooth_instance = require("lxbluetooth").new()
        register_lx_widget("bluetooth", lxbluetooth_instance.widget, 10)
        register_popup_handle("bluetooth", "default", {
            open = function()
                lxbluetooth_instance:toggle_popup(nil, popup_cycle_opts())
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
        lxnotify_instance = require("lxnotify").new({
            notification_denylist = {
                { app_name = "Volume OSD" },
                { app_name = "Mute Indicator" },
                { app_name = "Brightness OSD" },
                { app_name = "Notification Indicator" },
                { app_name = "Calendar" },
            },
        })
        register_lx_widget("notify", lxnotify_instance.widget, 50)
        register_popup_handle("notify", "default", {
            open = function()
                local popup_opts = popup_cycle_opts()
                popup_opts.hover_close = false
                lxnotify_instance:show_notification_popup(popup_opts)
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
        local programs = require("config.programs")
        lxdisplay_instance = require("lxdisplay").new({
            brightness = programs.brightness,
            redshift = programs.redshift,
        })
        register_lx_widget("display", lxdisplay_instance.widget, 60)
    end

    return lxdisplay_instance
end

function M.network()
    local settings = require("config.settings")
    if settings.widgets and settings.widgets.network == false then
        return nil
    end

    if not lxnetwork_instance then
        lxnetwork_instance = require("lxnetwork").new()
        register_lx_widget("network", lxnetwork_instance.widget, 20)
        register_popup_handle("network", "default", {
            open = function()
                lxnetwork_instance:toggle_popup(nil, popup_cycle_opts())
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
        lxrunner_instance = require("lxrunner").new()
    end

    return lxrunner_instance
end

function M.powerprofiles()
    local settings = require("config.settings")
    if settings.widgets and settings.widgets.powerprofiles == false then
        return nil
    end

    if not lxpowerprofiles_instance then
        lxpowerprofiles_instance = require("lxpowerprofiles").new()
        register_lx_widget("powerprofiles", lxpowerprofiles_instance.widget, 30)
        register_popup_handle("powerprofiles", "default", {
            open = function()
                lxpowerprofiles_instance:toggle_popup(nil, popup_cycle_opts())
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
