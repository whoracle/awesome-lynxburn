local gears = require("gears")

local util = require("lxcommon.util")

local M = {}

local GITLAB_SPECIAL_KEYS = {
    type = true,
    gitlab_url = true,
    label = true,
    threshold = true,
    lifetime = true,
    admin_selector = true,
}

local VAULT_SPECIAL_KEYS = {
    type = true,
    vault_url = true,
    label = true,
    auth_path = true,
    skip_verify = true,
    env = true,
    threshold = true,
}

local function script_path(name)
    return gears.filesystem.get_configuration_dir() .. "lxsecrets/" .. name
end

local function sorted_keys(source)
    local keys = {}

    for key, _ in pairs(source or {}) do
        keys[#keys + 1] = key
    end

    table.sort(keys)
    return keys
end

local function selector_string(source, special_keys)
    local parts = {}

    for _, key in ipairs(sorted_keys(source)) do
        local value = source[key]

        if not special_keys[key] and value ~= nil and value ~= false then
            parts[#parts + 1] = tostring(key)
            parts[#parts + 1] = tostring(value)
        end
    end

    return table.concat(parts, " ")
end

local function shell_assignment(key, value)
    return tostring(key) .. "=" .. util.shell_escape(value)
end

local function wrap_vpn(command, vpn_name)
    local vpn = util.shell_escape(vpn_name)

    return table.concat({
        "(",
        "if nmcli -t -f NAME connection show --active | grep -Fx -- " .. vpn .. " >/dev/null; then",
        command .. ";",
        "else",
        "nmcli connection up " .. vpn .. " --ask >/dev/null || exit $?;",
        command .. ";",
        "rc=$?;",
        "nmcli connection down " .. vpn .. " >/dev/null || true;",
        "exit $rc;",
        "fi",
        ")",
    }, " ")
end

local function gitlab_command(secret)
    local selectors = secret.selectors or {}
    local token_selector = selector_string(secret.token_selector or selectors, GITLAB_SPECIAL_KEYS)
    local admin_selector = selector_string(secret.admin_selector or selectors.admin_selector or selectors, GITLAB_SPECIAL_KEYS)
    local store_label = selectors.label or secret.name or "GitLab Personal Access Token"

    local parts = {
        util.shell_escape(script_path("gitlab_refresh.sh")),
        "--gitlab-url", util.shell_escape(selectors.gitlab_url or ""),
        "--admin-selector", util.shell_escape(admin_selector),
        "--token-selector", util.shell_escape(token_selector),
        "--threshold-days", util.shell_escape(secret.gitlab_threshold_days or 30),
        "--new-lifetime-days", util.shell_escape(secret.gitlab_lifetime_days or 365),
        "--store-label", util.shell_escape(store_label),
    }

    return table.concat(parts, " ")
end

local function vault_command(secret)
    local selectors = secret.selectors or {}
    local env = {
        shell_assignment("VAULT_ADDR", selectors.vault_url or ""),
        shell_assignment("VAULT_AUTH_PATH", selectors.auth_path or "oidc"),
        shell_assignment("VAULT_SKIP_VERIFY", selectors.skip_verify and "true" or "false"),
        shell_assignment("KEYRING_LABEL", selectors.label or ("Vault token for " .. tostring(selectors.vault_url or ""))),
        shell_assignment("KEYRING_SERVICE", selectors.service or "vault"),
        shell_assignment("KEYRING_ACCOUNT", selectors.account or ""),
        shell_assignment("VAULT_ENV", selectors.env or secret.name or "unset"),
        shell_assignment("RENEW_BELOW_SECONDS", secret.threshold_seconds or 604800),
        shell_assignment("NOTIFY_APP_NAME", "lxsecrets"),
    }

    return table.concat(env, " ") .. " " .. util.shell_escape(script_path("vault_refresh.sh"))
end

function M.provider_group(provider)
    if provider == "gitlab" then
        return "gitlab"
    end

    if provider == "hashicorp_vault" then
        return "hashicorp_vault"
    end

    return "other"
end

function M.provider_label(provider)
    if provider == "gitlab" then
        return "GitLab"
    end

    if provider == "hashicorp_vault" then
        return "Vault"
    end

    return tostring(provider or "unknown")
end

function M.build_command(secret)
    local provider = secret.provider
    local command

    if provider == "gitlab" then
        command = gitlab_command(secret)
    elseif provider == "hashicorp_vault" then
        command = vault_command(secret)
    else
        return nil, "unsupported provider: " .. tostring(provider)
    end

    if secret.vpn and secret.vpn ~= "" then
        command = wrap_vpn(command, secret.vpn)
    end

    return command
end

return M
