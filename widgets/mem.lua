local metric = require("widgets.metric")
local system_metrics = require("widgets.system_metrics")

return function(context)
    local theme = (context and context.beautiful) or require("beautiful")
    local icon = metric.icon(theme.icon_mem)
    local widget = require("wibox").widget.textbox()

    system_metrics.watch(2, function()
        local percent = system_metrics.memory()
        local mem_p = ""

        if percent and percent >= 75 then
            mem_p = metric.font(
                theme,
                (theme.space or " ") .. percent .. metric.color(theme, "%" .. (theme.space or " "))
            )
            metric.show(icon)
        else
            metric.hide(icon)
        end

        widget:set_markup(mem_p)
    end)

    return metric.wrap(context, icon, widget).metric
end
