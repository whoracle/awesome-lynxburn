return {
    {
        name = "vpntoggle",
        type = "shell",
        command = [[
            nmcli c show --active | grep senec
            if [ $? -eq 0 ]; then
                echo "VPN is up. Disabling..."
                nmcli connection down senec
            else
                echo "VPN is down. Enabling..."
                nmcli connection up senec --ask
            fi
        ]],
        env = {},
    },
    {
        name = "browser",
        type = "template",
        command = "/usr/bin/vivaldi %s",
        env = {},
    },
    -- {
    --     name = "vault",
    --     type = "template",
    --     command = "vault kv list %s",
    --     env = {
    --         VAULT_URL = "https://some.vault.com",
    --     },
    -- },
}
