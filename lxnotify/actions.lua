local naughty = require("naughty")

local actions = {}

local function activate_client(client)
    if not client then
        return false
    end

    client:emit_signal("request::activate", "lxnotify", { raise = true })
    return true
end

---Dismiss the underlying naughty notification if its API allows it.
---@param notification table|nil
function actions.destroy(notification)
    if not notification then
        return
    end

    if type(notification.destroy) == "function" then
        pcall(notification.destroy, notification, naughty.notification_closed_reason.dismissed_by_user)
        return
    end

    if type(notification.die) == "function" then
        pcall(notification.die, notification, naughty.notification_closed_reason.dismissed_by_user)
    end
end

---Invoke the notification's primary action or best fallback.
---@param notification table|nil
---@return boolean
function actions.invoke(notification)
    if not notification then
        return false
    end

    if type(notification.get_clients) == "function" then
        local ok, clients = pcall(notification.get_clients, notification)
        if ok and type(clients) == "table" then
            for _, client in ipairs(clients) do
                if activate_client(client) then
                    return true
                end
            end
        end
    end

    if type(notification.run) == "function" then
        notification.run(notification)
        return true
    end

    if type(notification.callback) == "function" then
        local private = rawget(notification, "_private")
        local args = private and private.args or {}
        notification.callback(args)
        return true
    end

    local actions_list = notification.actions
    if type(actions_list) == "table" and actions_list[1] and type(actions_list[1].invoke) == "function" then
        actions_list[1]:invoke(notification)
        return true
    end

    return false
end

return actions
