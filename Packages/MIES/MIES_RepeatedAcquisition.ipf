#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_RA
#endif

/// comment in to enable repeated acquisition performance measurement code
// #define PERFING_RA

/// @file MIES_RepeatedAcquisition.ipf
/// @brief __RA__ Repated acquisition functionality

/// @brief Recalculate the Inter trial interval (ITI) for the given device.
static Function RA_RecalculateITI(device)
	string device

	variable ITI

	NVAR repurposedTime = $GetRepurposedSweepTime(device)
	ITI = DAG_GetNumericalValue(device, "SetVar_DataAcq_ITI") - DQ_StopDAQDeviceTimer(device) + repurposedTime
	repurposedTime = 0

	return ITI
End

static Function RA_HandleITI_MD(device)
	string device

	variable ITI
	string funcList

	DAP_ApplyDelayedClampModeChange(device)

	AS_HandlePossibleTransition(device, AS_ITI)

	ITI = RA_RecalculateITI(device)

	if(!DAG_GetNumericalValue(device, "check_Settings_ITITP") || ITI <= 0)

		funcList = "RA_CounterMD(\"" + device + "\")"

		if(ITI <= 0 && !IsBackgroundTaskRunning("ITC_TimerMD")) // we are the only device currently
			ExecuteListOfFunctions(funcList)
			return NaN
		endif

		DQM_StartBackgroundTimer(device, ITI, funcList)

		return NaN
	endif

	TPM_StartTPMultiDeviceLow(device, runModifier=TEST_PULSE_DURING_RA_MOD)

	funcList = "TPM_StopTestPulseMultiDevice(\"" + device + "\")" + ";" + "RA_CounterMD(\"" + device + "\")"
	DQM_StartBackgroundTimer(device, ITI, funcList)
End

static Function RA_WaitUntiIITIDone(device, elapsedTime)
	string device
	variable elapsedTime

	variable reftime, timeLeft
	string oscilloscopeSubwindow

	refTime = RelativeNowHighPrec()
	oscilloscopeSubwindow = SCOPE_GetGraph(device)

	do
		timeLeft = max((refTime + elapsedTime) - RelativeNowHighPrec(), 0)
		SetValDisplay(device, "valdisp_DataAcq_ITICountdown", var = timeLeft)

		DoUpdate/W=$oscilloscopeSubwindow

		if(timeLeft == 0)
			return 0
		endif
	while(!(GetKeyState(0) & ESCAPE_KEY))

	return 1
End

static Function RA_HandleITI(device)
	string device

	variable ITI, refTime, background, aborted
	string funcList

	DAP_ApplyDelayedClampModeChange(device)
	AS_HandlePossibleTransition(device, AS_ITI)

	ITI = RA_RecalculateITI(device)
	background = DAG_GetNumericalValue(device, "Check_Settings_BackgrndDataAcq")
	funcList = "RA_Counter(\"" + device + "\")"

	if(!DAG_GetNumericalValue(device, "check_Settings_ITITP") || ITI <= 0)

		if(ITI <= 0)
			ExecuteListOfFunctions(funcList)
		elseif(background)
			DQS_StartBackgroundTimer(device, ITI, funcList)
		else
			aborted = RA_WaitUntiIITIDone(device, ITI)

			if(aborted)
				RA_FinishAcquisition(device)
			else
				ExecuteListOfFunctions(funcList)
			endif
		endif

		return NaN
	endif

	if(background)
		TP_Setup(device, TEST_PULSE_BG_SINGLE_DEVICE | TEST_PULSE_DURING_RA_MOD)
		TPS_StartBackgroundTestPulse(device)
		funcList = "TPS_StopTestPulseSingleDevice(\"" + device + "\")" + ";" + "RA_Counter(\"" + device + "\")"
		DQS_StartBackgroundTimer(device, ITI, funcList)
	else
		TP_Setup(device, TEST_PULSE_FG_SINGLE_DEVICE | TEST_PULSE_DURING_RA_MOD)
		aborted = TPS_StartTestPulseForeground(device, elapsedTime = ITI)
		TP_Teardown(device)

		if(aborted)
			RA_FinishAcquisition(device)
		else
			ExecuteListOfFunctions(funcList)
		endif
	endif
End

/// @brief Calculate the total number of sweeps for repeated acquisition
///
/// Helper function for plain calculation without lead and follower logic
static Function RA_GetTotalNumberOfSweepsLowLev(device)
	string device

	if(DAG_GetNumericalValue(device, "Check_DataAcq_Indexing"))
		return GetValDisplayAsNum(device, "valdisp_DataAcq_SweepsInSet")
	else
		return IDX_CalculcateActiveSetCount(device)
	endif
End

