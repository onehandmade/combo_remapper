# Combo ReMapper 9.5

**Play and work with fewer keys, fewer fingers and less effort.**

Combo ReMapper is a remapper for keyboard, mouse and controller input, built for people who have limited use of their hands. One key press can do what normally takes several keys, a held key or a burst of fast repeats. Every game or program gets its own profile, and a built-in cheat sheet reminds you what each key does.

It is a single AutoHotkey v2 script. It has no installer and no extra files to set up.

> ## ⚠️ AI WARNING — PLEASE READ FIRST
>
> **This software was written with AI.** The code was written by an AI (Claude, made by Anthropic). The author, Dani, had the idea, decided how the program should work, tested it on their own games and directed every change. The AI wrote the code.
>
> We say this openly because many people don't want AI-made software, and that is a fair choice. If you would rather not use an AI project, please don't. There are no hard feelings.
>
> **What that means for you:**
> - **It has not been professionally reviewed or audited.** Treat it as a hobby project made for accessibility.
> - **It can have bugs**, including ones nobody has found yet. Some features were written without being run before release.
> - **You can read all of it.** It is one plain-text script. Read it, or have someone you trust read it, before you run it.
> - **Scan it with your own antivirus** like any download. Remapping tools can trigger false alarms.
> - **No warranty.** Use it at your own risk. Don't use it in online or competitive games, where it can get your account banned.
> - **If it breaks,** report it. Tray menu -> More -> *Copy diagnostics* gives the details to paste into an issue.


### Watch the demos

