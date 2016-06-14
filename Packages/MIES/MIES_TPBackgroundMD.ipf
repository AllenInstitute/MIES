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

	SVAR listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
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
		CtrlNamedBackground TestPulseMD, period = 1, burst = 1, proc = ITC_BkrdTPFuncMD
		CtrlNamedBackground TestPulseMD, start
	endif

	HW_StartAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, triggerMode=triggerMode, flags=HARDWARE_ABORT_ON_ERROR)
End

Function ITC_BkrdTPFuncMD(s)
	STRUCT BackgroundStruct &s

	variable ADChannelToMonitor, i, deviceID
	variable StopCollectionPoint, pointsCompletedInITCDataWave, activeChunk
	string panelTitle

	DFREF dfr = GetActITCDevicesTestPulseFolder()
	WAVE/SDFR=dfr ActiveDeviceList
	WAVE/T/SDFR=dfr ActiveDeviceTextList
	WAVE/WAVE/SDFR=dfr ActiveDevWavePathWave

	if(s.wmbs.started)
		s.wmbs.started = 0
		s.count  = 0
	else
		s.count += 1
	endif

	// works through list of active devices
	// update parameters for a particular active device
	// ActiveDeviceTextList size might change inside the loop so we can
	// *not* precompute it.
	for(i = 0; i < DimSize(ActiveDeviceTextList, ROWS); i += 1)
		panelTitle = ActiveDeviceTextList[i]
		DFREF deviceDFR = GetDevicePath(panelTitle)

		WAVE ITCDataWave = ActiveDevWavePathWave[i][0]
		WAVE ITCFIFOAvailAllConfigWave = ActiveDevWavePathWave[i][1]
		WAVE ITCFIFOPositionAllConfigWave = ActiveDevWavePathWave[i][2]

		deviceID            = ActiveDeviceList[i][0]
		ADChannelToMonitor  = ActiveDeviceList[i][1]
		stopCollectionPoint = ActiveDeviceList[i][2]

		HW_SelectDevice(HARDWARE_ITC_DAC, deviceID, flags=HARDWARE_ABORT_ON_ERROR)
		HW_ITC_MoreData(deviceID, fifoAvail=ActiveDevWavePathWave[i][1], ADChannelToMonitor=ADChannelToMonitor, stopCollectionPoint=stopCollectionPoint, fifoPos=pointsCompletedInITCDataWave)
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
			if((WaveExists(FIFOAdvance) && FIFOAdvance[0][2] <= 0) || (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] > 0 && abs(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] - ActiveDeviceList[i][5]) <= 1)) // checks to see if the hardware buffer is at max capacity
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
				panelTitle = GetMainWindow(GetCurrentWindow())
				// only stop the currently active device
				if(!cmpstr(panelTitle,ActiveDeviceTextList[i]))
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
	WAVE/T/SDFR=dfr ActiveDeviceTextList
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)

	if(HW_IsRunning(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)) // makes sure the device being stopped is actually running
		HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)

		ITC_MakeOrUpdateTPDevLstWave(panelTitle, ITCDeviceIDGlobal, 0, 0, -1)
		ITC_ZeroITCOnActiveChan(panelTitle) // zeroes the active DA channels - makes sure the DA isn't left in the TP up state.
		if (dimsize(ActiveDeviceTextList, 0) == 0) 
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

	ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, addOrRemoveDevice)

	WAVE/Z/SDFR=dfr ActiveDeviceList, ActiveDeviceTextList, ActiveDevWavePathWave
	ASSERT(WaveExists(ActiveDeviceList), "Missing wave ActiveDeviceList")
	ASSERT(WaveExists(ActiveDeviceTextList), "Missing wave ActiveDeviceTextList")
	ASSERT(WaveExists(ActiveDevWavePathWave), "Missing wave ActiveDevWavePathWave")
	ASSERT(DimSize(ActiveDeviceList, ROWS) == DimSize(ActiveDeviceTextList, ROWS), "Number of rows in ActiveDeviceList and ActiveDeviceTextList must be equal")
	ASSERT(DimSize(ActiveDeviceList, ROWS) == DimSize(ActiveDevWavePathWave, ROWS), "Number of rows in ActiveDeviceList and ActiveDevWavePathWave must be equal")
