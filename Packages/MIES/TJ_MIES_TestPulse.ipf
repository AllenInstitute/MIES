#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function TP_SelectTestPulseWave(panelTitle)//Selects Test Pulse output wave for all checked DA channels
	string 	panelTitle
	string 	ListOfCheckedDA = DC_ControlStatusListString("DA", "Check", panelTitle)
	string 	DAPopUpMenu
	variable 	i
	
	do
		if((str2num(stringfromlist(i, ListOfCheckedDA,";"))) == 1)
			DAPopUpMenu = "Wave_DA_0"+num2str(i)
			popUpMenu $DAPopUpMenu mode = 2, win = $panelTitle
		endif
	i += 1
	while(i < itemsinlist(ListOfCheckedDA))
End

Function TP_StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
	wave 	SelectedDACWaveList
	string 	panelTitle
	string 	ListOfCheckedDA = DC_ControlStatusListString("DA", "Check", panelTitle)
	string 	DAPopUpMenu
	variable 	i
	
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
	wave 	SelectedDACWaveList
	string 	panelTitle
	string 	ListOfCheckedDA 	= DC_ControlStatusListString("DA", "Check", panelTitle)
	string 	DAPopUpMenu
	variable 	i 					= 0
	do
		if((str2num(stringfromlist(i,ListOfCheckedDA,";"))) == 1)
			DAPopUpMenu = "Wave_DA_0"+num2str(i)
			popupMenu $DAPopUpMenu mode = SelectedDACWaveList[i], win = $panelTitle
		endif
	i += 1
	while(i < itemsinlist(ListOfCheckedDA))

End

Function TP_StoreDAScale(SelectedDACScale, panelTitle)
	wave 	SelectedDACScale
	string 	panelTitle
	string 	ListOfCheckedDA = DC_ControlStatusListString("DA", "Check", panelTitle)
	string 	DAPopUpMenu
	variable 	i
	
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
	string 	panelTitle

	string 	ListOfCheckedDA 	= DC_ControlStatusListString("DA", "Check", panelTitle)
	string 	DASetVariable
	Wave 	ChannelClampMode 	= GetChannelClampMode(panelTitle)
	variable 	ScalingFactor
	variable 	i
	
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
	wave 	SelectedDACScale
	string 	panelTitle
	string 	ListOfCheckedDA 	= DC_ControlStatusListString("DA", "Check", panelTitle)
	string 	DASetVariable
	variable 	i 					= 0
	do
		if((str2num(stringfromlist(i, ListOfCheckedDA,";"))) == 1)
		DASetVariable = "Scale_DA_0"+num2str(i)
		setvariable $DASetVariable value = _num:SelectedDACScale[i], win = $panelTitle
		endif
	i += 1
	while(i < itemsinlist(ListOfCheckedDA))
end

Function TP_UpdateTestPulseWave(TestPulse, panelTitle) // full path name
	wave 		TestPulse
	string 		panelTitle
	variable 		PulseDuration
	string 		TPGlobalPath = HSU_DataFullFolderPathString(panelTitle) + ":TestPulse"
	//print TPGlobalPath
	variable /g  	$TPGlobalPath + ":Duration"
	NVAR 		GlobalTPDurationVariable 				= $(TPGlobalPath + ":Duration")
	variable /g 	$TPGlobalPath + ":AmplitudeVC"
	NVAR 		GlobalTPAmplitudeVariableVC 			= $(TPGlobalPath + ":AmplitudeVC")
	variable /g 	$TPGlobalPath + ":AmplitudeIC"
	NVAR 		GlobalTPAmplitudeVariableIC 			= $(TPGlobalPath + ":AmplitudeIC")	
	make /o /n = 8 $TPGlobalPath + ":Resistance"
	wave /z 		ITCChanConfigWave = $(HSU_DataFullFolderPathString(panelTitle) + ":ITCChanConfigWave")
	string /g 		$(TPGlobalPath + ":ADChannelList") 	= SCOPE_RefToPullDatafrom2DWave(0, 0, 1, ITCChanConfigWave)
	variable /g $(TPGlobalPath + ":NoOfActiveDA") = DC_NoOfChannelsSelected("da", panelTitle)
				controlinfo /w = $panelTitle SetVar_DataAcq_TPDuration
				PulseDuration 						= (v_value) // duration of the TP in ms
	// PulseDuration = (v_value / 0.005)
	// PulseDuration = (v_value / (DC_ITCMinSamplingInterval(panelTitle) / 1000))
				GlobalTPDurationVariable = (PulseDuration / (DC_ITCMinSamplingInterval(panelTitle) / 1000))
				print "here, tp global dur =", GlobalTPDurationVariable
	
	variable 		PointsInTPWave 					= (2 * PulseDuration) 
				PointsInTPWave 					*= 200
				redimension /n = (PointsInTPWave) TestPulse
				//redimension /n = ((8 * PulseDuration)) TestPulse
				// need to deal with units here to ensure that resistance is calculated correctly
				controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitude // the scaling converts the V-clamp TP to an I-clamp TP as appropriate (i.e. it is not done here)
	variable 		TPamp 							= v_value
				print "TP amp =",v_value

				PulseDuration *= 2
				print "startpoint = ", (0.25*PointsInTPWave)
				TestPulse[round(0.25 * PointsInTPWave), round(0.75 * PointsInTPWave)] = TPamp

 				GlobalTPAmplitudeVariableVC 		= TPamp
				controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitudeIC
				GlobalTPAmplitudeVariableIC = v_value
	//print v_value
