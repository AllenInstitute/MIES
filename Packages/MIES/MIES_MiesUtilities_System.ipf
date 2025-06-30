#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_MIESUTILS_SYSTEM
#endif // AUTOMATED_TESTING

// @brief Common setup routine for all MIES background tasks for DAQ, TP and pressure control
Function SetupBackgroundTasks()

	CtrlNamedBackground $TASKNAME_TIMERMD, dialogsOK=0, period=6, proc=DQM_Timer
	CtrlNamedBackground $TASKNAME_FIFOMONMD, dialogsOK=0, period=1, proc=DQM_FIFOMonitor
	CtrlNamedBackground $TASKNAME_FIFOMON, dialogsOK=0, period=5, proc=DQS_FIFOMonitor
	CtrlNamedBackground $TASKNAME_TIMER, dialogsOK=0, period=5, proc=DQS_Timer
	CtrlNamedBackground $TASKNAME_TPMD, dialogsOK=0, period=5, proc=TPM_BkrdTPFuncMD
	CtrlNamedBackground $TASKNAME_TP, dialogsOK=0, period=5, proc=TPS_TestPulseFunc
	CtrlNamedBackground P_ITC_FIFOMonitor, dialogsOK=0, period=10, proc=P_ITC_FIFOMonitorProc
End

/// @file MIES_MiesUtilities_System.ipf
/// @brief This file holds MIES utility functions related to the system

/// @brief Save the current experiment under a new name and clear all/some data
/// @param mode mode for generating the experiment name, one of @ref SaveExperimentModes
Function SaveExperimentSpecial(variable mode)

	variable numDevices, i, ret, pos
	variable zeroSweepCounter, keepOtherData, showSaveDialog, useNewNWBFile
	string path, devicesWithData, activeDevices, device, expLoc, list, refNum
	string expName, substr

	if(mode == SAVE_AND_CLEAR)
		zeroSweepCounter = 1
		keepOtherData    = 0
		showSaveDialog   = 1
		useNewNWBFile    = 1
	elseif(mode == SAVE_AND_SPLIT)
		zeroSweepCounter = 0
		keepOtherData    = 1
		showSaveDialog   = 0
		useNewNWBFile    = 0
	else
		FATAL_ERROR("Unknown mode")
	endif

	// We want never to loose data so we do the following:
	// Case 1: Unitled experiment
	// - Save (with dialog if requested) without fileNameSuffix suffix
	// - Save (with dialog if requested) with fileNameSuffix suffix
	// - Clear data
	// - Save without dialog
	//
	// Case 2: Experiment with name
	// - Save without dialog
	// - Save (with dialog if requested) with fileNameSuffix suffix
	// - Clear data
	// - Save without dialog
	//
	// User aborts in the save dialogs always results in a complete abort

	expName = GetExperimentName()

	if(!cmpstr(expName, UNTITLED_EXPERIMENT))
		ret = SaveExperimentWrapper("", "_" + GetTimeStamp() + PACKED_FILE_EXPERIMENT_SUFFIX, overrideInteractiveMode = showSaveDialog)

		if(ret)
			return NaN
		endif

		// the user might have changed the experiment name in the dialog
		expName = GetExperimentName()
	else
		SaveExperiment
	endif

	if(mode == SAVE_AND_SPLIT)
		expName = CleanupExperimentName(expName) + SIBLING_FILENAME_SUFFIX
	elseif(mode == SAVE_AND_CLEAR)
		expName = "_" + GetTimeStamp()
	endif

	// saved experiments are stored in the symbolic path "home"
	expLoc  = "home"
	expName = UniqueFileOrFolder(expLoc, expName, suffix = PACKED_FILE_EXPERIMENT_SUFFIX)

	ret = SaveExperimentWrapper(expLoc, expName, overrideInteractiveMode = showSaveDialog)

	if(ret)
		return NaN
	endif

	FUNCREF CALL_FUNCTION_LIST_PROTOTYPE_TS killFunc = KillOrMoveToTrashPath

	// remove sweep data from all devices with data
	devicesWithData = GetAllDevicesWithContent()
	numDevices      = ItemsInList(devicesWithData)
	for(i = 0; i < numDevices; i += 1)
		device = StringFromList(i, devicesWithData)

		path = GetDeviceDataPathAsString(device)
		killFunc(path)

		if(windowExists(device) && zeroSweepCounter)
			PGC_SetAndActivateControl(device, "SetVar_Sweep", val = 0)
		endif
	endfor

	if(!keepOtherData)
		// remove labnotebook
		path = GetLabNotebookFolderAsString()
		killFunc(path)

		path = GetCacheFolderAS()
		killFunc(path)

		list = GetListOfLockedDevices()
		CallFunctionForEachListItem(DAP_ClearCommentNotebook, list)

		DB_ClearAllGraphs()

		// remove other waves from active devices
		activeDevices = GetAllDevices()
		numDevices    = ItemsInList(activeDevices)
		for(i = 0; i < numDevices; i += 1)
			device = StringFromList(i, activeDevices)

			DFREF dfr = GetDevicePath(device)
			list = GetListOfObjects(dfr, "ChanAmpAssign_Sweep_*", fullPath = 1)
			CallFunctionForEachListItem_TS(killFunc, list)

			DFREF dfr = GetDeviceTestPulse(device)
			list = GetListOfObjects(dfr, "TPStorage_*", fullPath = 1)
			CallFunctionForEachListItem_TS(killFunc, list)

			DFREF dfr = GetDevicePath(device)
			list = GetListOfObjects(dfr, "Databrowser*", typeFlag = COUNTOBJECTS_DATAFOLDER, fullPath = 1)
			CallFunctionForEachListItem_TS(killFunc, list)

			RemoveTracesFromGraph(SCOPE_GetGraph(device))
		endfor
	endif

	SaveExperiment

	if(useNewNWBFile)

		KillWindow/Z HistoryCarbonCopy
		CreateHistoryNotebook()

		NWB_CloseAllNWBFiles()

		NVAR sesssionStartTime = $GetSessionStartTime()
		sesssionStartTime = DateTimeInUTC()
	endif
