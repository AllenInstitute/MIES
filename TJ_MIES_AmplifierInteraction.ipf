#pragma rtGlobals=3		// Use modern global access method and strict wave access.




Function/t ReturnListOf700BChannels(panelTitle)
string panelTitle
Variable TotalNoChannels
Variable i = 0
String ChannelList=""
String Value
//make/o/n=0 W_TelegraphServers
//AxonTelegraphFindServers
wave/z W_TelegraphServers
TotalNoChannels = DimSize(W_TelegraphServers, 0 )// 0 is for rows, 1 for columns, 2 for layers, 3 for chunks
	
	If(TotalNoChannels>0)
		do
		sprintf Value, "%g" W_TelegraphServers[i][0]
		ChannelList+="AmpNo " +Value + " Chan " + num2str(W_TelegraphServers[i][1]) +";"
		i+=1
		while(i<TotalNoChannels)
	endif

if(cmpstr(ChannelList,"")==0)
	ChannelList = "MC not available;"
	print "Activate Multiclamp Commander software to populate list of available amplifiers"
endif

return ChannelList

End


Function ButtonProc(ctrlName) : ButtonControl
	String ctrlName

make/o/n=0 W_TelegraphServers
AxonTelegraphFindServers

getwindow kwTopWin wtitle
string PopUpList = "\" - none - ;" 
PopUpList += ReturnListOf700BChannels(s_value)+"\""
popupmenu  popup_Settings_Amplifier win = $s_value, value = #PopUpList

End

Function UpdateChanAmpAssignStorageWave(panelTitle)
	string panelTitle
	Variable HeadStageNo, SweepNo, i
	wave W_telegraphServers
	string WavePath=HSU_DataFullFolderPathString(PanelTitle)
	wave/z ChanAmpAssign=$WavePath + ":ChanAmpAssign"

	controlinfo/w=$panelTitle Popup_Settings_HeadStage
	HeadStageNo = str2num(s_value)
	
	If (waveexists(ChanAmpAssign)==0)// checks to see if data storage wave exists, makes it if it doesn't
	string ChanAmpAssignPath = WavePath + ":ChanAmpAssign"
	make/n=(12,8) $ChanAmpAssignPath
	wave ChanAmpAssign=$ChanAmpAssignPath
	endif

	duplicate/free ChanAmpAssign ChanAmpAssignOrig

	// Assigns V-clamp settings for a particular headstage
	ControlInfo/w=$panelTitle Popup_Settings_VC_DA
	ChanAmpAssign[0][HeadStageNo]=str2num(s_value)
	ControlInfo/w=$panelTitle setvar_Settings_VC_DAgain
	ChanAmpAssign[1][HeadStageNo]=v_value
	ControlInfo/w=$panelTitle Popup_Settings_VC_AD
	ChanAmpAssign[2][HeadStageNo]=str2num(s_value)
	ControlInfo/w=$panelTitle setvar_Settings_VC_ADgain_0
	ChanAmpAssign[3][HeadStageNo]=v_value
	
	//Assigns I-clamp settings for a particular headstage
	ControlInfo/w=$panelTitle Popup_Settings_IC_DA
	ChanAmpAssign[4][HeadStageNo]=str2num(s_value)
	ControlInfo/w=$panelTitle setvar_Settings_IC_DAgain
	ChanAmpAssign[5][HeadStageNo]=v_value
	ControlInfo/w=$panelTitle Popup_Settings_IC_AD
	ChanAmpAssign[6][HeadStageNo]=str2num(s_value)
	ControlInfo/w=$panelTitle setvar_Settings_IC_ADgain
	ChanAmpAssign[7][HeadStageNo]=v_value
	
	//Assigns amplifier to a particualr headstage - sounds weird because this relationship is predetermined in hardware but now you are telling the software what it is
	if(waveexists(W_telegraphServers)==1)
	ControlInfo/w=$panelTitle popup_Settings_Amplifier
		if(v_value>1)
		ChanAmpAssign[8][HeadStageNo]=W_TelegraphServers[v_value-2][0]
		ChanAmpAssign[9][HeadStageNo]=W_TelegraphServers[v_value-2][1]
		else
		ChanAmpAssign[8][HeadStageNo]=nan
		ChanAmpAssign[9][HeadStageNo]=nan
		endif
		ChanAmpAssign[10][HeadStageNo]=v_value

	endif
	//Duplicate ChanampAssign wave and add sweep number if the wave is changed
	controlinfo SetVar_Sweep
	SweepNo=v_value
	
	if(SweepNo>0)
		ChanAmpAssignOrig-=ChanAmpAssign//used to see if settings have changed
		if((wavemax(ChanAmpAssignOrig)) != 0 || (wavemin(ChanAmpAssignOrig)) != 0)
		MakeSettingsHistoryWave(panelTitle)
		endif
	endif
	

	
