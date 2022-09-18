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
Function ED_AddEntriesToLabnotebook(WAVE vals, WAVE/T keys, variable sweepNo, string device, variable entrySourceType)
	ED_CheckValuesAndKeys(vals, keys)

	if(IsTextWave(vals))
		ED_createTextNotes(vals, keys, sweepNo, entrySourceType, LBT_LABNOTEBOOK, device = device)
	else
		ED_createWaveNotes(vals, keys, sweepNo, entrySourceType, LBT_LABNOTEBOOK, device = device)
	endif
End

/// @brief Add numerical/textual entries to results
Function ED_AddEntriesToResults(WAVE vals, WAVE/T keys, variable entrySourceType)
	ED_CheckValuesAndKeys(vals, keys)

	if(IsTextWave(vals))
		ED_createTextNotes(vals, keys, NaN, entrySourceType, LBT_RESULTS)
	else
		ED_createWaveNotes(vals, keys, NaN, entrySourceType, LBT_RESULTS)
	endif
End

static Function ED_CheckValuesAndKeys(WAVE vals, WAVE keys)
	ASSERT(DimSize(vals, ROWS)   == 1, "Mismatched row count")
	ASSERT(DimSize(vals, COLS)   == DimSize(keys, COLS), "Mismatched column count")
	ASSERT(DimSize(vals, LAYERS) <= LABNOTEBOOK_LAYER_COUNT, "Mismatched layer count")

	ASSERT(DimSize(keys, ROWS)   == 1 || DimSize(keys, ROWS) == 3 || DimSize(keys, ROWS) == 6, "Mismatched row count")
	ASSERT(DimSize(keys, LAYERS) <= 1, "Mismatched layer count")
End

/// @brief Add textual entries to the logbook
///
/// The text documentation wave will use layers to report the different headstages.
///
/// The incoming value wave can have zero to nine (#NUM_HEADSTAGES + 1) layers. The
/// first eight layers are for headstage dependent data, the last layer for
/// headstage independent data.
///
/// @param incomingTextualValues incoming Text Documentation Wave sent by the each reporting subsystem
/// @param incomingTextualKeys   incoming Text Documentation key wave that is used to reference the incoming settings wave
/// @param sweepNo               sweep number
/// @param device                [optional for logbookType LBT_RESULTS only] device
/// @param entrySourceType       type of reporting subsystem, one of @ref DataAcqModes
/// @param logbookType           type of the logbook, one of @ref LogbookTypes
static Function ED_createTextNotes(WAVE/T incomingTextualValues, WAVE/T incomingTextualKeys, variable sweepNo, variable entrySourceType, variable logbookType, [string device])
	variable rowIndex, numCols, i, lastValidIncomingLayer, state
	string timestamp

	if(ParamIsDefault(device))
		ASSERT(logbookType == LBT_RESULTS, "Invalid logbook type")
		state = AS_INACTIVE

		WAVE/T values = GetLogbookWaves(logbookType, LBN_TEXTUAL_VALUES)
		WAVE/T keys = GetLogbookWaves(logbookType, LBN_TEXTUAL_KEYS)
	else
		WAVE/T values = GetLogbookWaves(logbookType, LBN_TEXTUAL_VALUES, device = device)
		WAVE/T keys = GetLogbookWaves(logbookType, LBN_TEXTUAL_KEYS, device = device)

		state = ROVar(GetAcquisitionState(device))
	endif

	[WAVE indizes, rowIndex] = ED_FindIndizesAndRedimension(incomingTextualKeys, incomingTextualValues, keys, values, logbookType)
	ASSERT(WaveExists(indizes), "Missing indizes")

	values[rowIndex][0][] = num2istr(sweepNo)
	values[rowIndex][3][] = num2istr(entrySourceType)

	values[rowIndex][4][] = num2istr(state)

	// store the current time in a variable first
	// so that all layers have the same timestamp
	timestamp = num2strHighPrec(DateTime, precision = 3)
	values[rowIndex][1][] = timestamp
	timestamp = num2strHighPrec(DateTimeInUTC(), precision = 3)
	values[rowIndex][2][] = timestamp

	WAVE valuesDat = ExtractLogbookSliceTimeStamp(values)
	EnsureLargeEnoughWave(valuesDat, minimumSize=rowIndex, dimension=ROWS)
	valuesDat[rowIndex] = str2num(values[rowIndex][1])

	WAVE valuesSweep = ExtractLogbookSliceSweep(values)
	EnsureLargeEnoughWave(valuesSweep, minimumSize=rowIndex, dimension=ROWS)
	valuesSweep[rowIndex] = str2num(values[rowIndex][0])

	WAVE valuesNull = ExtractLogbookSliceEmpty(values)
	EnsureLargeEnoughWave(valuesNull, minimumSize=rowIndex, dimension=ROWS)
	// nothing to do

	numCols = DimSize(incomingTextualValues, COLS)
	lastValidIncomingLayer = DimSize(incomingTextualValues, LAYERS) == 0 ? 0 : DimSize(incomingTextualValues, LAYERS) - 1
	for(i = 0; i < numCols; i += 1)
		values[rowIndex][indizes[i]][0, lastValidIncomingLayer] = NormalizeToEOL(incomingTextualValues[0][i][r], "\n")
	endfor

	SetNumberInWaveNote(values, NOTE_INDEX, rowIndex + 1)