/// @brief Calculate the total number of sweeps for repeated acquisition
static Function RA_GetTotalNumberOfSweeps(device)
	string device

	variable i, numFollower, numTotalSweeps
	string followerPanelTitle

	numTotalSweeps = RA_GetTotalNumberOfSweepsLowLev(device)

	if(DeviceHasFollower(device))
		SVAR listOfFollowerDevices = $GetFollowerList(device)
		numFollower = ItemsInList(listOfFollowerDevices)
		for(i = 0; i < numFollower; i += 1)
			followerPanelTitle = StringFromList(i, listOfFollowerDevices)

			numTotalSweeps = max(numTotalSweeps, RA_GetTotalNumberOfSweepsLowLev(followerPanelTitle))
		endfor
	endif

	return numTotalSweeps
End

/// @brief Update the "Sweeps remaining" control
Function RA_StepSweepsRemaining(device)
	string device

	if(DAG_GetNumericalValue(device, "Check_DataAcq1_RepeatAcq"))
		variable numTotalSweeps = RA_GetTotalNumberOfSweeps(device)
		NVAR count = $GetCount(device)

		SetValDisplay(device, "valdisp_DataAcq_TrialsCountdown", var = numTotalSweeps - count - 1)
	else
		SetValDisplay(device, "valdisp_DataAcq_TrialsCountdown", var = 0)
	endif
End

/// @brief Function gets called after the first sweep is already
/// acquired and if repeated acquisition is on
static Function RA_Start(device)
	string device

	variable numTotalSweeps

#ifdef PERFING_RA
	RA_PerfInitialize(device)
#endif

	numTotalSweeps = RA_GetTotalNumberOfSweeps(device)

	if(numTotalSweeps == 1)
		return RA_FinishAcquisition(device)
	endif

	RA_StepSweepsRemaining(device)
	RA_HandleITI(device)
End

Function RA_Counter(device)
	string device

	variable numTotalSweeps, runMode
	string str

	runMode = ROVar(GetDataAcqRunMode(device))

	if(runMode == DAQ_NOT_RUNNING)
		return NaN
	endif

	DAP_ApplyDelayedClampModeChange(device)

	NVAR count = $GetCount(device)
	NVAR activeSetCount = $GetActiveSetCount(device)

	count += 1
	activeSetCount -= 1

#ifdef PERFING_RA
	RA_PerfAddMark(device, count)
#endif

	sprintf str, "count=%d, activeSetCount=%d\r" count, activeSetCount
	DEBUGPRINT(str)

	RA_StepSweepsRemaining(device)
	IDX_HandleIndexing(device)

	numTotalSweeps = RA_GetTotalNumberOfSweeps(device)

	if(Count < numTotalSweeps)
		AssertOnAndClearRTError()
		try
			DC_Configure(device, DATA_ACQUISITION_MODE)

			if(DAG_GetNumericalValue(device, "Check_Settings_BackgrndDataAcq"))
				DQS_BkrdDataAcq(device)
			else
				DQS_DataAcq(device)
			endif
		catch
			ClearRTError()
			RA_FinishAcquisition(device)
		endtry
	else
		RA_FinishAcquisition(device)
	endif
End

static Function RA_FinishAcquisition(device)
	string device

	string list
	variable numEntries, i

	DQ_StopDAQDeviceTimer(device)

#ifdef PERFING_RA
	RA_PerfFinish(device)
#endif

	list = GetListofLeaderAndPossFollower(device)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		DAP_OneTimeCallAfterDAQ(StringFromList(i, list), DQ_STOP_REASON_FINISHED)
	endfor
End

static Function RA_BckgTPwithCallToRACounter(device)
	string device

	variable numTotalSweeps
	NVAR count = $GetCount(device)

	numTotalSweeps = RA_GetTotalNumberOfSweeps(device)

	if(Count < (numTotalSweeps - 1))
		RA_HandleITI(device)
	else
		RA_FinishAcquisition(device)
	endif
End

static Function RA_StartMD(device)
	string device

	variable i, numFollower, numTotalSweeps
	string followerPanelTitle

#ifdef PERFING_RA
	RA_PerfInitialize(device)
#endif

	RA_StepSweepsRemaining(device)

	numTotalSweeps = RA_GetTotalNumberOfSweeps(device)

	if(numTotalSweeps == 1)
		return RA_FinishAcquisition(device)
	endif

	if(DeviceHasFollower(device))
		SVAR listOfFollowerDevices = $GetFollowerList(device)
		numFollower = ItemsInList(listOfFollowerDevices)
		for(i = 0; i < numFollower; i += 1)
			followerPanelTitle = StringFromList(i, listOfFollowerDevices)

			NVAR followerCount = $GetCount(followerPanelTitle)
			followerCount = 0

			RA_StepSweepsRemaining(followerPanelTitle)
		endfor
	endif

	RA_HandleITI_MD(device)
End

