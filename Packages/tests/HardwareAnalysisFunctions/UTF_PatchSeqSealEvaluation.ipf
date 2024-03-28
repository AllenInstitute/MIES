#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=PatchSeqSealEvaluation

/// Test matrix
/// @rst
///
/// .. Column order: test overrides, analysis parameters
///
/// ========================== ====================== =================== =================== =================== ====================== ======================== ======================== ========================
///  Test case                  Baseline QC            Seal Resistance A   Seal Resistance B   Async Channels QC   SamplingFrequency      NumSweepsFailed          BaselineChunkLength      TestPulseGroupSelector
/// ========================== ====================== =================== =================== =================== ====================== ======================== ======================== ========================
///  PS_SE1                     -                      600                 800                 ✓                   500 (✓)                3                        500                      Both
///  PS_SE2                     ✓                      1400                1600                ✓                   500 (✓)                3                        500                      Both
///  PS_SE3                     ✓                      1400                800                 ✓                   500 (✓)                3                        500                      First
///  PS_SE4                     ✓                      600                 1600                ✓                   500 (✓)                3                        500                      Second
///  PS_SE5                     chunk0 ✓, chunk1 -     1400                1600                ✓                   500 (✓)                3                        500                      Second
///  PS_SE6                     chunk0 -,chunk1 ✓      1400                1600                ✓                   500 (✓)                3                        500                      Second
///  PS_SE7                     -                      1400                1600                ✓                   500 (✓)                1                        500                      Both
///  PS_SE7a                    ✓                      1400                1600                -                   500 (✓)                3                        500                      Both
///  PS_SE8                     -                      1400                1600                ✓                   500 (✓)                3                        60                       Both
///  PS_SE9                     ✓                      1400                1600                ✓                   10  (-)                3                        500                      Both
/// ========================== ====================== =================== =================== =================== ====================== ======================== ======================== ========================
///
/// @endrst

static Function [STRUCT DAQSettings s] PS_GetDAQSettings(string device)

	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_DB1"                                                        + \
	                             "__HS" + num2str(PSQ_TEST_HEADSTAGE) + "_DA0_AD0_CM:VC:_ST:PatchSeqSealChec_DA_0:")

	return [s]
End

static Function GlobalPreAcq(string device)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = 25)
End

static Function GlobalPreInit(string device)

	AdjustAnalysisParamsForPSQ(device, "PatchSeqSealChec_DA_0")
	PrepareForPublishTest()
End

static Function/WAVE GetResultsSingleEntry_IGNORE(string name)
	WAVE/T textualResultsValues = GetTextualResultsValues()

	WAVE/Z indizesName = GetNonEmptyLBNRows(textualResultsValues, name)
	WAVE/Z indizesType = GetNonEmptyLBNRows(textualResultsValues, "EntrySourceType")

	if(!WaveExists(indizesName) || !WaveExists(indizesType))
		return $""
	endif

	indizesType[] = (str2numSafe(textualResultsValues[indizesType[p]][%$"EntrySourceType"][INDEP_HEADSTAGE]) == SWEEP_FORMULA_RESULT) ? indizesType[p] : NaN

	WAVE/Z indizesTypeClean = ZapNaNs(indizesType)

	if(!WaveExists(indizesTypeClean))
		return $""
	endif

	WAVE/Z indizes = GetSetIntersection(indizesName, indizesTypeClean)

	if(!WaveExists(indizes))
		return $""
	endif

	Make/FREE/T/N=(DimSize(indizes, ROWS)) entries = textualResultsValues[indizes[p]][%$name][INDEP_HEADSTAGE]

	return GetUniqueEntries(entries)
End

