#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_PSQ
#endif

/// @file MIES_AnalysisFunctions_PatchSeq.ipf
/// @brief __PSQ__ Analysis functions for patch sequence
///
/// The Patch Seq analysis functions store various results in the labnotebook.
///
/// For orientation the following table shows their relation. All labnotebook
/// keys can and should be created via PSQ_CreateLBNKey().
///
/// \rst
///
/// =========================== ========================================================= ================= =====================  =====================
/// Naming constant             Description                                               Analysis function Per Chunk?             Headstage dependent?
/// =========================== ========================================================= ================= =====================  =====================
/// PSQ_FMT_LBN_SPIKE_DETECT    The required number of spikes were detected on the sweep  SP, RB, RA        No                     Yes
/// PSQ_FMT_LBN_SPIKE_POSITIONS Spike positions in ms                                     RA                No                     Yes
/// PSQ_FMT_LBN_STEPSIZE        Current DAScale step size                                 SP                No                     Yes
/// PSQ_FMT_LBN_RB_DASCALE_EXC  Range for valid DAScale values is exceedd                 RB                No                     Yes
/// PSQ_FMT_LBN_FINAL_SCALE     Final DAScale of the given headstage, only set on success SP, RB            No                     No
/// PSQ_FMT_LBN_INITIAL_SCALE   Initial DAScale                                           RB                No                     No
/// PSQ_FMT_LBN_RMS_SHORT_PASS  Short RMS baseline QC result                              DA, RB, RA        Yes                    Yes
/// PSQ_FMT_LBN_RMS_LONG_PASS   Long RMS baseline QC result                               DA, RB, RA        Yes                    Yes
/// PSQ_FMT_LBN_TARGETV_PASS    Target voltage baseline QC result                         DA, RB, RA        Yes                    Yes
/// PSQ_FMT_LBN_CHUNK_PASS      Which chunk passed/failed baseline QC                     DA, RB, RA        Yes                    Yes
/// PSQ_FMT_LBN_BL_QC_PASS      Pass/fail state of the complete baseline                  DA, RB, RA        No                     Yes
/// PSQ_FMT_LBN_SWEEP_PASS      Pass/fail state of the complete sweep                     DA, SP, RA        No                     No
/// PSQ_FMT_LBN_SET_PASS        Pass/fail state of the complete set                       DA, RB, RA, SP    No                     No
/// PSQ_FMT_LBN_PULSE_DUR       Pulse duration as determined experimentally               RB                No                     Yes
/// =========================== ========================================================= ================= =====================  =====================
///
/// \endrst
///
/// Query the standard STIMSET_SCALE_FACTOR_KEY entry from labnotebook for getting the DAScale.

static Constant PSQ_BL_PRE_PULSE   = 0x0
static Constant PSQ_BL_POST_PULSE  = 0x1

static Constant PSQ_RMS_SHORT_TEST = 0x0
static Constant PSQ_RMS_LONG_TEST  = 0x1
static Constant PSQ_TARGETV_TEST   = 0x2

static StrConstant PSQ_SP_LBN_PREFIX = "Squ. Pul."
static StrConstant PSQ_DS_LBN_PREFIX = "DA Scale"
static StrConstant PSQ_RB_LBN_PREFIX = "Rheobase"
static StrConstant PSQ_RA_LBN_PREFIX = "Ramp"

static Constant PSQ_DEFAULT_SAMPLING_MULTIPLIER = 4

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
		case PSQ_DA_SCALE:
			prefix = PSQ_DS_LBN_PREFIX
			break
		case PSQ_RHEOBASE:
			prefix = PSQ_RB_LBN_PREFIX
			break
		case PSQ_SQUARE_PULSE:
			prefix = PSQ_SP_LBN_PREFIX
			break
		case PSQ_RAMP:
			prefix = PSQ_RA_LBN_PREFIX
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

	string msg

	switch(type)
		case PSQ_DA_SCALE:
			s.prePulseChunkLength  = PSQ_DS_BL_EVAL_RANGE_MS
			s.postPulseChunkLength = PSQ_DS_BL_EVAL_RANGE_MS
			s.pulseDuration        = PSQ_DS_PULSE_DUR
			break
		case PSQ_RHEOBASE:
			s.prePulseChunkLength  = PSQ_RB_PRE_BL_EVAL_RANGE
			s.postPulseChunkLength = PSQ_RB_POST_BL_EVAL_RANGE
			s.pulseDuration        = NaN
			break
		case PSQ_RAMP:
			s.prePulseChunkLength  = PSQ_RA_BL_EVAL_RANGE
			s.postPulseChunkLength = PSQ_RA_BL_EVAL_RANGE
			s.pulseDuration        = NaN
			break
		default:
			ASSERT(0, "unsupported type")
			break
	endswitch

	sprintf msg, "postPulseChunkLength %d, prePulseChunkLength %d, pulseDuration %g", s.postPulseChunkLength, s.prePulseChunkLength, s.pulseDuration
	DEBUGPRINT(msg)
End

/// Return the pulse durations from the labnotebook or calculate them before if required.
/// For convenience unused headstages will have 0 instead of NaN in the returned wave.
static Function/WAVE PSQ_GetPulseDurations(panelTitle, type, sweepNo, totalOnsetDelay, [forceRecalculation])
	string panelTitle
	variable type, sweepNo, totalOnsetDelay, forceRecalculation

	string key

	if(ParamIsDefault(forceRecalculation))
		forceRecalculation = 0
	else
		forceRecalculation = !!forceRecalculation
	endif

	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	key = PSQ_CreateLBNKey(type, PSQ_FMT_LBN_PULSE_DUR, query = 1)
	WAVE/Z durations = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

	if(!WaveExists(durations) || forceRecalculation)
		WAVE durations = PSQ_DeterminePulseDuration(panelTitle, sweepNo, totalOnsetDelay)

		key = PSQ_CreateLBNKey(type, PSQ_FMT_LBN_PULSE_DUR)
		ED_AddEntryToLabnotebook(panelTitle, key, durations, unit = "ms", overrideSweepNo = sweepNo)
	endif

	durations[] = IsNaN(durations[p]) ? 0 : durations[p]

	return durations
End

/// @brief Determine the pulse duration on each headstage
///
/// Returns the labnotebook wave as well.
static Function/WAVE PSQ_DeterminePulseDuration(panelTitle, sweepNo, totalOnsetDelay)
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

