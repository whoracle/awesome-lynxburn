local wibox = require("wibox")

return function()
    return {
        widget = wibox.widget.systray(),
    }
end
