local keygrabber = require("awful.keygrabber")

local M = {}

local active = nil
local grabber = nil
local dispatching = false
local stop_after_dispatch = false

local function grabber_running()
    return grabber and (grabber.is_running or grabber.grabber)
end

local function stop_grabber()
    if grabber_running() then
        grabber:stop()
    end
end

local function clear_active()
    local session = active
    active = nil

    if session then
        if session.active_key then
            session.owner[session.active_key] = false
        end

        if type(session.on_stop) == "function" then
            session.on_stop(session.owner)
        end
    end
end

local function ensure_grabber()
    if grabber then
        return grabber
    end

    grabber = keygrabber({
        keypressed_callback = function(_, modifiers, key, event)
            if not active then
                stop_grabber()
                return
            end

            dispatching = true
            stop_after_dispatch = false

            local session = active
            local handler = session.handler
            if type(handler) == "function" then
                handler(nil, modifiers, key, event)
            end

            dispatching = false
            if stop_after_dispatch and not active then
                stop_grabber()
            end
        end,
        stop_callback = function()
            clear_active()
        end,
    })

    return grabber
end

function M.activate(owner, opts)
    opts = opts or {}

    if active and active.owner ~= owner and active.active_key then
        active.owner[active.active_key] = false
    end

    active = {
        owner = owner,
        handler = opts.handler,
        active_key = opts.active_key,
        on_stop = opts.on_stop,
    }
    stop_after_dispatch = false

    if opts.active_key then
        owner[opts.active_key] = true
    end

    local g = ensure_grabber()
    if not grabber_running() then
        local started = g:start()
        if started == false then
            clear_active()
            return false
        end
    end

    if type(opts.on_start) == "function" then
        opts.on_start(owner)
    end

    return true
end

function M.release(owner, opts)
    opts = opts or {}

    if opts.active_key then
        owner[opts.active_key] = false
    end

    if not (active and active.owner == owner) then
        return
    end

    active = nil

    if dispatching then
        stop_after_dispatch = true
        return
    end

    stop_grabber()
end

function M.is_active(owner)
    return active and active.owner == owner or false
end

return M
