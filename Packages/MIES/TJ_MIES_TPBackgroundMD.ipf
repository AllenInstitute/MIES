#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file TJ_MIES_TPBackgroundMD.ipf
/// @brief __ITC__ Multi device background test pulse functionality

Function ITC_BkrdTPMD(TriggerMode, panelTitle) // if start time = 0 the variable is ignored
	variable TriggerMode
	string panelTitle

	string cmd
	variable StopCollectionPoint = DC_GetStopCollectionPoint(panelTitle, TEST_PULSE_MODE)
	variable ADChannelToMonitor = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_DAC) // channel that is monitored to determine when a sweep should terminate
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	ITC_MakeOrUpdateTPDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, 1)
	ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, 1)
	
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	ExecuteITCOperationAbortOnError(cmd)
	
	if (IsBackgroundTaskRunning("ITC_BkrdTPFuncMD") == 0)
		CtrlNamedBackground TestPulseMD, period = 1, burst = 1, proc = ITC_BkrdTPFuncMD
		CtrlNamedBackground TestPulseMD, start
	endif

	if(TriggerMode == 0) // Start data acquisition triggered on immediate - triggered is used for syncronizing/yoking multiple DACs
		sprintf cmd, "ITCStartAcq"
		ExecuteITCOperationAbortOnError(cmd)
	elseif(TriggerMode > 0)
		sprintf cmd, "ITCStartAcq 1, %d" TriggerMode  // Trigger mode 256 = use external trigger
		ExecuteITCOperationAbortOnError(cmd)
	endif
End

Function ITC_BkrdTPFuncMD(s)
	STRUCT BackgroundStruct &s
	String cmd, Keyboard, panelTitle
	
	WAVE ActiveDeviceList = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDeviceList // column 0 = ITCDeviceIDGlobal; column 1 = ADChannelToMonitor; column 2 = StopCollectionPoint
	WAVE /T ActiveDeviceTextList = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDeviceTextList
	WAVE /WAVE ActiveDeviceWavePathWave = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDevWavePathWave
	variable i = 0
	variable NumberOfActiveDevices
	variable ADChannelToMonitor
	variable StopCollectionPoint
	variable startPoint
	variable PointsInTP
	variable PointsInTPITCDataWave

	if(s.wmbs.started)
		s.wmbs.started = 0
		s.count  = 0
	else
		s.count += 1
	endif

	do // works through list of active devices
		// update parameters for a particular active device
		panelTitle = ActiveDeviceTextList[i]
		DFREF deviceDFR = GetDevicePath(panelTitle)
		NVAR GlobalTPDurationVariable = $GetTestpulseDuration(panelTitle) // number of points in a single test pulse

		WAVE ITCDataWave = ActiveDeviceWavePathWave[i][0]
		WAVE ITCFIFOAvailAllConfigWave = ActiveDeviceWavePathWave[i][1]
		WAVE ITCFIFOPositionAllConfigWave = ActiveDeviceWavePathWave[i][2] //  ActiveDeviceWavePathWave contains wave references
		ADChannelToMonitor = ActiveDeviceList[i][1]
		StopCollectionPoint = ActiveDeviceList[i][2]
		PointsInTP = (GlobalTPDurationVariable * 3)
		PointsInTPITCDataWave = dimsize(ITCDataWave,0)
		//print "PointsInTP =",PointsInTP
		// works with a active device
		sprintf cmd, "ITCSelectDevice %d" ActiveDeviceList[i][0] // ITCDeviceIDGlobal
		ExecuteITCOperationAbortOnError(cmd)
	
		sprintf cmd, "ITCFIFOAvailableALL /z = 0 , %s", GetWavesDataFolder(ITCFIFOAvailAllConfigWave, 2)
		ExecuteITCOperation(cmd)
		variable TPSweepCount = floor(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] / PointsInTPITCDataWave)
		variable PointsCompletedInITCDataWave = (mod(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2], PointsInTPITCDataWave))
