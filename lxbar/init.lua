local wibox = require("wibox")

local popup_manager = require("lxcommon.popup_manager")
local registry = require("lxcommon.registry")

local M = {}
M.__index = M

function M:refresh()
    self._layout:reset()

    for _, entry in ipairs(registry.list()) do
        self._layout:add(entry.widget)
    end
end

function M:_ordered_popup_entries()
    local ordered = {}

    for _, entry in ipairs(registry.list()) do
        if entry.include_in_popup_cycle ~= false then
            for _, popup_entry in ipairs(popup_manager.list_module_cycle(entry.id)) do
                ordered[#ordered + 1] = {
                    module_id = entry.id,
                    popup_id = popup_entry.popup_id,
                    handle = popup_entry.handle,
                    popup_role = popup_entry.popup_role,
                }
            end
        end
    end

    return ordered
end

function M:close_popup()
    popup_manager.close_all()
end

function M:show_popup(module_id, popup_id, opts)
    return popup_manager.show(module_id, popup_id or "default", opts)
end

function M:toggle_popup(module_id, popup_id, opts)
    return popup_manager.toggle(module_id, popup_id or "default", opts)
end

function M:show_popup_by_role(module_id, popup_role, opts)
    return popup_manager.show_by_popup_role(module_id, popup_role, opts)
end

function M:toggle_popup_by_role(module_id, popup_role, opts)
    return popup_manager.toggle_by_popup_role(module_id, popup_role, opts)
end

function M:cycle_popups(direction, opts)
    local ordered = self:_ordered_popup_entries()
    if #ordered == 0 then
        return false
    end

    local visible = popup_manager.current_visible()
    direction = direction or 1
    local target_index = direction < 0 and #ordered or 1

    if visible then
        for index, entry in ipairs(ordered) do
            if entry.module_id == visible.module_id and entry.popup_id == visible.popup_id then
                target_index = index + direction
                break
            end
        end
    end

    if target_index < 1 then
        target_index = #ordered
    elseif target_index > #ordered then
        target_index = 1
    end

    local target = ordered[target_index]
    return popup_manager.show(target.module_id, target.popup_id, opts)
end

function M.new(opts)
    opts = opts or {}

    local self = setmetatable({}, M)
    self._layout = wibox.layout.fixed.horizontal()
    self.widget = wibox.widget({
        self._layout,
        spacing = opts.spacing or 0,
        layout = wibox.layout.fixed.horizontal,
    })

    self:refresh()

    return self
end

return M
