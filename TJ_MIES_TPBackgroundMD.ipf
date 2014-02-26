#pragma rtGlobals=3		// Use modern global access method and strict wave access.



Function ITC_StartBackgroundTestPulseMD(DeviceType, DeviceNum, panelTitle)
	variable DeviceType, DeviceNum	// ITC-1600
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	// string /G root:MIES:ITCDevices:panelTitleG //$WavePath + ":PanelTitleG" = panelTitle
	// SVAR panelTitleG = root:MIES:ITCDevices:panelTitleG// = $WavePath + ":PanelTitleG"
	string cmd
	variable i = 0
	variable StopCollectionPoint = DC_CalculateITCDataWaveLength(panelTitle) / 5
	variable ADChannelToMonitor = (DC_NoOfChannelsSelected("DA", "Check", panelTitle))
	variable /G root:MIES:ITCDevices:BackgroundTPCount = 0
	WAVE ITCDataWave = $WavePath + ":ITCDataWave"
	WAVE ITCFIFOAvailAllConfigWave = $WavePath + ":ITCFIFOAvailAllConfigWave"//
	string  ITCDataWavePath = WavePath + ":ITCDataWave", ITCChanConfigWavePath = WavePath + ":ITCChanConfigWave"
	variable ITCDeviceIDGlobal = $WavePath + ":ITCDeviceIDGlobal"
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd
	sprintf cmd, "ITCconfigAllchannels, %s, %s" ITCChanConfigWavePath, ITCDataWavePath
	execute cmd
	
	ITC_MakeOrUpdateTPDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, 1)
	ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, 1)
	
	if (TP_IsBackgrounOpRunning(panelTitle, "ITC_TestPulseFuncMD") == 0)
		CtrlNamedBackground TestPulse, period = 2, proc = ITC_TestPulseFuncMD
		CtrlNamedBackground TestPulse, start
	endif

End
//======================================================================================

Function ITC_TestPulseFuncMD(s)
	STRUCT WMBackgroundStruct &s
	String cmd, Keyboard
	
	WAVE ActiveDeviceList = root:MIES:ITCDevices:ActiveITCDevices:ActiveDeviceList // column 0 = ITCDeviceIDGlobal; column 1 = ADChannelToMonitor; column 2 = StopCollectionPoint
	WAVE /T ActiveDeviceTextList = root:MIES:ITCDevices:ActiveITCDevices:ActiveDeviceTextList
	WAVE /WAVE ActiveDeviceWavePathWave = root:MIES:ITCDevices:ActiveITCDevices:ActiveDevWavePathWave
	
		//	ActiveDevWavePathWave[0][0] = ITCDataWave
		//	ActiveDevWavePathWave[0][1] = ITCFIFOAvailAllConfigWave 
		//	ActiveDevWavePathWave[0][2] = ITCFIFOPositionAllConfigWave
		//	ActiveDevWavePathWave[0][3] = ResultsWave
	do
		string WavePath = HSU_DataFullFolderPathString(ActiveDeviceTextList[i])
		WAVE ITCDataWave = ActiveDeviceWavePathWave[i][0]
		WAVE ITCFIFOAvailAllConfigWave = ActiveDeviceWavePathWave[i][1]
		WAVE ITCFIFOPositionAllConfigWavePth = ActiveDeviceWavePathWave[i][2]
		WAVE ResultsWavePath = ActiveDeviceWavePathWave[i][3]
		string CountPath = GetWavesDataFolder(ActiveDeviceWavePathWave[i][0],1) + ":count"
		string oscilloscopeSubWindow = panelTitle + "#oscilloscope"
		Variable ADChannelToMonitor = ActiveDeviceList[i][1]
		Variable StopCollectionPoint = ActiveDeviceList[i][2]
		
		sprintf cmd, "ITCSelectDevice %d" ActiveDeviceList[i][0]// ITCDeviceIDGlobal
		execute cmd
		sprintf cmd, "ITCUpdateFIFOPositionAll , %s" ITCFIFOPositionAllConfigWavePth // I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		execute cmd// this also seems necessary to update the DA channel data to the board!!
		sprintf cmd, "ITCStartAcq"
		Execute cmd	
		
		 //ITC_StartBckgrdFIFOMonitor()
			do
				sprintf cmd, "ITCFIFOAvailableALL /z = 0 , %s" ITCFIFOAvailAllConfigWavePath
				Execute cmd	
				//doxopidle
			while (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] < StopCollectionPoint)// 
		//Check Status
		sprintf cmd, "ITCGetState /R /O /C /E %s" ResultsWavePath
		Execute cmd
		sprintf cmd, "ITCStopAcq /z = 0"
		Execute cmd
		sprintf cmd, "ITCConfigChannelUpload /f /z = 0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
		Execute cmd
		
		DM_CreateScaleTPHoldingWave(panelTitle)
		TP_ClampModeString(panelTitle)
		TP_Delta(panelTitle, WavePath + ":TestPulse") 
	
		BackgroundTPCount += 1
		if(mod(BackgroundTPCount,30) == 0 || BackgroundTPCount == 1) // switches autoscale on and off in oscilloscope Graph
			ModifyGraph /w = $oscilloscopeSubWindow Live = 0
			ModifyGraph /w = $oscilloscopeSubWindow Live = 1
		endif
		if(exists(countPath) == 0)// uses the presence of a global variable that is created by the activation of repeated aquisition to determine if the space bar can turn off the TP
			Keyboard = KeyboardState("")
			if (cmpstr(Keyboard[9], " ") == 0)	// Is space bar pressed (note the space between the quotations)?
				beep 
				ITC_STOPTestPulse(panelTitle)
			endif
		endif
					NumberOfActiveDevices = numpnts(ActiveDeviceTextList)

		i += 1

		print "background loop took (ms):", (stopmstimer(-2) - start) / 1000
		// single loop with one device takes between 26 and 98 micro seconds (micro is the correct prefix)
	while(i < NumberOfActiveDevices)	
	
	return 0
	
