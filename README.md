# 
```textCoACombat — action camera for Ascension / WoW 3.3.5a

Version 0.4.2. Persistent mouselook, an RPG camera, selectable centre reticles,
combat mouse bindings, and an interact key for Ascension's 3.3.5a client.

## Compatibility

CoACombat is built for the Ascension 3.3.5a client and its custom
`SetMouselookOverrideBinding` and action-camera APIs. It has no server component
and does not modify game executables, MPQs, account data or ordinary saved key
bindings. Stock Wrath clients and older Ascension builds may not expose the
required APIs.

## Installation

1. Download the versioned `CoACombat-x.y.z.zip` release asset. GitHub's generic
   **Source code.zip** may add an unwanted repository-name wrapper folder.
2. Extract it into the game's `Interface/AddOns` directory.
3. Confirm this exact layout:

   ```text
   Interface/AddOns/CoACombat/CoACombat.toc
   Interface/AddOns/CoACombat/Textures/Triad.tga
   ```

   Keep the folder name `CoACombat`; the texture paths use that name.
4. At character selection, open **AddOns** and enable
   **CoA Combat (Action Camera)**. Enable **Load out of date AddOns** only if
   your compatible Ascension build labels Interface 30300 addons as outdated.
5. Fully exit and reopen Ascension after the first install or any release that
   adds files. This legacy client does not discover new Lua or texture files
   through `/reload`.

Updating normally means replacing the `CoACombat` folder while the client is
closed. Settings remain in the client's `WTF` directory.

## Required first-time setup

CoACombat deliberately does not overwrite your permanent game key bindings.
You must assign the cursor-release key yourself:

1. Log in and open **Escape → Key Bindings → CoA Combat**.
2. Bind **Release camera until next world click**. **Caps Lock** is the
   recommended laptop-friendly choice.
3. Optionally bind **Toggle action camera** and **Show crosshair** in the same
   category.
4. Type `/cac on` to start action mode. `/cac off` always releases the cursor
   and disables the temporary controls.

Pressing the release key hides the reticle and frees the cursor with no timer.
After finishing with the UI, press and release a mouse button over the game
world to lock the camera again. Opening standard menus, bags, chat, quest
windows, popups or a ground-target spell also releases it automatically.

Next, type `/cac options`:

- **Left mouse action**, **Right mouse action** and **Middle mouse action** are
  WoW action commands, not keyboard names. `ACTIONBUTTON1` means action-bar
  slot 1, so place the desired ability in that slot.
- **Interact key** is the keyboard key used to talk, loot and interact. The
  default is **E**; enter **F** if that is your preferred layout.
- Select **Apply bindings** after editing these fields.
- Select **Crosshair** for shape, scale, opacity and colour controls.
- Select **Camera** for the on-foot, mounted and combat camera profiles.

Recommended starting layout:

| Control | Recommended assignment | Where to configure it |
|---|---|---|
| Release cursor | Caps Lock | Escape → Key Bindings → CoA Combat |
| Left mouse | `ACTIONBUTTON1` | `/cac options` |
| Right mouse | `ACTIONBUTTON2` | `/cac options` |
| Middle mouse | `ACTIONBUTTON3` or blank | `/cac options` |
| Interact | F | `/cac options` |
| Target cycle | Your existing Tab binding | Normal WoW key bindings |

## How it works

While action mode is active and no menu is open, CoACombat starts mouselook,
centres and hides the pointer, shows the reticle, and temporarily maps the
configured controls. It never replaces the saved bindings in the game client.

For `ACTIONBUTTON1` through `ACTIONBUTTON12`, a hardware-triggered secure macro
first selects a living hostile mouseover, falls back to a nearest enemy only
when the current target is missing or dead, and then clicks the requested
action slot. This allows an action press to switch away from a still-living old
target when the client resolves the new enemy at the centre. Custom `SPELL`,
`MACRO`, `ITEM` and `CLICK` commands retain their own targeting behavior.

Interaction uses the client's native `INTERACTMOUSEOVER` hardware binding. It
tries the mouseover unit and then the selected target, and remains available
when the cursor is temporarily released. The RPG camera changes only supported
camera CVars, snapshots their prior values, and restores values it still owns
when action mode is disabled or the character logs out.

The reticle is anchored to the exact screen centre. Its colour reflects no
target, hostile, friendly, interactable and dead mouseover states. Colour mode
and opacity change only the reticle; they do not alter the game world.

Bindings use the client's `SetMouselookOverrideBinding` API. They apply
only while mouselooking, so menus and ground-spell placement have their
normal mouse controls. The interaction key additionally uses an owned,
temporary override with the cursor released. Disabling clears this override
and restores the underlying game binding. Saved game bindings are never
changed. The optional
RPG camera temporarily changes supported camera CVars and restores its
previous values when disabled or logged out.
This API has no owner frame or getter: another camera addon using the same
keys can conflict. Its prior mouselook overrides cannot be restored.

Binding edits are deferred during combat. Enabling from off during combat
waits until combat ends before capturing the cursor. Disabling releases
the cursor immediately, and removes installed overrides after combat.
Until then, manually entering mouselook can still use the old overrides.

## Commands

`/coacombat` and `/cac` are equivalent.

```text
/cac                         status
/cac help                    command reference
/cac on|off|toggle            action mode
/cac options                 settings panel
/cac lmb <command>            left mouse action; blank clears
/cac rmb <command>            right mouse action; blank clears
/cac mmb <command>            middle mouse action; blank clears
/cac interact <key>           move interaction to another key
/cac bind <key> <command>     custom mouselook binding
/cac unbind <key>             clear a binding
/cac reticle show|hide        crosshair visibility
/cac reticle size <4-128>     size in UI pixels
/cac reticle style <name>    triangle, cross, dot, plus, stacked, diagonal, curved, or tbar
/cac reticle opacity <10-100> global crosshair opacity percentage
/cac reticle color <mode>    normal, redgreen, blueyellow, contrast, or mono
/cac reticle options         crosshair appearance panel
/cac pause                    release until a new world click is released
/cac macros                   casting templates
/cac targeting on|off         aimed-enemy switching on action-slot presses
/cac targeting debug          last camera-lock aim and native API availability
/cac assist on|off            optional nearby-nameplate aiming cue
/cac assist radius <20-300>   search radius in UI pixels
/cac preset save <name>       save current bindings and interact key
/cac preset load <name>       restore saved bindings
/cac preset delete <name>     remove a preset and its spec assignments
/cac preset list              list this character's presets
/cac preset spec <1|2> <name> assign a preset to a talent group
/cac preset spec <1|2> off    remove that assignment
/cac camera rpg              restore RPG camera defaults and triangular reticle
/cac camera on|off           enable framing or restore previous camera settings
/cac camera options          camera settings for each movement state
/cac camera speed <0-3>      framing transition duration in seconds
/cac camera profile <state> <setting> <value>  change one profile setting
/cac reset                    defaults, mode off, delete character presets
```

Commands include `ACTIONBUTTON1` through `ACTIONBUTTON12`,
`MULTIACTIONBAR1BUTTON1` through `MULTIACTIONBAR4BUTTON12`, `STARTATTACK`,
`JUMP`, `TOGGLEAUTORUN`, `CAMERAZOOMIN`, and `CAMERAZOOMOUT`.
Direct forms include `SPELL Fireball`, `MACRO My Macro`, `ITEM ItemName`,
and `CLICK ButtonName:RightButton`. The older space-separated CLICK form
is also accepted and converted. The client determines supported commands.

## Cursor release

The cursor releases for standard panels, bags, chat and other focused
text fields, popups, death/ghost, cinematics, dragged items/spells, and
armed ground-target spells. It resumes when those blockers clear and the
pointer is over the world. Pausing has no timeout and survives chat closing;
a new press and release over the world resumes it. UI clicks do not.
`/cac on` also resumes explicitly.

Custom UI panels may need additional frame names in
`CoACombatDB.extraReleaseFrames`, followed by `/reload`. Custom bag and
Ascension panel layouts require an in-game compatibility check. Compatibility
with ElvUI or Clique has not been certified in this verification pass.

## Casting and interaction

Put this damage macro on a mouse-bound action slot:

```text
/cast [@mouseover,harm,nodead][@target,harm,nodead][] Frostbolt
```

Healing example:

```text
/cast [@mouseover,help,nodead][@target,help,nodead][@player] Heal
```

The first valid macro clause wins. Mouseover uses the client's mouseover
unit; the crosshair itself does not change the engine's targeting ray.
Confirm that this Ascension build resolves mouseover at the crosshair
while mouselooking before relying on aiming casts.

For ground AoE, use `/cast SpellName` and place the targeting circle
manually. The addon automatically releases mouselook while targeting.
Stock 3.3.5a does not provide the later `@cursor` ground-cast workflow.
Use your interaction key while close to a quest giver. Point at the NPC or
select it and press the key, with the cursor locked or released. The native
INTERACTMOUSEOVER handler tries mouseover first, then your selected target if
mouseover interaction fails. It does not select an unrelated nearby unit.
World-object interaction depends on the client's native binding behavior.
The Lua `:Interact()` helper only prints the configured key.

## Aiming cues and presets

Aiming assistance is **off by default**. It scans visible legacy Blizzard
nameplates, selects the nearest red/yellow health bar inside the radius,
and displays its name under the crosshair when no mouseover unit exists.
It excludes green/grey bars and keeps a small preference for the previous
plate while it remains visible and inside the radius. Custom nameplate
textures may not be detected. It never changes your target or fires actions.
Tab keeps its existing behavior; it does not guarantee selection of the
indicated nameplate. Duplicate names cannot identify individual units.

Presets store complete copies of bindings and the interact key in
per-character saved variables. Active settings remain account-wide.
Preset names are one word and case-sensitive. Example:

/cac preset save melee
/cac lmb ACTIONBUTTON3
/cac preset save caster
/cac preset spec 1 melee
/cac preset spec 2 caster
```

