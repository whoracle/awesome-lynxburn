local M = {}

function M.primary_selection_command(util)
    if util.command_exists("x" .. "clip") then
        return "x" .. "clip -o -selection primary 2>/dev/null"
    end

    if util.command_exists("x" .. "sel") then
        return "x" .. "sel -o -p 2>/dev/null"
    end

    return nil
end

return M