End
//==================================================================================================


Function UpdateChanAmpAssignPanel(PanelTitle)
string panelTitle
Variable HeadStageNo
	string WavePath=HSU_DataFullFolderPathString(PanelTitle)
	wave ChanAmpAssign=$WavePath + ":ChanAmpAssign"

controlinfo/w=$panelTitle Popup_Settings_HeadStage
HeadStageNo=str2num(s_value)

Popupmenu Popup_Settings_VC_DA win=$panelTitle, mode=(ChanAmpAssign[0][HeadStageNo]+1)
Setvariable setvar_Settings_VC_DAgain win=$panelTitle, value=_num:ChanAmpAssign[1][HeadStageNo]
Popupmenu Popup_Settings_VC_AD win=$panelTitle, mode=(ChanAmpAssign[2][HeadStageNo]+1)
Setvariable setvar_Settings_VC_ADgain_0 win=$panelTitle, value=_num:ChanAmpAssign[3][HeadStageNo]

Popupmenu Popup_Settings_IC_DA win=$panelTitle, mode=(ChanAmpAssign[4][HeadStageNo]+1)
Setvariable setvar_Settings_IC_DAgain win=$panelTitle, value=_num:ChanAmpAssign[5][HeadStageNo]
Popupmenu  Popup_Settings_IC_AD win=$panelTitle, mode=(ChanAmpAssign[6][HeadStageNo]+1)
Setvariable setvar_Settings_IC_ADgain win=$panelTitle, value=_num:ChanAmpAssign[7][HeadStageNo]

Popupmenu popup_Settings_Amplifier win=$panelTitle, mode=ChanAmpAssign[10][HeadStageNo]

End




