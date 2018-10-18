#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_TP
#endif

/// @file MIES_TestPulse.ipf
/// @brief __TP__ Basic Testpulse related functionality

static Constant TP_MAX_VALID_RESISTANCE       = 3000 ///< Units MOhm
static Constant TP_TPSTORAGE_WRITE_INTERVAL   = 0.18
static Constant TP_FIT_POINTS                 = 5
static Constant TP_DIMENSION_SCALING_INTERVAL = 100  ///< Interval in steps of #TP_TPSTORAGE_WRITE_INTERVAL for recalculating the time axis
static Constant TP_EVAL_POINT_OFFSET          = 5

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
///        chunk for the MD case, in points for the real sampling interval type
///
/// @param panelTitle  device
Function TP_GetTestPulseLengthInPoints(panelTitle)
	string panelTitle

	NVAR duration = $GetTestpulseDuration(panelTitle)
	NVAR baselineFrac = $GetTestpulseBaselineFraction(panelTitle)

	return trunc(TP_CalculateTestPulseLength(duration, baselineFrac))
End

/// @brief Store the full test pulse wave for later inspection
static Function TP_StoreFullWave(panelTitle)
	string panelTitle

	variable index, startOfADColumns

	WAVE OscilloscopeData = GetOscilloscopeWave(panelTitle)
	WAVE config = GetITCChanConfigWave(panelTitle)
	startOfADColumns = DimSize(GetDACListFromConfig(config), ROWS)
	WAVE/WAVE storedTP = GetStoredTestPulseWave(panelTitle)

	index = GetNumberFromWaveNote(storedTP, NOTE_INDEX)
	EnsureLargeEnoughWave(storedTP, minimumSize = index)
	Duplicate/FREE/R=[][startOfADColumns,] OscilloscopeData, tmp
	Note/K tmp, "TimeStamp: " + GetISO8601TimeStamp(numFracSecondsDigits = 3)
	storedTP[index++] = tmp
	WaveClear tmp

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

