#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = BackgroundFunctions

/// @brief Background function to wait until DAQ is finished.
Function WaitUntilDAQDone_IGNORE(STRUCT WMBackgroundStruct &s)

	string dev
	variable numEntries, i

	SVAR devices = $GetLockedDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		dev = StringFromList(i, devices)

		NVAR dataAcqRunMode = $GetDataAcqRunMode(dev)

		if(IsNaN(dataAcqRunMode))
			// not active
			continue
		endif

		if(dataAcqRunMode != DAQ_NOT_RUNNING)
			return 0
		endif
	endfor

	return 1
End

/// @brief Background function to wait until TP is finished.
///
/// If it is finished pushes the next two, one setup and the
/// corresponding `Test`, testcases to the queue.
Function WaitUntilTPDone_IGNORE(STRUCT WMBackgroundStruct &s)

	string device
	variable numEntries, i

	SVAR devices = $GetLockedDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devices)

		NVAR runMode = $GetTestpulseRunMode(device)

		if(IsNaN(runMode))
			// not active
			continue
		endif

		if(runMode != TEST_PULSE_NOT_RUNNING)
			return 0
		endif
	endfor

	return 1
End

Function StopAcqDuringITI_IGNORE(STRUCT WMBackgroundStruct &s)

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		PGC_SetAndActivateControl(device, "DataAcquireButton")
		return 1
	endif

	return 0
End

Function StopAcqByUnlocking_IGNORE(STRUCT WMBackgroundStruct &s)

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		PGC_SetAndActivateControl(device, "button_SettingsPlus_unLockDevic")
		return 1
	endif

	return 0
End

Function StopAcqByUncompiled_IGNORE(STRUCT WMBackgroundStruct &s)

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		ForceRecompile()
		return 1
	endif

	return 0
End

Function StartTPDuringITI_IGNORE(STRUCT WMBackgroundStruct &s)

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		PGC_SetAndActivateControl(device, "StartTestPulseButton")
		return 1
	endif

	return 0
End

Function SkipToEndDuringITI_IGNORE(STRUCT WMBackgroundStruct &s)

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO)
		return 1
	endif

	return 0
End

Function SkipSweepBackDuringITI_IGNORE(STRUCT WMBackgroundStruct &s)

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		CHECK_EQUAL_VAR(AFH_GetLastSweepAcquired(device), 0)
		RA_SkipSweeps(device, -1, SWEEP_SKIP_AUTO)
		return 1
	endif

	return 0
End

Function StopAcq_IGNORE(STRUCT WMBackgroundStruct &s)

	SVAR     devices = $GetLockedDevices()
	string   device  = StringFromList(0, devices)
	variable runMode = ROVAR(GetDataAcqRunMode(device))

	if(runMode == DAQ_NOT_RUNNING)
		return 0
	endif

	PGC_SetAndActivateControl(device, "DataAcquireButton")

	return 1
End

Function JustDelay_IGNORE(STRUCT WMBackgroundStruct &s)

	return 1
End

Function AutoPipetteOffsetAndStopTP_IGNORE(STRUCT WMBackgroundStruct &s)

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	PGC_SetAndActivateControl(device, "button_DataAcq_AutoPipOffset_VC")
	PGC_SetAndActivateControl(device, "StartTestPulseButton")

	return 1
End

/// Call AI_ZeroAmps for headstage 1 or all headstages, see `root:zeroAmpsAllHeadstages`, with
/// running test pulse and stop the test pulse afterwards
///
/// The test pulse results used by AI_ZeroAmps depend on the hardware setup, e.g. a loopback has no
/// baseline current, so they are replaced by defined ones before: headstage 0 below and headstage 1
/// above the zero tolerance of AI_ZeroAmps.
///
/// Stores the test pulse results and the pipette offset before and after of headstage 0 and 1
/// in `root:zeroAmpsResults`.
Function ZeroAmpsAndStopTP_IGNORE(STRUCT WMBackgroundStruct &s)

	variable headstage
	variable numHeadstages = 2

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	WAVE TPResults = GetTPResults(device)
	for(headstage = 0; headstage < numHeadstages; headstage += 1)
		if(!IsFinite(TPResults[%BaselineSteadyState][headstage]))
			// wait for the test pulse results
			return 0
		endif
	endfor

	// no new test pulse results can arrive until AI_ZeroAmps is called, as both run in the main thread
	TPResults[%BaselineSteadyState][0]                      = 0
	TPResults[%BaselineSteadyState][1]                      = 200
	TPResults[%ResistanceSteadyState][0, numHeadstages - 1] = 100

	Make/O/D/N=(4, numHeadstages) root:zeroAmpsResults/WAVE=results
	SetDimensionLabels(results, "Baseline;Resistance;OffsetBefore;OffsetAfter", ROWS)

	for(headstage = 0; headstage < numHeadstages; headstage += 1)
		results[%Baseline][headstage]     = TPResults[%BaselineSteadyState][headstage]
		results[%Resistance][headstage]   = TPResults[%ResistanceSteadyState][headstage]
		results[%OffsetBefore][headstage] = AI_ReadFromAmplifier(device, headstage, V_CLAMP_MODE, MCC_PIPETTEOFFSET_FUNC)
	endfor

	NVAR allHeadstages = root:zeroAmpsAllHeadstages
	if(allHeadstages)
		AI_ZeroAmps(device)
	else
		AI_ZeroAmps(device, headStage = 1)
	endif

	for(headstage = 0; headstage < numHeadstages; headstage += 1)
		results[%OffsetAfter][headstage] = AI_ReadFromAmplifier(device, headstage, V_CLAMP_MODE, MCC_PIPETTEOFFSET_FUNC)
	endfor

	PGC_SetAndActivateControl(device, "StartTestPulseButton")

	return 1
