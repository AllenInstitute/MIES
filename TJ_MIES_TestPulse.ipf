#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// The test pulse is a specia DA wave. As such it isn't stored with the other DA waves in the wavebuilder folders.
//This allows different ITC devices to have TestPulse waves with different parameters.
//Unfortunately it also creates special cases in the code where a different path needs to be provided when a test pulse is being used.
//The logic of having different TP waves is slightly flawed given that channels on a DAC are already limited to a single TP wave
//The workaround would be a different scaling factor on each channel but this would scaling would need to be applied to the TP holding wave.
//For now I am leaving this limitation
//having panel specific Test pulse waves was initiated with resistance calculations in mind. I wanted to create globals that stored the 
// TP parameters and use these as input parameters for resistance calculation

Function SelectTestPulseWave(panelTitle)//Selects Test Pulse output wave for all checked DA channels
	string panelTitle
	string ListOfCheckedDA = ControlStatusListString("DA", "Check", panelTitle)
	string DAPopUpMenu
	variable i
	
	do
		if((str2num(stringfromlist(i, ListOfCheckedDA,";"))) == 1)
			DAPopUpMenu = "Wave_DA_0"+num2str(i)
			popUpMenu $DAPopUpMenu mode = 2, win = $panelTitle
		endif
	i += 1
	while(i < itemsinlist(ListOfCheckedDA))
End

Function StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
	wave SelectedDACWaveList
	string panelTitle
	string ListOfCheckedDA = ControlStatusListString("DA", "Check", panelTitle)
	string DAPopUpMenu
	variable i
	
	do
		if((str2num(stringfromlist(i,ListOfCheckedDA,";"))) == 1)
			DAPopUpMenu= "Wave_DA_0"+num2str(i)
			controlinfo /w = $panelTitle $DAPopUpMenu 
			SelectedDACWaveList[i] = v_value
		endif
	i += 1
	while(i < itemsinlist(ListOfCheckedDA))
end

Function ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
	wave SelectedDACWaveList
	string panelTitle
	string ListOfCheckedDA = ControlStatusListString("DA", "Check", panelTitle)
	string DAPopUpMenu
	variable i = 0
	do
		if((str2num(stringfromlist(i,ListOfCheckedDA,";"))) == 1)
			DAPopUpMenu = "Wave_DA_0"+num2str(i)
			popupMenu $DAPopUpMenu mode = SelectedDACWaveList[i], win = $panelTitle
		endif
	i += 1
	while(i < itemsinlist(ListOfCheckedDA))

End

Function StoreDAScale(SelectedDACScale, panelTitle)
	wave SelectedDACScale
	string panelTitle
	string ListOfCheckedDA = ControlStatusListString("DA", "Check", panelTitle)
	string DAPopUpMenu
	variable i
	
	do
		if((str2num(stringfromlist(i,ListOfCheckedDA,";")))==1)
			DAPopUpMenu = "Scale_DA_0"+num2str(i)
			controlinfo /w = $panelTitle $DAPopUpMenu 
			SelectedDACScale[i] = v_value
		endif
	i += 1
	while(i < itemsinlist(ListOfCheckedDA))
end

Function SetDAScaleToOne(panelTitle)
	string panelTitle
	string ListOfCheckedDA = ControlStatusListString("DA", "Check", panelTitle)
	string DASetVariable
	variable i
	
	do
		if((str2num(stringfromlist(i, ListOfCheckedDA,";"))) == 1)
			DASetVariable = "Scale_DA_0"+num2str(i)
			setvariable $DASetVariable value = _num:1, win = $panelTitle
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
		if((str2num(stringfromlist(i, ListOfCheckedDA,";"))) == 1)
		DASetVariable = "Scale_DA_0"+num2str(i)
		setvariable $DASetVariable value = _num:SelectedDACScale[i], win = $panelTitle
		endif
	i += 1
	while(i < itemsinlist(ListOfCheckedDA))
end

