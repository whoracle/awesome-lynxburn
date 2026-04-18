local M = {}

local function resolve_widget(target)
    if not target then
        return nil
    end

    if target._lx_set_feedback_active then
        return target
    end

    if target._feedback_widget and target._feedback_widget._lx_set_feedback_active then
        return target._feedback_widget
    end

    if target.widget and target.widget._lx_set_feedback_active then
        return target.widget
    end

    if target._widget_refs and target._widget_refs.root and target._widget_refs.root._lx_set_feedback_active then
        return target._widget_refs.root
    end

    return nil
end

function M.set_active(target, value)
    local widget = resolve_widget(target)
    if widget and widget._lx_set_feedback_active then
        widget:_lx_set_feedback_active(value and true or false)
    end
end

function M.sync(target, active)
    if type(active) == "function" then
        M.set_active(target, active())
        return
    end

    M.set_active(target, active)
end

return M
