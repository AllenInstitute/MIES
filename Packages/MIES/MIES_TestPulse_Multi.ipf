#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_TP_MD
#endif

/// @brief After this time in s the background task reading data from the ADC device
/// @brief will not read multiple TP data sets subsequently to keep up if late
/// @brief it will however still update once per device
/// @brief so the gui thread can update at least every ~0.5 seconds (default value here)
/// @brief however the fifo may run full if the timeout is hit too often
static Constant TPM_NI_TASKTIMEOUT = 0.5
static Constant TPM_NI_FIFO_THRESHOLD_SIZE = 1073741824

/// @file MIES_TestPulse_Multi.ipf
/// @brief __TPM__ Multi device background test pulse functionality

/// @brief Start the test pulse when MD support is activated.
///
/// Handles the TP initiation for all DAQ devices. Yoked ITC1600s are handled specially using the external trigger.
/// The external trigger is assumed to be a arduino device using the arduino squencer.
Function TPM_StartTPMultiDeviceLow(device, [runModifier, fast])
	string device
	variable runModifier
	variable fast

	if(ParamIsDefault(fast))
		fast = 0
	else
		fast = !!fast
	endif

	variable i, TriggerMode
	variable runMode, numFollower
	string followerDevice

	runMode = TEST_PULSE_BG_MULTI_DEVICE

	if(!ParamIsDefault(runModifier))
		runMode = runMode | runModifier
	endif

	if(!DeviceHasFollower(device))
		AssertOnAndClearRTError()
		try
			TP_Setup(device, runMode, fast = fast)
			TPM_BkrdTPMD(device)
		catch
			ClearRTError()
			TP_Teardown(device)
		endtry

		return NaN
	else
		ASSERT(!fast, "fast mode does not work with yoking")
	endif

	SVAR listOfFollowerDevices = $GetFollowerList(device)
	numFollower = ItemsInList(listOfFollowerDevices)

	AssertOnAndClearRTError()
	try
		// configure all followers
		for(i = 0; i < numFollower; i += 1)
			followerDevice = StringFromList(i, listOfFollowerDevices)
			TP_Setup(followerDevice, runMode)
		endfor

		TP_Setup(device, runMode)
	catch
		ClearRTError()
		// deconfigure all followers
		for(i = 0; i < numFollower; i += 1)
			followerDevice = StringFromList(i, listOfFollowerDevices)
			TP_Teardown(followerDevice)
		endfor

		// deconfigure leader
		TP_Teardown(device)
		return NaN
	endtry

	// Sets lead board in wait for trigger
	TPM_BkrdTPMD(device, triggerMode=HARDWARE_DAC_EXTERNAL_TRIGGER)

	// set followers in wait for trigger
	for(i = 0; i < numFollower; i += 1)
		followerDevice = StringFromList(i, listOfFollowerDevices)
		TPM_BkrdTPMD(followerDevice, triggerMode=HARDWARE_DAC_EXTERNAL_TRIGGER)
	endfor

	// trigger
	ARDStartSequence()
End

/// @brief Start a multi device test pulse, always done in background mode
Function TPM_StartTestPulseMultiDevice(device, [fast])
	string device
	variable fast

	if(ParamIsDefault(fast))
		fast = 0
	else
		fast = !!fast
	endif

	if(fast)
		TPM_StartTPMultiDeviceLow(device, fast = 1)
		return NaN
	endif

	AbortOnValue DAP_CheckSettings(device, TEST_PULSE_MODE),1

	DQ_StopOngoingDAQ(device, DQ_STOP_REASON_TP_STARTED)

	// stop early as "TP after DAQ" might be already running
	if(TP_CheckIfTestpulseIsRunning(device))
		return NaN
	endif

	TPM_StartTPMultiDeviceLow(device)
	P_InitBeforeTP(device)
End

/// @brief Stop the TP on yoked devices simultaneously
///
/// Handles also non-yoked devices in multi device mode correctly.
Function TPM_StopTestPulseMultiDevice(device, [fast])
	string device
	variable fast

	if(ParamIsDefault(fast))
		fast = 0
	else
		fast = !!fast
	endif

	if(fast)
		DQM_CallFuncForDevicesYoked(device, TPM_StopTPMDFast)
	else
		DQM_CallFuncForDevicesYoked(device, TPM_StopTPMD)
	endif
End

static Function TPM_BkrdTPMD(device, [triggerMode])
	string device
	variable triggerMode

	variable hardwareType = GetHardwareType(device)

	if(ParamIsDefault(triggerMode))
		triggerMode = HARDWARE_DAC_DEFAULT_TRIGGER
	endif

	NVAR deviceID = $GetDAQDeviceID(device)

	TPM_AddDevice(device)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			HW_ITC_ResetFifo(deviceID, flags=HARDWARE_ABORT_ON_ERROR)
			HW_StartAcq(HARDWARE_ITC_DAC, deviceID, triggerMode=triggerMode, flags=HARDWARE_ABORT_ON_ERROR)
			TFH_StartFIFOResetDeamon(HARDWARE_ITC_DAC, deviceID, triggerMode)
			break
		case HARDWARE_NI_DAC:
			HW_StartAcq(HARDWARE_NI_DAC, deviceID, triggerMode=triggerMode, flags=HARDWARE_ABORT_ON_ERROR, repeat=1)
			NVAR tpCounter = $GetNITestPulseCounter(device)
			tpCounter = 0
			break
	endswitch
	if(!IsBackgroundTaskRunning(TASKNAME_TPMD))
		CtrlNamedBackground $TASKNAME_TPMD, start
	endif
