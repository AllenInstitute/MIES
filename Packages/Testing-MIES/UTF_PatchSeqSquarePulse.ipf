#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma ModuleName=PatchSeqTestSquarePulse

static Constant HEADSTAGE = 0

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(s)
	STRUCT DAQSettings& s

	string unlockedPanelTitle = DAP_CreateDAEphysPanel()

	ChooseCorrectDevice(unlockedPanelTitle, DEVICE)
	PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")

	REQUIRE(WindowExists(DEVICE))

	PGC_SetAndActivateControl(DEVICE, "ADC", val=0)
	DoUpdate/W=$DEVICE

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

	PGC_SetAndActivateControl(DEVICE, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(DEVICE, "setvar_DataAcq_AutoBiasV", val = 70)
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), val = GetStimSet("PatchSeqSquarePu_DA_0") + 1)

	PGC_SetAndActivateControl(DEVICE, "check_Settings_MD", val = s.MD)
	PGC_SetAndActivateControl(DEVICE, "Check_DataAcq1_RepeatAcq", val = s.RA)
	PGC_SetAndActivateControl(DEVICE, "Check_DataAcq_Indexing", val = s.IDX)
	PGC_SetAndActivateControl(DEVICE, "Check_DataAcq1_IndexingLocked", val = s.LIDX)
	PGC_SetAndActivateControl(DEVICE, "Check_Settings_BackgrndDataAcq", val = s.BKG_DAQ)
	PGC_SetAndActivateControl(DEVICE, "SetVar_DataAcq_SetRepeats", val = s.RES)
	PGC_SetAndActivateControl(DEVICE, "Check_Settings_SkipAnalysFuncs", val = 0)
	PGC_SetAndActivateControl(DEVICE, "Popup_Settings_SampIntMult", str = "4")

	DoUpdate/W=$DEVICE

	PGC_SetAndActivateControl(DEVICE, "DataAcquireButton")
	OpenDatabrowser()
End

static Function/WAVE GetSpikeResults_IGNORE(sweepNo)
	variable sweepNo

	string key

	WAVE numericalValues = GetLBNumericalValues(DEVICE)
	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
	return GetLastSettingEachRAC(numericalValues, sweepNo, key, HEADSTAGE, UNKNOWN_MODE)
End

static Function/WAVE GetDAScaleStepSize_IGNORE(sweepNo)
	variable sweepNo

	string key

	WAVE numericalValues = GetLBNumericalValues(DEVICE)
	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_STEPSIZE, query = 1)
	return GetLastSettingIndepEachRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
End

static Function PS_SP1()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_SQUARE_PULSE)
	// all tests fail
	wv = 0
End

static Function PS_SP1_REENTRY()

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 0)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	key =  PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDaScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, NaN)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK(!WaveExists(daScaleZero))
	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 20)

	Make/D/FREE/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000}, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(stepSizes, {100e-12, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-13)
End

static Function PS_SP2()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_SQUARE_PULSE)
	// all tests fail
	// spike before pulse, does not count
	wv = 2.5
End

static Function PS_SP2_REENTRY()

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 0)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	key =  PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDaScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, NaN)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK(!WaveExists(daScaleZero))
	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 20)

	Make/D/FREE/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000}, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(stepSizes, {100e-12, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-13)
End

static Function PS_SP3()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_SQUARE_PULSE)
	// spike detected on second sweep, but never again
	wv[]  = 0
	wv[1] = 1
End

static Function PS_SP3_REENTRY()

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 0)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	key =  PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDaScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, NaN)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, HEADSTAGE, UNKNOWN_MODE)
	CHECK(!WaveExists(daScaleZero))
	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 20)

	Make/D/FREE/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320}, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(stepSizes, {100e-12, -50e-12, 10e-12, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-13)
End

static Function PS_SP4()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_SQUARE_PULSE)
	// spike detected on second and third sweep, but never again
	wv[]    = 0
	wv[1,2] = 1
End

static Function PS_SP4_REENTRY()

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 0)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	key =  PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDaScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, NaN)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK(!WaveExists(daScaleZero))
	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 20)

	Make/D/FREE/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	CHECK_EQUAL_WAVES(stimScale, {100,200,150,100,110,120,130,140,150,160,170,180,190,200,210,220,230,240,250,260}, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(stepSizes, {100e-12, -50e-12, NaN, 10e-12, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-13)
End

static Function PS_SP5()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_SQUARE_PULSE)
	// spike detected on first and third sweep -> success
	wv[]  = 0
	wv[1] = 1
	wv[3] = 1
End

static Function PS_SP5_REENTRY()

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 4)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 3)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 1)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	key =  PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDaScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, 160e-12)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK(!WaveExists(daScaleZero))
	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 0, 1}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 4)

	Make/D/FREE/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 160}, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(stepSizes, {100e-12, -50e-12, 10e-12, NaN}, mode = WAVE_DATA, tol = 1e-13)
End

static Function PS_SP6()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_SQUARE_PULSE)
	// spike detected so that we get a DAScale zero with spike LBN entry and success
	wv[] = 0
	wv[0,2] = 1
	wv[4] = 1
End

static Function PS_SP6_REENTRY()

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 1)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDAScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, 10e-12)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, HEADSTAGE, UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(daScaleZero, {NaN, NaN, 1, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {1, 1, 1, 0, 1}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	Make/D/FREE/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	CHECK_EQUAL_WAVES(stimScale, {100, 50, 0, 0, 10}, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(stepSizes, {-50e-12, NaN, NaN, 10e-12, NaN}, mode = WAVE_DATA, tol = 1e-13)
End

static Function PS_SP7()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_SQUARE_PULSE)
	// always spikes -> failure due to DAScaleZero handling
	wv[] = 1
End

static Function PS_SP7_REENTRY()

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 0)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDAScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, NaN)

	key = PSQ_CreateLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(daScaleZero, {NaN, NaN, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	Make/D/FREE/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	CHECK_EQUAL_WAVES(stimScale, {100, 50, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(stepSizes, {-50e-12, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-13)
End
