#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_RA
#endif

/// comment in to enable repeated acquisition performance measurement code
// #define PERFING_RA

/// @file MIES_RepeatedAcquisition.ipf
/// @brief __RA__ Repated acquisition functionality

/// @brief Recalculate the Inter trial interval (ITI) for the given device.
static Function RA_RecalculateITI(panelTitle)
	string panelTitle

	variable ITI

	NVAR repurposedTime = $GetRepurposedSweepTime(panelTitle)
	ITI = DAG_GetNumericalValue(panelTitle, "SetVar_DataAcq_ITI") - DQ_StopITCDeviceTimer(panelTitle) + repurposedTime
	repurposedTime = 0

	return ITI
End

static Function RA_HandleITI_MD(panelTitle)
	string panelTitle

	variable ITI
	string funcList

	AFM_CallAnalysisFunctions(panelTitle, POST_SET_EVENT)
	ITI = RA_RecalculateITI(panelTitle)

	if(!DAG_GetNumericalValue(panelTitle, "check_Settings_ITITP") || ITI <= 0)

		funcList = "RA_CounterMD(\"" + panelTitle + "\")"

		if(ITI <= 0 && !IsBackgroundTaskRunning("ITC_TimerMD")) // we are the only device currently
			ExecuteListOfFunctions(funcList)
			return NaN
		endif

		DQM_StartBackgroundTimer(panelTitle, ITI, funcList)

		return NaN
	endif

	TPM_StartTPMultiDeviceLow(panelTitle, runModifier=TEST_PULSE_DURING_RA_MOD)

	funcList = "TPM_StopTestPulseMultiDevice(\"" + panelTitle + "\")" + ";" + "RA_CounterMD(\"" + panelTitle + "\")"
	DQM_StartBackgroundTimer(panelTitle, ITI, funcList)
End

static Function RA_WaitUntiIITIDone(panelTitle, elapsedTime)
	string panelTitle
	variable elapsedTime

	variable reftime, timeLeft
	string oscilloscopeSubwindow

	refTime = RelativeNowHighPrec()
	oscilloscopeSubwindow = SCOPE_GetGraph(panelTitle)

	do
		timeLeft = max((refTime + elapsedTime) - RelativeNowHighPrec(), 0)
		SetValDisplay(panelTitle, "valdisp_DataAcq_ITICountdown", var = timeLeft)

		DoUpdate/W=$oscilloscopeSubwindow

		if(timeLeft == 0)
			return 0
		endif
	while(!(GetKeyState(0) & ESCAPE_KEY))

	return 1
End

static Function RA_HandleITI(panelTitle)
	string panelTitle

	variable ITI, refTime, background, aborted
	string funcList

	AFM_CallAnalysisFunctions(panelTitle, POST_SET_EVENT)
	ITI = RA_RecalculateITI(panelTitle)
	background = DAG_GetNumericalValue(panelTitle, "Check_Settings_BackgrndDataAcq")
	funcList = "RA_Counter(\"" + panelTitle + "\")"

	if(!DAG_GetNumericalValue(panelTitle, "check_Settings_ITITP") || ITI <= 0)

		if(ITI <= 0)
			ExecuteListOfFunctions(funcList)
		elseif(background)
			DQS_StartBackgroundTimer(panelTitle, ITI, funcList)
		else
			RA_WaitUntiIITIDone(panelTitle, ITI)

			if(aborted)
				RA_FinishAcquisition(panelTitle)
			else
				ExecuteListOfFunctions(funcList)
			endif
		endif

		return NaN
	endif

	if(background)
		TP_Setup(panelTitle, TEST_PULSE_BG_SINGLE_DEVICE | TEST_PULSE_DURING_RA_MOD)
		TPS_StartBackgroundTestPulse(panelTitle)
		funcList = "TPS_StopTestPulseSingleDevice(\"" + panelTitle + "\")" + ";" + "RA_Counter(\"" + panelTitle + "\")"
		DQS_StartBackgroundTimer(panelTitle, ITI, funcList)
	else
		TP_Setup(panelTitle, TEST_PULSE_FG_SINGLE_DEVICE | TEST_PULSE_DURING_RA_MOD)
		aborted = TPS_StartTestPulseForeground(panelTitle, elapsedTime = ITI)
		TP_Teardown(panelTitle)

		if(aborted)
			RA_FinishAcquisition(panelTitle)
		else
			ExecuteListOfFunctions(funcList)
		endif
	endif
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