End

static Function ED_ParseHeadstageContigencyMode(string str)

	if(!cmpstr(str, "ALL"))
		return (HCM_DEPEND | HCM_INDEP)
	elseif(strsearch(str, "DEPEND", 0) >= 0)
		return HCM_DEPEND
	elseif(strsearch(str, "INDEP", 0) >= 0)
		return HCM_INDEP
	endif

	return HCM_EMPTY
End

static Function/S ED_HeadstageContigencyModeToString(variable mode)

	switch(mode)
		case HCM_INDEP:
			return "INDEP"
		case HCM_DEPEND:
			return "DEPEND"
		case 0x03: // HCM_INDEP | HCM_DEPEND
			return "ALL"
		case HCM_EMPTY:
			return ""
		default:
			ASSERT(0, "Invalid mode")
	endswitch
End

/// @brief Return the headstage contigency mode for values
static Function ED_GetHeadstageContingency(WAVE values)

	if(IsTextWave(values))
		WAVE/T valuesText = values
		WAVE stats = LBN_GetNumericWave()
		stats[] = strlen(valuesText[p]) == 0 ? NaN : 1
	else
		Wave stats = values
	endif

	WaveStats/Q/M=1 stats

	if(V_numNaNs == LABNOTEBOOK_LAYER_COUNT)
		return HCM_EMPTY
	elseif(!IsNaN(stats[INDEP_HEADSTAGE]) && V_numNaNs == NUM_HEADSTAGES)
		return HCM_INDEP
	elseif(IsNaN(stats[INDEP_HEADSTAGE]))
		return HCM_DEPEND
	endif

	return (HCM_DEPEND | HCM_INDEP)
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
/// @param device                  [optional for logbooktype LBT_RESULTS only] device
/// @param entrySourceType         type of reporting subsystem, one of @ref DataAcqModes
/// @param logbookType             one of @ref LogbookTypes
static Function ED_createWaveNotes(WAVE incomingNumericalValues, WAVE/T incomingNumericalKeys, variable sweepNo, variable entrySourceType, variable logbookType, [string device])
	variable rowIndex, numCols, lastValidIncomingLayer, i, timestamp, state

	if(ParamIsDefault(device))
		ASSERT(logbookType == LBT_RESULTS, "Invalid logbook type")

		WAVE values = GetLogbookWaves(logbookType, LBN_NUMERICAL_VALUES)
		WAVE/T keys = GetLogbookWaves(logbookType, LBN_NUMERICAL_KEYS)

		state = AS_INACTIVE
	else
		WAVE values = GetLogbookWaves(logbookType, LBN_NUMERICAL_VALUES, device = device)
		WAVE/T keys = GetLogbookWaves(logbookType, LBN_NUMERICAL_KEYS, device = device)

		state = ROVar(GetAcquisitionState(device))
	endif

	[WAVE indizes, rowIndex] = ED_FindIndizesAndRedimension(incomingNumericalKeys, incomingNumericalValues, keys, values, logbookType)
	ASSERT(WaveExists(indizes), "Missing indizes")

	values[rowIndex][0][] = sweepNo
	values[rowIndex][3][] = entrySourceType

	values[rowIndex][4][] = state

	// store the current time in a variable first
	// so that all layers have the same timestamp
	timestamp = DateTime
	values[rowIndex][1][] = timestamp
	timestamp = DateTimeInUTC()
	values[rowIndex][2][] = timestamp

	WAVE valuesDat = ExtractLogbookSliceTimeStamp(values)
	EnsureLargeEnoughWave(valuesDat, minimumSize=rowIndex, dimension=ROWS, initialValue=NaN)
	valuesDat[rowIndex] = values[rowIndex][1]

	numCols = DimSize(incomingNumericalValues, COLS)
	lastValidIncomingLayer = DimSize(incomingNumericalValues, LAYERS) == 0 ? 0 : DimSize(incomingNumericalValues, LAYERS) - 1
	for(i = 0; i < numCols; i += 1)
		values[rowIndex][indizes[i]][0, lastValidIncomingLayer] = incomingNumericalValues[0][i][r]
	endfor

	SetNumberInWaveNote(values, NOTE_INDEX, rowIndex + 1)
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
/// 	WAVE values = LBN_GetNumericWave()
/// 	values[0] = 4711 // setting of the first headstage
/// 	ED_AddEntryToLabnotebook(device, "SomeSetting", values)
/// \endrst
///
/// The later on the labnotebook can be queried with:
/// \rst
/// .. code-block:: igorpro
///
///		WAVE/Z settings = GetLastSetting(values, NaN, LABNOTEBOOK_USER_PREFIX + key, UNKNOWN_MODE)
/// \endrst
///
/// @param device      device
/// @param key             name under which to store the entry.
/// @param values          entry to add, wave can be numeric (floating point) or text, must have
///                        #LABNOTEBOOK_LAYER_COUNT rows. It can be all NaN or empty (text), this is useful
///                        if you want to make the key known without adding an entry. Use LBN_GetNumericWave()
///                        or LBN_GetTextWave() to create them.
/// @param unit            [optional, defaults to ""] physical unit of the entry
/// @param tolerance       [optional, defaults to #LABNOTEBOOK_NO_TOLERANCE] tolerance of the entry, used for
///                        judging if a change is "relevant" and should then be written to the sweep wave
/// @param overrideSweepNo [optional, defaults to last acquired sweep] Adds metadata to the
///                        given sweep number. Mostly useful for adding
///                        labnotebook entries during #MID_SWEEP_EVENT for
///                        analysis functions.
Function ED_AddEntryToLabnotebook(device, key, values, [unit, tolerance, overrideSweepNo])
	string device, key
	WAVE values
	string unit
	variable tolerance, overrideSweepNo

	string toleranceStr
	variable sweepNo, headstageCont

	ASSERT(!IsEmpty(key), "Empty key")
	ASSERT(DimSize(values, ROWS) == LABNOTEBOOK_LAYER_COUNT, "wv has the wrong number of rows")
	ASSERT(DimSize(values, COLS) == 0, "wv must be 1D")
	ASSERT(IsTextWave(values) || IsFloatingPointWave(values), "Wave must be text or floating point")
	ASSERT(strsearch(key, LABNOTEBOOK_USER_PREFIX, 0, 2) != 0, "Don't prefix key with LABNOTEBOOK_USER_PREFIX")

	headstageCont = ED_GetHeadstageContingency(values)
	ASSERT(headstageCont != (HCM_INDEP | HCM_DEPEND), "The independent headstage entry can not be combined with headstage dependent entries.")
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
		sweepNo = AFH_GetLastSweepAcquired(device)
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

	ED_AddEntriesToLabnotebook(valuesReshaped, keys, sweepNo, device, UNKNOWN_MODE)
