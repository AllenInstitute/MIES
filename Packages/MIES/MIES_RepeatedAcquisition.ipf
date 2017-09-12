#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_RA
#endif

/// @file MIES_RepeatedAcquisition.ipf
/// @brief __RA__ Repated acquisition functionality

/// @brief Recalculate the Inter trial interval (ITI) for the given device.
static Function RA_RecalculateITI(panelTitle)
	string panelTitle

	variable ITI

	NVAR repurposedTime = $GetRepurposedSweepTime(panelTitle)
	ITI = GetSetVariable(panelTitle, "SetVar_DataAcq_ITI") - ITC_StopITCDeviceTimer(panelTitle) + repurposedTime
	repurposedTime = 0

	return ITI
End

static Function RA_HandleITI_MD(panelTitle)
	string panelTitle

	variable ITI
	string funcList

	AFM_CallAnalysisFunctions(panelTitle, POST_SET_EVENT)
	ITI = RA_RecalculateITI(panelTitle)

	if(!GetCheckBoxState(panelTitle, "check_Settings_ITITP") || ITI <= 0)

		funcList = "RA_CounterMD(\"" + panelTitle + "\")"

		if(ITI <= 0 && !IsBackgroundTaskRunning("ITC_TimerMD")) // we are the only device currently
			ExecuteListOfFunctions(funcList)
			return NaN
		endif

		ITC_StartBackgroundTimerMD(panelTitle, ITI, funcList)

		return NaN
	endif

	ITC_StartTestPulseMultiDevice(panelTitle, runModifier=TEST_PULSE_DURING_RA_MOD)

	funcList = "ITC_StopTestPulseMultiDevice(\"" + panelTitle + "\")" + ";" + "RA_CounterMD(\"" + panelTitle + "\")"
	ITC_StartBackgroundTimerMD(panelTitle, ITI, funcList)
End

static Function RA_HandleITI(panelTitle)
	string panelTitle

	variable ITI
	string funcList

	AFM_CallAnalysisFunctions(panelTitle, POST_SET_EVENT)
	ITI = RA_RecalculateITI(panelTitle)

	if(!GetCheckBoxState(panelTitle, "check_Settings_ITITP") || ITI <= 0)

		funcList = "RA_Counter(\"" + panelTitle + "\")"

		if(ITI <= 0)
			ExecuteListOfFunctions(funcList)
			return NaN
		endif

		ITC_StartBackgroundTimer(panelTitle, ITI, funcList)

		return NaN
	endif

	TP_Setup(panelTitle, TEST_PULSE_BG_SINGLE_DEVICE | TEST_PULSE_DURING_RA_MOD)
	ITC_StartBackgroundTestPulse(panelTitle)

	funcList = "ITC_STOPTestPulseSingleDevice(\"" + panelTitle + "\")" + ";" + "RA_Counter(\"" + panelTitle + "\")"
	ITC_StartBackgroundTimer(panelTitle, ITI, funcList)
End

/// @brief Return the total number of sets
///
/// Takes into account yoking
static Function RA_GetTotalNumberOfSets(panelTitle)
	string panelTitle

	variable i, numFollower, numSets
	string followerPanelTitle

	numSets = IDX_MaxNoOfSweeps(panelTitle, 1)

	if(DeviceHasFollower(panelTitle))
		SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)
		numFollower = ItemsInList(listOfFollowerDevices)
		for(i = 0; i < numFollower; i += 1)
			followerPanelTitle = StringFromList(i, listOfFollowerDevices)

			numSets = max(numSets, IDX_MaxNoOfSweeps(followerPanelTitle, 1))
		endfor
	endif

	return numSets
End

/// @brief Calculate the total number of trials for repeated acquisition
///
/// Helper function for plain calculation without lead and follower logic
static Function RA_GetTotalNumberOfTrialsLowLev(panelTitle)
	string panelTitle

	if(GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing"))
		return GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_SweepsInSet")
	else
		return IDX_CalculcateActiveSetCount(panelTitle)
	endif
End

/// @brief Calculate the total number of trials for repeated acquisition
static Function RA_GetTotalNumberOfTrials(panelTitle)
	string panelTitle

	variable i, numFollower, totTrials
	string followerPanelTitle

	totTrials = RA_GetTotalNumberOfTrialsLowLev(panelTitle)

	if(DeviceHasFollower(panelTitle))
		SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)
		numFollower = ItemsInList(listOfFollowerDevices)
		for(i = 0; i < numFollower; i += 1)
			followerPanelTitle = StringFromList(i, listOfFollowerDevices)

			totTrials = max(totTrials, RA_GetTotalNumberOfTrialsLowLev(followerPanelTitle))
		endfor
	endif

	return totTrials
