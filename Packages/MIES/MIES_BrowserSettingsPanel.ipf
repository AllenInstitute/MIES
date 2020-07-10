#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

/// @file MIES_BrowserSettingsPanel.ipf
/// @brief __BSP__ Panel for __DB__ and __AB__ (SweepBrowser) that combines different settings in a tabcontrol.

static strConstant EXT_PANEL_SUBWINDOW = "BrowserSettingsPanel"
static strConstant EXT_PANEL_SWEEPCONTROL = "SweepControl"
static strConstant EXT_PANEL_SF_FORMULA = "sweepFormula_formula"
static strConstant EXT_PANEL_SF_JSON = "sweepFormula_json"
static strConstant EXT_PANEL_SF_HELP = "sweepFormula_help"

static Constant BROWSERSETTINGS_PANEL_VERSION = 6

static strConstant BROWSERTYPE_DATABROWSER  = "D"
static strConstant BROWSERTYPE_SWEEPBROWSER = "S"

/// @brief List of controls that have specific control procedures set
static StrConstant BROWSERSETTING_UNSET_CONTROLPROCEDURES = "check_BrowserSettings_DAC;check_BrowserSettings_ADC;check_BrowserSettings_TTL;check_BrowserSettings_splitTTL;check_BrowserSettings_OChan;check_BrowserSettings_dDAQ;check_Calculation_AverageTraces;check_Calculation_ZeroTraces;button_Calculation_RestoreData;check_SweepControl_HideSweep;slider_BrowserSettings_dDAQ;button_TimeAlignment_Action;"

/// @brief exclusive controls that are enabled/disabled for the specific browser window type
static StrConstant BROWSERSETTINGS_CONTROLS_DATABROWSER = "popup_DB_lockedDevices;"
static StrConstant BROWSERSETTINGS_AXES_SCALING_CHECKBOXES = "check_Display_VisibleXrange;check_Display_EqualYrange;check_Display_EqualYignore"

/// @brief List of controls that have specific control procedures set
static StrConstant SWEEPCONTROL_UNSET_CONTROLPROCEDURES = "button_SweepControl_PrevSweep;button_SweepControl_NextSweep;setvar_SweepControl_SweepNo;"

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

	BSP_DynamicSweepControls(mainPanel)
	BSP_DynamicStartupSettings(mainPanel)
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

	mainPanel = GetMainWindow(mainPanel)
	ASSERT(windowExists(mainPanel), "HOST panel does not exist")

	if(BSP_MainPanelNeedsUpdate(mainPanel))
		Abort "Can not display data. The main panel is too old to be usable. Please close it and open a new one."
	endif

	bsPanel = BSP_GetPanel(mainPanel)
	if(BSP_PanelNeedsUpdate(mainPanel))
		Abort "The Browser Settings panel is too old to be usable. Please close main panel and open a new one."
	endif

	ASSERT(windowExists(bsPanel),"BrowserSettings panel does not exist")
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

	SetControlProcedures(scPanel, "button_SweepControl_PrevSweep;button_SweepControl_NextSweep", BSP_AddBrowserPrefix(mainPanel, "ButtonProc_ChangeSweep"))

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
	SetControlProcedures(scPanel, SWEEPCONTROL_UNSET_CONTROLPROCEDURES, "")
End

