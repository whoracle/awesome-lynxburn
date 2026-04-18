local helpers = require("config.helpers")
local defaults = require("config.defaults")

local M = {}

local cached_widgets

local function load_widgets()
    if cached_widgets then
        return cached_widgets
    end

    local merged = helpers.deep_merge({}, {
        widgets = defaults.widgets,
    })
    local override_settings = helpers.load_optional_module("config.override.settings", {})
    local override_config = helpers.load_optional_module("config.override.config", {})

    helpers.deep_merge(merged, {
        widgets = override_settings.widgets,
    })
    helpers.deep_merge(merged, override_config)

    cached_widgets = merged.widgets or {}
    return cached_widgets
end

function M.widgets()
    return load_widgets()
end

return M
