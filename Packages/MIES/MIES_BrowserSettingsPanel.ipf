#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma IgorVersion=7.04

#include ":MIES_OverlaySweeps"
#include ":MIES_PulseAveraging"
#include ":MIES_ArtefactRemoval"

/// @file MIES_BrowserSettingsPanel.ipf
/// @brief __BSP__ Panel for __DB__ and __AB__ (SweepBrowser) that combines different settings in a tabcontrol.

static strConstant EXT_PANEL_SUBWINDOW = "BrowserSettingsPanel"
static Constant BROWSERSETTINGS_PANEL_VERSION = 1

/// @brief return the name of the external panel depending on main window name
///
/// @param mainPanel 	mainWindow panel name
Function/S BSP_GetPanel(mainPanel)
	string mainPanel

	return GetMainWindow(mainPanel) + "#" + EXT_PANEL_SUBWINDOW
End

/// @brief open/close side Panel
///
/// @param mainPanel 	mainWindow panel name
Function BSP_TogglePanel(mainPanel)
	string mainPanel

	variable openSidePanel

	if(BSP_MainPanelNeedsUpdate(mainPanel))
		Abort "Can not display data. The main panel is too old to be usable. Please close it and open a new one."
	endif

	openSidePanel = TogglePanel(mainPanel, EXT_PANEL_SUBWINDOW)

	if(BSP_PanelNeedsUpdate(mainPanel))
		KillWindow/Z $BSP_GetPanel(mainPanel)
		openSidePanel = 1
	endif

	if(!openSidePanel)
		return 1
	endif

	ASSERT(WindowExists(mainPanel), "HOST panel does not exist")
	NewPanel/HOST=$mainPanel/EXT=1/W=(260,0,0,600)/N=$EXT_PANEL_SUBWINDOW  as " "
	Execute "DataBrowserPanel()"
	BSP_DynamicStartupSettings(mainPanel)
	BSP_MainPanelButtonToggle(mainPanel, 0)
End

/// @brief dynamic settings for panel initialization
///
/// @param mainPanel 	mainWindow panel name
static Function BSP_DynamicStartupSettings(mainPanel)
	string mainPanel

	variable sweepNo
	string extPanel

	extPanel = BSP_GetPanel(mainPanel)

	SetWindow $extPanel, hook(main)=BSP_ClosePanelHook
	AddVersionToPanel(extPanel, BROWSERSETTINGS_PANEL_VERSION)

	// overlay sweeps
	SetControlProcedure(extPanel, "check_BrowserSettings_OVS", "DB_CheckBoxProc_OverlaySweeps")
	DFREF dfr = BSP_GetFolder(mainPanel, MIES_BSP_OVS_FOLDER)
	WAVE/T listBoxWave        = GetOverlaySweepsListWave(dfr)
	WAVE listBoxSelWave       = GetOverlaySweepsListSelWave(dfr)
	WAVE/WAVE sweepSelChoices = GetOverlaySweepSelectionChoices(dfr)
	ListBox list_of_ranges, listWave=listBoxWave
	ListBox list_of_ranges, selWave=listBoxSelWave
	sweepNo = GetSetVariable(mainPanel, "setvar_DataBrowser_SweepNo")
	OVS_ChangeSweepSelectionState(mainPanel, CHECKBOX_SELECTED, sweepNO=sweepNo)
	WaveClear listBoxWave
	PopupMenu popup_overlaySweeps_select,value= #("OVS_GetSweepSelectionChoices(\"" + extPanel + "\")")

	// artefact removal
	DFREF dfr = BSP_GetFolder(mainPanel, MIES_BSP_AR_FOLDER)
	WAVE/T listBoxWave = GetArtefactRemovalListWave(dfr)
	ListBox list_of_ranges1, listWave=listBoxWave

	// bind the channel selection wave to the user controls of the external panel
	WAVE channelSelection = BSP_GetChannelSelectionWave(mainPanel)
	ChannelSelectionWaveToGUI(mainPanel, channelSelection)

	BSP_SetMainCheckboxes(extPanel, 0)
	BSP_SetCSButtonProc(extPanel, "DB_CheckProc_ChangedSetting")

	PGC_SetAndActivateControl(extPanel, "Settings", val = MIES_BSP_OVS)
	UpdateSweepPlot(mainPanel)
