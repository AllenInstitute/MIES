#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

/// @file MIES_ExperimentDocumentation.ipf
/// @brief __ED__ Writing numerical/textual information to the labnotebook

/// @brief Add numerical entries to the labnotebook
///
/// The history wave will use layers to report the different headstages.
///
/// @param incomingNumericalValues settingsWave sent by the each reporting subsystem
/// @param incomingNumericalKeys   key wave that is used to reference the incoming settings wave
/// @param sweepNo                 sweep number
/// @param panelTitle              device
/// @param entrySourceType         type of reporting subsystem, one of @ref DataAcqModes
Function ED_createWaveNotes(incomingNumericalValues, incomingNumericalKeys, sweepNo, panelTitle, entrySourceType)
	wave incomingNumericalValues
	wave/T incomingNumericalKeys
	string panelTitle
	variable sweepNo
	variable entrySourceType

	variable rowIndex, numCols, lastValidIncomingLayer, i

	WAVE/T numericalKeys = GetLBNumericalKeys(panelTitle)
	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	ASSERT(!cmpstr(numericalKeys[0][2], "TimeStampSinceIgorEpochUTC"), "Labnotebook update failed")
	ASSERT(DimSize(incomingNumericalValues, LAYERS) <= DimSize(numericalValues, LAYERS), "Unexpected large layer count in the incoming settings wave")

	WAVE indizes = ED_FindIndizesAndRedimension(incomingNumericalKeys, numericalKeys, numericalValues, rowIndex)

	numericalValues[rowIndex][0] = sweepNo
	numericalValues[rowIndex][1] = DateTime
	numericalValues[rowIndex][2] = DateTimeInUTC()
	numericalValues[rowIndex][3] = entrySourceType

	WAVE numericalValuesDat = ExtractLBColumnTimeStamp(numericalValues)
	EnsureLargeEnoughWave(numericalValuesDat, minimumSize=rowIndex, dimension=ROWS, initialValue=NaN)
	numericalValuesDat[rowIndex] = numericalValues[rowIndex][1]

	numCols = DimSize(incomingNumericalValues, COLS)
	lastValidIncomingLayer = DimSize(incomingNumericalValues, LAYERS) == 0 ? 0 : DimSize(incomingNumericalValues, LAYERS) - 1
	for(i = 0; i < numCols; i += 1)
		numericalValues[rowIndex][indizes[i]][0, lastValidIncomingLayer] = incomingNumericalValues[0][i][r]
	endfor

	SetNumberInWaveNote(numericalValues, NOTE_INDEX, rowIndex + 1)

	SetDimensionLabels(numericalKeys, numericalValues)
	WAVE/Z saveDataWave = GetSweepWave(panelTitle, sweepNo)
	ED_WriteChangedValuesToNote(saveDataWave, incomingNumericalKeys, numericalValues, sweepNo, entrySourceType)
End

