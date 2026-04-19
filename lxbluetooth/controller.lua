local popup_controller = require("lxcommon.popup_controller")

local controller = {}

---Attach popup session-control methods to the lxbluetooth instance method table.
function controller.extend(instance_methods)
    popup_controller.extend(instance_methods)
end

return controller
