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

	CloseNWBFile()
	HDF5CloseFile/A/Z 0

	KillOrMoveToTrash(dfr=root:MIES)

	NewDataFolder root:MIES
	MoveDataFolder root:$name, root:MIES

	// currently superfluous as we remove root:MIES above
	// but might be needed in the future and helps in understanding the code
	CA_FlushCache()

	NVAR interactiveMode = $GetInteractiveMode()
	interactiveMode = 0

	NVAR bugCount = $GetBugCount()
	KillVariables bugCount
End

Function WaitForPubSubHeartbeat()
	variable i, foundHeart
	string msg, filter

	// wait until we get the first heartbeat
	for(i = 0; i < 200; i += 1)
		msg = zeromq_sub_recv(filter)
		if(!cmpstr(filter, ZEROMQ_HEARTBEAT))
			PASS()
			return NaN
		endif

		Sleep/S 0.1
	endfor

	FAIL()
End

Function AdjustAnalysisParamsForPSQ(string device, string stimset)

	variable samplingFrequency

	switch(GetHardwareType(device))
		case HARDWARE_ITC_DAC:
			samplingFrequency = 50
			break
		case HARDWARE_NI_DAC:
			samplingFrequency = 125
			break
		default:
			ASSERT(0, "Unknown hardware")
	endswitch

	AFH_AddAnalysisParameter(stimset, "SamplingMultiplier", var = 4)
	AFH_AddAnalysisParameter(stimset, "SamplingFrequency", var = samplingFrequency)
End

Function DoInstrumentation()
#if IgorVersion() >= 9.0
	variable instru = str2numSafe(GetEnvironmentVariable("BAMBOO_INSTRUMENT_TESTS")) == 1           \
	                  || !cmpstr(GetEnvironmentVariable("bamboo_repository_git_branch"), "main")

	return instru
#else
	// no support in IP8
	return 0
#endif
End
