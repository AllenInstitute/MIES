#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @brief Create MIES data folder architecture and create some panels
Function IM_InitiateMIES()
	createDFWithAllParents("root:MIES:Amplifiers:Settings")

	// stores lists of data that the background timer uses
	createDFWithAllParents("root:MIES:ITCDevices:ActiveITCDevices:Timer")

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
//=========================================================================================

Function IM_MakeGlobalsAndWaves(panelTitle)// makes the necessary parameters for the locked device to function.
	string panelTitle

	HSU_CreateDataFolderForLockdDev(panelTitle)
	HSU_UpdateChanAmpAssignStorWv(panelTitle)
	DAP_FindConnectedAmps(panelTitle)

	dfref data = HSU_GetDevicePathFromTitle(panelTitle)
	make /o /n= (1,8) data:ITCDataWave
	make /o /n= (2,4) data:ITCChanConfigWave
	make /o /n= (2,4) data:ITCFIFOAvailAllConfigWave
	make /o /n= (2,4) data:ITCFIFOPositionAllConfigWave
	make /o /i /n = 4 data:ResultsWave

	dfref dfr = HSU_GetDeviceTestPulseFromTitle(panelTitle)
	make /o /n= (1,8) dfr:TestPulseITC
	make /o /n= (1,8) dfr:InstResistance
	make /o /n= (1,8) dfr:Resistance
	make /o /n= (1,8) dfr:SSResistance
End

//=========================================================================================
// FUNCTION BELOW WITH THE PATH PREFIX RETURN PATHS TO ALL MIES FOLDERS AS WELL AS A FEW SPECIAL CASE PATHS
//=========================================================================================
///@deprecated use @ref GetMiesPathAsString() instead
Function /T Path_MIESfolder(panelTitle)
	string panelTitle
	string pathToMIES // = "root:MIES"
	sprintf pathToMIES, "root:MIES"
	return pathToMIES
End
//=========================================================================================
///@deprecated use GetAmplifierFolderAsString() or GetAmplifierFolder()
Function /T Path_AmpFolder(panelTitle)
	string panelTitle
	string pathToAmpFolder =Path_MIESfolder(panelTitle) + ":Amplifiers"
	return pathToAmpFolder
End
//=========================================================================================
///@deprecated use GetAmpSettingsFolderAsString() or GetAmpSettingsFolder()
Function /T Path_AmpSettingsFolder(panelTitle)
	string panelTitle
	string pathToAmpSettingsFolder
	sprintf pathToAmpSettingsFolder, "%s:Settings" Path_AmpFolder(panelTitle)
	return pathToAmpSettingsFolder
End
//=========================================================================================

/// @todo take no argument as it is not used
Function /T Path_ITCDevicesFolder(panelTitle)
	string panelTitle
	string pathToITCDevicesFolder // = Path_MIESfolder(panelTitle) + ":ITCDevices"
	sprintf pathToITCDevicesFolder, "%s:ITCDevices" Path_MIESfolder(panelTitle)
	return pathToITCDevicesFolder
End
//=========================================================================================
Function /T Path_ActiveITCDevicesFolder(panelTitle)
	string panelTitle
	string ActiveITCDevicesFolder = Path_ITCDevicesFolder(panelTitle) + ":ActiveITCDevices"
	return ActiveITCDevicesFolder
End
//=========================================================================================
Function /T Path_ActITCDevTestPulseFolder(panelTitle)
	string panelTitle
	string ActITCDevTestPulseFolder = Path_ActiveITCDevicesFolder(panelTitle) + ":TestPulse"
	return ActITCDevTestPulseFolder
End
//=========================================================================================
Function /T Path_ActITCDevTestTimerFolder(panelTitle)
	string panelTitle
	string ActITCDevTestTimerFolder = Path_ActiveITCDevicesFolder(panelTitle) + ":Timer"
	
	return ActITCDevTestTimerFolder
End
//=========================================================================================
//=========================================================================================
// TB in the long run, I would propose to rewrite data folder returning functions like
// HSU_DataFullFolderPathString to always return a valid datafolder reference.
// As always checking if the folder exists is error-prone
Function/S GetListOfYokedDACs()

	dfref dfr = $HSU_DataFullFolderPathString(ITC1600_FIRST_DEVICE)
	if(!DataFolderExistsDFR(dfr))
		return ""
	endif

	SVAR/Z/SDFR=dfr ListOfFollowerITC1600s
	if(SVAR_Exists(ListOfFollowerITC1600s))
		return ListOfFollowerITC1600s
	endif

	return ""
End
//=========================================================================================

static Function IgorBeforeQuitHook(igorApplicationNameStr)
	string igorApplicationNameStr

	DAP_UnlockAllDevices()
	return 0
End

static Function IgorBeforeNewHook(igorApplicationNameStr)
	string igorApplicationNameStr

	DAP_UnlockAllDevices()
	return 0
End
