#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_ITC
#endif

/// @file MIES_DataAcqITC.ipf
/// @brief __ITC__ Data acquisition handling

Function ITC_DataAcq(panelTitle)
	string panelTitle

	variable fifoPos
	string oscilloscopeSubwindow = SCOPE_GetGraph(panelTitle)

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_ITC_PrepareAcq(ITCDeviceIDGlobal)

	if(GetCheckBoxState(panelTitle, "Check_DataAcq1_RepeatAcq"))
		ITC_StartITCDeviceTimer(panelTitle) // starts a timer for each ITC device. Timer is used to do real time ITI timing.
	endif

	HW_StartAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)

	do
		DoXOPIdle
		SCOPE_UpdateOscilloscopeData(panelTitle, DATA_ACQUISITION_MODE, fifoPos=fifoPos)
		DoUpdate/W=$oscilloscopeSubwindow
	while(HW_ITC_MoreData(ITCDeviceIDGlobal, fifoPos=fifoPos))

	HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, prepareForDAQ=1)

	SWS_SaveAndScaleITCData(panelTitle)
End

Function ITC_BkrdDataAcq(panelTitle)
	string panelTitle

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_ITC_PrepareAcq(ITCDeviceIDGlobal)

	if(GetCheckboxState(panelTitle, "Check_DataAcq1_RepeatAcq"))
		ITC_StartITCDeviceTimer(panelTitle) // starts a timer for each ITC device. Timer is used to do real time ITI timing.
	endif

	HW_StartAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)

	ITC_StartBckgrdFIFOMonitor()
End

Function ITC_StopDataAcq()

	SVAR panelTitleG = $GetPanelTitleGlobal()
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitleG)

	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)
	HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, prepareForDAQ=1, zeroDAC = 1)

	SWS_SaveAndScaleITCData(panelTitleG)

	if(RA_IsFirstSweep(panelTitleG))
		if(GetCheckboxState(panelTitleG, "Check_DataAcq1_RepeatAcq"))
			RA_Start(PanelTitleG)
		else
			DAP_OneTimeCallAfterDAQ(panelTitleG)
		endif
	else
		RA_BckgTPwithCallToRACounter(panelTitleG)
	endif
END

Function ITC_StartBckgrdFIFOMonitor()
	CtrlNamedBackground ITC_FIFOMonitor, period = 5, proc = ITC_FIFOMonitor
	CtrlNamedBackground ITC_FIFOMonitor, start
End

Function ITC_FIFOMonitor(s)
	STRUCT WMBackgroundStruct &s

	string oscilloscopeSubwindow
	variable fifoPos, moreData, anaFuncReturn, result

	SVAR panelTitleG       = $GetPanelTitleGlobal()
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitleG)
	oscilloscopeSubwindow  = SCOPE_GetGraph(panelTitleG)

	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)

	moreData = HW_ITC_MoreData(ITCDeviceIDGlobal, fifoPos=fifoPos)

	SCOPE_UpdateOscilloscopeData(panelTitleG, DATA_ACQUISITION_MODE, fifoPos=fifoPos)

	AM_analysisMasterMidSweep(panelTitleG)

	if(moreData)
		result = AFM_CallAnalysisFunctions(panelTitleG, MID_SWEEP_EVENT)

		if(result == ANALYSIS_FUNC_RET_REPURP_TIME)
			UpdateLeftOverSweepTime(panelTitleG, fifoPos)
			moreData = 0
		elseif(result == ANALYSIS_FUNC_RET_EARLY_STOP)
			moreData = 0
		endif
	endif

	if(!moreData)
		ITC_STOPFifoMonitor()
		ITC_StopDataAcq()
		return 1
	endif

	return 0
End

Function ITC_STOPFifoMonitor()
	CtrlNamedBackground ITC_FIFOMonitor, stop
End

Function ITC_StartBackgroundTimer(panelTitle, runTime, funcList)
	string panelTitle, funcList
	variable runTime

	ASSERT(!isEmpty(funcList), "Empty funcList does not makse sense")

	SVAR repeatedAcqFuncList = $GetRepeatedAcquisitionFuncList()
	NVAR repeatedAcqDuration = $GetRepeatedAcquisitionDuration()
	NVAR repeatedAcqStart    = $GetRepeatedAcquisitionStart()

	repeatedAcqFuncList = funcList
	repeatedAcqStart    = ticks
	repeatedAcqDuration = runTime / TICKS_TO_SECONDS

	CtrlNamedBackground ITC_Timer, period = 5, proc = ITC_Timer, start
