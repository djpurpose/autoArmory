#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_x64=autoArmoryTest.exe
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <ImageSearch.au3>
#include <AutoItConstants.au3>
#include <Date.au3>
#include <ScreenCapture.au3>
#include <File.au3>

global $hFile = FileOpen(@ScriptDir & "\ArmoryLog.txt", 1)
global $rosbotwindowtitle = ""
global $riftCount = 0
global $numRiftsToRun = 1
global $numGriftsToRun = 2
global $riftType = 1
global $leaveGame = False
global $armNumber = 2
global $changingGearFlag = 0
global $ignoreCounter = 0


; Activate window
WinActivate("[CLASS:D3 Main Window Class]")

Local $bPos = WinGetPos("Diablo III")

global $x = $bPos[0]
global $y = $bPos[1]
global $w = $bPos[2]
global $h = $bPos[3]


; Hotkey INFO - Running Step : Talk to Orek
HotKeySet("^[", "incRiftCount")

; Hotkey INFO - Vendor loop
HotKeySet("^]", "armoryControler")

; Hotkey incRiftCount
HotKeySet("^.", "incRiftCount")

; Hotkey decRiftCount
HotKeySet("^,", "decRiftCount")

; Hotkey decRiftCount
HotKeySet("^,", "decRiftCount")

; Hotkey decRiftCount
HotKeySet("^g", "testSwapGear")

; Test swapping gear back and forth
Func testSwapGear()
	; 1 -> 2
	If $riftType = 1 Then
		$armNumber = 2
	; 2 -> 1
	ElseIf $riftType = 2 Then
		$armNumber = 1
	EndIf

	selectArmory($armNumber)

	; If we get an error in selectArmory further down lets just forget we were called
	; Reset all the stuff to the state we were in and stop/start the monitor after 60
	If @error Then
		_FileWriteLog($hFile, "[armoryControler() - selectArmory() had an ERROR] Waiting for 60 seconds before trying to stop/start Monitor ")

		; Wait for 60 sec then call
		sleep(60000)

		stopStartMonitor()

		fixState()

		Return
	EndIf

	; Happy case we changed gear correctly
	If $armNumber = $riftType Then
		_FileWriteLog($hFile, "[armoryControler() - Select Armory worked, continuing to changeBotRiftType()]  riftType: " & $riftType & "  riftCount: " & $riftCount & "  $numRiftsToRun: " & $numRiftsToRun & "  numGriftsToRun: " & $numGriftsToRun & " armNumber: " & $armNumber)

		; Reset riftCount
		$riftCount = 0

		; Change bot to run GRift and Start
		changeBotRiftType($riftType)

		stopStartMonitor()

		_FileWriteLog($hFile, "[armoryControler() - Reseting Flag]")
		$changingGearFlag = 0

	; Oh no we messed up, lets restart, try again next rift
	Else
		_FileWriteLog($hFile, "[armoryControler() - Select Armory failed, start/stoping monitor]  riftType: " & $riftType & "  riftCount: " & $riftCount & "  $numRiftsToRun: " & $numRiftsToRun & "  numGriftsToRun: " & $numGriftsToRun & " armNumber: " & $armNumber)

		stopStartMonitor()

		fixState()

	EndIf

EndFunc

; Increment Rift count
Func incRiftCount()
    $riftCount = $riftCount + 1
	_FileWriteLog($hFile, "[incRiftCount() called]  riftType: " & $riftType & "  riftCount: " & $riftCount & "  $numRiftsToRun: " & $numRiftsToRun & "  numGriftsToRun: " & $numGriftsToRun)
EndFunc

; Decrement Rift count
Func decRiftCount()
    $riftCount = $riftCount - 1
	_FileWriteLog($hFile, "[decRiftCount() called]  riftType: " & $riftType & "  riftCount: " & $riftCount & "  $numRiftsToRun: " & $numRiftsToRun & "  numGriftsToRun: " & $numGriftsToRun)
EndFunc

Func fixState()
	; Avoid weird loops because we are in the wrong town
	; Next make the town not matter
	$riftCount = $riftCount > 0 ? $riftCount - 1 : 0
	_FileWriteLog($hFile, "[fixState() - Setting $riftCount] $riftCount set to: " & $riftCount)

	_FileWriteLog($hFile, "[fixState() - Reseting Flag]")
	$changingGearFlag = 0
