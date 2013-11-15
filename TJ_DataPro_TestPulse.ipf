#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function SelectTestPulseWave(panelTitle)//Selects Test Pulse output wave for all checked DA channels
string panelTitle
string ListOfCheckedDA = ControlStatusListString("DA", "Check", panelTitle)
string DAPopUpMenu
variable i

do
	if((str2num(stringfromlist(i,ListOfCheckedDA,";")))==1)
	DAPopUpMenu= "Wave_DA_0"+num2str(i)
	popUpMenu $DAPopUpMenu mode = 2, win=$panelTitle
	endif
i+=1
while(i<itemsinlist(ListOfCheckedDA))
End




Function StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
wave SelectedDACWaveList
string panelTitle
string ListOfCheckedDA = ControlStatusListString("DA", "Check", panelTitle)
string DAPopUpMenu
variable i

do
	if((str2num(stringfromlist(i,ListOfCheckedDA,";")))==1)
	DAPopUpMenu= "Wave_DA_0"+num2str(i)
	controlinfo/w=$panelTitle $DAPopUpMenu 
	SelectedDACWaveList[i]=v_value
	endif
i+=1
while(i<itemsinlist(ListOfCheckedDA))

end

Function ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
wave SelectedDACWaveList
string panelTitle
string ListOfCheckedDA = ControlStatusListString("DA", "Check", panelTitle)
string DAPopUpMenu
variable i = 0
do
	if((str2num(stringfromlist(i,ListOfCheckedDA,";")))==1)
	DAPopUpMenu= "Wave_DA_0"+num2str(i)
	popupMenu $DAPopUpMenu mode=SelectedDACWaveList[i], win=$panelTitle
	endif
i+=1
while(i<itemsinlist(ListOfCheckedDA))

End

Function StoreDAScale(SelectedDACScale, panelTitle)
wave SelectedDACScale
string panelTitle
string ListOfCheckedDA = ControlStatusListString("DA", "Check", panelTitle)
string DAPopUpMenu
variable i

do
	if((str2num(stringfromlist(i,ListOfCheckedDA,";")))==1)
	DAPopUpMenu= "Scale_DA_0"+num2str(i)
	controlinfo/w=$panelTitle $DAPopUpMenu 
	SelectedDACScale[i]=v_value
	endif
i+=1
while(i<itemsinlist(ListOfCheckedDA))
end

Function SetDAScaleToOne(panelTitle)
string panelTitle
string ListOfCheckedDA = ControlStatusListString("DA", "Check", panelTitle)
string DASetVariable
variable i

do
	if((str2num(stringfromlist(i,ListOfCheckedDA,";")))==1)
	DASetVariable= "Scale_DA_0"+num2str(i)
	setvariable $DASetVariable value=_num:1, win=$panelTitle
	endif
i+=1
while(i<itemsinlist(ListOfCheckedDA))
end

Function RestoreDAScale(SelectedDACScale, panelTitle)
wave SelectedDACScale
string panelTitle
string ListOfCheckedDA = ControlStatusListString("DA", "Check", panelTitle)
string DASetVariable
variable i = 0
do
	if((str2num(stringfromlist(i,ListOfCheckedDA,";")))==1)
	DASetVariable= "Scale_DA_0"+num2str(i)
	setvariable $DASetVariable value =_num:SelectedDACScale[i], win=$panelTitle
	endif
i+=1
while(i<itemsinlist(ListOfCheckedDA))
end

Function AdjustTestPulseWave(TestPulse, panelTitle)
wave TestPulse
string panelTitle
variable PulseDuration
controlinfo/w=$panelTitle SetVar_DataAcq_TPDuration
PulseDuration=(v_value/0.005)
redimension/n=(2*PulseDuration) TestPulse

controlinfo/w=$panelTitle SetVar_DataAcq_TPAmplitude
TestPulse[(PulseDuration/2),(Pulseduration + (PulseDuration/2))]=v_value
End


Function TP_ButtonProc_DataAcq_TestPulse(ctrlName) : ButtonControl// Button that starts the test pulse
	String ctrlName
	string PanelTitle
	getwindow kwTopWin wtitle
	PanelTitle=s_value
	AbortOnValue HSU_DeviceLockCheck(PanelTitle),1
	
	variable MinSampInt = ITCMinSamplingInterval(PanelTitle)
	ValDisplay ValDisp_DataAcq_SamplingInt win = $PanelTitle, value=_NUM:MinSampInt
	
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	controlinfo/w=$panelTitle popup_MoreSettings_DeviceType
	variable DeviceType=v_value-1
	controlinfo/w=$panelTitle popup_moreSettings_DeviceNo
	variable DeviceNum=v_value-1
	
	StoreTTLState(panelTitle)
	TurnOffAllTTLs(panelTitle)
	
	controlinfo/w=$panelTitle check_Settings_ShowScopeWindow
	if(v_value==0)
	SmoothResizePanel(340, panelTitle)
	endif
	
	string TestPulsePath = "root:WaveBuilder:SavedStimulusSets:DA:TestPulse"
	make/o/n=0 $TestPulsePath
	wave TestPulse = $TestPulsePath
	SetScale/P x 0,0.005,"ms", TestPulse
	AdjustTestPulseWave($TestPulsePath, panelTitle)
	
	make/free/n=8 SelectedDACWaveList
	StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
	SelectTestPulseWave(panelTitle)

	make/free/n=8 SelectedDACScale
	StoreDAScale(SelectedDACScale,panelTitle)
	SetDAScaleToOne(panelTitle)
	
	ConfigureDataForITC(panelTitle)
	wave TestPulseITC = $WavePath + ":TestPulseITC"
	ITCOscilloscope(TestPulseITC,panelTitle)
	controlinfo/w=$panelTitle Check_Settings_BkgTP
	if(v_value==1)// runs background TP
		StartBackgroundTestPulse(panelTitle)
	else // runs TP
		StartTestPulse(DeviceType,DeviceNum, panelTitle)
		controlinfo/w=$panelTitle check_Settings_ShowScopeWindow
		if(v_value==0)
		SmoothResizePanel(-340, panelTitle)
		endif
	endif
	
	ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
	RestoreDAScale(SelectedDACScale,panelTitle)
	killwaves/f TestPulse
End