static Function/WAVE GetLBNSingleEntry_IGNORE(device, sweepNo, name, [chunk])
	string device
	variable sweepNo, chunk
	string name

	variable val, type
	string key

	CHECK(IsValidSweepNumber(sweepNo))
	CHECK_LE_VAR(sweepNo, AFH_GetLastSweepAcquired(device))

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	type = PSQ_SEAL_EVALUATION

	strswitch(name)
		case PSQ_FMT_LBN_SWEEP_PASS:
		case PSQ_FMT_LBN_SE_RESISTANCE_A:
		case PSQ_FMT_LBN_SE_RESISTANCE_B:
		case PSQ_FMT_LBN_SE_RESISTANCE_MAX:
		case PSQ_FMT_LBN_SE_RESISTANCE_PASS:
		case PSQ_FMT_LBN_SAMPLING_PASS:
		case PSQ_FMT_LBN_ASYNC_PASS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_BL_QC_PASS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_SET_PASS:
		case PSQ_FMT_LBN_SE_TESTPULSE_GROUP:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			val = GetLastSettingIndepSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
			Make/D/FREE wv = {val}
			return wv
		case PSQ_FMT_LBN_CHUNK_PASS:
			key = CreateAnaFuncLBNKey(type, name, chunk = chunk, query = 1)
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		default:
			FAIL()
	endswitch
End

static Function/WAVE GetWave_IGNORE()

	string list = "sweepPass;setPass;baselinePass;"                                       + \
	              "resistanceA;resistanceB;resistancePass;"                               + \
	              "resultsSweep;resultsResistanceA;resultsResistanceB;testpulseGroupSel;" + \
	              "resistanceMax;baselineQCChunk0;baselineQCChunk1;samplingPass;asyncPass"

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

	wv[%testpulseGroupSel] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SE_TESTPULSE_GROUP)

	wv[%resistanceA]    = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SE_RESISTANCE_A)
	wv[%resistanceB]    = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SE_RESISTANCE_B)
	wv[%resistanceMax]  = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SE_RESISTANCE_MAX)
	wv[%resistancePass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SE_RESISTANCE_PASS)

	wv[%baselineQCChunk0] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 0)
	wv[%baselineQCChunk1] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 1)

	wv[%resultsSweep]       = ExtractSweepsFromSFPairs(GetResultsSingleEntry_IGNORE("Sweep Formula sweeps/channels"))
	wv[%resultsResistanceA] = GetResultsSingleEntry_IGNORE("Sweep Formula store [Steady state resistance (group A)]")
	wv[%resultsResistanceB] = GetResultsSingleEntry_IGNORE("Sweep Formula store [Steady state resistance (group B)]")

	wv[%samplingPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	wv[%asyncPass]    = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)

	return wv
End

static Function CheckTestPulseLikeEpochs(string device, variable testpulseGroupSel)

	switch(testpulseGroupSel)
		case PSQ_SE_TGS_FIRST:
			//                       group A
			CheckUserEpochs(device, {520, 540, 540, 560, 560, 580}, EPOCH_SHORTNAME_USER_PREFIX + "TP%d")
			CheckUserEpochs(device, {520, 525, 540, 545, 560, 565}, EPOCH_SHORTNAME_USER_PREFIX + "TP%d_B0")
			CheckUserEpochs(device, {525, 535, 545, 555, 565, 575}, EPOCH_SHORTNAME_USER_PREFIX + "TP%d_P")
			CheckUserEpochs(device, {535, 540, 555, 560, 575, 580}, EPOCH_SHORTNAME_USER_PREFIX + "TP%d_B1")
			break
		case PSQ_SE_TGS_SECOND:
			//                       group B
			CheckUserEpochs(device, {1140, 1160, 1160, 1180, 1180, 1200}, EPOCH_SHORTNAME_USER_PREFIX + "TP%d")
			CheckUserEpochs(device, {1140, 1145, 1160, 1165, 1180, 1185}, EPOCH_SHORTNAME_USER_PREFIX + "TP%d_B0")
			CheckUserEpochs(device, {1145, 1155, 1165, 1175, 1185, 1195}, EPOCH_SHORTNAME_USER_PREFIX + "TP%d_P")
			CheckUserEpochs(device, {1155, 1160, 1175, 1180, 1195, 1200}, EPOCH_SHORTNAME_USER_PREFIX + "TP%d_B1")
			break
		case PSQ_SE_TGS_BOTH:
			//                       group A                       group B
			CheckUserEpochs(device, {520, 540, 540, 560, 560, 580, 1140, 1160, 1160, 1180, 1180, 1200}, EPOCH_SHORTNAME_USER_PREFIX + "TP%d")
			CheckUserEpochs(device, {520, 525, 540, 545, 560, 565, 1140, 1145, 1160, 1165, 1180, 1185}, EPOCH_SHORTNAME_USER_PREFIX + "TP%d_B0")
			CheckUserEpochs(device, {525, 535, 545, 555, 565, 575, 1145, 1155, 1165, 1175, 1185, 1195}, EPOCH_SHORTNAME_USER_PREFIX + "TP%d_P")
			CheckUserEpochs(device, {535, 540, 555, 560, 575, 580, 1155, 1160, 1175, 1180, 1195, 1200}, EPOCH_SHORTNAME_USER_PREFIX + "TP%d_B1")
			break
		default:
			ASSERT(0, "Invalid testpulseGroupSel")
	endswitch

