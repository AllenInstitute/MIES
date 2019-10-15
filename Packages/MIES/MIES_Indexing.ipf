#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
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
		DACIndexingStorageWave[0][i] = GetPopupMenuIndex(panelTitle, ctrl) + 1

		ctrl = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
		DACIndexingStorageWave[1][i] = GetPopupMenuIndex(panelTitle, ctrl) + 1

		ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
		TTLIndexingStorageWave[0][i] = GetPopupMenuIndex(panelTitle, ctrl) + 1

		ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
		TTLIndexingStorageWave[1][i] = GetPopupMenuIndex(panelTitle, ctrl) + 1
	endfor 
End

/// @brief Resets the selected set popupmenus stored by #IDX_StoreStartFinishForIndexing
Function IDX_ResetStartFinishForIndexing(panelTitle)
	string panelTitle

	variable i, idx
	string ctrl

	WAVE DACIndexingStorageWave = GetDACIndexingStorageWave(panelTitle)
	WAVE TTLIndexingStorageWave = GetTTLIndexingStorageWave(panelTitle)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		ctrl = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		idx = DACIndexingStorageWave[0][i]
		SetPopupMenuIndex(paneltitle, ctrl, idx - 1)

		WAVE stimsets = IDX_GetStimsets(panelTitle, i, CHANNEL_TYPE_DAC)
		DAG_Update(panelTitle, ctrl, val = idx - 1, str = IDX_GetSingleStimset(stimsets, idx, allowNone = 1))

		ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
		idx = TTLIndexingStorageWave[0][i]
		SetPopupMenuIndex(paneltitle, ctrl, idx - 1)

		WAVE stimsets = IDX_GetStimsets(panelTitle, i, CHANNEL_TYPE_TTL)
		DAG_Update(panelTitle, ctrl, val = idx - 1, str = IDX_GetSingleStimset(stimsets, idx, allowNone = 1))
	endfor

	DAP_UpdateDAQControls(panelTitle, REASON_STIMSET_CHANGE)
End

/// @brief Locked indexing, indexes all active channels at once
Function IDX_IndexingDoIt(panelTitle)
	string panelTitle

	variable i

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		IDX_IndexSingleChannel(panelTitle, CHANNEL_TYPE_DAC, i)
		IDX_IndexSingleChannel(panelTitle, CHANNEL_TYPE_TTL, i)
	endfor

	// need to fire pre set event on next occasion
	WAVE setEventFlag = GetSetEventFlag(panelTitle)
	setEventFlag[][%PRE_SET_EVENT] = 1

	DAP_UpdateDAQControls(panelTitle, REASON_STIMSET_CHANGE_DUR_DAQ)
	NVAR activeSetCount = $GetActiveSetCount(panelTitle)
	activeSetCount = IDX_CalculcateActiveSetCount(panelTitle)
End

/// @brief Indexes a single channel - used when indexing is unlocked
///
/// Callers need to call DAP_UpdateDAQControls() with #REASON_STIMSET_CHANGE_DUR_DAQ.
static Function IDX_IndexSingleChannel(panelTitle, channelType, i)
	string panelTitle
	variable channelType, i

	variable popIdx
	string ctrl

	ctrl = GetSpecialControlLabel(channelType, CHANNEL_CONTROL_CHECK)

	if(!DAG_GetNumericalValue(panelTitle, ctrl, index = i))
		return NaN
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
	WAVE stimsets = IDX_GetStimsets(panelTitle, i, channelType)
	DAG_Update(panelTitle, ctrl, val = popIdx - 1, str = IDX_GetSingleStimset(stimsets, popIdx))
End

/// @brief Sum of the largest sets for each indexing step
Function IDX_MaxSweepsLockedIndexing(panelTitle)
	string panelTitle

	variable i, maxSteps
	variable MaxCycleIndexSteps = IDX_MaxSets(panelTitle) + 1

	do
		MaxSteps += max(IDX_StepsInSetWithMaxSweeps(panelTitle, i, CHANNEL_TYPE_DAC), \
							IDX_StepsInSetWithMaxSweeps(panelTitle, i, CHANNEL_TYPE_TTL))
		i += 1
	while(i < MaxCycleIndexSteps)

	return MaxSteps
End