/// @brief Calculate the total number of sweeps for repeated acquisition
///
/// Helper function for plain calculation without lead and follower logic
static Function RA_GetTotalNumberOfSweepsLowLev(panelTitle)
	string panelTitle

	if(DAG_GetNumericalValue(panelTitle, "Check_DataAcq_Indexing"))
		return GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_SweepsInSet")
	else
		return IDX_CalculcateActiveSetCount(panelTitle)
	endif
End

/// @brief Calculate the total number of sweeps for repeated acquisition
static Function RA_GetTotalNumberOfSweeps(panelTitle)
	string panelTitle

	variable i, numFollower, numTotalSweeps
	string followerPanelTitle

	numTotalSweeps = RA_GetTotalNumberOfSweepsLowLev(panelTitle)

	if(DeviceHasFollower(panelTitle))
		SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)
		numFollower = ItemsInList(listOfFollowerDevices)
		for(i = 0; i < numFollower; i += 1)
			followerPanelTitle = StringFromList(i, listOfFollowerDevices)

			numTotalSweeps = max(numTotalSweeps, RA_GetTotalNumberOfSweepsLowLev(followerPanelTitle))
		endfor
	endif

	return numTotalSweeps
End

/// @brief Update the "Sweeps remaining" control
Function RA_StepSweepsRemaining(panelTitle)
	string panelTitle

	if(DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_RepeatAcq"))
		variable numTotalSweeps = RA_GetTotalNumberOfSweeps(panelTitle)
		NVAR count = $GetCount(panelTitle)

		SetValDisplay(panelTitle, "valdisp_DataAcq_TrialsCountdown", var = numTotalSweeps - count - 1)
	else
		SetValDisplay(panelTitle, "valdisp_DataAcq_TrialsCountdown", var = 0)
	endif
End

/// @brief Function gets called after the first sweep is already
/// acquired and if repeated acquisition is on
Function RA_Start(panelTitle)
	string panelTitle
	
	variable numTotalSweeps
	NVAR count = $GetCount(panelTitle)

#ifdef PERFING_RA
	RA_PerfInitialize(panelTitle)
#endif

	numTotalSweeps = RA_GetTotalNumberOfSweeps(panelTitle)

	if(numTotalSweeps == 1)
		return RA_FinishAcquisition(panelTitle)
	endif

	RA_StepSweepsRemaining(panelTitle)
	RA_HandleITI(panelTitle)
End

Function RA_Counter(panelTitle)
	string panelTitle

	variable numTotalSweeps, indexing, indexingLocked
	variable numSets
	string str

	NVAR count = $GetCount(panelTitle)
	NVAR activeSetCount = $GetActiveSetCount(panelTitle)

	count += 1
	activeSetCount -= 1

#ifdef PERFING_RA
	RA_PerfAddMark(panelTitle, count)
#endif

	numSets        = RA_GetTotalNumberOfSets(panelTitle)
	numTotalSweeps = RA_GetTotalNumberOfSweeps(panelTitle)
	indexing       = DAG_GetNumericalValue(panelTitle, "Check_DataAcq_Indexing")
	indexingLocked = DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_IndexingLocked")


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

	if(Count < numTotalSweeps)
		try
			DC_ConfigureDataForITC(panelTitle, DATA_ACQUISITION_MODE)

			if(DAG_GetNumericalValue(panelTitle, "Check_Settings_BackgrndDataAcq"))
				DQS_BkrdDataAcq(panelTitle)
			else
				DQS_DataAcq(panelTitle)
			endif
		catch
			RA_FinishAcquisition(panelTitle)
		endtry
	else
		RA_FinishAcquisition(panelTitle)
	endif
End

static Function RA_FinishAcquisition(panelTitle)
	string panelTitle

	string list
	variable numEntries, i

	DQ_StopITCDeviceTimer(panelTitle)

#ifdef PERFING_RA
	RA_PerfFinish(panelTitle)
#endif

	list = GetListofLeaderAndPossFollower(panelTitle)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		DAP_OneTimeCallAfterDAQ(StringFromList(i, list))
	endfor
End

Function RA_BckgTPwithCallToRACounter(panelTitle)
	string panelTitle

	variable numTotalSweeps
	NVAR count = $GetCount(panelTitle)

	numTotalSweeps = RA_GetTotalNumberOfSweeps(panelTitle)

	if(Count < (numTotalSweeps - 1))
		RA_HandleITI(panelTitle)
	else
		RA_FinishAcquisition(panelTitle)
	endif
End

static Function RA_StartMD(panelTitle)
	string panelTitle

	variable i, numFollower, numTotalSweeps
	string followerPanelTitle
	NVAR count = $GetCount(panelTitle)

#ifdef PERFING_RA
	RA_PerfInitialize(panelTitle)
#endif

	RA_StepSweepsRemaining(panelTitle)

	numTotalSweeps = RA_GetTotalNumberOfSweeps(panelTitle)

	if(numTotalSweeps == 1)
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

	variable numTotalSweeps, numSets, recalcActiveSetCount, activeSetCountMax
	NVAR count = $GetCount(panelTitle)
	NVAR activeSetCount = $GetActiveSetCount(panelTitle)
	variable i, indexing, indexingLocked, numFollower, followerActiveSetCount
	string str, followerPanelTitle

	Count += 1
	ActiveSetCount -= 1

#ifdef PERFING_RA
	RA_PerfAddMark(panelTitle, count)
#endif

	numSets        = RA_GetTotalNumberOfSets(panelTitle)
	numTotalSweeps = RA_GetTotalNumberOfSweeps(panelTitle)
	indexing       = DAG_GetNumericalValue(panelTitle, "Check_DataAcq_Indexing")
	indexingLocked = DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_IndexingLocked")

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

		activeSetCountMax = activeSetCount

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
					activeSetCountMax = max(activeSetCountMax, followerActiveSetCount)
				endif

				if(!indexingLocked)
					// channel indexes when set has completed all its steps
					IDX_ApplyUnLockedIndexing(followerPanelTitle, count, 0)
					IDX_ApplyUnLockedIndexing(followerPanelTitle, count, 1)
				endif
			endif
		endfor

		if(indexing)
			// set maximum on leader and all followers
			NVAR activeSetCount = $GetActiveSetCount(panelTitle)
			activeSetCount = activeSetCountMax

			for(i = 0; i < numFollower; i += 1)
				followerPanelTitle = StringFromList(i, listOfFollowerDevices)

				NVAR activeSetCount = $GetActiveSetCount(followerPanelTitle)
				activeSetCount = activeSetCountMax
			endfor
		endif
	endif

	if(count < numTotalSweeps)
		DQM_StartDAQMultiDevice(panelTitle, initialSetupReq=0)
	else
		RA_FinishAcquisition(panelTitle)
	endif
End

static Function RA_BckgTPwithCallToRACounterMD(panelTitle)
	string panelTitle

	variable numTotalSweeps
	NVAR count = $GetCount(panelTitle)

	numTotalSweeps = RA_GetTotalNumberOfSweeps(panelTitle)

	if(count < (numTotalSweeps - 1))
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

	variable totSweeps = RA_GetTotalNumberOfSweeps(panelTitle)
	NVAR count = $GetCount(panelTitle)
	if(DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_RepeatAcq"))
		// RA_counter and RA_counterMD increment count at initialization, -1 accounts for this and allows a skipping back to sweep 0
		return min(totSweeps - 1, max(count + skipCount, -1))
	else 
		return 0
	endif
End

Function RA_PerfInitialize(panelTitle)
	string panelTitle

	KillOrMoveToTrash(wv = GetRAPerfWave(panelTitle))
	WAVE perfWave = GetRAPerfWave(panelTitle)

	perfWave[0] = RelativeNowHighPrec()
End

Function RA_PerfAddMark(panelTitle, idx)
	string panelTitle
	variable idx

	WAVE perfWave = GetRAPerfWave(panelTitle)

	EnsureLargeEnoughWave(perfWave, minimumSize = idx, initialValue = NaN)
	perfWave[idx] = RelativeNowHighPrec()
End

Function RA_PerfFinish(panelTitle)
	string panelTitle

	WAVE perfWave = GetRAPerfWave(panelTitle)

	NVAR count = $GetCount(panelTitle)

	Redimension/N=(count + 1) perfWave

	if(count <= 1)
		// nothing to do
		return NaN
	endif

	perfWave[1, Dimsize(perfWave, ROWS) - 1] = perfWave[p] - perfWave[0]
	perfWave[0] = 0
	perfWave[1] = NaN

	DFREF dfr = GetWavesDataFolderDFR(perfWave)

	Duplicate perfWave, dfr:$UniqueWaveName(dfr, NameOfWave(perfWave) + "_finished")
End