/// @brief dynamic settings for panel initialization
///
/// @param mainPanel 	mainWindow panel name
Function BSP_DynamicStartupSettings(mainPanel)
	string mainPanel

	variable sweepNo
	string bsPanel, controls

	bsPanel = BSP_GetPanel(mainPanel)

	SetWindow $bsPanel, hook(main)=BSP_ClosePanelHook
	AddVersionToPanel(bsPanel, BROWSERSETTINGS_PANEL_VERSION)

	SetControlProcedure(bsPanel, "check_BrowserSettings_OVS", BSP_AddBrowserPrefix(mainPanel, "CheckProc_OverlaySweeps"))
	PopupMenu popup_overlaySweeps_select, win=$bsPanel, value= #("OVS_GetSweepSelectionChoices(\"" + bsPanel + "\")")

	BSP_SetCSButtonProc(bsPanel, BSP_AddBrowserPrefix(mainPanel, "CheckProc_ChangedSetting"))

	if(!BSP_IsDataBrowser(mainPanel) || BSP_HasBoundDevice(mainPanel))
		BSP_BindListBoxWaves(mainPanel)
	endif

	// settings tab
	controls = "check_BrowserSettings_DAC;check_BrowserSettings_ADC;check_BrowserSettings_TTL;check_BrowserSettings_splitTTL;check_BrowserSettings_OChan;check_BrowserSettings_dDAQ;check_Calculation_AverageTraces;check_Calculation_ZeroTraces;"
	SetControlProcedures(bsPanel, controls, BSP_AddBrowserPrefix(mainPanel, "CheckProc_ChangedSetting"))
	SetControlProcedure(bsPanel, "button_Calculation_RestoreData", BSP_AddBrowserPrefix(mainPanel, "ButtonProc_RestoreData"))
	SetControlProcedures(bsPanel, "check_SweepControl_HideSweep;", BSP_AddBrowserPrefix(mainPanel, "CheckProc_ChangedSetting"))
	SetControlProcedures(bsPanel, "slider_BrowserSettings_dDAQ;", "BSP_SliderProc_ChangedSetting")
	SetControlProcedures(bsPanel, "button_TimeAlignment_Action", BSP_AddBrowserPrefix(mainPanel, "DoTimeAlignment"))

	if(BSP_IsDataBrowser(mainPanel))
		EnableControls(bsPanel, BROWSERSETTINGS_CONTROLS_DATABROWSER)
	else
		DisableControls(bsPanel, BROWSERSETTINGS_CONTROLS_DATABROWSER)
		DisableControls(bsPanel, "list_dashboard;check_BrowserSettings_DB_Failed;check_BrowserSettings_DB_Passed")
	endif
	PopupMenu popup_TimeAlignment_Master win=$bsPanel, value = #("TimeAlignGetAllTraces(\"" + mainPanel + "\")")

	BSP_InitMainCheckboxes(bsPanel)

	PGC_SetAndActivateControl(bsPanel, "SF_InfoTab", val = 0)
	PGC_SetAndActivateControl(bsPanel, "Settings", val = 0)

	BSP_UpdateHelpNotebook(mainPanel)

	SetWindow $bsPanel, hook(sweepFormula)=BSP_SweepFormulaHook
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

	string bsPanel

	ASSERT(BSP_IsDataBrowser(mainPanel), "Browser window is not of type DataBrowser")
	bsPanel = BSP_GetPanel(mainPanel)
	ASSERT(WindowExists(bsPanel), "external BrowserSettings panel not found")
	SetWindow $bsPanel, hook(main)=$""
	SetWindow $bsPanel, userData(panelVersion) = ""
	PopupMenu popup_overlaySweeps_select, win=$bsPanel, value=""
	SetControlProcedures(bsPanel, BROWSERSETTING_UNSET_CONTROLPROCEDURES, "")
	PopupMenu popup_TimeAlignment_Master win=$bsPanel, value = ""
	ListBox list_of_ranges, win=$bsPanel, listWave=$"", selWave=$""
	ListBox list_of_ranges1, win=$bsPanel, listWave=$"", selWave=$""
	ListBox list_dashboard, win=$bsPanel, listWave=$"", colorWave=$"", selWave=$""
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
	WAVE listBoxColorWave = GetAnaFuncDashboardColorWave(dfr)
	WAVE listBoxSelWave   = GetAnaFuncDashboardselWave(dfr)
	WAVE/T listBoxWave    = GetAnaFuncDashboardListWave(dfr)
	ListBox list_dashboard, win=$bsPanel, listWave=listBoxWave, colorWave=listBoxColorWave, selWave=listBoxSelWave

	// sweep formula tab
	SetValDisplay(bsPanel, "status_sweepFormula_parser", var=1)
	SetSetVariableString(bsPanel, "setvar_sweepFormula_parseResult", "")
End

