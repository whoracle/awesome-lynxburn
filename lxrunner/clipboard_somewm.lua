local M = {}

function M.primary_selection_command(util)
    if util.command_exists("wl-paste") then
        return "wl-paste --no-newline --primary 2>/dev/null"
    end

    return nil
end

return M