**[Demo playlist on YouTube](https://youtube.com/playlist?list=PLdhGZ74KtEfI)**: videos of the program in use. Watching a demo first is the quickest way to see what it does.

---

## Contents

1. [Demo videos](#watch-the-demos)
2. [What it does](#what-it-does)
3. [Who it is for](#who-it-is-for)
4. [What you need](#what-you-need)
5. [Quick start](#quick-start)
6. [How it works](#how-it-works)
7. [Modes](#modes)
8. [Combo words](#combo-words)
9. [Combo recipes](#combo-recipes)
10. [Profiles, pages and the cheat sheet](#profiles-pages-and-the-cheat-sheet)
11. [The setup wizard](#the-setup-wizard)
12. [Settings and customization](#settings-and-customization)
13. [Quick time events](#quick-time-events)
14. [Accessibility tools](#accessibility-tools)
15. [Game compatibility](#game-compatibility) (including emulators)
16. [Default hotkeys](#default-hotkeys)
17. [Safety](#safety)
18. [Troubleshooting](#troubleshooting)
19. [Files the program uses](#files-the-program-uses)
20. [About](#about)

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
- The script `Combo_ReMapper_9_5.ahk`.

Run it as Administrator (the default) if the game runs as administrator.

## Quick start

1. Install AutoHotkey v2.
2. Put `Combo_ReMapper_9_5.ahk` in its own folder and double-click it. A tray icon appears.
3. On first start a welcome window offers the **setup wizard**. Press *Open the wizard*.
4. Answer the questions: which hand you use, a profile name, which program is the game, which keys the game already uses, and what you want one key to do.
5. Press **Create profile**, read the summary, and confirm.
6. Start the game, press **F1** to see your keys, and play. **F2** (left hand) or **F8** (right hand) turns everything off and on.

To use a ready-made profile, copy its `.ini` file into the `profiles` folder next to the script, then pick it in the main window or from **tray icon -> Switch profile**.

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
| `burst:x,30,40` | Press `x` 30 times, 40 ms apart (a one-key button mash) |
| `alt:x/c,30,40` | Alternate `x` and `c` 30 times (a left/right mash) |
| `hold:x,800` | Hold `x` for 800 ms, then let go |

`burst`, `alt` and `hold` work in the Press, Turbo, TglTurbo and DblTap modes.

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
| **Settings -> Accessibility tools...** | Window key, tremor filter, keyboard mouse and one-button control (see [Accessibility tools](#accessibility-tools)). |
| **Settings -> Customize...** | Status box: text size, see-through level, background color, and whether it shows the row's name when a row fires (and for how long). Cheat sheet: text size, how long it stays up, colors, position. |
| **Advanced Settings** | Key and mouse timing, **Auto-detect (sec)** (how long Auto, Set and Bind listen, 3 to 120), "let go of everything when the game loses focus", Run as Administrator, writing the log file, and colors and theme. |

Input modes (**Game**, **Classic**, **Hybrid**) change how keys are sent. If a game ignores the keys, try another mode (also in the tray menu).

Hover over a setting in the Settings window for a short explanation. **Help...** in the tray menu has the full reference inside the program.

## Quick time events

Quick time events (timed button prompts) are hard when you need fast, exact presses. These helpers make them easier without reading the screen. Use one key per button and press only the key for the button the prompt shows, because a wrong button can end some mini-games.

| Prompt | Row mode | Combo | What happens |
|---|---|---|---|
| Mash a button | **Press** | `burst:x,30,40` | One press sends 30 presses of `x`, 40 ms apart (about 1.2 seconds), then stops |
| Mash left and right | **Press** | `alt:x/c,30,40` | One press alternates `x` and `c` 30 times |
| Hold a button | **Press** | `hold:x,1000` | One press holds `x` for 1 second, then lets go |
| Mash for as long as it takes | **TglTurbo** | `x` | Press once to start, press again to stop |
| Mash while you hold the key | **Turbo** | `x` | Repeats only while you hold the trigger |

- The **panic key** stops a burst at once.
- The setup wizard can make these rows for you (tick the mash, alternate and hold options).
- A ready-made profile, `QTE helper (RPCS3 face buttons)`, comes with the program: the four face buttons on the keys 1 to 4, plus an alternate mash, a hold and two keep-mashing keys. Copy its `.ini` file into the `profiles` folder. It uses the PlayStation-style layout of V, X, B and C from the RPCS3 emulator; change the letters to match your game.
- Burst length and speed are in the combo: change `30` (how many) and `40` (milliseconds apart).

## Accessibility tools

Open **Settings -> Accessibility tools...** (or the tray menu). The settings are kept for the whole program, not per profile.

### Edit while in the game

Press the **window key** (default `F12`) to bring the Combo ReMapper window in front of the game, and press it again to hide it and return to the game. Double-clicking the tray icon does the same.

- While the window is in front, the row keys are switched off, so you can type into the boxes without anything firing. They switch back on when you return to the game.
- **Keep it on top of the game while it is open** can be turned off in the same window.
- The game must run in windowed or borderless mode. A game in exclusive fullscreen can hide any window.
- Switching away from the game also lets go of held keys and toggles, so nothing stays stuck while you edit (this is the focus-loss safety setting, and it needs a Target program).
- Closing the window with the X still exits the program. Use the window key to hide it instead.

### Tremor filter

Helps if your hand shakes or you press keys by accident.

- **Ignore a repeat press within (ms).** After a press is accepted, another press of the same trigger inside this time is ignored. Try 150 to 400. 0 is off.
- **Key must be held for (ms).** A press only counts if you keep the key down this long. 0 is off.

It does not apply to **DblTap** rows, because those need two quick presses.

### Keyboard mouse

Moves the cursor and clicks with the keyboard, for when using a mouse is hard. Turn it on and off with its own key (default `F11`) or the tray menu item **More -> Keyboard mouse on / off**.

| Action | Default key |
|---|---|
| Move up / left / down / right | `E` / `S` / `D` / `F` |
| Left / right / middle click | `Q` / `W` / `R` |
| Scroll up / down | `T` / `G` |

- You can hold a click key to drag.
- The cursor speeds up the longer you hold a movement key (switch this off in the window). **Speed** is in pixels per second.
- The keys only act while the keyboard mouse is ON. The **panic key** turns it off at once.
- Change any key with its **Bind** button. A key left empty is not used.

### One-button control

One key steps through your actions, so a single switch or button is enough.

1. Press the switch key. A list of this profile's actions appears on screen.
2. **Automatic mode:** the highlight moves down the list by itself. Press the key when the action you want is highlighted.
   **Step mode:** tap the key to move to the next action, hold it for about 0.7 seconds to choose.
3. The chosen action runs as if you had pressed its own key.

It works best with **Press**, **Toggle** and **TglTurbo** rows. The list shows each row's note, then its mode. It closes by itself if nothing is chosen. Set the speed in milliseconds per step. Tray menu item: **One-button control menu**.

### Row notes

Right-click a row and choose **Edit Row Note...** to give it a plain-language name, such as "Walk forward". Notes appear in the cheat sheet, in one-button control and in the status box: when a row fires, the status box flashes its note (with ON or OFF for toggles and auto-repeats). A row without a note shows the usual message, such as the key and what it sends. You can switch that off or change how long it shows in **Settings -> Customize...**. Press **Apply** to save the profile.

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

### Emulators and console games

Emulators run on your computer and read the keyboard, mouse and controllers like any other program, so Combo ReMapper can control them in the same way. This is how it is used with PCSX2 (see the list above).

- **Controller layouts.** The program has a **PS4 pad** setting and a starter profile that maps a PS4 pad to keyboard and mouse. Switch it on in **Settings -> Controller...** (it is off by default).
- **Use the emulator's own controls first.** Most emulators have a built-in key and controller mapping screen. Use Combo ReMapper for what that screen can't do: turn a combo into one key, hold something for you, or repeat fast.
- **Only the emulators listed above have been tested.** PS4 emulators and other newer emulators haven't been tested yet, so test yours and expect to adjust the **Target program** name and the **input mode**.
- **Games you own.** Use it only with games and emulators you are allowed to use, and follow the rules of the emulator and the game.

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

- Try another **input mode** (Game, Classic or Hybrid) in Settings or the tray menu (More -> Input mode).
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
- **Check combos** (tray menu, More) looks for typos and mistakes in your rows.
- **Single-player use.** Don't use it in online or competitive games.

## Troubleshooting

| Problem | What to try |
|---|---|
| The program does nothing, or only shows a tray icon (often on another computer) | 1. Make sure it is **AutoHotkey v2** (not v1) and that the script is in a normal folder, not inside a zip. 2. Accept the Windows prompt (UAC) when it asks for administrator rights; if you can't, start it with `/noadmin` or set `RunAsAdmin=0` in `remapper_global.ini`. 3. If a *startup problem* window appears, send its text. 4. Check that your antivirus has not blocked it. |
| Keys do nothing in the game | Check the **Target program** name in Task Manager, run the program as Administrator, or try another input mode. |
| A key does nothing at all | Another row, the panic key or another hotkey may already use it. **Check Combos** will tell you. |
| Timed prompts or short taps are missed | Raise **Extra press time** in Settings. |
| A held key got stuck | Press the panic key. |
| The wizard doesn't appear | Open it from the tray menu. It stops appearing at start after you press **Don't ask again**. |
| Something broke | Tray menu -> More -> **Copy diagnostics**, then paste the result when you ask for help. |

The program writes errors and what fired to `combo_remapper.log` next to the script (switch this on or off in Advanced Settings). Tray menu -> More -> **Open log file** shows it.

## Files the program uses

| File or folder | Purpose |
|---|---|
| `Combo_ReMapper_9_5.ahk` | The program. |
| `profiles\` | One `.ini` file per profile or page. |
| `remapper_global.ini` | Program-wide settings such as the look, Run as Administrator and logging. |
| `combo_remapper.log` | Errors and what fired. Starts a new file after about 250 KB. |

If the script's own folder can't be written to (for example Program Files, or a protected folder), the program keeps these files in `%AppData%\ComboReMapper` instead and copies your existing profiles there.

## About

Made by **Dani**.

Dani is handicapped, and makes these tools so that games and programs are easier to play and use, for Dani and for others.

This program was written with the help of AI (Claude, made by Anthropic). Dani came up with the idea and decided how it works and what it should do; the AI wrote the code. This is said openly so that people know how the software was made and where to report a problem if it breaks.
