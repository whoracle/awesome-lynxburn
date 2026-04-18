local os = os
local ipairs = ipairs
local helpers = require("config.helpers")
local config_data = require("config.config_data")

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

    for _, candidate in ipairs({
        "alacritty",
        "kitty",
        "urxvt",
        "xterm",
        "x-terminal-emulator",
    }) do
        if command_exists(candidate) then
            return candidate
        end
    end

    return configured
end

---External command definitions and runtime command configuration.
---
---When changing command-line tools, launchers, screenshot tooling, brightness
---control, or Redshift parameters, this is usually the first file to edit.
local programs = helpers.deep_merge({}, config_data.commands())

programs.terminal = resolve_terminal(programs.terminal)

return programs
