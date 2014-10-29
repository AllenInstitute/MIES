#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ITC_BkrdTPMD(DeviceType, DeviceNum, TriggerMode, panelTitle) // if start time = 0 the variable is ignored
 	variable DeviceType, DeviceNum, TriggerMode
	string panelTitle
	string WavePath
	sprintf WavePath, "%s" HSU_DataFullFolderPathString(panelTitle)
	string  ITCDataWavePath
	sprintf ITCDataWavePath, "%s:ITCDataWave" WavePath
	string ITCChanConfigWavePath
	sprintf ITCChanConfigWavePath, "%s:ITCChanConfigWave" WavePath
	string ITCDeviceIDGlobalPath
	sprintf ITCDeviceIDGlobalPath, "%s:ITCDeviceIDGlobal" WavePath
	string ITCFIFOAvailAllConfigWavePath
	sprintf ITCFIFOAvailAllConfigWavePath, "%s:ITCFIFOAvailAllConfigWave" WavePath
	string cmd
	sprintf cmd, ""
	
	variable StopCollectionPoint = DC_CalculateLongestSweep(panelTitle) // used to determine when a sweep should terminate
	variable ADChannelToMonitor = DC_NoOfChannelsSelected("DA", panelTitle) // channel that is monitored to determine when a sweep should terminate
	NVAR ITCDeviceIDGlobal = $ITCDeviceIDGlobalPath
	
	WAVE ITCDataWave = $ITCDataWavePath // ITC data wave is the wave that is uploaded to the DAC and contains the DA (output) data and place holder for the input data
	WAVE ITCFIFOAvailAllConfigWave = $ITCFIFOAvailAllConfigWavePath
	
	ITC_MakeOrUpdateTPDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, 1)
	ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, 1)
	
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd
	
	if (TP_IsBackgrounOpRunning(panelTitle, "ITC_BkrdTPFuncMD") == 0)
		CtrlNamedBackground TestPulseMD, period = 1, burst = 1, proc = ITC_BkrdTPFuncMD
		CtrlNamedBackground TestPulseMD, start
	endif

	if(TriggerMode == 0) // Start data acquisition triggered on immediate - triggered is used for syncronizing/yoking multiple DACs
		Execute "ITCStartAcq" 
	elseif(TriggerMode > 0)
		sprintf cmd, "ITCStartAcq 1, %d" TriggerMode  // Trigger mode 256 = use external trigger
		Execute cmd	
	endif

End


Function ITC_BkrdTPFuncMD(s)
	STRUCT WMBackgroundStruct &s
	String cmd, Keyboard, panelTitle
	
	WAVE ActiveDeviceList = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDeviceList // column 0 = ITCDeviceIDGlobal; column 1 = ADChannelToMonitor; column 2 = StopCollectionPoint
	WAVE /T ActiveDeviceTextList = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDeviceTextList
	WAVE /WAVE ActiveDeviceWavePathWave = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDevWavePathWave
	variable i = 0
	variable NumberOfActiveDevices
	string WavePath
	string CountPath
	string oscilloscopeSubWindow
	variable ADChannelToMonitor
	variable StopCollectionPoint
	variable NumberOfChannels
	variable sweepCount
	variable startPoint
	variable PointsInTP
	string TPDurationGlobalPath 
	//NVAR FifoOffset = root:FifoOffset
	variable PointsInTPITCDataWave

	
	do // works through list of active devices
		// update parameters for a particular active device
		panelTitle = ActiveDeviceTextList[i]
		WavePath = HSU_DataFullFolderPathString(panelTitle)
		WAVE /z FIFOAdvance = $WavePath + ":FifoAdvance"
		sprintf TPDurationGlobalPath, "%s:TestPulse:Duration" WavePath
		NVAR GlobalTPDurationVariable = $TPDurationGlobalPath // number of points in a single test pulse
		
		WAVE ITCDataWave = ActiveDeviceWavePathWave[i][0]
		WAVE ITCFIFOAvailAllConfigWave = ActiveDeviceWavePathWave[i][1]
		WAVE ITCFIFOPositionAllConfigWavePth = ActiveDeviceWavePathWave[i][2] //  ActiveDeviceWavePathWave contains wave references
		// WAVE ResultsWavePath = ActiveDeviceWavePathWave[i][3]
		//ITCFIFOAvailAllConfigWave[][2] = 0
		CountPath = GetWavesDataFolder(ActiveDeviceWavePathWave[i][0],1) + "count"
		oscilloscopeSubWindow = ActiveDeviceTextList[i] + "#oscilloscope"
		ADChannelToMonitor = ActiveDeviceList[i][1]
		StopCollectionPoint = ActiveDeviceList[i][2]
