local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local lain = require("lain")

local M = {}

---Configure wallpaper handling and per-screen defaults.
---
---This is where monitor indices from `settings.lua` are translated into layout
---defaults and DPI settings.
---@param settings table
function M.setup(settings)
    screen.connect_signal("property::geometry", function(s)
        if beautiful.wallpaper then
            local wallpaper = beautiful.wallpaper
            if type(wallpaper) == "function" then
                wallpaper = wallpaper(s)
            end
            gears.wallpaper.maximized(wallpaper, s, true)
        end
    end)

    awful.screen.connect_for_each_screen(function(s)
        beautiful.at_screen_connect(s)

        if s.index == settings.monitors.left then
            s.selected_tag.layout = lain.layout.centerwork.horizontal
            s.dpi = 96
        end

        if s.index == settings.monitors.center then
            s.selected_tag.layout = lain.layout.centerwork
            s.dpi = 110
        end

        if s.index == settings.monitors.right then
            s.dpi = 110
        end
    end)
end

return M
