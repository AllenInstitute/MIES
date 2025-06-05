#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = AutoTP

static Function [STRUCT DAQSettings s] AutoTP_GetDAQSettings(string device)

	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_DB0_TP1" + \
	                             "__HS0_DA0_AD0_CM:IC:"       + \
	                             "__HS1_DA1_AD1_CM:IC:")

	return [s]
End

static Function GlobalPreAcq(string device)

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = 70)
End

static Function GlobalPreInit(string device)

	PASS()
End

static Function/WAVE GetEntriesWave_IGNORE()

	string list = "amplitudePass_HS0;amplitudePass_HS1;"                   \
	              + "baselinePass_HS0;baselinePass_HS1;"                   \
	              + "baselineRangeExceeded_HS0;baselineRangeExceeded_HS1;" \
	              + "baselineFitResult_HS0;baselineFitResult_HS1;"         \
	              + "autoTPEnable;amplitudeIC;baselineFrac;autoTPQC"

	Make/FREE/WAVE/N=(ItemsInList(list)) wv
	SetDimensionLabels(wv, list, ROWS)

	return wv
End

static Function/WAVE GetLBNSingleEntry_IGNORE(string device)

	WAVE TPStorage       = GetTPstorage(device)
	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	WAVE/WAVE wv = GetEntriesWave_IGNORE()

	wv[%amplitudePass_HS0] = TP_GetValuesFromTPStorage(TPStorage, 0, "AutoTPAmplitude", Inf)
	wv[%amplitudePass_HS1] = TP_GetValuesFromTPStorage(TPStorage, 1, "AutoTPAmplitude", Inf)

	wv[%baselinePass_HS0] = TP_GetValuesFromTPStorage(TPStorage, 0, "AutoTPBaseline", Inf)
	wv[%baselinePass_HS1] = TP_GetValuesFromTPStorage(TPStorage, 1, "AutoTPBaseline", Inf)

	wv[%baselineRangeExceeded_HS0] = TP_GetValuesFromTPStorage(TPStorage, 0, "AutoTPBaselineRangeExceeded", Inf)
	wv[%baselineRangeExceeded_HS1] = TP_GetValuesFromTPStorage(TPStorage, 1, "AutoTPBaselineRangeExceeded", Inf)

	wv[%baselineFitResult_HS0] = TP_GetValuesFromTPStorage(TPStorage, 0, "AutoTPBaselineFitResult", Inf)
	wv[%baselineFitResult_HS1] = TP_GetValuesFromTPStorage(TPStorage, 1, "AutoTPBaselineFitResult", Inf)

	wv[%autoTPEnable] = GetLastSetting(numericalValues, NaN, "TP Auto", TEST_PULSE_MODE)
	wv[%autoTPQC]     = GetLastSetting(numericalValues, NaN, "TP Auto QC", TEST_PULSE_MODE)
	wv[%amplitudeIC]  = GetLastSetting(numericalValues, NaN, TP_AMPLITUDE_IC_ENTRY_KEY, TEST_PULSE_MODE)
	wv[%baselineFrac] = GetLastSetting(numericalValues, NaN, "TP Baseline Fraction", TEST_PULSE_MODE)

	return wv
End

static Function AutoTP_OptimumValues_preAcq(string device)

	WAVE overrideResults = MIES_TP#TP_CreateOverrideResults(device, TP_OVERRIDE_RESULTS_AUTO_TP)

	// 2 HS in IC mode
	// both have the ideal values
	overrideResults[][0, 1][%Factor]            = TP_BASELINE_RATIO_OPT
	overrideResults[][0, 1][%Voltage]           = 0.015 // V
	overrideResults[][0, 1][%BaselineFitResult] = TP_BASELINE_FIT_RESULT_OK

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoTP", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_targetVoltage", val = 15)
	// same sign as target voltage
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val = 50)
	PGC_SetAndActivateControl(device, "Check_TP_SendToAllHS", val = 0)

	CtrlNamedBackGround StopTP, start, period=1, proc=StopTPWhenFinished
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AutoTP_OptimumValues([string str])

	[STRUCT DAQSettings s] = AutoTP_GetDAQSettings(str)
	AcquireData_NG(s, str)
End

