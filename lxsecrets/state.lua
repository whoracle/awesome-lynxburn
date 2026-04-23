local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")

local providers = require("lxsecrets.providers")
local util = require("lxcommon.util")

local M = {}

local DURATION_UNITS = {
    s = 1,
    m = 60,
    h = 3600,
    d = 86400,
    w = 604800,
}

local PROVIDER_ALIASES = {
    vault = "hashicorp_vault",
    hashicorp_vault = "hashicorp_vault",
    gitlab = "gitlab",
}

local function copy_table(source)
    local out = {}

    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            out[key] = copy_table(value)
        else
            out[key] = value
        end
    end

    return out
end

local function parse_duration_seconds(value)
    if type(value) == "number" then
        return math.max(0, math.floor(value))
    end

    local amount, unit = tostring(value or ""):match("^(%d+)([smhdw])$")
    if not amount or not unit then
        return nil
    end

    return tonumber(amount) * (DURATION_UNITS[unit] or 0)
end

local function duration_or_default(value, fallback)
    return parse_duration_seconds(value) or fallback
end

local function duration_days(value, fallback)
    local seconds = parse_duration_seconds(value)
    if not seconds or seconds < 1 then
        seconds = parse_duration_seconds(fallback) or 86400
    end

    return math.max(1, math.floor((seconds + 86399) / 86400))
end

local function format_timestamp(timestamp)
    if not timestamp then
        return "never"
    end

    return os.date("%Y-%m-%d %H:%M", timestamp)
end

local function last_nonempty_line(output)
    local last_line = nil

    for _, line in ipairs(util.split_lines(output)) do
        local trimmed = util.trim(line)
        if trimmed and trimmed ~= "" then
            last_line = trimmed
        end
    end

    return last_line
end

local function threshold_text(seconds)
    if not seconds then
        return "-"
    end

    if seconds % 86400 == 0 then
        return tostring(seconds / 86400) .. "d"
    end

    if seconds % 3600 == 0 then
        return tostring(seconds / 3600) .. "h"
    end

    if seconds % 60 == 0 then
        return tostring(seconds / 60) .. "m"
    end

    return tostring(seconds) .. "s"
end

local function top_level_mode(value)
    value = tostring(value or "always")
    if value == "never" or value == "urgent" then
        return value
    end

    return "always"
end

local function normalize_provider(value)
    return PROVIDER_ALIASES[tostring(value or "")] or tostring(value or "")
end

local function secret_status_label(secret)
    if secret.running then
        return "running"
    end

    if secret.status == "ok" then
        return "ok"
    end

    if secret.status == "attention" then
        return "attention"
    end

    if secret.status == "error" then
        return "error"
    end

    return "idle"
end

