#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//this proc gets activated after first trial is already acquired if repeated acquisition is on.
// it looks like the test pulse is always run in the ITI!!! it should be user selectable
Function RepeatedAcquisition(PanelTitle)
string PanelTitle
variable ITI
variable IndexingState
variable i = 0
variable/g Count=0
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	wave TestPulseITC = root:WaveBuilder:SavedStimulusSets:DA:TestPulseITC

	variable TotTrials
	
	controlinfo/w=$panelTitle popup_MoreSettings_DeviceType
	variable DeviceType=v_value-1
	controlinfo/w=$panelTitle popup_moreSettings_DeviceNo
	variable DeviceNum=v_value-1
	
	controlinfo/w=$panelTitle valdisp_DataAcq_SweepsInSet
	TotTrials=v_value
	controlinfo/w=$panelTitle SetVar_DataAcq_Repeats
	TotTrials=TotTrials*v_value
	Count+=1
	
	ValDisplay valdisp_DataAcq_TrialsCountdown win=$panelTitle, value=_NUM:(TotTrials-(Count+1))//updates trials remaining in panel
	
	controlinfo/w=$panelTitle SetVar_DataAcq_ITI
	ITI=v_value
	
	controlinfo/w=$panelTitle Check_DataAcq1_Indexing
	IndexingState=v_value
	

		StoreTTLState(panelTitle)//preparations for test pulse begin here
		TurnOffAllTTLs(panelTitle)
		string TestPulsePath = "root:WaveBuilder:SavedStimulusSets:DA:TestPulse"
		make/o/n=0 $TestPulsePath
		wave TestPulse = root:WaveBuilder:SavedStimulusSets:DA:TestPulse
		SetScale/P x 0,0.005,"ms", TestPulse
		AdjustTestPulseWave(TestPulse,panelTitle)

		make/free/n=8 SelectedDACWaveList
		StoreSelectedDACWaves(SelectedDACWaveList,panelTitle)
		SelectTestPulseWave(panelTitle)
	
		make/free/n=8 SelectedDACScale
		StoreDAScale(SelectedDACScale, panelTitle)
		SetDAScaleToOne(panelTitle)
		
		ConfigureDataForITC(PanelTitle)
		ITCOscilloscope(TestPulseITC, panelTitle)
		
		controlinfo/w=$panelTitle check_Settings_ShowScopeWindow
		if(v_value==0)
		SmoothResizePanel(340, panelTitle)
		endif
		StartBackgroundTestPulse(DeviceType, DeviceNum, panelTitle)// modify thes line and the next to make the TP during ITI a user option
		StartBackgroundTimer(ITI, "STOPTestPulse("+"\""+panelTitle+"\""+")", "RepeatedAcquisitionCounter("+num2str(DeviceType)+","+num2str(DeviceNum)+",\""+panelTitle+"\")", "", panelTitle)
		
		ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
		RestoreDAScale(SelectedDACScale,panelTitle)
		//killwaves/f TestPulse

End

