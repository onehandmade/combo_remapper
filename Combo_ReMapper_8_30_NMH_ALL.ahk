; ============================================================
; Combo ReMapper 8.30 — NMH PROFILES, TglTurbo MODE, CONTROLLER ON/OFF COMBO, RIGHT-CLICK FIX / SWITCHABLE COMPATIBILITY MODES
; Mouse actions + Gamepad (controller) support
; ============================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook True

; ---- Run elevated: games/emulators started as admin ignore input from a
; non-elevated script. If UAC is declined the script simply keeps running
; without elevation.
; ---- About section: change your name here ----
global creatorName := "Dani"
global aiNote := "This program was written with the help of AI (Claude, made by Anthropic). I described what I needed and decided how it should work; the AI wrote the code. I say so openly so that people know how this software was made."
global runAsAdmin := true
try runAsAdmin := (IniRead(A_ScriptDir "\remapper_global.ini", "Global", "RunAsAdmin", "1") = "1")
global compatMode := 1   ; 1 = Game, 2 = Classic, 3 = Hybrid (see CompatModeNames)
if (runAsAdmin && !A_IsAdmin) {
    try {
        if A_IsCompiled
            Run('*RunAs "' A_ScriptFullPath '"')
        else
            Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
        ExitApp()
    }
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
    try LogEvent("ERROR: " . err.Message . "  (line " . err.Line . ")", true)
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

; ---- Mouse & Controller state ----
global mouseHeld := Map()           ; tracks left/right/middle buttons held by engine
global controllerEnabled := true    ; master switch for gamepad polling
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
global logGui := 0
global logLV := 0
global logClearBtn := 0
global logCloseBtn := 0
global logLastMsg := ""
global logLastTick := 0
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
    "Custom Image", Map("bg", "1E1E1E", "text", "FFFFFF", "controlBg", "2D2D2D", "img", "")
)
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
profilesDir := A_ScriptDir "\profiles"
if !DirExist(profilesDir)
    DirCreate(profilesDir)

globalSettingsFile := A_ScriptDir "\remapper_global.ini"

currentProfile := "default"
try currentProfile := IniRead(globalSettingsFile, "Global", "LastProfile", "default")
try autoProfile := (IniRead(globalSettingsFile, "Global", "AutoProfile", "0") = "1")
if !FileExist(profilesDir "\" currentProfile ".ini")
    currentProfile := "default"
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
    if (k = "mlc" || k = "mrc" || k = "mmc" || k = "mdown" || k = "mup")
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
    SetTimer(() => UpdateOSD(scriptEnabled ? "REMAPPER: ACTIVE" : "REMAPPER: DISABLED", scriptEnabled ? "00FF00" : "FF0000"), -ms)
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
    return ["Game  (scan codes + raw mouse)", "Classic  (SendInput, plain key names)", "Hybrid  (SendInput scan codes + AHK mouse)"]
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
    global compatMode
    data := 0
    lowBtn := StrLower(Trim(name))
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
    global compatMode
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
    NotifyUser("Compatibility: " . CompatModeNames()[compatMode])
}

GameKeyDown(name) {
    n := Trim(name)
    if (n = "" || IsJoyTrigger(n) || IsMouseActionToken(n) || IsKeyHoldToken(n))
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
    if (n = "" || IsJoyTrigger(n) || IsMouseActionToken(n) || IsKeyHoldToken(n))
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
    return ["Auto  (Xbox or PS4)", "Xbox  (XInput)", "PS4  (DirectInput)"]
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
    NotifyUser("Controller type: " . PadTypeNames()[padType])
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
    btn.Text := "Hold..."
    seen := Map()
    order := []
    anyHeld := false
    t0 := A_TickCount
    NotifyUser("Hold the controller buttons you want, then let go.", -6000)

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
            btn.Text := "Detect"
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
    global currentProfile, compatMode, padType, autoProfile
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Toggle Engine", ToggleScript)
    A_TrayMenu.Add("Toggle OSD Overlay", ToggleOSDOverlay)
    A_TrayMenu.Add("Toggle Controller Support", ToggleController)
    A_TrayMenu.Add()

    profileSub := Menu()
    for p in GetProfileList() {
        profileSub.Add(p, TraySelectProfile)
        if (p = currentProfile)
            profileSub.Check(p)
    }
    A_TrayMenu.Add("Switch Profile", profileSub)

    compatSub := Menu()
    for i, nm in CompatModeNames() {
        compatSub.Add(nm, SetCompatMode.Bind(i))
        if (i = compatMode)
            compatSub.Check(nm)
    }
    A_TrayMenu.Add("Compatibility Mode", compatSub)

    padSub := Menu()
    for i, nm in PadTypeNames() {
        padSub.Add(nm, SetPadType.Bind(i))
        if (i = padType)
            padSub.Check(nm)
    }
    A_TrayMenu.Add("Controller Type", padSub)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Auto-switch Profile by Game", ToggleAutoProfile)
    if (autoProfile)
        A_TrayMenu.Check("Auto-switch Profile by Game")
    starterSub := Menu()
    for i, nm in StarterNames()
        starterSub.Add(nm, CreateStarterProfile.Bind(i))
    A_TrayMenu.Add("Create Starter Profile", starterSub)
    A_TrayMenu.Add("Check Combos...", (*) => ShowComboCheck(true))
    A_TrayMenu.Add("Controller Test...", ShowControllerTest)
    A_TrayMenu.Add("Help...", ShowHelp)
    A_TrayMenu.Add("Fire Log...", ShowFireLog)
    A_TrayMenu.Add("About...", ShowAbout)
    A_TrayMenu.Add()
    A_TrayMenu.AddStandard()
}

ShowAbout(*) {
    global creatorName, aiNote
    aboutGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox", "About Combo ReMapper")
    aboutGui.SetFont("s10", "Segoe UI")
    aboutGui.Add("Text", "w400", "Combo ReMapper 8.30")
    aboutGui.SetFont("s10 Bold", "Segoe UI")
    aboutGui.Add("Text", "w400 y+14", "About the creator")
    aboutGui.SetFont("s10 Norm", "Segoe UI")
    aboutGui.Add("Text", "w400 y+6", "Made by " . creatorName . ".`n`nI'm handicapped, and I make these tools so that games and programs are easier for me, and for others, to play and use.")
    aboutGui.SetFont("s10 Bold", "Segoe UI")
    aboutGui.Add("Text", "w400 y+18", "Made with AI")
    aboutGui.SetFont("s10 Norm", "Segoe UI")
    aboutGui.Add("Text", "w400 y+6", aiNote)
    aboutGui.SetFont("s10 Bold", "Segoe UI")
    aboutGui.Add("Text", "w400 y+14", "Why I say this")
    aboutGui.SetFont("s10 Norm", "Segoe UI")
    aboutGui.Add("Text", "w400 y+6", "- People should know how software is made.`n- I came up with the idea and decided how it works and what it should do; the AI wrote the code.`n- If something breaks, people know the code was written by an AI and may need checking.`n- It shows that people like me can build our own tools with AI.")
    closeBtn := aboutGui.Add("Button", "y+18 w100 h30 Default", "Close")
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
        NotifyUser("Controller support: ON")
    } else {
        StopControllerPolling()
        NotifyUser("Controller support: OFF")
    }
}

