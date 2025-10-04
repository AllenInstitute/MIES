#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_TP
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

static Function TP_GetStoredTPIndex(string device, variable tpMarker)

	variable numEntries

	WAVE/WAVE storedTP = GetStoredTestPulseWave(device)
	numEntries = GetNumberFromWaveNote(storedTP, NOTE_INDEX)
	if(numEntries == 0)
		return NaN
	endif

	Make/FREE/N=(numEntries) matches
	Multithread matches[0, numEntries - 1] = GetNumberFromWaveNote(storedTP[p], "TPMarker") == tpMarker
	FindValue/V=1 matches
	if(V_row == -1)
		return NaN
	endif

	return V_row
End

static Function/WAVE TP_RecreateDACWave(variable tpLengthPointsDAC, variable pulseStartPointsDAC, variable pulseLengthPointsDAC, variable clampMode, variable clampAmp, variable samplingInterval)

	Make/FREE/D/N=0 tpDAC
	TP_CreateTestPulseWaveImpl(tpDAC, tpLengthPointsDAC, pulseStartPointsDAC, pulseLengthPointsDAC)
	tpDAC *= clampAmp
	SetScale/P x, 0, samplingInterval, "ms", tpDAC
	SetScale d, 0, 0, GetADChannelUnit(clampMode), tpDAC

	return tpDAC
End

static Function/WAVE TP_GetTPMetaData(WAVE tpStorage, variable tpMarker, variable headstage)

	variable i
	variable numEntries = GetNumberFromWaveNote(tpStorage, NOTE_INDEX)
	variable numlayers  = DimSize(tpStorage, LAYERS)
	variable dimMarker  = FindDimLabel(tpStorage, LAYERS, "TPMarker")

	FindValue/RMD=[][headstage][dimMarker]/V=(tpMarker) tpStorage
	ASSERT(V_row >= 0, "Inconsistent TP data")
	Duplicate/FREE/RMD=[V_row][headstage][] tpStorage, tpResult
	Redimension/E=1/N=(numLayers) tpResult
	for(i = 0; i < numLayers; i += 1)
		SetDimLabel ROWS, i, $GetDimLabel(tpStorage, LAYERS, i), tpResult
	endfor

	return tpResult
End

/// @brief Returns data about a stored TestPulse from a given tpMarker
///
/// Returns a wave reference wave with 3 entries:
/// 0 : numeric wave with the acquired AD data of the test pulse (signal) in the format as created by @ref TP_StoreTP
/// 1 : numeric wave with the recreated DA data of the test pulse (command)
/// 2 : Additional information for the test pulse from creation and analysis in the format described for @ref GetTPStorage
///     As the information is for a single TP only, the wave contains a single slice (1 row)
///
/// @param device     device name
/// @param tpMarker   testpulse marker
/// @param headstage  headstage number
/// @param includeDAC flag, when set the DAC wave of the testpulse is recreated
Function/WAVE TP_GetStoredTP(string device, variable tpMarker, variable headstage, variable includeDAC)

	variable tpIndex
	variable i, numlayers

	ASSERT(IsValidHeadstage(headstage), "Invalid headstage number")
	includeDAC = !!includeDAC

	tpIndex = TP_GetStoredTPIndex(device, tpMarker)
	if(IsNaN(tpIndex))
		return $""
	endif

	WAVE/WAVE tpStored = GetStoredTestPulseWave(device)
	WAVE      tpADC    = tpStored[tpIndex]

	WAVE tpStorage = GetTPStorage(device)
	WAVE tpResult  = TP_GetTPMetaData(tpStorage, tpMarker, headstage)

	if(includeDAC)
		WAVE tpDAC = TP_RecreateDACWave(tpResult[%TPLENGTHPOINTSDAC], tpResult[%PULSESTARTPOINTSDAC], tpResult[%PULSELENGTHPOINTSDAC], tpResult[%ClampMode], tpResult[%CLAMPAMP], tpResult[%SAMPLINGINTERVALADC])
	else
		WAVE/Z tpDAC = $""
	endif

	Make/FREE/WAVE tpAll = {tpADC, tpDAC, tpResult}

	return tpAll
End

