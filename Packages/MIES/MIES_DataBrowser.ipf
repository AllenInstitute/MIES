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

	SetWindow $win, hook(cleanup)=DB_SweepBrowserWindowHook

	AddVersionToPanel(win, DATABROWSER_PANEL_VERSION)
	BSP_SetDataBrowser(win)
	BSP_InitPanel(win)
	DB_DynamicSettingsHistory(win)

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

	bsPanel = BSP_GetPanel(panelTitle)
	scPanel = BSP_GetSweepControlsPanel(panelTitle)
	shPanel = DB_GetSettingsHistoryPanel(panelTitle)

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
	DB_ClearGraph(panelTitle)

	BSP_InitPanel(panelTitle)
	DB_DynamicSettingsHistory(panelTitle)

	BSP_UnsetDynamicSweepControlOfDataBrowser(panelTitle)
	BSP_UnsetDynamicStartupSettingsOfDataBrowser(panelTitle)
	DB_UnsetDynamicSettingsHistory(panelTitle)

	TabControl SF_InfoTab, WIN = $bsPanel, disable=2

	// invalidate main panel
	SetWindow $panelTitle, userData(panelVersion) = ""
	SetWindow $panelTitle, userdata(Config_FileName) = ""
	SetWindow $panelTitle, userdata(Config_FileHash) = ""

	// static defaults for SweepControl subwindow
	PopupMenu Popup_SweepControl_Selector WIN = $scPanel, mode=1,popvalue=" ", value= #"\" \""
	CheckBox check_SweepControl_AutoUpdate WIN = $scPanel, value= 1


	// static defaults for BrowserSettings subwindow
	PGC_SetAndActivateControl(bsPanel, "Settings", val = 0)
	CheckBox check_overlaySweeps_disableHS WIN = $bsPanel, value= 0
	CheckBox check_overlaySweeps_non_commula WIN = $bsPanel, value= 0
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
	CheckBox check_channelSel_HEADSTAGE_0 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_1 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_2 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_3 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_4 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_5 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_6 WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_7 WIN = $bsPanel, value= 1
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
	SetVariable setvar_cutoff_length_after WIN = $bsPanel, value= _NUM:0.2
	SetVariable setvar_cutoff_length_before WIN = $bsPanel, value= _NUM:0.1
	CheckBox check_auto_remove WIN = $bsPanel, value= 0
	CheckBox check_highlightRanges WIN = $bsPanel, value= 0
	SetVariable setvar_pulseAver_fallbackLength WIN = $bsPanel, value= _NUM:100
	SetVariable setvar_pulseAver_endPulse WIN = $bsPanel, value= _NUM:inf
	SetVariable setvar_pulseAver_startPulse WIN = $bsPanel, value= _NUM:0
	CheckBox check_pulseAver_multGraphs WIN = $bsPanel, value= 0
	CheckBox check_pulseAver_zeroTrac WIN = $bsPanel, value= 0
	CheckBox check_pulseAver_showAver WIN = $bsPanel, value= 0
	CheckBox check_pulseAver_indTraces WIN = $bsPanel, value= 1
	CheckBox check_pulseAver_deconv WIN = $bsPanel, value= 0
	CheckBox check_pulseAver_timeAlign WIN = $bsPanel, value= 0
	SetVariable setvar_pulseAver_deconv_tau WIN = $bsPanel, value= _NUM:15
	SetVariable setvar_pulseAver_deconv_smth WIN = $bsPanel, value= _NUM:1000
	SetVariable setvar_pulseAver_deconv_range WIN = $bsPanel, value= _NUM:inf
	CheckBox check_BrowserSettings_OVS WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_AR WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_PA WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_DAC WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_ADC WIN = $bsPanel, value= 1
	CheckBox check_BrowserSettings_TTL WIN = $bsPanel, value= 0
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
	CheckBox check_Display_EqualYrange WIN = $bsPanel, value= 0
	CheckBox check_Display_EqualYignore WIN = $bsPanel, value= 0
	SetVariable setvar_Display_EqualYlevel WIN = $bsPanel, value= _NUM:0
	Slider slider_BrowserSettings_dDAQ WIN = $bsPanel, value= -1
	CheckBox check_SweepControl_HideSweep WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_splitTTL WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_DB_Passed WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_DB_Failed WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_SF WIN = $bsPanel, value= 0

	sfFormula = BSP_GetSFFormula(panelTitle)
	ReplaceNotebookText(sfFormula, "data(\rcursors(A,B),\rchannels(AD),\rsweeps()\r)")

	sfJSON = BSP_GetSFJSON(panelTitle)
	ReplaceNotebookText(sfJSON, "")

	SetVariable setvar_sweepFormula_parseResult WIN = $bsPanel, value=_STR:""
	ValDisplay status_sweepFormula_parser, WIN = $bsPanel, value=1

	SearchForInvalidControlProcs(panelTitle)
	print "Do not forget to increase DATABROWSER_PANEL_VERSION and/or SWEEPBROWSER_PANEL_VERSION and/or BROWSERSETTINGS_PANEL_VERSION."

	Execute/P/Z "DoWindow/R " + DATABROWSER_WINDOW_TITLE
	Execute/P/Q/Z "COMPILEPROCEDURES "
