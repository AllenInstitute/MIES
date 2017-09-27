#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_ITC_TIMER_MD
#endif

/// @file MIES_BackgroundTimerMD.ipf
/// @brief __ITC__ Multi device background timer related code

Function ITC_StartBackgroundTimerMD(panelTitle, runTime, funcList)
	string panelTitle, funcList
	variable runTime

	ASSERT(!isEmpty(funcList), "Empty funcList does not makse sense")

	variable StartTicks    = ticks
	variable DurationTicks = runTime / TICKS_TO_SECONDS
	variable EndTimeTicks  = StartTicks + DurationTicks
	
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	ITC_MakeOrUpdateTimerParamWave(panelTitle, funcList, StartTicks, DurationTicks, EndTimeTicks, 1)

	if(!IsBackgroundTaskRunning("ITC_TimerMD"))
		CtrlNamedBackground ITC_TimerMD, period = 6, proc = ITC_TimerMD, start
	endif
End

Function ITC_TimerMD(s)
	STRUCT WMBackgroundStruct &s

	WAVE/SDFR=GetActiveITCDevicesTimerFolder() ActiveDevTimeParam
	// column 0 = ITCDeviceIDGlobal; column 1 = Start time; column 2 = run time; column 3 = end time
	WAVE/T/SDFR=GetActiveITCDevicesTimerFolder() TimerFunctionListWave
	// column 0 = panel title; column 1 = list of functions
	variable i
	string panelTitle
	variable TimeLeft

	for(i = 0; i < DimSize(ActiveDevTimeParam, ROWS); i += 1)
		ActiveDevTimeParam[i][4] = (ticks - ActiveDevTimeParam[i][1])
		timeLeft = max(ActiveDevTimeParam[i][2] - ActiveDevTimeParam[i][4], 0)
		panelTitle = TimerFunctionListWave[i][0]

		SetValDisplay(panelTitle, "valdisp_DataAcq_ITICountdown", var = timeLeft * TICKS_TO_SECONDS)

		if(timeLeft == 0)
			ExecuteListOfFunctions(TimerFunctionListWave[i][1])
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

static Function ITC_MakeOrUpdateTimerParamWave(panelTitle, listOfFunctions, startTime, RunTime, EndTime, addOrRemoveDevice)
	string panelTitle, ListOfFunctions
	variable startTime, RunTime, EndTime, addOrRemoveDevice

	variable rowToRemove = NaN
	variable numberOfRows

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	DFREF dfr = GetActiveITCDevicesTimerFolder()

	WAVE/Z/SDFR=dfr ActiveDevTimeParam
	if(addOrRemoveDevice == 1) // add a ITC device
		if(!WaveExists(ActiveDevTimeParam))
			Make/N=(1, 5) dfr:ActiveDevTimeParam/Wave=ActiveDevTimeParam
			ActiveDevTimeParam[0][0] = ITCDeviceIDGlobal
			ActiveDevTimeParam[0][1] = startTime
			ActiveDevTimeParam[0][2] = RunTime
			ActiveDevTimeParam[0][3] = EndTime
			//ActiveDevTimeParam[0][4] = Elapsed time - calculated by background timer
		else
			numberOfRows = DimSize(ActiveDevTimeParam, ROWS)
			Redimension/N=(numberOfRows + 1, 5) ActiveDevTimeParam
			ActiveDevTimeParam[numberOfRows][0] = ITCDeviceIDGlobal
			ActiveDevTimeParam[numberOfRows][1] = startTime
			ActiveDevTimeParam[numberOfRows][2] = RunTime
			ActiveDevTimeParam[numberOfRows][3] = EndTime
			//ActiveDevTimeParam[0][4] = Elapsed time - calculated by background timer
		endif
	elseif(addOrRemoveDevice == -1) // remove a ITC device
		Duplicate/FREE/R=[][0] ActiveDevTimeParam ListOfITCDeviceIDGlobal
		FindValue/V=(ITCDeviceIDGlobal) ListOfITCDeviceIDGlobal
		rowToRemove = V_Value
		ASSERT(rowToRemove >= 0, "Trying to remove a non existing device")
		DeletePoints/M=(ROWS) rowToRemove, 1, ActiveDevTimeParam
	else
		ASSERT(0, "Invalid addOrRemoveDevice value")
	endif

	ITC_MakeOrUpdtDevTimerTxtWv(panelTitle, ListOfFunctions, rowToRemove, addOrRemoveDevice)

	WAVE/Z/SDFR=dfr ActiveDevTimeParam, TimerFunctionListWave
	ASSERT(WaveExists(ActiveDevTimeParam), "Missing wave ActiveDevTimeParam")
	ASSERT(WaveExists(TimerFunctionListWave), "Missing wave TimerFunctionListWave")
	ASSERT(DimSize(TimerFunctionListWave, ROWS) == DimSize(ActiveDevTimeParam, ROWS), "Number of rows in ActiveDevTimeParam and TimerFunctionListWave must be equal")
