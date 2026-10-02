; ============================================================
; Combo ReMapper 8.16 — SWITCHABLE COMPATIBILITY MODES
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

; ---- Global State Initializations ----
global scriptEnabled := true
global yAxisLocked := false
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
global padMouseStick := 0           ; 0 off, 1 left stick, 2 right stick
global padScrollStick := 0          ; 0 off, 1 left stick, 2 right stick
global padMouseSpeed := 900         ; pixels per second at full deflection
global padMouseDead := 18           ; deadzone, percent
global padMouseCurve := 1.6         ; response curve (1 = linear)
global padScrollSpeed := 12         ; wheel ticks per second at full deflection
global padTrigThresh := 40          ; trigger press threshold (0-255)
global mouseScale := 100            ; percent, applies to m / mm / mshake / mh tokens
global padMouseTimerOn := false
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
    if RegExMatch(t, "^J(\d{1,2}|POV[UDLR])$")
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
    return false
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
    global keyDelayPress, compatMode
    if (compatMode = 2)
        return 20
    return Max(keyDelayPress, 35)
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

MouseButtonEvent(name, isDown) {
    global compatMode
    data := 0
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
    if (n = "" || IsJoyTrigger(n) || IsMouseActionToken(n))
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
    if (n = "" || IsJoyTrigger(n) || IsMouseActionToken(n))
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
    global controllerTimerActive, joyButtonState, joyPovState, xiPrev
    if (controllerTimerActive)
        SetTimer(PollController, 0)
    controllerTimerActive := false
    joyButtonState := Map()
    joyPovState := ""
    xiPrev := Map()
    UpdatePadMouseTimer()
}

; ---- XINPUT BLOCK BEGIN ----
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

PadStick(sel, &vx, &vy) {
    ; Radial deadzone + response curve. Returns -1..1 on each axis (up = +y).
    global xiBuf, padMouseDead, padMouseCurve
    off := (sel = 2) ? 12 : 8
    nx := NumGet(xiBuf, off, "Short") / 32767.0
    ny := NumGet(xiBuf, off + 2, "Short") / 32767.0
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
    global padLast, padAccX, padAccY, padAccS
    nowT := NowMs()
    dt := Min(100.0, nowT - padLast)
    padLast := nowT
    if (!scriptEnabled || (targetExe != "" && !WinActive("ahk_exe " . targetExe)))
        return
    if (!XInputPoll())
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
    if (SubStr(t, 1, 1) = "X") {
        if (!XInputPoll())
            return false
        return XInputTokens().Has(t)
    }
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
    global controllerEnabled, scriptEnabled, joyButtonState, joyPovState, xiPrev
    global targetExe, joyId, joyDetectTick

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
        return
    }

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

    ; --- XInput (Xbox-style pads: buttons, separate triggers, stick directions) ---
    if (XInputPoll()) {
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
}

; ============================================================
; ---- System Tray Context Menu Engine ----
; ============================================================
BuildTrayMenu() {
    global currentProfile, compatMode
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
    A_TrayMenu.Add()
    A_TrayMenu.Add("About...", ShowAbout)
    A_TrayMenu.Add()
    A_TrayMenu.AddStandard()
}

