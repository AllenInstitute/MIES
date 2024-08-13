#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=ExportToNWB

/// UTF_TD_GENERATOR GetHistoricDataFilesPXP
static Function TestExportingDataToNWB([string str])

	string templateName, nwbFileName, device
	variable nwbVersion = GetNWBVersion()

	LoadMIESFolderFromPXP("input:" + str)

	PathInfo home
	templateName = S_path + GetBaseName(str)
	// attempt export
	NWB_ExportAllData(nwbVersion, overrideFileTemplate = templateName, writeStoredTestPulses = 1, writeIgorHistory = 1)

	CHECK_NO_RTE()

	WAVE/T devicesWithContent = ListToTextWave(GetAllDevicesWithContent(contentType = CONTENT_TYPE_ALL), ";")
	for(device : devicesWithContent)
		nwbFileName = templateName + MIES_NWB#NWB_GetFileNameSuffixDevice(device) + ".nwb"
		CHECK_EQUAL_VAR(FileExists(nwbFileName), 1)
	endfor
End