End

/// @brief get the channel selection wave stored in main window property CSW_FOLDER
///
/// @param panelName 	name of external panel or main window
/// @returns channel selection wave
Function/WAVE BSP_GetChannelSelectionWave(panelName)
	string panelName

	DFREF dfr = BSP_GetFolder(panelName, MIES_BSP_CS_FOLDER)
	WAVE wv = GetChannelSelectionWave(dfr)

	return wv
End

/// @brief get a FOLDER property from the specified panel
///
/// @param panelName 				name of external panel or main window
/// @param MIES_BSP_FOLDER_TYPE 	see the FOLDER constants in this file
///
/// @return DFR to specified folder. No check for invalid folders
Function/DF BSP_GetFolder(panelName, MIES_BSP_FOLDER_TYPE)
	string panelName, MIES_BSP_FOLDER_TYPE

	// since BSP-side-panel all properties are stored in main panel
	panelName = GetMainWindow(panelName)
	ASSERT(WindowExists(panelName), "specified panel does not exist.")

	DFREF dfr = $GetUserData(panelName, "", MIES_BSP_FOLDER_TYPE)
	ASSERT(DataFolderExistsDFR(dfr), "DataFolder does not exist. Probably check device assignment.")

	return dfr
End

/// @brief set a FOLDER property at the specified panel
///
/// @param panelName 				name of external panel or main window
/// @param dfr 						DataFolder Reference to th folder
/// @param MIES_BSP_FOLDER_TYPE 	see the FOLDER constants in this file
Function BSP_SetFolder(panelName, dfr, MIES_BSP_FOLDER_TYPE)
	string panelName, MIES_BSP_FOLDER_TYPE
	DFREF dfr

	panelName = GetMainWindow(panelName)

	ASSERT(DataFolderExistsDFR(dfr), "Missing dfr")
	SetWindow $panelName, userData($MIES_BSP_FOLDER_TYPE) = GetDataFolder(1, dfr)
End

/// @brief get a the assigned DEVICE property from the specified panel
///
/// @param panelName 				name of external panel or main window
///
/// @return device as string
Function/S BSP_GetDevice(panelName)
	string panelName

	// since BSP-side-panel all properties are stored in main panel
	panelName = GetMainWindow(panelName)
	ASSERT(WindowExists(panelName), "specified panel does not exist.")

	return GetUserData(panelName, "", MIES_BSP_DEVICE)
End

/// @brief set DEVICE property to the userdata of the specified panel
///
/// @param panelName                name of external panel or main window
/// @param device                   bound device as string
Function/S BSP_SetDevice(panelName, device)
	string panelName, device

	SetWindow $panelName, userdata($MIES_BSP_DEVICE) = device
End

/// @brief check if the DEVICE property has a not nullstring property
///
/// @param panelName 				name of external panel or main window
/// @return 1 if device is assigned and 0 otherwise. does not check if device is valid.
Function BSP_HasBoundDevice(panelName)
	string panelName

	string device = BSP_GetDevice(panelName)

	return !(IsEmpty(device) || !cmpstr(device, NONE))
End

/// @brief control the state of the enable/disable buttons on top of the extPanel tabcontrol
///
/// @param panelName 		name of external panel or main window
/// @param checkBoxState 	boolean set value of checkboxes
static Function BSP_SetMainCheckboxes(panelName, checkBoxState)
	string panelName
	variable checkBoxState

	string extPanel, control

	checkBoxState = !!checkBoxState ? CHECKBOX_SELECTED : CHECKBOX_UNSELECTED

	extPanel = BSP_GetPanel(panelName)
	if(!windowExists(extPanel))
		return NaN
	endif

	control = "check_BrowserSettings_OVS"
	PGC_SetAndActivateControl(extPanel, control, val = checkBoxState)
	control = "check_BrowserSettings_AR"
	PGC_SetAndActivateControl(extPanel, control, val = checkBoxState)
	control = "check_BrowserSettings_PA"
	PGC_SetAndActivateControl(extPanel, control, val = checkBoxState)

	return 1
