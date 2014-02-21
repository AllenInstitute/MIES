#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

 Function ITC_BkrdDataAcqMD(DeviceType, DeviceNum, panelTitle)
	variable DeviceType, DeviceNum
	string panelTitle
	string cmd
	variable ADChannelToMonitor = (DC_NoOfChannelsSelected("DA", "Check", panelTitle))
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath+ ":ITCDataWave"
	variable /G StopCollectionPoint = dimsize(ITCDataWave, 0) / 5 
	wave ITCFIFOAvailAllConfigWave = $WavePath + ":ITCFIFOAvailAllConfigWave"//, ChannelConfigWave, UpdateFIFOWave, RecordedWave
	
	string ITCDataWavePath = WavePath + ":ITCDataWave", ITCFIFOAvailAllConfigWavePath = WavePath + ":ITCFIFOAvailAllConfigWave"
	string ITCChanConfigWavePath = WavePath + ":ITCChanConfigWave"
	string ITCFIFOPositionAllConfigWavePth = WavePath + ":ITCFIFOPositionAllConfigWave"
	// open ITC device
	//ITCSelectDevice DeviceID
	//sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNum
	//	Execute cmd	
	NVAR ITCDeviceIDGlobal = $WavePath + ":ITCDeviceIDGlobal"
	
	
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd
	sprintf cmd, "ITCconfigAllchannels, %s, %s" ITCChanConfigWavePath, ITCDataWavePath
	execute cmd
	sprintf cmd, "ITCUpdateFIFOPositionAll , %s" ITCFIFOPositionAllConfigWavePth// I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
	execute cmd// this also seems necessary to update the DA channel data to the board!!
	sprintf cmd, "ITCStartAcq" 
	Execute cmd	
	
	ITC_MakeOrUpdateActivDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, 1)
	ITC_MakeOrUpdtActivDevListTxtWv(panelTitle, 1)
	
	if (TP_IsBackgrounOpRunning(panelTitle, "ITC_BckgrdFIFOMonitorMD") == 0)
		ITC_StartBckrdFIFOMonitorMD()
	endif
	
	End
 
	Function ITC_StartBckrdFIFOMonitorMD()
		CtrlNamedBackground ITC_FIFOMonitorMD, period = 1, proc = ITC_FIFOMonitorMD
		CtrlNamedBackground ITC_FIFOMonitorMD, start
	End // Function ITC_StartBckrdFIFOMonitorMD
	
 
 Function ITC_FIFOMonitorMD(s) // MD = Multiple Devices 
	STRUCT WMBackgroundStruct &s
	WAVE ActiveDeviceList = root:MIES:ITCDevices:ActiveITCDevices:ActiveDeviceList
	WAVE /T ActiveDeviceTextList = root:MIES:ITCDevices:ActiveITCDevices:ActiveDeviceTextList
	WAVE /Z ITCDataWave
	String cmd = ""
	Variable NumberOfActiveDevices // = numpnts(ActiveDeviceTextList)
	Variable i = 0
	String panelTitle = ""
	String WavePath = ""
	WAVE /z ITCDataWave
	WAVE /z ITCFIFOAvailConfigWave
	
	do
		NumberOfActiveDevices = numpnts(ActiveDeviceTextList)
		panelTitle = ActiveDeviceTextList[i]
		WavePath = HSU_DataFullFolderPathString(PanelTitle)
		WAVE /Z ITCDataWave = $WavePath + ":ITCDataWave", ITCFIFOAvailAllConfigWave = $WavePath + ":ITCFIFOAvailAllConfigWave"
			if(ITCFIFOAvailAllConfigWave[(ActiveDeviceList[i][1])][2] >= (ActiveDeviceList[i][2]))	// ActiveDeviceList[i][2] = ADChannelToMonitor ; ActiveDeviceList[i][2] = StopCollectionPoint
				print "stopped data acq on " + panelTitle
				ITC_MakeOrUpdateActivDevLstWave(panelTitle, ActiveDeviceList[i][0], 0, 0, -1) // removes device from list of active Devices. ActiveDeviceTextList[i] = ITCGlobalDeviceID
				ITC_MakeOrUpdtActivDevListTxtWv(panelTitle, -1)
				ITC_StopDataAcqMD(panelTitle, ActiveDeviceList[i][0]) 
				if (numpnts(ActiveDeviceTextList) == 0) 
					ITC_StopBckrdFIFOMonitorMD() // stops FIFO monitor when there are no devices left to monitor
				endif
			endif
		i += 1
	while(i < NumberOfActiveDevices)

	
End // Function ITC_FIFOMonitorMD(s)

Function ITC_StopBckrdFIFOMonitorMD()
	CtrlNamedBackground ITC_FIFOMonitorMD, stop
End // Function ITC_StopBckrdFIFOMonitorMD
	
