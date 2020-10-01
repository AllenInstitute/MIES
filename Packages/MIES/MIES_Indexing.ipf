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

	variable i, j, waveIdx, indexIdx, channelType

	WAVE IndexingStorageWave = GetIndexingStorageWave(panelTitle)
	Make/FREE channelTypes = {CHANNEL_TYPE_DAC, CHANNEL_TYPE_TTL}

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		for(j = 0; j < 2; j += 1)
			channelType = channelTypes[j]

			[waveIdx, indexIdx] = IDX_GetCurrentSets(panelTitle, channelType, i)
			IndexingStorageWave[channelType][%CHANNEL_CONTROL_WAVE][i] = waveIdx
			IndexingStorageWave[channelType][%CHANNEL_CONTROL_INDEX_END][i] = indexIdx
		endfor
	endfor
End

/// @brief Resets the selected set popupmenus stored by #IDX_StoreStartFinishForIndexing
Function IDX_ResetStartFinishForIndexing(panelTitle)
	string panelTitle

	variable i, j, idx, channelType
	string ctrl, stimset

	WAVE IndexingStorageWave = GetIndexingStorageWave(panelTitle)
	Make/FREE channelTypes = {CHANNEL_TYPE_DAC, CHANNEL_TYPE_TTL}

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		for(j = 0; j < 2; j += 1)
			channelType = channelTypes[j]

			ctrl = GetPanelControl(i, channelType, CHANNEL_CONTROL_WAVE)
			idx = IndexingStorageWave[channelType][%CHANNEL_CONTROL_WAVE][i]
			SetPopupMenuIndex(paneltitle, ctrl, idx)

			WAVE stimsets = IDX_GetStimsets(panelTitle, i, channelType)
			stimset = IDX_GetSingleStimset(stimsets, idx, allowNone = 1)
			DAG_Update(panelTitle, ctrl, val = idx, str = stimset)
		endfor
	endfor

	DAP_UpdateDAQControls(panelTitle, REASON_STIMSET_CHANGE)
End

/// @brief Locked indexing, indexes all active channels at once
static Function IDX_IndexingDoIt(panelTitle)
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
static Function IDX_IndexSingleChannel(panelTitle, channelType, channel)
	string panelTitle
	variable channelType, channel

	variable first, last
	variable waveIdx, indexIdx
	string ctrl

	ctrl = GetSpecialControlLabel(channelType, CHANNEL_CONTROL_CHECK)

	if(!DAG_GetNumericalValue(panelTitle, ctrl, index = channel))
		return NaN
	endif

	WAVE indexingStorageWave = GetIndexingStorageWave(panelTitle)
	first = indexingStorageWave[channelType][%CHANNEL_CONTROL_WAVE][channel]
	last  = indexingStorageWave[channelType][%CHANNEL_CONTROL_INDEX_END][channel]

	[waveIdx, indexIdx] = IDX_GetCurrentSets(panelTitle, channelType, channel)

	if(last > first)
		if(waveIdx < last)
			waveIdx += 1
		else
			waveIdx = first
		endif
	elseif(last < first)
		if(waveIdx > last)
			waveIdx -= 1
		else
			waveIdx = first
		endif
	endif

	ctrl = GetPanelControl(channel, channelType, CHANNEL_CONTROL_WAVE)
	SetPopupMenuIndex(panelTitle, ctrl, waveIdx)
	WAVE stimsets = IDX_GetStimsets(panelTitle, channel, channelType)
	DAG_Update(panelTitle, ctrl, val = waveIdx, str = IDX_GetSingleStimset(stimsets, waveIdx))
End

/// @brief Sum of the largest sets for each indexing step
Function IDX_MaxSweepsLockedIndexing(panelTitle)
	string panelTitle

	variable i, maxSteps
	variable MaxCycleIndexSteps = max(IDX_MaxSets(panelTitle, CHANNEL_TYPE_DAC), \
									  IDX_MaxSets(panelTitle, CHANNEL_TYPE_TTL)) + 1

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
	string setName
	variable i

	WAVE status = DAG_GetChannelState(panelTitle, channelType)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!status[i])
			continue
		endif

		[ListStartNo, ListEndNo] = IDX_GetCurrentSets(panelTitle, channelType, i)

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