End

/// @brief overwrite the control action of all Channel Selection Buttons
static Function BSP_SetCSButtonProc(panelName, procedure)
	string panelName, procedure

	string extPanel
	variable i
	string controlList = ""

	extPanel = BSP_GetPanel(panelName)

	for(i = 0; i < 8; i += 1)
		controlList += "check_channelSel_HEADSTAGE_" + num2str(i) + ";"
		controlList += "check_channelSel_DA_" + num2str(i) + ";"
	endfor
	for(i = 0; i < 16; i += 1)
		controlList += "check_channelSel_AD_" + num2str(i) + ";"
	endfor

	SetControlProcedures(extPanel, controlList, procedure)
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

	if(!IsDataBrowser(mainPanel))
		return NaN
	endif

	panelButton = "button_DataBrowser_extPanel"
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

	string mainPanel, extPanel, panelButton

	switch(s.eventCode)
		case 2: // kill
			mainPanel = GetMainWindow(s.winName)
			extPanel = BSP_GetPanel(mainPanel)

			ASSERT(!cmpstr(s.winName, extPanel), "this hook is only available for BSP panel.")

			BSP_SetMainCheckboxes(extPanel, 0)
			BSP_MainPanelButtonToggle(mainPanel, 1)

			break
	endswitch

	return 0
End

