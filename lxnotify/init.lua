local gears = require("gears")
local naughty = require("naughty")
local controller = require("lxnotify.controller")
local popup_state = require("lxnotify.popup_state")
local store = require("lxnotify.store")
local theme = require("lxnotify.theme")
local widget = require("lxnotify.widget")

local lxnotify = {}
local instance_methods = {}

theme.extend(instance_methods)
store.extend(instance_methods)
popup_state.extend(instance_methods)
controller.extend(instance_methods)

---Create a new lxnotify instance with widget, popup controller, and interception hooks.
---@param opts table|nil
---@return table
function lxnotify.new(opts)
    opts = opts or {}

    local instance = setmetatable({
        unread_count = 0,
        suspended = naughty.suspended and true or false,
        interception_paused = opts.interception_paused == true,
        active_group_key = nil,
        popup_title = "Notifications",
        popup_footer_text = nil,
        popup_scroll_offset = 1,
        popup_selected_index = 1,
        popup_total_items = 0,
        notifications = {},
        _next_notification_id = 0,
        debug_notifications = opts.debug_notifications == true,
        notification_denylist = opts.notification_denylist or {},
        notification_title_limit = opts.notification_title_max_length,
        notification_body_limit = opts.notification_body_max_length,
        notification_source_limit = opts.notification_source_max_length,
        notification_time_format_string = opts.notification_time_format,
        popup_visible_item_count = opts.popup_visible_items,
    }, {
        __index = instance_methods,
    })

    instance._widget_refs = widget.new(instance)
    instance.widget = instance._widget_refs.root
    instance:_attach_notification_listener()
    instance:refresh()

    -- Startup ordering can leave theme keys unavailable for the first render.
    -- Refresh again on the next loop tick so the initial glyph matches later updates.
    gears.timer.delayed_call(function()
        instance:refresh()
    end)

    return instance
end

return lxnotify
