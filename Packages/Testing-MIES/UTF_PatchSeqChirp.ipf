#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma ModuleName=PatchSeqTestChirp

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(s, device, [postInitializeFunc, preAcquireFunc])
	STRUCT DAQSettings& s
	string device
	FUNCREF CALLABLE_PROTO postInitializeFunc, preAcquireFunc

	string stimset, unlockedDevice

	KillWaves/Z root:overrideResults
	Make/O/N=(0) root:overrideResults/Wave=overrideResults
	Note/K overrideResults

	if(!ParamIsDefault(postInitializeFunc))
		postInitializeFunc(device)
	endif

	unlockedDevice = DAP_CreateDAEphysPanel()

	PGC_SetAndActivateControl(unlockedDevice, "popup_MoreSettings_Devices", str=device)
	PGC_SetAndActivateControl(unlockedDevice, "button_SettingsPlus_LockDevice")

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

	stimset = "PatchSeqChirp_DA_0"
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

static Function/WAVE GetLBNEntriesWave_IGNORE()

	string list = "sweepPass;setPass;insideBounds;baselinePass;spikePass;"                    \
			      + "boundsState;boundsAction;initialDAScale;DAScale;resistance;spikeCheck;" \
			      + "samplingPass"

	Make/FREE/WAVE/N=(ItemsInList(list)) wv
	SetDimensionLabels(wv, list, ROWS)

	return wv
End

static Function/WAVE GetLBNEntries_IGNORE(string device, variable sweepNo)

	WAVE numericalValues = GetLBNumericalValues(device)

	WAVE/WAVE wv = GetLBNEntriesWave_IGNORE()

	wv[%sweepPass] = GetResults_IGNORE(device, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	wv[%setPass] = GetResults_IGNORE(device, sweepNo, PSQ_FMT_LBN_SET_PASS)
	wv[%insideBounds] = GetResults_IGNORE(device, sweepNo, PSQ_FMT_LBN_CR_INSIDE_BOUNDS)
	wv[%baselinePass] = GetResults_IGNORE(device, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	wv[%spikePass] = GetResults_IGNORE(device, sweepNo, PSQ_FMT_LBN_CR_SPIKE_PASS)
	wv[%boundsState] = GetResults_IGNORE(device, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_STATE)
	wv[%boundsAction] = GetResults_IGNORE(device, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_ACTION)
	wv[%initialDAScale] = GetResults_IGNORE(device, sweepNo, PSQ_FMT_LBN_INITIAL_SCALE)
	wv[%DAScale] = GetResults_IGNORE(device, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	wv[%resistance] = GetResults_IGNORE(device, sweepNo, PSQ_FMT_LBN_CR_RESISTANCE)
	wv[%spikeCheck] = GetResults_IGNORE(device, sweepNo, PSQ_FMT_LBN_CR_SPIKE_CHECK)
	wv[%samplingPass] = GetResults_IGNORE(device, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)

	return wv
End

static Function/WAVE GetResults_IGNORE(device, sweepNo, name)
	string device
	variable sweepNo
	string name

	variable val
	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues = GetLBTextualValues(device)

	strswitch(name)
		case PSQ_FMT_LBN_SWEEP_PASS:
		case PSQ_FMT_LBN_CR_INSIDE_BOUNDS:
		case PSQ_FMT_LBN_CR_BOUNDS_ACTION:
		case PSQ_FMT_LBN_SAMPLING_PASS:
			key = CreateAnaFuncLBNKey(PSQ_CHIRP, name, query = 1)
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_CR_BOUNDS_STATE:
			key = CreateAnaFuncLBNKey(PSQ_CHIRP, name, query = 1)
			return GetLastSettingTextIndepEachSCI(numericalValues, textualValues, sweepNo, PSQ_TEST_HEADSTAGE, key, UNKNOWN_MODE)
		case PSQ_FMT_LBN_BL_QC_PASS:
		case PSQ_FMT_LBN_CR_SPIKE_PASS:
		case PSQ_FMT_LBN_PULSE_DUR:
			key = CreateAnaFuncLBNKey(PSQ_CHIRP, name, query = 1)
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case STIMSET_SCALE_FACTOR_KEY:
			return GetLastSettingEachSCI(numericalValues, sweepNo, name, PSQ_TEST_HEADSTAGE, DATA_ACQUISITION_MODE)
		case PSQ_FMT_LBN_SET_PASS:
		case PSQ_FMT_LBN_CR_SPIKE_CHECK:
		case PSQ_FMT_LBN_INITIAL_SCALE:
		case PSQ_FMT_LBN_CR_RESISTANCE:
			key = CreateAnaFuncLBNKey(PSQ_CHIRP, name, query = 1)
			val = GetLastSettingIndepSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
			Make/D/FREE wv = {val}
			return wv
		default:
			FAIL()
	endswitch
End

static Function PS_CR1_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Symmetric")
End

// BBAA but with zero value which results in PSQ_CR_RERUN
//
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR1_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests fail
	// layer 0: BL
	// layer 1: Maximum of AD (0 triggers PSQ_CR_RERUN)
	// layer 2: Minimum of AD (0 triggers PSQ_CR_RERUN)
	// layer 3: Spikes check during chirp (not done)
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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_WAVE(lbnEntries[%insideBounds], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsState], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsAction], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520})
End

