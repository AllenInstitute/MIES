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

static strConstant BROWSERTYPE_DATABROWSER  = "D"
static strConstant BROWSERTYPE_SWEEPBROWSER = "S"

/// @brief exclusive controls that are enabled/disabled for the specific browser window type
static StrConstant BROWSERSETTINGS_CONTROLS_DATABROWSER = "popup_DB_lockedDevices;"
static StrConstant BROWSERSETTINGS_AXES_SCALING_CHECKBOXES = "check_Display_VisibleXrange;check_Display_EqualYrange;check_Display_EqualYignore"

/// @brief exclusive controls that are enabled/disabled for the specific browser window type
static StrConstant SWEEPCONTROL_CONTROLS_DATABROWSER = "check_SweepControl_AutoUpdate;setvar_SweepControl_SweepNo;"
static StrConstant SWEEPCONTROL_CONTROLS_SWEEPBROWSER = "popup_SweepControl_Selector;"

static StrConstant BSP_USER_DATA_SF_CONTENT_CRC = "SweepFormulaContentCRC"

static Constant BSP_EPOCH_LEVELS = 5

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

	BSP_AddWindowHooks(mainPanel)

	graph = LBV_GetLabNoteBookGraph(mainPanel)
	TUD_Init(graph)
End

/// @brief UnHides BrowserSettings side Panel
///
/// @param mainPanel 	mainWindow panel name
static Function BSP_UnHidePanel(mainPanel)
	string mainPanel

	BSP_UnHideSweepControls(mainPanel)
	BSP_UnHideSettingsPanel(mainPanel)
	BSP_UnHideSettingsHistory(mainPanel)

	BSP_MainPanelButtonToggle(mainPanel, 0)
End

static Function BSP_UnHideSettingsPanel(mainPanel)
	string mainPanel

	string bsPanel

	if(!HasPanelLatestVersion(mainPanel, DATA_SWEEP_BROWSER_PANEL_VERSION))
		DoAbortNow("The main panel is too old to be usable. Please close it and open a new one.")
	endif

	bsPanel = BSP_GetPanel(mainPanel)

	SetWindow $bsPanel, hide=0, needUpdate=1
End

/// @brief open bottom Panel
///
/// @param mainPanel 	mainWindow panel name
static Function BSP_UnHideSweepControls(mainPanel)
	string mainPanel

	string scPanel

	mainPanel = GetMainWindow(mainPanel)
	ASSERT(WindowExists(mainPanel), "HOST panel does not exist")
	scPanel = BSP_GetSweepControlsPanel(mainPanel)
	ASSERT(WindowExists(scPanel), "SweepControl panel does not exist")

	SetWindow $scPanel, hide=0, needUpdate=1
End

/// @brief dynamic settings for bottom panel at initialization
///
/// @param mainPanel 	mainWindow panel name
static Function BSP_DynamicSweepControls(mainPanel)
	string mainPanel

	string scPanel

	scPanel = BSP_GetSweepControlsPanel(mainPanel)
	ASSERT(WindowExists(scPanel), "external SweepControl Panel not found")

	SetSetVariable(scPanel, "setvar_SweepControl_SweepNo", 0)
	SetSetVariableLimits(scPanel, "setvar_SweepControl_SweepNo", 0, 0, 1)
	SetValDisplay(scPanel, "valdisp_SweepControl_LastSweep", var=NaN)
	SetSetVariable(scPanel, "setvar_SweepControl_SweepStep", 1)

	if(BSP_IsDataBrowser(mainPanel))
		SetControlProcedures(scPanel, "setvar_SweepControl_SweepNo;", "DB_SetVarProc_SweepNo")
		EnableControls(scPanel, SWEEPCONTROL_CONTROLS_DATABROWSER)
		DisableControls(scPanel, SWEEPCONTROL_CONTROLS_SWEEPBROWSER)
	else
		PopupMenu popup_SweepControl_Selector, win=$scPanel, value= #("SB_GetSweepList(\"" + mainPanel + "\")")
		SetControlProcedures(scPanel, "popup_SweepControl_Selector;", "SB_PopupMenuSelectSweep")
		EnableControls(scPanel, SWEEPCONTROL_CONTROLS_SWEEPBROWSER)
		DisableControls(scPanel, SWEEPCONTROL_CONTROLS_DATABROWSER)
	endif
End

