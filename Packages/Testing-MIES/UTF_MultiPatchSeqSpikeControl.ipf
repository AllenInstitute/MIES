#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=MultiPatchSeqSpikeControl

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(s, device, [postInitializeFunc, preAcquireFunc])
	STRUCT DAQSettings& s
	string device
	FUNCREF CALLABLE_PROTO postInitializeFunc, preAcquireFunc

	if(!ParamIsDefault(postInitializeFunc))
		postInitializeFunc(device)
	endif

	string unlockedPanelTitle = DAP_CreateDAEphysPanel()

	PGC_SetAndActivateControl(unlockedPanelTitle, "popup_MoreSettings_Devices", str=device)
	PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")

	REQUIRE(WindowExists(device))

	PGC_SetAndActivateControl(device, "ADC", val=0)
	DoUpdate/W=$device

	WAVE ampMCC = GetAmplifierMultiClamps()
	WAVE ampTel = GetAmplifierTelegraphServers()

	REQUIRE_EQUAL_VAR(DimSize(ampMCC, ROWS), 2)
	REQUIRE_EQUAL_VAR(DimSize(ampTel, ROWS), 2)

	// HS 0 with Amp
	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = 0)
	PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", val = 1)
	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 0), val=1)

	// HS 1 with Amp
	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = 1)
	PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", val = 2)
	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val=1)

	DoUpdate/W=$device

	PGC_SetAndActivateControl(device, "button_Hardware_AutoGainAndUnit")

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str ="MSQ_SpikeControl_DA_0")

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str ="MSQ_SpikeControl_DA_0")

	PGC_SetAndActivateControl(device, "check_Settings_MD", val = s.MD)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = s.RA)
	PGC_SetAndActivateControl(device, "Check_DataAcq_Indexing", val = s.IDX)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_IndexingLocked", val = s.LIDX)
	PGC_SetAndActivateControl(device, "Check_Settings_BackgrndDataAcq", val = s.BKG_DAQ)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_SetRepeats", val = s.RES)
	PGC_SetAndActivateControl(device, "Check_Settings_SkipAnalysFuncs", val = 0)

	DoUpdate/W=$device

	if(!ParamIsDefault(preAcquireFunc))
		preAcquireFunc(device)
	endif

	DB_OpenDatabrowser()

	PGC_SetAndActivateControl(device, "DataAcquireButton")
End

Function TuneBrowser_IGNORE()

	string databrowser, settingsHistoryPanel

	databrowser = DB_FindDataBrowser("ITC18USB_DEV_0")
	settingsHistoryPanel = DB_GetSettingsHistoryPanel(databrowser)

	PGC_SetAndActivateControl(settingsHistoryPanel, "button_clearlabnotebookgraph")

	STRUCT WMPopupAction pa
	pa.win = settingsHistoryPanel
	pa.eventCode = 2

	pa.popStr = CreateAnaFuncLBNKey(MSQ_SPIKE_CONTROL, MSQ_FMT_LBN_SET_PASS, query = 1)
	DB_PopMenuProc_LabNotebook(pa)

	pa.popStr = CreateAnaFuncLBNKey(MSQ_SPIKE_CONTROL, MSQ_FMT_LBN_SWEEP_PASS, query = 1)
	DB_PopMenuProc_LabNotebook(pa)

	pa.popStr = CreateAnaFuncLBNKey(MSQ_SPIKE_CONTROL, MSQ_FMT_LBN_HEADSTAGE_PASS, query = 1)
	DB_PopMenuProc_LabNotebook(pa)

	pa.popStr = CreateAnaFuncLBNKey(MSQ_SPIKE_CONTROL, MSQ_FMT_LBN_RERUN_TRIAL, query = 1)
	DB_PopMenuProc_LabNotebook(pa)

	pa.popStr = CreateAnaFuncLBNKey(MSQ_SPIKE_CONTROL, MSQ_FMT_LBN_RERUN_TRIAL_EXC, query = 1)
	DB_PopMenuProc_LabNotebook(pa)

	pa.popStr = CreateAnaFuncLBNKey(MSQ_SPIKE_CONTROL, MSQ_FMT_LBN_FAILED_PULSES, query = 1)
	DB_PopMenuProc_LabNotebook(pa)

	pa.popStr = STIMSET_SCALE_FACTOR_KEY
	DB_PopMenuProc_LabNotebook(pa)

	pa.popStr = "Set sweep count"
	DB_PopMenuProc_LabNotebook(pa)
