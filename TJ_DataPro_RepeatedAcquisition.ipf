#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function RepeatedAcquisition()
variable ITI
variable IndexingState
variable i = 0
variable/g Count=0
wave ITCDataWave, TestPulseITC
variable TotTrials

	controlinfo/w=DataPro_ITC1600 SetVar_DataAcq_TotTrial
	TotTrials=v_value
	ValDisplay valdisp_DataAcq_TrialsCountdown win=DataPro_ITC1600, value=_NUM:(TotTrials-(Count+1))//updates trials remaining in panel
	
	controlinfo/w=DataPro_ITC1600 SetVar_DataAcq_ITI
	ITI=v_value
	
	controlinfo/w=DataPro_ITC1600 Check_DataAcq1_Indexing
	IndexingState=v_value
	

		
		StoreTTLState()//preparations for test pulse begin here
		TurnOffAllTTLs()
		
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
		
		controlinfo/w=DataPro_ITC1600 check_Settings_ShowScopeWindow
		if(v_value==0)
		SmoothResizePanel(340)
		endif
		
		StartBackgroundTestPulse()
		StartBackgroundTimer(ITI, "STOPTestPulse()", "RepeatedAcquisitionCounter()", "")
	
		ResetSelectedDACWaves(SelectedDACWaveList)
		RestoreDAScale(SelectedDACScale)
		killwaves/f TestPulse

End

Function RepeatedAcquisitionCounter(DeviceType,DeviceNum)
variable DeviceType,DeviceNum
NVAR Count
variable TotTrials
variable ITI
wave ITCDataWave, TestPulseITC
	controlinfo/w=DataPro_ITC1600 SetVar_DataAcq_TotTrial
	TotTrials=v_value
	Count+=1
	controlinfo/w=DataPro_ITC1600 SetVar_DataAcq_ITI
	ITI=v_value
	ValDisplay valdisp_DataAcq_TrialsCountdown win=datapro_ITC1600, value=_NUM:(TotTrials-(Count+1))// reports trials remaining
	
	controlinfo/w=DataPro_ITC1600 Check_DataAcq1_Indexing
	If(v_value==1)// if indexing is activated, indexing is applied.
	IndexingDoIt()
	endif
	
	if(Count<TotTrials)
		ConfigureDataForITC()
		ITCOscilloscope(ITCDataWave)
		
		ControlInfo/w=DataPro_ITC1600 Check_Settings_BackgrndDataAcq
		If(v_value==0)//No background aquisition
			ITCDataAcq(DeviceType,DeviceNum)
			if(Count<(TotTrials-1)) //prevents test pulse from running after last trial is acquired
				StoreTTLState()
				TurnOffAllTTLs()
				
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
				
				controlinfo/w=DataPro_ITC1600 check_Settings_ShowScopeWindow
				if(v_value==0)
					SmoothResizePanel(340)
				endif
				
				StartBackgroundTestPulse()
				StartBackgroundTimer(ITI, "STOPTestPulse()", "RepeatedAcquisitionCounter()", "")
				
				ResetSelectedDACWaves(SelectedDACWaveList)
				RestoreDAScale(SelectedDACScale)
				
				killwaves/f TestPulse
			else
				//ValDisplay valdisp_DataAcq_TrialsCountdown value=_NUM:0
				print "Repeated acquisition is complete"
				Killvariables Count
				killvariables/z Start, RunTime
				Killstrings/z FunctionNameA, FunctionNameB//, FunctionNameC
			endif
		else //background aquisition is on
				ITCBkrdAcq(DeviceType,DeviceNum)
								
		endif
	endif

End

Function BckgTPwithCallToRptAcqContr()
	wave TestPulseITC
	variable ITI
	variable TotTrials
	NVAR count	
	controlinfo/w=DataPro_ITC1600 SetVar_DataAcq_TotTrial
	TotTrials=v_value
	controlinfo/w=DataPro_ITC1600 SetVar_DataAcq_ITI
	ITI=v_value
			
			if(Count<(TotTrials-1))
				StoreTTLState()
				TurnOffAllTTLs()
				
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
				
				controlinfo/w=DataPro_ITC1600 check_Settings_ShowScopeWindow
				if(v_value==0)
					SmoothResizePanel(340)
				endif
				
				StartBackgroundTestPulse()
				StartBackgroundTimer(ITI, "STOPTestPulse()", "RepeatedAcquisitionCounter()", "")
				
				ResetSelectedDACWaves(SelectedDACWaveList)
				RestoreDAScale(SelectedDACScale)
				
				killwaves/f TestPulse
			else
				print "Repeated acquisition is complete"
				Killvariables Count
				killvariables/z Start, RunTime
				Killstrings/z FunctionNameA, FunctionNameB//, FunctionNameC
			endif
End


