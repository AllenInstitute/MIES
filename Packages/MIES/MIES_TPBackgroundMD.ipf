#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_ITC_BKG
#endif

/// @file MIES_TPBackgroundMD.ipf
/// @brief __ITC__ Multi device background test pulse functionality

/// @brief Start the test pulse when MD support is activated.
///
/// Handles the TP initiation for all ITC devices. Yoked ITC1600s are handled specially using the external trigger.
/// The external trigger is assumed to be a arduino device using the arduino squencer.
Function ITC_StartTestPulseMultiDevice(panelTitle, [runModifier])
	string panelTitle
	variable runModifier

	variable i, TriggerMode
	variable runMode, numFollower
	string followerPanelTitle

	runMode = TEST_PULSE_BG_MULTI_DEVICE

	if(!ParamIsDefault(runModifier))
		runMode = runMode | runModifier
	endif

	if(!DeviceHasFollower(panelTitle))
		try
			TP_Setup(panelTitle, runMode)
			ITC_BkrdTPMD(panelTitle)
		catch
			TP_Teardown(panelTitle)
		endtry

		return NaN
	endif

	SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)
	numFollower = ItemsInList(listOfFollowerDevices)

	try
		// configure all followers
		for(i = 0; i < numFollower; i += 1)
			followerPanelTitle = StringFromList(i, listOfFollowerDevices)
			TP_Setup(followerPanelTitle, runMode)
		endfor

		TP_Setup(panelTitle, runMode)
	catch
		// deconfigure all followers
		for(i = 0; i < numFollower; i += 1)
			followerPanelTitle = StringFromList(i, listOfFollowerDevices)
			TP_Teardown(followerPanelTitle)
		endfor

		// deconfigure leader
		TP_Teardown(panelTitle)
		return NaN
	endtry

	// Sets lead board in wait for trigger
	ITC_BkrdTPMD(panelTitle, triggerMode=HARDWARE_DAC_EXTERNAL_TRIGGER)

	// set followers in wait for trigger
	for(i = 0; i < numFollower; i += 1)
		followerPanelTitle = StringFromList(i, listOfFollowerDevices)
		ITC_BkrdTPMD(followerPanelTitle, triggerMode=HARDWARE_DAC_EXTERNAL_TRIGGER)
	endfor

	// trigger
	ARDStartSequence()
End

static Function ITC_BkrdTPMD(panelTitle, [triggerMode])
	string panelTitle
	variable triggerMode

	if(ParamIsDefault(triggerMode))
		triggerMode = HARDWARE_DAC_DEFAULT_TRIGGER
	endif

	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	NVAR ADChannelToMonitor  = $GetADChannelToMonitor(panelTitle)
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	ITC_AddDevice(panelTitle)

	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_ITC_ResetFifo(ITCDeviceIDGlobal)
	HW_StartAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, triggerMode=triggerMode, flags=HARDWARE_ABORT_ON_ERROR)
	TFH_StartFIFOResetDeamon(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)

	if(!IsBackgroundTaskRunning("TestPulseMD"))
		CtrlNamedBackground TestPulseMD, period = 1, proc = ITC_BkrdTPFuncMD
		CtrlNamedBackground TestPulseMD, start
	endif
End

