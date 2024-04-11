#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=PatchSeqTestChirp

static Function [STRUCT DAQSettings s] PS_GetDAQSettings(string device)

	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_DB1"                                                     + \
	                             "__HS" + num2str(PSQ_TEST_HEADSTAGE) + "_DA0_AD0_CM:IC:_ST:PatchSeqChirp_DA_0:")

	return [s]
End

static Function GlobalPreAcq(string device)
	variable ret

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = 70)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = 25)

	ret = AI_SendToAmp(device, PSQ_TEST_HEADSTAGE, I_CLAMP_MODE, MCC_SETPRIMARYSIGNALLPF_FUNC, LPF_BYPASS)
	REQUIRE(!ret)
End

static Function GlobalPreInit(string device)

	AdjustAnalysisParamsForPSQ(device, "PatchSeqChirp_DA_0")
	PrepareForPublishTest()

	// Ensure that PRE_SET_EVENT already sees the override wave
	ResetOverrideResults()
End

static Function/WAVE GetLBNEntriesWave_IGNORE()

	string list = "sweepPass;setPass;insideBounds;baselinePass;spikePass;stimsetPass;"          \
	              + "boundsState;boundsAction;initialDAScale;DAScale;resistance;spikeCheck;"    \
	              + "samplingPass;autobiasTargetV;initUserOnsetDelay;userOnsetDelay;asyncPass;" \
	              + "initLowPassFilter;lowPassFilter"

	Make/FREE/WAVE/N=(ItemsInList(list)) wv
	SetDimensionLabels(wv, list, ROWS)

	return wv
End

static Function/WAVE GetLBNEntries_IGNORE(string device, variable sweepNo)

	WAVE numericalValues = GetLBNumericalValues(device)

	WAVE/WAVE wv = GetLBNEntriesWave_IGNORE()

	wv[%sweepPass]          = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	wv[%setPass]            = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SET_PASS)
	wv[%insideBounds]       = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_CR_INSIDE_BOUNDS)
	wv[%baselinePass]       = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	wv[%spikePass]          = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SPIKE_PASS)
	wv[%stimsetPass]        = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_CR_STIMSET_QC)
	wv[%boundsState]        = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_STATE)
	wv[%boundsAction]       = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_ACTION)
	wv[%initialDAScale]     = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_INITIAL_SCALE)
	wv[%DAScale]            = GetLBNSingleEntry_IGNORE(device, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	wv[%resistance]         = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_CR_RESISTANCE)
	wv[%spikeCheck]         = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_CR_SPIKE_CHECK)
	wv[%samplingPass]       = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	wv[%autobiasTargetV]    = GetLBNSingleEntry_IGNORE(device, sweepNo, "Autobias Vcom")
	wv[%initUserOnsetDelay] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_CR_INIT_UOD)
	wv[%userOnsetDelay]     = GetLBNSingleEntry_IGNORE(device, sweepNo, "Delay onset user")
	wv[%asyncPass]          = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)
	wv[%initLowPassFilter]  = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_CR_INIT_LPF)
	wv[%lowPassFilter]      = GetLBNSingleEntry_IGNORE(device, sweepNo, "LPF cutoff")

	return wv
End