/// @brief Calculates peak and steady state resistance simultaneously on all active headstages. Also returns basline Vm.
// The function TPDelta is called by the TP dataaquistion functions
// It updates a wave in the Test pulse folder for the device
// The wave contains the steady state difference between the baseline and the TP response
Function TP_Delta(panelTitle)
	string 	panelTitle

	variable amplitudeIC, amplitudeVC, referenceTime
	variable BaselineSSStartPoint
	variable BaselineSSEndPoint, TPSSEndPoint, TPSSStartPoint, TPInstantaneousOnsetPoint
	variable columns, i, columnsInWave, OndDBaseline, durationInTime, baselineInTime
	variable lengthTPInPoints, evalRangeInPoints, refPoint, TPInstantaneousEndPoint
	string msg

	referenceTime = DEBUG_TIMER_START()

	WAVE GUIState = GetDA_EphysGuiStateNum(panelTitle)

	if(GUIState[0][%check_Settings_TP_SaveTP])
		TP_StoreFullWave(panelTitle)
	endif

	DFREF dfr = GetDeviceTestPulse(panelTitle)
	
	WAVE OscilloscopeData = GetOscilloscopeWave(panelTitle)
	NVAR/SDFR=dfr amplitudeICGlobal = amplitudeIC
	NVAR/SDFR=dfr amplitudeVCGlobal = amplitudeVC
	NVAR ADChannelToMonitor = $GetADChannelToMonitor(panelTitle)
	WAVE activeHSProp = GetActiveHSProperties(panelTitle)

	NVAR duration     = $GetTestpulseDuration(panelTitle)
	NVAR baselineFrac = $GetTestpulseBaselineFraction(panelTitle)
	lengthTPInPoints  = TP_GetTestPulseLengthInPoints(panelTitle)

	NVAR tpBufferSize = $GetTPBufferSizeGlobal(panelTitle)

	amplitudeIC = abs(amplitudeICGlobal)
	amplitudeVC = abs(amplitudeVCGlobal)

	durationInTime = duration * DimDelta(OscilloscopeData, ROWS)
	baselineInTime = baseLineFrac * lengthTPInPoints * DimDelta(OscilloscopeData, ROWS)

	// Normal durations: 20% of the minimum of duration and baseline
	// Long durations:   5ms
	evalRangeInPoints = min(5, 0.2 * min(durationInTime, baselineInTime)) / DimDelta(OscilloscopeData, ROWS)

	// Use data immediately before elevated onset
	refPoint = baselineFrac * lengthTPInPoints - TP_EVAL_POINT_OFFSET
	BaselineSSStartPoint = refPoint - evalRangeInPoints
	BaselineSSEndPoint   = refPoint
	// Use data before the end of the elevation
	refPoint = (1 - baselineFrac) * lengthTPInPoints - TP_EVAL_POINT_OFFSET
	TPSSStartPoint = refPoint - evalRangeInPoints
	TPSSEndPoint   = refPoint

	// Use 0.25ms at the very beginning of the elevated onset
	evalRangeInPoints = 0.25 / DimDelta(OscilloscopeData, ROWS)
	refPoint = baselineFrac * lengthTPInPoints + TP_EVAL_POINT_OFFSET
	TPInstantaneousOnsetPoint = refPoint
	TPInstantaneousEndPoint   = refPoint + evalRangeInPoints

	sprintf msg, "%g ms/point,TP length %g ms, duration %g, baseline range [%g, %g], elevated range [%g, %g], instanenous range [%g, %g]", DimDelta(OscilloscopeData ,ROWS), IndexToScale(OscilloscopeData, lengthTPInPoints, ROWS), IndexToScale(OscilloscopeData, duration, ROWS), IndexToScale(OscilloscopeData, BaselineSSStartPoint, ROWS), IndexToScale(OscilloscopeData, BaselineSSEndPoint, ROWS), IndexToScale(OscilloscopeData, TPSSStartPoint, ROWS), IndexToScale(OscilloscopeData, TPSSEndPoint, ROWS), IndexToScale(OscilloscopeData, TPInstantaneousOnsetPoint, ROWS), IndexToScale(OscilloscopeData, TPInstantaneousEndPoint, ROWS)
	DEBUGPRINT(msg)

	//	duplicate chunks of TP wave in regions of interest: Baseline, Onset, Steady state
	// 	OscilloscopeData has the AD columns in the order of active AD channels, not the order of active headstages
	Duplicate/FREE/R=[BaselineSSStartPoint, BaselineSSEndPoint][] OscilloscopeData, BaselineSS
	Duplicate/FREE/R=[TPSSStartPoint, TPSSEndPoint][] OscilloscopeData, TPSS
	Duplicate/FREE/R=[TPInstantaneousOnsetPoint, TPInstantaneousEndPoint][] OscilloscopeData, Instantaneous
	//	average the steady state wave
	MatrixOP /free /NTHR = 0 AvgTPSS = sumCols(TPSS)
	avgTPSS /= dimsize(TPSS, ROWS)

	///@todo rework the matrxOp calls with sumCols to also use ^t (transposition), so that intstead of
	/// a `1xm` wave we get a `m` wave (no columns)
	MatrixOp /FREE /NTHR = 0   AvgBaselineSS = sumCols(BaselineSS)
	AvgBaselineSS /= dimsize(BaselineSS, ROWS)
	// duplicate only the AD columns - this would error if a TTL was ever active with the TP, at present, however, they should never be coactive
	Duplicate/O/R=[][ADChannelToMonitor, dimsize(BaselineSS,1) - 1] AvgBaselineSS dfr:BaselineSSAvg/Wave=BaselineSSAvg

	//	calculate the difference between the steady state and the baseline
	Duplicate/FREE AvgTPSS, AvgDeltaSS
	AvgDeltaSS -= AvgBaselineSS
	AvgDeltaSS = abs(AvgDeltaSS)

	//	create wave that will hold instantaneous average
	columnsInWave = dimsize(Instantaneous, 1)
	if(columnsInWave == 0)
		columnsInWave = 1
	endif

	Make/FREE/N=(1, columnsInWave) InstAvg
	
	do
		matrixOp /Free Instantaneous1d = col(Instantaneous, i + ADChannelToMonitor)
		WaveStats/Q/M=1 Instantaneous1d
		OndDBaseline = AvgBaselineSS[0][i + ADChannelToMonitor]
		if((activeHSProp[i][%ClampMode] == V_CLAMP_MODE ? sign(amplitudeVCGlobal) : sign(amplitudeICGlobal)) == 1) // handles positive or negative TPs
			Multithread InstAvg[0][i + ADChannelToMonitor] = mean(Instantaneous1d, pnt2x(Instantaneous1d, V_maxRowLoc - 1), pnt2x(Instantaneous1d, V_maxRowLoc + 1))
		else
			Multithread InstAvg[0][i + ADChannelToMonitor] = mean(Instantaneous1d, pnt2x(Instantaneous1d, V_minRowLoc - 1), pnt2x(Instantaneous1d, V_minRowLoc + 1))
		endif
		i += 1
	while(i < (columnsInWave - ADChannelToMonitor))

	Multithread InstAvg -= AvgBaselineSS
	Multithread InstAvg = abs(InstAvg)

	Duplicate/O/R=[][ADChannelToMonitor, dimsize(TPSS,1) - 1] AvgDeltaSS dfr:SSResistance/Wave=SSResistance
	SetScale/P x IndexToScale(OscilloscopeData, TPSSEndPoint, ROWS),1,"ms", SSResistance // this line determines where the value sit on the bottom axis of the oscilloscope

	Duplicate/O/R=[][(ADChannelToMonitor), (dimsize(TPSS,1) - 1)] InstAvg dfr:InstResistance/Wave=InstResistance
	SetScale/P x IndexToScale(OscilloscopeData, TPInstantaneousOnsetPoint, ROWS),1,"ms", InstResistance

	i = 0
	do
		if(activeHSProp[i][%ClampMode] == I_CLAMP_MODE)
			// R = V / I
			Multithread SSResistance[0][i] = (AvgDeltaSS[0][i + ADChannelToMonitor] / (amplitudeIC)) * 1000
			Multithread InstResistance[0][i] =  (InstAvg[0][i + ADChannelToMonitor] / (amplitudeIC)) * 1000
		else
			Multithread SSResistance[0][i] = ((amplitudeVC) / AvgDeltaSS[0][i + ADChannelToMonitor]) * 1000
			Multithread InstResistance[0][i] = ((amplitudeVC) / InstAvg[0][i + ADChannelToMonitor]) * 1000
		endif
		i += 1
	while(i < (dimsize(AvgDeltaSS, 1) - ADChannelToMonitor))

	/// @todo very crude hack which needs to go
	columns = DimSize(TPSS, 1) - ADChannelToMonitor
	if(!columns)
		columns = 1
	endif

	if(tpBufferSize > 1)
		// the first row will hold the value of the most recent TP,
		// the waves will be averaged and the value will be passed into what was storing the data for the most recent TP
		WAVE/SDFR=dfr TPBaselineBuffer, TPInstBuffer, TPSSBuffer

		TP_CalculateAverage(TPBaselineBuffer, BaselineSSAvg)
		TP_CalculateAverage(TPInstBuffer, InstResistance)
		TP_CalculateAverage(TPSSBuffer, SSResistance)
	endif

	variable numADCs = columns
	TP_RecordTP(panelTitle, BaselineSSAvg, InstResistance, SSResistance, numADCs)
	DQ_ApplyAutoBias(panelTitle, BaselineSSAvg, SSResistance)

	DEBUGPRINT_ELAPSED(referenceTime)
