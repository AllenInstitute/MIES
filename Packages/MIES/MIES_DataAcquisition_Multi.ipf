#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DAQ_MD
#endif

/// @file MIES_DataAcquisition_Multi.ipf
/// @brief __DQM__ Routines for Multi Device Data acquisition

//Reinitialize Device 1 with intrabox clock
// Execute "ITCInitialize /M = 1"
// Execute "ITCStartAcq 1, 256"

/// @brief Start data acquisition using multi device mode
///
/// This is the high level function usable for all external users.
Function DQM_StartDAQMultiDevice(panelTitle)
	string panelTitle

	NVAR dataAcqRunMode = $GetDataAcqRunMode(panelTitle)

	if(dataAcqRunMode == DAQ_NOT_RUNNING)

		AbortOnValue DAP_CheckSettings(panelTitle, DATA_ACQUISITION_MODE), 1

		TP_StopTestPulse(panelTitle)
		DQM_StartDAQMultiDeviceLowLevel(panelTitle)
	else // data acquistion is ongoing, stop data acq
		DQ_StopOngoingDAQ(panelTitle)
	endif
End

/// @brief Fifo monitor for DAQ Multi Device
///
/// @ingroup BackgroundFunctions
Function DQM_FIFOMonitor(s)
	STRUCT WMBackgroundStruct &s

	DFREF activeDevices = GetActiveITCDevicesFolder()
	WAVE/SDFR=activeDevices ActiveDeviceList
	variable deviceID, isFinished
	variable i, fifoPos, result
	string panelTitle

	for(i = 0; i < DimSize(ActiveDeviceList, ROWS); i += 1)
		deviceID   = ActiveDeviceList[i][0]
		panelTitle = HW_GetMainDeviceName(HARDWARE_ITC_DAC, deviceID)

		NVAR tgID = $GetThreadGroupIDFIFO(panelTitle)
		fifoPos = TS_GetNewestFromThreadQueue(tgID, "fifoPos")
		isFinished = IsNaN(fifoPos)

		SCOPE_UpdateOscilloscopeData(panelTitle, DATA_ACQUISITION_MODE, fifoPos=fifoPos)

		if(!isFinished)
			result = AFM_CallAnalysisFunctions(panelTitle, MID_SWEEP_EVENT)

			if(result == ANALYSIS_FUNC_RET_REPURP_TIME)
				UpdateLeftOverSweepTime(panelTitle, fifoPos)
				isFinished = 1
			elseif(result == ANALYSIS_FUNC_RET_EARLY_STOP)
				isFinished = 1
			endif
		endif

		if(isFinished)
			DQM_MakeOrUpdateActivDevLstWave(panelTitle, deviceID, 0, 0, -1)
			DQM_StopDataAcq(panelTitle, deviceID)
			i = 0
			continue
		endif
	endfor

	if(DimSize(ActiveDeviceList, ROWS) == 0)
		return 1
	endif

	return 0
End

/// @brief Stop ongoing multi device DAQ
///
/// Follower handling for yoked devices is done by the caller.
Function DQM_TerminateOngoingDAQHelper(panelTitle)
	String panelTitle

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	WAVE/T/SDFR=GetActiveITCDevicesFolder() ActiveDeviceList

	TFH_StopFIFODaemon(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)
	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, zeroDAC = 1)

	// remove device passed in from active device lists
	DQM_MakeOrUpdateActivDevLstWave(panelTitle, ITCDeviceIDGlobal, 0, 0, -1)

	// determine if device removed was the last device on the list, if yes stop the background function
	if(DimSize(ActiveDeviceList, ROWS) == 0)
		CtrlNamedBackground ITC_FIFOMonitorMD, stop
	endif
END

