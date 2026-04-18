return {
    {
        name = "senecvpn",
        type = "shell",
        -- icon = "/absolute/path/to/vpn.svg",
        -- glyph = "",
        -- glyph_font = "Symbols Nerd Font 12",
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
        -- icon = "/absolute/path/to/browser.svg",
        -- glyph = "󰖟",
        command = "/usr/bin/vivaldi-home %s",
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
