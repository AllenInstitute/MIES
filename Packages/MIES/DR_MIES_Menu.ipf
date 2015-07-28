#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file DR_MIES_Menu.ipf
/// @brief Definition of the menu items

static StrConstant optionalTangoInclude = "DR_MIES_TangoInteract"
static StrConstant optionalHDF5Include = "DR_MIES_HDF5Ops"

Menu "Mies Panels", dynamic
		"DA_Ephys"                   , /Q, Execute "DA_Ephys()"
		"WaveBuilder"                , /Q, WBP_CreateWaveBuilderPanel()
		"Data Browser"               , /Q, Execute "DataBrowser()"
		"Save and Clear Experiment"  , /Q, SaveExperimentSpecial(SAVE_AND_CLEAR)
		"Close Mies"                 , /Q, CloseMies()
		"Open Downsample Panel"      , /Q, CreateDownsamplePanel()
		"Open AnalysisMaster Panel", /Q, analysisMaster()
		"-"
		GetOptTangoIncludeMenuTitle(), /Q, HandleTangoOptionalInclude()
		"-"
	SubMenu "Advanced"
		"Enable debug mode", /Q, EnableDebugMode()
		"Disable debug mode", /Q, DisableDebugMode()
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