End

/// @brief Record changed labnotebook entries compared to the last sweep to the sweep wave note
///
/// Honours tolerances defined in the keywave and LABNOTEBOOK_BINARY_UNIT values
static Function ED_WriteChangedValuesToNote(device, sweepNo)
	string device
	variable sweepNo

	string key, factor, unit, text, frontLabel
	string str = ""
	variable tolerance, i, j, numRows, numCols, err

	WAVE/T numericalKeys = GetLBNumericalKeys(device)
	WAVE numericalValues = GetLBNumericalValues(device)

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
				sprintf text, "%s%s: %s\r" frontLabel, key, SelectString(currentSetting[i], "Off", "On")
			else
				sprintf text, "%s%s: %.2f %s\r" frontLabel, key, currentSetting[i], unit
			endif

			str += text
		endfor
	endfor

	if(!isEmpty(str))
		WAVE sweepWave = GetSweepWave(device, sweepNo)
		Note sweepWave, str
	endif
End

/// @brief Record changed labnotebook entries compared to the last sweep to the sweep wave note
///
/// Textual version.
///
/// Honours tolerances defined in the keywave and LABNOTEBOOK_BINARY_UNIT values
static Function ED_WriteChangedValuesToNoteText(device, sweepNo)
	string device
	variable sweepNo

	string key, factor, text, frontLabel
	string str = ""
	variable tolerance, i, j, numRows, numCols

	WAVE/T textualValues = GetLBTextualValues(device)
	WAVE/T textualKeys   = GetLBTextualKeys(device)

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
		WAVE sweepWave = GetSweepWave(device, sweepNo)
		Note sweepWave, str
	endif