End

// TP_UpdateTestPulseWaveChunks  
Function TP_UpdateTestPulseWaveChunks(TestPulse, panelTitle) // Testpulse = full path name; creates wave with enought TPs to fill min wave size(2^17)
	wave 		TestPulse											// this function is only used with MD functions
	string 		panelTitle
	variable 		i 									= 0
	variable 		PulseDuration
	variable 		DataAcqOrTP 						= 1 // test pulse function
	string 		TPGlobalPath 						= HSU_DataFullFolderPathString(panelTitle) + ":TestPulse"
	variable 		MinSampInt 							= DC_ITCMinSamplingInterval(panelTitle)
	variable /g $(TPGlobalPath + ":NoOfActiveDA") = DC_NoOfChannelsSelected("da", panelTitle)
	variable /g  	$TPGlobalPath + ":Duration"
	NVAR 		GlobalTPDurationVariable 				= $(TPGlobalPath + ":Duration")
	variable /g 	$TPGlobalPath + ":AmplitudeVC"
	NVAR 		GlobalTPAmplitudeVariableVC 			= $(TPGlobalPath + ":AmplitudeVC")
	variable /g 	$TPGlobalPath + ":AmplitudeIC"
	NVAR 		GlobalTPAmplitudeVariableIC 			= $(TPGlobalPath + ":AmplitudeIC")	
	make /o /n = 8 $TPGlobalPath + ":Resistance"
	wave /z 		ITCChanConfigWave 					= $(HSU_DataFullFolderPathString(panelTitle) + ":ITCChanConfigWave")
	string /g 		$(TPGlobalPath + ":ADChannelList") 	= SCOPE_RefToPullDatafrom2DWave(0, 0, 1, ITCChanConfigWave)
	variable /g $(TPGlobalPath + ":NoOfActiveDA") = DC_NoOfChannelsSelected("da", panelTitle)
	controlinfo /w 									= $panelTitle SetVar_DataAcq_TPDuration
	variable 		TPDurInms 							= v_value
				//print "tp dur in ms=",tpdurinms
				// print "min samp int = ", minsampint
				PulseDuration 						= (TPDurInms  / (MinSampInt/1000))  // pulse duration in points - should be called pulse points
				// print "pulse points = ", PulseDuration
				GlobalTPDurationVariable 				= PulseDuration
	variable 		ITCdataWaveLength 					= DC_CalculateITCDataWaveLength(panelTitle, DataAcqOrTP) // wave length in points
	
				//redimension /n = (200 * PulseDuration) TestPulse // makes room in wave for 100 TPs
				// need to deal with units here to ensure that resistance is calculated correctly
	controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitude
	variable 		Amplitude 							= v_value
//	print "TP amp =", v_value 
//	print pulseduration
	variable 		Frequency 							= 1000 / (TPDurInms * 2)
	// print "frequency = ",frequency
	variable /g 	$(TPGlobalPath + ":TPPulseCount")
	NVAR 		TPPulseCount 						= $(TPGlobalPath + ":TPPulseCount")
				TPPulseCount						= TP_CreateSquarePulseWave(panelTitle, Frequency, Amplitude, TestPulse)