Function RepeatedAcquisitionCounter(DeviceType,DeviceNum,panelTitle)
	variable DeviceType,DeviceNum
	string panelTitle
	NVAR Count
	variable TotTrials
	variable ITI
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	wave TestPulseITC = root:WaveBuilder:SavedStimulusSets:DA:TestPulseITC
	wave TestPulse = root:WaveBuilder:SavedStimulusSets:DA:TestPulse

	controlinfo/w=$panelTitle valdisp_DataAcq_SweepsInSet
	TotTrials=v_value
	controlinfo/w=$panelTitle SetVar_DataAcq_Repeats
	TotTrials=(TotTrials*v_value)+1
	Count+=1
	
	controlinfo/w=$panelTitle SetVar_DataAcq_ITI
	ITI=v_value
	ValDisplay valdisp_DataAcq_TrialsCountdown win=$panelTitle, value=_NUM:(TotTrials-(Count+1))// reports trials remaining
	
	controlinfo/w=$panelTitle Check_DataAcq1_Indexing
	If(v_value==1)// if indexing is activated, indexing is applied.
	IndexingDoIt(panelTitle)//IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
	endif
	
	if(Count<TotTrials)
		ConfigureDataForITC(PanelTitle)
		ITCOscilloscope(ITCDataWave, panelTitle)
		
		ControlInfo/w=$panelTitle Check_Settings_BackgrndDataAcq
		If(v_value==0)//No background aquisition
			ITCDataAcq(DeviceType,DeviceNum, panelTitle)
			if(Count<(TotTrials-1)) //prevents test pulse from running after last trial is acquired
				StoreTTLState(panelTitle)
				TurnOffAllTTLs(panelTitle)
				
				string TestPulsePath = "root:WaveBuilder:SavedStimulusSets:DA:TestPulse"
				make/o/n=0 $TestPulsePath
				wave TestPulse = root:WaveBuilder:SavedStimulusSets:DA:TestPulse
				SetScale/P x 0,0.005,"ms", TestPulse
				AdjustTestPulseWave(TestPulse, panelTitle)
				
				make/free/n=8 SelectedDACWaveList
				StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
				SelectTestPulseWave(panelTitle)
			
				make/free/n=8 SelectedDACScale
				StoreDAScale(SelectedDACScale, panelTitle)
				SetDAScaleToOne(panelTitle)
				
				ConfigureDataForITC(PanelTitle)
				ITCOscilloscope(TestPulseITC,panelTitle)
				
				controlinfo/w=$panelTitle check_Settings_ShowScopeWindow
				if(v_value==0)
					SmoothResizePanel(340, panelTitle)
				endif
				
				StartBackgroundTestPulse(DeviceType, DeviceNum, panelTitle)
				//StartBackgroundTimer(ITI, "STOPTestPulse()", "RepeatedAcquisitionCounter()", "", panelTitle)
				StartBackgroundTimer(ITI, "STOPTestPulse("+"\""+panelTitle+"\""+")", "RepeatedAcquisitionCounter("+num2str(DeviceType)+","+num2str(DeviceNum)+",\""+panelTitle+"\")", "", panelTitle)
				
				ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
				RestoreDAScale(SelectedDACScale, panelTitle)
				
				//killwaves/f TestPulse
			else
				//ValDisplay valdisp_DataAcq_TrialsCountdown value=_NUM:0
				print "Repeated acquisition is complete"
				Killvariables Count
				killvariables/z Start, RunTime
				Killstrings/z FunctionNameA, FunctionNameB//, FunctionNameC
			endif
		else //background aquisition is on
				ITCBkrdAcq(DeviceType,DeviceNum, panelTitle)
								
		endif
	endif

End

Function BckgTPwithCallToRptAcqContr(PanelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave TestPulseITC = root:WaveBuilder:SavedStimulusSets:DA:TestPulseITC
	wave TestPulse = root:WaveBuilder:SavedStimulusSets:DA:TestPulse
	variable ITI
	variable TotTrials
	NVAR count	
	
	controlinfo/w=$panelTitle popup_MoreSettings_DeviceType
	variable DeviceType=v_value-1
	controlinfo/w=$panelTitle popup_moreSettings_DeviceNo
	variable DeviceNum=v_value-1
	
	controlinfo/w=$panelTitle SetVar_DataAcq_TotTrial
	TotTrials=v_value
	controlinfo/w=$panelTitle SetVar_DataAcq_ITI
	ITI=v_value
			
			if(Count<(TotTrials-1))
				StoreTTLState(panelTitle)
				TurnOffAllTTLs(panelTitle)
				
				string TestPulsePath = "root:WaveBuilder:SavedStimulusSets:DA:TestPulse"
				make/o/n=0 $TestPulsePath
				wave TestPulse = root:WaveBuilder:SavedStimulusSets:DA:TestPulse
				SetScale/P x 0,0.005,"ms", TestPulse
				AdjustTestPulseWave(TestPulse, panelTitle)
				
				make/free/n=8 SelectedDACWaveList
				StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
				SelectTestPulseWave(panelTitle)
			
				make/free/n=8 SelectedDACScale
				StoreDAScale(SelectedDACScale, panelTitle)
				SetDAScaleToOne(panelTitle)
				
				ConfigureDataForITC(panelTitle)
				ITCOscilloscope(TestPulseITC, panelTitle)
				
				controlinfo/w=$panelTitle check_Settings_ShowScopeWindow
				if(v_value==0)
					SmoothResizePanel(340, panelTitle)
				endif
				
				StartBackgroundTestPulse(DeviceType, DeviceNum, panelTitle)
				StartBackgroundTimer(ITI, "STOPTestPulse()", "RepeatedAcquisitionCounter()", "", panelTitle)
				
				ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
				RestoreDAScale(SelectedDACScale, panelTitle)
				
				killwaves/f TestPulse
			else
				print "Repeated acquisition is complete"
				Killvariables Count
				killvariables/z Start, RunTime
				Killstrings/z FunctionNameA, FunctionNameB//, FunctionNameC
			endif
End



