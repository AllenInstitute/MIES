#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function IDX_MakeIndexingStorageWaves(panelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(panelTitle)// determines ITC device 
	variable NoOfTTLs = DC_TotNoOfControlType("check", "TTL",panelTitle)
	variable NoOfDACs = DC_TotNoOfControlType("check", "DA",panelTitle)
	make /o /n = (4,NoOfTTLs) $WavePath + ":TTLIndexingStorageWave"
	make /o /n = (4,NoOfDACs) $WavePath + ":DACIndexingStorageWave"
End

Function IDX_StoreStartFinishForIndexing(panelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(panelTitle)// determines ITC device 
	wave DACIndexingStorageWave = $wavePath+":DACIndexingStorageWave"
	wave TTLIndexingStorageWave = $wavePath+":TTLIndexingStorageWave"
	variable i 
	variable NoOfTTLs = DC_TotNoOfControlType("check", "TTL",panelTitle)
	variable NoOfDACs = DC_TotNoOfControlType("check", "DA",panelTitle)
	string TTLPopUpNameIndexStart, DACPopUpNameIndexStart, TTLPopUpNameIndexEnd, DACPopUpNameIndexEnd
	
	For(i = 0; i < NoOfDACS; i += 1)
		if(i < 10)
			DACPopUpNameIndexStart = "Wave_DA_0"+num2str(i)
			controlInfo /w = $panelTitle $DACPopUpNameIndexStart
			DACIndexingStorageWave[0][i] = v_value
			DACPopUpNameIndexEnd = "Popup_DA_IndexEnd_0" + num2str(i)
			controlInfo/w = $panelTitle $DACPopUpNameIndexEnd
			DACIndexingStorageWave[1][i] = v_value
		else
			DACPopUpNameIndexStart = "Wave_DA_"+num2str(i)
			controlInfo /w = $panelTitle $DACPopUpNameIndexStart
			DACIndexingStorageWave[0][i] = v_value
			DACPopUpNameIndexEnd = "Popup_DA_IndexEnd_"+num2str(i)
			controlInfo /w =$panelTitle $DACPopUpNameIndexEnd
			DACIndexingStorageWave[1][i] = v_value
		endif
	endfor 
		
	For(i = 0; i < NoOfTTLs; i += 1)
		if(i < 10)
			TTLPopUpNameIndexStart = "Wave_TTL_0"+num2str(i)
			controlInfo /w = $panelTitle $TTLPopUpNameIndexStart
			TTLIndexingStorageWave[0][i] = v_value
			TTLPopUpNameIndexEnd = "Popup_TTL_IndexEnd_0" + num2str(i)
			controlInfo /w = $panelTitle $TTLPopUpNameIndexEnd
			TTLIndexingStorageWave[1][i] = v_value
		else
			TTLPopUpNameIndexStart = "Wave_TTL_"+num2str(i)
			controlInfo /w = $panelTitle $TTLPopUpNameIndexStart
			TTLIndexingStorageWave[0][i] = v_value
			TTLPopUpNameIndexEnd = "Popup_TTL_IndexEnd_" + num2str(i)
			controlInfo /w = $panelTitle $TTLPopUpNameIndexEnd
			TTLIndexingStorageWave[1][i] = v_value
		endif
	endfor
End

Function IDX_IndexingDoIt(panelTitle)// for locked indexing, indexes all active channels at once
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(panelTitle)// determines ITC device 
	wave DACIndexingStorageWave = $wavePath+":DACIndexingStorageWave"
	wave TTLIndexingStorageWave = $wavePath+":TTLIndexingStorageWave"
	variable i 
	variable NoOfTTLs = DC_TotNoOfControlType("check", "TTL", panelTitle)
	variable NoOfDACs = DC_TotNoOfControlType("check", "DA",panelTitle)
	variable CurrentPopUpMenuNo
	string DACPopUpName, TTLPopUpName


	for(i = 0; i < NoOfDACS; i += 1)
		if(DACIndexingStorageWave[1][i] > DACIndexingStorageWave[0][i])
			if(i < 10)
				DACPopUpName = "Wave_DA_0" + num2str(i)
				controlinfo /w = $panelTitle $DACPopUpName
				if(v_value < DACIndexingStorageWave[1][i])
					PopUpMenu $DACPopUpName win = $panelTitle, mode = (v_value + 1)
				else
					PopUpMenu $DACPopUpName win = $panelTitle, mode = DACIndexingStorageWave[0][i]
				endif
			else
				DACPopUpName = "Wave_DA_" + num2str(i)
				controlinfo /w = $panelTitle $DACPopUpName
				if(v_value < DACIndexingStorageWave[1][i])
					PopUpMenu $DACPopUpName win = $panelTitle, mode = (v_value + 1)
				else
					PopUpMenu $DACPopUpName win = $panelTitle, mode = DACIndexingStorageWave[0][i]
				endif
			endif
		endif
		
		if(DACIndexingStorageWave[1][i] < DACIndexingStorageWave[0][i])
			if(i < 10)
				DACPopUpName = "Wave_DA_0" + num2str(i)
				controlinfo /w = $panelTitle $DACPopUpName
				if(v_value > DACIndexingStorageWave[1][i])
					PopUpMenu $DACPopUpName win = $panelTitle, mode = (v_value - 1)
				else
					PopUpMenu $DACPopUpName win = $panelTitle, mode = DACIndexingStorageWave[0][i]
				endif
			else
				DACPopUpName = "Wave_DA_" + num2str(i)
				controlinfo /w = $panelTitle $DACPopUpName
				if(v_value > DACIndexingStorageWave[1][i])
					PopUpMenu $DACPopUpName win = $panelTitle, mode = (v_value - 1)
				else
					PopUpMenu $DACPopUpName win = $panelTitle, mode = DACIndexingStorageWave[0][i]
				endif
			endif
		endif
	endfor
	
	for(i = 0; i < NoOfTTLS; i += 1)
		if(TTLIndexingStorageWave[1][i] > TTLIndexingStorageWave[0][i])
			if(i < 10)
				TTLPopUpName = "Wave_TTL_0"+num2str(i)
				controlinfo /w = $panelTitle $TTLPopUpName
				if(v_value < TTLIndexingStorageWave[1][i])
					PopUpMenu $TTLPopUpName win = $panelTitle, mode = (v_value + 1)
				else
					PopUpMenu $TTLPopUpName win = $panelTitle, mode = TTLIndexingStorageWave[0][i]
				endif
			else
				TTLPopUpName = "Wave_TTL_" + num2str(i)
				controlinfo /w = $panelTitle $TTLPopUpName
				if(v_value < TTLIndexingStorageWave[1][i])
					PopUpMenu $TTLPopUpName win = $panelTitle, mode = (v_value + 1)
				else
					PopUpMenu $TTLPopUpName win = $panelTitle, mode = TTLIndexingStorageWave[0][i]
				endif
			endif
		endif
		
		if(TTLIndexingStorageWave[1][i] < TTLIndexingStorageWave[0][i])
			if(i < 10)
				TTLPopUpName = "Wave_TTL_0" + num2str(i)
				controlinfo /w = $panelTitle $TTLPopUpName
				if(v_value > TTLIndexingStorageWave[1][i])
					PopUpMenu $TTLPopUpName win = $panelTitle, mode = (v_value - 1)
				else
					PopUpMenu $TTLPopUpName win = $panelTitle, mode = TTLIndexingStorageWave[0][i]
				endif
			else
			TTLPopUpName = "Wave_TTL_" + num2str(i)
			controlinfo /w = $panelTitle $TTLPopUpName
				if(v_value > TTLIndexingStorageWave[1][i])
					PopUpMenu $TTLPopUpName win = $panelTitle, mode = (v_value - 1)
				else
					PopUpMenu $TTLPopUpName win = $panelTitle, mode = TTLIndexingStorageWave[0][i]
				endif
			endif
		endif
	endfor
End

Function IDX_IndexSingleChannel(panelTitle, DAorTTL, ChannelNo)// indexes a single channel - used when indexing is unlocked
	string panelTitle
	variable DAorTTL, ChannelNo
	variable i = ChannelNo
	string WavePath = HSU_DataFullFolderPathString(panelTitle)// determines ITC device 
	wave DACIndexingStorageWave = $wavePath + ":DACIndexingStorageWave"
	wave TTLIndexingStorageWave = $wavePath+":TTLIndexingStorageWave"
	string DACPopUpName, TTLPopUpName
	
	if(DAorTTL == 0)
		if(DACIndexingStorageWave[1][i] > DACIndexingStorageWave[0][i])
			if(i < 10)
				DACPopUpName = "Wave_DA_0" + num2str(i)
				controlinfo /w = $panelTitle $DACPopUpName
				if(v_value < DACIndexingStorageWave[1][i])
					PopUpMenu $DACPopUpName win = $panelTitle, mode = (v_value + 1)
				else
					PopUpMenu $DACPopUpName win = $panelTitle, mode = DACIndexingStorageWave[0][i]
				endif
			else
				DACPopUpName = "Wave_DA_" + num2str(i)
				controlinfo /w = $panelTitle $DACPopUpName
				if(v_value < DACIndexingStorageWave[1][i])
					PopUpMenu $DACPopUpName win = $panelTitle, mode = (v_value + 1)
				else
					PopUpMenu $DACPopUpName win = $panelTitle, mode = DACIndexingStorageWave[0][i]
				endif
			endif
		endif
		
		if(DACIndexingStorageWave[1][i] < DACIndexingStorageWave[0][i])
			if(i < 10)
				DACPopUpName = "Wave_DA_0" + num2str(i)
				controlinfo /w = $panelTitle $DACPopUpName
				if(v_value>DACIndexingStorageWave[1][i])
					PopUpMenu $DACPopUpName win = $panelTitle, mode = (v_value - 1)
				else
					PopUpMenu $DACPopUpName win = $panelTitle, mode = DACIndexingStorageWave[0][i]
				endif
			else
				DACPopUpName = "Wave_DA_" + num2str(i)
				controlinfo /w = $panelTitle $DACPopUpName
				if(v_value > DACIndexingStorageWave[1][i])
					PopUpMenu $DACPopUpName win = $panelTitle, mode = (v_value - 1)
				else
					PopUpMenu $DACPopUpName win = $panelTitle, mode = DACIndexingStorageWave[0][i]
				endif
			endif
		endif
	endif
	
	if(DAorTTL == 1)
		if(TTLIndexingStorageWave[1][i] > TTLIndexingStorageWave[0][i])
			if(i < 10)
				TTLPopUpName = "Wave_TTL_0" + num2str(i)
				controlinfo /w = $panelTitle $TTLPopUpName
				if(v_value < TTLIndexingStorageWave[1][i])
					PopUpMenu $TTLPopUpName win = $panelTitle, mode = (v_value + 1)
				else
					PopUpMenu $TTLPopUpName win = $panelTitle, mode = TTLIndexingStorageWave[0][i]
				endif
			else
				TTLPopUpName = "Wave_TTL_" + num2str(i)
				controlinfo /w = $panelTitle $TTLPopUpName
				if(v_value < TTLIndexingStorageWave[1][i])
					PopUpMenu $TTLPopUpName win = $panelTitle, mode = (v_value + 1)
				else
					PopUpMenu $TTLPopUpName win = $panelTitle, mode = TTLIndexingStorageWave[0][i]
				endif
			endif
		endif
		
		if(TTLIndexingStorageWave[1][i] < TTLIndexingStorageWave[0][i])
			if(i < 10)
				TTLPopUpName = "Wave_TTL_0" + num2str(i)
				controlinfo /w = $panelTitle $TTLPopUpName
				if(v_value > TTLIndexingStorageWave[1][i])
					PopUpMenu $TTLPopUpName win = $panelTitle, mode = (v_value - 1)
				else
					PopUpMenu $TTLPopUpName win = $panelTitle, mode = TTLIndexingStorageWave[0][i]
				endif
			else
				TTLPopUpName = "Wave_TTL_" + num2str(i)
				controlinfo /w = $panelTitle $TTLPopUpName
				if(v_value > TTLIndexingStorageWave[1][i])
					PopUpMenu $TTLPopUpName win = $panelTitle, mode = (v_value - 1)
				else
					PopUpMenu $TTLPopUpName win = $panelTitle, mode = TTLIndexingStorageWave[0][i]
				endif
			endif
		endif
	endif
End
//===================================================================================
//NEW INDEXING FUNCTIONS FOR USE WITH 2D SETS
//===================================================================================
//**************NEED TO ADD FUNCTION TO CALCULATE CYCLE STEPS FOR LOCKED INDEXING!! NEED TO TEST WITH 3 OR MORE SETS!!!!*************

Function IDX_MaxSweepsLockedIndexing(panelTitle)// a sum of the largest sets for each indexing step
	string panelTitle
	string DAChannelStatusList = DC_ControlStatusListString("DA", "check",panelTitle)
	string TTLChannelStatusList = DC_ControlStatusListString("TTL", "check",panelTitle)
	variable i = 0
	variable MaxCycleIndexSteps= (IDX_MaxSets(panelTitle)+1)
	variable MaxSteps
	
	do
		MaxSteps+= IDX_StepsInSetWithMaxSweeps(panelTitle,i)
		i += 1
	while(i < MaxCycleIndexSteps)
	
	return MaxSteps
End

Function IDX_StepsInSetWithMaxSweeps(panelTitle,IndexNo)// returns the number of steps in the largest set for a particular index number
	string panelTitle
	variable IndexNo
	string DAChannelStatusList = DC_ControlStatusListString("DA", "check", panelTitle)
	string TTLChannelStatusList = DC_ControlStatusListString("TTL", "check",panelTitle)
	variable MaxSteps = 0, SetSteps
	variable ListStartNo, ListEndNo, ListLength, Index
	string setName
	string SetList
	variable i = 0
	variable ListOffset = 3
	string popMenuIndexStartName, popMenuIndexEndName
	
	do // for DAs
		if((str2num(stringfromlist(i, DAChannelStatusList,";"))) == 1)
			popMenuIndexStartName = "Wave_DA_0" + num2str(i)
			controlinfo /w = $panelTitle $popMenuIndexStartName
			ListStartNo = v_value
			popMenuIndexEndName = "Popup_DA_IndexEnd_0" + num2str(i)
			controlinfo /w = $panelTitle $popMenuIndexEndName
			ListEndNo = v_value
			ListLength = abs(ListStartNo - ListEndNo) + 1
			index = indexNo
			if(listLength <= IndexNo)
				Index = mod(IndexNo, ListLength)
			endif
			
			if((ListStartNo - ListEndNo) > 0)
				index *= -1
			endif
			SetList = getuserdata(panelTitle, "Wave_DA_0" + num2str(i), "menuexp")
			SetName = stringfromlist((ListStartNo+index-listoffset), SetList,";")
			SetSteps = IDX_NumberOfTrialsInSet(panelTitle, SetName, 0)
			MaxSteps = max(MaxSteps, SetSteps)
		endif
		i += 1
	while(i < (itemsinlist(DAChannelStatusList, ";")))
	
	ListOffset = 2
	i = 0
	
	do // for TTLs
		if((str2num(stringfromlist(i, TTLChannelStatusList, ";"))) == 1)
			popMenuIndexStartName = "Wave_TTL_0" + num2str(i)
			controlinfo /w = $panelTitle $popMenuIndexStartName
			ListStartNo = v_value
			popMenuIndexEndName = "Popup_TTL_IndexEnd_0" + num2str(i)
			controlinfo /w = $panelTitle $popMenuIndexEndName
			ListEndNo = v_value
			ListLength = abs(ListStartNo - ListEndNo) + 1
			index = indexNo
		
			if(listLength <= IndexNo)
				Index = mod(IndexNo, ListLength)
			endif
			
			if((ListStartNo - ListEndNo) > 0)
				index *= -1
			endif
			
		SetList = getuserdata(panelTitle, "Wave_TTL_0" + num2str(i), "menuexp")
		SetName = stringfromlist((ListStartNo + index - listoffset), SetList, ";")
		SetSteps = IDX_NumberOfTrialsInSet(panelTitle, SetName, 1)
		MaxSteps = max(MaxSteps, SetSteps)
		endif
		i += 1
	while(i < (itemsinlist(TTLChannelStatusList, ";")))	
	
	return MaxSteps
End

Function IDX_MaxSets(panelTitle)// returns the number of sets on the active channel with the most sets.
	string panelTitle
	string DAChannelStatusList = DC_ControlStatusListString("DA", "check",panelTitle)
	string TTLChannelStatusList = DC_ControlStatusListString("TTL", "check",panelTitle)
	variable MaxSets = 0
	variable ChannelSets
	string popMenuIndexStartName, popMenuIndexEndName
	variable i = 0
	do
		if((str2num(stringfromlist(i, DAChannelStatusList, ";"))) == 1)
			popMenuIndexStartName = "Wave_DA_0" + num2str(i)
			controlinfo /w = $panelTitle $popMenuIndexStartName
			ChannelSets = v_value
			popMenuIndexEndName = "Popup_DA_IndexEnd_0" + num2str(i)
			controlinfo /w = $panelTitle $popMenuIndexEndName
			ChannelSets -= v_value
			ChannelSets = abs(ChannelSets)
			MaxSets = max(MaxSets,ChannelSets)
		endif	
		i += 1
	while(i < (itemsinlist(DAChannelStatusList, ";")))
	
	i = 0
	do
		if((str2num(stringfromlist(i, TTLChannelStatusList, ";"))) == 1)
			popMenuIndexStartName="Wave_TTL_0" + num2str(i)
			controlinfo /w = $panelTitle $popMenuIndexStartName
			ChannelSets = v_value
			popMenuIndexEndName = "Popup_TTL_IndexEnd_0" + num2str(i)
			controlinfo/w=$panelTitle $popMenuIndexEndName
			ChannelSets -= v_value
			ChannelSets = abs(ChannelSets)
			MaxSets = max(MaxSets,ChannelSets)
		endif	
		i += 1
	while(i < (itemsinlist(DAChannelStatusList,";")))
	
	return MaxSets // if the start and end set are the same, this returns 0
End

Function IDX_MaxNoOfSweeps(panelTitle, IndexOverRide)// determine the max number of sweeps in the largest start set on active (checked) DA or TTL channels
// works for unlocked (independent) indexing
	string panelTitle
	variable IndexOverRide// some Functions that call this function only want the max number of steps in the start (active) set, when indexing is on. 1 = over ride ON
	variable MaxNoOfSweeps = 0
	string DAChannelStatusList = DC_ControlStatusListString("DA", "check",panelTitle)
	string TTLChannelStatusList = DC_ControlStatusListString("TTL", "check",panelTitle)
	variable i = 0
 
 	do
		if(str2num(stringfromlist(i, DAChannelStatusList, ";")) == 1)
			MaxNoOfSweeps = max(MaxNoOfSweeps, IDX_NumberOfTrialsAcrossSets(panelTitle, i, 0, IndexOverRide))
		endif
	
		i += 1
	while(i < itemsinlist(DAChannelStatusList,";"))
	
	i = 0
	do
		if(str2num(stringfromlist(i, TTLChannelStatusList, ";")) == 1)
			MaxNoOfSweeps = max(MaxNoOfSweeps, IDX_NumberOfTrialsAcrossSets(panelTitle, i, 1, IndexOverRide))
		endif
	
		i += 1
	while(i < itemsinlist(TTLChannelStatusList, ";"))
	print MaxNoOfSweeps
	return MaxNoOfSweeps
End

Function IDX_NumberOfTrialsAcrossSets(panelTitle, PopUpMenuNumber, DAorTTL, IndexOverRide)// determines the number of trials for a DA or TTL channel
	string panelTitle
	variable PopUpMenuNumber, DAorTTL, IndexOverRide//DA = 0, TTL = 1	
	variable NumberOfTrialsAcrossSets
	variable IndexStart, IndexEnd, ListOffset
	string DAorTTL_cntrlName = "", DAorTTL_indexEndName = "", setname = ""
	string DAorTTLString
	
	if(DAorTTL == 0)// determine control names based on DA or TTL 
		DAorTTL_cntrlName = "Wave_DA_0" + num2str(PopUpMenuNumber)
		DAorTTL_indexEndName = "Popup_DA_IndexEnd_0" + num2str(PopUpMenuNumber)
		ListOffset = 3// accounts for first two options in DA popup menu list
	//	sprintf DAorTTLString, "%s" "DA"
	endif

	if(DAorTTL == 1)
		DAorTTL_cntrlName = "Wave_TTL_0" + num2str(PopUpMenuNumber)
		DAorTTL_indexEndName = "Popup_TTL_IndexEnd_0" + num2str(PopUpMenuNumber)
		ListOffset = 2
	//	sprintf DAorTTLString, "%s" "TTL"
	endif
	
	controlinfo /w = $panelTitle $DAorTTL_cntrlName// check if indexing is activated
	IndexStart = v_value
	
	controlinfo /w = $panelTitle Check_DataAcq_Indexing// checks to if indexing is activated
	if(v_value == 0)
		IndexEnd = indexStart
	else
		controlinfo /w = $panelTitle $DAorTTL_indexEndName
		IndexEnd = v_value 
	endif
	
	If(IndexOverRide == 1)
		IndexEnd = indexStart
	endIF
	
	string setList  = getuserdata(panelTitle, DAorTTL_cntrlName, "menuexp")
	//sprintf setLIst, "%s" WBP_ITCPanelPopUps(0, DAorTTLString) 
	variable i = (min(indexstart, indexend) - ListOffset)
	
	do
		Setname = stringfromlist(i, setList, ";")
		NumberOfTrialsAcrossSets += IDX_NumberOfTrialsInSet(panelTitle, SetName, DAorTTL)
		i += 1
	while(i < (max(indexstart, indexend) - (ListOffset - 1)))
	return NumberOfTrialsAcrossSets

End

Function IDX_NumberOfTrialsInSet(panelTitle, SetName, DAorTTL)// set name is the wave name, does not include wave path
	string panelTitle, SetName
	variable DAorTTL//DA = 0, TTL = 1
	string WavePath 
	
	if(DAorTTL == 0)// to determine location
		WavePath = "root:MIES:WaveBuilder:SavedStimulusSets:DA:" // root:MIES:WaveBuilder:SavedStimulusSets:DA
	endif
	
	if(DAorTTL == 1)
		WavePath = "root:MIES:WaveBuilder:SavedStimulusSets:TTL:"
	endif
	if(stringmatch(setname, "") == 1)
		variable NumberOfTrialsInSet = 0
	else
		string NameOfWaveSelectedInPopUP = WavePath + setName
		NumberOfTrialsInSet = DimSize($NameOfWaveSelectedInPopUP, 1)
	endif
	return NumberOfTrialsInSet
End

Function IDX_ApplyUnLockedIndexing(panelTitle, count, DAorTTL)
	string panelTitle
	variable count, DAorTTL
	variable i=0
	string ActivechannelList 
	
	if(DAorTTL==0)
		ActiveChannelList = DC_ControlStatusListString("DA","check",panelTitle)
	endif
	
	if(DAorTTL==1)
		ActiveChannelList = DC_ControlStatusListString("TTL","check",panelTitle)
	endif
	
	do
		if(str2num(stringfromlist(i,ActiveChannelList,";"))==1)
			if(IDX_DetIfCountIsAtSetBorder(panelTitle, count, i, DAorTTL)==1)
				IDX_IndexSingleChannel(panelTitle, DAorTTL, i)
			endif
		endif
	
	i+=1
	while(i<itemsinlist(ActiveChannelList,";"))
End

Function IDX_TotalIndexingListSteps(panelTitle, ChannelNumber, DAorTTL)
	string panelTitle
	variable ChannelNumber, DAorTTL
	variable TotalListSteps
	string WavePath = HSU_DataFullFolderPathString(panelTitle)// determines ITC device 
	wave DAIndexingStorageWave = $wavePath+":DACIndexingStorageWave"
	wave TTLIndexingStorageWave = $wavePath+":TTLIndexingStorageWave"
	string PopUpMenuList, ChannelPopUpMenuName, DAorTTLWavePath, DAorTTLFullWaveName, ChannelTypeName
	variable i, ListOffset
	
	if(DAorTTL==0)
		ChannelTypeName="DA"
		ListOffset=3
		DAorTTLWavePath= "root:MIES:WaveBuilder:SavedStimulusSets:DA:"
	endif
	
	if(DAorTTL==1)
		ChannelTypeName="TTL"
		ListOffset=2
		DAorTTLWavePath= "root:MIES:WaveBuilder:SavedStimulusSets:TTL:"
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

Function IDX_UnlockedIndexingStepNo(panelTitle, channelNo, DAorTTL, count)
	string paneltitle
	variable channelNo, DAorTTL, count
	variable column, i, StepsInSummedSets, listOffSet, totalListSteps
	string ChannelTypeName, DAorTTLWavePath, ChannelPopUpMenuName,PopUpMenuList
	string WavePath = HSU_DataFullFolderPathString(panelTitle)// determines ITC device 
	wave DAIndexingStorageWave = $wavePath+":DACIndexingStorageWave"
	wave TTLIndexingStorageWave = $wavePath+":TTLIndexingStorageWave"
	
	if(DAorTTL == 0)
	ChannelTypeName = "DA"
	ListOffset = 3
	DAorTTLWavePath = "root:MIES:WaveBuilder:SavedStimulusSets:DA:"
	endif
	
	if(DAorTTL == 1)
	ChannelTypeName = "TTL"
	ListOffset = 2
	DAorTTLWavePath = "root:MIES:WaveBuilder:SavedStimulusSets:TTL:"
	endif
	
	TotalListSteps = IDX_TotalIndexingListSteps(panelTitle, channelNo, DAorTTL)// Total List steps is all the columns in all the waves defined by the start index and end index waves
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
Function IDX_DetIfCountIsAtSetBorder(panelTitle, count, channelNumber, DAorTTL)
	string panelTitle
	variable count, channelNumber, DAorTTL
	variable AtSetBorder=0
	string WavePath = HSU_DataFullFolderPathString(panelTitle)// determines ITC device 
	wave DAIndexingStorageWave = $wavePath+":DACIndexingStorageWave"
	wave TTLIndexingStorageWave = $wavePath+":TTLIndexingStorageWave"
	string listOfWaveInPopup, PopUpMenuList, ChannelPopUpMenuName,ChannelTypeName, DAorTTLWavePath, DAorTTLFullWaveName
	variable NoOfTTLs = DC_TotNoOfControlType("check", "TTL", panelTitle)
	variable NoOfDAs = DC_TotNoOfControlType("check", "DA",panelTitle)
	variable i, StepsInSummedSets, ListOffset, TotalListSteps
	
	if(DAorTTL==0)
		ChannelTypeName="DA"
		ListOffset=3
		DAorTTLWavePath= "root:MIES:WaveBuilder:SavedStimulusSets:DA:"
	endif
	
	if(DAorTTL==1)
		ChannelTypeName="TTL"
		ListOffset=2
		DAorTTLWavePath= "root:MIES:WaveBuilder:SavedStimulusSets:TTL:"
	endif
	
		ChannelPopUpMenuName = "Wave_"+ChannelTypeName+"_0"+num2str(ChannelNumber)
		PopUpMenuList=getuserdata(panelTitle, ChannelPopUpMenuName, "MenuExp")// returns list of waves - does not include none or testpulse
		TotalListSteps=IDX_TotalIndexingListSteps(panelTitle, ChannelNumber, DAorTTL)
		
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
					//print PopUpMenuList
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

Function IDX_IndxChannWithCompleteSets(panelTitle, DAorTTL, localCount) // #####FUNCTION NOT IN USE
	string panelTitle
	variable DAorTTL, localCount
	string ListOfSetStatus = IDX_RetrnLstOfChanWthComplSets(panelTitle, DAorTTL, localCount)
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
			IDX_IndexSingleChannel(panelTitle, DAorTTL, ChannelNumber)
		endif
	channelNumber+=1
	while(ChannelNumber<itemsinlist(ListOfSetStatus,";"))
End

Function/T IDX_RetrnLstOfChanWthComplSets(panelTitle, DAorTTL, localCount) // #####FUNCTION NOT IN USE
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
	WavePath = "root:MIES:WaveBuilder:SavedStimulusSets:DA:"
	endif
	
	if(DAorTTL==1)
	ChannelTypeName="TTL"
	WavePath = "root:MIES:WaveBuilder:SavedStimulusSets:TTL:"
	endif
	
	string ActivechannelList = DC_ControlStatusListString(ChannelTypeName,"check",panelTitle)
	
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

