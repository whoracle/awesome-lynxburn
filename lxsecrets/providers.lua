local awful = require("awful")
local config_data = require("config.config_data")
local json = require("lain.util").dkjson

local util = require("lxcommon.util")

local M = {}

local DEFAULT_VPN_TIMEOUT_SECONDS = 300

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

local function sorted_keys(source)
    local keys = {}

    for key, _ in pairs(source or {}) do
        keys[#keys + 1] = key
    end

    table.sort(keys)
    return keys
end

local function selector_pairs(source, special_keys)
    local pairs_out = {}

    for _, key in ipairs(sorted_keys(source)) do
        local value = source[key]

        if not special_keys[key] and value ~= nil and value ~= false then
            pairs_out[#pairs_out + 1] = tostring(key)
            pairs_out[#pairs_out + 1] = tostring(value)
        end
    end

    return pairs_out
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

local function append_all(target, values)
    for _, value in ipairs(values or {}) do
        target[#target + 1] = value
    end
end

local function run_process(args, callback)
    awful.spawn.easy_async(args, function(stdout, stderr, _, exit_code)
        callback(stdout or "", stderr or "", exit_code or 1)
    end)
end

local function run_env_process(env_assignments, args, timeout_seconds, callback)
    local command = {}

    if timeout_seconds and tonumber(timeout_seconds) and tonumber(timeout_seconds) > 0 then
        command[#command + 1] = "timeout"
        command[#command + 1] = "--foreground"
        command[#command + 1] = tostring(math.floor(tonumber(timeout_seconds)))
    end

    if env_assignments and #env_assignments > 0 then
        command[#command + 1] = "env"
        append_all(command, env_assignments)
    end

    append_all(command, args)
    run_process(command, callback)
end

local function decode_json(raw)
    if not raw or raw == "" then
        return nil, "empty JSON output"
    end

    local decoded, _, err = json.decode(raw, 1, nil)
    if err then
        return nil, err
    end

    return decoded
end

local function parse_http_output(raw)
    local body, code = tostring(raw or ""):match("^(.*)\n(%d%d%d)\n?$")
    if not code then
        return nil, nil
    end

    return body, tonumber(code)
end

local function parse_ymd_epoch(value)
    local year, month, day = tostring(value or ""):match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    if not year then
        return nil
    end

    return os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = 0,
        min = 0,
        sec = 0,
    })
end

local function format_expiry(timestamp)
    if not timestamp then
        return nil
    end

    return os.date("%Y-%m-%d %H:%M", timestamp)
end

local function iso_to_local_display(value)
    local year, month, day, hour, min, sec = tostring(value or ""):match(
        "^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)"
    )
    if not year then
        return tostring(value or "")
    end

    local timestamp = os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec),
    })

    return format_expiry(timestamp) or tostring(value or "")
end

local function parse_display_epoch(value)
    local year, month, day, hour, min = tostring(value or ""):match(
        "^(%d%d%d%d)%-(%d%d)%-(%d%d) ?(%d%d):?(%d%d)$"
    )
    if year then
        return os.time({
            year = tonumber(year),
            month = tonumber(month),
            day = tonumber(day),
            hour = tonumber(hour),
            min = tonumber(min),
            sec = 0,
        })
    end

    local y2, m2, d2 = tostring(value or ""):match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    if y2 then
        return os.time({
            year = tonumber(y2),
            month = tonumber(m2),
            day = tonumber(d2),
            hour = 0,
            min = 0,
            sec = 0,
        })
    end

    return nil
end

local function hold_path(vpn_name)
    local safe = tostring(vpn_name or ""):gsub("[^%w_.-]", "_")
    return "/tmp/lxsecrets-vpn-" .. safe .. ".hold"
end

local function hold_exists(vpn_name)
    local file = io.open(hold_path(vpn_name), "r")
    if file then
        file:close()
        return true
    end

    return false
end

local function write_hold(vpn_name)
    local file = io.open(hold_path(vpn_name), "w")
    if file then
        file:write("1\n")
        file:close()
    end
end

local function clear_hold(vpn_name)
    os.remove(hold_path(vpn_name))
end

local function vpn_is_active(vpn_name, callback)
    run_process({ "nmcli", "-t", "-f", "NAME", "connection", "show", "--active" }, function(stdout)
        for _, line in ipairs(util.split_lines(stdout)) do
            if util.trim(line) == vpn_name then
                callback(true)
                return
            end
        end

        callback(false)
    end)
end

local function ensure_vpn(secret, callback)
    if not secret.vpn or secret.vpn == "" then
        callback(true)
        return
    end

    vpn_is_active(secret.vpn, function(active)
        if active then
            secret._vpn_managed = hold_exists(secret.vpn)
            callback(true)
            return
        end

        run_process({ "nmcli", "connection", "up", secret.vpn }, function(stdout, stderr, exit_code)
            if exit_code == 0 then
                secret._vpn_managed = true
                callback(true)
                return
            end

            callback(false, last_nonempty_line(stderr) or last_nonempty_line(stdout)
                or ("failed to activate vpn " .. tostring(secret.vpn)))
        end)
    end)
end

local function release_vpn(secret, keep_open, callback)
    callback = callback or function() end

    if not secret.vpn or secret.vpn == "" then
        callback()
        return
    end

    if keep_open then
        if secret._vpn_managed then
            write_hold(secret.vpn)
        end
        callback()
        return
    end

    clear_hold(secret.vpn)

    if not secret._vpn_managed then
        callback()
        return
    end

    run_process({ "nmcli", "connection", "down", secret.vpn }, function()
        secret._vpn_managed = false
        callback()
    end)
end

local function secret_lookup(selector_pairs_list, callback)
    local args = { "secret-tool", "lookup" }
    append_all(args, selector_pairs_list)

    run_process(args, function(stdout, stderr, exit_code)
        if exit_code == 0 then
            callback(util.trim(stdout or ""))
            return
        end

        callback(nil, last_nonempty_line(stderr) or last_nonempty_line(stdout))
    end)
end

local function secret_search_metadata(selector_pairs_list, callback)
    local args = { "secret-tool", "search", "--all" }
    append_all(args, selector_pairs_list)

    run_process(args, function(stdout, _, exit_code)
        if exit_code ~= 0 then
            callback({})
            return
        end

        local metadata = {}

        for _, line in ipairs(util.split_lines(stdout)) do
            local value = line:match("^%s*attribute%.expiry_date%s*=%s*(.+)%s*$")
                or line:match("^%s*expiry_date%s*=%s*(.+)%s*$")
                or line:match("^%s*attribute expiry_date%s*=%s*(.+)%s*$")
            if value then
                metadata.expiry_date = value:gsub("^['\"]", ""):gsub("['\"]$", "")
                break
            end
        end

        callback(metadata)
    end)
end

local function secret_clear(selector_pairs_list, callback)
    local args = { "secret-tool", "clear" }
    append_all(args, selector_pairs_list)

    run_process(args, function(_, _, _)
        callback(true)
    end)
end

local function secret_store(label, selector_pairs_list, extra_pairs, secret_value, callback)
    local args = {
        "env",
        "LXSECRET_VALUE=" .. tostring(secret_value or ""),
        "sh",
        "-lc",
        'label=$1; shift; printf %s "$LXSECRET_VALUE" | secret-tool store --label="$label" "$@"',
        "sh",
        tostring(label or "Secret"),
    }

    append_all(args, selector_pairs_list)
    append_all(args, extra_pairs)

    run_process(args, function(stdout, stderr, exit_code)
        if exit_code == 0 then
            callback(true)
            return
        end

        callback(false, last_nonempty_line(stderr) or last_nonempty_line(stdout) or "failed to store secret")
    end)
end

local function curl_json(method, token, url, body, callback)
    local args = {
        "curl",
        "-sS",
        "-X", method,
        "-H", "PRIVATE-TOKEN: " .. tostring(token),
        "-H", "Accept: application/json",
    }

    if body then
        args[#args + 1] = "-H"
        args[#args + 1] = "Content-Type: application/json"
        args[#args + 1] = "--data-binary"
        args[#args + 1] = body
    end

    args[#args + 1] = "-w"
    args[#args + 1] = "\n%{http_code}"
    args[#args + 1] = url

    run_process(args, function(stdout, stderr, exit_code)
        if exit_code ~= 0 then
            callback(nil, nil, last_nonempty_line(stderr) or "curl request failed")
            return
        end

        local response_body, code = parse_http_output(stdout)
        if not code then
            callback(nil, nil, "failed to parse HTTP response")
            return
        end

        callback(code, response_body or "", nil)
    end)
end

local function keyring_label(secret)
    local selectors = secret.selectors or {}
    return selectors.label or ("Vault token for " .. tostring(selectors.vault_url or ""))
end

local function keyring_service(secret)
    local selectors = secret.selectors or {}
    return selectors.service or "vault"
end

local function keyring_account(secret)
    local selectors = secret.selectors or {}
    return selectors.account or "me@example.org"
end

local function keyring_selector(secret)
    return {
        "service", keyring_service(secret),
        "account", keyring_account(secret),
    }
end

local function update_secret_expiry(secret, display_value, expired)
    secret.expires_at_display = display_value or "unknown"
    secret.expires_at_sort = parse_display_epoch(display_value)
    secret.expired = expired and true or false
end

local function sync_keyring_expiry(secret, token, callback)
    local display_value = secret.expires_at_display
    callback = callback or function() end

    if not display_value or display_value == "unknown" or display_value == "expired" then
        callback(true)
        return
    end

    secret_store(
        keyring_label(secret),
        keyring_selector(secret),
        { "expiry_date", tostring(display_value) },
        token,
        function(ok)
            callback(ok)
        end
    )
end

local function vault_env(secret, token, browser_override)
    local selectors = secret.selectors or {}
    local browser = browser_override or secret.browser_command or config_data.commands().browser
    local env = {
        "VAULT_ADDR=" .. tostring(selectors.vault_url or ""),
        "VAULT_SKIP_VERIFY=" .. (selectors.skip_verify and "true" or "false"),
    }

    if token and token ~= "" then
        env[#env + 1] = "VAULT_TOKEN=" .. token
    end

    if browser and browser ~= "" then
        env[#env + 1] = "BROWSER=" .. browser
    end

    return env
end

local function vault_run(secret, token, args, timeout_seconds, browser_override, callback)
    run_env_process(vault_env(secret, token, browser_override), args, timeout_seconds, callback)
end

local function gitlab_refresh(secret, callback)
    local selectors = secret.selectors or {}
    local admin_selector = selector_pairs(secret.admin_selector or selectors.admin_selector or selectors, GITLAB_SPECIAL_KEYS)
    local token_selector = selector_pairs(secret.token_selector or selectors, GITLAB_SPECIAL_KEYS)
    local store_label = selectors.label or secret.name or "GitLab Personal Access Token"
    local api_base = tostring(selectors.gitlab_url or ""):gsub("/+$", "") .. "/api/v4"

    secret_lookup(admin_selector, function(admin_pat)
        if not admin_pat or admin_pat == "" then
            callback("error", "admin PAT not found in keyring")
            return
        end

        secret_lookup(token_selector, function(managed_pat)
            if not managed_pat or managed_pat == "" then
                callback("error", "managed PAT not found in keyring")
                return
            end

            curl_json("GET", managed_pat, api_base .. "/personal_access_tokens/self", nil, function(code, body, err)
                if err then
                    callback("error", err)
                    return
                end

                if code == 401 then
                    callback("error", "managed PAT is invalid, expired, or revoked")
                    return
                end

                if code ~= 200 then
                    callback("error", "unexpected HTTP " .. tostring(code) .. " from self info endpoint")
                    return
                end

                local info, decode_err = decode_json(body)
                if not info then
                    callback("error", "failed to parse GitLab PAT metadata: " .. tostring(decode_err))
                    return
                end

                local token_id = info.id
                local user_id = info.user_id
                local expires_at = info.expires_at
                local scopes = info.scopes or {}
                local name = info.name or secret.name or "Managed token"
                local description = info.description
                local expiry_epoch = parse_ymd_epoch(expires_at)

                if not token_id or not user_id or not expires_at or not expiry_epoch then
                    callback("error", "managed PAT metadata is incomplete")
                    return
                end

                local seconds_left = expiry_epoch - os.time()
                local days_left = math.floor(seconds_left / 86400)
                update_secret_expiry(secret, expires_at, seconds_left <= 0)

                if seconds_left <= 0 then
                    callback("error", "managed PAT is already expired")
                    return
                end

                if days_left > (secret.gitlab_threshold_days or 30) then
                    sync_keyring_expiry(secret, managed_pat, function()
                        callback("ok", string.format("token healthy; ~%dd left", days_left))
                    end)
                    return
                end

                local payload = json.encode({
                    name = name,
                    description = description ~= "" and description or nil,
                    expires_at = os.date("!%Y-%m-%d", os.time() + ((secret.gitlab_lifetime_days or 365) * 86400)),
                    scopes = scopes,
                })

                curl_json("POST", admin_pat, api_base .. "/users/" .. tostring(user_id) .. "/personal_access_tokens", payload, function(create_code, create_body, create_err)
                    if create_err then
                        callback("error", create_err)
                        return
                    end

                    if create_code ~= 200 and create_code ~= 201 then
                        callback("error", "failed to create successor PAT: HTTP " .. tostring(create_code))
                        return
                    end

                    local created, create_decode_err = decode_json(create_body)
                    if not created then
                        callback("error", "failed to parse successor PAT response: " .. tostring(create_decode_err))
                        return
                    end

                    local new_pat = created.token
                    local new_id = created.id
                    local new_expires_at = created.expires_at

                    if not new_pat or new_pat == "" or not new_expires_at or new_expires_at == "" then
                        callback("error", "GitLab did not return the new PAT value")
                        return
                    end

                    curl_json("GET", new_pat, api_base .. "/personal_access_tokens/self", nil, function(verify_code, _, verify_err)
                        if verify_err then
                            callback("error", verify_err)
                            return
                        end

                        if verify_code ~= 200 then
                            callback("error", "successor PAT verification failed: HTTP " .. tostring(verify_code))
                            return
                        end

                        update_secret_expiry(secret, new_expires_at, false)

                        secret_clear(token_selector, function()
                            secret_store(store_label, token_selector, { "expiry_date", tostring(new_expires_at) }, new_pat, function(stored, store_err)
                                if not stored then
                                    callback("error", store_err)
                                    return
                                end

                                curl_json("DELETE", admin_pat, api_base .. "/personal_access_tokens/" .. tostring(token_id), nil, function(delete_code, _, delete_err)
                                    if delete_err then
                                        callback("error", "new PAT stored, but failed to revoke old PAT id=" .. tostring(token_id))
                                        return
                                    end

                                    if delete_code ~= 200 and delete_code ~= 204 then
                                        callback("error", "new PAT stored, but failed to revoke old PAT id=" .. tostring(token_id) .. " (HTTP " .. tostring(delete_code) .. ")")
                                        return
                                    end

                                    callback("ok", "replaced PAT id=" .. tostring(token_id) .. " with new id=" .. tostring(new_id) .. " expiring " .. tostring(new_expires_at))
                                end)
                            end)
                        end)
                    end)
                end)
            end)
        end)
    end)
end

local function vault_login(secret, opts, callback)
    local selectors = secret.selectors or {}
    local args = {
        "vault",
        "login",
        "-method=oidc",
        "-path=" .. tostring(selectors.auth_path or "oidc"),
        "-token-only",
    }

    vault_run(
        secret,
        nil,
        args,
        (opts and opts.vpn_timeout_seconds) or secret.interactive_vpn_timeout_seconds or DEFAULT_VPN_TIMEOUT_SECONDS,
        (opts and opts.browser_command) or secret.browser_command,
        function(stdout, stderr, exit_code)
            if exit_code ~= 0 then
                callback("error", last_nonempty_line(stderr) or "Vault login failed")
                return
            end

            local token = util.trim(stdout or "")
            if not token or token == "" then
                callback("error", "OIDC login returned empty token")
                return
            end

            local selector_pairs_list = keyring_selector(secret)

            secret_store(keyring_label(secret), selector_pairs_list, {}, token, function(stored, store_err)
                if not stored then
                    callback("error", store_err)
                    return
                end

                vault_run(secret, token, { "vault", "token", "lookup", "-format=json" }, secret.vpn_timeout_seconds, nil, function(lookup_stdout, _, lookup_exit_code)
                    if lookup_exit_code == 0 then
                        local lookup = decode_json(lookup_stdout)
                        local data = lookup and lookup.data or {}
                        local ttl = tonumber(data.ttl) or 0
                        local expire_time = data.expire_time

                        if expire_time and expire_time ~= "" and expire_time ~= "0001-01-01T00:00:00Z" then
                            update_secret_expiry(secret, iso_to_local_display(expire_time), false)
                        elseif ttl > 0 then
                            update_secret_expiry(secret, format_expiry(os.time() + ttl), false)
                        end

                        sync_keyring_expiry(secret, token, function() end)
                    end

                    callback("ok", "login succeeded")
                end)
            end)
        end
    )
end

local function vault_refresh(secret, opts, callback)
    local selector_pairs_list = keyring_selector(secret)

    secret_lookup(selector_pairs_list, function(token)
        if not token or token == "" then
            update_secret_expiry(secret, "unknown", false)
            if opts and opts.interactive_login then
                vault_login(secret, opts, callback)
            else
                callback("auth_required", "vault login required for " .. tostring((secret.selectors or {}).vault_url or "vault"))
            end
            return
        end

        secret_search_metadata(selector_pairs_list, function(metadata)
        if metadata.expiry_date and metadata.expiry_date ~= "" then
            update_secret_expiry(secret, metadata.expiry_date, false)
        else
            update_secret_expiry(secret, "unknown", false)
        end

        vault_run(secret, token, { "vault", "token", "lookup", "-format=json" }, secret.vpn_timeout_seconds, nil, function(stdout, _, exit_code)
            if exit_code ~= 0 then
                update_secret_expiry(secret, "expired", true)
                secret_clear(selector_pairs_list, function()
                    if opts and opts.interactive_login then
                        vault_login(secret, opts, callback)
                    else
                        callback("auth_required", "vault login required for " .. tostring((secret.selectors or {}).vault_url or "vault"))
                    end
                end)
                return
            end

            local lookup, err = decode_json(stdout)
            if not lookup then
                callback("error", "failed to parse Vault token metadata: " .. tostring(err))
                return
            end

            local data = lookup.data or {}
            local ttl = tonumber(data.ttl) or 0
            local renewable = data.renewable == true
            local expire_time = data.expire_time

            if expire_time and expire_time ~= "" and expire_time ~= "0001-01-01T00:00:00Z" then
                update_secret_expiry(secret, iso_to_local_display(expire_time), false)
            elseif ttl > 0 then
                update_secret_expiry(secret, format_expiry(os.time() + ttl), false)
            else
                update_secret_expiry(secret, "unknown", ttl <= 0)
            end

            if ttl > (secret.threshold_seconds or 604800) then
                sync_keyring_expiry(secret, token, function()
                    callback("ok", "token healthy; ttl=" .. tostring(ttl) .. "s")
                end)
                return
            end

            if renewable then
                vault_run(secret, token, { "vault", "token", "renew", "-format=json" }, secret.vpn_timeout_seconds, nil, function(renew_stdout, renew_stderr, renew_exit_code)
                    if renew_exit_code == 0 then
                        local renewed, renew_err = decode_json(renew_stdout)
                        if renewed then
                            local new_ttl = tonumber(((renewed.auth or {}).lease_duration) or renewed.lease_duration) or 0
                            update_secret_expiry(secret, format_expiry(os.time() + new_ttl), new_ttl <= 0)
                            sync_keyring_expiry(secret, token, function()
                                callback("ok", "renewal succeeded; new ttl=" .. tostring(new_ttl) .. "s")
                            end)
                            return
                        end

                        callback("error", "failed to parse Vault renewal response: " .. tostring(renew_err))
                        return
                    end

                    if opts and opts.interactive_login then
                        vault_login(secret, opts, callback)
                    else
                        callback("auth_required", last_nonempty_line(renew_stderr) or "vault login required for " .. tostring((secret.selectors or {}).vault_url or "vault"))
                    end
                end)
                return
            end

            if opts and opts.interactive_login then
                vault_login(secret, opts, callback)
            else
                callback("auth_required", "vault login required for " .. tostring((secret.selectors or {}).vault_url or "vault"))
            end
        end)
        end)
    end)
end

local function run_without_vpn(secret, opts, callback)
    if secret.provider == "gitlab" then
        gitlab_refresh(secret, callback)
    elseif secret.provider == "hashicorp_vault" then
        vault_refresh(secret, opts, callback)
    else
        callback("error", "unsupported provider: " .. tostring(secret.provider))
    end
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

function M.refresh(secret, opts, callback)
    opts = opts or {}

    ensure_vpn(secret, function(ok, vpn_message)
        if not ok then
            callback("error", vpn_message or ("failed to activate vpn " .. tostring(secret.vpn)))
            return
        end

        run_without_vpn(secret, opts, function(kind, message)
            release_vpn(secret, kind == "auth_required", function()
                callback(kind, message)
            end)
        end)
    end)
end

return M
