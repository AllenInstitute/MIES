#pragma rtGlobals=3		// Use modern global access method and strict wave access.


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
		if((str2num(stringfromlist(i,ListOfCheckedDA,";"))) == 1)
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
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ChannelClampMode = $WavePath + ":ChannelClampMode"
	variable ScalingFactor
	variable i
	
	do
		if((str2num(stringfromlist(i, ListOfCheckedDA,";"))) == 1)
			DASetVariable = "Scale_DA_0"+num2str(i)
			if(ChannelClampMode[i][0] == 0)
				ScalingFactor = 1
			endif
			
			if(ChannelClampMode[i][0] == 1)
				controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitudeIC
				ScalingFactor = v_value
				controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitude
				ScalingFactor /= v_value
			endif
			
			setvariable $DASetVariable value = _num:ScalingFactor, win = $panelTitle
		endif
	i+=1
	while(i < itemsinlist(ListOfCheckedDA))
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
	variable /g $TPGlobalPath + ":AmplitudeVC"
	NVAR GlobalTPAmplitudeVariableVC = $TPGlobalPath + ":AmplitudeVC"
	variable /g $TPGlobalPath + ":AmplitudeIC"
	NVAR GlobalTPAmplitudeVariableIC = $TPGlobalPath + ":AmplitudeIC"	
	make /o /n = 8 $TPGlobalPath + ":Resistance"
	wave ITCChanConfigWave = $HSU_DataFullFolderPathString(PanelTitle) + ":ITCChanConfigWave"
	string /g $TPGlobalPath + ":ADChannelList" = RefToPullDatafrom2DWave(0, 0, 1, ITCChanConfigWave)
	variable /g $TPGlobalPath + ":NoOfActiveDA" = NoOfChannelsSelected("da", "check", panelTitle)
	controlinfo /w = $panelTitle SetVar_DataAcq_TPDuration
	PulseDuration = (v_value / 0.005)
	GlobalTPDurationVariable = PulseDuration
	redimension /n = (2 * PulseDuration) TestPulse
	controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitude
	TestPulse[(PulseDuration / 2), (Pulseduration + (PulseDuration / 2))] = v_value
	GlobalTPAmplitudeVariableVC = v_value
	controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitudeIC
	GlobalTPAmplitudeVariableIC = v_value
End


Function TP_ButtonProc_DataAcq_TestPulse(ctrlName) : ButtonControl// Button that starts the test pulse
	String ctrlName
	string PanelTitle
	
	getwindow kwTopWin activesw
	PanelTitle = s_value
	variable SearchResult = strsearch(panelTitle, "Oscilloscope", 2)
	
	if(SearchResult != -1)
	PanelTitle = PanelTitle[0,SearchResult-2]//SearchResult+1]
	endif
	
	AbortOnValue HSU_DeviceLockCheck(PanelTitle),1
	
	
	controlinfo /w = $panelTitle SetVar_DataAcq_TPDuration
	if(v_value == 0)
		abort "Give test pulse a duration greater than 0 ms"
	endif
	
	ControlInfo /w = $panelTitle $ctrlName
	if(V_disable == 0)
		Button $ctrlName, win = $panelTitle, disable = 1
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
	setwindow $panelTitle +"#oscilloscope", hide = 0
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
		controlinfo /w = $panelTitle check_Settings_ShowScopeWindow
		if(v_value == 0)
			SmoothResizePanel(-340, panelTitle)
			setwindow $panelTitle +"#oscilloscope", hide = 1
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

//The function TPDelta is called by the TP dataaquistion functions
//It updates a wave in the Test pulse folder for the device
//The wave contains the steady state difference between the baseline and the TP response

