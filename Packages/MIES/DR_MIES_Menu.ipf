#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static StrConstant optionalInclude = "DR_MIES_TangoInteract"

Menu "Mies Panels", dynamic
		"DA_Ephys"                   , /Q, Execute "DA_Ephys()"
		"WaveBuilder"                , /Q, WBP_CreateWaveBuilderPanel()
		"Data Browser"               , /Q, Execute "DataBrowser()"
		"Initiate Mies"              , /Q, IM_InitiateMies()
		"Close Mies"                 , /Q, CloseMies()
		"Open Downsample Panel"      , /Q, CreateDownsamplePanel()
		"-"
		GetOptionalIncludeMenuTitle(), /Q, HandleOptionalInclude()
End

///@returns 1 if the optional include is loaded, 0 otherwise
static Function OptionalIncludeLoaded()

	string procList = WinList(optionalInclude + ".ipf",";","")

	return !isEmpty(procList)
End

///@brief Returns the title of the load/unload menu entry
Function/S GetOptionalIncludeMenuTitle()

	if(OptionalIncludeLoaded())
		return "Unload Tango\HDF5 tools"
	else
		return "Load Tango\HDF5 tools"
	endif
End

///@brief Load/Unload the optional include
Function HandleOptionalInclude()

	if(!OptionalIncludeLoaded())
		Execute/P/Q/Z "INSERTINCLUDE \"" + optionalInclude + "\""
	else
		Execute/P/Q/Z "DELETEINCLUDE \"" + optionalInclude + "\""
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
		if ( StringMatch(windowToClose, "waveBuilder*") || StringMatch(windowToClose, "dataBrowser*") || StringMatch(windowToClose, "DB_ITC*") || StringMatch(windowToClose, "DA_Ephys*") )
			KillWindow $windowToClose
		endif
	endfor

	print "Exiting Mies..."
End
