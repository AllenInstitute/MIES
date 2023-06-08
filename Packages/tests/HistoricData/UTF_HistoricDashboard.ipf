#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=HistoricDashboard

static Function TestCompression()

	string data, filename, path, refData, fullPath, compPath, compFile

	path = GetInputPath()

	refData = "abcd"
	filename = "test.bak"
	compfile = filename  + ZSTD_SUFFIX
	fullPath = path + filename
	compPath = path + compfile

	// cleanup from previous runs
	DeleteFile/Z=1 fullPath
	CHECK(!FileExists(fullPath))

	DeleteFile/Z=1 compPath
	CHECK(!FileExists(compPath))

	SaveTextFile(refData, fullPath)
	CHECK(FileExists(fullPath))

	CompressFile(filename)
	CHECK(FileExists(compPath))

	DeleteFile/Z=1 fullPath
	CHECK(!FileExists(fullPath))

	DecompressFile(filename)
	CHECK(FileExists(compPath))
	CHECK(FileExists(fullPath))

	[data, filename] = LoadTextFile(fullPath)
	CHECK_EQUAL_STR(filename, fullPath)
	CHECK_EQUAL_STR(refData, data)
End

/// UTF_TD_GENERATOR GetHistoricDataFiles
Function TestDashboardWithHistoricData([string str])

	string abWin, sweepBrowsers, file, bsPanel, sbWin

	file = "input:" + str

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file}, loadSweeps = 1)
	sbWin = StringFromList(0, sweepBrowsers)
	CHECK_PROPER_STR(sbWin)
	bsPanel = BSP_GetPanel(sbWin)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DS", val = 1)
End
