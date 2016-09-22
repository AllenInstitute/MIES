#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

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

	if(!IsBackgroundTaskRunning("TestPulseMD"))
		CtrlNamedBackground TestPulseMD, period = 1, proc = ITC_BkrdTPFuncMD
		CtrlNamedBackground TestPulseMD, start
	endif

	HW_StartAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, triggerMode=triggerMode, flags=HARDWARE_ABORT_ON_ERROR)
End

Function ITC_BkrdTPFuncMD(s)
	STRUCT BackgroundStruct &s

	variable ADChannelToMonitor, i, deviceID
	variable StopCollectionPoint, pointsCompletedInITCDataWave, activeChunk
	string panelTitle, currentWindow

	DFREF dfr = GetActITCDevicesTestPulseFolder()
	WAVE/SDFR=dfr ActiveDeviceList

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

		deviceID            = ActiveDeviceList[i][0]
		ADChannelToMonitor  = ActiveDeviceList[i][1]
		stopCollectionPoint = ActiveDeviceList[i][2]

		panelTitle = HW_GetMainDeviceName(HARDWARE_ITC_DAC, deviceID)
		DFREF deviceDFR = GetDevicePath(panelTitle)

		WAVE ITCDataWave                  = GetITCDataWave(panelTitle)
		WAVE ITCFIFOAvailAllConfigWave    = GetITCFIFOAvailAllConfigWave(panelTitle)
		WAVE ITCFIFOPositionAllConfigWave = GetITCFIFOPositionAllConfigWave(panelTitle)

		HW_SelectDevice(HARDWARE_ITC_DAC, deviceID, flags=HARDWARE_ABORT_ON_ERROR)
		HW_ITC_MoreData(deviceID, fifoPos=pointsCompletedInITCDataWave)
		pointsCompletedInITCDataWave = mod(pointsCompletedInITCDataWave, DimSize(ITCDataWave, ROWS))

		if(pointsCompletedInITCDataWave >= stopCollectionPoint * 0.05)
			// advances the FIFO is the TP sweep has reached point that gives time for command to be recieved
			// and processed by the DAC - that's why the multiplier
			// @todo the above line of code won't handle acquisition with only AD channels
			// this is probably more generally true as well - need to work this into the code
			Duplicate/O/R=[0, (ADChannelToMonitor-1)][0,3] ITCFIFOAvailAllConfigWave, deviceDFR:FIFOAdvance/Wave=FIFOAdvance
			FIFOAdvance[][2] = ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] - ActiveDeviceList[i][3]
			HW_ITC_ResetFifo(deviceID, fifoPos=FIFOAdvance)
			ActiveDeviceList[i][3] = ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2]
		endif

		// don't extract the last chunk for plotting
		activeChunk = max(0, floor(pointsCompletedInITCDataWave / TP_GetTestPulseLengthInPoints(panelTitle, REAL_SAMPLING_INTERVAL_TYPE)) - 1)

		// Ensures that the new TP chunk isn't the same as the last one.
		// This is required to keep the TP buffer in sync.
		if(activeChunk != ActiveDeviceList[i][4])
			DM_UpdateOscilloscopeData(panelTitle, TEST_PULSE_MODE, chunk=activeChunk)
			TP_Delta(panelTitle)
			ActiveDeviceList[i][4] = activeChunk
		endif

		// the IF below is there because the ITC18USB locks up and returns a negative value for the FIFO advance with on screen manipulations. 
		// the code stops and starts the data acquisition to correct FIFO error
		if(!DeviceCanLead(panelTitle))
			WAVE/Z/SDFR=deviceDFR FIFOAdvance
			// checks to see if the hardware buffer is at max capacity
			if((WaveExists(FIFOAdvance) && FIFOAdvance[0][2] <= 0)      \
			   || (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] > 0 \
				  && abs(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] - ActiveDeviceList[i][5]) <= 1))
				HW_StopAcq(HARDWARE_ITC_DAC, deviceID)
				ITCFIFOAvailAllConfigWave[][2] = 0
				FIFOAdvance[0][2] = NaN

				HW_ITC_PrepareAcq(deviceID, dataFunc=GetITCDataWave, configFunc=GetITCChanConfigWave, fifoPos=ITCFIFOPositionAllConfigWave)
				HW_StartAcq(HARDWARE_ITC_DAC, deviceID, flags=HARDWARE_ABORT_ON_ERROR)
				printf "Device %s restarted\r", panelTitle
			endif
		endif

		ActiveDeviceList[i][5] = ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2]

		if(mod(s.count, TEST_PULSE_LIVE_UPDATE_INTERVAL) == 0)
			SCOPE_UpdateGraph(panelTitle)
		endif

		NVAR count = $GetCount(panelTitle)
		if(!IsFinite(count))
			if(GetKeyState(0) & ESCAPE_KEY)
				currentWindow = GetMainWindow(GetCurrentWindow())
				// only stop the currently active device
				if(!cmpstr(panelTitle, currentWindow))
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

	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)

	if(HW_IsRunning(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)) // makes sure the device being stopped is actually running
		HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)

		ITC_MakeOrUpdateTPDevLstWave(panelTitle, ITCDeviceIDGlobal, 0, 0, -1)
		ITC_ZeroITCOnActiveChan(panelTitle) // zeroes the active DA channels - makes sure the DA isn't left in the TP up state.
		if(DimSize(ActiveDeviceList, ROWS) == 0)
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
			ActiveDeviceList[0][3] = 0 // FIFO advance from last background cycle
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
