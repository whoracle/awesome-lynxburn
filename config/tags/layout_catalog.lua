local awful = require("awful")
local lain = require("lain")

local M = {}

local LAYOUTS = {
    ["centerwork"] = lain.layout.centerwork,
    ["centerwork.horizontal"] = lain.layout.centerwork.horizontal,
    ["fair"] = awful.layout.suit.fair,
    ["fairv"] = awful.layout.suit.fair,
    ["fair.horizontal"] = awful.layout.suit.fair.horizontal,
    ["fairh"] = awful.layout.suit.fair.horizontal,
    ["vertical"] = awful.layout.suit.fair,
    ["horizontal"] = awful.layout.suit.fair.horizontal,
    ["floating"] = awful.layout.suit.floating,
}

---Resolve a configured layout name into an Awesome/lain layout object.
---@param layout_name string|nil
---@return table|nil
function M.resolve(layout_name)
    if layout_name == nil then
        return nil
    end

    return LAYOUTS[layout_name] or awful.layout.suit.fair
end

return M