End

static Function ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, addOrRemoveDevice)
	string panelTitle
	variable addOrRemoveDevice

	variable rowToRemove = NaN
	variable numberOfRows

	DFREF dfr = GetActITCDevicesTestPulseFolder()
	WAVE/Z/T/SDFR=dfr ActiveDeviceTextList

	if(addOrRemoveDevice == 1) // Add a device
		if(!WaveExists(ActiveDeviceTextList))
			Make/T/N=1 dfr:ActiveDeviceTextList/WAVE=ActiveDeviceTextList
			ActiveDeviceTextList[0] = panelTitle
		else
			numberOfRows = DimSize(ActiveDeviceTextList, ROWS)
			Redimension/N=(numberOfRows + 1) ActiveDeviceTextList
			ActiveDeviceTextList[numberOfRows] = panelTitle
		endif
	elseif(addOrRemoveDevice == -1) // remove a device
		FindValue/TEXT=panelTitle ActiveDeviceTextList
		rowToRemove = V_Value
		ASSERT(rowToRemove >= 0, "Trying to remove a non existing device")
		DeletePoints/M=(ROWS) rowToRemove, 1, ActiveDeviceTextList
	else
		ASSERT(0, "Invalid addOrRemoveDevice value")
	endif

	ITC_MakeOrUpdtTPDevWvPth(panelTitle, addOrRemoveDevice, rowToRemove)
End

static Function ITC_MakeOrUpdtTPDevWvPth(panelTitle, addOrRemoveDevice, rowToRemove)
	string panelTitle
	variable addOrRemoveDevice, rowToRemove

	variable numberOfRows

	DFREF dfr = GetActITCDevicesTestPulseFolder()

	WAVE ITCDataWave                  = GetITCDataWave(panelTitle)
	WAVE ITCChanConfigWave            = GetITCChanConfigWave(panelTitle)
	WAVE ITCFIFOAvailAllConfigWave    = GetITCFIFOAvailAllConfigWave(panelTitle)
	WAVE ITCFIFOPositionAllConfigWave = GetITCFIFOPositionAllConfigWave(panelTitle)
	WAVE ResultsWave                  = GetITCResultsWave(panelTitle)

	WAVE/Z/WAVE/SDFR=dfr ActiveDevWavePathWave
	if(addOrRemoveDevice == 1)
		if(!WaveExists(ActiveDevWavePathWave))
			Make/WAVE/N=(1,5) dfr:ActiveDevWavePathWave/Wave=ActiveDevWavePathWave
			ActiveDevWavePathWave[0][0] = ITCDataWave
			ActiveDevWavePathWave[0][1] = ITCFIFOAvailAllConfigWave
			ActiveDevWavePathWave[0][2] = ITCFIFOPositionAllConfigWave
			ActiveDevWavePathWave[0][3] = ResultsWave
			ActiveDevWavePathWave[0][4] = ITCChanConfigWave
		else
			numberOfRows = DimSize(ActiveDevWavePathWave, ROWS)
			Redimension/N=(numberOfRows + 1, 5) ActiveDevWavePathWave
			ActiveDevWavePathWave[numberOfRows][0] = ITCDataWave
			ActiveDevWavePathWave[numberOfRows][1] = ITCFIFOAvailAllConfigWave
			ActiveDevWavePathWave[numberOfRows][2] = ITCFIFOPositionAllConfigWave
			ActiveDevWavePathWave[numberOfRows][3] = ResultsWave
			ActiveDevWavePathWave[numberOfRows][4] = ITCChanConfigWave
		endif
	elseif(addOrRemoveDevice == -1)
		ASSERT(rowToRemove >= 0, "Trying to remove a non existing device")
		DeletePoints/M=(ROWS) rowToRemove, 1, ActiveDevWavePathWave
	else
		ASSERT(0, "Invalid addOrRemoveDevice value")
	endif
End
