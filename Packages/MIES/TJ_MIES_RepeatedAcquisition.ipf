#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//this proc gets activated after first trial is already acquired if repeated acquisition is on.
// it looks like the test pulse is always run in the ITI!!! it should be user selectable
Function RA_Start(panelTitle)
	string panelTitle
	variable ITI
	variable IndexingState
	variable i = 0
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	wave TestPulseITC = $WavePath + ":TestPulse:TestPulseITC"
	string CountPath = WavePath + ":Count"
	variable /g $CountPath = 0
	NVAR Count = $CountPath
	NVAR ITCDeviceIDGlobal = $WavePath + ":ITCDeviceIDGlobal"
	string ActiveSetCountPath = WavePath + ":ActiveSetCount"
	controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
	variable /g $ActiveSetCountPath = v_value
	NVAR ActiveSetCount = $ActiveSetCountPath
	controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats// the active set count is multiplied by the times the set is to repeated
	ActiveSetCount *= v_value
	//ActiveSetCount -= 1
	variable TotTrials
	
	controlinfo /w = $panelTitle popup_MoreSettings_DeviceType
	variable DeviceType = v_value - 1
	controlinfo /w = $panelTitle popup_moreSettings_DeviceNo
	variable DeviceNum = v_value - 1
	
	controlinfo /w = $panelTitle Check_DataAcq_Indexing
	if(v_value == 0)
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
		TotTrials = v_value
		controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
		TotTrials = (TotTrials * v_value)//+1
	else
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsInSet
		TotTrials = v_value
	endif
	
	//controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
	//TotTrials = (TotTrials * v_value) + 1
	
	//Count += 1
	//ActiveSetCount -= 1
	ValDisplay valdisp_DataAcq_TrialsCountdown win = $panelTitle, value = _NUM:(TotTrials - (Count))//updates trials remaining in panel
	
	controlinfo /w = $panelTitle SetVar_DataAcq_ITI
	ITI = v_value
	
	controlinfo /w = $panelTitle Check_DataAcq_Indexing
	IndexingState = v_value
	

		DAP_StoreTTLState(panelTitle)//preparations for test pulse begin here
		DAP_TurnOffAllTTLs(panelTitle)
		string TestPulsePath = "root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse"
		make /o /n = 0 $TestPulsePath
		wave TestPulse = $TestPulsePath
		SetScale /P x 0, 0.005, "ms", TestPulse
		TP_UpdateTestPulseWave(TestPulse,panelTitle)

		make /free /N=(NUM_DA_TTL_CHANNELS) SelectedDACWaveList
		TP_StoreSelectedDACWaves(SelectedDACWaveList,panelTitle)
		TP_SelectTestPulseWave(panelTitle)

		make /free /N=(NUM_DA_TTL_CHANNELS) SelectedDACScale
		TP_StoreDAScale(SelectedDACScale, panelTitle)
		TP_SetDAScaleToOne(panelTitle)
		DC_ConfigureDataForITC(panelTitle, TEST_PULSE_MODE)

		SCOPE_CreateGraph(TestPulseITC, panelTitle)

		ITI -= ITC_StopITCDeviceTimer(panelTitle)

		ITC_StartBackgroundTestPulse(panelTitle)// modify thes line and the next to make the TP during ITI a user option
		ITC_StartBackgroundTimer(ITI, "ITC_STOPTestPulse(\"" + panelTitle + "\")", "RA_Counter(" + num2str(DeviceType) + "," + num2str(DeviceNum) + ",\"" + panelTitle + "\")", "", panelTitle)
		
		TP_ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
		TP_RestoreDAScale(SelectedDACScale,panelTitle)
End
//====================================================================================================

