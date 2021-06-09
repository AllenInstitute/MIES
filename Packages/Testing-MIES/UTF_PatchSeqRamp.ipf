#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=PatchSeqTestRamp

// Time were we inject the spike
Constant SPIKE_POSITION_MS = 10000

// Maximum time we accept it
Constant SPIKE_POSITION_TEST_DELAY_MS = 10500

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(s, device)
	STRUCT DAQSettings& s
	string device

	// create an empty one so that the preDAQ analysis function can find it
	Make/N=0/O root:overrideResults

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

	PGC_SetAndActivateControl(device, "Popup_Settings_HEADSTAGE", val = 0)
	PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")

	PGC_SetAndActivateControl(device, "Popup_Settings_HEADSTAGE", val = 1)
	PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")

	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = PSQ_TEST_HEADSTAGE)
	PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", val = 1)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, PSQ_TEST_HEADSTAGE), val=1)
	DoUpdate/W=$device

	PGC_SetAndActivateControl(device, "Popup_Settings_VC_DA", str = "0")
	PGC_SetAndActivateControl(device, "Popup_Settings_IC_DA", str = "0")
	PGC_SetAndActivateControl(device, "Popup_Settings_VC_AD", str = "1")
	PGC_SetAndActivateControl(device, "Popup_Settings_IC_AD", str = "1")

	PGC_SetAndActivateControl(device, "button_Hardware_AutoGainAndUnit")

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = 70)
	PGC_SetAndActivateControl(device, GetPanelControl(PSQ_TEST_HEADSTAGE, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "Ramp*")

	PGC_SetAndActivateControl(device, "check_Settings_MD", val = s.MD)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = s.RA)
	PGC_SetAndActivateControl(device, "Check_DataAcq_Indexing", val = s.IDX)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_IndexingLocked", val = s.LIDX)
	PGC_SetAndActivateControl(device, "Check_Settings_BackgrndDataAcq", val = s.BKG_DAQ)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_SetRepeats", val = s.RES)
	PGC_SetAndActivateControl(device, "Check_Settings_SkipAnalysFuncs", val = 0)
	PGC_SetAndActivateControl(device, "Popup_Settings_SampIntMult", str = "4")

	DoUpdate/W=$device

	PGC_SetAndActivateControl(device, "DataAcquireButton")
	DB_OpenDatabrowser()
End

static Function/WAVE GetSpikePosition_IGNORE(sweepNo, device)
	variable sweepNo
	string device

	string key

	WAVE textualValues   = GetLBTextualValues(device)
	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_POSITIONS, query = 1)
	return GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
End

static Function/WAVE GetSpikeResults_IGNORE(sweepNo, device)
	variable sweepNo
	string device

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
	return GetLastSettingEachRAC(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
End

static Function/WAVE GetSweepQCResults_IGNORE(sweepNo, device)
	variable sweepNo
	string device

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	return GetLastSettingIndepEachRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
End

static Function/WAVE GetSetQCResults_IGNORE(sweepNo, device)
	variable sweepNo
	string device

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SET_PASS, query = 1)
	Make/FREE/D/N=1 val = {GetLastSettingIndepSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)}
	return val
End

static Function/WAVE GetBaselineQCResults_IGNORE(sweepNo, device)
	variable sweepNo
	string device

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	return GetLastSettingEachRAC(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
End

static Function/WAVE GetPulseDurations_IGNORE(sweepNo, device)
	variable sweepNo
	string device

	string key

	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_PULSE_DUR, query = 1)
	return GetLastSettingEachRAC(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_RA1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_RAMP)
	// all tests fail, baseline QC fails and spike search inconclusive
	wv[][][0] = 0
	wv[][][1] = NaN
End