/// @brief Add default window hooks
static Function BSP_AddWindowHooks(string win)

	string scPanel, bsPanel, shPanel, mainPanel

	mainPanel = GetMainWindow(win)

	SetWindow $mainPanel, hook(cleanup)=BSP_WindowHook

	scPanel = BSP_GetSweepControlsPanel(win)
	SetWindow $scPanel, hook(main)=BSP_ClosePanelHook

	bsPanel = BSP_GetPanel(win)
	SetWindow $bsPanel, hook(main)=BSP_ClosePanelHook
	SetWindow $bsPanel, hook(sweepFormula)=BSP_SweepFormulaHook
	SetWindow $bsPanel, hook(nbinteract)=BSP_SFHelpWindowHook
	SetWindow $bsPanel, tooltipHook(nbinteract)=BSP_TTHookSFFormulaNB

	shPanel = LBV_GetSettingsHistoryPanel(win)
	SetWindow $shPanel, hook(main)=BSP_ClosePanelHook
	SetWindow $shPanel, hook(description)=LBV_EntryDescription
	SetWindow $shPanel, hook(resetScaling)=IH_ResetScaling
End

/// @brief Remove all window hooks from the window and its subwindows
Function BSP_RemoveWindowHooks(string win)

	string scPanel, bsPanel, shPanel, mainPanel

	mainPanel = GetMainWindow(win)

	SetWindow $mainPanel, hook(cleanup)=$""

	scPanel = BSP_GetSweepControlsPanel(win)
	SetWindow $scPanel, hook(main)=$""

	bsPanel = BSP_GetPanel(win)
	SetWindow $bsPanel, hook(main)=$""
	SetWindow $bsPanel, hook(sweepFormula)=$""
	SetWindow $bsPanel, hook(nbinteract)=$""
	SetWindow $bsPanel, tooltipHook(nbinteract)=$""

	shPanel = LBV_GetSettingsHistoryPanel(win)
	SetWindow $shPanel, hook(main)=$""
	SetWindow $shPanel, hook(description)=$""
	SetWindow $shPanel, hook(resetScaling)=$""
End

/// @brief dynamic settings for panel initialization
///
/// @param mainPanel 	mainWindow panel name
Function BSP_DynamicStartupSettings(mainPanel)
	string mainPanel

	variable sweepNo
	string bsPanel, shPanel, experiments, devices

	bsPanel = BSP_GetPanel(mainPanel)

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
	PopupMenu popup_TimeAlignment_Master, win=$bsPanel, value = #("TimeAlignGetAllTraces(\"" + mainPanel + "\")")

	BSP_InitMainCheckboxes(bsPanel)

	BSP_UpdateHelpNotebook(mainPanel)

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
		case EVENT_WINDOW_HOOK_KEYBOARD: // keyboard
			if(s.specialKeyCode == 200 && s.eventMod & WINDOW_HOOK_EMOD_SHIFTKEYDOWN) // Enter + Shift
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
Function BSP_UnsetDynamicStartupSettings(mainPanel)
	string mainPanel

	string bsPanel, shPanel

	ASSERT(BSP_IsDataBrowser(mainPanel), "Browser window is not of type DataBrowser")
	bsPanel = BSP_GetPanel(mainPanel)
	ASSERT(WindowExists(bsPanel), "external BrowserSettings panel not found")
	SetWindow $bsPanel, userData(panelVersion) = ""
	PopupMenu popup_overlaySweeps_select, win=$bsPanel, value=""
	PopupMenu popup_TimeAlignment_Master, win=$bsPanel, value = ""
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
/// @param win          name of external panel or main window
/// @param folderType   see the FOLDER constants in this file
/// @param versionCheck [optional, defaults to true] abort on outdated window version
///
/// @return DFR to specified folder. No check for invalid folders
Function/DF BSP_GetFolder(win, folderType, [versionCheck])
	string win, folderType
	variable versionCheck

	string mainPanel

	if(ParamIsDefault(versionCheck))
		versionCheck = 1
	else
		versionCheck = !!versionCheck
	endif

	if(versionCheck && !HasPanelLatestVersion(win, DATA_SWEEP_BROWSER_PANEL_VERSION))
		DoAbortNow("The main panel is too old to be usable. Please close it and open a new one.")
	endif

	mainPanel = GetMainWindow(win)

	DFREF dfr = $GetUserData(mainPanel, "", folderType)
	ASSERT(DataFolderExistsDFR(dfr), "DataFolder does not exist. Probably check device assignment.")

	return dfr
End

