#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=PatchSeqTestRamp

// Time were we inject the spike
static Constant SPIKE_POSITION_MS = 10000

// Maximum time we accept it
static Constant SPIKE_POSITION_TEST_DELAY_MS = 10500

static Function [STRUCT DAQSettings s] PS_GetDAQSettings(string device)

	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_DB1"                                            + \
	                             "__HS" + num2str(PSQ_TEST_HEADSTAGE) + "_DA0_AD0_CM:IC:_ST:Ramp_DA_0:")

	return [s]
End

static Function GlobalPreAcq(string device)
	variable ret

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = 70)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = 25)
End

static Function GlobalPreInit(string device)

	AdjustAnalysisParamsForPSQ(device, "Ramp_DA_0")
	PrepareForPublishTest()
End

static Function/WAVE GetSpikePosition_IGNORE(sweepNo, device)
	variable sweepNo
	string   device

	string key

	WAVE textualValues   = GetLBTextualValues(device)
	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_POSITIONS, query = 1)
	return GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
End

static Function/WAVE GetSpikeResults_IGNORE(sweepNo, device)
	variable sweepNo
	string   device

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
	return GetLastSettingEachRAC(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
End

static Function/WAVE GetSweepQCResults_IGNORE(sweepNo, device)
	variable sweepNo
	string   device

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	return GetLastSettingIndepEachRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
End

static Function/WAVE GetSetQCResults_IGNORE(sweepNo, device)
	variable sweepNo
	string   device

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SET_PASS, query = 1)
	Make/FREE/D/N=1 val = {GetLastSettingIndepSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)}
	return val
End

static Function/WAVE GetBaselineQCResults_IGNORE(sweepNo, device)
	variable sweepNo
	string   device

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	return GetLastSettingEachRAC(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
End

static Function/WAVE GetPulseDurations_IGNORE(sweepNo, device)
	variable sweepNo
	string   device

	string key

	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_PULSE_DUR, query = 1)
	return GetLastSettingEachRAC(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
End

static Function/WAVE GetStimsetLengths_IGNORE(sweepNo, device)
	variable sweepNo
	string   device

	WAVE numericalValues = GetLBNumericalValues(device)

	return GetLastSettingEachRAC(numericalValues, sweepNo, "Stim set length", PSQ_TEST_HEADSTAGE, DATA_ACQUISITION_MODE)
End

static Function/WAVE GetStimScaleFactor_IGNORE(sweepNo, device)
	variable sweepNo
	string   device

	WAVE numericalValues = GetLBNumericalValues(device)

	return GetLastSettingEachRAC(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, PSQ_TEST_HEADSTAGE, DATA_ACQUISITION_MODE)
End

static Function/WAVE GetUserEpochs_IGNORE(sweepNo, device)
	variable sweepNo
	string   device

	variable i, j, numEntries, numEpochs

	WAVE textualValues   = GetLBTextualValues(device)
	WAVE numericalValues = GetLBNumericalValues(device)

	WAVE/T/Z results = GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, EPOCHS_ENTRY_KEY, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
	CHECK_WAVE(results, TEXT_WAVE)

	// now filter out the user epochs
	numEntries = DimSize(results, ROWS)
	for(i = 0; i < numEntries; i += 1)
		WAVE/T/Z epochWave = EP_EpochStrToWave(results[i])
		CHECK_WAVE(epochWave, TEXT_WAVE)

		numEpochs = DimSize(epochWave, ROWS)
		for(j = numEpochs - 1; j >= 0; j -= 1)
			if(!GrepString(epochWave[j][EPOCH_COL_TAGS], "ShortName=" + EPOCH_SHORTNAME_USER_PREFIX))
				DeletePoints j, 1, epochWave
			endif
		endfor

		results[i] = TextWaveToList(epochWave, EPOCH_LIST_ROW_SEP, colSep = EPOCH_LIST_COL_SEP, stopOnEmpty = 1)
	endfor

	return results
End

static Function/WAVE FindUserEpochs(WAVE/T userEpochs)

	// RA_DS is present for all hardware types
	Make/FREE/N=(DimSize(userEpochs, ROWS)) foundIt = (strsearch(userEpochs[p], "RA_DS", 0) >= 0)
	return foundIt
End

static Function/WAVE GetSamplingIntervalQCResults_IGNORE(sweepNo, device)
	variable sweepNo
	string   device

	string key

	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SAMPLING_PASS, query = 1)
	return GetLastSettingIndepEachRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
