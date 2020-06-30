﻿#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma ModuleName=PatchSeqTestChirp

static Constant HEADSTAGE = 0

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(s, device, [postInitializeFunc, preAcquireFunc])
	STRUCT DAQSettings& s
	string device
	FUNCREF CALLABLE_PROTO postInitializeFunc, preAcquireFunc

	Make/O/N=(0) root:overrideResults/Wave=overrideResults
	Note/K overrideResults

	if(!ParamIsDefault(postInitializeFunc))
		postInitializeFunc(device)
	endif
	string unlockedPanelTitle = DAP_CreateDAEphysPanel()

	PGC_SetAndActivateControl(unlockedPanelTitle, "popup_MoreSettings_Devices", str=device)
	PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")

	REQUIRE(WindowExists(device))

	PGC_SetAndActivateControl(device, "ADC", val=0)
	DoUpdate/W=$device

	WAVE ampMCC = GetAmplifierMultiClamps()
	WAVE ampTel = GetAmplifierTelegraphServers()

	REQUIRE_EQUAL_VAR(DimSize(ampMCC, ROWS), 2)
	REQUIRE_EQUAL_VAR(DimSize(ampTel, ROWS), 2)

	// HS 0 with Amp
	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = HEADSTAGE)
	PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", val = 1)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, HEADSTAGE), val=1)
	DoUpdate/W=$device

	PGC_SetAndActivateControl(device, "button_Hardware_AutoGainAndUnit")

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = 70)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "PatchSeqChirp*")

	PGC_SetAndActivateControl(device, "check_Settings_MD", val = s.MD)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = s.RA)
	PGC_SetAndActivateControl(device, "Check_DataAcq_Indexing", val = s.IDX)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_IndexingLocked", val = s.LIDX)
	PGC_SetAndActivateControl(device, "Check_Settings_BackgrndDataAcq", val = s.BKG_DAQ)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_SetRepeats", val = s.RES)
	PGC_SetAndActivateControl(device, "Check_Settings_SkipAnalysFuncs", val = 0)

	DoUpdate/W=$device

	if(!ParamIsDefault(preAcquireFunc))
		preAcquireFunc(device)
	endif

	PGC_SetAndActivateControl(device, "DataAcquireButton")
	OpenDatabrowser()
End

static Function/WAVE GetLBNEntries_IGNORE(device, sweepNo, name)
	string device
	variable sweepNo
	string name

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues = GetLBTextualValues(device)

	strswitch(name)
		case PSQ_FMT_LBN_SWEEP_PASS:
		case PSQ_FMT_LBN_SET_PASS:
		case PSQ_FMT_LBN_CR_INSIDE_BOUNDS:
		case PSQ_FMT_LBN_CR_BOUNDS_ACTION:
		case PSQ_FMT_LBN_INITIAL_SCALE:
		case PSQ_FMT_LBN_CR_RESISTANCE:
			key = PSQ_CreateLBNKey(PSQ_CHIRP, name, query = 1)
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, HEADSTAGE, UNKNOWN_MODE)
			break
		case PSQ_FMT_LBN_CR_BOUNDS_STATE:
			key = PSQ_CreateLBNKey(PSQ_CHIRP, name, query = 1)
			return GetLastSettingTextIndepEachSCI(numericalValues, textualValues, sweepNo, HEADSTAGE, key, UNKNOWN_MODE)
			break
		case PSQ_FMT_LBN_BL_QC_PASS:
		case PSQ_FMT_LBN_PULSE_DUR:
			key = PSQ_CreateLBNKey(PSQ_CHIRP, name, query = 1)
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, HEADSTAGE, UNKNOWN_MODE)
			break
		case STIMSET_SCALE_FACTOR_KEY:
			return GetLastSettingEachSCI(numericalValues, sweepNo, name, HEADSTAGE, DATA_ACQUISITION_MODE)
			break
		default:
			FAIL()
	endswitch
End

static Function PS_CR1_IGNORE(string device)

	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "LowerRelativeBound", var=20)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "UpperRelativeBound", var=40)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=1)
End

// BBAA but with zero value which results in PSQ_CR_RERUN
//
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR1_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_CHIRP)
	// all tests fail
	// layer 0: BL
	// layer 1: Maximum of AD (0 triggers PSQ_CR_RERUN)
	// layer 2: Minimum of AD (0 triggers PSQ_CR_RERUN)
	wv = 0
End

