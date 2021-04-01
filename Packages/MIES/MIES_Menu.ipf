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
		"Load Standard Configuration/1"        , /Q, CONF_AutoLoader()
		"Load Window Configuration"            , /Q, CONF_RestoreWindow("", usePanelTypeFromFile = 1)
		"Save Window Configuration"            , /Q, CONF_SaveWindow("")
		"Open Configuration Files"             , /Q, CONF_OpenConfigInNotebook()
		"Blowout/8"                            , /Q, BWO_SelectDevice()
		"Save and Clear Experiment"            , /Q, SaveExperimentSpecial(SAVE_AND_CLEAR)
		"Close Mies"                           , /Q, CloseMies()
		"IVSCC control panel"                  , /Q, IVS_CreatePanel()
	End
	"-"
	SubMenu "Neurodata Without Borders (NWB)"
		"Export all data into NWB"             , /Q, NWB_ExportWithDialog(NWB_EXPORT_DATA)
		"-"
		"Export all data into NWBv1 (legacy)"  , /Q, NWB_ExportWithDialog(NWB_EXPORT_DATA, nwbVersion = 1)
		"-"
		"Export all stimsets into NWB"         , /Q, NWB_ExportWithDialog(NWB_EXPORT_STIMSETS)
		"Load Stimsets from NWB"               , /Q, NWB_LoadAllStimsets()
	End
	"-"
	"Report an issue"                          , /Q, CreateIssueOnGithub()
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
		"Show Diagnostics (crash dumps) directory" , /Q, ShowDiagnosticsDirectory()
		"Upload crash dumps"                       , /Q, UploadCrashDumps()
		"Clear package settings"                   , /Q, ClearPackageSettings()
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

	string version, nb
	variable sfactor
	string panel = "AboutMIES"

	DoWindow/F $panel
	if(V_flag)
		return NaN
	endif

	sfactor = ScreenResolution/96
	NewPanel/N=$panel/K=1/W=(332 / sfactor, 252 / sfactor,928 / sfactor, 724 / sfactor) as "About MIES"

	nb = "MiesVersionNB"
	NewNotebook /F=1 /N=MiesVersionNB/FG=(FL,FT,FR,FB)/HOST=#/OPTS=3
	nb = panel + "#" + nb

	Notebook $nb defaultTab=36, magnification=100
	Notebook $nb showRuler=0, rulerUnits=2, updating={1, 1},writeProtect=1
	Notebook $nb newRuler=Normal, justification=0, margins={0,0,468}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",11,0,(0,0,0)}
	Notebook $nb ruler=Normal, text="MIES is a sweep based data acquisition tool written in Igor Pro.\r"
	Notebook $nb text="\r"

	version = ROStr(GetMiesVersion())
	version = StringFromList(0, version, "\r")
	version = RemovePrefix(version, startStr = "Release_")
	Notebook $nb text="Version: " + version  + "\r"
	Notebook $nb text="\r"
	NotebookAction/W=$nb name=Action1, title="Report an Issue/Enhancement proposal", ignoreErrors=1
	NotebookAction/W=$nb name=Action1, commands="CreateIssueOnGithub()"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="Location: "
	NotebookAction/W=$nb name=Action2, title="github.com/AllenInstitute/MIES", ignoreErrors=1
	NotebookAction/W=$nb name=Action2, commands="BrowseURL(\"https://github.com/AllenInstitute/MIES\")"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="License: "
	NotebookAction/W=$nb name=Action0, title="2-clause BSD license plus a third clause", ignoreErrors=1
	NotebookAction/W=$nb name=Action0, commands="BrowseURL(\"https://github.com/AllenInstitute/MIES/blob/main/LICENSE\")"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="Sponsors: "
	NotebookAction/W=$nb name=Action3, title="www.alleninstitute.org", ignoreErrors=1
	NotebookAction/W=$nb name=Action3, commands="BrowseURL(\"https://www.alleninstitute.org\")"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="Data products:"
	Notebook $nb text="\r"
	NotebookAction/W=$nb name=Action5, title="", showmode=3, linkStyle=0, scaling={40.0 * sfactor, 40.0 * sfactor}, procPICTName=SynPhys, ignoreErrors=1, padding={0,0,0,0,5}, commands="BrowseURL(\"https://portal.brain-map.org/explore/connectivity/synaptic-physiology\")"
	NotebookAction/W=$nb name=Action6, title="", showmode=3, linkStyle=0, scaling={40.0 * sfactor, 40.0 * sfactor}, procPICTName=CellTypes, ignoreErrors=1, padding={0,0,0,0,0}, commands="BrowseURL(\"http://celltypes.brain-map.org/\")"
	SetActiveSubwindow ##
End

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

/// @brief Custom notebook action for the "About MIES" dialog
///
/// Opens a prefilled new issue on github.
Function CreateIssueOnGithub()
	string url, body, title, version, str
	variable ref

	title = "Please summarize your issue here"
	body = ""

	version = ROStr(GetMiesVersion())

	body += "Description:\n"
	body += "- What was MIES doing at the time of the unexpected behavior?\n\n"
	body += "- Did user input immediately precede the unexpected behavior?\n\n"
	body += "- What did you expect to happen?\n\n"
	body += "\n"
	body += "Igor Pro Experiment files can be attached as zip file if needed.\n"
	body += "\n"
	body += "The following contains installation information (keep unchanged):\n"

	sprintf str, "```\nMIES version: %s\n```\n\n", version
	body += str

	sprintf str, "```\nIgor Pro version: %s\n```\n\n", IgorInfo(3)
	body += str

	body += "```\nInstallation self-test results:\n"

	ref = CaptureHistoryStart()
	CHI_CheckInstallation()
	str = CaptureHistory(ref, 1)

	body += str
	body +=  "```\n\n"

	sprintf url, "https://github.com/AllenInstitute/MIES/issues/new?title=%s&body=%s", URLEncode(title), URLEncode(body)

	BrowseURL(url)
End

Function ClearPackageSettings()
	NVAR JSONid = $GetSettingsJSONid()
	JSON_Release(JSONId)

	JSONid = GenerateSettingsDefaults()
	PS_WriteSettings("MIES", JSONid)
End
