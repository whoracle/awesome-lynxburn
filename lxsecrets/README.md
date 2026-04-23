# lxsecrets

`lxsecrets` is the secret/token refresh helper for this config.

It wraps the existing GitLab and Vault refresh logic in an Awesome-native
module with a compact top-level widget plus a grouped popup.

## Dependencies

External:

- common: `secret-tool`
- GitLab secrets: `curl`, `jq`, `date`, `mktemp`
- Vault secrets: `vault`, `jq`, `notify-send`
- VPN-gated secrets: `nmcli`

Internal:

- `lxcommon.popup_controller`
- `lxcommon.popup_ui`
- `lxcommon.popup_placement`
- `lxcommon.screen`
- `lxcommon.util`

## Features

- startup and interval-based refresh runs
- grouped popup by provider
- per-secret manual refresh
- global refresh-all action
- pause/resume checks
- compact healthy/suspended/attention widget state
- optional VPN-gated refresh execution per secret
- Vault cards surface an inline login action only after a refresh determines
  that interactive auth is required
- interactive Vault login keeps VPN-gated runs alive until success or timeout
- Vault login can use an explicit browser command instead of ambient desktop
  browser resolution

## Example Usage

lxbar block:

```lua
lxmodules = {
    lxbar = {
        order = { "lxsecrets", "lxnetwork", "lxmedia" },
        modules = {
            lxsecrets = {
                cycle = false,
            },
        },
    },
}
```

Module config:

```lua
lxmodules = {
    lxsecrets = {
        at_start = true,
        interval = "30m",
        top_level = "urgent",
        cycle_exclude = true,
        browser = "vivaldi-stable --profile-directory=Profile\\ 1",
        vpn_timeout = "5m",
        interactive_vpn_timeout = "15m",
        thresholds = {
            gitlab = "30d",
            hashicorp_vault = "7d",
        },
        secrets = {
            {
                name = "GitLab PAT",
                selectors = {
                    type = "gitlab",
                    gitlab_url = "https://gitlab.example.org",
                    label = "SHELL_GIT_TOKEN",
                    service = "gitlab-example",
                    account = "me@example.org",
                },
            },
            {
                name = "Vault token",
                vpn = "corp-vpn",
                selectors = {
                    type = "hashicorp_vault",
                    vault_url = "https://vault.example.org",
                    label = "Vault token for https://vault.example.org",
                    service = "vault-example",
                    account = "me@example.org",
                    auth_path = "oidc",
                    skip_verify = false,
                },
            },
        },
    },
}
```

## Configuration

Supported knobs:

- `at_start`
- `interval`
- `top_level`
- `cycle_exclude`
- `browser`
- `vpn_timeout`
- `interactive_vpn_timeout`
- `thresholds.gitlab`
- `thresholds.hashicorp_vault`
- `lifetimes.gitlab`
- `secrets`
- `secrets[].name`
- `secrets[].browser`
- `secrets[].vpn`
- `secrets[].vpn_timeout`
- `secrets[].interactive_vpn_timeout`
- `secrets[].threshold`
- `secrets[].lifetime`
- `secrets[].selectors`
- `secrets[].selectors.type`
- `secrets[].selectors.label`
- `secrets[].selectors.service`
- `secrets[].selectors.account`
- `secrets[].selectors.gitlab_url`
- `secrets[].selectors.vault_url`
- `secrets[].selectors.auth_path`
- `secrets[].selectors.skip_verify`
- `secrets[].admin_selector`
- `secrets[].token_selector`

Current provider support:

- `gitlab`
- `hashicorp_vault`

`top_level` accepts:

- `"always"`
- `"never"`
- `"urgent"`

## Theme Variables

- `lxsecrets_icon`
- `lxsecrets_icon_font`
- `lxsecrets_icon_width`
- `lxsecrets_widget_fg`
- `lxsecrets_widget_suspended_fg`
- `lxsecrets_widget_attention_fg`
- `lxsecrets_widget_hover_bg`
- `lxsecrets_widget_press_bg`
- `lxsecrets_popup_bg`
- `lxsecrets_popup_width`
- `lxsecrets_popup_placement`
- `lxsecrets_button_hover`
- `lxsecrets_selected_bg`
- `lxsecrets_meta_fg`

## Screenshots

- `[placeholder] compact widget`
- `[placeholder] grouped secrets popup`

## File Layout

- `init.lua`: module constructor and wiring
- `state.lua`: config normalization, timers, refresh queue, and runtime state
- `providers.lua`: provider-specific shell command construction
- `popup.lua`: popup rendering and selection behavior
- `theme.lua`: compact widget rendering and theme-backed state colors
- `*.sh`: existing shell refresh backends currently reused by the module

## Notes

- per-secret status is currently in-memory only and does not survive Awesome
  reloads
- provider execution still uses the bundled shell backends rather than a full
  native Lua reimplementation
- `cycle_exclude = true` is the default first-pass behavior
- automatic/background Vault refresh runs fail into attention state when login
  is required; they do not open an interactive login flow on their own
- clicking a card always means “try refresh”
- Vault rows expose an inline `login` action only after a refresh reports that
  auth is required; normal `refresh` stays non-interactive and is safe for
  periodic or retry use
- `browser` or `secrets[].browser` is exported as `BROWSER` for Vault OIDC
  login when set
