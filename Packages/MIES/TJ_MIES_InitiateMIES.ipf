#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function IM_InitiateMIES()
	// Create MIES data folder architecture
	NewDataFolder /o root:MIES
	NewDataFolder /o root:MIES:Amplifiers
	NewDataFolder /o root:MIES:Amplifiers:Settings
	NewDataFolder /o root:MIES:Manipulators
	NewDataFolder /o root:MIES:Camera
	NewDataFolder /o root:MIES:LabNoteBook // saves history of device settings
	NewDataFolder /o root:MIES:ITCDevices
	NewDataFolder /o root:MIES:ITCDevices:ActiveITCDevices // stores lists of data related to ITC devices actively acquiring data
	NewDataFolder /o root:MIES:ITCDevices:ActiveITCDevices:TestPulse // stores lists of data related to ITC devices actively running a test pulse
	NewDataFolder /o root:MIES:ITCDevices:ActiveITCDevices:Timer // stores lists of data that the background timer uses
	
	string /G root:MIES:ITCDevices:ITCPanelTitleList
	
	// Initiate wave builder - includes making wave builder panel
	WB_InitiateWaveBuilder()
	// make ephys panel
	execute "DA_Ephys()"
	// make data browser panel
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
Function /T Path_MIESfolder(panelTitle)
	string panelTitle
	string pathToMIES // = "root:MIES"
	sprintf pathToMIES, "root:MIES"
	return pathToMIES
End
//=========================================================================================
Function /T Path_AmpFolder(panelTitle)
	string panelTitle
	string pathToAmpFolder =Path_MIESfolder(panelTitle) + ":Amplifiers"
	return pathToAmpFolder
End
//=========================================================================================
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
Function /T Path_LabNoteBookFolder(panelTitle)
	string panelTitle
	string pathToLabNoteBookFolder // = Path_MIESfolder(panelTitle) + ":ITCDevices"
	sprintf pathToLabNoteBookFolder, "%s:LabNoteBook" Path_MIESfolder(panelTitle)
	return pathToLabNoteBookFolder
End

Function/DF DF_GetDeviceSpecificLabNotebook(panelTitle)
	string panelTitle

	return createDFWithAllParents(ED_DevSpecLabNotebkPathString(panelTitle))
End

Function/S ED_DevSpecLabNotebkPathString(panelTitle)
	string panelTitle

	string deviceType, deviceNumber, path
	variable ret


	ret = ParseDeviceString(panelTitle,deviceType,deviceNumber)
	ASSERT(ret,"Could not parse the panelTitle")
	
	string labNoteBookFolder
	sprintf labNoteBookFolder, "%s:%s:Device%s" Path_LabNoteBookFolder(panelTitle), DeviceType, DeviceNumber

	return labNoteBookFolder
End

// functions for geting the settings key directory
Function/DF DF_GetDevSpecLabNotebkSttngsKey(panelTitle)
	string panelTitle

	return createDFWithAllParents(ED_DevSpcLbNtbkPthStgStgsKey(panelTitle))
End

Function/S ED_DevSpcLbNtbkPthStgStgsKey(panelTitle)
	string panelTitle

	string deviceType, deviceNumber, path
	variable ret


	ret = ParseDeviceString(panelTitle,deviceType,deviceNumber)
	ASSERT(ret,"Could not parse the panelTitle")
	
	string labNoteBookFolder
	sprintf labNoteBookFolder, "%s:%s:Device%s:KeyWave" Path_LabNoteBookFolder(panelTitle), DeviceType, DeviceNumber

	return labNoteBookFolder
End

// functions for getting the settings history directory
Function/DF DF_GetDevSpecLabNotebkSttngs(panelTitle)
	string panelTitle

	return createDFWithAllParents(ED_DvSpcLbNtbkPthStgStgs(panelTitle))
End

Function/S ED_DvSpcLbNtbkPthStgStgs(panelTitle)
	string panelTitle

	string deviceType, deviceNumber, path
	variable ret


	ret = ParseDeviceString(panelTitle,deviceType,deviceNumber)
	ASSERT(ret,"Could not parse the panelTitle")
	
	string labNoteBookFolder
	sprintf labNoteBookFolder, "%s:%s:Device%s:settingsHistory" Path_LabNoteBookFolder(panelTitle), DeviceType, DeviceNumber

	return labNoteBookFolder
