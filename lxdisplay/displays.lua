local awful = require("awful")
local naughty = require("naughty")

local helpers = require("lxdisplay.helpers")

local displays = {}

local POSITION_KEYS = {
    left_of = true,
    right_of = true,
    above = true,
    below = true,
    same_as = true,
}

local NON_XRANDR_OUTPUT_KEYS = {
    friendly_name = true,
}

local function clone_table(source)
    local copy = {}

    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            copy[key] = clone_table(value)
        else
            copy[key] = value
        end
    end

    return copy
end

local function sorted_output_names(outputs)
    local names = {}

    for output_name, _ in pairs(outputs or {}) do
        names[#names + 1] = output_name
    end

    table.sort(names)
    return names
end

local function flag_name(key)
    return "--" .. tostring(key or ""):gsub("_", "-")
end

local function preferred_xrandr_command(self)
    return self._redshift.command or "xrandr"
end

local function active_profile(self)
    return self._profiles[self.state.active_profile_index or 0]
end

local function active_profile_signature(profile, missing)
    profile = profile or {}
    table.sort(missing)
    return table.concat({
        profile.name or "",
        table.concat(missing, ","),
    }, "|")
end

local function cell_text(label)
    return "[" .. label .. "]"
end

local function trim_right_spaces(value)
    return (tostring(value or ""):gsub("%s+$", ""))
end

function displays.extend(instance_methods)
    function instance_methods:xrandr_enabled()
        return self._profiles_enabled == true
    end

    function instance_methods:_normalize_profiles(profiles)
        local normalized = {}

        for _, profile in ipairs(profiles or {}) do
            if type(profile) == "table" and type(profile.outputs) == "table" then
                normalized[#normalized + 1] = {
                    name = profile.name or ("Profile " .. tostring(#normalized + 1)),
                    default = profile.default == true,
                    outputs = clone_table(profile.outputs),
                }
            end
        end

        return normalized
    end

    function instance_methods:_notify_display_warning(message)
        io.stderr:write("[lxdisplay] " .. tostring(message) .. "\n")
        naughty.notify({
            app_name = "lxdisplay",
            title = "Display configuration warning",
            text = tostring(message),
            urgency = "normal",
        })
    end

    function instance_methods:_profile_primary_output(profile)
        for output_name, output_opts in pairs((profile or {}).outputs or {}) do
            if type(output_opts) == "table" and output_opts.primary == true then
                return output_name
            end
        end

        local names = sorted_output_names((profile or {}).outputs or {})
        return names[1]
    end

    function instance_methods:_profile_output_names(profile)
        return sorted_output_names((profile or {}).outputs or {})
    end

    function instance_methods:_profile_output_label(profile, output_name)
        local output_opts = ((profile or {}).outputs or {})[output_name] or {}
        local friendly_name = output_opts.friendly_name

        if type(friendly_name) == "string" and friendly_name ~= "" then
            return friendly_name
        end

        return output_name
    end

    function instance_methods:_profile_output_summary(profile)
        local labels = {}

        for _, output_name in ipairs(self:_profile_output_names(profile)) do
            labels[#labels + 1] = self:_profile_output_label(profile, output_name)
        end

        return table.concat(labels, " + ")
    end

    function instance_methods:_profile_topology_summary(profile)
        local fragments = {}

        for _, output_name in ipairs(self:_profile_output_names(profile)) do
            local opts = (profile.outputs or {})[output_name] or {}
            local relationship
            local display_name = self:_profile_output_label(profile, output_name)

            for key, _ in pairs(POSITION_KEYS) do
                if type(opts[key]) == "string" and opts[key] ~= "" then
                    local target_name = self:_profile_output_label(profile, opts[key])
                    relationship = display_name .. " " .. key:gsub("_", "-") .. " " .. target_name
                    break
                end
            end

            if not relationship and opts.primary == true then
                relationship = display_name .. " primary"
            end

            if relationship then
                fragments[#fragments + 1] = relationship
            end
        end

        if #fragments == 0 then
            return nil
        end

        return table.concat(fragments, ", ")
    end

    function instance_methods:_profile_spatial_summary(profile)
        local outputs = (profile or {}).outputs or {}
        local output_names = self:_profile_output_names(profile)
        if #output_names == 0 then
            return nil
        end

        local relation_of = {}
        local dependents = {}
        local roots = {}

        for _, output_name in ipairs(output_names) do
            local opts = outputs[output_name] or {}
            local relation_key = nil
            local relation_target = nil

            for _, key in ipairs({ "left_of", "right_of", "above", "below" }) do
                if type(opts[key]) == "string" and opts[key] ~= "" then
                    if relation_key ~= nil then
                        return nil
                    end

                    relation_key = key
                    relation_target = opts[key]
                end
            end

            if opts.same_as ~= nil then
                return nil
            end

            if relation_key == nil then
                roots[#roots + 1] = output_name
            else
                relation_of[output_name] = {
                    key = relation_key,
                    target = relation_target,
                }
                dependents[relation_target] = dependents[relation_target] or {}
                dependents[relation_target][#dependents[relation_target] + 1] = output_name
            end
        end

        if #roots == 0 then
            local primary = self:_profile_primary_output(profile)
            if primary then
                roots[1] = primary
            else
                return nil
            end
        elseif #roots > 1 then
            return nil
        end

        local coords = {}
        local queue = { roots[1] }
        coords[roots[1]] = { x = 0, y = 0 }

        while #queue > 0 do
            local current = table.remove(queue, 1)
            local current_coord = coords[current]

            for _, child in ipairs(dependents[current] or {}) do
                if coords[child] then
                    return nil
                end

                local relation = relation_of[child]
                local x = current_coord.x
                local y = current_coord.y

                if relation.key == "right_of" then
                    x = x + 1
                elseif relation.key == "left_of" then
                    x = x - 1
                elseif relation.key == "below" then
                    y = y + 1
                elseif relation.key == "above" then
                    y = y - 1
                else
                    return nil
                end

                coords[child] = { x = x, y = y }
                queue[#queue + 1] = child
            end
        end

        for _, output_name in ipairs(output_names) do
            if not coords[output_name] then
                return nil
            end
        end

        local occupancy = {}
        local min_x, max_x, min_y, max_y

        for _, output_name in ipairs(output_names) do
            local coord = coords[output_name]
            occupancy[coord.y] = occupancy[coord.y] or {}
            if occupancy[coord.y][coord.x] then
                return nil
            end
            occupancy[coord.y][coord.x] = output_name

            min_x = min_x and math.min(min_x, coord.x) or coord.x
            max_x = max_x and math.max(max_x, coord.x) or coord.x
            min_y = min_y and math.min(min_y, coord.y) or coord.y
            max_y = max_y and math.max(max_y, coord.y) or coord.y
        end

        local column_widths = {}
        for x = min_x, max_x do
            local width = 0
            for y = min_y, max_y do
                local output_name = occupancy[y] and occupancy[y][x]
                if output_name then
                    width = math.max(width, #cell_text(self:_profile_output_label(profile, output_name)))
                end
            end
            column_widths[x] = width
        end

        local lines = {}
        for y = min_y, max_y do
            local parts = {}
            for x = min_x, max_x do
                local output_name = occupancy[y] and occupancy[y][x]
                if output_name then
                    local text = cell_text(self:_profile_output_label(profile, output_name))
                    parts[#parts + 1] = text .. string.rep(" ", column_widths[x] - #text)
                else
                    parts[#parts + 1] = string.rep(" ", column_widths[x])
                end
            end

            lines[#lines + 1] = trim_right_spaces(table.concat(parts, " "))
        end

        return table.concat(lines, "\n")
    end

    function instance_methods:_profile_missing_outputs(profile, connected_set)
        local missing = {}

        for _, output_name in ipairs(self:_profile_output_names(profile)) do
            if not connected_set[output_name] then
                missing[#missing + 1] = output_name
            end
        end

        return missing
    end

    function instance_methods:_notify_display_error(message)
        io.stderr:write("[lxdisplay] " .. tostring(message) .. "\n")
        naughty.notify({
            app_name = "lxdisplay",
            title = "Display configuration failed",
            text = tostring(message),
            urgency = "critical",
        })
    end

    function instance_methods:_panic_mirror_all_outputs(state, callback)
        local outputs = state and state.output_names or {}
        if #outputs == 0 then
            if callback then
                callback(false)
            end
            return
        end

        local args = { preferred_xrandr_command(self) }
        local primary = state.primary_output or outputs[1]

        for _, output_name in ipairs(outputs) do
            args[#args + 1] = "--output"
            args[#args + 1] = output_name
            args[#args + 1] = "--auto"

            if output_name == primary then
                args[#args + 1] = "--primary"
            else
                args[#args + 1] = "--same-as"
                args[#args + 1] = primary
            end
        end

        self:_notify_display_warning(
            "Falling back to panic display mode: all connected outputs active, auto, mirrored."
        )
        self:_apply_xrandr_argv(args, function()
            if callback then
                callback(true)
            end
        end)
    end

    function instance_methods:_query_xrandr_state(callback)
        awful.spawn.easy_async({ preferred_xrandr_command(self), "--query" }, function(stdout)
            local outputs = helpers.parse_xrandr_outputs(stdout)
            local primary_output = nil

            for _, output in ipairs(outputs) do
                if output.primary then
                    primary_output = output.name
                    break
                end
            end

            callback({
                outputs = outputs,
                output_names = helpers.parse_connected_outputs(stdout),
                output_set = helpers.output_name_set(outputs),
                primary_output = primary_output,
            })
        end)
    end

    function instance_methods:_remember_inventory(state)
        self.state.connected_outputs = state.output_names or {}
        self.state.connected_output_set = state.output_set or {}
        self.state.current_primary_output = state.primary_output
    end

    function instance_methods:_refresh_detected_outputs(state)
        local current_profile = active_profile(self)
        if not current_profile then
            self.state.detected_outputs = {}
            return
        end

        local profile_outputs = helpers.output_name_set(self:_profile_output_names(current_profile))
        local detected = {}

        for _, output in ipairs(state.outputs or {}) do
            if not profile_outputs[output.name] then
                detected[#detected + 1] = {
                    name = output.name,
                    primary = output.primary == true,
                }
            end
        end

        self.state.detected_outputs = detected
    end

    function instance_methods:_validate_active_profile(state)
        local profile = active_profile(self)
        if not profile then
            self._active_profile_missing_signature = nil
            return true
        end

        local missing = self:_profile_missing_outputs(profile, state.output_set or {})
        if #missing == 0 then
            self._active_profile_missing_signature = nil
            return true
        end

        local signature = active_profile_signature(profile, missing)
        if self._active_profile_missing_signature ~= signature then
            self._active_profile_missing_signature = signature
            self:_notify_display_error(string.format(
                "Active profile '%s' references missing outputs: %s",
                profile.name or "unnamed profile",
                table.concat(missing, ", ")
            ))
        end

        return false
    end

    function instance_methods:refresh_display_state(callback)
        if not self:xrandr_enabled() then
            self.state.connected_outputs = {}
            self.state.connected_output_set = {}
            self.state.current_primary_output = nil
            self.state.detected_outputs = {}

            if self._refresh_popup then
                self:_refresh_popup()
            end

            if callback then
                callback({
                    outputs = {},
                    output_names = {},
                    output_set = {},
                    primary_output = nil,
                })
            end
            return
        end

        self:_query_xrandr_state(function(state)
            self:_remember_inventory(state)
            self:_refresh_detected_outputs(state)
            self:_validate_active_profile(state)

            if self._refresh_popup then
                self:_refresh_popup()
            end

            if callback then
                callback(state)
            end
        end)
    end

    function instance_methods:detect_displays()
        if not self:xrandr_enabled() then
            return
        end

        self:refresh_display_state()
    end

    function instance_methods:_append_output_args(args, output_name, output_opts)
        args[#args + 1] = "--output"
        args[#args + 1] = output_name

        output_opts = output_opts or {}

        local mode = output_opts.mode
        if mode == "auto" then
            args[#args + 1] = "--auto"
        elseif type(mode) == "string" and mode ~= "" then
            args[#args + 1] = "--mode"
            args[#args + 1] = mode
        end

        local keys = {}
        for key, value in pairs(output_opts) do
            if key ~= "mode"
                and not NON_XRANDR_OUTPUT_KEYS[key]
                and value ~= false
                and value ~= nil then
                keys[#keys + 1] = key
            end
        end
        table.sort(keys)

        for _, key in ipairs(keys) do
            local value = output_opts[key]
            args[#args + 1] = flag_name(key)

            if value ~= true then
                args[#args + 1] = tostring(value)
            end
        end
    end

    function instance_methods:_apply_xrandr_argv(args, callback)
        awful.spawn.easy_async(args, function(_, _, _, exit_code)
            local ok = exit_code == 0
            self:refresh_display_state(function(state)
                if callback then
                    callback(ok, state)
                end
            end)
        end)
    end

    function instance_methods:_resolve_startup_profile_index()
        local count = #self._profiles
        if count == 0 then
            return nil
        end

        if count == 1 then
            return 1
        end

        local defaults = {}
        for index, profile in ipairs(self._profiles) do
            if profile.default == true then
                defaults[#defaults + 1] = {
                    index = index,
                    name = profile.name or ("Profile " .. tostring(index)),
                }
            end
        end

        if #defaults == 1 then
            return defaults[1].index
        end

        local fallback_name = self._profiles[1].name or "Profile 1"
        if #defaults == 0 then
            self:_notify_display_warning(
                "Multiple lxdisplay profiles are configured but none is marked default. "
                    .. "Using '" .. fallback_name .. "' automatically."
            )
            return 1
        end

        self:_notify_display_warning(
            "Multiple lxdisplay profiles are marked default. Using '" .. fallback_name .. "' automatically."
        )
        return 1
    end

    function instance_methods:_build_profile_argv(profile, state)
        local missing = self:_profile_missing_outputs(profile, state.output_set or {})
        if #missing > 0 then
            return nil, missing
        end

        local args = { preferred_xrandr_command(self) }

        for _, output_name in ipairs(state.output_names or {}) do
            local output_opts = profile.outputs[output_name]

            if output_opts then
                self:_append_output_args(args, output_name, output_opts)
            else
                args[#args + 1] = "--output"
                args[#args + 1] = output_name
                args[#args + 1] = "--off"
            end
        end

        return args, nil
    end

    function instance_methods:_apply_profile_index(index, opts)
        opts = opts or {}
        local profile = self._profiles[index]
        if not profile then
            return
        end

        self:_query_xrandr_state(function(state)
            self:_remember_inventory(state)

            local args, missing = self:_build_profile_argv(profile, state)
            if not args then
                local message = string.format(
                    "Profile '%s' references missing outputs: %s",
                    profile.name or "unnamed profile",
                    table.concat(missing or {}, ", ")
                )

                if opts.allow_panic_fallback then
                    self:_notify_display_error(message)
                    self:_panic_mirror_all_outputs(state)
                else
                    self:_notify_display_error(message)
                    self:_refresh_detected_outputs(state)
                    if self._refresh_popup then
                        self:_refresh_popup()
                    end
                end
                return
            end

            self.state.active_profile_index = index
            self._active_profile_missing_signature = nil
            self:_apply_xrandr_argv(args, function(ok, refreshed_state)
                if ok then
                    return
                end

                self:_notify_display_error(string.format(
                    "Applying profile '%s' failed.",
                    profile.name or "unnamed profile"
                ))

                if opts.allow_panic_fallback then
                    self:_panic_mirror_all_outputs(refreshed_state or state)
                end
            end)
        end)
    end

    function instance_methods:activate_profile(index)
        if not self:xrandr_enabled() then
            return
        end

        if not self._profiles[index] then
            return
        end

        self:_apply_profile_index(index, { allow_panic_fallback = false })
    end

    function instance_methods:auto_apply_startup_profile()
        if not self:xrandr_enabled() or self._startup_auto_apply == false then
            return
        end

        local index = self:_resolve_startup_profile_index()
        if index == nil then
            return
        end

        self:_apply_profile_index(index, { allow_panic_fallback = true })
    end

    function instance_methods:_resolve_detect_extend_reference(state)
        local configured = self._detected.extend_relative_to
        if configured == "profile-primary" or configured == nil then
            local profile = active_profile(self)
            local profile_primary = self:_profile_primary_output(profile)
            if profile_primary and (state.output_set or {})[profile_primary] then
                return profile_primary
            end
        elseif type(configured) == "string" and configured ~= "" and (state.output_set or {})[configured] then
            return configured
        end

        if state.primary_output and (state.output_set or {})[state.primary_output] then
            return state.primary_output
        end

        for _, output_name in ipairs(state.output_names or {}) do
            return output_name
        end

        return nil
    end

    function instance_methods:configure_detected_output(output_name, action)
        if not self:xrandr_enabled() then
            return
        end

        if type(output_name) ~= "string" or output_name == "" then
            return
        end

        self:_query_xrandr_state(function(state)
            self:_remember_inventory(state)
            if not (state.output_set or {})[output_name] then
                self:_notify_display_error("Output '" .. output_name .. "' is no longer connected.")
                self:_refresh_detected_outputs(state)
                if self._refresh_popup then
                    self:_refresh_popup()
                end
                return
            end

            local args = { preferred_xrandr_command(self), "--output", output_name }

            if action == "disable" then
                args[#args + 1] = "--off"
            else
                local reference = self:_resolve_detect_extend_reference(state)
                if not reference or reference == output_name then
                    self:_notify_display_error("No reference output is available for detected display placement.")
                    return
                end

                args[#args + 1] = "--auto"

                if action == "mirror" then
                    args[#args + 1] = "--same-as"
                    args[#args + 1] = reference
                else
                    local direction = tostring(self._detected.extend_direction or "left"):gsub("-", "_")
                    local flag = POSITION_KEYS[direction] and flag_name(direction) or "--left-of"
                    args[#args + 1] = flag
                    args[#args + 1] = reference
                end
            end

            self:_apply_xrandr_argv(args)
        end)
    end
end

return displays
