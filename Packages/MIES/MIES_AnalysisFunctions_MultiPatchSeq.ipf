#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_MSQ
#endif

/// @file MIES_AnalysisFunctions_MultiPatchSeq.ipf
/// @brief __MSQ__ Analysis functions for multi patch sequence
///
/// The Multi Patch Seq analysis functions store various results in the labnotebook.
///
/// For orientation the following table shows their relation. All labnotebook
/// keys can and should be created via MSQ_CreateLBNKey().
///
/// \rst
///
/// =========================== ========================================================= ================= ===================== =====================
/// Naming constant             Description                                               Analysis function Per Chunk?            Headstage dependent?
/// =========================== ========================================================= ================= ===================== =====================
/// MSQ_FMT_LBN_SPIKE_DETECT    The required number of spikes were detected on the sweep  FRE               No                    Yes
/// MSQ_FMT_LBN_STEPSIZE        Current DAScale step size                                 FRE               No                    Yes
/// MSQ_FMT_LBN_FINAL_SCALE     Final DAScale of the given headstage, only set on success FRE               No                    Yes
/// MSQ_FMT_LBN_HEADSTAGE_PASS  Pass/fail state of the headstage                          FRE, DS           No                    Yes
/// MSQ_FMT_LBN_SWEEP_PASS      Pass/fail state of the complete sweep                     FRE, DS           No                    No
/// MSQ_FMT_LBN_SET_PASS        Pass/fail state of the complete set                       FRE, DS           No                    No
/// MSQ_FMT_LBN_ACTIVE_HS       Active headstages in pre DAQ event                        FRE, DS           No                    Yes
/// MSQ_FMT_LBN_DASCALE_EXC     Allowed DAScale exceeded given limit                      FRE               No                    Yes
/// MSQ_FMT_LBN_PULSE_DUR       Square pulse duration in ms                               FRE               No                    Yes
/// =========================== ========================================================= ================= ===================== =====================
///
/// \endrst
///
/// Query the standard STIMSET_SCALE_FACTOR_KEY entry from labnotebook for getting the DAScale.

static Constant MSQ_BL_PRE_PULSE   = 0x0
static Constant MSQ_BL_POST_PULSE  = 0x1

static Constant MSQ_RMS_SHORT_TEST = 0x0
static Constant MSQ_RMS_LONG_TEST  = 0x1
static Constant MSQ_TARGETV_TEST   = 0x2

static StrConstant MSQ_FRE_LBN_PREFIX = "F Rheo E"
static StrConstant MSQ_DS_LBN_PREFIX  = "Da Scale"

/// @brief Return labnotebook keys for patch seq analysis functions
///
/// @param type         One of @ref MultiPatchSeqAnalysisFunctionTypes
/// @param formatString One of  @ref MultiPatchSeqLabnotebookFormatStrings
/// @param chunk        [optional] Some format strings expect a chunk number
/// @param query        [optional, defaults to false] If the key is to be used for setting or querying the labnotebook
Function/S MSQ_CreateLBNKey(type, formatString, [chunk, query])
	variable type, chunk, query
	string formatString

	string str, prefix

	switch(type)
		case MSQ_FAST_RHEO_EST:
			prefix = MSQ_FRE_LBN_PREFIX
			break
		case MSQ_DA_SCALE:
			prefix = MSQ_DS_LBN_PREFIX
			break
		default:
			ASSERT(0, "unsupported type")
			break
	endswitch

	if(ParamIsDefault(chunk))
		sprintf str, formatString, prefix
	else
		sprintf str, formatString, prefix, chunk
	endif

	if(ParamIsDefault(query))
		query = 0
	else
		query = !!query
	endif

	if(query)
		return LABNOTEBOOK_USER_PREFIX + str
	else
		return str
	endif
End

/// @brief Settings structure filled by MSQ_GetPulseSettingsForType()
static Structure MSQ_PulseSettings
	variable prePulseChunkLength  // ms
	variable pulseDuration      // ms
	variable postPulseChunkLength // ms
EndStructure

/// @brief Fills `s` according to the analysis function type
static Function MSQ_GetPulseSettingsForType(type, s)
	variable type
	struct MSQ_PulseSettings &s

	string msg

	switch(type)
		default:
			ASSERT(0, "unsupported type")
			break
	endswitch

	sprintf msg, "postPulseChunkLength %d, prePulseChunkLength %d, pulseDuration %g", s.postPulseChunkLength, s.prePulseChunkLength, s.pulseDuration
	DEBUGPRINT(msg)
End

/// Return the pulse durations from the labnotebook or calculate them before if required.
/// For convenience unused headstages will have 0 instead of NaN in the returned wave.
static Function/WAVE MSQ_GetPulseDurations(panelTitle, type, sweepNo, totalOnsetDelay, headstage, [useSCI, forceRecalculation])
	string panelTitle
	variable type, sweepNo, totalOnsetDelay, headstage, useSCI, forceRecalculation

	string key

	if(ParamIsDefault(forceRecalculation))
		forceRecalculation = 0
	else
		forceRecalculation = !!forceRecalculation
	endif

	if(ParamIsDefault(useSCI))
		useSCI = 0
	else
		useSCI = !!useSCI
	endif

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	key = MSQ_CreateLBNKey(type, MSQ_FMT_LBN_PULSE_DUR, query = 1)

	if(useSCI)
		WAVE/Z durations = GetLastSettingSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	else
		WAVE/Z durations = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
	endif

	if(!WaveExists(durations) || forceRecalculation)
		WAVE durations = MSQ_DeterminePulseDuration(panelTitle, sweepNo, totalOnsetDelay)

		key = MSQ_CreateLBNKey(type, MSQ_FMT_LBN_PULSE_DUR)
		ED_AddEntryToLabnotebook(panelTitle, key, durations, unit = "ms", overrideSweepNo = sweepNo)
	endif

	durations[] = IsNaN(durations[p]) ? 0 : durations[p]

	return durations
End

/// @brief Determine the pulse duration on each headstage
///
/// Returns the labnotebook wave as well.
static Function/WAVE MSQ_DeterminePulseDuration(panelTitle, sweepNo, totalOnsetDelay)
	string panelTitle
	variable sweepNo, totalOnsetDelay

	variable i, level, first, last, duration
	string key

	WAVE/Z sweepWave = GetSweepWave(panelTitle, sweepNo)

	if(!WaveExists(sweepWave))
		WAVE sweepWave = GetHardwareDataWave(panelTitle)
		WAVE config    = GetITCChanConfigWave(panelTitle)
	else
		WAVE config = GetConfigWave(sweepWave)
	endif

	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	MAKE/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) durations = NaN

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		WAVE singleDA = AFH_ExtractOneDimDataFromSweep(panelTitle, sweepWave, i, ITC_XOP_CHANNEL_TYPE_DAC, config = config)
		level = WaveMin(singleDA, totalOnsetDelay, inf) + GetMachineEpsilon(WaveType(singleDA))

		FindLevel/Q/R=(totalOnsetDelay, inf)/EDGE=1 singleDA, level
		ASSERT(!V_Flag, "Could not find a rising edge")
		first = V_LevelX

		FindLevel/Q/R=(totalOnsetDelay, inf)/EDGE=2 singleDA, level
		ASSERT(!V_Flag, "Could not find a falling edge")
		last = V_LevelX

		if(level > 0)
			duration = last - first - DimDelta(singleDA, ROWS)
		else
			duration = first - last + DimDelta(singleDA, ROWS)
		endif

		ASSERT(duration > 0, "Duration must be strictly positive")

		durations[i] = duration
	endfor

	return durations