static Function/WAVE GetLBNSingleEntry_IGNORE(device, sweepNo, name)
	string   device
	variable sweepNo
	string   name

	variable val
	string   key

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	strswitch(name)
		case PSQ_FMT_LBN_SWEEP_PASS:
		case PSQ_FMT_LBN_CR_INSIDE_BOUNDS:
		case PSQ_FMT_LBN_CR_BOUNDS_ACTION:
		case PSQ_FMT_LBN_SAMPLING_PASS:
		case PSQ_FMT_LBN_ASYNC_PASS:
		case PSQ_FMT_LBN_CR_STIMSET_QC:
			key = CreateAnaFuncLBNKey(PSQ_CHIRP, name, query = 1)
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_CR_BOUNDS_STATE:
			key = CreateAnaFuncLBNKey(PSQ_CHIRP, name, query = 1)
			return GetLastSettingTextIndepEachSCI(numericalValues, textualValues, sweepNo, PSQ_TEST_HEADSTAGE, key, UNKNOWN_MODE)
		case PSQ_FMT_LBN_BL_QC_PASS:
		case PSQ_FMT_LBN_SPIKE_PASS:
		case PSQ_FMT_LBN_PULSE_DUR:
			key = CreateAnaFuncLBNKey(PSQ_CHIRP, name, query = 1)
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case STIMSET_SCALE_FACTOR_KEY:
		case "Autobias Vcom":
		case "LPF cutoff":
			return GetLastSettingEachSCI(numericalValues, sweepNo, name, PSQ_TEST_HEADSTAGE, DATA_ACQUISITION_MODE)
		case "Delay onset user":
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, name, PSQ_TEST_HEADSTAGE, DATA_ACQUISITION_MODE)
		case PSQ_FMT_LBN_SET_PASS:
		case PSQ_FMT_LBN_CR_SPIKE_CHECK:
		case PSQ_FMT_LBN_INITIAL_SCALE:
		case PSQ_FMT_LBN_CR_RESISTANCE:
		case PSQ_FMT_LBN_CR_INIT_UOD:
		case PSQ_FMT_LBN_CR_INIT_LPF:
			key = CreateAnaFuncLBNKey(PSQ_CHIRP, name, query = 1)
			val = GetLastSettingIndepSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
			Make/D/FREE wv = {val}
			return wv
		default:
			FAIL()
	endswitch
End

static Function CheckMCCLPF(string device, variable expectedValue)
	variable val

	val = AI_SendToAmp(device, PSQ_TEST_HEADSTAGE, I_CLAMP_MODE, MCC_GETPRIMARYSIGNALLPF_FUNC, NaN, selectAmp = 0)
	CHECK_EQUAL_VAR(val, expectedValue)
End

static Function CheckChirpUserEpochs(string device, WAVE baselineChunks, WAVE chirpChunk, WAVE spikeChunk, [variable incomplete, variable sweep])

	if(ParamIsDefault(incomplete))
		incomplete = 0
	else
		incomplete = !!incomplete
	endif

	if(ParamIsDefault(sweep))
		sweep = NaN
	endif

	CheckUserEpochs(device, chirpChunk, EPOCH_SHORTNAME_USER_PREFIX + "CR_CE", sweep = sweep, ignoreIncomplete = incomplete)
	CheckUserEpochs(device, spikeChunk, EPOCH_SHORTNAME_USER_PREFIX + "CR_SE", sweep = sweep, ignoreIncomplete = incomplete)
	CheckPSQChunkTimes(device, baselineChunks, sweep = sweep)
End

static Function PS_CR1_preAcq(string device)
	variable ret

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// BBAA but with zero value which results in PSQ_CR_RERUN
//
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR1([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests fail
	// layer 0: BL
	// layer 1: Maximum of AD (0 triggers PSQ_CR_RERUN)
	// layer 2: Minimum of AD (0 triggers PSQ_CR_RERUN)
	// layer 3: Spikes check during chirp (not done)
	// layer 4: async QC
	wv = 0
End

static Function PS_CR1_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 2

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_WAVE(lbnEntries[%insideBounds], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsState], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsAction], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520}, empty, empty, incomplete = 1)
End

static Function PS_CR2_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "UserOnsetDelay", var = 2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	PGC_SetAndActivateControl(device, "setvar_DataAcq_OnsetDelayUser", val = 1)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR2([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests pass
	// layer 0: BL
	// layer 1: Maximum of AD (35 triggers PSQ_CR_PASS)
	// layer 2: Minimum of AD (-25 triggers PSQ_CR_PASS)
	// layer 3: Spikes check during chirp (not done)
	// layer 4: async QC
	wv[][][0] = 1
	wv[][][1] = 35
	wv[][][2] = -25
	wv[][][4] = 1
End

static Function PS_CR2_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 2

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {2, 2, 2}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 1)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20 + 2, 520 + 2, 2020 + 2, 2520 + 2}, {522, 854.6995}, empty)
End

