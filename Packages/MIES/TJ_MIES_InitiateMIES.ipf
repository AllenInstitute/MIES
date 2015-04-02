#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @brief Create MIES data folder architecture and create some panels
Function IM_InitiateMIES()
	createDFWithAllParents("root:MIES:Amplifiers:Settings")

	// stores lists of data that the background timer uses
	GetActiveITCDevicesTimerFolder()

	// the arduino sequencer does not handle datafolder creation reliable
	createDFWithAllParents("root:ImageHardware:Arduino")

	// stores lists of data related to ITC devices actively running a test pulse
	createDFWithAllParents("root:MIES:ITCDevices:ActiveITCDevices:TestPulse")
	createDFWithAllParents("root:MIES:LabNoteBook")
	createDFWithAllParents("root:MIES:Camera")
	createDFWithAllParents("root:MIES:Manipulators")

	string /G root:MIES:ITCDevices:ITCPanelTitleList

	WBP_CreateWaveBuilderPanel()
	execute "DA_Ephys()"
	execute "DataBrowser()"
End

/// @brief Returns 1 if the user cancelled, zero if SaveExperiment was called
///
/// It is currently not possible to check if SaveExperiment was successfull
/// (E-Mail from Howard Rodstein WaveMetrics, 30 Jan 2015)
Function SaveExperimentWithDialog(path, filename)
	string path, filename

	variable refNum

	Open/D/M="Save experiment"/F="All Files:.*;"/P=$path refNum as filename

	if(isEmpty(S_fileName))
		return 1
	endif

	SaveExperiment as S_fileName
	return 0
End

/// @brief Save the current experiment under a new name and clear all/some data
/// @param mode                                       mode for generating the experiment name, one of @ref SaveExperimentModes
/// @param zeroSweeps       [optional: default true]  should the sweep number be resetted to zero
/// @param keepOtherWaves   [optional: default false] only delete the sweep and sweep config waves
Function IM_SaveExperiment(mode, [zeroSweeps, keepOtherWaves])
	variable mode
	variable zeroSweeps, keepOtherWaves

	variable numDevices, i, ret, pos
	string path, devicesWithData, activeDevices, device, expLoc, list, refNum
	string expName, substr

	if(ParamIsDefault(zeroSweeps))
		zeroSweeps = 1
	else
		zeroSweeps = !!zeroSweeps
	endif

	if(ParamIsDefault(keepOtherWaves))
		keepOtherWaves = 0
	else
		keepOtherWaves = !!keepOtherWaves
	endif

	// We want never to loose data so we do the following:
	// Case 1: Unitled experiment
	// - Save with dialog without fileNameSuffix suffix
	// - Save with dialog with fileNameSuffix suffix
	// - Clear data
	// - Save without dialog
	//
	// Case 2: Experiment with name
	// - Save without dialog
	// - Save with dialog with fileNameSuffix suffix
	// - Clear data
	// - Save without dialog
	//
	// User aborts in the save dialogs always results in a complete abort

	expName = GetExperimentName()

	if(!cmpstr(expName, UNTITLED_EXPERIMENT))
		ret = SaveExperimentWithDialog("", "_" + GetTimeStamp() + PACKED_FILE_EXPERIMENT_SUFFIX)

		if(ret)
			return NaN
		endif

		// the user might have changed the experimet name in the dialog
		expName = GetExperimentName()
	else
		SaveExperiment
	endif

	if(mode == SAVE_AND_SPLIT)
		// Remove the following suffixes:
		// - sibling
		// - time stamp
		// - numerical suffixes added to prevent overwriting files
		expName  = RemoveEnding(expName, "_" + SIBLING_FILENAME_SUFFIX)
		expName  = RemoveEndingRegExp(expName, "_[[:digit:]]{4}_[[:digit:]]{2}_[[:digit:]]{2}_[[:digit:]]{6}") // example: 2015_03_25_213219
		expName  = RemoveEndingRegExp(expName, "_[[:digit:]]+") // example: _1, _123
		expName += SIBLING_FILENAME_SUFFIX
	elseif(mode == SAVE_AND_CLEAR)
		expName = "_" + GetTimeStamp()
	else
		ASSERT(0, "unknown mode")
	endif

	// saved experiments are stored in the symbolic path "home"
	expLoc  = "home"
	expName = UniqueFile(expLoc, expName, PACKED_FILE_EXPERIMENT_SUFFIX)

	ret = SaveExperimentWithDialog(expLoc, expName)

	if(ret)
		return NaN
	endif

	FUNCREF CALL_FUNCTION_LIST_PROTOTYPE killFunc = KillOrMoveToTrash

	// remove sweep data from all devices with data
	devicesWithData = GetAllDevicesWithData()
	numDevices = ItemsInList(devicesWithData)
	for(i = 0; i < numDevices; i += 1)
		device = StringFromList(i, devicesWithData)

		path = GetDeviceDataPathAsString(device)
		killFunc(path)

		if(windowExists(device) && zeroSweeps)
			SetSetVariable(device, "SetVar_Sweep", 0)
		endif
	endfor

	if(!keepOtherWaves)
		// remove labnotebook
		path = GetLabNotebookFolderAsString()
		killFunc(path)

		// remove other waves from active devices
		activeDevices = GetAllActiveDevices()
		numDevices = ItemsInList(activeDevices)
		for(i = 0; i < numDevices; i += 1)
			device = StringFromList(i, activeDevices)

			DFREF dfr = GetDevicePath(device)
			list = GetListOfWaves(dfr, "ChanAmpAssign_Sweep_*", fullPath=1)
			CallFunctionForEachListItem(killFunc, list)

			DFREF dfr = GetDeviceTestPulse(device)
			list = GetListOfWaves(dfr, "TPStorage_*", fullPath=1)
			CallFunctionForEachListItem(killFunc, list)
		endfor
	endif

	SaveExperiment
