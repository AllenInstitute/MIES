#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_PSQ
#endif

/// @file MIES_AnalysisFunctions_PatchSeq.ipf
/// @brief __PSQ__ Analysis functions for patch sequence

static Constant PSQ_BL_PRE_PULSE   = 0x0
static Constant PSQ_BL_POST_PULSE  = 0x1

static Constant PSQ_RMS_SHORT_TEST = 0x0
static Constant PSQ_RMS_LONG_TEST  = 0x1
static Constant PSQ_TARGETV_TEST   = 0x2

static StrConstant PSQ_SP_LBN_PREFIX = "Squ. Pul."
static StrConstant PSQ_ST_LBN_PREFIX = "Sub Th."

/// The Patch Seq analysis functions store various results in the labnotebook.
///
/// For orientation the following table shows their relation. All labnotebook
/// keys can and should be created via PSQ_CreateLBNKey().
///
/// \rst
///
/// ===============             ========================================================= ================= =====================  =====================
/// Naming constant             Description                                               Analysis function Per Chunk?             Headstage dependent?
/// ===============             ========================================================= ================= =====================  =====================
/// PSQ_FMT_LBN_SPIKE_DETECT    Spike was detected on the sweep                           SP                No                     Yes
/// PSQ_FMT_LBN_STEPSIZE        Current DAScale step size                                 SP                No                     Yes
/// PSQ_FMT_LBN_FINAL_SCALE     Final DAScale of the given headstage, only set on success SP                No                     No
/// PSQ_FMT_LBN_RMS_SHORT_PASS  Short RMS baseline QC result                              ST                Yes                    Yes
/// PSQ_FMT_LBN_RMS_LONG_PASS   Long RMS baseline QC result                               ST                Yes                    Yes
/// PSQ_FMT_LBN_TARGETV_PASS    Target voltage baseline QC result                         ST                Yes                    Yes
/// PSQ_FMT_LBN_CHUNK_PASS      Which chunk passed/failed baseline QC                     ST                Yes                    Yes
/// PSQ_FMT_LBN_BL_QC_PASS      Pass/fail state of the complete baseline                  ST                No                     Yes
/// PSQ_FMT_LBN_SWEEP_PASS      Pass/fail state of the complete sweep                     ST, SP            No                     No
/// PSQ_FMT_LBN_SET_PASS        Pass/fail state of the complete set                       ST                No                     No
///
/// \endrst
///
/// Query the standard "Stim Scale Factor" entry from labnotebook for getting the DAScale.

/// @brief Return labnotebook keys for patch seq analysis functions
///
/// @param type                                One of @ref PatchSeqAnalysisFunctionTypes
/// @param formatString                        One of  @ref PatchSeqLabnotebookFormatStrings
/// @param chunk [optional]                    Some format strings expect a chunk number
/// @param query [optional, defaults to false] If the key is to be used for setting or querying the labnotebook
Function/S PSQ_CreateLBNKey(type, formatString, [chunk, query])
	variable type, chunk, query
	string formatString

	string str, prefix

	switch(type)
		case PSQ_SUB_THRESHOLD:
			prefix = PSQ_ST_LBN_PREFIX
			break
		case PSQ_SQUARE_PULSE:
			prefix = PSQ_SP_LBN_PREFIX
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

/// @brief Settings structure filled by PSQ_GetPulseSettingsForType()
static Structure PSQ_PulseSettings
	variable prePulseChunkLength  // ms
	variable pulseDuration      // ms
	variable postPulseChunkLength // ms
EndStructure

/// @brief Fills `s` according to the analysis function type
static Function PSQ_GetPulseSettingsForType(type, s)
	variable type
	struct PSQ_PulseSettings &s

	switch(type)
		case PSQ_SUB_THRESHOLD:
			s.prePulseChunkLength  = PSQ_ST_BL_EVAL_RANGE_MS
			s.postPulseChunkLength = PSQ_ST_BL_EVAL_RANGE_MS
			s.pulseDuration        = PSQ_ST_PULSE_DUR
			break
		default:
			ASSERT(0, "unsupported type")
			break
	endswitch
End