//		PointsInTP = (GlobalTPDurationVariable * 2) //
		PointsInTP = (GlobalTPDurationVariable * 3) //
		PointsInTPITCDataWave = dimsize(ITCDataWave,0)
		//print "PointsInTP =",PointsInTP
		// works with a active device
		sprintf cmd, "ITCSelectDevice %d" ActiveDeviceList[i][0] // ITCDeviceIDGlobal
		execute cmd		
	
		sprintf cmd, "ITCFIFOAvailableALL /z = 0 , %s" (WavePath + ":ITCFIFOAvailAllConfigWave")
		Execute cmd	
		variable TPSweepCount = floor(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] / PointsInTPITCDataWave)
//		print "TPSweepCount =", TPSweepCount
//		variable PointsCompletedInITCDataWave = PointsInTPITCDataWave - (mod(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2], PointsInTPITCDataWave))
		variable PointsCompletedInITCDataWave = (mod(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2], PointsInTPITCDataWave))
//		print PointsCompletedInITCDataWave
		if(PointsCompletedInITCDataWave >= (StopCollectionPoint * .05)) // advances the FIFO is the TP sweep has reached point that gives time for command to be recieved and processed by the DAC - that's why the 0.2 multiplier
			// the above line of code won't handle acquisition with only AD channels - this is probably more generally true as well - need to work this into the code
			duplicate /o /r = [0, (ADChannelToMonitor-1)][0,3] ITCFIFOAvailAllConfigWave, $WavePath + ":FifoAdvance" // creates a wave that will take DA FIFO advance parameter
			WAVE FIFOAdvance = $WavePath + ":FifoAdvance"
			FIFOAdvance[][2] = (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] - ActiveDeviceList[i][3]) // the abs prevents a neg number
			sprintf cmd, "ITCUpdateFIFOPositionAll , %s" (WavePath + ":FifoAdvance") // goal is to move the DA FIFO pointers back to the start
			execute cmd
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
		TP_Delta(panelTitle, WavePath + ":TestPulse") 
//		ActiveDeviceList[i][4] += 1
		ActiveDeviceList[i][4] = ActiveChunk
		//print ActiveChunk
		// print stopcollectionpoint
		// print PointsCompletedInITCDataWave
		// print pointsintp
		
		

		
		// the IF below is there because the ITC18USB locks up and returns a negative value for the FIFO advance with on screen manipulations. 
		// the code stops and starts the data acquisition to correct FIFO error
			if(stringmatch(WavePath,"*ITC1600*") == 0) // checks to see if the device is not a ITC1600
				if(FIFOAdvance[0][2] <= 0 || ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] <= (ActiveDeviceList[i][5] + 1) && ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] >= (ActiveDeviceList[i][5] - 1)) //(1000000 / (ADChannelToMonitor - 1))) // checks to see if the hardware buffer is at max capacity
					Execute "ITCStopAcq" // stop and restart acquisition
					ITCFIFOAvailAllConfigWave[][2] =0
					string ITCChanConfigWavePath
					sprintf ITCChanConfigWavePath, "%s:ITCChanConfigWave" WavePath
					string ITCDataWavePath
					sprintf ITCDataWavePath, "%s:ITCDataWave" WavePath
					sprintf cmd, "ITCconfigAllchannels, %s, %s" ITCChanConfigWavePath, ITCDataWavePath
					Execute cmd	
					string ITCFIFOPosAllConfigWvPthStr
					sprintf ITCFIFOPosAllConfigWvPthStr, "%s:ITCFIFOPositionAllConfigWave" WavePath
					sprintf cmd, "ITCUpdateFIFOPositionAll , %s" ITCFIFOPosAllConfigWvPthStr// I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
					execute cmd
					Execute "ITCStartAcq"
					print "FIFO over/underrun, acq restarted"
				endif
			endif
			
			ActiveDeviceList[i][5] = ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2]
			//ITCDataWave[0][0] =+ 0
			
			if(mod(s.curRunTicks, 100) == 0)// || BackgroundTPCount == 1) // switches autoscale on and off in oscilloscope Graph
				ModifyGraph /w = $oscilloscopeSubWindow Live = 0
				ModifyGraph /w = $oscilloscopeSubWindow Live = 1
			endif
			
			ActiveDeviceList[i][3] += 1
			//ActiveDeviceList[i][4] = 1 // resets the test pulse chunk to use back to 1 every time the DA wave loops
		//endif
		
		if(exists(countPath) == 0)// uses the presence of a global variable that is created by the activation of repeated aquisition to determine if the space bar can turn off the TP
			Keyboard = KeyboardState("")
			if (cmpstr(Keyboard[9], " ") == 0)	// Is space bar pressed (note the space between the quotations)?
				panelTitle = DAP_ReturnPanelName()
				//PRINT PANELTITLE
				if(stringmatch(panelTitle,ActiveDeviceTextList[i]) == 1) // makes sure the panel title being passed is a data acq panel title -  allows space bar hit to apply to a particualr data acquisition panel
					beep 
