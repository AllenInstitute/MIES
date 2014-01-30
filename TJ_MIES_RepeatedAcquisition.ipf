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
	wave TestPulseITC = $WavePath+":TestPulse:TestPulseITC"
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
		wave TestPulse = $TestPulsePath
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
			setwindow $panelTitle +"#oscilloscope", hide = 0
		endif
		StartBackgroundTestPulse(DeviceType, DeviceNum, panelTitle)// modify thes line and the next to make the TP during ITI a user option
		StartBackgroundTimer(ITI, "STOPTestPulse(\""+panelTitle+"\")", "RepeatedAcquisitionCounter("+num2str(DeviceType)+","+num2str(DeviceNum)+",\""+panelTitle+"\")", "", panelTitle)
		
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
	wave TestPulseITC = $WavePath+":TestPulse:TestPulseITC"
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
		//print "active set count "+num2str(activesetcount)
		if(activeSetcount==0)//mod(Count,v_value)==0)
			controlinfo/w=$panelTitle Check_DataAcq1_IndexingLocked
			if(v_value==1)//indexing is locked
				print "Index Step taken"
				IndexingDoIt(panelTitle)//IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
			endif	

			valdisplay valdisp_DataAcq_SweepsActiveSet win=$panelTitle, value=_NUM:Index_MaxNoOfSweeps(PanelTitle,1)
			controlinfo/w=$panelTitle valdisp_DataAcq_SweepsActiveSet
			activeSetCount=v_value
			controlinfo/w=$panelTitle SetVar_DataAcq_SetRepeats// the active set count is multiplied by the times the set is to repeated
			ActiveSetCount*=v_value
		endif
		
		controlinfo/w=$panelTitle Check_DataAcq1_IndexingLocked
		if(v_value==0)// indexing is not locked = channel indexes when set has completed all its steps
			//print "should have indexed independently"
			ApplyUnLockedIndexing(panelTitle, count, 0)
			ApplyUnLockedIndexing(panelTitle, count, 1)
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
					setwindow $panelTitle +"#oscilloscope", hide = 0
				endif
				
				StartBackgroundTestPulse(DeviceType, DeviceNum, panelTitle)
				//StartBackgroundTimer(ITI, "STOPTestPulse()", "RepeatedAcquisitionCounter()", "", panelTitle)
				StartBackgroundTimer(ITI, "STOPTestPulse("+"\""+panelTitle+"\""+")", "RepeatedAcquisitionCounter("+num2str(DeviceType)+","+num2str(DeviceNum)+",\""+panelTitle+"\")", "", panelTitle)
				
				ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
				RestoreDAScale(SelectedDACScale, panelTitle)
				
				//killwaves/f TestPulse
			else
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
	wave TestPulseITC = $WavePath+":TestPulse:TestPulseITC"
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
					setwindow $panelTitle +"#oscilloscope", hide = 0
				endif
				
				StartBackgroundTestPulse(DeviceType, DeviceNum, panelTitle)
				StartBackgroundTimer(ITI, "STOPTestPulse(\""+ panelTitle + "\")", "RepeatedAcquisitionCounter("+num2str(DeviceType)+","+num2str(DeviceNum)+",\""+panelTitle+"\")", "", panelTitle)
				
				ResetSelectedDACWaves(SelectedDACWaveList, panelTitle)
				RestoreDAScale(SelectedDACScale, panelTitle)
				
				//killwaves/f TestPulse
			else
				print "Repeated acquisition is complete"
				Killvariables Count
				killvariables/z Start, RunTime
				Killstrings/z FunctionNameA, FunctionNameB//, FunctionNameC
				killwaves/f TestPulse
			endif
End
//====================================================================================================
Function ApplyUnLockedIndexing(panelTitle, count, DAorTTL)
	string panelTitle
	variable count, DAorTTL
	variable i=0
	string ActivechannelList 
	
	if(DAorTTL==0)
		ActiveChannelList = ControlStatusListString("DA","check",panelTitle)
	endif
	
	if(DAorTTL==1)
		ActiveChannelList = ControlStatusListString("TTL","check",panelTitle)
	endif
	
	do
		if(str2num(stringfromlist(i,ActiveChannelList,";"))==1)
			if(DetIfCountIsAtSetBorder(panelTitle, count, i, DAorTTL)==1)
				IndexSingleChannel(panelTitle, DAorTTL, i)
			endif
		endif
	
	i+=1
	while(i<itemsinlist(ActiveChannelList,";"))
End