End

Function/S DB_GetMainGraph(win)
	string win

	return GetMainWindow(win)
End

Function DB_UnHideSettingsHistory(win)
	string win

	string settingsHistoryPanel

	ASSERT(WindowExists(GetMainWindow(win)), "HOST panel does not exist")

	settingsHistoryPanel = DB_GetSettingsHistoryPanel(win)
	if(WindowExists(settingsHistoryPanel))
		SetWindow $settingsHistoryPanel hide=0, needUpdate=1
	endif
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
		endif
	endfor
End

Function/S DB_GetSettingsHistoryPanel(win)
	string win

	return GetMainWindow(win) + "#" + EXT_PANEL_SETTINGSHISTORY
End

static Function/S DB_GetLabNoteBookGraph(win)
	string win

	return DB_GetSettingsHistoryPanel(win) + "#Labnotebook"
End

static Function/S DB_LockToDevice(win, device)
	string win, device

	string newWindow
	variable first, last

	if(!cmpstr(device, NONE))
		newWindow = DATABROWSER_WINDOW_TITLE
		print "Please choose a device assignment for the data browser"
		ControlWindowToFront()
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
		DB_DynamicSettingsHistory(newWindow)
		[first, last] = DB_FirstAndLastSweepAcquired(newWindow)
		DB_UpdateLastSweepControls(newWindow, first, last)
	endif

	DB_UpdateSweepPlot(newWindow)

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

Function/S DB_GetPlainSweepList(win)
	string win

	string device
	DFREF dfr

	if(!BSP_HasBoundDevice(win))
		return ""
	endif

	device = BSP_GetDevice(win)
	dfr = GetDeviceDataPath(device)
	return GetListOfObjects(dfr, DATA_SWEEP_REGEXP, waveProperty="MINCOLS:2")
End

static Function [variable first, variable last] DB_FirstAndLastSweepAcquired(string win)
	string list

	list = DB_GetPlainSweepList(win)

	first = NaN
	last  = NaN

	if(!isEmpty(list))
		first = NumberByKey("Sweep", list, "_")
		last = ItemsInList(list) - 1 + first
	endif

	return [first, last]
End