//					sprintf cmd, "ITCStopAcq"
//					execute cmd
//					ITC_MakeOrUpdateTPDevLstWave(panelTitle, ActiveDeviceList[i][0], 0, 0, -1) // ActiveDeviceList[i][0] = device ID global
//					ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, -1)
//					ITC_ZeroITCOnActiveChan(panelTitle) // zeroes the active DA channels - makes sure the DA isn't left in the TP up state.
//					if (dimsize(ActiveDeviceTextList, 0) == 0) 
//						CtrlNamedBackground TestPulseMD, stop
//						print "Stopping test pulse"
//						ITC_FinishTestPulseMD(panelTitle) // stops the test pulse on the top data acq panel
//					endif
				   ITCStopTP(panelTitle)
				   ITC_TPDocumentation(panelTitle) // documents the TP Vrest, peak and steady state resistance values for manual termination of the TP.
				endif
			endif
		endif
		
		NumberOfActiveDevices = numpnts(ActiveDeviceTextList)
		i += 1
	while(i < NumberOfActiveDevices)	
	
	return 0
End
//======================================================================================

Function ITC_FinishTestPulseMD(panelTitle)
	string panelTitle
	string cmd
	// CtrlNamedBackground TestPulse, stop
	// sprintf cmd, "ITCCloseAll" 
	// execute cmd
	//print "PT=",panelTitle
	controlinfo /w = $panelTitle check_Settings_ShowScopeWindow
	if(v_value == 0)
		DAP_SmoothResizePanel(-340, panelTitle)
		setwindow $panelTitle + "#oscilloscope", hide = 1
	endif

	ControlInfo /w = $panelTitle StartTestPulseButton
	if(V_disable == 2) // 0 = normal, 1 = hidden, 2 = disabled, visible
		Button StartTestPulseButton, win = $panelTitle, disable = 0
	endif
	
	if(V_disable == 3) // 0 = normal, 1 = hidden, 2 = disabled, visible
		V_disable = V_disable & ~0x2
		Button StartTestPulseButton, win = $panelTitle, disable =  V_disable
	endif
	
	DAP_RestoreTTLState(panelTitle)
	// killvariables /z  StopCollectionPoint, ADChannelToMonitor, BackgroundTaskActive
	// killstrings /z root:MIES:ITCDevices:PanelTitleG
End

//======================================================================================
Function ITC_StopTPMD(panelTitle) // This function is designed to stop the test pulse on a particular panel
	string panelTitle
	string cmd
	WAVE /T ActiveDeviceTextList = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDeviceTextList
	string DeviceFolderPath = HSU_DataFullFolderPathString(panelTitle)
	string DeviceIDGlobalPathString
	sprintf DeviceIDGlobalPathString, "%s:ITCDeviceIDGlobal" DeviceFolderPath
	NVAR DeviceIDGlobal = $DeviceIDGlobalPathString
	
	sprintf cmd, "ITCSelectDevice %d" DeviceIDGlobal
	execute cmd		
	
	// code section below is used to get the state of the DAC
	string StateWavePathString 
	sprintf StateWavePathString, "%s:StateWave" DeviceFolderPath
	Make /I/O/N=4 $StateWavePathString
	wave StateWave = $StateWavePathString
	sprintf cmd, "ITCGetState /R=1 %s" StateWavePathString
	execute cmd

	if(StateWave[0] != 0) // makes sure the device being stopped is actually running
		sprintf cmd, "ITCStopAcq"
		execute cmd
		
		ITC_MakeOrUpdateTPDevLstWave(panelTitle, DeviceIDGlobal, 0, 0, -1) // 
		ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, -1)
		ITC_ZeroITCOnActiveChan(panelTitle) // zeroes the active DA channels - makes sure the DA isn't left in the TP up state.
		if (dimsize(ActiveDeviceTextList, 0) == 0) 
			CtrlNamedBackground TestPulseMD, stop
			print "Stopping test pulse on:", panelTitle, "In ITC_StopTPMD"
			ITC_FinishTestPulseMD(panelTitle) // makes appropriate updated to locked DA ephys panel following termination of the TP, ex. enables TP button
		endif
	endif
