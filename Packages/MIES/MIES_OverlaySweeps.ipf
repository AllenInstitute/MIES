#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

Menu "TracePopup"
	"Ignore Headstage in Overlay Sweeps", /Q, OVS_IgnoreHeadstageInOverlay()
End

/// @brief This user trace menu function allows the user to select a trace
///        in overlay sweeps mode which should be ignored.
Function OVS_IgnoreHeadstageInOverlay()
	string graph, trace, extPanel, str, folder
	variable headstage, sweepNo, index

	GetLastUserMenuInfo
	graph = S_graphName
	trace = S_traceName

	extPanel = BSP_GetPanel(graph)

	if(!WindowExists(graph))
		printf "Context menu option \"%s\" is only useable for overlay sweeps.\r", S_Value
		ControlWindowToFront()
		return NaN
	endif

	sweepNo = str2num(TUD_GetUserData(graph, trace, "sweepNumber"))

	if(!IsValidSweepNumber(sweepNo))
		printf "Could not extract sweep number information from trace \"%s\".\r", trace
		ControlWindowToFront()
		return NaN
	endif

	headstage = str2num(TUD_GetUserData(graph, trace, "headstage"))

	if(!IsFinite(headstage))
		printf "Ignoring trace \"%s\" as it is not associated with a headstage.\r", trace
		ControlWindowToFront()
		return NaN
	endif

	sprintf str, "sweepNo=%d, headstage=%d", sweepNo, headstage
	DEBUGPRINT(str)

	// only set for sweepbrowser graphs
	folder = GetUserData(graph, "", "folder")

	if(!IsEmpty(folder))
		WAVE traceWave = $TUD_GetUserData(graph, trace, "fullPath")
		DFREF sweepDataDFR = GetWavesDataFolderDFR(traceWave)
		index = SB_GetIndexFromSweepDataPath(graph, sweepDataDFR)
		OVS_AddToIgnoreList(extPanel, headstage, index=index)
	else
		OVS_AddToIgnoreList(extPanel, headstage, sweepNo=sweepNo)
	endif
End

/// @brief Return a list of choices for the sweep selection popup
///
/// Includes a unique list of the DA stimsets of all available sweeps
Function/S OVS_GetSweepSelectionChoices(win)
	string win

	if(!OVS_IsActive(win))
		return NONE
	endif
	DFREF dfr = OVS_GetFolder(win)

	WAVE/T sweepSelChoices = GetOverlaySweepSelectionChoices(dfr)

	Duplicate/FREE/R=[][][0]/T sweepSelChoices, sweepSelecChoicesDAStimSets

	Make/FREE/T/N=0 dupsRemovedDAStimSets
	FindDuplicates/Z/RT=dupsRemovedDAStimSets sweepSelecChoicesDAStimSets

	Duplicate/FREE/R=[][][1]/T sweepSelChoices, sweepSelecChoicesTTLStimSets

	Make/FREE/T/N=0  dupsRemovedTTLStimSets
	FindDuplicates/Z/RT=dupsRemovedTTLStimSets sweepSelecChoicesTTLStimSets

	Duplicate/FREE/R=[][][2]/T sweepSelChoices, sweepSelecChoicesClamp

	Make/FREE/T/N=0 dupsRemovedStimSetsClamp
	FindDuplicates/Z/RT=dupsRemovedStimSetsClamp sweepSelecChoicesClamp

	return NONE + ";All;\\M1(-;\\M1(DA Stimulus Sets;"             \
				+ TextWaveToList(dupsRemovedDAStimSets, ";")       \
				+ "\\M1(TTL Stimulus Sets;"                        \
				+ TextWaveToList(dupsRemovedTTLStimSets, ";")      \
				+ "\\M1(-;\\M1(DA Stimulus Sets and Clamp Mode;"   \
				+ TextWaveToList(dupsRemovedStimSetsClamp, ";")
End

