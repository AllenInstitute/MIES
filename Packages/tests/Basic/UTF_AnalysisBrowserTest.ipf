#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=AnalysisBrowserTests

/// @file UTF_AnalysisBrowserTest.ipf
/// @brief __ANALYSISBROWSER_Test__ This file holds the tests for the Analysis Browser Tests

static StrConstant PXP_FILENAME = "AB_LoadSweepsFromIgorData.pxp"
static StrConstant PXP2_FILENAME = "AB_SweepsFromMultipleDevices.pxp"
static StrConstant NWB1_FILENAME = "AB_SweepsFromMultipleDevices-compressed-V1.nwb"
static StrConstant NWB2_FILENAME = "AB_SweepsFromMultipleDevices-compressed-V2.nwb"

static Function/S LoadSweeps(string winAB)

	PGC_SetAndActivateControl(winAB, "button_load_sweeps")

	return StringFromList(0, WinList("*", ";", "WIN:" + num2istr(WINTYPE_GRAPH)))
End

static Function LoadSweepsFromIgor()

	string win

	NVAR JSONid = $GetSettingsJSONid()
	WAVE/T saveSetting = JSON_GetTextWave(jsonID, SETTINGS_AB_FOLDER)

	PathInfo home
	REQUIRE_EQUAL_VAR(V_flag, 1)
	Make/FREE/T setFolderList = {S_path + PXP_FILENAME}
	JSON_SetWave(jsonID, SETTINGS_AB_FOLDER, setFolderList)
	win = AB_OpenAnalysisBrowser()
	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	PGC_SetAndActivateControl(win, "button_load_sweeps")
	KillWindow $win

	win = WinList("*", ";", "WIN:" + num2istr(WINTYPE_GRAPH))
	CHECK_EQUAL_VAR(ItemsInList(win), 1)
	win = StringFromList(0, win)
	WAVE sweep = WaveRefIndexed(win, 0, 1)
	CHECK_EQUAL_VAR(DimSize(sweep, ROWS), 31667)
	CHECK_CLOSE_VAR(WaveMax(sweep), 1000, tol=1E-2)
	KillWindow $win

	JSON_SetWave(jsonID, SETTINGS_AB_FOLDER, saveSetting)
End

static Function CheckRefCount()

	string win, dfPath
	string sBrowser1, sBrowser2

	NVAR JSONid = $GetSettingsJSONid()
	WAVE/T saveSetting = JSON_GetTextWave(jsonID, SETTINGS_AB_FOLDER)

	PathInfo home
	REQUIRE_EQUAL_VAR(V_flag, 1)

	Make/FREE/T setFolderList = {S_path + PXP2_FILENAME}
	JSON_SetWave(jsonID, SETTINGS_AB_FOLDER, setFolderList)
	win = AB_OpenAnalysisBrowser()
	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED

	dfPath = GetAnalysisFolderAS() + ":workFolder:" + RemoveEnding(PXP2_FILENAME, ".pxp")
	NVAR rc = $GetDFReferenceCount($dfPath)
	CHECK_EQUAL_VAR(rc, 1)
	sBrowser1 = LoadSweeps(win)
	CHECK_EQUAL_VAR(rc, 2)
	sBrowser2 = LoadSweeps(win)
	CHECK_EQUAL_VAR(rc, 3)

	KillWindow $win
	CHECK_EQUAL_VAR(rc, 2)
	KillWindow $sBrowser1
	CHECK_EQUAL_VAR(rc, 1)
	KillWindow $sBrowser2
	CHECK_EQUAL_VAR(DataFolderExists(dfPath), 0)

	JSON_SetWave(jsonID, SETTINGS_AB_FOLDER, saveSetting)
End

static Function TryLoadingDifferentFiles()

	string win, sBrowser1

	NVAR JSONid = $GetSettingsJSONid()
	WAVE/T saveSetting = JSON_GetTextWave(jsonID, SETTINGS_AB_FOLDER)

	PathInfo home
	REQUIRE_EQUAL_VAR(V_flag, 1)

	Make/FREE/T setFolderList = {S_path + PXP2_FILENAME, S_path + NWB1_FILENAME, S_path + NWB2_FILENAME}
	JSON_SetWave(jsonID, SETTINGS_AB_FOLDER, setFolderList)
	win = AB_OpenAnalysisBrowser()
	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	sBrowser1 = LoadSweeps(win)

	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW
	expBrowserSel[6][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	try
		LoadSweeps(win)
		FAIL()
	catch
		PASS()
	endtry

	expBrowserSel[6][0][0] = LISTBOX_TREEVIEW
	expBrowserSel[12][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	try
		LoadSweeps(win)
		FAIL()
	catch
		PASS()
	endtry

	KillWindow $win
	KillWindow $sBrowser1

	JSON_SetWave(jsonID, SETTINGS_AB_FOLDER, saveSetting)
End
