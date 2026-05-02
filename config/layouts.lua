local awful = require("awful")
local quake = require("config.quake")
local tags = require("config.tags")

local M = {}

---Configure the available layouts and global terminal/tag names.
---@param settings {terminal:string}
function M.setup(settings)
    awful.util.terminal = settings.terminal
    awful.layout.append_default_layouts(tags.default_layouts())
end

---Create the drop-down Quake terminal wrapper.
---@param terminal string
---@return table
function M.create_quake(terminal)
    return quake.new({
        app = terminal,
    })
end

function M.resize_useless_gaps(delta)
    local screen = awful.screen.focused()
    local tag = screen and screen.selected_tag

    if not tag then
        return
    end

    tag.gap = math.max(0, (tag.gap or 0) + tonumber(delta or 0))
    awful.layout.arrange(screen)
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
