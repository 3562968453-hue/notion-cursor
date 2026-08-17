#NoEnv
#SingleInstance Force
#MaxHotkeysPerInterval 200
SetBatchLines -1
SetWinDelay, 0
SetFormat, FloatFast, 0.16
OnExit, Quit

PI := 3.141592653589793
RAD := PI / 180.0
J2000 := 2451545.0
E_OBL := RAD * 23.4397
TZ := 8
INI := A_ScriptDir . "\sunrise-countdown.ini"
KuGouIni := A_AppData . "\KuGou8\KuGou.ini"
LyricFontName := "霞鹜文楷 轻便版 Medium"
LyricFontItalic := 0
LyricFontWeight := 500

; Wallpaper mist plaque + IronMan Time (Facon / orange-yellow)
ColFill   := 0x62D6E8EE
ColStroke := 0x55E0C97A
ColOrange := 0xFFF16624
ColOrange2 := 0xFFFFDD18
ColLav    := 0xFFB89AD8
ColBlue   := 0xFF2A96D4
ColBlue2  := 0xFF7EC8F0
ColInk    := 0xFFF2F4F6
ColCnt1   := 0xFFFFFFFF
ColCnt2   := 0xFFC5CCD4
ColIvory  := 0xFFF7F4EE
ColMuted  := 0xFF5C6B78
FaconFam := 0
pFaconColl := 0

Cities := "
(
北京|39.9042|116.4074
上海|31.2304|121.4737
广州|23.1291|113.2644
深圳|22.5431|114.0579
杭州|30.2741|120.1551
成都|30.5728|104.0668
武汉|30.5928|114.3055
西安|34.3416|108.9398
南京|32.0603|118.7969
重庆|29.4316|106.9123
天津|39.3434|117.3616
苏州|31.2989|120.5853
长沙|28.2282|112.9388
郑州|34.7466|113.6253
青岛|36.0671|120.3826
沈阳|41.8057|123.4315
合肥|31.8206|117.2273
福州|26.0745|119.2965
厦门|24.4798|118.0894
昆明|25.0406|102.7123
哈尔滨|45.8038|126.5350
济南|36.6512|117.1201
大连|38.9140|121.6147
香港|22.3193|114.1694
台北|25.0330|121.5654
)"

IniRead, CityName, %INI%, Location, City, 北京
IniRead, Lat, %INI%, Location, Lat, 39.9042
IniRead, Lon, %INI%, Location, Lon, 116.4074
IniRead, PosX, %INI%, Window, X, -1
IniRead, PosY, %INI%, Window, Y, -1
IniRead, PinTop, %INI%, Window, AlwaysOnTop, 0
IniRead, UiScale, %INI%, Window, Scale, 1.0
UiScale := UiScale + 0.0
if (UiScale < 0.35)
    UiScale := 0.35
if (UiScale > 3.0)
    UiScale := 3.0
BaseW := 500
BaseH := 280

word := "距日落"
cnt := "00:00"
riseTxt := "--:--"
setTxt := "--:--"
sunT := 0
HoverOn := 0
BgFade := 0.0
FadeFrom := 0.0
FadeTo := 0.0
FadeT0 := 0
FadeDur := 320

Menu, Tray, Icon, shell32.dll, 169
Menu, Tray, NoStandard
Menu, Tray, Add, 选择城市, ShowCityPicker
Menu, Tray, Add, 始终置顶, ToggleTop
Menu, Tray, Add
Menu, Tray, Add, 退出, Quit
Menu, Tray, Tip, 日出日落倒计时
Menu, Tray, Icon
Menu, Ctx, Add, 选择城市, ShowCityPicker
Menu, Ctx, Add, 始终置顶, ToggleTop
Menu, Ctx, Add
Menu, Ctx, Add, 退出, Quit
if (PinTop = 1)
{
    Menu, Tray, Check, 始终置顶
    Menu, Ctx, Check, 始终置顶
}

WaitForDesktop()
SysGet, WA, MonitorWorkArea
sysDpi := DllCall("user32\GetDpiForSystem", "UInt")
if (sysDpi < 96)
    sysDpi := 96
ApplyUiSize()
if (PosX = -1 || PosY = -1)
{
    PosX := WARight - GuiW - 28
    PosY := WATop + 28
}

pToken := GdipStartup()
LoadFaconFont()
LoadLyricFont()
Gui, +HwndGuiHwnd -Caption +ToolWindow +E0x80000 +LastFound
Gui, Show, x%PosX% y%PosY% w%GuiW% h%GuiH% NA, 日出日落
if (PinTop = 1)
    WinSet, AlwaysOnTop, On, ahk_id %GuiHwnd%
ApplyCardRegion()
WinGetPos, bootX, bootY,,, ahk_id %GuiHwnd%
MagnetMove(bootX, bootY)

OnMessage(0x201, "WM_LBUTTONDOWN")
OnMessage(0x20A, "WM_MOUSEWHEEL")
OnMessage(0x0232, "OnExitSizeMove")
CalcSun()
UpdateCount()
SetTimer, UpdateCount, 1000
SetTimer, SavePos, 8000
SetTimer, LoadLyricFont, 2500
SetTimer, CheckHover, 30
BootPass := 0
SetTimer, BootSettle, 900
return

GuiContextMenu:
Menu, Ctx, Show
return

WM_LBUTTONDOWN()
{
    global GuiHwnd, GuiW, GuiH, HoverOn
    HoverOn := 1
    StartFade(1.0)
    CoordMode, Mouse, Screen
    MouseGetPos, mx, my
    WinGetPos, wx, wy,,, ahk_id %GuiHwnd%
    offx := mx - wx
    offy := my - wy
    while GetKeyState("LButton", "P")
    {
        MouseGetPos, mx, my
        nx := mx - offx
        ny := my - offy
        MagnetMove(nx, ny)
        Sleep, 10
    }
    WinGetPos, x, y,,, ahk_id %GuiHwnd%
    MagnetMove(x, y)
    SaveWindowPos()
    CheckHover()
}

OnExitSizeMove()
{
    global GuiHwnd
    WinGetPos, x, y,,, ahk_id %GuiHwnd%
    MagnetMove(x, y)
    SaveWindowPos()
}

