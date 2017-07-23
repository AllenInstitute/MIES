#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

static StrConstant EXT_PANEL_SUBWINDOW = "OverlaySweeps"

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

	extPanel = OVS_GetExtPanel(graph)

	if(!WindowExists(graph))
		printf "Context menu option \"%s\" is only useable for overlay sweeps.\r", S_Value
		ControlWindowToFront()
		return NaN
	endif

	sweepNo = str2num(GetUserData(graph, trace, "sweepNumber"))

	if(!IsValidSweepNumber(sweepNo))
		printf "Could not extract sweep number information from trace \"%s\".\r", trace
		ControlWindowToFront()
		return NaN
	endif

	headstage = str2num(GetUserData(graph, trace, "headstage"))

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
		WAVE traceWave     = TraceNameToWaveRef(graph, trace)
		DFREF sweepDataDFR = GetWavesDataFolderDFR(traceWave)
		index = OVS_GetIndexFromSweepDataPathW(graph, sweepDataDFR)
		OVS_AddToIgnoreList(extPanel, headstage, index=index)
	else
		OVS_AddToIgnoreList(extPanel, headstage, sweepNo=sweepNo)
	endif
End

Function OVS_GetIndexFromSweepDataPathP(graph, dataDFR)
	string graph
	DFREF dataDFR

	ASSERT(0, "Can't call prototype function")
End

Function OVS_GetIndexFromSweepDataPathW(graph, dataDFR)
	string graph
	DFREF dataDFR

	FUNCREF OVS_GetIndexFromSweepDataPathP f = $"SB_GetIndexFromSweepDataPath"

	return f(graph, dataDFR)
End

/// @brief Return the full subwindow specification of the overlay sweeps panel
Function/S OVS_GetExtPanel(win)
	string win

	return GetMainWindow(win) + "#" + EXT_PANEL_SUBWINDOW
End

/// @brief Return a list of choices for the sweep selection popup
///
/// Includes a unique list of the DA stimsets of all available sweeps
Function/S OVS_GetSweepSelectionChoices(win)
	string win

	DFREF dfr = OVS_GetFolder(win)
	WAVE/T sweepSelChoices = GetOverlaySweepSelectionChoices(dfr)

	Duplicate/FREE/R=[][][0]/T sweepSelChoices, sweepSelectionChoicesStimSets

	Make/FREE/T dupsRemovedStimSets
	FindDuplicates/Z/RT=dupsRemovedStimSets sweepSelectionChoicesStimSets

	Duplicate/FREE/R=[][][1]/T sweepSelChoices, sweepSelectionChoicesClamp

	Make/FREE/T dupsRemovedStimSetsClamp
	FindDuplicates/Z/RT=dupsRemovedStimSetsClamp sweepSelectionChoicesClamp

	return NONE + ";All;\\M1(-;\\M1(DA Stimulus Sets;"           \
				+ TextWaveToList(dupsRemovedStimSets, ";")       \
				+ "\\M1(-;\\M1(DA Stimulus Sets and Clamp Mode;" \
				+ TextWaveToList(dupsRemovedStimSetsClamp, ";")
End

/// @brief Return the datafolder reference to the folder storing the listbox and selection wave
///
/// Requires the user data `OVS_FOLDER` of the external overlay sweeps panel.
///
/// @return a valid DFREF or an invalid one in case the external panel could not be found
Function/DF OVS_GetFolder(win)
	string win

	string extPanel = OVS_GetExtPanel(win)

	if(!WindowExists(extPanel))
		return $""
	endif

	DFREF dfr = $GetUserData(extPanel, "", "OVS_FOLDER")
	ASSERT(DataFolderExistsDFR(dfr), "Missing extPanel OVS_FOLDER userdata")

	return dfr
End