End

static Function TP_CalculateAverage(buffer, dest)
	Wave buffer, dest

	variable i
	variable lastFiniteRow = NaN
	variable numRows = DimSize(buffer, ROWS)

	ASSERT(DimSize(buffer, COLS) == DimSize(dest, COLS) || (DimSize(dest, COLS) == 1 && DimSize(buffer, COLS) == 0) , "Mismatched column sizes")

	MatrixOp/O buffer = rotaterows(buffer, 1)
	buffer[0][] = dest[0][q]

	// only remove NaNs if we actually have one
	// as we append data to the front, the last row is a good point to check
	if(IsFinite(buffer[numRows - 1][0]))
		MatrixOp/O dest = sumcols(buffer)
		dest /= numRows
	else
		// FindValue/BinarySearch does not support searching for NaNs
		// reported to WM on 2nd April 2015
		for(i = 0; i < numRows; i += 1)
			if(!IsFinite(buffer[i][0]))
				ASSERT(i > 0, "No valid entries in buffer")
				lastFiniteRow = i - 1
				break
			endif
		endfor
		ASSERT(IsFinite(lastFiniteRow), "Hugh? Did not find any NaNs...")
		Duplicate/FREE/R=[0, lastFiniteRow][] buffer, filledBuffer
		MatrixOp/O dest = sumcols(filledBuffer)
		dest /= DimSize(filledBuffer, ROWS)
	endif
