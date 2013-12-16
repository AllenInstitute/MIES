#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//this proc gets activated after first trial is already acquired if repeated acquisition is on.
// it looks like the test pulse is always run in the ITI!!! it should be user selectable
Function RepeatedAcquisition(PanelTitle)
string PanelTitle
variable ITI
variable IndexingState
variable i = 0
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	wave TestPulseITC = root:WaveBuilder:SavedStimulusSets:DA:TestPulseITC
	string CountPath=WavePath+":Count"
	variable/g $CountPath=0
	NVAR Count=$CountPath
	string ActiveSetCountPath=WavePath+":ActiveSetCount"
	controlinfo/w=$panelTitle valdisp_DataAcq_SweepsActiveSet
	variable/g $ActiveSetCountPath=v_value
	NVAR ActiveSetCount = $ActiveSetCountPath
	controlinfo/w=$panelTitle SetVar_DataAcq_SetRepeats// the active set count is multiplied by the times the set is to repeated
	ActiveSetCount*=v_value
	//ActiveSetCount-=1
	variable TotTrials
	
	controlinfo/w=$panelTitle popup_MoreSettings_DeviceType
	variable DeviceType=v_value-1
	controlinfo/w=$panelTitle popup_moreSettings_DeviceNo
	variable DeviceNum=v_value-1
	
	controlinfo/w=$panelTitle Check_DataAcq_Indexing
	if(v_value==0)
		controlinfo/w=$panelTitle valdisp_DataAcq_SweepsActiveSet
		TotTrials=v_value
		controlinfo/w=$panelTitle SetVar_DataAcq_SetRepeats
		TotTrials=(TotTrials*v_value)//+1
	else
		controlinfo/w=$panelTitle valdisp_DataAcq_SweepsInSet
		TotTrials=v_value
	endif
	
	//controlinfo/w=$panelTitle SetVar_DataAcq_SetRepeats
	//TotTrials=(TotTrials*v_value)+1
	
	//Count+=1
	//ActiveSetCount-=1
	ValDisplay valdisp_DataAcq_TrialsCountdown win=$panelTitle, value=_NUM:(TotTrials-(Count))//updates trials remaining in panel
	
	controlinfo/w=$panelTitle SetVar_DataAcq_ITI
	ITI=v_value
	
	controlinfo/w=$panelTitle Check_DataAcq_Indexing
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
	variable TotTrials
	variable ITI
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	wave TestPulseITC = root:WaveBuilder:SavedStimulusSets:DA:TestPulseITC
	wave TestPulse = root:WaveBuilder:SavedStimulusSets:DA:TestPulse
	string CountPath=WavePath+":Count"
	NVAR Count=$CountPath
	string ActiveSetCountPath=WavePath+":ActiveSetCount"
	NVAR ActiveSetCount=$ActiveSetCountPath
	
	Count+=1
	ActiveSetCount-=1
	
	controlinfo/w=$panelTitle Check_DataAcq_Indexing
	if(v_value==0)
		controlinfo/w=$panelTitle valdisp_DataAcq_SweepsActiveSet
		TotTrials=v_value
		controlinfo/w=$panelTitle SetVar_DataAcq_SetRepeats
		TotTrials=(TotTrials*v_value)//+1
	else
		controlinfo/w=$panelTitle valdisp_DataAcq_SweepsInSet
		TotTrials=v_value
	endif
	//print "TotTrials = "+num2str(tottrials)
	print "count = "+num2str(count)
	//controlinfo/w=$panelTitle SetVar_DataAcq_SetRepeats
	//TotTrials=(TotTrials*v_value)+1
	
	controlinfo/w=$panelTitle SetVar_DataAcq_ITI
	ITI=v_value
	ValDisplay valdisp_DataAcq_TrialsCountdown win=$panelTitle, value=_NUM:(TotTrials-(Count))// reports trials remaining
	
	controlinfo/w=$panelTitle Check_DataAcq_Indexing
	If(v_value==1)// if indexing is activated, indexing is applied.
		if(count==1)
			MakeIndexingStorageWaves(panelTitle)
			StoreStartFinishForIndexing(panelTitle)
		endif
		print "active set count "+num2str(activesetcount)
		if(activeSetcount==0)//mod(Count,v_value)==0)
			controlinfo/w=$panelTitle Check_DataAcq1_IndexingLocked
			if(v_value==1)//indexing is locked
				print "Index Step taken"
				IndexingDoIt(panelTitle)//IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
			endif
			
			if(v_value==0)// indexing is not locked = channel indexes when set has completed all its steps
				print "should have indexed independently"
				variable localCount// is how many steps have been taken on a index cycle (max steps in a index cycle is determined by the longest set on all the active channelss)
				controlinfo/w=$panelTitle valdisp_DataAcq_SweepsActiveSet
				localCount = v_value
				//controlinfo/w=$panelTitle SetVar_DataAcq_SetRepeats
				//localCount*=v_value
				localCount-=ActiveSetCount
				//what da and ttl channels are active
				IndexChannelsWithCompleteSets(PanelTitle, 0, localCount)
				//IndexChannelsWithCompleteSets(PanelTitle, 1, localCount)
				//what set on active da and ttl channels have been stepped through completely once
				
			endif
			valdisplay valdisp_DataAcq_SweepsActiveSet win=$panelTitle, value=_NUM:Index_MaxNoOfSweeps(PanelTitle,1)
			controlinfo/w=$panelTitle valdisp_DataAcq_SweepsActiveSet
			activeSetCount=v_value
			controlinfo/w=$panelTitle SetVar_DataAcq_SetRepeats// the active set count is multiplied by the times the set is to repeated
			ActiveSetCount*=v_value
		endif
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
	string CountPath=WavePath+":Count"
	NVAR Count=$CountPath
		
	controlinfo/w=$panelTitle popup_MoreSettings_DeviceType
	variable DeviceType=v_value-1
	controlinfo/w=$panelTitle popup_moreSettings_DeviceNo
	variable DeviceNum=v_value-1
	
	controlinfo/w=$panelTitle Check_DataAcq_Indexing
	if(v_value==0)
		controlinfo/w=$panelTitle valdisp_DataAcq_SweepsActiveSet
		TotTrials=v_value
		controlinfo/w=$panelTitle SetVar_DataAcq_SetRepeats
		TotTrials=(TotTrials*v_value)//+1
	else
		controlinfo/w=$panelTitle valdisp_DataAcq_SweepsInSet
		TotTrials=v_value
	endif
	
	//controlinfo/w=$panelTitle SetVar_DataAcq_SetRepeats
	//TotTrials=(TotTrials*v_value)+1
	
	controlinfo/w=$panelTitle SetVar_DataAcq_ITI
	ITI=v_value
			
			if(Count<(TotTrials))
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

