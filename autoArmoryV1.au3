#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_x64=autoArmoryRfp.exe
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <ImageSearch.au3>
#include <AutoItConstants.au3>
#include <Date.au3>
#include <ScreenCapture.au3>
#include <File.au3>

; User ini settings
Global $numRiftsToRun = 2				; Number of normal rifts to run
Global $numGriftsToRun = 4 				; Number of greater rifts to run (ignored if RFP is enabled)
Global $leaveGame = False 				; Should we leave game on rifts? No effect on grifts
Global $riftForPools = False			; When true we rift until pool marker shows on the right, then run $numRiftsToRun more rifts
										; We then switch to greater rifts until pools are gone. Note this mode needs extra keys available
										; as it might use more keys than it gets in rifts. If you are low on keys keep this false and adjust
										; the number of rifts/grifts accordingly.

; Defaults
Global Const $autoArmoryLogFile = FileOpen(@ScriptDir & "\ArmoryLog.txt", 1)
Global Const $settingsIni = "autoArmorySettings.ini"

; Dynamic state variables
Global $riftCount = 0					; How many rifts/grifts we have run in this cycle
Global $rosbotwindowtitle = ""			; Window title for RosBot (it changes)
Global $riftType = 1					; What rift type we are running. 1 is normal, 2 is greater rift
Global $armNumber = 2
Global $changingGearFlag = 0
Global $ignoreCounter = 0
Global $pools = False
Global $checkingPools = False
Global $justFailedGearSwap = False

loadSettings()

; Activate window
WinActivate("[CLASS:D3 Main Window Class]")

Local $bPos = WinGetPos("Diablo III")

Global $x = $bPos[0]
Global $y = $bPos[1]
Global $w = $bPos[2]
Global $h = $bPos[3]


; Hotkey INFO - Running Step : Talk to Orek
HotKeySet("^[", "incRiftCount")

; Hotkey INFO - Vendor loop
HotKeySet("^]", "armoryControler")


Func loadSettings()
	#cs
	$x = readSetting("General", "winX", "null")

	$rosbotwindowtitle = ""
	Global $riftCount = 0
	Global $numRiftsToRun = 2
	Global $numGriftsToRun = 4 ; Not used in this version
	Global $riftType = 1
	Global $leaveGame = False
	Global $armNumber = 2
	Global $changingGearFlag = 0
	Global $ignoreCounter = 0
	Global $pools = False
	Global $checkingPools = False
	Global $justFailedGearSwap = False
	#ce
EndFunc

;===============================================================================
; Description:      setDiabloWindowLocation - Sets the x, y, w, h of D3 window.
; Parameter(s):  	None
; Return Value(s):  None
;===============================================================================
Func setDiabloWindowLocation()
	; Activate window
	WinActivate("[CLASS:D3 Main Window Class]")

	Local $bPos = WinGetPos("Diablo III")

	If @error Then
		aaLog("setDiabloWindowLocation", "ERROR: Window Position Failed, Diablo Window not Present")
		Return SetError(1,0,0)
	EndIf

	aaLog("setDiabloWindowLocation", "Window detected - Setting - x: " & $x & " y: " & $y & " w: " & $w & " h: " & $h)

	Global $x = $bPos[0]
	Global $y = $bPos[1]
	Global $w = $bPos[2]
	Global $h = $bPos[3]
EndFunc

