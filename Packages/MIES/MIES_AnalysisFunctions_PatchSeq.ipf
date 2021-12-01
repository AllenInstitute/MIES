#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_PSQ
#endif

/// @file MIES_AnalysisFunctions_PatchSeq.ipf
/// @brief __PSQ__ Analysis functions for patch sequence
///
/// The stimsets with the analysis functions attached are executed in the following order:
/// - PSQ_DaScale (sub threshold)
/// - PSQ_SquarePulse (long pulse)
/// - PSQ_Rheobase (long pulse)
/// - PSQ_DaScale (supra threshold)
/// - PSQ_SquarePulse (short pulse)
/// - PSQ_Rheobase (short pulse)
/// - PSQ_Ramp
/// - PSQ_Chirp
///
/// The Patch Seq analysis functions store various results in the labnotebook.
///
/// For orientation the following table shows their relation. All labnotebook
/// keys can and should be created via CreateAnaFuncLBNKey().
///
/// \rst
///
/// =============================== ========================================================= ======================== ======================== =====================  =====================
/// Naming constant                 Description                                               Labnotebook              Analysis function        Per Chunk?             Headstage dependent?
/// =============================== ========================================================= ======================== ======================== =====================  =====================
/// PSQ_FMT_LBN_SPIKE_DETECT        The required number of spikes were detected on the sweep  Numerical                SP, RB, RA, DA (Supra)   No                     Yes
/// PSQ_FMT_LBN_SPIKE_POSITIONS     Spike positions in ms                                     Numerical                RA                       No                     Yes
/// PSQ_FMT_LBN_SPIKE_COUNT         Spike count                                               Numerical                DA (Supra)               No                     Yes
/// PSQ_FMT_LBN_STEPSIZE            Current DAScale step size                                 Numerical                SP, RB                   No                     No
/// PSQ_FMT_LBN_STEPSIZE_FUTURE     Future DAScale step size                                  Numerical                RB                       No                     No
/// PSQ_FMT_LBN_RB_DASCALE_EXC      Range for valid DAScale values is exceeded                Numerical                RB                       No                     Yes
/// PSQ_FMT_LBN_RB_LIMITED_RES      Failed due to limited DAScale resolution                  Numerical                RB                       No                     Yes
/// PSQ_FMT_LBN_FINAL_SCALE         Final DAScale of the given headstage, only set on success Numerical                SP, RB                   No                     No
/// PSQ_FMT_LBN_SPIKE_DASCALE_ZERO  Sweep spiked with DAScale of 0                            Numerical                SP                       No                     No
/// PSQ_FMT_LBN_INITIAL_SCALE       Initial DAScale                                           Numerical                RB, CR                   No                     No
/// PSQ_FMT_LBN_RMS_SHORT_PASS      Short RMS baseline QC result                              Numerical                DA, RB, RA, CR           Yes                    Yes
/// PSQ_FMT_LBN_RMS_SHORT_THRESHOLD Short RMS baseline threshold [V]                          Numerical                DA, RB, RA, CR           No                     Yes
/// PSQ_FMT_LBN_RMS_LONG_PASS       Long RMS baseline QC result                               Numerical                DA, RB, RA, CR           Yes                    Yes
/// PSQ_FMT_LBN_RMS_LONG_THRESHOLD  Long RMS baseline threshold [V]                           Numerical                DA, RB, RA, CR           No                     Yes
/// PSQ_FMT_LBN_TARGETV             Target voltage baseline                                   Numerical                DA, RB, RA, CR           Yes                    Yes
/// PSQ_FMT_LBN_TARGETV_PASS        Target voltage baseline QC result                         Numerical                DA, RB, RA, CR           Yes                    Yes
/// PSQ_FMT_LBN_CHUNK_PASS          Which chunk passed/failed baseline QC                     Numerical                DA, RB, RA, CR           Yes                    Yes
/// PSQ_FMT_LBN_BL_QC_PASS          Pass/fail state of the complete baseline                  Numerical                DA, RB, RA, CR           No                     Yes
/// PSQ_FMT_LBN_SWEEP_PASS          Pass/fail state of the complete sweep                     Numerical                DA, SP, RA, CR           No                     No
/// PSQ_FMT_LBN_SET_PASS            Pass/fail state of the complete set                       Numerical                DA, RB, RA, SP, CR       No                     No
/// PSQ_FMT_LBN_SAMPLING_PASS       Pass/fail state of the sampling interval check            Numerical                DA, RB, RA, SP, CR       No                     No
/// PSQ_FMT_LBN_PULSE_DUR           Pulse duration as determined experimentally               Numerical                RB, DA (Supra), CR       No                     Yes
/// PSQ_FMT_LBN_DA_fI_SLOPE         Fitted slope in the f-I plot                              Numerical                DA (Supra)               No                     Yes
/// PSQ_FMT_LBN_DA_fI_SLOPE_REACHED Fitted slope in the f-I plot exceeds target value         Numerical                DA (Supra)               No                     No
/// PSQ_FMT_LBN_DA_OPMODE           Operation Mode: One of PSQ_DS_SUB/PSQ_DS_SUPRA            Textual                  DA                       No                     No
/// PSQ_FMT_LBN_CR_INSIDE_BOUNDS    AD response is inside the given bands                     Numerical                CR                       No                     No
/// PSQ_FMT_LBN_CR_RESISTANCE       Calculated resistance in Ohm from DAScale sub threshold   Numerical                CR                       No                     No
/// PSQ_FMT_LBN_CR_BOUNDS_ACTION    Action according to min/max positions                     Numerical                CR                       No                     No
/// PSQ_FMT_LBN_CR_BOUNDS_STATE     Upper and Lower bounds state according to min/max pos.    Textual                  CR                       No                     No
/// PSQ_FMT_LBN_CR_SPIKE_CHECK      Spike check was enabled/disabled                          Numerical                CR                       No                     No
/// PSQ_FMT_LBN_CR_SPIKE_PASS       Pass/fail state of the spike search (No spikes → Pass)    Numerical                CR                       No                     Yes
/// FMT_LBN_ANA_FUNC_VERSION        Integer version of the analysis function                  Numerical                All                      No                     Yes
/// =============================== ========================================================= ======================== ======================== =====================  =====================
///
/// Query the standard STIMSET_SCALE_FACTOR_KEY entry from labnotebook for getting the DAScale.
///
/// \endrst
///
/// The following table lists the user epochs which are added during data acquisition:
///
/// \rst
///
/// ============================ ========== ================== ======================================= =====
/// Tags                         Short Name Analysis function  Description                             Level
/// ============================ ========== ================== ======================================= =====
/// Name=Baseline Chunk;Index=x  U_BLCx     DA, RB, RA, CR     Baseline QC evaluation chunks           -1
/// Name=DA Suppression          U_RA_DA    RA                 DA was suppressed in this time interval -1
/// Name=Unacquired DA data      U_RA_UD    RA                 Interval of unacquired data             -1
/// ============================ ========== ================== ======================================= =====
///
/// See also :ref:`epoch_time_specialities`.
/// \endrst

static Constant PSQ_BL_PRE_PULSE   = 0x0
static Constant PSQ_BL_POST_PULSE  = 0x1

static Constant PSQ_RMS_SHORT_TEST = 0x0
static Constant PSQ_RMS_LONG_TEST  = 0x1
static Constant PSQ_TARGETV_TEST   = 0x2

static Constant PSQ_DEFAULT_SAMPLING_MULTIPLIER = 4

static Constant PSQ_RHEOBASE_DURATION = 500

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
		case PSQ_CHIRP:
			s.prePulseChunkLength  = PSQ_CR_BL_EVAL_RANGE
			s.postPulseChunkLength = PSQ_CR_BL_EVAL_RANGE
			s.pulseDuration        = NaN
			break
		default:
			ASSERT(0, "unsupported type")
			break
	endswitch

	sprintf msg, "postPulseChunkLength %d, prePulseChunkLength %d, pulseDuration %g", s.postPulseChunkLength, s.prePulseChunkLength, s.pulseDuration
	DEBUGPRINT(msg)
End

/// Return the pulse durations from the labnotebook or calculate them before if required in ms.
/// For convenience unused headstages will have 0 instead of NaN in the returned wave.
///
/// We recalculate the durations on every sweep again as we can not assume that
/// it is constant for the whole stimulus set.
static Function/WAVE PSQ_GetPulseDurations(device, type, sweepNo, totalOnsetDelay, [forceRecalculation])
	string device
	variable type, sweepNo, totalOnsetDelay, forceRecalculation

	string key

	if(ParamIsDefault(forceRecalculation))
		forceRecalculation = 0
	else
		forceRecalculation = !!forceRecalculation
	endif

	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_PULSE_DUR, query = 1)
	WAVE/Z durations = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

	if(!WaveExists(durations) || forceRecalculation)
		WAVE durations = PSQ_DeterminePulseDuration(device, sweepNo, type, totalOnsetDelay)

		key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_PULSE_DUR)
		ED_AddEntryToLabnotebook(device, key, durations, unit = "ms", overrideSweepNo = sweepNo)
	endif

	durations[] = IsNaN(durations[p]) ? 0 : durations[p]

	return durations
End

/// @brief Determine the pulse duration on each headstage
///
/// Returns the labnotebook wave as well.
static Function/WAVE PSQ_DeterminePulseDuration(device, sweepNo, type, totalOnsetDelay)
	string device
	variable sweepNo, type, totalOnsetDelay

	variable i, level, first, last, duration
	string key

	WAVE/Z sweepWave = GetSweepWave(device, sweepNo)

	if(!WaveExists(sweepWave))
		WAVE sweepWave = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
		WAVE config    = GetDAQConfigWave(device)
	else
		WAVE config = GetConfigWave(sweepWave)
	endif

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
	MAKE/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) durations = NaN

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		WAVE singleDA = AFH_ExtractOneDimDataFromSweep(device, sweepWave, i, XOP_CHANNEL_TYPE_DAC, config = config)

		if(type == PSQ_CHIRP)
			// search something above/below zero from front and back
			FindLevel/Q/R=(totalOnsetDelay, inf) singleDA, 0
			ASSERT(!V_Flag, "Could not find an edge")
			first = V_LevelX

			FindLevel/Q/R=(inf, totalOnsetDelay) singleDA, 0
			ASSERT(!V_Flag, "Could not find an edge")
			last = V_LevelX
		else
			level = WaveMin(singleDA, totalOnsetDelay, inf) + GetMachineEpsilon(WaveType(singleDA))

			// search a square pulse
			FindLevel/Q/R=(totalOnsetDelay, inf)/EDGE=1 singleDA, level
			ASSERT(!V_Flag, "Could not find a rising edge")
			first = V_LevelX

			FindLevel/Q/R=(totalOnsetDelay, inf)/EDGE=2 singleDA, level
			ASSERT(!V_Flag, "Could not find a falling edge")
			last = V_LevelX
		endif

		if(level > 0 || type == PSQ_CHIRP)
			duration = last - first - DimDelta(singleDA, ROWS)
		else
			duration = first - last + DimDelta(singleDA, ROWS)
		endif

		ASSERT(duration > 0, "Duration must be strictly positive")

		durations[i] = duration
	endfor

	return durations
End

/// @brief Return the baseline RMS short/long thresholds in mV
static Function [variable rmsShortThreshold, variable rmsLongThreshold] PSQ_GetBaselineRMSThresholds(string params)

	rmsShortThreshold = AFH_GetAnalysisParamNumerical("BaselineRMSShortThreshold", params, defValue = PSQ_RMS_SHORT_THRESHOLD)
	rmsLongThreshold  = AFH_GetAnalysisParamNumerical("BaselineRMSLongThreshold", params, defValue = PSQ_RMS_LONG_THRESHOLD)

	return [rmsShortThreshold, rmsLongThreshold]
End

static Function PSQ_StoreRMSThresholdsInLabnotebook(string device, variable type, variable sweepNo, variable headstage, variable rmsShortThreshold, variable rmsLongThreshold)
	string key

	Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN

	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	// mV -> V
	values[headstage] = rmsShortThreshold * 1e-3
	ED_AddEntryToLabnotebook(device, key, values, unit = "V", overrideSweepNo = sweepNo)

	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	// mV -> V
	values[headstage] = rmsLongThreshold * 1e-3
	ED_AddEntryToLabnotebook(device, key, values, unit = "V", overrideSweepNo = sweepNo)
End

static Function PSQ_EvaluateBaselinePassed(string device, variable type, variable sweepNo, variable headstage, variable chunk, variable ret)
	variable baselineQCPassed
	string key, msg

	baselineQCPassed = (ret == 0)

	sprintf msg, "BL QC %s, last evaluated chunk %d returned with %g\r", ToPassFail(baselineQCPassed), chunk, ret
	DEBUGPRINT(msg)

	// document BL QC results
	Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
	result[headstage] = baselineQCPassed

	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_BL_QC_PASS)
	ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)

	return baselineQCPassed ? ANALYSIS_FUNC_RET_EARLY_STOP : ret
End

static Function [variable ret, variable chunk] PSQ_EvaluateBaselineChunks(string device, variable type, STRUCT AnalysisFunction_V3 &s)

	variable numBaselineChunks, i, totalOnsetDelay, fifoInStimsetPoint, fifoInStimsetTime

	numBaselineChunks = PSQ_GetNumberOfChunks(device, s.sweepNo, s.headstage, type)

	if(type == PSQ_CHIRP)
		ASSERT(numBaselineChunks >= 3, "Unexpected number of baseline chunks")
	endif

	totalOnsetDelay = DAG_GetNumericalValue(device, "setvar_DataAcq_OnsetDelayUser") \
					  + GetValDisplayAsNum(device, "valdisp_DataAcq_OnsetDelayAuto")

	fifoInStimsetPoint = s.lastKnownRowIndex - totalOnsetDelay / DimDelta(s.rawDACWAVE, ROWS)
	fifoInStimsetTime  = fifoInStimsetPoint * DimDelta(s.rawDACWAVE, ROWS)

	for(i = 0; i < numBaselineChunks; i += 1)

		ret = PSQ_EvaluateBaselineProperties(device, s, type, i, fifoInStimsetTime, totalOnsetDelay)

		if(IsNaN(ret))
			// NaN: not enough data for check

			// last chunk was only partially present and so can never pass
			if(i == numBaselineChunks - 1 && s.lastKnownRowIndex == s.lastValidRowIndex)
				ret = PSQ_BL_FAILED
			endif

			break
		elseif(ret)
			// != 0: failed with special mid sweep return value (on first failure) or PSQ_BL_FAILED
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

	return [ret, i]
End