static Function PS_CR2a_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Depolarized")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR2a([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests pass
	// layer 0: BL
	// layer 1: Maximum of AD (35 triggers PSQ_CR_PASS)
	// layer 2: Minimum of AD (0)
	// layer 3: Spikes check during chirp (not done)
	// layer 4: async QC
	wv[][][0] = 1
	wv[][][1] = 35
	wv[][][2] = 0
	wv[][][4] = 1
End

static Function PS_CR2a_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 2

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BA__", "BA__", "BA__"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	// CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 852.6995})
End

static Function PS_CR2b_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Hyperpolarized")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR2b([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests pass
	// layer 0: BL
	// layer 1: Maximum of AD (0)
	// layer 2: Minimum of AD (-25 triggers PSQ_CR_PASS)
	// layer 3: Spikes check during chirp (not done)
	// layer 4: async QC
	wv[][][0] = 1
	wv[][][1] = 0
	wv[][][2] = -25
	wv[][][4] = 1
End

static Function PS_CR2b_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 2

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"__BA", "__BA", "__BA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 852.6995}, empty)
End

static Function PS_CR3_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AmpBesselFilter", var = 14)
	// AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR3([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// BL fails, rest passes
	// layer 0: BL
	// layer 1: Maximum of AD (35 would be PSQ_CR_PASS but we abort early due to baseline not passing)
	// layer 2: Minimum of AD (-25 would be PSQ_CR_PASS but we abort early due to baseline not passing)
	// layer 3: Spikes check during chirp (not done)
	// layer 4: async QC
	wv[][][0] = 0
	wv[][][1] = 35
	wv[][][2] = -25
	wv[][][4] = 1
End

static Function PS_CR3_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 2

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_WAVE(lbnEntries[%insideBounds], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsState], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsAction], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {14, 14, 14}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	// CheckChirpUserEpochs(str, {20, 520}, empty, incomplete = 1)
End

// No a, b as we don't do boundsState evaluation

static Function PS_CR4_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AmpBesselFilter", var = 14)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AmpBesselFilterRestore", var = 0)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR4([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// async QC passes
	wv[][][4] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp
	// layer 4: async QC

	// INCREASE (BAAA)
	wv[][0][1] = 35
	wv[][0][2] = -15

	// PASS
	wv[][1][1] = 39
	wv[][1][2] = -21

	// DECREASE (AABA)
	wv[][2][1] = 45
	wv[][2][2] = -21

	// PASS
	wv[][3][1] = 38
	wv[][3][2] = -22

	// PASS
	wv[][4][1] = 37
	wv[][4][2] = -23

	// PASS
	wv[][5][1] = 38
	wv[][5][2] = -24
End

static Function PS_CR4_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 5

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {NaN, 1, NaN, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BAAA", "BABA", "AABA", "BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 41, 41, 42, 42, 42}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70, 70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {14, 14, 14, 14, 14, 14}, mode = WAVE_DATA)
	CheckMCCLPF(str, 14)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])

	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 0)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 1)
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 2)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 3)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 4)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 5)
End

static Function PS_CR4a_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Depolarized")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR4a([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// async QC passes
	wv[][][4] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp
	// layer 4: async QC

	// INCREASE (BB__)
	wv[][0][1] = 15
	wv[][0][2] = 0

	// PASS
	wv[][1][1] = 39
	wv[][1][2] = 0

	// DECREASE (AA__)
	wv[][2][1] = 45
	wv[][2][2] = 0

	// PASS
	wv[][3][1] = 38
	wv[][3][2] = 0

	// PASS
	wv[][4][1] = 37
	wv[][4][2] = 0

	// PASS
	wv[][5][1] = 38
	wv[][5][2] = 0
