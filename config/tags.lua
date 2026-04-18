local awful = require("awful")
local lain = require("lain")
local config_data = require("config.config_data")

local M = {}

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

local function build_specs()
    local tag_config = config_data.tags()
    local order = tag_config.order or {}
    local definitions = tag_config.definitions or {}
    local specs = {}

    for _, tag_name in ipairs(order) do
        local definition = definitions[tag_name] or {}

        specs[#specs + 1] = {
            name = tag_name,
            layout = definition.layout,
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

    for _, spec in ipairs(build_specs()) do
        names[#names + 1] = spec.name
        layouts[#layouts + 1] = resolve_layout(spec.layout)
    end

    awful.tag(names, screen, layouts)
end

return M
