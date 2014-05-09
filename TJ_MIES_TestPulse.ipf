#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function TP_SelectTestPulseWave(panelTitle)//Selects Test Pulse output wave for all checked DA channels
	string panelTitle
	string ListOfCheckedDA = DC_ControlStatusListString("DA", "Check", panelTitle)
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

Function TP_StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
	wave SelectedDACWaveList
	string panelTitle
	string ListOfCheckedDA = DC_ControlStatusListString("DA", "Check", panelTitle)
	string DAPopUpMenu
	variable i
	
	do
		if((str2num(stringfromlist(i,ListOfCheckedDA,";"))) == 1)
			DAPopUpMenu = "Wave_DA_0"+num2str(i)
			controlinfo /w = $panelTitle $DAPopUpMenu 
			SelectedDACWaveList[i] = v_value
		endif
	i += 1
	while(i < itemsinlist(ListOfCheckedDA))
end

Function TP_ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
	wave SelectedDACWaveList
	string panelTitle
	string ListOfCheckedDA = DC_ControlStatusListString("DA", "Check", panelTitle)
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

Function TP_StoreDAScale(SelectedDACScale, panelTitle)
	wave SelectedDACScale
	string panelTitle
	string ListOfCheckedDA = DC_ControlStatusListString("DA", "Check", panelTitle)
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

Function TP_SetDAScaleToOne(panelTitle)
	string panelTitle
	string ListOfCheckedDA = DC_ControlStatusListString("DA", "Check", panelTitle)
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
	i += 1
	while(i < itemsinlist(ListOfCheckedDA))
end

Function TP_RestoreDAScale(SelectedDACScale, panelTitle)
	wave SelectedDACScale
	string panelTitle
	string ListOfCheckedDA = DC_ControlStatusListString("DA", "Check", panelTitle)
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

Function TP_UpdateTestPulseWave(TestPulse, panelTitle) // full path name
	wave TestPulse
	string panelTitle
	variable PulseDuration
	string TPGlobalPath = HSU_DataFullFolderPathString(PanelTitle) + ":TestPulse"
	//print TPGlobalPath
	variable /g  $TPGlobalPath + ":Duration"
	NVAR GlobalTPDurationVariable = $(TPGlobalPath + ":Duration")
	variable /g $TPGlobalPath + ":AmplitudeVC"
	NVAR GlobalTPAmplitudeVariableVC = $(TPGlobalPath + ":AmplitudeVC")
	variable /g $TPGlobalPath + ":AmplitudeIC"
	NVAR GlobalTPAmplitudeVariableIC = $(TPGlobalPath + ":AmplitudeIC")	
	make /o /n = 8 $TPGlobalPath + ":Resistance"
	wave /z ITCChanConfigWave = $(HSU_DataFullFolderPathString(PanelTitle) + ":ITCChanConfigWave")
	string /g $(TPGlobalPath + ":ADChannelList") = SCOPE_RefToPullDatafrom2DWave(0, 0, 1, ITCChanConfigWave)
	variable /g $(TPGlobalPath + ":NoOfActiveDA") = DC_NoOfChannelsSelected("da", "check", panelTitle)
	controlinfo /w = $panelTitle SetVar_DataAcq_TPDuration
	PulseDuration = (v_value / 0.005)
	GlobalTPDurationVariable = PulseDuration
	redimension /n = (2 * PulseDuration) TestPulse
	// need to deal with units here to ensure that resistance is calculated correctly
	controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitude
	print "TP amp =",v_value
	TestPulse[(PulseDuration / 2), (Pulseduration + (PulseDuration / 2))] = v_value
	GlobalTPAmplitudeVariableVC = v_value
	controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitudeIC
	GlobalTPAmplitudeVariableIC = v_value
End

