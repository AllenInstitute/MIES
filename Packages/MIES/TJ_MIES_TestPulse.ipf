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
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave ChannelClampMode = $WavePath + ":ChannelClampMode"
	variable ScalingFactor
	variable i
	
	do
		if((str2num(stringfromlist(i, ListOfCheckedDA,";"))) == 1)
			//DASetVariable = "Scale_DA_0"+num2str(i)
			sprintf DASetVariable, "Scale_DA_0%s" num2str(i)
			if(ChannelClampMode[i][0] == 0)
				ScalingFactor = 1
			endif
			
			if(ChannelClampMode[i][0] == 1) // this adjust the scaling in current clamp so that the TP wave (constructed based on v-clamp param) is converted into the I clamp amp
				controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitudeIC
				ScalingFactor = v_value
				controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitude
				ScalingFactor /= v_value
			endif
			
			setvariable $DASetVariable WIN = $panelTitle,  value =_num:ScalingFactor 
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
	string TPGlobalPath = HSU_DataFullFolderPathString(panelTitle) + ":TestPulse"
	//print TPGlobalPath
	variable /g  $TPGlobalPath + ":Duration"
	NVAR GlobalTPDurationVariable = $(TPGlobalPath + ":Duration")
	variable /g $TPGlobalPath + ":AmplitudeVC"
	NVAR GlobalTPAmplitudeVariableVC = $(TPGlobalPath + ":AmplitudeVC")
	variable /g $TPGlobalPath + ":AmplitudeIC"
	NVAR GlobalTPAmplitudeVariableIC = $(TPGlobalPath + ":AmplitudeIC")	
	make /o /n = 8 $TPGlobalPath + ":Resistance"
	wave /z ITCChanConfigWave = $(HSU_DataFullFolderPathString(panelTitle) + ":ITCChanConfigWave")
	string /g $(TPGlobalPath + ":ADChannelList") = SCOPE_RefToPullDatafrom2DWave(0, 0, 1, ITCChanConfigWave)
	variable /g $(TPGlobalPath + ":NoOfActiveDA") = DC_NoOfChannelsSelected("da", "check", panelTitle)
	controlinfo /w = $panelTitle SetVar_DataAcq_TPDuration
	PulseDuration = (v_value) // duration of the TP in ms
	// PulseDuration = (v_value / 0.005)
	// PulseDuration = (v_value / (DC_ITCMinSamplingInterval(panelTitle) / 1000))
	GlobalTPDurationVariable = (PulseDuration / (DC_ITCMinSamplingInterval(panelTitle) / 1000))
	print "here, tp global dur =", GlobalTPDurationVariable
	
	variable PointsInTPWave = (2 * PulseDuration) 
	PointsInTPWave *= 200
	redimension /n = (PointsInTPWave) TestPulse
	//redimension /n = ((8 * PulseDuration)) TestPulse
	// need to deal with units here to ensure that resistance is calculated correctly
	controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitude // the scaling converts the V-clamp TP to an I-clamp TP as appropriate (i.e. it is not done here)
	variable TPamp = v_value
	print "TP amp =",v_value

	PulseDuration *= 2
	print "startpoint = ", (0.25*PointsInTPWave)
	TestPulse[round(0.25 * PointsInTPWave), round(0.75 * PointsInTPWave)] = TPamp

 	GlobalTPAmplitudeVariableVC = TPamp
	controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitudeIC
	GlobalTPAmplitudeVariableIC = v_value
	//print v_value
End

