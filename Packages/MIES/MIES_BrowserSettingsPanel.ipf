#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

/// @file MIES_BrowserSettingsPanel.ipf
/// @brief __BSP__ Panel for __DB__ and __AB__ (SweepBrowser) that combines different settings in a tabcontrol.

static strConstant EXT_PANEL_SUBWINDOW = "BrowserSettingsPanel"
static strConstant EXT_PANEL_SWEEPCONTROL = "SweepControl"

static Constant BROWSERSETTINGS_PANEL_VERSION = 2

static strConstant BROWSERTYPE_DATABROWSER  = "D"
static strConstant BROWSERTYPE_SWEEPBROWSER = "S"

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

/// @brief open BrowserSettings side Panel
///
/// @param mainPanel 	mainWindow panel name
Function BSP_OpenPanel(mainPanel)
	string mainPanel

	BSP_OpenSweepControls(mainPanel)
	BSP_OpenSettingsPanel(mainPanel)

	BSP_MainPanelButtonToggle(mainPanel, 0)
End

Function BSP_OpenSettingsPanel(mainPanel)
	string mainPanel

	string bsPanel

	mainPanel = GetMainWindow(mainPanel)
	if(BSP_MainPanelNeedsUpdate(mainPanel))
		Abort "Can not display data. The main panel is too old to be usable. Please close it and open a new one."
	endif

	bsPanel = BSP_GetPanel(mainPanel)
	if(BSP_PanelNeedsUpdate(mainPanel))
		KillWindow/Z $bsPanel
	endif

	if(windowExists(bsPanel))
		SetWindow $bsPanel hide=0, needUpdate=1
		return 1
	endif

	ASSERT(windowExists(mainPanel), "HOST panel does not exist")
	NewPanel/HOST=$mainPanel/EXT=1/W=(366,0,0,407)/N=$EXT_PANEL_SUBWINDOW  as " "
	Execute "BrowserSettingsPanel()"
	BSP_DynamicStartupSettings(mainPanel)
End

/// @brief open bottom Panel
///
/// @param mainPanel 	mainWindow panel name
Function BSP_OpenSweepControls(mainPanel)
	string mainPanel

	string scPanel

	mainPanel = GetMainWindow(mainPanel)
	ASSERT(WindowExists(mainPanel), "HOST panel does not exist")

	scPanel = BSP_GetSweepControlsPanel(mainPanel)
	if(WindowExists(scPanel))
		SetWindow $scPanel hide=0, needUpdate=1
		return 1
	endif

	NewPanel/HOST=$mainPanel/EXT=2/W=(0,0,580,66)/N=$EXT_PANEL_SWEEPCONTROL as "Sweep Control"
	Execute "SweepControlPanel()"
	BSP_DynamicSweepControls(mainPanel)
End

/// @brief dynamic settings for bottom panel at initialization
///
/// @param mainPanel 	mainWindow panel name
static Function BSP_DynamicSweepControls(mainPanel)
	string mainPanel

	string scPanel, controlsDB, controlsSB

	scPanel = BSP_GetSweepControlsPanel(mainPanel)
	ASSERT(WindowExists(scPanel), "external SweepControl Panel not found")

	SetWindow $scPanel, hook(main)=BSP_ClosePanelHook

	SetControlProcedures(scPanel, "button_SweepControl_PrevSweep;button_SweepControl_NextSweep", BSP_AddBrowserPrefix(mainPanel, "ButtonProc_ChangeSweep"))

	SetSetVariable(scPanel, "setvar_SweepControl_SweepNo", 0)
	SetSetVariableLimits(scPanel, "setvar_SweepControl_SweepNo", 0, 0, 1)
	SetValDisplay(scPanel, "valdisp_SweepControl_LastSweep", var=0)
	SetSetVariable(scPanel, "setvar_SweepControl_SweepStep", 1)

	controlsDB = "check_SweepControl_AutoUpdate;setvar_SweepControl_SweepNo;"
	controlsSB = "popup_SweepControl_Selector;"
	if(BSP_IsDataBrowser(mainPanel))
		SetControlProcedures(scPanel, "setvar_SweepControl_SweepNo;", "DB_SetVarProc_SweepNo")
		EnableControls(scPanel, controlsDB)
		DisableControls(scPanel, controlsSB)
	else
		PopupMenu popup_SweepControl_Selector win=$scPanel, value= #("SB_GetSweepList(\"" + mainPanel + "\")")
		SetControlProcedures(scPanel, "popup_SweepControl_Selector;", "SB_PopupMenuSelectSweep")
		EnableControls(scPanel, controlsSB)
		DisableControls(scPanel, controlsDB)
	endif
End