Function TP_UpdateTestPulseWaveChunks(TestPulse, panelTitle) // Testpulse = full path name; creates 100 TPs in a row
	wave TestPulse
	string panelTitle
	variable i = 0
	variable PulseDuration
	variable DataAcqOrTP = 1 // test pulse function
	string TPGlobalPath = HSU_DataFullFolderPathString(PanelTitle) + ":TestPulse"
	variable MinSampInt = DC_ITCMinSamplingInterval(panelTitle)
	//print TPGlobalPath
	variable /g  $TPGlobalPath + ":Duration"
	NVAR GlobalTPDurationVariable = $(TPGlobalPath + ":Duration")
	variable /g $TPGlobalPath + ":AmplitudeVC"
	NVAR GlobalTPAmplitudeVariableVC = $(TPGlobalPath + ":AmplitudeVC")
	variable /g $TPGlobalPath + ":AmplitudeIC"
	NVAR GlobalTPAmplitudeVariableIC = $(TPGlobalPath + ":AmplitudeIC")	
	make /o /n = 8 $TPGlobalPath + ":Resistance"
	wave /z ITCChanConfigWave = $(HSU_DataFullFolderPathString(PanelTitle) + ":ITCChanConfigWave")
	string /g $(TPGlobalPath + ":ADChannelList") = SCOPE_RefToPullDatafrom2DWave(0, 0, 1, ITCChanConfigWave)
	variable /g $(TPGlobalPath + ":NoOfActiveDA") = DC_NoOfChannelsSelected("da", "check", panelTitle)
	controlinfo /w = $panelTitle SetVar_DataAcq_TPDuration
	variable TPDurInms = v_value
	print "min samp int = ", minsampint
	PulseDuration = (TPDurInms  / (MinSampInt/1000))
	GlobalTPDurationVariable = PulseDuration
	variable ITCdataWaveLength = DC_CalculateITCDataWaveLength(panelTitle, DataAcqOrTP)
	
	//redimension /n = (200 * PulseDuration) TestPulse // makes room in wave for 100 TPs
	// need to deal with units here to ensure that resistance is calculated correctly
	controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitude
	variable Amplitude = v_value
	print "TP amp =", v_value 
	print pulseduration
	variable Frequency = 1000 / (TPDurInms * 2)
	print "frequency = ",frequency
	variable /g $(TPGlobalPath + ":TPPulseCount")
	NVAR TPPulseCount = $(TPGlobalPath + ":TPPulseCount")
	TPPulseCount = TP_CreateSquarePulseWave(panelTitle, Frequency, Amplitude, TestPulse)
//	do
//		TestPulse[((PulseDuration / 2) + (i * PulseDuration * 2)), ((Pulseduration + (PulseDuration / 2))  + (i * PulseDuration * 2))] = v_value
//		
//		i += 1
//	while (i < 100)
	GlobalTPAmplitudeVariableVC = v_value
	controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitudeIC
	GlobalTPAmplitudeVariableIC = v_value
End