End

/// @brief Returns the column indizes of each parameter in incomingKey into the `key` wave
///
/// Redimensions `key` and `values` waves.
/// Prefills `key` with `incomingKey` data if necessary.
///
/// Ensures that key and values have a matching column size at return.
///
/// @param incomingKey    text wave with the keys to add
/// @param incomingValues wave with the values to add
/// @param key            key wave of the labnotebook (Rows: 1/3/6, Columns: Same as values, Layers: 1)
/// @param values         values/data wave of the labnotebook
/// @param logbookType    type of the logbook, one of @ref LogbookTypes
///
/// @retval colIndizes column indizes of the entries from incomingKey
/// @retval rowIndex   returns the row index into values at which the new values should be written
static Function [WAVE colIndizes, variable rowIndex] ED_FindIndizesAndRedimension(WAVE/T incomingKey, WAVE incomingValues, WAVE/T key, WAVE values, variable logbookType)
	variable numCols, numKeyRows, numKeyCols, i, j, numAdditions, idx
	variable lastValidIncomingKeyRow, descIndex, isUserEntry, headstageCont, headstageContDesc, isUnAssoc
	string msg, searchStr

	numKeyRows = DimSize(key, ROWS)
	numKeyCols = DimSize(key, COLS)
	lastValidIncomingKeyRow = DimSize(incomingKey, ROWS) - 1

	Make/FREE/D/N=(DimSize(incomingKey, COLS)) indizes = NaN

	WAVE/T/ZZ desc

	numCols = DimSize(incomingKey, COLS)
	for(i = 0; i < numCols; i += 1)
		searchStr = incomingKey[0][i]

		FindValue/TXOP=4/TEXT=(searchStr)/RMD=[0][] key

		if(V_col >= 0)
			indizes[i] = V_col
			continue
		endif

		ASSERT(IsValidLiberalObjectName(searchStr), "Incoming key is not a valid liberal object name: " + searchStr)

		// need to add new entry
		idx = numKeyCols + numAdditions
		EnsureLargeEnoughWave(key, minimumSize=idx, dimension=COLS)
		key[0, lastValidIncomingKeyRow][idx] = incomingKey[p][i]
		indizes[i] = idx
		numAdditions += 1

		isUserEntry = (strsearch(searchStr, LABNOTEBOOK_USER_PREFIX, 0) == 0)

		if(isUserEntry)
			continue
		endif

		if(logbookType == LBT_LABNOTEBOOK)
			if(!WaveExists(desc) && IsNumericWave(values))
				WAVE/T desc = GetLBNumericalDescription()
			else
				// @todo not yet done for text waves
			endif
		endif

		// check description wave if available
		if(!WaveExists(desc))
			continue
		endif

		descIndex = FindDimLabel(desc, COLS, searchStr)

		isUnAssoc = 0

		if(descIndex < 0)
			// retry with removing unassociated suffix
			searchStr = RemoveUNassocLBNKeySuffix(searchStr)
			descIndex = FindDimLabel(desc, COLS, searchStr)

			if(descIndex >= 0)
				isUnAssoc = 1
			endif
		endif

		if(descIndex < 0)
			// retry as that might be a dynamic Async key, see the fifth column in
			// GetAsyncSettingsKeyWave()

			if(GrepString(searchStr, "^Async AD ?[[:digit:]] \[.+\]$"))
				// continue as the entry is fully dynamic and we can't check anything
				continue
			endif
		endif

		if(descIndex < 0)
			sprintf msg, "Could not find a description for entry: %s", searchStr
			BUG(msg)
			continue
		endif

		// check that metadata is consistent
		for(j = 1; j <= lastValidIncomingKeyRow; j +=  1)
			if(!cmpstr(desc[j][descIndex], incomingKey[j][i]))
				continue
			endif

			// some LBN entries have a runtime tolerance, ignore those
			if(!cmpstr(GetDimLabel(desc, ROWS, j), "Tolerance") && !cmpstr(desc[j][descIndex], "runtime"))
				continue
			endif

			sprintf msg, "The metadata in row \"%s\" differs for entry \"%s\": stock: \"%s\", incoming: \"%s\"", GetDimLabel(desc, ROWS, j), searchStr, desc[j][descIndex], incomingKey[j][i]
			BUG(msg)
		endfor

		// check for correct headstage contingency
		Duplicate/FREE/RMD=[0][i][*] incomingValues, valuesSlice
		headstageCont = ED_GetHeadstageContingency(valuesSlice)
		headstageContDesc = ED_ParseHeadstageContigencyMode(desc[%HeadstageContingency][descIndex])

		if(isUnAssoc)
			headstageContDesc = HCM_INDEP
		endif

		if(headstageCont != HCM_EMPTY && !(headstageCont & headstageContDesc))
			sprintf msg, "Headstage contingency for entry \"%s\": stock: \"%s\", incoming: \"%s\"", searchStr, desc[%HeadstageContingency][descIndex], ED_HeadstageContigencyModeToString(headstageCont)
			BUG(msg)
		endif

		// copy additional entries from desc into key
		// in case the incoming key wave provided all entries
		// there is nothing left to do
		if(DimSize(incomingKey, ROWS) != DimSize(desc, ROWS))
			key[lastValidIncomingKeyRow + 1, inf][idx] = desc[p][descIndex]
		endif
	endfor

	rowIndex = GetNumberFromWaveNote(values, NOTE_INDEX)
	if(!IsFinite(rowIndex))
		// old waves don't have that info
		// use the last row
		rowIndex = DimSize(values, ROWS)
	endif

	// for further performance enhancement we must add "support for enhancing multiple dimensions at once"
	// to EnsureLargeEnoughWave
	if(numAdditions)
		Redimension/N=(-1, numKeyCols + numAdditions, -1) key, values

		// rowIndex will be zero for empty waves only and these also need dimension labels for all columns
		LBN_SetDimensionLabels(key, values, start = (rowIndex == 0 ? 0 : numKeyCols))
	endif

	if(IsNumericWave(values))
		EnsureLargeEnoughWave(values, minimumSize=rowIndex, dimension=ROWS, initialValue=NaN)
		if(numAdditions)
			values[][numKeyCols,][] = NaN
		endif
	else
		EnsureLargeEnoughWave(values, minimumSize=rowIndex, dimension=ROWS)
	endif

	return [indizes, rowIndex]
