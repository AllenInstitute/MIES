#pragma TextEncoding = "UTF-8"		// For details execute DisplayHelpTopic "The TextEncoding Pragma"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function GetDimLabelVsCtrlInfo(win)
	string win
	string CtrlList = GetUniqueCtrlList(controlNameList(win))
	variable ctrlCount = itemsInList(CtrlList)
	print "ctrl count:", ctrlCount
	variable i, dimIndex, value
	WAVE GuiState = GetDA_EphysGuiStateNum(win)
	Variable timerRefNum
	Variable microSeconds
	Variable n
	timerRefNum = startMSTimer
	if (timerRefNum == -1)
		Abort "All timers are in use"
	endif

	for(i=0; i<ctrlCount; i+=1)
	value = GuiState[0][%$stringFromList(i, ctrlList)]
	endfor

	microSeconds = stopMSTimer(timerRefNum)
	Print microSeconds/1000/ctrlCount, "milliseconds for dimLabelSearch"

	timerRefNum = startMSTimer
	if (timerRefNum == -1)
		Abort "All timers are in use"
	endif

	for(i=0; i<=ctrlCount; i+=1)
		controlInfo/W=$win $stringFromList(i, ctrlList)
	endfor

	microSeconds = stopMSTimer(timerRefNum)
	Print microSeconds/1000/ctrlCount, "milliseconds for controlInfo"
End

// This is a testing function to make sure the experiment documentation function is working correctly
Function createDummySettingsWave(panelTitle, SweepCount)
	string panelTitle
	Variable SweepCount

	Make /FREE /N = (1, 6, 8) dummySettingsWave

	Make /FREE /T /N = (3, 6) dummySettingsKey

	// Row 0: Parameter
	// Row 1: Units
	// Row 2: Tolerance factor

	// Add dimension labels to the dummySettingsKey wave
	SetDimLabel 0, 0, Parameter, dummySettingsKey
	SetDimLabel 0, 1, Units, dummySettingsKey
	SetDimLabel 0, 2, Tolerance, dummySettingsKey

	// And now populate the wave
	dummySettingsKey[0][0] =  "Dummy Setting 1"
	dummySettingsKey[1][0] =  "V"
	dummySettingsKey[2][0] =  "0.5"

	dummySettingsKey[0][1] =   "Dummy Setting 2"
	dummySettingsKey[1][1] =  "V"
	dummySettingsKey[2][1] =  "0.5"

	dummySettingsKey[0][2] =   "Dummy Setting 3"
	dummySettingsKey[1][2] =   "V"
	dummySettingsKey[2][2] =   "0.5"

	dummySettingsKey[0][3] =   "Dummy Setting 4"
	dummySettingsKey[1][3] =   "V"
	dummySettingsKey[2][3] =   "0.5"

	dummySettingsKey[0][4] =   "Dummy Setting 5"
	dummySettingsKey[1][4] =   "V"
	dummySettingsKey[2][4] =   "0.05"

	dummySettingsKey[0][5] =   "Dummy Setting 6"
	dummySettingsKey[1][5] =   "V"
	dummySettingsKey[2][5] =   "0.05"

	// Now populate the Settings Wave
	// the wave is 1 row, 15 columns, and headstage number layers
	// first...determine if the head stage is being controlled
	variable headStageControlledCounter
	for(headStageControlledCounter = 0;headStageControlledCounter < NUM_HEADSTAGES ;headStageControlledCounter += 1)
		dummySettingsWave[0][0][headStageControlledCounter] = sweepCount * 0.1
		dummySettingsWave[0][1][headStageControlledCounter] = sweepCount * 0.2
		dummySettingsWave[0][2][headStageControlledCounter] = sweepCount * 0.3
		dummySettingsWave[0][3][headStageControlledCounter] = sweepCount * 0.4
		dummySettingsWave[0][4][headStageControlledCounter] = sweepCount * 0.5
		dummySettingsWave[0][5][headStageControlledCounter] = sweepCount * 0.6
	endfor

	// now call the function that will create the wave notes
	ED_createWaveNotes(dummySettingsWave, dummySettingsKey, SweepCount, panelTitle)
End
