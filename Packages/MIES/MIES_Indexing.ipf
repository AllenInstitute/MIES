#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_Indexing.ipf
/// @brief __IDX__ Indexing related functionality

/// @brief Returns a list of the status of the checkboxes specified by ChannelType and ControlType
///
/// @deprecated use @ref DC_ControlStatusWave() instead
///
/// @param ChannelType  one of DA, AD, or TTL
/// @param ControlType  currently restricted to "Check"
/// @param panelTitle   panel title
static Function/S IDX_ControlStatusListString(ChannelType, ControlType, panelTitle)
	String ChannelType, panelTitle
	string ControlType

	variable TotalPossibleChannels = GetNumberFromType(str=channelType)

	String ControlStatusList = ""
	String ControlName
	variable i

	i=0
	do
		sprintf ControlName, "%s_%s_%.2d", ControlType, ChannelType, i
		ControlInfo /w = $panelTitle $ControlName
		ControlStatusList = AddlistItem(num2str(v_value), ControlStatusList, ";",i)
		i+=1
	while(i <= (TotalPossibleChannels - 1))

	return ControlStatusList
End

Function IDX_StoreStartFinishForIndexing(panelTitle)
	string panelTitle

	variable i
	string ctrl

	WAVE DACIndexingStorageWave = GetDACIndexingStorageWave(panelTitle)
	WAVE TTLIndexingStorageWave = GetTTLIndexingStorageWave(panelTitle)
	
	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		ctrl = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		ControlInfo/W=$panelTitle $ctrl
		DACIndexingStorageWave[0][i] = V_Value

		ctrl = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
		ControlInfo/W=$panelTitle $ctrl
		DACIndexingStorageWave[1][i] = V_Value + 1 // added " +1 " because indexing end no longer has test pulse listed

		ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
		ControlInfo/W=$panelTitle $ctrl
		TTLIndexingStorageWave[0][i] = V_Value

		ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
		ControlInfo/W=$panelTitle $ctrl
		TTLIndexingStorageWave[1][i] = V_Value
	endfor 
End

/// @brief Resets the selected set popupmenus stored by #IDX_StoreStartFinishForIndexing
Function IDX_ResetStartFinishForIndexing(panelTitle)
	string panelTitle

	variable i
	string ctrl

	WAVE DACIndexingStorageWave = GetDACIndexingStorageWave(panelTitle)
	WAVE TTLIndexingStorageWave = GetTTLIndexingStorageWave(panelTitle)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		ctrl = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		SetPopupMenuIndex(paneltitle, ctrl, DACIndexingStorageWave[0][i] - 1)

		ctrl = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
		SetPopupMenuIndex(paneltitle, ctrl, DACIndexingStorageWave[1][i] - 2)

		ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
		SetPopupMenuIndex(paneltitle, ctrl, TTLIndexingStorageWave[0][i] - 1)

		ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
		SetPopupMenuIndex(paneltitle, ctrl, TTLIndexingStorageWave[1][i] - 1)
	endfor
End

