#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_BackgroundTimerMD.ipf
/// @brief __ITC__ Multi device background timer related code

Function ITC_StartBackgroundTimerMD(RunTime,FunctionNameAPassedIn, FunctionNameBPassedIn,  FunctionNameCPassedIn, panelTitle)//Function name is the name of the function you want to run after run time has elapsed
	Variable RunTime//how long you want the background timer to run in seconds
	String FunctionNameAPassedIn, FunctionNameBPassedIn, FunctionNameCPassedIn, panelTitle

	// caclulate timing parameters
	//Variable numTicks = 15		// Run every quarter second (15 ticks)
	Variable StartTicks = ticks
	Variable DurationTicks = (RunTime*60)
	Variable EndTimeTicks = StartTicks + DurationTicks
	
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	// create string list with function names passed in
	string ListOfFunctions = FunctionNameAPassedIn + ";" + FunctionNameBPassedIn + ";" + FunctionNameCPassedIn
	
	// Make or update waves that store parameters that the background timer references
		ITC_MakeOrUpdateTimerParamWave(panelTitle, listOfFunctions, StartTicks, DurationTicks, EndTimeTicks, 1)
	
	// Check if bacground timer operation is running. If no, start background timer operation.
	if(!IsBackgroundTaskRunning("ITC_TimerMD"))
		// print "background data acq is not running"
		CtrlNamedBackground ITC_TimerMD, period = 6, proc = ITC_TimerMD // period 6 = 100 ms
		CtrlNamedBackground ITC_TimerMD, start
	endif
	
	If(RunTIme < 0)
		print "The time to configure " + panelTitle + " and the sweep time are greater than the user specified ITI"
		print "Data acquisition has not been interrupted but the actual ITI is longer than what was specified by: " + num2str(abs(RunTime)) + "seconds"
	endif
End

Function ITC_TimerMD(s)
	STRUCT WMBackgroundStruct &s

	WAVE/SDFR=GetActiveITCDevicesTimerFolder() ActiveDevTimeParam
	// column 0 = ITCDeviceIDGlobal; column 1 = Start time; column 2 = run time; column 3 = end time
	WAVE/T/SDFR=GetActiveITCDevicesTimerFolder() TimerFunctionListWave
	// column 0 = panel title; column 1 = list of functions
	variable i, j
	string panelTitle, functionsToCall
	variable TimeLeft

	for(i = 0; i < DimSize(ActiveDevTimeParam, ROWS); i += 1)
		ActiveDevTimeParam[i][4] = (ticks - ActiveDevTimeParam[i][1])
		timeLeft = max(ActiveDevTimeParam[i][2] - ActiveDevTimeParam[i][4], 0)
		panelTitle = TimerFunctionListWave[i][0]

		ValDisplay valdisp_DataAcq_ITICountdown win = $panelTitle, value = _NUM:(TimeLeft/60)

		if(timeLeft == 0)
			functionsToCall = TimerFunctionListWave[i][1]
			for(j = 0; j < ItemsInList(functionsToCall); j += 1)
				Execute StringFromList(j, functionsToCall)
			endfor

			ITC_MakeOrUpdateTimerParamWave(panelTitle, "", 0, 0, 0, -1)

			// restart iterating over the remaining devices
			i = 0
			continue
		endif
	endfor

	if(DimSize(ActiveDevTimeParam, ROWS) == 0)
		return 1
	endif

	return 0
End

// functions to execute should be in a string list - or at least not limited to a set number.
// start time for each device, end time for each device, total elapsed time
// start and end time are calculated at function call 

Function ITC_StopTimerForDeviceMD(panelTitle)
	string panelTitle

	WAVE/SDFR=GetActiveITCDevicesTimerFolder() ActiveDevTimeParam

	ITC_MakeOrUpdateTimerParamWave(panelTitle, "", 0, 0, 0, -1)
	variable DevicesWithActiveTimers = DimSize(ActiveDevTimeParam, 0)
	if(DevicesWithActiveTimers == 0) // stops background timer if no more devices are in the parameter waves
		CtrlNamedBackground ITC_TimerMD, Stop
	endif
End