ShowAbout(*) {
    global creatorName, aiNote
    aboutGui := Gui("+AlwaysOnTop +ToolWindow", "About Combo ReMapper")
    aboutGui.SetFont("s10", "Segoe UI")
    aboutGui.Add("Text", "w400", "Combo ReMapper 8.16")
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

try Hotkey("*F6", ToggleYAxisLock, "On")

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
    global rows, nextRowId, scrollTriggerKey, panicKey, osdToggleKey, targetExe, configFile, currentTheme, Themes
    global keyDelayDuration, keyDelayPress, mouseDelayDuration, soundAlerts, showTooltips, showOsd, osdLocked, osdX, osdY
    global compatMode
    global padPort, padMouseStick, padScrollStick, padMouseSpeed, padMouseDead, padMouseCurve
    global padScrollSpeed, padTrigThresh, mouseScale
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

        if (mode != "toggle" && mode != "press" && mode != "turbo" && mode != "taphold")
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
            MsgBox("Failed to bind panic key: " . panicKey, "Combo ReMapper 8.16", "Icon!")
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
            MsgBox("Failed to bind OSD toggle key: " . osdToggleKey, "Combo ReMapper 8.16", "Icon!")
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
    if (!scriptEnabled || (targetExe != "" && !WinActive("ahk_exe " . targetExe)))
        return

    row := FindRow(triggerKey)
    if (row = "" || row.keys.Length = 0)
        return
    if (row.HasOwnProp("enabled") && !row.enabled)
        return

    if (row.mode = "taphold") {
        timedOut := WaitTriggerRelease(triggerKey, 250)
        if (!timedOut && row.keys.Length >= 1) {
            ExecuteComboSequence([row.keys[1]])
            FlashOSD(triggerKey . " -> " . row.keys[1])
        } else if (timedOut && row.keys.Length >= 2) {
            ExecuteComboSequence([row.keys[2]])
            FlashOSD(triggerKey . " -> " . row.keys[2])
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
    } else if (row.mode = "toggle" || row.mode = "press" || row.mode = "taphold") {
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

ReleaseAllHeldCombos() {
    global heldCombos, toggleActive, pressLatched, turboTimers, mouseHeld

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
    SyncBoxesToRows()

    outStr := "[REMAPPER_v8.16|NAME:" . currentProfile . "|EXE:" . targetExe . "|PANIC:" . panicKey . "]`n"
    for row in rows {
        if (row.trigger != "")
            outStr .= row.trigger . ">" . KeyListToString(row.keys) . ">" . row.mode . ";"
    }

    A_Clipboard := outStr
    NotifyUser("Profile '" . currentProfile . "' copied to clipboard!")
}

ImportProfile(*) {
    global profileDD, profilesDir
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
        }
    }
    IniWrite(validRows, targetPath, "Meta", "RowCount")
    IniWrite(pPanic, targetPath, "Meta", "PanicKey")
    IniWrite(tExe, targetPath, "Meta", "TargetExe")

    profileDD.OnEvent("Change", SwitchProfile, -1)
    profileDD.Delete()
    profileDD.Add(GetProfileList())
    profileDD.Choose(pName)
    profileDD.OnEvent("Change", SwitchProfile, 1)

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

    JoyCaptureTick() {
        if (!controllerEnabled)
            return
        if (XInputPoll()) {
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

    myGui := Gui("+Resize", "Combo ReMapper 8.16")
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
        dd := myGui.Add("DropDownList", "x+5 yp w75", ["Hold", "Toggle", "Press", "Turbo", "TapHold"])
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
OpenSettingsPanel(*) {
    global keyDelayDuration, keyDelayPress, mouseDelayDuration, soundAlerts, showTooltips, showOsd, osdLocked, osdToggleKey
    global customBgColor, customControlColor, customTextColor, configFile, myGui, currentTheme
    global controllerEnabled, controllerPollMs, compatMode, runAsAdmin

    settingsGui := Gui("+Owner" . myGui.Hwnd . " +ToolWindow", "Remapper Settings Panel")
    settingsGui.SetFont("s9")

    settingsGui.Add("GroupBox", "xm ym w340 h115", "Engine Delay & Speed (ms)")
    settingsGui.Add("Text", "x20 yp+28 w120", "Key Delay:")
    kdEdit := settingsGui.Add("Edit", "x150 yp-3 w60", keyDelayDuration)

    settingsGui.Add("Text", "x20 y+12 w120", "Press Duration:")
    kpEdit := settingsGui.Add("Edit", "x150 yp-3 w60", keyDelayPress)

    settingsGui.Add("Text", "x20 y+12 w120", "Mouse Delay:")
    mdEdit := settingsGui.Add("Edit", "x150 yp-3 w60", mouseDelayDuration)

    settingsGui.Add("GroupBox", "xm y+20 w340 h195", "System, OSD, Controller & Notifications")
    autoStartCB := settingsGui.Add("Checkbox", "x20 yp+25 " . (IsAutoStartEnabled() ? "Checked" : ""), "Auto-Start with Windows Startup")
    soundCB := settingsGui.Add("Checkbox", "x20 y+8 " . (soundAlerts ? "Checked" : ""), "Enable Audio Beep Alerts")
    tooltipCB := settingsGui.Add("Checkbox", "x20 y+8 " . (showTooltips ? "Checked" : ""), "Enable Overlay ToolTips")
    osdCB := settingsGui.Add("Checkbox", "x20 y+8 " . (showOsd ? "Checked" : ""), "Enable On-Screen Overlay (OSD)")
    osdLockCB := settingsGui.Add("Checkbox", "x20 y+8 " . (osdLocked ? "Checked" : ""), "Lock OSD Position (Click-Through)")
    controllerCB := settingsGui.Add("Checkbox", "x20 y+8 " . (controllerEnabled ? "Checked" : ""), "Enable Gamepad / Controller Support")

    settingsGui.Add("Text", "x20 y+10 w110", "OSD Toggle Key:")
    osdKeyBox := settingsGui.Add("Edit", "x130 yp-3 w60", osdToggleKey)
    osdCapBtn := settingsGui.Add("Button", "x+5 yp w45 h22", "Bind")
    osdCapBtn.OnEvent("Click", (*) => CaptureSingleKey(osdKeyBox))

    settingsGui.Add("GroupBox", "xm y+20 w340 h100", "Compatibility")
    settingsGui.Add("Text", "x20 yp+26 w80", "Input mode:")
    compatDD := settingsGui.Add("DropDownList", "x105 yp-3 w240 AltSubmit Choose" . compatMode, CompatModeNames())
    adminCB := settingsGui.Add("Checkbox", "x20 y+12 " . (runAsAdmin ? "Checked" : ""), "Run as Administrator (applies after restart)")

    settingsGui.Add("GroupBox", "xm y+20 w340 h195", "Controller and Mouse")
    settingsGui.Add("Text", "x20 yp+26 w70", "Xbox pad:")
    padDD := settingsGui.Add("DropDownList", "x95 yp-3 w95 AltSubmit Choose" . (padPort + 1), ["Auto", "Pad 1", "Pad 2", "Pad 3", "Pad 4"])
    settingsGui.Add("Text", "x200 yp+3 w70", "Trigger at:")
    trigEdit := settingsGui.Add("Edit", "x272 yp-3 w50", padTrigThresh)

    settingsGui.Add("Text", "x20 y+12 w70", "Mouse stick:")
    msDD := settingsGui.Add("DropDownList", "x95 yp-3 w95 AltSubmit Choose" . (padMouseStick + 1), ["Off", "Left stick", "Right stick"])
    settingsGui.Add("Text", "x200 yp+3 w70", "Speed px/s:")
    msSpeedEdit := settingsGui.Add("Edit", "x272 yp-3 w50", padMouseSpeed)

    settingsGui.Add("Text", "x20 y+12 w70", "Deadzone %:")
    msDeadEdit := settingsGui.Add("Edit", "x95 yp-3 w50", padMouseDead)
    settingsGui.Add("Text", "x200 yp+3 w70", "Curve:")
    msCurveEdit := settingsGui.Add("Edit", "x272 yp-3 w50", padMouseCurve)

    settingsGui.Add("Text", "x20 y+12 w70", "Scroll stick:")
    scDD := settingsGui.Add("DropDownList", "x95 yp-3 w95 AltSubmit Choose" . (padScrollStick + 1), ["Off", "Left stick", "Right stick"])
    settingsGui.Add("Text", "x200 yp+3 w70", "Ticks/s:")
    scSpeedEdit := settingsGui.Add("Edit", "x272 yp-3 w50", padScrollSpeed)

    settingsGui.Add("Text", "x20 y+12 w100", "Mouse speed %:")
    scaleEdit := settingsGui.Add("Edit", "x125 yp-3 w50", mouseScale)
    settingsGui.Add("Text", "x185 yp+3 w150", "(m / mm / mshake / mh)")

    settingsGui.Add("GroupBox", "xm y+20 w340 h115", "Custom RGB Theme Pickers (HEX)")
    settingsGui.Add("Text", "x20 yp+28 w130", "Window Background:")
    bgHexEdit := settingsGui.Add("Edit", "x150 yp-3 w70", customBgColor)

    settingsGui.Add("Text", "x20 y+12 w130", "Control Background:")
    ctrlHexEdit := settingsGui.Add("Edit", "x150 yp-3 w70", customControlColor)

    settingsGui.Add("Text", "x20 y+12 w130", "Text Color:")
    textHexEdit := settingsGui.Add("Edit", "x150 yp-3 w70", customTextColor)

    aboutBtn := settingsGui.Add("Button", "xm y+20 w110 h30", "About...")
    aboutBtn.OnEvent("Click", ShowAbout)
    saveBtn := settingsGui.Add("Button", "x+10 yp w110 h30", "Save Settings")
    saveBtn.OnEvent("Click", (*) => SaveSettingsAction())

    settingsGui.Show()

    SaveSettingsAction() {
        global keyDelayDuration, keyDelayPress, mouseDelayDuration, soundAlerts, showTooltips, showOsd, osdLocked, osdToggleKey
        global customBgColor, customControlColor, customTextColor, Themes, osdGui, scriptEnabled, currentTheme, configFile
        global controllerEnabled, compatMode, runAsAdmin, globalSettingsFile
        global padPort, padMouseStick, padScrollStick, padMouseSpeed, padMouseDead, padMouseCurve
        global padScrollSpeed, padTrigThresh, mouseScale

        ; Switch input mode: release anything held with the OLD method first
        if (compatDD.Value >= 1 && compatDD.Value != compatMode) {
            ReleaseAllHeldCombos()
            compatMode := compatDD.Value
            BuildTrayMenu()
        }
        newAdmin := adminCB.Value ? true : false
        if (newAdmin != runAsAdmin) {
            runAsAdmin := newAdmin
            try IniWrite(runAsAdmin ? 1 : 0, globalSettingsFile, "Global", "RunAsAdmin")
            MsgBox("The Administrator setting applies the next time the remapper starts.", "Combo ReMapper 8.16", "Iconi")
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
        padPort := padDD.Value - 1
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
            row.mode := (modeText = "Toggle") ? "toggle" : ((modeText = "Press") ? "press" : ((modeText = "Turbo") ? "turbo" : ((modeText = "TapHold") ? "taphold" : "hold")))
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
            rowUI[slotIdx].dd.Choose(row.mode = "toggle" ? 2 : (row.mode = "press" ? 3 : (row.mode = "turbo" ? 4 : (row.mode = "taphold" ? 5 : 1))))
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
        MsgBox("The panic toggle key cannot be blank. This is required for safety.", "Combo ReMapper 8.16", "Icon!")
        return
    }

    seenTriggers := Map()
    for row in rows {
        if (row.trigger = "")
            continue
        cleanTrig := RegExReplace(StrUpper(row.trigger), "^~")
        if (cleanTrig = StrUpper(panicKey)) {
            MsgBox("'" row.trigger "' is reserved for the panic toggle and can't be a trigger key. Nothing was saved.", "Combo ReMapper 8.16", "Icon!")
            return
        }
        if (seenTriggers.Has(cleanTrig)) {
            MsgBox("'" row.trigger "' is used as a trigger key on more than one row. Please make each trigger key unique.", "Combo ReMapper 8.16", "Icon!")
            return
        }
        seenTriggers[cleanTrig] := true
    }

    if (scrollTriggerKey != "") {
        if (StrUpper(scrollTriggerKey) = StrUpper(panicKey)) {
            MsgBox("The scroll-click key can't be the panic toggle. Nothing was saved.", "Combo ReMapper 8.16", "Icon!")
            return
        }
        if (seenTriggers.Has(StrUpper(scrollTriggerKey))) {
            MsgBox("The scroll-click key ('" scrollTriggerKey "') is the same as one of your row trigger keys. Pick a different one.", "Combo ReMapper 8.16", "Icon!")
            return
        }
    }

    ReleaseAllHeldCombos()

    RegisterRowHotkeys()
    RegisterScrollHotkey()
    RegisterPanicHotkey()
    RegisterOsdHotkey()

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