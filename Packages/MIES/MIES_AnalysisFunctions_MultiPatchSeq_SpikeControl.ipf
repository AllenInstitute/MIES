#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SC
#endif

/// @file MIES_AnalysisFunctions_MultiPatchSeq_SpikeControl.ipf
/// @brief __SC__ Spike Control analysis function for multi patch sequence

/// Pulse information in the labnotebook is stored as `PX_RY:...`. This regular expression can be used to match the
/// prefix in order to remove it with RemovePrefix.
static StrConstant SC_PULSE_PREFIX_RE = "^[^:]+:"

/// @brief Store the newly calcualted rerun trials in the labnotebook and return the minimum and maximum of it
static Function [variable minTrials, variable maxTrials] SC_GetTrials(string panelTitle, variable sweepNo, variable headstage)

	string key, msg

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE textualValues = GetLBTextualValues(panelTitle)

	key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_RERUN_TRIAL, query = 1)
	WAVE/Z trialsInSCI = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	// check that we have at least 2 sweeps in the current SCI
	if(DimSize(trialsInSCI, ROWS) == 1)
		return [0, 0]
	endif

	// use the trials from the previous which is from the *same* SCI
	WAVE/Z trialsLBN = GetLastSetting(numericalValues, sweepNo - 1, key, UNKNOWN_MODE)

	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	// check if we are still repeating the same sweep or have started a new one

	WAVE setSweepCountPrev = GetLastSetting(numericalValues, sweepNo - 1, "Set Sweep Count", DATA_ACQUISITION_MODE)
	WAVE setSweepCount     = GetLastSetting(numericalValues, sweepNo, "Set Sweep Count", DATA_ACQUISITION_MODE)

	WAVE stimsetAcqCycleIDPrev = GetLastSetting(numericalValues, sweepNo - 1, "Stimset Acq Cycle ID", DATA_ACQUISITION_MODE)
	WAVE stimsetAcqCycleID     = GetLastSetting(numericalValues, sweepNo, "Stimset Acq Cycle ID", DATA_ACQUISITION_MODE)

	if(EqualWaves(setSweepCountPrev, setSweepCount, 1) && EqualWaves(stimsetAcqCycleIDPrev, stimsetAcqCycleID, 1))
		trialsLBN[0, NUM_HEADSTAGES - 1] += (statusHS[p] == 1)
	else
		trialsLBN[0, NUM_HEADSTAGES - 1] = (statusHS[p] == 1 ? 0 : NaN)
	endif

	key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_RERUN_TRIAL)
	ED_AddEntryToLabnotebook(panelTitle, key, trialsLBN)

	sprintf msg, "rerun trials \"%s\"", NumericWaveToList(trialsLBN, "|")
	DebugPrint(msg)

	WAVE trialsLBNClean = ZapNaNs(trialsLBN)
	[minTrials, maxTrials] = WaveMinAndMaxWrapper(trialsLBNClean)

	return [minTrials, maxTrials]
End

/// @brief Return a 2D wave with the headstage QC result as a function of the set sweep count
///
/// This function *does* return the result for all active headstages. The `headstage` argument
/// is needed for fetching all sweeps from the current SCI.
///
/// Value:
/// - Cumulated headstage QC result
///
/// Rows:
/// - Headstage
///
/// Cols:
/// - Stimulus set sweep count
static Function/WAVE SC_GetHeadstageQCForSetCount(string panelTitle, variable sweepNo)

	variable DAC, sweepsInSet, i, numSweeps, setSweepCount, headstage
	string stimset, key, msg

	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	// use the first active headstage
	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	headstage = GetRowIndex(statusHS, val = 1)

	DAC = AFH_GetDACFromHeadstage(panelTitle, headstage)
	stimset = AFH_GetStimSetName(paneltitle, DAC, CHANNEL_TYPE_DAC)
	sweepsInSet = IDX_NumberOfSweepsInSet(stimset)

	// now we need to check that we have for every set sweep count
	// in the SCI one sweep where every headstage passed at least once
	// Or to rephrase that all headstages passed with all set sweep counts
	// sweep counts: [0, sweepsInSet - 1]

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)
	ASSERT(WaveExists(sweeps), "No sweeps acquired?")

	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT, sweepsInSet) headstageQCTotalPerSweepCount = 0

	numSweeps = DimSize(sweeps, ROWS)
	for(i = 0; i < numSweeps; i += 1)
		key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_HEADSTAGE_PASS, query = 1)
		WAVE headstageQCLBN = GetLastSetting(numericalValues, sweeps[i], key, UNKNOWN_MODE)

		setSweepCount = SC_GetSetSweepCount(numericalValues, sweeps[i])

		headstageQCTotalPerSweepCount[][setSweepCount] += IsFinite(headstageQCLBN[p]) ? headstageQCLBN[p] : NaN
	endfor

#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForCaller())
		for(i = 0; i < sweepsInSet; i += 1)
			Duplicate/FREE/RMD=[][i] headstageQCTotalPerSweepCount, slice
			Redimension/N=-1 slice
			sprintf msg, "headstageQC total at set sweep count %d \"%s\"", i, NumericWaveToList(slice, "|")
			DebugPrint(msg)
		endfor
	endif
#endif

	return headstageQCTotalPerSweepCount
End


/// @brief Return the stimulus set sweep count for the given sweep
static Function SC_GetSetSweepCount(WAVE numericalValues, variable sweepNo)

	variable setSweepCount

	WAVE setSweepCountLBN = GetLastSetting(numericalValues, sweepNo, "Set Sweep Count", DATA_ACQUISITION_MODE)

	WaveTransform/O zapNans, setSweepCountLBN
	setSweepCount = setSweepCountLBN[0]
	ASSERT(IsConstant(setSweepCountLBN, setSweepCount), "Unexpected set sweep counts")

	return setSweepCount
End