static Function PS_RA1_REENTRY([str])
	string str

	variable sweepNo, i, numEntries, DAScale, onsetDelay

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 2)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 1)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetSetQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(setPassed, {0}, mode = WAVE_DATA)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(baselineQCWave, {0, 0}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(sweepQCWave, {0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_WAVE(spikeDetectionWave, NULL_WAVE)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo, str)
	CHECK_WAVE(spikePositionWave, NULL_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 2)

	DAScale = GetLastSetting(numericalValues, sweeps[0], STIMSET_SCALE_FACTOR_KEY, UNKNOWN_MODE)[PSQ_TEST_HEADSTAGE]
	CHECK_EQUAL_VAR(DAScale, PSQ_RA_DASCALE_DEFAULT)

	// no early abort on BL QC failure
	onsetDelay = GetLastSettingIndep(numericalValues, sweepNo, "Delay onset auto", DATA_ACQUISITION_MODE) + \
				 GetLastSettingIndep(numericalValues, sweepNo, "Delay onset user", DATA_ACQUISITION_MODE)

	Make/FREE/N=(numEntries) stimSetLengths = GetLastSetting(numericalValues, sweeps[p], "Stim set length", DATA_ACQUISITION_MODE)[PSQ_TEST_HEADSTAGE]
	Make/FREE/N=(numEntries) sweepLengths   = DimSize(GetSweepWave(str, sweeps[p]), ROWS)

	sweepLengths[] -= onsetDelay / DimDelta(GetSweepWave(str, sweeps[p]), ROWS)

	CHECK_EQUAL_WAVES(stimSetLengths, sweepLengths, mode = WAVE_DATA)

	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(durations, {15000, 15000}, mode = WAVE_DATA, tol = 1)

	CheckDashboard(str, setPassed)
End

// we don't test the BL QC code path here anymore
// as that is already done in the patchseq square pulse tests

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_RA2([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_RAMP)
	// baseline QC passes and no spikes at all
	wv = 0
	wv[0,2][][0] = 1
End

static Function PS_RA2_REENTRY([str])
	string str

	variable sweepNo, i, numEntries

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetSetQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(sweepQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo, str)
	CHECK_WAVE(spikePositionWave, NULL_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 3)

	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(durations, {15000, 15000, 15000}, mode = WAVE_DATA, tol = 1)

	CheckDashboard(str, setPassed)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_RA3([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_RAMP)
	// baseline QC passes and always spikes
	wv = 0
	wv[0,2][][0] = 1
	wv[0,2][][1] = SPIKE_POSITION_MS
End

static Function PS_RA3_REENTRY([str])
	string str

	variable sweepNo, i, numEntries

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetSetQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(sweepQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo, str)
	CHECK_EQUAL_TEXTWAVES(spikePositionWave, {"10000;", "10000;", "10000;"}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 3)

	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, str)
	CHECK(durations[0] > SPIKE_POSITION_MS - PSQ_RA_BL_EVAL_RANGE && durations[0] < SPIKE_POSITION_TEST_DELAY_MS)
	CHECK(durations[1] > SPIKE_POSITION_MS - PSQ_RA_BL_EVAL_RANGE && durations[1] < SPIKE_POSITION_TEST_DELAY_MS)
	CHECK(durations[2] > SPIKE_POSITION_MS - PSQ_RA_BL_EVAL_RANGE && durations[2] < SPIKE_POSITION_TEST_DELAY_MS)

	CheckDashboard(str, setPassed)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_RA4([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_RAMP)
	// baseline QC passes and first spikes, second and third not
	wv = 0
	wv[0,2][][0] = 1
	wv[][0][1]   = SPIKE_POSITION_MS
End

static Function PS_RA4_REENTRY([str])
	string str

	variable sweepNo, i, numEntries

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetSetQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(sweepQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {1, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo, str)
	CHECK_EQUAL_TEXTWAVES(spikePositionWave, {"10000;", "", ""}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 3)

	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, str)
	CHECK(durations[0] > SPIKE_POSITION_MS - PSQ_RA_BL_EVAL_RANGE && durations[0] < SPIKE_POSITION_TEST_DELAY_MS)
	CHECK_CLOSE_VAR(durations[1], 15000, tol = 1)
	CHECK_CLOSE_VAR(durations[2], 15000, tol = 1)

	CheckDashboard(str, setPassed)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_RA5([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_RAMP)
	// baseline QC passes and first spikes not, second and third does
	wv = 0
	wv[0,2][][0] = 1
	wv[][1,2][1] = SPIKE_POSITION_MS
End

static Function PS_RA5_REENTRY([str])
	string str

	variable sweepNo, i, numEntries

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetSetQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(sweepQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo, str)
	CHECK_EQUAL_TEXTWAVES(spikePositionWave, {"", "10000;", "10000;"}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 3)

	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, str)
	CHECK(durations[0] > 15000 - PSQ_RA_BL_EVAL_RANGE)
	CHECK(durations[1] > SPIKE_POSITION_MS - PSQ_RA_BL_EVAL_RANGE)
	CHECK(durations[2] > SPIKE_POSITION_MS - PSQ_RA_BL_EVAL_RANGE && durations[2] < SPIKE_POSITION_TEST_DELAY_MS)

	CheckDashboard(str, setPassed)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_RA6([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_RAMP)
	// baseline QC passes and first two spike not, third does
	wv = 0
	wv[0,1][][0] = 1
	wv[][2][1]   = SPIKE_POSITION_MS
End

static Function PS_RA6_REENTRY([str])
	string str

	variable sweepNo, i, numEntries

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetSetQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(sweepQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo, str)
	CHECK_EQUAL_TEXTWAVES(spikePositionWave, {"", "", "10000;"}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 3)

	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, str)
	CHECK(durations[0] > 15000 - PSQ_RA_BL_EVAL_RANGE)
	CHECK(durations[1] > 15000 - PSQ_RA_BL_EVAL_RANGE)
	CHECK(durations[2] > SPIKE_POSITION_MS - PSQ_RA_BL_EVAL_RANGE && durations[2] < SPIKE_POSITION_TEST_DELAY_MS)

	CheckDashboard(str, setPassed)
End