//	do
//		TestPulse[((PulseDuration / 2) + (i * PulseDuration * 2)), ((Pulseduration + (PulseDuration / 2))  + (i * PulseDuration * 2))] = v_value
//		
//		i += 1
//	while (i < 100)
				GlobalTPAmplitudeVariableVC 			= v_value
				controlinfo /w = $panelTitle SetVar_DataAcq_TPAmplitudeIC
				GlobalTPAmplitudeVariableIC 			= v_value
End


// mV and pA = Mohm
Function TP_ButtonProc_DataAcq_TestPulse(ctrlName) : ButtonControl// Button that starts the test pulse
	String ctrlName
	string panelTitle

	pauseupdate
	setdatafolder root:
//	getwindow kwTopWin activesw
	sprintf panelTitle, "%s" DAP_ReturnPanelName()
	
//	panelTitle = s_value
	variable SearchResult = strsearch(panelTitle, "Oscilloscope", 2)
	if(SearchResult != -1)
		panelTitle = panelTitle[0,SearchResult - 2]//SearchResult+1]
	endif
	
	AbortOnValue DAP_CheckSettings(panelTitle),1
		
	controlinfo /w = $panelTitle SetVar_DataAcq_TPDuration
	if(v_value == 0)
		abort "Give test pulse a duration greater than 0 ms"
	endif
	
	DisableControl(panelTitle, ctrlName)
	
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	
	string CountPath = WavePath + ":count"
	if(exists(CountPath) == 2)
		killvariables $CountPath
	endif

	DAP_UpdateITCMinSampIntDisplay(panelTitle)

	variable DeviceType = HSU_GetDeviceTypeIndex(panelTitle)
	variable DeviceNum  = HSU_GetDeviceNumberIndex(panelTitle)
	
	DAP_StoreTTLState(panelTitle)
	DAP_TurnOffAllTTLs(panelTitle)
	
	if(!GetCheckboxState(panelTitle,"check_Settings_ShowScopeWindow"))
		DAP_SmoothResizePanel(340, panelTitle)
		setwindow $panelTitle +"#oscilloscope", hide = 0
	endif
	
	string TestPulsePath = "root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse"
	make /o /n = 0 $TestPulsePath
	wave TestPulse = $TestPulsePath
	SetScale /P x 0,0.005,"ms", TestPulse
	
	TP_UpdateTPBufferSizeGlobal(panelTitle)
	//print testpulsepath
	TP_UpdateTestPulseWave(TestPulse, panelTitle)
	DM_CreateScaleTPHoldingWave(panelTitle)
	make /free /n = 8 SelectedDACWaveList
	TP_StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
	TP_SelectTestPulseWave(panelTitle)

	make /free /n = 8 SelectedDACScale
	TP_StoreDAScale(SelectedDACScale,panelTitle)
	TP_SetDAScaleToOne(panelTitle)
	
	DC_ConfigureDataForITC(panelTitle, TEST_PULSE_MODE)
	wave TestPulseITC = $WavePath+":TestPulse:TestPulseITC"
	SCOPE_UpdateGraph(TestPulseITC,panelTitle)

	if(GetCheckBoxState(panelTitle, "Check_Settings_BkgTP"))// runs background TP
		ITC_StartBackgroundTestPulse(panelTitle)
	else // runs TP
		ITC_StartTestPulse(DeviceType, DeviceNum, panelTitle)
		if(!GetCheckBoxState(panelTitle, "check_Settings_ShowScopeWindow"))
			DAP_SmoothResizePanel(-340, panelTitle)
			setwindow $panelTitle +"#oscilloscope", hide = 1
		endif
		// killwaves /f TestPulse
	endif
	
	TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
	TP_RestoreDAScale(SelectedDACScale,panelTitle)
	
	// Enable pressure buttons
	//variable headStage = GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage") // determine the selected MIES headstage
	//P_LoadPressureButtonState(panelTitle, headStage)
End

