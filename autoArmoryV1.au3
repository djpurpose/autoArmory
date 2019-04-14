#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_x64=autoArmoryV1.exe
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; Includes
#include <ImageSearch.au3>
#include <AutoItConstants.au3>
#include <Date.au3>
#include <ScreenCapture.au3>
#include <File.au3>

; User ini settings
Global $numRiftsToRun = 2				; Number of normal rifts to run
Global $numGriftsToRun = 4 				; Number of greater rifts to run (ignored if RFP is enabled)
Global $leaveGameOnNormalRift = True 	; Should we leave game on rifts? No effect on grifts
Global $riftForPools = True				; When true we rift until pool marker shows on the right, then run $numRiftsToRun more rifts
										; We then switch to greater rifts until pools are gone. Note this mode needs extra keys available
										; as it might use more keys than it gets in rifts. If you are low on keys keep this false and adjust
										; the number of rifts/grifts accordingly.

; Defaults settings
Global Const $autoArmoryLogFile = FileOpen(@ScriptDir & "\ArmoryLog.txt", 1)
Global Const $settingsIni = "autoArmorySettings.ini"
Global Const $screenshotDirectory = "armoryScreenshots\"

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
Global $x = 0
Global $y = 0
Global $w = 0
Global $h = 0

loadSettings()
setDiabloWindowLocation()

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

	; Get position
	Local $bPos = WinGetPos("Diablo III")

	If @error Then
		aaLog("setDiabloWindowLocation", "ERROR: Window Position Failed, Diablo Window not Present")
		Return SetError(1,0,0)
	EndIf

	; Set position
	aaLog("setDiabloWindowLocation", "Window detected - Setting - x: " & $x & " y: " & $y & " w: " & $w & " h: " & $h)
	$x = $bPos[0]
	$y = $bPos[1]
	$w = $bPos[2]
	$h = $bPos[3]
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
Func aaLog($functionName, $message, $state = 0, $settings = 0)
	; We always log the functionName and message
	_FileWriteLog($autoArmoryLogFile, "[" & $functionName & "] - " & $message)

	; Log State if requested
	If $state Then
		_FileWriteLog($autoArmoryLogFile, "   | $pools: " & $pools & " | $riftType: " & $riftType & " | $riftCount: " & $riftCount & " | $changingGearFlag: " & $changingGearFlag & " | $justFailedGearSwap: " & $justFailedGearSwap & " | $rosbotwindowtitle: " & $rosbotwindowtitle)
	EndIf

	; Log settings if requested
	If $settings Then
		_FileWriteLog($autoArmoryLogFile, "   | riftsToRun: " & $numRiftsToRun & " | rt: " & $numGriftsToRun & " | $leaveGameOnNormalRift: " & $leaveGameOnNormalRift & " | $riftForPools: " & $riftForPools)
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

;===============================================================================
; Description:      fixState - Called when we we failed a gear swap. Fixes
;                              edge cases like diablo closing while swapping.
;                              When we fail a swap we should do another rift
;                              until we are in a better state.
;  Changes:         $changingGearFlag from 1 to 0
;				    $riftCount -= 1 or 0
;					$justFailedGearSwap from 0 to 1
; Parameter(s):  	None
; Return Value(s):  None
;===============================================================================
Func fixState()
	; Avoid weird loops because we are in the wrong town after a crash
	; Run another rift so that that we are in the right town at the
	; right time.
	aaLog("fixState", "Setting $riftCoun to: " & $riftCount)
	$riftCount = $riftCount > 0 ? $riftCount - 1 : 0

	aaLog("fixState", "Setting $changingGear flag to: 0")
	$changingGearFlag = 0

	aaLog("fixState", "Setting $justFailedGearSwap flag to: true")
	$justFailedGearSwap = True
EndFunc

;===============================================================================
; Description:      clickReturnToGame - Clicks return to game or clicks on exp
;                   bar. Ideally we know all the possible states of leaving game
;                   detect them and handle them. For now we force a state we can
;                   handle. TODO: handle the others with logic.
; Parameter(s):  	None
; Return Value(s):  None
;===============================================================================
Func clickReturnToGame()
	MouseClick("left", 408 + $x, 573 + $y, 1, 1)
	sleep(100)
	MouseClick("left", 408 + $x, 573 + $y, 1, 1)
	sleep(100)
	MouseClick("left", 408 + $x, 573 + $y, 1, 1)
EndFunc

