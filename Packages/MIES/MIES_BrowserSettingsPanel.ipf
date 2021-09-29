#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_BSP
#endif

/// @file MIES_BrowserSettingsPanel.ipf
/// @brief __BSP__ Panel for __DB__ and __AB__ (SweepBrowser) that combines different settings in a tabcontrol.

static strConstant EXT_PANEL_SUBWINDOW = "BrowserSettingsPanel"
static strConstant EXT_PANEL_SWEEPCONTROL = "SweepControl"
static strConstant EXT_PANEL_SF_FORMULA = "sweepFormula_formula"
static strConstant EXT_PANEL_SF_JSON = "sweepFormula_json"
static strConstant EXT_PANEL_SF_HELP = "sweepFormula_help"

static Constant BROWSERSETTINGS_PANEL_VERSION = 7

static strConstant BROWSERTYPE_DATABROWSER  = "D"
static strConstant BROWSERTYPE_SWEEPBROWSER = "S"

/// @brief exclusive controls that are enabled/disabled for the specific browser window type
static StrConstant BROWSERSETTINGS_CONTROLS_DATABROWSER = "popup_DB_lockedDevices;"
static StrConstant BROWSERSETTINGS_AXES_SCALING_CHECKBOXES = "check_Display_VisibleXrange;check_Display_EqualYrange;check_Display_EqualYignore"

/// @brief exclusive controls that are enabled/disabled for the specific browser window type
static StrConstant SWEEPCONTROL_CONTROLS_DATABROWSER = "check_SweepControl_AutoUpdate;setvar_SweepControl_SweepNo;"
static StrConstant SWEEPCONTROL_CONTROLS_SWEEPBROWSER = "popup_SweepControl_Selector;"

/// @brief return the name of the external panel depending on main window name
///
/// @param mainPanel 	mainWindow panel name
Function/S BSP_GetPanel(mainPanel)
	string mainPanel

	return GetMainWindow(mainPanel) + "#" + EXT_PANEL_SUBWINDOW
End

/// @brief return the name of the WaveNote Display inside BSP
Function/S BSP_GetNotebookSubWindow(win)
	string win

	return BSP_GetPanel(win) + "#WaveNoteDisplay"
End

/// @brief return the name of the bottom Panel
///
/// @param mainPanel 	mainWindow panel name
Function/S BSP_GetSweepControlsPanel(mainPanel)
	string mainPanel

	return GetMainWindow(mainPanel) + "#" + EXT_PANEL_SWEEPCONTROL
End

Function /S BSP_GetSFFormula(mainPanel)
	string mainPanel

	return BSP_GetPanel(mainPanel) + "#" + EXT_PANEL_SF_FORMULA
End

Function /S BSP_GetSFJSON(mainPanel)
	string mainPanel

	return BSP_GetPanel(mainPanel) + "#" + EXT_PANEL_SF_JSON
End

Function /S BSP_GetSFHELP(mainPanel)
	string mainPanel

	return BSP_GetPanel(mainPanel) + "#" + EXT_PANEL_SF_HELP
End

/// @brief Inits controls of BrowserSettings side Panel
///
/// @param mainPanel 	mainWindow panel name
Function BSP_InitPanel(mainPanel)
	string mainPanel

	string graph

	BSP_DynamicSweepControls(mainPanel)
	BSP_DynamicStartupSettings(mainPanel)
	BSP_DynamicSettingsHistory(mainPanel)

	graph = LBV_GetLabNoteBookGraph(mainPanel)
	TUD_Init(graph)
End

/// @brief UnHides BrowserSettings side Panel
///
/// @param mainPanel 	mainWindow panel name
Function BSP_UnHidePanel(mainPanel)
	string mainPanel

	BSP_UnHideSweepControls(mainPanel)
	BSP_UnHideSettingsPanel(mainPanel)

	BSP_MainPanelButtonToggle(mainPanel, 0)
End

Function BSP_UnHideSettingsPanel(mainPanel)
	string mainPanel

	string bsPanel

	if(!HasPanelLatestVersion(mainPanel, DATA_SWEEP_BROWSER_PANEL_VERSION))
		DoAbortNow("The main panel is too old to be usable. Please close it and open a new one.")
	endif

	bsPanel = BSP_GetPanel(mainPanel)

	SetWindow $bsPanel hide=0, needUpdate=1
End

/// @brief open bottom Panel
///
/// @param mainPanel 	mainWindow panel name
Function BSP_UnHideSweepControls(mainPanel)
	string mainPanel

	string scPanel

	mainPanel = GetMainWindow(mainPanel)
	ASSERT(WindowExists(mainPanel), "HOST panel does not exist")
	scPanel = BSP_GetSweepControlsPanel(mainPanel)
	ASSERT(WindowExists(scPanel), "SweepControl panel does not exist")

	SetWindow $scPanel hide=0, needUpdate=1
End

/// @brief dynamic settings for bottom panel at initialization
///
/// @param mainPanel 	mainWindow panel name
static Function BSP_DynamicSweepControls(mainPanel)
	string mainPanel

	string scPanel

	scPanel = BSP_GetSweepControlsPanel(mainPanel)
	ASSERT(WindowExists(scPanel), "external SweepControl Panel not found")

	SetWindow $scPanel, hook(main)=BSP_ClosePanelHook

	SetSetVariable(scPanel, "setvar_SweepControl_SweepNo", 0)
	SetSetVariableLimits(scPanel, "setvar_SweepControl_SweepNo", 0, 0, 1)
	SetValDisplay(scPanel, "valdisp_SweepControl_LastSweep", var=NaN)
	SetSetVariable(scPanel, "setvar_SweepControl_SweepStep", 1)

	if(BSP_IsDataBrowser(mainPanel))
		SetControlProcedures(scPanel, "setvar_SweepControl_SweepNo;", "DB_SetVarProc_SweepNo")
		EnableControls(scPanel, SWEEPCONTROL_CONTROLS_DATABROWSER)
		DisableControls(scPanel, SWEEPCONTROL_CONTROLS_SWEEPBROWSER)
	else
		PopupMenu popup_SweepControl_Selector win=$scPanel, value= #("SB_GetSweepList(\"" + mainPanel + "\")")
		SetControlProcedures(scPanel, "popup_SweepControl_Selector;", "SB_PopupMenuSelectSweep")
		EnableControls(scPanel, SWEEPCONTROL_CONTROLS_SWEEPBROWSER)
		DisableControls(scPanel, SWEEPCONTROL_CONTROLS_DATABROWSER)
	endif
End

/// @brief Unsets all control properties that are set in BSP_DynamicSweepControls for DataBrowser type
///
/// @param mainPanel 	mainWindow panel name
Function BSP_UnsetDynamicSweepControlOfDataBrowser(mainPanel)
	string mainPanel

	string scPanel

	ASSERT(BSP_IsDataBrowser(mainPanel), "Browser window is not of type DataBrowser")
	scPanel = BSP_GetSweepControlsPanel(mainPanel)
	ASSERT(WindowExists(scPanel), "external SweepControl panel not found")
	SetWindow $scPanel, hook(main)=$""
End

