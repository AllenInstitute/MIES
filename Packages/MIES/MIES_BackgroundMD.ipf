#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_ITC_MD
#endif

/// @file MIES_BackgroundMD.ipf
/// @brief __ITC__ Multi device background data acquisition

//Reinitialize Device 1 with intrabox clock
// Execute "ITCInitialize /M = 1"
// Execute "ITCStartAcq 1, 256"

/// @brief Handles function calls for data acquistion. These include calls for starting Yoked ITC1600s.
///
/// Handles the calls to the data configurator (DC) functions and BackgroundMD
/// it is required because of the special handling syncronous ITC1600s require
///
/// @param panelTitle      device
/// @param initialSetupReq [optional, defaults to true] performs initialization routines
///                        at the very beginning of DAQ, turn off for RA
Function ITC_StartDAQMultiDeviceLowLevel(panelTitle, [initialSetupReq])
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
			ITC_StopITCDeviceTimer(panelTitle)
		endif

		return NaN
	endtry

	// configure passed device
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_ITC_PrepareAcq(ITCDeviceIDGlobal)

	if(!DeviceHasFollower(panelTitle))
		ITC_BkrdDataAcqMD(panelTitle)
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
			ITC_StopITCDeviceTimer(panelTitle)
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
	ITC_BkrdDataAcqMD(panelTitle, triggerMode=HARDWARE_DAC_EXTERNAL_TRIGGER)

	// start follower devices
	for(i = 0; i < numFollower; i += 1)
		followerPanelTitle = StringFromList(i, listOfFollowerDevices)
		ITC_BkrdDataAcqMD(followerPanelTitle, triggerMode=HARDWARE_DAC_EXTERNAL_TRIGGER)
	endfor

	if(GetCheckBoxState(panelTitle, "Check_DataAcq1_RepeatAcq"))
		ITC_StartITCDeviceTimer(panelTitle)
	endif

	// trigger
	ARDStartSequence()
End

static Function ITC_BkrdDataAcqMD(panelTitle, [triggerMode])
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
		ITC_StartITCDeviceTimer(panelTitle)
	endif

	HW_StartAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, triggerMode=triggerMode, flags=HARDWARE_ABORT_ON_ERROR)
	TFH_StartFIFOStopDaemon(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)

	ITC_MakeOrUpdateActivDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, 1) // adds a device

	if(!IsBackgroundTaskRunning("ITC_FIFOMonitorMD"))
		ITC_StartBckrdFIFOMonitorMD()
	endif
End

Function ITC_StartBckrdFIFOMonitorMD()
	CtrlNamedBackground ITC_FIFOMonitorMD, period = 5, proc = ITC_FIFOMonitorMD
	CtrlNamedBackground ITC_FIFOMonitorMD, start
End
 
Function ITC_FIFOMonitorMD(s)
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
			ITC_MakeOrUpdateActivDevLstWave(panelTitle, deviceID, 0, 0, -1)
			ITC_StopDataAcqMD(panelTitle, deviceID)
			i = 0
			continue
		endif
	endfor

	if(DimSize(ActiveDeviceList, ROWS) == 0)
		return 1
	endif

	return 0
End

static Function ITC_StopDataAcqMD(panelTitle, ITCDeviceIDGlobal)
	String panelTitle
	Variable ITCDeviceIDGlobal

	TFH_StopFIFODaemon(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)
	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, prepareForDAQ=1)

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
END

/// @brief Stop ongoing multi device DAQ
///
/// Follower handling for yoked devices is done by the caller.
static Function ITC_TerminateOngoingDAQMDHelper(panelTitle)
	String panelTitle

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	WAVE/T/SDFR=GetActiveITCDevicesFolder() ActiveDeviceList

	TFH_StopFIFODaemon(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)
	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, zeroDAC = 1)

	// remove device passed in from active device lists
	ITC_MakeOrUpdateActivDevLstWave(panelTitle, ITCDeviceIDGlobal, 0, 0, -1)

	// determine if device removed was the last device on the list, if yes stop the background function
	if(DimSize(ActiveDeviceList, ROWS) == 0)
		CtrlNamedBackground ITC_FIFOMonitorMD, stop
	endif
END

/// @brief Stop the DAQ on yoked devices simultaneously
///
/// Handles also non-yoked devices in multi device mode correctly.
Function ITC_StopOngoingDAQMultiDevice(panelTitle)
	string panelTitle

	ITC_CallFuncForDevicesMDYoked(panelTitle, ITC_StopOngoingDAQMDHelper)
End

static Function ITC_StopOngoingDAQMDHelper(panelTitle)
	string panelTitle

	variable needsOTCAfterDAQ = 0
	variable discardData      = 0

	if(IsDeviceActiveWithBGTask(panelTitle, "TestPulseMD"))
		ITC_StopTestPulseMultiDevice(panelTitle)

		needsOTCAfterDAQ = needsOTCAfterDAQ | 0
		discardData      = discardData      | 1
	endif

	if(IsDeviceActiveWithBGTask(panelTitle, "ITC_TimerMD"))
		ITC_StopTimerForDeviceMD(panelTitle)

		/// @todo why needs that to be different than for single device
		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
		discardData      = discardData      | 1
	endif

	if(IsDeviceActiveWithBGTask(panelTitle, "ITC_FIFOMonitorMD"))
		ITC_TerminateOngoingDAQMDHelper(panelTitle)
		ITC_StopITCDeviceTimer(panelTitle)

		if(!discardData)
			SWS_SaveAndScaleITCData(panelTitle, forcedStop = 1)
		endif

		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
	endif

	NVAR dataAcqRunMode = $GetDataAcqRunMode(panelTitle)

	if(dataAcqRunMode != DAQ_NOT_RUNNING)
		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
	endif

	if(needsOTCAfterDAQ)
		DAP_OneTimeCallAfterDAQ(panelTitle, forcedStop = 1)
	endif
End

static Function ITC_MakeOrUpdateActivDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, addOrRemoveDevice)
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

/// @brief Call a function for a device and if this device is a leader with followers
/// for all follower too.
///
/// Handles also non-yoked devices in multi device mode correctly.
Function ITC_CallFuncForDevicesMDYoked(panelTitle, func)
	string panelTitle
	FUNCREF CALL_FUNCTION_LIST_PROTOTYPE func

	string list = GetListofLeaderAndPossFollower(panelTitle)
	CallFunctionForEachListItem(func, list)
End