/// @brief Evaluate one chunk of the baseline
///
/// @param device        device
/// @param s                 AnalysisFunction_V3 struct
/// @param type              analysis function type, one of @ref PatchSeqAnalysisFunctionTypes
/// @param chunk             chunk number, `chunk == 0` -> Pre pulse baseline chunk, `chunk >= 1` -> Post pulse baseline
/// @param fifoInStimsetTime Fifo position in ms *relative* to the start of the stimset (therefore ignoring the totalOnsetDelay)
/// @param totalOnsetDelay   total onset delay in ms
///
/// @return
/// pre pulse baseline: 0 if the chunk passes, one of the possible @ref AnalysisFuncReturnTypesConstants values otherwise
/// post pulse baseline: 0 if the chunk passes, PSQ_BL_FAILED if it does not pass
static Function PSQ_EvaluateBaselineProperties(string device, STRUCT AnalysisFunction_V3 &s, variable type, variable chunk, variable fifoInStimsetTime, variable totalOnsetDelay)

	variable , evalStartTime, evalRangeTime
	variable i, DAC, ADC, ADcol, chunkStartTimeMax, chunkStartTime
	variable targetV, index
	variable rmsShortPassedAll, rmsLongPassedAll, chunkPassed
	variable targetVPassedAll, baselineType, chunkLengthTime
	variable rmsShortThreshold, rmsLongThreshold, chunkPassedTestOverride
	string msg, adUnit, ctrl, key, epName, epShortName

	struct PSQ_PulseSettings ps
	PSQ_GetPulseSettingsForType(type, ps)

	if(chunk == 0) // pre pulse baseline
		chunkStartTimeMax  = totalOnsetDelay
		chunkLengthTime    = ps.prePulseChunkLength
		baselineType       = PSQ_BL_PRE_PULSE
	else // post pulse baseline
		 if(type == PSQ_RHEOBASE || type == PSQ_RAMP || type == PSQ_CHIRP)
			 WAVE durations = PSQ_GetPulseDurations(device, type, s.sweepNo, totalOnsetDelay)
		 else
			 Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) durations = ps.pulseDuration
		 endif

		 // skip: onset delay, the pulse itself and one chunk of post pulse baseline
		chunkStartTimeMax = (totalOnsetDelay + ps.prePulseChunkLength + WaveMax(durations)) + chunk * ps.postPulseChunkLength
		chunkLengthTime   = ps.postPulseChunkLength
		baselineType      = PSQ_BL_POST_PULSE
	endif

	// not enough data to evaluate
	if(fifoInStimsetTime + totalOnsetDelay < chunkStartTimeMax + chunkLengthTime)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_CHUNK_PASS, chunk = chunk, query = 1)
	chunkPassed = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE, defValue = NaN)

	if(IsFinite(chunkPassed)) // already evaluated
		return !chunkPassed
	endif

	[rmsShortThreshold, rmsLongThreshold] = PSQ_GetBaselineRMSThresholds(s.params)

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

	sprintf msg, "We have some data to evaluate in chunk %d [%g, %g]:  %gms\r", chunk, chunkStartTimeMax, chunkStartTimeMax + chunkLengthTime, fifoInStimsetTime + totalOnsetDelay
	DEBUGPRINT(msg)

	WAVE config = GetDAQConfigWave(device)

	Make/D/FREE/N = (LABNOTEBOOK_LAYER_COUNT) rmsShort       = NaN
	Make/D/FREE/N = (LABNOTEBOOK_LAYER_COUNT) rmsShortPassed = NaN
	Make/D/FREE/N = (LABNOTEBOOK_LAYER_COUNT) rmsLong        = NaN
	Make/D/FREE/N = (LABNOTEBOOK_LAYER_COUNT) rmsLongPassed  = NaN
	Make/D/FREE/N = (LABNOTEBOOK_LAYER_COUNT) avgVoltage     = NaN
	Make/D/FREE/N = (LABNOTEBOOK_LAYER_COUNT) targetVPassed  = NaN

	targetV = DAG_GetNumericalValue(device, "setvar_DataAcq_AutoBiasV")

	// BEGIN TEST
	if(TestOverrideActive())
		WAVE overrideResults = GetOverrideResults()
		NVAR count = $GetCount(device)
		chunkPassedTestOverride = overrideResults[chunk][count][0]
	endif
	// END TEST

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		DAC = AFH_GetDACFromHeadstage(device, i)
		ASSERT(IsFinite(DAC), "Could not determine DAC channel number for HS " + num2istr(i) + " for device " + device)
		epName = "Name=Baseline Chunk;Index=" + num2istr(chunk)
		epShortName = PSQ_BASELINE_CHUNK_SHORT_NAME_PREFIX + num2istr(chunk)
		EP_AddUserEpoch(device, XOP_CHANNEL_TYPE_DAC, DAC, chunkStartTimeMax / 1E3, (chunkStartTimeMax + chunkLengthTime) / 1E3, epName, shortname = epShortName)

		if(chunk == 0) // pre pulse baseline
			chunkStartTime = totalOnsetDelay

			// store baseline RMS short/long analysis parameters in labnotebook on first use
			PSQ_StoreRMSThresholdsInLabnotebook(device, type, s.sweepNo, i, rmsShortThreshold, rmsLongThreshold)
		else
			ASSERT(durations[i] != 0, "Invalid calculated durations")
			chunkStartTime = (totalOnsetDelay + ps.prePulseChunkLength + durations[i]) + chunk * ps.postPulseChunkLength
		endif

		ADC = AFH_GetADCFromHeadstage(device, i)
		ASSERT(IsFinite(ADC), "This analysis function does not work with unassociated AD channels")
		ADcol = AFH_GetDAQDataColumn(config, ADC, XOP_CHANNEL_TYPE_ADC)

		ADunit = DAG_GetTextualValue(device, GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT), index = ADC)

		// assuming millivolts
		ASSERT(!cmpstr(ADunit, "mV"), "Unexpected AD Unit")

		if(testMatrix[baselineType][PSQ_RMS_SHORT_TEST])

			evalStartTime = chunkStartTime + chunkLengthTime - 1.5
			evalRangeTime = 1.5

			// check 1: RMS of the last 1.5ms of the baseline should be below 0.07mV
			rmsShort[i] = PSQ_Calculate(s.scaledDACWave, ADCol, evalStartTime, evalRangeTime, PSQ_CALC_METHOD_RMS)

			if(TestOverrideActive())
				rmsShortPassed[i] = chunkPassedTestOverride
			else
				rmsShortPassed[i] = rmsShort[i] < rmsShortThreshold
			endif

			sprintf msg, "RMS noise short: %g (%s)\r", rmsShort[i], ToPassFail(rmsShortPassed[i])
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
			rmsLong[i] = PSQ_Calculate(s.scaledDACWave, ADCol, evalStartTime, evalRangeTime, PSQ_CALC_METHOD_RMS)

			if(TestOverrideActive())
				rmsLongPassed[i] = chunkPassedTestOverride
			else
				rmsLongPassed[i] = rmsLong[i] < rmsLongThreshold
			endif

			sprintf msg, "RMS noise long: %g (%s)", rmsLong[i], ToPassFail(rmsLongPassed[i])
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
			avgVoltage[i] = PSQ_Calculate(s.scaledDACWave, ADCol, evalStartTime, evalRangeTime, PSQ_CALC_METHOD_AVG)

			if(TestOverrideActive())
				targetVPassed[i] = chunkPassedTestOverride
			else
				targetVPassed[i] = abs(avgVoltage[i] - targetV) <= PSQ_TARGETV_THRESHOLD
			endif

			sprintf msg, "Average voltage of %gms: %g (%s)", evalRangeTime, avgVoltage[i], ToPassFail(targetVPassed[i])
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

	if(HasOneValidEntry(avgVoltage))
		// mV -> V
		avgVoltage[] *= 1000
		key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_TARGETV, chunk = chunk)
		ED_AddEntryToLabnotebook(device, key, avgVoltage, unit = "Volt", overrideSweepNo = s.sweepNo)
	endif

	// document results per headstage and chunk
	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(device, key, rmsShortPassed, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)
	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(device, key, rmsLongPassed, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)
	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_TARGETV_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(device, key, targetVPassed, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

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

	sprintf msg, "Chunk %d %s", chunk, ToPassFail(chunkPassed)
	DEBUGPRINT(msg)

	// document chunk results
	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
	result[INDEP_HEADSTAGE] = chunkPassed
	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_CHUNK_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

	if(baselineType == PSQ_BL_PRE_PULSE)
		if(!rmsShortPassedAll)
			return ANALYSIS_FUNC_RET_EARLY_STOP
		elseif(!rmsLongPassedAll)
			return ANALYSIS_FUNC_RET_EARLY_STOP
		elseif(!targetVPassedAll)
			NVAR repurposedTime = $GetRepurposedSweepTime(device)
			repurposedTime = 10
			return ANALYSIS_FUNC_RET_REPURP_TIME
		else
			ASSERT(chunkPassed, "logic error")
		endif
	elseif(baselineType == PSQ_BL_POST_PULSE)
		if(chunkPassed)
			return 0
		else
			return PSQ_BL_FAILED
		endif
	else
		ASSERT(0, "unknown baseline type")
	endif
End

/// @brief Return the number of chunks
///
/// A chunk is #PSQ_DS_BL_EVAL_RANGE_MS/#PSQ_RB_POST_BL_EVAL_RANGE/#PSQ_RB_PRE_BL_EVAL_RANGE/#PSQ_RA_BL_EVAL_RANGE
/// #PSQ_CR_BL_EVAL_RANGE [ms] of baseline
///
/// For calculating the number of chunks we ignore the one chunk after the pulse which we don't evaluate!
static Function PSQ_GetNumberOfChunks(device, sweepNo, headstage, type)
	string device
	variable type, sweepNo, headstage

	variable length, nonBL, totalOnsetDelay

	WAVE DAQDataWave    = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
	NVAR stopCollectionPoint = $GetStopCollectionPoint(device)
	totalOnsetDelay = DAG_GetNumericalValue(device, "setvar_DataAcq_OnsetDelayUser") \
					  + GetValDisplayAsNum(device, "valdisp_DataAcq_OnsetDelayAuto")

	length = stopCollectionPoint * DimDelta(DAQDataWave, ROWS)

	switch(type)
		case PSQ_DA_SCALE:
			nonBL = totalOnsetDelay + PSQ_DS_PULSE_DUR + PSQ_DS_BL_EVAL_RANGE_MS
			return DEBUGPRINTv(floor((length - nonBL) / PSQ_DS_BL_EVAL_RANGE_MS))
			break
		case PSQ_RHEOBASE:
			WAVE durations = PSQ_GetPulseDurations(device, PSQ_RHEOBASE, sweepNo, totalOnsetDelay)
			ASSERT(durations[headstage] != 0, "Pulse duration can not be zero")
			nonBL = totalOnsetDelay + durations[headstage] + PSQ_RB_POST_BL_EVAL_RANGE
			return DEBUGPRINTv(floor((length - nonBL - PSQ_RB_PRE_BL_EVAL_RANGE) / PSQ_RB_POST_BL_EVAL_RANGE) + 1)
			break
		case PSQ_RAMP:
			WAVE durations = PSQ_GetPulseDurations(device, PSQ_RAMP, sweepNo, totalOnsetDelay)
			ASSERT(durations[headstage] != 0, "Pulse duration can not be zero")
			nonBL = totalOnsetDelay + durations[headstage] + PSQ_RA_BL_EVAL_RANGE
			return DEBUGPRINTv(floor((length - nonBL - PSQ_RA_BL_EVAL_RANGE) / PSQ_RA_BL_EVAL_RANGE) + 1)
			break
		case PSQ_CHIRP:
			WAVE durations = PSQ_GetPulseDurations(device, PSQ_CHIRP, sweepNo, totalOnsetDelay)
			ASSERT(durations[headstage] != 0, "Pulse duration can not be zero")
			nonBL = totalOnsetDelay + durations[headstage] + PSQ_CR_BL_EVAL_RANGE
			return DEBUGPRINTv(floor((length - nonBL - PSQ_CR_BL_EVAL_RANGE) / PSQ_CR_BL_EVAL_RANGE) + 1)
			break
		default:
			ASSERT(0, "unsupported type")
	endswitch
End

// @brief Calculate a value from `startTime` spanning
//        `rangeTime` milliseconds according to `method`
static Function PSQ_Calculate(wv, column, startTime, rangeTime, method)
	WAVE wv
	variable column, startTime, rangeTime, method

	variable rangePoints, startPoints

	startPoints = startTime / DimDelta(wv, ROWS)
	rangePoints = rangeTime / DimDelta(wv, ROWS)

	if(startPoints + rangePoints >= DimSize(wv, ROWS))
		rangePoints = DimSize(wv, ROWS) - startPoints - 1
	endif

	MatrixOP/FREE data = subWaveC(wv, startPoints, column, rangePoints)

	switch(method)
		case PSQ_CALC_METHOD_AVG:
			MatrixOP/FREE result = mean(data)
			break
		case PSQ_CALC_METHOD_RMS:
			// This differs from what WaveStats returns in `V_sdev` as we divide by
			// `N` but WaveStats by `N -1`
			MatrixOP/FREE avg = mean(data)
			MatrixOP/FREE result = sqrt(sumSqr(data - avg[0]) / numRows(data))
			break
		default:
			ASSERT(0, "Unknown method")
	endswitch

	ASSERT(IsFinite(result[0]), "result must be finite")

	return result[0]
End

/// @brief Return the number of already acquired sweeps from the given
///        stimset cycle
static Function PSQ_NumAcquiredSweepsInSet(device, sweepNo, headstage)
	string device
	variable sweepNo, headstage

	WAVE numericalValues = GetLBNumericalValues(device)

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)

	if(!WaveExists(sweeps)) // very unlikely
		return 0
	endif

	return DimSize(sweeps, ROWS)
End

/// @brief Return the number of passed sweeps in all sweeps from the given
///        stimset cycle
Function PSQ_NumPassesInSet(numericalValues, type, sweepNo, headstage)
	WAVE numericalValues
	variable type, sweepNo, headstage

	string key

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)

	if(!WaveExists(sweeps)) // very unlikely
		return NaN
	endif

	Make/FREE/N=(DimSize(sweeps, ROWS)) passes
	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	passes[] = GetLastSettingIndep(numericalValues, sweeps[p], key, UNKNOWN_MODE)

	return sum(passes)
End

/// @brief Return the DA stimset length in ms of the given headstage
///
/// @return stimset length or -1 on error
static Function PSQ_GetDAStimsetLength(device, headstage)
	string device
	variable headstage

	string setName
	variable DAC

	DAC = AFH_GetDACFromHeadstage(device, headstage)
	setName = AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC)

	WAVE/Z stimset = WB_CreateAndGetStimSet(setName)
	if(!WaveExists(stimset))
		return -1
	endif

	return DimSize(stimset, ROWS) * DimDelta(stimset, ROWS)
End

/// @brief Create the overrides results wave for CI testing
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
///
/// #PSQ_DA_SCALE:
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
/// - 2: Number of spikes
///
/// #PSQ_CHIRP:
///
/// Rows:
/// - chunk indizes
///
/// Cols:
/// - sweeps/steps
///
/// Layers:
/// - 0: 1 if the chunk has passing baseline QC or not
/// - 1: maximum of AD data in chirp region [first row only,
///      others are ignored], use NaN to use the real values
/// - 2: minimum of AD data in chirp region [first row only,
///      others are ignored], use NaN to use the real values
/// - 3: passing spike check in chirp region or not [first row only,
///      others are ignored]
Function/WAVE PSQ_CreateOverrideResults(device, headstage, type)
	string device
	variable headstage, type

	variable DAC, numCols, numRows, numLayers
	string stimset

	DAC = AFH_GetDACFromHeadstage(device, headstage)
	stimset = AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC)
	WAVE/Z stimsetWave = WB_CreateAndGetStimSet(stimset)
	ASSERT(WaveExists(stimsetWave), "Stimset does not exist")

	switch(type)
		case PSQ_RAMP:
		case PSQ_RHEOBASE:
			numLayers = 2
			numRows = PSQ_GetNumberOfChunks(device, 0, headstage, type)
			numCols = IDX_NumberOfSweepsInSet(stimset)
			break
		case PSQ_DA_SCALE:
			numLayers = 3
			numRows = PSQ_GetNumberOfChunks(device, 0, headstage, type)
			numCols = IDX_NumberOfSweepsInSet(stimset)
			break
		case PSQ_SQUARE_PULSE:
			numRows = IDX_NumberOfSweepsInSet(stimset)
			numCols = 0
			break
		case PSQ_CHIRP:
			numLayers = 4
			numRows = PSQ_GetNumberOfChunks(device, 0, headstage, type)
			numCols = IDX_NumberOfSweepsInSet(stimset)
			break
		default:
			ASSERT(0, "invalid type")
	endswitch

	WAVE/D/Z/SDFR=root: wv = overrideResults

	if(WaveExists(wv))
		Redimension/D/N=(numRows, numCols, numLayers) wv
	else
		Make/D/N=(numRows, numCols, numLayers) root:overrideResults/Wave=wv
	endif

	wv[] = 0

	return wv
End

/// @brief Store the step size in the labnotebook
static Function PSQ_StoreStepSizeInLBN(device, type, sweepNo, stepsize, [future])
	string device
	variable type, sweepNo, stepsize, future

	string key

	if(ParamIsDefault(future))
		future = 0
	else
		future = !!future
	endif

	Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
	values[INDEP_HEADSTAGE] = stepsize
	key = CreateAnaFuncLBNKey(type, SelectString(future, PSQ_FMT_LBN_STEPSIZE, PSQ_FMT_LBN_STEPSIZE_FUTURE))
	ED_AddEntryToLabnotebook(device, key, values, overrideSweepNo = sweepNo)
End

/// @brief Search the AD channel of the given headstage for spikes from the
/// pulse onset until the end of the sweep or `searchEnd` if given
///
/// @param[in] device            device
/// @param[in] type                  One of @ref PatchSeqAnalysisFunctionTypes
/// @param[in] sweepWave             sweep wave with acquired data
/// @param[in] headstage             headstage in the range [0, NUM_HEADSTAGES[
/// @param[in] offset                offset in ms where the spike search should start, commonly the totalOnsetDelay
/// @param[in] level                 set the level for the spike search
/// @param[in] searchEnd             [optional, defaults to inf] total length in ms of the spike search, relative to sweepWave start
/// @param[in] numberOfSpikesReq     [optional, defaults to one] number of spikes to look for
///                                  Positive finite value: Return value is 1 iff at least `numberOfSpikes` were found
///                                  Inf: Return value is 1 if at least 1 spike was found
/// @param[out] spikePositions       [optional] returns the position of the first `numberOfSpikes` found on success in ms
/// @param[out] numberOfSpikesFound  [optional] returns the number of spikes found
///
/// @return labnotebook value wave suitable for ED_AddEntryToLabnotebook()
static Function/WAVE PSQ_SearchForSpikes(device, type, sweepWave, headstage, offset, level, [searchEnd, numberOfSpikesReq, spikePositions, numberOfSpikesFound])
	string device
	variable type
	WAVE sweepWave
	variable headstage, offset, level, searchEnd
	variable numberOfSpikesReq
	WAVE spikePositions
	variable &numberOfSpikesFound

	variable first, last, overrideValue, rangeSearchLevel
	variable minVal, maxVal, numSpikesFoundOverride
	string msg

	Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) spikeDetection = (p == headstage ? 0 : NaN)

	if(WaveRefsEqual(sweepWave, GetDAQDataWave(device, DATA_ACQUISITION_MODE)))
		WAVE config = GetDAQConfigWave(device)
	else
		WAVE config = GetConfigWave(sweepWave)
	endif

	if(ParamIsDefault(searchEnd))
		searchEnd = inf
	endif

	if(ParamIsDefault(numberOfSpikesReq))
		numberOfSpikesReq = 1
	else
		ASSERT(numberOfSpikesReq > 0, "Invalid numberOfSpikesFound")
		numberOfSpikesReq = trunc(numberOfSpikesReq)
	endif

	if(!ParamIsDefault(numberOfSpikesFound))
		numberOfSpikesFound = NaN
	endif

	sprintf msg, "Type %d, headstage %d, offset %g, numberOfSpikesReq %d", type, headstage, offset, numberOfSpikesReq
	DEBUGPRINT(msg)

	if(type == PSQ_CHIRP)
		first = offset
		last  = searchEnd
	else
		WAVE singleDA = AFH_ExtractOneDimDataFromSweep(device, sweepWave, headstage, XOP_CHANNEL_TYPE_DAC, config = config)
		[minVal, maxVal] = WaveMinAndMaxWrapper(singleDA, x1 = offset, x2 = inf)

		if(minVal == 0 && maxVal == 0)
			if(type == PSQ_SQUARE_PULSE)
				first = 0
				last  = searchEnd
			else
				return spikeDetection
			endif
		else
			rangeSearchLevel = minVal + GetMachineEpsilon(WaveType(singleDA))

			Make/FREE/D levels
			FindLevels/R=(offset, inf)/Q/N=2/DEST=levels singleDA, rangeSearchLevel
			ASSERT(V_LevelsFound == 2, "Could not find two levels")
			first = levels[0]

			if(type == PSQ_DA_SCALE)
				last = levels[1]
			else
				last = searchEnd
			endif
		endif
	endif

	if(TestOverrideActive())
		WAVE overrideResults = GetOverrideResults()
		NVAR count = $GetCount(device)

		switch(type)
			case PSQ_CHIRP:
				overrideValue = !overrideResults[0][count][3]
				numSpikesFoundOverride = overrideValue > 0
				break
			case PSQ_RHEOBASE:
				overrideValue = overrideResults[0][count][1]
				numSpikesFoundOverride = overrideValue > 0
				break
			case PSQ_SQUARE_PULSE:
				overrideValue = overrideResults[count]
				numSpikesFoundOverride = overrideValue > 0
				break
			case PSQ_RAMP:
				overrideValue = overrideResults[0][count][1]
				numSpikesFoundOverride = overrideValue > 0
				break
			case PSQ_DA_SCALE:
				overrideValue = overrideResults[0][count][1]
				if(overrideValue > 0)
					numSpikesFoundOverride = overrideResults[0][count][2]
				else
					numSpikesFoundOverride = 0
				endif
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
			Redimension/D/N=(numSpikesFoundOverride) spikePositions
			spikePositions[] = overrideValue
		endif

		if(!ParamIsDefault(numberOfSpikesFound))
			numberOfSpikesFound = numSpikesFoundOverride
		endif
	else
		if(type == PSQ_RAMP || type == PSQ_CHIRP) // during midsweep
			// use the first active AD channel
			level *= SWS_GetChannelGains(device, timing = GAIN_AFTER_DAQ)[1]
		endif

		WAVE singleAD = AFH_ExtractOneDimDataFromSweep(device, sweepWave, headstage, XOP_CHANNEL_TYPE_ADC, config = config)
		ASSERT(!cmpstr(WaveUnits(singleAD, -1), "mV"), "Unexpected AD Unit")

		if(type == PSQ_CHIRP)
			// use PA plot logic
			Duplicate/R=(first, last)/FREE singleAD, chirpChunk

			ASSERT(numberOfSpikesReq == inf, "Unexpected value of numberOfSpikesReq")
			WAVE spikePositionsResult = PA_SpikePositionsForNonVC(chirpChunk, level)

			spikeDetection[headstage] = DimSize(spikePositionsResult, ROWS) > 0

			if(!ParamIsDefault(numberOfSpikesFound))
				numberOfSpikesFound = DimSize(spikePositionsResult, ROWS)
			endif
		else
			if(numberOfSpikesReq == 1)
				// search the spike from the start till the end
				FindLevel/Q/R=(first, last)/B=3 singleAD, level
				spikeDetection[headstage] = !V_flag

				if(!ParamIsDefault(spikePositions))
					ASSERT(WaveExists(spikePositions), "Wave spikePositions must exist")
					Redimension/D/N=(numberOfSpikesReq) spikePositions
					spikePositions[0] = V_LevelX
				endif

				if(!ParamIsDefault(numberOfSpikesFound))
					numberOfSpikesFound = spikeDetection[headstage]
				endif
			elseif(numberOfSpikesReq > 1)
				Make/D/FREE/N=0 crossings
				FindLevels/Q/R=(first, last)/N=(numberOfSpikesReq)/DEST=crossings/EDGE=1/B=3 singleAD, level
				spikeDetection[headstage] = IsFinite(numberOfSpikesReq) ? (!V_flag) : (V_LevelsFound > 0)

				if(!ParamIsDefault(spikePositions))
					ASSERT(WaveExists(spikePositions), "Wave spikePositions must exist")
					Redimension/D/N=(V_LevelsFound) spikePositions

					if(spikeDetection[headstage])
						spikePositions[] = crossings[p]
					endif
				endif

				if(!ParamIsDefault(numberOfSpikesFound))
					numberOfSpikesFound = V_LevelsFound
				endif
			else
				ASSERT(0, "Invalid number of spikes value")
			endif
		endif
	endif

	ASSERT(IsFinite(spikeDetection[headstage]), "Expected finite result")

	return DEBUGPRINTw(spikeDetection)
