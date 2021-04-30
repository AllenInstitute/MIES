#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_OVS
#endif

Menu "TracePopup"
	"Ignore Headstage in Overlay Sweeps", /Q, OVS_IgnoreHeadstageInOverlay()
End

static StrConstant OVS_FULL_UPDATE_NOTE = "FullUpdate"

/// @brief This user trace menu function allows the user to select a trace
///        in overlay sweeps mode which should be ignored.
Function OVS_IgnoreHeadstageInOverlay()
	string graph, trace, extPanel, str, folder
	variable headstage, sweepNo, index

	GetLastUserMenuInfo
	graph = S_graphName
	trace = S_traceName

	extPanel = BSP_GetPanel(graph)

	if(!WindowExists(extPanel))
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

	WAVE/T sweepSelChoices = GetOverlaySweepSelectionChoices(win, dfr)

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
/// @param win        databrowser panel or graph
/// @param fullUpdate [optional, defaults to false] Performs a full update instead
///                   of an incremental one. Selects the first sweep if nothing is selected as well.
///
/// Must be called after the sweeps changed.
Function OVS_UpdatePanel(string win, [variable fullUpdate])

	variable i, numEntries, sweepNoOrIndex, lastEntry, newCycleHasStartedRAC, newCycleHasStartedSCI
	string extPanel, scPanel

	if(ParamIsDefault(fullUpdate))
		fullUpdate = 0
	else
		fullUpdate = !!fullUpdate
	endif

	extPanel = BSP_GetPanel(win)
	WAVE/Z sweeps = GetPlainSweepList(win)

	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)

	WAVE/T sweepSelectionChoices = GetOverlaySweepSelectionChoices(win, dfr, skipUpdate = 1)
	SetNumberInWaveNote(sweepSelectionChoices, NOTE_NEEDS_UPDATE, 1)
	WaveClear sweepSelectionChoices

	WAVE/T listBoxWave    = GetOverlaySweepsListWave(dfr)
	WAVE listBoxSelWave   = GetOverlaySweepsListSelWave(dfr)
	WAVE headstageRemoval = GetOverlaySweepHeadstageRemoval(dfr)

	WAVE updateHandle = OVS_BeginIncrementalUpdate(win, fullUpdate = fullUpdate)

	if(!WaveExists(sweeps))
		Redimension/N=(0, -1, -1) listBoxWave, listBoxSelWave, headstageRemoval
		OVS_EndIncrementalUpdate(win, updateHandle)
		return NaN
	endif

	WAVE/WAVE allNumericalValues = BSP_GetNumericalValues(win)

	numEntries = DimSize(sweeps, ROWS)
	Redimension/N=(numEntries, -1, -1) listBoxWave, listBoxSelWave, headstageRemoval

	MultiThread listBoxWave[][%Sweep] = num2str(sweeps[p])

	if(OVS_IsActive(win) && GetCheckBoxState(extPanel, "check_overlaySweeps_disableHS"))
		listBoxSelWave[][%Headstages] = SetBit(listBoxSelWave[p][%Headstages], LISTBOX_CELL_EDITABLE)
	else
		listBoxSelWave[][%Headstages] = ClearBit(listBoxSelWave[p][%Headstages], LISTBOX_CELL_EDITABLE)
	endif

	lastEntry = numEntries - 1

	if(GetCheckBoxState(extPanel, "check_ovs_clear_on_new_ra_cycle"))
		WAVE/Z RACSweeps = AFH_GetSweepsFromSameRACycle(allNumericalValues[lastEntry], sweeps[lastEntry])
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

	// we select the first sweep when doing a fullUpdate and nothing selected
	if(OVS_IsActive(win) && fullUpdate)
		FindValue/I=(LISTBOX_CHECKBOX | LISTBOX_CHECKBOX_SELECTED)/RMD=[][0] listBoxSelWave
		if(V_Value == -1)
			scPanel = BSP_GetSweepControlsPanel(win)

			if(BSP_IsDataBrowser(win))
				sweepNoOrIndex = GetSetVariable(scPanel, "setvar_SweepControl_SweepNo")
			else
				sweepNoOrIndex = GetPopupMenuIndex(scPanel, "Popup_SweepControl_Selector")
			endif

			listBoxSelWave[sweepNoOrIndex][%Sweep] = SetBit(listBoxSelWave[sweepNoOrIndex][%Sweep], LISTBOX_CHECKBOX_SELECTED)
		endif
	endif

	OVS_EndIncrementalUpdate(win, updateHandle)
