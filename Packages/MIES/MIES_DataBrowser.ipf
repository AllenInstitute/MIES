#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DB
#endif

/// @file MIES_DataBrowser.ipf
/// @brief __DB__ Panel for browsing acquired data during acquisition

Function/S DB_OpenDataBrowser()
	string win, device, devicesWithData, bsPanel

	Execute "DataBrowser()"
	win = GetCurrentWindow()

	SetWindow $win, hook(cleanup)=DB_WindowHook

	AddVersionToPanel(win, DATA_SWEEP_BROWSER_PANEL_VERSION)
	BSP_SetDataBrowser(win)
	BSP_InitPanel(win)

	// immediately lock if we have only data from one device
	devicesWithData = ListMatch(DB_GetAllDevicesWithData(), "!" + NONE)
	if(ItemsInList(devicesWithData) == 1)
		device = StringFromList(0, devicesWithData)
	else
		device = NONE
	endif

	bsPanel = BSP_GetPanel(win)
	PGC_SetAndActivateControl(bsPanel, "popup_DB_lockedDevices", str = device)

	return GetMainWindow(GetCurrentWindow())
End

/// @brief Utility function to generate new window recreation macro of DataBrowser (also used for SweepBrowser)
///        after GUI editor adapted controls in development process
Function DB_ResetAndStoreCurrentDBPanel()
	string panelTitle, bsPanel, scPanel, shPanel, recreationCode
	string sfFormula, sfJSON

	panelTitle = GetMainWindow(GetCurrentWindow())
	if(!windowExists(panelTitle))
		print "The top panel does not exist"
		ControlWindowToFront()
		return NaN
	endif
	if(CmpStr(panelTitle, DATABROWSER_WINDOW_TITLE))
		printf "The top window is not named \"%s\"\r", DATABROWSER_WINDOW_TITLE
		return NaN
	endif

	// allow an already used panel to be used again
	if(!HasPanelLatestVersion(panelTitle, DATA_SWEEP_BROWSER_PANEL_VERSION))
		AddVersionToPanel(panelTitle, DATA_SWEEP_BROWSER_PANEL_VERSION)
	endif

	bsPanel = BSP_GetPanel(panelTitle)
	scPanel = BSP_GetSweepControlsPanel(panelTitle)
	shPanel = LBV_GetSettingsHistoryPanel(panelTitle)

	ASSERT(WindowExists(bsPanel) && WindowExists(scPanel) && WindowExists(shPanel), "BrowserSettings or SweepControl or SettingsHistory panel subwindow does not exist.")

	PGC_SetAndActivateControl(bsPanel, "popup_DB_lockedDevices", str = NONE)
	panelTitle = GetMainWindow(GetCurrentWindow())

	if(CmpStr(panelTitle, DATABROWSER_WINDOW_TITLE))
		printf "The top window is not named \"%s\" after unlocking\r", DATABROWSER_WINDOW_TITLE
		return NaN
	endif

	// The following block resets the GUI state of the window and subwindows
	HideTools/W=$panelTitle/A
	HideTools/W=$bsPanel/A
	HideTools/W=$scPanel/A
	HideTools/W=$shPanel/A

	PGC_SetAndActivateControl(panelTitle, "button_BSP_open")
	DB_ClearAllGraphs()
	LBV_ClearGraph(panelTitle)

	Checkbox check_BrowserSettings_OVS WIN = $bsPanel, value= 0

	BSP_InitPanel(panelTitle)

	BSP_UnsetDynamicSweepControlOfDataBrowser(panelTitle)
	BSP_UnsetDynamicStartupSettingsOfDataBrowser(panelTitle)
	BSP_UnsetDynamicSettingsHistory(panelTitle)

	// store current positions as reference
	StoreCurrentPanelsResizeInfo(bsPanel)

	TabControl SF_InfoTab, WIN = $bsPanel, disable=2

	// invalidate main panel
	SetWindow $panelTitle, userData(panelVersion) = ""
	SetWindow $panelTitle, userdata(Config_FileName) = ""
	SetWindow $panelTitle, userdata(Config_FileHash) = ""
	SetWindow $panelTitle, userdata(Config_FileHash) = ""
	SetWindow $panelTitle, userdata(PulseAverageSettings) = ""

	// invalidate hooks