; ============================================================
; ---- OSD Indicator Overlay Functions ----
; ============================================================
BuildOSD() {
    global osdGui, osdText, showOsd, osdLocked, osdX, osdY
    if (!showOsd)
        return
    if (osdGui != "") {
        osdGui.Show("x" osdX " y" osdY " NoActivate")
        return
    }
    opts := "+AlwaysOnTop -Caption +ToolWindow" . (osdLocked ? " +E0x20" : "")
    osdGui := Gui(opts)
    osdGui.BackColor := "1E1E1E"
    osdGui.SetFont("s10 bold c00FF00", "Consolas")
    osdText := osdGui.Add("Text", "x10 y6 w200 h22", "REMAPPER: ACTIVE")
    OnMessage(0x0201, WM_LBUTTONDOWN)
    osdGui.Show("x" osdX " y" osdY " NoActivate")
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

UpdateOSD(msg, colorHex := "00FF00") {
    global osdGui, osdText, showOsd, osdX, osdY
    if (!showOsd) {
        if (osdGui != "")
            osdGui.Hide()
        return
    }
    if (osdGui = "") {
        BuildOSD()
    } else {
        osdGui.Show("x" osdX " y" osdY " NoActivate")
    }
    if (osdText != "") {
        osdText.SetFont("c" . colorHex)
        osdText.Value := msg
    }
}

ToggleOSDOverlay(*) {
    global showOsd, osdGui, scriptEnabled
    showOsd := !showOsd

    if (!showOsd && osdGui != "") {
        osdGui.Hide()
        NotifyUser("Indicator Overlay: OFF")
    } else {
        UpdateOSD(scriptEnabled ? "REMAPPER: ACTIVE" : "REMAPPER: DISABLED", scriptEnabled ? "00FF00" : "FF0000")
        NotifyUser("Indicator Overlay: ON")
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
        NotifyUser("Y-Axis Locked")
    } else {
        SetTimer(MaintainYLock, 0)
        NotifyUser("Y-Axis Unlocked")
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
        MsgBox("Failed to bind Y-axis lock key: " . yLockKey, "Combo ReMapper 8.30", "Icon!")
    }
}

; ============================================================
; ---- Registry Helper for Auto-Start ----
; ============================================================
SetAutoStart(enable := true) {
    regKey := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
    appName := "AHK_ComboRemapper"
    if (enable) {
        RegWrite('"' A_ScriptFullPath '"', "REG_SZ", regKey, appName)
    } else {
        try RegDelete(regKey, appName)
    }
}

IsAutoStartEnabled() {
    regKey := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
    try {
        val := RegRead(regKey, "AHK_ComboRemapper")
        return val != ""
    }
    return false
}

; ============================================================
; ---- Load & Save State ----
; ============================================================
LoadState() {
    global rows, nextRowId, scrollTriggerKey, panicKey, osdToggleKey, targetExe, configFile, currentTheme, Themes, yLockKey
    global keyDelayDuration, keyDelayPress, mouseDelayDuration, soundAlerts, showTooltips, showOsd, osdLocked, osdX, osdY
    global compatMode
    global pressExtraMs, padPanic, padType, padPort, padMouseStick, padScrollStick, padMouseSpeed, padMouseDead, padMouseCurve
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
    try targetExe := IniRead(configFile, "Meta", "TargetExe", "")
    targetExe := NormalizeExe(targetExe)

    try currentTheme := IniRead(configFile, "Meta", "Theme", "Dark")
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
    try controllerEnabled := (IniRead(configFile, "Settings", "ControllerEnabled", "1") = "1")
    try padPort := Max(0, Min(4, Integer(IniRead(configFile, "Settings", "PadPort", 0))))
    try pressExtraMs := Max(0, Min(500, Integer(IniRead(configFile, "Settings", "PressExtraMs", 0))))
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
        turboMsVal := 60
        try turboMsVal := Integer(IniRead(configFile, "Row" . i, "TurboMs", 60))
        if (turboMsVal <= 0)
            turboMsVal := 60

        if (mode != "toggle" && mode != "press" && mode != "turbo" && mode != "autoturbo" && mode != "taphold" && mode != "doubletap")
            mode := "hold"

        rows.Push({id: i, trigger: Trim(trig), keys: ParseKeyList(combo), mode: mode, enabled: (enabledVal != "0"), turboMs: turboMsVal})
    }
    nextRowId := rowCount + 1
}

SaveStateToINI(targetFile) {
    global rows, scrollTriggerKey, panicKey, osdToggleKey, targetExe, currentTheme, Themes
    global keyDelayDuration, keyDelayPress, mouseDelayDuration, soundAlerts, showTooltips, showOsd, osdLocked, osdX, osdY
    global compatMode
    global customBgColor, customControlColor, customTextColor, controllerEnabled

    try FileDelete(targetFile)

    IniWrite(rows.Length, targetFile, "Meta", "RowCount")
    IniWrite(scrollTriggerKey != "" ? scrollTriggerKey : "(none)", targetFile, "Meta", "ScrollKey")
    IniWrite(panicKey, targetFile, "Meta", "PanicKey")
    IniWrite(osdToggleKey, targetFile, "Meta", "OsdKey")
    IniWrite(yLockKey != "" ? yLockKey : "(none)", targetFile, "Meta", "YLockKey")
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
    global rows, registeredRowTriggers
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
            MsgBox("Failed to bind panic key: " . panicKey, "Combo ReMapper 8.30", "Icon!")
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
            MsgBox("Failed to bind OSD toggle key: " . osdToggleKey, "Combo ReMapper 8.30", "Icon!")
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

    if (!heldCombos.Has(triggerKey) && !pressLatched.Has(triggerKey))
        LogEvent(StrUpper(triggerKey) . "  [" . row.mode . "]  ->  " . KeyListToString(row.keys) . "   (" . StrSplit(CompatModeNames()[compatMode], " ")[1] . " mode, " . (targetExe != "" ? "target focused" : "any window") . ")")

    if (row.mode = "taphold") {
        ; Tap (released within 250 ms) fires the first key; holding fires the second.
        released := WaitTriggerRelease(triggerKey, 250)
        if (released && row.keys.Length >= 1) {
            ExecuteComboSequence([row.keys[1]])
            FlashOSD(triggerKey . " tap -> " . row.keys[1])
        } else if (!released && row.keys.Length >= 2) {
            ExecuteComboSequence([row.keys[2]])
            FlashOSD(triggerKey . " hold -> " . row.keys[2])
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
            FlashOSD(triggerKey . " double-tap -> " . KeyListToString(row.keys))
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
            FlashOSD(triggerKey . " AUTO OFF", "FF6666")
        } else {
            heldCombos[triggerKey] := true
            turboInterval := (row.HasOwnProp("turboMs") && row.turboMs > 0) ? row.turboMs : 60
            boundFn := FireTurbo.Bind(triggerKey)
            turboTimers[triggerKey] := boundFn
            SetTimer(boundFn, turboInterval)
            FlashOSD(triggerKey . " AUTO ON (" . turboInterval . "ms)", "00FF66")
        }
    } else if (row.mode = "turbo") {
        if (heldCombos.Has(triggerKey))
            return
        heldCombos[triggerKey] := true
        turboInterval := (row.HasOwnProp("turboMs") && row.turboMs > 0) ? row.turboMs : 60
        boundFn := FireTurbo.Bind(triggerKey)
        turboTimers[triggerKey] := boundFn
        SetTimer(boundFn, turboInterval)
        FlashOSD(triggerKey . " TURBO (" . turboInterval . "ms)")
    } else if (row.mode = "press") {
        if (pressLatched.Has(triggerKey))
            return
        pressLatched[triggerKey] := true
        ExecuteComboSequence(row.keys)
        FlashOSD(triggerKey . " -> " . KeyListToString(row.keys))
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
        FlashOSD(triggerKey . " " . (isActive ? "OFF" : "ON"))
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
        FlashOSD(triggerKey . " -> " . KeyListToString(row.keys))
    }
}

HandleRelease(triggerKey, *) {
    global heldCombos, pressLatched, turboTimers, mouseHeld

    row := FindRow(triggerKey)
    if (row = "")
        return

    if (row.mode = "turbo") {
        heldCombos.Delete(triggerKey)
        if (turboTimers.Has(triggerKey)) {
            SetTimer(turboTimers[triggerKey], 0)
            turboTimers.Delete(triggerKey)
        }
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
scrollSignalFile := A_ScriptDir "\scroll_signal.txt"

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
    if (!scriptEnabled)
        ReleaseAllHeldCombos()
    UpdateToggleButton()
    UpdateOSD(scriptEnabled ? "REMAPPER: ACTIVE" : "REMAPPER: DISABLED", scriptEnabled ? "00FF00" : "FF0000")
    NotifyUser(scriptEnabled ? "Combo remapper: ON" : "Combo remapper: OFF")
}

RegisterPanicHotkey()
RegisterOsdHotkey()
RegisterYLockHotkey()

ReleaseAllHeldCombos() {
    global heldCombos, toggleActive, pressLatched, turboTimers, mouseHeld, seqHeldKeys

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

    ; Release any mouse buttons the engine was holding
    ReleaseMouseHeldButtons()
}

HandleExit(*) {
    ReleaseAllHeldCombos()
    StopControllerPolling()
    DllCall("winmm\timeEndPeriod", "UInt", 1)
}

; Releases held combos if the game loses focus mid-hold (alt-tab etc.)
FocusWatch() {
    global targetExe, heldCombos
    if (targetExe = "" || heldCombos.Count = 0)
        return
    if WinActive("ahk_exe " . targetExe)
        return
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
    NotifyUser("Profile '" . currentProfile . "' copied to clipboard!")
}

ImportProfile(*) {
    global profileDD, profilesDir, currentProfile, configFile
    clipText := Trim(A_Clipboard)

    if (!RegExMatch(clipText, "^\[REMAPPER_v.*\|NAME:([^\|]+)\|EXE:([^\|]*)\|PANIC:([^\]]+)\]", &match)) {
        MsgBox("Invalid profile string in clipboard.", "Import Error", "Icon!")
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
    NotifyUser("Imported & Switched to profile '" . pName . "'!")
}

; ============================================================
; ---- Key & Mouse Recorder Engine ----
; Captures keyboard via InputHook, mouse buttons via hotkeys, and
; gamepad via a polling timer that runs while recording.
; ============================================================
CaptureSingleKey(targetEditControl) {
    ih := InputHook("V L1 T5")
    NotifyUser("Press any key to bind...", -3000)
    ih.OnKeyDown := (hook, vk, sc) => (
        keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc)),
        targetEditControl.Text := keyName,
        NotifyUser("Bound key: " . keyName)
    )
    ih.Start()
}

