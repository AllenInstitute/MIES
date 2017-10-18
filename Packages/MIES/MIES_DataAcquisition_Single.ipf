#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DAQ_SD
#endif

/// @file MIES_DataAcquisition_Single.ipf
/// @brief __DQS__ Routines for Single Device Data acquisition

/// @brief Start data acquisition using single device mode
///
/// This is the high level function usable for all external users.
///
/// @param panelTitle    device
/// @param useBackground [optional, defaults to background checkbox setting in the DA_Ephys
///                      panel]
Function DQS_StartDAQSingleDevice(panelTitle, [useBackground])
	string panelTitle
	variable useBackground

	NVAR dataAcqRunMode = $GetDataAcqRunMode(panelTitle)

	if(dataAcqRunMode == DAQ_NOT_RUNNING)

		AbortOnValue DAP_CheckSettings(panelTitle, DATA_ACQUISITION_MODE),1

		TP_StopTestPulse(panelTitle)

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
			DQS_DataAcq(panelTitle)
			if(GetCheckBoxState(panelTitle, "Check_DataAcq1_RepeatAcq"))
				RA_Start(panelTitle)
			else
				DAP_OneTimeCallAfterDAQ(panelTitle)
			endif
		else
			DQS_BkrdDataAcq(panelTitle)
		endif
	else
		ITC_StopDAQ(panelTitle)
	endif
End

static Function DQS_DataAcq(panelTitle)
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
	ED_MarkSweepStart(panelTitle)

	do
		DoXOPIdle
		SCOPE_UpdateOscilloscopeData(panelTitle, DATA_ACQUISITION_MODE, fifoPos=fifoPos)
		DoUpdate/W=$oscilloscopeSubwindow
	while(HW_ITC_MoreData(ITCDeviceIDGlobal, fifoPos=fifoPos))

	HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, prepareForDAQ=1)

	SWS_SaveAndScaleITCData(panelTitle)
End

Function DQS_BkrdDataAcq(panelTitle)
	string panelTitle

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_ITC_PrepareAcq(ITCDeviceIDGlobal)

	if(GetCheckboxState(panelTitle, "Check_DataAcq1_RepeatAcq"))
		ITC_StartITCDeviceTimer(panelTitle) // starts a timer for each ITC device. Timer is used to do real time ITI timing.
	endif

	HW_StartAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	ED_MarkSweepStart(panelTitle)

	DQS_StartBackgroundFifoMonitor()
End

static Function DQS_StopDataAcq()

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

Function DQS_StartBackgroundFifoMonitor()
	CtrlNamedBackground ITC_FIFOMonitor, period = 5, proc = ITC_FIFOMonitor
	CtrlNamedBackground ITC_FIFOMonitor, start
End

Function DQS_FIFOMonitor(s)
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
		DQS_STOPBackgroundFifoMonitor()
		DQS_StopDataAcq()
		return 1
	endif

	return 0
End

Function DQS_StopBackgroundFifoMonitor()
	CtrlNamedBackground ITC_FIFOMonitor, stop
End

/// @brief Start the background timer used for ITI tracking
Function DQS_StartBackgroundTimer(panelTitle, runTime, funcList)
	string panelTitle, funcList
	variable runTime

	ASSERT(!isEmpty(funcList), "Empty funcList does not makse sense")

	SVAR repeatedAcqFuncList = $GetRepeatedAcquisitionFuncList()
	NVAR repeatedAcqDuration = $GetRepeatedAcquisitionDuration()
	NVAR repeatedAcqStart    = $GetRepeatedAcquisitionStart()

	repeatedAcqFuncList = funcList
	repeatedAcqStart    = ticks
	repeatedAcqDuration = runTime / TICKS_TO_SECONDS

	CtrlNamedBackground ITC_Timer, period = 5, proc = DQS_Timer, start
End

/// @brief Stop the background timer used for ITI tracking
Function DQS_StopBackgroundTimer()

	CtrlNamedBackground ITC_Timer, stop
End

Function DQS_Timer(s)
	STRUCT WMBackgroundStruct &s

	variable timeLeft, elapsedTime

	NVAR repeatedAcqStart    = $GetRepeatedAcquisitionStart()
	NVAR repeatedAcqDuration = $GetRepeatedAcquisitionDuration()
	SVAR panelTitleG         = $GetPanelTitleGlobal()

	elapsedTime = ticks - repeatedAcqStart
	timeLeft    = max((repeatedAcqDuration - elapsedTime) * TICKS_TO_SECONDS, 0)

	SetValDisplay(panelTitleG, "valdisp_DataAcq_ITICountdown", var = timeLeft)

	if(elapsedTime >= repeatedAcqDuration)
		SVAR repeatedAcqFuncList = $GetRepeatedAcquisitionFuncList()
		ExecuteListOfFunctions(repeatedAcqFuncList)
		return 1
	endif

	return 0
End
