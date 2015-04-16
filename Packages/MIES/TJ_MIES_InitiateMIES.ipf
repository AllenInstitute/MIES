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