// TP_UpdateTestPulseWaveChunks  
Function TP_UpdateTestPulseWaveChunks(TestPulse, panelTitle) // Testpulse = full path name; creates wave with enought TPs to fill min wave size(2^17)
	wave TestPulse											// this function is only used with MD functions
	string panelTitle
	variable i = 0
	variable PulseDuration
	variable DataAcqOrTP = 1 // test pulse function
	string TPGlobalPath = HSU_DataFullFolderPathString(panelTitle) + ":TestPulse"
	variable MinSampInt = DC_ITCMinSamplingInterval(panelTitle)
	variable /g $(TPGlobalPath + ":NoOfActiveDA") = DC_NoOfChannelsSelected("da", "check", panelTitle)	
	variable /g  $TPGlobalPath + ":Duration"
	NVAR GlobalTPDurationVariable = $(TPGlobalPath + ":Duration")
	variable /g $TPGlobalPath + ":AmplitudeVC"
	NVAR GlobalTPAmplitudeVariableVC = $(TPGlobalPath + ":AmplitudeVC")
	variable /g $TPGlobalPath + ":AmplitudeIC"
	NVAR GlobalTPAmplitudeVariableIC = $(TPGlobalPath + ":AmplitudeIC")	
	make /o /n = 8 $TPGlobalPath + ":Resistance"
	wave /z ITCChanConfigWave = $(HSU_DataFullFolderPathString(panelTitle) + ":ITCChanConfigWave")
	string /g $(TPGlobalPath + ":ADChannelList") = SCOPE_RefToPullDatafrom2DWave(0, 0, 1, ITCChanConfigWave)
	variable /g $(TPGlobalPath + ":NoOfActiveDA") = DC_NoOfChannelsSelected("da", "check", panelTitle)
	controlinfo /w = $panelTitle SetVar_DataAcq_TPDuration
	variable TPDurInms = v_value
	//print "tp dur in ms=",tpdurinms
	// print "min samp int = ", minsampint
	PulseDuration = (TPDurInms  / (MinSampInt/1000))  // pulse duration in points - should be called pulse points
	// print "pulse points = ", PulseDuration
	GlobalTPDurationVariable = PulseDuration
	variable ITCdataWaveLength = DC_CalculateITCDataWaveLength(panelTitle, DataAcqOrTP) // wave length in points
	
	//redimension /n = (200 * PulseDuration) TestPulse // makes room in wave for 100 TPs
	// need to deal with units here to ensure that resistance is calculated correctly
	controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitude
	variable Amplitude = v_value
//	print "TP amp =", v_value 
//	print pulseduration
	variable Frequency = 1000 / (TPDurInms * 2)
	// print "frequency = ",frequency
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


// mV and pA = Mohm
Function TP_ButtonProc_DataAcq_TestPulse(ctrlName) : ButtonControl// Button that starts the test pulse
	String ctrlName
	string panelTitle

	pauseupdate
	setdatafolder root:
	getwindow kwTopWin activesw

	variable DataAcqOrTP = 1
	panelTitle = s_value
	variable SearchResult = strsearch(panelTitle, "Oscilloscope", 2)
	if(SearchResult != -1)
		panelTitle = panelTitle[0,SearchResult - 2]//SearchResult+1]
	endif
	
	AbortOnValue HSU_DeviceLockCheck(panelTitle),1
		
	controlinfo /w = $panelTitle SetVar_DataAcq_TPDuration
	if(v_value == 0)
		abort "Give test pulse a duration greater than 0 ms"
	endif
	
	ControlInfo /w = $panelTitle $ctrlName
	if(V_disable == 0)
		Button $ctrlName, win = $panelTitle, disable = 2
	endif
	
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	

	
	string CountPath = WavePath + ":count"
	if(exists(CountPath) == 2)
		killvariables $CountPath
	endif
	
	variable MinSampInt = DC_ITCMinSamplingInterval(panelTitle)
	ValDisplay ValDisp_DataAcq_SamplingInt win = $panelTitle, value = _NUM:MinSampInt
	
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
		// killwaves /f TestPulse
	endif
	
	TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
	TP_RestoreDAScale(SelectedDACScale,panelTitle)
End