mV and pA = Mohm
Function TP_ButtonProc_DataAcq_TestPulse(ctrlName) : ButtonControl// Button that starts the test pulse
	String ctrlName
	string PanelTitle

	pauseupdate
	setdatafolder root:
	getwindow kwTopWin activesw

	variable DataAcqOrTP = 1
	PanelTitle = s_value
	variable SearchResult = strsearch(panelTitle, "Oscilloscope", 2)
	if(SearchResult != -1)
		PanelTitle = PanelTitle[0,SearchResult - 2]//SearchResult+1]
	endif
	
	AbortOnValue HSU_DeviceLockCheck(PanelTitle),1
		
	controlinfo /w = $panelTitle SetVar_DataAcq_TPDuration
	if(v_value == 0)
		abort "Give test pulse a duration greater than 0 ms"
	endif
	
	ControlInfo /w = $panelTitle $ctrlName
	if(V_disable == 0)
		Button $ctrlName, win = $panelTitle, disable = 2
	endif
	
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	

	
	string CountPath = WavePath + ":count"
	if(exists(CountPath) == 2)
		killvariables $CountPath
	endif
	
	variable MinSampInt = DC_ITCMinSamplingInterval(PanelTitle)
	ValDisplay ValDisp_DataAcq_SamplingInt win = $PanelTitle, value = _NUM:MinSampInt
	
	controlinfo /w = $panelTitle popup_MoreSettings_DeviceType
	variable DeviceType = v_value - 1
	controlinfo /w = $panelTitle popup_moreSettings_DeviceNo
	variable DeviceNum = v_value - 1
	
	DAP_StoreTTLState(panelTitle)
	DAP_TurnOffAllTTLs(panelTitle)
	
	controlinfo /w = $panelTitle check_Settings_ShowScopeWindow
	if(v_value == 0)
	DAP_SmoothResizePanel(340, panelTitle)
	setwindow $panelTitle +"#oscilloscope", hide = 0
	endif
	
	string TestPulsePath = "root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse"
	make /o /n = 0 $TestPulsePath
	wave TestPulse = $TestPulsePath
	SetScale /P x 0,0.005,"ms", TestPulse
	//print testpulsepath
	TP_UpdateTestPulseWave(TestPulse, panelTitle)
	DM_CreateScaleTPHoldingWave(panelTitle)
	make /free /n = 8 SelectedDACWaveList
	TP_StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
	TP_SelectTestPulseWave(panelTitle)

	make /free /n = 8 SelectedDACScale
	TP_StoreDAScale(SelectedDACScale,panelTitle)
	TP_SetDAScaleToOne(panelTitle)
	
	DC_ConfigureDataForITC(panelTitle, DataAcqOrTP)
	wave TestPulseITC = $WavePath+":TestPulse:TestPulseITC"
	SCOPE_UpdateGraph(TestPulseITC,panelTitle)

	controlinfo /w = $panelTitle Check_Settings_BkgTP
	if(v_value == 1)// runs background TP
		ITC_StartBackgroundTestPulse(DeviceType, DeviceNum, panelTitle)
	else // runs TP
		ITC_StartTestPulse(DeviceType,DeviceNum, panelTitle)
		controlinfo /w = $panelTitle check_Settings_ShowScopeWindow
		if(v_value == 0)
			DAP_SmoothResizePanel(-340, panelTitle)
			setwindow $panelTitle +"#oscilloscope", hide = 1
		endif
		killwaves /f TestPulse
	endif
	
	TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
	TP_RestoreDAScale(SelectedDACScale,panelTitle)
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
				AmplitudeIC = abs(AmplitudeIC)
				AmplitudeVC =  abs(AmplitudeVC)
				wave TPWave = $InputDataPath + ":TestPulseITC"
				variable BaselineSteadyStateStartTime = (0.75 * (Duration / 400))
				variable BaselineSteadyStateEndTime = (0.95 * (Duration / 400))
				variable TPSSEndTime = (0.95*((Duration * 0.0075)))
				variable TPInstantaneouseOnsetTime = (Duration / 400) + 0.01 // starts a tenth of a second after pulse to exclude cap transients - this should probably not be hard coded
				variable DimOffsetVar = DimOffset(TPWave, 0) 
				variable DimDeltaVar = DimDelta(TPWave, 0)
				variable PointsInSteadyStatePeriod =  (((BaselineSteadyStateEndTime - DimOffsetVar) / DimDeltaVar) - ((BaselineSteadyStateStartTime - DimOffsetVar) / DimDeltaVar))// (x2pnt(TPWave, BaselineSteadyStateEndTime) - x2pnt(TPWave, BaselineSteadyStateStartTime))
				variable BaselineSSStartPoint = ((BaselineSteadyStateStartTime - DimOffsetVar) / DimDeltaVar)
				variable BaslineSSEndPoint = BaselineSSStartPoint + PointsInSteadyStatePeriod	
				variable TPSSEndPoint = ((TPSSEndTime - DimOffsetVar) / DimDeltaVar)
				variable TPSSStartPoint = TPSSEndPoint - PointsInSteadyStatePeriod
				variable TPInstantaneouseOnsetPoint = ((TPInstantaneouseOnsetTime  - DimOffsetVar) / DimDeltaVar)
				NVAR NoOfActiveDA = $InputDataPath + ":NoOfActiveDA"
				SVAR ClampModeString = $InputDataPath + ":ClampModeString"
				duplicate /free /r = [BaselineSSStartPoint, BaslineSSEndPoint][] TPWave, BaselineSS
				duplicate /free /r = [TPSSStartPoint, TPSSEndPoint][] TPWave, TPSS
				duplicate /free /r = [TPInstantaneouseOnsetPoint, (TPInstantaneouseOnsetPoint + 50)][] TPWave Instantaneous
				
				MatrixOP /free /NTHR = 0 AvgTPSS = sumCols(TPSS)
				avgTPSS /= dimsize(TPSS, 0)
 				//avgTPSS = abs(avgTPSS)
 				
				MatrixOp /free /NTHR = 0   AvgBaselineSS = sumCols(BaselineSS)
				AvgBaselineSS /= dimsize(BaselineSS, 0)
				//AvgBaselineSS = abs(AvgBaselineSS)
				
				duplicate /free AvgTPSS, AvgDeltaSS
				AvgDeltaSS -= AvgBaselineSS
				AvgDeltaSS = abs(AvgDeltaSS)
				
				wavestats Instantaneous
				variable i = 0 
				variable columnsInWave = dimsize(Instantaneous, 1)
				make /FREE /n = (1, columnsInWave) InstAvg
				variable OneDInstMax
				variable OndDBaseline

				do
					matrixOp /Free Instantaneous1d = col(Instantaneous, i + NoOfActiveDA)
					wavestats Instantaneous1d
					OneDInstMax = v_max
					OndDBaseline = AvgBaselineSS[0][i + NoOfActiveDA]	

					if(OneDInstMax > OndDBaseline)
						Multithread InstAvg[0][i + NoOfActiveDA] = mean(Instantaneous1d, pnt2x(Instantaneous1d, V_maxRowLoc - 1), pnt2x(Instantaneous1d, V_maxRowLoc + 1))
					else
						Multithread InstAvg[0][i + NoOfActiveDA] = mean(Instantaneous1d, pnt2x(Instantaneous1d, V_minRowLoc - 1), pnt2x(Instantaneous1d, V_minRowLoc + 1))
					endif
					//print InstAvg[0][i + NoOfActiveDA]
					i += 1
				while(i < (columnsInWave - NoOfActiveDA))

				//Multithread InstAvg = abs(InstAvg)
				Multithread InstAvg -= AvgBaselineSS
				Multithread InstAvg = abs(InstAvg)
				//Multithread AvgInstantaneousDelta = abs(AvgInstantaneousDelta)
				
				//variable columns =  (dimsize(DeltaSS,1)// - NoOfActiveDA) //- 1
				//print "columns " ,columns
				duplicate /o /r = [][NoOfActiveDA, dimsize(TPSS,1) - 1] AvgDeltaSS $InputDataPath + ":SSResistance"
				wave SSResistance = $InputDataPath + ":SSResistance"
				SetScale/P x TPSSEndTime,1,"ms", SSResistance
				
				duplicate /o /r = [][(NoOfActiveDA), (dimsize(TPSS,1) - 1)] InstAvg $InputDataPath + ":InstResistance"
				wave InstResistance = $InputDataPath + ":InstResistance"
				SetScale/P x TPInstantaneouseOnsetTime,1,"ms", InstResistance

				SVAR ClampModeString = $InputDataPath + ":ClampModeString"
				string decimalAdjustment
			 	i = 0
				do
					if((str2num(stringfromlist(i, ClampModeString, ";"))) == 1)
						Multithread SSResistance[0][i] = (AvgDeltaSS[0][i + NoOfActiveDA] / (AmplitudeIC))*1000 // R = V / I
						sprintf decimalAdjustment, "%0.3g", SSResistance[0][i]
						SSResistance[0][i] = str2num(decimalAdjustment)

						Multithread InstResistance[0][i] =  (InstAvg[0][i + NoOfActiveDA] / (AmplitudeIC))*1000
						sprintf decimalAdjustment, "%0.3g", InstResistance[0][i]
						Multithread InstResistance[0][i] = str2num(decimalAdjustment)						
					else
 						Multithread SSResistance[0][i] = ((AmplitudeVC) / AvgDeltaSS[0][i + NoOfActiveDA]) * 1000
 						sprintf decimalAdjustment, "%0.3g", SSResistance[0][i]
						Multithread SSResistance[0][i] = str2num(decimalAdjustment)
 						
 						Multithread InstResistance[0][i] = ((AmplitudeVC) / InstAvg[0][i + NoOfActiveDA]) * 1000
 						sprintf decimalAdjustment, "%0.3g", InstResistance[0][i]
						Multithread InstResistance[0][i] = str2num(decimalAdjustment)						
					endif
					i += 1
				while(i < (dimsize(AvgDeltaSS, 1) - NoOfActiveDA))
			End
			