ThreadSafe Function TP_Delta(panelTitle, InputDataPath) // the input path is the path to the test pulse folder for the device on which the TP is being activated
				string panelTitle
				string InputDataPath
				NVAR Duration = $InputDataPath + ":Duration"
				NVAR AmplitudeIC = $InputDataPath + ":AmplitudeIC"	
				NVAR AmplitudeVC = $InputDataPath + ":AmplitudeVC"	
				wave TPWave = $InputDataPath + ":TestPulseITC"
				variable BaselineSteadyStateStartTime = (0.75 * (Duration / 400))
				variable BaselineSteadyStateEndTime = (0.95 * (Duration / 400))
				variable TPSSEndTime = (0.95*((Duration * 0.0075)))
				variable PointsInSteadyStatePeriod =  (((BaselineSteadyStateEndTime - DimOffset(TPWave, 0))/DimDelta(TPWave,0)) - ((BaselineSteadyStateStartTime - DimOffset(TPWave, 0))/DimDelta(TPWave,0)))// (x2pnt(TPWave, BaselineSteadyStateEndTime) - x2pnt(TPWave, BaselineSteadyStateStartTime))
				variable BaselineSSStartPoint = (BaselineSteadyStateStartTime - DimOffset(TPWave, 0))/DimDelta(TPWave,0)
				variable BaslineSSEndPoint = BaselineSSStartPoint + PointsInSteadyStatePeriod	
				variable TPSSEndPoint = (TPSSEndTime - DimOffset(TPWave, 0))/DimDelta(TPWave,0)
				variable TPSSStartPoint = TPSSEndPoint - PointsInSteadyStatePeriod
				duplicate /o /r = [BaselineSSStartPoint, BaslineSSEndPoint][] TPWave, $InputDataPath + ":BaselineSS"
				wave BaselineSS = $InputDataPath + ":BaselineSS"
				duplicate /o /r = [TPSSStartPoint, TPSSEndPoint][] TPWave, $InputDataPath + ":DeltaSS"
				wave DeltaSS = $InputDataPath + ":DeltaSS"
				DeltaSS -= BaselineSS
				DeltaSS = abs(DeltaSS)
				
				NVAR NoOfActiveDA = $InputDataPath + ":NoOfActiveDA"
				variable columns =  (dimsize(DeltaSS,1) - NoOfActiveDA)-1
				duplicate /o /r = [0][0, columns] DeltaSS $InputDataPath + ":DeltaSSAvg"
				wave DeltaSSAvg = $InputDataPath + ":DeltaSSAvg"
				
				variable i = 0
				i += NoOfActiveDA

				do
					duplicate /Free /r = [][i] DeltaSS, TPWaveColumn
					DeltaSSAvg[0][i - NoOfActiveDA] = mean(TPWaveColumn)
					i += 1
				while(i < dimsize(DeltaSS, 1))
				
				duplicate /o DeltaSSAvg $InputDataPath + ":Resistance"
				wave Resistance = $InputDataPath + ":Resistance"
				SVAR ClampModeString = $InputDataPath + ":ClampModeString"
				i = 0
				do
					if(str2num(stringfromlist(i, ClampModeString, ";"))==1)
						Resistance[0][i] = DeltaSSAvg / AmplitudeIC    // R = V / I
					else
						Resistance[0][i] = AmplitudeVC / DeltaSSAvg    // R = V / I
					endif
					i += 1
				while(i < dimsize(DeltaSSAvg, 1))
			End
			
Function TP_CalculateResistance(panelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCChanConfigWave = $WavePath + ":ITCChanConfigWave"
	string ADChannelList = RefToPullDatafrom2DWave(0,0, 1, ITCChanConfigWave)
	variable NoOfActiveDA = NoOfChannelsSelected("DA", "check", panelTitle)
	variable NoOfActiveAD = NoOfChannelsSelected("AD", "check", panelTitle)
	variable i = 0
	make /o /n = (NoOfActiveAD) Resistance
	variable AmplitudeVC
	variable AmplitudeIC

End

Function TP_PullDataFromTPITCandAvgIT(PanelTitle, InputDataPath)
	string panelTitle, InputDataPath
	NVAR NoOfActiveDA = $InputDataPath + ":NoOFActiveDA"
	variable column = NoOfActiveDA-1
	SVAR ADChannelList = $InputDataPath + ":ADChannelList"
	variable NoOfADChannels = itemsinlist(ADchannelList)
	wave Resistance = $InputDataPath + ":Resistance"
	NVAR Amplitude = $InputDataPath + ":Amplitude"
End

//  function that creates string of clamp modes based on the ad channel associated with the headstage	
Function TP_ClampModeString(panelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	SVAR ADChannelList = $WavePath + ":TestPulse:ADChannelList"
	variable i = 0
	string /g $WavePath + ":TestPulse:ClampModeString"
	SVAR ClampModeString = $WavePath + ":TestPulse:ClampModeString"
	ClampModeString = ""
	
	do
		ClampModeString += (num2str(TP_HeadstageMode(panelTitle, TP_HeadstageUsingADC(panelTitle, str2num(stringfromlist(i,ADChannelList, ";"))))) + ";")
		i += 1
	while(i < itemsinlist(ADChannelList))
End



Function TP_HeadstageUsingADC(panelTitle, AD)
	string panelTitle
	variable AD
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ChanAmpAssign = $WavePath +":ChanAmpAssign"
	variable i = 0
	
	do
		if(ChanAmpAssign[4][i] == AD)
		 	break
		endif
	i += 1
	while(i<7)	
	
	if(ChanAmpAssign[4][i] == AD)
		return i
	else
		return Nan
	endif
End

Function TP_HeadstageMode(panelTitle, HeadStage)
	string panelTitle
	variable Headstage
	variable ClampMode
	Headstage*=2

	string ControlName = "Radio_ClampMode_" + num2str(HeadStage)
	
	controlinfo /w = $panelTitle $ControlName
	if(v_value == 1)
		clampMode = 0 // V clamp
		return clampMode
	endif
	
	if(v_value == 0)
		clampMode = 1 // I clamp
		return clampMode
	endif
	
	return ClampMode
End