End

/// Change the holding command during a running test pulse and stop the test pulse afterwards
///
/// Reads the headstage, clamp mode and new holding command from `root:holdingChangeDuringTP`, waits until
/// the test pulse has cycled a few times, changes the holding command of all active headstages and stores the
/// TPStorage index at the time of the change in `root:holdingChangeDuringTP[%IndexAtChange]`. The test pulse
/// is stopped after it
/// has cycled a few more times.
Function ChangeHoldingAndStopTP_IGNORE(STRUCT WMBackgroundStruct &s)

	variable index, numCycles
	string device

	numCycles = 10

	SVAR devices = $GetLockedDevices()
	device = StringFromList(0, devices)

	if(!TP_CheckIfTestpulseIsRunning(device))
		return 1
	endif

	WAVE settings  = root:holdingChangeDuringTP
	WAVE TPStorage = GetTPStorage(device)
	index = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)

	if(IsNaN(settings[%IndexAtChange]))
		if(!TP_TestPulseHasCycled(device, numCycles))
			return 0
		endif

		settings[%IndexAtChange] = index
		AI_WriteToAmplifier(device, settings[%Headstage], settings[%ClampMode], MCC_HOLDING_FUNC, settings[%Holding], sendToAll = 1)

		return 0
	endif

	if((index - settings[%IndexAtChange]) <= numCycles)
		return 0
	endif

	PGC_SetAndActivateControl(device, "StartTestPulseButton")

	return 1
End

Function StopTP_IGNORE(STRUCT WMBackgroundStruct &s)

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)
	PGC_SetAndActivateControl(device, "StartTestPulseButton")

	return 1
End

Function StartAcq_IGNORE(STRUCT WMBackgroundStruct &s)

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)
	PGC_SetAndActivateControl(device, "DataAcquireButton")
	CtrlNamedBackGround DAQWatchdog, start, period=120, proc=WaitUntilDAQDone_IGNORE

	return 1
End

Function ChangeStimSet_IGNORE(STRUCT WMBackgroundStruct &s)

	string ctrl
	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)

	NVAR tpRunMode = $GetTestpulseRunMode(device)

	if(dataAcqRunMode != DAQ_NOT_RUNNING && !(tpRunMode & TEST_PULSE_DURING_RA_MOD))
		ctrl = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		PGC_SetAndActivateControl(device, ctrl, val = GetPopupMenuIndex(device, ctrl) + 1)

		return 1
	endif

	return 0
End

Function ClampModeDuringSweep_IGNORE(STRUCT WMBackgroundStruct &s)

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)

	if(dataAcqRunMode != DAQ_NOT_RUNNING)
		PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val = 1)
		return 1
	endif

	return 0
End

Function ClampModeDuringTP_IGNORE(STRUCT WMBackgroundStruct &s)

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	NVAR tpRunMode = $GetTestpulseRunMode(device)

	if(tpRunMode != TEST_PULSE_NOT_RUNNING)
		PGC_SetAndActivateControl(device, DAP_GetClampModeControl(V_CLAMP_MODE, 1), val = 1)
		return 1
	endif

	return 0
End

Function ClampModeDuringITI_IGNORE(STRUCT WMBackgroundStruct &s)

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)

	if(IsFinite(dataAcqRunMode) && dataAcqRunMode != DAQ_NOT_RUNNING && IsDeviceActiveWithBGTask(device, TASKNAME_TIMERMD))
		PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val = 1)
		return 1
	endif

	return 0
End

Function AddLabnotebookEntries_IGNORE(STRUCT WMBackgroundStruct &s)

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		// add entry for AS_ITI
		Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
		Make/T/FREE/N=(LABNOTEBOOK_LAYER_COUNT) valuesText = ""
		values[0] = AS_ITI
		ED_AddEntryToLabnotebook(device, "AcqStateTrackingValue_AS_ITI", values)
		valuesText[0] = AS_StateToString(AS_ITI)
		ED_AddEntryToLabnotebook(device, "AcqStateTrackingValue_AS_ITI", valuesText)
		return 1
	endif

	return 0
End

Function StopTPWhenWeHaveOne(STRUCT WMBackgroundStruct &s)

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	if(TP_TestPulseHasCycled(device, 1))
		PGC_SetAndActivateControl(device, "StartTestPulseButton")
		return 1
	endif

	return 0
End

Function StopTPWhenFinished(STRUCT WMBackgroundStruct &s)

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	if(!TP_AutoTPActive(device))
		PGC_SetAndActivateControl(device, "StartTestPulseButton")
		return 1
	endif

	return 0
End
