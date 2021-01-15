#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=MultiPatchSeqDAScale

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(s, device, [postInitializeFunc, preAcquireFunc])
	STRUCT DAQSettings& s
	string device
	FUNCREF CALLABLE_PROTO postInitializeFunc, preAcquireFunc

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
	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = 0)
	PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", val = 1)
	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 0), val=1)

	DoUpdate/W=$device

	PGC_SetAndActivateControl(device, "button_Hardware_AutoGainAndUnit")

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = 70)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str ="MSQ_DAScale_DA_0")

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

	MSQ_CreateOverrideResults(device, 0, MSQ_DA_SCALE)

	PGC_SetAndActivateControl(device, "DataAcquireButton")
	OpenDatabrowser()
End

static Constant INDEP_EACH_SCI = 0x01
static Constant EACH_SCI       = 0x02
static Constant INDEP          = 0x04
static Constant SINGLE_SCI     = 0x08

static Function/WAVE GetResults_IGNORE(sweepNo, device, str, headstage, mode)
	variable sweepNo
	string device
	variable headstage, mode
	string str

	string key

	WAVE numericalValues = GetLBNumericalValues(device)

	if(!cmpstr(str, STIMSET_SCALE_FACTOR_KEY))
		key = STIMSET_SCALE_FACTOR_KEY
	else
		key = CreateAnaFuncLBNKey(MSQ_DA_SCALE, str, query = 1)
	endif

	switch(mode)
		case INDEP_EACH_SCI:
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
		case EACH_SCI:
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
		case INDEP:
			CHECK_EQUAL_VAR(numtype(headstage), 2)
			Make/D/N=1/FREE val = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
			return val
		case SINGLE_SCI:
			return GetLastSettingSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	endswitch
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function MSQ_DS1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str)
End

static Function MSQ_DS1_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE/Z headstageActive = GetResults_IGNORE(sweepNo, str, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(headstageActive, {1, 0, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z setPass = GetResults_IGNORE(sweepNo, str, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, str, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, str, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetResults_IGNORE(sweepNo, str, STIMSET_SCALE_FACTOR_KEY, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(stimScale, {33, 43, 53, 63, 73}, mode = WAVE_DATA)
End
