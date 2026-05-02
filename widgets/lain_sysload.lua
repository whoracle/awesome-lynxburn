local metric = require("widgets.lain_metric")
local system_metrics = require("widgets.system_metrics")

return function(context)
    local theme = (context and context.beautiful) or require("beautiful")
    local icon = metric.icon(theme.icon_sysload)
    local widget = require("wibox").widget.textbox()

    system_metrics.watch(2, function()
        local load_1 = system_metrics.loadavg()
        local load_p = ""

        if tonumber(load_1) and tonumber(load_1) >= 8 then
            load_p = metric.font(theme, (theme.space or " ") .. load_1 .. (theme.space or " "))
            metric.show(icon)
        else
            metric.hide(icon)
        end

        widget:set_markup(load_p)
    end)

    return metric.wrap(context, icon, widget).metric
end
