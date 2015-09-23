#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_TestPulse.ipf
/// @brief __TP__ Basic Testpulse related functionality

/// @brief Selects Test Pulse output wave for all checked DA channels
static Function TP_SelectTestPulseWave(panelTitle)
	string 	panelTitle

	string control
	variable i
	WAVE statusDA = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_DAC)

	do
		if(statusDA[i])
			control = "Wave_DA_0" + num2str(i)
			PopUpMenu $control mode = 2, win = $panelTitle
		endif
		i += 1
	while(i < NUM_DA_TTL_CHANNELS)
End

static Function TP_StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
	Wave 	SelectedDACWaveList
	string 	panelTitle

	string control
	variable i
	WAVE statusDA = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_DAC)

	do
		if(statusDA[i])
			control = "Wave_DA_0" + num2str(i)
			ControlInfo /w = $panelTitle $control
			SelectedDACWaveList[i] = v_value
		endif
		i += 1
	while(i < NUM_DA_TTL_CHANNELS)
end

static Function TP_ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
	Wave 	SelectedDACWaveList
	string 	panelTitle

	string control
	variable i
	WAVE statusDA = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_DAC)

	do
		if(statusDA[i])
			control = "Wave_DA_0" + num2str(i)
			PopupMenu $control mode = SelectedDACWaveList[i], win = $panelTitle
		endif
		i += 1
	while(i < NUM_DA_TTL_CHANNELS)
End

static Function TP_StoreDAScale(SelectedDACScale, panelTitle)
	Wave 	SelectedDACScale
	string 	panelTitle

	string control
	variable i
	WAVE statusDA = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_DAC)

	do
		if(statusDA[i])
			control = "Scale_DA_0" + num2str(i)
			ControlInfo /w = $panelTitle $control
			SelectedDACScale[i] = v_value
		endif
		i += 1
	while(i < NUM_DA_TTL_CHANNELS)
End

static Function TP_SetDAScaleToOne(panelTitle)
	string 	panelTitle

	string control
	variable scalingFactor, i
	WAVE ChannelClampMode = GetChannelClampMode(panelTitle)
	WAVE statusDA = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_DAC)

	do
		if(statusDA[i])
			control = "Scale_DA_0" + num2str(i)
			if(ChannelClampMode[i][0] == V_CLAMP_MODE)
				scalingFactor = 1
			elseif(ChannelClampMode[i][0] == I_CLAMP_MODE)
				// this adjust the scaling in current clamp so that the TP wave
				// (constructed based on v-clamp param) is converted into the I clamp amp
				controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitudeIC
				scalingFactor = v_value
				controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitude
				scalingFactor /= v_value
			else
				ASSERT(0, "no other modes are supported")
			endif

			SetSetVariable(panelTitle, control, scalingFactor)
		endif
		i += 1
	while(i < NUM_DA_TTL_CHANNELS)
End

static Function TP_RestoreDAScale(SelectedDACScale, panelTitle)
	Wave 	SelectedDACScale
	string 	panelTitle

	string control
	variable i
	WAVE statusDA = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_DAC)

	do
		if(statusDA[i])
			control = "Scale_DA_0" + num2str(i)
			SetSetVariable(panelTitle, control, SelectedDACScale[i])
		endif
		i += 1
	while(i < NUM_DA_TTL_CHANNELS)
end