//=============================================================================================
/// TP_ButtonProc_DataAcq_TPMD
Function TP_ButtonProc_DataAcq_TPMD(ctrlName) : ButtonControl// Button that starts the test pulse
	String ctrlName
	string panelTitle
	sprintf panelTitle, "%s" DAP_ReturnPanelName()
	// pauseupdate
	
	// make sure data folder is correct
	setdatafolder root:
	
	//variable DataAcqOrTP = 1
	
	// Check if panel is locked to a DAC
	AbortOnValue HSU_DeviceLockCheck(panelTitle),1
	
	// *** need to modify for yoked devices
	// Check if TP uduration is greater than 0 ms	
	controlinfo /w = $panelTitle SetVar_DataAcq_TPDuration
	if(v_value == 0)
		abort "Give test pulse a duration greater than 0 ms"
	endif
	
	// Disable the TP start button
	ControlInfo /w = $panelTitle $ctrlName
	if(V_disable == 0)
		Button $ctrlName, win = $panelTitle, disable = 2
	endif
	
	// Determine the data folder path for the DAC
	string WavePath
	sprintf WavePath, "%s" HSU_DataFullFolderPathString(panelTitle)
	
	// *** need to modify for yoked devices
	// Kill the global variable Count if it exists - if it was allowed to exist the user would not be able to stop the TP using the space bar
	string CountPath = WavePath + ":count"
	if(exists(CountPath) == 2)
		killvariables $CountPath
	endif
	
	// update TP buffer size global
	TP_UpdateTPBufferSizeGlobal(panelTitle)
	
	
	// update the miniumum sampling interval
	variable MinSampInt = DC_ITCMinSamplingInterval(panelTitle)
	ValDisplay ValDisp_DataAcq_SamplingInt win = $panelTitle, value = _NUM:MinSampInt
	
	// determine the device type and device number
	controlinfo /w = $panelTitle popup_MoreSettings_DeviceType
	variable DeviceType = v_value - 1
	controlinfo /w = $panelTitle popup_moreSettings_DeviceNo
	variable DeviceNum = v_value - 1
	
	StartTestPulse(deviceType, deviceNum, panelTitle)

End // Function
//=============================================================================================
/// updates the global variable n in the TP folder for the device that TP_Delta uses to calculate the mean resistance values
/// n determines the number of TP cycles to average
Function TP_UpdateTPBufferSizeGlobal(panelTitle)
	string panelTitle
	controlInfo /w = $panelTitle setvar_Settings_TPBuffer
	variable TPBufferSize = v_value
	string TPBufferSizeGlobalStringPath
	sprintf TPBufferSizeGlobalStringPath, "%s:TestPulse:n" HSU_DataFullFolderPathString(panelTitle)
	if(exists(TPBufferSizeGlobalStringPath) ==2)
		NVAR TPBufferSizeGlobal = $TPBufferSizeGlobalStringPath
		TPBufferSizeGlobal = TPBufferSize
	elseif(exists(TPBufferSizeGlobalStringPath) ==0)
		variable /g $TPBufferSizeGlobalStringPath
		NVAR TPBufferSizeGlobal = $TPBufferSizeGlobalStringPath
		TPBufferSizeGlobal = TPBufferSize	
	endif