/// @brief Locked indexing, indexes all active channels at once
Function IDX_IndexingDoIt(panelTitle)
	string panelTitle

	WAVE DACIndexingStorageWave = GetDACIndexingStorageWave(panelTitle)
	WAVE TTLIndexingStorageWave = GetTTLIndexingStorageWave(panelTitle)
	variable i
	string ctrl

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		ctrl = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)

		if(DACIndexingStorageWave[1][i] > DACIndexingStorageWave[0][i])
			ControlInfo/W=$panelTitle $ctrl
			if(v_value < DACIndexingStorageWave[1][i])
				PopUpMenu $ctrl win = $panelTitle, mode = (v_value + 1)
			else
				PopUpMenu $ctrl win = $panelTitle, mode = DACIndexingStorageWave[0][i]
			endif
		elseif(DACIndexingStorageWave[1][i] < DACIndexingStorageWave[0][i])
			ControlInfo/W=$panelTitle $ctrl
			if(v_value > DACIndexingStorageWave[1][i])
				PopUpMenu $ctrl win = $panelTitle, mode = (v_value - 1)
			else
				PopUpMenu $ctrl win = $panelTitle, mode = DACIndexingStorageWave[0][i]
			endif
		else
			// do nothing
		endif
	endfor

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
		if(TTLIndexingStorageWave[1][i] > TTLIndexingStorageWave[0][i])
			ControlInfo /w = $panelTitle $ctrl
			if(v_value < TTLIndexingStorageWave[1][i])
				PopUpMenu $ctrl win = $panelTitle, mode = (v_value + 1)
			else
				PopUpMenu $ctrl win = $panelTitle, mode = TTLIndexingStorageWave[0][i]
			endif
		elseif(TTLIndexingStorageWave[1][i] < TTLIndexingStorageWave[0][i])
			ControlInfo /w = $panelTitle $ctrl
			if(v_value > TTLIndexingStorageWave[1][i])
				PopUpMenu $ctrl win = $panelTitle, mode = (v_value - 1)
			else
				PopUpMenu $ctrl win = $panelTitle, mode = TTLIndexingStorageWave[0][i]
			endif
		else
			// do nothing
		endif
	endfor

	DAP_UpdateITIAcrossSets(panelTitle)
End

/// @brief Indexes a single channel - used when indexing is unlocked
Function IDX_IndexSingleChannel(panelTitle, channelType, i)
	string panelTitle
	variable channelType, i

	variable popIdx
	WAVE DACIndexingStorageWave = GetDACIndexingStorageWave(panelTitle)
	WAVE TTLIndexingStorageWave = GetTTLIndexingStorageWave(panelTitle)
	string ctrl

	ctrl = GetPanelControl(i, channelType, CHANNEL_CONTROL_WAVE)
	ControlInfo/W=$panelTitle $ctrl
	popIdx = V_Value
	if(channelType == CHANNEL_TYPE_DAC)
		if(DACIndexingStorageWave[1][i] > DACIndexingStorageWave[0][i])
			if(popIdx < DACIndexingStorageWave[1][i])
				PopUpMenu $ctrl win = $panelTitle, mode = (popIdx + 1)
			else
				PopUpMenu $ctrl win = $panelTitle, mode = DACIndexingStorageWave[0][i]
			endif
		elseif(DACIndexingStorageWave[1][i] < DACIndexingStorageWave[0][i])
			if(popIdx > DACIndexingStorageWave[1][i])
				PopUpMenu $ctrl win = $panelTitle, mode = (popIdx - 1)
			else
				PopUpMenu $ctrl win = $panelTitle, mode = DACIndexingStorageWave[0][i]
			endif
		endif
	elseif(channelType == CHANNEL_TYPE_TTL)
		if(TTLIndexingStorageWave[1][i] > TTLIndexingStorageWave[0][i])
			if(popIdx < TTLIndexingStorageWave[1][i])
				PopUpMenu $ctrl win = $panelTitle, mode = (popIdx + 1)
			else
				PopUpMenu $ctrl win = $panelTitle, mode = TTLIndexingStorageWave[0][i]
			endif
		elseif(TTLIndexingStorageWave[1][i] < TTLIndexingStorageWave[0][i])
			if(popIdx > TTLIndexingStorageWave[1][i])
				PopUpMenu $ctrl win = $panelTitle, mode = (popIdx - 1)
			else
				PopUpMenu $ctrl win = $panelTitle, mode = TTLIndexingStorageWave[0][i]
			endif
		endif
	else
		ASSERT(0, "invalid channel type")
	endif

	DAP_UpdateITIAcrossSets(panelTitle)
End

//NEW INDEXING FUNCTIONS FOR USE WITH 2D SETS

//**************NEED TO ADD FUNCTION TO CALCULATE CYCLE STEPS FOR LOCKED INDEXING!! NEED TO TEST WITH 3 OR MORE SETS!!!!*************

