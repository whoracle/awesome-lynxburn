local debug = {}

local DEBUG_FIELDS = {
    "id",
    "title",
    "message",
    "text",
    "app_name",
    "category",
    "urgency",
    "timeout",
    "resident",
    "ignore",
    "ignore_suspend",
    "position",
    "destroy_reason",
}

local DEBUG_PRIVATE_FIELDS = {
    "app_name",
    "category",
    "fg",
    "bg",
    "font",
    "icon",
    "id",
    "ignore",
    "margin",
    "message",
    "ontop",
    "position",
    "preset",
    "registered",
    "text",
    "timeout",
    "title",
    "urgency",
    "args",
}

local function debug_value(value)
    local value_type = type(value)

    if value_type == "string" then
        return string.format("%q", value)
    end

    if value_type == "number" or value_type == "boolean" then
        return tostring(value)
    end

    if value == nil then
        return "nil"
    end

    if value_type == "table" then
        local is_array = true
        local max_index = 0
        local key_count = 0

        for key in pairs(value) do
            key_count = key_count + 1
            if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
                is_array = false
            elseif key > max_index then
                max_index = key
            end
        end

        if is_array and key_count == max_index then
            local parts = {}
            for index = 1, max_index do
                parts[#parts + 1] = debug_value(value[index])
            end
            return "{ " .. table.concat(parts, ", ") .. " }"
        end

        local keys = {}
        for key in pairs(value) do
            keys[#keys + 1] = key
        end
        table.sort(keys, function(left, right)
            return tostring(left) < tostring(right)
        end)

        local parts = {}
        for _, key in ipairs(keys) do
            parts[#parts + 1] = string.format("%s=%s", tostring(key), debug_value(value[key]))
        end
        return "{ " .. table.concat(parts, ", ") .. " }"
    end

    return tostring(value)
end

---Format a normalized snapshot for readable Awesome log output.
---@param snapshot table
---@return string
function debug.format_snapshot(snapshot)
    local keys = {}
    for key in pairs(snapshot) do
        keys[#keys + 1] = key
    end
    table.sort(keys)

    local parts = {}
    for _, key in ipairs(keys) do
        parts[#parts + 1] = string.format("%s=%s", key, debug_value(snapshot[key]))
    end

    return "{ " .. table.concat(parts, ", ") .. " }"
end

---Capture the stable and useful attributes of a naughty notification.
---@param notification table
---@return table
function debug.snapshot(notification)
    local snapshot = {}

    for _, field in ipairs(DEBUG_FIELDS) do
        local ok, value = pcall(function()
            return notification[field]
        end)

        if ok and value ~= nil then
            snapshot[field] = value
        end
    end

    local ok_screen, screen_value = pcall(function()
        return notification.screen
    end)
    if ok_screen and screen_value then
        snapshot.screen = screen_value.index or tostring(screen_value)
    end

    local ok_actions, actions = pcall(function()
        return notification.actions
    end)
    if ok_actions and type(actions) == "table" then
        snapshot.actions_count = #actions
    end

    local private = rawget(notification, "_private")
    if type(private) == "table" then
        local private_keys = {}
        for key in pairs(private) do
            private_keys[#private_keys + 1] = tostring(key)
        end
        table.sort(private_keys)
        snapshot._private_keys = private_keys

        local private_values = {}
        for _, field in ipairs(DEBUG_PRIVATE_FIELDS) do
            if private[field] ~= nil then
                private_values[field] = private[field]
            end
        end

        if next(private_values) ~= nil then
            snapshot._private = private_values
        end
    end

    return snapshot
end

---Check one denylist rule against a normalized notification snapshot.
---@param rule table|fun(snapshot: table): boolean
---@param snapshot table
---@return boolean
function debug.rule_matches_snapshot(rule, snapshot)
    if type(rule) == "function" then
        return rule(snapshot) == true
    end

    if type(rule) ~= "table" then
        return false
    end

    for key, expected in pairs(rule) do
        local actual = snapshot[key]

        if type(expected) == "function" then
            if expected(actual, snapshot) ~= true then
                return false
            end
        elseif type(expected) == "string" and type(actual) == "string" then
            if actual ~= expected and not actual:match(expected) then
                return false
            end
        else
            if actual ~= expected then
                return false
            end
        end
    end

    return true
end

return debug