static Function PS_CR2_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Symmetric")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR2([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR2_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests pass
	// layer 0: BL
	// layer 1: Maximum of AD (35 triggers PSQ_CR_PASS)
	// layer 2: Minimum of AD (-25 triggers PSQ_CR_PASS)
	// layer 3: Spikes check during chirp (not done)
	wv[][][0] = 1
	wv[][][1] = 35
	wv[][][2] = -25
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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End

static Function PS_CR2a_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Depolarized")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR2a([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR2a_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests pass
	// layer 0: BL
	// layer 1: Maximum of AD (35 triggers PSQ_CR_PASS)
	// layer 2: Minimum of AD (0)
	// layer 3: Spikes check during chirp (not done)
	wv[][][0] = 1
	wv[][][1] = 35
	wv[][][2] = 0
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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BA__", "BA__", "BA__"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End

static Function PS_CR2b_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Hyperpolarized")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR2b([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR2b_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests pass
	// layer 0: BL
	// layer 1: Maximum of AD (0)
	// layer 2: Minimum of AD (-25 triggers PSQ_CR_PASS)
	// layer 3: Spikes check during chirp (not done)
	wv[][][0] = 1
	wv[][][1] = 0
	wv[][][2] = -25
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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"__BA", "__BA", "__BA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End

static Function PS_CR3_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Symmetric")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR3([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR3_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// BL fails, rest passes
	// layer 0: BL
	// layer 1: Maximum of AD (35 would be PSQ_CR_PASS but we abort early due to baseline not passing)
	// layer 2: Minimum of AD (-25 would be PSQ_CR_PASS but we abort early due to baseline not passing)
	// layer 3: Spikes check during chirp (not done)
	wv[][][0] = 0
	wv[][][1] = 35
	wv[][][2] = -25
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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_WAVE(lbnEntries[%insideBounds], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsState], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsAction], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520})
End

// No a, b as we don't do boundsState evaluation

static Function PS_CR4_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Symmetric")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR4([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR4_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp

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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BAAA", "BABA", "AABA", "BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 41, 41, 42, 42, 42}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 2)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 3)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 4)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 5)
End

static Function PS_CR4a_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Depolarized")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR4a([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR4a_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp

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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BB__", "BA__", "AA__", "BA__", "BA__", "BA__"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 64, 64, 44, 44, 44}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 2)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 3)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 4)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 5)
End

static Function PS_CR4b_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Hyperpolarized")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR4b([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR4b_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp

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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"__AA", "__BA", "__BB", "__BA", "__BA", "__BA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 56, 56, 40, 40, 40}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 2)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 3)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 4)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 5)
End

static Function PS_CR5_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Symmetric")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR5([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR5_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD

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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BBBA", "BABA", "BABB", "BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 49, 49, 38, 38, 38}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 2)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 3)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 4)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 5)
End

// No a, b as this is the same as PS_CR4 for non-symmetric

static Function PS_CR6_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Symmetric")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR6([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR6_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD

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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BBAA", "BABA", "AABB", "BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 60, 60, 40, 40, 40}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 2)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 3)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 4)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 5)
End

// No a, b as this is the same as PS_CR4 for non-symmetric

static Function PS_CR7_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Symmetric")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR7([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR7_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp (not done)

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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {0, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"AAAA", "AAAA", "BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_RERUN, PSQ_CR_RERUN, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 2)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 3)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 4)
End

// No a, b as we can't have RERUN for non-symmetric

static Function PS_CR8_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Symmetric")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR8([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR8_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {0, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BBBB", "BBBB", "BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_RERUN, PSQ_CR_RERUN, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 2)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 3)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 4)
End

// No a, b as we can't have RERUN for non-symmetric

static Function PS_CR9_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Symmetric")
End

// Enough passing sweeps but not enough with the same DAScale
//
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR9([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR9_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp (not done)

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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 1, 0, 0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BABA", "BABA", "AABB", "BAAA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30, 17, 23, 23}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 2)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 3)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 4)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 5)
End

static Function PS_CR9a_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Depolarized")
End

