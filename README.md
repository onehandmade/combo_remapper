# Combo ReMapper 9.2

**Play and work with fewer keys, fewer fingers and less effort.**

Combo ReMapper is a remapper for keyboard, mouse and controller input, built for people who have limited use of their hands. One key press can do what normally takes several keys, a held key or a burst of fast repeats. Every game or program gets its own profile, and a built-in cheat sheet reminds you what each key does.

It is a single AutoHotkey v2 script. It has no installer and no extra files to set up.

---

## Contents

1. [What it does](#what-it-does)
2. [Who it is for](#who-it-is-for)
3. [What you need](#what-you-need)
4. [Quick start](#quick-start)
5. [How it works](#how-it-works)
6. [Modes](#modes)
7. [Combo words](#combo-words)
8. [Combo recipes](#combo-recipes)
9. [Profiles, pages and the cheat sheet](#profiles-pages-and-the-cheat-sheet)
10. [The setup wizard](#the-setup-wizard)
11. [Settings and customization](#settings-and-customization)
12. [Game compatibility](#game-compatibility)
13. [Default hotkeys](#default-hotkeys)
14. [Safety](#safety)
15. [Troubleshooting](#troubleshooting)
16. [Files the program uses](#files-the-program-uses)
17. [About](#about)

---

## What it does

Combo ReMapper sits between your input and the game. You press a **trigger** (a key, a mouse button or a controller button) and the program sends a **combo** for you. A combo can be as simple as one key or as long as a timed sequence of keys, clicks and mouse moves.

With it you can:

- **Replace key combinations with one key.** Shift and Space together, Ctrl and C, a dodge or a roll: one press.
- **Replace holding a key with a switch.** Press once to start walking or holding Shift, press again to stop.
- **Replace button-mashing and rapid clicking.** Press once to start a fast repeat, press again to stop.
- **Get more actions out of fewer keys.** A key can do one thing on a tap and another on a hold or a double tap, and pages let one key set stand in for several.
- **Run short sequences.** Keys, waits, clicks, scrolling and smooth mouse movement in a single combo.
- **Use a controller as a keyboard and mouse.** Buttons, the d-pad and sticks can trigger combos, and a stick can move the mouse.
- **Remember your keys.** A cheat sheet lists every key of a profile, and the setup wizard can build a first profile for you.

## Who it is for

Combo ReMapper is made for people who find standard keyboard, mouse and controller layouts hard to use, including:

- people who play with **one hand** (left or right) or only a few reachable keys;
- people with **limited hand or finger movement, tremor, pain or fatigue**, who benefit from fewer presses and less holding;
- people who find **key combinations**, holding several keys, or rapid pressing difficult or tiring;
- **carers, therapists and accessibility groups** who help set a game up for someone else;
- anyone who wants **fewer chorded keys** and more comfortable controls in a single-player game or an everyday program.

The program was written by a handicapped player for exactly this use, and every feature is meant to lower the physical effort of playing.

**What it is not for.** It is not meant for online or competitive games, where automation can break the rules and get accounts banned. See [Game compatibility](#game-compatibility).

---

## What you need

- Windows 10 or 11.
- [AutoHotkey v2](https://www.autohotkey.com/) (v2 only, not v1).
- The script `Combo_ReMapper_9_2.ahk`.

Run it as Administrator (the default) if the game runs as administrator.

## Quick start

1. Install AutoHotkey v2.
2. Put `Combo_ReMapper_9_2.ahk` in its own folder and double-click it. A tray icon appears.
3. On first start a welcome window offers the **setup wizard**. Press *Open the wizard*.
4. Answer the questions: which hand you use, a profile name, which program is the game, which keys the game already uses, and what you want one key to do.
5. Press **Create profile**, read the summary, and confirm.
6. Start the game, press **F1** to see your keys, and play. **F2** (left hand) or **F8** (right hand) turns everything off and on.

To use a ready-made profile, copy its `.ini` file into the `profiles` folder next to the script, then pick it in the main window or from **tray icon -> Switch Profile**.

## How it works

Each row in the main window is:

> **Trigger** → **Combo**, with a **Mode**

When you press the trigger, the program sends the combo to the game. Rows only react while the **Target program** is in front. Leave the target empty (or `(any)`) to react in every window.

| Part | What it is |
|---|---|
| **Trigger** | The key or mouse button you press. The **Set** button next to it listens for your next key press and fills it in. |
| **Combo** | What the program sends, as comma-separated words (see [Combo words](#combo-words)). The **Auto** button records the keys you press into the combo. |
| **Mode** | How the trigger behaves (see [Modes](#modes)). |
| **On** | The checkbox that switches a single row on or off. |

Right-click a row for more tools: test-fire it, set the repeat interval, insert mouse actions, duplicate or clear it.

## Modes

| Mode | What it does |
|---|---|
| **Hold** | Sends the combo while you hold the trigger, and lets go when you release. |
| **Toggle** | Press once to hold the keys down, press again to let go. |
| **Press** | One quick press of the combo each time. |
| **Turbo** | Repeats the combo quickly while you hold the trigger. |
| **TapHold** | A quick tap sends the first key, holding sends the second. |
| **DblTap** | Two quick presses (within 0.35 seconds) send the combo. |
| **TglTurbo** | Press once and the combo repeats by itself, press again to stop. Good for auto-click and auto-mash. |

## Combo words

Separate words with commas.

| Word | Meaning |
|---|---|
| `w`, `shift`, `space`, `f5` | Keys by name |
| `d150` or `150` | Wait 150 milliseconds (a single digit is a real key) |
| `mlc` `mrc` `mmc` | Left, right and middle click |
| `mdc` | Double click |
| `mdown` `mup` | Hold and release the left button |
| `mwd5` `mwu5` | Scroll down or up 5 notches |
| `m10,-5` | Move the mouse 10 right and 5 up (relative) |
| `mx400,300` | Move the mouse to screen position 400,300 |
| `mm200,0,500` | Smooth move: 200 px right over 500 ms |
| `mshake12,600` | Camera shake up to 12 px for 600 ms |
| `mwave0,30,600,15` | Waggle up and down 30 px every 15 ms for 600 ms |
| `mh300,0` | Steady move of 300 px per second while a Hold row is held or a Toggle row is on |
| `down:q` `up:q` | Hold a key (or a mouse button such as `lbutton`) across several steps, then let go |

## Combo recipes

Copy these into the combo box.

| I want | Combo |
|---|---|
| Shift and Space together | `down:lshift,d30,space,d40,up:lshift` |
| Hold a key for half a second | `down:e,d500,up:e` |
| Tap a key three times | `e,d60,e,d60,e` |
| Double click | `mdc` |
| Hold right click for 1 second | `down:rbutton,d1000,up:rbutton` |
| Ctrl and scroll (zoom) | `down:lctrl,mwd1,up:lctrl` |
| Copy / paste | `down:lctrl,c,up:lctrl` / `down:lctrl,v,up:lctrl` |
| Alt and Tab | `down:lalt,tab,d100,up:lalt` |
| Scroll, then click | `mwd3,d50,mlc` |
| Walk forward, then turn | `down:w,d1000,down:a,d200,up:a,up:w` |
| Drag with the mouse | `mx400,300,mdown,d50,mm200,0,500,mup` |
| Hold a key and wiggle the mouse | `down:lctrl,mwave0,30,600,15` |
| Hold a key and use the wheel | `down:q,mwd2,d40,mwu2,d40` |
| Auto-click | row mode **TglTurbo**, combo `mlc`, interval 20 |
| Auto-mash a key | row mode **TglTurbo**, combo `e`, interval 20 |
| Walk forever | row mode **Toggle**, combo `w` |

## Profiles, pages and the cheat sheet

**Profiles.** A profile is one set of rows plus its settings, saved as an `.ini` file in the `profiles` folder. Switch from the main window or the tray menu. **Auto-switch Profile by Game** changes profile for you when you switch to a game whose profile has that target program. **Export Profile** copies a profile to the clipboard and **Import** brings it back.

**Pages.** Each page is a profile. In **Settings -> Pages...** add profiles in the order you want, then choose a **Next-page key** and an optional **Previous-page key**. After the last page, Next goes back to the first. Held keys are let go on every switch. The status box and cheat sheet show which page you are on, such as "Page 2 of 4".

**Cheat sheet.** Set a cheat-sheet key in the same window (F1 in the ready-made profiles).
- First press: every key of the profile, and of all its pages, with a plain-language note on each.
- Second press: the same list with the exact combo each key sends.
- Third press: closes it.

Long lists are split into columns so everything fits. Rows get their notes from a `Note=` line in the profile file.

## The setup wizard

Open it from **tray icon -> Setup wizard...**. It builds a ready profile:

1. Pick your hand. It then chooses keys that hand reaches easily: for the left hand F, G, X, T, B and the number keys; for the right hand J, K, L, U, I, O, H, N, M and the number pad.
2. Name the profile and pick the game program from the list of open programs.
3. List the keys the game already uses. The wizard never takes those.
4. Tick what you want one key to do: walk forward, auto-click, auto-press a key, hold Shift, hold Ctrl, or Shift + Space together.

The **What does everything do?** button explains every question and button, and each box has a hover tip. Before saving, it shows exactly what it will make and asks you to confirm.

## Settings and customization

Open **Settings** from the tray icon.

| Where | What you can change |
|---|---|
| **Settings** | Input mode, startup and display options, the scroll-click key and the Y-axis lock key. (The panic key is in the main window.) |
| **Settings -> Pages...** | Next-page key, previous-page key, the list of pages, and the cheat-sheet key. |
| **Settings -> Controller...** | Controller type and stick settings. The controller is off by default. |
| **Settings -> Customize...** | Status box: text size, see-through level, background color. Cheat sheet: text size, how long it stays up, colors, position. |
| **Advanced Settings** | Key and mouse timing, **Auto-detect (sec)** (how long Auto, Set and Bind listen, 3 to 120), "let go of everything when the game loses focus", Run as Administrator, writing the log file, and colors and theme. |

Input modes (**Game**, **Classic**, **Hybrid**) change how keys are sent. If a game ignores the keys, try another mode (also in the tray menu).

Hover over a setting in the Settings window for a short explanation. **Help...** in the tray menu has the full reference inside the program.

## Game compatibility

Combo ReMapper works by sending input to the game, the same way a keyboard or mouse does. Whether a game accepts it depends on the game and, for online games, on its anti-cheat.

### Compatibility list

Games and programs the author has used it with:

| Game / platform | Status | Notes |
|---|---|---|
| PCSX2 emulator | ✅ Working | Fully compatible |
| GTA San Andreas | ✅ Working | Fully compatible |
| No More Heroes | ✅ Working | Fully compatible |
| VRChat | ✅ Working | Fully compatible |
| My Hero Ultra Rumble | ✅ Working | Fully compatible |
| Lollipop Chainsaw RePop | ✅ Working | Fully compatible |

This list comes from the author's own use. Test your own game before you rely on it.

### Anti-cheat

Input scripts are treated differently by every game's anti-cheat, and some games ban remapping tools even when they are used for accessibility.

- Many indie games, older titles and games without anti-cheat are usually fine.
- Games with Easy Anti-Cheat, BattlEye or kernel-mode anti-cheat may detect the script.
- Competitive online games such as Valorant, Apex Legends, Fortnite and PUBG typically ban all input remapping.

Before you use it with a new game:

1. Check whether the game officially supports accessibility remapping tools.
2. Read the game's anti-cheat policy.
3. Test on a non-ranked or non-competitive account if you can.
4. Ask the accessibility community about that title.

### If a game ignores the keys

- Try another **input mode** (Game, Classic or Hybrid) in Settings or the tray menu.
- Run the program as **Administrator** if the game or emulator runs as administrator.
- Raise **Extra press time** in Settings if short taps are missed.
- Check that the **Target program** name is the game's real program name.

## Default hotkeys

| Hotkey | Action |
|---|---|
| `F6` | Toggle the Y-axis mouse lock |
| `F7` | Show or hide the status box |
| `F8` | Panic: turn the remapper off and on, and let go of every held key |

You can change all three in Settings. The ready-made left-hand profiles use `F2` for panic and `F1` for the cheat sheet.

---

## Safety

- **Panic key.** Turns the whole remapper off and on at once and lets go of every held key. Default F8, and F2 in the ready-made left-hand profiles. It can't be left blank.
- **Focus-loss release.** When you switch away from the game (Alt+Tab, crash, minimize), held keys, toggles and auto-repeats are stopped so nothing stays stuck. This needs a Target program, and you can switch it off in Advanced Settings.
- **Exit.** Closing the program lets go of every key it was holding.
- **Check Combos** (tray menu) looks for typos and mistakes in your rows.
- **Single-player use.** Don't use it in online or competitive games.

## Troubleshooting

| Problem | What to try |
|---|---|
| Keys do nothing in the game | Check the **Target program** name in Task Manager, run the program as Administrator, or try another input mode. |
| A key does nothing at all | Another row, the panic key or another hotkey may already use it. **Check Combos** will tell you. |
| Timed prompts or short taps are missed | Raise **Extra press time** in Settings. |
| A held key got stuck | Press the panic key. |
| The wizard doesn't appear | Open it from the tray menu. It stops appearing at start after you press **Don't ask again**. |
| Something broke | Tray menu -> **Copy diagnostics**, then paste the result when you ask for help. |

The program writes errors and what fired to `combo_remapper.log` next to the script (switch this on or off in Advanced Settings). Tray menu -> **Open log file** shows it.

## Files the program uses

| File or folder | Purpose |
|---|---|
| `Combo_ReMapper_9_2.ahk` | The program. |
| `profiles\` | One `.ini` file per profile or page. |
| `remapper_global.ini` | Program-wide settings such as the look, Run as Administrator and logging. |
| `combo_remapper.log` | Errors and what fired. Starts a new file after about 250 KB. |

## About

Made by **Dani**.

Dani is handicapped, and makes these tools so that games and programs are easier to play and use, for Dani and for others.

This program was written with the help of AI (Claude, made by Anthropic). Dani came up with the idea and decided how it works and what it should do; the AI wrote the code. This is said openly so that people know how the software was made and where to report a problem if it breaks.
