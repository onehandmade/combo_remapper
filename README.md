# Combo ReMapper 9.0

Combo ReMapper is a feature-rich AutoHotkey v2 script for remapping keyboard, mouse, and controller inputs into custom combo sequences, hotkeys, and macros. It is designed for accessibility, game control customization, and rapid input remapping in Windows games and apps.

Version 9.0 adds a more complete controller engine, improved compatibility modes, safer mouse trigger handling, and better game input behavior while keeping the original combo-based workflow.

## What’s new in 9.0

### TglTurbo mode
- Adds a hybrid toggle/turbo behavior for rows that need to stay active while also repeating actions continuously.
- Useful for sustained actions such as held movement, repeated key taps, or rapid macro loops while the trigger remains down.

### Controller on/off support
- Adds a master controller enable/disable switch for the pad engine.
- Allows the script to turn gamepad input processing on or off via custom trigger logic.
- Keeps pad polling from interfering when controller input should be temporarily ignored.

### Right-click trigger fix
- Fixes the classic recursion problem where using right-click as a trigger could cause the script to trigger itself endlessly.
- The engine now detects when a mouse button is being used as an own trigger and sends it in a way that avoids hotkey re-entry loops.

### Switchable compatibility modes
The script supports 3 input-sending modes:

- Game mode: scan codes + raw mouse_event for better compatibility with games that read raw input.
- Classic mode: SendInput with plain key names.
- Hybrid mode: SendInput scan codes + AutoHotkey mouse events.

This lets users choose the safest mode for different games and apps.

### Expanded controller support
- Native XInput support for Xbox-style pads.
- DirectInput support for pads such as DualShock / PS4-style controllers.
- Auto-detection of controller type.
- D-pad and stick digital token support.
- Trigger thresholds and stick deadzones for gamepad input tuning.
- Controller panic combo support (
  - Xbox: Start + Back
  - PS4: Share + Options
  )

### Stick-to-mouse and controller cursor control
- Left stick or right stick can be mapped to mouse movement.
- Includes speed scaling, deadzone, and response curve controls.
- Useful for games that need cursor control or camera-style movement from a controller.

### Advanced mouse automation
- Relative movement: `mX,Y`
- Absolute pointer movement: `mxX,Y`
- Smooth relative motion: `mmX,Y,ms`
- Screen shake / jitter: `mshakeAmp,ms`
- Mouse wave motion: `mwaveX,Y,ms,stepMs`
- Continuous drift while held: `mhVX,VY`
- Y-axis lock hotkey (`F6`) for motion control stability

### Better hold/toggle behavior
- Continuous motion can run while a Hold row is active or while a Toggle row is enabled.
- Motion state is tracked cleanly and can be aborted/reset safely when the script is disabled or a target process is no longer active.

### Safety and reliability improvements
- Auto-elevates the script when needed for elevated games or emulators.
- Releases all stuck combos on exit or compatibility mode changes.
- Logs unexpected hotkey errors without crashing the entire script.
- Includes a global panic key (`F8`) for suspend/kill-switch behavior.
- Keeps track of held keys and automatically releases them.

### Profiles, UI, and session state
- Local profile system saved in `.ini` files.
- Auto-profile switching by active executable name.
- On-screen display (OSD) for status and macro feedback.
- Live log window for recent triggered events.
- Tray menu and settings management.
- Theme support with Dark, Light, and custom image backgrounds.

## Core features

### Multi-input remapping
- Keyboard keys
- Mouse buttons and wheel actions
- Controller buttons and sticks
- D-pad logic and trigger input

### Combo row modes
The script supports multiple row behaviors:

- Toggle
- Hold
- Press
- Turbo
- TapHold
- TglTurbo

These modes let you create everything from simple key swaps to directional movement triggers and long repeated macros.

### Game-compatible input engine
The engine is designed to work well with games that read scan codes or raw input:

- Raw mouse_event for game-safe relative movement
- SendInput and scan code-based sends depending on compatibility mode
- Delay tuning to help modern games register inputs reliably

### Accessibility-first design
The project was built with accessibility use cases in mind, especially for users who need alternative input layouts or reduced finger strain. Features like hold-to-toggle logic, controller macros, and adaptive motion control are part of the design focus.

## Default hotkeys

| Hotkey | Action |
| --- | --- |
| F6 | Toggle Y-axis mouse lock |
| F7 | Toggle OSD overlay |
| F8 | Panic suspend / hard reset |

## Special token syntax

### Timing and delays
- `d150` or `150` — pause for 150 ms before continuing the combo sequence

### Mouse tokens
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

### Controller tokens
- `J1` through `J32` — controller buttons
- `JPOVU`, `JPOVD`, `JPOVL`, `JPOVR` — D-pad directions
- `XUP`, `XDOWN`, `XLEFT`, `XRIGHT`, `XSTART`, `XBACK`, etc. — XInput tokens
- `XLSU`, `XLSD`, `XLSL`, `XLSR`, `XRSU`, `XRSD`, `XRSL`, `XRSR` — stick directions

## Compatibility and notes

This software injects input and can be detected differently depending on the game, emulator, or anti-cheat system in use.

- Many indie games and older titles work well.
- Some anti-cheat systems may actively detect or restrict remapping tools.
- Competitive or online games with strict anti-cheat rules may ban or flag these tools.

Use with caution and always test in a safe environment before relying on it in competitive play.

## Requirements

- Windows 10 / 11
- AutoHotkey v2.0+
- Administrator privileges recommended for elevated games/emulators

## Files

- `Combo_ReMapper_9_0.ahk` — main script
- `profiles/` — saved remap profiles
- `remapper_global.ini` — global script settings

## Author

- Dani
- Created with assistance from AI (Claude by Anthropic) and designed with accessibility-focused keyboard/mouse/controller remapping in mind.

---

This README reflects the current feature set in the supplied AutoHotkey script, including the newly added TglTurbo, controller enable/disable logic, right-click fix, compatibility modes, and advanced controller/mouse behavior.
