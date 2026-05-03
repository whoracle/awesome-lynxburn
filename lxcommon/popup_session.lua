local awful = require("awful")

local popup_placement = require("lxcommon.popup_placement")

local M = {}

local session = {
    popup = nil,
    owner = nil,
    popup_key = nil,
}

local function is_geometry(value)
    return type(value) == "table"
        and type(value.x) == "number"
        and type(value.y) == "number"
        and type(value.width) == "number"
        and type(value.height) == "number"
end

local function deactivate_current(run_hook)
    if not session.owner then
        return
    end

    local owner = session.owner
    local popup_key = session.popup_key

    owner._popup_session_active = false
    if popup_key and owner[popup_key] == session.popup then
        owner[popup_key] = nil
    end

    if run_hook ~= false and type(owner._deactivate_popup_session) == "function" then
        owner:_deactivate_popup_session()
    end

    if session.owner == owner then
        session.owner = nil
        session.popup_key = nil
    end
end

local function ensure_popup(opts)
    opts = opts or {}

    if not session.popup then
        session.popup = awful.popup({
            visible = false,
            ontop = true,
            type = "dock",
            bg = opts.bg,
            border_width = 0,
            preferred_positions = { "bottom", "top" },
            preferred_anchors = { "middle", "front", "back" },
            offset = { y = 6 },
            widget = opts.widget,
        })
    end

    return session.popup
end

local function apply_geometry(instance, popup, anchor, opts)
    opts = opts or {}

    if opts.placement then
        popup_placement.apply(
            popup,
            opts.screen or awful.screen.focused(),
            opts.placement,
            { width = opts.width or popup.minimum_width or popup.maximum_width or 420 }
        )
        return
    end

    local anchor_mode = opts.anchor or "widget"
    if anchor_mode == "widget" then
        local resolved = is_geometry(anchor) and anchor or instance._last_anchor_geo
        if not resolved and instance._resolve_anchor_geo then
            resolved = instance:_resolve_anchor_geo()
        end

        if is_geometry(resolved) then
            popup:move_next_to(resolved)
            return
        end
    end

    popup_placement.apply(
        popup,
        opts.screen or awful.screen.focused(),
        "center",
        { width = opts.width or popup.minimum_width or popup.maximum_width or 420 }
    )
end

function M.show(instance, popup_key, anchor, builder, opts)
    opts = opts or {}

    if session.owner ~= instance or session.popup_key ~= popup_key then
        deactivate_current(true)
    end

    local widget = builder(instance)
    local popup = ensure_popup({ bg = opts.bg, widget = widget })

    if opts.bg then
        popup.bg = opts.bg
    end

    if is_geometry(anchor) then
        instance._last_anchor_geo = anchor
    end

    popup.widget = widget
    popup.visible = true

    instance[popup_key] = popup
    instance._popup_session_active = true
    session.owner = instance
    session.popup_key = popup_key

    apply_geometry(instance, popup, anchor, opts)
    return true
end

function M.close(instance, popup_key)
    if session.owner ~= instance or session.popup_key ~= popup_key then
        if instance then
            instance._popup_session_active = false
            if popup_key and instance[popup_key] == session.popup then
                instance[popup_key] = nil
            end
        end
        return
    end

    if session.popup then
        session.popup.visible = false
    end

    deactivate_current(false)
end

function M.is_visible(instance, popup_key)
    return session.owner == instance
        and session.popup_key == popup_key
        and session.popup
        and session.popup.visible
        and instance._popup_session_active == true
        or false
end

function M.geometry(instance, popup_key)
    if not M.is_visible(instance, popup_key) then
        return nil
    end

    return session.popup and session.popup:geometry() or nil
end

return M