Function TP_UpdateGlobals(panelTitle)
	string panelTitle

	DFREF testPulseDFR = GetDeviceTestPulse(panelTitle)

	variable/G testPulseDFR:pulseDuration
	NVAR/SDFR=testPulseDFR pulseDuration

	variable/G testPulseDFR:duration
	NVAR/SDFR=testPulseDFR duration

	variable/G testPulseDFR:AmplitudeVC
	NVAR/SDFR=testPulseDFR AmplitudeVC

	variable/G testPulseDFR:AmplitudeIC
	NVAR/SDFR=testPulseDFR AmplitudeIC

	variable/G testPulseDFR:baselineFrac
	NVAR/SDFR=testPulseDFR baselineFrac

	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)

	string/G testPulseDFR:ADChannelList  = Convert1DWaveToList(GetADCListFromConfig(ITCChanConfigWave))
	variable/G testPulseDFR:NoOfActiveDA = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_DAC)
	
	// Stores panelTitle GUI control state
	DAP_RecordDA_EphysGuiState(panelTitle)
	
	pulseDuration = GetSetVariable(panelTitle, "SetVar_DataAcq_TPDuration")
	duration = pulseDuration / (DAP_GetITCSampInt(panelTitle, TEST_PULSE_MODE) / 1000)
	baselineFrac = GetSetVariable(panelTitle, "SetVar_DataAcq_TPBaselinePerc") / 100

	// need to deal with units here to ensure that resistance is calculated correctly
	AmplitudeVC = GetSetVariable(panelTitle, "SetVar_DataAcq_TPAmplitude")
	AmplitudeIC = GetSetVariable(panelTitle, "SetVar_DataAcq_TPAmplitudeIC")

	NVAR n = $GetTPBufferSizeGlobal(panelTitle)
	// n determines the number of TP cycles to average
	n = GetSetVariable(panelTitle, "setvar_Settings_TPBuffer")
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

/// @brief Return the total length in points of a single testpulse with baseline, equal to one chunk for the MD case, in points
///
/// The used sampling interval is the real sampling interval without multiplier.
Function TP_GetTestPulseLengthInPoints(panelTitle)
	string panelTitle

	NVAR duration     = $GetTestpulseDuration(panelTitle)
	NVAR baselineFrac = $GetTestpulseBaselineFraction(panelTitle)

	return TP_CalculateTestPulseLength(duration, baselineFrac)
End

static Function TP_UpdateTestPulseWave(panelTitle, TestPulse)
	string panelTitle
	WAVE TestPulse

	variable length
	DFREF testPulseDFR = GetDeviceTestPulse(panelTitle)
	NVAR/SDFR=testPulseDFR amplitudeVC, baselineFrac, pulseDuration

	// this length here is with minimum sampling interval, it will
	// later be downsampled to match the return value of TP_GetTestPulseLengthInPoints
	length = ceil(TP_CalculateTestPulseLength(pulseDuration , baselineFrac) / MINIMUM_SAMPLING_INTERVAL)
	Redimension/N=(length) TestPulse
	FastOp TestPulse = 0
	// TP_SetDAScaleToOne adapts to the different clamp modes
	// so setting it here unconditionally for V_CLAMP is correct
	TestPulse[baselineFrac * length, (1 - baselineFrac) * length] = amplitudeVC
End

/// @brief MD-variant of #TP_UpdateTestPulseWave
static Function TP_UpdateTestPulseWaveMD(panelTitle, TestPulse)
	string panelTitle
	WAVE TestPulse

	variable length, numPulses
	DFREF testPulseDFR = GetDeviceTestPulse(panelTitle)

	Make/FREE singlePulse
	TP_UpdateTestPulseWave(panelTitle, singlePulse)

	length = 2^MINIMUM_ITCDATAWAVE_EXPONENT
	Redimension/N=0 TestPulse

	do
		Concatenate/NP=0 {singlePulse}, TestPulse
		numPulses += 1

		if(DimSize(TestPulse, ROWS) >= length)
			if(numPulses < 3) // keep creating more pulses
				length *= 2
				continue
			endif
			break
		endif
	while(1)
End

/// @brief Start a single device test pulse, either in background
/// or in foreground mode depending on the settings
Function TP_StartTestPulseSingleDevice(panelTitle)
	string panelTitle

	variable headstage

	AbortOnValue DAP_CheckSettings(panelTitle, TEST_PULSE_MODE),1

	DisableControl(panelTitle, "StartTestPulseButton")
	DAP_StopOngoingDataAcquisition(panelTitle)

	NVAR count = $GetCount(panelTitle)
	KillVariables/Z count

	DAP_UpdateITCSampIntDisplay(panelTitle)
	TP_Setup(panelTitle)
	
	if(GetCheckBoxState(panelTitle, "Check_Settings_BkgTP"))
		ITC_StartBackgroundTestPulse(panelTitle)
	else
		ITC_StartTestPulse(panelTitle)
		SCOPE_KillScopeWindowIfRequest(panelTitle)
	endif

	TP_Teardown(panelTitle)

	headStage = GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage")
	P_LoadPressureButtonState(panelTitle, headStage)
End

