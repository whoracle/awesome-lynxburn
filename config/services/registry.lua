local module_config = require("config.lxmodules")
local popup_cycle = require("config.services.popup_cycle")
local state = require("config.services.state")

local common_registry = require("lxcommon.registry")
local popup_manager = require("lxcommon.popup_manager")

local M = {}

---Configure the widget registry order from the current lxbar module order.
function M.configure_widget_registry()
    common_registry.set_order(module_config.order())
end

---Register a top-level lx widget with the shared widget registry.
---@param id string
---@param widget table
---@param default_order number
---@param opts? table
function M.register_widget(id, widget, default_order, opts)
    opts = opts or {}

    common_registry.register({
        id = id,
        widget = widget,
        default_order = default_order,
        enabled = function()
            return module_config.enabled(id, false)
        end,
        include_in_popup_cycle = module_config.cycle_enabled(id, opts.include_in_popup_cycle),
    })

    local bar = state.get("bar")
    if bar then
        bar:refresh()
    end
end

local function build_popup_handle(module_id, popup_id, spec)
    return {
        open = function(opts)
            local popup_opts = popup_cycle.options(opts)
            popup_opts.cycle_anchor = {
                module_id = module_id,
                popup_id = popup_id,
            }

            if spec.hover_close ~= nil then
                popup_opts.hover_close = spec.hover_close
            end

            spec.open(popup_opts)
        end,
        close = spec.close,
        is_visible = spec.is_visible,
        shared_shell = spec.shared_shell,
    }
end

---Register one semantic popup handle for popup-manager/lxbar integration.
---@param module_id string
---@param popup_id string
---@param popup_role string
---@param spec table
function M.register_semantic_popup(module_id, popup_id, popup_role, spec)
    popup_manager.register(module_id, popup_id, build_popup_handle(module_id, popup_id, spec), {
        popup_role = popup_role,
    })
end

return M