Function IDX_MaxSweepsLockedIndexing(panelTitle)// a sum of the largest sets for each indexing step
	string panelTitle
	string DAChannelStatusList = IDX_ControlStatusListString("DA", "check",panelTitle)
	string TTLChannelStatusList = IDX_ControlStatusListString("TTL", "check",panelTitle)
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
	string DAChannelStatusList = IDX_ControlStatusListString("DA", "check", panelTitle)
	string TTLChannelStatusList = IDX_ControlStatusListString("TTL", "check",panelTitle)
	variable MaxSteps = 0, SetSteps
	variable ListStartNo, ListEndNo, ListLength, Index
	string setName
	string SetList
	variable i = 0
	variable ListOffset = 3
	string popMenuIndexStartName, popMenuIndexEndName
	
	do // for DAs
		if((str2num(stringfromlist(i, DAChannelStatusList,";"))) == 1)
			popMenuIndexStartName = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
			controlinfo /w = $panelTitle $popMenuIndexStartName
			ListStartNo = v_value
			popMenuIndexEndName = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
			controlinfo /w = $panelTitle $popMenuIndexEndName
			ListEndNo = v_value + 1 // " +1 " added to compensate for test pulse not being listed in index end popup menu ************************
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
			SetSteps = IDX_NumberOfTrialsInSet(panelTitle, SetName)
			MaxSteps = max(MaxSteps, SetSteps)
		endif
		i += 1
	while(i < (itemsinlist(DAChannelStatusList, ";")))
	
	ListOffset = 2
	i = 0
	
	do // for TTLs
		if((str2num(stringfromlist(i, TTLChannelStatusList, ";"))) == 1)
			popMenuIndexStartName = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
			controlinfo /w = $panelTitle $popMenuIndexStartName
			ListStartNo = v_value
			popMenuIndexEndName = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
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
		SetSteps = IDX_NumberOfTrialsInSet(panelTitle, SetName)
		MaxSteps = max(MaxSteps, SetSteps)
		endif
		i += 1
	while(i < (itemsinlist(TTLChannelStatusList, ";")))	
	
	return MaxSteps
End

Function IDX_MaxSets(panelTitle)// returns the number of sets on the active channel with the most sets.
	string panelTitle
	string DAChannelStatusList = IDX_ControlStatusListString("DA", "check",panelTitle)
	string TTLChannelStatusList = IDX_ControlStatusListString("TTL", "check",panelTitle)
	variable MaxSets = 0
	variable ChannelSets
	string popMenuIndexStartName, popMenuIndexEndName
	variable i = 0
	do
		if((str2num(stringfromlist(i, DAChannelStatusList, ";"))) == 1)
			popMenuIndexStartName = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
			controlinfo /w = $panelTitle $popMenuIndexStartName
			ChannelSets = v_value
			popMenuIndexEndName = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
			controlinfo /w = $panelTitle $popMenuIndexEndName
			ChannelSets -= (v_value + 1) // added " +1 " to compensate for test pulse not being listed in indexing end wave *******************
			ChannelSets = abs(ChannelSets)
			MaxSets = max(MaxSets,ChannelSets)
		endif	
		i += 1
	while(i < (itemsinlist(DAChannelStatusList, ";")))
	
	i = 0
	do
		if((str2num(stringfromlist(i, TTLChannelStatusList, ";"))) == 1)
			popMenuIndexStartName = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
			controlinfo /w = $panelTitle $popMenuIndexStartName
			ChannelSets = v_value
			popMenuIndexEndName = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
			controlinfo/w=$panelTitle $popMenuIndexEndName
			ChannelSets -= v_value
			ChannelSets = abs(ChannelSets)
			MaxSets = max(MaxSets,ChannelSets)
		endif	
		i += 1
	while(i < (itemsinlist(DAChannelStatusList,";")))
	
	return MaxSets // if the start and end set are the same, this returns 0
End

/// determine the max number of sweeps in the largest start set on active (checked) DA or TTL channels
/// works for unlocked (independent) indexing
/// index override is the same as indexing off
Function IDX_MaxNoOfSweeps(panelTitle, IndexOverRide)
	string panelTitle
	variable IndexOverRide// some Functions that call this function only want the max number of steps in the start (active) set, when indexing is on. 1 = over ride ON
	variable MaxNoOfSweeps = 0
	string DAChannelStatusList = IDX_ControlStatusListString("DA", "check",panelTitle)
	string TTLChannelStatusList = IDX_ControlStatusListString("TTL", "check",panelTitle)
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

	return DEBUGPRINTv(MaxNoOfSweeps)