End

/// @brief Return a sweep number of an existing sweep matching the following conditions
///
/// - Acquired with Rheobase analysis function
/// - Set QC passed for this SCI
/// - Pulse duration was longer than `duration`
/// - Spiked
///
/// And as usual we want the *last* matching sweep.
///
/// @return existing sweep number or -1 in case no such sweep could be found
static Function PSQ_GetLastPassingLongRHSweep(string device, variable headstage, variable duration)
	string key
	variable i, j, setSweep, numSetSweeps, numEntries, sweepNo, setQC, numPassingSweeps

	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS, query = 1)
	WAVE/Z sweeps = GetSweepsWithSetting(numericalValues, key)

	if(!WaveExists(sweeps))
		return -1
	endif

	// sweeps hold all which have a Set QC entry
	numEntries = DimSize(sweeps, ROWS)
	for(i = numEntries - 1; i >= 0; i -= 1)
		sweepNo = sweeps[i]

		setQC = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

		if(!setQC)
			// set QC failed
			continue
		endif

		// check that the pulse duration was long enough
		key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_PULSE_DUR, query = 1)
		WAVE/Z setting = GetLastSettingSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

		if(!WaveExists(setting) || setting[headstage] < duration)
			continue
		endif

		// now fetch all sweeps from that SCI
		WAVE/Z setSweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)
		ASSERT(WaveExists(setSweeps), "Passing set but without sweeps is implausible")

		numSetSweeps = DimSize(setSweeps, ROWS)
		for(j = numSetSweeps - 1; j >= 0; j -= 1)
			setSweep = setSweeps[j]
			key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
			WAVE/Z spikeDetect = GetLastSetting(numericalValues, setSweep, key, UNKNOWN_MODE)

			// and return the last spiking one
			if(WaveExists(spikeDetect) && spikeDetect[headstage] == 1)
				return setSweep
			endif
		endfor
	endfor

	return -1
End

/// @brief Return the sweep number of the last sweep using the PSQ_DaScale()
///        analysis function, where the set passes and was in subthreshold mode.
static Function PSQ_GetLastPassingDAScaleSub(device, headstage)
	string device
	variable headstage

	variable numEntries, sweepNo, i, setQC
	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues = GetLBTextualValues(device)

	// PSQ_DaScale with set QC
	key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1)
	WAVE/Z sweeps = GetSweepsWithSetting(numericalValues, key)

	if(!WaveExists(sweeps))
		return -1
	endif

	numEntries = DimSize(sweeps, ROWS)
	for(i = numEntries - 1; i >= 0; i -= 1)
		sweepNo = sweeps[i]

		setQC = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

		if(!setQC)
			// set QC failed
			continue
		endif

		// check for subthreshold operation mode
		key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_OPMODE, query = 1)

		WAVE/T/Z setting = GetLastSettingTextSCI(numericalValues, textualValues, sweepNo, key, headstage, UNKNOWN_MODE)

		if(WaveExists(setting) && !cmpstr(setting[INDEP_HEADSTAGE], PSQ_DS_SUB))
			return sweepNo
		endif
	endfor

	return -1
End

/// @brief Return the DAScale offset for PSQ_DaScale()
///
/// @return DAScale value in pA or NaN on error
Function PSQ_DS_GetDAScaleOffset(device, headstage, opMode)
	string device, opMode
	variable headstage

	variable sweepNo

	if(!cmpstr(opMode, PSQ_DS_SUPRA))
		if(TestOverrideActive())
			return PSQ_DS_OFFSETSCALE_FAKE
		endif

		sweepNo = PSQ_GetLastPassingLongRHSweep(device, headstage, PSQ_RHEOBASE_DURATION)
		if(!IsValidSweepNumber(sweepNo))
			return NaN
		endif

		WAVE numericalValues = GetLBNumericalValues(device)
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
Function PSQ_FoundAtLeastOneSpike(device, sweepNo)
	string device
	variable sweepNo

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

	if(!WaveExists(settings))
		return NaN
	endif

	return Sum(settings) > 0
End

/// @brief Return the QC state of the sampling interval/frequency check and store it also in the labnotebook
static Function PSQ_CheckSamplingFrequencyAndStoreInLabnotebook(string device, variable type, struct AnalysisFunction_V3& s)
	variable samplingFrequency, expected, actual, samplingFrequencyPassed
	string key

	samplingFrequency = AFH_GetAnalysisParamNumerical("SamplingFrequency", s.params, defValue = 50)

	ASSERT(!cmpstr(StringByKey("XUNITS", WaveInfo(s.scaledDACWave, 0)), "ms"), "Unexpected wave x unit")

	// dimension delta [ms]
	actual = 1.0 / (DimDelta(s.scaledDACWave, ROWS) * 1e-3)

	// samplingFrequency [kHz]
	expected = samplingFrequency * 1e3

	samplingFrequencyPassed = CheckIfClose(expected, actual, tol = 1)

	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
	result[INDEP_HEADSTAGE] = samplingFrequencyPassed
	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_SAMPLING_PASS)
	ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

	return samplingFrequencyPassed
End

/// @brief Require parameters from stimset
Function/S PSQ_DAScale_GetParams()
	return "DAScales:wave,OperationMode:string,SamplingMultiplier:variable,[ShowPlot:variable],[OffsetOperator:string]," +        \
		   "[FinalSlopePercent:variable],[MinimumSpikeCount:variable],[MaximumSpikeCount:variable],[DAScaleModifier:variable]," + \
		   "[SamplingFrequency:variable],[BaselineRMSShortThreshold:variable],[BaselineRMSLongThreshold:variable]"
End

Function/S PSQ_DAScale_GetHelp(string name)

	strswitch(name)
		case "DAScales":
			 return "DA Scale Factors in pA"
			 break
		case "OperationMode":
			 return "Operation mode of the analysis function. Can be either \"Sub\" or \"Supra\"."
			 break
		case "SamplingFrequency":
			 return "Required sampling frequency for the acquired data [kHz]. Defaults to 50."
		case "SamplingMultiplier":
			 return "Sampling multiplier, use 1 for no multiplier"
			 break
		case "BaselineRMSShortThreshold":
			 return "Threshold value in mV for the short RMS baseline QC check (defaults to " + num2str(PSQ_RMS_SHORT_THRESHOLD) + ")"
		case "BaselineRMSLongThreshold":
			 return "Threshold value in mV for the long RMS baseline QC check (defaults to " + num2str(PSQ_RMS_LONG_THRESHOLD) + ")"
		case "OffsetOperator":
			 return "[Optional, defaults to \"+\"] Set the math operator to use for "      \
					+ "combining the rheobase DAScale value from the previous run and "    \
					+ "the DAScales values. Valid strings are \"+\" (addition) and \"*\" " \
					+ "(multiplication). Ignored for \"Sub\"."
			 break
		case "ShowPlot":
			 return "[Optional, defaults to true] Show the resistance (\"Sub\") or the f-I (\"Supra\") plot."
			 break
		case "FinalSlopePercent":
			 return "[Optional] As additional passing criteria the slope of the f-I plot must be larger than this value. " \
					+ "Note: The slope is used in percent. Ignored for \"Sub\"."
			 break
		 case "MinimumSpikeCount":
			 return "[Optional] The lower limit of the number of spikes. Ignored for \"Sub\"."
		 case "MaximumSpikeCount":
			 return "[Optional] The upper limit of the number of spikes. Ignored for \"Sub\"."
		 case "DAScaleModifier":
			 return "[Optional] Percentage how the DAScale value is adapted if it is outside of the " \
					+ "MinimumSpikeCount\"/\"MaximumSpikeCount\" band. Ignored for \"Sub\"."
		default:
			 ASSERT(0, "Unimplemented for parameter " + name)
			 break
	endswitch
End

Function/S PSQ_DAScale_CheckParam(string name, struct CheckParametersStruct &s)

	variable val
	string str

	strswitch(name)
		case "BaselineRMSShortThreshold":
		case "BaselineRMSLongThreshold":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val > 0 && val <= 20))
				return "Invalid value " + num2str(val)
			endif
			break
		case "DAScales":
			WAVE/D/Z wv = AFH_GetAnalysisParamWave(name, s.params)
			if(!WaveExists(wv))
				return "Wave must exist"
			endif

			WaveStats/Q/M=1 wv
			if(V_numNans > 0 || V_numInfs > 0)
				return "Wave must neither have NaNs nor Infs"
			endif
			break
		case "OperationMode":
			str = AFH_GetAnalysisParamTextual(name, s.params)
			if(cmpstr(str, PSQ_DS_SUB) && cmpstr(str, PSQ_DS_SUPRA))
				return "Invalid string " + str
			endif
			break
		case "SamplingFrequency":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0 && val <= 1000))
				return "Invalid value " + num2str(val)
			endif
			break
		case "SamplingMultiplier":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsValidSamplingMultiplier(val))
				return "Invalid value " + num2str(val)
			endif
			break
		case "OffsetOperator":
			str = AFH_GetAnalysisParamTextual(name, s.params)
			if(cmpstr(str, "+") && cmpstr(str, "*"))
				return "Invalid string " + str
			endif
			break
		case "ShowPlot":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(val != 0 && val != 1)
				return "Invalid string " + num2str(val)
			endif
			break
		case "FinalSlopePercent":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0 && val <= 100))
				return "Not a precentage"
			endif
			break
		case "MinimumSpikeCount":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0))
				return "Not a positive integer or zero"
			endif
			break
		case "MaximumSpikeCount":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0))
				return "Not a positive integer or zero"
			endif
			break
		case "DAScaleModifier":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0 && val <= 1000))
				return "Not a precentage"
			endif
			break
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
			break
	endswitch

	// check ordering of min/max
	strswitch(name)
		case "MinimumSpikeCount":
		case "MaximumSpikeCount":
			if(AFH_GetAnalysisParamNumerical("MinimumSpikeCount", s.params)    \
			   >= AFH_GetAnalysisParamNumerical("MaximumSpikeCount", s.params))
			   return "The minimum/maximum spike counts are not ordered properly"
		   endif
		   break
	endswitch

	// check that all three are present
	strswitch(name)
		case "MinimumSpikeCount":
		case "MaximumSpikeCount":
		case "DAScaleModifier":
			if(IsNaN(AFH_GetAnalysisParamNumerical("MinimumSpikeCount", s.params))    \
			   || IsNaN(AFH_GetAnalysisParamNumerical("MaximumSpikeCount", s.params)) \
			   || IsNaN(AFH_GetAnalysisParamNumerical("DAScaleModifier", s.params)))
			   return "One of MinimumSpikeCount/MaximumSpikeCount/DAScaleModifier is not present"
		   endif
		   break
   endswitch

   return ""
End