End

static Function/WAVE GetAsyncQCResults_IGNORE(sweepNo, device)
	variable sweepNo
	string   device

	string key

	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_ASYNC_PASS, query = 1)
	return GetLastSettingIndepEachRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
End

/// @brief Retrieve the time interval for the post baseline chunk interval
///        Based on code from @sa PSQ_EvaluateBaselineProperties
static Function [variable start, variable stop] GetPostBaseLineInterval(string dev, variable sweepNo, variable chunk)

	variable chunkStartTimeMax, chunkLengthTime, totalOnsetDelay

	STRUCT PSQ_PulseSettings s
	MIES_PSQ#PSQ_GetPulseSettingsForType(PSQ_RAMP, s)

	totalOnsetDelay = GetTotalOnsetDelayFromDevice(dev)
	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, dev)

	chunkStartTimeMax = (totalOnsetDelay + s.prePulseChunkLength + durations[sweepNo]) + chunk * s.postPulseChunkLength
	chunkLengthTime   = s.postPulseChunkLength

	return [chunkStartTimeMax, chunkStartTimeMax + chunkLengthTime]
End

static Function PS_RA1_preAcq(string device)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("Ramp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_RA1([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_RAMP)
	// all tests fail, baseline QC fails, spike search inconclusive, async QC passes
	wv[][][0] = 0
	wv[][][1] = NaN
	wv[][][2] = 0
End

static Function PS_RA1_REENTRY([str])
	string str

	variable sweepNo, i, numEntries, DAScale, onsetDelay

	sweepNo = 1

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetSetQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(setPassed, {0}, mode = WAVE_DATA)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(baselineQCWave, {0, 0}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(sweepQCWave, {0, 0}, mode = WAVE_DATA)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_WAVE(spikeDetectionWave, NULL_WAVE)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo, str)
	CHECK_WAVE(spikePositionWave, NULL_WAVE)

	WAVE/T/Z userEpochs = GetUserEpochs_IGNORE(sweepNo, str)
	CHECK_WAVE(userEpochs, TEXT_WAVE)

	WAVE/Z foundUserEpochs = FindUserEpochs(userEpochs)
	CHECK_WAVE(foundUserEpochs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(foundUserEpochs, {0, 0})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 2)

	WAVE/Z DAScaleWave = GetStimscaleFactor_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(DAScaleWave, {PSQ_RA_DASCALE_DEFAULT, PSQ_RA_DASCALE_DEFAULT}, mode = WAVE_DATA)

	// no early abort on BL QC failure
	onsetDelay = GetTotalOnsetDelay(numericalValues, sweepNo)

	WAVE/Z stimSetLengths = GetStimsetLengths_IGNORE(sweepNo, str)

	Make/FREE/N=(numEntries) sweepLengths
	for(i = 0; i < numEntries; i += 1)
		WAVE sweepT  = GetSweepWave(str, sweeps[i])
		WAVE channel = ResolveSweepChannel(sweepT, 0)
		sweepLengths[i] = DimSize(channel, ROWS) - onsetDelay / DimDelta(channel, ROWS)
	endfor
	CHECK_EQUAL_WAVES(stimSetLengths, sweepLengths, mode = WAVE_DATA)

	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(durations, {15000, 15000}, mode = WAVE_DATA, tol = 1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520})
End

