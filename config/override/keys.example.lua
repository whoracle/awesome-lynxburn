local awful = require("awful")

return {
    global = function(context)
        local settings = context.settings

        return awful.key(
            { settings.modkey },
            "Return",
            function()
                awful.spawn(context.programs.terminal)
            end,
            { description = "terminal", group = "04. programs" }
        )
    end,

    -- Use `transform` when you need to replace or reorder existing bindings.
    -- transform = function(keymaps, context)
    --     return keymaps
    -- end,
}
