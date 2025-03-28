#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_TP
#endif // AUTOMATED_TESTING

/// @file MIES_TestPulse.ipf
/// @brief __TP__ Basic Testpulse related functionality

static Constant TP_MAX_VALID_RESISTANCE    = 3000  ///< Units MΩ
static Constant TP_TPSTORAGE_EVAL_INTERVAL = 0.18
static Constant TP_FIT_POINTS              = 5
static Constant TP_PRESSURE_INTERVAL       = 0.090 ///< [s]
static Constant TP_EVAL_POINT_OFFSET       = 5

static Constant TP_BASELINE_FITTING_INSET = 0.3 // ms
static Constant TP_SET_PRECISION          = 2

/// Comment in for debugging of TP_TSAnalysis
///
/// For visualising the evaluation ranges from the returned DFREF:
///
/// \rst
/// .. code-block:: igorpro
///
///		Duplicate/O dfr:data, root:data
///		Duplicate/O dfr:colors, root:colors
///
///		ModifyGraph zColor(data)={colors,*,*,Rainbow,1}
///
/// \endrst
#if 0
#define TP_ANALYSIS_DEBUGGING
#endif

/// @brief Check if the value is a valid baseline fraction
Function TP_IsValidBaselineFraction(variable value)

	return value >= TP_BASELINE_FRACTION_LOW && value <= TP_BASELINE_FRACTION_HIGH
End

/// @brief Return the total length of a single testpulse with baseline
///
/// Static on purpose as all users during DAQ/TP should prefer GetTPSettingsCalculated()
///
/// @param pulseDuration duration of the high portion of the testpulse in points or time
/// @param baselineFrac  fraction, *not* percentage, of the baseline
static Function TP_CalculateTestPulseLength(variable pulseDuration, variable baselineFrac)

	ASSERT(TP_IsValidBaselineFraction(baselineFrac), "baselineFrac is out of range")
	return pulseDuration / (1 - 2 * baselineFrac)
End

/// @brief Inverse function of TP_CalculateTestPulseLength
///
/// Can be used when reconstructing the baseline fraction from epoch information.
Function TP_CalculateBaselineFraction(variable pulseDuration, variable totalLength)

	return (pulseDuration / totalLength - 1) / -2
End

/// @brief Stores the given TP wave
///
/// @param device device
/// @param TPWave     reference to wave holding the TP data, see GetOscilloscopeWave()
/// @param tpMarker   unique number for this set of TPs from all TP channels
/// @param hsList     list of headstage numbers in the same order as the columns of TPWave
///
/// The stored test pulse waves will have column dimension labels in the format `HS_X`.
Function TP_StoreTP(string device, WAVE TPWave, variable tpMarker, string hsList)

	variable index, ret

	WAVE/WAVE storedTP = GetStoredTestPulseWave(device)
	index = GetNumberFromWaveNote(storedTP, NOTE_INDEX)

	ret = EnsureLargeEnoughWave(storedTP, indexShouldExist = index, checkFreeMemory = 1)

	if(ret)
		HandleOutOfMemory(device, NameOfWave(storedTP))
		return NaN
	endif

	Note/K TPWave

	SetStringInWaveNote(TPWave, "TimeStamp", GetISO8601TimeStamp(numFracSecondsDigits = 3))
	SetNumberInWaveNote(TPWave, "TPMarker", tpMarker, format = "%d")
	SetNumberInWaveNote(TPWave, "TPCycleID", ROVAR(GetTestpulseCycleID(device)), format = "%d")
	SetStringInWaveNote(TPWave, "Headstages", hsList)

	// setting dimension labels only works if the dimension size is not zero
	if(DimSize(TPWave, COLS) == 0)
		Redimension/N=(-1, 1, -1, -1) TPWave
	endif

	hsList = ReplaceString(",", hsList, ";")
	SetDimensionLabels(TPWave, AddPrefixToEachListItem("HS_", hsList), COLS)

	storedTP[index++] = TPWave

	SetNumberInWaveNote(storedTP, NOTE_INDEX, index)
End

/// @brief Return a number of consecutive test pulses ending with the TP
/// identified by tpMarker.
///
/// The wave reference wave will have as many columns as active headstages were used.
Function/WAVE TP_GetStoredTPs(string device, variable tpMarker, variable number)

	variable numEntries

	WAVE/WAVE storedTP = GetStoredTestPulseWave(device)
	numEntries = GetNumberFromWaveNote(storedTP, NOTE_INDEX)

	if(numEntries == 0)
		return $""
	endif

	Make/FREE/N=(numEntries) matches

	Multithread matches[0, numEntries - 1] = GetNumberFromWaveNote(storedTP[p], "TPMarker") == tpMarker

	FindValue/V=1 matches

	if(V_row == -1)
		return $""
	endif

	Make/FREE/N=(number)/WAVE result

	if(number > (V_row + 1))
		// too few TPs available
		return $""
	endif

	result[] = storedTP[V_row - number + 1 + p]

	// check that they all belong to the same TP cycle
	Redimension/N=(number) matches
	matches[] = GetNumberFromWaveNote(result[0], "TPCycleID") == GetNumberFromWaveNote(result[p], "TPCycleID")

	if(Sum(matches) < number)
		return $""
	endif

	return result
End

/// @brief Split the stored testpulse wave reference wave into single waves
///        for easier handling
Function TP_SplitStoredTestPulseWave(string device)

	variable numEntries, i

	WAVE/WAVE storedTP = GetStoredTestPulseWave(device)
	DFREF     dfr      = GetDeviceTestPulse(device)

	numEntries = GetNumberFromWaveNote(storedTP, NOTE_INDEX)
	for(i = 0; i < numEntries; i += 1)

		WAVE/Z wv = storedTP[i]

		if(!WaveExists(wv))
			continue
		endif

		Duplicate/O wv, dfr:$("StoredTestPulses_" + num2str(i))
	endfor
End

/// @brief Receives data from the async function TP_TSAnalysis(), buffers partial results and puts
/// complete results back to main thread,
/// results are base line level, steady state resistance, instantaneous resistance and their positions
/// collected results for all channels of a measurement are send to TP_RecordTP(), DQ_ApplyAutoBias() when complete
///
/// @param ar ASYNC_ReadOutStruct structure with dfr with input data
Function TP_ROAnalysis(STRUCT ASYNC_ReadOutStruct &ar)

	variable i, j, bufSize
	variable posMarker, posAsync, tpBufferSize
	variable posBaseline, posSSRes, posInstRes
	variable posElevSS, posElevInst

	if(ar.rtErr || ar.abortCode)
		ASSERT(!ar.rtErr, "TP analysis thread encountered RTE " + ar.rtErrMsg)
		ASSERT(!ar.abortCode, "TP analysis thread aborted with code: " + GetErrMessage(ar.abortCode))
	endif

	DFREF dfr = ar.dfr

	WAVE/SDFR=dfr inData     = outData
	NVAR/SDFR=dfr now        = now
	NVAR/SDFR=dfr headstage  = headstage
	SVAR/SDFR=dfr device     = device
	NVAR/SDFR=dfr marker     = marker
	NVAR/SDFR=dfr activeADCs = activeADCs

	WAVE asyncBuffer = GetTPResultAsyncBuffer(device)

	bufSize     = DimSize(asyncBuffer, ROWS)
	posMarker   = FindDimLabel(asyncBuffer, LAYERS, "MARKER")
	posAsync    = FindDimLabel(asyncBuffer, COLS, "ASYNCDATA")
	posBaseline = FindDimLabel(asyncBuffer, COLS, "BASELINE")
	posSSRes    = FindDimLabel(asyncBuffer, COLS, "STEADYSTATERES")
	posInstRes  = FindDimLabel(asyncBuffer, COLS, "INSTANTRES")
	posElevSS   = FindDimLabel(asyncBuffer, COLS, "ELEVATED_SS")
	posElevInst = FindDimLabel(asyncBuffer, COLS, "ELEVATED_INST")

	FindValue/RMD=[][posAsync][posMarker, posMarker]/V=(marker)/T=0 asyncBuffer
	i = (V_Value >= 0) ? V_Row : bufSize

	if(i == bufSize)
		Redimension/N=(bufSize + 1, -1, -1) asyncBuffer
		asyncBuffer[bufSize][][]                      = NaN
		asyncBuffer[bufSize][posAsync][%REC_CHANNELS] = 0
		asyncBuffer[bufSize][posAsync][posMarker]     = marker
	endif

	asyncBuffer[i][posBaseline][headstage] = inData[%BASELINE]
	asyncBuffer[i][posSSRes][headstage]    = inData[%STEADYSTATERES]
	asyncBuffer[i][posInstRes][headstage]  = inData[%INSTANTRES]
	asyncBuffer[i][posElevSS][headstage]   = inData[%ELEVATED_SS]
	asyncBuffer[i][posElevInst][headstage] = inData[%ELEVATED_INST]

	asyncBuffer[i][posAsync][%NOW]           = now
	asyncBuffer[i][posAsync][%REC_CHANNELS] += 1

	// got one set of results ready
	if(asyncBuffer[i][posAsync][%REC_CHANNELS] == activeADCs)

		WAVE TPResults  = GetTPResults(device)
		WAVE TPSettings = GetTPSettings(device)

		MultiThread TPResults[%BaselineSteadyState][] = asyncBuffer[i][posBaseline][q]
		MultiThread TPResults[%ResistanceSteadyState][] = asyncBuffer[i][posSSRes][q]
		MultiThread TPResults[%ResistanceInst][] = asyncBuffer[i][posInstRes][q]
		MultiThread TPResults[%ElevatedSteadyState][] = asyncBuffer[i][posElevSS][q]
		MultiThread TPResults[%ElevatedInst][] = asyncBuffer[i][posElevInst][q]

		// Remove finished results from buffer
		DeletePoints i, 1, asyncBuffer
		if(!DimSize(asyncBuffer, ROWS))
			KillOrMoveToTrash(wv = asyncBuffer)
		endif

		if(TPSettings[%bufferSize][INDEP_HEADSTAGE] > 1)
			WAVE TPResultsBuffer = GetTPResultsBuffer(device)
			TP_CalculateAverage(TPResultsBuffer, TPResults)
		endif

		TPResults[%AutoTPAmplitude][]             = NaN
		TPResults[%AutoTPBaseline][]              = NaN
		TPResults[%AutoTPBaselineRangeExceeded][] = NaN
		TPResults[%AutoTPBaselineFitResult][]     = NaN

		MultiThread TPResults[%AutoTPDeltaV][] = TPResults[%ElevatedSteadyState][q] - TPResults[%BaselineSteadyState][q]

		TP_AutoAmplitudeAndBaseline(device, TPResults, marker)
		DQ_ApplyAutoBias(device, TPResults)
		TP_RecordTP(device, TPResults, now, marker)
	endif