ApplyUiSize()
{
    global GuiW, GuiH, UiSW, UiSH, UiScale, sysDpi, BaseW, BaseH
    GuiW := Round(BaseW * sysDpi / 96 * UiScale)
    GuiH := Round(BaseH * sysDpi / 96 * UiScale)
    if (GuiW < 160)
        GuiW := 160
    if (GuiH < 90)
        GuiH := 90
    UiSW := GuiW / BaseW
    UiSH := GuiH / BaseH
}

WM_MOUSEWHEEL(wParam, lParam, msg, hwnd)
{
    global GuiHwnd, UiScale
    if (hwnd != GuiHwnd)
        return
    wheel := (wParam >> 16) & 0xFFFF
    if (wheel > 32767)
        wheel -= 65536
    if (wheel = 0)
        return 0
    if (wheel > 0)
        SetOverlayScale(UiScale * 1.10)
    else
        SetOverlayScale(UiScale / 1.10)
    return 0
}

SetOverlayScale(newScale)
{
    global GuiHwnd, GuiW, GuiH, UiScale, ScaleTick
    now := A_TickCount
    if (ScaleTick != "" && now - ScaleTick < 50)
        return
    if (newScale < 0.35)
        newScale := 0.35
    if (newScale > 3.0)
        newScale := 3.0
    if (Abs(newScale - UiScale) < 0.0005)
        return
    ScaleTick := now
    WinGetPos, x, y, oldW, oldH, ahk_id %GuiHwnd%
    if (oldW < 10)
        oldW := GuiW
    if (oldH < 10)
        oldH := GuiH
    cx := x + oldW // 2
    cy := y + oldH // 2
    UiScale := newScale
    ApplyUiSize()
    nx := cx - GuiW // 2
    ny := cy - GuiH // 2
    WinMove, ahk_id %GuiHwnd%,, %nx%, %ny%, %GuiW%, %GuiH%
    MagnetMove(nx, ny)
    DrawCard()
    SaveWindowPos()
}

MagnetMove(nx, ny)
{
    global GuiHwnd, GuiW, GuiH
    WinGetPos, , , w, h, ahk_id %GuiHwnd%
    if (w < 10)
        w := GuiW
    if (h < 10)
        h := GuiH
    thresh := 36
    cx := nx + w // 2
    cy := ny + h // 2
    GetScreen(cx, cy, L, T, R, B)
    if (Abs(nx - L) <= thresh)
        nx := L
    else if (Abs((nx + w) - R) <= thresh)
        nx := R - w
    if (Abs(ny - T) <= thresh)
        ny := T
    else if (Abs((ny + h) - B) <= thresh)
        ny := B - h
    if (w > R - L)
        nx := L
    else if (nx < L)
        nx := L
    else if (nx + w > R)
        nx := R - w
    if (h > B - T)
        ny := T
    else if (ny < T)
        ny := T
    else if (ny + h > B)
        ny := B - h
    WinMove, ahk_id %GuiHwnd%,, %nx%, %ny%
}

GetScreen(cx, cy, ByRef L, ByRef T, ByRef R, ByRef B)
{
    SysGet, cnt, MonitorCount
    Loop, %cnt%
    {
        SysGet, Mon, Monitor, %A_Index%
        if (cx >= MonLeft && cx < MonRight && cy >= MonTop && cy < MonBottom)
        {
            L := MonLeft, T := MonTop, R := MonRight, B := MonBottom
            return
        }
    }
    SysGet, Mon, Monitor
    L := MonLeft, T := MonTop, R := MonRight, B := MonBottom
}

GetWorkArea(cx, cy, ByRef L, ByRef T, ByRef R, ByRef B)
{
    SysGet, cnt, MonitorCount
    Loop, %cnt%
    {
        SysGet, Mon, MonitorWorkArea, %A_Index%
        if (cx >= MonLeft && cx < MonRight && cy >= MonTop && cy < MonBottom)
        {
            L := MonLeft, T := MonTop, R := MonRight, B := MonBottom
            return
        }
    }
    SysGet, Mon, MonitorWorkArea
    L := MonLeft, T := MonTop, R := MonRight, B := MonBottom
}

SaveWindowPos()
{
    global GuiHwnd, INI, UiScale
    WinGetPos, x, y,,, ahk_id %GuiHwnd%
    if (x != "" && y != "")
    {
        IniWrite, %x%, %INI%, Window, X
        IniWrite, %y%, %INI%, Window, Y
    }
    s := Round(UiScale * 100) / 100
    IniWrite, %s%, %INI%, Window, Scale
}

CheckHover()
{
    global GuiHwnd, HoverOn
    CoordMode, Mouse, Screen
    MouseGetPos, mx, my, hwndUnder
    inside := (hwndUnder = GuiHwnd)
    if GetKeyState("LButton", "P")
        inside := 1
    if (inside = HoverOn)
        return
    HoverOn := inside
    StartFade(inside ? 1.0 : 0.0)
}

StartFade(target)
{
    global BgFade, FadeFrom, FadeTo, FadeT0, FadeDur
    target := target + 0.0
    if (Abs(target - FadeTo) < 0.001 && Abs(BgFade - target) < 0.01)
        return
    FadeFrom := BgFade + 0.0
    FadeTo := target
    FadeT0 := A_TickCount
    FadeDur := Round(340 * Abs(FadeTo - FadeFrom))
    if (FadeDur < 120)
        FadeDur := 120
    SetTimer, FadeTick, 15
}

FadeTick()
{
    global BgFade, FadeFrom, FadeTo, FadeT0, FadeDur
    Critical
    t := (A_TickCount - FadeT0) / (FadeDur + 0.0)
    if (t >= 1.0)
    {
        BgFade := FadeTo
        SetTimer, FadeTick, Off
    }
    else
    {
        if (t < 0)
            t := 0
        e := SmootherStep(t)
        BgFade := FadeFrom + (FadeTo - FadeFrom) * e
    }
    DrawCard()
}

SmootherStep(t)
{
    if (t < 0)
        t := 0
    if (t > 1)
        t := 1
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
}