End

/// @brief Evaluate one chunk of the baseline.
///
/// chunk == 0: Pre pulse baseline
/// chunk >= 1: Post pulse baseline
/// chunk >= 1: Post pulse baseline
///
/// @return
/// pre pulse baseline: 0 if the chunk passes, one of the possible @ref AnalysisFuncReturnTypesConstants values otherwise
/// post pulse baseline: 0 if the chunk passes, NaN if it does not pass
static Function MSQ_EvaluateBaselineProperties(panelTitle, type, sweepNo, chunk, fifoInStimsetTime, totalOnsetDelay)
	string panelTitle
	variable type, sweepNo, chunk, fifoInStimsetTime, totalOnsetDelay

	variable , evalStartTime, evalRangeTime
	variable i, ADC, ADcol, chunkStartTimeMax, chunkStartTime
	variable targetV, index
	variable rmsShortPassedAll, rmsLongPassedAll, chunkPassed
	variable targetVPassedAll, baselineType, chunkLengthTime
	string msg, adUnit, ctrl, key

	struct MSQ_PulseSettings s
	MSQ_GetPulseSettingsForType(type, s)

	if(chunk == 0) // pre pulse baseline
		chunkStartTimeMax  = totalOnsetDelay
		chunkLengthTime    = s.prePulseChunkLength
		baselineType       = MSQ_BL_PRE_PULSE
	else // post pulse baseline
		 Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) durations = s.pulseDuration

		 // skip: onset delay, the pulse itself and one chunk of post pulse baseline
		chunkStartTimeMax = (totalOnsetDelay + s.prePulseChunkLength + WaveMax(durations)) + chunk * s.postPulseChunkLength
		chunkLengthTime   = s.postPulseChunkLength
		baselineType      = MSQ_BL_POST_PULSE
	endif

	// not enough data to evaluate
	if(fifoInStimsetTime < chunkStartTimeMax + chunkLengthTime)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE textualValues   = GetLBTextualValues(panelTitle)

	key = MSQ_CreateLBNKey(type, MSQ_FMT_LBN_CHUNK_PASS, chunk = chunk, query = 1)
	chunkPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE, defValue = NaN)

	if(IsFinite(chunkPassed)) // already evaluated
		return !chunkPassed
	endif

	// Rows: baseline types
	// - 0: pre pulse
	// - 1: post pulse
	//
	// Cols: checks
	// - 0: short RMS
	// - 1: long RMS
	// - 2: average voltage
	//
	// Contents:
	//  0: skip test
	//  1: perform test
	Make/FREE/N=(2, 3) testMatrix

	testMatrix[MSQ_BL_PRE_PULSE][] = 1 // all tests
	testMatrix[MSQ_BL_POST_PULSE][MSQ_TARGETV_TEST] = 1

	WAVE OscilloscopeData = GetOscilloscopeWave(panelTitle)

	sprintf msg, "We have some data to evaluate in chunk %d [%g, %g]:  %gms\r", chunk, chunkStartTimeMax, chunkStartTimeMax + chunkLengthTime, fifoInStimsetTime
	DEBUGPRINT(msg)

	WAVE config = GetITCChanConfigWave(panelTitle)

	Make/FREE/N = (LABNOTEBOOK_LAYER_COUNT) rmsShort       = NaN
	Make/FREE/N = (LABNOTEBOOK_LAYER_COUNT) rmsShortPassed = NaN
	Make/FREE/N = (LABNOTEBOOK_LAYER_COUNT) rmsLong        = NaN
	Make/FREE/N = (LABNOTEBOOK_LAYER_COUNT) rmsLongPassed  = NaN
	Make/FREE/N = (LABNOTEBOOK_LAYER_COUNT) avgVoltage     = NaN
	Make/FREE/N = (LABNOTEBOOK_LAYER_COUNT) targetVPassed  = NaN

	targetV = DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_AutoBiasV")

	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		if(chunk == 0) // pre pulse baseline
			chunkStartTime = totalOnsetDelay
		else
			ASSERT(durations[i] != 0, "Invalid calculated durations")
			chunkStartTime = (totalOnsetDelay + s.prePulseChunkLength + durations[i]) + chunk * s.postPulseChunkLength
		endif

		ADC = AFH_GetADCFromHeadstage(panelTitle, i)
		ASSERT(IsFinite(ADC), "This analysis function does not work with unassociated AD channels")
		ADcol = AFH_GetITCDataColumn(config, ADC, ITC_XOP_CHANNEL_TYPE_ADC)

		ADunit = DAG_GetTextualValue(panelTitle, GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT), index = ADC)

		// assuming millivolts
		ASSERT(!cmpstr(ADunit, "mV"), "Unexpected AD Unit")

		if(testMatrix[baselineType][MSQ_RMS_SHORT_TEST])

			evalStartTime = chunkStartTime + chunkLengthTime - 1.5
			evalRangeTime = 1.5

			// check 1: RMS of the last 1.5ms of the baseline should be below 0.07mV
			rmsShort[i]       = MSQ_CalculateRMS(OscilloscopeData, ADCol, evalStartTime, evalRangeTime)
			rmsShortPassed[i] = rmsShort[i] < MSQ_RMS_SHORT_THRESHOLD

			sprintf msg, "RMS noise short: %g (%s)\r", rmsShort[i], SelectString(rmsShortPassed[i], "failed", "passed")
			DEBUGPRINT(msg)
		else
			sprintf msg, "RMS noise short: (%s)\r", "skipped"
			DEBUGPRINT(msg)
			rmsShortPassed[i] = -1
		endif

		if(!rmsShortPassed[i])
			continue
		endif

		if(testMatrix[baselineType][MSQ_RMS_LONG_TEST])

			evalStartTime = chunkStartTime
			evalRangeTime = chunkLengthTime

			// check 2: RMS of the last 500ms of the baseline should be below 0.50mV
			rmsLong[i]       = MSQ_CalculateRMS(OscilloscopeData, ADCol, evalStartTime, evalRangeTime)
			rmsLongPassed[i] = rmsLong[i] < MSQ_RMS_LONG_THRESHOLD

			sprintf msg, "RMS noise long: %g (%s)", rmsLong[i], SelectString(rmsLongPassed[i], "failed", "passed")
			DEBUGPRINT(msg)
		else
			sprintf msg, "RMS noise long: (%s)\r", "skipped"
			DEBUGPRINT(msg)
			rmsLongPassed[i] = -1
		endif

		if(!rmsLongPassed[i])
			continue
		endif

		if(testMatrix[baselineType][MSQ_TARGETV_TEST])

			evalStartTime = chunkStartTime
			evalRangeTime = chunkLengthTime

			// check 3: Average voltage within 1mV of auto bias target voltage
			avgVoltage[i]    = MSQ_CalculateAvg(OscilloscopeData, ADCol, evalStartTime, evalRangeTime)
			targetVPassed[i] = abs(avgVoltage[i] - targetV) <= MSQ_TARGETV_THRESHOLD

			sprintf msg, "Average voltage of %gms: %g (%s)", evalRangeTime, avgVoltage[i], SelectString(targetVPassed[i], "failed", "passed")
			DEBUGPRINT(msg)
		else
			sprintf msg, "Average voltage of %gms: (%s)\r", evalRangeTime, "skipped"
			DEBUGPRINT(msg)
			targetVPassed[i] = -1
		endif

		if(!targetVPassed[i])
			continue
		endif

		// more tests can be added here
	endfor

	// document results per headstage and chunk
	key = MSQ_CreateLBNKey(type, MSQ_FMT_LBN_RMS_SHORT_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(panelTitle, key, rmsShortPassed, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)
	key = MSQ_CreateLBNKey(type, MSQ_FMT_LBN_RMS_LONG_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(panelTitle, key, rmsLongPassed, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)
	key = MSQ_CreateLBNKey(type, MSQ_FMT_LBN_TARGETV_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(panelTitle, key, targetVPassed, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)

	if(testMatrix[baselineType][MSQ_RMS_SHORT_TEST])
		rmsShortPassedAll = WaveMin(rmsShortPassed) == 1
	else
		rmsShortPassedAll = -1
	endif

	if(testMatrix[baselineType][MSQ_RMS_LONG_TEST])
		rmsLongPassedAll = WaveMin(rmsLongPassed) == 1
	else
		rmsLongPassedAll = -1
	endif

	if(testMatrix[baselineType][MSQ_TARGETV_TEST])
		targetVPassedAll = WaveMin(targetVPassed) == 1
	else
		targetVPassedAll = -1
	endif

	if(rmsShortPassedAll == -1 && rmsLongPassedAll == - 1 && targetVPassedAll == -1)
		print "All tests were skipped??"
		ControlWindowToFront()
		return NaN
	endif

	chunkPassed = rmsShortPassedAll && rmsLongPassedAll && targetVPassedAll

	// BEGIN TEST
	if(MSQ_TestOverrideActive())
		WAVE/SDFR=root: overrideResults
		NVAR count = $GetCount(panelTitle)
		chunkPassed = overrideResults[chunk][count][0]
	endif
	// END TEST

	sprintf msg, "Chunk %d %s", chunk, SelectString(chunkPassed, "failed", "passed")
	DEBUGPRINT(msg)

	// document chunk results
	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
	result[INDEP_HEADSTAGE] = chunkPassed
	key = MSQ_CreateLBNKey(type, MSQ_FMT_LBN_CHUNK_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(panelTitle, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)

	if(MSQ_TestOverrideActive())
		if(baselineType == MSQ_BL_PRE_PULSE)
			if(!chunkPassed)
				return ANALYSIS_FUNC_RET_EARLY_STOP
			else
				return 0
			endif
		elseif(baselineType == MSQ_BL_POST_PULSE)
			if(!chunkPassed)
				return NaN
			else
				return 0
			else
				ASSERT(0, "unknown baseline type")
			endif
		endif
	endif

	if(baselineType == MSQ_BL_PRE_PULSE)
		if(!rmsShortPassedAll)
			return ANALYSIS_FUNC_RET_EARLY_STOP
		elseif(!rmsLongPassedAll)
			return ANALYSIS_FUNC_RET_EARLY_STOP
		elseif(!targetVPassedAll)
			NVAR repurposedTime = $GetRepurposedSweepTime(panelTitle)
			repurposedTime = 10
			return ANALYSIS_FUNC_RET_REPURP_TIME
		else
			ASSERT(chunkPassed, "logic error")
		endif
	elseif(baselineType == MSQ_BL_POST_PULSE)
		if(chunkPassed)
			return 0
		else
			return NaN
		endif
	else
		ASSERT(0, "unknown baseline type")
	endif
End

// @brief Calculate the average from `startTime` spanning
//        `rangeTime` milliseconds
static Function MSQ_CalculateAvg(wv, column, startTime, rangeTime)
	WAVE wv
	variable column, startTime, rangeTime

	variable rangePoints, startPoints

	startPoints = startTime / DimDelta(wv, ROWS)
	rangePoints = rangeTime / DimDelta(wv, ROWS)

	MatrixOP/FREE data = subWaveC(wv, startPoints, column, rangePoints)
	MatrixOP/FREE avg  = mean(data)

	ASSERT(IsFinite(avg[0]), "result must be finite")

	return avg[0]
End

// @brief Calculate the RMS minus the average from `startTime` spanning
//        `rangeTime` milliseconds
//
// @note: This differs from what WaveStats returns in `V_sdev` as we divide by
//        `N` but WaveStats by `N -1`.
static Function MSQ_CalculateRMS(wv, column, startTime, rangeTime)
	WAVE wv
	variable column, startTime, rangeTime

	variable rangePoints, startPoints

	startPoints = startTime / DimDelta(wv, ROWS)
	rangePoints = rangeTime / DimDelta(wv, ROWS)

	MatrixOP/FREE data = subWaveC(wv, startPoints, column, rangePoints)
	MatrixOP/FREE avg  = mean(data)
	MatrixOP/FREE rms  = sqrt(sumSqr(data - avg[0]) / numRows(data))

	ASSERT(IsFinite(rms[0]), "result must be finite")

	return rms[0]
End

/// @brief Return the number of already acquired sweeps from the given
///        repeated acquisition cycle.
static Function MSQ_NumAcquiredSweepsInSet(panelTitle, sweepNo, headstage)
	string panelTitle
	variable sweepNo, headstage

	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)

	if(!WaveExists(sweeps)) // very unlikely
		return 0
	endif

	return DimSize(sweeps, ROWS)
End

/// @brief Return the number of passed sweeps in all sweeps from the given
///        repeated acquisition cycle.
Function MSQ_NumPassesInSet(numericalValues, type, sweepNo, headstage)
	WAVE numericalValues
	variable type, sweepNo, headstage

	string key

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)

	if(!WaveExists(sweeps)) // very unlikely
		return NaN
	endif

	Make/FREE/N=(DimSize(sweeps, ROWS)) passes
	key = MSQ_CreateLBNKey(type, MSQ_FMT_LBN_SWEEP_PASS, query = 1)
	passes[] = GetLastSettingIndep(numericalValues, sweeps[p], key, UNKNOWN_MODE)

	return sum(passes)
End

/// @brief Return the DA stimset length in ms of the given headstage
///
/// @return stimset length or -1 on error
static Function MSQ_GetDAStimsetLength(panelTitle, headstage)
	string panelTitle
	variable headstage

	string setName
	variable DAC

	DAC = AFH_GetDACFromHeadstage(panelTitle, headstage)
	setName = AFH_GetStimSetName(panelTitle, DAC, CHANNEL_TYPE_DAC)

	WAVE/Z stimset = WB_CreateAndGetStimSet(setName)
	if(!WaveExists(stimset))
		return -1
	endif

	return DimSize(stimset, ROWS) * DimDelta(stimset, ROWS)
End

/// MSQ_PSQ_CreateOverrideResults("ITC18USB_DEV_0", 0, $type) where type is one of:
///
/// #MSQ_FAST_RHEO_EST
///
/// Rows:
/// - x position in ms where the spike is in each sweep/step
///   For convenience the values `0` always means no spike and `1` spike detected (at the appropriate position).
///
/// Cols:
/// - IC headstages
///
Function/WAVE MSQ_CreateOverrideResults(panelTitle, headstage, type)
	string panelTitle
	variable headstage, type

	variable DAC, numCols, numRows, numLayers
	string stimset

	DAC = AFH_GetDACFromHeadstage(panelTitle, headstage)

	stimset = AFH_GetStimSetName(panelTitle, DAC, CHANNEL_TYPE_DAC)
	WAVE/Z wv = WB_CreateAndGetStimSet(stimset)
	ASSERT(WaveExists(wv), "Stimset does not exist")

	switch(type)
		case MSQ_FAST_RHEO_EST:
			numRows = IDX_NumberOfSweepsInSet(stimset)
			numCols = Sum(MSQ_GetActiveHeadstages(panelTitle, I_CLAMP_MODE))
			numLayers = 0
		case MSQ_DA_SCALE:
			// nothing to set
			break
		default:
			ASSERT(0, "invalid type")
	endswitch

	Make/D/O/N=(numRows, numCols, numLayers) root:overrideResults/Wave=overrideResults = 0

	return overrideResults
End

/// @brief Search the AD channel of the given headstage for spikes from the
/// pulse onset until the end of the sweep
///
/// @param[in]  panelTitle      device
/// @param[in]  type            One of @ref PatchSeqAnalysisFunctionTypes
/// @param[in]  sweepWave       sweep wave with acquired data
/// @param[in]  headstage       headstage in the range [0, NUM_HEADSTAGES[
/// @param[in]  totalOnsetDelay total delay in ms until the stimset data starts
/// @param[in]  numberOfSpikes  [optional, defaults to one] number of spikes to look for
/// @param[out] spikePositions  [optional] returns the position of the first `numberOfSpikes` found on success in ms
/// @param[in]  defaultValue    [optiona, defaults to `NaN`] the value of the other headstages in the returned wave
///
/// @return labnotebook value wave suitable for ED_AddEntryToLabnotebook()
static Function/WAVE MSQ_SearchForSpikes(panelTitle, type, sweepWave, headstage, totalOnsetDelay, [numberOfSpikes, defaultValue, spikePositions])
	string panelTitle
	variable type
	WAVE sweepWave
	variable headstage, totalOnsetDelay
	variable numberOfSpikes, defaultValue
	WAVE spikePositions

	variable level, first, last, overrideValue
	variable minVal, maxVal
	string msg

	if(WaveRefsEqual(sweepWave, GetHardwareDataWave(panelTitle)))
		WAVE config = GetITCChanConfigWave(panelTitle)
	else
		WAVE config = GetConfigWave(sweepWave)
	endif

	if(ParamIsDefault(numberOfSpikes))
		numberOfSpikes = 1
	else
		numberOfSpikes = trunc(numberOfSpikes)
	endif

	if(ParamIsDefault(defaultValue))
		defaultValue = NaN
	endif

	Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) spikeDetection = (p == headstage ? 0 : defaultValue)

	sprintf msg, "Type %d, headstage %d, totalOnsetDelay %g, numberOfSpikes %d", type, headstage, totalOnsetDelay, numberOfSpikes
	DEBUGPRINT(msg)

	WAVE singleDA = AFH_ExtractOneDimDataFromSweep(panelTitle, sweepWave, headstage, ITC_XOP_CHANNEL_TYPE_DAC, config = config)
	minVal = WaveMin(singleDA, totalOnsetDelay, inf)
	maxVal = WaveMax(singleDA, totalOnsetDelay, inf)

	if(minVal == 0 && maxVal == 0)
		return spikeDetection
	endif

	level = minVal + GetMachineEpsilon(WaveType(singleDA))

	Make/FREE/D levels
	FindLevels/R=(totalOnsetDelay, inf)/Q/N=2/DEST=levels singleDA, level
	ASSERT(V_LevelsFound == 2, "Could not find two levels")
	first = levels[0]
	last  = inf

	WAVE singleAD = AFH_ExtractOneDimDataFromSweep(panelTitle, sweepWave, headstage, ITC_XOP_CHANNEL_TYPE_ADC, config = config)
	ASSERT(!cmpstr(WaveUnits(singleAD, -1), "mV"), "Unexpected AD Unit")

	if(MSQ_TestOverrideActive())
		WAVE/SDFR=root: overrideResults
		NVAR count = $GetCount(panelTitle)

		switch(type)
			case MSQ_FAST_RHEO_EST:
				overrideValue = overrideResults[count][headstage]
				break
			default:
				ASSERT(0, "unsupported type")
		endswitch

		if(overrideValue == 0 || overrideValue == 1)
			spikeDetection[headstage] = overrideValue
		else
			spikeDetection[headstage] = overrideValue >= first && overrideValue <= last
		endif

		if(!ParamIsDefault(spikePositions))
			ASSERT(WaveExists(spikePositions), "Wave spikePositions must exist")
			Redimension/D/N=(numberOfSpikes) spikePositions
			spikePositions[] = overrideValue
		endif
	else
		// scale with SWS_GetChannelGains(panelTitle) when called during mid sweep event
		level = MSQ_SPIKE_LEVEL

		if(numberOfSpikes == 1)
			// search the spike from the rising edge till the end of the wave
			FindLevel/Q/R=(first, last) singleAD, level
			spikeDetection[headstage] = !V_flag

			if(!ParamIsDefault(spikePositions))
				ASSERT(WaveExists(spikePositions), "Wave spikePositions must exist")
				Redimension/D/N=(numberOfSpikes) spikePositions
				spikePositions[0] = V_LevelX
			endif
		elseif(numberOfSpikes > 1)
			Make/D/FREE/N=0 crossings
			FindLevels/Q/R=(first, last)/N=(numberOfSpikes)/DEST=crossings/EDGE=1 singleAD, level
			spikeDetection[headstage] = !V_flag

			if(!ParamIsDefault(spikePositions))
				ASSERT(WaveExists(spikePositions), "Wave spikePositions must exist")
				Redimension/D/N=(V_LevelsFound) spikePositions

				if(!V_flag && V_LevelsFound > 0)
					spikePositions[] = crossings[p]
				endif
			endif
		else
			ASSERT(0, "Invalid number of spikes value")
		endif
	endif

	ASSERT(IsFinite(spikeDetection[headstage]), "Expected finite result")

	return DEBUGPRINTw(spikeDetection)
End

/// @brief Return if the analysis function results are overriden for testing purposes
static Function MSQ_TestOverrideActive()

	variable numberOfOverrideWarnings

	WAVE/Z/SDFR=root: overrideResults

	if(WaveExists(overrideResults))
		numberOfOverrideWarnings = GetNumberFromWaveNote(overrideResults, "OverrideWarningIssued")
		if(IsNaN(numberOfOverrideWarnings))
			print "TEST OVERRIDE ACTIVE"
			SetNumberInWaveNote(overrideResults, "OverrideWarningIssued", 1)
		endif
		return 1
	endif

	return 0
End

/// @brief Return a wave with `NUM_HEADSTAGES` rows with `1` where
///        the given headstages is active and in the given clamp mode.
static Function/WAVE MSQ_GetActiveHeadstages(panelTitle, clampMode)
	string panelTitle
	variable clampMode

	AI_AssertOnInvalidClampMode(clampMode)

	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	Make/FREE/N=(NUM_HEADSTAGES) status = statusHS[p] && DAG_GetHeadstageMode(panelTitle, p) == clampMode

	return status
End

/// @brief Return true if one of the entries is true for the given headstage. False otherwise.
///        Searches in the complete SCI and assumes that the entries are either 0/1/NaN.
///
/// @todo merge with LBN functions once these are reworked.
static Function MSQ_GetLBNEntryForHSSCIBool(numericalValues, sweepNo, type, str, headstage)
	WAVE numericalValues
	variable sweepNo, type
	string str
	variable headstage

	string key

	key = MSQ_CreateLBNKey(type, str, query = 1)
	WAVE/Z values = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(!WaveExists(values))
		return 0
	endif

	WaveTransform/O zapNaNs, values

	if(DimSize(values, ROWS) == 0)
		return 0
	endif

	return Sum(values) >= 1
End

/// @brief Return the last entry for a given headstage from the full SCI.
///
/// This differs from GetLastSettingSCI as specifically the setting for the
/// passed headstage must be valid.
///
/// @todo merge with LBN functions once these are reworked.
static Function MSQ_GetLBNEntryForHeadstageSCI(numericalValues, sweepNo, type, str, headstage)
	WAVE numericalValues
	variable sweepNo, type
	string str
	variable headstage

	string key
	variable numEntries

	key = MSQ_CreateLBNKey(type, str, query = 1)
	WAVE/Z values = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(!WaveExists(values))
		return NaN
	endif

	WaveTransform/O zapNaNs, values

	numEntries = DimSize(values, ROWS)

	if(numEntries == 0)
		return NaN
	endif

	return values[numEntries - 1]
End

/// @brief Return a list of required parameters for MSQ_FastRheoEst()
///
/// \rst
///
/// =========================== ========= ====================================================================
/// Name                        Type      Description
/// =========================== ========= ====================================================================
/// SamplingMultiplier          variable  Sampling multiplier, use 1 for no multiplier
/// MaximumDAScale              variable  Maximum allowed DAScale, set to NaN to turn the check off [pA]
/// PostDAQDAScaleForFailedHS   variable  Failed headstages will be set to this DAScale value [pA]
///                                       in the post set event
/// PostDAQDAScale              variable  If true the found DAScale value will be set at the end of the set
/// PostDAQDAScaleFactor        variable  Scaling factor for setting the DAScale of passed headstages
///                                       at the end of the set
/// PostDAQDAScaleMinOffset     variable  Mininum absolute offset value applied to the found DAScale [pA]
/// =========================== ========= ====================================================================
///
/// \endrst
Function/S MSQ_FastRheoEst_GetParams()
	return "SamplingMultiplier:variable,"        + \
		   "PostDAQDAScaleForFailedHS:variable," + \
		   "PostDAQDAScaleMinOffset:variable,"   + \
		   "PostDAQDAScale:variable,"            + \
		   "PostDAQDAScaleFactor:variable,"      + \
		   "MaximumDAScale:variable"
End

/// @brief Analysis function to find the smallest DAScale where the cell spikes
///
/// Prerequisites:
/// - Assumes that the stimset has a square pulse
///
/// Testing:
/// For testing the spike detection logic, the results can be defined in the wave
/// root:overrideResults. @see MSQ_CreateOverrideResults()
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: ../multi-patch-seq-fast-rheo-estimate.dot.svg
/// \endrst
///
/// @verbatim
///
/// Sketch of a stimset with pre pulse baseline (-), square pulse (*), and post pulse baseline (-).
///
///    *******
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
/// ---|     |--------------------------------------------
///
/// @endverbatim
Function MSQ_FastRheoEst(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3 &s

	variable totalOnsetDelay, setPassed, sweepPassed, multiplier, newDAScaleValue, found, val
	variable i, postDAQDAScale, postDAQDAScaleFactor, DAC, maxDAScale, allHeadstagesExceeded, minRheoOffset
	string key, msg, ctrl
	string stimsets = ""

	switch(s.eventType)
		case PRE_DAQ_EVENT:

			if(s.headstage != DAP_GetHighestActiveHeadstage(panelTitle))
				break
			endif

			PGC_SetAndActivateControl(panelTitle, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_RepeatAcq", val = 1)

			WAVE statusTTL = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			if(Sum(MSQ_GetActiveHeadstages(panelTitle, I_CLAMP_MODE)) == 0)
				printf "(%s) At least one active headstage must have IC clamp mode.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)

			if(!IsValidSamplingMultiplier(multiplier))
				printf "(%s): The sampling multiplier of %g passed as analysis parameter is invalid.\r", panelTitle, multiplier
				ControlWindowToFront()
				return 1
			endif

			PGC_SetAndActivateControl(panelTitle, "Popup_Settings_SampIntMult", str = num2str(multiplier))

			DisableControls(panelTitle, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")

			// fallthrough-by-design
		case PRE_SET_EVENT:

			if(s.headstage != DAP_GetHighestActiveHeadstage(panelTitle))
				break
			endif

			WAVE statusHSIC = MSQ_GetActiveHeadstages(panelTitle, I_CLAMP_MODE)

			for(i = 0; i < NUM_HEADSTAGES; i += 1)

				if(!statusHSIC[i])
					continue
				endif

				DAC = AFH_GetDACFromHeadstage(panelTitle, i)
				ASSERT(IsFinite(DAC), "Unexpected unassociated DAC")
				stimsets = AddListItem(AFH_GetStimSetName(panelTitle, DAC, CHANNEL_TYPE_DAC), stimsets, ";", inf)
			endfor

			if(ItemsInList(GetUniqueTextEntriesFromList(stimsets)) > 1)
				printf "(%s): Not all IC headstages have the same stimset.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			minRheoOffset = AFH_GetAnalysisParamNumerical("PostDAQDAScaleMinOffset", s.params)

			if(!(minRheoOffset >= 0))
				printf "(%s): Analysis parameter \"PostDAQDAScaleMinOffset\" must be zero or positive.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			WAVE statusHSIC = MSQ_GetActiveHeadstages(panelTitle, I_CLAMP_MODE)

			for(i = 0; i < NUM_HEADSTAGES; i += 1)

				if(!statusHSIC[i])
					continue
				endif

				SetDAScale(panelTitle, i, MSQ_FRE_INIT_AMP_p100)
			endfor

			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(panelTitle, "Check_Settings_InsertTP", val = 0)
			PGC_SetAndActivateControl(panelTitle, "SetVar_DataAcq_ITI", val = 0.1)
			PGC_SetAndActivateControl(panelTitle, "check_Settings_ITITP", val = 0)
			PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_OnsetDelayUser", val = 0)
			PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_TerminationDelay", val = 0)

			Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
			values[0, NUM_HEADSTAGES - 1] = statusHSIC[p] ? MSQ_FRE_INIT_AMP_p100 : NaN
			key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_STEPSIZE)
			ED_AddEntryToLabnotebook(panelTitle, key, values, overrideSweepNo = s.sweepNo)

			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
			values[0, NUM_HEADSTAGES - 1] = statusHSIC[p] ? 0 : NaN
			key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_DASCALE_EXC)
			ED_AddEntryToLabnotebook(panelTitle, key, values, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			if(s.eventType == PRE_DAQ_EVENT)
				WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

				key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_ACTIVE_HS)
				Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
				values[0, NUM_HEADSTAGES - 1] = statusHS[p]
				ED_AddEntryToLabnotebook(panelTitle, key, values, overrideSweepNo = s.sweepNo)

				for(i = 0; i < NUM_HEADSTAGES; i += 1)
					if(statusHS[i] && !statusHSIC[i]) // active non-IC headstage
						ctrl = GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
						PGC_SetAndActivateControl(panelTitle, ctrl, val=CHECKBOX_UNSELECTED)
					endif
				endfor
			endif

			return 0

			break
		case POST_SWEEP_EVENT:

			if(s.headstage != DAP_GetHighestActiveHeadstage(panelTitle))
				break
			endif

			WAVE sweepWave = GetSweepWave(panelTitle, s.sweepNo)
			WAVE numericalValues = GetLBNumericalValues(panelTitle)

			totalOnsetDelay = GetTotalOnsetDelay(numericalValues, s.sweepNo)

			MSQ_GetPulseDurations(panelTitle, MSQ_FAST_RHEO_EST, s.sweepNo, totalOnsetDelay, s.headstage, useSCI = 1)

			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) spikeDetection   = NaN
			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) headstagePassed  = NaN
			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) finalDAScale     = NaN
			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) rangeExceededNew = NaN

			key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_STEPSIZE, query = 1)
			WAVE stepSize = GetLastSettingSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
			WAVE DAScale = GetLastSetting(numericalValues, s.sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
			DAScale[] *= 1e-12

			totalOnsetDelay = GetTotalOnsetDelay(numericalValues, s.sweepNo)
			WAVE statusHSIC = MSQ_GetActiveHeadstages(panelTitle, I_CLAMP_MODE)

			for(i = 0; i < NUM_HEADSTAGES; i += 1)

				if(!statusHSIC[i])
					continue
				endif

				found = MSQ_GetLBNEntryForHSSCIBool(numericalValues, s.sweepNo, MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_DASCALE_EXC, i)
				if(found)
					continue
				endif

				found = MSQ_GetLBNEntryForHSSCIBool(numericalValues, s.sweepNo, MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_HEADSTAGE_PASS, i)
				if(found)
					stepSize[i] = NaN
					continue
				endif

				spikeDetection[i] = MSQ_SearchForSpikes(panelTitle, MSQ_FAST_RHEO_EST, sweepWave, i, totalOnsetDelay)[i]

				ASSERT(IsFinite(stepSize[i]), "Unexpected step size value")
				ASSERT(IsFinite(DaScale[i]), "Unexpected DAScale value")

				headstagePassed[i] = 0
				newDAScaleValue = NaN

				if(spikeDetection[i])
					if(CheckIfClose(stepSize[i], MSQ_FRE_INIT_AMP_m50))
						newDAScaleValue = DAScale[i] + stepSize[i]
					elseif(CheckIfClose(stepSize[i], MSQ_FRE_INIT_AMP_p10))
						finalDAScale[i] = DAScale[i]
						headstagePassed[i] = 1
						newDAScaleValue = 0
					elseif(CheckIfClose(stepSize[i], MSQ_FRE_INIT_AMP_p100))
						stepSize[i] = MSQ_FRE_INIT_AMP_m50
						newDAScaleValue = DAScale[i] + stepSize[i]
					else
						ASSERT(0, "Unknown stepsize")
					endif
				else // headstage did not spike
					if(CheckIfClose(stepSize[i], MSQ_FRE_INIT_AMP_m50))
						stepSize[i] = MSQ_FRE_INIT_AMP_p10
						newDAScaleValue = DAScale[i] + stepSize[i]
					elseif(CheckIfClose(stepSize[i], MSQ_FRE_INIT_AMP_p10))
						newDAScaleValue = DAScale[i] + stepSize[i]
					elseif(CheckIfClose(stepSize[i], MSQ_FRE_INIT_AMP_p100))
						newDAScaleValue = DAScale[i] + stepSize[i]
					else
						ASSERT(0, "Unknown stepsize")
					endif
				endif

				sprintf msg, "Headstage %d: spikeDetection %g, stepSize %g, DAScale %g: Has %s\r", i, spikeDetection[i], stepSize[i], DAScale[i], ToPassFail(headstagePassed[i])
				DEBUGPRINT(msg)

				ASSERT(IsFinite(newDAScaleValue), "Unexpected newDAScaleValue")

				maxDAScale = AFH_GetAnalysisParamNumerical("MaximumDAScale", s.params) * 1e-12

				if(IsFinite(maxDAScale) && newDAScaleValue > maxDAScale)
					rangeExceededNew[i] = 1
					ASSERT(headstagePassed[i] != 1, "Unexpected headstage passing")
					headstagePassed[i] = 0
				else
					SetDAScale(panelTitle, i, newDAScaleValue)
				endif
			endfor

			key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_SPIKE_DETECT)
			ED_AddEntryToLabnotebook(panelTitle, key, spikeDetection, unit = LABNOTEBOOK_BINARY_UNIT)

			key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_HEADSTAGE_PASS)
			ED_AddEntryToLabnotebook(panelTitle, key, headstagePassed, unit = LABNOTEBOOK_BINARY_UNIT)

			if(HasOneValidEntry(finalDAScale))
				key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_FINAL_SCALE)
				ED_AddEntryToLabnotebook(panelTitle, key, finalDAScale)
			endif

			if(HasOneValidEntry(rangeExceededNew))
				key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_DASCALE_EXC)
				ED_AddEntryToLabnotebook(panelTitle, key, rangeExceededNew, unit = LABNOTEBOOK_BINARY_UNIT)
			endif

			key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_STEPSIZE)
			ED_AddEntryToLabnotebook(panelTitle, key, stepSize)

			Make/D/FREE/N=(NUM_HEADSTAGES) totalRangeExceeded = 0
			sweepPassed = 1

			for(i = 0; i < NUM_HEADSTAGES; i += 1)

				if(!statusHSIC[i])
					continue
				endif

				totalRangeExceeded[i] = MSQ_GetLBNEntryForHSSCIBool(numericalValues, s.sweepNo, MSQ_FAST_RHEO_EST,\
																	   MSQ_FMT_LBN_DASCALE_EXC, i)

				sweepPassed = sweepPassed && MSQ_GetLBNEntryForHSSCIBool(numericalValues, s.sweepNo, MSQ_FAST_RHEO_EST,\
																	   MSQ_FMT_LBN_HEADSTAGE_PASS, i)
			endfor

			allHeadstagesExceeded = Sum(totalRangeExceeded) == Sum(statusHSIC)

			Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) value = NaN
			ASSERT((sweepPassed && !allHeadstagesExceeded) || !sweepPassed, "Invalid sweepPassed and allHeadstagesExceeded combination.")
			value[INDEP_HEADSTAGE] = sweepPassed
			key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(panelTitle, key, value, unit = LABNOTEBOOK_BINARY_UNIT)

			if(sweepPassed || allHeadstagesExceeded)
				MSQ_ForceSetEvent(panelTitle, s.headstage)
				RA_SkipSweeps(panelTitle, inf, limitToSetBorder = 1)
			endif

			sprintf msg, "Sweep has %s\r", ToPassFail(sweepPassed)
			DEBUGPRINT(msg)

			break
		case POST_SET_EVENT:

			if(s.headstage != DAP_GetHighestActiveHeadstage(panelTitle))
				break
			endif

			PGC_SetAndActivateControl(panelTitle, "check_Settings_ITITP", val = 1)
			PGC_SetAndActivateControl(panelTitle, "Check_Settings_InsertTP", val = 1)

			WAVE numericalValues = GetLBNumericalValues(panelTitle)
			// assuming that all headstages have the same sweeps in their SCI
			setPassed = MSQ_NumPassesInSet(numericalValues, MSQ_FAST_RHEO_EST, s.sweepNo, s.headstage) >= 1

			sprintf msg, "Set has %s\r", ToPassFail(setPassed)
			DEBUGPRINT(msg)

			Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
			result[INDEP_HEADSTAGE] = setPassed
			key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(panelTitle, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			postDAQDAScale = AFH_GetAnalysisParamNumerical("PostDAQDAScale", s.params)

			if(!postDAQDAScale)
				break
			endif

			postDAQDAScaleFactor = AFH_GetAnalysisParamNumerical("PostDAQDAScaleFactor", s.params)

			minRheoOffset = AFH_GetAnalysisParamNumerical("PostDAQDAScaleMinOffset", s.params)

			key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_FINAL_SCALE, query = 1)
			WAVE statusHSIC = MSQ_GetActiveHeadstages(panelTitle, I_CLAMP_MODE)

			for(i = 0; i < NUM_HEADSTAGES; i += 1)

				if(!statusHSIC[i])
					continue
				endif

				WAVE/Z finalDAScale = GetLastSettingEachSCI(numericalValues, s.sweepNo, key, i, UNKNOWN_MODE)
				if(WaveExists(finalDAScale))
					WaveTransform/O zapNans, finalDAScale
					ASSERT(DimSize(finalDAScale, ROWS) == 1, "Unexpected finalDAScale")
					val = max(postDAQDAScaleFactor * finalDAScale[0], minRheoOffset * 1e-12 + finalDAScale[0])
				else
					val = AFH_GetAnalysisParamNumerical("PostDAQDAScaleForFailedHS", s.params) * 1e-12
					ASSERT(IsFinite(val), "PostDAQDAScaleForFailedHS is not finite.")
				endif

				SetDAScale(panelTitle, i, val)
			endfor

			// @todo add support in dashboard
			// AD_UpdateAllDatabrowser()

			break
		case POST_DAQ_EVENT:

			if(s.headstage != DAP_GetHighestActiveHeadstage(panelTitle))
				break
			endif

			WAVE numericalValues = GetLBNumericalValues(panelTitle)

			EnableControls(panelTitle, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")

			WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

			key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_ACTIVE_HS, query = 1)

			WAVE/Z previousActiveHS = GetLastSettingSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			if(WaveExists(previousActiveHS))
				for(i = 0; i < NUM_HEADSTAGES; i += 1)
					if(previousActiveHS[i] && !statusHS[i])
						ctrl = GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
						PGC_SetAndActivateControl(panelTitle, ctrl, val=CHECKBOX_SELECTED)
					endif
				endfor
			endif

			// @todo add support in dashboard
			// AD_UpdateAllDatabrowser()

			break
		default:
			// do nothing
			break
	endswitch

	return NaN
