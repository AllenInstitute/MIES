#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=SweepBrowserTests

/// UTF_TD_GENERATOR GetHistoricDataFilesWithTTLData
static Function TestTTLDisplayWithNoEpochInfo([string str])

	string file, abWin, sweepBrowsers, win

	file = "input:" + str

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file}, loadSweeps = 1, loadStimsets = 1)

	win = BSP_GetPanel(StringFromList(0, sweepBrowsers))
	PGC_SetAndActivateControl(win, "check_BrowserSettings_DAC", val = 1)
	PGC_SetAndActivateControl(win, "check_BrowserSettings_ADC", val = 1)
	PGC_SetAndActivateControl(win, "check_BrowserSettings_TTL", val = 1)
	PGC_SetAndActivateControl(win, "check_BrowserSettings_VisEpochs", val = 1)

	PGC_SetAndActivateControl(win, "check_BrowserSettings_OVS", val = 1)
	PGC_SetAndActivateControl(win, "popup_overlaySweeps_select", str = "All")

	CHECK_NO_RTE()
End
