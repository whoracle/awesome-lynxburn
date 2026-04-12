local awful = require("awful")
local lain = require("lain")

local M = {}

---Configure the available Awesome/lain layouts and global terminal/tag names.
---@param settings {terminal:string,workspaces:string[]}
function M.setup(settings)
    lain.layout.termfair.nmaster = 3
    lain.layout.termfair.ncol = 1
    lain.layout.termfair.center.nmaster = 3
    lain.layout.termfair.center.ncol = 1
    lain.layout.cascade.tile.offset_x = 2
    lain.layout.cascade.tile.offset_y = 32
    lain.layout.cascade.tile.extra_padding = 5
    lain.layout.cascade.tile.nmaster = 5
    lain.layout.cascade.tile.ncol = 2

    awful.util.terminal = settings.terminal
    awful.util.tagnames = settings.workspaces
    awful.layout.layouts = {
        awful.layout.suit.fair,
        lain.layout.centerwork,
        lain.layout.centerwork.horizontal,
        awful.layout.suit.fair.horizontal,
        awful.layout.suit.floating,
    }
end

---Create the drop-down Quake terminal wrapper.
---@param terminal string
---@return table
function M.create_quake(terminal)
    return lain.util.quake({
        app = terminal,
        followtag = true,
    })
end

return M