//		print PointsCompletedInITCDataWave
		if(PointsCompletedInITCDataWave >= (StopCollectionPoint * .05)) // advances the FIFO is the TP sweep has reached point that gives time for command to be recieved and processed by the DAC - that's why the 0.2 multiplier
			// the above line of code won't handle acquisition with only AD channels - this is probably more generally true as well - need to work this into the code
			Duplicate/O/R=[0, (ADChannelToMonitor-1)][0,3] ITCFIFOAvailAllConfigWave, deviceDFR:FIFOAdvance/Wave=FIFOAdvance // creates a wave that will take DA FIFO advance parameter
			FIFOAdvance[][2] = (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] - ActiveDeviceList[i][3]) // the abs prevents a neg number
			sprintf cmd, "ITCUpdateFIFOPositionAll , %s", GetWavesDataFolder(FIFOAdvance, 2) // goal is to move the DA FIFO pointers back to the start
			ExecuteITCOperation(cmd)
			ActiveDeviceList[i][3] = (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2])
		endif
		
//		print pointsintp
		// extracts chunk from ITCDataWave for plotting
		variable ActiveChunk =  (floor(PointsCompletedInITCDataWave /  (PointsInTP)))
 		if(ActiveChunk >= 1) // This is here because trying to get the last complete chunk somtimes returns a what looks like a incomplete chunk - could be because the xop isn't releasing the itc datawave
			ActiveChunk -= 1 // Doing: ITCDataWave[0][0] += 0 does not help but looking one chunk behind does help avoid a chunk where TP has not occurred yet
		endif
//		startPoint = (ActiveChunk * (PointsInTP*2)) 
		startPoint = (ActiveChunk * (PointsInTP)) 
//		print ActiveChunk
		//startPoint += 0.25 * (PointsInTP)
		//variable endpoint = 0.75 * PointsInTP
		if(startPoint < (PointsInTP))
			startPoint = 0
		endif
	//	ITCDataWave[0][0] += 0
		if(ActiveChunk != ActiveDeviceList[i][4]) // Ensures that the new TP chunk isn't the same as the last one. This is required to keep the TP buffer in sych.
	//		print activechunk
			DM_CreateScaleTPHoldWaveChunk(panelTitle, startPoint, PointsInTP / 1.5) // 
		endif																	
		TP_Delta(panelTitle)
//		ActiveDeviceList[i][4] += 1
		ActiveDeviceList[i][4] = ActiveChunk
		// print ActiveChunk
		// print stopcollectionpoint
		// print PointsCompletedInITCDataWave
		// print pointsintp
		
		// the IF below is there because the ITC18USB locks up and returns a negative value for the FIFO advance with on screen manipulations. 
		// the code stops and starts the data acquisition to correct FIFO error
			if(!DAP_DeviceCanLead(panelTitle))
				WAVE/SDFR=deviceDFR FIFOAdvance
				if(FIFOAdvance[0][2] <= 0 || ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] <= (ActiveDeviceList[i][5] + 1) && ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] >= (ActiveDeviceList[i][5] - 1)) //(1000000 / (ADChannelToMonitor - 1))) // checks to see if the hardware buffer is at max capacity
					sprintf cmd, "ITCStopAcq" // stop and restart acquisition
					ExecuteITCOperation(cmd)
					ITCFIFOAvailAllConfigWave[][2] = 0
					WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
					WAVE ITCDataWave = GetITCDataWave(panelTitle)

					sprintf cmd, "ITCconfigAllchannels, %s, %s", GetWavesDataFolder(ITCChanConfigWave, 2), GetWavesDataFolder(ITCDataWave, 2)
					ExecuteITCOperation(cmd)
					sprintf cmd, "ITCUpdateFIFOPositionAll , %s" GetWavesDataFolder(ITCFIFOPositionAllConfigWave, 2) // I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
					ExecuteITCOperation(cmd)
					sprintf cmd, "ITCStartAcq"
					ExecuteITCOperationAbortOnError(cmd)
					print "FIFO over/underrun, acq restarted"
				endif
			endif
			
			ActiveDeviceList[i][5] = ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2]

			if(mod(s.count, TEST_PULSE_LIVE_UPDATE_INTERVAL) == 0)
				SCOPE_UpdateGraph(panelTitle)
			endif

			ActiveDeviceList[i][3] += 1
		
		NVAR count = $GetCount(panelTitle)
		if(!IsFinite(count))
			Keyboard = KeyboardState("")
			if (cmpstr(Keyboard[9], " ") == 0)	// Is space bar pressed (note the space between the quotations)?
				panelTitle = GetMainWindow(GetCurrentWindow())
				//PRINT PANELTITLE
				if(stringmatch(panelTitle,ActiveDeviceTextList[i]) == 1) // makes sure the panel title being passed is a data acq panel title -  allows space bar hit to apply to a particualr data acquisition panel
					beep 
					DAM_StopTPMD(panelTitle)
				endif
			endif
		endif
		
		NumberOfActiveDevices = numpnts(ActiveDeviceTextList)
		i += 1
	while(i < NumberOfActiveDevices)	
	
	return 0
