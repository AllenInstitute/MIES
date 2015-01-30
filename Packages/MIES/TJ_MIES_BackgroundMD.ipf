#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Reinitialize Device 1 with intrabox clock
// Execute "ITCInitialize /M = 1"
// Execute "ITCStartAcq 1, 256"
 
Function ITC_BkrdDataAcqMD(DeviceType, DeviceNum, TriggerMode, panelTitle) // if start time = 0 the variable is ignored
	variable DeviceType, DeviceNum, TriggerMode
	string panelTitle
//	Variable start = stopmstimer(-2)
	string cmd
	variable ADChannelToMonitor = DC_NoOfChannelsSelected("DA", panelTitle)
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	WAVE ITCDataWave = $WavePath+ ":ITCDataWave"
	variable StopCollectionPoint = ITC_CalcDataAcqStopCollPoint(panelTitle) // DC_CalculateLongestSweep(panelTitle)
	variable TimerStart

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd

	controlinfo /w =$panelTitle Check_DataAcq1_RepeatAcq
	variable RepeatedAcqOnOrOff = v_value
	
	if(TriggerMode == 0)
		if(RepeatedAcqOnOrOff == 1)
			ITC_StartITCDeviceTimer(panelTitle) // starts a timer for each ITC device. Timer is used to do real time ITI timing.
		endif
		Execute "ITCStartAcq" 
	elseif(TriggerMode > 0)
		sprintf cmd, "ITCStartAcq 1, %d" TriggerMode
		Execute cmd	
	endif
	//print "background data acquisition initialization took: ", (stopmstimer(-2) - start) / 1000, " ms"

	ITC_MakeOrUpdateActivDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, 1) // adds a device
	ITC_MakeOrUpdtActivDevListTxtWv(panelTitle, 1) // adds a device
	
	if (TP_IsBackgrounOpRunning(panelTitle, "ITC_BckgrdFIFOMonitorMD") == 0)
		// print "background data acq is not running"
		ITC_StartBckrdFIFOMonitorMD()
	endif
	//	print "background data acquisition initialization took: ", (stopmstimer(-2) - start) / 1000, " ms"
End
 //=============================================================================================================================

Function ITC_StartBckrdFIFOMonitorMD()
	CtrlNamedBackground ITC_FIFOMonitorMD, period = 1, proc = ITC_FIFOMonitorMD
	CtrlNamedBackground ITC_FIFOMonitorMD, start
End
//=============================================================================================================================
 
 Function ITC_FIFOMonitorMD(s) // MD = Multiple Devices 
	STRUCT WMBackgroundStruct &s

	DFREF activeDevices = GetActiveITCDevicesFolder()
	WAVE/SDFR=activeDevices ActiveDeviceList // column 0 = ITCDeviceIDGlobal; column 1 = ADChannelToMonitor; column 3 = StopCollectionPoint
	WAVE/SDFR=activeDevices/T ActiveDeviceTextList
	WAVE/WAVE/SDFR=activeDevices ActiveDevWavePathWave
	String cmd = ""
	Variable NumberOfActiveDevices // = numpnts(ActiveDeviceTextList)
	Variable DeviceIDGlobal
	Variable i = 0
	String panelTitle = ""
	String WavePath = ""
	String PathToITCFIFOAvailAllConfigWave
	do
		Variable start = stopmstimer(-2)
		NumberOfActiveDevices = dimsize(ActiveDeviceTextList, 0)
		//print "Number of Active Devices = ",NumberOfActiveDevices
		panelTitle = ActiveDeviceTextList[i]
		//print "panel Title = ", panelTitle
		WAVE /Z ITCDataWave = ActiveDevWavePathWave[i][0]
		WAVE /Z ITCFIFOAvailAllConfigWave = ActiveDevWavePathWave[i][1]
			//print "AD channel to monitor = ", ActiveDeviceList[i][1]
			PathToITCFIFOAvailAllConfigWave = getwavesdatafolder(ITCFIFOAvailAllConfigWave,2) // because the ITC commands cannot be run directly from functions, wave references cannot be directly passed into ITC commands. 
			
			sprintf cmd, "ITCSelectDevice %d" ActiveDeviceList[i][0]
			execute cmd
			sprintf cmd, "ITCFIFOAvailableALL/z=0, %s" PathToITCFIFOAvailAllConfigWave
			//print cmd
			Execute cmd	
			//print "FIFO available = ", ITCFIFOAvailAllConfigWave[(ActiveDeviceList[i][1])][2]
			if(ITCFIFOAvailAllConfigWave[(ActiveDeviceList[i][1])][2] >= (ActiveDeviceList[i][2]))	// ActiveDeviceList[i][1] = ADChannelToMonitor ; ActiveDeviceList[i][2] = StopCollectionPoint
				print "stopped data acq on " + panelTitle, "device ID global = ", ActiveDeviceList[i][0]
				DeviceIDGlobal = ActiveDeviceList[i][0]
				ITC_MakeOrUpdateActivDevLstWave(panelTitle, DeviceIDGlobal, 0, 0, -1) // removes device from list of active Devices. ActiveDeviceTextList[i] = ITCGlobalDeviceID
				ITC_MakeOrUpdtActivDevListTxtWv(panelTitle, -1)
				ITC_StopDataAcqMD(panelTitle, DeviceIDGlobal) 
				if (dimsize(ActiveDeviceTextList, 0) == 0) 
					print "no more active devices, stopping named background"
					CtrlNamedBackground ITC_FIFOMonitorMD, stop
					//ITC_StopBckrdFIFOMonitorMD() // stops FIFO monitor when there are no devices left to monitor
				endif
				//print "i = ",i
				NumberOfActiveDevices = numpnts(ActiveDeviceTextList)
				//print " number of active devices = ",NumberOfActiveDevices
			endif
		i += 1
		itcdatawave[0][0] += 0
		//print "background loop took (ms):", (stopmstimer(-2) - start) / 1000
		// single loop with one device takes between 26 and 98 micro seconds (micro is the correct prefix)
	while(i < NumberOfActiveDevices)
	
	return 0