static Function AutoTP_OptimumValues_REENTRY([string str])

	WAVE TPStorage = GetTPstorage(str)

	WAVE/WAVE entries = GetLBNSingleEntry_IGNORE(str)

	CHECK(IsConstant(entries[%amplitudePass_HS0], 1))
	CHECK(IsConstant(entries[%amplitudePass_HS1], 1))

	CHECK(IsConstant(entries[%baselinePass_HS0], 1))
	CHECK(IsConstant(entries[%baselinePass_HS1], 1))

	CHECK_EQUAL_WAVES(entries[%autoTPQC], {1, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	CHECK(IsConstant(entries[%baselineRangeExceeded_HS0], 0))
	CHECK(IsConstant(entries[%baselineRangeExceeded_HS1], 0))

	CHECK(IsConstant(entries[%baselineFitResult_HS0], TP_BASELINE_FIT_RESULT_OK))
	CHECK(IsConstant(entries[%baselineFitResult_HS1], TP_BASELINE_FIT_RESULT_OK))

	CHECK_EQUAL_WAVES(entries[%autoTPEnable], {0, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%amplitudeIC], {50, 50, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineFrac], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0.35}, mode = WAVE_DATA, tol = 1e-6)
End

static Function AutoTP_BadValues_preAcq(string device)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 0), val = 1)
	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val = 1)

	WAVE overrideResults = MIES_TP#TP_CreateOverrideResults(device, TP_OVERRIDE_RESULTS_AUTO_TP)

	// 2 HS in IC mode
	// both have very bad values, the fit is good
	overrideResults[][0, 1][%Factor]            = TP_BASELINE_RATIO_LOW / 4
	overrideResults[][0, 1][%Voltage]           = 0.020 // V
	overrideResults[][0, 1][%BaselineFitResult] = TP_BASELINE_FIT_RESULT_OK

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoTP", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_targetVoltage", val = 15)
	// same sign as target voltage
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val = 50)
	PGC_SetAndActivateControl(device, "Check_TP_SendToAllHS", val = 0)

	CtrlNamedBackGround StopTP, start, period=30, proc=StopTPWhenFinished
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AutoTP_BadValues([string str])

	[STRUCT DAQSettings s] = AutoTP_GetDAQSettings(str)
	AcquireData_NG(s, str)
End

