#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = HistoricDashboard

static Function TestCompression()

	string data, filename, path, refData, fullPath, compPath, compFile

	path = GetInputPath()

	refData  = "abcd"
	filename = "test.bak"
	compfile = filename + ZSTD_SUFFIX
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

/// UTF_TD_GENERATOR HistoricDataHelpers#GetHistoricDataFiles
Function TestDashboardWithHistoricData([string str])

	string abWin, sweepBrowsers, file, bsPanel, sbWin

	if(!CmpStr(str, "NWB-Export-bug-two-devices.pxp"))
		// @todo SweepBrowser is not fully multi-device compliant, see issue
		// https://github.com/AllenInstitute/MIES/issues/2151
		SKIP_TESTCASE()
	endif

	file = "input:" + str

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file}, loadSweeps = 1)
	sbWin                  = StringFromList(0, sweepBrowsers)
	CHECK_PROPER_STR(sbWin)
	bsPanel = BSP_GetPanel(sbWin)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DS", val = 1)
End

Function TestAnalysisBrowserAddingFiles()

	string abWin, sweepBrowsers, fileToReadd
	variable holeIndex

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFiles()
	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files)

	PGC_SetAndActivateControl(abWin, "button_collapse_all")

	WAVE/T map = GetAnalysisBrowserMap()
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(map, NOTE_INDEX), DimSize(files, ROWS))

	holeIndex   = 1
	fileToReadd = map[holeIndex]

	SetListBoxSelection(abWin, "listbox_AB_Folders", LISTBOX_SELECTED, holeIndex)
	PGC_SetAndActivateControl(abWin, "button_AB_Remove")
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(map, NOTE_INDEX), DimSize(files, ROWS))

	MIES_AB#AB_AddFiles(abWin, {fileToReadd})
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(map, NOTE_INDEX), DimSize(files, ROWS))
End

Function TestDashboardDependentControlHandling()

	string abWin, sweepBrowsers, file, sweepBrowser, bsPanel, scPanel

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFiles()
	file = "input:" + files[0]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file}, loadSweeps = 1)
	sweepBrowser           = StringFromList(0, sweepBrowsers, ";")

	bsPanel = BSP_GetPanel(sweepBrowser)
	CHECK(WindowExists(bsPanel))

	scPanel = BSP_GetSweepControlsPanel(sweepBrowser)
	CHECK(WindowExists(scPanel))

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DS", val = CHECKBOX_SELECTED)

	// OVS checkbox is now enabled and but disabled
	CHECK_EQUAL_VAR(GetCheckBoxState(bsPanel, "check_BrowserSettings_OVS"), CHECKBOX_SELECTED)
	CHECK_EQUAL_VAR(IsControlDisabled(bsPanel, "check_BrowserSettings_OVS"), 1)

	// disabling the dashboard
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DS", val = CHECKBOX_UNSELECTED)

	// restores it
	CHECK_EQUAL_VAR(GetCheckBoxState(bsPanel, "check_BrowserSettings_OVS"), CHECKBOX_UNSELECTED)
	CHECK_EQUAL_VAR(IsControlDisabled(bsPanel, "check_BrowserSettings_OVS"), 0)

	// so does previous sweep
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DS", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(scPanel, "button_SweepControl_PrevSweep")

	CHECK_EQUAL_VAR(GetCheckBoxState(bsPanel, "check_BrowserSettings_DS"), CHECKBOX_UNSELECTED)
	CHECK_EQUAL_VAR(GetCheckBoxState(bsPanel, "check_BrowserSettings_OVS"), CHECKBOX_UNSELECTED)
	CHECK_EQUAL_VAR(IsControlDisabled(bsPanel, "check_BrowserSettings_OVS"), 0)

	// so does next sweep
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DS", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(scPanel, "button_SweepControl_NextSweep")

	CHECK_EQUAL_VAR(GetCheckBoxState(bsPanel, "check_BrowserSettings_DS"), CHECKBOX_UNSELECTED)
	CHECK_EQUAL_VAR(GetCheckBoxState(bsPanel, "check_BrowserSettings_OVS"), CHECKBOX_UNSELECTED)
	CHECK_EQUAL_VAR(IsControlDisabled(bsPanel, "check_BrowserSettings_OVS"), 0)
End

static Function CheckNumberOfSelectedRows(string bsPanel)

	DFREF dfr            = BSP_GetFolder(bsPanel, MIES_BSP_PANEL_FOLDER)
	WAVE  listBoxSelWave = GetAnaFuncDashboardselWave(dfr)
	Duplicate/FREE/RMD=[][][0] listBoxSelWave, listBoxSelWaveFirstLayer

	return Sum(listBoxSelWaveFirstLayer) / DimSize(listBoxSelWave, COLS)
