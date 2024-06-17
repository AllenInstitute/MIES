#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=DataBrowserTests

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
Function CanFindAllDataBrowsers([string str])

	string win, bsPanel

	// locked device
	CreateLockedDAEphys(str)

	// first db
	CreateLockedDatabrowser(str)

	// second db
	CreateLockedDatabrowser(str)

	WAVE/T/Z matches = DB_FindAllDataBrowser(str)
	CHECK_WAVE(matches, TEXT_WAVE)

	CHECK_EQUAL_VAR(DimSize(matches, ROWS), 2)

	WAVE/T/Z matchesAll = DB_FindAllDataBrowser(str, mode = BROWSER_MODE_ALL)
	CHECK_EQUAL_WAVES(matches, matchesAll)

	WAVE/T/Z matchesUser = DB_FindAllDataBrowser(str, mode = BROWSER_MODE_USER)
	CHECK_EQUAL_WAVES(matches, matchesUser)

	WAVE/T/Z matchesAuto = DB_FindAllDataBrowser(str, mode = BROWSER_MODE_AUTOMATION)
	CHECK_WAVE(matchesAuto, NULL_WAVE)

	DB_GetBoundDataBrowser(str, mode = BROWSER_MODE_AUTOMATION)

	WAVE/T/Z matchesAuto = DB_FindAllDataBrowser(str, mode = BROWSER_MODE_AUTOMATION)
	CHECK_WAVE(matchesAuto, TEXT_WAVE)

	CHECK_EQUAL_VAR(DimSize(matchesAuto, ROWS), 1)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
Function CheckWindowTitles([string str])

	string win

	CreateLockedDAEphys(str)

	// check window titles

	win = DB_GetBoundDataBrowser(str, mode = BROWSER_MODE_USER)
	GetWindow $win, wtitle
	CHECK_EQUAL_STR(S_Value, "Browser with \"" + str + "\"")

	win = DB_GetBoundDataBrowser(str, mode = BROWSER_MODE_AUTOMATION)
	GetWindow $win, wtitle
	CHECK_EQUAL_STR(S_Value, "Browser [1] with \"" + str + "\" (A*U*T*O*M*A*T*I*O*N)")
End

static Function/WAVE AllDatabrowserSubWindows()

	string win

	win = DB_OpenDatabrowser()

	WAVE/T/Z allWindows = ListToTextWave(GetAllWindows(win), ";")
	CHECK_WAVE(allWindows, TEXT_WAVE)

	allWindows[] = StringFromList(1, allWindows[p], "#")

	RemoveTextWaveEntry1D(allWindows, "", all = 1)

	WAVE/T/Z allWindowsUnique = GetUniqueEntries(allWindows)
	CHECK_WAVE(allWindowsUnique, TEXT_WAVE)

	SetDimensionLabels(allWindowsUnique, TextWaveToList(allWindowsUnique, ";"), ROWS)

	KillWindow $win

	return allWindowsUnique
End

// UTF_TD_GENERATOR AllDatabrowserSubWindows
Function RestoreButtonWorks([string str])

	string win, subWindow

	win       = DB_OpenDatabrowser()
	subWindow = str

	CHECK(WindowExists(subWindow))

	// restore button is hidden
	CHECK(IsControlHidden(win, "button_BSP_open"))

	// restore button is not hidden amymore after killing the subwindow
	KillWindow $subWindow
	CHECK(!IsControlHidden(win, "button_BSP_open"))

	// subwindow is hidden
	GetWindow $subWindow, hide
	CHECK_EQUAL_VAR(V_Value, 0x1)

	// restoring
	PGC_SetAndActivateControl(win, "button_BSP_open")
	CHECK(WindowExists(subWindow))

	// subwindow is not hidden
	GetWindow $subWindow, hide
	CHECK_EQUAL_VAR(V_Value, 0x0)

	// but the button is hidden again
	CHECK(IsControlHidden(win, "button_BSP_open"))
End
