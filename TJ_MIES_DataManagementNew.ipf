 #pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function SaveITCData(panelTitle)
	string panelTitle
	variable DeviceType, DeviceNum
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	wave ITCChanConfigWave = $WavePath + ":ITCChanConfigWave"
	Variable SweepNo
	ControlInfo/w=$panelTitle SetVar_Sweep
	SweepNo=v_value
	controlinfo/w=$panelTitle popup_MoreSettings_DeviceType
	DeviceType=v_value-1
	controlinfo/w=$panelTitle popup_moreSettings_DeviceNo
	DeviceNum=v_value-1
	
	
	string SavedDataWaveName=WavePath+":Data:"+"Sweep_"+ num2str(SweepNo)
	string SavedSetUpWaveName=WavePath+":Data:"+"Config_Sweep_"+ num2str(SweepNo)
	variable RowsToCopy = CalculateITCDataWaveLength(panelTitle)/4
	Duplicate/o/r=[0,RowsToCopy][] ITCDataWave $SavedDataWaveName
	Duplicate/o ITCChanConfigWave $SavedSetUpWaveName
	note $savedDataWaveName, Time()// adds time stamp to wave note
	AppendCommentToDataWave($SavedDataWaveName, panelTitle)//adds user comments as wave note
	controlinfo Check_Settings_Append
	if(v_value==1)// if option is checked, wave note containing single readings from (async) ADs is made
		AD_DataBasedWaveNotes($SavedDataWaveName, DeviceType,DeviceNum, panelTitle)
	endif	
	SetVariable SetVar_Sweep, Value=_NUM:(SweepNo+1), limits={0,SweepNo+1,1},win=$panelTitle
	redimension/d $SavedDataWaveName
	ADScaling($SavedDataWaveName, panelTitle)
	DAScaling($SavedDataWaveName, panelTitle)
End

Function CreateAndScaleTPHoldingWave(panelTitle)// TestPulseITC is the TP (test pulse) holding wave.
	string panelTitle
	variable RowsToCopy = CalculateITCDataWaveLength(panelTitle)/4
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	string TestPulseITCPath = WavePath+":TestPulse:TestPulseITC"
	Duplicate/o/r=[0,RowsToCopy][] ITCDataWave $TestPulseITCPath
	wave TestPulseITC = $TestPulseITCPath
	redimension/d TestPulseITC
	ADScaling(TestPulseITC, panelTitle)
End

Function MakeFloatingPointWave(WaveBeingPassed)
wave WaveBeingPassed

redimension/d WaveBeingPassed

End

Function ADScaling(WaveToScale, panelTitle)
wave WaveToScale
string panelTitle
string WavePath = HSU_DataFullFolderPathString(PanelTitle)
wave ITCChanConfigWave = $WavePath +":ITCChanConfigWave"
string ADChannelList  =  RefToPullDatafrom2DWave(0,0, 1, ITCChanConfigWave)
variable NoOfADColumns = NoOfChannelsSelected("ad", "check", panelTitle)
variable StartOfADColumns =NoOfChannelsSelected("da", "check", panelTitle)
string ADGainControlName
variable gain, i
wave ChannelClampMode = $WavePath + ":ChannelClampMode"
for(i=0;i<(itemsinlist(ADChannelList));i+=1)
//Gain_AD_00
	if(str2num(stringfromlist(i,ADChannelList,";"))<10)
	ADGainControlName="Gain_AD_0"+stringfromlist(i,ADChannelList,";")
	else
	ADGainControlName="Gain_AD_"+stringfromlist(i,ADChannelList,";")
	endif
	controlinfo/w=$panelTitle $ADGainControlName
	gain=v_value
	
	if(ChannelClampMode[str2num(stringfromlist(i,ADChannelList,";"))][1] == 0) // V-clamp
	gain*=3200// itc output will be multiplied by 1000 to convert to pA then divided by the gain
	WaveToScale[][(StartOfADColumns+i)]/=gain
	//WaveToScale[][(StartOfADColumns+i)]*=1000
	endif
	
	if(ChannelClampMode[str2num(stringfromlist(i,ADChannelList,";"))][1] == 1) // I-clamp
	gain*=3200// 
	WaveToScale[][(StartOfADColumns+i)]/=gain
	endif
	
endfor

end

Function DAScaling(WaveToScale, panelTitle)
	wave WaveToScale
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	wave ITCChanConfigWave = $WavePath + ":ITCChanConfigWave"
	variable NoOfDAColumns = NoOfChannelsSelected("da", "check", panelTitle)
	string DAChannelList  =  RefToPullDatafrom2DWave(1,0, 1, ITCChanConfigWave)
	string DAGainControlName
	variable gain, i
	wave ChannelClampMode = $WavePath + ":ChannelClampMode"

