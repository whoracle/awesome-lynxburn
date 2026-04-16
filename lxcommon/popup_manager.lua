local M = {}

local popups = {}

local function ensure_module(module_id)
    if not popups[module_id] then
        popups[module_id] = {}
    end

    return popups[module_id]
end

function M.register(module_id, popup_id, handle)
    ensure_module(module_id)[popup_id] = handle
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

return M