Function ITC_StopDataAcqMD(panelTitle, ITCDeviceIDGlobal)
	String panelTitle
	Variable ITCDeviceIDGlobal
	variable DeviceType, DeviceNum
	string cmd
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	WAVE ITCDataWave = $WavePath + ":ITCDataWave"
	string CountPath = WavePath + ":count"

	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd	
	sprintf cmd, "ITCStopAcq /z = 0"
	Execute cmd

	itcdatawave[0][0] += 0//runs arithmatic on data wave to force onscreen update 
	doupdate
	
	sprintf cmd, "ITCConfigChannelUpload /f /z = 0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
	Execute cmd	
	
	//sprintf cmd, "ITCCloseAll" 
	//execute cmd
	
	ControlInfo /w = $panelTitle Check_Settings_SaveData
	If(v_value == 0)
		DM_SaveITCData(panelTitle)// saving always comes before scaling - there are two independent scaling steps
	endif
	
	 DM_ScaleITCDataWave(panelTitle)
	if(exists(CountPath) == 0)//If the global variable count does not exist, it is the first trial of repeated acquisition
	controlinfo /w = $panelTitle Check_DataAcq1_RepeatAcq
		if(v_value == 1)//repeated aquisition is selected
			RA_Start(PanelTitle)
		else
			DAP_StopButtonToAcqDataButton(panelTitle)
			NVAR /z DataAcqState = $wavepath + ":DataAcqState"
			DataAcqState = 0
		endif
	else
		//print "about to initiate RA_BckgTPwithCallToRACounter(panelTitleG)"
		RA_BckgTPwithCallToRACounter(panelTitle)//FUNCTION THAT ACTIVATES BCKGRD TP AND THEN CALLS REPEATED ACQ XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	endif
	
	//killvariables /z StopCollectionPoint, ADChannelToMonitor
	//killvariables /z  ADChannelToMonitor
	//killstrings /z PanelTitleG
END
	ITC_MakeOrUpdateActivDevLstWave
Function ITC_MakeOrUpdateActivDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, AddorRemoveDevice)
	string panelTitle
	Variable ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, AddorRemoveDevice // when removing a device only the ITCDeviceIDGlobal is needed
	string WavePath = "root:MIES:ITCDevices:ActiveITCDevices"
	WAVE /z ActiveDeviceList = $WavePath + ":ActiveDeviceList"
	if (AddorRemoveDevice == 1) // add a ITC device
		if (waveexists($WavePath + ":ActiveDeviceList") == 0) 
			Make /o /n = (1,4) $WavePath + ":ActiveDeviceList"
			WAVE /Z ActiveDeviceList = $WavePath + ":ActiveDeviceList"
			ActiveDeviceList[0, 0] = ITCDeviceIDGlobal
			ActiveDeviceList[0, 1] = ADChannelToMonitor
			ActiveDeviceList[0, 2] = StopCollectionPoint
		elseif (waveexists($WavePath + ":ActiveDeviceList") == 1)
			variable numberOfRows = DimSize(ActiveDeviceList, 0)
			Redimension /n = (numberOfRows, 4) ActiveDeviceList
			ActiveDeviceList[numberOfRows, 0] = ITCDeviceIDGlobal
			ActiveDeviceList[numberOfRows, 1] = ADChannelToMonitor
			ActiveDeviceList[numberOfRows, 2] = StopCollectionPoint
		endif
	elseif (AddorRemoveDevice == -1) // remove a ITC device
		Duplicate /FREE /r = [][0,0] ActiveDeviceList ListOfITCDeviceIDGlobal // duplicates the column that contains the global device ID's
		FindValue /I = (ITCDeviceIDGlobal) ListOfITCDeviceIDGlobal // searchs the duplicated column for the device to be turned off
		DeletePoints /m = 0 v_value, 1, ActiveDeviceList // removes the row that contains the device 
	endif
End // Function 	ITC_MakeOrUpdateActivDevLstWave(panelTitle)

 Function ITC_MakeOrUpdtActivDevListTxtWv(panelTitle, AddorRemoveDevice)
 	string panelTitle
 	Variable AddOrRemoveDevice
 	String WavePath = "root:MIES:ITCDevices:ActiveITCDevices"
 	WAVE /z /T ActiveDeviceTextList = $WavePath + ":ActiveDeviceTextList"
 	if (AddOrRemoveDevice == 1) // Add a device
 		if(WaveExists($WavePath + ":ActiveDeviceTextList") == 0)
 			Make /t /o /n = 1 $WavePath + ":ActiveDeviceTextList"
 			WAVE /Z /T ActiveDeviceTextList = $WavePath + ":ActiveDeviceTextList"
 		elseif (WaveExists($WavePath + ":ActiveDeviceTextList") == 1)
 			Variable numberOfRows = numpnts(ActiveDeviceTextList)
 			Redimension /n = (numberOfRows) ActiveDeviceTextList
 			ActiveDeviceTextList = panelTitle
 		endif
 	elseif (AddOrRemoveDevice == -1) // remove a device 
 		FindValue /Text = panelTitle ActiveDeviceTextList
 		DeletePoints /m = 0 v_value, 1, ActiveDeviceTextList
 	endif
 End // ITC_MakeOrUpdtActivDevListTxtWv(panelTitle)
 


//Function ITC_GlobalActiveDevCountUpdate(panelTitle, TPorDataAcq, Add_Remove) // TP = TestPulse = 0, DataAcq = Data acquistion = 1
	String PanelTitle
	Variable TPorDataAcq
	Variable Add_Remove // 1 to add a device; -1 to remove a device
	
	if (TPorDataAcq == 0) 
		if(NVAR_Exists(ActiveTPDevices)==0) // creates global if it does not exist.
			Variable /G ActiveTPDevices = 0
		endif
	
		NVAR ActiveTPDevices
		ActiveTPDevices += Add_Remove // Updates global to reflect the number of active devices
		
		if (ActiveTPDevices < 0) // Check to ensure the number of active devices is never less than 0
			ActiveTPDevices = 0
		endif
	
	elseif (TPorDataAcq == 1)
			if(NVAR_Exists(ActiveDataAcqDevices)==0) // creates global if it does not exist.
			Variable /G ActiveDataAcqDevices = 0
		endif
	
		NVAR ActiveDataAcqDevices
		ActiveDataAcqDevices += Add_Remove // Updates global to reflect the number of active devices
		
		if (ActiveDataAcqDevices < 0) // Check to ensure the number of active devices is never less than 0
			ActiveDataAcqDevices = 0
		endif
	endif
	
End // Function GlobalActiveDevCountUpdate(panelTitle)