/// @brief Patch Seq Analysis function to find a suitable DAScale
///
/// Prerequisites:
/// - Does only work for one headstage
/// - Assumes that the stimset has 500ms of pre pulse baseline, a 1000ms (#PSQ_DS_PULSE_DUR) pulse and at least 1000ms post pulse baseline.
/// - Each 500ms (#PSQ_DS_BL_EVAL_RANGE_MS) of the baseline is a chunk
///
/// Testing:
/// For testing the spike detection logic, the results can be defined in the override wave,
/// @see PSQ_CreateOverrideResults().
///
/// Reading the results from the labnotebook:
///
/// \rst
/// .. code-block:: igorpro
///
///    WAVE numericalValues = GetLBNumericalValues(device)
///
///    // set properties
///
///    key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASSED, query = 1)
///    setPassed = GetLastSettingIndepSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
///
///    if(setPassed)
///      // set passed
///    else
///      // set did not pass
///    endif
///
///    // single sweep properties
///    key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
///    sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///
///    // chunk (500ms portions of the baseline) properties
///    key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_CHUNK_PASS, chunk = chunk, query = 1)
///    chunkPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///
///    // single test properties
///    key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = chunk, query = 1)
///    rmsShortPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///    key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = chunk, query = 1)
///    rmsLongPassed  = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///    key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_TARGETV_PASS, chunk = chunk, query = 1)
///    targetVPassed  = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///
///    // get fitted resistance from last passing sweep
///    // resistance for the first headstage can be found in resistanceFitted[0]
///    WAVE/Z resistanceFitted = GetLastSettingSCI(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + "ResistanceFromFit", headstage, UNKNOWN_MODE)
/// \endrst
///
/// Decision logic flowchart:
///
/// \rst
/// .. image:: /dot/patch-seq-dascale.svg
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
Function PSQ_DAScale(device, s)
	string device
	STRUCT AnalysisFunction_V3 &s

	variable val, totalOnsetDelay, DAScale, baselineQCPassed
	variable i, numberOfSpikes, samplingFrequencyPassed
	variable index, ret, showPlot, V_AbortCode, V_FitError, err, enoughSweepsPassed
	variable sweepPassed, setPassed, numSweepsPass, length, minLength
	variable minimumSpikeCount, maximumSpikeCount, daScaleModifierParam
	variable sweepsInSet, passesInSet, acquiredSweepsInSet, multiplier
	string msg, stimset, key, opMode, offsetOp, textboxString, str
	variable daScaleOffset = NaN
	variable finalSlopePercent = NaN
	variable daScaleModifier, chunk

	WAVE/D/Z DAScales = AFH_GetAnalysisParamWave("DAScales", s.params)
	opMode = AFH_GetAnalysisParamTextual("OperationMode", s.params)
	multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)

	if(!cmpstr(opMode, PSQ_DS_SUPRA))
		offsetOp = AFH_GetAnalysisParamTextual("OffsetOperator", s.params, defValue = "+")
		finalSlopePercent = AFH_GetAnalysisParamNumerical("FinalSlopePercent", s.params, defValue = NaN)
	else
		offsetOp = "+"
	endif

	numSweepsPass = DimSize(DAScales, ROWS)
	ASSERT(numSweepsPass > 0, "Invalid number of entries in DAScales")

	WAVE DAScalesIndex = GetAnalysisFuncIndexingHelper(device)

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
			PGC_SetAndActivateControl(device, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)

			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", device
				ControlWindowToFront()
				return 1
			endif

			if(DAG_GetHeadstageMode(device, s.headstage) != I_CLAMP_MODE)
				printf "(%s) Clamp mode must be current clamp.\r", device
				ControlWindowToFront()
				return 1
			endif

			length = PSQ_GetDAStimsetLength(device, s.headstage)
			minLength = PSQ_DS_PULSE_DUR + 3 * PSQ_DS_BL_EVAL_RANGE_MS
			if(length < minLength)
				printf "(%s) Stimset of headstage %d is too short, it must be at least %g ms long.\r", device, s.headstage, minLength
				ControlWindowToFront()
				return 1
			endif

			val = DAG_GetNumericalValue(device, "setvar_DataAcq_AutoBiasV")

			if(!IsFinite(val) || CheckIfSmall(val, tol = 1e-12))
				printf "(%s): Autobias value is zero or non-finite\r", device
				ControlWindowToFront()
				return 1
			endif

			DisableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")

			// fallthrough-by-design
		case PRE_SET_EVENT:
			SetAnalysisFunctionVersion(device, PSQ_DA_SCALE, s.headstage, s.sweepNo)

			PSQ_SetSamplingIntervalMultiplier(device, multiplier)

			DAScalesIndex[s.headstage] = 0

			daScaleOffset = PSQ_DS_GetDAScaleOffset(device, s.headstage, opMode)
			if(!IsFinite(daScaleOffset))
				printf "(%s): Could not find a valid DAScale threshold value from previous rheobase runs with long pulses.\r", device
				ControlWindowToFront()
				return 1
			endif

			PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = 1)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 1)

			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleDeltaI(device))
			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleDeltaV(device))
			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleRes(device))
			KillWindow/Z $RESISTANCE_GRAPH
			KillWindow/Z $SPIKE_FREQ_GRAPH

			break
		case POST_SWEEP_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE textualValues   = GetLBTextualValues(device)

			Make/T/FREE/N=(LABNOTEBOOK_LAYER_COUNT) opModeLBN
			opModeLBN[INDEP_HEADSTAGE] = opMode
			key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_OPMODE)
			ED_AddEntryToLabnotebook(device, key, opModeLBN, overrideSweepNo = s.sweepNo)

			daScaleOffset = PSQ_DS_GetDAScaleOffset(device, s.headstage, opMode)

			key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
			WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			ASSERT(WaveExists(baselineQCPassedLBN), "Expected BL QC passed LBN entry")

			samplingFrequencyPassed = PSQ_CheckSamplingFrequencyAndStoreInLabnotebook(device, PSQ_DA_SCALE, s)

			sweepPassed = baselineQCPassedLBN[s.headstage] && samplingFrequencyPassed

			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
			result[INDEP_HEADSTAGE] = sweepPassed
			key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			sprintf msg, "SamplingFrequency %s, Sweep %s\r", ToPassFail(samplingFrequencyPassed), ToPassFail(sweepPassed)
			DEBUGPRINT(msg)

			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) fISlope = NaN

			if(sweepPassed)

				showPlot = AFH_GetAnalysisParamNumerical("ShowPlot", s.params, defValue = 1)

				WAVE/Z sweep = GetSweepWave(device, s.sweepNo)
				ASSERT(WaveExists(sweep), "Expected a sweep for evaluation")

				if(!cmpstr(opMode, PSQ_DS_SUB))
					Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) deltaV     = NaN
					Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) deltaI     = NaN
					Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) resistance = NaN

					CalculateTPLikePropsFromSweep(numericalValues, textualValues, sweep, deltaI, deltaV, resistance)

					ED_AddEntryToLabnotebook(device, "Delta I", deltaI, unit = "A")
					ED_AddEntryToLabnotebook(device, "Delta V", deltaV, unit = "V")

					FitResistance(device, showPlot = showPlot)

				elseif(!cmpstr(opMode, PSQ_DS_SUPRA))
					totalOnsetDelay = DAG_GetNumericalValue(device, "setvar_DataAcq_OnsetDelayUser") \
									  + GetValDisplayAsNum(device, "valdisp_DataAcq_OnsetDelayAuto")

					WAVE spikeDetection = PSQ_SearchForSpikes(device, PSQ_DA_SCALE, sweep, s.headstage, totalOnsetDelay, \
					                                          PSQ_DS_SPIKE_LEVEL, numberOfSpikesReq = inf, numberOfSpikesFound = numberOfSpikes)
					key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SPIKE_DETECT)
					ED_AddEntryToLabnotebook(device, key, spikeDetection, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

					Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) numberOfSpikesLBN = NaN
					numberOfSpikesLBN[s.headstage] = numberOfSpikes
					key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SPIKE_COUNT)
					ED_AddEntryToLabnotebook(device, key, numberOfSpikesLBN, overrideSweepNo = s.sweepNo)

					minimumSpikeCount = AFH_GetAnalysisParamNumerical("MinimumSpikeCount", s.params)
					maximumSpikeCount = AFH_GetAnalysisParamNumerical("MaximumSpikeCount", s.params)
					daScaleModifierParam = AFH_GetAnalysisParamNumerical("DAScaleModifier", s.params) / 100
					if(!IsNaN(daScaleModifierParam))
						if(numberOfSpikes < minimumSpikeCount)
							daScaleModifier = +daScaleModifierParam
						elseif(numberOfSpikes > maximumSpikeCount)
							daScaleModifier = -daScaleModifierParam
						endif
					endif

					WAVE durations = PSQ_DeterminePulseDuration(device, s.sweepNo, PSQ_DA_SCALE, totalOnsetDelay)
					key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_PULSE_DUR)
					ED_AddEntryToLabnotebook(device, key, durations, unit = "ms", overrideSweepNo = s.sweepNo)

					sprintf msg, "Spike detection: result %d, number of spikes %d, pulse duration %d\r", spikeDetection[s.headstage], numberOfSpikesLBN[s.headstage], durations[s.headstage]
					DEBUGPRINT(msg)

					acquiredSweepsInSet = PSQ_NumAcquiredSweepsInSet(device, s.sweepNo, s.headstage)

					ASSERT(acquiredSweepsInSet > 0, "Unexpected number of acquired sweeps")
					WAVE spikeFrequencies = GetAnalysisFuncDAScaleSpikeFreq(device, s.headstage)
					Redimension/N=(acquiredSweepsInSet) spikeFrequencies

					key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SPIKE_COUNT, query = 1)
					WAVE spikeCount = GetLastSettingEachSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
					ASSERT(DimSize(spikeCount, ROWS) == acquiredSweepsInSet, "Mismatched row count")

					key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_PULSE_DUR, query = 1)
					WAVE pulseDuration = GetLastSettingEachSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
					ASSERT(DimSize(pulseDuration, ROWS) == acquiredSweepsInSet, "Mismatched row count")

					spikeFrequencies[] = str2num(FloatWithMinSigDigits(spikeCount[p] / (pulseDuration[p] / 1000), numMinSignDigits = 2))

					WAVE DAScalesPlot = GetAnalysisFuncDAScales(device, s.headstage)
					Redimension/N=(acquiredSweepsInSet) DAScalesPlot

					WAVE DAScalesLBN = GetLastSettingEachSCI(numericalValues, s.sweepNo, STIMSET_SCALE_FACTOR_KEY, \
															 s.headstage, DATA_ACQUISITION_MODE)
					ASSERT(DimSize(DAScalesLBN, ROWS) == acquiredSweepsInSet, "Mismatched row count")
					DAScalesPlot[] = DAScalesLBN[p] * 1e-12

					sprintf msg, "Spike frequency %.2W1PHz, DAScale %.2W1PA", spikeFrequencies[acquiredSweepsInSet - 1], DAScalesPlot[acquiredSweepsInSet - 1]
					DEBUGPRINT(msg)

					AssertOnAndClearRTError()
					try
						V_FitError  = 0
						V_AbortCode = 0

						Make/FREE/D/N=2 coefWave
						CurveFit/Q/N=1/NTHR=1/M=0/W=2 line, kwCWave=coefWave, spikeFrequencies[]/D/X=DAScalesPlot[]; AbortOnRTE

						WAVE/D/Z W_sigma
						if(!WaveExists(W_sigma))
							Make/FREE/D/N=2 W_sigma = NaN
						endif

						fISlope[s.headstage] = coefWave[1]/1e12 * 100

						WAVE fitWave = $(CleanupName("fit_" + NameOfWave(spikeFrequencies), 0))

						WAVE curveFitWave = GetAnalysisFuncDAScaleFreqFit(device, i)
						Duplicate/O fitWave, curveFitWave

						if(showPlot)
							if(WindowExists(SPIKE_FREQ_GRAPH))
								RemoveFromGraph/Z/W=$SPIKE_FREQ_GRAPH $NameOfWave(fitWave)
							else
								Display/K=1/N=$SPIKE_FREQ_GRAPH spikeFrequencies vs DAScalesPlot
								ModifyGraph/W=$SPIKE_FREQ_GRAPH mode=3, zapTZ(left)=1

								AppendToGraph/W=$SPIKE_FREQ_GRAPH curveFitWave

								Label/W=$SPIKE_FREQ_GRAPH left "Spike Frequency (\\U)"
								Label/W=$SPIKE_FREQ_GRAPH bottom "DAScale (\\U)"
							endif

							sprintf str, "\\s(%s) Spike Frequency\r", NameOfWave(spikeFrequencies)
							textBoxString = str

							sprintf str, "\\s(%s) Linear Regression\r", NameOfWave(curveFitWave)
							textBoxString += str

							sprintf str, "Fit parameters:\r"
							textBoxString += str

							sprintf str, "a = %.3g +/- %.3g Hz\r", coefWave[0], W_sigma[0]
							textBoxString += str

							sprintf str, "b = %.3g +/- %.3g Hz/pA\r", coefWave[1]/1e12, W_sigma[1]/1e12
							textBoxString += str

							sprintf str, "Fitted Slope: %.0W1P%%\r", fISlope[s.headstage]
							textBoxString += str
							TextBox/A=RB/C/N=text/W=$SPIKE_FREQ_GRAPH RemoveEnding(textBoxString, "\r")
						endif
					catch
						err = ClearRTError()
						DEBUGPRINT("CurveFit failed with " + num2str(err))
					endtry
				endif
			endif

			sprintf msg, "Fitted Slope: %.0W1P%%\r", fISlope[s.headstage]
			DEBUGPRINT(msg)

			key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_fI_SLOPE)
			ED_AddEntryToLabnotebook(device, key, fISlope, unit = "% of Hz/pA")

			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
			result[INDEP_HEADSTAGE] = IsFinite(finalSlopePercent) && fiSlope[s.headstage] >= finalSlopePercent
			key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			WAVE/T stimsets = GetLastSetting(textualValues, s.sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
			stimset = stimsets[s.headstage]

			sweepsInSet         = IDX_NumberOfSweepsInSet(stimset)
			passesInSet         = PSQ_NumPassesInSet(numericalValues, PSQ_DA_SCALE, s.sweepNo, s.headstage)
			acquiredSweepsInSet = PSQ_NumAcquiredSweepsInSet(device, s.sweepNo, s.headstage)

			sprintf msg, "Sweep %s, BL QC %s, total sweeps %d, acquired sweeps %d, passed sweeps %d, required passes %d, DAScalesIndex %d\r", ToPassFail(sweepPassed), ToPassFail(baselineQCPassed), sweepsInSet, acquiredSweepsInSet, passesInSet, numSweepsPass, DAScalesIndex[s.headstage]
			DEBUGPRINT(msg)

			if(!sweepPassed)
				// not enough sweeps left to pass the set
				if((sweepsInSet - acquiredSweepsInSet) < (numSweepsPass - passesInSet))
					PSQ_ForceSetEvent(device, s.headstage)
					RA_SkipSweeps(device, inf)
					return NaN
				endif

				if(!samplingFrequencyPassed)
					PSQ_ForceSetEvent(device, s.headstage)
					RA_SkipSweeps(device, inf)
					return NaN
				endif
			else
				if(passesInSet >= numSweepsPass)
					PSQ_ForceSetEvent(device, s.headstage)
					RA_SkipSweeps(device, inf, limitToSetBorder = 1)
					return NaN
				else
					// set next DAScale value
					DAScalesIndex[s.headstage] += 1
				endif
			endif

			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)

			enoughSweepsPassed = PSQ_NumPassesInSet(numericalValues, PSQ_DA_SCALE, s.sweepNo, s.headstage) >= numSweepsPass

			if(!cmpstr(opMode, PSQ_DS_SUPRA))
				key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED, query = 1)
				WAVE fISlopeReached = GetLastSettingIndepEachSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

				if(IsFinite(finalSlopePercent))
					setPassed = enoughSweepsPassed && Sum(fISlopeReached) > 0
				else
					sprintf msg, "Final slope percentage not present\r"
					DEBUGPRINT(msg)

					setPassed = enoughSweepsPassed
				endif
			elseif(!cmpstr(opMode, PSQ_DS_SUB))
				setPassed = enoughSweepsPassed
			endif

			sprintf msg, "Set has %s\r", ToPassFail(setPassed)
			DEBUGPRINT(msg)

			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
			result[INDEP_HEADSTAGE] = setPassed
			key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			AD_UpdateAllDatabrowser()

			break
		case POST_DAQ_EVENT:
			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
	endswitch

	if(s.eventType == PRE_DAQ_EVENT || s.eventType == PRE_SET_EVENT || s.eventType == POST_SWEEP_EVENT)
		WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

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

				strswitch(offsetOp)
					case "+":
						DAScale = DAScales[index] * (1 + daScaleModifier) + daScaleOffset
						break
					case "*":
						DAScale = DAScales[index] * (1 + daScaleModifier) * daScaleOffset
						break
					default:
						ASSERT(0, "Invalid case")
						break
				endswitch
				SetDAScale(device, i, absolute=DAScale * 1e-12)
			endif
		endfor
	endif

	if(s.eventType != MID_SWEEP_EVENT)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
	baselineQCPassed = WaveExists(baselineQCPassedLBN) ? baselineQCPassedLBN[s.headstage] : 0

	if(baselineQCPassed) // already done
		return NaN
	endif

	[ret, chunk] = PSQ_EvaluateBaselineChunks(device, PSQ_DA_SCALE, s)

	return PSQ_EvaluateBaselinePassed(device, PSQ_DA_SCALE, s.sweepNo, s.headstage, chunk, ret)
End

/// @brief Return a list of required parameters
Function/S PSQ_SquarePulse_GetParams()
	return "SamplingMultiplier:variable,[SamplingFrequency:variable],[BaselineRMSShortThreshold:variable],[BaselineRMSLongThreshold:variable]"
End

Function/S PSQ_SquarePulse_GetHelp(string name)

	strswitch(name)
		case "SamplingMultiplier":
			 return "Use 1 for no multiplier"
			 break
		 case "SamplingFrequency":
			 return "Required sampling frequency for the acquired data [kHz]. Defaults to 50."
		 case "BaselineRMSShortThreshold":
			 return "Threshold value in mV for the short RMS baseline QC check (defaults to " + num2str(PSQ_RMS_SHORT_THRESHOLD) + ")"
		 case "BaselineRMSLongThreshold":
			 return "Threshold value in mV for the long RMS baseline QC check (defaults to " + num2str(PSQ_RMS_LONG_THRESHOLD) + ")"
		default:
			 ASSERT(0, "Unimplemented for parameter " + name)
			 break
	endswitch
End

Function/S PSQ_SquarePulse_CheckParam(string name, struct CheckParametersStruct &s)

	variable val

	strswitch(name)
		case "BaselineRMSShortThreshold":
		case "BaselineRMSLongThreshold":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val > 0 && val <= 20))
				return "Invalid value " + num2str(val)
			endif
			break
		case "SamplingMultiplier":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsValidSamplingMultiplier(val))
				return "Invalid value " + num2str(val)
			endif
			break
		case "SamplingFrequency":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0 && val <= 1000))
				return "Invalid value " + num2str(val)
			endif
			break
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
			break
	endswitch
End

/// @brief Analysis function to find the smallest DAScale where the cell spikes
///
/// Prerequisites:
/// - Does only work for one headstage
/// - Assumes that the stimset has a pulse
///
/// Testing:
/// For testing the spike detection logic, the results can be defined in the override wave,
/// @see PSQ_CreateOverrideResults().
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: /dot/patch-seq-squarepulse.svg
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
Function PSQ_SquarePulse(device, s)
	string device
	STRUCT AnalysisFunction_V3 &s

	variable stepsize, DAScale, totalOnsetDelay, setPassed, sweepPassed, multiplier
	variable val, samplingFrequencyPassed
	string key, msg

	multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", device
				ControlWindowToFront()
				return 1
			endif

			PGC_SetAndActivateControl(device, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)

			if(DAG_GetHeadstageMode(device, s.headstage) != I_CLAMP_MODE)
				printf "(%s) Clamp mode must be current clamp.\r", device
				ControlWindowToFront()
				return 1
			endif

			DisableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")

			// fallthrough-by-design
		case PRE_SET_EVENT:
			SetAnalysisFunctionVersion(device, PSQ_SQUARE_PULSE, s.headstage, s.sweepNo)

			PSQ_SetSamplingIntervalMultiplier(device, multiplier)

			PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 1)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 0)
			PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = 0)

			PSQ_StoreStepSizeInLBN(device, PSQ_SQUARE_PULSE, s.sweepNo, PSQ_SP_INIT_AMP_p100)
			SetDAScale(device, s.headstage, absolute=PSQ_SP_INIT_AMP_p100)

			return 0

			break
		case POST_SWEEP_EVENT:
			WAVE sweepWave = GetSweepWave(device, s.sweepNo)
			WAVE numericalValues = GetLBNumericalValues(device)

			totalOnsetDelay = GetTotalOnsetDelay(numericalValues, s.sweepNo)

			WAVE spikeDetection = PSQ_SearchForSpikes(device, PSQ_SQUARE_PULSE, sweepWave, s.headstage, \
			                                          totalOnsetDelay, PSQ_SPIKE_LEVEL)
			key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DETECT)
			ED_AddEntryToLabnotebook(device, key, spikeDetection, unit = LABNOTEBOOK_BINARY_UNIT)

			key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_STEPSIZE, query = 1)
			stepSize = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
			WAVE DAScalesLBN = GetLastSetting(numericalValues, s.sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
			DAScale = DAScalesLBN[s.headstage] * 1e-12

			samplingFrequencyPassed = PSQ_CheckSamplingFrequencyAndStoreInLabnotebook(device, PSQ_SQUARE_PULSE, s)

			sweepPassed = 0

			sprintf msg, "DAScale %g, stepSize %g", DAScale, stepSize
			DEBUGPRINT(msg)

			if(spikeDetection[s.headstage]) // headstage spiked
				if(CheckIfSmall(DAScale, tol = 1e-14))
					Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) value = NaN
					value[INDEP_HEADSTAGE] = 1
					key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO)
					ED_AddEntryToLabnotebook(device, key, value, unit = LABNOTEBOOK_BINARY_UNIT)

					key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
					WAVE spikeWithDAScaleZero = GetLastSettingIndepEachSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
					WAVE spikeWithDAScaleZeroReduced = ZapNaNs(spikeWithDAScaleZero)
					if(DimSize(spikeWithDAScaleZeroReduced, ROWS) == PSQ_NUM_MAX_DASCALE_ZERO)
						PSQ_ForceSetEvent(device, s.headstage)
						RA_SkipSweeps(device, inf, limitToSetBorder = 1)
					endif
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_m50))
					SetDAScale(device, s.headstage, absolute=DAScale + stepsize)
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_p10))
					Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) value = NaN
					value[INDEP_HEADSTAGE] = DAScale
					key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE)
					ED_AddEntryToLabnotebook(device, key, value)

					sweepPassed = samplingFrequencyPassed

					if(sweepPassed)
						PSQ_ForceSetEvent(device, s.headstage)
						RA_SkipSweeps(device, inf, limitToSetBorder = 1)
					endif
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_p100))
					PSQ_StoreStepSizeInLBN(device, PSQ_SQUARE_PULSE, s.sweepNo, PSQ_SP_INIT_AMP_m50)
					stepsize = PSQ_SP_INIT_AMP_m50
					SetDAScale(device, s.headstage, absolute=DAScale + stepsize)
				else
					ASSERT(0, "Unknown stepsize")
				endif
			else // headstage did not spike
				if(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_m50))
					PSQ_StoreStepSizeInLBN(device, PSQ_SQUARE_PULSE, s.sweepNo, PSQ_SP_INIT_AMP_p10)
					stepsize = PSQ_SP_INIT_AMP_p10
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_p10))
					// do nothing
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_p100))
					// do nothing
				else
					ASSERT(0, "Unknown stepsize")
				endif

				SetDAScale(device, s.headstage, absolute=DAScale + stepsize)
			endif

			sprintf msg, "Sweep has %s\r", ToPassFail(sweepPassed)
			DEBUGPRINT(msg)

			Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) value = NaN
			value[INDEP_HEADSTAGE] = sweepPassed
			key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(device, key, value, unit = LABNOTEBOOK_BINARY_UNIT)

			if(!samplingFrequencyPassed)
				PSQ_ForceSetEvent(device, s.headstage)
				RA_SkipSweeps(device, inf, limitToSetBorder = 1)
			endif

			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)

			setPassed = PSQ_NumPassesInSet(numericalValues, PSQ_SQUARE_PULSE, s.sweepNo, s.headstage) >= 1

			if(!setPassed)
				PSQ_ForceSetEvent(device, s.headstage)
				RA_SkipSweeps(device, inf)
			endif

			sprintf msg, "Set has %s\r", ToPassFail(setPassed)
			DEBUGPRINT(msg)

			Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
			result[INDEP_HEADSTAGE] = setPassed
			key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			AD_UpdateAllDatabrowser()

			break
		case POST_DAQ_EVENT:
			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
		default:
			// do nothing
			break
	endswitch

	return NaN