;===============================================================================
; Description:      aaLog - Standard logging for autoArmory
; Parameter(s):  	$functionName - String - Name of calling function
;                   $message - String - Message to display
;                   $state - 1 to include states like pool, rift count
;							 0 to exclude state
;                   $settings - 1 to include static settings like rifts to run
;							    0 to exclude settings
; Return Value(s):  None
;===============================================================================
Func aaLog($functionName, $message, $state, $settings)
	; We always log the functionName and message
	_FileWriteLog($autoArmoryLogFile, "[" & $functionName & "] - " & $message)

	; Log State if requested
	If $state Then
		_FileWriteLog($autoArmoryLogFile, "   | $pools: " & $pools & " | $riftType: " & $riftType & " | $riftCount: " & $riftCount & " | $changingGearFlag: " & $changingGearFlag & " | $justFailedGearSwap: " $justFailedGearSwap & " | $rosbotwindowtitle: " $rosbotwindowtitle)
	EndIf

	; Log settings if requested
	If $settings Then
		_FileWriteLog($autoArmoryLogFile, "   | riftsToRun: " & $numRiftsToRun & " | rt: " & $numGriftsToRun & " | $leaveGame: " & $leaveGame & " | $riftForPools: " & $riftForPools)
	EndIf
EndFunc


;===============================================================================
; Description:      poolOrNah - Checks for pools by looking for the yellow
;                               marker on the far right of the exp bar.
; Parameter(s):  	None
; Return Value(s):  True - if we detected pools.
;                   False - if we didn't
;===============================================================================
Func poolOrNah()
	Local $poolCount = 0
	Local $xx = 0, $yy = 0

	aaLog("poolOrNah", "checking pools...")

	; Activate window
	WinActivate("[CLASS:D3 Main Window Class]")
		If @error Then
		aaLog("poolOrNah", "ERROR: WinActivate Failed, Diablo Window not Present")
		Return SetError(1,0,0)
	EndIf

	Local $bPos = WinGetPos("Diablo III")

	If @error Then
		aaLog("poolOrNah", "ERROR: WinGetPos Failed, Diablo Window not Present")
		Return SetError(1,0,0)
	EndIf

	; Check pools
	For $i = 1 To 2
		$poolCount += _ImageSearchArea("pool.bmp", 0, 580 + $x, 570 + $y, 604 + $x, 587 + $y, $xx, $yy, 90)
	Next

	If ($poolCount > 0) Then
		aaLog("poolOrNah", "Pools detected!")
		Return True
	Else
		aaLog("poolOrNah", "No pools detected")
		Return False
	EndIf
EndFunc

;===============================================================================
; Description:      incRiftCount - Increment the rift count when we finish a rift.
;					               If running rfp this is only incremented when
;                                  we have pools.
; Parameter(s):  	None
; Return Value(s):  None
;===============================================================================
Func incRiftCount()
	aaLog("incRiftCount", "Called")

	If ($pools = 1) Then
		$riftCount += 1
		aaLog("incRiftCount", "riftCount ++",1,1)
	EndIf

	$pools = poolOrNah()
	aaLog("incRiftCount", "setting pools flag to: " & $pools)

	; fixes the case when pools return false after we just stopped running rifts and are wanting to run grifts
	; we should instead run another rift to get back into a good state.
	if $justFailedGearSwap Then
		$justFailedGearSwap = False
		aaLog("incRiftCount", "Setting justFailedGearSwap flag to false",1,1)
	EndIf
EndFunc

Func fixState()
	; Avoid weird loops because we are in the wrong town
	; Next make the town not matter
	_FileWriteLog($autoArmoryLogFile, "[fixState() - Setting $riftCount] $riftCount set to: " & $riftCount)
	$riftCount = $riftCount > 0 ? $riftCount - 1 : 0

	_FileWriteLog($autoArmoryLogFile, "[fixState() - Reseting changingGear flag]")
	$changingGearFlag = 0

	_FileWriteLog($autoArmoryLogFile, "[fixState() - Reseting justFailedGearSwap flag]")
	$justFailedGearSwap = true
EndFunc