#if IgorVersion() >= 9.00
	SetWindow $panelTitle,tooltiphook(hook)=$""
#endif

	// static defaults for SweepControl subwindow
	PopupMenu Popup_SweepControl_Selector WIN = $scPanel, mode=1,popvalue=" ", value= #"\" \""
	CheckBox check_SweepControl_AutoUpdate WIN = $scPanel, value= 1

	// static defaults for BrowserSettings subwindow
	PGC_SetAndActivateControl(bsPanel, "Settings", val = 0)
	CheckBox check_overlaySweeps_disableHS WIN = $bsPanel, value= 0
	CheckBox check_overlaySweeps_non_commula WIN = $bsPanel, value= 0
	PopupMenu popup_overlaySweeps_select, WIN = $bsPanel, mode=1
	SetVariable setvar_overlaySweeps_offset WIN = $bsPanel, value= _NUM:0
	SetVariable setvar_overlaySweeps_step WIN = $bsPanel, value= _NUM:1
	CheckBox check_channelSel_DA_0 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_DA_1 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_DA_2 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_DA_3 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_DA_4 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_DA_5 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_DA_6 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_DA_7 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_DA_ALL WIN = $bsPanel, value= 0
	CheckBox check_channelSel_HEADSTAGE_0 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_1 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_2 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_3 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_4 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_5 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_6 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_7 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_ALL WIN = $bsPanel, value= 0
	CheckBox check_channelSel_AD_0 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_1 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_2 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_3 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_4 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_5 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_6 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_7 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_8 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_9 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_10 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_11 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_12 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_13 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_14 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_15 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_ALL WIN = $bsPanel, value= 0
	SetVariable setvar_cutoff_length_after WIN = $bsPanel, value= _NUM:0.2
	SetVariable setvar_cutoff_length_before WIN = $bsPanel, value= _NUM:0.1
	CheckBox check_auto_remove WIN = $bsPanel, value= 0
	CheckBox check_highlightRanges WIN = $bsPanel, value= 0

	// BEGIN PA
	CheckBox check_pulseAver_showTraces WIN = $bsPanel, value= 1
	SetVariable setvar_pulseAver_vert_scale_bar WIN = $bsPanel, value= _NUM:1

	CheckBox check_pulseAver_ShowImage WIN = $bsPanel, value= 0
	CheckBox check_pulseAver_drawXZeroLine WIN = $bsPanel, value= 0
	SetVariable setvar_pulseAver_overridePulseLength WIN = $bsPanel, value= _NUM:10
	PopupMenu popup_pulseAver_colorscales WIN= $bsPanel, mode=8 // Terrain
	PopupMenu popup_pulseAver_pulseSortOrder WIN= $bsPanel, mode=1

	CheckBox check_pulseAver_deconv WIN = $bsPanel, value= 0
	SetVariable setvar_pulseAver_deconv_tau WIN = $bsPanel, value= _NUM:15
	SetVariable setvar_pulseAver_deconv_smth WIN = $bsPanel, value= _NUM:1000
	SetVariable setvar_pulseAver_deconv_range WIN = $bsPanel, value= _NUM:inf

	CheckBox check_pulseAver_zero WIN = $bsPanel, value= 0
	CheckBox check_pulseAver_timeAlign WIN = $bsPanel, value= 0
	CheckBox check_pulseAver_showAver WIN = $bsPanel, value= 0
	CheckBox check_pulseAver_multGraphs WIN = $bsPanel, value= 0
	CheckBox check_pulseAver_indPulses WIN = $bsPanel, value= 1

	SetVariable setvar_pulseAver_startPulse WIN = $bsPanel, value= _NUM:0
	SetVariable setvar_pulseAver_endPulse WIN = $bsPanel, value= _NUM:inf
	CheckBox check_pulseAver_fixedPulseLength WIN = $bsPanel, value= 0
	SetVariable setvar_pulseAver_overridePulseLength WIN = $bsPanel, value= _NUM:10

	CheckBox check_pulseAver_searchFailedPulses WIN = $bsPanel, value= 0
	CheckBox check_pulseAver_hideFailedPulses WIN = $bsPanel, value= 0
	SetVariable setvar_pulseAver_failedPulses_level WIN = $bsPanel, value= _NUM:0
	SetVariable setvar_pulseAver_numberOfSpikes WIN = $bsPanel, value= _NUM:NaN

	// END PA

	CheckBox check_BrowserSettings_OVS WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_AR WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_PA WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_DAC WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_ADC WIN = $bsPanel, value= 1
	CheckBox check_BrowserSettings_TTL WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_splitTTL WIN = $bsPanel, value= 0,disable=DISABLE_CONTROL_BIT
	CheckBox check_BrowserSettings_OChan WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_dDAQ WIN = $bsPanel, value= 0
	CheckBox check_Calculation_ZeroTraces WIN = $bsPanel, value= 0
	CheckBox check_Calculation_AverageTraces WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_TA WIN = $bsPanel, value= 0
	CheckBox check_ovs_clear_on_new_ra_cycle WIN = $bsPanel, value= 0
	CheckBox check_ovs_clear_on_new_stimset_cycle WIN = $bsPanel, value= 0
	PopupMenu popup_TimeAlignment_Mode WIN = $bsPanel, mode=1, popvalue="Level (Raising)",value= #"\"Level (Raising);Level (Falling);Min;Max\""
	SetVariable setvar_TimeAlignment_LevelCross WIN = $bsPanel, value= _NUM:0
	CheckBox check_Display_VisibleXrange WIN = $bsPanel, value= 0
	CheckBox check_Display_EqualYrange WIN = $bsPanel, value= 0, disable=0
	CheckBox check_Display_EqualYignore WIN = $bsPanel, value= 0, disable=0
	SetVariable setvar_Display_EqualYlevel WIN = $bsPanel, value= _NUM:0
	Slider slider_BrowserSettings_dDAQ WIN = $bsPanel, value= -1,disable=DISABLE_CONTROL_BIT
	CheckBox check_SweepControl_HideSweep WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_DB_Passed WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_DB_Failed WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_SF WIN = $bsPanel, value= 0

	CheckBox check_BrowserSettings_VisEpochs WIN = $bsPanel, value=0,disable=DISABLE_CONTROL_BIT

	sfFormula = BSP_GetSFFormula(panelTitle)
	ReplaceNotebookText(sfFormula, "data(\rcursors(A,B),\rchannels(AD),\rsweeps()\r)")

	sfJSON = BSP_GetSFJSON(panelTitle)
	ReplaceNotebookText(sfJSON, "")

	SetVariable setvar_sweepFormula_parseResult WIN = $bsPanel, value=_STR:""
	ValDisplay status_sweepFormula_parser, WIN = $bsPanel, value=1

	SearchForInvalidControlProcs(panelTitle)
	print "Do not forget to increase DATA_SWEEP_BROWSER_PANEL_VERSION."

	Execute/P/Z "DoWindow/R " + DATABROWSER_WINDOW_TITLE
	Execute/P/Q/Z "COMPILEPROCEDURES "
