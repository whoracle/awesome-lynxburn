local gears = require("gears")

local popup_controller = require("lxcommon.popup_controller")
local popup = require("lxsecrets.popup")
local state = require("lxsecrets.state")
local theme = require("lxsecrets.theme")

local M = {}
M.__index = M

local DEFAULTS = {
    at_start = true,
    interval = "30m",
    top_level = "always",
    cycle_exclude = true,
    thresholds = {
        gitlab = "30d",
        hashicorp_vault = "7d",
    },
    lifetimes = {
        gitlab = "365d",
    },
    secrets = {},
}

local function deep_copy(source)
    local out = {}

    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            out[key] = deep_copy(value)
        else
            out[key] = value
        end
    end

    return out
end

local function merge_defaults(opts)
    local merged = deep_copy(DEFAULTS)

    for key, value in pairs(opts or {}) do
        if type(value) == "table" and type(merged[key]) == "table" then
            for subkey, subvalue in pairs(value) do
                merged[key][subkey] = subvalue
            end
        else
            merged[key] = value
        end
    end

    return merged
end

theme.extend(M)
state.extend(M)
popup.extend(M)
popup_controller.extend(M, {
    popup_key = "_popup",
    actions = {
        Right = function(self)
            self:activate_selected_popup_secondary()
        end,
    },
})

function M.new(opts)
    opts = merge_defaults(opts)

    local self = setmetatable({}, M)
    self.opts = opts
    self._refs = {}
    self.state = {
        suspended = opts.suspended == true,
        secrets = {},
    }
    self._popup_selected_index = 1
    self.state.secrets = self:_normalize_secrets(opts.secrets)

    self:_build_widget()
    self:_start_timer()

    if self.opts.at_start ~= false and #self.state.secrets > 0 and not self.state.suspended then
        gears.timer.delayed_call(function()
            self:refresh_all()
        end)
    end

    return self
end

return M