End
//======================================================================================

Function ITC_MakeOrUpdateTPDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, AddorRemoveDevice)
	string panelTitle
	Variable ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, AddorRemoveDevice // when removing a device only the ITCDeviceIDGlobal is needed
	//Variable start = stopmstimer(-2)

	string WavePath = "root:MIES:ITCDevices:ActiveITCDevices:TestPulse"
	WAVE /z ActiveDeviceList = $WavePath + ":ActiveDeviceList"
	string TPFolderPath
	sprintf TPFolderPath, "%s:TestPulse:TPPulseCount" HSU_DataFullFolderPathString(panelTitle)
	NVAR TPPulseCount = $TPFolderPath
	if (AddorRemoveDevice == 1) // add a ITC device
		if (waveexists($WavePath + ":ActiveDeviceList") == 0) 
			Make /o /n = (1,6) $WavePath + ":ActiveDeviceList"
			WAVE /Z ActiveDeviceList = $WavePath + ":ActiveDeviceList"
			ActiveDeviceList[0][0] = ITCDeviceIDGlobal
			ActiveDeviceList[0][1] = ADChannelToMonitor
			ActiveDeviceList[0][2] = StopCollectionPoint
			ActiveDeviceList[0][3] =  0 // FIFO advance from last background cycle
			ActiveDeviceList[0][4] = 1 // TP count
			ActiveDeviceList[0][5] = TPPulseCount // pulses in TP ITC data wave
		elseif (waveexists($WavePath + ":ActiveDeviceList") == 1)
			variable numberOfRows = DimSize(ActiveDeviceList, 0)
			// print numberofrows
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
		// wavestats ListOfITCDeviceIDGlobal
		// print "ITCDeviceIDGlobal = ", ITCDeviceIDGlobal
		FindValue /V = (ITCDeviceIDGlobal) ListOfITCDeviceIDGlobal // searchs the duplicated column for the device to be turned off
		DeletePoints /m = 0 v_value, 1, ActiveDeviceList // removes the row that contains the device 
	endif
	//print "text wave creation took (ms):", (stopmstimer(-2) - start) / 1000
End // Function 	ITC_MakeOrUpdateTPDevLstWave(panelTitle)
//=============================================================================================================================

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

 End // ITC_MakeOrUpdtTPDevListTxtWv(panelTitle)
//=============================================================================================================================