/// @brief dynamic settings for panel initialization
///
/// @param mainPanel 	mainWindow panel name
Function BSP_DynamicStartupSettings(mainPanel)
	string mainPanel

	variable sweepNo
	string bsPanel, controls, controlsDB, controlsSB

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
	SetControlProcedure(bsPanel, "check_Display_VisibleXrange", BSP_AddBrowserPrefix(mainPanel, "CheckProc_ScaleAxes"))
	SetControlProcedures(bsPanel, "check_SweepControl_HideSweep;", BSP_AddBrowserPrefix(mainPanel, "CheckProc_ChangedSetting"))
	SetControlProcedures(bsPanel, "slider_BrowserSettings_dDAQ;", "BSP_SliderProc_ChangedSetting")

	// SB/DB specific controls
	controlsSB = "check_BrowserSettings_TA;check_Display_EqualYrange;check_Display_EqualYignore;"
	controlsDB = "popup_DB_lockedDevices;"
	if(BSP_IsDataBrowser(mainPanel))
		EnableControls(bsPanel, controlsDB)
		DisableControls(bsPanel, controlsSB)
	else
		EnableControls(bsPanel, controlsSB)
		DisableControls(bsPanel, controlsDB)
		DisableControls(bsPanel, "list_dashboard;check_BrowserSettings_DB_Failed;check_BrowserSettings_DB_Passed")
		PopupMenu popup_TimeAlignment_Master win=$bsPanel, value = #("SB_GetAllTraces(\"" + mainPanel + "\")")
	endif

	BSP_InitMainCheckboxes(bsPanel)

	PGC_SetAndActivateControl(bsPanel, "Settings", val = 0)
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
	ChannelSelectionWaveToGUI(bsPanel, channelSelection)

	// dashboard
	WAVE listBoxColorWave = GetAnaFuncDashboardColorWave(dfr)
	WAVE listBoxSelWave   = GetAnaFuncDashboardselWave(dfr)
	WAVE/T listBoxWave    = GetAnaFuncDashboardListWave(dfr)
	ListBox list_dashboard, win=$bsPanel, listWave=listBoxWave, colorWave=listBoxColorWave, selWave=listBoxSelWave
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

/// @brief get the channel selection wave stored in main window property CSW_FOLDER
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

	string mainPanel

	mainPanel = GetMainWindow(win)
	ASSERT(WindowExists(mainPanel), "specified panel does not exist.")

	SetWindow $mainPanel, userdata($MIES_BSP_BROWSER) = type
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

	string controlList = "group_properties_sweeps;popup_overlaySweeps_select;setvar_overlaySweeps_offset;setvar_overlaySweeps_step;check_overlaySweeps_disableHS;check_overlaySweeps_non_commula;list_of_ranges"

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

	string controlList = "group_properties_pulse;check_pulseAver_indTraces;check_pulseAver_showAver;check_pulseAver_multGraphs;setvar_pulseAver_startPulse;setvar_pulseAver_endPulse;setvar_pulseAver_fallbackLength;"

	BSP_SetControlStatus(win, controlList, PA_IsActive(win))
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

/// @brief window macro for bottom panel
Window SweepControlPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	//NewPanel /W=(459,529,1042,593) as "Sweep Control"
	Button button_SweepControl_NextSweep,pos={335.00,0.00},size={150.00,37.00},title="Next  \\W649"
	Button button_SweepControl_NextSweep,help={"Displays the next sweep (sweep no. = last sweep number + step)"}
	Button button_SweepControl_NextSweep,fSize=20
	ValDisplay valdisp_SweepControl_LastSweep,pos={240.00,3.00},size={89.00,34.00},bodyWidth=60,title="of"
	ValDisplay valdisp_SweepControl_LastSweep,help={"The number of the last sweep acquired for the device assigned to the data browser"}
	ValDisplay valdisp_SweepControl_LastSweep,fSize=24,frame=2,fStyle=1
	ValDisplay valdisp_SweepControl_LastSweep,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_SweepControl_LastSweep,value= #"0"
	ValDisplay valdisp_SweepControl_LastSweep,barBackColor= (56576,56576,56576)
	SetVariable setvar_SweepControl_SweepNo,pos={155.00,2.00},size={74.00,35.00}
	SetVariable setvar_SweepControl_SweepNo,help={"Sweep number of last sweep plotted"}
	SetVariable setvar_SweepControl_SweepNo,userdata(lastSweep)=  "NaN",fSize=24
	SetVariable setvar_SweepControl_SweepNo,limits={0,0,1},value= _NUM:0,live= 1
	SetVariable setvar_SweepControl_SweepStep,pos={488.00,2.00},size={92.00,35.00},bodyWidth=40,title="Step"
	SetVariable setvar_SweepControl_SweepStep,help={"Set the increment between sweeps"}
	SetVariable setvar_SweepControl_SweepStep,userdata(lastSweep)=  "0",fSize=24
	SetVariable setvar_SweepControl_SweepStep,limits={1,inf,1},value= _NUM:1
	Button button_SweepControl_PrevSweep,pos={0.00,0.00},size={150.00,37.00},title="\\W646 Previous"
	Button button_SweepControl_PrevSweep,help={"Displays the previous sweep (sweep no. = last sweep number - step)"}
	Button button_SweepControl_PrevSweep,fSize=20
	PopupMenu Popup_SweepControl_Selector,pos={155.00,41.00},size={175.00,19.00},bodyWidth=175
	PopupMenu Popup_SweepControl_Selector,help={"List of sweeps in this sweep browser"}
	PopupMenu Popup_SweepControl_Selector,userdata(tabnum)=  "0"
	PopupMenu Popup_SweepControl_Selector,userdata(tabcontrol)=  "Settings"
	PopupMenu Popup_SweepControl_Selector,mode=1,popvalue=" ",value= #"\" \""
	CheckBox check_SweepControl_AutoUpdate,pos={345.00,44.00},size={159.00,15.00},disable=2,title="Display last sweep acquired"
	CheckBox check_SweepControl_AutoUpdate,help={"Displays the last sweep acquired when data acquistion is ongoing"}
	CheckBox check_SweepControl_AutoUpdate,value= 0