/// @brief add SB_* or DB_* prefix to the input string depending on current window
Function/S BSP_AddBrowserPrefix(win, str)
	string win, str

	if(BSP_IsDataBrowser(win))
		return "DB_" + str
	else
		return "SB_" + str
	endif
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

	if(BSP_MainPanelNeedsUpdate(win))
		DoAbortNow("The main panel is too old to be usable. Please close it and open a new one.")
	endif

	mainPanel = GetMainWindow(win)
	ASSERT(WindowExists(mainPanel), "specified panel does not exist.")

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
	GetITCDevicesFolder()

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
static Function/S BSP_GetBrowserType(win)
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
static Function/S BSP_SetBrowserType(win, type)
	string win, type

	string mainPanel, settingsHistoryPanel

	mainPanel = GetMainWindow(win)
	ASSERT(WindowExists(mainPanel), "specified panel does not exist.")

	SetWindow $mainPanel, userdata($MIES_BSP_BROWSER) = type
	if(!CmpStr(type, BROWSERTYPE_SWEEPBROWSER))
		DoWindow/T $mainPanel, SWEEPBROWSER_WINDOW_TITLE
		settingsHistoryPanel = DB_GetSettingsHistoryPanel(mainPanel)
		if(WindowExists(settingsHistoryPanel))
			KillWindows(settingsHistoryPanel)
		endif
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

	return !(IsEmpty(device) || !cmpstr(device, NONE))
End

/// @brief get the selected headstage from the slider position
///
/// if the slider is at position -1, all headstages are selected
/// this equals to dDAQ checkbox beeing deactivated
///
/// @param win 	name of external panel or main window
/// @returns the headstage number if active and -1 if the headstage slider was not found or is deactivated
Function BSP_GetDDAQ(win)
	string win

	string bsPanel, ctrl

	ctrl = "slider_BrowserSettings_dDAQ"
	bsPanel = BSP_GetPanel(win)

	if(!ControlExists(bsPanel, ctrl))
		return -1
	endif

	if(!BSP_DDAQisActive(win))
		return -1
	endif

	return GetSliderPositionIndex(bsPanel, ctrl)
End

/// @brief get the status of the dDAQ control
///
/// @param win 	name of external panel or main window
/// @returns the status of the checkbox control "dDAQ" in the BrowserSettings Panel
static Function BSP_DDAQisActive(win)
	string win

	string bsPanel, ctrl

	ctrl = "check_BrowserSettings_dDAQ"
	bsPanel = BSP_GetPanel(win)

	if(!ControlExists(bsPanel, ctrl))
		return 0
	endif

	return GetCheckboxState(bsPanel, ctrl)
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
	BSP_SetPAControlStatus(bsPanel)

	return 1
End

/// @brief overwrite the control action of all Channel Selection Buttons
static Function BSP_SetCSButtonProc(win, procedure)
	string win, procedure

	string bsPanel
	variable i
	string controlList = ""

	bsPanel = BSP_GetPanel(win)

	for(i = 0; i < 8; i += 1)
		controlList += "check_channelSel_HEADSTAGE_" + num2str(i) + ";"
		controlList += "check_channelSel_DA_" + num2str(i) + ";"
	endfor
	for(i = 0; i < 16; i += 1)
		controlList += "check_channelSel_AD_" + num2str(i) + ";"
	endfor

	controlList += "check_channelSel_AD_All;check_channelSel_DA_All;check_channelSel_HEADSTAGE_All"

	SetControlProcedures(bsPanel, controlList, procedure)
	if(IsEmpty(procedure))
		DisableControls(bsPanel, controlList)
	endif
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

/// @brief enable/disable the PA buttons
///
/// @param win 	specify mainPanel or bsPanel with OVS controls
Function BSP_SetPAControlStatus(win)
	string win

	string controlList

	controlList = "group_properties_pulse;check_pulseAver_indTraces;check_pulseAver_showAver;check_pulseAver_zeroTrac;check_pulseAver_multGraphs;check_pulseAver_deconv;check_pulseAver_timeAlign;setvar_pulseAver_startPulse;setvar_pulseAver_endPulse;setvar_pulseAver_fallbackLength;"
	BSP_SetControlStatus(win, controlList, PA_IsActive(win))
	BSP_SetIndividualControlStatus(win)
	BSP_SetDeconvControlStatus(win)

	BSP_SetDeconvControlStatus(win)