/// @brief Returns data about stored TestPulses from a given cycle id
///
/// Returns a wave reference wave with 3 entries:
/// 0 : wave ref wave that stores numeric waves with the acquired AD data of the test pulse (signal) in the format as created by @ref TP_StoreTP
///     The number of elements in the wave ref wave equals the number of test pulses in the cycle.
/// 1 : numeric wave with the recreated DA data of the test pulse (command)
///     Note: here only a single wave is recreated because the DA data for all test pulses of that cycle is identical
/// 2 : wave ref wave that stores additional information for the test pulses from creation and analysis in the format described for @ref GetTPStorage
///     The number of elements in the wave ref wave equals the number of test pulses in the cycle and has the same order as the signal waves from index 0.
///     Each element is a single slice (1 row) of tpStorage.
///
/// If no test pulses exist for the given cycle id a null wave is returned.
///
/// @param device     device name
/// @param cycleId    test pulse cycle id
/// @param headstage  headstage number
/// @param includeDAC flag, when set the DAC wave of the testpulse is recreated
Function/WAVE TP_GetStoredTPsFromCycle(string device, variable cycleId, variable headstage, variable includeDAC)

	variable i, numStored, numIndices

	ASSERT(IsValidHeadstage(headstage), "Invalid headstage number")
	includeDAC = !!includeDAC

	WAVE/WAVE tpStored = GetStoredTestPulseWave(device)
	numStored = GetNumberFromWaveNote(tpStored, NOTE_INDEX)
	Make/FREE/D/N=(numStored) matchCycleId
	matchCycleId[] = (cycleId == GetNumberFromWaveNote(tpStored[p], "TPCycleID")) ? p : NaN
	WAVE/Z tpIndices = ZapNaNs(matchCycleId)
	if(!WaveExists(tpIndices))
		return $""
	endif

	numIndices = DimSize(tpIndices, ROWS)
	Make/FREE/WAVE/N=(numIndices) tpsADC, tpsresult
	for(i = 0; i < numIndices; i += 1)
		Duplicate/FREE/RMD=[][headstage] tpStored[tpIndices[i]], tpADCSliced
		Redimension/N=(-1) tpADCSliced
		tpsADC[i] = tpADCSliced
	endfor

	Make/FREE/D/N=(numIndices) tpMarkers
	tpMarkers[] = GetNumberFromWaveNote(tpsADC[p], "TPMarker")

	WAVE tpStorage = GetTPStorage(device)
	tpsResult[] = TP_GetTPMetaData(tpStorage, tpMarkers[p], headstage)

	if(includeDAC)
		Make/FREE/WAVE/N=(numIndices) tpsDAC
		tpsDAC[] = TP_RecreateDACWave(WaveRef(tpsResult[p])[%TPLENGTHPOINTSDAC], WaveRef(tpsResult[p])[%PULSESTARTPOINTSDAC], WaveRef(tpsResult[p])[%PULSELENGTHPOINTSDAC], WaveRef(tpsResult[p])[%ClampMode], WaveRef(tpsResult[p])[%CLAMPAMP], WaveRef(tpsResult[p])[%SAMPLINGINTERVALADC])
	else
		WAVE/Z tpsDAC = $""
	endif

	Make/FREE/WAVE tpAll = {tpsADC, tpsDAC, tpsResult}

	return tpAll
End

