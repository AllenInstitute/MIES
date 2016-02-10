#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_RepeatedAcquisition.ipf
/// @brief __RA__ Repated acquisition functionality

static Function RA_HandleITI_MD(panelTitle)
	string panelTitle

	variable ITI

	DM_CallAnalysisFunctions(panelTitle, POST_SET_EVENT)

	ITI = GetSetVariable(panelTitle, "SetVar_DataAcq_ITI")
	if(!GetCheckBoxState(panelTitle, "check_Settings_ITITP"))
		ITI -= ITC_StopITCDeviceTimer(panelTitle)
		ITC_StartBackgroundTimerMD(ITI, "RA_CounterMD(\"" + panelTitle + "\")", "", "", panelTitle)
		return NaN
	endif

	ITI -= ITC_StopITCDeviceTimer(panelTitle)
	DAM_StartTestPulseMD(panelTitle, runModifier=TEST_PULSE_DURING_RA_MOD)

	ITC_StartBackgroundTimerMD(ITI,"ITC_StopTestPulseMultiDevice(\"" + panelTitle + "\")", "RA_CounterMD(\"" + panelTitle + "\")",  "", panelTitle)
End

static Function RA_HandleITI(panelTitle)
	string panelTitle

	variable ITI

	DM_CallAnalysisFunctions(panelTitle, POST_SET_EVENT)

	ITI = GetSetVariable(panelTitle, "SetVar_DataAcq_ITI")
	if(!GetCheckBoxState(panelTitle, "check_Settings_ITITP"))
		ITI -= ITC_StopITCDeviceTimer(panelTitle)
		ITC_StartBackgroundTimer(ITI, "RA_Counter(\"" + panelTitle + "\")", "", "", panelTitle)
		return NaN
	endif

	TP_Setup(panelTitle, TEST_PULSE_BG_SINGLE_DEVICE | TEST_PULSE_DURING_RA_MOD)

	ITI -= ITC_StopITCDeviceTimer(panelTitle)

	ITC_StartBackgroundTestPulse(panelTitle)
	ITC_StartBackgroundTimer(ITI, "ITC_STOPTestPulseSingleDevice(\"" + panelTitle + "\")", "RA_Counter(\"" + panelTitle + "\")", "", panelTitle)
End

/// @brief Return the total number of sets
///
/// Takes into account yoking
static Function RA_GetTotalNumberOfSets(panelTitle)
	string panelTitle

	variable i, numFollower, numSets
	string followerPanelTitle

	numSets = IDX_MaxNoOfSweeps(panelTitle, 1)

	if(DAP_DeviceIsYokeable(panelTitle))
		SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
		if(SVAR_Exists(listOfFollowerDevices) && DAP_DeviceIsLeader(panelTitle))
			numFollower = ItemsInList(listOfFollowerDevices)
			for(i = 0; i < numFollower; i += 1)
				followerPanelTitle = StringFromList(i, listOfFollowerDevices)

				numSets = max(numSets, IDX_MaxNoOfSweeps(followerPanelTitle, 1))
			endfor
		endif
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

	if(DAP_DeviceIsYokeable(panelTitle))
		SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
		if(SVAR_Exists(listOfFollowerDevices) && DAP_DeviceIsLeader(panelTitle))
			numFollower = ItemsInList(listOfFollowerDevices)
			for(i = 0; i < numFollower; i += 1)
				followerPanelTitle = StringFromList(i, listOfFollowerDevices)

				totTrials = max(totTrials, RA_GetTotalNumberOfTrialsLowLev(followerPanelTitle))
			endfor
		endif
	endif

	return totTrials
End

/// @brief Function gets called after the first trial is already
/// acquired and if repeated acquisition is on
Function RA_Start(panelTitle)
	string panelTitle

	variable totTrials

	NVAR count = $GetCount(panelTitle)
	count = 0

	NVAR activeSetCount = $GetActiveSetCount(panelTitle)
	activeSetCount = IDX_CalculcateActiveSetCount(panelTitle)

	totTrials = RA_GetTotalNumberOfTrials(panelTitle)

	if(totTrials == 1)
		return RA_FinishAcquisition(panelTitle)
	endif

	SetValDisplaySingleVariable(panelTitle, "valdisp_DataAcq_TrialsCountdown", totTrials - count)
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

	SetValDisplaySingleVariable(panelTitle, "valdisp_DataAcq_TrialsCountdown", totTrials - count)

	if(indexing)
		if(count == 1)
			IDX_StoreStartFinishForIndexing(panelTitle)
		endif
		if(activeSetcount == 0)
			if(indexingLocked)
				IDX_IndexingDoIt(panelTitle)
			endif

			SetValDisplaySingleVariable(panelTitle, "valdisp_DataAcq_SweepsActiveSet", numSets)
			activeSetCount = IDX_CalculcateActiveSetCount(panelTitle)
		endif

		if(!indexingLocked)
			IDX_ApplyUnLockedIndexing(panelTitle, count, 0)
			IDX_ApplyUnLockedIndexing(panelTitle, count, 1)
		endif
	endif

	if(Count < TotTrials)
		DC_ConfigureDataForITC(panelTitle, DATA_ACQUISITION_MODE)

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

	ITC_StopITCDeviceTimer(panelTitle)
	DAP_OneTimeCallAfterDAQ(panelTitle)
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

