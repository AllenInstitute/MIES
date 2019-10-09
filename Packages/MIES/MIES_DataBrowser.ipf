#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DB
#endif

/// @file MIES_DataBrowser.ipf
/// @brief __DB__ Panel for browsing acquired data during acquisition

static strConstant EXT_PANEL_SETTINGSHISTORY = "SettingsHistoryPanel"

Function/S DB_OpenDataBrowser()
	string win, device, devicesWithData, bsPanel

	Execute "DataBrowser()"
	win = GetCurrentWindow()

	AddVersionToPanel(win, DATABROWSER_PANEL_VERSION)
	BSP_SetDataBrowser(win)

	BSP_OpenPanel(win)
	DB_OpenSettingsHistory(win)

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

Function/S DB_GetMainGraph(win)
	string win

	return GetMainWindow(win)
End

Function DB_OpenSettingsHistory(win)
	string win

	string mainPanel, shPanel

	mainPanel = GetMainWindow(win)
	ASSERT(WindowExists(mainPanel), "HOST panel does not exist")

	shPanel = DB_GetSettingsHistoryPanel(win)
	if(windowExists(shPanel))
		SetWindow $shPanel hide=0, needUpdate=1
		return 1
	endif

	NewPanel/HOST=$mainPanel/EXT=2/W=(0,0,580,140)/N=$EXT_PANEL_SETTINGSHISTORY  as " "
	Execute "SettingsHistoryPanel()"
	DB_DynamicSettingsHistory(mainPanel)
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

static Function/S DB_GetSettingsHistoryPanel(win)
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
		newWindow = "DataBrowser"
		print "Please choose a device assignment for the data browser"
		ControlWindowToFront()
	else
		newWindow = "DB_" + device
	endif

	if(windowExists(newWindow))
		newWindow = UniqueName(newWindow, 9, 1)
	endif
	DoWindow/W=$win/C $newWindow

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
		return 0
	endif

	DFREF dfr = GetDeviceDataBrowserPath(device)
	BSP_SetFolder(win, dfr, MIES_BSP_PANEL_FOLDER)
End

static Function/S DB_GetPlainSweepList(win)
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
	SetSetVariableLimits(scPanel, "setvar_SweepControl_SweepNo", first, last, 1)

	if(formerLast != last)
		SetValDisplay(scPanel, "valdisp_SweepControl_LastSweep", var=last)
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
	string device, mainPanel, lbPanel, bsPanel, scPanel, graph

	if(BSP_MainPanelNeedsUpdate(win))
		DoAbortNow("Can not display data. The Databrowser panel is too old to be usable. Please close it and open a new one.")
	endif

	referenceTime = DEBUG_TIMER_START()

	mainPanel = GetMainWindow(win)
	lbPanel   = BSP_GetNotebookSubWindow(win)
	bsPanel   = BSP_GetPanel(win)
	scPanel   = BSP_GetSweepControlsPanel(win)
	graph     = DB_GetMainGraph(win)

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

		CreateTiledChannelGraph(graph, config, sweepNo, numericalValues, textualValues, tgs, dfr, axisLabelCache, traceIndex, channelSelWave=sweepChannelSel)
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

	pps.averageDataFolder = GetDeviceDataBrowserPath(BSP_GetDevice(win))
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

static Function/WAVE DB_GetNumericalValues(win)
	string win

	string device

	device = BSP_GetDevice(win)

	return GetLBNumericalValues(device)
End

static Function/WAVE DB_GetTextualValues(win)
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
End

static Function DB_UpdateOverlaySweepWaves(win)
	string win

	string device, sweepWaveList, mainPanel

	if(!OVS_IsActive(win))
		return NaN
	endif

	device = BSP_GetDevice(win)
	DFREF dfr = GetDeviceDataBrowserPath(device)

	WAVE listBoxWave       = GetOverlaySweepsListWave(dfr)
	WAVE listBoxSelWave    = GetOverlaySweepsListSelWave(dfr)
	WAVE/T textualValues   = DB_GetTextualValues(win)
	WAVE numericalValues   = DB_GetNumericalValues(win)
	WAVE/T sweepSelChoices = GetOverlaySweepSelectionChoices(dfr)

	sweepWaveList = DB_GetPlainSweepList(win)

	OVS_UpdatePanel(win, listBoxWave, listBoxSelWave, sweepSelChoices, sweepWaveList, textualValues=textualValues, numericalValues=numericalValues)