Function RA_Counter(DeviceType,DeviceNum,panelTitle)
	variable DeviceType,DeviceNum
	string panelTitle
	variable TotTrials
	variable ITI
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	wave TestPulseITC = $WavePath + ":TestPulse:TestPulseITC"
	wave TestPulse = root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse
	string CountPath = WavePath + ":Count"
	NVAR Count = $CountPath
	string ActiveSetCountPath = WavePath + ":ActiveSetCount"
	NVAR ActiveSetCount = $ActiveSetCountPath
	NVAR ITCDeviceIDGlobal = $WavePath + ":ITCDeviceIDGlobal"

	Count += 1
	ActiveSetCount -= 1
	
	controlinfo/w = $panelTitle Check_DataAcq_Indexing
	if(v_value == 0)
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
		TotTrials = v_value
		controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
		TotTrials = (TotTrials * v_value)//+1
	else
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsInSet
		TotTrials = v_value
	endif
	//print "TotTrials = " + num2str(tottrials)
	print "count = " + num2str(count), "in RA_Counter"
	//controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
	//TotTrials = (TotTrials * v_value) + 1
	
	controlinfo /w = $panelTitle SetVar_DataAcq_ITI
	ITI = v_value
	ValDisplay valdisp_DataAcq_TrialsCountdown win = $panelTitle, value = _NUM:(TotTrials - (Count))// reports trials remaining
	
	controlinfo /w = $panelTitle Check_DataAcq_Indexing
	If(v_value == 1)// if indexing is activated, indexing is applied.
		if(count == 1)
			IDX_MakeIndexingStorageWaves(panelTitle)
			IDX_StoreStartFinishForIndexing(panelTitle)
		endif
		//print "active set count "+num2str(activesetcount)
		if(activeSetcount == 0)//mod(Count,v_value)==0)
			controlinfo /w = $panelTitle Check_DataAcq1_IndexingLocked
			if(v_value == 1)//indexing is locked
				print "Index Step taken"
				IDX_IndexingDoIt(panelTitle)//IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
			endif	

			valdisplay valdisp_DataAcq_SweepsActiveSet win=$panelTitle, value=_NUM:IDX_MaxNoOfSweeps(panelTitle,1)
			controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
			activeSetCount = v_value
			controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats// the active set count is multiplied by the times the set is to repeated
			ActiveSetCount *= v_value
		endif
		
		controlinfo /w = $panelTitle Check_DataAcq1_IndexingLocked
		if(v_value == 0)// indexing is not locked = channel indexes when set has completed all its steps
			//print "should have indexed independently"
			IDX_ApplyUnLockedIndexing(panelTitle, count, 0)
			IDX_ApplyUnLockedIndexing(panelTitle, count, 1)
		endif
	endif
	
	if(Count < TotTrials)
		DC_ConfigureDataForITC(panelTitle, DATA_ACQUISITION_MODE)
		SCOPE_CreateGraph(ITCDataWave, panelTitle)
	
		ControlInfo /w = $panelTitle Check_Settings_BackgrndDataAcq
		If(v_value == 0)//No background aquisition
			ITC_DataAcq(panelTitle)
			if(Count < (TotTrials - 1)) //prevents test pulse from running after last trial is acquired
				DAP_StoreTTLState(panelTitle)
				DAP_TurnOffAllTTLs(panelTitle)
				
				string TestPulsePath = "root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse"
				make /o /n = 0 $TestPulsePath
				wave TestPulse = root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse
				SetScale /P x 0, 0.005, "ms", TestPulse
				TP_UpdateTestPulseWave(TestPulse, panelTitle)
				
				make /free /N=(NUM_DA_TTL_CHANNELS) SelectedDACWaveList
				TP_StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
				TP_SelectTestPulseWave(panelTitle)
			
				make /free /N=(NUM_DA_TTL_CHANNELS) SelectedDACScale
				TP_StoreDAScale(SelectedDACScale, panelTitle)
				TP_SetDAScaleToOne(panelTitle)
				DC_ConfigureDataForITC(panelTitle, TEST_PULSE_MODE)
				SCOPE_CreateGraph(TestPulseITC,panelTitle)
				
				ITI -= ITC_StopITCDeviceTimer(panelTitle)
				ITC_StartBackgroundTestPulse(panelTitle)
				ITC_StartBackgroundTimer(ITI, "ITC_STOPTestPulse(" + "\"" + panelTitle+"\"" + ")", "RA_Counter(" + num2str(DeviceType) + "," + num2str(DeviceNum) + ",\"" + panelTitle + "\")", "", panelTitle)
				
				TP_ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
				TP_RestoreDAScale(SelectedDACScale, panelTitle)
			else
				DAP_StopButtonToAcqDataButton(panelTitle)
				ITC_StopITCDeviceTimer(panelTitle)
				NVAR DataAcqState = $GetDataAcqState(panelTitle)
				DataAcqState = 0
				print "Repeated acquisition is complete"
				Killvariables Count
				killvariables /z Start, RunTime
				Killstrings /z FunctionNameA, FunctionNameB//, FunctionNameC
			endif
		else //background aquisition is on
				print "about in initate bkcrdDataAcq"
				ITC_BkrdDataAcq(panelTitle)
		endif
	endif
