local M = {}

---Normalize legacy screen profile shorthand into table form.
---@param profile table|any
---@return table|any
function M.normalize_profile(profile)
    if type(profile) ~= "table" then
        return profile
    end

    if profile.layout == nil and type(profile[1]) == "string" then
        profile.layout = profile[1]
    end

    return profile
end

---Return a normalized copy of the configured screen profiles table.
---@param screen_profiles table
---@return table
function M.normalize_profiles(screen_profiles)
    for screen_name, profile in pairs(screen_profiles) do
        screen_profiles[screen_name] = M.normalize_profile(profile)
    end

    return screen_profiles
end

---Return the configured profile table for one physical screen index.
---@param settings table
---@param screen_profiles table
---@param screen_index number
---@return table|nil
function M.profile_for_screen(settings, screen_profiles, screen_index)
    local monitors = settings.monitors or {}

    for screen_name, monitor_index in pairs(monitors) do
        if screen_index == monitor_index then
            return screen_profiles[screen_name]
        end
    end

    return nil
end

return M
