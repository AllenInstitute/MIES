#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_IDX
#endif

/// @file MIES_Indexing.ipf
/// @brief __IDX__ Indexing related functionality

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
		DACIndexingStorageWave[1][i] = V_Value

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

		ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
		SetPopupMenuIndex(paneltitle, ctrl, TTLIndexingStorageWave[0][i] - 1)
	endfor
End

/// @brief Locked indexing, indexes all active channels at once
Function IDX_IndexingDoIt(panelTitle)
	string panelTitle

	variable i

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		IDX_IndexSingleChannel(panelTitle, CHANNEL_TYPE_DAC, i, update = 0)
		IDX_IndexSingleChannel(panelTitle, CHANNEL_TYPE_TTL, i, update = 0)
	endfor

	DAP_UpdateITIAcrossSets(panelTitle)
End

/// @brief Indexes a single channel - used when indexing is unlocked
static Function IDX_IndexSingleChannel(panelTitle, channelType, i, [update])
	string panelTitle
	variable channelType, i, update

	variable popIdx
	string ctrl

	if(ParamIsDefault(update))
		update = 1
	else
		update = !!update
	endif

	WAVE indexingStorageWave = GetIndexingStorageWave(panelTitle, channelType)

	ctrl   = GetPanelControl(i, channelType, CHANNEL_CONTROL_WAVE)
	popIdx = GetPopupMenuIndex(panelTitle, ctrl) + 1

	if(indexingStorageWave[1][i] > indexingStorageWave[0][i])
		if(popIdx < indexingStorageWave[1][i])
			popIdx += 1
		else
			popIdx  = indexingStorageWave[0][i]
		endif
	elseif(indexingStorageWave[1][i] < indexingStorageWave[0][i])
		if(popIdx > indexingStorageWave[1][i])
			popIdx -= 1
		else
			popIdx  = indexingStorageWave[0][i]
		endif
	endif

	SetPopupMenuIndex(panelTitle, ctrl, popIdx - 1)

	if(update)
		DAP_UpdateITIAcrossSets(panelTitle)
	endif
End

/// @brief Sum of the largest sets for each indexing step
Function IDX_MaxSweepsLockedIndexing(panelTitle)
	string panelTitle

	variable i, maxSteps
	variable MaxCycleIndexSteps = IDX_MaxSets(panelTitle) + 1

	do
		MaxSteps += IDX_StepsInSetWithMaxSweeps(panelTitle,i)
		i += 1
	while(i < MaxCycleIndexSteps)

	return MaxSteps
End

/// @brief Return the number of steps in the largest set for a particular index number
static Function IDX_StepsInSetWithMaxSweeps(panelTitle,IndexNo)
	string panelTitle
	variable IndexNo

	variable MaxSteps = 0, SetSteps
	variable ListStartNo, ListEndNo, ListLength, Index
	string setName
	string popMenuIndexStartName, popMenuIndexEndName
	variable i = 0

	WAVE statusDA = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_DAC)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusDA[i])
			continue
		endif

		popMenuIndexStartName = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		controlinfo /w = $panelTitle $popMenuIndexStartName
		ListStartNo = v_value
		popMenuIndexEndName = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
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

		WAVE stimsets = IDX_GetStimsets(panelTitle, i, CHANNEL_TYPE_DAC)
		SetSteps = IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, ListStartNo + index))
		MaxSteps = max(MaxSteps, SetSteps)
	endfor

	WAVE statusTTL = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_TTL)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusTTL[i])
			continue
		endif

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

		WAVE stimsets = IDX_GetStimsets(panelTitle, i, CHANNEL_TYPE_TTL)
		SetSteps = IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, ListStartNo + index))
		MaxSteps = max(MaxSteps, SetSteps)
	endfor
	
	return MaxSteps
End

/// @brief Return the number of sets on the active channel with the most sets.
static Function IDX_MaxSets(panelTitle)
	string panelTitle

	variable MaxSets = 0
	variable ChannelSets
	string popMenuIndexStartName, popMenuIndexEndName
	variable i = 0

	WAVE statusDA  = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_DAC)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusDA[i])
			continue
		endif

		popMenuIndexStartName = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		controlinfo /w = $panelTitle $popMenuIndexStartName
		ChannelSets = v_value
		popMenuIndexEndName = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
		controlinfo /w = $panelTitle $popMenuIndexEndName
		ChannelSets -= v_value
		ChannelSets  = abs(ChannelSets)
		MaxSets = max(MaxSets,ChannelSets)
	endfor

	WAVE statusTTL = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_TTL)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusTTL[i])
			continue
		endif

		popMenuIndexStartName = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
		controlinfo /w = $panelTitle $popMenuIndexStartName
		ChannelSets = v_value
		popMenuIndexEndName = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
		controlinfo/w=$panelTitle $popMenuIndexEndName
		ChannelSets -= v_value
		ChannelSets = abs(ChannelSets)
		MaxSets = max(MaxSets,ChannelSets)
	endfor

	return MaxSets // if the start and end set are the same, this returns 0