End

Function ITC_Timer(s)
	STRUCT WMBackgroundStruct &s

	variable timeLeft, elapsedTime

	NVAR repeatedAcqStart    = $GetRepeatedAcquisitionStart()
	NVAR repeatedAcqDuration = $GetRepeatedAcquisitionDuration()
	SVAR panelTitleG         = $GetPanelTitleGlobal()

	elapsedTime = ticks - repeatedAcqStart
	timeLeft    = max((repeatedAcqDuration - elapsedTime) * TICKS_TO_SECONDS, 0)

	SetValDisplay(panelTitleG, "valdisp_DataAcq_ITICountdown", var = timeLeft)

	if(elapsedTime >= repeatedAcqDuration)
		ITC_StopBackgroundTimerTask()
		return 1
	endif

	return 0
End

Function ITC_StopBackgroundTimerTask()

	CtrlNamedBackground ITC_Timer, stop

	SVAR repeatedAcqFuncList = $GetRepeatedAcquisitionFuncList()
	ExecuteListOfFunctions(repeatedAcqFuncList)
End

Function ITC_StartBackgroundTestPulse(panelTitle)
	string panelTitle

	CtrlNamedBackground TestPulse, period = 5, proc = ITC_TestPulseFunc
	CtrlNamedBackground TestPulse, start
End

///@brief Background execution function for the test pulse data acquisition
Function ITC_TestPulseFunc(s)
	STRUCT BackgroundStruct &s

	SVAR panelTitleG = $GetPanelTitleGlobal()
	// create a copy as panelTitleG is killed in ITC_StopTestPulseSingleDevice
	// but we still need it afterwards
	string panelTitle = panelTitleG

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	if(s.wmbs.started)
		s.wmbs.started = 0
		s.count  = 0
	else
		s.count += 1
	endif

	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_ITC_ResetFifo(ITCDeviceIDGlobal)
	HW_StartAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)

	do
		// nothing
	while (HW_ITC_MoreData(ITCDeviceIDGlobal))

	HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, prepareForDAQ=1)
	SCOPE_UpdateOscilloscopeData(panelTitle, TEST_PULSE_MODE)
	TP_Delta(panelTitle)

	if(mod(s.count, TEST_PULSE_LIVE_UPDATE_INTERVAL) == 0)
		SCOPE_UpdateGraph(panelTitle)
	endif

	if(RA_IsFirstSweep(panelTitle))
		if(GetKeyState(0) & ESCAPE_KEY)
			beep
			ITC_StopTestPulseSingleDevice(panelTitle)
		endif
	endif

	return 0
End

Function ITC_StopTestPulseSingleDevice(panelTitle)
	string panelTitle

	variable headstage

	CtrlNamedBackground TestPulse, stop

	TP_Teardown(panelTitle)
End

static Constant DEFAULT_MAXAUTOBIASCURRENT = 1500e-12 /// Unit: Amps
static Constant AUTOBIAS_INTERVALL_SECONDS = 1

