#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_AR
#endif

/// @file MIES_ArtefactRemoval.ipf
/// @brief __AR__ Functions related to artefact removal

static Constant AR_MIN_RANGE_FACTOR = 0.1

/// @brief Return a free 2D wave with artefact positions and the corresponding
///        DA channel from which it originated.
///
/// Columns:
/// - Artefact position [ms]
/// - DAC
/// - ADC
/// - Headstage
static Function/WAVE AR_ComputeRanges(DFREF sweepDFR, variable sweepNo, WAVE numericalValues)

	variable i, dac, adc
	variable level, index, total
	string key

	key = CA_ArtefactRemovalRangesKey(sweepDFR, sweepNo)
	WAVE/Z cachedRanges = CA_TryFetchingEntryFromCache(key)
	if(WaveExists(cachedRanges))
		return cachedRanges
	endif

	WAVE statusDAC = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)
	WAVE statusADC = GetLastSetting(numericalValues, sweepNo, "ADC", DATA_ACQUISITION_MODE)
	WAVE statusHS  = GetLastSetting(numericalValues, sweepNo, "Headstage Active", DATA_ACQUISITION_MODE)

	Make/D/FREE/N=(MINIMUM_WAVE_SIZE, 4) ranges = NaN
	SetNumberInWaveNote(ranges, NOTE_INDEX, 0)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		dac = statusDAC[i]
		adc = statusADC[i]

		WAVE wv = GetDAQDataSingleColumnWave(sweepDFR, XOP_CHANNEL_TYPE_DAC, dac)

		WaveStats/Q/M=1 wv
		if(V_max > 0)
			level = V_max * AR_MIN_RANGE_FACTOR

			FindLevels/Q wv, level
			WAVE posLevels = MakeWaveFree($"W_FindLevels")

			index = GetNumberFromWaveNote(ranges, NOTE_INDEX)
			total = index + V_LevelsFound
			EnsureLargeEnoughWave(ranges, indexShouldExist = total, initialValue = NaN)

			ranges[index, total - 1][0] = posLevels[p - index]
			ranges[index, total - 1][1] = dac
			ranges[index, total - 1][2] = adc
			ranges[index, total - 1][3] = i
			SetNumberInWaveNote(ranges, NOTE_INDEX, total)
		endif

		if(V_min < 0)
			level = V_min * AR_MIN_RANGE_FACTOR

			FindLevels/Q wv, level
			WAVE negLevels = MakeWaveFree($"W_FindLevels")

			index = GetNumberFromWaveNote(ranges, NOTE_INDEX)
			total = index + V_LevelsFound
			EnsureLargeEnoughWave(ranges, indexShouldExist = total, initialValue = NaN)

			ranges[index, total - 1][0] = negLevels[p - index]
			ranges[index, total - 1][1] = dac
			ranges[index, total - 1][2] = adc
			ranges[index, total - 1][3] = i
			SetNumberInWaveNote(ranges, NOTE_INDEX, total)
		endif
	endfor

	Redimension/N=(GetNumberFromWaveNote(ranges, NOTE_INDEX), -1) ranges
	Note/K ranges

	CA_StoreEntryIntoCache(key, ranges)

	return ranges
End

static Function AR_UpdatePanel(string device, WAVE ranges, DFREF sweepDFR)

	AR_SetSweepFolder(device, sweepDFR)

	DFREF  dfr          = AR_GetFolder(device)
	WAVE/T listBoxWave  = GetArtefactRemovalListWave(dfr)
	WAVE   artefactWave = GetArtefactRemovalDataWave(dfr)

	Redimension/N=(DimSize(ranges, ROWS), -1) listBoxWave, artefactWave

	MultiThread artefactWave[][] = ranges[p][q]
	AR_UpdateListBoxWave(device)
End

static Function AR_UpdateListBoxWave(string device)

	variable cutoffLength_before, cutoffLength_after
	string extPanel

	extPanel = BSP_GetPanel(device)
	DFREF  dfr          = AR_GetFolder(device)
	WAVE/T listBoxWave  = GetArtefactRemovalListWave(dfr)
	WAVE   artefactWave = GetArtefactRemovalDataWave(dfr)

	cutoffLength_before = GetSetVariable(extPanel, "setvar_cutoff_length_before")
	cutoffLength_after  = GetSetVariable(extPanel, "setvar_cutoff_length_after")

	listBoxWave[][0] = num2str(artefactWave[p][%ArtefactPosition] - cutoffLength_before)
	listBoxWave[][1] = num2str(artefactWave[p][%ArtefactPosition] + cutoffLength_after)
