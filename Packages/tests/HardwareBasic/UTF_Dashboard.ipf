#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=DashboardTests

static Function DAB_Indexing_IGNORE(string device)
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=0)

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "DashboardAnaFunc")

	ST_SetStimsetParameter("StimulusSetB_DA_0", "Analysis function (generic)", str = "")
	ST_SetStimsetParameter("StimulusSetB_DA_0", "Total number of steps", var = 2)

	OpenDatabrowser()
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function DAB_Indexing([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L0_BKG_1")
	BasicHardwareTests#AcquireData(s, str, preAcquireFunc = DAB_Indexing_IGNORE)
End

static Function DAB_Indexing_REENTRY([string str])
	variable sweepNo, index
	string win, ref, actual, bsPanel

	sweepNo = AFH_GetLastSweepAcquired(str)

	CHECK_EQUAL_VAR(sweepNo, 4)

	win = DB_GetBoundDataBrowser(str)
	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)

	WAVE/T infoWave = GetAnaFuncDashboardInfoWave(dfr)
	WAVE/T listWave = GetAnaFuncDashboardListWave(dfr)

	index = GetNumberFromWaveNote(listWave, NOTE_INDEX)
	CHECK_EQUAL_VAR(index, 2)

	// nothing is ongoing anymore
	ref    = "0"
	actual = infoWave[0][%$"Ongoing DAQ"]
	CHECK_EQUAL_STR(ref, actual)

	ref    = "0"
	actual = infoWave[1][%$"Ongoing DAQ"]
	CHECK_EQUAL_STR(ref, actual)

	ref    = "0"
	actual = infoWave[0][%$"Ongoing DAQ"]
	CHECK_EQUAL_STR(ref, actual)

	Duplicate/FREE/RMD=[0,1][] listWave, listWaveDup

	Make/FREE/T refListWaveDup = {{"StimulusSetA_DA_0", "StimulusSetB_DA_0"}, {"DashboardAnaFunc", "n/a"}, {"0", "0"}, {"Pass", "n/a"}}

	CHECK_EQUAL_TEXTWAVES(listWaveDup, refListWaveDup, mode = WAVE_DATA)

	bsPanel = BSP_GetPanel(win)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DB_Passed", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DB_Failed", val = CHECKBOX_SELECTED)

	// setA
	PGC_SetAndActivateControl(bsPanel, "list_dashboard", val = 0)

	WAVE/Z selectedSweeps = OVS_GetSelectedSweeps(win, OVS_SWEEP_SELECTION_SWEEPNO)
	CHECK_EQUAL_WAVES(selectedSweeps, {0, 1, 2})

	// setB
	PGC_SetAndActivateControl(bsPanel, "list_dashboard", val = 1)

	WAVE/Z selectedSweeps = OVS_GetSelectedSweeps(win, OVS_SWEEP_SELECTION_SWEEPNO)
	CHECK_EQUAL_WAVES(selectedSweeps, {3, 4})
End

static Function DAB_Skipping_IGNORE(string device)
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=0)

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "JustFail")

	PGC_SetAndActivateControl(device, "Check_Settings_SkipAnalysFuncs", val=CHECKBOX_SELECTED)

	OpenDatabrowser()
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function DAB_Skipping([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")
	BasicHardwareTests#AcquireData(s, str, preAcquireFunc = DAB_Skipping_IGNORE)
End

static Function DAB_Skipping_REENTRY([string str])
	variable sweepNo, index
	string win, ref, actual, bsPanel

	sweepNo = AFH_GetLastSweepAcquired(str)

	CHECK_EQUAL_VAR(sweepNo, 0)

	win = DB_GetBoundDataBrowser(str)
	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)

	WAVE/T infoWave = GetAnaFuncDashboardInfoWave(dfr)
	WAVE/T listWave = GetAnaFuncDashboardListWave(dfr)

	index = GetNumberFromWaveNote(listWave, NOTE_INDEX)
	CHECK_EQUAL_VAR(index, 1)

	Duplicate/FREE/RMD=[0][] listWave, listWaveDup

	Make/FREE/T refListWaveDup = {{"StimulusSetA_DA_0"}, {"JustFail (Skipped)"}, {"0"}, {"n/a"}}

	CHECK_EQUAL_TEXTWAVES(listWaveDup, refListWaveDup, mode = WAVE_DATA)
End