End

static Function/WAVE TP_CreateOverrideResults(string device, variable type)

	variable numRows, numCols, numLayers
	string labels

	switch(type)
		case TP_OVERRIDE_RESULTS_AUTO_TP:
			numRows   = MINIMUM_WAVE_SIZE
			numCols   = NUM_HEADSTAGES
			numLayers = 3
			labels    = "Factor;Voltage;BaselineFitResult"
			break
		default:
			ASSERT(0, "Invalid type")
	endswitch

	KillOrMoveToTrash(wv = GetOverrideResults())

	Make/D/N=(numRows, numCols, numLayers) root:overrideResults/WAVE=wv

	wv[] = NaN

	SetDimensionLabels(wv, labels, LAYERS)

	Make/FREE/N=(NUM_HEADSTAGES) zeros
	SetStringInWaveNote(wv, "Next unread index [baseline]", NumericWaveToList(zeros, ","))
	SetStringInWaveNote(wv, "Next unread index [amplitude]", NumericWaveToList(zeros, ","))

	return wv
End

/// @brief Return a 2D wave with two testpulses concatenated
///
/// Rows:
/// - TPs
///
/// Columns:
/// - Active headstages
static Function/WAVE TP_GetTPWaveForAutoTP(string device, variable marker)

	WAVE/Z/WAVE TPs = TP_GetStoredTPs(device, marker, 2)

	if(!WaveExists(TPs))
		return $""
	endif

	Concatenate/DL/FREE/NP=0 {TPs}, allData

	return allData
End

static Function TP_AutoBaseline(string device, variable headstage, WAVE TPResults, WAVE TPs)

	variable idx, pulseLengthMS, tau, baseline, fac, baselineFracCand, needsUpdate
	variable rangeExceeded, result
	string msg

	WAVE TPSettings = GetTPSettings(device)

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	Make/D/FREE/N=(NUM_HEADSTAGES) baselineFrac = NaN

	pulseLengthMS = TPSettings[%durationMS][INDEP_HEADSTAGE]

	// extract data from single headstage
	idx = FindDimLabel(TPs, COLS, "HS_" + num2str(headstage))
	ASSERT(idx >= 0, "Invalid dimension label")

	Duplicate/FREE/RMD=[*][idx] TPs, data
	Redimension/N=(numpnts(data))/E=1 data

	[result, tau, baseline] = TP_AutoFitBaseline(data, pulseLengthMS)

	if(TestOverrideActive())
		WAVE overrideResults = GetOverrideResults()
		WAVE indizes         = ListToNumericWave(GetStringFromWaveNote(overrideResults, "Next unread index [baseline]"), ",")
		ASSERT(indizes[headstage] < DimSize(overrideResults, ROWS), "Invalid index")
		fac                 = overrideResults[indizes[headstage]][headstage][%Factor]
		result              = overrideResults[indizes[headstage]][headstage][%BaselineFitResult]
		indizes[headstage] += 1
		SetStringInWaveNote(overrideResults, "Next unread index [baseline]", NumericWaveToList(indizes, ","))
		tau = fac * baseline
	else
		fac = tau / baseline
	endif

	sprintf msg, "TP_AutoFitBaseline: result %g, tau %g, baseline %g", result, tau, baseline
	DEBUGPRINT(msg)

	TPResults[%AutoTPBaselineFitResult][headstage] = result

	switch(result)
		case TP_BASELINE_FIT_RESULT_OK:
			// nothing to do
			break
		case TP_BASELINE_FIT_RESULT_ERROR:
		case TP_BASELINE_FIT_RESULT_TOO_NOISY:
			TPResults[%AutoTPBaseline][headstage]              = 0
			TPResults[%AutoTPBaselineRangeExceeded][headstage] = 0
			return NaN
		default:
			ASSERT(0, "Unknown return value from TP_AutoFitBaseline")
	endswitch

	if(fac >= TP_BASELINE_RATIO_LOW && fac <= TP_BASELINE_RATIO_HIGH)
		TPResults[%AutoTPBaseline][headstage]              = 1
		TPResults[%AutoTPBaselineRangeExceeded][headstage] = 0
	else
		TPResults[%AutoTPBaseline][headstage] = 0

		// optimum baseline length [ms]: baseline * (fac / TP_BASELINE_RATIO_OPT) = tau / TP_BASELINE_RATIO_OPT
		baselineFracCand        = TP_CalculateBaselineFraction(pulseLengthMS, pulseLengthMS + tau / TP_BASELINE_RATIO_OPT)
		baselineFrac[headstage] = limit(baselineFracCand, TP_BASELINE_FRACTION_LOW, TP_BASELINE_FRACTION_HIGH)

		TPResults[%AutoTPBaselineRangeExceeded][headstage] = (baselineFracCand != baselineFrac[headstage])

		needsUpdate = 1
	endif

	sprintf msg, "headstage %d, tau %g, baseline %g, baselineFracCand %g, factor %g, QC %s, range exceeded: %s", headstage, tau, baseline, baselineFracCand, fac, ToPassFail(TPResults[%AutoTPBaseline][headstage]), ToTrueFalse(TPResults[%AutoTPBaselineRangeExceeded][headstage])
	DEBUGPRINT(msg)

	if(needsUpdate)
		// now use the maximum of all baselines
		WAVE baselineFracClean = ZapNaNs(baselineFrac)

		TPSettings[%baselinePerc][INDEP_HEADSTAGE] = RoundNumber(WaveMax(baselineFracClean) * ONE_TO_PERCENT, TP_SET_PRECISION)

		DAP_TPSettingsToGUI(device, entry = "baselinePerc")
	endif
End

/// @brief Fit the tail of the first TP with an expontential and return it's time constant.
///
/// @verbatim
///
///        +----+        +----+
///        |    |        |    |
///        |    |        |    |
///        |    |        |    |
///        |    |        |    |
///    ----+    +--------+    +----
///
///             <-------->
///            Fitting range
///
///    <------------>
///        One TP
///
///        <---->
///        Pulse
///
/// @endverbatim
///
/// @param data          input data
/// @param pulseLengthMS length of the pulse (high part) of the testpulse [ms]
///
/// @retval result       One of @ref TPBaselineFitResults
/// @retval tau          time constant of the decay [ms]
/// @retval baseline     baseline length of one pulse (same as the fitting range) [ms]
static Function [variable result, variable tau, variable baseline] TP_AutoFitBaseline(WAVE data, variable pulseLengthMS)

	variable first, last, firstPnt, lastPnt, totalLength, debugEnabled, fitQuality, referenceThreshold
	variable V_FitQuitReason, V_FitOptions, V_FitError, V_AbortCode
	string msg, win

	ASSERT(IsFloatingPointWave(data), "Expected floating point wave")
	ASSERT(DimSize(data, COLS) <= 1, "Invalid data dimensions")
	ASSERT(DimOffset(data, ROWS) == 0, "Invalid dimension offset")
	ASSERT(pulseLengthMS > 0, "Expected valid pulse length")

	totalLength = DimDelta(data, ROWS) * (DimSize(data, ROWS) - 1)

	first = 1 / 4 * totalLength + 1 / 2 * pulseLengthMS
	last  = 3 / 4 * totalLength - 1 / 2 * pulseLengthMS
	ASSERT(first < last, "Invalid first/last")

	baseline = last - first

	first += TP_BASELINE_FITTING_INSET
	last  -= TP_BASELINE_FITTING_INSET