/// @brief If the newly written values differ from the values in the last sweep, we write them to the wave note
///
/// Honours tolerances defined in the keywave and "On/Off" values
static Function ED_WriteChangedValuesToNote(saveDataWave, incomingNumericalKeys, numericalValues, sweepNo, entrySourceType)
	Wave/Z saveDataWave
	Wave/T incomingNumericalKeys
	Wave numericalValues
	variable sweepNo, entrySourceType

	string key, factor, unit, text, frontLabel
	string str = ""
	variable tolerance, i, j, numRows, numCols, err

	if(!WaveExists(saveDataWave))
		return NaN
	endif

	numCols = DimSize(incomingNumericalKeys, COLS)
	for (j = 0; j < numCols; j += 1)
		key    = incomingNumericalKeys[0][j]
		unit   = incomingNumericalKeys[1][j]
		factor = incomingNumericalKeys[2][j]
		Wave/Z currentSetting = GetLastSetting(numericalValues, sweepNo, key, entrySourceType)
		Wave/Z lastSetting = GetLastSetting(numericalValues, sweepNo - 1, key, entrySourceType)

		// We have four combinations for the current and the last setting:
		// 1. valid -> valid
		// 2. valid -> invalid
		// 3. invalid -> invalid
		// 4. invalid -> valid

		// In case 3. we have nothing to do, everyting else needs a closer look
		// for 2., 4. we create fake data set to NaN
		// and 1. needs no special treatment
		if(!WaveExists(currentSetting) && !WaveExists(lastSetting))
			continue
		elseif(!WaveExists(lastSetting))
			Duplicate/FREE currentSetting, lastSetting
			lastSetting = NaN
		elseif(!WaveExists(currentSetting))
			Duplicate/FREE lastSetting, currentSetting
			currentSetting = NaN
		endif

		ASSERT(DimSize(currentSetting, ROWS) == DimSize(lastSetting, ROWS), "last and current settings must have the same size")

		if(EqualWaves(currentSetting, lastSetting, 1))
			continue
		endif

		numRows = DimSize(currentSetting, ROWS)
		for(i = 0; i < numRows; i += 1)
			if(currentSetting[i] == lastSetting[i] || (!IsFinite(currentSetting[i]) && !IsFinite(lastSetting[i])))
				continue
			endif

			tolerance = str2num(factor); err = GetRTError(1)

			// in case we have tolerance as "-" we get tolerance == NaN
			// and the following check is false
			if(abs(currentSetting[i] - lastSetting[i]) < tolerance)
				continue
			endif

			if(i < NUM_HEADSTAGES)
				sprintf frontLabel, "HS#%d:" i
			else
				frontLabel = ""
			endif

			if (!cmpstr(factor, "-"))
				sprintf text, "%s%s: %s\r" frontLabel, key, SelectString(currentSetting[i], "Off", "On"); err = GetRTError(1)
			else
				sprintf text, "%s%s: %.2f %s\r" frontLabel, key, currentSetting[i], unit
			endif

			str += text
		endfor
	endfor

	if(!isEmpty(str))
		Note saveDataWave, str
	endif
End

/// @brief If the newly written values differ from the values in the last sweep, we write them to the wave note
///
/// Honours tolerances defined in the keywave and "On/Off" values
static Function ED_WriteChangedValuesToNoteText(saveDataWave, incomingTextualKeys, numericalValues, sweepNo, entrySourceType)
	Wave/Z saveDataWave
	Wave/T incomingTextualKeys
	Wave/T numericalValues
	variable sweepNo, entrySourceType

	string key, factor, text, frontLabel
	string str = ""
	variable tolerance, i, j, numRows, numCols

	if(!WaveExists(saveDataWave))
		return NaN
	endif

	numCols = DimSize(incomingTextualKeys, COLS)
	for (j = 0; j < numCols; j += 1)
		key    = incomingTextualKeys[0][j]
		Wave/T/Z currentSetting = GetLastSettingText(numericalValues, sweepNo, key, entrySourceType)
		Wave/T/Z lastSetting = GetLastSettingText(numericalValues, sweepNo - 1, key, entrySourceType)

		// We have four combinations for the current and the last setting:
		// 1. valid -> valid
		// 2. valid -> invalid
		// 3. invalid -> invalid
		// 4. invalid -> valid

		// In case 3. we have nothing to do, everyting else needs a closer look
		// for 2., 4. we create fake data set to NaN
		// and 1. needs no special treatment
		if(!WaveExists(currentSetting) && !WaveExists(lastSetting))
			continue
		elseif(!WaveExists(lastSetting))
			Duplicate/T/FREE currentSetting, lastSetting
			lastSetting = ""
		elseif(!WaveExists(currentSetting))
			Duplicate/T/FREE lastSetting, currentSetting
			currentSetting = ""
		endif

		ASSERT(DimSize(currentSetting, ROWS) == DimSize(lastSetting, ROWS), "last and current settings must have the same size")

		if(EqualWaves(currentSetting, lastSetting, 1))
			continue
		endif

		numRows = DimSize(currentSetting, ROWS)
		for(i = 0; i < numRows; i += 1)
			if(!cmpstr(currentSetting[i], lastSetting[i]))
				continue
			endif

			if(i < NUM_HEADSTAGES)
				sprintf frontLabel, "HS#%d:" i
			else
				frontLabel = ""
			endif

			sprintf text, "%s%s: %s\r" frontLabel, key, currentSetting[i]
			str += text
		endfor
	endfor

	if(!isEmpty(str))
		Note saveDataWave, str
	endif
End

