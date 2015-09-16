#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_BackgroundMD.ipf
/// @brief __ITC__ Multi device background data acquisition

//Reinitialize Device 1 with intrabox clock
// Execute "ITCInitialize /M = 1"
// Execute "ITCStartAcq 1, 256"
 
Function ITC_BkrdDataAcqMD(TriggerMode, panelTitle) // if start time = 0 the variable is ignored
	variable TriggerMode
	string panelTitle
//	Variable start = stopmstimer(-2)
	string cmd
	variable ADChannelToMonitor = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_DAC)
	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	variable StopCollectionPoint = DC_GetStopCollectionPoint(panelTitle, DATA_ACQUISITION_MODE)
	variable TimerStart

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	ExecuteITCOperationAbortOnError(cmd)

	controlinfo /w =$panelTitle Check_DataAcq1_RepeatAcq
	variable RepeatedAcqOnOrOff = v_value
	
	if(TriggerMode == 0)
		if(RepeatedAcqOnOrOff == 1)
			ITC_StartITCDeviceTimer(panelTitle) // starts a timer for each ITC device. Timer is used to do real time ITI timing.
		endif
		sprintf cmd, "ITCStartAcq"
		ExecuteITCOperationAbortOnError(cmd)
	elseif(TriggerMode > 0)
		sprintf cmd, "ITCStartAcq 1, %d" TriggerMode
		ExecuteITCOperationAbortOnError(cmd)
	endif
	//print "background data acquisition initialization took: ", (stopmstimer(-2) - start) / 1000, " ms"

	ITC_MakeOrUpdateActivDevLstWave(panelTitle, ITCDeviceIDGlobal, ADChannelToMonitor, StopCollectionPoint, 1) // adds a device
	ITC_MakeOrUpdtActivDevListTxtWv(panelTitle, 1) // adds a device
	
	if (IsBackgroundTaskRunning("ITC_BckgrdFIFOMonitorMD") == 0)
		// print "background data acq is not running"
		ITC_StartBckrdFIFOMonitorMD()
	endif
	//	print "background data acquisition initialization took: ", (stopmstimer(-2) - start) / 1000, " ms"
End

Function ITC_StartBckrdFIFOMonitorMD()
	CtrlNamedBackground ITC_FIFOMonitorMD, period = 1, proc = ITC_FIFOMonitorMD
	CtrlNamedBackground ITC_FIFOMonitorMD, start
End
 
Function ITC_FIFOMonitorMD(s)
	STRUCT WMBackgroundStruct &s

	DFREF activeDevices = GetActiveITCDevicesFolder()
	WAVE/SDFR=activeDevices ActiveDeviceList
	WAVE/SDFR=activeDevices/T ActiveDeviceTextList
	WAVE/WAVE/SDFR=activeDevices ActiveDevWavePathWave
	string cmd
	variable NumberOfActiveDevices
	variable DeviceIDGlobal
	variable i
	string panelTitle

	do
		NumberOfActiveDevices = DimSize(ActiveDeviceTextList, ROWS)
		panelTitle = ActiveDeviceTextList[i]

		WAVE ITCDataWave = ActiveDevWavePathWave[i][0]
		WAVE ITCFIFOAvailAllConfigWave = ActiveDevWavePathWave[i][1]

		sprintf cmd, "ITCSelectDevice %d" ActiveDeviceList[i][0]
		ExecuteITCOperationAbortOnError(cmd)
		sprintf cmd, "ITCFIFOAvailableALL/z=0, %s", GetWavesDataFolder(ITCFIFOAvailAllConfigWave,2)
		ExecuteITCOperation(cmd)
		if(ITCFIFOAvailAllConfigWave[ActiveDeviceList[i][1]][2] >= ActiveDeviceList[i][2])
			print "stopped data acq on " + panelTitle, "device ID global = ", ActiveDeviceList[i][0]
			DeviceIDGlobal = ActiveDeviceList[i][0]
			ITC_MakeOrUpdateActivDevLstWave(panelTitle, DeviceIDGlobal, 0, 0, -1)
			ITC_MakeOrUpdtActivDevListTxtWv(panelTitle, -1)
			if (DimSize(ActiveDeviceTextList, ROWS) == 0)
				print "no more active devices, stopping named background"
				CtrlNamedBackground ITC_FIFOMonitorMD, stop
			endif
			ITC_StopDataAcqMD(panelTitle, DeviceIDGlobal)
			NumberOfActiveDevices = numpnts(ActiveDeviceTextList)
		endif
		i += 1
		ITCDataWave[0][0] += 0
	while(i < NumberOfActiveDevices)

	return 0
End

Function ITC_StopDataAcqMD(panelTitle, ITCDeviceIDGlobal)
	String panelTitle
	Variable ITCDeviceIDGlobal

	string cmd
	NVAR count = $GetCount(panelTitle)
	WAVE ITCDataWave = GetITCDataWave(panelTitle)

	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	ExecuteITCOperation(cmd)
	sprintf cmd, "ITCStopAcq /z = 0"
	ExecuteITCOperation(cmd)

	itcdatawave[0][0] += 0 // Force onscreen update
	
	sprintf cmd, "ITCConfigChannelUpload /f /z = 0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
	ExecuteITCOperation(cmd)
	
	DM_SaveAndScaleITCData(panelTitle)
	if(!IsFinite(count))
		ControlInfo/W=$panelTitle Check_DataAcq1_RepeatAcq
		if(v_value == 1)//repeated aquisition is selected
			// RA_StartMD(panelTitle)  // *************THIS NEEDS TO BE POSTPONED FOR YOKED DEVICES*********************************
			DAM_YokedRAStartMD(panelTitle)
		else
			DAP_OneTimeCallAfterDAQ(panelTitle)
		endif
	else
		DAM_YokedRABckgTPCallRACounter(panelTitle)
	endif
END

Function ITC_TerminateOngoingDataAcqMD(panelTitle) // called to terminate ongoing data acquisition
	String panelTitle

	string cmd

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	NVAR/Z/SDFR=GetDevicePath(panelTitle) count
	NVAR DataAcqState = $GetDataAcqState(panelTitle)
	WAVE/T/SDFR=GetActiveITCDevicesFolder() ActiveDeviceTextList

	// stop data acq on device passsed in
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	ExecuteITCOperationAbortOnError(cmd)
	sprintf cmd, "ITCStopAcq /z = 0"
	ExecuteITCOperation(cmd)
	
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

	DM_SaveAndScaleITCData(panelTitle)

	// kills the global variable associated with ongoing repeated data acquisition
	if(NVAR_Exists(count))
		KillVariables count
	endif

	DAP_OneTimeCallAfterDAQ(panelTitle)
END

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