#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForCaller())
		debugEnabled = 1

		Duplicate/O data, root:AutoTPDebuggingData/WAVE=displayedData
		Duplicate/O data, root:Res_AutoTPDebuggingData/WAVE=residuals

		if(!WindowExists("AutoTPDebugging"))
			Display/K=1/N=AutoTPDebugging displayedData

			AppendToGraph/W=AutoTPDebugging/L=res residuals
			AppendToGraph/W=AutoTPDebugging displayedData
			ModifyGraph/W=AutoTPDebugging rgb(Res_AutoTPDebuggingData)=(0, 0, 0), rgb(AutoTPDebuggingData)=(655355, 0, 0)
			ModifyGraph axisEnab(left)={0, 0.65}, axisEnab(res)={0.7, 1}, freePos(res)=0
		endif

		Cursor/W=AutoTPDebugging A, $NameOfWave(displayedData), first
		Cursor/W=AutoTPDebugging B, $NameOfWave(displayedData), last

		WAVE data      = root:AutoTPDebuggingData
		WAVE residuals = root:Res_AutoTPDebuggingData
	endif
#endif // DEBUGGING_ENABLED

	if(!debugEnabled)
		Duplicate/FREE data, residuals
	endif

	residuals = NaN

	Make/FREE/D/N=3 coefWave

	V_FitOptions = 4

	AssertOnAndClearRTError()
	try
		V_FitError  = 0
		V_AbortCode = 0

		firstPnt = ScaleToIndex(data, first, ROWS)
		lastPnt  = ScaleToIndex(data, last, ROWS)
		CurveFit/Q=(!debugEnabled)/N=(!debugEnabled)/NTHR=1/M=0/W=2 exp_XOffset, kwCWave=coefWave, data[firstPnt, lastPnt]/A=(debugEnabled)/R=residuals; AbortOnRTE
	catch
		msg = GetRTErrMessage()
		ClearRTError()

		ASSERT(0, "CurveFit failed with error: " + msg)
	endtry

	MakeWaveFree($"W_Sigma")
	MakeWaveFree($"W_FitConstants")

	sprintf msg, "Fit result: tau %g, V_FitError %g, V_FitQuitReason %g\r", coefWave[2], V_FitError, V_FitQuitReason
	DEBUGPRINT(msg)

	if(V_FitError || V_FitQuitReason)
		return [TP_BASELINE_FIT_RESULT_ERROR, NaN, baseline]
	endif

	// @todo check coefficient sign, range, etc

	// detect residuals being too large
	Multithread residuals = residuals[p]^2
	fitQuality         = Sum(residuals, first, last) / (lastPnt - firstPnt)
	referenceThreshold = 0.25 * abs(WaveMax(data, first, last))

	sprintf msg, "fitQuality %g, referenceThreshold %g\r", fitQuality, referenceThreshold
	DEBUGPRINT(msg)

	ASSERT(IsFinite(fitQuality), "Invalid fit quality")

	if(fitQuality > referenceThreshold)
		return [TP_BASELINE_FIT_RESULT_TOO_NOISY, NaN, baseline]
	endif

	return [TP_BASELINE_FIT_RESULT_OK, coefWave[2], baseline]
End

/// @brief Automatically tune the Testpulse amplitude and baseline
///
/// Decision logic flowchart:
///
/// \rst
/// .. image:: /dot/auto-testpulse.svg
/// \endrst
static Function TP_AutoAmplitudeAndBaseline(string device, WAVE TPResults, variable marker)

	variable i, maximumCurrent, targetVoltage, targetVoltageTol, resistance, voltage, current
	variable needsUpdate, lastInvocation, curTime, scalar, skipAutoBaseline
	string msg

	NVAR daqRunMode = $GetDataAcqRunMode(device)

	if(daqRunMode != DAQ_NOT_RUNNING)
		// don't do anything for TP during DAQ
		// and TP during ITI
		return NaN
	endif

	WAVE TPSettings = GetTPSettings(device)

	WAVE/Z TPs = TP_GetTPWaveForAutoTP(device, marker)

	if(!WaveExists(TPs))
		return NaN
	endif

	WAVE TPStorage = GetTPStorage(device)
	lastInvocation = GetNumberFromWaveNote(TPStorage, AUTOTP_LAST_INVOCATION_KEY)
	curTime        = ticks * TICKS_TO_SECONDS

	if(IsFinite(lastInvocation) && (curTime - lastInvocation) < TPSettings[%autoTPInterval][INDEP_HEADSTAGE])
		return NaN
	endif

	SetNumberInWaveNote(TPStorage, AUTOTP_LAST_INVOCATION_KEY, curTime, format = "%.06f")

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		if(DAG_GetHeadstageMode(device, i) != I_CLAMP_MODE)
			continue
		endif

		if(!TPSettings[%autoTPEnable][i])
			continue
		endif

		/// all variables holding physical units use plain values without prefixes
		/// e.g Amps instead of pA

		maximumCurrent = abs(TPSettings[%autoAmpMaxCurrent][i] * PICO_TO_ONE)

		targetVoltage    = TPSettings[%autoAmpVoltage][i] * MILLI_TO_ONE
		targetVoltageTol = TPSettings[%autoAmpVoltageRange][i] * MILLI_TO_ONE

		resistance = TPResults[%ResistanceSteadyState][i] * MEGA_TO_ONE

		if(TestOverrideActive())
			WAVE overrideResults = GetOverrideResults()
			WAVE indizes         = ListToNumericWave(GetStringFromWaveNote(overrideResults, "Next unread index [amplitude]"), ",")
			ASSERT(indizes[i] < DimSize(overrideResults, ROWS), "Invalid index")
			voltage     = overrideResults[indizes[i]][i][%Voltage]
			indizes[i] += 1
			SetStringInWaveNote(overrideResults, "Next unread index [amplitude]", NumericWaveToList(indizes, ","))
		else
			voltage = TPResults[%AutoTPDeltaV][i] * MILLI_TO_ONE
		endif

		skipAutoBaseline = 0

		if(sign(targetVoltage) != sign(TPSettings[%amplitudeIC][i]))
			TPSettings[%amplitudeIC][i] = RoundNumber(abs(TPSettings[%amplitudeIC][i]) * sign(targetVoltage), TP_SET_PRECISION)

			skipAutoBaseline = 1
			needsUpdate      = 1
		endif

		if(abs(TPSettings[%amplitudeIC][i]) <= 5)
			// generate random amplitude from [5, 10)
			TPSettings[%amplitudeIC][i] = RoundNumber((7.5 + enoise(2.5, NOISE_GEN_MERSENNE_TWISTER)) * sign(targetVoltage), TP_SET_PRECISION)

			skipAutoBaseline = 1
			needsUpdate      = 1
		endif

		if(skipAutoBaseline)
			TPResults[%AutoTPAmplitude][i] = 0
		else
			TP_AutoBaseline(device, i, TPResults, TPs)

			ASSERT(IsFinite(TPResults[%AutoTPBaseline][i]), "Unexpected AutoTPBaseline result")

			if(!TPResults[%AutoTPBaseline][i])
				// only adapt amplitude once the baseline passes
				continue
			endif

			if(abs(targetVoltage - voltage) < targetVoltageTol)
				TPResults[%AutoTPAmplitude][i] = 1
				sprintf msg, "headstage %d has passing auto TP amplitude", i
				DEBUGPRINT(msg)
				continue
			endif

			// Auto TP amplitude always fails when we get here
			TPResults[%AutoTPAmplitude][i] = 0

			if(!isFinite(resistance))
				printf "Headstage %d: Can not apply auto TP amplitude as the measured resistance is non-finite.\r", i
				continue
			endif

			scalar = TPSettings[%autoTPPercentage][INDEP_HEADSTAGE] * PERCENT_TO_ONE

			current = (targetVoltage - voltage) / resistance

			sprintf msg, "headstage %d: current  %g, targetVoltage %g, resistance %g, scalar %g\r", i, current, targetVoltage, resistance, scalar
			DEBUGPRINT(msg)

			current = TPSettings[%amplitudeIC][i] * PICO_TO_ONE + current * scalar

			if(abs(current) > maximumCurrent)
				printf "Headstage %d: Not applying new amplitude of %.0W0PA as that would exceed the maximum allowed current of %.0W0PA.\r", i, current, maximumCurrent
				continue
			endif

			TPSettings[%amplitudeIC][i] = RoundNumber(current * ONE_TO_PICO, TP_SET_PRECISION)
		endif

		sprintf msg, "headstage %d has failing auto TP amplitude and will use a new IC amplitude of %g", i, TPSettings[%amplitudeIC][i]
		DEBUGPRINT(msg)

		needsUpdate = 1
	endfor

	if(needsUpdate)
		DAP_TPSettingsToGUI(device, entry = "amplitudeIC")
	endif
End

Function TP_AutoTPActive(string device)

	WAVE settings = GetTPSettings(device)

	WAVE statusHS = DAG_GetActiveHeadstages(device, I_CLAMP_MODE)

	Duplicate/FREE/RMD=[FindDimLabel(settings, ROWS, "autoTPEnable")][0, NUM_HEADSTAGES - 1] settings, autoTPEnable
	Redimension/N=(numpnts(autoTPEnable))/E=1 autoTPEnable

	autoTPEnable[] = statusHS[p] && autoTPEnable[p]

	return Sum(autoTPEnable) > 0