;===============================================================================
; Description:      armoryControler - Main controller for armory. Decides if we
;                   should switch specs or not. Triggered by RBAssist.
; Parameter(s):  	None
; Return Value(s):  None
;===============================================================================
Func armoryControler()
	; Fix an edge case were we are trying to gear swap in a bad state
	If $justFailedGearSwap Then
		aaLog("armoryControler", "Called after failing. Lets run another rift before re-trying.")
	EndIf

	If ($changingGearFlag = 1 And $ignoreCounter <= 10) Then
		;aaLog("armoryControler", "called during gear change, ignoring...")
		Return

	; Something happened and a previous thread failed poorly, lets get back to a good state
	ElseIf $ignoreCounter > 10 Then
		aaLog("armoryControler", "called during gear change, Ignore counter breached: " & $ignoreCounter & " Fixing state...")
		fixState()
		Return
	EndIf
	aaLog("armoryControler", "Called", 1, 0)


    ; Should we switch fift types?
    If (($riftType = 1 And $riftCount >= $numRiftsToRun  And $changingGearFlag = 0 And $pools) Or ($riftType = 2 And $pools = False And $changingGearFlag = 0)) Then
		If $changingGearFlag = 1 Then
			aaLog("armoryControler", "called during gear change (Inside of if) Ignoring...")
			Return
		EndIf

		; Flip the Flag so we don't try to change gear during a gear change
		$changingGearFlag = 1
		clickReturnToGame()

		aaLog("armoryControler", "Switching rift/armory", 1,1)

		; Take a selfie
		screenShotDiablo()

        ; Stop Bot and wait 5 sec
        Send("{F7}")
        clickReturnToGame()
        sleep(4000)

		; 1 -> 2
        If $riftType = 1 Then
			$armNumber = 2
		; 2 -> 1
		ElseIf $riftType = 2 Then
			$armNumber = 1
		EndIf

		clickReturnToGame()
		selectArmory($armNumber)

		; Check for pools
		poolOrNah()

		; If we get an error in selectArmory further down lets just forget we were called
		; Reset all the stuff to the state we were in and stop/start the monitor after 60
		If @error Then
			aaLog("armoryControler", "selectArmory() had an ERROR. Waiting for 60 seconds before trying to stop/start monitor.")

			; Wait for 60 sec then start
			sleep(60000)
			stopStartMonitor()
			fixState()
			Return
		EndIf

		; Happy case we changed gear correctly
		If $armNumber = $riftType Then

			; Reset riftCount
			$riftCount = 0

			aaLog("armoryControler", "Select Armory worked, continuing to changeBotRiftType()",1,0)

			; Change bot to run GRift and Start
			changeBotRiftType($riftType)
			stopStartMonitor()

			aaLog("armoryControler", "Reseting changingGear flag.")
			$changingGearFlag = 0

		; Oh no we messed up, lets restart, try again next rift
		Else
			aaLog("armoryControler", "Select Armory failed, start/stoping monitor",1,0)
			stopStartMonitor()
			fixState()
		EndIf
    EndIf
EndFunc

;===============================================================================
; Description:      screenShotDiablo - This takes a screenshot right before
;                   stopping the bot when swapping gear. This ideally allows you
;                   to have an idea how each cycle is doing.
; Parameter(s):  	None
; Return Value(s):  None
;===============================================================================
Func screenShotDiablo()
	_ScreenCapture_Capture($screenshotDirectory & @MON & "-" & @MDAY  & "-" & @YEAR & "_" & @HOUR & "-" & @MIN & "-" & @SEC & ".jpg", $x, $y, $w + $x, $h + $y, False)
	aaLog("screenShotDiablo", "Screenshot saved to: " & $screenshotDirectory & @MON & "-" & @MDAY  & "-" & @YEAR & "_" & @HOUR & "-" & @MIN & "-" & @SEC & ".jpg")
EndFunc

;===============================================================================
; Description:      stopStartMonitor - Stops and starts RBAssist. This does lots
;                   of things for us. Starts rosbot, launches d3 if needed.
; Parameter(s):  	None
; Return Value(s):  None
;===============================================================================
Func stopStartMonitor()
	sleep(1000)

	; Wait 10 sec to activate the window
	aaLog("stopStartMonitor", "Activating the monitor window")
	WinActivate("RBAssist v1.3.6 by Sunblood")

	aaLog("stopStartMonitor", "Looking for Monitor window")
	Local $hWnd = WinWaitActive("[CLASS:AutoIt v3 GUI]", "", 10)

	; If it succeeded then click stop/start, if we fail we will try again after another rift
	if $hWnd Then
		aaLog("stopStartMonitor", "Stopping Monitor")
		ControlClick($hWnd, "", "[CLASS:Button; INSTANCE:2]")
		sleep(1000)

		aaLog("stopStartMonitor", "Starting Monitor")
		ControlClick($hWnd, "", "[CLASS:Button; INSTANCE:1]")
		sleep(1000)
	Else
		aaLog("stopStartMonitor", "Failed to find Monitor Window] Returning...")
	EndIf
