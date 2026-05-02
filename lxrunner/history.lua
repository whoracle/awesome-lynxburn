local awful = require("awful")
local gears = require("gears")
local json = require("lxcommon.dkjson")
local util = require("lxcommon.util")

local M = {}

local function strip_trailing_newlines(s)
    return tostring(s or ""):gsub("[\r\n]+$", "")
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

local function normalize_history_entry(entry)
    if type(entry) ~= "table" then
        return nil
    end

    local launch_source = tostring(entry.launch_source or entry.source or "")
    local count = math.max(1, tonumber(entry.count) or 1)
    local last_used = tonumber(entry.last_used) or 0

    if launch_source == "alias" then
        local alias_name = util.trim(entry.alias_name or entry.name or "")
        if alias_name == "" then
            return nil
        end

        local alias_args = util.trim(entry.alias_args or entry.args or "")
        local name = util.trim(entry.name or alias_name)
        if name == "" then
            name = alias_name
        end

        return {
            last_used = last_used,
            launch_source = "alias",
            count = count,
            name = name,
            alias_name = alias_name,
            alias_args = alias_args,
            source = "history",
        }
    end

    if not entry.command or entry.command == "" then
        return nil
    end

    return {
        last_used = last_used,
        launch_source = launch_source,
        count = count,
        name = tostring(entry.name or entry.command or ""),
        command = tostring(entry.command or ""),
        source = "history",
    }
end

local function history_identity(entry)
    if (entry.launch_source or entry.source) == "alias" then
        return table.concat({
            "alias",
            tostring(entry.alias_name or entry.name or ""),
            tostring(entry.alias_args or ""),
        }, "\0")
    end

    return "command\0" .. tostring(entry.command or "")
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

        local contents = handle:read("*a")
        handle:close()

        local decoded = json.decode(contents or "")
        if type(decoded) ~= "table"
            or decoded.format ~= "lxrunner-history"
            or tonumber(decoded.version) ~= 1
            or type(decoded.entries) ~= "table" then
            return
        end

        for _, entry in ipairs(decoded.entries) do
            local normalized = normalize_history_entry(entry)
            if normalized then
                table.insert(self._history, normalized)
            end
        end

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
            local same_alias = entry.alias_name ~= nil
                and history_entry.launch_source == "alias"
                and history_entry.alias_name == entry.alias_name
                and tostring(history_entry.alias_args or "") == tostring(entry.alias_args or "")

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

        local entries = {}
        for i = 1, math.min(#self._history, self.opts.history_limit) do
            local entry = self._history[i]
            local saved = {
                last_used = tonumber(entry.last_used) or 0,
                launch_source = tostring(entry.launch_source or entry.source or ""),
                count = math.max(1, tonumber(entry.count) or 1),
                name = tostring(entry.name or ""),
            }

            if saved.launch_source == "alias" then
                saved.alias_name = tostring(entry.alias_name or entry.name or "")
                local alias_args = util.trim(entry.alias_args or "")
                if alias_args ~= "" then
                    saved.alias_args = alias_args
                end
            else
                saved.command = tostring(entry.command or "")
            end

            entries[#entries + 1] = saved
        end

        handle:write(json.encode({
            format = "lxrunner-history",
            version = 1,
            entries = entries,
        }, {
            indent = true,
        }))
        handle:write("\n")
        handle:close()
    end

    ---Find a configured alias by name.
    function instance_methods:_find_alias(alias_name)
        for _, alias in ipairs(self._aliases or {}) do
            if alias.name == alias_name then
                return alias
            end
        end

        return nil
    end

    ---Resolve a semantic alias history row through the current alias config.
    function instance_methods:_resolve_history_alias(entry)
        local alias = self:_find_alias(entry.alias_name or entry.name)
        if not alias then
            return nil
        end

        local alias_args = util.trim(entry.alias_args or "")
        local raw_input = alias.name
        if alias_args ~= "" then
            raw_input = raw_input .. " " .. alias_args
        end

        local resolved = self:_resolved_alias_entry(alias, raw_input, alias_args)
        resolved.source = "history"
        resolved.launch_source = "alias"
        resolved.name = entry.name or resolved.name
        resolved.last_used = entry.last_used
        resolved.count = entry.count

        return resolved
    end

    ---Choose the user-facing history label based on the original launch source.
    function instance_methods:_history_label(entry)
        if not entry then
            return ""
        end

        local source = entry.launch_source or entry.source

        if source == "alias" then
            return util.trim(entry.name or entry.alias_name or entry.command)
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
        if not entry then
            return
        end

        local launch_source = entry.launch_source or entry.source
        local is_alias = launch_source == "alias"

        if not is_alias and (not entry.command or entry.command == "") then
            return
        end

        local updated = {
            name = self:_history_label(entry),
            source = "history",
            launch_source = launch_source,
            last_used = os.time(),
            count = 1,
        }

        if is_alias then
            updated.alias_name = util.trim(entry.alias_name or entry.name or "")
            updated.alias_args = util.trim(entry.alias_args or "")

            if updated.alias_name == "" then
                return
            end
        else
            updated.command = entry.command
        end

        local updated_identity = history_identity(updated)
        local existing_count = 0
        local new_history = { updated }

        for _, existing in ipairs(self._history) do
            if history_identity(existing) == updated_identity then
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
            local visible = {}

            for _, entry in ipairs(self._history) do
                if entry.launch_source == "alias" then
                    local resolved = self:_resolve_history_alias(entry)
                    if resolved then
                        table.insert(visible, resolved)
                    end
                else
                    table.insert(visible, entry)
                end
            end

            return visible
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

        local is_alias_launch = selected.source == "alias" or selected.launch_source == "alias"

        if is_alias_launch
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
