local beautiful = require("beautiful")
local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local metric = require("widgets.metric")

local markup = require("widgets.markup")

return function(context)
    local config_data = require("config.config_data")
    local commands = config_data.commands()
    local imap_commands = commands.imap or {}
    local mail_account = imap_commands.imap_mail
    local mail_password_lookup = imap_commands.imap_secret
    local mail_server = imap_commands.imap_server
    local mail_login_options = imap_commands.imap_login_options or "AUTH=LOGIN"
    local mail_timeout = tonumber(imap_commands.imap_timeout) or 60
    local theme = context and context.beautiful or beautiful

    if not mail_account or not mail_password_lookup or not mail_server then
        return nil
    end

    local mail_icon = metric.icon(theme.icon_mail)

    local mail_widget = wibox.widget.textbox()
    local password

    local function update_count(mailcount)
        local count = ""

        if mailcount > 0 then
            count = markup.font(theme.font, (theme.space or " ") .. mailcount .. (theme.space or " "))
            metric.show(mail_icon)
        else
            metric.hide(mail_icon)
        end

        mail_widget:set_markup(count)
    end

    local function request_status()
        if type(password) ~= "string" then
            return
        end

        local curl = {
            "curl",
            "--connect-timeout", "3",
            "-f",
            "-s",
            "-m", "3",
            "--url", string.format("imaps://%s:993/INBOX", mail_server),
            "-u", string.format("%s:%s", mail_account, password),
            "-X", "STATUS INBOX (MESSAGES RECENT UNSEEN)",
            "-k",
        }

        if type(mail_login_options) == "string" and #mail_login_options > 0 then
            curl[#curl + 1] = "--login-options"
            curl[#curl + 1] = mail_login_options
        end

        awful.spawn.easy_async(curl, function(stdout, _, _, exit_code)
            if exit_code ~= 0 then
                return
            end

            local unseen = 0
            for name, value in stdout:gmatch("(%w+)%s+(%d+)") do
                if name == "UNSEEN" then
                    unseen = tonumber(value) or 0
                    break
                end
            end

            update_count(unseen)
        end)
    end

    local function load_password(callback)
        if type(password) == "string" then
            callback()
            return
        end

        local function done(stdout, _, _, exit_code)
            if exit_code == 0 then
                password = stdout:gsub("\n", "")
            end
            callback()
        end

        if type(mail_password_lookup) == "table" then
            awful.spawn.easy_async(mail_password_lookup, done)
        else
            awful.spawn.easy_async_with_shell(mail_password_lookup, done)
        end
    end

    local function refresh()
        load_password(request_status)
    end

    local timer = gears.timer({ timeout = mail_timeout })
    timer:connect_signal("timeout", refresh)
    timer:start()
    refresh()

    return {
        widget = wibox.widget({
            {
                mail_icon,
                mail_widget,
                layout = wibox.layout.fixed.horizontal,
            },
            draw_empty = false,
            widget = wibox.container.margin,
        }),
        style = "lxbar",
    }
end
