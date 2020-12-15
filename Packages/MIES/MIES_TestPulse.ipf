#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_TP
#endif

/// @file MIES_TestPulse.ipf
/// @brief __TP__ Basic Testpulse related functionality

static Constant TP_MAX_VALID_RESISTANCE       = 3000 ///< Units MOhm
static Constant TP_TPSTORAGE_EVAL_INTERVAL    = 0.18
static Constant TP_FIT_POINTS                 = 5
static Constant TP_DIMENSION_SCALING_INTERVAL = 18  ///< [s]
static Constant TP_PRESSURE_INTERVAL          = 0.090  ///< [s]
static Constant TP_EVAL_POINT_OFFSET          = 5

// comment in for debugging
// #define TP_ANALYSIS_DEBUGGING

Function TP_CreateTPAvgBuffer(panelTitle)
	string panelTitle

	variable numADCs

	WAVE DAQConfigWave = GetDAQConfigWave(panelTitle)
	WAVE ADCs = GetADCListFromConfig(DAQConfigWave)
	numADCs = DimSize(ADCs, ROWS)

	NVAR tpBufferSize = $GetTPBufferSizeGlobal(panelTitle)
	WAVE TPBaselineBuffer = GetGetBaselineBuffer(panelTitle)
	WAVE TPInstBuffer = GetInstantaneousBuffer(panelTitle)
	WAVE TPSSBuffer = GetSteadyStateBuffer(panelTitle)

	Redimension/N=(tpBufferSize, NUM_HEADSTAGES) TPBaselineBuffer, TPInstBuffer, TPSSBuffer
	TPBaselineBuffer = NaN
	TPInstBuffer = NaN
	TPSSBuffer = NaN
End

Function TP_ReadTPSettingFromGUI(panelTitle)
	string panelTitle

	NVAR pulseDuration = $GetTPPulseDuration(panelTitle)
	NVAR duration = $GetTestpulseDuration(panelTitle)
	NVAR AmplitudeVC = $GetTPAmplitudeVC(panelTitle)
	NVAR AmplitudeIC = $GetTPAmplitudeIC(panelTitle)
	NVAR baselineFrac = $GetTestpulseBaselineFraction(panelTitle)
	NVAR tpBufSizeGlobal = $GetTPBufferSizeGlobal(panelTitle)

	pulseDuration = DAG_GetNumericalValue(panelTitle, "SetVar_DataAcq_TPDuration")
	// pulseDuration in ms, SampInt in microSec, test pulse mode ignores sample int multiplier for DAQ
	duration = pulseDuration / (DAP_GetSampInt(panelTitle, TEST_PULSE_MODE) / 1000)
	baselineFrac = DAG_GetNumericalValue(panelTitle, "SetVar_DataAcq_TPBaselinePerc") / 100

	// need to deal with units here to ensure that resistance is calculated correctly
	AmplitudeVC = DAG_GetNumericalValue(panelTitle, "SetVar_DataAcq_TPAmplitude")
	AmplitudeIC = DAG_GetNumericalValue(panelTitle, "SetVar_DataAcq_TPAmplitudeIC")

	// tpBufSizeGlobal determines the number of TP cycles to average at end of TP_Delta
	tpBufSizeGlobal = DAG_GetNumericalValue(panelTitle, "setvar_Settings_TPBuffer")
End

/// @brief Return the total length of a single testpulse with baseline
///
/// @param pulseDuration duration of the high portion of the testpulse in points or time
/// @param baselineFrac  fraction, *not* percentage, of the baseline
Function TP_CalculateTestPulseLength(pulseDuration, baselineFrac)
	variable pulseDuration, baselineFrac

	ASSERT(baselineFrac > 0 && baselineFrac < 0.5, "baselineFrac is out of range")
	return pulseDuration / (1 - 2 * baselineFrac)
End

/// @brief Return the total length in points of a single testpulse with baseline, equal to one
///        chunk for the MD case, in points for the real sampling interval type for the given mode.
///
/// See DAP_GetSampInt() for the difference regarding the modes
/// Use GetTestpulseLengthInPoints() for fast access during DAQ/TP.
///
/// @param panelTitle device
/// @param mode       one of @ref DataAcqModes
Function TP_GetTestPulseLengthInPoints(panelTitle, mode)
	string panelTitle
	variable mode

	NVAR duration = $GetTestpulseDuration(panelTitle)
	NVAR baselineFrac = $GetTestpulseBaselineFraction(panelTitle)

	if(mode == TEST_PULSE_MODE)
		return trunc(TP_CalculateTestPulseLength(duration, baselineFrac))
	elseif(mode == DATA_ACQUISITION_MODE)
		return trunc(TP_CalculateTestPulseLength(duration, baselineFrac) / DAP_GetSampInt(panelTitle, DATA_ACQUISITION_MODE) * DAP_GetSampInt(panelTitle, TEST_PULSE_MODE))
	else
		ASSERT(0, "Invalid mode")
	endif