/// @brief Start a multi device test pulse, always done in background mode
Function TP_StartTestPulseMultiDevice(panelTitle)
	string panelTitle

	variable headstage
	AbortOnValue DAP_CheckSettings(panelTitle, TEST_PULSE_MODE),1

	DAP_StopOngoingDataAcqMD(panelTitle)
	DisableControl(panelTitle, "StartTestPulseButton")

	// @todo Need to modify (killing count global) for yoked devices
	NVAR count = $GetCount(panelTitle)
	KillVariables/Z count

	DAP_UpdateITCSampIntDisplay(panelTitle)

	DAM_StartTestPulseMD(panelTitle)

	// Enable pressure buttons
	headStage = GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage")
	P_LoadPressureButtonState(panelTitle, headStage)
End

/// @brief Calculates peak and steady state resistance simultaneously on all active headstages. Also returns basline Vm.
// The function TPDelta is called by the TP dataaquistion functions
// It updates a wave in the Test pulse folder for the device
// The wave contains the steady state difference between the baseline and the TP response
Function TP_Delta(panelTitle)
	string 	panelTitle

	DFREF dfr = GetDeviceTestPulse(panelTitle)

	WAVE/SDFR=dfr TestPulseITC
	NVAR/SDFR=dfr amplitudeIC
	NVAR/SDFR=dfr amplitudeVC
	NVAR/SDFR=dfr baselineFrac
	NVAR/SDFR=dfr noOfActiveDA
	SVAR/SDFR=dfr clampModeString

	NVAR tpBufferSize = $GetTPBufferSizeGlobal(panelTitle)

	amplitudeIC = abs(amplitudeIC)
	amplitudeVC = abs(amplitudeVC)

	variable DimOffsetVar = DimOffset(TestPulseITC, ROWS)
	variable DimDeltaVar = DimDelta(TestPulseITC, ROWS)
	variable duration = DimSize(TestPulseITC, ROWS) * DimDeltaVar // total duration of TP in ms
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
	// 	TestPulseITC has the AD columns in the order of active AD channels, not the order of active headstages
	Duplicate/FREE/R=[BaselineSSStartPoint, BaslineSSEndPoint][] TestPulseITC, BaselineSS
	Duplicate/FREE/R=[TPSSStartPoint, TPSSEndPoint][] TestPulseITC, TPSS
	Duplicate/FREE/R=[TPInstantaneousOnsetPoint, (TPInstantaneousOnsetPoint + 50)][] TestPulseITC, Instantaneous
	//	average the steady state wave
	MatrixOP /free /NTHR = 0 AvgTPSS = sumCols(TPSS)
	avgTPSS /= dimsize(TPSS, ROWS)

	///@todo rework the matrxOp calls with sumCols to also use ^t (transposition), so that intstead of
	/// a `1xm` wave we get a `m` wave (no columns)
	MatrixOp /FREE /NTHR = 0   AvgBaselineSS = sumCols(BaselineSS)
	AvgBaselineSS /= dimsize(BaselineSS, ROWS)
	// duplicate only the AD columns - this would error if a TTL was ever active with the TP, at present, however, they should never be coactive
	Duplicate/O/R=[][NoOfActiveDA, dimsize(BaselineSS,1) - 1] AvgBaselineSS dfr:BaselineSSAvg/Wave=BaselineSSAvg

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
		matrixOp /Free Instantaneous1d = col(Instantaneous, i + NoOfActiveDA)
		WaveStats/Q/M=1 Instantaneous1d
		OneDInstMax = v_max
		OndDBaseline = AvgBaselineSS[0][i + NoOfActiveDA]

		if(OneDInstMax > OndDBaseline) // handles positive or negative TPs
			Multithread InstAvg[0][i + NoOfActiveDA] = mean(Instantaneous1d, pnt2x(Instantaneous1d, V_maxRowLoc - 1), pnt2x(Instantaneous1d, V_maxRowLoc + 1))
		else
			Multithread InstAvg[0][i + NoOfActiveDA] = mean(Instantaneous1d, pnt2x(Instantaneous1d, V_minRowLoc - 1), pnt2x(Instantaneous1d, V_minRowLoc + 1))
		endif
		i += 1
	while(i < (columnsInWave - NoOfActiveDA))

	Multithread InstAvg -= AvgBaselineSS
	Multithread InstAvg = abs(InstAvg)

	Duplicate/O/R=[][NoOfActiveDA, dimsize(TPSS,1) - 1] AvgDeltaSS dfr:SSResistance/Wave=SSResistance
	SetScale/P x TPSSEndTime,1,"ms", SSResistance // this line determines where the value sit on the bottom axis of the oscilloscope

	Duplicate/O/R=[][(NoOfActiveDA), (dimsize(TPSS,1) - 1)] InstAvg dfr:InstResistance/Wave=InstResistance
	SetScale/P x TPInstantaneouseOnsetTime,1,"ms", InstResistance

	i = 0
	do
		if((str2num(stringfromlist(i, ClampModeString, ";"))) == I_CLAMP_MODE)
			// R = V / I
			Multithread SSResistance[0][i] = (AvgDeltaSS[0][i + NoOfActiveDA] / (amplitudeIC)) * 1000
			Multithread InstResistance[0][i] =  (InstAvg[0][i + NoOfActiveDA] / (amplitudeIC)) * 1000
		else
			Multithread SSResistance[0][i] = ((amplitudeVC) / AvgDeltaSS[0][i + NoOfActiveDA]) * 1000
			Multithread InstResistance[0][i] = ((amplitudeVC) / InstAvg[0][i + NoOfActiveDA]) * 1000
		endif
		i += 1
	while(i < (dimsize(AvgDeltaSS, 1) - NoOfActiveDA))

	/// @todo very crude hack which needs to go
	columns = DimSize(TPSS, 1) - NoOfActiveDA
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
static Constant samplingInterval = 0.2

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