End

Function/S DB_GetMainGraph(win)
	string win

	return GetMainWindow(win)
End

Function/S DB_ClearAllGraphs()

	string unlocked, locked, listOfGraphs
	string listOfPanels = ""
	string graph
	variable i, numEntries

	locked   = WinList("DB_*", ";", "WIN:1")
	unlocked = WinList("DataBrowser*", ";", "WIN:1")

	if(!IsEmpty(locked))
		listOfPanels = AddListItem(locked, listOfPanels, ";", inf)
	endif

	if(!IsEmpty(unlocked))
		listOfPanels = AddListItem(unlocked, listOfPanels, ";", inf)
	endif

	numEntries = ItemsInList(listOfPanels)
	for(i = 0; i < numEntries; i += 1)
		graph = DB_GetMainGraph(StringFromList(i, listOfPanels))

		if(WindowExists(graph))
			RemoveTracesFromGraph(graph)
			RemoveFreeAxisFromGraph(graph)
		endif
	endfor
End

static Function/S DB_LockToDevice(win, device)
	string win, device

	string newWindow
	variable first, last

	if(!cmpstr(device, NONE))
		newWindow = DATABROWSER_WINDOW_TITLE
		print "Please choose a device assignment for the data browser"
		ControlWindowToFront()
		BSP_UnsetDynamicStartupSettingsOfDataBrowser(win)
		BSP_UnsetDynamicSettingsHistory(win)
	else
		newWindow = "DB_" + device
	endif

	if(CmpStr(win, newWindow))
		if(windowExists(newWindow))
			newWindow = UniqueName(newWindow, 9, 1)
		endif
		DoWindow/W=$win/C $newWindow
		win = newWindow
	endif

	DB_SetUserData(newWindow, device)
	if(windowExists(BSP_GetPanel(newWindow)) && BSP_HasBoundDevice(newWindow))
		BSP_DynamicStartupSettings(newWindow)
		BSP_DynamicSettingsHistory(newWindow)
		[first, last] = BSP_FirstAndLastSweepAcquired(newWindow)
		DB_UpdateLastSweepControls(newWindow, first, last)
	endif

	UpdateSweepPlot(newWindow)

	return newWindow
