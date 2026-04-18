return {
    theme_name = "lynxburn2",
    modkey = "Mod4",
    widgets = {
        order = {
            "bluetooth",
            "network",
            "powerprofiles",
            "audio",
            "notify",
        },
        modules = {
            bluetooth = {
                enabled = true,
            },
            network = {
                enabled = true,
                -- cycle = false,
            },
            powerprofiles = {
                enabled = true,
            },
        },
    },
    monitors = {
        left = 1,
        center = 2,
        right = 3,
    },
}