End

/// @brief Records values from  BaselineSSAvg, InstResistance, SSResistance into TPStorage at defined intervals.
///
/// Used for analysis of TP over time.
/// When the TP is initiated by any method, the TP storageWave should be empty
/// If 200 ms have elapsed, or it is the first TP sweep,
/// data from the input waves is transferred to the storage waves.
static Function TP_RecordTP(panelTitle, BaselineSSAvg, InstResistance, SSResistance, numADCs)
	string 	panelTitle
	wave 	BaselineSSAvg, InstResistance, SSResistance
	variable numADCs

	variable needsUpdate, delta, i
	Wave TPStorage = GetTPStorage(panelTitle)
	WAVE activeHSProp = GetActiveHSProperties(panelTitle)
	Wave GUIState  = GetDA_EphysGuiStateNum(panelTitle)
	variable count = GetNumberFromWaveNote(TPStorage, TP_CYLCE_COUNT_KEY)
	variable now   = ticks * TICKS_TO_SECONDS
	variable lastRescaling = GetNumberFromWaveNote(TPStorage, DIMENSION_SCALING_LAST_INVOC)

	ASSERT(numADCs, "Can not proceed with zero ADCs")

	if(!count)
		Redimension/N=(-1, numADCs, -1, -1) TPStorage
		TPStorage = NaN
		// time of the first sweep
		TPStorage[0][][%TimeInSeconds] = now

		for(i = 0 ; i < NUM_HEADSTAGES; i += 1)
			if(GUIState[i][%$GetSpecialControlLabel(CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)])
				TP_UpdateHoldCmdInTPStorage(panelTitle, i)
			endif
		endfor

		needsUpdate = 1
	elseif((now - TPStorage[count - 1][0][%TimeInSeconds]) > TP_TPSTORAGE_WRITE_INTERVAL)
		needsUpdate = 1
	endif

	if(needsUpdate)
		EnsureLargeEnoughWave(TPStorage, minimumSize=count, dimension=ROWS, initialValue=NaN)

		// use the last value if we don't have a current one
		if(count > 0)
			TPStorage[count][][%HoldingCmd_VC] = !IsFinite(TPStorage[count][q][%HoldingCmd_VC]) \
			                                     ? TPStorage[count - 1][q][%HoldingCmd_VC]      \
			                                     : TPStorage[count][q][%HoldingCmd_VC]

			TPStorage[count][][%HoldingCmd_IC] = !IsFinite(TPStorage[count][q][%HoldingCmd_IC]) \
			                                     ? TPStorage[count - 1][q][%HoldingCmd_IC]      \
			                                     : TPStorage[count][q][%HoldingCmd_IC]
		endif

		TPStorage[count][][%PeakResistance]             = min(InstResistance[0][q][0], TP_MAX_VALID_RESISTANCE)
		TPStorage[count][][%SteadyStateResistance]      = min(SSResistance[0][q][0], TP_MAX_VALID_RESISTANCE)
		TPStorage[count][][%ValidState]                 = TPStorage[count][q][%PeakResistance] < TP_MAX_VALID_RESISTANCE \
		                                                  && TPStorage[count][q][%SteadyStateResistance] < TP_MAX_VALID_RESISTANCE
		TPStorage[count][][%TimeInSeconds]              = now
		TPStorage[count][][%TimeStamp]                  = DateTime
		TPStorage[count][][%TimeStampSinceIgorEpochUTC] = DateTimeInUTC()

		TPStorage[count][][%ADC]       = activeHSProp[q][%ADC]
		TPStorage[count][][%DAC]       = activeHSProp[q][%DAC]
		TPStorage[count][][%Headstage] = activeHSProp[q][%HeadStage]
		TPStorage[count][][%ClampMode] = activeHSProp[q][%ClampMode]

		TPStorage[count][][%Baseline_VC] = activeHSProp[q][%ClampMode] == V_CLAMP_MODE ? baselineSSAvg[0][q] : NaN
		TPStorage[count][][%Baseline_IC] = activeHSProp[q][%ClampMode] != V_CLAMP_MODE ? baselineSSAvg[0][q] : NaN

		TPStorage[count][][%DeltaTimeInSeconds] = count > 0 ? now - TPStorage[0][0][%TimeInSeconds] : 0
		P_PressureControl(panelTitle)
		SetNumberInWaveNote(TPStorage, TP_CYLCE_COUNT_KEY, count + 1)
		TP_AnalyzeTP(panelTitle, TPStorage, count)

		// not all rows have the unit seconds, but with
		// setting up a seconds scale, commands like
		// Display TPStorage[][0][%PeakResistance]
		// show the correct units for the bottom axis
		if((now - lastRescaling) > TP_DIMENSION_SCALING_INTERVAL * TP_TPSTORAGE_WRITE_INTERVAL)

			if(!count) // initial estimate
				delta = TP_TPSTORAGE_WRITE_INTERVAL
			else
				delta = TPStorage[count][0][%DeltaTimeInSeconds] / count
			endif

			DEBUGPRINT("Old delta: ", var=DimDelta(TPStorage, ROWS))
			SetScale/P x, 0.0, delta, "s", TPStorage
			DEBUGPRINT("New delta: ", var=delta)

			SetNumberInWaveNote(TPStorage, DIMENSION_SCALING_LAST_INVOC, now)
		endif
	endif
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

	variable i, startRow, V_FitQuitReason, V_FitOptions, V_FitError, V_AbortCode, numADCs

	startRow = endRow - ceil(TP_FIT_POINTS / TP_TPSTORAGE_WRITE_INTERVAL)

	if(startRow < 0 || startRow >= endRow || !WaveExists(TPStorage) || endRow >= DimSize(TPStorage,ROWS))
		return NaN
	endif

	Make/FREE/D/N=2 coefWave
	V_FitOptions = 4

	numADCs = DimSize(TPStorage, COLS)
	for(i = 0; i < numADCS; i += 1)
		try
			V_FitError  = 0
			V_AbortCode = 0
			CurveFit/Q/N=1/NTHR=1/M=0/W=2 line, kwCWave=coefWave, TPStorage[startRow,endRow][i][%SteadyStateResistance]/X=TPStorage[startRow,endRow][0][3]/AD=0/AR=0; AbortOnRTE
			TPStorage[0][i][%Rss_Slope] = coefWave[1]
		catch
			/// @todo - add code that let's functions which rely on this data know to wait for good data
			TPStorage[0][i][%Rss_Slope] = NaN
			DEBUGPRINT("Fit was not successfull")
			DEBUGPRINT("V_FitError=", var=V_FitError)
			DEBUGPRINT("V_FitQuitReason=", var=V_FitQuitReason)
			DEBUGPRINT("V_AbortCode=", var=V_AbortCode)
			if(V_AbortCode == -4)
				DEBUGPRINT(GetErrMessage(GetRTError(1)))
			endif
		endtry
	endfor