Function DetIfCountIsAtSetBorder(panelTitle, count, channelNumber, DAorTTL)
	string panelTitle
	variable count, channelNumber, DAorTTL
	variable AtSetBorder=0
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)// determines ITC device 
	wave DAIndexingStorageWave = $wavePath+":DACIndexingStorageWave"
	wave TTLIndexingStorageWave = $wavePath+":TTLIndexingStorageWave"
	string listOfWaveInPopup, PopUpMenuList, ChannelPopUpMenuName,ChannelTypeName, DAorTTLWavePath, DAorTTLFullWaveName
	variable NoOfTTLs = TotNoOfControlType("check", "TTL", panelTitle)
	variable NoOfDAs = TotNoOfControlType("check", "DA",panelTitle)
	variable i, StepsInSummedSets, ListOffset, TotalListSteps
	
	if(DAorTTL==0)
		ChannelTypeName="DA"
		ListOffset=3
		DAorTTLWavePath= "root:WaveBuilder:SavedStimulusSets:DA:"
	endif
	
	if(DAorTTL==1)
		ChannelTypeName="TTL"
		ListOffset=2
		DAorTTLWavePath= "root:WaveBuilder:SavedStimulusSets:TTL:"
	endif
	
		ChannelPopUpMenuName = "Wave_"+ChannelTypeName+"_0"+num2str(ChannelNumber)
		PopUpMenuList=getuserdata(panelTitle, ChannelPopUpMenuName, "MenuExp")// returns list of waves - does not include none or testpulse
		TotalListSteps=TotalIndexingListSteps(panelTitle, ChannelNumber, DAorTTL)
		
	do
		if(count>TotalListSteps)
			count-=totalListsteps
		endif
	while(count>totalListSteps)
		
		
		if(DAIndexingStorageWave[0][ChannelNumber]<DAIndexingStorageWave[1][ChannelNumber])
			i=0
			if(DAorTTL==0)//DA channel
				do
					StepsInSummedSets+=dimsize($DAorTTLWavePath+stringfromlist((DAIndexingStorageWave[0][ChannelNumber]+i-ListOffset),PopUpMenuList,";"),1)
					//print "steps in summed sets = "+num2str(stepsinsummedsets)
					if(StepsInSummedSets==Count)
						//print "At a Set Border"
						AtSetBorder=1
						return AtSetBorder
					endif
				i+=1
				while(StepsInSummedSets<=Count)
			endif
			i=0
		endif
		
		if(TTLIndexingStorageWave[0][ChannelNumber]<TTLIndexingStorageWave[1][ChannelNumber])
			if(DAorTTL==1)// TTL channel
				do
					StepsInSummedSets+=dimsize($DAorTTLWavePath+stringfromlist((TTLIndexingStorageWave[0][ChannelNumber]+i-ListOffset),PopUpMenuList,";"),1)
					
					if(StepsInSummedSets==Count)
						//print "At a Set Border"
						AtSetBorder=1
						return AtSetBorder
					endif
				i+=1
				while(StepsInSummedSets<=Count)
			endif
		endif
		
		if(DAIndexingStorageWave[0][ChannelNumber]>DAIndexingStorageWave[1][ChannelNumber])// handles end index that is in front of start index in the popup menu list
			i=0
			if(DAorTTL==0)//DA channel
				do
					StepsInSummedSets+=dimsize($DAorTTLWavePath+stringfromlist((DAIndexingStorageWave[0][ChannelNumber]+i-ListOffset),PopUpMenuList,";"),1)
					if(ChannelNumber==0)
					print PopUpMenuList
					print DAIndexingStorageWave[1][ChannelNumber]
					//print "steps in summed sets = "+num2str(stepsinsummedsets)
					endif
					if(StepsInSummedSets==Count)
						print "At a Set Border"
						AtSetBorder=1
						return AtSetBorder
					endif
				i-=1
				while(StepsInSummedSets<=Count)
			endif
			i=0
		endif
		
		if(TTLIndexingStorageWave[0][ChannelNumber]>TTLIndexingStorageWave[1][ChannelNumber])
			if(DAorTTL==1)// TTL channel
				do
					StepsInSummedSets+=dimsize($DAorTTLWavePath+stringfromlist((TTLIndexingStorageWave[0][ChannelNumber]+i-ListOffset),PopUpMenuList,";"),1)
					
					if(StepsInSummedSets==Count)
						//print "At a Set Border"
						AtSetBorder=1
						return AtSetBorder
					endif
				i-=1
				while(StepsInSummedSets<=Count)
			endif
		endif
	return AtSetBorder
End