End

/// @brief Background TP Multi Device
///
/// @ingroup BackgroundFunctions
Function TPM_BkrdTPFuncMD(s)
	STRUCT BackgroundStruct &s

	variable i, j, deviceID, fifoPos, hardwareType, checkAgain, updateInt, endOfPulse
	variable fifoLatest, lastTP, now
	variable channelNr, tpLengthPoints, err
	string device, fifoChannelName, fifoName, errMsg

	variable debTime

	WAVE ActiveDeviceList = GetActiveDevicesTPMD()

	if(s.wmbs.started)
		s.wmbs.started    = 0
		s.count           = 0
		s.threadDeadCount = 0
	else
		s.count += 1
	endif

	now = DateTime

	debTime = DEBUG_TIMER_START()

	// works through list of active devices
	// update parameters for a particular active device
	for(i = 0; i < GetNumberFromWaveNote(ActiveDeviceList, NOTE_INDEX); i += 1)
		deviceID = ActiveDeviceList[i][%DeviceID]
		hardwareType = ActiveDeviceList[i][%HardwareType]
		device = HW_GetMainDeviceName(hardwareType, deviceID)

		WAVE TPSettingsCalc = GetTPsettingsCalculated(device)

		switch(hardwareType)
			case HARDWARE_NI_DAC:
				// Pull data until end of FIFO, after BGTask finishes Graph shows only last update
				do
					checkAgain = 0
					NVAR tpCounter = $GetNITestPulseCounter(device)
					NVAR datapoints = $GetStopCollectionPoint(device)
					fifoName = GetNIFIFOName(deviceID)

					FIFOStatus/Q $fifoName
					ASSERT(V_Flag != 0,"FIFO does not exist!")
					endOfPulse = datapoints * tpCounter + datapoints
					if(V_FIFOChunks >= endOfPulse)
						WAVE/WAVE NIDataWave = GetDAQDataWave(device, TEST_PULSE_MODE)

						AssertOnAndClearRTError()
						try
							for(j = 0; j < V_FIFOnchans; j += 1)
								fifoChannelName = StringByKey("NAME" + num2str(j), S_Info)
								channelNr = str2num(fifoChannelName)
								WAVE NIChannel = NIDataWave[channelNr]
								FIFO2WAVE/R=[endOfPulse - datapoints, endOfPulse - 1] $fifoName, $fifoChannelName, NIChannel; AbortOnRTE
								SetScale/P x, 0, DimDelta(NIChannel, ROWS) * 1000, "ms", NIChannel
							endfor

							SCOPE_UpdateOscilloscopeData(device, TEST_PULSE_MODE, deviceID=deviceID)
						catch
							errMsg = GetRTErrMessage()
							err = ClearRTError()
							LOG_AddEntry(PACKAGE_MIES, "hardware error")
							DQ_StopOngoingDAQ(device, DQ_STOP_REASON_HW_ERROR)
							if(err == 18)
								ASSERT(0, "Acquisition FIFO overflow, data lost. This may happen if the computer is too slow.")
							else
								ASSERT(0, "Error reading data from NI device: code " + num2str(err) + "\r" + errMsg)
							endif
						endtry

						tpCounter += 1
						if((DateTime - now) < TPM_NI_TASKTIMEOUT)
							checkAgain = 1
						else
							DEBUGPRINT("Warning: NI DAC readout is late, aborted further reading.")
						endif
					endif
					if(V_FIFOChunks > TPM_NI_FIFO_THRESHOLD_SIZE)
						HW_NI_StopAcq(deviceID)
						HW_NI_PrepareAcq(deviceID, TEST_PULSE_MODE)
						HW_NI_StartAcq(deviceID, HARDWARE_DAC_DEFAULT_TRIGGER)
						tpCounter = 0
					endif
				while(checkAgain)
			break
		case HARDWARE_ITC_DAC:
			WAVE ITCDataWave = GetDAQDataWave(device, TEST_PULSE_MODE)

			NVAR tgID = $GetThreadGroupIDFIFO(device)
			if(DeviceHasFollower(device))
				WAVE/Z/D result = TS_GetNewestFromThreadQueueMult(tgID, {"fifoPos", "startSequence"})

				if(WaveExists(result))
					fifoPos = result[%fifoPos]

					if(IsFinite(result[%startSequence]))
						ARDStartSequence()
					endif
				else
					fifoPos = NaN
				endif
			else
				fifoPos = TS_GetNewestFromThreadQueue(tgID, "fifoPos")
			endif

			// should never be hit
			if(!IsFinite(fifoPos))
				if(s.threadDeadCount < TP_MD_THREAD_DEAD_MAX_RETRIES)
					s.threadDeadCount += 1
					printf "Retrying getting data from thread, keep fingers crossed (%d/%d)\r", s.threadDeadCount, TP_MD_THREAD_DEAD_MAX_RETRIES
					ControlWindowToFront()
					continue
				endif

				// give up
				TPM_StopTestPulseMultiDevice(device)
				return 0
			endif

			s.threadDeadCount = 0

			fifoLatest = mod(fifoPos, DimSize(ITCDataWave, ROWS))

			// extract the last fully completed chunk
			// for ITC only the last complete TP is evaluated, all earlier TPs get discarded
			lastTP = trunc(fifoLatest / TPSettingsCalc[%totalLengthPointsTP]) - 1

			// Ensures that the new TP chunk isn't the same as the last one.
			// This is required to keep the TP buffer in sync.
			if(lastTP >= 0 && lastTP != ActiveDeviceList[i][%ActiveChunk])
				SCOPE_UpdateOscilloscopeData(device, TEST_PULSE_MODE, chunk=lastTP)
				ActiveDeviceList[i][%ActiveChunk] = lastTP
			endif

			break
		endswitch

		SCOPE_UpdateGraph(device, TEST_PULSE_MODE)

		if(GetKeyState(0) & ESCAPE_KEY)
			DQ_StopOngoingDAQ(device, DQ_STOP_REASON_ESCAPE_KEY)
		endif
	endfor

	DEBUGPRINT_ELAPSED(debTime)

	return 0
