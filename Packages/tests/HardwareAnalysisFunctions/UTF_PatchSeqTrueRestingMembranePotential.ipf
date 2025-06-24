#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = PatchSeqTrueRestMembranePot

/// Test matrix
/// @rst
///
/// .. Column order: test overrides, analysis parameters
///
/// =========== ===================== =================== =================== ================== =================== ====================== ===================== ===================== ===================== ====================== =================== ============================
///  Test case   Baseline QC chunk 0   Average V chunk 0   Average V chunk 1   Number of Spikes   Async Channels QC   NumberOfFailedSweeps   BaselineChunkLength   AbsoluteVoltageDiff   RelativeVoltageDiff   Sampling Interval QC   NextStimSetName     NextIndexingEndStimSetName
/// =========== ===================== =================== =================== ================== =================== ====================== ===================== ===================== ===================== ====================== =================== ============================
///  PS_VM1      -                     [12,13,14]          [16,17,18]          [1,2,3]            ✓                  3                      500                   0                     0                     ✓                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM2      ✓                     [12,13,14]          [12,13,14]          0                  ✓                  3                      500                   0                     0                     ✓                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM3      -                     [12,13,14]          [12,13,14]          0                  ✓                  3                      500                   0                     0                     ✓                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM4      ✓                     [12,13,14]          [16,17,18]          0                  ✓                  3                      500                   inf                   0                     ✓                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM5      ✓                     [12,13,14]          [16,17,18]          0                  ✓                  3                      500                   0                     inf                   ✓                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM5a     ✓                     [10,0.1,1]          [11,0.15,1.05]      0                  ✓                  3                      500                   0.1                   10                    ✓                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM5b     ✓                     [12,13,14]          [12,13,14]          0                  ✓                  3                      500                   0                     0                     ✓                      StimulusSetA_DA_0   (none)
///  PS_VM6      ✓                     [12,13,14]          [12,13,14]          0                  ✓                  3                      600                   0                     0                     ✓                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM7      ✓                     [12,13,14]          [12,13,14]          1                  ✓                  1                      500                   0                     inf                   ✓                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM7a     ✓                     [12,13,14]          [12,13,14]          [1, 0]             ✓                  3                      500                   0                     0                     ✓                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM7b     ✓                     [12,13,14]          [12,13,14]          0                  -                  3                      500                   0                     0                     ✓                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM8      ✓                     [12,13,14]          [12,13,14]          0                  ✓                  3                      500                   0                     0                     -                      StimulusSetA_DA_0   StimulusSetB_DA_0
/// =========== ===================== =================== =================== ================== =================== ====================== ===================== ===================== ===================== ====================== =================== ============================
///
/// @endrst

static Function [STRUCT DAQSettings s] PS_GetDAQSettings(string device)

	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_DB1"                                                    + \
	                             "__HS" + num2str(PSQ_TEST_HEADSTAGE) + "_DA0_AD0_CM:IC:_ST:PSQ_TrueRest_DA_0:")

	return [s]
End

static Function GlobalPreAcq(string device)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = 25)
End

static Function GlobalPreInit(string device)

	AdjustAnalysisParamsForPSQ(device, "PSQ_TrueRest_DA_0")
	PrepareForPublishTest()
End

static Function/WAVE GetLBNSingleEntry_IGNORE(string device, variable sweepNo, string name, [variable chunk])

	variable val, type
	string key

	CHECK(IsValidSweepNumber(sweepNo))
	CHECK_LE_VAR(sweepNo, AFH_GetLastSweepAcquired(device))

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	type = PSQ_TRUE_REST_VM

	strswitch(name)
		case PSQ_FMT_LBN_SWEEP_PASS: // fallthrough
		case PSQ_FMT_LBN_SAMPLING_PASS: // fallthrough
		case PSQ_FMT_LBN_ASYNC_PASS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_BL_QC_PASS: // fallthrough
		case PSQ_FMT_LBN_SPIKE_PASS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_SET_PASS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			val = GetLastSettingIndepSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
			Make/D/FREE wv = {val}
			return wv
		case PSQ_FMT_LBN_VM_FULL_AVG: // fallthrough
		case PSQ_FMT_LBN_VM_FULL_AVG_ADIFF: // fallthrough
		case PSQ_FMT_LBN_VM_FULL_AVG_ADIFF_PASS: // fallthrough
		case PSQ_FMT_LBN_VM_FULL_AVG_RDIFF: // fallthrough
		case PSQ_FMT_LBN_VM_FULL_AVG_RDIFF_PASS: // fallthrough
		case PSQ_FMT_LBN_VM_FULL_AVG_PASS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_SPIKE_POSITIONS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			return GetLastSettingTextEachSCI(numericalValues, textualValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_CHUNK_PASS:
			key = CreateAnaFuncLBNKey(type, name, chunk = chunk, query = 1)
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_RMS_SHORT_PASS: // fallthrough
		case PSQ_FMT_LBN_RMS_LONG_PASS: // fallthrough
		case PSQ_FMT_LBN_AVERAGEV:
			key = CreateAnaFuncLBNKey(type, name, chunk = chunk, query = 1)
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case "Autobias Vcom": // fallthrough
		case "Autobias":
			return GetLastSettingEachSCI(numericalValues, sweepNo, name, PSQ_TEST_HEADSTAGE, DATA_ACQUISITION_MODE)
		case "Inter-trial interval": // fallthrough
		case "Get/Set Inter-trial interval":
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, name, PSQ_TEST_HEADSTAGE, DATA_ACQUISITION_MODE)
		default:
			FAIL()
	endswitch
