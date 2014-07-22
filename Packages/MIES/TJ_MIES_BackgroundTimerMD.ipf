#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ITC_StartBackgroundTimerMD(RunTime,FunctionNameAPassedIn, FunctionNameBPassedIn,  FunctionNameCPassedIn, panelTitle)//Function name is the name of the function you want to run after run time has elapsed
	Variable RunTime//how long you want the background timer to run in seconds
	String FunctionNameAPassedIn, FunctionNameBPassedIn, FunctionNameCPassedIn, panelTitle

	// caclulate timing parameters
	//Variable numTicks = 15		// Run every quarter second (15 ticks)
	Variable StartTicks = ticks
	Variable DurationTicks = (RunTime*60)
	Variable EndTimeTicks = StartTicks + DurationTicks
	
	// get device ID global
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	NVAR ITCDeviceIDGlobal = $WavePath + ":ITCDeviceIDGlobal"

	// create string list with function names passed in
	string ListOfFunctions = FunctionNameAPassedIn + ";" + FunctionNameBPassedIn + ";" + FunctionNameCPassedIn
	
	// Make or update waves that store parameters that the background timer references
		ITC_MakeOrUpdateTimerParamWave(panelTitle, listOfFunctions, StartTicks, DurationTicks, EndTimeTicks, 1)
	
	// Check if bacground timer operation is running. If no, start background timer operation.
	if (TP_IsBackgrounOpRunning(panelTitle, "ITC_TimerMD") == 0)
		// print "background data acq is not running"
		CtrlNamedBackground ITC_TimerMD, period = 6, proc = ITC_TimerMD // period 6 = 100 ms
		CtrlNamedBackground ITC_TimerMD, start
	endif
	
	If(RunTIme < 0)
		print "The time to configure " + panelTitle + " and the sweep time are greater than the user specified ITI"
		print "Data acquisition has not been interrupted but the actual ITI is longer than what was specified by: " + num2str(abs(RunTime)) + "seconds"
	endif
End
//=============================================================================================================================

Function ITC_TimerMD(s)
	STRUCT WMBackgroundStruct &s
	
	WAVE ActiveDevTimeParam = root:MIES:ITCDevices:ActiveITCDevices:Timer:ActiveDevTimeParam
	// column 0 = ITCDeviceIDGlobal; column 1 = Start time; column 2 = run time; column 3 = end time
	WAVE /T TimerFunctionListWave = root:MIES:ITCDevices:ActiveITCDevices:Timer:TimerFunctionListWave
	// column 0 = panel title; column 1 = list of functions
	variable DevicesWithActiveTimers = DimSize(ActiveDevTimeParam, 0)
	Variable i = 0
	Variable FunctionListCount
	string panelTitle
	Variable TimeLeft
	
	do
		ActiveDevTimeParam[i][4] = (ticks - ActiveDevTimeParam[i][1])
		TimeLeft = ActiveDevTimeParam[i][2] - ActiveDevTimeParam[i][4]
		panelTitle = TimerFunctionListWave[i][0]
		if(TimeLeft <= 0)
			TimeLeft = 0
					do 
						Execute stringfromlist(FunctionListCount, TimerFunctionListWave[i][1], ";")
						FunctionListCount +=1
					while(FunctionListCount < ItemsInList(TimerFunctionListWave[i][1]))
					ITC_MakeOrUpdateTimerParamWave(TimerFunctionListWave[i][0], "", 0, 0, 0, -1)
					DevicesWithActiveTimers = DimSize(ActiveDevTimeParam, 0)
					if(DevicesWithActiveTimers == 0) // stops background timer if no more devices are in the parameter waves
						CtrlNamedBackground ITC_TimerMD, Stop
					elseif (DevicesWithActiveTimers > 0) // resets i ** NEED TO CHECK HOW REMOVING A DEVICE FROM THE START, MIDDLE OR END OF LIST AFFECTS THINGS
						i -= 1
					endif
		endif
		//print TimeLeft/60
		ValDisplay valdisp_DataAcq_ITICountdown win = $panelTitle, value = _NUM:(TimeLeft/60)
		
		i+=1
	while(i < DevicesWithActiveTimers)

	//printf "NextRunTicks %d", s.nextRunTicks
	return 0
End


// functions to execute should be in a string list - or at least not limited to a set number.
// start time for each device, end time for each device, total elapsed time
// start and end time are calculated at function call 

