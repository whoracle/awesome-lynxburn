local awful = require("awful")

local M = {}

local ROTATION_MAP = {
    ["90"] = "left",
    ["180"] = "inverted",
    ["270"] = "right",
    normal = "normal",
    flipped = "normal",
    ["flipped-90"] = "left",
    ["flipped-180"] = "inverted",
    ["flipped-270"] = "right",
}

local TRANSFORM_MAP = {
    left = "90",
    right = "270",
    inverted = "180",
    normal = "normal",
}

local NON_WLR_OUTPUT_KEYS = {
    friendly_name = true,
    optional = true,
    initial_state = true,
    primary = true,
    same_as = true,
    scale = true,
}

local RELATION_KEYS = {
    left_of = true,
    right_of = true,
    above = true,
    below = true,
}

local function normalize_transform(value)
    return ROTATION_MAP[tostring(value or "")] or "normal"
end

local function live_outputs()
    local outputs = {}
    local primary_output = nil

    for s in screen do
        local output = s.output
        local name = output and output.name

        if name then
            local geometry = s.geometry or {}
            outputs[#outputs + 1] = {
                name = name,
                primary = primary_output == nil,
                active = true,
                mode = geometry.width and geometry.height and string.format("%dx%d", geometry.width, geometry.height) or nil,
                pos_x = geometry.x,
                pos_y = geometry.y,
                rotation = normalize_transform(output and output.transform),
                rate = output and (output.refresh or output.current_refresh),
            }

            if primary_output == nil then
                primary_output = name
            end
        end
    end

    table.sort(outputs, function(a, b)
        return tostring(a.name) < tostring(b.name)
    end)

    local names = {}
    local set = {}
    for _, output in ipairs(outputs) do
        names[#names + 1] = output.name
        set[output.name] = true
    end

    return {
        outputs = outputs,
        output_names = names,
        output_set = set,
        primary_output = primary_output,
    }
end

local function parse_rate(value)
    local rate = tonumber(value)
    if not rate then
        return nil
    end

    return string.format("%.2f", rate)
end

local function mode_with_rate(output_opts)
    local mode = tostring(output_opts.mode or "")
    if mode == "" or mode == "auto" then
        return nil
    end

    local rate = parse_rate(output_opts.rate)
    if rate then
        return string.format("%s@%sHz", mode, rate)
    end

    return mode
end

local function mode_without_rate(output_opts)
    local mode = tostring(output_opts.mode or "")
    if mode == "" or mode == "auto" then
        return nil
    end

    return mode
end

local function relation_for(output_opts)
    for _, key in ipairs({ "left_of", "right_of", "above", "below" }) do
        local value = (output_opts or {})[key]
        if type(value) == "string" and value ~= "" then
            return key, value
        end
    end

    return nil, nil
end

local function output_command(instance, output_name, output_opts, state)
    local args = { "wlr-randr", "--output", output_name }
    local desired_off = instance:_profile_output_initial_state({ outputs = { [output_name] = output_opts } }, output_name) == "off"

    if desired_off then
        args[#args + 1] = "--off"
        return { args = args }
    end

    args[#args + 1] = "--on"

    local mode = mode_with_rate(output_opts)
    local retry_args = nil
    if mode then
        args[#args + 1] = "--mode"
        args[#args + 1] = mode

        local fallback_mode = mode_without_rate(output_opts)
        if fallback_mode and fallback_mode ~= mode then
            retry_args = { "wlr-randr", "--output", output_name, "--on", "--mode", fallback_mode }
        end
    end

    if type(output_opts.pos) == "string" and output_opts.pos ~= "" then
        local pos = tostring(output_opts.pos):gsub("x", ",")
        args[#args + 1] = "--pos"
        args[#args + 1] = pos
        if retry_args then
            retry_args[#retry_args + 1] = "--pos"
            retry_args[#retry_args + 1] = pos
        end
    end

    local relation_key, relation_target = relation_for(output_opts)
    if relation_key and relation_target then
        args[#args + 1] = "--" .. relation_key:gsub("_", "-")
        args[#args + 1] = relation_target
        if retry_args then
            retry_args[#retry_args + 1] = "--" .. relation_key:gsub("_", "-")
            retry_args[#retry_args + 1] = relation_target
        end
    end

    if type(output_opts.scale) == "number" or type(output_opts.scale) == "string" then
        args[#args + 1] = "--scale"
        args[#args + 1] = tostring(output_opts.scale)
        if retry_args then
            retry_args[#retry_args + 1] = "--scale"
            retry_args[#retry_args + 1] = tostring(output_opts.scale)
        end
    end

    if type(output_opts.rotate) == "string" and output_opts.rotate ~= "" then
        args[#args + 1] = "--transform"
        args[#args + 1] = TRANSFORM_MAP[output_opts.rotate] or tostring(output_opts.rotate)
        if retry_args then
            retry_args[#retry_args + 1] = "--transform"
            retry_args[#retry_args + 1] = TRANSFORM_MAP[output_opts.rotate] or tostring(output_opts.rotate)
        end
    end

    local keys = {}
    for key, value in pairs(output_opts or {}) do
        if key ~= "mode"
            and key ~= "rate"
            and key ~= "rotate"
            and key ~= "pos"
            and not RELATION_KEYS[key]
            and not NON_WLR_OUTPUT_KEYS[key]
            and value ~= false
            and value ~= nil then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys)

    for _, key in ipairs(keys) do
        args[#args + 1] = "--" .. tostring(key):gsub("_", "-")
        if output_opts[key] ~= true then
            args[#args + 1] = tostring(output_opts[key])
        end

        if retry_args then
            retry_args[#retry_args + 1] = "--" .. tostring(key):gsub("_", "-")
            if output_opts[key] ~= true then
                retry_args[#retry_args + 1] = tostring(output_opts[key])
            end
        end
    end

    return {
        args = args,
        retry_args = retry_args,
    }
end

local function sequential_apply(instance, queue, callback)
    local command = table.remove(queue, 1)
    if not command then
        instance:refresh_display_state(function(state)
            if callback then
                callback(true, state)
            end
        end)
        return
    end

    awful.spawn.easy_async(command.args, function(_, _, _, exit_code)
        if exit_code ~= 0 then
            if command.retry_args then
                awful.spawn.easy_async(command.retry_args, function(_, _, _, retry_exit_code)
                    if retry_exit_code == 0 then
                        sequential_apply(instance, queue, callback)
                        return
                    end

                    instance:refresh_display_state(function(state)
                        if callback then
                            callback(false, state)
                        end
                    end)
                end)
                return
            end

            instance:refresh_display_state(function(state)
                if callback then
                    callback(false, state)
                end
            end)
            return
        end

        sequential_apply(instance, queue, callback)
    end)
end

function M.name()
    return "somewm"
end

function M.supports_redshift()
    return false
end

function M.supports_profiles()
    return true
end

function M.display_command()
    return "wlr-randr"
end

function M.query_connected_outputs(_, callback)
    local state = live_outputs()
    callback(state.output_names)
end

function M.apply_gamma(_, _, _, callback)
    if callback then
        callback(true)
    end
end

function M.query_state(_, callback)
    callback(live_outputs())
end

function M.apply_argv(instance, queue, callback)
    sequential_apply(instance, queue, callback)
end

function M.profile_matches_state(instance, profile, state)
    if not profile or not state then
        return false
    end

    local live = {}
    for _, output in ipairs(state.outputs or {}) do
        live[output.name] = output
    end

    for _, output_name in ipairs(state.output_names or {}) do
        local output_opts = (profile.outputs or {})[output_name]
        local current = live[output_name] or {}

        if output_opts then
            if instance:_profile_output_initial_state(profile, output_name) == "off" then
                return false
            end

            if type(output_opts.mode) == "string"
                and output_opts.mode ~= ""
                and output_opts.mode ~= "auto"
                and current.mode ~= output_opts.mode then
                return false
            end

            if type(output_opts.rotate) == "string"
                and output_opts.rotate ~= ""
                and current.rotation ~= output_opts.rotate then
                return false
            end

            if type(output_opts.pos) == "string" and output_opts.pos ~= "" then
                local x, y = tostring(output_opts.pos):match("^(%-?%d+)x(%-?%d+)$")
                if not x or current.pos_x ~= tonumber(x) or current.pos_y ~= tonumber(y) then
                    return false
                end
            end
        else
            return false
        end
    end

    return true
end

function M.panic_mirror(instance, state, callback)
    local queue = {}
    for _, output_name in ipairs((state or {}).output_names or {}) do
        queue[#queue + 1] = { "wlr-randr", "--output", output_name, "--on" }
    end

    instance:_notify_display_warning(
        "Falling back to panic display mode: all currently visible outputs enabled."
    )
    sequential_apply(instance, queue, callback)
end

function M.build_profile_plan(instance, profile, state)
    local missing = instance:_profile_missing_outputs(profile, state.output_set or {})
    if #missing > 0 then
        return nil, missing
    end

    local queue = {}

    for _, output_name in ipairs(state.output_names or {}) do
        local output_opts = (profile.outputs or {})[output_name]

        if output_opts then
            queue[#queue + 1] = output_command(instance, output_name, output_opts, state)
        else
            queue[#queue + 1] = { args = { "wlr-randr", "--output", output_name, "--off" } }
        end
    end

    return queue, nil
end

return M