/// @brief Return pass/fail state of the set
///
/// This is true iff we have for very stimulus set sweep count a passing headstage
static Function SC_GetSetPassed(string panelTitle, variable sweepNo)

	WAVE headstageQCTotalPerSweepCount = SC_GetHeadstageQCForSetCount(panelTitle, sweepNo)

	FindValue/V=(0.0) headstageQCTotalPerSweepCount

	return V_Value == -1
End

/// @brief Return pass/fail state of the sweep
///
/// This is true iff we have for the current stimulus set sweep count a passing headstage
static Function SC_GetSweepPassed(string panelTitle, variable sweepNo)

	variable setSweepCount

	WAVE headstageQCTotalPerSweepCount = SC_GetHeadstageQCForSetCount(panelTitle, sweepNo)

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	setSweepCount = SC_GetSetSweepCount(numericalValues, sweepNo)

	FindValue/RMD=[][setSweepCount]/V=(0.0) headstageQCTotalPerSweepCount

	return V_Value == -1
End

/// @brief Return 1 if we are currently acquiring the last sweep in the stimulus set, 0 otherwise
static Function SC_LastSweepInSet(string panelTitle, variable sweepNo, variable headstage)

	variable DAC, sweepsInSet

	DAC = AFH_GetHeadstageFromDAC(panelTitle, headstage)
	sweepsInSet = IDX_NumberOfSweepsInSet(AFH_GetStimSetName(paneltitle, DAC, CHANNEL_TYPE_DAC))

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE sweepSetCount = GetLastSetting(numericalValues, sweepNo, "Set Sweep Count", DATA_ACQUISITION_MODE)

	return (sweepSetCount[headstage] + 1) == sweepsInSet
End

/// @brief Given a list of pulses by their indizes, this function return only the diagonal
/// ones which are matching the given sweep
static Function/WAVE SC_FilterPulses(WAVE/WAVE propertiesWaves, WAVE/Z indizesAll, WAVE/Z indizesSweep)

	variable i, j, size

	if(!WaveExists(indizesAll))
		return $""
	endif

	WAVE/Z indizesFiltered = GetSetIntersection(indizesSweep, indizesAll)

	if(!WaveExists(indizesFiltered))
		return $""
	endif

	Duplicate/FREE indizesFiltered, indizesFilteredDiagonal

	size = DimSize(indizesFiltered, ROWS)
	for(i = 0; i < size; i += 1)
		WAVE noteWave = propertiesWaves[indizesFiltered[i]][%PULSENOTE]
		if(GetNumberFromWaveNote(noteWave, NOTE_KEY_PULSE_IS_DIAGONAL) == 1)
			indizesFilteredDiagonal[j++] = indizesFiltered[i]
		endif
	endfor

	if(j == 0)
		return $""
	endif

	Redimension/N=(j) indizesFilteredDiagonal

	return indizesFilteredDiagonal
End

/// @brief Add a new `PX_PY:..` entry in to the wave `inputLBN`
///
/// The value part after the `:` is only present if `data` is passed in
static Function SC_AddPulseRegionLBNEntries(WAVE/T inputLBN, variable pulseIndex, variable region, variable headstage, [WAVE/Z data])
	string str

	sprintf str, "P%d_R%d", pulseIndex, region

	if(!ParamIsDefault(data))
		str += ":"

		if(IsNumericWave(data))
			str += NumericWaveToList(data, ",")
		elseif(IsTextWave(data))
			str += TextWaveToList(data, ",")
		else
			ASSERT(0, "Unsupported wave type")
		endif
	endif

	inputLBN[headstage] = AddListItem(str, inputLBN[headstage], ";", Inf)
End

/// @brief Return the PA plot waves from the databrowser connected to the given device
static Function [WAVE properties, WAVE/WAVE propertiesWaves] SC_GetPulseAveragePropertiesWaves(string paneltitle)

	string databrowser

	databrowser = DB_FindDataBrowser(panelTitle)
	DFREF dfr = BSP_GetFolder(databrowser, MIES_BSP_PANEL_FOLDER)
	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(dfr)
	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)
	WAVE/WAVE propertiesWaves = GetPulseAveragePropertiesWaves(pulseAverageHelperDFR)

	return [properties, propertiesWaves]
End

/// @brief Return the diagonal pulses for the given sweep
static Function/WAVE SC_GetPulseIndizes(WAVE properties, WAVE/WAVE propertiesWaves, variable sweepNo)
	variable idx, size, endRow, i, headstageProp, region, pulseIndex, sweepNoProp, pulseFailedState
	string entry, msg

	size = GetNumberFromWaveNote(properties, NOTE_INDEX)
	endRow = limit(size - 1, 0, inf)

	WAVE/Z indizesSweep = FindIndizes(properties, colLabel = "Sweep", var = sweepNo, endRow = endRow)
	ASSERT(WaveExists(indizesSweep), "Could not find sweeps with sweepNo")

	WAVE/Z indizesAllPulses = SC_FilterPulses(propertiesWaves, indizesSweep, indizesSweep)

	sprintf msg, "indizes all pulses \"%s\"", NumericWaveToList(SelectWave(WaveExists(indizesAllPulses), {NaN}, indizesAllPulses), "|")
	DebugPrint(msg)

	return indizesAllPulses
End

