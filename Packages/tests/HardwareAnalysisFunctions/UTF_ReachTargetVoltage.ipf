#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=ReachTargetVoltageTesting

static Constant HEADSTAGE = 1

static Function [STRUCT DAQSettings s] PS_GetDAQSettings(string device)

	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_DB0"                                           + \
	                             "__HS" + num2str(HEADSTAGE) + "_DA1_AD1_CM:IC:_ST:StimulusSetA_DA_0:")

	return [s]
End

static Function GlobalPreAcq(string device)

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "ReachTargetVoltage")

	PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = HEADSTAGE)

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = -70)
End

static Function GlobalPreInit(string device)

	PASS()
End

static Function [WAVE/Z deltaI, WAVE/Z deltaV, WAVE/Z resistance, WAVE/Z resistanceErr, WAVE/Z autobiasFromDialog] GetLBNEntries_IGNORE(string device, variable sweepNo)

	WAVE numericalValues = GetLBNumericalValues(device)

	WAVE/Z deltaI             = GetLastSettingEachSCI(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + LBN_DELTA_I, HEADSTAGE, UNKNOWN_MODE)
	WAVE/Z deltaV             = GetLastSettingEachSCI(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + LBN_DELTA_V, HEADSTAGE, UNKNOWN_MODE)
	WAVE/Z resistance         = GetLastSettingEachSCI(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + LBN_RESISTANCE_FIT, HEADSTAGE, UNKNOWN_MODE)
	WAVE/Z resistanceErr      = GetLastSettingEachSCI(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + LBN_RESISTANCE_FIT_ERR, HEADSTAGE, UNKNOWN_MODE)
	WAVE/Z autobiasFromDialog = GetLastSettingEachSCI(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + LBN_AUTOBIAS_TARGET_DIAG, HEADSTAGE, UNKNOWN_MODE)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function RTV_Works([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)
End

static Function RTV_Works_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	[WAVE deltaI, WAVE deltaV, WAVE resistance, WAVE resistanceErr, WAVE autobiasFromDialog] = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_WAVE(deltaI, NUMERIC_WAVE)
	CHECK_WAVE(deltaV, NUMERIC_WAVE)
	CHECK_WAVE(resistance, NUMERIC_WAVE)
	CHECK_WAVE(resistanceErr, NUMERIC_WAVE)
	CHECK_WAVE(autobiasFromDialog, NULL_WAVE)
End

static Function RTV_WorksWithIndexing_preAcq(device)
	string device

	AFH_AddAnalysisParameter("StimulusSetA_DA_0", "EnableIndexing", var = 1)
	AFH_AddAnalysisParameter("StimulusSetA_DA_0", "IndexingEndStimsetAllIC", str = "StimulusSetB_DA_0")
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function RTV_WorksWithIndexing([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)
End

static Function RTV_WorksWithIndexing_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 4)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 3)

	[WAVE deltaI, WAVE deltaV, WAVE resistance, WAVE resistanceErr, WAVE autobiasFromDialog] = GetLBNEntries_IGNORE(str, 0)

	CHECK_WAVE(deltaI, NUMERIC_WAVE)
	CHECK_WAVE(deltaV, NUMERIC_WAVE)
	CHECK_WAVE(resistance, NUMERIC_WAVE)
	CHECK_WAVE(resistanceErr, NUMERIC_WAVE)
	CHECK_WAVE(autobiasFromDialog, NUMERIC_WAVE)

	CHECK_EQUAL_WAVES(autobiasFromDialog, {-69, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(GetSetVariable(str, "setvar_DataAcq_AutoBiasV"), -69)
End
