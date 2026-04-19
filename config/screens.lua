local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local config_data = require("config.config_data")
local profiles = require("config.screens.profiles")
local tags = require("config.tags")

local M = {}

local function apply_wallpaper(screen_obj)
    if not beautiful.wallpaper then
        return
    end

    local wallpaper = beautiful.wallpaper

    if type(wallpaper) == "function" then
        wallpaper = wallpaper(screen_obj)
    end

    gears.wallpaper.maximized(wallpaper, screen_obj, true)
end

local function apply_profile(screen_obj, settings, screen_profiles)
    local profile = profiles.profile_for_screen(settings, screen_profiles, screen_obj.index)

    if not profile then
        return
    end

    local layout = tags.resolve_layout(profile.layout)

    if layout and screen_obj.selected_tag then
        screen_obj.selected_tag.layout = layout
    end

    if profile.dpi then
        screen_obj.dpi = profile.dpi
    end
end

---Configure wallpaper handling and per-screen defaults.
---
---This is where monitor indices from `settings.lua` are translated into layout
---defaults and DPI settings.
---@param settings table
function M.setup(settings)
    local screen_profiles = profiles.normalize_profiles(config_data.screens())

    screen.connect_signal("property::geometry", function(s)
        apply_wallpaper(s)
    end)

    awful.screen.connect_for_each_screen(function(s)
        beautiful.at_screen_connect(s)
        apply_profile(s, settings, screen_profiles)
    end)
end

return M