End

/// @brief Stores the given TP wave
///
/// @param panelTitle panel title
///
/// @param TPWave reference to wave holding the TP data in the same format as OscilloscopeData
///
/// @param tpMarker unique number for this set of TPs from all TP channels
///
/// @param hsList list of headstage numbers in the same order as the columns of TPWave
Function TP_StoreTP(panelTitle, TPWave, tpMarker, hsList)
	string panelTitle
	WAVE TPWave
	variable tpMarker
	string hsList

	variable index

	WAVE/WAVE storedTP = GetStoredTestPulseWave(panelTitle)
	index = GetNumberFromWaveNote(storedTP, NOTE_INDEX)
	EnsureLargeEnoughWave(storedTP, minimumSize=index)
	Note/K TPWave
	SetStringInWaveNote(TPWave, "TimeStamp", GetISO8601TimeStamp(numFracSecondsDigits = 3))
	SetNumberInWaveNote(TPWave, "TPMarker", tpMarker, format="%d")
	SetStringInWaveNote(TPWave, "Headstages", hsList)
	storedTP[index++] = TPWave

	SetNumberInWaveNote(storedTP, NOTE_INDEX, index)
End

/// @brief Split the stored testpulse wave reference wave into single waves
///        for easier handling
Function TP_SplitStoredTestPulseWave(panelTitle)
	string panelTitle

	variable numEntries, i

	WAVE/WAVE storedTP = GetStoredTestPulseWave(panelTitle)
	DFREF dfr = GetDeviceTestPulse(panelTitle)

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
/// @param dfr output data folder from ASYNC frame work with results from workloads associated with this registered function
///		  The output parameter in the data folder follow the definition as created in TP_TSAnalysis()
///
/// @param err error code of TP_TSAnalysis() function
///
/// @param errmsg error message of TP_TSAnalysis() function
Function TP_ROAnalysis(dfr, err, errmsg)
	DFREF dfr
	variable err
	string errmsg

	variable i, j, bufSize
	variable posMarker, posAsync
	variable posBaseline, posSSRes, posInstRes

	if(err)
		ASSERT(0, "RTError " + num2str(err) + " in TP_Analysis thread: " + errmsg)
	endif

	WAVE/SDFR=dfr inData=outData
	NVAR/SDFR=dfr now=now
	NVAR/SDFR=dfr hsIndex=hsIndex
	SVAR/SDFR=dfr panelTitle=panelTitle
	NVAR/SDFR=dfr marker=marker
	NVAR/SDFR=dfr activeADCs=activeADCs

	WAVE asyncBuffer = GetTPResultAsyncBuffer(panelTitle)

	bufSize = DimSize(asyncBuffer, ROWS)
	posMarker = FindDimLabel(asyncBuffer, LAYERS, "MARKER")
	posAsync = FindDimLabel(asyncBuffer, COLS, "ASYNCDATA")
	posBaseline = FindDimLabel(asyncBuffer, COLS, "BASELINE")
	posSSRes = FindDimLabel(asyncBuffer, COLS, "STEADYSTATERES")
	posInstRes = FindDimLabel(asyncBuffer, COLS, "INSTANTRES")

	FindValue/RMD=[][posAsync][posMarker, posMarker]/V=(marker)/T=0 asyncBuffer
	i = V_Value >= 0 ? V_Row : bufSize

	if(i == bufSize)
		Redimension/N=(bufSize + 1, -1, -1) asyncBuffer
		asyncBuffer[bufSize][][] = NaN
		asyncBuffer[bufSize][posAsync][%REC_CHANNELS] = 0
		asyncBuffer[bufSize][posAsync][posMarker] = marker
	endif

	asyncBuffer[i][posBaseline][hsIndex] = inData[%BASELINE]
	asyncBuffer[i][posSSRes][hsIndex] = inData[%STEADYSTATERES]
	asyncBuffer[i][posInstRes][hsIndex] = inData[%INSTANTRES]

	asyncBuffer[i][posAsync][%NOW] = now
	asyncBuffer[i][posAsync][%REC_CHANNELS] += 1

	// got one set of results ready
	if(asyncBuffer[i][posAsync][%REC_CHANNELS] == activeADCs)

		WAVE BaselineSSAvg = GetBaselineAverage(panelTitle)
		WAVE SSResistance = GetSSResistanceWave(panelTitle)
		WAVE InstResistance = GetInstResistanceWave(panelTitle)
		MultiThread BaselineSSAvg[] = asyncBuffer[i][posBaseline][p]
		MultiThread SSResistance[] = asyncBuffer[i][posSSRes][p]
		MultiThread InstResistance[] = asyncBuffer[i][posInstRes][p]

		// Remove finished results from buffer
		DeletePoints i, 1, asyncBuffer
		if(!DimSize(asyncBuffer, ROWS))
			KillOrMoveToTrash(wv=asyncBuffer)
		endif

		NVAR tpBufferSize = $GetTPBufferSizeGlobal(panelTitle)
		if(tpBufferSize > 1)
			DFREF dfr = GetDeviceTestPulse(panelTitle)
			WAVE/SDFR=dfr TPBaselineBuffer, TPInstBuffer, TPSSBuffer

			TP_CalculateAverage(TPBaselineBuffer, BaselineSSAvg)
			TP_CalculateAverage(TPInstBuffer, InstResistance)
			TP_CalculateAverage(TPSSBuffer, SSResistance)
		endif

		TP_RecordTP(panelTitle, BaselineSSAvg, InstResistance, SSResistance, now, marker)
		DQ_ApplyAutoBias(panelTitle, BaselineSSAvg, SSResistance)
	endif