/// @brief Handle automatic bias current injection
///
/// @param panelTitle	locked panel with test pulse running occasionally
/// @param BaselineSSAvg
/// @param SSResistance
Function ITC_ApplyAutoBias(panelTitle, BaselineSSAvg, SSResistance)
	string panelTitle
	Wave BaselineSSAvg, SSResistance

	variable headStage, actualcurrent, current, targetVoltage, targetVoltageTol, setVoltage
	variable activeADCol, DAC, ADC
	variable resistance, maximumAutoBiasCurrent
	Wave TPStorage = GetTPStorage(panelTitle)
	variable lastInvocation = GetNumberFromWaveNote(TPStorage, AUTOBIAS_LAST_INVOCATION_KEY)
	variable curTime = ticks * TICKS_TO_SECONDS

	if( (curTime - lastInvocation) < AUTOBIAS_INTERVALL_SECONDS )
		return NaN
	endif

	DEBUGPRINT("ITC_ApplyAutoBias's turn, curTime=", var=curTime)
	SetNumberInWaveNote(TPStorage, AUTOBIAS_LAST_INVOCATION_KEY, curTime)

	if(isEmpty(panelTitle))
		DEBUGPRINT("Can't work with an empty panelTitle")
		return NaN
	endif

	Wave channelClampMode = GetChannelClampMode(panelTitle)
	Wave ampSettings      = GetAmplifierParamStorageWave(panelTitle)

	for(headStage=0; headStage < NUM_HEADSTAGES; headStage+=1)

		DAC = AFH_GetDACFromHeadstage(panelTitle, headstage)
		ADC = AFH_GetADCFromHeadstage(panelTitle, headstage)

		// From DAP_RemoveClampModeSettings and DAP_ApplyClmpModeSavdSettngs we know that
		// both wave entries are NaN iff the headstage is unset
		if(!IsFinite(DAC) || !IsFinite(ADC) || !IsFinite(channelClampMode[DAC][%DAC]) || !IsFinite(channelClampMode[ADC][%ADC]))
			continue
		endif

		// headStage channels not in current clamp mode
		if(channelClampMode[DAC][%DAC] != I_CLAMP_MODE && channelClampMode[ADC][%ADC] != I_CLAMP_MODE)
			continue
		endif

		// autobias not enabled
		if(!ampSettings[%AutoBiasEnable][0][headStage])
			continue
		endif

		DEBUGPRINT("current clamp mode set in headstage", var=headStage)

		maximumAutoBiasCurrent = abs(ampSettings[%AutoBiasIbiasmax][0][headStage] * 1e-12)
		if(maximumAutoBiasCurrent == 0 || maximumAutoBiasCurrent > DEFAULT_MAXAUTOBIASCURRENT)
			printf "Warning for headStage %d: replacing invalid maximum auto bias currrent of %g with %g\r", headStage, maximumAutoBiasCurrent, DEFAULT_MAXAUTOBIASCURRENT
			maximumAutoBiasCurrent = DEFAULT_MAXAUTOBIASCURRENT
		endif

		DEBUGPRINT("maximumAutoBiasCurrent=", var=maximumAutoBiasCurrent)

		/// all variables holding physical units use plain values without prefixes
		/// e.g Amps instead of pA

		targetVoltage    = ampSettings[%AutoBiasVcom][0][headStage] * 1e-3
		targetVoltageTol = ampSettings[%AutoBiasVcomVariance][0][headStage] * 1e-3

		activeADCol = TP_GetTPResultsColOfHS(panelTitle, headstage)
		ASSERT(activeADCol >= 0, "Active Testpulse column is invalid")

		resistance = SSResistance[0][activeADCol] * 1e6
		setVoltage = BaselineSSAvg[0][activeADCol] * 1e-3

		DEBUGPRINT("resistance[Ohm]=", var=resistance)
		DEBUGPRINT("setVoltage[V]=", var=setVoltage)
		DEBUGPRINT("targetVoltage[V]=", var=targetVoltage)

		// if we are in the desired voltage region, check the next headstage
		if(abs(targetVoltage - setVoltage) < targetVoltageTol)
			continue
		endif

		// neuron needs a current shot
		// I = U / R
		current = ( targetVoltage - setVoltage ) / resistance
		DEBUGPRINT("current[A]=", var=current)
		// only use part of the calculated current, as BaselineSSAvg holds
		// an overestimate for small buffer sizes
		current *= 0.15
		
		// check if holding is enabled. If it is not, ignore holding current value.
		if(AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETHOLDINGENABLE_FUNC, NaN))
			actualCurrent = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETHOLDING_FUNC, NaN, usePrefixes=0)
		else
			actualCurrent = 0
		endif

		DEBUGPRINT("actualCurrent[A]=", var=actualCurrent)

		if(!IsFinite(actualCurrent))
			print "Queried amplifier current is non-finite"
			ControlWindowToFront()
			continue
		endif

		current += actualCurrent

		if( abs(current) > maximumAutoBiasCurrent)
			printf "Headstage %d: Not applying autobias current shot of %gA as that would exceed the maximum allowed current of %gA\r", headStage, current, maximumAutoBiasCurrent
			continue
		endif

		DEBUGPRINT("current[A] to send=", var=current)
		AI_UpdateAmpModel(panelTitle, "check_DatAcq_HoldEnable", headStage, value=1)
		AI_UpdateAmpModel(panelTitle, "setvar_DataAcq_Hold_IC", headstage, value=current * 1e12)
	endfor