//=============================================================================================================================


Function ITC_StopTimerForDeviceMD(panelTitle)
	string panelTitle
	WAVE ActiveDevTimeParam = root:MIES:ITCDevices:ActiveITCDevices:Timer:ActiveDevTimeParam	

	ITC_MakeOrUpdateTimerParamWave(panelTitle, "", 0, 0, 0, -1)
	variable DevicesWithActiveTimers = DimSize(ActiveDevTimeParam, 0)
	if(DevicesWithActiveTimers == 0) // stops background timer if no more devices are in the parameter waves
		CtrlNamedBackground ITC_TimerMD, Stop
	endif
End


//=============================================================================================================================

Function ITC_MakeOrUpdateTimerParamWave(panelTitle, listOfFunctions, startTime, RunTime, EndTime, AddOrRemoveDevice)
	string panelTitle, ListOfFunctions
Variable startTime, RunTime, EndTime, AddorRemoveDevice // when removing a device only the ITCDeviceIDGlobal is needed
	Variable start = stopmstimer(-2)

	// get device ID global
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	NVAR ITCDeviceIDGlobal = $WavePath + ":ITCDeviceIDGlobal"

	WavePath = "root:MIES:ITCDevices:ActiveITCDevices:Timer"
	WAVE /z ActiveDevTimeParam = $WavePath + ":ActiveDevTimeParam"
	if (AddorRemoveDevice == 1) // add a ITC device
		if (waveexists($WavePath + ":ActiveDevTimeParam") == 0) 
			Make /o /n = (1,5) $WavePath + ":ActiveDevTimeParam"
			WAVE /Z ActiveDevTimeParam = $WavePath + ":ActiveDevTimeParam"
			ActiveDevTimeParam[0][0] = ITCDeviceIDGlobal
			ActiveDevTimeParam[0][1] = startTime
			ActiveDevTimeParam[0][2] = RunTime
			ActiveDevTimeParam[0][3] = EndTime
			//ActiveDevTimeParam[0][4] = Elapsed time - calculated by background timer
		elseif (waveexists($WavePath + ":ActiveDevTimeParam") == 1)
			variable numberOfRows = DimSize(ActiveDevTimeParam, 0)
			// print numberofrows
			Redimension /n = (numberOfRows + 1, 5) ActiveDevTimeParam
			ActiveDevTimeParam[numberOfRows][0] = ITCDeviceIDGlobal
			ActiveDevTimeParam[numberOfRows][1] = startTime
			ActiveDevTimeParam[numberOfRows][2] = RunTime
			ActiveDevTimeParam[numberOfRows][3] = EndTime
			//ActiveDevTimeParam[0][4] = Elapsed time - calculated by background timer
		endif
	elseif (AddorRemoveDevice == -1) // remove a ITC device
		Duplicate /FREE /r = [][0] ActiveDevTimeParam ListOfITCDeviceIDGlobal // duplicates the column that contains the global device ID's
		// wavestats ListOfITCDeviceIDGlobal
		// print "ITCDeviceIDGlobal = ", ITCDeviceIDGlobal
		FindValue /V = (ITCDeviceIDGlobal) ListOfITCDeviceIDGlobal // searchs the duplicated column for the device to be turned off
		variable rowToRemove = v_value
		DeletePoints /m = 0 rowToRemove, 1, ActiveDevTimeParam // removes the row that contains the device 
	endif
	//print "text wave creation took (ms):", (stopmstimer(-2) - start) / 1000
	
	ITC_MakeOrUpdtDevTimerTxtWv(panelTitle, ListOfFunctions, RowToRemove, AddorRemoveDevice)