End

/// @brief Returns 1 if the user cancelled, zero if SaveExperiment was called
///
/// It is currently not possible to check if SaveExperiment was successfull
/// (E-Mail from Howard Rodstein WaveMetrics, 30 Jan 2015)
///
/// @param path                    Igor symbolic path where the experiment should be stored
/// @param filename 			   filename of the experiment *including* suffix, usually #PACKED_FILE_EXPERIMENT_SUFFIX
/// @param overrideInteractiveMode [optional, defaults to GetInteractiveMode()] Overrides the current setting of
///                                the interactive mode
Function SaveExperimentWrapper(string path, string filename, [variable overrideInteractiveMode])

	variable refNum, pathNeedsKilling

	if(ParamIsDefault(overrideInteractiveMode))
		NVAR interactiveMode = $GetInteractiveMode()
		overrideInteractiveMode = interactiveMode
	else
		overrideInteractiveMode = !!overrideInteractiveMode
	endif

	if(overrideInteractiveMode)
		Open/D/M="Save experiment"/F="All Files:.*;"/P=$path refNum as filename

		if(isEmpty(S_fileName))
			return 1
		endif
	else
		if(isEmpty(path))
			PathInfo Desktop
			if(!V_flag)
				NewPath/Q Desktop, SpecialDirPath("Desktop", 0, 0, 0)
			endif
			path             = "Desktop"
			pathNeedsKilling = 1
		endif
		Open/Z/P=$path refNum as filename

		if(pathNeedsKilling)
			KillPath/Z $path
		endif

		if(V_flag != 0)
			return 1
		endif

		Close refNum
	endif

	SaveExperiment as S_fileName
	return 0
End

/// @brief Starts with a new experiment.
///
/// You have to manually save before, see SaveExperimentWrapper()
Function NewExperiment()

	Execute/P/Q "NEWEXPERIMENT "
End

/// @brief Return if the function results are overriden for testing purposes
Function TestOverrideActive()

	variable numberOfOverrideWarnings

	WAVE/Z overrideResults = GetOverrideResults()

	if(WaveExists(overrideResults))
		numberOfOverrideWarnings = JWN_GetNumberFromWaveNote(overrideResults, "OverrideWarningIssued")
		if(IsNaN(numberOfOverrideWarnings))
			print "TEST OVERRIDE ACTIVE"
			JWN_SetNumberInWaveNote(overrideResults, "OverrideWarningIssued", 1)
		endif

		return 1
	endif

	return 0
End

Function HandleOutOfMemory(string device, string name)

	printf "The amount of free memory is too low to increase the %s wave, please create a new experiment.\r", name
	ControlWindowToFront()

	LOG_AddEntry(PACKAGE_MIES, "out of memory", stacktrace = 1)

	DQ_StopDAQ(device, DQ_STOP_REASON_OUT_OF_MEMORY, startTPAfterDAQ = 0)
	TP_StopTestPulse(device)
End