End

static Function PS_CR4a_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 5

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {NaN, 1, NaN, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BB__", "BA__", "AA__", "BA__", "BA__", "BA__"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 64, 64, 44, 44, 44}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70, 70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 0)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 1)
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 2)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 3)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 4)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 5)
End

static Function PS_CR4b_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Hyperpolarized")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR4b([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// async QC passes
	wv[][][4] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp
	// layer 4: async QC

	// INCREASE (__AA)
	wv[][0][1] = 0
	wv[][0][2] = -15

	// PASS
	wv[][1][1] = 0
	wv[][1][2] = -21

	// DECREASE (__BB)
	wv[][2][1] = 0
	wv[][2][2] = -41

	// PASS
	wv[][3][1] = 0
	wv[][3][2] = -22

	// PASS
	wv[][4][1] = 0
	wv[][4][2] = -23

	// PASS
	wv[][5][1] = 38
	wv[][5][2] = -24
End

static Function PS_CR4b_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 5

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {NaN, 1, NaN, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"__AA", "__BA", "__BB", "__BA", "__BA", "__BA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 56, 56, 40, 40, 40}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70, 70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 0)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 1)
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 2)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 3)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 4)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 5)
End

static Function PS_CR5_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR5([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// async QC passes
	wv[][][4] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 4: async QC

	// INCREASE (BBBA)
	wv[][0][1] = 15
	wv[][0][2] = -25

	// PASS
	wv[][1][1] = 39
	wv[][1][2] = -21

	// DECREASE (BABB)
	wv[][2][1] = 35
	wv[][2][2] = -45

	// PASS
	wv[][3][1] = 38
	wv[][3][2] = -22

	// PASS
	wv[][4][1] = 37
	wv[][4][2] = -23

	// PASS
	wv[][5][1] = 38
	wv[][5][2] = -24
End

static Function PS_CR5_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 5

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {NaN, 1, NaN, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BBBA", "BABA", "BABB", "BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 49, 49, 38, 38, 38}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70, 70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 0)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 1)
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 2)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 3)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 4)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 5)
End

// No a, b as this is the same as PS_CR4 for non-symmetric

static Function PS_CR6_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR6([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// async QC passes
	wv[][][4] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp (not done)
	// layer 4: async QC

	// INCREASE (BBAA)
	wv[][0][1] = 15
	wv[][0][2] = -15

	// PASS
	wv[][1][1] = 39
	wv[][1][2] = -21

	// DECREASE (AABB)
	wv[][2][1] = 45
	wv[][2][2] = -45

	// PASS
	wv[][3][1] = 38
	wv[][3][2] = -22

	// PASS
	wv[][4][1] = 37
	wv[][4][2] = -23

	// PASS
	wv[][5][1] = 38
	wv[][5][2] = -24
End

static Function PS_CR6_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 5

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {NaN, 1, NaN, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BBAA", "BABA", "AABB", "BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 60, 60, 40, 40, 40}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70, 70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 0)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 1)
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 2)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 3)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 4)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 5)
End

// No a, b as this is the same as PS_CR4 for non-symmetric

static Function PS_CR7_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR7([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// async QC passes
	wv[][][4] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp (not done)
	// layer 4: async QC

	// RERUN (AAAA)
	wv[][0][1] = 45
	wv[][0][2] = -15

	// RERUN (AAAA)
	wv[][1][1] = 100
	wv[][1][2] = 110

	// PASS
	wv[][2][1] = 38
	wv[][2][2] = -22

	// PASS
	wv[][3][1] = 38
	wv[][3][2] = -22

	// PASS
	wv[][4][1] = 38
	wv[][4][2] = -22
End

static Function PS_CR7_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 4

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {NaN, NaN, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {0, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"AAAA", "AAAA", "BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_RERUN, PSQ_CR_RERUN, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 0)
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 1)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 2)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 3)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 4)
End

