#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ITC_StartBackgroundTimerMD(RunTime,FunctionNameAPassedIn, FunctionNameBPassedIn,  FunctionNameCPassedIn, panelTitle)//Function name is the name of the function you want to run after run time has elapsed
	Variable RunTime//how long you want the background timer to run in seconds
	String FunctionNameAPassedIn, FunctionNameBPassedIn, FunctionNameCPassedIn, panelTitle

	// caclulate timing parameters
	Variable numTicks = 15		// Run every quarter second (15 ticks)
	Variable Start = ticks
	Variable Duration = (RunTime*60)
	Variable EndTime = Start + Duration
	
	// get device ID global
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	NVAR ITCDeviceIDGlobal = $WavePath + ":ITCDeviceIDGlobal"

	// create string list with function names passed in
	string ListOfFunctions = FunctionNameAPassedIn + ";" + FunctionNameBPassedIn + ";" + FunctionNameCPassedIn
	
	// 
	
	if (TP_IsBackgrounOpRunning(panelTitle, "ITC_TimerMD") == 0)
		// print "background data acq is not running"
		CtrlNamedBackground ITC_TimerMD, period = 5, proc = ITC_TimerMD
		CtrlNamedBackground ITC_TimerMD, start
	endif

End

Function ITC_TimerMD(s)
	STRUCT WMBackgroundStruct &s
	SVAR panelTitleG =  root:MIES:ITCDevices:panelTitleG
	NVAR Start = root:MIES:ITCDevices:Start, RunTime = root:MIES:ITCDevices:RunTime
	variable TimeLeft
	
	variable ElapsedTime = (ticks - Start)
	
	TimeLeft = abs(((RunTime - (ElapsedTime)) / 60))
	if(TimeLeft < 0)
		timeleft = 0
	endif
	ValDisplay valdisp_DataAcq_ITICountdown win = $panelTitleG, value = _NUM:TimeLeft
	
	if(ElapsedTime >= RunTime)
		ITC_StopBackgroundTimerTask()
	endif
	//printf "NextRunTicks %d", s.nextRunTicks
	return 0
End

Function ITC_StopBackgroundTimerTaskMD()
	SVAR FunctionNameA = root:MIES:ITCDevices:FunctionNameA
	SVAR FunctionNameB = root:MIES:ITCDevices:FunctionNameB
	SVAR FunctionNameC = root:MIES:ITCDevices:FunctionNameC
	CtrlNamedBackground ITC_Timer, stop // had incorrect background procedure name
	Execute FunctionNameA
 	Execute FunctionNameB
	//Execute FunctionNameC
	//killvariables/z Start, RunTime
	//Killstrings/z FunctionNameA, FunctionNameB, FunctionNameC
End

// functions to execute should be in a string list - or at least not limited to a set number.
// start time for each device, end time for each device, total elapsed time
// start and end time are calculated at function call 
//=============================================================================================================================

Function ITC_MakeOrUpdateTimerParamWave(panelTitle, startTime, RunTime, EndTime, AddOrRemoveDevice)
	string panelTitle, FunctionNameA, FunctionNameB, FunctionNameC
Variable startTime, RunTime, EndTime, AddorRemoveDevice // when removing a device only the ITCDeviceIDGlobal is needed
	Variable start = stopmstimer(-2)

	// get device ID global
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	NVAR ITCDeviceIDGlobal = $WavePath + ":ITCDeviceIDGlobal"

	string WavePath = "root:MIES:ITCDevices:ActiveITCDevices:Timer"
	WAVE /z ActiveDeviceList = $WavePath + ":ActiveDevTimeParam"
	if (AddorRemoveDevice == 1) // add a ITC device
		if (waveexists($WavePath + ":ActiveDevTimeParam") == 0) 
			Make /o /n = (1,5) $WavePath + ":ActiveDevTimeParam"
			WAVE /Z ActiveDevTimeParam = $WavePath + ":ActiveDevTimeParam"
			ActiveDevTimeParam[0][0] = ITCDeviceIDGlobal
			ActiveDevTimeParam[0][1] = startTime
			ActiveDevTimeParam[0][2] = RunTime
			ActiveDevTimeParam[0][3] = EndTime
			//ActiveDevTimeParam[0][3] = Elapsed time - calculated by background timer
		elseif (waveexists($WavePath + ":ActiveDevTimeParam") == 1)
			variable numberOfRows = DimSize(ActiveDevTimeParam, 0)
			// print numberofrows
			Redimension /n = (numberOfRows + 1, 4) ActiveDevTimeParam
			ActiveDevTimeParam[0][0] = ITCDeviceIDGlobal
			ActiveDevTimeParam[0][1] = startTime
			ActiveDevTimeParam[0][2] = RunTime
			ActiveDevTimeParam[0][3] = EndTime
			//ActiveDevTimeParam[0][3] = Elapsed time - calculated by background timer
		endif
	elseif (AddorRemoveDevice == -1) // remove a ITC device
		Duplicate /FREE /r = [][0] ActiveDevTimeParam ListOfITCDeviceIDGlobal // duplicates the column that contains the global device ID's
		// wavestats ListOfITCDeviceIDGlobal
		// print "ITCDeviceIDGlobal = ", ITCDeviceIDGlobal
		FindValue /V = (ITCDeviceIDGlobal) ListOfITCDeviceIDGlobal // searchs the duplicated column for the device to be turned off
		DeletePoints /m = 0 v_value, 1, ActiveDeviceList // removes the row that contains the device 
	endif
	print "text wave creation took (ms):", (stopmstimer(-2) - start) / 1000
End // Function 	ITC_MakeOrUpdateTimerParamWave
//=============================================================================================================================

 Function ITC_MakeOrUpdtDevTimerTxtWv(panelTitle, ListOfFunctions, AddorRemoveDevice) // creates or updates wave that contains string of active panel title names
 	string panelTitle, ListOfFunctions
 	Variable AddOrRemoveDevice
 	Variable start = stopmstimer(-2)

 	String WavePath = "root:MIES:ITCDevices:ActiveITCDevices:TestPulse"
 	WAVE /z /T ActiveDeviceTextList = $WavePath + ":ActiveDeviceTextList"
 	if (AddOrRemoveDevice == 1) // Add a device
 		if(WaveExists($WavePath + ":ActiveDeviceTextList") == 0)
 			Make /t /o /n = (1,2) $WavePath + ":ActiveDeviceTextList"
 			WAVE /Z /T ActiveDeviceTextList = $WavePath + ":ActiveDeviceTextList"
 			ActiveDeviceTextList[0][0] = panelTitle
 			ActiveDeviceTextList[0][1] = ListOfFunctions
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

 	ITC_MakeOrUpdtTPDevWvPth(panelTitle, AddOrRemoveDevice, RowToRemove)

 End // IITC_MakeOrUpdtDevTimerTxtWv