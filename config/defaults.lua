local helpers = require("config.helpers")
local platform = require("config.platform")

local shared = require("config.defaults_shared")
local awesome_defaults = require("config.defaults_awesome")
local somewm_defaults = require("config.defaults_somewm")

local M = helpers.deep_merge({}, shared)

if platform.effective_target() == "somewm" or platform.is_wayland() then
    helpers.deep_merge(M, somewm_defaults)
else
    helpers.deep_merge(M, awesome_defaults)
end

return M