static Function DB_UpdateLastSweepControls(win, first, last)
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
		DB_UpdateOverlaySweepWaves(win)
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
	string device, mainPanel, lbPanel, bsPanel, scPanel, graph, experiment

	if(BSP_MainPanelNeedsUpdate(win))
		DoAbortNow("Can not display data. The Databrowser panel is too old to be usable. Please close it and open a new one.")
	endif

	referenceTime = DEBUG_TIMER_START()

	mainPanel  = GetMainWindow(win)
	lbPanel    = BSP_GetNotebookSubWindow(win)
	bsPanel    = BSP_GetPanel(win)
	scPanel    = BSP_GetSweepControlsPanel(win)
	graph      = DB_GetMainGraph(win)
	experiment = GetExperimentName()

	WAVE axesRanges = GetAxesRanges(graph)

	WAVE/T cursorInfos = GetCursorInfos(graph)
	RemoveTracesFromGraph(graph)

	if(!BSP_HasBoundDevice(win))
		return NaN
	endif
	device = BSP_GetDevice(win)

	WAVE numericalValues = DB_GetNumericalValues(win)
	WAVE textualValues   = DB_GetTextualValues(win)

	STRUCT TiledGraphSettings tgs
	tgs.displayDAC      = GetCheckBoxState(bsPanel, "check_BrowserSettings_DAC")
	tgs.displayTTL      = GetCheckBoxState(bsPanel, "check_BrowserSettings_TTL")
	tgs.displayADC      = GetCheckBoxState(bsPanel, "check_BrowserSettings_ADC")
	tgs.overlaySweep 	= OVS_IsActive(mainPanel)
	tgs.splitTTLBits    = GetCheckBoxState(bsPanel, "check_BrowserSettings_splitTTL")
	tgs.overlayChannels = GetCheckBoxState(bsPanel, "check_BrowserSettings_OChan")
	tgs.dDAQDisplayMode = GetCheckBoxState(bsPanel, "check_BrowserSettings_dDAQ")
	tgs.dDAQHeadstageRegions = GetSliderPositionIndex(bsPanel, "slider_BrowserSettings_dDAQ")
	tgs.hideSweep       = GetCheckBoxState(bsPanel, "check_SweepControl_HideSweep")

	WAVE channelSel        = BSP_GetChannelSelectionWave(win)
	WAVE/Z sweepsToOverlay = OVS_GetSelectedSweeps(win, OVS_SWEEP_SELECTION_SWEEPNO)

	if(!WaveExists(sweepsToOverlay))
		if(GetCheckBoxState(bsPanel, "check_BrowserSettings_OVS"))
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

		WAVE/Z activeHS = OVS_ParseIgnoreList(win, highlightSweep, sweepNo=sweepNo)
		tgs.highlightSweep = highlightSweep

		if(WaveExists(activeHS))
			Duplicate/FREE channelSel, sweepChannelSel
			sweepChannelSel[0, NUM_HEADSTAGES - 1][%HEADSTAGE] = sweepChannelSel[p][%HEADSTAGE] && activeHS[p]
		else
			WAVE sweepChannelSel = channelSel
		endif

		DB_SplitSweepsIfReq(win, sweepNo)
		WAVE config = GetConfigWave(sweepWave)

		CreateTiledChannelGraph(graph, config, sweepNo, numericalValues, textualValues, tgs, dfr, axisLabelCache, traceIndex, experiment, channelSelWave=sweepChannelSel)
		AR_UpdateTracesIfReq(graph, dfr, numericalValues, sweepNo)
	endfor

	RestoreCursors(graph, cursorInfos)

	DEBUGPRINT_ELAPSED(referenceTime)

	if(WaveExists(sweepWave))
		Notebook $lbPanel selection={startOfFile, endOfFile} // select entire contents of notebook
		Notebook $lbPanel text = note(sweepWave) // replaces selected notebook content with new wave note.
	endif

	Struct PostPlotSettings pps
	DB_InitPostPlotSettings(win, pps)

	PostPlotTransformations(graph, pps)
	SetAxesRanges(graph, axesRanges)
	DEBUGPRINT_ELAPSED(referenceTime)
End

/// @see SB_InitPostPlotSettings
Function DB_InitPostPlotSettings(win, pps)
	string win
	STRUCT PostPlotSettings &pps

	string bsPanel = BSP_GetPanel(win)

	ASSERT(BSP_HasBoundDevice(win), "DataBrowser was not assigned to a specific device")

	pps.averageDataFolder = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)
	pps.averageTraces     = GetCheckboxState(bsPanel, "check_Calculation_AverageTraces")
	pps.zeroTraces        = GetCheckBoxState(bsPanel, "check_Calculation_ZeroTraces")
	pps.hideSweep         = GetCheckBoxState(bsPanel, "check_SweepControl_HideSweep")
	pps.timeAlignRefTrace = ""
	pps.timeAlignMode     = TIME_ALIGNMENT_NONE

	PA_GatherSettings(win, pps)

	FUNCREF FinalUpdateHookProto pps.finalUpdateHook = DB_GraphUpdate