/// @brief window macro for side panel
Window DataBrowserPanel() : Panel // no dynamic changes here
	TabControl Settings,pos={2.00,2.00},size={255.00,19.00},proc=ACL_DisplayTab
	TabControl Settings,userdata(currenttab)=  "1",tabLabel(0)="Sweeps"
	TabControl Settings,tabLabel(1)="Channels",tabLabel(2)="Artefact"
	TabControl Settings,tabLabel(3)="Pulse",value= 0

	ListBox list_of_ranges,pos={27.00,206.00},size={186.00,381.00},disable=1,proc=OVS_MainListBoxProc
	ListBox list_of_ranges,help={"Select sweeps for overlay; The second column (\"Headstages\") allows to ignore some headstages for the graphing. Syntax is a semicolon \";\" separated list of subranges, e.g. \"0\", \"0,2\", \"1;4;2\""}
	ListBox list_of_ranges,userdata(tabnum)=  "0",userdata(tabcontrol)=  "Settings"
	ListBox list_of_ranges,widths={50,50}
	PopupMenu popup_overlaySweeps_select,pos={56.00,99.00},size={143.00,19.00},bodyWidth=109,disable=1,proc=OVS_PopMenuProc_Select,title="Select"
	PopupMenu popup_overlaySweeps_select,help={"Select sweeps according to various properties"}
	PopupMenu popup_overlaySweeps_select,userdata(tabnum)=  "0"
	PopupMenu popup_overlaySweeps_select,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_overlaySweeps_select,mode=1,popvalue="- none -"
	CheckBox check_overlaySweeps_disableHS,pos={43.00,160.00},size={120.00,15.00},disable=1,proc=OVS_CheckBoxProc_HS_Select,title="Headstage Removal"
	CheckBox check_overlaySweeps_disableHS,help={"Toggle headstage removal"}
	CheckBox check_overlaySweeps_disableHS,userdata(tabnum)=  "0"
	CheckBox check_overlaySweeps_disableHS,userdata(tabcontrol)=  "Settings"
	CheckBox check_overlaySweeps_disableHS,value= 0
	CheckBox check_overlaySweeps_non_commula,pos={42.00,180.00},size={153.00,15.00},title="Non-commulative update"
	CheckBox check_overlaySweeps_non_commula,help={"If \"Display Last sweep acquired\" is checked, this checkbox here allows to only add the newly acquired sweep and will remove the currently added last sweep."}
	CheckBox check_overlaySweeps_non_commula,value= 0
	CheckBox check_overlaySweeps_non_commula,userdata(tabcontrol)=  "Settings"
	CheckBox check_overlaySweeps_non_commula,userdata(tabnum)=  "0"
	SetVariable setvar_overlaySweeps_offset,pos={41.00,126.00},size={81.00,18.00},bodyWidth=45,disable=1,proc=OVS_SetVarProc_SelectionRange,title="Offset"
	SetVariable setvar_overlaySweeps_offset,help={"Offsets the first selected sweep from the selection menu"}
	SetVariable setvar_overlaySweeps_offset,userdata(tabnum)=  "0"
	SetVariable setvar_overlaySweeps_offset,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_overlaySweeps_offset,limits={0,inf,1},value= _NUM:0
	SetVariable setvar_overlaySweeps_step,pos={128.00,126.00},size={72.00,18.00},bodyWidth=45,disable=1,proc=OVS_SetVarProc_SelectionRange,title="Step"
	SetVariable setvar_overlaySweeps_step,help={"Selects every `step` sweep from the selection menu"}
	SetVariable setvar_overlaySweeps_step,userdata(tabnum)=  "0"
	SetVariable setvar_overlaySweeps_step,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_overlaySweeps_step,limits={1,inf,1},value= _NUM:1

	GroupBox group_enable_sweeps,pos={4.00,27.00},size={252.00,53.00},disable=1,title="Overlay Sweeps"
	GroupBox group_enable_sweeps,userdata(tabnum)=  "0"
	GroupBox group_enable_sweeps,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_channels,pos={4.00,27.00},size={252.00,53.00},disable=1,title="Channel Selection"
	GroupBox group_enable_channels,userdata(tabnum)=  "1"
	GroupBox group_enable_channels,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_artifact,pos={4.00,27.00},size={252.00,53.00},title="Artefact Removal"
	GroupBox group_enable_artifact,userdata(tabnum)=  "2"
	GroupBox group_enable_artifact,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_sweeps,pos={4.00,86.00},size={252.00,508.00},disable=1
	GroupBox group_properties_sweeps,userdata(tabnum)=  "0"
	GroupBox group_properties_sweeps,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_channels,pos={4.00,86.00},size={252.00,508.00},disable=1
	GroupBox group_properties_channels,userdata(tabnum)=  "1"
	GroupBox group_properties_channels,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_artefact,pos={4.00,86.00},size={252.00,508.00}
	GroupBox group_properties_artefact,userdata(tabnum)=  "2"
	GroupBox group_properties_artefact,userdata(tabcontrol)=  "Settings"
	GroupBox group_channelSel_DA,pos={105.00,104.00},size={44.00,199.00},title="DA"
	GroupBox group_channelSel_DA,userdata(tabnum)=  "1"
	GroupBox group_channelSel_DA,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_pulse,pos={4.00,86.00},size={252.00,508.00},disable=1
	GroupBox group_properties_pulse,userdata(tabnum)=  "3"
	GroupBox group_properties_pulse,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_pulse,pos={4.00,27.00},size={252.00,53.00},disable=1,title="Pulse Averaging"
	GroupBox group_enable_pulse,userdata(tabnum)=  "3"
	GroupBox group_enable_pulse,userdata(tabcontrol)=  "Settings"

	CheckBox check_channelSel_DA_0,pos={115.00,120.00},size={21.00,15.00},title="0"
	CheckBox check_channelSel_DA_0,userdata(tabnum)=  "1"
	CheckBox check_channelSel_DA_0,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_DA_1,pos={115.00,141.00},size={21.00,15.00},title="1"
	CheckBox check_channelSel_DA_1,userdata(tabnum)=  "1"
	CheckBox check_channelSel_DA_1,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_DA_2,pos={115.00,162.00},size={21.00,15.00},title="2"
	CheckBox check_channelSel_DA_2,userdata(tabnum)=  "1"
	CheckBox check_channelSel_DA_2,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_DA_3,pos={115.00,183.00},size={21.00,15.00},title="3"
	CheckBox check_channelSel_DA_3,userdata(tabnum)=  "1"
	CheckBox check_channelSel_DA_3,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_DA_4,pos={115.00,204.00},size={21.00,15.00},title="4"
	CheckBox check_channelSel_DA_4,userdata(tabnum)=  "1"
	CheckBox check_channelSel_DA_4,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_DA_5,pos={115.00,225.00},size={21.00,15.00},title="5"
	CheckBox check_channelSel_DA_5,userdata(tabnum)=  "1"
	CheckBox check_channelSel_DA_5,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_DA_6,pos={115.00,246.00},size={21.00,15.00},title="6"
	CheckBox check_channelSel_DA_6,userdata(tabnum)=  "1"
	CheckBox check_channelSel_DA_6,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_DA_7,pos={115.00,267.00},size={21.00,15.00},title="7"
	CheckBox check_channelSel_DA_7,userdata(tabnum)=  "1"
	CheckBox check_channelSel_DA_7,userdata(tabcontrol)=  "Settings",value= 1
	GroupBox group_channelSel_HEADSTAGE,pos={43.00,104.00},size={44.00,199.00},title="HS"
	GroupBox group_channelSel_HEADSTAGE,userdata(tabnum)=  "1"
	GroupBox group_channelSel_HEADSTAGE,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_0,pos={53.00,120.00},size={21.00,15.00},title="0"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(tabnum)=  "1"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_HEADSTAGE_1,pos={53.00,141.00},size={21.00,15.00},title="1"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(tabnum)=  "1"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_HEADSTAGE_2,pos={53.00,162.00},size={21.00,15.00},title="2"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(tabnum)=  "1"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_HEADSTAGE_3,pos={53.00,183.00},size={21.00,15.00},title="3"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(tabnum)=  "1"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_HEADSTAGE_4,pos={53.00,204.00},size={21.00,15.00},title="4"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(tabnum)=  "1"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_HEADSTAGE_5,pos={53.00,225.00},size={21.00,15.00},title="5"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(tabnum)=  "1"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_HEADSTAGE_6,pos={53.00,246.00},size={21.00,15.00},title="6"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(tabnum)=  "1"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_HEADSTAGE_7,pos={53.00,267.00},size={21.00,15.00},title="7"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(tabnum)=  "1"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(tabcontrol)=  "Settings",value= 1
	GroupBox group_channelSel_AD,pos={166.00,104.00},size={45.00,360.00},title="AD"
	GroupBox group_channelSel_AD,userdata(tabnum)=  "1"
	GroupBox group_channelSel_AD,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_0,pos={174.00,120.00},size={21.00,15.00},title="0"
	CheckBox check_channelSel_AD_0,userdata(tabnum)=  "1"
	CheckBox check_channelSel_AD_0,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_1,pos={174.00,141.00},size={21.00,15.00},title="1"
	CheckBox check_channelSel_AD_1,userdata(tabnum)=  "1"
	CheckBox check_channelSel_AD_1,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_2,pos={174.00,162.00},size={21.00,15.00},title="2"
	CheckBox check_channelSel_AD_2,userdata(tabnum)=  "1"
	CheckBox check_channelSel_AD_2,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_3,pos={174.00,183.00},size={21.00,15.00},title="3"
	CheckBox check_channelSel_AD_3,userdata(tabnum)=  "1"
	CheckBox check_channelSel_AD_3,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_4,pos={174.00,204.00},size={21.00,15.00},title="4"
	CheckBox check_channelSel_AD_4,userdata(tabnum)=  "1"
	CheckBox check_channelSel_AD_4,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_5,pos={174.00,225.00},size={21.00,15.00},title="5"
	CheckBox check_channelSel_AD_5,userdata(tabnum)=  "1"
	CheckBox check_channelSel_AD_5,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_6,pos={174.00,246.00},size={21.00,15.00},title="6"
	CheckBox check_channelSel_AD_6,userdata(tabnum)=  "1"
	CheckBox check_channelSel_AD_6,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_7,pos={174.00,267.00},size={21.00,15.00},title="7"
	CheckBox check_channelSel_AD_7,userdata(tabnum)=  "1"
	CheckBox check_channelSel_AD_7,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_8,pos={174.00,289.00},size={21.00,15.00},title="8"
	CheckBox check_channelSel_AD_8,userdata(tabnum)=  "1"
	CheckBox check_channelSel_AD_8,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_9,pos={174.00,310.00},size={21.00,15.00},title="9"
	CheckBox check_channelSel_AD_9,userdata(tabnum)=  "1"
	CheckBox check_channelSel_AD_9,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_10,pos={174.00,331.00},size={27.00,15.00},title="10"
	CheckBox check_channelSel_AD_10,userdata(tabnum)=  "1"
	CheckBox check_channelSel_AD_10,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_11,pos={174.00,352.00},size={27.00,15.00},title="11"
	CheckBox check_channelSel_AD_11,userdata(tabnum)=  "1"
	CheckBox check_channelSel_AD_11,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_12,pos={174.00,373.00},size={27.00,15.00},title="12"
	CheckBox check_channelSel_AD_12,userdata(tabnum)=  "1"
	CheckBox check_channelSel_AD_12,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_13,pos={174.00,394.00},size={27.00,15.00},title="13"
	CheckBox check_channelSel_AD_13,userdata(tabnum)=  "1"
	CheckBox check_channelSel_AD_13,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_14,pos={174.00,415.00},size={27.00,15.00},title="14"
	CheckBox check_channelSel_AD_14,userdata(tabnum)=  "1"
	CheckBox check_channelSel_AD_14,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_channelSel_AD_15,pos={174.00,437.00},size={27.00,15.00},title="15"
	CheckBox check_channelSel_AD_15,userdata(tabnum)=  "1"
	CheckBox check_channelSel_AD_15,userdata(tabcontrol)=  "Settings",value= 1
	ListBox list_of_ranges1,pos={27.00,163.00},size={198.00,330.00},disable=1,proc=AR_MainListBoxProc
	ListBox list_of_ranges1,userdata(tabnum)=  "2",userdata(tabcontrol)=  "Settings"
	ListBox list_of_ranges1,mode= 1,selRow= 0,widths={54,50,66}
	Button button_RemoveRanges,pos={26.00,132.00},size={55.00,22.00},disable=1,proc=AR_ButtonProc_RemoveRanges,title="Remove"
	Button button_RemoveRanges,userdata(tabnum)=  "2"
	Button button_RemoveRanges,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_cutoff_length_after,pos={182.00,102.00},size={45.00,18.00},disable=1,proc=AR_SetVarProcCutoffLength
	SetVariable setvar_cutoff_length_after,help={"Time in ms which should be cutoff *after* the artefact."}
	SetVariable setvar_cutoff_length_after,userdata(tabnum)=  "2"
	SetVariable setvar_cutoff_length_after,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_cutoff_length_after,limits={0,inf,0.1},value= _NUM:0.2
	SetVariable setvar_cutoff_length_before,pos={28.00,102.00},size={150.00,18.00},disable=1,proc=AR_SetVarProcCutoffLength,title="Cutoff length [ms]:"
	SetVariable setvar_cutoff_length_before,help={"Time in ms which should be cutoff *before* the artefact."}
	SetVariable setvar_cutoff_length_before,userdata(tabnum)=  "2"
	SetVariable setvar_cutoff_length_before,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_cutoff_length_before,limits={0,inf,0.1},value= _NUM:0.1
	CheckBox check_auto_remove,pos={96.00,136.00},size={84.00,15.00},disable=1,proc=AR_CheckProc_Update,title="Auto remove"
	CheckBox check_auto_remove,help={"Automatically remove the found ranges on sweep plotting"}
	CheckBox check_auto_remove,userdata(tabnum)=  "2"
	CheckBox check_auto_remove,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_highlightRanges,pos={195.00,136.00},size={30.00,15.00},disable=1,proc=AR_CheckProc_Update,title="HL"
	CheckBox check_highlightRanges,help={"Visualize the found ranges in the graph (*might* slowdown graphing)"}
	CheckBox check_highlightRanges,userdata(tabnum)=  "2"
	CheckBox check_highlightRanges,userdata(tabcontrol)=  "Settings",value= 0
	SetVariable setvar_pulseAver_fallbackLength,pos={55.00,207.00},size={137.00,18.00},bodyWidth=50,disable=1,proc=PA_SetVarProc_Common,title="Fallback Length"
	SetVariable setvar_pulseAver_fallbackLength,help={"Pulse To Pulse Length in ms for edge cases which can not be computed."}
	SetVariable setvar_pulseAver_fallbackLength,userdata(tabnum)=  "3"
	SetVariable setvar_pulseAver_fallbackLength,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_fallbackLength,value= _NUM:100
	SetVariable setvar_pulseAver_endPulse,pos={70.00,184.00},size={122.00,18.00},bodyWidth=50,disable=1,proc=PA_SetVarProc_Common,title="Ending Pulse"
	SetVariable setvar_pulseAver_endPulse,userdata(tabnum)=  "3"
	SetVariable setvar_pulseAver_endPulse,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_endPulse,value= _NUM:inf
	SetVariable setvar_pulseAver_startPulse,pos={66.00,162.00},size={126.00,18.00},bodyWidth=50,disable=1,proc=PA_SetVarProc_Common,title="Starting Pulse"
	SetVariable setvar_pulseAver_startPulse,userdata(tabnum)=  "3"
	SetVariable setvar_pulseAver_startPulse,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_startPulse,value= _NUM:0
	CheckBox check_pulseAver_multGraphs,pos={60.00,142.00},size={120.00,15.00},disable=1,proc=PA_CheckProc_Common,title="Use multiple graphs"
	CheckBox check_pulseAver_multGraphs,help={"Show the single pulses in multiple graphs or only one graph with mutiple axis."}
	CheckBox check_pulseAver_multGraphs,userdata(tabnum)=  "3"
	CheckBox check_pulseAver_multGraphs,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_pulseAver_showAver,pos={60.00,121.00},size={117.00,15.00},disable=1,proc=PA_CheckProc_Common,title="Show average trace"
	CheckBox check_pulseAver_showAver,help={"Show the average trace"}
	CheckBox check_pulseAver_showAver,userdata(tabnum)=  "3"
	CheckBox check_pulseAver_showAver,userdata(tabcontrol)=  "Settings",value= 0
	CheckBox check_pulseAver_indTraces,pos={60.00,100.00},size={133.00,15.00},disable=1,proc=PA_CheckProc_Common,title="Show individual traces"
	CheckBox check_pulseAver_indTraces,help={"Show the individual traces"}
	CheckBox check_pulseAver_indTraces,userdata(tabnum)=  "3"
	CheckBox check_pulseAver_indTraces,userdata(tabcontrol)=  "Settings",value= 1
	CheckBox check_BrowserSettings_OVS,pos={100.00,50.00},size={97.00,15.00},disable=1,title="enable"
	CheckBox check_BrowserSettings_OVS,value= 0
	CheckBox check_BrowserSettings_OVS,help={"Adds unplotted sweep to graph. Removes plotted sweep from graph."}
	CheckBox check_BrowserSettings_OVS,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_OVS,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_AR,pos={100.00,50.00},size={106.00,15.00},disable=1,proc=BSP_CheckBoxProc_ArtRemoval,title="enable"
	CheckBox check_BrowserSettings_AR,value= 0
	CheckBox check_BrowserSettings_AR,help={"Open the artefact removal dialog"}
	CheckBox check_BrowserSettings_AR,userdata(tabnum)=  "2"
	CheckBox check_BrowserSettings_AR,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_PA,pos={100.00,50.00},size={100.00,15.00},disable=1,proc=BSP_CheckBoxProc_PerPulseAver,title="enable"
	CheckBox check_BrowserSettings_PA,value= 0
	CheckBox check_BrowserSettings_PA,help={"Allows to average multiple pulses from pulse train epochs"}
	CheckBox check_BrowserSettings_PA,userdata(tabnum)=  "3"
	CheckBox check_BrowserSettings_PA,userdata(tabcontrol)=  "Settings"