End

/// @brief determine the max number of sweeps in the largest start set on active (checked) DA or TTL channels
/// works for unlocked (independent) indexing
///
/// @param panelTitle    device
/// @param IndexOverRide index override is the same as indexing off. some
///                      Functions that call this function only want the max number of steps in the
///                      start (active) set, when indexing is on. 1 = over ride ON
Function IDX_MaxNoOfSweeps(panelTitle, IndexOverRide)
	string panelTitle
	variable IndexOverRide

	variable MaxNoOfSweeps
	variable i

	WAVE statusDA = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_DAC)
 
	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusDA[i])
			continue
		endif

		MaxNoOfSweeps = max(MaxNoOfSweeps, IDX_NumberOfTrialsAcrossSets(panelTitle, i, 0, IndexOverRide))
	endfor

	WAVE statusTTL = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_TTL)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusTTL[i])
			continue
		endif

		MaxNoOfSweeps = max(MaxNoOfSweeps, IDX_NumberOfTrialsAcrossSets(panelTitle, i, 1, IndexOverRide))
	endfor

	return DEBUGPRINTv(MaxNoOfSweeps)
End

/// @brief Returns the number of sweeps in the stimulus set with the smallest number of sweeps (across all active stimulus sets).
///
/// @param panelTitle device
Function IDX_MinNoOfSweeps(panelTitle)
	string panelTitle

	variable MinNoOfSweeps = inf
	variable i

	WAVE statusDA = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_DAC)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusDA[i])
			continue
		endif

		MinNoOfSweeps = min(MinNoOfSweeps, IDX_NumberOfTrialsAcrossSets(panelTitle, i, 0, 1))
	endfor

	WAVE statusTTL = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_TTL)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusTTL[i])
			continue
		endif

		MinNoOfSweeps = min(MinNoOfSweeps, IDX_NumberOfTrialsAcrossSets(panelTitle, i, 1, 1))
	endfor

	return MinNoOfSweeps == inf ? 0 : MinNoOfSweeps
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

	panelList = GetListofLeaderAndPossFollower(panelTitle)

	maxITI = -INF
	numPanels = ItemsInList(panelList)
	for(i = 0; i < numPanels; i += 1)
		panelTitle = StringFromList(i, panelList)

		Wave DAChannelStatus = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_DAC)
		if(i == 0) // this is either the lead panel or the first and only panel
			numActiveDAChannels = sum(DAChannelStatus)
			if(numActiveDAChannels > 1)
				lockedIndexing = GetCheckBoxState(panelTitle, "Check_DataAcq1_IndexingLocked")
			else // With only a single channel, locked and unlocked indexing are equivalent.
				lockedIndexing = 1
			endif
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
static Function/S IDX_GetSetsInRange(panelTitle, channel, channelType, lockedIndexing)
	string panelTitle
	variable channel, channelType, lockedIndexing

	variable listOffset, first, last, indexStart, indexEnd
	string waveCtrl, lastCtrl, list

	// Additional entries not in menuExp: None
	listOffset = 1

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
static Function IDX_NumberOfTrialsAcrossSets(panelTitle, channel, channelType, lockedIndexing)
	string panelTitle
	variable channel, channelType, lockedIndexing

	variable numTrials, numEntries, i
	string setList, set

	setList = IDX_GetSetsInRange(panelTitle, channel, channelType, lockedIndexing)

	numEntries = ItemsInList(setList)
	for(i = 0; i < numEntries; i += 1)
		set = StringFromList(i, setList)
		numTrials += IDX_NumberOfTrialsInSet(set)
	endfor

	return DEBUGPRINTv(numTrials)
End