End

static Function CheckBaselineChunks(string device, variable testpulseGroupSel)

	switch(testpulseGroupSel)
		case PSQ_SE_TGS_FIRST:
			CheckUserEpochs(device, {20, 520}, EPOCH_SHORTNAME_USER_PREFIX + "BLS%d", sweep = 0)
			CheckPSQChunkTimes(device, {20, 520})
			break
		case PSQ_SE_TGS_SECOND:
			CheckUserEpochs(device, {640, 1140}, EPOCH_SHORTNAME_USER_PREFIX + "BLS%d", sweep = 0)
			CheckPSQChunkTimes(device, {640, 1140})
			break
		case PSQ_SE_TGS_BOTH:
			CheckUserEpochs(device, {20, 520, 640, 1140}, EPOCH_SHORTNAME_USER_PREFIX + "BLS%d", sweep = 0)
			CheckPSQChunkTimes(device, {20, 520, 640, 1140})
			break
		default:
			ASSERT(0, "Invalid testpulseGroupSel")
	endswitch

End

static Function PS_SE1_preAcq(device)
	string device

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "TestPulseGroupSelector", str = "Both")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "SealThreshold", var = 1)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineChunkLength", var = 500)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_SE1([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SEAL_EVALUATION)

	// all tests fail
	wv[][][0] = 0
	wv[][][1] = 0.6e3
	wv[][][2] = 0.8e3
	wv[][][3] = 0
End

static Function PS_SE1_REENTRY([str])
	string str

	variable sweepNo, autobiasV
	string lbl, failedPulses, spikeCounts

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineQCChunk1], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%testpulseGroupSel], {PSQ_SE_TGS_BOTH}, mode = WAVE_DATA)

	Make/D resistanceARef = {0.6e9, 0.6e9, 0.6e9}
	CHECK_EQUAL_WAVES(entries[%resistanceA], resistanceARef, mode = WAVE_DATA)

	Make/D resistanceBRef = {0.8e9, 0.8e9, 0.8e9}
	CHECK_EQUAL_WAVES(entries[%resistanceB], resistanceBRef, mode = WAVE_DATA)

	Make/D resistanceMaxRef = {0.8e9, 0.8e9, 0.8e9}
	CHECK_EQUAL_WAVES(entries[%resistanceMax], resistanceMaxRef, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%resistancePass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(entries[%resultsSweep], {"0;", "1;", "2;"}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%resultsResistanceA], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsResistanceB], TEXT_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckTestPulseLikeEpochs(str, PSQ_SE_TGS_BOTH)
	CheckBaselineChunks(str, PSQ_SE_TGS_BOTH)
End

static Function PS_SE2_preAcq(device)
	string device

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "TestPulseGroupSelector", str = "Both")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "SealThreshold", var = 1)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineChunkLength", var = 500)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_SE2([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SEAL_EVALUATION)

	// all tests pass
	wv[][][0] = 1
	wv[][][1] = 1.4e3
	wv[][][2] = 1.6e3
	wv[][][3] = 1
End