End

/// @brief Stop the test pulse in multi device mode
Function ITC_StopTPMD(panelTitle)
	string panelTitle

	string cmd
	variable headstage
	WAVE /T ActiveDeviceTextList = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDeviceTextList
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	DFREF deviceDFR = GetDevicePath(panelTitle)

	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	ExecuteITCOperation(cmd)

	///@todo rename to ResultsWave if possible
	Make/I/O/N=4 deviceDFR:StateWave/Wave=StateWave
	// code section below is used to get the state of the DAC
	sprintf cmd, "ITCGetState /R=1 %s", GetWavesDataFolder(StateWave, 2)
	ExecuteITCOperation(cmd)

	if(StateWave[0] != 0) // makes sure the device being stopped is actually running
		sprintf cmd, "ITCStopAcq"
		ExecuteITCOperation(cmd)

		ITC_MakeOrUpdateTPDevLstWave(panelTitle, ITCDeviceIDGlobal, 0, 0, -1)
		ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, -1)
		ITC_ZeroITCOnActiveChan(panelTitle) // zeroes the active DA channels - makes sure the DA isn't left in the TP up state.
		if (dimsize(ActiveDeviceTextList, 0) == 0) 
			CtrlNamedBackground TestPulseMD, stop
			print "Stopping test pulse on:", panelTitle, "In ITC_StopTPMD"
		endif
	endif

	SCOPE_KillScopeWindowIfRequest(panelTitle)
	ED_TPDocumentation(panelTitle)
	EnableControl(panelTitle, "StartTestPulseButton")
	DAP_RestoreTTLState(panelTitle)

	headstage = GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage")
	P_LoadPressureButtonState(panelTitle, headStage)
End

Function ITC_MakeOrUpdateTPDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, AddorRemoveDevice)
	string panelTitle
	Variable ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, AddorRemoveDevice // when removing a device only the ITCDeviceIDGlobal is needed
	//Variable start = stopmstimer(-2)

	DFREF activeDevicesTestPulse = createDFWithAllParents("root:MIES:ITCDevices:ActiveITCDevices:TestPulse")
	WAVE/Z/SDFR=activeDevicesTestPulse ActiveDeviceList

	NVAR/SDFR=GetDeviceTestPulse(panelTitle) TPPulseCount
	if (AddorRemoveDevice == 1) // add a ITC device
		if(!WaveExists(ActiveDeviceList))
			Make/N=(1, 6) activeDevicesTestPulse:ActiveDeviceList/Wave=ActiveDeviceList
			ActiveDeviceList[0][0] = ITCDeviceIDGlobal
			ActiveDeviceList[0][1] = ADChannelToMonitor
			ActiveDeviceList[0][2] = StopCollectionPoint
			ActiveDeviceList[0][3] =  0 // FIFO advance from last background cycle
			ActiveDeviceList[0][4] = 1 // TP count
			ActiveDeviceList[0][5] = TPPulseCount // pulses in TP ITC data wave
		else
			variable numberOfRows = DimSize(ActiveDeviceList, 0)
			Redimension /n = (numberOfRows + 1, 6) ActiveDeviceList
			ActiveDeviceList[numberOfRows][0] = ITCDeviceIDGlobal
			ActiveDeviceList[numberOfRows][1] = ADChannelToMonitor
			ActiveDeviceList[numberOfRows][2] = StopCollectionPoint
			ActiveDeviceList[0][3] = 0 // FIFO advance from last background cycle
			ActiveDeviceList[0][4] = 1 // TP count
			ActiveDeviceList[0][5] = TPPulseCount// pulses in TP ITC data wave
		endif
	elseif (AddorRemoveDevice == -1) // remove a ITC device
		Duplicate /FREE /r = [][0] ActiveDeviceList ListOfITCDeviceIDGlobal // duplicates the column that contains the global device ID's
		FindValue /V = (ITCDeviceIDGlobal) ListOfITCDeviceIDGlobal // searchs the duplicated column for the device to be turned off
		DeletePoints /m = 0 v_value, 1, ActiveDeviceList // removes the row that contains the device 
	endif