/// @brief Return the 0-based popup menu indizes of the current WAVE/INDEX_END stimsets
static Function [variable waveIdx, variable indexIdx] IDX_GetCurrentSets(string panelTitle, variable channelType, variable channelNumber)

	string lbl

	lbl = GetSpecialControlLabel(channelType, CHANNEL_CONTROL_WAVE)
	waveIdx = DAG_GetNumericalValue(panelTitle, lbl, index = channelNumber)

	lbl = GetSpecialControlLabel(channelType, CHANNEL_CONTROL_INDEX_END)
	indexIdx = DAG_GetNumericalValue(panelTitle, lbl, index = channelNumber)

	return [waveIdx, indexIdx]
End

/// @brief Return the number of sets on the active channel with the most sets.
static Function IDX_MaxSets(panelTitle, channelType)
	string panelTitle
	variable channelType

	variable i, waveIdx, indexIdx, MaxSets

	WAVE status = DAG_GetChannelState(panelTitle, channelType)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!status[i])
			continue
		endif

		[waveIdx, indexIdx] = IDX_GetCurrentSets(panelTitle, channelType, i)

		MaxSets = max(MaxSets, abs(indexIdx - waveIdx))
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

	WAVE statusDAFiltered = DC_GetFilteredChannelState(panelTitle, DATA_ACQUISITION_MODE, CHANNEL_TYPE_DAC, DAQChannelType = DAQ_CHANNEL_TYPE_DAQ)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusDAFiltered[i])
			continue
		endif

		MaxNoOfSweeps = max(MaxNoOfSweeps, IDX_NumberOfSweepsAcrossSets(panelTitle, i, 0, IndexOverRide))
	endfor

	WAVE statusTTLFiltered = DC_GetFilteredChannelState(panelTitle, DATA_ACQUISITION_MODE, CHANNEL_TYPE_TTL, DAQChannelType = DAQ_CHANNEL_TYPE_DAQ)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusTTLFiltered[i])
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

	WAVE statusDAFiltered = DC_GetFilteredChannelState(panelTitle, DATA_ACQUISITION_MODE, CHANNEL_TYPE_DAC, DAQChannelType = DAQ_CHANNEL_TYPE_DAQ)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusDAFiltered[i])
			continue
		endif

		MinNoOfSweeps = min(MinNoOfSweeps, IDX_NumberOfSweepsAcrossSets(panelTitle, i, CHANNEL_TYPE_DAC, 1))
	endfor

	WAVE statusTTLFiltered = DC_GetFilteredChannelState(panelTitle, DATA_ACQUISITION_MODE, CHANNEL_TYPE_TTL, DAQChannelType = DAQ_CHANNEL_TYPE_DAQ)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusTTLFiltered[i])
			continue
		endif

		MinNoOfSweeps = min(MinNoOfSweeps, IDX_NumberOfSweepsAcrossSets(panelTitle, i, CHANNEL_TYPE_TTL, 1))
	endfor

	return MinNoOfSweeps == inf ? 0 : MinNoOfSweeps
End

/// @brief Returns a 1D textwave of selected set names
/// @param panelTitle panel
/// @param channel channel
/// @param channelType  CHANNEL_TYPE_DAC or CHANNEL_TYPE_TTL
/// @param lockedIndexing defaults to false, true returns just the DAC/TTL setname
///
/// Constants are defined at @ref ChannelTypeAndControlConstants
Function/WAVE IDX_GetSetsInRange(panelTitle, channel, channelType, lockedIndexing)
	string panelTitle
	variable channel, channelType, lockedIndexing

	variable listOffset, first, last, indexStart, indexEnd
	string waveCtrl, lastCtrl, list, msg

	sprintf msg, "channel %d, channelType %d, lockedIndexing %d", channel, channelType, lockedIndexing
	DEBUGPRINT(msg)

	// Additional entries not in menuExp: None
	listOffset = 1

	WAVE/T stimsets = IDX_GetStimsets(panelTitle, channel, channelType)

	waveCtrl = GetSpecialControlLabel(channelType, CHANNEL_CONTROL_WAVE)
	first = DAG_GetNumericalValue(panelTitle, waveCtrl, index = channel) - ListOffset

	lastCtrl = GetSpecialControlLabel(channelType, CHANNEL_CONTROL_INDEX_END)
	last = DAG_GetNumericalValue(panelTitle, lastCtrl, index = channel) - ListOffset

	if(lockedIndexing || !DAG_GetNumericalValue(panelTitle, "Check_DataAcq_Indexing"))
		return DuplicateSubRange(stimsets, first, first)
	endif

	[indexStart, indexEnd] = MinMax(first, last)

	 // - None - is selected
	if(indexStart < 0 || indexEnd < 0)
		Make/N=0/T/FREE result
		return result
	endif

	sprintf msg, "indexStart %d, indexEnd %d", indexStart, indexEnd
	DEBUGPRINT(msg)

	return DuplicateSubRange(stimsets, indexStart, indexEnd)
