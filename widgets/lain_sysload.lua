local lain = require("lain")

local metric = require("widgets.lain_metric")

return function(context)
    local theme = (context and context.beautiful) or require("beautiful")
    local icon = metric.icon(theme.icon_sysload)

    local sysload = lain.widget.sysload({
        settings = function()
            local load_p = ""

            if tonumber(load_1) >= 8 then
                load_p = metric.font(theme, (theme.space or " ") .. load_1 .. (theme.space or " "))
                metric.show(icon)
            else
                metric.hide(icon)
            end

            widget:set_markup(load_p)
        end,
    })

    return metric.wrap(context, icon, sysload.widget).metric
end
