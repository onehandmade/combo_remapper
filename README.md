# Combo ReMapper 9.1

Combo ReMapper is a feature-rich AutoHotkey v2 script for remapping keyboard, mouse, and controller inputs into custom combo sequences, hotkeys, and macros. It is designed for accessibility, game control, and low-friction input customization.

Version 9.1 adds local diagnostics logging, better troubleshooting output, and continued stability improvements while keeping the original combo-based workflow.

## What’s New in 9.1

### Local Diagnostics Log
- Adds a local `combo_remapper.log` file next to the script for troubleshooting.
- Records profile loads, safety releases, and unexpected errors without interrupting the script.
- Includes a tray option to open the log file or copy a short diagnostics snapshot to the clipboard.

### TglTurbo Mode
- Adds a hybrid toggle/turbo behavior for rows that need to stay active while also repeating actions continuously.
- Useful for sustained actions such as held movement, repeated key taps, or rapid macro loops while the trigger remains down.

### Controller On/Off Support
- Adds a master controller enable/disable switch for the pad engine.
- Allows the script to turn gamepad input processing on or off when needed.
- Helps avoid controller interference when input should be temporarily ignored.

### Right-Click Trigger Fix
- Fixes the classic recursion problem where using right-click as a trigger could cause the script to trigger itself endlessly.
- The engine detects when a mouse button is used as its own trigger and sends it in a way that avoids hotkey re-entry loops.

### Switchable Compatibility Modes
The script supports 3 input-sending modes:

- Game mode: scan codes + raw mouse_event for better compatibility with games that read raw input.
- Classic mode: SendInput with plain key names.
- Hybrid mode: SendInput scan codes + AutoHotkey mouse events.

This allows users to choose the safest mode for different games and apps.

### Expanded Controller Support
- Native XInput support for Xbox-style controllers.
- DirectInput support for pads such as DualShock / PS4-style controllers.
- Automatic controller type detection.
- D-pad and stick digital token support.
- Trigger thresholds and stick deadzones for gamepad tuning.
- Panic combo support:
  - Xbox: Start + Back
  - PS4: Share + Options

### Stick-to-Mouse and Controller Cursor Control
- Left stick or right stick can be mapped to mouse movement.
- Includes speed scaling, deadzone, and response curve controls.
- Useful for games that need cursor control or camera-style movement from a controller.

### Advanced Mouse Automation
- Relative movement: `mX,Y`
- Absolute pointer movement: `mxX,Y`
- Smooth relative motion: `mmX,Y,ms`
- Screen shake / jitter: `mshakeAmp,ms`
- Mouse wave motion: `mwaveX,Y,ms,stepMs`
- Continuous drift while held: `mhVX,VY`
- Y-axis lock hotkey (`F6`) for motion control stability

### Better Hold/Toggle Behavior
- Continuous motion can run while a Hold row is active or while a Toggle row is enabled.
- Motion state is tracked and can be safely aborted or reset.
- Prevents stuck movement states when the script is disabled or the target process is no longer active.

### Safety and Reliability Improvements
- Auto-elevates the script when needed for elevated games or emulators.
- Releases all stuck combos on exit or compatibility mode changes.
- Logs unexpected hotkey errors without crashing the whole script.
- Includes a global panic key (`F8`) for suspend/kill-switch behavior.
- Keeps track of held keys and automatically releases them.

### Profiles, UI, and Session State
- Local profile system saved in `.ini` files.
- Auto-profile switching by active executable name.
- On-screen display (OSD) for status and macro feedback.
- Live log window for recent triggered events.
- Tray menu and settings management.
- Theme support with Dark, Light, and custom image backgrounds.

## Local Diagnostics and Privacy Warning

The script can write a local diagnostics log named `combo_remapper.log` in the same folder as the script. This is primarily for troubleshooting unexpected errors, profile changes, and safety resets.

Warning: this log is local-only. It stays on your machine and is not automatically uploaded or sent anywhere. The author cannot access it unless you open the file and send it yourself.

If you need to share a problem, open the log file from the tray menu or copy the diagnostics snapshot and paste it into a support message.

## Core Features