End // Function ITC_FIFOMonitorMD(s)
//=============================================================================================================================

Function ITC_StopBckrdFIFOMonitorMD()
	CtrlNamedBackground ITC_FIFOMonitorMD, stop
End
//=============================================================================================================================

Function ITC_StopDataAcqMD(panelTitle, ITCDeviceIDGlobal)
	String panelTitle
	Variable ITCDeviceIDGlobal
	variable DeviceType, DeviceNum
	string cmd
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	WAVE ITCDataWave = $WavePath + ":ITCDataWave"
	string CountPath = WavePath + ":count"

	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd	
	sprintf cmd, "ITCStopAcq /z = 0"
	Execute cmd

	itcdatawave[0][0] += 0 // Force onscreen update
	
	sprintf cmd, "ITCConfigChannelUpload /f /z = 0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
	Execute cmd	
	
	ControlInfo /w = $panelTitle Check_Settings_SaveData
	If(v_value == 0)
		DM_SaveITCData(panelTitle)// saving always comes before scaling - there are two independent scaling steps, one for saved waves, one for the oscilloscope
	endif
	
	DM_ScaleITCDataWave(panelTitle)
	if(exists(CountPath) == 0)//If the global variable count does not exist, it is the first trial of repeated acquisition
	controlinfo /w = $panelTitle Check_DataAcq1_RepeatAcq
		if(v_value == 1)//repeated aquisition is selected
			// RA_StartMD(panelTitle)  // *************THIS NEEDS TO BE POSTPONED FOR YOKED DEVICES*********************************
			YokedRA_StartMD(panelTitle)
		else
			DAP_StopButtonToAcqDataButton(panelTitle)
			NVAR DataAcqState = $GetDataAcqState(panelTitle)
			DataAcqState = 0
		endif
	else
		YokedRA_BckgTPwCallToRACounter(panelTitle)
	endif
END

//=============================================================================================================================
Function ITC_TerminateOngoingDataAcqMD(panelTitle) // called to terminate ongoing data acquisition
	String panelTitle

	string cmd

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	NVAR/Z/SDFR=GetDevicePath(panelTitle) count
	NVAR DataAcqState = $GetDataAcqState(panelTitle)
	WAVE/T/SDFR=GetActiveITCDevicesFolder() ActiveDeviceTextList

	// stop data acq on device passsed in
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd	
	sprintf cmd, "ITCStopAcq /z = 0"
	Execute cmd
	
	ITC_ZeroITCOnActiveChan(panelTitle)
	
	// remove device passed in from active device lists
	ITC_MakeOrUpdateActivDevLstWave(panelTitle, ITCDeviceIDGlobal, 0, 0, -1) // removes device from list of active Devices. ActiveDeviceTextList[i] = ITCGlobalDeviceID
	ITC_MakeOrUpdtActivDevListTxtWv(panelTitle, -1)
	/// @todo It seems like stopping the follower devices is missing
	// determine if device removed was the last device on the list, if yes stop the background function
	if (dimsize(ActiveDeviceTextList, 0) == 0) 
		print "no more active devices, stopping named background"
		CtrlNamedBackground ITC_FIFOMonitorMD, stop
	endif
	
	// Save data if save data check box is selected
	ControlInfo /w = $panelTitle Check_Settings_SaveData
	If(v_value == 0)
		DM_SaveITCData(panelTitle)// saving always comes before scaling - there are two independent scaling steps
	endif
	
	// Scale the ITC Data wave for display
	DM_ScaleITCDataWave(panelTitle)
	
	// kills the global variable associated with ongoing repeated data acquisition
	if(NVAR_Exists(count))
		KillVariables count
	endif
	
	// sets the global variable that records the devices aquisition state to 0, indicating no onging acquisition.
	DataAcqState = 0
	
	// sets the state of the data acq button to reflect that data acq has terminated
	DAP_StopButtonToAcqDataButton(panelTitle)