End 


 Function ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, AddorRemoveDevice) // creates or updates wave that contains string of active panel title names
 	string panelTitle
 	Variable AddOrRemoveDevice
 	//Variable start = stopmstimer(-2)
 	String WavePath = "root:MIES:ITCDevices:ActiveITCDevices:TestPulse"
 	WAVE /z /T ActiveDeviceTextList = $WavePath + ":ActiveDeviceTextList"
 	if (AddOrRemoveDevice == 1) // Add a device
 		if(WaveExists($WavePath + ":ActiveDeviceTextList") == 0)
 			Make /t /o /n = 1 $WavePath + ":ActiveDeviceTextList"
 			WAVE /Z /T ActiveDeviceTextList = $WavePath + ":ActiveDeviceTextList"
 			ActiveDeviceTextList = panelTitle
 		elseif (WaveExists($WavePath + ":ActiveDeviceTextList") == 1)
 			Variable numberOfRows = numpnts(ActiveDeviceTextList)
 			Redimension /n = (numberOfRows + 1) ActiveDeviceTextList
 			ActiveDeviceTextList[numberOfRows] = panelTitle
 		endif
 	elseif (AddOrRemoveDevice == -1) // remove a device 
 		FindValue /Text = panelTitle ActiveDeviceTextList
 		Variable RowToRemove = v_value
 		DeletePoints /m = 0 RowToRemove, 1, ActiveDeviceTextList
 	endif
 	 //print "text wave creation took (ms):", (stopmstimer(-2) - start) / 1000

 	ITC_MakeOrUpdtTPDevWvPth(panelTitle, AddOrRemoveDevice, RowToRemove)
 End


static Function ITC_MakeOrUpdtTPDevWvPth(panelTitle, AddOrRemoveDevice, RowToRemove) // creates wave that contains wave references
	string panelTitle
	variable AddOrRemoveDevice, RowToRemove

	variable numberOfRows
	DFREF deviceDFR = GetDevicePath(panelTitle)
	DFREF dfr = root:MIES:ITCDevices:ActiveITCDevices:testPulse

	WAVE/Z/WAVE/SDFR=dfr ActiveDevWavePathWave
	if(AddOrRemoveDevice == 1)
		if(!WaveExists(ActiveDevWavePathWave))
			Make/WAVE/N=(1,5) dfr:ActiveDevWavePathWave/Wave=ActiveDevWavePathWave
			ActiveDevWavePathWave[0][0] = deviceDFR:ITCDataWave
			ActiveDevWavePathWave[0][1] = deviceDFR:ITCFIFOAvailAllConfigWave
			ActiveDevWavePathWave[0][2] = deviceDFR:ITCFIFOPositionAllConfigWave
			ActiveDevWavePathWave[0][3] = deviceDFR:ResultsWave
			ActiveDevWavePathWave[0][4] = deviceDFR:ITCChanConfigWave
		else
			numberOfRows = DimSize(ActiveDevWavePathWave, ROWS)
			Redimension/N=(numberOfRows + 1, 5) ActiveDevWavePathWave
			ActiveDevWavePathWave[numberOfRows][0] = deviceDFR:ITCDataWave
			ActiveDevWavePathWave[numberOfRows][1] = deviceDFR:ITCFIFOAvailAllConfigWave
			ActiveDevWavePathWave[numberOfRows][2] = deviceDFR:ITCFIFOPositionAllConfigWave
			ActiveDevWavePathWave[numberOfRows][3] = deviceDFR:ResultsWave
			ActiveDevWavePathWave[numberOfRows][4] = deviceDFR:ITCChanConfigWave
		endif
	elseif(AddOrRemoveDevice == -1)
		DeletePoints /m = 0 RowToRemove, 1, ActiveDevWavePathWave
	endif
End