EndMacro

/// @brief window macro for side panel
Window BrowserSettingsPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	//NewPanel /W=(202,80,484,492) as " "
	GroupBox group_calc,pos={12.00,196.00},size={288.00,51.00}
	GroupBox group_calc,userdata(tabnum)=  "0",userdata(tabcontrol)=  "Settings"
	TabControl Settings,pos={2.00,2.00},size={362.00,22.00},proc=ACL_DisplayTab
	TabControl Settings,userdata(currenttab)=  "0",tabLabel(0)="Settings"
	TabControl Settings,tabLabel(1)="OVS",tabLabel(2)="CS",tabLabel(3)="AR"
	TabControl Settings,tabLabel(4)="PA",tabLabel(5)="Note",tabLabel(6)="Dashboard"
	TabControl Settings,value= 0
	ListBox list_of_ranges,pos={83.00,199.00},size={186.00,200.00},disable=3,proc=OVS_MainListBoxProc
	ListBox list_of_ranges,help={"Select sweeps for overlay; The second column (\"Headstages\") allows to ignore some headstages for the graphing. Syntax is a semicolon \";\" separated list of subranges, e.g. \"0\", \"0,2\", \"1;4;2\""}
	ListBox list_of_ranges,userdata(tabnum)=  "1",userdata(tabcontrol)=  "Settings"
	ListBox list_of_ranges,widths={50,50}
	PopupMenu popup_overlaySweeps_select,pos={112.00,99.00},size={143.00,19.00},bodyWidth=109,disable=3,proc=OVS_PopMenuProc_Select,title="Select"
	PopupMenu popup_overlaySweeps_select,help={"Select sweeps according to various properties"}
	PopupMenu popup_overlaySweeps_select,userdata(tabnum)=  "1"
	PopupMenu popup_overlaySweeps_select,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_overlaySweeps_select,mode=1,popvalue="- none -",value= #"OVS_GetSweepSelectionChoices(\"DB_ITC18USB_Dev_0#BrowserSettingsPanel\")"
	CheckBox check_overlaySweeps_disableHS,pos={99.00,160.00},size={120.00,15.00},disable=3,proc=OVS_CheckBoxProc_HS_Select,title="Headstage Removal"
	CheckBox check_overlaySweeps_disableHS,help={"Toggle headstage removal"}
	CheckBox check_overlaySweeps_disableHS,userdata(tabnum)=  "1"
	CheckBox check_overlaySweeps_disableHS,userdata(tabcontrol)=  "Settings"
	CheckBox check_overlaySweeps_disableHS,value= 0
	CheckBox check_overlaySweeps_non_commula,pos={98.00,180.00},size={153.00,15.00},disable=3,title="Non-commulative update"
	CheckBox check_overlaySweeps_non_commula,help={"If \"Display Last sweep acquired\" is checked, this checkbox here allows to only add the newly acquired sweep and will remove the currently added last sweep."}
	CheckBox check_overlaySweeps_non_commula,userdata(tabcontrol)=  "Settings"
	CheckBox check_overlaySweeps_non_commula,userdata(tabnum)=  "1",value= 0
	SetVariable setvar_overlaySweeps_offset,pos={97.00,126.00},size={81.00,18.00},bodyWidth=45,disable=3,proc=OVS_SetVarProc_SelectionRange,title="Offset"
	SetVariable setvar_overlaySweeps_offset,help={"Offsets the first selected sweep from the selection menu"}
	SetVariable setvar_overlaySweeps_offset,userdata(tabnum)=  "1"
	SetVariable setvar_overlaySweeps_offset,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_overlaySweeps_offset,limits={0,inf,1},value= _NUM:0
	SetVariable setvar_overlaySweeps_step,pos={184.00,126.00},size={72.00,18.00},bodyWidth=45,disable=3,proc=OVS_SetVarProc_SelectionRange,title="Step"
	SetVariable setvar_overlaySweeps_step,help={"Selects every `step` sweep from the selection menu"}
	SetVariable setvar_overlaySweeps_step,userdata(tabnum)=  "1"
	SetVariable setvar_overlaySweeps_step,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_overlaySweeps_step,limits={1,inf,1},value= _NUM:1
	GroupBox group_enable_sweeps,pos={4.00,30.00},size={354.00,53.00},disable=1,title="Overlay Sweeps"
	GroupBox group_enable_sweeps,userdata(tabnum)=  "1"
	GroupBox group_enable_sweeps,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_channels,pos={6.00,25.00},size={352.00,383.00},disable=1,title="Channel Selection"
	GroupBox group_enable_channels,userdata(tabnum)=  "2"
	GroupBox group_enable_channels,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_artifact,pos={4.00,27.00},size={354.00,54.00},disable=1,title="Artefact Removal"
	GroupBox group_enable_artifact,userdata(tabnum)=  "3"
	GroupBox group_enable_artifact,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_sweeps,pos={5.00,94.00},size={354.00,310.00},disable=3
	GroupBox group_properties_sweeps,userdata(tabnum)=  "1"
	GroupBox group_properties_sweeps,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_artefact,pos={5.00,84.00},size={354.00,321.00},disable=3
	GroupBox group_properties_artefact,userdata(tabnum)=  "3"
	GroupBox group_properties_artefact,userdata(tabcontrol)=  "Settings"
	GroupBox group_channelSel_DA,pos={95.00,44.00},size={44.00,199.00},disable=1,title="DA"
	GroupBox group_channelSel_DA,userdata(tabnum)=  "2"
	GroupBox group_channelSel_DA,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_pulse,pos={4.00,89.00},size={355.00,317.00},disable=3
	GroupBox group_properties_pulse,userdata(tabnum)=  "4"
	GroupBox group_properties_pulse,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_pulse,pos={4.00,27.00},size={355.00,57.00},disable=1,title="Pulse Averaging"
	GroupBox group_enable_pulse,userdata(tabnum)=  "4"
	GroupBox group_enable_pulse,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_0,pos={105.00,60.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="0"
	CheckBox check_channelSel_DA_0,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_0,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_DA_1,pos={105.00,81.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="1"
	CheckBox check_channelSel_DA_1,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_1,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_DA_2,pos={105.00,102.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="2"
	CheckBox check_channelSel_DA_2,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_2,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_DA_3,pos={105.00,123.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="3"
	CheckBox check_channelSel_DA_3,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_3,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_DA_4,pos={105.00,144.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="4"
	CheckBox check_channelSel_DA_4,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_4,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_DA_5,pos={105.00,165.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="5"
	CheckBox check_channelSel_DA_5,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_5,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_DA_6,pos={105.00,186.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="6"
	CheckBox check_channelSel_DA_6,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_6,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_DA_7,pos={105.00,207.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="7"
	CheckBox check_channelSel_DA_7,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_7,userdata(tabcontrol)=  "Settings",value= 1
	GroupBox group_channelSel_HEADSTAGE,pos={33.00,44.00},size={44.00,199.00},disable=1,title="HS"
	GroupBox group_channelSel_HEADSTAGE,userdata(tabnum)=  "2"
	GroupBox group_channelSel_HEADSTAGE,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_0,pos={43.00,60.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="0"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_HEADSTAGE_1,pos={43.00,81.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="1"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_HEADSTAGE_2,pos={43.00,102.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="2"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_HEADSTAGE_3,pos={43.00,123.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="3"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_HEADSTAGE_4,pos={43.00,144.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="4"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_HEADSTAGE_5,pos={43.00,165.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="5"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_HEADSTAGE_6,pos={43.00,186.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="6"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_HEADSTAGE_7,pos={43.00,207.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="7"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(tabcontrol)=  "Settings",value= 1
	GroupBox group_channelSel_AD,pos={156.00,44.00},size={45.00,360.00},disable=1,title="AD"
	GroupBox group_channelSel_AD,userdata(tabnum)=  "2"
	GroupBox group_channelSel_AD,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_0,pos={164.00,60.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="0"
	CheckBox check_channelSel_AD_0,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_0,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_1,pos={164.00,81.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="1"
	CheckBox check_channelSel_AD_1,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_1,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_2,pos={164.00,102.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="2"
	CheckBox check_channelSel_AD_2,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_2,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_3,pos={164.00,123.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="3"
	CheckBox check_channelSel_AD_3,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_3,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_4,pos={164.00,144.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="4"
	CheckBox check_channelSel_AD_4,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_4,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_5,pos={164.00,165.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="5"
	CheckBox check_channelSel_AD_5,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_5,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_6,pos={164.00,186.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="6"
	CheckBox check_channelSel_AD_6,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_6,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_7,pos={164.00,207.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="7"
	CheckBox check_channelSel_AD_7,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_7,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_8,pos={164.00,229.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="8"
	CheckBox check_channelSel_AD_8,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_8,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_9,pos={164.00,250.00},size={21.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="9"
	CheckBox check_channelSel_AD_9,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_9,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_10,pos={164.00,271.00},size={27.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="10"
	CheckBox check_channelSel_AD_10,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_10,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_11,pos={164.00,292.00},size={27.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="11"
	CheckBox check_channelSel_AD_11,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_11,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_12,pos={164.00,313.00},size={27.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="12"
	CheckBox check_channelSel_AD_12,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_12,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_13,pos={164.00,334.00},size={27.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="13"
	CheckBox check_channelSel_AD_13,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_13,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_14,pos={164.00,355.00},size={27.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="14"
	CheckBox check_channelSel_AD_14,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_14,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_15,pos={164.00,377.00},size={27.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="15"
	CheckBox check_channelSel_AD_15,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_15,userdata(tabcontrol)=  "Settings",value= 1
	ListBox list_of_ranges1,pos={77.00,157.00},size={198.00,240.00},disable=3,proc=AR_MainListBoxProc
	ListBox list_of_ranges1,userdata(tabnum)=  "3",userdata(tabcontrol)=  "Settings"
	ListBox list_of_ranges1,mode= 1,selRow= 0,widths={54,50,66}
	Button button_RemoveRanges,pos={76.00,126.00},size={55.00,22.00},disable=3,proc=AR_ButtonProc_RemoveRanges,title="Remove"
	Button button_RemoveRanges,userdata(tabnum)=  "3"
	Button button_RemoveRanges,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_cutoff_length_after,pos={233.00,96.00},size={45.00,18.00},disable=3,proc=AR_SetVarProcCutoffLength
	SetVariable setvar_cutoff_length_after,help={"Time in ms which should be cutoff *after* the artefact."}
	SetVariable setvar_cutoff_length_after,userdata(tabnum)=  "3"
	SetVariable setvar_cutoff_length_after,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_cutoff_length_after,limits={0,inf,0.1},value= _NUM:0.2
	SetVariable setvar_cutoff_length_before,pos={79.00,96.00},size={150.00,18.00},disable=3,proc=AR_SetVarProcCutoffLength,title="Cutoff length [ms]:"
	SetVariable setvar_cutoff_length_before,help={"Time in ms which should be cutoff *before* the artefact."}
	SetVariable setvar_cutoff_length_before,userdata(tabnum)=  "3"
	SetVariable setvar_cutoff_length_before,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_cutoff_length_before,limits={0,inf,0.1},value= _NUM:0.1
	CheckBox check_auto_remove,pos={146.00,130.00},size={84.00,15.00},disable=3,proc=AR_CheckProc_Update,title="Auto remove"
	CheckBox check_auto_remove,help={"Automatically remove the found ranges on sweep plotting"}
	CheckBox check_auto_remove,userdata(tabnum)=  "3"
	CheckBox check_auto_remove,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_highlightRanges,pos={246.00,130.00},size={30.00,15.00},disable=3,proc=AR_CheckProc_Update,title="HL"
	CheckBox check_highlightRanges,help={"Visualize the found ranges in the graph (*might* slowdown graphing)"}
	CheckBox check_highlightRanges,userdata(tabnum)=  "3"
	CheckBox check_highlightRanges,userdata(tabcontrol)=  "Settings",value= 0
	SetVariable setvar_pulseAver_fallbackLength,pos={105.00,207.00},size={137.00,18.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="Fallback Length"
	SetVariable setvar_pulseAver_fallbackLength,help={"Pulse To Pulse Length in ms for edge cases which can not be computed."}
	SetVariable setvar_pulseAver_fallbackLength,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_fallbackLength,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_fallbackLength,value= _NUM:100
	SetVariable setvar_pulseAver_endPulse,pos={120.00,184.00},size={122.00,18.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="Ending Pulse"
	SetVariable setvar_pulseAver_endPulse,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_endPulse,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_endPulse,value= _NUM:inf
	SetVariable setvar_pulseAver_startPulse,pos={116.00,162.00},size={126.00,18.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="Starting Pulse"
	SetVariable setvar_pulseAver_startPulse,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_startPulse,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_startPulse,value= _NUM:0
	CheckBox check_pulseAver_multGraphs,pos={110.00,142.00},size={120.00,15.00},disable=3,proc=PA_CheckProc_Common,title="Use multiple graphs"
	CheckBox check_pulseAver_multGraphs,help={"Show the single pulses in multiple graphs or only one graph with mutiple axis."}
	CheckBox check_pulseAver_multGraphs,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_multGraphs,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_pulseAver_showAver,pos={110.00,121.00},size={117.00,15.00},disable=3,proc=PA_CheckProc_Common,title="Show average trace"
	CheckBox check_pulseAver_showAver,help={"Show the average trace"}
	CheckBox check_pulseAver_showAver,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_showAver,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_pulseAver_indTraces,pos={110.00,100.00},size={133.00,15.00},disable=3,proc=PA_CheckProc_Common,title="Show individual traces"
	CheckBox check_pulseAver_indTraces,help={"Show the individual traces"}
	CheckBox check_pulseAver_indTraces,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_indTraces,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_BrowserSettings_OVS,pos={156.00,50.00},size={50.00,15.00},disable=1,proc=DB_CheckProc_OverlaySweeps,title="enable"
	CheckBox check_BrowserSettings_OVS,help={"Adds unplotted sweep to graph. Removes plotted sweep from graph."}
	CheckBox check_BrowserSettings_OVS,userdata(tabnum)=  "1"
	CheckBox check_BrowserSettings_OVS,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_BrowserSettings_AR,pos={151.00,50.00},size={50.00,15.00},disable=1,proc=BSP_CheckBoxProc_ArtRemoval,title="enable"
	CheckBox check_BrowserSettings_AR,help={"Open the artefact removal dialog"}
	CheckBox check_BrowserSettings_AR,userdata(tabnum)=  "3"
	CheckBox check_BrowserSettings_AR,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_BrowserSettings_PA,pos={150.00,50.00},size={50.00,15.00},disable=1,proc=BSP_CheckBoxProc_PerPulseAver,title="enable"
	CheckBox check_BrowserSettings_PA,help={"Allows to average multiple pulses from pulse train epochs"}
	CheckBox check_BrowserSettings_PA,userdata(tabnum)=  "4"
	CheckBox check_BrowserSettings_PA,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_BrowserSettings_DAC,pos={13.00,36.00},size={31.00,15.00},proc=DB_CheckProc_ChangedSetting,title="DA"
	CheckBox check_BrowserSettings_DAC,help={"Display the DA channel data"}
	CheckBox check_BrowserSettings_DAC,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_DAC,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_BrowserSettings_ADC,pos={75.00,36.00},size={31.00,15.00},proc=DB_CheckProc_ChangedSetting,title="AD"
	CheckBox check_BrowserSettings_ADC,help={"Display the AD channels"}
	CheckBox check_BrowserSettings_ADC,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_ADC,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_BrowserSettings_TTL,pos={132.00,36.00},size={35.00,15.00},proc=DB_CheckProc_ChangedSetting,title="TTL"
	CheckBox check_BrowserSettings_TTL,help={"Display the TTL channels"}
	CheckBox check_BrowserSettings_TTL,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_TTL,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_BrowserSettings_OChan,pos={13.00,62.00},size={64.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Channels"
	CheckBox check_BrowserSettings_OChan,help={"Overlay the data from multiple channels in one graph"}
	CheckBox check_BrowserSettings_OChan,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_OChan,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_BrowserSettings_dDAQ,pos={132.00,62.00},size={47.00,15.00},proc=DB_CheckProc_ChangedSetting,title="dDAQ"
	CheckBox check_BrowserSettings_dDAQ,help={"Enable dedicated support for viewing distributed DAQ data"}
	CheckBox check_BrowserSettings_dDAQ,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_dDAQ,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_Calculation_ZeroTraces,pos={25.00,220.00},size={76.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Zero Traces"
	CheckBox check_Calculation_ZeroTraces,help={"Remove the offset of all traces"}
	CheckBox check_Calculation_ZeroTraces,userdata(tabnum)=  "0"
	CheckBox check_Calculation_ZeroTraces,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_Calculation_AverageTraces,pos={25.00,200.00},size={95.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Average Traces"
	CheckBox check_Calculation_AverageTraces,help={"Average all traces which belong to the same y axis"}
	CheckBox check_Calculation_AverageTraces,userdata(tabnum)=  "0"
	CheckBox check_Calculation_AverageTraces,userdata(tabcontrol)=  "Settings"
	CheckBox check_Calculation_AverageTraces,value= 0
	CheckBox check_BrowserSettings_TA,pos={139.00,112.00},size={50.00,15.00},disable=2,proc=SB_TimeAlignmentProc,title="enable"
	CheckBox check_BrowserSettings_TA,help={"Activate time alignment"}
	CheckBox check_BrowserSettings_TA,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_TA,userdata(tabcontrol)=  "Settings",value= 0
	PopupMenu popup_TimeAlignment_Mode,pos={24.00,135.00},size={143.00,19.00},bodyWidth=50,disable=2,proc=SB_TimeAlignmentPopup,title="Alignment Mode"
	PopupMenu popup_TimeAlignment_Mode,help={"Select the alignment mode"}
	PopupMenu popup_TimeAlignment_Mode,userdata(tabnum)=  "0"
	PopupMenu popup_TimeAlignment_Mode,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_TimeAlignment_Mode,mode=1,popvalue="Level (Raising)",value= #"\"Level (Raising);Level (Falling);Min;Max\""
	SetVariable setvar_TimeAlignment_LevelCross,pos={173.00,136.00},size={50.00,18.00},disable=2,proc=SB_TimeAlignmentLevel,title="Level"
	SetVariable setvar_TimeAlignment_LevelCross,help={"Select the level (for rising and falling alignment mode) at which traces are aligned"}
	SetVariable setvar_TimeAlignment_LevelCross,userdata(tabnum)=  "0"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_TimeAlignment_LevelCross,limits={-inf,inf,0},value= _NUM:0
	Button button_TimeAlignment_Action,pos={193.00,159.00},size={30.00,20.00},disable=2,proc=SB_DoTimeAlignment,title="Do!"
	Button button_TimeAlignment_Action,help={"Perform the time alignment, needs the cursors A and B to have a selected feature"}
	Button button_TimeAlignment_Action,userdata(tabnum)=  "0"
	Button button_TimeAlignment_Action,userdata(tabcontrol)=  "Settings"
	GroupBox group_SB_axes_scaling,pos={12.00,248.00},size={286.00,52.00},title="Axes Scaling"
	GroupBox group_SB_axes_scaling,userdata(tabnum)=  "0"
	GroupBox group_SB_axes_scaling,userdata(tabcontrol)=  "Settings"
	CheckBox check_Display_VisibleXrange,pos={25.00,272.00},size={40.00,15.00},proc=DB_CheckProc_ScaleAxes,title="Vis X"
	CheckBox check_Display_VisibleXrange,help={"Scale the y axis to the visible x data range"}
	CheckBox check_Display_VisibleXrange,userdata(tabnum)=  "0"
	CheckBox check_Display_VisibleXrange,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_Display_EqualYrange,pos={79.00,272.00},size={54.00,15.00},disable=2,title="Equal Y"
	CheckBox check_Display_EqualYrange,help={"Equalize the vertical axes ranges"}
	CheckBox check_Display_EqualYrange,userdata(tabnum)=  "0"
	CheckBox check_Display_EqualYrange,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_Display_EqualYignore,pos={139.00,272.00},size={35.00,15.00},disable=2,title="ign."
	CheckBox check_Display_EqualYignore,help={"Equalize the vertical axes ranges but ignore all traces with level crossings"}
	CheckBox check_Display_EqualYignore,userdata(tabnum)=  "0"
	CheckBox check_Display_EqualYignore,userdata(tabcontrol)=  "Settings",value= 0
	SetVariable setvar_Display_EqualYlevel,pos={178.00,270.00},size={25.00,18.00},disable=2,proc=SB_AxisScalingLevelCross
	SetVariable setvar_Display_EqualYlevel,help={"Crossing level value for 'Equal Y ign.\""}
	SetVariable setvar_Display_EqualYlevel,userdata(tabnum)=  "0"
	SetVariable setvar_Display_EqualYlevel,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_Display_EqualYlevel,limits={-inf,inf,0},value= _NUM:0
	PopupMenu popup_TimeAlignment_Master,pos={32.00,159.00},size={134.00,19.00},bodyWidth=50,disable=2,proc=SB_TimeAlignmentPopup,title="Reference trace"
	PopupMenu popup_TimeAlignment_Master,help={"Select the reference trace to which all other traces should be aligned to"}
	PopupMenu popup_TimeAlignment_Master,userdata(tabnum)=  "0"
	PopupMenu popup_TimeAlignment_Master,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_TimeAlignment_Master,mode=1,popvalue="AD0",value= #"\"\""
	Button button_Calculation_RestoreData,pos={137.00,210.00},size={75.00,25.00},proc=DB_ButtonProc_RestoreData,title="Restore"
	Button button_Calculation_RestoreData,help={"Duplicate the graph and its trace for further processing"}
	Button button_Calculation_RestoreData,userdata(tabnum)=  "0"
	Button button_Calculation_RestoreData,userdata(tabcontrol)=  "Settings"
	Button button_BrowserSettings_Export,pos={68.00,333.00},size={100.00,25.00},proc=SB_ButtonProc_ExportTraces,title="Export Traces"
	Button button_BrowserSettings_Export,help={"Export the traces for further processing"}
	Button button_BrowserSettings_Export,userdata(tabnum)=  "0"
	Button button_BrowserSettings_Export,userdata(tabcontrol)=  "Settings"
	GroupBox group_timealignment,pos={12.00,89.00},size={286.00,101.00},title="Time Alignment"
	GroupBox group_timealignment,userdata(tabnum)=  "0"
	GroupBox group_timealignment,userdata(tabcontrol)=  "Settings"
	Slider slider_BrowserSettings_dDAQ,pos={302.00,38.00},size={54.00,300.00},disable=2,proc=BSP_SliderProc_ChangedSetting
	Slider slider_BrowserSettings_dDAQ,help={"Allows to view only regions from the selected headstage (oodDAQ) resp. the selected headstage (dDAQ). Choose -1 to display all."}
	Slider slider_BrowserSettings_dDAQ,userdata(tabnum)=  "0"
	Slider slider_BrowserSettings_dDAQ,userdata(tabcontrol)=  "Settings"
	Slider slider_BrowserSettings_dDAQ,limits={-1,7,1},value= -1
	CheckBox check_SweepControl_HideSweep,pos={238.00,62.00},size={40.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Hide"
	CheckBox check_SweepControl_HideSweep,help={"Hide sweep traces. Usually combined with \"Average traces\"."}
	CheckBox check_SweepControl_HideSweep,userdata(tabnum)=  "0"
	CheckBox check_SweepControl_HideSweep,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_BrowserSettings_splitTTL,pos={238.00,36.00},size={59.00,15.00},proc=DB_CheckProc_ChangedSetting,title="sep. TTL"
	CheckBox check_BrowserSettings_splitTTL,help={"Display the TTL channel data as single traces for each TTL bit"}
	CheckBox check_BrowserSettings_splitTTL,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_splitTTL,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_splitTTL,value= 0
	PopupMenu popup_DB_lockedDevices,pos={13.00,304.00},size={205.00,19.00},bodyWidth=100,proc=DB_PopMenuProc_LockDBtoDevice,title="Device assingment:"
	PopupMenu popup_DB_lockedDevices,help={"Select a data acquistion device to display data"}
	PopupMenu popup_DB_lockedDevices,userdata(tabnum)=  "0"
	PopupMenu popup_DB_lockedDevices,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_DB_lockedDevices,mode=1,popvalue="ITC18USB_Dev_0",value= #"DB_GetAllDevicesWithData()"
	ListBox list_dashboard,pos={4.00,90.00},size={353.00,311.00},proc=AD_ListBoxProc
	ListBox list_dashboard,userdata(tabnum)=  "6",userdata(tabcontrol)=  "Settings"
	ListBox list_dashboard,fSize=12
	ListBox list_dashboard,mode= 1,selRow= -1,widths={141,109,500}
	ListBox list_dashboard,userColumnResize= 1
	GroupBox group_enable_dashboard,pos={4.00,27.00},size={355.00,57.00}
	GroupBox group_enable_dashboard,userdata(tabnum)=  "6",userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_DB_Passed,pos={160.00,40.00},size={51.00,15.00},title="Passed"
	CheckBox check_BrowserSettings_DB_Passed,help={"Show passed sweeps on double click into ListBox "}
	CheckBox check_BrowserSettings_DB_Passed,value= 0
	CheckBox check_BrowserSettings_DB_Passed, proc=AD_CheckProc_PassedSweeps
	CheckBox check_BrowserSettings_DB_Passed,userdata(tabnum)=  "6",userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_DB_Failed,pos={160.00,60.00},size={46.00,15.00},title="Failed"
	CheckBox check_BrowserSettings_DB_Failed,help={"Show failed sweeps on double click into ListBox "}
	CheckBox check_BrowserSettings_DB_Failed,value= 0
	CheckBox check_BrowserSettings_DB_Failed,userdata(tabnum)=  "6",userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_DB_Failed,proc=AD_CheckProc_FailedSweeps
	SetWindow kwTopWin,hook(main)=BSP_ClosePanelHook
	SetWindow kwTopWin,userdata(panelVersion)=  "2"
	NewNotebook /F=1 /N=WaveNoteDisplay /W=(200,24,600,561)/FG=(FL,$"",FR,UGH0) /HOST=# /V=0 /OPTS=10
	Notebook kwTopWin, defaultTab=36, autoSave= 1, showRuler=0, rulerUnits=1
	Notebook kwTopWin newRuler=Normal, justification=0, margins={0,0,252}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",10,0,(0,0,0)}
	SetWindow kwTopWin,userdata(tabnum)=  "5"
	SetWindow kwTopWin,userdata(tabcontrol)=  "Settings"
	RenameWindow #,WaveNoteDisplay
	SetActiveSubwindow ##
EndMacro

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

/// @brief procedure for the open button of the side panel
Function BSP_ButtonProc_Panel(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string win

	switch(ba.eventcode)
		case 2: // mouse up
			win = GetMainWindow(ba.win)
			BSP_OpenPanel(win)
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

/// @brief update controls in scPanel and change to new sweep
///
/// @param win 		  name of external panel or main window
/// @param ctrl       name of the button that was pressed and is initiating the update
/// @param firstSweep first available sweep(DB) or index(SB)
/// @param lastSweep  first available sweep(DB) or index(SB)
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
		default:
			return 0
	endswitch

	return GetCheckboxState(bsPanel, control) == CHECKBOX_SELECTED
End
