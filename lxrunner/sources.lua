local awful = require("awful")
local config_data = require("config.config_data")

local util = require("lxcommon.util")

local M = {}

local DESKTOP_ENTRY_DIRS = {
    function()
        return (os.getenv("XDG_DATA_HOME") or ((os.getenv("HOME") or "") .. "/.local/share")) .. "/applications"
    end,
    function()
        return (os.getenv("HOME") or "") .. "/.local/share/flatpak/exports/share/applications"
    end,
    function()
        return "/var/lib/flatpak/exports/share/applications"
    end,
}

local function configured_runner_aliases()
    local lxmodules = config_data.lxmodules()
    local runner = lxmodules.lxrunner or {}

    if type(runner.aliases) ~= "table" then
        return {}
    end

    return runner.aliases
end

local function split_path(path_value)
    local parts = {}

    for part in tostring(path_value or ""):gmatch("[^:]+") do
        table.insert(parts, part)
    end

    return parts
end

local function desktop_entry_dirs()
    local dirs = {}
    local seen = {}

    for _, dir_fn in ipairs(DESKTOP_ENTRY_DIRS) do
        local dir = dir_fn()

        if dir ~= "" and not seen[dir] then
            seen[dir] = true
            table.insert(dirs, dir)
        end
    end

    local data_dirs = os.getenv("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"

    for _, base_dir in ipairs(split_path(data_dirs)) do
        local dir = base_dir .. "/applications"

        if not seen[dir] then
            seen[dir] = true
            table.insert(dirs, dir)
        end
    end

    return dirs
end

local function shell_escape(s)
    s = tostring(s or "")
    return "'" .. s:gsub("'", [["'"']]) .. "'"
end

local function upsert_alias(target, alias)
    for index, existing in ipairs(target) do
        if existing.name == alias.name then
            target[index] = alias
            return
        end
    end

    table.insert(target, alias)
end

local function build_env_prefix(env)
    if type(env) ~= "table" then
        return ""
    end

    local parts = {}

    for key, value in pairs(env) do
        if type(key) == "string" and key:match("^[%a_][%w_]*$") then
            table.insert(parts, string.format("%s=%s", key, shell_escape(value)))
        end
    end

    table.sort(parts)

    if #parts == 0 then
        return ""
    end

    return table.concat(parts, " ") .. " "
end

local function desktop_id_from_path(path)
    local name = tostring(path or ""):match("([^/]+)%.desktop$")
    return name or ""
end

local function sanitize_desktop_exec(command)
    local exec = util.trim(command)

    if exec == "" then
        return ""
    end

    exec = exec:gsub("%%%%", "\0")
    exec = exec:gsub("%%%b{}", "")
    exec = exec:gsub("%%[fFuUdDnNickvm]", "")
    exec = exec:gsub("\0", "%%")
    exec = util.trim(exec)

    return exec
end

local function parse_desktop_entry(path)
    local handle = io.open(path, "r")
    if not handle then
        return nil
    end

    local in_desktop_entry = false
    local fields = {}

    for line in handle:lines() do
        local section = line:match("^%[([^%]]+)%]$")
        if section then
            in_desktop_entry = section == "Desktop Entry"
        elseif in_desktop_entry then
            local key, value = line:match("^([%w%-]+)%s*=%s*(.-)%s*$")
            if key and value then
                fields[key] = value
            end
        end
    end

    handle:close()

    if fields.Type ~= "Application" then
        return nil
    end

    if fields.Hidden == "true" or fields.NoDisplay == "true" then
        return nil
    end

    local name = util.trim(fields.Name)
    local exec = sanitize_desktop_exec(fields.Exec)
    if name == "" or exec == "" then
        return nil
    end

    if fields.Terminal == "true" then
        exec = string.format("%s -e %s", awful.util.terminal or "xterm", shell_escape(exec))
    end

    return {
        name = name,
        display = name,
        command = exec,
        desktop_id = desktop_id_from_path(path),
        source = "desktop",
    }
end

local function expand_template(command, arg_tail)
    if command:find("%%s") then
        return command:gsub("%%s", arg_tail)
    end

    return command
end

---Attach alias, PATH, and desktop-entry source helpers to lxrunner.
function M.extend(instance_methods)
    ---Reload configured aliases from `lxmodules.lxrunner.aliases`.
    function instance_methods:_load_aliases()
        self._aliases = {}

        for _, alias in ipairs(configured_runner_aliases()) do
            if type(alias) == "table"
                and type(alias.name) == "string"
                and alias.name ~= ""
                and type(alias.command) == "string"
                and alias.command ~= ""
            then
                upsert_alias(self._aliases, {
                    name = alias.name,
                    type = alias.type or "shell",
                    command = alias.command,
                    env = alias.env,
                    icon = alias.icon,
                    glyph = alias.glyph,
                    glyph_font = alias.glyph_font,
                    description = alias.description,
                    source = "alias",
                })
            end
        end
    end

    ---Cache executable names from the current PATH once per runner instance.
    function instance_methods:_load_path_commands()
        local seen = {}
        local commands = {}

        for _, dir in ipairs(split_path(os.getenv("PATH"))) do
            local cmd = string.format(
                "find %s -maxdepth 1 -type f -executable -printf '%%f\\n' 2>/dev/null",
                shell_escape(dir)
            )
            local handle = io.popen(cmd)

            if handle then
                for line in handle:lines() do
                    if line ~= "" and not seen[line] then
                        seen[line] = true
                        table.insert(commands, {
                            name = line,
                            display = line,
                            command = line,
                            source = "path",
                        })
                    end
                end

                handle:close()
            end
        end

        table.sort(commands, function(a, b)
            return a.name < b.name
        end)

        self._path_commands = commands
    end

    ---Lazy-load PATH command discovery on first use.
    function instance_methods:_ensure_path_commands()
        if not self._path_commands then
            self:_load_path_commands()
        end
    end

    ---Scan desktop-entry directories and keep only visible application launchers.
    function instance_methods:_load_desktop_entries()
        local seen = {}
        local entries = {}

        for _, dir in ipairs(desktop_entry_dirs()) do
            local cmd = string.format(
                "find %s -type f -name '*.desktop' 2>/dev/null",
                shell_escape(dir)
            )
            local handle = io.popen(cmd)

            if handle then
                for path in handle:lines() do
                    local entry = parse_desktop_entry(path)

                    if entry then
                        local key = entry.desktop_id ~= "" and entry.desktop_id or path

                        if not seen[key] then
                            seen[key] = true
                            table.insert(entries, entry)
                        end
                    end
                end

                handle:close()
            end
        end

        table.sort(entries, function(a, b)
            return a.name < b.name
        end)

        self._desktop_entries = entries
    end

    ---Lazy-load desktop-entry discovery on first use.
    function instance_methods:_ensure_desktop_entries()
        if not self._desktop_entries then
            self:_load_desktop_entries()
        end
    end

    ---Resolve an alias into the concrete command line shown/launched for the current input.
    function instance_methods:_resolved_alias_entry(alias, raw_input, arg_tail)
        local resolved_command = alias.command
        local env_prefix = build_env_prefix(alias.env)
        local display_name = alias.name
        local display_text = alias.name

        if alias.type == "template" then
            resolved_command = expand_template(alias.command, arg_tail)
            if util.trim(raw_input) ~= "" then
                display_name = util.trim(raw_input)
            end

            if arg_tail ~= "" then
                display_text = string.format("%s -> %s", display_name, env_prefix .. resolved_command)
            end
        end

        resolved_command = env_prefix .. resolved_command

        return {
            name = display_name,
            display = display_text,
            command = resolved_command,
            source = "alias",
            alias_name = alias.name,
            icon = alias.icon,
            glyph = alias.glyph,
            glyph_font = alias.glyph_font,
        }
    end
end

return M
