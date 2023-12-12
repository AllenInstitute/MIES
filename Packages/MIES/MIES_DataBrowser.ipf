#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DB
#endif

/// @file MIES_DataBrowser.ipf
/// @brief __DB__ Panel for browsing acquired data during acquisition

Function/S DB_OpenDataBrowser([variable mode])
	string win, device, devicesWithData, bsPanel

	if(ParamIsDefault(mode))
		mode = BROWSER_MODE_USER
	else
		ASSERT(mode == BROWSER_MODE_USER || mode == BROWSER_MODE_AUTOMATION || mode == BROWSER_MODE_ALL, "Invalid mode")
	endif

	UploadPingPeriodically()

	Execute "DataBrowser()"
	win = GetCurrentWindow()

	AddVersionToPanel(win, DATA_SWEEP_BROWSER_PANEL_VERSION)
	BSP_SetDataBrowser(win, mode)
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
	string device, bsPanel, scPanel, shPanel, recreationCode
	string sfJSON, descNB, helpNBWin

	device = GetMainWindow(GetCurrentWindow())
	if(!windowExists(device))
		print "The top panel does not exist"
		ControlWindowToFront()
		return NaN
	endif
	if(CmpStr(device, DATABROWSER_WINDOW_NAME))
		printf "The top window is not named \"%s\"\r", DATABROWSER_WINDOW_NAME
		return NaN
	endif

	// allow an already used panel to be used again
	if(!HasPanelLatestVersion(device, DATA_SWEEP_BROWSER_PANEL_VERSION))
		AddVersionToPanel(device, DATA_SWEEP_BROWSER_PANEL_VERSION)
	endif

	bsPanel = BSP_GetPanel(device)
	scPanel = BSP_GetSweepControlsPanel(device)
	shPanel = LBV_GetSettingsHistoryPanel(device)

	ASSERT(WindowExists(bsPanel) && WindowExists(scPanel) && WindowExists(shPanel), "BrowserSettings or SweepControl or SettingsHistory panel subwindow does not exist.")

	PGC_SetAndActivateControl(bsPanel, "popup_DB_lockedDevices", str = NONE)
	device = GetMainWindow(GetCurrentWindow())

	if(CmpStr(device, DATABROWSER_WINDOW_NAME))
		printf "The top window is not named \"%s\" after unlocking\r", DATABROWSER_WINDOW_NAME
		return NaN
	endif

	// The following block resets the GUI state of the window and subwindows
	HideTools/W=$device/A
	HideTools/W=$bsPanel/A
	HideTools/W=$scPanel/A
	HideTools/W=$shPanel/A

	PGC_SetAndActivateControl(device, "button_BSP_open")
	DB_ClearAllGraphs()
	LBV_ClearGraph(device)

	Checkbox check_BrowserSettings_OVS, WIN = $bsPanel, value= 0

	BSP_InitPanel(device)
	BSP_RemoveWindowHooks(device)

	BSP_UnsetDynamicStartupSettings(device)

	// store current positions as reference
	StoreCurrentPanelsResizeInfo(bsPanel)

	TabControl SF_InfoTab, WIN = $bsPanel, value=0, disable=1

	// invalidate main panel
	SetWindow $device, userData(panelVersion) = ""
	SetWindow $device, userdata(Config_FileName) = ""
	SetWindow $device, userdata(Config_FileHash) = ""
	SetWindow $device, userdata(Config_FileHash) = ""
	SetWindow $device, userdata(PulseAverageSettings) = ""

	// invalidate hooks
	SetWindow $device,tooltiphook(hook)=$""

	// static defaults for SweepControl subwindow
	PopupMenu Popup_SweepControl_Selector, WIN = $scPanel, mode=1,popvalue=" ", value= #"\" \""
	CheckBox check_SweepControl_AutoUpdate, WIN = $scPanel, value= 1

	// static defaults for BrowserSettings subwindow
	PGC_SetAndActivateControl(bsPanel, "Settings", val = 0)
	CheckBox check_overlaySweeps_disableHS, WIN = $bsPanel, value= 0
	CheckBox check_overlaySweeps_non_commula, WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_splitTTL, WIN = $bsPanel, value= 1,disable=DISABLE_CONTROL_BIT
	PopupMenu popup_overlaySweeps_select, WIN = $bsPanel, mode=1
	SetVariable setvar_overlaySweeps_offset, WIN = $bsPanel, value= _NUM:0
	SetVariable setvar_overlaySweeps_step, WIN = $bsPanel, value= _NUM:1
	CheckBox check_channelSel_DA_0, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_DA_1, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_DA_2, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_DA_3, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_DA_4, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_DA_5, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_DA_6, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_DA_7, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_DA_ALL, WIN = $bsPanel, value= 0
	CheckBox check_channelSel_HEADSTAGE_0, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_1, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_2, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_3, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_4, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_5, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_6, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_7, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_HEADSTAGE_ALL, WIN = $bsPanel, value= 0
	CheckBox check_channelSel_AD_0, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_1, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_2, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_3, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_4, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_5, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_6, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_7, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_8, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_9, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_10, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_11, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_12, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_13, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_14, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_15, WIN = $bsPanel, value= 1
	CheckBox check_channelSel_AD_ALL, WIN = $bsPanel, value= 0
	SetVariable setvar_cutoff_length_after, WIN = $bsPanel, value= _NUM:0.2
	SetVariable setvar_cutoff_length_before, WIN = $bsPanel, value= _NUM:0.1
	CheckBox check_auto_remove, WIN = $bsPanel, value= 0
	CheckBox check_highlightRanges, WIN = $bsPanel, value= 0

	// BEGIN PA
	CheckBox check_pulseAver_showTraces, WIN = $bsPanel, value= 1
	SetVariable setvar_pulseAver_vert_scale_bar, WIN = $bsPanel, value= _NUM:1

	CheckBox check_pulseAver_ShowImage, WIN = $bsPanel, value= 0
	CheckBox check_pulseAver_drawXZeroLine, WIN = $bsPanel, value= 0
	SetVariable setvar_pulseAver_overridePulseLength, WIN = $bsPanel, value= _NUM:10
	PopupMenu popup_pulseAver_colorscales, WIN= $bsPanel, mode=8 // Terrain
	PopupMenu popup_pulseAver_pulseSortOrder, WIN= $bsPanel, mode=1

	CheckBox check_pulseAver_deconv, WIN = $bsPanel, value= 0
	SetVariable setvar_pulseAver_deconv_tau, WIN = $bsPanel, value= _NUM:15
	SetVariable setvar_pulseAver_deconv_smth, WIN = $bsPanel, value= _NUM:1000
	SetVariable setvar_pulseAver_deconv_range, WIN = $bsPanel, value= _NUM:inf

	CheckBox check_pulseAver_zero, WIN = $bsPanel, value= 0
	CheckBox check_pulseAver_timeAlign, WIN = $bsPanel, value= 0
	CheckBox check_pulseAver_showAver, WIN = $bsPanel, value= 0
	CheckBox check_pulseAver_multGraphs, WIN = $bsPanel, value= 0
	CheckBox check_pulseAver_indPulses, WIN = $bsPanel, value= 1

	SetVariable setvar_pulseAver_startPulse, WIN = $bsPanel, value= _NUM:0
	SetVariable setvar_pulseAver_endPulse, WIN = $bsPanel, value= _NUM:inf
	CheckBox check_pulseAver_fixedPulseLength, WIN = $bsPanel, value= 0
	SetVariable setvar_pulseAver_overridePulseLength, WIN = $bsPanel, value= _NUM:10

	CheckBox check_pulseAver_searchFailedPulses, WIN = $bsPanel, value= 0
	CheckBox check_pulseAver_hideFailedPulses, WIN = $bsPanel, value= 0
	SetVariable setvar_pulseAver_failedPulses_level, WIN = $bsPanel, value= _NUM:0
	SetVariable setvar_pulseAver_numberOfSpikes, WIN = $bsPanel, value= _NUM:NaN

	// END PA

	CheckBox check_BrowserSettings_OVS, WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_AR, WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_PA, WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_DAC, WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_ADC, WIN = $bsPanel, value= 1
	CheckBox check_BrowserSettings_TTL, WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_OChan, WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_dDAQ, WIN = $bsPanel, value= 0
	CheckBox check_Calculation_ZeroTraces, WIN = $bsPanel, value= 0
	CheckBox check_Calculation_AverageTraces, WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_TA, WIN = $bsPanel, value= 0
	CheckBox check_ovs_clear_on_new_ra_cycle, WIN = $bsPanel, value= 0
	CheckBox check_ovs_clear_on_new_stimset_cycle, WIN = $bsPanel, value= 0
	PopupMenu popup_TimeAlignment_Mode, WIN = $bsPanel, mode=1, popvalue="Level (Raising)",value= #"\"Level (Raising);Level (Falling);Min;Max\""
	SetVariable setvar_TimeAlignment_LevelCross, WIN = $bsPanel, value= _NUM:0
	CheckBox check_Display_VisibleXrange, WIN = $bsPanel, value= 0
	CheckBox check_Display_EqualYrange, WIN = $bsPanel, value= 0, disable=0
	CheckBox check_Display_EqualYignore, WIN = $bsPanel, value= 0, disable=0
	SetVariable setvar_Display_EqualYlevel, WIN = $bsPanel, value= _NUM:0
	Slider slider_BrowserSettings_dDAQ, WIN = $bsPanel, value= -1,disable=DISABLE_CONTROL_BIT
	CheckBox check_SweepControl_HideSweep, WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_DS, WIN = $bsPanel, value= 0
	CheckBox check_BrowserSettings_DB_Passed, WIN = $bsPanel, value= 0,disable=DISABLE_CONTROL_BIT | HIDDEN_CONTROL_BIT
	CheckBox check_BrowserSettings_DB_Failed, WIN = $bsPanel, value= 0,disable=DISABLE_CONTROL_BIT | HIDDEN_CONTROL_BIT
	CheckBox check_BrowserSettings_SF, WIN = $bsPanel, value= 0

	CheckBox check_BrowserSettings_VisEpochs, WIN = $bsPanel, value=0, disable=0

	// settings history
	CheckBox check_limit_x_selected_sweeps, WIN = $shPanel, value=0

	SF_SetFormula(device, SF_GetDefaultFormula())

	helpNBWin = BSP_GetSFHELP(device)
	SetWindow $helpNBWin, userdata($EXPCONFIG_UDATA_EXCLUDE_RESTORE)="1"
	SetWindow $helpNBWin, userdata($EXPCONFIG_UDATA_EXCLUDE_SAVE)="1"

	sfJSON = BSP_GetSFJSON(device)
	ReplaceNotebookText(sfJSON, "")
	SetWindow $sfJSON, userdata($EXPCONFIG_UDATA_EXCLUDE_RESTORE)="1"
	SetWindow $sfJSON, userdata($EXPCONFIG_UDATA_EXCLUDE_SAVE)="1"

	descNB = LBV_GetDescriptionNotebook(shPanel)
	ReplaceNotebookText(descNB, "")
	SetWindow $descNB, userdata($EXPCONFIG_UDATA_EXCLUDE_RESTORE)="1"
	SetWindow $descNB, userdata($EXPCONFIG_UDATA_EXCLUDE_SAVE)="1"

	SetVariable setvar_sweepFormula_parseResult, WIN = $bsPanel, value=_STR:""
	ValDisplay status_sweepFormula_parser, WIN = $bsPanel, value=1

	SearchForInvalidControlProcs(device)
	print "Do not forget to increase DATA_SWEEP_BROWSER_PANEL_VERSION."

	Execute/P/Z "DoWindow/R " + DATABROWSER_WINDOW_NAME
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
		newWindow = DATABROWSER_WINDOW_NAME
		print "Please choose a device assignment for the data browser"
		ControlWindowToFront()
		BSP_UnsetDynamicStartupSettings(win)
	else
		newWindow = "DB_" + device
	endif

	win = BSP_RenameAndSetTitle(win, newWindow)

	DB_SetUserData(win, device)
	if(windowExists(BSP_GetPanel(win)) && BSP_HasBoundDevice(win))
		BSP_DynamicStartupSettings(win)
		[first, last] = BSP_FirstAndLastSweepAcquired(win)
		DB_UpdateLastSweepControls(win, first, last)
	endif

	UpdateSweepPlot(win)

	return win
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

	string device

	if(!BSP_HasBoundDevice(win))
		return $""
	endif

	device = BSP_GetDevice(win)

	return AFH_GetSweeps(device)
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

	WAVE axesProps = GetAxesProperties(graph)

	WAVE/T/Z cursorInfos = GetCursorInfos(graph)
	RemoveTracesFromGraph(graph)
	RemoveFreeAxisFromGraph(graph)
	TUD_Clear(graph, recursive = 0)

	if(!BSP_HasBoundDevice(win))
		return NaN
	endif

	device = BSP_GetDevice(win)

	// fetch keys waves to trigger a potential labnotebook upgrade
	WAVE numericalKeys = DB_GetLBNWave(win, LBN_NUMERICAL_KEYS)
	WAVE textualKeys   = DB_GetLBNWave(win, LBN_TEXTUAL_KEYS)

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

		if(DB_SplitSweepsIfReq(win, sweepNo) != 0)
			BUG("Splitting sweep failed on DB update")
			continue
		endif

		WAVE/Z/SDFR=dfr sweepWave = $GetSweepWaveName(sweepNo)
		if(!WaveExists(sweepWave))
			DEBUGPRINT("Expected sweep wave does not exist. Hugh?")
			continue
		endif
		WAVE config = GetConfigWave(sweepWave)

		CreateTiledChannelGraph(graph, config, sweepNo, numericalValues, textualValues, tgs, dfr, \
		                        axisLabelCache, traceIndex, experiment, sweepChannelSel)
		AR_UpdateTracesIfReq(graph, dfr, sweepNo)
	endfor

	RestoreCursors(graph, cursorInfos)

	DEBUGPRINT_ELAPSED(referenceTime)

	BSP_UpdateSweepNote(win)

	PostPlotTransformations(graph, POST_PLOT_FULL_UPDATE)

	SetAxesProperties(graph, axesProps)
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

	device = BSP_GetDevice(win)

	return GetLogbookWaves(LBT_LABNOTEBOOK, type, device = device)