/// @brief Return the datafolder reference to the folder storing the listbox and selection wave
///
/// Requires the user data `PANEL_FOLDER` of the BrowserSettings panel
///
/// @return a valid DFREF or an invalid one in case the external panel could not be found
Function/DF OVS_GetFolder(win)
	string win

	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)
	if(!DataFolderExistsDFR(dfr))
		DebugPrint("OVS Folder does not exist")
		return $""
	endif

	return dfr
End

/// @brief Update the overlay sweep waves
///
/// Must be called after the sweeps changed.
Function OVS_UpdatePanel(win)
	string win

	variable i, numEntries, sweepNo, lastEntry, newCycleHasStartedRAC, newCycleHasStartedSCI
	string extPanel

	extPanel = BSP_GetPanel(win)
	WAVE/Z sweeps = GetPlainSweepList(win)

	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)

	WAVE/T listBoxWave           = GetOverlaySweepsListWave(dfr)
	WAVE listBoxSelWave          = GetOverlaySweepsListSelWave(dfr)
	WAVE/T sweepSelectionChoices = GetOverlaySweepSelectionChoices(dfr)

	WAVE/WAVE allNumericalValues = BSP_GetNumericalValues(win)
	WAVE/WAVE allTextualValues   = BSP_GetTextualValues(win)

	if(!WaveExists(sweeps))
		Redimension/N=(0, -1, -1) listBoxWave, listBoxSelWave, sweepSelectionChoices
		return NaN
	endif

	numEntries = DimSize(sweeps, ROWS)
	Redimension/N=(numEntries, -1, -1) listBoxWave, listBoxSelWave, sweepSelectionChoices

	MultiThread listBoxWave[][%Sweep] = num2str(sweeps[p])

	if(OVS_IsActive(win) && GetCheckBoxState(extPanel, "check_overlaySweeps_disableHS"))
		listBoxSelWave[][%Headstages] = SetBit(listBoxSelWave[p][%Headstages], LISTBOX_CELL_EDITABLE)
	else
		listBoxSelWave[][%Headstages] = ClearBit(listBoxSelWave[p][%Headstages], LISTBOX_CELL_EDITABLE)
	endif

	for(i = 0; i < numEntries; i += 1)
		WAVE/T stimsets = GetLastSetting(allTextualValues[i], sweeps[i], STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
		sweepSelectionChoices[i][][%Stimset] = stimsets[q]
		WAVE/T/Z TTLStimSets = GetTTLstimSets(allNumericalValues[i], allTextualValues[i], sweeps[i])
		if(WaveExists(TTLStimSets))
			sweepSelectionChoices[i][][%TTLStimSet] = TTLStimSets[q]
		else
			sweepSelectionChoices[i][][%TTLStimSet] = ""
		endif

		WAVE/Z clampMode = GetLastSetting(allNumericalValues[i], sweeps[i], "Clamp Mode", DATA_ACQUISITION_MODE)

		if(!WaveExists(clampMode))
			WAVE/Z clampMode = GetLastSetting(allNumericalValues[i], sweeps[i], "Operating Mode", DATA_ACQUISITION_MODE)
			ASSERT(WaveExists(clampMode), "Labnotebook is too old for NWB export.")
		endif

		sweepSelectionChoices[i][][%StimsetAndClampMode] = SelectString(IsFinite(clampMode[q]), "", stimsets[q] + " (" + ConvertAmplifierModeShortStr(clampMode[q]) + ")")
	endfor

	lastEntry = numEntries - 1

	if(GetCheckBoxState(extPanel, "check_ovs_clear_on_new_ra_cycle"))
		WAVE RACSweeps = AFH_GetSweepsFromSameRACycle(allNumericalValues[lastEntry], sweeps[lastEntry])
		newCycleHasStartedRAC = WaveExists(RACSweeps) && DimSize(RACSweeps, ROWS) == 1
	endif
	if(GetCheckBoxState(extPanel, "check_ovs_clear_on_new_stimset_cycle"))
		Make/FREE/WAVE/N=(NUM_HEADSTAGES) sweepsInCycleForHS = AFH_GetSweepsFromSameSCI(allNumericalValues[lastEntry], sweeps[lastEntry], p)
		Make/FREE/N=(NUM_HEADSTAGES) SCISweeps = WaveExists(sweepsInCycleForHS[p]) && DimSize(sweepsInCycleForHS[p], ROWS) == 1
		newCycleHasStartedSCI = IsFinite(GetRowIndex(SCISweeps, val = 1))
	endif

	if(newCycleHasStartedRAC || newCycleHasStartedSCI)
		listBoxSelWave[][%Sweep] = LISTBOX_CHECKBOX
		listBoxSelWave[lastEntry][%Sweep] = LISTBOX_CHECKBOX | LISTBOX_CHECKBOX_SELECTED
	else
		listBoxSelWave[][%Sweep] = listBoxSelWave[p] & LISTBOX_CHECKBOX_SELECTED ? LISTBOX_CHECKBOX | LISTBOX_CHECKBOX_SELECTED : LISTBOX_CHECKBOX
	endif
End

/// @brief Return the selected sweeps (either indizes or the real sweep numbers)
///
/// @param win  window (databrowser or sweepbrowser)
/// @param mode sweep property
///           -  #OVS_SWEEP_SELECTION_INDEX
///           -  #OVS_SWEEP_SELECTION_SWEEPNO
///           -  #OVS_SWEEP_ALL_SWEEPNO
///
/// @return invalid wave reference in case nothing is selected or numeric indizes/sweep numbers depending on mode parameter
Function/WAVE OVS_GetSelectedSweeps(win, mode)
	string win
	variable mode

	ASSERT(mode == OVS_SWEEP_SELECTION_INDEX || \
	       mode == OVS_SWEEP_SELECTION_SWEEPNO || \
	       mode == OVS_SWEEP_ALL_SWEEPNO, "Invalid mode")

	DFREF dfr = OVS_GetFolder(win)

	if(mode == OVS_SWEEP_ALL_SWEEPNO)
		return GetPlainSweepList(win)
	endif

	// SWEEP_SELECTION_* modes
	if(!OVS_IsActive(win))
		return $""
	endif

	WAVE/T listboxWave  = GetOverlaySweepsListWave(dfr)
	WAVE listboxSelWave = GetOverlaySweepsListSelWave(dfr)

	Extract/INDX/FREE listboxSelWave, selectedSweepsIndizes, listboxSelWave & LISTBOX_CHECKBOX_SELECTED

	if(DimSize(selectedSweepsIndizes, ROWS) == 0)
		return $""
	endif

	if(mode == OVS_SWEEP_SELECTION_SWEEPNO)
		Make/FREE/N=(DimSize(selectedSweepsIndizes, ROWS)) selectedSweeps = str2num(listBoxWave[selectedSweepsIndizes[p]])
		return selectedSweeps
	endif

	return selectedSweepsIndizes
End

/// @brief Change the selection state of the the given sweep in the listbox wave
///
/// Triggers a update for the affected sweep.
///
/// @param win      panel
/// @param sweepNo  [optional] sweep number
/// @param index    [optional] index into the listbox wave
/// @param newState new checkbox state of the given sweep.
///
/// One of `sweepNo`/`index` is required.
Function OVS_ChangeSweepSelectionState(win, newState, [sweepNo, index])
	string win
	variable sweepNo, index, newState

	if(!OVS_IsActive(win))
		return NaN
	endif

	// coerce to 0/1
	newState = !!newState

	DFREF dfr = OVS_GetFolder(win)
	WAVE/T listboxWave  = GetOverlaySweepsListWave(dfr)
	WAVE listboxSelWave = GetOverlaySweepsListSelWave(dfr)

	if(!ParamIsDefault(sweepNo))
		FindValue/TEXT=num2str(sweepNo)/TXOP=4 listboxWave
		index = V_Value
	elseif(!ParamIsDefault(index))
		// do nothing
	else
		ASSERT(0, "Requires one of index or sweepNo")
	endif

	if(index < 0 || index >= DimSize(listBoxWave, ROWS) || !IsFinite(index))
		return NaN
	endif

	if(newState)
		listboxSelWave[index] = SetBit(listboxSelWave[index], LISTBOX_CHECKBOX_SELECTED)
	else
		listboxSelWave[index] = ClearBit(listboxSelWave[index], LISTBOX_CHECKBOX_SELECTED)
	endif

	UpdateSweepInGraph(win, index)
	PostPlotTransformations(win)
End

/// checks if OVS is active.
Function OVS_IsActive(win)
	string win

	return BSP_IsActive(win, MIES_BSP_OVS)
End

/// @brief Add `headstage` to the ignore list of the given `sweepNo/index`
static Function OVS_AddToIgnoreList(win, headstage, [sweepNo, index])
	string win
	variable headstage, sweepNo, index

	if(!OVS_IsActive(win))
		return NaN
	endif

	DFREF dfr = OVS_GetFolder(win)
	WAVE/T listboxWave = GetOverlaySweepsListWave(dfr)

	if(!ParamIsDefault(sweepNo))
		FindValue/TEXT=num2str(sweepNo)/TXOP=4 listboxWave
		index = V_Value
	elseif(!ParamIsDefault(index))
		// do nothing
	else
		ASSERT(0, "Requires one of index or sweepNo")
	endif

	if(index < 0 || index >= DimSize(listBoxWave, ROWS) || !IsFinite(index))
		ASSERT(0, "Invalid sweepNo/index")
	endif

	listboxWave[index][%headstages] = AddListItem(num2str(headstage), listboxWave[index][%headstages], ";", inf)
	UpdateSweepInGraph(win, index)
	PostPlotTransformations(win)
End

/// @brief Parse the ignore list of the given sweep.
///
///
/// The expected format of the ignore list entries is a semicolon (";") separated
/// list of subranges (without the possibility of denoting the step size).
///
/// Examples:
/// - 0 (ignore HS 0)
/// - 1,3;0 (ignore HS 0 to 3)
/// - * (ignore all headstages)
///
/// @param[in] win     name of mainPanel
/// @param[in] sweepNo [optional] search sweepNo in list to get index
/// @param[in] index   [optional] specify sweep directly by index
/// @return free wave of size `NUM_HEADSTAGES` denoting with 0/1 the active state
///         of the headstage
Function/WAVE OVS_ParseIgnoreList(win, [sweepNo, index])
	string win
	variable sweepNo, index

	variable numEntries, i, start, stop, step
	string ignoreList, subRangeStr, extPanel

	if(!OVS_IsActive(win))
		return $""
	endif

	extPanel =  BSP_GetPanel(win)
	if(!GetCheckBoxState(extPanel, "check_overlaySweeps_disableHS"))
		return $""
	endif

	DFREF dfr = OVS_GetFolder(win)
	WAVE/T listboxWave = GetOverlaySweepsListWave(dfr)

	if(!ParamIsDefault(sweepNo))
		FindValue/TEXT=num2str(sweepNo)/TXOP=4 listboxWave
		index = V_Value
	elseif(!ParamIsDefault(index))
		// do nothing
	else
		ASSERT(0, "Requires one of index or sweepNo")
	endif

	if(index < 0 || index >= DimSize(listBoxWave, ROWS) || !IsFinite(index))
		ASSERT(index != -1, "Invalid sweepNo/index")
	endif

	ignoreList = listboxWave[index][%headstages]
	numEntries = ItemsInList(ignoreList)

	Make/FREE/N=(NUM_HEADSTAGES) activeHS = 1

	for(i = 0; i < numEntries; i += 1)
		subRangeStr = "[" + StringFromList(i, ignoreList) + "]"
		WAVE/Z subrange = ExtractFromSubrange(subRangeStr, 0)

		if(!WaveExists(subrange) || DimSize(subrange, ROWS) != 1)
			printf "Could not parse subrange \"%s\" number %d from sweep %d\r", subRangeStr, i, sweepNo
			ControlWindowToFront()
			continue
		endif

		start = subrange[0][0]
		stop  = subrange[0][1]

		if(start == -1 && stop == -1) // ignore all
			activeHS = 0
			return activeHS
		endif

		if(stop != -1 && (stop < 0 || stop >= NUM_HEADSTAGES))
			printf "Overlay sweeps ignore list invalid for sweep %d", sweepNo
			ControlWindowToFront()
			continue
		elseif(start < 0 || start >= NUM_HEADSTAGES)
			printf "Overlay sweeps ignore list invalid for sweep %d", sweepNo
			ControlWindowToFront()
			continue
		endif

		if(stop == -1)
			activeHS[start, inf]  = 0
		else
			activeHS[start, stop] = 0
		endif
	endfor

	return activeHS
End

Function OVS_CheckBoxProc_HS_Select(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	string win

	switch(cba.eventCode)
		case 2: // mouse up
			win = cba.win

			DFREF dfr = OVS_GetFolder(win)
			WAVE listboxSelWave = GetOverlaySweepsListSelWave(dfr)

			if(cba.checked)
				listBoxSelWave[][%Headstages] = SetBit(listBoxSelWave[p][%Headstages], LISTBOX_CELL_EDITABLE)
			else
				listBoxSelWave[][%Headstages] = ClearBit(listBoxSelWave[p][%Headstages], LISTBOX_CELL_EDITABLE)
			endif

			UpdateSweepPlot(win)
		break
	endswitch

	return 0
End

static Function OVS_HighlightSweep(win, index)
	string win
	variable index

	variable sweepNo, i, numTraces
	string experiment, graph, trace, msg
	STRUCT RGBAColor c

	ASSERT(OVS_IsActive(win), "Highlighting is only supported if OVS is enabled")

	graph = GetMainWindow(win)
	WAVE/T traces = TUD_GetUserDataAsWave(graph, "traceName", keys = {"traceType"}, values = {"Sweep"})

	if(IsFinite(index))
		[sweepNo, experiment] = OVS_GetSweepAndExperiment(win, index)
		WAVE/T/Z highlightTraces = TUD_GetUserDataAsWave(graph, "traceName", keys = {"traceType", "sweepNumber", "experiment"}, values = {"Sweep", num2str(sweepNo), experiment})

		if(!WaveExists(highlightTraces))
			// the to-be-highlighted traces are not plotted
			return NaN
		endif
	endif

	// index >= 0:
	// adjust alpha of all traces not belonging to (experiment, sweepNo)
	//
	// index NaN:
	// reset alpha of all traces

	numTraces = DimSize(traces, ROWS)
	for(i = 0; i < numTraces; i += 1)
		trace = traces[i]
		[c] = ParseColorSpec(TUD_GetUserData(graph, trace, "TRACECOLOR"))

		if(IsFinite(index) && IsNaN(GetRowIndex(highlightTraces, str = trace)))
			c.alpha = c.alpha * 0.05
		endif

		ModifyGraph/W=$graph rgb($trace)=(c.red, c.green, c.blue, c.alpha)

		sprintf msg, "trace: %s, (%d, %d, %d, %d)\r", trace, c.red, c.green, c.blue, c.alpha
		DEBUGPRINT(msg)
	endfor
End

/// @brief Return the sweep number and experiment name for the given list index
Function [variable sweepNo, string experiment] OVS_GetSweepAndExperiment(string win, variable index)

	string graph

	if(!BSP_HasBoundDevice(win))
		return [NaN, ""]
	endif

	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)

	WAVE/T listBoxWave = GetOverlaySweepsListWave(dfr)

	if(BSP_IsDataBrowser(win))
		if(index < 0 || index >= DimSize(listBoxWave, ROWS) || !IsFinite(index))
			return [NaN, ""]
		endif

		return [str2num(listBoxWave[index][%Sweep]), GetExperimentName()]
	endif

	// SweepBrowser
	graph = GetMainWindow(win)
	DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(graph)
	WAVE/T sweepMap = GetSweepBrowserMap(sweepBrowserDFR)

	if(index < 0 || index >= DimSize(sweepMap, ROWS) || !IsFinite(index))
		return [NaN, ""]
	endif

	return [str2num(sweepMap[index][%Sweep]), sweepMap[index][%FileName]]
End

/// @brief Change the selected sweep according to one of the popup menu options
static Function OVS_ChangeSweepSelection(win, choiceString)
	string win, choiceString

	variable i, j, numEntries, numLayers, offset, step
	string extPanel

	ASSERT(OVS_IsActive(win), "Selecting sweeps is only supported if OVS is enabled")

	extPanel  = BSP_GetPanel(win)

	DFREF dfr = OVS_GetFolder(win)
	WAVE listboxSelWave = GetOverlaySweepsListSelWave(dfr)

	if(DimSize(listboxSelWave, ROWS) == 0)
		return NaN
	endif

	WAVE/T sweepSelectionChoices = GetOverlaySweepSelectionChoices(dfr)

	offset = GetSetVariable(extPanel, "setvar_overlaySweeps_offset")
	step   = GetSetVariable(extPanel, "setvar_overlaySweeps_step")

	// deselect all
	listboxSelWave[][%Sweep] = listboxSelWave[p][q] & ~LISTBOX_CHECKBOX_SELECTED

	if(!cmpstr(choiceString, NONE))
		// nothing to do
	elseif(!cmpstr(choiceString, "All"))
		listboxSelWave[offset, inf;step][%Sweep] = listboxSelWave[p][q] | LISTBOX_CHECKBOX_SELECTED
	else
		numLayers = DimSize(sweepSelectionChoices, LAYERS)
		for(i = 0; i < NUM_HEADSTAGES; i += 1)
			for(j = 0; j < numLayers; j += 1)
				Duplicate/FREE/R=[][][j] sweepSelectionChoices, sweepSelectionChoicesSingle
				WAVE/Z indizes = FindIndizes(sweepSelectionChoicesSingle, col=i, str=choiceString)
				if(!WaveExists(indizes))
					continue
				endif

				numEntries = DimSize(indizes, ROWS)
				for(j = offset; j < numEntries; j += step)
					listboxSelWave[indizes[j]][%Sweep] = listboxSelWave[p][q] | LISTBOX_CHECKBOX_SELECTED
				endfor
			endfor
		endfor
	endif

	UpdateSweepPlot(win)
End

Function OVS_MainListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	string win

	switch(lba.eventCode)
		case 6: //begin edit
			win = lba.win
			OVS_HighlightSweep(win, lba.row)
			break
		case 7:  // end edit
			win = lba.win
			OVS_HighlightSweep(win, NaN)
			if(lba.selWave[lba.row] & LISTBOX_CHECKBOX_SELECTED)
				UpdateSweepInGraph(win, lba.row)
				PostPlotTransformations(win)
			endif
			break
		case 13: // checkbox clicked
			win = lba.win
			if(lba.selWave[lba.row] & LISTBOX_CHECKBOX_SELECTED)
				AddSweepToGraph(win, lba.row)
			else
				RemoveSweepFromGraph(win, lba.row)
			endif
			PostPlotTransformations(win)
			break
	endswitch

	return 0
End

Function OVS_PopMenuProc_Select(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch(pa.eventCode)
		case 2: // mouse up
			OVS_ChangeSweepSelection(pa.win, pa.popStr)
			break
	endswitch

	return 0
End

Function OVS_SetVarProc_SelectionRange(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	string popStr, win

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			win = sva.win
			popStr = GetPopupMenuString(win, "popup_overlaySweeps_select")
			OVS_ChangeSweepSelection(win, popStr)
			break
	endswitch

	return 0
End
