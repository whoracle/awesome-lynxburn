local awful = require("awful")
local gears = require("gears")

local actions = require("lxnotify.actions")
local cards = require("lxnotify.cards")
local format = require("lxnotify.format")
local popup = require("lxnotify.popup")
local store = require("lxnotify.store")

local popup_state = {}
local unpack = table.unpack or unpack

local POPUP_TITLES = {
    notifications = "Notifications",
    grouped_notifications = "Grouped Notifications",
}

---Group stored notifications into the burst-group structure used by the popup.
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

---Attach popup-content and selection-state methods to the instance method table.
function popup_state.extend(instance_methods)
    function instance_methods:enter_group_detail(group_key)
        self.active_group_key = group_key
        self.popup_scroll_offset = 1
        self:refresh_popup()
    end

    function instance_methods:leave_group_detail()
        if not self.active_group_key then
            return
        end

        store.reset_popup_view(self)
        self:refresh_popup()
    end

    function instance_methods:dismiss_active_group()
        if not self.active_group_key then
            return
        end

        local kept = {}
        for _, entry in ipairs(self.notifications) do
            if format.group_key(entry) == self.active_group_key then
                if self:should_destroy_on_dismiss() then
                    actions.destroy(entry.notification)
                end
            else
                kept[#kept + 1] = entry
            end
        end

        self.notifications = kept
        self.unread_count = #self.notifications
        store.reset_popup_view(self)
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
                store.reset_popup_view(self)
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

            -- Rebuild cards on every refresh so selection visuals and callbacks
            -- always reflect the current grouped/detail view state.
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
                "Use Up/Down to browse %d-%d of %d, Enter for primary action, Right for secondary action, Left to go back/close",
                self.popup_scroll_offset,
                last_index,
                #popup_items
            )
        elseif #popup_items == 0 then
            self.popup_footer_text = "No notifications"
        else
            self.popup_footer_text = nil
        end

        list:buttons(gears.table.join(unpack(wheel_buttons)))

        popup.refresh_header(self)
    end
end

return popup_state
