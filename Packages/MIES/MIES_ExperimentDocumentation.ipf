#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_ED
#endif

/// @file MIES_ExperimentDocumentation.ipf
/// @brief __ED__ Writing numerical/textual information to the labnotebook

/// @brief Add numerical/textual entries to the labnotebook
///
/// @see ED_createTextNotes, ED_createWaveNote
Function ED_AddEntriesToLabnotebook(vals, keys, sweepNo, panelTitle, entrySourceType)
	wave vals, keys
	string panelTitle
	variable sweepNo, entrySourceType

	ASSERT(DimSize(vals, ROWS)   == 1, "Mismatched row count")
	ASSERT(DimSize(vals, COLS)   == DimSize(keys, COLS), "Mismatched column count")
	ASSERT(DimSize(vals, LAYERS) <= LABNOTEBOOK_LAYER_COUNT, "Mismatched layer count")

	ASSERT(DimSize(keys, ROWS)   == 1 || DimSize(keys, ROWS) == 3, "Mismatched row count")
	ASSERT(DimSize(keys, LAYERS) <= 1, "Mismatched layer count")

	if(IsTextWave(vals))
		ED_createTextNotes(vals, keys, sweepNo, panelTitle, entrySourceType)
	else
		ED_createWaveNotes(vals, keys, sweepNo, panelTitle, entrySourceType)
	endif
End

/// @brief Add textual entries to the labnotebook
///
/// The text documentation wave will use layers to report the different headstages.
///
/// The incoming value wave can have zero to nine (#NUM_HEADSTAGES + 1) layers. The
/// first eight layers are for headstage dependent data, the last layer for
/// headstage independent data.
///
/// @param incomingTextualValues  incoming Text Documentation Wave sent by the each reporting subsystem
/// @param incomingTextualKeys    incoming Text Documentation key wave that is used to reference the incoming settings wave
/// @param sweepNo                sweep number
/// @param panelTitle             device
/// @param entrySourceType         type of reporting subsystem, one of @ref DataAcqModes
static Function ED_createTextNotes(incomingTextualValues, incomingTextualKeys, sweepNo, panelTitle, entrySourceType)
	wave/T incomingTextualValues
	wave/T incomingTextualKeys
	string panelTitle
	variable sweepNo, entrySourceType

	variable rowIndex, numCols, i, lastValidIncomingLayer, state
	string timestamp

	WAVE/T textualValues = GetLBTextualValues(panelTitle)
	WAVE/T textualKeys   = GetLBTextualKeys(panelTitle)

	WAVE indizes = ED_FindIndizesAndRedimension(incomingTextualKeys, textualKeys, textualValues, rowIndex)

	textualValues[rowIndex][0][] = num2istr(sweepNo)
	textualValues[rowIndex][3][] = num2istr(entrySourceType)

	state = ROVar(GetAcquisitionState(panelTitle))
	textualValues[rowIndex][4][] = num2istr(state)

	// store the current time in a variable first
	// so that all layers have the same timestamp
	timestamp = num2strHighPrec(DateTime, precision = 3)
	textualValues[rowIndex][1][] = timestamp
	timestamp = num2strHighPrec(DateTimeInUTC(), precision = 3)
	textualValues[rowIndex][2][] = timestamp

	WAVE textualValuesDat = ExtractLogbookSliceTimeStamp(textualValues)
	EnsureLargeEnoughWave(textualValuesDat, minimumSize=rowIndex, dimension=ROWS)
	textualValuesDat[rowIndex] = str2num(textualValues[rowIndex][1])

	WAVE textualValuesSweep = ExtractLogbookSliceSweep(textualValues)
	EnsureLargeEnoughWave(textualValuesSweep, minimumSize=rowIndex, dimension=ROWS)
	textualValuesSweep[rowIndex] = str2num(textualValues[rowIndex][0])

	numCols = DimSize(incomingTextualValues, COLS)
	lastValidIncomingLayer = DimSize(incomingTextualValues, LAYERS) == 0 ? 0 : DimSize(incomingTextualValues, LAYERS) - 1
	for(i = 0; i < numCols; i += 1)
		textualValues[rowIndex][indizes[i]][0, lastValidIncomingLayer] = NormalizeToEOL(incomingTextualValues[0][i][r], "\n")
	endfor

	SetNumberInWaveNote(textualValues, NOTE_INDEX, rowIndex + 1)

	LBN_SetDimensionLabels(textualKeys, textualValues)