End

static Constant INDEP_EACH_SCI = 0x01
static Constant EACH_SCI       = 0x02
static Constant INDEP          = 0x04
static Constant SINGLE_SCI     = 0x08

static Function/WAVE GetResults_IGNORE(string device, variable sweepNo, string str, variable headstage, variable mode, [variable textualEntry])

	string key

	if(ParamIsDefault(textualEntry))
		textualEntry = 0
	else
		textualEntry = !!textualEntry
	endif

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE/T textualValues = GetLBTextualValues(device)

	key = CreateAnaFuncLBNKey(MSQ_SPIKE_CONTROL, str, query = 1)

	switch(mode)
		case INDEP_EACH_SCI:
			if(textualEntry)
				return GetLastSettingTextIndepEachSCI(numericalValues, textualValues, sweepNo, headstage, key, UNKNOWN_MODE)
			else
				return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
			endif
		case EACH_SCI:
			if(textualEntry)
				return GetLastSettingTextEachSCI(numericalValues, textualValues, sweepNo, key, headstage, UNKNOWN_MODE)
			else
				return GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
			endif
		case INDEP:
			CHECK_EQUAL_VAR(numtype(headstage), 2)
			if(textualEntry)
				Make/T/N=1/FREE valText = GetLastSettingTextIndep(textualValues, sweepNo, key, UNKNOWN_MODE)
				return valText
			else
				Make/D/N=1/FREE val = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
				return val
			endif
		case SINGLE_SCI:
			return GetLastSettingSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	endswitch
End

// @todo use functions like this one here for all future analysis function tests
// as that ensure that we don't forget anything and avoid code duplication
static Function [WAVE/Z setPass, WAVE/Z sweepPass, WAVE/Z headstagePass_HS0, WAVE/Z headstagePass_HS1, WAVE/Z setSweepCount_HS0, WAVE/Z setSweepCount_HS1, WAVE/Z rerunTrials_HS0, WAVE/Z rerunTrials_HS1, WAVE/Z rerunTrialsExceeded_HS0, WAVE/Z rerunTrialsExceeded_HS1, WAVE/Z stimScale_HS0, WAVE/Z stimScale_HS1, WAVE/T/Z failedPulses_HS0, WAVE/T/Z failedPulses_HS1] GetLBNEntries_IGNORE(string device, variable sweepNo)

	WAVE numericalValues = GetLBNumericalValues(device)

	WAVE/Z sweepPass = GetResults_IGNORE(device, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	WAVE/Z setPass = GetResults_IGNORE(device, sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)

	WAVE/Z setSweepCount_HS0 = GetLastSettingEachSCI(numericalValues, sweepNo, "Set Sweep Count", 0, DATA_ACQUISITION_MODE)
	WAVE/Z setSweepCount_HS1 = GetLastSettingEachSCI(numericalValues, sweepNo, "Set Sweep Count", 1, DATA_ACQUISITION_MODE)

	WAVE/Z rerunTrials_HS0 = GetResults_IGNORE(device, sweepNo, MSQ_FMT_LBN_RERUN_TRIAL, 0, EACH_SCI)
	WAVE/Z rerunTrials_HS1 = GetResults_IGNORE(device, sweepNo, MSQ_FMT_LBN_RERUN_TRIAL, 1, EACH_SCI)

	WAVE/Z rerunTrialsExceeded_HS0 = GetResults_IGNORE(device, sweepNo, MSQ_FMT_LBN_RERUN_TRIAL_EXC, 0, EACH_SCI)
	WAVE/Z rerunTrialsExceeded_HS1 = GetResults_IGNORE(device, sweepNo, MSQ_FMT_LBN_RERUN_TRIAL_EXC, 1, EACH_SCI)

	WAVE/Z headstagePass_HS0 = GetResults_IGNORE(device, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	WAVE/Z headstagePass_HS1 = GetResults_IGNORE(device, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)

	WAVE/Z stimScale_HS0 = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	WAVE/Z stimScale_HS1 = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)


	WAVE/T/Z failedPulses_HS0 = GetResults_IGNORE(device, sweepNo, MSQ_FMT_LBN_FAILED_PULSES, 0, EACH_SCI, textualEntry = 1)
	WAVE/T/Z failedPulses_HS1 = GetResults_IGNORE(device, sweepNo, MSQ_FMT_LBN_FAILED_PULSES, 1, EACH_SCI, textualEntry = 1)
End

static Function MSQ_SC1_IGNORE(device)
	string device

	WBP_AddAnalysisParameter("MSQ_SpikeControl_DA_0", "DAScaleModifier", var=1.5)
	WBP_AddAnalysisParameter("MSQ_SpikeControl_DA_0", "DAScaleOperator", str="+")
	WBP_AddAnalysisParameter("MSQ_SpikeControl_DA_0", "MaxTrials", var=2)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function MSQ_SC1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, postInitializeFunc=MSQ_SC1_IGNORE)

	WAVE wv = MSQ_CreateOverrideResults(str, 0, MSQ_SPIKE_CONTROL)

	// [sweep][headstage][pulse][region]
	wv[][][0][0, 1] = 1
	// all pulses fail
