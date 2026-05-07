local awful = require("awful")

local helpers = require("lxdisplay.helpers")

local M = {}

local function debug_profile_match(instance, message)
    if not (instance and instance._debug_profile_matching) then
        return
    end

    io.stderr:write("[lxdisplay] profile match: " .. tostring(message) .. "\n")
end

local function output_status_map(state)
    local status = {}

    for _, output in ipairs((state or {}).outputs or {}) do
        status[output.name] = output
    end

    return status
end

local function bool_label(value)
    return value == true and "true" or "false"
end

local function value_label(value)
    if value == nil then
        return "nil"
    end

    return tostring(value)
end

function M.name()
    return "x11"
end

function M.supports_redshift()
    return true
end

function M.supports_profiles()
    return true
end

function M.display_command(instance)
    return instance._redshift.command or "xrandr"
end

function M.query_connected_outputs(instance, callback)
    awful.spawn.easy_async({ M.display_command(instance), "--query" }, function(stdout)
        callback(helpers.parse_connected_outputs(stdout))
    end)
end

function M.build_gamma_argv(instance, gamma, outputs)
    local args = { M.display_command(instance) }

    for _, output in ipairs(outputs or {}) do
        args[#args + 1] = "--output"
        args[#args + 1] = output
        args[#args + 1] = "--gamma"
        args[#args + 1] = table.concat({
            helpers.format_gamma(gamma.red),
            helpers.format_gamma(gamma.green),
            helpers.format_gamma(gamma.blue),
        }, ":")
    end

    return args
end

function M.apply_gamma(instance, gamma, outputs, callback)
    if #outputs == 0 then
        if callback then
            callback(true)
        end
        return
    end

    awful.spawn.easy_async(M.build_gamma_argv(instance, gamma, outputs), function(_, _, _, exit_code)
        if callback then
            callback(exit_code == 0)
        end
    end)
end

function M.query_state(instance, callback)
    awful.spawn.easy_async({ M.display_command(instance), "--query" }, function(stdout)
        local outputs = helpers.parse_xrandr_outputs(stdout, {
            debug = instance._debug_profile_matching == true,
        })
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

function M.apply_argv(instance, args, callback)
    awful.spawn.easy_async(args, function(_, _, _, exit_code)
        local ok = exit_code == 0
        instance:refresh_display_state(function(state)
            if callback then
                callback(ok, state)
            end
        end)
    end)
end

function M.profile_matches_state(instance, profile, state)
    if not profile or not state then
        debug_profile_match(instance, "missing profile or state")
        return false
    end

    local live_outputs = output_status_map(state)
    local desired_primary = instance:_profile_primary_output(profile)

    debug_profile_match(instance, string.format(
        "checking '%s' against connected outputs: %s",
        profile.name or "unnamed profile",
        table.concat(state.output_names or {}, ", ")
    ))

    for _, output_name in ipairs(state.output_names or {}) do
        local output_opts = (profile.outputs or {})[output_name]
        local live = live_outputs[output_name] or {}

        if output_opts then
            local expected_off = instance:_profile_output_initial_state(profile, output_name) == "off"
            debug_profile_match(instance, string.format(
                "%s: live active=%s primary=%s mode=%s rotation=%s rate=%s; desired active=%s primary=%s mode=%s rotation=%s rate=%s",
                output_name,
                bool_label(live.active),
                bool_label(live.primary),
                value_label(live.mode),
                value_label(live.rotation),
                value_label(live.rate),
                bool_label(not expected_off),
                bool_label(output_opts.primary == true or output_name == desired_primary),
                value_label(output_opts.mode),
                value_label(output_opts.rotate),
                value_label(output_opts.rate)
            ))

            if expected_off then
                if live.active == true then
                    debug_profile_match(instance, output_name .. ": expected off, live active")
                    return false
                end
            else
                if live.active ~= true then
                    debug_profile_match(instance, output_name .. ": expected active, live inactive")
                    return false
                end

                if output_opts.primary == true or output_name == desired_primary then
                    if live.primary ~= true then
                        debug_profile_match(instance, output_name .. ": expected primary")
                        return false
                    end
                elseif live.primary == true and desired_primary ~= nil then
                    debug_profile_match(instance, string.format(
                        "%s: live primary but desired primary is %s",
                        output_name,
                        desired_primary
                    ))
                    return false
                end

                if type(output_opts.mode) == "string"
                    and output_opts.mode ~= ""
                    and output_opts.mode ~= "auto"
                    and live.mode ~= output_opts.mode then
                    debug_profile_match(instance, string.format(
                        "%s: mode mismatch live=%s desired=%s",
                        output_name,
                        tostring(live.mode),
                        tostring(output_opts.mode)
                    ))
                    return false
                end

                if type(output_opts.rotate) == "string"
                    and output_opts.rotate ~= ""
                    and live.rotation ~= output_opts.rotate then
                    debug_profile_match(instance, string.format(
                        "%s: rotation mismatch live=%s desired=%s",
                        output_name,
                        tostring(live.rotation),
                        tostring(output_opts.rotate)
                    ))
                    return false
                end

                if output_opts.rate ~= nil
                    and output_opts.rate ~= ""
                    and not instance:_rates_match(live.rate, output_opts.rate) then
                    debug_profile_match(instance, string.format(
                        "%s: rate mismatch live=%s desired=%s normalized_live=%s normalized_desired=%s",
                        output_name,
                        tostring(live.rate),
                        tostring(output_opts.rate),
                        tostring(instance:_normalized_rate(live.rate)),
                        tostring(instance:_normalized_rate(output_opts.rate))
                    ))
                    return false
                end
            end
        else
            debug_profile_match(instance, string.format(
                "%s: live active=%s primary=%s mode=%s rotation=%s rate=%s; desired absent/off",
                output_name,
                bool_label(live.active),
                bool_label(live.primary),
                value_label(live.mode),
                value_label(live.rotation),
                value_label(live.rate)
            ))

            if live.active == true then
                debug_profile_match(instance, output_name .. ": live active but not in profile")
                return false
            end
        end
    end

    debug_profile_match(instance, "matched")
    return true
end

function M.panic_mirror(instance, state, callback)
    local outputs = state and state.output_names or {}
    if #outputs == 0 then
        if callback then
            callback(false)
        end
        return
    end

    local args = { M.display_command(instance) }
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

    instance:_notify_display_warning(
        "Falling back to panic display mode: all connected outputs active, auto, mirrored."
    )
    M.apply_argv(instance, args, function()
        if callback then
            callback(true)
        end
    end)
end

return M
