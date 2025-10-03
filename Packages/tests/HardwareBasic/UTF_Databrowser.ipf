#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = DataBrowserTests

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
Function CanFindAllDataBrowsers([string str])

	string win, bsPanel

	// locked device
	CreateLockedDAEphys(str)

	// first db
	CreateLockedDatabrowser(str)

	// second db
	CreateLockedDatabrowser(str)

	WAVE/Z/T matches = DB_FindAllDataBrowser(str)
	CHECK_WAVE(matches, TEXT_WAVE)

	CHECK_EQUAL_VAR(DimSize(matches, ROWS), 2)

	WAVE/Z/T matchesAll = DB_FindAllDataBrowser(str, mode = BROWSER_MODE_ALL)
	CHECK_EQUAL_WAVES(matches, matchesAll)

	WAVE/Z/T matchesUser = DB_FindAllDataBrowser(str, mode = BROWSER_MODE_USER)
	CHECK_EQUAL_WAVES(matches, matchesUser)

	WAVE/Z/T matchesAuto = DB_FindAllDataBrowser(str, mode = BROWSER_MODE_AUTOMATION)
	CHECK_WAVE(matchesAuto, NULL_WAVE)

	DB_GetBoundDataBrowser(str, mode = BROWSER_MODE_AUTOMATION)

	WAVE/Z/T matchesAuto = DB_FindAllDataBrowser(str, mode = BROWSER_MODE_AUTOMATION)
	CHECK_WAVE(matchesAuto, TEXT_WAVE)

	CHECK_EQUAL_VAR(DimSize(matchesAuto, ROWS), 1)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
Function CheckWindowTitles([string str])

	string win

	CreateLockedDAEphys(str)

	// check window titles

	win = DB_GetBoundDataBrowser(str, mode = BROWSER_MODE_USER)
	GetWindow $win, wtitle
	CHECK_EQUAL_STR(S_Value, "Browser with \"" + str + "\"")

	win = DB_GetBoundDataBrowser(str, mode = BROWSER_MODE_AUTOMATION)
	GetWindow $win, wtitle
	CHECK_EQUAL_STR(S_Value, "Browser with \"" + str + "\" (A*U*T*O*M*A*T*I*O*N)")
End

// UTF_TD_GENERATOR DataGenerators#AllDatabrowserSubWindows
Function RestoreButtonWorks([string str])

	string win, subWindow

	win       = DB_OpenDatabrowser()
	subWindow = str

	CHECK(WindowExists(subWindow))

	// restore button is hidden
	CHECK(IsControlHidden(win, BSP_SHOW_WIN_BUTTON))

	// restore button is not hidden amymore after killing the subwindow
	KillWindow $subWindow
	CHECK(!IsControlHidden(win, BSP_SHOW_WIN_BUTTON))

	// subwindow is hidden
	GetWindow $subWindow, hide
	CHECK_EQUAL_VAR(V_Value, 0x1)

	// restoring
	PGC_SetAndActivateControl(win, BSP_SHOW_WIN_BUTTON)
	CHECK(WindowExists(subWindow))

	// subwindow is not hidden
	GetWindow $subWindow, hide
	CHECK_EQUAL_VAR(V_Value, 0x0)

	// but the button is hidden again
	CHECK(IsControlHidden(win, BSP_SHOW_WIN_BUTTON))
End

Function NextPreviousSweepUnlocked()

	string win, scPanel

	win     = DB_OpenDatabrowser()
	scPanel = BSP_GetSweepControlsPanel(win)

	try
		PGC_SetAndActivateControl(scPanel, "button_SweepControl_NextSweep")
		PGC_SetAndActivateControl(scPanel, "button_SweepControl_PrevSweep")
		PASS()
	catch
		FAIL()
	endtry
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
Function NextPreviousNoData([string str])

	string win, scPanel

	CreateLockedDAEphys(str)

	win     = DB_OpenDatabrowser()
	scPanel = BSP_GetSweepControlsPanel(win)

	try
		PGC_SetAndActivateControl(scPanel, "button_SweepControl_NextSweep")
		PGC_SetAndActivateControl(scPanel, "button_SweepControl_PrevSweep")
		PASS()
	catch
		FAIL()
	endtry
End
