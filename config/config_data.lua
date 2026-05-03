local helpers = require("config.helpers")
local defaults = require("config.defaults")
local platform = require("config.platform")
local os = os
local ipairs = ipairs
local gears = require("gears")

local M = {}

local cached_sections = {}
local cached_user_config

local function load_config_file(path)
    local ok, result = pcall(dofile, path)

    if ok then
        return type(result) == "table" and result or {}
    end

    local err = tostring(result or "")
    if err:match("No such file or directory") then
        return nil
    end

    error(result)
end

local function load_user_config()
    if cached_user_config ~= nil then
        return cached_user_config
    end

    local config_dir = gears.filesystem.get_configuration_dir()
    local merged = load_config_file(config_dir .. "config.lua") or {}

    cached_user_config = merged
    return cached_user_config
end

local function shell_escape(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function first_token(command)
    return tostring(command or ""):match("^(%S+)")
end

local function command_exists(binary)
    if not binary or binary == "" then
        return false
    end

    local ok = os.execute("command -v " .. shell_escape(binary) .. " >/dev/null 2>&1")

    if type(ok) == "number" then
        return ok == 0
    end

    return ok == true
end

local function resolve_terminal(command)
    local configured = tostring(command or "")

    if command_exists(first_token(configured)) then
        return configured
    end

    local candidates = platform.is_wayland() and {
        "foot",
        "alacritty",
        "kitty",
        "xterm",
        "x-terminal-emulator",
    } or {
        "alacritty",
        "kitty",
        "urxvt",
        "xterm",
        "x-terminal-emulator",
    }

    for _, candidate in ipairs(candidates) do
        if command_exists(candidate) then
            return candidate
        end
    end

    return configured
end

local function merge_section(merged, key, value)
    if type(value) ~= "table" or next(value) == nil then
        return
    end

    helpers.deep_merge(merged, {
        [key] = value,
    })
end

local function merge_commands(merged)
    local user_config = load_user_config()

    merge_section(merged, "commands", user_config.commands)
end

local function merge_keys(merged)
    local user_config = load_user_config()

    merge_section(merged, "keys", user_config.keys)
end

local function merge_lxmodules(merged)
    local user_config = load_user_config()

    merge_section(merged, "lxmodules", user_config.lxmodules)
end

local function merge_theme(merged)
    local user_config = load_user_config()

    merge_section(merged, "theme", user_config.theme)
end

local function merge_screens(merged)
    local user_config = load_user_config()

    merge_section(merged, "screens", user_config.screens)
end

local function merge_layouts(merged)
    local user_config = load_user_config()

    merge_section(merged, "layouts", user_config.layouts)
end

local function merge_settings(merged)
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

local function load_section(name, merge_overrides)
    if cached_sections[name] then
        return cached_sections[name]
    end

    local merged = helpers.deep_merge({}, {
        [name] = defaults[name],
    })

    if merge_overrides then
        merge_overrides(merged)
    end

    cached_sections[name] = merged[name] or {}
    return cached_sections[name]
end

function M.commands()
    local commands = load_section("commands", merge_commands)
    commands.terminal = resolve_terminal(commands.terminal)
    return commands
end

function M.keys()
    return load_section("keys", merge_keys)
end

local function load_rules()
    if cached_sections.rules ~= nil then
        return cached_sections.rules
    end

    local merged = {}

    merge_rule_overrides(merged)

    cached_sections.rules = merged.rules
    return cached_sections.rules
end

function M.rules()
    return load_rules()
end

function M.lxmodules()
    return load_section("lxmodules", merge_lxmodules)
end

function M.settings()
    return load_section("settings", merge_settings)
end

function M.theme()
    return load_section("theme", merge_theme)
end

function M.screens()
    return load_section("screens", merge_screens)
end

function M.layouts()
    return load_section("layouts", merge_layouts)
end

function M.user_config()
    return load_user_config()
end

return M