static Function PS_RA2_preAcq(string device)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("Ramp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_RA2([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_RAMP)
	// baseline QC passes, no spikes at all, async QC passes
	wv            = 0
	wv[0, 2][][0] = 1
	wv[][][2]     = 1
End

static Function PS_RA2_REENTRY([str])
	string str

	variable sweepNo, i, numEntries

	sweepNo = 2

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetSetQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(sweepQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo, str)
	CHECK_WAVE(spikePositionWave, NULL_WAVE)

	WAVE/T/Z userEpochs = GetUserEpochs_IGNORE(sweepNo, str)
	CHECK_WAVE(userEpochs, TEXT_WAVE)

	WAVE/Z foundUserEpochs = FindUserEpochs(userEpochs)
	CHECK_WAVE(foundUserEpochs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(foundUserEpochs, {0, 0, 0})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 3)

	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(durations, {15000, 15000, 15000}, mode = WAVE_DATA, tol = 1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 16020, 16520})
End

static Function PS_RA2a_preAcq(string device)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("Ramp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_RA2a([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_RAMP)
	// the duration will change midsweep, so we will have more chunks in the end
	Redimension/N=(16, -1, -1, -1) wv

	// pre pulse baseline QC passes, post pulse always fails
	// one spike
	// async QC passes
	wv         = 0
	wv[0][][0] = 1
	wv[0][][1] = SPIKE_POSITION_MS
	wv[][][2]  = 1
End

static Function PS_RA2a_REENTRY([str])
	string str

	variable sweepNo, i, numEntries, chunkStart, chunkEnd

	sweepNo = 1

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetSetQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(setPassed, {0}, mode = WAVE_DATA)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(baselineQCWave, {0, 0}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(sweepQCWave, {0, 0}, mode = WAVE_DATA)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {1, 1}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo, str)
	CHECK_EQUAL_TEXTWAVES(spikePositionWave, {"10000;", "10000;"}, mode = WAVE_DATA)

	WAVE/T/Z userEpochs = GetUserEpochs_IGNORE(sweepNo, str)
	CHECK_WAVE(userEpochs, TEXT_WAVE)

	WAVE/Z foundUserEpochs = FindUserEpochs(userEpochs)
	CHECK_WAVE(foundUserEpochs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(foundUserEpochs, {1, 1})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 2)

	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, str)
	if(TestHelperFunctions#DoInstrumentation())
		CHECK_WAVE(durations, NUMERIC_WAVE)
	else
		CHECK_GT_VAR(durations[0], SPIKE_POSITION_MS - PSQ_BL_EVAL_RANGE)
		CHECK_LT_VAR(durations[0], SPIKE_POSITION_TEST_DELAY_MS)
		CHECK_GT_VAR(durations[1], SPIKE_POSITION_MS - PSQ_BL_EVAL_RANGE)
		CHECK_LT_VAR(durations[1], SPIKE_POSITION_TEST_DELAY_MS)
	endif

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)

	Make/FREE/D/N=(16 * 2) chunkTimes
	chunkTimes[0] = 20
	chunkTimes[1] = 520

	for(i = 1; i < 16; i += 1)
		[chunkStart, chunkEnd] = GetPostBaseLineInterval(str, 0, i)

		chunkTimes[2 * i]     = chunkStart
		chunkTimes[2 * i + 1] = chunkEnd
	endfor

	CheckPSQChunkTimes(str, chunkTimes, sweep = 0)
End

