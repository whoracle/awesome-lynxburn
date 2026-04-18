local os = os
local helpers = require("config.helpers")

---Static user-facing settings that are referenced across the config.
---
---Keep machine-specific and preference-style values here instead of scattering
---them across multiple modules.
local settings = {
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
    widgets = {
        order = {
            "network",
            "audio",
            "notify",
        },
        bluetooth = false,
        network = true,
        powerprofiles = false,
    },
    popup_cycle = {
        -- network = false,
    },
}

return helpers.deep_merge(
    settings,
    helpers.load_optional_module("config.override.settings", {})
)
