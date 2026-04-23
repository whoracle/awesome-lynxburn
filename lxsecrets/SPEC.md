# lxsecrets SPEC

## Overview

`lxsecrets` is supposed to be a helper widget/tool for rotating access tokens/secrets stored in the keyring. It is supposed to run at session startup, and in configurable intervals during the session. It checks configured secrets in the keyring, checks their validity and rotates/replaces them if their remaining age is below a configurable threshold. The results get written to the keyring again, so anything that depends on those values has fresh secrets available after a rotation.

## Instructions

Read the two pairs of .sh files in this repository and build the module from that, including dependency pre-flight checking, documentation etc. Use shared resources from e.g. lxcommon and make sure it integrates with lxbar as per SPEC and tradition.

## Planned

- a top-level widget with a key glyph
  - red if user interaction is needed
  - gray if currently suspended
  - gold if all is well
  - visibility should be configurable
    - invisible instead of gold
- a popup that lists secrets by upstream (a section for vault, a section for gitlab, with more to be determined)
  - the popup should be able to be excluded from cycling
  - should list (configureable) metadata for each secret
  - click should trigger a replacement
  - include a button to trigger an active (re)check
- a standalone invocation method that can be run on session startup once
- secret replacement failures should log to ~/.xsession-errors and via notification
- configuration of each secret should be in `config.lua`
  - keyring identifiers and neccessary other parameters like vault/gitlab URLs
  - wrap in a "vpn" block if a specific VPN connections needs to be active for the secrets in question
  - everything not wrapped in a VPN block can "jusut run"
  - VPN invocation needs to check if the given VPN is already active. If not, activate, refresh, then deactivate.
  - if VPN is already active, do nothing with the VPN
  - make VPN prereq visible on each secret via a kind of tag as in lxdisplay/lxbluetooth/lxnetwork
- some kind of "plugin system"/specified API to add new plugins reasonably easily

example `config.lua` snippet (to be refined if neccessary):

```lua
return {
    lxmodules = {
        lxbar = {
            order = {
                "secrets",
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

## To be discussed

- should we allow age to be configured globally, per token, or both (a default value per plugin and an override per secret)
- should we allow inert secrets, too: secrets that we can't actively rotate, but still want notifications for.
  - Pro: unified surface for expiring secrets
  - Con: noise, need to keep some kind of state per secret so we don't realert every few minutes

## Unplanned

- More plugins maintained by myself
  Why: Because this is what I currently use