End

/// @brief Remove the traces used for highlightning the to-be-removed ranges
static Function AR_RemoveTraces(string graph)

	string traces, trace
	variable numEntries, i

	traces = AR_GetHighlightTraces(graph)

	numEntries = ItemsInList(traces)
	for(i = 0; i < numEntries; i += 1)
		trace = StringFromList(i, traces)
		RemoveFromGraph/W=$graph $trace
		TUD_RemoveUserData(graph, trace)
	endfor
End

/// @brief Return a list of the traces used for highlightning the to-be-removed ranges
static Function/S AR_GetHighlightTraces(string graph)

	WAVE/Z/T traces = TUD_GetUserDataAsWave(graph, "traceName", keys = {"traceType"}, values = {"ArtefactRemoval"})

	if(!WaveExists(traces))
		return ""
	endif

	return TextWaveToList(traces, ";")
End

Function AR_HighlightArtefactsEntry(string graph)

	string traces, trace, extPanel
	variable numEntries, i, index, row

	extPanel = BSP_GetPanel(graph)

	if(!AR_IsActive(extPanel) || !GetCheckBoxState(extPanel, "check_highlightRanges"))
		return NaN
	endif

	DFREF  dfr          = AR_GetFolder(graph)
	WAVE/T listBoxWave  = GetArtefactRemovalListWave(dfr)
	WAVE   artefactWave = GetArtefactRemovalDataWave(dfr)

	row = GetListBoxSelRow(extPanel, "list_of_ranges")

	if(!IsInteger(row) || row < 0 || row >= DimSize(listBoxWave, ROWS))
		return NaN
	endif

	traces = AR_GetHighlightTraces(graph)

	numEntries = ItemsInList(traces)
	for(i = 0; i < numEntries; i += 1)
		trace = StringFromList(i, traces)
		index = str2num(TUD_GetUserData(graph, trace, "AR_INDEX"))

		if(row == index)
			ModifyGraph/W=$graph rgb($trace)=(1, 39321, 19939, 32768)
			ReorderTraces/W=$graph _front_, {$trace}
		else
			ModifyGraph/W=$graph rgb($trace)=(65535, 0, 0, 32768)
		endif
	endfor
End

static Function AR_HandleRanges(string graph, [variable removeRange])

	variable first, last, substituteValue
	variable i, j, k, traceIndex, numEntries
	string traceName, leftAxis, bottomAxis, extPanel

	extPanel = BSP_GetPanel(graph)

	if(ParamIsDefault(removeRange))
		removeRange = GetCheckboxState(extPanel, "check_auto_remove")
	else
		removeRange = !!removeRange
	endif

	DFREF  dfr          = AR_GetFolder(graph)
	WAVE/T listBoxWave  = GetArtefactRemovalListWave(dfr)
	WAVE   artefactWave = GetArtefactRemovalDataWave(dfr)

	AR_RemoveTraces(graph)

	if(!removeRange && !GetCheckBoxState(extPanel, "check_highlightRanges"))
		return NaN
	endif

	DFREF     sweepDFR = AR_GetSweepFolder(graph)
	WAVE/WAVE ADCs     = GetDAQDataSingleColumnWaves(sweepDFR, XOP_CHANNEL_TYPE_ADC)

	ASSERT(DimSize(listBoxWave, ROWS) == DimSize(artefactWave, ROWS), "Unexpected dimension sizes")

	numEntries = DimSize(listBoxWave, ROWS)
	for(i = 0; i < numEntries; i += 1)
		for(j = 0; j < NUM_AD_CHANNELS; j += 1)

			WAVE/Z AD = ADCs[j]

			if(removeRange && i == 0 && WaveExists(AD))
				AddEntryIntoWaveNoteAsList(AD, NOTE_KEY_ARTEFACT_REMOVAL, str = "true", replaceEntry = 1)
			endif

			if(!WaveExists(AD))
				continue
			endif

			WAVE/Z/T leftAxisMatches = TUD_GetUserDataAsWave(graph, "YAXIS", keys = {"channelType", "channelNumber"}, \
			                                                 values = {"AD", num2str(j)})
			ASSERT(WaveExists(leftAxisMatches) && DimSize(leftAxisMatches, ROWS) >= 1, "Expected one hit")
			leftAxis = leftAxisMatches[0]

			// skip that AD as the range originated from the DA of the same headstage
			if(j == artefactWave[i][%ADC])
				continue
			endif

			first = limit(ScaleToIndex(AD, str2num(listBoxWave[i][0]), ROWS), 0, DimSize(AD, ROWS) - 1)
			last  = limit(ScaleToIndex(AD, str2num(listBoxWave[i][1]), ROWS), 0, DimSize(AD, ROWS) - 1)

			// check if we need a special bottom axis, required for dDAQ viewing
			bottomAxis = leftAxis + "_b"
			GetAxis/W=$graph/Q $bottomAxis
			if(V_flag)
				bottomAxis = "bottom"
			endif

			if(removeRange)
				substituteValue = AD[first]
				AD[first, last] = substituteValue
			else
				sprintf traceName, "%s_HS_%d", GetTraceNamePrefix(traceIndex++), j, i

				AppendToGraph/W=$graph/L=$leftAxis/B=$bottomAxis AD[first, last]/TN=$traceName
				ModifyGraph/W=$graph mode($traceName)=3, marker($traceName)=8
				ModifyGraph/W=$graph msize($traceName)=0.5, rgb($traceName)=(65535, 0, 0, 32768)
				TUD_SetUserData(graph, traceName, "AR_INDEX", num2str(i))
				TUD_SetUserData(graph, traceName, "traceType", "ArtefactRemoval")
			endif
		endfor
	endfor