Function AdjustTestPulseWave(TestPulse, panelTitle)// full path name
	wave TestPulse
	string panelTitle
	variable PulseDuration
	string TPGlobalPath = HSU_DataFullFolderPathString(PanelTitle) + ":TestPulse"
	variable /g  $TPGlobalPath + ":Duration"
	NVAR GlobalTPDurationVariable = $TPGlobalPath + ":Duration"
	variable /g $TPGlobalPath + ":Amplitude"
	NVAR GlobalTPAmplitudeVariable = $TPGlobalPath + ":Amplitude"
	controlinfo /w = $panelTitle SetVar_DataAcq_TPDuration
	PulseDuration = (v_value / 0.005)
	GlobalTPDurationVariable = PulseDuration
	redimension /n = (2 * PulseDuration) TestPulse
	controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitude
	TestPulse[(PulseDuration / 2),(Pulseduration + (PulseDuration / 2))] = v_value
	GlobalTPAmplitudeVariable = v_value
End


Function TP_ButtonProc_DataAcq_TestPulse(ctrlName) : ButtonControl// Button that starts the test pulse
	String ctrlName
	string PanelTitle
	getwindow kwTopWin wtitle
	PanelTitle = s_value
	AbortOnValue HSU_DeviceLockCheck(PanelTitle),1
	
	controlinfo /w = $panelTitle SetVar_DataAcq_TPDuration
	if(v_value == 0)
		abort "Give test pulse a duration greater than 0 ms"
	endif
	
	variable MinSampInt = ITCMinSamplingInterval(PanelTitle)
	ValDisplay ValDisp_DataAcq_SamplingInt win = $PanelTitle, value = _NUM:MinSampInt
	
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)// determines ITC device 
	controlinfo /w = $panelTitle popup_MoreSettings_DeviceType
	variable DeviceType = v_value - 1
	controlinfo /w = $panelTitle popup_moreSettings_DeviceNo
	variable DeviceNum = v_value - 1
	
	StoreTTLState(panelTitle)
	TurnOffAllTTLs(panelTitle)
	
	controlinfo /w = $panelTitle check_Settings_ShowScopeWindow
	if(v_value == 0)
	SmoothResizePanel(340, panelTitle)
	endif
	
	string TestPulsePath = "root:WaveBuilder:SavedStimulusSets:DA:TestPulse"
	make /o /n = 0 $TestPulsePath
	wave TestPulse = $TestPulsePath
	SetScale /P x 0,0.005,"ms", TestPulse
	AdjustTestPulseWave(TestPulse, panelTitle)
	CreateAndScaleTPHoldingWave(panelTitle)
	make /free /n = 8 SelectedDACWaveList
	StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
	SelectTestPulseWave(panelTitle)

	make /free /n = 8 SelectedDACScale
	StoreDAScale(SelectedDACScale,panelTitle)
	SetDAScaleToOne(panelTitle)
	
	ConfigureDataForITC(panelTitle)
	wave TestPulseITC = $WavePath+":TestPulse:TestPulseITC"
	ITCOscilloscope(TestPulseITC,panelTitle)
	controlinfo /w = $panelTitle Check_Settings_BkgTP
	if(v_value == 1)// runs background TP
		StartBackgroundTestPulse(DeviceType, DeviceNum, panelTitle)
	else // runs TP
		StartTestPulse(DeviceType,DeviceNum, panelTitle)
		controlinfo/w=$panelTitle check_Settings_ShowScopeWindow
		if(v_value == 0)
			SmoothResizePanel(-340, panelTitle)
		endif
		killwaves /f TestPulse
	endif
	
	ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
	RestoreDAScale(SelectedDACScale,panelTitle)
End

//=============================================================================================

// Calculate input resistance simultaneously on array so it is fast
	controlinfo /w =$panelTitle SetVar_DataAcq_TPDuration
	PulseDuration = (v_value / 0.005)
	redimension /n = (2 * PulseDuration) TestPulse
	controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitude
	TestPulse[(PulseDuration / 2),(Pulseduration + (PulseDuration / 2))] = v_value
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)

//Function TPParameters

ThreadSafe Function CalculateResistance(panelTitle, TestPulsePath, BaseLineStartPoint, PulseStartPoint, PulseEndPoint)
				string panelTitle
				wave TestPulsePath
				variable BaseLineStartPoint, PulseStartPoint, PulseEndPoint
				
	
			End
			
// multithread 
// Threadsafe