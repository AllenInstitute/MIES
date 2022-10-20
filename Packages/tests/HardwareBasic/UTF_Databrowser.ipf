#pragma TextEncoding = "UTF-8"
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
End
