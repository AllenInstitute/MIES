#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_TP_MD
#endif

/// @file MIES_TestPulse_Multi.ipf
/// @brief __TPM__ Multi device background test pulse functionality

/// @brief Start the test pulse when MD support is activated.
///
/// Handles the TP initiation for all ITC devices. Yoked ITC1600s are handled specially using the external trigger.
/// The external trigger is assumed to be a arduino device using the arduino squencer.
Function TPM_StartTPMultiDeviceLow(panelTitle, [runModifier])
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
			TPM_BkrdTPMD(panelTitle)
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
	TPM_BkrdTPMD(panelTitle, triggerMode=HARDWARE_DAC_EXTERNAL_TRIGGER)

	// set followers in wait for trigger
	for(i = 0; i < numFollower; i += 1)
		followerPanelTitle = StringFromList(i, listOfFollowerDevices)
		TPM_BkrdTPMD(followerPanelTitle, triggerMode=HARDWARE_DAC_EXTERNAL_TRIGGER)
	endfor

	// trigger
	ARDStartSequence()
End

/// @brief Start a multi device test pulse, always done in background mode
Function TPM_StartTestPulseMultiDevice(panelTitle)
	string panelTitle

	AbortOnValue DAP_CheckSettings(panelTitle, TEST_PULSE_MODE),1

	DQ_StopOngoingDAQ(panelTitle)

	// stop early as "TP after DAQ" might be already running
	if(TP_CheckIfTestpulseIsRunning(panelTitle))
		return NaN
	endif

	TPM_StartTPMultiDeviceLow(panelTitle)


	P_InitBeforeTP(panelTitle)
End

/// @brief Stop the TP on yoked devices simultaneously
///
/// Handles also non-yoked devices in multi device mode correctly.
Function TPM_StopTestPulseMultiDevice(panelTitle)
	string panelTitle

	DQM_CallFuncForDevicesYoked(panelTitle, TPM_StopTPMD)
End

static Function TPM_BkrdTPMD(panelTitle, [triggerMode])
	string panelTitle
	variable triggerMode

	if(ParamIsDefault(triggerMode))
		triggerMode = HARDWARE_DAC_DEFAULT_TRIGGER
	endif

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	TPM_AddDevice(panelTitle)

	HW_ITC_ResetFifo(ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_StartAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, triggerMode=triggerMode, flags=HARDWARE_ABORT_ON_ERROR)
	TFH_StartFIFOResetDeamon(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, triggerMode)

	if(!IsBackgroundTaskRunning("TestPulseMD"))
		CtrlNamedBackground TestPulseMD, period = 5, proc = TPM_BkrdTPFuncMD
		CtrlNamedBackground TestPulseMD, start
	endif
End

/// @brief Background TP Multi Device
///
/// @ingroup BackgroundFunctions
Function TPM_BkrdTPFuncMD(s)
	STRUCT BackgroundStruct &s

	variable i, deviceID
	variable pointsCompletedInITCDataWave, activeChunk
	string panelTitle

	WAVE ActiveDeviceList = GetActiveDevicesTPMD()

	if(s.wmbs.started)
		s.wmbs.started    = 0
		s.count           = 0
		s.threadDeadCount = 0
	else
		s.count += 1
	endif

	// works through list of active devices
	// update parameters for a particular active device
	for(i = 0; i < GetNumberFromWaveNote(ActiveDeviceList, NOTE_INDEX); i += 1)
		deviceID = ActiveDeviceList[i][%DeviceID]
		panelTitle = HW_GetMainDeviceName(HARDWARE_ITC_DAC, deviceID)

		WAVE ITCDataWave = GetITCDataWave(panelTitle)

		NVAR tgID = $GetThreadGroupIDFIFO(panelTitle)
		WAVE/Z result = TS_GetNewestFromThreadQueueMult(tgID, {"fifoPos", "startSequence"})

		// should never be hit
		if(!WaveExists(result))
			if(s.threadDeadCount < TP_MD_THREAD_DEAD_MAX_RETRIES)
				s.threadDeadCount += 1
				printf "Retrying getting data from thread, keep fingers crossed (%d/%d)\r", s.threadDeadCount, TP_MD_THREAD_DEAD_MAX_RETRIES
				ControlWindowToFront()
				continue
			endif

			// give up
			TPM_StopTestPulseMultiDevice(panelTitle)
			return 0
		endif

		s.threadDeadCount = 0

		if(IsFinite(result[%startSequence]))
			ARDStartSequence()
		endif

		if(!IsFinite(result[%fifoPos]))
			continue
		endif

		pointsCompletedInITCDataWave = mod(result[%fifoPos], DimSize(ITCDataWave, ROWS))

		// extract the last fully completed chunk
		activeChunk = floor(pointsCompletedInITCDataWave / TP_GetTestPulseLengthInPoints(panelTitle)) - 1

		// Ensures that the new TP chunk isn't the same as the last one.
		// This is required to keep the TP buffer in sync.
		if(activeChunk >= 0 && activeChunk != ActiveDeviceList[i][%ActiveChunk])
			SCOPE_UpdateOscilloscopeData(panelTitle, TEST_PULSE_MODE, chunk=activeChunk)
			TP_Delta(panelTitle)
			ActiveDeviceList[i][%ActiveChunk] = activeChunk
		endif

		if(mod(s.count, TEST_PULSE_LIVE_UPDATE_INTERVAL) == 0)
			SCOPE_UpdateGraph(panelTitle)
		endif

		if(GetKeyState(0) & ESCAPE_KEY)
			DQ_StopOngoingDAQ(panelTitle)
			return 1
		endif
	endfor

	return 0
End

static Function TPM_StopTPMD(panelTitle)
	string panelTitle

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	TFH_StopFifoDaemon(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)

	// makes sure the device being stopped is actually running
	if(!HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags = HARDWARE_PREVENT_ERROR_MESSAGE | HARDWARE_PREVENT_ERROR_POPUP) \
	   && HW_IsRunning(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags = HARDWARE_ABORT_ON_ERROR))
		HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, zeroDAC = 1)

		TPM_RemoveDevice(panelTitle)
		if(!TPM_HasActiveDevices())
			CtrlNamedBackground TestPulseMD, stop
		endif

		TP_Teardown(panelTitle)
	endif
End

static Function TPM_HasActiveDevices()
	WAVE ActiveDevicesTPMD = GetActiveDevicesTPMD()

	return GetNumberFromWaveNote(ActiveDevicesTPMD, NOTE_INDEX) > 0
End

static Function TPM_RemoveDevice(panelTitle)
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

static Function TPM_AddDevice(panelTitle)
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