Mapped presets load at login and talent-group changes. Zone transitions
do not overwrite edits. Use `preset save` again to update a stored preset;
loading one replaces the complete binding set. Combat changes defer.
The main options panel provides camera/crosshair/cue toggles, mouse actions,
interaction key, crosshair size, and preset save/load controls. Its
**Crosshair** button opens the appearance panel with previous/next style and
colour-vision controls, a live preview, a 4–128 scale slider, a 10–100%
opacity slider, and an appearance-only reset.

## Crosshair appearance and accessibility

Eight styles are included: the original three-bar triangle, the classic
procedural cross, a small centre dot, and the five supplied Plus, Stacked,
Diagonal, Curved and T-bar designs. Every texture keeps the source canvas's
exact 50/50 aim point at screen centre. Scaling changes the square canvas
around that pivot; it does not crop or visually re-centre the asymmetric
Stacked or T-bar artwork.

Colour modes include Default, Red-green safe, Blue-yellow safe, High contrast
and Monochrome. Each mode has a distinct idle/no-target colour as well as
contextual hostile, friendly and interactable colours, so changing modes is
visible while aiming at terrain. These are user-selectable visibility alternatives; the game
world and nameplate context remain the non-colour cues for unit state. The
opacity slider multiplies the existing contextual alpha, including the dim
idle state. W3C guidance likewise recommends sufficient contrast and avoiding
colour as the only information channel:
https://www.w3.org/WAI/perspectives/contrast.html