End

static Function IDX_GetITIFromWaveNote(wv)
	Wave wv

	string str
	str = note(wv)
	// All spaces and carriage returns are just to make the note human readable
	// remove them before searching the key
	str = ReplaceString("\r", str, "")
	str = ReplaceString(" ", str, "")
	return NumberByKey("ITI",str,"=",";")
End

/// @brief Calculates the maximum ITI of a lead panel and all its followers, honours indexing
///
/// @param[in] panelTitle panel title
/// @param[out] numActiveDAChannels returns the number of active DACs of panelTitle
Function IDX_LongestITI(panelTitle, numActiveDAChannels)
	string panelTitle
	variable& numActiveDAChannels

	variable numPanels, i, j, k, iti, maxITI, numDACs, lockedIndexing, numSets
	string panelList, setName, setList

	panelList = panelTitle

	if(DAP_DeviceCanLead(panelTitle))
		SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
		if(SVAR_Exists(listOfFollowerDevices))
			panelList = AddListItem(panelList, listOfFollowerDevices, ";", inf)
		endif
	endif

	lockedIndexing = GetCheckBoxState(panelTitle, "Check_DataAcq1_IndexingLocked")
	maxITI = -INF
	numPanels = ItemsInList(panelList)
	for(i = 0; i < numPanels; i += 1)
		panelTitle = StringFromList(i, panelList)

		Wave DAChannelStatus = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_DAC)
		if(i == 0) // this is either the lead panel or the first and only panel
			numActiveDAChannels = sum(DAChannelStatus)
		endif

		numDACs = DimSize(DAChannelStatus, ROWS)
		for(j = 0; j < numDACs; j += 1)
			if(!DAChannelStatus[j])
				continue
			endif

			setList = IDX_GetSetsInRange(panelTitle, j, CHANNEL_TYPE_DAC, lockedIndexing)
			numSets = ItemsInList(setList)
			for(k = 0; k < numSets; k += 1)
				setName = StringFromList(k, setList)
				WAVE/Z wv = WB_CreateAndGetStimSet(setName)

				if(!WaveExists(wv))
					continue
				endif

				iti = IDX_GetITIFromWaveNote(wv)
				if(IsFinite(iti))
					maxITI = max(maxITI, iti)
				endif
			endfor
		endfor
	endfor

	if(!IsFinite(maxITI))
		return 0
	endif

	return maxITI
End