static Function PS_SE2_REENTRY([str])
	string str

	variable sweepNo, autobiasV
	string lbl, failedPulses, spikeCounts

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineQCChunk1], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%testpulseGroupSel], {PSQ_SE_TGS_BOTH}, mode = WAVE_DATA)

	Make/D resistanceARef = {1.4e9}
	CHECK_EQUAL_WAVES(entries[%resistanceA], resistanceARef, mode = WAVE_DATA)

	Make/D resistanceBRef = {1.6e9}
	CHECK_EQUAL_WAVES(entries[%resistanceB], resistanceBRef, mode = WAVE_DATA)

	Make/D resistanceMaxRef = {1.6e9}
	CHECK_EQUAL_WAVES(entries[%resistanceMax], resistanceMaxRef, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%resistancePass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(entries[%resultsSweep], {"0;"}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%resultsResistanceA], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsResistanceB], TEXT_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckTestPulseLikeEpochs(str, PSQ_SE_TGS_BOTH)
	CheckBaselineChunks(str, PSQ_SE_TGS_BOTH)
End

static Function PS_SE3_preAcq(device)
	string device

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "TestPulseGroupSelector", str = "First")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "SealThreshold", var = 1)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineChunkLength", var = 500)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_SE3([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SEAL_EVALUATION)

	// tests pass, but only looking at first
	wv[][][0] = 1
	wv[][][1] = 1.4e3
	wv[][][2] = 0.8e3
	wv[][][3] = 1
End

static Function PS_SE3_REENTRY([str])
	string str

	variable sweepNo, autobiasV
	string lbl, failedPulses, spikeCounts

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%baselineQCChunk1], NULL_WAVE)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%testpulseGroupSel], {PSQ_SE_TGS_FIRST}, mode = WAVE_DATA)

	Make/D resistanceARef = {1.4e9}
	CHECK_EQUAL_WAVES(entries[%resistanceA], resistanceARef, mode = WAVE_DATA)

	CHECK_WAVE(entries[%resistanceB], NULL_WAVE)

	Make/D resistanceMaxRef = {1.4e9}
	CHECK_EQUAL_WAVES(entries[%resistanceMax], resistanceMaxRef, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%resistancePass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(entries[%resultsSweep], {"0;"}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%resultsResistanceA], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsResistanceB], NULL_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckTestPulseLikeEpochs(str, PSQ_SE_TGS_FIRST)
	CheckBaselineChunks(str, PSQ_SE_TGS_FIRST)
End

static Function PS_SE4_preAcq(device)
	string device

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "TestPulseGroupSelector", str = "Second")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "SealThreshold", var = 1)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineChunkLength", var = 500)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_SE4([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SEAL_EVALUATION)

	// tests pass, but only looking at second
	wv[][][0] = 1
	wv[][][1] = 0.6e3
	wv[][][2] = 1.6e3
	wv[][][3] = 1
End

static Function PS_SE4_REENTRY([str])
	string str

	variable sweepNo, autobiasV
	string lbl, failedPulses, spikeCounts

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%baselineQCChunk1], NULL_WAVE)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%testpulseGroupSel], {PSQ_SE_TGS_SECOND}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%resistanceA], NULL_WAVE)

	Make/D resistanceBRef = {1.6e9}
	CHECK_EQUAL_WAVES(entries[%resistanceB], resistanceBRef, mode = WAVE_DATA)

	Make/D resistanceMaxRef = {1.6e9}
	CHECK_EQUAL_WAVES(entries[%resistanceMax], resistanceMaxRef, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%resistancePass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(entries[%resultsSweep], {"0;"}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%resultsResistanceA], NULL_WAVE)
	CHECK_WAVE(entries[%resultsResistanceB], TEXT_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckTestPulseLikeEpochs(str, PSQ_SE_TGS_SECOND)
	CheckBaselineChunks(str, PSQ_SE_TGS_SECOND)
End

static Function PS_SE5_preAcq(device)
	string device

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "TestPulseGroupSelector", str = "Both")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "SealThreshold", var = 1)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineChunkLength", var = 500)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_SE5([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SEAL_EVALUATION)

	// tests fail as baseline QC fails in first chunk
	wv[0][][0] = 0
	wv[1][][0] = 1
	wv[][][1]  = 1.4e3
	wv[][][2]  = 1.6e3
	wv[][][3]  = 1