MixBgFill(fade)
{
    global ColFill
    a0 := 2, r0 := 255, g0 := 255, b0 := 255
    a1 := (ColFill >> 24) & 255
    r1 := (ColFill >> 16) & 255
    g1 := (ColFill >> 8) & 255
    b1 := ColFill & 255
    a := Round(a0 + (a1 - a0) * fade)
    r := Round(r0 + (r1 - r0) * fade)
    g := Round(g0 + (g1 - g0) * fade)
    b := Round(b0 + (b1 - b0) * fade)
    return (a << 24) | (r << 16) | (g << 8) | b
}

Pad2(n)
{
    n := n + 0
    return (n < 10 ? "0" : "") . n
}

WaitForDesktop()
{
    t0 := A_TickCount
    while (A_TickCount - t0 < 20000)
    {
        if WinExist("ahk_class Shell_TrayWnd") && WinExist("ahk_class Progman")
            break
        Sleep, 40
    }
    Sleep, 80
}

BootSettle()
{
    global GuiHwnd, PinTop, BootPass
    BootPass += 1
    WinSet, AlwaysOnTop, On, ahk_id %GuiHwnd%
    if (PinTop != 1)
        WinSet, AlwaysOnTop, Off, ahk_id %GuiHwnd%
    DrawCard()
    if (BootPass >= 4)
        SetTimer, BootSettle, Off
}

GdipStartup()
{
    if !DllCall("kernel32\GetModuleHandle", "Str", "gdiplus", "Ptr")
        DllCall("kernel32\LoadLibrary", "Str", "gdiplus", "Ptr")
    VarSetCapacity(si, 24, 0)
    NumPut(1, si, 0, "UInt")
    DllCall("gdiplus\GdiplusStartup", "Ptr*", token, "Ptr", &si, "Ptr", 0)
    return token
}

LoadFaconFont()
{
    global FaconFam, pFaconColl
    FaconFam := 0
    pFaconColl := 0
    DllCall("gdiplus\GdipNewPrivateFontCollection", "Ptr*", pFaconColl)
    pFonts := A_ScriptDir . "\fonts\Facon.ttf"
    p1 := A_ScriptDir . "\runtime\Facon.ttf"
    p2 := "D:\我的文档\Rainmeter\Skins\IronMan_Suite\@Resources\Fonts\Facon.ttf"
    loaded := 0
    if FileExist(pFonts)
    {
        if !DllCall("gdiplus\GdipPrivateAddFontFile", "Ptr", pFaconColl, "Str", pFonts)
            loaded := 1
    }
    if (!loaded && FileExist(p1))
    {
        if !DllCall("gdiplus\GdipPrivateAddFontFile", "Ptr", pFaconColl, "Str", p1)
            loaded := 1
    }
    if (!loaded && FileExist(p2))
    {
        if !DllCall("gdiplus\GdipPrivateAddFontFile", "Ptr", pFaconColl, "Str", p2)
            loaded := 1
    }
    if (loaded)
        DllCall("gdiplus\GdipCreateFontFamilyFromName", "Str", "Facon", "Ptr", pFaconColl, "Ptr*", FaconFam)
    if (!FaconFam)
        DllCall("gdiplus\GdipCreateFontFamilyFromName", "Str", "Facon", "Ptr", 0, "Ptr*", FaconFam)
}

LoadLyricFont()
{
    global KuGouIni, LyricFontName, LyricFontItalic, LyricFontWeight
    IniRead, n, %KuGouIni%, LyricConfigSection, DesktopVertLyricFontName, 霞鹜文楷 轻便版 Medium
    IniRead, it, %KuGouIni%, LyricConfigSection, DesktopVertLyricFontItalic, 0
    IniRead, wt, %KuGouIni%, LyricConfigSection, DesktopVertLyricFontWeight, 500
    if (n = "" || n = "ERROR")
        n := "霞鹜文楷 轻便版 Medium"
    LyricFontName := n
    LyricFontItalic := it + 0
    LyricFontWeight := wt + 0
}

DrawCard()
{
    global GuiHwnd, GuiW, GuiH, UiSW, UiSH, ColFill, ColStroke, ColOrange, ColLav, ColBlue, ColInk, word, cnt, riseTxt, setTxt, sunT, BgFade
    w := GuiW, h := GuiH

    DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", w, "Int", h, "Int", 0, "Int", 0xE200B, "Ptr", 0, "Ptr*", pBmp)
    DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBmp, "Ptr*", G)
    DllCall("gdiplus\GdipGraphicsClear", "Ptr", G, "UInt", 0x00000000)
    DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", G, "Int", 4)
    DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", G, "Int", 4)

    DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0x0CFFFFFF, "Ptr*", bHit)
    DllCall("gdiplus\GdipFillRectangle", "Ptr", G, "Ptr", bHit, "Float", 0.0, "Float", 0.0, "Float", w, "Float", h)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", bHit)

    cx := w * 0.5
    a0 := 232.0
    a1 := 308.0
    rArc := w * 0.58
    arcPeak := h * 0.07
    arcCy := arcPeak + rArc
    DrawSunArc(G, cx, arcCy, rArc, a0, a1, w * 0.011, 0.16)
    DrawSunArc(G, cx, arcCy, rArc, a0, a1, w * 0.0044, 1.0)
    t := sunT
    if (t < 0)
        t := 0
    if (t > 1)
        t := 1
    ang := (a0 + (a1 - a0) * t) * 0.0174532925199433
    sx := cx + rArc * Cos(ang)
    sy := arcCy + rArc * Sin(ang)
    colDot := ArcColor(t)
    dGlow := w * 0.014
    dDot := w * 0.006
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", GlowColor(colDot, 0x55), "Ptr*", bGlow)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", G, "Ptr", bGlow, "Float", sx - dGlow, "Float", sy - dGlow, "Float", dGlow * 2, "Float", dGlow * 2)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", bGlow)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", colDot, "Ptr*", bDot)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", G, "Ptr", bDot, "Float", sx - dDot, "Float", sy - dDot, "Float", dDot * 2, "Float", dDot * 2)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", bDot)
    iconS := 0.92
    iconLift := h * 0.07
    rad0 := a0 * 0.0174532925199433
    rad1 := a1 * 0.0174532925199433
    DrawSunIcon(G, cx + (rArc + iconLift) * Cos(rad0), arcCy + (rArc + iconLift) * Sin(rad0), ColOrange, iconS)
    DrawMoonIcon(G, cx + (rArc + iconLift) * Cos(rad1), arcCy + (rArc + iconLift) * Sin(rad1), ColBlue, iconS)

    DrawEffectText(G, cnt, w * 0.04, h * 0.26, w * 0.92, h * 0.20, h * 0.175, 1, 1)
    DrawEffectText(G, riseTxt, w * 0.06, h * 0.44, w * 0.40, h * 0.15, h * 0.105, 1, 2)
    DrawEffectText(G, setTxt, w * 0.54, h * 0.44, w * 0.40, h * 0.15, h * 0.105, 1, 3)

    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBmp, "Ptr*", hbm, "UInt", 0)
    hdc := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
    obm := DllCall("SelectObject", "Ptr", hdc, "Ptr", hbm, "Ptr")
    VarSetCapacity(sz, 8, 0)
    NumPut(w, sz, 0, "UInt"), NumPut(h, sz, 4, "UInt")
    VarSetCapacity(ptSrc, 8, 0)
    VarSetCapacity(blend, 4, 0)
    NumPut(0, blend, 0, "UChar")
    NumPut(0, blend, 1, "UChar")
    NumPut(255, blend, 2, "UChar")
    NumPut(1, blend, 3, "UChar")
    DllCall("UpdateLayeredWindow", "Ptr", GuiHwnd, "Ptr", 0, "Ptr", 0, "Ptr", &sz, "Ptr", hdc, "Ptr", &ptSrc, "UInt", 0, "Ptr", &blend, "UInt", 2)
    DllCall("SelectObject", "Ptr", hdc, "Ptr", obm, "Ptr")
    DllCall("DeleteObject", "Ptr", hbm)
    DllCall("DeleteDC", "Ptr", hdc)
    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", G)
    DllCall("gdiplus\GdipDisposeImage", "Ptr", pBmp)
}