StartKeyRecorder(slotIdx, *) {
    global rowUI, registeredRowTriggers, scriptEnabled
    global controllerEnabled, joyId

    targetTrigger := StrLower(Trim(rowUI[slotIdx].tb.Text))
    targetCB := rowUI[slotIdx].cb
    targetBtn := rowUI[slotIdx].autoBtn

    targetBtn.Text := "[REC]"
    targetBtn.Enabled := false

    for t in registeredRowTriggers {
        try Hotkey(t, "Off")
        try Hotkey(t " Up", "Off")
    }

    recordedKeys := Map()
    keyList := []

    UpdateOSD("RECORDING INPUTS...", "FFFF00")
    NotifyUser("RECORDING... Press keys, mouse buttons, or gamepad!", -6000)

    mouseButtons := ["LButton", "RButton", "MButton", "XButton1", "XButton2", "WheelUp", "WheelDown"]

    RecordMouse(mName, *) {
        mLower := StrLower(mName)
        if (mLower != targetTrigger && !recordedKeys.Has(mLower)) {
            recordedKeys[mLower] := true
            keyList.Push(mLower)
            targetCB.Text := JoinArray(keyList, ",")
            UpdateOSD("CAPTURED: " . StrUpper(mLower), "00FFFF")
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
                        UpdateOSD("CAPTURED: " . StrUpper(tLower), "00FFFF")
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
                    UpdateOSD("CAPTURED: " . StrUpper(tLower), "00FFFF")
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
                UpdateOSD("CAPTURED: " . StrUpper(povName), "00FFFF")
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
                    UpdateOSD("CAPTURED: " . StrUpper(tLower), "00FFFF")
                }
            }
        }
        jsRecPrev := curStick
    }

    SetTimer(JoyCaptureTick, 15)

    ih := InputHook("V L0 T6")
    ih.KeyOpt("{All}", "+N")

    HandleKeyDown(hook, vk, sc) {
        keyName := StrLower(GetKeyName(Format("vk{:x}sc{:x}", vk, sc)))
        if (keyName != "" && keyName != targetTrigger && !recordedKeys.Has(keyName)) {
            recordedKeys[keyName] := true
            keyList.Push(keyName)
            targetCB.Text := JoinArray(keyList, ",")
            UpdateOSD("CAPTURED: " . StrUpper(keyName), "00FFFF")
        }
    }
    ih.OnKeyDown := HandleKeyDown

    HandleEnd(*) {
        SetTimer(JoyCaptureTick, 0)
        for mKey in mouseButtons {
            try Hotkey("~*" mKey, "Off")
        }
        targetBtn.Text := "Auto"
        targetBtn.Enabled := true
        RegisterRowHotkeys()
        UpdateOSD(scriptEnabled ? "REMAPPER: ACTIVE" : "REMAPPER: DISABLED", scriptEnabled ? "00FF00" : "FF0000")
        ToolTip()
    }
    ih.OnEnd := HandleEnd

    ih.Start()
}

; ============================================================
; GUI ENGINE & SETTINGS PANEL
; ============================================================
BuildGUI() {
    global myGui, rowUI, rowSlider, scrollLabel, panicKeyBox, scrollKeyBox, targetExeBox, applyBtn, toggleBtn, statusBadge, statusText, scrollUpBtn, scrollDownBtn
    global profileDD, themeDD, bgPicControl, textControls, VISIBLE_ROWS, panicKey, scrollTriggerKey, targetExe, scriptEnabled, currentProfile, currentTheme

    myGui := Gui("+Resize -MaximizeBox", "Combo ReMapper 8.30")
    myGui.SetFont("s10")
    myGui.OnEvent("Close", (*) => ExitApp())

    textControls := []
    bgPicControl := myGui.Add("Picture", "x0 y0 w570 h630 +0x4000000 Hidden", "")

    OnMessage(0x020A, OnMouseWheel)

    t1 := myGui.Add("Text", "x10 y12 w45 h24 +0x200 +BackgroundTrans", "Profile:")
    textControls.Push(t1)

    profileDD := myGui.Add("DropDownList", "x55 y12 w80", GetProfileList())
    profileDD.Choose(currentProfile)
    profileDD.OnEvent("Change", SwitchProfile)

    newProfBtn := myGui.Add("Button", "x138 y11 w38 h24", "+New")
    newProfBtn.OnEvent("Click", CreateNewProfile)

    delProfBtn := myGui.Add("Button", "x178 y11 w38 h24", "-Del")
    delProfBtn.OnEvent("Click", DeleteProfile)

    expBtn := myGui.Add("Button", "x218 y11 w38 h24", "Exp")
    expBtn.OnEvent("Click", ExportProfile)

    impBtn := myGui.Add("Button", "x258 y11 w38 h24", "Imp")
    impBtn.OnEvent("Click", ImportProfile)

    settingsBtn := myGui.Add("Button", "x298 y11 w55 h24", "Settings")
    settingsBtn.OnEvent("Click", OpenSettingsPanel)

    t2 := myGui.Add("Text", "x358 y12 w42 h24 +0x200 +BackgroundTrans", "Theme:")
    textControls.Push(t2)

    themeDD := myGui.Add("DropDownList", "x402 y12 w80", ["Dark", "Light", "Custom Image"])
    themeDD.Choose(currentTheme)
    themeDD.OnEvent("Change", ChangeTheme)

    t3 := myGui.Add("Text", "xm y+15 w80 +BackgroundTrans", "Trigger key")
    tOn := myGui.Add("Text", "x+3 yp w20 +BackgroundTrans", "On")
    t4 := myGui.Add("Text", "x+3 yp w131 +BackgroundTrans", "Holds/Executes keys")
    t5 := myGui.Add("Text", "x+50 yp w65 +BackgroundTrans", "Mode")
    textControls.Push(t3, tOn, t4, t5)

    rowUI := []
    loop VISIBLE_ROWS {
        slotIdx := A_Index
        yOpt := (slotIdx = 1) ? "xm y+8" : "xm y+6"

        tb := myGui.Add("Edit", yOpt . " w80")
        enChk := myGui.Add("Checkbox", "x+3 yp+2 w16 h16 Checked", "")
        cb := myGui.Add("Edit", "x+3 yp-2 w131")
        autoBtn := myGui.Add("Button", "x+5 yp w42 h22", "Auto")
        dd := myGui.Add("DropDownList", "x+5 yp w75", ["Hold", "Toggle", "Press", "Turbo", "TapHold", "DblTap", "TglTurbo"])
        optsBtn := myGui.Add("Button", "x+2 yp w24 h22", "...")
        remBtn := myGui.Add("Button", "x+2 yp w45 h22", "Rem")

        autoBtn.OnEvent("Click", StartKeyRecorder.Bind(slotIdx))
        optsBtn.OnEvent("Click", OpenOptionsMenu.Bind(slotIdx))
        remBtn.OnEvent("Click", RemoveRowSlot.Bind(slotIdx))
        enChk.OnEvent("Click", (*) => SyncBoxesToRows())

        rowUI.Push({tb: tb, cb: cb, autoBtn: autoBtn, dd: dd, optsBtn: optsBtn, remBtn: remBtn, enChk: enChk})
    }

    scrollUpBtn := myGui.Add("Button", "x480 y46 w28 h22", "▲")
    rowSlider := myGui.Add("Slider", "x480 y70 w28 h175 Vertical TickInterval1 Range0-0", 0)
    rowSlider.OnEvent("Change", HandleSliderChange)
    scrollDownBtn := myGui.Add("Button", "x480 y247 w28 h22", "▼")

    scrollUpBtn.OnEvent("Click", (*) => ScrollRowsBy(-1))
    scrollDownBtn.OnEvent("Click", (*) => ScrollRowsBy(1))

    scrollLabel := myGui.Add("Text", "xm y+10 w450 +BackgroundTrans", "")
    textControls.Push(scrollLabel)

    addRowBtn := myGui.Add("Button", "xm y+10 w140 h26", "+ Add Combo")
    addRowBtn.OnEvent("Click", AddRow)

    t6 := myGui.Add("Text", "xm y+14 w130 +BackgroundTrans", "Panic Toggle key:")
    textControls.Push(t6)
    panicKeyBox := myGui.Add("Edit", "x+5 yp-4 w60", panicKey)
    panicCapBtn := myGui.Add("Button", "x+2 yp w35 h22", "Bind")
    panicCapBtn.OnEvent("Click", (*) => CaptureSingleKey(panicKeyBox))

    t7 := myGui.Add("Text", "x+10 yp+4 w95 +BackgroundTrans", "Scroll-click key:")
    textControls.Push(t7)
    scrollKeyBox := myGui.Add("Edit", "x+5 yp-4 w45", scrollTriggerKey)
    scrollCapBtn := myGui.Add("Button", "x+2 yp w35 h22", "Bind")
    scrollCapBtn.OnEvent("Click", (*) => CaptureSingleKey(scrollKeyBox))

    t8 := myGui.Add("Text", "xm y+14 w130 +BackgroundTrans", "Target Exe filter:")
    t9 := myGui.Add("Text", "x+5 yp +BackgroundTrans", "(blank/any)")
    textControls.Push(t8, t9)
    targetExeBox := myGui.Add("Edit", "x+5 yp-4 w130", targetExe)

    applyBtn := myGui.Add("Button", "xm y+14 w120 h30", "Apply")
    applyBtn.OnEvent("Click", ApplyChanges)

    toggleBtn := myGui.Add("Button", "x+10 yp w110 h30", scriptEnabled ? "Turn OFF" : "Turn ON")
    toggleBtn.OnEvent("Click", ToggleScript)

    statusBadge := myGui.Add("Text", "x+8 yp+2 w80 h26 +0x200 +Center +Border +BackgroundTrans", "ON")
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
                NotifyUser("Auto-switched to profile '" . name . "' for " . exe)
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
    NotifyUser("Auto-switch profile by game: " . (autoProfile ? "ON" : "OFF"))
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
            warnings.Push(label . ": '" . trig . "' is not a key, mouse button or controller button name")
        if (row.keys.Length = 0) {
            warnings.Push(label . ": no keys to send")
            continue
        }
        if (row.mode = "taphold" && row.keys.Length < 2)
            warnings.Push(label . ": TapHold needs two keys (first = tap, second = hold)")
        for k in row.keys {
            tok := Trim(k)
            if (tok = "")
                continue
            low := StrLower(tok)
            if (IsPauseToken(tok))
                continue
            if (IsJoyTrigger(tok)) {
                warnings.Push(label . ": '" . tok . "' is a controller button and cannot be sent as output")
                continue
            }
            if RegExMatch(tok, "i)^(down|up):(\S+)$", &hm) {
                if (!IsValidKeyName(hm[2]))
                    warnings.Push(label . ": unknown key name '" . hm[2] . "' in '" . tok . "'")
                if (row.mode = "hold" || row.mode = "toggle")
                    warnings.Push(label . ": '" . tok . "' does nothing in Hold or Toggle rows (use Press, Turbo or TglTurbo)")
                continue
            }
            if (IsMouseActionToken(low)) {
                if (IsHoldMotionToken(low) && row.mode != "hold" && row.mode != "toggle")
                    warnings.Push(label . ": '" . tok . "' only works in Hold or Toggle rows")
                continue
            }
            if (!IsValidKeyName(tok))
                warnings.Push(label . ": unknown key name '" . tok . "'")
        }
    }
    return warnings
}

