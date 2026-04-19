local gears = require("gears")
local naughty = require("naughty")

local actions = require("lxnotify.actions")
local debug = require("lxnotify.debug")
local format = require("lxnotify.format")

local store = {}

local ENTRY_SIGNAL_PROPERTIES = {
    "title",
    "message",
    "text",
    "app_name",
    "category",
    "urgency",
    "icon",
    "app_icon",
    "image",
    "images",
}

local function supports_notification_signal()
    return type(naughty.connect_signal) == "function"
end

---Reset popup-local browsing state after the notification structure changes.
function store.reset_popup_view(self)
    self.active_group_key = nil
    self.popup_scroll_offset = 1
    self.popup_selected_index = 1
end

---Attach notification-store methods to the lxnotify instance method table.
function store.extend(instance_methods)
    function instance_methods:toggle_daemon_pause()
        naughty.suspended = not naughty.suspended
        self.suspended = naughty.suspended
        self:refresh()
    end

    function instance_methods:toggle_suspend()
        self:toggle_daemon_pause()
    end

    function instance_methods:toggle_interception_pause()
        self.interception_paused = not self.interception_paused
        self:refresh()
    end

    function instance_methods:should_destroy_on_dismiss()
        return not self.suspended
    end

    function instance_methods:dismiss_all()
        if self:should_destroy_on_dismiss() then
            for _, entry in ipairs(self.notifications) do
                actions.destroy(entry.notification)
            end
        end

        self.notifications = {}
        self.unread_count = 0
        store.reset_popup_view(self)
        self:refresh()
    end

    function instance_methods:dismiss_notification(notification_id)
        local kept = {}

        for _, entry in ipairs(self.notifications) do
            if entry.id ~= notification_id then
                kept[#kept + 1] = entry
            end
        end

        self.notifications = kept
        self.unread_count = #self.notifications

        if self.active_group_key then
            local still_present = false
            for _, entry in ipairs(self.notifications) do
                if format.group_key(entry) == self.active_group_key then
                    still_present = true
                    break
                end
            end

            if not still_present then
                store.reset_popup_view(self)
            end
        end

        self:refresh()
    end

    function instance_methods:dismiss_group(group_key)
        if not group_key or group_key == "" then
            return
        end

        local kept = {}

        for _, entry in ipairs(self.notifications) do
            if format.group_key(entry) == group_key then
                if self:should_destroy_on_dismiss() then
                    actions.destroy(entry.notification)
                end
            else
                kept[#kept + 1] = entry
            end
        end

        self.notifications = kept
        self.unread_count = #self.notifications

        if self.active_group_key == group_key then
            store.reset_popup_view(self)
        end

        self:refresh()
    end

    function instance_methods:find_notification_entry(notification)
        if not notification then
            return nil
        end

        for _, entry in ipairs(self.notifications) do
            if entry.notification == notification then
                return entry
            end

            if notification.id and entry.notification and entry.notification.id == notification.id then
                return entry
            end
        end

        return nil
    end

    function instance_methods:_remove_entry_object(target_entry)
        if not target_entry then
            return
        end

        local kept = {}
        for _, entry in ipairs(self.notifications) do
            if entry ~= target_entry then
                kept[#kept + 1] = entry
            end
        end

        self.notifications = kept
        self.unread_count = #self.notifications
    end

    function instance_methods:remove_notification(notification)
        local entry = self:find_notification_entry(notification)
        if not entry then
            return
        end

        self:_remove_entry_object(entry)
        self:refresh()
    end

    function instance_methods:update_notification_entry(entry)
        if not entry or not entry.notification then
            return
        end

        if self:should_ignore_notification(entry.notification) then
            self:_remove_entry_object(entry)
            self:refresh()
            return
        end

        local summary = format.summary(self, entry.notification, entry.created_at)
        entry.title = summary.title
        entry.body = summary.body
        entry.source = summary.source
        entry.category = summary.category
        entry.icon = summary.icon
        entry.urgency = summary.urgency
        entry.updated_at = os.date(self:notification_time_format())
        self:refresh()
    end

    function instance_methods:_attach_entry_signals(entry)
        if not entry or not entry.notification or entry._signals_attached then
            return
        end

        entry._signals_attached = true
        entry._signal_callbacks = {}

        for _, property in ipairs(ENTRY_SIGNAL_PROPERTIES) do
            local signal = "property::" .. property
            -- Keep the retained inbox synchronized when naughty mutates a
            -- visible notification after it was first captured.
            local callback = function()
                self:update_notification_entry(entry)
            end
            entry._signal_callbacks[signal] = callback
            entry.notification:connect_signal(signal, callback)
        end
    end

    function instance_methods:push_notification(notification)
        local existing_entry = self:find_notification_entry(notification)
        if existing_entry then
            if existing_entry.notification ~= notification then
                existing_entry.notification = notification
                existing_entry._signals_attached = false
                existing_entry._signal_callbacks = nil
                self:_attach_entry_signals(existing_entry)
            end

            existing_entry.notification = notification
            self:update_notification_entry(existing_entry)
            return
        end

        self._next_notification_id = self._next_notification_id + 1

        local summary = format.summary(self, notification)
        local entry = {
            id = self._next_notification_id,
            notification = notification,
            title = summary.title,
            body = summary.body,
            source = summary.source,
            category = summary.category,
            icon = summary.icon,
            urgency = summary.urgency,
            created_at = summary.created_at,
            updated_at = nil,
        }

        self.notifications[#self.notifications + 1] = entry
        self:_attach_entry_signals(entry)

        self.unread_count = #self.notifications
        self:refresh()
    end

    function instance_methods:debug_notification(notification)
        if not self.debug_notifications then
            return
        end

        local snapshot = debug.snapshot(notification)
        gears.debug.print_warning("lxnotify notification: " .. debug.format_snapshot(snapshot))
    end

    function instance_methods:should_ignore_notification(notification)
        if not self.notification_denylist or #self.notification_denylist == 0 then
            return false
        end

        local snapshot = debug.snapshot(notification)

        for _, rule in ipairs(self.notification_denylist) do
            if debug.rule_matches_snapshot(rule, snapshot) then
                if self.debug_notifications then
                    gears.debug.print_warning("lxnotify notification denied: " .. debug.format_snapshot(snapshot))
                end
                return true
            end
        end

        return false
    end

    ---Subscribe the lxnotify instance to naughty's global notification signals.
    function instance_methods:_attach_notification_listener()
        if not supports_notification_signal() then
            return
        end

        self._notification_signal = function(notification)
            self:debug_notification(notification)

            if self.interception_paused then
                return
            end

            if self:should_ignore_notification(notification) then
                return
            end

            self:push_notification(notification)
        end

        naughty.connect_signal("new", self._notification_signal)

        self._suspended_signal = function()
            self.suspended = naughty.suspended and true or false
            self:refresh()
        end

        naughty.connect_signal("property::suspended", self._suspended_signal)
    end
end

return store