DrawSunIcon(G, cx, cy, col, s)
{
    if (s = "")
        s := 2.2
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", GlowColor(col, 0x50), "Ptr*", bGlow)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", G, "Ptr", bGlow, "Float", cx - 11 * s, "Float", cy - 11 * s, "Float", 22 * s, "Float", 22 * s)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", bGlow)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", col, "Ptr*", b)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", G, "Ptr", b, "Float", cx - 6.2 * s, "Float", cy - 6.2 * s, "Float", 12.4 * s, "Float", 12.4 * s)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", b)
    DllCall("gdiplus\GdipCreatePen1", "UInt", col, "Float", 1.8 * s, "Int", 2, "Ptr*", pPen)
    DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPen, "Int", 2)
    DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPen, "Int", 2)
    Loop, 8
    {
        ang := (A_Index - 1) * 0.7853981633974483
        x0 := cx + 8.2 * s * Cos(ang), y0 := cy + 8.2 * s * Sin(ang)
        x1 := cx + 12.4 * s * Cos(ang), y1 := cy + 12.4 * s * Sin(ang)
        DllCall("gdiplus\GdipDrawLine", "Ptr", G, "Ptr", pPen, "Float", x0, "Float", y0, "Float", x1, "Float", y1)
    }
    DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
}

DrawMoonIcon(G, cx, cy, col, s)
{
    if (s = "")
        s := 2.2
    d := 14.0 * s
    x := cx - d / 2.0
    y := cy - d / 2.0
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", GlowColor(col, 0x50), "Ptr*", bGlow)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", G, "Ptr", bGlow, "Float", cx - 12 * s, "Float", cy - 12 * s, "Float", 24 * s, "Float", 24 * s)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", bGlow)
    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pMoon)
    DllCall("gdiplus\GdipAddPathEllipse", "Ptr", pMoon, "Float", x, "Float", y, "Float", d, "Float", d)
    DllCall("gdiplus\GdipCreateRegionPath", "Ptr", pMoon, "Ptr*", rgn)
    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pCut)
    DllCall("gdiplus\GdipAddPathEllipse", "Ptr", pCut, "Float", x - 5.0 * s, "Float", y - 1.2 * s, "Float", d, "Float", d)
    DllCall("gdiplus\GdipCombineRegionPath", "Ptr", rgn, "Ptr", pCut, "Int", 4)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", col, "Ptr*", b)
    DllCall("gdiplus\GdipFillRegion", "Ptr", G, "Ptr", b, "Ptr", rgn)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", b)
    DllCall("gdiplus\GdipDeleteRegion", "Ptr", rgn)
    DllCall("gdiplus\GdipDeletePath", "Ptr", pCut)
    DllCall("gdiplus\GdipDeletePath", "Ptr", pMoon)
}

DrawSunArc(G, cx, cy, r, a0, a1, width, alphaScale)
{
    segs := 64
    Loop, %segs%
    {
        t0 := (A_Index - 1) / segs
        t1 := A_Index / segs
        rad0 := (a0 + (a1 - a0) * t0) * 0.0174532925199433
        rad1 := (a0 + (a1 - a0) * t1) * 0.0174532925199433
        x0 := cx + r * Cos(rad0), y0 := cy + r * Sin(rad0)
        x1 := cx + r * Cos(rad1), y1 := cy + r * Sin(rad1)
        col := GlowColor(ArcColor((t0 + t1) / 2.0), Round(255 * alphaScale))
        DllCall("gdiplus\GdipCreatePen1", "UInt", col, "Float", width, "Int", 2, "Ptr*", pPen)
        DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPen, "Int", 2)
        DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPen, "Int", 2)
        DllCall("gdiplus\GdipDrawLine", "Ptr", G, "Ptr", pPen, "Float", x0, "Float", y0, "Float", x1, "Float", y1)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
    }
}

ArcColor(t)
{
    global ColOrange, ColLav, ColBlue
    if (t < 0.5)
        return LerpColor(ColOrange, ColLav, t / 0.5)
    return LerpColor(ColLav, ColBlue, (t - 0.5) / 0.5)
}

