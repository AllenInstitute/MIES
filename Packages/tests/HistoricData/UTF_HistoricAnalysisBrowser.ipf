#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = HistoricAnalysisBrowser

static StrConstant PXP_FILENAME  = "input:AB_LoadSweepsFromIgorData.pxp"
static StrConstant PXP2_FILENAME = "input:AB_SweepsFromMultipleDevices.pxp"
static StrConstant PXP3_FILENAME = "input:SourceOfDependentStimset.pxp"
static StrConstant NWB1_FILENAME = "input:AB_SweepsFromMultipleDevices-compressed-V1.nwb"
static StrConstant NWB2_FILENAME = "input:AB_SweepsFromMultipleDevices-compressed-V2.nwb"

static StrConstant TARGETSB_FILENAME1 = "input:Pvalb-IRES-Cre;Ai14-646904.13.03.02.pxp"
static StrConstant TARGETSB_FILENAME2 = "input:nwb2_H17.03.016.11.09.01.nwb"

static StrConstant LOADTPSTORAGE_FILENAME   = "input:nwb2_H17.03.016.11.09.01.nwb"
static StrConstant LOADHISTORY_FILENAME     = "input:nwb2_H17.03.016.11.09.01.nwb"
static StrConstant CHECKCOLLAPSED_FILENAME1 = "input:nwb2_H17.03.016.11.09.01.nwb"
static StrConstant CHECKCOLLAPSED_FILENAME2 = "input:Pvalb-IRES-Cre;Ai14-646904.13.03.02.pxp"

/// UTF_TD_GENERATOR HistoricDataHelpers#GetHistoricDataNoData
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

	PGC_SetAndActivateControl(abWin, "button_expand_all")
	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	sBrowser1              = LoadSweeps(abWin)

	PGC_SetAndActivateControl(abWin, "button_expand_all")
	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW
	expBrowserSel[6][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	try
		LoadSweeps(abWin)
		FAIL()
	catch
		PASS()
	endtry

	PGC_SetAndActivateControl(abWin, "button_expand_all")
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

static Function TestLabnotebookFallbackPathsInSweepDisplay()

	string abWin, sweepBrowsers, win

	Make/FREE/T files = {"input:very_very_early_mies-data_Rbp4-Cre_KL100;Ai14-206137.04.02.pxp"}
	DownloadFilesIfRequired(files)
	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1)
	CHECK_NO_RTE()
End

static Function TestNWBvsPXP_Selection()

	string abWin, sweepBrowsers, fType

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({PXP_FILENAME, NWB1_FILENAME})
	CHECK(WindowExists(abWin))

	WAVE   expBrowserSel = GetExperimentBrowserGUISel()
	WAVE/T expBrowserGUI = GetExperimentBrowserGUIList()

	PGC_SetAndActivateControl(abWin, "check_load_nwb", val = CHECKBOX_UNSELECTED)
	CHECK_EQUAL_VAR(DimSize(expBrowserSel, ROWS), 1)
	CHECK_EQUAL_VAR(DimSize(expBrowserGUI, ROWS), 1)
	fType = expBrowserGUI[0][%type]
	CHECK_EQUAL_STR(fType, ANALYSISBROWSER_FILE_TYPE_IGOR)

	PGC_SetAndActivateControl(abWin, "check_load_nwb", val = CHECKBOX_SELECTED)
	// The file includes data from two devices
	CHECK_EQUAL_VAR(DimSize(expBrowserSel, ROWS), 2)
	CHECK_EQUAL_VAR(DimSize(expBrowserGUI, ROWS), 2)
	fType = expBrowserGUI[0][%type]

	CHECK_EQUAL_STR(fType, ANALYSISBROWSER_FILE_TYPE_NWBv1)
End

