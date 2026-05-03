local awful = require("awful")
local gears = require("gears")
local util = require("lxcommon.util")

local M = {}
local subscription_pid = nil
local subscription_debounce = nil
local subscription_exit_hook_registered = false
local parse_first_percent
local map_sink_input_mutes
local map_sink_input_volumes
local map_source_output_mutes
local map_source_output_volumes

-- Parse `pactl list short ...` output into small typed row tables.
local function parse_tabular_short_list(out, kind)
    local rows = {}
    for _, line in ipairs(util.split_lines(out)) do
        local cols = {}
        for col in line:gmatch("[^\t]+") do
            cols[#cols + 1] = col
        end

        if kind == "sink" or kind == "source" then
            rows[#rows + 1] = {
                id = cols[1],
                name = cols[2],
                driver = cols[3],
                state = cols[4],
            }
        elseif kind == "sink-input" then
            rows[#rows + 1] = {
                id = cols[1],
                sink_id = cols[2],
                client_id = cols[3],
                format = cols[4],
            }
        elseif kind == "source-output" then
            rows[#rows + 1] = {
                id = cols[1],
                source_id = cols[2],
                client_id = cols[3],
                format = cols[4],
            }
        end
    end
    return rows
end

-- Extract stream property dictionaries from the verbose `pactl list` format.
local function parse_proplist_blocks(out)
    local blocks = {}
    local current = nil

    for _, line in ipairs(util.split_lines(out)) do
        if line:match("^Sink Input #") or line:match("^Source Output #") then
            if current then
                blocks[#blocks + 1] = current
            end
            current = {
                header = line,
                props = {},
            }
        elseif current then
            local key, val = line:match("^%s*([^=]+)%s*=%s*(.+)$")
            if key and val then
                val = val:gsub('^"', ""):gsub('"$', "")
                current.props[util.trim(key)] = val
            end
        end
    end

    if current then
        blocks[#blocks + 1] = current
    end

    return blocks
end

local function map_stream_props_by_id(out)
    local result = {}
    for _, block in ipairs(parse_proplist_blocks(out)) do
        local id = block.header:match("#(%d+)")
        if id then
            result[id] = block.props
        end
    end
    return result
end

local function get_default_sink()
    local out = util.read_command("pactl get-default-sink 2>/dev/null")
    return util.trim(out)
end

local function get_default_source()
    local out = util.read_command("pactl get-default-source 2>/dev/null")
    return util.trim(out)
end

local function get_sink_volume_percent(name)
    if not name then
        return nil
    end

    local out = util.read_command("pactl get-sink-volume " .. util.shell_escape(name) .. " 2>/dev/null") or ""
    return parse_first_percent(out)
end

local function get_source_volume_percent(name)
    if not name then
        return nil
    end

    local out = util.read_command("pactl get-source-volume " .. util.shell_escape(name) .. " 2>/dev/null") or ""
    return parse_first_percent(out)
end

local function build_sinks(short_out, default_name)
    local short = parse_tabular_short_list(short_out or "", "sink")

    for _, sink in ipairs(short) do
        sink.is_default = (sink.name == default_name)
        sink.label = sink.name
    end

    return short
end

local function build_sources(short_out, default_name, sources_dump)
    local short = parse_tabular_short_list(short_out or "", "source")
    local source_mutes = {}

    local current_id = nil
    for _, line in ipairs(util.split_lines(sources_dump or "")) do
        local id = line:match("^Source #(%d+)")
        if id then
            current_id = id
        elseif current_id then
            if line:match("^%s*Mute:%s*yes") then
                source_mutes[current_id] = true
            elseif line:match("^%s*Mute:%s*no") then
                source_mutes[current_id] = false
            end
        end
    end

    local filtered = {}
    for _, source in ipairs(short) do
        if not source.name:match("%.monitor$") then
            source.is_default = (source.name == default_name)
            source.label = source.name
            source.muted = source_mutes[source.id] or false
            filtered[#filtered + 1] = source
        end
    end

    return filtered
end

local function build_sink_inputs(short_out, sink_inputs_dump, sinks)
    local short = parse_tabular_short_list(short_out or "", "sink-input")
    local props = map_stream_props_by_id(sink_inputs_dump or "")
    local sink_map = {}
    local volumes = map_sink_input_volumes(sink_inputs_dump or "")
    local mutes = map_sink_input_mutes(sink_inputs_dump or "")

    for _, sink in ipairs(sinks or {}) do
        sink_map[sink.id] = sink
    end

    for _, stream in ipairs(short) do
        local p = props[stream.id] or {}
        local app_name = p["application.name"]
        local media_name = p["media.name"]
        local window_title = p["window.x11.title"] or p["application.process.title"] or p["node.description"]
        local binary = p["application.process.binary"] or p["application.process.name"]

        stream.app_name = app_name or media_name or ("Stream " .. tostring(stream.id))
        stream.media_name = media_name
        stream.window_title = window_title
        stream.binary = binary
        stream.props = p
        stream.label = stream.app_name
        stream.volume = volumes[stream.id] or nil
        stream.muted = mutes[stream.id] or false

        if stream.media_name and stream.media_name ~= stream.app_name then
            stream.label = stream.app_name .. " — " .. stream.media_name
        end

        if stream.window_title and stream.window_title ~= ""
            and stream.window_title ~= stream.media_name
            and stream.window_title ~= stream.app_name
        then
            stream.detail = stream.window_title
        elseif stream.media_name and stream.media_name ~= "" and stream.media_name ~= stream.app_name then
            stream.detail = stream.media_name
        elseif stream.binary and stream.binary ~= "" and stream.binary ~= stream.app_name then
            stream.detail = stream.binary
        end

        local sink = sink_map[stream.sink_id]
        if sink then
            stream.sink_name = sink.name
            stream.sink_label = sink.label or sink.name
        end
    end

    return short
end

local function build_source_outputs(short_out, source_outputs_dump, sources)
    local short = parse_tabular_short_list(short_out or "", "source-output")
    local mutes = map_source_output_mutes(source_outputs_dump or "")
    local volumes = map_source_output_volumes(source_outputs_dump or "")
    local props = map_stream_props_by_id(source_outputs_dump or "")
    local source_map = {}

    for _, source in ipairs(sources or {}) do
        source_map[source.id] = source
    end

    for _, source_output in ipairs(short) do
        local p = props[source_output.id] or {}
        local app_name = p["application.name"]
        local media_name = p["media.name"]
        local window_title = p["window.x11.title"] or p["application.process.title"] or p["node.description"]
        local binary = p["application.process.binary"] or p["application.process.name"]

        source_output.app_name = app_name or media_name or ("Source Output " .. tostring(source_output.id))
        source_output.media_name = media_name
        source_output.window_title = window_title
        source_output.binary = binary
        source_output.props = p
        source_output.label = source_output.app_name
        source_output.volume = volumes[source_output.id] or nil
        source_output.muted = mutes[source_output.id] or false

        if source_output.media_name and source_output.media_name ~= source_output.app_name then
            source_output.label = source_output.app_name .. " — " .. source_output.media_name
        end

        local source = source_map[source_output.source_id]
        if source then
            source_output.source_name = source.name
            source_output.source_label = source.label or source.name
        end
    end

    return short
end

-- Read widget-facing default output volume and mute state from `pactl`.
local function get_volume_info()
    local sink = get_default_sink()
    if not sink then
        return { volume = 0, muted = false }
    end

    local vol_out = util.read_command("pactl get-sink-volume " .. util.shell_escape(sink) .. " 2>/dev/null") or ""
    local mute_out = util.read_command("pactl get-sink-mute " .. util.shell_escape(sink) .. " 2>/dev/null") or ""

    local pct = vol_out:match("(%d+)%%")
    local muted = mute_out:match("yes") ~= nil

    return {
        volume = math.max(0, math.min(1, (tonumber(pct or "0") or 0) / 100)),
        muted = muted,
    }
end

-- Read widget-facing default input volume and aggregate mute state for
-- recording devices. Volume tracks the default source, while mute reflects
-- whether all non-monitor sources are currently muted.
local function get_input_volume_info()
    local default_source = get_default_source()
    local sources = M.list_sources()
    local all_muted = #sources > 0

    for _, source in ipairs(sources) do
        if not source.muted then
            all_muted = false
            break
        end
    end

    if not default_source then
        return {
            volume = 0,
            muted = all_muted,
        }
    end

    local vol_out = util.read_command("pactl get-source-volume " .. util.shell_escape(default_source) .. " 2>/dev/null") or ""
    local pct = vol_out:match("(%d+)%%")

    return {
        volume = math.max(0, math.min(1, (tonumber(pct or "0") or 0) / 100)),
        muted = all_muted,
    }
end

parse_first_percent = function(s)
    if not s then
        return nil
    end

    local pct = s:match("(%d+)%%")
    if not pct then
        return nil
    end

    return tonumber(pct)
end

local function clamp_percent(value)
    return math.max(0, math.min(100, math.floor((tonumber(value) or 0) + 0.5)))
end

local function get_sink_input_volume_percent(stream_id)
    local dump = util.read_command("pactl list sink-inputs 2>/dev/null") or ""
    local current_id = nil

    for _, line in ipairs(util.split_lines(dump)) do
        local id = line:match("^Sink Input #(%d+)")
        if id then
            current_id = id
        elseif current_id == tostring(stream_id) and line:match("^%s*Volume:") then
            local pct = parse_first_percent(line)
            if pct then
                return pct
            end
        end
    end

    return nil
end

map_sink_input_mutes = function(out)
    local result = {}

    local current_id = nil
    for _, line in ipairs(util.split_lines(out)) do
        local id = line:match("^Sink Input #(%d+)")
        if id then
            current_id = id
        elseif current_id then
            local muted = line:match("^%s*Mute:%s*(yes)")
            if muted then
                result[current_id] = true
            elseif line:match("^%s*Mute:%s*(no)") then
                result[current_id] = false
            end
        end
    end

    return result
end

map_source_output_mutes = function(out)
    local result = {}

    local current_id = nil
    for _, line in ipairs(util.split_lines(out)) do
        local id = line:match("^Source Output #(%d+)")
        if id then
            current_id = id
        elseif current_id then
            if line:match("^%s*Mute:%s*yes") then
                result[current_id] = true
            elseif line:match("^%s*Mute:%s*no") then
                result[current_id] = false
            end
        end
    end

    return result
end

map_source_output_volumes = function(out)
    local result = {}

    local current_id = nil
    for _, line in ipairs(util.split_lines(out)) do
        local id = line:match("^Source Output #(%d+)")
        if id then
            current_id = id
        elseif current_id then
            local pct = parse_first_percent(line)
            if pct and line:match("^%s*Volume:") then
                result[current_id] = pct
            end
        end
    end

    return result
end

-- Return the minimum state needed by the compact widget.
function M.get_widget_state(_opts)
    local volume_info = get_volume_info()
    local input_volume_info = get_input_volume_info()
    local src_outs = M.list_source_outputs()
    local mic_muted = input_volume_info.muted

    if #src_outs > 0 then
        mic_muted = true
        for _, source_output in ipairs(src_outs) do
            if not source_output.muted then
                mic_muted = false
                break
            end
        end
    end

    return {
        volume = volume_info.volume,
        muted = volume_info.muted,
        mic_volume = input_volume_info.volume,
        mic_muted = mic_muted,
        mic_active = #src_outs > 0,
    }
end

-- Toggle mute on the current default sink.
function M.toggle_mute()
    local sink = get_default_sink()
    if sink then
        awful.spawn("pactl set-sink-mute " .. util.shell_escape(sink) .. " toggle", false)
    end
end

-- Change default sink volume by a signed fractional delta.
function M.change_volume(delta)
    local step = math.floor(math.abs(delta) * 100 + 0.5)
    if step < 1 then
        step = 1
    end

    local sink = get_default_sink()
    if not sink then
        return
    end

    local current = get_sink_volume_percent(sink)
    if current == nil then
        return
    end

    local target = delta >= 0 and (current + step) or (current - step)
    awful.spawn("pactl set-sink-volume " .. util.shell_escape(sink) .. " " .. clamp_percent(target) .. "%", false)
end

-- Toggle mute on all non-monitor input devices so the compact mic controls
-- can act as a coarse "recording off/on" switch.
function M.toggle_input_mute()
    local sources = M.list_sources()
    local source_outputs = M.list_source_outputs()
    if #sources == 0 and #source_outputs == 0 then
        return
    end

    local should_mute = (#source_outputs > 0)
    for _, source in ipairs(sources) do
        if not source.muted then
            should_mute = true
            break
        end
    end

    if #source_outputs > 0 then
        should_mute = false
        for _, source_output in ipairs(source_outputs) do
            if not source_output.muted then
                should_mute = true
                break
            end
        end
    end

    for _, source in ipairs(sources) do
        awful.spawn(
            "pactl set-source-mute " .. util.shell_escape(source.name) .. " " .. (should_mute and "1" or "0"),
            false
        )
    end

    for _, source_output in ipairs(source_outputs) do
        awful.spawn(
            "pactl set-source-output-mute " .. util.shell_escape(source_output.id) .. " " .. (should_mute and "1" or "0"),
            false
        )
    end
end

-- Change default source volume by a signed fractional delta.
function M.change_input_volume(delta)
    local step = math.floor(math.abs(delta) * 100 + 0.5)
    if step < 1 then
        step = 1
    end

    local source = get_default_source()
    if not source then
        return
    end

    local current = get_source_volume_percent(source)
    if current == nil then
        return
    end

    local target = delta >= 0 and (current + step) or (current - step)
    awful.spawn("pactl set-source-volume " .. util.shell_escape(source) .. " " .. clamp_percent(target) .. "%", false)
end

-- List available output devices, tagging the current default sink.
function M.list_sinks()
    return build_sinks(util.read_command("pactl list short sinks 2>/dev/null"), get_default_sink())
end

-- List available input devices, excluding monitor sources.
function M.list_sources()
    return build_sources(
        util.read_command("pactl list short sources 2>/dev/null"),
        get_default_source(),
        util.read_command("pactl list sources 2>/dev/null")
    )
end

function M.set_default_sink(name)
    awful.spawn("pactl set-default-sink " .. util.shell_escape(name), false)
end

function M.set_default_source(name)
    awful.spawn("pactl set-default-source " .. util.shell_escape(name), false)
end

map_sink_input_volumes = function(out)
    local result = {}

    local current_id = nil
    for _, line in ipairs(util.split_lines(out)) do
        local id = line:match("^Sink Input #(%d+)")
        if id then
            current_id = id
        elseif current_id then
            local pct = parse_first_percent(line)
            if pct and line:match("^%s*Volume:") then
                result[current_id] = pct
            end
        end
    end

    return result
end

-- Enumerate active playback streams together with their sink routing and
-- best-effort metadata extracted from stream properties.
function M.list_sink_inputs()
    return build_sink_inputs(
        util.read_command("pactl list short sink-inputs 2>/dev/null"),
        util.read_command("pactl list sink-inputs 2>/dev/null"),
        M.list_sinks()
    )
end

-- Change volume for a single sink input rather than the default sink.
function M.change_sink_input_volume(stream_id, delta)
    local step = math.floor(math.abs(delta) * 100 + 0.5)
    if step < 1 then
        step = 1
    end

    local current = get_sink_input_volume_percent(stream_id)
    if current == nil then
        return
    end

    local target = current
    if delta >= 0 then
        target = current + step
    else
        target = current - step
    end

    M.set_sink_input_volume(stream_id, target)
end

function M.toggle_sink_input_mute(stream_id)
    awful.spawn("pactl set-sink-input-mute " .. util.shell_escape(stream_id) .. " toggle", false)
end

function M.set_sink_input_volume(stream_id, percent)
    local value = clamp_percent(percent)
    awful.spawn("pactl set-sink-input-volume " .. util.shell_escape(stream_id) .. " " .. value .. "%", false)

    if value > 0 then
        awful.spawn("pactl set-sink-input-mute " .. util.shell_escape(stream_id) .. " 0", false)
    end
end

-- Temporary compatibility aliases for partially rolled out trees where some
-- popup code may still reference the old helper names.
M.set_sink_input_value = M.set_sink_input_volume

-- Source outputs are used as a coarse "microphone currently active" signal.
function M.list_source_outputs()
    return build_source_outputs(
        util.read_command("pactl list short source-outputs 2>/dev/null"),
        util.read_command("pactl list source-outputs 2>/dev/null"),
        M.list_sources()
    )
end

function M.set_source_output_volume(source_output_id, percent)
    local value = clamp_percent(percent)
    awful.spawn("pactl set-source-output-volume " .. util.shell_escape(source_output_id) .. " " .. value .. "%", false)

    if value > 0 then
        awful.spawn("pactl set-source-output-mute " .. util.shell_escape(source_output_id) .. " 0", false)
    end
end

M.set_source_output_value = M.set_source_output_volume

function M.toggle_source_output_mute(source_output_id)
    awful.spawn("pactl set-source-output-mute " .. util.shell_escape(source_output_id) .. " toggle", false)
end

function M.collect_popup_data_async(callback)
    local commands = {
        sinks_short = "pactl list short sinks 2>/dev/null",
        sources_short = "pactl list short sources 2>/dev/null",
        sink_inputs_short = "pactl list short sink-inputs 2>/dev/null",
        source_outputs_short = "pactl list short source-outputs 2>/dev/null",
        sources_dump = "pactl list sources 2>/dev/null",
        sink_inputs_dump = "pactl list sink-inputs 2>/dev/null",
        source_outputs_dump = "pactl list source-outputs 2>/dev/null",
        default_sink = "pactl get-default-sink 2>/dev/null",
        default_source = "pactl get-default-source 2>/dev/null",
    }

    local results = {}
    local remaining = 0
    for _ in pairs(commands) do
        remaining = remaining + 1
    end

    local function finish()
        remaining = remaining - 1
        if remaining > 0 then
            return
        end

        local sinks = build_sinks(results.sinks_short, util.trim(results.default_sink or ""))
        local sources = build_sources(results.sources_short, util.trim(results.default_source or ""), results.sources_dump)
        local streams = build_sink_inputs(results.sink_inputs_short, results.sink_inputs_dump, sinks)
        local source_outputs = build_source_outputs(results.source_outputs_short, results.source_outputs_dump, sources)

        callback({
            sinks = sinks,
            sources = sources,
            streams = streams,
            source_outputs = source_outputs,
        })
    end

    for key, cmd in pairs(commands) do
        awful.spawn.easy_async_with_shell(cmd, function(stdout)
            results[key] = stdout or ""
            finish()
        end)
    end
end

function M.move_sink_input(stream_id, sink_name)
    awful.spawn("pactl move-sink-input " .. util.shell_escape(stream_id) .. " " .. util.shell_escape(sink_name), false)
end

function M.open_pavucontrol()
    awful.spawn("pavucontrol", false)
end

function M.unsubscribe()
    if subscription_debounce then
        subscription_debounce:stop()
        subscription_debounce = nil
    end

    if subscription_pid then
        awful.spawn("kill " .. tostring(subscription_pid), false)
        subscription_pid = nil
    end
end

local function ensure_subscription_exit_hook()
    if subscription_exit_hook_registered then
        return
    end

    subscription_exit_hook_registered = true

    if awesome and awesome.connect_signal then
        awesome.connect_signal("exit", function()
            M.unsubscribe()
        end)
    end
end

-- Subscribe to backend events once and debounce bursts of `pactl subscribe`
-- output into a single callback.
function M.subscribe(callback)
    if subscription_pid then
        return subscription_pid
    end

    ensure_subscription_exit_hook()

    subscription_debounce = gears.timer({
        timeout = 0.15,
        autostart = false,
        single_shot = true,
        callback = function()
            callback()
        end,
    })

    subscription_pid = awful.spawn.with_line_callback("pactl subscribe", {
        stdout = function(_line)
            if subscription_debounce.started then
                subscription_debounce:again()
            else
                subscription_debounce:start()
            end
        end,
        stderr = function(_line)
            -- ignore
        end,
        exit = function()
            if subscription_debounce then
                subscription_debounce:stop()
                subscription_debounce = nil
            end
            subscription_pid = nil
        end,
    })

    return subscription_pid
end

return M
