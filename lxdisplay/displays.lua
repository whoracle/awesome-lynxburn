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

function displays.extend(instance_methods)
    function instance_methods:_normalize_profiles(profiles)
        local normalized = {}

        for _, profile in ipairs(profiles or {}) do
            if type(profile) == "table" and type(profile.outputs) == "table" then
                normalized[#normalized + 1] = {
                    name = profile.name or ("Profile " .. tostring(#normalized + 1)),
                    outputs = clone_table(profile.outputs),
                }
            end
        end

        return normalized
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

    function instance_methods:_profile_topology_summary(profile)
        local fragments = {}

        for _, output_name in ipairs(self:_profile_output_names(profile)) do
            local opts = (profile.outputs or {})[output_name] or {}
            local relationship

            for key, _ in pairs(POSITION_KEYS) do
                if type(opts[key]) == "string" and opts[key] ~= "" then
                    relationship = output_name .. " " .. key:gsub("_", "-") .. " " .. opts[key]
                    break
                end
            end

            if not relationship and opts.primary == true then
                relationship = output_name .. " primary"
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
            if key ~= "mode" and value ~= false and value ~= nil then
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
        awful.spawn.easy_async(args, function()
            self:refresh_display_state(callback)
        end)
    end

    function instance_methods:activate_profile(index)
        local profile = self._profiles[index]
        if not profile then
            return
        end

        self:_query_xrandr_state(function(state)
            self:_remember_inventory(state)

            local missing = self:_profile_missing_outputs(profile, state.output_set or {})
            if #missing > 0 then
                self:_notify_display_error(string.format(
                    "Profile '%s' references missing outputs: %s",
                    profile.name or "unnamed profile",
                    table.concat(missing, ", ")
                ))
                self:_refresh_detected_outputs(state)
                if self._refresh_popup then
                    self:_refresh_popup()
                end
                return
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

            self.state.active_profile_index = index
            self._active_profile_missing_signature = nil
            self:_apply_xrandr_argv(args)
        end)
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