/// @brief Stop any running background test pulses
///
/// Assumes that single device and multi device do not run at the same time.
/// @return One of @ref TestPulseRunModes
Function TP_StopTestPulse(panelTitle)
	string panelTitle

	if(IsBackgroundTaskRunning("TestPulse"))
		ITC_StopTestPulseSingleDevice(panelTitle)
		return TEST_PULSE_BG_SINGLE_DEVICE
	elseif(IsBackgroundTaskRunning("TestPulseMD"))
		ITC_StopTPMD(panelTitle)
		return TEST_PULSE_BG_MULTI_DEVICE
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
			ASSERT(0, "Unhandled case in ITC_RestartTestPulse")
			break
	endswitch
End

/// @brief Prepare device for TestPulse
/// @param panelTitle  device
/// @param multiDevice [optional: defaults to false] Fine tune data handling for single device (false) or multi device (true)
Function TP_Setup(panelTitle, [multiDevice])
	string panelTitle
	variable multiDevice

	DFREF deviceDFR = GetDevicePath(panelTitle)

	DAP_StoreTTLState(panelTitle)
	DAP_TurnOffAllTTLs(panelTitle)

	TP_UpdateGlobals(panelTitle)

	TP_ResetTPStorage(panelTitle)

	// stores panel settings
	Make/O/N=(NUM_DA_TTL_CHANNELS) deviceDFR:SelectedDACWaveList/Wave=SelectedDACWaveList
	TP_StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
	TP_SelectTestPulseWave(panelTitle)

	Make/O/N=(NUM_DA_TTL_CHANNELS) deviceDFR:SelectedDACScale/Wave=SelectedDACScale
	TP_StoreDAScale(SelectedDACScale,panelTitle)
	TP_SetDAScaleToOne(panelTitle)

	WAVE TestPulse = GetTestPulse()
	if(multiDevice)
		TP_UpdateTestPulseWaveMD(panelTitle, TestPulse)
	else
		TP_UpdateTestPulseWave(panelTitle, TestPulse)
	endif

	DC_ConfigureDataForITC(panelTitle, TEST_PULSE_MODE, multiDevice=multiDevice)

	/// @todo use also for single device
	if(multiDevice)
		DAM_ConfigUploadDAC(panelTitle)
	endif
End

/// @brief Perform common actions after the testpulse
Function TP_Teardown(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	WAVE/SDFR=dfr SelectedDACWaveList
	TP_ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
	WAVE/SDFR=dfr SelectedDACScale
	TP_RestoreDAScale(SelectedDACScale, panelTitle)
End