EndFunc

;===============================================================================
; Description:      changeBotRiftType - Flips DoGreaterRift in RoS Bot between
;                   true and false.
; Parameter(s):  	None
; Return Value(s):  None
;===============================================================================
Func changeBotRiftType($riftType)
	aaLog("changeBotRiftType", "Changing to new rift type in bot",1,0)

    ; Click Configure
	FindBotTitle()
	WinActivate($rosbotwindowtitle)
	Local $hWnd = WinWaitActive("[CLASS:WindowsForms10.Window.8.app.0.9585cb_r6_ad1]")
	ControlClick($hWnd, "", "[CLASS:WindowsForms10.BUTTON.app.0.9585cb_r6_ad1; INSTANCE:2]")
	sleep(200)

	; When true we will swap back and forth between 0 and 100 probability
	; 0 for Rifts and 100 for Grifts. This saves us from waiting 30 seconds
	; after rifts and doesn't waste time leaving game on grifts.
	If $leaveGameOnNormalRift Then

		; Select stay in game probability
		Send("{UP}")
		sleep(200)
		Send("{UP}")
		sleep(200)

		; Change stay in game probability
		If $riftType = 1 Then
			aaLog("changeBotRiftType", "We're running rifts. Changing stay in game probability to 0.")
			ControlSetText("Configure", "", "[CLASS:WindowsForms10.EDIT.app.0.9585cb_r6_ad1; INSTANCE:1]", "0")
		Else
			aaLog("changeBotRiftType", "We're running Greater Rifts. Changing stay in game probability to 100.")
			ControlSetText("Configure", "", "[CLASS:WindowsForms10.EDIT.app.0.9585cb_r6_ad1; INSTANCE:1]", "100")
		EndIf
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
		aaLog("changeBotRiftType", "Setting DoGreaterRift: False")
	ElseIf $riftType = 2 Then
		; DoGreaterRift: True
		ControlClick("Configure", "", "[CLASS:WindowsForms10.BUTTON.app.0.9585cb_r6_ad1; INSTANCE:1]")
		aaLog("changeBotRiftType", "Setting DoGreaterRift: True")
	EndIf

	sleep(100)

	; Click Save
	ControlClick("Configure", "", "[CLASS:WindowsForms10.BUTTON.app.0.9585cb_r6_ad1; INSTANCE:3]")
	aaLog("changeBotRiftType", "Saving rift settings in RoS Bot")
	sleep(300)
EndFunc

;===============================================================================
; Description:      selectArmory - Flips DoGreaterRift in RoS Bot between
;                   true and false.
; Parameter(s):  	$armoryNumber - Armory number to switch to. 1 for Rifts, 2
;                   for grifts. Changes the rift type if we swapped correctly.
; Return Value(s):  None
;===============================================================================
Func selectArmory($armoryNumber)
    If ($armoryNumber = 1 Or $armoryNumber = 2) Then
		aaLog("selectArmory", "Starting armory swap sequence")
		sleep(1000)

		; Activate window
		WinActivate("[CLASS:D3 Main Window Class]")
		sleep(2000)

		; Update the coordinates we will be using to swap gear
		setDiabloWindowLocation()

        ; Map
        Send("{m}")
        sleep(1500)

        ; Old Ruins
		aaLog("selectArmory", "Telporting to Old Ruins")
		MouseMove(367 + $x, 218 + $y)
        MouseClick("left", 367 + $x, 218 + $y, 1, 1)
        sleep(4500)

        ; Teleporter
		MouseMove(404 + $x, 307 + $y)
        MouseClick("left", 404 + $x, 307 + $y, 1, 1)
        sleep(3500)

        ; New Tristam
		aaLog("selectArmory", "Telporting back to New Tristam")
		MouseMove(439 + $x, 300 + $y)
        MouseClick("left", 439 + $x, 300 + $y, 1, 1)
        sleep(4500)

        ; Armory
		MouseMove(185 + $x, 70 + $y)
        MouseClick("left", 185 + $x, 70 + $y, 1, 1)
        sleep(3500)

        ; Click on the Armory 1 or 2
        If $armoryNumber = 1 Then
            ; Armory 1
			aaLog("selectArmory", "Selecting Armory 1")
            MouseClick("left", 293 + $x, 156 + $y, 1, 1)
            sleep(1000)
        ElseIf $armoryNumber = 2 Then
            ; Armory 2
			aaLog("selectArmory", "Selecting Armory 2")
            MouseClick("left", 293 + $x, 227 + $y, 1, 1)
            sleep(1000)
		EndIf

		; Equip the gear in a loop until we detect it changed
		; Fixes an edge case were we can't change because of a
		; Skill on cooldown. Discovered by BinSu. Seems to be
		; CDR / script related.
		For $1 = 1 to 20
			MouseClick("left", 220 + $x, 502 + $y, 1, 2)
			sleep(1000)

			; verify we actually changed
			Local $gearnum = gearOneOrTwo()

			; We changed correctly LETS GO!!!
			If $armoryNumber = $gearnum Then
				aaLog("selectArmory", "Rift type set to: " & $armoryNumber)
				$riftType = $armoryNumber
				Return
			EndIf
		Next
    EndIf
