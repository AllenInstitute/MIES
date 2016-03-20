#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_Menu.ipf
/// @brief Definition of the menu items

static StrConstant optionalTangoInclude = "MIES_TangoInteract"
static StrConstant optionalHDF5Include = "MIES_HDF5Ops"

Menu "Mies Panels", dynamic
		"DA_Ephys"                   , /Q, DAP_CreateDAEphysPanel()
		"WaveBuilder"                , /Q, WBP_CreateWaveBuilderPanel()
		"Data Browser"               , /Q, DB_OpenDataBrowser()
		"Save and Clear Experiment"  , /Q, SaveExperimentSpecial(SAVE_AND_CLEAR)
		"Close Mies"                 , /Q, CloseMies()
		"Open Downsample Panel"      , /Q, CreateDownsamplePanel()
		"Open AnalysisMaster Panel"  , /Q, analysisMaster()
		"Export all data into NWB"   , /Q, NWB_ExportAllData()
		"-"
		GetOptTangoIncludeMenuTitle(), /Q, HandleTangoOptionalInclude()
		"-"
		"About MIES"                 , /Q, OpenAboutDialog()
		"-"
	SubMenu "Advanced"
		"Enable debug mode", /Q, EnableDebugMode()
		"Disable debug mode", /Q, DisableDebugMode()
		"Check Installation", /q, CHI_CheckInstallation()
		"Start Background Task watcher panel", /Q, BkgWatcher#BW_StartPanel()
		"Allow to edit files in Independent Modules", /Q, SetIgorOption IndependentModuleDev=1
	End
End

Menu "HDF5 Tools", dynamic
	GetOptHDF5IncludeMenuTitle(), /Q, HandleHDF5OptionalInclude()	
End

///@returns 1 if the optional include is loaded, 0 otherwise
static Function OptTangoIncludeLoaded()

	string procList = WinList(optionalTangoInclude + ".ipf",";","")

	return !isEmpty(procList)
End

///@returns 1 if the optional include is loaded, 0 otherwise
static Function OptHDF5IncludeLoaded()

	string procList = WinList(optionalHDF5Include + ".ipf",";","")

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

///@brief Returns the title of the HDF5 load/unload menu entry
Function/S GetOptHDF5IncludeMenuTitle()

	if(OptHDF5IncludeLoaded())
		return "Unload HDF5 Tools"
	else
		return "Load HDF5 Tools"
	endif
End

///@brief Load/Unload the optional tango include
Function HandleTangoOptionalInclude()

	if(!OptTangoIncludeLoaded())
		Execute/P/Q/Z "INSERTINCLUDE \"" + optionalTangoInclude + "\""
	else
		Execute/P/Q/Z "DELETEINCLUDE \"" + optionalTangoInclude + "\""
	endif

	Execute/P/Q/Z "COMPILEPROCEDURES "
End

///@brief Load/Unload the optional hdf5 include
Function HandleHDF5OptionalInclude()

	if(!OptHDF5IncludeLoaded())
		Execute/P/Q/Z "INSERTINCLUDE \"" + optionalHDF5Include + "\""
	else
		Execute/P/Q/Z "DELETEINCLUDE \"" + optionalHDF5Include + "\""
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
		if ( StringMatch(windowToClose, "waveBuilder*") || StringMatch(windowToClose, "dataBrowser*") || StringMatch(windowToClose, "DB_ITC*") || StringMatch(windowToClose, "DA_Ephys*") || StringMatch(windowToClose, "configureAnalysis*") || StringMatch(windowToClose, "analysisMaster*") )
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