End

/// @brief This function analyses a TP data set. It is called by the ASYNC frame work in an own thread.
/// 		  currently six properties are determined.
///
/// @param dfrInp input data folder from the ASYNC framework, parameter input order therein follows the setup in TP_SendToAnalysis()
///
threadsafe Function/DF TP_TSAnalysis(dfrInp)
	DFREF dfrInp

	variable evalRange, refTime, refPoint, tpStartPoint
	variable sampleInt
	variable avgBaselineSS, avgTPSS, avgInst

	DFREF dfrOut = NewFreeDataFolder()

	WAVE data = dfrInp:param0
	NVAR/SDFR=dfrInp clampAmp = param1
	NVAR/SDFR=dfrInp clampMode = param2
	NVAR/SDFR=dfrInp duration = param3
	NVAR/SDFR=dfrInp baselineFrac = param4
	NVAR/SDFR=dfrInp lengthTPInPoints = param5
	NVAR/SDFR=dfrInp now = param6
	NVAR/SDFR=dfrInp hsIndex = param7
	SVAR/SDFR=dfrInp panelTitle = param8
	NVAR/SDFR=dfrInp marker = param9
	NVAR/SDFR=dfrInp activeADCs = param10

#if defined(TP_ANALYSIS_DEBUGGING)
	DEBUGPRINT_TS("Marker: ", var = marker)
	Duplicate data dfrOut:colors
	Duplicate data dfrOut:data
	WAVE colors = dfrOut:colors
	colors = 0
	colors[0, lengthTPInPoints - 1] = 100
#endif

	// Rows:
	// 0: base line level
	// 1: steady state resistance
	// 2: instantaneous resistance
	Make/N=3/D dfrOut:outData/wave=outData
	SetDimLabel ROWS, 0, BASELINE, outData
	SetDimLabel ROWS, 1, STEADYSTATERES, outData
	SetDimLabel ROWS, 2, INSTANTRES, outData

	sampleInt = DimDelta(data, ROWS)
	tpStartPoint = baseLineFrac * lengthTPInPoints
	evalRange = min(5 / sampleInt, min(duration * 0.2, tpStartPoint * 0.2)) * sampleInt

	refTime = (tpStartPoint - TP_EVAL_POINT_OFFSET) * sampleInt
	AvgBaselineSS = mean(data, refTime - evalRange, refTime)

#if defined(TP_ANALYSIS_DEBUGGING)
	// color BASE
	variable refpt = tpStartPoint - TP_EVAL_POINT_OFFSET
	colors[refpt - evalRange / sampleInt, refpt] = 50
	DEBUGPRINT_TS("SampleInt: ", var = sampleInt)
	DEBUGPRINT_TS("tpStartPoint: ", var = tpStartPoint)
	DEBUGPRINT_TS("evalRange (ms): ", var = evalRange)
	DEBUGPRINT_TS("evalRange in points: ", var = evalRange / sampleInt)
	DEBUGPRINT_TS("Base range begin (ms): ", var = refTime - evalRange)
	DEBUGPRINT_TS("Base range eng (ms): ", var = refTime)
	DEBUGPRINT_TS("average BaseLine: ", var = AvgBaselineSS)
