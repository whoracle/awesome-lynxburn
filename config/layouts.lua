local awful = require("awful")
local lain = require("lain")
local tags = require("config.tags")

local M = {}

---Configure the available Awesome/lain layouts and global terminal/tag names.
---@param settings {terminal:string}
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
    awful.layout.append_default_layouts(tags.default_layouts())
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

function M.resize_useless_gaps(delta)
    lain.util.useless_gaps_resize(delta)
end

function M.cycle_selected_tag(step)
    local screen = awful.screen.focused()
    local tag = screen and screen.selected_tag

    tags.cycle_for_tag(tag, step)
end

function M.reset_selected_tag_layout()
    local screen = awful.screen.focused()
    local tag = screen and screen.selected_tag
    local layout = tags.first_layout_for_tag(tag)

    if tag and layout then
        tag.layout = layout
    end
end

return M
