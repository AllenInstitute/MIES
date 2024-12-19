#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=MultiPatchSeqDAScale

static Constant INDEP_EACH_SCI = 0x01
static Constant EACH_SCI       = 0x02
static Constant INDEP          = 0x04
static Constant SINGLE_SCI     = 0x08

static Function [STRUCT DAQSettings s] MSQ_GetDAQSettings(string device)

	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_DB1"                 + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:MSQ_DAScale_DA_0:")

	return [s]
End

static Function GlobalPreAcq(string device)

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = 70)

	MSQ_CreateOverrideResults(device, 0, MSQ_DA_SCALE)
End

static Function GlobalPreInit(string device)

	PASS()
End

static Function/WAVE GetLBNSingleEntry_IGNORE(variable sweepNo, string device, string str, variable headstage, variable mode)

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

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function MSQ_DS1([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)
End

static Function MSQ_DS1_REENTRY([string str])

	variable sweepNo

	sweepNo = 4

	WAVE/Z headstageActive = GetLBNSingleEntry_IGNORE(sweepNo, str, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(headstageActive, {1, 0, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z setPass = GetLBNSingleEntry_IGNORE(sweepNo, str, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(sweepNo, str, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(sweepNo, str, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLBNSingleEntry_IGNORE(sweepNo, str, STIMSET_SCALE_FACTOR_KEY, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(stimScale, {33, 43, 53, 63, 73}, mode = WAVE_DATA)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(sweepNo, str, MSQ_FMT_LBN_DASCALE_OOR, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, setPass)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function MSQ_DS2([string str])

	AFH_AddAnalysisParameter("MSQ_DAScale_DA_0", "DAScales", wv = {1000, 1500, 2000, 3000, 5000})

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)
End

static Function MSQ_DS2_REENTRY([string str])

	variable sweepNo

	sweepNo = 3

	WAVE/Z headstageActive = GetLBNSingleEntry_IGNORE(sweepNo, str, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(headstageActive, {1, 0, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z setPass = GetLBNSingleEntry_IGNORE(sweepNo, str, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(sweepNo, str, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {1, 1, 1, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(sweepNo, str, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {1, 1, 1, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLBNSingleEntry_IGNORE(sweepNo, str, STIMSET_SCALE_FACTOR_KEY, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(stimScale, {1023, 1523, 2023, 3023}, mode = WAVE_DATA, tol = 1e-12)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(sweepNo, str, MSQ_FMT_LBN_DASCALE_OOR, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 1}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, setPass)
End
