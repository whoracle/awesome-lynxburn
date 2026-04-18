local config_data = require("config.config_data")

---Static user-facing settings loaded from the centralized config surface.
---
---Environment-derived runtime values such as `HOME`, `EDITOR`, and derived tag
---name lists live in `config.runtime`.
return config_data.settings()