Function PopMenuProc_Headstage(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	getwindow kwTopWin wtitle
	UpdateChanAmpAssignPanel(s_value)
End

Function PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	getwindow kwTopWin wtitle
	UpdateChanAmpAssignStorageWave(s_value)
End

Function SetVarProc_CAA(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	getwindow kwTopWin wtitle
	UpdateChanAmpAssignStorageWave(s_value)
End

Function ApplyClampModeSavedSettings(HeadStageNo, ClampMode, panelTitle)
variable HeadStageNo, ClampMode// 0 = VC, 1 = IC
string panelTitle
	string WavePath=HSU_DataFullFolderPathString(PanelTitle)
	wave ChanAmpAssign=$WavePath + ":ChanAmpAssign"
string DACheck, DAGain, ADCheck, ADGain
If(ClampMode==0)
	DACheck="Check_DA_0"+num2str(ChanAmpAssign[0][HeadStageNo])
	CheckBox $DACheck win=$panelTitle, value=1
	
	DAGain="Gain_DA_0"+num2str(ChanAmpAssign[0][HeadStageNo])
	SetVariable $DAGain win=$panelTitle, value=_num:ChanAmpAssign[1][HeadStageNo]
	
	If(ChanAmpAssign[2][HeadStageNo]<10)
	ADCheck="Check_AD_0" + num2str(ChanAmpAssign[2][HeadStageNo])
	CheckBox $ADCheck win=$panelTitle, value=1
	
	ADGain="Gain_AD_0"+num2str(ChanAmpAssign[2][HeadStageNo])
	SetVariable $ADGain win=$panelTitle, value=_num:ChanAmpAssign[3][HeadStageNo]
	else
	ADCheck="Check_AD_" + num2str(ChanAmpAssign[2][HeadStageNo])
	CheckBox $ADCheck win=$panelTitle, value=1
	
	ADGain="Gain_AD_"+num2str(ChanAmpAssign[2][HeadStageNo])
	SetVariable $ADGain win=$panelTitle, value=_num:ChanAmpAssign[3][HeadStageNo]	
	endif
endIf

If(ClampMode==1)
	DACheck="Check_DA_0"+num2str(ChanAmpAssign[4][HeadStageNo])
	CheckBox $DACheck win=$panelTitle, value=1
	
	DAGain="Gain_DA_0"+num2str(ChanAmpAssign[4][HeadStageNo])
	SetVariable $DAGain win=$panelTitle, value=_num:ChanAmpAssign[5][HeadStageNo]
	
	If(ChanAmpAssign[6][HeadStageNo]<10)
	ADCheck="Check_AD_0" + num2str(ChanAmpAssign[6][HeadStageNo])
	CheckBox $ADCheck win=$panelTitle, value=1
	
	ADGain="Gain_AD_0"+num2str(ChanAmpAssign[6][HeadStageNo])
	SetVariable $ADGain win=$panelTitle, value=_num:ChanAmpAssign[7][HeadStageNo]
	else
	ADCheck="Check_AD_" + num2str(ChanAmpAssign[6][HeadStageNo])
	CheckBox $ADCheck win=$panelTitle, value=1
	
	ADGain="Gain_AD_"+num2str(ChanAmpAssign[6][HeadStageNo])
	SetVariable $ADGain win=$panelTitle, value=_num:ChanAmpAssign[7][HeadStageNo]	
	endif
endIf
End

Function RemoveClampModeSettings(HeadStageNo, ClampMode, panelTitle)
	variable HeadStageNo, ClampMode// 0 = VC, 1 = IC
	string panelTitle
	string WavePath=HSU_DataFullFolderPathString(PanelTitle)
	wave ChanAmpAssign=$WavePath + ":ChanAmpAssign"
	string DACheck, DAGain, ADCheck, ADGain
If(ClampMode==0)
	DACheck="Check_DA_0"+num2str(ChanAmpAssign[0][HeadStageNo])
	CheckBox $DACheck value=0
	
	If(ChanAmpAssign[2][HeadStageNo]<10)
	ADCheck="Check_AD_0" + num2str(ChanAmpAssign[2][HeadStageNo])
	CheckBox $ADCheck value=0
	else
	ADCheck="Check_AD_" + num2str(ChanAmpAssign[2][HeadStageNo])
	CheckBox $ADCheck value=0
	endif
endIf

If(ClampMode==1)
	DACheck="Check_DA_0"+num2str(ChanAmpAssign[4][HeadStageNo])
	CheckBox $DACheck value=0
	
	If(ChanAmpAssign[6][HeadStageNo]<10)
	ADCheck="Check_AD_0" + num2str(ChanAmpAssign[6][HeadStageNo])
	CheckBox $ADCheck value=0

	else
	ADCheck="Check_AD_" + num2str(ChanAmpAssign[6][HeadStageNo])
	CheckBox $ADCheck value=0

	endif
endIf

End




Function CheckProc_ClampMode(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	String PairedRadioButton = "Radio_ClampMode_"
	Variable RadioButtonNo = str2num(ctrlName[16,inf])
	string HeadStageCheckBox = "Check_DataAcq_"
	getwindow kwTopWin wtitle
	string panelTitle=s_value

	if(mod(RadioButtonNo,2)==0)//even numbers
		PairedRadioButton += (num2str(RadioButtonNo+1))
		checkbox $PairedRadioButton value=0
		
		HeadStageCheckBox+=num2str((RadioButtonNo/2))
		controlinfo/w=$panelTitle $HeadStageCheckBox
		
		if(v_value==1)//checks to see if headstage is "ON"
		RemoveClampModeSettings((RadioButtonNo/2), 1,panelTitle)
		ApplyClampModeSavedSettings((RadioButtonNo/2), 0,panelTitle)//Applies VC settings for headstage
		endif
		
	else
		PairedRadioButton += (num2str(RadioButtonNo-1))
		checkbox $PairedRadioButton value=0
		
		HeadStageCheckBox+=num2str(((RadioButtonNo-1)/2))
		controlinfo/w=$panelTitle $HeadStageCheckBox
		
		if(v_value==1)//checks to see if headstage is "ON"
		RemoveClampModeSettings(((RadioButtonNo-1)/2), 0, panelTitle)
		ApplyClampModeSavedSettings(((RadioButtonNo-1)/2), 1,panelTitle)//Applies IC settings for headstage
		endif

	endif
	
	variable MinSampInt = ITCMinSamplingInterval(PanelTitle)
	ValDisplay ValDisp_DataAcq_SamplingInt win = $PanelTitle, value=_NUM:MinSampInt
End

Function CheckProc_HeadstageCheck(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	string RadioButtonName = "Radio_ClampMode_"
	Variable HeadStageNo =str2num(ctrlname[15])
	Variable ClampMode//
	getwindow kwTopWin wtitle
	string panelTitle=s_value
	RadioButtonName+=num2str((HeadStageNo*2)+1)
	ControlInfo/w=$panelTitle $RadioButtonName
	ClampMode=v_value
	
	If(Checked==0)
	RemoveClampModeSettings(HeadStageNo, ClampMode, panelTitle)
	else
	ApplyClampModeSavedSettings(HeadStageNo, ClampMode,panelTitle)
	endif
 
	variable MinSampInt = ITCMinSamplingInterval(PanelTitle)
	ValDisplay ValDisp_DataAcq_SamplingInt win = $PanelTitle, value=_NUM:MinSampInt
End