End

Function DB_DoTimeAlignment(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			DB_HandleTimeAlignPropChange(ba.win)
			break
	endswitch

	return 0
End

/// @see SB_HandleTimeAlignPropChange
static Function DB_HandleTimeAlignPropChange(win)
	string win

	string bsPanel, graph

	graph = GetMainWindow(win)
	bsPanel = BSP_GetPanel(graph)

	if(!BSP_HasBoundDevice(win))
		UpdateSettingsPanel(win)
		return NaN
	endif

	STRUCT PostPlotSettings pps
	DB_InitPostPlotSettings(graph, pps)

	TimeAlignGatherSettings(bsPanel, pps)

	PostPlotTransformations(graph, pps)
End

static Function DB_ClearGraph(win)
	string win

	string graph = DB_GetLabNoteBookGraph(win)
	if(!WindowExists(graph))
		return 0
	endif

	RemoveTracesFromGraph(graph)
	UpdateLBGraphLegend(graph)
End

Function/WAVE DB_GetNumericalValues(win)
	string win

	string device

	device = BSP_GetDevice(win)

	return GetLBNumericalValues(device)
End

Function/WAVE DB_GetTextualValues(win)
	string win

	string device

	device = BSP_GetDevice(win)

	return GetLBTextualValues(device)
End

static Function/WAVE DB_GetNumericalKeys(win)
	string win

	string device

	device = BSP_GetDevice(win)

	return GetLBNumericalKeys(device)
End

static Function/WAVE DB_GetTextualKeys(win)
	string win

	string device

	device = BSP_GetDevice(win)

	return GetLBTextualKeys(device)
End

Function DB_UpdateToLastSweep(win)
	string win

	variable first, last
	string device, mainPanel, bsPanel, scPanel

	mainPanel = GetMainWindow(win)
	bsPanel   = BSP_GetPanel(win)
	scPanel   = BSP_GetSweepControlsPanel(win)

	if(!HasPanelLatestVersion(mainPanel, DATABROWSER_PANEL_VERSION))
		print "Can not display data. The Databrowser panel is too old to be usable. Please close it and open a new one."
		ControlWindowToFront()
		return NaN
	endif

	device = BSP_GetDevice(win)

	if(!cmpstr(device, NONE))
		return NaN
	endif

	[first, last] = DB_FirstAndLastSweepAcquired(win)
	DB_UpdateLastSweepControls(win, first, last)
	SetSetVariable(scPanel, "setvar_SweepControl_SweepNo", last)

	if(OVS_IsActive(win) && GetCheckBoxState(bsPanel, "check_overlaySweeps_non_commula"))
		OVS_ChangeSweepSelectionState(win, CHECKBOX_UNSELECTED, sweepNo=last - 1)
	endif

	OVS_ChangeSweepSelectionState(win, CHECKBOX_SELECTED, sweepNo=last)
	DB_UpdateSweepPlot(win)
	if(SF_IsActive(win))
		PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display")
	endif
End

static Function DB_UpdateOverlaySweepWaves(win)
	string win

	if(!OVS_IsActive(win))
		return NaN
	endif

	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)

	WAVE listBoxWave       = GetOverlaySweepsListWave(dfr)
	WAVE listBoxSelWave    = GetOverlaySweepsListSelWave(dfr)
	WAVE/T textualValues   = DB_GetTextualValues(win)
	WAVE numericalValues   = DB_GetNumericalValues(win)
	WAVE/T sweepSelChoices = GetOverlaySweepSelectionChoices(dfr)

	OVS_UpdatePanel(win, listBoxWave, listBoxSelWave, sweepSelChoices, textualValues=textualValues, numericalValues=numericalValues)
End

