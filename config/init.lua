---Convenience aggregator for the maintainable Awesome config modules.
---
---This keeps `rc.lua` readable by allowing:
---`local config = require("config.init")`
---and then `config.keys`, `config.lxmodules`, `config.services`, etc.
return {
    config_data = require("config.config_data"),
    defaults = require("config.defaults"),
    helpers = require("config.helpers"),
    input = require("config.input"),
    platform = require("config.platform"),
    runtime = require("config.runtime"),
    theme = require("config.theme"),
    tags = require("config.tags"),
    lxmodules = require("config.lxmodules"),
    layouts = require("config.layouts"),
    osd = require("config.osd"),
    keys = require("config.keys"),
    mouse = require("config.mouse"),
    preflight = require("config.preflight"),
    rules = require("config.rules"),
    signals = require("config.signals"),
    screens = require("config.screens"),
    services = require("config.services"),
}