End

/// @brief Update the "Sweeps remaining" control
Function RA_StepSweepsRemaining(panelTitle)
	string panelTitle

	if(GetCheckBoxState(panelTitle, "Check_DataAcq1_RepeatAcq"))
		variable totTrials = RA_GetTotalNumberOfTrials(panelTitle)
		NVAR count = $GetCount(panelTitle)

		SetValDisplay(panelTitle, "valdisp_DataAcq_TrialsCountdown", var = totTrials - count - 1)
	else
		SetValDisplay(panelTitle, "valdisp_DataAcq_TrialsCountdown", var = 0)
	endif
End

/// @brief Function gets called after the first trial is already
/// acquired and if repeated acquisition is on
Function RA_Start(panelTitle)
	string panelTitle
	
	variable totTrials
	NVAR count = $GetCount(panelTitle)
	NVAR activeSetCount = $GetActiveSetCount(panelTitle)

	activeSetCount = IDX_CalculcateActiveSetCount(panelTitle)
	totTrials = RA_GetTotalNumberOfTrials(panelTitle)

	if(totTrials == 1)
		return RA_FinishAcquisition(panelTitle)
	endif

	RA_StepSweepsRemaining(panelTitle)
	RA_HandleITI(panelTitle)
End

Function RA_Counter(panelTitle)
	string panelTitle

	variable totTrials, indexing, indexingLocked, backgroundDAQ
	variable numSets
	string str

	NVAR count = $GetCount(panelTitle)
	NVAR activeSetCount = $GetActiveSetCount(panelTitle)

	count += 1
	activeSetCount -= 1

	numSets        = RA_GetTotalNumberOfSets(panelTitle)
	totTrials      = RA_GetTotalNumberOfTrials(panelTitle)
	indexing       = GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing")
	indexingLocked = GetCheckBoxState(panelTitle, "Check_DataAcq1_IndexingLocked")
	backgroundDAQ  = GetCheckBoxState(panelTitle, "Check_Settings_BackgrndDataAcq")

	sprintf str, "count=%d, activeSetCount=%d\r" count, activeSetCount
	DEBUGPRINT(str)

	RA_StepSweepsRemaining(panelTitle)

	if(indexing)
		if(activeSetcount == 0)
			if(indexingLocked)
				IDX_IndexingDoIt(panelTitle)
			endif

			SetValDisplay(panelTitle, "valdisp_DataAcq_SweepsActiveSet", var=numSets)
			activeSetCount = IDX_CalculcateActiveSetCount(panelTitle)
		endif

		if(!indexingLocked)
			IDX_ApplyUnLockedIndexing(panelTitle, count, 0)
			IDX_ApplyUnLockedIndexing(panelTitle, count, 1)
		endif
	endif

	if(Count < TotTrials)
		try
			DC_ConfigureDataForITC(panelTitle, DATA_ACQUISITION_MODE)
		catch
			RA_FinishAcquisition(panelTitle)
		endtry

		if(!backgroundDAQ)
			ITC_DataAcq(panelTitle)
			if(Count < (TotTrials - 1)) //prevents test pulse from running after last trial is acquired
				RA_HandleITI(panelTitle)
			else
				RA_FinishAcquisition(panelTitle)
			endif
		else
			ITC_BkrdDataAcq(panelTitle)
		endif
	else
		RA_FinishAcquisition(panelTitle)
	endif
End

static Function RA_FinishAcquisition(panelTitle)
	string panelTitle

	string list
	variable numEntries, i

	ITC_StopITCDeviceTimer(panelTitle)

	list = GetListofLeaderAndPossFollower(panelTitle)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		DAP_OneTimeCallAfterDAQ(StringFromList(i, list))
	endfor
End

Function RA_BckgTPwithCallToRACounter(panelTitle)
	string panelTitle

	variable totTrials
	NVAR count = $GetCount(panelTitle)

	totTrials = RA_GetTotalNumberOfTrials(panelTitle)

	if(Count < (totTrials - 1))
		RA_HandleITI(panelTitle)
	else
		RA_FinishAcquisition(panelTitle)
	endif
