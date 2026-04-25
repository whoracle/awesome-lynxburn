local awful = require("awful")

local helpers = require("lxdisplay.helpers")

local M = {}

local function output_status_map(state)
    local status = {}

    for _, output in ipairs((state or {}).outputs or {}) do
        status[output.name] = output
    end

    return status
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
        return false
    end

    local live_outputs = output_status_map(state)
    local desired_primary = instance:_profile_primary_output(profile)

    for _, output_name in ipairs(state.output_names or {}) do
        local output_opts = (profile.outputs or {})[output_name]
        local live = live_outputs[output_name] or {}

        if output_opts then
            local expected_off = instance:_profile_output_initial_state(profile, output_name) == "off"
            if expected_off then
                if live.active == true then
                    return false
                end
            else
                if live.active ~= true then
                    return false
                end

                if output_opts.primary == true or output_name == desired_primary then
                    if live.primary ~= true then
                        return false
                    end
                elseif live.primary == true and desired_primary ~= nil then
                    return false
                end

                if type(output_opts.mode) == "string"
                    and output_opts.mode ~= ""
                    and output_opts.mode ~= "auto"
                    and live.mode ~= output_opts.mode then
                    return false
                end

                if type(output_opts.rotate) == "string"
                    and output_opts.rotate ~= ""
                    and live.rotation ~= output_opts.rotate then
                    return false
                end

                if output_opts.rate ~= nil
                    and output_opts.rate ~= ""
                    and instance:_normalized_rate(live.rate) ~= instance:_normalized_rate(output_opts.rate) then
                    return false
                end
            end
        else
            if live.active == true then
                return false
            end
        end
    end

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