End

/// @brief Resets the TP storage wave
///
/// - Store the TP record if requested by the user
/// - Clear the wave to start with a pristine storage wave
static Function TP_ResetTPStorage(panelTitle)
	string panelTitle

	Wave TPStorage = GetTPStorage(panelTitle)
	variable count = GetNumberFromWaveNote(TPStorage, TP_CYLCE_COUNT_KEY)
	string name

	if(count > 0)
		if(DAG_GetNumericalValue(panelTitle, "check_Settings_TP_SaveTPRecord"))
			dfref dfr = GetDeviceTestPulse(panelTitle)
			name = NameOfWave(TPStorage)
			Duplicate/RMD=[0, count - 1] TPStorage, dfr:$(name + "_" + num2str(ItemsInList(GetListOfObjects(dfr, TP_STORAGE_REGEXP))))
		endif

		SetNumberInWaveNote(TPStorage, TP_CYLCE_COUNT_KEY, 0)
		SetNumberInWaveNote(TPStorage, AUTOBIAS_LAST_INVOCATION_KEY, 0)
		SetNumberInWaveNote(TPStorage, DIMENSION_SCALING_LAST_INVOC, 0)
		EnsureSmallEnoughWave(TPStorage)
		TPStorage = NaN
	endif
End

/// @brief Returns the column of any of the TP results waves (TPBaseline, TPInstResistance, TPSSResistance) associated with a headstage.
///
Function TP_GetTPResultsColOfHS(panelTitle, headStage)
	string panelTitle
	variable headStage
	variable ADC
	DFREF dfr = GetDevicePath(panelTitle)
	Wave/Z/SDFR=dfr wv = ITCChanConfigWave
	if(!WaveExists(Wv))
		return -1
	endif	
	// Get the AD channel associated with the headstage
	ADC = AFH_GetADCFromHeadstage(panelTitle, headstage)
	// Get the first AD rows of the ITCChanConfig wave
	matrixOp/FREE OneDwave = col(Wv, 0) // extract the channel type column
	FindValue/V = 0 OneDwave // ITC_XOP_CHANNEL_TYPE_ADC // find the AD channels
	if(V_Value == -1)
		return -1
	endif
	//ASSERT(V_Value + 1, "No AD Columns found in ITCChanConfigWave")
	variable FirstADColumn = V_Value
	// Get the Column used by the headstage
	matrixOp/FREE OneDwave = col(Wv, 1) // Extract the channel number column
	findValue/S=(FirstADColumn)/V=(ADC) OneDwave // find the specific AD channel
	if(V_Value == -1)
		return -1
	endif
	//ASSERT(V_Value + 1, "AD channel not found in ITCChaneConfigWave")
	return V_value - FirstADColumn