End

static Function RA_StartMD(panelTitle)
	string panelTitle

	variable i, numFollower, totTrials
	string followerPanelTitle
	NVAR count = $GetCount(panelTitle)
	NVAR activeSetCount = $GetActiveSetCount(panelTitle)

	activeSetCount = IDX_CalculcateActiveSetCount(panelTitle)

	RA_StepSweepsRemaining(panelTitle)

	totTrials = RA_GetTotalNumberOfTrials(panelTitle)

	if(totTrials == 1)
		return RA_FinishAcquisition(panelTitle)
	endif

	if(DeviceHasFollower(panelTitle))
		SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)
		numFollower = ItemsInList(listOfFollowerDevices)
		for(i = 0; i < numFollower; i += 1)
			followerPanelTitle = StringFromList(i, listOfFollowerDevices)

			NVAR followerCount = $GetCount(followerPanelTitle)
			followerCount = 0

			RA_StepSweepsRemaining(followerPanelTitle)
		endfor
	endif

	RA_HandleITI_MD(panelTitle)
End

Function RA_CounterMD(panelTitle)
	string panelTitle

	variable totTrials, numSets, recalcActiveSetCount
	NVAR count = $GetCount(panelTitle)
	NVAR activeSetCount = $GetActiveSetCount(panelTitle)
	variable i, indexing, indexingLocked, numFollower, followerActiveSetCount
	string str, followerPanelTitle

	Count += 1
	ActiveSetCount -= 1

	numSets        = RA_GetTotalNumberOfSets(panelTitle)
	totTrials      = RA_GetTotalNumberOfTrials(panelTitle)
	indexing       = GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing")
	indexingLocked = GetCheckBoxState(panelTitle, "Check_DataAcq1_IndexingLocked")

	sprintf str, "count=%d, activeSetCount=%d\r" count, activeSetCount
	DEBUGPRINT(str)

	RA_StepSweepsRemaining(panelTitle)

	recalcActiveSetCount = (activeSetCount == 0)

	if(indexing)
		if(recalcActiveSetCount)
			if(indexingLocked)
				IDX_IndexingDoIt(panelTitle)
			endif

			SetValDisplay(panelTitle, "valdisp_DataAcq_SweepsActiveSet", var=numSets)
			activeSetCount = IDX_CalculcateActiveSetCount(panelTitle)
		endif

		if(!indexingLocked)
			// indexing is not locked = channel indexes when set has completed all its steps
			IDX_ApplyUnLockedIndexing(panelTitle, count, 0)
			IDX_ApplyUnLockedIndexing(panelTitle, count, 1)
		endif
	endif

	if(DeviceHasFollower(panelTitle))
		SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)
		numFollower = ItemsInList(listOfFollowerDevices)
		for(i = 0; i < numFollower; i += 1)
			followerPanelTitle = StringFromList(i, listOfFollowerDevices)
			NVAR followerCount = $GetCount(followerPanelTitle)
			followerCount += 1

			RA_StepSweepsRemaining(followerPanelTitle)

			if(indexing)
				if(recalcActiveSetCount)
					if(indexingLocked)
						IDX_IndexingDoIt(followerPanelTitle)
					endif
					SetValDisplay(followerPanelTitle, "valdisp_DataAcq_SweepsActiveSet", var=numSets)
					followerActiveSetCount = IDX_CalculcateActiveSetCount(followerPanelTitle)
					activeSetCount = max(activeSetCount, followerActiveSetCount)
				endif

				if(!indexingLocked)
					// channel indexes when set has completed all its steps
					IDX_ApplyUnLockedIndexing(followerPanelTitle, count, 0)
					IDX_ApplyUnLockedIndexing(followerPanelTitle, count, 1)
				endif
			endif
		endfor
	endif

	if(count < totTrials)
		ITC_StartDAQMultiDeviceLowLevel(panelTitle, initialSetupReq=0)
	endif
End

static Function RA_BckgTPwithCallToRACounterMD(panelTitle)
	string panelTitle

	variable totTrials
	NVAR count = $GetCount(panelTitle)

	totTrials = RA_GetTotalNumberOfTrials(panelTitle)

	if(count < (totTrials - 1))
		RA_HandleITI_MD(panelTitle)
	else
		RA_FinishAcquisition(panelTitle)
	endif
