local helpers = require("config.helpers")
local defaults = require("config.defaults")

local M = {}

local cached_commands
local cached_keys
local cached_rules
local cached_runner
local cached_settings
local cached_theme
local cached_widgets
local cached_screens

local function load_user_config()
    return helpers.load_optional_module("config", {})
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
    local user_config = load_user_config()

    merge_section(merged, "widgets", user_config.widgets)
end

local function merge_command_overrides(merged)
    local user_config = load_user_config()

    merge_section(merged, "commands", user_config.commands)
end

local function merge_key_overrides(merged)
    local user_config = load_user_config()

    merge_section(merged, "keys", user_config.keys)
end

local function merge_runner_overrides(merged)
    local user_config = load_user_config()

    merge_section(merged, "runner", user_config.runner)
end

local function merge_theme_overrides(merged)
    local user_config = load_user_config()

    merge_section(merged, "theme", user_config.theme)
end

local function merge_screen_overrides(merged)
    local user_config = load_user_config()

    merge_section(merged, "screens", user_config.screens)
end

local function merge_settings_overrides(merged)
    local user_config = load_user_config()
    merge_section(merged, "settings", user_config.settings)
end

local function merge_rule_overrides(merged)
    local user_config = load_user_config()
    local rules = user_config.rules

    if type(rules) == "function" or type(rules) == "table" then
        merged.rules = rules
    end
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

local function load_keys()
    if cached_keys then
        return cached_keys
    end

    local merged = {}

    merge_key_overrides(merged)

    cached_keys = merged.keys or {}
    return cached_keys
end

function M.keys()
    return load_keys()
end

local function load_rules()
    if cached_rules ~= nil then
        return cached_rules
    end

    local merged = {}

    merge_rule_overrides(merged)

    cached_rules = merged.rules
    return cached_rules
end

function M.rules()
    return load_rules()
end

local function load_runner()
    if cached_runner then
        return cached_runner
    end

    local merged = {}

    merge_runner_overrides(merged)

    cached_runner = merged.runner or {}
    return cached_runner
end

function M.runner()
    return load_runner()
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

local function load_screens()
    if cached_screens then
        return cached_screens
    end

    local merged = helpers.deep_merge({}, {
        screens = defaults.screens,
    })

    merge_screen_overrides(merged)

    cached_screens = merged.screens or {}
    return cached_screens
end

function M.screens()
    return load_screens()
end

function M.widgets()
    return load_widgets()
end

return M