End

static Function DB_SetUserData(win, device)
	string win, device

	SetWindow $win, userdata = ""
	BSP_SetDevice(win, device)

	if(!cmpstr(device, NONE))
		SetWindow $win, userData($MIES_BSP_PANEL_FOLDER) = ""
		return 0
	endif

	DFREF dfr = UniqueDataFolder(GetDevicePath(device), "Databrowser")
	BSP_SetFolder(win, dfr, MIES_BSP_PANEL_FOLDER)
End

Function/WAVE DB_GetPlainSweepList(win)
	string win

	string device, list
	DFREF dfr

	if(!BSP_HasBoundDevice(win))
		return $""
	endif

	device = BSP_GetDevice(win)
	dfr = GetDeviceDataPath(device)
	list = GetListOfObjects(dfr, DATA_SWEEP_REGEXP)

	if(IsEmpty(list))
		return $""
	endif

	Make/FREE/R/N=(ItemsInList(list)) sweeps = ExtractSweepNumber(StringFromList(p, list))

	return sweeps
End

Function DB_UpdateLastSweepControls(win, first, last)
	string win
	variable first, last

	variable formerLast
	string scPanel

	scPanel = BSP_GetSweepControlsPanel(win)
	if(!WindowExists(scPanel))
		return 0
	endif

	formerLast = GetValDisplayAsNum(scPanel, "valdisp_SweepControl_LastSweep")

	if(formerLast != last || (IsNaN(formerLast) && IsFinite(last)))
		SetValDisplay(scPanel, "valdisp_SweepControl_LastSweep", var=last)
		SetSetVariableLimits(scPanel, "setvar_SweepControl_SweepNo", first, last, 1)

		if(IsNaN(GetSetVariable(scPanel, "setvar_SweepControl_SweepNo")))
			SetSetVariable(scPanel, "setvar_SweepControl_SweepNo", first)
		endif

		OVS_UpdatePanel(win)
		AD_Update(win)
	endif
End