End

static Function TP_AutoTPTurnOff(string device, WAVE autoTPEnable, variable headstage, variable QC)

	autoTPEnable[headstage] = 0

	QC = !!QC

	PUB_AutoTPResult(device, headstage, QC)

	TP_AutoTPGenerateNewCycleID(device, headstage = headstage)

	WAVE TPSettingsLBN = GetTPSettingsLabnotebook(device)
	TPSettingsLBN[0][%$"TP Auto QC"][headstage] = QC
End

/// @brief Disable Auto TP if it passed `TP_AUTO_TP_CONSECUTIVE_PASSES` times in a row.
static Function TP_AutoDisableIfFinished(string device, WAVE TPStorage)

	variable i, needsUpdate, TPState

	WAVE TPSettings = GetTPSettings(device)

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	WAVE autoTPEnable = LBN_GetNumericWave()
	autoTPEnable[] = TPSettings[%autoTPEnable][p]

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(!statusHS[i])
			continue
		endif

		if(!TPSettings[%autoTPEnable][i])
			continue
		endif

		if(DAG_GetHeadstageMode(device, i) != I_CLAMP_MODE)
			continue
		endif

		// auto TP is enabled on this headstage
		WAVE/Z amplitudePasses = TP_GetValuesFromTPStorage(TPStorage, i, "AutoTPAmplitude", TP_AUTO_TP_CONSECUTIVE_PASSES, options = TP_GETVALUES_LATEST_AUTOTPCYCLE)
		WAVE/Z baselinePasses  = TP_GetValuesFromTPStorage(TPStorage, i, "AutoTPBaseline", TP_AUTO_TP_CONSECUTIVE_PASSES, options = TP_GETVALUES_LATEST_AUTOTPCYCLE)

		if((WaveExists(amplitudePasses) && Sum(amplitudePasses) == TP_AUTO_TP_CONSECUTIVE_PASSES) \
		   && (WaveExists(baselinePasses) && Sum(baselinePasses) == TP_AUTO_TP_CONSECUTIVE_PASSES))

			TP_AutoTPTurnOff(device, autoTPEnable, i, 1)

			needsUpdate = 1
			continue
		endif

		WAVE/Z baselineRangeExceeded = TP_GetValuesFromTPStorage(TPStorage, i, "AutoTPBaselineRangeExceeded", TP_AUTO_TP_BASELINE_RANGE_EXCEEDED_FAILS, options = TP_GETVALUES_LATEST_AUTOTPCYCLE)
		if(WaveExists(baselineRangeExceeded) && Sum(baselineRangeExceeded) == TP_AUTO_TP_BASELINE_RANGE_EXCEEDED_FAILS)
			printf "Auto TP baseline adaptation failed %d times in a row for headstage %d to calculate a value in range, turning it off.\r", TP_AUTO_TP_BASELINE_RANGE_EXCEEDED_FAILS, i
			ControlWindowToFront()

			TP_AutoTPTurnOff(device, autoTPEnable, i, 0)

			needsUpdate = 1
			continue
		endif
	endfor

	if(needsUpdate)
		// implicitly transfers TPSettings to TPSettingsLBN and write entries to labnotebook
		TPState = TP_StopTestPulse(device)

		// only now can we apply the new auto TP enabled state
		TPSettings[%autoTPEnable][] = autoTPEnable[q]

		DAP_TPSettingsToGUI(device, entry = "autoTPEnable")

		TP_RestartTestPulse(device, TPState)
	endif

	if(needsUpdate)
		DAP_TPSettingsToGUI(device, entry = "autoTPEnable")
	endif
End

/// @brief Generate new auto TP cycle IDs
///
/// This is required everytime we lock a device or toggle Auto TP for a headstage
///
/// @param device device
/// @param headstage  [optional, default to all headstages] only update it for a specific headstage
/// @param first      [optional, default to all headstages] only update the range [first, last]
/// @param last       [optional, default to all headstages] only update the range [first, last]
Function TP_AutoTPGenerateNewCycleID(string device, [variable headstage, variable first, variable last])

	if(!ParamIsDefault(headstage))
		first = headstage
		last  = headstage
	elseif(!ParamIsDefault(first) && !ParamIsDefault(last))
		// nothing to set
	elseif(!ParamIsDefault(headstage) && !ParamIsDefault(first) && !ParamIsDefault(last))
		first = 0
		last  = NUM_HEADSTAGES
	endif

	WAVE TPSettings = GetTPSettings(device)

	// we don't look at HS activeness here, this is done in TP_RecordTP()
	TPSettings[%autoTPCycleID][first, last] = GetNextRandomNumberForDevice(device)
End

/// @brief Return the last `numReqEntries` non-NaN values from layer `entry` of `headstage`
///
/// @param TPStorage     TP results wave, see GetTPStorage()
/// @param headstage     Headstage
/// @param entry         Name of the value to search
/// @param numReqEntries Number of entries to return, supports integer values and inf
/// @param options       [optional, default to nothing] One of @ref TPStorageQueryingOptions
Function/WAVE TP_GetValuesFromTPStorage(WAVE TPStorage, variable headstage, string entry, variable numReqEntries, [variable options])

	variable i, idx, value, entryLayer, lastValidEntry, numValidEntries, currentAutoTPCycleID, latestAutoTPCycleID

	if(ParamIsDefault(options))
		options = TP_GETVALUES_DEFAULT
	else
		ASSERT(options == TP_GETVALUES_DEFAULT || options == TP_GETVALUES_LATEST_AUTOTPCYCLE, "Invalid option")
	endif

	// NOTE_INDEX gives the next free index *and* therefore also the number of valid entries
	numValidEntries = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)

	if(numValidEntries <= 0)
		return $""
	endif

	lastValidEntry = numValidEntries - 1

	latestAutoTPCycleID = TPStorage[lastValidEntry][headstage][%autoTPCycleID]

	if(numReqEntries == Inf)
		entryLayer = FindDimLabel(TPstorage, LAYERS, entry)
		ASSERT(entryLayer >= 0, "Invalid entry")
		Duplicate/FREE/RMD=[0, lastValidEntry][headstage][entryLayer] TPStorage, slice
		Redimension/N=(numpnts(slice))/E=1 slice

		if(options == TP_GETVALUES_LATEST_AUTOTPCYCLE)
			// filter all entries which don't have the latest ID out
			slice[] = (TPStorage[p][headstage][%autoTPCycleID] == latestAutoTPCycleID) ? slice[p] : NaN
		endif

		return ZapNaNs(slice)
	endif

	ASSERT(IsInteger(numReqEntries) && numReqEntries > 0, "Number of required entries must be larger than zero")

	if(numReqEntries > numValidEntries)
		return $""
	endif

	Make/FREE/D/N=(numReqEntries) result = NaN

	// take the last finite values
	for(i = lastValidEntry; i >= 0; i -= 1)
		if(idx == numReqEntries)
			break
		endif

		value = TPStorage[i][headstage][%$entry]

		if(!IsFinite(value))
			continue
		endif

		if(options == TP_GETVALUES_LATEST_AUTOTPCYCLE)
			currentAutoTPCycleID = TPStorage[i][headstage][%autoTPCycleID]

			if(currentAutoTPCycleID != latestAutoTPCycleID)
				continue
			endif
		endif

		result[idx++] = value
	endfor

	if(idx == numReqEntries)
		ASSERT(!IsNaN(Sum(result)), "Expected non-nan sum")
		return result
	endif

	return $""
End

/// @brief This function analyses a TP data set. It is called by the ASYNC frame work in an own thread.
/// 		  currently six properties are determined.
///
/// @param dfrInp input data folder from the ASYNC framework, parameter input order therein follows the setup in TP_SendToAnalysis()
///
threadsafe Function/DF TP_TSAnalysis(DFREF dfrInp)

	variable evalRange, refTime, refPoint, tpStartPoint
	variable sampleInt
	variable avgBaselineSS, avgTPSS, instVal, evalOffsetPointsCorrected, instPoint

	DFREF dfrOut = NewFreeDataFolder()

	WAVE             data             = dfrInp:param0
	NVAR/SDFR=dfrInp clampAmp         = param1
	NVAR/SDFR=dfrInp clampMode        = param2
	NVAR/SDFR=dfrInp duration         = param3
	NVAR/SDFR=dfrInp baselineFrac     = param4
	NVAR/SDFR=dfrInp lengthTPInPoints = param5
	NVAR/SDFR=dfrInp now              = param6
	NVAR/SDFR=dfrInp headstage        = param7
	SVAR/SDFR=dfrInp device           = param8
	NVAR/SDFR=dfrInp marker           = param9
	NVAR/SDFR=dfrInp activeADCs       = param10

#if defined(TP_ANALYSIS_DEBUGGING)
	DEBUGPRINT_TS("Marker: ", var = marker)
	Duplicate data, dfrOut:colors
	Duplicate data, dfrOut:data
	WAVE colors = dfrOut:colors
	colors                          = 0
	colors[0, lengthTPInPoints - 1] = 100