/// @brief Return the spike numbers and positions in waves prepared for labnotebook writing
static Function [WAVE/T spikeNumbersLBN, WAVE/T spikePositionsLBN] SC_GetSpikeNumbersAndPositions(string panelTitle, variable sweepNo)
	variable i, idx, numFailedPulses, sweepPassed, size, numPulses
	variable pulseIndex, region, pulseFailedState, headstageProp, sweepNoProp, numberOfSpikes
	variable pulseStart, pulseEnd, numSpikes
	string entry, msg

	WAVE/Z properties
	WAVE/WAVE/Z propertiesWaves
	[properties, propertiesWaves] = SC_GetPulseAveragePropertiesWaves(paneltitle)

	WAVE/Z indizesAllPulses = SC_GetPulseIndizes(properties, propertiesWaves, sweepNo)

	// one sweep has multiple pulses and each pulse can have multiple spikes
	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT)/T spikePositionsLBN, spikeNumbersLBN

	numPulses = WaveExists(indizesAllPulses) ? DimSize(indizesAllPulses, ROWS) : 0
	for(i = 0; i < numPulses; i += 1)
		idx = indizesAllPulses[i]

		sweepNoProp = properties[idx][%Sweep]
		headstageProp = properties[idx][%Headstage]
		pulseIndex = properties[idx][%Pulse]
		region = properties[idx][%Region]

		WAVE noteWave = propertiesWaves[idx][PA_PROPERTIESWAVES_INDEX_PULSENOTE]

		if(MSQ_TestOverrideActive())
			WAVE/T overrideResults = GetOverrideResults()
			entry = overrideResults[sweepNoProp][headstageProp][pulseIndex][region]
			WAVE spikePositions = ListToNumericWave(StringByKey("SpikePosition_ms", entry), ",")
		else
			// stored in ms relative to pulse start
			WAVE spikePositions = ListToNumericWave(GetStringFromWaveNote(noteWave, NOTE_KEY_PULSE_SPIKE_POSITIONS), ",")
		endif

		// coordinates are in ms of the pulse
		pulseStart = GetNumberFromWaveNote(noteWave, NOTE_KEY_PULSE_START)
		pulseEnd = GetNumberFromWaveNote(noteWave, NOTE_KEY_PULSE_END)

		numSpikes = DimSize(spikePositions, ROWS)

		if(numSpikes > 0)
			// convert spike positions to 0-100 coordinates (aka pulse active coordinate system)
			Make/FREE/D/N=(numSpikes) spikePositionsPUCrd = (spikePositions[p] - pulseStart) / (pulseEnd - pulseStart) * 100
			// round to one decimal digit
			spikePositionsPUCrd[] = round(spikePositionsPUCrd[p] * 10) / 10

			SC_AddPulseRegionLBNEntries(spikePositionsLBN, pulseIndex, region, headstageProp, data = spikePositionsPUCrd)
		endif

		SC_AddPulseRegionLBNEntries(spikeNumbersLBN, pulseIndex, region, headstageProp, data = {DimSize(spikePositions, ROWS)})
	endfor

	sprintf msg, "spike numbers \"%s\", spike positions \"%s\"", TextWaveToList(spikeNumbersLBN, "|"), TextWaveToList(spikePositionsLBN, "|")
	DebugPrint(msg)

	return [spikeNumbersLBN, spikePositionsLBN]
End

/// @brief Fetch the pulses from the PA plot and write the results into the labnotebooks
static Function SC_ProcessPulses(string panelTitle, variable sweepNo, variable minimumSpikePosition, variable idealNumberOfSpikes)
	string key

	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	WAVE/T/Z spikeNumbersLBN, spikePositionsLBN
	[spikeNumbersLBN, spikePositionsLBN] = SC_GetSpikeNumbersAndPositions(panelTitle, sweepNo)

	key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_SPIKE_COUNTS)
	ED_AddEntryToLabnotebook(panelTitle, key, spikeNumbersLBN, unit = "a. u.")

	key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_SPIKE_POSITIONS)
	ED_AddEntryToLabnotebook(panelTitle, key, spikePositionsLBN, unit = "PA crd")

	if(!HasOneValidEntry(spikePositionsLBN))
		KillWaves/Z spikePositionsLBN
	endif

	SC_DetermineQCState(panelTitle, sweepNo, spikeNumbersLBN, spikePositionsLBN, minimumSpikePosition, idealNumberOfSpikes)
End

/// @brief Convert a numeric spike counts state to its string
///
/// Returns "" for unknown state variables
static Function/S SC_SpikeCountStateToString(variable countState)

	switch(countState)
		case SC_SPIKE_COUNT_NUM_GOOD:
			return SC_SPIKE_COUNT_STATE_STR_GOOD
			break
		case SC_SPIKE_COUNT_NUM_TOO_FEW:
			return SC_SPIKE_COUNT_STATE_STR_TOO_FEW
			break
		case SC_SPIKE_COUNT_NUM_TOO_MANY:
			return SC_SPIKE_COUNT_STATE_STR_TOO_MANY
			break
		case SC_SPIKE_COUNT_NUM_MIXED:
			return SC_SPIKE_COUNT_STATE_STR_MIXED
			break
		default:
			return ""
	endswitch
End

/// @brief Determine the spike counts state
///
/// - Minimum[HS] == Maximum[HS] == idealNumberOfSpikes -> Pass
/// - idealNumberOfSpikes >= Maximum[HS] -> Too few
/// - idealNumberOfSpikes <= Mininum[HS] -> Too many
/// - If nothing else matched -> Mixed
///
/// We assume:
/// - minimum < maximum
/// - idealNumberOfSpikes >= 1
/// - All numbers are integers
static Function SC_SpikeCountsCalcDetail(variable minimum, variable maximum, variable idealNumberOfSpikes)

	if(idealNumberOfSpikes == minimum && idealNumberOfSpikes == maximum)
		return SC_SPIKE_COUNT_NUM_GOOD
	elseif(idealNumberOfSpikes >= maximum)
		return SC_SPIKE_COUNT_NUM_TOO_FEW
	elseif(idealNumberOfSpikes <= minimum)
		return SC_SPIKE_COUNT_NUM_TOO_MANY
	elseif(IsNaN(minimum) && IsNaN(maximum))
		// headstages without pulses
		return SC_SPIKE_COUNT_NUM_MIXED
	endif

	ASSERT(idealNumberOfSpikes > minimum && idealNumberOfSpikes < maximum, "Unexpected case in spike counts calculation")
	return SC_SPIKE_COUNT_NUM_MIXED
End