End
//=============================================================================================
// Calculate input resistance simultaneously on array so it is fast
ThreadSafe Function TP_Delta(panelTitle, InputDataPath) // the input path is the path to the test pulse folder for the device on which the TP is being activated
				string panelTitle
				string InputDataPath
				string StringPath
				sprintf StringPath, "%s:Duration" InputDataPath
				NVAR DurationG = $StringPath

				sprintf stringPath,  "%s:AmplitudeIC" InputDataPath
				NVAR AmplitudeIC = $StringPath
				
				sprintf stringPath,  "%s:AmplitudeVC" InputDataPath
				NVAR AmplitudeVC = $StringPath			
				
				AmplitudeIC = abs(AmplitudeIC)
				AmplitudeVC =  abs(AmplitudeVC)

				sprintf stringPath,  "%s:TestPulseITC" InputDataPath
				wave TPWave = $stringPath
				
				sprintf stringPath,  "%s:n" InputDataPath
				NVAR RowsInBufferWaves = $stringPath
										
				variable Duration = (durationG * 2 * deltaX(TPWave)) // total duration of TP in ms
				variable BaselineSteadyStateStartTime =(0.1 * duration)
				variable BaselineSteadyStateEndTime = (0.24 * Duration)
				variable TPSSEndTime = (0.74 * duration)
				variable TPInstantaneouseOnsetTime = (0.252 * Duration)
				variable DimOffsetVar = DimOffset(TPWave, 0) 
				variable DimDeltaVar = DimDelta(TPWave, 0)
				variable PointsInSteadyStatePeriod =  (((BaselineSteadyStateEndTime - DimOffsetVar) / DimDeltaVar) - ((BaselineSteadyStateStartTime - DimOffsetVar) / DimDeltaVar))// (x2pnt(TPWave, BaselineSteadyStateEndTime) - x2pnt(TPWave, BaselineSteadyStateStartTime))
				variable BaselineSSStartPoint = ((BaselineSteadyStateStartTime - DimOffsetVar) / DimDeltaVar)
				variable BaslineSSEndPoint = BaselineSSStartPoint + PointsInSteadyStatePeriod	
				variable TPSSEndPoint = ((TPSSEndTime - DimOffsetVar) / DimDeltaVar)
				variable TPSSStartPoint = TPSSEndPoint - PointsInSteadyStatePeriod
				variable TPInstantaneousOnsetPoint = ((TPInstantaneouseOnsetTime  - DimOffsetVar) / DimDeltaVar)
				sprintf StringPath, "%s:NoOfActiveDA" InputDataPath
				NVAR NoOfActiveDA = $StringPath
			//	NVAR NoOfActiveDA = $InputDataPath + ":NoOfActiveDA"
				sprintf StringPath, "%s:ClampModeString" InputDataPath
				SVAR ClampModeString = $StringPath
			//	SVAR ClampModeString = $InputDataPath + ":ClampModeString"
			//	duplicate chunks of TP wave in regions of interest: Baseline, Onset, Steady state
				duplicate /free /r = [BaselineSSStartPoint, BaslineSSEndPoint][] TPWave, BaselineSS
				duplicate /free /r = [TPSSStartPoint, TPSSEndPoint][] TPWave, TPSS
				duplicate /free /r = [TPInstantaneousOnsetPoint, (TPInstantaneousOnsetPoint + 50)][] TPWave Instantaneous
			//	print "baseline start =", BaselineSSStartPoint, "BaslineSSEndPoint = ",BaslineSSEndPoint
			//	average the steady state wave	
				MatrixOP /free /NTHR = 0 AvgTPSS = sumCols(TPSS)
				avgTPSS /= dimsize(TPSS, 0)
 				//avgTPSS = abs(avgTPSS)
 			
 			//	average the baseline wave	
				MatrixOp /FREE /NTHR = 0   AvgBaselineSS = sumCols(BaselineSS)
			//	wave avgbaseliness
				AvgBaselineSS /= dimsize(BaselineSS, 0)
			//	print BaselineSS[0][4]
			//	print AvgBaselineSS[0][4]
				sprintf StringPath, "%s:BaselineSSAvg" InputDataPath 			
			//	print dimsize(TPSS,1) - 1
				duplicate /o / r = [][NoOfActiveDA, dimsize(BaselineSS,1) - 1] AvgBaselineSS $StringPath			
				wave BaselineSSAvg = $StringPath
			//	print baselinessavg[0][0], "here"
			//	calculate the difference between the steady state and the baseline	
				duplicate /free AvgTPSS, AvgDeltaSS
				AvgDeltaSS -= AvgBaselineSS
				AvgDeltaSS = abs(AvgDeltaSS)
			
			//	create wave that will hold instantaneous average
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

					if(OneDInstMax > OndDBaseline) // handles positive or negative TPs
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
				sprintf StringPath, "%s:SSResistance" InputDataPath