End

/// @brief Remember the "exact" start of the sweep
///
/// Should be called immediately after HW_StartAcq().
Function ED_MarkSweepStart(device)
	string device

	WAVE/T sweepSettingsTxtWave = GetSweepSettingsTextWave(device)

	sweepSettingsTxtWave[0][%$HIGH_PREC_SWEEP_START_KEY][INDEP_HEADSTAGE] = GetISO8601TimeStamp(numFracSecondsDigits = 3)
End

/// @brief Add sweep specific information to the labnotebook
Function ED_createWaveNoteTags(device, sweepCount)
	string device
	variable sweepCount

	variable i, j, refITI, ITI

	WAVE sweepSettingsWave = GetSweepSettingsWave(device)
	WAVE/T sweepSettingsKey = GetSweepSettingsKeyWave(device)
	ED_AddEntriesToLabnotebook(sweepSettingsWave, sweepSettingsKey, SweepCount, device, DATA_ACQUISITION_MODE)

	ITI = DAG_GetNumericalValue(device, "SetVar_DataAcq_ITI")
	refITI = GetSweepSettingsWave(device)[0][%$"Inter-trial interval"][INDEP_HEADSTAGE]
	if(!CheckIfClose(ITI, refITI, tol = 1e-3))
		Make/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) vals = NaN
		vals[0][0][INDEP_HEADSTAGE] = ITI

		Make/T/FREE/N=(3, 1) keys
		WAVE/T sweepSettingsKeyWave = GetSweepSettingsKeyWave(device)
		keys[0] = sweepSettingsKeyWave[0][%$"Inter-trial interval"]
		keys[1] = sweepSettingsKeyWave[1][%$"Inter-trial interval"]
		keys[2] = sweepSettingsKeyWave[2][%$"Inter-trial interval"]
		ED_AddEntriesToLabnotebook(vals, keys, sweepCount, device, DATA_ACQUISITION_MODE)
	endif

	WAVE/T sweepSettingsTxtWave = GetSweepSettingsTextWave(device)
	WAVE/T sweepSettingsTxtKey = GetSweepSettingsTextKeyWave(device)
	ED_AddEntriesToLabnotebook(sweepSettingsTxtWave, sweepSettingsTxtKey, SweepCount, device, DATA_ACQUISITION_MODE)

	if(DAG_GetNumericalValue(device, "check_Settings_SaveAmpSettings"))
		AI_FillAndSendAmpliferSettings(device, sweepCount)
		// function for debugging
		// AI_createDummySettingsWave(device, SweepNo)
	endif

	ED_createAsyncWaveNoteTags(device, sweepCount)

	// TP settings, especially useful if "global TP insertion" is active
	ED_TPSettingsDocumentation(device, sweepCount, DATA_ACQUISITION_MODE)

	ED_WriteChangedValuesToNote(device, sweepCount)
	ED_WriteChangedValuesToNoteText(device, sweepCount)
