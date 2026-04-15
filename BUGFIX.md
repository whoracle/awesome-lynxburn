# Notebook Day-One Bugfix Plan

This file captures the current implementation plan based on day-one notebook findings.
This pass is explicitly polish-oriented: the modules are usable, but the notebook experience is rough enough that it needs cleanup before the larger rewrite at home.

## Resolved Product Decisions

These points are now considered settled for this bugfix pass.

1. Scope priority:
   - this is polish, not a blocker-only stabilization pass
   - functionality mostly exists already, but daily-use quality is not acceptable on the notebook

2. Naming:
   - no global/module rename now
   - keep current module names pinned for this pass
   - full naming and architecture cleanup belongs to the later rewrite, likely alongside the `lxcommon` work referenced in `SPEC.md`

3. Battery compact glyph policy:
   - use `1/3`, `2/3`, and `full`
   - add a separate warning glyph/state
   - warning state should cover critical/odd/missing-time scenarios where the normal coarse battery glyph is misleading

4. `lxnotify` compact state:
   - keep only a bell icon
   - use red bell for unread notifications
   - drop the numeric unread count from the compact widget to save space

5. Bluetooth connected-state color:
   - red when any device is connected

6. `lxpower` pinning semantics:
   - pinning means "do not auto-switch profile on AC/battery transitions until manually unpinned"
   - this exists specifically to handle unstable AC situations such as unreliable train power

7. Bose headset media-key issue:
   - not yet diagnosed
   - defer until a later check on Friday
   - keep out of scope for the current UI-focused bugfix pass unless evidence shows it is config-local

8. YouTube artwork issue:
   - the problem is missing video artwork/thumbnail on the notebook
   - desktop behavior is the expected reference
   - this is not a URL-display request

## Findings Grouped By Type

### Clear Bugs

- icon layouts overall are inconsistent or broken
- no visible press feedback on many clickable rows/buttons
- repeated brightness/volume presses feel laggy or uneven
- `lxnotify` popup reacts to click/right-click too broadly instead of only on intended action targets
- Wi-Fi icon is visually halved/clipped
- icon glyphs and text/numbers have uneven baseline/alignment
- battery "time to full/empty" is sometimes missing

### Likely Missing Features / Incomplete UX

- `lxnetwork` needs an explicit "disable Wi-Fi" power-saving action
- `lxpower` popup needs stronger layout and richer information density
- `lxnotify` unread state should collapse to bell-only color signaling
- `lxbluetooth` needs richer state information
- `lxpower` needs a profile pin/unpin control
- battery widget likely needs clearer coarse charge-state glyphs

### Possible External / Out-of-Scope Issue

- Bose headset `playerctl` controls may be unrelated to this config

## Constraints Observed In Current Code

- Main config intends `lx*` modules to be owned separately, but they are still local and editable here.
- Wibar composition is centralized in `themes/lynxburn2/widgets.lua`.
- Theme knobs already exist for `lxaudio`, `lxnotify`, `lxdisplay`, `lxnetwork`, `lxbluetooth`, and `lxpowerprofiles`.
- `lxpowerprofiles` already remembers preferred profiles per power source, but it does not expose any explicit "pin current profile" mode.
- `lxaudio/media.lua` only reads metadata from `playerctl`; artwork loading only supports `file://` URLs, which is now the main suspect for the desktop-vs-notebook YouTube thumbnail mismatch.
- `lxnotify/widget.lua` currently binds:
  - left click -> toggle popup
  - middle click -> toggle daemon pause
  - right click -> dismiss all
  This matches the complaint that click behavior needs tightening and clearer feedback.
- Global renames are deferred; this pass should not spend time on module naming churn when a broader rewrite is already planned.

## Prioritized Implementation Plan

### Phase 1: Stabilize Core Interaction

Goal: remove the things that make the notebook feel broken during normal use.

1. Fix compact widget geometry and clipping.
   Scope:
   - inspect each `lx*` compact widget for forced width, margins, font choice, and icon/text baseline mismatch
   - specifically fix the halved Wi-Fi icon and any clipped battery/Bluetooth glyphs
   - normalize icon box widths so glyph-only widgets align consistently in the bar
   Expected outcome:
   - no clipped icons
   - more even spacing between glyph and text widgets

2. Add clear press/hover/selection feedback everywhere interactive.
   Scope:
   - compact widgets
   - popup rows
   - media control buttons
   - notification cards and action rows
   Notes:
   - visual feedback should exist on press, not only hover
   - keyboard selection highlight should match mouse interaction styling where possible