/// @brief Return the number of trials
Function IDX_NumberOfTrialsInSet(setName)
	string setName

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

	variable i

	if(DAorTTL == 0)
		WAVE status = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_DAC)
	elseif(DAorTTL == 1)
		WAVE status = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_TTL)
	else
		ASSERT(0, "Invalid value")
	endif

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!status[i])
			continue
		endif

		if(IDX_DetIfCountIsAtSetBorder(panelTitle, count, i, DAorTTL) == 1)
			IDX_IndexSingleChannel(panelTitle, DAorTTL, i)
		endif
	endfor
End

static Function IDX_TotalIndexingListSteps(panelTitle, ChannelNumber, DAorTTL)
	string panelTitle
	variable ChannelNumber, DAorTTL

	variable TotalListSteps
	WAVE DAIndexingStorageWave = GetDACIndexingStorageWave(panelTitle)
	WAVE TTLIndexingStorageWave = GetTTLIndexingStorageWave(panelTitle)
	string setName
	variable i

	WAVE stimsets = IDX_GetStimsets(panelTitle, channelNumber, DAorTTL)

	// the do-while loops adjust count based on the number of times the list of sets has cycled

	if(DAIndexingStorageWave[0][ChannelNumber]<DAIndexingStorageWave[1][ChannelNumber])
		if(DAorTTL==0)
			do
				totalListSteps += IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, DAIndexingStorageWave[0][channelNumber] + i))
				i+=1
			while( (i + DAIndexingStorageWave[0][ChannelNumber]) <= DAIndexingStorageWave[1][ChannelNumber] )
		endif
		
		if(DAorTTL==1)
			do
				totalListSteps += IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, TTLIndexingStorageWave[0][channelNumber] + i))
				i+=1
			while( (i + TTLIndexingStorageWave[0][ChannelNumber]) <= TTLIndexingStorageWave[1][ChannelNumber] )
		endif
	endif
	i=0

	// end index wave is before start index wave in wave list of popup menu
	if(DAIndexingStorageWave[0][ChannelNumber]>DAIndexingStorageWave[1][ChannelNumber])
		if(DAorTTL==0)
			do
				totalListSteps += IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, DAIndexingStorageWave[0][channelNumber] + i))
				i+=1
			while( (i + DAIndexingStorageWave[1][ChannelNumber]) <= DAIndexingStorageWave[0][ChannelNumber] )
		endif

		if(DAorTTL==1)
			do
				totalListSteps += IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, TTLIndexingStorageWave[0][channelNumber] + i))
				i+=1
			while( (i + TTLIndexingStorageWave[1][ChannelNumber]) <= TTLIndexingStorageWave[0][ChannelNumber] )
		endif
	endif

	return TotalListSteps
End

Function IDX_UnlockedIndexingStepNo(panelTitle, channelNo, DAorTTL, count)
	string paneltitle
	variable channelNo, DAorTTL, count
	variable column, i, StepsInSummedSets, totalListSteps
	string setName

	WAVE DAIndexingStorageWave = GetDACIndexingStorageWave(panelTitle)
	WAVE TTLIndexingStorageWave = GetTTLIndexingStorageWave(panelTitle)

	WAVE stimsets = IDX_GetStimsets(panelTitle, channelNo, DAorTTL)

	// Total List steps is all the columns in all the waves defined by the start index and end index waves
	TotalListSteps = IDX_TotalIndexingListSteps(panelTitle, channelNo, DAorTTL)

	do // do loop resets count if the the count has cycled through the total list steps
		if(count >= TotalListSteps)
		count -= totalListsteps
		endif
	while(count >= totalListSteps)

	i = 0
	
	if((DAIndexingStorageWave[0][channelNo]) < (DAIndexingStorageWave[1][channelNo]))
		if(DAorTTL == 0)//DA channel
			do
				StepsInSummedSets += IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, DAIndexingStorageWave[0][channelNo] + i))
				i += 1
			while(StepsInSummedSets<=Count)
			i-=1
			StepsInSummedSets -= IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, DAIndexingStorageWave[0][channelNo] + i))
		endif

		if(DAorTTL==1)//TTL channel
			do
				StepsInSummedSets += IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, TTLIndexingStorageWave[0][channelNo] + i))
				i+=1
			while(StepsInSummedSets<=Count)
			i-=1
			StepsInSummedSets -= IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, TTLIndexingStorageWave[0][channelNo] + i))
		endif
	endif

	i=0
	if(DAIndexingStorageWave[0][channelNo] > DAIndexingStorageWave[1][channelNo])//  handels the situation where the start set is after the end set on the index list
		if(DAorTTL==0)//DA channel
			do
				StepsInSummedSets += IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, DAIndexingStorageWave[0][channelNo] + i))
				i-=1
			while(StepsInSummedSets<=Count)
			i+=1
			StepsInSummedSets -= IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, DAIndexingStorageWave[0][channelNo] + i))
		endif

		if(DAorTTL==1)//TTL channel
			do
				StepsInSummedSets += IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, TTLIndexingStorageWave[0][channelNo] + i))
				i-=1
			while(StepsInSummedSets<=Count)
			i+=1
			StepsInSummedSets -= IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, TTLIndexingStorageWave[0][channelNo] + i))
		endif
	endif

	column=count-StepsInSummedSets
	return column
