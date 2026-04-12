local os = os

return {
    theme_name = "lynxburn2",
    modkey = "Mod4",
    altkey = "Mod1",
    ctrlkey = "Control",
    shiftkey = "Shift",
    editor = os.getenv("EDITOR") or "vim",
    home = os.getenv("HOME"),
    workspaces = { "primary", "secondary", "tertiary" },
    volume_step = 5,
    monitors = {
        left = 3,
        center = 1,
        right = 2,
    },
}
