#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_MENU
#endif

/// @file MIES_Menu.ipf
/// @brief Definition of the menu items

Menu "Mies Panels"
	"Generate stimulus sets (WB)/2"            , /Q, WBP_CreateWaveBuilderPanel()
	"Acquire data (DA_Ephys)/3"                , /Q, DAP_CreateDAEphysPanel()
	"Browse data (DB)/4"                       , /Q, DB_OpenDataBrowser()
	"-"
	SubMenu "Analysis"
		"Analysis Browser"                     , /Q, AB_OpenAnalysisBrowser()
		"Labnotebook Browser"                  , /Q, LBN_OpenLabnotebookBrowser()
		"TPStorage Browser"                    , /Q, LBN_OpenTPStorageBrowser()
		"Open Downsample Panel"                , /Q, CreateDownsamplePanel()
	End
	"-"
	SubMenu "Automation"
		"Configure MIES/1"                     , /Q, ExpConfig_ConfigureMIES()
		"Blowout/8"                            , /Q, BWO_SelectDevice()
		"Save and Clear Experiment"            , /Q, SaveExperimentSpecial(SAVE_AND_CLEAR)
		"Close Mies"                           , /Q, CloseMies()
		"IVSCC control panel"                  , /Q, IVS_CreatePanel()
	End
	"-"
	SubMenu "Neurodata Without Borders (NWB)"
		"Export all data into NWB"             , /Q, NWB_ExportWithDialog(NWB_EXPORT_DATA)
		"Export all stimsets into NWB"         , /Q, NWB_ExportWithDialog(NWB_EXPORT_STIMSETS)
		"Load Stimsets from NWB"               , /Q, NWB_LoadAllStimsets()
		"-"
	End
	"-"
	"About MIES"                               , /Q, OpenAboutDialog()
	"-"
	SubMenu "Advanced"
		"Restart ZeroMQ Message Handler"           , /Q, StartZeroMQMessageHandler()
		"Turn off ASLR (requires UAC elevation)"   , /Q, TurnOffASLR()
		"Open debug panel"                         , /Q, DP_OpenDebugPanel()
		"Check Installation"                       , /Q, CHI_CheckInstallation()
		"Start Background Task watcher panel"      , /Q, BkgWatcher#BW_StartPanel()
		"Enable Independent Module editing"        , /Q, SetIgorOption IndependentModuleDev=1
		"Reset and store current DA_EPHYS panel"   , /Q, DAP_EphysPanelStartUpSettings()
		"Reset and store current DataBrowser panel", /Q, DB_ResetAndStoreCurrentDBPanel()
		"Check GUI control procedures of top panel", /Q, SearchForInvalidControlProcs(GetCurrentWindow())
		"Flush Cache"                              , /Q, CA_FlushCache()
		"Output Cache statistics"                  , /Q, CA_OutputCacheStatistics()
	End
End

Function CloseMies()

	DAP_UnlockAllDevices()

	string windowToClose
	string activeWindows = WinList("*", ";", "WIN:64")
	Variable index
	Variable noOfActiveWindows = ItemsInList(activeWindows)

	for (index = 0; index < noOfActiveWindows;index += 1)
		windowToClose = StringFromList(index, activeWindows)
		if(StringMatch(windowToClose, "waveBuilder*")          \
		   || StringMatch(windowToClose, "dataBrowser*")       \
		   || StringMatch(windowToClose, "DB_ITC*")            \
		   || StringMatch(windowToClose, "DA_Ephys*")          \
		   || StringMatch(windowToClose, "configureAnalysis*"))
			KillWindow $windowToClose
		endif
	endfor
End

Function OpenAboutDialog()

	string panel = "AboutMIES"

	DoWindow/F $panel
	if(V_flag)
		return NaN
	endif

	Execute panel + "()"
	SVAR miesVersion = $GetMiesVersion()
	Notebook AboutMIES#MiesVersionNB selection={startOfFile, endOfFile}
	Notebook AboutMIES#MiesVersionNB setData=miesVersion
End

Window AboutMies() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(348,491,982,661) as "About MIES"
	Button button_okay,pos={246.00,136.00},size={50.00,20.00},proc=ButtonProc_AboutMIESClose,title="OK"
	Button button_copy_to_clipboard,pos={328.00,136.00},size={50.00,20.00},proc=ButtonProc_AboutMIESCopy,title="Copy"
	NewNotebook /F=0 /N=MiesVersionNB /W=(14,7,309,124)/FG=(FL,FT,FR,$"") /HOST=# /OPTS=15
	Notebook kwTopWin, defaultTab=20, autoSave= 0, writeProtect=1
	Notebook kwTopWin font="Lucida Console", fSize=11, fStyle=0, textRGB=(0,0,0)
	RenameWindow #,MiesVersionNB
	SetActiveSubwindow ##
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


	switch(ba.eventCode)
		case 2: // mouse up
			SVAR miesVersion = $GetMiesVersion()
			PutScrapText miesVersion
			break
	endswitch

	return 0
End