end

static Function IDX_DetIfCountIsAtSetBorder(panelTitle, count, channelNumber, DAorTTL)
	string panelTitle
	variable count, channelNumber, DAorTTL

	WAVE DAIndexingStorageWave = GetDACIndexingStorageWave(panelTitle)
	WAVE TTLIndexingStorageWave = GetTTLIndexingStorageWave(panelTitle)
	string setName
	variable i, StepsInSummedSets, TotalListSteps

	WAVE stimsets = IDX_GetStimsets(panelTitle, channelNumber, DAorTTL)
	TotalListSteps = IDX_TotalIndexingListSteps(panelTitle, ChannelNumber, DAorTTL)
		
	do
		if(count>TotalListSteps)
			count-=totalListsteps
		endif
	while(count>totalListSteps)
		
	if(DAIndexingStorageWave[0][ChannelNumber]<DAIndexingStorageWave[1][ChannelNumber])
		i=0
		if(DAorTTL==0)//DA channel
			do
				StepsInSummedSets += IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, DAIndexingStorageWave[0][ChannelNumber] + i))
				if(StepsInSummedSets == Count)
					return 1
				endif
			i+=1
			while(StepsInSummedSets<=Count)
		endif
		i=0
	endif

	if(TTLIndexingStorageWave[0][ChannelNumber]<TTLIndexingStorageWave[1][ChannelNumber])
		if(DAorTTL==1)// TTL channel
			do
				StepsInSummedSets += IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, TTLIndexingStorageWave[0][ChannelNumber] + i))

				if(StepsInSummedSets == Count)
					return 1
				endif
			i+=1
			while(StepsInSummedSets<=Count)
		endif
	endif

	if(DAIndexingStorageWave[0][ChannelNumber]>DAIndexingStorageWave[1][ChannelNumber])// handles end index that is in front of start index in the popup menu list
		i=0
		if(DAorTTL==0)//DA channel
			do
				StepsInSummedSets += IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, DAIndexingStorageWave[0][ChannelNumber] + i))
				if(StepsInSummedSets == Count)
					return 1
				endif
			i-=1
			while(StepsInSummedSets<=Count)
		endif
		i=0
	endif

	if(TTLIndexingStorageWave[0][ChannelNumber]>TTLIndexingStorageWave[1][ChannelNumber])
		if(DAorTTL==1)// TTL channel
			do
				StepsInSummedSets += IDX_NumberOfTrialsInSet(IDX_GetSingleStimset(stimsets, TTLIndexingStorageWave[0][ChannelNumber] + i))

				if(StepsInSummedSets == Count)
					return 1
				endif
			i-=1
			while(StepsInSummedSets<=Count)
		endif
	endif

	return 0
End

/// @brief Calculate the active set count
Function IDX_CalculcateActiveSetCount(panelTitle)
	string panelTitle

	variable value

	value  = GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_SweepsActiveSet")
	value *= GetSetVariable(panelTitle, "SetVar_DataAcq_SetRepeats")

	return value
End

/// @brief Extract the list of stimsets from the control user data
static Function/WAVE IDX_GetStimsets(panelTitle, channelIdx, channelType)
	string panelTitle
	variable channelIdx, channelType

	string ctrl, list

	ctrl = GetPanelControl(channelIdx, channelType, CHANNEL_CONTROL_WAVE)
	// does not include - None -
	list = GetUserData(panelTitle, ctrl, "MenuExp")
	WAVE/T stimsets = ListToTextWave(list, ";")

	return stimsets
End

static Function/S IDX_GetSingleStimset(listWave, idx)
	WAVE/T listWave
	variable idx

	// 2 because:
	// none is not part of MenuExp
	// and idx is 1-based
	string setName = listWave[idx - 2]
	ASSERT(!IsEmpty(setName), "Unexpected empty set")

	return setName
End
