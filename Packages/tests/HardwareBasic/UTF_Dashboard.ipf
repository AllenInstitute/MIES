#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = DashboardTests

static Function DAB_Indexing_preAcq(string device)

	ST_SetStimsetParameter("StimulusSetB_DA_0", "Analysis function (generic)", str = "")
	ST_SetStimsetParameter("StimulusSetB_DA_0", "Total number of steps", var = 2)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function DAB_Indexing([string str])

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA1_I1_L0_BKG1_DB1"                                          + \
	                                                           "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:_AF:DashboardAnaFunc:" + \
	                                                           "_IST:StimulusSetB_DA_0:")

	ACD_AcquireData(s, str)
End

static Function DAB_Indexing_REENTRY([string str])

	variable sweepNo, index
	string win, ref, actual, bsPanel

	sweepNo = AFH_GetLastSweepAcquired(str)

	CHECK_EQUAL_VAR(sweepNo, 4)

	win = DB_GetBoundDataBrowser(str)
	DFREF dfr = AD_GetDashboardFolder(win)

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

	Duplicate/FREE/RMD=[0, 1][] listWave, listWaveDup

	Make/FREE/T refListWaveDup = {{"StimulusSetA_DA_0", "StimulusSetB_DA_0"}, {"DashboardAnaFunc", "n/a"}, {"0", "0"}, {"Pass", "n/a"}}

	CHECK_EQUAL_TEXTWAVES(listWaveDup, refListWaveDup, mode = WAVE_DATA)

	bsPanel = BSP_GetPanel(win)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DB_Passed", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DB_Failed", val = CHECKBOX_SELECTED)

	// setA
	PGC_SetAndActivateControl(bsPanel, "list_dashboard", val = 0, eventCode = EVENT_LISTBOXACTION_CELL_SELECTION)

	WAVE/Z selectedSweeps = OVS_GetSelectedSweeps(win, OVS_SWEEP_SELECTION_SWEEPNO)
	CHECK_EQUAL_WAVES(selectedSweeps, {0, 1, 2})

	// setB
	PGC_SetAndActivateControl(bsPanel, "list_dashboard", val = LISTBOX_CLEAR_SELECTION, eventCode = EVENT_LISTBOXACTION_CELL_SELECTION)
	PGC_SetAndActivateControl(bsPanel, "list_dashboard", val = 1, eventCode = EVENT_LISTBOXACTION_CELL_SELECTION)

	WAVE/Z selectedSweeps = OVS_GetSelectedSweeps(win, OVS_SWEEP_SELECTION_SWEEPNO)
	CHECK_EQUAL_WAVES(selectedSweeps, {3, 4})

	KillVariables/Z V_flag
End

static Function DAB_OpenDatabrowserWithDashboard(string device)

	string win

	ACD_CreateLockedDatabrowser(device)

	WAVE/T databrowsers = DB_FindAllDataBrowser(device)
	for(win : databrowsers)
		PGC_SetAndActivateControl(BSP_GetPanel(win), "check_BrowserSettings_DS", val = CHECKBOX_SELECTED)
	endfor
End

static Function DAB_CheckListWaveBinding(string win, WAVE/T listWave)

	ControlInfo/W=$BSP_GetPanel(win) list_dashboard
	WAVE/Z boundListWave = $(S_DataFolder + PossiblyQuoteName(S_Value))
	CHECK_EQUAL_VAR(WaveRefsEqual(boundListWave, listWave), 1)
End

/// @brief Check that after a change of the inputs only the first databrowser fills the data
static Function DAB_CheckFilledOnce(string win, string otherWin, WAVE/T listWave)

	variable modCount

	modCount = WaveModCount(listWave)
	AD_Update(win)
	CHECK_GT_VAR(WaveModCount(listWave), modCount)

	modCount = WaveModCount(listWave)
	AD_Update(otherWin)
	CHECK_EQUAL_VAR(WaveModCount(listWave), modCount)
End

static Function DAB_SharedData_preAcq(string device)

	ST_SetStimsetParameter("StimulusSetB_DA_0", "Analysis function (generic)", str = "")
	ST_SetStimsetParameter("StimulusSetB_DA_0", "Total number of steps", var = 2)

	DAB_OpenDatabrowserWithDashboard(device)
	DAB_OpenDatabrowserWithDashboard(device)
End

/// @brief The databrowsers of a device share the dashboard data, filled once
///        per change of its inputs, but each one has its own selection
// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function DAB_SharedData([string str])

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA1_I1_L0_BKG1_DB0"                                          + \
	                                                           "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:_AF:DashboardAnaFunc:" + \
	                                                           "_IST:StimulusSetB_DA_0:")

	ACD_AcquireData(s, str)
End