Function ITC_BkrdTPFuncMD(s)
	STRUCT BackgroundStruct &s

	variable i, deviceID, fifoPos
	variable pointsCompletedInITCDataWave, activeChunk
	string panelTitle

	WAVE ActiveDeviceList = GetActiveDevicesTPMD()

	if(s.wmbs.started)
		s.wmbs.started = 0
		s.count  = 0
	else
		s.count += 1
	endif

	// works through list of active devices
	// update parameters for a particular active device
	for(i = 0; i < GetNumberFromWaveNote(ActiveDeviceList, NOTE_INDEX); i += 1)
		deviceID = ActiveDeviceList[i][%DeviceID]
		panelTitle = HW_GetMainDeviceName(HARDWARE_ITC_DAC, deviceID)

		WAVE ITCDataWave                  = GetITCDataWave(panelTitle)
		NVAR stopCollectionPoint          = $GetStopCollectionPoint(panelTitle)
		NVAR ADChannelToMonitor           = $GetADChannelToMonitor(panelTitle)

		NVAR tgID = $GetThreadGroupIDFIFO(panelTitle)
		fifoPos = TS_GetNewestFromThreadQueue(tgID, "fifoPos")
		pointsCompletedInITCDataWave = mod(fifoPos, DimSize(ITCDataWave, ROWS))

		// don't extract the last chunk for plotting
		activeChunk = max(0, floor(pointsCompletedInITCDataWave / TP_GetTestPulseLengthInPoints(panelTitle, REAL_SAMPLING_INTERVAL_TYPE)) - 1)

		// Ensures that the new TP chunk isn't the same as the last one.
		// This is required to keep the TP buffer in sync.
		if(activeChunk != ActiveDeviceList[i][%ActiveChunk])
			DM_UpdateOscilloscopeData(panelTitle, TEST_PULSE_MODE, chunk=activeChunk)
			TP_Delta(panelTitle)
			ActiveDeviceList[i][%ActiveChunk] = activeChunk
		endif

		if(mod(s.count, TEST_PULSE_LIVE_UPDATE_INTERVAL) == 0)
			SCOPE_UpdateGraph(panelTitle)
		endif

		if(RA_IsFirstSweep(panelTitle))
			if(GetKeyState(0) & ESCAPE_KEY)
				// only stop the currently active device
				if(!cmpstr(panelTitle,GetMainWindow(GetCurrentWindow())))
					beep 
					ITC_StopTestPulseMultiDevice(panelTitle)
				endif
			endif
		endif
	endfor

	return 0
End

/// @brief Stop the TP on yoked devices simultaneously
///
/// Handles also non-yoked devices in multi device mode correctly.
Function ITC_StopTestPulseMultiDevice(panelTitle)
	string panelTitle

	ITC_CallFuncForDevicesMDYoked(panelTitle, ITC_StopTPMD)
End

static Function ITC_StopTPMD(panelTitle)
	string panelTitle

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	TFH_StopFifoDaemon(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)
	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)

	if(HW_IsRunning(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)) // makes sure the device being stopped is actually running
		HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)

		ITC_RemoveDevice(panelTitle)
		ITC_ZeroITCOnActiveChan(panelTitle) // zeroes the active DA channels - makes sure the DA isn't left in the TP up state.
		if(!ITC_HasActiveDevices())
			CtrlNamedBackground TestPulseMD, stop
			print "Stopping test pulse on:", panelTitle, "In ITC_StopTPMD"
		endif

		TP_Teardown(panelTitle)
	endif
End

static Function ITC_HasActiveDevices()
	WAVE ActiveDevicesTPMD = GetActiveDevicesTPMD()

	return GetNumberFromWaveNote(ActiveDevicesTPMD, NOTE_INDEX) > 0
End

static Function ITC_RemoveDevice(panelTitle)
	string panelTitle

	variable idx
	string msg

	WAVE ActiveDevicesTPMD = GetActiveDevicesTPMD()
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	idx = GetNumberFromWaveNote(ActiveDevicesTPMD, NOTE_INDEX) - 1
	ASSERT(idx >= 0, "Invalid index")

	Duplicate/FREE/R=[0, idx][0] ActiveDevicesTPMD, deviceIDs
	FindValue/V=(ITCDeviceIDGlobal) deviceIDs
	ASSERT(V_Value != -1, "Could not find the device")

	// overwrite the to be removed device with the last one
	ActiveDevicesTPMD[V_Value][] = ActiveDevicesTPMD[idx][q]
	ActiveDevicesTPMD[idx][]     = NaN

	SetNumberInWaveNote(ActiveDevicesTPMD, NOTE_INDEX, idx)

	sprintf msg, "Remove device %s in row %d", panelTitle, V_Value
	DEBUGPRINT(msg)
End

static Function ITC_AddDevice(panelTitle)
	string panelTitle

	variable idx
	string msg

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	WAVE ActiveDevicesTPMD = GetActiveDevicesTPMD()

	idx = GetNumberFromWaveNote(ActiveDevicesTPMD, NOTE_INDEX)
	EnsureLargeEnoughWave(ActiveDevicesTPMD, minimumSize=idx + 1)

	ActiveDevicesTPMD[idx][%DeviceID]    = ITCDeviceIDGlobal
	ActiveDevicesTPMD[idx][%activeChunk] = NaN

	SetNumberInWaveNote(ActiveDevicesTPMD, NOTE_INDEX, idx + 1)

	sprintf msg, "Adding device %s with deviceID %d in row %d", panelTitle, ITCDeviceIDGlobal, idx
	DEBUGPRINT(msg)
End