/// UTF_TD_GENERATOR HistoricDataHelpers#GetHistoricDataLoadResults
static Function TestLoadResults([string str])

	string abWin, sweepBrowsers, file

	file = "input:" + str

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file})
	CHECK(WindowExists(abWin))
	WAVE/T map        = GetAnalysisBrowserMap()
	DFREF  dataFolder = GetAnalysisExpFolder(map[0][%DataFolder])
	DFREF  dfr        = dataFolder:results
	CHECK_EQUAL_VAR(DataFolderExistsDFR(dfr), 0)

	PGC_SetAndActivateControl(abWin, "check_load_results", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(abWin, "button_AB_refresh")
	DFREF dfr = dataFolder:results
	CHECK_EQUAL_VAR(DataFolderExistsDFR(dfr), 1)
End

/// UTF_TD_GENERATOR HistoricDataHelpers#GetHistoricDataLoadUserComment
static Function TestLoadComments([string str])

	string abWin, sweepBrowsers, file

	file = "input:" + str

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file})
	CHECK(WindowExists(abWin))

	WAVE/T map     = GetAnalysisBrowserMap()
	WAVE/T devList = GetAnalysisDeviceWave(map[0][%DataFolder])

	DFREF  dfr     = GetAnalysisDeviceFolder(map[0][%DataFolder], devList[0])
	SVAR/Z comment = dfr:userComment
	CHECK_EQUAL_VAR(SVAR_Exists(comment), 0)

	PGC_SetAndActivateControl(abWin, "check_load_comment", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(abWin, "button_AB_refresh")

	WAVE/T devList = GetAnalysisDeviceWave(map[0][%DataFolder])
	DFREF  dfr     = GetAnalysisDeviceFolder(map[0][%DataFolder], devList[0])
	SVAR/Z comment = dfr:userComment
	CHECK_EQUAL_VAR(SVAR_Exists(comment), 1)
End

static Function TestTargetSweepBrowser()

	string abWin, sweepBrowsers, sBrowser1, sBrowser2, sBrowser3, sbTitle
	variable numSweeps1, numSweeps2, first, last

	Make/FREE/T files = {TARGETSB_FILENAME1, TARGETSB_FILENAME2}
	DownloadFilesIfRequired(files)
	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files)
	CHECK(WindowExists(abWin))

	WAVE   expBrowserSel = GetExperimentBrowserGUISel()
	WAVE/T expBrowserGUI = GetExperimentBrowserGUIList()

	PGC_SetAndActivateControl(abWin, "button_expand_all")
	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	sBrowser1              = LoadSweeps(abWin)
	CHECK_NON_EMPTY_STR(sBrowser1)
	numSweeps1    = str2num(expBrowserGUI[0][%'#sweeps'])
	[first, last] = BSP_FirstAndLastSweepAcquired(sBrowser1)
	CHECK_EQUAL_VAR(numSweeps1, last - first + 1)

	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW
	expBrowserSel[1][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	sBrowser2              = LoadSweeps(abWin)
	CHECK_NON_EMPTY_STR(sBrowser2)
	numSweeps2    = str2num(expBrowserGUI[1][%'#sweeps'])
	[first, last] = BSP_FirstAndLastSweepAcquired(sBrowser2)
	CHECK_EQUAL_VAR(numSweeps2, last - first + 1)

	PGC_SetAndActivateControl(abWin, "popup_SweepBrowserSelect", val = 1)
	PGC_SetAndActivateControl(abWin, "button_expand_all")
	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	sBrowser3              = LoadSweeps(abWin)
	CHECK_EQUAL_STR(sBrowser2, sBrowser3)
	[first, last] = BSP_FirstAndLastSweepAcquired(sBrowser3)
	CHECK_EQUAL_VAR(numSweeps1 + numSweeps2, last - first + 1)

	KillWindow/Z $sBrowser3
	sbTitle = GetPopupMenuString(ANALYSIS_BROWSER_NAME, "popup_SweepBrowserSelect")
	CHECK_EQUAL_STR(sbTitle, "New")

	KillWindow/Z $abWin
	KillWindow/Z $sBrowser1
	CHECK_NO_RTE()
End

static Function TestLoadTPStorage()

	string abWin, sweepBrowsers, wList

	Make/FREE/T files = {LOADTPSTORAGE_FILENAME}
	DownloadFilesIfRequired(files)
	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files)
	CHECK(WindowExists(abWin))

	WAVE/T map = GetAnalysisBrowserMap()

	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	PGC_SetAndActivateControl(abWin, "button_load_tpstorage")

	WAVE/T devList = GetAnalysisDeviceWave(map[0][%DataFolder])
	DFREF  dfr     = GetAnalysisDeviceFolder(map[0][%DataFolder], devList[0])
	DFREF  dfrTP   = dfr:testpulse
	CHECK_EQUAL_VAR(DataFolderExistsDFR(dfrTP), 1)
	wList = GetListOfObjects(dfrTP, TP_STORAGE_REGEXP, recursive = 1, typeFlag = COUNTOBJECTS_WAVES, exprType = MATCH_REGEXP)
	CHECK_NON_EMPTY_STR(wList)
End

static Function TestLoadHistory()

	string abWin, sweepBrowsers, name, text

	Make/FREE/T files = {LOADHISTORY_FILENAME}
	DownloadFilesIfRequired(files)
	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files)
	CHECK(WindowExists(abWin))

	WAVE/T map = GetAnalysisBrowserMap()

	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	PGC_SetAndActivateControl(abWin, "button_load_history")

	name = WinName(0, 16)
	text = GetNotebookText(name)
	CHECK_NON_EMPTY_STR(text)
End

static Function CheckIfABCollapsed_IGNORE()

	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	FindValue/V=0/RMD=[][0][0][0] expBrowserSel
	CHECK_EQUAL_VAR(V_Value, -1)
End

static Function TestCheckIfCollapsed()

	string abWin, sweepBrowsers, name, text

	Make/FREE/T files = {CHECKCOLLAPSED_FILENAME1, CHECKCOLLAPSED_FILENAME2}
	DownloadFilesIfRequired(files)
	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files)
	CHECK(WindowExists(abWin))

	CheckIfABCollapsed_IGNORE()

	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	PGC_SetAndActivateControl(abWin, "button_expand_all")
	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	LoadSweeps(abWin)
	CheckIfABCollapsed_IGNORE()

	WAVE folderSel = GetAnalysisBrowserGUIFolderSelection()
	PGC_SetAndActivateControl(abWin, "button_expand_all")
	folderSel[0][0][0] = LISTBOX_SELECTED
	PGC_SetAndActivateControl(abWin, "button_AB_Remove")
	CheckIfABCollapsed_IGNORE()
End