/// @brief Return a number of consecutive test pulses ending with the TP
/// identified by tpMarker.
///
/// The wave reference wave will have as many columns as active headstages were used.
Function/WAVE TP_GetConsecutiveTPsUptoMarker(string device, variable tpMarker, variable number)

	variable tpIndex, tpCycleId

	tpIndex = TP_GetStoredTPIndex(device, tpMarker)
	if(IsNaN(tpIndex))
		return $""
	endif

	if(number > (tpIndex + 1))
		// too few TPs available
		return $""
	endif

	Make/FREE/N=(number)/WAVE result

	WAVE/WAVE storedTP = GetStoredTestPulseWave(device)
	result[] = storedTP[tpIndex - number + 1 + p]

	// check that they all belong to the same TP cycle
	Make/FREE/N=(number) matches
	tpCycleId = GetNumberFromWaveNote(result[0], "TPCycleID")
	matches[] = tpCycleId == GetNumberFromWaveNote(result[p], "TPCycleID")
	if(sum(matches) < number)
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

	variable i, j, bufSize, headstage, marker
	variable posMarker, posAsync
	string lbl

	if(ar.rtErr || ar.abortCode)
		ASSERT(!ar.rtErr, "TP analysis thread encountered RTE " + ar.rtErrMsg)
		ASSERT(!ar.abortCode, "TP analysis thread aborted with code: " + GetErrMessage(ar.abortCode))
	endif

	DFREF dfr = ar.dfr

	WAVE/SDFR=dfr inData = tpData
	SVAR/SDFR=dfr device = device
	headstage = inData[%HEADSTAGE]
	marker    = inData[%MARKER]

	WAVE asyncBuffer = GetTPResultAsyncBuffer(device)

	bufSize   = DimSize(asyncBuffer, ROWS)
	posMarker = FindDimLabel(asyncBuffer, LAYERS, "MARKER")
	posAsync  = FindDimLabel(asyncBuffer, COLS, "ASYNCDATA")

	FindValue/RMD=[][posAsync][posMarker, posMarker]/V=(marker)/T=0 asyncBuffer
	i = (V_Value >= 0) ? V_Row : bufSize

	if(i == bufSize)
		Redimension/N=(bufSize + 1, -1, -1) asyncBuffer
		asyncBuffer[bufSize][][]                      = NaN
		asyncBuffer[bufSize][posAsync][%REC_CHANNELS] = 0
		asyncBuffer[bufSize][posAsync][posMarker]     = marker
	endif

	WAVE/T dimLabels = ListToTextWave(TP_ANALYSIS_DATA_LABELS, ";")
	for(lbl : dimLabels)
		asyncBuffer[i][%$lbl][headstage] = inData[%$lbl]
	endfor
	asyncBuffer[i][posAsync][%REC_CHANNELS] += 1

	// got one set of results ready
	if(asyncBuffer[i][posAsync][%REC_CHANNELS] == inData[%NUMBER_OF_TP_CHANNELS])

		WAVE TPResults  = GetTPResults(device)
		WAVE TPSettings = GetTPSettings(device)

		MultiThread TPResults[%BaselineSteadyState][] = asyncBuffer[i][%BASELINE][q]
		MultiThread TPResults[%ResistanceSteadyState][] = asyncBuffer[i][%STEADYSTATERES][q]
		MultiThread TPResults[%ResistanceInst][] = asyncBuffer[i][%INSTANTRES][q]
		MultiThread TPResults[%ElevatedSteadyState][] = asyncBuffer[i][%ELEVATED_SS][q]
		MultiThread TPResults[%ElevatedInst][] = asyncBuffer[i][%ELEVATED_INST][q]
		MultiThread TPResults[%HEADSTAGE][] = asyncBuffer[i][%HEADSTAGE][q]
		MultiThread TPResults[%MARKER][] = asyncBuffer[i][%MARKER][q]
		MultiThread TPResults[%NUMBER_OF_TP_CHANNELS][] = asyncBuffer[i][%NUMBER_OF_TP_CHANNELS][q]
		MultiThread TPResults[%TIMESTAMP][] = asyncBuffer[i][%TIMESTAMP][q]
		MultiThread TPResults[%TIMESTAMPUTC][] = asyncBuffer[i][%TIMESTAMPUTC][q]
		MultiThread TPResults[%CLAMPMODE][] = asyncBuffer[i][%CLAMPMODE][q]
		MultiThread TPResults[%CLAMPAMP][] = asyncBuffer[i][%CLAMPAMP][q]
		MultiThread TPResults[%BASELINEFRAC][] = asyncBuffer[i][%BASELINEFRAC][q]
		MultiThread TPResults[%CYCLEID][] = asyncBuffer[i][%CYCLEID][q]
		MultiThread TPResults[%TPLENGTHPOINTSADC][] = asyncBuffer[i][%TPLENGTHPOINTSADC][q]
		MultiThread TPResults[%PULSELENGTHPOINTSADC][] = asyncBuffer[i][%PULSELENGTHPOINTSADC][q]
		MultiThread TPResults[%PULSESTARTPOINTSADC][] = asyncBuffer[i][%PULSESTARTPOINTSADC][q]
		MultiThread TPResults[%SAMPLINGINTERVALADC][] = asyncBuffer[i][%SAMPLINGINTERVALADC][q]
		MultiThread TPResults[%TPLENGTHPOINTSDAC][] = asyncBuffer[i][%TPLENGTHPOINTSDAC][q]
		MultiThread TPResults[%PULSELENGTHPOINTSDAC][] = asyncBuffer[i][%PULSELENGTHPOINTSDAC][q]
		MultiThread TPResults[%PULSESTARTPOINTSDAC][] = asyncBuffer[i][%PULSESTARTPOINTSDAC][q]
		MultiThread TPResults[%SAMPLINGINTERVALDAC][] = asyncBuffer[i][%SAMPLINGINTERVALDAC][q]

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
		TP_RecordTP(device, TPResults)
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
			FATAL_ERROR("Invalid type")
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

	WAVE/Z/WAVE TPs = TP_GetConsecutiveTPsUptoMarker(device, marker, 2)

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
		case TP_BASELINE_FIT_RESULT_ERROR: // fallthrough
		case TP_BASELINE_FIT_RESULT_TOO_NOISY:
			TPResults[%AutoTPBaseline][headstage]              = 0
			TPResults[%AutoTPBaselineRangeExceeded][headstage] = 0
			return NaN
		default:
			FATAL_ERROR("Unknown return value from TP_AutoFitBaseline")
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

		FATAL_ERROR("CurveFit failed with error: " + msg)
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

