local awful = require("awful")
local config_data = require("config.config_data")
local centerwork = require("config.layouts.centerwork")

local M = {}

local LAYOUTS = {
    ["centerwork"] = centerwork,
    ["centerwork.horizontal"] = centerwork.horizontal,
    ["fair"] = awful.layout.suit.fair,
    ["fairv"] = awful.layout.suit.fair,
    ["fair.horizontal"] = awful.layout.suit.fair.horizontal,
    ["fairh"] = awful.layout.suit.fair.horizontal,
    ["vertical"] = awful.layout.suit.fair,
    ["horizontal"] = awful.layout.suit.fair.horizontal,
    ["floating"] = awful.layout.suit.floating,
}

local function custom_layouts()
    local layout_config = config_data.layouts()
    return type(layout_config.custom) == "table" and layout_config.custom or {}
end

---Resolve a configured layout name into an Awesome layout object.
---@param layout_name string|nil
---@return table|nil
function M.resolve(layout_name)
    if layout_name == nil then
        return nil
    end

    return custom_layouts()[layout_name] or LAYOUTS[layout_name] or awful.layout.suit.fair
end

return M
