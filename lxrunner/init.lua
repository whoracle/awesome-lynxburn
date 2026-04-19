local gears = require("gears")

local history = require("lxrunner.history")
local sources = require("lxrunner.sources")
local ui = require("lxrunner.ui")
local controller = require("lxrunner.controller")

local M = {}
M.__index = M

local DEFAULTS = {
    width = 520,
    row_count = 5,
    history_limit = 5,
    history_file = function()
        return (os.getenv("HOME") or "") .. "/.lxrunner_history"
    end,
    prompt = "Run",
}

local function resolve_default(value)
    if type(value) == "function" then
        return value()
    end

    return value
end

local function merge_defaults(opts)
    opts = opts or {}

    local merged = {}
    for k, v in pairs(DEFAULTS) do
        merged[k] = resolve_default(v)
    end

    for k, v in pairs(opts) do
        merged[k] = v
    end

    return merged
end

sources.extend(M)
history.extend(M)
ui.extend(M)
controller.extend(M)

---Create a new lxrunner instance.
---@param opts? table
---@return table
function M.new(opts)
    opts = merge_defaults(opts)

    local self = setmetatable({}, M)
    self.opts = opts
    self.visible = false
    self._input = ""
    self._path_commands = nil
    self._desktop_entries = nil
    self._aliases = {}
    self._history = {}
    self._matches = {}
    self._selected_index = 1
    self._mousegrabber_running = false
    -- Source-specific fallback icons live in the module so themes only need to
    -- supply styling, not assets.
    self._icons = {
        alias = gears.filesystem.get_configuration_dir() .. "lxrunner/icons/alias.svg",
        path = gears.filesystem.get_configuration_dir() .. "lxrunner/icons/path.svg",
        desktop = gears.filesystem.get_configuration_dir() .. "lxrunner/icons/desktop.svg",
    }

    self:_build_popup()

    return self
end

return M
