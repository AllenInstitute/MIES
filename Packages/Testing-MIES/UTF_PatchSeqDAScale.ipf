#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma ModuleName=PatchSeqTestDAScale

static Constant HEADSTAGE = 0

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(s, stimset, device, [postInitializeFunc, preAcquireFunc])
	STRUCT DAQSettings& s
	string stimset
	string device
	FUNCREF CALLABLE_PROTO postInitializeFunc, preAcquireFunc

	if(!ParamIsDefault(postInitializeFunc))
		postInitializeFunc(device)
	endif
	string unlockedPanelTitle = DAP_CreateDAEphysPanel()

	ChooseCorrectDevice(unlockedPanelTitle, device)
	PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")

	REQUIRE(WindowExists(device))

	PGC_SetAndActivateControl(device, "ADC", val=0)
	DoUpdate/W=$device

	WAVE ampMCC = GetAmplifierMultiClamps()
	WAVE ampTel = GetAmplifierTelegraphServers()

	CHECK_EQUAL_VAR(DimSize(ampMCC, ROWS), 2)
	CHECK_EQUAL_VAR(DimSize(ampTel, ROWS), 2)

	// HS 0 with Amp
	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = HEADSTAGE)
	PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", val = 1)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, HEADSTAGE), val=1)
	DoUpdate/W=$device

	PGC_SetAndActivateControl(device, "button_Hardware_AutoGainAndUnit")

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = 70)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = stimset)

	PGC_SetAndActivateControl(device, "check_Settings_MD", val = s.MD)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = s.RA)
	PGC_SetAndActivateControl(device, "Check_DataAcq_Indexing", val = s.IDX)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_IndexingLocked", val = s.LIDX)
	PGC_SetAndActivateControl(device, "Check_Settings_BackgrndDataAcq", val = s.BKG_DAQ)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_SetRepeats", val = s.RES)
	PGC_SetAndActivateControl(device, "Check_Settings_SkipAnalysFuncs", val = 0)
	PGC_SetAndActivateControl(device, "Popup_Settings_SampIntMult", str = "4")

	DoUpdate/W=$device

	if(!ParamIsDefault(preAcquireFunc))
		preAcquireFunc(device)
	endif

	PGC_SetAndActivateControl(device, "DataAcquireButton")
	OpenDatabrowser()
End

Function/WAVE GetLBNEntries_IGNORE(device, sweepNo, name)
	string device
	variable sweepNo
	string name

	string key

	WAVE numericalValues = GetLBNumericalValues(DEVICE)
	key = PSQ_CreateLBNKey(PSQ_DA_SCALE, name, query = 1)

	strswitch(name)
		case PSQ_FMT_LBN_SWEEP_PASS:
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_BL_QC_PASS:
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, HEADSTAGE, UNKNOWN_MODE)
			break
		default:
			FAIL()
	endswitch
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_DA_SCALE)
	// all tests fail
	wv = 0
End

Function PS_DS_Sub1_REENTRY([str])
	string str

	variable sweepNo, setPassed, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(str)

	key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = -30

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub2([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_DA_SCALE)
	// only pre pulse chunk pass, others fail
	wv[]    = 0
	wv[0][] = 1
End

Function PS_DS_Sub2_REENTRY([str])
	string str

	variable sweepNo, setPassed, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(str)

	key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = -30

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub3([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// first post pulse chunk pass
	wv[]      = 0
	wv[0,1][] = 1
End

Function PS_DS_Sub3_REENTRY([str])
	string str

	variable sweepNo, setPassed, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(str)

	key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -50, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub4([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// last post pulse chunk pass
	wv[] = 0
	wv[0][] = 1
	wv[DimSize(wv, ROWS) - 1][] = 1
End

Function PS_DS_Sub4_REENTRY([str])
	string str

	variable sweepNo, setPassed, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(str)

	key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -50, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub5([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk fails
	// all post pulse chunk pass
	wv[]    = 1
	wv[0][] = 0
End

Function PS_DS_Sub5_REENTRY([str])
	string str

	variable sweepNo, setPassed, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(str)

	key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = -30

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub6([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv[]    = 0
	wv[0][] = 1
	wv[2][] = 1
End

Function PS_DS_Sub6_REENTRY([str])
	string str

	variable sweepNo, setPassed, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(str)

	key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -50, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub7([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// first post pulse chunk pass
	// of sweeps 2-6
	wv[]          = 0
	wv[0, 1][2,6] = 1
End

Function PS_DS_Sub7_REENTRY([str])
	string str

	variable sweepNo, setPassed, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 7)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 6)

	WAVE numericalValues = GetLBNumericalValues(str)

	key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 7)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -30, -30, -50, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub8([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// first post pulse chunk pass
	// of sweep 0, 3, 6, 7 , 8
	wv[]        = 0
	wv[0, 1][0] = 1
	wv[0, 1][3] = 1
	wv[0, 1][6] = 1
	wv[0, 1][7] = 1
	wv[0, 1][8] = 1
End

Function PS_DS_Sub8_REENTRY([str])
	string str

	variable sweepNo, setPassed, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 9)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 8)

	WAVE numericalValues = GetLBNumericalValues(str)

	key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 0, 0, 1, 0, 0, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 9)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -50, -50, -50, -70, -70, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

// We only have here one function to test the used DAScale values
// the decision logic is the same as for Sub
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Supra1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Supr_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv[]    = 0
	wv[0][] = 1
	wv[1][] = 1
End

Function PS_DS_Supra1_REENTRY([str])
	string str

	variable sweepNo, setPassed, numEntries
	string key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 2)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 1)

	WAVE numericalValues = GetLBNumericalValues(str)

	key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 2)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {PSQ_DS_OFFSETSCALE_FAKE + 20, PSQ_DS_OFFSETSCALE_FAKE + 40}
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

Function PS_SetOffsetOp_IGNORE(device)
	string device

	WBP_AddAnalysisParameter("PSQ_DaScale_Supr_DA_0", "OffsetOperator", str="*")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Supra2([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Supr_DA_0", str, postInitializeFunc = PS_SetOffsetOp_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv[]    = 0
	wv[0][] = 1
	wv[1][] = 1
End

Function PS_DS_Supra2_REENTRY([str])
	string str

	variable sweepNo, setPassed, numEntries

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 2)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 1)

	WAVE numericalValues = GetLBNumericalValues(str)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 2)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {PSQ_DS_OFFSETSCALE_FAKE * 20, PSQ_DS_OFFSETSCALE_FAKE * 40}
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End