//				duplicate /o /r = [][NoOfActiveDA, dimsize(TPSS,1) - 1] AvgDeltaSS $InputDataPath + ":SSResistance"
				duplicate /o /r = [][NoOfActiveDA, dimsize(TPSS,1) - 1] AvgDeltaSS $StringPath
//				sprintf StringPath, "%s:SSResistance" InputDataPath
//				wave SSResistance = $InputDataPath + ":SSResistance"
				wave SSResistance = $StringPath
				SetScale/P x TPSSEndTime,1,"ms", SSResistance // this line determines where the value sit on the bottom axis of the oscilloscope
				
				sprintf StringPath, "%s:InstResistance" InputDataPath
//				duplicate /o /r = [][(NoOfActiveDA), (dimsize(TPSS,1) - 1)] InstAvg $InputDataPath + ":InstResistance"
				duplicate /o /r = [][(NoOfActiveDA), (dimsize(TPSS,1) - 1)] InstAvg $StringPath
//				wave InstResistance = $InputDataPath + ":InstResistance"
				wave InstResistance = $StringPath
				SetScale/P x TPInstantaneouseOnsetTime,1,"ms", InstResistance

				sprintf StringPath, "%s:ClampModeString" InputDataPath
//				SVAR ClampModeString = $InputDataPath + ":ClampModeString"
				SVAR ClampModeString = $StringPath
				string decimalAdjustment

			 	i = 0
				do
					if((str2num(stringfromlist(i, ClampModeString, ";"))) == 1)
						Multithread SSResistance[0][i] = (AvgDeltaSS[0][i + NoOfActiveDA] / (AmplitudeIC)) * 1000 // R = V / I
//						sprintf decimalAdjustment, "%0.3g", SSResistance[0][i]
//						SSResistance[0][i] = str2num(decimalAdjustment)

						Multithread InstResistance[0][i] =  (InstAvg[0][i + NoOfActiveDA] / (AmplitudeIC)) * 1000
//						sprintf decimalAdjustment, "%0.3g", InstResistance[0][i]
//						Multithread InstResistance[0][i] = str2num(decimalAdjustment)						
					else
 						Multithread SSResistance[0][i] = ((AmplitudeVC) / AvgDeltaSS[0][i + NoOfActiveDA]) * 1000
// 						sprintf decimalAdjustment, "%0.3g", SSResistance[0][i]
//						Multithread SSResistance[0][i] = str2num(decimalAdjustment)
 						
 						Multithread InstResistance[0][i] = ((AmplitudeVC) / InstAvg[0][i + NoOfActiveDA]) * 1000
// 						sprintf decimalAdjustment, "%0.3g", InstResistance[0][i]
//						Multithread InstResistance[0][i] = str2num(decimalAdjustment)						
					endif
					i += 1
				while(i < (dimsize(AvgDeltaSS, 1) - NoOfActiveDA))
			
			if(RowsInBufferWaves > 1)
				//variable columns = dimsize(SSResistance, 1)
//				variable columns = ((dimsize(TPSS,1) - 1) - NoOfActiveDA)
				variable columns = ((dimsize(TPSS,1)) - NoOfActiveDA)

//				variable rows = dimsize(SSResistance, 0)

				sprintf stringPath,  "%s:TPBaselineBuffer" InputDataPath
				make /o /n = (RowsInBufferWaves, columns) $stringPath
				wave /z TPBaselineBuffer = $stringPath // buffer wave for baseline avg - the first row will hold the value of the most recent TP, the waves will be averaged and the value will be passed into what was storing the data for the most recent TP
				matrixop /o TPBaselineBuffer =  rotaterows(TPBaselineBuffer, 1)