/// @brief Evaluate one chunk of the baseline
///
/// @param panelTitle        device
/// @param type              analysis function type, one of @ref PatchSeqAnalysisFunctionTypes
/// @param sweepNo           sweep number
/// @param chunk             chunk number, `chunk == 0` -> Pre pulse baseline chunk, `chunk >= 1` -> Post pulse baseline
/// @param fifoInStimsetTime Fifo position in ms *relative* to the start of the stimset (therefore ignoring the totalOnsetDelay)
/// @param totalOnsetDelay   total onset delay in ms
///
/// @return
/// pre pulse baseline: 0 if the chunk passes, one of the possible @ref AnalysisFuncReturnTypesConstants values otherwise
/// post pulse baseline: 0 if the chunk passes, NaN if it does not pass
static Function PSQ_EvaluateBaselineProperties(panelTitle, type, sweepNo, chunk, fifoInStimsetTime, totalOnsetDelay)
	string panelTitle
	variable type, sweepNo, chunk, fifoInStimsetTime, totalOnsetDelay

	variable , evalStartTime, evalRangeTime
	variable i, ADC, ADcol, chunkStartTimeMax, chunkStartTime
	variable targetV, index
	variable rmsShortPassedAll, rmsLongPassedAll, chunkPassed
	variable targetVPassedAll, baselineType, chunkLengthTime
	string msg, adUnit, ctrl, key

	struct PSQ_PulseSettings s
	PSQ_GetPulseSettingsForType(type, s)

	if(chunk == 0) // pre pulse baseline
		chunkStartTimeMax  = totalOnsetDelay
		chunkLengthTime    = s.prePulseChunkLength
		baselineType       = PSQ_BL_PRE_PULSE
	else // post pulse baseline
		 if(type == PSQ_RHEOBASE || type == PSQ_RAMP)
			 WAVE durations = PSQ_GetPulseDurations(panelTitle, type, sweepNo, totalOnsetDelay)
		 else
			 Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) durations = s.pulseDuration
		 endif

		 // skip: onset delay, the pulse itself and one chunk of post pulse baseline
		chunkStartTimeMax = (totalOnsetDelay + s.prePulseChunkLength + WaveMax(durations)) + chunk * s.postPulseChunkLength
		chunkLengthTime   = s.postPulseChunkLength
		baselineType      = PSQ_BL_POST_PULSE
	endif

	// not enough data to evaluate
	if(fifoInStimsetTime + totalOnsetDelay < chunkStartTimeMax + chunkLengthTime)
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

	sprintf msg, "We have some data to evaluate in chunk %d [%g, %g]:  %gms\r", chunk, chunkStartTimeMax, chunkStartTimeMax + chunkLengthTime, fifoInStimsetTime + totalOnsetDelay
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
	ED_AddEntryToLabnotebook(panelTitle, key, rmsShortPassed, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)
	key = PSQ_CreateLBNKey(type, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(panelTitle, key, rmsLongPassed, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)
	key = PSQ_CreateLBNKey(type, PSQ_FMT_LBN_TARGETV_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(panelTitle, key, targetVPassed, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)

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
	endif
	// END TEST

	sprintf msg, "Chunk %d %s", chunk, SelectString(chunkPassed, "failed", "passed")
	DEBUGPRINT(msg)

	// document chunk results
	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
	result[INDEP_HEADSTAGE] = chunkPassed
	key = PSQ_CreateLBNKey(type, PSQ_FMT_LBN_CHUNK_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(panelTitle, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)

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
/// A chunk is #PSQ_DS_BL_EVAL_RANGE_MS/#PSQ_RB_POST_BL_EVAL_RANGE/#PSQ_RB_PRE_BL_EVAL_RANGE/#PSQ_RA_BL_EVAL_RANGE [ms] of baseline
static Function PSQ_GetNumberOfChunks(panelTitle, sweepNo, headstage, type)
	string panelTitle
	variable type, sweepNo, headstage

	variable length, nonBL, totalOnsetDelay

	WAVE OscilloscopeData    = GetOscilloscopeWave(panelTitle)
	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	totalOnsetDelay = DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_OnsetDelayUser") \
					  + GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_OnsetDelayAuto")

	length = stopCollectionPoint * DimDelta(OscilloscopeData, ROWS)

	switch(type)
		case PSQ_DA_SCALE:
			nonBL = totalOnsetDelay + PSQ_DS_PULSE_DUR + PSQ_DS_BL_EVAL_RANGE_MS
			return DEBUGPRINTv(floor((length - nonBL) / PSQ_DS_BL_EVAL_RANGE_MS))
			break
		case PSQ_RHEOBASE:
			WAVE durations = PSQ_GetPulseDurations(panelTitle, PSQ_RHEOBASE, sweepNo, totalOnsetDelay)
			ASSERT(durations[headstage] != 0, "Pulse duration can not be zero")
			nonBL = totalOnsetDelay + durations[headstage] + PSQ_RB_POST_BL_EVAL_RANGE
			return DEBUGPRINTv(floor((length - nonBL - PSQ_RB_PRE_BL_EVAL_RANGE) / PSQ_RB_POST_BL_EVAL_RANGE) + 1)
			break
		case PSQ_RAMP:
			WAVE durations = PSQ_GetPulseDurations(panelTitle, PSQ_RAMP, sweepNo, totalOnsetDelay)
			ASSERT(durations[headstage] != 0, "Pulse duration can not be zero")
			nonBL = totalOnsetDelay + durations[headstage] + PSQ_RA_BL_EVAL_RANGE
			return DEBUGPRINTv(floor((length - nonBL - PSQ_RA_BL_EVAL_RANGE) / PSQ_RA_BL_EVAL_RANGE) + 1)
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

	if(startPoints + rangePoints >= DimSize(wv, ROWS))
		rangePoints = DimSize(wv, ROWS) - startPoints - 1
	endif

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
static Function PSQ_NumAcquiredSweepsInSet(panelTitle, sweepNo, headstage)
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
Function PSQ_NumPassesInSet(numericalValues, type, sweepNo, headstage)
	WAVE numericalValues
	variable type, sweepNo, headstage

	string key

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)

	if(!WaveExists(sweeps)) // very unlikely
		return NaN
	endif

	Make/FREE/N=(DimSize(sweeps, ROWS)) passes
	key = PSQ_CreateLBNKey(type, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	passes[] = GetLastSettingIndep(numericalValues, sweeps[p], key, UNKNOWN_MODE)

	return sum(passes)
End

/// @brief Return the DA stimset length in ms of the given headstage
///
/// @return stimset length or -1 on error
static Function PSQ_GetDAStimsetLength(panelTitle, headstage)
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

/// PSQ_PSQ_CreateOverrideResults("ITC18USB_DEV_0", 0, $type) where type is one of:
///
/// #PSQ_DA_SCALE:
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
/// #PSQ_RHEOBASE/#PSQ_RAMP:
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
		case PSQ_RAMP:
		case PSQ_RHEOBASE:
			numLayers = 2
		case PSQ_DA_SCALE:
			numRows = PSQ_GetNumberOfChunks(panelTitle, 0, headstage, type)
			numCols = IDX_NumberOfSweepsInSet(stimset)
			break
		case PSQ_SQUARE_PULSE:
			numRows = IDX_NumberOfSweepsInSet(stimset)
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
/// @param[in] panelTitle      device
/// @param[in] type            One of @ref PatchSeqAnalysisFunctionTypes
/// @param[in] sweepWave       sweep wave with acquired data
/// @param[in] headstage       headstage in the range [0, NUM_HEADSTAGES[
/// @param[in] totalOnsetDelay total delay in ms until the stimset data starts
/// @param[in] numberOfSpikes  [optional, defaults to one] number of spikes to look for
/// @param[out] spikePositions [optional] returns the position of the first `numberOfSpikes` found on success in ms
///
/// @return labnotebook value wave suitable for ED_AddEntryToLabnotebook()
static Function/WAVE PSQ_SearchForSpikes(panelTitle, type, sweepWave, headstage, totalOnsetDelay, [numberOfSpikes, spikePositions])
	string panelTitle
	variable type
	WAVE sweepWave
	variable headstage, totalOnsetDelay
	variable numberOfSpikes
	WAVE spikePositions

	variable level, first, last, overrideValue
	variable minVal, maxVal
	string msg

	Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) spikeDetection = (p == headstage ? 0 : NaN)

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

	if(PSQ_TestOverrideActive())
		WAVE/SDFR=root: overrideResults
		NVAR count = $GetCount(panelTitle)

		switch(type)
			case PSQ_RHEOBASE:
				overrideValue = overrideResults[0][count][1]
				break
			case PSQ_SQUARE_PULSE:
				overrideValue = overrideResults[count]
				break
			case PSQ_RAMP:
				overrideValue = overrideResults[0][count][1]
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
		if(type == PSQ_RAMP) // during midsweep
			// use the first active AD channel
			level = PSQ_SPIKE_LEVEL * SWS_GetChannelGains(panelTitle)[1]
		else
			level = PSQ_SPIKE_LEVEL
		endif

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
static Function PSQ_TestOverrideActive()

	WAVE/Z/SDFR=root: overrideResults

	if(WaveExists(overrideResults))
		print "TEST OVERRIDE ACTIVE"
		return 1
	endif

	return 0
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
Function PSQ_GetLastPassingLongRHSweep(panelTitle, headstage)
	string panelTitle
	variable headstage

	string key
	variable i, numEntries, sweepNo, sweepCol

	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	// rheobase sweeps passing
	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS, query = 1)
	WAVE/Z sweeps = GetSweepsWithSetting(numericalValues, key)

	if(!WaveExists(sweeps))
		return -1
	endif

	// pulse duration
	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_PULSE_DUR, query = 1)

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

