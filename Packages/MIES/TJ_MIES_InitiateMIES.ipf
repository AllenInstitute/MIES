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
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	//string ChanAmpAssignPath = WavePath + ":ChanAmpAssign"
	//make /o /n = (12,8) $ChanAmpAssignPath = nan
	HSU_UpdateChanAmpAssignStorWv(panelTitle)
	DAP_FindConnectedAmps("button_Settings_UpdateAmpStatus")
	make /o /n= (1,8) $WavePath + ":ITCDataWave"
	make /o /n= (2,4) $WavePath + ":ITCChanConfigWave"
	make /o /n= (2,4) $WavePath + ":ITCFIFOAvailAllConfigWave"
	make /o /n= (2,4) $WavePath + ":ITCFIFOPositionAllConfigWave"
	make /o /i /n = 4 $WavePath + ":ResultsWave" 
	make /o /n= (1,8) $WavePath + ":TestPulse:" + "TestPulseITC"
	make /o /n= (1,8) $WavePath + ":TestPulse:" + "InstResistance"
	make /o /n= (1,8) $WavePath + ":TestPulse:" + "Resistance"
	make /o /n= (1,8) $WavePath + ":TestPulse:" + "SSResistance"
	
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
Function /t Path_ListOfYokedDACs(panelTitle)
	string panelTitle
	string strPathToListOfYokedDACs = HSU_DataFullFolderPathString("ITC1600_Dev_0") + ":ListOfFollowerITC1600s" // ITC1600 Device 0 is always the lead device for yoked ITC1600s
	if(exists(strPathToListOfYokedDACs)==2)
		SVAR /z ListOfYokedDACs = $strPathToListOfYokedDACs
		return ListOfYokedDACs
	else
		return "No Yoked Devices"
	endif
End
//=========================================================================================