Function RA_CounterMD(device)
	string device

	variable numTotalSweeps
	NVAR count = $GetCount(device)
	NVAR activeSetCount = $GetActiveSetCount(device)
	variable i, runMode
	string str

	runMode = ROVar(GetDataAcqRunMode(device))

	if(runMode == DAQ_NOT_RUNNING)
		return NaN
	endif

	DAP_ApplyDelayedClampModeChange(device)

	Count += 1
	ActiveSetCount -= 1

#ifdef PERFING_RA
	RA_PerfAddMark(device, count)
#endif

	sprintf str, "count=%d, activeSetCount=%d\r" count, activeSetCount
	DEBUGPRINT(str)

	RA_StepSweepsRemaining(device)
	IDX_HandleIndexing(device)

	numTotalSweeps = RA_GetTotalNumberOfSweeps(device)

	if(count < numTotalSweeps)
		DQM_StartDAQMultiDevice(device, initialSetupReq=0)
	else
		RA_FinishAcquisition(device)
	endif
End

static Function RA_BckgTPwithCallToRACounterMD(device)
	string device

	variable numTotalSweeps
	NVAR count = $GetCount(device)

	numTotalSweeps = RA_GetTotalNumberOfSweeps(device)

	if(count < (numTotalSweeps - 1))
		RA_HandleITI_MD(device)
	else
		RA_FinishAcquisition(device)
	endif
End

static Function RA_AreLeaderAndFollowerFinished()

	variable numCandidates, i, row
	string listOfCandidates, candidate

	WAVE ActiveDeviceList = GetDQMActiveDeviceList()

	if(DimSize(ActiveDeviceList, ROWS) == 0)
		return 1
	endif

	listOfCandidates = GetListofLeaderAndPossFollower(ITC1600_FIRST_DEVICE)
	numCandidates = ItemsInList(listOfCandidates)

	for(i = 0; i < numCandidates; i += 1)
		candidate = StringFromList(i, listOfCandidates)
		NVAR deviceID = $GetDAQDeviceID(candidate)

		row = DQM_GetActiveDeviceRow(deviceID)
		if(IsFinite(row)) // device still active
			return 0
		endif
	endfor

	return 1
End

static Function RA_YokedRAStartMD(device)
	string device

	// catches independent devices and leader with no follower
	if(!DeviceCanFollow(device) || !DeviceHasFollower(ITC1600_FIRST_DEVICE))
		RA_StartMD(device)
		return NaN
	endif

	if(RA_AreLeaderAndFollowerFinished())
		RA_StartMD(ITC1600_FIRST_DEVICE)
	endif
End

static Function RA_YokedRABckgTPCallRACounter(device)
	string device

	// catches independent devices and leader with no follower
	if(!DeviceCanFollow(device) || !DeviceHasFollower(ITC1600_FIRST_DEVICE))
		RA_BckgTPwithCallToRACounterMD(device)
		return NaN
	endif

	if(RA_AreLeaderAndFollowerFinished())
		RA_BckgTPwithCallToRACounterMD(ITC1600_FIRST_DEVICE)
	endif
End

/// @brief Return one if we are acquiring currently the very first sweep of a
///        possible repeated acquisition cycle. Zero means that we acquire a later
///        sweep than the first one in a repeated acquisition cycle.
Function RA_IsFirstSweep(device)
	string device

	NVAR count = $GetCount(device)
	return !count
End

/// @brief Allows skipping forward or backwards the sweep count during data acquistion
///
/// @param device       device
/// @param skipCount        The number of sweeps to skip (forward or backwards)
///                         during repeated acquisition
/// @param limitToSetBorder [optional, defaults to false] Limits skipCount so
///                         that we don't skip further than after the last sweep of the
///                         stimset with the most number of sweeps.
/// @param document         [optional, defaults to false] Add labnotebook
///                         entries to document the sweep skipping.
Function RA_SkipSweeps(device, skipCount, [limitToSetBorder, document])
	string device
	variable skipCount, limitToSetBorder, document

	variable numFollower, i, sweepsInSet, recalculatedCount
	string followerPanelTitle, msg

	NVAR count = $GetCount(device)
	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)
	NVAR activeSetCount = $GetActiveSetCount(device)

	//Skip sweeps if, and only if, data acquisition is ongoing.
	if(dataAcqRunMode == DAQ_NOT_RUNNING)
		return NaN
	endif

	if(ParamIsDefault(limitToSetBorder))
		limitToSetBorder = 0
	else
		limitToSetBorder = !!limitToSetBorder
	endif

	if(ParamIsDefault(document))
		document = 0
	else
		document = !!document
	endif

	sprintf msg, "skipCount (as passed) %d, limitToSetBorder %d, count %d, activeSetCount %d", skipCount, limitToSetBorder, count, activeSetCount
	DEBUGPRINT(msg)

	if(limitToSetBorder)
		if(skipCount > 0)
			skipCount = limit(skipCount, 0, activeSetCount - 1)
		else
			sweepsInSet = IDX_CalculcateActiveSetCount(device)
			skipCount = limit(skipCount, activeSetCount - sweepsInSet - 1, 0)
		endif
	endif

	recalculatedCount = RA_SkipSweepCalc(device, skipCount)
	skipCount = recalculatedCount - count
	count = recalculatedCount

	activeSetCount -= skipCount

	sprintf msg, "skipCount (possibly clipped) %g, activeSetCount (adjusted) %d, count (adjusted) %d\r", skipCount, activeSetCount, count
	DEBUGPRINT(msg)

	if(document)
		RA_DocumentSweepSkipping(device, skipCount)
	endif

	RA_StepSweepsRemaining(device)

	if(DeviceHasFollower(device))
		SVAR listOfFollowerDevices = $GetFollowerList(device)
		numFollower = ItemsInList(listOfFollowerDevices)
		for(i = 0; i < numFollower; i += 1)
			followerPanelTitle = StringFromList(i, listOfFollowerDevices)
			NVAR followerCount = $GetCount(followerPanelTitle)
			followerCount = RA_SkipSweepCalc(followerPanelTitle, skipCount)

			if(document)
				RA_DocumentSweepSkipping(device, skipCount)
			endif

			RA_StepSweepsRemaining(followerPanelTitle)
		endfor
	endif