//=============================================================================================
/// @brief  Test pulse button call function
Function TP_ButtonProc_DataAcq_TPMD(ctrlName) : ButtonControl// Button that starts the test pulse
	String ctrlName
	string panelTitle
	sprintf panelTitle, "%s" DAP_ReturnPanelName()
	// pauseupdate
	
	// make sure data folder is correct
	setdatafolder root:
	
	AbortOnValue DAP_CheckSettings(panelTitle),1
	
	// *** need to modify for yoked devices becuase it is only looking at the lead device
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
	
	// @todo Need to modify (killing count global) for yoked devices
	// Kill the global variable Count if it exists - if it was allowed to exist the user would not be able to stop the TP using the space bar
	string CountPath = WavePath + ":count"
	if(exists(CountPath) == 2)
		killvariables $CountPath
	endif
	
	// update TP buffer size global
	TP_UpdateTPBufferSizeGlobal(panelTitle)
	DAP_UpdateITCMinSampIntDisplay(panelTitle)
	
	// determine the device type and device number
	controlinfo /w = $panelTitle popup_MoreSettings_DeviceType
	variable DeviceType = v_value - 1
	controlinfo /w = $panelTitle popup_moreSettings_DeviceNo
	variable DeviceNum = v_value - 1
	
	StartTestPulse(deviceType, deviceNum, panelTitle)
	
	// Enable pressure buttons
	variable headStage = GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage") // determine the selected MIES headstage
	P_LoadPressureButtonState(panelTitle, headStage)

End // Function
//=============================================================================================
/// @brief Updates the global variable n in the TP folder for the device that TP_Delta uses to calculate the mean resistance values
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
/// @brief Calculates peak and steady state resistance simultaneously on all active headstages. Also returns basline Vm.
// The function TPDelta is called by the TP dataaquistion functions
// It updates a wave in the Test pulse folder for the device
// The wave contains the steady state difference between the baseline and the TP response
// In order to allow TP_Delta to be threadsafe it uses global variables (controlinfo is not threadsafe).
Function TP_Delta(panelTitle, InputDataPath) // the input path is the path to the test pulse folder for the device on which the TP is being activated
	string 	panelTitle
	string 	InputDataPath

	string 	StringPath
	sprintf 	StringPath, "%s:Duration" 		InputDataPath
	NVAR 	DurationG 	= $StringPath

	sprintf 	stringPath,  "%s:AmplitudeIC" 	InputDataPath
	NVAR 	AmplitudeIC 	= $StringPath

	sprintf 	stringPath,  "%s:AmplitudeVC"	InputDataPath
	NVAR 	AmplitudeVC	= $StringPath

			AmplitudeIC 	= abs(AmplitudeIC)
			AmplitudeVC	=  abs(AmplitudeVC)

	sprintf 	stringPath,  "%s:TestPulseITC"	InputDataPath
	wave 	TPWave 	= $stringPath

	sprintf 	stringPath,  "%s:n" 			InputDataPath
	NVAR 	RowsInBufferWaves = $stringPath

	variable 	Duration = (durationG * 2 * deltaX(TPWave)) // total duration of TP in ms
	variable 	BaselineSteadyStateStartTime =(0.1 * duration)
	variable 	BaselineSteadyStateEndTime = (0.24 * Duration)
	variable 	TPSSEndTime = (0.74 * duration)
	variable 	TPInstantaneouseOnsetTime = (0.252 * Duration)
	variable 	DimOffsetVar = DimOffset(TPWave, 0)
	variable 	DimDeltaVar = DimDelta(TPWave, 0)
	variable 	PointsInSteadyStatePeriod =  (((BaselineSteadyStateEndTime - DimOffsetVar) / DimDeltaVar) - ((BaselineSteadyStateStartTime - DimOffsetVar) / DimDeltaVar))// (x2pnt(TPWave, BaselineSteadyStateEndTime) - x2pnt(TPWave, BaselineSteadyStateStartTime))
	variable 	BaselineSSStartPoint = ((BaselineSteadyStateStartTime - DimOffsetVar) / DimDeltaVar)
	variable 	BaslineSSEndPoint = BaselineSSStartPoint + PointsInSteadyStatePeriod
	variable 	TPSSEndPoint = ((TPSSEndTime - DimOffsetVar) / DimDeltaVar)
	variable 	TPSSStartPoint = TPSSEndPoint - PointsInSteadyStatePeriod
	variable 	TPInstantaneousOnsetPoint = ((TPInstantaneouseOnsetTime  - DimOffsetVar) / DimDeltaVar)
	sprintf 	StringPath, "%s:NoOfActiveDA" InputDataPath
	NVAR 	NoOfActiveDA = $StringPath
	sprintf 	StringPath, "%s:ClampModeString" InputDataPath
	SVAR 	ClampModeString = $StringPath
