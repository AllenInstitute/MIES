#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//=============================================================================================================
Function ED_MakeSettingsHistoryWave(panelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave ChanAmpAssign = $WavePath + ":ChanAmpAssign"
	variable NextSweep
	controlinfo /w = $panelTitle SetVar_Sweep
	NextSweep = v_value
	string NewWaveName = WavePath + ":ChanAmpAssign_Sweep_" + num2str(NextSweep)//sweep name has these new settings
	string cmd
	duplicate /o ChanAmpAssign $NewWaveName
	wave SettingsHistoryWave = $NewWaveName
	SettingsHistoryWave[11][] = NextSweep
	note SettingsHistoryWave, time()
End

//=============================================================================================================
Function ED_AppendCommentToDataWave(DataWaveName, panelTitle)
	wave DataWaveName
	string panelTitle
	controlinfo /w = $panelTitle SetVar_DataAcq_Comment
	if(strlen(s_value) != 0)
		Note DataWaveName, s_value
		SetVariable SetVar_DataAcq_Comment value = _STR:""
	endif
End
//=============================================================================================================
Function ED_AppendTPparamToDataWave(panelTitle, DataWaveName)
	string panelTitle
	wave DataWaveName
	
	
End
//=============================================================================================================