/// @brief procedure for the open button of the side panel
Function DB_ButtonProc_Panel(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string win

	switch(ba.eventcode)
		case 2: // mouse up
			win = GetMainWindow(ba.win)
			DB_UnHideSettingsHistory(win)
			break
	endswitch

	BSP_ButtonProc_Panel(ba)
	return 0
End

static Function DB_DynamicSettingsHistory(win)
	string win

	string mainPanel, shPanel

	mainPanel = GetMainWindow(win)
	shPanel = DB_GetSettingsHistoryPanel(win)
	if(!WindowExists(shPanel))
		return 0
	endif

	SetWindow $shPanel, hook(main)=DB_CloseSettingsHistoryHook

	if(BSP_HasBoundDevice(win))
		PopupMenu popup_LBNumericalKeys, win=$shPanel, value=#("DB_GetLBNumericalKeys(\"" + mainPanel + "\")")
		PopupMenu popup_LBTextualKeys, win=$shPanel, value=#("DB_GetLBTextualKeys(\"" + mainPanel + "\")")
	else
		PopupMenu popup_LBNumericalKeys, win=$shPanel, value=#("\"" + NONE + "\"")
		PopupMenu popup_LBTextualKeys, win=$shPanel, value=#("\"" + NONE + "\"")
	endif

	SetPopupMenuIndex(shPanel, "popup_LBNumericalKeys", 0)
	SetPopupMenuIndex(shPanel, "popup_LBTextualKeys", 0)
End

/// @brief Unsets all control properties that are set in DB_DynamicSettingsHistory
static Function DB_UnsetDynamicSettingsHistory(win)
	string win

	string shPanel

	shPanel = DB_GetSettingsHistoryPanel(win)
	ASSERT(WindowExists(shPanel), "external SettingsHistory panel not found")
	SetWindow $shPanel, hook(main)=$""
End

/// @brief panel close hook for settings history panel
Function DB_CloseSettingsHistoryHook(s)
	STRUCT WMWinHookStruct &s

	string mainPanel, shPanel
	variable hookResult = 0

	switch(s.eventCode)
		case 17: // killVote
			mainPanel = GetMainWindow(s.winName)

			if(!BSP_IsDataBrowser(mainPanel))
				hookResult = 0
				break
			endif

			shPanel = DB_GetSettingsHistoryPanel(mainPanel)

			ASSERT(!cmpstr(s.winName, shPanel), "This hook is only available for Setting History Panel.")

			SetWindow $s.winName hide=1

			BSP_MainPanelButtonToggle(mainPanel, 1)

			hookResult = 2 // don't kill window
			break
	endswitch

	return hookResult
End

Function DB_ButtonProc_ChangeSweep(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string graph, scPanel
	variable firstSweep, lastSweep, formerLast, sweepNo

	graph = GetMainWindow(ba.win)
	scPanel = BSP_GetSweepControlsPanel(graph)

	switch(ba.eventcode)
		case 2: // mouse up
			[firstSweep, lastSweep] = DB_FirstAndLastSweepAcquired(scPanel)
			DB_UpdateLastSweepControls(scPanel, firstSweep, lastSweep)

			sweepNo = BSP_UpdateSweepControls(graph, ba.ctrlName, firstSweep, lastSweep)

			OVS_ChangeSweepSelectionState(graph, CHECKBOX_SELECTED, sweepNO=sweepNo)
			DB_UpdateSweepPlot(graph)
			break
	endswitch

	return 0
End

Function DB_ButtonProc_AutoScale(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string win, mainGraph, lbGraph

	win = ba.win
	lbGraph   = DB_GetLabNotebookGraph(win)

	switch(ba.eventcode)
		case 2: // mouse up
			if(WindowExists(lbGraph))
				SetAxis/A=2/W=$lbGraph
			endif
			break
	endswitch

	return 0
End

Function DB_PopMenuProc_LockDBtoDevice(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string mainPanel

	mainPanel = GetMainWindow(pa.win)

	switch(pa.eventcode)
		case 2: // mouse up
			DB_LockToDevice(mainPanel, pa.popStr)
			break
	endswitch

	return 0
End

Function DB_PopMenuProc_LabNotebook(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string lbGraph, popStr, win, device, ctrl

	win = pa.win
	lbGraph = DB_GetLabNoteBookGraph(win)

	switch(pa.eventCode)
		case 2: // mouse up
			popStr     = pa.popStr
			ctrl       = pa.ctrlName
			if(!CmpStr(popStr, NONE))
				break
			endif

			strswitch(ctrl)
				case "popup_LBNumericalKeys":
					Wave values = DB_GetNumericalValues(win)
					WAVE keys   = DB_GetNumericalKeys(win)
				break
				case "popup_LBTextualKeys":
					Wave values = DB_GetTextualValues(win)
					WAVE keys   = DB_GetTextualKeys(win)
				break
				default:
					ASSERT(0, "Unknown ctrl")
					break
			endswitch

			AddTraceToLBGraph(lbGraph, keys, values, popStr)
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

			DB_UpdateSweepPlot(win)
			OVS_ChangeSweepSelectionState(win, CHECKBOX_SELECTED, sweepNO=sweepNo)
			break
	endswitch

	return 0
End

Function DB_ButtonProc_ClearGraph(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			DB_ClearGraph(ba.win)
			break
	endswitch

	return 0
End

Function/S DB_GetLBTextualKeys(win)
	string win

	string device, mainPanel

	if(!windowExists(win))
		return NONE
	endif

	device = BSP_GetDevice(win)
	if(!CmpStr(device, NONE))
		return NONE
	endif

	WAVE/T keyWave = DB_GetTextualKeys(win)

	return AddListItem(NONE, GetLabNotebookSortedKeys(keyWave), ";", 0)
End

Function/S DB_GetLBNumericalKeys(win)
	string win

	string device, mainPanel

	if(!windowExists(win))
		return NONE
	endif

	device = BSP_GetDevice(win)
	if(!CmpStr(device, NONE))
		return NONE
	endif

	WAVE/T keyWave = DB_GetNumericalKeys(win)

	return AddListItem(NONE, GetLabNotebookSortedKeys(keyWave), ";", 0)
End

Function/S DB_GetAllDevicesWithData()

	string list

	list = AddListItem(NONE, GetAllDevicesWithContent(), ";", 0)
	list = AddListItem(RemoveEnding(list, ";"), GetListOfLockedDevices(), ";", inf)

	return GetUniqueTextEntriesFromList(list)
End

Function DB_ButtonProc_SwitchXAxis(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string win, lbGraph

	win = ba.win
	lbGraph = DB_GetLabNoteBookGraph(win)

	switch(ba.eventCode)
		case 2: // mouse up
			if(!BSP_HasBoundDevice(win))
				break
			endif
			WAVE numericalValues = DB_GetNumericalValues(win)
			WAVE textualValues   = DB_GetTextualValues(win)

			SwitchLBGraphXAxis(lbGraph, numericalValues, textualValues)
			break
	endswitch

	return 0
End

Function DB_CheckProc_ChangedSetting(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	variable checked
	string win, bsPanel, ctrl

	switch(cba.eventCode)
		case 2: // mouse up
			ctrl    = cba.ctrlName
			checked = cba.checked
			win     = cba.win
			bsPanel = BSP_GetPanel(win)

			strswitch(ctrl)
				case "check_BrowserSettings_dDAQ":
					if(checked)
						EnableControl(bsPanel, "slider_BrowserSettings_dDAQ")
					else
						DisableControl(bsPanel, "slider_BrowserSettings_dDAQ")
					endif
					break
				default:
					if(StringMatch(ctrl, "check_channelSel_*"))
						BSP_GUIToChannelSelectionWave(win, ctrl, checked)
					endif
					break
			endswitch

			DB_UpdateSweepPlot(win)
			break
	endswitch

	return 0
End

Function DB_CheckProc_ScaleAxes(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			DB_GraphUpdate(cba.win)
			break
	endswitch

	return 0
End

/// @see SB_PanelUpdate
Function DB_GraphUpdate(win)
	string win

	string bsPanel, graph

	graph = GetMainWindow(win)
	bsPanel = BSP_GetPanel(win)

	if(GetCheckBoxState(bsPanel, "check_Display_VisibleXrange"))
		AutoscaleVertAxisVisXRange(graph)
	endif
End

/// @brief enable/disable checkbox control for side panel
Function DB_CheckProc_OverlaySweeps(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string win, mainPanel, scPanel, device
	variable sweepNo

	win = cba.win
	mainPanel = GetMainWindow(win)
	scPanel   = BSP_GetSweepControlsPanel(win)

	switch(cba.eventCode)
		case 2: // mouse up
			BSP_SetOVSControlStatus(win)

			if(BSP_HasBoundDevice(win))
				DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)
				WAVE/T listBoxWave        = GetOverlaySweepsListWave(dfr)
				WAVE listBoxSelWave       = GetOverlaySweepsListSelWave(dfr)
				WAVE/WAVE sweepSelChoices = GetOverlaySweepSelectionChoices(dfr)

				WAVE/T numericalValues = DB_GetNumericalValues(win)
				WAVE/T textualValues   = DB_GetTextualValues(win)
				OVS_UpdatePanel(win, listBoxWave, listBoxSelWave, sweepSelChoices, textualValues=textualValues, numericalValues=numericalValues)
			endif

			if(OVS_IsActive(win))
				sweepNo = GetSetVariable(scPanel, "setvar_SweepControl_SweepNo")
				OVS_ChangeSweepSelectionState(win, CHECKBOX_SELECTED, sweepNo=sweepNo)
			endif

			DB_UpdateSweepPlot(win)
			break
	endswitch

	return 0
End

static Function DB_SplitSweepsIfReq(win, sweepNo)
	string win
	variable sweepNo

	string device, mainPanel
	variable sweepModTime, numWaves, requireNewSplit, i

	device = BSP_GetDevice(win)
	if(!cmpstr(device, NONE))
		return NaN
	endif

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
	endfor

	if(!requireNewSplit)
		return NaN
	endif

	WAVE numericalValues = DB_GetNumericalValues(win)

	SplitSweepIntoComponents(numericalValues, sweepNo, sweepWave, configWave, TTL_RESCALE_ON, targetDFR=singleSweepDFR)
End

Function DB_ButtonProc_RestoreData(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string mainPanel, graph, bsPanel, traceList
	variable autoRemoveOldState, zeroTracesOldState

	mainPanel = GetMainWindow(ba.win)
	graph     = DB_GetMainGraph(mainPanel)
	bsPanel   = BSP_GetPanel(mainPanel)

	switch(ba.eventCode)
		case 2: // mouse up
			traceList = GetAllSweepTraces(graph)
			ReplaceAllWavesWithBackup(graph, traceList)

			zeroTracesOldState = GetCheckBoxState(bsPanel, "check_Calculation_ZeroTraces")
			SetCheckBoxState(bsPanel, "check_Calculation_ZeroTraces", CHECKBOX_UNSELECTED)

			if(!AR_IsActive(mainPanel))
				DB_UpdateSweepPlot(mainPanel)
			else
				autoRemoveOldState = GetCheckBoxState(bsPanel, "check_auto_remove")
				SetCheckBoxState(bsPanel, "check_auto_remove", CHECKBOX_UNSELECTED)
				DB_UpdateSweepPlot(mainPanel)
				SetCheckBoxState(bsPanel, "check_auto_remove", autoRemoveOldState)
			endif

			SetCheckBoxState(bsPanel, "check_Calculation_ZeroTraces", zeroTracesOldState)
			break
	endswitch

	return 0
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

Function DB_SweepBrowserWindowHook(s)
	STRUCT WMWinHookStruct &s

	variable hookResult
	string win

	switch(s.eventCode)
		case 2: // Kill

			win = s.winName
			if(!BSP_HasBoundDevice(win))
				break
			endif

			try
				DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER); AbortOnRTE

				KillWindow/Z $s.winName
				KillOrMoveToTrash(dfr = dfr); AbortOnRTE
			catch
				ClearRTError()
			endtry

			hookResult = 1
			break
	endswitch

	return hookResult // 0 if nothing done, else 1
End
