#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

/// @file MIES_Menu.ipf
/// @brief Definition of the menu items

static StrConstant OPTIONAL_TANGO_INCLUDE = "MIES_TangoInteract"

Menu "Mies Panels", dynamic
	"DA_Ephys"                      , /Q, DAP_CreateDAEphysPanel()
	"WaveBuilder"                   , /Q, WBP_CreateWaveBuilderPanel()
	"Data Browser"                  , /Q, DB_OpenDataBrowser()
	"Analysis Browser"              , /Q, AB_OpenAnalysisBrowser()
	"Labnotebook Browser"           , /Q, LBN_OpenLabnotebookBrowser()
	"TPStorage Browser"             , /Q, LBN_OpenTPStorageBrowser()
	"Restart ZeroMQ Message Handler", /Q, StartZeroMQMessageHandler()
	"Save and Clear Experiment"     , /Q, SaveExperimentSpecial(SAVE_AND_CLEAR)
	"Close Mies"                    , /Q, CloseMies()
	"Open Downsample Panel"         , /Q, CreateDownsamplePanel()
	"Open AnalysisMaster Panel"     , /Q, analysisMaster()
	"Export all data into NWB"      , /Q, NWB_ExportWithDialog()
	"-"
	GetOptTangoIncludeMenuTitle(), /Q, HandleTangoOptionalInclude()
	"-"
	"About MIES"                 , /Q, OpenAboutDialog()
	"-"
	SubMenu "Advanced"
		"Open debug panel"                          , /Q, DP_OpenDebugPanel()
		"Check Installation"                        , /Q, CHI_CheckInstallation()
		"Start Background Task watcher panel"       , /Q, BkgWatcher#BW_StartPanel()
		"Allow to edit files in Independent Modules", /Q, SetIgorOption IndependentModuleDev=1
		"Reset and store current DA_EPHYS panel"    , /Q, DAP_EphysPanelStartUpSettings()
		"Check GUI control procedures of top panel" , /Q, SearchForInvalidControlProcs(GetCurrentWindow())
		"Flush Cache"                               , /Q, CA_FlushCache()
	End
End

Menu "HDF5 Tools"
	"-"
	"Open HDF5 Browser"        , /Q, IPNWB#CreateNewHDF5Browser()
	"Save HDF5 File"           , /Q, HD_Convert_To_HDF5("menuSaveFile.h5")
	"Save Stim Set"            , /Q, HD_SaveStimSet()
	"Load and Replace Stim Set", /Q, HD_LoadReplaceStimSet()
	"Load Additional Stim Set" , /Q, HD_LoadAdditionalStimSet()
	"Save Sweep Data"          , /Q, HD_SaveSweepData()
	"Save Configuration"       , /Q, HD_SaveConfiguration()
	"Load Configuration"       , /Q, HD_LoadConfigSet()
	"Load Sweep Data"          , /Q, HD_LoadDataSet()
End

///@returns 1 if the optional include is loaded, 0 otherwise
static Function OptTangoIncludeLoaded()

	string procList = WinList(OPTIONAL_TANGO_INCLUDE + ".ipf",";","")

	return !isEmpty(procList)
End

///@brief Returns the title of the tango load/unload menu entry
Function/S GetOptTangoIncludeMenuTitle()

	if(OptTangoIncludeLoaded())
		return "Unload Tango Tools"
	else
		return "Load Tango Tools"
	endif
End

///@brief Load/Unload the optional tango include
Function HandleTangoOptionalInclude()

	if(!OptTangoIncludeLoaded())
		Execute/P/Q/Z "INSERTINCLUDE \"" + OPTIONAL_TANGO_INCLUDE + "\""
	else
		Execute/P/Q/Z "DELETEINCLUDE \"" + OPTIONAL_TANGO_INCLUDE + "\""
	endif

	Execute/P/Q/Z "COMPILEPROCEDURES "
End

Function CloseMies()

	DAP_UnlockAllDevices()

	string windowToClose
	string activeWindows = WinList("*", ";", "WIN:64")
	Variable index
	Variable noOfActiveWindows = ItemsInList(activeWindows)

	print "Closing Mies windows..."

	for (index = 0; index < noOfActiveWindows;index += 1)
		windowToClose = StringFromList(index, activeWindows)
		if(StringMatch(windowToClose, "waveBuilder*")          \
		   || StringMatch(windowToClose, "dataBrowser*")       \
		   || StringMatch(windowToClose, "DB_ITC*")            \
		   || StringMatch(windowToClose, "DA_Ephys*")          \
		   || StringMatch(windowToClose, "configureAnalysis*") \
		   || StringMatch(windowToClose, "analysisMaster*"))
			KillWindow $windowToClose
		endif
	endfor

	print "Exiting Mies..."
End

Function OpenAboutDialog()

	string panel = "AboutMIES"

	DoWindow/F $panel
	if(V_flag)
		return NaN
	endif

	Execute panel + "()"
	SVAR miesVersion = $GetMiesVersion()
	SetSetVariableString(panel, "setvar_info", "MIES Version: " + miesVersion)
End

Window AboutMies() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(348,491,612,592) as "About MIES"
	Button button_okay,pos={99.00,71.00},size={50.00,20.00},proc=ButtonProc_AboutMIESClose,title="OK"
	SetVariable setvar_info,pos={18.00,20.00},size={213.00,15.00}
	Button button_copy_to_clipboard,pos={181.00,71.00},size={50.00,20.00},proc=ButtonProc_AboutMIESCopy,title="Copy"
EndMacro

Function ButtonProc_AboutMIESClose(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			KillWindow $ba.win
			break
	endswitch

	return 0
End

Function ButtonProc_AboutMIESCopy(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string str

	switch(ba.eventCode)
		case 2: // mouse up
			str = GetSetVariableString(ba.win, "setvar_info")
			PutScrapText str
			break
	endswitch

	return 0
End