static Function AutoTP_BadValues_REENTRY([string str])

	WAVE TPStorage = GetTPstorage(str)

	WAVE/WAVE entries = GetLBNSingleEntry_IGNORE(str)

	CHECK_WAVE(entries[%amplitudePass_HS0], NULL_WAVE)
	CHECK_WAVE(entries[%amplitudePass_HS1], NULL_WAVE)

	CHECK(IsConstant(entries[%baselinePass_HS0], 0))
	CHECK(IsConstant(entries[%baselinePass_HS1], 0))

	CHECK_EQUAL_WAVES(entries[%autoTPQC], {0, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	CHECK(IsConstant(entries[%baselineRangeExceeded_HS0], 1))
	CHECK(IsConstant(entries[%baselineRangeExceeded_HS1], 1))

	CHECK(IsConstant(entries[%baselineFitResult_HS0], TP_BASELINE_FIT_RESULT_OK))
	CHECK(IsConstant(entries[%baselineFitResult_HS1], TP_BASELINE_FIT_RESULT_OK))

	CHECK_EQUAL_WAVES(entries[%autoTPEnable], {0, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%amplitudeIC], {50, 50, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

static Function AutoTP_MixedOptimumBadValues_preAcq(string device)

	WAVE overrideResults = MIES_TP#TP_CreateOverrideResults(device, TP_OVERRIDE_RESULTS_AUTO_TP)

	// 2 HS in IC mode

	// HS0: ideal values
	overrideResults[][0][%Factor]            = TP_BASELINE_RATIO_OPT
	overrideResults[][0][%Voltage]           = 0.015 // V
	overrideResults[][0][%BaselineFitResult] = TP_BASELINE_FIT_RESULT_OK

	// HS1: bad values
	overrideResults[][1][%Factor]            = TP_BASELINE_RATIO_LOW / 4
	overrideResults[][1][%Voltage]           = 0.020 // V
	overrideResults[][1][%BaselineFitResult] = TP_BASELINE_FIT_RESULT_OK

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoTP", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_targetVoltage", val = 15)
	// same sign as target voltage
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val = 50)
	PGC_SetAndActivateControl(device, "Check_TP_SendToAllHS", val = 0)

	CtrlNamedBackGround StopTP, start, period=1, proc=StopTPWhenFinished
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AutoTP_MixedOptimumBadValues([string str])

	[STRUCT DAQSettings s] = AutoTP_GetDAQSettings(str)
	AcquireData_NG(s, str)
End

static Function AutoTP_MixedOptimumBadValues_REENTRY([string str])

	WAVE TPStorage = GetTPstorage(str)

	WAVE/WAVE entries = GetLBNSingleEntry_IGNORE(str)

	CHECK(IsConstant(entries[%amplitudePass_HS0], 1))
	CHECK_WAVE(entries[%amplitudePass_HS1], NULL_WAVE)

	CHECK(IsConstant(entries[%baselinePass_HS0], 1))
	CHECK(IsConstant(entries[%baselinePass_HS1], 0))

	CHECK_EQUAL_WAVES(entries[%autoTPQC], {1, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	CHECK(IsConstant(entries[%baselineRangeExceeded_HS0], 0))
	CHECK(IsConstant(entries[%baselineRangeExceeded_HS1], 1))

	CHECK(IsConstant(entries[%baselineFitResult_HS0], TP_BASELINE_FIT_RESULT_OK))
	CHECK(IsConstant(entries[%baselineFitResult_HS1], TP_BASELINE_FIT_RESULT_OK))

	CHECK_EQUAL_WAVES(entries[%autoTPEnable], {0, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%amplitudeIC], {50, 50, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineFrac], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0.25}, mode = WAVE_DATA)
End

static Function AutoTP_SpecialCases_preAcq(string device)

	WAVE overrideResults = MIES_TP#TP_CreateOverrideResults(device, TP_OVERRIDE_RESULTS_AUTO_TP)

	// 2 HS in IC mode
	overrideResults[][0, 1][%Factor]  = TP_BASELINE_RATIO_OPT
	overrideResults[][0, 1][%Voltage] = 0.050 // V

	overrideResults[][0, 1][%BaselineFitResult] = TP_BASELINE_FIT_RESULT_OK

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoTP", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_targetVoltage", val = 50)
	PGC_SetAndActivateControl(device, "Check_TP_SendToAllHS", val = 0)

	// HS0: different sign
	PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = 0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val = -15)

	// HS1: too small
	PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = 1)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val = 1)

	CtrlNamedBackGround StopTP, start, period=1, proc=StopTPWhenFinished
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AutoTP_SpecialCases([string str])

	[STRUCT DAQSettings s] = AutoTP_GetDAQSettings(str)
	AcquireData_NG(s, str)
End

static Function AutoTP_SpecialCases_REENTRY([string str])

	WAVE TPStorage = GetTPstorage(str)

	WAVE/WAVE entries = GetLBNSingleEntry_IGNORE(str)

	Duplicate/FREE entries[%amplitudePass_HS0], ampPassRef_HS0
	ampPassRef_HS0[]  = 1
	ampPassRef_HS0[0] = 0

	Duplicate/FREE entries[%amplitudePass_HS1], ampPassRef_HS1
	ampPassRef_HS1[]  = 1
	ampPassRef_HS1[0] = 0

	CHECK_EQUAL_WAVES(entries[%amplitudePass_HS0], ampPassRef_HS0)
	CHECK_EQUAL_WAVES(entries[%amplitudePass_HS1], ampPassRef_HS1)

	CHECK(IsConstant(entries[%baselinePass_HS0], 1))
	CHECK(IsConstant(entries[%baselinePass_HS1], 1))

	CHECK_EQUAL_WAVES(entries[%autoTPQC], {1, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	CHECK(IsConstant(entries[%baselineRangeExceeded_HS0], 0))
	CHECK(IsConstant(entries[%baselineRangeExceeded_HS1], 0))

	CHECK(IsConstant(entries[%baselineFitResult_HS0], TP_BASELINE_FIT_RESULT_OK))
	CHECK(IsConstant(entries[%baselineFitResult_HS1], TP_BASELINE_FIT_RESULT_OK))

	CHECK_EQUAL_WAVES(entries[%autoTPEnable], {0, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	WAVE amplitudeIC = entries[%amplitudeIC]

	CHECK_EQUAL_VAR(amplitudeIC[0], 15)
	// determined by RNG
	CHECK_GE_VAR(amplitudeIC[1], 5)
	CHECK_LE_VAR(amplitudeIC[1], 10)

	CHECK_EQUAL_WAVES(entries[%baselineFrac], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0.35}, mode = WAVE_DATA, tol = 1e-6)
End
