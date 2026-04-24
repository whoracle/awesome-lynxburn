local lain = require("lain")

local metric = require("widgets.lain_metric")

return function(context)
    local theme = (context and context.beautiful) or require("beautiful")
    local built

    local sysload = lain.widget.sysload({
        settings = function()
            local load_p = ""

            if tonumber(load_1) >= 8 then
                load_p = metric.font(theme, (theme.space or " ") .. load_1 .. (theme.space or " "))
                metric.show(built.icon)
            else
                metric.hide(built.icon)
            end

            widget:set_markup(load_p)
        end,
    })

    built = metric.build(context, theme.icon_sysload, sysload.widget)
    return built.metric
end