End

Window DataBrowser() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(850.5,168.5,1284,473.75)/K=1  as "DataBrowser"
	SetWindow kwTopWin,userdata(panelVersion)=  "7"
	SetWindow kwTopWin,hook(TA_CURSOR_MOVED)=TimeAlignCursorMovedHook
	ModifyGraph margin(left)=28,margin(bottom)=1
	Button button_BSP_open,pos={5.00,5.00},size={25.00,25.00},proc=DB_ButtonProc_Panel,title="<<"
	Button button_BSP_open,help={"Open Side Panel"}
EndMacro

/// @brief procedure for the open button of the side panel
Function DB_ButtonProc_Panel(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string win

	switch(ba.eventcode)
		case 2: // mouse up
			win = GetMainWindow(ba.win)
			DB_OpenSettingsHistory(win)
			break
	endswitch

	BSP_ButtonProc_Panel(ba)
	return 0
End

Window SettingsHistoryPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	//NewPanel /W=(458,631,1041,778) as "Settings History"
	PopupMenu popup_LBNumericalKeys,pos={411.00,26.00},size={150.00,19.00},bodyWidth=150,proc=DB_PopMenuProc_LabNotebook
	PopupMenu popup_LBNumericalKeys,help={"Select numeric lab notebook data to display"}
	PopupMenu popup_LBNumericalKeys,userdata(ResizeControlsInfo)= A"!!,I3J,hm^!!#A%!!#<Pz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_LBNumericalKeys,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	PopupMenu popup_LBNumericalKeys,userdata(ResizeControlsInfo) += A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	PopupMenu popup_LBNumericalKeys,mode=1,popvalue="- none -"
	PopupMenu popup_LBTextualKeys,pos={411.00,55.00},size={150.00,19.00},bodyWidth=150,proc=DB_PopMenuProc_LabNotebook
	PopupMenu popup_LBTextualKeys,help={"Select textual lab notebook data to display"}
	PopupMenu popup_LBTextualKeys,userdata(ResizeControlsInfo)= A"!!,I3J,ho@!!#A%!!#<Pz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_LBTextualKeys,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	PopupMenu popup_LBTextualKeys,userdata(ResizeControlsInfo) += A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	PopupMenu popup_LBTextualKeys,mode=1,popvalue="- none -"
	Button button_clearlabnotebookgraph,pos={402.00,85.00},size={80.00,25.00},proc=DB_ButtonProc_ClearGraph,title="Clear graph"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo)= A"!!,I/!!#?c!!#?Y!!#=+z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	Button button_switchxaxis,pos={494.00,85.00},size={80.00,25.00},proc=DB_ButtonProc_SwitchXAxis,title="Switch X-axis"
	Button button_switchxaxis,help={"Toggle lab notebook horizontal axis between time of day or sweep number"}
	Button button_switchxaxis,userdata(ResizeControlsInfo)= A"!!,I]!!#?c!!#?Y!!#=+z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_switchxaxis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	Button button_switchxaxis,userdata(ResizeControlsInfo) += A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	GroupBox group_labnotebook_ctrls,pos={403.00,5.00},size={170.00,78.00},title="Settings History Column"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo)= A"!!,I/J,hj-!!#A9!!#?Uz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo) += A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	Button button_DataBrowser_setaxis,pos={401.00,114.00},size={171.00,25.00},proc=DB_ButtonProc_AutoScale,title="Autoscale"
	Button button_DataBrowser_setaxis,help={"Autoscale sweep data"}
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo)= A"!!,I.J,hps!!#A:!!#=+z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	DefineGuide UGV0={FR,-187}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#D!^]6_8zzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGV0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV0)= A":-hTC3`S[N0KW?-:-)<bFED57B6-UXF*)>@Grnu.:dmEFF(KAR85E,T>#.mm5tj<n4&A^O8Q88W:-(0k2D-[;4%E:B6q&gk7T)<<<CoSI1-.Kp78-NR;b9q[:JNr&0fV*R"
	Display/W=(200,187,395,501)/FG=(FL,FT,UGV0,FB)/HOST=#
	ModifyGraph margin(right)=74
	TextBox/C/N=text0/F=0/B=1/X=0.50/Y=2.02/E=2 ""
	RenameWindow #,LabNoteBook
	SetActiveSubwindow ##
EndMacro

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

	ModifyPanel/W=$shPanel fixedSize=0
End

/// @brief panel close hook for settings history panel
Function DB_CloseSettingsHistoryHook(s)
	STRUCT WMWinHookStruct &s

	string mainPanel, shPanel
	variable hookResult = 0

	switch(s.eventCode)
		case 17: // killVote
			mainPanel = GetMainWindow(s.winName)
			shPanel = DB_GetSettingsHistoryPanel(mainPanel)

			ASSERT(!cmpstr(s.winName, shPanel), "This hook is only available for Setting History Panel.")

			SetWindow $s.winName hide=1

			BSP_MainPanelButtonToggle(mainPanel, 1)

			hookResult = 2 // don't kill window
			break
	endswitch

	return hookResult
End

Function DB_DataBrowserStartupSettings()

	string allCheckBoxes, mainPanel, lbPanel, mainGraph, lbGraph, bsPanel
	variable i, numCheckBoxes

	mainPanel = "DataBrowser"
	lbPanel   = BSP_GetNotebookSubWindow(mainPanel)
	mainGraph = DB_GetMainGraph(mainPanel)
	lbGraph   = DB_GetLabNotebookGraph(mainPanel)
	bsPanel   = BSP_GetPanel(mainPanel)

	if(!windowExists(mainPanel))
		print "A panel named \"DataBrowser\" does not exist"
		ControlWindowToFront()
		return NaN
	endif

	// remove tools
	HideTools/A/W=$mainPanel

	RemoveTracesFromGraph(mainGraph)
	if(windowExists(lbGraph))
		RemoveTracesFromGraph(lbGraph)
	endif

	Notebook $lbPanel selection={startOfFile, endOfFile}
	Notebook $lbPanel text = ""

	SetWindow $mainPanel, userdata(DataFolderPath) = ""

	SetCheckBoxState(bsPanel, "check_BrowserSettings_ADC", CHECKBOX_SELECTED)

	SetSliderPositionIndex(bsPanel, "slider_BrowserSettings_dDAQ", -1)
	DisableControl(bsPanel, "slider_BrowserSettings_dDAQ")

	DB_ClearGraph(mainPanel)

	SearchForInvalidControlProcs(mainPanel)
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

			formerLast = GetValDisplayAsNum(scPanel, "valdisp_SweepControl_LastSweep")
			if(formerLast != lastSweep)
				DB_UpdateLastSweepControls(scPanel, firstSweep, lastSweep)
			endif

			sweepNo = BSP_UpdateSweepControls(graph, ba.ctrlName, firstSweep, lastSweep)

			if(OVS_IsActive(graph))
				OVS_ChangeSweepSelectionState(graph, CHECKBOX_SELECTED, sweepNO=sweepNo)
			endif

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
			mainPanel = DB_LockToDevice(mainPanel, pa.popStr)
			DB_UpdateSweepPlot(mainPanel)
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

	variable checked, channelNum
	string win, bsPanel, ctrl, channelType, device

	win = cba.win
	bsPanel = BSP_GetPanel(win)

	switch(cba.eventCode)
		case 2: // mouse up
			ctrl       = cba.ctrlName
			checked    = cba.checked

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
						WAVE channelSel = BSP_GetChannelSelectionWave(win)
						ParseChannelSelectionControl(cba.ctrlName, channelType, channelNum)
						channelSel[channelNum][%$channelType] = checked
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

	string win, mainPanel, scPanel, device, sweepWaveList
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
				sweepWaveList = DB_GetPlainSweepList(win)
				OVS_UpdatePanel(win, listBoxWave, listBoxSelWave, sweepSelChoices, sweepWaveList, textualValues=textualValues, numericalValues=numericalValues)
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