//				print BaselineSSAvg[0][0]
				TPBaselineBuffer[0][] = BaselineSSAvg[0][q]	 
				matrixop /o BaselineSSAvg = sumcols(TPBaselineBuffer)
				BaselineSSAvg /= RowsInBufferWaves
								
				sprintf stringPath,  "%s:TPInstBuffer" InputDataPath
				make /o /n = (RowsInBufferWaves, columns) $stringPath
				wave /z TPInstBuffer = $stringPath // buffer wave for Instantaneous avg				
				matrixop /o TPInstBuffer =  rotaterows(TPInstBuffer, 1)
				Multithread TPInstBuffer[0][] = InstResistance[0][q]
				matrixop /o InstResistance = sumcols(TPInstBuffer)
				InstResistance /= RowsInBufferWaves
				
				sprintf stringPath,  "%s:TPSSBuffer" InputDataPath
				make /o /n = (RowsInBufferWaves, columns) $stringPath
				wave /z TPSSBuffer = $stringPath // buffer wave for steady state avg
				matrixop /o TPSSBuffer =  rotaterows(TPSSBuffer, 1)
				Multithread TPSSBuffer[0][] = SSResistance[0][q]
				matrixop /o SSResistance = sumcols(TPSSBuffer)
				SSResistance /= RowsInBufferWaves			
			
			endif
			
//			sprintf StringPath, "%s:BaselineSS" InputDataPath 			
//			duplicate /o / r = [][NoOfActiveDA, dimsize(TPSS,1) - 1] AvgBaselineSS $StringPath		
			
			End

