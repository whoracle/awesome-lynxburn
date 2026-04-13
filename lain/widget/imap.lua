--[[

     Licensed under GNU General Public License v2
      * (c) 2013, Luca CPZ

--]]

local helpers  = require("lain.helpers")
local naughty  = require("naughty")
local wibox    = require("wibox")
local awful    = require("awful")
local gdebug   = require("gears.debug")
local string   = string
local type     = type
local tonumber = tonumber

-- Mail IMAP check
-- lain.widget.imap

local function factory(args)
    args             = args or {}

    local imap       = { widget = args.widget or wibox.widget.textbox() }
    local server     = args.server
    local mail       = args.mail
    local password   = args.password
    local port       = args.port or 993
    local timeout    = args.timeout or 60
    local pwdtimeout = args.pwdtimeout or 10
    local is_plain   = args.is_plain or false
    local followtag  = args.followtag or false
    local notify     = args.notify or "on"
    local login_options = args.login_options
    local settings   = args.settings or function() end

    local request = "STATUS INBOX (MESSAGES RECENT UNSEEN)"

    if not server or not mail or not password then return end

    mail_notification_preset = {
        icon     = helpers.icons_dir .. "mail.png",
        position = "top_left"
    }

    helpers.set_map(mail, 0)

    if not is_plain then
        if type(password) == "string" or type(password) == "table" then
            local password_cmd = password
            password = nil
            helpers.async(password_cmd, function(f, exit_code)
                if exit_code ~= 0 then
                    gdebug.print_warning(string.format("lain.widget.imap: password lookup failed for %s (exit %s)", mail, tostring(exit_code)))
                    password = ""
                    return
                end

                password = f:gsub("\n", "")
                imap.update()
            end)
        elseif type(password) == "function" then
            imap.pwdtimer = helpers.newtimer(mail .. "-password", pwdtimeout, function()
                local retrieved_password, try_again = password()
                if not try_again then
                    imap.pwdtimer:stop() -- stop trying to retrieve
                    password = retrieved_password or "" -- failsafe
                    imap.update()
                end
            end, true, true)
        end
    end

    function imap.update()
        -- do not update if the password has not been retrieved yet
        if type(password) ~= "string" then return end

        local curl = {
            "curl",
            "--connect-timeout", "3",
            "-f",
            "-s",
            "-m", "3",
            "--url", string.format("imaps://%s:%s/INBOX", server, port),
            "-u", string.format("%s:%s", mail, password),
            "-X", request,
            "-k",
        }

        if type(login_options) == "string" and #login_options > 0 then
            curl[#curl + 1] = "--login-options"
            curl[#curl + 1] = login_options
        end

        helpers.async(curl, function(f, exit_code)
            if exit_code ~= 0 then
                gdebug.print_warning(string.format("lain.widget.imap: IMAP request failed for %s (exit %s)", mail, tostring(exit_code)))
                return
            end

            imap_now = { ["MESSAGES"] = 0, ["RECENT"] = 0, ["UNSEEN"] = 0 }

            for s,d in f:gmatch("(%w+)%s+(%d+)") do imap_now[s] = tonumber(d) end
            mailcount = imap_now["UNSEEN"] -- backwards compatibility
            widget = imap.widget

            settings()

            if notify == "on" and mailcount and mailcount >= 1 and mailcount > helpers.get_map(mail) then
                if followtag then mail_notification_preset.screen = awful.screen.focused() end
                naughty.notify {
                    preset = mail_notification_preset,
                    text   = string.format("%s has <b>%d</b> new message%s", mail, mailcount, mailcount == 1 and "" or "s")
                }
            end

            helpers.set_map(mail, imap_now["UNSEEN"])
        end)

    end

    imap.timer = helpers.newtimer(mail, timeout, imap.update, true, true)
    if is_plain and type(password) == "string" then
        imap.update()
    end

    return imap
end

return factory
