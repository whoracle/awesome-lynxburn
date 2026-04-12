local M = {}

function M.setup_error_handling(awesome, naughty)
    if awesome.startup_errors then
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, there were errors during startup!",
            text = awesome.startup_errors,
        })
    end

    local in_error = false

    awesome.connect_signal("debug::error", function(err)
        if in_error then
            return
        end

        in_error = true
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err),
        })
        in_error = false
    end)
end

function M.run_once(awful, commands)
    for _, cmd in ipairs(commands) do
        local findme = cmd
        local firstspace = cmd:find(" ")

        if firstspace then
            findme = cmd:sub(0, firstspace - 1)
        end

        awful.spawn.with_shell(
            string.format("pgrep -u $USER -x %s > /dev/null || (%s)", findme, cmd)
        )
    end
end

return M