End

/// @brief Determine the number of sweeps for a DA or TTL channel
static Function IDX_NumberOfSweepsAcrossSets(panelTitle, channel, channelType, lockedIndexing)
	string panelTitle
	variable channel, channelType, lockedIndexing

	variable numSweeps, numEntries, i
	string setList

	WAVE/T stimsets = IDX_GetSetsInRange(panelTitle, channel, channelType, lockedIndexing)

	numEntries = DimSize(stimsets, ROWS)
	for(i = 0; i < numEntries; i += 1)
		numSweeps += IDX_NumberOfSweepsInSet(stimsets[i])
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

static Function IDX_ApplyUnLockedIndexing(panelTitle, count)
	string panelTitle
	variable count

	variable i, update

	WAVE statusDAFiltered = DC_GetFilteredChannelState(panelTitle, DATA_ACQUISITION_MODE, CHANNEL_TYPE_DAC, DAQChannelType = DAQ_CHANNEL_TYPE_DAQ)
	WAVE statusTTLFiltered = DC_GetFilteredChannelState(panelTitle, DATA_ACQUISITION_MODE, CHANNEL_TYPE_TTL, DAQChannelType = DAQ_CHANNEL_TYPE_DAQ)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusDAFiltered[i])
			continue
		endif

		if(IDX_DetIfCountIsAtSetBorder(panelTitle, count, i, CHANNEL_TYPE_DAC) == 1)
			update = 1
			IDX_IndexSingleChannel(panelTitle, CHANNEL_TYPE_DAC, i)
		endif
	endfor

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusTTLFiltered[i])
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
	variable i, first, last, minimum, maximum

	WAVE indexingStorageWave = GetIndexingStorageWave(panelTitle)
	first = indexingStorageWave[channelType][%CHANNEL_CONTROL_WAVE][channelNumber]
	last  = indexingStorageWave[channelType][%CHANNEL_CONTROL_INDEX_END][channelNumber]

	ASSERT(first != last, "Unexpected combo")
	[minimum, maximum] = MinMax(first, last)

	WAVE stimsets = IDX_GetStimsets(panelTitle, channelNumber, channelType)

	for(i = minimum; i <= maximum; i += 1)
		totalListSteps += IDX_NumberOfSweepsInSet(IDX_GetSingleStimset(stimsets, i))
	endfor

	return totalListSteps
End

Function IDX_UnlockedIndexingStepNo(panelTitle, channelNumber, channelType, count)
	string paneltitle
	variable channelNumber, channelType, count

	variable i, stepsInSummedSets, totalListSteps, direction
	variable first, last

	WAVE indexingStorageWave = GetIndexingStorageWave(panelTitle)
	first = indexingStorageWave[channelType][%CHANNEL_CONTROL_WAVE][channelNumber]
	last  = indexingStorageWave[channelType][%CHANNEL_CONTROL_INDEX_END][channelNumber]

	WAVE stimsets = IDX_GetStimsets(panelTitle, channelNumber, channelType)
	totalListSteps = IDX_TotalIndexingListSteps(panelTitle, channelNumber, channelType)
	ASSERT(TotalListSteps > 0, "Expected strictly positive value")
	ASSERT(first != last, "Unexpected combo")

	count     = mod(count, totalListSTeps)
	direction = first < last ? +1 : -1

	for(i = 0; stepsInSummedSets <= count; i += direction)
		stepsInSummedSets += IDX_NumberOfSweepsInSet(IDX_GetSingleStimset(stimsets, first + i))
	endfor
	stepsInSummedSets -= IDX_NumberOfSweepsInSet(IDX_GetSingleStimset(stimsets, first + i - direction))

	return count - StepsInSummedSets
end

