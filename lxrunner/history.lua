local awful = require("awful")
local gears = require("gears")
local util = require("lxcommon.util")

local M = {}

local function strip_trailing_newlines(s)
    return tostring(s or ""):gsub("[\r\n]+$", "")
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
    local trimmed = util.trim(input)
    local alias_name, arg_tail = trimmed:match("^(%S+)%s*(.*)$")

    return alias_name or "", util.trim(arg_tail or "")
end

---Attach history, ranking, and query/filter helpers to lxrunner.
function M.extend(instance_methods)
    ---Keep persisted history sorted by usage first, then recency.
    function instance_methods:_sort_history()
        table.sort(self._history, function(a, b)
            local a_count = math.max(1, tonumber(a.count) or 1)
            local b_count = math.max(1, tonumber(b.count) or 1)
            local a_used = tonumber(a.last_used) or 0
            local b_used = tonumber(b.last_used) or 0

            if a_count ~= b_count then
                return a_count > b_count
            end

            if a_used ~= b_used then
                return a_used > b_used
            end

            return tostring(a.name or "") < tostring(b.name or "")
        end)
    end

    ---Load persisted launch history from disk.
    function instance_methods:_load_history()
        self._history = {}

        local handle = io.open(self.opts.history_file, "r")
        if not handle then
            return
        end

        for line in handle:lines() do
            local ts, launch_source, count, name, command = line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$")
            if ts and launch_source and count and name and command then
                table.insert(self._history, {
                    last_used = tonumber(ts) or 0,
                    launch_source = launch_source,
                    count = math.max(1, tonumber(count) or 1),
                    name = unescape_field(name),
                    command = unescape_field(command),
                    source = "history",
                })
            else
                ts, launch_source, name, command = line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$")
                if ts and launch_source and name and command then
                    table.insert(self._history, {
                        last_used = tonumber(ts) or 0,
                        launch_source = launch_source,
                        count = 1,
                        name = unescape_field(name),
                        command = unescape_field(command),
                        source = "history",
                    })
                else
                    ts, name, command = line:match("^([^\t]*)\t([^\t]*)\t(.*)$")
                    if ts and name and command then
                        table.insert(self._history, {
                            last_used = tonumber(ts) or 0,
                            count = 1,
                            name = unescape_field(name),
                            command = unescape_field(command),
                            source = "history",
                        })
                    end
                end
            end
        end

        handle:close()
        self:_sort_history()
    end

    ---Prefer recently and frequently launched items without hiding weaker matches.
    function instance_methods:_history_rank_bonus(entry)
        local best_bonus = 0

        for index, history_entry in ipairs(self._history) do
            local same_command = history_entry.command ~= ""
                and entry.command ~= nil
                and history_entry.command == entry.command
            local same_name = history_entry.name ~= ""
                and entry.name ~= nil
                and history_entry.name == entry.name
            local same_alias = entry.alias_name ~= nil and history_entry.name == entry.alias_name

            if same_command or same_name or same_alias then
                local recency_bonus = math.max(0, (self.opts.history_limit - index + 1) * 10)
                local count_bonus = math.min(math.max(1, tonumber(history_entry.count) or 1), 50) * 2
                local bonus = recency_bonus + count_bonus

                if bonus > best_bonus then
                    best_bonus = bonus
                end
            end
        end

        return best_bonus
    end

    ---Persist the bounded history list back to disk.
    function instance_methods:_save_history()
        local handle = io.open(self.opts.history_file, "w")
        if not handle then
            return
        end

        for i = 1, math.min(#self._history, self.opts.history_limit) do
            local entry = self._history[i]
            handle:write(string.format(
                "%s\t%s\t%s\t%s\t%s\n",
                tostring(entry.last_used or 0),
                tostring(entry.launch_source or entry.source or ""),
                tostring(math.max(1, tonumber(entry.count) or 1)),
                escape_field(entry.name),
                escape_field(entry.command)
            ))
        end

        handle:close()
    end

    ---Choose the user-facing history label based on the original launch source.
    function instance_methods:_history_label(entry)
        if not entry then
            return ""
        end

        local source = entry.launch_source or entry.source

        if source == "alias" then
            return util.trim(entry.alias_name or entry.name or entry.command)
        end

        if source == "desktop" then
            return util.trim(entry.display or entry.name or entry.command)
        end

        if source == "path" then
            return util.trim(entry.name or entry.command)
        end

        return util.trim(entry.name or entry.command)
    end

    ---Move a launch to the front of history and keep the list size bounded.
    function instance_methods:_record_history(entry)
        if not entry or not entry.command or entry.command == "" then
            return
        end

        local updated = {
            name = self:_history_label(entry),
            command = entry.command,
            source = "history",
            launch_source = entry.launch_source or entry.source,
            last_used = os.time(),
            count = 1,
        }

        local existing_count = 0
        local new_history = { updated }

        for _, existing in ipairs(self._history) do
            if existing.command == updated.command then
                existing_count = math.max(existing_count, tonumber(existing.count) or 1)
            else
                table.insert(new_history, existing)
            end
        end

        updated.count = existing_count + 1

        while #new_history > self.opts.history_limit do
            table.remove(new_history)
        end

        self._history = new_history
        self:_sort_history()
        self:_save_history()
    end

    ---Rebuild the visible match list from PATH commands, desktop entries, and aliases.
    function instance_methods:_filter_matches()
        local query = normalize_query(self._input)
        local alias_query, arg_tail = split_alias_query(self._input)
        local normalized_alias_query = normalize_query(alias_query)
        self._matches = {}
        self._selected_index = 1

        if query == "" then
            return
        end

        self:_ensure_path_commands()
        self:_ensure_desktop_entries()

        local ranked = {}

        for _, entry in ipairs(self._path_commands) do
            local rank = command_matches(entry.name, query)
            if rank ~= nil then
                table.insert(ranked, {
                    rank = rank - self:_history_rank_bonus(entry),
                    name = entry.name,
                    display = entry.display or entry.name,
                    command = entry.command,
                    source = entry.source,
                })
            end
        end

        for _, entry in ipairs(self._desktop_entries) do
            local rank = command_matches(entry.name, query)
            if rank ~= nil then
                table.insert(ranked, {
                    rank = rank - self:_history_rank_bonus(entry),
                    name = entry.name,
                    display = entry.display or entry.name,
                    command = entry.command,
                    source = entry.source,
                    desktop_id = entry.desktop_id,
                })
            end
        end

        for _, alias in ipairs(self._aliases) do
            local rank = command_matches(alias.name, normalized_alias_query)
            if rank ~= nil then
                -- Aliases intentionally outrank PATH and desktop results for the same prefix.
                local entry = self:_resolved_alias_entry(alias, self._input, arg_tail)
                entry.rank = rank - 1000
                entry.rank = entry.rank - self:_history_rank_bonus(entry)
                table.insert(ranked, entry)
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

    ---Return the active result set: history while empty, filtered matches while typing.
    function instance_methods:_visible_entries()
        if self._input == "" then
            return self._history
        end

        return self._matches
    end

    ---Append literal user input and refresh the result list.
    function instance_methods:_append_input(text)
        local appended = tostring(text or "")

        if appended == "" then
            return
        end

        self._input = self._input .. appended
        self:_refresh()
    end

    ---Pick a backend for primary-selection paste if one is available.
    function instance_methods:_primary_selection_command()
        if util.command_exists("xclip") then
            return "xclip -o -selection primary 2>/dev/null"
        end

        if util.command_exists("xsel") then
            return "xsel -o -p 2>/dev/null"
        end

        return nil
    end

    ---Paste X11 primary selection into the prompt without closing the runner.
    function instance_methods:_paste_primary_selection()
        local command = self:_primary_selection_command()

        if not command then
            return
        end

        awful.spawn.easy_async_with_shell(command, function(stdout)
            local pasted = strip_trailing_newlines(stdout)

            if pasted ~= "" then
                self:_append_input(pasted)
            end
        end)
    end

    ---Cycle through the currently visible result list.
    function instance_methods:_move_selection(delta)
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

    ---Complete either to the common prefix or, for a single exact candidate, add a space.
    function instance_methods:_complete_input()
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

    ---Launch the selected entry, then record it in history and close the popup.
    function instance_methods:_launch_selected()
        local selected = self:_visible_entries()[self._selected_index]
        if not selected then
            return
        end

        if selected.source == "alias"
            and selected.notify
            and type(self.opts.service_refresh) == "function" then
            awful.spawn.easy_async_with_shell(selected.command, function()
                self.opts.service_refresh(selected.notify)

                -- Commands like `nmcli connection up ...` can return before the
                -- long-lived service state has visibly settled. A short follow-up
                -- refresh keeps aliases useful without requiring tighter poll loops.
                gears.timer.start_new(1.5, function()
                    self.opts.service_refresh(selected.notify)
                    return false
                end)
            end)
        else
            awful.spawn.with_shell(selected.command)
        end

        self:_record_history(selected)
        self:hide()
    end
end

return M