End

static Function/WAVE GetWave_IGNORE()

	string list = "sweepPass;setPass;baselinePass;spikePass;samplingPass;" + \
	              "spikePositions;autobiasVCom;autobias;"                  + \
	              "fullAvg;fullAvgPass;"                                   + \
	              "fullAvgADiff;fullAvgADiffPass;"                         + \
	              "fullAvgRDiff;fullAvgRDiffPass;"                         + \
	              "baselineQCChunk0;baselineQCChunk1;"                     + \
	              "rmsShortQCChunk0;rmsShortQCChunk1;"                     + \
	              "rmsLongQCChunk0;rmsLongQCChunk1;"                       + \
	              "averageVChunk0;averageVChunk1;"                         + \
	              "iti;getsetiti;asyncPass"

	Make/FREE/WAVE/N=(ItemsInList(list)) wv
	SetDimensionLabels(wv, list, ROWS)

	return wv
End

static Function/WAVE GetEntries_IGNORE(string device, variable sweepNo)

	WAVE numericalValues = GetLBNumericalValues(device)

	WAVE/WAVE wv = GetWave_IGNORE()

	wv[%sweepPass]    = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	wv[%setPass]      = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SET_PASS)
	wv[%baselinePass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	wv[%spikePass]    = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SPIKE_PASS)
	wv[%samplingPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	wv[%asyncPass]    = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)

	wv[%spikePositions] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SPIKE_POSITIONS)

	wv[%autobiasVcom] = GetLBNSingleEntry_IGNORE(device, sweepNo, "Autobias Vcom")
	wv[%autobias]     = GetLBNSingleEntry_IGNORE(device, sweepNo, "Autobias")
	wv[%iti]          = GetLBNSingleEntry_IGNORE(device, sweepNo, "Inter-trial interval")
	wv[%getsetiti]    = GetLBNSingleEntry_IGNORE(device, sweepNo, "Get/Set Inter-trial interval")

	wv[%fullAvg]          = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_VM_FULL_AVG)
	wv[%fullAvgADiff]     = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_VM_FULL_AVG_ADIFF)
	wv[%fullAvgADiffPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_VM_FULL_AVG_ADIFF_PASS)
	wv[%fullAvgRDiff]     = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_VM_FULL_AVG_RDIFF)
	wv[%fullAvgRDiffPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_VM_FULL_AVG_RDIFF_PASS)

	wv[%fullAvgPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_VM_FULL_AVG_PASS)

	wv[%baselineQCChunk0] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 0)
	wv[%baselineQCChunk1] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 1)
	wv[%rmsShortQCChunk0] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 0)
	wv[%rmsShortQCChunk1] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 1)
	wv[%rmsLongQCChunk0]  = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 0)
	wv[%rmsLongQCChunk1]  = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 1)
	wv[%averageVChunk0]   = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_AVERAGEV, chunk = 0)
	wv[%averageVChunk1]   = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_AVERAGEV, chunk = 1)

	REQUIRE_EQUAL_VAR(GetRTerror(1), 0)

	return wv
End

Function CheckBaselineChunks(string device, WAVE chunkTimes)

	CheckUserEpochs(device, {20, 520, 625, 1125}, EPOCH_SHORTNAME_USER_PREFIX + "BLS%d", sweep = 0)
	CheckPSQChunkTimes(device, chunkTimes)
End

