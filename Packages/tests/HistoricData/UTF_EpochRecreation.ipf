#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=EpochRecreation

/// UTF_TD_GENERATOR GetHistoricDataFiles
static Function TestEpochRecreation([string str])

	string file, miesPath, win, device
	variable numObjectsLoaded, first, last, i

	file = "input:" + str
	PathInfo home

	DFREF dfr = GetMIESPath()
	KillDataFolder dfr

	miesPath = GetMiesPathAsString()

	DFREF dfr     = NewFreeDataFolder()
	DFREF savedDF = GetDataFolderDFR()
	SetDataFolder dfr
	LoadData/Q/R/P=home/S=miesPath file
	numObjectsLoaded = V_flag
	SetDataFolder savedDF
	MoveDataFolder dfr, root:
	RenameDataFolder root:$DF_NAME_FREE, $DF_NAME_MIES

	// sanity check if the test setup is ok
	CHECK_NO_RTE()
	CHECK_GT_VAR(numObjectsLoaded, 0)

	// This is a workaround because LoadData DOES NOT LOAD WaveRef WAVES
	// The Cache values are in the pxp present but not loaded as they are of type /WAVE
	// PLEASE CHECK THIS, IF THIS TEST FAILS IN FUTURE HISTORIC DATA TESTS
	CA_FlushCache()

	win    = DB_OpenDataBrowser()
	device = BSP_GetDevice(win)
	[first, last] = BSP_FirstAndLastSweepAcquired(win)
	CHECK_GE_VAR(last, first)

	WAVE numericalValues = DB_GetLBNWave(win, LBN_NUMERICAL_VALUES)
	WAVE textualValues   = DB_GetLBNWave(win, LBN_TEXTUAL_VALUES)
	for(i = first; i < last; i += 1)
		SplitAndUpgradeSweepGlobal(device, i)
		DFREF  sweepDFR = BSP_GetSweepDF(win, i)
		WAVE/Z epochs   = MIES_EP#EP_RecreateEpochsFromLoadedData(numericalValues, textualValues, sweepDFR, i)
		CHECK_NO_RTE()
		CHECK_WAVE(epochs, TEXT_WAVE)
	endfor
End