/// @brief set a FOLDER property at the specified panel
///
/// @param win 			name of external panel or main window
/// @param dfr 			DataFolder Reference to the folder
/// @param folderType 	see the FOLDER constants in this file
Function BSP_SetFolder(win, dfr, folderType)
	string win, folderType
	DFREF dfr

	string mainPanel

	mainPanel = GetMainWindow(win)
	ASSERT(WindowExists(mainPanel), "specified panel does not exist.")

	ASSERT(DataFolderExistsDFR(dfr), "Missing dfr")
	SetWindow $mainPanel, userData($folderType) = GetDataFolder(1, dfr)
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
/// @param win 	   name of external panel or main window
/// @param type    One of #BROWSERTYPE_DATABROWSER or #BROWSERTYPE_SWEEPBROWSER
/// @param mode    One of @ref BrowserModes
static Function/S BSP_SetBrowserType(string win, string type, variable mode)
	string mainPanel

	string title, suffix

	mainPanel = GetMainWindow(win)
	ASSERT(WindowExists(mainPanel), "specified panel does not exist.")

	SetWindow $mainPanel, userdata($MIES_BSP_BROWSER) = type

	if(mode == BROWSER_MODE_USER)
		suffix = ""
	elseif(mode == BROWSER_MODE_AUTOMATION)
		suffix = " (A*U*T*O*M*A*T*I*O*N)"
	endif

	SetWindow $mainPanel, userdata($MIES_BSP_BROWSER_MODE) = BSP_SerializeBrowserMode(mode)

	if(!CmpStr(type, BROWSERTYPE_SWEEPBROWSER))
		title = SWEEPBROWSER_WINDOW_NAME
	elseif(!CmpStr(type, BROWSERTYPE_DATABROWSER))
		title = DATABROWSER_WINDOW_NAME
	else
		ASSERT(0, "Invalid type")
	endif

	title += suffix

	DoWindow/T $mainPanel, title
End

static Function BSP_ParseBrowserMode(string mode)
	strswitch(mode)
		case "User":
			return BROWSER_MODE_USER
		case "Automation":
			return BROWSER_MODE_AUTOMATION
		case "All":
			return BROWSER_MODE_ALL
		default:
			ASSERT(0, "Invalid mode")
	endswitch
End

static Function/S BSP_SerializeBrowserMode(variable mode)
	switch(mode)
		case BROWSER_MODE_USER:
			return "User"
		case BROWSER_MODE_AUTOMATION:
			return "Automation"
		case BROWSER_MODE_ALL:
			return "All"
		default:
			ASSERT(0, "Invalid mode")
	endswitch
End

Function BSP_HasMode(string win, variable mode)

	string mainPanel
	variable foundMode

	mainPanel = GetMainWindow(win)
	foundMode = BSP_ParseBrowserMode(GetUserData(mainPanel, "", MIES_BSP_BROWSER_MODE))

	return foundMode & mode
End

/// @brief wrapper function for external calls
Function BSP_SetDataBrowser(string win, variable mode)

	BSP_SetBrowserType(win, BROWSERTYPE_DATABROWSER, mode)
End

/// @brief wrapper function for external calls
Function BSP_SetSweepBrowser(string win, variable mode)

	BSP_SetBrowserType(win, BROWSERTYPE_SWEEPBROWSER, mode)
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
	BSP_SetSFControlStatus(bsPanel)

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

	controlList = "group_properties_sweepFormula;SF_InfoTab;button_sweepFormula_display;button_sweepFormula_check;setvar_sweepFormula_parseResult;status_sweepFormula_parser;button_sweepFormula_tofront;button_sweepformula_all_code"
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
static Function BSP_MainPanelButtonToggle(mainPanel, visible)
	string mainPanel
	variable visible

	string panelButton

	visible = !!visible ? 1 : 0

	panelButton = "button_BSP_open"

	if(!ControlExists(mainPanel, panelButton) || IsControlDisabled(mainPanel, panelButton))
		return NaN
	endif

	if(visible)
		ShowControl(mainPanel, panelButton)
	else
		HideControl(mainPanel, panelButton)
	endif
End

static Function BSP_HidePanel(string win)

	string mainPanel, currentWindow

	currentWindow = GetMainWindow(GetCurrentWindow())

	mainPanel = GetMainWindow(win)
	SetWindow $win, hide=1

	DoWindow/F $currentWindow

	BSP_MainPanelButtonToggle(mainPanel, 1)
End

/// @brief panel close hook for side panel
Function BSP_ClosePanelHook(s)
	STRUCT WMWinHookStruct &s

	string mainPanel

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_KILLVOTE:
			BSP_HidePanel(s.winName)

			return 2 // don't kill window
	endswitch

	return 0
End

Function BSP_SweepsAndMouseWheel(s)
	STRUCT WMWinHookStruct &s

	string graph, scPanel, ctrl

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_MOUSEWHEEL:
			graph = GetMainWindow(s.winName)

			if(!windowExists(graph))
				break
			endif

			if(!(s.eventMod & WINDOW_HOOK_EMOD_ALTKEYDOWN))
				break
			endif

			scPanel = BSP_GetSweepControlsPanel(graph)

			// ALT changes the scroll direction and the sign
			if(sign(s.wheelDx) == -1) // negative
				ctrl = "button_SweepControl_PrevSweep"
			else //negative
				ctrl = "button_SweepControl_NextSweep"
			endif

			PGC_SetAndActivateControl(scPanel, ctrl)
			break
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

	helpNotebook = BSP_GetSFHELP(win)
	text = GetNotebookText(helpNotebook, mode = 2)

	if(!IsEmpty(text))
		return NaN
	endif

	name = UniqueName("notebook", 10, 0)
	path = GetFolder(FunctionPath("")) + "SweepFormulaHelp.ifn"

	OpenNotebook/Z/V=0/N=$name path
	ASSERT(!V_Flag, "Error opening sweepformula help notebook")

	text = GetNotebookText(name)
	ReplaceNotebookText(helpNotebook, text)
	KillWindow/Z $name