/// @brief Update the sweep plotting facility
///
/// Only outside callers are generic external panels which must update the graph.
/// @param win        locked databrowser
Function DB_UpdateSweepPlot(win)
	string win

	variable numEntries, i, sweepNo, highlightSweep, referenceTime, traceIndex
	string device, lbPanel, scPanel, graph, experiment
	STRUCT TiledGraphSettings tgs

	if(!HasPanelLatestVersion(win, DATA_SWEEP_BROWSER_PANEL_VERSION))
		DoAbortNow("Can not display data. The Databrowser panel is too old to be usable. Please close it and open a new one.")
	endif

	referenceTime = DEBUG_TIMER_START()

	lbPanel    = BSP_GetNotebookSubWindow(win)
	scPanel    = BSP_GetSweepControlsPanel(win)
	graph      = DB_GetMainGraph(win)
	experiment = GetExperimentName()

	[tgs] = BSP_GatherTiledGraphSettings(graph)

	WAVE axesRanges = GetAxesRanges(graph)

	WAVE/T/Z cursorInfos = GetCursorInfos(graph)
	RemoveTracesFromGraph(graph)
	RemoveFreeAxisFromGraph(graph)
	TUD_Clear(graph)

	if(!BSP_HasBoundDevice(win))
		return NaN
	endif

	device = BSP_GetDevice(win)

	WAVE numericalValues = DB_GetLBNWave(win, LBN_NUMERICAL_VALUES)
	WAVE textualValues   = DB_GetLBNWave(win, LBN_TEXTUAL_VALUES)

	WAVE/Z sweepsToOverlay = OVS_GetSelectedSweeps(win, OVS_SWEEP_SELECTION_SWEEPNO)

	if(!WaveExists(sweepsToOverlay))
		if(tgs.overlaySweep)
			return NaN
		else
			Make/FREE/N=1 sweepsToOverlay = GetSetVariable(scPanel, "setvar_SweepControl_SweepNo")
		endif
	endif

	WAVE axisLabelCache = GetAxisLabelCacheWave()
	DFREF dfr = GetDeviceDataPath(device)
	numEntries = DimSize(sweepsToOverlay, ROWS)
	for(i = 0; i < numEntries; i += 1)
		sweepNo = sweepsToOverlay[i]
		WAVE/Z/SDFR=dfr sweepWave = $GetSweepWaveName(sweepNo)

		if(!WaveExists(sweepWave))
			DEBUGPRINT("Expected sweep wave does not exist. Hugh?")
			continue
		endif

		WAVE sweepChannelSel = BSP_FetchSelectedChannels(graph, sweepNo=sweepNo)

		DB_SplitSweepsIfReq(win, sweepNo)
		WAVE config = GetConfigWave(sweepWave)

		CreateTiledChannelGraph(graph, config, sweepNo, numericalValues, textualValues, tgs, dfr, \
		                        axisLabelCache, traceIndex, experiment, sweepChannelSel)
		AR_UpdateTracesIfReq(graph, dfr, sweepNo)
	endfor

	RestoreCursors(graph, cursorInfos)

	DEBUGPRINT_ELAPSED(referenceTime)

	BSP_UpdateSweepNote(win)

	PostPlotTransformations(graph, POST_PLOT_FULL_UPDATE)

	SetAxesRanges(graph, axesRanges)
	DEBUGPRINT_ELAPSED(referenceTime)
End

/// @brief Return the labnotebook waves
///
/// The databrowser only knows about one experiment/device at a time
/// so we don't need to specify what we return further.
///
/// @param win  panel
/// @param type One of @ref LabnotebookWaveTypes
Function/WAVE DB_GetLBNWave(string win, variable type)
	string device

	switch(type)
		case LBN_NUMERICAL_KEYS:
			FUNCREF DAQ_LBN_GETTER_PROTO func = GetLBNumericalKeys
			break
		case LBN_NUMERICAL_VALUES:
			FUNCREF DAQ_LBN_GETTER_PROTO func = GetLBNumericalValues
			break
		case LBN_TEXTUAL_KEYS:
			FUNCREF DAQ_LBN_GETTER_PROTO func = GetLBTextualKeys
			break
		case LBN_TEXTUAL_VALUES:
			FUNCREF DAQ_LBN_GETTER_PROTO func = GetLBTextualValues
			break
		default:
			ASSERT(0, "Invalid type")
	endswitch

	device = BSP_GetDevice(win)

	return func(device)
End

