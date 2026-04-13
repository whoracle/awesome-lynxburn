local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local lain = require("lain")
local helpers = require("config.helpers")

local M = {}

local function normalize_profile(profile)
    if type(profile) ~= "table" then
        return profile
    end

    if profile.layout == nil and type(profile[1]) == "string" then
        profile.layout = profile[1]
    end

    return profile
end

local function resolve_layout(layout_name)
    if layout_name == nil then
        return nil
    end

    local layouts = {
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

    return layouts[layout_name]
end

local function default_screen_profiles()
    return {
        left = {
            layout = "centerwork.horizontal",
            dpi = 96,
        },
        center = {
            layout = "centerwork",
            dpi = 110,
        },
        right = {
            dpi = 110,
        },
    }
end

---Configure wallpaper handling and per-screen defaults.
---
---This is where monitor indices from `settings.lua` are translated into layout
---defaults and DPI settings.
---@param settings table
function M.setup(settings)
    local screen_profiles = helpers.deep_merge(
        default_screen_profiles(),
        helpers.load_optional_module("config.override.screens", {})
    )

    for screen_name, profile in pairs(screen_profiles) do
        screen_profiles[screen_name] = normalize_profile(profile)
    end

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

        for screen_name, monitor_index in pairs(settings.monitors) do
            local profile = screen_profiles[screen_name]

            if profile and s.index == monitor_index then
                local layout = resolve_layout(profile.layout)

                if layout then
                    s.selected_tag.layout = layout
                end

                if profile.dpi then
                    s.dpi = profile.dpi
                end
            end
        end
    end)
end

return M