Function IndexChannelsWithCompleteSets(PanelTitle, DAorTTL, localCount)
	string panelTitle
	variable DAorTTL, localCount
	string ListOfSetStatus = RetrnListOfChanWithCompletSets(PanelTitle, DAorTTL, localCount)
	string channelTypeWaveName, ChannelTypeName
	string ChannelPopUpMenuName
	variable ChannelNumber
	
	if(DAorTTL==0)
	ChannelTypeName="DA"
	endif
	
	if(DAorTTL==1)
	ChannelTypeName="TTL"
	endif
	
	do
		if(str2num(stringfromlist(ChannelNumber,ListOfSetStatus,";"))==1)
			ChannelPopUpMenuName = "Wave_"+ChannelTypeName+"_0"+num2str(ChannelNumber)
			IndexSingleChannel(panelTitle, DAorTTL, ChannelNumber)
		endif
	channelNumber+=1
	while(ChannelNumber<itemsinlist(ListOfSetStatus,";"))
End

Function/T RetrnListOfChanWithCompletSets(PanelTitle, DAorTTL, localCount)
	string panelTitle
	variable DAorTTL, localcount
	string ListOfChanWithCompleteSets=""
	string ChannelTypeName
	string ChannelPopUpMenuName
	string setName
	variable columnsInSet
	string WavePath
	
	if(DAorTTL==0)
	ChannelTypeName="DA"
	WavePath = "root:WaveBuilder:SavedStimulusSets:DA:"
	endif
	
	if(DAorTTL==1)
	ChannelTypeName="TTL"
	WavePath = "root:WaveBuilder:SavedStimulusSets:TTL:"
	endif
	
	string ActivechannelList = ControlStatusListString(ChannelTypeName,"check",panelTitle)
	
	variable ChannelNumber = 0
	
	do
		if(str2num(stringfromlist(ChannelNumber,ActiveChannelList,";"))==1)
		ChannelPopUpMenuName = "Wave_"+ChannelTypeName+"_0"+num2str(ChannelNumber)
		controlinfo/w=$panelTitle $ChannelPopUpMenuName
		setName=WavePath+s_value
		columnsInSet=dimsize($setName, 1)
			if(LocalCount >= columnsInSet)
			ListOfChanWithCompleteSets+="1;"
			else
			ListOfChanWithCompleteSets+="0;"
			endif
		else
		ListOfChanWithCompleteSets+="0;"
		endif
	
	
	ChannelNumber+=1
	While (ChannelNumber<itemsinlist(ActiveChannelList,";"))
	
	return ListOfChanWithCompleteSets
End

active channels

channels with complete sets

ControlStatusListString(ChannelType, ControlType,panelTitle)