local M = {}

local entries = {}

local function normalize_entry(entry)
    return {
        id = assert(entry.id, "lxcommon registry entry requires id"),
        widget = assert(entry.widget, "lxcommon registry entry requires widget"),
        default_order = tonumber(entry.default_order) or 100,
        enabled = entry.enabled,
    }
end

function M.register(entry)
    local normalized = normalize_entry(entry)
    entries[normalized.id] = normalized
    return normalized
end

function M.unregister(id)
    entries[id] = nil
end

function M.get(id)
    return entries[id]
end

function M.list()
    local ordered = {}

    for _, entry in pairs(entries) do
        local enabled = true
        if type(entry.enabled) == "function" then
            enabled = entry.enabled() ~= false
        elseif entry.enabled ~= nil then
            enabled = entry.enabled ~= false
        end

        if enabled then
            ordered[#ordered + 1] = entry
        end
    end

    table.sort(ordered, function(a, b)
        if a.default_order ~= b.default_order then
            return a.default_order < b.default_order
        end

        return a.id < b.id
    end)

    return ordered
end

function M.clear()
    entries = {}
end

return M