#endif

	refTime = (lengthTPInPoints - tpStartPoint - TP_EVAL_POINT_OFFSET) * sampleInt
	avgTPSS = mean(data, refTime - evalRange, refTime)

#if defined(TP_ANALYSIS_DEBUGGING)
	DEBUGPRINT_TS("TPSS range begin (ms): ", var = refTime - evalRange)
	DEBUGPRINT_TS("TPSS range eng (ms): ", var = refTime)
	DEBUGPRINT_TS("average TPSS: ", var = avgTPSS)
	// color SS
	refpt = lengthTPInPoints - tpStartPoint - TP_EVAL_POINT_OFFSET
	colors[refpt - evalRange / sampleInt, refpt] = 50
	// color INST
	refpt = tpStartPoint + TP_EVAL_POINT_OFFSET
	colors[refpt, refpt + 0.25 / sampleInt] = 50
#endif

	refPoint = tpStartPoint + TP_EVAL_POINT_OFFSET
	Duplicate/FREE/R=[refPoint, refPoint + 0.25 / sampleInt] data, inst1d
	WaveStats/Q/M=1 inst1d
	avgInst = (clampAmp < 0) ? mean(inst1d, pnt2x(inst1d, V_minRowLoc - 1), pnt2x(inst1d, V_minRowLoc + 1)) : mean(inst1d, pnt2x(inst1d, V_maxRowLoc - 1), pnt2x(inst1d, V_maxRowLoc + 1))

#if defined(TP_ANALYSIS_DEBUGGING)
	refpt = V_minRowLoc + refPoint
	DEBUGPRINT_TS("refPoint IntSS: ", var = refpt)
	DEBUGPRINT_TS("average InstSS: ", var = avgInst)
	colors[refpt - 1, refpt + 1] = 75
#endif

	if(clampMode == I_CLAMP_MODE)
		outData[1] = (avgTPSS - avgBaselineSS) / clampAmp * 1000
		outData[2] = (avgInst - avgBaselineSS) / clampAmp * 1000
	else
		outData[1] = clampAmp / (avgTPSS - avgBaselineSS) * 1000
		outData[2] = clampAmp / (avgInst - avgBaselineSS) * 1000
	endif
	outData[0] = avgBaselineSS

#if defined(TP_ANALYSIS_DEBUGGING)
	DEBUGPRINT_TS("IntRes: ", var = outData[2])
	DEBUGPRINT_TS("SSRes: ", var = outData[1])
#endif

	// additional data copy
	variable/G dfrOut:now = now
	variable/G dfrOut:hsIndex = hsIndex
	string/G dfrOut:panelTitle = panelTitle
	variable/G dfrOut:marker = marker
	variable/G dfrOut:activeADCs = activeADCs

	return dfrOut
End

/// @brief Calculates running average [box average] of single point data for all active channels
///
/// @param buffer 2D wave storing the values for the average, the rows are the box size, cols index the channels
///
/// @param dest 1D wave where rows index the channels, store the input data per channel
///		  the number of rows of dest must match the number of columns of buffer
///		  On return the content of dest is replaced with the averaged output data
static Function TP_CalculateAverage(buffer, dest)
	Wave buffer, dest

	variable i, j
	variable numRows = DimSize(buffer, ROWS)
	variable numCols = DimSize(buffer, COLS)

	ASSERT(numCols == DimSize(dest, ROWS) , "Number of averaging buffer columns and 1D input wave size must have be the same")

	MatrixOp/O buffer = rotateRows(buffer, 1)
	buffer[0][] = dest[q]

	// find head stage (COL) with actual values, that we just wrote in ROW 0 above
	for(j = 0; j < numCols; j += 1)
		if(IsFinite(buffer[0][j]))
			break
		endif
	endfor
	ASSERT(j != numCols, "Average found no actual new value in any input row.")

	// only remove NaNs if we actually have one
	// as we append data to the front, the last row is a good point to check
	if(IsFinite(buffer[numRows - 1][j]))
		MatrixOp/O dest = sumCols(buffer)
		dest /= numRows
		Redimension/E=1/N=(numCols) dest
	else
		// FindValue/BinarySearch does not support searching for NaNs
		// reported to WM on 2nd April 2015

		// find first row with NaN in an 'active' column
		for(i = 0; i < numRows; i += 1)
			if(!IsFinite(buffer[i][j]))
				break
			endif
		endfor
		Duplicate/FREE/R=[0, i - 1][] buffer, filledBuffer
		MatrixOp/O dest = sumCols(filledBuffer)
		dest /= i
		Redimension/E=1/N=(numCols) dest
	endif