//The function TPDelta is called by the TP dataaquistion functions
//It updates a wave in the Test pulse folder for the device
//The wave contains the steady state difference between the baseline and the TP response
// instantaneous
/// In order to allow TP_Delta to be threadsafe it uses global variables (controlinfo is not threadsafe).
// ThreadSafe Function TP_Delta(panelTitle, InputDataPath) // the input path is the path to the test pulse folder for the device on which the TP is being activated
				string panelTitle
				string InputDataPath
				NVAR DurationG = $InputDataPath + ":Duration" // number of points in half the test pulse
				NVAR AmplitudeIC = $InputDataPath + ":AmplitudeIC"	
				NVAR AmplitudeVC = $InputDataPath + ":AmplitudeVC"	
				AmplitudeIC = abs(AmplitudeIC)
				AmplitudeVC =  abs(AmplitudeVC)
			//	variable Duration = DurationG  
				wave TPWave = $InputDataPath + ":TestPulseITC"
			//	print "duration global =",durationG
			//	variable Duration = (deltax(TPWave) / 0.005) * DurationG  // remove this line for non MD test pulse method Total points in TP wave // equals twice the number of points in the TP
				variable Duration = (durationG * 2 * deltaX(TPWave)) // total duration of TP in ms
			//	print "duration local = ", duration
			//	variable BaselineSteadyStateStartTime = (0.75 * (Duration / 400))
				variable BaselineSteadyStateStartTime =(0.1 * duration)
			//	variable BaselineSteadyStateEndTime = (0.95 * (Duration / 400))
				variable BaselineSteadyStateEndTime = (0.24 * Duration)
			//	variable TPSSEndTime = (0.95*((Duration * 0.0075)))
				variable TPSSEndTime = (0.74 * duration)
			//	variable TPInstantaneouseOnsetTime = (Duration / 400) + 0.03 // starts a tenth of a second after pulse to exclude cap transients - this should probably not be hard coded
				variable TPInstantaneouseOnsetTime = (0.252 * Duration)
			//	print "PeakOnset =",	TPInstantaneouseOnsetTime
				variable DimOffsetVar = DimOffset(TPWave, 0) 
				variable DimDeltaVar = DimDelta(TPWave, 0)
				variable PointsInSteadyStatePeriod =  (((BaselineSteadyStateEndTime - DimOffsetVar) / DimDeltaVar) - ((BaselineSteadyStateStartTime - DimOffsetVar) / DimDeltaVar))// (x2pnt(TPWave, BaselineSteadyStateEndTime) - x2pnt(TPWave, BaselineSteadyStateStartTime))
				variable BaselineSSStartPoint = ((BaselineSteadyStateStartTime - DimOffsetVar) / DimDeltaVar)
				variable BaslineSSEndPoint = BaselineSSStartPoint + PointsInSteadyStatePeriod	
				variable TPSSEndPoint = ((TPSSEndTime - DimOffsetVar) / DimDeltaVar)
				variable TPSSStartPoint = TPSSEndPoint - PointsInSteadyStatePeriod
				variable TPInstantaneousOnsetPoint = ((TPInstantaneouseOnsetTime  - DimOffsetVar) / DimDeltaVar)
				NVAR NoOfActiveDA = $InputDataPath + ":NoOfActiveDA"
				SVAR ClampModeString = $InputDataPath + ":ClampModeString"
			//	duplicate chunks of TP wave in regions of interest: Baseline, Onset, Steady state
				duplicate /free /r = [BaselineSSStartPoint, BaslineSSEndPoint][] TPWave, BaselineSS
				duplicate /free /r = [TPSSStartPoint, TPSSEndPoint][] TPWave, TPSS
				duplicate /free /r = [TPInstantaneousOnsetPoint, (TPInstantaneousOnsetPoint + 50)][] TPWave Instantaneous
				
			//	average the steady state wave	
				MatrixOP /free /NTHR = 0 AvgTPSS = sumCols(TPSS)
				avgTPSS /= dimsize(TPSS, 0)
 				//avgTPSS = abs(avgTPSS)
 			
 			//	average the baseline wave	
				MatrixOp /free /NTHR = 0   AvgBaselineSS = sumCols(BaselineSS)
				AvgBaselineSS /= dimsize(BaselineSS, 0)
				//AvgBaselineSS = abs(AvgBaselineSS)
			
			//	calculate the difference between the steady state and the baseline	
				duplicate /free AvgTPSS, AvgDeltaSS
				AvgDeltaSS -= AvgBaselineSS
				AvgDeltaSS = abs(AvgDeltaSS)
			
			//	create wave that will hold instantaneous average
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

					if(OneDInstMax > OndDBaseline) // handles positive or negative TPs
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
				SetScale/P x TPSSEndTime,1,"ms", SSResistance // this line determines where the value sit on the bottom axis of the oscilloscope
				
				duplicate /o /r = [][(NoOfActiveDA), (dimsize(TPSS,1) - 1)] InstAvg $InputDataPath + ":InstResistance"
				wave InstResistance = $InputDataPath + ":InstResistance"
				SetScale/P x TPInstantaneouseOnsetTime,1,"ms", InstResistance

				SVAR ClampModeString = $InputDataPath + ":ClampModeString"
				string decimalAdjustment
			 	i = 0
				do
					if((str2num(stringfromlist(i, ClampModeString, ";"))) == 1)
						Multithread SSResistance[0][i] = (AvgDeltaSS[0][i + NoOfActiveDA] / (AmplitudeIC)) * 1000 // R = V / I
						sprintf decimalAdjustment, "%0.3g", SSResistance[0][i]
						SSResistance[0][i] = str2num(decimalAdjustment)

						Multithread InstResistance[0][i] =  (InstAvg[0][i + NoOfActiveDA] / (AmplitudeIC)) * 1000
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
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave ITCChanConfigWave = $WavePath + ":ITCChanConfigWave"
	string ADChannelList = SCOPE_RefToPullDatafrom2DWave(0,0, 1, ITCChanConfigWave)
	variable NoOfActiveDA = DC_NoOfChannelsSelected("DA", "check", panelTitle)
	variable NoOfActiveAD = DC_NoOfChannelsSelected("AD", "check", panelTitle)
	variable i = 0
	make /o /n = (NoOfActiveAD) Resistance
	variable AmplitudeVC
	variable AmplitudeIC

End