End

/// @brief Return a list of required parameters
Function/S PSQ_Rheobase_GetParams()
	return "SamplingMultiplier:variable,[SamplingFrequency:variable],[BaselineRMSShortThreshold:variable],[BaselineRMSLongThreshold:variable]"
End

Function/S PSQ_Rheobase_GetHelp(string name)

	strswitch(name)
		case "SamplingMultiplier":
			 return "Use 1 for no multiplier"
			 break
		 case "SamplingFrequency":
			 return "Required sampling frequency for the acquired data [kHz]. Defaults to 50."
		 case "BaselineRMSShortThreshold":
			 return "Threshold value in mV for the short RMS baseline QC check (defaults to " + num2str(PSQ_RMS_SHORT_THRESHOLD) + ")"
		 case "BaselineRMSLongThreshold":
			 return "Threshold value in mV for the long RMS baseline QC check (defaults to " + num2str(PSQ_RMS_LONG_THRESHOLD) + ")"
		default:
			 ASSERT(0, "Unimplemented for parameter " + name)
			 break
	endswitch
End

Function/S PSQ_Rheobase_CheckParam(string name, struct CheckParametersStruct &s)

	variable val

	strswitch(name)
		case "BaselineRMSShortThreshold":
		case "BaselineRMSLongThreshold":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val > 0 && val <= 20))
				return "Invalid value " + num2str(val)
			endif
			break
		case "SamplingMultiplier":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsValidSamplingMultiplier(val))
				return "Invalid value " + num2str(val)
			endif
			break
		case "SamplingFrequency":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0 && val <= 1000))
				return "Invalid value " + num2str(val)
			endif
			break
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
			break
	endswitch
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
/// For testing the spike detection logic, the results can be defined in the override wave,
/// @see PSQ_CreateOverrideResults().
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: /dot/patch-seq-rheobase.svg
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
Function PSQ_Rheobase(device, s)
	string device
	STRUCT AnalysisFunction_V3 &s

	variable DAScale, val, numSweeps, currentSweepHasSpike, lastSweepHasSpike, setPassed, diff
	variable baselineQCPassed, finalDAScale, initialDAScale, stepSize, previousStepSize, samplingFrequencyPassed
	variable totalOnsetDelay
	variable i, ret, numSweepsWithSpikeDetection, sweepNoFound, length, minLength, multiplier, chunk
	string key, msg

	multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			PGC_SetAndActivateControl(device, "SetVar_DataAcq_SetRepeats", val = 1)
			PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
			PGC_SetAndActivateControl(device, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)

			if(DAG_GetHeadstageMode(device, s.headstage) != I_CLAMP_MODE)
				printf "(%s) Clamp mode must be current clamp.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", device
				ControlWindowToFront()
				return 1
			endif

			length = PSQ_GetDAStimsetLength(device, s.headstage)
			minLength = PSQ_RB_PRE_BL_EVAL_RANGE + 2 * PSQ_RB_POST_BL_EVAL_RANGE
			if(length < minLength)
				printf "(%s) Stimset of headstage %d is too short, it must be at least %g ms long.\r", device, s.headstage, minLength
				ControlWindowToFront()
				return 1
			endif

			val = DAG_GetNumericalValue(device, "setvar_DataAcq_AutoBiasV")

			if(!IsFinite(val) || CheckIfSmall(val, tol = 1e-12))
				printf "(%s): Autobias value is zero or non-finite\r", device
				ControlWindowToFront()
				return 1
			endif

			DisableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")

			// fallthrough-by-design
		case PRE_SET_EVENT:
			SetAnalysisFunctionVersion(device, PSQ_RHEOBASE, s.headstage, s.sweepNo)

			PSQ_SetSamplingIntervalMultiplier(device, multiplier)

			PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 4)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 1)
			PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = 1)

			WAVE numericalValues = GetLBNumericalValues(device)
			key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
			finalDAScale = GetLastSweepWithSettingIndep(numericalValues, key, sweepNoFound)

			if(!IsFinite(finalDAScale) || CheckIfSmall(finalDAScale, tol = 1e-14) || !IsValidSweepNumber(sweepNoFound))
				printf "(%s): Could not find final DAScale value from one of the previous analysis functions.\r", device
				if(TestOverrideActive())
					finalDASCale = PSQ_GetFinalDAScaleFake()
				else
					ControlWindowToFront()
					return 1
				endif
			endif

			SetDAScale(device, s.headstage, absolute=finalDAScale)

			return 0

			break
		case POST_SWEEP_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE sweeps = AFH_GetSweepsFromSameSCI(numericalValues, s.sweepNo, s.headstage)

			numSweeps = DimSize(sweeps, ROWS)

			if(numSweeps == 1)
				// query the initial DA scale from the previous sweep (which is from a different RAC)
				key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
				finalDAScale = GetLastSweepWithSettingIndep(numericalValues, key, sweepNoFound)
				if(TestOverrideActive())
					finalDAScale = PSQ_GetFinalDAScaleFake()
				else
					ASSERT(IsFinite(finalDAScale) && IsValidSweepNumber(sweepNoFound), "Could not find final DAScale value from previous analysis function")
				endif

				// and set it as the initial DAScale for this SCI
				Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
				result[INDEP_HEADSTAGE] = finalDAScale
				key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_INITIAL_SCALE)
				ED_AddEntryToLabnotebook(device, key, result)

				PSQ_StoreStepSizeInLBN(device, PSQ_RHEOBASE, s.sweepNo, PSQ_RB_DASCALE_STEP_LARGE, future = 1)
			endif

			// store the future step size as the step size of the current sweep
			key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_STEPSIZE_FUTURE, query = 1)
			stepSize = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
			PSQ_StoreStepSizeInLBN(device, PSQ_RHEOBASE, s.sweepNo, stepSize)

			samplingFrequencyPassed = PSQ_CheckSamplingFrequencyAndStoreInLabnotebook(device, PSQ_RHEOBASE, s)

			sprintf msg, "numSweeps %d, baselineQCPassed %d, samplingFrequencyPassed %d", numSweeps, baselineQCPassed, samplingFrequencyPassed
			DEBUGPRINT(msg)

			if(!samplingFrequencyPassed)
				Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
				key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS)
				result[INDEP_HEADSTAGE] = 0
				ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

				PSQ_ForceSetEvent(device, s.headstage)
				RA_SkipSweeps(device, inf, limitToSetBorder = 1)
				break
			endif

			key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
			WAVE/Z baselineQCPassedWave = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)

			baselineQCPassed = WaveExists(baselineQCPassedWave) && baselineQCPassedWave[s.headstage]

			if(!baselineQCPassed)
				break
			endif

			// search for spike and store result
			WAVE sweepWave = GetSweepWave(device, s.sweepNo)
			WAVE numericalValues = GetLBNumericalValues(device)

			totalOnsetDelay = GetTotalOnsetDelay(numericalValues, s.sweepNo)

			WAVE spikeDetection = PSQ_SearchForSpikes(device, PSQ_RHEOBASE, sweepWave, s.headstage, totalOnsetDelay, \
			                                          PSQ_SPIKE_LEVEL)
			key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SPIKE_DETECT)
			ED_AddEntryToLabnotebook(device, key, spikeDetection, unit = LABNOTEBOOK_BINARY_UNIT)

			key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
			WAVE spikeDetectionRA = GetLastSettingEachSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			DEBUGPRINT("spikeDetectionRA: ", wv = spikeDetectionRA)

			numSweepsWithSpikeDetection = DimSize(spikeDetectionRA, ROWS)
			currentSweepHasSpike        = spikeDetectionRA[numSweepsWithSpikeDetection - 1]

			WAVE DAScalesLBN = GetLastSetting(numericalValues, s.sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
			DAScale = DAScalesLBN[s.headstage] * 1e-12

			if(numSweepsWithSpikeDetection >= 2)
				lastSweepHasSpike = spikeDetectionRA[numSweepsWithSpikeDetection - 2]

				key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_STEPSIZE, query = 1)
				stepSize = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
				previousStepSize = GetLastSettingIndep(numericalValues, s.sweepNo - 1, key, UNKNOWN_MODE)

				if(IsFinite(currentSweepHasSpike) && IsFinite(lastSweepHasSpike) \
				   && (currentSweepHasSpike != lastSweepHasSpike)                \
				   && (CheckIfClose(stepSize, previousStepSize)))

					key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_STEPSIZE_FUTURE, query = 1)
					stepSize = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

					if(DAScale <= PSQ_RB_DASCALE_SMALL_BORDER && CheckIfClose(stepSize, PSQ_RB_DASCALE_STEP_LARGE))
						PSQ_StoreStepSizeInLBN(device, PSQ_RHEOBASE, s.sweepNo, PSQ_RB_DASCALE_STEP_SMALL, future = 1)
					else
						// mark the set as passed
						// we can't mark each sweep as passed/failed as it is not possible
						// to add LBN entries to other sweeps than the last one
						Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
						key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS)
						result[INDEP_HEADSTAGE] = 1
						ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)
						PSQ_ForceSetEvent(device, s.headstage)
						RA_SkipSweeps(device, inf, limitToSetBorder = 1)

						DEBUGPRINT("Sweep has passed")
						break
					endif
				endif
			endif

			// fetch the future step size
			key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_STEPSIZE_FUTURE, query = 1)
			stepSize = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
			if(currentSweepHasSpike)
				DAScale -= stepSize
			else
				DAScale += stepSize
			endif

			if(CheckIfSmall(DaScale, tol = 1e-14) && currentSweepHasSpike)
				// future DAScale would be zero
				if(CheckIfClose(stepSize, PSQ_RB_DASCALE_STEP_SMALL))
					// mark set as failure
					Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
					key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS)
					result[INDEP_HEADSTAGE] = 0
					ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

					key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_LIMITED_RES)
					result              = NaN
					result[s.headstage] = 1
					ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

					PSQ_ForceSetEvent(device, s.headstage)
					RA_SkipSweeps(device, inf)

					DEBUGPRINT("Set has failed")
					break
				elseif(CheckIfClose(stepSize, PSQ_RB_DASCALE_STEP_LARGE))
					// retry with much smaller values
					PSQ_StoreStepSizeInLBN(device, PSQ_RHEOBASE, s.sweepNo, PSQ_RB_DASCALE_STEP_SMALL, future = 1)

					key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_STEPSIZE_FUTURE, query = 1)
					stepSize = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

					DAScale = PSQ_RB_DASCALE_STEP_SMALL
				else
					ASSERT(0, "Unknown step size")
				endif
			endif

			key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_INITIAL_SCALE, query = 1)
			initialDAScale = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			diff = abs(DAScale - initialDAScale)
			if(diff > PSQ_RB_MAX_DASCALE_DIFF || CheckIfClose(diff, PSQ_RB_MAX_DASCALE_DIFF))
				// mark set as failure
				Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
				key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS)
				result[INDEP_HEADSTAGE] = 0
				ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

				result              = NaN
				result[s.headstage] = 1

				key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_DASCALE_EXC)
				ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

				PSQ_ForceSetEvent(device, s.headstage)
				RA_SkipSweeps(device, inf)

				DEBUGPRINT("Set has failed")
				break
			endif

			SetDAScale(device, s.headstage, absolute=DAScale)
			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS, query = 1)
			setPassed = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			// if we don't have an entry yet for the set passing, it has failed
			if(!IsFinite(setPassed))
				key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS)
				Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
				result[INDEP_HEADSTAGE] = 0
				ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

				PSQ_ForceSetEvent(device, s.headstage)
				RA_SkipSweeps(device, inf)

				DEBUGPRINT("Set has failed")
			endif

			key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_DASCALE_EXC, query = 1)
			WAVE/Z rangeExceeded = GetLastSettingSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			if(!WaveExists(rangeExceeded))
				Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
				result[s.headstage] = 0
				key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_DASCALE_EXC)
				ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)
			endif

			key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_LIMITED_RES, query = 1)
			WAVE/Z limitedResolution = GetLastSettingSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			if(!WaveExists(limitedResolution))
				Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
				result[s.headstage] = 0
				key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_LIMITED_RES)
				ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)
			endif

			AD_UpdateAllDatabrowser()

			break
		case POST_DAQ_EVENT:
			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
	endswitch

	if(s.eventType != MID_SWEEP_EVENT)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
	baselineQCPassed = WaveExists(baselineQCPassedLBN) ? baselineQCPassedLBN[s.headstage] : 0

	if(baselineQCPassed)
		return NaN
	endif

	[ret, chunk] = PSQ_EvaluateBaselineChunks(device, PSQ_RHEOBASE, s)

	return PSQ_EvaluateBaselinePassed(device, PSQ_RHEOBASE, s.sweepNo, s.headstage, chunk, ret)
End

Function PSQ_GetFinalDAScaleFake()

	variable daScale

	ASSERT(TestOverrideActive(), "Should not be called in production.")

	WAVE overrideResults = GetOverrideResults()
	ASSERT(WaveExists(overrideResults), "overrideResults wave must exist")

	daScale = GetNumberFromWaveNote(overrideResults, PSQ_RB_FINALSCALE_FAKE_KEY)
	ASSERT(IsFinite(daScale), "Missing fake DAScale for PatchSeq Rheobase")
	return daScale
End

/// @brief Return a list of required parameters
Function/S PSQ_Ramp_GetParams()
	return "NumberOfSpikes:variable,SamplingMultiplier:variable,[SamplingFrequency:variable],[BaselineRMSShortThreshold:variable],[BaselineRMSLongThreshold:variable]"
End

Function/S PSQ_Ramp_GetHelp(string name)

	strswitch(name)
		 case "SamplingFrequency":
			 return "Required sampling frequency for the acquired data [kHz]. Defaults to 50."
		case "SamplingMultiplier":
			 return "Use 1 for no multiplier"
			 break
		 case "BaselineRMSShortThreshold":
			 return "Threshold value in mV for the short RMS baseline QC check (defaults to " + num2str(PSQ_RMS_SHORT_THRESHOLD) + ")"
		 case "BaselineRMSLongThreshold":
			 return "Threshold value in mV for the long RMS baseline QC check (defaults to " + num2str(PSQ_RMS_LONG_THRESHOLD) + ")"
		 case "NumberOfSpikes":
			return "Number of spikes required to be found after the pulse onset " \
			 + "in order to label the cell as having \"spiked\"."
		 default:
			ASSERT(0, "Unimplemented for parameter " + name)
			break
	endswitch
End