ShowComboCheck(always := false) {
    SyncBoxesToRows()
    warnings := ValidateRows()
    if (warnings.Length = 0) {
        if (always)
            MsgBox("No problems found in your combos.", "Combo check", "Iconi")
        return
    }
    text := ""
    for i, w in warnings {
        LogEvent("* check: " . w)
        if (i <= 14)
            text .= "- " . w . "`n"
    }
    if (warnings.Length > 14)
        text .= "...and " . (warnings.Length - 14) . " more (see the Fire Log).`n"
    MsgBox("Possible problems in your combos:`n`n" . text, "Combo check", "Icon!")
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
    ctGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox +E0x08000000", "Controller Test")
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
    t := "PS4 / generic pad (DirectInput)`n"
    if (!JoyPresent())
        DetectJoyId()
    if (JoyPresent()) {
        padName := GetKeyState(joyId . "JoyName")
        t .= "  pad: " . padName . "  (#" . joyId . ")`n"
        t .= "  buttons down:"
        anyDown := false
        loop 32 {
            if GetKeyState(joyId . "Joy" . A_Index) {
                t .= " J" . A_Index
                anyDown := true
            }
        }
        t .= anyDown ? "`n" : " none`n"
        pov := GetPovName()
        t .= "  d-pad: " . (pov != "" ? pov : "centre") . "`n"
        t .= Format("  X {:5.1f}  Y {:5.1f}  Z {:5.1f}`n  R {:5.1f}  U {:5.1f}  V {:5.1f}`n", JoyAxis("X"), JoyAxis("Y"), JoyAxis("Z"), JoyAxis("R"), JoyAxis("U"), JoyAxis("V"))
        stickList := ""
        for tok, v in JoyStickTokens()
            stickList .= " " . tok
        t .= "  stick directions:" . (stickList != "" ? stickList : " none") . "`n"
    } else {
        t .= "  no DirectInput pad found`n"
    }
    t .= "`nXbox pad (XInput)`n"
    if (XInputPoll()) {
        tokList := ""
        for tok, v in XInputTokens()
            tokList .= " " . tok
        t .= "  slot " . (xiUser + 1) . ": pressed:" . (tokList != "" ? tokList : " none") . "`n"
    } else {
        t .= "  no Xbox pad found`n"
    }
    try ctEdit.Value := t
}
; ---- CONTROLLER TEST BLOCK END ----

; ---- HELP BLOCK BEGIN ----
HelpText() {
    t := ""
    t .= "COMBO REMAPPER - QUICK HELP" . "`n"
    t .= "============================" . "`n"
    t .= "" . "`n"
    t .= "WHAT IT DOES" . "`n"
    t .= "Each row is: TRIGGER -> COMBO, with a MODE. When you press the trigger" . "`n"
    t .= "(keyboard key, mouse button, or controller button), the remapper sends the" . "`n"
    t .= "combo to the game. It only reacts while the Target EXE window is in front" . "`n"
    t .= "(leave Target EXE on `"(any)`" to react everywhere)." . "`n"
    t .= "" . "`n"
    t .= "TRIGGERS" . "`n"
    t .= "  Keyboard / mouse    F1, q, XButton1, WheelUp ... any AutoHotkey key name" . "`n"
    t .= "  DualShock 4 (J)     J1 Square, J2 Cross, J3 Circle, J4 Triangle," . "`n"
    t .= "                      J5 L1, J6 R1, J7 L2, J8 R2, J9 Share, J10 Options," . "`n"
    t .= "                      J11 L3, J12 R3, J13 PS, J14 Touchpad" . "`n"
    t .= "                      (numbers can differ - use the Auto recorder to be sure)" . "`n"
    t .= "  D-pad               JPOVU  JPOVD  JPOVL  JPOVR" . "`n"
    t .= "  Stick directions    JLSU JLSD JLSL JLSR (left)  JRSU JRSD JRSL JRSR (right)" . "`n"
    t .= "  Xbox pad (X)        XA XB XX XY XLB XRB XLT XRT XSTART XBACK XLS XRS" . "`n"
    t .= "                      XUP XDOWN XLEFT XRIGHT, sticks XLSU.. and XRSU.." . "`n"
    t .= "  Chords              J5+J6   XLB+XRB   (all buttons held together)" . "`n"
    t .= "" . "`n"
    t .= "MODES" . "`n"
    t .= "  Hold      Sends the keys while the trigger is held, releases on release." . "`n"
    t .= "  Toggle    Press once to hold the keys down, press again to let go (auto-hold)." . "`n"
    t .= "  Press     One quick press of the combo each time." . "`n"
    t .= "  Turbo     Repeats the combo quickly while held (right-click row: interval)." . "`n"
    t .= "  TapHold   A quick tap sends the FIRST key, holding sends the SECOND key." . "`n"
    t .= "  DblTap    Two quick presses (within 0.35 s) send the combo." . "`n"
    t .= "  TglTurbo  Press once: the combo repeats by itself. Press again: it stops." . "`n"
    t .= "            (right-click row: interval)" . "`n"
    t .= "" . "`n"
    t .= "COMBO WORDS (separate with commas)" . "`n"
    t .= "  w, shift, space, f5     keys by name" . "`n"
    t .= "  d150  or  150           wait 150 milliseconds (a single digit is a real key)" . "`n"
    t .= "  mlc mrc mmc             left / right / middle click" . "`n"
    t .= "  mdown  mup              hold / release the left button" . "`n"
    t .= "  mwd5   mwu5             scroll down / up 5 notches" . "`n"
    t .= "  m10,-5                  move the mouse 10 right, 5 up (relative)" . "`n"
    t .= "  mx400,300               move the mouse to screen position 400,300" . "`n"
    t .= "  mm200,0,500             smooth move: 200 px right over 500 ms" . "`n"
    t .= "  mshake12,600            camera shake up to 12 px for 600 ms" . "`n"
    t .= "  mwave0,30,600,15        waggle up/down 30 px every 15 ms for 600 ms" . "`n"
    t .= "  down:q  up:q           hold a key (or lbutton) across steps, then let go" . "`n"
    t .= "                         e.g.  down:q,d40,mlc,d40,up:q" . "`n"
    t .= "  mh300,0                 steady move 300 px/s while a Hold row is held or a" . "`n"
    t .= "                          Toggle row is on" . "`n"
    t .= "" . "`n"
    t .= "SETTINGS (tray icon > Settings)" . "`n"
    t .= "  Input mode              Game / Classic / Hybrid. If a game ignores the keys," . "`n"
    t .= "                          try another mode (also in the tray menu)." . "`n"
    t .= "  Extra press time        Adds milliseconds to every key press. Helps with" . "`n"
    t .= "                          timed prompts and games that miss short taps." . "`n"
    t .= "  Controller type         Auto, Xbox (XInput) or PS4 (DirectInput)." . "`n"
    t .= "  Mouse stick / Scroll    A stick moves the mouse or scrolls the wheel." . "`n"
    t .= "  Speed, Deadzone, Curve  Tune the stick. A higher curve = finer control" . "`n"
    t .= "                          near the centre." . "`n"
    t .= "  Mouse speed %           Scales m / mm / mshake / mh moves." . "`n"
    t .= "  Run as Administrator    Needed when the game runs as admin. Restart to apply." . "`n"
    t .= "  Auto-switch profile     Changes profile by itself when you switch to a game" . "`n"
    t .= "                          whose profile has that Target EXE." . "`n"
    t .= "" . "`n"
    t .= "TRAY MENU EXTRAS" . "`n"
    t .= "  Fire Log                Shows what fired and why something did not." . "`n"
    t .= "  Controller Test         Live view of every button, d-pad and stick Windows sees." . "`n"
    t .= "  Check Combos            Looks for typos and mistakes in your rows." . "`n"
    t .= "  Create Starter Profile  Ready-made profiles to change to your liking." . "`n"
    t .= "  Compatibility / Controller Type   Quick switches." . "`n"
    t .= "" . "`n"
    t .= "PANIC" . "`n"
    t .= "  Keyboard: the panic key (default F8) turns the remapper off or on." . "`n"
    t .= "  Controller: hold Start+Back (Xbox) or Share+Options (PS4) for 1 second" . "`n"
    t .= "  to turn it off - hold it again to turn it back on. You can set your own" . "`n"
    t .= "  buttons in Settings (On/Off buttons). Held keys are always released." . "`n"
    t .= "" . "`n"
    t .= "TIPS" . "`n"
    t .= "  * Right-click a row for tools: Test Fire, Turbo interval, insert mouse" . "`n"
    t .= "    actions, duplicate, clear." . "`n"
    t .= "  * Hover over a setting in the Settings window for a short explanation." . "`n"
    t .= "  * Export Profile copies a profile to the clipboard; Import brings it back," . "`n"
    t .= "    including input mode, controller and mouse settings." . "`n"
    return t
}