Function RA_StartMD(panelTitle)
	string panelTitle

	variable i, totTrials, numFollower
	string followerPanelTitle

	NVAR count = $GetCount(panelTitle)
	count = 0
	NVAR activeSetCount = $GetActiveSetCount(panelTitle)
	activeSetCount = IDX_CalculcateActiveSetCount(panelTitle)
	totTrials = RA_GetTotalNumberOfTrials(panelTitle)

	if(DAP_DeviceIsYokeable(panelTitle))
		SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
		if(SVAR_exists(listOfFollowerDevices) && DAP_DeviceIsLeader(panelTitle))
			numFollower = ItemsInList(listOfFollowerDevices)
			for(i = 0; i < numFollower; i += 1)
				followerPanelTitle = StringFromList(i, listOfFollowerDevices)

				totTrials = max(totTrials, RA_GetTotalNumberOfTrials(followerPanelTitle))
				SetValDisplaySingleVariable(followerPanelTitle, "valdisp_DataAcq_TrialsCountdown", totTrials - count)

				NVAR followerCount = $GetCount(followerPanelTitle)
				followerCount = 0
			endfor
		endif
	endif

	SetValDisplaySingleVariable(panelTitle, "valdisp_DataAcq_TrialsCountdown", totTrials - count)
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

	SetValDisplaySingleVariable(panelTitle, "valdisp_DataAcq_TrialsCountdown", totTrials - count)

	recalcActiveSetCount = (activeSetCount == 0)

	if(indexing)
		if(count == 1)
			IDX_StoreStartFinishForIndexing(panelTitle)
		endif

		if(recalcActiveSetCount)
			if(indexingLocked)
				print "Index Step taken"
				IDX_IndexingDoIt(panelTitle)
			endif

			SetValDisplaySingleVariable(panelTitle, "valdisp_DataAcq_SweepsActiveSet", numSets)
			activeSetCount = IDX_CalculcateActiveSetCount(panelTitle)
		endif

		if(!indexingLocked)
			// indexing is not locked = channel indexes when set has completed all its steps
			IDX_ApplyUnLockedIndexing(panelTitle, count, 0)
			IDX_ApplyUnLockedIndexing(panelTitle, count, 1)
		endif
	endif

	if(DAP_DeviceIsYokeable(panelTitle))
		SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
		if(SVAR_Exists(listOfFollowerDevices) && DAP_DeviceIsLeader(panelTitle))
			numFollower = ItemsInList(listOfFollowerDevices)
			for(i = 0; i < numFollower; i += 1)
				followerPanelTitle = StringFromList(i, listOfFollowerDevices)
				NVAR followerCount = $GetCount(followerPanelTitle)
				followerCount += 1

				SetValDisplaySingleVariable(panelTitle, "valdisp_DataAcq_TrialsCountdown", totTrials - count)

				if(indexing)
					if(count == 1)
						IDX_StoreStartFinishForIndexing(followerPanelTitle)
					endif

					if(recalcActiveSetCount)
						if(indexingLocked)
							IDX_IndexingDoIt(followerPanelTitle)
						endif
						SetValDisplaySingleVariable(followerPanelTitle, "valdisp_DataAcq_SweepsActiveSet", numSets)
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
	endif

	if(count < totTrials)
		DAM_FunctionStartDataAcq(panelTitle)
	endif
End

Function RA_BckgTPwithCallToRACounterMD(panelTitle)
	string panelTitle

	variable totTrials, numFollower, i, numberOfFollowerDevices
	string followerPanelTitle
	NVAR count = $GetCount(panelTitle)

	totTrials = RA_GetTotalNumberOfTrials(panelTitle)

	if(count < (totTrials - 1))
		RA_HandleITI_MD(panelTitle)
	else
		RA_FinishAcquisition(panelTitle)

		SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
		if(SVAR_Exists(listOfFollowerDevices) && DAP_DeviceIsLeader(panelTitle))
			numberOfFollowerDevices = ItemsInList(listOfFollowerDevices)
			for(i = 0; i < numberOfFollowerDevices; i += 1)
				followerPanelTitle = StringFromList(i, listOfFollowerDevices)
				DAP_OneTimeCallAfterDAQ(followerPanelTitle)
			endfor
		endif
	endif
End