End

/// @brief Return a sweep formula graph name unique for that sweepbrowser/databrowser
Function/S BSP_GetFormulaGraph(win)
	string win

	if(!BSP_HasBoundDevice(win))
		return CleanupName(SF_PLOT_NAME_TEMPLATE, 0)
	endif

	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)

	return CleanupName(SF_PLOT_NAME_TEMPLATE + GetDataFolder(0, dfr), 0)
End

Function/S BSP_GetFormulaGraphTitle(string win)

	GetWindow $win, wtitle

	return SF_PLOT_NAME_TEMPLATE + " from <" + S_Value + ">"
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
	tgs.visualizeEpochs       = GetCheckBoxState(bsPanel, "check_BrowserSettings_VisEpochs")

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
				case "check_BrowserSettings_TTL":
					if(checked && !GetCheckBoxState(bsPanel, "check_BrowserSettings_VisEpochs"))
						EnableControl(bsPanel, "check_BrowserSettings_splitTTL")
					else
						DisableControl(bsPanel, "check_BrowserSettings_splitTTL")
					endif
					break
				case "check_BrowserSettings_VisEpochs":
					if(GetCheckBoxState(bsPanel, "check_BrowserSettings_TTL"))
						AdaptDependentControls(bsPanel, "check_BrowserSettings_splitTTL", CHECKBOX_UNSELECTED, checked, DEP_CTRLS_SAME)
					endif
					if(checked)
						DisableControls(bsPanel, "check_Display_EqualYrange;check_Display_EqualYignore")
					else
						EnableControls(bsPanel, "check_Display_EqualYrange;check_Display_EqualYignore")
					endif
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

	string bspPanel, bsPanel, graph, device
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
					DFREF sweepDFR = SB_GetSweepDataFolder(sweepMap, index = i)
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

/// @brief Generic getter for logbook waves
///
/// Works with Databrowser/Sweepbrowser.
///
/// For the Sweepbrowser this returns the stored logbooks.
/// If you want to fetch the global results wave use GetLogbookWaves().
///
/// @param win               panel
/// @param logbookType       one of @ref LogbookTypes
/// @param logbookWaveType   one of @ref LabnotebookWaveTypes
/// @param sweepNumber       [optional] sweep number
/// @param selectedExpDevice [optional, defaults to off] return the labnotebook for the selected experiment/device combination
///
/// @returns returns the specified logbook wave or a null wave
Function/WAVE BSP_GetLogbookWave(string win, variable logbookType, variable logbookWaveType, [variable sweepNumber, variable selectedExpDevice])
	string shPanel, device, dataFolder

	if(ParamIsDefault(selectedExpDevice))
		selectedExpDevice = 0
	else
		selectedExpDevice = !!selectedExpDevice
	endif

	if(BSP_IsDataBrowser(win))
		device = BSP_GetDevice(win)

		// for all sweep numbers the same LBN
		if(ParamIsDefault(sweepNumber) && !selectedExpDevice)
			WAVE/Z sweeps = GetPlainSweepList(win)

			if(!WaveExists(sweeps))
				return $""
			endif

			Make/FREE/WAVE/N=(DimSize(sweeps, ROWS)) waves = GetLogbookWaves(logbookType, logbookWaveType, device = device)
			return waves
		elseif(selectedExpDevice)
			return GetLogbookWaves(logbookType, logbookWaveType, device = device)
		elseif(!ParamIsDefault(sweepNumber))
			ASSERT(IsValidSweepNumber(sweepNumber), "Unsupported sweep number")
			return GetLogbookWaves(logbookType, logbookWaveType, device = device)
		else
			ASSERT(0, "Invalid parameter combination")
		endif
	else
		if(ParamIsDefault(sweepNumber) && !selectedExpDevice)
			return SB_GetLogbookWave(win, logbookType, logbookWaveType)
		elseif(selectedExpDevice)
			shPanel = LBV_GetSettingsHistoryPanel(win)

			dataFolder = GetPopupMenuString(shPanel, "popup_experiment")
			device = GetPopupMenuString(shPanel, "popup_Device")

			if(!cmpstr(dataFolder, NONE) || !cmpstr(device, NONE))
				return $""
			endif

			return SB_GetLogbookWave(win, logbookType, logbookWaveType, dataFolder = dataFolder, device = device)
		elseif(!ParamIsDefault(sweepNumber))
			ASSERT(IsValidSweepNumber(sweepNumber), "Unsupported sweep number")
			return SB_GetLogbookWave(win, logbookType, logbookWaveType, sweepNumber = sweepNumber)
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

	string graph, scPanel, bsPanel
	variable first, last, formerLast, sweepNo, overlaySweeps
	variable index

	switch(ba.eventcode)
		case 2: // mouse up
			graph = GetMainWindow(ba.win)
			scPanel = BSP_GetSweepControlsPanel(graph)
			bsPanel = BSP_GetPanel(graph)

			PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DS", val = CHECKBOX_UNSELECTED)

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