End

/// @brief Update the sweep selection choices for the popup menu
///
/// This function is expensive as it iterates over all sweeps.
Function OVS_UpdateSweepSelectionChoices(string win, WAVE/T sweepSelectionChoices)

	variable numEntries, i, needsUpdate

	needsUpdate = GetNumberFromWaveNote(sweepSelectionChoices, NOTE_NEEDS_UPDATE)

	if(!needsUpdate)
		return NaN
	endif

	WAVE/Z sweeps = GetPlainSweepList(win)

	numEntries = WaveExists(sweeps) ? DimSize(sweeps, ROWS) : 0

	if(numEntries > 0)
		WAVE/WAVE allNumericalValues = BSP_GetNumericalValues(win)
		WAVE/WAVE allTextualValues   = BSP_GetTextualValues(win)
	endif

	Redimension/N=(numEntries, -1, -1, -1) sweepSelectionChoices

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

	SetNumberInWaveNote(sweepSelectionChoices, NOTE_NEEDS_UPDATE, 0)
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
/// @param win          panel
/// @param sweepNo      [optional] sweep number
/// @param sweeps       [optional] sweeps to change, can be `$""`
/// @param index        [optional] index into the listbox wave
/// @param newState     new checkbox state of the given sweeps
/// @param invertOthers [optional, default to false] set the other sweeps to !newState if true
///
/// One of `sweepNo`/`index` is required.
Function OVS_ChangeSweepSelectionState(win, newState, [sweepNo, index, sweeps, invertOthers])
	string win
	variable sweepNo, index, newState, invertOthers
	WAVE/Z sweeps

	variable i, numEntries

	if(!OVS_IsActive(win))
		return NaN
	endif

	if(ParamIsDefault(invertOthers))
		invertOthers = 0
	else
		invertOthers = !!invertOthers
	endif

	// coerce to 0/1
	newState = !!newState

	DFREF dfr = OVS_GetFolder(win)
	WAVE/T listboxWave  = GetOverlaySweepsListWave(dfr)
	WAVE listboxSelWave = GetOverlaySweepsListSelWave(dfr)

	if(!ParamIsDefault(sweepNo))
		FindValue/RMD=[][0]/TEXT=num2str(sweepNo)/TXOP=4 listboxWave
		ASSERT(V_Value >= 0, "Could not find sweep")
		Make/FREE/N=(1, 2) indices = {{V_Value}, {0}}
	elseif(!ParamIsDefault(index))
		Make/FREE/N=(1, 2) indices = {{index}, {0}}
		ASSERT(index >= 0 && index < DimSize(listboxWave, ROWS), "Could not find index")
	elseif(!ParamIsDefault(sweeps))
		if(WaveExists(sweeps))
			numEntries = DimSize(sweeps, ROWS)

			Make/FREE/N=(numEntries, 2) indices

			for(i = 0; i < numEntries; i += 1)
				sweepNo = sweeps[i]
				FindValue/RMD=[][0]/TEXT=num2str(sweepNo)/TXOP=4 listboxWave
				ASSERT(V_Value >= 0, "Could not find sweep")
				indices[i][0] = V_Value
			endfor
		endif
	else
		ASSERT(0, "Requires one of index or sweepNo")
	endif

	WAVE updateHandle = OVS_BeginIncrementalUpdate(win)

	if(newState)
		if(invertOthers)
			listboxSelWave[][0] = ClearBit(listboxSelWave[p], LISTBOX_CHECKBOX_SELECTED)
		endif

		if(WaveExists(indices))
			// Indexing with a index wave, indices is 2D
			listboxSelWave[indices] = SetBit(listboxSelWave[p], LISTBOX_CHECKBOX_SELECTED)
		endif
	else
		if(invertOthers)
			listboxSelWave[][] = SetBit(listboxSelWave[p], LISTBOX_CHECKBOX_SELECTED)
		endif

		if(WaveExists(indices))
			listboxSelWave[indices] = ClearBit(listboxSelWave[p], LISTBOX_CHECKBOX_SELECTED)
		endif
	endif

	OVS_EndIncrementalUpdate(win, updateHandle)
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
	OVS_UpdateHeadstageRemoval(win, index)