End

/// @brief Records values from  BaselineSSAvg, InstResistance, SSResistance into TPStorage at defined intervals.
///
/// Used for analysis of TP over time.
/// When the TP is initiated by any method, the TP storageWave should be empty
/// If 200 ms have elapsed, or it is the first TP sweep,
/// data from the input waves is transferred to the storage waves.
static Function TP_RecordTP(panelTitle, BaselineSSAvg, InstResistance, SSResistance, now, tpMarker)
	string 	panelTitle
	wave 	BaselineSSAvg, InstResistance, SSResistance
	variable now, tpMarker

	variable delta, i, ret, lastPressureCtrl, timestamp
	WAVE TPStorage = GetTPStorage(panelTitle)
	WAVE hsProp = GetHSProperties(panelTitle)
	variable count = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)
	variable lastRescaling = GetNumberFromWaveNote(TPStorage, DIMENSION_SCALING_LAST_INVOC)

	if(!count)
		// time of the first sweep
		TPStorage[0][][%TimeInSeconds] = now

		WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

		for(i = 0 ; i < NUM_HEADSTAGES; i += 1)

			if(!statusHS[i])
				continue
			endif

			TP_UpdateHoldCmdInTPStorage(panelTitle, i)
		endfor
	endif

	ret = EnsureLargeEnoughWave(TPStorage, minimumSize=count, dimension=ROWS, initialValue=NaN, checkFreeMemory = 1)

	if(ret) // running out of memory
		printf "The amount of free memory is too low to increase TPStorage, please create a new experiment.\r"
		ControlWindowToFront()
		DQ_StopDAQ(panelTitle, startTPAfterDAQ = 0)
		TP_StopTestPulse(panelTitle)
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

	TPStorage[count][][%TimeInSeconds]              = now

	// store the current time in a variable first
	// so that all columns have the same timestamp
	timestamp = DateTime
	TPStorage[count][][%TimeStamp] = timestamp
	timestamp = DateTimeInUTC()
	TPStorage[count][][%TimeStampSinceIgorEpochUTC] = timestamp

	TPStorage[count][][%PeakResistance]        = min(InstResistance[q], TP_MAX_VALID_RESISTANCE)
	TPStorage[count][][%SteadyStateResistance] = min(SSResistance[q], TP_MAX_VALID_RESISTANCE)
	TPStorage[count][][%ValidState]            = TPStorage[count][q][%PeakResistance] < TP_MAX_VALID_RESISTANCE \
															&& TPStorage[count][q][%SteadyStateResistance] < TP_MAX_VALID_RESISTANCE

	TPStorage[count][][%DAC]       = hsProp[q][%DAC]
	TPStorage[count][][%ADC]       = hsProp[q][%ADC]
	TPStorage[count][][%Headstage] = hsProp[q][%Enabled] ? q : NaN
	TPStorage[count][][%ClampMode] = hsProp[q][%ClampMode]

	TPStorage[count][][%Baseline_VC] = hsProp[q][%ClampMode] == V_CLAMP_MODE ? baselineSSAvg[q] : NaN
	TPStorage[count][][%Baseline_IC] = hsProp[q][%ClampMode] == I_CLAMP_MODE ? baselineSSAvg[q] : NaN

	TPStorage[count][][%DeltaTimeInSeconds] = count > 0 ? now - TPStorage[0][0][%TimeInSeconds] : 0
	TPStorage[count][][%TPMarker] = tpMarker

	lastPressureCtrl = GetNumberFromWaveNote(TPStorage, PRESSURE_CTRL_LAST_INVOC)
	if((now - lastPressureCtrl) > TP_PRESSURE_INTERVAL)
		P_PressureControl(panelTitle)
		SetNumberInWaveNote(TPStorage, PRESSURE_CTRL_LAST_INVOC, now, format="%.06f")
	endif

	TP_AnalyzeTP(panelTitle, TPStorage, count)

	// not all rows have the unit seconds, but with
	// setting up a seconds scale, commands like
	// Display TPStorage[][0][%PeakResistance]
	// show the correct units for the bottom axis
	if((now - lastRescaling) > TP_DIMENSION_SCALING_INTERVAL)

		if(!count) // initial estimate
			WAVE DAQDataWave = GetDAQDataWave(panelTitle, TEST_PULSE_MODE)
			delta = ROVAR(GetTestPulseLengthInPoints(panelTitle, TEST_PULSE_MODE)) * DimDelta(DAQDataWave, ROWS) / 1000
		else
			delta = TPStorage[count][0][%DeltaTimeInSeconds] / count
		endif

		DEBUGPRINT("Old delta: ", var=DimDelta(TPStorage, ROWS))
		SetScale/P x, 0.0, delta, "s", TPStorage
		DEBUGPRINT("New delta: ", var=delta)

		SetNumberInWaveNote(TPStorage, DIMENSION_SCALING_LAST_INVOC, now, format="%.06f")
	endif

	SetNumberInWaveNote(TPStorage, NOTE_INDEX, count + 1)