/// @brief dynamic settings for panel initialization
///
/// @param mainPanel 	mainWindow panel name
Function BSP_DynamicStartupSettings(mainPanel)
	string mainPanel

	variable sweepNo
	string bsPanel, shPanel, experiments, devices

	bsPanel = BSP_GetPanel(mainPanel)

	SetWindow $bsPanel, hook(main)=BSP_ClosePanelHook
	AddVersionToPanel(bsPanel, BROWSERSETTINGS_PANEL_VERSION)

	NVAR JSONid = $GetSettingsJSONid()
	PS_InitCoordinates(JSONid, mainPanel, "datasweepbrowser", addHook=0)

	PopupMenu popup_overlaySweeps_select, win=$bsPanel, value= #("OVS_GetSweepSelectionChoices(\"" + bsPanel + "\")")

	if(BSP_HasBoundDevice(mainPanel))
		BSP_BindListBoxWaves(mainPanel)
	endif

	if(BSP_IsDataBrowser(mainPanel))
		EnableControls(bsPanel, BROWSERSETTINGS_CONTROLS_DATABROWSER)
	else
		DisableControls(bsPanel, BROWSERSETTINGS_CONTROLS_DATABROWSER)
	endif
	PopupMenu popup_TimeAlignment_Master win=$bsPanel, value = #("TimeAlignGetAllTraces(\"" + mainPanel + "\")")

	BSP_InitMainCheckboxes(bsPanel)

	PGC_SetAndActivateControl(bsPanel, "SF_InfoTab", val = 0)
	PGC_SetAndActivateControl(bsPanel, "Settings", val = 0)

	BSP_SetSFControlStatus(bsPanel)
	BSP_UpdateHelpNotebook(mainPanel)

	SetWindow $bsPanel, hook(sweepFormula)=BSP_SweepFormulaHook

	shPanel = LBV_GetSettingsHistoryPanel(mainPanel)

	if(BSP_IsDataBrowser(mainPanel))
		SetPopupMenuVal(shPanel, "popup_Device", list = NONE)
		SetPopupMenuVal(shPanel, "popup_Experiment", list = NONE)
		DisableControls(shPanel, "popup_Device;popup_Experiment")

		SetPopupMenuIndex(shPanel, "popup_Device", 0)
		SetPopupMenuIndex(shPanel, "popup_Experiment", 0)
	else
		SetPopupMenuVal(shPanel, "popup_Device", func = "LBV_GetAllDevicesForExperiment(\"" + shPanel + "\")")
		SetPopupMenuVal(shPanel, "popup_Experiment", func = "LBV_GetExperiments(\"" + shPanel + "\")")
		EnableControls(shPanel, "popup_Device;popup_Experiment")
	endif
End

/// @brief Hook function for the Sweep Formula Notebook
Function BSP_SweepFormulaHook(s)
	STRUCT WMWinHookStruct &s

	string win, bsPanel

	switch(s.eventCode)
		case 11: // keyboard
			if(s.specialKeyCode == 200 && s.eventMod & 0x2) // Enter + Shift
				win = GetMainWindow(s.winName)
				bsPanel = BSP_GetPanel(win)

				if(SF_IsActive(win))
					PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display")
					return 1
				endif
			endif

			break
	endswitch

	return 0
End

/// @brief Unsets all control properties that are set in BSP_DynamicStartupSettings for DataBrowser type
///
/// @param mainPanel 	mainWindow panel name
Function BSP_UnsetDynamicStartupSettingsOfDataBrowser(mainPanel)
	string mainPanel

	string bsPanel, shPanel

	ASSERT(BSP_IsDataBrowser(mainPanel), "Browser window is not of type DataBrowser")
	bsPanel = BSP_GetPanel(mainPanel)
	ASSERT(WindowExists(bsPanel), "external BrowserSettings panel not found")
	SetWindow $bsPanel, hook(main)=$""
	SetWindow $bsPanel, userData(panelVersion) = ""
	PopupMenu popup_overlaySweeps_select, win=$bsPanel, value=""
	PopupMenu popup_TimeAlignment_Master win=$bsPanel, value = ""
	ListBox list_of_ranges, win=$bsPanel, listWave=$"", selWave=$""
	ListBox list_of_ranges1, win=$bsPanel, listWave=$"", selWave=$""
	ListBox list_dashboard, win=$bsPanel, listWave=$"", colorWave=$"", selWave=$"", helpWave=$""

	shPanel = LBV_GetSettingsHistoryPanel(mainPanel)

	SetPopupMenuVal(shPanel, "popup_Device", list = NONE)
	SetPopupMenuVal(shPanel, "popup_Experiment", list = NONE)
	EnableControls(shPanel, "popup_Device;popup_Experiment")
End


Function BSP_BindListBoxWaves(win)
	string win

	string mainPanel, bsPanel

	ASSERT(BSP_IsDataBrowser(win) && BSP_HasBoundDevice(win) || !BSP_IsDataBrowser(win), "DataBrowser needs bound device to bind listBox waves.")

	mainPanel = GetMainWindow(win)
	bsPanel = BSP_GetPanel(win)

	// overlay sweeps
	DFREF dfr = BSP_GetFolder(mainPanel, MIES_BSP_PANEL_FOLDER)
	WAVE/T listBoxWave        = GetOverlaySweepsListWave(dfr)
	WAVE listBoxSelWave       = GetOverlaySweepsListSelWave(dfr)
	ListBox list_of_ranges, win=$bsPanel, listWave=listBoxWave
	ListBox list_of_ranges, win=$bsPanel, selWave=listBoxSelWave
	WaveClear listBoxWave, listBoxSelWave

	// artefact removal
	WAVE/T listBoxWave = GetArtefactRemovalListWave(dfr)
	ListBox list_of_ranges1, win=$bsPanel, listWave=listBoxWave

	// channel selection
	WAVE channelSelection = BSP_GetChannelSelectionWave(mainPanel)
	BSP_ChannelSelectionWaveToGUI(bsPanel, channelSelection)

	// dashboard
	WAVE listBoxHelpWave  = GetAnaFuncDashboardHelpWave(dfr)
	WAVE listBoxColorWave = GetAnaFuncDashboardColorWave(dfr)
	WAVE listBoxSelWave   = GetAnaFuncDashboardselWave(dfr)
	WAVE/T listBoxWave    = GetAnaFuncDashboardListWave(dfr)
	ListBox list_dashboard, win=$bsPanel, listWave=listBoxWave, colorWave=listBoxColorWave, selWave=listBoxSelWave, helpWave=listBoxHelpWave

	// sweep formula tab
	SetValDisplay(bsPanel, "status_sweepFormula_parser", var=1)
	SetSetVariableString(bsPanel, "setvar_sweepFormula_parseResult", "")
End

/// @brief Get the channel selection wave
///
/// @param win 	name of external panel or main window
/// @returns channel selection wave
Function/WAVE BSP_GetChannelSelectionWave(win)
	string win

	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)
	WAVE wv = GetChannelSelectionWave(dfr)

	return wv
End

