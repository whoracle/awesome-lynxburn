local lain = require("lain")

local metric = require("widgets.lain_metric")

return function(context)
    local theme = (context and context.beautiful) or require("beautiful")
    local icon = metric.icon(theme.icon_mem)

    local mem = lain.widget.mem({
        settings = function()
            local mem_p = ""

            if mem_now.perc >= 75 then
                mem_p = metric.font(
                    theme,
                    (theme.space or " ") .. mem_now.perc .. metric.color(theme, "%" .. (theme.space or " "))
                )
                metric.show(icon)
            else
                metric.hide(icon)
            end

            widget:set_markup(mem_p)
        end,
    })

    return metric.wrap(context, icon, mem.widget).metric
end
