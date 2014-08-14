#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static StrConstant optionalInclude = "DR_MIES_TangoInteract"

Menu "Mies Panels", dynamic
		"DA_Ephys", execute "DA_Ephys()"
		"WaveBuilder", WB_InitiateWaveBuilder()
		"Data Browser", execute "DataBrowser()"
		"Initiate Mies", IM_InitiateMies()		
		"Close Mies", CloseMies()
		"Open Downsample Panel", CreateDownsamplePanel()
		"-"
		GetOptionalIncludeMenuTitle(), HandleOptionalInclude()
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
		
	string activeWindows = winlist("*", ";", "WIN:64")
	Variable index
	Variable noOfActiveWindows = itemsinlist(activeWindows)

	print "Closing Mies windows..."
	for (index = 0; index < noOfActiveWindows;index += 1)
		string windowToClose = stringfromlist(index, activeWindows)
		if (stringmatch(windowToClose, "waveBuilder") == 1)
			KillWindow waveBuilder
		elseif (stringmatch(windowToClose, "dataBrowser") == 1)
			KillWindow dataBrowser
		elseif(stringmatch(windowToClose, "DB_ITC*") == 1)		// The data browser window title changes to display wave data
			KillWindow $windowToClose
		elseif (stringmatch(windowToClose, "DA_Ephys") == 1)
			KillWindow DA_Ephys
		elseif (stringmatch(windowToClose, "ITC*") == 1)
			HSU_UnlockDevice(windowToClose)
			// unlocking the device changes the window title back to DA_Ephys
			KillWindow DA_Ephys
		endif
	endfor
	
	print "Exiting Mies..."
End