End

/// @brief Stop running background testpulse on all locked devices
Function TP_StopTestPulseOnAllDevices()

	CallFunctionForEachListItem(TP_StopTestPulse, GetListOfLockedDevices())
End

/// @brief Stop any running background test pulses
///
/// Assumes that single device and multi device do not run at the same time.
/// @return One of @ref TestPulseRunModes
Function TP_StopTestPulse(panelTitle)
	string panelTitle

	variable runMode

	NVAR runModeGlobal = $GetTestpulseRunMode(panelTitle)

	// create copy as TP_TearDown() will change runModeGlobal
	runMode = runModeGlobal

	// clear all modifiers from runMode
	runMode = runMode & ~TEST_PULSE_DURING_RA_MOD

	if(runMode == TEST_PULSE_BG_SINGLE_DEVICE)
		TPS_StopTestPulseSingleDevice(panelTitle)
		return runMode
	elseif(runMode == TEST_PULSE_BG_MULTI_DEVICE)
		TPM_StopTestPulseMultiDevice(panelTitle)
		return runMode
	elseif(runMode == TEST_PULSE_FG_SINGLE_DEVICE)
		// can not be stopped
		return TEST_PULSE_FG_SINGLE_DEVICE
	endif

	return TEST_PULSE_NOT_RUNNING
End

/// @brief Restarts a test pulse previously stopped with #TP_StopTestPulse
Function TP_RestartTestPulse(panelTitle, testPulseMode)
	string panelTitle
	variable testPulseMode

	switch(testPulseMode)
		case TEST_PULSE_NOT_RUNNING:
			break // nothing to do
		case TEST_PULSE_BG_SINGLE_DEVICE:
			TPS_StartTestPulseSingleDevice(panelTitle)
			break
		case TEST_PULSE_BG_MULTI_DEVICE:
			TPM_StartTestPulseMultiDevice(panelTitle)
			break
		default:
			DEBUGPRINT("Ignoring unknown value:", var=testPulseMode)
			break
	endswitch
