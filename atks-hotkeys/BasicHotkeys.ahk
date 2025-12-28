#Requires AutoHotkey v2.0
#SingleInstance Force

; =========================
; Configuration
; =========================

; Performance (reduce internal delays)
Perf_WinDelay        := -1
Perf_ControlDelay    := -1
Perf_KeyDelay        := -1
Perf_KeyPressDelay   := -1

; Keyboard layouts (HKL IDs)
LayoutId_EN  := "00000409" ; en-US
LayoutId_RU  := "00000419" ; ru-RU
LayoutId_UK  := "00000422" ; uk-UA
LayoutId_PL  := "00000415" ; pl-PL
KLF_ACTIVATE := 1

; Windows messages / timeouts for input language switching
MSG_INPUTLANGCHANGEREQUEST := 0x50
HWND_BROADCAST              := 0xFFFF
SMTO_ABORTIFHUNG            := 0x2
LangApplyTimeoutMs          := 20

; OSD appearance
Osd_BackColor     := "202020"
Osd_TextColor     := "FFFFFF"
Osd_FontName      := "Segoe UI"
Osd_FontSize      := 18
Osd_FontWeight    := 700
Osd_MarginX       := 14
Osd_MarginY       := 8
Osd_Width         := 200
Osd_Transparency  := 235
Osd_DurationMs    := 650
Osd_YOffset       := 140  ; positive = below center

; VirtualDesktopAccessor (required for virtual desktop hotkeys)
VDA_DllName := "VirtualDesktopAccessor.dll"

; Virtual desktop behavior
Move_FollowAfterMove := false

; =========================
; Apply configuration
; =========================

SetWinDelay Perf_WinDelay
SetControlDelay Perf_ControlDelay
SetKeyDelay Perf_KeyDelay, Perf_KeyPressDelay

; Key remaps
CapsLock::Esc
Esc::CapsLock

; Preload keyboard layouts
HKL_EN := DllCall("LoadKeyboardLayout", "Str", LayoutId_EN, "UInt", KLF_ACTIVATE, "Ptr")
HKL_RU := DllCall("LoadKeyboardLayout", "Str", LayoutId_RU, "UInt", KLF_ACTIVATE, "Ptr")
HKL_UK := DllCall("LoadKeyboardLayout", "Str", LayoutId_UK, "UInt", KLF_ACTIVATE, "Ptr")
HKL_PL := DllCall("LoadKeyboardLayout", "Str", LayoutId_PL, "UInt", KLF_ACTIVATE, "Ptr")

; =========================
; Helpers
; =========================

GetForegroundHwnd() {
    return DllCall("user32\GetForegroundWindow", "Ptr")
}

GetMonitorWorkAreaUnderMouse(&L, &T, &R, &B) {
    ; Center OSD on the monitor under the mouse cursor (fallback: primary monitor)
    MouseGetPos &mx, &my
    cnt := MonitorGetCount()
    Loop cnt {
        MonitorGetWorkArea(A_Index, &l, &t, &r, &b)
        if (mx >= l && mx < r && my >= t && my < b) {
            L := l, T := t, R := r, B := b
            return
        }
    }
    MonitorGetWorkArea(1, &L, &T, &R, &B)
}

; =========================
; OSD (center language label)
; =========================

global OsdGui := 0
global OsdText := 0

EnsureOsdGui() {
    global OsdGui, OsdText
    global Osd_BackColor, Osd_TextColor, Osd_FontName, Osd_FontSize, Osd_FontWeight
    global Osd_MarginX, Osd_MarginY, Osd_Width

    if OsdGui
        return

    OsdGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border +E0x20")
    OsdGui.MarginX := Osd_MarginX
    OsdGui.MarginY := Osd_MarginY
    OsdGui.BackColor := Osd_BackColor

    OsdGui.SetFont("s" Osd_FontSize " w" Osd_FontWeight, Osd_FontName)
    OsdText := OsdGui.AddText("c" Osd_TextColor " Center w" Osd_Width, "LANG")
}

ShowOsd(text, durationMs := "") {
    global OsdGui, OsdText
    global Osd_DurationMs, Osd_Transparency, Osd_YOffset

    if (durationMs = "")
        durationMs := Osd_DurationMs

    EnsureOsdGui()
    OsdText.Text := text

    OsdGui.Show("AutoSize Hide")
    OsdGui.GetPos(, , &w, &h)

    GetMonitorWorkAreaUnderMouse(&L, &T, &R, &B)
    x := L + (R - L - w) // 2
    y := T + (B - T - h) // 2 + Osd_YOffset

    OsdGui.Show("NoActivate x" x " y" y)
    WinSetTransparent Osd_Transparency, "ahk_id " OsdGui.Hwnd

    SetTimer HideOsd, 0
    SetTimer HideOsd, -durationMs
}