Function DB_UpdateToLastSweep(win)
	string win

	variable first, last
	string bsPanel, scPanel

	bsPanel = BSP_GetPanel(win)
	scPanel = BSP_GetSweepControlsPanel(win)

	if(!HasPanelLatestVersion(win, DATA_SWEEP_BROWSER_PANEL_VERSION))
		print "Can not display data. The Databrowser panel is too old to be usable. Please close it and open a new one."
		ControlWindowToFront()
		return NaN
	endif

	if(!BSP_HasBoundDevice(win))
		return NaN
	endif

	[first, last] = BSP_FirstAndLastSweepAcquired(win)
	DB_UpdateLastSweepControls(win, first, last)
	SetSetVariable(scPanel, "setvar_SweepControl_SweepNo", last)

	if(OVS_IsActive(win))
		if(GetCheckBoxState(bsPanel, "check_overlaySweeps_non_commula"))
			OVS_ChangeSweepSelectionState(win, CHECKBOX_UNSELECTED, sweepNo=last - 1)
		endif

		OVS_ChangeSweepSelectionState(win, CHECKBOX_SELECTED, sweepNo=last)
	else
		UpdateSweepPlot(win)
	endif

	if(SF_IsActive(win))
		PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display")
	endif

	LBV_UpdateTagsForTextualLBNEntries(win, last)
End