; Controler function, decides if we should switch specs
Func armoryControler()
	; Fix an edge case were we are trying to gear swap in a bad state
	If $justFailedGearSwap Then
		_FileWriteLog($autoArmoryLogFile, "[armoryControler() - called after failing]  Ignoring. Will run another rift before retrying")
	EndIf

	If ($changingGearFlag = 1 And $ignoreCounter <= 10) Then
		_FileWriteLog($autoArmoryLogFile, "[armoryControler() - called during gear change]  Ignoring...")
		Return

	; Something happened and a previous thread failed poorly, lets get back to a good state
	ElseIf $ignoreCounter > 10 Then
		_FileWriteLog($autoArmoryLogFile, "[armoryControler() - called during gear change]  Fixing state...")
		fixState()
		Return
	EndIf
	_FileWriteLog($autoArmoryLogFile, "[armoryControler() - called]  riftType: " & $riftType & "  riftCount: " & $riftCount & "  $numRiftsToRun: " & $numRiftsToRun)


    ; Should we switch fift types?
    If (($riftType = 1 And $riftCount >= $numRiftsToRun  And $changingGearFlag = 0 And $pools) Or ($riftType = 2 And $pools = False And $changingGearFlag = 0)) Then
		If $changingGearFlag = 1 Then
			_FileWriteLog($autoArmoryLogFile, "[armoryControler() - called during gear change (Inside of if)]  Ignoring...")
			Return
		EndIf

		; Flip the Flag
		$changingGearFlag = 1

		; Click Return to game just in case the run failed
		_FileWriteLog($autoArmoryLogFile, "[armoryControler() - clicking return to game)]  1")
        MouseClick("left", 408 + $x, 573 + $y, 1, 1)
		sleep(100)
        MouseClick("left", 408 + $x, 573 + $y, 1, 1)
		sleep(100)
        MouseClick("left", 408 + $x, 573 + $y, 1, 1)

		_FileWriteLog($autoArmoryLogFile, "[armoryControler() - switching rift/armory] Pools: " & $pools & " riftType: " & $riftType & "  riftCount: " & $riftCount & "  $numRiftsToRun: " & $numRiftsToRun)

		; Take a selfie
		screenShotDiablo()

        ; Stop Bot and wait 5 sec
        Send("{F7}")

		; Click Return to game just in case the run failed
		_FileWriteLog($autoArmoryLogFile, "[armoryControler() - clicking return to game)]  2")
        MouseClick("left", 408 + $x, 573 + $y, 1, 1)
		sleep(100)
        MouseClick("left", 408 + $x, 573 + $y, 1, 1)
		sleep(100)
        MouseClick("left", 408 + $x, 573 + $y, 1, 1)

        sleep(4000)

		; 1 -> 2
        If $riftType = 1 Then
			$armNumber = 2
		; 2 -> 1
		ElseIf $riftType = 2 Then
			$armNumber = 1
		EndIf

		; Click Return to game just in case the run failed
		_FileWriteLog($autoArmoryLogFile, "[armoryControler() - clicking return to game)]  3")
        MouseClick("left", 408 + $x, 573 + $y, 1, 1)
		sleep(100)
        MouseClick("left", 408 + $x, 573 + $y, 1, 1)
		sleep(100)
        MouseClick("left", 408 + $x, 573 + $y, 1, 1)

		selectArmory($armNumber)


		; hopefully this works
		poolOrNah()


		; If we get an error in selectArmory further down lets just forget we were called
		; Reset all the stuff to the state we were in and stop/start the monitor after 60
		If @error Then
			_FileWriteLog($autoArmoryLogFile, "[armoryControler() - selectArmory() had an ERROR] Waiting for 60 seconds before trying to stop/start Monitor ")

			; Wait for 60 sec then call
			sleep(60000)

			stopStartMonitor()

			fixState()

			Return
		EndIf

		; Happy case we changed gear correctly
		If $armNumber = $riftType Then
			_FileWriteLog($autoArmoryLogFile, "[armoryControler() - Select Armory worked, continuing to changeBotRiftType()]  riftType: " & $riftType & "  riftCount: " & $riftCount & "  $numRiftsToRun: " & $numRiftsToRun & " armNumber: " & $armNumber)

			; Reset riftCount
			$riftCount = 0

			; Change bot to run GRift and Start
			changeBotRiftType($riftType)

			stopStartMonitor()

			_FileWriteLog($autoArmoryLogFile, "[armoryControler() - Reseting changingGear flag]")
			$changingGearFlag = 0

		; Oh no we messed up, lets restart, try again next rift
		Else
			_FileWriteLog($autoArmoryLogFile, "[armoryControler() - Select Armory failed, start/stoping monitor]  riftType: " & $riftType & "  riftCount: " & $riftCount & "  $numRiftsToRun: " & $numRiftsToRun & " armNumber: " & $armNumber)
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
	_FileWriteLog($autoArmoryLogFile, "[stopStartMonitor() - Activating the monitor window]")
	WinActivate("RBAssist v1.3.6 by Sunblood")

	_FileWriteLog($autoArmoryLogFile, "[stopStartMonitor() - Looking for Monitor window]")
	Local $hWnd = WinWaitActive("[CLASS:AutoIt v3 GUI]", "", 10)

	; If it succeeded then click stop/start, if we fail we will try again after another rift
	if $hWnd Then
		_FileWriteLog($autoArmoryLogFile, "[stopStartMonitor() - Stopping Monitor]")
		ControlClick($hWnd, "", "[CLASS:Button; INSTANCE:2]")
		sleep(1000)

		_FileWriteLog($autoArmoryLogFile, "[stopStartMonitor() - Starting Monitor]")
		ControlClick($hWnd, "", "[CLASS:Button; INSTANCE:1]")
		sleep(1000)
	Else
		_FileWriteLog($autoArmoryLogFile, "[stopStartMonitor() - Failed to find Monitor Window] Returning...")
	EndIf