End
//======================================================================================

Function ITC_STOPTestPulseMD(panelTitle)
	string panelTitle
	string cmd
	CtrlNamedBackground TestPulse, stop
	//sprintf cmd, "ITCCloseAll" 
	//execute cmd

	controlinfo /w = $panelTitle check_Settings_ShowScopeWindow
	if(v_value == 0)
		DAP_SmoothResizePanel(-340, panelTitle)
		setwindow $panelTitle + "#oscilloscope", hide = 1
	endif

	DAP_RestoreTTLState(panelTitle)
	//killwaves /z root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse// this line generates an error. hence the /z. not sure why.
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

Function ITC_MakeOrUpdateTPDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, AddorRemoveDevice)
	string panelTitle
	Variable ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, AddorRemoveDevice // when removing a device only the ITCDeviceIDGlobal is needed
	Variable start = stopmstimer(-2)

	string WavePath = "root:MIES:ITCDevices:ActiveITCDevices:TestPulse"
	WAVE /z ActiveDeviceList = $WavePath + ":ActiveDeviceList"
	if (AddorRemoveDevice == 1) // add a ITC device
		if (waveexists($WavePath + ":ActiveDeviceList") == 0) 
			Make /o /n = (1,4) $WavePath + ":ActiveDeviceList"
			WAVE /Z ActiveDeviceList = $WavePath + ":ActiveDeviceList"
			ActiveDeviceList[0][0] = ITCDeviceIDGlobal
			ActiveDeviceList[0][1] = ADChannelToMonitor
			ActiveDeviceList[0][2] = StopCollectionPoint
		elseif (waveexists($WavePath + ":ActiveDeviceList") == 1)
			variable numberOfRows = DimSize(ActiveDeviceList, 0)
			// print numberofrows
			Redimension /n = (numberOfRows + 1, 4) ActiveDeviceList
			ActiveDeviceList[numberOfRows][0] = ITCDeviceIDGlobal
			ActiveDeviceList[numberOfRows][1] = ADChannelToMonitor
			ActiveDeviceList[numberOfRows][2] = StopCollectionPoint
		endif
	elseif (AddorRemoveDevice == -1) // remove a ITC device
		Duplicate /FREE /r = [][0] ActiveDeviceList ListOfITCDeviceIDGlobal // duplicates the column that contains the global device ID's
		// wavestats ListOfITCDeviceIDGlobal
		// print "ITCDeviceIDGlobal = ", ITCDeviceIDGlobal
		FindValue /V = (ITCDeviceIDGlobal) ListOfITCDeviceIDGlobal // searchs the duplicated column for the device to be turned off
		DeletePoints /m = 0 v_value, 1, ActiveDeviceList // removes the row that contains the device 
	endif
	print "text wave creation took (ms):", (stopmstimer(-2) - start) / 1000
