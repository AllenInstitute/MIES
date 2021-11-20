#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=PatchSeqTestRamp

// Time were we inject the spike
Constant SPIKE_POSITION_MS = 10000

// Maximum time we accept it
Constant SPIKE_POSITION_TEST_DELAY_MS = 10500

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(STRUCT DAQSettings& s, string device, [FUNCREF CALLABLE_PROTO preAcquireFunc])
	string stimset, unlockedPanelTitle

	// create an empty one so that the preDAQ analysis function can find it
	Make/N=0/O root:overrideResults

	unlockedPanelTitle = DAP_CreateDAEphysPanel()

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

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = 25)

	PGC_SetAndActivateControl(device, "Popup_Settings_VC_DA", str = "0")
	PGC_SetAndActivateControl(device, "Popup_Settings_IC_DA", str = "0")
	PGC_SetAndActivateControl(device, "Popup_Settings_VC_AD", str = "1")
	PGC_SetAndActivateControl(device, "Popup_Settings_IC_AD", str = "1")

	PGC_SetAndActivateControl(device, "button_Hardware_AutoGainAndUnit")

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = 70)
	PGC_SetAndActivateControl(device, GetPanelControl(PSQ_TEST_HEADSTAGE, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)

	stimset = "Ramp_DA_0"
	AdjustAnalysisParamsForPSQ(device, stimset)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = stimset)

	PGC_SetAndActivateControl(device, "check_Settings_MD", val = s.MD)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = s.RA)
	PGC_SetAndActivateControl(device, "Check_DataAcq_Indexing", val = s.IDX)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_IndexingLocked", val = s.LIDX)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_SetRepeats", val = s.RES)
	PGC_SetAndActivateControl(device, "Check_Settings_SkipAnalysFuncs", val = 0)

	if(!s.MD)
		PGC_SetAndActivateControl(device, "Check_Settings_BackgrndDataAcq", val = s.BKG_DAQ)
	else
		CHECK_EQUAL_VAR(s.BKG_DAQ, 1)
	endif

	DoUpdate/W=$device

	if(!ParamIsDefault(preAcquireFunc))
		preAcquireFunc(device)
	endif

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

static Function/WAVE GetUserEpochs_IGNORE(sweepNo, device)
	variable sweepNo
	string device

	variable i, j, numEntries, numEpochs

	WAVE textualValues = GetLBTextualValues(device)
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
	string device

	string key

	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SAMPLING_PASS, query = 1)
	return GetLastSettingIndepEachRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
End