/// @brief Returns the column indizes of each parameter in incomingKey into the `key` wave
///
/// Redimensions `key` and `values` waves.
/// Prefills `key` with `incomingKey` data if necessary.
///
/// Ensures that data and key have a matching column size at return.
/// @param[in]  incomingKey text wave with the keys to add
/// @param[in]  key         key wave of the labnotebook
/// @param[in]  values      values/data wave of the labnotebook
/// @param[out] rowIndex    returns the row index into values at which the new values should be written
static Function/Wave ED_FindIndizesAndRedimension(incomingKey, key, values, rowIndex)
	WAVE/T incomingKey, key
	WAVE values
	variable &rowIndex

	variable numCols, col, row, numKeyRows, numKeyCols, i, numAdditions, idx
	variable lastValidIncomingKeyRow
	string msg, searchStr

	numKeyRows = DimSize(key, ROWS)
	numKeyCols = DimSize(key, COLS)
	lastValidIncomingKeyRow = DimSize(incomingKey, ROWS) - 1

	Make/FREE/U/I/N=(DimSize(incomingKey, COLS)) indizes = NaN

	numCols = DimSize(incomingKey, COLS)
	for(i = 0; i < numCols; i += 1)
		searchStr = incomingKey[0][i]
		ASSERT(!isEmpty(searchStr), "Incoming key can not be empty")

		FindValue/TXOP=4/TEXT=(searchStr) key
		col = floor(V_value / numKeyRows)

		if(col >= 0)
			row = V_value - col * numKeyRows
			ASSERT(row == 0, "Unexpected match in a row not being zero")
			indizes[i] = col
			sprintf msg, "Found key \"%s\" from incoming column %d in key column %d", incomingKey[0][i], i, idx
			DEBUGPRINT(msg)
		else
			idx = numKeyCols + numAdditions
			EnsureLargeEnoughWave(key, minimumSize=idx, dimension=COLS)
			ASSERT(strlen(incomingKey[0][i]) > 0, "can not handle empty incoming key")
			key[0, lastValidIncomingKeyRow][idx] = incomingKey[p][i]
			indizes[i] = idx
			numAdditions += 1
			sprintf msg, "Created key \"%s\" from incoming column %d in key column %d", incomingKey[0][i], i, idx
			DEBUGPRINT(msg)
		endif
	endfor

	// for further performance enhancement we must add "support for enhancing multiple dimensions at once"
	// to EnsureLargeEnoughWave
	if(numAdditions)
		Redimension/N=(-1, numKeyCols + numAdditions, -1) key, values
	endif

	rowIndex = GetNumberFromWaveNote(values, NOTE_INDEX)
	if(!IsFinite(rowIndex))
		// old waves don't have that info
		// use the last row
		rowIndex = DimSize(values, ROWS)
	endif

	if(WaveType(values)) // numeric
		EnsureLargeEnoughWave(values, minimumSize=rowIndex, dimension=ROWS, initialValue=NaN)
		if(numAdditions)
			values[][numKeyCols,][] = NaN
		endif
	else
		EnsureLargeEnoughWave(values, minimumSize=rowIndex, dimension=ROWS)
	endif

	return indizes
End

