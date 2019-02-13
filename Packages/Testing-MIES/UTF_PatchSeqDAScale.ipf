#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma ModuleName=PatchSeqTestDAScale

static Constant HEADSTAGE = 0

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(s, stimset, [postInitializeFunc, preAcquireFunc])
	STRUCT DAQSettings& s
	string stimset
	FUNCREF CALLABLE_PROTO postInitializeFunc, preAcquireFunc

	Initialize_IGNORE()

	if(!ParamIsDefault(postInitializeFunc))
		postInitializeFunc()
	endif

	string unlockedPanelTitle = DAP_CreateDAEphysPanel()

	ChooseCorrectDevice(unlockedPanelTitle, DEVICE)
	PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")

	REQUIRE(WindowExists(DEVICE))

	PGC_SetAndActivateControl(DEVICE, "ADC", val=0)
	DoUpdate/W=$DEVICE

	PGC_SetAndActivateControl(DEVICE, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(DEVICE, "setvar_DataAcq_AutoBiasV", val = 70)
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = stimset)

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

	PGC_SetAndActivateControl(DEVICE, "check_Settings_MD", val = s.MD)
	PGC_SetAndActivateControl(DEVICE, "Check_DataAcq1_RepeatAcq", val = s.RA)
	PGC_SetAndActivateControl(DEVICE, "Check_DataAcq_Indexing", val = s.IDX)
	PGC_SetAndActivateControl(DEVICE, "Check_DataAcq1_IndexingLocked", val = s.LIDX)
	PGC_SetAndActivateControl(DEVICE, "Check_Settings_BackgrndDataAcq", val = s.BKG_DAQ)
	PGC_SetAndActivateControl(DEVICE, "SetVar_DataAcq_SetRepeats", val = s.RES)
	PGC_SetAndActivateControl(DEVICE, "Check_Settings_SkipAnalysFuncs", val = 0)
	PGC_SetAndActivateControl(DEVICE, "Popup_Settings_SampIntMult", str = "4")

	DoUpdate/W=$DEVICE

	if(!ParamIsDefault(preAcquireFunc))
		preAcquireFunc()
	endif

	CtrlNamedBackGround DAQWatchdog, start, period=120, proc=WaitUntilDAQDone_IGNORE
	PGC_SetAndActivateControl(DEVICE, "DataAcquireButton")
	OpenDatabrowser()
End

Function/WAVE GetSweepResults_IGNORE(sweepNo)
	variable sweepNo

	WAVE numericalValues = GetLBNumericalValues(DEVICE)
	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)

	Make/FREE/N=(DimSize(sweeps, ROWS)) sweepPassed = GetLastSettingIndep(numericalValues, sweeps[p], PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SWEEP_PASS, query = 1), UNKNOWN_MODE)

	return sweepPassed
End

Function PS_DS_Sub_Run1()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0")

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_DA_SCALE)
	// all tests fail
	wv = 0
End

Function PS_DS_Sub_Test1()

	variable sweepNo, setPassed, numEntries

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 0, 0, 0})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = -30

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

Function PS_DS_Sub_Run2()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0")

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_DA_SCALE)
	// only pre pulse chunk pass, others fail
	wv[]    = 0
	wv[0][] = 1
End

Function PS_DS_Sub_Test2()

	variable sweepNo, setPassed, numEntries

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 0, 0, 0})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = -30

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

Function PS_DS_Sub_Run3()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0")

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// first post pulse chunk pass
	wv[]      = 0
	wv[0,1][] = 1
End

Function PS_DS_Sub_Test3()

	variable sweepNo, setPassed, numEntries

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 1, 1, 1})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -50, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

Function PS_DS_Sub_Run4()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0")

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// last post pulse chunk pass
	wv[] = 0
	wv[0][] = 1
	wv[DimSize(wv, ROWS) - 1][] = 1
End

Function PS_DS_Sub_Test4()

	variable sweepNo, setPassed, numEntries

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 1, 1, 1})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -50, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

Function PS_DS_Sub_Run5()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0")

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk fails
	// all post pulse chunk pass
	wv[]    = 1
	wv[0][] = 0
End

Function PS_DS_Sub_Test5()

	variable sweepNo, setPassed, numEntries

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 0, 0, 0})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = -30

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

Function PS_DS_Sub_Run6()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0")

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv[]    = 0
	wv[0][] = 1
	wv[2][] = 1
End

Function PS_DS_Sub_Test6()

	variable sweepNo, setPassed, numEntries

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 1, 1, 1})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -50, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

Function PS_DS_Sub_Run7()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0")

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// first post pulse chunk pass
	// of sweeps 2-6
	wv[]          = 0
	wv[0, 1][2,6] = 1
End

Function PS_DS_Sub_Test7()

	variable sweepNo, setPassed, numEntries

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 7)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 6)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 1, 1, 1, 1, 1})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 7)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -30, -30, -50, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

Function PS_DS_Sub_Run8()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0")

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_DA_SCALE)
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

Function PS_DS_Sub_Test8()

	variable sweepNo, setPassed, numEntries

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 9)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 8)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 0, 0, 1, 0, 0, 1, 1, 1})

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
Function PS_DS_Supra_Run1()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Supr_DA_0")

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv[]    = 0
	wv[0][] = 1
	wv[1][] = 1
End

Function PS_DS_Supra_Test1()

	variable sweepNo, setPassed, numEntries

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 2)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 1)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 2)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {PSQ_DS_OFFSETSCALE_FAKE + 20, PSQ_DS_OFFSETSCALE_FAKE + 40}
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End

Function PS_SetOffsetOp_IGNORE()
	WBP_AddAnalysisParameter("PSQ_DaScale_Supr_DA_0", "OffsetOperator", str="*")
End

Function PS_DS_Supra_Run2()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Supr_DA_0", postInitializeFunc = PS_SetOffsetOp_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(DEVICE, HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv[]    = 0
	wv[0][] = 1
	wv[1][] = 1
End

Function PS_DS_Supra_Test2()

	variable sweepNo, setPassed, numEntries

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 2)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 1)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1), UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1})

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 2)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {PSQ_DS_OFFSETSCALE_FAKE * 20, PSQ_DS_OFFSETSCALE_FAKE * 40}
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)
End
