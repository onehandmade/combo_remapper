# Combo ReMapper 8.15

**Combo ReMapper** is a feature-rich AutoHotkey v2 script designed to remap mouse actions, keyboard keys, and gamepad inputs into custom combo sequences, hotkeys, and macro routines. Built with accessibility in mind, it empowers users with disabilities and accessibility needs to play games and use software comfortably.

## 🌟 Key Features

* **Multi-Input Support:** Remap keyboard keys, mouse buttons, wheel events, and Gamepad / Controller triggers (`J1`-`J32`, `JPOVU`, `JPOVD`, `JPOVL`, `JPOVR`).

* **5 Distinct Remap Modes:**

  * **Toggle:** Toggles defined key states or continuous motion on and off with each press. *Perfect for converting holds into taps — a critical accessibility feature for users with limited grip strength or stamina.*

  * **Hold:** Holds target keys down for as long as the trigger key is held down.

  * **Press:** One-shot execution of a key combo sequence on press.

  * **Turbo:** Continuously repeats a sequence at a specified millisecond interval while held.

  * **TapHold:** Executes one action on a short tap (<250ms) and another on a long hold.

* **Game-Compatible Input Engine:**

  * 3 switchable modes: **Game** (Scan codes + Raw mouse_event), **Classic** (SendInput), and **Hybrid**.

  * Dynamic frame delay timing to ensure modern DirectInput and RawInput games properly register inputs.

* **Advanced Mouse Automation:**

  * Relative (`mX,Y`) and absolute (`mxX,Y`) mouse positioning.

  * Timed smooth mouse sliding (`mmX,Y,ms`) and camera jitter/shake (`mshakeAmp,ms`).

  * Continuous background mouse drift (`mhVX,VY`) for hold/toggle actions.

  * Y-Axis lock hotkey (`F6`).

* **Live Recording Engine:** Click **Auto** on any row to automatically capture incoming keyboard, mouse, or gamepad inputs into your active combo.

* **OSD Overlay & Indicator:** Floating status indicator overlay (`F7` default) showing active script state and live macro feedback.

* **Profiles & Import/Export:** Unlimited profiles saved locally (`.ini`), with fast clipboard sharing strings for exporting and importing configurations.

* **Target Process Filtering:** Limit macro triggers to run only when a specific target executable (e.g., `game.exe`) is active.

* **Accessibility Focused:** Created with open acknowledgement of accessibility-driven design principles.

## ⚠️ Anti-Cheat & Game Compatibility

**Important:** Input injection scripts are detected and handled differently by every game's anti-cheat system. Some games explicitly ban for input remapping, even when used for accessibility purposes. **Users with disabilities have no fallback option and may face account bans.**

### Tested Compatible Games
* **Known Safe:** Many indie games, older titles, and games without anti-cheat
* **Proceed with Caution:** Games with Easy Anti-Cheat, BattlEye, or Kernel-mode AC systems may detect input scripts
* **Likely Unsafe:** Competitive online games (Valorant, Apex Legends, Fortnite, PUBG, etc.) — these typically ban all input remapping

**Before using Combo ReMapper with any new game:**
1. Check the game's official support for accessibility remapping tools
2. Review the anti-cheat policy documentation
3. Test on a non-ranked/non-competitive account if possible
4. Join the accessibility community to ask about others' experiences with that specific title

**We strongly recommend**: Always verify compatibility before relying on this tool in games that matter to you.

## 🛠️ System Requirements

* **OS:** Windows 10 / 11

* **AutoHotkey:** [AutoHotkey v2.0+](https://www.autohotkey.com/) installed (or running compiled executable)

* **Privileges:** Administrator privileges recommended when interacting with games running elevated (enabled by default).

## 🚀 Quick Start Guide

1. **Launch the Script:** Run `Combo_ReMapper.ahk` (or the compiled `.exe`).

2. **Add/Edit Combos:**

   * Enter a **Trigger Key** in the left field (e.g., `F1`, `RButton`, `J1`).

   * Enter your target key sequence in the **Holds/Executes keys** field, separated by commas (e.g., `shift,w` or `ctrl,c`).

   * Select a **Mode** (*Toggle*, *Hold*, *Press*, *Turbo*, or *TapHold*).

3. **Save Changes:** Click **Apply** to bind your new hotkeys and save state to the current profile.

4. **Panic Hotkey:** Press **`F8`** (default) at any time to instantly suspend/resume all script hotkeys and clear stuck inputs.

## 📖 Syntax & Special Tokens Guide

When writing combo sequences, you can use regular key names (`a`, `Space`, `LShift`, `RButton`) along with special action tokens:

### Delays & Timing

* `d150` or `150` — Sleep/pause for 150 milliseconds before executing the next key in the sequence.

### Mouse Actions

* `mlc` — Left Mouse Click

* `mrc` — Right Mouse Click

* `mmc` — Middle Mouse Click

* `mdown` — Press and hold Left Mouse Button

* `mup` — Release Left Mouse Button

* `mwd2` / `mwu2` — Scroll Mouse Wheel Down / Up ($N$ ticks)

* `m100,-50` — Instant relative mouse movement ($\Delta x=100$, $\Delta y=-50$)

* `mx400,300` — Absolute mouse movement to screen coordinate ($X=400$, $Y=300$)

* `mm200,0,500` — Smooth mouse movement ($\Delta x=200$, $\Delta y=0$ over $500\text{ ms}$)

* `mshake12,600` — Screen/camera shake effect ($12\text{ px}$ intensity for $600\text{ ms}$)

* `mh300,0` — Continuous mouse drift ($\Delta x=300\text{ px/sec}$) while held or toggled ON

### Gamepad Input Tokens

Gamepad triggers use the prefix `J` followed by the button number, or `JPOV` for D-Pad directions:

* `J1` through `J32` — Controller Buttons 1 through 32

* `JPOVU`, `JPOVD`, `JPOVL`, `JPOVR` — D-Pad Up, Down, Left, Right

## ⌨️ Default Global Hotkeys

| **Hotkey** | **Action** | 
| --- | --- |
| **`F6`** | Toggle Y-Axis Mouse Lock | 
| **`F7`** | Toggle OSD (On-Screen Display) Overlay | 
| **`F8`** | Panic Key (Master Suspend / Kill-switch) | 

## ⚙️ Configuration Files

Configuration and profile settings are automatically maintained in the script directory:

* `remapper_global.ini` — Global startup preferences (e.g., `RunAsAdmin`).

* `profiles/*.ini` — Profile-specific combo bindings, delays, and theme settings.

## 👤 Author & Acknowledgments

* **Author:** Dani

* **Note:** Created with assistance from AI (Claude by Anthropic) to streamline software development and improve accessibility options for gaming and computing.