#endif

	// Rows:
	// 0: base line level
	// 1: steady state resistance
	// 2: instantaneous resistance
	// 3: averaged elevated level (steady state)
	// 4: averaged elevated level (instantaneous)
	Make/N=5/D dfrOut:outData/WAVE=outData
	SetDimLabel ROWS, 0, BASELINE, outData
	SetDimLabel ROWS, 1, STEADYSTATERES, outData
	SetDimLabel ROWS, 2, INSTANTRES, outData
	SetDimLabel ROWS, 3, ELEVATED_SS, outData
	SetDimLabel ROWS, 4, ELEVATED_INST, outData

	sampleInt    = DimDelta(data, ROWS)
	tpStartPoint = baseLineFrac * lengthTPInPoints
	evalRange    = min(5 / sampleInt, min(duration * 0.2, tpStartPoint * 0.2)) * sampleInt

	// correct TP_EVAL_POINT_OFFSET for the non-standard sampling interval
	evalOffsetPointsCorrected = (TP_EVAL_POINT_OFFSET / sampleInt) * HARDWARE_ITC_MIN_SAMPINT

	refTime       = (tpStartPoint - evalOffsetPointsCorrected) * sampleInt
	AvgBaselineSS = mean(data, refTime - evalRange, refTime)

#if defined(TP_ANALYSIS_DEBUGGING)
	// color BASE
	variable refpt = refTime / sampleInt
	colors[refpt - evalRange / sampleInt, refpt] = 50
	DEBUGPRINT_TS("SampleInt: ", var = sampleInt)
	DEBUGPRINT_TS("tpStartPoint: ", var = tpStartPoint)
	DEBUGPRINT_TS("evalRange (ms): ", var = evalRange)
	DEBUGPRINT_TS("evalRange in points: ", var = evalRange / sampleInt)
	DEBUGPRINT_TS("Base range begin (ms): ", var = refTime - evalRange)
	DEBUGPRINT_TS("Base range eng (ms): ", var = refTime)
	DEBUGPRINT_TS("average BaseLine: ", var = AvgBaselineSS)
#endif

	refTime = (lengthTPInPoints - tpStartPoint - evalOffsetPointsCorrected) * sampleInt
	avgTPSS = mean(data, refTime - evalRange, refTime)

#if defined(TP_ANALYSIS_DEBUGGING)
	DEBUGPRINT_TS("steady state range begin (ms): ", var = refTime - evalRange)
	DEBUGPRINT_TS("steady state range eng (ms): ", var = refTime)
	DEBUGPRINT_TS("steady state average: ", var = avgTPSS)
	// color steady state
	refpt                                        = lengthTPInPoints - tpStartPoint - evalOffsetPointsCorrected
	colors[refpt - evalRange / sampleInt, refpt] = 50
	// color instantaneous
	refpt                                   = tpStartPoint + evalOffsetPointsCorrected
	colors[refpt, refpt + 0.25 / sampleInt] = 50
#endif

	refPoint = tpStartPoint + evalOffsetPointsCorrected
	// as data is always too small for threaded execution, the values of V_minRowLoc/V_maxRowLoc are reproducible
	WaveStats/P/Q/M=1/R=[refPoint, refPoint + 0.25 / sampleInt] data
	instPoint = (clampAmp < 0) ? V_minRowLoc : V_maxRowLoc
	if(instPoint == -1)
		// all wave data is NaN
		instVal = NaN
	else
		instVal = data[instPoint]
	endif

#if defined(TP_ANALYSIS_DEBUGGING)
	DEBUGPRINT_TS("instantaneous refPoint: ", var = instPoint)
	DEBUGPRINT_TS("instantaneous value: ", var = instVal)
	colors[instPoint] = 75
#endif

	if(clampMode == I_CLAMP_MODE)
		outData[1] = (avgTPSS - avgBaselineSS) * MILLI_TO_ONE / (clampAmp * PICO_TO_ONE) * ONE_TO_MEGA
		outData[2] = (instVal - avgBaselineSS) * MILLI_TO_ONE / (clampAmp * PICO_TO_ONE) * ONE_TO_MEGA
	else
		outData[1] = (clampAmp * MILLI_TO_ONE) / ((avgTPSS - avgBaselineSS) * PICO_TO_ONE) * ONE_TO_MEGA
		outData[2] = (clampAmp * MILLI_TO_ONE) / ((instVal - avgBaselineSS) * PICO_TO_ONE) * ONE_TO_MEGA
	endif
	outData[0] = avgBaselineSS
	outData[3] = avgTPSS
	outData[4] = instVal

#if defined(TP_ANALYSIS_DEBUGGING)
	DEBUGPRINT_TS("instantaneous resistance: ", var = outData[2])
	DEBUGPRINT_TS("steady state resistance: ", var = outData[1])
#endif

	// additional data copy
	variable/G dfrOut:now        = now
	variable/G dfrOut:headstage  = headstage
	string/G   dfrOut:device     = device
	variable/G dfrOut:marker     = marker
	variable/G dfrOut:activeADCs = activeADCs

	return dfrOut
End

/// @brief Calculates running average [box average] for all entries and all headstages
static Function TP_CalculateAverage(WAVE TPResultsBuffer, WAVE TPResults)

	variable numEntries, numLayers

	MatrixOp/FREE TPResultsBufferCopy = rotateLayers(TPResultsBuffer, 1)
	TPResultsBuffer[][][]  = TPResultsBufferCopy[p][q][r]
	TPResultsBuffer[][][0] = TPResults[p][q]

	numLayers  = DimSize(TPResultsBuffer, LAYERS)
	numEntries = GetNumberFromWaveNote(TPResultsBuffer, NOTE_INDEX)

	if(numEntries < numLayers)
		numEntries += 1
		SetNumberInWaveNote(TPResultsBuffer, NOTE_INDEX, numEntries)
		Duplicate/FREE/RMD=[][][0, numEntries - 1] TPResultsBuffer, TPResultsBufferSub
		MatrixOp/FREE results = sumBeams(TPResultsBufferSub) / numEntries
	else
		ASSERT(numEntries == numLayers, "Unexpected number of entries/layers")
		MatrixOp/FREE results = sumBeams(TPResultsBuffer) / numEntries
	endif

	TPResults[][] = results[p][q]
End

/// @brief Records values from TPResults into TPStorage at defined intervals.
///
/// Used for analysis of TP over time.
static Function TP_RecordTP(string device, WAVE TPResults, variable now, variable tpMarker)

	variable delta, i, ret, lastPressureCtrl, timestamp, cycleID
	WAVE     TPStorage     = GetTPStorage(device)
	WAVE     hsProp        = GetHSProperties(device)
	variable count         = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)
	variable lastRescaling = GetNumberFromWaveNote(TPStorage, DIMENSION_SCALING_LAST_INVOC)

	if(!count)
		// time of the first sweep
		TPStorage[0][][%TimeInSeconds] = now

		WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

		for(i = 0; i < NUM_HEADSTAGES; i += 1)

			if(!statusHS[i])
				continue
			endif

			TP_UpdateHoldCmdInTPStorage(device, i)
		endfor
	endif

	ret = EnsureLargeEnoughWave(TPStorage, indexShouldExist = count, dimension = ROWS, initialValue = NaN, checkFreeMemory = 1)

	if(ret)
		HandleOutOfMemory(device, NameOfWave(TPStorage))
		return NaN
	endif

	// use the last value if we don't have a current one
	if(count > 0)
		TPStorage[count][][%HoldingCmd_VC] = !IsFinite(TPStorage[count][q][%HoldingCmd_VC]) \
		                                     ? TPStorage[count - 1][q][%HoldingCmd_VC]      \
		                                     : TPStorage[count][q][%HoldingCmd_VC]

		TPStorage[count][][%HoldingCmd_IC] = !IsFinite(TPStorage[count][q][%HoldingCmd_IC]) \
		                                     ? TPStorage[count - 1][q][%HoldingCmd_IC]      \
		                                     : TPStorage[count][q][%HoldingCmd_IC]
	endif

	TPStorage[count][][%TimeInSeconds] = now

	// store the current time in a variable first
	// so that all columns have the same timestamp
	timestamp                                       = DateTime
	TPStorage[count][][%TimeStamp]                  = timestamp
	timestamp                                       = DateTimeInUTC()
	TPStorage[count][][%TimeStampSinceIgorEpochUTC] = timestamp

	TPStorage[count][][%PeakResistance]        = min(TPResults[%ResistanceInst][q], TP_MAX_VALID_RESISTANCE)
	TPStorage[count][][%SteadyStateResistance] = min(TPResults[%ResistanceSteadyState][q], TP_MAX_VALID_RESISTANCE)
	TPStorage[count][][%ValidState]            = TPStorage[count][q][%PeakResistance] < TP_MAX_VALID_RESISTANCE         \
	                                             && TPStorage[count][q][%SteadyStateResistance] < TP_MAX_VALID_RESISTANCE

	TPStorage[count][][%DAC]       = hsProp[q][%DAC]
	TPStorage[count][][%ADC]       = hsProp[q][%ADC]
	TPStorage[count][][%Headstage] = hsProp[q][%Enabled] ? q : NaN
	TPStorage[count][][%ClampMode] = hsProp[q][%ClampMode]

	TPStorage[count][][%Baseline_VC] = (hsProp[q][%ClampMode] == V_CLAMP_MODE) ? TPResults[%BaselineSteadyState][q] : NaN
	TPStorage[count][][%Baseline_IC] = (hsProp[q][%ClampMode] == I_CLAMP_MODE) ? TPResults[%BaselineSteadyState][q] : NaN

	TPStorage[count][][%DeltaTimeInSeconds] = (count > 0) ? (now - TPStorage[0][0][%TimeInSeconds]) : 0
	TPStorage[count][][%TPMarker]           = tpMarker

	cycleID                        = ROVAR(GetTestpulseCycleID(device))
	TPStorage[count][][%TPCycleID] = cycleID

	TPStorage[count][][%AutoTPAmplitude]             = TPResults[%AutoTPAmplitude][q]
	TPStorage[count][][%AutoTPBaseline]              = TPResults[%AutoTPBaseline][q]
	TPStorage[count][][%AutoTPBaselineRangeExceeded] = TPResults[%AutoTPBaselineRangeExceeded][q]
	TPStorage[count][][%AutoTPBaselineFitResult]     = TPResults[%AutoTPBaselineFitResult][q]
	TPStorage[count][][%AutoTPDeltaV]                = TPResults[%AutoTPDeltaV][q]

	WAVE TPSettings = GetTPSettings(device)
	TPStorage[count][][%AutoTPCycleID] = hsProp[q][%Enabled] ? TPSettings[%autoTPCycleID][q] : NaN

	lastPressureCtrl = GetNumberFromWaveNote(TPStorage, PRESSURE_CTRL_LAST_INVOC)
	if((now - lastPressureCtrl) > TP_PRESSURE_INTERVAL)
		P_PressureControl(device)
		SetNumberInWaveNote(TPStorage, PRESSURE_CTRL_LAST_INVOC, now, format = "%.06f")
	endif

	TP_AnalyzeTP(device, TPStorage, count)

	WAVE TPStorageDat = ExtractLogbookSliceTimeStamp(TPStorage)
	EnsureLargeEnoughWave(TPStorageDat, indexShouldExist = count, dimension = ROWS, initialValue = NaN)
	TPStorageDat[count][] = TPStorage[count][q][%TimeStampSinceIgorEpochUTC]

	SetNumberInWaveNote(TPStorage, NOTE_INDEX, count + 1)

	TP_AutoDisableIfFinished(device, TPStorage)
