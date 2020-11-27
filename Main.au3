#include <WindowsConstants.au3>
#Include <ScreenCapture.au3>
#Include <Misc.au3>

Func Mark_Rect()
    local $iX1, $iY1, $iX2, $iY2, $aPos, $sMsg, $sBMP_Path
    Local $aMouse_Pos, $hMask, $hMaster_Mask, $iTemp
    Local $UserDLL = DllOpen("user32.dll")

; Create transparent GUI with Cross cursor
    $hCross_GUI = GUICreate("Test", @DesktopWidth, @DesktopHeight - 20, 0, 0, $WS_POPUP, $WS_EX_TOPMOST)
    WinSetTrans($hCross_GUI, "", 8)
    GUISetState(@SW_SHOW, $hCross_GUI)
    GUISetCursor(3, 1, $hCross_GUI)

    Global $hRectangle_GUI = GUICreate("", @DesktopWidth, @DesktopHeight, 0, 0, $WS_POPUP, $WS_EX_TOOLWINDOW + $WS_EX_TOPMOST)
    GUISetBkColor(0x000000)

; Wait until mouse button pressed
    While Not _IsPressed("01", $UserDLL)
        Sleep(10)
    WEnd

; Get first mouse position
    $aMouse_Pos = MouseGetPos()
    $iX1 = $aMouse_Pos[0]
    $iY1 = $aMouse_Pos[1]

; Draw rectangle while mouse button pressed
    While _IsPressed("01", $UserDLL)

        $aMouse_Pos = MouseGetPos()

        $hMaster_Mask = _WinAPI_CreateRectRgn(0, 0, 0, 0)
        $hMask = _WinAPI_CreateRectRgn($iX1,  $aMouse_Pos[1], $aMouse_Pos[0],  $aMouse_Pos[1] + 1) ; Bottom of rectangle
        _WinAPI_CombineRgn($hMaster_Mask, $hMask, $hMaster_Mask, 2)
        _WinAPI_DeleteObject($hMask)
        $hMask = _WinAPI_CreateRectRgn($iX1, $iY1, $iX1 + 1, $aMouse_Pos[1]) ; Left of rectangle
        _WinAPI_CombineRgn($hMaster_Mask, $hMask, $hMaster_Mask, 2)
        _WinAPI_DeleteObject($hMask)
        $hMask = _WinAPI_CreateRectRgn($iX1 + 1, $iY1 + 1, $aMouse_Pos[0], $iY1) ; Top of rectangle
        _WinAPI_CombineRgn($hMaster_Mask, $hMask, $hMaster_Mask, 2)
        _WinAPI_DeleteObject($hMask)
        $hMask = _WinAPI_CreateRectRgn($aMouse_Pos[0], $iY1, $aMouse_Pos[0] + 1,  $aMouse_Pos[1]) ; Right of rectangle
        _WinAPI_CombineRgn($hMaster_Mask, $hMask, $hMaster_Mask, 2)
        _WinAPI_DeleteObject($hMask)
        ; Set overall region
        _WinAPI_SetWindowRgn($hRectangle_GUI, $hMaster_Mask)

        If WinGetState($hRectangle_GUI) < 15 Then GUISetState()
        Sleep(10)

    WEnd

; Get second mouse position
    $iX2 = $aMouse_Pos[0]
    $iY2 = $aMouse_Pos[1]

; Set in correct order if required
    If $iX2 < $iX1 Then
        $iTemp = $iX1
        $iX1 = $iX2
        $iX2 = $iTemp
    EndIf
    If $iY2 < $iY1 Then
        $iTemp = $iY1
        $iY1 = $iY2
        $iY2 = $iTemp
    EndIf

    GUIDelete($hRectangle_GUI)
    GUIDelete($hCross_GUI)
    DllClose($UserDLL)
    local $coords[4]
    $coords[0] = Ceiling($iX1/0.7994);
    $coords[1] = Ceiling($iY1/0.7990); 
    $coords[2] = Ceiling($iX2/0.7994);
    $coords[3] = Ceiling($iY2/0.7990);
    return $coords
EndFunc  ;==>Mark_Rect

Func _getDOSOutput($command , $wd='')
    Local $text = '', $Pid = Run('"' & @ComSpec & '" /c ' & $command, $wd, @SW_HIDE, 2 + 4)
    While 1
        $text &= StdoutRead($Pid, False, False)
        If @error Then ExitLoop
        Sleep(10)
    WEnd
    Return StringStripWS($text, 7)
 EndFunc   ;==>_getDOSOutput

Func CopyFromScreen()
    $coords = Mark_Rect()
    $sBMP_Path = @ScriptDir & "\Rect.bmp"
    _ScreenCapture_Capture($sBMP_Path, $coords[0], $coords[1], $coords[2], $coords[3], False)
    $text = _getDOSOutput('tesseract.exe '& $sBMP_Path & ' stdout')
    ClipPut($text)
EndFunc

HotKeySet("{f2}", "CopyFromScreen") ;select and copy f2
HotKeySet("^!{esc}", "Terminate") ;ctrl+alt+esc close

While 1   
   Sleep(100)
WEnd
   
Func Terminate()
    Exit
EndFunc