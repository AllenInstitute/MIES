#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_TestPulse.ipf
/// @brief __TP__ Basic Testpulse related functionality

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
///        chunk for the MD case, in points for the given sampling interval type
///
/// The used sampling interval is the real sampling interval without multiplier, because
/// the testpulse is *never* subject to the sampling interval multiplier.
///
/// @param panelTitle  device
/// @param sampIntType One of @ref SamplingIntervalQueryFlags
Function TP_GetTestPulseLengthInPoints(panelTitle, sampIntType)
	string panelTitle
	variable sampIntType

	variable scale

	switch(sampIntType)
		case MIN_SAMPLING_INTERVAL_TYPE:
			NVAR/SDFR=GetDeviceTestPulse(panelTitle) duration = pulseDuration
			scale = HARDWARE_ITC_MIN_SAMPINT
			break
		case REAL_SAMPLING_INTERVAL_TYPE:
			NVAR duration = $GetTestpulseDuration(panelTitle)
			scale = 1
			break
		default:
			ASSERT(0, "Invalid type of sampIntType")
			break
	endswitch

	NVAR baselineFrac = $GetTestpulseBaselineFraction(panelTitle)

	return trunc(TP_CalculateTestPulseLength(duration, baselineFrac) / scale)
End

/// @brief Start a single device test pulse, either in background
/// or in foreground mode depending on the settings
Function TP_StartTestPulseSingleDevice(panelTitle)
	string panelTitle

	AbortOnValue DAP_CheckSettings(panelTitle, TEST_PULSE_MODE),1

	DAP_StopOngoingDataAcquisition(panelTitle)
	DAP_UpdateITCSampIntDisplay(panelTitle)

	if(GetCheckBoxState(panelTitle, "Check_Settings_BkgTP"))
		TP_Setup(panelTitle, TEST_PULSE_BG_SINGLE_DEVICE)
		ITC_StartBackgroundTestPulse(panelTitle)

		P_LoadPressureButtonState(panelTitle)
	else
		TP_Setup(panelTitle, TEST_PULSE_FG_SINGLE_DEVICE)
		ITC_StartTestPulse(panelTitle)
		TP_Teardown(panelTitle)
	endif
End

/// @brief Start a multi device test pulse, always done in background mode
Function TP_StartTestPulseMultiDevice(panelTitle)
	string panelTitle

	AbortOnValue DAP_CheckSettings(panelTitle, TEST_PULSE_MODE),1

	ITC_StopOngoingDAQMultiDevice(panelTitle)
	DAP_UpdateITCSampIntDisplay(panelTitle)

	ITC_StartTestPulseMultiDevice(panelTitle)

	P_LoadPressureButtonState(panelTitle)
End

