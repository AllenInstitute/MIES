#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma ModuleName=PatchSeqTestRheobase

static Constant HEADSTAGE = 0

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(s, finalDAScaleFake)
	STRUCT DAQSettings& s
	variable finalDAScaleFake

	Initialize_IGNORE()

	Make/O/N=(0) root:overrideResults/Wave=overrideResults
	Note/K overrideResults
	SetNumberInWaveNote(overrideResults, PSQ_RB_FINALSCALE_FAKE_KEY, finalDaScaleFake)

	string unlockedPanelTitle = DAP_CreateDAEphysPanel()

	ChooseCorrectDevice(unlockedPanelTitle, DEVICE)
	PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")

	REQUIRE(WindowExists(DEVICE))

	PGC_SetAndActivateControl(DEVICE, "ADC", val=0)
	DoUpdate/W=$DEVICE

	PGC_SetAndActivateControl(DEVICE, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(DEVICE, "setvar_DataAcq_AutoBiasV", val = 70)
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "Rheobase*")

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

static Function/WAVE GetSpikeResults_IGNORE(sweepNo)
	variable sweepNo

	string key

	WAVE numericalValues = GetLBNumericalValues(DEVICE)
	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
	return GetLastSettingEachRAC(numericalValues, sweepNo, key, HEADSTAGE, UNKNOWN_MODE)
End

static Function/WAVE GetBaselineQCResults_IGNORE(sweepNo)
	variable sweepNo

	string key

	WAVE numericalValues = GetLBNumericalValues(DEVICE)
	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	return GetLastSettingEachRAC(numericalValues, sweepNo, key, HEADSTAGE, UNKNOWN_MODE)
End

static Function PS_RB_Run1()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, PSQ_RB_FINALSCALE_FAKE_HIGH)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_RHEOBASE)
	// all tests fail, baseline QC and alternating spike finding
	wv = 0
End

static Function PS_RB_Test1()

	variable sweepNo, setPassed, i, numEntries, onsetDelay, initialDAScale
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 15)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 14)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_INITIAL_SCALE, query = 1)
	initialDAScale = GetLastSettingIndepRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(initialDAScale, PSQ_GetFinalDAScaleFake())

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(baselineQCWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 15)

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_INITIAL_SCALE, query = 1)
	initialDAScale = GetLastSettingIndep(numericalValues, sweeps[0], key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(initialDAScale, PSQ_GetFinalDAScaleFake())

	Make/D/FREE/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]

	Make/FREE/D/N=(numEntries) stimScaleRef = PSQ_GetFinalDAScaleFake() * 1e12
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA)

	// no early abort on BL QC failure
	onsetDelay = GetLastSettingIndep(numericalValues, sweepNo, "Delay onset auto", DATA_ACQUISITION_MODE) + \
				 GetLastSettingIndep(numericalValues, sweepNo, "Delay onset user", DATA_ACQUISITION_MODE)

	Make/FREE/N=(numEntries) stimSetLengths = GetLastSetting(numericalValues, sweeps[p], "Stim set length", DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/N=(numEntries) sweepLengths   = DimSize(GetSweepWave(DEVICE, sweeps[p]), ROWS)

	sweepLengths[] -= onsetDelay / DimDelta(GetSweepWave(DEVICE, sweeps[p]), ROWS)

	CHECK_EQUAL_WAVES(stimSetLengths, sweepLengths, mode = WAVE_DATA)

	WAVE/Z durations = GetLastSetting(numericalValues, sweeps[0], PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_PULSE_DUR, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(durations, {3, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 0.01)

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_STEPSIZE, query = 1)
	setPassed = GetLastSettingIndepRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, PSQ_RB_DASCALE_STEP_LARGE)
End

// we don't test the BL QC code path here anymore
// as that is already done in the patchseq square pulse tests

static Function PS_RB_Run2()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, PSQ_RB_FINALSCALE_FAKE_HIGH)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_RHEOBASE)
	// baseline QC passes and no spikes at all
	wv = 0
	wv[0,1][][0] = 1
End

static Function PS_RB_Test2()

	variable sweepNo, setPassed, i, numEntries, onsetDelay
	variable initialDAScale
	string key

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 6)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 5)

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_INITIAL_SCALE, query = 1)
	initialDAScale = GetLastSettingIndepRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(initialDAScale, PSQ_GetFinalDAScaleFake())

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 6)

	Make/FREE/D/N=(numEntries) stimScale    = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = (p * PSQ_RB_DASCALE_STEP_LARGE + PSQ_GetFinalDAScaleFake()) * 1e12

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z durations = GetLastSetting(numericalValues, sweeps[0], PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_PULSE_DUR, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(durations, {3, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 0.01)

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_STEPSIZE, query = 1)
	setPassed = GetLastSettingIndepRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, PSQ_RB_DASCALE_STEP_LARGE)
End

static Function PS_RB_Run3()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, PSQ_RB_FINALSCALE_FAKE_HIGH)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_RHEOBASE)
	// baseline QC passes and always spikes
	wv = 0
	wv[0,1][][0] = 1
	wv[][][1]    = 1
End

