local gears = require("gears")

local M = {}

local function escape(text)
    return gears.string.xml_escape(tostring(text or ""))
end

function M.color(color, text)
    return string.format("<span foreground='%s'>%s</span>", escape(color), escape(text))
end

function M.font(font, text)
    return string.format("<span font_desc='%s'>%s</span>", escape(font), escape(text))
end

function M.bold(text)
    return string.format("<b>%s</b>", escape(text))
end

return setmetatable(M, {
    __call = function(_, color, text)
        return M.color(color, text)
    end,
})