/// @brief Return the number of steps in the largest set for a particular index number
static Function IDX_StepsInSetWithMaxSweeps(panelTitle, IndexNo, channelType)
	string panelTitle
	variable IndexNo, channelType

	variable MaxSteps, SetSteps
	variable ListStartNo, ListEndNo, ListLength, Index
	string ctrl, setName
	variable i

	WAVE status = DAG_GetChannelState(panelTitle, channelType)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!status[i])
			continue
		endif

		ctrl = GetPanelControl(i, channelType, CHANNEL_CONTROL_WAVE)
		ListStartNo = GetPopupMenuIndex(panelTitle, ctrl) + 1

		ctrl = GetPanelControl(i, channelType, CHANNEL_CONTROL_INDEX_END)
		ListEndNo = GetPopupMenuIndex(panelTitle, ctrl) + 1

		ListLength = abs(ListStartNo - ListEndNo) + 1
		index = indexNo
		if(listLength <= IndexNo)
			Index = mod(IndexNo, ListLength)
		endif

		if((ListStartNo - ListEndNo) > 0)
			index *= -1
		endif

		WAVE stimsets = IDX_GetStimsets(panelTitle, i, channelType)
		setName  = IDX_GetSingleStimset(stimsets, ListStartNo + index, allowNone = 1)
		SetSteps = IDX_NumberOfSweepsInSet(setName)
		MaxSteps = max(MaxSteps, SetSteps)
	endfor

	return MaxSteps
End

/// @brief Return the number of sets on the active channel with the most sets.
static Function IDX_MaxSets(panelTitle)
	string panelTitle

	variable MaxSets = 0
	variable ChannelSets
	string ctrl
	variable i = 0

	WAVE statusDA  = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_DAC)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusDA[i])
			continue
		endif

		ctrl = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		ChannelSets = GetPopupMenuIndex(panelTitle, ctrl) + 1

		ctrl = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
		ChannelSets -= GetPopupMenuIndex(panelTitle, ctrl) + 1

		ChannelSets  = abs(ChannelSets)
		MaxSets = max(MaxSets,ChannelSets)
	endfor

	WAVE statusTTL = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_TTL)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusTTL[i])
			continue
		endif

		ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
		ChannelSets = GetPopupMenuIndex(panelTitle, ctrl) + 1

		ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
		ChannelSets -= GetPopupMenuIndex(panelTitle, ctrl) + 1

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
	variable i, numFollower
	string followerPanelTitle

	WAVE statusDA = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_DAC)
 
	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusDA[i])
			continue
		endif

		MaxNoOfSweeps = max(MaxNoOfSweeps, IDX_NumberOfSweepsAcrossSets(panelTitle, i, 0, IndexOverRide))
	endfor

	WAVE statusTTL = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_TTL)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusTTL[i])
			continue
		endif

		MaxNoOfSweeps = max(MaxNoOfSweeps, IDX_NumberOfSweepsAcrossSets(panelTitle, i, 1, IndexOverRide))
	endfor

	if(DeviceHasFollower(panelTitle))
		SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)
		numFollower = ItemsInList(listOfFollowerDevices)
		for(i = 0; i < numFollower; i += 1)
			followerPanelTitle = StringFromList(i, listOfFollowerDevices)

			MaxNoOfSweeps = max(MaxNoOfSweeps, IDX_MaxNoOfSweeps(followerPanelTitle, IndexOverRide))
		endfor
	endif

	return DEBUGPRINTv(MaxNoOfSweeps)
End

/// @brief Returns the number of sweeps in the stimulus set with the smallest number of sweeps (across all active stimulus sets).
///
/// @param panelTitle device
Function IDX_MinNoOfSweeps(panelTitle)
	string panelTitle

	variable MinNoOfSweeps = inf
	variable i

	WAVE statusDA = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_DAC)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusDA[i])
			continue
		endif

		MinNoOfSweeps = min(MinNoOfSweeps, IDX_NumberOfSweepsAcrossSets(panelTitle, i, 0, 1))
	endfor

	WAVE statusTTL = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_TTL)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusTTL[i])
			continue
		endif

		MinNoOfSweeps = min(MinNoOfSweeps, IDX_NumberOfSweepsAcrossSets(panelTitle, i, 1, 1))
	endfor

	return MinNoOfSweeps == inf ? 0 : MinNoOfSweeps
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
	string waveCtrl, lastCtrl, list, msg

	sprintf msg, "channel %d, channelType %d, lockedIndexing %d", channel, channelType, lockedIndexing
	DEBUGPRINT(msg)

	// Additional entries not in menuExp: None
	listOffset = 1

	waveCtrl = GetPanelControl(channel, channelType, CHANNEL_CONTROL_WAVE)
	lastCtrl = GetPanelControl(channel, channelType, CHANNEL_CONTROL_INDEX_END)
	list     = GetUserData(panelTitle, waveCtrl, "menuexp")

	// deliberately not using the gui state wave
	first = GetPopupMenuIndex(panelTitle, waveCtrl) - ListOffset

	if(lockedIndexing)
		return DEBUGPRINTs(StringFromList(first, list))
	endif

	if(DAG_GetNumericalValue(panelTitle, "Check_DataAcq_Indexing"))
		// deliberately not using the gui state wave
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