End

/// @brief Update the OVS headstage removal wave from the listbox entry
static Function OVS_UpdateHeadstageRemoval(string win, variable index)

	DFREF dfr = OVS_GetFolder(win)
	WAVE/T listboxWave = GetOverlaySweepsListWave(dfr)

	WAVE activeHS = OVS_ParseIgnoreList(listboxWave[index][%headstages], str2num(listboxWave[index][%Sweep]))

	WAVE headstageRemoval = GetOverlaySweepHeadstageRemoval(dfr)
	headstageRemoval[index][] = activeHS[q]

	UpdateSweepInGraph(win, index)
	PostPlotTransformations(win, POST_PLOT_FULL_UPDATE)
End

// @brief Return the headstage removal entry for the given sweepNo/index
Function/WAVE OVS_GetHeadstageRemoval(string win, [variable sweepNo, variable index])

	string extPanel

	if(!OVS_IsActive(win))
		return $""
	endif

	extPanel = BSP_GetPanel(win)
	if(!GetCheckBoxState(extPanel, "check_overlaySweeps_disableHS"))
		return $""
	endif

	DFREF dfr = OVS_GetFolder(win)
	WAVE/T listboxWave = GetOverlaySweepsListWave(dfr)
	WAVE headstageRemoval = GetOverlaySweepHeadstageRemoval(dfr)

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

	Duplicate/FREE/RMD=[index][] headstageRemoval, activeHS
	Redimension/E=1/N=(NUM_HEADSTAGES) activeHS

	return activeHS
End

/// @brief Parse the headstage removal list
///
/// The expected format of the list entries is a semicolon (";") separated
/// list of subranges (without the possibility of denoting the step size).
///
/// Examples:
/// - 0 (ignore HS 0)
/// - 1,3;0 (ignore HS 0 to 3)
/// - * (ignore all headstages)
///
/// @param ignoreList list of entries to parse
/// @param sweepNo    sweep number
/// @return free wave of size `NUM_HEADSTAGES` denoting with 0/1 the active state
///         of the headstage
static Function/WAVE OVS_ParseIgnoreList(string ignoreList, variable sweepNo)

	variable numEntries, i, start, stop
	string subRangeStr

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
			WAVE updateHandle = OVS_BeginIncrementalUpdate(win)
			WAVE listboxSelWave = GetOverlaySweepsListSelWave(dfr)

			if(cba.checked)
				listBoxSelWave[][%Headstages] = SetBit(listBoxSelWave[p][%Headstages], LISTBOX_CELL_EDITABLE)
			else
				listBoxSelWave[][%Headstages] = ClearBit(listBoxSelWave[p][%Headstages], LISTBOX_CELL_EDITABLE)
			endif

			OVS_EndIncrementalUpdate(win, updateHandle)
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
	WAVE/T/Z traces = TUD_GetUserDataAsWave(graph, "traceName", keys = {"traceType"}, values = {"Sweep"})
	if(!WaveExists(traces))
		return NaN
	endif

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

	WAVE updateHandle = OVS_BeginIncrementalUpdate(win)

	offset = GetSetVariable(extPanel, "setvar_overlaySweeps_offset")
	step   = GetSetVariable(extPanel, "setvar_overlaySweeps_step")

	// deselect all
	listboxSelWave[][%Sweep] = listboxSelWave[p][q] & ~LISTBOX_CHECKBOX_SELECTED

	if(!cmpstr(choiceString, NONE))
		// nothing to do
	elseif(!cmpstr(choiceString, "All"))
		listboxSelWave[offset, inf;step][%Sweep] = listboxSelWave[p][q] | LISTBOX_CHECKBOX_SELECTED
	else
		WAVE/T sweepSelectionChoices = GetOverlaySweepSelectionChoices(win, dfr)

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

	OVS_EndIncrementalUpdate(win, updateHandle)
End