ShowHelp(*) {
    global helpGui
    if (IsObject(helpGui)) {
        helpGui.Show()
        return
    }
    helpGui := Gui("+Resize -MaximizeBox", "Combo ReMapper - Help")
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
    return ["PS4 pad to keyboard + mouse", "Xbox pad to keyboard + mouse", "Auto-walk and auto-fire", "Quick-time mash"
        , "No More Heroes 1 (UAA port)", "No More Heroes 2 (UAA port)", "No More Heroes 3 (UAA port)"]
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
    if (idx = 5) {
        return Map("name", "nmh1_uaa_port", "padType", 1, "stick", 0, "exe", "No More Heroes.exe", "extra", 0, "panic", "F2", "rows", [
            ["XButton2", "w", "toggle", 60], ["XButton1", "lshift", "toggle", 60],
            ["Numpad3", "space", "press", 60], ["MButton", "up,down,left,right,d15,up,down,left,right", "press", 60],
            ["r", "down:q,mwave0,30,300,16", "autoturbo", 40], ["Numpad5", "down:q,mwd2,d40,mwu2,d40", "autoturbo", 40],
            ["Numpad4", "e", "autoturbo", 20], ["Numpad0", "mlc", "autoturbo", 20],
            ["Numpad1", "down:w,d1000,down:a,d200,up:a", "autoturbo", 50]])
    }
    if (idx = 6) {
        return Map("name", "nmh2_uaa_port", "padType", 1, "stick", 0, "exe", "No More Heroes 2.exe", "extra", 0, "panic", "F2", "rows", [
            ["XButton2", "w", "toggle", 60], ["XButton1", "lshift", "toggle", 60],
            ["Numpad3", "space", "press", 60], ["MButton", "up,down,left,right,d15,up,down,left,right", "press", 60],
            ["r", "down:q,mwave0,30,300,16", "autoturbo", 40], ["Numpad5", "down:q,mwd2,d40,mwu2,d40", "autoturbo", 40],
            ["Numpad4", "e", "autoturbo", 20], ["Numpad0", "mlc", "autoturbo", 20],
            ["Numpad1", "down:w,d1000,down:a,d200,up:a", "autoturbo", 50]])
    }
    if (idx = 7) {
        return Map("name", "nmh3_uaa_port", "padType", 1, "stick", 0, "exe", "NMH3.exe", "extra", 15, "panic", "F2", "rows", [
            ["XButton2", "w", "toggle", 60], ["XButton1", "lshift", "toggle", 60],
            ["Numpad3", "space", "press", 60], ["MButton", "up,down,left,right,d50,up,down,left,right", "press", 60],
            ["r", "down:q,mwave0,30,300,16", "autoturbo", 40], ["Numpad4", "e", "autoturbo", 50],
            ["Numpad0", "mlc", "autoturbo", 50], ["Numpad1", "down:w,d1000,down:a,d200,up:a", "autoturbo", 50],
            ["Numpad2", "w,s", "autoturbo", 50], ["Numpad5", "down:q,mwd2,d40,mwu2,d40", "autoturbo", 40],
            ["1", "down:q,d50,down:lbutton,d60,up:lbutton,d50,up:q", "press", 60],
            ["2", "down:q,d50,down:rbutton,d60,up:rbutton,d50,up:q", "press", 60], ["3", "down:q,d50,down:mbutton,d60,up:mbutton,d50,up:q", "press", 60],
            ["4", "down:q,d50,down:space,d60,up:space,d50,up:q", "press", 60]])
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
            IniWrite(1, path, "Row" . i, "Enabled")
            IniWrite(r[4], path, "Row" . i, "TurboMs")
        }
    }
    GotoProfile(name)
    NotifyUser("Starter profile ready: " . name . (data.Has("exe") ? "  (target: " . data["exe"] . " - change it if your game shows another name)" : "  (set your Target EXE, then Apply)"))
}
; ---- STARTER PROFILES BLOCK END ----

; ---- FIRE LOG BLOCK BEGIN ----
LogEvent(msg, throttle := false) {
    global fireLog, logLV, logLastMsg, logLastTick
    if (throttle && msg = logLastMsg && A_TickCount - logLastTick < 400)
        return
    logLastMsg := msg
    logLastTick := A_TickCount
    stamp := FormatTime(, "HH:mm:ss") . "." . Format("{:03}", A_MSec)
    fireLog.Push([stamp, msg])
    if (fireLog.Length > 300)
        fireLog.RemoveAt(1)
    if (IsObject(logLV)) {
        try {
            logLV.Add("", stamp, msg)
            if (logLV.GetCount() > 300)
                logLV.Delete(1)
            logLV.Modify(logLV.GetCount(), "Vis")
        }
    }
}

ShowFireLog(*) {
    global logGui, logLV, fireLog, logClearBtn, logCloseBtn
    if (IsObject(logGui)) {
        logGui.Show("NoActivate")
        return
    }
    ; Never takes focus, so it does not disturb the game while you watch it
    logGui := Gui("+AlwaysOnTop +ToolWindow +Resize -MaximizeBox +E0x08000000", "Remapper Fire Log")
    logGui.SetFont("s9", "Segoe UI")
    logLV := logGui.Add("ListView", "x8 y8 w560 h250 -Multi Grid", ["Time", "Event"])
    logLV.ModifyCol(1, 90)
    logLV.ModifyCol(2, 450)
    for entry in fireLog
        logLV.Add("", entry[1], entry[2])
    logClearBtn := logGui.Add("Button", "x8 y266 w90 h28", "Clear")
    logCloseBtn := logGui.Add("Button", "x106 y266 w90 h28", "Close")
    logClearBtn.OnEvent("Click", ClearFireLog)
    logCloseBtn.OnEvent("Click", CloseFireLog)
    logGui.OnEvent("Close", CloseFireLog)
    logGui.OnEvent("Size", ResizeFireLog)
    logGui.Show("w576 h304 NoActivate")
    if (logLV.GetCount() > 0)
        logLV.Modify(logLV.GetCount(), "Vis")
}

ResizeFireLog(g, minMax, w, h) {
    global logLV, logClearBtn, logCloseBtn
    if (minMax = -1 || !IsObject(logLV))
        return
    logLV.Move(, , Max(100, w - 16), Max(60, h - 54))
    logClearBtn.Move(, h - 38)
    logCloseBtn.Move(, h - 38)
}