EndFunc

;===============================================================================
; Description:      gearOneOrTwo - Used to detect what gear/skills we have on
;                   at the armory. Currently it detects the quiver and right
;                   mouse button skills.
; Parameter(s):  	None
; Return Value(s):  1 - if we detected armory 1 gear
;                   2 - if we detected armory 2 gear
;                   0 - if there was no winner.
;===============================================================================
Func gearOneOrTwo()
	Local $g1count = 0, $g2count = 0, $g1count2 = 0, $g2count2 = 0
	Local $xx = 0, $yy = 0

	aaLog("selectArmory", "Checking gear and skills")

	setDiabloWindowLocation()

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

	; If the two checks agree then return if we are in A1 or A2 gear
	If ($g1count > $g2count And $g1count2 > $g2count2) Then
		aaLog("selectArmory", "Quiver check: A1 > A2]  Armory 1: " & $g1count & " is >  Armory 2: " & $g2count & "  Returning 1")
		aaLog("selectArmory", "RMB Skill check: A1 > A2]  Armory 1: " & $g1count2 & " is >  Armory 2: " & $g2count2 & "  Returning 1")
		Return 1
	ElseIf ($g1count < $g2count And $g1count2 < $g2count2) Then
		aaLog("selectArmory", "Quiver check: A1 < A2]  Armory 1: " & $g1count & " is <  Armory 2: " & $g2count & "  Returning 2")
		aaLog("selectArmory", "RMB Skill check: A1 < A2]  Armory 1: " & $g1count2 & " is <  Armory 2: " & $g2count2 & "  Returning 2")
		Return 2
	Else
		aaLog("selectArmory", "Quiver check: no winner]  Armory 1: " & $g1count & " Armory 2: " & $g2count & "  Returning 0")
		aaLog("selectArmory", "RMB Skill check: no winner]  Armory 1: " & $g1count2 & " Armory 2: " & $g2count2 & "  Returning 0")
		Return 0
	EndIf
EndFunc


;===============================================================================
; Description:      FindBotTitle - Since RoS Bot window is random we need to
;                   find out the name to interact with it.
; Parameter(s):  	None
; Return Value(s):  Sets $rosbotwindowtitle
;===============================================================================
Func FindBotTitle()
	$list = WinList() ;get a list of every window (this actually includes many hidden system and OS things but that's ok)
	For $i = 1 To $list[0][0]
		If ControlGetHandle($list[$i][0], "", "[TEXT:Start botting !]") <> 0 Then ;if one of the windows has a button on it that says "Start Botting !" (just like that) it's *probably* Rosbot.
			$rosbotwindowtitle = $list[$i][0] ;set the window title that we found
			aaLog("FindBotTitle", "RoS Bot window title found, setting $rosbotwindowtitle to: " & $rosbotwindowtitle)
			ExitLoop ;don't bother checking the rest of the (hundreds of) windows we found
		EndIf
	Next
EndFunc

;Just some shorthand functions for reading ini settings, thanks Sunblood
Func readSetting($section, $key, $default = 0)
	Return IniRead($settingsIni, $section, $key, $default)
EndFunc   ;==>ReadSetting
Func saveSetting($section, $key, $data)
	IniWrite($settingsIni, $section, $key, $data)
EndFunc   ;==>SaveSetting

while 1
sleep(200)
WEnd