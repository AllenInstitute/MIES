#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = PatchSeqTestSquarePulse

static Function [STRUCT DAQSettings s] PS_GetDAQSettings(string device)

	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_DB1"                                                        + \
	                             "__HS" + num2str(PSQ_TEST_HEADSTAGE) + "_DA0_AD0_CM:IC:_ST:PatchSeqSquarePu_DA_0:")

	return [s]
End

static Function GlobalPreAcq(string device)

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = 70)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = 25)
End

static Function GlobalPreInit(string device)

	AdjustAnalysisParamsForPSQ(device, "PatchSeqSquarePu_DA_0")
	PrepareForPublishTest()
End

static Function/WAVE GetSpikeResults_IGNORE(variable sweepNo, string device)

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
	return GetLastSettingEachRAC(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
End

static Function/WAVE GetDAScaleStepSize_IGNORE(variable sweepNo, string device)

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_STEPSIZE, query = 1)
	return GetLastSettingIndepEachRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
End

static Function/WAVE GetSamplingIntervalQCResults_IGNORE(variable sweepNo, string device)

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SAMPLING_PASS, query = 1)
	return GetLastSettingIndepEachRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
End

static Function/WAVE GetAsyncQCResults_IGNORE(variable sweepNo, string device)

	string key

	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_ASYNC_PASS, query = 1)
	return GetLastSettingIndepEachRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
End

static Function/WAVE GetStimScaleFactor_IGNORE(variable sweepNo, string device)

	WAVE numericalValues = GetLBNumericalValues(device)

	return GetLastSettingEachRAC(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
End

static Function/WAVE GetOORDAScale_IGNORE(variable sweepNo, string device)

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_DASCALE_OOR, query = 1)
	return GetLastSettingEachRAC(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
End

static Function PS_SP1_preAcq(string device)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqSquarePu_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function PS_SP1([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SQUARE_PULSE)
	// all tests fail
	wv = 0
End

static Function PS_SP1_REENTRY([string str])

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries
	string key

	sweepNo = 19

	WAVE numericalValues = GetLBNumericalValues(str)

	key         = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 0)

	key       = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	key          = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDaScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, NaN)

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK(!WaveExists(daScaleZero))
	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetStimScaleFactor_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000}, tol = 1e-14, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stepSizes, {100e-12, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-13)

	WAVE/Z oorDAScale = GetOORDAScale_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {setPassed})
	Make/FREE/N=0 chunkTimes
	CheckPSQChunkTimes(str, chunkTimes)
End

static Function PS_SP2_preAcq(string device)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqSquarePu_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function PS_SP2([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SQUARE_PULSE)
	// spike before pulse, does not count
	wv[][][0] = 2.5
	wv[][][1] = 1
End

static Function PS_SP2_REENTRY([string str])

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries
	string key

	sweepNo = 19

	WAVE numericalValues = GetLBNumericalValues(str)

	key         = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 0)

	key       = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	key          = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDaScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, NaN)

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK(!WaveExists(daScaleZero))
	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetStimScaleFactor_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000}, tol = 1e-14, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stepSizes, {100e-12, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-13)

	WAVE/Z oorDAScale = GetOORDAScale_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {setPassed})
	Make/FREE/N=0 chunkTimes
	CheckPSQChunkTimes(str, chunkTimes)
End

static Function PS_SP3_preAcq(string device)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqSquarePu_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function PS_SP3([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SQUARE_PULSE)
	// spike detected on second sweep, but never again
	wv[][][0]  = 0
	wv[][1][0] = 1
	wv[][][1]  = 1
End

static Function PS_SP3_REENTRY([string str])

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries
	string key

	sweepNo = 19

	WAVE numericalValues = GetLBNumericalValues(str)

	key         = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 0)

	key       = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	key          = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDaScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, NaN)

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
	CHECK(!WaveExists(daScaleZero))
	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetStimScaleFactor_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320}, tol = 1e-14, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stepSizes, {100e-12, -50e-12, 10e-12, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-13)

	WAVE/Z oorDAScale = GetOORDAScale_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {setPassed})
	Make/FREE/N=0 chunkTimes
	CheckPSQChunkTimes(str, chunkTimes)
End

