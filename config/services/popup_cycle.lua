local config_data = require("config.config_data")
local state = require("config.services.state")

local M = {}

local function merge(defaults, overrides)
    local merged = {}

    for key, value in pairs(defaults or {}) do
        merged[key] = value
    end

    for key, value in pairs(overrides or {}) do
        merged[key] = value
    end

    return merged
end

local function keychains()
    local settings = config_data.settings()

    return {
        prev = {
            modifiers = { settings.modkey, settings.altkey, settings.ctrlkey },
            key = "Left",
        },
        next = {
            modifiers = { settings.modkey, settings.altkey, settings.ctrlkey },
            key = "Right",
        },
    }
end

---Build popup-manager options for lxbar popup cycling.
---@param overrides? table
---@return table
function M.options(overrides)
    overrides = overrides or {}
    local keychain_settings = keychains()
    local defaults = {
        keyboard_navigation = true,
        width = 360,
        prev_keychain = keychain_settings.prev,
        next_keychain = keychain_settings.next,
        on_cycle_prev = function(anchor)
            local bar = state.get("bar")

            if bar then
                bar:cycle_popups_from(anchor, -1, M.options())
            end
        end,
        on_cycle_next = function(anchor)
            local bar = state.get("bar")

            if bar then
                bar:cycle_popups_from(anchor, 1, M.options())
            end
        end,
    }

    return merge(defaults, overrides)
end

return M