End

static Function RA_AreLeaderAndFollowerFinished()

	variable numCandidates, i
	string listOfCandidates, candidate

	WAVE/SDFR=GetActiveITCDevicesFolder() ActiveDeviceList

	Duplicate/FREE/R=[][0] ActiveDeviceList, activeIDs

	if(DimSize(activeIDs, ROWS) == 0)
		return 1
	endif

	listOfCandidates = GetListofLeaderAndPossFollower(ITC1600_FIRST_DEVICE)
	numCandidates = ItemsInList(listOfCandidates)

	for(i = 0; i < numCandidates; i += 1)
		candidate = StringFromList(i, listOfCandidates)
		NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(candidate)

		FindValue/V=(ITCDeviceIDGlobal) activeIDs
		if(V_Value != -1) // device still active
			return 0
		endif
	endfor

	return 1
End

Function RA_YokedRAStartMD(panelTitle)
	string panelTitle

	// catches independent devices and leader with no follower
	if(!DeviceCanFollow(panelTitle) || !DeviceHasFollower(ITC1600_FIRST_DEVICE))
		RA_StartMD(panelTitle)
		return NaN
	endif

	if(RA_AreLeaderAndFollowerFinished())
		RA_StartMD(ITC1600_FIRST_DEVICE)
	endif
End

Function RA_YokedRABckgTPCallRACounter(panelTitle)
	string panelTitle

	// catches independent devices and leader with no follower
	if(!DeviceCanFollow(panelTitle) || !DeviceHasFollower(ITC1600_FIRST_DEVICE))
		RA_BckgTPwithCallToRACounterMD(panelTitle)
		return NaN
	endif

	if(RA_AreLeaderAndFollowerFinished())
		RA_BckgTPwithCallToRACounterMD(ITC1600_FIRST_DEVICE)
	endif
End

/// @brief Return one if we are acquiring currently the very first sweep of a
///        possible repeated acquisition cycle. Zero means that we acquire a later
///        sweep than the first one in a repeated acquisition cycle.
Function RA_IsFirstSweep(panelTitle)
	string panelTitle

	NVAR count = $GetCount(panelTitle)
	return !count
End

///@brief Allows skipping forward or backwards the sweep count during data acquistion
///
///@param panelTitle device
///@param skipCount The number of sweeps to skip (forward or backwards) during repeated acquisition
Function RA_SkipSweeps(panelTitle, skipCount)
	string panelTitle
	variable skipCount

	variable numFollower, i
	string followerPanelTitle
	NVAR count = $GetCount(panelTitle)
	NVAR dataAcqRunMode = $GetDataAcqRunMode(panelTitle)

	//Skip sweeps if, and only if, data acquisition is ongoing.
	if(dataAcqRunMode == DAQ_NOT_RUNNING)
		return NaN
	endif

	count = RA_SkipSweepCalc(panelTitle, skipCount)
	RA_StepSweepsRemaining(panelTitle)

	if(DeviceHasFollower(panelTitle))
		SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)
		numFollower = ItemsInList(listOfFollowerDevices)
		for(i = 0; i < numFollower; i += 1)
			followerPanelTitle = StringFromList(i, listOfFollowerDevices)
			NVAR followerCount = $GetCount(followerPanelTitle)
			followerCount = RA_SkipSweepCalc(followerPanelTitle, skipCount)
			RA_StepSweepsRemaining(followerPanelTitle)
		endfor
	endif
End

///@brief Returns valid count after adding skipCount
///
///@param panelTitle device
///@param skipCount The number of sweeps to skip (forward or backwards) during repeated acquisition.
static Function RA_SkipSweepCalc(panelTitle, skipCount)
	string panelTitle
	variable skipCount

	variable totSweeps = RA_GetTotalNumberOfTrials(panelTitle)
	NVAR count = $GetCount(panelTitle)
	if(getCheckboxState(panelTitle, "Check_DataAcq1_RepeatAcq"))
		// RA_counter and RA_counterMD increment count at initialization, -1 accounts for this and allows a skipping back to sweep 0
		return min(totSweeps - 1, max(count + skipCount, -1))
	else 
		return 0
	endif
End