static Function BSP_UnHideSettingsHistory(win)
	string win

	string settingsHistoryPanel

	ASSERT(WindowExists(GetMainWindow(win)), "HOST panel does not exist")

	settingsHistoryPanel = LBV_GetSettingsHistoryPanel(win)
	if(WindowExists(settingsHistoryPanel))
		SetWindow $settingsHistoryPanel, hide=0, needUpdate=1
	endif
End

static Function BSP_RemoveTraces(string graph)
	variable i, numEntries
	string trace

	WAVE/Z/T traces = TUD_GetUserDataAsWave(graph, "traceName", keys = {"traceType"}, values = {"EpochVis"})

	if(!WaveExists(traces))
		return NaN
	endif

	numEntries = DimSize(traces, ROWS)
	for(i = 0; i < numEntries; i += 1)
		trace = traces[i]
		RemoveFromGraph/W=$graph $trace
		TUD_RemoveUserData(graph, trace)
	endfor
End

/// @brief Debug function to add traces with epoch information
Function BSP_AddTracesForEpochs(string win)

	variable i, j, start_x, start_y, end_x, end_y, yOffset
	variable headstage, yLevelOffset, level, idx, numTraces, numEpochs
	variable sweepNumber, traceIndex, channelType, channelNumber
	STRUCT RGBColor c
	string xaxis, yaxis, axes, axis, levels_x_name, levels_y_name, name, idPart, level_x_trace

	if(!BSP_IsDataBrowser(win) && !BSP_IsSweepBrowser(win))
		printf "The current window is neither a databrowser nor a sweepbrowser windows.\r"
		ControlWindowToFront()
		return Nan
	endif

	DFREF dfr = GetEpochsVisualizationFolder(BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER))
	BSP_RemoveTraces(win)

	WAVE/T/Z traceInfosHS = GetTraceInfos(win, addFilterKeys = {"channelType", "AssociatedHeadstage"}, addFilterValues = {"AD", "1"})
	if(!WaveExists(traceInfosHS))
		// fallback to DA traces
		WAVE/T/Z traceInfosHS = GetTraceInfos(win, addFilterKeys = {"channelType", "AssociatedHeadstage"}, addFilterValues = {"DA", "1"})
	endif

	WAVE/T/Z traceInfosUnassocDA = GetTraceInfos(win, addFilterKeys = {"channelType", "AssociatedHeadstage"}, addFilterValues = {"DA", "0"})
	WAVE/T/Z traceInfosTTL = GetTraceInfos(win, addFilterKeys = {"channelType"}, addFilterValues = {"TTL"})

	if(!WaveExists(traceInfosHS) && !WaveExists(traceInfosUnassocDA) && !WaveExists(traceInfosTTL))
		return NaN
	else
		WAVE/T traceInfosFull = GetGraphUserData(win)
		Duplicate/FREE/T traceInfosFull, traceInfos
		Redimension/N=(0, -1) traceInfos
		if(WaveExists(traceInfosHS))
			Concatenate/FREE/T/NP=(ROWS) {traceInfosHS}, traceInfos
		endif
		if(WaveExists(traceInfosUnassocDA))
			Concatenate/FREE/T/NP=(ROWS) {traceInfosUnassocDA}, traceInfos
		endif
		if(WaveExists(traceInfosTTL))
			Concatenate/FREE/T/NP=(ROWS) {traceInfosTTL}, traceInfos
		endif
	endif

	traceIndex = GetNextTraceIndex(win)

	numTraces = DimSize(traceInfos, ROWS)
	for(i = 0; i < numTraces; i += 1)
		yaxis = traceInfos[i][%YAXIS]
		xaxis = traceInfos[i][%XAXIS]

		// use our own y axis
		// need to replace for both AD and DA cases
		yaxis = ReplaceString("_DA", yaxis, DB_AXIS_PART_EPOCHS + "_DA")
		yaxis = ReplaceString("_AD", yaxis, DB_AXIS_PART_EPOCHS + "_DA")
		yaxis = ReplaceString("_TTL", yaxis, DB_AXIS_PART_EPOCHS + "_TTL")

		headstage   = str2num(traceInfos[i][%headstage])
		sweepNumber = str2num(traceInfos[i][%sweepNumber])
		channelType = WhichListItem(traceInfos[i][%channelType], XOP_CHANNEL_NAMES)
		channelNumber = str2num(traceInfos[i][%GUIChannelNumber])

		WAVE/Z/T numericalValues = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweepNumber)
		ASSERT(WaveExists(numericalValues), "Numerical LabNotebook not found.")
		WAVE/Z/T textualValues = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = sweepNumber)
		ASSERT(WaveExists(textualValues), "Textual LabNotebook not found.")

		// present since a2172f03 (Added generations of epoch information wave, 2019-05-22)
		WAVE/T/Z epochsFromLBN = EP_FetchEpochs(numericalValues, textualValues, sweepNumber, channelNumber, channelType)
		if(!WaveExists(epochsFromLBN))
			continue
		endif

		sprintf idPart, "_sweep%d_chan%d_type%d_HS%.0g", sweepNumber, channelNumber, channelType, headstage
		sprintf name, "epochs_%s", idPart
		Duplicate/O/T epochsFromLBN, dfr:$name/Wave=epochs

		yLevelOffset = 10
		yOffset = - yLevelOffset

		numEpochs = DimSize(epochs, ROWS)

		Make/FREE/D/N=(BSP_EPOCH_LEVELS) currentLevel, indexInLevel

		sprintf levels_x_name, "levels_x_%s", idpart
		Make/O/D/N=(numEpochs * 3, 5, 2) dfr:$levels_x_name/WAVE=levels_x
		levels_x = NaN

		sprintf levels_y_name, "levels_y_%s", idPart
		Make/O/D/N=(numEpochs * 3, 5, 2) dfr:$levels_y_name/WAVE=levels_y
		levels_y = NaN
		SetStringInWaveNote(levels_y, "EpochInfo", GetWavesDataFolder(epochs, 2))

		for(j = 0; j < numEpochs; j += 1)

			start_x = str2num(epochs[j][0]) * ONE_TO_MILLI
			end_x   = str2num(epochs[j][1]) * ONE_TO_MILLI

			// handle EPOCH_USER_LEVEL being -1
			level = str2num(epochs[j][3]) + 1

			start_y = yOffset - yLevelOffset * level  - 0.1 * yLevelOffset * currentLevel[level]
			end_y = start_y

			idx = indexInLevel[level]
			levels_x[idx][level][0] = start_x
			levels_x[idx + 1][level][0] = end_x
			levels_x[idx + 2][level][0] = NaN
			levels_x[idx, idx + 2][level][1] = j

			levels_y[idx][level][0] = start_y
			levels_y[idx + 1][level][0] = end_y
			levels_y[idx + 2][level][0] = NaN
			levels_y[idx, idx + 2][level][1] = j

			indexInLevel[level] = idx + 3

			currentLevel[level] += 1
		endfor

		for(j = 0; j < BSP_EPOCH_LEVELS; j += 1)
			sprintf level_x_trace, "%s_level%d_x_%s", GetTraceNamePrefix(traceIndex++), j, idPart

			AppendToGraph/W=$win/L=$yAxis levels_y[][j]/TN=$level_x_trace vs levels_x[][j]
			TUD_SetUserDataFromWaves(win, level_x_trace, {"traceType", "occurence", "XAXIS", "YAXIS"}, {"EpochVis", "", "bottom", yaxis})

			[c] = GetTraceColor(j)
			ModifyGraph/W=$win marker($level_x_trace)=10, mode($level_x_trace)=4, rgb($level_x_trace)=(c.red, c.green, c.blue)
		endfor

		SetWindow $win, tooltipHook(hook) = BSP_EpochGraphToolTip

		SetAxis/W=$win/A
	endfor
