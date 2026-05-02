# AwesomeWM Declarative Session Manager — Brief

## Goal

Create an AwesomeWM Lua module that can:

1. Snapshot the current desktop state.
2. Restore/switch to named session profiles.
3. Reconcile the live desktop against a desired session:
   - existing clients are moved/resized/tagged correctly
   - missing clients are spawned
   - unrelated clients are handled by a configurable policy

This is not full application-state restore. Apps remain responsible for their own state; this only manages invocation, placement, tags, screens, and window state.

## Core Concept

Treat sessions as **desired desktop state**.

A session profile declares which clients should exist and where they should be.

Example:

```lua
return {
  name = "work",

  unmanaged_policy = "parking",
  parking_tag = "parking",

  clients = {
    {
      id = "terminal-main",
      cmd = "alacritty --class work-terminal",
      match = {
        class = "work-terminal",
      },
      screen = 1,
      tag = "dev",
      geometry = { x = 20, y = 40, width = 1200, height = 900 },
      floating = true,
    },

    {
      id = "browser",
      cmd = "vivaldi-stable --user-data-dir ~/.config/vivaldi-work",
      match = {
        class = "Vivaldi-stable",
      },
      screen = 1,
      tag = "web",
      maximized = true,
    },
  },
}
```

## Desired Behavior

When switching to a session:

1. Load the requested profile.
2. Enumerate current AwesomeWM clients.
3. For each desired client:
   - find an existing matching client
   - if found, move it to the target screen/tag and apply geometry/window state
   - if not found, spawn `cmd`
4. For spawned clients, apply placement/state from `client.connect_signal("manage", ...)`.
5. For current clients not part of the target session:
   - move to parking tag by default
   - optionally minimize, ignore, or close depending on policy

## Matching Rules

Avoid relying only on generic window class when possible.

Preferred matching data:

```lua
match = {
  class = "...",
  instance = "...",
  name = "...",
  role = "...",
}
```

The matcher should support partial matching: if only `class` is provided, match by class; if multiple fields are provided, all must match.

For terminals and duplicate apps, prefer launching with unique classes:

```bash
alacritty --class work-terminal
alacritty --class gaming-terminal
```

For browsers, prefer separate profiles/user-data dirs where possible.

## Snapshot Feature

Provide a function:

```lua
session.snapshot("current")
```

It should write a Lua profile or JSON file containing currently visible/manageable clients:

```lua
{
  class = c.class,
  instance = c.instance,
  name = c.name,
  screen = c.screen.index,
  tag = c.first_tag and c.first_tag.name or nil,
  geometry = c:geometry(),
  floating = c.floating,
  maximized = c.maximized,
  fullscreen = c.fullscreen,
  sticky = c.sticky,
}
```

Important: command reconstruction is unreliable. Snapshot output may include:

```lua
cmd = nil
```

or a placeholder comment requiring manual cleanup.

## Suggested Module Structure

```text
lxsession/
  init.lua
  matcher.lua
  snapshot.lua
  reconcile.lua
  profiles/
    work.lua
    gaming.lua
    writing.lua
```

## Public API

```lua
local lxsession = require("lxsession")

lxsession.switch("work")
lxsession.switch("gaming")
lxsession.snapshot("current")
lxsession.set_unmanaged_policy("parking")
```

## Unmanaged Client Policies

Support at least:

```lua
"ignore"      -- leave unrelated clients alone
"minimize"   -- minimize unrelated clients
"parking"    -- move unrelated clients to parking tag
"close"      -- request close
```

Default should be:

```lua
"parking"
```

Do not hard-close by default.

## Spawn/Placement Handling

When a desired client is missing:

1. Add its desired state to a pending-placement table.
2. Spawn `cmd`.
3. On `client.manage`, match new client against pending entries.
4. Apply:
   - screen
   - tag
   - geometry
   - floating
   - maximized/fullscreen/sticky
   - focus if configured

Pseudo-flow:

```lua
pending[id] = desired_client
awful.spawn(desired_client.cmd)

client.connect_signal("manage", function(c)
  local desired = matcher.find_pending_match(c, pending)
  if desired then
    reconcile.apply_client_state(c, desired)
    pending[desired.id] = nil
  end
end)
```

## Implementation Order

1. Implement profile loading.
2. Implement client matcher.
3. Implement `apply_client_state(c, desired)`.
4. Implement `switch(profile_name)`:
   - move existing matches
   - spawn missing clients
   - handle unmanaged clients
5. Implement snapshot exporter.
6. Add keybindings in `rc.lua`.
7. Optional later: `lxbar` UI picker, akin to `lxdisplay`

## Example Keybindings

```lua
awful.key({ modkey, "Shift" }, "s", function()
  session.snapshot("current")
end),

awful.key({ modkey, "Shift" }, "w", function()
  session.switch("work")
end),

awful.key({ modkey, "Shift" }, "g", function()
  session.switch("gaming")
end),
```

## Notes / Constraints

- This should be X11-focused initially.
- Exact application state is out of scope.
- Command inference is unreliable; runnable profiles may need manual editing.
- Matching duplicate clients requires deliberate unique launch commands/classes.
- Closing unmanaged clients should be opt-in or per-profile, never default.