/// @brief Update the overlay sweep waves
///
/// Must be called after the sweeps changed.
Function OVS_UpdatePanel(win, listBoxWave, listBoxSelWave, sweepSelectionChoices, sweepWaveList, [allTextualValues, textualValues, allNumericalValues, numericalValues])
	string win
	WAVE/T listBoxWave
	WAVE listBoxSelWave
	WAVE/T sweepSelectionChoices
	WAVE/T textualValues
	WAVE/WAVE allTextualValues
	string sweepWaveList
	WAVE/WAVE allNumericalValues
	WAVE/T numericalValues

	variable i, numEntries, sweepNo
	string ttlStimSets, extPanel

	extPanel = OVS_GetExtPanel(win)

	numEntries = ItemsInList(sweepWaveList)

	if(!ParamIsDefault(textualValues))
		Make/WAVE/FREE/N=(numEntries) allTextualValues = textualValues
	elseif(!ParamIsDefault(allTextualValues))
		ASSERT(numEntries == DimSize(allTextualValues, ROWS), "allTextualValues number of rows is not matching")
	else
		ASSERT(0, "Expected exactly one of textualValues or allTextualValues")
	endif

	if(!ParamIsDefault(numericalValues))
		Make/WAVE/FREE/N=(numEntries) allNumericalValues = numericalValues
	elseif(!ParamIsDefault(allNumericalValues))
		ASSERT(numEntries == DimSize(allNumericalValues, ROWS), "allNumericalValues number of rows is not matching")
	else
		ASSERT(0, "Expected exactly one of numericalValues or allNumericalValues")
	endif

	Redimension/N=(numEntries, -1, -1) listBoxWave, listBoxSelWave, sweepSelectionChoices

	Make/FREE/U/I/N=(numEntries) sweeps = ExtractSweepNumber(StringFromList(p, sweepWaveList))
	MultiThread listBoxWave[][%Sweep] = num2str(sweeps[p])

	listBoxSelWave[][%Sweep] = listBoxSelWave[p] & LISTBOX_CHECKBOX_SELECTED ? LISTBOX_CHECKBOX | LISTBOX_CHECKBOX_SELECTED : LISTBOX_CHECKBOX

	if(WindowExists(extPanel) && GetCheckBoxState(extPanel, "check_overlaySweeps_disableHS"))
		listBoxSelWave[][%Headstages] = SetBit(listBoxSelWave[p][%Headstages], LISTBOX_CELL_EDITABLE)
	else
		listBoxSelWave[][%Headstages] = ClearBit(listBoxSelWave[p][%Headstages], LISTBOX_CELL_EDITABLE)
	endif

	for(i = 0; i < numEntries; i += 1)
		WAVE/T stimsets = GetLastSettingText(allTextualValues[i], sweeps[i], STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
		sweepSelectionChoices[i][][%Stimset] = stimsets[q]

		WAVE clampModes = GetLastSetting(allNumericalValues[i], sweeps[i], "Clamp Mode", DATA_ACQUISITION_MODE)
		sweepSelectionChoices[i][][%StimsetAndClampMode] = SelectString(IsFinite(clampModes[q]), "", stimsets[q] + " (" + ConvertAmplifierModeShortStr(clampModes[q]) + ")")
	endfor
End

/// @brief Return the selected sweeps (either indizes or the real sweep numbers)
///
/// @param win  window (databrowser or sweepbrowser)
/// @param mode one of #OVS_SWEEP_SELECTION_INDEX or #OVS_SWEEP_SELECTION_SWEEPNO
///
/// @return invalid wave reference in case nothing is selected or indizes/sweep numbers depending on mode parameter
Function/WAVE OVS_GetSelectedSweeps(win, mode)
	string win
	variable mode

	ASSERT(mode == OVS_SWEEP_SELECTION_INDEX || mode == OVS_SWEEP_SELECTION_SWEEPNO, "Invalid mode")

	DFREF dfr = OVS_GetFolder(win)

	if(!DataFolderExistsDFR(dfr))
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

/// @brief Invert the selection of the given sweep in the listbox wave
Function OVS_InvertSweepSelection(win, [sweepNo, index])
	string win
	variable sweepNo, index

	variable selectionState

	DFREF dfr = OVS_GetFolder(win)

	if(!DataFolderExistsDFR(dfr))
		return NaN
	endif

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

	selectionState = listboxSelWave[index][0]
	if(selectionState & LISTBOX_CHECKBOX_SELECTED)
		listboxSelWave[index][0] = ClearBit(selectionState, LISTBOX_CHECKBOX_SELECTED)
	else
		listboxSelWave[index][0] = SetBit(selectionState, LISTBOX_CHECKBOX_SELECTED)
	endif
End

/// @brief Change the selection state of the the given sweep in the listbox wave
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

	variable selectionState

	DFREF dfr = OVS_GetFolder(win)

	if(!DataFolderExistsDFR(dfr))
		return NaN
	endif

	// coerce to 0/1
	newState = !!newState

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
End

/// @brief Add `headstage` to the ignore list of the given `sweepNo/index`
static Function OVS_AddToIgnoreList(win, headstage, [sweepNo, index])
	string win
	variable headstage, sweepNo, index

	variable row

	DFREF dfr = OVS_GetFolder(win)

	if(!DataFolderExistsDFR(dfr))
		return NaN
	endif

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
	UpdateSweepPlot(win)
End

/// @brief Parse the ignore list of the given sweep.
///
///
/// The expected format of the ignore list entries is a semicolon (";") separated
/// list of subranges (without the possibility denoting the step size).
///
/// Examples:
/// - 0 (ignore HS 0)
/// - 1,3;0 (ignore HS 0 to 3)
/// - * (ignore all headstages)
///
/// @return free wave of size `NUM_HEADSTAGES` denoting with 0/1 the active state
///         of the headstage
Function/WAVE OVS_ParseIgnoreList(win, highlightSweep, [sweepNo, index])
	string win
	variable sweepNo, index, &highlightSweep

	variable numEntries, i, start, stop, step
	string ignoreList, subRangeStr, extPanel

	extPanel =  OVS_GetExtPanel(win)

	DFREF dfr = OVS_GetFolder(win)

	// save default
	highlightSweep = NaN

	if(!DataFolderExistsDFR(dfr) || !GetCheckBoxState(extPanel, "check_overlaySweeps_disableHS"))
		return $""
	endif

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

	highlightSweep = OVS_IsSweepHighlighted(listboxWave, index)

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
		elseif(stop == -1)
			activeHS[start, inf]  = 0
		else
			activeHS[start, stop] = 0
		endif
	endfor

	return activeHS
End

/// @brief Toggle the overlay sweeps external panel
///
/// @return 0 if opened, 1 if closed
Function OVS_TogglePanel(win, listboxWave, listboxSelWave)
	string win
	WAVE/T listboxWave
	WAVE listboxSelWave

	string extPanel = OVS_GetExtPanel(win)

	if(WindowExists(extPanel))
		KillWindow $extPanel
		return 1
	endif

	win = GetMainWindow(win)
	NewPanel/HOST=$win/EXT=1/W=(200,0,0,485)/N=$EXT_PANEL_SUBWINDOW as " "
	SetWindow kwTopWin, hook(main)=OVS_MainWindowHook
	ListBox list_of_ranges,pos={4.00,127.00},size={189.00,348.00},proc=OVS_MainListBoxProc
	ListBox list_of_ranges,help={"Select sweeps for overlay; The second column (\"Headstages\") allows to ignore some headstages for the graphing. Syntax is a semicolon \";\" separated list of subranges, e.g. \"0\", \"0,2\", \"1;4;2\""}
	ListBox list_of_ranges,listWave=listboxWave, selWave=listboxSelWave,widths={50,50}
	PopupMenu popup_overlaySweeps_select,pos={27.00,14.00},size={143.00,19.00},bodyWidth=109,proc=OVS_PopMenuProc_Select,title="Select"
	PopupMenu popup_overlaySweeps_select,help={"Select sweeps according to various properties"}
	PopupMenu popup_overlaySweeps_select,mode=1,popvalue=NONE,value= #("OVS_GetSweepSelectionChoices(\"" + extPanel + "\")")
	CheckBox check_overlaySweeps_disableHS,pos={24.00,99.00},size={120.00,15.00},proc=OVS_CheckBoxProc_HS_Select,title="Headstage Removal"
	CheckBox check_overlaySweeps_disableHS,help={"Toggle headstage removal"}
	CheckBox check_overlaySweeps_disableHS,value= 0
	CheckBox check_overlaySweeps_non_commula,pos={24.00,78.00},size={153.00,15.00},title="Non-commulative update"
	CheckBox check_overlaySweeps_non_commula,help={"If \"Display Last sweep acquired\" is checked, this checkbox here allows to only add the newly acquired sweep and will remove the currently added last sweep."}
	CheckBox check_overlaySweeps_non_commula,value= 0
	SetVariable setvar_overlaySweeps_offset,pos={12.00,41.00},size={81.00,18.00},bodyWidth=45,title="Offset",value=_NUM:0, proc=OVS_SetVarProc_SelectionRange, limits={0, inf, 1}
	SetVariable setvar_overlaySweeps_offset,help={"Offsets the first selected sweep from the selection menu"}
	SetVariable setvar_overlaySweeps_step,pos={99.00,41.00},size={72.00,18.00},bodyWidth=45,title="Step",value=_NUM:1, proc=OVS_SetVarProc_SelectionRange, limits={1, inf, 1}
	SetVariable setvar_overlaySweeps_step,help={"Selects every `step` sweep from the selection menu"}
	GroupBox group_overlaySweeps_selection,pos={5.00,4.00},size={191.00,65.00}

	OVS_SetFolder(win, $GetWavesDataFolder(listboxWave, 1))

	return 0
End

/// @brief Set the basefolder for the current device
///
/// Must be called if the source device of the sweeps changed.
Function OVS_SetFolder(win, dfr)
	string win
	DFREF dfr

	string extPanel = OVS_GetExtPanel(win)

	ASSERT(DataFolderExistsDFR(dfr), "Missing dfr")
	SetWindow $extPanel, userData(OVS_FOLDER)=GetDataFolder(1, dfr)
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

	DFREF dfr = OVS_GetFolder(win)
	WAVE/T listboxWave = GetOverlaySweepsListWave(dfr)

	SetDimLabel ROWS, -1, $num2str(index), listboxWave
End

/// @brief Return the state of the sweep highlightning
///
/// @return NaN no sweep highlighted, or 1/0 if index needs highlightning or not
static Function OVS_IsSweepHighlighted(listBoxWave, index)
	WAVE/T listBoxWave
	variable index

	variable state = str2num(GetDimLabel(listBoxWave, ROWS, -1))

	if(!IsFinite(state))
		return NaN
	endif

	return state == index
End

/// @brief Change the selected sweep according to one of the popup menu options
static Function OVS_ChangeSweepSelection(win, choiceString)
	string win, choiceString

	variable i, j, numEntries, numLayers, offset, step
	string extPanel

	extPanel  = OVS_GetExtPanel(win)

	DFREF dfr = OVS_GetFolder(win)
	WAVE listboxSelWave          = GetOverlaySweepsListSelWave(dfr)
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
			UpdateSweepPlot(win)
			break
		case 7:  // end edit
			win = lba.win
			OVS_HighlightSweep(win, NaN)
			UpdateSweepPlot(win)
			break
		case 13: // checkbox clicked
			win = lba.win
			UpdateSweepPlot(win)
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

Function OVS_MainWindowHook(s)
	STRUCT WMWinHookStruct &s

	string win, mainWindow, ctrl

	switch(s.eventCode)
		case 2: // kill
			mainWindow = GetMainWindow(s.winName)

			if(IsDataBrowser(mainWindow))
				ctrl = "check_DataBrowser_SweepOverlay"
				win  = mainWindow
			else
				ctrl = "check_SweepBrowser_SweepOverlay"
				win  = mainWindow + "#P0"
			endif

			PGC_SetAndActivateControl(win, ctrl, val=CHECKBOX_UNSELECTED)
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
