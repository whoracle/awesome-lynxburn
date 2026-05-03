local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local helpers = require("config.helpers")
local config_theme = require("config.theme")
local structure = require("themes.lynxburn.structure")

local theme_dir = gears.filesystem.get_configuration_dir() .. "themes/lynxburn"
local zenburn_dir = awful.util.get_themes_dir() .. "zenburn"
local DEFAULT_COLOR_SCHEME = "lynxburn"
local AVAILABLE_COLOR_SCHEMES = {
    "lynxburn",
    "nord",
    "zenburn",
    "catppuccin",
    "solarized_light",
    "solarized_dark",
    "kanagawa_wave",
    "kanagawa_dragon",
    "kanagawa_lotus",
}
local COLOR_SCHEME_ALIASES = {
    default = DEFAULT_COLOR_SCHEME,
}

local function load_color_scheme(name)
    local requested = tostring(name or "")
    local resolved = COLOR_SCHEME_ALIASES[requested] or requested
    local ok, scheme = pcall(require, "themes.lynxburn.colors." .. resolved)
    if ok then
        return scheme, resolved, nil
    end

    local available = table.concat(AVAILABLE_COLOR_SCHEMES, "\n  ")
    local message = string.format(
        "Theme not found.\nConfigured theme: %s\nAvailable Themes:\n  %s\n\nFalling back to default theme %s.",
        requested ~= "" and requested or "<empty>",
        available,
        DEFAULT_COLOR_SCHEME
    )

    return require("themes.lynxburn.colors." .. DEFAULT_COLOR_SCHEME), DEFAULT_COLOR_SCHEME, message
end

local scheme_name = config_theme.color_scheme()
local scheme_module, resolved_scheme_name, theme_warning = load_color_scheme(scheme_name)
local scheme = scheme_module.build()
local theme = {}

if theme_warning then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Invalid color scheme",
        text = theme_warning,
    })
end

helpers.deep_merge(theme, structure.build({
    fonts = scheme.fonts,
    theme_dir = theme_dir,
    zenburn_dir = zenburn_dir,
}))
helpers.deep_merge(theme, scheme.theme)
theme.color_scheme = resolved_scheme_name

local theme_overrides = config_theme.overrides()
local custom_at_screen_connect = theme_overrides.at_screen_connect

theme_overrides.at_screen_connect = nil
helpers.deep_merge(theme, theme_overrides)

theme.at_screen_connect = require("themes.lynxburn.widgets").build(theme)

if custom_at_screen_connect then
    theme.at_screen_connect = custom_at_screen_connect
end

return theme