Function ITC_MakeOrUpdateTimerParamWave(panelTitle, listOfFunctions, startTime, RunTime, EndTime, AddOrRemoveDevice)
	string panelTitle, ListOfFunctions
	variable startTime, RunTime, EndTime, AddorRemoveDevice // when removing a device only the ITCDeviceIDGlobal is needed

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	DFREF activeDevicesTimer = GetActiveITCDevicesTimerFolder()

	WAVE/Z/SDFR=activeDevicesTimer ActiveDevTimeParam
	if (AddorRemoveDevice == 1) // add a ITC device
		if(!WaveExists(ActiveDevTimeParam))
			Make/N=(1, 5) activeDevicesTimer:ActiveDevTimeParam/Wave=ActiveDevTimeParam
			ActiveDevTimeParam[0][0] = ITCDeviceIDGlobal
			ActiveDevTimeParam[0][1] = startTime
			ActiveDevTimeParam[0][2] = RunTime
			ActiveDevTimeParam[0][3] = EndTime
			//ActiveDevTimeParam[0][4] = Elapsed time - calculated by background timer
		else
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
		FindValue /V = (ITCDeviceIDGlobal) ListOfITCDeviceIDGlobal // searchs the duplicated column for the device to be turned off
		variable rowToRemove = v_value
		DeletePoints /m = 0 rowToRemove, 1, ActiveDevTimeParam // removes the row that contains the device 
	endif
	
	ITC_MakeOrUpdtDevTimerTxtWv(panelTitle, ListOfFunctions, RowToRemove, AddorRemoveDevice)
End

Function ITC_MakeOrUpdtDevTimerTxtWv(panelTitle, ListOfFunctions, RowToRemove, AddorRemoveDevice) // creates or updates wave that contains string of active panel title names
	string panelTitle, ListOfFunctions
	Variable RowToRemove, AddOrRemoveDevice

	DFREF activeDevices = GetActiveITCDevicesTimerFolder()

	WAVE/Z/T/SDFR=activeDevices TimerFunctionListWave
	if(AddOrRemoveDevice == 1) // Add a device
		if(!WaveExists(TimerFunctionListWave))
			Make/T/N=(1, 2) activeDevices:TimerFunctionListWave/Wave=TimerFunctionListWave
			TimerFunctionListWave[0][0] = panelTitle
			TimerFunctionListWave[0][1] = ListOfFunctions
		else
			Variable numberOfRows = dimSize(TimerFunctionListWave, 0)
			Redimension /n = (numberOfRows + 1, 2) TimerFunctionListWave
			TimerFunctionListWave[numberOfRows][0] = panelTitle
			TimerFunctionListWave[numberOfRows][1] = ListOfFunctions
		endif
	elseif(AddOrRemoveDevice == -1) // remove a device
		DeletePoints /m = 0 RowToRemove, 1, TimerFunctionListWave
	endif
End
 

/// @brief Stores the timer number in a wave where the row number corresponds to the Device ID global.
///
/// This function and ITC_StopITCDeviceTimer are used to correct the ITI for the time it took to collect data, and pre and post processing of data. 
/// It allows for a real time, start to start, ITI
Function ITC_StartITCDeviceTimer(panelTitle)
	string panelTitle

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	DFREF timer = GetActiveITCDevicesTimerFolder()

	WAVE/Z/SDFR=timer CycleTimeStorageWave
	if(!WaveExists(CycleTimeStorageWave))
		// the size of the wave is limited by the number of igor timers.
		// This will also limit the number of simultaneously active devices possible to 10
		Make/N=10 timer:CycleTimeStorageWave/Wave=CycleTimeStorageWave
	endif

	variable timerID = startmstimer
	ASSERT(timerID != -1, "No more ms timers available, Run: ITC_StopAllMSTimers() to reset")
	CycleTimeStorageWave[ITCDeviceIDGlobal] = timerID
End

/// @brief Stops the timer associated with a particular device
Function ITC_StopITCDeviceTimer(panelTitle)
	string panelTitle

	WAVE/Z/SDFR=GetActiveITCDevicesTimerFolder() CycleTimeStorageWave

	if(!WaveExists(CycleTimeStorageWave))
		return NaN
	endif

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	return stopmstimer(CycleTimeStorageWave[ITCDeviceIDGlobal]) / 1000000
End

/// @brief Stops all ms timers
Function ITC_StopAllMSTimers()
	variable i

	for(i = 0; i < 10; i += 1)
		print "ms timer", i, "stopped.", "Elapsed time:", stopmstimer(i)
	endfor
End