End

Function TestDashboardSelections()

	string abWin, sweepBrowsers, file, sweepBrowser, bsPanel

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFiles()
	file = "input:" + files[0]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file}, loadSweeps = 1)
	sweepBrowser           = StringFromList(0, sweepBrowsers, ";")

	bsPanel = BSP_GetPanel(sweepBrowser)
	CHECK(WindowExists(bsPanel))

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DS", val = CHECKBOX_SELECTED)

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DB_Passed", val = CHECKBOX_SELECTED)
	CHECK_EQUAL_VAR(CheckNumberOfSelectedRows(bsPanel), 0)

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DB_Failed", val = CHECKBOX_SELECTED)
	CHECK_EQUAL_VAR(CheckNumberOfSelectedRows(bsPanel), 0)

	// 0th SCI
	SetListBoxSelection(bsPanel, "list_dashboard", LISTBOX_SELECTED, 1)
	PGC_SetAndActivateControl(bsPanel, "list_dashboard", val = 1)

	CHECK_EQUAL_VAR(CheckNumberOfSelectedRows(bsPanel), 1)
	WAVE/Z sweeps = OVS_GetSelectedSweeps(bsPanel, OVS_SWEEP_SELECTION_SWEEPNO)
	CHECK_EQUAL_WAVES(sweeps, {1}, mode = WAVE_DATA)

	// 4th SCI
	SetListBoxSelection(bsPanel, "list_dashboard", 0, 1)
	SetListBoxSelection(bsPanel, "list_dashboard", LISTBOX_SELECTED, 4)
	PGC_SetAndActivateControl(bsPanel, "list_dashboard", val = 4)

	// Passed & Failed
	CHECK_EQUAL_VAR(CheckNumberOfSelectedRows(bsPanel), 1)
	WAVE/Z sweeps = OVS_GetSelectedSweeps(bsPanel, OVS_SWEEP_SELECTION_SWEEPNO)
	CHECK_EQUAL_WAVES(sweeps, {4, 5, 6, 7, 8, 9, 10, 11}, mode = WAVE_DATA)

	// Failed
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DB_Passed", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DB_Failed", val = CHECKBOX_SELECTED)
	CHECK_EQUAL_VAR(CheckNumberOfSelectedRows(bsPanel), 1)
	WAVE/Z sweeps = OVS_GetSelectedSweeps(bsPanel, OVS_SWEEP_SELECTION_SWEEPNO)
	CHECK_EQUAL_WAVES(sweeps, {5, 6, 7}, mode = WAVE_DATA)

	// Passed
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DB_Passed", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DB_Failed", val = CHECKBOX_UNSELECTED)
	CHECK_EQUAL_VAR(CheckNumberOfSelectedRows(bsPanel), 1)
	WAVE/Z sweeps = OVS_GetSelectedSweeps(bsPanel, OVS_SWEEP_SELECTION_SWEEPNO)
	CHECK_EQUAL_WAVES(sweeps, {4, 8, 9, 10, 11}, mode = WAVE_DATA)

	// and the 6th in addition
	SetListBoxSelection(bsPanel, "list_dashboard", LISTBOX_SELECTED, 6)
	PGC_SetAndActivateControl(bsPanel, "list_dashboard", val = 6)
	CHECK_EQUAL_VAR(CheckNumberOfSelectedRows(bsPanel), 2)
	WAVE/Z sweeps = OVS_GetSelectedSweeps(bsPanel, OVS_SWEEP_SELECTION_SWEEPNO)
	CHECK_EQUAL_WAVES(sweeps, {4, 8, 9, 10, 11, 20, 21}, mode = WAVE_DATA)
End

static Function TestOngoingDAQBugWithoutAnalysisFunction()

	string sweepBrowsers, sweepBrowser, bsPanel, abWin

	Make/FREE/T files = {"input:H22.03.311.11.08.01.06.nwb", "input:NWB_V1_single_device.nwb"}
	DownloadFilesIfRequired(files)
	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1, multipleSweepBrowser = 0)
	CHECK_NO_RTE()

	sweepBrowser = StringFromList(0, sweepBrowsers)

	bsPanel = BSP_GetPanel(sweepBrowser)
	CHECK(WindowExists(bsPanel))

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DS", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DB_Passed", val = CHECKBOX_SELECTED)
End