static Function DAB_SharedData_REENTRY([string str])

	variable modCount
	string win, otherWin, newWin, bsPanel, otherBsPanel

	CHECK_EQUAL_VAR(AFH_GetLastSweepAcquired(str), 4)

	// both databrowsers were open during acquisition
	WAVE/T databrowsers = DB_FindAllDataBrowser(str)
	CHECK_EQUAL_VAR(DimSize(databrowsers, ROWS), 2)
	win      = databrowsers[0]
	otherWin = databrowsers[1]

	bsPanel      = BSP_GetPanel(win)
	otherBsPanel = BSP_GetPanel(otherWin)

	CHECK_EQUAL_VAR(DataFolderRefsEqual(AD_GetDashboardFolder(win), AD_GetDashboardFolder(otherWin)), 1)

	WAVE/T listWave = GetAnaFuncDashboardListWave(AD_GetDashboardFolder(win))
	WAVE/T infoWave = GetAnaFuncDashboardInfoWave(AD_GetDashboardFolder(win))

	CHECK_EQUAL_VAR(GetNumberFromWaveNote(listWave, NOTE_INDEX), 2)
	Make/FREE/T refListWave = {{"StimulusSetA_DA_0", "StimulusSetB_DA_0"}, {"DashboardAnaFunc", "n/a"}, {"0", "0"}, {"Pass", "n/a"}}
	CHECK_EQUAL_TEXTWAVES(listWave, refListWave, mode = WAVE_DATA)
	CHECK_EQUAL_STR(infoWave[0][%$"Ongoing DAQ"], "0")
	CHECK_EQUAL_STR(infoWave[1][%$"Ongoing DAQ"], "0")

	DAB_CheckListWaveBinding(win, listWave)
	DAB_CheckListWaveBinding(otherWin, listWave)

	// a new databrowser shows the data without filling it again
	modCount = WaveModCount(listWave)
	DAB_OpenDatabrowserWithDashboard(str)
	CHECK_EQUAL_VAR(WaveModCount(listWave), modCount)

	WAVE/T databrowsers = DB_FindAllDataBrowser(str)
	CHECK_EQUAL_VAR(DimSize(databrowsers, ROWS), 3)
	for(newWin : databrowsers)
		DAB_CheckListWaveBinding(newWin, listWave)
	endfor

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DB_Passed", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DB_Failed", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(otherBsPanel, "check_BrowserSettings_DB_Passed", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(otherBsPanel, "check_BrowserSettings_DB_Failed", val = CHECKBOX_SELECTED)

	// setA
	PGC_SetAndActivateControl(bsPanel, "list_dashboard", val = 0, eventCode = EVENT_LISTBOXACTION_CELL_SELECTION)
	// setB
	PGC_SetAndActivateControl(otherBsPanel, "list_dashboard", val = 1, eventCode = EVENT_LISTBOXACTION_CELL_SELECTION)

	WAVE/Z selectedSweeps = OVS_GetSelectedSweeps(win, OVS_SWEEP_SELECTION_SWEEPNO)
	CHECK_EQUAL_WAVES(selectedSweeps, {0, 1, 2})

	WAVE/Z selectedSweeps = OVS_GetSelectedSweeps(otherWin, OVS_SWEEP_SELECTION_SWEEPNO)
	CHECK_EQUAL_WAVES(selectedSweeps, {3, 4})

	// unchanged inputs don't fill the data again
	modCount = WaveModCount(listWave)
	AD_UpdateAllDatabrowser()
	CHECK_EQUAL_VAR(WaveModCount(listWave), modCount)

	// each input makes the first databrowser fill the data, but not the second
	WAVE numericalValues = GetLBNumericalValues(str)
	numericalValues[0][0][0] = numericalValues[0][0][0]
	DAB_CheckFilledOnce(win, otherWin, listWave)

	WAVE/T textualValues = GetLBTextualValues(str)
	textualValues[0][0][0] = textualValues[0][0][0]
	DAB_CheckFilledOnce(win, otherWin, listWave)

	NVAR acqState = $GetAcquisitionState(str)
	acqState = AS_ITI
	DAB_CheckFilledOnce(win, otherWin, listWave)

	acqState = AS_INACTIVE
	DAB_CheckFilledOnce(otherWin, win, listWave)

	// the selections survive filling the data
	WAVE/Z selectedSweeps = OVS_GetSelectedSweeps(win, OVS_SWEEP_SELECTION_SWEEPNO)
	CHECK_EQUAL_WAVES(selectedSweeps, {0, 1, 2})

	WAVE/Z selectedSweeps = OVS_GetSelectedSweeps(otherWin, OVS_SWEEP_SELECTION_SWEEPNO)
	CHECK_EQUAL_WAVES(selectedSweeps, {3, 4})

	// disabling the dashboard in one databrowser keeps the data of the other
	PGC_SetAndActivateControl(otherBsPanel, "check_BrowserSettings_DS", val = CHECKBOX_UNSELECTED)
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(listWave, NOTE_INDEX), 2)
	CHECK_EQUAL_VAR(DimSize(listWave, ROWS), 2)

	ControlInfo/W=$otherBsPanel list_dashboard
	CHECK_EMPTY_STR(S_Value)

	DAB_CheckListWaveBinding(win, listWave)

	KillVariables/Z V_flag
End

static Function DAB_Skipping_preAcq(string device)

	PGC_SetAndActivateControl(device, "Check_Settings_SkipAnalysFuncs", val = CHECKBOX_SELECTED)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function DAB_Skipping([string str])

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_DB1"                                  + \
	                                                           "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:_AF:JustFail:" + \
	                                                           "_IST:StimulusSetB_DA_0:")

	ACD_AcquireData(s, str)
End

static Function DAB_Skipping_REENTRY([string str])

	variable sweepNo, index
	string win, ref, actual, bsPanel

	sweepNo = AFH_GetLastSweepAcquired(str)

	CHECK_EQUAL_VAR(sweepNo, 0)

	win = DB_GetBoundDataBrowser(str)
	DFREF dfr = AD_GetDashboardFolder(win)

	WAVE/T infoWave = GetAnaFuncDashboardInfoWave(dfr)
	WAVE/T listWave = GetAnaFuncDashboardListWave(dfr)

	index = GetNumberFromWaveNote(listWave, NOTE_INDEX)
	CHECK_EQUAL_VAR(index, 1)

	Duplicate/FREE/RMD=[0][] listWave, listWaveDup

	Make/FREE/T refListWaveDup = {{"StimulusSetA_DA_0"}, {"JustFail (Skipped)"}, {"0"}, {"n/a"}}

	CHECK_EQUAL_TEXTWAVES(listWaveDup, refListWaveDup, mode = WAVE_DATA)
End
