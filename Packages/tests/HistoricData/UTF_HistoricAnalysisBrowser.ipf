#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=HistoricAnalysisBrowser

static StrConstant PXP_FILENAME  = "input:AB_LoadSweepsFromIgorData.pxp"
static StrConstant PXP2_FILENAME = "input:AB_SweepsFromMultipleDevices.pxp"
static StrConstant PXP3_FILENAME = "input:SourceOfDependentStimset.pxp"
static StrConstant NWB1_FILENAME = "input:AB_SweepsFromMultipleDevices-compressed-V1.nwb"
static StrConstant NWB2_FILENAME = "input:AB_SweepsFromMultipleDevices-compressed-V2.nwb"

/// UTF_TD_GENERATOR GetHistoricDataNoData
static Function TestEmptyPXP([string str])

	string file, abWin, sweepBrowsers

	file = "input:" + str

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file}, loadSweeps = 1)
	CHECK(WindowExists(abWin))
	CHECK_EMPTY_STR(sweepBrowsers)
End

static Function LoadSweepsFromIgor()

	string abWin, sweepBrowsers, win

	Make/FREE/T files = {PXP_FILENAME}
	DownloadFilesIfRequired(files)
	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1)

	CHECK_EQUAL_VAR(ItemsInList(sweepBrowsers), 1)
	win = StringFromList(0, sweepBrowsers)
	WAVE/Z sweep = WaveRefIndexed(win, 0, 1)
	CHECK_WAVE(sweep, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(sweep, ROWS), 31667)
	CHECK_CLOSE_VAR(WaveMax(sweep), 1000, tol = 1E-2)
	KillWindow $abWin
	KilLWindow $win
End

static Function CheckRefCount()

	string abWin, dfPath, sweepBrowsers
	string sBrowser1, sBrowser2

	KillOrMoveToTrash(dfr = GetAnalysisFolder())

	Make/FREE/T files = {PXP2_FILENAME}
	DownloadFilesIfRequired(files)
	[abWin, sweepBrowsers] = OpenAnalysisBrowser({PXP2_FILENAME})

	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED

	DFREF  dfr         = $(GetAnalysisFolderAS() + ":workFolder:")
	WAVE/T workFolders = ListToTextWave(GetListOfObjects(dfr, ".*", typeFlag = COUNTOBJECTS_DATAFOLDER, fullPath = 1), ";")
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

	Make/FREE/T files = {PXP2_FILENAME, NWB1_FILENAME, NWB2_FILENAME}
	DownloadFilesIfRequired(files)
	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files)
	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	sBrowser1              = LoadSweeps(abWin)

	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW
	expBrowserSel[6][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	try
		LoadSweeps(abWin)
		FAIL()
	catch
		PASS()
	endtry

	expBrowserSel[6][0][0]  = LISTBOX_TREEVIEW
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

static Function LoadDependentStimsetsFromPXP()

	string abWin, sweepBrowsers, formulaSet

	Make/FREE/T files = {PXP3_FILENAME}
	DownloadFilesIfRequired(files)

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadStimsets = 1)
	formulaSet             = MIES_WB#WB_StimsetChildren(stimset = "baseset_DA_0")
	CHECK_EQUAL_STR(formulaSet, "formula_da_0;")

	KillWindow $abWin
End

static Function TestGetChannelInfo()

	string abWin, sweepBrowsers, win

	Make/FREE/T files = {PXP_FILENAME}
	DownloadFilesIfRequired(files)
	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1)

	CHECK_EQUAL_VAR(ItemsInList(sweepBrowsers), 1)
	win = StringFromList(0, sweepBrowsers)

	WAVE/T channelInfo = SB_GetChannelInfoFromGraph(win, "AD")
	CHECK_WAVE(channelInfo, TEXT_WAVE | FREE_WAVE)

	Make/FREE/T channelInfoRef = {{"0"}, {"root:MIES:Analysis:workFolder:AB_LoadSweepsFromIgorData:Dev1:sweep:X_0:AD_0"}, {"0"}}
	CHECK_EQUAL_TEXTWAVES(channelInfo, channelInfoRef, mode = WAVE_DATA)
End
