#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static Function RA_HandleITI_MD(panelTitle)
	string panelTitle

	variable ITI
	ITI = GetSetVariable(panelTitle, "SetVar_DataAcq_ITI")
	if(!GetCheckBoxState(panelTitle, "check_Settings_ITITP"))
		ITI -= ITC_StopITCDeviceTimer(panelTitle)
		ITC_StartBackgroundTimerMD(ITI, "RA_CounterMD(\"" + panelTitle + "\")", "", "", panelTitle)
		return NaN
	endif

	ITI -= ITC_StopITCDeviceTimer(panelTitle)
	DAM_StartTestPulseMD(panelTitle)

	ITC_StartBackgroundTimerMD(ITI,"DAM_StopTPMD(\"" + panelTitle + "\")", "RA_CounterMD(\"" + panelTitle + "\")",  "", panelTitle)
End

static Function RA_HandleITI(panelTitle)
	string panelTitle

	variable ITI
	string TestPulsePath = "root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse"

	ITI = GetSetVariable(panelTitle, "SetVar_DataAcq_ITI")
	if(!GetCheckBoxState(panelTitle, "check_Settings_ITITP"))
		ITI -= ITC_StopITCDeviceTimer(panelTitle)
		ITC_StartBackgroundTimer(ITI, "RA_Counter(\"" + panelTitle + "\")", "", "", panelTitle)
		return NaN
	endif

	/// @todo create one function which does the TP initialization
	DAP_StoreTTLState(panelTitle)
	DAP_TurnOffAllTTLs(panelTitle)

	MAKE/O/N = 0 $TestPulsePath/Wave=TestPulse
	SetScale/P x 0, MINIMUM_SAMPLING_INTERVAL, "ms", TestPulse
	TP_UpdateTestPulseWave(TestPulse,panelTitle)

	MAKE/FREE/N=(NUM_DA_TTL_CHANNELS) SelectedDACWaveList
	TP_StoreSelectedDACWaves(SelectedDACWaveList,panelTitle)
	TP_SelectTestPulseWave(panelTitle)

	MAKE/FREE/N=(NUM_DA_TTL_CHANNELS) SelectedDACScale
	TP_StoreDAScale(SelectedDACScale, panelTitle)
	TP_SetDAScaleToOne(panelTitle)
	DC_ConfigureDataForITC(panelTitle, TEST_PULSE_MODE)

	WAVE TestPulseITC = GetTestPulseITCWave(panelTitle)
	SCOPE_CreateGraph(TestPulseITC, panelTitle)

	ITI -= ITC_StopITCDeviceTimer(panelTitle)

	ITC_StartBackgroundTestPulse(panelTitle)
	ITC_StartBackgroundTimer(ITI, "ITC_STOPTestPulseSingleDevice(\"" + panelTitle + "\")", "RA_Counter(\"" + panelTitle + "\")", "", panelTitle)

	TP_ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
	TP_RestoreDAScale(SelectedDACScale,panelTitle)
End

/// @brief Function gets called after the first trial is already
/// acquired and if repeated acquisition is on
Function RA_Start(panelTitle)
	string panelTitle
	variable ITI

	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	WAVE TestPulseITC = GetTestPulseITCWave(panelTitle)
	NVAR count = $GetCount(panelTitle)
	count = 0
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	string ActiveSetCountPath = GetDevicePathAsString(panelTitle) + ":ActiveSetCount"
	controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
	variable /g $ActiveSetCountPath = v_value
	NVAR ActiveSetCount = $ActiveSetCountPath
	controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats// the active set count is multiplied by the times the set is to repeated
	ActiveSetCount *= v_value
	variable TotTrials

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

	if(TotTrials == 1)
		return RA_FinishAcquisition(panelTitle)
	endif

	ValDisplay valdisp_DataAcq_TrialsCountdown win = $panelTitle, value = _NUM:(TotTrials - (Count))//updates trials remaining in panel
	RA_HandleITI(panelTitle)
End

Function RA_Counter(panelTitle)
	string panelTitle

	variable TotTrials
	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	WAVE TestPulseITC = GetTestPulseITCWave(panelTitle)
	wave TestPulse = root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse
	NVAR count = $GetCount(panelTitle)
	string ActiveSetCountPath = GetDevicePathAsString(panelTitle) + ":ActiveSetCount"
	NVAR ActiveSetCount = $ActiveSetCountPath
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

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
	
	ValDisplay valdisp_DataAcq_TrialsCountdown win = $panelTitle, value = _NUM:(TotTrials - (Count))// reports trials remaining
	
	controlinfo /w = $panelTitle Check_DataAcq_Indexing
	If(v_value == 1)// if indexing is activated, indexing is applied.
		if(count == 1)
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
				RA_HandleITI(panelTitle)
			else
				RA_FinishAcquisition(panelTitle)
			endif
		else //background aquisition is on
			ITC_BkrdDataAcq(panelTitle)
		endif
	else
		RA_FinishAcquisition(panelTitle)
	endif
End

static Function RA_FinishAcquisition(panelTitle)
	string panelTitle

	ITC_StopITCDeviceTimer(panelTitle)
	DAP_OneTimeCallAfterDAQ(panelTitle)

	KillVariables/Z Count
	KillVariables/Z Start, RunTime
	KillStrings /z FunctionNameA, FunctionNameB
End

