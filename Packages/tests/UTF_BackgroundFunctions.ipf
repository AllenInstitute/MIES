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

Function StopTPAfterFiveSeconds_IGNORE(STRUCT WMBackgroundStruct &s)

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	PGC_SetAndActivateControl(device, "StartTestPulseButton")

	return 1
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

	WAVE settings = GetTPSettings(device)

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	Duplicate/FREE/RMD=[FindDimLabel(settings, ROWS, "autoTPEnable")][0, NUM_HEADSTAGES - 1] settings, autoTPEnable
	Redimension/N=(numpnts(autoTPEnable)) autoTPEnable

	autoTPEnable[] = statusHS[p] && autoTPEnable[p]

	if(Sum(autoTPEnable) == 0)
		PGC_SetAndActivateControl(device, "StartTestPulseButton")
		return 1
	endif

	return 0
End
