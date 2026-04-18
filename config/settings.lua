local os = os
local config_data = require("config.config_data")
local theme_config = require("config.theme")

local static_settings = config_data.settings()
local static_tags = config_data.tags()
local tag_names = {}

for _, tag_name in ipairs(static_tags.order or {}) do
    tag_names[#tag_names + 1] = tag_name
end

---Static user-facing settings that are referenced across the config.
---
---Keep machine-specific and preference-style values here instead of scattering
---them across multiple modules.
local settings = {
    theme_name = theme_config.name(),
    modkey = static_settings.modkey,
    altkey = static_settings.altkey,
    ctrlkey = static_settings.ctrlkey,
    shiftkey = static_settings.shiftkey,
    editor = os.getenv("EDITOR") or "vim",
    home = os.getenv("HOME"),
    tags = tag_names,
    volume_step = static_settings.volume_step,
    monitors = static_settings.monitors,
    widgets = config_data.widgets(),
}

return settings