/// @brief Returns a ";" seperated list of selected set names
/// @param panelTitle panel
/// @param channel channel
/// @param channelType  CHANNEL_TYPE_DAC or CHANNEL_TYPE_TTL
/// @param lockedIndexing defaults to false, true returns just the DAC/TTL setname
///
/// Constants are defined at @ref ChannelTypeAndControlConstants
Function/S IDX_GetSetsInRange(panelTitle, channel, channelType, lockedIndexing)
	string panelTitle
	variable channel, channelType, lockedIndexing

	variable listOffset, first, last, indexStart, indexEnd
	string waveCtrl, lastCtrl, list

	if(channelType == CHANNEL_TYPE_DAC)
		// Additional entries not in menuExp: None, TestPulse
		listOffset = 2
	elseif(channelType == CHANNEL_TYPE_TTL)
		// Additional entries not in menuExp: None
		listOffset = 1
	else
		ASSERT(0, "Invalid channelType")
	endif
	
	waveCtrl = GetPanelControl(channel, channelType, CHANNEL_CONTROL_WAVE)
	lastCtrl = GetPanelControl(channel, channelType, CHANNEL_CONTROL_INDEX_END)
	list     = GetUserData(panelTitle, waveCtrl, "menuexp")

	first = GetPopupMenuIndex(panelTitle, waveCtrl) - ListOffset

	if(lockedIndexing)
		return DEBUGPRINTs(StringFromList(first, list))
	endif

	if(GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing"))
		last = GetPopupMenuIndex(panelTitle, lastCtrl) - 1
		if(last < 0) // - None - is selected
			last = first
		endif
	else // without indexing
		last = first
	endif

	indexStart = min(first, last)
	indexEnd   = max(first, last)

	DEBUGPRINT("Control ", str=waveCtrl)
	DEBUGPRINT("UserData(MenuExp) ", str=list)

	if(indexStart == indexEnd) // only one element
		return DEBUGPRINTs(StringFromList(indexStart, list))
	elseif(indexEnd + 1 == ItemsInList(list))
		return DEBUGPRINTs(list[FindListItem(StringFromList(indexStart, list), list), strlen(list) - 2])
	else // return the part of list from indexStart to indexEnd + 1
		return DEBUGPRINTs(list[FindListItem(StringFromList(indexStart, list), list), FindListItem(StringFromList(indexEnd + 1, list), list) - 2])
	endif
End

/// @brief Determine the number of trials for a DA or TTL channel
Function IDX_NumberOfTrialsAcrossSets(panelTitle, channel, channelType, lockedIndexing)
	string panelTitle
	variable channel, channelType, lockedIndexing

	variable numTrials, numEntries, i
	string setList, set

	setList = IDX_GetSetsInRange(panelTitle, channel, channelType, lockedIndexing)

	numEntries = ItemsInList(setList)
	for(i = 0; i < numEntries; i += 1)
		set = StringFromList(i, setList)
		numTrials += IDX_NumberOfTrialsInSet(panelTitle, set)
	endfor

	return DEBUGPRINTv(numTrials)
End

/// @brief Return the number of trials
Function IDX_NumberOfTrialsInSet(panelTitle, setName)
	string panelTitle, setName

	if(isEmpty(setName))
		return 0
	endif

	WAVE/Z wv = WB_CreateAndGetStimSet(setName)

	if(!WaveExists(wv))
		return 0
	endif

	return max(1, DimSize(wv, COLS))
End

Function IDX_ApplyUnLockedIndexing(panelTitle, count, DAorTTL)
	string panelTitle
	variable count, DAorTTL
	variable i=0
	string ActivechannelList 
	
	if(DAorTTL==0)
		ActiveChannelList = IDX_ControlStatusListString("DA","check",panelTitle)
	endif
	
	if(DAorTTL==1)
		ActiveChannelList = IDX_ControlStatusListString("TTL","check",panelTitle)
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
	WAVE DAIndexingStorageWave = GetDACIndexingStorageWave(panelTitle)
	WAVE TTLIndexingStorageWave = GetTTLIndexingStorageWave(panelTitle)
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

	// ensure that the folder exists
	DFREF dfr = GetSetFolderFromString(ChannelTypeName)

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

	WAVE DAIndexingStorageWave = GetDACIndexingStorageWave(panelTitle)
	WAVE TTLIndexingStorageWave = GetTTLIndexingStorageWave(panelTitle)

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

	// ensure that the folder exists
	DFREF dfr = GetSetFolderFromString(ChannelTypeName)
	
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

Function IDX_DetIfCountIsAtSetBorder(panelTitle, count, channelNumber, DAorTTL)
	string panelTitle
	variable count, channelNumber, DAorTTL
	variable AtSetBorder=0
	WAVE DAIndexingStorageWave = GetDACIndexingStorageWave(panelTitle)
	WAVE TTLIndexingStorageWave = GetTTLIndexingStorageWave(panelTitle)
	string listOfWaveInPopup, PopUpMenuList, ChannelPopUpMenuName,ChannelTypeName, DAorTTLWavePath, DAorTTLFullWaveName
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
					// print DAIndexingStorageWave[1][ChannelNumber]
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

/// @brief Calculate the active set count
Function IDX_CalculcateActiveSetCount(panelTitle)
	string panelTitle

	variable value

	value  = GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_SweepsActiveSet")
	value *= GetSetVariable(panelTitle, "SetVar_DataAcq_SetRepeats")

	return value
End