// No a, b as we can't have RERUN for non-symmetric

static Function PS_CR8_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR8([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// async QC passes
	wv[][][4] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp (not done)

	// RERUN (BBBB)
	wv[][0][1] = 15
	wv[][0][2] = -45

	// RERUN (BBBB)
	wv[][1][1] = -100
	wv[][1][2] = -110

	// PASS
	wv[][2][1] = 38
	wv[][2][2] = -22

	// PASS
	wv[][3][1] = 38
	wv[][3][2] = -22

	// PASS
	wv[][4][1] = 38
	wv[][4][2] = -22
End

static Function PS_CR8_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 4

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {NaN, NaN, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {0, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BBBB", "BBBB", "BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_RERUN, PSQ_CR_RERUN, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 0)
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 1)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 2)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 3)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 4)
End

// No a, b as we can't have RERUN for non-symmetric

static Function PS_CR9_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// Enough passing sweeps but not enough with the same DAScale
//
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR9([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// async QC passes
	wv[][][4] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp (not done)
	// layer 4: async QC

	// PASS
	wv[][0][1] = 38
	wv[][0][2] = -22

	// PASS
	wv[][1][1] = 38
	wv[][1][2] = -22

	// DECREASE (AABB)
	wv[][2][1] = 50
	wv[][2][2] = -60

	// INCREASE (BAAA)
	wv[][3][1] = 38
	wv[][3][2] = -15

	// PASS
	wv[][4][1] = 38
	wv[][4][2] = -22

	// PASS
	wv[][5][1] = 38
	wv[][5][2] = -22
End

static Function PS_CR9_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 5

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {1, 1, 0, 0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {1, 1, NaN, NaN, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 1, 0, 0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BABA", "BABA", "AABB", "BAAA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30, 17, 23, 23}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70, 70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 0)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 1)
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 2)
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 3)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 4)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 5)
End

static Function PS_CR9a_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Depolarized")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// Enough passing sweeps but not enough with the same DAScale
//
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR9a([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// async QC passes
	wv[][][4] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp (not done)
	// layer 4: async QC

	// PASS
	wv[][0][1] = 38
	wv[][0][2] = 0

	// PASS
	wv[][1][1] = 38
	wv[][1][2] = 0

	// DECREASE (AA__)
	wv[][2][1] = 50
	wv[][2][2] = 0

	// INCREASE (BB__)
	wv[][3][1] = 18
	wv[][3][2] = 0

	// PASS
	wv[][4][1] = 38
	wv[][4][2] = 0

	// PASS
	wv[][5][1] = 38
	wv[][5][2] = 0
End

static Function PS_CR9a_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 5

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {1, 1, 0, 0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {1, 1, NaN, NaN, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 1, 0, 0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BA__", "BA__", "AA__", "BB__", "BA__", "BA__"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30, 18, 32, 32}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70, 70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 0)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 1)
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 2)
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 3)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 4)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 5)
End

static Function PS_CR9b_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Hyperpolarized")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// Enough passing sweeps but not enough with the same DAScale
//
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR9b([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// async QC passes
	wv[][][4] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp (not done)
	// layer 4: async QC

	// PASS
	wv[][0][1] = 0
	wv[][0][2] = -22

	// PASS
	wv[][1][1] = 0
	wv[][1][2] = -22

	// DECREASE (__BB)
	wv[][2][1] = 0
	wv[][2][2] = -60

	// INCREASE (__AA)
	wv[][3][1] = 0
	wv[][3][2] = -15

	// PASS
	wv[][4][1] = 0
	wv[][4][2] = -22

	// PASS
	wv[][5][1] = 0
	wv[][5][2] = -22
End

static Function PS_CR9b_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 5

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {1, 1, 0, 0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {1, 1, NaN, NaN, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 1, 0, 0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"__BA", "__BA", "__BB", "__AA", "__BA", "__BA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30, 15, 28, 28}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70, 70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 0)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 1)
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 2)
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 3)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 4)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 5)
End

