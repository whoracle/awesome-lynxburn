local os = os

local awful = require("awful")
local helpers = require("config.helpers")
local config_theme = require("config.theme")
local structure = require("themes.lynxburn.structure")

local theme_dir = os.getenv("HOME") .. "/.config/awesome/themes/lynxburn"
local zenburn_dir = awful.util.get_themes_dir() .. "zenburn"

local function load_color_scheme(name)
    local ok, scheme = pcall(require, "themes.lynxburn.colors." .. name)
    if ok then
        return scheme
    end

    return require("themes.lynxburn.colors.lynxburn")
end

local scheme_name = config_theme.color_scheme()
local scheme = load_color_scheme(scheme_name).build()
local theme = {}

helpers.deep_merge(theme, structure.build({
    fonts = scheme.fonts,
    theme_dir = theme_dir,
    zenburn_dir = zenburn_dir,
}))
helpers.deep_merge(theme, scheme.theme)

local theme_overrides = config_theme.overrides()
local custom_at_screen_connect = theme_overrides.at_screen_connect

theme_overrides.at_screen_connect = nil
helpers.deep_merge(theme, theme_overrides)

theme.at_screen_connect = require("themes.lynxburn.widgets").build(theme)

if custom_at_screen_connect then
    theme.at_screen_connect = custom_at_screen_connect
end

return theme