Function/S PSQ_Ramp_CheckParam(string name, struct CheckParametersStruct &s)

	variable val

	strswitch(name)
		case "BaselineRMSShortThreshold":
		case "BaselineRMSLongThreshold":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val > 0 && val <= 20))
				return "Invalid value " + num2str(val)
			endif
			break
		case "SamplingMultiplier":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsValidSamplingMultiplier(val))
				return "Invalid value " + num2str(val)
			endif
			break
		case "NumberOfSpikes":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val > 0))
				return "Invalid value " + num2str(val)
			endif
			break
		case "SamplingFrequency":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0 && val <= 1000))
				return "Invalid value " + num2str(val)
			endif
			break
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
			break
	endswitch
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
/// For testing the spike detection logic, the results can be defined in the override wave,
/// @see PSQ_CreateOverrideResults().
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: /dot/patch-seq-ramp.svg
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
Function PSQ_Ramp(device, s)
	string device
	STRUCT AnalysisFunction_V3 &s

	variable DAScale, val, numSweeps, currentSweepHasSpike, setPassed
	variable baselineQCPassed, finalDAScale, initialDAScale, samplingFrequencyPassed
	variable lastFifoPos, totalOnsetDelay, fifoInStimsetPoint, fifoInStimsetTime
	variable i, ret, numSweepsWithSpikeDetection, sweepNoFound, length, minLength
	variable DAC, sweepPassed, sweepsInSet, passesInSet, acquiredSweepsInSet, enoughSpikesFound
	variable pulseStart, pulseDuration, fifoPos, fifoOffset, numberOfSpikes, multiplier, chunk
	string key, msg, stimset
	string fifoname
	variable hardwareType

	numberOfSpikes = AFH_GetAnalysisParamNumerical("NumberOfSpikes", s.params)
	multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
			PGC_SetAndActivateControl(device, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)

			if(DAG_GetHeadstageMode(device, s.headstage) != I_CLAMP_MODE)
				printf "(%s) Clamp mode must be current clamp.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", device
				ControlWindowToFront()
				return 1
			endif

			length = PSQ_GetDAStimsetLength(device, s.headstage)
			minLength = 3 * PSQ_RA_BL_EVAL_RANGE
			if(length < minLength)
				printf "(%s) Stimset of headstage %d is too short, it must be at least %g ms long.\r", device, s.headstage, minLength
				ControlWindowToFront()
				return 1
			endif

			val = DAG_GetNumericalValue(device, "setvar_DataAcq_AutoBiasV")

			if(!IsFinite(val) || CheckIfSmall(val, tol = 1e-12))
				printf "(%s): Autobias value is zero or non-finite\r", device
				ControlWindowToFront()
				return 1
			endif

			DAC = AFH_GetDACFromHeadstage(device, s.headstage)
			stimset = AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC)
			if(IDX_NumberOfSweepsInSet(stimset) < PSQ_RA_NUM_SWEEPS_PASS)
				printf "(%s): The stimset must have at least %d sweeps\r", device, PSQ_RA_NUM_SWEEPS_PASS
				ControlWindowToFront()
				return 1
			endif

			DisableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")

			// fallthrough-by-design
		case PRE_SET_EVENT:
			SetAnalysisFunctionVersion(device, PSQ_RAMP, s.headstage, s.sweepNo)

			PSQ_SetSamplingIntervalMultiplier(device, multiplier)

			PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 0)
			PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = 1)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 1)

			SetDAScale(device, s.headstage, absolute=PSQ_RA_DASCALE_DEFAULT * 1e-12)

			return 0

			break
		case POST_SWEEP_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE textualValues   = GetLBTextualValues(device)

			key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
			WAVE baselinePassed = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)

			samplingFrequencyPassed = PSQ_CheckSamplingFrequencyAndStoreInLabnotebook(device, PSQ_RAMP, s)

			sweepPassed = baselinePassed[s.headstage] && samplingFrequencyPassed

			Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
			result[INDEP_HEADSTAGE] = sweepPassed
			key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			WAVE/T stimsets = GetLastSetting(textualValues, s.sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
			stimset = stimsets[s.headstage]

			sweepsInSet         = IDX_NumberOfSweepsInSet(stimset)
			passesInSet         = PSQ_NumPassesInSet(numericalValues, PSQ_RAMP, s.sweepNo, s.headstage)
			acquiredSweepsInSet = PSQ_NumAcquiredSweepsInSet(device, s.sweepNo, s.headstage)

			if(!sweepPassed)
				// not enough sweeps left to pass the set
				if((sweepsInSet - acquiredSweepsInSet) < (PSQ_RA_NUM_SWEEPS_PASS - passesInSet))
					PSQ_ForceSetEvent(device, s.headstage)
					RA_SkipSweeps(device, inf)
				elseif(!samplingFrequencyPassed)
					PSQ_ForceSetEvent(device, s.headstage)
					RA_SkipSweeps(device, inf)
				endif
			else
				if(passesInSet >= PSQ_RA_NUM_SWEEPS_PASS)
					PSQ_ForceSetEvent(device, s.headstage)
					RA_SkipSweeps(device, inf, limitToSetBorder = 1)
				endif
			endif

			sprintf msg, "Sweep %s, total sweeps %d, acquired sweeps %d, sweeps passed %d, required passes %d\r", ToPassFail(sweepPassed), sweepsInSet, acquiredSweepsInSet, passesInSet, PSQ_RA_NUM_SWEEPS_PASS
			DEBUGPRINT(msg)

			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)

			setPassed = PSQ_NumPassesInSet(numericalValues, PSQ_RAMP, s.sweepNo, s.headstage) >= PSQ_RA_NUM_SWEEPS_PASS

			sprintf msg, "Set has %s\r", ToPassFail(setPassed)
			DEBUGPRINT(msg)

			Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
			result[INDEP_HEADSTAGE] = setPassed
			key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			AD_UpdateAllDatabrowser()

			break
		case POST_DAQ_EVENT:
			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
	endswitch

	if(s.eventType != MID_SWEEP_EVENT)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
	baselineQCPassed = WaveExists(baselineQCPassedLBN) ? baselineQCPassedLBN[s.headstage] : 0

	enoughSpikesFound = PSQ_FoundAtLeastOneSpike(device, s.sweepNo)

	sprintf msg, "enoughSpikesFound %g, baselineQCPassed %d", enoughSpikesFound, baselineQCPassed
	DEBUGPRINT(msg)

	if(IsFinite(enoughSpikesFound) && baselineQCPassed) // spike already found/definitly not found and baseline QC passed
		return NaN
	endif

	totalOnsetDelay = DAG_GetNumericalValue(device, "setvar_DataAcq_OnsetDelayUser") \
					  + GetValDisplayAsNum(device, "valdisp_DataAcq_OnsetDelayAuto")

	fifoInStimsetPoint = s.lastKnownRowIndex - totalOnsetDelay / DimDelta(s.rawDACWAVE, ROWS)
	fifoInStimsetTime  = fifoInStimsetPoint * DimDelta(s.rawDACWAVE, ROWS)

	WAVE durations = PSQ_GetPulseDurations(device, PSQ_RAMP, s.sweepNo, totalOnsetDelay)
	pulseStart     = PSQ_RA_BL_EVAL_RANGE
	pulseDuration  = durations[s.headstage]

	if(IsNaN(enoughSpikesFound) && fifoInStimsetTime >= pulseStart) // spike search was inconclusive up to now
																	// and we are after the pulse onset

		Make/FREE/D spikePos
		WAVE spikeDetection = PSQ_SearchForSpikes(device, PSQ_RAMP, s.rawDACWave, s.headstage, \
		                                          totalOnsetDelay, PSQ_SPIKE_LEVEL, spikePositions = spikePos, numberOfSpikesReq = numberOfSpikes)

		if(spikeDetection[s.headstage] \
		   && ((TestOverrideActive() && (fifoInStimsetTime > WaveMax(spikePos))) || !TestOverrideActive()))

			enoughSpikesFound = 1

			key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_DETECT)
			ED_AddEntryToLabnotebook(device, key, spikeDetection, overrideSweepNo = s.sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)

			Make/FREE/T/N=(LABNOTEBOOK_LAYER_COUNT) resultTxT
			resultTxT[s.headstage] = NumericWaveToList(spikePos, ";")
			key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_POSITIONS)
			ED_AddEntryToLabnotebook(device, key, resultTxT, overrideSweepNo = s.sweepNo, unit = "ms")

			NVAR deviceID = $GetDAQDeviceID(device)
			NVAR ADChannelToMonitor = $GetADChannelToMonitor(device)

			hardwareType = GetHardwareType(device)
			if(hardwareType == HARDWARE_ITC_DAC)

				// stop DAQ, set DA to zero from now to the end and start DAQ again

				// fetch the very last fifo position immediately before we stop it
				NVAR tgID = $GetThreadGroupIDFIFO(device)
				fifoOffset = TS_GetNewestFromThreadQueue(tgID, "fifoPos")
				TFH_StopFIFODaemon(HARDWARE_ITC_DAC, deviceID)
				HW_StopAcq(HARDWARE_ITC_DAC, deviceID)
				HW_ITC_PrepareAcq(deviceID, DATA_ACQUISITION_MODE, offset=fifoOffset)

				WAVE wv = s.rawDACWave

				sprintf msg, "DA black out: [%g, %g]\r", fifoOffset, inf
				DEBUGPRINT(msg)

				SetWaveLock 0, wv
				Multithread wv[fifoOffset, inf][0, ADChannelToMonitor - 1] = 0
				SetWaveLock 1, wv

				PSQ_Ramp_AddEpoch(device, s.headstage, wv, "Name=DA Suppression", "RA_DS", fifoOffset, DimSize(wv, ROWS) - 1)

				HW_StartAcq(HARDWARE_ITC_DAC, deviceID)
				TFH_StartFIFOStopDaemon(HARDWARE_ITC_DAC, deviceID)

				// fetch newest fifo position, blocks until it gets a valid value
				// its zero is now fifoOffset
				NVAR tgID = $GetThreadGroupIDFIFO(device)
				fifoPos = TS_GetNewestFromThreadQueue(tgID, "fifoPos")
				ASSERT(fifoPos > 0, "Invalid fifo position, has the thread died?")

				// wait until the hardware is finished with writing this chunk
				// this is to avoid that two threads write simultaneously into the DAQDataWave
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

				PSQ_Ramp_AddEpoch(device, s.headstage, wv, "Name=Unacquired DA data", "RA_UD", fifoOffset, fifoOffset + fifoPos)

			elseif(hardwareType == HARDWARE_NI_DAC)
				// DA output runs on the AD tasks clock source ai
				// we stop DA and set the analog out to 0, the AD task keeps on running

				WAVE config = GetDAQConfigWave(device)
				fifoName = GetNIFIFOName(deviceID)

				HW_NI_StopDAC(deviceID)
				HW_NI_ZeroDAC(deviceID)

				DoXOPIdle
				FIFOStatus/Q $fifoName
				WAVE/WAVE NIDataWave = s.rawDACWave
				// As only one AD and DA channel is allowed for this function, at index 0 the setting for first DA channel are expected
				WAVE NIChannel = NIDataWave[0]
				if(V_FIFOChunks < DimSize(NIChannel, ROWS))
					SetWaveLock 0, NIChannel
					MultiThread NIChannel[V_FIFOChunks,] = 0
					SetWaveLock 1, NIChannel

					PSQ_Ramp_AddEpoch(device, s.headstage, NIChannel, "Name=DA suppression", "RA_DS", V_FIFOChunks, DimSize(NIChannel, ROWS) - 1)
				endif
			else
				ASSERT(0, "Unknown hardware type")
			endif

			// recalculate pulse duration
			PSQ_GetPulseDurations(device, PSQ_RAMP, s.sweepNo, totalOnsetDelay, forceRecalculation = 1)
		elseif(fifoInStimsetTime > pulseStart + pulseDuration)
			// we are past the pulse and have not found a spike
			// write the results into the LBN
			key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_DETECT)
			ED_AddEntryToLabnotebook(device, key, spikeDetection, overrideSweepNo = s.sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)
		endif
	endif

	if(!baselineQCPassed)
		[ret, chunk] = PSQ_EvaluateBaselineChunks(device, PSQ_RAMP, s)

		if(IsFinite(ret))
			baselineQCPassed = (ret == 0)

			// we can return here as we either:
			// - failed pre pulse BL QC and we don't need to search for a spike
			// - or passed post pulse BL QC and already searched for a spike
			enoughSpikesFound = PSQ_FoundAtLeastOneSpike(device, s.sweepNo)

			ASSERT(!baselineQCPassed || (baselineQCPassed && isFinite(enoughSpikesFound)), "We missed searching for a spike")
			return PSQ_EvaluateBaselinePassed(device, PSQ_RAMP, s.sweepNo, s.headstage, chunk, ret)
		endif
	endif
End

static Function PSQ_Ramp_AddEpoch(string device, variable headstage, WAVE wv, string tags, string shortName, variable first, variable last)
	variable DAC, epBegin, epEnd

	DAC = AFH_GetDACFromHeadstage(device, headstage)

	ASSERT(!cmpstr(WaveUnits(wv, ROWS), "ms"), "Unexpected x unit")
	epBegin = IndexToScale(wv, first, ROWS) / 1e3
	epEnd   = IndexToScale(wv, last, ROWS) / 1e3

	EP_AddUserEpoch(device, XOP_CHANNEL_TYPE_DAC, DAC, epBegin, epEnd, tags, shortName = shortName)
End

/// @brief Determine if we have three passing sweeps with the same DAScale value
///
/// @returns result        set passing state (0/1)
/// @returns maxOccurences maximum number of passing sets with the same DASCale value
Function [variable result, variable maxOccurences] PSQ_CR_SetHasPassed(WAVE numericalValues, variable sweepNo, variable headstage)
	variable i, numEntries, scaleFactor, index, maxValue
	string key

	key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	WAVE sweepPassedSCI = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	WAVE scaleFactorSCI = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, headstage, DATA_ACQUISITION_MODE)
	numEntries = DimSize(sweepPassedSCI, ROWS)
	ASSERT(numEntries == DimSize(scaleFactorSCI, ROWS), "Mismatching sizes")

	Make/I/FREE/N=(numEntries) numberOfOccurences, scaleFactors

	for(i = 0; i < numEntries; i += 1)

		if(!sweepPassedSCI[i])
			continue
		endif

		scaleFactor = round(scaleFactorSCI[i])

		FindValue/I=(scaleFactor) scaleFactors
		if(V_Value == -1)
			scaleFactors[index]= scaleFactor
			numberOfOccurences[index] = 1
			index += 1
		else
			numberOfOccurences[V_Value] += 1

			if(numberOfOccurences[V_Value] == PSQ_CR_NUM_SWEEPS_PASS)
				return [1, PSQ_CR_NUM_SWEEPS_PASS]
			endif
		endif
	endfor

	if(!index)
		return [0, 0]
	endif

	// keep only NumberOfOccurences column
	maxValue = WaveMax(numberOfOccurences)
	ASSERT(maxValue < PSQ_CR_NUM_SWEEPS_PASS, "Should have exited earlier!")

	return [0, maxValue]
End

/// @brief Returns the two letter states "AA", "AB" and "BA" for the value and
/// the scaling factors to reach min/center/max
///
/// We need the real baseline value (measured), whereas
/// the center between minimum/maximum would be targetV, which the user
/// entered together with an allowed ± range.
static Function [STRUCT ChirpBoundsInfo s] PSQ_CR_DetermineBoundsState(variable baseline, variable minimum, variable maximum, variable value)

	variable center

	ASSERT(minimum < maximum, "Invalid ordering")

	minimum -= baseline
	maximum -= baseline
	value   -= baseline

	s.minimumFac = minimum/value
	s.maximumFac = maximum/value
	center = minimum + (maximum - minimum) / 2
	s.centerFac = center/value

	if(value >= maximum)
		s.state = "AA"
	elseif(value <= minimum)
		s.state = "BB"
	else
		s.state = "BA"
	endif

	return [s]
End

Function/S PSQ_CR_BoundsActionToString(variable boundsAction)

	switch(boundsAction)
		case PSQ_CR_PASS:
			return "PSQ_CR_PASS"
		case PSQ_CR_INCREASE:
			return "PSQ_CR_INCREASE"
		case PSQ_CR_DECREASE:
			return "PSQ_CR_DECREASE"
		case PSQ_CR_RERUN:
			return "PSQ_CR_RERUN"
		default:
			ASSERT(0, "Invalid case")
	endswitch
End

static Function PSQ_CR_DetermineBoundsActionHelper(Wave wv, string state, variable action)

	variable index = GetNumberFromWaveNote(wv, NOTE_INDEX)
	SetDimLabel ROWS, index, $state, wv
	wv[index] = action
	SetNumberInWaveNote(wv, NOTE_INDEX, ++index)
End

/// @brief Returns an action depending on the upper and lower states, see @ref ChirpBoundsAction
static Function PSQ_CR_DetermineBoundsActionFromState(string upperState, string lowerState)

	variable action

	Make/FREE/N=15 comb
	SetNumberInWaveNote(comb, NOTE_INDEX, 0)

	// symmetric
	PSQ_CR_DetermineBoundsActionHelper(comb, "BA" + "BA", PSQ_CR_PASS)
	PSQ_CR_DetermineBoundsActionHelper(comb, "AA" + "BA", PSQ_CR_DECREASE)
	PSQ_CR_DetermineBoundsActionHelper(comb, "BA" + "BB", PSQ_CR_DECREASE)
	PSQ_CR_DetermineBoundsActionHelper(comb, "AA" + "BB", PSQ_CR_DECREASE)
	PSQ_CR_DetermineBoundsActionHelper(comb, "BB" + "BA", PSQ_CR_INCREASE)
	PSQ_CR_DetermineBoundsActionHelper(comb, "BA" + "AA", PSQ_CR_INCREASE)
	PSQ_CR_DetermineBoundsActionHelper(comb, "BB" + "AA", PSQ_CR_INCREASE)
	PSQ_CR_DetermineBoundsActionHelper(comb, "AA" + "AA", PSQ_CR_RERUN)
	PSQ_CR_DetermineBoundsActionHelper(comb, "BB" + "BB", PSQ_CR_RERUN)

	// hyperpolarized
	PSQ_CR_DetermineBoundsActionHelper(comb, "__" + "BA", PSQ_CR_PASS)
	PSQ_CR_DetermineBoundsActionHelper(comb, "__" + "AA", PSQ_CR_INCREASE)
	PSQ_CR_DetermineBoundsActionHelper(comb, "__" + "BB", PSQ_CR_DECREASE)

	// depolarized
	PSQ_CR_DetermineBoundsActionHelper(comb, "BA" + "__", PSQ_CR_PASS)
	PSQ_CR_DetermineBoundsActionHelper(comb, "AA" + "__", PSQ_CR_DECREASE)
	PSQ_CR_DetermineBoundsActionHelper(comb, "BB" + "__", PSQ_CR_INCREASE)

	action = comb[%$(upperState + lowerState)]
	ASSERT(IsFinite(action), "Invalid action")
	return action
End