static Function PS_VM1_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var = 0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var = 1)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var = 500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var = 10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var = 5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var = -3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var = 0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var = 0)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_VM1([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// all tests fail
	wv[][][0] = 0

	// number of spikes
	wv[][][1] = 1 + q

	// average voltages
	// chunk 0
	wv[0][0][2] = 12
	wv[0][1][2] = 13
	wv[0][2][2] = 14

	// chunk 1
	wv[1][0][2] = 16
	wv[1][1][2] = 17
	wv[1][2][2] = 18
End

static Function PS_VM1_REENTRY([string str])

	variable sweepNo

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%rmsLongQCChunk0], NULL_WAVE)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%averageVChunk0], NULL_WAVE)
	CHECK_WAVE(entries[%averageVChunk1], NULL_WAVE)

	CHECK_WAVE(entries[%fullAvg], NULL_WAVE)
	CHECK_WAVE(entries[%fullAvgADiff], NULL_WAVE)
	CHECK_WAVE(entries[%fullAvgRDiff], NULL_WAVE)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(entries[%spikePositions], {"1;", "2;2;", "3;3;3;"}, mode = WAVE_DATA)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0, 11, 12}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 13)

	CHECK_EQUAL_WAVES(entries[%autobias], {0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 1)

	CHECK_EQUAL_WAVES(entries[%iti], {0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 1)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
End

static Function PS_VM2_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var = 0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var = 0)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var = 500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var = 10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var = 5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var = -3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var = 0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var = 0)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_VM2([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// all tests pass
	wv[][][0] = 1

	// number of spikes
	wv[][][1] = 0

	// average voltages
	// chunk 0
	wv[0][0][2] = 12
	wv[0][1][2] = 13
	wv[0][2][2] = 14

	// chunk 1
	wv[1][0][2] = 12
	wv[1][1][2] = 13
	wv[1][2][2] = 14

	// async QC
	wv[][][3] = 1
End

static Function PS_VM2_REENTRY([string str])

	variable sweepNo

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk0], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {12e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {12e-3}, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvg = {12e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {0}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA)

	Make/D/FREE fullAvgRDiff = {0}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%spikePositions], NULL_WAVE)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 12)

	CHECK_EQUAL_WAVES(entries[%autobias], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 1)

	CHECK_EQUAL_WAVES(entries[%iti], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 0)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
End

static Function PS_VM3_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var = 0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var = 0)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var = 500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var = 10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var = 5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var = -3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var = 0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var = 0)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_VM3([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// tests pass, except BL QC in chunk0
	wv[][][0]  = 1
	wv[0][][0] = 0

	// number of spikes
	wv[][][1] = 0

	// average voltages
	// chunk 0
	wv[0][0][2] = 12
	wv[0][1][2] = 13
	wv[0][2][2] = 14

	// chunk 1
	wv[1][0][2] = 12
	wv[1][1][2] = 13
	wv[1][2][2] = 14

	// async QC
	wv[][][3] = 1
End

static Function PS_VM3_REENTRY([string str])

	variable sweepNo

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%rmsLongQCChunk0], NULL_WAVE)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%averageVChunk0], NULL_WAVE)
	CHECK_WAVE(entries[%averageVChunk1], NULL_WAVE)

	CHECK_WAVE(entries[%fullAvg], NULL_WAVE)
	CHECK_WAVE(entries[%fullAvgADiff], NULL_WAVE)
	CHECK_WAVE(entries[%fullAvgRDiff], NULL_WAVE)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%spikePositions], NULL_WAVE)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 0)

	CHECK_EQUAL_WAVES(entries[%autobias], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 0)

	CHECK_EQUAL_WAVES(entries[%iti], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 0)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
End

static Function PS_VM4_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var = 0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var = 0)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var = 500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var = 10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var = 5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var = -3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var = Inf)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var = 0)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_VM4([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// tests pass, except relative average voltage diff
	wv[][][0] = 1

	// number of spikes
	wv[][][1] = 0

	// average voltages
	// chunk 0
	wv[0][0][2] = 12
	wv[0][1][2] = 13
	wv[0][2][2] = 14

	// chunk 1
	wv[1][0][2] = 16
	wv[1][1][2] = 17
	wv[1][2][2] = 18

	// async QC
	wv[][][3] = 1
End

static Function PS_VM4_REENTRY([string str])

	variable sweepNo

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk0], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {12e-3, 13e-3, 14e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {16e-3, 17e-3, 18e-3}, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvg = {14e-3, 15e-3, 16e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {-4e-3, -4e-3, -4e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgRDiff = {-0.33, -0.30, -0.28}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA, tol = 1e-2)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%spikePositions], NULL_WAVE)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 0)

	CHECK_EQUAL_WAVES(entries[%autobias], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 0)

	CHECK_EQUAL_WAVES(entries[%iti], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 0)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