/// @brief Return the DAScale offset for PSQ_DaScale()
///
/// @return DAScale value in pA or NaN on error
Function PSQ_DS_GetDAScaleOffset(panelTitle, headstage, opMode)
	string panelTitle, opMode
	variable headstage

	variable sweepNo

	if(!cmpstr(opMode, PSQ_DS_SUPRA))
		if(PSQ_TestOverrideActive())
			return PSQ_DS_OFFSETSCALE_FAKE
		endif

		sweepNo = PSQ_GetLastPassingLongRHSweep(panelTitle, sweepNo)
		if(!IsValidSweepNumber(sweepNo))
			return NaN
		endif

		WAVE numericalValues = GetLBNumericalValues(panelTitle)
		WAVE/Z setting = GetLastSetting(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
		ASSERT(WaveExists(setting), "Could not find DAScale value of matching rheobase sweep")
		return setting[headstage]
	elseif(!cmpstr(opMode, PSQ_DS_SUB))
		return 0
	else
		ASSERT(0, "unknown opMode")
	endif
End

/// @brief Check if the given sweep has at least one "spike detected" entry in
///        the labnotebook
///
/// @return 1 if found at least one, zero if none and `NaN` if no such entry
/// could be found
Function PSQ_FoundAtLeastOneSpike(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	string key

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

	if(!WaveExists(settings))
		return NaN
	endif

	return Sum(settings) > 0
End

/// @brief Require parameters from stimset
///
/// - DAScales (Numeric wave):       DA Scale Factors in pA
/// - OperationMode (String):        Operation mode of the analayis function. Can be
///                                  either #PSQ_DS_SUB or #PSQ_DS_SUPRA.
/// - SamplingMultiplier (Variable): Sampling multiplier, use 1 for no multiplier
Function/S PSQ_DAScale_GetParams()
	return "DAScales:wave,OperationMode:string,SamplingMultiplier:variable"
End

/// @brief Patch Seq Analysis function to find a suitable DAScale
///
/// Prerequisites:
/// - Does only work for one headstage
/// - Assumes that the stimset has 500ms of pre pulse baseline, a 1000ms (#PSQ_DS_PULSE_DUR) pulse and at least 1000ms post pulse baseline.
/// - Each 500ms (#PSQ_DS_BL_EVAL_RANGE_MS) of the baseline is a chunk
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
///    key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASSED, query = 1)
///    setPassed = GetLastSettingIndepSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
///
///    if(setPassed)
///      // set passed
///    else
///      // set did not pass
///    endif
///
///    // single sweep properties
///    key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
///    sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///
///    // chunk (500ms portions of the baseline) properties
///    key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_CHUNK_PASS, chunk = chunk, query = 1)
///    chunkPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///
///    // single test properties
///    key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = chunk, query = 1)
///    rmsShortPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///    key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = chunk, query = 1)
///    rmsLongPassed  = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///    key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_TARGETV_PASS, chunk = chunk, query = 1)
///    targetVPassed  = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///
///    // get fitted resistance from last passing sweep
///	   // resistance for the first headstage can be found in resistanceFitted[0]
///    WAVE/Z resistanceFitted = GetLastSettingSCI(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + "ResistanceFromFit", headstage, UNKNOWN_MODE)
/// \endrst
///
/// Decision logic flowchart:
///
/// \rst
/// .. image:: ../patch-seq-dascale.dot.svg
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
Function PSQ_DAScale(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3 &s

	variable val, totalOnsetDelay
	variable i, fifoInStimsetPoint, fifoInStimsetTime
	variable index, ret
	variable sweepPassed, setPassed, numSweepsPass, length, minLength
	variable sweepsInSet, passesInSet, acquiredSweepsInSet, numBaselineChunks, multiplier
	string msg, stimset, key, opMode
	variable daScaleOffset = NaN

	WAVE/D/Z DAScales = AFH_GetAnalysisParamWave("DAScales", s.params)
	ASSERT(WaveExists(DAScales), "Missing DAScale parameter")

	opMode = AFH_GetAnalysisParamTextual("OperationMode", s.params)
	ASSERT(!cmpstr(opMode, PSQ_DS_SUB) || !cmpstr(opMode, PSQ_DS_SUPRA), "Invalid opMode")

	multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)
	ASSERT(multiplier > 0, "Missing or non-positive SamplingMultiplier parameter.")

	numSweepsPass = DimSize(DAScales, ROWS)
	ASSERT(numSweepsPass > 0, "Invalid number of entries in DAScales")

	WAVE DAScalesIndex = GetAnalysisFuncIndexingHelper(panelTitle)

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			PGC_SetAndActivateControl(panelTitle, "check_DataAcq_AutoBias", val = 1)
			PGC_SetAndActivateControl(panelTitle, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_RepeatAcq", val = 1)

			WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			if(DAG_GetHeadstageMode(panelTitle, s.headstage) != I_CLAMP_MODE)
				printf "(%s) Clamp mode must be current clamp.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			length = PSQ_GetDAStimsetLength(panelTitle, s.headstage)
			minLength = PSQ_DS_PULSE_DUR + 3 * PSQ_DS_BL_EVAL_RANGE_MS
			if(length < minLength)
				printf "(%s) Stimset of headstage %d is too short, it must be at least %g ms long.\r", panelTitle, s.headstage, minLength
				ControlWindowToFront()
				return 1
			endif

			val = DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_AutoBiasV")

			if(!IsFinite(val) || CheckIfSmall(val, tol = 1e-12))
				printf "(%s): Autobias value is zero or non-finite\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			val = WhichListItem(num2str(multiplier), DAP_GetSamplingMultiplier())
			if(val == -1)
				printf "(%s): The passed sampling multiplier of %d is invalid.\r", panelTitle, multiplier
				ControlWindowToFront()
				return 1
			endif

			PGC_SetAndActivateControl(panelTitle, "Popup_Settings_SampIntMult", val = val)

			DisableControls(panelTitle, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")

			// fallthrough-by-design
		case PRE_SET_EVENT:
			DAScalesIndex[s.headstage] = 0

			daScaleOffset = PSQ_DS_GetDAScaleOffset(panelTitle, s.headstage, opMode)
			if(!IsFinite(daScaleOffset))
				printf "(%s): Could not find a valid DAScale threshold value from previous rheobase runs with long pulses.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			PGC_SetAndActivateControl(panelTitle, "check_Settings_ITITP", val = 1)
			PGC_SetAndActivateControl(panelTitle, "Check_Settings_InsertTP", val = 1)

			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleDeltaI(panelTitle))
			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleDeltaV(panelTitle))
			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleRes(panelTitle))
			KillWindow/Z $RESISTANCE_GRAPH

			break
		case POST_SWEEP_EVENT:
			WAVE numericalValues = GetLBNumericalValues(panelTitle)
			WAVE textualValues   = GetLBTextualValues(panelTitle)

			daScaleOffset = PSQ_DS_GetDAScaleOffset(panelTitle, s.headstage, opMode)

			key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
			sweepPassed = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			ASSERT(IsFinite(sweepPassed), "Could not find the sweep passed labnotebook entry")

			WAVE/T stimsets = GetLastSetting(textualValues, s.sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
			stimset = stimsets[s.headstage]

			sweepsInSet         = IDX_NumberOfSweepsInSet(stimset)
			passesInSet         = PSQ_NumPassesInSet(numericalValues, PSQ_DA_SCALE, s.sweepNo, s.headstage)
			acquiredSweepsInSet = PSQ_NumAcquiredSweepsInSet(panelTitle, s.sweepNo, s.headstage)

			sprintf msg, "Sweep %s, total sweeps %d, acquired sweeps %d, passed sweeps %d, required passes %d, DAScalesIndex %d\r", SelectString(sweepPassed, "failed", "passed"), sweepsInSet, acquiredSweepsInSet, passesInSet, numSweepsPass, DAScalesIndex[s.headstage]
			DEBUGPRINT(msg)

			if(!sweepPassed)
				// not enough sweeps left to pass the set
				if((sweepsInSet - acquiredSweepsInSet) < (numSweepsPass - passesInSet))
					PSQ_ForceSetEvent(panelTitle, s.headstage)
					RA_SkipSweeps(panelTitle, inf)
					return NaN
				endif
			else
				// sweep passed
				if(!cmpstr(opMode, PSQ_DS_SUB))
					WAVE/Z sweep = GetSweepWave(panelTitle, s.sweepNo)
					ASSERT(WaveExists(sweep), "Expected a sweep for evaluation")

					Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) deltaV     = NaN
					Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) deltaI     = NaN
					Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) resistance = NaN

					CalculateTPLikePropsFromSweep(numericalValues, textualValues, sweep, deltaI, deltaV, resistance)

					ED_AddEntryToLabnotebook(panelTitle, "Delta I", deltaI, unit = "I")
					ED_AddEntryToLabnotebook(panelTitle, "Delta V", deltaV, unit = "V")

					PlotResistanceGraph(panelTitle)
				endif

				if(passesInSet >= numSweepsPass)
					PSQ_ForceSetEvent(panelTitle, s.headstage)
					RA_SkipSweeps(panelTitle, inf, limitToSetBorder = 1)
					return NaN
				else
					// set next DAScale value
					DAScalesIndex[s.headstage] += 1
				endif
			endif

			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(panelTitle)

			setPassed = PSQ_NumPassesInSet(numericalValues, PSQ_DA_SCALE, s.sweepNo, s.headstage) >= numSweepsPass

			sprintf msg, "Set has %s\r", SelectString(setPassed, "failed", "passed")
			DEBUGPRINT(msg)

			Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
			result[INDEP_HEADSTAGE] = setPassed
			key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(panelTitle, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			AD_UpdateAllDatabrowser()

			break
		case POST_DAQ_EVENT:
			EnableControls(panelTitle, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
	endswitch

	if(s.eventType == PRE_DAQ_EVENT || s.eventType == PRE_SET_EVENT || s.eventType == POST_SWEEP_EVENT)
		WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

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
				ASSERT(isFinite(daScaleOffset), "DAScale offset is non-finite")
				SetDAScale(panelTitle, i, (DAScales[index] + daScaleOffset) * 1e-12)
			endif
		endfor
	endif

	if(s.eventType != MID_SWEEP_EVENT)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE, defValue = 0)

	if(sweepPassed) // already done
		return NaN
	endif

	totalOnsetDelay = DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_OnsetDelayUser") \
					  + GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_OnsetDelayAuto")

	fifoInStimsetPoint = s.lastKnownRowIndex - totalOnsetDelay / DimDelta(s.rawDACWAVE, ROWS)
	fifoInStimsetTime  = fifoInStimsetPoint * DimDelta(s.rawDACWAVE, ROWS)

	numBaselineChunks = PSQ_GetNumberOfChunks(panelTitle, s.sweepNo, s.headstage, PSQ_DA_SCALE)

	for(i = 0; i < numBaselineChunks; i += 1)

		ret = PSQ_EvaluateBaselineProperties(panelTitle, PSQ_DA_SCALE, s.sweepNo, i, fifoInStimsetTime, totalOnsetDelay)

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

	key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SWEEP_PASS)
	ED_AddEntryToLabnotebook(panelTitle, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

	return sweepPassed ? ANALYSIS_FUNC_RET_EARLY_STOP : ret
End

/// @brief Return a list of required parameters for PSQ_SquarePulse()
///
/// - SamplingMultiplier (Variable): Sampling multiplier, use 1 for no multiplier
Function/S PSQ_SquarePulse_GetParams()
	return "SamplingMultiplier:variable"
End

/// @brief Analysis function to find the smallest DAScale where the cell spikes
///
/// Prerequisites:
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
///	.. image:: ../patch-seq-squarepulse.dot.svg
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
Function PSQ_SquarePulse(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3 &s

	variable stepsize, DAScale, totalOnsetDelay, setPassed, sweepPassed, multiplier
	variable val
	string key, msg

	multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)
	ASSERT(multiplier > 0, "Missing or non-positive SamplingMultiplier parameter.")

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			PGC_SetAndActivateControl(panelTitle, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_RepeatAcq", val = 1)

			if(DAG_GetHeadstageMode(panelTitle, s.headstage) != I_CLAMP_MODE)
				printf "(%s) Clamp mode must be current clamp.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			val = WhichListItem(num2str(multiplier), DAP_GetSamplingMultiplier())
			if(val == -1)
				printf "(%s): The passed sampling multiplier of %d is invalid.\r", panelTitle, multiplier
				ControlWindowToFront()
				return 1
			endif

			PGC_SetAndActivateControl(panelTitle, "Popup_Settings_SampIntMult", val = val)

			DisableControls(panelTitle, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")

			// fallthrough-by-design
		case PRE_SET_EVENT:

			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq_Get_Set_ITI", val = 1)
			PGC_SetAndActivateControl(panelTitle, "Check_Settings_InsertTP", val = 0)
			PGC_SetAndActivateControl(panelTitle, "check_Settings_ITITP", val = 0)

			PSQ_StoreStepSizeInLBN(panelTitle, s.sweepNo, PSQ_SP_INIT_AMP_p100)
			SetDAScale(panelTitle, s.headstage, PSQ_SP_INIT_AMP_p100)

			return 0

			break
		case POST_SWEEP_EVENT:
			WAVE sweepWave = GetSweepWave(panelTitle, s.sweepNo)
			WAVE numericalValues = GetLBNumericalValues(panelTitle)

			totalOnsetDelay = GetTotalOnsetDelay(numericalValues, s.sweepNo)

			WAVE spikeDetection = PSQ_SearchForSpikes(panelTitle, PSQ_SQUARE_PULSE, sweepWave, s.headstage, totalOnsetDelay)
			key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DETECT)
			ED_AddEntryToLabnotebook(panelTitle, key, spikeDetection, unit = LABNOTEBOOK_BINARY_UNIT)

			key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_STEPSIZE, query = 1)
			stepSize = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
			DAScale  = GetLastSetting(numericalValues, s.sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[s.headstage] * 1e-12

			sweepPassed = 0

			sprintf msg, "stepSize %g", stepSize
			DEBUGPRINT(msg)

			if(spikeDetection[s.headstage]) // headstage spiked
				if(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_m50))
					SetDAScale(panelTitle, s.headstage, DAScale + stepsize)
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_p10))
					Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) value = NaN
					value[INDEP_HEADSTAGE] = DAScale
					key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE)
					ED_AddEntryToLabnotebook(panelTitle, key, value)

					sweepPassed = 1

					PSQ_ForceSetEvent(panelTitle, s.headstage)
					RA_SkipSweeps(panelTitle, inf, limitToSetBorder = 1)
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_p100))
					PSQ_StoreStepSizeInLBN(panelTitle, s.sweepNo, PSQ_SP_INIT_AMP_m50)
					stepsize = PSQ_SP_INIT_AMP_m50
					SetDAScale(panelTitle, s.headstage, DAScale + stepsize)
				else
					ASSERT(0, "Unknown stepsize")
				endif
			else // headstage did not spike
				if(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_m50))
					PSQ_StoreStepSizeInLBN(panelTitle, s.sweepNo, PSQ_SP_INIT_AMP_p10)
					stepsize = PSQ_SP_INIT_AMP_p10
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_p10))
					// do nothing
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_p100))
					// do nothing
				else
					ASSERT(0, "Unknown stepsize")
				endif

				SetDAScale(panelTitle, s.headstage, DAScale + stepsize)
			endif

			sprintf msg, "Sweep has %s\r", SelectString(sweepPassed, "failed", "passed")
			DEBUGPRINT(msg)

			Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) value = NaN
			value[INDEP_HEADSTAGE] = sweepPassed
			key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(panelTitle, key, value, unit = LABNOTEBOOK_BINARY_UNIT)

			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(panelTitle)

			setPassed = PSQ_NumPassesInSet(numericalValues, PSQ_SQUARE_PULSE, s.sweepNo, s.headstage) >= 1

			if(!setPassed)
				PSQ_ForceSetEvent(panelTitle, s.headstage)
				RA_SkipSweeps(panelTitle, inf)
			endif

			sprintf msg, "Set has %s\r", SelectString(setPassed, "failed", "passed")
			DEBUGPRINT(msg)

			Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
			result[INDEP_HEADSTAGE] = setPassed
			key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(panelTitle, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			AD_UpdateAllDatabrowser()

			break
		case POST_DAQ_EVENT:
			EnableControls(panelTitle, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
		default:
			// do nothing
			break
	endswitch

	return NaN
End

/// @brief Return a list of required parameters for PSQ_Rheobase()
///
/// - SamplingMultiplier (Variable): Sampling multiplier, use 1 for no multiplier
Function/S PSQ_Rheobase_GetParams()
	return "SamplingMultiplier:variable"
End

/// @brief Analysis function for finding the exact DAScale value between spiking and non-spiking
///
/// Prerequisites:
/// - Does only work for one headstage
/// - Assumes that the stimset has a pulse of non-zero and arbitrary length
/// - Pre pulse baseline length is #PSQ_RB_PRE_BL_EVAL_RANGE
/// - Post pulse baseline length a multiple of #PSQ_RB_POST_BL_EVAL_RANGE
///
/// Testing:
/// For testing the spike detection logic, the results can be defined in the wave
/// root:overrideResults. @see PSQ_CreateOverrideResults()
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: ../patch-seq-rheobase.dot.svg
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
Function PSQ_Rheobase(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3 &s

	variable DAScale, val, numSweeps, currentSweepHasSpike, lastSweepHasSpike, setPassed
	variable baselineQCPassed, finalDAScale, initialDAScale
	variable numBaselineChunks, lastFifoPos, totalOnsetDelay, fifoInStimsetPoint, fifoInStimsetTime
	variable i, ret, numSweepsWithSpikeDetection, sweepNoFound, length, minLength, multiplier
	string key, msg

	multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)
	ASSERT(multiplier > 0, "Missing or non-positive SamplingMultiplier parameter.")

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			PGC_SetAndActivateControl(panelTitle, "SetVar_DataAcq_SetRepeats", val = 1)
			PGC_SetAndActivateControl(panelTitle, "check_DataAcq_AutoBias", val = 1)
			PGC_SetAndActivateControl(panelTitle, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_RepeatAcq", val = 1)

			if(DAG_GetHeadstageMode(panelTitle, s.headstage) != I_CLAMP_MODE)
				printf "(%s) Clamp mode must be current clamp.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			length = PSQ_GetDAStimsetLength(panelTitle, s.headstage)
			minLength = PSQ_RB_PRE_BL_EVAL_RANGE + 2 * PSQ_RB_POST_BL_EVAL_RANGE
			if(length < minLength)
				printf "(%s) Stimset of headstage %d is too short, it must be at least %g ms long.\r", panelTitle, s.headstage, minLength
				ControlWindowToFront()
				return 1
			endif

			val = DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_AutoBiasV")

			if(!IsFinite(val) || CheckIfSmall(val, tol = 1e-12))
				printf "(%s): Autobias value is zero or non-finite\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			val = WhichListItem(num2str(multiplier), DAP_GetSamplingMultiplier())
			if(val == -1)
				printf "(%s): The passed sampling multiplier of %d is invalid.\r", panelTitle, multiplier
				ControlWindowToFront()
				return 1
			endif

			PGC_SetAndActivateControl(panelTitle, "Popup_Settings_SampIntMult", val = val)

			DisableControls(panelTitle, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")

			// fallthrough-by-design
		case PRE_SET_EVENT:

			PGC_SetAndActivateControl(panelTitle, "SetVar_DataAcq_ITI", val = 4)
			PGC_SetAndActivateControl(panelTitle, "Check_Settings_InsertTP", val = 1)
			PGC_SetAndActivateControl(panelTitle, "check_Settings_ITITP", val = 1)

			WAVE numericalValues = GetLBNumericalValues(panelTitle)
			key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
			finalDAScale = GetLastSweepWithSettingIndep(numericalValues, key, sweepNoFound)

			if(!IsFinite(finalDAScale) || !IsValidSweepNumber(sweepNoFound))
				printf "(%s): Could not find final DAScale value from one of the previous analysis functions.\r", panelTitle
				if(PSQ_TestOverrideActive())
					finalDASCale = PSQ_RB_FINALSCALE_FAKE
				else
					ControlWindowToFront()
					return 1
				endif
			endif

			SetDAScale(panelTitle, s.headstage, finalDAScale)

			return 0

			break
		case POST_SWEEP_EVENT:
			WAVE numericalValues = GetLBNumericalValues(panelTitle)
			WAVE sweeps = AFH_GetSweepsFromSameSCI(numericalValues, s.sweepNo, s.headstage)

			numSweeps = DimSize(sweeps, ROWS)

			if(numSweeps == 1)
				// query the initial DA scale from the previous sweep (which is from a different RAC)
				key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
				finalDAScale = GetLastSweepWithSettingIndep(numericalValues, key, sweepNoFound)
				if(PSQ_TestOverrideActive())
					finalDAScale = PSQ_RB_FINALSCALE_FAKE
				else
					ASSERT(IsFinite(finalDAScale) && IsValidSweepNumber(sweepNoFound), "Could not find final DAScale value from previous analysis function")
				endif

				// and set it as the initial DAScale for this SCI
				Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
				result[INDEP_HEADSTAGE] = finalDAScale
				key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_INITIAL_SCALE)
				ED_AddEntryToLabnotebook(panelTitle, key, result)
			endif

			key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
			WAVE/Z baselineQCPassedWave = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)

			baselineQCPassed = WaveExists(baselineQCPassedWave) && baselineQCPassedWave[s.headstage]

			sprintf msg, "numSweeps %d, baselineQCPassed %d", numSweeps, baselineQCPassed
			DEBUGPRINT(msg)

			if(!baselineQCPassed)
				break
			endif

			// search for spike and store result
			WAVE sweepWave = GetSweepWave(panelTitle, s.sweepNo)
			WAVE numericalValues = GetLBNumericalValues(panelTitle)

			totalOnsetDelay = GetTotalOnsetDelay(numericalValues, s.sweepNo)

			WAVE spikeDetection = PSQ_SearchForSpikes(panelTitle, PSQ_RHEOBASE, sweepWave, s.headstage, totalOnsetDelay)
			key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SPIKE_DETECT)
			ED_AddEntryToLabnotebook(panelTitle, key, spikeDetection, unit = LABNOTEBOOK_BINARY_UNIT)

			key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
			WAVE spikeDetectionRA = GetLastSettingEachSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			DEBUGPRINT("spikeDetectionRA: ", wv = spikeDetectionRA)

			numSweepsWithSpikeDetection = DimSize(spikeDetectionRA, ROWS)
			currentSweepHasSpike        = spikeDetectionRA[numSweepsWithSpikeDetection - 1]

			if(numSweepsWithSpikeDetection >= 2)
				lastSweepHasSpike = spikeDetectionRA[numSweepsWithSpikeDetection - 2]

				if(IsFinite(currentSweepHasSpike) && IsFinite(lastSweepHasSpike) \
				   && (currentSweepHasSpike != lastSweepHasSpike))
					// mark the set as passed
					// we can't mark each sweep as passed/failed as it is not possible
					// to add LBN entries to other sweeps than the last one
					Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
					key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS)
					result[INDEP_HEADSTAGE] = 1
					ED_AddEntryToLabnotebook(panelTitle, key, result, unit = LABNOTEBOOK_BINARY_UNIT)
					PSQ_ForceSetEvent(panelTitle, s.headstage)
					RA_SkipSweeps(panelTitle, inf, limitToSetBorder = 1)

					DEBUGPRINT("Sweep has passed")
					break
				endif
			endif

			DAScale = GetLastSetting(numericalValues, s.sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[s.headstage] * 1e-12
			if(currentSweepHasSpike)
				DAScale -= PSQ_RB_DASCALE_STEP
			else
				DAScale += PSQ_RB_DASCALE_STEP
			endif

			key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_INITIAL_SCALE, query = 1)
			initialDAScale = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			if(abs(DAScale - initialDAScale) >= PSQ_RB_MAX_DASCALE_DIFF)
				// mark set as failure
				Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
				key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS)
				result[INDEP_HEADSTAGE] = 0
				ED_AddEntryToLabnotebook(panelTitle, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

				result              = NaN
				result[s.headstage] = 1

				key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_DASCALE_EXC)
				ED_AddEntryToLabnotebook(panelTitle, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

				PSQ_ForceSetEvent(panelTitle, s.headstage)
				RA_SkipSweeps(panelTitle, inf)

				DEBUGPRINT("Set has failed")
				break
			endif

			SetDAScale(panelTitle, s.headstage, DAScale)
			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(panelTitle)
			key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS, query = 1)
			setPassed = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			// if we don't have an entry yet for the set passing, it has failed
			if(!IsFinite(setPassed))
				key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS)
				Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
				result[INDEP_HEADSTAGE] = 0
				ED_AddEntryToLabnotebook(panelTitle, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

				PSQ_ForceSetEvent(panelTitle, s.headstage)
				RA_SkipSweeps(panelTitle, inf)

				DEBUGPRINT("Set has failed")
			endif

			key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_DASCALE_EXC, query = 1)
			WAVE/Z rangeExceeded = GetLastSettingSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			if(!WaveExists(rangeExceeded))
				Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
				result[s.headstage] = 0
				key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_DASCALE_EXC)
				ED_AddEntryToLabnotebook(panelTitle, key, result, unit = LABNOTEBOOK_BINARY_UNIT)
			endif

			AD_UpdateAllDatabrowser()

			break
		case POST_DAQ_EVENT:
			EnableControls(panelTitle, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
	endswitch

	if(s.eventType != MID_SWEEP_EVENT)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	baselineQCPassed = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE, defValue = 0)

	if(baselineQCPassed)
		return NaN
	endif

	totalOnsetDelay = DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_OnsetDelayUser") \
					  + GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_OnsetDelayAuto")

	fifoInStimsetPoint = s.lastKnownRowIndex - totalOnsetDelay / DimDelta(s.rawDACWAVE, ROWS)
	fifoInStimsetTime  = fifoInStimsetPoint * DimDelta(s.rawDACWAVE, ROWS)

	numBaselineChunks = PSQ_GetNumberOfChunks(panelTitle, s.sweepNo, s.headstage, PSQ_RHEOBASE)

	for(i = 0; i < numBaselineChunks; i += 1)

		ret = PSQ_EvaluateBaselineProperties(panelTitle, PSQ_RHEOBASE, s.sweepNo, i, fifoInStimsetTime, totalOnsetDelay)

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

	baselineQCPassed = (ret == 0)

	sprintf msg, "Baseline QC %s, last evaluated chunk %d returned with %g\r", SelectString(baselineQCPassed, "failed", "passed"), i, ret
	DEBUGPRINT(msg)

	// document BL QC results
	Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
	result[s.headstage] = baselineQCPassed

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_BL_QC_PASS)
	ED_AddEntryToLabnotebook(panelTitle, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

	return baselineQCPassed ? ANALYSIS_FUNC_RET_EARLY_STOP : ret
End

/// @brief Return a list of required parameters for PSQ_Ramp()
///
/// - NumberOfSpikes (variable):     Number of spikes required to be found after
///                                  the pulse onset in order to label the cell
///                                  as having "spiked".
/// - SamplingMultiplier (Variable): Sampling multiplier, use 1 for no multiplier
Function/S PSQ_Ramp_GetParams()
	return "NumberOfSpikes:variable,SamplingMultiplier:variable"
End

/// @brief Analysis function for applying a ramp stim set and finding the position were it spikes.
///
/// Prerequisites:
/// - Does only work for one headstage
/// - Assumes that the stimset has a ramp of non-zero and arbitrary length
/// - Pre pulse baseline length is #PSQ_RA_BL_EVAL_RANGE
/// - Post pulse baseline length is at least two times #PSQ_RA_BL_EVAL_RANGE
///
/// Testing:
/// For testing the spike detection logic, the results can be defined in the wave
/// root:overrideResults. @see PSQ_CreateOverrideResults()
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: ../patch-seq-ramp.dot.svg
/// \endrst
///
/// @verbatim
///
/// Sketch of a stimset with pre pulse baseline (-), ramp (/|), and post pulse baseline (-).
///
///                 /|
///                / |
///               /  |
///              /   |
///             /    |
///            /     |
///           /      |
///          /       |
///         /        |
///        /         |
///       /          |
///      /           |
///     /            |
/// ---/             |--------------------------------------------
///
/// @endverbatim
Function PSQ_Ramp(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3 &s

	variable DAScale, val, numSweeps, currentSweepHasSpike, setPassed
	variable baselineQCPassed, finalDAScale, initialDAScale
	variable numBaselineChunks, lastFifoPos, totalOnsetDelay, fifoInStimsetPoint, fifoInStimsetTime
	variable i, ret, numSweepsWithSpikeDetection, sweepNoFound, length, minLength
	variable DAC, sweepPassed, sweepsInSet, passesInSet, acquiredSweepsInSet, enoughSpikesFound
	variable pulseStart, pulseDuration, fifoPos, fifoOffset, numberOfSpikes, multiplier
	string key, msg, stimset
	string fifoname
	variable hardwareType

	numberOfSpikes = AFH_GetAnalysisParamNumerical("NumberOfSpikes", s.params)
	ASSERT(numberOfSpikes > 0, "Missing or non-positive NumberOfSpikes parameter.")

	multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)
	ASSERT(multiplier > 0, "Missing or non-positive SamplingMultiplier parameter.")

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			PGC_SetAndActivateControl(panelTitle, "check_DataAcq_AutoBias", val = 1)
			PGC_SetAndActivateControl(panelTitle, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_RepeatAcq", val = 1)

			if(DAG_GetHeadstageMode(panelTitle, s.headstage) != I_CLAMP_MODE)
				printf "(%s) Clamp mode must be current clamp.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			length = PSQ_GetDAStimsetLength(panelTitle, s.headstage)
			minLength = 3 * PSQ_RA_BL_EVAL_RANGE
			if(length < minLength)
				printf "(%s) Stimset of headstage %d is too short, it must be at least %g ms long.\r", panelTitle, s.headstage, minLength
				ControlWindowToFront()
				return 1
			endif

			val = DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_AutoBiasV")

			if(!IsFinite(val) || CheckIfSmall(val, tol = 1e-12))
				printf "(%s): Autobias value is zero or non-finite\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			val = WhichListItem(num2str(multiplier), DAP_GetSamplingMultiplier())
			if(val == -1)
				printf "(%s): The passed sampling multiplier of %d is invalid.\r", panelTitle, multiplier
				ControlWindowToFront()
				return 1
			endif

			PGC_SetAndActivateControl(panelTitle, "Popup_Settings_SampIntMult", val = val)

			DAC = AFH_GetDACFromHeadstage(panelTitle, s.headstage)
			stimset = AFH_GetStimSetName(panelTitle, DAC, CHANNEL_TYPE_DAC)
			if(IDX_NumberOfSweepsInSet(stimset) < PSQ_RA_NUM_SWEEPS_PASS)
				printf "(%s): The stimset must have at least %d sweeps\r", panelTitle, PSQ_RA_NUM_SWEEPS_PASS
				ControlWindowToFront()
				return 1
			endif

			DisableControls(panelTitle, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")

			// fallthrough-by-design
		case PRE_SET_EVENT:
			PGC_SetAndActivateControl(panelTitle, "SetVar_DataAcq_ITI", val = 0)
			PGC_SetAndActivateControl(panelTitle, "check_Settings_ITITP", val = 1)
			PGC_SetAndActivateControl(panelTitle, "Check_Settings_InsertTP", val = 1)

			SetDAScale(panelTitle, s.headstage, PSQ_RA_DASCALE_DEFAULT * 1e-12)

			return 0

			break
		case POST_SWEEP_EVENT:
			WAVE numericalValues = GetLBNumericalValues(panelTitle)
			WAVE textualValues   = GetLBTextualValues(panelTitle)

			key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
			sweepPassed = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			ASSERT(IsFinite(sweepPassed), "Could not find the sweep passed labnotebook entry")

			WAVE/T stimsets = GetLastSetting(textualValues, s.sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
			stimset = stimsets[s.headstage]

			sweepsInSet         = IDX_NumberOfSweepsInSet(stimset)
			passesInSet         = PSQ_NumPassesInSet(numericalValues, PSQ_RAMP, s.sweepNo, s.headstage)
			acquiredSweepsInSet = PSQ_NumAcquiredSweepsInSet(panelTitle, s.sweepNo, s.headstage)

			if(!sweepPassed)
				// not enough sweeps left to pass the set
				if((sweepsInSet - acquiredSweepsInSet) < (PSQ_RA_NUM_SWEEPS_PASS - passesInSet))
					PSQ_ForceSetEvent(panelTitle, s.headstage)
					RA_SkipSweeps(panelTitle, inf)
				endif
			else
				if(passesInSet >= PSQ_RA_NUM_SWEEPS_PASS)
					PSQ_ForceSetEvent(panelTitle, s.headstage)
					RA_SkipSweeps(panelTitle, inf, limitToSetBorder = 1)
				endif
			endif

			sprintf msg, "Sweep %s, total sweeps %d, acquired sweeps %d, sweeps passed %d, required passes %d\r", SelectString(sweepPassed, "failed", "passed"), sweepsInSet, acquiredSweepsInSet, passesInSet, PSQ_RA_NUM_SWEEPS_PASS
			DEBUGPRINT(msg)

			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(panelTitle)

			setPassed = PSQ_NumPassesInSet(numericalValues, PSQ_RAMP, s.sweepNo, s.headstage) >= PSQ_RA_NUM_SWEEPS_PASS

			sprintf msg, "Set has %s\r", SelectString(setPassed, "failed", "passed")
			DEBUGPRINT(msg)

			Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
			result[INDEP_HEADSTAGE] = setPassed
			key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(panelTitle, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			AD_UpdateAllDatabrowser()

			break
		case POST_DAQ_EVENT:
			EnableControls(panelTitle, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
	endswitch

	if(s.eventType != MID_SWEEP_EVENT)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	baselineQCPassed = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE, defValue = 0)

	enoughSpikesFound = PSQ_FoundAtLeastOneSpike(panelTitle, s.sweepNo)

	sprintf msg, "enoughSpikesFound %g, baselineQCPassed %d", enoughSpikesFound, baselineQCPassed
	DEBUGPRINT(msg)

	if(IsFinite(enoughSpikesFound) && baselineQCPassed) // spike already found/definitly not found and baseline QC passed
		return NaN
	endif

	totalOnsetDelay = DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_OnsetDelayUser") \
					  + GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_OnsetDelayAuto")

	fifoInStimsetPoint = s.lastKnownRowIndex - totalOnsetDelay / DimDelta(s.rawDACWAVE, ROWS)
	fifoInStimsetTime  = fifoInStimsetPoint * DimDelta(s.rawDACWAVE, ROWS)

	numBaselineChunks = PSQ_GetNumberOfChunks(panelTitle, s.sweepNo, s.headstage, PSQ_RAMP)

	WAVE durations = PSQ_GetPulseDurations(panelTitle, PSQ_RAMP, s.sweepNo, totalOnsetDelay)
	pulseStart     = PSQ_RA_BL_EVAL_RANGE
	pulseDuration  = durations[s.headstage]

	if(IsNaN(enoughSpikesFound) && fifoInStimsetTime >= pulseStart) // spike search was inconclusive up to now
																	// and we are after the pulse onset

		Make/FREE/D spikePos
		WAVE spikeDetection = PSQ_SearchForSpikes(panelTitle, PSQ_RAMP, s.rawDACWave, s.headstage, \
												  totalOnsetDelay, spikePositions = spikePos, numberOfSpikes = numberOfSpikes)

		if(spikeDetection[s.headstage] \
		   && ((PSQ_TestOverrideActive() && (fifoInStimsetTime > WaveMax(spikePos))) || !PSQ_TestOverrideActive()))

			enoughSpikesFound = 1

			key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_DETECT)
			ED_AddEntryToLabnotebook(panelTitle, key, spikeDetection, overrideSweepNo = s.sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)

			Make/FREE/T/N=(LABNOTEBOOK_LAYER_COUNT) resultTxT
			resultTxT[s.headstage] = NumericWaveToList(spikePos, ";")
			key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_POSITIONS)
			ED_AddEntryToLabnotebook(panelTitle, key, resultTxT, overrideSweepNo = s.sweepNo, unit = "ms")

			NVAR deviceID = $GetITCDeviceIDGlobal(panelTitle)
			NVAR ADChannelToMonitor = $GetADChannelToMonitor(panelTitle)

			hardwareType = GetHardwareType(panelTitle)
			if(hardwareType == HARDWARE_ITC_DAC)

				// stop DAQ, set DA to zero from now to the end and start DAQ again

				// fetch the very last fifo position immediately before we stop it
				NVAR tgID = $GetThreadGroupIDFIFO(panelTitle)
				fifoOffset = TS_GetNewestFromThreadQueue(tgID, "fifoPos")
				TFH_StopFIFODaemon(HARDWARE_ITC_DAC, deviceID)
				HW_StopAcq(HARDWARE_ITC_DAC, deviceID)
				HW_ITC_PrepareAcq(deviceID, offset=fifoOffset)

				WAVE wv = s.rawDACWave

				sprintf msg, "DA black out: [%g, %g]\r", fifoOffset, inf
				DEBUGPRINT(msg)

				SetWaveLock 0, wv
				Multithread wv[fifoOffset, inf][0, ADChannelToMonitor - 1] = 0
				SetWaveLock 1, wv

				HW_StartAcq(HARDWARE_ITC_DAC, deviceID)
				TFH_StartFIFOStopDaemon(HARDWARE_ITC_DAC, deviceID)

				// fetch newest fifo position, blocks until it gets a valid value
				// its zero is now fifoOffset
				NVAR tgID = $GetThreadGroupIDFIFO(panelTitle)
				fifoPos = TS_GetNewestFromThreadQueue(tgID, "fifoPos")
				ASSERT(fifoPos > 0, "Invalid fifo position, has the thread died?")

				// wait until the hardware is finished with writing this chunk
				// this is to avoid that two threads write simultaneously into the ITCDataWave
				for(;;)
					val = TS_GetNewestFromThreadQueue(tgID, "fifoPos")

					if(val > fifoPos)
						break
					endif
				endfor

				sprintf msg, "AD black out: [%g, %g]\r", fifoOffset, (fifoOffset + fifoPos)
				DEBUGPRINT(msg)

				SetWaveLock 0, wv
				Multithread wv[fifoOffset, fifoOffset + fifoPos][ADChannelToMonitor, inf] = 0
				SetWaveLock 1, wv

			elseif(hardwareType == HARDWARE_NI_DAC)
				// DA output runs on the AD tasks clock source ai
				// we stop DA and set the analog out to 0, the AD task keeps on running

				WAVE config = GetITCChanConfigWave(panelTitle)
				fifoName = GetNIFIFOName(deviceID)

				HW_NI_StopDAC(deviceID)
				HW_NI_ZeroDAC(deviceID)

				DoXOPIdle
				FIFOStatus/Q $fifoName
				WAVE/WAVE NIDataWave = s.rawDACWave
				// As only one AD and DA channel is allowed for this function, at index 0 the setting for first DA channel are expected
				WAVE NIChannel = NIDataWave[0]
				if(V_FIFOChunks < DimSize(NIChannel, ROWS))
					MultiThread NIChannel[V_FIFOChunks,] = 0
				endif

			else
				ASSERT(0, "Unknown hardware type")
			endif

			// recalculate pulse duration
			PSQ_GetPulseDurations(panelTitle, PSQ_RAMP, s.sweepNo, totalOnsetDelay, forceRecalculation = 1)
		elseif(fifoInStimsetTime > pulseStart + pulseDuration)
			// we are past the pulse and have not found a spike
			// write the results into the LBN
			key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_DETECT)
			ED_AddEntryToLabnotebook(panelTitle, key, spikeDetection, overrideSweepNo = s.sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)
		endif
	endif

	if(!baselineQCPassed)
		for(i = 0; i < numBaselineChunks; i += 1)

			ret = PSQ_EvaluateBaselineProperties(panelTitle, PSQ_RAMP, s.sweepNo, i, fifoInStimsetTime, totalOnsetDelay)

			if(IsNaN(ret))
				// NaN: not enough data for check
				//
				// not last chunk: retry on next invocation
				// last chunk: mark sweep as failed
				if(i == numBaselineChunks - 1)
					ret = 1
				endif

				break
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

		if(IsFinite(ret))
			baselineQCPassed = (ret == 0)

			sprintf msg, "Baseline QC/Sweep has %s, last evaluated chunk %d returned with %g\r", SelectString(baselineQCPassed, "failed", "passed"), i, ret
			DEBUGPRINT(msg)

			// document BL QC results
			Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
			result[s.headstage] = baselineQCPassed

			key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_BL_QC_PASS)
			ED_AddEntryToLabnotebook(panelTitle, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			result[] = NaN
			result[INDEP_HEADSTAGE] = baselineQCPassed
			key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(panelTitle, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			// we can return here as we either:
			// - failed pre pulse BL QC and we don't need to search for a spike
			// - or passed post pulse BL QC and already searched for a spike
			enoughSpikesFound = PSQ_FoundAtLeastOneSpike(panelTitle, s.sweepNo)

			ASSERT(!baselineQCPassed || (baselineQCPassed && isFinite(enoughSpikesFound)), "We missed searching for a spike")
			return baselineQCPassed ? ANALYSIS_FUNC_RET_EARLY_STOP : ret
		endif
	endif
End

/// @brief Map from analysis function name to numeric constant
///
/// @return One of @ref PatchSeqAnalysisFunctionTypes
Function PSQ_MapFunctionToConstant(anaFunc)
	string anaFunc

	strswitch(anaFunc)
		case "PSQ_Ramp":
			return PSQ_RAMP
		case "PSQ_DaScale":
			return PSQ_DA_SCALE
		case "PSQ_Rheobase":
			return PSQ_RHEOBASE
		case "PSQ_SquarePulse":
			return PSQ_SQUARE_PULSE
		default:
			return NaN
	endswitch
End

/// @brief Manually force the pre/post set events
///
/// Required to do before skipping sweeps.
/// @todo this hack must go away.
static Function PSQ_ForceSetEvent(panelTitle, headstage)
	string panelTitle
	variable headstage

	variable DAC

	WAVE setEventFlag = GetSetEventFlag(panelTitle)
	DAC = AFH_GetDACFromHeadstage(panelTitle, headstage)

	setEventFlag[DAC][%PRE_SET_EVENT]  = 1
	setEventFlag[DAC][%POST_SET_EVENT] = 1
End