End

/// @brief Document the number of skipped sweeps
static Function RA_DocumentSweepSkipping(string device, variable skipCount)

	variable sweepNo, skipCountExisting

	sweepNo = AS_GetSweepNumber(device)

	WAVE numericalValues = GetLBNumericalValues(device)
	skipCountExisting = GetLastSettingIndep(numericalValues, sweepNo, SKIP_SWEEPS_KEY, UNKNOWN_MODE, defValue = 0)

	Make/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) vals = NaN
	vals[0][0][INDEP_HEADSTAGE] = skipCountExisting + skipCount
	Make/T/FREE/N=(3, 1) keys
	keys[0] = SKIP_SWEEPS_KEY
	keys[1] = "a. u."
	keys[2] = "0.1"

	ED_AddEntriesToLabnotebook(vals, keys, sweepNo, device, UNKNOWN_MODE)
End

///@brief Returns valid count after adding skipCount
///
///@param device device
///@param skipCount The number of sweeps to skip (forward or backwards) during repeated acquisition.
static Function RA_SkipSweepCalc(device, skipCount)
	string device
	variable skipCount

	string msg
	variable totSweeps

	totSweeps = RA_GetTotalNumberOfSweeps(device)
	NVAR count = $GetCount(device)

	sprintf msg, "skipCount %d, totSweeps %d, count %d", skipCount, totSweeps, count
	DEBUGPRINT(msg)

	if(DAG_GetNumericalValue(device, "Check_DataAcq1_RepeatAcq"))
		// RA_counter and RA_counterMD increment count at initialization, -1 accounts for this and allows a skipping back to sweep 0
		return DEBUGPRINTv(min(totSweeps - 1, max(count + skipCount, -1)))
	else
		return DEBUGPRINTv(0)
	endif
End

static Function RA_PerfInitialize(device)
	string device

	KillOrMoveToTrash(wv = GetRAPerfWave(device))
	WAVE perfWave = GetRAPerfWave(device)

	perfWave[0] = RelativeNowHighPrec()
End

static Function RA_PerfAddMark(device, idx)
	string device
	variable idx

	WAVE perfWave = GetRAPerfWave(device)

	EnsureLargeEnoughWave(perfWave, minimumSize = idx, initialValue = NaN)
	perfWave[idx] = RelativeNowHighPrec()
End

static Function RA_PerfFinish(device)
	string device

	WAVE perfWave = GetRAPerfWave(device)

	NVAR count = $GetCount(device)

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

/// @brief Continue DAQ if requested or stop it
///
/// @param device  device
/// @param multiDevice [optional, defaults to false] DAQ mode
Function RA_ContinueOrStop(device, [multiDevice])
	string device
	variable multiDevice

	if(ParamIsDefault(multiDevice))
		multiDevice = 0
	else
		multiDevice = !!multiDevice
	endif

	if(RA_IsFirstSweep(device))
		if(DAG_GetNumericalValue(device, "Check_DataAcq1_RepeatAcq"))
			if(multiDevice)
				RA_YokedRAStartMD(device)
			else
				RA_Start(device)
			endif
		else
			DAP_OneTimeCallAfterDAQ(device, DQ_STOP_REASON_FINISHED)
		endif
	else
		if(multiDevice)
			RA_YokedRABckgTPCallRACounter(device)
		else
			RA_BckgTPwithCallToRACounter(device)
		endif
	endif
End