End

/// @brief Map from analysis function name to numeric constant
///
/// @return One of @ref MultiPatchSeqAnalysisFunctionTypes
Function MSQ_MapFunctionToConstant(anaFunc)
	string anaFunc

	strswitch(anaFunc)
		case "MSQ_FastRheoEst":
			return MSQ_FAST_RHEO_EST
		case "MSQ_DAScale":
			return MSQ_DA_SCALE
		default:
			return NaN
	endswitch
End

/// @brief Return the DAScale offset [pA] for MSQ_DaScale()
///
/// @return wave with #LABNOTEBOOK_LAYER_COUNT entries, each holding the final DA Scale entry
///         from the previous fast rheo estimate run.
static Function/WAVE MSQ_DS_GetDAScaleOffset(panelTitle, headstage)
	string panelTitle
	variable headstage

	variable sweepNo, i

	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN

	if(MSQ_TestOverrideActive())
		values[] = MSQ_DS_OFFSETSCALE_FAKE
		return values
	endif

	sweepNo = MSQ_GetLastPassingLongRHSweep(panelTitle, headstage)
	if(!IsValidSweepNumber(sweepNo))
		return values
	endif

	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	values[0, NUM_HEADSTAGES - 1] = MSQ_GetLBNEntryForHeadstageSCI(numericalValues, sweepNo, MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_FINAL_SCALE, p) * 1e12

	return values