/// @brief Determine the number of sweeps for a DA or TTL channel
static Function IDX_NumberOfSweepsAcrossSets(panelTitle, channel, channelType, lockedIndexing)
	string panelTitle
	variable channel, channelType, lockedIndexing

	variable numSweeps, numEntries, i
	string setList, set

	setList = IDX_GetSetsInRange(panelTitle, channel, channelType, lockedIndexing)

	numEntries = ItemsInList(setList)
	for(i = 0; i < numEntries; i += 1)
		set = StringFromList(i, setList)
		numSweeps += IDX_NumberOfSweepsInSet(set)
	endfor

	return DEBUGPRINTv(numSweeps)
End

/// @brief Return the number of sweeps
Function IDX_NumberOfSweepsInSet(setName)
	string setName

	if(isEmpty(setName))
		return 0
	endif
	if(!CmpStr(setName, STIMSET_TP_WHILE_DAQ))
		return 1
	endif

	WAVE/Z wv = WB_CreateAndGetStimSet(setName)

	if(!WaveExists(wv))
		return 0
	endif

	return max(1, DimSize(wv, COLS))
End

Function IDX_ApplyUnLockedIndexing(panelTitle, count)
	string panelTitle
	variable count

	variable i, update

	WAVE statusDA = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_DAC)
	WAVE statusTTL = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_TTL)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusDA[i])
			continue
		endif

		if(IDX_DetIfCountIsAtSetBorder(panelTitle, count, i, CHANNEL_TYPE_DAC) == 1)
			update = 1
			IDX_IndexSingleChannel(panelTitle, CHANNEL_TYPE_DAC, i)
		endif
	endfor

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusTTL[i])
			continue
		endif

		if(IDX_DetIfCountIsAtSetBorder(panelTitle, count, i, CHANNEL_TYPE_TTL) == 1)
			update = 1
			IDX_IndexSingleChannel(panelTitle, CHANNEL_TYPE_TTL, i)
		endif
	endfor

	if(update)
		DAP_UpdateDAQControls(panelTitle, REASON_STIMSET_CHANGE_DUR_DAQ)
		NVAR activeSetCount = $GetActiveSetCount(panelTitle)
		activeSetCount = IDX_CalculcateActiveSetCount(panelTitle)
	endif
End

static Function IDX_TotalIndexingListSteps(panelTitle, channelNumber, channelType)
	string panelTitle
	variable channelNumber, channelType

	variable totalListSteps
	variable i, first, last

	if(channelType == CHANNEL_TYPE_DAC)
		WAVE indexingStorageWave = GetDACindexingStorageWave(panelTitle)
	elseif(channelType == CHANNEL_TYPE_TTL)
		WAVE indexingStorageWave = GetTTLindexingStorageWave(panelTitle)
	else
		ASSERT(0, "Invalid value")
	endif

	ASSERT(indexingStorageWave[0][channelNumber] != indexingStorageWave[1][channelNumber], "Unexpected combo")
	first = min(indexingStorageWave[0][channelNumber], indexingStorageWave[1][channelNumber])
	last  = max(indexingStorageWave[0][channelNumber], indexingStorageWave[1][channelNumber])

	WAVE stimsets = IDX_GetStimsets(panelTitle, channelNumber, channelType)

	for(i = first; i <= last; i += 1)
		totalListSteps += IDX_NumberOfSweepsInSet(IDX_GetSingleStimset(stimsets, i))
	endfor

	return totalListSteps
End

