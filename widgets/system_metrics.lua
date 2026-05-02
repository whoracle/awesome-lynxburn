local gears = require("gears")

local M = {}

local function read_first_line(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end

    local line = file:read("*l")
    file:close()
    return line
end

function M.watch(timeout, callback)
    local timer = gears.timer({ timeout = timeout or 2 })
    timer:connect_signal("timeout", callback)
    timer:start()
    callback()
    return timer
end

function M.cpu_reader()
    local last_active = 0
    local last_total = 0

    return function()
        local line = read_first_line("/proc/stat")
        if not line then
            return nil
        end

        local values = {}
        for value in line:gmatch("%s+(%d+)") do
            values[#values + 1] = tonumber(value) or 0
        end

        local idle = (values[4] or 0) + (values[5] or 0)
        local total = 0
        for _, value in ipairs(values) do
            total = total + value
        end

        local active = total - idle
        local delta_active = active - last_active
        local delta_total = total - last_total
        last_active = active
        last_total = total

        if delta_total <= 0 then
            return 0
        end

        return math.ceil(math.abs((delta_active / delta_total) * 100))
    end
end

function M.memory()
    local values = {}

    for line in io.lines("/proc/meminfo") do
        local key, value = line:match("^([%a]+):%s+(%d+)")
        if key and value then
            values[key] = tonumber(value) or 0
        end
    end

    local total = values.MemTotal or 0
    if total <= 0 then
        return nil
    end

    local used = total
        - (values.MemFree or 0)
        - (values.Buffers or 0)
        - (values.Cached or 0)
        - (values.SReclaimable or 0)

    return math.floor((used / total) * 100)
end

function M.loadavg()
    local line = read_first_line("/proc/loadavg")
    return line and line:match("^(%S+)")
end

return M