End

/// @brief Return a sweep number of an existing sweep matching the following conditions
///
/// - Acquired with Rheobase analysis function
/// - Sweep set was passing
/// - Pulse duration was longer than 500ms
///
/// And as usual we want the *last* matching sweep.
///
/// @return existing sweep number or -1 in case no such sweep could be found
static Function MSQ_GetLastPassingLongRHSweep(panelTitle, headstage)
	string panelTitle
	variable headstage

	string key
	variable i, numEntries, sweepNo, sweepCol

	if(MSQ_TestOverrideActive())
		return MSQ_DS_SWEEP_FAKE
	endif

	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	// rheobase sweeps passing
	key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_SET_PASS, query = 1)
	WAVE/Z sweeps = GetSweepsWithSetting(numericalValues, key)

	if(!WaveExists(sweeps))
		return -1
	endif

	// pulse duration
	key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_PULSE_DUR, query = 1)

	numEntries = DimSize(sweeps, ROWS)
	for(i = numEntries - 1; i >= 0; i -= 1)
		sweepNo = sweeps[i]
		WAVE/Z setting = GetLastSettingSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

		if(WaveExists(setting) && setting[headstage] > 500)
			return sweepNo
		endif
	endfor

	return -1
End

/// @brief Require parameters from stimset
///
/// - DAScales (Numeric wave): DA Scale Factors in pA
Function/S MSQ_DAScale_GetParams()
	return "DAScales:wave"