End

/// @brief Threadsafe wrapper for performing CurveFits on the TPStorage wave
threadsafe static Function TP_FitResistance(WAVE TPStorage, variable startRow, variable endRow, variable headstage)

	variable V_FitQuitReason, V_FitOptions, V_FitError, V_AbortCode

	// finish early on missing data
	if(!IsFinite(TPStorage[startRow][headstage][%SteadyStateResistance]) \
	   || !IsFinite(TPStorage[endRow][headstage][%SteadyStateResistance]))
		return NaN
	endif

	Make/FREE/D/N=2 coefWave
	V_FitOptions = 4

	AssertOnAndClearRTError()
	try
		V_FitError  = 0
		V_AbortCode = 0
		CurveFit/Q/N=1/NTHR=1/M=0/W=2 line, kwCWave=coefWave, TPStorage[startRow, endRow][headstage][%SteadyStateResistance]/X=TPStorage[startRow, endRow][headstage][%TimeInSeconds]/AD=0/AR=0; AbortOnRTE
		return coefWave[1]
	catch
		ClearRTError()
	endtry

	return NaN
End

/// @brief Determine the slope of the steady state resistance
/// over a user defined window (in seconds)
///
/// @param device       locked device string
/// @param TPStorage        test pulse storage wave
/// @param endRow           last valid row index in TPStorage
static Function TP_AnalyzeTP(string device, WAVE/Z TPStorage, variable endRow)

	variable i, startRow, headstage

	startRow = endRow - ceil(TP_FIT_POINTS / TP_TPSTORAGE_EVAL_INTERVAL)

	if(startRow < 0 || startRow >= endRow || !WaveExists(TPStorage) || endRow >= DimSize(TPStorage, ROWS))
		return NaN
	endif

	Make/FREE/N=(NUM_HEADSTAGES) statusHS = 0

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		headstage = TPStorage[endRow][i][%Headstage]

		if(!IsValidHeadstage(headstage) || DC_GetChannelTypefromHS(device, headstage) != DAQ_CHANNEL_TYPE_TP)
			continue
		endif

		statusHS[i] = 1
	endfor

	Multithread TPStorage[0][][%Rss_Slope] = statusHS[q] ? TP_FitResistance(TPStorage, startRow, endRow, q) : NaN
End

/// @brief Stop running background testpulse on all locked devices
Function TP_StopTestPulseOnAllDevices()

	CallFunctionForEachListItem(TP_StopTestPulse, GetListOfLockedDevices())
End

/// @sa TP_StopTestPulseWrapper
Function TP_StopTestPulseFast(string device)

	return TP_StopTestPulseWrapper(device, fast = 1)
End

/// @sa TP_StopTestPulseWrapper
Function TP_StopTestPulse(string device)

	return TP_StopTestPulseWrapper(device, fast = 0)
End

/// @brief Stop any running background test pulses
///
/// @param device device
/// @param fast       [optional, defaults to false] Performs only the totally
///                   necessary steps for tear down.
///
/// @return One of @ref TestPulseRunModes
static Function TP_StopTestPulseWrapper(string device, [variable fast])

	variable runMode

	if(ParamIsDefault(fast))
		fast = 0
	else
		fast = !!fast
	endif

	NVAR runModeGlobal = $GetTestpulseRunMode(device)

	// create copy as TP_TearDown() will change runModeGlobal
	runMode = runModeGlobal

	// clear all modifiers from runMode
	runMode = runMode & ~TEST_PULSE_DURING_RA_MOD

	if(runMode == TEST_PULSE_BG_SINGLE_DEVICE)
		TPS_StopTestPulseSingleDevice(device, fast = fast)
		return runMode
	elseif(runMode == TEST_PULSE_BG_MULTI_DEVICE)
		TPM_StopTestPulseMultiDevice(device, fast = fast)
		return runMode
	elseif(runMode == TEST_PULSE_FG_SINGLE_DEVICE)
		// can not be stopped
		return runMode
	endif

	return TEST_PULSE_NOT_RUNNING
End

/// @brief Restarts a test pulse previously stopped with #TP_StopTestPulse
Function TP_RestartTestPulse(string device, variable testPulseMode, [variable fast])

	if(ParamIsDefault(fast))
		fast = 0
	else
		fast = !!fast
	endif

	switch(testPulseMode)
		case TEST_PULSE_NOT_RUNNING:
			break // nothing to do
		case TEST_PULSE_BG_SINGLE_DEVICE:
			TPS_StartTestPulseSingleDevice(device, fast = fast)
			break
		case TEST_PULSE_BG_MULTI_DEVICE:
			TPM_StartTestPulseMultiDevice(device, fast = fast)
			break
		default:
			DEBUGPRINT("Ignoring unknown value:", var = testPulseMode)
			break
	endswitch
End

/// @brief Prepare device for TestPulse
/// @param device  device
/// @param runMode     Testpulse running mode, one of @ref TestPulseRunModes
/// @param fast        [optional, defaults to false] Performs only the totally necessary steps for setup
Function TP_Setup(string device, variable runMode, [variable fast])

	if(ParamIsDefault(fast))
		fast = 0
	else
		fast = !!fast
	endif

	if(fast)
		NVAR runModeGlobal = $GetTestpulseRunMode(device)
		runModeGlobal = runMode

		// fast restart is considered to be part of the same cycle

		NVAR deviceID = $GetDAQDeviceID(device)
		HW_PrepareAcq(GetHardwareType(device), deviceID, TEST_PULSE_MODE, flags = HARDWARE_ABORT_ON_ERROR)
		return NaN
	endif

	DC_Configure(device, TEST_PULSE_MODE, multiDevice = (runMode & TEST_PULSE_BG_MULTI_DEVICE))

	TP_SetupCommon(device)

	NVAR runModeGlobal = $GetTestpulseRunMode(device)

	if(!(runMode & TEST_PULSE_DURING_RA_MOD))
		DAP_ToggleTestpulseButton(device, TESTPULSE_BUTTON_TO_STOP)
		DisableControls(device, CONTROLS_DISABLE_DURING_DAQ_TP)
		PUB_DAQStateChange(device, TEST_PULSE_MODE, runModeGlobal, runMode)
	endif

	runModeGlobal = runMode

	DAP_AdaptAutoTPColorAndDependent(device)

	NVAR deviceID = $GetDAQDeviceID(device)
	HW_PrepareAcq(GetHardwareType(device), deviceID, TEST_PULSE_MODE, flags = HARDWARE_ABORT_ON_ERROR)
End

