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
        local layouts = override.layouts or definition.layouts

        if layout == nil and type(profile.layout) == "string" then
            layout = profile.layout
        end

        if layouts == nil and layout ~= nil then
            layouts = { layout }
        end

        specs[#specs + 1] = {
            name = tag_name,
            layout = layout,
            layouts = layouts,
        }
    end

    return specs
end

local function spec_for_tag(screen_name, tag_name)
    for _, spec in ipairs(build_specs(screen_name)) do
        if spec.name == tag_name then
            return spec
        end
    end

    return nil
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
    local seen = {}
    local layouts = {}
    local screen_config = config_data.screens()

    local function append(layout_name)
        local layout = resolve_layout(layout_name)

        if layout and not seen[layout] then
            seen[layout] = true
            layouts[#layouts + 1] = layout
        end
    end

    for _, tag_name in ipairs(screen_config.tag_order or {}) do
        local definition = (screen_config.tag_defaults or {})[tag_name] or {}

        for _, layout_name in ipairs(definition.layouts or {}) do
            append(layout_name)
        end

        append(definition.layout)
    end

    for screen_name, profile in pairs(screen_config) do
        if type(profile) == "table" and profile.tags then
            for _, tag_name in ipairs(screen_config.tag_order or {}) do
                local spec = profile.tags[tag_name] or {}

                for _, layout_name in ipairs(spec.layouts or {}) do
                    append(layout_name)
                end

                append(spec.layout)
            end
        end
    end

    if #layouts == 0 then
        layouts = {
            awful.layout.suit.fair,
            lain.layout.centerwork,
            awful.layout.suit.floating,
        }
    end

    return layouts
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

function M.layouts_for_tag(tag)
    if not tag or not tag.screen or not tag.name then
        return {}
    end

    local screen_name = screen_name_for_index(tag.screen.index)
    local spec = spec_for_tag(screen_name, tag.name)
    local layouts = {}

    if not spec then
        return layouts
    end

    for _, layout_name in ipairs(spec.layouts or {}) do
        layouts[#layouts + 1] = resolve_layout(layout_name)
    end

    if #layouts == 0 and spec.layout then
        layouts[1] = resolve_layout(spec.layout)
    end

    return layouts
end

function M.cycle_for_tag(tag, step)
    if not tag then
        return
    end

    local layouts = M.layouts_for_tag(tag)

    if #layouts == 0 then
        return
    end

    local current_index = 1

    for index, layout in ipairs(layouts) do
        if tag.layout == layout then
            current_index = index
            break
        end
    end

    local next_index = ((current_index - 1 + step) % #layouts) + 1
    tag.layout = layouts[next_index]
end

function M.first_layout_for_tag(tag)
    local layouts = M.layouts_for_tag(tag)

    return layouts[1]
end

return M
