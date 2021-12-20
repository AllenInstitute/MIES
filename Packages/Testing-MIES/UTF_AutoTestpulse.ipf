#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=AutoTP

/// @brief Acquire testpulses with the given DAQSettings
static Function AcquireTestpulse(s, device, [postInitializeFunc, preAcquireFunc])
	STRUCT DAQSettings& s
	string device
	FUNCREF CALLABLE_PROTO postInitializeFunc, preAcquireFunc

	if(!ParamIsDefault(postInitializeFunc))
		postInitializeFunc(device)
	endif

	string unlockedDevice = DAP_CreateDAEphysPanel()

	PGC_SetAndActivateControl(unlockedDevice, "popup_MoreSettings_Devices", str=device)
	PGC_SetAndActivateControl(unlockedDevice, "button_SettingsPlus_LockDevice")

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

	PGC_SetAndActivateControl(device, "TestpulseButton")
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

static Function/WAVE GetResults_IGNORE(string device)

	WAVE TPStorage = GetTPstorage(device)
	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	WAVE/WAVE wv = GetEntriesWave_IGNORE()

	wv[%amplitudePass_HS0] = TP_GetValuesFromTPStorage(TPStorage, 0, "AutoTPAmplitude", inf)
	wv[%amplitudePass_HS1] = TP_GetValuesFromTPStorage(TPStorage, 1, "AutoTPAmplitude", inf)

	wv[%baselinePass_HS0] = TP_GetValuesFromTPStorage(TPStorage, 0, "AutoTPBaseline", inf)
	wv[%baselinePass_HS1] = TP_GetValuesFromTPStorage(TPStorage, 1, "AutoTPBaseline", inf)

	wv[%baselineRangeExceeded_HS0] = TP_GetValuesFromTPStorage(TPStorage, 0, "AutoTPBaselineRangeExceeded", inf)
	wv[%baselineRangeExceeded_HS1] = TP_GetValuesFromTPStorage(TPStorage, 1, "AutoTPBaselineRangeExceeded", inf)

	wv[%baselineFitResult_HS0] = TP_GetValuesFromTPStorage(TPStorage, 0, "AutoTPBaselineFitResult", inf)
	wv[%baselineFitResult_HS1] = TP_GetValuesFromTPStorage(TPStorage, 1, "AutoTPBaselineFitResult", inf)

	wv[%autoTPEnable]  = GetLastSetting(numericalValues, NaN, "TP Auto", TEST_PULSE_MODE)
	wv[%autoTPQC]      = GetLastSetting(numericalValues, NaN, "TP Auto QC", TEST_PULSE_MODE)
	wv[%amplitudeIC]   = GetLastSetting(numericalValues, NaN, TP_AMPLITUDE_IC_ENTRY_KEY, TEST_PULSE_MODE)
	wv[%baselineFrac]  = GetLastSetting(numericalValues, NaN, "TP Baseline Fraction", TEST_PULSE_MODE)

	return wv
End

static Function AutoTP_OptimumValues_IGNORE(string device)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 0), val=1)
	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val=1)

	WAVE overrideResults = MIES_TP#TP_CreateOverrideResults(device, TP_OVERRIDE_RESULTS_AUTO_TP)

	// 2 HS in IC mode
	// both have the ideal values
	overrideResults[][0, 1][%Factor]  = TP_BASELINE_RATIO_OPT
	overrideResults[][0, 1][%Voltage] = 0.015 // V
	overrideResults[][0, 1][%BaselineFitResult] = TP_BASELINE_FIT_RESULT_OK

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoTP", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_targetVoltage", val = 15)
	// same sign as target voltage
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val = 50)
	PGC_SetAndActivateControl(device, "Check_TP_SendToAllHS", val = 0)

	CtrlNamedBackGround StopTP, start, period=1, proc=StopTPWhenFinished
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function AutoTP_OptimumValues([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	BasicHardwareTests#AcquireData(s, str, startTPInstead = 1, preAcquireFunc = AutoTP_OptimumValues_IGNORE)
End

static Function AutoTP_OptimumValues_REENTRY([string str])

	WAVE TPStorage = GetTPstorage(str)

	WAVE/WAVE entries = GetResults_IGNORE(str)

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

static Function AutoTP_BadValues_IGNORE(string device)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 0), val=1)
	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val=1)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function AutoTP_BadValues([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	BasicHardwareTests#AcquireData(s, str, startTPInstead = 1, preAcquireFunc = AutoTP_BadValues_IGNORE)
End

static Function AutoTP_BadValues_REENTRY([string str])

	WAVE TPStorage = GetTPstorage(str)

	WAVE/WAVE entries = GetResults_IGNORE(str)

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

static Function AutoTP_MixedOptimumBadValues_IGNORE(string device)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 0), val=1)
	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val=1)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function AutoTP_MixedOptimumBadValues([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	BasicHardwareTests#AcquireData(s, str, startTPInstead = 1, preAcquireFunc = AutoTP_MixedOptimumBadValues_IGNORE)
End

static Function AutoTP_MixedOptimumBadValues_REENTRY([string str])

	WAVE TPStorage = GetTPstorage(str)

	WAVE/WAVE entries = GetResults_IGNORE(str)

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

static Function AutoTP_SpecialCases_IGNORE(string device)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 0), val=1)
	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val=1)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function AutoTP_SpecialCases([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	BasicHardwareTests#AcquireData(s, str, startTPInstead = 1, preAcquireFunc = AutoTP_SpecialCases_IGNORE)
End

static Function AutoTP_SpecialCases_REENTRY([string str])
	WAVE TPStorage = GetTPstorage(str)

	WAVE/WAVE entries = GetResults_IGNORE(str)

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