static Function PS_SP4_preAcq(string device)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqSquarePu_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function PS_SP4([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SQUARE_PULSE)
	// spike detected on second and third sweep, but never again
	wv[][][0]     = 0
	wv[][1, 2][0] = 1
	wv[][][1]     = 1
End

static Function PS_SP4_REENTRY([string str])

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries
	string key

	sweepNo = 19

	WAVE numericalValues = GetLBNumericalValues(str)

	key         = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 0)

	key       = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	key          = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDaScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, NaN)

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK(!WaveExists(daScaleZero))
	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetStimScaleFactor_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260}, tol = 1e-14, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stepSizes, {100e-12, -50e-12, NaN, 10e-12, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-13)

	WAVE/Z oorDAScale = GetOORDAScale_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {setPassed})
	Make/FREE/N=0 chunkTimes
	CheckPSQChunkTimes(str, chunkTimes)
End

static Function PS_SP5_preAcq(string device)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqSquarePu_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function PS_SP5([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SQUARE_PULSE)
	// spike detected on first and third sweep -> success
	wv[]       = 0
	wv[][1][0] = 1
	wv[][3][0] = 1
	wv[][][1]  = 1
End

static Function PS_SP5_REENTRY([string str])

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries
	string key

	sweepNo = 3

	WAVE numericalValues = GetLBNumericalValues(str)

	key         = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 1)

	key       = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {1, 1, 1, 1}, mode = WAVE_DATA)

	key          = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDaScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, 160e-12)

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK(!WaveExists(daScaleZero))
	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 0, 1}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetStimScaleFactor_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 160}, tol = 1e-14, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stepSizes, {100e-12, -50e-12, 10e-12, NaN}, mode = WAVE_DATA, tol = 1e-13)

	WAVE/Z oorDAScale = GetOORDAScale_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {setPassed})
	Make/FREE/N=0 chunkTimes
	CheckPSQChunkTimes(str, chunkTimes)
End

static Function PS_SP6_preAcq(string device)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqSquarePu_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function PS_SP6([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SQUARE_PULSE)
	// spike detected so that we get a DAScale zero with spike LBN entry and success
	wv[]          = 0
	wv[][0, 2][0] = 1
	wv[][4][0]    = 1
	wv[][][1]     = 1
End

static Function PS_SP6_REENTRY([string str])

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries
	string key

	sweepNo = 4

	WAVE numericalValues = GetLBNumericalValues(str)

	key         = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 1)

	key       = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	key          = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDAScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, 10e-12)

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(daScaleZero, {NaN, NaN, 1, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {1, 1, 1, 0, 1}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetStimScaleFactor_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stimScale, {100, 50, 0, 0, 10}, tol = 1e-14, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stepSizes, {-50e-12, NaN, NaN, 10e-12, NaN}, mode = WAVE_DATA, tol = 1e-13)

	WAVE/Z oorDAScale = GetOORDAScale_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, NaN, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {setPassed})
	Make/FREE/N=0 chunkTimes
	CheckPSQChunkTimes(str, chunkTimes)
End

static Function PS_SP7_preAcq(string device)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqSquarePu_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function PS_SP7([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SQUARE_PULSE)
	// always spikes -> failure due to DAScaleZero handling
	wv[][][0] = 1
	wv[][][1] = 1
End

static Function PS_SP7_REENTRY([string str])

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries
	string key

	sweepNo = 4

	WAVE numericalValues = GetLBNumericalValues(str)

	key         = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 0)

	key       = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	key          = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDAScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, NaN)

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(daScaleZero, {NaN, NaN, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetStimScaleFactor_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stimScale, {100, 50, 0, 0, 0}, tol = 1e-14, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stepSizes, {-50e-12, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-13)

	WAVE/Z oorDAScale = GetOORDAScale_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, NaN, NaN, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {setPassed})
	Make/FREE/N=0 chunkTimes
	CheckPSQChunkTimes(str, chunkTimes)
End

static Function PS_SP8_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqSquarePu_DA_0", "SamplingFrequency", var = 10)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqSquarePu_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// Same as PS_SP1 but with failing sampling interval check
//
// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function PS_SP8([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SQUARE_PULSE)
	// all tests fail
	wv[][][0] = 0
	wv[][][1] = 1
End

static Function PS_SP8_REENTRY([string str])

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries
	string key

	sweepNo = 0

	WAVE numericalValues = GetLBNumericalValues(str)

	key         = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 0)

	key       = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {0}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {1}, mode = WAVE_DATA)

	key          = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDaScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, NaN)

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK(!WaveExists(daScaleZero))
	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetStimScaleFactor_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stimScale, {100}, tol = 1e-14, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stepSizes, {100e-12}, mode = WAVE_DATA, tol = 1e-13)

	WAVE/Z oorDAScale = GetOORDAScale_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(oorDAScale, {0}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {setPassed})
	Make/FREE/N=0 chunkTimes
	CheckPSQChunkTimes(str, chunkTimes)
