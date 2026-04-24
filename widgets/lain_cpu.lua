local lain = require("lain")

local metric = require("widgets.lain_metric")

return function(context)
    local theme = (context and context.beautiful) or require("beautiful")
    local built

    local cpu = lain.widget.cpu({
        settings = function()
            local cpu_p = ""

            if cpu_now.usage >= 75 then
                cpu_p = (theme.space or " ") .. cpu_now.usage .. metric.color(theme, "%" .. (theme.space or " "))
                metric.show(built.icon)
            else
                metric.hide(built.icon)
            end

            widget:set_markup(cpu_p)
        end,
    })

    built = metric.build(context, theme.icon_cpu, cpu.widget)
    return built.metric
end