/// @brief Determine the spike counts state for all headstages
static Function/WAVE SC_SpikeCountsCalc(string panelTitle, WAVE minimum, WAVE maximum, variable idealNumberOfSpikes)
	variable i
	string msg

	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) state = NaN
	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(!statusHS[i])
			continue
		endif

		state[i] = SC_SpikeCountsCalcDetail(minimum[i], maximum[i], idealNumberOfSpikes)
	endfor

	sprintf msg, "numeric spike counts state \"%s\"", NumericWaveToList(state, "|")
	DebugPrint(msg)

	return state
End

/// @brief Check that the we have found the expected number of spikes per pulse
///
/// @return Spike counts state according to @ref SpikeCountsStateConstants stringified
static Function/WAVE SC_SpikeCountsQC(string panelTitle, WAVE/T spikeNumbersLBN, variable idealNumberOfSpikes)
	string msg, str
	variable i

	ASSERT(IsInteger(idealNumberOfSpikes) && idealNumberOfSpikes > 0, "Invalid ideal number of spikes")

	Make/FREE/N=(NUM_HEADSTAGES)/WAVE spikeNumbers = ListToNumericWave(RemovePrefixFromListItem(SC_PULSE_PREFIX_RE, spikeNumbersLBN[p], regExp = 1), ";")

#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForCaller())

		WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

		str = ""

		for(i = 0; i < NUM_HEADSTAGES; i += 1)

			if(!statusHS[i])
				continue
			endif

			sprintf msg, "HS%d: \"%s\", ", i, NumericWaveToList(spikeNumbers[i], ";")
			str += msg
		endfor

		DebugPrint(RemoveEnding(str, ", "))
	endif
#endif

	Make/FREE/N=(NUM_HEADSTAGES) minimum, maximum
	minimum[] = WaveMin(spikeNumbers[p])
	maximum[] = WaveMax(spikeNumbers[p])

	WAVE state = SC_SpikeCountsCalc(panelTitle, minimum, maximum, idealNumberOfSpikes)

	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT)/T stateAsString = SC_SpikeCountStateToString(state[p])

	sprintf msg, "spike counts state \"%s\"", TextWaveToList(stateAsString, "|")
	DebugPrint(msg)

	return stateAsString
End

/// @brief Calculate the QC state of a list of spike positions from one pulse
///
/// All are in `Pulse active coordinate system`
///
/// @param spikePositions       spike position
/// @param minimumSpikePosition minimum allowed spike position
static Function SC_SpikePositionsCalcDetail(WAVE spikePositions, variable minimumSpikePosition)

	WaveStats/Q/M=1 spikePositions
	ASSERT_TS(V_numInfs == 0 && V_numNaNs == 0, "Unexpected non-finite entries in input")

	return V_avg >= minimumSpikePosition
End

/// @brief Calculate the QC state of the spike positions of each pulse
///
/// All values are in PA crd, see SC_SpikeControl().
///
/// @param panelTitle           device
/// @param spikePositionsLBN    spike position of each pulse, ordered per headstage, for the current sweep
/// @param minimumSpikePosition minimum allowed spike position
static Function/WAVE SC_SpikePositionQC(string panelTitle, WAVE/T/Z spikePositionsLBN, variable minimumSpikePosition)
	string list, msg
	variable numPulses, i

	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) spikePositionsQCLBN = NaN

	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	spikePositionsQCLBN[0, NUM_HEADSTAGES - 1] = (statusHS[p] == 1) ? 0 : NaN

	if(!WaveExists(spikePositionsLBN))
		return spikePositionsQCLBN
	endif

	// HS0 -> PX_RX:1.23,4.56;PY_RY:1.23,4.56
	Make/FREE/WAVE/N=(NUM_HEADSTAGES) spikePositionsPerHeadstage = ListToTextWave(spikePositionsLBN[p], ";")

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		WAVE/T spikePositionsPerPulse = spikePositionsPerHeadstage[i]
		numPulses = DimSize(spikePositionsPerPulse, ROWS)

		sprintf msg, "HS%d: (text) \"%s\", ", i, TextWaveToList(spikePositionsPerPulse, ";")
		DebugPrint(msg)

		if(numPulses > 0)
			spikePositionsPerPulse[] = RemovePrefix(spikePositionsPerPulse[p], start = SC_PULSE_PREFIX_RE, regexp = 1)
			Make/FREE/WAVE/N=(numPulses) spikePositionsPerPulseNum = ListToNumericWave(spikePositionsPerPulse[p], ",")

			sprintf msg, "HS%d: (numeric) \"%s\", ", i, NumericWaveToList(spikePositionsPerPulseNum[i], ";")
			DebugPrint(msg)

			Make/FREE/N=(numPulses) spikePositionQCPerPulse
			spikePositionQCPerPulse = SC_SpikePositionsCalcDetail(spikePositionsPerPulseNum[p], minimumSpikePosition)

			spikePositionsQCLBN[i] = IsConstant(spikePositionQCPerPulse, 1)
		else
			// do nothing, spikePositionsQCLBN is initialized to 0
		endif
	endfor

	sprintf msg, "spike positions \"%s\"", NumericWaveToList(spikePositionsQCLBN, "|")
	DebugPrint(msg)

	return spikePositionsQCLBN
End

/// @brief Replace all points inside an oodDAQ region with NaN in the data wave
static Function/WAVE SC_RegionBlanked(WAVE data, variable totalOnsetDelay, WAVE/T oodDAQRegion)
	variable i, numEntries, first, last

	numEntries = DimSize(oodDAQRegion, ROWS)
	Make/D/FREE/N=(numEntries) regionStart, regionEnd

	regionStart[] = str2num(StringFromList(0, oodDAQRegion[p], "-")) + totalOnsetDelay
	regionEnd[]   = str2num(StringFromList(1, oodDAQRegion[p], "-")) + totalOnsetDelay

	for(i = 0; i < numEntries; i += 1)
		first = ScaleToIndex(data, regionStart[i], ROWS)
		last  = ScaleToIndex(data, regionEnd[i], ROWS)
		data[first, last] = NaN
	endfor

	return ZapNaNs(data)
