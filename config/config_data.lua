local helpers = require("config.helpers")
local defaults = require("config.defaults")

local M = {}

local cached_commands
local cached_settings
local cached_theme
local cached_widgets

local function load_override_settings()
    return helpers.load_optional_module("config.override.settings", {})
end

local function load_override_programs()
    return helpers.load_optional_module("config.override.programs", {})
end

local function load_override_config()
    return helpers.load_optional_module("config.override.config", {})
end

local function merge_section(merged, key, value)
    if type(value) ~= "table" or next(value) == nil then
        return
    end

    helpers.deep_merge(merged, {
        [key] = value,
    })
end

local function merge_widget_overrides(merged)
    local override_settings = load_override_settings()
    local override_config = load_override_config()

    merge_section(merged, "widgets", override_settings.widgets)
    merge_section(merged, "widgets", override_config.widgets)
end

local function merge_command_overrides(merged)
    local override_settings = load_override_settings()
    local override_programs = load_override_programs()
    local override_config = load_override_config()

    merge_section(merged, "commands", override_settings.commands)
    merge_section(merged, "commands", override_programs)
    merge_section(merged, "commands", override_config.commands)
end

local function merge_theme_overrides(merged)
    local override_settings = load_override_settings()
    local override_config = load_override_config()

    if override_settings.theme_name ~= nil then
        helpers.deep_merge(merged, {
            theme = {
                name = override_settings.theme_name,
            },
        })
    end

    merge_section(merged, "theme", override_config.theme)
end

local function merge_settings_overrides(merged)
    local override_settings = load_override_settings()
    local override_config = load_override_config()
    local settings_override = {}

    for _, key in ipairs({
        "modkey",
        "altkey",
        "ctrlkey",
        "shiftkey",
        "workspaces",
        "volume_step",
        "monitors",
    }) do
        if override_settings[key] ~= nil then
            settings_override[key] = override_settings[key]
        end
    end

    merge_section(merged, "settings", settings_override)
    merge_section(merged, "settings", override_config.settings)
end

local function load_commands()
    if cached_commands then
        return cached_commands
    end

    local merged = helpers.deep_merge({}, {
        commands = defaults.commands,
    })

    merge_command_overrides(merged)

    cached_commands = merged.commands or {}
    return cached_commands
end

local function load_widgets()
    if cached_widgets then
        return cached_widgets
    end

    local merged = helpers.deep_merge({}, {
        widgets = defaults.widgets,
    })

    merge_widget_overrides(merged)

    cached_widgets = merged.widgets or {}
    return cached_widgets
end

function M.commands()
    return load_commands()
end

local function load_settings()
    if cached_settings then
        return cached_settings
    end

    local merged = helpers.deep_merge({}, {
        settings = defaults.settings,
    })

    merge_settings_overrides(merged)

    cached_settings = merged.settings or {}
    return cached_settings
end

function M.settings()
    return load_settings()
end

local function load_theme()
    if cached_theme then
        return cached_theme
    end

    local merged = helpers.deep_merge({}, {
        theme = defaults.theme,
    })

    merge_theme_overrides(merged)

    cached_theme = merged.theme or {}
    return cached_theme
end

function M.theme()
    return load_theme()
end

function M.widgets()
    return load_widgets()
end

return M
