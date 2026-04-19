local gears = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local config_data = require("config.config_data")
local actions_builder = require("config.keys.actions")
local bindings = require("config.keys.bindings")
local tags = require("config.keys.tags")

local M = {}

---Register a small set of non-Awesome default hotkey hints for the popup.
local function register_extra_hotkeys()
end

---Build root and client keymaps from the shared config context.
---
---This module intentionally owns only keybinding definitions and their local
---helper functions. Application commands live in the centralized `commands`
---config section, and long-lived
---widget/module state is passed in through `context`.
---@param context table
---@return {globalkeys:any, clientkeys:any}
function M.build(context)
    local my_table = context.my_table or gears.table
    local settings = context.settings
    local lxmedia = context.lxmedia
    local key_config = config_data.keys()

    register_extra_hotkeys()
    local actions = actions_builder.build({
        settings = settings,
        runtime = context.runtime,
        commands = context.commands,
        lxnotify = context.lxnotify,
        lxmedia = lxmedia,
        lxbar = context.lxbar,
        lxbluetooth = context.lxbluetooth,
        lxdisplay = context.lxdisplay,
        lxnetwork = context.lxnetwork,
        lxrunner = context.lxrunner,
        lxpower = context.lxpower,
        osd = context.osd,
        lain = context.lain,
        layouts = context.layouts,
        hotkeys_popup = hotkeys_popup,
        quake = context.quake,
    })

    local global_spec_order = {}
    local client_spec_order = {}
    local global_specs = {}
    local client_specs = {}
    local ordered_action_ids, action_bindings = bindings.collect_binding_entries(settings, key_config)

    bindings.populate_scope_specs(global_specs, global_spec_order, action_bindings, ordered_action_ids, "global")
    bindings.populate_scope_specs(client_specs, client_spec_order, action_bindings, ordered_action_ids, "client")

    tags.extend(actions, global_specs, global_spec_order, settings)

    if not bindings.has_binding(global_specs, { settings.modkey, settings.altkey, settings.ctrlkey }, "Left")
        and not bindings.has_binding(client_specs, { settings.modkey, settings.altkey, settings.ctrlkey }, "Left") then
        global_spec_order[#global_spec_order + 1] = "commands_cycle_lxbar_popups_backward"
        global_specs.commands_cycle_lxbar_popups_backward =
            bindings.key_spec(
                { settings.modkey, settings.altkey, settings.ctrlkey },
                "Left",
                "cycle_lxbar_popups_backward",
                "cycle lxbar popups backward",
                "04. commands"
            )
    end

    if not bindings.has_binding(global_specs, { settings.modkey, settings.altkey, settings.ctrlkey }, "Right")
        and not bindings.has_binding(client_specs, { settings.modkey, settings.altkey, settings.ctrlkey }, "Right") then
        global_spec_order[#global_spec_order + 1] = "commands_cycle_lxbar_popups_forward"
        global_specs.commands_cycle_lxbar_popups_forward =
            bindings.key_spec(
                { settings.modkey, settings.altkey, settings.ctrlkey },
                "Right",
                "cycle_lxbar_popups_forward",
                "cycle lxbar popups forward",
                "04. commands"
            )
    end

    if lxmedia and lxmedia.set_popup_key_actions then
        lxmedia:set_popup_key_actions(actions_builder.build_lxmedia_popup_key_actions(global_specs))
    end

    local keymaps = {
        globalkeys = bindings.compile_key_specs(global_specs, global_spec_order, actions, my_table.join),
        clientkeys = bindings.compile_key_specs(client_specs, client_spec_order, actions, my_table.join),
    }

    return keymaps
end

return M