/// @brief get a FOLDER property from the specified panel
///
/// @param win 						name of external panel or main window
/// @param MIES_BSP_FOLDER_TYPE 	see the FOLDER constants in this file
///
/// @return DFR to specified folder. No check for invalid folders
Function/DF BSP_GetFolder(win, MIES_BSP_FOLDER_TYPE)
	string win, MIES_BSP_FOLDER_TYPE

	string mainPanel

	if(!HasPanelLatestVersion(win, DATA_SWEEP_BROWSER_PANEL_VERSION))
		DoAbortNow("The main panel is too old to be usable. Please close it and open a new one.")
	endif

	mainPanel = GetMainWindow(win)

	DFREF dfr = $GetUserData(mainPanel, "", MIES_BSP_FOLDER_TYPE)
	ASSERT(DataFolderExistsDFR(dfr), "DataFolder does not exist. Probably check device assignment.")

	return dfr
End

/// @brief set a FOLDER property at the specified panel
///
/// @param win 						name of external panel or main window
/// @param dfr 						DataFolder Reference to the folder
/// @param MIES_BSP_FOLDER_TYPE 	see the FOLDER constants in this file
Function BSP_SetFolder(win, dfr, MIES_BSP_FOLDER_TYPE)
	string win, MIES_BSP_FOLDER_TYPE
	DFREF dfr

	string mainPanel

	mainPanel = GetMainWindow(win)
	ASSERT(WindowExists(mainPanel), "specified panel does not exist.")

	ASSERT(DataFolderExistsDFR(dfr), "Missing dfr")
	SetWindow $mainPanel, userData($MIES_BSP_FOLDER_TYPE) = GetDataFolder(1, dfr)
End

/// @brief get the assigned DEVICE property from the main panel
///
/// @param win 	name of external panel or main window
///
/// @return device as string
Function/S BSP_GetDevice(win)
	string win

	string mainPanel

	mainPanel = GetMainWindow(win)
	if(IsEmpty(mainPanel))
		return ""
	endif
	ASSERT(WindowExists(mainPanel), "specified panel does not exist.")

	// upgrade folder locations
	GetDAQDevicesFolder()

	return GetUserData(mainPanel, "", MIES_BSP_DEVICE)
End

/// @brief set DEVICE property to the userdata of the main panel
///
/// @param win                      name of external panel or main window
/// @param device                   bound device as string
Function/S BSP_SetDevice(win, device)
	string win, device

	string mainPanel

	ASSERT(WindowExists(win), "specified panel does not exist.")
	ASSERT(BSP_IsDataBrowser(win), "device property only relevant in DB context")

	mainPanel = GetMainWindow(win)
	SetWindow $mainPanel, userdata($MIES_BSP_DEVICE) = device
End

/// @brief get the MIES Browser Type
///
/// @param win 	name of external panel or main window
///
/// @return D for DataBrowser or S for SweepBrowser
Function/S BSP_GetBrowserType(win)
	string win

	string mainPanel

	mainPanel = GetMainWindow(win)
	ASSERT(WindowExists(mainPanel), "specified panel does not exist.")

	return GetUserData(mainPanel, "", MIES_BSP_BROWSER)
End

/// @brief set DEVICE property to the userdata of the main panel
///
/// @param win 	name of external panel or main window
/// @param type One of #BROWSERTYPE_DATABROWSER or #BROWSERTYPE_SWEEPBROWSER
static Function/S BSP_SetBrowserType(string win, string type)
	string mainPanel

	mainPanel = GetMainWindow(win)
	ASSERT(WindowExists(mainPanel), "specified panel does not exist.")

	SetWindow $mainPanel, userdata($MIES_BSP_BROWSER) = type

	if(!CmpStr(type, BROWSERTYPE_SWEEPBROWSER))
		DoWindow/T $mainPanel, SWEEPBROWSER_WINDOW_TITLE
	elseif(!CmpStr(type, BROWSERTYPE_DATABROWSER))
		DoWindow/T $mainPanel, DATABROWSER_WINDOW_TITLE
	endif
End

/// @brief wrapper function for external calls
Function BSP_SetDataBrowser(win)
	string win

	BSP_SetBrowserType(win, BROWSERTYPE_DATABROWSER)
End

/// @brief wrapper function for external calls
Function BSP_SetSweepBrowser(win)
	string win

	BSP_SetBrowserType(win, BROWSERTYPE_SWEEPBROWSER)
End

/// @brief wrapper function for external calls
Function BSP_IsSweepBrowser(win)
	string win

	return !cmpstr(BSP_GetBrowserType(win), BROWSERTYPE_SWEEPBROWSER)
End

/// @brief wrapper function for external calls
Function BSP_IsDataBrowser(win)
	string win

	return !cmpstr(BSP_GetBrowserType(win), BROWSERTYPE_DATABROWSER)
End

/// @brief check if the DEVICE property has a not nullstring property
///
/// @param win 	name of external panel or main window
/// @return 1 if device is assigned and 0 otherwise. does not check if device is valid.
Function BSP_HasBoundDevice(win)
	string win

	string device = BSP_GetDevice(win)

	return !BSP_IsDataBrowser(win) || !(IsEmpty(device) || !cmpstr(device, NONE))
End

/// @brief set the initial state of the enable/disable buttons
///
/// @param win 		name of external panel or main window
static Function BSP_InitMainCheckboxes(win)
	string win

	string bsPanel

	bsPanel = BSP_GetPanel(win)
	if(!WindowExists(bsPanel))
		return NaN
	endif

	BSP_SetOVSControlStatus(bsPanel)
	BSP_SetARControlStatus(bsPanel)

	return 1
End

/// @brief enable/disable the OVS buttons
///
/// @param win 	specify mainPanel or bsPanel with OVS controls
Function BSP_SetOVSControlStatus(win)
	string win

	string controlList = "group_properties_sweeps;popup_overlaySweeps_select;setvar_overlaySweeps_offset;"            \
						 + "setvar_overlaySweeps_step;check_overlaySweeps_disableHS;check_overlaySweeps_non_commula;" \
						 + "list_of_ranges;check_ovs_clear_on_new_ra_cycle;check_ovs_clear_on_new_stimset_cycle"

	BSP_SetControlStatus(win, controlList, OVS_IsActive(win))
End

/// @brief enable/disable the AR buttons
///
/// @param win 	specify mainPanel or bsPanel with OVS controls
Function BSP_SetARControlStatus(win)
	string win

	string controlList = "group_properties_artefact;setvar_cutoff_length_before;setvar_cutoff_length_after;button_RemoveRanges;check_auto_remove;check_highlightRanges;list_of_ranges1;"

	BSP_SetControlStatus(win, controlList, AR_IsActive(win))
End

/// @brief enable/disable the SF buttons
///
/// @param win 	specify mainPanel or bsPanel with OVS controls
Function BSP_SetSFControlStatus(win)
	string win

	string controlList

	controlList = "group_properties_sweepFormula;SF_InfoTab;button_sweepFormula_display;button_sweepFormula_check;setvar_sweepFormula_parseResult;status_sweepFormula_parser;button_sweepFormula_tofront;"
	BSP_SetControlStatus(win, controlList, SF_IsActive(win))
End

