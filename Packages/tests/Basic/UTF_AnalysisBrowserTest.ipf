#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=AnalysisBrowserTests

/// @file UTF_AnalysisBrowserTest.ipf
/// @brief __ANALYSISBROWSER_Test__ This file holds the tests for the Analysis Browser Tests

static StrConstant PXP_FILENAME = "AB_LoadSweepsFromIgorData.pxp"

static Function LoadSweepsFromIgor()

	string win

	win = AB_OpenAnalysisBrowser()
	PathInfo home
	REQUIRE_EQUAL_VAR(V_flag, 1)
	PGC_SetAndActivateControl(win, "setvar_baseFolder", str=S_path)
	PGC_SetAndActivateControl(win, "button_base_folder_scan")
	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	expBrowserSel[0][0][0] = 81
	PGC_SetAndActivateControl(win, "button_load_sweeps")
	win = WinList("*", ";", "WIN:" + num2istr(WINTYPE_GRAPH))
	CHECK_EQUAL_VAR(ItemsInList(win), 1)
	win = StringFromList(0, win)
	WAVE sweep = WaveRefIndexed(win, 0, 1)
	CHECK_EQUAL_VAR(DimSize(sweep, ROWS), 31667)
	CHECK_CLOSE_VAR(WaveMax(sweep), 1000, tol=1E-2)
End