/// @brief Disable Auto TP if appropriate
///
/// Disable Auto TP if it passed #TP_AUTO_TP_CONSECUTIVE_PASSES or failed
/// #TP_AUTO_TP_BASELINE_RANGE_EXCEEDED_FAILS times in a row or forceFailedQC
/// is true.
///
/// @param device        Device
/// @param TPStorage     TPStorage wave
/// @param forceFailedQC [optional, defaults to false] Stop Auto TP with a QC failure
/// @param headstage     [optional, defaults to all IC headstages] Headstage [0, 8[ or use one of @ref AllHeadstageModeConstants
/// @param restartTP     [optional, defaults to true] restart the Testpulse
///
/// @return Returns the previously running Test Pulse mode , one of @ref
///         TestPulseRunModes, when it was stopped or NaN if the testpulse was not changed
Function TP_AutoTPDisableIfAppropriate(string device, WAVE TPStorage, [variable forceFailedQC, variable headstage, variable restartTP])

	variable i, needsUpdate, TPState

	if(ParamIsDefault(forceFailedQC))
		forceFailedQC = 0
	else
		forceFailedQC = !!forceFailedQC
	endif

	if(ParamIsDefault(headstage))
		headstage = NaN
	endif

	if(ParamIsDefault(restartTP))
		restartTP = 1
	else
		restartTP = !!restartTP
	endif

	if(!TP_AutoTPActive(device))
		return NaN
	endif

	WAVE TPSettings = GetTPSettings(device)

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	if(headstage >= 0)
		statusHS[] = statusHS[p] && p == headstage
	endif

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

		if(forceFailedQC)
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

		if(restartTP)
			TP_RestartTestPulse(device, TPState)
		endif

		return TPState
	endif

	return NaN
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
	variable jsonId
	variable avgBaselineSS, avgTPSS, instVal, evalOffsetPointsCorrected, instPoint

	DFREF dfrOut = NewFreeDataFolder()

	WAVE     data                 = ASYNC_FetchWave(dfrInp, "data")
	WAVE     ampParamStorageSlice = ASYNC_FetchWave(dfrInp, "ampParamStorageSlice")
	variable clampAmp             = ASYNC_FetchVariable(dfrInp, "clampAmp")
	variable clampMode            = ASYNC_FetchVariable(dfrInp, "clampMode")
	variable pulseLengthPointsADC = ASYNC_FetchVariable(dfrInp, "pulseLengthPointsADC")
	variable baselineFrac         = ASYNC_FetchVariable(dfrInp, "baselineFrac")
	variable tpLengthPointsADC    = ASYNC_FetchVariable(dfrInp, "tpLengthPointsADC")
	variable headstage            = ASYNC_FetchVariable(dfrInp, "headstage")
	string   device               = ASYNC_FetchString(dfrInp, "device")
	variable marker               = ASYNC_FetchVariable(dfrInp, "marker")
	variable activeADCs           = ASYNC_FetchVariable(dfrInp, "numTPChannels")
	variable timeStamp            = ASYNC_FetchVariable(dfrInp, "timeStamp")
	variable timeStampUTC         = ASYNC_FetchVariable(dfrInp, "timeStampUTC")
	variable cycleId              = ASYNC_FetchVariable(dfrInp, "cycleId")
	variable pulseStartPointsADC  = ASYNC_FetchVariable(dfrInp, "pulseStartPointsADC")
	variable samplingIntervalADC  = ASYNC_FetchVariable(dfrInp, "samplingIntervalADC")
	variable tpLengthPointsDAC    = ASYNC_FetchVariable(dfrInp, "tpLengthPointsDAC")
	variable pulseLengthPointsDAC = ASYNC_FetchVariable(dfrInp, "pulseLengthPointsDAC")
	variable pulseStartPointsDAC  = ASYNC_FetchVariable(dfrInp, "pulseStartPointsDAC")
	variable samplingIntervalDAC  = ASYNC_FetchVariable(dfrInp, "samplingIntervalDAC")
	variable sendTPMessage        = ASYNC_FetchVariable(dfrInp, "sendTPMessage")

