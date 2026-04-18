local M = {}

M.widgets = {
    order = {
        "network",
        "audio",
        "notify",
    },
    modules = {
        bluetooth = {
            enabled = false,
        },
        network = {
            enabled = true,
            -- cycle = false,
        },
        powerprofiles = {
            enabled = false,
        },
    },
}

return M