/// @brief Common setup calls for TP and TP during DAQ
Function TP_SetupCommon(string device)

	variable now, index

	// ticks are relative to OS start time
	// so we can have "future" timestamps from existing experiments
	WAVE TPStorage = GetTPStorage(device)
	now = ticks * TICKS_TO_SECONDS

	if(GetNumberFromWaveNote(TPStorage, DIMENSION_SCALING_LAST_INVOC) > now)
		SetNumberInWaveNote(TPStorage, DIMENSION_SCALING_LAST_INVOC, 0)
	endif

	if(GetNumberFromWaveNote(TPStorage, AUTOBIAS_LAST_INVOCATION_KEY) > now)
		SetNumberInWaveNote(TPStorage, AUTOBIAS_LAST_INVOCATION_KEY, 0)
	endif

	if(GetNumberFromWaveNote(TPStorage, PRESSURE_CTRL_LAST_INVOC) > now)
		SetNumberInWaveNote(TPStorage, PRESSURE_CTRL_LAST_INVOC, 0)
	endif

	if(GetNumberFromWaveNote(TPStorage, AUTOTP_LAST_INVOCATION_KEY) > now)
		SetNumberInWaveNote(TPStorage, AUTOTP_LAST_INVOCATION_KEY, 0)
	endif

	index = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)
	SetNumberInWaveNote(TPStorage, INDEX_ON_TP_START, index)

	NVAR tpCycleID = $GetTestpulseCycleID(device)
	tpCycleID = TP_GetTPCycleID(device)

	WAVE tpAsyncBuffer = GetTPResultAsyncBuffer(device)
	KillOrMoveToTrash(wv = tpAsyncBuffer)
End

/// @brief Perform common actions after the testpulse
Function TP_Teardown(string device, [variable fast])

	if(ParamIsDefault(fast))
		fast = 0
	else
		fast = !!fast
	endif

	NVAR runMode = $GetTestpulseRunMode(device)

	if(fast)
		runMode = TEST_PULSE_NOT_RUNNING
		return NaN
	endif

	if(!(runMode & TEST_PULSE_DURING_RA_MOD))
		DAP_HandleSingleDeviceDependentControls(device)
	endif

	DAP_ToggleTestpulseButton(device, TESTPULSE_BUTTON_TO_START)

	ED_TPDocumentation(device)

	SCOPE_KillScopeWindowIfRequest(device)

	PUB_DAQStateChange(device, TEST_PULSE_MODE, runMode, TEST_PULSE_NOT_RUNNING)
	runMode = TEST_PULSE_NOT_RUNNING

	DAP_AdaptAutoTPColorAndDependent(device)

	TP_TeardownCommon(device)
End

/// @brief Common teardown calls for TP and TP during DAQ
Function TP_TeardownCommon(string device)

	P_LoadPressureButtonState(device)

	NVAR tpCycleID = $GetTestpulseCycleID(device)
	tpCycleID = NaN
End

/// @brief Return the number of devices which have TP running
Function TP_GetNumDevicesWithTPRunning()

	variable numEntries, i, count
	string list, device

	list       = GetListOfLockedDevices()
	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, list)
		count += TP_CheckIfTestpulseIsRunning(device)
	endfor

	return count
End

/// @brief Check if the testpulse is running
///
/// Can not be used to check for foreground TP as during foreground TP/DAQ nothing else runs.
Function TP_CheckIfTestpulseIsRunning(string device)

	NVAR runMode = $GetTestpulseRunMode(device)

	return isFinite(runMode) && runMode != TEST_PULSE_NOT_RUNNING && (IsDeviceActiveWithBGTask(device, TASKNAME_TP) || IsDeviceActiveWithBGTask(device, TASKNAME_TPMD))
End

/// @brief See if the testpulse has run enough times to create valid measurements
///
/// @param device		DA_Ephys panel name
/// @param cycles		number of cycles that test pulse must run
Function TP_TestPulseHasCycled(string device, variable cycles)

	variable index, indexOnTPStart

	WAVE TPStorage = GetTPStorage(device)
	index          = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)
	indexOnTPStart = GetNumberFromWaveNote(TPStorage, INDEX_ON_TP_START)

	return (index - indexOnTPStart) > cycles
End

/// @brief Save the amplifier holding command in the TPStorage wave
Function TP_UpdateHoldCmdInTPStorage(string device, variable headStage)

	variable count, clampMode

	if(!TP_CheckIfTestpulseIsRunning(device))
		return NaN
	endif

	WAVE TPStorage = GetTPStorage(device)

	count = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)
	EnsureLargeEnoughWave(TPStorage, indexShouldExist = count, dimension = ROWS, initialValue = NaN)

	if(!IsFinite(TPStorage[count][headstage][%Headstage])) // HS not active
		return NaN
	endif

	clampMode = TPStorage[count][headstage][%ClampMode]

	if(clampMode == V_CLAMP_MODE)
		TPStorage[count][headstage][%HoldingCmd_VC] = AI_GetHoldingCommand(device, headStage)
	else
		TPStorage[count][headstage][%HoldingCmd_IC] = AI_GetHoldingCommand(device, headStage)
	endif
End

/// @brief Create the testpulse wave with the current settings
Function TP_CreateTestPulseWave(string device, variable dataAcqOrTP)

	variable totalLengthPoints, pulseStartPoints, pulseLengthPoints

	WAVE TestPulse      = GetTestPulse()
	WAVE TPSettingsCalc = GetTPsettingsCalculated(device)

	[totalLengthPoints, pulseStartPoints, pulseLengthPoints] = TP_GetCreationPropertiesInPoints(TPSettingsCalc, dataAcqOrTP)
	TP_CreateTestPulseWaveImpl(TestPulse, totalLengthPoints, pulseStartPoints, pulseLengthPoints)
End

/// @brief device independent test pulse wave creation
Function TP_CreateTestPulseWaveImpl(WAVE tp, variable totalLength, variable pulseStart, variable pulseLength)

	Redimension/N=(totalLength) tp
	FastOp tp = 0

	MultiThread tp[pulseStart, pulseStart + pulseLength] = 1
End

Function [variable totalLengthPoints, variable pulseStartPoints, variable pulseLengthPoints] TP_GetCreationPropertiesInPoints(WAVE TPSettingsCalc, variable dataAcqOrTP)

	totalLengthPoints = (dataAcqOrTP == TEST_PULSE_MODE) ? TPSettingsCalc[%totalLengthPointsTP] : TPSettingsCalc[%totalLengthPointsDAQ]
	pulseStartPoints  = (dataAcqOrTP == TEST_PULSE_MODE) ? TPSettingsCalc[%pulseStartPointsTP] : TPSettingsCalc[%pulseStartPointsDAQ]
	pulseLengthPoints = (dataAcqOrTP == TEST_PULSE_MODE) ? TPSettingsCalc[%pulseLengthPointsTP] : TPSettingsCalc[%pulseLengthPointsDAQ]

	return [totalLengthPoints, pulseStartPoints, pulseLengthPoints]
End

/// @brief Prepares a TP data set data folder to the asynchroneous analysis function TP_TSAnalysis
///
/// @param[in] device title of panel that ran this test pulse
/// @param tpInput holds the parameters send to analysis
/// @returns data folder that can be pushed for execution by the async frame work
Function/DF TP_PrepareAnalysisDF(string device, STRUCT TPAnalysisInput &tpInput)

	string wlName

	wlName = GetWorkLoadName(WORKLOADCLASS_TP, device)

	DFREF threadDF = ASYNC_PrepareDF("TP_TSAnalysis", "TP_ROAnalysis", wlName, inOrder = 0)
	ASYNC_AddParam(threadDF, w = tpInput.data)
	ASYNC_AddParam(threadDF, var = tpInput.clampAmp)
	ASYNC_AddParam(threadDF, var = tpInput.clampMode)
	ASYNC_AddParam(threadDF, var = tpInput.duration)
	ASYNC_AddParam(threadDF, var = tpInput.baselineFrac)
	ASYNC_AddParam(threadDF, var = tpInput.tpLengthPoints)
	ASYNC_AddParam(threadDF, var = tpInput.readTimeStamp)
	ASYNC_AddParam(threadDF, var = tpInput.headstage)
	ASYNC_AddParam(threadDF, str = tpInput.device)
	ASYNC_AddParam(threadDF, var = tpInput.measurementMarker)
	ASYNC_AddParam(threadDF, var = tpInput.activeADCs)

	return threadDF
End

/// @brief Send a TP data set to the asynchroneous analysis function TP_TSAnalysis
///
/// @param[in] device title of panel that ran this test pulse
/// @param tpInput holds the parameters send to analysis
Function TP_SendToAnalysis(string device, STRUCT TPAnalysisInput &tpInput)

	DFREF threadDF = TP_PrepareAnalysisDF(device, tpInput)
	ASYNC_Execute(threadDF)
End