/// @brief Add textual entries to the labnotebook
///
/// The text documentation wave will use layers to report the different headstages.
///
/// @param incomingTextualValues  incoming Text Documentation Wave sent by the each reporting subsystem
/// @param incomingTextualKeys    incoming Text Documentation key wave that is used to reference the incoming settings wave
/// @param sweepNo                sweep number
/// @param panelTitle             device
/// @param entrySourceType         type of reporting subsystem, one of @ref DataAcqModes
Function ED_createTextNotes(incomingTextualValues, incomingTextualKeys, sweepNo, panelTitle, entrySourceType)
	wave/T incomingTextualValues
	wave/T incomingTextualKeys
	string panelTitle
	variable sweepNo, entrySourceType

	variable rowIndex, numCols, i, lastValidIncomingLayer

	WAVE/T textualValues = GetLBTextualValues(panelTitle)
	WAVE/T textualKeys   = GetLBTextualKeys(panelTitle)

	ASSERT(!cmpstr(textualKeys[0][2], "TimeStampSinceIgorEpochUTC"), "Labnotebook update failed")
	ASSERT(DimSize(incomingTextualValues, ROWS)   == 1, "Mismatched row counts")
	ASSERT(DimSize(incomingTextualValues, LAYERS) <= DimSize(textualValues, LAYERS), "Mismatched layer counts")
	ASSERT(DimSize(incomingTextualValues, COLS)   == DimSize(incomingTextualKeys, COLS), "Mismatched column counts")

	WAVE indizes = ED_FindIndizesAndRedimension(incomingTextualKeys, textualKeys, textualValues, rowIndex)

	textualValues[rowIndex][0] = num2istr(sweepNo)
	textualValues[rowIndex][1] = num2istr(DateTime)
	textualValues[rowIndex][2] = num2istr(DateTimeInUTC())
	textualValues[rowIndex][3] = num2istr(entrySourceType)

	WAVE textualValuesDat = ExtractLBColumnTimeStamp(textualValues)
	EnsureLargeEnoughWave(textualValuesDat, minimumSize=rowIndex, dimension=ROWS)
	textualValuesDat[rowIndex] = str2num(textualValues[rowIndex][1])

	WAVE textualValuesSweep = ExtractLBColumnSweep(textualValues)
	EnsureLargeEnoughWave(textualValuesSweep, minimumSize=rowIndex, dimension=ROWS)
	textualValuesSweep[rowIndex] = str2num(textualValues[rowIndex][0])

	numCols = DimSize(incomingTextualValues, COLS)
	lastValidIncomingLayer = DimSize(incomingTextualValues, LAYERS) == 0 ? 0 : DimSize(incomingTextualValues, LAYERS) - 1
	for(i = 0; i < numCols; i += 1)
		textualValues[rowIndex][indizes[i]][0, lastValidIncomingLayer] = incomingTextualValues[0][i][r]
	endfor

	SetNumberInWaveNote(textualValues, NOTE_INDEX, rowIndex + 1)

	SetDimensionLabels(textualKeys, textualValues)

	WAVE/Z saveDataWave = GetSweepWave(panelTitle, sweepNo)
	ED_WriteChangedValuesToNoteText(saveDataWave, incomingTextualKeys, textualValues, sweepNo, entrySourceType)
End

/// @brief Add sweep specific information to the labnotebook
Function ED_createWaveNoteTags(panelTitle, sweepCount)
	string panelTitle
	variable sweepCount

	variable i, j

	WAVE sweepSettingsWave = GetSweepSettingsWave(panelTitle)
	WAVE/T sweepSettingsKey = GetSweepSettingsKeyWave(panelTitle)
	ED_createWaveNotes(sweepSettingsWave, sweepSettingsKey, SweepCount, panelTitle, DATA_ACQUISITION_MODE)

	WAVE/T sweepSettingsTxtWave = GetSweepSettingsTextWave(panelTitle)
	WAVE/T sweepSettingsTxtKey = GetSweepSettingsTextKeyWave(panelTitle)
	ED_createTextNotes(sweepSettingsTxtWave, sweepSettingsTxtKey, SweepCount, panelTitle, DATA_ACQUISITION_MODE)

	// document active headstages and their clamp modes
	Make/FREE/N=(3, 2)/T numKeys
	numKeys = ""

	numKeys[0][0] =  "Headstage Active"
	numKeys[1][0] =  "On/Off"
	numKeys[2][0] =  "-"

	numKeys[0][1] =  "Clamp Mode"
	numKeys[1][1] =  ""
	numKeys[2][1] =  "-"

	WAVE statusHS = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	Make/FREE/N=(1, 2, LABNOTEBOOK_LAYER_COUNT) numSettings = NaN
	numSettings[0][0][0,7] = statusHS[r]

	WAVE activeHSProp = GetActiveHSProperties(panelTitle)
	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(!statusHS[i])
			continue
		endif

		numSettings[0][1][i] = activeHSProp[j][%ClampMode]
		j += 1
	endfor

	ED_createWaveNotes(numSettings, numKeys, SweepCount, panelTitle, DATA_ACQUISITION_MODE)

	Make/FREE/T/N=(3, 2) keys
	keys = ""

	keys[0][0] = "Follower Device"
	keys[1][0] = "On/Off"
	keys[2][0] = "-"

	keys[0][1] = "MIES version"
	keys[1][1] = "On/Off"
	keys[2][1] = "-"

	Make/FREE/T/N=(1, 2, LABNOTEBOOK_LAYER_COUNT) values
	values = ""

	if(DeviceCanLead(panelTitle))
		SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)
		values[0][0][INDEP_HEADSTAGE] = listOfFollowerDevices
	endif

	SVAR miesVersion = $GetMiesVersion()
	values[0][1][INDEP_HEADSTAGE] = miesVersion

	ED_createTextNotes(values, keys, SweepCount, panelTitle, DATA_ACQUISITION_MODE)

	if(GetCheckboxState(panelTitle, "check_Settings_SaveAmpSettings"))
		AI_FillAndSendAmpliferSettings(panelTitle, sweepCount)
		// function for debugging
		// AI_createDummySettingsWave(panelTitle, SweepNo)
	endif

	if(GetCheckboxState(panelTitle, "Check_Settings_Append"))
		ED_createAsyncWaveNoteTags(panelTitle, sweepCount)
	endif

	// TP settings, especially useful if "global TP insertion" is active
	ED_TPSettingsDocumentation(panelTitle, DATA_ACQUISITION_MODE)
