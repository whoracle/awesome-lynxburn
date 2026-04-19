local awful = require("awful")

local M = {}

---Resolve the target screen from an anchor geometry or explicit screen field.
function M.resolve_screen(anchor)
    if type(anchor) == "table" then
        if anchor.screen then
            return anchor.screen
        end

        if anchor.x and anchor.y then
            local screen_index = awful.screen.getbycoord(anchor.x, anchor.y)
            if screen_index then
                return screen[screen_index]
            end
        end
    end

    return awful.screen.focused()
end

return M