EndFunc

Func changeBotRiftType($riftType)
	_FileWriteLog($autoArmoryLogFile, "[changeBotRiftType() - Changing to new rift type in bot]  riftType: " & $riftType & "  riftCount: " & $riftCount & "  $numRiftsToRun: " & $numRiftsToRun & " armNumber: " & $armNumber)

    ; Click Configure
	FindBotTitle()
	WinActivate($rosbotwindowtitle)
	Local $hWnd = WinWaitActive("[CLASS:WindowsForms10.Window.8.app.0.9585cb_r6_ad1]")
	ControlClick($hWnd, "", "[CLASS:WindowsForms10.BUTTON.app.0.9585cb_r6_ad1; INSTANCE:2]")
	sleep(200)


	; Change stay in game probability
	Send("{UP}")
	sleep(100)
	Send("{UP}")
	sleep(100)

	If $riftType = 1 Then
		_FileWriteLog($autoArmoryLogFile, "[changeBotRiftType() - Changing stay in game to 100]  riftType: " & $riftType & "  riftCount: " & $riftCount & "  $numRiftsToRun: " & $numRiftsToRun & " armNumber: " & $armNumber)
		ControlSetText("Configure", "", "[CLASS:WindowsForms10.EDIT.app.0.9585cb_r6_ad1; INSTANCE:1]", "0")
	Else
		_FileWriteLog($autoArmoryLogFile, "[changeBotRiftType() - Changing stay in game to 100]  riftType: " & $riftType & "  riftCount: " & $riftCount & "  $numRiftsToRun: " & $numRiftsToRun & " armNumber: " & $armNumber)
		ControlSetText("Configure", "", "[CLASS:WindowsForms10.EDIT.app.0.9585cb_r6_ad1; INSTANCE:1]", "100")
	EndIf


	; Select DoGreaterRift
	WinActivate("[CLASS:WindowsForms10.SysListView32.app.0.9585cb_r6_ad1; INSTANCE:1]")
	For $i = 1 To 20 Step 1
		Send("{UP}")
		sleep(50)
	Next
	sleep(200)

	; Change rift type
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
			_FileWriteLog($autoArmoryLogFile, "[selectArmory() - ERROR] Window Position Failed, Diablo Window not Present")
			Return SetError(1,0,0)
		EndIf

		Global $x = $bPos[0]
		Global $y = $bPos[1]
		Global $w = $bPos[2]
		Global $h = $bPos[3]

        ; Map
        Send("{m}")
        sleep(1500)

        ; Old Ruins
        MouseClick("left", 367 + $x, 218 + $y, 1, 1)
        sleep(4500)

        ; Teleporter
		MouseMove(404 + $x, 307 + $y)
        MouseClick("left", 404 + $x, 307 + $y, 1, 1)
        sleep(3500)

        ; New Tristam
        MouseClick("left", 439 + $x, 300 + $y, 1, 1)
        sleep(4500)

        ; Armory
		MouseMove(185 + $x, 70 + $y)
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

		For $1 = 1 to 20
			; Equip for BinSu
			MouseClick("left", 220 + $x, 502 + $y, 1, 2)
			sleep(1000)

			; verify we actually changed
			Local $gearnum = gearOneOrTwo()

			; We changed correctly LETS GO!!!
			If $armoryNumber = $gearnum Then
				$riftType = $armoryNumber
				Return
			EndIf
		Next
    EndIf