static Function PS_CR10_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// Early abort as not enough sweeps with the same DASCale value pass
//
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR10([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// async QC passes
	wv[][][4] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp (not done)
	// layer 4: async QC

	// PASS
	wv[][0][1] = 38
	wv[][0][2] = -22

	// DECREASE (AABB)
	wv[][1][1] = 50
	wv[][1][2] = -60

	// PASS
	wv[][2][1] = 38
	wv[][2][2] = -22

	// INCREASE (BAAA)
	wv[][3][1] = 38
	wv[][3][2] = -15

	// PASS
	wv[][4][1] = 38
	wv[][4][2] = -22
End

static Function PS_CR10_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 4

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {1, 0, 1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {1, NaN, 1, NaN, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 0, 1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BABA", "AABB", "BABA", "BAAA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_PASS, PSQ_CR_INCREASE, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 17, 17, 23}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 0)
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 1)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 2)
	CheckChirpUserEpochs(str, {20, 520}, {520, 1038.854}, empty, sweep = 3)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, empty, sweep = 4)
End

// No a, b as this is the same as PS_CR9 for non-symmetric

static Function PS_CR11_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "FailedLevel", var = 10)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "DAScaleOperator", str = "+")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "DAScaleModifier", var = 1.2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR11([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests fail
	// layer 0: BL
	// layer 1: Maximum of AD (0 triggers PSQ_CR_RERUN)
	// layer 2: Minimum of AD (0 triggers PSQ_CR_RERUN)
	// layer 3: Spikes check during chirp fails
	// layer 4: async QC

	// first BL chunk passes, later ones fail. This is done so that
	// we reach the chirp region for performing spike checks.
	wv          = 0
	wv[0][][0]  = 1
	wv[1,][][0] = 0
End

static Function PS_CR11_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 2

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%baselinePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikePass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_WAVE(lbnEntries[%insideBounds], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsState], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsAction], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 31, 32}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520}, empty, empty, incomplete = 1)
End

// No a, b as boundsState evaluation is always passing

static Function PS_CR12_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "FailedLevel", var = 10)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "DAScaleOperator", str = "+")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "DAScaleModifier", var = 1.2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR12([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests pass
	// layer 0: BL
	// layer 1: Maximum of AD (35 triggers PSQ_CR_PASS)
	// layer 2: Minimum of AD (-25 triggers PSQ_CR_PASS)
	// layer 3: Spikes check during chirp passes
	// layer 4: async QC
	wv[][][0] = 1
	wv[][][1] = 35
	wv[][][2] = -25
	wv[][][3] = 1
	wv[][][4] = 1
End

static Function PS_CR12_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 2

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikePass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 852.6995}, {520, 1519.992})
End

// No a, b as boundsState evaluation is always passing

static Function PS_CR13_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "FailedLevel", var = 10)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "DAScaleOperator", str = "+")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "DAScaleModifier", var = 1.2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// Early abort as not enough sweeps with the same DASCale value pass
//
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR13([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// layer 0: BL
	// layer 1: Maximum of AD (35 triggers PSQ_CR_PASS)
	// layer 2: Minimum of AD (-25 triggers PSQ_CR_PASS)
	wv[][][0] = 1
	wv[][][1] = 35
	wv[][][2] = -25

	// layer 3: Spikes check during chirp
	wv[][0][3] = 0
	wv[][1][3] = 1
	wv[][2][3] = 1
	wv[][3][3] = 0
	wv[][4][3] = 1

	// async QC passes
	wv[][0][4] = 1
	wv[][1][4] = 1
	wv[][2][4] = 1
	wv[][3][4] = 1
	wv[][4][4] = 0
End

static Function PS_CR13_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 4

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 1, 1, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {NaN, 1, 1, NaN, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1, 1, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikePass], {0, 1, 1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {NaN, 1, 1, NaN, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"", "BABA", "BABA", "", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {NaN, PSQ_CR_PASS, PSQ_CR_PASS, NaN, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 31, 31, 31, 32}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520}, empty, empty, sweep = 0, incomplete = 1)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, {520, 1519.992}, sweep = 1)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, {520, 1519.992}, sweep = 2)
	CheckChirpUserEpochs(str, {20, 520}, empty, empty, sweep = 3, incomplete = 1)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 1038.854}, {520, 1519.992}, sweep = 4)