End

/// @brief Update the databrowser to the last sweep
///
/// `force` is off by default and in this case respects the autoupdate checkbox setting.
Function DB_UpdateToLastSweep(string databrowser, [variable force])

	if(ParamIsDefault(force))
		force = 0
	else
		force = !!force
	endif

	// catch all error conditions, asserts and aborts
	// and silently ignore them
	AssertOnAndClearRTError()
	try
		DB_UpdateToLastSweepWrapper(databrowser, force); AbortOnRTE
	catch
		ClearRTError()
	endtry
End

static Function DB_UpdateToLastSweepWrapper(string win, variable force)

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

	if(!force && !GetCheckBoxState(scPanel, "check_SweepControl_AutoUpdate"))
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

	LBV_UpdateTagsForTextualLBNEntries(win, last)
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
Function DB_AddSweepToGraph(string win, variable index, [STRUCT BufferedDrawInfo &bdi])
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

	WAVE config = GetConfigWave(sweepWave)

	if(!IsValidSweepAndConfig(sweepWave, config, configVersion = 0))
		printf "The sweep %d of device %s does not match its configuration data. Therefore we can't display it.\r", sweepNo, device
		return 1
	endif

	WAVE sweepChannelSel = BSP_FetchSelectedChannels(graph, sweepNo=sweepNo)

	DB_SplitSweepsIfReq(win, sweepNo)

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

