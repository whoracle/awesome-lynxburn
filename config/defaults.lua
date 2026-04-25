local helpers = require("config.helpers")
local platform = require("config.platform")

local shared = require("config.defaults_shared")

local M = helpers.deep_merge({}, shared)

if platform.effective_target() == "somewm" or platform.is_wayland() then
    helpers.deep_merge(M, require("config.defaults_somewm"))
else
    helpers.deep_merge(M, require("config.defaults_awesome"))
end

return M