EndFunc

; Controler function, decides if we should switch specs
Func armoryControler()
	If ($changingGearFlag = 1 And $ignoreCounter <= 10) Then
		_FileWriteLog($hFile, "[armoryControler() - called during gear change]  Ignoring...")
		Return

	; Something happened and a previous thread failed poorly, lets get back to a good state
	ElseIf $ignoreCounter > 10 Then
		_FileWriteLog($hFile, "[armoryControler() - called during gear change]  Ignoring...")
		fixState()
		Return
	EndIf
	_FileWriteLog($hFile, "[armoryControler() - called]  riftType: " & $riftType & "  riftCount: " & $riftCount & "  $numRiftsToRun: " & $numRiftsToRun & "  numGriftsToRun: " & $numGriftsToRun)

    ; Should we switch to running GRifts?
    If (($riftType = 1 And $riftCount >= $numRiftsToRun  And $changingGearFlag = 0) Or ($riftType = 2 And $riftCount >= $numGRiftsToRun And $changingGearFlag = 0)) Then
		If $changingGearFlag = 1 Then
			_FileWriteLog($hFile, "[armoryControler() - called during gear change (Inside of if)]  Ignoring...")
			Return
		EndIf

		; Flip the Flag
		$changingGearFlag = 1

		_FileWriteLog($hFile, "[armoryControler() - switching rift/armory]  riftType: " & $riftType & "  riftCount: " & $riftCount & "  $numRiftsToRun: " & $numRiftsToRun & "  numGriftsToRun: " & $numGriftsToRun)

		; Click Return to game just in case the run failed
        MouseClick("left", 408 + $x, 573 + $y, 1, 1)

		; Take a selfie
		screenShotDiablo()

		; Click Return to game just in case the run failed
        MouseClick("left", 408 + $x, 573 + $y, 1, 1)

        ; Stop Bot and wait 5 sec
        Send("{F7}")
        sleep(5000)

		; Click Return to game just in case the run failed
        MouseClick("left", 408 + $x, 573 + $y, 1, 1)

		; 1 -> 2
        If $riftType = 1 Then
			$armNumber = 2
		; 2 -> 1
		ElseIf $riftType = 2 Then
			$armNumber = 1
		EndIf

		selectArmory($armNumber)

		; If we get an error in selectArmory further down lets just forget we were called
		; Reset all the stuff to the state we were in and stop/start the monitor after 60
		If @error Then
			_FileWriteLog($hFile, "[armoryControler() - selectArmory() had an ERROR] Waiting for 60 seconds before trying to stop/start Monitor ")

			; Wait for 60 sec then call
			sleep(60000)

			stopStartMonitor()

			fixState()

			Return
		EndIf

		; Happy case we changed gear correctly
		If $armNumber = $riftType Then
			_FileWriteLog($hFile, "[armoryControler() - Select Armory worked, continuing to changeBotRiftType()]  riftType: " & $riftType & "  riftCount: " & $riftCount & "  $numRiftsToRun: " & $numRiftsToRun & "  numGriftsToRun: " & $numGriftsToRun & " armNumber: " & $armNumber)

			; Reset riftCount
			$riftCount = 0

			; Change bot to run GRift and Start
			changeBotRiftType($riftType)

			stopStartMonitor()

			_FileWriteLog($hFile, "[armoryControler() - Reseting Flag]")
			$changingGearFlag = 0

		; Oh no we messed up, lets restart, try again next rift
		Else
			_FileWriteLog($hFile, "[armoryControler() - Select Armory failed, start/stoping monitor]  riftType: " & $riftType & "  riftCount: " & $riftCount & "  $numRiftsToRun: " & $numRiftsToRun & "  numGriftsToRun: " & $numGriftsToRun & " armNumber: " & $armNumber)

			stopStartMonitor()

			fixState()

		EndIf
    EndIf
EndFunc

