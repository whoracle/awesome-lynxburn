return {
    -- settings = {
    --     modkey = "Mod4",
    --     monitors = {
    --         left = 1,
    --         center = 2,
    --         right = 3,
    --     },
    -- },
    -- theme = {
    --     name = "lynxburn2",
    -- },
    -- widgets = {
    --     order = {
    --         "network",
    --         "audio",
    --         "notify",
    --     },
    --     modules = {
    --         network = {
    --             enabled = true,
    --             -- cycle = false,
    --         },
    --     },
    -- },
    -- commands = {
    --     terminal = "alacritty",
    -- },
    commands = {
        autostart_once = {
            "nm-applet --sm-disable",
            "nextcloud",
        },
        redshift = {
            enabled = true,
            autostart = true,
            latitude = 47.9990,
            longitude = 7.8421,
            temperature_day = 6500,
            temperature_night = 4500,
        },
    },
}