/// @brief procedure for the open button of the side panel
Function DB_ButtonProc_Panel(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string win

	switch(ba.eventcode)
		case 2: // mouse up
			win = GetMainWindow(ba.win)
			BSP_UnHideSettingsHistory(win)
			break
	endswitch

	BSP_ButtonProc_Panel(ba)
	return 0
End

Function DB_PopMenuProc_LockDBtoDevice(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string mainPanel

	switch(pa.eventcode)
		case 2: // mouse up
			mainPanel = GetMainWindow(pa.win)
			DB_LockToDevice(mainPanel, pa.popStr)
			break
	endswitch

	return 0
End

Function DB_SetVarProc_SweepNo(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	string win
	variable sweepNo

	switch(sva.eventCode)
		case 1: // mouse up - when the scroll wheel is used on the mouse - "up or down"
		case 2: // Enter key - when a number is manually entered
		case 3: // Live update - happens when you hit the arrow keys associated with the set variable
			sweepNo = sva.dval
			win = sva.win

			if(OVS_IsActive(win))
				OVS_ChangeSweepSelectionState(win, CHECKBOX_SELECTED, sweepNo=sweepNo)
			else
				UpdateSweepPlot(win)
			endif
			break
	endswitch

	return 0
End

Function/S DB_GetAllDevicesWithData()

	string list

	list = AddListItem(NONE, GetAllDevicesWithContent(), ";", 0)
	list = AddListItem(RemoveEnding(list, ";"), GetListOfLockedDevices(), ";", inf)

	return GetUniqueTextEntriesFromList(list)
End

/// @brief Adds traces of a sweep to the databrowser graph
/// @param win Name of the DataBrowser
/// @param index Index of the sweep
/// @param bdi [optional, default = n/a] BufferedDrawInfo structure, when given buffered draw is used.
Function DB_AddSweepToGraph(string win, variable index[, STRUCT BufferedDrawInfo &bdi])
	STRUCT TiledGraphSettings tgs

	variable sweepNo, traceIndex
	string experiment, device, graph

	graph  = GetMainWindow(win)
	device = BSP_GetDevice(win)

	WAVE/Z numericalValues = DB_GetLBNWave(win, LBN_NUMERICAL_VALUES)
	WAVE/Z textualValues   = DB_GetLBNWave(win, LBN_TEXTUAL_VALUES)

	[tgs] = BSP_GatherTiledGraphSettings(graph)
	[sweepNo, experiment] = OVS_GetSweepAndExperiment(win, index)

	DFREF dfr = GetDeviceDataPath(device)
	WAVE/Z/SDFR=dfr sweepWave = $GetSweepWaveName(sweepNo)

	if(!WaveExists(sweepWave))
		return NaN
	endif

	WAVE sweepChannelSel = BSP_FetchSelectedChannels(graph, sweepNo=sweepNo)

	DB_SplitSweepsIfReq(win, sweepNo)
	WAVE config = GetConfigWave(sweepWave)

	WAVE axisLabelCache = GetAxisLabelCacheWave()

	traceIndex = GetNextTraceIndex(graph)

	if(ParamIsDefault(bdi))
		CreateTiledChannelGraph(graph, config, sweepNo, numericalValues, textualValues, tgs, dfr, axisLabelCache, \
							traceIndex, experiment, sweepChannelSel)
	else
		CreateTiledChannelGraph(graph, config, sweepNo, numericalValues, textualValues, tgs, dfr, axisLabelCache, \
							traceIndex, experiment, sweepChannelSel, bdi = bdi)
	endif

	AR_UpdateTracesIfReq(graph, dfr, sweepNo)
End

static Function DB_SplitSweepsIfReq(win, sweepNo)
	string win
	variable sweepNo

	string device, mainPanel
	variable sweepModTime, numWaves, requireNewSplit, i
	variable numBackupWaves

	if(!BSP_HasBoundDevice(win))
		return NaN
	endif

	device = BSP_GetDevice(win)

	DFREF deviceDFR = GetDeviceDataPath(device)
	DFREF singleSweepDFR = GetSingleSweepFolder(deviceDFR, sweepNo)

	WAVE sweepWave  = GetSweepWave(device, sweepNo)
	WAVE configWave = GetConfigWave(sweepWave)

	sweepModTime = max(ModDate(sweepWave), ModDate(configWave))
	numWaves = CountObjectsDFR(singleSweepDFR, COUNTOBJECTS_WAVES)
	requireNewSplit = (numWaves == 0)

	for(i = 0; i < numWaves; i += 1)
		WAVE/SDFR=singleSweepDFR wv = $GetIndexedObjNameDFR(singleSweepDFR, COUNTOBJECTS_WAVES, i)
		if(sweepModTime > ModDate(wv))
			// original sweep was modified, regenerate single sweep waves
			KillOrMoveToTrash(dfr=singleSweepDFR)
			DFREF singleSweepDFR = GetSingleSweepFolder(deviceDFR, sweepNo)
			requireNewSplit = 1
			break
		endif
		if(GrepString(NameOfWave(wv), "\\Q" + WAVE_BACKUP_SUFFIX + "\\E$"))
			numBackupWaves += 1
		endif
	endfor

	if(!requireNewSplit && (numBackupWaves * 2 == numWaves))
		return NaN
	endif

	KillOrMoveToTrash(dfr = singleSweepDFR)
	DFREF singleSweepDFR = GetSingleSweepFolder(deviceDFR, sweepNo)

	WAVE numericalValues = DB_GetLBNWave(win, LBN_NUMERICAL_VALUES)

	SplitSweepIntoComponents(numericalValues, sweepNo, sweepWave, configWave, TTL_RESCALE_ON, targetDFR=singleSweepDFR)
End

/// @brief Find a Databrowser which is locked to the given DAEphys panel
Function/S DB_FindDataBrowser(panelTitle)
	string panelTitle

	string panelList
	string panel
	variable numPanels, i

	panelList = WinList("DB_*", ";", "WIN:1")

	numPanels = ItemsInList(panelList)
	for(i = 0; i < numPanels; i += 1)
		panel = StringFromList(i, panelList)

		if(!BSP_IsDataBrowser(panel))
			continue
		endif

		if(!cmpstr(panelTitle, BSP_GetDevice(panel)))
			return panel
		endif
	endfor

	return ""
End

Function DB_WindowHook(s)
	STRUCT WMWinHookStruct &s

	string win

	switch(s.eventCode)
		case 2: // Kill

			win = s.winName

			NVAR JSONid = $GetSettingsJSONid()
			PS_StoreWindowCoordinate(JSONid, win)

			if(!BSP_HasBoundDevice(win))
				break
			endif

			AssertOnAndClearRTError()
			try
				// catch all error conditions, asserts and aborts
				// and silently ignore them
				DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER); AbortOnRTE

				KillOrMoveToTrash(dfr = dfr); AbortOnRTE
			catch
				ClearRTError()
			endtry

			break
	endswitch

	// return zero so that other hooks are called as well
	return 0
End