/// @brief Handles function calls for data acquistion. These include calls for starting Yoked ITC1600s.
///
/// Handles the calls to the data configurator (DC) functions and BackgroundMD
/// it is required because of the special handling syncronous ITC1600s require
///
/// @param panelTitle      device
/// @param initialSetupReq [optional, defaults to true] performs initialization routines
///                        at the very beginning of DAQ, turn off for RA
Function DQM_StartDAQMultiDeviceLowLevel(panelTitle, [initialSetupReq])
	string panelTitle
	variable initialSetupReq

	variable numFollower, i
	string followerPanelTitle

	if(ParamIsDefault(initialSetupReq))
		initialSetupReq = 1
	else
		initialSetupReq = !!initialSetupReq
	endif

	try
		if(initialSetupReq)
			DAP_OneTimeCallBeforeDAQ(panelTitle, DAQ_BG_MULTI_DEVICE)
		endif

		DC_ConfigureDataForITC(panelTitle, DATA_ACQUISITION_MODE)
	catch
		if(initialSetupReq)
			DAP_OneTimeCallAfterDAQ(panelTitle, forcedStop = 1)
		else // required for RA for the lead device only
			DQ_StopITCDeviceTimer(panelTitle)
		endif

		return NaN
	endtry

	// configure passed device
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_ITC_PrepareAcq(ITCDeviceIDGlobal)

	if(!DeviceHasFollower(panelTitle))
		DQM_BkrdDataAcq(panelTitle)
		return NaN
	endif

	SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)
	numFollower = ItemsInList(listOfFollowerDevices)

	try
		for(i = 0; i < numFollower; i += 1)
			followerPanelTitle = StringFromList(i, listOfFollowerDevices)

			if(initialSetupReq)
				DAP_OneTimeCallBeforeDAQ(followerPanelTitle, DAQ_BG_MULTI_DEVICE)
			endif

			DC_ConfigureDataForITC(followerPanelTitle, DATA_ACQUISITION_MODE)
		endfor
	catch
		if(initialSetupReq)
			for(i = 0; i < numFollower; i += 1)
				followerPanelTitle = StringFromList(i, listOfFollowerDevices)
				DAP_OneTimeCallAfterDAQ(followerPanelTitle, forcedStop = 1)
			endfor

			DAP_OneTimeCallAfterDAQ(panelTitle, forcedStop = 1)
		else // required for RA for the lead device only
			DQ_StopITCDeviceTimer(panelTitle)
		endif

		return NaN
	endtry

	// configure follower devices
	for(i = 0; i < numFollower; i += 1)
		followerPanelTitle = StringFromList(i, listOfFollowerDevices)

		NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(followerPanelTitle)
		HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
		HW_ITC_PrepareAcq(ITCDeviceIDGlobal)
	endfor

	// start lead device
	DQM_BkrdDataAcq(panelTitle, triggerMode=HARDWARE_DAC_EXTERNAL_TRIGGER)

	// start follower devices
	for(i = 0; i < numFollower; i += 1)
		followerPanelTitle = StringFromList(i, listOfFollowerDevices)
		DQM_BkrdDataAcq(followerPanelTitle, triggerMode=HARDWARE_DAC_EXTERNAL_TRIGGER)
	endfor

	if(GetCheckBoxState(panelTitle, "Check_DataAcq1_RepeatAcq"))
		DQ_StartITCDeviceTimer(panelTitle)
	endif

	// trigger
	ARDStartSequence()
End

/// @brief Call a function for a device and if this device is a leader with followers
/// for all follower too.
///
/// Handles also non-yoked devices in multi device mode correctly.
Function DQM_CallFuncForDevicesYoked(panelTitle, func)
	string panelTitle
	FUNCREF CALL_FUNCTION_LIST_PROTOTYPE func

	string list = GetListofLeaderAndPossFollower(panelTitle)
	CallFunctionForEachListItem(func, list)
End

/// @brief Start the background timer for the inter trial interval (ITI)
///
/// Multi device variant
///
/// @param panelTitle device
/// @param runTime    left over time to wait in seconds
/// @param funcList   list of functions to execute at the end of the ITI
Function DQM_StartBackgroundTimer(panelTitle, runTime, funcList)
	string panelTitle, funcList
	variable runTime

	ASSERT(!isEmpty(funcList), "Empty funcList does not makse sense")

	variable startTime    = RelativeNowHighPrec()
	variable durationTime = runTime
	variable endTime      = startTime + durationTime

	DQM_MakeOrUpdateTimerParamWave(panelTitle, funcList, startTime, durationTime, endTime, 1)
	if(!IsBackgroundTaskRunning("ITC_TimerMD"))
		CtrlNamedBackground ITC_TimerMD, period = 6, proc = DQM_Timer, start
	endif
End

/// @brief Stop the background timer used for ITI tracking
Function DQM_StopBackgroundTimer(panelTitle)
	string panelTitle

	WAVE/SDFR=GetActiveITCDevicesTimerFolder() ActiveDevTimeParam

	DQM_MakeOrUpdateTimerParamWave(panelTitle, "", 0, 0, 0, -1)
	variable DevicesWithActiveTimers = DimSize(ActiveDevTimeParam, 0)
	if(DevicesWithActiveTimers == 0) // stops background timer if no more devices are in the parameter waves
		CtrlNamedBackground ITC_TimerMD, Stop
	endif
End