HideOsd() {
    global OsdGui
    if OsdGui
        OsdGui.Hide()
}

; =========================
; Input language switching (last request wins)
; =========================

global PendingHKL := 0
global PendingLabel := ""

RequestLayout(hkl, label) {
    global PendingHKL, PendingLabel
    PendingHKL := hkl
    PendingLabel := label

    SetTimer ApplyPendingLayout, 0
    SetTimer ApplyPendingLayout, -1
}

ApplyPendingLayout() {
    global PendingHKL, PendingLabel
    global MSG_INPUTLANGCHANGEREQUEST, HWND_BROADCAST, SMTO_ABORTIFHUNG, LangApplyTimeoutMs

    hkl := PendingHKL
    if !hkl
        return

    hwnd := GetForegroundHwnd()
    if hwnd {
        result := 0
        DllCall("SendMessageTimeout"
            , "Ptr", hwnd
            , "UInt", MSG_INPUTLANGCHANGEREQUEST
            , "Ptr", 0
            , "Ptr", hkl
            , "UInt", SMTO_ABORTIFHUNG
            , "UInt", LangApplyTimeoutMs
            , "PtrP", result)
    }

    PostMessage MSG_INPUTLANGCHANGEREQUEST, 0, hkl, , "ahk_id " HWND_BROADCAST

    if (PendingLabel != "")
        ShowOsd(PendingLabel)
}

; Layout hotkeys: Win+F/D/S/A
#f::RequestLayout(HKL_EN, "EN")
#d::RequestLayout(HKL_RU, "RU")
#s::RequestLayout(HKL_UK, "UK")
#a::RequestLayout(HKL_PL, "PL")

; =========================
; Virtual desktops (VirtualDesktopAccessor)
; =========================

FocusFix_BeforeDesktopSwitch() {
    ; Minimizes visual glitches by giving focus to the taskbar before switching
    hwndTray := WinExist("ahk_class Shell_TrayWnd")
    if hwndTray
        DllCall("user32\SetForegroundWindow", "Ptr", hwndTray)
}

global VDA_Ready := false

InitVDA() {
    global VDA_Ready, VDA_DllName
    dllPath := A_ScriptDir "\" VDA_DllName

    if !FileExist(dllPath) {
        MsgBox "Missing dependency:`n" dllPath "`nPlace " VDA_DllName " next to this script."
        return
    }

    h := DllCall("LoadLibrary", "Str", dllPath, "Ptr")
    if !h {
        MsgBox "LoadLibrary failed.`nA_LastError=" A_LastError
            . "`nCommon causes: 193 (bitness mismatch) or 126 (missing dependencies)."
        return
    }

    VDA_Ready := true
}
InitVDA()

GoToDesktop(n) {
    global VDA_Ready
    if !VDA_Ready
        return

    FocusFix_BeforeDesktopSwitch()
    DllCall("VirtualDesktopAccessor\GoToDesktopNumber", "Int", n - 1)
}

MoveActiveWindowToDesktop(n, follow := true) {
    global VDA_Ready
    if !VDA_Ready
        return

    hwnd := GetForegroundHwnd()
    if !hwnd
        return

    idx := n - 1
    DllCall("VirtualDesktopAccessor\MoveWindowToDesktopNumber", "Ptr", hwnd, "Int", idx)

    if follow {
        FocusFix_BeforeDesktopSwitch()
        DllCall("VirtualDesktopAccessor\GoToDesktopNumber", "Int", idx)
    }
}

; Desktop switch: Win+1..4
#1::GoToDesktop(1)
#2::GoToDesktop(2)
#3::GoToDesktop(3)
#4::GoToDesktop(4)

; Move active window: Ctrl+Win+1..9
#^1::MoveActiveWindowToDesktop(1, Move_FollowAfterMove)
#^2::MoveActiveWindowToDesktop(2, Move_FollowAfterMove)
#^3::MoveActiveWindowToDesktop(3, Move_FollowAfterMove)
#^4::MoveActiveWindowToDesktop(4, Move_FollowAfterMove)
#^5::MoveActiveWindowToDesktop(5, Move_FollowAfterMove)
#^6::MoveActiveWindowToDesktop(6, Move_FollowAfterMove)
#^7::MoveActiveWindowToDesktop(7, Move_FollowAfterMove)
#^8::MoveActiveWindowToDesktop(8, Move_FollowAfterMove)
#^9::MoveActiveWindowToDesktop(9, Move_FollowAfterMove)
