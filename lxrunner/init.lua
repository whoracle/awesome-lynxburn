local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

local M = {}
M.__index = M

local DEFAULTS = {
    width = function()
        return beautiful.lxrunner_width or 520
    end,
    row_count = function()
        return beautiful.lxrunner_row_count or 5
    end,
    history_limit = function()
        return beautiful.lxrunner_history_limit or 5
    end,
    history_file = function()
        return (os.getenv("HOME") or "") .. "/.lxrunner_history"
    end,
    prompt = "Run",
}

local function trim(s)
    s = tostring(s or "")
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function split_path(path_value)
    local parts = {}

    for part in tostring(path_value or ""):gmatch("[^:]+") do
        table.insert(parts, part)
    end

    return parts
end

local function shell_escape(s)
    s = tostring(s or "")
    return "'" .. s:gsub("'", [["'"']]) .. "'"
end

local function escape_field(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\")
    s = s:gsub("\t", "\\t")
    s = s:gsub("\n", "\\n")
    return s
end

local function unescape_field(s)
    s = tostring(s or "")
    s = s:gsub("\\n", "\n")
    s = s:gsub("\\t", "\t")
    s = s:gsub("\\\\", "\\")
    return s
end

local function resolve_default(value)
    if type(value) == "function" then
        return value()
    end

    return value
end

local function merge_defaults(opts)
    opts = opts or {}

    local merged = {}
    for k, v in pairs(DEFAULTS) do
        merged[k] = resolve_default(v)
    end

    for k, v in pairs(opts) do
        merged[k] = v
    end

    return merged
end

local function build_row(text, selected, icon)
    local fg = selected
        and (beautiful.lxrunner_row_selected_fg or beautiful.fg_focus or "#ffffff")
        or (beautiful.lxrunner_row_fg or beautiful.fg_normal or "#bbbbbb")

    local icon_widget
    if icon then
        icon_widget = wibox.widget({
            image = gears.color.recolor_image(icon, fg),
            resize = true,
            forced_width = beautiful.lxrunner_icon_size or 14,
            forced_height = beautiful.lxrunner_icon_size or 14,
            widget = wibox.widget.imagebox,
        })
    else
        icon_widget = wibox.widget({
            text = "",
            forced_width = beautiful.lxrunner_icon_size or 14,
            forced_height = beautiful.lxrunner_icon_size or 14,
            widget = wibox.widget.textbox,
        })
    end

    return wibox.widget({
        {
            icon_widget,
            {
                {
                    text = text,
                    align = "left",
                    valign = "center",
                    font = beautiful.lxrunner_row_font or beautiful.font,
                    widget = wibox.widget.textbox,
                },
                left = beautiful.lxrunner_icon_text_spacing or 8,
                widget = wibox.container.margin,
            },
            left = beautiful.lxrunner_row_padding or 10,
            right = beautiful.lxrunner_row_padding or 10,
            top = 4,
            bottom = 4,
            layout = wibox.layout.fixed.horizontal,
        },
        bg = selected
            and (beautiful.lxrunner_row_selected_bg or beautiful.bg_focus or "#444444")
            or (beautiful.lxrunner_row_bg or beautiful.bg_normal or "#222222"),
        fg = fg,
        widget = wibox.container.background,
    })
end

local function normalize_query(query)
    return tostring(query or ""):lower()
end

local function command_matches(name, query)
    if query == "" then
        return false
    end

    local lower_name = name:lower()

    if lower_name:sub(1, #query) == query then
        return 0
    end

    local start_at = lower_name:find(query, 1, true)
    if start_at then
        return start_at
    end

    return nil
end

local function split_alias_query(input)
    local trimmed = trim(input)
    local alias_name, arg_tail = trimmed:match("^(%S+)%s*(.*)$")

    return alias_name or "", trim(arg_tail or "")
end

local function expand_template(command, arg_tail)
    if command:find("%%s") then
        return command:gsub("%%s", arg_tail)
    end

    return command
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

local function longest_common_prefix(values)
    if #values == 0 then
        return ""
    end

    local prefix = values[1]

    for i = 2, #values do
        local value = values[i]
        local max_len = math.min(#prefix, #value)
        local j = 1

        while j <= max_len and prefix:sub(j, j) == value:sub(j, j) do
            j = j + 1
        end

        prefix = prefix:sub(1, j - 1)

        if prefix == "" then
            break
        end
    end

    return prefix
end

function M:_set_placeholder_rows()
    local rows = {
        "Type to search PATH commands",
        "Recent commands will appear here",
        "Alias support comes next",
        "Desktop entries are a later stage",
        "Escape closes the runner",
    }

    self._results:reset()

    for i = 1, self.opts.row_count do
        self._results:add(build_row(rows[i] or "", i == 1))
    end
end

function M:_icon_for_entry(entry)
    if not entry then
        return nil
    end

    local source = entry.source == "history" and entry.launch_source or entry.source

    if source == "path" then
        return self._icons.path
    end

    if source == "alias" then
        return self._icons.alias
    end

    if source == "desktop" then
        return self._icons.desktop
    end

    return nil
end

function M:_load_history()
    self._history = {}

    local handle = io.open(self.opts.history_file, "r")
    if not handle then
        return
    end

    for line in handle:lines() do
        local ts, launch_source, name, command = line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$")
        if ts and launch_source and name and command then
            table.insert(self._history, {
                last_used = tonumber(ts) or 0,
                launch_source = launch_source,
                name = unescape_field(name),
                command = unescape_field(command),
                source = "history",
            })
        else
            ts, name, command = line:match("^([^\t]*)\t([^\t]*)\t(.*)$")
            if ts and name and command then
                table.insert(self._history, {
                    last_used = tonumber(ts) or 0,
                    name = unescape_field(name),
                    command = unescape_field(command),
                    source = "history",
                })
            end
        end
    end

    handle:close()
end

function M:_load_aliases()
    self._aliases = {}

    local path = gears.filesystem.get_configuration_dir() .. "lxrunner/aliases.lua"
    local ok, aliases = pcall(dofile, path)

    if not ok or type(aliases) ~= "table" then
        return
    end

    for _, alias in ipairs(aliases) do
        if type(alias) == "table"
            and type(alias.name) == "string"
            and alias.name ~= ""
            and type(alias.command) == "string"
            and alias.command ~= ""
        then
            table.insert(self._aliases, {
                name = alias.name,
                type = alias.type or "shell",
                command = alias.command,
                env = alias.env,
                description = alias.description,
                source = "alias",
            })
        end
    end
end

function M:_save_history()
    local handle = io.open(self.opts.history_file, "w")
    if not handle then
        return
    end

    for i = 1, math.min(#self._history, self.opts.history_limit) do
        local entry = self._history[i]
        handle:write(string.format(
            "%s\t%s\t%s\t%s\n",
            tostring(entry.last_used or 0),
            tostring(entry.launch_source or entry.source or ""),
            escape_field(entry.name),
            escape_field(entry.command)
        ))
    end

    handle:close()
end

function M:_record_history(entry)
    if not entry or not entry.command or entry.command == "" then
        return
    end

    local updated = {
        name = entry.name or entry.command,
        command = entry.command,
        source = "history",
        launch_source = entry.source,
        last_used = os.time(),
    }

    local new_history = { updated }

    for _, existing in ipairs(self._history) do
        if existing.command ~= updated.command then
            table.insert(new_history, existing)
        end
    end

    while #new_history > self.opts.history_limit do
        table.remove(new_history)
    end

    self._history = new_history
    self:_save_history()
end

function M:_load_path_commands()
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

function M:_ensure_path_commands()
    if not self._path_commands then
        self:_load_path_commands()
    end
end

function M:_filter_matches()
    local query = normalize_query(self._input)
    local alias_query, arg_tail = split_alias_query(self._input)
    local normalized_alias_query = normalize_query(alias_query)
    self._matches = {}
    self._selected_index = 1

    if query == "" then
        return
    end

    self:_ensure_path_commands()

    local ranked = {}

    for _, entry in ipairs(self._path_commands) do
        local rank = command_matches(entry.name, query)
        if rank ~= nil then
            table.insert(ranked, {
                rank = rank,
                name = entry.name,
                display = entry.display or entry.name,
                command = entry.command,
                source = entry.source,
            })
        end
    end

    for _, alias in ipairs(self._aliases) do
        local rank = command_matches(alias.name, normalized_alias_query)
        if rank ~= nil then
            local resolved_command = alias.command
            local env_prefix = build_env_prefix(alias.env)
            local display_name = alias.name
            local display_text = alias.name

            if alias.type == "template" then
                resolved_command = expand_template(alias.command, arg_tail)
                if trim(self._input) ~= "" then
                    display_name = trim(self._input)
                end

                if arg_tail ~= "" then
                    display_text = string.format("%s -> %s", display_name, env_prefix .. resolved_command)
                end
            end

            resolved_command = env_prefix .. resolved_command

            table.insert(ranked, {
                rank = rank - 1000,
                name = display_name,
                display = display_text,
                command = resolved_command,
                source = "alias",
                alias_name = alias.name,
            })
        end
    end

    table.sort(ranked, function(a, b)
        if a.rank ~= b.rank then
            return a.rank < b.rank
        end

        return a.name < b.name
    end)

    for i = 1, math.min(#ranked, self.opts.row_count) do
        self._matches[i] = ranked[i]
    end
end

function M:_visible_entries()
    if self._input == "" then
        return self._history
    end

    return self._matches
end

function M:_render_results()
    self._results:reset()

    if self._input == "" then
        if #self._history == 0 then
            self:_set_placeholder_rows()
            return
        end

        for i = 1, self.opts.row_count do
            local entry = self._history[i]
            if entry then
                self._results:add(build_row(entry.name, i == self._selected_index, self:_icon_for_entry(entry)))
            else
                self._results:add(build_row("", false))
            end
        end

        return
    end

    if #self._matches == 0 then
        self._results:add(build_row("No matches", true))

        for _ = 2, self.opts.row_count do
            self._results:add(build_row("", false))
        end

        return
    end

    for i = 1, self.opts.row_count do
        local match = self._matches[i]
        if match then
            self._results:add(build_row(match.display or match.name, i == self._selected_index, self:_icon_for_entry(match)))
        else
            self._results:add(build_row("", false))
        end
    end
end

function M:_render_prompt()
    local cursor = self.visible and (beautiful.lxrunner_cursor or "_") or ""
    self._prompt:set_markup(string.format(
        '<span foreground="%s">%s</span><span foreground="%s"> %s%s</span>',
        beautiful.lxrunner_prompt_fg or beautiful.fg_focus or "#ffffff",
        gears.string.xml_escape(self.opts.prompt .. ":"),
        beautiful.lxrunner_input_fg or beautiful.fg_normal or "#ffffff",
        gears.string.xml_escape(self._input),
        gears.string.xml_escape(cursor)
    ))
end

function M:_refresh()
    self:_render_prompt()
    self:_filter_matches()
    self:_render_results()
end

function M:_move_selection(delta)
    local entries = self:_visible_entries()

    if #entries == 0 then
        return
    end

    self._selected_index = self._selected_index + delta

    if self._selected_index < 1 then
        self._selected_index = #entries
    elseif self._selected_index > #entries then
        self._selected_index = 1
    end

    self:_render_results()
end

function M:_complete_input()
    local entries = self:_visible_entries()
    local input = self._input

    if input == "" then
        local selected = entries[self._selected_index]
        if selected then
            self._input = selected.name
            self:_refresh()
        end
        return
    end

    local query_head, arg_tail = split_alias_query(input)
    local base_query = input
    local suffix = ""

    if input:find("%s") then
        base_query = query_head
        if arg_tail ~= "" then
            suffix = " " .. arg_tail
        end
    end

    local normalized_base_query = normalize_query(base_query)
    local candidates = {}

    for _, entry in ipairs(entries) do
        local candidate = entry.alias_name or entry.name
        if normalize_query(candidate):sub(1, #normalized_base_query) == normalized_base_query then
            table.insert(candidates, candidate)
        end
    end

    if #candidates == 0 then
        return
    end

    local prefix = longest_common_prefix(candidates)
    if prefix == "" or prefix == base_query then
        if #candidates == 1 and suffix == "" then
            self._input = candidates[1] .. " "
            self:_refresh()
        end
        return
    end

    self._input = prefix .. suffix
    self:_refresh()
end

function M:_launch_selected()
    local selected = self:_visible_entries()[self._selected_index]
    if not selected then
        return
    end

    awful.spawn.with_shell(selected.command)
    self:_record_history(selected)
    self:hide()
end

function M:_start_keygrabber()
    if self._keygrabber then
        self._keygrabber:stop()
    end

    self._keygrabber = awful.keygrabber({
        auto_start = false,
        stop_event = "release",
        keypressed_callback = function(_, _, key)
            if key == "Escape" then
                self:hide()
                return
            end

            if key == "Up" then
                self:_move_selection(-1)
                return
            end

            if key == "Down" then
                self:_move_selection(1)
                return
            end

            if key == "BackSpace" then
                self._input = self._input:sub(1, -2)
                self:_refresh()
                return
            end

            if key == "Tab" or key == "ISO_Left_Tab" then
                self:_complete_input()
                return
            end

            if key == "Return" or key == "KP_Enter" then
                self:_launch_selected()
                return
            end

            if #key == 1 then
                self._input = self._input .. key
                self:_refresh()
            end
        end,
    })

    self._keygrabber:start()
end

function M:_stop_keygrabber()
    if self._keygrabber then
        self._keygrabber:stop()
        self._keygrabber = nil
    end
end

function M:_start_mousegrabber()
    if self._mousegrabber_running then
        return
    end

    self._mousegrabber_running = true
    mousegrabber.run(function(mouse_state)
        if not self.visible or not self.popup.visible then
            self._mousegrabber_running = false
            return false
        end

        local geometry = self.popup:geometry()
        local inside = mouse_state.x >= geometry.x
            and mouse_state.x < geometry.x + geometry.width
            and mouse_state.y >= geometry.y
            and mouse_state.y < geometry.y + geometry.height

        if not inside and (mouse_state.buttons[1] or mouse_state.buttons[2] or mouse_state.buttons[3]) then
            self._mousegrabber_running = false
            self:hide()
            return false
        end

        return true
    end, "left_ptr")
end

function M:_stop_mousegrabber()
    if self._mousegrabber_running then
        mousegrabber.stop()
        self._mousegrabber_running = false
    end
end

function M:show()
    self.visible = true
    self._input = ""
    self._matches = {}
    self._selected_index = 1
    self:_ensure_path_commands()
    self:_load_aliases()
    self:_load_history()
    self.popup.screen = awful.screen.focused()
    self.popup.visible = true
    awful.placement.centered(self.popup, { honor_workarea = true, parent = awful.screen.focused() })
    self:_refresh()
    self:_start_keygrabber()
    self:_start_mousegrabber()
end

function M:hide()
    self.visible = false
    self.popup.visible = false
    self:_stop_keygrabber()
    self:_stop_mousegrabber()
    self:_render_prompt()
end

function M:toggle()
    if self.popup.visible then
        self:hide()
    else
        self:show()
    end
end

function M.new(opts)
    opts = merge_defaults(opts)

    local self = setmetatable({}, M)
    self.opts = opts
    self.visible = false
    self._input = ""
    self._path_commands = nil
    self._aliases = {}
    self._history = {}
    self._matches = {}
    self._selected_index = 1
    self._mousegrabber_running = false
    self._icons = {
        alias = gears.filesystem.get_configuration_dir() .. "lxrunner/icons/alias.svg",
        path = gears.filesystem.get_configuration_dir() .. "lxrunner/icons/path.svg",
        desktop = gears.filesystem.get_configuration_dir() .. "lxrunner/icons/desktop.svg",
    }

    self._prompt = wibox.widget({
        markup = "",
        font = beautiful.lxrunner_input_font or beautiful.font,
        align = "left",
        valign = "center",
        widget = wibox.widget.textbox,
    })

    self._results = wibox.layout.fixed.vertical()

    local input_box = wibox.widget({
        {
            self._prompt,
            left = beautiful.lxrunner_padding or 12,
            right = beautiful.lxrunner_padding or 12,
            top = beautiful.lxrunner_padding or 12,
            bottom = beautiful.lxrunner_padding or 12,
            widget = wibox.container.margin,
        },
        bg = beautiful.lxrunner_input_bg or beautiful.bg_focus or "#111111",
        fg = beautiful.lxrunner_input_fg or beautiful.fg_normal or "#ffffff",
        widget = wibox.container.background,
    })

    self.popup = awful.popup({
        ontop = true,
        visible = false,
        type = "splash",
        minimum_width = opts.width,
        maximum_width = opts.width,
        placement = function(c)
            awful.placement.centered(c, { honor_workarea = true })
        end,
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, beautiful.lxrunner_radius or 6)
        end,
        border_width = beautiful.lxrunner_border_width or beautiful.border_width or 1,
        border_color = beautiful.lxrunner_border_color or beautiful.border_focus or "#666666",
        bg = beautiful.lxrunner_bg or beautiful.bg_normal or "#222222",
        widget = {
            {
                input_box,
                {
                    self._results,
                    top = 8,
                    widget = wibox.container.margin,
                },
                spacing = 0,
                layout = wibox.layout.fixed.vertical,
            },
            margins = beautiful.lxrunner_outer_margin or 10,
            widget = wibox.container.margin,
        },
    })

    self:_render_prompt()
    self:_set_placeholder_rows()

    return self
end

return M