/// @brief Retrieve the time interval for the post baseline chunk interval
///        Based on code from @sa PSQ_EvaluateBaselineProperties
static Function [variable start, variable stop] GetPostBaseLineInterval(string dev, variable sweepNo, variable chunk)

	variable chunkStartTimeMax, chunkLengthTime, totalOnsetDelay

	struct PSQ_PulseSettings s
	MIES_PSQ#PSQ_GetPulseSettingsForType(PSQ_RAMP, s)

	totalOnsetDelay = DAG_GetNumericalValue(dev, "setvar_DataAcq_OnsetDelayUser") + GetValDisplayAsNum(dev, "valdisp_DataAcq_OnsetDelayAuto")
	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, dev)

	chunkStartTimeMax = (totalOnsetDelay + s.prePulseChunkLength + durations[sweepNo]) + chunk * s.postPulseChunkLength
	chunkLengthTime   = s.postPulseChunkLength

	return [chunkStartTimeMax, chunkStartTimeMax + chunkLengthTime]
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

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520})
End

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
	CHECK(durations[0] > SPIKE_POSITION_MS - PSQ_RA_BL_EVAL_RANGE && durations[0] < SPIKE_POSITION_TEST_DELAY_MS)
	CHECK(durations[1] > SPIKE_POSITION_MS - PSQ_RA_BL_EVAL_RANGE && durations[1] < SPIKE_POSITION_TEST_DELAY_MS)
	CHECK(durations[2] > SPIKE_POSITION_MS - PSQ_RA_BL_EVAL_RANGE && durations[2] < SPIKE_POSITION_TEST_DELAY_MS)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	[chunkStart, chunkEnd] = GetPostBaseLineInterval(str, 0, 1)
	CheckPSQChunkTimes(str, {20, 520, chunkStart, chunkEnd}, sweep = 0)
	[chunkStart, chunkEnd] = GetPostBaseLineInterval(str, 1, 1)
	CheckPSQChunkTimes(str, {20, 520, chunkStart, chunkEnd}, sweep = 1)
	[chunkStart, chunkEnd] = GetPostBaseLineInterval(str, 2, 1)
	CheckPSQChunkTimes(str, {20, 520, chunkStart, chunkEnd}, sweep = 2)
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
	CHECK(durations[0] > SPIKE_POSITION_MS - PSQ_RA_BL_EVAL_RANGE && durations[0] < SPIKE_POSITION_TEST_DELAY_MS)
	CHECK_CLOSE_VAR(durations[1], 15000, tol = 1)
	CHECK_CLOSE_VAR(durations[2], 15000, tol = 1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	[chunkStart, chunkEnd] = GetPostBaseLineInterval(str, 0, 1)
	CheckPSQChunkTimes(str, {20, 520, chunkStart, chunkEnd}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520, 16020, 16520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520, 16020, 16520}, sweep = 2)
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
	CHECK_GT_VAR(durations[0], 15000 - PSQ_RA_BL_EVAL_RANGE)
	CHECK_GT_VAR(durations[1], SPIKE_POSITION_MS - PSQ_RA_BL_EVAL_RANGE)
	CHECK(durations[2] > SPIKE_POSITION_MS - PSQ_RA_BL_EVAL_RANGE && durations[2] < SPIKE_POSITION_TEST_DELAY_MS)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 16020, 16520}, sweep = 0)
	[chunkStart, chunkEnd] = GetPostBaseLineInterval(str, 1, 1)
	CheckPSQChunkTimes(str, {20, 520, chunkStart, chunkEnd}, sweep = 1)
	[chunkStart, chunkEnd] = GetPostBaseLineInterval(str, 2, 1)
	CheckPSQChunkTimes(str, {20, 520, chunkStart, chunkEnd}, sweep = 2)
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

	WAVE/Z spikeDetectionWave = GetSpikeResults_IGNORE(sweepNo, str)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z spikePositionWave = GetSpikePosition_IGNORE(sweepNo, str)
	CHECK_EQUAL_TEXTWAVES(spikePositionWave, {"", "", "10000;"}, mode = WAVE_DATA)

	WAVE/T/Z userEpochs = GetUserEpochs_IGNORE(sweepNo, str)
	CHECK_WAVE(userEpochs, TEXT_WAVE)

	WAVE/Z foundUserEpochs = FindUserEpochs(userEpochs)
	CHECK_WAVE(foundUserEpochs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(foundUserEpochs, {0, 0, 1})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 3)

	WAVE/Z durations = GetPulseDurations_IGNORE(sweepNo, str)
	CHECK_GT_VAR(durations[0], 15000 - PSQ_RA_BL_EVAL_RANGE)
	CHECK_GT_VAR(durations[1], 15000 - PSQ_RA_BL_EVAL_RANGE)
	CHECK(durations[2] > SPIKE_POSITION_MS - PSQ_RA_BL_EVAL_RANGE && durations[2] < SPIKE_POSITION_TEST_DELAY_MS)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 16020, 16520}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520, 16020, 16520}, sweep = 1)
	[chunkStart, chunkEnd] = GetPostBaseLineInterval(str, 2, 1)
	CheckPSQChunkTimes(str, {20, 520, chunkStart, chunkEnd}, sweep = 2)
End

static Function PS_RA7_IGNORE(string device)
	AFH_AddAnalysisParameter("Ramp_DA_0", "SamplingFrequency", var=10)
End

// Same as PS_RA2 but with failing sampling interval check
//
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_RA7([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, preAcquireFunc = PS_RA7_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_RAMP)
	// baseline QC passes and no spikes at all
	wv = 0
	wv[0,2][][0] = 1
End

static Function PS_RA7_REENTRY([str])
	string str
	variable sweepNo, numEntries, onsetDelay, DAScale

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
	CHECK_EQUAL_WAVES(durations, {15000}, mode = WAVE_DATA, tol = 1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 16020, 16520})
End