End

/// @brief Add numerical entries to the labnotebook
///
/// The history wave will use layers to report the different headstages.
///
/// The incoming value wave can have zero to nine #LABNOTEBOOK_LAYER_COUNT
/// layers. The first eight layers are for headstage dependent data, the last
/// layer for headstage independent data.
///
/// @param incomingNumericalValues settingsWave sent by the each reporting subsystem
/// @param incomingNumericalKeys   key wave that is used to reference the incoming settings wave
/// @param sweepNo                 sweep number
/// @param panelTitle              device
/// @param entrySourceType         type of reporting subsystem, one of @ref DataAcqModes
static Function ED_createWaveNotes(incomingNumericalValues, incomingNumericalKeys, sweepNo, panelTitle, entrySourceType)
	wave incomingNumericalValues
	wave/T incomingNumericalKeys
	string panelTitle
	variable sweepNo
	variable entrySourceType

	variable rowIndex, numCols, lastValidIncomingLayer, i, timestamp, state

	WAVE/T numericalKeys = GetLBNumericalKeys(panelTitle)
	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	WAVE indizes = ED_FindIndizesAndRedimension(incomingNumericalKeys, numericalKeys, numericalValues, rowIndex)

	numericalValues[rowIndex][0][] = sweepNo
	numericalValues[rowIndex][3][] = entrySourceType

	state = ROVar(GetAcquisitionState(panelTitle))
	numericalValues[rowIndex][4][] = state

	// store the current time in a variable first
	// so that all layers have the same timestamp
	timestamp = DateTime
	numericalValues[rowIndex][1][] = timestamp
	timestamp = DateTimeInUTC()
	numericalValues[rowIndex][2][] = timestamp

	WAVE numericalValuesDat = ExtractLogbookSliceTimeStamp(numericalValues)
	EnsureLargeEnoughWave(numericalValuesDat, minimumSize=rowIndex, dimension=ROWS, initialValue=NaN)
	numericalValuesDat[rowIndex] = numericalValues[rowIndex][1]

	numCols = DimSize(incomingNumericalValues, COLS)
	lastValidIncomingLayer = DimSize(incomingNumericalValues, LAYERS) == 0 ? 0 : DimSize(incomingNumericalValues, LAYERS) - 1
	for(i = 0; i < numCols; i += 1)
		numericalValues[rowIndex][indizes[i]][0, lastValidIncomingLayer] = incomingNumericalValues[0][i][r]
	endfor

	SetNumberInWaveNote(numericalValues, NOTE_INDEX, rowIndex + 1)

	LBN_SetDimensionLabels(numericalKeys, numericalValues)
End