End

/// @brief Analysis function to apply a list of DAScale values to a range of sweeps
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: ../multi-patch-seq-dascale.dot.svg
/// \endrst
///
Function MSQ_DAScale(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3 &s

	variable i, index, ret, headstagePassed, val, sweepNo
	string msg, key, ctrl

	WAVE DAScales = AFH_GetAnalysisParamWave("DAScales", s.params)

	WAVE DAScalesIndex = GetAnalysisFuncIndexingHelper(panelTitle)

	if(s.headstage != DAP_GetHighestActiveHeadstage(panelTitle))
		return NaN
	endif

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			PGC_SetAndActivateControl(panelTitle, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_RepeatAcq", val = 1)

			PGC_SetAndActivateControl(panelTitle, "Popup_Settings_SampIntMult", str = "1")

			WAVE statusTTL = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)
			WAVE statusHSIC = MSQ_GetActiveHeadstages(panelTitle, I_CLAMP_MODE)

			key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_ACTIVE_HS)
			Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
			values[0, NUM_HEADSTAGES - 1] = statusHS[p]
			ED_AddEntryToLabnotebook(panelTitle, key, values, overrideSweepNo = s.sweepNo)

			WAVE numericalValues = GetLBNumericalValues(panelTitle)

			for(i = 0; i < NUM_HEADSTAGES; i += 1)

				if(MSQ_TestOverrideActive())
					headstagePassed = 1
				else
					headstagePassed = MSQ_GetLBNEntryForHSSCIBool(numericalValues, sweepNo, MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_HEADSTAGE_PASS, i)
				endif

				if(statusHS[i] && (!statusHSIC[i] || !headstagePassed)) // active non-IC headstage or not passing in FastRheoEstimate
					ctrl = GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
					PGC_SetAndActivateControl(panelTitle, ctrl, val=CHECKBOX_UNSELECTED)
				endif
			endfor

			if(Sum(MSQ_GetActiveHeadstages(panelTitle, I_CLAMP_MODE)) == 0)
				printf "(%s) At least one active headstage must have IC clamp mode.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			DisableControls(panelTitle, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			break
		case PRE_SET_EVENT:

			DAScalesIndex[] = 0

			WAVE daScaleOffset = MSQ_DS_GetDAScaleOffset(panelTitle, s.headstage)
			if(!HasOneValidEntry(daScaleOffset))
				printf "(%s): Could not find a valid DAScale threshold value from previous rheobase runs with long pulses.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			val = DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_AutoBiasV")

			if(!IsFinite(val) || CheckIfSmall(val, tol = 1e-12))
				printf "(%s): Autobias value is zero or non-finite\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			PGC_SetAndActivateControl(panelTitle, "check_DataAcq_AutoBias", val = 1)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_DistribDaq", val = 1)
			PGC_SetAndActivateControl(panelTitle, "check_Settings_ITITP", val = 1)
			PGC_SetAndActivateControl(panelTitle, "Check_Settings_InsertTP", val = 1)

			break
		case POST_SWEEP_EVENT:

			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
			WAVE statusHSIC = MSQ_GetActiveHeadstages(panelTitle, I_CLAMP_MODE)
			values[0, NUM_HEADSTAGES - 1] = statusHSIC[p] ? 1 : NaN
			key = MSQ_CreateLBNKey(MSQ_DA_SCALE, MSQ_FMT_LBN_HEADSTAGE_PASS)
			ED_AddEntryToLabnotebook(panelTitle, key, values, unit = LABNOTEBOOK_BINARY_UNIT)

			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
			values[INDEP_HEADSTAGE] = 1
			key = MSQ_CreateLBNKey(MSQ_DA_SCALE, MSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(panelTitle, key, values, unit = LABNOTEBOOK_BINARY_UNIT)

			break
		case POST_SET_EVENT:

			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
			values[INDEP_HEADSTAGE] = 1
			key = MSQ_CreateLBNKey(MSQ_DA_SCALE, MSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(panelTitle, key, values, unit = LABNOTEBOOK_BINARY_UNIT)

			/// @todo support
			/// AD_UpdateAllDatabrowser()
			break
		case POST_DAQ_EVENT:
			WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

			WAVE numericalValues = GetLBNumericalValues(panelTitle)

			key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_ACTIVE_HS, query = 1)
			WAVE/Z previousActiveHS = GetLastSettingSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			if(WaveExists(previousActiveHS))
				for(i = 0; i < NUM_HEADSTAGES; i += 1)
					if(previousActiveHS[i] && !statusHS[i])
						ctrl = GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
						PGC_SetAndActivateControl(panelTitle, ctrl, val=CHECKBOX_SELECTED)
					endif
				endfor
			endif

			/// @todo support
			/// AD_UpdateAllDatabrowser()
			EnableControls(panelTitle, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			break
		default:
			break
	endswitch

	if(s.eventType == PRE_SET_EVENT || s.eventType == POST_SWEEP_EVENT)
		WAVE daScaleOffset = MSQ_DS_GetDAScaleOffset(panelTitle, s.headstage)

		WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

		for(i = 0; i < NUM_HEADSTAGES; i += 1)
			if(!statusHS[i])
				continue
			endif

			index = mod(DAScalesIndex[i], DimSize(DAScales, ROWS))

			ASSERT(isFinite(daScaleOffset[i]), "DAScale offset is non-finite")
			SetDAScale(panelTitle, i, (DAScales[index] + daScaleOffset[i]) * 1e-12)
			DAScalesIndex[i] += 1
		endfor
	endif
End

/// @brief Manually force the pre/post set events
///
/// Required to do before skipping sweeps.
/// @todo this hack must go away.
static Function MSQ_ForceSetEvent(panelTitle, headstage)
	string panelTitle
	variable headstage

	variable DAC

	WAVE setEventFlag = GetSetEventFlag(panelTitle)
	DAC = AFH_GetDACFromHeadstage(panelTitle, headstage)

	setEventFlag[DAC][%PRE_SET_EVENT]  = 1
	setEventFlag[DAC][%POST_SET_EVENT] = 1
End