/// @brief Calculates peak and steady state resistance simultaneously on all active headstages. Also returns basline Vm.
// The function TPDelta is called by the TP dataaquistion functions
// It updates a wave in the Test pulse folder for the device
// The wave contains the steady state difference between the baseline and the TP response
Function TP_Delta(panelTitle)
	string 	panelTitle

	variable amplitudeIC, amplitudeVC

	DFREF dfr = GetDeviceTestPulse(panelTitle)

	WAVE OscilloscopeData = GetOscilloscopeWave(panelTitle)
	NVAR/SDFR=dfr amplitudeICGlobal = amplitudeIC
	NVAR/SDFR=dfr amplitudeVCGlobal = amplitudeVC
	NVAR/SDFR=dfr baselineFrac
	SVAR/SDFR=dfr clampModeString
	NVAR ADChannelToMonitor = $GetADChannelToMonitor(panelTitle)

	NVAR tpBufferSize = $GetTPBufferSizeGlobal(panelTitle)

	amplitudeIC = abs(amplitudeICGlobal)
	amplitudeVC = abs(amplitudeVCGlobal)

	variable DimOffsetVar = DimOffset(OscilloscopeData, ROWS)
	variable DimDeltaVar = DimDelta(OscilloscopeData, ROWS)
	variable duration = DimSize(OscilloscopeData, ROWS) * DimDeltaVar // total duration of TP in ms
	variable BaselineSteadyStateStartTime = 0.1 * duration
	variable BaselineSteadyStateEndTime = (baselineFrac - 0.01) * duration
	variable TPSSEndTime = (1 - (baselineFrac + 0.01)) * duration
	variable TPInstantaneouseOnsetTime = (baselineFrac + 0.002) * duration
	variable PointsInSteadyStatePeriod = (((BaselineSteadyStateEndTime - DimOffsetVar) / DimDeltaVar) - ((BaselineSteadyStateStartTime - DimOffsetVar) / DimDeltaVar))
	variable BaselineSSStartPoint = ((BaselineSteadyStateStartTime - DimOffsetVar) / DimDeltaVar)
	variable BaslineSSEndPoint = BaselineSSStartPoint + PointsInSteadyStatePeriod
	variable TPSSEndPoint = ((TPSSEndTime - DimOffsetVar) / DimDeltaVar)
	variable TPSSStartPoint = TPSSEndPoint - PointsInSteadyStatePeriod
	variable TPInstantaneousOnsetPoint = ((TPInstantaneouseOnsetTime  - DimOffsetVar) / DimDeltaVar)
	variable columns

	//	duplicate chunks of TP wave in regions of interest: Baseline, Onset, Steady state
	// 	OscilloscopeData has the AD columns in the order of active AD channels, not the order of active headstages
	Duplicate/FREE/R=[BaselineSSStartPoint, BaslineSSEndPoint][] OscilloscopeData, BaselineSS
	Duplicate/FREE/R=[TPSSStartPoint, TPSSEndPoint][] OscilloscopeData, TPSS
	Duplicate/FREE/R=[TPInstantaneousOnsetPoint, (TPInstantaneousOnsetPoint + 50)][] OscilloscopeData, Instantaneous
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
	variable 	i = 0
	variable 	columnsInWave = dimsize(Instantaneous, 1)
	if(columnsInWave == 0)
		columnsInWave = 1
	endif

	Make/FREE/N=(1, columnsInWave) InstAvg
	variable 	OneDInstMax
	variable 	OndDBaseline

	do
		matrixOp /Free Instantaneous1d = col(Instantaneous, i + ADChannelToMonitor)
		WaveStats/Q/M=1 Instantaneous1d
		OneDInstMax = v_max
		OndDBaseline = AvgBaselineSS[0][i + ADChannelToMonitor]

		if(OneDInstMax > OndDBaseline) // handles positive or negative TPs
			Multithread InstAvg[0][i + ADChannelToMonitor] = mean(Instantaneous1d, pnt2x(Instantaneous1d, V_maxRowLoc - 1), pnt2x(Instantaneous1d, V_maxRowLoc + 1))
		else
			Multithread InstAvg[0][i + ADChannelToMonitor] = mean(Instantaneous1d, pnt2x(Instantaneous1d, V_minRowLoc - 1), pnt2x(Instantaneous1d, V_minRowLoc + 1))
		endif
		i += 1
	while(i < (columnsInWave - ADChannelToMonitor))

	Multithread InstAvg -= AvgBaselineSS
	Multithread InstAvg = abs(InstAvg)

	Duplicate/O/R=[][ADChannelToMonitor, dimsize(TPSS,1) - 1] AvgDeltaSS dfr:SSResistance/Wave=SSResistance
	SetScale/P x TPSSEndTime,1,"ms", SSResistance // this line determines where the value sit on the bottom axis of the oscilloscope

	Duplicate/O/R=[][(ADChannelToMonitor), (dimsize(TPSS,1) - 1)] InstAvg dfr:InstResistance/Wave=InstResistance
	SetScale/P x TPInstantaneouseOnsetTime,1,"ms", InstResistance

	i = 0
	do
		if((str2num(stringfromlist(i, ClampModeString, ";"))) == I_CLAMP_MODE)
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
	ITC_ApplyAutoBias(panelTitle, BaselineSSAvg, SSResistance)
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

/// Sampling interval in seconds
static Constant samplingInterval = 0.18

/// Fitting range in seconds
static Constant fittingRange = 5

/// Interval in steps of samplingInterval for recalculating the time axis
static Constant dimensionRescalingInterval = 100

/// Units MOhm
static Constant MAX_VALID_RESISTANCE = 3000

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

	variable needsUpdate, delta, numCols

	Wave TPStorage = GetTPStorage(panelTitle)
	variable count = GetNumberFromWaveNote(TPStorage, TP_CYLCE_COUNT_KEY)
	variable now   = ticks * TICKS_TO_SECONDS
	variable lastRescaling = GetNumberFromWaveNote(TPStorage, DIMENSION_SCALING_LAST_INVOC)

	ASSERT(numADCs, "Can not proceed with zero ADCs")

	if(!count)
		Redimension/N=(-1, numADCs, -1, -1) TPStorage
		TPStorage = NaN
		// time of the first sweep
		TPStorage[0][][%TimeInSeconds] = now
		needsUpdate = 1
		// % is used here to index the wave using dimension labels, see also
		// DisplayHelpTopic "Example: Wave Assignment and Indexing Using Labels"
	elseif((now - TPStorage[count - 1][0][%TimeInSeconds]) > samplingInterval)
		needsUpdate = 1
	endif

	if(needsUpdate)
		EnsureLargeEnoughWave(TPStorage, minimumSize=count, dimension=ROWS, initialValue=NaN)

		TPStorage[count][][%Vm]                         = BaselineSSAvg[0][q][0]
		TPStorage[count][][%PeakResistance]             = min(InstResistance[0][q][0], MAX_VALID_RESISTANCE)
		TPStorage[count][][%SteadyStateResistance]      = min(SSResistance[0][q][0], MAX_VALID_RESISTANCE)
		TPStorage[count][][%TimeInSeconds]              = now
		TPStorage[count][][%TimeStamp]                  = DateTime
		TPStorage[count][][%TimeStampSinceIgorEpochUTC] = DateTimeInUTC()

		// ? : is the ternary/conditional operator, see DisplayHelpTopic "? :"
		TPStorage[count][][%DeltaTimeInSeconds] = count > 0 ? now - TPStorage[0][0][%TimeInSeconds] : 0
		P_PressureControl(panelTitle) // Call pressure functions
		SetNumberInWaveNote(TPStorage, TP_CYLCE_COUNT_KEY, count + 1)
		TP_AnalyzeTP(panelTitle, TPStorage, count, samplingInterval, fittingRange)

		// not all rows have the unit seconds, but with
		// setting up a seconds scale, commands like
		// Display TPStorage[][0][%PeakResistance]
		// show the correct units for the bottom axis
		if((now - lastRescaling) > dimensionRescalingInterval * samplingInterval)

			if(!count) // initial estimate
				delta = samplingInterval
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

