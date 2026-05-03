local M = {}

local popups = {}
local active = nil
local POPUP_ROLE_ORDER = {
    primary = 1,
    secondary = 2,
    tertiary = 3,
}

local function ensure_module(module_id)
    if not popups[module_id] then
        popups[module_id] = {}
    end

    return popups[module_id]
end

local function normalize_handle(handle, opts)
    local normalized = {}

    for key, value in pairs(handle or {}) do
        normalized[key] = value
    end

    opts = opts or {}
    normalized.popup_role = opts.popup_role
    normalized.include_in_cycle = opts.include_in_cycle

    return normalized
end

local function popup_role_sort_key(popup_role)
    return POPUP_ROLE_ORDER[popup_role] or math.huge
end

---Register one popup handle for a module.
---A handle may expose `open`, `close`, and `is_visible`, plus cycle metadata.
function M.register(module_id, popup_id, handle, opts)
    ensure_module(module_id)[popup_id] = normalize_handle(handle, opts)
end

---Remove a previously registered popup handle.
function M.unregister(module_id, popup_id)
    local module_popups = popups[module_id]
    if not module_popups then
        return
    end

    if active and active.module_id == module_id and active.popup_id == (popup_id or "default") then
        active = nil
    end

    module_popups[popup_id] = nil
end

---Fetch one popup handle by module id and popup id.
function M.get(module_id, popup_id)
    local module_popups = popups[module_id]
    if not module_popups then
        return nil
    end

    return module_popups[popup_id or "default"]
end

---List all popups for one module in a stable id-oriented order.
function M.list_module(module_id)
    local module_popups = popups[module_id] or {}
    local ordered = {}

    for popup_id, handle in pairs(module_popups) do
        ordered[#ordered + 1] = {
            popup_id = popup_id,
            handle = handle,
        }
    end

    table.sort(ordered, function(a, b)
        if a.popup_id == "default" then
            return true
        end

        if b.popup_id == "default" then
            return false
        end

        return a.popup_id < b.popup_id
    end)

    return ordered
end

---List cycle-participating popups for one module in semantic role order.
---This is the primary/secondary/tertiary ordering consumed by lxbar popup
---cycling and should stay aligned with top-level widget semantics.
function M.list_module_cycle(module_id)
    local ordered = {}

    for popup_id, handle in pairs(popups[module_id] or {}) do
        if handle
            and handle.popup_role
            and handle.include_in_cycle ~= false then
            ordered[#ordered + 1] = {
                popup_id = popup_id,
                handle = handle,
                popup_role = handle.popup_role,
            }
        end
    end

    table.sort(ordered, function(a, b)
        local left_key = popup_role_sort_key(a.popup_role)
        local right_key = popup_role_sort_key(b.popup_role)

        if left_key ~= right_key then
            return left_key < right_key
        end

        return a.popup_id < b.popup_id
    end)

    return ordered
end

---Find the popup registered for one semantic popup role.
function M.find_by_popup_role(module_id, popup_role)
    if not popup_role then
        return nil
    end

    for popup_id, handle in pairs(popups[module_id] or {}) do
        if handle and handle.popup_role == popup_role then
            return {
                popup_id = popup_id,
                handle = handle,
                popup_role = popup_role,
            }
        end
    end

    return nil
end

local function active_is_visible()
    if not active then
        return false
    end

    local handle = active.handle
    if type(handle.is_visible) == "function" then
        if handle.is_visible() then
            return true
        end

        active = nil
        return false
    end

    return true
end

local function scan_visible()
    for module_id, module_popups in pairs(popups) do
        for popup_id, handle in pairs(module_popups) do
            if handle and type(handle.is_visible) == "function" and handle.is_visible() then
                active = {
                    module_id = module_id,
                    popup_id = popup_id,
                    handle = handle,
                }
                return active
            end
        end
    end

    return nil
end

local function close_active()
    if not active then
        return
    end

    local handle = active.handle
    active = nil

    if handle and type(handle.close) == "function" then
        handle.close()
    end
end

---Close the currently active popup, if any.
function M.close_current()
    close_active()
end

---Compatibility alias for older callers.
function M.close_all()
    close_active()
end

---Return the popup handle currently tracked as visible.
function M.current_visible()
    if active_is_visible() then
        return active
    end

    return scan_visible()
end

---Show one popup and close every other registered popup first.
function M.show(module_id, popup_id, opts)
    popup_id = popup_id or "default"
    local handle = M.get(module_id, popup_id)
    if not (handle and type(handle.open) == "function") then
        return false
    end

    local visible = M.current_visible()
    local already_active = visible
        and visible.module_id == module_id
        and visible.popup_id == popup_id

    if visible and not already_active and not (handle.shared_shell and visible.handle.shared_shell) then
        close_active()
    end

    handle.open(opts or {})
    active = {
        module_id = module_id,
        popup_id = popup_id,
        handle = handle,
    }
    return active_is_visible()
end

---Toggle one popup, treating it as exclusive with every other registered popup.
function M.toggle(module_id, popup_id, opts)
    popup_id = popup_id or "default"
    local visible = M.current_visible()

    if visible
        and visible.module_id == module_id
        and visible.popup_id == popup_id then
        close_active()
        return false
    end

    return M.show(module_id, popup_id, opts)
end

---Show the popup registered for one semantic popup role.
function M.show_by_popup_role(module_id, popup_role, opts)
    local entry = M.find_by_popup_role(module_id, popup_role)
    if not entry then
        return false
    end

    return M.show(module_id, entry.popup_id, opts)
end

---Toggle the popup registered for one semantic popup role.
function M.toggle_by_popup_role(module_id, popup_role, opts)
    local entry = M.find_by_popup_role(module_id, popup_role)
    if not entry then
        return false
    end

    return M.toggle(module_id, entry.popup_id, opts)
end

return M