End

/// @brief enable/disable the SF buttons
///
/// @param win 	specify mainPanel or bsPanel with OVS controls
Function BSP_SetSFControlStatus(win)
	string win

	string controlList

	controlList = "group_properties_sweepFormula;SF_InfoTab;button_sweepFormula_display;button_sweepFormula_check;setvar_sweepFormula_parseResult;status_sweepFormula_parser;"
	BSP_SetControlStatus(win, controlList, SF_IsActive(win))
	BSP_SetIndividualControlStatus(win)
End

/// @brief enable/disable the buttons that rely on displayed traces
///
/// @param win 	specify mainPanel or bsPanel with OVS controls
Function BSP_SetIndividualControlStatus(win)
	string win

	BSP_SetControlStatus(win, "check_pulseAver_timeAlign", PA_IndividualIsActive(win))
End

/// @brief enable/disable deconvolution buttons depending on the status of @c check_pulseAver_showAver
///
/// @param win 	specify mainPanel or bsPanel with OVS controls
Function BSP_SetDeconvControlStatus(win)
	string win

	string controlList

	controlList = "group_pulseAver_deconv;check_pulseAver_deconv;"
	BSP_SetControlStatus(win, controlList, PA_AverageIsActive(win))

	controlList = "setvar_pulseAver_deconv_tau;setvar_pulseAver_deconv_smth;setvar_pulseAver_deconv_range;"
	BSP_SetControlStatus(win, controlList, PA_DeconvolutionIsActive(win))
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

	string mainPanel, panelButton
	string panels = ""
	variable hookResult = 0

	switch(s.eventCode)
		case 17: // killVote
			mainPanel = GetMainWindow(s.winName)
			panels = AddListItem(BSP_GetPanel(mainPanel), panels)
			panels = AddListItem(BSP_GetSweepControlsPanel(mainPanel), panels)

			ASSERT(FindListItem(s.winName, panels) >= 0, "this hook is only available for specific BSP panel.")

			SetWindow $s.winName hide=1

			BSP_MainPanelButtonToggle(mainPanel, 1)

			hookResult = 2 // don't kill window
			break
	endswitch

	return hookResult
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
			BSP_SetPAControlStatus(mainPanel)
			UpdateSweepPlot(mainPanel)
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
			UpdateSweepPlot(mainPanel)
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

/// @see SB_DoTimeAlignment DB_DoTimeAlignment
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