/// @brief Background function for tracking ITI
///
/// @ingroup BackgroundFunctions
Function DQM_Timer(s)
	STRUCT WMBackgroundStruct &s

	WAVE/SDFR=GetActiveITCDevicesTimerFolder() ActiveDevTimeParam
	// column 0 = ITCDeviceIDGlobal; column 1 = Start time; column 2 = run time; column 3 = end time
	WAVE/T/SDFR=GetActiveITCDevicesTimerFolder() TimerFunctionListWave
	// column 0 = panel title; column 1 = list of functions
	variable i
	string panelTitle
	variable TimeLeft

	for(i = 0; i < DimSize(ActiveDevTimeParam, ROWS); i += 1)
		ActiveDevTimeParam[i][4] = (RelativeNowHighPrec() - ActiveDevTimeParam[i][1])
		timeLeft = max(ActiveDevTimeParam[i][2] - ActiveDevTimeParam[i][4], 0)
		panelTitle = TimerFunctionListWave[i][0]

		SetValDisplay(panelTitle, "valdisp_DataAcq_ITICountdown", var = timeLeft)

		if(timeLeft == 0)
			ExecuteListOfFunctions(TimerFunctionListWave[i][1])
			DQM_MakeOrUpdateTimerParamWave(panelTitle, "", 0, 0, 0, -1)

			// restart iterating over the remaining devices
			i = 0
			continue
		endif
	endfor

	if(DimSize(ActiveDevTimeParam, ROWS) == 0)
		return 1
	endif

	return 0
End

static Function DQM_StartBckrdFIFOMonitor()
	CtrlNamedBackground ITC_FIFOMonitorMD, period = 5, proc = DQM_FIFOMonitor
	CtrlNamedBackground ITC_FIFOMonitorMD, start
End

static Function DQM_StopDataAcq(panelTitle, ITCDeviceIDGlobal)
	String panelTitle
	Variable ITCDeviceIDGlobal

	TFH_StopFIFODaemon(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)
	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, prepareForDAQ=1, zeroDAC = 1)

	SWS_SaveAndScaleITCData(panelTitle)
	if(RA_IsFirstSweep(panelTitle))
		if(GetCheckboxState(panelTitle, "Check_DataAcq1_RepeatAcq"))
			RA_YokedRAStartMD(panelTitle)
		else
			DAP_OneTimeCallAfterDAQ(panelTitle)
		endif
	else
		RA_YokedRABckgTPCallRACounter(panelTitle)
	endif
End

static Function DQM_BkrdDataAcq(panelTitle, [triggerMode])
	string panelTitle
	variable triggerMode

	if(ParamIsDefault(triggerMode))
		triggerMode = HARDWARE_DAC_DEFAULT_TRIGGER
	endif

	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	NVAR ADChannelToMonitor  = $GetADChannelToMonitor(panelTitle)
	NVAR ITCDeviceIDGlobal   = $GetITCDeviceIDGlobal(panelTitle)

	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)

	if(triggerMode == HARDWARE_DAC_DEFAULT_TRIGGER && GetCheckBoxState(panelTitle, "Check_DataAcq1_RepeatAcq"))
		DQ_StartITCDeviceTimer(panelTitle)
	endif

	HW_StartAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, triggerMode=triggerMode, flags=HARDWARE_ABORT_ON_ERROR)
	ED_MarkSweepStart(panelTitle)
	TFH_StartFIFOStopDaemon(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)

	DQM_MakeOrUpdateActivDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, 1) // adds a device

	if(!IsBackgroundTaskRunning("ITC_FIFOMonitorMD"))
		DQM_StartBckrdFIFOMonitor()
	endif
End

static Function DQM_MakeOrUpdateActivDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, addOrRemoveDevice)
	string panelTitle
	Variable ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, addOrRemoveDevice // when removing a device only the ITCDeviceIDGlobal is needed

	variable numberOfRows

	DFREF dfr = GetActiveITCDevicesFolder()
	WAVE/Z/SDFR=dfr ActiveDeviceList

	if(addOrRemoveDevice == 1) // add a ITC device
		if(!WaveExists(ActiveDeviceList))
			Make/N=(1, 4) dfr:ActiveDeviceList/WAVE=ActiveDeviceList
			ActiveDeviceList[0][0] = ITCDeviceIDGlobal
			ActiveDeviceList[0][1] = ADChannelToMonitor
			ActiveDeviceList[0][2] = StopCollectionPoint
		else
			numberOfRows = DimSize(ActiveDeviceList, ROWS)
			Redimension/N=(numberOfRows + 1, 4) ActiveDeviceList
			ActiveDeviceList[numberOfRows][0] = ITCDeviceIDGlobal
			ActiveDeviceList[numberOfRows][1] = ADChannelToMonitor
			ActiveDeviceList[numberOfRows][2] = StopCollectionPoint
		endif
	elseif(addOrRemoveDevice == -1) // remove a ITC device
		Duplicate /FREE /r = [][0] ActiveDeviceList ListOfITCDeviceIDGlobal // duplicates the column that contains the global device ID's
		FindValue/V=(ITCDeviceIDGlobal) ListOfITCDeviceIDGlobal
		ASSERT(V_Value >= 0, "Trying to remove a non existing device")
		DeletePoints/M=(ROWS) V_Value, 1, ActiveDeviceList
	else
		ASSERT(0, "Invalid addOrRemoveDevice value")
	endif