End

Function IM_MakeGlobalsAndWaves(panelTitle)// makes the necessary parameters for the locked device to function.
	string panelTitle

	HSU_CreateDataFolderForLockdDev(panelTitle)
	HSU_UpdateChanAmpAssignStorWv(panelTitle)
	DAP_FindConnectedAmps(panelTitle)

	dfref data = GetDevicePath(panelTitle)
	make /o /n= (1,8) data:ITCDataWave
	make /o /n= (2,4) data:ITCChanConfigWave
	make /o /n= (2,4) data:ITCFIFOAvailAllConfigWave
	make /o /n= (2,4) data:ITCFIFOPositionAllConfigWave
	make /o /i /n = 4 data:ResultsWave

	dfref dfr = GetDeviceTestPulse(panelTitle)
	make /o /n= (1,8) dfr:TestPulseITC
	make /o /n= (1,8) dfr:InstResistance
	make /o /n= (1,8) dfr:Resistance
	make /o /n= (1,8) dfr:SSResistance
End

/// @brief Remove all strings/variables/waves which should not
/// survive experiment reload/quit/saving
///
/// Mainly useful for temporaries which you want to recreate on initialization
static Function KillTemporaries()

	string trashFolders, path, allFolders
	variable numFolders, i

	DFREF dfr = GetMiesPath()

	KillStrings/Z dfr:version
	KillVariables/Z dfr:skip_free_memory_warning

	// try to delete all trash folders
	allFolders = StringByKey("FOLDERS", DataFolderDir(1, dfr))
	trashFolders = ListMatch(allFolders, TRASH_FOLDER_PREFIX + "*", ",")

	numFolders = ItemsInList(trashFolders, ",")
	for(i = 0; i < numFolders; i += 1)
		path = GetDataFolder(1, dfr) + StringFromList(i, trashFolders, ",")
		KillDataFolder/Z $path
	endfor

	RemoveEmptyDataFolder(dfr)
End

Function BeforeExperimentSaveHook(rN, fileName, path, type, creator, kind)
	Variable rN, kind
	String fileName, path, type, creator

	KillTemporaries()
End

static Function IgorBeforeQuitHook(igorApplicationNameStr)
	string igorApplicationNameStr

	DAP_UnlockAllDevices()
	KillTemporaries()
	return 0
End

static Function IgorBeforeNewHook(igorApplicationNameStr)
	string igorApplicationNameStr

	DAP_UnlockAllDevices()
	KillTemporaries()
	return 0
End