//	duplicate chunks of TP wave in regions of interest: Baseline, Onset, Steady state
	duplicate /free /r = [BaselineSSStartPoint, BaslineSSEndPoint][] TPWave, 	BaselineSS
	duplicate /free /r = [TPSSStartPoint, TPSSEndPoint][] TPWave, 			TPSS
	duplicate /free /r = [TPInstantaneousOnsetPoint, (TPInstantaneousOnsetPoint + 50)][] TPWave Instantaneous
//	average the steady state wave
	MatrixOP /free /NTHR = 0 AvgTPSS = sumCols(TPSS)
	avgTPSS /= dimsize(TPSS, 0)

	///@todo rework the matrxOp calls with sumCols to also use ^t (transposition), so that intstead of
	/// a `1xm` wave we get a `m` wave (no columns)
	MatrixOp /FREE /NTHR = 0   AvgBaselineSS = sumCols(BaselineSS)
	AvgBaselineSS /= dimsize(BaselineSS, 0)
	sprintf StringPath, "%s:BaselineSSAvg" InputDataPath
	duplicate /o / r = [][NoOfActiveDA, dimsize(BaselineSS,1) - 1] AvgBaselineSS $StringPath
	wave 	BaselineSSAvg = $StringPath
//	calculate the difference between the steady state and the baseline
	duplicate /free AvgTPSS, AvgDeltaSS
	AvgDeltaSS -= AvgBaselineSS
	AvgDeltaSS = abs(AvgDeltaSS)

//	create wave that will hold instantaneous average
	variable 	i = 0
	variable 	columnsInWave = dimsize(Instantaneous, 1)
	if(columnsInWave == 0)
		columnsInWave = 1
	endif

	make /FREE /n = (1, columnsInWave) InstAvg
	variable 	OneDInstMax
	variable 	OndDBaseline

	do
		matrixOp /Free Instantaneous1d = col(Instantaneous, i + NoOfActiveDA)
		WaveStats/Q/M=1 Instantaneous1d
		OneDInstMax = v_max
		OndDBaseline = AvgBaselineSS[0][i + NoOfActiveDA]

		if(OneDInstMax > OndDBaseline) // handles positive or negative TPs
			Multithread InstAvg[0][i + NoOfActiveDA] = mean(Instantaneous1d, pnt2x(Instantaneous1d, V_maxRowLoc - 1), pnt2x(Instantaneous1d, V_maxRowLoc + 1))
		else
			Multithread InstAvg[0][i + NoOfActiveDA] = mean(Instantaneous1d, pnt2x(Instantaneous1d, V_minRowLoc - 1), pnt2x(Instantaneous1d, V_minRowLoc + 1))
		endif
		i += 1
	while(i < (columnsInWave - NoOfActiveDA))

	Multithread InstAvg -= AvgBaselineSS
	Multithread InstAvg = abs(InstAvg)

	sprintf StringPath, "%s:SSResistance" InputDataPath
	duplicate /o /r = [][NoOfActiveDA, dimsize(TPSS,1) - 1] AvgDeltaSS $StringPath
	wave 	SSResistance = $StringPath
	SetScale/P x TPSSEndTime,1,"ms", SSResistance // this line determines where the value sit on the bottom axis of the oscilloscope

	sprintf StringPath, "%s:InstResistance" InputDataPath
	duplicate /o /r = [][(NoOfActiveDA), (dimsize(TPSS,1) - 1)] InstAvg $StringPath
	wave 	InstResistance = $StringPath
	SetScale/P x TPInstantaneouseOnsetTime,1,"ms", InstResistance

	sprintf StringPath, "%s:ClampModeString" InputDataPath
	SVAR 	ClampModeString = $StringPath
	string 	decimalAdjustment

	i = 0
	do
		if((str2num(stringfromlist(i, ClampModeString, ";"))) == I_CLAMP_MODE)
			// R = V / I
			Multithread SSResistance[0][i] = (AvgDeltaSS[0][i + NoOfActiveDA] / (AmplitudeIC)) * 1000
			Multithread InstResistance[0][i] =  (InstAvg[0][i + NoOfActiveDA] / (AmplitudeIC)) * 1000
		else
			Multithread SSResistance[0][i] = ((AmplitudeVC) / AvgDeltaSS[0][i + NoOfActiveDA]) * 1000
			Multithread InstResistance[0][i] = ((AmplitudeVC) / InstAvg[0][i + NoOfActiveDA]) * 1000
		endif
		i += 1
	while(i < (dimsize(AvgDeltaSS, 1) - NoOfActiveDA))

	if(RowsInBufferWaves > 1)
		variable columns = ((dimsize(TPSS,1)) - NoOfActiveDA)
		if(!columns)
			columns = 1
		endif
		sprintf stringPath,  "%s:TPBaselineBuffer" InputDataPath
		make /o /n = (RowsInBufferWaves, columns) $stringPath // ** does not clear TP buffer wave each time TP is started by the user
		wave /z TPBaselineBuffer = $stringPath // buffer wave for baseline avg - the first row will hold the value of the most recent TP, the waves will be averaged and the value will be passed into what was storing the data for the most recent TP
		matrixop /o TPBaselineBuffer =  rotaterows(TPBaselineBuffer, 1)
		TPBaselineBuffer[0][] = BaselineSSAvg[0][q]
		matrixop /o BaselineSSAvg = sumcols(TPBaselineBuffer)
		BaselineSSAvg /= RowsInBufferWaves // *

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

	TP_RecordTP(panelTitle, BaselineSSAvg, InstResistance, SSResistance, NoOfActiveDA)
	ITC_ApplyAutoBias(panelTitle, BaselineSSAvg, SSResistance)