End

static Function DQM_MakeOrUpdateTimerParamWave(panelTitle, listOfFunctions, startTime, RunTime, EndTime, addOrRemoveDevice)
	string panelTitle, ListOfFunctions
	variable startTime, RunTime, EndTime, addOrRemoveDevice

	variable rowToRemove = NaN
	variable numberOfRows

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	DFREF dfr = GetActiveITCDevicesTimerFolder()

	WAVE/Z/SDFR=dfr ActiveDevTimeParam
	if(addOrRemoveDevice == 1) // add a ITC device
		if(!WaveExists(ActiveDevTimeParam))
			Make/N=(1, 5) dfr:ActiveDevTimeParam/Wave=ActiveDevTimeParam
			ActiveDevTimeParam[0][0] = ITCDeviceIDGlobal
			ActiveDevTimeParam[0][1] = startTime
			ActiveDevTimeParam[0][2] = RunTime
			ActiveDevTimeParam[0][3] = EndTime
			//ActiveDevTimeParam[0][4] = Elapsed time - calculated by background timer
		else
			numberOfRows = DimSize(ActiveDevTimeParam, ROWS)
			Redimension/N=(numberOfRows + 1, 5) ActiveDevTimeParam
			ActiveDevTimeParam[numberOfRows][0] = ITCDeviceIDGlobal
			ActiveDevTimeParam[numberOfRows][1] = startTime
			ActiveDevTimeParam[numberOfRows][2] = RunTime
			ActiveDevTimeParam[numberOfRows][3] = EndTime
			//ActiveDevTimeParam[0][4] = Elapsed time - calculated by background timer
		endif
	elseif(addOrRemoveDevice == -1) // remove a ITC device
		Duplicate/FREE/R=[][0] ActiveDevTimeParam ListOfITCDeviceIDGlobal
		FindValue/V=(ITCDeviceIDGlobal) ListOfITCDeviceIDGlobal
		rowToRemove = V_Value
		ASSERT(rowToRemove >= 0, "Trying to remove a non existing device")
		DeletePoints/M=(ROWS) rowToRemove, 1, ActiveDevTimeParam
	else
		ASSERT(0, "Invalid addOrRemoveDevice value")
	endif

	DQM_MakeOrUpdtDevTimerTxtWv(panelTitle, ListOfFunctions, rowToRemove, addOrRemoveDevice)

	WAVE/Z/SDFR=dfr ActiveDevTimeParam, TimerFunctionListWave
	ASSERT(WaveExists(ActiveDevTimeParam), "Missing wave ActiveDevTimeParam")
	ASSERT(WaveExists(TimerFunctionListWave), "Missing wave TimerFunctionListWave")
	ASSERT(DimSize(TimerFunctionListWave, ROWS) == DimSize(ActiveDevTimeParam, ROWS), "Number of rows in ActiveDevTimeParam and TimerFunctionListWave must be equal")
End

static Function DQM_MakeOrUpdtDevTimerTxtWv(panelTitle, listOfFunctions, rowToRemove, addOrRemoveDevice)
	string panelTitle, listOfFunctions
	variable rowToRemove, addOrRemoveDevice

	variable numberOfRows

	DFREF dfr = GetActiveITCDevicesTimerFolder()
	WAVE/Z/T/SDFR=dfr TimerFunctionListWave

	if(addOrRemoveDevice == 1) // Add a device
		if(!WaveExists(TimerFunctionListWave))
			Make/T/N=(1, 2) dfr:TimerFunctionListWave/Wave=TimerFunctionListWave
			TimerFunctionListWave[0][0] = panelTitle
			TimerFunctionListWave[0][1] = listOfFunctions
		else
			numberOfRows = DimSize(TimerFunctionListWave, ROWS)
			Redimension/N=(numberOfRows + 1, 2) TimerFunctionListWave
			TimerFunctionListWave[numberOfRows][0] = panelTitle
			TimerFunctionListWave[numberOfRows][1] = listOfFunctions
		endif
	elseif(addOrRemoveDevice == -1) // remove a device
		ASSERT(rowToRemove >= 0 && rowToRemove < DimSize(TimerFunctionListWave, ROWS), "Trying to remove a non existing index")
		DeletePoints/M=(ROWS) rowToRemove, 1, TimerFunctionListWave
	else
		ASSERT(0, "Invalid addOrRemoveDevice value")
	endif
End