/// @brief Evaluate one chunk of the baseline.
///
/// chunk == 0: Pre pulse baseline
/// chunk >= 1: Post pulse baseline
///
/// @return
/// pre pulse baseline: 0 if the chunk passes, one of the possible @ref AnalysisFuncReturnTypesConstants values otherwise
/// post pulse baseline: 0 if the chunk passes, NaN if it does not pass
static Function PSQ_EvaluateBaselineProperties(panelTitle, type, sweepNo, chunk, fifoInStimsetTime, totalOnsetDelay)
	string panelTitle
	variable type, sweepNo, chunk, fifoInStimsetTime, totalOnsetDelay

	variable , evalStartTime, evalRangeTime
	variable i, ADC, ADcol, chunkStartTime
	variable targetV, index
	variable rmsShortPassedAll, rmsLongPassedAll, chunkPassed
	variable targetVPassedAll, baselineType, chunkLengthTime
	string msg, adUnit, ctrl, key

	struct PSQ_PulseSettings s
	PSQ_GetPulseSettingsForType(type, s)

	if(chunk == 0) // pre pulse baseline
		chunkStartTime  = totalOnsetDelay
		chunkLengthTime = s.prePulseChunkLength
		baselineType    = PSQ_BL_PRE_PULSE
	else // post pulse baseline
		 // skip: onset delay, the pulse itself and one chunk of post pulse baseline
		chunkStartTime  = (totalOnsetDelay + s.prePulseChunkLength + s.pulseDuration) + chunk * s.postPulseChunkLength
		chunkLengthTime = s.postPulseChunkLength
		baselineType    = PSQ_BL_POST_PULSE
	endif

	// not enough data to evaluate
	if(fifoInStimsetTime < chunkStartTime + chunkLengthTime)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE textualValues   = GetLBTextualValues(panelTitle)

	key = PSQ_CreateLBNKey(type, PSQ_FMT_LBN_CHUNK_PASS, chunk = chunk, query = 1)
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

	testMatrix[PSQ_BL_PRE_PULSE][] = 1 // all tests
	testMatrix[PSQ_BL_POST_PULSE][PSQ_TARGETV_TEST] = 1

	WAVE OscilloscopeData = GetOscilloscopeWave(panelTitle)

	sprintf msg, "We have some data to evaluate in chunk %d [%g, %g]:  %gms\r", chunk, chunkStartTime, chunkStartTime + chunkLengthTime, fifoInStimsetTime
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

		ADC = AFH_GetADCFromHeadstage(panelTitle, i)
		ASSERT(IsFinite(ADC), "This analysis function does not work with unassociated AD channels")
		ADcol = AFH_GetITCDataColumn(config, ADC, ITC_XOP_CHANNEL_TYPE_ADC)

		ADunit = DAG_GetTextualValue(panelTitle, GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT), index = ADC)

		// assuming millivolts
		ASSERT(!cmpstr(ADunit, "mV"), "Unexpected AD Unit")

		if(testMatrix[baselineType][PSQ_RMS_SHORT_TEST])

			evalStartTime = chunkStartTime + chunkLengthTime - 1.5
			evalRangeTime = 1.5

			// check 1: RMS of the last 1.5ms of the baseline should be below 0.07mV
			rmsShort[i]       = PSQ_CalculateRMS(OscilloscopeData, ADCol, evalStartTime, evalRangeTime)
			rmsShortPassed[i] = rmsShort[i] < PSQ_RMS_SHORT_THRESHOLD

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

		if(testMatrix[baselineType][PSQ_RMS_LONG_TEST])

			evalStartTime = chunkStartTime
			evalRangeTime = chunkLengthTime

			// check 2: RMS of the last 500ms of the baseline should be below 0.50mV
			rmsLong[i]       = PSQ_CalculateRMS(OscilloscopeData, ADCol, evalStartTime, evalRangeTime)
			rmsLongPassed[i] = rmsLong[i] < PSQ_RMS_LONG_THRESHOLD

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

		if(testMatrix[baselineType][PSQ_TARGETV_TEST])

			evalStartTime = chunkStartTime
			evalRangeTime = chunkLengthTime

			// check 3: Average voltage within 1mV of auto bias target voltage
			avgVoltage[i]    = PSQ_CalculateAvg(OscilloscopeData, ADCol, evalStartTime, evalRangeTime)
			targetVPassed[i] = abs(avgVoltage[i] - targetV) <= PSQ_TARGETV_THRESHOLD

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
	key = PSQ_CreateLBNKey(type, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(panelTitle, key, rmsShortPassed, unit = "On/Off", overrideSweepNo = sweepNo)
	key = PSQ_CreateLBNKey(type, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(panelTitle, key, rmsLongPassed, unit = "On/Off", overrideSweepNo = sweepNo)
	key = PSQ_CreateLBNKey(type, PSQ_FMT_LBN_TARGETV_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(panelTitle, key, targetVPassed, unit = "On/Off", overrideSweepNo = sweepNo)

	if(testMatrix[baselineType][PSQ_RMS_SHORT_TEST])
		rmsShortPassedAll = WaveMin(rmsShortPassed) == 1
	else
		rmsShortPassedAll = -1
	endif

	if(testMatrix[baselineType][PSQ_RMS_LONG_TEST])
		rmsLongPassedAll = WaveMin(rmsLongPassed) == 1
	else
		rmsLongPassedAll = -1
	endif

	if(testMatrix[baselineType][PSQ_TARGETV_TEST])
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

	if(PSQ_TestOverrideActive())
		WAVE/SDFR=root: overrideResults
		NVAR count = $GetCount(panelTitle)
		chunkPassed = overrideResults[chunk][count][0]
		printf "Chunk %d %s\r", chunk, SelectString(chunkPassed, "failed", "passed")
	endif
	// END TEST

	// document chunk results
	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
	result[INDEP_HEADSTAGE] = chunkPassed
	key = PSQ_CreateLBNKey(type, PSQ_FMT_LBN_CHUNK_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(panelTitle, key, result, unit = "On/Off", overrideSweepNo = sweepNo)

	if(PSQ_TestOverrideActive())
		if(baselineType == PSQ_BL_PRE_PULSE)
			if(!chunkPassed)
				return ANALYSIS_FUNC_RET_EARLY_STOP
			else
				return 0
			endif
		elseif(baselineType == PSQ_BL_POST_PULSE)
			if(!chunkPassed)
				return NaN
			else
				return 0
			else
				ASSERT(0, "unknown baseline type")
			endif
		endif
	endif

	if(baselineType == PSQ_BL_PRE_PULSE)
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
	elseif(baselineType == PSQ_BL_POST_PULSE)
		if(chunkPassed)
			return 0
		else
			return NaN
		endif
	else
		ASSERT(0, "unknown baseline type")
	endif
End

/// @brief Return the number of chunks
///
/// A chunk is #PSQ_ST_BL_EVAL_RANGE_MS/#PSQ_RB_POST_BL_EVAL_RANGE/#PSQ_RB_PRE_BL_EVAL_RANGE [ms] of baseline
static Function PSQ_GetNumberOfChunks(panelTitle, type)
	string panelTitle
	variable type

	variable length, nonBL, totalOnsetDelay

	WAVE OscilloscopeData    = GetOscilloscopeWave(panelTitle)
	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	totalOnsetDelay = DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_OnsetDelayUser") \
					  + GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_OnsetDelayAuto")

	length = stopCollectionPoint * DimDelta(OscilloscopeData, ROWS)

	switch(type)
		case PSQ_SUB_THRESHOLD:
			nonBL = totalOnsetDelay + PSQ_ST_PULSE_DUR + PSQ_ST_BL_EVAL_RANGE_MS
			return floor((length - nonBL) / PSQ_ST_BL_EVAL_RANGE_MS)
			break
		default:
			ASSERT(0, "unsupported type")
	endswitch
End

// @brief Calculate the average from `startTime` spanning
//        `rangeTime` milliseconds
static Function PSQ_CalculateAvg(wv, column, startTime, rangeTime)
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
static Function PSQ_CalculateRMS(wv, column, startTime, rangeTime)
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
static Function PSQ_NumAcquiredSweepsInSet(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)

	if(!WaveExists(sweeps)) // very unlikely
		return 0
	endif

	return DimSize(sweeps, ROWS)
End

/// @brief Return the number of passed sweeps in all sweeps from the given
///        repeated acquisition cycle.
static Function PSQ_NumPassesInSet(panelTitle, type, sweepNo)
	string panelTitle
	variable type, sweepNo

	string key

	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)

	if(!WaveExists(sweeps)) // very unlikely
		return NaN
	endif

	Make/FREE/N=(DimSize(sweeps, ROWS)) passes
	key = PSQ_CreateLBNKey(type, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	passes[] = GetLastSettingIndep(numericalValues, sweeps[p], key, UNKNOWN_MODE)

	return sum(passes)
End

/// PSQ_PSQ_CreateOverrideResults("ITC18USB_DEV_0", 0, $type) where type is one of:
///
/// #PSQ_SUB_THRESHOLD:
///
/// Rows:
/// - chunk indizes: 1 if the chunk passes, 0 if not
///
/// Cols:
/// - sweeps/steps
///
/// #PSQ_SQUARE_PULSE:
///
/// Rows:
/// - x position in ms where the spike is in each sweep/step
///   For convenience the values `0` always means no spike and `1` spike detected (at the appropriate position).
///
/// #PSQ_RHEOBASE:
///
/// Rows:
/// - chunk indizes
///
/// Cols:
/// - sweeps/steps
///
/// Layers:
/// - 0: 1 if the chunk has passing baseline QC or not
/// - 1: x position in ms where the spike is in each sweep/step
///      For convenience the values `0` always means no spike and `1` spike detected (at the appropriate position).
Function/WAVE PSQ_CreateOverrideResults(panelTitle, headstage, type)
	string panelTitle
	variable headstage, type

	variable DAC, numCols, numRows, numLayers
	string stimset

	DAC = AFH_GetDACFromHeadstage(panelTitle, headstage)
	stimset = AFH_GetStimSetName(panelTitle, DAC, CHANNEL_TYPE_DAC)
	WAVE/Z wv = WB_CreateAndGetStimSet(stimset)
	ASSERT(WaveExists(wv), "Stimset does not exist")

	switch(type)
		case PSQ_SUB_THRESHOLD:
			numRows = PSQ_GetNumberOfChunks(panelTitle, type)
			numCols = IDX_NumberOfTrialsInSet(stimset)
			break
		case PSQ_SQUARE_PULSE:
			numRows = IDX_NumberOfTrialsInSet(stimset)
			numCols = 0
			break
		default:
			ASSERT(0, "invalid type")
	endswitch

	Make/D/O/N=(numRows, numCols, numLayers) root:overrideResults/Wave=overrideResults = 0

	return overrideResults
End

/// @brief Store the current step size in the labnotebook
static Function PSQ_StoreStepSizeInLBN(panelTitle, sweepNo, stepsize)
	string panelTitle
	variable sweepNo, stepsize

	string key

	Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
	values[INDEP_HEADSTAGE] = stepsize
	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_STEPSIZE)
	ED_AddEntryToLabnotebook(panelTitle, key, values, overrideSweepNo = sweepNo)
End

/// @brief Search the AD channel of the given headstage for spikes from the
/// pulse onset until the end of the sweep
///
/// @param panelTitle device
/// @param type       One of @ref PatchSeqAnalysisFunctionTypes
/// @param sweepWave  sweep wave with acquired data
/// @param headstage  headstage in the range [0, NUM_HEADSTAGES[
///
/// @return labnotebook value wave suitable for ED_AddEntryToLabnotebook()
static Function/WAVE PSQ_SearchForSpikes(panelTitle, type, sweepWave, headstage)
	string panelTitle
	variable type
	WAVE sweepWave
	variable headstage

	variable level, first, last, overrideValue

	Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) spikeDetection = 0

	WAVE singleDA = AFH_ExtractOneDimDataFromSweep(panelTitle, sweepWave, headstage, ITC_XOP_CHANNEL_TYPE_DAC)
	level = WaveMin(singleDA) + 0.1 * (WaveMax(singleDA) - WaveMin(singleDA))
	Make/FREE/D levels
	FindLevels/Q/N=2/DEST=levels singleDA, level
	ASSERT(V_LevelsFound == 2, "Could not find two levels")
	first = levels[0]
	last  = inf

	WAVE singleAD = AFH_ExtractOneDimDataFromSweep(panelTitle, sweepWave, headstage, ITC_XOP_CHANNEL_TYPE_ADC)
	ASSERT(!cmpstr(WaveUnits(singleAD, -1), "mV"), "Unexpected AD Unit")

	if(PSQ_TestOverrideActive())
		WAVE/SDFR=root: overrideResults
		NVAR count = $GetCount(panelTitle)

		switch(type)
			case PSQ_SQUARE_PULSE:
				overrideValue = overrideResults[count]
				break
			default:
				ASSERT(0, "unsupported type")
		endswitch

		printf "Sweep %d has %g\r", count, overrideValue

		if(overrideValue == 0 || overrideValue == 1)
			spikeDetection[headstage] = overrideValue
		else
			spikeDetection[headstage] = overrideValue >= first && overrideValue <= last
		endif
	else
		// search the spike from the rising edge till the end of the wave
		spikeDetection[headstage] = WaveMax(singleAD, first, last) >= PSQ_SPIKE_LEVEL
	endif

	return spikeDetection
End

/// @brief Return if the analysis function results are overriden for testing purposes
static Function PSQ_TestOverrideActive()

	WAVE/Z/SDFR=root: overrideResults

	if(WaveExists(overrideResults))
		print "TEST OVERRIDE ACTIVE"
		return 1
	endif

	return 0
End

/// @brief Patch Seq Analysis function for sub threshold stimsets
///
/// Prerequisites:
/// - This stimset must have this analysis function set for the "Pre DAQ", "Mid
///   Sweep", "Post Sweep" and "Post Set" Event
/// - A sweep passes if all tests on all headstages pass
/// - Assumes that the number of sets in all stimsets are equal
/// - Assumes that the stimset has 500ms of pre pulse baseline, a 1000ms (#PSQ_ST_PULSE_DUR) pulse and at least 1000ms post pulse baseline.
/// - Each 500ms (#PSQ_ST_BL_EVAL_RANGE_MS) of the baseline is a chunk
///
/// Testing:
/// For testing the sweep/set passing/fail logic can be defined in the wave
/// root:overrideResults. @see PSQ_CreateOverrideResults()
///
/// Reading the results from the labnotebook:
///
/// \rst
/// .. code-block:: igorpro
///
///    WAVE numericalValues = GetLBNumericalValues(panelTitle)
///
///    // set properties
///
///    key = PSQ_CreateLBNKey(PSQ_SUB_THRESHOLD, PSQ_FMT_LBN_SET_PASSED)
///    setPassed = GetLastSettingIndepRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
///
///    if(setPassed)
///      // set passed
///    else
///      // set did not pass
///    endif
///
///    // single sweep properties
///    key = PSQ_CreateLBNKey(PSQ_SUB_THRESHOLD, PSQ_FMT_LBN_SWEEP_PASS)
///    sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///
///    // chunk (500ms portions of the baseline) properties
///    key = PSQ_CreateLBNKey(PSQ_SUB_THRESHOLD, PSQ_FMT_LBN_CHUNK_PASS, chunk = chunk)
///    chunkPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///
///    // single test properties (currently not set/queryable per chunk)
///    key = PSQ_CreateLBNKey(PSQ_SUB_THRESHOLD, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = chunk)
///    rmsShortPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///    key = PSQ_CreateLBNKey(PSQ_SUB_THRESHOLD, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = chunk)
///    rmsLongPassed  = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///    key = PSQ_CreateLBNKey(PSQ_SUB_THRESHOLD, PSQ_FMT_LBN_TARGETV_PASS, chunk = chunk)
///    targetVPassed  = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///
///    // get fitted resistance from last passing sweep
///	   // resistance for the first headstage can be found in resistanceFitted[0]
///    WAVE/Z resistanceFitted = GetLastSettingRAC(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + "ResistanceFromFit", UNKNOWN_MODE)
/// \endrst
///
/// Decision logic flowchart:
///
/// \rst
///	.. graphviz:: ../patch-seq-subthreshold.dot
/// \endrst
///
/// @verbatim
///
/// Sketch of a stimset with inserted TP, pre pulse baseline (-), pulse (*), and post pulse baseline (-).
///
///  |-|                 ***********************************
///  | |                 |                                 |
///  | |                 |                      \WWW/      |
///  | |                 |                      /   \      |
///  | |                 |                     /wwwww\     |
///  | |                 |                   _|  o_o  |_   |
///  | |                 |      \WWWWWWW/   (_   / \   _)  |
///  | |                 |    _/`  o_o  `\_   |  \_/  |    |
///  | |                 |   (_    (_)    _)  : ~~~~~ :    |
///  | |                 |     \ '-...-' /     \_____/     |
///  | |                 |     (`'-----'`)     [     ]     |
///  | |                 |      `"""""""`      `"""""`     |
///  | |                 |                                 |
/// -| |-----------------|                                 |--------------------------------------------
///
/// ascii art image from: http://ascii.co.uk/art/erniebert
///
/// @endverbatim
///
Function PSQ_SubThreshold(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	variable val, totalOnsetDelay, lastFifoPos
	variable i, sweepNo, fifoInStimsetPoint, fifoInStimsetTime
	variable index, skipToEnd, ret
	variable sweepPassed, setPassed
	variable sweepsInSet, passesInSet, acquiredSweepsInSet, numBaselineChunks
	string msg, stimset, key

	// only do something if we are called for the very last headstage
	if(DAP_GetHighestActiveHeadstage(panelTitle) != headstage)
		return NaN
	endif

	// BEGIN CHANGE ME
	MAKE/D/FREE DAScales = {-30, -70, -90}
	// END CHANGE ME

	WAVE DAScalesIndex = GetAnalysisFuncIndexingHelper(panelTitle)

	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	switch(eventType)
		case PRE_DAQ_EVENT:
			DAScalesIndex[headstage] = 0

			if(!DAG_GetNumericalValue(panelTitle, "check_Settings_ITITP"))
				printf "(%s): TP during ITI must be checked\r", panelTitle
				ControlWindowToFront()
				return 1
			elseif(!DAG_GetNumericalValue(panelTitle, "check_DataAcq_AutoBias"))
				printf "(%s): Auto Bias must be checked\r", panelTitle
				ControlWindowToFront()
				return 1
			elseif(!DAG_GetNumericalValue(panelTitle, "check_Settings_MD"))
				printf "(%s): Please check \"Multi Device\" mode.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			val = DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_AutoBiasV")

			if(!IsFinite(val) || CheckIfSmall(val, tol = 1e-12))
				printf "(%s): Autobias value is zero or non-finite\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			break
		case POST_SWEEP_EVENT:
			sweepNo              = AFH_GetLastSweepAcquired(panelTitle)
			WAVE numericalValues = GetLBNumericalValues(panelTitle)
			WAVE textualValues   = GetLBTextualValues(panelTitle)

			key = PSQ_CreateLBNKey(PSQ_SUB_THRESHOLD, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
			sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
			ASSERT(IsFinite(sweepPassed), "Could not find the sweep passed labnotebook entry")

			WAVE/T stimsets = GetLastSettingText(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
			stimset = stimsets[headstage]

			sweepsInSet         = IDX_NumberOfTrialsInSet(stimset)
			passesInSet         = PSQ_NumPassesInSet(panelTitle, PSQ_SUB_THRESHOLD, sweepNo)
			acquiredSweepsInSet = PSQ_NumAcquiredSweepsInSet(panelTitle, sweepNo)

			if(!sweepPassed)
				// not enough sweeps left to pass the set
				skipToEnd = (sweepsInSet - acquiredSweepsInSet) < (PSQ_ST_NUM_SWEEPS_PASS - passesInSet)
			else
				// sweep passed

				WAVE/Z sweep = GetSweepWave(panelTitle, sweepNo)
				ASSERT(WaveExists(sweep), "Expected a sweep for evaluation")

				Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) deltaV     = NaN
				Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) deltaI     = NaN
				Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) resistance = NaN

				CalculateTPLikePropsFromSweep(numericalValues, textualValues, sweep, deltaI, deltaV, resistance)

				ED_AddEntryToLabnotebook(panelTitle, "Delta I", deltaI, unit = "I")
				ED_AddEntryToLabnotebook(panelTitle, "Delta V", deltaV, unit = "V")

				PlotResistanceGraph(panelTitle)

				if(passesInSet >= PSQ_ST_NUM_SWEEPS_PASS)
					skipToEnd = 1
				else
					// set next DAScale value
					DAScalesIndex[headstage] += 1
				endif
			endif

			sprintf msg, "Sweep %s, total sweeps %d, acquired sweeps %d, passed sweeps %d, skipToEnd %s, DAScalesIndex %d\r", SelectString(sweepPassed, "failed", "passed"), sweepsInSet, acquiredSweepsInSet, passesInSet, SelectString(skiptoEnd, "false", "true"), DAScalesIndex[headstage]
			DEBUGPRINT(msg)

			if(skiptoEnd)
				RA_SkipSweeps(panelTitle, inf)
				return NaN
			endif

			break
		case POST_SET_EVENT:
			sweepNo = AFH_GetLastSweepAcquired(panelTitle)
			setPassed = PSQ_NumPassesInSet(panelTitle, PSQ_SUB_THRESHOLD, sweepNo) >= PSQ_ST_NUM_SWEEPS_PASS

			sprintf msg, "Set has %s\r", SelectString(setPassed, "failed", "passed")
			DEBUGPRINT(msg)

			Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
			result[INDEP_HEADSTAGE] = setPassed
			key = PSQ_CreateLBNKey(PSQ_SUB_THRESHOLD, PSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(panelTitle, key, result, unit = "On/Off")

			return NaN
			break
	endswitch

	if(eventType == PRE_DAQ_EVENT || eventType == POST_SWEEP_EVENT)
		for(i = 0; i < NUM_HEADSTAGES; i += 1)
			if(!statusHS[i])
				continue
			endif

			index = DAScalesIndex[i]

			// index equals the number of sweeps in the stimset on the last call (*post* sweep event)
			if(index > DimSize(DAScales, ROWS))
				printf "(%s): The stimset has too many sweeps, increase the size of DAScales.\r", GetRTStackInfo(1)
				continue
			elseif(index < DimSize(DAScales, ROWS))
				SetDAScale(panelTitle, i, DAScales[index] * 1e-12)
			endif
		endfor
	endif

	if(eventType != MID_SWEEP_EVENT)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	// we can't use AFH_GetLastSweepAcquired as the sweep is not yet acquired
	sweepNo = DAG_GetNumericalValue(panelTitle, "SetVar_Sweep")
	key = PSQ_CreateLBNKey(PSQ_SUB_THRESHOLD, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE, defValue = 0)

	if(sweepPassed) // already done
		return NaN
	endif

	// oscilloscope data holds scaled data already
	WAVE OscilloscopeData = GetOscilloscopeWave(panelTitle)
	lastFifoPos = GetNumberFromWaveNote(OscilloscopeData, "lastFifoPos") - 1

	totalOnsetDelay = DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_OnsetDelayUser") \
					  + GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_OnsetDelayAuto")

	fifoInStimsetPoint = lastFifoPos - totalOnsetDelay / DimDelta(OscilloscopeData, ROWS)
	fifoInStimsetTime  = fifoInStimsetPoint * DimDelta(OscilloscopeData, ROWS)

	numBaselineChunks = PSQ_GetNumberOfChunks(panelTitle, PSQ_SUB_THRESHOLD)

	for(i = 0; i < numBaselineChunks; i += 1)

		ret = PSQ_EvaluateBaselineProperties(panelTitle, PSQ_SUB_THRESHOLD, sweepNo, i, fifoInStimsetTime, totalOnsetDelay)

		if(IsNaN(ret))
			// NaN: not enough data for check
			//
			// not last chunk: retry on next invocation
			// last chunk: mark sweep as failed
			if(i == numBaselineChunks - 1)
				ret = 1
				break
			else
				return NaN
			endif
		elseif(ret)
			// != 0: failed with special mid sweep return value (on first failure)
			if(i == 0)
				// pre pulse baseline
				// fail sweep
				break
			else
				// post pulse baseline
				// try next chunk
				continue
			endif
		else
			// 0: passed
			if(i == 0)
				// pre pulse baseline
				// try next chunks
				continue
			else
				// post baseline
				// we're done!
				break
			endif
		endif
	endfor

	sweepPassed = (ret == 0)

	sprintf msg, "Sweep %s, last evaluated chunk %d returned with %g\r", SelectString(sweepPassed, "failed", "passed"), i, ret
	DEBUGPRINT(msg)

	// document sweep results
	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
	result[INDEP_HEADSTAGE] = sweepPassed

	key = PSQ_CreateLBNKey(PSQ_SUB_THRESHOLD, PSQ_FMT_LBN_SWEEP_PASS)
	ED_AddEntryToLabnotebook(panelTitle, key, result, unit = "On/Off", overrideSweepNo = sweepNo)

	return sweepPassed ? ANALYSIS_FUNC_RET_EARLY_STOP : ret
