; ============================================================
; Combo ReMapper 9.7 — CHEAT SHEET, PAGES, TglTurbo MODE, CONTROLLER ON/OFF COMBO, RIGHT-CLICK FIX / SWITCHABLE COMPATIBILITY MODES
; Mouse actions + Gamepad (controller) support
; ============================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook True

; ---- Where settings, profiles and the log are kept ----
; Normally next to this script. If that folder cannot be written to (Program Files, a read-only
; or protected folder, an unzipped-in-place archive), %AppData%\ComboReMapper is used instead.
global langCode := "en"
global sentDown := Map()
global stuckSince := 0
global modStuckSince := 0
global langMap := Map()
global bootDone := false
global bootErrorCount := 0
global dataDir := A_ScriptDir
if (!DataDirWritable(A_ScriptDir)) {
    dataDir := A_AppData "\ComboReMapper"
    try DirCreate(dataDir)
    try DirCreate(dataDir "\profiles")
    try {
        if (DirExist(A_ScriptDir "\profiles"))
            FileCopy(A_ScriptDir "\profiles\*.ini", dataDir "\profiles\", 0)
    }
    try {
        if (FileExist(A_ScriptDir "\remapper_global.ini") && !FileExist(dataDir "\remapper_global.ini"))
            FileCopy(A_ScriptDir "\remapper_global.ini", dataDir "\remapper_global.ini", 0)
    }
}

DataDirWritable(dir) {
    probe := dir "\.write_test_" . A_TickCount
    try {
        FileAppend("x", probe)
        FileDelete(probe)
        return true
    }
    return false
}

; ---- Run elevated: games/emulators started as admin ignore input from a
; non-elevated script. If UAC is declined the script simply keeps running
; without elevation.
; ---- About section: change your name here ----
global creatorName := "Dani"
global aiNote := "This program was written with the help of AI (Claude, made by Anthropic). I described what I needed and decided how it should work; the AI wrote the code. I say so openly so that people know how this software was made."
global runAsAdmin := true
try runAsAdmin := (IniRead(dataDir "\remapper_global.ini", "Global", "RunAsAdmin", "1") = "1")
global osdSize := 10
global osdOpacity := 100
global osdBg := "1E1E1E"
global cheatSize := 12
global cheatSeconds := 45
global cheatBg := "101820"
global cheatFg := "FFFFFF"
global cheatPos := "Center"
global showFireName := true
global showOsdRunning := true
global fireNameMs := 800
CustomLoad()
global tremorMs := 0
global tremorHoldMs := 0
global tremorLast := Map()
global tremorIgnored := Map()
global kmOn := false
global kmToggleKey := "F11"
global kmSpeed := 700
global kmAccel := true
global kmKeys := Map()
global kmHotkeysSet := []
global kmBtnHeld := Map()
global kmLastTick := 0
global kmAccX := 0
global kmAccY := 0
global kmMoveStart := 0
global kmRegisteredToggle := ""
global scanKey := ""
global scanMode := "auto"
global scanMs := 1200
global scanOn := false
global scanIdx := 0
global scanItems := []
global scanTexts := []
global scanGui := 0
global scanLoops := 0
global scanKeyIsDown := false
global scanKeyDownTick := 0
global scanRegisteredKey := ""
global accGui := 0
global windowKey := "F12"
global windowRegisteredKey := ""
global winKeepTop := true
global prevWinHwnd := 0
global rowHotkeysOn := true
AccessLoad()
global logToFile := true            ; write combo_remapper.log (errors, profile loads, safety releases)
try logToFile := (IniRead(dataDir "\remapper_global.ini", "Global", "LogToFile", "1") != "0")
global compatMode := 1   ; 1 = Game, 2 = Classic, 3 = Hybrid (see CompatModeNames)
; ---- Language (English is built in; Hungarian = Magyar). Change it in the tray menu: More -> Language ----
LangLoad()

global elevatedAlready := false
global startedByAutoStart := false
for argText in A_Args {
    if (argText = "/elevated" || argText = "/noadmin")
        elevatedAlready := true
    if (argText = "/autostart")
        startedByAutoStart := true
}
if (runAsAdmin && !A_IsAdmin && !elevatedAlready) {
    relaunched := false
    try {
        if A_IsCompiled
            Run('*RunAs "' A_ScriptFullPath '" /elevated' . (startedByAutoStart ? ' /autostart' : ''))
        else
            Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '" /elevated' . (startedByAutoStart ? ' /autostart' : ''))
        relaunched := true
    }
    if (relaunched)
        ExitApp()
}

SendMode("Event")
; Held keys auto-repeat and fire hotkeys constantly; disable the
; "too many hotkeys" limiter so it never pops a dialog over the game.
A_MaxHotkeysPerInterval := 99000000
A_HotkeyInterval := 2000
try ProcessSetPriority("High")
; 1 ms timer resolution so Sleep() and SetTimer() are accurate (default ~15.6 ms)
DllCall("winmm\timeBeginPeriod", "UInt", 1)

OnExit(HandleExit)
; Safety net: an unexpected error in a hotkey thread is logged and that thread
; stops, but the whole program no longer closes.
OnError(HandleUnexpectedError)
HandleUnexpectedError(err, mode) {
    global bootDone, bootErrorCount
    if (!bootDone && bootErrorCount < 3) {
        bootErrorCount += 1
        try MsgBox(LangT("Combo ReMapper hit a problem while starting:`n`n") . err.Message . "`n(" . err.What . LangT(", line ") . err.Line . LangT(")`n`nThe program may not work correctly. If you ask for help, please send this message."), LangT("Combo ReMapper - startup problem"), "Icon! 262144")
    }
    try LogEvent("ERROR: " . err.Message . "  (line " . err.Line . ")", true)
    try DiagLog("ERROR: " . err.Message . " | in: " . err.What . " | line: " . err.Line . " | extra: " . err.Extra)
    try ReleaseAllHeldCombos()
    return 1
}

; ---- Global State Initializations ----
global scriptEnabled := true
global yAxisLocked := false
global seqHeldKeys := Map()          ; keys held by down:/up: tokens, so they can always be released
global yLockKey := "F6"              ; hotkey for the Y-axis lock; blank = disabled
global registeredYLockKey := ""
global lockedYCoord := 0
global osdGui := ""
global osdText := ""
global showOsd := true
global osdLocked := true
global osdX := 20
global osdY := 20
global osdToggleKey := "F7"
global turboTimers := Map()

; ---- Cheat sheet and pages (9.6) ----
global layerKey := ""
global layerProfile := ""
global layerBase := ""
global layerSwitching := false
global layerReturning := false
global layerPrevKey := ""
global registeredPrevKey := ""
global layerPages := []
global layerIdx := 0
global captureHook := ""
global registeredLayerKey := ""
global cheatKey := ""
global registeredCheatKey := ""
global cheatGui := ""
global cheatState := 0
global customGui := 0
global wizGui := 0
global wizHelpGui := 0
global offerGui := 0

; ---- Mouse & Controller state ----
global mouseHeld := Map()           ; tracks left/right/middle buttons held by engine
global controllerEnabled := false   ; master switch for gamepad polling (off by default since 9.0)
global joyButtonState := Map()      ; per-button last-seen state (edge detection)
global joyPovState := ""            ; last POV direction seen
global stickDeadzone := 0.25        ; reserved for optional stick triggers
global controllerPollMs := 15
global controllerTimerActive := false
global joyId := 1                   ; which gamepad (1-16) is being polled
global joyDetectTick := 0
global holdMotion := Map()          ; trigger -> continuous-motion state (mh tokens)
global motionEpoch := 0             ; bumped to abort any running smooth-move / shake
global MOTION_TICK_MS := 8          ; mouse motion update interval (~125 Hz)

; ---- XInput pad + stick-to-mouse + mouse scaling ----
global xiGetState := 0
global xiBuf := Buffer(16, 0)
global xiUser := -1                 ; active XInput pad index (0-3), -1 = none
global xiPrev := Map()              ; XInput tokens down on the previous poll
global xiScanTick := 0
global xiTried := false
global padPort := 0                 ; 0 = auto, 1-4 = fixed pad
global padType := 1                 ; 1 = Auto, 2 = Xbox (XInput only), 3 = PS4 (DirectInput only)
global padMouseStick := 0           ; 0 off, 1 left stick, 2 right stick
global padScrollStick := 0          ; 0 off, 1 left stick, 2 right stick
global padMouseSpeed := 900         ; pixels per second at full deflection
global padMouseDead := 18           ; deadzone, percent
global padMouseCurve := 1.6         ; response curve (1 = linear)
global padScrollSpeed := 12         ; wheel ticks per second at full deflection
global padTrigThresh := 40          ; trigger press threshold (0-255)
global mouseScale := 100            ; percent, applies to m / mm / mshake / mh tokens
global padMouseTimerOn := false
global pressExtraMs := 0            ; extra milliseconds added to every key press
global autoDetectSecs := 10         ; how long Auto / Set / Bind listen for a key (seconds)
global releaseOnBlur := true        ; let go of everything when the game loses focus
global trigRecHook := ""
global padPanic := true             ; hold Start+Back / Share+Options to stop
global padPanicStart := 0
global padSwitchCombo := ""        ; blank = default (Xbox Start+Back / PS4 Share+Options); else e.g. XLB+XRB+XSTART
global padPanicFired := false
global chordDown := Map()           ; controller chord triggers currently held
global doubleTapLast := Map()       ; trigger -> tick of its last press (DblTap mode)
global tipMap := Map()              ; control hwnd -> hover tip text
global tipLast := ""
global tipWinHwnd := 0
global helpGui := 0
global advGui := 0
global jsPrev := Map()              ; DirectInput stick-direction tokens down on the previous poll
global autoProfile := false         ; auto-switch profile by active game window
global autoProfLastExe := ""
global fireLog := []                ; recent events for the Fire Log window
global logLastMsg := ""
global logLastTick := 0
global logLastWrite := 0
global padSrc := 1                  ; stick source: 1 = XInput, 2 = DirectInput (DualShock etc.)
global padLast := 0.0
global padAccX := 0.0
global padAccY := 0.0
global padAccS := 0.0
global scaleRemX := 0.0
global scaleRemY := 0.0

; ---- Global Themes & Configuration ----
global Themes := Map(
    "Dark",         Map("bg", "1E1E1E", "text", "FFFFFF", "controlBg", "2D2D2D", "img", ""),
    "Light",        Map("bg", "F0F0F0", "text", "000000", "controlBg", "FFFFFF", "img", ""),
    "Custom Image", Map("bg", "1E1E1E", "text", "FFFFFF", "controlBg", "2D2D2D", "img", ""),
    "Cyber Red",    Map("bg", "0F0D0D", "text", "F4EDE4", "controlBg", "241615", "edit", "FF7A1A", "img", ""),
    "Cyber Yellow", Map("bg", "0A0612", "text", "FCEE0A", "controlBg", "1A0B2E", "edit", "00F0FF", "img", "")
)
global cyberUnlocked := Map("Cyber Red", false, "Cyber Yellow", false)
global cyberPulseList := []
global cyDeck := ""
global cyDeckBtns := []
global cyDeckStatus := ""
global cyDeckSeq := []
global cyDeckPos := 0
global cyDeckLocked := true
global cyDeckStepNo := 0
global cyDeckTheme := "Cyber Red"
global cySeqGui := ""
global cySeqCtl := ""
global cySeqFull := ""
global cySeqTick := 0
global cySeqBase := [0, 0]
global cySeqPrev := "Dark"
global cySeqTheme := "Cyber Red"
global currentTheme := "Dark"

; ---- Advanced Global Settings ----
global keyDelayDuration := 20
global keyDelayPress := 20
global mouseDelayDuration := 10
global soundAlerts := true
global showTooltips := true
global customBgColor := "1E1E1E"
global customControlColor := "2D2D2D"
global customTextColor := "FFFFFF"

; ---- Profile Directory & File Setup ----
profilesDir := dataDir "\profiles"
if !DirExist(profilesDir)
    try DirCreate(profilesDir)

globalSettingsFile := dataDir "\remapper_global.ini"

currentProfile := "default"
try currentProfile := IniRead(globalSettingsFile, "Global", "LastProfile", "default")
try autoProfile := (IniRead(globalSettingsFile, "Global", "AutoProfile", "0") = "1")
if !FileExist(profilesDir "\" currentProfile ".ini") {
    ; the saved profile is gone (new folder, renamed or deleted): use the first profile that exists,
    ; and only fall back to a new "default" when the folder has none at all
    firstProfile := ""
    loop files, profilesDir "\*.ini" {
        firstProfile := StrReplace(A_LoopFileName, ".ini", "")
        break
    }
    currentProfile := (firstProfile != "") ? firstProfile : "default"
}
configFile := profilesDir "\" currentProfile ".ini"

; ---- Global State ----
rows := []
nextRowId := 1
scrollTriggerKey := "K"
panicKey := "F8"
targetExe := ""

heldCombos := Map()
toggleActive := Map()
pressLatched := Map()

registeredRowTriggers := []
registeredScrollKey := ""
registeredPanicKey := ""
registeredOsdKey := ""

VISIBLE_ROWS := 6
scrollOffset := 0

; GUI control references
rowUI := []
rowSlider := ""
scrollLabel := ""
scrollUpBtn := ""
scrollDownBtn := ""
panicKeyBox := ""
scrollKeyBox := ""
targetExeBox := ""
statusBadge := ""
toggleBtn := ""
statusText := ""
profileDD := ""
themeDD := ""
bgPicControl := ""
textControls := []
myGui := ""

; ============================================================
; ---- Token classification helpers ----
; ============================================================

IsJoyTrigger(trig) {
    ; Returns true if the given trigger string is a gamepad token
    if (trig = "")
        return false
    t := StrUpper(Trim(RegExReplace(trig, "^~")))
    if InStr(t, "+") {
        ; Chord: several controller buttons held together, e.g. J5+J6
        chordParts := StrSplit(t, "+")
        if (chordParts.Length < 2)
            return false
        for part in chordParts {
            if (part = "" || InStr(part, "+") || !IsJoyTrigger(part))
                return false
        }
        return true
    }
    if RegExMatch(t, "^J(\d{1,2}|POV[UDLR]|[LR]S[UDLR])$")
        return true
    ; XInput (Xbox-style pad): XA XB XX XY XLB XRB XBACK XSTART XLS XRS XUP XDOWN XLEFT XRIGHT XLT XRT
    ; and stick directions XLSU/XLSD/XLSL/XLSR, XRSU/XRSD/XRSL/XRSR
    return RegExMatch(t, "^X(A|B|X|Y|LB|RB|BACK|START|LS|RS|UP|DOWN|LEFT|RIGHT|LT|RT|[LR]S[UDLR])$") ? true : false
}

IsMouseActionToken(key) {
    ; Returns true if this combo entry is a mouse-action token (not a key)
    k := StrLower(Trim(key))
    if (k = "mlc" || k = "mrc" || k = "mmc" || k = "mdc" || k = "mdown" || k = "mup")
        return true
    if RegExMatch(k, "^mw[du]\d+$")
        return true
    if RegExMatch(k, "^m-?\d+,-?\d+$")
        return true
    if RegExMatch(k, "^mx-?\d+,-?\d+$")
        return true
    if RegExMatch(k, "^mm-?\d+,-?\d+,\d+$")
        return true
    if RegExMatch(k, "^mshake\d+,\d+$")
        return true
    if RegExMatch(k, "^mh-?\d+,-?\d+$")
        return true
    if RegExMatch(k, "^mwave-?\d+,-?\d+,\d+,\d+$")
        return true
    return false
}

IsMacroToken(key) {
    ; burst:x,30,40  alt:x/c,30,40  hold:x,800  = quick-time-event helpers (sequence modes only)
    return RegExMatch(Trim(key), "i)^(burst|alt|hold):\S+") ? true : false
}

IsKeyHoldToken(key) {
    ; down:q = press q and keep it down, up:q = let q go (used inside one combo)
    return RegExMatch(Trim(key), "i)^(down|up):\S+$") ? true : false
}

IsHoldMotionToken(key) {
    ; mh<vx>,<vy> = continuous relative motion (pixels/second) while a Hold row is
    ; held, or while a Toggle row is on.
    return RegExMatch(StrLower(Trim(key)), "^mh-?\d+,-?\d+$") ? true : false
}

GetRowHoldMotion(row, &vx, &vy) {
    ; Sums every mh token in the row. Returns true if the row has any.
    vx := 0
    vy := 0
    found := false
    for k in row.keys {
        if RegExMatch(StrLower(Trim(k)), "^mh(-?\d+),(-?\d+)$", &m) {
            vx += Integer(m[1])
            vy += Integer(m[2])
            found := true
        }
    }
    return found
}

IsMouseButtonName(key) {
    k := StrLower(Trim(key))
    return (k = "lbutton" || k = "rbutton" || k = "mbutton"
         || k = "xbutton1" || k = "xbutton2"
         || k = "wheelup" || k = "wheeldown")
}

; ============================================================
; ---- Helpers ----
; ============================================================
Range(a, b) {
    out := []
    loop b - a + 1
        out.Push(a + A_Index - 1)
    return out
}

ParseKeyList(raw) {
    parts := StrSplit(raw, ",")
    result := []
    i := 1
    while (i <= parts.Length) {
        trimmed := Trim(parts[i])
        ; Re-join mouse tokens the comma split apart:
        ;   m10,-5   mx400,300   mh300,0   mshake12,600   -> 1 extra number
        ;   mm200,0,500                                    -> 2 extra numbers
        extra := 0
        if RegExMatch(trimmed, "i)^(mx?|mh|mshake)-?\d+$")
            extra := 1
        else if RegExMatch(trimmed, "i)^mm-?\d+$")
            extra := 2
        else if RegExMatch(trimmed, "i)^mwave-?\d+$")
            extra := 3
        else if RegExMatch(trimmed, "i)^(burst|alt):\S+$")
            extra := 2
        else if RegExMatch(trimmed, "i)^hold:\S+$")
            extra := 1
        loop extra {
            if (i < parts.Length && RegExMatch(Trim(parts[i + 1]), "^-?\d+$")) {
                trimmed .= "," . Trim(parts[i + 1])
                i += 1
            }
        }
        if (trimmed != "")
            result.Push(trimmed)
        i += 1
    }
    return result
}

IsPauseToken(k) {
    ; Pause = "d150" or a multi-digit number. A single digit (0-9) is a real key.
    return RegExMatch(k, "i)^d\d+$") || (IsInteger(k) && StrLen(k) > 1)
}

NormalizeExe(name) {
    n := Trim(name)
    if (n = "" || n = "(any)")
        return ""
    if !RegExMatch(n, "i)\.exe$")
        n .= ".exe"
    return n
}

JoinArray(arr, sep) {
    out := ""
    for i, v in arr {
        out .= (i = 1 ? "" : sep) . v
    }
    return out
}

KeyListToString(keys) {
    return keys.Length ? JoinArray(keys, ",") : ""
}

GetProfileList() {
    global profilesDir
    list := []
    loop files, profilesDir "\*.ini" {
        list.Push(StrReplace(A_LoopFileName, ".ini", ""))
    }
    return list.Length ? list : ["default"]
}

SaveLastProfile() {
    global currentProfile, globalSettingsFile
    try IniWrite(currentProfile, globalSettingsFile, "Global", "LastProfile")
}

FlashOSD(msg, colorHex := "00FFFF", ms := 700) {
    global scriptEnabled, showOsd
    if (!showOsd)
        return
    UpdateOSD(msg, colorHex)
    SetTimer(() => UpdateOSD(scriptEnabled ? LangT("REMAPPER: ACTIVE") : LangT("REMAPPER: DISABLED"), scriptEnabled ? "00FF00" : "FF0000"), -ms)
}

NotifyUser(msg, duration := -1000) {
    global showTooltips, soundAlerts
    LogEvent("* " . msg)
    if (soundAlerts)
        SoundBeep(750, 100)
    if (showTooltips) {
        ToolTip(msg)
        SetTimer(() => ToolTip(), duration)
    }
}

; ============================================================
; ---- GAME-COMPATIBLE INPUT LAYER ----
; Keys are sent by scan code (DirectInput/RawInput games read scan codes),
; mouse buttons/wheel/movement use Win32 mouse_event (raw-input friendly),
; and every press is held long enough for a game frame to see it.
; ============================================================
CompatModeNames() {
    return [LangT("Game  (scan codes + raw mouse)"), LangT("Classic  (SendInput, plain key names)"), LangT("Hybrid  (SendInput scan codes + AHK mouse)")]
}

GetPressHold() {
    global keyDelayPress, compatMode, pressExtraMs
    if (compatMode = 2)
        return 20 + pressExtraMs
    return Max(keyDelayPress, 35) + pressExtraMs
}

RelMoveRaw(dx, dy) {
    ; Relative mouse move. Game mode uses the Win32 mouse_event call; the other
    ; modes use AutoHotkey's own MouseMove.
    global compatMode
    if (compatMode = 1) {
        DllCall("mouse_event", "UInt", 0x0001, "Int", dx, "Int", dy, "UInt", 0, "UPtr", 0)
    } else {
        SetMouseDelay(-1)
        MouseMove(dx, dy, 0, "R")
    }
}

MouseSleep() {
    global mouseDelayDuration
    if (mouseDelayDuration > 0)
        Sleep(mouseDelayDuration)
}

; True when some row uses this mouse button as its TRIGGER. The engine must then
; send that button in a way AutoHotkey recognises as its own, otherwise the
; trigger hotkey catches our own click, swallows it and fires again forever
; (that endless loop is what crashed the program with Right Click as trigger).
IsOwnTriggerButton(lowName) {
    global rows
    for row in rows {
        t := StrLower(LTrim(Trim(row.trigger), "~*"))
        if (t = lowName)
            return true
    }
    return false
}

MouseButtonEvent(name, isDown) {
    global compatMode, sentDown
    data := 0
    lowBtn := StrLower(Trim(name))
    if (RegExMatch(lowBtn, "^(lbutton|rbutton|mbutton|xbutton1|xbutton2)$")) {
        if (isDown)
            sentDown[lowBtn] := lowBtn
        else if (sentDown.Has(lowBtn))
            sentDown.Delete(lowBtn)
    }
    if (compatMode = 1 && RegExMatch(lowBtn, "^(lbutton|rbutton|mbutton|xbutton1|xbutton2)$") && IsOwnTriggerButton(lowBtn)) {
        ; SendEvent uses mouse_event too, but tags it so our own hotkeys ignore it
        ; while the game still receives it.
        SendEvent("{Blind}{" . lowBtn . (isDown ? " down}" : " up}"))
        return true
    }
    if (compatMode != 1) {
        lowName := StrLower(name)
        if !RegExMatch(lowName, "^(lbutton|rbutton|mbutton|xbutton1|xbutton2)$")
            return false
        SendInput("{" . lowName . (isDown ? " down}" : " up}"))
        return true
    }
    switch StrLower(name) {
        case "lbutton":
            flags := isDown ? 0x0002 : 0x0004
        case "rbutton":
            flags := isDown ? 0x0008 : 0x0010
        case "mbutton":
            flags := isDown ? 0x0020 : 0x0040
        case "xbutton1":
            flags := isDown ? 0x0080 : 0x0100
            data := 1
        case "xbutton2":
            flags := isDown ? 0x0080 : 0x0100
            data := 2
        default:
            return false
    }
    DllCall("mouse_event", "UInt", flags, "Int", 0, "Int", 0, "UInt", data, "UPtr", 0)
    return true
}

MouseClickGame(name) {
    MouseButtonEvent(name, true)
    Sleep(GetPressHold())
    MouseButtonEvent(name, false)
    MouseSleep()
}

MouseWheelTick(dir) {
    global compatMode
    if (compatMode != 1) {
        Click(dir > 0 ? "WheelUp" : "WheelDown")
        return
    }
    DllCall("mouse_event", "UInt", 0x0800, "Int", 0, "Int", 0, "Int", (dir > 0 ? 120 : -120), "UPtr", 0)
}

MouseMoveRelative(dx, dy) {
    RelMoveScaled(dx, dy)
    MouseSleep()
}

; ------------------------------------------------------------
; Real mouse motion engine (Win32 mouse_event, relative, timed loops)
; ------------------------------------------------------------
NowMs() {
    static freq := 0
    if (freq = 0) {
        f := 0
        DllCall("QueryPerformanceFrequency", "Int64*", &f)
        freq := f
    }
    c := 0
    DllCall("QueryPerformanceCounter", "Int64*", &c)
    return c * 1000.0 / freq
}

MouseSmoothMove(dx, dy, ms) {
    ; Spreads a total dx,dy over ms milliseconds in small timed steps, so the
    ; game sees continuous motion instead of one jump. Sub-pixel remainders are
    ; carried so the total is exact.
    global motionEpoch, MOTION_TICK_MS
    epoch := motionEpoch
    ms := Max(1, ms)
    startT := NowMs()
    sentX := 0
    sentY := 0
    loop {
        elapsed := Min(ms, NowMs() - startT)
        tx := Round(dx * elapsed / ms)
        ty := Round(dy * elapsed / ms)
        stepX := tx - sentX
        stepY := ty - sentY
        if (stepX != 0 || stepY != 0) {
            RelMoveScaled(stepX, stepY)
            sentX := tx
            sentY := ty
        }
        if (elapsed >= ms || epoch != motionEpoch)
            break
        Sleep(MOTION_TICK_MS)
    }
}

MouseShake(amp, ms) {
    ; Camera shake: the cursor jitters randomly within +/-amp pixels for ms
    ; milliseconds, then returns to exactly where it started.
    global motionEpoch, MOTION_TICK_MS
    epoch := motionEpoch
    startT := NowMs()
    offX := 0
    offY := 0
    while (NowMs() - startT < ms && epoch = motionEpoch) {
        nx := Random(-amp, amp)
        ny := Random(-amp, amp)
        RelMoveScaled(nx - offX, ny - offY)
        offX := nx
        offY := ny
        Sleep(MOTION_TICK_MS)
    }
    if (offX != 0 || offY != 0)
        RelMoveScaled(-offX, -offY)
}

MouseWave(dx, dy, ms, stepMs) {
    ; Waggle: the cursor swings between +(dx,dy) and -(dx,dy) of where it started,
    ; one swing every stepMs milliseconds, for ms milliseconds, then returns to the
    ; start. Handy for "shake the controller" prompts (e.g. katana recharge).
    global motionEpoch
    epoch := motionEpoch
    startT := NowMs()
    curX := 0
    curY := 0
    dir := -1
    stepMs := Max(4, stepMs)
    while (NowMs() - startT < ms && epoch = motionEpoch) {
        tx := dir * dx
        ty := dir * dy
        RelMoveScaled(tx - curX, ty - curY)
        curX := tx
        curY := ty
        dir := -dir
        Sleep(stepMs)
    }
    if (curX != 0 || curY != 0)
        RelMoveScaled(-curX, -curY)
}

StartHoldMotion(trig, vx, vy) {
    global holdMotion, MOTION_TICK_MS
    StopHoldMotion(trig)
    st := {vx: vx, vy: vy, last: NowMs(), ax: 0.0, ay: 0.0, fn: ""}
    st.fn := HoldMotionTick.Bind(trig)
    holdMotion[trig] := st
    SetTimer(st.fn, MOTION_TICK_MS)
}

StopHoldMotion(trig) {
    global holdMotion
    if holdMotion.Has(trig) {
        try SetTimer(holdMotion[trig].fn, 0)
        holdMotion.Delete(trig)
    }
}

StopAllHoldMotion() {
    global holdMotion, motionEpoch
    motionEpoch += 1
    for trig, st in holdMotion.Clone() {
        try SetTimer(st.fn, 0)
    }
    holdMotion := Map()
}

HoldMotionTick(trig) {
    global holdMotion, scriptEnabled, targetExe
    if !holdMotion.Has(trig)
        return
    st := holdMotion[trig]
    if (!scriptEnabled || (targetExe != "" && !WinActive("ahk_exe " . targetExe))) {
        StopHoldMotion(trig)
        return
    }
    nowT := NowMs()
    dt := nowT - st.last
    st.last := nowT
    st.ax += st.vx * dt / 1000
    st.ay += st.vy * dt / 1000
    ix := Integer(st.ax)
    iy := Integer(st.ay)
    if (ix != 0 || iy != 0) {
        st.ax -= ix
        st.ay -= iy
        RelMoveScaled(ix, iy)
    }
}

KeyToken(name) {
    vk := GetKeyVK(name)
    sc := GetKeySC(name)
    if (vk = 0 && sc = 0)
        return name
    return Format("vk{:X}sc{:X}", vk, sc)
}

SendKeyByMode(n, isDown) {
    global compatMode, sentDown
    sentKey := StrLower(Trim(n))
    if (isDown)
        sentDown[sentKey] := Trim(n)
    else if (sentDown.Has(sentKey))
        sentDown.Delete(sentKey)
    dir := isDown ? " down}" : " up}"
    if (compatMode = 2)
        SendInput("{" . n . dir)
    else if (compatMode = 3)
        SendInput("{Blind}{" . KeyToken(n) . dir)
    else
        SendEvent("{Blind}{" . KeyToken(n) . dir)
}

SetCompatMode(mode, *) {
    ; Quick switch (tray menu). Anything held is released with the OLD method first.
    global compatMode, configFile
    if (mode = compatMode)
        return
    ReleaseAllHeldCombos()
    compatMode := mode
    try IniWrite(compatMode, configFile, "Settings", "CompatMode")
    BuildTrayMenu()
    NotifyUser(LangT("Compatibility: ") . CompatModeNames()[compatMode])
}

GameKeyDown(name) {
    n := Trim(name)
    if (n = "" || IsJoyTrigger(n) || IsMouseActionToken(n) || IsKeyHoldToken(n) || IsMacroToken(n))
        return
    low := StrLower(n)
    if (low = "wheelup") {
        MouseWheelTick(1)
        return
    }
    if (low = "wheeldown") {
        MouseWheelTick(-1)
        return
    }
    if MouseButtonEvent(low, true)
        return
    SendKeyByMode(n, true)
}

GameKeyUp(name) {
    n := Trim(name)
    if (n = "" || IsJoyTrigger(n) || IsMouseActionToken(n) || IsKeyHoldToken(n) || IsMacroToken(n))
        return
    low := StrLower(n)
    if (low = "wheelup" || low = "wheeldown")
        return
    if MouseButtonEvent(low, false)
        return
    SendKeyByMode(n, false)
}

; ============================================================
; ---- MOUSE ACTION EXECUTOR ----
; ============================================================
RunMouseToken(lowerKey) {
    ; Executes a single mouse-action token. Returns true if handled.
    global mouseHeld

    if (lowerKey = "mlc") {
        MouseClickGame("lbutton")
        return true
    }
    if (lowerKey = "mrc") {
        MouseClickGame("rbutton")
        return true
    }
    if (lowerKey = "mmc") {
        MouseClickGame("mbutton")
        return true
    }
    if (lowerKey = "mdc") {
        MouseClickGame("lbutton")
        Sleep(70)
        MouseClickGame("lbutton")
        return true
    }
    if (lowerKey = "mdown") {
        MouseButtonEvent("lbutton", true)
        mouseHeld["lbutton"] := true
        return true
    }
    if (lowerKey = "mup") {
        MouseButtonEvent("lbutton", false)
        mouseHeld.Delete("lbutton")
        return true
    }
    if RegExMatch(lowerKey, "^mwd(\d+)$", &m) {
        loop Integer(m[1]) {
            MouseWheelTick(-1)
            Sleep(15)
        }
        return true
    }
    if RegExMatch(lowerKey, "^mwu(\d+)$", &m) {
        loop Integer(m[1]) {
            MouseWheelTick(1)
            Sleep(15)
        }
        return true
    }
    if RegExMatch(lowerKey, "^m(-?\d+),(-?\d+)$", &m) {
        MouseMoveRelative(Integer(m[1]), Integer(m[2]))
        return true
    }
    if RegExMatch(lowerKey, "^mx(-?\d+),(-?\d+)$", &m) {
        MouseMove(Integer(m[1]), Integer(m[2]), 0)
        MouseSleep()
        return true
    }
    if RegExMatch(lowerKey, "^mm(-?\d+),(-?\d+),(\d+)$", &m) {
        MouseSmoothMove(Integer(m[1]), Integer(m[2]), Integer(m[3]))
        return true
    }
    if RegExMatch(lowerKey, "^mwave(-?\d+),(-?\d+),(\d+),(\d+)$", &m) {
        MouseWave(Integer(m[1]), Integer(m[2]), Integer(m[3]), Integer(m[4]))
        return true
    }
    if RegExMatch(lowerKey, "^mshake(\d+),(\d+)$", &m) {
        MouseShake(Integer(m[1]), Integer(m[2]))
        return true
    }
    if RegExMatch(lowerKey, "^mh-?\d+,-?\d+$") {
        ; Continuous motion only runs in Hold / Toggle rows; ignored elsewhere.
        return true
    }
    return false
}

ReleaseMouseHeldButtons() {
    ; Sends up for any mouse button this engine is currently holding
    global mouseHeld
    for btn, _ in mouseHeld.Clone() {
        try MouseButtonEvent(btn, false)
    }
    mouseHeld := Map()
}

; ============================================================
; ---- CONTROLLER (GAMEPAD) ENGINE ----
; Uses native AHK v2 GetKeyState("JoyN") polling — no library required.
; ============================================================
StartControllerPolling() {
    global controllerTimerActive, controllerPollMs
    if (controllerTimerActive)
        return
    SetTimer(PollController, controllerPollMs)
    controllerTimerActive := true
    UpdatePadMouseTimer()
}

StopControllerPolling() {
    global controllerTimerActive, joyButtonState, joyPovState, xiPrev, jsPrev
    if (controllerTimerActive)
        SetTimer(PollController, 0)
    controllerTimerActive := false
    joyButtonState := Map()
    joyPovState := ""
    xiPrev := Map()
    jsPrev := Map()
    UpdatePadMouseTimer()
}

; ---- XINPUT BLOCK BEGIN ----
PadTypeNames() {
    return [LangT("Auto  (Xbox or PS4)"), LangT("Xbox  (XInput)"), LangT("PS4  (DirectInput)")]
}

UseXInput() {
    global padType
    return padType != 3
}

UseDirect() {
    global padType
    return padType != 2
}

SetPadType(mode, *) {
    ; Switch between Xbox (XInput) and PS4 (DirectInput). Anything held through the
    ; old input path is released first so nothing stays stuck.
    global padType, joyButtonState, joyPovState, xiPrev, jsPrev, configFile
    if (mode = padType)
        return
    for n, st in joyButtonState.Clone() {
        if (st)
            HandleRelease("J" . n)
    }
    if (joyPovState != "")
        HandleRelease(joyPovState)
    for tok, v in xiPrev.Clone()
        HandleRelease(tok)
    for tok, v in jsPrev.Clone()
        HandleRelease(tok)
    joyButtonState := Map()
    joyPovState := ""
    xiPrev := Map()
    jsPrev := Map()
    padType := mode
    try IniWrite(padType, configFile, "Settings", "PadType")
    BuildTrayMenu()
    NotifyUser(LangT("Controller type: ") . PadTypeNames()[padType])
}

XInputInit() {
    global xiGetState, xiTried
    if (xiGetState)
        return true
    if (xiTried)
        return false
    xiTried := true
    for dll in ["xinput1_4.dll", "xinput1_3.dll", "xinput9_1_0.dll"] {
        h := DllCall("LoadLibrary", "Str", dll, "Ptr")
        if (h) {
            p := DllCall("GetProcAddress", "Ptr", h, "AStr", "XInputGetState", "Ptr")
            if (p) {
                xiGetState := p
                return true
            }
        }
    }
    return false
}

XInputReadPad(idx) {
    global xiGetState, xiBuf
    if (!xiGetState)
        return false
    return DllCall(xiGetState, "UInt", idx, "Ptr", xiBuf, "UInt") = 0
}

XInputPoll() {
    ; Reads the active pad into xiBuf. Returns true if a pad is connected.
    global xiUser, xiScanTick, padPort
    if (!XInputInit())
        return false
    if (padPort >= 1) {
        xiUser := padPort - 1
        return XInputReadPad(xiUser)
    }
    if (xiUser >= 0) {
        if XInputReadPad(xiUser)
            return true
        xiUser := -1
    }
    if (A_TickCount - xiScanTick < 1000)
        return false
    xiScanTick := A_TickCount
    loop 4 {
        if XInputReadPad(A_Index - 1) {
            xiUser := A_Index - 1
            return true
        }
    }
    return false
}

XInputTokens() {
    ; Returns a Map of every XInput token currently held (from the last XInputPoll).
    global xiBuf, padTrigThresh
    down := Map()
    b := NumGet(xiBuf, 4, "UShort")
    if (b & 0x0001)
        down["XUP"] := true
    if (b & 0x0002)
        down["XDOWN"] := true
    if (b & 0x0004)
        down["XLEFT"] := true
    if (b & 0x0008)
        down["XRIGHT"] := true
    if (b & 0x0010)
        down["XSTART"] := true
    if (b & 0x0020)
        down["XBACK"] := true
    if (b & 0x0040)
        down["XLS"] := true
    if (b & 0x0080)
        down["XRS"] := true
    if (b & 0x0100)
        down["XLB"] := true
    if (b & 0x0200)
        down["XRB"] := true
    if (b & 0x1000)
        down["XA"] := true
    if (b & 0x2000)
        down["XB"] := true
    if (b & 0x4000)
        down["XX"] := true
    if (b & 0x8000)
        down["XY"] := true
    if (NumGet(xiBuf, 6, "UChar") >= padTrigThresh)
        down["XLT"] := true
    if (NumGet(xiBuf, 7, "UChar") >= padTrigThresh)
        down["XRT"] := true
    thr := 18000
    lx := NumGet(xiBuf, 8, "Short")
    ly := NumGet(xiBuf, 10, "Short")
    rx := NumGet(xiBuf, 12, "Short")
    ry := NumGet(xiBuf, 14, "Short")
    if (lx > thr)
        down["XLSR"] := true
    if (lx < -thr)
        down["XLSL"] := true
    if (ly > thr)
        down["XLSU"] := true
    if (ly < -thr)
        down["XLSD"] := true
    if (rx > thr)
        down["XRSR"] := true
    if (rx < -thr)
        down["XRSL"] := true
    if (ry > thr)
        down["XRSU"] := true
    if (ry < -thr)
        down["XRSD"] := true
    return down
}

JoyStickTokens() {
    ; DirectInput stick directions as digital tokens (DualShock 4: left = X/Y, right = Z/R):
    ; JLSU JLSD JLSL JLSR (left stick) and JRSU JRSD JRSL JRSR (right stick).
    down := Map()
    thr := 0.55
    lx := AxisToNorm(JoyAxis("X"))
    ly := -AxisToNorm(JoyAxis("Y"))
    rx := AxisToNorm(JoyAxis("Z"))
    ry := -AxisToNorm(JoyAxis("R"))
    if (lx > thr)
        down["JLSR"] := true
    if (lx < -thr)
        down["JLSL"] := true
    if (ly > thr)
        down["JLSU"] := true
    if (ly < -thr)
        down["JLSD"] := true
    if (rx > thr)
        down["JRSR"] := true
    if (rx < -thr)
        down["JRSL"] := true
    if (ry > thr)
        down["JRSU"] := true
    if (ry < -thr)
        down["JRSD"] := true
    return down
}

JoyPresent() {
    global joyId
    name := ""
    try name := GetKeyState(joyId . "JoyName")
    return name != ""
}

AxisToNorm(v) {
    ; DirectInput axes via winmm run 0-100 with the centre near 50
    return (v - 50.0) / 50.0
}

JoyAxis(axisName) {
    global joyId
    v := ""
    try v := GetKeyState(joyId . "Joy" . axisName)
    if (v = "" || !IsNumber(v))
        return 50.0
    return v + 0.0
}

PadStick(sel, &vx, &vy) {
    ; Radial deadzone + response curve. Returns -1..1 on each axis (up = +y).
    ; Source: XInput pad if present, otherwise the DirectInput pad (DualShock 4 etc.):
    ; left stick = JoyX/JoyY, right stick = JoyZ/JoyR.
    global xiBuf, padMouseDead, padMouseCurve, padSrc
    if (padSrc = 2) {
        if (sel = 2) {
            nx := AxisToNorm(JoyAxis("Z"))
            ny := -AxisToNorm(JoyAxis("R"))
        } else {
            nx := AxisToNorm(JoyAxis("X"))
            ny := -AxisToNorm(JoyAxis("Y"))
        }
    } else {
        off := (sel = 2) ? 12 : 8
        nx := NumGet(xiBuf, off, "Short") / 32767.0
        ny := NumGet(xiBuf, off + 2, "Short") / 32767.0
    }
    dead := Min(0.9, padMouseDead / 100.0)
    mag := Sqrt(nx * nx + ny * ny)
    vx := 0.0
    vy := 0.0
    if (mag <= dead)
        return
    scaled := Min(1.0, (mag - dead) / (1.0 - dead))
    factor := (scaled ** padMouseCurve) / mag
    vx := nx * factor
    vy := ny * factor
}

UpdatePadMouseTimer() {
    global controllerEnabled, padMouseStick, padScrollStick, padMouseTimerOn, padLast
    global padAccX, padAccY, padAccS, MOTION_TICK_MS
    want := controllerEnabled && (padMouseStick != 0 || padScrollStick != 0)
    if (want && !padMouseTimerOn) {
        padLast := NowMs()
        padAccX := 0.0
        padAccY := 0.0
        padAccS := 0.0
        SetTimer(PadMouseTick, MOTION_TICK_MS)
        padMouseTimerOn := true
    } else if (!want && padMouseTimerOn) {
        SetTimer(PadMouseTick, 0)
        padMouseTimerOn := false
    }
}

PadMouseTick() {
    global scriptEnabled, targetExe, padMouseStick, padScrollStick, padMouseSpeed, padScrollSpeed
    global padLast, padAccX, padAccY, padAccS, padSrc
    nowT := NowMs()
    dt := Min(100.0, nowT - padLast)
    padLast := nowT
    if (!scriptEnabled || (targetExe != "" && !WinActive("ahk_exe " . targetExe)))
        return
    if (UseXInput() && XInputPoll())
        padSrc := 1
    else if (UseDirect() && JoyPresent())
        padSrc := 2
    else
        return
    if (padMouseStick) {
        PadStick(padMouseStick, &vx, &vy)
        padAccX += vx * padMouseSpeed * dt / 1000
        padAccY -= vy * padMouseSpeed * dt / 1000
        ix := Integer(padAccX)
        iy := Integer(padAccY)
        if (ix != 0 || iy != 0) {
            padAccX -= ix
            padAccY -= iy
            RelMoveRaw(ix, iy)
        }
    }
    if (padScrollStick) {
        PadStick(padScrollStick, &sx, &sy)
        padAccS += sy * padScrollSpeed * dt / 1000
        while (padAccS >= 0.99999) {
            MouseWheelTick(1)
            padAccS -= 1
        }
        while (padAccS <= -0.99999) {
            MouseWheelTick(-1)
            padAccS += 1
        }
    }
}

RelMoveScaled(dx, dy) {
    ; Relative move for m / mm / mshake / mh tokens, with the global "mouse speed %".
    global mouseScale, scaleRemX, scaleRemY
    if (mouseScale = 100) {
        RelMoveRaw(dx, dy)
        return
    }
    scaleRemX += dx * mouseScale / 100
    scaleRemY += dy * mouseScale / 100
    ix := Integer(scaleRemX)
    iy := Integer(scaleRemY)
    scaleRemX -= ix
    scaleRemY -= iy
    if (ix != 0 || iy != 0)
        RelMoveRaw(ix, iy)
}
; ---- XINPUT BLOCK END ----

DetectJoyId() {
    global joyId
    loop 16 {
        name := ""
        try name := GetKeyState(A_Index . "JoyName")
        if (name != "") {
            joyId := A_Index
            return true
        }
    }
    return false
}

GetPovName() {
    global joyId
    povRaw := ""
    try povRaw := GetKeyState(joyId . "JoyPOV")
    if (povRaw = "" || !IsNumber(povRaw))
        return ""
    pov := povRaw + 0
    ; -1 (or 65535 on some drivers) means centered
    if (pov < 0 || pov > 35999)
        return ""
    if (pov <= 4500 || pov >= 31500)
        return "JPOVU"
    if (pov <= 13500)
        return "JPOVR"
    if (pov <= 22500)
        return "JPOVD"
    return "JPOVL"
}

JoyTriggerDown(token) {
    global joyId, xiUser
    t := StrUpper(Trim(token))
    if InStr(t, "+") {
        for part in StrSplit(t, "+") {
            if (!JoyTriggerDown(part))
                return false
        }
        return true
    }
    if (SubStr(t, 1, 1) = "X") {
        if (!XInputPoll())
            return false
        return XInputTokens().Has(t)
    }
    if RegExMatch(t, "^J[LR]S[UDLR]$")
        return JoyStickTokens().Has(t)
    if RegExMatch(t, "^J(\d{1,2})$", &m)
        return GetKeyState(joyId . "Joy" . m[1]) ? true : false
    return (GetPovName() = t)
}

WaitTriggerRelease(trig, ms) {
    ; Returns true if the trigger was released within ms milliseconds.
    clean := RegExReplace(Trim(trig), "^~")
    if IsJoyTrigger(clean) {
        startTick := A_TickCount
        while (A_TickCount - startTick < ms) {
            if (!JoyTriggerDown(clean))
                return true
            Sleep(5)
        }
        return false
    }
    return KeyWait(clean, "T" . (ms / 1000)) ? true : false
}

PollController() {
    global controllerEnabled, scriptEnabled, joyButtonState, joyPovState, xiPrev, jsPrev
    global targetExe, joyId, joyDetectTick
    global padPanic, padPanicStart, padPanicFired, chordDown

    if (!controllerEnabled)
        return

    active := scriptEnabled && (targetExe = "" || WinActive("ahk_exe " . targetExe))

    ; If target isn't active, drop any tracked state so the next press
    ; (or a currently-held button, once the window becomes active) is seen
    ; as a fresh edge.
    if (!active) {
        joyButtonState := Map()
        joyPovState := ""
        xiPrev := Map()
        jsPrev := Map()
        chordDown := Map()
        PadSwitchTick()   ; the controller on/off combo works even while the remapper is OFF
        return
    }

    if (UseDirect()) {
    ; Re-scan for a connected pad every 2 s if the current one has vanished
    if (A_TickCount - joyDetectTick > 2000) {
        joyDetectTick := A_TickCount
        curName := ""
        try curName := GetKeyState(joyId . "JoyName")
        if (curName = "")
            DetectJoyId()
    }

    ; --- Buttons ---
    loop 32 {
        n := A_Index
        state := GetKeyState(joyId . "Joy" . n) ? true : false
        prev := joyButtonState.Has(n) ? joyButtonState[n] : false
        if (state && !prev) {
            joyButtonState[n] := true
            HandlePress("J" . n)
        } else if (!state && prev) {
            joyButtonState[n] := false
            HandleRelease("J" . n)
        }
    }

    ; --- POV hat (digital) ---
    povName := GetPovName()
    if (povName != joyPovState) {
        if (joyPovState != "")
            HandleRelease(joyPovState)
        if (povName != "")
            HandlePress(povName)
        joyPovState := povName
    }

    ; --- Stick directions (DualShock etc.) as buttons ---
    if (JoyPresent()) {
        curS := JoyStickTokens()
        for tok, v in curS {
            if (!jsPrev.Has(tok))
                HandlePress(tok)
        }
        for tok, v in jsPrev.Clone() {
            if (!curS.Has(tok))
                HandleRelease(tok)
        }
        jsPrev := curS
    } else if (jsPrev.Count > 0) {
        for tok, v in jsPrev.Clone()
            HandleRelease(tok)
        jsPrev := Map()
    }

    }

    ; --- XInput (Xbox-style pads: buttons, separate triggers, stick directions) ---
    if (UseXInput() && XInputPoll()) {
        cur := XInputTokens()
        for tok, v in cur {
            if (!xiPrev.Has(tok))
                HandlePress(tok)
        }
        for tok, v in xiPrev.Clone() {
            if (!cur.Has(tok))
                HandleRelease(tok)
        }
        xiPrev := cur
    } else if (xiPrev.Count > 0) {
        for tok, v in xiPrev.Clone()
            HandleRelease(tok)
        xiPrev := Map()
    }

    ; --- Chord triggers (J5+J6, XLB+XRB ...): fire while every part is held ---
    for chordRow in rows {
        chordTrig := StrUpper(Trim(chordRow.trigger))
        if (!InStr(chordTrig, "+") || !IsJoyTrigger(chordTrig))
            continue
        allDown := true
        for part in StrSplit(chordTrig, "+") {
            if (!ChordPartDown(part)) {
                allDown := false
                break
            }
        }
        wasDown := chordDown.Has(chordTrig)
        if (allDown && !wasDown) {
            chordDown[chordTrig] := true
            HandlePress(chordTrig)
        } else if (!allDown && wasDown) {
            chordDown.Delete(chordTrig)
            HandleRelease(chordTrig)
        }
    }

    ; --- Controller on/off combo (default Start+Back / Share+Options, hold 1 second) ---
    PadSwitchTick()
}

; Everything the controller is holding right now, as tokens (XSTART, J9, JPOVUP ...)
PadSnapshot() {
    global joyId
    held := Map()
    if (UseXInput() && XInputPoll()) {
        for tok, v in XInputTokens()
            held[tok] := true
    }
    if (UseDirect()) {
        loop 32 {
            if GetKeyState(joyId . "Joy" . A_Index)
                held["J" . A_Index] := true
        }
        pov := StrUpper(GetPovName())
        if (pov != "")
            held[pov] := true
        if JoyPresent() {
            for tok, v in JoyStickTokens()
                held[tok] := true
        }
    }
    return held
}

PadSwitchHeld() {
    global padSwitchCombo
    held := PadSnapshot()
    combo := StrUpper(Trim(padSwitchCombo))
    if (combo = "") {
        if (held.Has("XSTART") && held.Has("XBACK"))
            return true
        return held.Has("J9") && held.Has("J10")
    }
    parts := 0
    for part in StrSplit(combo, "+") {
        part := Trim(part)
        if (part = "")
            continue
        parts += 1
        if !held.Has(part)
            return false
    }
    return parts > 0
}

; Hold the combo for 1 second: switches the remapper OFF, or back ON again.
PadSwitchTick() {
    global padPanic, padPanicStart, padPanicFired
    if (padPanic && PadSwitchHeld()) {
        if (padPanicStart = 0) {
            padPanicStart := A_TickCount
        } else if (!padPanicFired && A_TickCount - padPanicStart >= 1000) {
            padPanicFired := true
            ToggleScript()
        }
    } else {
        padPanicStart := 0
        padPanicFired := false
    }
}

; Settings "Detect" button: hold the buttons you want (together), then let go.
DetectPadSwitch(editCtrl, btn, *) {
    btn.Enabled := false
    btn.Text := LangT("Hold...")
    seen := Map()
    order := []
    anyHeld := false
    t0 := A_TickCount
    NotifyUser(LangT("Hold the controller buttons you want, then let go."), -6000)

    DetectTick() {
        held := PadSnapshot()
        if (held.Count > 0) {
            anyHeld := true
            for tok, v in held {
                if (!seen.Has(tok) && order.Length < 4) {
                    seen[tok] := true
                    order.Push(tok)
                }
            }
        }
        if ((anyHeld && held.Count = 0) || A_TickCount - t0 > 8000) {
            SetTimer(DetectTick, 0)
            if (order.Length > 0)
                editCtrl.Value := JoinArray(order, "+")
            btn.Text := LangT("Detect")
            btn.Enabled := true
        }
    }
    SetTimer(DetectTick, 30)
}

ChordPartDown(part) {
    global joyButtonState, joyPovState, jsPrev, xiPrev
    t := StrUpper(Trim(part))
    if RegExMatch(t, "^J(\d{1,2})$", &m)
        return joyButtonState.Has(Integer(m[1])) && joyButtonState[Integer(m[1])]
    if (t = joyPovState)
        return true
    return jsPrev.Has(t) || xiPrev.Has(t)
}

; ============================================================
; ---- System Tray Context Menu Engine ----
; ============================================================
BuildTrayMenu() {
    global currentProfile, compatMode, padType, autoProfile, langCode
    A_TrayMenu.Delete()

    ; ---- what you use every day ----
    A_TrayMenu.Add(LangT("Show / hide window"), ToggleMainWindow)
    A_TrayMenu.Default := LangT("Show / hide window")
    A_TrayMenu.Add(LangT("Remapper on / off"), ToggleScript)

    profileSub := Menu()
    for p in GetProfileList() {
        profileSub.Add(p, TraySelectProfile)
        if (p = currentProfile)
            profileSub.Check(p)
    }
    A_TrayMenu.Add(LangT("Switch profile"), profileSub)

    A_TrayMenu.Add(LangT("Key cheat sheet"), ToggleCheatSheet)
    pageSub := Menu()
    pageSub.Add(LangT("Next page"), LayerNext)
    pageSub.Add(LangT("Previous page"), LayerPrev)
    A_TrayMenu.Add(LangT("Pages"), pageSub)
    A_TrayMenu.Add()

    ; ---- setup ----
    A_TrayMenu.Add(LangT("Setup wizard..."), ShowWizard)
    A_TrayMenu.Add(LangT("Settings..."), (*) => OpenSettingsPanel())
    A_TrayMenu.Add(LangT("Accessibility tools..."), ShowAccessTools)

    ; ---- everything else, out of the way ----
    moreSub := Menu()
    moreSub.Add(LangT("Status box on / off"), ToggleOSDOverlay)
    moreSub.Add(LangT("Keyboard mouse on / off"), KmToggle)
    moreSub.Add(LangT("One-button control menu"), ScanToggleMenu)
    moreSub.Add(LangT("Customize look..."), ShowCustomize)
    moreSub.Add(LangT("Check combos..."), (*) => ShowComboCheck(true))
    moreSub.Add(LangT("Auto-switch profile by game"), ToggleAutoProfile)
    if (autoProfile)
        moreSub.Check(LangT("Auto-switch profile by game"))
    starterSub := Menu()
    for i, nm in StarterNames()
        starterSub.Add(nm, CreateStarterProfile.Bind(i))
    moreSub.Add(LangT("Create starter profile"), starterSub)
    compatSub := Menu()
    for i, nm in CompatModeNames() {
        compatSub.Add(nm, SetCompatMode.Bind(i))
        if (i = compatMode)
            compatSub.Check(nm)
    }
    moreSub.Add(LangT("Input mode"), compatSub)
    padSub := Menu()
    padSub.Add(LangT("Controller support on / off"), ToggleController)
    padTypeSub := Menu()
    for i, nm in PadTypeNames() {
        padTypeSub.Add(nm, SetPadType.Bind(i))
        if (i = padType)
            padTypeSub.Check(nm)
    }
    padSub.Add(LangT("Controller type"), padTypeSub)
    padSub.Add(LangT("Controller test..."), ShowControllerTest)
    moreSub.Add(LangT("Controller"), padSub)
    langSub := Menu()
    for item in LangList() {
        langSub.Add(item.name, LangPickItem.Bind(item.code))
        if (item.code = langCode)
            langSub.Check(item.name)
    }
    langSub.Add()
    langSub.Add(LangT("Export translation template..."), LangExportTemplate)
    langSub.Add(LangT("Add language file..."), LangAddFiles)
    langSub.Add(LangT("Open language folder"), LangOpenFolder)
    moreSub.Add("Language / Nyelv", langSub)
    moreSub.Add()
    moreSub.Add(LangT("Copy diagnostics"), CopyDiagnostics)
    moreSub.Add(LangT("Open log file"), OpenLogFile)
    A_TrayMenu.Add(LangT("More"), moreSub)
    A_TrayMenu.Add()

    A_TrayMenu.Add(LangT("Help..."), ShowHelp)
    A_TrayMenu.Add(LangT("About..."), ShowAbout)
    A_TrayMenu.Add()
    A_TrayMenu.Add(LangT("Exit"), (*) => ExitApp())
}

ShowAbout(*) {
    global creatorName, aiNote
    aboutGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox", LangT("About Combo ReMapper"))
    aboutGui.SetFont("s10", "Segoe UI")
    aboutGui.Add("Text", "w400", LangT("Combo ReMapper 9.7"))
    aboutGui.SetFont("s10 Bold", "Segoe UI")
    aboutGui.Add("Text", "w400 y+14", LangT("About the creator"))
    aboutGui.SetFont("s10 Norm", "Segoe UI")
    aboutGui.Add("Text", "w400 y+6", LangT("Made by ") . creatorName . LangT(".`n`nI'm handicapped, and I make these tools so that games and programs are easier for me, and for others, to play and use."))
    aboutGui.SetFont("s10 Bold", "Segoe UI")
    aboutGui.Add("Text", "w400 y+18", LangT("Made with AI"))
    aboutGui.SetFont("s10 Norm", "Segoe UI")
    aboutGui.Add("Text", "w400 y+6", LangT(aiNote))
    aboutGui.SetFont("s10 Bold", "Segoe UI")
    aboutGui.Add("Text", "w400 y+14", LangT("Why I say this"))
    aboutGui.SetFont("s10 Norm", "Segoe UI")
    aboutGui.Add("Text", "w400 y+6", LangT("- People should know how software is made.`n- I came up with the idea and decided how it works and what it should do; the AI wrote the code.`n- If something breaks, people know the code was written by an AI and may need checking.`n- It shows that people like me can build our own tools with AI."))
    aboutGui.SetFont("s9 Italic", "Segoe UI")
    aboutGui.Add("Text", "w400 y+14", LangT("Just a fun project. The hidden Cyber Red and Cyber Yellow themes are not affiliated with or endorsed by any company."))
    aboutGui.SetFont("s10 Norm", "Segoe UI")
    closeBtn := aboutGui.Add("Button", "y+18 w100 h30 Default", LangT("Close"))
    closeBtn.OnEvent("Click", (*) => aboutGui.Destroy())
    aboutGui.OnEvent("Close", (*) => aboutGui.Destroy())
    aboutGui.Show()
}

TraySelectProfile(itemText, *) {
    global profileDD
    if (profileDD != "") {
        profileDD.Choose(itemText)
        SwitchProfile(profileDD)
    }
}

ToggleController(*) {
    global controllerEnabled
    controllerEnabled := !controllerEnabled
    if (controllerEnabled) {
        StartControllerPolling()
        NotifyUser(LangT("Controller support: ON"))
    } else {
        StopControllerPolling()
        NotifyUser(LangT("Controller support: OFF"))
    }
}

; ============================================================
; ---- OSD Indicator Overlay Functions ----
; ============================================================
BuildOSD() {
    global osdGui, osdText, showOsd, osdLocked, osdX, osdY, osdSize, osdOpacity, osdBg
    if (!showOsd)
        return
    if (osdGui != "") {
        osdGui.Show("x" osdX " y" osdY " NoActivate")
        return
    }
    opts := "+AlwaysOnTop -Caption +ToolWindow" . (osdLocked ? " +E0x20" : "")
    osdGui := Gui(opts)
    osdGui.BackColor := osdBg
    osdGui.SetFont("s" . osdSize . " bold c00FF00", "Consolas")
    osdText := osdGui.Add("Text", "x10 y6 w" . Max(200, osdSize * 24) . " h" . (osdSize * 2 + 6), LangT("REMAPPER: ACTIVE"))
    OnMessage(0x0201, WM_LBUTTONDOWN)
    osdGui.Show("x" osdX " y" osdY " NoActivate")
    try WinSetTransparent(Round(osdOpacity * 2.55), osdGui)
}

WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    global osdGui, osdX, osdY, osdLocked, configFile
    if (osdGui != "" && hwnd = osdGui.Hwnd && !osdLocked) {
        PostMessage(0xA1, 2, 0, , osdGui)
        KeyWait("LButton")
        osdGui.GetPos(&osdX, &osdY)
        try {
            IniWrite(osdX, configFile, "Settings", "OsdX")
            IniWrite(osdY, configFile, "Settings", "OsdY")
        }
    }
}

; The status box also lists everything that is running by itself: toggles that are on (a dot) and
; turbo / auto-repeat rows (a circular arrow), one line each, so you can see what is on.
OsdRowLabel(trig) {
    label := StrUpper(trig)
    row := FindRow(trig)
    if (IsObject(row)) {
        note := row.HasOwnProp("note") ? Trim(row.note) : ""
        label := (note != "") ? note : (StrUpper(trig) . " > " . KeyListToString(row.keys))
    }
    return CheatTrim(label, 30)
}

OsdRunningLines() {
    global scriptEnabled, toggleActive, turboTimers, showOsdRunning
    lines := []
    if (!scriptEnabled || !showOsdRunning)
        return lines
    for trig, on in toggleActive {
        if (on)
            lines.Push("● " . OsdRowLabel(trig))
    }
    for trig, fn in turboTimers
        lines.Push("» " . OsdRowLabel(trig))
    if (lines.Length > 6) {
        extra := lines.Length - 5
        while (lines.Length > 5)
            lines.Pop()
        lines.Push("+" . extra . " ...")
    }
    return lines
}

UpdateOSD(msg, colorHex := "00FF00") {
    global osdGui, osdText, showOsd, osdX, osdY, osdSize, currentTheme, osdBg
    static prevLineCount := 1
    if (CyberTheme(currentTheme)) {
        ; cyber look: the colours follow the theme, and the wording says CYBER MODE
        look := CyberLook(currentTheme)
        colorHex := (colorHex = "00FF00") ? look["on"] : (colorHex = "FF0000") ? look["off"] : (colorHex = "00FFFF") ? look["info"] : colorHex
        if (msg = LangT("REMAPPER: ACTIVE"))
            msg := LangT("CYBER MODE: ON")
        else if (msg = LangT("REMAPPER: DISABLED"))
            msg := LangT("CYBER MODE: OFF")
        if (IsObject(osdGui))
            osdGui.BackColor := look["osdBg"]
    } else if (IsObject(osdGui)) {
        osdGui.BackColor := osdBg
    }
    running := OsdRunningLines()
    for runLine in running
        msg .= "`n" . runLine
    lineCount := 1 + running.Length
    if (!showOsd) {
        if (osdGui != "")
            osdGui.Hide()
        return
    }
    if (osdGui = "") {
        BuildOSD()
        prevLineCount := 1
    } else {
        osdGui.Show("x" osdX " y" osdY " NoActivate")
    }
    if (osdText != "") {
        osdText.SetFont("c" . colorHex)
        osdText.Value := msg
        if (lineCount != prevLineCount) {
            try osdText.Move(, , , lineCount * Round(osdSize * 1.9) + 6)
            try osdGui.Show("AutoSize NoActivate x" . osdX . " y" . osdY)
            prevLineCount := lineCount
        }
    }
}

ToggleOSDOverlay(*) {
    global showOsd, osdGui, scriptEnabled
    showOsd := !showOsd

    if (!showOsd && osdGui != "") {
        osdGui.Hide()
        NotifyUser(LangT("Indicator Overlay: OFF"))
    } else {
        UpdateOSD(scriptEnabled ? LangT("REMAPPER: ACTIVE") : LangT("REMAPPER: DISABLED"), scriptEnabled ? "00FF00" : "FF0000")
        NotifyUser(LangT("Indicator Overlay: ON"))
    }
}

; ============================================================
; ---- Mouse Axis Lock Functions ----
; ============================================================
ToggleYAxisLock(*) {
    global yAxisLocked, lockedYCoord
    yAxisLocked := !yAxisLocked
    if (yAxisLocked) {
        MouseGetPos(, &lockedYCoord)
        SetTimer(MaintainYLock, 10)
        NotifyUser(LangT("Y-Axis Locked"))
    } else {
        SetTimer(MaintainYLock, 0)
        NotifyUser(LangT("Y-Axis Unlocked"))
    }
}

MaintainYLock() {
    global lockedYCoord, targetExe
    if (targetExe != "" && !WinActive("ahk_exe " . targetExe))
        return
    MouseGetPos(&currentX)
    MouseMove(currentX, lockedYCoord, 0)
}

RegisterYLockHotkey() {
    global yLockKey, registeredYLockKey, yAxisLocked
    if (registeredYLockKey != "") {
        try Hotkey("*" registeredYLockKey, "Off")
        registeredYLockKey := ""
    }
    if (yLockKey = "") {
        ; Feature switched off: never leave the mouse stuck on a locked line
        if (yAxisLocked)
            ToggleYAxisLock()
        return
    }
    try {
        Hotkey("*" yLockKey, ToggleYAxisLock, "On")
        registeredYLockKey := yLockKey
    } catch {
        MsgBox(LangT("Failed to bind Y-axis lock key: ") . yLockKey, LangT("Combo ReMapper 9.7"), "Icon! 262144")
    }
}

; ============================================================
; ---- Registry Helper for Auto-Start ----
; ============================================================
; Runs schtasks.exe and returns its exit code; its text output goes into the "out" variable.
SchTasksRun(args, &out) {
    tmp := A_Temp "\ComboReMapper_schtasks.txt"
    try FileDelete(tmp)
    rc := -1
    try rc := RunWait(A_ComSpec ' /c schtasks.exe ' . args . ' > "' . tmp . '" 2>&1', , "Hide")
    out := ""
    try out := Trim(FileRead(tmp))
    try FileDelete(tmp)
    return rc
}

XmlEsc(text) {
    text := StrReplace(text, "&", "&amp;")
    text := StrReplace(text, "<", "&lt;")
    text := StrReplace(text, ">", "&gt;")
    return text
}

SetAutoStart(enable := true) {
    regKey := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
    appName := "AHK_ComboRemapper"
    taskName := "ComboReMapper_AutoStart"
    out := ""
    if (!enable) {
        try RegDelete(regKey, appName)
        SchTasksRun('/Delete /TN "' . taskName . '" /F', &out)
        return "off"
    }
    if (A_IsCompiled) {
        exeFile := A_ScriptFullPath
        exeArgs := "/autostart"
    } else {
        exeFile := A_AhkPath
        exeArgs := '"' . A_ScriptFullPath . '" /autostart'
    }
    ; 1) a scheduled task that starts at logon with the highest rights: no UAC prompt at every start,
    ;    and none of the default limits (not on battery, stop after 3 days) that stop a plain task
    if (A_IsAdmin) {
        domain := EnvGet("USERDOMAIN")
        if (domain = "")
            domain := A_ComputerName
        who := XmlEsc(domain . "\" . A_UserName)
        xml := '<?xml version="1.0" encoding="UTF-16"?>`r`n'
            . '<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">`r`n'
            . '<RegistrationInfo><Description>Combo ReMapper starts at logon</Description></RegistrationInfo>`r`n'
            . '<Triggers><LogonTrigger><Enabled>true</Enabled><UserId>' . who . '</UserId><Delay>PT5S</Delay></LogonTrigger></Triggers>`r`n'
            . '<Principals><Principal id="Author"><UserId>' . who . '</UserId><LogonType>InteractiveToken</LogonType><RunLevel>HighestAvailable</RunLevel></Principal></Principals>`r`n'
            . '<Settings><MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy><DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>'
            . '<StopIfGoingOnBatteries>false</StopIfGoingOnBatteries><AllowHardTerminate>true</AllowHardTerminate><StartWhenAvailable>true</StartWhenAvailable>'
            . '<RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable><AllowStartOnDemand>true</AllowStartOnDemand><Enabled>true</Enabled><Hidden>false</Hidden>'
            . '<ExecutionTimeLimit>PT0S</ExecutionTimeLimit><Priority>7</Priority></Settings>`r`n'
            . '<Actions Context="Author"><Exec><Command>' . XmlEsc(exeFile) . '</Command><Arguments>' . XmlEsc(exeArgs) . '</Arguments>'
            . '<WorkingDirectory>' . XmlEsc(A_ScriptDir) . '</WorkingDirectory></Exec></Actions>`r`n</Task>'
        xmlPath := A_Temp "\ComboReMapper_task.xml"
        rc := -1
        try {
            try FileDelete(xmlPath)
            f := FileOpen(xmlPath, "w", "UTF-16")
            f.Write(xml)
            f.Close()
            rc := SchTasksRun('/Create /TN "' . taskName . '" /XML "' . xmlPath . '" /F', &out)
        }
        try FileDelete(xmlPath)
        if (rc = 0) {
            try RegDelete(regKey, appName)
            LogEvent("Auto-start: scheduled task created for " . domain . "\" . A_UserName)
            return "task"
        }
        LogEvent("Auto-start: the scheduled task could not be created (code " . rc . "): " . out)
    }
    ; 2) a normal start-up entry (Windows may ask for administrator rights at each start)
    try {
        RegWrite('"' . exeFile . '" ' . exeArgs, "REG_SZ", regKey, appName)
        LogEvent("Auto-start: start-up entry written (not a scheduled task)")
        return "run"
    }
    LogEvent("Auto-start: nothing could be written")
    return "failed"
}

IsAutoStartEnabled() {
    regKey := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
    try {
        if (RegRead(regKey, "AHK_ComboRemapper") != "")
            return true
    }
    rc := 1
    try rc := RunWait('schtasks.exe /Query /TN "ComboReMapper_AutoStart"', , "Hide")
    return (rc = 0)
}

; Applies the check box at once (no need to press Save) and says what happened.
AutoStartClick(ctrl, *) {
    res := SetAutoStart(ctrl.Value)
    if (res = "task") {
        NotifyUser(LangT("Auto-start is on (starts at logon with administrator rights)."), -3000)
    } else if (res = "run") {
        NotifyUser(LangT("Auto-start is on (Windows may ask for administrator rights at each start)."), -3500)
    } else if (res = "off") {
        NotifyUser(LangT("Auto-start is off."), -2500)
    } else {
        ctrl.Value := 0
        NotifyUser(LangT("Auto-start could not be set."), -3500)
    }
}

; ============================================================
; ---- Load & Save State ----
; ============================================================
LoadState() {
    global rows, nextRowId, scrollTriggerKey, panicKey, osdToggleKey, targetExe, configFile, currentTheme, Themes, yLockKey
    global layerKey, layerPrevKey, layerPages, layerIdx, layerBase, cheatKey, layerReturning
    global keyDelayDuration, keyDelayPress, mouseDelayDuration, soundAlerts, showTooltips, showOsd, osdLocked, osdX, osdY
    global compatMode
    global pressExtraMs, padPanic, padType, padPort, padMouseStick, padScrollStick, padMouseSpeed, padMouseDead, padMouseCurve, autoDetectSecs, releaseOnBlur
    global padScrollSpeed, padTrigThresh, mouseScale, padSwitchCombo
    global customBgColor, customControlColor, customTextColor, controllerEnabled

    defaultRows := [
        ["F1", "l,1", "hold"],
        ["F2", "shift,w", "hold"],
        ["F3", "ctrl,c", "hold"],
        ["F4", "shift,space", "hold"],
        ["F5", "ctrl,shift", "hold"]
    ]

    rowCount := 5
    try rowCount := Integer(IniRead(configFile, "Meta", "RowCount", 5))
    if (rowCount < 0)
        rowCount := 0

    try scrollTriggerKey := IniRead(configFile, "Meta", "ScrollKey", "K")
    if (scrollTriggerKey = "(none)")
        scrollTriggerKey := ""

    try panicKey := IniRead(configFile, "Meta", "PanicKey", "F8")
    try osdToggleKey := IniRead(configFile, "Meta", "OsdKey", "F7")
    try yLockKey := IniRead(configFile, "Meta", "YLockKey", "F6")
    if (yLockKey = "(none)")
        yLockKey := ""
    if (layerBase = "" || layerReturning) {
        layerKey := ""
        layerPrevKey := ""
        layerPages := []
        layerIdx := 0
        pagesText := ""
        try layerKey := IniRead(configFile, "Meta", "LayerKey", "(none)")
        try layerPrevKey := IniRead(configFile, "Meta", "LayerPrevKey", "(none)")
        try pagesText := IniRead(configFile, "Meta", "LayerProfile", "(none)")
        try cheatKey := IniRead(configFile, "Meta", "CheatKey", "(none)")
        if (layerKey = "(none)")
            layerKey := ""
        if (layerPrevKey = "(none)")
            layerPrevKey := ""
        if (cheatKey = "(none)")
            cheatKey := ""
        for pageName in StrSplit(pagesText, "|") {
            pageName := Trim(pageName)
            if (pageName != "" && pageName != "(none)")
                layerPages.Push(pageName)
        }
    }
    try targetExe := IniRead(configFile, "Meta", "TargetExe", "")
    targetExe := NormalizeExe(targetExe)

    try currentTheme := IniRead(configFile, "Meta", "Theme", "Dark")
    if (!Themes.Has(currentTheme))
        currentTheme := "Dark"
    try customImg := IniRead(configFile, "Meta", "CustomImgPath", "")
    Themes["Custom Image"]["img"] := customImg

    try keyDelayDuration := Integer(IniRead(configFile, "Settings", "KeyDelayDuration", 20))
    try keyDelayPress := Integer(IniRead(configFile, "Settings", "KeyDelayPress", 20))
    try mouseDelayDuration := Integer(IniRead(configFile, "Settings", "MouseDelayDuration", 10))
    try compatMode := Max(1, Min(3, Integer(IniRead(configFile, "Settings", "CompatMode", 1))))
    try soundAlerts := (IniRead(configFile, "Settings", "SoundAlerts", "1") = "1")
    try showTooltips := (IniRead(configFile, "Settings", "ShowTooltips", "1") = "1")
    try showOsd := (IniRead(configFile, "Settings", "ShowOsd", "1") = "1")
    try osdLocked := (IniRead(configFile, "Settings", "OsdLocked", "1") = "1")
    try osdX := Integer(IniRead(configFile, "Settings", "OsdX", 20))
    try osdY := Integer(IniRead(configFile, "Settings", "OsdY", 20))
    try controllerEnabled := (IniRead(configFile, "Settings", "ControllerEnabled", "0") = "1")
    try padPort := Max(0, Min(4, Integer(IniRead(configFile, "Settings", "PadPort", 0))))
    try pressExtraMs := Max(0, Min(500, Integer(IniRead(configFile, "Settings", "PressExtraMs", 0))))
    try autoDetectSecs := Max(3, Min(120, Integer(IniRead(configFile, "Settings", "AutoDetectSecs", 10))))
    try releaseOnBlur := (IniRead(configFile, "Settings", "ReleaseOnBlur", "1") != "0")
    try padPanic := (IniRead(configFile, "Settings", "PadPanic", "1") = "1")
    try padSwitchCombo := StrUpper(Trim(IniRead(configFile, "Settings", "PadSwitchCombo", "")))
    try padType := Max(1, Min(3, Integer(IniRead(configFile, "Settings", "PadType", 1))))
    try padMouseStick := Max(0, Min(2, Integer(IniRead(configFile, "Settings", "PadMouseStick", 0))))
    try padScrollStick := Max(0, Min(2, Integer(IniRead(configFile, "Settings", "PadScrollStick", 0))))
    try padMouseSpeed := Max(50, Min(5000, Integer(IniRead(configFile, "Settings", "PadMouseSpeed", 900))))
    try padMouseDead := Max(0, Min(80, Integer(IniRead(configFile, "Settings", "PadMouseDead", 18))))
    try padMouseCurve := Max(1.0, Min(4.0, Float(IniRead(configFile, "Settings", "PadMouseCurve", "1.6"))))
    try padScrollSpeed := Max(1, Min(60, Integer(IniRead(configFile, "Settings", "PadScrollSpeed", 12))))
    try padTrigThresh := Max(5, Min(250, Integer(IniRead(configFile, "Settings", "PadTrigThresh", 40))))
    try mouseScale := Max(10, Min(500, Integer(IniRead(configFile, "Settings", "MouseScale", 100))))

    try customBgColor := IniRead(configFile, "Settings", "CustomBgColor", "1E1E1E")
    try customControlColor := IniRead(configFile, "Settings", "CustomControlColor", "2D2D2D")
    try customTextColor := IniRead(configFile, "Settings", "CustomTextColor", "FFFFFF")

    SetKeyDelay(keyDelayDuration, keyDelayPress)
    SetMouseDelay(mouseDelayDuration)
    UpdatePadMouseTimer()

    rows := []
    for i in Range(1, rowCount) {
        defTrigger := i <= defaultRows.Length ? defaultRows[i][1] : ""
        defCombo := i <= defaultRows.Length ? defaultRows[i][2] : ""
        defMode := i <= defaultRows.Length ? defaultRows[i][3] : "hold"

        trig := defTrigger
        combo := defCombo
        mode := defMode
        try trig := IniRead(configFile, "Row" . i, "Trigger", defTrigger)
        try combo := IniRead(configFile, "Row" . i, "Combo", defCombo)
        try mode := IniRead(configFile, "Row" . i, "Mode", defMode)
        enabledVal := "1"
        try enabledVal := IniRead(configFile, "Row" . i, "Enabled", "1")
        noteVal := ""
        try noteVal := IniRead(configFile, "Row" . i, "Note", "")
        turboMsVal := 60
        try turboMsVal := Integer(IniRead(configFile, "Row" . i, "TurboMs", 60))
        if (turboMsVal <= 0)
            turboMsVal := 60

        if (mode != "toggle" && mode != "press" && mode != "turbo" && mode != "autoturbo" && mode != "taphold" && mode != "doubletap")
            mode := "hold"

        rows.Push({id: i, trigger: Trim(trig), keys: ParseKeyList(combo), mode: mode, enabled: (enabledVal != "0"), turboMs: turboMsVal, note: noteVal})
    }
    nextRowId := rowCount + 1
    try DiagLog("Profile loaded: " . currentProfile . " (" . rows.Length . " rows)")
}

SaveStateToINI(targetFile) {
    global rows, scrollTriggerKey, panicKey, osdToggleKey, targetExe, currentTheme, Themes
    global autoDetectSecs, releaseOnBlur
    global layerKey, layerPrevKey, layerPages, layerBase, cheatKey
    global keyDelayDuration, keyDelayPress, mouseDelayDuration, soundAlerts, showTooltips, showOsd, osdLocked, osdX, osdY
    global compatMode
    global customBgColor, customControlColor, customTextColor, controllerEnabled

    try FileDelete(targetFile)

    IniWrite(rows.Length, targetFile, "Meta", "RowCount")
    IniWrite(scrollTriggerKey != "" ? scrollTriggerKey : "(none)", targetFile, "Meta", "ScrollKey")
    IniWrite(panicKey, targetFile, "Meta", "PanicKey")
    IniWrite(osdToggleKey, targetFile, "Meta", "OsdKey")
    IniWrite(yLockKey != "" ? yLockKey : "(none)", targetFile, "Meta", "YLockKey")
    if (layerBase = "") {
        IniWrite(layerKey != "" ? layerKey : "(none)", targetFile, "Meta", "LayerKey")
        IniWrite(layerPrevKey != "" ? layerPrevKey : "(none)", targetFile, "Meta", "LayerPrevKey")
        IniWrite(layerPages.Length > 0 ? JoinArray(layerPages, "|") : "(none)", targetFile, "Meta", "LayerProfile")
        IniWrite(cheatKey != "" ? cheatKey : "(none)", targetFile, "Meta", "CheatKey")
    }
    IniWrite(targetExe != "" ? targetExe : "(any)", targetFile, "Meta", "TargetExe")
    IniWrite(currentTheme, targetFile, "Meta", "Theme")
    IniWrite(Themes["Custom Image"]["img"], targetFile, "Meta", "CustomImgPath")

    IniWrite(keyDelayDuration, targetFile, "Settings", "KeyDelayDuration")
    IniWrite(keyDelayPress, targetFile, "Settings", "KeyDelayPress")
    IniWrite(mouseDelayDuration, targetFile, "Settings", "MouseDelayDuration")
    IniWrite(compatMode, targetFile, "Settings", "CompatMode")
    IniWrite(soundAlerts ? 1 : 0, targetFile, "Settings", "SoundAlerts")
    IniWrite(showTooltips ? 1 : 0, targetFile, "Settings", "ShowTooltips")
    IniWrite(showOsd ? 1 : 0, targetFile, "Settings", "ShowOsd")
    IniWrite(osdLocked ? 1 : 0, targetFile, "Settings", "OsdLocked")
    IniWrite(osdX, targetFile, "Settings", "OsdX")
    IniWrite(osdY, targetFile, "Settings", "OsdY")
    IniWrite(controllerEnabled ? 1 : 0, targetFile, "Settings", "ControllerEnabled")
    IniWrite(padPort, targetFile, "Settings", "PadPort")
    IniWrite(pressExtraMs, targetFile, "Settings", "PressExtraMs")
    IniWrite(autoDetectSecs, targetFile, "Settings", "AutoDetectSecs")
    IniWrite(releaseOnBlur ? 1 : 0, targetFile, "Settings", "ReleaseOnBlur")
    IniWrite(padPanic ? 1 : 0, targetFile, "Settings", "PadPanic")
    IniWrite(padSwitchCombo, targetFile, "Settings", "PadSwitchCombo")
    IniWrite(padType, targetFile, "Settings", "PadType")
    IniWrite(padMouseStick, targetFile, "Settings", "PadMouseStick")
    IniWrite(padScrollStick, targetFile, "Settings", "PadScrollStick")
    IniWrite(padMouseSpeed, targetFile, "Settings", "PadMouseSpeed")
    IniWrite(padMouseDead, targetFile, "Settings", "PadMouseDead")
    IniWrite(padMouseCurve, targetFile, "Settings", "PadMouseCurve")
    IniWrite(padScrollSpeed, targetFile, "Settings", "PadScrollSpeed")
    IniWrite(padTrigThresh, targetFile, "Settings", "PadTrigThresh")
    IniWrite(mouseScale, targetFile, "Settings", "MouseScale")

    IniWrite(customBgColor, targetFile, "Settings", "CustomBgColor")
    IniWrite(customControlColor, targetFile, "Settings", "CustomControlColor")
    IniWrite(customTextColor, targetFile, "Settings", "CustomTextColor")

    for i, row in rows {
        IniWrite(row.trigger, targetFile, "Row" . i, "Trigger")
        IniWrite(KeyListToString(row.keys), targetFile, "Row" . i, "Combo")
        IniWrite(row.mode, targetFile, "Row" . i, "Mode")
        IniWrite((row.HasOwnProp("enabled") && !row.enabled) ? 0 : 1, targetFile, "Row" . i, "Enabled")
        IniWrite(row.HasOwnProp("turboMs") ? row.turboMs : 60, targetFile, "Row" . i, "TurboMs")
        if (row.HasOwnProp("note") && row.note != "")
            IniWrite(row.note, targetFile, "Row" . i, "Note")
    }
}

LoadState()

; ============================================================
; ---- Dynamic Hotkeys ----
; Mouse buttons work through this same path. Keyboard rows use * or ~*.
; Gamepad triggers (J1..J32 / JPOV*) are handled by PollController() and
; skipped here.
; ============================================================
RegisterRowHotkeys() {
    global rows, registeredRowTriggers, rowHotkeysOn
    rowHotkeysOn := true
    for t in registeredRowTriggers {
        try Hotkey(t, "Off")
        try Hotkey(t " Up", "Off")
    }
    registeredRowTriggers := []

    for row in rows {
        if (row.trigger = "")
            continue
        if IsJoyTrigger(row.trigger)
            continue   ; handled by polling
        try {
            trig := row.trigger
            hkPrefix := (SubStr(trig, 1, 1) = "~") ? "~*" SubStr(trig, 2) : "*" trig
            Hotkey(hkPrefix, HandlePress.Bind(trig), "On")
            Hotkey(hkPrefix " Up", HandleRelease.Bind(trig), "On")
            registeredRowTriggers.Push(hkPrefix)
        }
    }
}

RegisterScrollHotkey() {
    global scrollTriggerKey, registeredScrollKey
    if (registeredScrollKey != "") {
        try Hotkey("*" registeredScrollKey, "Off")
        registeredScrollKey := ""
    }
    if (scrollTriggerKey != "") {
        try {
            Hotkey("*" scrollTriggerKey, HandleScrollPress, "On")
            registeredScrollKey := scrollTriggerKey
        }
    }
}

RegisterPanicHotkey() {
    global panicKey, registeredPanicKey
    if (registeredPanicKey != "") {
        try Hotkey("*" registeredPanicKey, "Off")
        registeredPanicKey := ""
    }
    if (panicKey != "") {
        try {
            Hotkey("*" panicKey, ToggleScript, "On")
            registeredPanicKey := panicKey
        } catch {
            MsgBox(LangT("Failed to bind panic key: ") . panicKey, LangT("Combo ReMapper 9.7"), "Icon! 262144")
        }
    }
}

RegisterOsdHotkey() {
    global osdToggleKey, registeredOsdKey
    if (registeredOsdKey != "") {
        try Hotkey("*" registeredOsdKey, "Off")
        registeredOsdKey := ""
    }
    if (osdToggleKey != "") {
        try {
            Hotkey("*" osdToggleKey, ToggleOSDOverlay, "On")
            registeredOsdKey := osdToggleKey
        } catch {
            MsgBox(LangT("Failed to bind OSD toggle key: ") . osdToggleKey, LangT("Combo ReMapper 9.7"), "Icon! 262144")
        }
    }
}

FindRow(triggerKey) {
    global rows
    for row in rows {
        if (row.trigger = triggerKey)
            return row
    }
    return ""
}

; ============================================================
; ---- Key / Mouse action engine ----
; ============================================================
ExecuteComboSequence(keysArray) {
    global seqHeldKeys
    for k in keysArray {
        cleanKey := Trim(k)
        if (cleanKey = "")
            continue

        if (IsInteger(cleanKey) && StrLen(cleanKey) > 1) {
            Sleep(Max(0, Integer(cleanKey)))
            continue
        }

        if RegExMatch(cleanKey, "i)^d(\d+)$", &match) {
            Sleep(Integer(match[1]))
            continue
        }

        lowerKey := StrLower(cleanKey)

        ; down:key / up:key  -> hold a key (or mouse button) across several steps
        if RegExMatch(cleanKey, "i)^(down|up):(\S+)$", &hm) {
            holdName := hm[2]
            if (StrLower(hm[1]) = "down") {
                GameKeyDown(holdName)
                seqHeldKeys[StrLower(holdName)] := holdName
            } else {
                GameKeyUp(holdName)
                seqHeldKeys.Delete(StrLower(holdName))
            }
            continue
        }

        ; burst:KEY,COUNT,GAP  = press KEY COUNT times, GAP ms apart (one-key button mash)
        if RegExMatch(cleanKey, "i)^burst:([^,\s]+)(?:,(\d+))?(?:,(\d+))?$", &bm) {
            RunBurst(bm[1], "", bm[2] != "" ? Integer(bm[2]) : 20, bm[3] != "" ? Integer(bm[3]) : 40)
            continue
        }

        ; alt:KEY1/KEY2,COUNT,GAP  = alternate two keys (left/right mash)
        if RegExMatch(cleanKey, "i)^alt:([^/,\s]+)/([^,\s]+)(?:,(\d+))?(?:,(\d+))?$", &am) {
            RunBurst(am[1], am[2], am[3] != "" ? Integer(am[3]) : 20, am[4] != "" ? Integer(am[4]) : 40)
            continue
        }

        ; hold:KEY,MS  = press and hold KEY for MS milliseconds, then let go
        if RegExMatch(cleanKey, "i)^hold:([^,\s]+)(?:,(\d+))?$", &ho) {
            holdName := ho[1]
            holdMs := ho[2] != "" ? Integer(ho[2]) : 500
            GameKeyDown(holdName)
            seqHeldKeys[StrLower(holdName)] := holdName
            Sleep(Max(10, holdMs))
            GameKeyUp(holdName)
            seqHeldKeys.Delete(StrLower(holdName))
            continue
        }

        ; Mouse action tokens
        if IsMouseActionToken(lowerKey) {
            RunMouseToken(lowerKey)
            continue
        }

        ; Regular key (including mouse button names)
        GameKeyDown(cleanKey)
        Sleep(GetPressHold())
        GameKeyUp(cleanKey)
    }
}

; Presses keyA (and keyB alternately, if given) count times with gap ms between presses.
; Stops early if the remapper is switched off with the panic key.
RunBurst(keyA, keyB, count, gap) {
    global scriptEnabled
    count := Max(1, Min(500, count))
    gap := Max(10, gap)
    loop count {
        if (!scriptEnabled)
            return
        name := (keyB != "" && Mod(A_Index, 2) = 0) ? keyB : keyA
        GameKeyDown(name)
        Sleep(GetPressHold())
        GameKeyUp(name)
        Sleep(gap)
    }
}

FireTurbo(triggerKey) {
    global heldCombos, scriptEnabled, turboTimers
    if (!scriptEnabled || !heldCombos.Has(triggerKey)) {
        if (turboTimers.Has(triggerKey)) {
            SetTimer(turboTimers[triggerKey], 0)
            turboTimers.Delete(triggerKey)
        }
        return
    }
    row := FindRow(triggerKey)
    if (row != "")
        ExecuteComboSequence(row.keys)
}

StopTurbo(triggerKey) {
    global turboTimers
    if (turboTimers.Has(triggerKey)) {
        SetTimer(turboTimers[triggerKey], 0)
        turboTimers.Delete(triggerKey)
    }
}

HandlePress(triggerKey, *) {
    global scriptEnabled, heldCombos, toggleActive, pressLatched, targetExe, turboTimers, mouseHeld
    global compatMode, seqHeldKeys
    if (!scriptEnabled || (targetExe != "" && !WinActive("ahk_exe " . targetExe))) {
        ignoredRow := FindRow(triggerKey)
        if (IsObject(ignoredRow))
            LogEvent(StrUpper(triggerKey) . "  ignored - " . (!scriptEnabled ? "script is OFF" : "target window not focused"), true)
        return
    }

    row := FindRow(triggerKey)
    if (row = "" || row.keys.Length = 0)
        return
    if (row.HasOwnProp("enabled") && !row.enabled) {
        LogEvent(StrUpper(triggerKey) . "  ignored - row is disabled", true)
        return
    }

    ; a new press (not key auto-repeat)
    freshPress := (!heldCombos.Has(triggerKey) && !pressLatched.Has(triggerKey))

    ; tremor filter: ignore accidental repeat presses
    if (freshPress && row.mode != "doubletap") {
        if (!TremorAllow(triggerKey)) {
            tremorIgnored[triggerKey] := true
            LogEvent(StrUpper(triggerKey) . "  ignored - tremor filter", true)
            return
        }
    }

    if (!heldCombos.Has(triggerKey) && !pressLatched.Has(triggerKey))
        LogEvent(StrUpper(triggerKey) . "  [" . row.mode . "]  ->  " . KeyListToString(row.keys) . "   (" . StrSplit(CompatModeNames()[compatMode], " ")[1] . " mode, " . (targetExe != "" ? "target focused" : "any window") . ")")

    if (row.mode = "taphold") {
        ; Tap (released within 250 ms) fires the first key; holding fires the second.
        released := WaitTriggerRelease(triggerKey, 250)
        if (released && row.keys.Length >= 1) {
            ExecuteComboSequence([row.keys[1]])
            FireFlash(row, triggerKey . " tap -> " . row.keys[1], "00FFFF", "  (tap)")
        } else if (!released && row.keys.Length >= 2) {
            ExecuteComboSequence([row.keys[2]])
            FireFlash(row, triggerKey . " hold -> " . row.keys[2], "00FFFF", "  (hold)")
        }
    } else if (row.mode = "doubletap") {
        ; Two presses within 350 ms fire the combo. Key auto-repeat is ignored via pressLatched.
        if (pressLatched.Has(triggerKey))
            return
        pressLatched[triggerKey] := true
        nowTick := A_TickCount
        lastTick := doubleTapLast.Has(triggerKey) ? doubleTapLast[triggerKey] : 0
        if (lastTick != 0 && nowTick - lastTick <= 350) {
            doubleTapLast[triggerKey] := 0
            ExecuteComboSequence(row.keys)
            FireFlash(row, triggerKey . " double-tap -> " . KeyListToString(row.keys), "00FFFF", "  (double-tap)")
        } else {
            doubleTapLast[triggerKey] := nowTick
        }
    } else if (row.mode = "autoturbo") {
        ; Press once: the combo repeats by itself. Press again: it stops.
        if (pressLatched.Has(triggerKey))
            return
        pressLatched[triggerKey] := true
        if (turboTimers.Has(triggerKey)) {
            StopTurbo(triggerKey)
            heldCombos.Delete(triggerKey)
            for k in row.keys {
                if RegExMatch(Trim(k), "i)^down:(\S+)$", &hm) {
                    try GameKeyUp(hm[1])
                    seqHeldKeys.Delete(StrLower(hm[1]))
                }
            }
            FireFlash(row, triggerKey . LangT(" AUTO OFF"), "FF6666", "  " . LangT("OFF"))
        } else {
            heldCombos[triggerKey] := true
            turboInterval := (row.HasOwnProp("turboMs") && row.turboMs > 0) ? row.turboMs : 60
            boundFn := FireTurbo.Bind(triggerKey)
            turboTimers[triggerKey] := boundFn
            SetTimer(boundFn, turboInterval)
            FireFlash(row, triggerKey . LangT(" AUTO ON (") . turboInterval . "ms)", "00FF66", "  " . LangT("ON"))
        }
    } else if (row.mode = "turbo") {
        if (heldCombos.Has(triggerKey))
            return
        heldCombos[triggerKey] := true
        turboInterval := (row.HasOwnProp("turboMs") && row.turboMs > 0) ? row.turboMs : 60
        boundFn := FireTurbo.Bind(triggerKey)
        turboTimers[triggerKey] := boundFn
        SetTimer(boundFn, turboInterval)
        FireFlash(row, triggerKey . " TURBO (" . turboInterval . "ms)")
    } else if (row.mode = "press") {
        if (pressLatched.Has(triggerKey))
            return
        pressLatched[triggerKey] := true
        ExecuteComboSequence(row.keys)
        FireFlash(row, triggerKey . " -> " . KeyListToString(row.keys))
    } else if (row.mode = "toggle") {
        if (pressLatched.Has(triggerKey))
            return
        pressLatched[triggerKey] := true

        isActive := toggleActive.Has(triggerKey) && toggleActive[triggerKey]
        for k in row.keys {
            cleanKey := Trim(k)
            lowerKey := StrLower(cleanKey)
            if (lowerKey = "mdown") {
                if (isActive) {
                    MouseButtonEvent("lbutton", false)
                    mouseHeld.Delete("lbutton")
                } else {
                    MouseButtonEvent("lbutton", true)
                    mouseHeld["lbutton"] := true
                }
                continue
            }
            if (lowerKey = "mup") {
                continue
            }
            if IsMouseActionToken(lowerKey)
                continue
            if (!IsPauseToken(cleanKey))
                try {
                    if (isActive)
                        GameKeyUp(cleanKey)
                    else
                        GameKeyDown(cleanKey)
                }
        }
        if (GetRowHoldMotion(row, &hvx, &hvy)) {
            if (isActive)
                StopHoldMotion(triggerKey)
            else
                StartHoldMotion(triggerKey, hvx, hvy)
        }
        toggleActive[triggerKey] := !isActive
        FireFlash(row, triggerKey . " " . (isActive ? "OFF" : "ON"), "00FFFF", isActive ? "  OFF" : "  ON")
    } else {
        ; hold mode
        if (heldCombos.Has(triggerKey))
            return
        heldCombos[triggerKey] := true
        if (GetRowHoldMotion(row, &hvx, &hvy))
            StartHoldMotion(triggerKey, hvx, hvy)
        for k in row.keys {
            ; Trigger released while a timed token was running: stop pressing keys
            if (!heldCombos.Has(triggerKey))
                break
            cleanKey := Trim(k)
            lowerKey := StrLower(cleanKey)
            if (lowerKey = "mdown") {
                MouseButtonEvent("lbutton", true)
                mouseHeld["lbutton"] := true
                continue
            }
            if IsHoldMotionToken(lowerKey)
                continue
            if IsMouseActionToken(lowerKey) {
                ; One-shot mouse actions fire immediately on hold-press
                RunMouseToken(lowerKey)
                continue
            }
            if (!IsPauseToken(cleanKey))
                try GameKeyDown(cleanKey)
        }
        if (!heldCombos.Has(triggerKey))
            StopHoldMotion(triggerKey)
        FireFlash(row, triggerKey . " -> " . KeyListToString(row.keys))
    }
}

HandleRelease(triggerKey, *) {
    global heldCombos, pressLatched, turboTimers, mouseHeld, tremorIgnored
    if (tremorIgnored.Has(triggerKey)) {
        tremorIgnored.Delete(triggerKey)
        return
    }

    row := FindRow(triggerKey)
    if (row = "")
        return

    if (row.mode = "turbo") {
        heldCombos.Delete(triggerKey)
        if (turboTimers.Has(triggerKey)) {
            SetTimer(turboTimers[triggerKey], 0)
            turboTimers.Delete(triggerKey)
        }
        SetTimer(CyberRefreshOSD, -50)
    } else if (row.mode = "toggle" || row.mode = "press" || row.mode = "taphold" || row.mode = "doubletap" || row.mode = "autoturbo") {
        pressLatched.Delete(triggerKey)
    } else {
        ; hold mode
        if (!heldCombos.Has(triggerKey))
            return
        heldCombos.Delete(triggerKey)
        StopHoldMotion(triggerKey)
        for k in row.keys {
            cleanKey := Trim(k)
            lowerKey := StrLower(cleanKey)
            if (lowerKey = "mdown") {
                MouseButtonEvent("lbutton", false)
                mouseHeld.Delete("lbutton")
                continue
            }
            if IsMouseActionToken(lowerKey)
                continue
            if (!IsPauseToken(cleanKey))
                try GameKeyUp(cleanKey)
        }
    }
}

RegisterRowHotkeys()

; ============================================================
; ---- Scroll Engine ----
; ============================================================
scrollSignalFile := dataDir "\scroll_signal.txt"

HandleScrollPress(*) {
    global scrollSignalFile, scriptEnabled, targetExe
    if (!scriptEnabled || (targetExe != "" && !WinActive("ahk_exe " . targetExe)))
        return

    try FileDelete(scrollSignalFile)
    FileAppend("scroll", scrollSignalFile)
    MouseWheelTick(-1)
}

RegisterScrollHotkey()

ToggleScript(*) {
    global scriptEnabled
    scriptEnabled := !scriptEnabled
    ; every step is guarded on its own, so one failing step can never leave the indicator on the wrong state
    if (!scriptEnabled) {
        try {
            ReleaseAllHeldCombos()
        } catch as e {
            LogEvent("Switch off: releasing held keys failed: " . e.Message, true)
        }
        try {
            KmForceOff()
        } catch as e {
            LogEvent("Switch off: keyboard mouse failed: " . e.Message, true)
        }
        try {
            ScanClose()
        } catch as e {
            LogEvent("Switch off: one-button control failed: " . e.Message, true)
        }
    }
    try {
        UpdateToggleButton()
    } catch as e {
        LogEvent("Updating the on/off button failed: " . e.Message, true)
    }
    try {
        UpdateOSD(scriptEnabled ? LangT("REMAPPER: ACTIVE") : LangT("REMAPPER: DISABLED"), scriptEnabled ? "00FF00" : "FF0000")
    } catch as e {
        LogEvent("Updating the status box failed: " . e.Message, true)
    }
    ; one more refresh a moment later, in case anything else drew over the status box
    SetTimer(CyberRefreshOSD, -200)
    LogEvent("Remapper switched " . (scriptEnabled ? "ON" : "OFF"), true)
    try NotifyUser(scriptEnabled ? LangT("Combo remapper: ON") : LangT("Combo remapper: OFF"))
}

RegisterPanicHotkey()
RegisterOsdHotkey()
RegisterYLockHotkey()
RegisterExtraHotkeys()

ReleaseAllHeldCombos() {
    global heldCombos, toggleActive, pressLatched, turboTimers, mouseHeld, seqHeldKeys, sentDown
    try KmReleaseAll()

    ; Stop all continuous mouse motion and abort any smooth-move / shake
    StopAllHoldMotion()

    ; Stop all turbo timers
    for tk, fn in turboTimers.Clone() {
        try SetTimer(fn, 0)
    }
    turboTimers := Map()

    for triggerKey in heldCombos.Clone() {
        row := FindRow(triggerKey)
        if (row != "") {
            for k in row.keys {
                cleanKey := Trim(k)
                lowerKey := StrLower(cleanKey)
                if (lowerKey = "mdown" || lowerKey = "mup")
                    continue
                if IsMouseActionToken(lowerKey)
                    continue
                if (!IsPauseToken(cleanKey))
                    try GameKeyUp(cleanKey)
            }
        }
    }
    heldCombos := Map()

    ; Keys held by down: tokens
    for lowName, realName in seqHeldKeys.Clone() {
        try GameKeyUp(realName)
    }
    seqHeldKeys := Map()

    for triggerKey in toggleActive.Clone() {
        if (toggleActive[triggerKey]) {
            row := FindRow(triggerKey)
            if (row != "") {
                for k in row.keys {
                    cleanKey := Trim(k)
                    lowerKey := StrLower(cleanKey)
                    if (lowerKey = "mdown" || lowerKey = "mup")
                        continue
                    if IsMouseActionToken(lowerKey)
                        continue
                    if (!IsPauseToken(cleanKey))
                        try GameKeyUp(cleanKey)
                }
            }
        }
    }
    toggleActive := Map()
    pressLatched := Map()
    SetTimer(CyberRefreshOSD, -50)

    ; Everything this program pressed and never let go of (for example when a row was edited
    ; or deleted while its keys were held): release exactly those keys.
    for lowKey, realKey in sentDown.Clone() {
        try {
            if (RegExMatch(lowKey, "^(lbutton|rbutton|mbutton|xbutton1|xbutton2)$"))
                MouseButtonEvent(lowKey, false)
            else
                SendKeyByMode(realKey, false)
        }
    }
    sentDown := Map()

    ; Release any mouse buttons the engine was holding
    ReleaseMouseHeldButtons()
}

HandleExit(*) {
    DiagLog("Exit")
    ReleaseAllHeldCombos()
    StopControllerPolling()
    DllCall("winmm\timeEndPeriod", "UInt", 1)
}

; Releases held combos if the game loses focus mid-hold (alt-tab etc.)
; With "Let go of everything..." on (default) toggles, auto-repeats, held mouse
; buttons and down: keys are stopped too, so nothing can get stuck.
AnyTrueInMap(m) {
    for k, v in m {
        if (v)
            return true
    }
    return false
}

; If keys are still down that this program pressed, but no row is holding or repeating anything
; any more, they are stuck (a stuck Ctrl or middle button makes a normal click open a new tab).
StuckKeyTick() {
    global sentDown, heldCombos, toggleActive, turboTimers, seqHeldKeys, mouseHeld, kmBtnHeld, stuckSince, scanOn
    if (sentDown.Count = 0) {
        stuckSince := 0
        return
    }
    if (heldCombos.Count > 0 || AnyTrueInMap(toggleActive) || turboTimers.Count > 0 || seqHeldKeys.Count > 0 || AnyTrueInMap(mouseHeld) || kmBtnHeld.Count > 0 || scanOn) {
        stuckSince := 0
        return
    }
    if (stuckSince = 0) {
        stuckSince := A_TickCount
        return
    }
    if (A_TickCount - stuckSince < 800)
        return
    names := ""
    for lowKey, realKey in sentDown
        names .= (names = "" ? "" : ", ") . realKey
    stuckSince := 0
    ReleaseAllHeldCombos()
    LogEvent("Released stuck keys: " . names, false)
}

; A modifier (Ctrl, Shift, Alt) or the middle button that Windows thinks is down while your fingers
; are not on it and this program is holding nothing is stuck. A stuck Ctrl or middle button makes a
; normal click open a link in a new tab, so it is let go after a short moment.
ModifierGuardTick() {
    global sentDown, heldCombos, toggleActive, turboTimers, seqHeldKeys, mouseHeld, kmBtnHeld, scanOn, modStuckSince
    stuck := ""
    for keyName in ["LControl", "RControl", "LShift", "RShift", "LAlt", "RAlt", "MButton"] {
        if (GetKeyState(keyName) && !GetKeyState(keyName, "P"))
            stuck .= (stuck = "" ? "" : ",") . keyName
    }
    busy := (sentDown.Count > 0 || heldCombos.Count > 0 || AnyTrueInMap(toggleActive) || turboTimers.Count > 0 || seqHeldKeys.Count > 0 || AnyTrueInMap(mouseHeld) || kmBtnHeld.Count > 0 || scanOn)
    if (stuck = "" || busy) {
        modStuckSince := 0
        return
    }
    if (modStuckSince = 0) {
        modStuckSince := A_TickCount
        return
    }
    if (A_TickCount - modStuckSince < 600)
        return
    modStuckSince := 0
    for keyName in StrSplit(stuck, ",") {
        try SendInput("{Blind}{" . keyName . " up}")
    }
    LogEvent("Released stuck modifiers: " . stuck, false)
}

FocusWatch() {
    global targetExe, heldCombos, toggleActive, turboTimers, seqHeldKeys, mouseHeld, releaseOnBlur
    try EditSafetyTick()
    try StuckKeyTick()
    try ModifierGuardTick()
    if (targetExe = "")
        return
    busy := (heldCombos.Count > 0)
    if (!busy && releaseOnBlur)
        busy := AnyTrueInMap(toggleActive) || (turboTimers.Count > 0) || (seqHeldKeys.Count > 0) || AnyTrueInMap(mouseHeld)
    if (!busy)
        return
    if WinActive("ahk_exe " . targetExe)
        return
    DiagLog("Game lost focus (" . targetExe . "): letting go of held inputs")
    LogEvent("FOCUS LOST - released held inputs", true)
    ReleaseAllHeldCombos()
}

; ============================================================
; ---- Profile Export / Import ----
; ============================================================
ExportProfile(*) {
    global rows, targetExe, panicKey, currentProfile
    global compatMode, padType, padPort, padMouseStick, padScrollStick, padMouseSpeed, padMouseDead, padMouseCurve
    global padScrollSpeed, padTrigThresh, mouseScale, keyDelayDuration, keyDelayPress, mouseDelayDuration
    global pressExtraMs, padPanic
    SyncBoxesToRows()

    outStr := "[REMAPPER_v8.24|NAME:" . currentProfile . "|EXE:" . targetExe . "|PANIC:" . panicKey . "]`n"
    for row in rows {
        if (row.trigger != "") {
            turboVal := row.HasOwnProp("turboMs") ? row.turboMs : 60
            enabledVal := (row.HasOwnProp("enabled") && !row.enabled) ? 0 : 1
            outStr .= row.trigger . ">" . KeyListToString(row.keys) . ">" . row.mode . ">" . turboVal . ">" . enabledVal . ";"
        }
    }
    ; Settings travel last, so older versions skip them as an unreadable row
    outStr .= "[SETTINGS|COMPAT:" . compatMode . "|PADTYPE:" . padType . "|PADPORT:" . padPort
        . "|STICK:" . padMouseStick . "|SSTICK:" . padScrollStick . "|SPEED:" . padMouseSpeed
        . "|DEAD:" . padMouseDead . "|CURVE:" . padMouseCurve . "|SSPEED:" . padScrollSpeed
        . "|TRIG:" . padTrigThresh . "|MSCALE:" . mouseScale . "|KD:" . keyDelayDuration
        . "|KP:" . keyDelayPress . "|MD:" . mouseDelayDuration . "|PEXTRA:" . pressExtraMs
        . "|PPANIC:" . (padPanic ? 1 : 0) . "|PCOMBO:" . padSwitchCombo . "]"

    A_Clipboard := outStr
    NotifyUser(LangT("Profile '") . currentProfile . LangT("' copied to clipboard!"))
}

ImportProfile(*) {
    global profileDD, profilesDir, currentProfile, configFile
    clipText := Trim(A_Clipboard)

    if (!RegExMatch(clipText, "^\[REMAPPER_v.*\|NAME:([^\|]+)\|EXE:([^\|]*)\|PANIC:([^\]]+)\]", &match)) {
        MsgBox(LangT("Invalid profile string in clipboard."), LangT("Import Error"), "Icon! 262144")
        return
    }

    pName := match[1]
    tExe := match[2]
    pPanic := match[3]

    body := SubStr(clipText, InStr(clipText, "`n") + 1)
    targetPath := profilesDir "\" pName ".ini"

    ; Optional settings block (v8.24+): input mode, controller type, stick/mouse tuning, delays
    settingsMap := Map()
    if RegExMatch(body, "\[SETTINGS\|([^\]]*)\]", &setMatch) {
        for pair in StrSplit(setMatch[1], "|") {
            kv := StrSplit(pair, ":", , 2)
            if (kv.Length = 2)
                settingsMap[kv[1]] := kv[2]
        }
        body := StrReplace(body, setMatch[0], "")
    }

    try FileDelete(targetPath)
    rowItems := StrSplit(body, ";")
    validRows := 0
    for item in rowItems {
        if (Trim(item) = "")
            continue
        parts := StrSplit(item, ">")
        if (parts.Length >= 3) {
            validRows++
            IniWrite(parts[1], targetPath, "Row" . validRows, "Trigger")
            IniWrite(parts[2], targetPath, "Row" . validRows, "Combo")
            IniWrite(parts[3], targetPath, "Row" . validRows, "Mode")
            if (parts.Length >= 5) {
                IniWrite(parts[4], targetPath, "Row" . validRows, "TurboMs")
                IniWrite(parts[5], targetPath, "Row" . validRows, "Enabled")
            }
        }
    }
    iniKeys := Map("COMPAT", "CompatMode", "PADTYPE", "PadType", "PADPORT", "PadPort", "STICK", "PadMouseStick"
        , "SSTICK", "PadScrollStick", "SPEED", "PadMouseSpeed", "DEAD", "PadMouseDead", "CURVE", "PadMouseCurve"
        , "SSPEED", "PadScrollSpeed", "TRIG", "PadTrigThresh", "MSCALE", "MouseScale", "KD", "KeyDelayDuration"
        , "KP", "KeyDelayPress", "MD", "MouseDelayDuration", "PEXTRA", "PressExtraMs", "PPANIC", "PadPanic", "PCOMBO", "PadSwitchCombo")
    for code, iniName in iniKeys {
        if settingsMap.Has(code)
            IniWrite(settingsMap[code], targetPath, "Settings", iniName)
    }
    IniWrite(validRows, targetPath, "Meta", "RowCount")
    IniWrite(pPanic, targetPath, "Meta", "PanicKey")
    IniWrite(tExe, targetPath, "Meta", "TargetExe")

    profileDD.OnEvent("Change", SwitchProfile, -1)
    profileDD.Delete()
    profileDD.Add(GetProfileList())
    profileDD.Choose(pName)
    profileDD.OnEvent("Change", SwitchProfile, 1)

    ; Importing over the profile that is open right now: stop SwitchProfile from
    ; saving the old in-memory state on top of the file we just wrote.
    if (StrLower(pName) = StrLower(currentProfile))
        configFile := ""

    SwitchProfile(profileDD)
    NotifyUser(LangT("Imported & Switched to profile '") . pName . "'!")
}

; ============================================================
; ---- Key & Mouse Recorder Engine ----
; Captures keyboard via InputHook, mouse buttons via hotkeys, and
; gamepad via a polling timer that runs while recording.
; ============================================================
CaptureSingleKey(targetEditControl) {
    global captureHook, autoDetectSecs
    try captureHook.Stop()
    captureHook := InputHook("T" . autoDetectSecs)
    captureHook.KeyOpt("{All}", "E")
    captureHook.OnEnd := CaptureSingleKeyDone.Bind(targetEditControl)
    NotifyUser(LangT("Press the key you want to bind (") . autoDetectSecs . LangT(" seconds)..."), -3000)
    captureHook.Start()
}

CaptureSingleKeyDone(targetEditControl, hook) {
    keyName := hook.EndKey
    if (keyName = "") {
        NotifyUser(LangT("No key was pressed - nothing changed."))
        return
    }
    if (keyName = "Escape") {
        NotifyUser(LangT("Binding cancelled."))
        return
    }
    try targetEditControl.Text := keyName
    NotifyUser(LangT("Bound key: ") . keyName)
}

StartKeyRecorder(slotIdx, *) {
    global rowUI, registeredRowTriggers, scriptEnabled
    global controllerEnabled, joyId, autoDetectSecs

    targetTrigger := StrLower(Trim(rowUI[slotIdx].tb.Text))
    targetCB := rowUI[slotIdx].cb
    targetBtn := rowUI[slotIdx].autoBtn

    targetBtn.Text := LangT("[REC]")
    targetBtn.Enabled := false

    for t in registeredRowTriggers {
        try Hotkey(t, "Off")
        try Hotkey(t " Up", "Off")
    }

    recordedKeys := Map()
    keyList := []

    UpdateOSD(LangT("RECORDING INPUTS..."), "FFFF00")
    NotifyUser(LangT("RECORDING... Press keys, mouse buttons, or gamepad! (") . autoDetectSecs . LangT(" seconds)"), -autoDetectSecs * 1000)

    mouseButtons := ["LButton", "RButton", "MButton", "XButton1", "XButton2", "WheelUp", "WheelDown"]

    RecordMouse(mName, *) {
        mLower := StrLower(mName)
        if (!recordedKeys.Has(mLower)) {
            recordedKeys[mLower] := true
            keyList.Push(mLower)
            targetCB.Text := JoinArray(keyList, ",")
            UpdateOSD(LangT("CAPTURED: ") . StrUpper(mLower), "00FFFF")
        }
    }

    ; Only wait if LButton is currently down (e.g. user clicked the Auto button).
    ; Short timeout prevents a hang if the button was activated via keyboard.
    if GetKeyState("LButton", "P")
        KeyWait("LButton", "T0.5")

    for mKey in mouseButtons {
        try Hotkey("~*" mKey, RecordMouse.Bind(mKey), "On")
    }

    ; --- Gamepad polling during recording ---
    joyPrev := Map()
    povPrev := ""
    xiRecPrev := Map()
    jsRecPrev := Map()

    JoyCaptureTick() {
        if (!controllerEnabled)
            return
        if (UseXInput() && XInputPoll()) {
            curTok := XInputTokens()
            for tok, v in curTok {
                if (!xiRecPrev.Has(tok)) {
                    tLower := StrLower(tok)
                    if (tLower != targetTrigger && !recordedKeys.Has(tLower)) {
                        recordedKeys[tLower] := true
                        keyList.Push(tLower)
                        targetCB.Text := JoinArray(keyList, ",")
                        UpdateOSD(LangT("CAPTURED: ") . StrUpper(tLower), "00FFFF")
                    }
                }
            }
            xiRecPrev := curTok
            return
        }
        if (!UseDirect())
            return
        loop 32 {
            n := A_Index
            state := GetKeyState(joyId . "Joy" . n) ? true : false
            prev := joyPrev.Has(n) ? joyPrev[n] : false
            if (state && !prev) {
                joyPrev[n] := true
                token := "J" . n
                tLower := StrLower(token)
                if (tLower != targetTrigger && !recordedKeys.Has(tLower)) {
                    recordedKeys[tLower] := true
                    keyList.Push(tLower)
                    targetCB.Text := JoinArray(keyList, ",")
                    UpdateOSD(LangT("CAPTURED: ") . StrUpper(tLower), "00FFFF")
                }
            } else if (!state && prev) {
                joyPrev[n] := false
            }
        }
        povName := StrLower(GetPovName())
        if (povName != povPrev) {
            if (povName != "" && povName != targetTrigger && !recordedKeys.Has(povName)) {
                recordedKeys[povName] := true
                keyList.Push(povName)
                targetCB.Text := JoinArray(keyList, ",")
                UpdateOSD(LangT("CAPTURED: ") . StrUpper(povName), "00FFFF")
            }
            povPrev := povName
        }
        curStick := JoyStickTokens()
        for tok, v in curStick {
            if (!jsRecPrev.Has(tok)) {
                tLower := StrLower(tok)
                if (tLower != targetTrigger && !recordedKeys.Has(tLower)) {
                    recordedKeys[tLower] := true
                    keyList.Push(tLower)
                    targetCB.Text := JoinArray(keyList, ",")
                    UpdateOSD(LangT("CAPTURED: ") . StrUpper(tLower), "00FFFF")
                }
            }
        }
        jsRecPrev := curStick
    }

    SetTimer(JoyCaptureTick, 15)

    ih := InputHook("V L0 T" . autoDetectSecs)
    ih.KeyOpt("{All}", "+N")

    HandleKeyDown(hook, vk, sc) {
        keyName := StrLower(GetKeyName(Format("vk{:x}sc{:x}", vk, sc)))
        if (keyName != "" && !recordedKeys.Has(keyName)) {
            recordedKeys[keyName] := true
            keyList.Push(keyName)
            targetCB.Text := JoinArray(keyList, ",")
            UpdateOSD(LangT("CAPTURED: ") . StrUpper(keyName), "00FFFF")
        }
    }
    ih.OnKeyDown := HandleKeyDown

    HandleEnd(*) {
        SetTimer(JoyCaptureTick, 0)
        for mKey in mouseButtons {
            try Hotkey("~*" mKey, "Off")
        }
        targetBtn.Text := LangT("Auto")
        targetBtn.Enabled := true
        RegisterRowHotkeys()
        UpdateOSD(scriptEnabled ? LangT("REMAPPER: ACTIVE") : LangT("REMAPPER: DISABLED"), scriptEnabled ? "00FF00" : "FF0000")
        ToolTip()
    }
    ih.OnEnd := HandleEnd

    ih.Start()
}

StartTriggerRecorder(slotIdx, *) {
    global rowUI, registeredRowTriggers, scriptEnabled, autoDetectSecs, trigRecHook
    tb := rowUI[slotIdx].tb
    btn := rowUI[slotIdx].trigBtn
    btn.Text := "..."
    btn.Enabled := false
    for t in registeredRowTriggers {
        try Hotkey(t, "Off")
        try Hotkey(t " Up", "Off")
    }
    UpdateOSD(LangT("PRESS THE TRIGGER KEY..."), "FFFF00")
    NotifyUser(LangT("Press the key or mouse button to use as the trigger (") . autoDetectSecs . LangT(" seconds)..."), -autoDetectSecs * 1000)
    mouseButtons := ["RButton", "MButton", "XButton1", "XButton2", "WheelUp", "WheelDown"]

    TrigPick(name) {
        tb.Text := StrLower(name)
        UpdateOSD(LangT("TRIGGER: ") . StrUpper(name), "00FFFF")
        try trigRecHook.Stop()
    }

    TrigMouse(mName, *) {
        TrigPick(mName)
    }

    ; the click that pressed the Set button must not count
    if GetKeyState("LButton", "P")
        KeyWait("LButton", "T0.5")
    for mKey in mouseButtons {
        try Hotkey("~*" mKey, TrigMouse.Bind(mKey), "On")
    }
    try trigRecHook.Stop()
    trigRecHook := InputHook("V L0 T" . autoDetectSecs)
    trigRecHook.KeyOpt("{All}", "+N+S")

    TrigKeyDown(hook, vk, sc) {
        keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
        if (keyName = "")
            return
        if (keyName = "Escape") {
            try trigRecHook.Stop()
            return
        }
        TrigPick(keyName)
    }
    trigRecHook.OnKeyDown := TrigKeyDown

    TrigEnd(*) {
        for mKey in mouseButtons {
            try Hotkey("~*" mKey, "Off")
        }
        btn.Text := LangT("Set")
        btn.Enabled := true
        RegisterRowHotkeys()
        UpdateOSD(scriptEnabled ? LangT("REMAPPER: ACTIVE") : LangT("REMAPPER: DISABLED"), scriptEnabled ? "00FF00" : "FF0000")
        ToolTip()
    }
    trigRecHook.OnEnd := TrigEnd
    trigRecHook.Start()
}

; ============================================================
; GUI ENGINE & SETTINGS PANEL
; ============================================================
BuildGUI() {
    global myGui, rowUI, rowSlider, scrollLabel, panicKeyBox, scrollKeyBox, targetExeBox, applyBtn, toggleBtn, statusBadge, statusText, scrollUpBtn, scrollDownBtn
    global profileDD, themeDD, bgPicControl, textControls, VISIBLE_ROWS, panicKey, scrollTriggerKey, targetExe, scriptEnabled, currentProfile, currentTheme, cyberUnlocked

    myGui := Gui("+Resize -MaximizeBox", LangT("Combo ReMapper 9.7"))
    myGui.SetFont("s10")
    myGui.OnEvent("Close", (*) => ExitApp())

    textControls := []
    bgPicControl := myGui.Add("Picture", "x0 y0 w570 h630 +0x4000000 Hidden", "")

    OnMessage(0x020A, OnMouseWheel)

    t1 := myGui.Add("Text", "x10 y12 w45 h24 +0x200 +BackgroundTrans", LangT("Profile:"))
    textControls.Push(t1)

    profileDD := myGui.Add("DropDownList", "x55 y12 w80", GetProfileList())
    try profileDD.Choose(currentProfile)
    catch
        try profileDD.Choose(1)
    profileDD.OnEvent("Change", SwitchProfile)

    newProfBtn := myGui.Add("Button", "x138 y11 w38 h24", LangT("+New"))
    newProfBtn.OnEvent("Click", CreateNewProfile)

    delProfBtn := myGui.Add("Button", "x178 y11 w38 h24", LangT("-Del"))
    delProfBtn.OnEvent("Click", DeleteProfile)

    expBtn := myGui.Add("Button", "x218 y11 w38 h24", LangT("Exp"))
    expBtn.OnEvent("Click", ExportProfile)

    impBtn := myGui.Add("Button", "x258 y11 w38 h24", LangT("Imp"))
    impBtn.OnEvent("Click", ImportProfile)

    settingsBtn := myGui.Add("Button", "x298 y11 w55 h24", LangT("Settings"))
    settingsBtn.OnEvent("Click", OpenSettingsPanel)

    t2 := myGui.Add("Text", "x358 y12 w42 h24 +0x200 +0x100 +BackgroundTrans", LangT("Theme:"))
    textControls.Push(t2)

    themeItems := ["Dark", "Light", "Custom Image"]
    for nm in ["Cyber Red", "Cyber Yellow"] {
        if (currentTheme = nm || CyberIsUnlocked(nm)) {
            themeItems.Push(nm)
            cyberUnlocked[nm] := true
        }
    }
    themeDD := myGui.Add("DropDownList", "x402 y12 w100", themeItems)
    try themeDD.Choose(currentTheme)
    catch
        try themeDD.Choose(1)
    themeDD.OnEvent("Change", ChangeTheme)

    t3 := myGui.Add("Text", "xm y+15 w80 +BackgroundTrans", LangT("Trigger key"))
    tOn := myGui.Add("Text", "x+3 yp w20 +BackgroundTrans", LangT("On"))
    t4 := myGui.Add("Text", "x+3 yp w131 +BackgroundTrans", LangT("Holds/Executes keys"))
    t5 := myGui.Add("Text", "x+50 yp w65 +BackgroundTrans", LangT("Mode"))
    textControls.Push(t3, tOn, t4, t5)

    rowUI := []
    loop VISIBLE_ROWS {
        slotIdx := A_Index
        yOpt := (slotIdx = 1) ? "xm y+8" : "xm y+6"

        tb := myGui.Add("Edit", yOpt . " w52")
        trigBtn := myGui.Add("Button", "x+2 yp w28 h22", LangT("Set"))
        enChk := myGui.Add("Checkbox", "x+3 yp+2 w16 h16 Checked", "")
        cb := myGui.Add("Edit", "x+3 yp-2 w131")
        autoBtn := myGui.Add("Button", "x+5 yp w42 h22", LangT("Auto"))
        dd := myGui.Add("DropDownList", "x+5 yp w" . (langCode = "en" ? 75 : 92), [LangMode("Hold"), LangMode("Toggle"), LangMode("Press"), LangMode("Turbo"), LangMode("TapHold"), LangMode("DblTap"), LangMode("TglTurbo")])
        optsBtn := myGui.Add("Button", "x+2 yp w24 h22", "...")
        remBtn := myGui.Add("Button", "x+2 yp w45 h22", LangT("Rem"))

        autoBtn.OnEvent("Click", StartKeyRecorder.Bind(slotIdx))
        trigBtn.OnEvent("Click", StartTriggerRecorder.Bind(slotIdx))
        AddTip(trigBtn, LangT("Press this, then press the key or mouse button you want as the trigger. It fills the box for you."))
        optsBtn.OnEvent("Click", OpenOptionsMenu.Bind(slotIdx))
        remBtn.OnEvent("Click", RemoveRowSlot.Bind(slotIdx))
        enChk.OnEvent("Click", (*) => SyncBoxesToRows())

        rowUI.Push({tb: tb, trigBtn: trigBtn, cb: cb, autoBtn: autoBtn, dd: dd, optsBtn: optsBtn, remBtn: remBtn, enChk: enChk})
    }

    scrollUpBtn := myGui.Add("Button", "x480 y46 w28 h22", "▲")
    rowSlider := myGui.Add("Slider", "x480 y70 w28 h175 Vertical TickInterval1 Range0-0", 0)
    rowSlider.OnEvent("Change", HandleSliderChange)
    scrollDownBtn := myGui.Add("Button", "x480 y247 w28 h22", "▼")

    scrollUpBtn.OnEvent("Click", (*) => ScrollRowsBy(-1))
    scrollDownBtn.OnEvent("Click", (*) => ScrollRowsBy(1))

    scrollLabel := myGui.Add("Text", "xm y+10 w450 +BackgroundTrans", "")
    textControls.Push(scrollLabel)

    addRowBtn := myGui.Add("Button", "xm y+10 w140 h26", LangT("+ Add Combo"))
    addRowBtn.OnEvent("Click", AddRow)

    t6 := myGui.Add("Text", "xm y+14 w130 +BackgroundTrans", LangT("Panic Toggle key:"))
    textControls.Push(t6)
    panicKeyBox := myGui.Add("Edit", "x+5 yp-4 w60", panicKey)
    panicCapBtn := myGui.Add("Button", "x+2 yp w72 h22", LangT("Bind"))
    panicCapBtn.OnEvent("Click", (*) => CaptureSingleKey(panicKeyBox))

    t7 := myGui.Add("Text", "x+10 yp+4 w95 +BackgroundTrans", LangT("Scroll-click key:"))
    textControls.Push(t7)
    scrollKeyBox := myGui.Add("Edit", "x+5 yp-4 w45", scrollTriggerKey)
    scrollCapBtn := myGui.Add("Button", "x+2 yp w72 h22", LangT("Bind"))
    scrollCapBtn.OnEvent("Click", (*) => CaptureSingleKey(scrollKeyBox))

    t8 := myGui.Add("Text", "xm y+14 w130 +BackgroundTrans", LangT("Target Exe filter:"))
    t9 := myGui.Add("Text", "x+5 yp +BackgroundTrans", LangT("(blank/any)"))
    textControls.Push(t8, t9)
    targetExeBox := myGui.Add("Edit", "x+5 yp-4 w130", targetExe)

    applyBtn := myGui.Add("Button", "xm y+14 w120 h30", LangT("Apply"))
    applyBtn.OnEvent("Click", ApplyChanges)

    toggleBtn := myGui.Add("Button", "x+10 yp w110 h30", scriptEnabled ? LangT("Turn OFF") : LangT("Turn ON"))
    toggleBtn.OnEvent("Click", ToggleScript)

    statusBadge := myGui.Add("Text", "x+8 yp+2 w80 h26 +0x200 +Center +Border +BackgroundTrans", LangT("ON"))
    statusBadge.SetFont("s10 bold c00FF00")

    statusText := myGui.Add("Text", "xm y+15 w460 +BackgroundTrans", "")
    textControls.Push(statusText)

    ApplyTheme(currentTheme)
    BuildTrayMenu()
    BuildOSD()
    myGui.Show("w520 h580")
}

; ---- Settings Panel Modal ----
; ---- AUTO PROFILE BLOCK BEGIN ----
GotoProfile(name) {
    ; Switches to a profile by name (rebuilds the dropdown first so new profiles are listed).
    global profileDD
    try {
        profileDD.OnEvent("Change", SwitchProfile, -1)
        profileDD.Delete()
        profileDD.Add(GetProfileList())
        profileDD.Choose(name)
        profileDD.OnEvent("Change", SwitchProfile, 1)
        SwitchProfile(profileDD)
        return true
    } catch as err {
        LogEvent("* Could not switch to profile '" . name . "': " . err.Message)
        return false
    }
}

AutoProfileTick() {
    ; Switches to the profile whose Target EXE matches the window in front.
    ; Does nothing when no profile matches, so alt-tabbing to the desktop keeps your profile.
    global autoProfile, autoProfLastExe, profilesDir, profileDD, targetExe, currentProfile
    if (!autoProfile)
        return
    exe := ""
    try exe := WinGetProcessName("A")
    if (exe = "" || exe = autoProfLastExe)
        return
    autoProfLastExe := exe
    ownExe := ""
    SplitPath(A_IsCompiled ? A_ScriptFullPath : A_AhkPath, &ownExe)
    if (StrLower(exe) = StrLower(ownExe))
        return
    curExe := NormalizeExe(targetExe)
    if (curExe != "" && StrLower(curExe) = StrLower(exe))
        return
    for name in GetProfileList() {
        tExe := ""
        try tExe := NormalizeExe(IniRead(profilesDir "\" name ".ini", "Meta", "TargetExe", "(any)"))
        if (tExe != "" && StrLower(tExe) = StrLower(exe)) {
            if (name = currentProfile)
                return
            if GotoProfile(name)
                NotifyUser(LangT("Auto-switched to profile '") . name . LangT("' for ") . exe)
            return
        }
    }
}

ToggleAutoProfile(*) {
    global autoProfile, autoProfLastExe, globalSettingsFile
    autoProfile := !autoProfile
    autoProfLastExe := ""
    try IniWrite(autoProfile ? 1 : 0, globalSettingsFile, "Global", "AutoProfile")
    BuildTrayMenu()
    NotifyUser(LangT("Auto-switch profile by game: ") . (autoProfile ? LangT("ON") : LangT("OFF")))
}
; ---- AUTO PROFILE BLOCK END ----

; ---- COMBO CHECK BLOCK BEGIN ----
IsValidKeyName(name) {
    n := Trim(name)
    if (n = "")
        return false
    low := StrLower(n)
    if (low = "wheelup" || low = "wheeldown" || low = "wheelleft" || low = "wheelright")
        return true
    return GetKeyName(n) != ""
}

IsValidTrigger(trig) {
    t := RegExReplace(Trim(trig), "^[~*$]+")
    if (t = "")
        return false
    if InStr(t, " & ") {
        for part in StrSplit(t, " & ") {
            if (!IsValidKeyName(part))
                return false
        }
        return true
    }
    if (IsJoyTrigger(t))
        return true
    return IsValidKeyName(t)
}

ValidateRows() {
    ; Looks for mistakes. Duplicate triggers are already blocked when you press Apply.
    global rows
    warnings := []
    for i, row in rows {
        trig := Trim(row.trigger)
        if (trig = "" || (row.HasOwnProp("enabled") && !row.enabled))
            continue
        label := "Row " . i . " (" . trig . ")"
        if (!IsValidTrigger(trig))
            warnings.Push(label . ": '" . trig . LangT("' is not a key, mouse button or controller button name"))
        if (row.keys.Length = 0) {
            warnings.Push(label . LangT(": no keys to send"))
            continue
        }
        if (row.mode = "taphold" && row.keys.Length < 2)
            warnings.Push(label . LangT(": TapHold needs two keys (first = tap, second = hold)"))
        for k in row.keys {
            tok := Trim(k)
            if (tok = "")
                continue
            low := StrLower(tok)
            if (IsPauseToken(tok))
                continue
            if (IsJoyTrigger(tok)) {
                warnings.Push(label . ": '" . tok . LangT("' is a controller button and cannot be sent as output"))
                continue
            }
            if (IsMacroToken(tok)) {
                if (row.mode = "hold" || row.mode = "toggle")
                    warnings.Push(label . ": '" . tok . LangT("' does nothing in Hold or Toggle rows (use Press, Turbo, TglTurbo or DblTap)"))
                if RegExMatch(tok, "i)^alt:([^/,\s]+)/([^,\s]+)(?:,\d+){0,2}$", &mk) {
                    if (!IsValidKeyName(mk[1]) || !IsValidKeyName(mk[2]))
                        warnings.Push(label . LangT(": unknown key name in '") . tok . "'")
                } else if RegExMatch(tok, "i)^(burst|hold):([^,\s]+)(?:,\d+){0,2}$", &mk) {
                    if (!IsValidKeyName(mk[2]))
                        warnings.Push(label . LangT(": unknown key name in '") . tok . "'")
                } else {
                    warnings.Push(label . ": '" . tok . LangT("' is not written correctly (burst:x,30,40   alt:x/c,30,40   hold:x,800)"))
                }
                continue
            }
            if RegExMatch(tok, "i)^(down|up):(\S+)$", &hm) {
                if (!IsValidKeyName(hm[2]))
                    warnings.Push(label . LangT(": unknown key name '") . hm[2] . LangT("' in '") . tok . "'")
                if (row.mode = "hold" || row.mode = "toggle")
                    warnings.Push(label . ": '" . tok . LangT("' does nothing in Hold or Toggle rows (use Press, Turbo or TglTurbo)"))
                continue
            }
            if (IsMouseActionToken(low)) {
                if (IsHoldMotionToken(low) && row.mode != "hold" && row.mode != "toggle")
                    warnings.Push(label . ": '" . tok . LangT("' only works in Hold or Toggle rows"))
                continue
            }
            if (!IsValidKeyName(tok))
                warnings.Push(label . LangT(": unknown key name '") . tok . "'")
        }
    }
    return warnings
}

ShowComboCheck(always := false) {
    SyncBoxesToRows()
    warnings := ValidateRows()
    if (warnings.Length = 0) {
        if (always)
            MsgBox(LangT("No problems found in your combos."), LangT("Combo check"), "Iconi 262144")
        return
    }
    text := ""
    for i, w in warnings {
        LogEvent("* check: " . w)
        if (i <= 14)
            text .= "- " . w . "`n"
    }
    if (warnings.Length > 14)
        text .= LangT("...and ") . (warnings.Length - 14) . LangT(" more (see the log file).`n")
    MsgBox(LangT("Possible problems in your combos:`n`n") . text, LangT("Combo check"), "Icon! 262144")
}
; ---- COMBO CHECK BLOCK END ----

; ---- HOVER TIPS BLOCK BEGIN ----
AddTip(ctrl, text) {
    global tipMap
    tipMap[ctrl.Hwnd] := text
}

StartTips(winHwnd) {
    global tipWinHwnd, tipLast
    tipWinHwnd := winHwnd
    tipLast := ""
    SetTimer(TipTick, 150)
}

TipTick() {
    global tipMap, tipLast, tipWinHwnd
    if (!WinExist("ahk_id " . tipWinHwnd)) {
        SetTimer(TipTick, 0)
        ToolTip(, , , 5)
        tipLast := ""
        return
    }
    MouseGetPos(, , &overWin, &overCtrl, 2)
    txt := ""
    if (tipMap.Has(overCtrl))
        txt := tipMap[overCtrl]
    if (txt != tipLast) {
        tipLast := txt
        ToolTip(txt, , , 5)
    }
}
; ---- HOVER TIPS BLOCK END ----

; ---- CONTROLLER TEST BLOCK BEGIN ----
global ctGui := 0
global ctEdit := 0

ShowControllerTest(*) {
    global ctGui, ctEdit
    if (IsObject(ctGui)) {
        ctGui.Show("NoActivate")
        return
    }
    ctGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox +E0x08000000", LangT("Controller Test"))
    ctGui.SetFont("s10", "Consolas")
    ctEdit := ctGui.Add("Edit", "x8 y8 w430 h290 ReadOnly -Wrap", "")
    ctGui.OnEvent("Close", CloseControllerTest)
    ctGui.Show("w446 h306 NoActivate")
    SetTimer(ControllerTestTick, 80)
}

CloseControllerTest(*) {
    global ctGui, ctEdit
    SetTimer(ControllerTestTick, 0)
    try ctGui.Destroy()
    ctGui := 0
    ctEdit := 0
}

ControllerTestTick() {
    ; Live view of what Windows reports, independent of rows and profiles.
    global ctGui, ctEdit, joyId
    if (!IsObject(ctGui)) {
        SetTimer(ControllerTestTick, 0)
        return
    }
    t := LangT("PS4 / generic pad (DirectInput)`n")
    if (!JoyPresent())
        DetectJoyId()
    if (JoyPresent()) {
        padName := GetKeyState(joyId . "JoyName")
        t .= LangT("  pad: ") . padName . "  (#" . joyId . ")`n"
        t .= LangT("  buttons down:")
        anyDown := false
        loop 32 {
            if GetKeyState(joyId . "Joy" . A_Index) {
                t .= " J" . A_Index
                anyDown := true
            }
        }
        t .= anyDown ? "`n" : " none`n"
        pov := GetPovName()
        t .= LangT("  d-pad: ") . (pov != "" ? pov : "centre") . "`n"
        t .= Format("  X {:5.1f}  Y {:5.1f}  Z {:5.1f}`n  R {:5.1f}  U {:5.1f}  V {:5.1f}`n", JoyAxis("X"), JoyAxis("Y"), JoyAxis("Z"), JoyAxis("R"), JoyAxis("U"), JoyAxis("V"))
        stickList := ""
        for tok, v in JoyStickTokens()
            stickList .= " " . tok
        t .= LangT("  stick directions:") . (stickList != "" ? stickList : " none") . "`n"
    } else {
        t .= LangT("  no DirectInput pad found`n")
    }
    t .= LangT("`nXbox pad (XInput)`n")
    if (XInputPoll()) {
        tokList := ""
        for tok, v in XInputTokens()
            tokList .= " " . tok
        t .= LangT("  slot ") . (xiUser + 1) . ": pressed:" . (tokList != "" ? tokList : " none") . "`n"
    } else {
        t .= LangT("  no Xbox pad found`n")
    }
    try ctEdit.Value := t
}
; ---- CONTROLLER TEST BLOCK END ----

; ---- HELP BLOCK BEGIN ----
HelpText() {
    t := ""
    t .= LangT("COMBO REMAPPER - QUICK HELP") . "`n"
    t .= "============================" . "`n"
    t .= "" . "`n"
    t .= LangT("WHAT IT DOES") . "`n"
    t .= LangT("Each row is: TRIGGER -> COMBO, with a MODE. When you press the trigger") . "`n"
    t .= LangT("(keyboard key, mouse button, or controller button), the remapper sends the") . "`n"
    t .= LangT("combo to the game. It only reacts while the Target EXE window is in front") . "`n"
    t .= LangT("(leave Target EXE on `"(any)`" to react everywhere).") . "`n"
    t .= "" . "`n"
    t .= LangT("TRIGGERS") . "`n"
    t .= LangT("  Keyboard / mouse    F1, q, XButton1, WheelUp ... any AutoHotkey key name") . "`n"
    t .= LangT("  DualShock 4 (J)     J1 Square, J2 Cross, J3 Circle, J4 Triangle,") . "`n"
    t .= LangT("                      J5 L1, J6 R1, J7 L2, J8 R2, J9 Share, J10 Options,") . "`n"
    t .= LangT("                      J11 L3, J12 R3, J13 PS, J14 Touchpad") . "`n"
    t .= LangT("                      (numbers can differ - use the Auto recorder to be sure)") . "`n"
    t .= LangT("  D-pad               JPOVU  JPOVD  JPOVL  JPOVR") . "`n"
    t .= LangT("  Stick directions    JLSU JLSD JLSL JLSR (left)  JRSU JRSD JRSL JRSR (right)") . "`n"
    t .= LangT("  Xbox pad (X)        XA XB XX XY XLB XRB XLT XRT XSTART XBACK XLS XRS") . "`n"
    t .= LangT("                      XUP XDOWN XLEFT XRIGHT, sticks XLSU.. and XRSU..") . "`n"
    t .= LangT("  Chords              J5+J6   XLB+XRB   (all buttons held together)") . "`n"
    t .= "" . "`n"
    t .= LangT("MODES") . "`n"
    t .= LangT("  Hold      Sends the keys while the trigger is held, releases on release.") . "`n"
    t .= LangT("  Toggle    Press once to hold the keys down, press again to let go (auto-hold).") . "`n"
    t .= LangT("  Press     One quick press of the combo each time.") . "`n"
    t .= LangT("  Turbo     Repeats the combo quickly while held (right-click row: interval).") . "`n"
    t .= LangT("  TapHold   A quick tap sends the FIRST key, holding sends the SECOND key.") . "`n"
    t .= LangT("  DblTap    Two quick presses (within 0.35 s) send the combo.") . "`n"
    t .= LangT("  TglTurbo  Press once: the combo repeats by itself. Press again: it stops.") . "`n"
    t .= LangT("            (right-click row: interval)") . "`n"
    t .= "" . "`n"
    t .= LangT("COMBO WORDS (separate with commas)") . "`n"
    t .= LangT("  w, shift, space, f5     keys by name") . "`n"
    t .= LangT("  d150  or  150           wait 150 milliseconds (a single digit is a real key)") . "`n"
    t .= LangT("  mlc mrc mmc             left / right / middle click") . "`n"
    t .= LangT("  mdc                     double click (left button)") . "`n"
    t .= LangT("  mdown  mup              hold / release the left button") . "`n"
    t .= LangT("  mwd5   mwu5             scroll down / up 5 notches") . "`n"
    t .= LangT("  m10,-5                  move the mouse 10 right, 5 up (relative)") . "`n"
    t .= LangT("  mx400,300               move the mouse to screen position 400,300") . "`n"
    t .= LangT("  mm200,0,500             smooth move: 200 px right over 500 ms") . "`n"
    t .= LangT("  mshake12,600            camera shake up to 12 px for 600 ms") . "`n"
    t .= LangT("  mwave0,30,600,15        waggle up/down 30 px every 15 ms for 600 ms") . "`n"
    t .= LangT("  down:q  up:q           hold a key (or lbutton) across steps, then let go") . "`n"
    t .= LangT("                         e.g.  down:q,d40,mlc,d40,up:q") . "`n"
    t .= LangT("  burst:x,30,40           press x 30 times, 40 ms apart (one-key button mash)") . "`n"
    t .= LangT("  alt:x/c,30,40           alternate x and c 30 times (left/right mash)") . "`n"
    t .= LangT("  hold:x,800              hold x for 800 ms, then let go") . "`n"
    t .= LangT("                          (burst, alt and hold work in Press, Turbo, TglTurbo, DblTap)") . "`n"
    t .= LangT("  mh300,0                 steady move 300 px/s while a Hold row is held or a") . "`n"
    t .= LangT("                          Toggle row is on") . "`n"
    t .= "" . "`n"
    t .= LangT("COMBO RECIPES (copy into the combo box)") . "`n"
    t .= LangT("  Shift + Space together      down:lshift,d30,space,d40,up:lshift") . "`n"
    t .= LangT("  Hold a key for half a second down:e,d500,up:e") . "`n"
    t .= LangT("  Tap a key three times       e,d60,e,d60,e") . "`n"
    t .= LangT("  Double click                mdc      (or  mlc,d80,mlc )") . "`n"
    t .= LangT("  Hold right click 1 second   down:rbutton,d1000,up:rbutton") . "`n"
    t .= LangT("  Hold middle button          down:mbutton,d500,up:mbutton") . "`n"
    t .= LangT("  Ctrl + scroll (zoom)        down:lctrl,mwd1,up:lctrl") . "`n"
    t .= LangT("  Ctrl + C   /   Ctrl + V     down:lctrl,c,up:lctrl   /   down:lctrl,v,up:lctrl") . "`n"
    t .= LangT("  Alt + Tab                   down:lalt,tab,d100,up:lalt") . "`n"
    t .= LangT("  Scroll then click           mwd3,d50,mlc") . "`n"
    t .= LangT("  Walk forward, then turn     down:w,d1000,down:a,d200,up:a,up:w") . "`n"
    t .= LangT("  Drag with the mouse         mx400,300,mdown,d50,mm200,0,500,mup") . "`n"
    t .= LangT("  Hold a key + wiggle mouse   down:lctrl,mwave0,30,600,15") . "`n"
    t .= LangT("  Hold a key + wheel          down:q,mwd2,d40,mwu2,d40") . "`n"
    t .= LangT("  Auto-click (set the row to TglTurbo, interval 20)     mlc") . "`n"
    t .= LangT("  Auto-mash a key (TglTurbo, interval 20)               e") . "`n"
    t .= LangT("  Walk forever (Toggle)       w") . "`n"
    t .= LangT("  Tap = one key, hold = another (TapHold)               e,q") . "`n"
    t .= LangT("  Double-tap to sprint (DblTap)                         lshift") . "`n"
    t .= "" . "`n"
    t .= LangT("SETTINGS (tray icon > Settings)") . "`n"
    t .= LangT("  Input mode              Game / Classic / Hybrid. If a game ignores the keys,") . "`n"
    t .= LangT("                          try another mode (also in the tray menu: More -> Input mode).") . "`n"
    t .= LangT("  Extra press time        Adds milliseconds to every key press. Helps with") . "`n"
    t .= LangT("                          timed prompts and games that miss short taps.") . "`n"
    t .= LangT("  Controller type         Auto, Xbox (XInput) or PS4 (DirectInput).") . "`n"
    t .= LangT("  Mouse stick / Scroll    A stick moves the mouse or scrolls the wheel.") . "`n"
    t .= LangT("  Speed, Deadzone, Curve  Tune the stick. A higher curve = finer control") . "`n"
    t .= LangT("                          near the centre.") . "`n"
    t .= LangT("  Mouse speed %           Scales m / mm / mshake / mh moves.") . "`n"
    t .= LangT("  Run as Administrator    Needed when the game runs as admin. Restart to apply.") . "`n"
    t .= LangT("  Auto-switch profile     Changes profile by itself when you switch to a game") . "`n"
    t .= LangT("                          whose profile has that Target EXE.") . "`n"
    t .= "" . "`n"
    t .= LangT("TRAY MENU (right-click the tray icon; double-click shows or hides the window)") . "`n"
    t .= LangT("  Every day: Show / hide window, Remapper on / off, Switch profile, Key cheat sheet, Pages.") . "`n"
    t .= LangT("  Setup: Setup wizard, Settings, Accessibility tools.") . "`n"
    t .= LangT("  More (the rest):") . "`n"
    t .= LangT("    Status box on / off, Keyboard mouse on / off, One-button control menu,") . "`n"
    t .= LangT("    Customize look (status box and cheat sheet), Check combos (finds typos),") . "`n"
    t .= LangT("    Auto-switch profile by game, Create starter profile, Input mode,") . "`n"
    t .= LangT("    Controller (support, type, test), Copy diagnostics, Open log file.") . "`n"
    t .= "" . "`n"
    t .= LangT("PANIC") . "`n"
    t .= LangT("  Keyboard: the panic key (default F8) turns the remapper off or on.") . "`n"
    t .= LangT("  Controller: hold Start+Back (Xbox) or Share+Options (PS4) for 1 second") . "`n"
    t .= LangT("  to turn it off - hold it again to turn it back on. You can set your own") . "`n"
    t .= LangT("  buttons in Settings (On/Off buttons). Held keys are always released.") . "`n"
    t .= "" . "`n"
    t .= LangT("SETUP WIZARD (tray menu -> Setup wizard...)") . "`n"
    t .= LangT("  Builds a ready profile: pick your hand (left, right, either), the game, and what") . "`n"
    t .= LangT("  you want one key to do. It picks keys within reach of that hand and avoids the") . "`n"
    t .= LangT("  keys the game uses. It is offered at start until you press Don't ask again.") . "`n"
    t .= "" . "`n"
    t .= LangT("QUICK TIME EVENTS (timed button prompts)") . "`n"
    t .= LangT("  Set the row mode to Press, then pick a combo:") . "`n"
    t .= LangT("  Mash prompt, one burst      burst:x,30,40    (30 presses of x, 40 ms apart, about 1.2 s)") . "`n"
    t .= LangT("  Left/right mash prompt      alt:x/c,30,40    (alternates x and c)") . "`n"
    t .= LangT("  Hold the button prompt      hold:x,1000      (holds x for 1 second)") . "`n"
    t .= LangT("  Mash for as long as needed  mode TglTurbo, combo x   (press once to start, again to stop)") . "`n"
    t .= LangT("  Mash while you hold the key mode Turbo, combo x") . "`n"
    t .= LangT("  The panic key stops a burst at once. A wrong button can end some mini-games, so") . "`n"
    t .= LangT("  use one key per button and press only the one the prompt shows.") . "`n"
    t .= "" . "`n"
    t .= LangT("STATUS BOX NAMES") . "`n"
    t .= LangT("  When a row fires, the status box shows the row's note (right-click a row") . "`n"
    t .= LangT("  -> Edit Row Note...) and ON or OFF for toggles. Switch it off or change how long") . "`n"
    t .= LangT("  it shows in Settings -> Customize...") . "`n"
    t .= "" . "`n"
    t .= LangT("EDITING IN THE GAME") . "`n"
    t .= LangT("  Press the window key (default F12) to bring this window in front of the game, and") . "`n"
    t .= LangT("  again to hide it and return to the game. The tray icon (double-click) does the same.") . "`n"
    t .= LangT("  While this window is in front the row keys are switched off, so you can type in the") . "`n"
    t .= LangT("  boxes safely. The game must be in windowed or borderless mode to show a window over it.") . "`n"
    t .= "" . "`n"
    t .= LangT("ACCESSIBILITY TOOLS (Settings -> Accessibility tools...)") . "`n"
    t .= LangT("  Tremor filter: ignores a repeat press that comes too soon after the last one, and can") . "`n"
    t .= LangT("  require a key to be held a moment before it counts. Both are off at 0.") . "`n"
    t .= LangT("  Keyboard mouse: keys move the cursor and click, for when the mouse is hard to use.") . "`n"
    t .= LangT("  Turn it on and off with its own key or the tray menu. Default keys: E S D F move,") . "`n"
    t .= LangT("  Q W R click, T and G scroll. It speeds up while a key is held. The panic key turns it off.") . "`n"
    t .= LangT("  One-button control: one key opens a list of this profile's actions and steps through") . "`n"
    t .= LangT("  them. Automatic: the highlight moves by itself and your key chooses. Step: tap = next,") . "`n"
    t .= LangT("  hold = choose. Works best with Press, Toggle and TglTurbo rows.") . "`n"
    t .= LangT("  Row notes: right-click a row -> Edit Row Note... The note shows in the cheat sheet and") . "`n"
    t .= LangT("  in one-button control. Press Apply to save it.") . "`n"
    t .= "" . "`n"
    t .= LangT("SAFETY AND DIAGNOSTICS") . "`n"
    t .= LangT("  Held keys, toggles and auto-repeats are let go when the game loses focus") . "`n"
    t .= LangT("  (Advanced Settings -> turn off if you do not want this).") . "`n"
    t .= LangT("  Something wrong? Tray menu -> More -> Copy diagnostics, then paste it in the chat.") . "`n"
    t .= LangT("  Tray menu -> More -> Open log file shows combo_remapper.log (errors, releases, what fired).") . "`n"
    t .= LangT("  The log file also records what fired. Advanced Settings -> System -> Write a log") . "`n"
    t .= LangT("  file switches it on or off.") . "`n"
    t .= "" . "`n"
    t .= LangT("AUTO AND SET BUTTONS") . "`n"
    t .= LangT("  Set (next to a trigger box): press it, then press the key or mouse button you") . "`n"
    t .= LangT("  want as the trigger. Esc cancels. Auto (next to the combo box) records the") . "`n"
    t .= LangT("  keys you press into the combo. Both listen for the time set in Advanced") . "`n"
    t .= LangT("  Settings -> Auto-detect (sec); the default is 10 seconds, up to 120.") . "`n"
    t .= "" . "`n"
    t .= LangT("PAGES AND CHEAT SHEET (Settings -> Pages and cheat sheet)") . "`n"
    t .= LangT("  Cheat-sheet key: shows every key of this profile - and of all its pages - on the") . "`n"
    t .= LangT("  screen. Press it again to also see the exact combos, a third time to close.") . "`n"
    t .= LangT("  Long lists are split into columns so everything fits.") . "`n"
    t .= LangT("  Pages: each page is a profile. Make one with New profile for every page you") . "`n"
    t .= LangT("  want, then in Settings use 'Add a page' to put them in order. The Next-page") . "`n"
    t .= LangT("  key moves forward (after the last page it goes back to the first). The") . "`n"
    t .= LangT("  Previous-page key moves back. Held keys are let go on every switch.") . "`n"
    t .= LangT("  The status box and cheat sheet show 'Page 2 of 4'.") . "`n"
    t .= LangT("  Tap/Hold and Dbl-tap modes give two or three actions on one key.") . "`n"
    t .= "" . "`n"
    t .= LangT("TIPS") . "`n"
    t .= LangT("  * Right-click a row for tools: Test Fire, Turbo interval, insert mouse") . "`n"
    t .= LangT("    actions, duplicate, clear.") . "`n"
    t .= LangT("  * Hover over a setting in the Settings window for a short explanation.") . "`n"
    t .= LangT("  * Export Profile copies a profile to the clipboard; Import brings it back,") . "`n"
    t .= LangT("    including input mode, controller and mouse settings.") . "`n"
    return t
}

ShowHelp(*) {
    global helpGui
    if (IsObject(helpGui)) {
        helpGui.Show()
        return
    }
    helpGui := Gui("+Resize -MaximizeBox", LangT("Combo ReMapper - Help"))
    helpGui.SetFont("s10", "Consolas")
    helpEdit := helpGui.Add("Edit", "x8 y8 w660 h520 ReadOnly -Wrap +VScroll +HScroll vHelpEdit", HelpText())
    helpGui.OnEvent("Size", HelpResize)
    helpGui.OnEvent("Close", HelpClose)
    helpGui.Show("w676 h536")
}

HelpResize(g, minMax, w, h) {
    if (minMax = -1)
        return
    g["HelpEdit"].Move(, , Max(100, w - 16), Max(100, h - 16))
}

HelpClose(*) {
    global helpGui
    try helpGui.Destroy()
    helpGui := 0
}
; ---- HELP BLOCK END ----

; ---- STARTER PROFILES BLOCK BEGIN ----
StarterNames() {
    return [LangT("PS4 pad to keyboard + mouse"), LangT("Xbox pad to keyboard + mouse"), LangT("Auto-walk and auto-fire"), LangT("Quick-time mash")]
}

StarterData(idx) {
    ; Returns Map with name, padType, stick and rows [[trigger, combo, mode, turboMs], ...]
    if (idx = 1) {
        return Map("name", "starter_ps4_keyboard", "padType", 3, "stick", 2, "rows", [
            ["JPOVU", "w", "hold", 60], ["JPOVD", "s", "hold", 60], ["JPOVL", "a", "hold", 60], ["JPOVR", "d", "hold", 60],
            ["J2", "space", "hold", 60], ["J3", "e", "press", 60], ["J1", "r", "press", 60], ["J4", "f", "press", 60],
            ["J5", "lshift", "hold", 60], ["J6", "lctrl", "hold", 60], ["J8", "lbutton", "hold", 60], ["J7", "rbutton", "hold", 60],
            ["J10", "escape", "press", 60], ["J9", "tab", "press", 60]])
    }
    if (idx = 2) {
        return Map("name", "starter_xbox_keyboard", "padType", 2, "stick", 2, "rows", [
            ["XUP", "w", "hold", 60], ["XDOWN", "s", "hold", 60], ["XLEFT", "a", "hold", 60], ["XRIGHT", "d", "hold", 60],
            ["XA", "space", "hold", 60], ["XY", "e", "press", 60], ["XX", "r", "press", 60], ["XB", "lctrl", "hold", 60],
            ["XLB", "lshift", "hold", 60], ["XRB", "f", "press", 60], ["XRT", "lbutton", "hold", 60], ["XLT", "rbutton", "hold", 60],
            ["XSTART", "escape", "press", 60], ["XBACK", "tab", "press", 60]])
    }
    if (idx = 3) {
        return Map("name", "starter_auto_walk_fire", "padType", 1, "stick", 0, "rows", [
            ["F1", "w", "toggle", 60], ["F2", "shift,w", "toggle", 60], ["F3", "lbutton", "toggle", 60],
            ["F4", "mlc", "turbo", 60]])
    }
    return Map("name", "starter_quick_time_mash", "padType", 1, "stick", 0, "rows", [
        ["F1", "e", "turbo", 40], ["F2", "space", "turbo", 50], ["F3", "mlc", "turbo", 80],
        ["F4", "e,d80,e,d80,e", "press", 60]])
}

CreateStarterProfile(idx, *) {
    global profilesDir
    data := StarterData(idx)
    name := data["name"]
    path := profilesDir "\" name ".ini"
    if !FileExist(path) {
        DirCreate(profilesDir)
        IniWrite(data["rows"].Length, path, "Meta", "RowCount")
        IniWrite("(none)", path, "Meta", "ScrollKey")
        IniWrite(data.Has("panic") ? data["panic"] : "F8", path, "Meta", "PanicKey")
        IniWrite(data.Has("exe") ? data["exe"] : "(any)", path, "Meta", "TargetExe")
        if (data.Has("exe")) {
            ; Game profiles: Game input mode (scan codes + raw mouse), beeps on, chosen press time
            IniWrite(1, path, "Settings", "CompatMode")
            IniWrite(1, path, "Settings", "SoundAlerts")
            IniWrite(data["extra"], path, "Settings", "PressExtraMs")
        }
        IniWrite(1, path, "Settings", "ControllerEnabled")
        IniWrite(data["padType"], path, "Settings", "PadType")
        IniWrite(data["stick"], path, "Settings", "PadMouseStick")
        for i, r in data["rows"] {
            IniWrite(r[1], path, "Row" . i, "Trigger")
            IniWrite(r[2], path, "Row" . i, "Combo")
            IniWrite(r[3], path, "Row" . i, "Mode")
            IniWrite(r.Length >= 5 ? r[5] : 1, path, "Row" . i, "Enabled")
            IniWrite(r[4], path, "Row" . i, "TurboMs")
        }
    }
    GotoProfile(name)
    NotifyUser(LangT("Starter profile ready: ") . name . (data.Has("exe") ? LangT("  (target: ") . data["exe"] . LangT(" - change it if your game shows another name)") : LangT("  (set your Target EXE, then Apply)")))
}
; ---- STARTER PROFILES BLOCK END ----

; ---- EVENT LOG (no window; goes to combo_remapper.log and a short in-memory list) ----
LogEvent(msg, throttle := false) {
    global fireLog, logLastMsg, logLastTick, logLastWrite
    if (throttle && msg = logLastMsg && A_TickCount - logLastTick < 400)
        return
    logLastMsg := msg
    logLastTick := A_TickCount
    stamp := FormatTime(, "HH:mm:ss") . "." . Format("{:03}", A_MSec)
    fireLog.Push([stamp, msg])
    if (fireLog.Length > 300)
        fireLog.RemoveAt(1)
    ; to the log file, at most 20 lines per second so fast auto-repeats cannot flood it
    if (A_TickCount - logLastWrite >= 50) {
        logLastWrite := A_TickCount
        DiagLog(msg)
    }
}

; ---- SCROLLABLE GUI BLOCK BEGIN ----
; Adds a vertical scroll bar (and mouse-wheel scrolling) to any Gui, so panels can keep growing.
global scrollGuis := Map()          ; top-level hwnd -> Map("contentH", total height, "pos", scroll offset)
global scrollHooked := false

MakeGuiScrollable(g, contentH) {
    global scrollGuis, scrollHooked
    scrollGuis[g.Hwnd] := Map("contentH", contentH, "pos", 0)
    if (!scrollHooked) {
        OnMessage(0x0115, ScrollWM_VScroll)
        OnMessage(0x020A, ScrollWM_MouseWheel)
        scrollHooked := true
    }
    g.OnEvent("Size", (gui, minMax, w, h) => ScrollGuiRefresh(gui.Hwnd))
    ScrollGuiRefresh(g.Hwnd)
}

ScrollClientH(hwnd) {
    rc := Buffer(16, 0)
    DllCall("GetClientRect", "Ptr", hwnd, "Ptr", rc)
    return NumGet(rc, 12, "Int")
}

ScrollMaxPos(hwnd) {
    global scrollGuis
    return Max(0, scrollGuis[hwnd]["contentH"] - ScrollClientH(hwnd))
}

ScrollSetBar(hwnd, fullUpdate) {
    global scrollGuis
    info := scrollGuis[hwnd]
    si := Buffer(28, 0)
    NumPut("UInt", 28, si, 0)
    if (fullUpdate) {
        NumPut("UInt", 0xF, si, 4)                       ; RANGE | PAGE | POS | DISABLENOSCROLL
        NumPut("Int", 0, si, 8)
        NumPut("Int", info["contentH"] - 1, si, 12)
        NumPut("UInt", ScrollClientH(hwnd), si, 16)
    } else {
        NumPut("UInt", 0x4, si, 4)                       ; POS only
    }
    NumPut("Int", info["pos"], si, 20)
    DllCall("SetScrollInfo", "Ptr", hwnd, "Int", 1, "Ptr", si, "Int", 1)
}

ScrollGuiTo(hwnd, newPos) {
    global scrollGuis
    info := scrollGuis[hwnd]
    newPos := Max(0, Min(ScrollMaxPos(hwnd), Round(newPos)))
    dy := info["pos"] - newPos
    if (dy != 0) {
        DllCall("ScrollWindow", "Ptr", hwnd, "Int", 0, "Int", dy, "Ptr", 0, "Ptr", 0)
        info["pos"] := newPos
        DllCall("RedrawWindow", "Ptr", hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0185)
    }
    ScrollSetBar(hwnd, false)
}

ScrollGuiRefresh(hwnd) {
    global scrollGuis
    if (!scrollGuis.Has(hwnd))
        return
    ScrollSetBar(hwnd, true)
    ; If the window was made taller, pull the content back into view
    ScrollGuiTo(hwnd, scrollGuis[hwnd]["pos"])
}

ScrollWM_VScroll(wParam, lParam, msg, hwnd) {
    global scrollGuis
    if (!scrollGuis.Has(hwnd))
        return
    pos := scrollGuis[hwnd]["pos"]
    page := ScrollClientH(hwnd)
    switch (wParam & 0xFFFF) {
        case 0:
            pos -= 30                                     ; line up
        case 1:
            pos += 30                                     ; line down
        case 2:
            pos -= page                                   ; page up
        case 3:
            pos += page                                   ; page down
        case 4, 5:
            pos := (wParam >> 16) & 0xFFFF                ; thumb drag
        case 6:
            pos := 0
        case 7:
            pos := scrollGuis[hwnd]["contentH"]
        default:
            return 0
    }
    ScrollGuiTo(hwnd, pos)
    return 0
}

ScrollWM_MouseWheel(wParam, lParam, msg, hwnd) {
    global scrollGuis
    root := DllCall("GetAncestor", "Ptr", hwnd, "UInt", 2, "Ptr")
    if (!scrollGuis.Has(root))
        return
    delta := (wParam >> 16) & 0xFFFF
    if (delta > 0x7FFF)
        delta -= 0x10000
    ScrollGuiTo(root, scrollGuis[root]["pos"] - Round(delta / 120) * 40)
    return 0
}
; ---- SCROLLABLE GUI BLOCK END ----

OpenSettingsPanel(*) {
    global keyDelayDuration, keyDelayPress, mouseDelayDuration, soundAlerts, showTooltips, showOsd, osdLocked, osdToggleKey
    global customBgColor, customControlColor, customTextColor, configFile, myGui, currentTheme
    global controllerEnabled, controllerPollMs, compatMode, runAsAdmin

    settingsGui := Gui("+Owner" . myGui.Hwnd . " +ToolWindow +Resize -MaximizeBox +0x200000", LangT("Remapper Settings Panel"))
    settingsGui.SetFont("s9")

    ; ---------------- Main settings window: everyday options ----------------
    settingsGui.Add("GroupBox", "xm ym w340 h258", LangT("Startup, display and input"))
    autoStartCB := settingsGui.Add("Checkbox", "x20 yp+25 " . (IsAutoStartEnabled() ? "Checked" : ""), LangT("Auto-Start with Windows Startup"))
    autoStartCB.OnEvent("Click", AutoStartClick)
    soundCB := settingsGui.Add("Checkbox", "x20 y+8 " . (soundAlerts ? "Checked" : ""), LangT("Enable Audio Beep Alerts"))
    tooltipCB := settingsGui.Add("Checkbox", "x20 y+8 " . (showTooltips ? "Checked" : ""), LangT("Enable Overlay ToolTips"))
    osdCB := settingsGui.Add("Checkbox", "x20 y+8 " . (showOsd ? "Checked" : ""), LangT("Enable On-Screen Overlay (OSD)"))
    osdLockCB := settingsGui.Add("Checkbox", "x20 y+8 " . (osdLocked ? "Checked" : ""), LangT("Lock OSD Position (Click-Through)"))
    settingsGui.Add("Text", "x20 y+12 w110", LangT("OSD Toggle Key:"))
    osdKeyBox := settingsGui.Add("Edit", "x130 yp-3 w60", osdToggleKey)
    osdCapBtn := settingsGui.Add("Button", "x+5 yp w78 h22", LangT("Bind"))
    osdCapBtn.OnEvent("Click", (*) => CaptureSingleKey(osdKeyBox))
    settingsGui.Add("Text", "x20 y+16 w80", LangT("Input mode:"))
    compatDD := settingsGui.Add("DropDownList", "x105 yp-3 w240 AltSubmit Choose" . compatMode, CompatModeNames())
    autoProfCB := settingsGui.Add("Checkbox", "x20 y+12 " . (autoProfile ? "Checked" : ""), LangT("Auto-switch profile by game window"))
    controllerCB := settingsGui.Add("Checkbox", "x20 y+8 " . (controllerEnabled ? "Checked" : ""), LangT("Enable Gamepad / Controller Support"))

    settingsGui.Add("GroupBox", "xm y+20 w340 h100", LangT("Mouse hotkeys (tick Off to disable)"))
    settingsGui.Add("Text", "x20 yp+26 w110", LangT("Scroll-click key:"))
    scrollKeyEdit := settingsGui.Add("Edit", "x135 yp-3 w60", scrollTriggerKey)
    scrollKeyBind := settingsGui.Add("Button", "x+5 yp w78 h22", LangT("Bind"))
    scrollKeyBind.OnEvent("Click", (*) => CaptureSingleKey(scrollKeyEdit))
    scrollOffCB := settingsGui.Add("Checkbox", "x+10 yp+3 " . (scrollTriggerKey = "" ? "Checked" : ""), LangT("Off"))
    settingsGui.Add("Text", "x20 y+14 w110", LangT("Y-Axis Lock key:"))
    yLockEdit := settingsGui.Add("Edit", "x135 yp-3 w60", yLockKey)
    yLockBind := settingsGui.Add("Button", "x+5 yp w78 h22", LangT("Bind"))
    yLockBind.OnEvent("Click", (*) => CaptureSingleKey(yLockEdit))
    yLockOffCB := settingsGui.Add("Checkbox", "x+10 yp+3 " . (yLockKey = "" ? "Checked" : ""), LangT("Off"))

    settingsGui.Add("GroupBox", "xm y+22 w340 h136", "Language / Nyelv")
    langChoices := LangList()
    langNames := []
    langPick := 1
    for i, item in langChoices {
        langNames.Push(item.name)
        if (item.code = langCode)
            langPick := i
    }
    langDD := settingsGui.Add("DropDownList", "x20 yp+26 w300 Choose" . langPick, langNames)
    langDD.OnEvent("Change", (*) => LangSet(LangList()[langDD.Value].code))
    langExpBtn := settingsGui.Add("Button", "x20 y+10 w150 h26", LangT("Export template"))
    langExpBtn.OnEvent("Click", LangExportTemplate)
    langDirBtn := settingsGui.Add("Button", "x+8 yp w150 h26", LangT("Open folder"))
    langDirBtn.OnEvent("Click", LangOpenFolder)
    langAddBtn := settingsGui.Add("Button", "x20 y+8 w308 h26", LangT("Add language file..."))
    langAddBtn.OnEvent("Click", (*) => LangAddFiles(langDD))
    AddTip(langDD, LangT("Pick the language. Changing it offers to restart the program. To add your own language: export the template, translate it, then press Add language file... and pick your .po file (you can pick several)."))

    ; ---------------- Pages and cheat sheet window (opened from a button) ----------------
    pagesGui := Gui("+Owner" . settingsGui.Hwnd . " +ToolWindow +Resize -MaximizeBox +0x200000", LangT("Pages and cheat sheet"))
    pagesGui.SetFont("s9")
    pagesGui.Add("GroupBox", "xm ym w340 h310", LangT("Pages and cheat sheet"))
    pagesGui.Add("Text", "x20 yp+26 w110", LangT("Next-page key:"))
    layerEdit := pagesGui.Add("Edit", "x135 yp-3 w60", layerKey)
    layerBind := pagesGui.Add("Button", "x+5 yp w78 h22", LangT("Bind"))
    layerBind.OnEvent("Click", (*) => CaptureSingleKey(layerEdit))
    layerOffCB := pagesGui.Add("Checkbox", "x+10 yp+3 " . (layerKey = "" ? "Checked" : ""), LangT("Off"))
    pagesGui.Add("Text", "x20 y+14 w110", LangT("Previous-page key:"))
    prevEdit := pagesGui.Add("Edit", "x135 yp-3 w60", layerPrevKey)
    prevBind := pagesGui.Add("Button", "x+5 yp w78 h22", LangT("Bind"))
    prevBind.OnEvent("Click", (*) => CaptureSingleKey(prevEdit))
    prevOffCB := pagesGui.Add("Checkbox", "x+10 yp+3 " . (layerPrevKey = "" ? "Checked" : ""), LangT("Off"))
    pagesGui.Add("Text", "x20 y+14 w110", LangT("Add a page:"))
    layerDD := pagesGui.Add("DropDownList", "x135 yp-3 w150", GetProfileList())
    layerAddBtn := pagesGui.Add("Button", "x+5 yp-1 w50 h24", LangT("Add"))
    layerWork := layerPages.Clone()
    pagesGui.Add("Text", "x20 y+8 w110", LangT("Pages, in order:"))
    layerList := pagesGui.Add("ListBox", "x135 yp-3 w200 r4", layerWork)
    layerRemBtn := pagesGui.Add("Button", "x135 y+4 w120 h24", LangT("Remove selected"))
    layerAddBtn.OnEvent("Click", (*) => LayerAddPage(layerDD, layerList, layerWork))
    layerRemBtn.OnEvent("Click", (*) => LayerRemovePage(layerList, layerWork))
    pagesGui.Add("Text", "x20 y+14 w110", LangT("Cheat-sheet key:"))
    cheatEdit := pagesGui.Add("Edit", "x135 yp-3 w60", cheatKey)
    cheatBind := pagesGui.Add("Button", "x+5 yp w78 h22", LangT("Bind"))
    cheatBind.OnEvent("Click", (*) => CaptureSingleKey(cheatEdit))
    cheatOffCB := pagesGui.Add("Checkbox", "x+10 yp+3 " . (cheatKey = "" ? "Checked" : ""), LangT("Off"))

    pagesDoneBtn := pagesGui.Add("Button", "xm y+22 w120 h30", LangT("Done"))
    pagesDoneBtn.OnEvent("Click", (*) => pagesGui.Hide())
    pagesGui.OnEvent("Close", (*) => pagesGui.Hide())
    pagesGui.Show("Hide")
    pagesGui.GetClientPos(, , &pgCW, &pgCH)
    pagesDoneBtn.GetPos(, &pgBtnY, , &pgBtnH)
    pgContentH := pgBtnY + pgBtnH + 15
    MonitorGetWorkArea(, , &pgWaTop, , &pgWaBottom)
    pgShowH := Min(pgContentH, (pgWaBottom - pgWaTop) - 110)
    pgW := pgCW + 24
    MakeGuiScrollable(pagesGui, pgContentH)

    ; ---------------- Controller window (opened from a button) ----------------
    padGui := Gui("+Owner" . settingsGui.Hwnd . " +ToolWindow +Resize -MaximizeBox +0x200000", LangT("Controller settings"))
    padGui.SetFont("s9")
    padGui.Add("GroupBox", "xm ym w340 h150", LangT("Controller"))
    padGui.Add("Text", "x20 yp+26 w100", LangT("Controller type:"))
    padTypeDD := padGui.Add("DropDownList", "x125 yp-3 w215 AltSubmit Choose" . padType, PadTypeNames())
    padGui.Add("Text", "x20 y+12 w80", LangT("Mouse stick:"))
    msDD := padGui.Add("DropDownList", "x105 yp-3 w95 AltSubmit Choose" . (padMouseStick + 1), [LangT("Off"), LangT("Left stick"), LangT("Right stick")])
    padGui.Add("Text", "x210 yp+3 w70", LangT("Speed px/s:"))
    msSpeedEdit := padGui.Add("Edit", "x282 yp-3 w55", padMouseSpeed)
    padGui.Add("Text", "x20 y+12 w80", LangT("Scroll stick:"))
    scDD := padGui.Add("DropDownList", "x105 yp-3 w95 AltSubmit Choose" . (padScrollStick + 1), [LangT("Off"), LangT("Left stick"), LangT("Right stick")])
    padGui.Add("Text", "x210 yp+3 w70", LangT("Ticks/s:"))
    scSpeedEdit := padGui.Add("Edit", "x282 yp-3 w55", padScrollSpeed)
    padPanicCB := padGui.Add("Checkbox", "x20 y+14 " . (padPanic ? "Checked" : ""), LangT("Hold the on/off buttons for 1 second to switch the remapper off / on"))
    padGui.Add("Text", "x20 y+8 w110", LangT("On/Off buttons:"))
    padSwitchEdit := padGui.Add("Edit", "x135 yp-3 w135", padSwitchCombo)
    padSwitchBtn := padGui.Add("Button", "x278 yp-1 w62", LangT("Detect"))
    padSwitchBtn.OnEvent("Click", DetectPadSwitch.Bind(padSwitchEdit))

    padDoneBtn := padGui.Add("Button", "xm y+22 w120 h30", LangT("Done"))
    padDoneBtn.OnEvent("Click", (*) => padGui.Hide())
    padGui.OnEvent("Close", (*) => padGui.Hide())
    padGui.Show("Hide")
    padGui.GetClientPos(, , &pdCW, &pdCH)
    padDoneBtn.GetPos(, &pdBtnY, , &pdBtnH)
    pdContentH := pdBtnY + pdBtnH + 15
    MonitorGetWorkArea(, , &pdWaTop, , &pdWaBottom)
    pdShowH := Min(pdContentH, (pdWaBottom - pdWaTop) - 110)
    pdW := pdCW + 24
    MakeGuiScrollable(padGui, pdContentH)

    ShowPagesWindow() {
        pagesGui.Show("w" . pgW . " h" . pgShowH)
        ScrollGuiRefresh(pagesGui.Hwnd)
    }

    ShowPadWindow() {
        padGui.Show("w" . pdW . " h" . pdShowH)
        ScrollGuiRefresh(padGui.Hwnd)
    }

    pagesBtn := settingsGui.Add("Button", "xm y+22 w108 h30", LangT("Pages..."))
    pagesBtn.OnEvent("Click", (*) => ShowPagesWindow())
    padBtn := settingsGui.Add("Button", "x+8 yp w108 h30", LangT("Controller..."))
    padBtn.OnEvent("Click", (*) => ShowPadWindow())
    custBtn := settingsGui.Add("Button", "x+8 yp w108 h30", LangT("Customize..."))
    custBtn.OnEvent("Click", ShowCustomize)
    accBtn := settingsGui.Add("Button", "xm y+8 w340 h30", LangT("Accessibility tools..."))
    accBtn.OnEvent("Click", ShowAccessTools)
    aboutBtn := settingsGui.Add("Button", "xm y+8 w100 h30", LangT("About..."))
    aboutBtn.OnEvent("Click", ShowAbout)
    logBtn := settingsGui.Add("Button", "x+8 yp w115 h30", LangT("Open log file"))
    logBtn.OnEvent("Click", OpenLogFile)
    helpBtn := settingsGui.Add("Button", "x+8 yp w100 h30", LangT("Help..."))
    helpBtn.OnEvent("Click", ShowHelp)
    advBtn := settingsGui.Add("Button", "xm y+8 w155 h30", LangT("Advanced..."))
    advBtn.OnEvent("Click", (*) => ShowAdvanced())
    saveBtn := settingsGui.Add("Button", "x+8 yp w172 h30", LangT("Save Settings"))
    saveBtn.OnEvent("Click", (*) => SaveSettingsAction())
    secretBtn := settingsGui.Add("Text", "xm y+10 w44 h32 +0x200 +0x100 Center Background0F0D0D", "⚡")
    secretBtn.SetFont("s16 bold cE5171F", "Segoe UI Symbol")
    StartCyberPulse(secretBtn, ["E5171F", "FF7A1A", "3A9BFF"])
    secretBtn.OnEvent("Click", CyberDeckOpen.Bind("Cyber Red"))

    ; ---------------- Advanced window: fine tuning (kept hidden until asked for) ----------------
    advGui := Gui("+Owner" . settingsGui.Hwnd . " +ToolWindow +Resize -MaximizeBox +0x200000", LangT("Advanced Settings"))
    advGui.SetFont("s9")
    advGui.Add("GroupBox", "xm ym w340 h215", LangT("Engine timing (ms) and safety"))
    advGui.Add("Text", "x20 yp+28 w120", LangT("Key Delay:"))
    kdEdit := advGui.Add("Edit", "x150 yp-3 w60", keyDelayDuration)
    advGui.Add("Text", "x20 y+12 w120", LangT("Press Duration:"))
    kpEdit := advGui.Add("Edit", "x150 yp-3 w60", keyDelayPress)
    advGui.Add("Text", "x20 y+12 w120", LangT("Mouse Delay:"))
    mdEdit := advGui.Add("Edit", "x150 yp-3 w60", mouseDelayDuration)
    advGui.Add("Text", "x20 y+12 w120", LangT("Extra press time:"))
    pressExtraEdit := advGui.Add("Edit", "x150 yp-3 w60 Number", pressExtraMs)
    advGui.Add("Text", "x20 y+12 w120", LangT("Auto-detect (sec):"))
    detectSecsEdit := advGui.Add("Edit", "x150 yp-3 w60 Number", autoDetectSecs)
    blurCB := advGui.Add("Checkbox", "x20 y+14 w310" . (releaseOnBlur ? " Checked" : ""), LangT("Let go of everything when the game loses focus"))

    advGui.Add("GroupBox", "xm y+22 w340 h140", LangT("Controller tuning"))
    advGui.Add("Text", "x20 yp+28 w80", LangT("Pad slot:"))
    padDD := advGui.Add("DropDownList", "x105 yp-3 w90 AltSubmit Choose" . (padPort + 1), [LangT("Auto"), LangT("Pad 1"), LangT("Pad 2"), LangT("Pad 3"), LangT("Pad 4")])
    advGui.Add("Text", "x210 yp+3 w70", LangT("Trigger at:"))
    trigEdit := advGui.Add("Edit", "x282 yp-3 w50", padTrigThresh)
    advGui.Add("Text", "x20 y+12 w85", LangT("Deadzone %:"))
    msDeadEdit := advGui.Add("Edit", "x105 yp-3 w50", padMouseDead)
    advGui.Add("Text", "x210 yp+3 w70", LangT("Curve:"))
    msCurveEdit := advGui.Add("Edit", "x282 yp-3 w50 r1", Round(padMouseCurve, 2))
    advGui.Add("Text", "x20 y+12 w100", LangT("Mouse speed %:"))
    scaleEdit := advGui.Add("Edit", "x125 yp-3 w50", mouseScale)
    advGui.Add("Text", "x185 yp+3 w150", LangT("(m / mm / mshake / mh)"))

    advGui.Add("GroupBox", "xm y+22 w340 h92", LangT("System"))
    adminCB := advGui.Add("Checkbox", "x20 yp+26 " . (runAsAdmin ? "Checked" : ""), LangT("Run as Administrator (applies after restart)"))
    logCB := advGui.Add("Checkbox", "x20 y+10 w310 " . (logToFile ? "Checked" : ""), LangT("Write a log file (combo_remapper.log)"))

    advGui.Add("GroupBox", "xm y+22 w340 h115", LangT("Custom RGB Theme Pickers (HEX)"))
    advGui.Add("Text", "x20 yp+28 w130", LangT("Window Background:"))
    bgHexEdit := advGui.Add("Edit", "x150 yp-3 w70", customBgColor)
    advGui.Add("Text", "x20 y+12 w130", LangT("Control Background:"))
    ctrlHexEdit := advGui.Add("Edit", "x150 yp-3 w70", customControlColor)
    advGui.Add("Text", "x20 y+12 w130", LangT("Text Color:"))
    textHexEdit := advGui.Add("Edit", "x150 yp-3 w70", customTextColor)
    advCloseBtn := advGui.Add("Button", "xm y+22 w120 h30", LangT("Done"))
    advCloseBtn.OnEvent("Click", (*) => advGui.Hide())
    secretYBtn := advGui.Add("Text", "x+150 yp-1 w44 h32 +0x200 +0x100 Center Background0A0612", "◈")
    secretYBtn.SetFont("s16 bold cFCEE0A", "Segoe UI Symbol")
    StartCyberPulse(secretYBtn, ["FCEE0A", "00F0FF", "FF2A6D"])
    secretYBtn.OnEvent("Click", CyberDeckOpen.Bind("Cyber Yellow"))
    advGui.OnEvent("Close", (*) => advGui.Hide())
    advGui.Show("Hide")
    advGui.GetClientPos(, , &advCW, &advCH)
    advCloseBtn.GetPos(, &advBtnY, , &advBtnH)
    advContentH := advBtnY + advBtnH + 15
    MonitorGetWorkArea(, , &advWaTop, , &advWaBottom)
    advShowH := Min(advContentH, (advWaBottom - advWaTop) - 110)
    advW := advCW + 24
    MakeGuiScrollable(advGui, advContentH)

    ShowAdvanced() {
        advGui.Show("w" . advW . " h" . advShowH)
        ScrollGuiRefresh(advGui.Hwnd)
    }

    AddTip(compatDD, LangT("How keys and the mouse are sent. If a game ignores the keys, try another mode."))
    AddTip(logCB, LangT("Records errors, profile loads and safety releases in combo_remapper.log so problems can be found. Turn it off to write nothing to disk. Takes effect at once."))
    AddTip(adminCB, LangT("Run as administrator. Needed when the game runs as admin. Applies after a restart."))
    AddTip(autoProfCB, LangT("Switches profile by itself when you open a game whose profile has that Target EXE."))
    AddTip(blurCB, LangT("When you switch away from the game (Alt+Tab, crash, minimize), every held key, toggle and auto-repeat is stopped so nothing gets stuck."))
    AddTip(detectSecsEdit, LangT("How many seconds the Auto, Set and Bind buttons wait for you to press keys (3 to 120). Make it longer if you need more time."))
    AddTip(pressExtraEdit, LangT("Extra milliseconds added to every key press. Helps timed prompts and games that miss short taps."))
    AddTip(padTypeDD, LangT("Auto uses either pad. Xbox reads only Xbox-style pads. PS4 reads only DirectInput pads such as a DualShock."))
    AddTip(padDD, LangT("Which Xbox controller slot to read. Auto picks the first one connected."))
    AddTip(trigEdit, LangT("How far an Xbox trigger (LT/RT) must be pressed to count as a button, 0 to 255."))
    AddTip(msDD, LangT("Lets a stick move the mouse."))
    AddTip(msSpeedEdit, LangT("Mouse speed in pixels per second with the stick fully pushed."))
    AddTip(msDeadEdit, LangT("Percent of stick travel ignored around the centre, so a resting stick does not drift."))
    AddTip(msCurveEdit, LangT("1 = even response. Higher = finer control near the centre and fast at the edge."))
    AddTip(scDD, LangT("Lets a stick scroll the mouse wheel."))
    AddTip(scSpeedEdit, LangT("Scroll notches per second with the stick fully pushed."))
    AddTip(scaleEdit, LangT("Scales every mouse move token (m, mm, mshake, mh). 100 = normal."))
    AddTip(padPanicCB, LangT("Hold the on/off buttons for 1 second to turn the remapper off. Hold them again to turn it back on."))
    AddTip(padSwitchEdit, LangT("Your own on/off buttons, joined with +, for example XLB+XRB+XSTART or J5+J6. Leave blank for the default: Start+Back (Xbox) / Share+Options (PS4)."))
    AddTip(padSwitchBtn, LangT("Click, hold the buttons you want together on the controller, then let go."))
    AddTip(scrollKeyEdit, LangT("Key that sends a mouse wheel scroll click. Press Bind and then the key you want."))
    AddTip(scrollOffCB, LangT("Tick to switch the scroll-click key off completely."))
    AddTip(yLockEdit, LangT("Key that locks the mouse to its current height (Y axis). Press it again to unlock."))
    AddTip(layerEdit, LangT("Key that moves to the next page (a profile). After the last page it goes back to the first. More pages = more actions on the same keys."))
    AddTip(prevEdit, LangT("Key that moves to the previous page. Optional."))
    AddTip(layerDD, LangT("Pick a profile, then press Add. Make each page with New profile. The keys on a page replace the keys of the page before it."))
    AddTip(cheatEdit, LangT("Key that shows or hides a list of every key in this profile on the screen."))
    AddTip(yLockOffCB, LangT("Tick to switch the Y-axis lock off completely."))
    AddTip(kdEdit, LangT("Pause after each key event, in milliseconds."))
    AddTip(kpEdit, LangT("How long each key is held down for a press, in milliseconds."))
    AddTip(mdEdit, LangT("Pause after each mouse action, in milliseconds."))
    AddTip(controllerCB, LangT("Turns controller reading on or off."))
    settingsGui.OnEvent("Close", (*) => (advGui.Destroy(), pagesGui.Destroy(), padGui.Destroy(), settingsGui.Destroy()))
    settingsGui.Show("Hide")
    secretBtn.GetPos(, &btnY, , &btnH)
    settingsContentH := btnY + btnH + 15
    settingsGui.GetClientPos(, , &settingsCW, &settingsCH)
    MonitorGetWorkArea(, , &waTop, , &waBottom)
    settingsShowH := Min(settingsContentH, (waBottom - waTop) - 110)
    settingsGui.Show("w" . (settingsCW + 24) . " h" . settingsShowH)
    MakeGuiScrollable(settingsGui, settingsContentH)
    StartTips(settingsGui.Hwnd)

    SaveSettingsAction() {
        global keyDelayDuration, keyDelayPress, mouseDelayDuration, soundAlerts, showTooltips, showOsd, osdLocked, osdToggleKey
        global customBgColor, customControlColor, customTextColor, Themes, osdGui, scriptEnabled, currentTheme, configFile
        global controllerEnabled, compatMode, runAsAdmin, globalSettingsFile, autoProfile, logToFile
        global pressExtraMs, padPanic, padType, padPort, padMouseStick, padScrollStick, padMouseSpeed, padMouseDead, padMouseCurve, autoDetectSecs, releaseOnBlur
        global padScrollSpeed, padTrigThresh, mouseScale, padSwitchCombo
        global scrollTriggerKey, yLockKey, scrollKeyBox, panicKey, layerKey, layerPrevKey, layerPages, cheatKey, currentProfile

        ; Switch input mode: release anything held with the OLD method first
        if (compatDD.Value >= 1 && compatDD.Value != compatMode) {
            ReleaseAllHeldCombos()
            compatMode := compatDD.Value
            BuildTrayMenu()
        }
        if ((autoProfCB.Value ? true : false) != autoProfile)
            ToggleAutoProfile()
        newAdmin := adminCB.Value ? true : false
        if (newAdmin != runAsAdmin) {
            runAsAdmin := newAdmin
            try IniWrite(runAsAdmin ? 1 : 0, globalSettingsFile, "Global", "RunAsAdmin")
            MsgBox(LangT("The Administrator setting applies the next time the remapper starts."), LangT("Combo ReMapper 9.7"), "Iconi 262144")
        }
        newLog := logCB.Value ? true : false
        if (newLog != logToFile) {
            if (!newLog)
                DiagLog("Logging switched off")
            logToFile := newLog
            try IniWrite(logToFile ? 1 : 0, globalSettingsFile, "Global", "LogToFile")
            if (logToFile)
                DiagLog("Logging switched on")
        }

        if IsNumber(kdEdit.Text) && IsNumber(kpEdit.Text) && IsNumber(mdEdit.Text) {
            keyDelayDuration := Integer(kdEdit.Text)
            keyDelayPress := Integer(kpEdit.Text)
            mouseDelayDuration := Integer(mdEdit.Text)

            SetKeyDelay(keyDelayDuration, keyDelayPress)
            SetMouseDelay(mouseDelayDuration)
        }

        soundAlerts := soundCB.Value
        showTooltips := tooltipCB.Value
        showOsd := osdCB.Value
        osdLocked := osdLockCB.Value

        ; Controller toggle
        newCtrl := controllerCB.Value
        if (newCtrl != controllerEnabled) {
            controllerEnabled := newCtrl
            if (controllerEnabled)
                StartControllerPolling()
            else
                StopControllerPolling()
        }

        ; Controller and mouse settings
        if (padTypeDD.Value >= 1 && padTypeDD.Value != padType)
            SetPadType(padTypeDD.Value)
        padPort := padDD.Value - 1
        if IsInteger(pressExtraEdit.Text)
            pressExtraMs := Max(0, Min(500, Integer(pressExtraEdit.Text)))
        if IsInteger(detectSecsEdit.Text)
            autoDetectSecs := Max(3, Min(120, Integer(detectSecsEdit.Text)))
        releaseOnBlur := blurCB.Value ? true : false
        padPanic := padPanicCB.Value ? true : false
        padSwitchCombo := StrUpper(RegExReplace(Trim(padSwitchEdit.Text), "\s+", ""))
        padMouseStick := msDD.Value - 1
        padScrollStick := scDD.Value - 1
        if IsInteger(trigEdit.Text)
            padTrigThresh := Max(5, Min(250, Integer(trigEdit.Text)))
        if IsInteger(msSpeedEdit.Text)
            padMouseSpeed := Max(50, Min(5000, Integer(msSpeedEdit.Text)))
        if IsInteger(msDeadEdit.Text)
            padMouseDead := Max(0, Min(80, Integer(msDeadEdit.Text)))
        if IsNumber(msCurveEdit.Text)
            padMouseCurve := Max(1.0, Min(4.0, Float(msCurveEdit.Text)))
        if IsInteger(scSpeedEdit.Text)
            padScrollSpeed := Max(1, Min(60, Integer(scSpeedEdit.Text)))
        if IsInteger(scaleEdit.Text)
            mouseScale := Max(10, Min(500, Integer(scaleEdit.Text)))
        UpdatePadMouseTimer()

        osdToggleKey := Trim(osdKeyBox.Text)
        RegisterOsdHotkey()

        ; Scroll-click key and Y-axis lock key (a ticked Off box disables the feature)
        newScroll := scrollOffCB.Value ? "" : Trim(scrollKeyEdit.Text)
        newYLock := yLockOffCB.Value ? "" : Trim(yLockEdit.Text)
        if (newYLock != "" && (StrUpper(newYLock) = StrUpper(newScroll) || StrUpper(newYLock) = StrUpper(panicKey) || StrUpper(newYLock) = StrUpper(osdToggleKey))) {
            MsgBox(LangT("The Y-axis lock key ('") . newYLock . LangT("') is already used by another hotkey. Pick a different one."), LangT("Combo ReMapper 9.7"), "Icon! 262144")
            newYLock := yLockKey
        }
        scrollTriggerKey := newScroll
        if (scrollKeyBox != "")
            scrollKeyBox.Text := scrollTriggerKey
        RegisterScrollHotkey()
        yLockKey := newYLock
        RegisterYLockHotkey()

        ; Page keys and cheat-sheet key
        newLayer := layerOffCB.Value ? "" : Trim(layerEdit.Text)
        newPrev := prevOffCB.Value ? "" : Trim(prevEdit.Text)
        newCheat := cheatOffCB.Value ? "" : Trim(cheatEdit.Text)
        if (newLayer != "" && KeyClash(newLayer, [scrollTriggerKey, yLockKey, panicKey, osdToggleKey, newPrev, newCheat])) {
            MsgBox(LangT("The next-page key ('") . newLayer . LangT("') is already used by another hotkey. Pick a different one."), LangT("Combo ReMapper 9.7"), "Icon! 262144")
            newLayer := layerKey
        }
        if (newPrev != "" && KeyClash(newPrev, [scrollTriggerKey, yLockKey, panicKey, osdToggleKey, newLayer, newCheat])) {
            MsgBox(LangT("The previous-page key ('") . newPrev . LangT("') is already used by another hotkey. Pick a different one."), LangT("Combo ReMapper 9.7"), "Icon! 262144")
            newPrev := layerPrevKey
        }
        if (newCheat != "" && KeyClash(newCheat, [scrollTriggerKey, yLockKey, panicKey, osdToggleKey, newLayer, newPrev])) {
            MsgBox(LangT("The cheat-sheet key ('") . newCheat . LangT("') is already used by another hotkey. Pick a different one."), LangT("Combo ReMapper 9.7"), "Icon! 262144")
            newCheat := cheatKey
        }
        layerKey := newLayer
        layerPrevKey := newPrev
        cheatKey := newCheat
        layerPages := layerWork.Clone()
        RegisterExtraHotkeys()
        RegisterExtraHotkeys()
        RegisterYLockHotkey()
        RegisterExtraHotkeys()

        if (osdGui != "") {
            osdGui.Destroy()
            osdGui := ""
        }
        if (showOsd) {
            BuildOSD()
            UpdateOSD(scriptEnabled ? LangT("REMAPPER: ACTIVE") : LangT("REMAPPER: DISABLED"), scriptEnabled ? "00FF00" : "FF0000")
        }

        customBgColor := Trim(bgHexEdit.Text)
        customControlColor := Trim(ctrlHexEdit.Text)
        customTextColor := Trim(textHexEdit.Text)

        Themes["Custom Image"]["bg"] := customBgColor
        Themes["Custom Image"]["controlBg"] := customControlColor
        Themes["Custom Image"]["text"] := customTextColor

        SaveStateToINI(configFile)
        ApplyTheme(currentTheme)

        try advGui.Destroy()
        try pagesGui.Destroy()
        try padGui.Destroy()
        settingsGui.Destroy()
        NotifyUser(LangT("Settings successfully applied!"))
    }
}

; ============================================================
; OPTIONS MENU & EXTENSIONS
; ============================================================
OpenOptionsMenu(slotIdx, *) {
    global rowUI, rows, scrollOffset

    targetCB := rowUI[slotIdx].cb
    targetIdx := scrollOffset + slotIdx
    rowExists := (targetIdx <= rows.Length)
    isTurbo := rowExists && rows[targetIdx].mode = "turbo"

    rowMenu := Menu()
    rowMenu.Add(LangT("Test Fire This Combo Now"), (*) => TestFireCombo(targetCB))
    if (isTurbo)
        rowMenu.Add(LangT("Set Turbo Interval (ms)..."), (*) => SetTurboInterval(slotIdx))
    rowMenu.Add()
    rowMenu.Add(LangT("Extend Combo (Append directly)"), (*) => ExtendComboDirect(targetCB))
    rowMenu.Add(LangT("Add Pause Delay (ms)"), (*) => AddDelayPrompt(targetCB))
    rowMenu.Add()
    rowMenu.Add(LangT("Prepend Key (Prefix)"), (*) => PrependKeyPrompt(targetCB))
    rowMenu.Add(LangT("Append Key (Suffix)"), (*) => AppendKeyPrompt(targetCB))
    rowMenu.Add()
    rowMenu.Add(LangT("Insert Mouse Move (Relative)"), (*) => InsertMouseMove(targetCB, false))
    rowMenu.Add(LangT("Insert Mouse Move (Absolute)"), (*) => InsertMouseMove(targetCB, true))
    rowMenu.Add(LangT("Insert Mouse Click (Left/Right/Middle)"), (*) => InsertMouseClick(targetCB))
    rowMenu.Add(LangT("Insert Smooth Mouse Move (over time)"), (*) => InsertSmoothMove(targetCB))
    rowMenu.Add(LangT("Insert Camera Shake"), (*) => InsertShake(targetCB))
    rowMenu.Add(LangT("Insert Continuous Move (while held / toggled)"), (*) => InsertHoldMove(targetCB))
    rowMenu.Add()
    rowMenu.Add(LangT("Edit Row Note..."), (*) => EditRowNote(slotIdx))
    rowMenu.Add(LangT("Duplicate Row"), (*) => DuplicateRowSlot(slotIdx))
    rowMenu.Add(LangT("Clear Row Inputs"), (*) => ClearRowSlot(slotIdx))

    rowMenu.Show()
}

; ---- Extra mouse helpers in the Options menu ----
InsertMouseMove(cbControl, absolute) {
    prompt := absolute
        ? LangT("Enter absolute X,Y coordinates (e.g. 400,300):")
        : LangT("Enter relative dx,dy movement (e.g. 10,-5):")
    ib := InputBox(prompt, LangT("Insert Mouse Move"), "w300 h130")
    if (ib.Result != "OK")
        return
    val := Trim(ib.Value)
    if !RegExMatch(val, "^-?\d+\s*,\s*-?\d+$") {
        NotifyUser(LangT("Invalid format. Use dx,dy (numbers only)."))
        return
    }
    val := StrReplace(val, " ", "")
    token := (absolute ? "mx" : "m") . val
    current := Trim(cbControl.Text)
    cbControl.Text := (current != "") ? current . "," . token : token
    NotifyUser(LangT("Inserted: ") . token)
}

AppendComboToken(cbControl, token) {
    current := Trim(cbControl.Text)
    cbControl.Text := (current != "") ? current . "," . token : token
    NotifyUser(LangT("Inserted: ") . token)
}

InsertSmoothMove(cbControl) {
    ib := InputBox(LangT("Total dx,dy and duration in ms, separated by commas`n(e.g. 200,0,500 moves 200 px right over half a second):"), LangT("Insert Smooth Mouse Move"), "w360 h150")
    if (ib.Result != "OK")
        return
    val := StrReplace(Trim(ib.Value), " ", "")
    if !RegExMatch(val, "^-?\d+,-?\d+,\d+$") {
        NotifyUser(LangT("Invalid format. Use dx,dy,ms (e.g. 200,0,500)."))
        return
    }
    AppendComboToken(cbControl, "mm" . val)
}

InsertShake(cbControl) {
    ib := InputBox(LangT("Shake strength in pixels and duration in ms`n(e.g. 12,600 = jitter up to 12 px for 0.6 s):"), LangT("Insert Camera Shake"), "w360 h150")
    if (ib.Result != "OK")
        return
    val := StrReplace(Trim(ib.Value), " ", "")
    if !RegExMatch(val, "^\d+,\d+$") {
        NotifyUser(LangT("Invalid format. Use strength,ms (e.g. 12,600)."))
        return
    }
    AppendComboToken(cbControl, "mshake" . val)
}

InsertHoldMove(cbControl) {
    ib := InputBox(LangT("Speed vx,vy in pixels per second, while the trigger is held (Hold rows) or on (Toggle rows)`n(e.g. 300,0 = steady turn right; negative = left/up):"), LangT("Insert Continuous Move"), "w400 h160")
    if (ib.Result != "OK")
        return
    val := StrReplace(Trim(ib.Value), " ", "")
    if !RegExMatch(val, "^-?\d+,-?\d+$") {
        NotifyUser(LangT("Invalid format. Use vx,vy (e.g. 300,0)."))
        return
    }
    AppendComboToken(cbControl, "mh" . val)
}

InsertMouseClick(cbControl) {
    ib := InputBox(LangT("Enter click type (L = left, R = right, M = middle):"), LangT("Insert Mouse Click"), "w300 h130")
    if (ib.Result != "OK")
        return
    v := StrUpper(Trim(ib.Value))
    token := ""
    if (v = "L")
        token := "mlc"
    else if (v = "R")
        token := "mrc"
    else if (v = "M")
        token := "mmc"
    else {
        NotifyUser(LangT("Invalid choice. Use L, R, or M."))
        return
    }
    current := Trim(cbControl.Text)
    cbControl.Text := (current != "") ? current . "," . token : token
    NotifyUser(LangT("Inserted: ") . token)
}

TestFireCombo(cbControl) {
    keys := ParseKeyList(cbControl.Text)
    if (keys.Length = 0) {
        NotifyUser(LangT("Nothing to test - combo is empty"))
        return
    }
    NotifyUser(LangT("Test firing combo..."))
    ExecuteComboSequence(keys)
}

SetTurboInterval(slotIdx) {
    global rows, scrollOffset
    SyncBoxesToRows()
    targetIdx := scrollOffset + slotIdx
    if (targetIdx > rows.Length)
        return
    current := rows[targetIdx].HasOwnProp("turboMs") ? rows[targetIdx].turboMs : 60
    ib := InputBox(LangT("Turbo repeat interval in milliseconds (lower = faster):"), LangT("Turbo Interval"), "w280 h130", current)
    if (ib.Result = "OK" && IsNumber(Trim(ib.Value)) && Integer(Trim(ib.Value)) > 0) {
        rows[targetIdx].turboMs := Integer(Trim(ib.Value))
        NotifyUser(LangT("Turbo interval set to ") . rows[targetIdx].turboMs . LangT("ms"))
    }
}

AddDelayPrompt(cbControl) {
    ib := InputBox(LangT("Enter pause delay in milliseconds (e.g. 150):"), LangT("Add Sequence Delay"), "w260 h130")
    if (ib.Result = "OK" && IsNumber(Trim(ib.Value))) {
        delayVal := "d" . Trim(ib.Value)
        current := Trim(cbControl.Text)
        cbControl.Text := (current != "") ? current . "," . delayVal : delayVal
    }
}

ExtendComboDirect(cbControl) {
    ib := InputBox(LangT("Enter key sequence to append directly (e.g. shift,w):"), LangT("Extend Combo"), "w280 h130")
    if (ib.Result = "OK" && Trim(ib.Value) != "") {
        extension := Trim(ib.Value)
        current := Trim(cbControl.Text)
        if (current != "") {
            cbControl.Text := (SubStr(current, -1) = ",") ? current . extension : current . "," . extension
        } else {
            cbControl.Text := extension
        }
    }
}

PrependKeyPrompt(cbControl) {
    ib := InputBox(LangT("Enter key(s) to PREPEND (e.g. shift, ctrl):"), LangT("Prepend Key"), "w260 h130")
    if (ib.Result = "OK" && Trim(ib.Value) != "") {
        prefix := Trim(ib.Value)
        current := Trim(cbControl.Text)
        cbControl.Text := (current != "") ? prefix . "," . current : prefix
    }
}

AppendKeyPrompt(cbControl) {
    ib := InputBox(LangT("Enter key(s) to APPEND (e.g. enter, space):"), LangT("Append Key"), "w260 h130")
    if (ib.Result = "OK" && Trim(ib.Value) != "") {
        suffix := Trim(ib.Value)
        current := Trim(cbControl.Text)
        if (current != "") {
            cbControl.Text := (SubStr(current, -1) = ",") ? current . suffix : current . "," . suffix
        } else {
            cbControl.Text := suffix
        }
    }
}

DuplicateRowSlot(slotIdx) {
    global rows, nextRowId, scrollOffset, VISIBLE_ROWS
    SyncBoxesToRows()
    targetIdx := scrollOffset + slotIdx
    if (targetIdx <= rows.Length) {
        orig := rows[targetIdx]
        rows.Push({id: nextRowId, trigger: orig.trigger != "" ? orig.trigger . "_copy" : "", keys: orig.keys.Clone(), mode: orig.mode, enabled: orig.HasOwnProp("enabled") ? orig.enabled : true, turboMs: orig.HasOwnProp("turboMs") ? orig.turboMs : 60, note: orig.HasOwnProp("note") ? orig.note : ""})
        nextRowId += 1
        scrollOffset := Max(0, rows.Length - VISIBLE_ROWS)
        UpdateSliderLimits()
        RenderAll(true)
    }
}

ClearRowSlot(slotIdx) {
    global rowUI
    rowUI[slotIdx].tb.Text := ""
    rowUI[slotIdx].cb.Text := ""
    rowUI[slotIdx].dd.Choose(1)
    rowUI[slotIdx].enChk.Value := 1
}

; ============================================================
; THEME ENGINE
; ============================================================
ApplyTheme(themeName) {
    global myGui, Themes, bgPicControl, textControls, rowUI, panicKeyBox, scrollKeyBox, targetExeBox
    if !Themes.Has(themeName)
        return

    palette := Themes[themeName]
    textColor := palette["text"]
    bgColor := palette["bg"]
    ctrlBg := palette["controlBg"]

    if (themeName = "Custom Image" && palette["img"] != "" && FileExist(palette["img"])) {
        bgPicControl.Value := palette["img"]
        bgPicControl.Visible := true
    } else {
        bgPicControl.Visible := false
        myGui.BackColor := bgColor
    }

    for ctrl in textControls {
        ctrl.SetFont("c" . textColor)
    }

    allEdits := [panicKeyBox, scrollKeyBox, targetExeBox]
    for slot in rowUI {
        allEdits.Push(slot.tb, slot.cb)
    }

    editColor := palette.Has("edit") ? palette["edit"] : textColor
    SetTimer(CyberRefreshOSD, -50)
    SetTimer(CyberGlitch, CyberTheme(themeName) ? 3000 : 0)
    for ed in allEdits {
        ed.Opt("Background" . ctrlBg)
        ed.SetFont("c" . editColor)
        ed.Redraw()
    }

    if (myGui != "")
        WinRedraw(myGui.Hwnd)
}

; ============================================================
; HIDDEN COLOUR THEMES: Cyber Red and Cyber Yellow
; Each is unlocked by winning a small on-screen puzzle (the "cyber deck"). Cyber Red: the lightning
; bolt in Settings. Cyber Yellow: the diamond next to Done in Advanced Settings.
; ============================================================
CyberTheme(name) {
    return (name = "Cyber Red" || name = "Cyber Yellow")
}

CyberIsUnlocked(name) {
    global dataDir
    key := "Unlock_" . StrReplace(name, " ", "")
    try return (IniRead(dataDir "\remapper_global.ini", "Global", key, "0") = "1")
    return false
}

CyberLook(name) {
    if (name = "Cyber Yellow")
        return Map("text", "FCEE0A", "flash", "FF2A6D", "on", "FCEE0A", "off", "FF2A6D", "info", "00F0FF", "osdBg", "0E0A1A"
            , "deckBg", "0A0612", "boot", "FCEE0A", "cols", ["FCEE0A", "00F0FF", "FF2A6D"]
            , "bright", ["FCEE0A", "00F0FF", "FF2A6D", "F4EDE4"], "dim", ["4D4803", "04484D", "4D1022", "4A4744"], "len", 6)
    return Map("text", "F4EDE4", "flash", "E5171F", "on", "FF7A1A", "off", "9B1C1F", "info", "3A9BFF", "osdBg", "140A0A"
        , "deckBg", "0F0D0D", "boot", "E5171F", "cols", ["E5171F", "FF7A1A", "3A9BFF"]
        , "bright", ["E5171F", "FF7A1A", "3A9BFF", "F4EDE4"], "dim", ["4A0A0D", "4D2406", "122C4D", "4A4744"], "len", 5)
}

CyberRefreshOSD() {
    global osdGui, scriptEnabled
    if (osdGui = "")
        return
    UpdateOSD(scriptEnabled ? LangT("REMAPPER: ACTIVE") : LangT("REMAPPER: DISABLED"), scriptEnabled ? "00FF00" : "FF0000")
}

; While a cyber theme is on, the labels flash for a split second every few seconds (a glitch).
CyberGlitch() {
    global textControls, currentTheme
    if (!CyberTheme(currentTheme) || !IsObject(textControls))
        return
    look := CyberLook(currentTheme)
    for ctrl in textControls {
        try ctrl.SetFont("c" . look["flash"])
    }
    SetTimer(CyberGlitchRestore, -90)
}

CyberGlitchRestore() {
    global textControls, currentTheme
    if (!CyberTheme(currentTheme) || !IsObject(textControls))
        return
    look := CyberLook(currentTheme)
    for ctrl in textControls {
        try ctrl.SetFont("c" . look["text"])
    }
}

; The secret buttons pulse through the theme's three colours while their window is open.
StartCyberPulse(ctl, cols) {
    global cyberPulseList
    cyberPulseList.Push({ctl: ctl, cols: cols})
    SetTimer(CyberPulse, 450)
}

CyberPulse() {
    global cyberPulseList
    static idx := 0
    idx += 1
    alive := []
    for item in cyberPulseList {
        try {
            item.ctl.SetFont("c" . item.cols[Mod(idx, 3) + 1])
            alive.Push(item)
        }
    }
    cyberPulseList := alive
    if (alive.Length = 0)
        SetTimer(CyberPulse, 0)
}

; The puzzle: a "cyber deck" with four big buttons. They light up in a random order; click the same
; buttons in the same order. A wrong button gives ACCESS DENIED and a new pattern. REPLAY shows it again.
CyberDeckOpen(themeName, *) {
    global cyDeck, cyDeckBtns, cyDeckStatus, cyDeckTheme
    if (IsObject(cyDeck)) {
        try cyDeck.Show()
        return
    }
    cyDeckTheme := themeName
    look := CyberLook(themeName)
    cyDeck := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox", LangT("CYBER DECK"))
    cyDeck.BackColor := look["deckBg"]
    cyDeck.SetFont("s11 bold c" . look["boot"], "Consolas")
    cyDeckStatus := cyDeck.Add("Text", "x16 y12 w244 h24 Center", "")
    cyDeckBtns := []
    glyphs := ["▲", "●", "■", "◆"]
    cyDeck.SetFont("s26 bold cF4EDE4", "Segoe UI Symbol")
    Loop 4 {
        col := Mod(A_Index - 1, 2)
        row := (A_Index - 1) // 2
        b := cyDeck.Add("Text", "x" . (16 + col * 126) . " y" . (44 + row * 86) . " w118 h78 +0x200 +0x100 Center Background" . look["dim"][A_Index], glyphs[A_Index])
        b.OnEvent("Click", CyberDeckClick.Bind(A_Index))
        cyDeckBtns.Push(b)
    }
    cyDeck.SetFont("s9 norm cF4EDE4", "Segoe UI")
    rp := cyDeck.Add("Text", "x16 y222 w244 h22 Center +0x100", "↻ " . LangT("REPLAY"))
    rp.OnEvent("Click", (*) => CyberDeckStart(false))
    cyDeck.SetFont("s8 italic cA89F96", "Segoe UI")
    cyDeck.Add("Text", "x16 y250 w244 h30 Center", LangT("Just a fun project. Not affiliated with any company."))
    cyDeck.OnEvent("Close", CyberDeckClose)
    cyDeck.Show("w276 h290")
    CyberDeckStart(true)
}

CyberDeckSetStatus(text, color := "") {
    global cyDeck, cyDeckStatus, cyDeckTheme
    if (!IsObject(cyDeck))
        return
    if (color = "")
        color := CyberLook(cyDeckTheme)["boot"]
    try cyDeckStatus.SetFont("c" . color)
    try cyDeckStatus.Value := text
}

CyberDeckLight(i, on := true) {
    global cyDeck, cyDeckBtns, cyDeckTheme
    if (!IsObject(cyDeck))
        return
    look := CyberLook(cyDeckTheme)
    try {
        cyDeckBtns[i].Opt("Background" . (on ? look["bright"][i] : look["dim"][i]))
        cyDeckBtns[i].Redraw()
    }
}

CyberDeckStart(newSeq := true) {
    global cyDeck, cyDeckSeq, cyDeckPos, cyDeckLocked, cyDeckStepNo, cyDeckTheme
    if (!IsObject(cyDeck))
        return
    if (newSeq) {
        cyDeckSeq := []
        Loop CyberLook(cyDeckTheme)["len"]
            cyDeckSeq.Push(Random(1, 4))
    }
    cyDeckPos := 0
    cyDeckLocked := true
    cyDeckStepNo := 0
    Loop 4
        CyberDeckLight(A_Index, false)
    CyberDeckSetStatus(LangT("WATCH"), CyberLook(cyDeckTheme)["cols"][2])
    SetTimer(CyberDeckTick, 350)
}

CyberDeckTick() {
    global cyDeck, cyDeckSeq, cyDeckLocked, cyDeckStepNo, cyDeckTheme
    if (!IsObject(cyDeck)) {
        SetTimer(CyberDeckTick, 0)
        return
    }
    cyDeckStepNo += 1
    if (cyDeckStepNo > cyDeckSeq.Length * 2) {
        SetTimer(CyberDeckTick, 0)
        Loop 4
            CyberDeckLight(A_Index, false)
        cyDeckLocked := false
        CyberDeckSetStatus(LangT("REPEAT"), CyberLook(cyDeckTheme)["cols"][3])
        return
    }
    if (Mod(cyDeckStepNo, 2) = 1) {
        CyberDeckLight(cyDeckSeq[(cyDeckStepNo + 1) // 2], true)
    } else {
        Loop 4
            CyberDeckLight(A_Index, false)
    }
}

CyberDeckClick(i, *) {
    global cyDeck, cyDeckSeq, cyDeckPos, cyDeckLocked, cyDeckTheme
    if (!IsObject(cyDeck) || cyDeckLocked)
        return
    CyberDeckLight(i, true)
    SetTimer(() => CyberDeckLight(i, false), -180)
    if (i = cyDeckSeq[cyDeckPos + 1]) {
        cyDeckPos += 1
        if (cyDeckPos >= cyDeckSeq.Length) {
            cyDeckLocked := true
            CyberDeckSetStatus(LangT("ACCESS GRANTED"), CyberLook(cyDeckTheme)["cols"][2])
            SetTimer(CyberDeckWin, -700)
        }
    } else {
        cyDeckLocked := true
        CyberDeckSetStatus(LangT("ACCESS DENIED"), CyberLook(cyDeckTheme)["flash"])
        SetTimer(() => CyberDeckStart(true), -1000)
    }
}

CyberDeckWin() {
    global cyDeckTheme
    won := cyDeckTheme
    CyberDeckClose()
    UnlockCyber(won, true)
}

CyberDeckClose(*) {
    global cyDeck
    SetTimer(CyberDeckTick, 0)
    if (IsObject(cyDeck)) {
        try cyDeck.Destroy()
    }
    cyDeck := ""
}

UnlockCyber(name, select := true) {
    global themeDD, cyberUnlocked, dataDir
    if (themeDD = "" || !CyberTheme(name))
        return
    try IniWrite("1", dataDir "\remapper_global.ini", "Global", "Unlock_" . StrReplace(name, " ", ""))
    if (!cyberUnlocked[name]) {
        themeDD.Add([name])
        cyberUnlocked[name] := true
    }
    if (select)
        StartCyberSequence(name)
}

; The unlock animation: a boot text types itself out on a black panel with colour glitches and jitter,
; then the window flickers between the old theme and the new one and settles.
StartCyberSequence(themeName) {
    global cySeqGui, cySeqCtl, cySeqFull, cySeqTick, cySeqBase, cySeqPrev, cySeqTheme, myGui, currentTheme
    if (IsObject(cySeqGui))
        return
    cySeqPrev := CyberTheme(currentTheme) ? "Dark" : currentTheme
    cySeqTheme := themeName
    look := CyberLook(themeName)
    cySeqFull := LangT("> CONNECTING...") . "`n" . LangT("> BYPASSING SECURITY") . "`n" . LangT("> ACCESS CODE ACCEPTED") . "`n" . LangT("> WELCOME, OPERATOR")
    cySeqTick := 0
    cySeqGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    cySeqGui.BackColor := look["deckBg"]
    cySeqGui.SetFont("s12 c" . look["boot"], "Consolas")
    cySeqCtl := cySeqGui.Add("Text", "x14 y12 w412 h96 +BackgroundTrans", "")
    px := (A_ScreenWidth - 440) // 2
    py := (A_ScreenHeight - 120) // 2
    try {
        WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " . myGui.Hwnd)
        px := wx + (ww - 440) // 2
        py := wy + (wh - 120) // 2
    }
    cySeqBase := [px, py]
    cySeqGui.Show("NoActivate w440 h120 x" . px . " y" . py)
    SetTimer(CyberSeqStep, 40)
}

CyberSeqStep() {
    global cySeqGui, cySeqCtl, cySeqFull, cySeqTick, cySeqBase, cySeqPrev, cySeqTheme, themeDD, currentTheme
    if (!IsObject(cySeqGui)) {
        SetTimer(CyberSeqStep, 0)
        return
    }
    cySeqTick += 1
    look := CyberLook(cySeqTheme)
    len := StrLen(cySeqFull)
    typeTicks := Ceil(len / 2)
    typed := Min(cySeqTick * 2, len)
    cursor := (Mod(cySeqTick, 4) < 2) ? "_" : " "
    try cySeqCtl.Value := SubStr(cySeqFull, 1, typed) . cursor
    if (Random(1, 100) <= 18) {
        try cySeqCtl.SetFont("c" . look["cols"][Random(1, 3)])
        try cySeqGui.Move(cySeqBase[1] + Random(-4, 4), cySeqBase[2] + Random(-3, 3))
    } else if (cySeqTick > typeTicks) {
        try cySeqGui.Move(cySeqBase[1], cySeqBase[2])
    }
    flickerStart := typeTicks + 15
    if (cySeqTick > flickerStart && cySeqTick <= flickerStart + 8) {
        ApplyTheme((Mod(cySeqTick, 2) = 0) ? cySeqPrev : cySeqTheme)
        return
    }
    if (cySeqTick > flickerStart + 8) {
        SetTimer(CyberSeqStep, 0)
        try cySeqGui.Destroy()
        cySeqGui := ""
        currentTheme := cySeqTheme
        try themeDD.Choose(cySeqTheme)
        ApplyTheme(currentTheme)
        ToolTip((cySeqTheme = "Cyber Yellow") ? LangT("Cyber Yellow theme unlocked.") : LangT("Cyber Red theme unlocked."))
        SetTimer(() => ToolTip(), -2500)
    }
}

ChangeTheme(ctrl, *) {
    global currentTheme, Themes
    newTheme := ctrl.Text

    if (newTheme = "Custom Image") {
        selectedImg := FileSelect("", A_ScriptDir, LangT("Select Custom Background Image"), LangT("Image Files") . " (*.png; *.jpg; *.jpeg; *.bmp)")
        if (selectedImg != "") {
            Themes["Custom Image"]["img"] := selectedImg
        } else if (Themes["Custom Image"]["img"] = "" || !FileExist(Themes["Custom Image"]["img"])) {
            ctrl.Choose(currentTheme)
            return
        }
    }

    currentTheme := newTheme
    ApplyTheme(currentTheme)
}

; ============================================================
; PROFILE ENGINE
; ============================================================
SwitchProfile(ctrl, *) {
    global layerBase, layerSwitching, layerIdx
    if (!layerSwitching) {
        layerBase := ""
        layerIdx := 0
    }
    global currentProfile, configFile, profilesDir, panicKeyBox, scrollKeyBox, targetExeBox, themeDD, rows, scrollOffset, currentTheme, targetExe, scrollTriggerKey, panicKey, osdToggleKey

    ReleaseAllHeldCombos()

    targetProf := ctrl.Text
    if (targetProf = "")
        return

    if FileExist(configFile) {
        SyncBoxesToRows()
        SaveStateToINI(configFile)
    }

    currentProfile := targetProf
    configFile := profilesDir "\" currentProfile ".ini"
    SaveLastProfile()

    rows := []
    LoadState()

    panicKeyBox.Text := panicKey
    scrollKeyBox.Text := scrollTriggerKey
    targetExeBox.Text := targetExe

    if (themeDD != "") {
        if (CyberTheme(currentTheme))
            UnlockCyber(currentTheme, false)
        try themeDD.Choose(currentTheme)
        ApplyTheme(currentTheme)
    }

    RegisterRowHotkeys()
    RegisterScrollHotkey()
    RegisterPanicHotkey()
    RegisterOsdHotkey()
    RegisterYLockHotkey()
    RegisterExtraHotkeys()
    BuildTrayMenu()

    scrollOffset := 0
    UpdateSliderLimits()
    RenderAll(true)
}

CreateNewProfile(*) {
    global profileDD, profilesDir
    ib := NamePrompt(LangT("New Profile"), LangT("Enter name for new profile:"))
    if (ib.Result = "OK" && Trim(ib.Value) != "") {
        newName := Trim(ib.Value)
        newPath := profilesDir "\" newName ".ini"

        SyncBoxesToRows()
        SaveStateToINI(newPath)

        profileDD.OnEvent("Change", SwitchProfile, -1)
        profileDD.Delete()
        profileDD.Add(GetProfileList())
        profileDD.OnEvent("Change", SwitchProfile, 1)

        profileDD.Choose(newName)
        SwitchProfile(profileDD)
    }
}

DeleteProfile(*) {
    global currentProfile, configFile, profileDD, profilesDir, rows, scrollOffset
    global panicKeyBox, scrollKeyBox, targetExeBox, panicKey, scrollTriggerKey, targetExe

    if (StrLower(currentProfile) = "default") {
        MsgBox(LangT("The 'default' profile cannot be deleted."), LangT("Delete Profile"), "Icon! 262144")
        return
    }

    result := MsgBox(LangT("Are you sure you want to delete profile '") . currentProfile . "'?", LangT("Delete Profile"), "YesNo Icon? 262144")
    if (result != "Yes")
        return

    fileToDelete := configFile
    profileList := GetProfileList()
    targetProf := ""

    for p in profileList {
        if (p != currentProfile) {
            targetProf := p
            break
        }
    }

    if (targetProf = "") {
        targetProf := "default"
    }

    profileDD.OnEvent("Change", SwitchProfile, -1)

    if FileExist(fileToDelete)
        FileDelete(fileToDelete)

    currentProfile := targetProf
    configFile := profilesDir "\" targetProf ".ini"
    SaveLastProfile()

    if !FileExist(configFile) {
        SaveStateToINI(configFile)
    }

    newList := GetProfileList()
    profileDD.Delete()
    profileDD.Add(newList)
    try profileDD.Choose(currentProfile)
    catch
        try profileDD.Choose(1)
    profileDD.OnEvent("Change", SwitchProfile, 1)

    rows := []
    LoadState()

    if (panicKeyBox != "")
        panicKeyBox.Text := panicKey
    if (scrollKeyBox != "")
        scrollKeyBox.Text := scrollTriggerKey
    if (targetExeBox != "")
        targetExeBox.Text := targetExe

    RegisterRowHotkeys()
    RegisterScrollHotkey()
    RegisterPanicHotkey()
    RegisterOsdHotkey()
    RegisterYLockHotkey()
    RegisterExtraHotkeys()
    BuildTrayMenu()

    scrollOffset := 0
    UpdateSliderLimits()
    RenderAll(true)
}

; ============================================================
; GUI EVENT HANDLERS
; ============================================================
OnMouseWheel(wParam, lParam, msg, hwnd) {
    global rows, VISIBLE_ROWS
    total := rows.Length
    maxOffset := Max(0, total - VISIBLE_ROWS)
    if (maxOffset <= 0)
        return

    delta := wParam >> 16
    if (delta > 0x7FFF)
        delta -= 0x10000

    ScrollRowsBy(delta > 0 ? -1 : 1)
}

ScrollRowsBy(delta) {
    global scrollOffset, rows, VISIBLE_ROWS
    maxOffset := Max(0, rows.Length - VISIBLE_ROWS)
    if (maxOffset <= 0)
        return
    SyncBoxesToRows()
    scrollOffset := Max(0, Min(maxOffset, scrollOffset + delta))
    RenderAll(true)
}

SyncBoxesToRows() {
    global rows, rowUI, scrollOffset, VISIBLE_ROWS, panicKeyBox, panicKey, scrollKeyBox, scrollTriggerKey, targetExeBox, targetExe
    total := rows.Length
    loop VISIBLE_ROWS {
        slotIdx := A_Index
        rowIdx := scrollOffset + slotIdx
        if (rowIdx <= total) {
            row := rows[rowIdx]
            row.trigger := Trim(rowUI[slotIdx].tb.Text)
            row.keys := ParseKeyList(rowUI[slotIdx].cb.Text)
            modeIdx := rowUI[slotIdx].dd.Value
            modeNames := ["hold", "toggle", "press", "turbo", "taphold", "doubletap", "autoturbo"]
            row.mode := (modeIdx >= 1 && modeIdx <= 7) ? modeNames[modeIdx] : "hold"
            row.enabled := rowUI[slotIdx].enChk.Value ? true : false
        }
    }
    if (panicKeyBox != "")
        panicKey := Trim(panicKeyBox.Text)
    if (scrollKeyBox != "")
        scrollTriggerKey := Trim(scrollKeyBox.Text)
    if (targetExeBox != "")
        targetExe := NormalizeExe(targetExeBox.Text)
}

UpdateSliderLimits() {
    global rows, rowSlider, VISIBLE_ROWS, scrollUpBtn, scrollDownBtn
    total := rows.Length
    maxOffset := Max(0, total - VISIBLE_ROWS)
    if (maxOffset > 0) {
        rowSlider.Opt("Range0-" . maxOffset)
        rowSlider.Visible := true
        scrollUpBtn.Visible := true
        scrollDownBtn.Visible := true
    } else {
        rowSlider.Visible := false
        scrollUpBtn.Visible := false
        scrollDownBtn.Visible := false
    }
}

RenderAll(updateSliderVal := true) {
    global rows, rowUI, rowSlider, scrollLabel, scrollOffset, VISIBLE_ROWS

    total := rows.Length
    maxOffset := Max(0, total - VISIBLE_ROWS)

    if (scrollOffset > maxOffset)
        scrollOffset := maxOffset
    if (scrollOffset < 0)
        scrollOffset := 0

    loop VISIBLE_ROWS {
        slotIdx := A_Index
        rowIdx := scrollOffset + slotIdx

        if (rowIdx <= total) {
            row := rows[rowIdx]
            rowUI[slotIdx].tb.Text := row.trigger
            rowUI[slotIdx].cb.Text := KeyListToString(row.keys)
            rowUI[slotIdx].dd.Choose(row.mode = "toggle" ? 2 : (row.mode = "press" ? 3 : (row.mode = "turbo" ? 4 : (row.mode = "taphold" ? 5 : (row.mode = "doubletap" ? 6 : (row.mode = "autoturbo" ? 7 : 1))))))
            rowUI[slotIdx].enChk.Value := (row.HasOwnProp("enabled") ? row.enabled : true) ? 1 : 0

            rowUI[slotIdx].tb.Visible := true
            rowUI[slotIdx].trigBtn.Visible := true
            rowUI[slotIdx].cb.Visible := true
            rowUI[slotIdx].enChk.Visible := true
            rowUI[slotIdx].autoBtn.Visible := true
            rowUI[slotIdx].dd.Visible := true
            rowUI[slotIdx].optsBtn.Visible := true
            rowUI[slotIdx].remBtn.Visible := true
        } else {
            rowUI[slotIdx].tb.Visible := false
            rowUI[slotIdx].trigBtn.Visible := false
            rowUI[slotIdx].cb.Visible := false
            rowUI[slotIdx].enChk.Visible := false
            rowUI[slotIdx].autoBtn.Visible := false
            rowUI[slotIdx].dd.Visible := false
            rowUI[slotIdx].optsBtn.Visible := false
            rowUI[slotIdx].remBtn.Visible := false
        }
    }

    if (maxOffset > 0) {
        if (updateSliderVal && rowSlider.Value != scrollOffset)
            rowSlider.Value := scrollOffset
        startIdx := scrollOffset + 1
        endIdx := Min(total, scrollOffset + VISIBLE_ROWS)
        scrollLabel.Text := LangT("Showing rows ") . startIdx . "-" . endIdx . LangT(" of ") . total
    } else {
        scrollLabel.Text := (total = 0) ? LangT("(no combos yet - click + Add Combo below)") : LangT("Showing all ") . total . LangT(" rows")
    }

    UpdateToggleButton()
}

HandleSliderChange(ctrl, *) {
    global scrollOffset
    SyncBoxesToRows()
    scrollOffset := ctrl.Value
    RenderAll(false)
}

AddRow(*) {
    global rows, nextRowId, scrollOffset, VISIBLE_ROWS
    SyncBoxesToRows()
    rows.Push({id: nextRowId, trigger: "", keys: [], mode: "hold", enabled: true, turboMs: 60})
    nextRowId += 1
    scrollOffset := Max(0, rows.Length - VISIBLE_ROWS)
    UpdateSliderLimits()
    RenderAll(true)
}

RemoveRowSlot(slotIdx, *) {
    global rows, scrollOffset
    SyncBoxesToRows()
    targetIdx := scrollOffset + slotIdx
    if (targetIdx <= rows.Length) {
        rows.RemoveAt(targetIdx)
        UpdateSliderLimits()
        RenderAll(true)
    }
}

UpdateToggleButton() {
    global scriptEnabled, toggleBtn, statusBadge, statusText, targetExe, panicKey, scrollTriggerKey, controllerEnabled
    if (toggleBtn = "" || statusText = "")
        return
    toggleBtn.Text := scriptEnabled ? LangT("Turn OFF") : LangT("Turn ON")

    if (statusBadge != "") {
        statusBadge.Value := scriptEnabled ? LangT("ACTIVE") : LangT("OFF")
        statusBadge.SetFont("c" . (scriptEnabled ? "00FF00" : "FF0000"))
    }

    scrollDesc := (scrollTriggerKey != "") ? LangT("ScrollKey: ") . scrollTriggerKey : LangT("Scroll: OFF")
    filterDesc := (targetExe != "") ? LangT("Target: ") . targetExe : LangT("Target: (any)")
    ctrlDesc := controllerEnabled ? LangT("Pad: ON") : LangT("Pad: OFF")
    statusText.Text := LangT("Status: ") . (scriptEnabled ? LangT("ON") : LangT("OFF")) . LangT(" | Panic: ") . panicKey . " | " . scrollDesc . " | " . filterDesc . " | " . ctrlDesc
}

ApplyChanges(*) {
    global rows, panicKey, scrollTriggerKey, configFile

    SyncBoxesToRows()

    if (panicKey = "") {
        MsgBox(LangT("The panic toggle key cannot be blank. This is required for safety."), LangT("Combo ReMapper 9.7"), "Icon! 262144")
        return
    }

    seenTriggers := Map()
    for row in rows {
        if (row.trigger = "")
            continue
        cleanTrig := RegExReplace(StrUpper(row.trigger), "^~")
        if (cleanTrig = StrUpper(panicKey)) {
            MsgBox("'" row.trigger LangT("' is reserved for the panic toggle and can't be a trigger key. Nothing was saved."), LangT("Combo ReMapper 9.7"), "Icon! 262144")
            return
        }
        if (seenTriggers.Has(cleanTrig)) {
            MsgBox("'" row.trigger LangT("' is used as a trigger key on more than one row. Please make each trigger key unique."), LangT("Combo ReMapper 9.7"), "Icon! 262144")
            return
        }
        seenTriggers[cleanTrig] := true
    }

    if (scrollTriggerKey != "") {
        if (StrUpper(scrollTriggerKey) = StrUpper(panicKey)) {
            MsgBox(LangT("The scroll-click key can't be the panic toggle. Nothing was saved."), LangT("Combo ReMapper 9.7"), "Icon! 262144")
            return
        }
        if (seenTriggers.Has(StrUpper(scrollTriggerKey))) {
            MsgBox(LangT("The scroll-click key ('") scrollTriggerKey LangT("') is the same as one of your row trigger keys. Pick a different one."), LangT("Combo ReMapper 9.7"), "Icon! 262144")
            return
        }
    }

    ReleaseAllHeldCombos()
    SetTimer(() => ShowComboCheck(false), -300)

    RegisterRowHotkeys()
    RegisterScrollHotkey()
    RegisterPanicHotkey()
    RegisterOsdHotkey()
    RegisterYLockHotkey()
    RegisterExtraHotkeys()

    SaveStateToINI(configFile)

    UpdateToggleButton()
    NotifyUser(LangT("Combos updated and saved"))
}

; ============================================================
; ---- KEY CHEAT SHEET + PAGES (v9.6) ----
; Cheat sheet: one key shows every key of the current profile on screen.
; Pages: one key swaps to another profile ("page") and back, so one hand
; reaches twice as many actions with no key combinations.
; ============================================================
KeyClash(key, others) {
    global rows
    k := StrUpper(Trim(key))
    if (k = "")
        return false
    for o in others {
        if (StrUpper(Trim(o)) = k)
            return true
    }
    for row in rows {
        if (StrUpper(RegExReplace(Trim(row.trigger), "^[~*$]+")) = k)
            return true
    }
    return false
}

RegisterLayerHotkey() {
    global layerKey, layerPrevKey, registeredLayerKey, registeredPrevKey
    if (registeredLayerKey != "") {
        try Hotkey("*" registeredLayerKey, "Off")
        registeredLayerKey := ""
    }
    if (registeredPrevKey != "") {
        try Hotkey("*" registeredPrevKey, "Off")
        registeredPrevKey := ""
    }
    if (layerKey != "") {
        try {
            Hotkey("*" layerKey, LayerNext, "On")
            registeredLayerKey := layerKey
        } catch {
            MsgBox(LangT("Failed to bind the next-page key: ") . layerKey, LangT("Combo ReMapper 9.7"), "Icon! 262144")
        }
    }
    if (layerPrevKey != "") {
        try {
            Hotkey("*" layerPrevKey, LayerPrev, "On")
            registeredPrevKey := layerPrevKey
        } catch {
            MsgBox(LangT("Failed to bind the previous-page key: ") . layerPrevKey, LangT("Combo ReMapper 9.7"), "Icon! 262144")
        }
    }
}

RegisterCheatHotkey() {
    global cheatKey, registeredCheatKey
    if (registeredCheatKey != "") {
        try Hotkey("*" registeredCheatKey, "Off")
        registeredCheatKey := ""
    }
    if (cheatKey = "")
        return
    try {
        Hotkey("*" cheatKey, ToggleCheatSheet, "On")
        registeredCheatKey := cheatKey
    } catch {
        MsgBox(LangT("Failed to bind the cheat-sheet key: ") . cheatKey, LangT("Combo ReMapper 9.7"), "Icon! 262144")
    }
}

RegisterExtraHotkeys() {
    RegisterLayerHotkey()
    RegisterCheatHotkey()
}

; ---- pages ----
LayerNext(*) {
    LayerGo(1)
}

LayerPrev(*) {
    LayerGo(-1)
}

LayerGo(dir) {
    global layerKey, layerPrevKey, layerPages, layerIdx, layerBase, layerSwitching, layerReturning, cheatKey
    global currentProfile, profilesDir, profileDD, scriptEnabled
    if (!scriptEnabled)
        return
    n := layerPages.Length
    if (n = 0) {
        NotifyUser(LangT("No other pages are set. Open Settings and add pages."), -2500)
        return
    }
    base := (layerBase != "") ? layerBase : currentProfile
    newIdx := layerIdx + dir
    if (newIdx > n)
        newIdx := 0
    if (newIdx < 0)
        newIdx := n
    target := (newIdx = 0) ? base : layerPages[newIdx]
    if (!FileExist(profilesDir "\" target ".ini")) {
        NotifyUser(LangT("Page profile '") . target . LangT("' was not found."), -2500)
        return
    }
    keepLayer := layerKey
    keepPrev := layerPrevKey
    keepCheat := cheatKey
    keepPages := layerPages
    layerSwitching := true
    layerReturning := (newIdx = 0)
    try SwitchProfile({Text: target})
    layerSwitching := false
    layerReturning := false
    if (newIdx = 0) {
        layerBase := ""
    } else {
        ; on another page: keep the same keys working so you can move on or get back
        layerBase := base
        layerKey := keepLayer
        layerPrevKey := keepPrev
        cheatKey := keepCheat
        layerPages := keepPages
    }
    layerIdx := newIdx
    RegisterExtraHotkeys()
    try profileDD.Choose(target)
    LogEvent("PAGE " . (newIdx + 1) . "/" . (n + 1) . " -> " . target, false)
    FlashOSD(LangT("PAGE ") . (newIdx + 1) . "/" . (n + 1) . ": " . target, "00CCFF", 1500)
    NotifyUser(LangT("Page ") . (newIdx + 1) . LangT(" of ") . (n + 1) . ": " . target)
}

LayerAddPage(dd, list, work) {
    global currentProfile
    pick := Trim(dd.Text)
    if (pick = "")
        return
    if (pick = currentProfile) {
        NotifyUser(LangT("That is this profile - pick a different one for the other pages."), -2500)
        return
    }
    for existing in work {
        if (existing = pick)
            return
    }
    work.Push(pick)
    list.Add([pick])
}

LayerRemovePage(list, work) {
    sel := list.Value
    if (sel < 1 || sel > work.Length)
        return
    work.RemoveAt(sel)
    list.Delete(sel)
}

; ---- cheat sheet ----
CheatPad(s, n) {
    while (StrLen(s) < n)
        s .= " "
    return s
}

CheatFriendly(tok) {
    static names := Map("lshift", "Left Shift", "rshift", "Right Shift", "shift", "Shift"
        , "lctrl", "Left Ctrl", "rctrl", "Right Ctrl", "ctrl", "Ctrl", "lalt", "Left Alt", "ralt", "Right Alt", "alt", "Alt"
        , "space", "Space", "enter", "Enter", "tab", "Tab", "esc", "Esc", "escape", "Esc", "backspace", "Backspace"
        , "mlc", "left click", "mrc", "right click", "mmc", "middle click"
        , "lbutton", "left button", "rbutton", "right button", "mbutton", "middle button"
        , "mwd1", "scroll down", "mwu1", "scroll up", "mwd2", "scroll down", "mwu2", "scroll up"
        , "up", "Up arrow", "down", "Down arrow", "left", "Left arrow", "right", "Right arrow")
    t := Trim(tok)
    low := StrLower(t)
    if (RegExMatch(low, "^burst:([^,]+)(?:,(\d+))?(?:,(\d+))?$", &m))
        return LangT("mash ") . CheatFriendly(m[1]) . " x" . (m[2] != "" ? m[2] : "20")
    if (RegExMatch(low, "^alt:([^/,]+)/([^,]+)(?:,(\d+))?(?:,(\d+))?$", &m))
        return LangT("alternate ") . CheatFriendly(m[1]) . " / " . CheatFriendly(m[2]) . " x" . (m[3] != "" ? m[3] : "20")
    if (RegExMatch(low, "^hold:([^,]+)(?:,(\d+))?$", &m))
        return LangT("hold ") . CheatFriendly(m[1]) . " " . (m[2] != "" ? m[2] : "500") . "ms"
    if (RegExMatch(low, "^down:(.+)$", &m))
        return LangT("hold ") . CheatFriendly(m[1])
    if (RegExMatch(low, "^up:(.+)$", &m))
        return LangT("release ") . CheatFriendly(m[1])
    if (RegExMatch(low, "^d(\d+)$", &m))
        return LangT("wait ") . m[1] . "ms"
    if (names.Has(low))
        return LangT(names[low])
    if (StrLen(t) = 1)
        return StrUpper(t)
    return t
}

CheatDescribe(row) {
    if (row.HasOwnProp("note") && row.note != "")
        return row.note
    parts := []
    for k in row.keys
        parts.Push(CheatFriendly(k))
    if (row.mode = "taphold") {
        a := parts.Length >= 1 ? parts[1] : ""
        b := parts.Length >= 2 ? parts[2] : ""
        return LangT("tap: ") . a . LangT("   hold: ") . b
    }
    out := ""
    for p in parts
        out .= (out = "" ? "" : ", ") . p
    return out
}

CheatModeLabel(mode) {
    static labels := Map("hold", "Hold", "toggle", "Toggle", "press", "Press", "turbo", "Turbo", "taphold", "Tap/Hold", "doubletap", "Dbl-tap", "autoturbo", "Auto-repeat")
    static dropdownName := Map("hold", "Hold", "toggle", "Toggle", "press", "Press", "turbo", "Turbo", "taphold", "TapHold", "doubletap", "DblTap", "autoturbo", "TglTurbo")
    english := labels.Has(mode) ? labels[mode] : mode
    return dropdownName.Has(mode) ? LangMode(dropdownName[mode], english) : english
}

CheatTrim(text, maxLen) {
    if (StrLen(text) > maxLen)
        return SubStr(text, 1, maxLen - 3) . "..."
    return text
}

; Reads the rows of another profile (a page) straight from its .ini file.
CheatLoadRows(profileName) {
    global profilesDir
    out := []
    path := profilesDir "\" profileName ".ini"
    if (!FileExist(path))
        return out
    cnt := 0
    try cnt := Integer(IniRead(path, "Meta", "RowCount", 0))
    loop cnt {
        sec := "Row" . A_Index
        trig := ""
        combo := ""
        mode := "hold"
        en := "1"
        note := ""
        tms := 60
        try trig := Trim(IniRead(path, sec, "Trigger", ""))
        try combo := IniRead(path, sec, "Combo", "")
        try mode := IniRead(path, sec, "Mode", "hold")
        try en := IniRead(path, sec, "Enabled", "1")
        try note := IniRead(path, sec, "Note", "")
        try tms := Integer(IniRead(path, sec, "TurboMs", 60))
        out.Push({trigger: trig, keys: ParseKeyList(combo), mode: mode, enabled: (en != "0"), note: note, turboMs: tms})
    }
    return out
}

CheatRowLines(rowList, detail, lines) {
    count := 0
    for row in rowList {
        if (row.trigger = "" || row.keys.Length = 0)
            continue
        if (row.HasOwnProp("enabled") && !row.enabled)
            continue
        lines.Push(CheatPad(StrUpper(RegExReplace(row.trigger, "^[~*$]+")), 9) . CheatPad(CheatModeLabel(row.mode), 12) . CheatTrim(CheatDescribe(row), 50))
        if (detail) {
            raw := KeyListToString(row.keys)
            if ((row.mode = "turbo" || row.mode = "autoturbo") && row.HasOwnProp("turboMs"))
                raw .= "   (every " . row.turboMs . " ms)"
            lines.Push(LangT("            sends: ") . CheatTrim(raw, 56))
        }
        count += 1
    }
    if (count = 0)
        lines.Push(LangT("(no keys set)"))
}

BuildCheatLines(detail) {
    global kmToggleKey, scanKey, windowKey
    global rows, currentProfile, layerBase, layerKey, layerPrevKey, layerPages, layerIdx, cheatKey, panicKey, osdToggleKey, yLockKey, scrollTriggerKey, targetExe
    lines := []
    lines.Push(LangT("Works in:  ") . (targetExe = "" ? LangT("any window") : targetExe))
    if (layerPages.Length > 0) {
        base := (layerBase != "") ? layerBase : currentProfile
        names := [base]
        for pg in layerPages
            names.Push(pg)
        total := names.Length
        if (layerKey != "")
            lines.Push(LangT("Next page: ") . StrUpper(layerKey))
        if (layerPrevKey != "")
            lines.Push(LangT("Back page: ") . StrUpper(layerPrevKey))
        for i, nm in names {
            lines.Push("")
            lines.Push(LangT("PAGE ") . i . LangT(" of ") . total . ":  " . nm . ((i - 1 = layerIdx) ? LangT("   <-- you are here") : ""))
            lines.Push(CheatPad(LangT("KEY"), 9) . CheatPad(LangT("HOW"), 12) . LangT("WHAT IT DOES"))
            lines.Push("--------------------------------------------------")
            CheatRowLines((i - 1 = layerIdx) ? rows : CheatLoadRows(nm), detail, lines)
        }
    } else {
        lines.Push("")
        lines.Push(LangT("KEYS FOR:  ") . currentProfile)
        lines.Push(CheatPad(LangT("KEY"), 9) . CheatPad(LangT("HOW"), 12) . LangT("WHAT IT DOES"))
        lines.Push("--------------------------------------------------")
        CheatRowLines(rows, detail, lines)
    }
    lines.Push("")
    lines.Push(LangT("ALWAYS"))
    if (windowKey != "")
        lines.Push(CheatPad(StrUpper(windowKey), 9) . LangT("Show / hide the remapper window"))
    if (kmToggleKey != "")
        lines.Push(CheatPad(StrUpper(kmToggleKey), 9) . LangT("Keyboard mouse on/off"))
    if (scanKey != "")
        lines.Push(CheatPad(StrUpper(scanKey), 9) . LangT("One-button control"))
    lines.Push(CheatPad(StrUpper(panicKey), 9) . LangT("Master on/off (panic)"))
    if (osdToggleKey != "")
        lines.Push(CheatPad(StrUpper(osdToggleKey), 9) . LangT("Show/hide the status box"))
    if (yLockKey != "")
        lines.Push(CheatPad(StrUpper(yLockKey), 9) . LangT("Lock the mouse height"))
    if (scrollTriggerKey != "")
        lines.Push(CheatPad(StrUpper(scrollTriggerKey), 9) . LangT("Scroll click"))
    if (cheatKey != "")
        lines.Push(CheatPad(StrUpper(cheatKey), 9) . (detail ? LangT("Close this sheet") : LangT("Press again for details, then again to close")))
    return lines
}

; Cheat key: 1st press = simple list, 2nd press = with the exact combos, 3rd press = close.
ToggleCheatSheet(*) {
    global cheatGui, cheatState
    if (!IsObject(cheatGui))
        cheatState := 0
    cheatState += 1
    if (cheatState > 2) {
        HideCheatSheet()
        return
    }
    ShowCheatSheet(cheatState = 2)
}

ShowCheatSheet(detail) {
    global cheatGui, cheatSize, cheatSeconds, cheatBg, cheatFg, cheatPos
    try cheatGui.Destroy()
    lines := BuildCheatLines(detail)
    fontSize := cheatSize
    lineH := Round(fontSize * 2)
    maxLines := Max(10, Floor((A_ScreenHeight * 0.8 - 50) / lineH))
    cols := Ceil(lines.Length / maxLines)
    if (cols > 3 && fontSize > 10) {
        fontSize := 10
        lineH := 19
        maxLines := Max(10, Floor((A_ScreenHeight * 0.8 - 50) / lineH))
        cols := Ceil(lines.Length / maxLines)
    }
    cols := Max(1, cols)
    per := Ceil(lines.Length / cols)
    cheatGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border +E0x08000000", LangT("Key cheat sheet"))
    cheatGui.BackColor := cheatBg
    cheatGui.MarginX := 20
    cheatGui.MarginY := 16
    cheatGui.SetFont("s" . fontSize . " c" . cheatFg, "Consolas")
    loop cols {
        startI := (A_Index - 1) * per + 1
        endI := Min(A_Index * per, lines.Length)
        if (startI > endI)
            break
        chunk := ""
        i := startI
        while (i <= endI) {
            chunk .= lines[i] . "`n"
            i += 1
        }
        cheatGui.Add("Text", (A_Index = 1 ? "xm Section 0x80" : "ys x+36 0x80"), RTrim(chunk, "`n"))
    }
    cheatGui.Show("NoActivate AutoSize xCenter yCenter")
    if (cheatPos != "Center") {
        cheatGui.GetPos(, , &cw, &ch)
        MonitorGetWorkArea(, &wl, &wt, &wr, &wb)
        cx := InStr(cheatPos, "left") ? wl + 20 : wr - cw - 20
        cy := InStr(cheatPos, "Top") ? wt + 20 : wb - ch - 20
        cheatGui.Move(cx, cy)
    }
    if (cheatSeconds > 0)
        SetTimer(HideCheatSheet, -cheatSeconds * 1000)
    else
        SetTimer(HideCheatSheet, 0)
}

HideCheatSheet(*) {
    global cheatGui, cheatState
    SetTimer(HideCheatSheet, 0)
    cheatState := 0
    if (IsObject(cheatGui)) {
        try cheatGui.Destroy()
        cheatGui := ""
    }
}

; ============================================================
; ---- DIAGNOSTICS (v9.6) ----
; combo_remapper.log records errors, profile loads and safety releases.
; "Copy diagnostics" (tray menu) puts a short report on the clipboard.
; ============================================================
DiagLog(msg) {
    global logToFile
    if (!logToFile)
        return
    f := dataDir "\combo_remapper.log"
    try {
        if (FileExist(f) && FileGetSize(f) > 262144)
            FileMove(f, dataDir "\combo_remapper.old.log", 1)
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") . "  " . msg . "`n", f, "UTF-8")
    }
}

DiagTail(n) {
    f := dataDir "\combo_remapper.log"
    out := ""
    try {
        text := FileRead(f, "UTF-8")
        lines := StrSplit(RTrim(text, "`r`n"), "`n")
        start := Max(1, lines.Length - n + 1)
        i := start
        while (i <= lines.Length) {
            out .= RTrim(lines[i], "`r") . "`n"
            i += 1
        }
    }
    return out
}

CopyDiagnostics(*) {
    global rows, currentProfile, targetExe, compatMode, keyDelayDuration, keyDelayPress, mouseDelayDuration
    global pressExtraMs, autoDetectSecs, releaseOnBlur, layerPages, layerIdx, scriptEnabled, controllerEnabled, fireLog, sentDown
    t := LangT("Combo ReMapper 9.7 diagnostics`n")
    t .= LangT("AutoHotkey ") . A_AhkVersion . "   Windows " . A_OSVersion . "   Admin: " . (A_IsAdmin ? "yes" : "no") . "   64-bit: " . (A_PtrSize = 8 ? "yes" : "no") . "`n"
    t .= LangT("Profile: ") . currentProfile . "   Rows: " . rows.Length . "   Engine on: " . (scriptEnabled ? "yes" : "no") . "`n"
    t .= LangT("Target program: ") . (targetExe = "" ? "(any window)" : targetExe) . "   Compatibility mode: " . compatMode . "`n"
    t .= LangT("Delays: key ") . keyDelayDuration . " / press " . keyDelayPress . " / mouse " . mouseDelayDuration . " / extra " . pressExtraMs . " ms`n"
    t .= LangT("Auto-detect: ") . autoDetectSecs . " s   Release on focus loss: " . (releaseOnBlur ? "yes" : "no") . "   Controller: " . (controllerEnabled ? "on" : "off") . "`n"
    t .= LangT("Pages: ") . (layerPages.Length + 1) . "   Current page: " . (layerIdx + 1) . "`n"
    held := ""
    for lowKey, realKey in sentDown
        held .= (held = "" ? "" : ", ") . realKey
    t .= "Held down by the program: " . (held = "" ? "nothing" : held) . "`n"
    state := ""
    for keyName in ["LControl", "RControl", "LShift", "RShift", "LAlt", "RAlt", "LWin", "RWin", "LButton", "MButton", "RButton"] {
        logicalDown := GetKeyState(keyName) ? true : false
        physicalDown := GetKeyState(keyName, "P") ? true : false
        if (logicalDown || physicalDown)
            state .= keyName . " (Windows: " . (logicalDown ? "down" : "up") . ", physical: " . (physicalDown ? "down" : "up") . ")  "
    }
    t .= "Modifiers and buttons that are down right now: " . (state = "" ? "none" : state) . "`n`n"
    t .= LangT("--- log file (last 30 lines) ---`n")
    tail := DiagTail(30)
    t .= (tail = "" ? "(empty)`n" : tail)
    t .= LangT("`n--- recent events (last 20) ---`n")
    startIdx := Max(1, fireLog.Length - 19)
    i := startIdx
    while (i <= fireLog.Length) {
        t .= fireLog[i][1] . "  " . fireLog[i][2] . "`n"
        i += 1
    }
    A_Clipboard := t
    NotifyUser(LangT("Diagnostics copied - paste them into the chat"), -3000)
}

OpenLogFile(*) {
    f := dataDir "\combo_remapper.log"
    if (!FileExist(f)) {
        NotifyUser(LangT("No log file yet - nothing has gone wrong."), -2500)
        return
    }
    try Run('notepad.exe "' . f . '"')
}

; ============================================================
; ---- CUSTOMIZE (v9.6): status box and cheat sheet look ----
; ============================================================
CustomLoad() {
    global osdSize, osdOpacity, osdBg, cheatSize, cheatSeconds, cheatBg, cheatFg, cheatPos, showFireName, fireNameMs, showOsdRunning
    gf := dataDir "\remapper_global.ini"
    try showFireName := (IniRead(gf, "Look", "ShowFireName", "1") != "0")
    try showOsdRunning := (IniRead(gf, "Look", "ShowRunning", "1") != "0")
    try fireNameMs := Max(200, Min(3000, Integer(IniRead(gf, "Look", "FireNameMs", 800))))
    try osdSize := Max(8, Min(28, Integer(IniRead(gf, "Look", "OsdSize", 10))))
    try osdOpacity := Max(30, Min(100, Integer(IniRead(gf, "Look", "OsdOpacity", 100))))
    try osdBg := CustomHex(IniRead(gf, "Look", "OsdBg", "1E1E1E"), "1E1E1E")
    try cheatSize := Max(8, Min(24, Integer(IniRead(gf, "Look", "CheatSize", 12))))
    try cheatSeconds := Max(0, Min(600, Integer(IniRead(gf, "Look", "CheatSeconds", 45))))
    try cheatBg := CustomHex(IniRead(gf, "Look", "CheatBg", "101820"), "101820")
    try cheatFg := CustomHex(IniRead(gf, "Look", "CheatFg", "FFFFFF"), "FFFFFF")
    try cheatPos := CustomPos(IniRead(gf, "Look", "CheatPos", "Center"))
}

CustomHex(text, fallback) {
    t := StrUpper(RegExReplace(Trim(text), "^#"))
    return RegExMatch(t, "^[0-9A-F]{6}$") ? t : fallback
}

CustomPosIndex(name) {
    for i, n in ["Center", "Top left", "Top right", "Bottom left", "Bottom right"] {
        if (n = name)
            return i
    }
    return 1
}

CustomPos(text) {
    for name in ["Center", "Top left", "Top right", "Bottom left", "Bottom right"] {
        if (StrLower(Trim(text)) = StrLower(name))
            return name
    }
    return "Center"
}

CustomSave() {
    global osdSize, osdOpacity, osdBg, cheatSize, cheatSeconds, cheatBg, cheatFg, cheatPos, showFireName, fireNameMs, showOsdRunning
    gf := dataDir "\remapper_global.ini"
    try {
        IniWrite(showFireName ? 1 : 0, gf, "Look", "ShowFireName")
        IniWrite(showOsdRunning ? 1 : 0, gf, "Look", "ShowRunning")
        IniWrite(fireNameMs, gf, "Look", "FireNameMs")
        IniWrite(osdSize, gf, "Look", "OsdSize")
        IniWrite(osdOpacity, gf, "Look", "OsdOpacity")
        IniWrite(osdBg, gf, "Look", "OsdBg")
        IniWrite(cheatSize, gf, "Look", "CheatSize")
        IniWrite(cheatSeconds, gf, "Look", "CheatSeconds")
        IniWrite(cheatBg, gf, "Look", "CheatBg")
        IniWrite(cheatFg, gf, "Look", "CheatFg")
        IniWrite(cheatPos, gf, "Look", "CheatPos")
    }
}

ApplyOsdLook() {
    global osdGui, osdText, scriptEnabled
    if (osdGui != "") {
        try osdGui.Destroy()
        osdGui := ""
        osdText := ""
    }
    UpdateOSD(scriptEnabled ? LangT("REMAPPER: ACTIVE") : LangT("REMAPPER: DISABLED"), scriptEnabled ? "00FF00" : "FF0000")
}

ShowCustomize(*) {
    global customGui, osdSize, osdOpacity, osdBg, cheatSize, cheatSeconds, cheatBg, cheatFg, cheatPos, showFireName, fireNameMs, showOsdRunning
    if (IsObject(customGui)) {
        try {
            customGui.Show()
            return
        }
    }
    customGui := Gui("+AlwaysOnTop +ToolWindow", LangT("Customize"))
    customGui.SetFont("s10")
    customGui.Add("GroupBox", "xm ym w360 h225", LangT("Status box (the little ACTIVE / DISABLED box)"))
    customGui.Add("Text", "x24 yp+30 w170", LangT("Text size (8 - 28):"))
    osdSizeE := customGui.Add("Edit", "x200 yp-3 w70 Number", osdSize)
    customGui.Add("Text", "x24 y+14 w170", LangT("See-through (30 - 100 %):"))
    osdOpE := customGui.Add("Edit", "x200 yp-3 w70 Number", osdOpacity)
    customGui.Add("Text", "x24 y+14 w170", LangT("Background color (hex):"))
    osdBgE := customGui.Add("Edit", "x200 yp-3 w90", osdBg)
    fnCB := customGui.Add("Checkbox", "x24 y+16 w330" . (showFireName ? " Checked" : ""), LangT("Show the row's name in the status box when it fires"))
    customGui.Add("Text", "x24 y+10 w170", LangT("Show the name for (ms):"))
    fnMsE := customGui.Add("Edit", "x200 yp-3 w70 Number", fireNameMs)
    runCB := customGui.Add("Checkbox", "x24 y+14 w330" . (showOsdRunning ? " Checked" : ""), LangT("List running toggles and turbos in the status box"))

    customGui.Add("GroupBox", "xm y+30 w360 h230", LangT("Key cheat sheet"))
    customGui.Add("Text", "x24 yp+30 w170", LangT("Text size (8 - 24):"))
    chSizeE := customGui.Add("Edit", "x200 yp-3 w70 Number", cheatSize)
    customGui.Add("Text", "x24 y+14 w170", LangT("Stays up (seconds, 0 = until pressed):"))
    chSecE := customGui.Add("Edit", "x200 yp-3 w70 Number", cheatSeconds)
    customGui.Add("Text", "x24 y+14 w170", LangT("Background color (hex):"))
    chBgE := customGui.Add("Edit", "x200 yp-3 w90", cheatBg)
    customGui.Add("Text", "x24 y+14 w170", LangT("Text color (hex):"))
    chFgE := customGui.Add("Edit", "x200 yp-3 w90", cheatFg)
    customGui.Add("Text", "x24 y+14 w170", LangT("Position:"))
    chPosDD := customGui.Add("DropDownList", "x200 yp-3 w140 AltSubmit", [LangT("Center"), LangT("Top left"), LangT("Top right"), LangT("Bottom left"), LangT("Bottom right")])
    try chPosDD.Choose(CustomPosIndex(cheatPos))

    applyB := customGui.Add("Button", "xm y+30 w120 h30 Default", LangT("Apply"))
    resetB := customGui.Add("Button", "x+8 yp w120 h30", LangT("Reset to default"))
    closeB := customGui.Add("Button", "x+8 yp w100 h30", LangT("Close"))
    customGui.Add("Text", "xm y+12 w360", LangT("Colors are 6 hex digits, for example 1E1E1E (dark gray) or FFFFFF (white). Apply shows the status box and the cheat sheet with the new look."))

    applyB.OnEvent("Click", (*) => CustomApply(osdSizeE, osdOpE, osdBgE, chSizeE, chSecE, chBgE, chFgE, chPosDD, fnCB, fnMsE, runCB))
    resetB.OnEvent("Click", (*) => CustomReset(osdSizeE, osdOpE, osdBgE, chSizeE, chSecE, chBgE, chFgE, chPosDD, fnCB, fnMsE, runCB))
    closeB.OnEvent("Click", (*) => CustomClose())
    customGui.OnEvent("Close", (*) => CustomClose())
    customGui.Show()
}

CustomClose() {
    global customGui
    try customGui.Destroy()
    customGui := 0
}

CustomReset(osdSizeE, osdOpE, osdBgE, chSizeE, chSecE, chBgE, chFgE, chPosDD, fnCB, fnMsE, runCB) {
    fnCB.Value := 1
    runCB.Value := 1
    fnMsE.Value := 800
    osdSizeE.Value := 10
    osdOpE.Value := 100
    osdBgE.Value := "1E1E1E"
    chSizeE.Value := 12
    chSecE.Value := 45
    chBgE.Value := "101820"
    chFgE.Value := "FFFFFF"
    chPosDD.Choose(1)
}

CustomApply(osdSizeE, osdOpE, osdBgE, chSizeE, chSecE, chBgE, chFgE, chPosDD, fnCB, fnMsE, runCB) {
    global osdSize, osdOpacity, osdBg, cheatSize, cheatSeconds, cheatBg, cheatFg, cheatPos, cheatGui, cheatState, showFireName, fireNameMs, showOsdRunning
    showFireName := fnCB.Value ? true : false
    showOsdRunning := runCB.Value ? true : false
    SetTimer(CyberRefreshOSD, -80)
    fireNameMs := QteIntSafe(fnMsE.Value, 800, 200, 3000)
    fnMsE.Value := fireNameMs
    osdSize := QteIntSafe(osdSizeE.Value, 10, 8, 28)
    osdOpacity := QteIntSafe(osdOpE.Value, 100, 30, 100)
    osdBg := CustomHex(osdBgE.Value, "1E1E1E")
    cheatSize := QteIntSafe(chSizeE.Value, 12, 8, 24)
    cheatSeconds := QteIntSafe(chSecE.Value, 45, 0, 600)
    cheatBg := CustomHex(chBgE.Value, "101820")
    cheatFg := CustomHex(chFgE.Value, "FFFFFF")
    cheatPos := ["Center", "Top left", "Top right", "Bottom left", "Bottom right"][Max(1, chPosDD.Value)]
    osdSizeE.Value := osdSize
    osdOpE.Value := osdOpacity
    osdBgE.Value := osdBg
    chSizeE.Value := cheatSize
    chSecE.Value := cheatSeconds
    chBgE.Value := cheatBg
    chFgE.Value := cheatFg
    CustomSave()
    ApplyOsdLook()
    ShowCheatSheet(false)
    cheatState := 1
}

QteIntSafe(value, dflt, lo, hi) {
    v := dflt
    try v := Integer(Trim(value))
    return Max(lo, Min(hi, v))
}

; ============================================================
; ---- SETUP WIZARD (v9.6) ----
; Asks which hand you use, which game and what you want one key to do,
; then writes a ready profile with keys picked from your hand's reach.
; ============================================================
WizardRunningExes() {
    seen := Map()
    out := []
    for hwnd in WinGetList() {
        try {
            if (!DllCall("IsWindowVisible", "Ptr", hwnd))
                continue
            if (WinGetTitle(hwnd) = "")
                continue
            exe := WinGetProcessName(hwnd)
            if (exe = "" || seen.Has(StrLower(exe)))
                continue
            if (StrLower(exe) = "explorer.exe" || StrLower(exe) = "textinputhost.exe" || StrLower(exe) = "applicationframehost.exe")
                continue
            seen[StrLower(exe)] := true
            out.Push(exe)
        }
    }
    return out
}

ShowWizard(*) {
    global wizGui, panicKey
    if (IsObject(wizGui)) {
        try {
            wizGui.Show()
            return
        }
    }
    wizGui := Gui("+AlwaysOnTop", LangT("Setup wizard"))
    wizGui.SetFont("s10")
    c := Map()
    wizGui.Add("Text", "xm w460", LangT("This builds a profile for you. Answer a few questions, then press Create. You can change everything afterwards."))
    wizGui.Add("Text", "xm y+16 w460", LangT("1.  Which hand do you use?"))
    c["hand"] := wizGui.Add("DropDownList", "xm w220 Choose1", [LangT("Left hand only"), LangT("Right hand only"), LangT("Either hand")])
    wizGui.Add("Text", "xm y+16 w460", LangT("2.  Name for this profile (for example the game's name):"))
    c["name"] := wizGui.Add("Edit", "xm w300", "My game")
    wizGui.Add("Text", "xm y+16 w460", LangT("3.  Which program is the game? Pick it from the open programs, or type its name (leave empty = works in any window):"))
    c["exe"] := wizGui.Add("ComboBox", "xm w300", WizardRunningExes())
    wizGui.Add("Text", "xm y+16 w460", LangT("4.  Keys the game already uses (the wizard will not take these):"))
    c["used"] := wizGui.Add("Edit", "xm w460", "w a s d e q r c v space lshift lctrl lalt tab enter backspace up down left right")
    wizGui.Add("Text", "xm y+16 w460", LangT("5.  What should one key do for you? Tick everything you want:"))
    c["walk"] := wizGui.Add("Checkbox", "xm Checked", LangT("Walk forward on its own (press again to stop).  Forward key:"))
    c["walkKey"] := wizGui.Add("Edit", "x+8 yp-3 w50", "w")
    c["click"] := wizGui.Add("Checkbox", "xm Checked", LangT("Click the left mouse button over and over (press again to stop)"))
    c["mash"] := wizGui.Add("Checkbox", "xm", LangT("Press a key over and over (press again to stop).  Key:"))
    c["mashKey"] := wizGui.Add("Edit", "x+8 yp-3 w50", "e")
    c["shift"] := wizGui.Add("Checkbox", "xm", LangT("Hold Shift for me (press again to let go)"))
    c["ctrl"] := wizGui.Add("Checkbox", "xm", LangT("Hold Ctrl for me (press again to let go)"))
    c["evade"] := wizGui.Add("Checkbox", "xm", LangT("Shift + Space together on one key (for a dodge or roll)"))
    c["burst"] := wizGui.Add("Checkbox", "xm", LangT("Mash a button in one burst (for a button-mashing prompt).  Button:"))
    c["burstKey"] := wizGui.Add("Edit", "x+8 yp-3 w50", "x")
    c["altm"] := wizGui.Add("Checkbox", "xm", LangT("Alternate two buttons fast (left/right mash).  Buttons:"))
    c["altKey1"] := wizGui.Add("Edit", "x+8 yp-3 w40", "x")
    c["altKey2"] := wizGui.Add("Edit", "x+4 yp w40", "c")
    c["holdq"] := wizGui.Add("Checkbox", "xm", LangT("Hold a button for 1 second (for a hold prompt).  Button:"))
    c["holdKey"] := wizGui.Add("Edit", "x+8 yp-3 w50", "x")
    c["cheat"] := wizGui.Add("Checkbox", "xm y+16 Checked", LangT("Add a key that shows all the keys on the screen (F1)"))
    helpB := wizGui.Add("Button", "xm y+20 w210 h32", LangT("What does everything do?"))
    createB := wizGui.Add("Button", "x+8 yp w140 h32 Default", LangT("Create profile"))
    cancelB := wizGui.Add("Button", "x+8 yp w100 h32", LangT("Cancel"))
    helpB.OnEvent("Click", ShowWizardHelp)
    createB.OnEvent("Click", (*) => WizardCreate(c))
    cancelB.OnEvent("Click", (*) => WizardClose())
    wizGui.OnEvent("Close", (*) => WizardClose())
    AddTip(c["hand"], LangT("Pick the hand you can use. The wizard picks keys that hand reaches easily. Left hand: F G X T B and the number keys. Right hand: J K L U I O H N M and the numpad."))
    AddTip(c["name"], LangT("The name of the new profile. It shows up in the profile list in the main window."))
    AddTip(c["exe"], LangT("The game's program. Start the game first, then pick it from the list, or type its name (for example MyGame.exe). When it is set, the keys only work while that game is in front. Empty = works in any window."))
    AddTip(c["used"], LangT("Keys the game already uses (moving, attacking...). The wizard never gives these to a helper, so your game keys keep working. Separate them with spaces."))
    AddTip(c["walk"], LangT("One key makes your character walk forward by itself. Press it again to stop."))
    AddTip(c["walkKey"], LangT("The key your game uses for moving forward (usually W)."))
    AddTip(c["click"], LangT("One key clicks the left mouse button over and over, fast. Press it again to stop."))
    AddTip(c["mash"], LangT("One key presses another key over and over, fast. Press it again to stop. Good for button-mashing parts."))
    AddTip(c["mashKey"], LangT("The key to be pressed over and over."))
    AddTip(c["shift"], LangT("One key holds Shift down for you (sprint, lock-on, and so on). Press it again to let go."))
    AddTip(c["ctrl"], LangT("One key holds Ctrl down for you. Press it again to let go."))
    AddTip(c["evade"], LangT("One key presses Shift and Space together, so you do not need two fingers for a dodge or roll."))
    AddTip(c["burst"], LangT("One key presses a button about 30 times in a row, quickly, then stops by itself. Made for quick time events that ask you to mash."))
    AddTip(c["burstKey"], LangT("The game button to mash (the key your game uses for it)."))
    AddTip(c["altm"], LangT("One key presses two buttons one after the other, again and again, for prompts that ask you to alternate left and right."))
    AddTip(c["altKey1"], LangT("The first of the two buttons."))
    AddTip(c["altKey2"], LangT("The second of the two buttons."))
    AddTip(c["holdq"], LangT("One key holds a button down for one second and then lets go, for prompts that say hold."))
    AddTip(c["holdKey"], LangT("The game button to hold."))
    AddTip(c["cheat"], LangT("Adds the F1 key. Press it to see a list of all your keys and what they do. Press it again for more detail, a third time to close it."))
    AddTip(helpB, LangT("Opens a window that explains every question and button."))
    AddTip(createB, LangT("Shows you what will be made and asks you to confirm, then builds the profile and switches to it."))
    AddTip(cancelB, LangT("Closes the wizard without making anything."))
    wizGui.Show()
    StartTips(wizGui.Hwnd)
}

ShowWizardHelp(*) {
    global wizHelpGui
    if (IsObject(wizHelpGui)) {
        try {
            wizHelpGui.Show()
            return
        }
    }
    t := LangT("SETUP WIZARD - WHAT EVERYTHING DOES`r`n`r`n")
    t .= LangT("1. Which hand`r`n   The wizard gives each helper a key that your hand reaches without stretching.`r`n   Left hand: F, G, X, T, B and the number keys.`r`n   Right hand: J, K, L, U, I, O, H, N, M and the number pad.`r`n   Either hand: the same keys as the left hand.`r`n`r`n")
    t .= LangT("2. Profile name`r`n   Any name you like. It appears in the profile list of the main window.`r`n`r`n")
    t .= LangT("3. Which program is the game`r`n   Start the game first, then pick it from the list. When it is set, the keys only work while the game is in front, and everything is let go if you switch away. Empty = works in any window (less safe).`r`n`r`n")
    t .= LangT("4. Keys the game already uses`r`n   The wizard will not take these keys, so your game controls keep working. Add the keys your game uses, separated by spaces.`r`n`r`n")
    t .= LangT("5. What one key should do (tick what you want)`r`n")
    t .= LangT("   Walk forward on its own - press the key once to start walking, again to stop.`r`n")
    t .= LangT("   Click over and over - fast left clicks until you press the key again.`r`n")
    t .= LangT("   Press a key over and over - for button-mashing; pick which key.`r`n")
    t .= LangT("   Hold Shift / Hold Ctrl - the key holds it down for you until you press it again.`r`n")
    t .= LangT("   Shift + Space together - a dodge or roll on a single key.`r`n")
    t .= LangT("   Mash a button in one burst - quick time events that ask you to mash: one press sends about 30 quick presses, then stops.`r`n")
    t .= LangT("   Alternate two buttons - left/right mash prompts.`r`n")
    t .= LangT("   Hold a button for 1 second - hold prompts.`r`n`r`n")
    t .= LangT("Add a key that shows all the keys (F1)`r`n   Press F1 in the game to see a list of every key and what it does. Press it again for more detail, a third time to close it.`r`n`r`n")
    t .= LangT("Buttons`r`n")
    t .= LangT("   What does everything do? - this window.`r`n")
    t .= LangT("   Create profile - shows you exactly what will be made (every key and what it does) and asks you to confirm. Nothing is saved until you say yes.`r`n")
    t .= LangT("   Cancel - closes the wizard and makes nothing.`r`n`r`n")
    t .= LangT("After it is made`r`n   The panic key (F2, or F8 for the right hand) turns everything off and on. You can change any key, add rows or add pages later in the main window and in Settings.")
    wizHelpGui := Gui("+AlwaysOnTop +ToolWindow +Resize", LangT("Setup wizard help"))
    wizHelpGui.SetFont("s10")
    wizHelpGui.Add("Edit", "w560 r22 ReadOnly Multi VScroll", t)
    closeB := wizHelpGui.Add("Button", "xm y+10 w100 h30 Default", LangT("Close"))
    closeB.OnEvent("Click", (*) => WizardHelpClose())
    wizHelpGui.OnEvent("Close", (*) => WizardHelpClose())
    wizHelpGui.Show()
}

WizardHelpClose() {
    global wizHelpGui
    try wizHelpGui.Destroy()
    wizHelpGui := 0
}

WizardClose() {
    global wizGui
    try wizGui.Destroy()
    wizGui := 0
}

WizardCreate(c) {
    global profilesDir, panicKey, osdToggleKey, yLockKey, scrollTriggerKey
    hand := c["hand"].Value
    name := Trim(RegExReplace(c["name"].Text, '[\\/:*?"<>|]'))
    if (name = "") {
        MsgBox(LangT("Please give the profile a name."), LangT("Setup wizard"), "Icon! 262144")
        return
    }
    exe := Trim(c["exe"].Text)
    ; the actions the user ticked: [label, combo, mode, turboMs]
    acts := []
    if (c["walk"].Value) {
        wk := Trim(c["walkKey"].Text)
        acts.Push([LangT("Walk forward (toggle)"), wk = "" ? "w" : wk, "toggle", 60, LangT("press once to start walking, press again to stop")])
    }
    if (c["click"].Value)
        acts.Push([LangT("Auto-click"), "mlc", "autoturbo", 40, LangT("press once to start clicking fast, press again to stop")])
    if (c["mash"].Value) {
        mk := Trim(c["mashKey"].Text)
        if (mk = "")
            mk := "e"
        acts.Push([LangT("Auto-press ") . StrUpper(mk), mk, "autoturbo", 40, LangT("press once to press ") . StrUpper(mk) . LangT(" over and over, press again to stop")])
    }
    if (c["shift"].Value)
        acts.Push([LangT("Hold Shift (toggle)"), "lshift", "toggle", 60, LangT("press once to hold Shift, press again to let go")])
    if (c["ctrl"].Value)
        acts.Push([LangT("Hold Ctrl (toggle)"), "lctrl", "toggle", 60, LangT("press once to hold Ctrl, press again to let go")])
    if (c["evade"].Value)
        acts.Push([LangT("Shift + Space together"), "down:lshift,d30,space,d40,up:lshift", "press", 60, LangT("press once to do Shift and Space together")])
    if (c["burst"].Value) {
        bk := Trim(c["burstKey"].Text)
        if (bk = "")
            bk := "x"
        acts.Push([LangT("Mash ") . StrUpper(bk) . LangT(" in one burst"), "burst:" . bk . ",30,40", "press", 60, LangT("press once to press ") . StrUpper(bk) . LangT(" about 30 times quickly, then it stops")])
    }
    if (c["altm"].Value) {
        ak1 := Trim(c["altKey1"].Text)
        ak2 := Trim(c["altKey2"].Text)
        if (ak1 = "")
            ak1 := "x"
        if (ak2 = "")
            ak2 := "c"
        acts.Push([LangT("Alternate ") . StrUpper(ak1) . LangT(" and ") . StrUpper(ak2), "alt:" . ak1 . "/" . ak2 . ",30,40", "press", 60, LangT("press once to alternate ") . StrUpper(ak1) . LangT(" and ") . StrUpper(ak2) . LangT(" about 30 times, then it stops")])
    }
    if (c["holdq"].Value) {
        hk := Trim(c["holdKey"].Text)
        if (hk = "")
            hk := "x"
        acts.Push([LangT("Hold ") . StrUpper(hk) . LangT(" for 1 second"), "hold:" . hk . ",1000", "press", 60, LangT("press once to hold ") . StrUpper(hk) . LangT(" for one second, then let go")])
    }
    if (acts.Length = 0) {
        MsgBox(LangT("Tick at least one thing you want a key to do."), LangT("Setup wizard"), "Icon! 262144")
        return
    }
    ; keys to stay away from: the game's own keys plus the program's hotkeys
    skip := Map()
    for k in StrSplit(RegExReplace(c["used"].Text, "[,;]", " "), " ") {
        k := StrLower(Trim(k))
        if (k != "")
            skip[k] := true
    }
    myPanic := (hand = 2) ? "F8" : "F2"
    for k in [myPanic, panicKey, osdToggleKey, yLockKey, scrollTriggerKey, "f1"] {
        if (k != "")
            skip[StrLower(k)] := true
    }
    pool := (hand = 2) ? ["j", "k", "l", "u", "i", "o", "h", "n", "m", "Numpad1", "Numpad2", "Numpad3", "Numpad4", "Numpad5", "Numpad6", "Numpad7", "Numpad8", "Numpad9"]
        : ["f", "g", "x", "t", "b", "1", "2", "3", "4", "5", "6", "F3", "F4", "F5"]
    free := []
    for k in pool {
        if (!skip.Has(StrLower(k)))
            free.Push(k)
    }
    if (free.Length < acts.Length) {
        MsgBox(LangT("Not enough free keys for that many actions. Untick a few, or remove some keys from the 'already used' list."), LangT("Setup wizard"), "Icon! 262144")
        return
    }
    ; show exactly what will be made and ask before saving anything
    preview := ""
    for i, a in acts
        preview .= StrUpper(free[i]) . "  -  " . a[1] . ":  " . a[5] . "`n"
    preview .= myPanic . LangT("  -  turns everything off and on`n")
    if (c["cheat"].Value)
        preview .= LangT("F1  -  shows all the keys on the screen`n")
    if (MsgBox(LangT("This is what the wizard will make:`n`n") . preview . LangT("`nProgram: ") . (exe = "" ? LangT("any window") : exe) . LangT("`nHand: ") . c["hand"].Text . LangT("`n`nCreate this profile?"), LangT("Setup wizard"), "YesNo Icon? 262144") != "Yes")
        return
    DirCreate(profilesDir)
    path := profilesDir "\" name ".ini"
    n := 2
    while FileExist(path) {
        path := profilesDir "\" name " " . n . ".ini"
        n += 1
    }
    finalName := RegExReplace(RegExReplace(path, "^.*\\", ""), "\.ini$")
    IniWrite(acts.Length, path, "Meta", "RowCount")
    IniWrite("(none)", path, "Meta", "ScrollKey")
    IniWrite(myPanic, path, "Meta", "PanicKey")
    IniWrite(c["cheat"].Value ? "F1" : "(none)", path, "Meta", "CheatKey")
    IniWrite("(none)", path, "Meta", "LayerKey")
    IniWrite("(none)", path, "Meta", "LayerProfile")
    IniWrite(exe = "" ? "(any)" : exe, path, "Meta", "TargetExe")
    IniWrite(1, path, "Settings", "CompatMode")
    IniWrite(1, path, "Settings", "SoundAlerts")
    IniWrite(0, path, "Settings", "ControllerEnabled")
    IniWrite(10, path, "Settings", "AutoDetectSecs")
    IniWrite(1, path, "Settings", "ReleaseOnBlur")
    for i, a in acts {
        IniWrite(free[i], path, "Row" . i, "Trigger")
        IniWrite(a[2], path, "Row" . i, "Combo")
        IniWrite(a[3], path, "Row" . i, "Mode")
        IniWrite(1, path, "Row" . i, "Enabled")
        IniWrite(a[4], path, "Row" . i, "TurboMs")
        IniWrite(a[1], path, "Row" . i, "Note")
    }
    summary := ""
    for i, a in acts
        summary .= StrUpper(free[i]) . "  =  " . a[1] . "`n"
    cheatTxt := c["cheat"].Value ? LangT("F1 shows all the keys on the screen.`n") : ""
    WizardClose()
    GotoProfile(finalName)
    anyTxt := (exe = "") ? LangT("`nIt works in any window. Set the Target program in the main window when you know it.") : ""
    MsgBox(LangT("Your profile '") . finalName . LangT("' is ready:`n`n") . summary . "`n" . myPanic . LangT(" turns everything off and on.`n") . cheatTxt . anyTxt, LangT("Setup wizard"), "Iconi 262144")
}

OfferWizard() {
    global offerGui
    if (IsObject(offerGui))
        return
    offerGui := Gui("+AlwaysOnTop", LangT("Welcome to Combo ReMapper 9.7"))
    offerGui.SetFont("s10")
    offerGui.Add("Text", "w440", LangT("Welcome! The setup wizard builds a first profile for you. It asks which hand you use, which game, and what you want one key to do, then picks keys your hand can reach."))
    offerGui.Add("Text", "w440 y+10", LangT("You can open it at any time: tray icon -> Setup wizard..."))
    openB := offerGui.Add("Button", "xm y+16 w140 h32 Default", LangT("Open the wizard"))
    laterB := offerGui.Add("Button", "x+8 yp w110 h32", LangT("Not now"))
    neverB := offerGui.Add("Button", "x+8 yp w150 h32", LangT("Don't ask again"))
    openB.OnEvent("Click", (*) => OfferWizardChoice("open"))
    laterB.OnEvent("Click", (*) => OfferWizardChoice("later"))
    neverB.OnEvent("Click", (*) => OfferWizardChoice("never"))
    offerGui.OnEvent("Close", (*) => OfferWizardChoice("later"))
    offerGui.Show()
}

OfferWizardChoice(choice) {
    global offerGui, globalSettingsFile
    try offerGui.Destroy()
    offerGui := 0
    if (choice = "open" || choice = "never")
        try IniWrite("never", globalSettingsFile, "Global", "WizardOffer")
    if (choice = "open")
        ShowWizard()
}

; ============================================================
; ---- ACCESSIBILITY TOOLS (v9.6) ----
; Tremor filter, keyboard mouse, one-button control. Settings are saved for the
; whole program in remapper_global.ini ([Access]).
; ============================================================
AccessLoad() {
    global tremorMs, tremorHoldMs, kmToggleKey, kmSpeed, kmAccel, kmKeys, scanKey, scanMode, scanMs, windowKey, winKeepTop
    gf := dataDir "\remapper_global.ini"
    kmKeys := Map("up", "e", "down", "d", "left", "s", "right", "f", "lclick", "q", "rclick", "w", "mclick", "r", "scrollup", "t", "scrolldown", "g")
    try {
        v := IniRead(gf, "Access", "WindowKey", "F12")
        windowKey := (v = "(none)") ? "" : v
    }
    try winKeepTop := (IniRead(gf, "Access", "WinKeepTop", "1") != "0")
    try tremorMs := Max(0, Min(2000, Integer(IniRead(gf, "Access", "TremorMs", 0))))
    try tremorHoldMs := Max(0, Min(2000, Integer(IniRead(gf, "Access", "TremorHoldMs", 0))))
    try kmSpeed := Max(100, Min(4000, Integer(IniRead(gf, "Access", "KmSpeed", 700))))
    try kmAccel := (IniRead(gf, "Access", "KmAccel", "1") != "0")
    try {
        v := IniRead(gf, "Access", "KmToggle", "F11")
        kmToggleKey := (v = "(none)") ? "" : v
    }
    for name in ["up", "down", "left", "right", "lclick", "rclick", "mclick", "scrollup", "scrolldown"] {
        try {
            v := IniRead(gf, "Access", "Km_" . name, kmKeys[name])
            kmKeys[name] := (v = "(none)") ? "" : v
        }
    }
    try {
        v := IniRead(gf, "Access", "ScanKey", "(none)")
        scanKey := (v = "(none)") ? "" : v
    }
    try scanMode := (IniRead(gf, "Access", "ScanMode", "auto") = "step") ? "step" : "auto"
    try scanMs := Max(300, Min(5000, Integer(IniRead(gf, "Access", "ScanMs", 1200))))
}

AccessSave() {
    global tremorMs, tremorHoldMs, kmToggleKey, kmSpeed, kmAccel, kmKeys, scanKey, scanMode, scanMs, windowKey, winKeepTop
    gf := dataDir "\remapper_global.ini"
    try {
        IniWrite(windowKey != "" ? windowKey : "(none)", gf, "Access", "WindowKey")
        IniWrite(winKeepTop ? 1 : 0, gf, "Access", "WinKeepTop")
        IniWrite(tremorMs, gf, "Access", "TremorMs")
        IniWrite(tremorHoldMs, gf, "Access", "TremorHoldMs")
        IniWrite(kmSpeed, gf, "Access", "KmSpeed")
        IniWrite(kmAccel ? 1 : 0, gf, "Access", "KmAccel")
        IniWrite(kmToggleKey != "" ? kmToggleKey : "(none)", gf, "Access", "KmToggle")
        for name, key in kmKeys
            IniWrite(key != "" ? key : "(none)", gf, "Access", "Km_" . name)
        IniWrite(scanKey != "" ? scanKey : "(none)", gf, "Access", "ScanKey")
        IniWrite(scanMode, gf, "Access", "ScanMode")
        IniWrite(scanMs, gf, "Access", "ScanMs")
    }
}

AccessRegisterKeys() {
    global kmToggleKey, kmRegisteredToggle, scanKey, scanRegisteredKey, kmOn, windowKey, windowRegisteredKey
    if (windowRegisteredKey != "") {
        try Hotkey("*" windowRegisteredKey, "Off")
        windowRegisteredKey := ""
    }
    if (windowKey != "") {
        try {
            Hotkey("*" windowKey, ToggleMainWindow, "On")
            windowRegisteredKey := windowKey
        }
    }
    if (kmRegisteredToggle != "") {
        try Hotkey("*" kmRegisteredToggle, "Off")
        kmRegisteredToggle := ""
    }
    if (kmToggleKey != "") {
        try {
            Hotkey("*" kmToggleKey, KmToggle, "On")
            kmRegisteredToggle := kmToggleKey
        }
    }
    if (scanRegisteredKey != "") {
        try Hotkey("*" scanRegisteredKey, "Off")
        try Hotkey("*" scanRegisteredKey " Up", "Off")
        scanRegisteredKey := ""
    }
    if (scanKey != "") {
        try {
            Hotkey("*" scanKey, ScanKeyDown, "On")
            Hotkey("*" scanKey " Up", ScanKeyUp, "On")
            scanRegisteredKey := scanKey
        }
    }
    if (kmOn)
        KmSetHotkeys(true)
}

; ---- tremor filter ----
; Ignores a repeat press that comes too soon after the last one, and (optionally)
; only accepts a press when the key is held for a short moment.
TremorAllow(key) {
    global tremorMs, tremorHoldMs, tremorLast
    if (tremorMs <= 0 && tremorHoldMs <= 0)
        return true
    now := A_TickCount
    if (tremorMs > 0 && tremorLast.Has(key) && now - tremorLast[key] < tremorMs)
        return false
    if (tremorHoldMs > 0) {
        plain := RegExReplace(key, "^[~*$]+")
        t0 := now
        while (A_TickCount - t0 < tremorHoldMs) {
            if (!GetKeyState(plain, "P"))
                return false
            Sleep(10)
        }
    }
    tremorLast[key] := A_TickCount
    return true
}

; ---- keyboard mouse ----
KmToggle(*) {
    global kmOn
    if (kmOn)
        KmTurnOff(true)
    else
        KmTurnOn()
}

KmTurnOn() {
    global kmOn, kmLastTick, kmAccX, kmAccY, kmMoveStart
    kmOn := true
    kmLastTick := A_TickCount
    kmAccX := 0
    kmAccY := 0
    kmMoveStart := 0
    KmSetHotkeys(true)
    SetTimer(KmTick, 10)
    NotifyUser(LangT("Keyboard mouse: ON"))
    FlashOSD(LangT("KEYBOARD MOUSE: ON"), "00CCFF", 1500)
}

KmTurnOff(announce := true) {
    global kmOn
    kmOn := false
    SetTimer(KmTick, 0)
    KmSetHotkeys(false)
    KmReleaseAll()
    if (announce) {
        NotifyUser(LangT("Keyboard mouse: OFF"))
        FlashOSD(LangT("KEYBOARD MOUSE: OFF"), "FF0000", 1200)
    }
}

KmForceOff() {
    global kmOn
    if (kmOn)
        KmTurnOff(false)
}

KmNoop(*) {
}

KmSetHotkeys(on) {
    global kmKeys, kmToggleKey, kmHotkeysSet
    for k in kmHotkeysSet {
        try Hotkey("*" k, "Off")
        try Hotkey("*" k " Up", "Off")
    }
    kmHotkeysSet := []
    if (!on)
        return
    for name, key in kmKeys {
        if (key = "" || StrLower(key) = StrLower(kmToggleKey))
            continue
        try {
            if (name = "lclick" || name = "rclick" || name = "mclick") {
                btn := (name = "lclick") ? "lbutton" : ((name = "rclick") ? "rbutton" : "mbutton")
                Hotkey("*" key, KmClick.Bind(btn, true), "On")
                Hotkey("*" key " Up", KmClick.Bind(btn, false), "On")
            } else if (name = "scrollup" || name = "scrolldown") {
                Hotkey("*" key, KmWheel.Bind(name = "scrollup" ? 1 : -1), "On")
                Hotkey("*" key " Up", KmNoop, "On")
            } else {
                Hotkey("*" key, KmNoop, "On")
                Hotkey("*" key " Up", KmNoop, "On")
            }
            kmHotkeysSet.Push(key)
        }
    }
}

KmClick(btn, down, *) {
    global kmBtnHeld
    if (down) {
        if (kmBtnHeld.Has(btn))
            return
        MouseButtonEvent(btn, true)
        kmBtnHeld[btn] := true
    } else if (kmBtnHeld.Has(btn)) {
        MouseButtonEvent(btn, false)
        kmBtnHeld.Delete(btn)
    }
}

KmWheel(dir, *) {
    MouseWheelTick(dir)
}

KmReleaseAll() {
    global kmBtnHeld
    for btn, v in kmBtnHeld {
        try MouseButtonEvent(btn, false)
    }
    kmBtnHeld := Map()
}

KmKeyDown(key) {
    return (key != "" && GetKeyState(key, "P")) ? true : false
}

KmTick() {
    global kmOn, kmKeys, kmSpeed, kmAccel, kmLastTick, kmAccX, kmAccY, kmMoveStart
    if (!kmOn)
        return
    now := A_TickCount
    dt := Min(50, Max(1, now - kmLastTick))
    kmLastTick := now
    vx := 0
    vy := 0
    if (KmKeyDown(kmKeys["left"]))
        vx -= 1
    if (KmKeyDown(kmKeys["right"]))
        vx += 1
    if (KmKeyDown(kmKeys["up"]))
        vy -= 1
    if (KmKeyDown(kmKeys["down"]))
        vy += 1
    if (vx = 0 && vy = 0) {
        kmMoveStart := 0
        kmAccX := 0
        kmAccY := 0
        return
    }
    if (kmMoveStart = 0)
        kmMoveStart := now
    factor := 1
    if (kmAccel)
        factor := 1 + Min(3, (now - kmMoveStart) / 800)
    if (vx != 0 && vy != 0)
        factor *= 0.7071
    kmAccX += vx * kmSpeed * factor * dt / 1000
    kmAccY += vy * kmSpeed * factor * dt / 1000
    ix := Integer(kmAccX)
    iy := Integer(kmAccY)
    kmAccX -= ix
    kmAccY -= iy
    if (ix != 0 || iy != 0)
        RelMoveRaw(ix, iy)
}

; ---- one-button control (single-switch scanning) ----
ScanKeyDown(*) {
    global scanOn, scanMode, scanKeyIsDown, scanKeyDownTick
    if (scanKeyIsDown)
        return
    scanKeyIsDown := true
    if (!scanOn) {
        scanKeyDownTick := 0
        ScanOpen()
        return
    }
    if (scanMode = "auto") {
        ScanSelect()
        return
    }
    scanKeyDownTick := A_TickCount
}

ScanKeyUp(*) {
    global scanOn, scanMode, scanKeyIsDown, scanKeyDownTick
    scanKeyIsDown := false
    if (!scanOn || scanMode != "step" || scanKeyDownTick = 0)
        return
    held := A_TickCount - scanKeyDownTick
    scanKeyDownTick := 0
    if (held >= 700)
        ScanSelect()
    else
        ScanAdvance()
}

ScanToggleMenu(*) {
    global scanOn
    if (scanOn)
        ScanClose()
    else
        ScanOpen()
}

ScanOpen() {
    global rows, scanOn, scanIdx, scanItems, scanLoops, scanMode, scanMs
    scanItems := []
    for row in rows {
        if (row.trigger = "" || row.keys.Length = 0 || IsJoyTrigger(row.trigger))
            continue
        if (row.HasOwnProp("enabled") && !row.enabled)
            continue
        if (scanItems.Length >= 14)
            break
        scanItems.Push({row: row, label: CheatTrim(CheatDescribe(row), 46) . "  [" . CheatModeLabel(row.mode) . "]"})
    }
    if (scanItems.Length = 0) {
        NotifyUser(LangT("One-button control: this profile has no rows to choose from."), -2500)
        return
    }
    scanIdx := 1
    scanLoops := 0
    scanOn := true
    ScanShow()
    if (scanMode = "auto")
        SetTimer(ScanAdvance, scanMs)
    else
        SetTimer(ScanClose, -20000)
}

ScanShow() {
    global scanGui, scanTexts, scanItems, scanIdx, scanMode
    try scanGui.Destroy()
    scanTexts := []
    scanGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border +E0x08000000", LangT("One-button control"))
    scanGui.BackColor := "101820"
    scanGui.MarginX := 24
    scanGui.MarginY := 18
    scanGui.SetFont("s14 cFFFFFF", "Consolas")
    scanGui.Add("Text", "w560 0x80", scanMode = "auto" ? LangT("ONE-BUTTON CONTROL - press your key to choose the highlighted action") : LangT("ONE-BUTTON CONTROL - tap = next, hold = choose"))
    scanGui.SetFont("s16 cFFFFFF", "Consolas")
    for i, it in scanItems
        scanTexts.Push(scanGui.Add("Text", "w560 y+8 0x80", "   " . it.label))
    scanGui.Show("NoActivate AutoSize xCenter yCenter")
    ScanHighlight()
}

ScanHighlight() {
    global scanTexts, scanItems, scanIdx
    for i, t in scanTexts {
        label := scanItems[i].label
        if (i = scanIdx) {
            t.Text := ">> " . label
            t.SetFont("cFFFF00 bold")
        } else {
            t.Text := "   " . label
            t.SetFont("cFFFFFF norm")
        }
    }
}

ScanAdvance(*) {
    global scanOn, scanIdx, scanItems, scanLoops, scanMode
    if (!scanOn)
        return
    scanIdx += 1
    if (scanIdx > scanItems.Length) {
        scanIdx := 1
        scanLoops += 1
        if (scanMode = "auto" && scanLoops >= 2) {
            ScanClose()
            return
        }
    }
    ScanHighlight()
    if (scanMode = "step")
        SetTimer(ScanClose, -20000)
}

ScanSelect() {
    global scanOn, scanIdx, scanItems
    if (!scanOn || scanIdx < 1 || scanIdx > scanItems.Length)
        return
    row := scanItems[scanIdx].row
    ScanClose()
    ScanFire(row)
}

; Acts like a quick tap of the row's own trigger key, so every mode works.
ScanFire(row) {
    trig := row.trigger
    try {
        HandlePress(trig)
        Sleep(40)
        HandleRelease(trig)
    }
}

ScanClose(*) {
    global scanOn, scanGui
    SetTimer(ScanAdvance, 0)
    SetTimer(ScanClose, 0)
    scanOn := false
    try scanGui.Destroy()
    scanGui := 0
}

; ---- editing a row's note (shown in the cheat sheet and in one-button control) ----
EditRowNote(slotIdx) {
    global rows, scrollOffset
    SyncBoxesToRows()
    idx := scrollOffset + slotIdx
    if (idx > rows.Length) {
        MsgBox(LangT("This row is empty. Fill in the trigger and combo first."), LangT("Row note"), "Icon! 262144")
        return
    }
    row := rows[idx]
    cur := row.HasOwnProp("note") ? row.note : ""
    ib := NamePrompt(LangT("Row note"), LangT("Short note for this row (shown in the cheat sheet, the status box and one-button control).`nExample: Walk forward (toggle)"), cur)
    if (ib.Result != "OK")
        return
    row.note := Trim(RegExReplace(ib.Value, "[\r\n]+", " "))
    NotifyUser(LangT("Note saved for this row. Press Apply to save the profile."), -2500)
}

; Status-box message when a row fires: the row's note if it has one (and the setting is on),
; otherwise the usual "key -> combo" text.
FireFlash(row, fallback, color := "00FFFF", suffix := "") {
    global showFireName, fireNameMs, showOsdRunning
    note := row.HasOwnProp("note") ? Trim(row.note) : ""
    if (showFireName && note != "")
        FlashOSD(CheatTrim(note . suffix, 42), color, fireNameMs)
    else
        FlashOSD(fallback, color)
}
; ---- bring the main window to the front while in a game ----
OwnWindowActive() {
    try return (WinGetPID("A") = ProcessExist()) ? true : false
    return false
}

ToggleMainWindow(*) {
    global myGui, prevWinHwnd, winKeepTop
    if (!IsObject(myGui))
        return
    visible := DllCall("IsWindowVisible", "Ptr", myGui.Hwnd)
    if (visible && WinActive("ahk_id " . myGui.Hwnd)) {
        ; hide it and give the game its focus back
        myGui.Hide()
        if (prevWinHwnd && WinExist("ahk_id " . prevWinHwnd))
            try WinActivate("ahk_id " . prevWinHwnd)
        return
    }
    prevWinHwnd := WinExist("A")
    if (prevWinHwnd = myGui.Hwnd)
        prevWinHwnd := 0
    myGui.Show()
    try WinRestore("ahk_id " . myGui.Hwnd)
    try WinSetAlwaysOnTop(winKeepTop ? true : false, "ahk_id " . myGui.Hwnd)
    try WinActivate("ahk_id " . myGui.Hwnd)
}

; While any window of this program is in front, the row hotkeys are switched off so keys
; can be typed into the boxes safely; they come back when you return to the game.
EditSafetyTick() {
    global rowHotkeysOn, registeredRowTriggers
    own := OwnWindowActive()
    if (own && rowHotkeysOn) {
        for t in registeredRowTriggers {
            try Hotkey(t, "Off")
            try Hotkey(t " Up", "Off")
        }
        rowHotkeysOn := false
    } else if (!own && !rowHotkeysOn) {
        RegisterRowHotkeys()
    }
}

; ---- the Accessibility tools window ----
ShowAccessTools(*) {
    global accGui, tremorMs, tremorHoldMs, kmToggleKey, kmSpeed, kmAccel, kmKeys, scanKey, scanMode, scanMs, windowKey, winKeepTop
    if (IsObject(accGui)) {
        try {
            accGui.Show()
            return
        }
    }
    accGui := Gui("+AlwaysOnTop +ToolWindow", LangT("Accessibility tools"))
    accGui.SetFont("s10")
    c := Map()
    accGui.Add("GroupBox", "xm ym w420 h104", LangT("Edit while in the game (bring this window to the front)"))
    accGui.Add("Text", "x24 yp+28 w150", LangT("Show / hide key:"))
    c["winKey"] := accGui.Add("Edit", "x180 yp-3 w60", windowKey)
    winB := accGui.Add("Button", "x+5 yp w78 h24", LangT("Bind"))
    winB.OnEvent("Click", (*) => CaptureSingleKey(c["winKey"]))
    c["winTop"] := accGui.Add("Checkbox", "x24 y+14 w380" . (winKeepTop ? " Checked" : ""), LangT("Keep it on top of the game while it is open"))
    accGui.Add("GroupBox", "xm y+26 w420 h110", LangT("Tremor filter"))
    accGui.Add("Text", "x24 yp+28 w250", LangT("Ignore a repeat press within (ms, 0 = off):"))
    c["tremor"] := accGui.Add("Edit", "x290 yp-3 w70 Number", tremorMs)
    accGui.Add("Text", "x24 y+14 w250", LangT("Key must be held for (ms, 0 = off):"))
    c["tremorHold"] := accGui.Add("Edit", "x290 yp-3 w70 Number", tremorHoldMs)

    accGui.Add("GroupBox", "xm y+26 w420 h330", LangT("Keyboard mouse (keys move the cursor and click)"))
    accGui.Add("Text", "x24 yp+28 w110", LangT("On/Off key:"))
    c["kmToggle"] := accGui.Add("Edit", "x140 yp-3 w60", kmToggleKey)
    kmToggleB := accGui.Add("Button", "x+5 yp w78 h24", LangT("Bind"))
    kmToggleB.OnEvent("Click", (*) => CaptureSingleKey(c["kmToggle"]))
    accGui.Add("Text", "x24 y+14 w110", LangT("Speed (px/sec):"))
    c["kmSpeed"] := accGui.Add("Edit", "x140 yp-3 w70 Number", kmSpeed)
    c["kmAccel"] := accGui.Add("Checkbox", "x+12 yp+3" . (kmAccel ? " Checked" : ""), LangT("Speed up while held"))
    labels := Map("up", "Up:", "down", "Down:", "left", "Left:", "right", "Right:", "lclick", "Left click:", "rclick", "Right click:", "mclick", "Middle click:", "scrollup", "Scroll up:", "scrolldown", "Scroll down:")
    order := ["up", "down", "left", "right", "lclick", "rclick", "mclick", "scrollup", "scrolldown"]
    accGui.Add("Text", "x24 y+16 w380", LangT("Keys (only active while the keyboard mouse is ON):"))
    for i, name in order {
        isLeft := (Mod(i, 2) = 1)
        accGui.Add("Text", (isLeft ? "x24 y+10" : "x+14 yp") . " w86", labels[name])
        c["km_" . name] := accGui.Add("Edit", "x+2 yp-3 w44", kmKeys[name])
        bb := accGui.Add("Button", "x+3 yp w78 h24", LangT("Bind"))
        bb.OnEvent("Click", KmBindClick.Bind(c["km_" . name]))
    }

    accGui.Add("GroupBox", "xm y+30 w420 h150", LangT("One-button control (one key steps through your actions)"))
    accGui.Add("Text", "x24 yp+28 w110", LangT("Switch key:"))
    c["scanKey"] := accGui.Add("Edit", "x140 yp-3 w60", scanKey)
    scanB := accGui.Add("Button", "x+5 yp w78 h24", LangT("Bind"))
    scanB.OnEvent("Click", (*) => CaptureSingleKey(c["scanKey"]))
    accGui.Add("Text", "x24 y+14 w110", LangT("How it works:"))
    c["scanMode"] := accGui.Add("DropDownList", "x140 yp-3 w270 Choose" . (scanMode = "step" ? 2 : 1), [LangT("Automatic (the highlight moves by itself)"), LangT("Step (tap = next, hold = choose)")])
    accGui.Add("Text", "x24 y+14 w110", LangT("Speed (ms):"))
    c["scanMs"] := accGui.Add("Edit", "x140 yp-3 w70 Number", scanMs)

    applyB := accGui.Add("Button", "xm y+24 w120 h32 Default", LangT("Apply"))
    closeB := accGui.Add("Button", "x+8 yp w100 h32", LangT("Close"))
    accGui.Add("Text", "xm y+12 w420", LangT("Leave a key empty to switch that function off. The panic key turns the keyboard mouse and one-button control off at once."))
    applyB.OnEvent("Click", (*) => AccessApply(c))
    closeB.OnEvent("Click", (*) => AccessClose())
    accGui.OnEvent("Close", (*) => AccessClose())
    accGui.Show()
}

KmBindClick(edit, *) {
    CaptureSingleKey(edit)
}

AccessClose() {
    global accGui
    try accGui.Destroy()
    accGui := 0
}

AccessApply(c) {
    global tremorMs, tremorHoldMs, kmToggleKey, kmSpeed, kmAccel, kmKeys, scanKey, scanMode, scanMs, panicKey, windowKey, winKeepTop
    tremorMs := QteIntSafe(c["tremor"].Value, 0, 0, 2000)
    tremorHoldMs := QteIntSafe(c["tremorHold"].Value, 0, 0, 2000)
    kmSpeed := QteIntSafe(c["kmSpeed"].Value, 700, 100, 4000)
    kmAccel := c["kmAccel"].Value ? true : false
    newToggle := Trim(c["kmToggle"].Text)
    newScan := Trim(c["scanKey"].Text)
    newWin := Trim(c["winKey"].Text)
    problems := ""
    for k in [newToggle, newScan, newWin] {
        if (k != "" && StrLower(k) = StrLower(panicKey))
            problems .= "'" . k . LangT("' is the panic key.`n")
        else if (k != "" && KeyClash(k, [])) {
            problems .= "'" . k . LangT("' is already a trigger in this profile.`n")
        }
    }
    if ((newToggle != "" && StrLower(newToggle) = StrLower(newScan)) || (newWin != "" && (StrLower(newWin) = StrLower(newScan) || StrLower(newWin) = StrLower(newToggle))))
        problems .= LangT("The window key, the keyboard mouse key and the one-button key must all differ.`n")
    if (problems != "") {
        MsgBox(LangT("Please pick different keys:`n`n") . problems, LangT("Accessibility tools"), "Icon! 262144")
        return
    }
    kmToggleKey := newToggle
    windowKey := newWin
    winKeepTop := c["winTop"].Value ? true : false
    for name, edit in Map("up", c["km_up"], "down", c["km_down"], "left", c["km_left"], "right", c["km_right"], "lclick", c["km_lclick"], "rclick", c["km_rclick"], "mclick", c["km_mclick"], "scrollup", c["km_scrollup"], "scrolldown", c["km_scrolldown"])
        kmKeys[name] := Trim(edit.Text)
    scanKey := newScan
    scanMode := (c["scanMode"].Value = 2) ? "step" : "auto"
    scanMs := QteIntSafe(c["scanMs"].Value, 1200, 300, 5000)
    AccessSave()
    AccessRegisterKeys()
    NotifyUser(LangT("Accessibility tools saved"))
}

; A small naming dialog: the text box has the keyboard focus and its text is selected,
; Enter = OK, Esc = Cancel. Returns an object shaped like InputBox's: {Result, Value}.
NamePrompt(title, promptText, initial := "") {
    state := Map("done", false, "ok", false, "text", "")
    g := Gui("+AlwaysOnTop +ToolWindow", title)
    g.SetFont("s10")
    g.Add("Text", "w420", promptText)
    ed := g.Add("Edit", "w420 y+8", initial)
    okB := g.Add("Button", "y+14 w100 h30 Default", LangT("OK"))
    cancelB := g.Add("Button", "x+8 yp w100 h30", LangT("Cancel"))
    okB.OnEvent("Click", (*) => NamePromptDone(g, ed, state, true))
    cancelB.OnEvent("Click", (*) => NamePromptDone(g, ed, state, false))
    g.OnEvent("Close", (*) => NamePromptDone(g, ed, state, false))
    g.OnEvent("Escape", (*) => NamePromptDone(g, ed, state, false))
    g.Show()
    try WinActivate("ahk_id " . g.Hwnd)
    ed.Focus()
    try SendMessage(0xB1, 0, -1, ed)
    while (!state["done"])
        Sleep(30)
    return {Result: state["ok"] ? "OK" : "Cancel", Value: state["text"]}
}

NamePromptDone(g, ed, state, ok) {
    if (state["done"])
        return
    state["ok"] := ok
    state["text"] := ed.Value
    state["done"] := true
    try g.Destroy()
}

; ============================================================
; ---- LANGUAGES (v9.6) ----
; Every piece of visible text goes through LangT(). English is the original text;
; other languages are lists of "English text" -> "translated text" (see LangData_hu).
; A text with no translation simply stays in English.
; ============================================================
LangT(text) {
    global langMap
    if (langMap.Count = 0)
        return text
    return langMap.Has(text) ? langMap[text] : text
}

LangLoad() {
    global langCode, langMap, dataDir
    langMap := Map()
    try langCode := IniRead(dataDir "\remapper_global.ini", "Global", "Language", "en")
    if (langCode = "hu")
        LangData_hu(langMap)
    if (langCode != "en") {
        f := dataDir "\lang\" . langCode . ".po"
        if (FileExist(f))
            LangLoadFile(f, langMap)
    }
}

; Text of one translated word, for the mode names. Falls back to the English word.
LangMode(name, fallback := "") {
    global langMap
    key := "mode:" . name
    if (langMap.Count > 0 && langMap.Has(key))
        return langMap[key]
    return (fallback != "") ? fallback : name
}

LangDir() {
    global dataDir
    d := dataDir "\lang"
    try {
        if (!DirExist(d))
            DirCreate(d)
    }
    return d
}

; Every language that can be chosen: English, Magyar, and any .po file in the lang folder
LangList() {
    list := [{code: "en", name: "English"}, {code: "hu", name: "Magyar"}]
    seen := Map("en", true, "hu", true)
    try {
        pat := LangDir() "\*.po"
        loop files, pat {
            code := RegExReplace(A_LoopFileName, "\.po$")
            if (StrLower(code) = "template" || seen.Has(StrLower(code)))
                continue
            name := code
            try {
                head := FileRead(A_LoopFileFullPath, "UTF-8")
                if (RegExMatch(head, "m)^#\s*Language:\s*(.+?)\s*$", &nm))
                    name := nm[1]
            }
            list.Push({code: code, name: name})
            seen[StrLower(code)] := true
        }
    }
    return list
}

LangPickItem(code, *) {
    LangSet(code)
}

; Reads a community translation file (.po style: msgid "English" / msgstr "Translation")
LangLoadFile(path, m) {
    text := ""
    try text := FileRead(path, "UTF-8")
    if (text = "")
        return 0
    id := ""
    str := ""
    part := ""
    added := 0
    for rawLine in StrSplit(text, "`n", "`r") {
        line := Trim(rawLine)
        if (SubStr(line, 1, 1) = "#")
            continue
        if (RegExMatch(line, '^msgid\s+"(.*)"$', &mm)) {
            if (id != "" && str != "") {
                m[id] := str
                added += 1
            }
            id := PoUnescape(mm[1])
            str := ""
            part := "id"
        } else if (RegExMatch(line, '^msgstr\s+"(.*)"$', &mm)) {
            str := PoUnescape(mm[1])
            part := "str"
        } else if (RegExMatch(line, '^"(.*)"$', &mm)) {
            if (part = "id")
                id .= PoUnescape(mm[1])
            else if (part = "str")
                str .= PoUnescape(mm[1])
        }
    }
    if (id != "" && str != "") {
        m[id] := str
        added += 1
    }
    return added
}

PoUnescape(text) {
    out := ""
    i := 1
    n := StrLen(text)
    while (i <= n) {
        c := SubStr(text, i, 1)
        if (c = "\" && i < n) {
            d := SubStr(text, i + 1, 1)
            if (d = "n")
                out .= "`n"
            else if (d = "r")
                out .= "`r"
            else if (d = "t")
                out .= "`t"
            else
                out .= d
            i += 2
        } else {
            out .= c
            i += 1
        }
    }
    return out
}

PoEscape(text) {
    text := StrReplace(text, "\", "\\")
    text := StrReplace(text, '"', '\"')
    text := StrReplace(text, "`r", "\r")
    text := StrReplace(text, "`n", "\n")
    text := StrReplace(text, "`t", "\t")
    return text
}

; Writes lang\template.po with every English text, ready to be translated
LangExportTemplate(*) {
    q := Chr(34)
    tmp := Map()
    LangData_hu(tmp)
    text := "# Combo ReMapper translation file`n"
    text .= "# Language: Write the name of your language here (for example: Deutsch)`n"
    text .= "# Save a copy of this file as <code>.po in this same folder (for example de.po), then pick the language in Settings.`n"
    text .= "# Write your translation between the quotes after each msgstr. Leave msgstr empty to keep the English text.`n"
    text .= "# Do not change the msgid lines. Keep symbols such as \n and the parts in quotes the same.`n`n"
    for key, value in tmp
        text .= "msgid " q PoEscape(key) q "`nmsgstr " q q "`n`n"
    path := LangDir() "\template.po"
    try FileDelete(path)
    try {
        FileAppend(text, path, "UTF-8")
        NotifyUser(LangT("Translation template saved: ") . path, -4000)
        Run('explorer.exe /select,"' . path . '"')
    } catch {
        NotifyUser(LangT("Could not save the template file."), -3000)
    }
}

; Copies one or more translation files (.po) into the lang folder so they show up in the language list.
LangAddFiles(dd := "", *) {
    global langCode, dataDir
    sel := ""
    try sel := FileSelect("M3", A_ScriptDir, LangT("Add language file(s)"), LangT("Translation files") . " (*.po)")
    if (!IsObject(sel) || sel.Length = 0)
        return
    added := 0
    lastCode := ""
    for path in sel {
        SplitPath(path, &fn)
        if (!RegExMatch(fn, "i)\.po$") || StrLower(fn) = "template.po")
            continue
        try {
            target := LangDir() . "\" . fn
            if (StrLower(path) != StrLower(target))
                FileCopy(path, target, 1)
            added += 1
            lastCode := RegExReplace(fn, "i)\.po$")
        }
    }
    if (added = 0) {
        NotifyUser(LangT("Could not add the language file."), -3000)
        return
    }
    if (IsObject(dd)) {
        try {
            names := []
            pick := 1
            for i, item in LangList() {
                names.Push(item.name)
                if (item.code = langCode)
                    pick := i
            }
            dd.Delete()
            dd.Add(names)
            dd.Choose(pick)
        }
    }
    NotifyUser(LangT("Language added: ") . lastCode, -3000)
    if (MsgBox(LangT("Switch to it now? (the program restarts)"), LangT("Add language file..."), "YesNo Icon? 262144") = "Yes") {
        try IniWrite(lastCode, dataDir "\remapper_global.ini", "Global", "Language")
        Reload()
    }
}

LangOpenFolder(*) {
    try Run('explorer.exe "' . LangDir() . '"')
}

LangSet(code) {
    global langCode, dataDir
    if (code = langCode)
        return
    try IniWrite(code, dataDir "\remapper_global.ini", "Global", "Language")
    if (MsgBox("Restart the program now to apply the language?`n`nÚjraindítod most a programot a nyelv alkalmazásához?", "Language / Nyelv", "YesNo Icon? 262144") = "Yes")
        Reload()
}

LangData_hu(m) {
    m["Combo ReMapper hit a problem while starting:`n`n"] := "A Combo ReMapper hibába ütközött indítás közben:`n`n"
    m[", line "] := ", sor "
    m[")`n`nThe program may not work correctly. If you ask for help, please send this message."] := ")`n`nA program lehet, hogy nem működik megfelelően. Ha segítséget kérsz, küldd el ezt az üzenetet."
    m["Combo ReMapper - startup problem"] := "Combo ReMapper - indítási hiba"
    m["REMAPPER: ACTIVE"] := "REMAPPER: AKTÍV"
    m["REMAPPER: DISABLED"] := "REMAPPER: KIKAPCSOLVA"
    m["Compatibility: "] := "Kompatibilitás: "
    m["Controller type: "] := "Kontroller típusa: "
    m["Hold..."] := "Tartsd..."
    m["Hold the controller buttons you want, then let go."] := "Tartsd nyomva a kívánt kontrollergombokat, majd engedd el."
    m["Detect"] := "Érzékel"
    m["Show / hide window"] := "Ablak megjelenítése / elrejtése"
    m["Remapper on / off"] := "Remapper be / ki"
    m["Switch profile"] := "Profil váltása"
    m["Key cheat sheet"] := "Billentyű-puska"
    m["Next page"] := "Következő lap"
    m["Previous page"] := "Előző lap"
    m["Pages"] := "Lapok"
    m["Setup wizard..."] := "Beállítási varázsló..."
    m["Settings..."] := "Beállítások..."
    m["Accessibility tools..."] := "Akadálymentesítő eszközök..."
    m["Status box on / off"] := "Állapotdoboz be / ki"
    m["Keyboard mouse on / off"] := "Billentyűzetes egér be / ki"
    m["One-button control menu"] := "Egygombos vezérlés menü"
    m["Customize look..."] := "Megjelenés testreszabása..."
    m["Check combos..."] := "Kombók ellenőrzése..."
    m["Auto-switch profile by game"] := "Profil automatikus váltása játék szerint"
    m["Create starter profile"] := "Kezdő profil létrehozása"
    m["Input mode"] := "Bemeneti mód"
    m["Controller support on / off"] := "Kontroller-támogatás be / ki"
    m["Controller type"] := "Kontroller típusa"
    m["Controller test..."] := "Kontroller teszt..."
    m["Controller"] := "Kontroller"
    m["Copy diagnostics"] := "Diagnosztika másolása"
    m["Open log file"] := "Naplófájl megnyitása"
    m["More"] := "Továbbiak"
    m["Help..."] := "Súgó..."
    m["About..."] := "Névjegy..."
    m["Exit"] := "Kilépés"
    m["About Combo ReMapper"] := "A Combo ReMapper névjegye"
    m["About the creator"] := "A készítőről"
    m["Made by "] := "Készítette: "
    m[".`n`nI'm handicapped, and I make these tools so that games and programs are easier for me, and for others, to play and use."] := ".`n`nMozgássérült vagyok, és azért készítem ezeket az eszközöket, hogy a játékok és programok könnyebben játszhatók és használhatók legyenek számomra és mások számára is."
    m["Made with AI"] := "MI segítségével készült"
    m["Why I say this"] := "Miért mondom el ezt"
    m["- People should know how software is made.`n- I came up with the idea and decided how it works and what it should do; the AI wrote the code.`n- If something breaks, people know the code was written by an AI and may need checking.`n- It shows that people like me can build our own tools with AI."] := "- Az embereknek tudniuk kell, hogyan készül a szoftver.`n- Én találtam ki az ötletet, én döntöttem el, hogyan működik és mit csináljon; a kódot az MI írta.`n- Ha valami elromlik, az emberek tudják, hogy a kódot MI írta, és szükség lehet az ellenőrzésére.`n- Megmutatja, hogy a hozzám hasonló emberek is megépíthetik a saját eszközeiket MI segítségével."
    m["Close"] := "Bezár"
    m["Controller support: ON"] := "Kontroller-támogatás: BE"
    m["Controller support: OFF"] := "Kontroller-támogatás: KI"
    m["Indicator Overlay: OFF"] := "Jelzőkijelző: KI"
    m["Indicator Overlay: ON"] := "Jelzőkijelző: BE"
    m["Y-Axis Locked"] := "Y tengely zárolva"
    m["Y-Axis Unlocked"] := "Y tengely feloldva"
    m["Failed to bind Y-axis lock key: "] := "Nem sikerült lekötni az Y-tengely zár billentyűt: "
    m["Failed to bind panic key: "] := "Nem sikerült lekötni a vészleállító billentyűt: "
    m["Failed to bind OSD toggle key: "] := "Nem sikerült lekötni az állapotdoboz billentyűt: "
    m["Combo remapper: ON"] := "Combo remapper: BE"
    m["Combo remapper: OFF"] := "Combo remapper: KI"
    m["Profile '"] := "A(z) '"
    m["' copied to clipboard!"] := "' profil a vágólapra másolva!"
    m["Invalid profile string in clipboard."] := "Érvénytelen profil szöveg a vágólapon."
    m["Import Error"] := "Importálási hiba"
    m["Imported & Switched to profile '"] := "Importálva, átváltva erre a profilra: '"
    m["Press the key you want to bind ("] := "Nyomd meg a lekötni kívánt billentyűt ("
    m[" seconds)..."] := " másodperc)..."
    m["No key was pressed - nothing changed."] := "Nem nyomtál billentyűt - semmi sem változott."
    m["Binding cancelled."] := "Az automata gomb választás megszakítva."
    m["Bound key: "] := "Kiválasztott billentyű: "
    m["[REC]"] := "[FELV]"
    m["RECORDING INPUTS..."] := "BEMENETEK FELVÉTELE..."
    m["RECORDING... Press keys, mouse buttons, or gamepad! ("] := "FELVÉTEL... Nyomj billentyűket, egérgombokat vagy kontrollergombokat! ("
    m[" seconds)"] := " másodperc)"
    m["CAPTURED: "] := "RÖGZÍTVE: "
    m["PRESS THE TRIGGER KEY..."] := "NYOMD MEG AZ INDÍTÓ BILLENTYŰT..."
    m["Press the key or mouse button to use as the trigger ("] := "Nyomd meg az indítóként használni kívánt billentyűt vagy egérgombot ("
    m["TRIGGER: "] := "INDÍTÓ: "
    m["Profile:"] := "Profil:"
    m["+New"] := "+Új"
    m["-Del"] := "-Tör"
    m["Settings"] := "Beáll."
    m["Theme:"] := "Téma:"
    m["Trigger key"] := "Indító gomb"
    m["On"] := "Be"
    m["Holds/Executes keys"] := "Billentyűket tart/küld"
    m["Mode"] := "Mód"
    m["Rem"] := "Töröl"
    m["Press this, then press the key or mouse button you want as the trigger. It fills the box for you."] := "Nyomd meg ezt, majd azt a billentyűt vagy egérgombot, amelyet indítóként szeretnél. Kitölti a mezőt helyetted."
    m["+ Add Combo"] := "+ Kombó hozzáadása"
    m["Panic Toggle key:"] := "Vészleállító billentyű:"
    m["Bind"] := "Auto gomb"
    m["Scroll-click key:"] := "Görgő-katt.:"
    m["Target Exe filter:"] := "Célprogram szűrő:"
    m["(blank/any)"] := "(üres/bármelyik)"
    m["Apply"] := "Alkalmaz"
    m["Turn OFF"] := "Kikapcsol"
    m["Turn ON"] := "Bekapcsol"
    m["ON"] := "BE"
    m["Auto-switched to profile '"] := "Automatikusan átváltva erre a profilra: '"
    m["' for "] := "' - játék: "
    m["Auto-switch profile by game: "] := "Profil automatikus váltása játék szerint: "
    m["OFF"] := "KI"
    m["' is not a key, mouse button or controller button name"] := "' nem billentyű-, egérgomb- vagy kontrollergomb-név"
    m[": no keys to send"] := ": nincs elküldendő billentyű"
    m[": TapHold needs two keys (first = tap, second = hold)"] := ": a TapHold két billentyűt igényel (az első = koppintás, a második = tartás)"
    m["' is a controller button and cannot be sent as output"] := "' kontrollergomb, nem küldhető ki kimenetként"
    m["' does nothing in Hold or Toggle rows (use Press, Turbo, TglTurbo or DblTap)"] := "' nem csinál semmit Hold vagy Toggle soroknál (használj Press, Turbo, TglTurbo vagy DblTap módot)"
    m[": unknown key name in '"] := ": ismeretlen billentyűnév itt: '"
    m["' is not written correctly (burst:x,30,40   alt:x/c,30,40   hold:x,800)"] := "' hibásan van írva (burst:x,30,40   alt:x/c,30,40   hold:x,800)"
    m[": unknown key name '"] := ": ismeretlen billentyűnév '"
    m["' in '"] := "' itt: '"
    m["' does nothing in Hold or Toggle rows (use Press, Turbo or TglTurbo)"] := "' nem csinál semmit Hold vagy Toggle soroknál (használj Press, Turbo vagy TglTurbo módot)"
    m["' only works in Hold or Toggle rows"] := "' csak Hold vagy Toggle soroknál működik"
    m["No problems found in your combos."] := "Nem találtam hibát a kombóidban."
    m["Combo check"] := "Kombó-ellenőrzés"
    m["Possible problems in your combos:`n`n"] := "Lehetséges hibák a kombóidban:`n`n"
    m["Controller Test"] := "Kontroller teszt"
    m["PS4 / generic pad (DirectInput)`n"] := "PS4 / általános kontroller (DirectInput)`n"
    m["  pad: "] := "  kontroller: "
    m["  buttons down:"] := "  lenyomott gombok:"
    m["  d-pad: "] := "  iránygombok: "
    m["  stick directions:"] := "  kar irányok:"
    m["  no DirectInput pad found`n"] := "  nincs DirectInput kontroller`n"
    m["`nXbox pad (XInput)`n"] := "`nXbox kontroller (XInput)`n"
    m["  slot "] := "  hely "
    m["  no Xbox pad found`n"] := "  nincs Xbox kontroller`n"
    m["COMBO REMAPPER - QUICK HELP"] := "COMBO REMAPPER - GYORS SÚGÓ"
    m["WHAT IT DOES"] := "MIT CSINÁL"
    m["Each row is: TRIGGER -> COMBO, with a MODE. When you press the trigger"] := "Minden sor: INDÍTÓ -> KOMBÓ, egy MÓDDAL. Amikor megnyomod az indítót"
    m["(keyboard key, mouse button, or controller button), the remapper sends the"] := "(billentyű, egérgomb vagy kontrollergomb), a remapper elküldi a"
    m["combo to the game. It only reacts while the Target EXE window is in front"] := "kombót a játéknak. Csak akkor reagál, ha a Célprogram ablaka van elöl"
    m["(leave Target EXE on `"(any)`" to react everywhere)."] := "(hagyd a Célprogramot `"(any)`"-n, hogy mindenhol reagáljon)."
    m["TRIGGERS"] := "INDÍTÓK"
    m["  Keyboard / mouse    F1, q, XButton1, WheelUp ... any AutoHotkey key name"] := "  Billentyű / egér    F1, q, XButton1, WheelUp ... bármely AutoHotkey billentyűnév"
    m["  DualShock 4 (J)     J1 Square, J2 Cross, J3 Circle, J4 Triangle,"] := "  DualShock 4 (J)     J1 Négyzet, J2 Kereszt, J3 Kör, J4 Háromszög,"
    m["                      (numbers can differ - use the Auto recorder to be sure)"] := "                      (a számok eltérhetnek - az Auto felvevővel győződj meg róla)"
    m["  D-pad               JPOVU  JPOVD  JPOVL  JPOVR"] := "  Iránygomb           JPOVU  JPOVD  JPOVL  JPOVR"
    m["  Stick directions    JLSU JLSD JLSL JLSR (left)  JRSU JRSD JRSL JRSR (right)"] := "  Kar irányok         JLSU JLSD JLSL JLSR (bal)  JRSU JRSD JRSL JRSR (jobb)"
    m["  Xbox pad (X)        XA XB XX XY XLB XRB XLT XRT XSTART XBACK XLS XRS"] := "  Xbox kontroller (X) XA XB XX XY XLB XRB XLT XRT XSTART XBACK XLS XRS"
    m["                      XUP XDOWN XLEFT XRIGHT, sticks XLSU.. and XRSU.."] := "                      XUP XDOWN XLEFT XRIGHT, karok XLSU.. és XRSU.."
    m["  Chords              J5+J6   XLB+XRB   (all buttons held together)"] := "  Együttes            J5+J6   XLB+XRB   (minden gomb együtt nyomva)"
    m["MODES"] := "MÓDOK"
    m["  Hold      Sends the keys while the trigger is held, releases on release."] := "  Hold      A billentyűket küldi, amíg az indítót nyomva tartod; elengedéskor elengedi."
    m["  Toggle    Press once to hold the keys down, press again to let go (auto-hold)."] := "  Toggle    Egyszer nyomd meg a billentyűk lenyomva tartásához, újra a feloldáshoz."
    m["  Press     One quick press of the combo each time."] := "  Press     Minden alkalommal a kombó egy gyors lenyomása."
    m["  Turbo     Repeats the combo quickly while held (right-click row: interval)."] := "  Turbo     Gyorsan ismétli a kombót, amíg nyomva tartod (sor jobb klikk: időköz)."
    m["  TapHold   A quick tap sends the FIRST key, holding sends the SECOND key."] := "  TapHold   Gyors koppintás az ELSŐ billentyűt, tartás a MÁSODIKAT küldi."
    m["  DblTap    Two quick presses (within 0.35 s) send the combo."] := "  DblTap    Két gyors lenyomás (0,35 mp-en belül) elküldi a kombót."
    m["  TglTurbo  Press once: the combo repeats by itself. Press again: it stops."] := "  TglTurbo  Egyszer megnyomod: a kombó magától ismétlődik. Újra: leáll."
    m["            (right-click row: interval)"] := "            (sor jobb klikk: időköz)"
    m["COMBO WORDS (separate with commas)"] := "KOMBÓ-SZAVAK (vesszővel válaszd el)"
    m["  w, shift, space, f5     keys by name"] := "  w, shift, space, f5     billentyűk név szerint"
    m["  d150  or  150           wait 150 milliseconds (a single digit is a real key)"] := "  d150  vagy  150         várj 150 ezredmásodpercet (egyetlen számjegy valódi billentyű)"
    m["  mlc mrc mmc             left / right / middle click"] := "  mlc mrc mmc             bal / jobb / középső kattintás"
    m["  mdc                     double click (left button)"] := "  mdc                     dupla kattintás (bal gomb)"
    m["  mdown  mup              hold / release the left button"] := "  mdown  mup              a bal gomb lenyomva tartása / elengedése"
    m["  mwd5   mwu5             scroll down / up 5 notches"] := "  mwd5   mwu5             görgetés le / fel 5 fokozatot"
    m["  m10,-5                  move the mouse 10 right, 5 up (relative)"] := "  m10,-5                  egér mozgatása 10-et jobbra, 5-öt fel (relatív)"
    m["  mx400,300               move the mouse to screen position 400,300"] := "  mx400,300               egér mozgatása a 400,300 képernyőpozícióra"
    m["  mm200,0,500             smooth move: 200 px right over 500 ms"] := "  mm200,0,500             sima mozgatás: 200 px jobbra 500 ms alatt"
    m["  mshake12,600            camera shake up to 12 px for 600 ms"] := "  mshake12,600            kamerarázás legfeljebb 12 px-lel 600 ms-ig"
    m["  mwave0,30,600,15        waggle up/down 30 px every 15 ms for 600 ms"] := "  mwave0,30,600,15        le-fel rázás 30 px-lel 15 ms-onként 600 ms-ig"
    m["  down:q  up:q           hold a key (or lbutton) across steps, then let go"] := "  down:q  up:q           billentyű (vagy lbutton) tartása több lépésen át, majd elengedés"
    m["                         e.g.  down:q,d40,mlc,d40,up:q"] := "                         pl.  down:q,d40,mlc,d40,up:q"
    m["  burst:x,30,40           press x 30 times, 40 ms apart (one-key button mash)"] := "  burst:x,30,40           x lenyomása 30-szor, 40 ms-onként (egygombos gombnyomkodás)"
    m["  alt:x/c,30,40           alternate x and c 30 times (left/right mash)"] := "  alt:x/c,30,40           x és c váltogatása 30-szor (bal/jobb nyomkodás)"
    m["  hold:x,800              hold x for 800 ms, then let go"] := "  hold:x,800              x tartása 800 ms-ig, majd elengedés"
    m["                          (burst, alt and hold work in Press, Turbo, TglTurbo, DblTap)"] := "                          (a burst, alt és hold a Press, Turbo, TglTurbo, DblTap módokban működik)"
    m["  mh300,0                 steady move 300 px/s while a Hold row is held or a"] := "  mh300,0                 egyenletes mozgatás 300 px/mp-cel, amíg egy Hold sor nyomva van vagy egy"
    m["                          Toggle row is on"] := "                          Toggle sor be van kapcsolva"
    m["COMBO RECIPES (copy into the combo box)"] := "KOMBÓ-RECEPTEK (másold a kombó mezőbe)"
    m["  Shift + Space together      down:lshift,d30,space,d40,up:lshift"] := "  Shift + Space együtt        down:lshift,d30,space,d40,up:lshift"
    m["  Hold a key for half a second down:e,d500,up:e"] := "  Billentyű fél másodpercig   down:e,d500,up:e"
    m["  Tap a key three times       e,d60,e,d60,e"] := "  Billentyű háromszori nyomás e,d60,e,d60,e"
    m["  Double click                mdc      (or  mlc,d80,mlc )"] := "  Dupla kattintás             mdc      (vagy  mlc,d80,mlc )"
    m["  Hold right click 1 second   down:rbutton,d1000,up:rbutton"] := "  Jobb gomb tartása 1 mp-ig   down:rbutton,d1000,up:rbutton"
    m["  Hold middle button          down:mbutton,d500,up:mbutton"] := "  Középső gomb tartása        down:mbutton,d500,up:mbutton"
    m["  Ctrl + scroll (zoom)        down:lctrl,mwd1,up:lctrl"] := "  Ctrl + görgetés (nagyítás)  down:lctrl,mwd1,up:lctrl"
    m["  Scroll then click           mwd3,d50,mlc"] := "  Görgetés, majd kattintás    mwd3,d50,mlc"
    m["  Walk forward, then turn     down:w,d1000,down:a,d200,up:a,up:w"] := "  Előre séta, majd fordulás   down:w,d1000,down:a,d200,up:a,up:w"
    m["  Drag with the mouse         mx400,300,mdown,d50,mm200,0,500,mup"] := "  Húzás az egérrel            mx400,300,mdown,d50,mm200,0,500,mup"
    m["  Hold a key + wiggle mouse   down:lctrl,mwave0,30,600,15"] := "  Billentyű + egérrázás       down:lctrl,mwave0,30,600,15"
    m["  Hold a key + wheel          down:q,mwd2,d40,mwu2,d40"] := "  Billentyű + görgő           down:q,mwd2,d40,mwu2,d40"
    m["  Auto-click (set the row to TglTurbo, interval 20)     mlc"] := "  Automata kattintás (TglTurbo mód, időköz 20)          mlc"
    m["  Auto-mash a key (TglTurbo, interval 20)               e"] := "  Automata billentyű-nyomkodás (TglTurbo, időköz 20)    e"
    m["  Walk forever (Toggle)       w"] := "  Folyamatos séta (Toggle)    w"
    m["  Tap = one key, hold = another (TapHold)               e,q"] := "  Koppintás = egy billentyű, tartás = másik (TapHold)   e,q"
    m["  Double-tap to sprint (DblTap)                         lshift"] := "  Dupla koppintás = sprint (DblTap)                     lshift"
    m["SETTINGS (tray icon > Settings)"] := "BEÁLLÍTÁSOK (tálcaikon > Beállítások)"
    m["  Input mode              Game / Classic / Hybrid. If a game ignores the keys,"] := "  Bemeneti mód            Game / Classic / Hybrid. Ha egy játék figyelmen kívül hagyja a billentyűket,"
    m["                          try another mode (also in the tray menu: More -> Input mode)."] := "                          próbálj másik módot (a tálcamenüben is: Továbbiak -> Bemeneti mód)."
    m["  Extra press time        Adds milliseconds to every key press. Helps with"] := "  Extra nyomvatartás      Ezredmásodperceket ad minden billentyűnyomáshoz. Segít az"
    m["                          timed prompts and games that miss short taps."] := "                          időzített felszólításoknál és a rövid koppintásokat kihagyó játékoknál."
    m["  Controller type         Auto, Xbox (XInput) or PS4 (DirectInput)."] := "  Kontroller típusa       Auto, Xbox (XInput) vagy PS4 (DirectInput)."
    m["  Mouse stick / Scroll    A stick moves the mouse or scrolls the wheel."] := "  Egér kar / Görgetés     Egy kar mozgatja az egeret vagy görgeti a kereket."
    m["  Speed, Deadzone, Curve  Tune the stick. A higher curve = finer control"] := "  Sebesség, Holtzóna, Görbe  A kar hangolása. Magasabb görbe = finomabb vezérlés"
    m["                          near the centre."] := "                          a középpont közelében."
    m["  Mouse speed %           Scales m / mm / mshake / mh moves."] := "  Egérsebesség %          Skálázza az m / mm / mshake / mh mozgásokat."
    m["  Run as Administrator    Needed when the game runs as admin. Restart to apply."] := "  Futtatás rendszergazdaként  Akkor kell, ha a játék rendszergazdaként fut. Újraindítás szükséges."
    m["  Auto-switch profile     Changes profile by itself when you switch to a game"] := "  Profil auto-váltás      Magától profilt vált, amikor átváltasz egy játékra,"
    m["                          whose profile has that Target EXE."] := "                          amelynek profiljában az a Célprogram szerepel."
    m["TRAY MENU (right-click the tray icon; double-click shows or hides the window)"] := "TÁLCAMENÜ (jobb klikk a tálcaikonon; dupla klikk megjeleníti vagy elrejti az ablakot)"
    m["  Every day: Show / hide window, Remapper on / off, Switch profile, Key cheat sheet, Pages."] := "  Mindennapi: Ablak megjelenítése / elrejtése, Remapper be / ki, Profil váltása, Billentyű-puska, Lapok."
    m["  Setup: Setup wizard, Settings, Accessibility tools."] := "  Beállítás: Beállítási varázsló, Beállítások, Akadálymentesítő eszközök."
    m["  More (the rest):"] := "  Továbbiak (a többi):"
    m["    Status box on / off, Keyboard mouse on / off, One-button control menu,"] := "    Állapotdoboz be / ki, Billentyűzetes egér be / ki, Egygombos vezérlés menü,"
    m["    Customize look (status box and cheat sheet), Check combos (finds typos),"] := "    Megjelenés testreszabása (állapotdoboz és puska), Kombók ellenőrzése (elírásokat keres),"
    m["    Auto-switch profile by game, Create starter profile, Input mode,"] := "    Profil automatikus váltása játék szerint, Kezdő profil létrehozása, Bemeneti mód,"
    m["    Controller (support, type, test), Copy diagnostics, Open log file."] := "    Kontroller (támogatás, típus, teszt), Diagnosztika másolása, Naplófájl megnyitása."
    m["PANIC"] := "VÉSZLEÁLLÍTÁS"
    m["  Keyboard: the panic key (default F8) turns the remapper off or on."] := "  Billentyűzet: a vészleállító billentyű (alapból F8) ki- vagy bekapcsolja a remappert."
    m["  Controller: hold Start+Back (Xbox) or Share+Options (PS4) for 1 second"] := "  Kontroller: tartsd nyomva a Start+Back (Xbox) vagy Share+Options (PS4) gombokat 1 másodpercig"
    m["  to turn it off - hold it again to turn it back on. You can set your own"] := "  a kikapcsoláshoz - tartsd újra a visszakapcsoláshoz. Saját gombokat"
    m["  buttons in Settings (On/Off buttons). Held keys are always released."] := "  is beállíthatsz a Beállításokban (Be/Ki gombok). A lenyomott billentyűk mindig elengedődnek."
    m["SETUP WIZARD (tray menu -> Setup wizard...)"] := "BEÁLLÍTÁSI VARÁZSLÓ (tálcamenü -> Beállítási varázsló...)"
    m["  Builds a ready profile: pick your hand (left, right, either), the game, and what"] := "  Kész profilt készít: válaszd ki a kezed (bal, jobb, bármelyik), a játékot, és hogy mit"
    m["  you want one key to do. It picks keys within reach of that hand and avoids the"] := "  csináljon egy billentyű. Olyan billentyűket választ, amelyeket a kezed elér, és kerüli"
    m["  keys the game uses. It is offered at start until you press Don't ask again."] := "  a játék billentyűit. Indításkor felajánlja, amíg a Ne kérdezd többé gombot meg nem nyomod."
    m["QUICK TIME EVENTS (timed button prompts)"] := "GYORS ESEMÉNYEK - QTE (időzített gombfelszólítások)"
    m["  Set the row mode to Press, then pick a combo:"] := "  Állítsd a sor módját Press-re, majd válassz kombót:"
    m["  Mash prompt, one burst      burst:x,30,40    (30 presses of x, 40 ms apart, about 1.2 s)"] := "  Nyomkodós felszólítás, egy sorozat  burst:x,30,40    (30 lenyomás x-szel, 40 ms-onként, kb. 1,2 mp)"
    m["  Left/right mash prompt      alt:x/c,30,40    (alternates x and c)"] := "  Bal/jobb nyomkodós          alt:x/c,30,40    (x és c váltogatása)"
    m["  Hold the button prompt      hold:x,1000      (holds x for 1 second)"] := "  Tartós gomb felszólítás     hold:x,1000      (x tartása 1 másodpercig)"
    m["  Mash for as long as needed  mode TglTurbo, combo x   (press once to start, again to stop)"] := "  Nyomkodás, amíg kell        mód TglTurbo, kombó x   (egyszer indít, újra megállít)"
    m["  Mash while you hold the key mode Turbo, combo x"] := "  Nyomkodás, amíg tartod      mód Turbo, kombó x"
    m["  The panic key stops a burst at once. A wrong button can end some mini-games, so"] := "  A vészleállító billentyű azonnal megállít egy sorozatot. A rossz gomb egyes minijátékokat befejezhet, ezért"
    m["  use one key per button and press only the one the prompt shows."] := "  gombonként egy billentyűt használj, és csak azt nyomd meg, amelyiket a felszólítás mutatja."
    m["STATUS BOX NAMES"] := "ÁLLAPOTDOBOZ NEVEK"
    m["  When a row fires, the status box shows the row's note (right-click a row"] := "  Amikor egy sor lefut, az állapotdoboz a sor megjegyzését mutatja (jobb klikk egy soron"
    m["  -> Edit Row Note...) and ON or OFF for toggles. Switch it off or change how long"] := "  -> Sor megjegyzésének szerkesztése...), kapcsolóknál BE vagy KI felirattal. Kikapcsolhatod, vagy"
    m["  it shows in Settings -> Customize..."] := "  megváltoztathatod, mennyi ideig látszik: Beállítások -> Testreszabás..."
    m["EDITING IN THE GAME"] := "SZERKESZTÉS JÁTÉK KÖZBEN"
    m["  Press the window key (default F12) to bring this window in front of the game, and"] := "  Nyomd meg az ablak-billentyűt (alapból F12), hogy ez az ablak a játék elé kerüljön, és"
    m["  again to hide it and return to the game. The tray icon (double-click) does the same."] := "  újra, hogy elrejtsd és visszatérj a játékhoz. A tálcaikon (dupla klikk) ugyanezt teszi."
    m["  While this window is in front the row keys are switched off, so you can type in the"] := "  Amíg ez az ablak elöl van, a sorok billentyűi ki vannak kapcsolva, így biztonságosan"
    m["  boxes safely. The game must be in windowed or borderless mode to show a window over it."] := "  gépelhetsz a mezőkbe. A játéknak ablakos vagy keret nélküli módban kell futnia."
    m["ACCESSIBILITY TOOLS (Settings -> Accessibility tools...)"] := "AKADÁLYMENTESÍTŐ ESZKÖZÖK (Beállítások -> Akadálymentesítő eszközök...)"
    m["  Tremor filter: ignores a repeat press that comes too soon after the last one, and can"] := "  Remegésszűrő: figyelmen kívül hagyja a túl hamar jövő ismételt lenyomást, és kérheti,"
    m["  require a key to be held a moment before it counts. Both are off at 0."] := "  hogy a billentyűt egy pillanatig tartsd nyomva, mielőtt számítana. Mindkettő 0-nál ki van kapcsolva."
    m["  Keyboard mouse: keys move the cursor and click, for when the mouse is hard to use."] := "  Billentyűzetes egér: billentyűk mozgatják a kurzort és kattintanak, ha az egér nehezen használható."
    m["  Turn it on and off with its own key or the tray menu. Default keys: E S D F move,"] := "  Saját billentyűvel vagy a tálcamenüből kapcsolható. Alap billentyűk: E S D F mozgat,"
    m["  Q W R click, T and G scroll. It speeds up while a key is held. The panic key turns it off."] := "  Q W R kattint, T és G görget. Gyorsul, amíg nyomva tartod. A vészleállító billentyű kikapcsolja."
    m["  One-button control: one key opens a list of this profile's actions and steps through"] := "  Egygombos vezérlés: egy billentyű megnyit egy listát a profil műveleteiről, és végiglépked"
    m["  them. Automatic: the highlight moves by itself and your key chooses. Step: tap = next,"] := "  rajtuk. Automatikus: a kijelölés magától mozog, a billentyűd választ. Léptetős: koppintás = következő,"
    m["  hold = choose. Works best with Press, Toggle and TglTurbo rows."] := "  tartás = választás. A Press, Toggle és TglTurbo soroknál működik a legjobban."
    m["  Row notes: right-click a row -> Edit Row Note... The note shows in the cheat sheet and"] := "  Sor-megjegyzések: jobb klikk egy soron -> Sor megjegyzésének szerkesztése... A megjegyzés látszik a puskán és"
    m["  in one-button control. Press Apply to save it."] := "  az egygombos vezérlésben. Mentéshez nyomd meg az Alkalmaz gombot."
    m["SAFETY AND DIAGNOSTICS"] := "BIZTONSÁG ÉS DIAGNOSZTIKA"
    m["  Held keys, toggles and auto-repeats are let go when the game loses focus"] := "  A lenyomott billentyűk, kapcsolók és automatikus ismétlések elengedődnek, ha a játék elveszíti a fókuszt"
    m["  (Advanced Settings -> turn off if you do not want this)."] := "  (Haladó beállítások -> kapcsold ki, ha nem kéred)."
    m["  Something wrong? Tray menu -> More -> Copy diagnostics, then paste it in the chat."] := "  Valami nem jó? Tálcamenü -> Továbbiak -> Diagnosztika másolása, majd illeszd be a csevegésbe."
    m["  Tray menu -> More -> Open log file shows combo_remapper.log (errors, releases, what fired)."] := "  Tálcamenü -> Továbbiak -> Naplófájl megnyitása: a combo_remapper.log-ot mutatja (hibák, elengedések, mi futott le)."
    m["  The log file also records what fired. Advanced Settings -> System -> Write a log"] := "  A naplófájl azt is rögzíti, mi futott le. Haladó beállítások -> Rendszer -> Naplófájl írása"
    m["  file switches it on or off."] := "  ki- vagy bekapcsolja."
    m["AUTO AND SET BUTTONS"] := "AUTO ÉS SET GOMBOK"
    m["  Set (next to a trigger box): press it, then press the key or mouse button you"] := "  Set (az indító mező mellett): nyomd meg, majd nyomd meg azt a billentyűt vagy egérgombot,"
    m["  want as the trigger. Esc cancels. Auto (next to the combo box) records the"] := "  amelyet indítónak szeretnél. Esc megszakítja. Az Auto (a kombó mező mellett) felveszi"
    m["  keys you press into the combo. Both listen for the time set in Advanced"] := "  a megnyomott billentyűket a kombóba. Mindkettő a Haladó beállításokban megadott ideig figyel:"
    m["  Settings -> Auto-detect (sec); the default is 10 seconds, up to 120."] := "  Haladó beállítások -> Automatikus érzékelés (mp); alapból 10 másodperc, legfeljebb 120."
    m["PAGES AND CHEAT SHEET (Settings -> Pages and cheat sheet)"] := "LAPOK ÉS PUSKA (Beállítások -> Lapok és puska)"
    m["  Cheat-sheet key: shows every key of this profile - and of all its pages - on the"] := "  Puska-billentyű: megmutatja a profil összes billentyűjét - és az összes lapét - a"
    m["  screen. Press it again to also see the exact combos, a third time to close."] := "  képernyőn. Nyomd meg újra a pontos kombókhoz, harmadszor a bezáráshoz."
    m["  Long lists are split into columns so everything fits."] := "  A hosszú listák oszlopokra oszlanak, hogy minden elférjen."
    m["  Pages: each page is a profile. Make one with New profile for every page you"] := "  Lapok: minden lap egy profil. Hozz létre egy Új profilt minden laphoz, amit"
    m["  want, then in Settings use 'Add a page' to put them in order. The Next-page"] := "  szeretnél, majd a Beállításokban a 'Lap hozzáadása' gombbal tedd őket sorrendbe. A Következő-lap"
    m["  key moves forward (after the last page it goes back to the first). The"] := "  billentyű előre lép (az utolsó lap után az elsőre ugrik). Az"
    m["  Previous-page key moves back. Held keys are let go on every switch."] := "  Előző-lap billentyű visszalép. A lenyomott billentyűk minden váltáskor elengedődnek."
    m["  The status box and cheat sheet show 'Page 2 of 4'."] := "  Az állapotdoboz és a puska mutatja: '2. lap a 4-ből'."
    m["  Tap/Hold and Dbl-tap modes give two or three actions on one key."] := "  A Tap/Hold és Dbl-tap módok két-három műveletet adnak egy billentyűre."
    m["TIPS"] := "TIPPEK"
    m["  * Right-click a row for tools: Test Fire, Turbo interval, insert mouse"] := "  * Jobb klikk egy soron: eszközök - Teszt-indítás, Turbo időköz, egérműveletek beszúrása,"
    m["    actions, duplicate, clear."] := "    többszörözés, törlés."
    m["  * Hover over a setting in the Settings window for a short explanation."] := "  * Vidd az egeret egy beállítás fölé a Beállítások ablakban egy rövid magyarázatért."
    m["  * Export Profile copies a profile to the clipboard; Import brings it back,"] := "  * Profil exportálása a vágólapra másolja a profilt; az Importálás visszahozza,"
    m["    including input mode, controller and mouse settings."] := "    a bemeneti móddal, kontrollerrel és egérbeállításokkal együtt."
    m["Combo ReMapper - Help"] := "Combo ReMapper - Súgó"
    m["Starter profile ready: "] := "Kezdő profil kész: "
    m["  (target: "] := "  (cél: "
    m[" - change it if your game shows another name)"] := " - változtasd meg, ha a játékod más nevet mutat)"
    m["  (set your Target EXE, then Apply)"] := "  (add meg a Célprogramot, majd Alkalmaz)"
    m["Remapper Settings Panel"] := "Remapper beállítások"
    m["Startup, display and input"] := "Indítás, megjelenítés és bevitel"
    m["Auto-Start with Windows Startup"] := "Automatikus indítás a Windows indulásakor"
    m["Enable Audio Beep Alerts"] := "Hangjelzések bekapcsolása"
    m["Enable Overlay ToolTips"] := "Lebegő tippek bekapcsolása"
    m["Enable On-Screen Overlay (OSD)"] := "Képernyőn megjelenő jelző (OSD) bekapcsolása"
    m["Lock OSD Position (Click-Through)"] := "OSD helyének rögzítése (átkattintható)"
    m["OSD Toggle Key:"] := "OSD billentyű:"
    m["Input mode:"] := "Bemeneti mód:"
    m["Auto-switch profile by game window"] := "Profil automatikus váltása játékablak szerint"
    m["Enable Gamepad / Controller Support"] := "Kontroller-támogatás bekapcsolása"
    m["Mouse hotkeys (tick Off to disable)"] := "Egér gyorsbillentyűk (a Ki jelölővel kikapcsolhatók)"
    m["Off"] := "Ki"
    m["Y-Axis Lock key:"] := "Y tengely zár billentyű:"
    m["Pages and cheat sheet"] := "Lapok és puska"
    m["Next-page key:"] := "Következő-lap billentyű:"
    m["Previous-page key:"] := "Előző-lap billentyű:"
    m["Add a page:"] := "Lap hozzáadása:"
    m["Add"] := "Hozzáad"
    m["Pages, in order:"] := "Lapok sorrendben:"
    m["Remove selected"] := "Kijelölt eltávolítása"
    m["Cheat-sheet key:"] := "Puska-billentyű:"
    m["Done"] := "Kész"
    m["Controller settings"] := "Kontroller beállítások"
    m["Controller type:"] := "Kontroller típusa:"
    m["Mouse stick:"] := "Egér kar:"
    m["Speed px/s:"] := "Sebesség px/mp:"
    m["Scroll stick:"] := "Görgető kar:"
    m["Ticks/s:"] := "Lépés/mp:"
    m["Hold the on/off buttons for 1 second to switch the remapper off / on"] := "Tartsd nyomva a be/ki gombokat 1 másodpercig a remapper ki- / bekapcsolásához"
    m["On/Off buttons:"] := "Be/Ki gombok:"
    m["Pages..."] := "Lapok..."
    m["Controller..."] := "Kontroller..."
    m["Customize..."] := "Testreszabás..."
    m["Advanced..."] := "Haladó..."
    m["Save Settings"] := "Beállítások mentése"
    m["Advanced Settings"] := "Haladó beállítások"
    m["Engine timing (ms) and safety"] := "Időzítés (ms) és biztonság"
    m["Key Delay:"] := "Billentyű késleltetés:"
    m["Press Duration:"] := "Nyomás időtartama:"
    m["Mouse Delay:"] := "Egér késleltetés:"
    m["Extra press time:"] := "Extra nyomvatartás:"
    m["Auto-detect (sec):"] := "Automatikus érzékelés (mp):"
    m["Let go of everything when the game loses focus"] := "Mindent elenged, ha a játék elveszíti a fókuszt"
    m["Controller tuning"] := "Kontroller hangolás"
    m["Pad slot:"] := "Kontroller hely:"
    m["Trigger at:"] := "Indítás itt:"
    m["Deadzone %:"] := "Holtzóna %:"
    m["Curve:"] := "Görbe:"
    m["Mouse speed %:"] := "Egérsebesség %:"
    m["System"] := "Rendszer"
    m["Run as Administrator (applies after restart)"] := "Futtatás rendszergazdaként (újraindítás után lép életbe)"
    m["Write a log file (combo_remapper.log)"] := "Naplófájl írása (combo_remapper.log)"
    m["Custom RGB Theme Pickers (HEX)"] := "Egyéni RGB téma színek (HEX)"
    m["Window Background:"] := "Ablak háttere:"
    m["Control Background:"] := "Vezérlők háttere:"
    m["Text Color:"] := "Szöveg színe:"
    m["How keys and the mouse are sent. If a game ignores the keys, try another mode."] := "Hogyan küldi a program a billentyűket és az egeret. Ha egy játék figyelmen kívül hagyja a billentyűket, próbálj másik módot."
    m["Records errors, profile loads and safety releases in combo_remapper.log so problems can be found. Turn it off to write nothing to disk. Takes effect at once."] := "Rögzíti a hibákat, a profil-betöltéseket és a biztonsági elengedéseket a combo_remapper.log fájlban, hogy a problémák megtalálhatók legyenek. Kikapcsolva semmi sem íródik a lemezre. Azonnal életbe lép."
    m["Run as administrator. Needed when the game runs as admin. Applies after a restart."] := "Futtatás rendszergazdaként. Akkor kell, ha a játék rendszergazdaként fut. Újraindítás után lép életbe."
    m["Switches profile by itself when you open a game whose profile has that Target EXE."] := "Magától profilt vált, amikor megnyitsz egy játékot, amelynek profiljában az a Célprogram szerepel."
    m["When you switch away from the game (Alt+Tab, crash, minimize), every held key, toggle and auto-repeat is stopped so nothing gets stuck."] := "Amikor átváltasz a játékból (Alt+Tab, összeomlás, minimalizálás), minden lenyomott billentyű, kapcsoló és automatikus ismétlés leáll, hogy semmi ne ragadjon be."
    m["How many seconds the Auto, Set and Bind buttons wait for you to press keys (3 to 120). Make it longer if you need more time."] := "Hány másodpercig várnak az Auto, Set és Auto gomb (automata gomb választás) gombok a billentyűnyomásodra (3-tól 120-ig). Állítsd hosszabbra, ha több idő kell."
    m["Extra milliseconds added to every key press. Helps timed prompts and games that miss short taps."] := "Extra ezredmásodpercek minden billentyűnyomáshoz. Segít az időzített felszólításoknál és a rövid koppintásokat kihagyó játékoknál."
    m["Auto uses either pad. Xbox reads only Xbox-style pads. PS4 reads only DirectInput pads such as a DualShock."] := "Az Auto bármelyik kontrollert használja. Az Xbox csak Xbox-típusú kontrollereket olvas. A PS4 csak DirectInput kontrollereket, például DualShockot."
    m["Which Xbox controller slot to read. Auto picks the first one connected."] := "Melyik Xbox kontroller-helyet olvassa. Az Auto az első csatlakoztatottat választja."
    m["How far an Xbox trigger (LT/RT) must be pressed to count as a button, 0 to 255."] := "Mennyire kell lenyomni egy Xbox ravaszt (LT/RT), hogy gombnak számítson, 0-tól 255-ig."
    m["Lets a stick move the mouse."] := "Lehetővé teszi, hogy egy kar mozgassa az egeret."
    m["Mouse speed in pixels per second with the stick fully pushed."] := "Egérsebesség képpont/másodpercben, teljesen kitolt karnál."
    m["Percent of stick travel ignored around the centre, so a resting stick does not drift."] := "A kar útjának azon százaléka, amelyet a közép körül figyelmen kívül hagy, hogy a nyugvó kar ne sodródjon."
    m["1 = even response. Higher = finer control near the centre and fast at the edge."] := "1 = egyenletes válasz. Magasabb = finomabb vezérlés a középpont közelében és gyors a szélen."
    m["Lets a stick scroll the mouse wheel."] := "Lehetővé teszi, hogy egy kar görgesse az egér görgőjét."
    m["Scroll notches per second with the stick fully pushed."] := "Görgetési fokozat másodpercenként, teljesen kitolt karnál."
    m["Scales every mouse move token (m, mm, mshake, mh). 100 = normal."] := "Skálázza az összes egérmozgás-jelet (m, mm, mshake, mh). 100 = normál."
    m["Hold the on/off buttons for 1 second to turn the remapper off. Hold them again to turn it back on."] := "Tartsd nyomva a be/ki gombokat 1 másodpercig a remapper kikapcsolásához. Tartsd újra a visszakapcsoláshoz."
    m["Your own on/off buttons, joined with +, for example XLB+XRB+XSTART or J5+J6. Leave blank for the default: Start+Back (Xbox) / Share+Options (PS4)."] := "Saját be/ki gombjaid, + jellel összekötve, például XLB+XRB+XSTART vagy J5+J6. Hagyd üresen az alapértelmezéshez: Start+Back (Xbox) / Share+Options (PS4)."
    m["Click, hold the buttons you want together on the controller, then let go."] := "Kattints, tartsd nyomva a kontrolleren együtt kívánt gombokat, majd engedd el."
    m["Key that sends a mouse wheel scroll click. Press Bind and then the key you want."] := "A billentyű, amely egér görgő-kattintást küld. Nyomd meg az Auto gomb (automata gomb választás) gombot, majd a kívánt billentyűt."
    m["Tick to switch the scroll-click key off completely."] := "Jelöld be, hogy a görgő-kattintás billentyű teljesen ki legyen kapcsolva."
    m["Key that locks the mouse to its current height (Y axis). Press it again to unlock."] := "A billentyű, amely az egeret a jelenlegi magasságán zárolja (Y tengely). Nyomd meg újra a feloldáshoz."
    m["Key that moves to the next page (a profile). After the last page it goes back to the first. More pages = more actions on the same keys."] := "A billentyű, amely a következő lapra (profilra) lép. Az utolsó lap után az elsőre ugrik. Több lap = több művelet ugyanazokon a billentyűkön."
    m["Key that moves to the previous page. Optional."] := "A billentyű, amely az előző lapra lép. Nem kötelező."
    m["Pick a profile, then press Add. Make each page with New profile. The keys on a page replace the keys of the page before it."] := "Válassz egy profilt, majd nyomd meg a Hozzáad gombot. Minden lapot az Új profil gombbal készíts. Egy lap billentyűi felülírják az előző lap billentyűit."
    m["Key that shows or hides a list of every key in this profile on the screen."] := "A billentyű, amely megjeleníti vagy elrejti a profil összes billentyűjét a képernyőn."
    m["Tick to switch the Y-axis lock off completely."] := "Jelöld be, hogy az Y tengely zár teljesen ki legyen kapcsolva."
    m["Pause after each key event, in milliseconds."] := "Szünet minden billentyűesemény után, ezredmásodpercben."
    m["How long each key is held down for a press, in milliseconds."] := "Meddig tartja lenyomva a program a billentyűt egy nyomásnál, ezredmásodpercben."
    m["Pause after each mouse action, in milliseconds."] := "Szünet minden egérművelet után, ezredmásodpercben."
    m["Turns controller reading on or off."] := "Be- vagy kikapcsolja a kontroller olvasását."
    m["The Administrator setting applies the next time the remapper starts."] := "A rendszergazdai beállítás a remapper következő indításakor lép életbe."
    m["The Y-axis lock key ('"] := "Az Y-tengely zár billentyű ('"
    m["') is already used by another hotkey. Pick a different one."] := "') már használatban van másik gyorsbillentyűként. Válassz másikat."
    m["The next-page key ('"] := "A következő-lap billentyű ('"
    m["The previous-page key ('"] := "Az előző-lap billentyű ('"
    m["The cheat-sheet key ('"] := "A puska-billentyű ('"
    m["Settings successfully applied!"] := "Beállítások sikeresen alkalmazva!"
    m["Test Fire This Combo Now"] := "Kombó tesztelése most"
    m["Set Turbo Interval (ms)..."] := "Turbo időköz beállítása (ms)..."
    m["Extend Combo (Append directly)"] := "Kombó bővítése (közvetlen hozzáfűzés)"
    m["Add Pause Delay (ms)"] := "Szünet beszúrása (ms)"
    m["Prepend Key (Prefix)"] := "Billentyű elé fűzése (előtag)"
    m["Append Key (Suffix)"] := "Billentyű hozzáfűzése (utótag)"
    m["Insert Mouse Move (Relative)"] := "Egérmozgatás beszúrása (relatív)"
    m["Insert Mouse Move (Absolute)"] := "Egérmozgatás beszúrása (abszolút)"
    m["Insert Mouse Click (Left/Right/Middle)"] := "Egérkattintás beszúrása (bal/jobb/középső)"
    m["Insert Smooth Mouse Move (over time)"] := "Sima egérmozgatás beszúrása (időben elosztva)"
    m["Insert Camera Shake"] := "Kamerarázás beszúrása"
    m["Insert Continuous Move (while held / toggled)"] := "Folyamatos mozgatás beszúrása (tartás / kapcsolás közben)"
    m["Edit Row Note..."] := "Sor megjegyzésének szerkesztése..."
    m["Duplicate Row"] := "Sor többszörözése"
    m["Clear Row Inputs"] := "Sor mezőinek törlése"
    m["Enter absolute X,Y coordinates (e.g. 400,300):"] := "Add meg az abszolút X,Y koordinátákat (pl. 400,300):"
    m["Enter relative dx,dy movement (e.g. 10,-5):"] := "Add meg a relatív dx,dy mozgást (pl. 10,-5):"
    m["Insert Mouse Move"] := "Egérmozgatás beszúrása"
    m["Invalid format. Use dx,dy (numbers only)."] := "Érvénytelen formátum. Használd: dx,dy (csak számok)."
    m["Inserted: "] := "Beszúrva: "
    m["Total dx,dy and duration in ms, separated by commas`n(e.g. 200,0,500 moves 200 px right over half a second):"] := "Teljes dx,dy és az időtartam ms-ban, vesszővel elválasztva`n(pl. 200,0,500 200 képpontot mozdít jobbra fél másodperc alatt):"
    m["Insert Smooth Mouse Move"] := "Sima egérmozgatás beszúrása"
    m["Invalid format. Use dx,dy,ms (e.g. 200,0,500)."] := "Érvénytelen formátum. Használd: dx,dy,ms (pl. 200,0,500)."
    m["Shake strength in pixels and duration in ms`n(e.g. 12,600 = jitter up to 12 px for 0.6 s):"] := "A rázás erőssége képpontban és az időtartam ms-ban`n(pl. 12,600 = legfeljebb 12 képpontos rezgés 0,6 másodpercig):"
    m["Invalid format. Use strength,ms (e.g. 12,600)."] := "Érvénytelen formátum. Használd: erősség,ms (pl. 12,600)."
    m["Speed vx,vy in pixels per second, while the trigger is held (Hold rows) or on (Toggle rows)`n(e.g. 300,0 = steady turn right; negative = left/up):"] := "Sebesség vx,vy képpont/másodpercben, amíg az indító nyomva van (Hold sorok) vagy be van kapcsolva (Toggle sorok)`n(pl. 300,0 = egyenletes fordulás jobbra; negatív = balra/fel):"
    m["Insert Continuous Move"] := "Folyamatos mozgatás beszúrása"
    m["Invalid format. Use vx,vy (e.g. 300,0)."] := "Érvénytelen formátum. Használd: vx,vy (pl. 300,0)."
    m["Enter click type (L = left, R = right, M = middle):"] := "Add meg a kattintás típusát (L = bal, R = jobb, M = középső):"
    m["Insert Mouse Click"] := "Egérkattintás beszúrása"
    m["Invalid choice. Use L, R, or M."] := "Érvénytelen választás. Használd: L, R vagy M."
    m["Nothing to test - combo is empty"] := "Nincs mit tesztelni - a kombó üres"
    m["Test firing combo..."] := "Kombó tesztelése..."
    m["Turbo repeat interval in milliseconds (lower = faster):"] := "Turbo ismétlési időköz ezredmásodpercben (alacsonyabb = gyorsabb):"
    m["Turbo Interval"] := "Turbo időköz"
    m["Turbo interval set to "] := "Turbo időköz beállítva: "
    m["Enter pause delay in milliseconds (e.g. 150):"] := "Add meg a szünet hosszát ezredmásodpercben (pl. 150):"
    m["Add Sequence Delay"] := "Szünet beszúrása a sorozatba"
    m["Enter key sequence to append directly (e.g. shift,w):"] := "Add meg a közvetlenül hozzáfűzendő billentyűsorozatot (pl. shift,w):"
    m["Extend Combo"] := "Kombó bővítése"
    m["Enter key(s) to PREPEND (e.g. shift, ctrl):"] := "Add meg az ELÉ fűzendő billentyű(ke)t (pl. shift, ctrl):"
    m["Prepend Key"] := "Billentyű elé fűzése"
    m["Enter key(s) to APPEND (e.g. enter, space):"] := "Add meg a HOZZÁFŰZENDŐ billentyű(ke)t (pl. enter, space):"
    m["Append Key"] := "Billentyű hozzáfűzése"
    m["New Profile"] := "Új profil"
    m["Enter name for new profile:"] := "Add meg az új profil nevét:"
    m["The 'default' profile cannot be deleted."] := "A 'default' profil nem törölhető."
    m["Delete Profile"] := "Profil törlése"
    m["Are you sure you want to delete profile '"] := "Biztosan törölni szeretnéd ezt a profilt: '"
    m["Showing rows "] := "Megjelenített sorok: "
    m[" of "] := " / "
    m["(no combos yet - click + Add Combo below)"] := "(még nincs kombó - kattints lent a + Kombó hozzáadása gombra)"
    m["Showing all "] := "Mind látható: "
    m[" rows"] := " sor"
    m["ACTIVE"] := "AKTÍV"
    m["ScrollKey: "] := "Görgő-billentyű: "
    m["Scroll: OFF"] := "Görgetés: KI"
    m["Target: "] := "Cél: "
    m["Target: (any)"] := "Cél: (bármelyik)"
    m["Pad: ON"] := "Kontroller: BE"
    m["Pad: OFF"] := "Kontroller: KI"
    m["Status: "] := "Állapot: "
    m[" | Panic: "] := " | Vészleállító: "
    m["The panic toggle key cannot be blank. This is required for safety."] := "A vészleállító billentyű nem lehet üres. Ez a biztonság miatt kötelező."
    m["' is reserved for the panic toggle and can't be a trigger key. Nothing was saved."] := "' a vészleállítónak van fenntartva, és nem lehet indító billentyű. Semmi sem lett mentve."
    m["' is used as a trigger key on more than one row. Please make each trigger key unique."] := "' több sorban is indító billentyűként szerepel. Kérlek, minden indító billentyű egyedi legyen."
    m["The scroll-click key can't be the panic toggle. Nothing was saved."] := "A görgő-kattintás billentyű nem lehet a vészleállító. Semmi sem lett mentve."
    m["The scroll-click key ('"] := "A görgő-kattintás billentyű ('"
    m["') is the same as one of your row trigger keys. Pick a different one."] := "') megegyezik valamelyik sor indító billentyűjével. Válassz másikat."
    m["Combos updated and saved"] := "Kombók frissítve és mentve"
    m["Failed to bind the next-page key: "] := "Nem sikerült lekötni a következő-lap billentyűt: "
    m["Failed to bind the previous-page key: "] := "Nem sikerült lekötni az előző-lap billentyűt: "
    m["Failed to bind the cheat-sheet key: "] := "Nem sikerült lekötni a puska-billentyűt: "
    m["No other pages are set. Open Settings and add pages."] := "Nincs más lap beállítva. Nyisd meg a Beállításokat, és adj hozzá lapokat."
    m["Page profile '"] := "Lap-profil '"
    m["' was not found."] := "' nem található."
    m["PAGE "] := "LAP "
    m["Page "] := "Lap "
    m["That is this profile - pick a different one for the other pages."] := "Ez ez a profil - válassz másikat a többi laphoz."
    m["            sends: "] := "            küldi: "
    m["(no keys set)"] := "(nincs beállított billentyű)"
    m["Works in:  "] := "Működik itt:  "
    m["any window"] := "bármely ablak"
    m["Next page: "] := "Következő lap: "
    m["Back page: "] := "Előző lap: "
    m["   <-- you are here"] := "   <-- itt vagy"
    m["KEY"] := "GOMB"
    m["HOW"] := "MÓD"
    m["KEYS FOR:  "] := "BILLENTYŰK ITT:  "
    m["ALWAYS"] := "MINDIG"
    m["Show / hide the remapper window"] := "A remapper ablak megjelenítése / elrejtése"
    m["Keyboard mouse on/off"] := "Billentyűzetes egér be/ki"
    m["One-button control"] := "Egygombos vezérlés"
    m["Master on/off (panic)"] := "Fő be/ki kapcsoló (vészleállító)"
    m["Show/hide the status box"] := "Az állapotdoboz megjelenítése/elrejtése"
    m["Lock the mouse height"] := "Az egér magasságának zárolása"
    m["Scroll click"] := "Görgő-kattintás"
    m["Close this sheet"] := "A puska bezárása"
    m["Press again for details, then again to close"] := "Nyomd újra a részletekért, majd még egyszer a bezáráshoz"
    m["Diagnostics copied - paste them into the chat"] := "Diagnosztika másolva - illeszd be a csevegésbe"
    m["No log file yet - nothing has gone wrong."] := "Még nincs naplófájl - nem történt hiba."
    m["Customize"] := "Testreszabás"
    m["Status box (the little ACTIVE / DISABLED box)"] := "Állapotdoboz (a kis AKTÍV / KIKAPCSOLVA doboz)"
    m["Text size (8 - 28):"] := "Szövegméret (8 - 28):"
    m["See-through (30 - 100 %):"] := "Átlátszóság (30 - 100 %):"
    m["Background color (hex):"] := "Háttérszín (hex):"
    m["Show the row's name in the status box when it fires"] := "Az állapotdobozban mutassa a sor nevét, amikor lefut"
    m["Show the name for (ms):"] := "A név megjelenítési ideje (ms):"
    m["Text size (8 - 24):"] := "Szövegméret (8 - 24):"
    m["Stays up (seconds, 0 = until pressed):"] := "Látszik (másodperc, 0 = amíg meg nem nyomod):"
    m["Text color (hex):"] := "Szövegszín (hex):"
    m["Position:"] := "Hely:"
    m["Reset to default"] := "Alaphelyzet"
    m["Colors are 6 hex digits, for example 1E1E1E (dark gray) or FFFFFF (white). Apply shows the status box and the cheat sheet with the new look."] := "A színek 6 hexadecimális számjegyből állnak, például 1E1E1E (sötétszürke) vagy FFFFFF (fehér). Az Alkalmaz az állapotdobozt és a puskát az új megjelenéssel mutatja."
    m["Setup wizard"] := "Beállítási varázsló"
    m["This builds a profile for you. Answer a few questions, then press Create. You can change everything afterwards."] := "Ez egy profilt készít neked. Válaszolj néhány kérdésre, majd nyomd meg a Létrehozás gombot. Utána bármit megváltoztathatsz."
    m["1.  Which hand do you use?"] := "1.  Melyik kezedet használod?"
    m["Left hand only"] := "Csak bal kéz"
    m["Right hand only"] := "Csak jobb kéz"
    m["Either hand"] := "Bármelyik kéz"
    m["2.  Name for this profile (for example the game's name):"] := "2.  A profil neve (például a játék neve):"
    m["3.  Which program is the game? Pick it from the open programs, or type its name (leave empty = works in any window):"] := "3.  Melyik program a játék? Válaszd ki a megnyitott programok közül, vagy írd be a nevét (üresen = bármely ablakban működik):"
    m["4.  Keys the game already uses (the wizard will not take these):"] := "4.  A játék által már használt billentyűk (a varázsló ezeket nem veszi el):"
    m["5.  What should one key do for you? Tick everything you want:"] := "5.  Mit csináljon neked egy billentyű? Jelöld be, amit szeretnél:"
    m["Walk forward on its own (press again to stop).  Forward key:"] := "Magától előre sétál (újra megnyomva leáll).  Előre billentyű:"
    m["Click the left mouse button over and over (press again to stop)"] := "Újra és újra kattint a bal egérgombbal (újra megnyomva leáll)"
    m["Press a key over and over (press again to stop).  Key:"] := "Újra és újra megnyom egy billentyűt (újra megnyomva leáll).  Billentyű:"
    m["Hold Shift for me (press again to let go)"] := "Tartsa lenyomva a Shiftet helyettem (újra megnyomva elengedi)"
    m["Hold Ctrl for me (press again to let go)"] := "Tartsa lenyomva a Ctrlt helyettem (újra megnyomva elengedi)"
    m["Shift + Space together on one key (for a dodge or roll)"] := "Shift + Space együtt egy billentyűn (kitéréshez vagy guruláshoz)"
    m["Mash a button in one burst (for a button-mashing prompt).  Button:"] := "Egy gomb nyomkodása egy sorozatban (nyomkodós felszólításhoz).  Gomb:"
    m["Alternate two buttons fast (left/right mash).  Buttons:"] := "Két gomb gyors váltogatása (bal/jobb nyomkodás).  Gombok:"
    m["Hold a button for 1 second (for a hold prompt).  Button:"] := "Egy gomb tartása 1 másodpercig (tartós felszólításhoz).  Gomb:"
    m["Add a key that shows all the keys on the screen (F1)"] := "Billentyű hozzáadása, amely a képernyőn mutatja az összes billentyűt (F1)"
    m["What does everything do?"] := "Mit csinál minden?"
    m["Create profile"] := "Profil létrehozása"
    m["Cancel"] := "Mégse"
    m["Pick the hand you can use. The wizard picks keys that hand reaches easily. Left hand: F G X T B and the number keys. Right hand: J K L U I O H N M and the numpad."] := "Válaszd ki a kezet, amelyet használni tudsz. A varázsló olyan billentyűket választ, amelyeket az a kéz könnyen elér. Bal kéz: F G X T B és a számbillentyűk. Jobb kéz: J K L U I O H N M és a numerikus billentyűzet."
    m["The name of the new profile. It shows up in the profile list in the main window."] := "Az új profil neve. Megjelenik a főablak profillistájában."
    m["The game's program. Start the game first, then pick it from the list, or type its name (for example MyGame.exe). When it is set, the keys only work while that game is in front. Empty = works in any window."] := "A játék programja. Előbb indítsd el a játékot, majd válaszd ki a listából, vagy írd be a nevét (például MyGame.exe). Ha meg van adva, a billentyűk csak akkor működnek, amikor az a játék van elöl. Üresen = bármely ablakban működik."
    m["Keys the game already uses (moving, attacking...). The wizard never gives these to a helper, so your game keys keep working. Separate them with spaces."] := "A játék által már használt billentyűk (mozgás, támadás...). A varázsló ezeket soha nem adja egy segédnek, így a játék billentyűi tovább működnek. Szóközzel válaszd el őket."
    m["One key makes your character walk forward by itself. Press it again to stop."] := "Egy billentyű magától előre sétáltatja a karaktered. Újra megnyomva leáll."
    m["The key your game uses for moving forward (usually W)."] := "A billentyű, amelyet a játékod az előre mozgáshoz használ (általában W)."
    m["One key clicks the left mouse button over and over, fast. Press it again to stop."] := "Egy billentyű gyorsan, újra és újra kattint a bal egérgombbal. Újra megnyomva leáll."
    m["One key presses another key over and over, fast. Press it again to stop. Good for button-mashing parts."] := "Egy billentyű gyorsan, újra és újra megnyom egy másik billentyűt. Újra megnyomva leáll. Jó a gombnyomkodós részekhez."
    m["The key to be pressed over and over."] := "A billentyű, amelyet újra és újra meg kell nyomni."
    m["One key holds Shift down for you (sprint, lock-on, and so on). Press it again to let go."] := "Egy billentyű lenyomva tartja helyetted a Shiftet (sprint, célbavétel stb.). Újra megnyomva elengedi."
    m["One key holds Ctrl down for you. Press it again to let go."] := "Egy billentyű lenyomva tartja helyetted a Ctrlt. Újra megnyomva elengedi."
    m["One key presses Shift and Space together, so you do not need two fingers for a dodge or roll."] := "Egy billentyű egyszerre nyomja le a Shiftet és a Space-t, így nincs szükséged két ujjra a kitéréshez vagy a guruláshoz."
    m["One key presses a button about 30 times in a row, quickly, then stops by itself. Made for quick time events that ask you to mash."] := "Egy billentyű gyorsan, egymás után kb. 30-szor megnyom egy gombot, majd magától leáll. Gyors eseményekhez (QTE), amelyek nyomkodást kérnek."
    m["The game button to mash (the key your game uses for it)."] := "A nyomkodandó játékgomb (a billentyű, amelyet a játékod használ hozzá)."
    m["One key presses two buttons one after the other, again and again, for prompts that ask you to alternate left and right."] := "Egy billentyű felváltva, újra és újra megnyom két gombot, olyan felszólításokhoz, amelyek bal-jobb váltogatást kérnek."
    m["The first of the two buttons."] := "A két gomb közül az első."
    m["The second of the two buttons."] := "A két gomb közül a második."
    m["One key holds a button down for one second and then lets go, for prompts that say hold."] := "Egy billentyű egy másodpercig lenyomva tart egy gombot, majd elengedi, olyan felszólításokhoz, amelyek tartást kérnek."
    m["The game button to hold."] := "A tartandó játékgomb."
    m["Adds the F1 key. Press it to see a list of all your keys and what they do. Press it again for more detail, a third time to close it."] := "Hozzáadja az F1 billentyűt. Nyomd meg, hogy lásd az összes billentyűd listáját és hogy mit csinálnak. Nyomd meg újra a részletekért, harmadszor a bezáráshoz."
    m["Opens a window that explains every question and button."] := "Megnyit egy ablakot, amely minden kérdést és gombot elmagyaráz."
    m["Shows you what will be made and asks you to confirm, then builds the profile and switches to it."] := "Megmutatja, mi fog készülni, és megerősítést kér, majd elkészíti a profilt és átvált rá."
    m["Closes the wizard without making anything."] := "Bezárja a varázslót anélkül, hogy bármit létrehozna."
    m["SETUP WIZARD - WHAT EVERYTHING DOES`r`n`r`n"] := "BEÁLLÍTÁSI VARÁZSLÓ - MIT CSINÁL MINDEN`r`n`r`n"
    m["1. Which hand`r`n   The wizard gives each helper a key that your hand reaches without stretching.`r`n   Left hand: F, G, X, T, B and the number keys.`r`n   Right hand: J, K, L, U, I, O, H, N, M and the number pad.`r`n   Either hand: the same keys as the left hand.`r`n`r`n"] := "1. Melyik kéz`r`n   A varázsló minden segédnek olyan billentyűt ad, amelyet a kezed nyújtózkodás nélkül elér.`r`n   Bal kéz: F, G, X, T, B és a számbillentyűk.`r`n   Jobb kéz: J, K, L, U, I, O, H, N, M és a numerikus billentyűzet.`r`n   Bármelyik kéz: ugyanazok a billentyűk, mint a bal kéznél.`r`n`r`n"
    m["2. Profile name`r`n   Any name you like. It appears in the profile list of the main window.`r`n`r`n"] := "2. Profil neve`r`n   Bármilyen név. Megjelenik a főablak profillistájában.`r`n`r`n"
    m["3. Which program is the game`r`n   Start the game first, then pick it from the list. When it is set, the keys only work while the game is in front, and everything is let go if you switch away. Empty = works in any window (less safe).`r`n`r`n"] := "3. Melyik program a játék`r`n   Előbb indítsd el a játékot, majd válaszd ki a listából. Ha meg van adva, a billentyűk csak akkor működnek, amikor a játék van elöl, és minden elengedődik, ha elváltasz. Üresen = bármely ablakban működik (kevésbé biztonságos).`r`n`r`n"
    m["4. Keys the game already uses`r`n   The wizard will not take these keys, so your game controls keep working. Add the keys your game uses, separated by spaces.`r`n`r`n"] := "4. A játék által már használt billentyűk`r`n   A varázsló nem veszi el ezeket a billentyűket, így a játék vezérlése tovább működik. Add meg a játékod billentyűit, szóközzel elválasztva.`r`n`r`n"
    m["5. What one key should do (tick what you want)`r`n"] := "5. Mit csináljon egy billentyű (jelöld be, amit szeretnél)`r`n"
    m["   Walk forward on its own - press the key once to start walking, again to stop.`r`n"] := "   Magától előre sétál - egyszer megnyomod: sétálni kezd, újra: megáll.`r`n"
    m["   Click over and over - fast left clicks until you press the key again.`r`n"] := "   Újra és újra kattint - gyors bal kattintások, amíg újra meg nem nyomod a billentyűt.`r`n"
    m["   Press a key over and over - for button-mashing; pick which key.`r`n"] := "   Újra és újra megnyom egy billentyűt - gombnyomkodáshoz; válaszd ki, melyiket.`r`n"
    m["   Hold Shift / Hold Ctrl - the key holds it down for you until you press it again.`r`n"] := "   Shift / Ctrl tartása - a billentyű lenyomva tartja helyetted, amíg újra meg nem nyomod.`r`n"
    m["   Shift + Space together - a dodge or roll on a single key.`r`n"] := "   Shift + Space együtt - kitérés vagy gurulás egyetlen billentyűn.`r`n"
    m["   Mash a button in one burst - quick time events that ask you to mash: one press sends about 30 quick presses, then stops.`r`n"] := "   Egy gomb nyomkodása egy sorozatban - gyors események (QTE), amelyek nyomkodást kérnek: egy nyomás kb. 30 gyors lenyomást küld, majd leáll.`r`n"
    m["   Alternate two buttons - left/right mash prompts.`r`n"] := "   Két gomb váltogatása - bal/jobb nyomkodós felszólítások.`r`n"
    m["   Hold a button for 1 second - hold prompts.`r`n`r`n"] := "   Egy gomb tartása 1 másodpercig - tartós felszólítások.`r`n`r`n"
    m["Add a key that shows all the keys (F1)`r`n   Press F1 in the game to see a list of every key and what it does. Press it again for more detail, a third time to close it.`r`n`r`n"] := "Billentyű hozzáadása, amely mutatja az összes billentyűt (F1)`r`n   Nyomd meg az F1-et a játékban, hogy lásd minden billentyű listáját és hogy mit csinál. Nyomd meg újra a részletekért, harmadszor a bezáráshoz.`r`n`r`n"
    m["Buttons`r`n"] := "Gombok`r`n"
    m["   What does everything do? - this window.`r`n"] := "   Mit csinál minden? - ez az ablak.`r`n"
    m["   Create profile - shows you exactly what will be made (every key and what it does) and asks you to confirm. Nothing is saved until you say yes.`r`n"] := "   Profil létrehozása - megmutatja, pontosan mi fog készülni (minden billentyű és hogy mit csinál), és megerősítést kér. Semmi sem mentődik, amíg igent nem mondasz.`r`n"
    m["   Cancel - closes the wizard and makes nothing.`r`n`r`n"] := "   Mégse - bezárja a varázslót, és semmit sem hoz létre.`r`n`r`n"
    m["After it is made`r`n   The panic key (F2, or F8 for the right hand) turns everything off and on. You can change any key, add rows or add pages later in the main window and in Settings."] := "Miután elkészült`r`n   A vészleállító billentyű (F2, vagy F8 a jobb kéznél) ki- és bekapcsol mindent. Később bármelyik billentyűt megváltoztathatod, sorokat vagy lapokat adhatsz hozzá a főablakban és a Beállításokban."
    m["Setup wizard help"] := "Beállítási varázsló súgó"
    m["Please give the profile a name."] := "Kérlek, adj nevet a profilnak."
    m["Walk forward (toggle)"] := "Előre séta (kapcsoló)"
    m["press once to start walking, press again to stop"] := "egyszer megnyomod: sétálni kezd, újra: megáll"
    m["Auto-click"] := "Automata kattintás"
    m["press once to start clicking fast, press again to stop"] := "egyszer megnyomod: gyorsan kattint, újra: megáll"
    m["Auto-press "] := "Automata nyomás: "
    m["press once to press "] := "egyszer megnyomod: nyomkodja a(z) "
    m[" over and over, press again to stop"] := " billentyűt újra és újra, újra megnyomod: megáll"
    m["Hold Shift (toggle)"] := "Shift tartása (kapcsoló)"
    m["press once to hold Shift, press again to let go"] := "egyszer megnyomod: lenyomva tartja a Shiftet, újra: elengedi"
    m["Hold Ctrl (toggle)"] := "Ctrl tartása (kapcsoló)"
    m["press once to hold Ctrl, press again to let go"] := "egyszer megnyomod: lenyomva tartja a Ctrlt, újra: elengedi"
    m["Shift + Space together"] := "Shift + Space együtt"
    m["press once to do Shift and Space together"] := "egyszer megnyomod: a Shift és a Space együtt lenyomódik"
    m["Mash "] := "Nyomkodás: "
    m[" in one burst"] := " egy sorozatban"
    m[" about 30 times quickly, then it stops"] := " kb. 30-szor gyorsan, majd leáll"
    m["Alternate "] := "Váltogatás: "
    m[" and "] := " és "
    m["press once to alternate "] := "egyszer megnyomod: váltogatja: "
    m[" about 30 times, then it stops"] := " kb. 30-szor, majd leáll"
    m["Hold "] := "Tartás: "
    m[" for 1 second"] := " 1 másodpercig"
    m["press once to hold "] := "egyszer megnyomod: tartja: "
    m[" for one second, then let go"] := " egy másodpercig, majd elengedi"
    m["Tick at least one thing you want a key to do."] := "Jelölj be legalább egy dolgot, amit egy billentyű csináljon."
    m["Not enough free keys for that many actions. Untick a few, or remove some keys from the 'already used' list."] := "Nincs elég szabad billentyű ennyi művelethez. Vegyél ki párat, vagy távolíts el billentyűket a 'már használt' listából."
    m["This is what the wizard will make:`n`n"] := "Ezt fogja létrehozni a varázsló:`n`n"
    m["`nHand: "] := "`nKéz: "
    m["`n`nCreate this profile?"] := "`n`nLétrehozod ezt a profilt?"
    m["Your profile '"] := "A(z) '"
    m["' is ready:`n`n"] := "' profilod kész:`n`n"
    m[" turns everything off and on.`n"] := " ki- és bekapcsol mindent.`n"
    m["Welcome to Combo ReMapper 9.7"] := "Üdvözöl a Combo ReMapper 9.7"
    m["Welcome! The setup wizard builds a first profile for you. It asks which hand you use, which game, and what you want one key to do, then picks keys your hand can reach."] := "Üdv! A beállítási varázsló készít neked egy első profilt. Megkérdezi, melyik kezedet használod, melyik játékhoz, és mit csináljon egy billentyű, majd olyan billentyűket választ, amelyeket a kezed elér."
    m["You can open it at any time: tray icon -> Setup wizard..."] := "Bármikor megnyithatod: tálcaikon -> Beállítási varázsló..."
    m["Open the wizard"] := "Varázsló megnyitása"
    m["Not now"] := "Most nem"
    m["Don't ask again"] := "Ne kérdezd többé"
    m["Keyboard mouse: ON"] := "Billentyűzetes egér: BE"
    m["KEYBOARD MOUSE: ON"] := "BILLENTYŰZETES EGÉR: BE"
    m["Keyboard mouse: OFF"] := "Billentyűzetes egér: KI"
    m["KEYBOARD MOUSE: OFF"] := "BILLENTYŰZETES EGÉR: KI"
    m["One-button control: this profile has no rows to choose from."] := "Egygombos vezérlés: ebben a profilban nincs sor, amelyből választani lehetne."
    m["ONE-BUTTON CONTROL - press your key to choose the highlighted action"] := "EGYGOMBOS VEZÉRLÉS - nyomd meg a billentyűd a kijelölt művelet kiválasztásához"
    m["ONE-BUTTON CONTROL - tap = next, hold = choose"] := "EGYGOMBOS VEZÉRLÉS - koppintás = következő, tartás = választás"
    m["This row is empty. Fill in the trigger and combo first."] := "Ez a sor üres. Először töltsd ki az indítót és a kombót."
    m["Row note"] := "Sor megjegyzése"
    m["Short note for this row (shown in the cheat sheet, the status box and one-button control).`nExample: Walk forward (toggle)"] := "Rövid megjegyzés ehhez a sorhoz (a puskán, az állapotdobozban és az egygombos vezérlésben látszik).`nPélda: Előre séta (kapcsoló)"
    m["Note saved for this row. Press Apply to save the profile."] := "A megjegyzés elmentve ehhez a sorhoz. A profil mentéséhez nyomd meg az Alkalmaz gombot."
    m["Accessibility tools"] := "Akadálymentesítő eszközök"
    m["Edit while in the game (bring this window to the front)"] := "Szerkesztés játék közben (ez az ablak előtérbe hozása)"
    m["Show / hide key:"] := "Megjelenítés / elrejtés billentyű:"
    m["Keep it on top of the game while it is open"] := "Maradjon a játék fölött, amíg nyitva van"
    m["Tremor filter"] := "Remegésszűrő"
    m["Ignore a repeat press within (ms, 0 = off):"] := "Ismételt lenyomás figyelmen kívül hagyása ennyi időn belül (ms, 0 = ki):"
    m["Key must be held for (ms, 0 = off):"] := "A billentyűt ennyi ideig kell nyomva tartani (ms, 0 = ki):"
    m["Keyboard mouse (keys move the cursor and click)"] := "Billentyűzetes egér (billentyűk mozgatják a kurzort és kattintanak)"
    m["On/Off key:"] := "Be/Ki billentyű:"
    m["Speed (px/sec):"] := "Sebesség (px/mp):"
    m["Speed up while held"] := "Gyorsul, amíg nyomva tartod"
    m["Keys (only active while the keyboard mouse is ON):"] := "Billentyűk (csak akkor aktívak, ha a billentyűzetes egér BE van kapcsolva):"
    m["One-button control (one key steps through your actions)"] := "Egygombos vezérlés (egy billentyű lépked a műveleteiden)"
    m["Switch key:"] := "Kapcsoló billentyű:"
    m["How it works:"] := "Hogyan működik:"
    m["Automatic (the highlight moves by itself)"] := "Automatikus (a kijelölés magától mozog)"
    m["Step (tap = next, hold = choose)"] := "Léptetős (koppintás = következő, tartás = választás)"
    m["Speed (ms):"] := "Sebesség (ms):"
    m["Leave a key empty to switch that function off. The panic key turns the keyboard mouse and one-button control off at once."] := "Hagyj üresen egy billentyűt, hogy az a funkció ki legyen kapcsolva. A vészleállító billentyű egyszerre kapcsolja ki a billentyűzetes egeret és az egygombos vezérlést."
    m["' is the panic key.`n"] := "' a vészleállító billentyű.`n"
    m["' is already a trigger in this profile.`n"] := "' már indító ebben a profilban.`n"
    m["The window key, the keyboard mouse key and the one-button key must all differ.`n"] := "Az ablak-billentyű, a billentyűzetes egér billentyűje és az egygombos billentyű mind különbözzenek.`n"
    m["Please pick different keys:`n`n"] := "Kérlek, válassz másik billentyűket:`n`n"
    m["Accessibility tools saved"] := "Akadálymentesítő eszközök elmentve"
    m["Running without administrator rights. Games or emulators started as administrator will ignore the keys. Restart the program and accept the Windows prompt, or start the game normally."] := "Rendszergazdai jogok nélkül fut. A rendszergazdaként indított játékok vagy emulátorok figyelmen kívül hagyják a billentyűket. Indítsd újra a programot, és fogadd el a Windows kérdését, vagy indítsd a játékot normálisan."
    m["Auto  (Xbox or PS4)"] := "Automatikus  (Xbox vagy PS4)"
    m["Xbox  (XInput)"] := "Xbox  (XInput)"
    m["PS4  (DirectInput)"] := "PS4  (DirectInput)"
    m["Game  (scan codes + raw mouse)"] := "Játék  (szkenkódok + nyers egér)"
    m["Classic  (SendInput, plain key names)"] := "Klasszikus  (SendInput, sima billentyűnevek)"
    m["Hybrid  (SendInput scan codes + AHK mouse)"] := "Hibrid  (SendInput szkenkódok + AHK egér)"
    m["PS4 pad to keyboard + mouse"] := "PS4 kontroller billentyűzetre + egérre"
    m["Xbox pad to keyboard + mouse"] := "Xbox kontroller billentyűzetre + egérre"
    m["Auto-walk and auto-fire"] := "Automatikus séta és automatikus tüzelés"
    m["Quick-time mash"] := "Quick-time gombnyomkodás"
    m["Left stick"] := "Bal kar"
    m["Right stick"] := "Jobb kar"
    m["Pad 1"] := "Kontroller 1"
    m["Pad 2"] := "Kontroller 2"
    m["Pad 3"] := "Kontroller 3"
    m["Pad 4"] := "Kontroller 4"
    m["Auto"] := "Auto"
    m["Center"] := "Középen"
    m["Top left"] := "Bal felül"
    m["Top right"] := "Jobb felül"
    m["Bottom left"] := "Bal alul"
    m["Bottom right"] := "Jobb alul"
    m["mash "] := "nyomkodd: "
    m["alternate "] := "váltogasd: "
    m["hold "] := "tartsd: "
    m["release "] := "engedd el: "
    m["wait "] := "várj: "
    m["tap: "] := "koppintás: "
    m["   hold: "] := "   tartás: "
    m["Left Shift"] := "Bal Shift"
    m["Right Shift"] := "Jobb Shift"
    m["Left Ctrl"] := "Bal Ctrl"
    m["Right Ctrl"] := "Jobb Ctrl"
    m["Left Alt"] := "Bal Alt"
    m["Right Alt"] := "Jobb Alt"
    m["Space"] := "Szóköz"
    m["left click"] := "bal kattintás"
    m["right click"] := "jobb kattintás"
    m["middle click"] := "középső kattintás"
    m["left button"] := "bal gomb"
    m["right button"] := "jobb gomb"
    m["middle button"] := "középső gomb"
    m["scroll down"] := "görgetés le"
    m["scroll up"] := "görgetés fel"
    m["Up arrow"] := "Fel nyíl"
    m["Down arrow"] := "Le nyíl"
    m["Left arrow"] := "Bal nyíl"
    m["Right arrow"] := "Jobb nyíl"
    m[" AUTO OFF"] := " AUTO KI"
    m[" AUTO ON ("] := " AUTO BE ("
    m["...and "] := "...és még "
    m[" more (see the log file).`n"] := " további (lásd a naplófájlt).`n"
    m["Select Custom Background Image"] := "Válassz egyéni háttérképet"
    m["Image Files"] := "Képfájlok"
    m["  -  turns everything off and on`n"] := "  -  mindent ki- és bekapcsol`n"
    m["F1  -  shows all the keys on the screen`n"] := "F1  -  megmutatja az összes billentyűt a képernyőn`n"
    m["F1 shows all the keys on the screen.`n"] := "Az F1 megmutatja az összes billentyűt a képernyőn.`n"
    m["`nIt works in any window. Set the Target program in the main window when you know it."] := "`nBármelyik ablakban működik. Állítsd be a Célprogramot a főablakban, ha már tudod."
    m["OK"] := "OK"
    m["Set"] := "Vál."
    m["Exp"] := "Exp."
    m["Imp"] := "Imp."
    m["ms"] := "ms"
    m["Profile: "] := "Profil: "
    m["Target program: "] := "Célprogram: "
    m["Pages: "] := "Lapok: "
    m["Auto-detect: "] := "Automatikus érzékelés: "
    m["Delays: key "] := "Késleltetések: billentyű "
    m["> JACKING IN..."] := "> CSATLAKOZÁS..."
    m["> CYBERWARE SYNC 100%"] := "> CYBERWARE SZINKRON 100%"
    m["WATCH"] := "FIGYELD"
    m["REPEAT"] := "ISMÉTELD"
    m["ACCESS DENIED"] := "HOZZÁFÉRÉS MEGTAGADVA"
    m["ACCESS GRANTED"] := "HOZZÁFÉRÉS ENGEDÉLYEZVE"
    m["REPLAY"] := "ÚJRAJÁTSZÁS"
    m["> CONNECTING..."] := "> CSATLAKOZÁS..."
    m["> BYPASSING SECURITY"] := "> BIZTONSÁG KIKERÜLÉSE"
    m["> ACCESS CODE ACCEPTED"] := "> HOZZÁFÉRÉSI KÓD ELFOGADVA"
    m["> WELCOME, OPERATOR"] := "> ÜDVÖZÖLLEK, OPERÁTOR"
    m["CYBER MODE: ON"] := "KIBER MÓD: BE"
    m["CYBER MODE: OFF"] := "KIBER MÓD: KI"
    m["CYBER DECK"] := "KIBER KONZOL"
    m["Cyber Red theme unlocked."] := "Cyber Red téma feloldva."
    m["Cyber Yellow theme unlocked."] := "Cyber Yellow téma feloldva."
    m["Just a fun project. The hidden Cyber Red and Cyber Yellow themes are not affiliated with or endorsed by any company."] := "Ez csak egy szórakoztató projekt. A rejtett Cyber Red és Cyber Yellow téma semmilyen céggel nincs kapcsolatban, és egyik cég sem támogatja."
    m["Just a fun project. Not affiliated with any company."] := "Ez csak egy szórakoztató projekt. Nem áll kapcsolatban egyetlen céggel sem."
    m["Add language file..."] := "Nyelvfájl hozzáadása..."
    m["Add language file(s)"] := "Nyelvfájl(ok) hozzáadása"
    m["Translation files"] := "Fordítási fájlok"
    m["Language added: "] := "Nyelv hozzáadva: "
    m["Could not add the language file."] := "A nyelvfájlt nem sikerült hozzáadni."
    m["Switch to it now? (the program restarts)"] := "Átváltasz rá most? (a program újraindul)"
    m["Pick the language. Changing it offers to restart the program. To add your own language: export the template, translate it, then press Add language file... and pick your .po file (you can pick several)."] := "Válaszd ki a nyelvet. A váltás felajánlja a program újraindítását. Saját nyelv hozzáadásához: exportáld a sablont, fordítsd le, majd nyomd meg a Nyelvfájl hozzáadása... gombot, és válaszd ki a .po fájlt (többet is kiválaszthatsz)."
    m["                      J11 L3, J12 R3, J13 PS, J14 Touchpad"] := "                      J11 L3, J12 R3, J13 PS, J14 Touchpad"
    m["                      J5 L1, J6 R1, J7 L2, J8 R2, J9 Share, J10 Options,"] := "                      J5 L1, J6 R1, J7 L2, J8 R2, J9 Share, J10 Options,"
    m["  Alt + Tab                   down:lalt,tab,d100,up:lalt"] := "  Alt + Tab                   down:lalt,tab,d100,up:lalt"
    m["  Ctrl + C   /   Ctrl + V     down:lctrl,c,up:lctrl   /   down:lctrl,v,up:lctrl"] := "  Ctrl + C   /   Ctrl + V     down:lctrl,c,up:lctrl   /   down:lctrl,v,up:lctrl"
    m["(m / mm / mshake / mh)"] := "(m / mm / mshake / mh)"
    m["--- log file (last 30 lines) ---`n"] := "--- naplófájl (utolsó 30 sor) ---`n"
    m["Auto-start could not be set."] := "Az automatikus indítást nem sikerült beállítani."
    m["Auto-start is off."] := "Az automatikus indítás ki van kapcsolva."
    m["Auto-start is on (Windows may ask for administrator rights at each start)."] := "Az automatikus indítás be van kapcsolva (a Windows minden indításkor rendszergazdai jogot kérhet)."
    m["Auto-start is on (starts at logon with administrator rights)."] := "Az automatikus indítás be van kapcsolva (bejelentkezéskor, rendszergazdai joggal indul)."
    m["AutoHotkey "] := "AutoHotkey "
    m["Combo ReMapper"] := "Combo ReMapper"
    m["Combo ReMapper 9.7"] := "Combo ReMapper 9.7"
    m["Combo ReMapper 9.7 diagnostics`n"] := "Combo ReMapper 9.7 diagnosztika`n"
    m["List running toggles and turbos in the status box"] := "Az állapotdobozban listázza a futó kapcsolókat és turbókat"
    m["`n--- recent events (last 20) ---`n"] := "`n--- legutóbbi események (utolsó 20) ---`n"
    m["`nProgram: "] := "`nProgram: "
    m["mode:Hold"] := "Tartás"
    m["mode:Toggle"] := "Kapcsoló"
    m["mode:Press"] := "Lenyomás"
    m["mode:Turbo"] := "Turbó"
    m["mode:TapHold"] := "Kopp/Tart"
    m["mode:DblTap"] := "Dupla"
    m["mode:TglTurbo"] := "Auto-turbó"
    m["This program was written with the help of AI (Claude, made by Anthropic). I described what I needed and decided how it should work; the AI wrote the code. I say so openly so that people know how this software was made."] := "Ez a program MI (Claude, az Anthropic terméke) segítségével készült. Én leírtam, mire van szükségem, és eldöntöttem, hogyan működjön; a kódot az MI írta. Ezt nyíltan megmondom, hogy az emberek tudják, hogyan készült ez a szoftver."
    m["Export translation template..."] := "Fordítási sablon exportálása..."
    m["Open language folder"] := "Nyelvi mappa megnyitása"
    m["Translation template saved: "] := "Fordítási sablon elmentve: "
    m["Could not save the template file."] := "Nem sikerült elmenteni a sablonfájlt."
    m["Export template"] := "Sablon exportálása"
    m["Open folder"] := "Mappa megnyitása"
    m["  Hold      Sends the keys while the trigger is held, releases on release."] := "  Hold = Tartás        A billentyűket küldi, amíg az indítót nyomva tartod; elengedéskor elengedi."
    m["  Toggle    Press once to hold the keys down, press again to let go (auto-hold)."] := "  Toggle = Kapcsoló    Egyszer nyomd meg a billentyűk lenyomva tartásához, újra a feloldáshoz."
    m["  Press     One quick press of the combo each time."] := "  Press = Lenyomás     Minden alkalommal a kombó egy gyors lenyomása."
    m["  Turbo     Repeats the combo quickly while held (right-click row: interval)."] := "  Turbo = Turbó        Gyorsan ismétli a kombót, amíg nyomva tartod (sor jobb klikk: időköz)."
    m["  TapHold   A quick tap sends the FIRST key, holding sends the SECOND key."] := "  TapHold = Kopp/Tart  Gyors koppintás az ELSŐ billentyűt, tartás a MÁSODIKAT küldi."
    m["  DblTap    Two quick presses (within 0.35 s) send the combo."] := "  DblTap = Dupla       Két gyors lenyomás (0,35 mp-en belül) elküldi a kombót."
    m["  TglTurbo  Press once: the combo repeats by itself. Press again: it stops."] := "  TglTurbo = Auto-turbó  Egyszer megnyomod: a kombó magától ismétlődik. Újra: leáll."
}

; ============================================================
; BOOT
; ============================================================
BuildGUI()
UpdateSliderLimits()
RenderAll(true)

; Start gamepad polling if enabled in settings
if (controllerEnabled) {
    DetectJoyId()
    StartControllerPolling()
}
SetTimer(FocusWatch, 250)
AccessRegisterKeys()
try {
    if (IniRead(globalSettingsFile, "Global", "WizardOffer", "ask") != "never")
        SetTimer(OfferWizard, -1500)
}
DiagLog("Started 9.7 | AHK " . A_AhkVersion . " | Windows " . A_OSVersion . " | admin: " . (A_IsAdmin ? "yes" : "no") . " | profile: " . currentProfile . (startedByAutoStart ? " | started by Windows auto-start" : ""))
SetTimer(AutoProfileTick, 600)
bootDone := true
if (runAsAdmin && !A_IsAdmin)
    try TrayTip(LangT("Running without administrator rights. Games or emulators started as administrator will ignore the keys. Restart the program and accept the Windows prompt, or start the game normally."), LangT("Combo ReMapper"))