End // Function 	ITC_MakeOrUpdateTPDevLstWave(panelTitle)
//=============================================================================================================================

 Function ITC_MakeOrUpdtTPDevListTxtWv(panelTitle, AddorRemoveDevice)
 	string panelTitle
 	Variable AddOrRemoveDevice
 	Variable start = stopmstimer(-2)

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
 	 		print "text wave creation took (ms):", (stopmstimer(-2) - start) / 1000

 	ITC_MakeOrUpdtActDevWvPth(panelTitle, AddOrRemoveDevice, RowToRemove)

 End // ITC_MakeOrUpdtTPDevListTxtWv(panelTitle)
//=============================================================================================================================

Function ITC_MakeOrUpdtTPDevWvPth(panelTitle, AddOrRemoveDevice, RowToRemove)
	String panelTitle
	Variable AddOrRemoveDevice, RowToRemove
	Variable start = stopmstimer(-2)
	string DeviceFolderPath = HSU_DataFullFolderPathString(panelTitle)
	WAVE /Z /WAVE ActiveDevWavePathWave = root:MIES:ITCDevices:ActiveITCDevices:TestPulse:ActiveDevWavePathWave
	if (AddOrRemoveDevice == 1) 
		if (WaveExists(root:MIES:ITCDevices:ActiveITCDevices:ActiveDevWavePathWave) == 0)
			Make /WAVE /n = (1,4) root:MIES:ITCDevices:ActiveITCDevices:TestPulse:ActiveDevWavePathWave
			WAVE /Z /WAVE ActiveDevWavePathWave = root:MIES:ITCDevices:ActiveITCDevices:TestPulse:ActiveDevWavePathWave
			// print devicefolderpath + ":itcdatawave"
			ActiveDevWavePathWave[0][0] = $(DeviceFolderPath + ":ITCDataWave") 
			ActiveDevWavePathWave[0][1] = $(DeviceFolderPath + ":ITCFIFOAvailAllConfigWave") 
			ActiveDevWavePathWave[0][2] = $(DeviceFolderPath + ":ITCFIFOPositionAllConfigWave") 
			ActiveDevWavePathWave[0][3] = $(DeviceFolderPath + ":ResultsWave") 			
		elseif (WaveExists(root:MIES:ITCDevices:ActiveITCDevices:ActiveDevWavePathWave) == 1)
			Variable numberOfRows = DimSize(ActiveDevWavePathWave, 0)
			Redimension /n = (numberOfRows + 1,4) ActiveDevWavePathWave
			ActiveDevWavePathWave[numberOfRows][0] = $(DeviceFolderPath + ":ITCDataWave") 
			ActiveDevWavePathWave[numberOfRows][1] = $(DeviceFolderPath + ":ITCFIFOAvailAllConfigWave") 
			ActiveDevWavePathWave[0][2] = $(DeviceFolderPath + ":ITCFIFOPositionAllConfigWave") 
			ActiveDevWavePathWave[0][3] = $(DeviceFolderPath + ":ResultsWave")
		endif
	elseif (AddOrRemoveDevice == -1)
		DeletePoints /m = 0 RowToRemove, 1, ActiveDevWavePathWave
	endif
	print "reference wave creation took (ms):", (stopmstimer(-2) - start) / 1000
End // Function ITC_MakeOrUpdtTPDevWvPth(panelTitle, AddorRemoveDevice)
//=============================================================================================================================
