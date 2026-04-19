local M = {}

local instances = {}

---Return the cached singleton instance for a service id.
---@param id string
---@return table|nil
function M.get(id)
    return instances[id]
end

---Store a singleton instance for a service id.
---@param id string
---@param value table
---@return table
function M.set(id, value)
    instances[id] = value
    return value
end

---Return an existing singleton or build and cache it on first use.
---@param id string
---@param builder fun(): table
---@return table
function M.ensure(id, builder)
    if not instances[id] then
        instances[id] = builder()
    end

    return instances[id]
end

return M