End

static Function PS_SP9_preAcq(string device)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqSquarePu_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// Same as PS_SP1 but with failing async QC
//
// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function PS_SP9([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SQUARE_PULSE)
	// all tests fail
	wv[][][0] = 0
	wv[][][1] = 0
End

static Function PS_SP9_REENTRY([string str])

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries
	string key

	sweepNo = 19

	WAVE numericalValues = GetLBNumericalValues(str)

	key         = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 0)

	key       = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	key          = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDaScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, NaN)

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK(!WaveExists(daScaleZero))
	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetStimScaleFactor_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000}, tol = 1e-14, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(stepSizes, {100e-12, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-13)

	WAVE/Z oorDAScale = GetOORDAScale_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {setPassed})
	Make/FREE/N=0 chunkTimes
	CheckPSQChunkTimes(str, chunkTimes)
End

static Function PS_SP10_preAcq(string device)

	ST_SetStimsetParameter("PatchSeqSquarePu_DA_0", "Total number of steps", var = 50)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqSquarePu_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function PS_SP10([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SQUARE_PULSE)
	// no spikes
	wv[][][0] = 0
	wv[][][1] = 1
End

static Function PS_SP10_REENTRY([string str])

	variable sweepNo, sweepPassed, setPassed, finalDAScale, numEntries, numEntriesRef
	string key

#ifdef TESTS_WITH_NI_HARDWARE
	sweepNo       = 38
	numEntriesRef = sweepNo + 1
#else
	sweepNo       = 39
	numEntriesRef = sweepNo + 1
#endif // TESTS_WITH_NI_HARDWARE

	WAVE numericalValues = GetLBNumericalValues(str)

	key         = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepPassed, 0)

	key       = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	Make/FREE/N=(numEntriesRef) samplingIntervalQCWaveRef = 1
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, samplingIntervalQCWaveRef, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	Make/FREE/N=(numEntriesRef) asyncQCWaveRef = 1
	CHECK_EQUAL_WAVES(asyncQCWave, asyncQCWaveRef, mode = WAVE_DATA)

	key          = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
	finalDaScale = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(finalDAScale, NaN)

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z daScaleZero = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK(!WaveExists(daScaleZero))
	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	Make/FREE/N=(numEntriesRef) spikeDetectionWaveRef = 0
	CHECK_EQUAL_WAVES(spikeDetectionWave, spikeDetectionWaveRef, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, numEntriesRef)

	WAVE/Z stimScale = GetStimScaleFactor_IGNORE(sweepNo, str)
	Make/FREE/N=(numEntriesRef) stimScaleRef = 100 * (p + 1)
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, tol = 1e-14, mode = WAVE_DATA)

	WAVE/Z stepSizes = GetDAScaleStepSize_IGNORE(sweepNo, str)
	Make/FREE/N=(numEntriesRef) stepSizesRef = NaN
	stepSizesRef[0] = 100e-12
	CHECK_EQUAL_WAVES(stepSizes, stepSizesRef, mode = WAVE_DATA, tol = 1e-13)

	WAVE/Z oorDAScale = GetOORDAScale_IGNORE(sweepNo, str)
	Make/FREE/N=(numEntriesRef) oorDAScaleRef = 0
	oorDAScaleRef[Inf] = 1
	CHECK_EQUAL_WAVES(oorDAScale, oorDAScaleRef, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {setPassed})
	Make/FREE/N=0 chunkTimes
	CheckPSQChunkTimes(str, chunkTimes)
End