### Multi-Input Remapping
- Keyboard keys
- Mouse buttons and wheel actions
- Controller buttons and sticks
- D-pad logic and trigger input

### Combo Row Modes
The script supports multiple row behaviors:

- Toggle
- Hold
- Press
- Turbo
- TapHold
- TglTurbo

These modes let you create everything from simple key swaps to directional movement triggers and long repeated macros.

### Game-Compatible Input Engine
The engine is designed to work well with games that read scan codes or raw input:

- Raw `mouse_event` for game-safe relative movement
- SendInput and scan code-based sends depending on compatibility mode
- Delay tuning to help modern games register inputs reliably

### Accessibility-First Design
The project was built with accessibility use cases in mind, especially for users who need alternative input layouts or reduced finger strain. Features like hold-to-toggle logic, controller macros, and profile switching are designed to make remapping easier and less physically demanding.

## Anti-Cheat & Game Compatibility

Important: Input injection scripts are detected and handled differently by every game's anti-cheat system. Some games explicitly ban remapping tools, even when used for accessibility purposes.

### Tested Compatible Games
- Many indie games, older titles, and games without anti-cheat are usually fine.
- Games with Easy Anti-Cheat, BattlEye, or kernel-mode anti-cheat may detect the script.
- Competitive online games such as Valorant, Apex Legends, Fortnite, and PUBG typically ban all input remapping.

Before using Combo ReMapper with any new game:
1. Check the game's official support for accessibility remapping tools.
2. Review the anti-cheat policy documentation.
3. Test on a non-ranked or non-competitive account if possible.
4. Ask the accessibility community about experiences with that specific title.

### Compatibility List

| Game/Platform | Status | Notes |
| --- | --- | --- |
| PCSX2 Emulator | ✅ Working | Fully compatible |
| GTA San Andreas | ✅ Working | Fully compatible |
| No More Heroes | ✅ Working | Fully compatible |
| VRChat | ✅ Working | Fully compatible |
| My Hero Ultra Rumble | ✅ Working | Fully compatible |
| Lollipop Chainsaw RePop | ✅ Working | Fully compatible |

## Default Hotkeys

| Hotkey | Action |
| --- | --- |
| `F6` | Toggle Y-axis mouse lock |
| `F7` | Toggle OSD overlay |
| `F8` | Panic suspend / hard reset |

## Special Token Syntax

### Timing and Delays
- `d150` or `150` — pause for 150 ms before continuing the combo sequence

### Mouse Tokens
- `mlc` — left click
- `mrc` — right click
- `mmc` — middle click
- `mdown` — press and hold left mouse button
- `mup` — release left mouse button
- `mwd2` / `mwu2` — wheel down/up by 2 ticks
- `m100,-50` — relative mouse move by X/Y pixels
- `mx400,300` — absolute mouse move to coordinates
- `mm200,0,500` — smooth move over 500 ms
- `mshake12,600` — shake effect with 12 px amplitude for 600 ms
- `mh300,0` — continuous mouse drift while held/toggled

### Controller Tokens
- `J1` through `J32` — controller buttons
- `JPOVU`, `JPOVD`, `JPOVL`, `JPOVR` — D-pad directions
- `XUP`, `XDOWN`, `XLEFT`, `XRIGHT`, `XSTART`, `XBACK`, etc. — XInput tokens
- `XLSU`, `XLSD`, `XLSL`, `XLSR`, `XRSU`, `XRSD`, `XRSL`, `XRSR` — stick directions

## Requirements

- Windows 10 / 11
- AutoHotkey v2.0+
- Administrator privileges recommended for elevated games/emulators

## Files

- `Combo_ReMapper_9_1.ahk` — main script
- `profiles/` — saved remap profiles
- `remapper_global.ini` — global script settings

## Author

- Dani
- Created with assistance from AI (Claude by Anthropic) and designed with accessibility-focused keyboard, mouse, and controller remapping in mind.

---

This README reflects the current feature set in the supplied AutoHotkey script, including the new local diagnostics logging, TglTurbo mode, controller enable/disable logic, right-click fix, compatibility modes, and advanced controller/mouse behavior.
