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
		TP_Setup(panelTitle, runMode)
		ITC_BkrdTPMD(panelTitle)
		return NaN
	endif

	SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)
	numFollower = ItemsInList(listOfFollowerDevices)

	// configure all followers
	for(i = 0; i < numFollower; i += 1)
		followerPanelTitle = StringFromList(i, listOfFollowerDevices)
		TP_Setup(followerPanelTitle, runMode)
	endfor

	// Sets lead board in wait for trigger
	TP_Setup(panelTitle, runMode)
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

	ITC_MakeOrUpdateTPDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, 1)

	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_ITC_ResetFifo(ITCDeviceIDGlobal)
	HW_StartAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, triggerMode=triggerMode, flags=HARDWARE_ABORT_ON_ERROR)
	TFM_StartFIFOResetDeamon(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)

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

	WAVE/SDFR=GetActITCDevicesTestPulseFolder() ActiveDeviceList

	if(s.wmbs.started)
		s.wmbs.started = 0
		s.count  = 0
	else
		s.count += 1
	endif

	// works through list of active devices
	// update parameters for a particular active device
	// ActiveDeviceList size might change inside the loop so we can
	// *not* precompute it.
	for(i = 0; i < DimSize(ActiveDeviceList, ROWS); i += 1)
		deviceID = ActiveDeviceList[i][0]
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
		if(activeChunk != ActiveDeviceList[i][4])
			DM_UpdateOscilloscopeData(panelTitle, TEST_PULSE_MODE, chunk=activeChunk)
			TP_Delta(panelTitle)
			ActiveDeviceList[i][4] = activeChunk
		endif

		// sometimes when moving around panels in Igor the ITC18USB locks up and returns
		// a negative value for the FIFO advance
		if(!DeviceCanLead(panelTitle))
			// checks to see if the hardware buffer is at max capacity
			if(fifoPos > 0 && abs(fifoPos - ActiveDeviceList[i][5]) <= 1)
				if(ActiveDeviceList[i][3] > NUM_CONSEC_FIFO_STILLSTANDS)
					TFM_StopFifoResetDaemon(HARDWARE_ITC_DAC, deviceID)
					HW_StopAcq(HARDWARE_ITC_DAC, deviceID, flags=HARDWARE_PREVENT_ERROR_POPUP)

					HW_ITC_PrepareAcq(deviceID, flags=HARDWARE_PREVENT_ERROR_POPUP)
					HW_StartAcq(HARDWARE_ITC_DAC, deviceID, flags=HARDWARE_ABORT_ON_ERROR)
					printf "Device %s restarted\r", panelTitle
					TFM_StartFIFOResetDeamon(HARDWARE_ITC_DAC, deviceID)
					ActiveDeviceList[i][3] = 0
				else
				ActiveDeviceList[i][3] += 1
				endif
			else
				ActiveDeviceList[i][3] = 0
			endif
		endif

		ActiveDeviceList[i][5] = fifoPos

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

	DFREF dfr = GetActITCDevicesTestPulseFolder()
	WAVE/T/SDFR=dfr ActiveDeviceList
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	TFM_StopFifoResetDaemon(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)
	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)

	if(HW_IsRunning(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)) // makes sure the device being stopped is actually running
		HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)

		ITC_MakeOrUpdateTPDevLstWave(panelTitle, ITCDeviceIDGlobal, 0, 0, -1)
		ITC_ZeroITCOnActiveChan(panelTitle) // zeroes the active DA channels - makes sure the DA isn't left in the TP up state.
		if (dimsize(ActiveDeviceList, 0) == 0)
			CtrlNamedBackground TestPulseMD, stop
			print "Stopping test pulse on:", panelTitle, "In ITC_StopTPMD"
		endif

		TP_Teardown(panelTitle)
	endif
End

static Function ITC_MakeOrUpdateTPDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, addOrRemoveDevice)
	string panelTitle
	variable ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, addOrRemoveDevice

	variable numberOfRows

	DFREF dfr = GetActITCDevicesTestPulseFolder()
	WAVE/Z/SDFR=dfr ActiveDeviceList

	if(addOrRemoveDevice == 1) // add a ITC device
		if(!WaveExists(ActiveDeviceList))
			Make/N=(1, 6) dfr:ActiveDeviceList/Wave=ActiveDeviceList
			ActiveDeviceList[0][0] = ITCDeviceIDGlobal
			ActiveDeviceList[0][1] = ADChannelToMonitor
			ActiveDeviceList[0][2] = StopCollectionPoint
			ActiveDeviceList[0][3] = 0 // number of consecutive loop iterations with stuck FIFO
			ActiveDeviceList[0][4] = NaN // Active chunk of the ITCDataWave
			ActiveDeviceList[0][5] = 0 // FIFO position
		else
			numberOfRows = DimSize(ActiveDeviceList, ROWS)
			Redimension/N=(numberOfRows + 1, 6) ActiveDeviceList
			ActiveDeviceList[numberOfRows][0] = ITCDeviceIDGlobal
			ActiveDeviceList[numberOfRows][1] = ADChannelToMonitor
			ActiveDeviceList[numberOfRows][2] = StopCollectionPoint
			ActiveDeviceList[numberOfRows][3] = 0
			ActiveDeviceList[numberOfRows][4] = NaN
			ActiveDeviceList[numberOfRows][5] = 0
		endif
	elseif(addOrRemoveDevice == -1) // remove a ITC device
		Duplicate/FREE/R=[][0] ActiveDeviceList ListOfITCDeviceIDGlobal
		FindValue/V=(ITCDeviceIDGlobal) ListOfITCDeviceIDGlobal
		ASSERT(V_Value >= 0, "Trying to remove a non existing device")
		DeletePoints/m=(ROWS) V_Value, 1, ActiveDeviceList
	else
		ASSERT(0, "Invalid addOrRemoveDevice value")
	endif
End