/// @brief Determine the scaling factor for DAScale which is required for being inside the bounds
static Function PSQ_CR_DetermineScalingFactor(STRUCT ChirpBoundsInfo &lowerInfo, STRUCT ChirpBoundsInfo &upperInfo, variable boundsEvaluationMode)

	switch(boundsEvaluationMode)
		case PSQ_CR_BEM_SYMMETRIC:
			return (lowerInfo.centerFac + upperInfo.centerFac) / 2
		case PSQ_CR_BEM_HYPERPOLARIZED:
			return lowerInfo.centerFac
		case PSQ_CR_BEM_DEPOLARIZED:
			return upperInfo.centerFac
		default:
			ASSERT(0, "Invalid case")
	endswitch
End

/// @brief Determine the bounds action given the requested chirp slice
///
/// @param device               device
/// @param scaledDACWave        DAQ data wave with correct units and scaling
/// @param headstage            headstage
/// @param sweepNo              sweep number
/// @param chirpStart           x-position relative to stimset start where the chirp starts
/// @param cycleEnd             x-position relative to stimset start where the requested number of cycles finish
/// @param innerRelativeBound   analysis parameter
/// @param outerRelativeBound   analysis parameter
/// @param boundsEvaluationMode bounds evaluation mode, one of @ref PSQChirpBoundsEvaluationMode
///
/// @return boundsAction, one of @ref ChirpBoundsAction
/// @return scalingFactorDAScale, scaling factor to be inside the bounds for actions PSQ_CR_INCREASE/PSQ_CR_DECREASE
static Function [variable boundsAction, variable scalingFactorDAScale] PSQ_CR_DetermineBoundsAction(string device, WAVE scaledDACWave, variable headstage, variable sweepNo, variable chirpStart, variable cycleEnd, variable innerRelativeBound, variable outerRelativeBound, variable boundsEvaluationMode)

	variable targetV, lowerValue, upperValue, upperMax, upperMin, lowerMax, lowerMin
	variable lowerValueOverride, upperValueOverride, totalOnsetDelay, scalingFactor, baselineVoltage
	string msg, str, graph, key

	WAVE config = GetDAQConfigWave(device)
	WAVE singleAD = AFH_ExtractOneDimDataFromSweep(device, scaledDACWave, headstage, XOP_CHANNEL_TYPE_ADC, config = config)

	[lowerValue, upperValue] = WaveMinAndMaxWrapper(singleAD, x1 = chirpStart, x2 = cycleEnd)

	if(TestOverrideActive())
		WAVE/SDFR=root: overrideResults
		NVAR count = $GetCount(device)
		upperValueOverride = overrideResults[0][count][1]
		lowerValueOverride = overrideResults[0][count][2]

		if(!IsNaN(lowerValueOverride))
			lowerValue = lowerValueOverride
		endif
		if(!IsNaN(upperValueOverride))
			upperValue = upperValueOverride
		endif
	endif

	totalOnsetDelay = DAG_GetNumericalValue(device, "setvar_DataAcq_OnsetDelayUser") \
						+ GetValDisplayAsNum(device, "valdisp_DataAcq_OnsetDelayAuto")

	if(TestOverrideActive())
		baselineVoltage = PSQ_CR_BASELINE_V_FAKE
	else
		key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_TARGETV, chunk = 0, query = 1)
		WAVE numericalValues = GetLBNumericalValues(device)
		WAVE/Z baselineLBN = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
		ASSERT(WaveExists(baselineLBN), "Missing targetV from LBN")
		baselineVoltage = baselineLBN[headstage] / 1000
		ASSERT(IsFinite(baselineVoltage), "Invalid baseline voltage")
	endif

	sprintf msg, "boundsEvaluationMode %s, baselineVoltage %g, lowerValue %g, upperValue %g", PSQ_CR_BoundsEvaluationModeToString(boundsEvaluationMode),  baselineVoltage, lowerValue, upperValue
	DEBUGPRINT(msg)

	// See the bounds actions sketch at PSQ_Chirp for an explanation regarding the naming

	upperMax = baselineVoltage + outerRelativeBound
	upperMin = baselineVoltage + innerRelativeBound
	lowerMax = baselineVoltage - innerRelativeBound
	lowerMin = baselineVoltage - outerRelativeBound

	STRUCT ChirpBoundsInfo upperInfo
	STRUCT ChirpBoundsInfo lowerInfo

	[upperInfo] = PSQ_CR_DetermineBoundsState(baselineVoltage, upperMin, upperMax, upperValue)
	[lowerInfo] = PSQ_CR_DetermineBoundsState(baselineVoltage, lowerMin, lowerMax, lowerValue)

	switch(boundsEvaluationMode)
		case PSQ_CR_BEM_SYMMETRIC:
			// do nothing
			break
		case PSQ_CR_BEM_HYPERPOLARIZED:
			// only look at Lower
			upperInfo.state = "__"
			break
		case PSQ_CR_BEM_DEPOLARIZED:
			// only look at Upper
			lowerInfo.state = "__"
			break
		default:
			ASSERT(0, "Invalid case")
	endswitch

	boundsAction = PSQ_CR_DetermineBoundsActionFromState(upperInfo.state, lowerInfo.state)

	sprintf msg, "upper: value %g, info: min %g, center %g, max %g, state %s", upperValue, upperInfo.minimumFac, upperInfo.centerFac, upperInfo.maximumFac, upperInfo.state
	DEBUGPRINT(msg)

	sprintf msg, "lower: value %g, info: min %g, center %g, max %g, state %s", lowerValue, lowerInfo.minimumFac, lowerInfo.centerFac, lowerInfo.maximumFac, lowerInfo.state
	DEBUGPRINT(msg)

	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT)/T resultText
	resultText[INDEP_HEADSTAGE] = upperInfo.state + lowerInfo.state
	key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_BOUNDS_STATE)
	ED_AddEntryToLabnotebook(device, key, resultText, overrideSweepNo = sweepNo)

#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForFile(GetFile(FunctionPath(""))))
		Make/O/N=7/D $("chirpVisDebug_" + num2str(sweepNo))/Wave=chirpVisDebug
		Make/O/N=7/D $("chirpVisDebugX_" + num2str(sweepNo))/Wave=chirpVisDebugX

		chirpVisDebug = NaN
		chirpVisDebugX = 0

		switch(boundsEvaluationMode)
			case PSQ_CR_BEM_SYMMETRIC:
				chirpVisDebug[0] = lowerMin
				chirpVisDebug[1] = lowerMax
				chirpVisDebug[2] = upperMin
				chirpVisDebug[3] = upperMax
				chirpVisDebug[4] = lowerValue
				chirpVisDebug[5] = upperValue

				break
			case PSQ_CR_BEM_HYPERPOLARIZED:
				// only look at Lower
				chirpVisDebug[0] = lowerMin
				chirpVisDebug[1] = lowerMax
				chirpVisDebug[4] = lowerValue

				break
			case PSQ_CR_BEM_DEPOLARIZED:
				// only look at Upper
				chirpVisDebug[2] = upperMin
				chirpVisDebug[3] = upperMax
				chirpVisDebug[5] = upperValue

				break
			default:
				ASSERT(0, "Invalid case")
		endswitch

		graph = "ChirpVisDebugGraph_" + num2str(sweepNo)
		KillWindow/Z $graph
		Display/N=$graph chirpVisDebug/TN=chirpVisDebug vs chirpVisDebugX
		ModifyGraph/W=$graph mode=3, marker(chirpVisDebug[4])=19, marker(chirpVisDebug[5])=19, nticks(bottom)=0, rgb(chirpVisDebug[5])=(0,0,65535), grid(left)=1,nticks(left)=10
		sprintf str "State: Upper %s, Lower %s\r\\s(chirpVisDebug) borders\r\n\\s(chirpVisDebug[5]) upperValue\r\\s(chirpVisDebug[4]) lowerValue", upperInfo.state, lowerInfo.state
		Legend/C/N=text2/J str
		SetAxis/A/E=1/W=$graph left
	endif
#endif // DEBUGGING_ENABLED

	switch(boundsAction)
		case PSQ_CR_RERUN:
			ASSERT(boundsEvaluationMode == PSQ_CR_BEM_SYMMETRIC, "Invalid bounds action")
		case PSQ_CR_PASS:
			scalingFactor = NaN
			// do nothing
			break
		case PSQ_CR_INCREASE:
		case PSQ_CR_DECREASE:
				scalingFactor = PSQ_CR_DetermineScalingFactor(lowerInfo, upperInfo, boundsEvaluationMode)
				if(!IsFinite(scalingFactor))
					// unlikely edge case
					boundsAction = PSQ_CR_Rerun
					scalingFactor = NaN
				endif
				break
		default:
			ASSERT(0, "impossible case")
	endswitch

	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT)/D result = NaN
	result[INDEP_HEADSTAGE] = boundsAction
	key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_BOUNDS_ACTION)
	ED_AddEntryToLabnotebook(device, key, result, overrideSweepNo = sweepNo)

	sprintf msg, "boundsAction %s, scalingFactor %g", PSQ_CR_BoundsActionToString(boundsAction), scalingFactor
	DEBUGPRINT(msg)

	return [boundsAction, scalingFactor]
End

/// @brief Return the x position of the end of the given cycle relative to the stimset start
static Function PSQ_CR_GetXPosFromCycles(variable cycle, WAVE cycleXValues, variable totalOnsetDelay)
	variable index

	// we have all crossings in cycleXValues
	// 0: start
	// 1: half cycle
	// 2: full cycle
	//
	// so the first cycle ranges from cycleXValues[0] to cycleXValues[2] and so on

	index = cycle * 2

	ASSERT(index < DimSize(cycleXValues, ROWS), "Not enough cycles present in the stimulus set.")

	return cycleXValues[index] - totalOnsetDelay
End

static Function/WAVE PSQ_CR_GetCycles(string device, variable sweepNo, WAVE rawDACWave, variable xstart)
	string key

	WAVE textualValues = GetLBTextualValues(device)

	key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_CYCLES, query = 1)
	WAVE/Z cycles = GetLastSetting(textualValues, sweepNo, key, UNKNOWN_MODE)

	if(!WaveExists(cycles))
		WAVE cycles = PSQ_CR_DetermineCycles(device, rawDACWave, xstart)

		key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_CYCLES)
		ED_AddEntryToLabnotebook(device, key, cycles, overrideSweepNo = sweepNo)
	endif

	return cycles
end

/// @brief Find all x values where DA channels have the same value as rawDACWave[xstart]
///
/// We search starting from xstart, where `matches` have a minimum of 1ms between them.
///
/// @param device device
/// @param rawDACWave unscaled DAQDataWave (aka GetHardwareDataWave(device))
/// @param xstart     position of reference value and starting point for the search
///
/// @return Labnotebook entry wave
static Function/WAVE PSQ_CR_DetermineCycles(string device, WAVE rawDACWave, variable xstart)

	variable yval, minimumWidthX, i

	minimumWidthX = 1

	WAVE config = GetDAQConfigWave(device)

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
	MAKE/FREE/T/N=(LABNOTEBOOK_LAYER_COUNT) cycles

	WAVE gains = SWS_GetChannelGains(device, timing = GAIN_AFTER_DAQ)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		WAVE singleDA = AFH_ExtractOneDimDataFromSweep(device, rawDACWave, i, XOP_CHANNEL_TYPE_DAC, config = config)

		// first active DA channel
		yval = singleDA[xstart] / gains[0]

		Make/FREE/R matches
		FindLevels/DEST=matches/R=(xstart - minimumWidthX / 2, inf)/M=(minimumWidthX)/Q singleDA, yval

		cycles[i] = NumericWaveToList(matches, ";")
	endfor

	return cycles
End

static Function/S PSQ_CR_BoundsEvaluationModeToString(variable val)
	switch(val)
		case PSQ_CR_BEM_SYMMETRIC:
			return "Symmetric"
		case PSQ_CR_BEM_HYPERPOLARIZED:
			return "Hyperpolarized"
		case PSQ_CR_BEM_DEPOLARIZED:
			return "Depolarized"
		default:
			ASSERT(0, "Invalid value: " + num2str(val))
	endswitch
End

static Function PSQ_CR_ParseBoundsEvaluationModeString(string str)
	strswitch(str)
		case "Symmetric":
			return PSQ_CR_BEM_SYMMETRIC
		case "Hyperpolarized":
			return PSQ_CR_BEM_HYPERPOLARIZED
		case "Depolarized":
			return PSQ_CR_BEM_DEPOLARIZED
		default:
			ASSERT(0, "Invalid value: " + str)
	endswitch
End

Function/S PSQ_Chirp_GetHelp(string name)

	strswitch(name)
		 case "BaselineRMSShortThreshold":
			 return "Threshold value in mV for the short RMS baseline QC check (defaults to " + num2str(PSQ_RMS_SHORT_THRESHOLD) + ")"
		 case "BaselineRMSLongThreshold":
			 return "Threshold value in mV for the long RMS baseline QC check (defaults to " + num2str(PSQ_RMS_LONG_THRESHOLD) + ")"
		 case "BoundsEvaluationMode":
			 return "Select the bounds evaluation mode: Symmetric (Lower and Upper), Depolarized (Upper) or Hyperpolarized (Lower)"
		case "InnerRelativeBound":
			return "Lower bound of a confidence band for the acquired data relative to the pre pulse baseline in mV. Must be positive."
		case "OuterRelativeBound":
			return "Upper bound of a confidence band for the acquired data relative to the pre pulse baseline in mV. Must be positive."
		case "NumberOfChirpCycles":
			return "Number of acquired chirp cycles before the bounds evaluation starts. Defaults to 1."
		case "NumberOfFailedSweeps":
			return "Number of failed sweeps which marks the set as failed."
		 case "SamplingFrequency":
			 return "Required sampling frequency for the acquired data [kHz]. Defaults to 50."
		case "SamplingMultiplier":
			 return "Use 1 for no multiplier"
		case "SpikeCheck":
			return "Toggle spike check during the chirp. Defaults to off."
		case "FailedLevel":
			return "Absolute level for spike search, required when SpikeCheck is enabled."
		case "DAScaleOperator":
			return "Set the math operator to use for combining the DAScale and the "            \
			       + "modifier. Valid strings are \"+\" (addition) and \"*\" (multiplication)."
		case "DAScaleModifier":
			return "Modifier value to the DA Scale of headstages with spikes during chirp"
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
			break
	endswitch
End

Function/S PSQ_Chirp_CheckParam(string name, struct CheckParametersStruct &s)
	variable val
	string str

	strswitch(name)
		case "BoundsEvaluationMode":
			str = AFH_GetAnalysisParamTextual(name, s.params)
			if(WhichListItem(str, PSQ_CR_BEM) == -1)
				return "Invalid value " + str
			endif
			break
		case "BaselineRMSShortThreshold":
		case "BaselineRMSLongThreshold":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val > 0 && val <= 20))
				return "Invalid value " + num2str(val)
			endif
			break
		case "InnerRelativeBound":
			if(AFH_GetAnalysisParamNumerical("InnerRelativeBound", s.params) >= AFH_GetAnalysisParamNumerical("OuterRelativeBound", s.params))
				return "InnerRelativeBound must be smaller than OuterRelativeBound"
			endif
		case "OuterRelativeBound": // fallthrough-by-design
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val) || val < PSQ_CR_LIMIT_BAND_LOW || val > PSQ_CR_LIMIT_BAND_HIGH)
				return "Out of bounds with value " + num2str(val)
			endif
			break
		case "NumberOfChirpCycles":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val) || !IsInteger(val) || val <= 0)
				return "Must be a finite non-zero integer"
			endif
			break
		case "NumberOfFailedSweeps":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val) || !IsInteger(val) || val <= 0 ||  val > IDX_NumberOfSweepsInSet(s.setName))
				return "Must be a finite non-zero integer and smaller or equal to the number of sweeps in the stimset"
			endif
			break
		case "FailedLevel":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val))
				return "Must be a finite value"
			endif
			break
		case "SamplingFrequency":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0 && val <= 1000))
				return "Invalid value " + num2str(val)
			endif
			break
		case "SamplingMultiplier":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsValidSamplingMultiplier(val))
				return "Invalid value " + num2str(val)
			endif
			break
		case "SpikeCheck":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val))
				return "Must be a finite value"
			endif
			break
		case "DAScaleOperator":
			str = AFH_GetAnalysisParamTextual(name, s.params)
			if(cmpstr(str, "+") && cmpstr(str, "*"))
				return "Invalid string " + str
			endif
			break
		case "DAScaleModifier":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val))
				return "Invalid value " + num2str(val)
			endif
			break
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
			break
	endswitch
End

/// @brief Return a list of required analysis functions for PSQ_Chirp()
Function/S PSQ_Chirp_GetParams()
	return "InnerRelativeBound:variable,OuterRelativeBound:variable," +                            \
		   "[NumberOfChirpCycles:variable],[SpikeCheck:variable],[FailedLevel:variable]," +         \
		   "[DAScaleOperator:string],[DAScaleModifier:variable],[NumberOfFailedSweeps:variable]," + \
		   "[SamplingMultiplier:variable],[SamplingFrequency:variable]," +                          \
		   "[BaselineRMSShortThreshold:variable],[BaselineRMSLongThreshold:variable]," +            \
		   "BoundsEvaluationMode:string"
End

