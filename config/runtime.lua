local os = os
local config_data = require("config.config_data")
local theme_config = require("config.theme")

local M = {}

function M.home()
    return os.getenv("HOME")
end

function M.editor()
    return os.getenv("EDITOR") or "vim"
end

function M.theme_name()
    return theme_config.name()
end

function M.tags()
    local names = {}
    local screens = config_data.screens()

    for _, tag_name in ipairs(screens.tag_order or {}) do
        names[#names + 1] = tag_name
    end

    return names
end

return M
