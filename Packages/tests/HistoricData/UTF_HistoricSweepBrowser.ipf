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

Function TestSweepFormulaPowerSpectrumAverage()

	string abWin, sweepBrowsers, file, sweepBrowser, bsPanel, scPanel, code

	WAVE/T files = GetHistoricDataFiles()
	file = "input:" + files[0]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file}, loadSweeps = 1)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	bsPanel = BSP_GetPanel(sweepBrowser)
	CHECK(WindowExists(bsPanel))

	scPanel = BSP_GetSweepControlsPanel(sweepBrowser)
	CHECK(WindowExists(scPanel))

	code = "trange = [0, inf]\r"                                            + \
	       "sel = select(selrange($trange),selchannels(AD), selsweeps())\r" + \
	       "dat = data($sel)\r"                                             + \
	       "powerspectrum($dat, default, avg)"

	ExecuteSweepFormulaCode(sweepBrowser, code)
End