End

Function BSP_EpochGraphToolTip(s)
	STRUCT WMTooltipHookStruct &s

	variable idx, hasShortname
	string first, last, tags, treelevel, shortname
	Variable hookResult = 0 // 0 tells Igor to use the standard tooltip

	// traceName is set only for graphs and only if the mouse hovered near a trace
	if(!IsEmpty(s.traceName))
		s.tooltip = "a <-> b"
		s.isHtml = 1
		WAVE w = s.yWave // The trace's Y wave
		if (WaveDims(w) > 2)
			WAVE/T/Z epochs = $GetStringFromWaveNote(w, "EpochInfo")
			ASSERT(WaveExists(epochs), "Missing epoch info")
			hookResult = 1 // 1 tells Igor to use our custom tooltip
			idx = w[s.row][s.column][1]

			first     = num2strHighPrec(str2num(epochs[idx][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI, precision = EPOCHTIME_PRECISION, shorten = 1)
			last      = num2strHighPrec(str2num(epochs[idx][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI, precision = EPOCHTIME_PRECISION, shorten = 1)
			tags      = epochs[idx][EPOCH_COL_TAGS]
			treelevel = epochs[idx][EPOCH_COL_TREELEVEL]

			shortname = EP_GetShortName(tags)
			hasShortname = IsEmpty(shortname)

			if(hasShortname)
				tags = EP_RemoveShortNameFromTags(tags)
			endif

			sprintf s.tooltip, "%s<br>%s &lt;-&gt; %s (ms)<br>Tags: %s<br>TreeLevel: %s", SelectString(hasShortname, "<b>" + shortname + "</b>", "Shortname: NA"), first, last, tags, treelevel
		endif
	endif

	return hookResult
End

Function BSP_SFHelpWindowHook(s)
	STRUCT WMWinHookStruct &s

	string mainWin, sfWin, bspPanel, cmdStr
	variable modMask,refContentCRC, contentCRC

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_MOUSEDOWN:
			mainWin = GetMainWindow(s.winName)
			sfWin = BSP_GetSFFormula(mainWin)
			if(CmpStr(sfWin, s.winName))
				return 0
			endif

			modMask = WINDOW_HOOK_EMOD_SHIFTKEYDOWN | WINDOW_HOOK_EMOD_RIGHTCLICK
			if((s.eventMod & modMask) != modMask)
				return 0
			endif
			cmdStr = LowerStr(GetNotebookText(sfWin, mode=4))

			WAVE/T knownOps = SF_GetNamedOperations()
			if(GetRowIndex(knownOps, str = cmdStr) >= 0)
				DB_SFHelpJumpToLine(BSP_GetHelpOperationHeadline(cmdStr))
				bspPanel = BSP_GetPanel(mainWin)
				PGC_SetAndActivateControl(bspPanel, "SF_InfoTab", val=2, mode=PGC_MODE_SKIP_ON_DISABLED)
				return 1
			endif

			WAVE/T knownKeywords = SF_GetFormulaKeywords()
			if(GetRowIndex(knownKeywords, str = cmdStr) >= 0)
				DB_SFHelpJumpToLine(BSP_GetHelpKeywordHeadline(cmdStr))
				bspPanel = BSP_GetPanel(mainWin)
				PGC_SetAndActivateControl(bspPanel, "SF_InfoTab", val=2, mode=PGC_MODE_SKIP_ON_DISABLED)
				return 1
			endif
			break
		case EVENT_WINDOW_HOOK_DEACTIVATE:
			mainWin = GetMainWindow(s.winName)
			sfWin = BSP_GetSFFormula(mainWin)
			refContentCRC = str2num(GetUserData(mainWin, "", BSP_USER_DATA_SF_CONTENT_CRC))
			contentCRC = GetNotebookCRC(sfWin)
			if(!CmpStr(sfWin, s.winName) && refContentCRC != contentCRC)
				BSP_SFFormulaColoring(sfWin)
				SetWindow $mainWin, userData($BSP_USER_DATA_SF_CONTENT_CRC)=num2istr(contentCRC)
			endif
			break
	endswitch

	// return zero so that other hooks are called as well
	return 0
End

static Function/S BSP_GetHelpOperationHeadline(string op)

	return "operation - " + op
End

static Function/S BSP_GetHelpKeywordHeadline(string keyWord)

	return "the " + keyWord + " keyword"
End

static Function BSP_SFFormulaColoring(string sfWin)

	Notebook $sfWin, selection={startOfFile, endOfFile}
	Notebook $sfWin, textRGB=(0, 0, 0)

	WAVE/T knownOps = SF_GetNamedOperations()
	for(s : knownOps)
		ColorNotebookKeywords(sfWin, s, 0xc300, 0x4e00, 0)
	endfor
	WAVE/T knownKeywords = SF_GetFormulaKeywords()
	for(s : knownKeywords)
		ColorNotebookKeywords(sfWin, s, 0, 0x4b00, 0x4b00)
	endfor

	Notebook $sfWin, selection={startOfFile, startOfFile}
	Notebook $sfWin, findText={"", 0}
End

Function BSP_TTHookSFFormulaNB(STRUCT WMTooltipHookStruct &s)

	string targetCtrl = "SF_InfoTab"
	string mainWin, sfWin, sfHelpWin, cmdStr, headLine

	if(CmpStr(targetCtrl, s.ctrlName))
		return 0
	endif
	if(GetTabID(s.winName, targetCtrl) != 0)
		return 0
	endif

	s.duration_ms = Inf
	mainWin = GetMainWindow(s.winName)
	sfWin = BSP_GetSFFormula(mainWin)
	Notebook $sfWin, getData=4
	if(isEmpty(S_Value))
		s.tooltip = "Mark operation or keyword for help tooltip or\r shift-rightclick on marked operation or keyword to jump to help."
		return 1
	endif
	cmdStr = LowerStr(S_Value)
	WAVE/T knownOps = SF_GetNamedOperations()
	WAVE/T knownKeywords = SF_GetFormulaKeywords()
	sfHelpWin = BSP_GetSFHELP(mainWin)
	if(GetRowIndex(knownOps, str = cmdStr) >= 0)
		headLine = BSP_GetHelpOperationHeadline(cmdStr)
		s.tooltip = BSP_RetrieveSFHelpTextImpl(sfHelpWin, headLine, "to_top_" + cmdStr)
		if(IsEmpty(s.tooltip))
			s.tooltip = "Help for operation " + cmdStr + " not found."
			BUG(s.tooltip)
			return 1
		endif
		DB_SFHelpJumpToLine(headLine)
	elseif(GetRowIndex(knownKeywords, str = cmdStr) >= 0)
		headLine = BSP_GetHelpKeywordHeadline(cmdStr)
		s.tooltip = BSP_RetrieveSFHelpTextImpl(sfHelpWin, headLine, "to_top_" + cmdStr)
		if(IsEmpty(s.tooltip))
			s.tooltip = "Help for keyword " + cmdStr + " not found."
			BUG(s.tooltip)
			return 1
		endif

		DB_SFHelpJumpToLine(headLine)
	else
		s.tooltip = "\"" + cmdStr + "\" is no known operation or keyword."
	endif

	return 1
End

static Function/S BSP_RetrieveSFHelpTextImpl(string win, string hlpStart, string hlpEnd)

	variable paraStart, paraStartOff, paraEnd

	if(DB_SFHelpJumpToLine(hlpStart))
		return ""
	endif
	GetSelection notebook, $win, 1
	paraStart = V_endParagraph
	paraStartOff = V_endPos

	Notebook $win, findSpecialCharacter={hlpEnd, 1}
	if(!V_flag)
		return ""
	endif
	GetSelection notebook, $win, 1
	paraEnd = V_startParagraph
	Notebook $win, selection={(paraStart, paraStartOff), (paraEnd, 0)}
	Notebook $win, getData=4

	return Trimstring(S_value)
End

Function BSP_WindowHook(s)
	STRUCT WMWinHookStruct &s

	string win

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_KILL:

			win = s.winName

			NVAR JSONid = $GetSettingsJSONid()
			PS_StoreWindowCoordinate(JSONid, win)

			if(BSP_IsSweepBrowser(win))
				BSP_MemoryFreeMappedDF(win)
			endif

			if(!BSP_HasBoundDevice(win))
				break
			endif

			AssertOnAndClearRTError()
			try
				// catch all error conditions, asserts and aborts
				// and silently ignore them
				DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER, versionCheck = 0); AbortOnRTE

				KillOrMoveToTrash(dfr = dfr); AbortOnRTE
			catch
				ClearRTError()
			endtry

			break
	endswitch

	// return zero so that other hooks are called as well
	return 0
End

/// @brief Renames the browser window and sets an informative title
///
/// @param win     name of the existing window
/// @param newName suggested new name, will be adapted to be unique
Function/S BSP_RenameAndSetTitle(string win, string newName)

	variable numOtherBrowser
	string newTitle
	string suffix = ""

	if(BSP_IsDataBrowser(win) && BSP_HasBoundDevice(win))
		suffix = " with \"" + BSP_GetDevice(win) + "\""
	endif

	if(WindowExists(newName) && cmpstr(win, newName))
		newName = UniqueName(newName, 9, 1)
	endif

	DoWindow/W=$win/C $newName
	win = newName

	numOtherBrowser += ItemsInList(WinList(SWEEPBROWSER_WINDOW_NAME + "*", ";", "WIN:1"))
	numOtherBrowser += ItemsInList(WinList(DATABROWSER_WINDOW_NAME + "*", ";", "WIN:1"))
	numOtherBrowser += ItemsInList(WinList("DB_*", ";", "WIN:1"))
	numOtherBrowser  = max(0, numOtherBrowser - 1)

	sprintf newTitle, "Browser %s%s", SelectString(numOtherBrowser, "", " [" + num2str(numOtherBrowser) + "]"), suffix
	newTitle = RemoveEnding(newTitle, " ")
	DoWindow/T $win, newTitle

	return win
End

static Function BSP_MemoryFreeMappedDF(string win)

	variable dim, index

	DFREF sweepBrowserDFR = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)
	WAVE/T map = GetSweepBrowserMap(sweepBrowserDFR)
	dim = FindDimLabel(map, COLS, "DataFolder")
	Duplicate/FREE/RMD=[][dim] map, dfList
	index = GetNumberFromWaveNote(map, NOTE_INDEX)

	AB_FreeWorkingDFs(dfList, index)
End
