#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//this proc gets activated after first trial is already acquired if repeated acquisition is on.
// it looks like the test pulse is always run in the ITI!!! it should be user selectable
Function RA_Start(PanelTitle)
	string PanelTitle
	variable ITI
	variable IndexingState
	variable i = 0
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	wave TestPulseITC = $WavePath+":TestPulse:TestPulseITC"
	string CountPath = WavePath+":Count"
	variable/g $CountPath=0
	NVAR Count = $CountPath
	string ActiveSetCountPath=WavePath+":ActiveSetCount"
	controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
	variable /g $ActiveSetCountPath=v_value
	NVAR ActiveSetCount = $ActiveSetCountPath
	controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats// the active set count is multiplied by the times the set is to repeated
	ActiveSetCount *= v_value
	//ActiveSetCount -= 1
	variable TotTrials
	
	controlinfo /w = $panelTitle popup_MoreSettings_DeviceType
	variable DeviceType = v_value - 1
	controlinfo /w = $panelTitle popup_moreSettings_DeviceNo
	variable DeviceNum = v_value - 1
	
	controlinfo /w = $panelTitle Check_DataAcq_Indexing
	if(v_value == 0)
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
		TotTrials = v_value
		controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
		TotTrials = (TotTrials * v_value)//+1
	else
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsInSet
		TotTrials = v_value
	endif
	
	//controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
	//TotTrials = (TotTrials * v_value) + 1
	
	//Count += 1
	//ActiveSetCount -= 1
	ValDisplay valdisp_DataAcq_TrialsCountdown win = $panelTitle, value = _NUM:(TotTrials - (Count))//updates trials remaining in panel
	
	controlinfo /w = $panelTitle SetVar_DataAcq_ITI
	ITI = v_value
	
	controlinfo /w = $panelTitle Check_DataAcq_Indexing
	IndexingState = v_value
	

		DAP_StoreTTLState(panelTitle)//preparations for test pulse begin here
		DAP_TurnOffAllTTLs(panelTitle)
		string TestPulsePath = "root:WaveBuilder:SavedStimulusSets:DA:TestPulse"
		make /o /n = 0 $TestPulsePath
		wave TestPulse = $TestPulsePath
		SetScale /P x 0, 0.005, "ms", TestPulse
		TP_UpdateTestPulseWave(TestPulse,panelTitle)

		make /free /n = 8 SelectedDACWaveList
		TP_StoreSelectedDACWaves(SelectedDACWaveList,panelTitle)
		TP_SelectTestPulseWave(panelTitle)
	
		make /free /n = 8 SelectedDACScale
		TP_StoreDAScale(SelectedDACScale, panelTitle)
		TP_SetDAScaleToOne(panelTitle)
		
		DC_ConfigureDataForITC(PanelTitle)
		SCOPE_UpdateGraph(TestPulseITC, panelTitle)
		
		controlinfo /w = $panelTitle check_Settings_ShowScopeWindow
		if(v_value == 0)
			DAP_SmoothResizePanel(340, panelTitle)
			setwindow $panelTitle + "#oscilloscope", hide = 0
		endif
		ITC_StartBackgroundTestPulse(DeviceType, DeviceNum, panelTitle)// modify thes line and the next to make the TP during ITI a user option
		ITC_StartBackgroundTimer(ITI, "ITC_STOPTestPulse(\"" + panelTitle + "\")", "RA_Counter(" + num2str(DeviceType) + "," + num2str(DeviceNum) + ",\"" + panelTitle + "\")", "", panelTitle)
		
		TP_ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
		TP_RestoreDAScale(SelectedDACScale,panelTitle)
		//killwaves /f TestPulse

End