End

static Function PS_VM5_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var = 0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var = 0)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var = 500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var = 10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var = 5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var = -3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var = 0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var = Inf)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_VM5([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// tests pass, except absolute average voltage diff
	wv[][][0] = 1

	// number of spikes
	wv[][][1] = 0

	// average voltages
	// chunk 0
	wv[0][0][2] = 12
	wv[0][1][2] = 13
	wv[0][2][2] = 14

	// chunk 1
	wv[1][0][2] = 16
	wv[1][1][2] = 17
	wv[1][2][2] = 18

	// async QC
	wv[][][3] = 1
End

static Function PS_VM5_REENTRY([string str])

	variable sweepNo

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk0], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {12e-3, 13e-3, 14e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {16e-3, 17e-3, 18e-3}, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvg = {14e-3, 15e-3, 16e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {-4e-3, -4e-3, -4e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgRDiff = {-0.33, -0.30, -0.28}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA, tol = 1e-2)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%spikePositions], NULL_WAVE)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 0)

	CHECK_EQUAL_WAVES(entries[%autobias], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 0)

	CHECK_EQUAL_WAVES(entries[%iti], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 0)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
End

static Function PS_VM5a_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var = 500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var = 10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var = 5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var = -3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var = 0.1)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var = 10)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_VM5a([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// sweep 0:
	// fail due to abs avg diff
	// sweep 1:
	// fail due to rel avg diff
	// sweep 2:
	// pass

	// BL QC passes
	wv[][][0] = 1

	// number of spikes
	wv[][][1] = 0

	// average voltages
	// chunk 0
	wv[0][0][2] = 10
	wv[0][1][2] = 0.1
	wv[0][2][2] = 1

	// chunk 1
	wv[1][0][2] = 11
	wv[1][1][2] = 0.15
	wv[1][2][2] = 1.05

	// async QC
	wv[][][3] = 1
End

static Function PS_VM5a_REENTRY([string str])

	variable sweepNo

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk0], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {10e-3, 0.1e-3, 1e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {11e-3, 0.15e-3, 1.05e-3}, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvg = {10.5e-3, 0.125e-3, 1.025e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {-1e-3, -0.05e-3, -0.05e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgRDiff = {-0.1, -0.5, -0.05}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA, tol = 1e-3)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {0, 0, 1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%spikePositions], NULL_WAVE)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_CLOSE_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 1.025, tol = 1e-6)

	CHECK_EQUAL_WAVES(entries[%autobias], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 1)

	CHECK_EQUAL_WAVES(entries[%iti], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 0)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
End

static Function PS_VM5b_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var = 0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var = 0)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	// NextIndexingEndStimSetName not set
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var = 500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var = 10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var = 5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var = -3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var = 0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var = 0)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_VM5b([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// all tests pass
	wv[][][0] = 1

	// number of spikes
	wv[][][1] = 0

	// average voltages
	// chunk 0
	wv[0][0][2] = 12
	wv[0][1][2] = 13
	wv[0][2][2] = 14

	// chunk 1
	wv[1][0][2] = 12
	wv[1][1][2] = 13
	wv[1][2][2] = 14

	// async QC
	wv[][][3] = 1
End

static Function PS_VM5b_REENTRY([string str])

	variable sweepNo

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk0], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {12e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {12e-3}, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvg = {12e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {0}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA)

	Make/D/FREE fullAvgRDiff = {0}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%spikePositions], NULL_WAVE)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 12)

	CHECK_EQUAL_WAVES(entries[%autobias], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 1)

	CHECK_EQUAL_WAVES(entries[%iti], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 0)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
End

