#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=PatchSeqTestRamp

static Constant HEADSTAGE = 0

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(s)
	STRUCT DAQSettings& s

	// create an empty one so that the preDAQ analysis function can find it
	Make/N=0/O root:overrideResults

	Initialize_IGNORE()

	string unlockedPanelTitle = DAP_CreateDAEphysPanel()

	ChooseCorrectDevice(unlockedPanelTitle, DEVICE)
	PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")

	REQUIRE(WindowExists(DEVICE))

	PGC_SetAndActivateControl(DEVICE, "ADC", val=0)
	DoUpdate/W=$DEVICE

	PGC_SetAndActivateControl(DEVICE, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(DEVICE, "setvar_DataAcq_AutoBiasV", val = 70)
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "Ramp*")

	WAVE ampMCC = GetAmplifierMultiClamps()
	WAVE ampTel = GetAmplifierTelegraphServers()

	CHECK_EQUAL_VAR(DimSize(ampMCC, ROWS), 2)
	CHECK_EQUAL_VAR(DimSize(ampTel, ROWS), 2)

	// HS 0 with Amp
	PGC_SetAndActivateControl(DEVICE, "Popup_Settings_HeadStage", val = HEADSTAGE)
	PGC_SetAndActivateControl(DEVICE, "popup_Settings_Amplifier", val = 1)

	PGC_SetAndActivateControl(DEVICE, DAP_GetClampModeControl(I_CLAMP_MODE, HEADSTAGE), val=1)
	DoUpdate/W=$DEVICE

	PGC_SetAndActivateControl(DEVICE, "button_Hardware_AutoGainAndUnit")

	PGC_SetAndActivateControl(DEVICE, "check_Settings_MD", val = s.MD)
	PGC_SetAndActivateControl(DEVICE, "Check_DataAcq1_RepeatAcq", val = s.RA)
	PGC_SetAndActivateControl(DEVICE, "Check_DataAcq_Indexing", val = s.IDX)
	PGC_SetAndActivateControl(DEVICE, "Check_DataAcq1_IndexingLocked", val = s.LIDX)
	PGC_SetAndActivateControl(DEVICE, "Check_Settings_BackgrndDataAcq", val = s.BKG_DAQ)
	PGC_SetAndActivateControl(DEVICE, "SetVar_DataAcq_SetRepeats", val = s.RES)
	PGC_SetAndActivateControl(DEVICE, "Check_Settings_SkipAnalysFuncs", val = 0)
	PGC_SetAndActivateControl(DEVICE, "Popup_Settings_SampIntMult", str = "4")

	DoUpdate/W=$DEVICE

	CtrlNamedBackGround DAQWatchdog, start, period=120, proc=WaitUntilDAQDone_IGNORE
	PGC_SetAndActivateControl(DEVICE, "DataAcquireButton")
	OpenDatabrowser()
End

static Function/WAVE GetSpikePosition_IGNORE(sweepNo)
	variable sweepNo

	string key

	WAVE textualValues   = GetLBTextualValues(DEVICE)
	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_POSITIONS, query = 1)
	return GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, key, HEADSTAGE, UNKNOWN_MODE)
End

static Function/WAVE GetSpikeResults_IGNORE(sweepNo)
	variable sweepNo

	string key

	WAVE numericalValues = GetLBNumericalValues(DEVICE)
	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
	return GetLastSettingEachRAC(numericalValues, sweepNo, key, HEADSTAGE, UNKNOWN_MODE)
End

static Function/WAVE GetSweepQCResults_IGNORE(sweepNo)
	variable sweepNo

	string key

	WAVE numericalValues = GetLBNumericalValues(DEVICE)
	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	return GetLastSettingIndepEachRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
End

static Function/WAVE GetBaselineQCResults_IGNORE(sweepNo)
	variable sweepNo

	string key

	WAVE numericalValues = GetLBNumericalValues(DEVICE)
	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	return GetLastSettingEachRAC(numericalValues, sweepNo, key, HEADSTAGE, UNKNOWN_MODE)
End

static Function PS_RA_Run1()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_RAMP)
	// all tests fail, baseline QC fails and spike search inconclusive
	wv[][][0] = 0
	wv[][][1] = NaN
End