Function RA_BckgTPwithCallToRACounter(panelTitle)
	string panelTitle

	WAVE TestPulseITC = GetTestPulseITCWave(panelTitle)
	wave TestPulse = root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse
	variable TotTrials
	NVAR count = $GetCount(panelTitle)

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
	
	if(Count < (TotTrials - 1))
		RA_HandleITI(panelTitle)
	else
		ED_TPDocumentation(panelTitle)
		DAP_OneTimeCallAfterDAQ(panelTitle)
		ITC_StopITCDeviceTimer(panelTitle)
		print "Repeated acquisition is complete"
		Killvariables Count
		killvariables /z Start, RunTime
		Killstrings /z FunctionNameA, FunctionNameB
		killwaves /f TestPulse
	endif
End
//====================================================================================================

Function RA_StartMD(panelTitle)
	string panelTitle

	variable ITI
	variable i = 0

	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	WAVE TestPulseITC = GetTestPulseITCWave(panelTitle)
	NVAR count = $GetCount(panelTitle)
	count = 0
	string ActiveSetCountPath = GetDevicePathAsString(panelTitle) + ":ActiveSetCount"
	controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
	variable /g $ActiveSetCountPath = v_value
	NVAR ActiveSetCount = $ActiveSetCountPath
	controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats// the active set count is multiplied by the times the set is to repeated
	ActiveSetCount *= v_value
	variable TotTrials
	
	// makes adjustments for indexing being on or off
	controlinfo /w = $panelTitle Check_DataAcq_Indexing
	if(v_value == 0)
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
		TotTrials = v_value
		controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
		TotTrials = (TotTrials * v_value)
	else
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsInSet
		TotTrials = v_value
	endif
	
	// if the device is an ITC1600 it will handle follower or independent devices
	if(DAP_DeviceIsYokeable(panelTitle))
		
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

					NVAR followerCount = $GetCount(followerPanelTitle)
					followerCount = 0
					i += 1
			
				while(i < numberOfFollowerDevices)
			endif
		endif
	endif

	ValDisplay valdisp_DataAcq_TrialsCountdown win = $panelTitle, value = _NUM:(TotTrials - (Count)) // updates trials remaining in panel
	RA_HandleITI_MD(panelTitle)
End
//====================================================================================================

Function RA_CounterMD(panelTitle)
	string panelTitle

	variable TotTrials
	variable ITI
	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	WAVE TestPulseITC = GetTestPulseITCWave(panelTitle)
	wave TestPulse = root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse
	NVAR count = $GetCount(panelTitle)
	string ActiveSetCountPath = GetDevicePathAsString(panelTitle) + ":ActiveSetCount"
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
	print "count = " + num2str(count), "in RA_CounterMD"
	
	controlinfo /w = $panelTitle SetVar_DataAcq_ITI
	ITI = v_value
	ValDisplay valdisp_DataAcq_TrialsCountdown win = $panelTitle, value = _NUM:(TotTrials - (Count))// reports trials remaining
	
	controlinfo /w = $panelTitle Check_DataAcq_Indexing
	If(v_value == 1)// if indexing is activated, indexing is applied.
		if(count == 1)
			IDX_StoreStartFinishForIndexing(panelTitle)
		endif
		//print "active set count "+num2str(activesetcount)
		if(activeSetcount == 0)//mod(Count,v_value)==0)
			controlinfo /w = $panelTitle Check_DataAcq1_IndexingLocked
			if(v_value == 1)//indexing is locked
				print "Index Step taken"
				IDX_IndexingDoIt(panelTitle)
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
	
	if(DAP_DeviceIsYokeable(panelTitle))
	
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
					NVAR followerCount = $GetCount(followerPanelTitle)
					followerCount += 1

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
		DAM_FunctionStartDataAcq(panelTitle)
	endif
End

//====================================================================================================
Function RA_BckgTPwithCallToRACounterMD(panelTitle)
	string panelTitle

	WAVE TestPulseITC = GetTestPulseITCWave(panelTitle)
	WAVE TestPulse = root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse
	variable ITI
	variable TotTrials
	NVAR count = $GetCount(panelTitle)

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

	if(DAP_DeviceIsYokeable(panelTitle)) // handling of  yoked ITC1600

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
		ED_TPDocumentation(panelTitle) // documents the TP Vrest, peak and steady state resistance values. from the last time the TP was run. Should append them to the subsequent sweep
		RA_HandleITI_MD(panelTitle)
	else
		ED_TPDocumentation(panelTitle) // documents TP for run just prior to last sweep in repeated acquisition.
		print "totalTrials =", TotTrials
		DAP_OneTimeCallAfterDAQ(panelTitle)
		print "Repeated acquisition is complete"
		print "**************************Killing count on:", panelTitle
		Killvariables Count
		ITC_StopITCDeviceTimer(panelTitle)
		
		if(SVAR_exists(listOfFollowerDevices) && stringmatch(ITCDACStatus, "Independent") != 1)
			print "*****************path to list of follower devices exists"
			numberOfFollowerDevices = itemsinlist(listOfFollowerDevices)
			if(numberOfFollowerDevices != 0) // there are followers
				i = 0
				do
					followerPanelTitle = StringFromList(i, listOfFollowerDevices)
					NVAR followerCount = $GetCount(followerPanelTitle)
					KillVariables/Z followerCount
					i += 1

				while(i < numberOfFollowerDevices)
			
			endif
		endif
	endif
End