#if defined(TP_ANALYSIS_DEBUGGING)
	DEBUGPRINT_TS("Marker: ", var = marker)
	Duplicate data, dfrOut:colors
	Duplicate data, dfrOut:data
	WAVE colors = dfrOut:colors
	colors                           = 0
	colors[0, tpLengthPointsADC - 1] = 100
#endif

	WAVE tpData = GetTPAnalysisDataWave()
	MoveWave tpData, dfrOut

	tpStartPoint = baseLineFrac * tpLengthPointsADC
	evalRange    = min(5 / samplingIntervalADC, min(pulseLengthPointsADC * 0.2, tpStartPoint * 0.2)) * samplingIntervalADC

	// correct TP_EVAL_POINT_OFFSET for the non-standard sampling interval
	evalOffsetPointsCorrected = (TP_EVAL_POINT_OFFSET / samplingIntervalADC) * HARDWARE_ITC_MIN_SAMPINT

	refTime       = (tpStartPoint - evalOffsetPointsCorrected) * samplingIntervalADC
	AvgBaselineSS = mean(data, refTime - evalRange, refTime)

#if defined(TP_ANALYSIS_DEBUGGING)
	// color BASE
	variable refpt = refTime / samplingIntervalADC
	colors[refpt - evalRange / samplingIntervalADC, refpt] = 50
	DEBUGPRINT_TS("SampleInt: ", var = samplingIntervalADC)
	DEBUGPRINT_TS("tpStartPoint: ", var = tpStartPoint)
	DEBUGPRINT_TS("evalRange (ms): ", var = evalRange)
	DEBUGPRINT_TS("evalRange in points: ", var = evalRange / samplingIntervalADC)
	DEBUGPRINT_TS("Base range begin (ms): ", var = refTime - evalRange)
	DEBUGPRINT_TS("Base range eng (ms): ", var = refTime)
	DEBUGPRINT_TS("average BaseLine: ", var = AvgBaselineSS)
#endif

	refTime = (tpLengthPointsADC - tpStartPoint - evalOffsetPointsCorrected) * samplingIntervalADC
	avgTPSS = mean(data, refTime - evalRange, refTime)

#if defined(TP_ANALYSIS_DEBUGGING)
	DEBUGPRINT_TS("steady state range begin (ms): ", var = refTime - evalRange)
	DEBUGPRINT_TS("steady state range eng (ms): ", var = refTime)
	DEBUGPRINT_TS("steady state average: ", var = avgTPSS)
	// color steady state
	refpt                                                  = tpLengthPointsADC - tpStartPoint - evalOffsetPointsCorrected
	colors[refpt - evalRange / samplingIntervalADC, refpt] = 50
	// color instantaneous
	refpt                                             = tpStartPoint + evalOffsetPointsCorrected
	colors[refpt, refpt + 0.25 / samplingIntervalADC] = 50