Function RA_Counter(DeviceType,DeviceNum,panelTitle)
	variable DeviceType,DeviceNum
	string panelTitle
	variable TotTrials
	variable ITI
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	wave TestPulseITC = $WavePath + ":TestPulse:TestPulseITC"
	wave TestPulse = root:WaveBuilder:SavedStimulusSets:DA:TestPulse
	string CountPath = WavePath + ":Count"
	NVAR Count = $CountPath
	string ActiveSetCountPath = WavePath + ":ActiveSetCount"
	NVAR ActiveSetCount = $ActiveSetCountPath
	
	Count += 1
	ActiveSetCount -= 1
	
	controlinfo/w = $panelTitle Check_DataAcq_Indexing
	if(v_value == 0)
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
		TotTrials = v_value
		controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
		TotTrials = (TotTrials * v_value)//+1
	else
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsInSet
		TotTrials = v_value
	endif
	//print "TotTrials = " + num2str(tottrials)
	print "count = " + num2str(count)
	//controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
	//TotTrials = (TotTrials * v_value) + 1
	
	controlinfo /w = $panelTitle SetVar_DataAcq_ITI
	ITI = v_value
	ValDisplay valdisp_DataAcq_TrialsCountdown win = $panelTitle, value = _NUM:(TotTrials - (Count))// reports trials remaining
	
	controlinfo /w = $panelTitle Check_DataAcq_Indexing
	If(v_value == 1)// if indexing is activated, indexing is applied.
		if(count == 1)
			IDX_MakeIndexingStorageWaves(panelTitle)
			IDX_StoreStartFinishForIndexing(panelTitle)
		endif
		//print "active set count "+num2str(activesetcount)
		if(activeSetcount == 0)//mod(Count,v_value)==0)
			controlinfo /w = $panelTitle Check_DataAcq1_IndexingLocked
			if(v_value == 1)//indexing is locked
				print "Index Step taken"
				IDX_IndexingDoIt(panelTitle)//IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
			endif	

			valdisplay valdisp_DataAcq_SweepsActiveSet win=$panelTitle, value=_NUM:IDX_MaxNoOfSweeps(PanelTitle,1)
			controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
			activeSetCount = v_value
			controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats// the active set count is multiplied by the times the set is to repeated
			ActiveSetCount *= v_value
		endif
		
		controlinfo /w = $panelTitle Check_DataAcq1_IndexingLocked
		if(v_value == 0)// indexing is not locked = channel indexes when set has completed all its steps
			//print "should have indexed independently"
			IDX_ApplyUnLockedIndexing(panelTitle, count, 0)
			IDX_ApplyUnLockedIndexing(panelTitle, count, 1)
		endif
	endif
	
	if(Count < TotTrials)
		DC_ConfigureDataForITC(PanelTitle)
		SCOPE_UpdateGraph(ITCDataWave, panelTitle)
		
		ControlInfo /w = $panelTitle Check_Settings_BackgrndDataAcq
		If(v_value == 0)//No background aquisition
			ITC_DataAcq(DeviceType,DeviceNum, panelTitle)
			if(Count < (TotTrials - 1)) //prevents test pulse from running after last trial is acquired
				DAP_StoreTTLState(panelTitle)
				DAP_TurnOffAllTTLs(panelTitle)
				
				string TestPulsePath = "root:WaveBuilder:SavedStimulusSets:DA:TestPulse"
				make /o /n = 0 $TestPulsePath
				wave TestPulse = root:WaveBuilder:SavedStimulusSets:DA:TestPulse
				SetScale /P x 0, 0.005, "ms", TestPulse
				TP_UpdateTestPulseWave(TestPulse, panelTitle)
				
				make /free /n = 8 SelectedDACWaveList
				TP_StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
				TP_SelectTestPulseWave(panelTitle)
			
				make /free /n = 8 SelectedDACScale
				TP_StoreDAScale(SelectedDACScale, panelTitle)
				TP_SetDAScaleToOne(panelTitle)
				
				DC_ConfigureDataForITC(PanelTitle)
				SCOPE_UpdateGraph(TestPulseITC,panelTitle)
				
				controlinfo /w = $panelTitle check_Settings_ShowScopeWindow
				if(v_value == 0)
					DAP_SmoothResizePanel(340, panelTitle)
					setwindow $panelTitle + "#oscilloscope", hide = 0
				endif
				
				ITC_StartBackgroundTestPulse(DeviceType, DeviceNum, panelTitle)
				//ITC_StartBackgroundTimer(ITI, "ITC_STOPTestPulse()", "RA_Counter()", "", panelTitle)
				ITC_StartBackgroundTimer(ITI, "ITC_STOPTestPulse(" + "\"" + panelTitle+"\"" + ")", "RA_Counter(" + num2str(DeviceType) + "," + num2str(DeviceNum) + ",\"" + panelTitle + "\")", "", panelTitle)
				
				TP_ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
				TP_RestoreDAScale(SelectedDACScale, panelTitle)
				
				//killwaves/f TestPulse
			else
				print "Repeated acquisition is complete"
				Killvariables Count
				killvariables /z Start, RunTime
				Killstrings /z FunctionNameA, FunctionNameB//, FunctionNameC
			endif
		else //background aquisition is on
				ITC_BkrdDataAcq(DeviceType,DeviceNum, panelTitle)					
		endif
	endif
