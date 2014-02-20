#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

 Function ITC_BkrdDataAcqMD(DeviceType, DeviceNum, panelTitle)
	variable DeviceType, DeviceNum
	string panelTitle
	string cmd
	variable i = 0
	//variable /G StopCollectionPoint = (DC_CalculateITCDataWaveLength(panelTitle)/4) + DC_ReturnTotalLengthIncrease(PanelTitle)
	variable ADChannelToMonitor = (DC_NoOfChannelsSelected("DA", "Check", panelTitle))
	string panelTitleG = panelTitle
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
	ITC_StartBckgrdFIFOMonitor()
	
	End
 
Function ITC_CreateOrUpdateActiveDeviceListWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, AddorRemoveDevice)
	string panelTitle
	Variable panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, AddorRemoveDevice
	string WavePath = "root:MIES:ITCDevices"
	WAVE /z ActiveDeviceList = $WavePath + ":ActiveDeviceList"
	if (AddorRemoveDevice == 1) // add a ITC device
		if (waveexists($WavePath + ":ActiveDeviceList") == 0) 
			Make /o /n = (1,4) $WavePath + ":ActiveDeviceList"
			ActiveDeviceList = $WavePath + ":ActiveDeviceList"
			ActiveDeviceList[0, 0] = ITCDeviceIDGlobal
			ActiveDeviceList[0, 1] = ADChannelToMonitor
			ActiveDeviceList[0, 2] = StopCollectionPoint
		elseif (waveexists($WavePath + ActiveDeviceList) == 1)
			variable numberOfRows = DimSize(ActiveDeviceList, 0)
			Redimension /n = (numberOfRows, 4) ActiveDeviceList
			ActiveDeviceList[numberOfRows, 0] = ITCDeviceIDGlobal
			ActiveDeviceList[numberOfRows, 1] = ADChannelToMonitor
			ActiveDeviceList[numberOfRows, 2] = StopCollectionPoint
		endif
	elseif (AddorRemoveDevice == -1) // remove a ITC device
		Duplicate /FREE ActiveDeviceList[0][] ListOfITCDeviceIDGlobal // duplicates the column that contains the global device ID's
		FindValue /I = ITCDeviceIDGlobal ListOfITCDeviceIDGlobal // searchs the duplicated column for the device to be turned off
		DeletePoints /m = 0 v_value, 1, ActiveDeviceList // removes the row that contains the device 
	endif

	
End // Function ITC_CreateOrUpdateActiveDeviceWaveList(panelTitle)

 
 
 
 
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

//Function ITC_FIFOMonitor(s)
	STRUCT WMBackgroundStruct &s
	NVAR StopCollectionPoint, ADChannelToMonitor
	SVAR panelTitleG
	String cmd
	string WavePath = HSU_DataFullFolderPathString(PanelTitleG)
	Wave ITCDataWave = $WavePath + ":ITCDataWave", ITCFIFOAvailAllConfigWave= $WavePath + ":ITCFIFOAvailAllConfigWave"
	string ITCFIFOAvailAllConfigWavePath = WavePath + ":ITCFIFOAvailAllConfigWave"
	sprintf cmd, "ITCFIFOAvailableALL /z = 0 , %s" ITCFIFOAvailAllConfigWavePath
	Execute cmd	
	ITCDataWave[0][0] += 0//forces on screen update
	string OscilloscopeSubWindow = panelTitleG + "#oscilloscope"
	doupdate /w = $OscilloscopeSubWindow
	if(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] >= StopCollectionPoint)	
		print "stopped data acq"
		ITC_StopDataAcq()
		ITC_STOPFifoMonitor()
	endif
				
	return 0
//End


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