End

/// Sampling interval in seconds
Constant samplingInterval = 0.2
/// Fitting range in seconds
Constant fittingRange     = 5

/// Units MOhm
static Constant MAX_VALID_RESISTANCE = 50000

/// @brief Records values from  BaselineSSAvg, InstResistance, SSResistance into TPStorage at defined intervals.
///
/// Used for analysis of TP over time.
/// When the TP is initiated by any method, the TP storageWave should be empty
/// If 200 ms have elapsed, or it is the first TP sweep,
/// data from the input waves is transferred to the storage waves.
Function TP_RecordTP(panelTitle, BaselineSSAvg, InstResistance, SSResistance, ADchanCount)
	string 	panelTitle
	wave 	BaselineSSAvg, InstResistance, SSResistance
	variable ADchanCount

	Wave TPStorage = GetTPStorage(panelTitle)
	variable count = GetNumberFromWaveNote(TPStorage, TP_CYLCE_COUNT_KEY)
	variable now   = ticks * TICKS_TO_SECONDS
	variable needsUpdate, numCols

	ASSERT(ADchanCount, "Can not proceed with zero active headstages")

	if(!count)
		Redimension/N=(-1, ADchanCount, -1, -1) TPStorage
		TPStorage = NaN
		// time of the first sweep
		TPStorage[0][][%TimeInSeconds] = now
		needsUpdate = 1
		// % here is used to index the wave using dimension labels, see also
		// DisplayHelpTopic "Example: Wave Assignment and Indexing Using Labels"
	elseif((now - TPStorage[count - 1][0][%TimeInSeconds]) > samplingInterval)
		needsUpdate = 1
	endif

	if(needsUpdate)
		EnsureLargeEnoughWave(TPStorage, minimumSize=count, dimension=ROWS, initialValue=NaN)

		numCols = DimSize(TPStorage, COLS)
		// the columns of the TPStorage wave and the right-hand side waves of the below assignments have to match only for column counts
		// greater than 1. This avoids false error reports with 1D waves vs 2D waves with 0 and 1 column.
		if( numCols > 1 && ( numCols != DimSize(BaselineSSAvg, COLS) || numCols != DimSize(InstResistance, COLS) || numCols != DimSize(SSResistance, COLS) ))
			printf "BUG! The column count of TPStorage (%d), BaselineSSAvg (%d), InstResistance (%d), SSResistance (%d) do not match\r", numCols, DimSize(BaselineSSAvg, COLS), DimSize(InstResistance, COLS), DimSize(SSResistance, COLS)
			return NaN
		endif

		TPStorage[count][][%Vm]                    = BaselineSSAvg[0][q][0]
		TPStorage[count][][%PeakResistance]        = min(InstResistance[0][q][0], MAX_VALID_RESISTANCE)
		TPStorage[count][][%SteadyStateResistance] = min(SSResistance[0][q][0], MAX_VALID_RESISTANCE)
		TPStorage[count][][%TimeInSeconds]         = now
		// ? : is the ternary/conditional operator, see DisplayHelpTopic "? :"
		TPStorage[count][][%DeltaTimeInSeconds]    = count > 0 ? now - TPStorage[0][0][%TimeInSeconds] : 0

		SetNumberInWaveNote(TPStorage, TP_CYLCE_COUNT_KEY, count + 1)
		TP_AnalyzeTP(panelTitle, ADChanCount, TPStorage, count, samplingInterval, fittingRange)
		P_PressureControl(panelTitle) // Call pressure functions
	endif