LerpColor(c1, c2, t)
{
    if (t < 0)
        t := 0
    if (t > 1)
        t := 1
    a1 := (c1 >> 24) & 255, r1 := (c1 >> 16) & 255, g1 := (c1 >> 8) & 255, b1 := c1 & 255
    a2 := (c2 >> 24) & 255, r2 := (c2 >> 16) & 255, g2 := (c2 >> 8) & 255, b2 := c2 & 255
    a := Round(a1 + (a2 - a1) * t)
    r := Round(r1 + (r2 - r1) * t)
    g := Round(g1 + (g2 - g1) * t)
    b := Round(b1 + (b2 - b1) * t)
    return (a << 24) | (r << 16) | (g << 8) | b
}

GlowColor(c, a)
{
    r := (c >> 16) & 255, g := (c >> 8) & 255, b := c & 255
    return (a << 24) | (r << 16) | (g << 8) | b
}

DesatColor(c, cut)
{
    if (cut < 0)
        cut := 0
    if (cut > 1)
        cut := 1
    a := (c >> 24) & 255
    r := (c >> 16) & 255
    g := (c >> 8) & 255
    b := c & 255
    y := 0.299 * r + 0.587 * g + 0.114 * b
    r := Round(r + (y - r) * cut)
    g := Round(g + (y - g) * cut)
    b := Round(b + (y - b) * cut)
    return (a << 24) | (r << 16) | (g << 8) | b
}

ATan2(y, x)
{
    global PI
    if (x > 0)
        return ATan(y / x)
    if (x < 0)
    {
        if (y >= 0)
            return ATan(y / x) + PI
        return ATan(y / x) - PI
    }
    if (y > 0)
        return PI / 2.0
    if (y < 0)
        return -PI / 2.0
    return 0.0
}

CatPt(cx, cy, rx, ry, deg, ByRef ox, ByRef oy)
{
    global PI
    rad := deg * PI / 180.0
    ox := cx + rx * Cos(rad)
    oy := cy + ry * Sin(rad)
}

CatGeom(bw, bh, ByRef cx, ByRef cy, ByRef rx, ByRef ry)
{
    pad := 3.0
    earLift := 1.12
    chin := 1.08
    ry := (bh - pad * 2.0) / (earLift + chin)
    rx := (bw - pad * 2.0) / 2.0
    cx := bw * 0.5
    cy := pad + ry * earLift
}

CatPath(x, y, bw, bh)
{
    CatGeom(bw, bh, cx, cy, rx, ry)
    cx := cx + x
    cy := cy + y
    aLO := 208.0
    aLI := 244.0
    aRI := 296.0
    aRO := 332.0
    CatPt(cx, cy, rx, ry, aLO, xLO, yLO)
    CatPt(cx, cy, rx, ry, aLI, xLI, yLI)
    CatPt(cx, cy, rx, ry, aRI, xRI, yRI)
    CatPt(cx, cy, rx, ry, aRO, xRO, yRO)
    tipY := cy - ry * 1.14
    if (tipY < y + 2.0)
        tipY := y + 2.0
    xLT := cx - rx * 0.34
    xRT := cx + rx * 0.34
    rOff := ry * 0.28
    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pPath)
    DllCall("gdiplus\GdipAddPathBezier", "Ptr", pPath, "Float", xLO, "Float", yLO, "Float", xLT - rOff, "Float", tipY + rOff, "Float", xLT + rOff * 0.45, "Float", tipY + rx * 0.04, "Float", xLI, "Float", yLI)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", cx - rx, "Float", cy - ry, "Float", rx * 2.0, "Float", ry * 2.0, "Float", aLI, "Float", aRI - aLI)
    DllCall("gdiplus\GdipAddPathBezier", "Ptr", pPath, "Float", xRI, "Float", yRI, "Float", xRT - rOff * 0.45, "Float", tipY + rx * 0.04, "Float", xRT + rOff, "Float", tipY + rOff, "Float", xRO, "Float", yRO)
    sweep := aLO + 360.0 - aRO
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", cx - rx, "Float", cy - ry, "Float", rx * 2.0, "Float", ry * 2.0, "Float", aRO, "Float", sweep)
    DllCall("gdiplus\GdipClosePathFigure", "Ptr", pPath)
    return pPath
}

