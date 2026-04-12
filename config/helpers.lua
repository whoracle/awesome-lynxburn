local M = {}

local ipairs = ipairs
local pcall = pcall
local require = require
local type = type

local function is_array(value)
    if type(value) ~= "table" then
        return false
    end

    local count = 0

    for key in pairs(value) do
        if type(key) ~= "number" then
            return false
        end

        count = count + 1
    end

    for index = 1, count do
        if value[index] == nil then
            return false
        end
    end

    return true
end

local function deep_copy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}

    for key, nested_value in pairs(value) do
        copy[key] = deep_copy(nested_value)
    end

    return copy
end

---Install startup-time and runtime error notifications.
---@param awesome table
---@param naughty table
function M.setup_error_handling(awesome, naughty)
    if awesome.startup_errors then
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, there were errors during startup!",
            text = awesome.startup_errors,
        })
    end

    local in_error = false

    awesome.connect_signal("debug::error", function(err)
        if in_error then
            return
        end

        in_error = true
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err),
        })
        in_error = false
    end)
end

---Spawn each command only when a matching process is not already running.
---
---This is used for "run once" startup applications and intentionally checks the
---first token of the configured command for process matching.
---@param awful table
---@param commands string[]
function M.run_once(awful, commands)
    for _, cmd in ipairs(commands) do
        local findme = cmd
        local firstspace = cmd:find(" ")

        if firstspace then
            findme = cmd:sub(0, firstspace - 1)
        end

        awful.spawn.with_shell(
            string.format("pgrep -u $USER -x %s > /dev/null || (%s)", findme, cmd)
        )
    end
end

---Deep-merge `source` into `destination`.
---
---Array-like tables replace the destination wholesale. Nested map-like tables
---merge recursively so local override files can override only the keys they
---care about.
---@param destination table
---@param source table|nil
---@return table
function M.deep_merge(destination, source)
    if type(source) ~= "table" then
        return destination
    end

    for key, value in pairs(source) do
        if type(value) == "table" then
            if is_array(value) then
                destination[key] = deep_copy(value)
            else
                if type(destination[key]) ~= "table" or is_array(destination[key]) then
                    destination[key] = {}
                end

                M.deep_merge(destination[key], value)
            end
        else
            destination[key] = value
        end
    end

    return destination
end

---Attempt to require an optional local module without failing startup.
---@param module_name string
---@param fallback any
---@return any
function M.load_optional_module(module_name, fallback)
    local ok, result = pcall(require, module_name)

    if ok then
        return result
    end

    local not_found_pattern = "module '" .. module_name .. "' not found"

    if type(result) == "string" and result:match(not_found_pattern) then
        return fallback
    end

    error(result)

    return fallback
end

return M