ClearFireLog(*) {
    global fireLog, logLV
    fireLog := []
    if (IsObject(logLV))
        logLV.Delete()
}

CloseFireLog(*) {
    global logGui, logLV
    try logGui.Destroy()
    logGui := 0
    logLV := 0
}
; ---- FIRE LOG BLOCK END ----

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

    settingsGui := Gui("+Owner" . myGui.Hwnd . " +ToolWindow +Resize -MaximizeBox +0x200000", "Remapper Settings Panel")
    settingsGui.SetFont("s9")

    ; ---------------- Main settings window: everyday options ----------------
    settingsGui.Add("GroupBox", "xm ym w340 h258", "Startup, display and input")
    autoStartCB := settingsGui.Add("Checkbox", "x20 yp+25 " . (IsAutoStartEnabled() ? "Checked" : ""), "Auto-Start with Windows Startup")
    soundCB := settingsGui.Add("Checkbox", "x20 y+8 " . (soundAlerts ? "Checked" : ""), "Enable Audio Beep Alerts")
    tooltipCB := settingsGui.Add("Checkbox", "x20 y+8 " . (showTooltips ? "Checked" : ""), "Enable Overlay ToolTips")
    osdCB := settingsGui.Add("Checkbox", "x20 y+8 " . (showOsd ? "Checked" : ""), "Enable On-Screen Overlay (OSD)")
    osdLockCB := settingsGui.Add("Checkbox", "x20 y+8 " . (osdLocked ? "Checked" : ""), "Lock OSD Position (Click-Through)")
    settingsGui.Add("Text", "x20 y+12 w110", "OSD Toggle Key:")
    osdKeyBox := settingsGui.Add("Edit", "x130 yp-3 w60", osdToggleKey)
    osdCapBtn := settingsGui.Add("Button", "x+5 yp w45 h22", "Bind")
    osdCapBtn.OnEvent("Click", (*) => CaptureSingleKey(osdKeyBox))
    settingsGui.Add("Text", "x20 y+16 w80", "Input mode:")
    compatDD := settingsGui.Add("DropDownList", "x105 yp-3 w240 AltSubmit Choose" . compatMode, CompatModeNames())
    autoProfCB := settingsGui.Add("Checkbox", "x20 y+12 " . (autoProfile ? "Checked" : ""), "Auto-switch profile by game window")
    controllerCB := settingsGui.Add("Checkbox", "x20 y+8 " . (controllerEnabled ? "Checked" : ""), "Enable Gamepad / Controller Support")

    settingsGui.Add("GroupBox", "xm y+20 w340 h100", "Mouse hotkeys (tick Off to disable)")
    settingsGui.Add("Text", "x20 yp+26 w110", "Scroll-click key:")
    scrollKeyEdit := settingsGui.Add("Edit", "x135 yp-3 w60", scrollTriggerKey)
    scrollKeyBind := settingsGui.Add("Button", "x+5 yp w45 h22", "Bind")
    scrollKeyBind.OnEvent("Click", (*) => CaptureSingleKey(scrollKeyEdit))
    scrollOffCB := settingsGui.Add("Checkbox", "x+10 yp+3 " . (scrollTriggerKey = "" ? "Checked" : ""), "Off")
    settingsGui.Add("Text", "x20 y+14 w110", "Y-Axis Lock key:")
    yLockEdit := settingsGui.Add("Edit", "x135 yp-3 w60", yLockKey)
    yLockBind := settingsGui.Add("Button", "x+5 yp w45 h22", "Bind")
    yLockBind.OnEvent("Click", (*) => CaptureSingleKey(yLockEdit))
    yLockOffCB := settingsGui.Add("Checkbox", "x+10 yp+3 " . (yLockKey = "" ? "Checked" : ""), "Off")

    settingsGui.Add("GroupBox", "xm y+22 w340 h150", "Controller")
    settingsGui.Add("Text", "x20 yp+26 w100", "Controller type:")
    padTypeDD := settingsGui.Add("DropDownList", "x125 yp-3 w215 AltSubmit Choose" . padType, PadTypeNames())
    settingsGui.Add("Text", "x20 y+12 w80", "Mouse stick:")
    msDD := settingsGui.Add("DropDownList", "x105 yp-3 w95 AltSubmit Choose" . (padMouseStick + 1), ["Off", "Left stick", "Right stick"])
    settingsGui.Add("Text", "x210 yp+3 w70", "Speed px/s:")
    msSpeedEdit := settingsGui.Add("Edit", "x282 yp-3 w55", padMouseSpeed)
    settingsGui.Add("Text", "x20 y+12 w80", "Scroll stick:")
    scDD := settingsGui.Add("DropDownList", "x105 yp-3 w95 AltSubmit Choose" . (padScrollStick + 1), ["Off", "Left stick", "Right stick"])
    settingsGui.Add("Text", "x210 yp+3 w70", "Ticks/s:")
    scSpeedEdit := settingsGui.Add("Edit", "x282 yp-3 w55", padScrollSpeed)
    padPanicCB := settingsGui.Add("Checkbox", "x20 y+14 " . (padPanic ? "Checked" : ""), "Hold the on/off buttons for 1 second to switch the remapper off / on")
    settingsGui.Add("Text", "x20 y+8 w110", "On/Off buttons:")
    padSwitchEdit := settingsGui.Add("Edit", "x135 yp-3 w135", padSwitchCombo)
    padSwitchBtn := settingsGui.Add("Button", "x278 yp-1 w62", "Detect")
    padSwitchBtn.OnEvent("Click", DetectPadSwitch.Bind(padSwitchEdit))

    aboutBtn := settingsGui.Add("Button", "xm y+30 w100 h30", "About...")
    aboutBtn.OnEvent("Click", ShowAbout)
    logBtn := settingsGui.Add("Button", "x+8 yp w115 h30", "Fire Log...")
    logBtn.OnEvent("Click", ShowFireLog)
    helpBtn := settingsGui.Add("Button", "x+8 yp w100 h30", "Help...")
    helpBtn.OnEvent("Click", ShowHelp)
    advBtn := settingsGui.Add("Button", "xm y+8 w155 h30", "Advanced...")
    advBtn.OnEvent("Click", (*) => ShowAdvanced())
    saveBtn := settingsGui.Add("Button", "x+8 yp w172 h30", "Save Settings")
    saveBtn.OnEvent("Click", (*) => SaveSettingsAction())

    ; ---------------- Advanced window: fine tuning (kept hidden until asked for) ----------------
    advGui := Gui("+Owner" . settingsGui.Hwnd . " +ToolWindow +Resize -MaximizeBox +0x200000", "Advanced Settings")
    advGui.SetFont("s9")
    advGui.Add("GroupBox", "xm ym w340 h150", "Engine timing (ms)")
    advGui.Add("Text", "x20 yp+28 w120", "Key Delay:")
    kdEdit := advGui.Add("Edit", "x150 yp-3 w60", keyDelayDuration)
    advGui.Add("Text", "x20 y+12 w120", "Press Duration:")
    kpEdit := advGui.Add("Edit", "x150 yp-3 w60", keyDelayPress)
    advGui.Add("Text", "x20 y+12 w120", "Mouse Delay:")
    mdEdit := advGui.Add("Edit", "x150 yp-3 w60", mouseDelayDuration)
    advGui.Add("Text", "x20 y+12 w120", "Extra press time:")
    pressExtraEdit := advGui.Add("Edit", "x150 yp-3 w60 Number", pressExtraMs)

    advGui.Add("GroupBox", "xm y+22 w340 h140", "Controller tuning")
    advGui.Add("Text", "x20 yp+28 w80", "Pad slot:")
    padDD := advGui.Add("DropDownList", "x105 yp-3 w90 AltSubmit Choose" . (padPort + 1), ["Auto", "Pad 1", "Pad 2", "Pad 3", "Pad 4"])
    advGui.Add("Text", "x210 yp+3 w70", "Trigger at:")
    trigEdit := advGui.Add("Edit", "x282 yp-3 w50", padTrigThresh)
    advGui.Add("Text", "x20 y+12 w85", "Deadzone %:")
    msDeadEdit := advGui.Add("Edit", "x105 yp-3 w50", padMouseDead)
    advGui.Add("Text", "x210 yp+3 w70", "Curve:")
    msCurveEdit := advGui.Add("Edit", "x282 yp-3 w50 r1", Round(padMouseCurve, 2))
    advGui.Add("Text", "x20 y+12 w100", "Mouse speed %:")
    scaleEdit := advGui.Add("Edit", "x125 yp-3 w50", mouseScale)
    advGui.Add("Text", "x185 yp+3 w150", "(m / mm / mshake / mh)")

    advGui.Add("GroupBox", "xm y+22 w340 h60", "System")
    adminCB := advGui.Add("Checkbox", "x20 yp+26 " . (runAsAdmin ? "Checked" : ""), "Run as Administrator (applies after restart)")

    advGui.Add("GroupBox", "xm y+22 w340 h115", "Custom RGB Theme Pickers (HEX)")
    advGui.Add("Text", "x20 yp+28 w130", "Window Background:")
    bgHexEdit := advGui.Add("Edit", "x150 yp-3 w70", customBgColor)
    advGui.Add("Text", "x20 y+12 w130", "Control Background:")
    ctrlHexEdit := advGui.Add("Edit", "x150 yp-3 w70", customControlColor)
    advGui.Add("Text", "x20 y+12 w130", "Text Color:")
    textHexEdit := advGui.Add("Edit", "x150 yp-3 w70", customTextColor)
    advCloseBtn := advGui.Add("Button", "xm y+22 w120 h30", "Done")
    advCloseBtn.OnEvent("Click", (*) => advGui.Hide())
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

    AddTip(compatDD, "How keys and the mouse are sent. If a game ignores the keys, try another mode.")
    AddTip(adminCB, "Run as administrator. Needed when the game runs as admin. Applies after a restart.")
    AddTip(autoProfCB, "Switches profile by itself when you open a game whose profile has that Target EXE.")
    AddTip(pressExtraEdit, "Extra milliseconds added to every key press. Helps timed prompts and games that miss short taps.")
    AddTip(padTypeDD, "Auto uses either pad. Xbox reads only Xbox-style pads. PS4 reads only DirectInput pads such as a DualShock.")
    AddTip(padDD, "Which Xbox controller slot to read. Auto picks the first one connected.")
    AddTip(trigEdit, "How far an Xbox trigger (LT/RT) must be pressed to count as a button, 0 to 255.")
    AddTip(msDD, "Lets a stick move the mouse.")
    AddTip(msSpeedEdit, "Mouse speed in pixels per second with the stick fully pushed.")
    AddTip(msDeadEdit, "Percent of stick travel ignored around the centre, so a resting stick does not drift.")
    AddTip(msCurveEdit, "1 = even response. Higher = finer control near the centre and fast at the edge.")
    AddTip(scDD, "Lets a stick scroll the mouse wheel.")
    AddTip(scSpeedEdit, "Scroll notches per second with the stick fully pushed.")
    AddTip(scaleEdit, "Scales every mouse move token (m, mm, mshake, mh). 100 = normal.")
    AddTip(padPanicCB, "Hold the on/off buttons for 1 second to turn the remapper off. Hold them again to turn it back on.")
    AddTip(padSwitchEdit, "Your own on/off buttons, joined with +, for example XLB+XRB+XSTART or J5+J6. Leave blank for the default: Start+Back (Xbox) / Share+Options (PS4).")
    AddTip(padSwitchBtn, "Click, hold the buttons you want together on the controller, then let go.")
    AddTip(scrollKeyEdit, "Key that sends a mouse wheel scroll click. Press Bind and then the key you want.")
    AddTip(scrollOffCB, "Tick to switch the scroll-click key off completely.")
    AddTip(yLockEdit, "Key that locks the mouse to its current height (Y axis). Press it again to unlock.")
    AddTip(yLockOffCB, "Tick to switch the Y-axis lock off completely.")
    AddTip(kdEdit, "Pause after each key event, in milliseconds.")
    AddTip(kpEdit, "How long each key is held down for a press, in milliseconds.")
    AddTip(mdEdit, "Pause after each mouse action, in milliseconds.")
    AddTip(controllerCB, "Turns controller reading on or off.")
    settingsGui.OnEvent("Close", (*) => (advGui.Destroy(), settingsGui.Destroy()))
    settingsGui.Show("Hide")
    saveBtn.GetPos(, &btnY, , &btnH)
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
        global controllerEnabled, compatMode, runAsAdmin, globalSettingsFile, autoProfile
        global pressExtraMs, padPanic, padType, padPort, padMouseStick, padScrollStick, padMouseSpeed, padMouseDead, padMouseCurve
        global padScrollSpeed, padTrigThresh, mouseScale, padSwitchCombo
        global scrollTriggerKey, yLockKey, scrollKeyBox, panicKey

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
            MsgBox("The Administrator setting applies the next time the remapper starts.", "Combo ReMapper 8.30", "Iconi")
        }

        if IsNumber(kdEdit.Text) && IsNumber(kpEdit.Text) && IsNumber(mdEdit.Text) {
            keyDelayDuration := Integer(kdEdit.Text)
            keyDelayPress := Integer(kpEdit.Text)
            mouseDelayDuration := Integer(mdEdit.Text)

            SetKeyDelay(keyDelayDuration, keyDelayPress)
            SetMouseDelay(mouseDelayDuration)
        }

        SetAutoStart(autoStartCB.Value)
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
            MsgBox("The Y-axis lock key ('" . newYLock . "') is already used by another hotkey. Pick a different one.", "Combo ReMapper 8.30", "Icon!")
            newYLock := yLockKey
        }
        scrollTriggerKey := newScroll
        if (scrollKeyBox != "")
            scrollKeyBox.Text := scrollTriggerKey
        RegisterScrollHotkey()
        yLockKey := newYLock
        RegisterYLockHotkey()
        RegisterYLockHotkey()

        if (osdGui != "") {
            osdGui.Destroy()
            osdGui := ""
        }
        if (showOsd) {
            BuildOSD()
            UpdateOSD(scriptEnabled ? "REMAPPER: ACTIVE" : "REMAPPER: DISABLED", scriptEnabled ? "00FF00" : "FF0000")
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
        settingsGui.Destroy()
        NotifyUser("Settings successfully applied!")
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
    rowMenu.Add("Test Fire This Combo Now", (*) => TestFireCombo(targetCB))
    if (isTurbo)
        rowMenu.Add("Set Turbo Interval (ms)...", (*) => SetTurboInterval(slotIdx))
    rowMenu.Add()
    rowMenu.Add("Extend Combo (Append directly)", (*) => ExtendComboDirect(targetCB))
    rowMenu.Add("Add Pause Delay (ms)", (*) => AddDelayPrompt(targetCB))
    rowMenu.Add()
    rowMenu.Add("Prepend Key (Prefix)", (*) => PrependKeyPrompt(targetCB))
    rowMenu.Add("Append Key (Suffix)", (*) => AppendKeyPrompt(targetCB))
    rowMenu.Add()
    rowMenu.Add("Insert Mouse Move (Relative)", (*) => InsertMouseMove(targetCB, false))
    rowMenu.Add("Insert Mouse Move (Absolute)", (*) => InsertMouseMove(targetCB, true))
    rowMenu.Add("Insert Mouse Click (Left/Right/Middle)", (*) => InsertMouseClick(targetCB))
    rowMenu.Add("Insert Smooth Mouse Move (over time)", (*) => InsertSmoothMove(targetCB))
    rowMenu.Add("Insert Camera Shake", (*) => InsertShake(targetCB))
    rowMenu.Add("Insert Continuous Move (while held / toggled)", (*) => InsertHoldMove(targetCB))
    rowMenu.Add()
    rowMenu.Add("Duplicate Row", (*) => DuplicateRowSlot(slotIdx))
    rowMenu.Add("Clear Row Inputs", (*) => ClearRowSlot(slotIdx))

    rowMenu.Show()
}

