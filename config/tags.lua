local awful = require("awful")
local lain = require("lain")
local config_data = require("config.config_data")

local M = {}

local function resolve_layout(layout_name)
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

    if layout_name == nil then
        return nil
    end

    return layouts[layout_name] or awful.layout.suit.fair
end

local function screen_name_for_index(screen_index)
    local monitors = config_data.settings().monitors or {}

    for screen_name, monitor_index in pairs(monitors) do
        if monitor_index == screen_index then
            return screen_name
        end
    end

    return nil
end

local function build_specs(screen_name)
    local screen_config = config_data.screens()
    local order = screen_config.tag_order or {}
    local defaults = screen_config.tag_defaults or {}
    local profile = screen_name and screen_config[screen_name] or {}
    local profile_tags = profile.tags or {}
    local specs = {}

    for _, tag_name in ipairs(order) do
        local definition = defaults[tag_name] or {}
        local override = profile_tags[tag_name] or {}
        local layout = override.layout or definition.layout

        if layout == nil and type(profile.layout) == "string" then
            layout = profile.layout
        end

        specs[#specs + 1] = {
            name = tag_name,
            layout = layout,
        }
    end

    return specs
end

function M.resolve_layout(layout_name)
    return resolve_layout(layout_name)
end

function M.specs()
    return build_specs()
end

function M.names()
    local names = {}

    for _, spec in ipairs(build_specs()) do
        names[#names + 1] = spec.name
    end

    return names
end

function M.default_layouts()
    return {
        awful.layout.suit.fair,
        lain.layout.centerwork,
        lain.layout.centerwork.horizontal,
        awful.layout.suit.fair.horizontal,
        awful.layout.suit.floating,
    }
end

function M.create_for_screen(screen)
    local names = {}
    local layouts = {}
    local screen_name = screen_name_for_index(screen.index)

    for _, spec in ipairs(build_specs(screen_name)) do
        names[#names + 1] = spec.name
        layouts[#layouts + 1] = resolve_layout(spec.layout)
    end

    awful.tag(names, screen, layouts)
end

return M