static Function PS_CR1_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 0}, mode = WAVE_DATA)

	key = PSQ_CreateLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z insideBounds = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_INSIDE_BOUNDS)
	CHECK_WAVE(insideBounds, NULL_WAVE)

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z boundsState = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_STATE)
	CHECK_WAVE(boundsState, NULL_WAVE)

	WAVE/Z boundsAction = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_ACTION)
	CHECK_WAVE(boundsAction, NULL_WAVE)

	WAVE/Z initialDAScale = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_INITIAL_SCALE)
	CHECK_EQUAL_WAVES(initialDAScale, {30e-12, NaN, NaN}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z DAScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	CHECK_EQUAL_WAVES(DAScale, {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_RESISTANCE)
	CHECK_EQUAL_WAVES(resistance, {1e9, NaN, NaN}, mode = WAVE_DATA)
End

static Function PS_CR2_IGNORE(string device)

	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "LowerRelativeBound", var=20)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "UpperRelativeBound", var=40)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=1)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR2([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR2_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_CHIRP)
	// all tests pass
	// layer 0: BL
	// layer 1: Maximum of AD (35 triggers PSQ_CR_PASS)
	// layer 2: Minimum of AD (-25 triggers PSQ_CR_PASS)
	wv[][][0] = 1
	wv[][][1] = 35
	wv[][][2] = -25
End

static Function PS_CR2_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 1}, mode = WAVE_DATA)

	key = PSQ_CreateLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z insideBounds = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_INSIDE_BOUNDS)
	CHECK_EQUAL_WAVES(insideBounds, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {1, 1, 1}, mode = WAVE_DATA)

	WAVE/T/Z boundsState = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_STATE)
	CHECK_EQUAL_TEXTWAVES(boundsState, {"BABA", "BABA", "BABA"})

	WAVE/Z boundsAction = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_ACTION)
	CHECK_EQUAL_WAVES(boundsAction, {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	WAVE/Z initialDAScale = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_INITIAL_SCALE)
	CHECK_EQUAL_WAVES(initialDAScale, {30e-12, NaN, NaN}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z DAScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	CHECK_EQUAL_WAVES(DAScale, {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_RESISTANCE)
	CHECK_EQUAL_WAVES(resistance, {1e9, NaN, NaN}, mode = WAVE_DATA)
End

static Function PS_CR3_IGNORE(string device)

	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "LowerRelativeBound", var=20)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "UpperRelativeBound", var=40)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=1)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR3([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR3_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_CHIRP)
	// BL fails, rest passes
	// layer 0: BL
	// layer 1: Maximum of AD (35 would be PSQ_CR_PASS but we abort early due to baseline not passing)
	// layer 2: Minimum of AD (-25 would be PSQ_CR_PASS but we abort early due to baseline not passing)
	wv[][][0] = 0
	wv[][][1] = 35
	wv[][][2] = -25
End

static Function PS_CR3_REENTRY([str])
	string str

	variable sweepNo, setPassed
	string key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 0}, mode = WAVE_DATA)

	key = PSQ_CreateLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z insideBounds = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_INSIDE_BOUNDS)
	CHECK_WAVE(insideBounds, NULL_WAVE)

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z/T boundsState = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_STATE)
	CHECK_WAVE(boundsState, NULL_WAVE)

	WAVE/Z boundsAction = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_ACTION)
	CHECK_WAVE(boundsAction, NULL_WAVE)

	WAVE/Z initialDAScale = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_INITIAL_SCALE)
	CHECK_EQUAL_WAVES(initialDAScale, {30e-12, NaN, NaN}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z DAScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	CHECK_EQUAL_WAVES(DAScale, {30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_RESISTANCE)
	CHECK_EQUAL_WAVES(resistance, {1e9, NaN, NaN}, mode = WAVE_DATA)
End

static Function PS_CR4_IGNORE(string device)

	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "LowerRelativeBound", var=20)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "UpperRelativeBound", var=40)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR4([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR4_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes, Set passes
	wv[][][0] = 1

	// layer 0: BL
	// layer 1: Minimum of AD
	// layer 2: Maximum of AD

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

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 6)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 5)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues = GetLBTextualValues(str)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)

	key = PSQ_CreateLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z insideBounds = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_INSIDE_BOUNDS)
	CHECK_EQUAL_WAVES(insideBounds, {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {NaN, 1, NaN, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/T/Z boundsState = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_STATE)
	CHECK_EQUAL_TEXTWAVES(boundsState, {"BAAA", "BABA", "AABA", "BABA", "BABA", "BABA"}, mode = WAVE_DATA)

	WAVE/Z boundsAction = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_ACTION)
	CHECK_EQUAL_WAVES(boundsAction, {PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	WAVE/Z initialDAScale = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_INITIAL_SCALE)
	CHECK_EQUAL_WAVES(initialDAScale, {30e-12, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z DAScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	CHECK_EQUAL_WAVES(DAScale, {30, 57, 57, 79, 79, 79}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_RESISTANCE)
	CHECK_EQUAL_WAVES(resistance, {1e9, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

static Function PS_CR5_IGNORE(string device)

	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "LowerRelativeBound", var=20)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "UpperRelativeBound", var=40)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR5([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR5_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes, Set passes
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

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 6)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 5)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues = GetLBTextualValues(str)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)

	key = PSQ_CreateLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z insideBounds = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_INSIDE_BOUNDS)
	CHECK_EQUAL_WAVES(insideBounds, {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {NaN, 1, NaN, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/T/Z boundsState = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_STATE)
	CHECK_EQUAL_TEXTWAVES(boundsState, {"BBBA", "BABA", "BABB", "BABA", "BABA", "BABA"}, mode = WAVE_DATA)

	WAVE/Z boundsAction = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_ACTION)
	CHECK_EQUAL_WAVES(boundsAction, {PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	WAVE/Z initialDAScale = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_INITIAL_SCALE)
	CHECK_EQUAL_WAVES(initialDAScale, {30e-12, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z DAScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	CHECK_EQUAL_WAVES(DAScale, {30, 35, 35, 23, 23, 23}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_RESISTANCE)
	CHECK_EQUAL_WAVES(resistance, {1e9, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

static Function PS_CR6_IGNORE(string device)

	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "LowerRelativeBound", var=20)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "UpperRelativeBound", var=40)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR6([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR6_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes, Set passes
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

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 6)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 5)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues = GetLBTextualValues(str)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)

	key = PSQ_CreateLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z insideBounds = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_INSIDE_BOUNDS)
	CHECK_EQUAL_WAVES(insideBounds, {0, 1, 0, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {NaN, 1, NaN, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/T/Z boundsState = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_STATE)
	CHECK_EQUAL_TEXTWAVES(boundsState, {"BBAA", "BABA", "AABB", "BABA", "BABA", "BABA"}, mode = WAVE_DATA)

	WAVE/Z boundsAction = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_ACTION)
	CHECK_EQUAL_WAVES(boundsAction, {PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	WAVE/Z initialDAScale = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_INITIAL_SCALE)
	CHECK_EQUAL_WAVES(initialDAScale, {30e-12, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z DAScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	CHECK_EQUAL_WAVES(DAScale, {30, 58, 58, 38, 38, 38}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_RESISTANCE)
	CHECK_EQUAL_WAVES(resistance, {1e9, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

static Function PS_CR7_IGNORE(string device)

	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "LowerRelativeBound", var=20)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "UpperRelativeBound", var=40)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR7([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR7_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes, Set passes
	wv[][][0] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD

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

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues = GetLBTextualValues(str)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 1, 1, 1}, mode = WAVE_DATA)

	key = PSQ_CreateLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z insideBounds = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_INSIDE_BOUNDS)
	CHECK_EQUAL_WAVES(insideBounds, {0, 0, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {NaN, NaN, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/T/Z boundsState = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_STATE)
	CHECK_EQUAL_TEXTWAVES(boundsState, {"AAAA", "AAAA", "BABA", "BABA", "BABA"}, mode = WAVE_DATA)

	WAVE/Z boundsAction = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_ACTION)
	CHECK_EQUAL_WAVES(boundsAction, {PSQ_CR_RERUN, PSQ_CR_RERUN, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	WAVE/Z initialDAScale = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_INITIAL_SCALE)
	CHECK_EQUAL_WAVES(initialDAScale, {30e-12, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z DAScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	CHECK_EQUAL_WAVES(DAScale, {30, 30, 30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_RESISTANCE)
	CHECK_EQUAL_WAVES(resistance, {1e9, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

static Function PS_CR8_IGNORE(string device)

	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "LowerRelativeBound", var=20)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "UpperRelativeBound", var=40)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR8([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR8_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes, Set passes
	wv[][][0] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD

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

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues = GetLBTextualValues(str)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 1, 1, 1}, mode = WAVE_DATA)

	key = PSQ_CreateLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z insideBounds = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_INSIDE_BOUNDS)
	CHECK_EQUAL_WAVES(insideBounds, {0, 0, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {NaN, NaN, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/T/Z boundsState = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_STATE)
	CHECK_EQUAL_TEXTWAVES(boundsState, {"BBBB", "BBBB", "BABA", "BABA", "BABA"}, mode = WAVE_DATA)

	WAVE/Z boundsAction = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_ACTION)
	CHECK_EQUAL_WAVES(boundsAction, {PSQ_CR_RERUN, PSQ_CR_RERUN, PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	WAVE/Z initialDAScale = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_INITIAL_SCALE)
	CHECK_EQUAL_WAVES(initialDAScale, {30e-12, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z DAScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	CHECK_EQUAL_WAVES(DAScale, {30, 30, 30, 30, 30}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_RESISTANCE)
	CHECK_EQUAL_WAVES(resistance, {1e9, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

static Function PS_CR9_IGNORE(string device)

	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "LowerRelativeBound", var=20)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "UpperRelativeBound", var=40)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
End

// Enough passing sweeps but not enough with the same DAScale
//
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR9([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR9_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes, Set passes
	wv[][][0] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD

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

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 6)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 5)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues = GetLBTextualValues(str)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 0, 0, 1, 1}, mode = WAVE_DATA)

	key = PSQ_CreateLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z insideBounds = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_INSIDE_BOUNDS)
	CHECK_EQUAL_WAVES(insideBounds, {1, 1, 0, 0, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {1, 1, NaN, NaN, 1, 1}, mode = WAVE_DATA)

	WAVE/T/Z boundsState = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_STATE)
	CHECK_EQUAL_TEXTWAVES(boundsState, {"BABA", "BABA", "AABB", "BAAA", "BABA", "BABA"}, mode = WAVE_DATA)

	WAVE/Z boundsAction = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_ACTION)
	CHECK_EQUAL_WAVES(boundsAction, {PSQ_CR_PASS, PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_INCREASE, PSQ_CR_PASS, PSQ_CR_PASS}, mode = WAVE_DATA)

	WAVE/Z initialDAScale = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_INITIAL_SCALE)
	CHECK_EQUAL_WAVES(initialDAScale, {30e-12, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z DAScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	CHECK_EQUAL_WAVES(DAScale, {30, 30, 30, 15, 28, 28}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_RESISTANCE)
	CHECK_EQUAL_WAVES(resistance, {1e9, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

static Function PS_CR10_IGNORE(string device)

	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "LowerRelativeBound", var=20)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "UpperRelativeBound", var=40)
	WBP_AddAnalysisParameter("PatchSeqChirp_DA_0", "NumberOfChirpCycles", var=2)
End

// Early abort as not enough sweeps with the same DASCale value pass
//
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_CR10([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = PS_CR10_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_CHIRP)
	wv = 0

	// BL passes, Set passes
	wv[][][0] = 1

	// layer 0: BL
	// layer 1: Maximum of AD
	// layer 2: Minimum of AD

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

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues = GetLBTextualValues(str)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 0, 1, 0, 1}, mode = WAVE_DATA)

	key = PSQ_CreateLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z insideBounds = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_INSIDE_BOUNDS)
	CHECK_EQUAL_WAVES(insideBounds, {1, 0, 1, 0, 1}, mode = WAVE_DATA)

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {1, NaN, 1, NaN, 1}, mode = WAVE_DATA)

	WAVE/T/Z boundsState = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_STATE)
	CHECK_EQUAL_TEXTWAVES(boundsState, {"BABA", "AABB", "BABA", "BAAA", "BABA"}, mode = WAVE_DATA)

	WAVE/Z boundsAction = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_BOUNDS_ACTION)
	CHECK_EQUAL_WAVES(boundsAction, {PSQ_CR_PASS, PSQ_CR_DECREASE, PSQ_CR_PASS, PSQ_CR_INCREASE, PSQ_CR_PASS}, mode = WAVE_DATA)

	WAVE/Z initialDAScale = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_INITIAL_SCALE)
	CHECK_EQUAL_WAVES(initialDAScale, {30e-12, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z DAScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	CHECK_EQUAL_WAVES(DAScale, {30, 30, 15, 15, 28}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CR_RESISTANCE)
	CHECK_EQUAL_WAVES(resistance, {1e9, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End