/// @brief Split sweeps to single sweep waves if required
///
/// @param win Databrowser window name
/// @param sweepNo Number of sweep to split
/// @returns 1 on error, 0 on success
Function DB_SplitSweepsIfReq(string win, variable sweepNo)

	string device, mainPanel
	variable sweepModTime, numWaves, requireNewSplit, i
	variable numBackupWaves

	if(!BSP_HasBoundDevice(win))
		return NaN
	endif

	device = BSP_GetDevice(win)

	DFREF deviceDFR = GetDeviceDataPath(device)
	DFREF singleSweepDFR = GetSingleSweepFolder(deviceDFR, sweepNo)

	WAVE/Z sweepWave  = GetSweepWave(device, sweepNo)
	if(!WaveExists(sweepWave))
		return 1
	endif

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
		return 0
	endif

	KillOrMoveToTrash(dfr = singleSweepDFR)
	DFREF singleSweepDFR = GetSingleSweepFolder(deviceDFR, sweepNo)

	WAVE numericalValues = DB_GetLBNWave(win, LBN_NUMERICAL_VALUES)

	SplitAndUpgradeSweep(numericalValues, sweepNo, sweepWave, configWave, TTL_RESCALE_ON, targetDFR=singleSweepDFR)

	return 0
End

/// @brief Find a Databrowser which is locked to the given DAEphys panel
Function/S DB_FindDataBrowser(string device, [variable mode])

	if(ParamIsDefault(mode))
		mode = BROWSER_MODE_USER
	else
		ASSERT(mode == BROWSER_MODE_USER || mode == BROWSER_MODE_AUTOMATION || mode == BROWSER_MODE_ALL, "Invalid mode")
	endif

	WAVE/T/Z matches = DB_FindAllDataBrowser(device, mode = mode)

	if(!WaveExists(matches))
		return ""
	endif

	return matches[0]