End

/// @brief Threadsafe wrapper for performing CurveFits on the TPStorage wave
threadsafe static Function CurveFitWrapper(TPStorage, startRow, endRow, headstage)
	WAVE TPStorage
	variable startRow, endRow, headstage

	variable V_FitQuitReason, V_FitOptions, V_FitError, V_AbortCode

	// finish early on missing data
	if(!IsFinite(TPStorage[startRow][headstage][%SteadyStateResistance])   \
	   || !IsFinite(TPStorage[endRow][headstage][%SteadyStateResistance]))
		return NaN
	endif

	Make/FREE/D/N=2 coefWave
	V_FitOptions = 4

	try
		ClearRTError()
		V_FitError  = 0
		V_AbortCode = 0
		CurveFit/Q/N=1/NTHR=1/M=0/W=2 line, kwCWave=coefWave, TPStorage[startRow,endRow][headstage][%SteadyStateResistance]/X=TPStorage[startRow,endRow][headstage][%TimeInSeconds]/AD=0/AR=0; AbortOnRTE
		return coefWave[1]
	catch
		ClearRTError()
	endtry

	return NaN
End

/// @brief Determine the slope of the steady state resistance
/// over a user defined window (in seconds)
///
/// @param panelTitle       locked device string
/// @param TPStorage        test pulse storage wave
/// @param endRow           last valid row index in TPStorage
static Function TP_AnalyzeTP(panelTitle, TPStorage, endRow)
	string panelTitle
	Wave/Z TPStorage
	variable endRow

	variable i, startRow, headstage

	startRow = endRow - ceil(TP_FIT_POINTS / TP_TPSTORAGE_EVAL_INTERVAL)

	if(startRow < 0 || startRow >= endRow || !WaveExists(TPStorage) || endRow >= DimSize(TPStorage,ROWS))
		return NaN
	endif

	Make/FREE/N=(NUM_HEADSTAGES) statusHS = 0

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		headstage = TPStorage[endRow][i][%Headstage]

		if(!IsFinite(headstage) || DC_GetChannelTypefromHS(panelTitle, headstage) != DAQ_CHANNEL_TYPE_TP)
			continue
		endif

		statusHS[i] = 1
	endfor

	Multithread TPStorage[0][][%Rss_Slope] = statusHS[q] ? CurveFitWrapper(TPStorage, startRow, endRow, q) : NaN; AbortOnRTE
End

/// @brief Stop running background testpulse on all locked devices
Function TP_StopTestPulseOnAllDevices()

	CallFunctionForEachListItem(TP_StopTestPulse, GetListOfLockedDevices())
End

/// @sa TP_StopTestPulseWrapper
Function TP_StopTestPulseFast(panelTitle)
	string panelTitle

	return TP_StopTestPulseWrapper(panelTitle, fast = 1)
End

/// @sa TP_StopTestPulseWrapper
Function TP_StopTestPulse(panelTitle)
	string panelTitle

	return TP_StopTestPulseWrapper(panelTitle, fast = 0)
End

/// @brief Stop any running background test pulses
///
/// @param panelTitle device
/// @param fast       [optional, defaults to false] Performs only the totally
///                   necessary steps for tear down.
///
/// @return One of @ref TestPulseRunModes
static Function TP_StopTestPulseWrapper(panelTitle, [fast])
	string panelTitle
	variable fast

	variable runMode

	if(ParamIsDefault(fast))
		fast = 0
	else
		fast = !!fast
	endif

	NVAR runModeGlobal = $GetTestpulseRunMode(panelTitle)

	// create copy as TP_TearDown() will change runModeGlobal
	runMode = runModeGlobal

	// clear all modifiers from runMode
	runMode = runMode & ~TEST_PULSE_DURING_RA_MOD

	if(runMode == TEST_PULSE_BG_SINGLE_DEVICE)
		TPS_StopTestPulseSingleDevice(panelTitle, fast = fast)
		return runMode
	elseif(runMode == TEST_PULSE_BG_MULTI_DEVICE)
		TPM_StopTestPulseMultiDevice(panelTitle, fast = fast)
		return runMode
	elseif(runMode == TEST_PULSE_FG_SINGLE_DEVICE)
		// can not be stopped
		return runMode
	endif

	return TEST_PULSE_NOT_RUNNING