End

/// @brief Write the user comment from the DA_Ephys panel to the labnotebook
Function ED_WriteUserCommentToLabNB(device, comment, sweepNo)
	string device
	string comment
	variable sweepNo

	Make/FREE/N=(3, 1)/T keys

	keys[0][0] =  "User comment"
	keys[1][0] =  ""
	keys[2][0] =  LABNOTEBOOK_NO_TOLERANCE

	Make/FREE/T/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values
	values[][][INDEP_HEADSTAGE] = comment

	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, UNKNOWN_MODE)
End

/// @brief This function is used to create wave notes for the informations found in the Asynchronous tab in the DA_Ephys panel
static Function ED_createAsyncWaveNoteTags(device, sweepCount)
	string device
	Variable sweepCount

	string title, unit, str, ctrl
	variable minSettingValue, maxSettingValue, i, scaledValue
	variable redoLastSweep, alarmState, alarmEnabled

	WAVE statusAsync = DAG_GetChannelState(device, CHANNEL_TYPE_ASYNC)

	if(IsConstant(statusAsync, 0))
		return NaN
	endif

	for(i = 0; i < NUM_ASYNC_CHANNELS ; i += 1)

		if(!statusAsync[i])
			continue
		endif

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_TITLE)
		title = DAG_GetTextualValue(device, ctrl, index = i)

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_UNIT)
		unit = DAG_GetTextualValue(device, ctrl, index = i)

		WAVE asyncSettingsWave = GetAsyncSettingsWave()
		WAVE/T asyncSettingsKey = GetAsyncSettingsKeyWave(asyncSettingsWave, i, title, unit)

		WAVE/T asyncSettingsTxtWave = GetAsyncSettingsTextWave()
		WAVE/T asyncSettingsTxtKey = GetAsyncSettingsTextKeyWave(asyncSettingsTxtWave, i)

		asyncSettingsWave[0][%ADOnOff][INDEP_HEADSTAGE] = CHECKBOX_SELECTED

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN)
		asyncSettingsWave[0][%ADGain][INDEP_HEADSTAGE] = DAG_GetNumericalValue(device, ctrl, index = i)

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ALARM, CHANNEL_CONTROL_CHECK)
		alarmEnabled = DAG_GetNumericalValue(device, ctrl, index = i)
		asyncSettingsWave[0][%AlarmOnOff][INDEP_HEADSTAGE] = alarmEnabled

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN)
		minSettingValue = DAG_GetNumericalValue(device, ctrl, index = i)
		asyncSettingsWave[0][%AlarmMin] = minSettingValue

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX)
		maxSettingValue = DAG_GetNumericalValue(device, ctrl, index = i)
		asyncSettingsWave[0][%AlarmMax] = maxSettingValue

		// Take the Min and Max values and use them for setting the tolerance value in the measurement key wave
		asyncSettingsKey[%Tolerance][%MeasuredValue] = num2str(abs((maxSettingValue - minSettingValue)/2))

		asyncSettingsTxtWave[0][%Title][INDEP_HEADSTAGE] = title

		asyncSettingsTxtWave[0][%Unit][INDEP_HEADSTAGE] = unit

		scaledValue = ASD_ReadChannel(device, i)

		// put the measurement value into the async settings wave for creation of wave notes
		asyncSettingsWave[0][%MeasuredValue][INDEP_HEADSTAGE] = scaledValue

		alarmState = alarmEnabled ? ASD_CheckAsynAlarmState(device, scaledValue, minSettingValue, maxSettingValue) : NaN
		asyncSettingsWave[0][%AlarmState][INDEP_HEADSTAGE] = alarmState

		if(alarmEnabled && alarmState)
			beep
			print time() + " !!!!!!!!!!!!! " + title + " has exceeded max/min settings" + " !!!!!!!!!!!!!"
			ControlWindowToFront()
			beep
			redoLastSweep = 1
		endif

		ED_AddEntriesToLabnotebook(asyncSettingsTxtWave, asyncSettingsTxtKey, sweepCount, device, DATA_ACQUISITION_MODE)
		ED_AddEntriesToLabnotebook(asyncSettingsWave, asyncSettingsKey, sweepCount, device, DATA_ACQUISITION_MODE)
	endfor

	if(redoLastSweep && DAG_GetNumericalValue(device, "Check_Settings_AlarmAutoRepeat"))
		RA_SkipSweeps(device, -1, SWEEP_SKIP_AUTO)
	endif