Function IDX_UnlockedIndexingStepNo(panelTitle, channelNumber, channelType, count)
	string paneltitle
	variable channelNumber, channelType, count

	variable column, i, stepsInSummedSets, totalListSteps, direction

	if(channelType == CHANNEL_TYPE_DAC)
		WAVE indexingStorageWave = GetDACindexingStorageWave(panelTitle)
	elseif(channelType == CHANNEL_TYPE_TTL)
		WAVE indexingStorageWave = GetTTLindexingStorageWave(panelTitle)
	else
		ASSERT(0, "Invalid value")
	endif

	WAVE stimsets = IDX_GetStimsets(panelTitle, channelNumber, channelType)
	totalListSteps = IDX_TotalIndexingListSteps(panelTitle, channelNumber, channelType)
	ASSERT(TotalListSteps > 0, "Expected strictly positive value")
	ASSERT(indexingStorageWave[0][channelNumber] != indexingStorageWave[1][channelNumber], "Unexpected combo")

	count     = mod(count, totalListSTeps)
	direction = indexingStorageWave[0][channelNumber] < indexingStorageWave[1][channelNumber] ? +1 : -1

	for(i = 0; stepsInSummedSets <= count; i += direction)
		stepsInSummedSets += IDX_NumberOfSweepsInSet(IDX_GetSingleStimset(stimsets, indexingStorageWave[0][channelNumber] + i))
	endfor
	stepsInSummedSets -= IDX_NumberOfSweepsInSet(IDX_GetSingleStimset(stimsets, indexingStorageWave[0][channelNumber] + i - direction))

	return count - StepsInSummedSets
end

static Function IDX_DetIfCountIsAtSetBorder(panelTitle, count, channelNumber, channelType)
	string panelTitle
	variable count, channelNumber, channelType

	variable i, stepsInSummedSets, totalListSteps, direction

	if(channelType == CHANNEL_TYPE_DAC)
		WAVE indexingStorageWave = GetDACindexingStorageWave(panelTitle)
	elseif(channelType == CHANNEL_TYPE_TTL)
		WAVE indexingStorageWave = GetTTLindexingStorageWave(panelTitle)
	else
		ASSERT(0, "Invalid value")
	endif

	WAVE stimsets = IDX_GetStimsets(panelTitle, channelNumber, channelType)
	TotalListSteps = IDX_TotalIndexingListSteps(panelTitle, ChannelNumber, channelType)
	ASSERT(TotalListSteps > 0, "Expected strictly positive value")
	ASSERT(indexingStorageWave[0][channelNumber] != indexingStorageWave[1][channelNumber], "Unexpected combo")

	count = (mod(count, totalListSteps) == 0 ? totalListSteps : mod(count, totalListSTeps))

	direction = indexingStorageWave[0][channelNumber] < indexingStorageWave[1][channelNumber] ? +1 : -1

	stepsInSummedSets = 0
	for(i = 0; stepsInSummedSets <= count; i += direction)
		stepsInSummedSets += IDX_NumberOfSweepsInSet(IDX_GetSingleStimset(stimsets, indexingStorageWave[0][channelNumber] + i))

		if(stepsInSummedSets == count)
			return 1
		endif
	endfor

	return 0
End

/// @brief Calculate the active set count
Function IDX_CalculcateActiveSetCount(panelTitle)
	string panelTitle

	variable value

	value  = GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_SweepsActiveSet")
	value *= DAG_GetNumericalValue(panelTitle, "SetVar_DataAcq_SetRepeats")

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

/// @brief Return the stimset from the list of stimsets
///        returned by IDX_GetStimsets()
///
/// @param listWave  list of stim sets returned by IDX_GetStimsets()
/// @param idx       1-based index
/// @param allowNone [optional, defaults to false] Return the `NONE` stimset for idx `1`.
///                  Not allowed during DAQ.
static Function/S IDX_GetSingleStimset(listWave, idx, [allowNone])
	WAVE/T listWave
	variable idx, allowNone

	if(ParamIsDefault(allowNone))
		allowNone = 0
	else
		allowNone = !!allowNone
	endif

	if(allowNone && idx == 1)
		return NONE
	endif

	// 2 because:
	// none is not part of MenuExp
	// and idx is 1-based
	string setName = listWave[idx - 2]
	ASSERT(!IsEmpty(setName), "Unexpected empty set")

	return setName
End