EndMacro

/// @brief enable/disable checkbox control for side panel
Function BSP_CheckBoxProc_ArtRemoval(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string mainPanel, extPanel
	string controlList = "group_properties_artefact;setvar_cutoff_length_before;setvar_cutoff_length_after;button_RemoveRanges;check_auto_remove;check_highlightRanges;list_of_ranges1;"

	switch(cba.eventCode)
		case 2: // mouse up
			mainPanel = GetMainWindow(cba.win)
			extPanel = BSP_GetPanel(mainPanel)

			ASSERT(windowExists(extPanel), "BrowserSettingsPanel does not exist.")

			if(cba.checked && BSP_HasBoundDevice(mainPanel))
				EnableControls(extPanel, controlList)
			else
				DisableControls(extPanel, controlList)
			endif

			UpdateSweepPlot(mainPanel)
			break
	endswitch

	return 0
End

/// @brief enable/disable checkbox control for side panel
Function BSP_CheckBoxProc_PerPulseAver(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string mainPanel, extPanel
	string controlList = "group_properties_pulse;check_pulseAver_indTraces;check_pulseAver_showAver;check_pulseAver_multGraphs;setvar_pulseAver_startPulse;setvar_pulseAver_endPulse;setvar_pulseAver_fallbackLength;"

	switch(cba.eventCode)
		case 2: // mouse up
			mainPanel = GetMainWindow(cba.win)
			extPanel = BSP_GetPanel(mainPanel)

			ASSERT(windowExists(extPanel), "BrowserSettingsPanel does not exist.")

			if(cba.checked && BSP_HasBoundDevice(mainPanel))
				EnableControls(extPanel, controlList)
			else
				DisableControls(extPanel, controlList)
			endif

			UpdateSweepPlot(mainPanel)
			break
	endswitch

	return 0
End

/// @brief check the DataBrowser or SweepBrowser panel if it has the required version
///
/// @param panelName 		name of external panel or main window
/// @return 0 if panel has latest version and 1 if update is required
static Function BSP_MainPanelNeedsUpdate(panelName)
	string panelName

	variable panelVersion, version

	panelName = GetMainWindow(panelName)
	panelVersion = GetPanelVersion(panelName)
	if(IsDataBrowser(panelName))
		version = DATABROWSER_PANEL_VERSION
	else
		version = SWEEPBROWSER_PANEL_VERSION
	endif

	return panelVersion < version
End

/// @brief check the BrowserSettings Panel if it has the required version
///
/// @param panelName 		name of external panel or main window
/// @return 0 if panel has latest version and 1 if update is required
static Function BSP_PanelNeedsUpdate(panelName)
	string panelName

	string extPanel
	variable version

	extPanel = BSP_GetPanel(panelName)
	if(!WindowExists(extPanel))
		return 0
	endif

	version = GetPanelVersion(extPanel)
	return version < BROWSERSETTINGS_PANEL_VERSION
End

/// @brief check if the specified setting is activated
///
/// @param panelName 	name of external panel or main window
/// @param elementID 	one of BROWSERSETTINGS_* constants
/// @return 1 if setting was activated, 0 otherwise
Function BSP_IsActive(panelName, elementID)
	string panelName
	variable elementID

	string extPanel, control

	extPanel = BSP_GetPanel(panelName)
	if(!WindowExists(extPanel))
		return 0
	endif

	// return inactive if panel is outdated
	if(BSP_MainPanelNeedsUpdate(panelName) || BSP_PanelNeedsUpdate(panelName))
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

	return GetCheckboxState(extPanel, control) == CHECKBOX_SELECTED
End