static Function PS_RB_Test3()

	variable sweepNo, setPassed, i, numEntries, onsetDelay
	variable initialDAScale
	string key

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 6)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 5)

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_INITIAL_SCALE, query = 1)
	initialDAScale = GetLastSettingIndepRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(initialDAScale, PSQ_GetFinalDAScaleFake())

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 6)

	Make/FREE/D/N=(numEntries) stimScale    = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = (PSQ_GetFinalDAScaleFake() - p * PSQ_RB_DASCALE_STEP_LARGE) * 1e12

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z durations = GetLastSetting(numericalValues, sweeps[0], PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_PULSE_DUR, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(durations, {3, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 0.01)
End

static Function PS_RB_Run4()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, PSQ_RB_FINALSCALE_FAKE_HIGH)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_RHEOBASE)
	// baseline QC passes and first spikes, second not
	wv = 0
	wv[0,1][][0] = 1
	wv[][0][1]   = 1
End

static Function PS_RB_Test4()

	variable sweepNo, setPassed, i, numEntries, onsetDelay
	variable initialDAScale
	string key

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 2)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 1)

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_INITIAL_SCALE, query = 1)
	initialDAScale = GetLastSettingIndepRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(initialDAScale, PSQ_GetFinalDAScaleFake())

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {1, 0}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 2)

	Make/FREE/D/N=(numEntries) stimScale    = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = (PSQ_GetFinalDAScaleFake() - p * PSQ_RB_DASCALE_STEP_LARGE) * 1e12

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z durations = GetLastSetting(numericalValues, sweeps[0], PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_PULSE_DUR, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(durations, {3, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 0.01)

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_STEPSIZE, query = 1)
	setPassed = GetLastSettingIndepRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, PSQ_RB_DASCALE_STEP_LARGE)
End

static Function PS_RB_Run5()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, PSQ_RB_FINALSCALE_FAKE_HIGH)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_RHEOBASE)
	// baseline QC passes and first spikes not, second does
	wv = 0
	wv[0,1][][0] = 1
	wv[][1][1]   = 1
End

static Function PS_RB_Test5()

	variable sweepNo, setPassed, i, numEntries, onsetDelay
	variable initialDAScale
	string key

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 2)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 1)

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_INITIAL_SCALE, query = 1)
	initialDAScale = GetLastSettingIndepRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(initialDAScale, PSQ_GetFinalDAScaleFake())

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 2)

	Make/FREE/D/N=(numEntries) stimScale    = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = (PSQ_GetFinalDAScaleFake() + p * PSQ_RB_DASCALE_STEP_LARGE) * 1e12

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z durations = GetLastSetting(numericalValues, sweeps[0], PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_PULSE_DUR, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(durations, {3, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 0.01)

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_STEPSIZE, query = 1)
	setPassed = GetLastSettingIndepRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, PSQ_RB_DASCALE_STEP_LARGE)
End

static Function PS_RB_Run6()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, PSQ_RB_FINALSCALE_FAKE_HIGH)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_RHEOBASE)
	// baseline QC passes and first two spike not, third does
	wv = 0
	wv[0,1][][0] = 1
	wv[][2][1]   = 1
End

static Function PS_RB_Test6()

	variable sweepNo, setPassed, i, numEntries, onsetDelay
	variable initialDAScale
	string key

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 2)

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_INITIAL_SCALE, query = 1)
	initialDAScale = GetLastSettingIndepRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(initialDAScale, PSQ_GetFinalDAScaleFake())

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 3)

	Make/FREE/D/N=(numEntries) stimScale    = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = (PSQ_GetFinalDAScaleFake() + p * PSQ_RB_DASCALE_STEP_LARGE) * 1e12

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z durations = GetLastSetting(numericalValues, sweeps[0], PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_PULSE_DUR, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(durations, {3, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 0.01)

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_STEPSIZE, query = 1)
	setPassed = GetLastSettingIndepRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, PSQ_RB_DASCALE_STEP_LARGE)
End

static Function PS_RB_Run7()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, PSQ_RB_FINALSCALE_FAKE_HIGH)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_RHEOBASE)
	// frist two sweeps: baseline QC fails
	// rest:baseline QC passes
	// all: no spikes
	wv = 0
	wv[0,1][2, inf][0] = 1
End

static Function PS_RB_Test7()

	variable sweepNo, setPassed, i, numEntries, onsetDelay
	variable initialDAScale
	string key

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 9)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 8)

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_INITIAL_SCALE, query = 1)
	initialDAScale = GetLastSettingIndepRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(initialDAScale, PSQ_GetFinalDAScaleFake())

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(baselineQCWave, {0, 0, 1, 1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {NaN, NaN, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 9)

	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef
	stimScaleRef[0, 1]   = PSQ_GetFinalDAScaleFake() * 1e12
	stimScaleRef[2, inf] = (PSQ_GetFinalDAScaleFake() + (p - 2) * PSQ_RB_DASCALE_STEP_LARGE) * 1e12

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z durations = GetLastSetting(numericalValues, sweeps[0], PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_PULSE_DUR, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(durations, {3, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 0.01)

	key = PSQ_CreateLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_STEPSIZE, query = 1)
	setPassed = GetLastSettingIndepRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, PSQ_RB_DASCALE_STEP_LARGE)
End