/// @brief enable/disable a list of controls
///
/// @param win    		specify mainPanel or bsPanel with OVS controls
/// @param controlList  list of controls
/// @param status       1: enable; 0: disable
Function BSP_SetControlStatus(win, controlList, status)
	string win, controlList
	variable status

	string bsPanel

	status = !!status

	bsPanel = BSP_GetPanel(win)
	ASSERT(windowExists(bsPanel), "BrowserSettingsPanel does not exist.")
	if(status)
		EnableControls(bsPanel, controlList)
	else
		DisableControls(bsPanel, controlList)
	endif
End

/// @brief action for button in mainPanel
///
/// @param mainPanel 	main Panel window
/// @param visible 		set status of external Panel (opened: visible = 1)
Function BSP_MainPanelButtonToggle(mainPanel, visible)
	string mainPanel
	variable visible

	string panelButton

	visible = !!visible ? 1 : 0

	panelButton = "button_BSP_open"
	if(!ControlExists(mainPanel, panelButton))
		return 0
	endif
	if(visible)
		ShowControl(mainPanel, panelButton)
	else
		HideControl(mainPanel, panelButton)
	endif
End

/// @brief panel close hook for side panel
Function BSP_ClosePanelHook(s)
	STRUCT WMWinHookStruct &s

	string mainPanel

	switch(s.eventCode)
		case 17: // killVote
			mainPanel = GetMainWindow(s.winName)
			SetWindow $s.winName hide=1

			BSP_MainPanelButtonToggle(mainPanel, 1)

			return 2 // don't kill window
	endswitch

	return 0
End

