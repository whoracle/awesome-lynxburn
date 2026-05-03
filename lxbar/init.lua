local wibox = require("wibox")

local popup_manager = require("lxcommon.popup_manager")
local registry = require("lxcommon.registry")

local M = {}
M.__index = M

---Return popup-cycle entries in the same order as the top-level bar widgets.
---Modules can opt out of cycling, but popup order itself stays tied to bar
---order and shared primary/secondary/tertiary popup-role semantics.
local function ordered_popup_entries()
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

---Return the next popup entry to show based on the currently visible popup.
---@param ordered table[]
---@param visible table|nil
---@param direction integer|nil
---@return table|nil
local function cycle_target(ordered, visible, direction)
    if #ordered == 0 then
        return nil
    end

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

    return ordered[target_index]
end

---Rebuild the visible lxbar widget row from the shared registry order.
function M:refresh()
    self._layout:reset()

    for _, entry in ipairs(registry.list()) do
        self._layout:add(entry.widget)
    end
end

---Close every registered popup, regardless of which module owns it.
function M:close_popups()
    popup_manager.close_all()
end

---Compatibility alias for older callers that still use the singular name.
function M:close_popup()
    return self:close_popups()
end

---Show one specific popup by module id and popup id.
function M:show_popup(module_id, popup_id, opts)
    return popup_manager.show(module_id, popup_id or "default", opts)
end

---Toggle one specific popup by module id and popup id.
function M:toggle_popup(module_id, popup_id, opts)
    return popup_manager.toggle(module_id, popup_id or "default", opts)
end

---Show the popup registered for a semantic popup role.
function M:show_popup_by_role(module_id, popup_role, opts)
    return popup_manager.show_by_popup_role(module_id, popup_role, opts)
end

---Toggle the popup registered for a semantic popup role.
function M:toggle_popup_by_role(module_id, popup_role, opts)
    return popup_manager.toggle_by_popup_role(module_id, popup_role, opts)
end

---Cycle through visible popup candidates using bar order plus popup-role order.
function M:cycle_popups(direction, opts)
    local ordered = ordered_popup_entries()
    local target = cycle_target(ordered, popup_manager.current_visible(), direction)

    if not target then
        return false
    end

    return popup_manager.show(target.module_id, target.popup_id, opts)
end

---Cycle through popup candidates from an explicit module/popup anchor.
---Popup keygrabbers use this so cycling does not depend on compositor-specific
---visibility state while the currently active popup is dispatching the key.
function M:cycle_popups_from(anchor, direction, opts)
    if not (anchor and anchor.module_id and anchor.popup_id) then
        return self:cycle_popups(direction, opts)
    end

    local ordered = ordered_popup_entries()
    local target = cycle_target(ordered, anchor, direction)

    if not target then
        return false
    end

    return popup_manager.show(target.module_id, target.popup_id, opts)
end

---Create the lxbar container backed by the shared widget registry.
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