EndFunc

; Return what gear, 1 for ms, 2 for imp, 0 for we dont know.
Func gearOneOrTwo()

	Local $g1count = 0, $g2count = 0, $g1count2 = 0, $g2count2 = 0
	Local $xx = 0, $yy = 0

	_FileWriteLog($autoArmoryLogFile, "[gearOneOrTwo() - checking gear]")

	; Activate window
	WinActivate("[CLASS:D3 Main Window Class]")
		If @error Then
		_FileWriteLog($autoArmoryLogFile, "[gearOneOrTwo() - ERROR] WinActivate Failed, Diablo Window not Present")
		Return SetError(1,0,0)
	EndIf

	Local $bPos = WinGetPos("Diablo III")

	If @error Then
		_FileWriteLog($autoArmoryLogFile, "[gearOneOrTwo() - ERROR] WinGetPos Failed, Diablo Window not Present")
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

	_FileWriteLog($autoArmoryLogFile, "[gearOneOrTwo() - gear check done]  $g1count: " & $g1count & "  $g2count: " & $g2count)

	If ($g1count > $g2count And $g1count2 > $g2count2) Then
		_FileWriteLog($autoArmoryLogFile, "[gearOneOrTwo() - g1 > g2]  $g1count: " & $g1count & " is >  $g2count: " & $g2count & "  Returning 1")
		_FileWriteLog($autoArmoryLogFile, "[gearOneOrTwo() - g1 > g2]  $g1count2: " & $g1count2 & " is >  $g2count2: " & $g2count2 & "  Returning 1")
		Return 1
	ElseIf ($g1count < $g2count And $g1count2 < $g2count2) Then
		_FileWriteLog($autoArmoryLogFile, "[gearOneOrTwo() - g2 > g1]  $g2count: " & $g2count & " is >  $g1count: " & $g1count & "  Returning 2")
		_FileWriteLog($autoArmoryLogFile, "[gearOneOrTwo() - g2 > g1]  $g2count2: " & $g2count2 & " is >  $g1count2: " & $g1count2 & "  Returning 2")

		Return 2
	Else
		_FileWriteLog($autoArmoryLogFile, "[gearOneOrTwo() - No winner]  $g1count: " & $g1count & " $g2count: " & $g2count & "  Returning 0")
		_FileWriteLog($autoArmoryLogFile, "[gearOneOrTwo() - No winner]  $g1count2: " & $g1count2 & " $g2count2: " & $g2count2 & "  Returning 0")
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

;Just some shorthand functions for reading ini settings, thanks to Sunblood
Func readSetting($section, $key, $default = 0)
	Return IniRead($settingsIni, $section, $key, $default)
EndFunc   ;==>ReadSetting
Func saveSetting($section, $key, $data)
	IniWrite($settingsIni, $section, $key, $data)
EndFunc   ;==>SaveSetting

while 1
sleep(200)
WEnd