End

/// @brief Stores test pulse related data in the labnotebook
Function ED_TPDocumentation(device)
	string device

	variable sweepNo, RTolerance
	variable i, j

	WAVE hsProp = GetHSProperties(device)
	WAVE TPSettings = GetTPsettings(device)
	WAVE TPResults = GetTPResults(device)
	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

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
	TPKeyWave[0][11] = CLAMPMODE_ENTRY_KEY

	TPKeyWave[1][0]  = "mV"
	TPKeyWave[1][1]  = "pA"
	TPKeyWave[1][2]  = "MΩ"
	TPKeyWave[1][3]  = "MΩ"
	TPKeyWave[1][4]  = "F"
	TPKeyWave[1][5]  = "F"
	TPKeyWave[1][6]  = "s"
	TPKeyWave[1][7]  = "s"
	TPKeyWave[1][8]  = LABNOTEBOOK_BINARY_UNIT
	TPKeyWave[1][9]  = ""
	TPKeyWave[1][10] = ""
	TPKeyWave[1][11] = ""

	RTolerance = TPSettings[%resistanceTol][INDEP_HEADSTAGE]
	TPKeyWave[2][0]  = "1" // Assume a tolerance of 1 mV for V rest
	TPKeyWave[2][1]  = "50" // Assume a tolerance of 50pA for I rest
	TPKeyWave[2][2]  = num2str(RTolerance) // applies the same R tolerance for the instantaneous and steady state resistance
	TPKeyWave[2][3]  = num2str(RTolerance)
	TPKeyWave[2][4]  = "1e-12"
	TPKeyWave[2][5]  = "1e-12"
	TPKeyWave[2][6]  = "1e-6"
	TPKeyWave[2][7]  = "1e-6"
	TPKeyWave[2][8]  = LABNOTEBOOK_NO_TOLERANCE
	TPKeyWave[2][9]  = "0.1"
	TPKeyWave[2][10] = "0.1"
	TPKeyWave[2][11] = LABNOTEBOOK_NO_TOLERANCE

	TPSettingsWave[0][2][0, NUM_HEADSTAGES - 1]  = TPResults[%ResistanceInst][r]
	TPSettingsWave[0][3][0, NUM_HEADSTAGES - 1]  = TPResults[%ResistanceSteadyState][r]

	TPSettingsWave[0][8][0, NUM_HEADSTAGES - 1] = statusHS[r]

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		if(hsProp[i][%ClampMode] != V_CLAMP_MODE)
			continue
		endif

		if(AI_SelectMultiClamp(device, i) != AMPLIFIER_CONNECTION_SUCCESS)
			continue
		endif

		TPSettingsWave[0][4][i] = AI_SendToAmp(device, i, V_CLAMP_MODE, MCC_GETFASTCOMPCAP_FUNC, NaN, selectAmp = 0)
		TPSettingsWave[0][5][i] = AI_SendToAmp(device, i, V_CLAMP_MODE, MCC_GETSLOWCOMPCAP_FUNC, NaN, selectAmp = 0)
		TPSettingsWave[0][6][i] = AI_SendToAmp(device, i, V_CLAMP_MODE, MCC_GETFASTCOMPTAU_FUNC, NaN, selectAmp = 0)
		TPSettingsWave[0][7][i] = AI_SendToAmp(device, i, V_CLAMP_MODE, MCC_GETSLOWCOMPTAU_FUNC, NaN, selectAmp = 0)
	endfor

	TPSettingsWave[0][1][0, NUM_HEADSTAGES - 1] = hsProp[r][%ClampMode] == V_CLAMP_MODE ? TPResults[%BaselineSteadyState][r] : NaN
	TPSettingsWave[0][0][0, NUM_HEADSTAGES - 1] = hsProp[r][%ClampMode] == I_CLAMP_MODE ? TPResults[%BaselineSteadyState][r] : NaN

	TPSettingsWave[0][9][0, NUM_HEADSTAGES - 1]  = hsProp[r][%DAC]
	TPSettingsWave[0][10][0, NUM_HEADSTAGES - 1] = hsProp[r][%ADC]
	TPSettingsWave[0][11][0, NUM_HEADSTAGES - 1] = hsProp[r][%ClampMode]

	sweepNo = AFH_GetLastSweepAcquired(device)
	ED_AddEntriesToLabnotebook(TPSettingsWave, TPKeyWave, sweepNo, device, TEST_PULSE_MODE)

	TP_UpdateTPLBNSettings(device)

	ED_TPSettingsDocumentation(device, sweepNo, TEST_PULSE_MODE)
End

/// @brief Document the settings of the Testpulse
///
/// The source type entry is not fixed. We want to document the testpulse
/// settings during ITI and the testpulse settings for plain test pulses.
///
/// @param device      device
/// @param sweepNo         sweep number
/// @param entrySourceType type of reporting subsystem, one of @ref DataAcqModes
static Function ED_TPSettingsDocumentation(string device, variable sweepNo, variable entrySourceType)
	WAVE TPSettingsLBN        = GetTPSettingsLabnotebook(device)
	WAVE TPSettingsLBNKeyWave = GetTPSettingsLabnotebookKeyWave(device)

	ED_AddEntriesToLabnotebook(TPSettingsLBN, TPSettingsLBNKeyWave, sweepNo, device, entrySourceType)
End
