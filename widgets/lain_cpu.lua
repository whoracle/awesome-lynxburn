local metric = require("widgets.lain_metric")
local system_metrics = require("widgets.system_metrics")

return function(context)
    local theme = (context and context.beautiful) or require("beautiful")
    local icon = metric.icon(theme.icon_cpu)
    local widget = require("wibox").widget.textbox()
    local read_cpu = system_metrics.cpu_reader()

    system_metrics.watch(2, function()
        local usage = read_cpu()
        local cpu_p = ""

        if usage and usage >= 75 then
            cpu_p = (theme.space or " ") .. usage .. metric.color(theme, "%" .. (theme.space or " "))
            metric.show(icon)
        else
            metric.hide(icon)
        end

        widget:set_markup(cpu_p)
    end)

    return metric.wrap(context, icon, widget).metric
end