static Function PS_RA_Test1()

	variable sweepNo, setPassed, i, numEntries, DAScale, onsetDelay
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 2)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 1)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(baselineQCWave, {0, 0}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepQCWave, {0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK(!WaveExists(spikeDetectionWave))

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo)
	CHECK(!WaveExists(spikePositionWave))

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 2)

	DAScale = GetLastSetting(numericalValues, sweeps[0], STIMSET_SCALE_FACTOR_KEY, UNKNOWN_MODE)[HEADSTAGE]
	CHECK_EQUAL_VAR(DAScale, PSQ_RA_DASCALE_DEFAULT)

	// no early abort on BL QC failure
	onsetDelay = GetLastSettingIndep(numericalValues, sweepNo, "Delay onset auto", DATA_ACQUISITION_MODE) + \
				 GetLastSettingIndep(numericalValues, sweepNo, "Delay onset user", DATA_ACQUISITION_MODE)

	Make/FREE/N=(numEntries) stimSetLengths = GetLastSetting(numericalValues, sweeps[p], "Stim set length", DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/N=(numEntries) sweepLengths   = DimSize(GetSweepWave(DEVICE, sweeps[p]), ROWS)

	sweepLengths[] -= onsetDelay / DimDelta(GetSweepWave(DEVICE, sweeps[p]), ROWS)

	CHECK_EQUAL_WAVES(stimSetLengths, sweepLengths, mode = WAVE_DATA)

	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_PULSE_DUR, query = 1)
	WAVE/Z durations = GetLastSetting(numericalValues, sweeps[0], key, UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(durations, {15000, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1)
	EnsureNoAnaFuncErrors()
End

// we don't test the BL QC code path here anymore
// as that is already done in the patchseq square pulse tests

static Function PS_RA_Run2()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_RAMP)
	// baseline QC passes and no spikes at all
	wv = 0
	wv[0,2][][0] = 1
End

static Function PS_RA_Test2()

	variable sweepNo, setPassed, i, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo)
	CHECK(!WaveExists(spikePositionWave))

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 3)

	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_PULSE_DUR, query = 1)
	WAVE/Z durations = GetLastSetting(numericalValues, sweeps[0], key, UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(durations, {15000, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1)
	EnsureNoAnaFuncErrors()
End

static Function PS_RA_Run3()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_RAMP)
	// baseline QC passes and always spikes
	wv = 0
	wv[0,2][][0] = 1
	wv[0,2][][1] = 10e3
End

static Function PS_RA_Test3()

	variable sweepNo, setPassed, i, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo)
	CHECK_EQUAL_TEXTWAVES(spikePositionWave, {"10000;", "10000;", "10000;"}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 3)

	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_PULSE_DUR, query = 1)
	WAVE durations = GetLastSetting(numericalValues, sweeps[0], key, UNKNOWN_MODE)
	CHECK(durations[0] > 10000 - PSQ_RA_BL_EVAL_RANGE && durations[0] < 10000)

	WAVE durations = GetLastSetting(numericalValues, sweeps[1], key, UNKNOWN_MODE)
	CHECK(durations[0] > 10000 - PSQ_RA_BL_EVAL_RANGE && durations[0] < 10000)

	WAVE durations = GetLastSetting(numericalValues, sweeps[2], key, UNKNOWN_MODE)
	CHECK(durations[0] > 10000 - PSQ_RA_BL_EVAL_RANGE && durations[0] < 10000)
	EnsureNoAnaFuncErrors()
End

static Function PS_RA_Run4()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_RAMP)
	// baseline QC passes and first spikes, second and third not
	wv = 0
	wv[0,2][][0] = 1
	wv[][0][1]   = 10e3
End

static Function PS_RA_Test4()

	variable sweepNo, setPassed, i, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {1, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo)
	CHECK_EQUAL_TEXTWAVES(spikePositionWave, {"10000;", "", ""}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 3)

	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_PULSE_DUR, query = 1)
	WAVE durations = GetLastSetting(numericalValues, sweeps[0], key, UNKNOWN_MODE)
	CHECK(durations[0] > 10000 - PSQ_RA_BL_EVAL_RANGE && durations[0] < 10000)
	EnsureNoAnaFuncErrors()
End

static Function PS_RA_Run5()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_RAMP)
	// baseline QC passes and first spikes not, second and third does
	wv = 0
	wv[0,2][][0] = 1
	wv[][1,2][1] = 10e3
End

static Function PS_RA_Test5()

	variable sweepNo, setPassed, i, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo)
	CHECK_EQUAL_TEXTWAVES(spikePositionWave, {"", "10000;", "10000;"}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 3)

	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_PULSE_DUR, query = 1)
	WAVE durations = GetLastSetting(numericalValues, sweeps[0], key, UNKNOWN_MODE)
	CHECK(durations[0] > 15000 - PSQ_RA_BL_EVAL_RANGE)

	WAVE durations = GetLastSetting(numericalValues, sweeps[1], key, UNKNOWN_MODE)
	CHECK(durations[0] > 10000 - PSQ_RA_BL_EVAL_RANGE)

	WAVE durations = GetLastSetting(numericalValues, sweeps[2], key, UNKNOWN_MODE)
	CHECK(durations[0] > 10000 - PSQ_RA_BL_EVAL_RANGE && durations[0] < 10000)
	EnsureNoAnaFuncErrors()
End

static Function PS_RA_Run6()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_RAMP)
	// baseline QC passes and first two spike not, third does
	wv = 0
	wv[0,1][][0] = 1
	wv[][2][1]   = 10e3
End

static Function PS_RA_Test6()

	variable sweepNo, setPassed, i, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo)
	CHECK_EQUAL_TEXTWAVES(spikePositionWave, {"", "", "10000;"}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 3)

	key = PSQ_CreateLBNKey(PSQ_RAMP, PSQ_FMT_LBN_PULSE_DUR, query = 1)
	WAVE durations = GetLastSetting(numericalValues, sweeps[0], key, UNKNOWN_MODE)
	CHECK(durations[0] > 15000 - PSQ_RA_BL_EVAL_RANGE)

	WAVE durations = GetLastSetting(numericalValues, sweeps[1], key, UNKNOWN_MODE)
	CHECK(durations[0] > 15000 - PSQ_RA_BL_EVAL_RANGE)

	WAVE durations = GetLastSetting(numericalValues, sweeps[2], key, UNKNOWN_MODE)
	CHECK(durations[0] > 10000 - PSQ_RA_BL_EVAL_RANGE && durations[0] < 10000)
	EnsureNoAnaFuncErrors()
End