function M.extend(instance_methods)
    function instance_methods:_normalize_secret(secret, index)
        local selectors = copy_table(secret.selectors or {})
        local provider = normalize_provider(selectors.type or secret.type)
        local threshold_value = secret.threshold or (self.opts.thresholds or {})[provider] or (self.opts.thresholds or {}).vault
        local threshold_seconds = parse_duration_seconds(threshold_value) or 604800
        local lifetime_days = duration_days(secret.lifetime or (self.opts.lifetimes or {})[provider] or "365d", "365d")
        local vpn_timeout_seconds = duration_or_default(
            secret.vpn_timeout or self.opts.vpn_timeout,
            300
        )
        local interactive_vpn_timeout_seconds = duration_or_default(
            secret.interactive_vpn_timeout or self.opts.interactive_vpn_timeout,
            900
        )

        return {
            index = index,
            id = secret.id or ("secret-" .. tostring(index)),
            name = secret.name or ("Secret " .. tostring(index)),
            provider = provider,
            provider_group = providers.provider_group(provider),
            provider_label = providers.provider_label(provider),
            selectors = selectors,
            admin_selector = copy_table(secret.admin_selector),
            token_selector = copy_table(secret.token_selector),
            vpn = secret.vpn,
            vpn_timeout_seconds = vpn_timeout_seconds,
            interactive_vpn_timeout_seconds = interactive_vpn_timeout_seconds,
            threshold_seconds = threshold_seconds,
            threshold_label = threshold_text(threshold_seconds),
            gitlab_threshold_days = math.max(1, math.floor((threshold_seconds + 86399) / 86400)),
            gitlab_lifetime_days = lifetime_days,
            running = false,
            status = "idle",
            auth_required = false,
            last_message = "never checked",
            last_checked_at = nil,
            needs_attention = false,
        }
    end

    function instance_methods:_normalize_secrets(secret_specs)
        local secrets = {}

        for index, secret in ipairs(secret_specs or {}) do
            secrets[#secrets + 1] = self:_normalize_secret(secret, index)
        end

        table.sort(secrets, function(a, b)
            if a.provider_group ~= b.provider_group then
                return a.provider_group < b.provider_group
            end

            return a.name < b.name
        end)

        for index, secret in ipairs(secrets) do
            secret.index = index
        end

        return secrets
    end

    function instance_methods:has_attention()
        for _, secret in ipairs(self.state.secrets or {}) do
            if secret.needs_attention then
                return true
            end
        end

        return false
    end

    function instance_methods:toggle_suspended()
        self.state.suspended = not self.state.suspended
        self:_apply_widget_state()
        self:_refresh_popup()
    end

    function instance_methods:_update_ui_state()
        self:_apply_widget_state()
        self:_refresh_popup()
    end

    function instance_methods:_notify_refresh_failure(secret, message)
        naughty.notify({
            app_name = "lxsecrets",
            title = "Secret refresh failed",
            text = string.format("%s: %s", secret.name, message),
            urgency = "critical",
        })
    end

    function instance_methods:_refresh_secret_async(secret, opts, callback)
        opts = opts or {}
        local command, build_error = providers.build_command(secret, opts)
        if not command then
            secret.running = false
            secret.status = "error"
            secret.needs_attention = true
            secret.last_checked_at = os.time()
            secret.last_message = build_error
            self:_update_ui_state()
            self:_notify_refresh_failure(secret, build_error)
            callback(false)
            return
        end

        secret.running = true
        secret.status = "running"
        secret.last_message = "refreshing"
        self:_update_ui_state()

        awful.spawn.easy_async_with_shell(command, function(stdout, stderr, _, exit_code)
            local output = util.trim((stderr ~= "" and stderr) or stdout or "")
            local message = last_nonempty_line(output) or (exit_code == 0 and "refresh succeeded" or "refresh failed")

            secret.running = false
            secret.last_checked_at = os.time()
            secret.last_message = message

            if exit_code == 0 then
                secret.status = "ok"
                secret.auth_required = false
                secret.needs_attention = false
            elseif exit_code == 10 or exit_code == 11 then
                secret.status = "attention"
                secret.auth_required = (secret.provider == "hashicorp_vault" and exit_code == 10)
                secret.needs_attention = true
                self:_notify_refresh_failure(secret, message)
            else
                secret.status = "error"
                secret.auth_required = false
                secret.needs_attention = true
                self:_notify_refresh_failure(secret, message)
            end

            self:_update_ui_state()
            callback(exit_code == 0)
        end)
    end

    function instance_methods:_run_secret_queue(indices, opts)
        opts = opts or {}
        if self._refreshing then
            return
        end

        self._refreshing = true
        local position = 1

        local function finish()
            self._refreshing = false
            self:_update_ui_state()
        end

        local function step()
            local index = indices[position]
            if not index then
                finish()
                return
            end

            position = position + 1
            local secret = self.state.secrets[index]
            if not secret then
                step()
                return
            end

            self:_refresh_secret_async(secret, opts, function()
                step()
            end)
        end

        step()
    end

    function instance_methods:refresh_secret(index, opts)
        if self.state.suspended then
            return
        end

        self:_run_secret_queue({ index }, opts)
    end

    function instance_methods:login_secret(index)
        local secret = (self.state.secrets or {})[index]
        if not secret then
            return
        end

        self:refresh_secret(index, {
            interactive_login = true,
            vpn_timeout_seconds = secret.interactive_vpn_timeout_seconds,
        })
    end

    function instance_methods:refresh_all(opts)
        if self.state.suspended then
            return
        end

        local indices = {}

        for index, _ in ipairs(self.state.secrets or {}) do
            indices[#indices + 1] = index
        end

        self:_run_secret_queue(indices, opts)
    end

    function instance_methods:provider_groups()
        local groups = {}
        local order = {}

        for _, secret in ipairs(self.state.secrets or {}) do
            if not groups[secret.provider_group] then
                groups[secret.provider_group] = {}
                order[#order + 1] = secret.provider_group
            end

            groups[secret.provider_group][#groups[secret.provider_group] + 1] = secret
        end

        return groups, order
    end

    function instance_methods:secret_metadata_lines(secret)
        local selectors = secret.selectors or {}
        local lines = {}

        if secret.provider == "gitlab" and selectors.gitlab_url then
            lines[#lines + 1] = selectors.gitlab_url
        elseif secret.provider == "hashicorp_vault" and selectors.vault_url then
            lines[#lines + 1] = selectors.vault_url
        end

        local selector_bits = {}
        if selectors.service then
            selector_bits[#selector_bits + 1] = selectors.service
        end
        if selectors.account then
            selector_bits[#selector_bits + 1] = selectors.account
        end
        if #selector_bits > 0 then
            lines[#lines + 1] = table.concat(selector_bits, " • ")
        end

        local tags = {
            "[" .. secret_status_label(secret) .. "]",
            "[threshold " .. secret.threshold_label .. "]",
            "[checked " .. format_timestamp(secret.last_checked_at) .. "]",
        }
        if secret.vpn and secret.vpn ~= "" then
            tags[#tags + 1] = "[vpn " .. tostring(secret.vpn) .. "]"
        end
        lines[#lines + 1] = table.concat(tags, " ")

        lines[#lines + 1] = secret.last_message or ""
        return lines
    end

    function instance_methods:popup_summary()
        local count = #(self.state.secrets or {})
        local attention = 0

        for _, secret in ipairs(self.state.secrets or {}) do
            if secret.needs_attention then
                attention = attention + 1
            end
        end

        if self.state.suspended then
            return "Checks are paused"
        end

        if self._refreshing then
            return string.format("Refreshing %d secret(s)", count)
        end

        if attention > 0 then
            return string.format("%d of %d secret(s) need attention", attention, count)
        end

        return string.format("%d secret(s) healthy", count)
    end

    function instance_methods:_start_timer()
        local interval = parse_duration_seconds(self.opts.interval)
        if not interval or interval < 1 then
            return
        end

        self._timer = gears.timer({
            timeout = interval,
            autostart = true,
            call_now = false,
            callback = function()
                self:refresh_all()
            end,
        })
    end
end

return M