static Function PS_RA3_preAcq(string device)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("Ramp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_RA3([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_RAMP)
	// baseline QC passes, always spikes, async QC passes
	wv            = 0
	wv[0, 2][][0] = 1
	wv[0, 2][][1] = SPIKE_POSITION_MS
	wv[][][2]     = 1
End

static Function PS_RA3_REENTRY([str])
	string str

	variable sweepNo, i, numEntries
	variable chunkStart, chunkEnd

	sweepNo = 2

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetSetQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(sweepQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo, str)
	CHECK_EQUAL_TEXTWAVES(spikePositionWave, {"10000;", "10000;", "10000;"}, mode = WAVE_DATA)

	WAVE/T/Z userEpochs = GetUserEpochs_IGNORE(sweepNo, str)
	CHECK_WAVE(userEpochs, TEXT_WAVE)

	WAVE/Z foundUserEpochs = FindUserEpochs(userEpochs)
	CHECK_WAVE(foundUserEpochs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(foundUserEpochs, {1, 1, 1})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 3)

	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, str)
	if(TestHelperFunctions#DoInstrumentation())
		CHECK_WAVE(durations, NUMERIC_WAVE)
	else
		CHECK_GT_VAR(durations[0], SPIKE_POSITION_MS - PSQ_BL_EVAL_RANGE)
		CHECK_LT_VAR(durations[0], SPIKE_POSITION_TEST_DELAY_MS)
		CHECK_GT_VAR(durations[1], SPIKE_POSITION_MS - PSQ_BL_EVAL_RANGE)
		CHECK_LT_VAR(durations[1], SPIKE_POSITION_TEST_DELAY_MS)
		CHECK_GT_VAR(durations[2], SPIKE_POSITION_MS - PSQ_BL_EVAL_RANGE)
		CHECK_LT_VAR(durations[2], SPIKE_POSITION_TEST_DELAY_MS)
	endif

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	[chunkStart, chunkEnd] = GetPostBaseLineInterval(str, 0, 1)
	CheckPSQChunkTimes(str, {20, 520, chunkStart, chunkEnd}, sweep = 0)
	[chunkStart, chunkEnd] = GetPostBaseLineInterval(str, 1, 1)
	CheckPSQChunkTimes(str, {20, 520, chunkStart, chunkEnd}, sweep = 1)
	[chunkStart, chunkEnd] = GetPostBaseLineInterval(str, 2, 1)
	CheckPSQChunkTimes(str, {20, 520, chunkStart, chunkEnd}, sweep = 2)
End

static Function PS_RA4_preAcq(string device)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("Ramp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_RA4([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_RAMP)
	// baseline QC passes and first spikes, second and third not, async QC passes
	wv            = 0
	wv[0, 2][][0] = 1
	wv[][0][1]    = SPIKE_POSITION_MS
	wv[][][2]     = 1
End

static Function PS_RA4_REENTRY([str])
	string str

	variable sweepNo, i, numEntries
	variable chunkStart, chunkEnd

	sweepNo = 2

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetSetQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(sweepQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {1, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo, str)
	CHECK_EQUAL_TEXTWAVES(spikePositionWave, {"10000;", "", ""}, mode = WAVE_DATA)

	WAVE/T/Z userEpochs = GetUserEpochs_IGNORE(sweepNo, str)
	CHECK_WAVE(userEpochs, TEXT_WAVE)

	WAVE/Z foundUserEpochs = FindUserEpochs(userEpochs)
	CHECK_WAVE(foundUserEpochs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(foundUserEpochs, {1, 0, 0})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 3)

	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, str)
	if(TestHelperFunctions#DoInstrumentation())
		CHECK_WAVE(durations, NUMERIC_WAVE)
	else
		CHECK_GT_VAR(durations[0], SPIKE_POSITION_MS - PSQ_BL_EVAL_RANGE)
		CHECK_LT_VAR(durations[0], SPIKE_POSITION_TEST_DELAY_MS)
		CHECK_CLOSE_VAR(durations[1], 15000, tol = 1)
		CHECK_CLOSE_VAR(durations[2], 15000, tol = 1)
	endif

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	[chunkStart, chunkEnd] = GetPostBaseLineInterval(str, 0, 1)
	CheckPSQChunkTimes(str, {20, 520, chunkStart, chunkEnd}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520, 16020, 16520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520, 16020, 16520}, sweep = 2)
End

static Function PS_RA5_preAcq(string device)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("Ramp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_RA5([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_RAMP)
	// baseline QC passes and first spikes not, second and third does, async QC passes
	wv            = 0
	wv[0, 2][][0] = 1
	wv[][1, 2][1] = SPIKE_POSITION_MS
	wv[][][2]     = 1
End

static Function PS_RA5_REENTRY([str])
	string str

	variable sweepNo, i, numEntries
	variable chunkStart, chunkEnd

	sweepNo = 2

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetSetQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(sweepQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo, str)
	CHECK_EQUAL_TEXTWAVES(spikePositionWave, {"", "10000;", "10000;"}, mode = WAVE_DATA)

	WAVE/T/Z userEpochs = GetUserEpochs_IGNORE(sweepNo, str)
	CHECK_WAVE(userEpochs, TEXT_WAVE)

	WAVE/Z foundUserEpochs = FindUserEpochs(userEpochs)
	CHECK_WAVE(foundUserEpochs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(foundUserEpochs, {0, 1, 1})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 3)

	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, str)
	if(TestHelperFunctions#DoInstrumentation())
		CHECK_WAVE(durations, NUMERIC_WAVE)
	else
		CHECK_GT_VAR(durations[0], 15000 - PSQ_BL_EVAL_RANGE)
		CHECK_GT_VAR(durations[1], SPIKE_POSITION_MS - PSQ_BL_EVAL_RANGE)
		CHECK_GT_VAR(durations[2], SPIKE_POSITION_MS - PSQ_BL_EVAL_RANGE)
		CHECK_LT_VAR(durations[2], SPIKE_POSITION_TEST_DELAY_MS)
	endif

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 16020, 16520}, sweep = 0)
	[chunkStart, chunkEnd] = GetPostBaseLineInterval(str, 1, 1)
	CheckPSQChunkTimes(str, {20, 520, chunkStart, chunkEnd}, sweep = 1)
	[chunkStart, chunkEnd] = GetPostBaseLineInterval(str, 2, 1)
	CheckPSQChunkTimes(str, {20, 520, chunkStart, chunkEnd}, sweep = 2)
End

static Function PS_RA6_preAcq(string device)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("Ramp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_RA6([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_RAMP)
	// baseline QC passes
	wv            = 0
	wv[0, 1][][0] = 1

	// sweep 0
	// spike passes, async QC passes
	wv[][0][1] = SPIKE_POSITION_MS
	wv[][0][2] = 1

	// sweep 1
	// no spike, async QC fails
	wv[][1][1] = 0
	wv[][1][2] = 0

	// sweep 2/3
	// spikes, async QC passes
	wv[][2, 3][1] = SPIKE_POSITION_MS
	wv[][2, 3][2] = 1
End

static Function PS_RA6_REENTRY([str])
	string str

	variable sweepNo, i, numEntries
	variable chunkStart, chunkEnd

	sweepNo = 3

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetSetQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(baselineQCWave, {1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(sweepQCWave, {1, 0, 1, 1}, mode = WAVE_DATA)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {1, 0, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {1, 0, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo, str)
	CHECK_EQUAL_TEXTWAVES(spikePositionWave, {"10000;", "", "10000;", "10000;"}, mode = WAVE_DATA)

	WAVE/T/Z userEpochs = GetUserEpochs_IGNORE(sweepNo, str)
	CHECK_WAVE(userEpochs, TEXT_WAVE)

	WAVE/Z foundUserEpochs = FindUserEpochs(userEpochs)
	CHECK_WAVE(foundUserEpochs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(foundUserEpochs, {1, 0, 1, 1})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 4)

	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, str)
	if(TestHelperFunctions#DoInstrumentation())
		CHECK_WAVE(durations, NUMERIC_WAVE)
	else
		CHECK_GT_VAR(durations[0], SPIKE_POSITION_MS - PSQ_BL_EVAL_RANGE)
		CHECK_LT_VAR(durations[0], SPIKE_POSITION_TEST_DELAY_MS)
		CHECK_GT_VAR(durations[1], 15000 - PSQ_BL_EVAL_RANGE)
		CHECK_GT_VAR(durations[2], SPIKE_POSITION_MS - PSQ_BL_EVAL_RANGE)
		CHECK_LT_VAR(durations[2], SPIKE_POSITION_TEST_DELAY_MS)
		CHECK_GT_VAR(durations[3], SPIKE_POSITION_MS - PSQ_BL_EVAL_RANGE)
		CHECK_LT_VAR(durations[3], SPIKE_POSITION_TEST_DELAY_MS)
	endif

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	[chunkStart, chunkEnd] = GetPostBaseLineInterval(str, 0, 1)
	CheckPSQChunkTimes(str, {20, 520, chunkStart, chunkEnd}, sweep = 0)
	[chunkstart, chunkend] = GetPostBaseLineInterval(str, 2, 1)
	CheckPSQChunkTimes(str, {20, 520, 16020, 16520}, sweep = 1)
	checkpsqchunktimes(str, {20, 520, chunkstart, chunkend}, sweep = 2)
	[chunkStart, chunkEnd] = GetPostBaseLineInterval(str, 3, 1)
	CheckPSQChunkTimes(str, {20, 520, chunkStart, chunkEnd}, sweep = 3)
End

static Function PS_RA7_preAcq(string device)
	AFH_AddAnalysisParameter("Ramp_DA_0", "SamplingFrequency", var = 10)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("Ramp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// Same as PS_RA2 but with failing sampling interval check
//
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_RA7([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_RAMP)
	// baseline QC passes, no spikes at all, async QC passes
	wv            = 0
	wv[0, 2][][0] = 1
	wv[][][2]     = 1
End

static Function PS_RA7_REENTRY([str])
	string str
	variable i, sweepNo, numEntries, onsetDelay, DAScale

	sweepNo = 0

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetSetQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(setPassed, {0}, mode = WAVE_DATA)

	WAVE/Z baselineQCWave = GetBaselineQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(baselineQCWave, {1}, mode = WAVE_DATA)

	WAVE/Z sweepQCWave = GetSweepQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(sweepQCWave, {0}, mode = WAVE_DATA)

	WAVE/Z samplingIntervalQCWave = GetSamplingIntervalQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(samplingIntervalQCWave, {0}, mode = WAVE_DATA)

	WAVE/Z asyncQCWave = GetAsyncQCResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(asyncQCWave, {1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo, str)
	CHECK_WAVE(spikePositionWave, NULL_WAVE)

	WAVE/T/Z userEpochs = GetUserEpochs_IGNORE(sweepNo, str)
	CHECK_WAVE(userEpochs, TEXT_WAVE)

	WAVE/Z foundUserEpochs = FindUserEpochs(userEpochs)
	CHECK_WAVE(foundUserEpochs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(foundUserEpochs, {0})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 1)

	WAVE/Z DAScaleWave = GetStimscaleFactor_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(DAScaleWave, {PSQ_RA_DASCALE_DEFAULT}, mode = WAVE_DATA)

	// no early abort on BL QC failure
	onsetDelay = GetTotalOnsetDelay(numericalValues, sweepNo)

	WAVE/Z stimSetLengths = GetStimsetLengths_IGNORE(sweepNo, str)
	Make/FREE/N=(numEntries) sweepLengths
	for(i = 0; i < numEntries; i += 1)
		WAVE sweepT  = GetSweepWave(str, sweeps[i])
		WAVE channel = ResolveSweepChannel(sweepT, 0)
		sweepLengths[i] = DimSize(channel, ROWS) - onsetDelay / DimDelta(channel, ROWS)
	endfor
	CHECK_EQUAL_WAVES(stimSetLengths, sweepLengths, mode = WAVE_DATA)

	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(durations, {15000}, mode = WAVE_DATA, tol = 1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 16020, 16520})
End