End

/// @brief Low level implementation for starting the test pulse
///
/// Please check before calling this function if not the functions #TP_StartTestPulseSingleDevice
/// or #TP_StartTestPulseMultiDevice are better suited for your application.
Function ITC_StartTestPulse(panelTitle)
	string panelTitle

	variable i
	string oscilloscopeSubwindow

	oscilloscopeSubwindow = SCOPE_GetGraph(panelTitle)
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	do
		DoXOPIdle
		HW_ITC_ResetFifo(ITCDeviceIDGlobal)
		HW_StartAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)

		do
			// nothing
		while (HW_ITC_MoreData(ITCDeviceIDGlobal))

		HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, prepareForDAQ=1)
		SCOPE_UpdateOscilloscopeData(panelTitle, TEST_PULSE_MODE)
		TP_Delta(panelTitle)

		if(mod(i, TEST_PULSE_LIVE_UPDATE_INTERVAL) == 0)
			SCOPE_UpdateGraph(panelTitle)
		endif

		DoUpdate/W=$oscilloscopeSubwindow

		i += 1	
	while(!(GetKeyState(0) & ESCAPE_KEY))

	TP_Teardown(panelTitle)
END

Function ITC_ADDataBasedWaveNotes(asyncMeasurementWave, panelTitle)
	WAVE asyncMeasurementWave
	string panelTitle

	// This function takes about 0.9 seconds to run
	// this is the wave that the note gets appended to. The note contains the async ad channel value and info
	variable i, numEntries, rawChannelValue, gain, deviceChannelOffset
	string setvarTitle, setvarGain, title

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	WAVE asyncChannelState = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_ASYNC)
	deviceChannelOffset = HW_ITC_CalculateDevChannelOff(panelTitle)

	numEntries = DimSize(asyncChannelState, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!asyncChannelState[i])
			continue
		endif

		// Async channels start at channel 16 on ITC 1600, needs to be a diff value constant for ITC18
		rawChannelValue = HW_ReadADC(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, i + deviceChannelOffset)

		sprintf setvarTitle, "SetVar_AsyncAD_Title_%02d", i
		setvarGain= GetPanelControl(i, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN)

		title = GetSetVariableString(panelTitle, setvarTitle)
		gain  = GetSetVariable(panelTitle, setvarGain)

		// put the measurement value into the async settings wave for creation of wave notes
		asyncMeasurementWave[0][i][,;LABNOTEBOOK_LAYER_COUNT - 1] = rawChannelValue / gain

		ITC_SupportSystemAlarm(i, asyncMeasurementWave[0][i], title, panelTitle)
	endfor
End

static Function ITC_SupportSystemAlarm(Channel, Measurement, MeasurementTitle, panelTitle)
	variable Channel, Measurement
	string MeasurementTitle, panelTitle

	string minCtrl, maxCtrl, checkCtrl
	variable paramMin, paramMax

	checkCtrl = GetPanelControl(channel, CHANNEL_TYPE_ALARM, CHANNEL_CONTROL_CHECK)
	if(GetCheckBoxState(panelTitle, checkCtrl))
		minCtrl = GetPanelControl(channel, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN)
		paramMin = GetSetVariable(panelTitle, minCtrl)
		maxCtrl = GetPanelControl(channel, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX)
		paramMax = GetSetVariable(panelTitle, maxCtrl)
		if(Measurement >= ParamMax || Measurement <= ParamMin)
			beep
			print time() + " !!!!!!!!!!!!! " + MeasurementTitle + " has exceeded max/min settings" + " !!!!!!!!!!!!!"
			ControlWindowToFront()
			beep
		endif
	endif
End