#endif

	refPoint = tpStartPoint + evalOffsetPointsCorrected
	// as data is always too small for threaded execution, the values of V_minRowLoc/V_maxRowLoc are reproducible
	WaveStats/P/Q/M=1/R=[refPoint, refPoint + 0.25 / samplingIntervalADC] data
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
		tpData[%STEADYSTATERES] = (avgTPSS - avgBaselineSS) * MILLI_TO_ONE / (clampAmp * PICO_TO_ONE) * ONE_TO_MEGA
		tpData[%INSTANTRES]     = (instVal - avgBaselineSS) * MILLI_TO_ONE / (clampAmp * PICO_TO_ONE) * ONE_TO_MEGA
	else
		tpData[%STEADYSTATERES] = (clampAmp * MILLI_TO_ONE) / ((avgTPSS - avgBaselineSS) * PICO_TO_ONE) * ONE_TO_MEGA
		tpData[%INSTANTRES]     = (clampAmp * MILLI_TO_ONE) / ((instVal - avgBaselineSS) * PICO_TO_ONE) * ONE_TO_MEGA
	endif
	tpData[%BASELINE]      = avgBaselineSS
	tpData[%ELEVATED_SS]   = avgTPSS
	tpData[%ELEVATED_INST] = instVal

#if defined(TP_ANALYSIS_DEBUGGING)
	DEBUGPRINT_TS("instantaneous resistance: ", var = tpData[%INSTANTRES])
	DEBUGPRINT_TS("steady state resistance: ", var = tpData[%STEADYSTATERES])