Func screenShotDiablo()
	_ScreenCapture_Capture("armoryScreenshots\" & @MON & "-" & @MDAY  & "-" & @YEAR & "_" & @HOUR & "-" & @MIN & "-" & @SEC & ".jpg", $x, $y, $w + $x, $h + $y,False)
EndFunc

Func stopStartMonitor()

	sleep(1000)

	; Wait 10 sec to activate the window
	_FileWriteLog($hFile, "[stopStartMonitor() - Activating the monitor window]")
	WinActivate("RBAssist v1.3.6 by Sunblood")

	_FileWriteLog($hFile, "[stopStartMonitor() - Looking for Monitor window]")
	Local $hWnd = WinWaitActive("[CLASS:AutoIt v3 GUI]", "", 10)

	; If it succeeded then click stop/start, if we fail we will try again after another rift
	if $hWnd Then
		_FileWriteLog($hFile, "[stopStartMonitor() - Stopping Monitor]")
		ControlClick($hWnd, "", "[CLASS:Button; INSTANCE:2]")
		sleep(1000)

		_FileWriteLog($hFile, "[stopStartMonitor() - Starting Monitor]")
		ControlClick($hWnd, "", "[CLASS:Button; INSTANCE:1]")
		sleep(1000)
	Else
		_FileWriteLog($hFile, "[stopStartMonitor() - Failed to find Monitor Window] Returning...")
	EndIf
EndFunc

Func changeBotRiftType($riftType)
	_FileWriteLog($hFile, "[changeBotRiftType() - Changing to new rift type in bot]  riftType: " & $riftType & "  riftCount: " & $riftCount & "  $numRiftsToRun: " & $numRiftsToRun & "  numGriftsToRun: " & $numGriftsToRun & " armNumber: " & $armNumber)

    ; Click Configure
	FindBotTitle()
	WinActivate($rosbotwindowtitle)
	Local $hWnd = WinWaitActive("[CLASS:WindowsForms10.Window.8.app.0.9585cb_r6_ad1]")
	ControlClick($hWnd, "", "[CLASS:WindowsForms10.BUTTON.app.0.9585cb_r6_ad1; INSTANCE:2]")
	sleep(200)

	; Select DoGreaterRift
	WinActivate("[CLASS:WindowsForms10.SysListView32.app.0.9585cb_r6_ad1; INSTANCE:1]")
	For $i = 1 To 20 Step 1
		Send("{UP}")
		sleep(50)
	Next
	sleep(200)

	; Click on the Armory 1 for ( Armory 2 for )
	If $riftType = 1 Then

		; DoGreaterRift: False
		ControlClick("Configure", "", "[CLASS:WindowsForms10.BUTTON.app.0.9585cb_r6_ad1; INSTANCE:2]")
	ElseIf $riftType = 2 Then

		; DoGreaterRift: True
		ControlClick("Configure", "", "[CLASS:WindowsForms10.BUTTON.app.0.9585cb_r6_ad1; INSTANCE:1]")
	EndIf

	; Sleep
	sleep(100)

	; Click Save
	ControlClick("Configure", "", "[CLASS:WindowsForms10.BUTTON.app.0.9585cb_r6_ad1; INSTANCE:3]")
	sleep(300)
EndFunc

; Switch from Armory 1 or 2
Func selectArmory($armoryNumber)


    If ($armoryNumber = 1 Or $armoryNumber = 2) Then
		sleep(1000)

		; Activate window
		WinActivate("[CLASS:D3 Main Window Class]")
		sleep(2000)

		Local $bPos = WinGetPos("Diablo III")

		If @error Then
			_FileWriteLog($hFile, "[selectArmory() - ERROR] Window Position Failed, Diablo Window not Present")
			Return SetError(1,0,0)
		EndIf

		global $x = $bPos[0]
		global $y = $bPos[1]
		global $w = $bPos[2]
		global $h = $bPos[3]

        ; Map
        Send("{m}")
        sleep(1500)

        ; Old Ruins
        MouseClick("left", 367 + $x, 218 + $y, 1, 1)
        sleep(4500)

        ; Teleporter
        MouseClick("left", 404 + $x, 307 + $y, 1, 1)
        sleep(3500)

        ; New Tristam
        MouseClick("left", 439 + $x, 300 + $y, 1, 1)
        sleep(4500)

        ; Armory
        MouseClick("left", 185 + $x, 70 + $y, 1, 1)
        sleep(3500)

        ; Click on the Armory 1 or 2
        If $armoryNumber = 1 Then
            ; Armory 1
            MouseClick("left", 293 + $x, 156 + $y, 1, 1)
            sleep(1000)
        ElseIf $armoryNumber = 2 Then
            ; Armory 2
            MouseClick("left", 293 + $x, 227 + $y, 1, 1)
            sleep(1000)
		EndIf

        ; Equip
        MouseClick("left", 220 + $x, 502 + $y, 1, 2)
        sleep(6000)

		; verify we actually changed
		Local $gearnum = gearOneOrTwo()

		; We changed correctly LETS GO!!!
		If $armoryNumber = $gearnum Then
			$riftType = $armoryNumber

		EndIf
    EndIf
EndFunc

; Return what gear, 1 for ms, 2 for imp, 0 for we dont know.
Func gearOneOrTwo()

	Local $g1count = 0, $g2count = 0, $g1count2 = 0, $g2count2 = 0
	Local $xx = 0, $yy = 0

	_FileWriteLog($hFile, "[gearOneOrTwo() - checking gear]")

	; Activate window
	WinActivate("[CLASS:D3 Main Window Class]")
		If @error Then
		_FileWriteLog($hFile, "[gearOneOrTwo() - ERROR] WinActivate Failed, Diablo Window not Present")
		Return SetError(1,0,0)
	EndIf

	Local $bPos = WinGetPos("Diablo III")

	If @error Then
		_FileWriteLog($hFile, "[gearOneOrTwo() - ERROR] WinGetPos Failed, Diablo Window not Present")
		Return SetError(1,0,0)
	EndIf

	; Check quiver
	For $i = 1 To 5
		$g1count += _ImageSearchArea("multishot-th.bmp", 0, 740 + $x, 262 + $y, 777 + $x, 300 + $y, $xx, $yy, 90)
		$g2count += _ImageSearchArea("impale-th.bmp", 0, 740 + $x, 262 + $y, 777 + $x, 300 + $y, $xx, $yy, 90)
	Next

	; Check right mouse button skill
	For $i = 1 To 5
		$g1count2 += _ImageSearchArea("multishot.bmp", 0, 404 + $x, 580 + $y, 440 + $x, 620 + $y, $xx, $yy, 90)
		$g2count2 += _ImageSearchArea("impale.bmp", 0, 404 + $x, 580 + $y, 440 + $x, 620 + $y, $xx, $yy, 90)
	Next

	_FileWriteLog($hFile, "[gearOneOrTwo() - gear check done]  $g1count: " & $g1count & "  $g2count: " & $g2count)

	If ($g1count > $g2count And $g1count2 > $g2count2) Then
		_FileWriteLog($hFile, "[gearOneOrTwo() - g1 > g2]  $g1count: " & $g1count & " is >  $g2count: " & $g2count & "  Returning 1")
		_FileWriteLog($hFile, "[gearOneOrTwo() - g1 > g2]  $g1count2: " & $g1count2 & " is >  $g2count2: " & $g2count2 & "  Returning 1")
		Return 1
	ElseIf ($g1count < $g2count And $g1count2 < $g2count2) Then
		_FileWriteLog($hFile, "[gearOneOrTwo() - g2 > g1]  $g2count: " & $g2count & " is >  $g1count: " & $g1count & "  Returning 2")
		_FileWriteLog($hFile, "[gearOneOrTwo() - g2 > g1]  $g2count2: " & $g2count2 & " is >  $g1count2: " & $g1count2 & "  Returning 2")

		Return 2
	Else
		_FileWriteLog($hFile, "[gearOneOrTwo() - No winner]  $g1count: " & $g1count & " $g2count: " & $g2count & "  Returning 0")
		_FileWriteLog($hFile, "[gearOneOrTwo() - No winner]  $g1count2: " & $g1count2 & " $g2count2: " & $g2count2 & "  Returning 0")
		Return 0
	EndIf
EndFunc


;Since Rosbot title is random, we need a way to find a window that matches some of its features to find the title properly
Func FindBotTitle()
	$list = WinList() ;get a list of every window (this actually includes many hidden system and OS things but that's ok)
	For $i = 1 To $list[0][0]
		If ControlGetHandle($list[$i][0], "", "[TEXT:Start botting !]") <> 0 Then ;if one of the windows has a button on it that says "Start Botting !" (just like that) it's *probably* Rosbot.
			$rosbotwindowtitle = $list[$i][0] ;set the window title that we found
			ExitLoop ;don't bother checking the rest of the (hundreds of) windows we found
		EndIf
	Next
EndFunc

while 1
sleep(200)
WEnd