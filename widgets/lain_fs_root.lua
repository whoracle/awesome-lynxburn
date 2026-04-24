local lain = require("lain")

local metric = require("widgets.lain_metric")

return function(context)
    local theme = (context and context.beautiful) or require("beautiful")
    local icon = metric.icon(theme.icon_fs)

    local fs_root = lain.widget.fs({
        partition = "/",
        threshold = 95,
        followtag = true,
        settings = function()
            local fs_p = ""
            local root_fs = fs_now["/"]

            if root_fs and root_fs.percentage >= 90 then
                fs_p = metric.font(
                    theme,
                    (theme.space or " ")
                        .. metric.color(theme, "root ")
                        .. root_fs.percentage
                        .. metric.color(theme, "%" .. (theme.space or " "))
                )
                metric.show(icon)
            else
                metric.hide(icon)
            end

            widget:set_markup(fs_p)
        end,
    })

    return metric.wrap(context, icon, fs_root.widget).metric
end
