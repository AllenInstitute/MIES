#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
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

	ASSERT(WhichListItem(GetRTStackInfo(2), DAQ_ALLOWED_FUNCTIONS) != -1, \
		"Calling this function directly is not supported, please use PGC_SetAndActivateControl.")

	if(ParamIsDefault(useBackground))
		useBackground = DAG_GetNumericalValue(panelTitle, "Check_Settings_BackgrndDataAcq")
	else
		useBackground = !!useBackground
	endif

	DAP_OneTimeCallBeforeDAQ(panelTitle, useBackground == 1 ? DAQ_BG_SINGLE_DEVICE : DAQ_FG_SINGLE_DEVICE)

	try
		DC_Configure(panelTitle, DATA_ACQUISITION_MODE)
	catch
		// we need to undo the earlier one time call only
		DAP_OneTimeCallAfterDAQ(panelTitle, forcedStop = 1)
		return NaN
	endtry

	if(useBackground)
		DQS_BkrdDataAcq(panelTitle)
	else
		DQS_DataAcq(panelTitle)
	endif
End

Function DQS_DataAcq(panelTitle)
	string panelTitle

	variable fifoPos, gotTPChannels, moreData
	string oscilloscopeSubwindow = SCOPE_GetGraph(panelTitle)

	NVAR deviceID = $GetDAQDeviceID(panelTitle)

	HW_PrepareAcq(HARDWARE_ITC_DAC, deviceID, DATA_ACQUISITION_MODE, flags=HARDWARE_ABORT_ON_ERROR)

	if(DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_RepeatAcq"))
		DQ_StartDAQDeviceTimer(panelTitle)
	endif

	HW_StartAcq(HARDWARE_ITC_DAC, deviceID, flags=HARDWARE_ABORT_ON_ERROR)
	AS_HandlePossibleTransition(panelTitle, AS_MID_SWEEP)

	gotTPChannels = GotTPChannelsOnADCs(paneltitle)

	do
		DoXOPIdle

		moreData = HW_ITC_MoreData(deviceID, fifoPos=fifoPos)
		SCOPE_UpdateOscilloscopeData(panelTitle, DATA_ACQUISITION_MODE, fifoPos=fifoPos)

		if(gotTPChannels)
			SCOPE_UpdateGraph(panelTitle, DATA_ACQUISITION_MODE)
		endif

		DoUpdate/W=$oscilloscopeSubwindow
		if(GetKeyState(0) & ESCAPE_KEY)
			DQS_StopDataAcq(panelTitle, forcedStop = 1)
			return NaN
		endif
	while(moreData)

	DQS_StopDataAcq(panelTitle)
End

/// @brief Fifo monitor for DAQ Single Device
///
/// @ingroup BackgroundFunctions
Function DQS_BkrdDataAcq(panelTitle)
	string panelTitle

	NVAR deviceID = $GetDAQDeviceID(panelTitle)
	HW_PrepareAcq(HARDWARE_ITC_DAC, deviceID, DATA_ACQUISITION_MODE, flags=HARDWARE_ABORT_ON_ERROR)

	if(DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_RepeatAcq"))
		DQ_StartDAQDeviceTimer(panelTitle)
	endif

	HW_StartAcq(HARDWARE_ITC_DAC, deviceID, flags=HARDWARE_ABORT_ON_ERROR)
	AS_HandlePossibleTransition(panelTitle, AS_MID_SWEEP)

	DQS_StartBackgroundFifoMonitor()
End

/// @brief Stop single device data acquisition
static Function DQS_StopDataAcq(string panelTitle, [variable forcedStop])
	if(ParamIsDefault(forcedStop))
		forcedStop = 0
	else
		forcedStop = !!forcedStop
	endif

	NVAR deviceID = $GetDAQDeviceID(panelTitle)
	HW_StopAcq(HARDWARE_ITC_DAC, deviceID, prepareForDAQ = 1, zeroDAC=1, flags=HARDWARE_ABORT_ON_ERROR)
	SWS_SaveAcquiredData(panelTitle, forcedStop = forcedStop)

	if(forcedStop)
		DQ_StopOngoingDAQ(panelTitle)
	else
		RA_ContinueOrStop(panelTitle, multiDevice=0)
	endif
End

Function DQS_StartBackgroundFifoMonitor()
	CtrlNamedBackground $TASKNAME_FIFOMON, start
End

/// @brief Fifo monitor for DAQ Single Device
///
/// @ingroup BackgroundFunctions
Function DQS_FIFOMonitor(s)
	STRUCT WMBackgroundStruct &s

	variable fifoPos, moreData, anaFuncReturn, result

	SVAR panelTitleG       = $GetPanelTitleGlobal()
	NVAR deviceID = $GetDAQDeviceID(panelTitleG)

	moreData = HW_ITC_MoreData(deviceID, fifoPos=fifoPos, flags=HARDWARE_ABORT_ON_ERROR)

	SCOPE_UpdateOscilloscopeData(panelTitleG, DATA_ACQUISITION_MODE, fifoPos=fifoPos)

	result = AS_HandlePossibleTransition(panelTitleG, AS_MID_SWEEP)

	if(result == ANALYSIS_FUNC_RET_REPURP_TIME)
		UpdateLeftOverSweepTime(panelTitleG, fifoPos)
		moreData = 0
	elseif(result == ANALYSIS_FUNC_RET_EARLY_STOP)
		moreData = 0
	endif

	SCOPE_UpdateGraph(panelTitleG, DATA_ACQUISITION_MODE)

	if(!moreData)
		DQS_STOPBackgroundFifoMonitor()
		DQS_StopDataAcq(panelTitleG)
		return 1
	endif

	if(GetKeyState(0) & ESCAPE_KEY)
		DQ_StopOngoingDAQ(panelTitleG, startTPAfterDAQ = 0)
		return 1
	endif

	return 0
End

Function DQS_StopBackgroundFifoMonitor()
	CtrlNamedBackground $TASKNAME_FIFOMON, stop
End

/// @brief Start the background timer for the inter trial interval (ITI)
///
/// @param panelTitle device
/// @param runTime    left over time to wait in seconds
/// @param funcList   list of functions to execute at the end of the ITI
Function DQS_StartBackgroundTimer(panelTitle, runTime, funcList)
	string panelTitle, funcList
	variable runTime

	ASSERT(!isEmpty(funcList), "Empty funcList does not makse sense")

	SVAR repeatedAcqFuncList = $GetRepeatedAcquisitionFuncList()
	NVAR repeatedAcqDuration = $GetRepeatedAcquisitionDuration()
	NVAR repeatedAcqStart    = $GetRepeatedAcquisitionStart()

	repeatedAcqFuncList = funcList
	repeatedAcqStart    = RelativeNowHighPrec()
	repeatedAcqDuration = runTime

	CtrlNamedBackground $TASKNAME_TIMER, start
End

/// @brief Stop the background timer used for ITI tracking
Function DQS_StopBackgroundTimer()

	CtrlNamedBackground $TASKNAME_TIMER, stop
End

/// @brief Keep track of time during ITI
///
/// @ingroup BackgroundFunctions
Function DQS_Timer(s)
	STRUCT WMBackgroundStruct &s

	variable timeLeft, elapsedTime

	NVAR repeatedAcqStart    = $GetRepeatedAcquisitionStart()
	NVAR repeatedAcqDuration = $GetRepeatedAcquisitionDuration()
	SVAR panelTitleG         = $GetPanelTitleGlobal()

	elapsedTime = RelativeNowHighPrec() - repeatedAcqStart
	timeLeft    = max(repeatedAcqDuration - elapsedTime, 0)

	SetValDisplay(panelTitleG, "valdisp_DataAcq_ITICountdown", var = timeLeft)

	if(elapsedTime >= repeatedAcqDuration)
		SVAR repeatedAcqFuncList = $GetRepeatedAcquisitionFuncList()
		ExecuteListOfFunctions(repeatedAcqFuncList)
		return 1
	endif

	return 0
End