DrawCatFaceExtras(G, cx, cy, rx, ry, fade)
{
    global ColStroke, ColOrange
    if (fade < 0.03)
        return
    aEar := Round(120 * fade)
    aBlush := Round(78 * fade)
    aNose := Round(170 * fade)
    aLine := Round(175 * fade)
    aPaw := Round(95 * fade)
    tipY := cy - ry * 1.12
    xLT := cx - rx * 0.34
    xRT := cx + rx * 0.34
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", GlowColor(0xFFFFB7C5, aEar), "Ptr*", bEar)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", G, "Ptr", bEar, "Float", xLT - ry * 0.12, "Float", tipY + ry * 0.22, "Float", ry * 0.28, "Float", ry * 0.32)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", G, "Ptr", bEar, "Float", xRT - ry * 0.16, "Float", tipY + ry * 0.22, "Float", ry * 0.28, "Float", ry * 0.32)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", bEar)
    bw := rx * 0.11
    bh := ry * 0.11
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", GlowColor(0xFFFF8FA3, aBlush), "Ptr*", bBl)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", G, "Ptr", bBl, "Float", cx - rx * 0.52, "Float", cy + ry * 0.02, "Float", bw, "Float", bh)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", G, "Ptr", bBl, "Float", cx + rx * 0.41, "Float", cy + ry * 0.02, "Float", bw, "Float", bh)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", bBl)
    nw := ry * 0.10
    nh := ry * 0.07
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", GlowColor(0xFFFF8FAB, aNose), "Ptr*", bN)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", G, "Ptr", bN, "Float", cx - nw / 2.0, "Float", cy - nh * 0.15, "Float", nw, "Float", nh)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", bN)
    DllCall("gdiplus\GdipCreatePen1", "UInt", GlowColor(ColStroke, aLine), "Float", ry * 0.016, "Int", 2, "Ptr*", pW)
    DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pW, "Int", 2)
    DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pW, "Int", 2)
    nx0 := cx - nw * 0.85
    ny0 := cy + nh * 0.40
    DllCall("gdiplus\GdipDrawLine", "Ptr", G, "Ptr", pW, "Float", nx0, "Float", ny0 - ry * 0.03, "Float", cx - rx * 0.78, "Float", cy - ry * 0.16)
    DllCall("gdiplus\GdipDrawLine", "Ptr", G, "Ptr", pW, "Float", nx0, "Float", ny0, "Float", cx - rx * 0.84, "Float", cy + ry * 0.04)
    DllCall("gdiplus\GdipDrawLine", "Ptr", G, "Ptr", pW, "Float", nx0, "Float", ny0 + ry * 0.03, "Float", cx - rx * 0.74, "Float", cy + ry * 0.22)
    nx1 := cx + nw * 0.85
    DllCall("gdiplus\GdipDrawLine", "Ptr", G, "Ptr", pW, "Float", nx1, "Float", ny0 - ry * 0.03, "Float", cx + rx * 0.78, "Float", cy - ry * 0.16)
    DllCall("gdiplus\GdipDrawLine", "Ptr", G, "Ptr", pW, "Float", nx1, "Float", ny0, "Float", cx + rx * 0.84, "Float", cy + ry * 0.04)
    DllCall("gdiplus\GdipDrawLine", "Ptr", G, "Ptr", pW, "Float", nx1, "Float", ny0 + ry * 0.03, "Float", cx + rx * 0.74, "Float", cy + ry * 0.22)
    DllCall("gdiplus\GdipDrawArc", "Ptr", G, "Ptr", pW, "Float", cx - ry * 0.08, "Float", cy + nh * 0.55, "Float", ry * 0.16, "Float", ry * 0.12, "Float", 20.0, "Float", 140.0)
    DllCall("gdiplus\GdipDeletePen", "Ptr", pW)
    DllCall("gdiplus\GdipCreatePen1", "UInt", GlowColor(ColOrange, aLine), "Float", ry * 0.038, "Int", 2, "Ptr*", pC)
    DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pC, "Int", 2)
    DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pC, "Int", 2)
    DllCall("gdiplus\GdipDrawArc", "Ptr", G, "Ptr", pC, "Float", cx - rx * 0.18, "Float", cy + ry * 0.72, "Float", rx * 0.36, "Float", ry * 0.28, "Float", 18.0, "Float", 144.0)
    DllCall("gdiplus\GdipDeletePen", "Ptr", pC)
    bell := ry * 0.10
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", GlowColor(ColOrange, aNose), "Ptr*", bBell)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", G, "Ptr", bBell, "Float", cx - bell / 2.0, "Float", cy + ry * 0.88, "Float", bell, "Float", bell)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", bBell)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", GlowColor(0xFFFFE08A, Round(200 * fade)), "Ptr*", bDot)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", G, "Ptr", bDot, "Float", cx - bell * 0.16, "Float", cy + ry * 0.90, "Float", bell * 0.32, "Float", bell * 0.32)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", bDot)
    pw := ry * 0.22
    ph := ry * 0.16
    py := cy + ry * 0.86
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", GlowColor(0xFFFFB7C5, aPaw), "Ptr*", bPaw)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", G, "Ptr", bPaw, "Float", cx - rx * 0.72, "Float", py, "Float", pw, "Float", ph)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", G, "Ptr", bPaw, "Float", cx + rx * 0.72 - pw, "Float", py, "Float", pw, "Float", ph)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", bPaw)
    bean := ry * 0.035
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", GlowColor(0xFFFF8FA3, aPaw + 20), "Ptr*", bBean)
    Loop, 3
    {
        bx := cx - rx * 0.72 + pw * 0.18 + (A_Index - 1) * pw * 0.26
        DllCall("gdiplus\GdipFillEllipse", "Ptr", G, "Ptr", bBean, "Float", bx, "Float", py + ph * 0.22, "Float", bean, "Float", bean * 1.15)
        bx2 := cx + rx * 0.72 - pw + pw * 0.18 + (A_Index - 1) * pw * 0.26
        DllCall("gdiplus\GdipFillEllipse", "Ptr", G, "Ptr", bBean, "Float", bx2, "Float", py + ph * 0.22, "Float", bean, "Float", bean * 1.15)
    }
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", bBean)
}

DrawCuteText(G, str, x, y, w, h, size, argb, align)
{
    global LyricFontName
    fam := 0
    DllCall("gdiplus\GdipCreateFontFamilyFromName", "Str", LyricFontName, "Ptr", 0, "Ptr*", fam)
    if (!fam)
        DllCall("gdiplus\GdipCreateFontFamilyFromName", "Str", "微软雅黑", "Ptr", 0, "Ptr*", fam)
    if (!fam)
        DllCall("gdiplus\GdipCreateFontFamilyFromName", "Str", "Segoe UI", "Ptr", 0, "Ptr*", fam)
    DllCall("gdiplus\GdipCreateFont", "Ptr", fam, "Float", size, "Int", 1, "Int", 2, "Ptr*", font)
    DllCall("gdiplus\GdipCreateStringFormat", "Int", 0, "Int", 0, "Ptr*", fmt)
    DllCall("gdiplus\GdipSetStringFormatAlign", "Ptr", fmt, "Int", align)
    DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", fmt, "Int", 1)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", argb, "Ptr*", br)
    VarSetCapacity(rc, 16, 0)
    NumPut(x, rc, 0, "Float"), NumPut(y, rc, 4, "Float")
    NumPut(w, rc, 8, "Float"), NumPut(h, rc, 12, "Float")
    DllCall("gdiplus\GdipDrawString", "Ptr", G, "Str", str, "Int", -1, "Ptr", font, "Ptr", &rc, "Ptr", fmt, "Ptr", br)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", br)
    DllCall("gdiplus\GdipDeleteStringFormat", "Ptr", fmt)
    DllCall("gdiplus\GdipDeleteFont", "Ptr", font)
    DllCall("gdiplus\GdipDeleteFontFamily", "Ptr", fam)
}

ApplyCardRegion()
{
    global GuiHwnd
    DllCall("user32\SetWindowRgn", "Ptr", GuiHwnd, "Ptr", 0, "Int", 1)
}