/// @brief Determines the slope of the BaselineSSAvg, InstResistance, SSResistance
/// over a user defined window (in seconds)
///
/// @param panelTitle       locked device string
/// @param TPStorage        test pulse storage wave
/// @param endRow           last valid row index in TPStorage
/// @param samplingInterval approximate time duration in seconds between data points
/// @param fittingRange     time duration to use for fitting
static Function TP_AnalyzeTP(panelTitle, TPStorage, endRow, samplingInterval, fittingRange)
	string panelTitle
	Wave/Z TPStorage
	variable endRow, samplingInterval, fittingRange

	variable i, startRow, V_FitQuitReason, V_FitOptions, V_FitError, V_AbortCode, numADCs

	startRow = endRow - ceil(fittingRange / samplingInterval)

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
			CurveFit/Q/N=1/NTHR=1/M=0/W=2 line, kwCWave=coefWave, TPStorage[startRow,endRow][i][%Vm]/X=TPStorage[startRow,endRow][0][3]/AD=0/AR=0; AbortOnRTE
			TPStorage[0][i][%Vm_Slope] = coefWave[1]

			V_FitError  = 0
			V_AbortCode = 0
			CurveFit/Q/N=1/NTHR=1/M=0/W=2 line, kwCWave=coefWave, TPStorage[startRow,endRow][i][%PeakResistance]/X=TPStorage[startRow,endRow][0][3]/AD=0/AR=0; AbortOnRTE
			TPStorage[0][i][%Rpeak_Slope] = coefWave[1]

			V_FitError  = 0
			V_AbortCode = 0
			CurveFit/Q/N=1/NTHR=1/M=0/W=2 line, kwCWave=coefWave, TPStorage[startRow,endRow][i][%SteadyStateResistance]/X=TPStorage[startRow,endRow][0][3]/AD=0/AR=0; AbortOnRTE
			TPStorage[0][i][%Rss_Slope] = coefWave[1]
		catch
			/// @todo - add code that let's functions which rely on this data know to wait for good data
			TPStorage[startRow,endRow][i][%Vm_Slope]    = NaN
			TPStorage[startRow,endRow][i][%Rpeak_Slope] = NaN
			TPStorage[startRow,endRow][i][%Rss_Slope]   = NaN
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
		if(GetCheckBoxState(panelTitle, "check_Settings_TP_SaveTPRecord"))
			dfref dfr = GetDeviceTestPulse(panelTitle)
			Redimension/N=(count, -1, -1, -1) TPStorage
			name = NameOfWave(TPStorage)
			Duplicate/O TPStorage, dfr:$(name + "_" + num2str(ItemsInList(GetListOfWaves(dfr, "^" + name + "_\d+"))))
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
		ITC_StopTestPulseSingleDevice(panelTitle)
		return runMode
	elseif(runMode == TEST_PULSE_BG_MULTI_DEVICE)
		ITC_StopTestPulseMultiDevice(panelTitle)
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
			TP_StartTestPulseSingleDevice(panelTitle)
			break
		case TEST_PULSE_BG_MULTI_DEVICE:
			TP_StartTestPulseMultiDevice(panelTitle)
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

	DFREF deviceDFR = GetDevicePath(panelTitle)

	multiDevice = (runMode & TEST_PULSE_BG_MULTI_DEVICE)

	if(!(runMode & TEST_PULSE_DURING_RA_MOD))
		DAP_ToggleTestpulseButton(panelTitle, TESTPULSE_BUTTON_TO_STOP)
	endif

	TP_ResetTPStorage(panelTitle)

	NVAR runModeGlobal = $GetTestpulseRunMode(panelTitle)
	runModeGlobal = runMode

	DC_ConfigureDataForITC(panelTitle, TEST_PULSE_MODE, multiDevice=multiDevice)

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_ITC_PrepareAcq(ITCDeviceIDGlobal)
End

/// @brief Perform common actions after the testpulse
Function TP_Teardown(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	DAP_ToggleTestpulseButton(panelTitle, TESTPULSE_BUTTON_TO_START)

	ED_TPDocumentation(panelTitle)

	SCOPE_KillScopeWindowIfRequest(panelTitle)

	NVAR runMode= $GetTestpulseRunMode(panelTitle)
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
