local io = io
local os = os
local ipairs = ipairs
local pairs = pairs
local table = table
local tostring = tostring
local type = type

local config_data = require("config.config_data")
local config_input = require("config.input")
local module_config = require("config.lxmodules")
local platform = require("config.platform")
local util = require("lxcommon.util")

local M = {}

local GROUP_ORDER = {
    "core",
    "lxsecrets",
    "lxmedia",
    "lxbluetooth",
    "lxnetwork",
    "lxdisplay",
    "lxpower",
    "lxrunner",
}

local function split_words(value)
    local words = {}

    for word in tostring(value or ""):gmatch("%S+") do
        words[#words + 1] = word
    end

    return words
end

local function command_binary(command)
    for _, word in ipairs(split_words(command)) do
        if not word:match("^[%a_][%w_]*=") then
            return word
        end
    end

    return nil
end

local function executable_exists(binary)
    binary = tostring(binary or "")
    if binary == "" then
        return false
    end

    if binary:match("^~/") then
        binary = (os.getenv("HOME") or "") .. binary:sub(2)
    end

    local escaped = util.shell_escape(binary)

    if binary:find("/", 1, true) then
        local ok = os.execute("[ -x " .. escaped .. " ] >/dev/null 2>&1")
        return ok == true or ok == 0
    end

    local ok = os.execute("command -v " .. escaped .. " >/dev/null 2>&1")
    return ok == true or ok == 0
end

local function add_missing(grouped, group, item)
    if not item or item == "" then
        return
    end

    local bucket = grouped[group]
    if not bucket then
        bucket = {}
        grouped[group] = bucket
    end

    for _, existing in ipairs(bucket) do
        if existing == item then
            return
        end
    end

    bucket[#bucket + 1] = item
end

local function require_binary(grouped, group, binary)
    if not executable_exists(binary) then
        add_missing(grouped, group, binary)
    end
end

local function require_command(grouped, group, command)
    local binary = command_binary(command)
    if binary then
        require_binary(grouped, group, binary)
    end
end

local function require_any(grouped, group, binaries, label)
    for _, binary in ipairs(binaries or {}) do
        if executable_exists(binary) then
            return
        end
    end

    add_missing(grouped, group, label)
end

local function nonempty_string(value)
    return type(value) == "string" and value ~= ""
end

local function is_overridden(user_table, key)
    return type(user_table) == "table" and user_table[key] ~= nil
end

local function sorted_missing(grouped, group)
    local items = grouped[group]
    if not items then
        return nil
    end

    table.sort(items)
    return items
end

local function build_report(grouped)
    local lines = {
        "missing dependencies:",
    }

    local seen_group = {}

    for _, group in ipairs(GROUP_ORDER) do
        local items = sorted_missing(grouped, group)
        if items and #items > 0 then
            seen_group[group] = true
            lines[#lines + 1] = "  " .. group .. ":"

            for _, item in ipairs(items) do
                lines[#lines + 1] = "    " .. item
            end
        end
    end

    for group, _ in pairs(grouped) do
        if not seen_group[group] then
            local items = sorted_missing(grouped, group)
            if items and #items > 0 then
                lines[#lines + 1] = "  " .. group .. ":"

                for _, item in ipairs(items) do
                    lines[#lines + 1] = "    " .. item
                end
            end
        end
    end

    if #lines == 1 then
        return nil
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "Please check your config or install dependencies."

    return table.concat(lines, "\n")
end

local function collect_core_dependencies(grouped, commands, user_commands)
    local keyboard_command = config_input.preflight_command(config_data.settings())

    require_command(grouped, "core", commands.terminal)
    require_command(grouped, "core", commands.launcher)
    require_command(grouped, "core", commands.filebrowser)
    require_command(grouped, "core", commands.scrlocker)
    require_command(grouped, "core", keyboard_command)

    if nonempty_string(commands.browser) then
        require_command(grouped, "core", commands.browser)
    end

    if not is_overridden(user_commands, "scrotmouse") then
        if platform.effective_target() == "somewm" or platform.is_wayland() then
            require_binary(grouped, "core", "grim")
            require_binary(grouped, "core", "slurp")
        else
            require_binary(grouped, "core", "scrot")
        end
    end

    if not is_overridden(user_commands, "scrotedit") then
        if platform.effective_target() == "somewm" or platform.is_wayland() then
            require_binary(grouped, "core", "grim")
        else
            require_binary(grouped, "core", "scrot")
        end
        require_binary(grouped, "core", "xdg-open")
    end

    if not is_overridden(user_commands, "scrotwin") then
        if platform.effective_target() == "somewm" or platform.is_wayland() then
            require_binary(grouped, "core", "grim")
        else
            require_binary(grouped, "core", "scrot")
        end
        require_binary(grouped, "core", "xdg-open")
    end
end

local function collect_media_dependencies(grouped)
    require_binary(grouped, "lxmedia", "pactl")
    require_binary(grouped, "lxmedia", "playerctl")
    require_binary(grouped, "lxmedia", "pavucontrol")
end

local function collect_bluetooth_dependencies(grouped, commands)
    require_binary(grouped, "lxbluetooth", "bluetoothctl")
    require_command(grouped, "lxbluetooth", commands.blueman_manager)
end

local function collect_network_dependencies(grouped)
    require_binary(grouped, "lxnetwork", "nmcli")
end

local function collect_display_dependencies(grouped)
    local opts = module_config.options("display")
    local brightness = opts.brightness or {}
    local redshift = opts.redshift or {}
    local wayland = platform.effective_target() == "somewm" or platform.is_wayland()
    local display_command = redshift.command or (wayland and "wlr-randr" or "xrandr")
    local brightness_get = brightness.get or (wayland and "brightnessctl g" or "xbacklight -get")
    local brightness_set = brightness.set or (wayland and "brightnessctl s %d%%" or "xbacklight -set %d")
    local brightness_off = brightness.off or (wayland and "wlopm --off '*'" or "xset dpms force off")

    require_command(grouped, "lxdisplay", brightness_get)
    require_command(grouped, "lxdisplay", brightness_set)
    require_command(grouped, "lxdisplay", brightness_off)
    require_command(grouped, "lxdisplay", display_command)
end

local function collect_power_dependencies(grouped)
    require_binary(grouped, "lxpower", "powerprofilesctl")
end

local function collect_runner_dependencies(grouped)
    require_binary(grouped, "lxrunner", "find")
end

local function collect_secrets_dependencies(grouped)
    local opts = module_config.options("secrets")
    local has_vpn = false
    local needs_gitlab = false
    local needs_vault = false

    for _, secret in ipairs(opts.secrets or {}) do
        local selectors = secret.selectors or {}
        local provider = tostring(selectors.type or secret.type or "")

        if provider == "gitlab" then
            needs_gitlab = true
        elseif provider == "hashicorp_vault" or provider == "vault" then
            needs_vault = true
        end

        if type(secret.vpn) == "string" and secret.vpn ~= "" then
            has_vpn = true
        end
    end

    if needs_gitlab then
        require_binary(grouped, "lxsecrets", "curl")
        require_binary(grouped, "lxsecrets", "secret-tool")
    end

    if needs_vault then
        require_binary(grouped, "lxsecrets", "vault")
        require_binary(grouped, "lxsecrets", "secret-tool")
    end

    if has_vpn then
        require_binary(grouped, "lxsecrets", "nmcli")
        require_binary(grouped, "lxsecrets", "timeout")
    end
end

function M.collect()
    local grouped = {}
    local commands = config_data.commands()
    local user_config = config_data.user_config()
    local user_commands = user_config.commands or {}

    collect_core_dependencies(grouped, commands, user_commands)
    if module_config.enabled("secrets", false) then
        collect_secrets_dependencies(grouped)
    end
    if module_config.enabled("media", false) then
        collect_media_dependencies(grouped)
    end
    if module_config.enabled("bluetooth", false) then
        collect_bluetooth_dependencies(grouped, commands)
    end
    if module_config.enabled("network", false) then
        collect_network_dependencies(grouped)
    end
    if module_config.enabled("display", false) then
        collect_display_dependencies(grouped)
    end
    if module_config.enabled("power", false) then
        collect_power_dependencies(grouped)
    end
    collect_runner_dependencies(grouped)

    return grouped
end

function M.run(opts)
    opts = opts or {}
    local grouped = M.collect()
    local report = build_report(grouped)

    if not report then
        return false
    end

    io.stderr:write(report .. "\n")

    if opts.naughty and opts.naughty.notify then
        opts.naughty.notify({
            app_name = "LynxBurn Preflight",
            title = "Missing dependencies",
            text = report,
            urgency = "critical",
            timeout = 0,
        })
    end

    return true
end

return M