End

/// @brief Prepare device for TestPulse
/// @param panelTitle  device
/// @param runMode     Testpulse running mode, one of @ref TestPulseRunModes
Function TP_Setup(panelTitle, runMode)
	string panelTitle
	variable runMode

	variable multiDevice

	multiDevice = (runMode & TEST_PULSE_BG_MULTI_DEVICE)

	if(!(runMode & TEST_PULSE_DURING_RA_MOD))
		DAP_ToggleTestpulseButton(panelTitle, TESTPULSE_BUTTON_TO_STOP)
		DisableControls(panelTitle, CONTROLS_DISABLE_DURING_DAQ_TP)
	endif

	TP_ResetTPStorage(panelTitle)

	NVAR runModeGlobal = $GetTestpulseRunMode(panelTitle)
	runModeGlobal = runMode

	DC_ConfigureDataForITC(panelTitle, TEST_PULSE_MODE, multiDevice=multiDevice)

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	HW_ITC_PrepareAcq(ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
End

/// @brief Perform common actions after the testpulse
Function TP_Teardown(panelTitle)
	string panelTitle

	NVAR runMode = $GetTestpulseRunMode(panelTitle)

	if(!(runMode & TEST_PULSE_DURING_RA_MOD))
		EnableControls(panelTitle, CONTROLS_DISABLE_DURING_DAQ_TP)
		DAP_SwitchSingleMultiMode(panelTitle)
	endif

	DAP_ToggleTestpulseButton(panelTitle, TESTPULSE_BUTTON_TO_START)

	ED_TPDocumentation(panelTitle)

	SCOPE_KillScopeWindowIfRequest(panelTitle)

	runMode = TEST_PULSE_NOT_RUNNING

	P_LoadPressureButtonState(panelTitle)
End

/// @brief Check if the testpulse is running
///
/// Can not be used to check for foreground TP as during foreground TP/DAQ nothing else runs.
Function TP_CheckIfTestpulseIsRunning(panelTitle)
	string panelTitle

	NVAR runMode = $GetTestpulseRunMode(panelTitle)

	return isFinite(runMode) && runMode != TEST_PULSE_NOT_RUNNING && (IsDeviceActiveWithBGTask(panelTitle, "TestPulse") || IsDeviceActiveWithBGTask(panelTitle, "TestPulseMD"))
End

/// @brief See if the testpulse has run enough times to create valid measurements
///
/// @param panelTitle		DA_Ephys panel name
/// @param cycles		number of cycles that test pulse must run
Function TP_TestPulseHasCycled(panelTitle, cycles)
	string panelTitle
	variable cycles

	Wave TPStorage = GetTPStorage(panelTitle)

	return GetNumberFromWaveNote(TPStorage, TP_CYLCE_COUNT_KEY) > cycles
End

/// @brief Save the amplifier holding command in the TPStorage wave
Function TP_UpdateHoldCmdInTPStorage(panelTitle, headStage)
	string panelTitle
	variable headStage

	variable col, count, clampMode

	if(!TP_CheckIfTestpulseIsRunning(panelTitle))
		return NaN
	endif

	col = TP_GetTPResultsColOfHS(panelTitle, headStage)

	if(col < 0) // headstage is not active
		return NaN
	endif

	clampMode = DAG_GetHeadstageMode(panelTitle, headStage)

	WAVE TPStorage = GetTPStorage(panelTitle)
	count = GetNumberFromWaveNote(TPStorage, TP_CYLCE_COUNT_KEY)

	EnsureLargeEnoughWave(TPStorage, minimumSize=count, dimension=ROWS, initialValue=NaN)

	if(clampMode == V_CLAMP_MODE)
		TPStorage[count][col][%HoldingCmd_VC] = AI_GetHoldingCommand(panelTitle, headStage)
	else
		TPStorage[count][col][%HoldingCmd_IC] = AI_GetHoldingCommand(panelTitle, headStage)
	endif
End
