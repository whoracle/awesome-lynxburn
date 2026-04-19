local awful = require("awful")

local helpers = require("config.helpers")

local M = {}

local unpack = table.unpack or unpack

local function key_spec(modifiers, key, on_press, description, group, extra)
    local spec = {
        modifiers = modifiers,
        key = key,
        on_press = on_press,
        description = description,
        group = group,
    }

    if type(extra) == "table" then
        helpers.deep_merge(spec, extra)
    end

    return spec
end

local function resolve_modifier_alias(settings, modifier)
    if modifier == "modkey" then
        return settings.modkey
    end

    if modifier == "altkey" then
        return settings.altkey
    end

    if modifier == "ctrlkey" then
        return settings.ctrlkey
    end

    if modifier == "shiftkey" then
        return settings.shiftkey
    end

    return modifier
end

local function normalize_key_spec(settings, spec)
    if type(spec) ~= "table" then
        return spec
    end

    local normalized = {}

    for key, value in pairs(spec) do
        normalized[key] = value
    end

    if type(spec.modifiers) == "table" then
        normalized.modifiers = {}

        for index, modifier in ipairs(spec.modifiers) do
            normalized.modifiers[index] = resolve_modifier_alias(settings, modifier)
        end
    end

    return normalized
end

local function is_binding_spec(value)
    return type(value) == "table"
        and (value.scope ~= nil
            or value.key ~= nil
            or value.modifiers ~= nil
            or value.on_press ~= nil
            or value.on_release ~= nil)
end

local function binding_entry_name(action_id, index)
    if index == nil then
        return action_id
    end

    return string.format("%s[%d]", action_id, index)
end

function M.key_spec(...)
    return key_spec(...)
end

function M.collect_binding_entries(settings, key_config)
    local ordered_action_ids = key_config.order or {}
    local action_bindings = {}

    for action_id, value in pairs(key_config) do
        if action_id ~= "order" then
            local bindings = {}

            if is_binding_spec(value) then
                bindings[1] = {
                    name = binding_entry_name(action_id),
                    spec = normalize_key_spec(settings, value),
                }
            elseif type(value) == "table" then
                for index, spec in ipairs(value) do
                    if is_binding_spec(spec) then
                        bindings[#bindings + 1] = {
                            name = binding_entry_name(action_id, index),
                            spec = normalize_key_spec(settings, spec),
                        }
                    end
                end
            end

            if #bindings > 0 then
                action_bindings[action_id] = bindings
            end
        end
    end

    return ordered_action_ids, action_bindings
end

local function append_binding_entry(target_specs, target_order, entry)
    local spec = {}

    for key, value in pairs(entry.spec) do
        if key ~= "scope" then
            spec[key] = value
        end
    end

    target_specs[entry.name] = spec
    target_order[#target_order + 1] = entry.name
end

function M.populate_scope_specs(target_specs, target_order, action_bindings, ordered_action_ids, scope)
    local seen = {}

    for _, action_id in ipairs(ordered_action_ids) do
        local bindings = action_bindings[action_id]

        if bindings then
            seen[action_id] = true

            for _, entry in ipairs(bindings) do
                if (entry.spec.scope or "global") == scope then
                    append_binding_entry(target_specs, target_order, entry)
                end
            end
        end
    end

    local extra_action_ids = {}

    for action_id in pairs(action_bindings) do
        if not seen[action_id] then
            extra_action_ids[#extra_action_ids + 1] = action_id
        end
    end

    table.sort(extra_action_ids)

    for _, action_id in ipairs(extra_action_ids) do
        for _, entry in ipairs(action_bindings[action_id]) do
            if (entry.spec.scope or "global") == scope then
                append_binding_entry(target_specs, target_order, entry)
            end
        end
    end
end

local function sorted_extra_names(specs, ordered_names)
    local seen = {}

    for _, name in ipairs(ordered_names) do
        seen[name] = true
    end

    local extra_names = {}

    for name in pairs(specs) do
        if not seen[name] then
            extra_names[#extra_names + 1] = name
        end
    end

    table.sort(extra_names)

    return extra_names
end

local function resolve_action(actions, action_name, binding_name, phase)
    if action_name == nil then
        return nil
    end

    if type(action_name) == "function" then
        return action_name
    end

    local action = actions[action_name]

    if type(action) ~= "function" then
        error(string.format("Unknown %s action '%s' for key binding '%s'", phase, tostring(action_name), binding_name))
    end

    return action
end

local function build_key_object(binding_name, spec, actions)
    if spec.disabled then
        return nil
    end

    local metadata = {}

    for key, value in pairs(spec) do
        if key ~= "disabled"
            and key ~= "key"
            and key ~= "modifiers"
            and key ~= "on_press"
            and key ~= "on_release" then
            metadata[key] = value
        end
    end

    return awful.key(
        spec.modifiers or {},
        spec.key,
        resolve_action(actions, spec.on_press, binding_name, "press"),
        resolve_action(actions, spec.on_release, binding_name, "release"),
        metadata
    )
end

function M.compile_key_specs(specs, ordered_names, actions, join)
    local keys = {}

    for _, name in ipairs(ordered_names) do
        local spec = specs[name]

        if spec then
            local key = build_key_object(name, spec, actions)

            if key then
                keys[#keys + 1] = key
            end
        end
    end

    for _, name in ipairs(sorted_extra_names(specs, ordered_names)) do
        local key = build_key_object(name, specs[name], actions)

        if key then
            keys[#keys + 1] = key
        end
    end

    return join(unpack(keys))
end

local function same_modifiers(left, right)
    if #left ~= #right then
        return false
    end

    local seen = {}

    for _, modifier in ipairs(left) do
        seen[modifier] = (seen[modifier] or 0) + 1
    end

    for _, modifier in ipairs(right) do
        if not seen[modifier] then
            return false
        end

        seen[modifier] = seen[modifier] - 1
        if seen[modifier] < 0 then
            return false
        end
    end

    return true
end

function M.has_binding(specs, modifiers, key)
    for _, spec in pairs(specs) do
        if not spec.disabled
            and spec.key == key
            and same_modifiers(spec.modifiers or {}, modifiers or {}) then
            return true
        end
    end

    return false
end

return M