static Function IDX_DetIfCountIsAtSetBorder(panelTitle, count, channelNumber, channelType)
	string panelTitle
	variable count, channelNumber, channelType

	variable i, stepsInSummedSets, totalListSteps, direction
	variable first, last

	WAVE indexingStorageWave = GetIndexingStorageWave(panelTitle)
	first = indexingStorageWave[channelType][%CHANNEL_CONTROL_WAVE][channelNumber]
	last  = indexingStorageWave[channelType][%CHANNEL_CONTROL_INDEX_END][channelNumber]

	WAVE stimsets = IDX_GetStimsets(panelTitle, channelNumber, channelType)
	TotalListSteps = IDX_TotalIndexingListSteps(panelTitle, ChannelNumber, channelType)
	ASSERT(TotalListSteps > 0, "Expected strictly positive value")
	ASSERT(first != last, "Unexpected combo")

	count = (mod(count, totalListSteps) == 0 ? totalListSteps : mod(count, totalListSTeps))
	direction = first < last ? +1 : -1

	for(i = 0; stepsInSummedSets <= count; i += direction)
		stepsInSummedSets += IDX_NumberOfSweepsInSet(IDX_GetSingleStimset(stimsets, first + i))

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
	list = GetUserData(panelTitle, ctrl, USER_DATA_MENU_EXP)
	WAVE/T stimsets = ListToTextWave(list, ";")

	return stimsets
End

/// @brief Return the stimset from the list of stimsets
///        returned by IDX_GetStimsets()
///
/// @param listWave  list of stim sets returned by IDX_GetStimsets()
/// @param idx       0-based index
/// @param allowNone [optional, defaults to false] Return the `NONE` stimset for idx `0`.
///                  Not allowed during DAQ.
static Function/S IDX_GetSingleStimset(listWave, idx, [allowNone])
	WAVE/T listWave
	variable idx, allowNone

	if(ParamIsDefault(allowNone))
		allowNone = 0
	else
		allowNone = !!allowNone
	endif

	if(allowNone && idx == 0)
		return NONE
	endif

	// 1 because:
	// none is not part of MenuExp
	string setName = listWave[idx - 1]
	ASSERT(!IsEmpty(setName), "Unexpected empty set")

	return setName
End

Function IDX_HandleIndexing(string panelTitle)

	variable i, indexing, indexingLocked, activeSetCountMax, numFollower, followerActiveSetCount
	string followerPanelTitle

	indexing = DAG_GetNumericalValue(panelTitle, "Check_DataAcq_Indexing")

	if(!indexing)
		return NaN
	endif

	indexingLocked = DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_IndexingLocked")

	NVAR count = $GetCount(panelTitle)
	NVAR activeSetCount = $GetActiveSetCount(panelTitle)

	if(indexingLocked && activeSetcount == 0)
		IDX_IndexingDoIt(panelTitle)
	elseif(!indexingLocked)
		IDX_ApplyUnLockedIndexing(panelTitle, count)
	endif

	if(DeviceHasFollower(panelTitle))

		activeSetCountMax = activeSetCount

		SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)
		numFollower = ItemsInList(listOfFollowerDevices)
		for(i = 0; i < numFollower; i += 1)
			followerPanelTitle = StringFromList(i, listOfFollowerDevices)
			NVAR followerCount = $GetCount(followerPanelTitle)
			followerCount += 1

			RA_StepSweepsRemaining(followerPanelTitle)

			if(indexing)
				if(indexingLocked && activeSetCount == 0)
					IDX_IndexingDoIt(followerPanelTitle)
					followerActiveSetCount = IDX_CalculcateActiveSetCount(followerPanelTitle)
					activeSetCountMax = max(activeSetCountMax, followerActiveSetCount)
				elseif(!indexingLocked)
					// channel indexes when set has completed all its steps
					IDX_ApplyUnLockedIndexing(followerPanelTitle, count)
					followerActiveSetCount = IDX_CalculcateActiveSetCount(followerPanelTitle)
					activeSetCountMax = max(activeSetCountMax, followerActiveSetCount)
				endif
			endif
		endfor

		if(indexing)
			// set maximum on leader and all followers
			NVAR activeSetCount = $GetActiveSetCount(panelTitle)
			activeSetCount = activeSetCountMax

			for(i = 0; i < numFollower; i += 1)
				followerPanelTitle = StringFromList(i, listOfFollowerDevices)

				NVAR activeSetCount = $GetActiveSetCount(followerPanelTitle)
				activeSetCount = activeSetCountMax
			endfor
		endif
	endif
End
