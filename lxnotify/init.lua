local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local naughty = require("naughty")
local keygrabber = require("awful.keygrabber")

local popup_control = require("lxcommon.popup_control")
local widget_feedback = require("lxcommon.widget_feedback")
local actions = require("lxnotify.actions")
local cards = require("lxnotify.cards")
local debug = require("lxnotify.debug")
local format = require("lxnotify.format")
local popup = require("lxnotify.popup")
local util = require("lxnotify.util")
local widget = require("lxnotify.widget")
local unpack = table.unpack or unpack

local lxnotify = {}
local instance_methods = {}

local POPUP_TITLES = {
    notifications = "Notifications",
    grouped_notifications = "Grouped Notifications",
}

local IGNORED_POPUP_MODIFIERS = {
    Lock = true,
    Mod2 = true,
    Mod3 = true,
    Mod5 = true,
}

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

local function current_target_screen_context()
    if mouse and mouse.current_widget_geometry then
        local geometry = mouse.current_widget_geometry
        if geometry then
            return geometry
        end
    end

    return { screen = awful.screen.focused() }
end

---Group stored entries into the burst-group structure used by the popup.
---@param notifications table[]
---@return table, table[]
local function build_groups(notifications)
    local grouped = {}
    local ordered = {}

    for _, entry in ipairs(notifications) do
        local key = format.group_key(entry)
        local group = grouped[key]

        if not group then
            group = {
                key = key,
                created_at = entry.created_at,
                entries = {},
            }
            grouped[key] = group
            ordered[#ordered + 1] = group
        end

        group.entries[#group.entries + 1] = entry
    end

    return grouped, ordered
end

---Reset popup-local view state after a structural change.
---@param self table
local function reset_popup_view(self)
    self.active_group_key = nil
    self.popup_scroll_offset = 1
    self.popup_selected_index = 1
end

function instance_methods:popup_width()
    return util.theme_value("lxnotify_popup_width", 360)
end

function instance_methods:popup_placement()
    return require("lxcommon.popup_placement").normalize(
        util.theme_value("lxnotify_popup_placement", "side"),
        "side"
    )
end

function instance_methods:popup_bg()
    return util.theme_value("lxnotify_popup_bg", beautiful.bg_normal or "#333333")
end

function instance_methods:notification_card_bg()
    return util.theme_value("lxnotify_notification_card_bg", beautiful.bg_minimize or "#222222")
end

function instance_methods:notification_meta_fg()
    return util.theme_value("lxnotify_notification_meta_fg", beautiful.fg_minimize or beautiful.fg_normal or "#999999")
end

function instance_methods:notification_hover_bg()
    return util.theme_value("lxnotify_bg_hover", beautiful.bg_focus or beautiful.bg_minimize or "#333333")
end

function instance_methods:notification_selected_bg()
    return util.theme_value(
        "lxnotify_selected_bg",
        util.theme_value("lxnotify_selected_border", beautiful.border_focus or beautiful.fg_focus or beautiful.fg_normal or "#ffffff")
    )
end

function instance_methods:button_bg()
    return util.theme_value("lxnotify_button_bg", beautiful.bg_minimize or "#222222")
end

function instance_methods:button_hover_bg()
    return util.theme_value("lxnotify_button_hover", beautiful.bg_focus or beautiful.bg_minimize or "#333333")
end

function instance_methods:hover_close_timeout()
    return util.theme_value("lxnotify_hover_close_timeout", 1.5)
end

function instance_methods:hover_close_poll_interval()
    return util.theme_value("lxnotify_hover_close_poll_interval", 0.25)
end

function instance_methods:notification_title_max_length()
    if self.notification_title_limit ~= nil then
        return self.notification_title_limit
    end

    return util.theme_value("lxnotify_notification_title_max_length", 72)
end

function instance_methods:notification_body_max_length()
    if self.notification_body_limit ~= nil then
        return self.notification_body_limit
    end

    return util.theme_value("lxnotify_notification_body_max_length", 140)
end

function instance_methods:notification_source_max_length()
    if self.notification_source_limit ~= nil then
        return self.notification_source_limit
    end

    return util.theme_value("lxnotify_notification_source_max_length", 28)
end

function instance_methods:notification_time_format()
    if self.notification_time_format_string ~= nil then
        return self.notification_time_format_string
    end

    return util.theme_value("lxnotify_notification_time_format", "%H:%M")
end

function instance_methods:notification_icon_size()
    return util.theme_value("lxnotify_notification_icon_size", beautiful.notification_icon_size or 32)
end

function instance_methods:notification_group_icon_size()
    return util.theme_value("lxnotify_group_icon_size", beautiful.notification_icon_size or 20)
end

function instance_methods:popup_visible_items()
    if self.popup_visible_item_count ~= nil then
        return self.popup_visible_item_count
    end

    return util.theme_value("lxnotify_popup_visible_items", 7)
end

function instance_methods:_widget_text()
    local icon = self.suspended
        and util.theme_value("lxnotify_icon_suspended", "off")
        or util.theme_value("lxnotify_icon_idle", "idle")
    local fg

    if self.unread_count > 0 then
        fg = util.theme_value("lxnotify_urgency_critical_fg", beautiful.fg_urgent or "#d97777")
    elseif self.interception_paused then
        fg = util.theme_value("lxnotify_widget_suspended_fg", beautiful.fg_minimize or beautiful.fg_normal or "#888888")
    else
        fg = util.theme_value("lxnotify_widget_fg", beautiful.fg_normal or "#ffffff")
    end

    return string.format("<span foreground='%s'>%s</span>", fg, icon)
end

---Refresh the compact wibar widget and, if present, the popup contents.
function instance_methods:refresh()
    self._widget_refs.text.markup = self:_widget_text()
    self:refresh_popup()
end

---Refresh state and re-apply popup geometry if the popup is currently visible.
function instance_methods:reload()
    self:refresh()

    if self._popup and self._popup.visible then
        popup.show(self, { screen = self._popup.screen or awful.screen.focused() })
    end
end

---Toggle `naughty.suspended` while continuing to capture notifications.
function instance_methods:toggle_daemon_pause()
    naughty.suspended = not naughty.suspended
    self.suspended = naughty.suspended
    self:refresh()
end

function instance_methods:toggle_suspend()
    self:toggle_daemon_pause()
end

---Pause or resume interception of new notifications into lxnotify.
function instance_methods:toggle_interception_pause()
    self.interception_paused = not self.interception_paused
    self:refresh()
end

function instance_methods:should_destroy_on_dismiss()
    return not self.suspended
end

---Dismiss all stored notifications and reset any active detail view.
function instance_methods:dismiss_all()
    if self:should_destroy_on_dismiss() then
        for _, entry in ipairs(self.notifications) do
            actions.destroy(entry.notification)
        end
    end

    self.notifications = {}
    self.unread_count = 0
    reset_popup_view(self)
    self:refresh()
end

---Dismiss one stored notification by its internal entry id.
---@param notification_id integer
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
            reset_popup_view(self)
        end
    end

    self:refresh()
end

---Dismiss every stored notification belonging to one burst group.
---@param group_key string
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
        reset_popup_view(self)
    end

    self:refresh()
end

---Find the stored entry corresponding to a live naughty notification object.
---@param notification table|nil
---@return table|nil
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

---Remove one stored entry object without triggering a refresh.
---@param target_entry table|nil
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

---Remove a stored notification by matching its live naughty object.
---@param notification table
function instance_methods:remove_notification(notification)
    local entry = self:find_notification_entry(notification)
    if not entry then
        return
    end

    self:_remove_entry_object(entry)
    self:refresh()
end

---Update the stored summary for one notification entry after a property change.
---@param entry table
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

---Subscribe a stored entry to live notification property updates.
---@param entry table
function instance_methods:_attach_entry_signals(entry)
    if not entry or not entry.notification or entry._signals_attached then
        return
    end

    entry._signals_attached = true
    entry._signal_callbacks = {}

    for _, property in ipairs(ENTRY_SIGNAL_PROPERTIES) do
        local signal = "property::" .. property
        local callback = function()
            self:update_notification_entry(entry)
        end
        entry._signal_callbacks[signal] = callback
        entry.notification:connect_signal(signal, callback)
    end
end

---Store a newly intercepted notification or merge it into an existing entry.
---@param notification table
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

---Log the normalized notification snapshot when debugging is enabled.
---@param notification table
function instance_methods:debug_notification(notification)
    if not self.debug_notifications then
        return
    end

    local snapshot = debug.snapshot(notification)
    gears.debug.print_warning("lxnotify notification: " .. debug.format_snapshot(snapshot))
end

---Return true when the notification matches any configured denylist rule.
---@param notification table
---@return boolean
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

---Open the dedicated detail view for a grouped burst.
---@param group_key string
function instance_methods:enter_group_detail(group_key)
    self.active_group_key = group_key
    self.popup_scroll_offset = 1
    self:refresh_popup()
end

---Return from a grouped detail view to the main inbox listing.
function instance_methods:leave_group_detail()
    if not self.active_group_key then
        return
    end

    reset_popup_view(self)
    self:refresh_popup()
end

---Dismiss every notification in the currently active grouped detail view.
function instance_methods:dismiss_active_group()
    if not self.active_group_key then
        return
    end

    local kept = {}
    for _, entry in ipairs(self.notifications) do
        if format.group_key(entry) == self.active_group_key then
            actions.destroy(entry.notification)
        else
            kept[#kept + 1] = entry
        end
    end

    self.notifications = kept
    self.unread_count = #self.notifications
    reset_popup_view(self)
    self:refresh()
end

function instance_methods:_ensure_popup_selection()
    local total_items = self.popup_total_items or 0

    if total_items <= 0 then
        self.popup_selected_index = 1
        return
    end

    self.popup_selected_index = math.max(1, math.min(self.popup_selected_index or 1, total_items))
end

function instance_methods:_ensure_selected_item_visible()
    local total_items = self.popup_total_items or 0
    if total_items <= 0 then
        self.popup_scroll_offset = 1
        return
    end

    local visible_items = math.max(1, self:popup_visible_items() or 1)
    local selected_index = math.max(1, math.min(self.popup_selected_index or 1, total_items))
    local max_offset = math.max(1, total_items - visible_items + 1)
    local scroll_offset = math.max(1, math.min(self.popup_scroll_offset or 1, max_offset))

    if selected_index < scroll_offset then
        scroll_offset = selected_index
    elseif selected_index >= scroll_offset + visible_items then
        scroll_offset = selected_index - visible_items + 1
    end

    self.popup_scroll_offset = math.max(1, math.min(scroll_offset, max_offset))
end

function instance_methods:selected_popup_item()
    if not self._popup_items or #self._popup_items == 0 then
        return nil
    end

    self:_ensure_popup_selection()
    return self._popup_items[self.popup_selected_index]
end

function instance_methods:move_popup_selection(delta)
    local total_items = self.popup_total_items or 0
    if total_items <= 0 then
        return
    end

    local next_index = math.max(1, math.min(total_items, (self.popup_selected_index or 1) + delta))
    if next_index == self.popup_selected_index then
        return
    end

    self.popup_selected_index = next_index
    self:_ensure_selected_item_visible()
    self:refresh_popup()
end

function instance_methods:activate_selected_popup_right()
    local item = self:selected_popup_item()
    if not item then
        return
    end

    if item.kind == "group" then
        self:enter_group_detail(item.group.key)
        return
    end

    if item.entry and item.entry.id then
        self:dismiss_notification(item.entry.id)
        return
    end

    if type(item.on_space) == "function" then
        item.on_space()
    end
end

function instance_methods:activate_selected_popup_enter()
    local item = self:selected_popup_item()
    if not item then
        return
    end

    if item.kind == "group" then
        self:enter_group_detail(item.group.key)
        return
    end

    if item.entry and item.entry.notification then
        if actions.invoke(item.entry.notification) then
            self:dismiss_notification(item.entry.id)
        end
        return
    end

    if type(item.on_enter) == "function" then
        item.on_enter()
    elseif type(item.on_space) == "function" then
        item.on_space()
    end
end

---Move the popup viewport by one or more stored cards.
---@param delta integer
function instance_methods:scroll_popup(delta)
    local total_items = self.popup_total_items or 0
    local visible_items = math.max(1, self:popup_visible_items() or 1)
    local max_offset = math.max(1, total_items - visible_items + 1)
    local next_offset = math.max(1, math.min(max_offset, (self.popup_scroll_offset or 1) + delta))

    if next_offset == self.popup_scroll_offset then
        return
    end

    self.popup_scroll_offset = next_offset
    self:_ensure_popup_selection()

    if self.popup_selected_index < next_offset then
        self.popup_selected_index = next_offset
    elseif self.popup_selected_index >= next_offset + visible_items then
        self.popup_selected_index = next_offset + visible_items - 1
    end

    self:refresh_popup()
end

function instance_methods:_handle_popup_keygrabber(_, modifiers, key, event)
    local handled = popup_control.dispatch_popup_keypress({
        event = event,
        modifiers = modifiers,
        key = key,
        ignored_modifiers = IGNORED_POPUP_MODIFIERS,
        is_open = function()
            return self._popup and self._popup.visible or false
        end,
        on_not_open = function()
            self:blur_popup_keyboard_navigation()
        end,
        prev_keychain = self._popup_prev_keychain,
        next_keychain = self._popup_next_keychain,
        toggle_key = self._popup_toggle_key,
        on_cycle_prev = self._popup_on_cycle_prev,
        on_cycle_next = self._popup_on_cycle_next,
        on_close = function()
            self:close_popups()
        end,
        actions = {
            Up = function()
                self:move_popup_selection(-1)
            end,
            Down = function()
                self:move_popup_selection(1)
            end,
            Right = function()
                self:activate_selected_popup_right()
            end,
            Return = function()
                self:activate_selected_popup_enter()
            end,
            KP_Enter = function()
                self:activate_selected_popup_enter()
            end,
            Left = function()
                if self.active_group_key then
                    self:leave_group_detail()
                else
                    self:close_popups()
                end
            end,
        },
    })

    if handled then
        return
    end
end

function instance_methods:focus_popup_keyboard_navigation()
    popup_control.focus_popup_keygrabber(self, {
        handler = function(grabber, modifiers, key, event)
            self:_handle_popup_keygrabber(grabber, modifiers, key, event)
        end,
        on_start = function()
            self:_start_popup_outside_click_dismiss()
        end,
    })
end

function instance_methods:set_popup_toggle_key(toggle_key)
    self._popup_toggle_key = popup_control.normalize_popup_toggle_key(toggle_key, {
        ignored_modifiers = IGNORED_POPUP_MODIFIERS,
    })
end

function instance_methods:blur_popup_keyboard_navigation()
    self._popup_keyboard_navigation_active = false
    self._popup_prev_keychain = nil
    self._popup_next_keychain = nil
    self._popup_on_cycle_prev = nil
    self._popup_on_cycle_next = nil
    self:_stop_popup_outside_click_dismiss()
    popup_control.blur_popup_keygrabber(self)
end

function instance_methods:_start_popup_outside_click_dismiss()
    popup_control.start_outside_click_dismiss(self, {
        is_open = function()
            return self._popup and self._popup.visible or false
        end,
        geometry_providers = {
            function()
                return self._popup and self._popup:geometry() or nil
            end,
        },
        on_outside_click = function()
            self:close_popups()
        end,
    })
end

function instance_methods:_stop_popup_outside_click_dismiss()
    popup_control.stop_outside_click_dismiss(self)
end

function instance_methods:_apply_popup_keyboard_opts(opts)
    self:set_popup_toggle_key(opts.toggle_key)
    self._popup_prev_keychain = popup_control.normalize_popup_toggle_key(opts.prev_keychain, {
        ignored_modifiers = IGNORED_POPUP_MODIFIERS,
    })
    self._popup_next_keychain = popup_control.normalize_popup_toggle_key(opts.next_keychain, {
        ignored_modifiers = IGNORED_POPUP_MODIFIERS,
    })
    self._popup_on_cycle_prev = opts.on_cycle_prev
    self._popup_on_cycle_next = opts.on_cycle_next

    if opts.hover_close == false then
        self:_stop_hover_close_timer()
        self:focus_popup_keyboard_navigation()
    else
        self:blur_popup_keyboard_navigation()
        self:_start_hover_close_timer()
    end
end

---Rebuild the visible popup list from the stored notification entries.
function instance_methods:refresh_popup()
    if not self._popup_refs then
        return
    end

    popup.refresh_header(self)

    local list = self._popup_refs.list
    list:reset()

    local grouped, ordered = build_groups(self.notifications)
    local wheel_buttons = {
        awful.button({}, 4, function()
            self:scroll_popup(-1)
        end),
        awful.button({}, 5, function()
            self:scroll_popup(1)
        end),
    }

    local popup_items = {}
    local popup_title = POPUP_TITLES.notifications

    if self.active_group_key then
        local active_group = grouped[self.active_group_key]
        if active_group and #active_group.entries > 0 then
            local latest = active_group.entries[#active_group.entries]
            popup_title = string.format("%s (%d)", latest.source, #active_group.entries)

            for _, entry in ipairs(active_group.entries) do
                popup_items[#popup_items + 1] = {
                    kind = "notification",
                    entry = entry,
                }
            end
        else
            reset_popup_view(self)
        end
    end

    if not self.active_group_key then
        for _, group in ipairs(ordered) do
            if #group.entries > 1 then
                popup_items[#popup_items + 1] = {
                    kind = "group",
                    group = group,
                }
            else
                popup_items[#popup_items + 1] = {
                    kind = "notification",
                    entry = group.entries[1],
                }
            end
        end
    else
        popup_title = popup_title ~= "" and popup_title or POPUP_TITLES.grouped_notifications
    end

    self.popup_title = popup_title
    self.popup_total_items = #popup_items
    self._popup_items = popup_items
    self:_ensure_popup_selection()

    local visible_items = math.max(1, self:popup_visible_items())
    local max_offset = math.max(1, #popup_items - visible_items + 1)
    self.popup_scroll_offset = math.max(1, math.min(self.popup_scroll_offset or 1, max_offset))
    self:_ensure_selected_item_visible()

    local last_index = math.min(#popup_items, self.popup_scroll_offset + visible_items - 1)
    for index = self.popup_scroll_offset, last_index do
        local item = popup_items[index]
        local card

        if item.kind == "group" then
            card = cards.build_group_card(self, item.group, {
                extra_buttons = wheel_buttons,
                selection_index = index,
                selected = index == self.popup_selected_index,
            })
        else
            card = cards.build_notification_card(self, item.entry, {
                extra_buttons = wheel_buttons,
                selection_index = index,
                selected = index == self.popup_selected_index,
            })
        end

        item.widget = card.widget
        item.on_space = card.on_space
        item.on_enter = card.on_enter
        list:add(card.widget)
    end

    if #popup_items > visible_items then
        self.popup_footer_text = string.format(
            "Use Up/Down to browse %d-%d of %d, Right to dismiss, Enter to open/activate, Left to go back/close",
            self.popup_scroll_offset,
            last_index,
            #popup_items
        )
    elseif #popup_items == 0 then
        self.popup_footer_text = "No notifications"
    else
        self.popup_footer_text = nil
    end

    list:buttons(gears.table.join(table.unpack(wheel_buttons)))

    popup.refresh_header(self)
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

function instance_methods:_stop_hover_close_timer()
    if self._hover_close_timer then
        self._hover_close_timer:stop()
        self._hover_close_timer = nil
    end
end

---Start the grace-period hover-close timer used for mouse-driven popup sessions.
function instance_methods:_start_hover_close_timer()
    self:_stop_hover_close_timer()

    local outside_ticks = 0
    local poll_interval = self:hover_close_poll_interval()
    local hover_timeout = self:hover_close_timeout()
    local max_outside_ticks = math.max(1, math.floor((hover_timeout / poll_interval) + 0.5))

    self._hover_close_timer = gears.timer({
        timeout = poll_interval,
        autostart = true,
        call_now = false,
        callback = function()
            local popup_widget = self._popup
            if not (popup_widget and popup_widget.visible) then
                self:_stop_hover_close_timer()
                return
            end

            local mouse_coords = mouse.coords()
            local geometry = popup_widget:geometry()
            local inside_popup =
                mouse_coords.x >= geometry.x and mouse_coords.x < (geometry.x + geometry.width) and
                mouse_coords.y >= geometry.y and mouse_coords.y < (geometry.y + geometry.height)

            if inside_popup then
                outside_ticks = 0
                return
            end

            outside_ticks = outside_ticks + 1
            if outside_ticks >= max_outside_ticks then
                popup.hide(self)
                self:_stop_hover_close_timer()
                widget_feedback.sync(self, self._popup and self._popup.visible or false)
            end
        end,
    })
end

---Hide the lxnotify popup and stop any hover-close timer.
function instance_methods:close_popups()
    self:_stop_hover_close_timer()
    self:blur_popup_keyboard_navigation()
    popup.hide(self)
    widget_feedback.sync(self, self._popup and self._popup.visible or false)
end

---Open the popup explicitly, optionally disabling hover-close for keyboard use.
function instance_methods:show_notification_popup(arg1, arg2)
    local opts = popup_control.normalize_popup_opts(arg1, arg2)
    if opts.hover_close == nil then
        opts.hover_close = true
    end

    popup.show(self, current_target_screen_context())
    self:_apply_popup_keyboard_opts(opts)
    widget_feedback.sync(self, self._popup and self._popup.visible or false)
end

---Toggle the popup, with keyboard-friendly control over hover-close behavior.
function instance_methods:toggle_notification_popup(arg1, arg2)
    local opts = popup_control.normalize_popup_opts(arg1, arg2)
    if opts.hover_close == nil then
        opts.hover_close = true
    end

    local was_visible = self._popup and self._popup.visible
    popup.toggle(self, current_target_screen_context())

    if self._popup and self._popup.visible and not was_visible then
        self:_apply_popup_keyboard_opts(opts)
    else
        self:_stop_hover_close_timer()
        self:blur_popup_keyboard_navigation()
    end

    widget_feedback.sync(self, self._popup and self._popup.visible or false)
end

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
        popup_title = POPUP_TITLES.notifications,
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