/// @brief Add custom entries to the numerical/textual labnotebook for the very last sweep acquired.
///
/// The entries are prefixed with `USER_` to distinguish them
/// from stock MIES entries.
///
/// The index of the entry in `values` determines the headstage to which the setting applies.
/// You can not set both headstage dependent and independent values at the same time as this
/// does not make sense.
///
/// Sample invocation:
/// \rst
/// .. code-block:: igorpro
///
/// 	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
/// 	values[0] = 4711 // setting of the first headstage
/// 	ED_AddEntryToLabnotebook(device, "SomeSetting", values)
/// \endrst
///
/// The later on the labnotebook can be queried with:
/// \rst
/// .. code-block:: igorpro
///
///		WAVE/Z settings = GetLastSetting(numericalValues, NaN, LABNOTEBOOK_USER_PREFIX + key, UNKNOWN_MODE)
/// \endrst
///
/// @param panelTitle      device
/// @param key             name under which to store the entry.
/// @param values          entry to add, wave can be numeric (floating point) or text, must have
///                        #LABNOTEBOOK_LAYER_COUNT rows. It can be all NaN or empty (text), this is useful
///                        if you want to make the key known without adding an entry.
/// @param unit            [optional, defaults to ""] physical unit of the entry
/// @param tolerance       [optional, defaults to #LABNOTEBOOK_NO_TOLERANCE] tolerance of the entry, used for
///                        judging if a change is "relevant" and should then be written to the sweep wave
/// @param overrideSweepNo [optional, defaults to last acquired sweep] Adds metadata to the
///                        given sweep number. Mostly useful for adding
///                        labnotebook entries during #MID_SWEEP_EVENT for
///                        analysis functions.
Function ED_AddEntryToLabnotebook(panelTitle, key, values, [unit, tolerance, overrideSweepNo])
	string panelTitle, key
	WAVE values
	string unit
	variable tolerance, overrideSweepNo

	string toleranceStr
	variable sweepNo

	ASSERT(!IsEmpty(key), "Empty key")
	ASSERT(DimSize(values, ROWS) == LABNOTEBOOK_LAYER_COUNT, "wv has the wrong number of rows")
	ASSERT(DimSize(values, COLS) == 0, "wv must be 1D")
	ASSERT(IsTextWave(values) || IsFloatingPointWave(values), "Wave must be text or floating point")
	ASSERT(strsearch(key, LABNOTEBOOK_USER_PREFIX, 0, 2) != 0, "Don't prefix key with LABNOTEBOOK_USER_PREFIX")

	// check input
	if(IsTextWave(values))
		WAVE/T valuesText = values
		Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) stats = strlen(valuesText[p]) == 0 ? NaN : 1
	else
		Wave stats = values
	endif

	// either INDEP_HEADSTAGE is set or one of the headstage entries but never both
	WaveStats/Q/M=1 stats
	ASSERT((IsFinite(stats[INDEP_HEADSTAGE]) && V_numNaNs == NUM_HEADSTAGES) || !IsFinite(stats[INDEP_HEADSTAGE]), \
	  "The independent headstage entry can not be combined with headstage dependent entries.")

	// we allow all entries to be NaN or empty

	if(ParamIsDefault(unit))
		unit = ""
	endif

	if(ParamIsDefault(tolerance) || !IsFinite(tolerance))
		toleranceStr = LABNOTEBOOK_NO_TOLERANCE
	else
		toleranceStr = num2str(tolerance)
	endif

	if(ParamIsDefault(overrideSweepNo))
		sweepNo = AFH_GetLastSweepAcquired(panelTitle)
	else
		ASSERT(isInteger(overrideSweepNo) && overrideSweepNo >= 0, "Invalid override sweep number")
		sweepNo = overrideSweepNo
	endif

	Duplicate/FREE values, valuesReshaped
	Redimension/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) valuesReshaped

	Make/FREE/T/N=(3, 1) keys
	keys[0] = LABNOTEBOOK_USER_PREFIX + key
	keys[1] = unit
	keys[2] = toleranceStr

	ASSERT(strlen(keys[0]) < MAX_OBJECT_NAME_LENGTH_IN_BYTES, "key is too long: \"" + keys[0] + "\"")

	ED_AddEntriesToLabnotebook(valuesReshaped, keys, sweepNo, panelTitle, UNKNOWN_MODE)
End