End

Function RA_BckgTPwithCallToRACounter(PanelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave TestPulseITC = $WavePath+":TestPulse:TestPulseITC"
	wave TestPulse = root:WaveBuilder:SavedStimulusSets:DA:TestPulse
	variable ITI
	variable TotTrials
	string CountPath = WavePath + ":Count"
	NVAR Count = $CountPath
		
	controlinfo /w = $panelTitle popup_MoreSettings_DeviceType
	variable DeviceType = v_value - 1
	controlinfo /w = $panelTitle popup_moreSettings_DeviceNo
	variable DeviceNum = v_value - 1
	
	controlinfo /w = $panelTitle Check_DataAcq_Indexing
	if(v_value == 0)
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet
		TotTrials = v_value
		controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
		TotTrials = (TotTrials * v_value)//+1
	else
		controlinfo /w = $panelTitle valdisp_DataAcq_SweepsInSet
		TotTrials = v_value
	endif
	
	//controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats
	//TotTrials = (TotTrials * v_value) + 1
	
	controlinfo /w = $panelTitle SetVar_DataAcq_ITI
	ITI = v_value
			
			if(Count < (TotTrials))
				DAP_StoreTTLState(panelTitle)
				DAP_TurnOffAllTTLs(panelTitle)
				
				string TestPulsePath = "root:WaveBuilder:SavedStimulusSets:DA:TestPulse"
				make /o /n = 0 $TestPulsePath
				wave TestPulse = root:WaveBuilder:SavedStimulusSets:DA:TestPulse
				SetScale/P x 0, 0.005, "ms", TestPulse
				TP_UpdateTestPulseWave(TestPulse, panelTitle)
				
				make /free /n = 8 SelectedDACWaveList
				TP_StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
				TP_SelectTestPulseWave(panelTitle)
			
				make /free /n = 8 SelectedDACScale
				TP_StoreDAScale(SelectedDACScale, panelTitle)
				TP_SetDAScaleToOne(panelTitle)
				
				DC_ConfigureDataForITC(panelTitle)
				SCOPE_UpdateGraph(TestPulseITC, panelTitle)
				
				controlinfo /w = $panelTitle check_Settings_ShowScopeWindow
				if(v_value == 0)
					DAP_SmoothResizePanel(340, panelTitle)
					setwindow $panelTitle + "#oscilloscope", hide = 0
				endif
				
				ITC_StartBackgroundTestPulse(DeviceType, DeviceNum, panelTitle)
				ITC_StartBackgroundTimer(ITI, "ITC_STOPTestPulse(\"" + panelTitle + "\")", "RA_Counter(" + num2str(DeviceType) + "," + num2str(DeviceNum) + ",\"" + panelTitle + "\")", "", panelTitle)
				
				TP_ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
				TP_RestoreDAScale(SelectedDACScale, panelTitle)
				
				//killwaves/f TestPulse
			else
				print "Repeated acquisition is complete"
				Killvariables Count
				killvariables /z Start, RunTime
				Killstrings /z FunctionNameA, FunctionNameB//, FunctionNameC
				killwaves /f TestPulse
			endif
End
//====================================================================================================