/// @brief enable/disable checkbox control for side panel
Function BSP_CheckBoxProc_ArtRemoval(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string mainPanel

	switch(cba.eventCode)
		case 2: // mouse up
			mainPanel = GetMainWindow(cba.win)
			BSP_SetARControlStatus(mainPanel)
			UpdateSweepPlot(mainPanel)
			break
	endswitch

	return 0
End

/// @brief enable/disable checkbox control for side panel
Function BSP_CheckBoxProc_PerPulseAver(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string mainPanel

	switch(cba.eventCode)
		case 2: // mouse up
			mainPanel = GetMainWindow(cba.win)
			PA_Update(mainPanel, POST_PLOT_FULL_UPDATE)
			break
	endswitch

	return 0
End

/// @brief enable/disable checkbox control for side panel
Function BSP_CheckBoxProc_SweepFormula(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string mainPanel

	switch(cba.eventCode)
		case 2: // mouse up
			mainPanel = GetMainWindow(cba.win)
			BSP_SetSFControlStatus(mainPanel)
			break
	endswitch

	return 0
End

/// @brief procedure for the open button of the side panel
Function BSP_ButtonProc_Panel(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string win

	switch(ba.eventcode)
		case 2: // mouse up
			win = GetMainWindow(ba.win)
			BSP_UnHidePanel(win)
			break
	endswitch

	return 0
End

Function BSP_SliderProc_ChangedSetting(spa) : SliderControl
	STRUCT WMSliderAction &spa

	string win

	if(spa.eventCode > 0 && spa.eventCode & 0x1)
		win = spa.win
		UpdateSweepPlot(win)
	endif

	return 0
End

Function BSP_TimeAlignmentProc(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			UpdateSettingsPanel(cba.win)
			break
	endswitch
End

Function BSP_TimeAlignmentPopup(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch(pa.eventCode)
		case 2: // mouse up
			UpdateSettingsPanel(pa.win)
			break
	endswitch

	return 0
End

Function BSP_TimeAlignmentLevel(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			UpdateSettingsPanel(sva.win)
			break
	endswitch

	return 0
End

Function BSP_DoTimeAlignment(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string graph, win

	switch(ba.eventCode)
		case 2: // mouse up

			win = ba.win
			graph = GetMainWindow(win)

			if(!BSP_HasBoundDevice(win))
				UpdateSettingsPanel(win)
				return NaN
			endif

			PostPlotTransformations(graph, POST_PLOT_FULL_UPDATE)
			break
	endswitch

	return 0
End

Function BSP_CheckProc_ScaleAxes(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	string ctrls, graph, bsPanel
	variable numCtrls, i

	switch(cba.eventCode)
		case 2: // mouse up
			graph   = GetMainWindow(cba.win)
			bsPanel = BSP_GetPanel(graph)

			if(cba.checked)
				ctrls = ListMatch(BROWSERSETTINGS_AXES_SCALING_CHECKBOXES, "!" + cba.ctrlName)
				numCtrls = ItemsInList(ctrls)
				for(i = 0; i < numCtrls; i += 1)
					SetCheckBoxState(bsPanel, StringFromList(i, ctrls), CHECKBOX_UNSELECTED)
				endfor
			endif

			if(GetCheckBoxState(bsPanel, "check_Display_EqualYignore"))
				EnableControl(bsPanel, "setvar_Display_EqualYlevel")
			else
				DisableControl(bsPanel, "setvar_Display_EqualYlevel")
			endif

			BSP_ScaleAxes(graph)
			break
	endswitch

	return 0
End

Function BSP_AxisScalingLevelCross(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	string graph, bsPanel

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			graph   = GetMainWindow(sva.win)
			bsPanel = BSP_GetPanel(graph)

			if(GetCheckBoxState(bsPanel, "check_Display_EqualYignore"))
				BSP_ScaleAxes(graph)
			endif
			break
	endswitch

	return 0
End

/// @brief update controls in scPanel and change to new sweep
///
/// @param win 		         name of external panel or main window
/// @param ctrl              name of the button that was pressed and is initiating the update
/// @param firstSweepOrIndex first available sweep(DB) or index(SB)
/// @param lastSweepOrIndex  last available sweep(DB) or index(SB)
///
/// @returns the new sweep number in case of DB or the index for SB
static Function BSP_UpdateSweepControls(win, ctrl, firstSweepOrIndex, lastSweepOrIndex)
	string win, ctrl
	variable firstSweepOrIndex, lastSweepOrIndex

	string graph, scPanel
	variable currentSweep, newSweep, step, direction, ret
	variable firstSweep, lastSweep, firstIndex, lastIndex, currentIndex, newIndex

	graph   = GetMainWindow(win)
	scPanel = BSP_GetSweepControlsPanel(graph)

	if(!HasPanelLatestVersion(graph, DATA_SWEEP_BROWSER_PANEL_VERSION))
		DoAbortNow("The main panel is too old to be usable. Please close it and open a new one.")
	endif

	step = GetSetVariable(scPanel, "setvar_SweepControl_SweepStep")
	if(!cmpstr(ctrl, "button_SweepControl_PrevSweep"))
		direction = -1
	elseif(!cmpstr(ctrl, "button_SweepControl_NextSweep"))
		direction = +1
	else
		ASSERT(0, "unhandled control name")
	endif

	if(BSP_IsDataBrowser(graph))
		firstSweep = firstSweepOrIndex
		lastSweep  = lastSweepOrIndex

		currentSweep = GetSetVariable(scPanel, "setvar_SweepControl_SweepNo")
		newSweep = currentSweep + direction * step
		newSweep = limit(newSweep, firstSweep, lastSweep)

		ret = newSweep
	else
		WAVE sweeps = SB_GetPlainSweepList(win)
		firstIndex = 0
		lastIndex  = DimSize(sweeps, ROWS) - 1

		currentIndex = GetPopupMenuIndex(scPanel, "popup_SweepControl_Selector")
		newIndex = currentIndex + direction * step
		newIndex = limit(newIndex, firstIndex, lastIndex)

		newSweep = sweeps[newIndex]
		firstSweep = sweeps[firstIndex]
		lastSweep = sweeps[lastIndex]

		SetPopupMenuIndex(scPanel, "popup_SweepControl_Selector", newIndex)

		ret = newIndex
	endif

	SetSetVariable(scPanel, "setvar_SweepControl_SweepNo", newSweep)
	SetSetVariableLimits(scPanel, "setvar_SweepControl_SweepNo", firstSweep, lastSweep, step)
	SetValDisplay(scPanel, "valdisp_SweepControl_LastSweep", var = lastSweep)

	return ret
End

/// @brief check if the specified setting is activated
///
/// @param win 			name of external panel or main window
/// @param elementID 	one of MIES_BSP_* constants like MIES_BSP_PA
/// @return 1 if setting was activated, 0 otherwise
Function BSP_IsActive(win, elementID)
	string win
	variable elementID

	string bsPanel, control

	bsPanel = BSP_GetPanel(win)

	// return inactive if panel is outdated or does not exist
	if(!HasPanelLatestVersion(win, DATA_SWEEP_BROWSER_PANEL_VERSION))
		DoAbortNow("The main panel is too old to be usable. Please close it and open a new one.")
		return 0
	endif

	switch(elementID)
		case MIES_BSP_OVS:
			control = "check_BrowserSettings_OVS"
			break
		case MIES_BSP_CS:
			return 1
		case MIES_BSP_AR:
			control = "check_BrowserSettings_AR"
			break
		case MIES_BSP_PA:
			control = "check_BrowserSettings_PA"
			break
		case MIES_BSP_SF:
			control = "check_BrowserSettings_SF"
			break
		case MIES_BSP_DS:
			control = "check_BrowserSettings_DS"
			break
		default:
			return 0
	endswitch

	return GetCheckboxState(bsPanel, control) == CHECKBOX_SELECTED
End

/// @brief Fill the SweepFormula help notebook
///        with the contents of the stored file
Function BSP_UpdateHelpNotebook(win)
	string win

	variable helpVersion
	string name, text, helpNotebook, path

	name = UniqueName("notebook", 10, 0)
	path = GetFolder(FunctionPath("")) + "SweepFormulaHelp.ifn"

	OpenNotebook/Z/V=0/N=$name path
	ASSERT(!V_Flag, "Error opening sweepformula help notebook")

	helpNotebook = BSP_GetSFHELP(win)
	text = GetNotebookText(name)
	ReplaceNotebookText(helpNotebook, text)
	KillWindow/Z $name
End

/// @brief Return a sweep formula graph name unique for that sweepbrowser/databrowser
Function/S BSP_GetFormulaGraph(win)
	string win

	if(!BSP_HasBoundDevice(win))
		return "FormulaPlot"
	endif

	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)

	return CleanupName("FormulaPlot_" + GetDataFolder(0, dfr), 0)
End

/// @brief Parse a control name for the "Channel Selection Panel" and return
///        its channel type and number. The number will be NaN for the ALL control.
Function BSP_ParseChannelSelectionControl(ctrl, channelType, channelNum)
	string ctrl
	string &channelType
	variable &channelNum

	string channelNumStr

	sscanf ctrl, "check_channelSel_%[^_]_%s", channelType, channelNumStr
	ASSERT(V_flag == 2, "Unexpected control name format")

	if(!cmpstr(channelNumStr, "All"))
		channelNum = NaN
	else
		channelNum = str2numSafe(channelNumStr)
		ASSERT(IsInteger(channelNum) && channelNum >= 0, "Unexpected channelNumStr")
	endif
End

/// @brief Set the channel selection dialog controls according to the channel
///        selection wave
Function BSP_ChannelSelectionWaveToGUI(panel, channelSel)
	string panel
	WAVE channelSel

	string list, channelType, ctrl
	variable channelNum, numEntries, i

	list = ControlNameList(panel, ";", "check_channelSel_*")
	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		ctrl = StringFromList(i, list)
		BSP_ParseChannelSelectionControl(ctrl, channelType, channelNum)

		if(IsNaN(channelNum))
			continue
		endif

		SetCheckBoxState(panel, ctrl, channelSel[channelNum][%$channelType])
	endfor
End

/// @brief Set the channel selection wave acccording to the channel selection
///        controls
Function BSP_GUIToChannelSelectionWave(win, ctrl, checked)
	string win, ctrl
	variable checked

	variable channelNum, numEntries
	string channelType

	WAVE channelSel = BSP_GetChannelSelectionWave(win)
	BSP_ParseChannelSelectionControl(ctrl, channelType, channelNum)

	if(isNaN(channelNum))
		numEntries = GetNumberFromType(str=channelType)
		channelSel[0, numEntries - 1][%$channelType] = checked
		Make/FREE/N=(numEntries) junkWave = SetCheckBoxState(win, "check_channelSel_" + channelType + "_" + num2str(p), checked)
	else
		channelSel[channelNum][%$channelType] = checked
	endif
End

/// @brief Removes the disabled channels and headstages from `ADCs`, `DACs` and `statusHS`
///
/// `channelSel` will be the result from BSP_FetchSelectedChannels() which is a
/// copy of the permanent channel selection wave.
Function BSP_RemoveDisabledChannels(channelSel, ADCs, DACs, statusHS, numericalValues, sweepNo)
	WAVE channelSel
	WAVE ADCs, DACs, numericalValues
	variable sweepNo
	WAVE statusHS

	variable numADCs, numDACs, i

	if(IsConstant(channelSel, channelSel[0]))
		return NaN
	endif

	numADCs = DimSize(ADCs, ROWS)
	numDACs = DimSize(DACs, ROWS)

	WAVE/Z statusDAC = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z statusADC = GetLastSetting(numericalValues, sweepNo, "ADC", DATA_ACQUISITION_MODE)

	// disable the AD/DA channels not wanted by the headstage setting first
	// adapt statusHS as well
	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(!channelSel[i][%HEADSTAGE])
			channelSel[statusADC[i]][%AD] = 0
			channelSel[statusDAC[i]][%DA] = 0
			statusHS[i] = 0
		endif
	endfor

	// start at the end of the config wave
	// we always have the order DA/AD/TTLs
	for(i = numADCs - 1; i >= 0; i -= 1)
		if(!channelSel[ADCs[i]][%AD])
			DeletePoints/M=(ROWS) i, 1, ADCs
		endif
	endfor

	for(i = numDACs - 1; i >= 0; i -= 1)
		if(!channelSel[DACs[i]][%DA])
			DeletePoints/M=(ROWS) i, 1, DACs
		endif
	endfor
End

Function BSP_ScaleAxes(win)
	string win

	string graph, bsPanel
	variable visXRange, equalY, equalYIgn, level

	graph      = GetMainWindow(win)
	bsPanel    = BSP_GetPanel(win)
	visXRange  = GetCheckBoxState(bsPanel, "check_Display_VisibleXrange")
	equalY     = GetCheckBoxState(bsPanel, "check_Display_EqualYrange") && !IsControlDisabled(bsPanel, "check_Display_EqualYrange")
	equalYIgn  = GetCheckBoxState(bsPanel, "check_Display_EqualYignore") && !IsControlDisabled(bsPanel, "check_Display_EqualYignore")

	ASSERT(visXRange + equalY + equalYIgn <= 1, "Only one scaling mode is allowed to be selected")

	if(visXRange)
		AutoscaleVertAxisVisXRange(graph)
	elseif(equalY)
		EqualizeVerticalAxesRanges(graph, ignoreAxesWithLevelCrossing=0)
	elseif(equalYIgn)
		level = GetSetVariable(bsPanel, "setvar_Display_EqualYlevel")
		EqualizeVerticalAxesRanges(graph, ignoreAxesWithLevelCrossing=1, level=level)
	else
		// do nothing
	endif
End

Function [STRUCT TiledGraphSettings tgs] BSP_GatherTiledGraphSettings(string win)

	string bsPanel

	bsPanel = BSP_GetPanel(win)

	tgs.displayDAC           = GetCheckBoxState(bsPanel, "check_BrowserSettings_DAC")
	tgs.displayTTL           = GetCheckBoxState(bsPanel, "check_BrowserSettings_TTL")
	tgs.displayADC           = GetCheckBoxState(bsPanel, "check_BrowserSettings_ADC")
	tgs.overlaySweep         = GetCheckBoxState(bsPanel, "check_BrowserSettings_OVS")
	tgs.splitTTLBits         = GetCheckBoxState(bsPanel, "check_BrowserSettings_splitTTL")
	tgs.overlayChannels      = GetCheckBoxState(bsPanel, "check_BrowserSettings_OChan")
	tgs.dDAQDisplayMode      = GetCheckBoxState(bsPanel, "check_BrowserSettings_dDAQ")
	tgs.dDAQHeadstageRegions = GetSliderPositionIndex(bsPanel, "slider_BrowserSettings_dDAQ")
	tgs.hideSweep            = GetCheckBoxState(bsPanel, "check_SweepControl_HideSweep")

	if(tgs.overlayChannels)
		tgs.splitTTLBits = 0
	endif
End

Function BSP_CheckProc_ChangedSetting(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string graph, bsPanel, ctrl
	variable checked

	switch(cba.eventCode)
		case 2: // mouse up
			ctrl    = cba.ctrlName
			checked = cba.checked
			graph   = GetMainWindow(cba.win)
			bsPanel = BSP_GetPanel(graph)

			if(!HasPanelLatestVersion(graph, DATA_SWEEP_BROWSER_PANEL_VERSION))
				DoAbortNow("The main panel is too old to be usable. Please close it and open a new one.")
			endif

			strswitch(ctrl)
				case "check_BrowserSettings_dDAQ":
					if(checked)
						EnableControl(bsPanel, "slider_BrowserSettings_dDAQ")
					else
						DisableControl(bsPanel, "slider_BrowserSettings_dDAQ")
					endif
					break
				case "check_BrowserSettings_DAC":
					if(checked)
						EnableControl(bsPanel, "check_BrowserSettings_VisEpochs")
					else
						DisableControl(bsPanel, "check_BrowserSettings_VisEpochs")
					endif
					break
				case "check_BrowserSettings_TTL":
					if(checked)
						EnableControl(bsPanel, "check_BrowserSettings_splitTTL")
					else
						DisableControl(bsPanel, "check_BrowserSettings_splitTTL")
					endif
					break
				case "check_BrowserSettings_VisEpochs":
#if IgorVersion() >= 9.0
					if(checked)
						DisableControls(bsPanel, "check_Display_EqualYrange;check_Display_EqualYignore")
					else
						EnableControls(bsPanel, "check_Display_EqualYrange;check_Display_EqualYignore")
					endif
#else
					print "Epoch visualization is an Igor Pro 9 only feature."
					ControlWindowToFront()
#endif
					break
				default:
					if(StringMatch(ctrl, "check_channelSel_*"))
						BSP_GUIToChannelSelectionWave(bsPanel, ctrl, checked)
					endif
					break
			endswitch

			UpdateSweepPlot(graph)
			break
	endswitch

	return 0
End

Function BSP_ButtonProc_RestoreData(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string bspPanel, bsPanel, graph, device, datafolder
	variable numEntries, i, sweepNo

	switch(ba.eventCode)
		case 2: // mouse up
			graph = GetMainWindow(ba.win)
			bsPanel = BSP_GetPanel(graph)

			if(!BSP_HasBoundDevice(graph))
				break
			endif

			if(BSP_IsDataBrowser(graph))
				device = BSP_GetDevice(graph)
				DFREF deviceDFR = GetDeviceDataPath(device)

				WAVE/Z sweeps = GetPlainSweepList(graph)

				if(!WaveExists(sweeps))
					break
				endif

				numEntries = DimSize(sweeps, ROWS)
				for(i = 0; i < numEntries; i += 1)
					DFREF singleSweepDFR = GetSingleSweepFolder(deviceDFR, i)
					ReplaceWaveWithBackupForAll(singleSweepDFR)
				endfor
			else
				DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(graph)
				WAVE/T sweepMap = GetSweepBrowserMap(sweepBrowserDFR)

				numEntries = GetNumberFromWaveNote(sweepMap, NOTE_INDEX)
				for(i = 0; i < numEntries; i += 1)
					dataFolder = sweepMap[i][%DataFolder]
					device     = sweepMap[i][%Device]
					sweepNo    = str2num(sweepMap[i][%Sweep])
					DFREF sweepDFR = GetAnalysisSweepPath(dataFolder, device)
					DFREF singleSweepDFR = GetSingleSweepFolder(sweepDFR, sweepNo)
					ReplaceWaveWithBackupForAll(singleSweepDFR)
				endfor
			endif

			SetCheckBoxState(bsPanel, "check_Calculation_ZeroTraces", CHECKBOX_UNSELECTED)
			SetCheckBoxState(bsPanel, "check_auto_remove", CHECKBOX_UNSELECTED)
			SetCheckBoxState(bsPanel, "check_BrowserSettings_TA", CHECKBOX_UNSELECTED)

			UpdateSweepPlot(graph)
			break
	endswitch

	return 0
End

Function BSP_CheckProc_OverlaySweeps(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string graph, bsPanel

	switch(cba.eventCode)
		case 2: // mouse up
			graph   = GetMainWindow(cba.win)
			bsPanel = BSP_GetPanel(graph)

			BSP_SetOVSControlStatus(bsPanel)
			OVS_UpdatePanel(graph, fullUpdate = 1)

			break
	endswitch

	return 0
End

/// @brief Generic getter for labnotebook waves.
///
/// Works with Databrowser/Sweepbrowser
///
/// @param win               panel
/// @param type              One of @ref LabnotebookWaveTypes
/// @param sweepNumber       [optional] sweep number
/// @param selectedExpDevice [optional, defaults to off] return the labnotebook for the selected experiment/device combination
Function/WAVE BSP_GetLBNWave(string win, variable type, [variable sweepNumber, variable selectedExpDevice])
	string shPanel, device, dataFolder

	if(ParamIsDefault(selectedExpDevice))
		selectedExpDevice = 0
	else
		selectedExpDevice = !!selectedExpDevice
	endif

	if(BSP_IsDataBrowser(win))
		// for all sweep numbers the same LBN
		if(ParamIsDefault(sweepNumber) && !selectedExpDevice)
			WAVE/Z sweeps = GetPlainSweepList(win)

			if(!WaveExists(sweeps))
				return $""
			endif

			Make/FREE/WAVE/N=(DimSize(sweeps, ROWS)) waves = DB_GetLBNWave(win, type)
			return waves
		elseif(selectedExpDevice)
			return DB_GetLBNWave(win, type)
		elseif(!ParamIsDefault(sweepNumber))
			ASSERT(IsValidSweepNumber(sweepNumber), "Unsupported sweep number")
			return DB_GetLBNWave(win, type)
		else
			ASSERT(0, "Invalid parameter combination")
		endif
	else
		if(ParamIsDefault(sweepNumber) && !selectedExpDevice)
			return SB_GetLBNWave(win, type)
		elseif(selectedExpDevice)
			shPanel = LBV_GetSettingsHistoryPanel(win)

			dataFolder = GetPopupMenuString(shPanel, "popup_experiment")
			device = GetPopupMenuString(shPanel, "popup_Device")

			if(!cmpstr(dataFolder, NONE) || !cmpstr(device, NONE))
				return $""
			endif

			return SB_GetLBNWave(win, type, dataFolder = dataFolder, device = device)
		elseif(!ParamIsDefault(sweepNumber))
			ASSERT(IsValidSweepNumber(sweepNumber), "Unsupported sweep number")
			return SB_GetLBNWave(win, type, sweepNumber = sweepNumber)
		else
			ASSERT(0, "Invalid parameter combination")
		endif
	endif
End

/// @brief Return the wave with the selected channels respecting the overlay
/// sweeps headstage ignore list. The wave has the same layout as BSP_GetChannelSelectionWave.
Function/WAVE BSP_FetchSelectedChannels(string graph, [variable index, variable sweepNo])

	if(ParamIsDefault(index) && !ParamIsDefault(sweepNo))
		WAVE/Z activeHS = OVS_GetHeadstageRemoval(graph, sweepNo=sweepNo)
	elseif(!ParamIsDefault(index) && ParamIsDefault(sweepNo))
		WAVE/Z activeHS = OVS_GetHeadstageRemoval(graph, index=index)
	else
		ASSERT(0, "Invalid optional flags")
	endif

	WAVE channelSelOriginal = BSP_GetChannelSelectionWave(graph)
	Duplicate/FREE channelSelOriginal, channelSel

	if(!WaveExists(activeHS))
		return channelSel
	endif

	channelSel[0, NUM_HEADSTAGES - 1][%HEADSTAGE] = channelSel[p][%HEADSTAGE] && activeHS[p]

	return channelSel
End

/// @brief Return the last and first sweep numbers
Function [variable first, variable last] BSP_FirstAndLastSweepAcquired(string win)
	string list

	WAVE/Z sweeps = GetPlainSweepList(win)

	if(!WaveExists(sweeps))
		return [NaN, NaN]
	endif

	return [sweeps[0], sweeps[DimSize(sweeps, ROWS) - 1]]
End

Function BSP_ButtonProc_ChangeSweep(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string graph, scPanel
	variable first, last, formerLast, sweepNo, overlaySweeps
	variable index

	switch(ba.eventcode)
		case 2: // mouse up
			graph = GetMainWindow(ba.win)
			scPanel = BSP_GetSweepControlsPanel(graph)
			overlaySweeps = OVS_IsActive(graph)

			[first, last] = BSP_FirstAndLastSweepAcquired(graph)

			if(BSP_IsDataBrowser(graph))
				DB_UpdateLastSweepControls(graph, first, last)
				sweepNo = BSP_UpdateSweepControls(graph, ba.ctrlName, first, last)
				OVS_ChangeSweepSelectionState(graph, CHECKBOX_SELECTED, sweepNo=sweepNo)
			else
				index = BSP_UpdateSweepControls(graph, ba.ctrlName, first, last)
				OVS_ChangeSweepSelectionState(graph, CHECKBOX_SELECTED, index=index)
			endif

			if(!overlaySweeps)
				UpdateSweepPlot(graph)
			endif
			break
	endswitch

	return 0
End

// Called from ACL_DisplayTab after the new tab is selected
Function BSP_MainTabControlFinal(tca)
	STRUCT WMTabControlAction &tca

	BSP_UpdateSweepNote(tca.win)
End

Function BSP_UpdateSweepNote(win)
	string win

	string scPanel, lbPanel, bsPanel, device, sweepNote
	string dataFolder, graph
	variable sweepNo, index

	bsPanel = BSP_GetPanel(win)

	if(GetTabID(bsPanel, "Settings") != 6)
		// nothing to do
		return NaN
	endif

	if(BSP_IsDataBrowser(win))
		if(!BSP_HasBoundDevice(win))
			return NaN
		endif

		scPanel = BSP_GetSweepControlsPanel(win)
		sweepNo = GetSetVariable(scPanel, "setvar_SweepControl_SweepNo")

		device = BSP_GetDevice(win)
		DFREF dfr = GetDeviceDataPath(device)

		WAVE/Z/SDFR=dfr sweepWave = $GetSweepWaveName(sweepNo)
		if(!WaveExists(sweepWave))
			return NaN
		endif

		sweepNote = note(sweepWave)
	else
		graph = GetMainWindow(win)

		scPanel = BSP_GetSweepControlsPanel(win)
		index = GetPopupMenuIndex(scPanel, "Popup_SweepControl_Selector")

		DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(graph)
		WAVE/T sweepMap = GetSweepBrowserMap(sweepBrowserDFR)

		dataFolder = sweepMap[index][%DataFolder]
		device     = sweepMap[index][%Device]
		sweepNo    = str2num(sweepMap[index][%Sweep])

		DFREF dfr = GetAnalysisSweepDataPath(dataFolder, device, sweepNo)
		SVAR/SDFR=dfr/Z sweepNoteSVAR = note
		if(!SVAR_EXISTS(sweepNoteSVAR))
			return NaN
		endif
		sweepNote = sweepNoteSVAR
	endif

	lbPanel = BSP_GetNotebookSubWindow(win)
	ReplaceNotebookText(lbPanel, sweepNote)
End

Function BSP_DynamicSettingsHistory(string win)
	string shPanel

	shPanel = LBV_GetSettingsHistoryPanel(win)

	SetWindow $shPanel, hook(main)=DB_CloseSettingsHistoryHook
End

/// @brief Unsets all control properties that are set in DB_DynamicSettingsHistory
Function BSP_UnsetDynamicSettingsHistory(win)
	string win

	string shPanel

	shPanel = LBV_GetSettingsHistoryPanel(win)
	ASSERT(WindowExists(shPanel), "external SettingsHistory panel not found")
	SetWindow $shPanel, hook(main)=$""
End

Function BSP_UnHideSettingsHistory(win)
	string win

	string settingsHistoryPanel

	ASSERT(WindowExists(GetMainWindow(win)), "HOST panel does not exist")

	settingsHistoryPanel = LBV_GetSettingsHistoryPanel(win)
	if(WindowExists(settingsHistoryPanel))
		SetWindow $settingsHistoryPanel hide=0, needUpdate=1
	endif
End

#if IgorVersion() >= 9.0

/// @brief Debug function to add traces with epoch information
Function BSP_AddTracesForEpochs(string win)

	variable i, j, k, numEntries, start_x, start_y, end_x, end_y, yOffset
	variable headstage, yLevelOffset, level, idx, numTraces, numEpochs
	variable sweepNumber
	STRUCT RGBColor c
	string xaxis, yaxis, axes, axis, levels_x_name, levels_y_name, name
	string level_0_trace, level_1_trace, level_2_trace, level_3_trace

	if(!BSP_IsDataBrowser(win) && !BSP_IsSweepBrowser(win))
		printf "The current window is neither a databrowser nor a sweepbrowser windows.\r"
		ControlWindowToFront()
		return Nan
	endif

	DFREF dfr = GetEpochsVisualizationFolder(BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER))
	RemoveTracesFromGraph(win, dfr = dfr)

	WAVE/T/Z traceInfos = GetTraceInfos(win, addFilterKeys = {"channelType", "AssociatedHeadstage"}, addFilterValues = {"DA", "1"})

	if(!WaveExists(traceInfos))
		printf "Could not find any DA traces. Please enable them for display.\r"
		ControlWindowToFront()
		return NaN
	endif

	numTraces = DimSize(traceInfos, ROWS)
	for(j = 0; j < numTraces; j += 1)
		yaxis = traceInfos[j][%YAXIS]
		xaxis = traceInfos[j][%XAXIS]

		headstage   = str2num(traceInfos[j][%headstage])
		sweepNumber = str2num(traceInfos[j][%sweepNumber])

		WAVE/T textualValues = BSP_GetlBNWave(win, LBN_TEXTUAL_VALUES, sweepNumber = sweepNumber)

		WAVE/T epochLBEntries = GetLastSetting(textualValues, sweepNumber, EPOCHS_ENTRY_KEY, DATA_ACQUISITION_MODE)
		WAVE/T epochs = ListToTextWaveMD(epochLBEntries[headstage], 2, rowSep = ":", colSep = ",")

		sprintf name, "epochs_sweep%d_HS%d", sweepNumber, headstage

		Duplicate/O/T epochs, dfr:$name/Wave=epochs

		yLevelOffset = 10
		yOffset = - yLevelOffset

		numEpochs = DimSize(epochs, ROWS)

		Make/FREE/N=(4) currentLevel, indexInLevel

		sprintf levels_x_name, "levels_x_sweep%d_HS%d", sweepNumber, headstage
		Make/O/N=(numEpochs * 3, 4, 2) dfr:$levels_x_name/WAVE=levels_x
		levels_x = NaN

		sprintf levels_y_name, "levels_y_sweep%d_HS%d", sweepNumber, headstage
		Make/O/N=(numEpochs * 3, 4, 2) dfr:$levels_y_name/WAVE=levels_y
		levels_y = NaN
		SetStringInWaveNote(levels_y, "EpochInfo", GetWavesDataFolder(epochs, 2))

		for(k = 0; k < numEpochs; k += 1)

			start_x = str2num(epochs[k][0]) * 1000
			end_x   = str2num(epochs[k][1]) * 1000

			level = str2num(epochs[k][3])

			start_y = yOffset - yLevelOffset * level  - 0.1 * yLevelOffset * currentLevel[level]
			end_y = start_y

			idx = indexInLevel[level]
			levels_x[idx][level][0] = start_x
			levels_x[idx + 1][level][0] = end_x
			levels_x[idx + 2][level][0] = NaN
			levels_x[idx, idx + 2][level][1] = k

			levels_y[idx][level][0] = start_y
			levels_y[idx + 1][level][0] = end_y
			levels_y[idx + 2][level][0] = NaN
			levels_y[idx, idx + 2][level][1] = k

			indexInLevel[level] = idx + 3

			currentLevel[level] += 1
		endfor

		sprintf level_0_trace, "level%d_x_sweep%d_HS%d", 0, sweepNumber, headstage
		sprintf level_1_trace, "level%d_x_sweep%d_HS%d", 1, sweepNumber, headstage
		sprintf level_2_trace, "level%d_x_sweep%d_HS%d", 2, sweepNumber, headstage
		sprintf level_3_trace, "level%d_x_sweep%d_HS%d", 3, sweepNumber, headstage

		AppendToGraph/W=$win/L=$yAxis levels_y[][0]/TN=$level_0_trace vs levels_x[][0]
		AppendToGraph/W=$win/L=$yAxis levels_y[][1]/TN=$level_1_trace vs levels_x[][1]
		AppendToGraph/W=$win/L=$yAxis levels_y[][2]/TN=$level_2_trace vs levels_x[][2]
		AppendToGraph/W=$win/L=$yAxis levels_y[][3]/TN=$level_3_trace vs levels_x[][3]

		[c] = GetTraceColor(0)
		ModifyGraph/W=$win marker($level_0_trace)=10, mode($level_0_trace)=4, rgb($level_0_trace)=(c.red, c.green, c.blue)
		[c] = GetTraceColor(1)
		ModifyGraph/W=$win marker($level_1_trace)=10, mode($level_1_trace)=4, rgb($level_1_trace)=(c.red, c.green, c.blue)
		[c] = GetTraceColor(2)
		ModifyGraph/W=$win marker($level_2_trace)=10, mode($level_2_trace)=4, rgb($level_2_trace)=(c.red, c.green, c.blue)
		[c] = GetTraceColor(3)
		ModifyGraph/W=$win marker($level_3_trace)=10, mode($level_3_trace)=4, rgb($level_3_trace)=(c.red, c.green, c.blue)

		SetWindow $win tooltipHook(hook) = BSP_EpochGraphToolTip

		DoWindow/F $win
		ShowTraceInfoTags()

		SetAxis/W=$win/A
	endfor
End

Function BSP_EpochGraphToolTip(s)
	STRUCT WMTooltipHookStruct &s

	variable idx, first, last
	Variable hookResult = 0 // 0 tells Igor to use the standard tooltip

	// traceName is set only for graphs and only if the mouse hovered near a trace
	if (strlen(s.traceName) > 0)
		s.tooltip = "a <-> b"
		s.isHtml = 1
		WAVE w = s.yWave // The trace's Y wave
		if (WaveDims(w) > 2)
			WAVE/T/Z epochs = $GetStringFromWaveNote(w, "EpochInfo")
			ASSERT(WaveExists(epochs), "Missing epoch info")
			hookResult = 1 // 1 tells Igor to use our custom tooltip
			idx = w[s.row][s.column][1]
			first = str2num(epochs[idx][0]) * 1000
			last  = str2num(epochs[idx][1]) * 1000

			s.tooltip = num2str(first) + "<->" + num2str(last) + "\n" + epochs[idx][2]
		endif
	endif

	return hookResult
End

#else

Function BSP_AddTracesForEpochs(string win)

	BUG("Epoch visualization is an IP9-only feature")
End

#endif