End

/// @brief Determines the slope of the BaselineSSAvg, InstResistance, SSResistance
/// over a user defined window (in seconds)
///
/// @param panelTitle       locked device string
/// @param ADChanCount      the number of columns that will require slope analysis
/// @param TPStorage        test pulse storage wave
/// @param endRow           last valid row index in TPStorage
/// @param samplingInterval approximate time duration in seconds between data points
/// @param fittingRange     time duration to use for fitting
Function TP_AnalyzeTP(panelTitle, ADChanCount, TPStorage, endRow, samplingInterval, fittingRange)
	string panelTitle
	variable ADChanCount
	Wave/Z TPStorage
	variable endRow, samplingInterval, fittingRange

	variable i, startRow, V_FitQuitReason, V_FitOptions, V_FitError, V_AbortCode

	startRow = endRow - ceil(fittingRange / samplingInterval)

	if(startRow < 0 || startRow >= endRow || !WaveExists(TPStorage) || endRow >= DimSize(TPStorage,ROWS) || ADChanCount > DimSize(TPStorage, COLS))
		return NaN
	endif

	V_FitOptions = 4

	for(i = 0; i < ADChanCount; i += 1)
		try
			V_FitError  = 0
			V_AbortCode = 0
			CurveFit/Q/N=1/NTHR=1/M=0/W=2 line, TPStorage[startRow,endRow][i][%Vm]/X=TPStorage[startRow,endRow][0][3]/D; AbortOnRTE
			Wave W_coef
			TPStorage[startRow,endRow][i][%Vm_Slope] = W_coef[1]

			V_FitError  = 0
			V_AbortCode = 0
			CurveFit/Q/N=1/NTHR=1/M=0/W=2 line, TPStorage[startRow,endRow][i][%PeakResistance]/X=TPStorage[startRow,endRow][0][3]/D; AbortOnRTE
			TPStorage[startRow,endRow][i][%Rpeak_Slope] = W_coef[1]

			V_FitError  = 0
			V_AbortCode = 0
			CurveFit/Q/N=1/NTHR=1/M=0/W=2 line, TPStorage[startRow,endRow][i][%SteadyStateResistance]/X=TPStorage[startRow,endRow][0][3]/D; AbortOnRTE
			TPStorage[startRow,endRow][i][%Rss_Slope] = W_coef[1]
		catch
			/// @todo - add code that let's functions which rely on this data know to wait for good data
			TPStorage[startRow,endRow][i][%Vm_Slope]    = NaN
			TPStorage[startRow,endRow][i][%Rpeak_Slope] = NaN
			TPStorage[startRow,endRow][i][%Rss_Slope]   = NaN
			DEBUGPRINT("Fit was not successfull")
			DEBUGPRINT("V_FitError=", var=V_FitError)
			DEBUGPRINT("V_FitQuitReason=", var=V_FitQuitReason)
			DEBUGPRINT("V_AbortCode=", var=V_AbortCode)
			if(V_AbortCode == -4)
				DEBUGPRINT(GetErrMessage(GetRTError(1)))
			endif
		endtry
	endfor
End

