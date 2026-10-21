#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = SweepBrowserTests

static StrConstant RESTORE_DATA_FILENAME = "input:AB_SweepsFromMultipleDevices.pxp"

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

	if(cmpstr(str, "C57BL6J-684963.02.04.01_pislocin_puff_2023_07_19_141829-compressed.nwb"))
		SKIP_TESTCASE()
		return NaN
	endif

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

static Function RestoreDataRestoresAllSweeps()

	string abWin, sweepBrowsers, win
	variable numSweeps

	Make/FREE/T files = {RESTORE_DATA_FILENAME}
	DownloadFilesIfRequired(files)
	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1)

	win = StringFromList(0, sweepBrowsers)

	DFREF  sbDFR    = SB_GetSweepBrowserFolder(win)
	WAVE/T sweepMap = GetSweepBrowserMap(sbDFR)
	numSweeps = GetNumberFromWaveNote(sweepMap, NOTE_INDEX)

	// more than one sweep per experiment/device, as sweep zero was the only one restored before
	CHECK_GT_VAR(numSweeps, 2)
	CHECK_GT_VAR(ModifySweepBrowserData(win, 1), numSweeps)

	PGC_SetAndActivateControl(BSP_GetPanel(win), "button_Calculation_RestoreData")

	WAVE/WAVE dataWaves = GetSweepBrowserDataWaves(win)
	for(WAVE wv : dataWaves)
		WAVE/Z backup = GetBackupWave(wv)
		CHECK_WAVE(backup, NUMERIC_WAVE)
		CHECK_EQUAL_WAVES(wv, backup, mode = WAVE_DATA)
	endfor
End