3. Fix repeated keypress stutter for brightness and volume.
   Scope:
   - inspect how repeated XF86 key events call `lxaudio` and `lxdisplay`
   - reduce command churn and refresh thrash during bursts
   - debounce or coalesce OSD refreshes so holding the key does not create uneven UI updates
   Likely work:
   - separate "apply state change" from "full refresh"
   - throttle expensive shell queries while allowing fast visible progress

4. Tighten `lxnotify` click behavior.
   Scope:
   - left/right click should only trigger the intended action target
   - entering/focusing a card must not behave like activation
   - compact widget clicks should remain deliberate and discoverable
   Expected outcome:
   - no accidental dismiss/default-action firing

### Phase 2: Repair Information Architecture

Goal: make the widgets readable and worthwhile on a notebook-sized bar.

1. Normalize typography and iconography.
   Scope:
   - align glyphs and numeric labels vertically
   - standardize compact font sizes across `lxnotify`, network, Bluetooth, and power
   - use a common compact-width policy so widgets do not jitter as values change

2. Rework `lxpower` compact representation.
   Scope:
   - add battery charge-state glyph set using `1/3`, `2/3`, and `full`
   - reserve a warning glyph/state for missing time data or critical battery
   - make "time to empty" / "time to full" fallback states explicit instead of blank
   - improve popup layout density and hierarchy
   Notes:
   - current popup already shows source, profile, dGPU, and time, but the visual hierarchy is sparse

3. Rework `lxbluetooth` compact and popup states.
   Scope:
   - add a stronger connected-state color treatment
   - enrich popup with connection state, battery if available, and clearer device affordances
   - reduce the "barren" feel by giving the popup a more structured status section

4. Rework `lxnotify` compact representation.
   Scope:
   - replace count-based compact state with bell-only color signaling
   - red bell means unread notifications are present
   - keep idle/suspended states distinct without wasting width

### Phase 3: Fill Functional Gaps

Goal: cover the missing actions that matter on a laptop.

1. Add "Disable Wi-Fi" to `lxnetwork`.
   Scope:
   - explicit radio-off action in popup
   - clear state reflection in compact widget and popup
   - preserve separate VPN/connection indicators where sensible

2. Add `lxpower` profile pinning.
   Proposed behavior:
   - pin locks the current profile against automatic AC/battery source switching
   - unpin restores normal per-source remembered behavior
   Implementation shape:
   - explicit pinned flag in module state
   - popup action to pin/unpin
   - compact widget visual marker when pinned

3. Improve battery state modeling.
   Scope:
   - distinguish charging, discharging, full, unknown
   - handle missing kernel-exposed time values gracefully
   - avoid empty-string compact labels when the data source is absent

### Phase 4: Investigate Likely External Integration Limits

Goal: separate config bugs from upstream/tooling limits.

1. Investigate YouTube artwork visibility in `lxaudio`.
   Current likely limitation:
   - `playerctl` metadata commonly exposes title/artist/status
   - artwork support currently depends on `mpris:artUrl` resolving to a usable local `file://` path
   - notebook and desktop may differ in browser/player metadata exposure even with the same site
   Decision:
   - treat this as a thumbnail/artwork diagnosis, not as a URL-display feature request

2. Investigate Bose headset media-control path.
   Current likely possibilities:
   - headset buttons are not producing usable media key events
   - desktop session captures them before Awesome
   - `playerctl` can control players, but headset events never arrive
   Recommendation:
   - treat this as a separate diagnosis task after widget/UI bugs are fixed

## Suggested Delivery Order

If the goal is fastest notebook usability improvement, implement in this order:

1. geometry/clipping fixes
2. button press feedback
3. repeated brightness/volume smoothing
4. `lxnotify` accidental action fix
5. Wi-Fi disable action
6. `lxpower` pinning
7. `lxpower` and `lxbluetooth` information-density pass
8. compact red-count / color-state polish
9. external integration investigations

## Acceptance Criteria

The bugfix pass is done when:

- no compact widget appears clipped or visually halved on the notebook bar
- repeated brightness/volume keypresses feel smooth and predictable
- every interactive control gives immediate visible feedback
- `lxnotify` does not trigger unintended actions
- `lxnotify` compact state uses bell-only color signaling rather than a numeric unread counter
- Wi-Fi can be explicitly disabled from the network module
- power-profile switching can be pinned when AC is unstable
- battery/Bluetooth/power compact states are readable at a glance
- missing battery-time data results in a clear fallback state, not silent emptiness

## Open Assumptions

These assumptions should be confirmed before implementation starts:

- Bluetooth connected state should use a stronger color signal
- power-profile pinning should override automatic source-based switching
- Bose headset media-key handling is allowed to stay out of scope for the first bugfix pass
- desktop behavior is the reference baseline for missing YouTube artwork
