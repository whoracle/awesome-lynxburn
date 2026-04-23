# lxsecrets SPEC

Planned work lives in [`../ROADMAP.md`](../ROADMAP.md).

## Scope

`lxsecrets` is the secret/token refresh helper for this config.

It is intended to:

- rotate access tokens or secrets stored in the keyring
- run on session startup and at configurable intervals
- check configured secrets for age/validity and refresh them before expiry
- write fresh values back into the keyring so downstream consumers can use
  updated secrets
- integrate with `lxbar` and shared popup behavior where that makes sense

example `config.lua` snippet (to be refined if neccessary):

```lua
return {
    lxmodules = {
        lxbar = {
            order = {
                "lxsecrets",
            },
        },
        lxsecrets = {
            at_start = true,
            interval = "30m",
            top_level = "always"  -- "always", "never", "urgent"
            cycle_excldue = true,
            thresholds = {  -- see To Be Discussed below
                gitlab = "30d",
                vault = "7d",
            },
            secrets = {
                {
                    name = "Vault Secret 1 behind VPN 1",
                    vpn = "vpn_selector_1",
                    selectors = {
                        type = "hashicorp_vault",
                        label = "SOME_LABEL1"
                        account = "me@example.org",
                        service = "vault-homelab",
                        vault_url = "https://vault.home.lab",
                    },
                },
                {
                    name = "Vault Secret 2 behind VPN 1",
                    vpn = "vpn_selector_1",
                    selectors = {
                        type = "hashicorp_vault",
                        label = "SOME_LABEL2"
                        account = "me@example.org",
                        service = "vault-puiblic",
                        vault_url = "https://vault.public.tld",
                    },
                },
                {
                    name = "Vault Secret 3 with no VPN",
                    threshold = "9d", -- see To Be Discussed below
                    selectors = {
                        type = "hashicorp_vault",
                        label = "SOME_LABEL3"
                        account = "me@example.org",
                        service = "vault-three",
                        vault_url = "https://vault.some.where",
                    },
                },
                {
                    name = "Gitlab Secret 1 with VPN 2",
                    vpn = "vpn_selector_2",
                    selectors = {
                        type = "gitlab",
                        label = "SOME_LABEL4"
                        account = "me@example.org",
                        service = "gitlab-vpn2",
                        gitlab_url = "https://gitlab.example.org",
                    },
                },
            },
        },
}
```

## Unplanned

- More plugins maintained by myself
  Why: Because this is what I currently use