; ---- Extra mouse helpers in the Options menu ----
InsertMouseMove(cbControl, absolute) {
    prompt := absolute
        ? "Enter absolute X,Y coordinates (e.g. 400,300):"
        : "Enter relative dx,dy movement (e.g. 10,-5):"
    ib := InputBox(prompt, "Insert Mouse Move", "w300 h130")
    if (ib.Result != "OK")
        return
    val := Trim(ib.Value)
    if !RegExMatch(val, "^-?\d+\s*,\s*-?\d+$") {
        NotifyUser("Invalid format. Use dx,dy (numbers only).")
        return
    }
    val := StrReplace(val, " ", "")
    token := (absolute ? "mx" : "m") . val
    current := Trim(cbControl.Text)
    cbControl.Text := (current != "") ? current . "," . token : token
    NotifyUser("Inserted: " . token)
}

AppendComboToken(cbControl, token) {
    current := Trim(cbControl.Text)
    cbControl.Text := (current != "") ? current . "," . token : token
    NotifyUser("Inserted: " . token)
}

InsertSmoothMove(cbControl) {
    ib := InputBox("Total dx,dy and duration in ms, separated by commas`n(e.g. 200,0,500 moves 200 px right over half a second):", "Insert Smooth Mouse Move", "w360 h150")
    if (ib.Result != "OK")
        return
    val := StrReplace(Trim(ib.Value), " ", "")
    if !RegExMatch(val, "^-?\d+,-?\d+,\d+$") {
        NotifyUser("Invalid format. Use dx,dy,ms (e.g. 200,0,500).")
        return
    }
    AppendComboToken(cbControl, "mm" . val)
}