End

/// @brief Return a wave ready for the labnotebook with the spontaneous spike check QC entries
static Function/WAVE SC_SpontaneousSpikingCheckQC(string panelTitle, variable sweepNo)

	variable failedPulseLevel, totalOnsetDelay, i, maximum, headstage
	string key, msg, entry

	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	// use the first active headstage
	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	headstage = GetRowIndex(statusHS, val = 1)

	key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_FAILED_PULSE_LEVEL, query = 1)
	failedPulseLevel = GetLastSettingIndepSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	ASSERT(IsFinite(failedPulseLevel), "Invalid failed pulse level")

	totalOnsetDelay = GetTotalOnsetDelay(numericalValues, sweepNo)

	WAVE sweepWave = GetSweepWave(paneltitle, sweepNo)

	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) spontaneousSpikingCheckLBN = NaN
	spontaneousSpikingCheckLBN[0, NUM_HEADSTAGES - 1] = (statusHS[p] == 1) ? 0 : NaN

	WAVE textualValues = GetLBTextualValues(panelTitle)
	WAVE/Z/T oodDAQRegions = GetLastSetting(textualValues, sweepNo, "oodDAQ regions", DATA_ACQUISITION_MODE)
	ASSERT(WaveExists(oodDAQRegions), "Could not find oodDAQ regions")

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		WAVE singleAD = AFH_ExtractOneDimDataFromSweep(panelTitle, sweepWave, i, XOP_CHANNEL_TYPE_ADC)
		WAVE oodDAQRegion = ListToTextWave(oodDAQRegions[i], ";")

		SC_RegionBlanked(singleAD, totalOnsetDelay, oodDAQRegion)

		// check that the max of the data is below failedPulseLevel
		if(MSQ_TestOverrideActive())
			WAVE/T overrideResults = GetOverrideResults()

			entry = overrideResults[sweepNo][i][0][0]
			maximum = NumberByKey("SpontaneousSpikeMax", entry)
		else
			maximum = WaveMax(singleAD)
		endif

		sprintf msg, "maximum %g, failed pulse level %g", maximum, failedPulseLevel
		DebugPrint(msg)

		spontaneousSpikingCheckLBN[i] = maximum < failedPulseLevel
	endfor

	sprintf msg, "spontaneous spike check \"%s\"", NumericWaveToList(spontaneousSpikingCheckLBN, "|")
	DebugPrint(msg)

	return spontaneousSpikingCheckLBN
End

/// @brief Determine the headstage QC result
static Function/WAVE SC_HeadstageQC(string panelTitle, WAVE/T spikeCountStateLBN, WAVE spontaneousSpikingCheckLBN)
	string msg

	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) headstageQCLBN = NaN

	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	// spike positions QC does not influence headstage QC
	headstageQCLBN[0, NUM_HEADSTAGES - 1] = (statusHS[p] == 1) ? (spontaneousSpikingCheckLBN[p] == 1 && !cmpstr(spikeCountStateLBN[p], SC_SPIKE_COUNT_STATE_STR_GOOD)) : NaN

	sprintf msg, "headstage check \"%s\"", NumericWaveToList(headstageQCLBN, "|")
	DebugPrint(msg)

	return headstageQCLBN
End

/// @brief Determine and write the QC states to the labnotebook
static Function SC_DetermineQCState(string panelTitle, variable sweepNo, WAVE spikeNumbersLBN, WAVE/Z spikePositionsLBN, variable minimumSpikePosition, variable idealNumberOfSpikes)
	string key, msg

	// spontaneous spiking check
	WAVE spontaneousSpikingCheckLBN = SC_SpontaneousSpikingCheckQC(panelTitle, sweepNo)
	key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_SPONT_SPIKE_PASS)
	ED_AddEntryToLabnotebook(panelTitle, key, spontaneousSpikingCheckLBN, unit = LABNOTEBOOK_BINARY_UNIT)

	// spike counts
	WAVE/T spikeCountStateLBN = SC_SpikeCountsQC(panelTitle, spikeNumbersLBN, idealNumberOfSpikes)
	key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_SPIKE_COUNTS_STATE)
	ED_AddEntryToLabnotebook(panelTitle, key, spikeCountStateLBN, unit = "a. u.")

	// headstage QC
	WAVE headstageQCLBN = SC_HeadstageQC(panelTitle, spikeCountStateLBN, spontaneousSpikingCheckLBN)
	key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_HEADSTAGE_PASS)
	ED_AddEntryToLabnotebook(panelTitle, key, headstageQCLBN, unit = LABNOTEBOOK_BINARY_UNIT)

	// spike positions
	WAVE spikePositionsQCLBN = SC_SpikePositionQC(panelTitle, spikePositionsLBN, minimumSpikePosition)
	key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_SPIKE_POSITION_PASS)
	ED_AddEntryToLabnotebook(panelTitle, key, spikePositionsQCLBN, unit = LABNOTEBOOK_BINARY_UNIT)
End

/// @brief Check if we can still skip sweeps without running more than `maxTrials`
static Function SC_CanStillSkip(variable maxTrials, string params)

	// 1st trial: 0
	// 2nd trial: 1
	// maxTrialsAllowed 2 -> don't skip anymore
	variable maxTrialsAllowed = AFH_GetAnalysisParamNumerical("MaxTrials", params, defValue = Inf)

	return DEBUGPRINTv(maxTrials < (maxTrialsAllowed - 1))
End

/// @brief Check if we have exhausted the available trials on all headstages
static Function SC_SkipsExhausted(variable minTrials, string params)

	variable maxTrialsAllowed = AFH_GetAnalysisParamNumerical("MaxTrials", params, defValue = Inf)

	return DEBUGPRINTv(minTrials >= maxTrialsAllowed)
End

