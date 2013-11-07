#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function SelectTestPulseWave()//Selects Test Pulse output wave for all checked DA channels
string ListOfCheckedDA = ControlStatusListString("DA", "Check")
string DAPopUpMenu
variable i

do
	if((str2num(stringfromlist(i,ListOfCheckedDA,";")))==1)
	DAPopUpMenu= "Wave_DA_0"+num2str(i)
	popUpMenu $DAPopUpMenu mode = 2, win=datapro_itc1600
	endif
i+=1
while(i<itemsinlist(ListOfCheckedDA))
End




Function StoreSelectedDACWaves(SelectedDACWaveList)
wave SelectedDACWaveList
string ListOfCheckedDA = ControlStatusListString("DA", "Check")
string DAPopUpMenu
variable i

do
	if((str2num(stringfromlist(i,ListOfCheckedDA,";")))==1)
	DAPopUpMenu= "Wave_DA_0"+num2str(i)
	controlinfo/w=datapro_itc1600 $DAPopUpMenu 
	SelectedDACWaveList[i]=v_value
	endif
i+=1
while(i<itemsinlist(ListOfCheckedDA))

end

Function ResetSelectedDACWaves(SelectedDACWaveList)
wave SelectedDACWaveList
string ListOfCheckedDA = ControlStatusListString("DA", "Check")
string DAPopUpMenu
variable i = 0
do
	if((str2num(stringfromlist(i,ListOfCheckedDA,";")))==1)
	DAPopUpMenu= "Wave_DA_0"+num2str(i)
	popupMenu $DAPopUpMenu mode=SelectedDACWaveList[i], win=datapro_itc1600
	endif
i+=1
while(i<itemsinlist(ListOfCheckedDA))

End

Function StoreDAScale(SelectedDACScale)
wave SelectedDACScale
string ListOfCheckedDA = ControlStatusListString("DA", "Check")
string DAPopUpMenu
variable i

do
	if((str2num(stringfromlist(i,ListOfCheckedDA,";")))==1)
	DAPopUpMenu= "Scale_DA_0"+num2str(i)
	controlinfo/w=datapro_itc1600 $DAPopUpMenu 
	SelectedDACScale[i]=v_value
	endif
i+=1
while(i<itemsinlist(ListOfCheckedDA))
end

Function SetDAScaleToOne()
string ListOfCheckedDA = ControlStatusListString("DA", "Check")
string DASetVariable
variable i

do
	if((str2num(stringfromlist(i,ListOfCheckedDA,";")))==1)
	DASetVariable= "Scale_DA_0"+num2str(i)
	setvariable $DASetVariable value=_num:1, win=datapro_itc1600
	endif
i+=1
while(i<itemsinlist(ListOfCheckedDA))
end

Function RestoreDAScale(SelectedDACScale)
wave SelectedDACScale
string ListOfCheckedDA = ControlStatusListString("DA", "Check")
string DASetVariable
variable i = 0
do
	if((str2num(stringfromlist(i,ListOfCheckedDA,";")))==1)
	DASetVariable= "Scale_DA_0"+num2str(i)
	setvariable $DASetVariable value =_num:SelectedDACScale[i], win=datapro_itc1600
	endif
i+=1
while(i<itemsinlist(ListOfCheckedDA))
end

Function AdjustTestPulseWave(TestPulse)
wave TestPulse
variable PulseDuration
controlinfo/w=datapro_itc1600 SetVar_DataAcq_TPDuration
PulseDuration=(v_value/0.005)
redimension/n=(2*PulseDuration) TestPulse

controlinfo/w=DataPro_ITC1600 SetVar_DataAcq_TPAmplitude
TestPulse[(PulseDuration/2),(Pulseduration + (PulseDuration/2))]=v_value
End


Function ButtonProc_1(ctrlName) : ButtonControl// Button that starts the test pulse
	String ctrlName
	wave TestPulseITC
	
	AbortOnValue HSU_DeviceLockCheck(),1
	
	controlinfo/w=datapro_itc1600 popup_MoreSettings_DeviceType
	variable DeviceType=v_value-1
	controlinfo/w=datapro_itc1600 popup_moreSettings_DeviceNo
	variable DeviceNum=v_value-1
	
	StoreTTLState()
	TurnOffAllTTLs()
	
	controlinfo/w=DataPro_ITC1600 check_Settings_ShowScopeWindow
	if(v_value==0)
	SmoothResizePanel(340)
	endif
	
	make/o/n=0 TestPulse
	SetScale/P x 0,0.005,"ms", TestPulse
	AdjustTestPulseWave(TestPulse)
	
	make/free/n=8 SelectedDACWaveList
	StoreSelectedDACWaves(SelectedDACWaveList)
	SelectTestPulseWave()

	make/free/n=8 SelectedDACScale
	StoreDAScale(SelectedDACScale)
	SetDAScaleToOne()
	
	ConfigureDataForITC()
	ITCOscilloscope(TestPulseITC)
	controlinfo/w=datapro_itc1600 Check_Settings_BkgTP
	if(v_value==1)// runs background TP
		StartBackgroundTestPulse()
	else // runs TP
		StartTestPulse(DeviceType,DeviceNum)
		controlinfo/w=DataPro_ITC1600 check_Settings_ShowScopeWindow
		if(v_value==0)
		SmoothResizePanel(-340)
		endif
	endif
	
	ResetSelectedDACWaves(SelectedDACWaveList)
	RestoreDAScale(SelectedDACScale)
	killwaves/f TestPulse
End