End

static Function PS_CR13a_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "FailedLevel", var = 10)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "DAScaleOperator", str = "+")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "DAScaleModifier", var = 1.2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "UserOnsetDelay", var = 2)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// Early abort as not enough sweeps with the same DASCale value pass
// and user onset delay
//
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR13a([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// layer 0: BL
	// layer 1: Maximum of AD (35 triggers PSQ_CR_PASS)
	// layer 2: Minimum of AD (-25 triggers PSQ_CR_PASS)
	wv[][][0] = 1
	wv[][][1] = 35
	wv[][][2] = -25

	// layer 3: Spikes check during chirp
	wv[][0][3] = 0
	wv[][1][3] = 1
	wv[][2][3] = 1
	wv[][3][3] = 0
	wv[][4][3] = 1

	// async QC passes
	wv[][0][4] = 1
	wv[][1][4] = 1
	wv[][2][4] = 1
	wv[][3][4] = 1
	wv[][4][4] = 0
End

static Function PS_CR13a_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 4

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 1, 1, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {NaN, 1, 1, NaN, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1, 1, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikePass], {0, 1, 1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {NaN, 1, 1, NaN, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"", "BABA", "BABA", "", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {NaN, PSQ_CR_PASS, PSQ_CR_PASS, NaN, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 31, 31, 31, 32}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {2, 2, 2, 2, 2}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20 + 2, 520 + 2}, empty, empty, sweep = 0, incomplete = 1)
	CheckChirpUserEpochs(str, {20 + 2, 520 + 2, 2020 + 2, 2520 + 2}, {520 + 2, 1038.854 + 2}, {520 + 2, 1519.992 + 2}, sweep = 1)
	CheckChirpUserEpochs(str, {20 + 2, 520 + 2, 2020 + 2, 2520 + 2}, {520 + 2, 1038.854 + 2}, {520 + 2, 1519.992 + 2}, sweep = 2)
	CheckChirpUserEpochs(str, {20 + 2, 520 + 2}, empty, empty, sweep = 3, incomplete = 1)
	CheckChirpUserEpochs(str, {20 + 2, 520 + 2, 2020 + 2, 2520 + 2}, {520 + 2, 1038.854 + 2}, {520 + 2, 1519.992 + 2}, sweep = 4)
End

// No a, b as boundsState evaluation is always passing

static Function PS_CR14_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SamplingFrequency", var = 10)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// Same as PS_CR1 but with failing sampling interval check
//
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR14([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests fail
	// layer 0: BL
	// layer 1: Maximum of AD (0 triggers PSQ_CR_RERUN)
	// layer 2: Minimum of AD (0 triggers PSQ_CR_RERUN)
	// layer 3: Spikes check during chirp (not done)
	// layer 4: async QC
	wv = 0
End

static Function PS_CR14_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 0

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {0}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1}, mode = WAVE_DATA)

	CHECK_WAVE(lbnEntries[%insideBounds], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsState], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsAction], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520}, empty, empty, incomplete = 1)
End

// No a, b as boundsState evaluation is always passing