End

// functions for geting the text doc key directory
Function/DF DF_GetDevSpecLabNotebkTxtDocKey(panelTitle)
	string panelTitle

	return createDFWithAllParents(ED_DvSpcLbNtbkPthStgTxtDocKey(panelTitle))
End

Function/S ED_DvSpcLbNtbkPthStgTxtDocKey(panelTitle)
	string panelTitle

	string deviceType, deviceNumber, path
	variable ret


	ret = ParseDeviceString(panelTitle,deviceType,deviceNumber)
	ASSERT(ret,"Could not parse the panelTitle")
	
	string labNoteBookFolder
	sprintf labNoteBookFolder, "%s:%s:Device%s:TextDocKeyWave" Path_LabNoteBookFolder(panelTitle), DeviceType, DeviceNumber

	return labNoteBookFolder
End

// functions for getting the text documentation directory
Function/DF DF_GetDevSpecLabNotebkTxtDoc(panelTitle)
	string panelTitle

	return createDFWithAllParents(ED_DvSpcLbNtbkPthStgTxtDoc(panelTitle))
End

Function/S ED_DvSpcLbNtbkPthStgTxtDoc(panelTitle)
	string panelTitle

	string deviceType, deviceNumber, path
	variable ret


	ret = ParseDeviceString(panelTitle,deviceType,deviceNumber)
	ASSERT(ret,"Could not parse the panelTitle")
	
	string labNoteBookFolder
	sprintf labNoteBookFolder, "%s:%s:Device%s:textDocumentation" Path_LabNoteBookFolder(panelTitle), DeviceType, DeviceNumber

	return labNoteBookFolder
End
//=========================================================================================
Function /T Path_WaveBuilderFolder(panelTitle)
	string panelTitle
	string WaveBuilderFolder = Path_MIESfolder(panelTitle) + ":WaveBuilder"
	return WaveBuilderFolder
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
Function /T Path_WaveBuilderDataFolder(panelTitle)
	string panelTitle
	string WaveBuilderDataFolder = Path_WaveBuilderFolder(panelTitle) + ":Data"
	return WaveBuilderDataFolder
End
//=========================================================================================
Function /T Path_WBSvdStimSetParamFolder(panelTitle)
	string panelTitle
	string WBSvdStimSetParamFolder = Path_WaveBuilderFolder(panelTitle) + ":SavedStimulusSetParameters"
	return WBSvdStimSetParamFolder
End
//=========================================================================================
Function /T Path_WBSvdStimSetFolder(panelTitle)
	string panelTitle
	string WBSvdStimSetFolder = Path_WaveBuilderFolder(panelTitle) + ":SavedStimulusSets"
	return WBSvdStimSetFolder
End
//=========================================================================================
Function /T Path_WBSvdStimSetParamDAFolder(panelTitle)
	string panelTitle
	string WBSvdStimSetParamDAFolder = Path_WBSvdStimSetParamFolder(panelTitle) + ":DA"
	return WBSvdStimSetParamDAFolder
End
//=========================================================================================
Function /T Path_WBSvdStimSetParamTTLFolder(panelTitle)
	string panelTitle
	string WBSvdStimSetParamTTLFolder = Path_WBSvdStimSetParamFolder(panelTitle) + ":TTL"
	return WBSvdStimSetParamTTLFolder
End
//=========================================================================================
Function /T Path_WBSvdStimSetDAFolder(panelTitle)
	string panelTitle
	string WBSvdStimSetDAFolder =  Path_WBSvdStimSetFolder(panelTitle) + ":DA"
	return WBSvdStimSetDAFolder
End
//=========================================================================================
Function /T Path_WBSvdStimSetTTLFolder(panelTitle)
	string panelTitle
	string WBSvdStimSetTTLFolder =  Path_WBSvdStimSetFolder(panelTitle) + ":TTL"
	return WBSvdStimSetTTLFolder
End
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