/// @brief Incremental sweep plot updates for overlay sweeps
///
/// When modifying the listbox selection and contents wave this function can be
/// called before doing so. After the modifications OVS_EndIncrementalUpdate()
/// will take care of updating all sweeps which got changed.
///
/// The returned wave should be considered an opaque handle and *not* modified.
///
/// Usage:
///
/// \rst
/// .. code-block:: igorpro
///
///		WAVE updateHandle = OVS_BeginIncrementalUpdate(win)
///
///		// modify list waves
///		// ...
///
///		OVS_EndIncrementalUpdate(win, updateHandle)
///
/// \endrst
///
/// By setting `fullUpdate` to true a conventional full, that means non-incremental,
/// update will be performed.
///
/// @param win        graph
/// @param fullUpdate [optional, defaults to true when OVS is off, false otherwise]
///                   allows to force a full update in OVS_EndIncrementalUpdate()
static Function/WAVE OVS_BeginIncrementalUpdate(string win, [variable fullUpdate])

	if(ParamIsDefault(fullUpdate))
		fullUpdate = !OVS_IsActive(win)
	else
		fullUpdate = !!fullUpdate
	endif

	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)

	WAVE/T listBoxWave = GetOverlaySweepsListWave(dfr)
	WAVE listSelWave   = GetOverlaySweepsListSelWave(dfr)

	Make/FREE/N=2/WAVE handle

	SetNumberInWaveNote(handle, OVS_FULL_UPDATE_NOTE, fullUpdate)

	if(!fullUpdate)
		SetDimLabel ROWS, 0, contents, handle
		SetDimLabel ROWS, 1, selection, handle

		Duplicate/FREE listBoxWave, listBoxWaveDuplicate
		handle[%contents] = listBoxWaveDuplicate

		Duplicate/FREE listSelWave, listSelWaveDuplicate
		handle[%selection] = listSelWaveDuplicate
	endif

	return handle
End

/// @brief Perform the update of all changed sweeps
///
/// Counterpart to OVS_BeginIncrementalUpdate().
static Function OVS_EndIncrementalUpdate(string win, WAVE/WAVE updateHandle)

	variable newSize, i, displayedBefore, displayedAfter, needsPostProcessing
	variable editableAfter, editableBefore, changedHeadstages
	variable updatedSweeps, addedSweeps, removedSweeps, mode
	string headstageBefore, headstageAfter, msg
	STRUCT BufferedDrawInfo bdi

	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)
	WAVE/T listBoxWaveAfterOriginal = GetOverlaySweepsListWave(dfr)
	WAVE listSelWaveAfterOriginal = GetOverlaySweepsListSelWave(dfr)

	if(GetNumberFromWaveNote(updateHandle, OVS_FULL_UPDATE_NOTE) == 1 \
	   || (DimSize(listBoxWaveAfterOriginal, ROWS) == 0               \
	       && DimSize(listSelWaveAfterOriginal, ROWS) == 0))
		UpdateSweepPlot(win)
		return NaN
	endif

	WAVE/T listBoxWaveBefore = updateHandle[%contents]
	WAVE listSelWaveBefore   = updateHandle[%selection]

	Duplicate/FREE/T listBoxWaveAfterOriginal, listBoxWaveAfter
	WaveClear listBoxWaveAfterOriginal

	Duplicate/FREE listSelWaveAfterOriginal, listSelWaveAfter
	WaveClear listSelWaveAfterOriginal

	// need to update all sweeps which are:
	// - newly selected
	// - newly deselected
	// - have a changed headstage removal list
	// - changed editable style (aka headstage removal turned on/off)
	//   with non empty headstages removal list)

	newSize = max(DimSize(listBoxWaveBefore, ROWS), DimSize(listBoxWaveAfter, ROWS))

	Redimension/N=(newSize, 2) listBoxWaveBefore, listSelWaveBefore, listBoxWaveAfter, listSelWaveAfter
	CopyDimLabels listBoxWaveAfter, listBoxWaveBefore
	CopyDimLabels listSelWaveAfter, listSelWaveBefore

	Make/FREE/N=(newSize) addedIndizes = NaN
	Make/FREE/N=(newSize) removedIndizes = NaN
	InitBufferedDrawInfo(bdi)

	// now we have the list of changed sweeps
	// so let's figure out what to do
	for(i = 0; i < newSize; i += 1)

		displayedBefore = (listSelWaveBefore[i][%Sweep] & LISTBOX_CHECKBOX_SELECTED) == LISTBOX_CHECKBOX_SELECTED
		displayedAfter  = (listSelWaveAfter[i][%Sweep] & LISTBOX_CHECKBOX_SELECTED) == LISTBOX_CHECKBOX_SELECTED

		editableBefore = (listSelWaveBefore[i][%Headstages] & LISTBOX_CELL_EDITABLE) == LISTBOX_CELL_EDITABLE
		editableAfter  = (listSelWaveAfter[i][%Headstages] & LISTBOX_CELL_EDITABLE) == LISTBOX_CELL_EDITABLE

		headstageBefore = listBoxWaveBefore[i][%Headstages]
		headstageAfter  = listBoxWaveAfter[i][%Headstages]

		changedHeadstages = (cmpstr(headstageBefore, headstageAfter) != 0)                  \
		                     || ((editableBefore != editableAfter)                          \
		                         && (!IsEmpty(headstageBefore) || !IsEmpty(headstageAfter)))