for(i=0;i<(itemsinlist(DAChannelList));i+=1)
	if(str2num(stringfromlist(i,DAChannelList,";"))<10)
	DAGainControlName="Gain_DA_0"+stringfromlist(i,DAChannelList,";")
	else
	DAGainControlName="Gain_DA_"+stringfromlist(i,DAChannelList,";")
	endif
	controlinfo/w=$panelTitle $DAGainControlName
	gain=v_value
	
	if(ChannelClampMode[str2num(stringfromlist(i,DAChannelList,";"))][0] == 0) // V-clamp
	WaveToScale[][i]/=3200
	WaveToScale[][i]*=gain
	endif
	
	if(ChannelClampMode[str2num(stringfromlist(i,DAChannelList,";"))][0] == 1) // I-clamp
	WaveToScale[][i]/=3200
	WaveToScale[][i]*=gain
	endif	
endfor

end

Function ScaleITCDataWave(panelTitle)// used after single trial of data aquisition - cannot be used when the same wave is output multiple times by the DAC
string panelTitle
string WavePath = HSU_DataFullFolderPathString(PanelTitle)
wave ITCDataWave = $WavePath + ":ITCDataWave"
redimension/d ITCDataWave
ADScaling(ITCDataWave,panelTitle)
end

Function DeleteSettingsHistoryWaves(SweepNo,PanelTitle)// deletes setting history waves "older" than SweepNo
	variable SweepNo
	string panelTitle
	string WavePath=HSU_DataFullFolderPathString(PanelTitle)
	variable i = 0
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder $WavePath
	string ListOf_ChanAmpAssign_Sweep_x_Wv=wavelist("ChanAmpAssign_Sweep_*", ";","")
	string WaveNameUnderConsideration
	do
		WaveNameUnderConsideration=WavePath+":"+stringfromlist(i, ListOf_ChanAmpAssign_Sweep_x_Wv, ";")
		print WaveNameUnderConsideration
		if(itemsinlist(ListOf_ChanAmpAssign_Sweep_x_Wv)>0)
		duplicate/free $WaveNameUnderConsideration WorkingWave
			print WaveNameUnderConsideration
			if(WorkingWave[11][0]>SweepNo)
				killwaves /f /z $WaveNameUnderConsideration
			endif	
		endif
		i+=1
	while(i<itemsinlist(ListOf_ChanAmpAssign_Sweep_x_Wv))
		SetDataFolder saveDFR

End
//=============================================================================================================	
Function ReturnLastSweepAcquired(panelTitle)
	//LastSweep
	string panelTitle
	string WavePath=HSU_DataFullFolderPathString(PanelTitle)+":data"
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder $WavePath
	
	string AcquiredWaveList
	AcquiredWaveList=wavelist("Sweep_*",";","MINCOLS:2")
	variable LastSweep
	LastSweep=itemsinlist(AcquiredWaveList,";")-1
	return LastSweep
	
	SetDataFolder saveDFR

End
//=============================================================================================================
Function IsLastSweepGreaterThanNextSweep(panelTitle)
	string panelTitle
	variable NextSweep
	controlinfo/w=$panelTitle SetVar_Sweep
	NextSweep=v_value
	
	if(NextSweep>ReturnLastSweepAcquired(panelTitle))
	return 0
	else
	return 1
	endif
End
//=============================================================================================================
Function DeleteDataWaves(panelTitle, SweepNo)
	string panelTitle
	variable SweepNo
	variable i=SweepNo
	string WavePath=HSU_DataFullFolderPathString(PanelTitle)+":data"
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder $WavePath

	
	
	string ListOfDataWaves=wavelist("Sweep_*",";","MINCOLS:2")
	string WaveNameUnderConsideration
		do
			WaveNameUnderConsideration=stringfromlist(i, ListOfDataWaves, ";")
			if(itemsinlist(ListOfDataWaves)>0)
	
					killwaves/z/f $WaveNameUnderConsideration
	
			endif
			i+=1
		while(i<itemsinlist(ListOfDataWaves))
	
	i=SweepNo
	ListOfDataWaves=wavelist("Config_Sweep_*",";","MINCOLS:2")
	do
		WaveNameUnderConsideration=stringfromlist(i, ListOfDataWaves, ";")
		if(itemsinlist(ListOfDataWaves)>0)

				killwaves/z/f $WaveNameUnderConsideration

		endif
		i+=1
	while(i<itemsinlist(ListOfDataWaves))
SetDataFolder saveDFR

End

//=============================================================================================================