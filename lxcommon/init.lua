local M = {}

-- Public re-export surface for shared lx* helpers. Keep this intentionally
-- small so modules can depend on lxcommon without knowing its file layout.
M.osd = require("lxcommon.osd")
M.popup_control = require("lxcommon.popup_control")
M.popup_controller = require("lxcommon.popup_controller")
M.popup_manager = require("lxcommon.popup_manager")
M.popup_placement = require("lxcommon.popup_placement")
M.popup_session = require("lxcommon.popup_session")
M.popup_ui = require("lxcommon.popup_ui")
M.registry = require("lxcommon.registry")
M.screen = require("lxcommon.screen")
M.util = require("lxcommon.util")
M.widget_feedback = require("lxcommon.widget_feedback")

return M