End

/// @brief Wrapper for DQM_CallFuncForDevicesYoked()
static Function TPM_StopTPMD(device)
	string device

	return TPM_StopTPMDWrapper(device, fast = 0)
End

/// @brief Wrapper for DQM_CallFuncForDevicesYoked()
static Function TPM_StopTPMDFast(device)
	string device

	return TPM_StopTPMDWrapper(device, fast = 1)
End

static Function TPM_StopTPMDWrapper(device, [fast])
	string device
	variable fast

	if(ParamIsDefault(fast))
		fast = 0
	else
		fast = !!fast
	endif

	NVAR deviceID = $GetDAQDeviceID(device)

	variable hardwareType = GetHardwareType(device)
	if(hardwareType == HARDWARE_ITC_DAC)
		TFH_StopFifoDaemon(HARDWARE_ITC_DAC, deviceID)
	endif

	if(!HW_SelectDevice(hardwareType, deviceID, flags = HARDWARE_PREVENT_ERROR_MESSAGE | HARDWARE_PREVENT_ERROR_POPUP) \
	   && HW_IsRunning(hardwareType, deviceID, flags = HARDWARE_ABORT_ON_ERROR))
		HW_StopAcq(hardwareType, deviceID, zeroDAC = 1)
		TPM_RemoveDevice(device)
		if(!TPM_HasActiveDevices())
			CtrlNamedBackground $TASKNAME_TPMD, stop
		endif

		TP_Teardown(device, fast = fast)
	endif
End

static Function TPM_HasActiveDevices()
	WAVE ActiveDevicesTPMD = GetActiveDevicesTPMD()

	return GetNumberFromWaveNote(ActiveDevicesTPMD, NOTE_INDEX) > 0
End

static Function TPM_RemoveDevice(device)
	string device

	variable idx
	string msg

	WAVE ActiveDevicesTPMD = GetActiveDevicesTPMD()
	NVAR deviceID = $GetDAQDeviceID(device)

	idx = GetNumberFromWaveNote(ActiveDevicesTPMD, NOTE_INDEX) - 1
	ASSERT(idx >= 0, "Invalid index")

	Duplicate/FREE/R=[0, idx][0] ActiveDevicesTPMD, deviceIDs
	FindValue/V=(deviceID) deviceIDs
	ASSERT(V_Value != -1, "Could not find the device")

	// overwrite the to be removed device with the last one
	ActiveDevicesTPMD[V_Value][] = ActiveDevicesTPMD[idx][q]
	ActiveDevicesTPMD[idx][]     = NaN

	SetNumberInWaveNote(ActiveDevicesTPMD, NOTE_INDEX, idx)

	sprintf msg, "Remove device %s in row %d", device, V_Value
	DEBUGPRINT(msg)
End

static Function TPM_AddDevice(device)
	string device

	variable idx
	string msg

	NVAR deviceID = $GetDAQDeviceID(device)
	WAVE ActiveDevicesTPMD = GetActiveDevicesTPMD()

	idx = GetNumberFromWaveNote(ActiveDevicesTPMD, NOTE_INDEX)
	EnsureLargeEnoughWave(ActiveDevicesTPMD, minimumSize=idx + 1)

	ActiveDevicesTPMD[idx][%DeviceID]     = deviceID
	ActiveDevicesTPMD[idx][%HardwareType] = GetHardwareType(device)
	ActiveDevicesTPMD[idx][%activeChunk] = NaN

	SetNumberInWaveNote(ActiveDevicesTPMD, NOTE_INDEX, idx + 1)

	sprintf msg, "Adding device %s with deviceID %d in row %d", device, deviceID, idx
	DEBUGPRINT(msg)
End