#ifdef DEBUGGING_ENABLED
		sprintf msg, "%d: display %d vs %d, edit: %d vs %d, HS: \"%5s\" vs \"%5s\" (HS changed: %d)\r", i, displayedBefore, displayedAfter, editableBefore, editableAfter, headstageBefore, headstageAfter, changedHeadstages
		DEBUGPRINT(msg)
#endif // DEBUGGING_ENABLED

		if(displayedBefore == displayedAfter && !changedHeadstages)
			// nothing changed
			continue
		elseif(!displayedBefore && !displayedAfter)
			// nothing to do
			continue
		elseif(displayedBefore && displayedAfter && changedHeadstages)
			// needs just an update
			needsPostProcessing += 1
			updatedSweeps += 1
			UpdateSweepInGraph(win, i)
		elseif(displayedBefore && !displayedAfter)
			needsPostProcessing += 1
			removedIndizes[removedSweeps++] = i
			RemoveSweepFromGraph(win, i)
		elseif(!displayedBefore && displayedAfter)
			needsPostProcessing += 1
			addedIndizes[addedSweeps++] = i
			AddSweepToGraph(win, i, bdi = bdi)
		else
			ASSERT(0, "Impossible case")
		endif
	endfor

	TiledGraphAccelerateDraw(bdi)

	if(needsPostProcessing)
		if(updatedSweeps)
			PostPlotTransformations(win, POST_PLOT_FULL_UPDATE)
		else
			if(removedSweeps == 0)
				Redimension/N=(addedSweeps) addedIndizes
				PostPlotTransformations(win, POST_PLOT_ADDED_SWEEPS, additionalData=addedIndizes)
			elseif(addedSweeps == 0)
				mode = POST_PLOT_REMOVED_SWEEPS
				Redimension/N=(removedSweeps) removedIndizes
				PostPlotTransformations(win, POST_PLOT_REMOVED_SWEEPS, additionalData=removedIndizes)
			else
				PostPlotTransformations(win, POST_PLOT_FULL_UPDATE)
			endif
		endif
	endif
End

Function OVS_MainListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	string win
	variable index

	switch(lba.eventCode)
		case 6: //begin edit
			win = lba.win
			index = lba.row
			OVS_HighlightSweep(win, index)
			break
		case 7:  // end edit
			win = lba.win
			index = lba.row
			OVS_HighlightSweep(win, NaN)
			if(lba.selWave[lba.row] & LISTBOX_CHECKBOX_SELECTED)
				OVS_UpdateHeadstageRemoval(win, index)
			endif
			break
		case 13: // checkbox clicked
			win = lba.win
			index = lba.row
			if(lba.selWave[lba.row] & LISTBOX_CHECKBOX_SELECTED)
				AddSweepToGraph(win, index)
				PostPlotTransformations(win, POST_PLOT_ADDED_SWEEPS, additionalData={index})
			else
				RemoveSweepFromGraph(win, index)
				PostPlotTransformations(win, POST_PLOT_REMOVED_SWEEPS, additionalData={index})
			endif
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
