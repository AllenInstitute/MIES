#pragma TextEncoding = "UTF-8"		// For details execute DisplayHelpTopic "The TextEncoding Pragma"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

Function GetDimLabelVsCtrlInfo(win)
	string win

	variable i, value
	variable timerRefNum
	variable microSeconds
	variable numTrials = 10000

	DAP_RecordDA_EphysGuiState(win)
	WAVE GuiState = GetDA_EphysGuiStateNum(win)

	timerRefNum = startMSTimer
	if (timerRefNum == -1)
		Abort "All timers are in use"
	endif

	for(i=0; i<numTrials; i+=1)
		value = GuiState[0][%Check_DataAcq1_RepeatAcq]
	endfor

	microSeconds = stopMSTimer(timerRefNum)
	Print microSeconds/1000/numTrials, "milliseconds for dimLabelSearch"

	timerRefNum = startMSTimer
	if (timerRefNum == -1)
		Abort "All timers are in use"
	endif

	for(i=0; i< numTrials; i+=1)
		value = GetCheckBoxState(win, "Check_DataAcq1_RepeatAcq")
	endfor

	microSeconds = stopMSTimer(timerRefNum)
	Print microSeconds/1000/numTrials, "milliseconds for controlInfo"
End

// This is a testing function to make sure the experiment documentation function is working correctly
Function createDummySettingsWave(device, SweepCount)
	string device
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
	ED_AddEntriesToLabnotebook(dummySettingsWave, dummySettingsKey, SweepCount, device, UNKNOWN_MODE)
End

/// @brief Exhaust all memory so that only `amountOfFreeMemoryLeft` [GB] is left
///
/// Unwise use of this function can break Igor!
Function ExhaustMemory(amountOfFreeMemoryLeft)
	variable amountOfFreeMemoryLeft

	variable i, expo=10, err
	string str

	for(i = expo; i >= 0;)
		err = GetRTError(1)
		str = UniqueName("base", 1, 0)
		Make/D/N=(10^expo) $str; err = GetRTError(1)

		if(err != 0)
			expo -= 1
		endif

		printf "Free Memory: %gGB\r", GetFreeMemory()

		if(GetFreeMemory() < amountOfFreeMemoryLeft)
			break
		endif
	endfor
End
