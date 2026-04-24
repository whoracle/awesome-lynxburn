local beautiful = require("beautiful")
local lain = require("lain")
local wibox = require("wibox")

local config_data = require("config.config_data")

local markup = lain.util.markup

return function(context)
    local commands = config_data.commands()
    local lain_commands = commands.lain or {}
    local mail_account = lain_commands.imap_mail
    local mail_password_lookup = lain_commands.imap_secret
    local mail_server = lain_commands.imap_server
    local mail_login_options = lain_commands.imap_login_options or "AUTH=LOGIN"
    local mail_timeout = tonumber(lain_commands.imap_timeout) or 60
    local theme = context and context.beautiful or beautiful

    if not mail_account or not mail_password_lookup or not mail_server then
        return nil
    end

    local mail_icon = wibox.widget.imagebox(theme.icon_mail)
    mail_icon.forced_width = 0
    mail_icon.forced_height = 0

    local mail = lain.widget.imap({
        timeout = mail_timeout,
        server = mail_server,
        mail = mail_account,
        password = mail_password_lookup,
        login_options = mail_login_options,
        settings = function()
            local count = ""

            if mailcount > 0 then
                count = markup.font(theme.font, (theme.space or " ") .. mailcount .. (theme.space or " "))
                mail_icon.forced_width = nil
                mail_icon.forced_height = nil
            else
                mail_icon.forced_width = 0
                mail_icon.forced_height = 0
            end

            widget:set_markup(count)
        end,
    })

    if not mail or not mail.widget then
        return nil
    end

    return {
        widget = wibox.widget({
            {
                mail_icon,
                mail.widget,
                layout = wibox.layout.fixed.horizontal,
            },
            draw_empty = false,
            widget = wibox.container.margin,
        }),
        style = "lxbar",
    }
end