Function TotalIndexingListSteps(panelTitle, ChannelNumber, DAorTTL)
	string panelTitle
	variable ChannelNumber, DAorTTL
	variable TotalListSteps
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)// determines ITC device 
	wave DAIndexingStorageWave = $wavePath+":DACIndexingStorageWave"
	wave TTLIndexingStorageWave = $wavePath+":TTLIndexingStorageWave"
	string PopUpMenuList, ChannelPopUpMenuName, DAorTTLWavePath, DAorTTLFullWaveName, ChannelTypeName
	variable i, ListOffset
	
	if(DAorTTL==0)
		ChannelTypeName="DA"
		ListOffset=3
		DAorTTLWavePath= "root:WaveBuilder:SavedStimulusSets:DA:"
	endif
	
	if(DAorTTL==1)
		ChannelTypeName="TTL"
		ListOffset=2
		DAorTTLWavePath= "root:WaveBuilder:SavedStimulusSets:TTL:"
	endif

	ChannelPopUpMenuName = "Wave_"+ChannelTypeName+"_0"+num2str(ChannelNumber)
	PopUpMenuList=getuserdata(panelTitle, ChannelPopUpMenuName, "MenuExp")// returns list of waves - does not include none or testpulse
	
	if(DAIndexingStorageWave[0][ChannelNumber]<DAIndexingStorageWave[1][ChannelNumber])
		if(DAorTTL==0)
			do // this do-while loop adjust count based on the number of times the list of sets has cycled
				DAorTTLFullWaveName=DAorTTLWavePath+stringfromlist((DAIndexingStorageWave[0][ChannelNumber]+i-ListOffset),PopUpMenuList,";")
				TotalListSteps+=dimsize($DAorTTLFullWaveName,1)
				i+=1
			while( (i + DAIndexingStorageWave[0][ChannelNumber]) <= DAIndexingStorageWave[1][ChannelNumber] )
		endif
		
		if(DAorTTL==1)
			do // this do-while loop adjust count based on the number of times the list of sets has cycled
				DAorTTLFullWaveName=DAorTTLWavePath+stringfromlist((TTLIndexingStorageWave[0][ChannelNumber]+i-ListOffset),PopUpMenuList,";")
				TotalListSteps+=dimsize($DAorTTLFullWaveName,1)
				i+=1
			while( (i + TTLIndexingStorageWave[0][ChannelNumber]) <= TTLIndexingStorageWave[1][ChannelNumber] )
		endif
	endif
	i=0
	
	if(DAIndexingStorageWave[0][ChannelNumber]>DAIndexingStorageWave[1][ChannelNumber])// end index wave is before start index wave in wave list of popup menu
		if(DAorTTL==0)
			do // this do-while loop adjust count based on the number of times the list of sets has cycled
				DAorTTLFullWaveName=DAorTTLWavePath+stringfromlist((DAIndexingStorageWave[1][ChannelNumber]+i-ListOffset),PopUpMenuList,";")
				TotalListSteps+=dimsize($DAorTTLFullWaveName,1)
				i+=1
			while( (i + DAIndexingStorageWave[1][ChannelNumber]) <= DAIndexingStorageWave[0][ChannelNumber] )
		endif

		if(DAorTTL==1)
			do // this do-while loop adjust count based on the number of times the list of sets has cycled
				DAorTTLFullWaveName=DAorTTLWavePath+stringfromlist((TTLIndexingStorageWave[1][ChannelNumber]+i-ListOffset),PopUpMenuList,";")
				TotalListSteps+=dimsize($DAorTTLFullWaveName,1)
				i+=1
			while( (i + TTLIndexingStorageWave[1][ChannelNumber]) <= TTLIndexingStorageWave[0][ChannelNumber] )
		endif
	endif
	if(channelnumber==0)
	//print "Chan0 total list steps = "+num2str(totalliststeps)
	endif
	
	if(channelnumber==1)
	//print "Chan1 total list steps = "+num2str(totalliststeps)
	endif
	return TotalListSteps
End