End

static Function PS_SE5_REENTRY([str])
	string str

	variable sweepNo, autobiasV
	string lbl, failedPulses, spikeCounts

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineQCChunk1], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%testpulseGroupSel], {PSQ_SE_TGS_BOTH}, mode = WAVE_DATA)

	Make/D resistanceARef = {1.4e9, 1.4e9, 1.4e9}
	CHECK_EQUAL_WAVES(entries[%resistanceA], resistanceARef, mode = WAVE_DATA)

	Make/D resistanceBRef = {1.6e9, 1.6e9, 1.6e9}
	CHECK_EQUAL_WAVES(entries[%resistanceB], resistanceBRef, mode = WAVE_DATA)

	Make/D resistanceMaxRef = {1.6e9, 1.6e9, 1.6e9}
	CHECK_EQUAL_WAVES(entries[%resistanceMax], resistanceMaxRef, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%resistancePass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(entries[%resultsSweep], {"0;", "1;", "2;"}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%resultsResistanceA], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsResistanceB], TEXT_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckTestPulseLikeEpochs(str, PSQ_SE_TGS_BOTH)
	CheckBaselineChunks(str, PSQ_SE_TGS_BOTH)
End

static Function PS_SE6_preAcq(device)
	string device

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "TestPulseGroupSelector", str = "Both")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "SealThreshold", var = 1)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineChunkLength", var = 500)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_SE6([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SEAL_EVALUATION)

	// tests fail as baseline QC fails in second chunk
	wv[0][][0] = 1
	wv[1][][0] = 0
	wv[][][1]  = 1.4e3
	wv[][][2]  = 1.6e3
	wv[][][3]  = 1
End

static Function PS_SE6_REENTRY([str])
	string str

	variable sweepNo, autobiasV
	string lbl, failedPulses, spikeCounts

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineQCChunk1], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%testpulseGroupSel], {PSQ_SE_TGS_BOTH}, mode = WAVE_DATA)

	Make/D resistanceARef = {1.4e9, 1.4e9, 1.4e9}
	CHECK_EQUAL_WAVES(entries[%resistanceA], resistanceARef, mode = WAVE_DATA)

	Make/D resistanceBRef = {1.6e9, 1.6e9, 1.6e9}
	CHECK_EQUAL_WAVES(entries[%resistanceB], resistanceBRef, mode = WAVE_DATA)

	Make/D resistanceMaxRef = {1.6e9, 1.6e9, 1.6e9}
	CHECK_EQUAL_WAVES(entries[%resistanceMax], resistanceMaxRef, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%resistancePass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(entries[%resultsSweep], {"0;", "1;", "2;"}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%resultsResistanceA], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsResistanceB], TEXT_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckTestPulseLikeEpochs(str, PSQ_SE_TGS_BOTH)
	CheckBaselineChunks(str, PSQ_SE_TGS_BOTH)
End

static Function PS_SE7_preAcq(device)
	string device

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "TestPulseGroupSelector", str = "Both")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "SealThreshold", var = 1)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NumberOfFailedSweeps", var = 1)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineChunkLength", var = 500)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_SE7([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SEAL_EVALUATION)

	// all tests fail
	wv[][][0] = 0
	wv[][][1] = 0.6e3
	wv[][][2] = 0.8e3
	wv[][][3] = 1
End

static Function PS_SE7_REENTRY([str])
	string str

	variable sweepNo, autobiasV
	string lbl, failedPulses, spikeCounts

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineQCChunk1], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%testpulseGroupSel], {PSQ_SE_TGS_BOTH}, mode = WAVE_DATA)

	Make/D resistanceARef = {0.6e9}
	CHECK_EQUAL_WAVES(entries[%resistanceA], resistanceARef, mode = WAVE_DATA)

	Make/D resistanceBRef = {0.8e9}
	CHECK_EQUAL_WAVES(entries[%resistanceB], resistanceBRef, mode = WAVE_DATA)

	Make/D resistanceMaxRef = {0.8e9}
	CHECK_EQUAL_WAVES(entries[%resistanceMax], resistanceMaxRef, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%resistancePass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(entries[%resultsSweep], {"0;"}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%resultsResistanceA], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsResistanceB], TEXT_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckTestPulseLikeEpochs(str, PSQ_SE_TGS_BOTH)
	CheckBaselineChunks(str, PSQ_SE_TGS_BOTH)