Function TP_UpdateTPSettingsCalculated(string device)

	WAVE TPSettings        = GetTPSettings(device)
	WAVE calculated        = GetTPSettingsCalculated(device)
	WAVE samplingIntervals = GetNewSamplingIntervalsAsFree()
	samplingIntervals[%SI_TP_DAC]  = DAP_GetSampInt(device, TEST_PULSE_MODE, XOP_CHANNEL_TYPE_DAC)
	samplingIntervals[%SI_DAQ_DAC] = DAP_GetSampInt(device, DATA_ACQUISITION_MODE, XOP_CHANNEL_TYPE_DAC)
	samplingIntervals[%SI_TP_ADC]  = DAP_GetSampInt(device, TEST_PULSE_MODE, XOP_CHANNEL_TYPE_ADC)
	samplingIntervals[%SI_DAQ_ADC] = DAP_GetSampInt(device, DATA_ACQUISITION_MODE, XOP_CHANNEL_TYPE_ADC)

	TP_UpdateTPSettingsCalculatedImpl(TPSettings, samplingIntervals, calculated)
End

/// @brief Device and globals independent calculcation of TPSettingsCalculated
Function TP_UpdateTPSettingsCalculatedImpl(WAVE TPSettings, WAVE samplingIntervals, WAVE tpCalculated)

	variable interTPDAC, interDAQDAC, interTPADC, interDAQADC, factorTP, factorDAQ

	tpCalculated = NaN

	interTPDAC  = samplingIntervals[%SI_TP_DAC] * MICRO_TO_MILLI
	interDAQDAC = samplingIntervals[%SI_DAQ_DAC] * MICRO_TO_MILLI
	interTPADC  = samplingIntervals[%SI_TP_ADC] * MICRO_TO_MILLI
	interDAQADC = samplingIntervals[%SI_DAQ_ADC] * MICRO_TO_MILLI
	factorTP    = interTPDAC / interTPADC
	factorDAQ   = interDAQDAC / interDAQADC

	// update the calculated values
	tpCalculated[%baselineFrac] = TPSettings[%baselinePerc][INDEP_HEADSTAGE] * PERCENT_TO_ONE

	tpCalculated[%pulseLengthMS]            = TPSettings[%durationMS][INDEP_HEADSTAGE] // here for completeness
	tpCalculated[%pulseLengthPointsTP]      = trunc(TPSettings[%durationMS][INDEP_HEADSTAGE] / interTPDAC)
	tpCalculated[%pulseLengthPointsDAQ]     = trunc(TPSettings[%durationMS][INDEP_HEADSTAGE] / interDAQDAC)
	tpCalculated[%pulseLengthPointsTP_ADC]  = trunc(tpCalculated[%pulseLengthPointsTP] * factorTP)
	tpCalculated[%pulseLengthPointsDAQ_ADC] = trunc(tpCalculated[%pulseLengthPointsDAQ] * factorDAQ)

	tpCalculated[%totalLengthMS]            = TP_CalculateTestPulseLength(tpCalculated[%pulseLengthMS], tpCalculated[%baselineFrac])
	tpCalculated[%totalLengthPointsTP]      = trunc(TP_CalculateTestPulseLength(tpCalculated[%pulseLengthPointsTP], tpCalculated[%baselineFrac]))
	tpCalculated[%totalLengthPointsDAQ]     = trunc(TP_CalculateTestPulseLength(tpCalculated[%pulseLengthPointsDAQ], tpCalculated[%baselineFrac]))
	tpCalculated[%totalLengthPointsTP_ADC]  = trunc(tpCalculated[%totalLengthPointsTP] * factorTP)
	tpCalculated[%totalLengthPointsDAQ_ADC] = trunc(tpCalculated[%totalLengthPointsDAQ] * factorDAQ)

	tpCalculated[%pulseStartMS]            = tpCalculated[%baselineFrac] * tpCalculated[%totalLengthMS]
	tpCalculated[%pulseStartPointsTP]      = trunc(tpCalculated[%baselineFrac] * tpCalculated[%totalLengthPointsTP])
	tpCalculated[%pulseStartPointsDAQ]     = trunc(tpCalculated[%baselineFrac] * tpCalculated[%totalLengthPointsDAQ])
	tpCalculated[%pulseStartPointsTP_ADC]  = trunc(tpCalculated[%pulseStartPointsTP] * factorTP)
	tpCalculated[%pulseStartPointsDAQ_ADC] = trunc(tpCalculated[%pulseStartPointsDAQ] * factorDAQ)
End

/// @brief Convert from row names of GetTPSettings()/GetTPSettingsCalculated() to GetTPSettingsLBN() column names.
Function/S TP_AutoTPLabelToLabnotebookName(string lbl)

	strswitch(lbl)
		case "autoTPEnable":
			return "TP Auto"
		case "autoAmpMaxCurrent":
			return "TP Auto max current"
		case "autoAmpVoltage":
			return "TP Auto voltage"
		case "autoAmpVoltageRange":
			return "TP Auto voltage range"
		case "autoTPPercentage":
			return "TP Auto percentage"
		case "autoTPInterval":
			return "TP Auto interval"
		case "sendToAllHS":
			return "Send TP settings to all headstages"
		default:
			ASSERT(0, "Invalid value: " + lbl)
	endswitch
End

/// @brief Update the Testpulse labnotebook wave
///
/// DAQ:
/// - TPSettings holds the current GUI values
/// - TPSettingsLabnotebook holds the settings which were active when the sweep started
///
/// TP:
/// - TPSettings holds the current GUI values
/// - TPSettingsLabnotebook is cleared when TP is started and filled from TPSettings when TP is stopped
///   This means we only have the *latest* values for the TP settings which don't restart TP. For entries
///   which do restart TP we always have the current values. See also the DAEPHYS_TP_CONTROLS_XXX constants.
///
/// @see DAP_TPGUISettingToWave() for the special auto TP entry handling.
Function TP_UpdateTPLBNSettings(string device)

	variable i, value
	string lbl, entry

	WAVE TPSettings = GetTPSettings(device)
	WAVE calculated = GetTPSettingsCalculated(device)

	WAVE TPSettingsLBN = GetTPSettingsLabnotebook(device)

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(!statusHS[i])
			continue
		endif

		TPSettingsLBN[0][%$TP_AMPLITUDE_VC_ENTRY_KEY][i] = TPSettings[%amplitudeVC][i]
		TPSettingsLBN[0][%$TP_AMPLITUDE_IC_ENTRY_KEY][i] = TPSettings[%amplitudeIC][i]

		lbl                          = "autoTPEnable"
		entry                        = TP_AutoTPLabelToLabnotebookName(lbl)
		TPSettingsLBN[0][%$entry][i] = TPSettings[%$lbl][i]

		lbl                          = "autoAmpMaxCurrent"
		entry                        = TP_AutoTPLabelToLabnotebookName(lbl)
		TPSettingsLBN[0][%$entry][i] = TPSettings[%$lbl][i]

		lbl                          = "autoAmpVoltage"
		entry                        = TP_AutoTPLabelToLabnotebookName(lbl)
		TPSettingsLBN[0][%$entry][i] = TPSettings[%$lbl][i]

		lbl                          = "autoAmpVoltageRange"
		entry                        = TP_AutoTPLabelToLabnotebookName(lbl)
		TPSettingsLBN[0][%$entry][i] = TPSettings[%$lbl][i]
	endfor

	TPSettingsLBN[0][%$"TP Baseline Fraction"][INDEP_HEADSTAGE]                = calculated[%baselineFrac]
	TPSettingsLBN[0][%$"TP Pulse Duration"][INDEP_HEADSTAGE]                   = calculated[%pulseLengthMS]
	TPSettingsLBN[0][%$"TP buffer size"][INDEP_HEADSTAGE]                      = TPSettings[%bufferSize][INDEP_HEADSTAGE]
	TPSettingsLBN[0][%$"Minimum TP resistance for tolerance"][INDEP_HEADSTAGE] = TPSettings[%resistanceTol][INDEP_HEADSTAGE]
	value                                                                      = ROVar(GetTestpulseCycleID(device))
	TPSettingsLBN[0][%$"TP Cycle ID"][INDEP_HEADSTAGE]                         = value

	lbl                                        = "sendToAllHS"
	entry                                      = TP_AutoTPLabelToLabnotebookName(lbl)
	TPSettingsLBN[0][%$entry][INDEP_HEADSTAGE] = TPSettings[%$lbl][INDEP_HEADSTAGE]

	lbl                                        = "autoTPPercentage"
	entry                                      = TP_AutoTPLabelToLabnotebookName(lbl)
	TPSettingsLBN[0][%$entry][INDEP_HEADSTAGE] = TPSettings[%$lbl][INDEP_HEADSTAGE]

	lbl                                        = "autoTPInterval"
	entry                                      = TP_AutoTPLabelToLabnotebookName(lbl)
	TPSettingsLBN[0][%$entry][INDEP_HEADSTAGE] = TPSettings[%$lbl][INDEP_HEADSTAGE]
End

/// @brief Return the TP cycle ID for the given device
static Function TP_GetTPCycleID(string device)

	DAP_AbortIfUnlocked(device)

	return GetNextRandomNumberForDevice(device)
End

/// @brief Return the length in points of the power spectrum generated via FFT
threadsafe Function TP_GetPowerSpectrumLength(variable tpLength)

	return 2^FindNextPower(tpLength, 2)
End