/// @brief Resets the TP storage wave
///
/// - Store the TP record if requested by the user
/// - Clear the wave to start with a pristine storage wave
Function TP_ResetTPStorage(panelTitle)
	string panelTitle

	Wave TPStorage = GetTPStorage(panelTitle)
	variable count = GetNumberFromWaveNote(TPStorage, TP_CYLCE_COUNT_KEY)
	string name

	if(count > 0)
		if(GetCheckBoxState(panelTitle, "check_Settings_TP_SaveTPRecord"))
			dfref dfr = GetDeviceTestPulse(panelTitle)
			Redimension/N=(count, -1, -1, -1) TPStorage
			name = NameOfWave(TPStorage)
			Duplicate/O TPStorage, dfr:$(name + "_" + num2str(ItemsInList(GetListOfWaves(dfr, "^" + name + "_\d+"))))
		endif

		SetNumberInWaveNote(TPStorage, TP_CYLCE_COUNT_KEY, 0)
		SetNumberInWaveNote(TPStorage, AUTOBIAS_LAST_INVOCATION_KEY, 0)
		TPStorage = NaN
	endif
End

/// @brief Updates the global string of clamp modes based on the ad channel associated with the headstage
///
/// In the order of the ADchannels in ITCDataWave - i.e. numerical order
Function/S TP_ClampModeString(panelTitle)
	string 	panelTitle

	string 	WavePath 			= HSU_DataFullFolderPathString(panelTitle)
	string /g $WavePath + ":TestPulse:ADChannelList"
	SVAR 	ADChannelList		= $WavePath + ":TestPulse:ADChannelList"
	wave 	ITCChanConfigWave 	= $WavePath + ":ITCChanConfigWave"
			ADChannelList		= SCOPE_RefToPullDatafrom2DWave(0, 0, 1, ITCChanConfigWave)
	variable 	i 					= 0
	string /g $WavePath + ":TestPulse:ClampModeString"
	SVAR 	ClampModeString 	= $WavePath + ":TestPulse:ClampModeString"
			ClampModeString 	= ""
	
	do
		ClampModeString += (num2str(AI_MIESHeadstageMode(panelTitle, TP_HeadstageUsingADC(panelTitle, str2num(stringfromlist(i,ADChannelList, ";"))))) + ";")
		i += 1
	while(i < itemsinlist(ADChannelList))

	return ClampModeString
End

///@brief Find the headstage using a particular AD channel
Function TP_HeadstageUsingADC(panelTitle, AD)
	string panelTitle

	variable AD

	Wave ChanAmpAssign = GetChanAmpAssign(panelTitle)
	variable i, entries

	entries = DimSize(ChanAmpAssign, COLS)
	for(i=0; i < entries; i+=1)
		if(ChanAmpAssign[2][i] == AD)
			return i
		endif
	endfor

	DEBUGPRINT("Could not find headstage for AD channel", var = AD)

	return NaN
End

///@brief Find the headstage using a particular DA channel
Function TP_HeadstageUsingDAC(panelTitle, DA)
	string 	panelTitle
	variable DA

	Wave ChanAmpAssign = GetChanAmpAssign(panelTitle)
	variable i, entries

	entries = DimSize(ChanAmpAssign, COLS)
	for(i=0; i < entries; i+=1)
		if(ChanAmpAssign[0][i] == DA)
			return i
		endif
	endfor

	DEBUGPRINT("Could not find headstage for DA channel", var = DA)

	return NaN
End

Function TP_IsBackgrounOpRunning(panelTitle, OpName)
	string 	panelTitle, OpName

	CtrlNamedBackground $OpName, status
	return ( str2num(StringFromList(2, s_info, ";")[4]) != 0 )
End

/// @brief Creates a square pulse wave where the duration of the pulse is equal to what the user inputs. The interpulse interval is twice the pulse duration.
/// The interpulse is twice as long as the pulse to give the cell membrane sufficient time to recover between pulses
Function TP_CreateSquarePulseWave(panelTitle, Frequency, Amplitude, TPWave)
	string 	panelTitle
	variable 	frequency
	variable 	amplitude
	Wave 	TPWave
	variable 	numberOfSquarePulses
	variable  	longestSweepPoints = (((1000 / Frequency) * 2) / 0.005)  * (1 / (DC_ITCMinSamplingInterval(panelTitle) / 0.005))
	//print "longest sweep =", longestSweepPoints
	variable 	exponent = ceil(log(longestSweepPoints)/log(2))
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