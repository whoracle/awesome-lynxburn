local layout_catalog = require("config.tags.layout_catalog")
local specs = require("config.tags.specs")

local M = {}

function M.resolve_layout(layout_name)
    return layout_catalog.resolve(layout_name)
end

function M.specs()
    return specs.global_specs()
end

function M.names()
    return specs.global_names()
end

function M.default_layouts()
    return specs.default_layouts()
end

function M.create_for_screen(screen)
    return specs.create_for_screen(screen)
end

function M.layouts_for_tag(tag)
    return specs.layouts_for_tag(tag)
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
