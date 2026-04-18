local config_data = require("config.config_data")

---External command definitions and runtime command configuration.
---
---When changing command-line tools, launchers, screenshot tooling, brightness
---control, or Redshift parameters, this is usually the first file to edit.
return config_data.commands()