Function ITC_MakeOrUpdtTPDevWvPth(panelTitle, AddOrRemoveDevice, RowToRemove) // creates wave that contains wave references
	String panelTitle
	Variable AddOrRemoveDevice, RowToRemove
	//Variable start = stopmstimer(-2)
	string DeviceFolderPath = HSU_DataFullFolderPathString(panelTitle)
	WAVE /Z /WAVE ActiveDevWavePathWave = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDevWavePathWave
	if (AddOrRemoveDevice == 1) 
		if (WaveExists(root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDevWavePathWave) == 0)
			Make /WAVE /n = (1,5) root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDevWavePathWave
			WAVE /Z /WAVE ActiveDevWavePathWave = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDevWavePathWave
			// print devicefolderpath + ":itcdatawave"
			ActiveDevWavePathWave[0][0] = $(DeviceFolderPath + ":ITCDataWave") 
			ActiveDevWavePathWave[0][1] = $(DeviceFolderPath + ":ITCFIFOAvailAllConfigWave") 
			ActiveDevWavePathWave[0][2] = $(DeviceFolderPath + ":ITCFIFOPositionAllConfigWave") 
			ActiveDevWavePathWave[0][3] = $(DeviceFolderPath + ":ResultsWave") 			
			ActiveDevWavePathWave[0][4] = $(DeviceFolderPath + ":ITCChanConfigWave") 
		elseif (WaveExists(root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDevWavePathWave) == 1)
			Variable numberOfRows = DimSize(ActiveDevWavePathWave, 0)
			Redimension /n = (numberOfRows + 1,5) ActiveDevWavePathWave
			ActiveDevWavePathWave[numberOfRows][0] = $(DeviceFolderPath + ":ITCDataWave") 
			ActiveDevWavePathWave[numberOfRows][1] = $(DeviceFolderPath + ":ITCFIFOAvailAllConfigWave") 
			ActiveDevWavePathWave[numberOfRows][2] = $(DeviceFolderPath + ":ITCFIFOPositionAllConfigWave") 
			ActiveDevWavePathWave[numberOfRows][3] = $(DeviceFolderPath + ":ResultsWave")
			ActiveDevWavePathWave[numberOfRows][4] = $(DeviceFolderPath + ":ITCChanConfigWave") 
		endif
	elseif (AddOrRemoveDevice == -1)
		DeletePoints /m = 0 RowToRemove, 1, ActiveDevWavePathWave
	endif
	//print "reference wave creation took (ms):", (stopmstimer(-2) - start) / 1000
End // Function ITC_MakeOrUpdtTPDevWvPth(panelTitle, AddorRemoveDevice)
//=============================================================================================================================
//BELOW  ARE THE OLD TP FUNCTIONS FOR MULTIPLE DEVICES AND YOKING.
//=============================================================================================================================

Function ITC_StartBackgroundTestPulseMD(DeviceType, DeviceNum, panelTitle)
	variable DeviceType, DeviceNum	// ITC-1600
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	string cmd
	variable i = 0
	variable StopCollectionPoint = DC_CalculateLongestSweep(panelTitle)
	variable ADChannelToMonitor = (DC_NoOfChannelsSelected("DA", "Check", panelTitle))
	variable /G root:MIES:ITCDevices:BackgroundTPCount = 0
	WAVE ITCDataWave = $WavePath + ":ITCDataWave"
	WAVE ITCFIFOAvailAllConfigWave = $WavePath + ":ITCFIFOAvailAllConfigWave"
	string  ITCDataWavePath = WavePath + ":ITCDataWave"
	string ITCChanConfigWavePath = WavePath + ":ITCChanConfigWave"
	NVAR ITCDeviceIDGlobal = $WavePath + ":ITCDeviceIDGlobal"

	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd

	sprintf cmd, "ITCconfigAllchannels, %s, %s" ITCChanConfigWavePath, ITCDataWavePath
	execute cmd
	
	ITC_MakeOrUpdateTPDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, 1)
	ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, 1)
	
	if (TP_IsBackgrounOpRunning(panelTitle, "ITC_TestPulseFuncMD") == 0)
		CtrlNamedBackground TestPulse, period = 1, proc = ITC_TestPulseFuncMD
		CtrlNamedBackground TestPulse, start
	endif
End
//======================================================================================