End

/// @brief Find all Databrowser which are locked to the given DAEphys panel
Function/WAVE DB_FindAllDataBrowser(string device, [variable mode])

	string panelList
	string panel
	variable numPanels, i, idx

	if(ParamIsDefault(mode))
		mode = BROWSER_MODE_USER
	else
		ASSERT(mode == BROWSER_MODE_USER || mode == BROWSER_MODE_AUTOMATION || mode == BROWSER_MODE_ALL, "Invalid mode")
	endif

	panelList = WinList("DB_*", ";", "WIN:1")
	numPanels = ItemsInList(panelList)

	Make/FREE/N=(numPanels)/T matches

	for(i = 0; i < numPanels; i += 1)
		panel = StringFromList(i, panelList)

		if(!BSP_IsDataBrowser(panel))
			continue
		endif

		if(!BSP_HasMode(panel, mode))
			continue
		endif

		if(cmpstr(device, BSP_GetDevice(panel)))
			continue
		endif

		matches[idx++] = panel
	endfor

	if(idx == 0)
		return $""
	endif

	Redimension/N=(idx) matches

	return matches
End

/// @brief Returns a databrowser bound to the given `device`
///
/// @param device locked device
/// @param mode   [defaults to #BROWSER_MODE_USER] mode of the databrowser to search. One of @ref BrowserModes.
///
/// Creates a new one, if none is found nor bound.
Function/S DB_GetBoundDataBrowser(string device, [variable mode])
	string databrowser, bsPanel

	if(ParamIsDefault(mode))
		mode = BROWSER_MODE_USER
	else
		ASSERT(mode == BROWSER_MODE_USER || mode == BROWSER_MODE_AUTOMATION || mode == BROWSER_MODE_ALL, "Invalid mode")
	endif

	databrowser = DB_FindDataBrowser(device, mode = mode)
	if(IsEmpty(databrowser)) // not yet open
		databrowser = DB_OpenDataBrowser(mode = mode)
	endif

	if(BSP_HasBoundDevice(databrowser))
		return databrowser
	endif

	bsPanel = BSP_GetPanel(databrowser)
	PGC_SetAndActivateControl(bsPanel, "popup_DB_lockedDevices", str = device)

	return DB_FindDataBrowser(device, mode = mode)
End

/// @brief Jumps in the SweepFormula help notebook of the current data/sweepbrowser to the first location
///        of the search string from the notebook start. Used for scrolling to operation help.
///
/// The convention is that the headlines of the operation description in the sweepformula help notebook is
/// `operation - <operationName>`
///
/// @param[in] str characters to find, use "" to jump to the notebook start
/// @returns 0 if help for operation was found, 1 in case of error
Function DB_SFHelpJumpToLine(string str)

	string win = BSP_GetSFHELP(GetCurrentWindow())

	Notebook $win, selection={startOfFile, startOfFile}
	Notebook $win, findText={"", 1}
	if(!IsEmpty(str))
		Notebook $win, findText={str, 1}
	endif

	return V_flag == 0
End