End

/// @brief Write the user comment from the DA_Ephys panel to the labnotebook
Function ED_WriteUserCommentToLabNB(panelTitle, comment, sweepNo)
	string panelTitle
	string comment
	variable sweepNo

	Make/FREE/N=(3, 1)/T keys
	keys = ""

	keys[0][0] =  "User comment"
	keys[1][0] =  ""
	keys[2][0] =  "-"


	Make/FREE/T/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values
	values[][][8] = comment

	ED_createTextNotes(values, keys, sweepNo, panelTitle, UNKNOWN_MODE)
End

/// @brief This function is used to create wave notes for the informations found in the Asynchronous tab in the DA_Ephys panel
static Function ED_createAsyncWaveNoteTags(panelTitle, sweepCount)
	string panelTitle
	Variable sweepCount

	string ctrl
	variable minSettingValue, maxSettingValue

	Wave asyncSettingsWave = GetAsyncSettingsWave()
	Wave/T asyncSettingsKey = GetAsyncSettingsKeyWave()

	Wave/T asyncSettingsTxtWave = GetAsyncSettingsTextWave()
	Wave/T asyncSettingsTxtKey = GetAsyncSettingsTextKeyWave()

	Wave asyncMeasurementWave = GetAsyncMeasurementWave()
	Wave/T asyncMeasurementKey = GetAsyncMeasurementKeyWave()

	variable asyncVariablesCounter
	for(asyncVariablesCounter = 0;asyncVariablesCounter < NUM_ASYNC_CHANNELS ;asyncVariablesCounter += 1)
		ctrl = GetPanelControl(asyncVariablesCounter, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_CHECK)

		if (GetCheckBoxState(panelTitle, ctrl))
			asyncSettingsWave[0][asyncVariablesCounter] = CHECKBOX_SELECTED

			ctrl = GetPanelControl(asyncVariablesCounter, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN)
			asyncSettingsWave[0][asyncVariablesCounter + 8] = GetSetVariable(panelTitle, ctrl)

			ctrl = GetPanelControl(asyncVariablesCounter, CHANNEL_TYPE_ALARM, CHANNEL_CONTROL_CHECK)
			minSettingValue = GetCheckBoxState(panelTitle, ctrl)
			asyncSettingsWave[0][asyncVariablesCounter + 16] = minSettingValue
			
			ctrl = GetPanelControl(asyncVariablesCounter, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN)
			maxSettingValue = GetSetVariable(panelTitle, ctrl)
			asyncSettingsWave[0][asyncVariablesCounter + 24] = maxSettingValue
			
			ctrl = GetPanelControl(asyncVariablesCounter, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX)
			minSettingValue = GetSetVariable(panelTitle, ctrl)
			asyncSettingsWave[0][asyncVariablesCounter + 32] = minSettingValue
	
			// Take the Min and Max values and use them for setting the tolerance value in the measurement key wave
			asyncMeasurementKey[%Tolerance][asyncVariablesCounter] = num2str(abs((maxSettingValue - minSettingValue)/2))
	
			//Now do the text stuff...
			// Async Title
			sprintf ctrl, "SetVar_AsyncAD_Title_0%d" asyncVariablesCounter
			string titleStringValue = GetSetVariableString(panelTitle, ctrl)
			string adTitleStringValue 
			sprintf adTitleStringValue, "Async AD %d: %s" asyncVariablesCounter, titleStringValue
			asyncSettingsTxtWave[0][asyncVariablesCounter] = titleStringValue
			// add the text unit value into the measurementKey Wave
			asyncMeasurementKey[%Parameter][asyncVariablesCounter] = adTitleStringValue

			ctrl = GetPanelControl(asyncVariablesCounter, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_UNIT)
			string unitStringValue = GetSetVariableString(panelTitle, ctrl)
			string adUnitStringValue
			sprintf adUnitStringValue, "Async AD %d: %s" asyncVariablesCounter, unitStringValue
			asyncSettingsTxtWave[0][asyncVariablesCounter + 8] = adUnitStringValue
			// add the unit value into numericalKeys
			asyncMeasurementKey[%Units][asyncVariablesCounter] = adUnitStringValue
		endif
	endfor

	ED_createTextNotes(asyncSettingsTxtWave, asyncSettingsTxtKey, sweepCount, panelTitle, DATA_ACQUISITION_MODE)
	ED_createWaveNotes(asyncSettingsWave, asyncSettingsKey, SweepCount, panelTitle, DATA_ACQUISITION_MODE)

	ITC_ADDataBasedWaveNotes(asyncMeasurementWave, panelTitle)
	ED_createWaveNotes(asyncMeasurementWave, asyncMeasurementKey, SweepCount, panelTitle, DATA_ACQUISITION_MODE)