Function BSP_CheckProc_ScaleAxes(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	string ctrls, graph, bsPanel
	variable numCtrls, i

	graph   = GetMainWindow(cba.win)
	bsPanel = BSP_GetPanel(graph)

	switch( cba.eventCode )
		case 2: // mouse up
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

	graph   = GetMainWindow(sva.win)
	bsPanel = BSP_GetPanel(graph)

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			if(GetCheckBoxState(bsPanel, "check_Display_EqualYignore"))
				BSP_ScaleAxes(graph)
			endif
			break
	endswitch

	return 0
End

/// @brief update controls in scPanel and change to new sweep
///
/// @param win 		  name of external panel or main window
/// @param ctrl       name of the button that was pressed and is initiating the update
/// @param firstSweep first available sweep(DB) or index(SB)
/// @param lastSweep  last available sweep(DB) or index(SB)
/// @returns the new sweep number in case of DB or the index for SB
Function BSP_UpdateSweepControls(win, ctrl, firstSweep, lastSweep)
	string win, ctrl
	variable firstSweep, lastSweep

	string graph, scPanel
	variable currentSweep, newSweep, step, direction

	graph   = GetMainWindow(win)
	scPanel = BSP_GetSweepControlsPanel(graph)

	if(BSP_MainPanelNeedsUpdate(graph))
		DoAbortNow("The main panel is too old to be usable. Please close it and open a new one.")
	endif

	currentSweep = GetSetVariable(scPanel, "setvar_SweepControl_SweepNo")
	step = GetSetVariable(scPanel, "setvar_SweepControl_SweepStep")
	if(!cmpstr(ctrl, "button_SweepControl_PrevSweep"))
		direction = -1
	elseif(!cmpstr(ctrl, "button_SweepControl_NextSweep"))
		direction = +1
	else
		ASSERT(0, "unhandled control name")
	endif

	newSweep = currentSweep + direction * step
	newSweep = limit(newSweep, firstSweep, lastSweep)

	SetSetVariable(scPanel, "setvar_SweepControl_SweepNo", newSweep)
	SetSetVariableLimits(scPanel, "setvar_SweepControl_SweepNo", firstSweep, lastSweep, step)
	SetValDisplay(scPanel, "valdisp_SweepControl_LastSweep", var = lastSweep)

	return newSweep
End

/// @brief check the DataBrowser or SweepBrowser panel if it has the required version
///
/// @param win 		name of external panel or main window
/// @return 0 if panel has latest version and 1 if update is required
Function BSP_MainPanelNeedsUpdate(win)
	string win

	variable panelVersion, version
	string mainPanel

	mainPanel = GetMainWindow(win)
	panelVersion = GetPanelVersion(mainPanel)
	if(BSP_IsDataBrowser(mainPanel))
		version = DATABROWSER_PANEL_VERSION
	else
		version = SWEEPBROWSER_PANEL_VERSION
	endif

	return panelVersion < version
End

/// @brief check the BrowserSettings Panel if it has the required version
///
/// @param win 	name of external panel or main window
/// @return 0 if panel has latest version and 1 if update is required
static Function BSP_PanelNeedsUpdate(win)
	string win

	string bsPanel
	variable version

	bsPanel = BSP_GetPanel(win)
	if(!WindowExists(bsPanel))
		return 0
	endif

	version = GetPanelVersion(bsPanel)
	return version < BROWSERSETTINGS_PANEL_VERSION
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
	if(!WindowExists(bsPanel))
		return 0
	endif

	// return inactive if panel is outdated
	if(BSP_MainPanelNeedsUpdate(win) || BSP_PanelNeedsUpdate(win))
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
		channelNum = str2num(channelNumStr); AbortOnRTE
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

/// @brief Removes the disabled channels and headstages from `ADCs` and `DACs`
Function BSP_RemoveDisabledChannels(channelSel, ADCs, DACs, numericalValues, sweepNo)
	WAVE/Z channelSel
	WAVE ADCs, DACs, numericalValues
	variable sweepNo

	variable numADCs, numDACs, i

	if(!WaveExists(channelSel) || (WaveMin(channelSel) == 1 && WaveMax(channelSel) == 1))
		return NaN
	endif

	Duplicate/FREE channelSel, channelSelMod

	numADCs = DimSize(ADCs, ROWS)
	numDACs = DimSize(DACs, ROWS)

	WAVE/Z statusDAC = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z statusADC = GetLastSetting(numericalValues, sweepNo, "ADC", DATA_ACQUISITION_MODE)
	WAVE/Z statusHS  = GetLastSetting(numericalValues, sweepNo, "Headstage Active", DATA_ACQUISITION_MODE)

	// disable the AD/DA channels not wanted by the headstage setting first
	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(!channelSelMod[i][%HEADSTAGE] && statusHS[i])
			channelSelMod[statusADC[i]][%AD] = 0
			channelSelMod[statusDAC[i]][%DA] = 0
		endif
	endfor

	// start at the end of the config wave
	// we always have the order DA/AD/TTLs
	for(i = numADCs - 1; i >= 0; i -= 1)
		if(!channelSelMod[ADCs[i]][%AD])
			DeletePoints/M=(ROWS) i, 1, ADCs
		endif
	endfor

	for(i = numDACs - 1; i >= 0; i -= 1)
		if(!channelSelMod[DACs[i]][%DA])
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
	equalY     = GetCheckBoxState(bsPanel, "check_Display_EqualYrange")
	equalYIgn  = GetCheckBoxState(bsPanel, "check_Display_EqualYignore")

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