// Enough passing sweeps but not enough with the same DAScale
//
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR9a([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR9a_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp (not done)

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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 1, 0, 0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BA__", "BA__", "AA__", "BB__", "BA__", "BA__"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30, 18, 32, 32}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 2)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 3)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 4)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 5)
End

static Function PS_CR9b_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Hyperpolarized")
End

// Enough passing sweeps but not enough with the same DAScale
//
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR9b([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR9b_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp (not done)

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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 1, 0, 0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"__BA", "__BA", "__BB", "__AA", "__BA", "__BA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30, 15, 28, 28}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 2)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 3)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 4)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 5)
End

static Function PS_CR10_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Symmetric")
End

// Early abort as not enough sweeps with the same DASCale value pass
//
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR10([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR10_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes
	wv[][][0] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD
	// layer 3: Spikes check during chirp (not done)

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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 0, 1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BABA", "AABB", "BABA", "BAAA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_PASS, PSQ_CR_INCREASE, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 17, 17, 23}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 2)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 3)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 4)
End

// No a, b as this is the same as PS_CR9 for non-symmetric

static Function PS_CR11_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "FailedLevel", var=10)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "DAScaleOperator", str="+")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "DAScaleModifier", var=1.2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Symmetric")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR11([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR11_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests fail
	// layer 0: BL
	// layer 1: Maximum of AD (0 triggers PSQ_CR_RERUN)
	// layer 2: Minimum of AD (0 triggers PSQ_CR_RERUN)
	// layer 3: Spikes check during chirp fails

	// first BL chunk passes, later ones fail. This is done so that
	// we reach the chirp region for performing spike checks.
	wv = 0
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
	CHECK_EQUAL_WAVES(lbnEntries[%spikePass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_WAVE(lbnEntries[%insideBounds], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsState], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsAction], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 31, 32}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {1}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520})
End

// No a, b as boundsState evaluation is always passing

static Function PS_CR12_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "FailedLevel", var=10)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "DAScaleOperator", str="+")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "DAScaleModifier", var=1.2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Symmetric")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR12([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR12_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests pass
	// layer 0: BL
	// layer 1: Maximum of AD (35 triggers PSQ_CR_PASS)
	// layer 2: Minimum of AD (-25 triggers PSQ_CR_PASS)
	// layer 3: Spikes check during chirp passes
	wv[][][0] = 1
	wv[][][1] = 35
	wv[][][2] = -25
	wv[][][3] = 1
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
	CHECK_EQUAL_WAVES(lbnEntries[%spikePass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"BABA", "BABA", "BABA"}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End

// No a, b as boundsState evaluation is always passing

static Function PS_CR13_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "FailedLevel", var=10)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "DAScaleOperator", str="+")
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "DAScaleModifier", var=1.2)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Symmetric")
End

// Early abort as not enough sweeps with the same DASCale value pass
//
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR13([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR13_IGNORE)

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
	wv[][4][3] = 0
End

static Function PS_CR13_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	sweepNo = 4

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 1, 1, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%baselinePass], {NaN, 1, 1, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%samplingPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikePass], {0, 1, 1, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%insideBounds], {NaN, 1, 1, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%boundsState], {"", "BABA", "BABA", "", ""}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%boundsAction], {NaN, PSQ_CR_PASS, PSQ_CR_PASS, NaN, NaN}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30, 31, 31, 31, 32}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 2)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 3)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 4)
End

// No a, b as boundsState evaluation is always passing

static Function PS_CR14_IGNORE(string device)

	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "InnerRelativeBound", var=20)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "OuterRelativeBound", var=40)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=1)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SpikeCheck", var=0)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "SamplingFrequency", var=10)
	AFH_AddAnalysisParameter("PatchSeqChirp_DA_0", "BoundsEvaluationMode", str="Symmetric")
End

// Same as PS_CR1 but with failing sampling interval check
//
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR14([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, preAcquireFunc = PS_CR14_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_CHIRP)
	// all tests fail
	// layer 0: BL
	// layer 1: Maximum of AD (0 triggers PSQ_CR_RERUN)
	// layer 2: Minimum of AD (0 triggers PSQ_CR_RERUN)
	// layer 3: Spikes check during chirp (not done)
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
	CHECK_WAVE(lbnEntries[%spikePass], NULL_WAVE)

	CHECK_WAVE(lbnEntries[%insideBounds], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsState], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%boundsAction], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%initialDAScale], {30e-12}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScale], {30}, mode = WAVE_DATA, tol = 1e-14)
	CHECK_EQUAL_WAVES(lbnEntries[%resistance], {1e9}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikeCheck], {0}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, lbnEntries[%setPass])
	CheckPSQChunkTimes(str, {20, 520})
End

// No a, b as boundsState evaluation is always passing