/// @brief Record changed labnotebook entries compared to the last sweep to the sweep wave note
///
/// Honours tolerances defined in the keywave and LABNOTEBOOK_BINARY_UNIT values
static Function ED_WriteChangedValuesToNote(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	string key, factor, unit, text, frontLabel
	string str = ""
	variable tolerance, i, j, numRows, numCols, err

	WAVE/T numericalKeys = GetLBNumericalKeys(panelTitle)
	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	// prefill the row cache for the labnotebook
	WAVE/Z junk = GetLastSetting(numericalValues, sweepNo, "TimeStamp", UNKNOWN_MODE)
	WAVE/Z junk = GetLastSetting(numericalValues, sweepNo - 1, "TimeStamp", UNKNOWN_MODE)

	numCols = DimSize(numericalKeys, COLS)
	for (j = INITIAL_KEY_WAVE_COL_COUNT + 1; j < numCols; j += 1)
		key    = numericalKeys[0][j]
		unit   = numericalKeys[1][j]
		factor = numericalKeys[2][j]

		Wave/Z currentSetting = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
		Wave/Z lastSetting = GetLastSetting(numericalValues, sweepNo - 1, key, UNKNOWN_MODE)

		// We have four combinations for the current and the last setting:
		// 1. valid -> valid
		// 2. valid -> invalid
		// 3. invalid -> invalid
		// 4. invalid -> valid

		// In case 2. and 3. we have nothing to do, everyting else needs a closer look
		// for 4. we create fake data set to NaN
		// and 1. needs no special treatment
		if(!WaveExists(currentSetting))
			continue
		elseif(!WaveExists(lastSetting))
			Duplicate/FREE currentSetting, lastSetting
			lastSetting = NaN
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

			tolerance = str2numSafe(factor)

			// in case we have tolerance as LABNOTEBOOK_NO_TOLERANCE we get tolerance == NaN
			// and the following check is false
			if(abs(currentSetting[i] - lastSetting[i]) < tolerance)
				continue
			endif

			if(i < NUM_HEADSTAGES)
				sprintf frontLabel, "HS#%d:" i
			else
				frontLabel = ""
			endif

			if (!cmpstr(factor, LABNOTEBOOK_NO_TOLERANCE))
				sprintf text, "%s%s: %s\r" frontLabel, key, SelectString(currentSetting[i], "Off", "On"); err = GetRTError(1)
			else
				sprintf text, "%s%s: %.2f %s\r" frontLabel, key, currentSetting[i], unit
			endif

			str += text
		endfor
	endfor

	if(!isEmpty(str))
		WAVE sweepWave = GetSweepWave(panelTitle, sweepNo)
		Note sweepWave, str
	endif
End

/// @brief Record changed labnotebook entries compared to the last sweep to the sweep wave note
///
/// Textual version.
///
/// Honours tolerances defined in the keywave and LABNOTEBOOK_BINARY_UNIT values
static Function ED_WriteChangedValuesToNoteText(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	string key, factor, text, frontLabel
	string str = ""
	variable tolerance, i, j, numRows, numCols

	// GetLastSetting will overwrite that on the first call
	variable firstCurrent  = LABNOTEBOOK_GET_RANGE
	variable lastCurrent   = LABNOTEBOOK_GET_RANGE
	variable firstPrevious = LABNOTEBOOK_GET_RANGE
	variable lastPrevious  = LABNOTEBOOK_GET_RANGE

	WAVE/T textualValues = GetLBTextualValues(panelTitle)
	WAVE/T textualKeys   = GetLBTextualKeys(panelTitle)

	// prefill the row cache for the labnotebook
	WAVE/Z junk = GetLastSetting(textualValues, sweepNo, "TimeStamp", UNKNOWN_MODE)
	WAVE/Z junk = GetLastSetting(textualValues, sweepNo - 1, "TimeStamp", UNKNOWN_MODE)

	numCols = DimSize(textualKeys, COLS)
	for (j = INITIAL_KEY_WAVE_COL_COUNT + 1; j < numCols; j += 1)
		key = textualKeys[0][j]

		if(!cmpstr(key, "MIES version") || !cmpstr(key, "Igor Pro version") || !cmpstr(key, "Igor Pro build") || !cmpstr(key, "Stim Wave Note"))
			continue
		endif

		Wave/Z/T currentSetting = GetLastSetting(textualValues, sweepNo, key, UNKNOWN_MODE)
		Wave/Z/T lastSetting    = GetLastSetting(textualValues, sweepNo - 1, key, UNKNOWN_MODE)

		// We have four combinations for the current and the last setting:
		// 1. valid -> valid
		// 2. valid -> invalid
		// 3. invalid -> invalid
		// 4. invalid -> valid

		// In case 2. and 3. we have nothing to do, everyting else needs a closer look
		// for 4. we create fake data set to NaN
		// and 1. needs no special treatment
		if(!WaveExists(currentSetting))
			continue
		elseif(!WaveExists(lastSetting))
			Duplicate/T/FREE currentSetting, lastSetting
			lastSetting = ""
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

			sprintf text, "%s%s: " frontLabel, key
			str += text + currentSetting[i] + "\r"
		endfor
	endfor

	if(!isEmpty(str))
		WAVE sweepWave = GetSweepWave(panelTitle, sweepNo)
		Note sweepWave, str
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

	if(IsNumericWave(values))
		EnsureLargeEnoughWave(values, minimumSize=rowIndex, dimension=ROWS, initialValue=NaN)
		if(numAdditions)
			values[][numKeyCols,][] = NaN
		endif
	else
		EnsureLargeEnoughWave(values, minimumSize=rowIndex, dimension=ROWS)
	endif

	return indizes
End

/// @brief Remember the "exact" start of the sweep
///
/// Should be called immediately after HW_StartAcq().
Function ED_MarkSweepStart(panelTitle)
	string panelTitle

	WAVE/T sweepSettingsTxtWave = GetSweepSettingsTextWave(panelTitle)

	sweepSettingsTxtWave[0][%$HIGH_PREC_SWEEP_START_KEY][INDEP_HEADSTAGE] = GetISO8601TimeStamp(numFracSecondsDigits = 3)
End

/// @brief Add sweep specific information to the labnotebook
Function ED_createWaveNoteTags(panelTitle, sweepCount)
	string panelTitle
	variable sweepCount

	variable i, j, refITI, ITI

	WAVE sweepSettingsWave = GetSweepSettingsWave(panelTitle)
	WAVE/T sweepSettingsKey = GetSweepSettingsKeyWave(panelTitle)
	ED_AddEntriesToLabnotebook(sweepSettingsWave, sweepSettingsKey, SweepCount, panelTitle, DATA_ACQUISITION_MODE)

	ITI = DAG_GetNumericalValue(panelTitle, "SetVar_DataAcq_ITI")
	refITI = GetSweepSettingsWave(panelTitle)[0][%$"Inter-trial interval"][INDEP_HEADSTAGE]
	if(!CheckIfClose(ITI, refITI, tol = 1e-3))
		Make/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) vals = NaN
		vals[0][0][INDEP_HEADSTAGE] = ITI

		Make/T/FREE/N=(3, 1) keys
		WAVE/T sweepSettingsKeyWave = GetSweepSettingsKeyWave(panelTitle)
		keys[0] = sweepSettingsKeyWave[0][%$"Inter-trial interval"]
		keys[1] = sweepSettingsKeyWave[1][%$"Inter-trial interval"]
		keys[2] = sweepSettingsKeyWave[2][%$"Inter-trial interval"]
		ED_AddEntriesToLabnotebook(vals, keys, sweepCount, panelTitle, DATA_ACQUISITION_MODE)
	endif

	WAVE/T sweepSettingsTxtWave = GetSweepSettingsTextWave(panelTitle)
	WAVE/T sweepSettingsTxtKey = GetSweepSettingsTextKeyWave(panelTitle)
	ED_AddEntriesToLabnotebook(sweepSettingsTxtWave, sweepSettingsTxtKey, SweepCount, panelTitle, DATA_ACQUISITION_MODE)

	if(DAG_GetNumericalValue(panelTitle, "check_Settings_SaveAmpSettings"))
		AI_FillAndSendAmpliferSettings(panelTitle, sweepCount)
		// function for debugging
		// AI_createDummySettingsWave(panelTitle, SweepNo)
	endif

	ED_createAsyncWaveNoteTags(panelTitle, sweepCount)

	// TP settings, especially useful if "global TP insertion" is active
	ED_TPSettingsDocumentation(panelTitle, sweepCount, DATA_ACQUISITION_MODE)

	ED_WriteChangedValuesToNote(panelTitle, sweepCount)
	ED_WriteChangedValuesToNoteText(panelTitle, sweepCount)
End

/// @brief Write the user comment from the DA_Ephys panel to the labnotebook
Function ED_WriteUserCommentToLabNB(panelTitle, comment, sweepNo)
	string panelTitle
	string comment
	variable sweepNo

	Make/FREE/N=(3, 1)/T keys

	keys[0][0] =  "User comment"
	keys[1][0] =  ""
	keys[2][0] =  LABNOTEBOOK_NO_TOLERANCE

	Make/FREE/T/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values
	values[][][INDEP_HEADSTAGE] = comment

	ED_AddEntriesToLabnotebook(values, keys, sweepNo, panelTitle, UNKNOWN_MODE)
End

/// @brief This function is used to create wave notes for the informations found in the Asynchronous tab in the DA_Ephys panel
static Function ED_createAsyncWaveNoteTags(panelTitle, sweepCount)
	string panelTitle
	Variable sweepCount

	string title, unit, str, ctrl
	variable minSettingValue, maxSettingValue, i, scaledValue
	variable redoLastSweep

	WAVE statusAsync = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_ASYNC)

	if(IsConstant(statusAsync, 0))
		return NaN
	endif

	for(i = 0; i < NUM_ASYNC_CHANNELS ; i += 1)

		if(!statusAsync[i])
			continue
		endif

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_TITLE)
		title = DAG_GetTextualValue(panelTitle, ctrl, index = i)

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_UNIT)
		unit = DAG_GetTextualValue(panelTitle, ctrl, index = i)

		WAVE asyncSettingsWave = GetAsyncSettingsWave()
		WAVE/T asyncSettingsKey = GetAsyncSettingsKeyWave(asyncSettingsWave, i, title, unit)

		WAVE/T asyncSettingsTxtWave = GetAsyncSettingsTextWave()
		WAVE/T asyncSettingsTxtKey = GetAsyncSettingsTextKeyWave(asyncSettingsTxtWave, i)

		asyncSettingsWave[0][%ADOnOff][INDEP_HEADSTAGE] = CHECKBOX_SELECTED

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN)
		asyncSettingsWave[0][%ADGain][INDEP_HEADSTAGE] = DAG_GetNumericalValue(panelTitle, ctrl, index = i)

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ALARM, CHANNEL_CONTROL_CHECK)
		asyncSettingsWave[0][%AlarmOnOff][INDEP_HEADSTAGE] = DAG_GetNumericalValue(panelTitle, ctrl, index = i)

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN)
		minSettingValue = DAG_GetNumericalValue(panelTitle, ctrl, index = i)
		asyncSettingsWave[0][%AlarmMin] = minSettingValue

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX)
		maxSettingValue = DAG_GetNumericalValue(panelTitle, ctrl, index = i)
		asyncSettingsWave[0][%AlarmMax] = maxSettingValue

		// Take the Min and Max values and use them for setting the tolerance value in the measurement key wave
		asyncSettingsKey[%Tolerance][%MeasuredValue] = num2str(abs((maxSettingValue - minSettingValue)/2))

		asyncSettingsTxtWave[0][%Title][INDEP_HEADSTAGE] = title

		asyncSettingsTxtWave[0][%Unit][INDEP_HEADSTAGE] = unit

		scaledValue = ASD_ReadChannel(panelTitle, i)

		// put the measurement value into the async settings wave for creation of wave notes
		asyncSettingsWave[0][%MeasuredValue][INDEP_HEADSTAGE] = scaledValue

		if(ASD_CheckAsynAlarmState(panelTitle, i, scaledValue))
			beep
			print time() + " !!!!!!!!!!!!! " + title + " has exceeded max/min settings" + " !!!!!!!!!!!!!"
			ControlWindowToFront()
			beep
			redoLastSweep = 1
		endif

		ED_AddEntriesToLabnotebook(asyncSettingsTxtWave, asyncSettingsTxtKey, sweepCount, panelTitle, DATA_ACQUISITION_MODE)
		ED_AddEntriesToLabnotebook(asyncSettingsWave, asyncSettingsKey, sweepCount, panelTitle, DATA_ACQUISITION_MODE)
	endfor

	if(redoLastSweep && DAG_GetNumericalValue(panelTitle, "Check_Settings_AlarmAutoRepeat"))
		RA_SkipSweeps(panelTitle, -1)
	endif
