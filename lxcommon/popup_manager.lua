local M = {}

local popups = {}
local CLICK_ROLE_ORDER = {
    left = 1,
    right = 2,
    middle = 3,
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
    normalized.click_role = opts.click_role
    normalized.include_in_cycle = opts.include_in_cycle

    return normalized
end

local function click_role_sort_key(click_role)
    return CLICK_ROLE_ORDER[click_role] or math.huge
end

function M.register(module_id, popup_id, handle, opts)
    ensure_module(module_id)[popup_id] = normalize_handle(handle, opts)
end

function M.unregister(module_id, popup_id)
    local module_popups = popups[module_id]
    if not module_popups then
        return
    end

    module_popups[popup_id] = nil
end

function M.get(module_id, popup_id)
    local module_popups = popups[module_id]
    if not module_popups then
        return nil
    end

    return module_popups[popup_id or "default"]
end

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

function M.list_module_cycle(module_id)
    local ordered = {}

    for popup_id, handle in pairs(popups[module_id] or {}) do
        if handle
            and handle.click_role
            and handle.include_in_cycle ~= false then
            ordered[#ordered + 1] = {
                popup_id = popup_id,
                handle = handle,
                click_role = handle.click_role,
            }
        end
    end

    table.sort(ordered, function(a, b)
        local left_key = click_role_sort_key(a.click_role)
        local right_key = click_role_sort_key(b.click_role)

        if left_key ~= right_key then
            return left_key < right_key
        end

        return a.popup_id < b.popup_id
    end)

    return ordered
end

function M.close_all()
    for _, module_popups in pairs(popups) do
        for _, handle in pairs(module_popups) do
            if handle and type(handle.close) == "function" then
                handle.close()
            end
        end
    end
end

function M.current_visible()
    for module_id, module_popups in pairs(popups) do
        for popup_id, handle in pairs(module_popups) do
            if handle and type(handle.is_visible) == "function" and handle.is_visible() then
                return {
                    module_id = module_id,
                    popup_id = popup_id,
                    handle = handle,
                }
            end
        end
    end

    return nil
end

function M.show(module_id, popup_id, opts)
    local handle = M.get(module_id, popup_id)
    if not (handle and type(handle.open) == "function") then
        return false
    end

    M.close_all()
    handle.open(opts or {})
    return true
end

function M.toggle(module_id, popup_id, opts)
    local visible = M.current_visible()

    if visible
        and visible.module_id == module_id
        and visible.popup_id == (popup_id or "default") then
        M.close_all()
        return false
    end

    return M.show(module_id, popup_id, opts)
end

return M