End

/// @brief Stores test pulse related data in the labnotebook
Function ED_TPDocumentation(panelTitle)
	string panelTitle

	variable sweepNo, RTolerance, numActiveHS
	variable i, j
	DFREF dfr = GetDeviceTestPulse(panelTitle)
	WAVE activeHSProp = GetActiveHSProperties(panelTitle)

	WAVE/Z/SDFR=dfr BaselineSSAvg
	WAVE/Z/SDFR=dfr InstResistance
	WAVE/Z/SDFR=dfr SSResistance

	if(!WaveExists(BaselineSSAvg) || !WaveExists(InstResistance) || !WaveExists(SSResistance))
		return NaN
	endif

	WAVE statusHS = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	numActiveHS = Sum(statusHS)

	if(DimSize(BaselineSSAvg, COLS) != numActiveHS || DimSize(InstResistance, COLS) != numActiveHS || DimSize(SSResistance, COLS) != numActiveHS)
		return NaN
	endif

	Make/FREE/T/N=(3, 12) TPKeyWave
	Make/FREE/N=(1, 12, LABNOTEBOOK_LAYER_COUNT) TPSettingsWave = NaN

	// add data to TPKeyWave
	TPKeyWave[0][0]  = "TP Baseline Vm"  // current clamp
	TPKeyWave[0][1]  = "TP Baseline pA"  // voltage clamp
	TPKeyWave[0][2]  = "TP Peak Resistance"
	TPKeyWave[0][3]  = "TP Steady State Resistance"
	// same names as  in GetAmplifierSettingsKeyWave
	TPKeyWave[0][4]  = "Fast compensation capacitance"
	TPKeyWave[0][5]  = "Slow compensation capacitance"
	TPKeyWave[0][6]  = "Fast compensation time"
	TPKeyWave[0][7]  = "Slow compensation time"
	TPKeyWave[0][8]  = "Headstage Active"
	TPKeyWave[0][9]  = "DAC"
	TPKeyWave[0][10] = "ADC"
	TPKeyWave[0][11] = "Clamp Mode"

	TPKeyWave[1][0]  = "mV"
	TPKeyWave[1][1]  = "pA"
	TPKeyWave[1][2]  = "Mohm"
	TPKeyWave[1][3]  = "Mohm"
	TPKeyWave[1][4]  = "F"
	TPKeyWave[1][5]  = "F"
	TPKeyWave[1][6]  = "s"
	TPKeyWave[1][7]  = "s"
	TPKeyWave[1][8]  = "On/Off"
	TPKeyWave[1][9]  = ""
	TPKeyWave[1][10] = ""
	TPKeyWave[1][11] = ""

	RTolerance = GetSetVariable(panelTitle, "setvar_Settings_TP_RTolerance")
	TPKeyWave[2][0]  = "1" // Assume a tolerance of 1 mV for V rest
	TPKeyWave[2][1]  = "50" // Assume a tolerance of 50pA for I rest
	TPKeyWave[2][2]  = num2str(RTolerance) // applies the same R tolerance for the instantaneous and steady state resistance
	TPKeyWave[2][3]  = num2str(RTolerance)
	TPKeyWave[2][4]  = "1e-12"
	TPKeyWave[2][5]  = "1e-12"
	TPKeyWave[2][6]  = "1e-6"
	TPKeyWave[2][7]  = "1e-6"
	TPKeyWave[2][8]  = "-"
	TPKeyWave[2][9]  = "0.0001"
	TPKeyWave[2][10] = "0.0001"
	TPKeyWave[2][11] = "-"

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		TPSettingsWave[0][8][i] = statusHS[i]

		if(!statusHS[i])
			continue
		endif

		if(activeHSProp[j][%ClampMode] == V_CLAMP_MODE)
			TPSettingsWave[0][4][i] = AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_GETFASTCOMPCAP_FUNC, NaN)
			TPSettingsWave[0][5][i] = AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_GETSLOWCOMPCAP_FUNC, NaN)
			TPSettingsWave[0][6][i] = AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_GETFASTCOMPTAU_FUNC, NaN)
			TPSettingsWave[0][7][i] = AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_GETSLOWCOMPTAU_FUNC, NaN)
			TPSettingsWave[0][1][i] = BaselineSSAvg[0][j]
		else
			TPSettingsWave[0][0][i] = BaselineSSAvg[0][j]
		endif

		TPSettingsWave[0][2][i]  = InstResistance[0][j]
		TPSettingsWave[0][3][i]  = SSResistance[0][j]
		TPSettingsWave[0][9][i]  = activeHSProp[j][%DAC]
		TPSettingsWave[0][10][i] = activeHSProp[j][%ADC]
		TPSettingsWave[0][11][i] = activeHSProp[j][%ClampMode]
		j += 1 //  BaselineSSAvg, InstResistance, SSResistance only have a column for each active
			   // headstage (no place holder columns), j only increments for active headstages.
	endfor

	sweepNo = AFH_GetLastSweepAcquired(panelTitle)
	ED_createWaveNotes(TPSettingsWave, TPKeyWave, sweepNo, panelTitle, TEST_PULSE_MODE)

	ED_TPSettingsDocumentation(panelTitle, TEST_PULSE_MODE)
