# Combo Remapper (AutoHotkey v2)

Turns "hold two keys at once" combos into a single key press. Also supports simple single-key-to-mouse-action triggers. Made for accessibility — if pressing multiple buttons together is hard, this does it for you.
  Warning. This was made with artificial intelligence because I am disabled, and I can't develop because of my hands. I know how. I just can't. I'm sorry. But if you have this project, help this project. You can help.
## Requirements
- **AutoHotkey v2** (not v1) — download from https://www.autohotkey.com/
- 

## How to run it
1. Install AutoHotkey v2 if you haven't already.
2. Double-click `combo_remapper.ahk` to start it. You'll see a small green "H" icon in your system tray while it's running.
3. To stop it completely, right-click the tray icon and choose Exit.

## Controls

| Key | Action |
|---|---|
| **F8** | Turn the whole script on/off (panic button) |
| **K** | Mouse middle-click (scroll-wheel click) |
| **F1** | Holds `L` + `1` together *(example — edit to match your real bindings)* |
| **F2** | Holds `Shift` + `W` together (common: sprint + forward) |
| **F3** | Holds `Ctrl` + `C` together (common: crouch-walk) |
| **F4** | Holds `Shift` + `Space` together (common: sprint-jump) |
| **F5** | Holds `Ctrl` + `Shift` together (common: crouch-sprint/slide) |

F8 turns everything off at once if you need to stop mid-game — none of the other keys will do anything while it's off, and pressing F8 again turns it back on.

## Editing or adding your own combos
Open `combo_remapper.ahk` in Notepad (or any text editor) and find this section near the top:

```
combos := Map(
    "F1", ["l", "1"],
    "F2", ["shift", "w"],
    "F3", ["ctrl", "c"],
    "F4", ["shift", "space"],
    "F5", ["ctrl", "shift"]
)
```

Each line means: *pressing this trigger key holds down these two real keys together.* To change one, just edit the key names. To add a new one, add another line in the same format — pick any key that isn't already used elsewhere in this list (or by the lockpicking script, if you're running both).

Save the file and re-run it (or right-click the tray icon → Reload Script) for changes to take effect **Combo Remapper v8.0 GUI** is an AutoHotkey v2 script designed to remap key combinations and automate complex input patterns across games, emulators (like PCSX2), and productivity software.

### **Core Capabilities**

* **Execution Modes:** Remaps trigger keys into four distinct modes—`Hold` (holds sequence while pressed), `Toggle` (flips key state on/off), `Press` (fires sequence once), and `Turbo` (loops sequence every 60ms).


* **Profile System:** Automatically creates, loads, and saves configuration `.ini` files. It includes an auto-switcher that detects target executable windows (e.g., `pcsx2-qt.exe`) to load specific profiles on the fly.


* **Auto Key Recorder:** Uses an interactive `InputHook` engine to automatically capture keypresses and bind them to slots without manual typing.


* **Safety Controls:** Includes a dedicated **Panic Key** (default: `F8`) to instantly kill active timers and unlatch all held/toggled inputs.


* **Customization:** Features full theme switching (Dark, Light, Custom HEX colors, or Background Images), dynamic scroll-wheel navigation for UI rows, and configurable key/mouse delays.

## Notes
- Windows may flag AutoHotkey scripts with a antivirus warning — this is common for all AHK scripts, not just this one, since they can simulate keypresses. You can allow it if you trust the source.
- If you're also running the lockpicking mouse-circle script at the same time, both can run together safely — they don't share any keys.
{https://youtu.be/6qu_r_OrRcw}
