# Combo Remapper v8.15 (AutoHotkey v2)

Combo Remapper turns difficult multi-key combinations into a single trigger key. It also supports single-key-to-mouse-action triggers and is designed with accessibility in mind. Use it with games and everyday applications to make keyboard and mouse controls easier to reach.

> **Accessibility note:** This project was created to help people who have difficulty pressing multiple buttons together. It was developed with assistance from artificial intelligence because the developer has a disability affecting their hands. Contributions, testing, and helpful suggestions are welcome.

## What's new in v8.15

- Updated to **Combo Remapper v8.15**.
- Added compatibility guidance for games and applications.
- Added information about compatible remapping modes.
- Added an **About the Developer** section.

## Requirements

- **Windows**
- **AutoHotkey v2** (not v1): https://www.autohotkey.com/

The downloadable release also includes compiled `.exe` and source `.ahk` versions when available.

## How to run it

1. Install AutoHotkey v2 if you are running the `.ahk` version.
2. Download and run the v8.15 release from the [Releases](https://github.com/onehandmade/combo_remapper/releases) page.
3. Double-click `combo_remapper.ahk` to start the script. A small green **H** icon appears in the system tray.
4. To stop it completely, right-click the tray icon and choose **Exit**.

## Remapping modes

Combo Remapper supports these modes for games and applications:

- **Hold** — holds the mapped keys while the trigger is held.
- **Toggle** — presses the trigger once to turn the mapped keys on, and again to turn them off.
- **Press** — sends the mapped key sequence once per trigger.
- **Turbo** — repeatedly sends the mapped sequence while enabled.

These modes can be used with games, emulators, productivity software, and other Windows applications. Some games or applications may restrict simulated input or may require the script to run with the same privileges as the target application.

## Default controls

| Key | Action |
|---|---|
| **F8** | Turn the whole script on/off (panic button) |
| **K** | Mouse middle-click (scroll-wheel click) |
| **F1** | Holds `L` + `1` together *(example — edit to match your bindings)* |
| **F2** | Holds `Shift` + `W` together |
| **F3** | Holds `Ctrl` + `C` together |
| **F4** | Holds `Shift` + `Space` together |
| **F5** | Holds `Ctrl` + `Shift` together |

F8 turns everything off at once if you need to stop mid-game. While it is off, the other remappings do nothing; press F8 again to turn them back on.

## Editing or adding your own combos

Open `combo_remapper.ahk` in Notepad or another text editor and find the combo definitions near the top:

```ahk
combos := Map(
    "F1", ["l", "1"],
    "F2", ["shift", "w"],
    "F3", ["ctrl", "c"],
    "F4", ["shift", "space"],
    "F5", ["ctrl", "shift"]
)
```

Each line means that pressing the trigger key holds or sends the specified real keys together. Edit the key names to change a combo, or add another line to create a new one. Save the file and restart it, or right-click the tray icon and choose **Reload Script**, for changes to take effect.

## Core capabilities

- **Execution modes:** Hold, Toggle, Press, and Turbo.
- **Profile system:** Creates, loads, and saves configuration `.ini` files, with an auto-switcher for target executable windows.
- **Auto Key Recorder:** Uses an interactive `InputHook` engine to capture keypresses and bind them to slots.
- **Safety controls:** The panic key (default F8) stops active timers and releases held or toggled inputs.
- **Customization:** Supports Dark, Light, custom HEX colors, background images, scroll-wheel navigation, and configurable key/mouse delays.

## About the developer

Combo Remapper is maintained by **onehandmade**. The project was created to make keyboard and mouse controls more accessible for people who find simultaneous key presses difficult. Feedback, testing, documentation improvements, and accessibility suggestions are appreciated.

## Notes

- Windows may show an antivirus warning for AutoHotkey scripts. This is common for scripts that simulate keyboard or mouse input; only allow the program if you trust the source.
- Run the script with appropriate permissions if the target game or application is running as administrator.
- If you also run the lockpicking mouse-circle script, both scripts can run together safely because they do not share keys.

## Video

https://youtu.be/6qu_r_OrRcw