Function ITC_TestPulseFuncMD(s)
	STRUCT WMBackgroundStruct &s

	String cmd, Keyboard, panelTitle

	WAVE ActiveDeviceList = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDeviceList // column 0 = ITCDeviceIDGlobal; column 1 = ADChannelToMonitor; column 2 = StopCollectionPoint
	WAVE /T ActiveDeviceTextList = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDeviceTextList
	WAVE /WAVE ActiveDeviceWavePathWave = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDevWavePathWave

	variable i = 0
	variable BackgroundTPCount = 0
	variable NumberOfActiveDevices
	string WavePath
	string CountPath
	string oscilloscopeSubWindow
	variable ADChannelToMonitor
	variable StopCollectionPoint

	//	ActiveDevWavePathWave[0][0] = ITCDataWave
	//	ActiveDevWavePathWave[0][1] = ITCFIFOAvailAllConfigWave
	//	ActiveDevWavePathWave[0][2] = ITCFIFOPositionAllConfigWave
	//	ActiveDevWavePathWave[0][3] = ResultsWave
	do
		panelTitle = ActiveDeviceTextList[i]
		WavePath = HSU_DataFullFolderPathString(panelTitle)
		WAVE ITCDataWave = ActiveDeviceWavePathWave[i][0]
		WAVE ITCFIFOAvailAllConfigWave = ActiveDeviceWavePathWave[i][1]
		WAVE ITCFIFOPositionAllConfigWavePth = ActiveDeviceWavePathWave[i][2]
		WAVE ResultsWavePath = ActiveDeviceWavePathWave[i][3]
		CountPath = GetWavesDataFolder(ActiveDeviceWavePathWave[i][0],1) + "count"
		oscilloscopeSubWindow = ActiveDeviceTextList[i] + "#oscilloscope"
		ADChannelToMonitor = ActiveDeviceList[i][1]
		StopCollectionPoint = ActiveDeviceList[i][2]

		sprintf cmd, "ITCSelectDevice %d" ActiveDeviceList[i][0]
		execute cmd

		// I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		// this also seems necessary to update the DA channel data to the board!!
		sprintf cmd, "ITCUpdateFIFOPositionAll , %s" WavePath + ":ITCFIFOPositionAllConfigWave"
		execute cmd

		sprintf cmd, "ITCStartAcq /R = %d /Z = %d %d, %d, %d" 0, 0, -1, -1, 0
		Execute cmd

		do
			sprintf cmd, "ITCFIFOAvailableALL /z = 0 , %s" (WavePath + ":ITCFIFOAvailAllConfigWave")
			Execute cmd
			ITCFIFOAvailAllConfigWave[0][0]+=0
		while (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] < StopCollectionPoint)

		sprintf cmd, "ITCStopAcq /z = 0"
		Execute cmd

		sprintf cmd, "ITCConfigChannelUpload /f /z = 0" //AS Long as this command is within the do-while loop the number of cycles can be repeated
		Execute cmd

		DM_CreateScaleTPHoldingWave(panelTitle)
		TP_ClampModeString(panelTitle)
		TP_Delta(panelTitle, WavePath + ":TestPulse")

		if(mod(s.curRunTicks, 100) == 0) // switches autoscale on and off in oscilloscope Graph
			ModifyGraph /w = $oscilloscopeSubWindow Live = 0
			ModifyGraph /w = $oscilloscopeSubWindow Live = 1
		endif

		if(exists(countPath) == 0)// uses the presence of a global variable that is created by the activation of repeated aquisition to determine if the space bar can turn off the TP
			Keyboard = KeyboardState("")
			if (cmpstr(Keyboard[9], " ") == 0)	// Is space bar pressed (**note the space between the quotations)?
				panelTitle = DAP_ReturnPanelName()

				if(stringmatch(panelTitle,ActiveDeviceTextList[i]) == 1) // makes sure the panel title being passed is a data acq panel title
					beep
					ITC_MakeOrUpdateTPDevLstWave(panelTitle, ActiveDeviceList[i][0], 0, 0, -1) // ActiveDeviceList[i][0] = device ID global
					ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, -1)
					if (dimsize(ActiveDeviceTextList, 0) == 0)
						CtrlNamedBackground TestPulse, stop
						print "stopping test pulse"
						ITC_STOPTestPulseMD(panelTitle) // stops the test pulse on the top data acq panel
					endif
				endif
			endif
		endif

		NumberOfActiveDevices = numpnts(ActiveDeviceTextList)
		i += 1
	while(i < NumberOfActiveDevices)

	return 0
End
//======================================================================================

Function ITC_STOPTestPulseMD(panelTitle)
	string panelTitle
	string cmd
	// CtrlNamedBackground TestPulse, stop
	// sprintf cmd, "ITCCloseAll" 
	// execute cmd
	
	controlinfo /w = $panelTitle check_Settings_ShowScopeWindow
	if(v_value == 0)
		DAP_SmoothResizePanel(-340, panelTitle)
		setwindow $panelTitle + "#oscilloscope", hide = 1
	endif

	//DAP_RestoreTTLState(panelTitle)
	// killwaves /z root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse// this line generates an error. hence the /z. not sure why.
	ControlInfo /w = $panelTitle StartTestPulseButton
	if(V_disable == 2) // 0 = normal, 1 = hidden, 2 = disabled, visible
		Button StartTestPulseButton, win = $panelTitle, disable = 0
	endif
	
	if(V_disable == 3) // 0 = normal, 1 = hidden, 2 = disabled, visible
		V_disable = V_disable & ~0x2
		Button StartTestPulseButton, win = $panelTitle, disable =  V_disable
	endif
	killvariables /z  StopCollectionPoint, ADChannelToMonitor, BackgroundTaskActive
	killstrings /z root:MIES:ITCDevices:PanelTitleG
