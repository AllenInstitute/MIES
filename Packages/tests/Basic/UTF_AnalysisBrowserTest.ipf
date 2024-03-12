#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=AnalysisBrowserTests

/// @file UTF_AnalysisBrowserTest.ipf
/// @brief __ANALYSISBROWSER_Test__ This file holds the tests for the Analysis Browser Tests

static StrConstant PXP_FILENAME = "input:AB_LoadSweepsFromIgorData.pxp"
static StrConstant PXP2_FILENAME = "input:AB_SweepsFromMultipleDevices.pxp"
static StrConstant NWB1_FILENAME = "input:AB_SweepsFromMultipleDevices-compressed-V1.nwb"
static StrConstant NWB2_FILENAME = "input:AB_SweepsFromMultipleDevices-compressed-V2.nwb"

static Function LoadSweepsFromIgor()

	string abWin, sweepBrowsers, win

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({PXP_FILENAME}, loadSweeps = 1)

	CHECK_EQUAL_VAR(ItemsInList(sweepBrowsers), 1)
	win = StringFromList(0, sweepBrowsers)
	WAVE/Z sweep = WaveRefIndexed(win, 0, 1)
	CHECK_WAVE(sweep, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(sweep, ROWS), 31667)
	CHECK_CLOSE_VAR(WaveMax(sweep), 1000, tol=1E-2)
	KillWindow $abWin
	KilLWindow $win
End

static Function CheckRefCount()

	string abWin, dfPath, sweepBrowsers
	string sBrowser1, sBrowser2

	KillOrMoveToTrash(dfr = GetAnalysisFolder())

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({PXP2_FILENAME})

	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED

	DFREF dfr = $(GetAnalysisFolderAS() + ":workFolder:")
	WAVE/T workFolders = ListToTextWave(GetListOfObjects(dfr, ".*", typeFlag = COUNTOBJECTS_DATAFOLDER, fullPath=1), ";")
	CHECK_WAVE(workFolders, TEXT_WAVE)
	dfPath = workFolders[0]
	CHECK_EQUAL_VAR(DataFolderExists(dfPath), 1)

	NVAR rc = $GetDFReferenceCount($dfPath)
	CHECK_EQUAL_VAR(rc, 1)
	sBrowser1 = LoadSweeps(abWin)
	CHECK_EQUAL_VAR(rc, 2)
	sBrowser2 = LoadSweeps(abWin)
	CHECK_EQUAL_VAR(rc, 3)

	KillWindow $abWin
	CHECK_EQUAL_VAR(rc, 2)
	KillWindow $sBrowser1
	CHECK_EQUAL_VAR(rc, 1)
	KillWindow $sBrowser2
	CHECK_EQUAL_VAR(DataFolderExists(dfPath), 0)
End

static Function TryLoadingDifferentFiles()

	string abWin, sweepBrowsers, sBrowser1

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({PXP2_FILENAME, NWB1_FILENAME, NWB2_FILENAME})
	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	sBrowser1 = LoadSweeps(abWin)

	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW
	expBrowserSel[6][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	try
		LoadSweeps(abWin)
		FAIL()
	catch
		PASS()
	endtry

	expBrowserSel[6][0][0] = LISTBOX_TREEVIEW
	expBrowserSel[12][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	try
		LoadSweeps(abWin)
		FAIL()
	catch
		PASS()
	endtry

	KillWindow $abWin
	KillWindow $sBrowser1
End

static Function TestAB_LoadDataWrapper()

	variable numLoaded
	string expFilePath
	string expName = "TestAB_LoadDataWrapper.pxp"
	string wName = "wAvE1"

	WAVE/Z wv =root:WAVE1
	KillOrMoveToTrash(wv=wv)
	wName = UpperStr(wName)
	Make root:$wName
	SaveExperiment/P=home as expName

	PathInfo home
	expFilePath = S_path + expName

	DFREF tmpDFR = NewFreeDataFolder()
	wName = LowerStr(wName) + ";"
	numLoaded = MIES_AB#AB_LoadDataWrapper(tmpDFR, expFilePath, "root:", wName, typeFlags=COUNTOBJECTS_WAVES)
	CHECK_GT_VAR(numLoaded, 0)
End