End

static Function ITC_MakeOrUpdtDevTimerTxtWv(panelTitle, listOfFunctions, rowToRemove, addOrRemoveDevice)
	string panelTitle, listOfFunctions
	variable rowToRemove, addOrRemoveDevice

	variable numberOfRows

	DFREF dfr = GetActiveITCDevicesTimerFolder()
	WAVE/Z/T/SDFR=dfr TimerFunctionListWave

	if(addOrRemoveDevice == 1) // Add a device
		if(!WaveExists(TimerFunctionListWave))
			Make/T/N=(1, 2) dfr:TimerFunctionListWave/Wave=TimerFunctionListWave
			TimerFunctionListWave[0][0] = panelTitle
			TimerFunctionListWave[0][1] = listOfFunctions
		else
			numberOfRows = DimSize(TimerFunctionListWave, ROWS)
			Redimension/N=(numberOfRows + 1, 2) TimerFunctionListWave
			TimerFunctionListWave[numberOfRows][0] = panelTitle
			TimerFunctionListWave[numberOfRows][1] = listOfFunctions
		endif
	elseif(addOrRemoveDevice == -1) // remove a device
		ASSERT(rowToRemove >= 0 && rowToRemove < DimSize(TimerFunctionListWave, ROWS), "Trying to remove a non existing index")
		DeletePoints/M=(ROWS) rowToRemove, 1, TimerFunctionListWave
	else
		ASSERT(0, "Invalid addOrRemoveDevice value")
	endif
End

/// @brief Stores the timer number in a wave where the row number corresponds to the Device ID global.
///
/// This function and ITC_StopITCDeviceTimer are used to correct the ITI for the time it took to collect data, and pre and post processing of data. 
/// It allows for a real time, start to start, ITI
Function ITC_StartITCDeviceTimer(panelTitle)
	string panelTitle

	string msg

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

	sprintf msg, "started timer %d", timerID
	DEBUGPRINT(msg)
End

/// @brief Stops the timer associated with a particular device
Function ITC_StopITCDeviceTimer(panelTitle)
	string panelTitle

	variable timerID
	string msg

	WAVE/Z/SDFR=GetActiveITCDevicesTimerFolder() CycleTimeStorageWave

	if(!WaveExists(CycleTimeStorageWave))
		return NaN
	endif

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	timerID = CycleTimeStorageWave[ITCDeviceIDGlobal]

	sprintf msg, "stopped timer %d", timerID
	DEBUGPRINT(msg)

	return stopmstimer(timerID) / 1000000
End

/// @brief Stops all ms timers
Function ITC_StopAllMSTimers()
	variable i

	for(i = 0; i < 10; i += 1)
		print "ms timer", i, "stopped.", "Elapsed time:", stopmstimer(i)
	endfor
End
