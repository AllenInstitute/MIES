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

/// UTF_TD_GENERATOR GetHistoricDataFilesNWB
static Function TestSweepBrowserExportToNWB([string str])

	string file, win, abWin, sweepBrowsers, fileType, dataFolder, nwbFileName

	file = "input:" + str
	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file})
	win = StringFromList(0, sweepBrowsers)

	WAVE/T map = GetAnalysisBrowserMap()
	fileType = map[0][%FileType]
	if(CmpStr(fileType, ANALYSISBROWSER_FILE_TYPE_NWBv1))
		SKIP_TESTCASE()
	endif

	MIES_AB#AB_ReExport(0, 0)
	CHECK_NO_RTE()

	dataFolder = map[0][%DataFolder]
	WAVE/T devices = ListToTextWave(AB_GetAllDevicesForExperiment(dataFolder), ";")
	for(device : devices)
		nwbFileName = MIES_AB#AB_ReExportGetNewFullFilePath(map[0][%DiscLocation], DimSize(devices, ROWS), device)
		CHECK_EQUAL_VAR(FileExists(nwbFileName), 1)
	endfor
End