End


//======================================================================================
/// Takes TP  related data produced by TPDelta function and rearranges it into the correct format (for ED_CreateWaveNotes), and passes it into ED_CreateWaveNotes function
Function ITC_TPDocumentation(panelTitle) 
	string panelTitle
	string DataFolderPath = HSU_DataFullFolderPathString(panelTitle)
	dfref TPDataFolderRef = $DataFolderPath + ":TestPulse"
	
	wave /SDFR = TPDataFolderRef BaselineSSAvg // wave that contains the baseline Vm from the TP, each column is a different headstage
	wave /SDFR = TPDataFolderRef InstResistance // wave that contains the peak resistance calculation result from the TP, each column is a different headstage
	wave /SDFR = TPDataFolderRef SSResistance // wave that contains the steady state resistance calculation result from the TP, each column is a different headstage

	make /o /T /n =(3,3,1) TPDataFolderRef:TPKeyWave // 3 rows to hold: Name of parameter; unit of parameter; tolerance of parameter. 3 columns for: BaselineSSAvg; InstResistance; SSResistance.
	wave /T /SDFR = TPDataFolderRef TPKeyWave
	make /o /n =(1,3,8) TPDataFolderRef:TPSettingsWave = nan // 1 row to hold values. 3 columns for BaselineSSAvg; InstResistance; SSResistance. A layer for each headstage.
	wave /SDFR = TPDataFolderRef TPSettingsWave
	
	// add data to TPKeyWave
	TPKeyWave[0][0] = "TP Baseline Vm"
	TPKeyWave[0][1] = "TP Peak Resistance"
	TPKeyWave[0][2] = "TP Steady State Resistance"
	
	TPKeyWave[1][0] = "mV"
	TPKeyWave[1][1] = "Mohm"
	TPKeyWave[1][2] = "Mohm"
	
	controlinfo /w = $panelTitle setvar_Settings_TP_RTolerance // get tolerances from locked DA_Ephys GUI
	ASSERT(V_Flag > 0, "Non-existing control or window")
	variable RTolerance = v_value
	TPKeyWave[2][0] = "1" // Assume a tolerance of 1 mV for V rest
	TPKeyWave[2][1] = num2str(RTolerance) // applies the same R tolerance for the instantaneous and steady state resistance
	TPKeyWave[2][2] = num2str(RTolerance)
			
	// add data to TPSettingsWave
	variable i = 0
	variable j
	Wave statusHS = DC_ControlStatusWave(panelTitle, "DataAcq_HS")
	variable numHS = DimSize(statusHS, ROWS)
	for(i = 0; i < numHS; i += 1)
		if(!statusHS[i])
			continue
		endif

		TPSettingsWave[0][0][i] = BaselineSSAvg[0][j] // i places data in appropriate layer; layer corresponds to headstage number
		TPSettingsWave[0][1][i] = InstResistance[0][j]
		TPSettingsWave[0][2][i] = SSResistance[0][j]
		j += 1 //  BaselineSSAvg, InstResistance, SSResistance only have a column for each active heastage (no place holder columns), j only increments for active headstages.
	endfor

	controlinfo /w = $panelTitle SetVar_Sweep // Determine the number of the next sweep to be acquired.
	ASSERT(V_Flag > 0, "Non-existing control or window")
	
	variable NextSweep = v_value
	variable lastSweep = NextSweep - 1
	
	if(NextSweep == 0) // adds to settings history wave if no data has been acquired
		ED_createWaveNotes(TPSettingsWave, TPKeyWave, "", nan, panelTitle)
	else // adds to settings history wave if data has been acquired
		string SweepName //= DataFolderPath + ":Sweep+_" + num2str(LastSweep)
		sprintf SweepName, "%s:Data:Sweep_%d" DataFolderPath, LastSweep
		ASSERT(waveexists($SweepName) > 0, "Sweep/Wave does not exist")
		print sweepname
		ED_createWaveNotes(TPSettingsWave, TPKeyWave, SweepName , lastSweep, panelTitle)
	endif
	
End