End

/// @brief Stores test pulse related data in the labnotebook
Function ED_TPDocumentation(panelTitle)
	string panelTitle

	variable sweepNo, RTolerance
	variable i, j
	WAVE hsProp = GetHSProperties(panelTitle)

	WAVE BaselineSSAvg = GetBaselineAverage(panelTitle)
	WAVE InstResistance = GetInstResistanceWave(panelTitle)
	WAVE SSResistance = GetSSResistanceWave(panelTitle)

	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

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
	TPKeyWave[1][8]  = LABNOTEBOOK_BINARY_UNIT
	TPKeyWave[1][9]  = ""
	TPKeyWave[1][10] = ""
	TPKeyWave[1][11] = ""

	RTolerance = DAG_GetNumericalValue(panelTitle, "setvar_Settings_TP_RTolerance")
	TPKeyWave[2][0]  = "1" // Assume a tolerance of 1 mV for V rest
	TPKeyWave[2][1]  = "50" // Assume a tolerance of 50pA for I rest
	TPKeyWave[2][2]  = num2str(RTolerance) // applies the same R tolerance for the instantaneous and steady state resistance
	TPKeyWave[2][3]  = num2str(RTolerance)
	TPKeyWave[2][4]  = "1e-12"
	TPKeyWave[2][5]  = "1e-12"
	TPKeyWave[2][6]  = "1e-6"
	TPKeyWave[2][7]  = "1e-6"
	TPKeyWave[2][8]  = LABNOTEBOOK_NO_TOLERANCE
	TPKeyWave[2][9]  = "0.0001"
	TPKeyWave[2][10] = "0.0001"
	TPKeyWave[2][11] = LABNOTEBOOK_NO_TOLERANCE

	TPSettingsWave[0][2][0, NUM_HEADSTAGES - 1]  = InstResistance[r]
	TPSettingsWave[0][3][0, NUM_HEADSTAGES - 1]  = SSResistance[r]

	TPSettingsWave[0][8][0, NUM_HEADSTAGES - 1] = statusHS[r]

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		if(hsProp[i][%ClampMode] != V_CLAMP_MODE)
			continue
		endif

		if(AI_SelectMultiClamp(panelTitle, i) != AMPLIFIER_CONNECTION_SUCCESS)
			continue
		endif

		TPSettingsWave[0][4][i] = AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_GETFASTCOMPCAP_FUNC, NaN, selectAmp = 0)
		TPSettingsWave[0][5][i] = AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_GETSLOWCOMPCAP_FUNC, NaN, selectAmp = 0)
		TPSettingsWave[0][6][i] = AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_GETFASTCOMPTAU_FUNC, NaN, selectAmp = 0)
		TPSettingsWave[0][7][i] = AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_GETSLOWCOMPTAU_FUNC, NaN, selectAmp = 0)
	endfor

	TPSettingsWave[0][1][0, NUM_HEADSTAGES - 1] = hsProp[r][%ClampMode] == V_CLAMP_MODE ? BaselineSSAvg[r] : NaN
	TPSettingsWave[0][0][0, NUM_HEADSTAGES - 1] = hsProp[r][%ClampMode] == I_CLAMP_MODE ? BaselineSSAvg[r] : NaN

	TPSettingsWave[0][9][0, NUM_HEADSTAGES - 1]  = hsProp[r][%DAC]
	TPSettingsWave[0][10][0, NUM_HEADSTAGES - 1] = hsProp[r][%ADC]
	TPSettingsWave[0][11][0, NUM_HEADSTAGES - 1] = hsProp[r][%ClampMode]

	sweepNo = AFH_GetLastSweepAcquired(panelTitle)
	ED_AddEntriesToLabnotebook(TPSettingsWave, TPKeyWave, sweepNo, panelTitle, TEST_PULSE_MODE)

	ED_TPSettingsDocumentation(panelTitle, sweepNo, TEST_PULSE_MODE)
End

/// @brief Document the settings of the Testpulse
///
/// The source type entry is not fixed. We want to document the testpulse
/// settings during ITI and the testpulse settings for plaint test pulses.
///
/// @param panelTitle      device
/// @param sweepNo         sweep number
/// @param entrySourceType type of reporting subsystem, one of @ref DataAcqModes
static Function ED_TPSettingsDocumentation(panelTitle, sweepNo, entrySourceType)
	string panelTitle
	variable sweepNo, entrySourceType

	NVAR pulseDuration = $GetTPPulseDuration(panelTitle)
	NVAR AmplitudeVC = $GetTPAmplitudeVC(panelTitle)
	NVAR AmplitudeIC = $GetTPAmplitudeIC(panelTitle)
	NVAR baselineFrac = $GetTestpulseBaselineFraction(panelTitle)

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

	ED_AddEntriesToLabnotebook(TPSettingsWave, TPKeyWave, sweepNo, panelTitle, entrySourceType)
End
