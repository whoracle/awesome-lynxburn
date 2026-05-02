local awful = require("awful")

local centerwork = {
    name = "centerwork",
    horizontal = { name = "centerworkh" },
}

local function arrange(p, horizontal)
    local tag = p.tag or screen[p.screen].selected_tag
    local workarea = p.workarea
    local clients = p.clients

    if #clients == 0 then
        return
    end

    local factor = tag.master_width_factor
    local main_width = math.floor(workarea.width * factor)
    local main_height = math.floor(workarea.height * factor)
    local side_width = workarea.width - main_width
    local side_height = workarea.height - main_height
    local first_count = math.floor(#clients / 2)
    local second_count = math.floor((#clients - 1) / 2)
    local geometry = {}

    if horizontal then
        geometry = {
            x = workarea.x,
            y = workarea.y + math.floor(side_height / 2),
            width = workarea.width,
            height = main_height,
        }
    else
        geometry = {
            x = workarea.x + math.floor(side_width / 2),
            y = workarea.y,
            width = main_width,
            height = workarea.height,
        }
    end

    geometry.width = math.max(geometry.width, 1)
    geometry.height = math.max(geometry.height, 1)
    p.geometries[clients[1]] = geometry

    if #clients <= 1 then
        return
    end

    local left_width = math.floor(side_width / 2)
    local right_width = side_width - left_width
    local top_height = math.floor(side_height / 2)
    local bottom_height = side_height - top_height
    local first_size = horizontal and math.floor(workarea.width / math.max(first_count, 1))
        or math.floor(workarea.height / math.max(first_count, 1))
    local second_size = horizontal and math.floor(workarea.width / math.max(second_count, 1))
        or math.floor(workarea.height / math.max(second_count, 1))

    for index = 2, #clients do
        local row = math.floor(index / 2)
        local first_side = index % 2 == 0
        local last_on_side = row == (first_side and first_count or second_count)
        local size = first_side and first_size or second_size
        local g

        if horizontal then
            local y = first_side and workarea.y or (workarea.y + top_height + main_height)
            local height = first_side and top_height or bottom_height
            local x = workarea.x + (row - 1) * size
            local width = last_on_side and (workarea.x + workarea.width - x) or size
            g = { x = x, y = y, width = width, height = height }
        else
            local x = first_side and workarea.x or (workarea.x + left_width + main_width)
            local width = first_side and left_width or right_width
            local y = workarea.y + (row - 1) * size
            local height = last_on_side and (workarea.y + workarea.height - y) or size
            g = { x = x, y = y, width = width, height = height }
        end

        g.width = math.max(g.width, 1)
        g.height = math.max(g.height, 1)
        p.geometries[clients[index]] = g
    end
end

local function resize_client(client_obj, horizontal)
    if not client_obj or not client_obj.valid then
        return
    end

    local workarea = client_obj.screen.workarea
    local tag = client_obj.screen.selected_tag
    local cursor = horizontal and "sb_v_double_arrow" or "sb_h_double_arrow"

    mousegrabber.run(function(pointer)
        if not client_obj.valid then
            return false
        end

        for _, pressed in ipairs(pointer.buttons) do
            if pressed then
                if horizontal then
                    tag.master_width_factor = math.min(math.max(1 - ((pointer.y - workarea.y) / workarea.height) * 2, 0.01), 0.99)
                else
                    tag.master_width_factor = math.min(math.max(1 - ((pointer.x - workarea.x) / workarea.width) * 2, 0.01), 0.99)
                end
                return true
            end
        end

        return false
    end, cursor)
end

function centerwork.arrange(p)
    arrange(p, false)
end

function centerwork.horizontal.arrange(p)
    arrange(p, true)
end

function centerwork.mouse_resize_handler(client_obj)
    resize_client(client_obj, false)
end

function centerwork.horizontal.mouse_resize_handler(client_obj)
    resize_client(client_obj, true)
end

function centerwork.focus_byidx(step)
    awful.client.focus.byidx(step)
end

function centerwork.swap_byidx(step)
    awful.client.swap.byidx(step)
end

return centerwork
