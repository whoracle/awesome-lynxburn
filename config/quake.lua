local awful = require("awful")

local M = {}

local Dropdown = {}
Dropdown.__index = Dropdown

local function client_matches(name)
    return function(c)
        return c.instance == name or c.class == name
    end
end

function Dropdown:geometry()
    local screen_obj = awful.screen.focused()
    local area = self.overlap and screen_obj.geometry or screen_obj.workarea
    local width = self.width <= 1 and math.floor(area.width * self.width) or self.width
    local height = self.height <= 1 and math.floor(area.height * self.height) or self.height

    return {
        x = area.x + math.floor((area.width - width) / 2),
        y = self.position == "bottom" and (area.y + area.height - height) or area.y,
        width = width,
        height = height,
    }
end

function Dropdown:find_client()
    for c in awful.client.iterate(client_matches(self.name)) do
        return c
    end

    return nil
end

function Dropdown:spawn()
    self.pending_spawn = true
    awful.spawn(string.format("%s -name %s", self.app, self.name), {
        tag = awful.screen.focused().selected_tag,
    })
end

function Dropdown:show(c)
    c.hidden = false
    c.floating = true
    c.ontop = true
    c.above = true
    c.skip_taskbar = true
    c.size_hints_honor = false
    c:geometry(self:geometry())
    c:move_to_tag(awful.screen.focused().selected_tag)
    client.focus = c
    c:raise()
    self.visible = true
end

function Dropdown:hide(c)
    c.hidden = true
    self.visible = false
end

function Dropdown:toggle()
    local c = self:find_client()

    if not c then
        self.visible = true
        self:spawn()
        return
    end

    if self.visible and not c.hidden then
        self:hide(c)
    else
        self:show(c)
    end
end

function M.new(opts)
    opts = opts or {}
    local dropdown = setmetatable({
        app = opts.app or "xterm",
        name = opts.name or "QuakeDD",
        width = opts.width or 1,
        height = opts.height or 0.25,
        position = opts.position or "top",
        overlap = opts.overlap or false,
        visible = false,
        pending_spawn = false,
    }, Dropdown)

    client.connect_signal("manage", function(c)
        if client_matches(dropdown.name)(c) and dropdown.pending_spawn then
            dropdown.pending_spawn = false
            dropdown:show(c)
        end
    end)

    client.connect_signal("unmanage", function(c)
        if client_matches(dropdown.name)(c) then
            dropdown.visible = false
        end
    end)

    return dropdown
end

return M
