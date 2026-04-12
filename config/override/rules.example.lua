return function(context)
    return {
        {
            rule = { class = "Firefox" },
            properties = {
                screen = context.monitors.center,
                tag = "primary",
            },
        },
        {
            rule_any = { class = { "Pavucontrol", "Arandr" } },
            properties = {
                floating = true,
                ontop = true,
            },
        },
    }
end