InsertShake(cbControl) {
    ib := InputBox("Shake strength in pixels and duration in ms`n(e.g. 12,600 = jitter up to 12 px for 0.6 s):", "Insert Camera Shake", "w360 h150")
    if (ib.Result != "OK")
        return
    val := StrReplace(Trim(ib.Value), " ", "")
    if !RegExMatch(val, "^\d+,\d+$") {
        NotifyUser("Invalid format. Use strength,ms (e.g. 12,600).")
        return
    }
    AppendComboToken(cbControl, "mshake" . val)
}

InsertHoldMove(cbControl) {
    ib := InputBox("Speed vx,vy in pixels per second, while the trigger is held (Hold rows) or on (Toggle rows)`n(e.g. 300,0 = steady turn right; negative = left/up):", "Insert Continuous Move", "w400 h160")
    if (ib.Result != "OK")
        return
    val := StrReplace(Trim(ib.Value), " ", "")
    if !RegExMatch(val, "^-?\d+,-?\d+$") {
        NotifyUser("Invalid format. Use vx,vy (e.g. 300,0).")
        return
    }
    AppendComboToken(cbControl, "mh" . val)
}

InsertMouseClick(cbControl) {
    ib := InputBox("Enter click type (L = left, R = right, M = middle):", "Insert Mouse Click", "w300 h130")
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
        NotifyUser("Invalid choice. Use L, R, or M.")
        return
    }
    current := Trim(cbControl.Text)
    cbControl.Text := (current != "") ? current . "," . token : token
    NotifyUser("Inserted: " . token)
}

TestFireCombo(cbControl) {
    keys := ParseKeyList(cbControl.Text)
    if (keys.Length = 0) {
        NotifyUser("Nothing to test - combo is empty")
        return
    }
    NotifyUser("Test firing combo...")
    ExecuteComboSequence(keys)
}

SetTurboInterval(slotIdx) {
    global rows, scrollOffset
    SyncBoxesToRows()
    targetIdx := scrollOffset + slotIdx
    if (targetIdx > rows.Length)
        return
    current := rows[targetIdx].HasOwnProp("turboMs") ? rows[targetIdx].turboMs : 60
    ib := InputBox("Turbo repeat interval in milliseconds (lower = faster):", "Turbo Interval", "w280 h130", current)
    if (ib.Result = "OK" && IsNumber(Trim(ib.Value)) && Integer(Trim(ib.Value)) > 0) {
        rows[targetIdx].turboMs := Integer(Trim(ib.Value))
        NotifyUser("Turbo interval set to " . rows[targetIdx].turboMs . "ms")
    }
}

AddDelayPrompt(cbControl) {
    ib := InputBox("Enter pause delay in milliseconds (e.g. 150):", "Add Sequence Delay", "w260 h130")
    if (ib.Result = "OK" && IsNumber(Trim(ib.Value))) {
        delayVal := "d" . Trim(ib.Value)
        current := Trim(cbControl.Text)
        cbControl.Text := (current != "") ? current . "," . delayVal : delayVal
    }
}

ExtendComboDirect(cbControl) {
    ib := InputBox("Enter key sequence to append directly (e.g. shift,w):", "Extend Combo", "w280 h130")
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
    ib := InputBox("Enter key(s) to PREPEND (e.g. shift, ctrl):", "Prepend Key", "w260 h130")
    if (ib.Result = "OK" && Trim(ib.Value) != "") {
        prefix := Trim(ib.Value)
        current := Trim(cbControl.Text)
        cbControl.Text := (current != "") ? prefix . "," . current : prefix
    }
}

AppendKeyPrompt(cbControl) {
    ib := InputBox("Enter key(s) to APPEND (e.g. enter, space):", "Append Key", "w260 h130")
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
        rows.Push({id: nextRowId, trigger: orig.trigger != "" ? orig.trigger . "_copy" : "", keys: orig.keys.Clone(), mode: orig.mode, enabled: orig.HasOwnProp("enabled") ? orig.enabled : true, turboMs: orig.HasOwnProp("turboMs") ? orig.turboMs : 60})
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

    for ed in allEdits {
        ed.Opt("Background" . ctrlBg)
        ed.SetFont("c" . textColor)
        ed.Redraw()
    }

    if (myGui != "")
        WinRedraw(myGui.Hwnd)
}

ChangeTheme(ctrl, *) {
    global currentTheme, Themes
    newTheme := ctrl.Text

    if (newTheme = "Custom Image") {
        selectedImg := FileSelect("", A_ScriptDir, "Select Custom Background Image", "Image Files (*.png; *.jpg; *.jpeg; *.bmp)")
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
        themeDD.Choose(currentTheme)
        ApplyTheme(currentTheme)
    }

    RegisterRowHotkeys()
    RegisterScrollHotkey()
    RegisterPanicHotkey()
    RegisterOsdHotkey()
    RegisterYLockHotkey()
    BuildTrayMenu()

    scrollOffset := 0
    UpdateSliderLimits()
    RenderAll(true)
}

CreateNewProfile(*) {
    global profileDD, profilesDir
    ib := InputBox("Enter name for new profile:", "New Profile", "w250 h120")
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
        MsgBox("The 'default' profile cannot be deleted.", "Delete Profile", "Icon!")
        return
    }

    result := MsgBox("Are you sure you want to delete profile '" . currentProfile . "'?", "Delete Profile", "YesNo Icon?")
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
    profileDD.Choose(currentProfile)
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
            modeText := rowUI[slotIdx].dd.Text
            row.mode := (modeText = "Toggle") ? "toggle" : ((modeText = "Press") ? "press" : ((modeText = "Turbo") ? "turbo" : ((modeText = "TapHold") ? "taphold" : ((modeText = "DblTap") ? "doubletap" : ((modeText = "TglTurbo") ? "autoturbo" : "hold")))))
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
            rowUI[slotIdx].cb.Visible := true
            rowUI[slotIdx].enChk.Visible := true
            rowUI[slotIdx].autoBtn.Visible := true
            rowUI[slotIdx].dd.Visible := true
            rowUI[slotIdx].optsBtn.Visible := true
            rowUI[slotIdx].remBtn.Visible := true
        } else {
            rowUI[slotIdx].tb.Visible := false
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
        scrollLabel.Text := "Showing rows " . startIdx . "-" . endIdx . " of " . total
    } else {
        scrollLabel.Text := (total = 0) ? "(no combos yet - click + Add Combo below)" : "Showing all " . total . " rows"
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
    toggleBtn.Text := scriptEnabled ? "Turn OFF" : "Turn ON"

    if (statusBadge != "") {
        statusBadge.Value := scriptEnabled ? "ACTIVE" : "OFF"
        statusBadge.SetFont("c" . (scriptEnabled ? "00FF00" : "FF0000"))
    }

    scrollDesc := (scrollTriggerKey != "") ? "ScrollKey: " . scrollTriggerKey : "Scroll: OFF"
    filterDesc := (targetExe != "") ? "Target: " . targetExe : "Target: (any)"
    ctrlDesc := controllerEnabled ? "Pad: ON" : "Pad: OFF"
    statusText.Text := "Status: " . (scriptEnabled ? "ON" : "OFF") . " | Panic: " . panicKey . " | " . scrollDesc . " | " . filterDesc . " | " . ctrlDesc
}

ApplyChanges(*) {
    global rows, panicKey, scrollTriggerKey, configFile

    SyncBoxesToRows()

    if (panicKey = "") {
        MsgBox("The panic toggle key cannot be blank. This is required for safety.", "Combo ReMapper 8.30", "Icon!")
        return
    }

    seenTriggers := Map()
    for row in rows {
        if (row.trigger = "")
            continue
        cleanTrig := RegExReplace(StrUpper(row.trigger), "^~")
        if (cleanTrig = StrUpper(panicKey)) {
            MsgBox("'" row.trigger "' is reserved for the panic toggle and can't be a trigger key. Nothing was saved.", "Combo ReMapper 8.30", "Icon!")
            return
        }
        if (seenTriggers.Has(cleanTrig)) {
            MsgBox("'" row.trigger "' is used as a trigger key on more than one row. Please make each trigger key unique.", "Combo ReMapper 8.30", "Icon!")
            return
        }
        seenTriggers[cleanTrig] := true
    }

    if (scrollTriggerKey != "") {
        if (StrUpper(scrollTriggerKey) = StrUpper(panicKey)) {
            MsgBox("The scroll-click key can't be the panic toggle. Nothing was saved.", "Combo ReMapper 8.30", "Icon!")
            return
        }
        if (seenTriggers.Has(StrUpper(scrollTriggerKey))) {
            MsgBox("The scroll-click key ('" scrollTriggerKey "') is the same as one of your row trigger keys. Pick a different one.", "Combo ReMapper 8.30", "Icon!")
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

    SaveStateToINI(configFile)

    UpdateToggleButton()
    NotifyUser("Combos updated and saved")
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
SetTimer(AutoProfileTick, 600)