The five original JPGs are preserved in
`Tools/coacombat/crosshair-sources`. `build_crosshairs.py` verifies their
SHA-256 hashes, converts white to transparent alpha without cropping, exports
128x128 tintable RGBA TGAs, and writes `crosshair-build.json` plus a visual
contact sheet. New clients must be fully restarted after first receiving the
new Lua and texture files; `/reload` cannot discover them in this legacy client.

The main binding fields deliberately hide Ascension's inherited
`Common-Input-Border` textures and draw a flat background with a one-pixel
border. This avoids the oversized grey end-cap blocks produced by this
client's skin while retaining the native edit-box text, focus and cursor.

Camera/settings/preset messages support enUS, deDE and frFR. Command
reference, status details and macro explanations use English fallback;
other client languages use English throughout.

## RPG camera

Inspired by [ActionCamPlus](https://www.curseforge.com/wow/addons/actioncamplus),
this is an original controller for the native Ascension camera extension.
It uses `ActionCam`, `cameraActionAngle`, `cameraActionDist`, `cameraActionZ`,
and the native head-bob and target-focus CVars. It does not install retail
ActionCamPlus or assume that retail `test_camera*` CVars exist.

There are three profiles: `foot`, `mounted`, and `combat`. Mounted settings
take priority during combat while mounted; travel/aquatic/flight forms can
also use that profile. Transitions interpolate native angle, distance and
height over 0.7 seconds by default. Zero transition seconds applies immediately.
Each profile controls angle (0-6), distance multiplier (0.25-2), height
(-1.25 to 0.75), head bob, enemy focus and interactable NPC focus. Head bob
and automatic focusing default off for stable manual aiming. Focus temporarily
turns off during menu use, manual pause, or ground-spell targeting.

The default native angle/distance/height start at the extension's registered
defaults (4, 1.25, 0.05); mounted/combat distance values widen the view. Tune
angle and height in the camera page and use the mouse wheel to match the
character size in the reference screenshot. Character size, camera pitch,
terrain, aspect ratio and UI scale affect the final appearance; it has not
been matched in the live game yet. The reticle has three separated bars,
one above and two below, with no centre dot, and retains mouseover colours.

For example:

```text
/cac camera profile foot distance 1.0
/cac camera profile foot height 0.15
/cac camera profile combat enemy on
/cac camera speed 0.5
```

Settings are `angle`, `distance`, `height`, `enemy`, `interact`, `headbob`,
`zoom` and `recall`; boolean values use `on`/`off`. Numeric distances here
are native multipliers, not absolute wheel-zoom distances.

Exact zoom recall is optional and requires `GetCameraZoom`, `CameraZoomIn`
and `CameraZoomOut`. This client's extracted API and binaries provide no
documented `GetCameraZoom`; recall controls stay disabled when it is absent.
The regular wheel continues working. On clients where all three are available,
recall can remember settled manual wheel zoom per state. Wheel zoom itself
is not reset when the addon is disabled. Retail dynamic pitch, focusing
strength sliders and per-mount spell zoom tables are not provided.

Original camera values and the last values written by the addon are persisted
for recovery across `/reload`. Only values still matching the addon's last
write are restored, preserving changes made since then. Supported camera
settings are restored on `/cac off`, `/cac camera off`, reset, and logout.
If using another camera controller, turn one controller off to avoid conflicts.

## Troubleshooting

### The camera locks, but my cursor-release key does nothing

Open **Escape → Key Bindings → CoA Combat** and confirm that
**Release camera until next world click** has a key. Installing the addon does
not assign this permanent binding. `/cac pause` invokes the same release action
for diagnosis. `/cac on` must be active.

### The cursor will not lock again

Close chat and any open panels, then press and release a mouse button over the
game world. `/cac on` also clears a manual pause. The addon intentionally stays
released while a text field, menu, popup, dragged item or ground-target spell
is active.

### A new crosshair or settings page is missing

Fully close and reopen Ascension. `/reload` can reload known files but cannot
make this client discover files which were added after it started. Confirm the
addon folder is named exactly `CoACombat` if a texture falls back to the
classic cross.

### The crosshair colour appears unchanged

Close the options window so the gameplay reticle can appear, then try the
High contrast preset while aiming at terrain. Colour also changes contextually
when the client reports hostile, friendly, interactable or dead mouseover
units. Check the opacity slider if the result is too faint.

### The interact key does not open a quest giver

Point at the NPC or select it, stand in interaction range and press the key.
Check the configured key in `/cac options`. `/cac targeting debug` reports the
resolved interaction mappings without attempting a protected interaction.

### Bindings changed during combat do not apply immediately

This is intentional. The client protects binding and secure-button changes in
combat, so CoACombat applies the pending configuration when combat ends.

### Resetting

`/cac reset` turns action mode off, restores appearance and binding defaults,
and deletes this character's CoACombat presets. Use it only when a full reset
is intended.

## Verification and remaining work

See `Tools/coacombat/HANDOVER.md` from the workspace root for findings,
API references, regression checks and the in-game acceptance checklist.
The separate `claude/coacombat-design.md` referenced in the original README
was not present in the supplied folder or archive.

Automatic nameplate targeting and automatic centre ground-AoE confirmation
remain open. They need a documented, supported Ascension client extension
or a different secure design. Calling protected targeting/interaction
functions from addon update callbacks is not an implementation for them.

## Uninstall

Turn mode off out of combat, then exit the client and delete the CoACombat
folder. Account settings are in `WTF/Account/<ACCOUNT>/SavedVariables/CoACombat.lua`;
character presets are in the character's `SavedVariables/CoACombat.lua`.
Delete those only if you also want to remove saved settings.
