#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=ExportToNWB

/// UTF_TD_GENERATOR GetHistoricDataFiles
static Function TestExportingDataToNWB([string str])

	string file, miesPath, nwbFileName
	variable numObjectsLoaded
	variable nwbVersion = GetNWBVersion()

	file = "input:" + str
	PathInfo home
	nwbFileName = S_path + GetBaseName(str) + ".nwb"

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

	// attempt export
	NWB_ExportAllData(nwbVersion, overrideFilePath = nwbFileName, writeStoredTestPulses = 1, writeIgorHistory = 1)

	CHECK_NO_RTE()
	CHECK_EQUAL_VAR(FileExists(nwbFileName), 1)
End
