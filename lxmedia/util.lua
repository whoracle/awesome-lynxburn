local M = {}

function M.trim(s)
    if not s then
        return nil
    end

    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.shell_escape(s)
    s = tostring(s or "")
    return "'" .. s:gsub("'", [["'"']]) .. "'"
end

function M.command_exists(cmd)
    local ok = os.execute("command -v " .. cmd .. " >/dev/null 2>&1")
    return ok == true or ok == 0
end

function M.read_command(cmd)
    local f = io.popen(cmd)
    if not f then
        return nil
    end

    local out = f:read("*a")
    f:close()
    return M.trim(out or "")
end

function M.split_lines(s)
    local lines = {}
    if not s or s == "" then
        return lines
    end

    for line in s:gmatch("[^\r\n]+") do
        lines[#lines + 1] = line
    end

    return lines
end

return M