/// @brief Analysis function for determining the impedance of the cell using a sine chirp stim set
///
/// Prerequisites:
/// - Does only work for one headstage
/// - Assumes that the stimset has a chirp of non-zero and arbitrary length
/// - Pre pulse baseline length is #PSQ_CR_BL_EVAL_RANGE
/// - Post pulse baseline length is at least two times #PSQ_CR_BL_EVAL_RANGE
///
/// Testing:
/// For testing the range detection logic, the results can be defined in the wave
/// root:overrideResults. @see PSQ_CreateOverrideResults()
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: /dot/patch-seq-chirp.svg
/// \endrst
///
/// The bounds action for Symmetric (Upper and Lower) is derived from the state according to the following sketch:
///
/// \rst
///	.. image:: ../patch-seq-chirp-bounds-state-action.png
/// \endrst
///
/// Depolarized (Upper only):
///
/// ======= ==========
///  State   Action
/// ======= ==========
///  BA      Pass
///  AA      Decrease
///  BB      Increase
/// ======= ==========
///
/// Hyperpolarized (Lower only):
///
/// ======= ==========
///  State   Action
/// ======= ==========
///  BA      Pass
///  AA      Increase
///  BB      Decrease
/// ======= ==========
///
/// @verbatim
///
/// Sketch of a stimset with pre pulse baseline (-), sine chirp (~), and post pulse baseline (-).
///
///
///
///                     ~               ~
///                   ~  ~             ~ ~
///                  ~    ~           ~   ~
///                 ~      ~         ~     ~
/// ---------------~        ~       ~       ~--------------------------------
///                          ~     ~
///                           ~   ~
///                             ~
///
/// @endverbatim
Function PSQ_Chirp(device, s)
	string device
	STRUCT AnalysisFunction_V3 &s

	variable InnerRelativeBound, OuterRelativeBound, sweepPassed, setPassed, boundsAction, failsInSet, leftSweeps, chunk, multiplier
	variable length, minLength, DAC, resistance, passingDaScaleSweep, sweepsInSet, passesInSet, acquiredSweepsInSet, samplingFrequencyPassed
	variable targetVoltage, initialDAScale, baselineQCPassed, insideBounds, totalOnsetDelay, scalingFactorDAScale
	variable fifoInStimsetPoint, fifoInStimsetTime, i, ret, range, chirpStart, chirpDuration
	variable numberOfChirpCycles, cycleEnd, maxOccurences, level, numberOfSpikesFound, abortDueToSpikes, spikeCheck
	variable spikeCheckPassed, daScaleModifier, chirpEnd, numSweepsFailedAllowed, boundsEvaluationMode
	string setName, key, msg, stimset, str, daScaleOperator

	innerRelativeBound = AFH_GetAnalysisParamNumerical("InnerRelativeBound", s.params)
	numberOfChirpCycles = AFH_GetAnalysisParamNumerical("NumberOfChirpCycles", s.params, defValue = 1)
	outerRelativeBound = AFH_GetAnalysisParamNumerical("OuterRelativeBound", s.params)
	numSweepsFailedAllowed = AFH_GetAnalysisParamNumerical("NumberOfFailedSweeps", s.params, defValue = 3)
	multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params, defValue = PSQ_DEFAULT_SAMPLING_MULTIPLIER)
	boundsEvaluationMode = PSQ_CR_ParseBoundsEvaluationModeString(AFH_GetAnalysisParamTextual("BoundsEvaluationMode", s.params))

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
			PGC_SetAndActivateControl(device, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)

			if(DAG_GetHeadstageMode(device, s.headstage) != I_CLAMP_MODE)
				printf "(%s) Clamp mode must be current clamp.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", device
				ControlWindowToFront()
				return 1
			endif

			length = PSQ_GetDAStimsetLength(device, s.headstage)
			minLength = 3 * PSQ_CR_BL_EVAL_RANGE
			if(length < minLength)
				printf "(%s) Stimset of headstage %d is too short, it must be at least %g ms long.\r", device, s.headstage, minLength
				ControlWindowToFront()
				return 1
			endif

			DAC = AFH_GetDACFromHeadstage(device, s.headstage)
			setName = AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC)
			if(IDX_NumberOfSweepsInSet(setName) < PSQ_CR_NUM_SWEEPS_PASS)
				printf "(%s): The stimset must have at least %d sweeps\r", device, PSQ_CR_NUM_SWEEPS_PASS
				ControlWindowToFront()
				return 1
			endif

			DisableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")

		case PRE_SET_EVENT: // fallthrough-by-design
			SetAnalysisFunctionVersion(device, PSQ_CHIRP, s.headstage, s.sweepNo)

			PSQ_SetSamplingIntervalMultiplier(device, multiplier)

			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE textualValues   = GetLBTextualValues(device)

			PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 0)
			PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = 1)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 1)

			if(s.eventType == PRE_SET_EVENT)
				spikeCheck = !!AFH_GetAnalysisParamNumerical("SpikeCheck", s.params, defValue = PSQ_CR_SPIKE_CHECK_DEFAULT)

				// if spikeCheck is enabled we also need the other analysis parameters
				// which are now not optional anymore
				if(spikeCheck)
					if(!PSQ_CR_FindDependentAnalysisParameter(device, "FailedLevel", s.params))
						return 1
					elseif(!PSQ_CR_FindDependentAnalysisParameter(device, "DAScaleModifier", s.params))
						return 1
					elseif(!PSQ_CR_FindDependentAnalysisParameter(device, "DAScaleOperator", s.params))
						return 1
					endif
				endif

				Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
				values[INDEP_HEADSTAGE] = spikeCheck
				key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_SPIKE_CHECK)
				ED_AddEntryToLabnotebook(device, key, values, overrideSweepNo = s.sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)

				if(TestOverrideActive())
					resistance = PSQ_CR_RESISTANCE_FAKE * 1e9
				else
					passingDaScaleSweep = PSQ_GetLastPassingDAScaleSub(device, s.headstage)

					if(!IsValidSweepNumber(passingDaScaleSweep))
						printf "(%s): We could not find a passing sweep with DAScale analysis function in Subthreshold mode.\r", device
						ControlWindowToFront()
						return 1
					endif

					// predates CreateAnaFuncLBNKey(), so we have to use a hardcoded name
					WAVE/Z resistanceFromFit = GetLastSetting(numericalValues, passingDaScaleSweep, LABNOTEBOOK_USER_PREFIX + "ResistanceFromFit", UNKNOWN_MODE)

					if(!WaveExists(resistanceFromFit))
						printf "(%s): The Resistance labnotebook entry could not be found.\r", device
						ControlWindowToFront()
						return 1
					endif

					resistance = resistanceFromFit[s.headstage]
				endif

				sprintf msg, "Resistance: %g [Ohm]\r", resistance
				DEBUGPRINT(msg)

				Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT)/D result = NaN
				result[INDEP_HEADSTAGE] = resistance

				key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_RESISTANCE)
				ED_AddEntryToLabnotebook(device, key, result, overrideSweepNo = s.sweepNo, unit = "Ohm")

				targetVoltage = ((outerRelativeBound + innerRelativeBound) / 2) * 1e-3
				initialDAScale = targetVoltage / resistance

				sprintf msg, "Initial DAScale: %g [Amperes]\r", initialDAScale
				DEBUGPRINT(msg)

				Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT)/D result = NaN
				key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_INITIAL_SCALE)
				result[INDEP_HEADSTAGE] = initialDAScale
				ED_AddEntryToLabnotebook(device, key, result, overrideSweepNo = s.sweepNo, unit = "Amperes")

				SetDAScale(device, s.headstage, absolute=initialDAScale, roundTopA = 1)
			endif
			break
		case POST_SWEEP_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE textualValues   = GetLBTextualValues(device)

			totalOnsetDelay = DAG_GetNumericalValue(device, "setvar_DataAcq_OnsetDelayUser") \
				  + GetValDisplayAsNum(device, "valdisp_DataAcq_OnsetDelayAuto")

			key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
			WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			// if we don't have a PSQ_FMT_LBN_BL_QC_PASS entry this means it did not pass
			baselineQCPassed = WaveExists(baselineQCPassedLBN) ? baselineQCPassedLBN[s.headstage] : 0

			key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_INSIDE_BOUNDS, query = 1)
			insideBounds = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE, defValue = 0)

			key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_SPIKE_CHECK, query = 1)
			spikeCheck = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
			ASSERT(IsFinite(spikeCheck), "Invalid spikeCheck value")

			key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_SPIKE_PASS, query = 1)
			WAVE/Z spikeCheckPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			spikeCheckPassed = WaveExists(spikeCheckPassedLBN) ? spikeCheckPassedLBN[s.headstage] : 0

			samplingFrequencyPassed = PSQ_CheckSamplingFrequencyAndStoreInLabnotebook(device, PSQ_CHIRP, s)

			if(spikeCheck)
				sweepPassed = (baselineQCPassed == 1 && insideBounds == 1 && samplingFrequencyPassed == 1 && spikeCheckPassed == 1)
			else
				sweepPassed = (baselineQCPassed == 1 && insideBounds == 1 && samplingFrequencyPassed == 1)
			endif

			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
			result[INDEP_HEADSTAGE] = sweepPassed
			key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			WAVE/T stimsets = GetLastSetting(textualValues, s.sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
			stimset = stimsets[s.headstage]

			sweepsInSet         = IDX_NumberOfSweepsInSet(stimset)
			passesInSet         = PSQ_NumPassesInSet(numericalValues, PSQ_CHIRP, s.sweepNo, s.headstage)
			acquiredSweepsInSet = PSQ_NumAcquiredSweepsInSet(device, s.sweepNo, s.headstage)
			failsInSet          = acquiredSweepsInSet - passesInSet
			leftSweeps          = sweepsInSet - acquiredSweepsInSet

			[setPassed, maxOccurences] = PSQ_CR_SetHasPassed(numericalValues, s.sweepNo, s.headstage)

			if(setPassed)
				PSQ_ForceSetEvent(device, s.headstage)
				RA_SkipSweeps(device, inf, limitToSetBorder = 1)
			else
				if((maxOccurences + leftSweeps) < PSQ_CR_NUM_SWEEPS_PASS)
					// not enough sweeps left to pass the set
					// we need PSQ_CR_NUM_SWEEPS_PASS with the same
					// DAScale value
					PSQ_ForceSetEvent(device, s.headstage)
					RA_SkipSweeps(device, inf)
				elseif(failsInSet >= numSweepsFailedAllowed)
					// failed too many sweeps
					PSQ_ForceSetEvent(device, s.headstage)
					RA_SkipSweeps(device, inf)
				elseif(!samplingFrequencyPassed)
					PSQ_ForceSetEvent(device, s.headstage)
					RA_SkipSweeps(device, inf)
				endif
			endif

			sprintf msg, "Sweep %s, Set %s, total sweeps %g, acquired sweeps %g, sweeps passed %g, sweeps passed with same DAScale %g, spike check performed %g, spike check %s\r", ToPassFail(sweepPassed), ToPassFail(setPassed), sweepsInSet, acquiredSweepsInSet, passesInSet, maxOccurences, spikeCheck, ToPassFail(spikeCheckPassed)
			DEBUGPRINT(msg)

			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)

			[setPassed, maxOccurences] = PSQ_CR_SetHasPassed(numericalValues, s.sweepNo, s.headstage)

			sprintf msg, "Set has %s\r", ToPassFail(setPassed)
			DEBUGPRINT(msg)

			Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT)/D result = NaN
			result[INDEP_HEADSTAGE] = setPassed
			key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			AD_UpdateAllDatabrowser()

			break
		case POST_DAQ_EVENT:
			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
	endswitch

	if(s.eventType != MID_SWEEP_EVENT)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(device)

	totalOnsetDelay = DAG_GetNumericalValue(device, "setvar_DataAcq_OnsetDelayUser") \
					  + GetValDisplayAsNum(device, "valdisp_DataAcq_OnsetDelayAuto")

	fifoInStimsetPoint = s.lastKnownRowIndex - totalOnsetDelay / DimDelta(s.rawDACWAVE, ROWS)
	fifoInStimsetTime  = fifoInStimsetPoint * DimDelta(s.rawDACWAVE, ROWS)

	spikeCheck = !!AFH_GetAnalysisParamNumerical("SpikeCheck", s.params, defValue = PSQ_CR_SPIKE_CHECK_DEFAULT)

	key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_SPIKE_PASS, query = 1)
	WAVE/Z spikeCheckPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
	spikeCheckPassed = WaveExists(spikeCheckPassedLBN) ? spikeCheckPassedLBN[s.headstage] : NaN

	key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
	baselineQCPassed = WaveExists(baselineQCPassedLBN) ? baselineQCPassedLBN[s.headstage] : NaN

	key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_INSIDE_BOUNDS, query = 1)
	insideBounds = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE)

	sprintf msg, "Midsweep: insideBounds %g, baselineQCPassed %g, spikeCheck %g, spikeCheckPassed %g", insideBounds, baselineQCPassed, spikeCheck, spikeCheckPassed
	DEBUGPRINT(msg)

	if(IsFinite(insideBounds) && IsFinite(baselineQCPassed) && (!spikeCheck || (spikeCheck && IsFinite(spikeCheckPassed) && spikeCheckPassed)))
		// nothing more to do if we did inside bounds check and baseline QC and either did not do spike checking or spike checking passed
		return NaN
	endif

	if(spikeCheck && IsNaN(spikeCheckPassed))
		WAVE durations = PSQ_GetPulseDurations(device, PSQ_CHIRP, s.sweepNo, totalOnsetDelay)

		chirpStart = totalOnsetDelay + PSQ_CR_BL_EVAL_RANGE
		chirpEnd   = chirpStart + durations[s.headstage]

		sprintf msg, "Spike check: chirpStart (relative to zero) %g, chirpEnd %g, fifoInStimsetTime %g", chirpStart, chirpEnd, fifoInStimsetTime
		DEBUGPRINT(msg)

		if(fifoInStimsetTime > chirpStart)
			level = AFH_GetAnalysisParamNumerical("FailedLevel", s.params)

			WAVE spikeDetection = PSQ_SearchForSpikes(device, PSQ_CHIRP, s.rawDACWave, s.headstage, chirpStart, level, searchEnd = chirpEnd, \
			                                          numberOfSpikesFound = numberOfSpikesFound, numberOfSpikesReq = inf)
			WaveClear spikeDetection

			if(numberOfSpikesFound > 0)
				Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) spikePass = NaN
				spikePass[s.headstage] = 0
			elseif(fifoInStimsetTime > chirpEnd)
				// beyond chirp and we found nothing, so we passed
				Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) spikePass = NaN
				spikePass[s.headstage] = 1
			endif

			if(WaveExists(spikePass))
				key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_SPIKE_PASS)
				ED_AddEntryToLabnotebook(device, key, spikePass, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

				spikeCheckPassed = spikePass[s.headstage]
			endif
		endif
	endif

	// no early return here because we want to do baseline QC checks (and chunk creation) always

	if(IsNaN(baselineQCPassed))
		[ret, chunk] = PSQ_EvaluateBaselineChunks(device, PSQ_CHIRP, s)

		if(IsFinite(ret))
			baselineQCPassed = (ret == 0)

			PSQ_EvaluateBaselinePassed(device, PSQ_CHIRP, s.sweepNo, s.headstage, chunk, ret)
		endif
	endif

	if(spikeCheck && IsFinite(spikeCheckPassed) && !spikeCheckPassed)
		// adapt DAScale and finish
		daScaleModifier = AFH_GetAnalysisParamNumerical("DAScaleModifier", s.params)
		daScaleOperator = AFH_GetAnalysisParamTextual("DAScaleOperator", s.params)
		SetDAScaleModOp(device, s.headstage, daScaleModifier, daScaleOperator, roundTopA = 1)

		return ANALYSIS_FUNC_RET_EARLY_STOP
	endif

	WAVE/T cycleXValuesLBN = PSQ_CR_GetCycles(device, s.sweepNo, s.rawDACWave, totalonsetDelay + PSQ_CR_BL_EVAL_RANGE)
	WAVE cycleXValues = ListToNumericWave(cycleXValuesLBN[s.headstage], ";")

	chirpStart = PSQ_CR_BL_EVAL_RANGE
	cycleEnd = PSQ_CR_GetXPosFromCycles(numberOfChirpCycles, cycleXValues, totalOnsetDelay)

	sprintf msg, "chirpStart (relative to stimset start) %g, fifoInStimsetTime %g, cycleEnd %g", chirpStart, fifoInStimsetTime, cycleEnd
	DEBUGPRINT(msg)

	if((IsNaN(baselineQCPassed) || baselineQCPassed) && IsNaN(insideBounds) && fifoInStimsetTime >= cycleEnd)
		// inside bounds search was inconclusive up to now
		// and we have acquired enough cycles
		// and baselineQC is not failing

		[boundsAction, scalingFactorDaScale] = PSQ_CR_DetermineBoundsAction(device, s.scaledDACWave, s.headstage, s.sweepNo, chirpStart, cycleEnd, innerRelativeBound, outerRelativeBound, boundsEvaluationMode)

		insideBounds = (boundsAction == PSQ_CR_PASS)
		Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT)/D result = NaN
		result[INDEP_HEADSTAGE] = insideBounds
		key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_INSIDE_BOUNDS)
		ED_AddEntryToLabnotebook(device, key, result, overrideSweepNo = s.sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)

		switch(boundsAction)
			case PSQ_CR_PASS:
			case PSQ_CR_RERUN: // fallthrough-by-design
				// nothing to do
				break
			case PSQ_CR_INCREASE:
			case PSQ_CR_DECREASE: // fallthrough-by-design
				SetDAScale(device, s.headstage, relative = scalingFactorDAScale, roundTopA = 1)
				break
			default:
				ASSERT(0, "impossible case")
		endswitch
	endif

	if(IsFinite(baselineQCPassed) && baselineQCPassed)
		ASSERT(IsFinite(insideBounds), "Must be already checked")
		return ANALYSIS_FUNC_RET_EARLY_STOP
	elseif(IsFinite(baselineQCPassed) && !baselineQCPassed)
		return ret
	elseif(!insideBounds)
		return ANALYSIS_FUNC_RET_EARLY_STOP
	endif

	return NaN
End

static Function PSQ_CR_FindDependentAnalysisParameter(string device, string name, string params)

	string strRep = AFH_GetAnalysisParameter(name, params)

	if(IsEmpty(strRep))
		printf "(%s): The analysis parameter \"%s\" is missing, but it is not optional when \"SpikeCheck\" is enabled.\r", device, name
		ControlWindowToFront()
		return 0
	endif

	return 1
End

/// @brief Manually force the pre/post set events
///
/// Required to do before skipping sweeps.
/// @todo this hack must go away.
static Function PSQ_ForceSetEvent(device, headstage)
	string device
	variable headstage

	variable DAC

	WAVE setEventFlag = GetSetEventFlag(device)
	DAC = AFH_GetDACFromHeadstage(device, headstage)

	setEventFlag[DAC][%PRE_SET_EVENT]  = 1
	setEventFlag[DAC][%POST_SET_EVENT] = 1
End

static Function PSQ_SetSamplingIntervalMultiplier(string device, variable multiplier)

	string multiplierAsString = num2str(multiplier)

	PGC_SetAndActivateControl(device, "Popup_Settings_SampIntMult", str = multiplierAsString)
	ASSERT(!cmpstr(DAG_GetTextualValue(device, "Popup_Settings_SampIntMult"), multiplierAsString), "Sampling interval multiplier could not be set")
End