#endif

	// additional data copy
	string/G dfrOut:device = device
	tpData[%HEADSTAGE]             = headstage
	tpData[%MARKER]                = marker
	tpData[%NUMBER_OF_TP_CHANNELS] = activeADCs
	tpData[%TIMESTAMP]             = timestamp
	tpData[%TIMESTAMPUTC]          = timestampUTC
	tpData[%CLAMPMODE]             = clampMode
	tpData[%CLAMPAMP]              = clampAmp
	tpData[%BASELINEFRAC]          = baselineFrac
	tpData[%CYCLEID]               = cycleId
	tpData[%TPLENGTHPOINTSADC]     = tpLengthPointsADC
	tpData[%PULSELENGTHPOINTSADC]  = pulseLengthPointsADC
	tpData[%PULSESTARTPOINTSADC]   = pulseStartPointsADC
	tpData[%SAMPLINGINTERVALADC]   = samplingIntervalADC
	tpData[%TPLENGTHPOINTSDAC]     = tpLengthPointsDAC
	tpData[%PULSELENGTHPOINTSDAC]  = pulseLengthPointsDAC
	tpData[%PULSESTARTPOINTSDAC]   = pulseStartPointsDAC
	tpData[%SAMPLINGINTERVALDAC]   = samplingIntervalDAC

	if(sendTPMessage)
		Make/FREE/WAVE additionalData = {data}
		PUB_TPResult(device, tpData, ampParamStorageSlice, additionalData)
	endif

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
static Function TP_RecordTP(string device, WAVE TPResults)

	variable delta, i, ret, lastPressureCtrl, now
	variable refTime = NaN

	WAVE     TPStorage     = GetTPStorage(device)
	WAVE     hsProp        = GetHSProperties(device)
	variable count         = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)
	variable lastRescaling = GetNumberFromWaveNote(TPStorage, DIMENSION_SCALING_LAST_INVOC)

	if(!count)
		WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

		for(i = 0; i < NUM_HEADSTAGES; i += 1)

			if(!statusHS[i])
				continue
			endif

			TP_UpdateHoldCmdInTPStorage(device, i)

			if(IsNaN(refTime))
				refTime = TPResults[%TIMESTAMP][i]
				SetNumberInWaveNote(TPStorage, REFERENCE_START_TIME, refTime)
			endif
		endfor
	else
		refTime = GetNumberFromWaveNote(TPStorage, REFERENCE_START_TIME)
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

	TPStorage[count][][%TimeStamp]                  = TPResults[%TIMESTAMP][q]
	TPStorage[count][][%TimeStampSinceIgorEpochUTC] = TPResults[%TIMESTAMPUTC][q]

	TPStorage[count][][%PeakResistance]        = min(TPResults[%ResistanceInst][q], TP_MAX_VALID_RESISTANCE)
	TPStorage[count][][%SteadyStateResistance] = min(TPResults[%ResistanceSteadyState][q], TP_MAX_VALID_RESISTANCE)
	TPStorage[count][][%ValidState]            = TPStorage[count][q][%PeakResistance] < TP_MAX_VALID_RESISTANCE         \
	                                             && TPStorage[count][q][%SteadyStateResistance] < TP_MAX_VALID_RESISTANCE

	TPStorage[count][][%DAC]       = hsProp[q][%DAC]
	TPStorage[count][][%ADC]       = hsProp[q][%ADC]
	TPStorage[count][][%Headstage] = hsProp[q][%Enabled] ? q : NaN
	TPStorage[count][][%ClampMode] = hsProp[q][%ClampMode]
	TPStorage[count][][%CLAMPAMP]  = TPResults[%CLAMPAMP][q]

	TPStorage[count][][%Baseline_VC] = (hsProp[q][%ClampMode] == V_CLAMP_MODE) ? TPResults[%BaselineSteadyState][q] : NaN
	TPStorage[count][][%Baseline_IC] = (hsProp[q][%ClampMode] == I_CLAMP_MODE) ? TPResults[%BaselineSteadyState][q] : NaN

	TPStorage[count][][%DeltaTimeInSeconds] = TPResults[%TIMESTAMP][q] - refTime
	TPStorage[count][][%TPMarker]           = TPResults[%MARKER][q]

	TPStorage[count][][%TPCycleID] = TPResults[%CYCLEID][q]

	TPStorage[count][][%AutoTPAmplitude]             = TPResults[%AutoTPAmplitude][q]
	TPStorage[count][][%AutoTPBaseline]              = TPResults[%AutoTPBaseline][q]
	TPStorage[count][][%AutoTPBaselineRangeExceeded] = TPResults[%AutoTPBaselineRangeExceeded][q]
	TPStorage[count][][%AutoTPBaselineFitResult]     = TPResults[%AutoTPBaselineFitResult][q]
	TPStorage[count][][%AutoTPDeltaV]                = TPResults[%AutoTPDeltaV][q]
	TPStorage[count][][%TPLENGTHPOINTSADC]           = TPResults[%TPLENGTHPOINTSADC][q]
	TPStorage[count][][%PULSELENGTHPOINTSADC]        = TPResults[%PULSELENGTHPOINTSADC][q]
	TPStorage[count][][%PULSESTARTPOINTSADC]         = TPResults[%PULSESTARTPOINTSADC][q]
	TPStorage[count][][%SAMPLINGINTERVALADC]         = TPResults[%SAMPLINGINTERVALADC][q]
	TPStorage[count][][%TPLENGTHPOINTSDAC]           = TPResults[%TPLENGTHPOINTSDAC][q]
	TPStorage[count][][%PULSELENGTHPOINTSDAC]        = TPResults[%PULSELENGTHPOINTSDAC][q]
	TPStorage[count][][%PULSESTARTPOINTSDAC]         = TPResults[%PULSESTARTPOINTSDAC][q]
	TPStorage[count][][%SAMPLINGINTERVALDAC]         = TPResults[%SAMPLINGINTERVALDAC][q]

	WAVE TPSettings = GetTPSettings(device)
	TPStorage[count][][%AutoTPCycleID] = hsProp[q][%Enabled] ? TPSettings[%autoTPCycleID][q] : NaN

	lastPressureCtrl = GetNumberFromWaveNote(TPStorage, PRESSURE_CTRL_LAST_INVOC)
	now              = DateTime
	if((now - lastPressureCtrl) > TP_PRESSURE_INTERVAL)
		P_PressureControl(device)
		SetNumberInWaveNote(TPStorage, PRESSURE_CTRL_LAST_INVOC, now, format = "%.06f")
	endif

	TP_AnalyzeTP(device, TPStorage, count)

	WAVE TPStorageDat = ExtractLogbookSliceTimeStamp(TPStorage)
	EnsureLargeEnoughWave(TPStorageDat, indexShouldExist = count, dimension = ROWS, initialValue = NaN)
	TPStorageDat[count][] = TPStorage[count][q][%TimeStampSinceIgorEpochUTC]

	SetNumberInWaveNote(TPStorage, NOTE_INDEX, count + 1)

	TP_AutoTPDisableIfAppropriate(device, TPStorage)
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
		CurveFit/Q/N=1/NTHR=1/M=0/W=2 line, kwCWave=coefWave, TPStorage[startRow, endRow][headstage][%SteadyStateResistance]/X=TPStorage[startRow, endRow][headstage][%TimeStamp]/AD=0/AR=0; AbortOnRTE
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

	variable ADCConfig

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
		ADCConfig = ROVar(GetDeviceADCConfig(device))
		HW_PrepareAcq(GetHardwareType(device), deviceID, TEST_PULSE_MODE, flags = HARDWARE_ABORT_ON_ERROR, ADCConfig = ADCConfig)
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
	ADCConfig = ROVar(GetDeviceADCConfig(device))
	HW_PrepareAcq(GetHardwareType(device), deviceID, TEST_PULSE_MODE, flags = HARDWARE_ABORT_ON_ERROR, ADCConfig = ADCConfig)
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

	WAVE ampStorage = GetAmplifierParamStorageWave(device)
	Duplicate/FREE/RMD=[][][tpInput.headstage] ampStorage, ampParamStorageSlice
	ASSERT(DimSize(ampParamStorageSlice, COLS) == 1, "Expected only one column")
	ASSERT(DimSize(ampParamStorageSlice, LAYERS) == 1, "Expected only one layer")
	Redimension/N=(-1, 0, 0)/E=1 ampParamStorageSlice

	DFREF threadDF = ASYNC_PrepareDF("TP_TSAnalysis", "TP_ROAnalysis", wlName, inOrder = 0)
	ASYNC_AddParam(threadDF, w = tpInput.data, name = "data")
	ASYNC_AddParam(threadDF, w = ampParamStorageSlice, name = "ampParamStorageSlice")
	ASYNC_AddParam(threadDF, var = tpInput.clampAmp, name = "clampAmp")
	ASYNC_AddParam(threadDF, var = tpInput.clampMode, name = "clampMode")
	ASYNC_AddParam(threadDF, var = tpInput.pulseLengthPointsADC, name = "pulseLengthPointsADC")
	ASYNC_AddParam(threadDF, var = tpInput.baselineFrac, name = "baselineFrac")
	ASYNC_AddParam(threadDF, var = tpInput.tpLengthPointsADC, name = "tpLengthPointsADC")
	ASYNC_AddParam(threadDF, var = tpInput.headstage, name = "headstage")
	ASYNC_AddParam(threadDF, str = tpInput.device, name = "device")
	ASYNC_AddParam(threadDF, var = tpInput.measurementMarker, name = "marker")
	ASYNC_AddParam(threadDF, var = tpInput.activeADCs, name = "numTPChannels")
	ASYNC_AddParam(threadDF, var = tpInput.timeStamp, name = "timeStamp")
	ASYNC_AddParam(threadDF, var = tpInput.timeStampUTC, name = "timeStampUTC")
	ASYNC_AddParam(threadDF, var = tpInput.cycleId, name = "cycleId")
	ASYNC_AddParam(threadDF, var = tpInput.pulseStartPointsADC, name = "pulseStartPointsADC")
	ASYNC_AddParam(threadDF, var = tpInput.samplingIntervalADC, name = "samplingIntervalADC")
	ASYNC_AddParam(threadDF, var = tpInput.tpLengthPointsDAC, name = "tpLengthPointsDAC")
	ASYNC_AddParam(threadDF, var = tpInput.pulseLengthPointsDAC, name = "pulseLengthPointsDAC")
	ASYNC_AddParam(threadDF, var = tpInput.pulseStartPointsDAC, name = "pulseStartPointsDAC")
	ASYNC_AddParam(threadDF, var = tpInput.samplingIntervalDAC, name = "samplingIntervalDAC")
	ASYNC_AddParam(threadDF, var = tpInput.sendTPMessage, name = "sendTPMessage")

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
			FATAL_ERROR("Invalid value: " + lbl)
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