End

//====================================================================================================

Function RA_BckgTPwithCallToRACounter(panelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave TestPulseITC = $WavePath+":TestPulse:TestPulseITC"
	wave TestPulse = root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse
	variable ITI
	variable TotTrials
	string CountPath = WavePath + ":Count"
	NVAR Count = $CountPath
		
	controlinfo /w = $panelTitle popup_MoreSettings_DeviceType
	variable DeviceType = v_value - 1
	controlinfo /w = $panelTitle popup_moreSettings_DeviceNo
	variable DeviceNum = v_value - 1
	
	controlinfo /w = $panelTitle Check_DataAcq_Indexing
	if(v_value == 0)
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
		TotTrials = v_value
		controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
		TotTrials = (TotTrials * v_value)//+1
	else
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsInSet
		TotTrials = v_value
	endif
	
	//controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
	//TotTrials = (TotTrials * v_value) + 1
	
	controlinfo /w = $panelTitle SetVar_DataAcq_ITI
	ITI = v_value
			
	if(Count < (TotTrials - 1))
		DAP_StoreTTLState(panelTitle)
		DAP_TurnOffAllTTLs(panelTitle)
		
		string TestPulsePath = "root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse"
		make /o /n = 0 $TestPulsePath
		wave TestPulse = root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse
		SetScale/P x 0, 0.005, "ms", TestPulse
		TP_UpdateTestPulseWave(TestPulse, panelTitle)
		
		make /free /N=(NUM_DA_TTL_CHANNELS) SelectedDACWaveList
		TP_StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
		TP_SelectTestPulseWave(panelTitle)
	
		make /free /N=(NUM_DA_TTL_CHANNELS) SelectedDACScale
		TP_StoreDAScale(SelectedDACScale, panelTitle)
		TP_SetDAScaleToOne(panelTitle)
		DC_ConfigureDataForITC(panelTitle, TEST_PULSE_MODE)
		SCOPE_CreateGraph(TestPulseITC, panelTitle)
		ITC_TPDocumentation(panelTitle) // documents the TP Vrest, peak and steady state resistance values. from the last time the TP was run. Should append them to the subsequent sweep

		ITI -= ITC_StopITCDeviceTimer(panelTitle)
		ITC_StartBackgroundTestPulse(panelTitle)
		ITC_StartBackgroundTimer(ITI, "ITC_StopTestPulse(\"" + panelTitle + "\")", "RA_Counter(" + num2str(DeviceType) + "," + num2str(DeviceNum) + ",\"" + panelTitle + "\")", "", panelTitle)
		
		TP_ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
		TP_RestoreDAScale(SelectedDACScale, panelTitle)
	else
		ITC_TPDocumentation(panelTitle) // documents the TP Vrest, peak and steady state resistance values. from the last time the TP was run. Should append them to the subsequent sweep
		DAP_StopButtonToAcqDataButton(panelTitle) // 
		ITC_StopITCDeviceTimer(panelTitle)
		NVAR DataAcqState = $GetDataAcqState(panelTitle)
		DataAcqState = 0
		print "Repeated acquisition is complete"
		Killvariables Count
		killvariables /z Start, RunTime
		Killstrings /z FunctionNameA, FunctionNameB//, FunctionNameC
		killwaves /f TestPulse
	endif
End
//====================================================================================================

Function RA_StartMD(panelTitle)
	string panelTitle
	variable ITI
	// variable IndexingState
	variable i = 0
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	wave TestPulseITC = $WavePath + ":TestPulse:TestPulseITC"
	string CountPathString
	sprintf  CountPathString, "%s:Count"  WavePath
	variable /g $CountPathString = 0
	print "count global variable was created here:",CountPathString
	NVAR Count = $CountPathString
	string ActiveSetCountPath = WavePath + ":ActiveSetCount"
	controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
	variable /g $ActiveSetCountPath = v_value
	NVAR ActiveSetCount = $ActiveSetCountPath
	controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats// the active set count is multiplied by the times the set is to repeated
	ActiveSetCount *= v_value
	//ActiveSetCount -= 1
	variable TotTrials
	
	// gets info from controls
	controlinfo /w = $panelTitle popup_MoreSettings_DeviceType
	variable DeviceType = v_value - 1
	controlinfo /w = $panelTitle popup_moreSettings_DeviceNo
	variable DeviceNum = v_value - 1
	
	// makes adjustments for indexing being on or off
	controlinfo /w = $panelTitle Check_DataAcq_Indexing
	if(v_value == 0)
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
		TotTrials = v_value
		controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
		TotTrials = (TotTrials * v_value) // + 1
	else
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsInSet
		TotTrials = v_value
	endif
	
	// if the device is an ITC1600 it will handle follower or independent devices
	if(DeviceType == 2)

		
		controlinfo /w = $panelTitle setvar_Hardware_Status
		string ITCDACStatus = s_value	

		SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
		if(SVAR_exists(listOfFollowerDevices) && stringmatch(ITCDACStatus, "Independent") != 1)  // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
			variable numberOfFollowerDevices = itemsinlist(listOfFollowerDevices)
			if(numberOfFollowerDevices != 0) 
				string followerPanelTitle
				variable followerTotTrials
				
				do // handles status update of variables that are used for indexing on follower devices
					followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
					print "follower panel title =", followerPanelTitle
					
					controlinfo /w = $followerPanelTitle Check_DataAcq_Indexing
					if(v_value == 0)
						controlinfo /w = $followerPanelTitle valdisp_DataAcq_SweepsActiveSet
						followerTotTrials = v_value
						controlinfo /w = $followerPanelTitle SetVar_DataAcq_SetRepeats
						followerTotTrials = (followerTotTrials * v_value) // + 1
					else
						controlinfo /w = $followerPanelTitle valdisp_DataAcq_SweepsInSet
						followerTotTrials = v_value
					endif
				
					TotTrials = max(TotTrials, followerTotTrials)
					ValDisplay valdisp_DataAcq_TrialsCountdown win = $followerPanelTitle, value = _NUM:(TotTrials - (Count)) // updates a status value on follower panels
					
					WavePath = HSU_DataFullFolderPathString(followerPanelTitle)
					sprintf  CountPathString, "%s:Count"  WavePath
					variable /g $CountPathString = 0
					NVAR /z followerCount = $CountPathString
					
					i += 1
			
				while(i < numberOfFollowerDevices)
				
			
			endif
		endif
	endif
	
	ValDisplay valdisp_DataAcq_TrialsCountdown win = $panelTitle, value = _NUM:(TotTrials - (Count)) // updates trials remaining in panel
	
	controlinfo /w = $panelTitle SetVar_DataAcq_ITI
	ITI = v_value
	
//	controlinfo /w = $panelTitle Check_DataAcq_Indexing
//	IndexingState = v_value
//	Print "run time:", ITC_StopITCDeviceTimer(panelTitle)
		//Print "run time:", ITC_StopITCDeviceTimer(panelTitle)
		ITI -= ITC_StopITCDeviceTimer(panelTitle)


//	ITI -= ITC_StopITCDeviceTimer(panelTitle)
	StartTestPulse(deviceType, deviceNum, panelTitle)  // 
	print " in	RA_StartMD:", panelTitle, "Count =", "count, TP was just started"
	ITC_StartBackgroundTimerMD(ITI,"ITCStopTP(\"" + panelTitle + "\")", "RA_CounterMD(" + num2str(DeviceType) + "," + num2str(DeviceNum) + ",\"" + panelTitle + "\")",  "", panelTitle)
	// ITC_StartBackgroundTimer(ITI, "ITC_STOPTestPulse(\"" + panelTitle + "\")", "RA_Counter(" + num2str(DeviceType) + "," + num2str(DeviceNum) + ",\"" + panelTitle + "\")", "", panelTitle)
	// wave SelectedDACWaveList = $(WavePath + ":SelectedDACWaveList")
	// wave SelectedDACScale = $(WavePath + ":SelectedDACScale")
	// TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
	// TP_RestoreDAScale(SelectedDACScale,panelTitle)	

End
//====================================================================================================

Function RA_CounterMD(DeviceType,DeviceNum,panelTitle)
	variable DeviceType,DeviceNum
	string panelTitle
	variable TotTrials
	variable ITI
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	wave TestPulseITC = $WavePath + ":TestPulse:TestPulseITC"
	wave TestPulse = root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse
	string CountPathString
	sprintf CountPathString, "%s:Count" WavePath
	NVAR Count = $CountPathString
	string ActiveSetCountPath = WavePath + ":ActiveSetCount"
	NVAR ActiveSetCount = $ActiveSetCountPath
	variable i = 0
	Count += 1
	ActiveSetCount -= 1
	
	controlinfo/w = $panelTitle Check_DataAcq_Indexing
	if(v_value == 0)
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
		TotTrials = v_value
		controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
		TotTrials = (TotTrials * v_value)//+1
	else
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsInSet
		TotTrials = v_value
	endif
	//print "TotTrials = " + num2str(tottrials)
	print "count = " + num2str(count), "in RA_CounterMD"
	//controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
	//TotTrials = (TotTrials * v_value) + 1
	
	controlinfo /w = $panelTitle SetVar_DataAcq_ITI
	ITI = v_value
	ValDisplay valdisp_DataAcq_TrialsCountdown win = $panelTitle, value = _NUM:(TotTrials - (Count))// reports trials remaining
	
	controlinfo /w = $panelTitle Check_DataAcq_Indexing
	If(v_value == 1)// if indexing is activated, indexing is applied.
		if(count == 1)
			IDX_MakeIndexingStorageWaves(panelTitle)
			IDX_StoreStartFinishForIndexing(panelTitle)
		endif
		//print "active set count "+num2str(activesetcount)
		if(activeSetcount == 0)//mod(Count,v_value)==0)
			controlinfo /w = $panelTitle Check_DataAcq1_IndexingLocked
			if(v_value == 1)//indexing is locked
				print "Index Step taken"
				IDX_IndexingDoIt(panelTitle) //
			endif	

			valdisplay valdisp_DataAcq_SweepsActiveSet win=$panelTitle, value=_NUM:IDX_MaxNoOfSweeps(panelTitle,1)
			controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
			activeSetCount = v_value
			controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats// the active set count is multiplied by the times the set is to repeated
			ActiveSetCount *= v_value
		endif
		
		controlinfo /w = $panelTitle Check_DataAcq1_IndexingLocked
		if(v_value == 0)// indexing is not locked = channel indexes when set has completed all its steps
			//print "unlocked indexing about to be initiated"
			IDX_ApplyUnLockedIndexing(panelTitle, count, 0)
			IDX_ApplyUnLockedIndexing(panelTitle, count, 1)
		endif
	endif
	
	if(DeviceType == 2)
	
		controlinfo /w = $panelTitle setvar_Hardware_Status
		string ITCDACStatus = s_value	

		SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
		if(SVAR_Exists(listOfFollowerDevices) && stringmatch(ITCDACStatus, "Independent") != 1)
			variable numberOfFollowerDevices = itemsinlist(listOfFollowerDevices)
			if(numberOfFollowerDevices != 0) 
				string followerPanelTitle
				variable followerTotTrials
				
				do
					followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
					print "follower panel title =", followerPanelTitle
					
					WavePath = HSU_DataFullFolderPathString(followerPanelTitle)
					sprintf CountPathString, "%s:Count" WavePath
					NVAR /z FollowerCount = $CountPathString
					FollowerCount += 1
					
					controlinfo /w = $followerPanelTitle Check_DataAcq_Indexing
					if(v_value == 0)
						controlinfo /w = $followerPanelTitle valdisp_DataAcq_SweepsActiveSet
						followerTotTrials = v_value
						controlinfo /w = $followerPanelTitle SetVar_DataAcq_SetRepeats
						followerTotTrials = (followerTotTrials * v_value) // + 1
					else
						controlinfo /w = $followerPanelTitle valdisp_DataAcq_SweepsInSet
						followerTotTrials = v_value
					endif
				
					TotTrials = max(TotTrials, followerTotTrials)
					ValDisplay valdisp_DataAcq_TrialsCountdown win = $followerPanelTitle, value = _NUM:(TotTrials - (Count))
					
					controlinfo /w = $followerPanelTitle Check_DataAcq_Indexing
					If(v_value == 1)// if indexing is activated, indexing is applied.
						if(count == 1)
							IDX_MakeIndexingStorageWaves(followerPanelTitle)
							IDX_StoreStartFinishForIndexing(followerPanelTitle)
						endif
						//print "active set count "+num2str(activesetcount)
						if(activeSetcount == 0)//mod(Count,v_value)==0)
							controlinfo /w = $followerPanelTitle Check_DataAcq1_IndexingLocked
							if(v_value == 1)//indexing is locked
								print "Index Step taken"
								IDX_IndexingDoIt(followerPanelTitle) //
							endif	
							variable followerActiveSetCount
							valdisplay valdisp_DataAcq_SweepsActiveSet win=$followerPanelTitle, value=_NUM:max(IDX_MaxNoOfSweeps(panelTitle,1), IDX_MaxNoOfSweeps(followerPanelTitle,1))
							valdisplay valdisp_DataAcq_SweepsActiveSet win=$panelTitle, value=_NUM:max(IDX_MaxNoOfSweeps(panelTitle,1), IDX_MaxNoOfSweeps(followerPanelTitle,1))
							controlinfo /w = $followerPanelTitle valdisp_DataAcq_SweepsActiveSet
							followerActiveSetCount = v_value
							controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats// the lead panel determines the repeats so panelTitle is correct here
							followerActiveSetCount *= v_value
						endif
						
						ActiveSetCount = max(ActiveSetCount, followerActiveSetCount)
						
						controlinfo /w = $panelTitle Check_DataAcq1_IndexingLocked
						if(v_value == 0)// indexing is not locked = channel indexes when set has completed all its steps
							//print "unlocked indexing about to be initiated"
							IDX_ApplyUnLockedIndexing(followerPanelTitle, count, 0)
							IDX_ApplyUnLockedIndexing(followerPanelTitle, count, 1)
						endif
					endif					
					
					i += 1
				
				while(i < numberOfFollowerDevices)
			
			endif
		endif
	endif

	if(Count < TotTrials)
		variable DataAcqOrTP = 0
		print "about in initate bkcrdDataAcq"
		FunctionStartDataAcq(deviceType, deviceNum, panelTitle)
	endif
End

//====================================================================================================
Function RA_BckgTPwithCallToRACounterMD(panelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave TestPulseITC = $WavePath+":TestPulse:TestPulseITC"
	wave TestPulse = root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse
	variable ITI
	variable TotTrials
	string CountPathString
	sprintf countPathString, "%s:Count"  WavePath
	NVAR Count = $countPathString
	
	// get the device info: device type and device number	
	controlinfo /w = $panelTitle popup_MoreSettings_DeviceType
	variable DeviceType = v_value - 1
	controlinfo /w = $panelTitle popup_moreSettings_DeviceNo
	variable DeviceNum = v_value - 1
	
	// check if indexing is selected
	controlinfo /w = $panelTitle Check_DataAcq_Indexing
	if(v_value == 0)
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
		TotTrials = v_value
		controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
		TotTrials = (TotTrials * v_value) // + 1
	else
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsInSet
		TotTrials = v_value
	endif

	if(DeviceType == 2) // handling of  yoked ITC1600 

		controlinfo /w = $panelTitle setvar_Hardware_Status
		string ITCDACStatus = s_value	

		SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
		if(SVAR_exists(listOfFollowerDevices) && stringmatch(ITCDACStatus, "Independent") != 0)
			variable numberOfFollowerDevices = itemsinlist(listOfFollowerDevices)
			if(numberOfFollowerDevices != 0) // there are followers
				string followerPanelTitle
				variable followerTotTrials
				variable i = 0
				do
					followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
					print "follower panel title =", followerPanelTitle
					
					controlinfo /w = $followerPanelTitle Check_DataAcq_Indexing
					if(v_value == 0)
						controlinfo /w = $followerPanelTitle valdisp_DataAcq_SweepsActiveSet
						followerTotTrials = v_value
						controlinfo /w = $followerPanelTitle SetVar_DataAcq_SetRepeats
						followerTotTrials = (followerTotTrials * v_value) // + 1
					else
						controlinfo /w = $followerPanelTitle valdisp_DataAcq_SweepsInSet
						followerTotTrials = v_value
					endif
//					print "followerTotTrials =", followerTotTrials
//					print "totalTrials BEFORE MAX =", TotTrials
					TotTrials = max(TotTrials, followerTotTrials)
//					print "totalTrials AFTER MAX =", TotTrials
					// ValDisplay valdisp_DataAcq_TrialsCountdown win = $followerPanelTitle, value = _NUM:(TotTrials - (Count))
					i += 1
			
				while(i < numberOfFollowerDevices)
			
			endif
		endif
	endif	
	
	
	// determine ITI
	controlinfo /w = $panelTitle SetVar_DataAcq_ITI
	ITI = v_value
			
	if(Count < (TotTrials - 1))
		//Print "run time:", ITC_StopITCDeviceTimer(panelTitle)
		ITC_TPDocumentation(panelTitle) // documents the TP Vrest, peak and steady state resistance values. from the last time the TP was run. Should append them to the subsequent sweep

		ITI -= ITC_StopITCDeviceTimer(panelTitle)
		StartTestPulse(deviceType, deviceNum, panelTitle)
		// ITC_StartBackgroundTimer(ITI, "ITC_STOPTestPulse(\"" + panelTitle + "\")", "RA_Counter(" + num2str(DeviceType) + "," + num2str(DeviceNum) + ",\"" + panelTitle + "\")", "", panelTitle)
		ITC_StartBackgroundTimerMD(ITI,"ITCStopTP(\"" + panelTitle + "\")", "RA_CounterMD(" + num2str(DeviceType) + "," + num2str(DeviceNum) + ",\"" + panelTitle + "\")",  "", panelTitle)
//		wave SelectedDACWaveList = $(WavePath + ":SelectedDACWaveList")
//		wave SelectedDACScale = $(WavePath + ":SelectedDACScale")
//		TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
//		TP_RestoreDAScale(SelectedDACScale,panelTitle)		
		
		//killwaves/f TestPulse
	else
		ITC_TPDocumentation(panelTitle) // documents TP for run just prior to last sweep in repeated acquisition.
		print "totalTrials =", TotTrials
		DAP_StopButtonToAcqDataButton(panelTitle)
		NVAR DataAcqState = $GetDataAcqState(panelTitle)
		DataAcqState = 0
		print "Repeated acquisition is complete"
		print "**************************Killing count on:", panelTitle
		Killvariables Count
		ITC_StopITCDeviceTimer(panelTitle)
		
		if(SVAR_exists(listOfFollowerDevices) && stringmatch(ITCDACStatus, "Independent") != 1)
			print "*****************path to list of follower devices exists"
			numberOfFollowerDevices = itemsinlist(listOfFollowerDevices)
			if(numberOfFollowerDevices != 0) // there are followers
				// string followerPanelTitle
				// variable followerTotTrials
				i = 0
				do
					followerPanelTitle = stringfromlist(i,listOfFollowerDevices, ";")
					WavePath = HSU_DataFullFolderPathString(followerPanelTitle)
					sprintf CountPathString, "%s:Count" WavePath
					NVAR /z FollowerCount = $CountPathString
					print "killing:" ,CountPathString
					Killvariables FollowerCount
					i += 1
			
				while(i < numberOfFollowerDevices)
			
			endif
		endif
		
		
		//killvariables /z Start, RunTime
		//Killstrings /z FunctionNameA, FunctionNameB//, FunctionNameC
		//killwaves /f TestPulse
	endif
End
//====================================================================================================
