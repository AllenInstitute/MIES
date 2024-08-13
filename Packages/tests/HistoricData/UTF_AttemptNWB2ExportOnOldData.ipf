#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=ExportToNWB

/// UTF_TD_GENERATOR GetHistoricDataFilesPXP
static Function TestExportingDataToNWB([string str])

	string nwbFileName
	variable nwbVersion = GetNWBVersion()

	LoadMIESFolderFromPXP("input:" + str)

	PathInfo home
	nwbFileName = S_path + GetBaseName(str) + ".nwb"
	// attempt export
	NWB_ExportAllData(nwbVersion, overrideFilePath = nwbFileName, writeStoredTestPulses = 1, writeIgorHistory = 1)

	CHECK_NO_RTE()
	CHECK_EQUAL_VAR(FileExists(nwbFileName), 1)
End