End // Function 	ITC_MakeOrUpdateTimerParamWave
//=============================================================================================================================

 Function ITC_MakeOrUpdtDevTimerTxtWv(panelTitle, ListOfFunctions, RowToRemove, AddorRemoveDevice) // creates or updates wave that contains string of active panel title names
 	string panelTitle, ListOfFunctions
 	Variable RowToRemove, AddOrRemoveDevice
 	
 	Variable start = stopmstimer(-2)

 	String WavePath = "root:MIES:ITCDevices:ActiveITCDevices:Timer"
 	WAVE /z /T TimerFunctionListWave = $WavePath + ":TimerFunctionListWave"
 	if (AddOrRemoveDevice == 1) // Add a device
 		if(WaveExists($WavePath + ":TimerFunctionListWave") == 0)
 			Make /t /o /n = (1,2) $WavePath + ":TimerFunctionListWave"
 			WAVE /Z /T TimerFunctionListWave = $WavePath + ":TimerFunctionListWave"
 			TimerFunctionListWave[0][0] = panelTitle
 			TimerFunctionListWave[0][1] = ListOfFunctions
 		elseif (WaveExists($WavePath + ":TimerFunctionListWave") == 1)
 			Variable numberOfRows = dimSize(TimerFunctionListWave, 0)
 			//print numberofrows
 			Redimension /n = (numberOfRows + 1, 2) TimerFunctionListWave
 			TimerFunctionListWave[numberOfRows][0] = panelTitle
 			TimerFunctionListWave[numberOfRows][1] = ListOfFunctions
 		endif
 	elseif (AddOrRemoveDevice == -1) // remove a device 
 		DeletePoints /m = 0 RowToRemove, 1, TimerFunctionListWave
 	endif
 	 	print "text wave creation took (ms):", (stopmstimer(-2) - start) / 1000

 End // IITC_MakeOrUpdtDevTimerTxtWv
 
//=============================================================================================================================
/// Stores the timer number in a wave where the row number corresponds to the Device ID global.
/// This function and ITC_StopITCDeviceTimer are used to correct the ITI for the time it took to collect data, and pre and post processing of data. 
/// It allows for a real time, start to start, ITI
Function ITC_StartITCDeviceTimer(panelTitle)
	string panelTitle
	//TimerStart = startmstimer
	
	string wavePath
	sprintf wavePath, "%s" HSU_DataFullFolderPathString(panelTitle)
	string ITCDeviceIDGlobalPathString 
	sprintf ITCDeviceIDGlobalPathString, "%s:ITCDeviceIDGlobal" wavePath
	NVAR ITCDeviceIDGlobal = $ITCDeviceIDGlobalPathString
	string CycleTimeStorageWavePathString
	sprintf CycleTimeStorageWavePathString, "%s:CycleTimeStorageWave" Path_ActITCDevTestTimerFolder(panelTitle)
	
	wave /z CycleTimeStorageWave = $CycleTimeStorageWavePathString
	if(waveexists($CycleTimeStorageWavePathString) == 0)
		make /o /n =10 $CycleTimeStorageWavePathString // the size of the wave is limited by the number of igor timers. This will also limit the number of simultaneously active devices possible to 10
		wave CycleTimeStorageWave = $CycleTimeStorageWavePathString
//		setDimLabel 1, 0, TimerNumber, CycleTimeStorageWave
//		setDimLabel 0, -1, DeviceIDGlobal, CycleTimeStorageWave
	endif
	
	variable TimerNumber = startmstimer
	ASSERT(TimerNumber != -1, "No more ms timers available, Run: ITC_StopAllMSTimers() to reset")
	CycleTimeStorageWave[ITCDeviceIDGlobal] = TimerNumber // inserts the timer number into the row that corresponds to the device ID global
	
End
//=============================================================================================================================
/// Stops the timer associated with a particular device
Function ITC_StopITCDeviceTimer(panelTitle)
	string panelTitle
	string CycleTimeStorageWavePathString

	sprintf CycleTimeStorageWavePathString, "%s:CycleTimeStorageWave" Path_ActITCDevTestTimerFolder(panelTitle)
	wave CycleTimeStorageWave = $CycleTimeStorageWavePathString
	string wavePath
	sprintf wavePath, "%s" HSU_DataFullFolderPathString(panelTitle)
	string ITCDeviceIDGlobalPathString 
	sprintf ITCDeviceIDGlobalPathString, "%s:ITCDeviceIDGlobal" wavePath
	NVAR ITCDeviceIDGlobal = $ITCDeviceIDGlobalPathString
	
	variable runTime = stopmstimer(CycleTimeStorageWave[ITCDeviceIDGlobal]) / 1000000
	// print "RUN TIME=", runtime
	return runTime

End
//=============================================================================================================================
/// Stops all ms timers
Function ITC_StopAllMSTimers()
	variable i
	for(i = 0; i < 10; i += 1)
		print "ms timer", i, "stopped.", "Elapsed time:", stopmstimer(i)
	endfor
End
//=============================================================================================================================

