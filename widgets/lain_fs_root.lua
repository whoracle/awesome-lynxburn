local lain = require("lain")

local metric = require("widgets.lain_metric")

return function(context)
    local theme = (context and context.beautiful) or require("beautiful")
    local built

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
                metric.show(built.icon)
            else
                metric.hide(built.icon)
            end

            widget:set_markup(fs_p)
        end,
    })

    built = metric.build(context, theme.icon_fs, fs_root.widget)
    return built.metric
end