Function TP_CalculateResistance(panelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCChanConfigWave = $WavePath + ":ITCChanConfigWave"
	string ADChannelList = SCOPE_RefToPullDatafrom2DWave(0,0, 1, ITCChanConfigWave)
	variable NoOfActiveDA = DC_NoOfChannelsSelected("DA", "check", panelTitle)
	variable NoOfActiveAD = DC_NoOfChannelsSelected("AD", "check", panelTitle)
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

//  function that creates string of clamp modes based on the ad channel associated with the headstage	- in the sequence of ADchannels in ITCDataWave - i.e. numerical order
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



Function TP_HeadstageUsingADC(panelTitle, AD) //find the headstage using a particular AD
	string panelTitle
	variable AD
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ChanAmpAssign = $WavePath +":ChanAmpAssign"
	variable i = 0
	
	do
		if(ChanAmpAssign[2][i] == AD)
		 	break
		endif
		i += 1
	while(i<7)	
	
	if(ChanAmpAssign[2][i] == AD)
		return i
	else
		return Nan
	endif
End

Function TP_HeadstageMode(panelTitle, HeadStage) // returns the clamp mode of a "headstage"
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

Function TP_IsBackgrounOpRunning(panelTitle, OpName)
	string panelTitle, OpName
	variable NoYes // no = 0, 1 = yes
	CtrlNamedBackground $OpName, status
	if(str2num(stringfromlist(2, s_info, ";")[4])==0)
		NoYes = 0 // NO = 0
	else
		NoYes = 1 // YES = 1
	endif
	
	return NoYes
End

Function TP_CreateSquarePulseWave(panelTitle, Frequency, Amplitude, TPWave)
	string panelTitle
	variable frequency
	variable amplitude
	Wave TPWave
	variable numberOfSquarePulses
	variable  longestSweepPoints = (((1000 / Frequency) * 2) / 0.005)
	//print "longest sweep =", longestSweepPoints
	variable exponent = ceil(log(longestSweepPoints)/log(2))
	if(exponent < 16) // prevents FIFO underrun overrun errors by keepint the wave a minimum size
		exponent = 16
	endif 
	print exponent
	make /FREE /n = (2 ^ exponent)  BuildWave
	SetScale /P x 0,0.005, "ms", BuildWave

	MultiThread BuildWave = 0.999999 * - sin(2 * Pi * (Frequency * 1000) * (5 / 1000000000) * p)
	MultiThread BuildWave = Ceil(BuildWave)
	duplicate /o BuildWave TPWave
	TPWave *= Amplitude
	FindLevels /Q BuildWave, 0.5
	numberOfSquarePulses = V_LevelsFound
	if(mod(numberOfSquarePulses, 2) == 0)
		return (numberOfSquarePulses / 2) 
	else
		numberOfSquarePulses -= 1
		return (numberOfSquarePulses / 2)
	endif
	// if an even number of levels are found the TP returns to baseline
End