#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_BackgroundMD.ipf
/// @brief __ITC__ Multi device background data acquisition

//Reinitialize Device 1 with intrabox clock
// Execute "ITCInitialize /M = 1"
// Execute "ITCStartAcq 1, 256"

/// @brief Handles function calls for data acquistion. These include calls for starting Yoked ITC1600s.
///
/// Handles the calls to the data configurator (DC) functions and BackgroundMD
/// it is required because of the special handling syncronous ITC1600s require
Function ITC_StartDAQMultiDeviceLowLevel(panelTitle)
	string panelTitle

	variable numFollower, i
	string followerPanelTitle

	// configure passed device
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	DC_ConfigureDataForITC(panelTitle, DATA_ACQUISITION_MODE)
	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_ITC_PrepareAcq(ITCDeviceIDGlobal)

	if(!DeviceHasFollower(panelTitle))
		ITC_BkrdDataAcqMD(panelTitle)
		return NaN
	endif

	SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)
	numFollower = ItemsInList(listOfFollowerDevices)

	// configure follower devices
	for(i = 0; i < numFollower; i += 1)
		followerPanelTitle = StringFromList(i, listOfFollowerDevices)
		DC_ConfigureDataForITC(followerPanelTitle, DATA_ACQUISITION_MODE)
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

	ITC_MakeOrUpdateActivDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, 1) // adds a device

	if(!IsBackgroundTaskRunning("ITC_FIFOMonitorMD"))
		ITC_StartBckrdFIFOMonitorMD()
	endif
End

Function ITC_StartBckrdFIFOMonitorMD()
	CtrlNamedBackground ITC_FIFOMonitorMD, period = 1, proc = ITC_FIFOMonitorMD
	CtrlNamedBackground ITC_FIFOMonitorMD, start
End
 
Function ITC_FIFOMonitorMD(s)
	STRUCT WMBackgroundStruct &s

	DFREF activeDevices = GetActiveITCDevicesFolder()
	WAVE/SDFR=activeDevices ActiveDeviceList
	variable deviceID, moreData
	variable i, fifoPos
	string panelTitle

	for(i = 0; i < DimSize(ActiveDeviceList, ROWS); i += 1)
		deviceID   = ActiveDeviceList[i][0]
		panelTitle = HW_GetMainDeviceName(HARDWARE_ITC_DAC, deviceID)

		HW_SelectDevice(HARDWARE_ITC_DAC, deviceID, flags=HARDWARE_ABORT_ON_ERROR)
		moreData = HW_ITC_MoreData(deviceID, fifoPos=fifoPos)

		DM_UpdateOscilloscopeData(panelTitle, DATA_ACQUISITION_MODE, fifoPos=fifoPos)
		DM_CallAnalysisFunctions(panelTitle, MID_SWEEP_EVENT)

		if(!moreData)
			print "stopped data acq on " + panelTitle, "device ID global = ", deviceID
			ITC_MakeOrUpdateActivDevLstWave(panelTitle, deviceID, 0, 0, -1)
			ITC_StopDataAcqMD(panelTitle, deviceID)
			i = 0
			continue
		endif
	endfor

	if(DimSize(ActiveDeviceList, ROWS) == 0)
		print "no more active devices, stopping named background"
		return 1
	endif

	return 0
End

static Function ITC_StopDataAcqMD(panelTitle, ITCDeviceIDGlobal)
	String panelTitle
	Variable ITCDeviceIDGlobal

	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, prepareForDAQ=1)

	DM_SaveAndScaleITCData(panelTitle)
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

	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)
	
	ITC_ZeroITCOnActiveChan(panelTitle)
	
	// remove device passed in from active device lists
	ITC_MakeOrUpdateActivDevLstWave(panelTitle, ITCDeviceIDGlobal, 0, 0, -1)

	// determine if device removed was the last device on the list, if yes stop the background function
	if(DimSize(ActiveDeviceList, ROWS) == 0)
		print "no more active devices, stopping named background"
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

		if(!discardData)
			DM_SaveAndScaleITCData(panelTitle)
		endif

		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
	endif

	if(needsOTCAfterDAQ)
		DAP_OneTimeCallAfterDAQ(panelTitle)
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