End

/// @brief Restarts a test pulse previously stopped with #TP_StopTestPulse
Function TP_RestartTestPulse(panelTitle, testPulseMode, [fast])
	string panelTitle
	variable testPulseMode, fast

	if(ParamIsDefault(fast))
		fast = 0
	else
		fast = !!fast
	endif

	switch(testPulseMode)
		case TEST_PULSE_NOT_RUNNING:
			break // nothing to do
		case TEST_PULSE_BG_SINGLE_DEVICE:
			TPS_StartTestPulseSingleDevice(panelTitle, fast = fast)
			break
		case TEST_PULSE_BG_MULTI_DEVICE:
			TPM_StartTestPulseMultiDevice(panelTitle, fast = fast)
			break
		default:
			DEBUGPRINT("Ignoring unknown value:", var=testPulseMode)
			break
	endswitch
End

/// @brief Prepare device for TestPulse
/// @param panelTitle  device
/// @param runMode     Testpulse running mode, one of @ref TestPulseRunModes
/// @param fast        [optional, defaults to false] Performs only the totally necessary steps for setup
Function TP_Setup(panelTitle, runMode, [fast])
	string panelTitle
	variable runMode
	variable fast

	variable multiDevice

	if(ParamIsDefault(fast))
		fast = 0
	else
		fast = !!fast
	endif

	if(fast)
		NVAR runModeGlobal = $GetTestpulseRunMode(panelTitle)
		runModeGlobal = runMode

		NVAR deviceID = $GetDAQDeviceID(panelTitle)
		HW_PrepareAcq(GetHardwareType(panelTitle), deviceID, TEST_PULSE_MODE, flags=HARDWARE_ABORT_ON_ERROR)
		return NaN
	endif

	multiDevice = (runMode & TEST_PULSE_BG_MULTI_DEVICE)

	TP_SetupCommon(panelTitle)

	if(!(runMode & TEST_PULSE_DURING_RA_MOD))
		DAP_ToggleTestpulseButton(panelTitle, TESTPULSE_BUTTON_TO_STOP)
		DisableControls(panelTitle, CONTROLS_DISABLE_DURING_DAQ_TP)
	endif

	NVAR runModeGlobal = $GetTestpulseRunMode(panelTitle)
	runModeGlobal = runMode

	DC_ConfigureDataForITC(panelTitle, TEST_PULSE_MODE, multiDevice=multiDevice)

	NVAR deviceID = $GetDAQDeviceID(panelTitle)
	HW_PrepareAcq(GetHardwareType(panelTitle), deviceID, TEST_PULSE_MODE, flags=HARDWARE_ABORT_ON_ERROR)
End

/// @brief Common setup calls for TP and TP during DAQ
Function TP_SetupCommon(panelTitle)
	string panelTitle

	variable now, index

	// ticks are relative to OS start time
	// so we can have "future" timestamps from existing experiments
	WAVE TPStorage = GetTPStorage(panelTitle)
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

	index = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)
	SetNumberInWaveNote(TPStorage, INDEX_ON_TP_START, index)

	WAVE tpAsyncBuffer = GetTPResultAsyncBuffer(panelTitle)
	KillOrMoveToTrash(wv=tpAsyncBuffer)
End

/// @brief Perform common actions after the testpulse
Function TP_Teardown(panelTitle, [fast])
	string panelTitle
	variable fast

	if(ParamIsDefault(fast))
		fast = 0
	else
		fast = !!fast
	endif

	NVAR runMode = $GetTestpulseRunMode(panelTitle)

	if(fast)
		runMode = TEST_PULSE_NOT_RUNNING
		return NaN
	endif

	if(!(runMode & TEST_PULSE_DURING_RA_MOD))
		EnableControls(panelTitle, CONTROLS_DISABLE_DURING_DAQ_TP)
		DAP_SwitchSingleMultiMode(panelTitle)
	endif

	DAP_ToggleTestpulseButton(panelTitle, TESTPULSE_BUTTON_TO_START)

	ED_TPDocumentation(panelTitle)

	SCOPE_KillScopeWindowIfRequest(panelTitle)

	runMode = TEST_PULSE_NOT_RUNNING

	TP_TeardownCommon(panelTitle)
End

/// @brief Common teardown calls for TP and TP during DAQ
Function TP_TeardownCommon(panelTitle)
	string panelTitle

	P_LoadPressureButtonState(panelTitle)