static Function PS_CR15_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AutobiasTargetV", var = 45)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AutobiasTargetVAtSetEnd", var = 55)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR15([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests pass
	// layer 0: BL
	// layer 1: Maximum of AD (35 triggers PSQ_CR_PASS)
	// layer 2: Minimum of AD (-25 triggers PSQ_CR_PASS)
	// layer 3: Spikes check during chirp (not done)
	// layer 4: async QC
	//
	// AutobiasTargetV/AutobiasTargetVAtSetEnd are present
	wv[][][0] = 1
	wv[][][1] = 35
	wv[][][2] = -25
	wv[][][4] = 1
End

static Function PS_CR15_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 2

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {45, 45, 45}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 55)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 852.6995}, empty)
End

// No a, b as boundsState evaluation is always passing

static Function PS_CR16_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AutobiasTargetV", var = 45)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AutobiasTargetVAtSetEnd", var = 55)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "UseTrueRestingMembranePotentialVoltage", var = 0)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR16([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests pass
	// layer 0: BL
	// layer 1: Maximum of AD (35 triggers PSQ_CR_PASS)
	// layer 2: Minimum of AD (-25 triggers PSQ_CR_PASS)
	// layer 3: Spikes check during chirp (not done)
	// layer 4: async QC
	//
	// AutobiasTargetV/AutobiasTargetVAtSetEnd/UseTrueRestingMembranePotentialVoltage are present
	wv[][][0] = 1
	wv[][][1] = 35
	wv[][][2] = -25
	wv[][][4] = 1
End

static Function PS_CR16_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 2

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {45, 45, 45}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 55)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 852.6995}, empty)
End

static Function PS_CR17_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "UserOnsetDelay", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR17([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// layer 0: BL
	// layer 1: Maximum of AD (35 triggers PSQ_CR_PASS)
	// layer 2: Minimum of AD (-25 triggers PSQ_CR_PASS)
	// layer 3: Spikes check during chirp (not done)
	// layer 4: async QC

	// BL targetV fails for 1 first chunk in first sweep
	wv[][][0]      = 1
	wv[0][0][0][2] = 0

	wv[][][1] = 35
	wv[][][2] = -25
	wv[][][4] = 1
End

static Function PS_CR17_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 3

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {NaN, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"", "BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {NaN, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70, 70, 70, 70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF, PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, {20, 520}, empty, empty, sweep = 0, incomplete = 1)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 852.6995}, empty, sweep = 1)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 852.6995}, empty, sweep = 2)
	CheckChirpUserEpochs(str, {20, 520, 2020, 2520}, {520, 852.6995}, empty, sweep = 3)
End

static Function PS_CR18_preAcq(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var = 20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var = 40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var = 100)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "UserOnsetDelay", var = 0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str = "Symmetric")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfFailedSweeps", var = 3)
	// AmpBesselFilter/AmpBesselFilterRestore defaults

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_CR18([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests would pass, but the NumberOfChirpCycles is too large
	// layer 0: BL
	// layer 1: Maximum of AD (35 triggers PSQ_CR_PASS)
	// layer 2: Minimum of AD (-25 triggers PSQ_CR_PASS)
	// layer 3: Spikes check during chirp (not done)
	// layer 4: async QC
	wv[][][0] = 1
	wv[][][1] = 35
	wv[][][2] = -25
	wv[][][4] = 1
End

static Function PS_CR18_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 0

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%baselinePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%asyncPass], {1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)
	CHECK_EQUAL_WAVES(lbnEntries[%stimsetPass], {0}, mode = WAVE_DATA)

	CHECK_WAVE(lbnEntries[%insideBounds], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsState], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsAction], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autobiasTargetV], {70}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 70)

	CHECK_EQUAL_WAVES(lbnEntries[%initUserOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%userOnsetDelay], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_OnsetDelayUser"), 0)

	CHECK_EQUAL_WAVES(lbnEntries[%initLowPassFilter], {LPF_BYPASS}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%lowPassFilter], {PSQ_CR_DEFAULT_LPF}, mode = WAVE_DATA)
	CheckMCCLPF(str, LPF_BYPASS)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	Make/FREE/N=0 empty
	CheckChirpUserEpochs(str, empty, empty, empty, incomplete = 1)
End
