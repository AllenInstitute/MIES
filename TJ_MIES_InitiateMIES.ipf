#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function IM_InitiateMIES()
	NewDataFolder /o root:MIES
	NewDataFolder /o root:MIES:Amplifiers
	NewDataFolder /o root:MIES:ITCDevices
	NewDataFolder /o root:MIES:ITCDevices:ActiveITCDevices
	WB_InitiateWaveBuilder()
	execute "DA_Ephys()"
	execute "DataBrowser()"
End

Function IM_MakeGlobalsAndWaves(panelTitle)// makes the necessary parameters for the locked device to function.
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
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