Function TP_PullDataFromTPITCandAvgIT(panelTitle, InputDataPath)
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
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	string /g $WavePath + ":TestPulse:ADChannelList"
	SVAR ADChannelList = $WavePath + ":TestPulse:ADChannelList"
	wave ITCChanConfigWave = $WavePath + ":ITCChanConfigWave"
	ADChannelList = SCOPE_RefToPullDatafrom2DWave(0, 0, 1, ITCChanConfigWave)
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
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
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

///@breif Creates a square pulse wave at a given frequency
//Function TP_CreateSquarePulseWave(panelTitle, Frequency, Amplitude, TPWave)
//	string panelTitle
//	variable frequency
//	variable amplitude
//	Wave TPWave
//	variable numberOfSquarePulses
//	variable  longestSweepPoints = (((1000 / Frequency) * 2) / 0.005)  * (1 / (DC_ITCMinSamplingInterval(panelTitle) / 0.005))
//	//print "longest sweep =", longestSweepPoints
//	variable exponent = ceil(log(longestSweepPoints)/log(2))
//	if(exponent < 17) // prevents FIFO underrun overrun errors by keepint the wave a minimum size
//		exponent = 17
//	endif 
////	print "exponent =", exponent
//	make /FREE /n = (2 ^ exponent)  BuildWave
////	make /o /n = (2 ^ exponent)  BuildWave
//
//	SetScale /P x 0,0.005, "ms", BuildWave
//
//	MultiThread BuildWave = 0.999999 * - sin(2 * Pi * (Frequency * 1000) * (5 / 1000000000) * p)
//	MultiThread BuildWave = Ceil(BuildWave)
//	duplicate /o BuildWave TPWave
//
//	TPWave *= Amplitude
//	FindLevels /Q BuildWave, 0.5
//	numberOfSquarePulses = V_LevelsFound
//	if(mod(numberOfSquarePulses, 2) == 0)
//		return (numberOfSquarePulses / 2) 
//	else
//		numberOfSquarePulses -= 1
//		return (numberOfSquarePulses / 2)
//	endif
//	// if an even number of levels are found the TP returns to baseline
//End

/// Creates a square pulse wave where the duration of the pulse is equal to what the user inputs. The interpulse interval is twice the pulse duration.
/// The interpulse is twice as long as the pulse to give the cell membrane sufficient time to recover between pulses
Function TP_CreateSquarePulseWave(panelTitle, Frequency, Amplitude, TPWave) // TPWave = full path name
	string panelTitle
	variable frequency
	variable amplitude
	Wave TPWave

	variable numberOfSquarePulses
	variable  longestSweepPoints = (((1000 / Frequency) * 2) / 0.005)  * (1 / (DC_ITCMinSamplingInterval(panelTitle) / 0.005))
	//print "longest sweep =", longestSweepPoints
	variable exponent = ceil(log(longestSweepPoints)/log(2))
	if(exponent < 17) // prevents FIFO underrun overrun errors by keepint the wave a minimum size
		exponent = 17
	endif 

	make /FREE /n = (2 ^ exponent)  SinBuildWave
	make /FREE /n = (2 ^ exponent)  CosBuildWave
	make /FREE /n = (2 ^ exponent)  BuildWave

	SetScale /P x 0,0.005, "ms", SinBuildWave
	SetScale /P x 0,0.005, "ms", CosBuildWave
	SetScale /P x 0,0.005, "ms", BuildWave
	
	Frequency /= 1.5
	// the point offset is 1/4 of a cos wave cycle in points. The is used to make the baseline before the first pulse the same length as the interpulse interval
	variable PointOffset = ((1 / Frequency) / 0.000005) * 0.25
	Multithread SinBuildWave =  .49 * - sin(2 * Pi * (Frequency * 1000) * (5 / 1000000000) * (p + PointOffset))
	Multithread CosBuildWave = 0.49 * - cos(2 * Pi * ((Frequency* 2) * 1000) * (5 / 1000000000) * (p + PointOffset))
	Multithread BuildWave = SinBuildWave + CosBuildWave
	Multithread BuildWave = Ceil(Buildwave)

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
	
End