End

/// @brief Analysis function to find the smallest DAScale where the cell spikes
///
/// Prerequisites:
/// - This stimset must have this analysis function set for the "Pre DAQ" and "Post Sweep" Event
/// - Does only work for one headstage
/// - Assumes that the stimset has a pulse
///
/// Testing:
/// For testing the spike detection logic, the results can be defined in the wave
/// root:overrideResults. @see PSQ_CreateOverrideResults()
///
/// Decision logic flowchart:
///
/// \rst
///	.. graphviz:: ../patch-seq-squarepulse.dot
/// \endrst
///
/// @verbatim
///
/// Sketch of a stimset with pre pulse baseline (-), pulse (*), and post pulse baseline (-).
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
Function PSQ_SquarePulse(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	variable sweepNo, stepsize, DAScale
	variable offset, first, last, level, overrideValue
	string key

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE textualValues   = GetLBTextualValues(panelTitle)

	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	ASSERT(sum(statusHS) == 1, "Analysis function only supports one headstage")

	switch(eventType)
		case PRE_DAQ_EVENT:
			if(!GetCheckBoxState(panelTitle, "check_Settings_MD"))
				printf "(%s): Please check \"Multi Device\" mode.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			PGC_SetAndActivateControl(panelTitle, "check_Settings_ITITP", val = 0)
			PGC_SetAndActivateControl(panelTitle, "Check_Settings_InsertTP", val = 0)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq_Get_Set_ITI", val = 1)

			if(DAG_GetHeadstageMode(panelTitle, headstage) != I_CLAMP_MODE)
				printf "(%s) Clamp mode must be current clamp.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			sweepNo = GetSetVariable(panelTitle, "SetVar_Sweep")
			PSQ_StoreStepSizeInLBN(panelTitle, sweepNo, PSQ_SP_INIT_AMP_p100)
			SetDAScale(panelTitle, headstage, PSQ_SP_INIT_AMP_p100)

			return 0

			break
		case POST_SWEEP_EVENT:

			sweepNo = AFH_GetLastSweepAcquired(panelTitle)
			WAVE sweepWave = GetSweepWave(panelTitle, sweepNo)
			WAVE spikeDetection = PSQ_SearchForSpikes(panelTitle, PSQ_SQUARE_PULSE, sweepWave, headstage)
			key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DETECT)
			ED_AddEntryToLabnotebook(panelTitle, key, spikeDetection)

			key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_STEPSIZE, query = 1)
			stepSize = GetLastSettingIndepRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
			DAScale  = GetLastSetting(numericalValues, sweepNo, "Stim Scale Factor", DATA_ACQUISITION_MODE)[headstage] * 1e-12

			if(spikeDetection[headstage]) // headstage spiked
				if(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_m50))
					SetDAScale(panelTitle, headstage, DAScale + stepsize)
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_p10))
					Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) value = 0
					value[INDEP_HEADSTAGE] = DAScale
					key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE)
					ED_AddEntryToLabnotebook(panelTitle, key, value)
					RA_SkipSweeps(panelTitle, inf)
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_p100))
					PSQ_StoreStepSizeInLBN(panelTitle, sweepNo, PSQ_SP_INIT_AMP_m50)
					stepsize = PSQ_SP_INIT_AMP_m50
					SetDAScale(panelTitle, headstage, DAScale + stepsize)
				else
					ASSERT(0, "Unknown stepsize")
				endif
			else // headstage did not spike
				if(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_m50))
					PSQ_StoreStepSizeInLBN(panelTitle, sweepNo, PSQ_SP_INIT_AMP_p10)
					stepsize = PSQ_SP_INIT_AMP_p10
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_p10))
					// do nothing
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_p100))
					// do nothing
				else
					ASSERT(0, "Unknown stepsize")
				endif

				SetDAScale(panelTitle, headstage, DAScale + stepsize)
			endif

			break
	endswitch

	return NaN
End
