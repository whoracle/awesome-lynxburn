local awful = require("awful")
local config_data = require("config.config_data")

local M = {}

---Build the Awesome client rule list.
---
---Per-application placement, floating/maximized defaults, and monitor/tag
---assignments belong here.
---@param context {beautiful:table,clientkeys:any,clientbuttons:any,monitors:table,tags:string[]}
---@return table[]
function M.build(context)
    local beautiful = context.beautiful
    local clientkeys = context.clientkeys
    local clientbuttons = context.clientbuttons
    local rules = {
        {
            rule = {},
            properties = {
                border_width = beautiful.border_width,
                border_color = beautiful.border_normal,
                callback = awful.client.setslave,
                focus = awful.client.focus.filter,
                raise = true,
                keys = clientkeys,
                buttons = clientbuttons,
                screen = awful.screen.preferred,
                placement = awful.placement.no_overlap + awful.placement.no_offscreen,
                size_hints_honor = false,
            },
        },
        {
            rule_any = { type = { "dialog", "normal" } },
            properties = { titlebars_enabled = false },
        },
    }

    local override_rules = config_data.rules()

    if type(override_rules) == "function" then
        override_rules = override_rules(context)
    end

    if type(override_rules) == "table" then
        for _, rule in ipairs(override_rules) do
            rules[#rules + 1] = rule
        end
    end

    return rules
end

return M
