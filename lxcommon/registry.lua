local M = {}

local entries = {}
local configured_order = {}

local function normalize_order(order)
    local normalized = {}

    for index, id in ipairs(order or {}) do
        if type(id) == "string" and id ~= "" and normalized[id] == nil then
            normalized[id] = index
        end
    end

    return normalized
end

local function normalize_entry(entry)
    return {
        id = assert(entry.id, "lxcommon registry entry requires id"),
        widget = assert(entry.widget, "lxcommon registry entry requires widget"),
        default_order = tonumber(entry.default_order) or 100,
        enabled = entry.enabled,
        include_in_popup_cycle = entry.include_in_popup_cycle,
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

function M.set_order(order)
    configured_order = normalize_order(order)
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
        local configured_a = configured_order[a.id]
        local configured_b = configured_order[b.id]

        if configured_a ~= nil or configured_b ~= nil then
            if configured_a == nil then
                return false
            end

            if configured_b == nil then
                return true
            end

            if configured_a ~= configured_b then
                return configured_a < configured_b
            end
        end

        if a.default_order ~= b.default_order then
            return a.default_order < b.default_order
        end

        return a.id < b.id
    end)

    return ordered
end

function M.clear()
    entries = {}
    configured_order = {}
end

return M