End

static Function PS_SE7a_preAcq(device)
	string device

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "TestPulseGroupSelector", str = "Both")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "SealThreshold", var = 1)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineChunkLength", var = 500)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_SE7a([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SEAL_EVALUATION)

	// all tests pass, except async QC
	wv[][][0] = 1
	wv[][][1] = 1.4e3
	wv[][][2] = 1.6e3
	wv[][][3] = 0
End

static Function PS_SE7a_REENTRY([str])
	string str

	variable sweepNo, autobiasV
	string lbl, failedPulses, spikeCounts, stimset, expected

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineQCChunk1], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%testpulseGroupSel], {PSQ_SE_TGS_BOTH}, mode = WAVE_DATA)

	Make/D resistanceARef = {1.4e9, 1.4e9, 1.4e9}
	CHECK_EQUAL_WAVES(entries[%resistanceA], resistanceARef, mode = WAVE_DATA)

	Make/D resistanceBRef = {1.6e9, 1.6e9, 1.6e9}
	CHECK_EQUAL_WAVES(entries[%resistanceB], resistanceBRef, mode = WAVE_DATA)

	Make/D resistanceMaxRef = {1.6e9, 1.6e9, 1.6e9}
	CHECK_EQUAL_WAVES(entries[%resistanceMax], resistanceMaxRef, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%resistancePass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(entries[%resultsSweep], {"0;", "1;", "2;"}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%resultsResistanceA], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsResistanceB], TEXT_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckTestPulseLikeEpochs(str, PSQ_SE_TGS_BOTH)
	CheckBaselineChunks(str, PSQ_SE_TGS_BOTH)
End

static Function PS_SE8_preAcq(device)
	string device

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "TestPulseGroupSelector", str = "Both")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "SealThreshold", var = 1)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NumberOfFailedSweeps", var = 1)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineChunkLength", var = 600)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_SE8([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SEAL_EVALUATION)

	// DAQ is not started as PRE_SWEEP_CONFIG_EVENT fails due to non-matching BaselineChunkLength
	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)
	CHECK_EQUAL_VAR(AFH_GetlastSweepAcquired(str), NaN)
End

static Function PS_SE9_preAcq(device)
	string device

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	// SamplingMultiplier uses default
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "SamplingFrequency", var = 10)

	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "TestPulseGroupSelector", str = "Both")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "SealThreshold", var = 1)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextStimSetName", str = "StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "NextIndexingEndStimSetName", str = "StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "BaselineChunkLength", var = 500)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PatchSeqSealChec_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_SE9([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_SEAL_EVALUATION)

	// all tests pass but sampling QC check fails
	wv[][][0] = 1
	wv[][][1] = 1.4e3
	wv[][][2] = 1.6e3
	wv[][][3] = 1
End

static Function PS_SE9_REENTRY([str])
	string str

	variable sweepNo, autobiasV
	string lbl, failedPulses, spikeCounts

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineQCChunk1], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%testpulseGroupSel], {PSQ_SE_TGS_BOTH}, mode = WAVE_DATA)

	Make/D resistanceARef = {1.4e9}
	CHECK_EQUAL_WAVES(entries[%resistanceA], resistanceARef, mode = WAVE_DATA)

	Make/D resistanceBRef = {1.6e9}
	CHECK_EQUAL_WAVES(entries[%resistanceB], resistanceBRef, mode = WAVE_DATA)

	Make/D resistanceMaxRef = {1.6e9}
	CHECK_EQUAL_WAVES(entries[%resistanceMax], resistanceMaxRef, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%resistancePass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(entries[%resultsSweep], {"0;"}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%resultsResistanceA], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsResistanceB], TEXT_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckTestPulseLikeEpochs(str, PSQ_SE_TGS_BOTH)
	CheckBaselineChunks(str, PSQ_SE_TGS_BOTH)
End
