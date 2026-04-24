local lain = require("lain")

local metric = require("widgets.lain_metric")

return function(context)
    local theme = (context and context.beautiful) or require("beautiful")
    local built

    local mem = lain.widget.mem({
        settings = function()
            local mem_p = ""

            if mem_now.perc >= 75 then
                mem_p = metric.font(
                    theme,
                    (theme.space or " ") .. mem_now.perc .. metric.color(theme, "%" .. (theme.space or " "))
                )
                metric.show(built.icon)
            else
                metric.hide(built.icon)
            end

            widget:set_markup(mem_p)
        end,
    })

    built = metric.build(context, theme.icon_mem, mem.widget)
    return built.metric
end