DrawText(G, str, x, y, w, h, size, argb, align, bold)
{
    global LyricFontName, LyricFontItalic, LyricFontWeight
    fam := 0
    DllCall("gdiplus\GdipCreateFontFamilyFromName", "Str", LyricFontName, "Ptr", 0, "Ptr*", fam)
    if (!fam)
        DllCall("gdiplus\GdipCreateFontFamilyFromName", "Str", "微软雅黑", "Ptr", 0, "Ptr*", fam)
    if (!fam)
        DllCall("gdiplus\GdipCreateFontFamilyFromName", "Str", "Segoe UI", "Ptr", 0, "Ptr*", fam)
    style := 1
    if (LyricFontItalic)
        style |= 2
    DllCall("gdiplus\GdipCreateFont", "Ptr", fam, "Float", size, "Int", style, "Int", 2, "Ptr*", font)
    DllCall("gdiplus\GdipCreateStringFormat", "Int", 0, "Int", 0, "Ptr*", fmt)
    DllCall("gdiplus\GdipSetStringFormatAlign", "Ptr", fmt, "Int", align)
    DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", fmt, "Int", 1)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", argb, "Ptr*", br)
    VarSetCapacity(rc, 16, 0)
    NumPut(x, rc, 0, "Float"), NumPut(y, rc, 4, "Float")
    NumPut(w, rc, 8, "Float"), NumPut(h, rc, 12, "Float")
    DllCall("gdiplus\GdipDrawString", "Ptr", G, "Str", str, "Int", -1, "Ptr", font, "Ptr", &rc, "Ptr", fmt, "Ptr", br)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", br)
    DllCall("gdiplus\GdipDeleteStringFormat", "Ptr", fmt)
    DllCall("gdiplus\GdipDeleteFont", "Ptr", font)
    DllCall("gdiplus\GdipDeleteFontFamily", "Ptr", fam)
}

DrawEffectText(G, str, x, y, w, h, size, align, kind)
{
    global FaconFam, ColInk, ColOrange, ColOrange2, ColBlue, ColBlue2, ColCnt1, ColCnt2, sunT
    fam := FaconFam
    if (!fam)
    {
        if (kind = 1)
            DrawText(G, str, x, y, w, h, size, ColInk, align, 1)
        else if (kind = 2)
            DrawText(G, str, x, y, w, h, size, ColOrange, align, 1)
        else
            DrawText(G, str, x, y, w, h, size, ColBlue, align, 1)
        return
    }
    DllCall("gdiplus\GdipCreateStringFormat", "Int", 0, "Int", 0, "Ptr*", fmt)
    DllCall("gdiplus\GdipSetStringFormatAlign", "Ptr", fmt, "Int", align)
    DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", fmt, "Int", 1)
    VarSetCapacity(rc, 16, 0)
    NumPut(x, rc, 0, "Float"), NumPut(y, rc, 4, "Float")
    NumPut(w, rc, 8, "Float"), NumPut(h, rc, 12, "Float")
    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pPath)
    DllCall("gdiplus\GdipAddPathString", "Ptr", pPath, "Str", str, "Int", -1, "Ptr", fam, "Int", 0, "Float", size, "Ptr", &rc, "Ptr", fmt)
    ; IronMan shadow
    VarSetCapacity(rc2, 16, 0)
    NumPut(x + 2, rc2, 0, "Float"), NumPut(y + 2, rc2, 4, "Float")
    NumPut(w, rc2, 8, "Float"), NumPut(h, rc2, 12, "Float")
    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pSh)
    DllCall("gdiplus\GdipAddPathString", "Ptr", pSh, "Str", str, "Int", -1, "Ptr", fam, "Int", 0, "Float", size, "Ptr", &rc2, "Ptr", fmt)
    sh := (kind = 1) ? 0x59485058 : 0x96000000
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", sh, "Ptr*", bSh)
    DllCall("gdiplus\GdipFillPath", "Ptr", G, "Ptr", bSh, "Ptr", pSh)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", bSh)
    DllCall("gdiplus\GdipDeletePath", "Ptr", pSh)
    if (kind = 1)
    {
        VarSetCapacity(rcHi, 16, 0)
        NumPut(x - 1, rcHi, 0, "Float"), NumPut(y - 1, rcHi, 4, "Float")
        NumPut(w, rcHi, 8, "Float"), NumPut(h, rcHi, 12, "Float")
        DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pHi)
        DllCall("gdiplus\GdipAddPathString", "Ptr", pHi, "Str", str, "Int", -1, "Ptr", fam, "Int", 0, "Float", size, "Ptr", &rcHi, "Ptr", fmt)
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xD8FFFFFF, "Ptr*", bHi)
        DllCall("gdiplus\GdipFillPath", "Ptr", G, "Ptr", bHi, "Ptr", pHi)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", bHi)
        DllCall("gdiplus\GdipDeletePath", "Ptr", pHi)
        c1 := ColCnt1
        c2 := ColCnt2
    }
    else
    {
        c1 := (kind = 2) ? ColOrange : ColBlue
        c2 := (kind = 2) ? ColOrange2 : ColBlue2
    }
    VarSetCapacity(pt1, 8, 0)
    NumPut(x, pt1, 0, "Float"), NumPut(y, pt1, 4, "Float")
    VarSetCapacity(pt2, 8, 0)
    NumPut(x, pt2, 0, "Float"), NumPut(y + h, pt2, 4, "Float")
    DllCall("gdiplus\GdipCreateLineBrush", "Ptr", &pt1, "Ptr", &pt2, "UInt", c1, "UInt", c2, "Int", 0, "Ptr*", br)
    if (!br)
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", c1, "Ptr*", br)
    if (kind = 1)
    {
        tStroke := sunT
        if (tStroke < 0)
            tStroke := 0
        if (tStroke > 1)
            tStroke := 1
        colOut := GlowColor(DesatColor(ArcColor(tStroke), 0.4), 255)
        pw := size * 0.09
        if (pw < 2.0)
            pw := 2.0
        DllCall("gdiplus\GdipCreatePen1", "UInt", colOut, "Float", pw, "Int", 2, "Ptr*", pOut)
        DllCall("gdiplus\GdipSetPenLineJoin", "Ptr", pOut, "Int", 2)
        DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pOut, "Int", 2)
        DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pOut, "Int", 2)
        DllCall("gdiplus\GdipDrawPath", "Ptr", G, "Ptr", pOut, "Ptr", pPath)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pOut)
    }
    DllCall("gdiplus\GdipFillPath", "Ptr", G, "Ptr", br, "Ptr", pPath)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", br)
    DllCall("gdiplus\GdipDeletePath", "Ptr", pPath)
    DllCall("gdiplus\GdipDeleteStringFormat", "Ptr", fmt)
}