End

static Function MSQ_SC1_REENTRY([str])
	string str

	variable sweepNo
	string lbl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 4)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 3)

	WAVE/Z setPass, sweepPass, headstagePass_HS0, headstagePass_HS1, setSweepCount_HS0, setSweepCount_HS1, setSweepCount_HS0, setSweepCount_HS1
	WAVE/Z rerunTrials_HS0, rerunTrials_HS1, rerunTrialsExceeded_HS0, rerunTrialsExceeded_HS1, stimScale_HS0, stimScale_HS1
	WAVE/T/Z failedPulses_HS0, failedPulses_HS1
	[setPass, sweepPass, headstagePass_HS0, headstagePass_HS1, setSweepCount_HS0, setSweepCount_HS1, rerunTrials_HS0, rerunTrials_HS1, rerunTrialsExceeded_HS0, rerunTrialsExceeded_HS1, stimScale_HS0, stimScale_HS1, failedPulses_HS0, failedPulses_HS1] = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(setPass, {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(headstagePass_HS0, {0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(headstagePass_HS1, {0, 0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(setSweepCount_HS0, {0, 0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(setSweepCount_HS1, {0, 0, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(rerunTrials_HS0, {0, 1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(rerunTrials_HS1, {0, 1, 0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(rerunTrialsExceeded_HS0, {0, 1, NaN, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(rerunTrialsExceeded_HS1, {0, 1, NaN, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(stimScale_HS0, {1, 2.5, 4, 5.5}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(stimScale_HS1, {1, 2.5, 4, 5.5}, mode = WAVE_DATA)

	// our failed pulses are from region 0 and 1, but we only count diagonal pulses
	CHECK_EQUAL_TEXTWAVES(failedPulses_HS0, {"P0_R0;", "P0_R0;", "P0_R0;", "P0_R0;"}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(failedPulses_HS1, {"P0_R1;", "P0_R1;", "P0_R1;", "P0_R1;"}, mode = WAVE_DATA)
End

static Function MSQ_SC2_IGNORE(device)
	string device

	WBP_AddAnalysisParameter("MSQ_SpikeControl_DA_0", "DAScaleModifier", var=1.5)
	WBP_AddAnalysisParameter("MSQ_SpikeControl_DA_0", "DAScaleOperator", str="+")
	WBP_AddAnalysisParameter("MSQ_SpikeControl_DA_0", "MaxTrials", var=2)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function MSQ_SC2([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, postInitializeFunc=MSQ_SC2_IGNORE)

	WAVE wv = MSQ_CreateOverrideResults(str, 0, MSQ_SPIKE_CONTROL)
	wv = 0
	// all pulses pass
End

static Function MSQ_SC2_REENTRY([str])
	string str

	variable sweepNo
	string lbl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 2)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 1)

	WAVE/Z setPass, sweepPass, headstagePass_HS0, headstagePass_HS1, setSweepCount_HS0, setSweepCount_HS1, setSweepCount_HS0, setSweepCount_HS1
	WAVE/Z rerunTrials_HS0, rerunTrials_HS1, rerunTrialsExceeded_HS0, rerunTrialsExceeded_HS1, stimScale_HS0, stimScale_HS1
	WAVE/T/Z failedPulses_HS0, failedPulses_HS1
	[setPass, sweepPass, headstagePass_HS0, headstagePass_HS1, setSweepCount_HS0, setSweepCount_HS1, rerunTrials_HS0, rerunTrials_HS1, rerunTrialsExceeded_HS0, rerunTrialsExceeded_HS1, stimScale_HS0, stimScale_HS1, failedPulses_HS0, failedPulses_HS1] = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(setPass, {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(sweepPass, {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(headstagePass_HS0, {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(headstagePass_HS1, {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(setSweepCount_HS0, {0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(setSweepCount_HS1, {0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(rerunTrials_HS0, {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(rerunTrials_HS1, {0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(rerunTrialsExceeded_HS0, {0, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(rerunTrialsExceeded_HS1, {0, NaN}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(stimScale_HS0, {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(stimScale_HS1, {1, 1}, mode = WAVE_DATA)

	CHECK_WAVE(failedPulses_HS0, NULL_WAVE)
	CHECK_WAVE(failedPulses_HS1, NULL_WAVE)
End

static Function MSQ_SC3_IGNORE(device)
	string device

	WBP_AddAnalysisParameter("MSQ_SpikeControl_DA_0", "DAScaleModifier", var=2)
	WBP_AddAnalysisParameter("MSQ_SpikeControl_DA_0", "DAScaleOperator", str="*")
	WBP_AddAnalysisParameter("MSQ_SpikeControl_DA_0", "MaxTrials", var=2)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function MSQ_SC3([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, postInitializeFunc=MSQ_SC3_IGNORE)

	WAVE wv = MSQ_CreateOverrideResults(str, 0, MSQ_SPIKE_CONTROL)

	// sweep 0, HS0: passing
	// sweep 0, HS1: passing
	// sweep 1, HS0, HS1: Two failed pulses on region 0 and 1
	// sweep 1, HS1: passing
	// sweep 2, HS0: passing
	// sweep 2, HS1: passing

	// start with passing all
	wv = 0

	// [sweep][headstage][pulse][region]
	wv[1][0][4, 5][0] = 1
	wv[1][1][4, 5][1] = 1
End

static Function MSQ_SC3_REENTRY([str])
	string str

	variable sweepNo
	string lbl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE/Z setPass, sweepPass, headstagePass_HS0, headstagePass_HS1, setSweepCount_HS0, setSweepCount_HS1, setSweepCount_HS0, setSweepCount_HS1
	WAVE/Z rerunTrials_HS0, rerunTrials_HS1, rerunTrialsExceeded_HS0, rerunTrialsExceeded_HS1, stimScale_HS0, stimScale_HS1
	WAVE/T/Z failedPulses_HS0, failedPulses_HS1
	[setPass, sweepPass, headstagePass_HS0, headstagePass_HS1, setSweepCount_HS0, setSweepCount_HS1, rerunTrials_HS0, rerunTrials_HS1, rerunTrialsExceeded_HS0, rerunTrialsExceeded_HS1, stimScale_HS0, stimScale_HS1, failedPulses_HS0, failedPulses_HS1] = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(setPass, {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(sweepPass, {1, 0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(headstagePass_HS0, {1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(headstagePass_HS1, {1, 0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(setSweepCount_HS0, {0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(setSweepCount_HS1, {0, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(rerunTrials_HS0, {0, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(rerunTrials_HS1, {0, 0, 1}, mode = WAVE_DATA)

	// the last one is 0 because of PRE_SET_EVENT called multiple times
	CHECK_EQUAL_WAVES(rerunTrialsExceeded_HS0, {0, NaN, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(rerunTrialsExceeded_HS1, {0, NaN, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(stimScale_HS0, {1, 1, 2}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(stimScale_HS1, {1, 1, 2}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(failedPulses_HS0, {"", "P4_R0;P5_R0;", ""}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(failedPulses_HS1, {"", "P4_R1;P5_R1;", ""}, mode = WAVE_DATA)
End

static Function MSQ_SC4_IGNORE(device)
	string device

	WBP_AddAnalysisParameter("MSQ_SpikeControl_DA_0", "DAScaleModifier", var=2)
	WBP_AddAnalysisParameter("MSQ_SpikeControl_DA_0", "DAScaleOperator", str="*")
	WBP_AddAnalysisParameter("MSQ_SpikeControl_DA_0", "MaxTrials", var=3)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function MSQ_SC4([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, postInitializeFunc=MSQ_SC4_IGNORE)

	WAVE wv = MSQ_CreateOverrideResults(str, 0, MSQ_SPIKE_CONTROL)

	// sweep 0, HS0: One failed pulse on region 0
	// sweep 0, HS1: passing

	// sweep 1, HS0: passing
	// sweep 1, HS1: Two failed pulses on region 1

	// sweep 2, HS0: passing
	// sweep 2, HS1: passing

	// start with passing all
	wv = 0

	// [sweep][headstage][pulse][region]
	wv[0][0][3][0] = 1
	wv[1][1][4, 5][1] = 1
End

static Function MSQ_SC4_REENTRY([str])
	string str

	variable sweepNo
	string lbl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE/Z setPass, sweepPass, headstagePass_HS0, headstagePass_HS1, setSweepCount_HS0, setSweepCount_HS1, setSweepCount_HS0, setSweepCount_HS1
	WAVE/Z rerunTrials_HS0, rerunTrials_HS1, rerunTrialsExceeded_HS0, rerunTrialsExceeded_HS1, stimScale_HS0, stimScale_HS1
	WAVE/T/Z failedPulses_HS0, failedPulses_HS1
	[setPass, sweepPass, headstagePass_HS0, headstagePass_HS1, setSweepCount_HS0, setSweepCount_HS1, rerunTrials_HS0, rerunTrials_HS1, rerunTrialsExceeded_HS0, rerunTrialsExceeded_HS1, stimScale_HS0, stimScale_HS1, failedPulses_HS0, failedPulses_HS1] = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(setPass, {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(sweepPass, {0, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(headstagePass_HS0, {0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(headstagePass_HS1, {1, 0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(setSweepCount_HS0, {0, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(setSweepCount_HS1, {0, 0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(rerunTrials_HS0, {0, 1, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(rerunTrials_HS1, {0, 1, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(rerunTrialsExceeded_HS0, {0, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(rerunTrialsExceeded_HS1, {0, NaN, NaN}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(stimScale_HS0, {1, 2, 2}, mode = WAVE_DATA)
	// 1 for the third sweep, because the second sweep passed
	CHECK_EQUAL_WAVES(stimScale_HS1, {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(failedPulses_HS0, {"P3_R0;", "", ""}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(failedPulses_HS1, {"", "P4_R1;P5_R1;", ""}, mode = WAVE_DATA)
End