End
/// @brief Return the number of devices which have TP running
Function TP_GetNumDevicesWithTPRunning()

	variable numEntries, i, count
	string list, panelTitle

	list = GetListOfLockedDevices()
	numEntries = ItemsInList(list)
	for(i= 0; i < numEntries;i += 1)
		panelTitle = StringFromList(i, list)
		count += TP_CheckIfTestpulseIsRunning(panelTitle)
	endfor

	return count
End

/// @brief Check if the testpulse is running
///
/// Can not be used to check for foreground TP as during foreground TP/DAQ nothing else runs.
Function TP_CheckIfTestpulseIsRunning(panelTitle)
	string panelTitle

	NVAR runMode = $GetTestpulseRunMode(panelTitle)

	return isFinite(runMode) && runMode != TEST_PULSE_NOT_RUNNING && (IsDeviceActiveWithBGTask(panelTitle, TASKNAME_TP) || IsDeviceActiveWithBGTask(panelTitle, TASKNAME_TPMD))
End

/// @brief See if the testpulse has run enough times to create valid measurements
///
/// @param panelTitle		DA_Ephys panel name
/// @param cycles		number of cycles that test pulse must run
Function TP_TestPulseHasCycled(panelTitle, cycles)
	string panelTitle
	variable cycles

	variable index, indexOnTPStart

	WAVE TPStorage = GetTPStorage(panelTitle)
	index          = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)
	indexOnTPStart = GetNumberFromWaveNote(TPStorage, INDEX_ON_TP_START)

	return (index - indexOnTPStart) > cycles
End

/// @brief Save the amplifier holding command in the TPStorage wave
Function TP_UpdateHoldCmdInTPStorage(panelTitle, headStage)
	string panelTitle
	variable headStage

	variable count, clampMode

	if(!TP_CheckIfTestpulseIsRunning(panelTitle))
		return NaN
	endif

	WAVE TPStorage = GetTPStorage(panelTitle)

	count = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)
	EnsureLargeEnoughWave(TPStorage, minimumSize=count, dimension=ROWS, initialValue=NaN)

	if(!IsFinite(TPStorage[count][headstage][%Headstage])) // HS not active
		return NaN
	endif

	clampMode = TPStorage[count][headstage][%ClampMode]

	if(clampMode == V_CLAMP_MODE)
		TPStorage[count][headstage][%HoldingCmd_VC] = AI_GetHoldingCommand(panelTitle, headStage)
	else
		TPStorage[count][headstage][%HoldingCmd_IC] = AI_GetHoldingCommand(panelTitle, headStage)
	endif
End

/// @brief Create the testpulse wave with the current settings
Function TP_CreateTestPulseWave(panelTitle)
	string panelTitle

	variable length

	WAVE TestPulse = GetTestPulse()

	length = ROVAR(GetTestPulseLengthInPoints(panelTitle, TEST_PULSE_MODE))

	Redimension/N=(length) TestPulse
	FastOp TestPulse = 0

	NVAR baselineFrac = $GetTestpulseBaselineFraction(panelTitle)
	TestPulse[baselineFrac * length, (1 - baselineFrac) * length] = 1
End

/// @brief Send a TP data set to the asynchroneous analysis function TP_TSAnalysis
///
/// @param[in] panelTitle title of panel that ran this test pulse
/// @param tpInput holds the parameters send to analysis
Function TP_SendToAnalysis(string panelTitle, STRUCT TPAnalysisInput &tpInput)

	DFREF threadDF = ASYNC_PrepareDF("TP_TSAnalysis", "TP_ROAnalysis", WORKLOADCLASS_TP + panelTitle, inOrder=0)
	ASYNC_AddParam(threadDF, w=tpInput.data)
	ASYNC_AddParam(threadDF, var=tpInput.clampAmp)
	ASYNC_AddParam(threadDF, var=tpInput.clampMode)
	ASYNC_AddParam(threadDF, var=tpInput.duration)
	ASYNC_AddParam(threadDF, var=tpInput.baselineFrac)
	ASYNC_AddParam(threadDF, var=tpInput.tpLengthPoints)
	ASYNC_AddParam(threadDF, var=tpInput.readTimeStamp)
	ASYNC_AddParam(threadDF, var=tpInput.hsIndex)
	ASYNC_AddParam(threadDF, str=tpInput.panelTitle)
	ASYNC_AddParam(threadDF, var=tpInput.measurementMarker)
	ASYNC_AddParam(threadDF, var=tpInput.activeADCs)
	ASYNC_Execute(threadDF)
End