Function UnlockedIndexingStepNo(panelTitle, channelNo, DAorTTL, count)
	string paneltitle
	variable channelNo, DAorTTL, count
	variable column, i, StepsInSummedSets, listOffSet, totalListSteps
	string ChannelTypeName, DAorTTLWavePath, ChannelPopUpMenuName,PopUpMenuList
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)// determines ITC device 
	wave DAIndexingStorageWave = $wavePath+":DACIndexingStorageWave"
	wave TTLIndexingStorageWave = $wavePath+":TTLIndexingStorageWave"
	
	if(DAorTTL == 0)
	ChannelTypeName = "DA"
	ListOffset = 3
	DAorTTLWavePath = "root:WaveBuilder:SavedStimulusSets:DA:"
	endif
	
	if(DAorTTL == 1)
	ChannelTypeName = "TTL"
	ListOffset = 2
	DAorTTLWavePath = "root:WaveBuilder:SavedStimulusSets:TTL:"
	endif
	
	TotalListSteps = TotalIndexingListSteps(panelTitle, channelNo, DAorTTL)// Total List steps is all the columns in all the waves defined by the start index and end index waves
	do // do loop resets count if the the count has cycled through the total list steps
		if(count >= TotalListSteps)
		count -= totalListsteps
		endif
	while(count >= totalListSteps)
	//print "totalListSteps = "+num2str(totalListSteps)
	
		ChannelPopUpMenuName = "Wave_"+ChannelTypeName+"_0"+num2str(channelNo)
		PopUpMenuList = getuserdata(panelTitle, ChannelPopUpMenuName, "MenuExp")// returns list of waves - does not include none or testpulse
		i = 0
		
		if((DAIndexingStorageWave[0][channelNo]) < (DAIndexingStorageWave[1][channelNo]))
			if(DAorTTL == 0)//DA channel
				do
					StepsInSummedSets += dimsize($DAorTTLWavePath + stringfromlist((DAIndexingStorageWave[0][channelNo] + i - ListOffset), PopUpMenuList,";"),1)
					//print (DAIndexingStorageWave[1][channelNo]+i-ListOffset)
					//print stringfromlist((DAIndexingStorageWave[1][channelNo]+i-ListOffset),PopUpMenuList,";")
					//print "columns in set = " + num2str(dimsize($DAorTTLWavePath+stringfromlist((DAIndexingStorageWave[0][channelNo]+i-ListOffset),PopUpMenuList,";"),1))
					i += 1
				while(StepsInSummedSets<=Count)
				i-=1
				StepsInSummedSets-=dimsize($DAorTTLWavePath+stringfromlist((DAIndexingStorageWave[0][channelNo]+i-ListOffset),PopUpMenuList,";"),1)
				//print "steps in summed sets = "+num2str(stepsinsummedsets)
			endif
		
			if(DAorTTL==1)//TTL channel
				do
					StepsInSummedSets+=dimsize($DAorTTLWavePath+stringfromlist((TTLIndexingStorageWave[0][channelNo]+i-ListOffset),PopUpMenuList,";"),1)
					i+=1
				while(StepsInSummedSets<=Count)
				i-=1
				StepsInSummedSets-=dimsize($DAorTTLWavePath+stringfromlist((TTLIndexingStorageWave[0][channelNo]+i-ListOffset),PopUpMenuList,";"),1)
				//print "steps in summed sets = "+num2str(stepsinsummedsets)
			endif
		endif
		
		i=0
		if(DAIndexingStorageWave[0][channelNo] > DAIndexingStorageWave[1][channelNo])//  handels the situation where the start set is after the end set on the index list
			if(DAorTTL==0)//DA channel
				do
					StepsInSummedSets+=dimsize($DAorTTLWavePath+stringfromlist((DAIndexingStorageWave[0][channelNo]+i-ListOffset),PopUpMenuList,";"),1)
				//	print (DAIndexingStorageWave[0][channelNo]+i-ListOffset)
				//	print stringfromlist((DAIndexingStorageWave[0][channelNo]+i-ListOffset),PopUpMenuList,";")
				//	print "columns in set = " + num2str(dimsize($DAorTTLWavePath+stringfromlist((DAIndexingStorageWave[0][channelNo]+i-ListOffset),PopUpMenuList,";"),1))			
					i-=1
				while(StepsInSummedSets<=Count)
				i+=1
				StepsInSummedSets-=dimsize($DAorTTLWavePath+stringfromlist((DAIndexingStorageWave[0][channelNo]+i-ListOffset),PopUpMenuList,";"),1)
			//	print "steps in summed sets = "+num2str(stepsinsummedsets)
			endif
		
			if(DAorTTL==1)//TTL channel
				do
					StepsInSummedSets+=dimsize($DAorTTLWavePath+stringfromlist((TTLIndexingStorageWave[0][channelNo]+i-ListOffset),PopUpMenuList,";"),1)
					i-=1
				while(StepsInSummedSets<=Count)
				i+=1
				StepsInSummedSets-=dimsize($DAorTTLWavePath+stringfromlist((TTLIndexingStorageWave[0][channelNo]+i-ListOffset),PopUpMenuList,";"),1)
				//print "steps in summed sets = "+num2str(stepsinsummedsets)
			endif
		endif
		
		column=count-StepsInSummedSets
		return column
end
//====================================================================================================
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