End

/// @brief Return the datafolder reference to the folder storing the listbox wave and the artefact data wave
///
/// Requires the user data `PANEL_FOLDER` of the external artefact removal panel.
static Function/DF AR_GetFolder(string device)

	if(!AR_IsActive(device))
		return $""
	endif

	return BSP_GetFolder(device, MIES_BSP_PANEL_FOLDER)
End

/// @brief Return the datafolder reference to the folder storing the single 1D sweep waves
///
/// Requires the user data `AR_SWEEPFOLDER` of the external artefact removal panel.
static Function/DF AR_GetSweepFolder(string device)

	if(!AR_IsActive(device))
		return $""
	endif

	return BSP_GetFolder(device, MIES_BSP_AR_SWEEPFOLDER)
End

/// @brief Updates the `AR_SWEEPFOLDER` user data of the artefact removal panel
static Function AR_SetSweepFolder(string device, DFREF sweepDFR)

	BSP_SetFolder(device, sweepDFR, MIES_BSP_AR_SWEEPFOLDER)
End

Function AR_MainListBoxProc(STRUCT WMListboxAction &lba) : ListBoxControl

	string graph

	switch(lba.eventCode)
		case 4: // cell selection
		case 5: // cell selection plus shift key
			graph = GetMainWindow(lba.win)
			AR_HighlightArtefactsEntry(graph)
			break
	endswitch

	return 0
End

Function AR_SetVarProcCutoffLength(STRUCT WMSetVariableAction &sva) : SetVariableControl

	string graph, device

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			device = GetMainWindow(sva.win)
			graph  = GetMainWindow(device)
			AR_UpdateListBoxWave(device)
			AR_HandleRanges(graph)
			break
	endswitch

	return 0
End

Function AR_ButtonProc_RemoveRanges(STRUCT WMButtonAction &ba) : ButtonControl

	string graph, win

	switch(ba.eventCode)
		case 2: // mouse up
			win   = ba.win
			graph = GetMainWindow(win)
			SetCheckBoxState(win, "check_auto_remove", CHECKBOX_SELECTED)
			UpdateSweepPlot(graph)
			SetCheckBoxState(win, "check_auto_remove", CHECKBOX_UNSELECTED)
			break
	endswitch

	return 0
End

Function AR_UpdateTracesIfReq(string graph, DFREF sweepFolder, variable sweepNo)

	string device

	device = GetMainWindow(graph)

	if(!AR_IsActive(device))
		return NaN
	endif

	WAVE/Z numericalValues = BSP_GetLogbookWave(device, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweepNo)
	ASSERT(WaveExists(numericalValues), "Numerical LabNotebook not found.")

	DFREF singleSweepDFR = GetSingleSweepFolder(sweepFolder, sweepNo)
	WAVE  ranges         = AR_ComputeRanges(singleSweepDFR, sweepNo, numericalValues)
	AR_UpdatePanel(device, ranges, singleSweepDFR)
	AR_HandleRanges(graph)
End

Function AR_CheckProc_Update(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	switch(cba.eventCode)
		case 2: // mouse up
			UpdateSweepPlot(cba.win)
			break
	endswitch

	return 0
End

/// checks if AR is active.
Function AR_IsActive(string win)

	return BSP_IsActive(win, MIES_BSP_AR)
End
