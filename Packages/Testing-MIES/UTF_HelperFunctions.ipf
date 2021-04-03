#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=TestHelperFunctions

/// @file UTF_HelperFunctions.ipf
/// @brief This file holds helper functions for the tests

Function/S PrependExperimentFolder_IGNORE(filename)
	string filename

	PathInfo home
	CHECK(V_flag)

	return S_path + filename
End

/// Kill all left-over windows and remove the trash
Function AdditionalExperimentCleanup()

	string win, list, name
	variable i, numWindows

	list = WinList("*", ";", "WIN:67") // Panels, Graphs and tables

	numWindows = ItemsInList(list)
	for(i = 0; i < numWindows; i += 1)
		win = StringFromList(i, list)

		if(!cmpstr(win, "BW_MiesBackgroundWatchPanel") || !cmpstr(win, "DP_DebugPanel"))
			continue
		endif

		KillWindow $win
	endfor

	DFREF dfr = GetDebugPanelFolder()
	name = GetDataFolder(0, dfr)
	MoveDataFolder/O=1 dfr, root:

	KillOrMoveToTrash(dfr=root:MIES)

	NewDataFolder root:MIES
	MoveDataFolder root:$name, root:MIES

	// currently superfluous as we remove root:MIES above
	// but might be needed in the future and helps in understanding the code
	CA_FlushCache()
End
