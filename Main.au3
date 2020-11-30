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

Func ASM_Bitmap_Grey_BnW($file, $iBlackAndWhite = 1, $iLight = 125) ;ASM code by AndyG
    _GDIPlus_Startup()
    Local $vBmp = _GDIPlus_BitmapCreateFromFile($file)
    Local $iWidth = _GDIPlus_ImageGetWidth($vBmp)
    Local $iHeight = _GDIPlus_ImageGetHeight($vBmp)
    $vBitmap = _GDIPlus_BitmapCloneArea($vBmp, 0, 0, $iWidth, $iHeight)
    Local $hBitmapData = _GDIPlus_BitmapLockBits($vBitmap, 0, 0, $iWidth, $iHeight, BitOR($GDIP_ILMREAD, $GDIP_ILMWRITE), $GDIP_PXF32RGB)
    Local $Scan = DllStructGetData($hBitmapData, "Scan0")
    Local $Stride = DllStructGetData($hBitmapData, "Stride")
    Local $tPixelData = DllStructCreate("dword[" & (Abs($Stride * $iHeight)) & "]", $Scan)
    Local $bytecode = "0x8B7C24048B5424088B5C240CB900000000C1E202575352518B040FBA00000000BB00000000B90000000088C2C1E80888C3C1E80888C18B44240883F800772FB85555000001CB01D3F7E3C1E810BB00000000B3FFC1E30888C3C1E30888C3C1E30888C389D8595A5B5F89040FEB3B89C839C3720289D839C2720289D05089F839C3770289D839C2770289D05B01D8BBDC780000F7E3C1E810595A5B5F3B4424107213C7040FFFFFFF0083C10439D1730EE95FFFFFFFC7040F00000000EBEBC3"
    Local $tCodebuffer = DllStructCreate("byte[" & StringLen($bytecode) / 2 - 1 & "]")
    Local $Ret = DllStructSetData($tCodebuffer, 1, $bytecode)
    DllCall("user32.dll", "int", "CallWindowProcW", "ptr", DllStructGetPtr($tCodebuffer), "ptr", DllStructGetPtr($tPixelData), "int", $iWidth * $iHeight, "int", $iBlackAndWhite, "int", $iLight);
    _GDIPlus_BitmapUnlockBits($vBitmap, $hBitmapData)
    $tPixelData = 0
    $tCodebuffer = 0
    _GDIPlus_ImageSaveToFile($vBitmap, @ScriptDir & "\Rect_BW.jpg")
    _GDIPlus_BitmapDispose($vBitmap)
    _GDIPlus_BitmapDispose($vBmp)
    _GDIPlus_Shutdown()
EndFunc   ;==>ASM_Bitmap_Grey_BnW

Func CopyFromScreen()
    $coords = Mark_Rect()
    $sBMP_Path = @ScriptDir & "\Rect.bmp"
    _ScreenCapture_Capture($sBMP_Path, $coords[0], $coords[1], $coords[2], $coords[3], False)
    ; ASM_Bitmap_Grey_BnW($sBMP_Path, 1, 125)
    $text = _getDOSOutput('tesseract.exe '& $sBMP_Path & ' stdout')
    ClipPut($text)
EndFunc

HotKeySet("{f2}", "CopyFromScreen") ;select and copy f2
HotKeySet("^!{esc}", "Terminate") ;ctrl+alt+esc close
Press Ctr1+Alt+Break to Restart or Ctr1+BREAK to Stop.
While 1   
   Sleep(100)
WEnd

Func Terminate()
    Exit
EndFunc