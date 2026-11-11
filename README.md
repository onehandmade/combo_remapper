# Combo ReMapper 9.7

**Play and work with fewer keys, fewer fingers and less effort.**

Combo ReMapper is a remapper for keyboard, mouse and controller input, built for people who have limited use of their hands. One key press can do what normally takes several keys, a held key or a burst of fast repeats. Every game or program gets its own profile, and a built-in cheat sheet reminds you what each key does.

It is a single AutoHotkey v2 script. It has no installer and no extra files to set up. The program speaks **English and Hungarian**, and you can add your own language.

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

> ## ℹ️ JUST A FUN PROJECT
>
> Combo ReMapper has two hidden colour themes, **Cyber Red** and **Cyber Yellow**. This is just a fun project. It is **not affiliated with, sponsored by or endorsed by any company or brand**. See [Hidden themes](#hidden-themes).

**Language / Nyelv:** English (this part) | [Magyar](#combo-remapper-97--magyar)

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
13. [Languages](#languages)
14. [Quick time events](#quick-time-events)
15. [Accessibility tools](#accessibility-tools)
16. [Game compatibility](#game-compatibility) (including emulators)
17. [Default hotkeys](#default-hotkeys)
18. [Safety](#safety)
19. [Troubleshooting](#troubleshooting)
20. [Files the program uses](#files-the-program-uses)
21. [Hidden themes](#hidden-themes)
22. [What's new in 9.7](#whats-new-in-97)
23. [About](#about)

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
- The script `Combo_ReMapper_9_7.ahk`.

Run it as Administrator (the default) if the game runs as administrator.

## Quick start

1. Install AutoHotkey v2.
2. Put `Combo_ReMapper_9_7.ahk` in its own folder and double-click it. A tray icon appears.
3. On first start a welcome window offers the **setup wizard**. Press *Open the wizard*.
4. Answer the questions: which hand you use, a profile name, which program is the game, which keys the game already uses, and what you want one key to do.
5. Press **Create profile**, read the summary, and confirm.
6. Start the game, press **F1** to see your keys, and play. **F2** (left hand) or **F8** (right hand) turns everything off and on.

To use a ready-made profile, copy its `.ini` file into the `profiles` folder next to the script, then pick it in the main window or from **tray icon -> Switch profile**.

To use the program in Hungarian, see [Languages](#languages).

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
| **Settings** | Input mode, language, startup (**Auto-Start with Windows Startup** applies at once and starts the program at logon, with administrator rights and no UAC prompt when it can) and display options, the scroll-click key and the Y-axis lock key. (The panic key is in the main window.) |
| **Settings -> Pages...** | Next-page key, previous-page key, the list of pages, and the cheat-sheet key. |
| **Settings -> Controller...** | Controller type and stick settings. The controller is off by default. |
| **Settings -> Accessibility tools...** | Window key, tremor filter, keyboard mouse and one-button control (see [Accessibility tools](#accessibility-tools)). |
| **Settings -> Customize...** | Status box: text size, see-through level, background color, and whether it shows the row's name when a row fires (and for how long). Cheat sheet: text size, how long it stays up, colors, position. |
| **Advanced Settings** | Key and mouse timing, **Auto-detect (sec)** (how long Auto, Set and Bind listen, 3 to 120), "let go of everything when the game loses focus", Run as Administrator, writing the log file, and colors and theme. |

Input modes (**Game**, **Classic**, **Hybrid**) change how keys are sent. If a game ignores the keys, try another mode (also in the tray menu).

Hover over a setting in the Settings window for a short explanation. **Help...** in the tray menu has the full reference inside the program.

## Languages

The program comes in **English** and **Magyar (Hungarian)**. This includes the menus, windows, hover tips, the Help window, the wizard, the mode names and the About window. You can add as many more languages as you like.

- Pick the language in **Settings** (the Language drop-down) or from the **tray menu** (More -> Language). The program offers to restart so the new language applies everywhere.
- **Make your own language.** In Settings press **Export template**. This writes `lang\template.po` with every English text in the program. Translate it (each `msgid` is the English text, each `msgstr` is your translation), and put `# Language: Your language name` on a comment line at the top. Leave a `msgstr` empty to keep the English text.
- **Add language files.** In Settings press **Add language file...** (also in the tray menu under Language), and pick one or **several** `.po` files at once. They are copied into the `lang` folder and appear in the language list straight away. The program then offers to switch to the language and restart. You can also copy `.po` files into the `lang` folder yourself (press **Open folder** to find it), for example `lang\de.po`.
- Every `.po` file in the `lang` folder is its own language, so people can share files and you can keep as many as you want. If a file has the same name as a built-in language, it overrides that language's texts.
- Share your translation by opening an issue or a pull request, and it can be added to the program.

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

**The status box** (F7 shows or hides it) shows *REMAPPER: ACTIVE* or *REMAPPER: DISABLED*. Under that line it lists everything that is running by itself, one line each: a dot (●) for a Toggle row that is on, and a double arrow (») for a Turbo or TglTurbo row that is repeating. Each line shows the row's note, or the key and what it sends if it has no note. When a row fires, the box also flashes its name for a moment. You can switch the list off in **Settings -> Customize...** (*List running toggles and turbos in the status box*).

---

## Safety

- **Panic key.** Turns the whole remapper off and on at once and lets go of every held key. Default F8, and F2 in the ready-made left-hand profiles. It can't be left blank.
- **Focus-loss release.** When you switch away from the game (Alt+Tab, crash, minimize), held keys, toggles and auto-repeats are stopped so nothing stays stuck. This needs a Target program, and you can switch it off in Advanced Settings.
- **Stuck-modifier release.** If Windows thinks Ctrl, Shift, Alt or the middle mouse button is down while your fingers are not on it and the program is holding nothing, the program lets it go after a short moment and writes a line to the log. A stuck Ctrl or middle button is what makes a normal click open a link in a new tab.
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
| A normal left click opens links in a new tab (for example in Chrome) | A Ctrl, Shift or middle button is probably stuck. Press the panic key. Since version 9.6 the program also lets go of stuck modifiers by itself after a moment. If it still happens, use tray menu -> More -> **Copy diagnostics** while it is happening and paste the result in an issue. |
| The wizard doesn't appear | Open it from the tray menu. It stops appearing at start after you press **Don't ask again**. |
| The program is in the wrong language | Pick the language in Settings or the tray menu. |
| Something broke | Tray menu -> More -> **Copy diagnostics**, then paste the result when you ask for help. |

The program writes errors and what fired to `combo_remapper.log` next to the script (switch this on or off in Advanced Settings). Tray menu -> More -> **Open log file** shows it.

## Files the program uses

| File or folder | Purpose |
|---|---|
| `Combo_ReMapper_9_7.ahk` | The program. |
| `profiles\` | One `.ini` file per profile or page. |
| `lang\` | Extra languages as `.po` files, and the exported template. |
| `remapper_global.ini` | Program-wide settings such as the language, the look, Run as Administrator and logging. |
| `combo_remapper.log` | Errors and what fired. Starts a new file after about 250 KB. |

If the script's own folder can't be written to (for example Program Files, or a protected folder), the program keeps these files in `%AppData%\ComboReMapper` instead and copies your existing profiles there.

## Hidden themes

Combo ReMapper has two secret colour themes. Each one is unlocked by winning a small on-screen puzzle, the **cyber deck**. It only needs the mouse, and nothing has to be held down.

| Theme | Look | How to unlock it |
|---|---|---|
| **Cyber Red** | Near-black background, warm off-white text, red, orange and blue accents | Open **Settings** and click the ⚡ at the bottom left. Win a 5-step pattern. |
| **Cyber Yellow** | Dark violet background, neon yellow text, cyan and pink accents | Open **Advanced Settings** and click the ◈ next to **Done**. Win a 6-step pattern. |

**The cyber deck.** A small window opens with four large buttons. They light up in a random pattern while it says WATCH. When it says REPEAT, click the same buttons in the same order. A wrong button gives ACCESS DENIED and a new pattern, and **REPLAY** shows the pattern again. When you win, a short boot animation plays and the theme turns on. After that the theme stays in the theme list of the main window, even after a restart.

While a cyber theme is on, the status box reads *CYBER MODE: ON* or *CYBER MODE: OFF*, in the theme's colors, and the labels flash for a split second every few seconds.

> **Just a fun project.** The themes are not affiliated with, sponsored by or endorsed by any company or brand.

## What's new in 9.7

- **Fixed:** the on/off switch. Turning the remapper off (panic key, Apply, losing focus) could stop halfway and leave the status box on ACTIVE and keys held. It now always finishes.
- **Fixed:** a startup error ("Parameter #1 invalid") when the `profiles` folder had other profiles but no `default` one, for example after moving the program to a new folder. It now opens the first profile it finds.
- **Fixed:** the setup wizard's confirmation window opened behind the wizard and could not be reached. All dialogs now appear in front.
- **Fixed:** **Auto-Start with Windows Startup** did not work reliably. It now starts AutoHotkey with the script explicitly, uses a scheduled task (no UAC prompt at each start) when the program runs as administrator, and tells you what it did.
- **New:** the status box lists every running toggle and turbo, and **Settings -> Customize...** has a check box to turn that list off.
- **New:** the two hidden themes are now **Cyber Red** and **Cyber Yellow**, and the status box says *CYBER MODE* while one is on.
- **New:** **Add language file...** adds one or several `.po` translation files at once.
- **Translation:** every text in the program is now in the Hungarian file and in the exported template.

## About

Made by **Dani**.

Dani is handicapped, and makes these tools so that games and programs are easier to play and use, for Dani and for others.

This program was written with the help of AI (Claude, made by Anthropic). Dani came up with the idea and decided how it works and what it should do; the AI wrote the code. This is said openly so that people know how the software was made and where to report a problem if it breaks.

---

# Combo ReMapper 9.7 – Magyar

**Játssz és dolgozz kevesebb billentyűvel, kevesebb ujjal és kevesebb erőfeszítéssel.**

A Combo ReMapper egy billentyűzet-, egér- és kontrollerbemenet-átalakító olyan emberek számára, akik korlátozottan tudják használni a kezüket. Egyetlen billentyűleütés elvégezheti azt, amihez általában több billentyű, egy lenyomva tartott billentyű vagy gyors ismétlések sorozata kell. Minden játék vagy program saját profilt kap, és egy beépített puskalap emlékeztet rá, melyik billentyű mit csinál.

Egyetlen AutoHotkey v2 szkript. Nincs telepítője, és semmilyen további fájlt nem kell beállítani. A program **angolul és magyarul** beszél, és saját nyelvet is hozzáadhatsz.

> ## ⚠️ MESTERSÉGES INTELLIGENCIA FIGYELMEZTETÉS – OLVASD EL ELŐSZÖR
>
> **Ez a szoftver mesterséges intelligenciával készült.** A kódot egy MI (a Claude, az Anthropic terméke) írta. A szerző, Dani, találta ki az ötletet, eldöntötte, hogyan működjön a program, kipróbálta a saját játékain, és irányította minden változtatást. A kódot az MI írta.
>
> Ezt nyíltan kimondjuk, mert sokan nem szeretnének MI-vel készült szoftvert használni, és ez tisztességes döntés. Ha inkább nem használnál MI-projektet, ne tedd. Nincs harag.
>
> **Mit jelent ez neked:**
> - **Nem ellenőrizte és nem auditálta szakember.** Kezeld hobbiprojektként, amely a hozzáférhetőségért készült.
> - **Lehetnek benne hibák**, olyanok is, amelyeket még senki nem talált meg. Néhány funkciót a kiadás előtt nem futtattak le.
> - **Az egészet elolvashatod.** Egyetlen egyszerű szöveges szkript. Olvasd el, vagy kérj meg valakit, akiben megbízol, mielőtt futtatod.
> - **Vizsgáld meg a saját vírusirtóddal**, mint minden letöltést. Az átalakító eszközök téves riasztást válthatnak ki.
> - **Nincs garancia.** Saját felelősségedre használd. Ne használd online vagy versenyjátékokban, mert a fiókodat kitilthatják.
> - **Ha elromlik,** jelezd. Tálcamenü -> Több -> *Diagnosztika másolása* megadja a részleteket, amelyeket beilleszthetsz egy hibajelentésbe.

> ## ℹ️ CSAK EGY SZÓRAKOZTATÓ PROJEKT
>
> A Combo ReMapper-ben két rejtett színtéma van, a **Cyber Red** és a **Cyber Yellow**. Ez csak egy szórakoztató projekt. **Semmilyen céggel vagy márkával nem áll kapcsolatban, egyikük sem szponzorálja vagy támogatja.** Lásd: [Rejtett témák](#rejtett-témák).

**Language / Nyelv:** [English](#combo-remapper-97) | Magyar (ez a rész)

### Nézd meg a bemutatókat

**[Bemutató lejátszási lista a YouTube-on](https://youtube.com/playlist?list=PLdhGZ74KtEfI)**: videók a program használatáról. A legegyszerűbb módja annak, hogy megértsd, mit tud, ha először megnézel egyet.

---

## Tartalom

1. [Bemutató videók](#nézd-meg-a-bemutatókat)
2. [Mit csinál](#mit-csinál)
3. [Kinek készült](#kinek-készült)
4. [Mire van szükséged](#mire-van-szükséged)
5. [Gyors kezdés](#gyors-kezdés)
6. [Hogyan működik](#hogyan-működik)
7. [Módok](#módok)
8. [Kombószavak](#kombószavak)
9. [Kombóreceptek](#kombóreceptek)
10. [Profilok, lapok és a puskalap](#profilok-lapok-és-a-puskalap)
11. [A beállítási varázsló](#a-beállítási-varázsló)
12. [Beállítások és testreszabás](#beállítások-és-testreszabás)
13. [Nyelvek](#nyelvek)
14. [Quick time eventek](#quick-time-eventek)
15. [Kisegítő eszközök](#kisegítő-eszközök)
16. [Játékkompatibilitás](#játékkompatibilitás)
17. [Alapértelmezett gyorsbillentyűk](#alapértelmezett-gyorsbillentyűk)
18. [Biztonság](#biztonság)
19. [Hibaelhárítás](#hibaelhárítás)
20. [A program által használt fájlok](#a-program-által-használt-fájlok)
21. [Rejtett témák](#rejtett-témák)
22. [Újdonságok a 9.7-ben](#újdonságok-a-97-ben)
23. [Névjegy](#névjegy)

---

## Mit csinál

A Combo ReMapper a bemeneted és a játék közé ül. Megnyomsz egy **kiváltót** (billentyűt, egérgombot vagy kontrollergombot), a program pedig elküld helyetted egy **kombót**. Egy kombó lehet egyetlen billentyű, vagy billentyűk, kattintások és egérmozgások hosszú, időzített sorozata.

Mire jó:

- **Billentyűkombinációk helyett egy billentyű.** Shift és Szóköz együtt, Ctrl és C, egy kitérés vagy gurulás: egy leütés.
- **A billentyű nyomva tartása helyett kapcsoló.** Egyszer megnyomod, hogy elinduljon a séta vagy a Shift tartása, még egyszer, hogy leálljon.
- **A gombnyomkodás és a gyors kattintgatás helyett egy leütés.** Egyszer megnyomod, hogy elinduljon a gyors ismétlés, még egyszer, hogy leálljon.
- **Több művelet kevesebb billentyűvel.** Egy billentyű koppintásra egyet, tartásra vagy dupla koppintásra mást csinálhat, a lapokkal pedig egy billentyűkészlet többet is helyettesíthet.
- **Rövid sorozatok futtatása.** Billentyűk, várakozások, kattintások, görgetés és sima egérmozgás egyetlen kombóban.
- **Kontroller használata billentyűzetként és egérként.** A gombok, az irányok és a karok kombókat válthatnak ki, és egy kar mozgathatja az egeret.
- **A billentyűid megjegyzése.** A puskalap felsorolja egy profil minden billentyűjét, a beállítási varázsló pedig elkészíti az első profilodat.

## Kinek készült

A Combo ReMapper azoknak készült, akiknek nehéz a szokásos billentyűzet-, egér- és kontrollerkiosztás, például:

- azoknak, akik **egy kézzel** (balral vagy jobbal) vagy csak néhány elérhető billentyűvel játszanak;
- azoknak, akiknek **korlátozott a kéz- vagy ujjmozgásuk, remegnek, fájdalmuk van vagy fáradékonyak**, és előnyös számukra a kevesebb leütés és a kevesebb tartás;
- azoknak, akiknek **a billentyűkombinációk**, több billentyű együttes nyomva tartása vagy a gyors nyomkodás nehéz vagy fárasztó;
- **gondozóknak, terapeutáknak és hozzáférhetőségi csoportoknak**, akik valaki másnak segítenek beállítani egy játékot;
- mindenkinek, aki **kevesebb egyszerre nyomott billentyűt** és kényelmesebb vezérlést szeretne egy egyjátékos játékban vagy egy mindennapi programban.

A programot egy mozgássérült játékos írta pontosan erre a célra, és minden funkció célja a játék fizikai megterhelésének csökkentése.

**Mire nem való.** Nem online vagy versenyjátékokhoz készült, ahol az automatizálás megszegheti a szabályokat, és a fiókokat kitilthatják. Lásd: [Játékkompatibilitás](#játékkompatibilitás).

---

## Mire van szükséged

- Windows 10 vagy 11.
- [AutoHotkey v2](https://www.autohotkey.com/) (csak v2, a v1 nem jó).
- A `Combo_ReMapper_9_7.ahk` szkript.

Futtasd rendszergazdaként (ez az alapértelmezés), ha a játék rendszergazdaként fut.

## Gyors kezdés

1. Telepítsd az AutoHotkey v2-t.
2. Tedd a `Combo_ReMapper_9_7.ahk` fájlt egy saját mappába, és kattints rá duplán. Megjelenik egy tálcaikon.
3. Az első indításkor egy üdvözlőablak felajánlja a **beállítási varázslót**. Nyomd meg a *Varázsló megnyitása* gombot.
4. Válaszolj a kérdésekre: melyik kezedet használod, mi legyen a profil neve, melyik program a játék, mely billentyűket használja már a játék, és mit szeretnél, hogy egy billentyű csináljon.
5. Nyomd meg a **Profil létrehozása** gombot, olvasd el az összefoglalót, és erősítsd meg.
6. Indítsd el a játékot, nyomd meg az **F1** billentyűt a billentyűid megtekintéséhez, és játssz. Az **F2** (bal kéz) vagy az **F8** (jobb kéz) mindent ki- és bekapcsol.

Kész profil használatához másold az `.ini` fájlját a szkript melletti `profiles` mappába, majd válaszd ki a főablakban vagy a **tálcaikon -> Profilváltás** menüben.

A program magyar nyelvű használatához lásd: [Nyelvek](#nyelvek).

## Hogyan működik

A főablak minden sora:

> **Kiváltó** → **Kombó**, egy **Móddal**

Amikor megnyomod a kiváltót, a program elküldi a kombót a játéknak. A sorok csak akkor reagálnak, amikor a **Célprogram** van előtérben. Hagyd üresen a célprogramot (vagy írd be: `(any)`), hogy minden ablakban reagáljanak.

| Rész | Mi ez |
|---|---|
| **Kiváltó** | A billentyű vagy egérgomb, amelyet megnyomsz. A mellette lévő **Vál.** gomb figyeli a következő leütésedet, és beírja. |
| **Kombó** | Amit a program elküld, vesszővel elválasztott szavakként (lásd: [Kombószavak](#kombószavak)). Az **Auto** gomb a lenyomott billentyűidet rögzíti a kombóba. |
| **Mód** | Hogyan viselkedik a kiváltó (lásd: [Módok](#módok)). |
| **Be** | A jelölőnégyzet, amely egyetlen sort kapcsol be vagy ki. |

Kattints jobb gombbal egy sorra további eszközökért: próbaindítás, az ismétlési időköz beállítása, egérműveletek beszúrása, sor megkettőzése vagy törlése.

## Módok

A programban a módok nevei magyarul jelennek meg (Tartás, Kapcsoló, Lenyomás, Turbó, Kopp/Tart, Dupla, Auto-turbó). Itt az angol nevek szerepelnek, hogy könnyű legyen összevetni a leírásokkal.

| Mód | Mit csinál |
|---|---|
| **Hold** (Tartás) | Elküldi a kombót, amíg nyomva tartod a kiváltót, és elengedi, amikor felengeded. |
| **Toggle** (Kapcsoló) | Egyszer megnyomod, hogy lenyomva tartsa a billentyűket, még egyszer, hogy elengedje. |
| **Press** (Lenyomás) | A kombó egy gyors leütése minden alkalommal. |
| **Turbo** (Turbó) | Gyorsan ismétli a kombót, amíg nyomva tartod a kiváltót. |
| **TapHold** (Kopp/Tart) | Egy gyors koppintás az első billentyűt küldi, a tartás a másodikat. |
| **DblTap** (Dupla) | Két gyors leütés (0,35 másodpercen belül) elküldi a kombót. |
| **TglTurbo** (Auto-turbó) | Egyszer megnyomod, és a kombó magától ismétlődik, még egyszer megnyomod, és leáll. Jó automatikus kattintáshoz és automatikus nyomkodáshoz. |

## Kombószavak

A szavakat vesszővel válaszd el.

| Szó | Jelentés |
|---|---|
| `w`, `shift`, `space`, `f5` | Billentyűk név szerint |
| `d150` vagy `150` | Várj 150 ezredmásodpercet (egyetlen számjegy valódi billentyű) |
| `mlc` `mrc` `mmc` | Bal, jobb és középső kattintás |
| `mdc` | Dupla kattintás |
| `mdown` `mup` | A bal gomb lenyomva tartása és felengedése |
| `mwd5` `mwu5` | Görgetés le vagy fel 5 fokot |
| `m10,-5` | Az egér mozgatása 10-zel jobbra és 5-tel felfelé (relatív) |
| `mx400,300` | Az egér mozgatása a 400,300 képernyőpozícióra |
| `mm200,0,500` | Sima mozgás: 200 képpont jobbra 500 ezredmásodperc alatt |
| `mshake12,600` | Kamerarázkódás legfeljebb 12 képponttal 600 ezredmásodpercig |
| `mwave0,30,600,15` | Fel-le hullámzás 30 képponttal 15 ezredmásodpercenként 600 ezredmásodpercig |
| `mh300,0` | Egyenletes mozgás másodpercenként 300 képponttal, amíg egy Hold sor nyomva van vagy egy Toggle sor be van kapcsolva |
| `down:q` `up:q` | Egy billentyű (vagy egérgomb, például `lbutton`) lenyomva tartása több lépésen át, majd elengedése |
| `burst:x,30,40` | Az `x` megnyomása 30-szor, 40 ezredmásodperces időközzel (egybillentyűs gombnyomkodás) |
| `alt:x/c,30,40` | Az `x` és a `c` váltogatása 30-szor (bal/jobb nyomkodás) |
| `hold:x,800` | Az `x` tartása 800 ezredmásodpercig, majd elengedése |

A `burst`, az `alt` és a `hold` a Press, Turbo, TglTurbo és DblTap módban működik.

## Kombóreceptek

Másold ezeket a kombómezőbe.

| Amit szeretnék | Kombó |
|---|---|
| Shift és Szóköz együtt | `down:lshift,d30,space,d40,up:lshift` |
| Egy billentyű tartása fél másodpercig | `down:e,d500,up:e` |
| Egy billentyű háromszori koppintása | `e,d60,e,d60,e` |
| Dupla kattintás | `mdc` |
| Jobb gomb tartása 1 másodpercig | `down:rbutton,d1000,up:rbutton` |
| Ctrl és görgetés (nagyítás) | `down:lctrl,mwd1,up:lctrl` |
| Másolás / beillesztés | `down:lctrl,c,up:lctrl` / `down:lctrl,v,up:lctrl` |
| Alt és Tab | `down:lalt,tab,d100,up:lalt` |
| Görgetés, majd kattintás | `mwd3,d50,mlc` |
| Előre séta, majd fordulás | `down:w,d1000,down:a,d200,up:a,up:w` |
| Húzás az egérrel | `mx400,300,mdown,d50,mm200,0,500,mup` |
| Billentyű tartása és az egér rázása | `down:lctrl,mwave0,30,600,15` |
| Billentyű tartása és a görgő használata | `down:q,mwd2,d40,mwu2,d40` |
| Automatikus kattintás | sormód **TglTurbo**, kombó `mlc`, időköz 20 |
| Egy billentyű automatikus nyomkodása | sormód **TglTurbo**, kombó `e`, időköz 20 |
| Végtelen séta | sormód **Toggle**, kombó `w` |

## Profilok, lapok és a puskalap

**Profilok.** Egy profil egy sorkészlet a beállításaival, `.ini` fájlként mentve a `profiles` mappában. Válts a főablakból vagy a tálcamenüből. Az **Automatikus profilváltás játék szerint** magától profilt vált, amikor olyan játékra váltasz, amelynek a profiljában az a célprogram szerepel. A **Profil exportálása** a vágólapra másolja a profilt, az **Importálás** pedig visszahozza.

**Lapok.** Minden lap egy profil. A **Beállítások -> Lapok...** ablakban add hozzá a profilokat a kívánt sorrendben, majd válassz egy **Következő lap billentyűt** és egy tetszőleges **Előző lap billentyűt**. Az utolsó lap után a Következő visszamegy az elsőre. A lenyomva tartott billentyűket minden váltásnál elengedi. Az állapotdoboz és a puskalap mutatja, melyik lapon vagy, például „2. lap a 4-ből".

**Puskalap.** Állíts be egy puskalap-billentyűt ugyanabban az ablakban (a kész profilokban az F1).
- Első leütés: a profil és az összes lapja minden billentyűje, mindegyikhez közérthető megjegyzéssel.
- Második leütés: ugyanez a lista, mindegyik billentyű pontos kombójával.
- Harmadik leütés: bezárja.

A hosszú listákat oszlopokra osztja, hogy minden elférjen. A sorok megjegyzései a profilfájl `Note=` soraiból származnak.

## A beállítási varázsló

Nyisd meg a **tálcaikon -> Beállítási varázsló...** menüből. Kész profilt készít:

1. Válaszd ki a kezedet. Ezután olyan billentyűket választ, amelyeket az a kéz könnyen elér: bal kéz esetén F, G, X, T, B és a számbillentyűk; jobb kéz esetén J, K, L, U, I, O, H, N, M és a numerikus billentyűzet.
2. Nevezd el a profilt, és válaszd ki a játék programját a megnyitott programok listájából.
3. Sorold fel a billentyűket, amelyeket a játék már használ. A varázsló ezeket soha nem veszi el.
4. Jelöld be, mit szeretnél, hogy egy billentyű csináljon: előre séta, automatikus kattintás, egy billentyű automatikus nyomkodása, Shift tartása, Ctrl tartása vagy Shift + Szóköz együtt.

A **Mit csinál mindez?** gomb elmagyaráz minden kérdést és gombot, és minden mezőhöz tartozik egy súgóbuborék. Mentés előtt pontosan megmutatja, mit fog létrehozni, és megerősítést kér.

## Beállítások és testreszabás

Nyisd meg a **Beállításokat** a tálcaikonról.

| Hol | Mit változtathatsz |
|---|---|
| **Beállítások** | Bemeneti mód, nyelv, indítás (az **Automatikus indítás a Windows indításakor** azonnal érvényesül, és ha lehet, rendszergazdai joggal, UAC-kérdés nélkül indítja a programot bejelentkezéskor) és megjelenítési beállítások, a görgetéskattintás-billentyű és az Y-tengely zárolás billentyűje. (A vészleállító billentyű a főablakban van.) |
| **Beállítások -> Lapok...** | Következő lap billentyű, előző lap billentyű, a lapok listája és a puskalap-billentyű. |
| **Beállítások -> Kontroller...** | Kontrollertípus és karbeállítások. A kontroller alapból ki van kapcsolva. |
| **Beállítások -> Kisegítő eszközök...** | Ablakbillentyű, remegésszűrő, billentyűzetes egér és egygombos vezérlés (lásd: [Kisegítő eszközök](#kisegítő-eszközök)). |
| **Beállítások -> Testreszabás...** | Állapotdoboz: szövegméret, átlátszóság, háttérszín, és hogy megmutassa-e a sor nevét, amikor egy sor lefut (és meddig). Puskalap: szövegméret, meddig marad fent, színek, pozíció. |
| **Speciális beállítások** | Billentyű- és egéridőzítés, **Automatikus érzékelés (mp)** (meddig figyel az Auto, a Vál. és az Auto gomb (automata gomb választás), 3-tól 120-ig), „engedj el mindent, ha a játék elveszti a fókuszt", Futtatás rendszergazdaként, a naplófájl írása, valamint színek és téma. |

A bemeneti módok (**Játék**, **Klasszikus**, **Hibrid**) a billentyűk küldésének módját változtatják. Ha egy játék nem veszi figyelembe a billentyűket, próbálj ki másik módot (a tálcamenüben is megtalálod).

Vidd az egeret egy beállítás fölé a Beállítások ablakban egy rövid magyarázatért. A tálcamenü **Súgó...** pontja a program belsejében a teljes leírást tartalmazza.

## Nyelvek

A program **angolul** és **magyarul** érhető el. Ez magában foglalja a menüket, ablakokat, súgóbuborékokat, a Súgó ablakot, a varázslót, a módok neveit és a Névjegy ablakot. Tetszőleges számú további nyelvet hozzáadhatsz.

- Válaszd ki a nyelvet a **Beállításokban** (a Nyelv legördülő listában) vagy a **tálcamenüben** (Több -> Nyelv). A program felajánlja az újraindítást, hogy az új nyelv mindenhol érvényesüljön.
- **Készíts saját nyelvet.** A Beállításokban nyomd meg a **Sablon exportálása** gombot. Ez létrehozza a `lang\template.po` fájlt a program minden angol szövegével. Fordítsd le (minden `msgid` az angol szöveg, minden `msgstr` a te fordításod), és írd a fájl elejére egy megjegyzéssorba, hogy `# Language: A nyelv neve`. Az üresen hagyott `msgstr` az angol szöveget tartja meg.
- **Nyelvfájlok hozzáadása.** A Beállításokban nyomd meg a **Nyelvfájl hozzáadása...** gombot (a tálcamenüben is megtalálod a Nyelv alatt), és válassz ki egy vagy **több** `.po` fájlt egyszerre. A program átmásolja őket a `lang` mappába, és a nyelvlistában azonnal megjelennek. Ezután felajánlja, hogy átvált az új nyelvre, és újraindul. A `.po` fájlokat magad is bemásolhatod a `lang` mappába (a **Mappa megnyitása** gombbal megtalálod), például `lang\de.po`.
- A `lang` mappa minden `.po` fájlja külön nyelv, így a fájlokat meg lehet osztani, és annyit tarthatsz meg, amennyit csak szeretnél. Ha egy fájl neve megegyezik egy beépített nyelvével, felülírja annak szövegeit.
- Oszd meg a fordításodat egy hibajelentés (issue) vagy egy pull request megnyitásával, és be lehet építeni a programba.

## Quick time eventek

A quick time eventek (időzített gombkérések) nehezek, ha gyors és pontos leütések kellenek. Ezek a segítők képernyőolvasás nélkül könnyítik meg őket. Használj egy billentyűt gombonként, és csak annak a gombnak a billentyűjét nyomd meg, amelyet a kérés mutat, mert egy rossz gomb egyes minijátékokat véget vethet.

| Kérés | Sormód | Kombó | Mi történik |
|---|---|---|---|
| Gombnyomkodás | **Press** | `burst:x,30,40` | Egy leütés 30-szor megnyomja az `x`-et, 40 ezredmásodperces időközzel (kb. 1,2 másodperc), aztán leáll |
| Bal-jobb nyomkodás | **Press** | `alt:x/c,30,40` | Egy leütés 30-szor váltogatja az `x`-et és a `c`-t |
| Gomb tartása | **Press** | `hold:x,1000` | Egy leütés 1 másodpercig tartja az `x`-et, aztán elengedi |
| Nyomkodás, ameddig kell | **TglTurbo** | `x` | Egyszer megnyomod az indításhoz, még egyszer a leállításhoz |
| Nyomkodás, amíg nyomva tartod a billentyűt | **Turbo** | `x` | Csak addig ismétel, amíg nyomva tartod a kiváltót |

- A **vészleállító billentyű** azonnal leállítja a sorozatot.
- A beállítási varázsló létre tudja hozni ezeket a sorokat (jelöld be a nyomkodás, váltogatás és tartás lehetőségeket).
- A programhoz tartozik egy kész profil, a `QTE helper (RPCS3 face buttons)`: a négy gomb az 1-től 4-ig terjedő billentyűkön, plusz egy váltogatós nyomkodás, egy tartás és két „nyomkodd tovább" billentyű. Másold az `.ini` fájlját a `profiles` mappába. Az RPCS3 emulátor PlayStation-stílusú V, X, B és C kiosztását használja; cseréld a betűket a saját játékodhoz.
- A sorozat hossza és sebessége a kombóban van: változtasd a `30`-at (hányszor) és a `40`-et (hány ezredmásodperces időközzel).

## Kisegítő eszközök

Nyisd meg a **Beállítások -> Kisegítő eszközök...** ablakot (vagy a tálcamenüt). A beállítások az egész programra érvényesek, nem profilonként.

### Szerkesztés játék közben

Nyomd meg az **ablakbillentyűt** (alapból `F12`), hogy a Combo ReMapper ablaka a játék elé kerüljön, és nyomd meg újra, hogy elrejtse és visszatérj a játékhoz. A tálcaikonra duplán kattintva ugyanez történik.

- Amíg az ablak elöl van, a sorbillentyűk ki vannak kapcsolva, így nyugodtan gépelhetsz a mezőkbe anélkül, hogy bármi elsülne. Amikor visszatérsz a játékhoz, újra bekapcsolnak.
- A **Maradjon a játék fölött, amíg nyitva van** kikapcsolható ugyanabban az ablakban.
- A játéknak ablakos vagy szegély nélküli módban kell futnia. Egy kizárólagos teljes képernyős játék bármelyik ablakot elrejtheti.
- A játékról való elváltás a lenyomva tartott billentyűket és kapcsolókat is elengedi, így szerkesztés közben semmi nem ragad be (ez a fókuszvesztés-biztonsági beállítás, és Célprogramot igényel).
- Az ablak bezárása az X-szel továbbra is kilép a programból. Az elrejtéshez használd az ablakbillentyűt.

### Remegésszűrő

Segít, ha remeg a kezed, vagy véletlenül nyomsz meg billentyűket.

- **Az ismételt leütés figyelmen kívül hagyása ennyi időn belül (ms).** Miután egy leütést elfogadott, ugyanannak a kiváltónak egy újabb leütését ezen az időn belül figyelmen kívül hagyja. Próbálj 150-től 400-ig. A 0 kikapcsolja.
- **A billentyűt ennyi ideig kell nyomva tartani (ms).** Egy leütés csak akkor számít, ha ennyi ideig lenyomva tartod. A 0 kikapcsolja.

A **DblTap** sorokra nem vonatkozik, mert ezekhez két gyors leütés kell.

### Billentyűzetes egér

A billentyűzettel mozgatja a kurzort és kattint, arra az esetre, ha az egér használata nehéz. Kapcsold be és ki a saját billentyűjével (alapból `F11`) vagy a tálcamenü **Több -> Billentyűzetes egér be / ki** pontjával.

| Művelet | Alapértelmezett billentyű |
|---|---|
| Mozgás fel / balra / le / jobbra | `E` / `S` / `D` / `F` |
| Bal / jobb / középső kattintás | `Q` / `W` / `R` |
| Görgetés fel / le | `T` / `G` |

- Egy kattintásbillentyű nyomva tartásával húzhatsz.
- A kurzor gyorsul, minél tovább tartasz nyomva egy mozgásbillentyűt (az ablakban kikapcsolható). A **Sebesség** képpont/másodpercben értendő.
- A billentyűk csak akkor működnek, amikor a billentyűzetes egér BE van kapcsolva. A **vészleállító billentyű** azonnal kikapcsolja.
- Bármelyik billentyűt megváltoztathatod az **Auto gomb** (automata gomb választás) gombbal. Az üresen hagyott billentyűt nem használja.

### Egygombos vezérlés

Egy billentyű végigléptet a műveleteiden, így egyetlen kapcsoló vagy gomb is elég.

1. Nyomd meg a kapcsolóbillentyűt. Megjelenik a képernyőn a profil műveleteinek listája.
2. **Automatikus mód:** a kiemelés magától halad lefelé a listán. Nyomd meg a billentyűt, amikor a kívánt művelet ki van emelve.
   **Léptető mód:** koppints a billentyűre a következő műveletre lépéshez, tartsd nyomva kb. 0,7 másodpercig a kiválasztáshoz.
3. A kiválasztott művelet úgy fut le, mintha a saját billentyűjét nyomtad volna meg.

A **Press**, **Toggle** és **TglTurbo** sorokkal működik a legjobban. A lista minden sor megjegyzését mutatja, utána a módját. Magától bezárul, ha semmit nem választasz. A sebességet lépésenkénti ezredmásodpercben állíthatod. Tálcamenü pont: **Egygombos vezérlés menü**.

### Sormegjegyzések

Kattints jobb gombbal egy sorra, és válaszd a **Sormegjegyzés szerkesztése...** pontot, hogy közérthető nevet adj neki, például „Előre séta". A megjegyzések megjelennek a puskalapon, az egygombos vezérlésben és az állapotdobozban: amikor egy sor lefut, az állapotdoboz felvillantja a megjegyzését (BE vagy KI felirattal a kapcsolóknál és az automatikus ismétléseknél). A megjegyzés nélküli sor a szokásos üzenetet mutatja, például a billentyűt és hogy mit küld. Ezt kikapcsolhatod, vagy megváltoztathatod, meddig látszik, a **Beállítások -> Testreszabás...** ablakban. A profil mentéséhez nyomd meg az **Alkalmaz** gombot.

## Játékkompatibilitás

A Combo ReMapper úgy működik, hogy bemenetet küld a játéknak, ugyanúgy, mint egy billentyűzet vagy egér. Hogy egy játék elfogadja-e, az a játéktól függ, online játékoknál pedig a csaló elleni védelmétől.

### Kompatibilitási lista

Játékok és programok, amelyekkel a szerző használta:

| Játék / platform | Állapot | Megjegyzés |
|---|---|---|
| PCSX2 emulátor | ✅ Működik | Teljesen kompatibilis |
| GTA San Andreas | ✅ Működik | Teljesen kompatibilis |
| No More Heroes | ✅ Működik | Teljesen kompatibilis |
| VRChat | ✅ Működik | Teljesen kompatibilis |
| My Hero Ultra Rumble | ✅ Működik | Teljesen kompatibilis |
| Lollipop Chainsaw RePop | ✅ Működik | Teljesen kompatibilis |

Ez a lista a szerző saját használatából származik. Próbáld ki a saját játékodat, mielőtt rá hagyatkozol.

### Emulátorok és konzoljátékok

Az emulátorok a számítógépeden futnak, és a billentyűzetet, az egeret és a kontrollereket úgy olvassák, mint bármely más program, így a Combo ReMapper ugyanúgy tudja vezérelni őket. Így használják a PCSX2-vel (lásd a fenti listát).

- **Kontrollerkiosztások.** A programban van egy **PS4 kontroller** beállítás és egy kezdő profil, amely a PS4 kontrollert billentyűzetre és egérre képezi le. Kapcsold be a **Beállítások -> Kontroller...** ablakban (alapból ki van kapcsolva).
- **Előbb használd az emulátor saját vezérlését.** A legtöbb emulátornak van beépített billentyű- és kontrollerkiosztó képernyője. A Combo ReMappert arra használd, amit az a képernyő nem tud: egy kombót egy billentyűvé alakít, tart helyetted valamit, vagy gyorsan ismétel.
- **Csak a fent felsorolt emulátorokat próbálták ki.** A PS4-emulátorokat és más újabb emulátorokat még nem próbálták ki, ezért teszteld a sajátodat, és számíts rá, hogy a **Célprogram** nevét és a **bemeneti módot** módosítanod kell.
- **Játékok, amelyek a tiéid.** Csak olyan játékokkal és emulátorokkal használd, amelyeket használhatsz, és tartsd be az emulátor és a játék szabályait.

### Csaló elleni védelem

A bemeneti szkripteket minden játék csaló elleni védelme másképp kezeli, és egyes játékok akkor is kitiltják az átalakító eszközöket, ha kisegítő célra használják őket.

- Sok indie játék, régebbi cím és csaló elleni védelem nélküli játék általában rendben van.
- Az Easy Anti-Cheat, BattlEye vagy kernel módú védelmet használó játékok észlelhetik a szkriptet.
- A versenyző online játékok, például a Valorant, az Apex Legends, a Fortnite és a PUBG általában minden bemenet-átalakítást kitiltanak.

Mielőtt új játékkal használod:

1. Nézd meg, hogy a játék hivatalosan támogatja-e a kisegítő célú átalakító eszközöket.
2. Olvasd el a játék csaló elleni szabályzatát.
3. Ha tudsz, próbáld ki nem rangsorolt vagy nem versenyző fiókon.
4. Kérdezd meg a kisegítő közösséget az adott címről.

### Ha a játék nem veszi figyelembe a billentyűket

- Próbálj ki másik **bemeneti módot** (Játék, Klasszikus vagy Hibrid) a Beállításokban vagy a tálcamenüben (Több -> Bemeneti mód).
- Futtasd a programot **rendszergazdaként**, ha a játék vagy az emulátor rendszergazdaként fut.
- Növeld az **Extra leütési időt** a Beállításokban, ha a rövid koppintások kimaradnak.
- Ellenőrizd, hogy a **Célprogram** neve a játék valódi programneve.

## Alapértelmezett gyorsbillentyűk

| Gyorsbillentyű | Művelet |
|---|---|
| `F6` | Az Y-tengely egérzár ki- és bekapcsolása |
| `F7` | Az állapotdoboz megjelenítése vagy elrejtése |
| `F8` | Vész: az átalakító ki- és bekapcsolása, és minden lenyomva tartott billentyű elengedése |

Mindhármat megváltoztathatod a Beállításokban. A kész balkezes profilok az `F2`-t használják vészleállításra és az `F1`-et a puskalaphoz.

**Az állapotdoboz** (az F7 megjeleníti vagy elrejti) a *REMAPPER: ACTIVE* vagy *REMAPPER: DISABLED* feliratot mutatja. Alatta soronként felsorol mindent, ami magától fut: pontot (●) a bekapcsolt Toggle sorokhoz, és dupla nyilat (») az ismétlődő Turbo vagy TglTurbo sorokhoz. Minden sor a sor megjegyzését mutatja, vagy a billentyűt és azt, hogy mit küld, ha nincs megjegyzése. Amikor egy sor lefut, a doboz egy pillanatra a nevét is felvillantja. A listát kikapcsolhatod a **Beállítások -> Testreszabás...** ablakban (*Az állapotdobozban listázza a futó kapcsolókat és turbókat*).

---

## Biztonság

- **Vészleállító billentyű.** Egyszerre ki- és bekapcsolja az egész átalakítót, és elenged minden lenyomva tartott billentyűt. Alapból F8, a kész balkezes profilokban F2. Nem hagyható üresen.
- **Elengedés fókuszvesztéskor.** Amikor elváltasz a játékról (Alt+Tab, összeomlás, kicsinyítés), a lenyomva tartott billentyűk, kapcsolók és automatikus ismétlések leállnak, így semmi nem ragad be. Ehhez Célprogram kell, és a Speciális beállításokban kikapcsolható.
- **Beragadt módosítók elengedése.** Ha a Windows szerint a Ctrl, a Shift, az Alt vagy a középső egérgomb le van nyomva, miközben nincs rajta az ujjad, és a program sem tart semmit, a program rövid idő után elengedi, és egy sort ír a naplóba. A beragadt Ctrl vagy középső gomb miatt nyit meg egy sima kattintás hivatkozást új lapon.
- **Kilépés.** A program bezárása elenged minden billentyűt, amelyet tartott.
- **Kombók ellenőrzése** (tálcamenü, Több) elgépeléseket és hibákat keres a soraidban.
- **Egyjátékos használat.** Ne használd online vagy versenyjátékokban.

## Hibaelhárítás

| Probléma | Mit próbálj |
|---|---|
| A program nem csinál semmit, vagy csak egy tálcaikont mutat (gyakran másik számítógépen) | 1. Győződj meg róla, hogy **AutoHotkey v2** (nem v1), és hogy a szkript egy normál mappában van, nem egy zip fájlban. 2. Fogadd el a Windows kérdését (UAC), amikor rendszergazdai jogot kér; ha nem tudod, indítsd `/noadmin` kapcsolóval, vagy állítsd a `RunAsAdmin=0` értéket a `remapper_global.ini` fájlban. 3. Ha megjelenik egy *indítási probléma* ablak, küldd el a szövegét. 4. Ellenőrizd, hogy a vírusirtód nem blokkolta-e. |
| A billentyűk nem csinálnak semmit a játékban | Ellenőrizd a **Célprogram** nevét a Feladatkezelőben, futtasd a programot rendszergazdaként, vagy próbálj ki másik bemeneti módot. |
| Egy billentyű egyáltalán nem csinál semmit | Lehet, hogy egy másik sor, a vészleállító billentyű vagy egy másik gyorsbillentyű már használja. A **Kombók ellenőrzése** megmondja. |
| Az időzített kérések vagy a rövid koppintások kimaradnak | Növeld az **Extra leütési időt** a Beállításokban. |
| Egy lenyomva tartott billentyű beragadt | Nyomd meg a vészleállító billentyűt. |
| Egy sima bal kattintás új lapon nyit meg hivatkozásokat (például Chrome-ban) | Valószínűleg beragadt egy Ctrl, Shift vagy a középső gomb. Nyomd meg a vészleállító billentyűt. A 9.6-os verzió óta a program magától is elengedi a beragadt módosítókat egy pillanat után. Ha mégis előfordul, használd a tálcamenü -> Több -> **Diagnosztika másolása** pontot, amíg történik, és illeszd be az eredményt egy hibajelentésbe. |
| A varázsló nem jelenik meg | Nyisd meg a tálcamenüből. A **Ne kérdezd újra** gomb megnyomása után nem jelenik meg indításkor. |
| A program rossz nyelven van | Válaszd ki a nyelvet a Beállításokban vagy a tálcamenüben. |
| Valami elromlott | Tálcamenü -> Több -> **Diagnosztika másolása**, majd illeszd be az eredményt, amikor segítséget kérsz. |

A program a hibákat és azt, hogy mi futott le, a szkript melletti `combo_remapper.log` fájlba írja (a Speciális beállításokban ki- és bekapcsolható). A tálcamenü -> Több -> **Naplófájl megnyitása** megmutatja.

## A program által használt fájlok

| Fájl vagy mappa | Cél |
|---|---|
| `Combo_ReMapper_9_7.ahk` | A program. |
| `profiles\` | Profilonként vagy lapként egy `.ini` fájl. |
| `lang\` | További nyelvek `.po` fájlként, és az exportált sablon. |
| `remapper_global.ini` | Az egész programra érvényes beállítások, például a nyelv, a megjelenés, a Futtatás rendszergazdaként és a naplózás. |
| `combo_remapper.log` | Hibák és hogy mi futott le. Körülbelül 250 KB után új fájlt kezd. |

Ha a szkript saját mappájába nem lehet írni (például Program Files vagy védett mappa), a program ezeket a fájlokat a `%AppData%\ComboReMapper` mappában tartja, és oda másolja a meglévő profiljaidat.

## Rejtett témák

A Combo ReMapper-ben két titkos színtéma van. Mindegyiket egy kis képernyőn megjelenő feladvány megnyerésével lehet feloldani, ez a **kiber konzol**. Csak egér kell hozzá, és semmit nem kell lenyomva tartani.

| Téma | Kinézet | Hogyan oldd fel |
|---|---|---|
| **Cyber Red** | Majdnem fekete háttér, meleg törtfehér szöveg, piros, narancs és kék kiemelések | Nyisd meg a **Beállításokat**, és kattints a bal alsó sarokban lévő ⚡ jelre. Nyerj meg egy 5 lépéses mintát. |
| **Cyber Yellow** | Sötét ibolya háttér, neonsárga szöveg, ciánkék és rózsaszín kiemelések | Nyisd meg a **Speciális beállításokat**, és kattints a **Kész** gomb melletti ◈ jelre. Nyerj meg egy 6 lépéses mintát. |

**A kiber konzol.** Megnyílik egy kis ablak négy nagy gombbal. Amíg azt írja, hogy FIGYELD, a gombok véletlenszerű mintában felvillannak. Amikor azt írja, hogy ISMÉTELD, kattints ugyanazokra a gombokra ugyanabban a sorrendben. Egy rossz gomb HOZZÁFÉRÉS MEGTAGADVA üzenetet és új mintát ad, az **ÚJRAJÁTSZÁS** pedig újra megmutatja a mintát. Ha nyersz, lejátszódik egy rövid indítási animáció, és bekapcsol a téma. Ezután a téma ott marad a főablak témalistájában, újraindítás után is.

Amíg valamelyik kiber téma be van kapcsolva, az állapotdoboz a téma színeivel *KIBER MÓD: BE* vagy *KIBER MÓD: KI* feliratot mutat, a feliratok pedig néhány másodpercenként egy pillanatra felvillannak.

> **Ez csak egy szórakoztató projekt.** A témák semmilyen céggel vagy márkával nem állnak kapcsolatban, egyikük sem szponzorálja vagy támogatja őket.

## Újdonságok a 9.7-ben

- **Javítva:** a ki- és bekapcsolás. A remapper kikapcsolása (vészleállító billentyű, Alkalmaz, fókuszvesztés) félúton megállhatott, és az állapotdoboz ACTIVE-on, a billentyűk lenyomva maradhattak. Mostantól mindig végigfut.
- **Javítva:** indítási hiba („Parameter #1 invalid”), ha a `profiles` mappában voltak más profilok, de `default` nem, például a program új mappába költöztetése után. Mostantól az első megtalált profilt nyitja meg.
- **Javítva:** a beállítási varázsló megerősítő ablaka a varázsló mögé került, és nem lehetett elérni. Minden párbeszédablak most elöl jelenik meg.
- **Javítva:** az **Automatikus indítás a Windows indításakor** nem működött megbízhatóan. Mostantól kifejezetten az AutoHotkey-jal indítja a szkriptet, rendszergazdai futásnál ütemezett feladatot használ (nincs UAC-kérdés minden indításkor), és megmondja, mit csinált.
- **Új:** az állapotdoboz felsorolja az összes futó kapcsolót és turbót, a **Beállítások -> Testreszabás...** ablakban pedig egy jelölőnégyzettel kikapcsolhatod ezt a listát.
- **Új:** a két rejtett téma neve most **Cyber Red** és **Cyber Yellow**, és az állapotdoboz *KIBER MÓD* feliratot mutat, amíg valamelyik be van kapcsolva.
- **Új:** a **Nyelvfájl hozzáadása...** egyszerre egy vagy több `.po` fordítási fájlt ad hozzá.
- **Fordítás:** a program minden szövege szerepel a magyar fájlban és a kiexportált sablonban.

## Névjegy

Készítette: **Dani**.

Dani mozgássérült, és azért készíti ezeket az eszközöket, hogy a játékokat és programokat könnyebb legyen játszani és használni, Daninak és másoknak.

Ezt a programot MI (a Claude, az Anthropic terméke) segítségével írták. Dani találta ki az ötletet, és döntötte el, hogyan működjön és mit csináljon; a kódot az MI írta. Ezt nyíltan kimondjuk, hogy az emberek tudják, hogyan készült a szoftver, és hová jelentsék a hibát, ha elromlik.