END
//=============================================================================================================================

Function ITC_MakeOrUpdateActivDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, AddorRemoveDevice)
	string panelTitle
	Variable ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, AddorRemoveDevice // when removing a device only the ITCDeviceIDGlobal is needed

	DFREF activeDevices = GetActiveITCDevicesFolder()
	WAVE/Z/SDFR=activeDevices ActiveDeviceList
	if (AddorRemoveDevice == 1) // add a ITC device
		if (!WaveExists(ActiveDeviceList))
			Make/N=(1, 4) activeDevices:ActiveDeviceList/WAVE=ActiveDeviceList
			ActiveDeviceList[0][0] = ITCDeviceIDGlobal
			ActiveDeviceList[0][1] = ADChannelToMonitor
			ActiveDeviceList[0][2] = StopCollectionPoint
		else
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
End
//=============================================================================================================================

Function ITC_MakeOrUpdtActivDevListTxtWv(panelTitle, AddorRemoveDevice)
	string panelTitle
	Variable AddOrRemoveDevice

	DFREF activeDevices = GetActiveITCDevicesFolder()
	WAVE/Z/T/SDFR=activeDevices ActiveDeviceTextList
	if(AddOrRemoveDevice == 1) // Add a device
		if(!WaveExists(ActiveDeviceTextList))
			Make/T/N=1 activeDevices:ActiveDeviceTextList/Wave=ActiveDeviceTextList
			ActiveDeviceTextList = panelTitle
		else
			Variable numberOfRows = numpnts(ActiveDeviceTextList)
			Redimension /n = (numberOfRows + 1) ActiveDeviceTextList
			ActiveDeviceTextList[numberOfRows] = panelTitle
		endif
	elseif(AddOrRemoveDevice == -1) // remove a device
		FindValue /Text = panelTitle ActiveDeviceTextList
		Variable RowToRemove = v_value
		DeletePoints /m = 0 RowToRemove, 1, ActiveDeviceTextList
	endif

	ITC_MakeOrUpdtActDevWvPth(panelTitle, AddOrRemoveDevice, RowToRemove)
End
//=============================================================================================================================

Function ITC_MakeOrUpdtActDevWvPth(panelTitle, AddOrRemoveDevice, RowToRemove)
	String panelTitle
	Variable AddOrRemoveDevice, RowToRemove

	string DeviceFolderPath = GetDevicePathAsString(panelTitle)
	DFREF activeDevices = GetActiveITCDevicesFolder()
	WAVE/Z/WAVE/SDFR=activeDevices ActiveDevWavePathWave
	if(AddOrRemoveDevice == 1)
		if(!WaveExists(ActiveDevWavePathWave))
			Make/WAVE/N=(1, 2) activeDevices:ActiveDevWavePathWave/Wave=ActiveDevWavePathWave

			ActiveDevWavePathWave[0][0] = $(DeviceFolderPath + ":ITCDataWave") 
			ActiveDevWavePathWave[0][1] = $(DeviceFolderPath + ":ITCFIFOAvailAllConfigWave") 
		else
			Variable numberOfRows = DimSize(ActiveDevWavePathWave, 0)
			Redimension /n = (numberOfRows + 1,2) ActiveDevWavePathWave
			ActiveDevWavePathWave[numberOfRows][0] = $(DeviceFolderPath + ":ITCDataWave") 
			ActiveDevWavePathWave[numberOfRows][1] = $(DeviceFolderPath + ":ITCFIFOAvailAllConfigWave") 
		endif
	elseif(AddOrRemoveDevice == -1)
		DeletePoints /m = 0 RowToRemove, 1, ActiveDevWavePathWave
	endif
End
