#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

 Function ITC_BkrdDataAcqMD(DeviceType, DeviceNum, panelTitle)
	variable DeviceType, DeviceNum
	string panelTitle
	string cmd
	variable i = 0
	//variable /G StopCollectionPoint = (DC_CalculateITCDataWaveLength(panelTitle)/4) + DC_ReturnTotalLengthIncrease(PanelTitle)
	variable /G ADChannelToMonitor = (DC_NoOfChannelsSelected("DA", "Check", panelTitle))
	string /G panelTitleG = panelTitle
	doupdate
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath+ ":ITCDataWave"
	variable /G StopCollectionPoint = dimsize(ITCDataWave, 0) / 5 
	wave ITCFIFOAvailAllConfigWave = $WavePath + ":ITCFIFOAvailAllConfigWave"//, ChannelConfigWave, UpdateFIFOWave, RecordedWave
	
	string ITCDataWavePath = WavePath + ":ITCDataWave", ITCFIFOAvailAllConfigWavePath = WavePath + ":ITCFIFOAvailAllConfigWave"
	string ITCChanConfigWavePath = WavePath + ":ITCChanConfigWave"
	string ITCFIFOPositionAllConfigWavePth = WavePath + ":ITCFIFOPositionAllConfigWave"
	// open ITC device
	//ITCSelectDevice DeviceID
	sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNum
		Execute cmd	
	sprintf cmd, "ITCconfigAllchannels, %s, %s" ITCChanConfigWavePath, ITCDataWavePath
		execute cmd
	sprintf cmd, "ITCUpdateFIFOPositionAll , %s" ITCFIFOPositionAllConfigWavePth// I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		execute cmd// this also seems necessary to update the DA channel data to the board!!
	sprintf cmd, "ITCStartAcq" 
		Execute cmd	
	ITC_StartBckgrdFIFOMonitor()
	
	End
 
 
 
 
 
 
 ITC_FIFOMonitorMD(s) // MD = Multiple Devices 
	STRUCT WMBackgroundStruct &s
	SVAR PanelTitleListG
	String cmd = ""
	Variable NumberOfListItems = ItemsInList(PanelTitleListG, ";")
	Variable i = 0
	String panelTitle = ""
	String WavePath = ""
	do
		panelTitle = StringFromList(i, PanelTitleListG, ";")
		WavePath = HSU_DataFullFolderPathString(PanelTitle)
		WAVE ITCDataWave = $WavePath + ":ITCDataWave", ITCFIFOAvailAllConfigWave = $WavePath + ":ITCFIFOAvailAllConfigWave"
		
		i += 1
	while(i < NumberOfListItems)
	
End // Function ITC_FIFOMonitorMD(s)

Function ITC_GlobalActiveDevCountUpdate(panelTitle, TPorDataAcq, Add_Remove) // TP = TestPulse = 0, DataAcq = Data acquistion = 1
	String PanelTitle = ""
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