/// @brief Start data acquisition using single device mode
///
/// This is the high level function usable for all external users.
///
/// @param panelTitle    device
/// @param useBackground [optional, defaults to background checkbox setting in the DA_Ephys
///                      panel]
Function ITC_StartDAQSingleDevice(panelTitle, [useBackground])
	string panelTitle
	variable useBackground

	NVAR dataAcqRunMode = $GetDataAcqRunMode(panelTitle)

	if(dataAcqRunMode == DAQ_NOT_RUNNING)

		AbortOnValue DAP_CheckSettings(panelTitle, DATA_ACQUISITION_MODE),1

		if(IsDeviceActiveWithBGTask(panelTitle, "Testpulse"))
			ITC_StopTestPulseSingleDevice(panelTitle)
		endif

		if(ParamIsDefault(useBackground))
			useBackground = GetCheckBoxState(panelTitle, "Check_Settings_BackgrndDataAcq")
		else
			useBackground = !!useBackground
		endif

		DAP_OneTimeCallBeforeDAQ(panelTitle, useBackground == 1 ? DAQ_BG_SINGLE_DEVICE : DAQ_FG_SINGLE_DEVICE)

		try
			DC_ConfigureDataForITC(panelTitle, DATA_ACQUISITION_MODE)
		catch
			// we need to undo the earlier one time call only
			DAP_OneTimeCallAfterDAQ(panelTitle, forcedStop = 1)
			return NaN
		endtry

		if(!useBackground)
			ITC_DataAcq(panelTitle)
			if(GetCheckBoxState(panelTitle, "Check_DataAcq1_RepeatAcq"))
				RA_Start(panelTitle)
			else
				DAP_OneTimeCallAfterDAQ(panelTitle)
			endif
		else
			ITC_BkrdDataAcq(panelTitle)
		endif
	else
		DAP_StopOngoingDataAcquisition(panelTitle)
	endif
End

/// @brief Start data acquisition using multi device mode
///
/// This is the high level function usable for all external users.
Function ITC_StartDAQMultiDevice(panelTitle)
	string panelTitle

	NVAR dataAcqRunMode = $GetDataAcqRunMode(panelTitle)

	if(dataAcqRunMode == DAQ_NOT_RUNNING)

		AbortOnValue DAP_CheckSettings(panelTitle, DATA_ACQUISITION_MODE), 1

		if(IsDeviceActiveWithBGTask(panelTitle, "TestPulseMD"))
			 ITC_StopTestPulseMultiDevice(panelTitle)
		endif

		ITC_StartDAQMultiDeviceLowLevel(panelTitle)
	else // data acquistion is ongoing, stop data acq
		ITC_StopOngoingDAQMultiDevice(panelTitle)
	endif
End

/// @brief Stop any running background DAQ
///
/// Assumes that single device and multi device do not run at the same time.
/// @return One of @ref DAQRunModes
Function ITC_StopDAQ(panelTitle)
	string panelTitle

	variable runMode

	NVAR dataAcqRunMode = $GetDataAcqRunMode(panelTitle)

	// create copy as the implicitly called DAP_OneTimeCallAfterDAQ()
	// will change it
	runMode = dataAcqRunMode

	switch(runMode)
		case DAQ_FG_SINGLE_DEVICE:
			// can not be stopped
			return runMode
		case DAQ_BG_SINGLE_DEVICE:
			DAP_StopOngoingDataAcquisition(panelTitle)
			return runMode
		case DAQ_BG_MULTI_DEVICE:
			ITC_StopOngoingDAQMultiDevice(panelTitle)
			return runMode
	endswitch

	return DAQ_NOT_RUNNING
End

/// @todo how to handle yoked devices??
Function ITC_RestartDAQ(panelTitle, dataAcqRunMode)
	string panelTitle
	variable dataAcqRunMode

	switch(dataAcqRunMode)
		case DAQ_NOT_RUNNING:
			// nothing to do
			break
		case DAQ_FG_SINGLE_DEVICE:
			ITC_StartDAQSingleDevice(panelTitle, useBackground=0)
			break
		case DAQ_BG_SINGLE_DEVICE:
			ITC_StartDAQSingleDevice(panelTitle, useBackground=1)
			break
		case DAQ_BG_MULTI_DEVICE:
			ITC_StartDAQMultiDevice(panelTitle)
			break
		default:
			DEBUGPRINT("Ignoring unknown value:", var=dataAcqRunMode)
			break
	endswitch
End