CalcSun()
{
    global
    riseToday := SunTime(Lat, Lon, A_Now, 1)
    setToday := SunTime(Lat, Lon, A_Now, 0)
    tom := A_Now
    tom += 1, Days
    riseTom := SunTime(Lat, Lon, tom, 1)
    FormatTime, riseTxt, %riseToday%, HH:mm
    FormatTime, setTxt, %setToday%, HH:mm
}

SunTime(lat, lon, when, isRise)
{
    global PI, RAD, J2000, E_OBL, TZ
    FormatTime, ymd, %when%, yyyyMMdd
    noon := ymd . "120000"
    t := noon
    t -= 19700101000000, Seconds
    unixUtc := t - TZ * 3600
    julian := unixUtc / 86400.0 - 0.5 + 2440588.0
    d := julian - J2000
    lw := RAD * (-lon)
    phi := RAD * lat
    n := Round(d - 0.0009 - lw / (2.0 * PI))
    ds := 0.0009 + lw / (2.0 * PI) + n
    M := RAD * (357.5291 + 0.98560028 * ds)
    C := RAD * (1.9148 * Sin(M) + 0.02 * Sin(2 * M) + 0.0003 * Sin(3 * M))
    L := M + C + (RAD * 102.9372) + PI
    dec := ASin(Sin(L) * Sin(E_OBL))
    Jnoon := J2000 + ds + 0.0053 * Sin(M) - 0.0069 * Sin(2 * L)
    h0 := RAD * -0.833
    cosH := (Sin(h0) - Sin(phi) * Sin(dec)) / (Cos(phi) * Cos(dec))
    if (cosH > 1)
        cosH := 1
    if (cosH < -1)
        cosH := -1
    w := ACos(cosH)
    a := 0.0009 + (w + lw) / (2.0 * PI) + n
    Jset := J2000 + a + 0.0053 * Sin(M) - 0.0069 * Sin(2 * L)
    Jrise := Jnoon - (Jset - Jnoon)
    j := isRise ? Jrise : Jset
    unixOut := (j + 0.5 - 2440588.0) * 86400.0
    localSec := Round(unixOut + TZ * 3600)
    ts := 19700101000000
    ts += localSec, Seconds
    return ts
}

UpdateCount:
UpdateCount()
return

UpdateCount()
{
    global riseToday, setToday, riseTom, word, cnt, sunT
    now := A_Now
    if (now < riseToday)
    {
        target := riseToday
        word := "距日出"
        sunT := 0
    }
    else if (now < setToday)
    {
        target := setToday
        word := "距日落"
        dur := setToday
        dur -= riseToday, Seconds
        el := now
        el -= riseToday, Seconds
        sunT := (dur > 0) ? (el / dur) : 0
    }
    else
    {
        target := riseTom
        word := "距日出"
        sunT := 1
    }
    t1 := now
    t1 -= target, Seconds
    left := -t1
    if (left < 0)
    {
        CalcSun()
        return
    }
    hh := left // 3600
    mm := Mod(left, 3600) // 60
    cnt := Pad2(hh) . ":" . Pad2(mm)
    DrawCard()
    FormatTime, today, %now%, yyyyMMdd
    FormatTime, riseDay, %riseToday%, yyyyMMdd
    if (today != riseDay)
        CalcSun()
}

SavePos:
SaveWindowPos()
return

ShowCityPicker:
Gui, City:Destroy
Gui, City:+AlwaysOnTop +ToolWindow
Gui, City:Font, s11, Microsoft YaHei UI
Gui, City:Add, Text,, 选择城市（按当地经纬度计算日出日落）
Gui, City:Add, ListBox, vPickedCity w220 r12, % CityList()
Gui, City:Add, Button, Default w220 gApplyCity, 确定
Gui, City:Show,, 日出日落 · 城市
return

CityList()
{
    global Cities, CityName
    out := ""
    Loop, Parse, Cities, `n, `r
    {
        if (A_LoopField = "")
            continue
        StringSplit, p, A_LoopField, |
        item := p1
        if (p1 = CityName)
            item := p1 . "|"
        out .= item . "|"
    }
    StringTrimRight, out, out, 1
    return out
}

ApplyCity:
Gui, City:Submit
if (PickedCity = "")
    return
Loop, Parse, Cities, `n, `r
{
    if (A_LoopField = "")
        continue
    StringSplit, p, A_LoopField, |
    if (p1 = PickedCity)
    {
        CityName := p1
        Lat := p2
        Lon := p3
        IniWrite, %CityName%, %INI%, Location, City
        IniWrite, %Lat%, %INI%, Location, Lat
        IniWrite, %Lon%, %INI%, Location, Lon
        CalcSun()
        UpdateCount()
        break
    }
}
return

CityGuiClose:
CityGuiEscape:
Gui, City:Destroy
return

ToggleTop:
PinTop := !PinTop
IniWrite, %PinTop%, %INI%, Window, AlwaysOnTop
if (PinTop)
{
    WinSet, AlwaysOnTop, On, ahk_id %GuiHwnd%
    Menu, Tray, Check, 始终置顶
    Menu, Ctx, Check, 始终置顶
}
else
{
    WinSet, AlwaysOnTop, Off, ahk_id %GuiHwnd%
    Menu, Tray, Uncheck, 始终置顶
    Menu, Ctx, Uncheck, 始终置顶
}
return

Quit:
Gosub, SavePos
if (pToken)
    DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
ExitApp

#If OverlayUnderMouse()
WheelUp::
SetOverlayScale(UiScale * 1.10)
return
WheelDown::
SetOverlayScale(UiScale / 1.10)
return
#If

OverlayUnderMouse()
{
    global GuiHwnd
    MouseGetPos, , , hwnd
    return (hwnd = GuiHwnd)
}