End

/// @brief Document the settings of the Testpulse
///
/// The source type entry is not fixed. We want to document the testpulse
/// settings during ITI and the testpulse settings for plaint test pulses.
///
/// @param panelTitle      device
/// @param entrySourceType type of reporting subsystem, one of @ref DataAcqModes
static Function ED_TPSettingsDocumentation(panelTitle, entrySourceType)
	string panelTitle
	variable entrySourceType

	variable sweepNo
	NVAR/SDFR=GetDeviceTestPulse(panelTitle) baselineFrac, AmplitudeVC, AmplitudeIC, pulseDuration

	Make/FREE/T/N=(3, 4) TPKeyWave
	Make/FREE/N=(1, 4, LABNOTEBOOK_LAYER_COUNT) TPSettingsWave = NaN

	// name
	TPKeyWave[0][0] = "TP Baseline Fraction" // fraction of total TP duration
	TPKeyWave[0][1] = "TP Amplitude VC"
	TPKeyWave[0][2] = "TP Amplitude IC"
	TPKeyWave[0][3] = "TP Pulse Duration"

	// unit
	TPKeyWave[1][0] = ""
	TPKeyWave[1][1] = ""
	TPKeyWave[1][2] = ""
	TPKeyWave[1][3] = "ms"

	// tolerance
	TPKeyWave[2][0] = ""
	TPKeyWave[2][1] = ""
	TPKeyWave[2][2] = ""
	TPKeyWave[2][3] = ""

	// the settings are valid for all headstages
	TPSettingsWave[0][0][INDEP_HEADSTAGE] = baselineFrac
	TPSettingsWave[0][1][INDEP_HEADSTAGE] = AmplitudeVC
	TPSettingsWave[0][2][INDEP_HEADSTAGE] = AmplitudeIC
	TPSettingsWave[0][3][INDEP_HEADSTAGE] = pulseDuration

	sweepNo = AFH_GetLastSweepAcquired(panelTitle)
	ED_createWaveNotes(TPSettingsWave, TPKeyWave, sweepNo, panelTitle, entrySourceType)
End
