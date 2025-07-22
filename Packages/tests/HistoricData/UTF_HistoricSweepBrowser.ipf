#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = SweepBrowserTests

/// UTF_TD_GENERATOR HistoricDataHelpers#GetHistoricDataFilesWithTTLData
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

	// without OVS and non-split TTL
	PGC_SetAndActivateControl(win, "check_BrowserSettings_OVS", val = 0)
	PGC_SetAndActivateControl(win, "check_BrowserSettings_VisEpochs", val = 0)
	PGC_SetAndActivateControl(win, "check_BrowserSettings_splitTTL", val = 0)

	// with overlay channels
	PGC_SetAndActivateControl(win, "check_BrowserSettings_OChan", val = 1)

	CHECK_NO_RTE()
End

static Function LoadAndCheckStimset(string win, string traceName, string channelTypeStr, string stimset)

	string waveBuilderPanel, str, history
	variable ref

	ref = CaptureHistoryStart()
	MIES_WBP#WB_OpenStimulusSetInWaveBuilderImpl(win, traceName, "Fake")
	history = CaptureHistory(ref, 1)
	CHECK_EMPTY_STR(history)

	waveBuilderPanel = GetCurrentWindow()
	CHECK_EQUAL_STR(waveBuilderPanel, "WaveBuilder")
	str = GetPopupMenuString(waveBuilderPanel, "popup_WaveBuilder_OutputType")
	CHECK_EQUAL_STR(str, channelTypeStr)
	str = GetSetVariableString(waveBuilderPanel, "setvar_WaveBuilder_baseName")
	CHECK_EQUAL_STR(str, stimset)
End

/// UTF_TD_GENERATOR HistoricDataHelpers#GetHistoricDataFilesWithTTLData
static Function TestStimsetLoading([string str])

	string file, abWin, sweepBrowsers, bsPanel, history, scPanel, win
	variable ref

	file = "input:" + str

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file}, loadSweeps = 1, loadStimsets = 1)

	win     = StringFromList(0, sweepBrowsers)
	bsPanel = BSP_GetPanel(win)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DAC", val = 1)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_ADC", val = 1)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_TTL", val = 1)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_VisEpochs", val = 1)

	CHECK_NO_RTE()

	scPanel = BSP_GetSweepControlsPanel(win)
	PGC_SEtAndActivateControl(scPanel, "Popup_SweepControl_Selector", str = "Sweep 26")

	// DA0
	LoadAndCheckStimset(win, "T000000", "DA", "DA13_50spuff_sti")

	// AD0
	LoadAndCheckStimset(win, "T000001", "DA", "DA13_50spuff_sti")

	// invalid trace (epoch)
	ref = CaptureHistoryStart()
	MIES_WBP#WB_OpenStimulusSetInWaveBuilderImpl(win, "T000005_level2_x__sweep26_chan0_type0_HS0", "Fake")
	history = CaptureHistory(ref, 1)
	CHECK_EQUAL_STR(history, "Context menu option \"Fake\" could not find the stimulus set of the trace T000005_level2_x__sweep26_chan0_type0_HS0.\r")

	// TTL
	LoadAndCheckStimset(win, "T000002", "TTL", "DA13_50spuff_sti")
End

Function TestSweepFormulaPowerSpectrumAverage()

	string abWin, sweepBrowsers, file, sweepBrowser, bsPanel, scPanel, code

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFiles()
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