static Function PS_VM6_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var = 0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var = 0)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var = 600)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var = 10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var = 5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var = -3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var = 0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var = 0)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_VM6([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// all tests pass, but see below
	wv[][][0] = 1

	// number of spikes
	wv[][][1] = 0

	// average voltages
	// chunk 0
	wv[0][0][2] = 12
	wv[0][1][2] = 13
	wv[0][2][2] = 14

	// chunk 1
	wv[1][0][2] = 12
	wv[1][1][2] = 13
	wv[1][2][2] = 14

	// async QC
	wv[][][3] = 1

	// DAQ is not started as PRE_SWEEP_CONFIG_EVENT fails due to non-matching BaselineChunkLength
	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)
	CHECK_EQUAL_VAR(AFH_GetlastSweepAcquired(str), NaN)
End

static Function PS_VM7_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var = 0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var = 1)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var = 1)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var = 500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var = 10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var = 5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var = -3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var = 0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var = 0)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_VM7([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// tests pass, except for 1 spike
	wv[][][0] = 1

	// number of spikes
	wv[][][1] = 1

	// average voltages
	// chunk 0
	wv[0][0][2] = 12
	wv[0][1][2] = 13
	wv[0][2][2] = 14

	// chunk 1
	wv[1][0][2] = 12
	wv[1][1][2] = 13
	wv[1][2][2] = 14

	// async QC
	wv[][][3] = 1
End

static Function PS_VM7_REENTRY([string str])

	variable sweepNo

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk0], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {12e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {12e-3}, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvg = {12e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {0}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgRDiff = {0}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA, tol = 1e-2)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(entries[%spikePositions], {"1;"}, mode = WAVE_DATA)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 6 + 3)

	CHECK_EQUAL_WAVES(entries[%autobias], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 1)

	CHECK_EQUAL_WAVES(entries[%iti], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 1)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
End

static Function PS_VM7a_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var = 0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var = 1)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var = 500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var = 10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var = 5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var = -3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var = 0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var = 0)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_VM7a([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// tests pass, except for 1 spike
	wv[][][0] = 1

	// number of spikes [1, 0]
	wv[][][1]  = 0
	wv[][0][1] = 1

	// average voltages
	// chunk 0
	wv[0][0][2] = 12
	wv[0][1][2] = 13
	wv[0][2][2] = 14

	// chunk 1
	wv[1][0][2] = 12
	wv[1][1][2] = 13
	wv[1][2][2] = 14

	// async QC
	wv[][][3] = 1
End

static Function PS_VM7a_REENTRY([string str])

	variable sweepNo

	sweepNo = 1

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk0], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {12e-3, 13e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {12e-3, 13e-3}, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvg = {12e-3, 13e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {0, 0}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgRDiff = {0, 0}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA, tol = 1e-2)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(entries[%spikePositions], {"1;", ""}, mode = WAVE_DATA)

	// first sweep does not have autobias enabled
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0, 6 + 3}, mode = WAVE_DATA)
	CHECK_CLOSE_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 13, tol = 1e-12)

	CHECK_EQUAL_WAVES(entries[%autobias], {0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 1)

	CHECK_EQUAL_WAVES(entries[%iti], {0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 1)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
End

static Function PS_VM7b_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var = 0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var = 0)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var = 500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var = 10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var = 5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var = -3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var = 0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var = 0)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_VM7b([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// tests pass, except async QC
	wv[][][0] = 1

	// number of spikes
	wv[][][1] = 0

	// average voltages
	// chunk 0
	wv[0][0][2] = 12
	wv[0][1][2] = 13
	wv[0][2][2] = 14

	// chunk 1
	wv[1][0][2] = 12
	wv[1][1][2] = 13
	wv[1][2][2] = 14

	// async QC
	wv[][][3] = 0
End

static Function PS_VM7b_REENTRY([string str])

	variable sweepNo
	string stimset, stimsetIndexEnd, expected

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%rmsLongQCChunk0], NUMERIC_WAVE)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {12e-3, 13e-3, 14e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {12e-3, 13e-3, 14e-3}, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvg = {12e-3, 13e-3, 14e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {0, 0, 0}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgRDiff = {0, 0, 0}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA, tol = 1e-2)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%spikePositions], NULL_WAVE)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 0)

	CHECK_EQUAL_WAVES(entries[%autobias], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 0)

	CHECK_EQUAL_WAVES(entries[%iti], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 0)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
End

static Function PS_VM8_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var = 0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var = 0)

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SamplingFrequency", var = 10)
	// SamplingMultiplier use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var = 1)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var = 500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var = 10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var = 5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var = -3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var = 0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var = 100)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_VM8([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// tests pass, except sampling QC fails
	wv[][][0] = 1

	// number of spikes
	wv[][][1] = 0

	// average voltages
	// chunk 0
	wv[0][0][2] = 12
	wv[0][1][2] = 13
	wv[0][2][2] = 14

	// chunk 1
	wv[1][0][2] = 12
	wv[1][1][2] = 13
	wv[1][2][2] = 14

	// async QC
	wv[][][3] = 1
End

static Function PS_VM8_REENTRY([string str])

	variable sweepNo

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk0], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {12e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {12e-3}, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvg = {12e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {0}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgRDiff = {0}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA, tol = 1e-2)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%spikePositions], NULL_WAVE)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 0)

	CHECK_EQUAL_WAVES(entries[%autobias], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 0)

	CHECK_EQUAL_WAVES(entries[%iti], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 0)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
End
