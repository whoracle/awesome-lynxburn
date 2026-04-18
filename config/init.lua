---Convenience aggregator for the maintainable Awesome config modules.
---
---This keeps `rc.lua` readable by allowing:
---`local config = require("config")`
---and then `config.keys`, `config.programs`, `config.services`, etc.
return {
    settings = require("config.settings"),
    programs = require("config.programs"),
    config_data = require("config.config_data"),
    defaults = require("config.defaults"),
    helpers = require("config.helpers"),
    theme = require("config.theme"),
    widgets = require("config.widgets"),
    layouts = require("config.layouts"),
    osd = require("config.osd"),
    keys = require("config.keys"),
    mouse = require("config.mouse"),
    rules = require("config.rules"),
    signals = require("config.signals"),
    screens = require("config.screens"),
    services = require("config.services"),
}