/// @brief Helper for setting the DAScale
static Function SC_SetDAScaleModOp(string panelTitle, variable headstage, variable modifier, string operator, [variable invert])

	if(ParamIsDefault(invert))
		invert = 0
	else
		invert = !!invert
	endif

	strswitch(operator)
		case "+":
			SetDAScale(panelTitle, headstage, offset = invert ? - modifier : modifier)
			break
		case "*":
			SetDAScale(panelTitle, headstage, relative = invert ? 1 / modifier : modifier)
			break
		default:
			ASSERT(0, "Invalid operator")
			break
	endswitch
End

/// @brief Perform various actions on QC failures
static Function SC_ReactToQCFailures(string panelTitle, variable sweepNo, string params)
	variable daScaleSpikePositionModifier, daScaleModifier, i, autoBiasV, autobiasModifier, prevSliderPos
	string daScaleOperator, daScaleSpikePositionOperator
	string key, msg

	daScaleModifier = AFH_GetAnalysisParamNumerical("DAScaleModifier", params)
	daScaleOperator = AFH_GetAnalysisParamTextual("DAScaleOperator", params)
	daScaleSpikePositionModifier = AFH_GetAnalysisParamNumerical("DAScaleSpikePositionModifier", params)
	daScaleSpikePositionOperator = AFH_GetAnalysisParamTextual("DAScaleSpikePositionOperator", params)
	autobiasModifier = AFH_GetAnalysisParamNumerical("AutoBiasBaselineModifier", params)

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE textualValues = GetLBTextualValues(panelTitle)
	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_SPIKE_COUNTS_STATE, query = 1)
	WAVE/T spikeCountStateLBN = GetLastSetting(textualValues, sweepNo, key, UNKNOWN_MODE)

	key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_SPIKE_POSITION_PASS, query = 1)
	WAVE spikePositionsQCLBN = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

	key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_SPONT_SPIKE_PASS, query = 1)
	WAVE spontaneousSpikingCheckQCLBN = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

	key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_HEADSTAGE_PASS, query = 1)
	WAVE headstageQCLBN = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

	prevSliderPos = GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage")

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(!statusHS[i])
			continue
		endif

		if(headstageQCLBN[i])
			if(!spikePositionsQCLBN[i])
				sprintf msg, "spike position QC failed on HS%d, adapting DAScale", i
				DebugPrint(msg)
				SC_SetDAScaleModOp(panelTitle, i, daScaleSpikePositionModifier, daScaleSpikePositionOperator)
			endif

			continue
		endif

		ASSERT(!headstageQCLBN[i], "Expected failing headstage QC")

		if(!spontaneousSpikingCheckQCLBN[i])
			sprintf msg, "spontaneous spiking QC failed on HS%d, adapting autobiasV", i
			DebugPrint(msg)

			PGC_SetAndActivateControl(panelTitle, "slider_DataAcq_ActiveHeadstage", val = i)
			autoBiasV = GetSetVariable(panelTitle, "setvar_DataAcq_AutoBiasV") + autobiasModifier
			PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_AutoBiasV", val = autoBiasV)
		endif

		if(cmpstr(spikeCountStateLBN[i], SC_SPIKE_COUNT_STATE_STR_GOOD))
			sprintf msg, "spike countQC failed with %s on HS%d, adapting DAScale", spikeCountStateLBN[i], i
			DebugPrint(msg)
		endif

		strswitch(spikeCountStateLBN[i])
			case SC_SPIKE_COUNT_STATE_STR_TOO_MANY:
				SC_SetDAScaleModOp(panelTitle, i, 2 * daScaleModifier, daScaleOperator, invert = 1)
				break
			case SC_SPIKE_COUNT_STATE_STR_MIXED:
				printf "The spike count on headstage %d in sweep %d is mixed (some pulses have too few, others too many)\n", i, sweepNo
				key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_SPIKE_COUNTS_STATE, query = 1)
				WAVE/T/Z spikeCountsRAC = GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, key, i, UNKNOWN_MODE)
				ASSERT(WaveExists(spikeCountsRAC), "Expected at least one sweep")
				WAVE/Z indizes = FindIndizes(spikeCountsRAC, col = 0, str = SC_SPIKE_COUNT_STATE_STR_MIXED)
				ASSERT(WaveExists(indizes), "Could not find at least one mixed entry")
				if(DimSize(indizes, ROWS) == 1)
					// push to front on first time
					ControlWindowToFront()
				endif
			case SC_SPIKE_COUNT_STATE_STR_TOO_FEW: // fallthrough-by-design
				SC_SetDAScaleModOp(panelTitle, i, daScaleModifier, daScaleOperator)
				break
			case SC_SPIKE_COUNT_STATE_STR_GOOD:
				// nothing to do
				break
			default:
				ASSERT(0, "Impossible case")
				break
		endswitch
	endfor

	if(prevSliderPos != GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage"))
		PGC_SetAndActivateControl(panelTitle, "slider_DataAcq_ActiveHeadstage", val = prevSliderPos)
	endif
End

Function/S SC_SpikeControl_GetParams()
	return "[FailedPulseLevel:variable],[MaxTrials:variable],DAScaleOperator:string,DAScaleModifier:variable,"             \
            + "DAScaleSpikePositionOperator:string,DAScaleSpikePositionModifier:variable,MinimumSpikePosition:variable," \
            + "IdealNumberOfSpikesPerPulse:variable,AutoBiasBaselineModifier:variable"
End

Function/S SC_SpikeControl_GetHelp(name)
	string name

	strswitch(name)
		case "FailedPulseLevel":
			return "[Optional, uses the already set value] Numeric level to use for the failed pulse search in the PA plot tab."
			break
		case "MaxTrials":
			return "[Optional, defaults to infinity] A sweep is rerun this many times on a failed headstage."
			break
		case "DAScaleOperator":
			return "Set the math operator to use for combining the DAScale and the "            \
			       + "modifier. Valid strings are \"+\" (addition) and \"*\" (multiplication)."
			break
		case "DAScaleModifier":
			return "Modifier value to the DA Scale of headstages with failed pulses"
			break
		case "DAScaleSpikePositionOperator":
			return "Set the math operator to use for combining the DAScale and the "                           \
			       + "spike position modifier. Valid strings are \"+\" (addition) and \"*\" (multiplication)."
			break
		case "DAScaleSpikePositionModifier":
			return "Modifier value to the DA Scale of headstages with failing spike positions."
			break
		case "MinimumSpikePosition":
			return "Minimum allowed spike positions in pulse active coordinate system (0 - 100)."
			break
		case "IdealNumberOfSpikesPerPulse":
			return "Ideal number of spike which should be present. Overwrites the PA plot GUI value."
			break
		case "AutoBiasBaselineModifier":
			return "Auto bias modifier value in mV on failing baseline QC."
			break
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
			break
	endswitch
End

Function/S SC_SpikeControl_CheckParam(string name, string params)

	variable val
	string str

	strswitch(name)
		case "FailedPulseLevel":
			val = AFH_GetAnalysisParamNumerical(name, params)
			if(!IsFinite(val))
				return "Invalid value " + num2str(val)
			endif
			break
		case "MaxTrials":
			val = AFH_GetAnalysisParamNumerical(name, params)
			if(!IsFinite(val))
				return "Invalid value " + num2str(val)
			endif
			break
		case "DAScaleOperator":
		case "DAScaleSpikePositionOperator":
			str = AFH_GetAnalysisParamTextual(name, params)
			if(cmpstr(str, "+") && cmpstr(str, "*"))
				return "Invalid string " + str
			endif
			break
		case "DAScaleModifier":
		case "DAScaleSpikePositionModifier":
			val = AFH_GetAnalysisParamNumerical(name, params)
			if(!IsFinite(val))
				return "Invalid value " + num2str(val)
			endif
			break
		case "MinimumSpikePosition":
			val = AFH_GetAnalysisParamNumerical(name, params)
			if(!IsFinite(val) || !(val >= 0 && val <= 100))
				return "Invalid value " + num2str(val)
			endif
			break
		case "IdealNumberOfSpikesPerPulse":
			val = AFH_GetAnalysisParamNumerical(name, params)
			if(!IsInteger(val) || val <= 0)
				return "Invalid value " + num2str(val)
			endif
			break
		case "AutoBiasBaselineModifier":
			val = AFH_GetAnalysisParamNumerical(name, params)
			if(!IsFinite(val) || abs(val) >= 1000)
				return "Invalid value " + num2str(val)
			endif
			break
	endswitch

	return ""
End

/// @brief Analysis function to check sweeps for failed pulses and rerun them if the pulses failed.
///
/// Decision logic flowchart:
///
/// \rst
/// .. image:: /dot/multi-patch-seq-spike-control.svg
/// \endrst
///
/// For judging the quality of the spike positions we have introduced a new coordinate system which
/// we call pulse active coordinate system (`PA crd`).
///
/// Consider the following pulse on the DA wave and the response spike in the AD wave
///
/// @verbatim
///
///        +---------+
///        |         |
///        |         |
///        |         |
///        |         |
///        |         |
///        |         |
/// -------+         +----------------------
///
///                   X
///                  XXX
///                 X   XX
///                X      XX
///               X         X
///              X           X
///             X             X
///            X               X
///           X                X
///          X                  X
///         X                   X
/// -------X                    X--------
///
/// @endverbatim
///
/// and the let pulse active start at 5ms and end at 15ms. We define the start as 0 and the end as 100.
/// Therefore the spike position will be 110 in `PA crd` which is one point after the end of the pulse.
///
/// The graphs were made with http://asciiflow.com.
Function SC_SpikeControl(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3 &s

	variable i, index, ret, headstagePassed, sweepPassed, val, failedPulseLevel, maxTrialsAllowed, minimumSpikePosition
	variable DAC, setPassed, minTrials, maxTrials, skippedBack, idealNumberOfSpikes, rerunExceededResult
	string msg, key, ctrl, databrowser, bsPanel, scPanel, stimset
	string stimsets = ""

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			return MSQ_CommonPreDAQ(panelTitle, s.headstage)

			break
		case PRE_SET_EVENT:

			if(s.headstage != DAP_GetHighestActiveHeadstage(panelTitle))
				return NaN
			endif

			databrowser = DB_FindDataBrowser(panelTitle)
			if(IsEmpty(databrowser)) // not yet open
				databrowser = DB_OpenDataBrowser()
			endif

			bsPanel = BSP_GetPanel(databrowser)
			scPanel = BSP_GetSweepControlsPanel(databrowser)

			if(!BSP_HasBoundDevice(bsPanel))
				PGC_SetAndActivateControl(bsPanel, "popup_DB_lockedDevices", str = panelTitle)
				databrowser = DB_FindDataBrowser(panelTitle)
				bsPanel = BSP_GetPanel(databrowser)
			endif

			PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_OVS", val = 1)
			PGC_SetAndActivateControl(bsPanel, "check_ovs_clear_on_new_stimset_cycle", val = 1)

			PGC_SetAndActivateControl(scPanel, "check_SweepControl_AutoUpdate", val = 1)

			PGC_SetAndActivateControl(bsPanel, "check_pulseAver_searchFailedPulses", val = 1)

			failedPulseLevel = AFH_GetAnalysisParamNumerical("FailedPulseLevel", s.params)
			if(IsFinite(failedPulseLevel)) // parameter is present
				PGC_SetAndActivateControl(bsPanel, "setvar_pulseAver_failedPulses_level", val = failedPulseLevel)
			else
				failedPulseLevel = GetSetVariable(bsPanel, "setvar_pulseAver_failedPulses_level")
			endif

			Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) settingsLBN = NaN
			settingsLBN[INDEP_HEADSTAGE] = failedPulseLevel
			key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_FAILED_PULSE_LEVEL)
			ED_AddEntryToLabnotebook(panelTitle, key, settingsLBN, unit = "a. u.", overrideSweepNo = s.sweepNo)

			idealNumberOfSpikes = AFH_GetAnalysisParamNumerical("IdealNumberOfSpikesPerPulse", s.params)
			PGC_SetAndActivateControl(bsPanel, "setvar_pulseAver_numberOfSpikes", val = idealNumberOfSpikes)

			settingsLBN = NaN
			settingsLBN[INDEP_HEADSTAGE] = idealNumberOfSpikes
			key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_IDEAL_SPIKE_COUNTS)
			ED_AddEntryToLabnotebook(panelTitle, key, settingsLBN, unit = "a. u.", overrideSweepNo = s.sweepNo)

			// turn on PA plot at the end to skip expensive updating
			PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_PA", val = 1)

			WAVE statusTTL = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_TTL)
			if(Sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

			for(i = 0; i < NUM_HEADSTAGES; i += 1)

				if(!statusHS[i])
					continue
				endif

				DAC = AFH_GetDACFromHeadstage(panelTitle, i)
				ASSERT(IsFinite(DAC), "Unexpected unassociated DAC")
				stimset = AFH_GetStimSetName(panelTitle, DAC, CHANNEL_TYPE_DAC)
				stimsets = AddListItem(stimset, stimsets, ";", inf)
			endfor

			if(ItemsInList(GetUniqueTextEntriesFromList(stimsets)) > 1)
				printf "(%s): Not all headstages have the same stimset.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			// set more controls usually done from SetControlInEvent analysis function
			// remove once https://github.com/AllenInstitute/MIES/issues/671 is resolved
			PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_OnsetDelayUser", val = 500)
			PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_TerminationDelay", val = 1000)
			PGC_SetAndActivateControl(panelTitle,"Check_DataAcq1_dDAQOptOv", val = 1)
			PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_dDAQDelay", val = 0)
			PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_dDAQOptOvPre", val = 0)
			PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_dDAQOptOvPost", val = 250)
			PGC_SetAndActivateControl(panelTitle, "SetVar_DataAcq_SetRepeats", val = 1)

			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) rerunExceeded = NaN
			rerunExceeded[0, NUM_HEADSTAGES - 1] = (statusHS[p] == 1) ? 0 : NaN
			key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_RERUN_TRIAL_EXC)
			ED_AddEntryToLabnotebook(panelTitle, key, rerunExceeded, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) trialsLBN = NaN
			trialsLBN[0, NUM_HEADSTAGES - 1] = (statusHS[p] == 1 ? 0 : NaN)
			key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_RERUN_TRIAL)
			ED_AddEntryToLabnotebook(panelTitle, key, trialsLBN, unit = "a. u.", overrideSweepNo = s.sweepNo)

			break
		case POST_SWEEP_EVENT:

			if(s.headstage != DAP_GetHighestActiveHeadstage(panelTitle))
				return NaN
			endif

			minimumSpikePosition = AFH_GetAnalysisParamNumerical("MinimumSpikePosition", s.params)

			WAVE numericalValues = GetLBNumericalValues(panelTitle)
			key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_IDEAL_SPIKE_COUNTS, query = 1)
			idealNumberOfSpikes = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			SC_ProcessPulses(panelTitle, s.sweepNo, minimumSpikePosition, idealNumberOfSpikes)

			// sweep QC
			sweepPassed = SC_GetSweepPassed(panelTitle, s.sweepNo)

			Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) sweepQCLBN = NaN
			sweepQCLBN[INDEP_HEADSTAGE] = sweepPassed
			key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(panelTitle, key, sweepQCLBN, unit = LABNOTEBOOK_BINARY_UNIT)

			[minTrials, maxTrials] = SC_GetTrials(panelTitle, s.sweepNo, s.headstage)

			SC_ReactToQCFailures(panelTitle, s.sweepNo, s.params)

			if(!sweepPassed)
				if(SC_CanStillSkip(maxTrials, s.params))
					skippedBack = 1
					RA_SkipSweeps(panelTitle, -1, limitToSetBorder=1)
				else
					rerunExceededResult = 1
				endif
			endif

			WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) rerunExceeded = NaN
			rerunExceeded[0, NUM_HEADSTAGES - 1] = (statusHS[p] == 1) ? rerunExceededResult : NaN
			key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_RERUN_TRIAL_EXC)
			ED_AddEntryToLabnotebook(panelTitle, key, rerunExceeded, unit = LABNOTEBOOK_BINARY_UNIT)

			setPassed = SC_GetSetPassed(panelTitle, s.sweepNo)

			// check if we can still pass
			if(!setPassed)
				if(SC_SkipsExhausted(minTrials, s.params))
					// if the minimum trials value has already reached the maximum
					// allowed trials, we are done and the set has not passed
				elseif(SC_LastSweepInSet(panelTitle, s.sweepNo, s.headstage) && !skippedBack)
					// work around broken XXX_SET_EVENT
					// we are done and were not successful
				else
					// still some trials left
					setPassed = NaN
				endif
			endif

			sprintf msg, "minTrials %g, maxTrials %g, sweepPassed %g, setPassed %g", minTrials, maxTrials, sweepPassed, setPassed
			DebugPrint(msg)

			if(IsFinite(setPassed))
				Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) setQC = NaN
				setQC[INDEP_HEADSTAGE] = setPassed
				key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_SET_PASS)
				ED_AddEntryToLabnotebook(panelTitle, key, setQC, unit = LABNOTEBOOK_BINARY_UNIT)

				RA_SkipSweeps(panelTitle, inf, limitToSetBorder=1)
				AD_UpdateAllDatabrowser()
			endif

			break
		case POST_SET_EVENT:
			// work around XXX_SET_EVENT issues
			break
		case POST_DAQ_EVENT:

			if(s.headstage != DAP_GetHighestActiveHeadstage(panelTitle))
				return NaN
			endif

			AD_UpdateAllDatabrowser()
			break
		default:
			break
	endswitch
End
