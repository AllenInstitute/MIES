#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=TestPulseAndTPDuringDAQ

static Function GlobalPreInit(string device)
	PASS()
End

static Function GlobalPreAcq(string device)
	PASS()
End

/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckCalculatedTPEntries([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_SIM2_TBP25"              + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function CheckCalculatedTPEntries_REENTRY([string str])
	variable samplingInterval, samplingIntervalMult, sweepNo, delayOnsetAuto

	WAVE numericalValues = GetLBNumericalValues(str)

	sweepNo              = 0
	samplingInterval     = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval AD", DATA_ACQUISITION_MODE)
	samplingIntervalMult = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval Multiplier", DATA_ACQUISITION_MODE)

	CHECK_EQUAL_VAR(samplingIntervalMult, 2)

	WAVE calculated = GetTPSettingsCalculated(str)

	CHECK_EQUAL_VAR(calculated[%baselineFrac], 0.25)

	CHECK_EQUAL_VAR(calculated[%pulseLengthMS], 10)
	CHECK_EQUAL_VAR(calculated[%totalLengthMS], 20)

#if defined(TESTS_WITH_ITC18USB_HARDWARE)
	CHECK_EQUAL_VAR(samplingInterval, 0.02)

	// sampling interval multiplier is ignored for TP
	CHECK_EQUAL_VAR(calculated[%pulseLengthPointsTP], 10 / 0.01)
	CHECK_EQUAL_VAR(calculated[%totalLengthPointsTP], 20 / 0.01)

	CHECK_EQUAL_VAR(calculated[%pulseLengthPointsDAQ], 10 / 0.02)
	CHECK_EQUAL_VAR(calculated[%totalLengthPointsDAQ], 20 / 0.02)
#elif defined(TESTS_WITH_NI_HARDWARE)
	CHECK_EQUAL_VAR(samplingInterval, 0.008)

	// sampling interval multiplier is ignored for TP
	CHECK_EQUAL_VAR(calculated[%pulseLengthPointsTP], 10 / 0.004)
	CHECK_EQUAL_VAR(calculated[%totalLengthPointsTP], 20 / 0.004)

	CHECK_EQUAL_VAR(calculated[%pulseLengthPointsDAQ], 10 / 0.008)
	CHECK_EQUAL_VAR(calculated[%totalLengthPointsDAQ], 20 / 0.008)
#endif

	delayOnsetAuto = GetLastSettingIndep(numericalValues, sweepNo, "Delay onset auto", DATA_ACQUISITION_MODE, defValue = NaN)
	CHECK_EQUAL_VAR(delayOnsetAuto, 20)
	CHECK_EQUAL_VAR(MIES_TP#TP_CalculateTestPulseLength(10, 0.25), 20)
End

Function CheckTPBaseline_PreAcq(string device)

	CtrlNamedBackGround StopTP, start=(ticks + 100), period=1, proc=StopTPWhenWeHaveOne
End

/// UTF_TD_GENERATOR v0:GenerateBaselineValues
/// UTF_TD_GENERATOR s0:DeviceNameGeneratorMD1
static Function CheckTPBaseline([STRUCT IUTF_MDATA &md])
	string   device
	variable TPbaseline

	device     = md.s0
	TPbaseline = md.v0

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_TP1_STP1_TBP" + num2str(TPBaseline) + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	AcquireData_NG(s, device)
End

static Function CheckTPBaseline_REENTRY([STRUCT IUTF_MDATA &md])
	string device
	variable i, numEntries, baselineFraction, baselineFractionRef, pulseDuration, tpLength, samplingInterval

	device              = md.s0
	baselineFractionRef = md.v0 * PERCENT_TO_ONE

	WAVE/T textualValues   = GetLBTextualValues(device)
	WAVE   numericalValues = GetLBNumericalValues(device)

	baselineFraction = GetLastSettingIndep(numericalValues, NaN, "TP Baseline Fraction", TEST_PULSE_MODE)
	CHECK_CLOSE_VAR(baselineFraction, baselineFractionRef)

	pulseDuration = GetLastSettingIndep(numericalValues, NaN, "TP Pulse Duration", TEST_PULSE_MODE)
	CHECK_CLOSE_VAR(pulseDuration, 10)

	WAVE/WAVE storedTPs = GetStoredTestPulseWave(device)
	CHECK_WAVE(storedTPs, WAVE_WAVE)

	numEntries = GetNumberFromWaveNote(storedTPs, NOTE_INDEX)
	CHECK_GT_VAR(numEntries, 0)

	samplingInterval = DAP_GetSampInt(device, TEST_PULSE_MODE, XOP_CHANNEL_TYPE_ADC)

	for(i = 0; i < numEntries; i += 1)
		WAVE/Z singleTP = storedTPs[i]
		CHECK_WAVE(singleTP, NUMERIC_WAVE)

		CHECK_CLOSE_VAR(DimSize(singleTP, ROWS), (MIES_TP#TP_CalculateTestPulseLength(pulseDuration, baselineFraction) * MILLI_TO_MICRO) / samplingInterval, tol = 0.1)
	endfor
End

static Function CheckTPEntriesFromLBN_PreAcq(string device)

	PGC_SetAndActivateControl(device, "setvar_Settings_TP_RTolerance", val = 2)
	PGC_SetAndActivateControl(device, "setvar_Settings_TPBuffer", val = 3)

	// turn off send to all HS
	PGC_SetAndActivateControl(device, "Check_TP_SendToAllHS", val = CHECKBOX_UNSELECTED)

	// select HS0
	PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = 0)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val = -60)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitude", val = 20)
	PGC_SetAndActivateControl(device, "check_DataAcq_AutoTP", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_targetVoltage", val = 10)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_targetVoltageRange", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_IinjMax", val = 300)

	// select HS1
	PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = 1)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val = -70)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitude", val = 30)
	PGC_SetAndActivateControl(device, "check_DataAcq_AutoTP", val = 0)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_targetVoltage", val = 15)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_targetVoltageRange", val = 2)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_IinjMax", val = 400)

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "ChangeTPSettings")
End

/// 2 Headstages
/// 1 VC, 1 IC
/// Different amplitudes and different auto amp settings (although this is not enabled)
/// 2 sweeps with TP during ITI
/// Check that we find all LBN entries and that they also have the correct entry source type
/// The analysis function ChangeTPSettings changes some settings in POST_SWEEP of sweep 1 and PRE_SWEEP_CONFIG of sweep 2. We check
/// that these settings are correctly refelected in the LBN as now TP and DAQ settings for sweep 1 differ.
///
/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckTPEntriesFromLBN([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_GSI0_ITI5_TBP30_TPD15"   + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function/WAVE GetTPLBNEntriesWave_IGNORE()

	string list = "bufferSize;resistanceTol;sendToAllHS;baselineFrac;durationMS;"                                \
	              + "amplitudeVC;amplitudeIC;autoTPEnable;autoAmpMaxCurrent;autoAmpVoltage;autoAmpVoltageRange;" \
	              + "autoTPPercentage;autoTPInterval;autoTPQC"

	Make/FREE/WAVE/N=(ItemsInList(list)) wv
	SetDimensionLabels(wv, list, ROWS)

	return wv
End

static Function/WAVE GetTPLBNEntries_IGNORE(string device, variable sweepNo, variable entrySourceType)

	WAVE numericalValues = GetLBNumericalValues(device)

	WAVE/WAVE wv = GetTPLBNEntriesWave_IGNORE()

	wv[%baselineFrac] = GetLastSetting(numericalValues, sweepNo, "TP Baseline Fraction", entrySourceType)
	wv[%durationMS]   = GetLastSetting(numericalValues, sweepNo, "TP Pulse Duration", entrySourceType)
	wv[%amplitudeIC]  = GetLastSetting(numericalValues, sweepNo, TP_AMPLITUDE_IC_ENTRY_KEY, entrySourceType)
	wv[%amplitudeVC]  = GetLastSetting(numericalValues, sweepNo, TP_AMPLITUDE_VC_ENTRY_KEY, entrySourceType)
	wv[%autoTPEnable] = GetLastSetting(numericalValues, sweepNo, "TP Auto", entrySourceType)
	wv[%autoTPQC]     = GetLastSetting(numericalValues, sweepNo, "TP Auto QC", entrySourceType)

	wv[%autoAmpMaxCurrent]   = GetLastSetting(numericalValues, sweepNo, "TP Auto max current", entrySourceType)
	wv[%autoAmpVoltage]      = GetLastSetting(numericalValues, sweepNo, "TP Auto voltage", entrySourceType)
	wv[%autoAmpVoltageRange] = GetLastSetting(numericalValues, sweepNo, "TP Auto voltage range", entrySourceType)
	wv[%bufferSize]          = GetLastSetting(numericalValues, sweepNo, "TP buffer size", entrySourceType)
	wv[%resistanceTol]       = GetLastSetting(numericalValues, sweepNo, "Minimum TP resistance for tolerance", entrySourceType)
	wv[%sendToAllHS]         = GetLastSetting(numericalValues, sweepNo, "Send TP settings to all headstages", entrySourceType)
	wv[%autoTPPercentage]    = GetLastSetting(numericalValues, sweepNo, "TP Auto percentage", entrySourceType)
	wv[%autoTPInterval]      = GetLastSetting(numericalValues, sweepNo, "TP Auto interval", entrySourceType)

	return wv
End

static Function CheckTPEntriesFromLBN_REENTRY([string str])
	// sweep 0
	WAVE/WAVE/Z entries_S0_DAQ = GetTPLBNEntries_IGNORE(str, 0, DATA_ACQUISITION_MODE)
	CHECK_WAVE(entries_S0_DAQ, WAVE_WAVE)

	CHECK_EQUAL_WAVES(entries_S0_DAQ[%baselineFrac], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0.30}, mode = WAVE_DATA, tol = 1e-8)
	CHECK_EQUAL_WAVES(entries_S0_DAQ[%durationMS], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 15}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries_S0_DAQ[%amplitudeIC], {-60, -70, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_DAQ[%amplitudeVC], {20, 30, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_DAQ[%autoTPEnable], {1, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_DAQ[%autoAmpMaxCurrent], {300, 400, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_DAQ[%autoAmpVoltage], {10, 15, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_DAQ[%autoAmpVoltageRange], {1, 2, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries_S0_DAQ[%bufferSize], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 3}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_DAQ[%resistanceTol], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 2}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_DAQ[%sendToAllHS], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_DAQ[%autoTPPercentage], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 90}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_DAQ[%autoTPInterval], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0}, mode = WAVE_DATA)

	CHECK_WAVE(entries_S0_DAQ[%autoTPQC], NULL_WAVE)

	WAVE/WAVE/Z entries_S0_TP = GetTPLBNEntries_IGNORE(str, 0, TEST_PULSE_MODE)
	CHECK_WAVE(entries_S0_TP, WAVE_WAVE)

	CHECK_EQUAL_WAVES(entries_S0_TP[%baselineFrac], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0.30}, mode = WAVE_DATA, tol = 1e-8)
	CHECK_EQUAL_WAVES(entries_S0_TP[%durationMS], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 15}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries_S0_TP[%amplitudeIC], {-60, -70, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_TP[%amplitudeVC], {20, 30, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_TP[%autoTPEnable], {1, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_TP[%autoAmpMaxCurrent], {300, 400, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_TP[%autoAmpVoltage], {10, 15, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_TP[%autoAmpVoltageRange], {1, 2, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries_S0_TP[%bufferSize], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 3}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_TP[%resistanceTol], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 2}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_TP[%sendToAllHS], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_TP[%autoTPPercentage], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 90}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S0_TP[%autoTPInterval], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0}, mode = WAVE_DATA)

	CHECK_WAVE(entries_S0_TP[%autoTPQC], NULL_WAVE)

	// sweep 1
	WAVE/WAVE/Z entries_S1_DAQ = GetTPLBNEntries_IGNORE(str, 1, DATA_ACQUISITION_MODE)
	CHECK_WAVE(entries_S1_DAQ, WAVE_WAVE)

	CHECK_EQUAL_WAVES(entries_S1_DAQ[%baselineFrac], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0.30}, mode = WAVE_DATA, tol = 1e-8)
	CHECK_EQUAL_WAVES(entries_S1_DAQ[%durationMS], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 15}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries_S1_DAQ[%amplitudeIC], {-60, -70, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_DAQ[%amplitudeVC], {20, 30, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_DAQ[%autoTPEnable], {1, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_DAQ[%autoAmpMaxCurrent], {300, 400, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_DAQ[%autoAmpVoltage], {10, 15, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_DAQ[%autoAmpVoltageRange], {1, 2, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries_S1_DAQ[%bufferSize], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 3}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_DAQ[%resistanceTol], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 2}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_DAQ[%sendToAllHS], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_DAQ[%autoTPPercentage], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 90}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_DAQ[%autoTPInterval], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0}, mode = WAVE_DATA)

	CHECK_WAVE(entries_S1_DAQ[%autoTPQC], NULL_WAVE)

	WAVE/WAVE/Z entries_S1_TP = GetTPLBNEntries_IGNORE(str, 1, TEST_PULSE_MODE)
	CHECK_WAVE(entries_S1_TP, WAVE_WAVE)

	CHECK_EQUAL_WAVES(entries_S1_TP[%baselineFrac], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0.30}, mode = WAVE_DATA, tol = 1e-8)
	CHECK_EQUAL_WAVES(entries_S1_TP[%durationMS], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 15}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries_S1_TP[%amplitudeIC], {-80, -70, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_TP[%amplitudeVC], {20, 40, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_TP[%autoTPEnable], {1, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_TP[%autoAmpMaxCurrent], {300, 400, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_TP[%autoAmpVoltage], {10, 15, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_TP[%autoAmpVoltageRange], {1, 2, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries_S1_TP[%bufferSize], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 3}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_TP[%resistanceTol], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 2}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_TP[%sendToAllHS], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_TP[%autoTPPercentage], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 90}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S1_TP[%autoTPInterval], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0}, mode = WAVE_DATA)

	CHECK_WAVE(entries_S1_TP[%autoTPQC], NULL_WAVE)

	// sweep 2
	WAVE/WAVE/Z entries_S2_DAQ = GetTPLBNEntries_IGNORE(str, 2, DATA_ACQUISITION_MODE)
	CHECK_WAVE(entries_S2_DAQ, WAVE_WAVE)

	CHECK_EQUAL_WAVES(entries_S2_DAQ[%baselineFrac], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0.30}, mode = WAVE_DATA, tol = 1e-8)
	CHECK_EQUAL_WAVES(entries_S2_DAQ[%durationMS], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 15}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries_S2_DAQ[%amplitudeIC], {-90, -70, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S2_DAQ[%amplitudeVC], {50, 40, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S2_DAQ[%autoTPEnable], {1, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S2_DAQ[%autoAmpMaxCurrent], {300, 400, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S2_DAQ[%autoAmpVoltage], {10, 15, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S2_DAQ[%autoAmpVoltageRange], {1, 2, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries_S2_DAQ[%bufferSize], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 3}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S2_DAQ[%resistanceTol], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 2}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S2_DAQ[%sendToAllHS], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S2_DAQ[%autoTPPercentage], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 90}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries_S2_DAQ[%autoTPInterval], {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0}, mode = WAVE_DATA)

	CHECK_WAVE(entries_S2_DAQ[%autoTPQC], NULL_WAVE)

	WAVE/WAVE/Z entries_S2_TP = GetTPLBNEntries_IGNORE(str, 2, TEST_PULSE_MODE)
	CHECK_WAVE(entries_S2_TP, WAVE_WAVE)

	Make/N=(DimSize(entries_S2_TP, ROWS))/FREE validWaves = WaveExists(entries_S2_TP[p])
	CHECK_EQUAL_VAR(Sum(validWaves), 0)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function TPCachingWorks([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_TP1_SIM4_STP1"           + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)

	CtrlNamedBackGround StartDAQDuringTP, start=(ticks + 600), period=100, proc=StartAcq_IGNORE
End

static Function TPCachingWorks_REENTRY([string str])
	variable sweepNo, numEntries, samplingInterval, samplingIntervalMultiplier

	NVAR runModeDAQ = $GetDataAcqRunMode(str)

	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(str)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE/WAVE storedTP = GetStoredTestPulseWave(str)
	CHECK_WAVE(storedTP, WAVE_WAVE)
	numEntries = DimSize(storedTP, ROWS)

	Make/FREE/N=(numEntries) dimDeltas = WaveExists(storedTP[p]) ? DimDelta(storedTP[p], ROWS) : NaN

	WAVE/Z dimDeltasClean = ZapNaNs(dimDeltas)
	CHECK_WAVE(dimDeltasClean, NUMERIC_WAVE)

	WAVE/Z dimDeltasUnique = GetUniqueEntries(dimDeltasClean)
	CHECK_WAVE(dimDeltasUnique, NUMERIC_WAVE)

	WAVE numericalValues = GetLBNumericalValues(str)
	samplingInterval           = GetLastSettingIndep(numericalValues, sweepNo, "Sampling Interval AD", DATA_ACQUISITION_MODE)
	samplingIntervalMultiplier = GetLastSettingIndep(numericalValues, sweepNo, "Sampling Interval Multiplier", DATA_ACQUISITION_MODE)

	CHECK_EQUAL_VAR(DimSize(dimDeltasUnique, ROWS), 1)
	CHECK_CLOSE_VAR(samplingInterval / samplingIntervalMultiplier, dimDeltasUnique[0], tol = 1e-3)
End

static Function/WAVE ExtractValidValues(WAVE TPStorage, variable headstage, string entry)
	variable idx

	idx = FindDimLabel(TPStorage, LAYERS, entry)
	CHECK_GE_VAR(idx, 0)

	Duplicate/FREE/RMD=[*][headstage][idx] TPStorage, slice
	Redimension/E=1/N=(numpnts(slice)) slice

	return ZapNaNs(slice)
End

static Function CheckTPStorage(string device)
	string entry

	WAVE/Z TPStorage = GetTPStorage(device)
	CHECK_WAVE(TPStorage, NUMERIC_WAVE, minorType = DOUBLE_WAVE)

	entry = "ADC"
	WAVE/Z values = ExtractvalidValues(TPStorage, 0, entry)
	CHECK_WAVE(values, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK(IsConstant(values, 0))

	WAVE/Z values = ExtractvalidValues(TPStorage, 1, entry)
	CHECK_WAVE(values, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK(IsConstant(values, 1))

	entry = "DAC"
	WAVE/Z values = ExtractvalidValues(TPStorage, 0, entry)
	CHECK_WAVE(values, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK(IsConstant(values, 0))

	WAVE/Z values = ExtractvalidValues(TPStorage, 1, entry)
	CHECK_WAVE(values, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK(IsConstant(values, 1))

	entry = "Headstage"
	WAVE/Z values = ExtractvalidValues(TPStorage, 0, entry)
	CHECK_WAVE(values, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK(IsConstant(values, 0))

	WAVE/Z values = ExtractvalidValues(TPStorage, 1, entry)
	CHECK_WAVE(values, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK(IsConstant(values, 1))

	entry = "ClampMode"
	WAVE/Z values = ExtractvalidValues(TPStorage, 0, entry)
	CHECK_WAVE(values, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK(IsConstant(values, V_CLAMP_MODE))

	WAVE/Z values = ExtractvalidValues(TPStorage, 1, entry)
	CHECK_WAVE(values, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK(IsConstant(values, I_CLAMP_MODE))

	// resistance values are constant and independent of IC/VC amplitudes
	entry = "PeakResistance"
	WAVE/Z values = ExtractvalidValues(TPStorage, 0, entry)
	CHECK_WAVE(values, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	WaveStats/M=0/Q values
	CHECK_CLOSE_VAR(V_avg, 10, tol = 0.1)

	WAVE/Z values = ExtractvalidValues(TPStorage, 1, entry)
	CHECK_WAVE(values, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	WaveStats/M=0/Q values
	CHECK_CLOSE_VAR(V_avg, 250, tol = 0.1)

	entry = "SteadyStateResistance"
	WAVE/Z values = ExtractvalidValues(TPStorage, 0, entry)
	CHECK_WAVE(values, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	WaveStats/M=0/Q values
	CHECK_CLOSE_VAR(V_avg, 10, tol = 0.1)

	WAVE/Z values = ExtractvalidValues(TPStorage, 1, entry)
	CHECK_WAVE(values, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	WaveStats/M=0/Q values
	CHECK_CLOSE_VAR(V_avg, 250, tol = 0.1)

	entry = "baseline_IC"
	WAVE/Z values = ExtractvalidValues(TPStorage, 0, entry)
	CHECK_WAVE(values, NULL_WAVE)

	WAVE/Z values = ExtractvalidValues(TPStorage, 1, entry)
	CHECK_WAVE(values, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	WaveStats/M=0/Q values
	CHECK_LT_VAR(V_avg, 100)

	entry = "baseline_VC"
	WAVE/Z values = ExtractvalidValues(TPStorage, 0, entry)
	WaveStats/M=0/Q values
	CHECK_LT_VAR(V_avg, 100)

	WAVE/Z values = ExtractvalidValues(TPStorage, 1, entry)
	CHECK_WAVE(values, NULL_WAVE)
End

static Function EnsureUnityGain(string device, variable headstage)
	variable gain, mode, ret

	mode = DAG_GetHeadstageMode(device, headstage)

	ret = AI_SendToAmp(device, headstage, mode, MCC_SETPRIMARYSIGNALGAIN_FUNC, 1)
	CHECK(!ret)

	ret = AI_SendToAmp(device, headstage, mode, MCC_SETSECONDARYSIGNALGAIN_FUNC, 1)
	CHECK(!ret)

	gain = AI_SendToAmp(device, headstage, mode, MCC_GETPRIMARYSIGNALGAIN_FUNC, NaN)
	REQUIRE_EQUAL_VAR(gain, 1)

	gain = AI_SendToAmp(device, headstage, mode, MCC_GETSECONDARYSIGNALGAIN_FUNC, NaN)
	REQUIRE_EQUAL_VAR(gain, 1)
End

static Function CheckTPStorage1_PreAcq(string device)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitude", val = 15)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val = -75)

	EnsureUnityGain(device, 0)
	EnsureUnityGain(device, 1)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
End

/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckTPStorage1([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_TP1"                     + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function CheckTPStorage1_REENTRY([string str])
	CheckTPStorage(str)
End

static Function CheckTPStorage2_PreAcq(string device)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val = 1)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitude", val = 37)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val = -150)

	EnsureUnityGain(device, 0)
	EnsureUnityGain(device, 1)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
End

/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckTPStorage2([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_TP1"                     + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function CheckTPStorage2_REENTRY([string str])
	CheckTPStorage(str)
End

static Function CheckTPStorage3_PreAcq(string device)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val = 1)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitude", val = -15)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val = 50)

	EnsureUnityGain(device, 0)
	EnsureUnityGain(device, 1)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
End

/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckTPStorage3([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_TP1"                     + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function CheckTPStorage3_REENTRY([string str])
	CheckTPStorage(str)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function TPDuringDAQOnlyTP([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"              + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:TestPulse:")

	AcquireData_NG(s, str)
End

static Function TPDuringDAQOnlyTP_REENTRY([str])
	string str

	variable sweepNo, col
	string ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, 0)
	CHECK_WAVE(sweepWave, TEXT_WAVE)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(configWave, ROWS), 2)
	CHECK_EQUAL_VAR(DimSize(configWave, COLS), 8)

	WAVE channelAD = ResolveSweepChannel(sweepWave, GetFirstADCChannelIndex(configWave))
	CHECK_EQUAL_VAR(GetMinSamplingInterval(unit = "ms"), DimDelta(channelAD, ROWS))
	CHECK_EQUAL_VAR(DimSize(channelAD, ROWS) * DimDelta(channelAD, ROWS) / 1000, TIME_TP_ONLY_ON_DAQ)

	col = FindDimLabel(configWave, COLS, "DAQChannelType")
	Duplicate/FREE/R=[][col] configWave, channelTypes
	Redimension/N=-1 channelTypes
	CHECK_EQUAL_WAVES(channelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_TP}, mode = WAVE_DATA)

	WAVE/T units = AFH_GetChannelUnits(configWave)
	CHECK_EQUAL_TEXTWAVES(units, {"mV", "pA"}, mode = WAVE_DATA)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues   = GetLBTextualValues(str)

	WAVE DAChannelTypes = GetLastSetting(numericalValues, sweepNo, "DA ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(DAChannelTypes, {DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE ADChannelTypes = GetLastSetting(numericalValues, sweepNo, "AD ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(ADChannelTypes, {DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z stimScale   = GetLastSetting(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
	WAVE/Z tpAmplitude = GetLastSetting(numericalValues, sweepNo, TP_AMPLITUDE_VC_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_WAVE(tpAmplitude, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(stimScale, {tpAmplitude[0], NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z/T stimsets = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_TEXTWAVES(stimsets, {"TestPulse", "", "", "", "", "", "", "", ""}, mode = WAVE_DATA)
End

// UTF_TD_GENERATOR v0:IndexingPossibilities
// UTF_TD_GENERATOR s0:DeviceNameGeneratorMD1
static Function TPDuringDAQOnlyTPAndIndexing([STRUCT IUTF_MDATA &md])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L" + num2str(md.v0) + "_BKG1_RES3" + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:TestPulse:")

	AcquireData_NG(s, md.s0)
End

static Function TPDuringDAQOnlyTPAndIndexing_REENTRY([STRUCT IUTF_MDATA &md])

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(md.s0, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(md.s0)
	CHECK_EQUAL_VAR(sweepNo, 2)

	// generic properties are checked in TPDuringDAQOnlyTP
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function TPDuringDAQTPAndUnAssoc([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1"                      + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:TestPulse:"           + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetA_DA_0:_ASO0")

	AcquireData_NG(s, str)
End

static Function TPDuringDAQTPAndUnAssoc_REENTRY([str])
	string str

	variable sweepNo, col, channelTypeUnassoc, stimScaleUnassoc, stimSetLengthRef
	string ctrl, stimsetUnassoc, stimsetUnassocRef, key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, 0)
	CHECK_WAVE(sweepWave, TEXT_WAVE)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(configWave, ROWS), 4)
	CHECK_EQUAL_VAR(DimSize(configWave, COLS), 8)

	WAVE channelAD = ResolveSweepChannel(sweepWave, GetFirstADCChannelIndex(configWave))
	CHECK_EQUAL_VAR(2 * GetMinSamplingInterval(unit = "ms"), DimDelta(channelAD, ROWS))
	stimSetLengthRef = 0.958336 // length of StimulusSetA_DA_0
	CHECK_CLOSE_VAR(DimSize(channelAD, ROWS) * DimDelta(channelAD, ROWS) / 1000, stimSetLengthRef, tol = 1E-3)

	col = FindDimLabel(configWave, COLS, "DAQChannelType")
	Duplicate/FREE/R=[][col] configWave, channelTypes
	Redimension/N=-1 channelTypes

	// the unassociated AD channel is in DAQ mode
	CHECK_EQUAL_WAVES(channelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ}, mode = WAVE_DATA)

	WAVE/T units = AFH_GetChannelUnits(configWave)
	CHECK_EQUAL_TEXTWAVES(units, {"mV", "V", "pA", "V"}, mode = WAVE_DATA)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues   = GetLBTextualValues(str)

	WAVE/Z setCycleCount = GetLastSetting(numericalValues, sweepNo, "Set Cycle Count", DATA_ACQUISITION_MODE)
	CHECK_WAVE(setCycleCount, NULL_WAVE)

	WAVE DAChannelTypes = GetLastSetting(numericalValues, sweepNo, "DA ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(DAChannelTypes, {DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE ADChannelTypes = GetLastSetting(numericalValues, sweepNo, "AD ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(ADChannelTypes, {DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	key                = CreateLBNUnassocKey("DA ChannelType", 1, XOP_CHANNEL_TYPE_DAC)
	channelTypeUnassoc = GetLastSettingIndep(numericalValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(channelTypeUnassoc, DAQ_CHANNEL_TYPE_DAQ)

	key                = CreateLBNUnassocKey("AD ChannelType", 1, XOP_CHANNEL_TYPE_ADC)
	channelTypeUnassoc = GetLastSettingIndep(numericalValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(channelTypeUnassoc, DAQ_CHANNEL_TYPE_DAQ)

	WAVE/Z stimScale   = GetLastSetting(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
	WAVE/Z tpAmplitude = GetLastSetting(numericalValues, sweepNo, TP_AMPLITUDE_VC_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_WAVE(tpAmplitude, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(stimScale, {tpAmplitude[0], NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	key              = CreateLBNUnassocKey(STIMSET_SCALE_FACTOR_KEY, 1, XOP_CHANNEL_TYPE_DAC)
	stimScaleUnassoc = GetLastSettingIndep(numericalValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(stimScaleUnassoc, 1.0)

	WAVE/Z/T stimsets = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_TEXTWAVES(stimsets, {"TestPulse", "", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	key               = CreateLBNUnassocKey(STIM_WAVE_NAME_KEY, 1, XOP_CHANNEL_TYPE_DAC)
	stimsetUnassoc    = GetLastSettingTextIndep(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	stimsetUnassocRef = "StimulusSetA_DA_0"
	CHECK_EQUAL_STR(stimsetUnassoc, stimsetUnassocRef)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function TPDuringDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                      + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:TestPulse:"      + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function TPDuringDAQ_REENTRY([str])
	string str

	variable sweepNo, col, daGain
	string ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, 0)
	CHECK_WAVE(sweepWave, TEXT_WAVE)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(configWave, ROWS), 4)
	CHECK_EQUAL_VAR(DimSize(configWave, COLS), 8)

	WAVE channelAD = ResolveSweepChannel(sweepWave, GetFirstADCChannelIndex(configWave))
	CHECK_EQUAL_VAR(2 * GetMinSamplingInterval(unit = "ms"), DimDelta(channelAD, ROWS))

	col = FindDimLabel(configWave, COLS, "DAQChannelType")
	Duplicate/FREE/R=[][col] configWave, channelTypes
	Redimension/N=-1 channelTypes

	CHECK_EQUAL_WAVES(channelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ}, mode = WAVE_DATA)

	WAVE/T units = AFH_GetChannelUnits(configWave)
	CHECK_EQUAL_TEXTWAVES(units, {"mV", "mV", "pA", "pA"}, mode = WAVE_DATA)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues   = GetLBTextualValues(str)

	WAVE setCycleCount = GetLastSetting(numericalValues, sweepNo, "Set Cycle Count", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(setCycleCount, {NaN, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE DAChannelTypes = GetLastSetting(numericalValues, sweepNo, "DA ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(DAChannelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE ADChannelTypes = GetLastSetting(numericalValues, sweepNo, "AD ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(ADChannelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z stimScale   = GetLastSetting(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
	WAVE/Z tpAmplitude = GetLastSetting(numericalValues, sweepNo, TP_AMPLITUDE_VC_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_WAVE(tpAmplitude, NUMERIC_WAVE)
	daGain = DAG_GetNumericalValue(str, GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE), index = 0)

	CHECK_EQUAL_WAVES(stimScale, {tpAmplitude[0], daGain, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z/T stimsets = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_TEXTWAVES(stimsets, {"TestPulse", "StimulusSetC_DA_0", "", "", "", "", "", "", ""}, mode = WAVE_DATA)
End

static Function TPDuringDAQWithoodDAQ_PreAcq(device)
	string device

	PGC_SetAndActivateControl(device, "check_Settings_RequireAmpConn", val = 0)
	// Reduce amplification to prevent border vals
	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = 2)
	PGC_SetAndActivateControl(device, "setvar_Settings_VC_DAgain", val = 2)
	PGC_SetAndActivateControl(device, "Gain_DA_02", val = 2)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function TPDuringDAQWithoodDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_oodDAQ1"                 + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:TestPulse:"         + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:" + \
	                             "__HS2_DA2_AD2_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function TPDuringDAQWithoodDAQ_REENTRY([str])
	string str

	variable sweepNo, col, daGain, oodDAQ
	string ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, 0)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NORMAL_WAVE)
	CHECK_EQUAL_VAR(DimSize(configWave, ROWS), 6)
	CHECK_EQUAL_VAR(DimSize(configWave, COLS), 8)

	col = FindDimLabel(configWave, COLS, "DAQChannelType")
	Duplicate/FREE/R=[][col] configWave, channelTypes
	Redimension/N=-1 channelTypes

	CHECK_EQUAL_WAVES(channelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_DAQ}, mode = WAVE_DATA)

	WAVE/T units = AFH_GetChannelUnits(configWave)
	CHECK_EQUAL_TEXTWAVES(units, {"mV", "mV", "mV", "pA", "pA", "pA"}, mode = WAVE_DATA)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues   = GetLBTextualValues(str)

	WAVE DAChannelTypes = GetLastSetting(numericalValues, sweepNo, "DA ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(DAChannelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_DAQ, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE ADChannelTypes = GetLastSetting(numericalValues, sweepNo, "AD ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(ADChannelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_DAQ, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z stimScale   = GetLastSetting(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
	WAVE/Z tpAmplitude = GetLastSetting(numericalValues, sweepNo, TP_AMPLITUDE_VC_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_WAVE(tpAmplitude, NUMERIC_WAVE)

	daGain = DAG_GetNumericalValue(str, GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE), index = 0)

	oodDAQ = GetLastSettingIndep(numericalValues, sweepNo, "Optimized Overlap dDAQ", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(oodDAQ, 1)

	WAVE/Z oodDAQMembers = GetLastSetting(numericalValues, sweepNo, "oodDAQ member", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(oodDAQMembers, {0, 1, 1, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(stimScale, {tpAmplitude[0], daGain, daGain, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z/T stimsets = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_TEXTWAVES(stimsets, {"TestPulse", "StimulusSetC_DA_0", "StimulusSetC_DA_0", "", "", "", "", "", ""}, mode = WAVE_DATA)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function TPDuringDAQOnlyWithoodDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_oodDAQ1"         + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:TestPulse:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:TestPulse:")

	AcquireData_NG(s, str)
End

static Function TPDuringDAQOnlyWithoodDAQ_REENTRY([str])
	string str

	variable sweepNo, col, oodDAQ

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, 0)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NORMAL_WAVE)
	CHECK_EQUAL_VAR(DimSize(configWave, ROWS), 4)
	CHECK_EQUAL_VAR(DimSize(configWave, COLS), 8)

	col = FindDimLabel(configWave, COLS, "DAQChannelType")
	Duplicate/FREE/R=[][col] configWave, channelTypes
	Redimension/N=-1 channelTypes

	CHECK_EQUAL_WAVES(channelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_TP}, mode = WAVE_DATA)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues   = GetLBTextualValues(str)

	WAVE DAChannelTypes = GetLastSetting(numericalValues, sweepNo, "DA ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(DAChannelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE ADChannelTypes = GetLastSetting(numericalValues, sweepNo, "AD ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(ADChannelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	oodDAQ = GetLastSettingIndep(numericalValues, sweepNo, "Optimized Overlap dDAQ", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(oodDAQ, 1)

	WAVE/Z oodDAQMembers = GetLastSetting(numericalValues, sweepNo, "oodDAQ member", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(oodDAQMembers, {0, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z/T stimsets = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_TEXTWAVES(stimsets, {"TestPulse", "TestPulse", "", "", "", "", "", "", ""}, mode = WAVE_DATA)
End

static Function TPDuringDAQTPStoreCheck_PreAcq(device)
	string device

	PGC_SetAndActivateControl(device, "check_Settings_RequireAmpConn", val = 0)
	// Reduce amplification to prevent border vals
	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = 2)
	PGC_SetAndActivateControl(device, "setvar_Settings_VC_DAgain", val = 2)
	PGC_SetAndActivateControl(device, "Gain_DA_02", val = 2)
End

static Constant TP_WAIT_TIMEOUT = 5

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function TPDuringDAQTPStoreCheck([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_oodDAQ1_STP1"               + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:TestPulse:"            + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:PulseTrain_10Hz_DA_0:" + \
	                             "__HS2_DA2_AD2_CM:VC:_ST:TestPulse:")
	AcquireData_NG(s, str)
End

static Function TPDuringDAQTPStoreCheck_REENTRY([str])
	string str

	WaitAndCheckStoredTPs_IGNORE(str, 2)
End

static Function WaitAndCheckStoredTPs_IGNORE(device, expectedNumTPchannels)
	string   device
	variable expectedNumTPchannels

	variable i, channel, numTPChan, numStored, numTP
	variable tresh, m, tpLength, pulseLengthMS
	string wlName

	WAVE/Z TPStorage = GetTPStorage(device)
	CHECK_WAVE(TPStorage, NORMAL_WAVE)
	numStored = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)
	CHECK_GT_VAR(numStored, 0)

	WAVE/Z/WAVE storedTestPulses = GetStoredTestPulseWave(device)
	CHECK_WAVE(storedTestPulses, WAVE_WAVE)
	numTP = GetNumberFromWaveNote(storedTestPulses, NOTE_INDEX)

	wlName = GetWorkLoadName(WORKLOADCLASS_TP, device)
	CHECK(!ASYNC_WaitForWLCToFinishAndRemove(wlName, TP_WAIT_TIMEOUT))

	WAVE TPSettingsCalculated = GetTPsettingsCalculated(device)

	tpLength      = TPSettingsCalculated[%totalLengthPointsDAQ]
	pulseLengthMS = TPSettingsCalculated[%pulseLengthMS]

	for(i = 0; i < numTP; i += 1)

		WAVE/Z singleTPs = storedTestPulses[i]
		CHECK_WAVE(singleTPs, NUMERIC_WAVE)

		CHECK_EQUAL_VAR(tpLength, DimSize(singleTPs, ROWS))
		numTPChan = DimSize(singleTPs, COLS)
		CHECK_EQUAL_VAR(expectedNumTPchannels, numTPChan)

		for(channel = 0; channel < numTPChan; channel += 1)

			Duplicate/FREE/RMD=[][channel] singleTPs, singleTP
			Redimension/N=(tpLength) singleTP

			CHECK_GT_VAR(DimSize(singleTP, ROWS), 0)
			CHECK_WAVE(singleTP, NUMERIC_WAVE, minorType = FLOAT_WAVE)
		endfor
	endfor
End

static Function CheckThatTPsCanBeFound_PreAcq(device)
	string device

	PrepareForPublishTest()
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckThatTPsCanBeFound([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_TP1_STP1"                + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)

	CtrlNamedBackGround StopTPAfterFiveSeconds, start=(ticks + TP_DURATION_S * 60), period=1, proc=StopTPAfterFiveSeconds_IGNORE
End

static Function CheckThatTPsCanBeFound_REENTRY([str])
	string str

	variable duration, index, col, i

	// check that we have at least 4.5 seconds of data
	WAVE/Z TPStorage = GetTPStorage(str)
	CHECK_WAVE(TPStorage, NORMAL_WAVE)

	index = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)
	CHECK_GT_VAR(index, 0)
	duration = TPStorage[index - 1][0][%DeltaTimeInSeconds]
	CHECK_GT_VAR(duration, TP_DURATION_S * 0.9)

	WaitAndCheckStoredTPs_IGNORE(str, 2)

	col = FindDimLabel(TPStorage, LAYERS, "TPMarker")
	Duplicate/FREE/RMD=[0, index - 1][0][col] TPStorage, TPMarker
	Redimension/N=-1 TPMarker

	// ensure that we have a one-to-one mapping between the stored Testpulses and our TPMarkers
	WAVE/Z/WAVE storedTestPulses = GetStoredTestPulseWave(str)
	CHECK_WAVE(storedTestPulses, WAVE_WAVE)

	Make/FREE/D/N=(index) TPMarkerTestpulses
	Make/FREE/T/N=(index) Headstages

	// fetch TPMarkers
	for(i = 0; i < index; i += 1)
		WAVE/Z wv = storedTestPulses[i]
		CHECK_WAVE(wv, FREE_WAVE)
		TPMarkerTestpulses[i] = GetNumberFromWaveNote(wv, "TPMarker")
		Headstages[i]         = GetStringFromWaveNote(wv, "Headstages")
	endfor

	FindDuplicates/RT=HeadstagesNoDups/FREE Headstages
	CHECK_EQUAL_TEXTWAVES(HeadstagesNoDups, {"0,1,"}, mode = WAVE_DATA)

	Sort/A TPMarkerTestpulses, TPMarkerTestpulses
	Sort/A TPMarker, TPMarker

	CHECK_EQUAL_WAVES(TPMarkerTestpulses, TPMarker, mode = WAVE_DATA)

	FindDuplicates/DN=dups/FREE TPMarkerTestpulses
	CHECK_EQUAL_VAR(DimSize(dups, ROWS), 0)

	FindDuplicates/DN=dups/FREE TPMarker
	CHECK_EQUAL_VAR(DimSize(dups, ROWS), 0)

	CheckStartStopMessages("tp", "starting")
	CheckStartStopMessages("tp", "stopping")
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function TPDuringDAQWithTTL([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_TBP25"                   + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:TestPulse:"         + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:" + \
	                             "__TTL0_ST:StimulusSetA_TTL_0:")

	AcquireData_NG(s, str)
End

static Function TPDuringDAQWithTTL_REENTRY([str])
	string str

	variable sweepNo, col, tpAmplitude, daGain, i
	string ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, 0)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	WAVE TPSettingsCalculated = GetTPSettingsCalculated(str)

	// correct test pulse lengths calculated for both modes
#if defined(TESTS_WITH_ITC18USB_HARDWARE)
	CHECK_EQUAL_VAR(TPSettingsCalculated[%totalLengthPointsDAQ], 1000)
	CHECK_EQUAL_VAR(TPSettingsCalculated[%totalLengthPointsTP], 2000)
#elif defined(TESTS_WITH_ITC1600_HARDWARE)
	CHECK_EQUAL_VAR(TPSettingsCalculated[%totalLengthPointsDAQ], 2000)
	CHECK_EQUAL_VAR(TPSettingsCalculated[%totalLengthPointsTP], 2000)
#elif defined(TESTS_WITH_NI_HARDWARE)
	CHECK_EQUAL_VAR(TPSettingsCalculated[%totalLengthPointsDAQ], 5000)
	CHECK_EQUAL_VAR(TPSettingsCalculated[%totalLengthPointsTP], 5000)
#endif

	for(i = 0; i < 2; i += 1)
		WAVE/Z DA = AFH_ExtractOneDimDataFromSweep(str, sweepWAVE, i, XOP_CHANNEL_TYPE_DAC)
		CHECK_WAVE(DA, NUMERIC_WAVE)

		// check that we start with the baseline
		WAVEStats/M=1/Q/RMD=[0, 100] DA
		CHECK_EQUAL_VAR(V_min, 0)
		CHECK_EQUAL_VAR(V_max, 0)
		CHECK_EQUAL_VAR(V_numNaNs, 0)
		CHECK_EQUAL_VAR(V_numinfs, 0)

		// testpulse/ inserted TP itself has the correct length
		FindLevels/Q/N=(2) DA, 5
		WAVE W_FindLevels
		MakeWaveFree(W_FindLevels)

		CHECK(!V_flag)

		// hardcode values for 10ms pulse and 25% baseline
		CHECK_CLOSE_VAR(W_FindLevels[0], 5, tol = 0.1)
		CHECK_CLOSE_VAR(W_FindLevels[1], 15, tol = 0.1)
	endfor
End

static Function RunPowerSpectrum_PreAcq(device)
	string device

	PGC_SetAndActivateControl(device, "check_settings_show_power", val = 1)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function RunPowerSpectrum([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_TP1" + \
	                             "__HS0_DA0_AD0_CM:VC:"   + \
	                             "__HS1_DA1_AD1_CM:IC:")

	AcquireData_NG(s, str)

	CtrlNamedBackGround StopTPAfterFiveSeconds, start=(ticks + TP_DURATION_S * 60), period=1, proc=StopTPAfterFiveSeconds_IGNORE
End

static Function RunPowerSpectrum_REENTRY([str])
	string str

	variable sweepNo
	string   ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE sweepDataLNB = GetSweepSettingsWave(str)
	CHECK_EQUAL_VAR(0, sweepDataLNB[0][%$STIMSET_SCALE_FACTOR_KEY][0])
	CHECK_EQUAL_VAR(0, sweepDataLNB[0][%$STIMSET_SCALE_FACTOR_KEY][1])

End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function TestPulseCachingWorks([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_GSI0_ITI3"               + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function TestPulseCachingWorks_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE/T keyWave = GetCacheKeyWave()
	// approximate search
	FindValue/TEXT=("HW Datawave Testpulse") keyWave
	CHECK_GE_VAR(V_Value, 0)

	WAVE stats = GetCacheStatsWave()
	CHECK_GE_VAR(stats[V_Value][%Hits], 1)
End

/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function ExportIntoNWB([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_TP1"                     + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)

	CtrlNamedBackGround StopTPAfterFiveSeconds, start=(ticks + TP_DURATION_S * 60), period=1, proc=StopTPAfterFiveSeconds_IGNORE
End

static Function ExportIntoNWB_REENTRY([str])
	string   str
	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	RegisterReentryFunction("TestPulseAndTPDuringDAQ#" + GetRTStackInfo(1))

	PGC_SetAndActivateControl(str, "Check_Settings_NwbExport", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(str, "StartTestPulseButton")

	CtrlNamedBackGround StopTPAfterFiveSeconds, start=(ticks + TP_DURATION_S * 60), period=1, proc=StopTPAfterFiveSeconds_IGNORE
End

static Function ExportIntoNWB_REENTRY_REENTRY([str])
	string   str
	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function TPDuringDAQwithPS_PreAcq(device)
	string device

	PGC_SetAndActivateControl(device, "check_settings_show_power", val = 1)
End

/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function GetStoredTPTest([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_STP1_TP1"        + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:TestPulse:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:TestPulse:")

	AcquireData_NG(s, str)

	CtrlNamedBackGround StopTPAfterFiveSeconds, start=(ticks + TP_DURATION_S * 60), period=1, proc=StopTPAfterFiveSeconds_IGNORE
End

static Function GetStoredTPTest_REENTRY([str])
	string str
	variable i, sweepNo, marker, cycleId, headstage, numHS

	Make/FREE/D headstages = {0, 1}
	numHS = DimSize(headstages, ROWS)

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WaitAndCheckStoredTPs_IGNORE(str, numHS)

	WAVE/Z TPStorage = GetTPStorage(str)
	CHECK_WAVE(TPStorage, NUMERIC_WAVE)
	marker = TPStorage[0][0][%TPMarker]
	CHECK_NEQ_VAR(marker, NaN)

	// Check GetStoredTP
	WAVE/Z storedTPData = TP_GetStoredTP(str, NaN, 0, 1)
	CHECK_WAVE(storedTPData, NULL_WAVE)

	try
		WAVE/Z storedTPData = TP_GetStoredTP(str, marker, NaN, 1)
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE/WAVE/N=(numHS) tpDACsRef, tpResultsRef
	for(headstage : headstages)
		WAVE/Z storedTPData = TP_GetStoredTP(str, marker, headstage, 1)
		CHECK_WAVE(storedTPData, WAVE_WAVE)
		CHECK_EQUAL_VAR(DimSize(storedTPData, ROWS), 3)

		WAVE/WAVE tpData = storedTPData
		WAVE/Z    tpADC  = tpData[0]
		WAVE/Z    tpDAC  = tpData[1]
		WAVE/Z    tpInfo = tpData[2]

		CHECK_WAVE(tpADC, NUMERIC_WAVE)
		CHECK_GE_VAR(DimSize(tpADC, ROWS), 1)
		CHECK_WAVE(tpDAC, NUMERIC_WAVE)
		CHECK_GE_VAR(DimSize(tpDAC, ROWS), 1)

		WAVE tpResult = MIES_TP#TP_GetTPMetaData(tpStorage, marker, headstage)
		CHECK_EQUAL_WAVES(tpInfo, tpResult)

		tpDACsRef[i]    = tpDAC
		tpResultsRef[i] = tpInfo
		i              += 1
	endfor

	// Check TP_GetStoredTPsFromCycle
	cycleId = TPStorage[0][0][%TPCycleID]
	CHECK_NEQ_VAR(cycleId, NaN)

	WAVE/Z storedTPData = TP_GetStoredTPsFromCycle(str, NaN, 0, 1)
	CHECK_WAVE(storedTPData, NULL_WAVE)

	try
		WAVE/Z storedTPData = TP_GetStoredTPsFromCycle(str, cycleId, NaN, 1)
		FAIL()
	catch
		PASS()
	endtry

	i = 0
	for(headstage : headstages)
		WAVE/Z storedTPData = TP_GetStoredTPsFromCycle(str, cycleId, headstage, 1)
		CHECK_WAVE(storedTPData, WAVE_WAVE)
		CHECK_EQUAL_VAR(DimSize(storedTPData, ROWS), 3)

		WAVE/WAVE   tpData     = storedTPData
		WAVE/WAVE/Z tpADCs     = tpData[0]
		WAVE/WAVE/Z tpDACs     = tpData[1]
		WAVE/WAVE/Z tpInfoWref = tpData[2]

		CHECK_WAVE(tpADCs, WAVE_WAVE)
		CHECK_GE_VAR(DimSize(tpADCs, ROWS), 1)
		CHECK_WAVE(tpDACs, WAVE_WAVE)
		CHECK_GE_VAR(DimSize(tpDACs, ROWS), 1)
		CHECK_WAVE(tpInfoWref, WAVE_WAVE)
		CHECK_EQUAL_VAR(DimSize(tpADCs, ROWS), DimSize(tpInfoWref, ROWS))
		CHECK_EQUAL_VAR(DimSize(tpADCs, ROWS), DimSize(tpDACs, ROWS))

		WAVE tpInfo0 = tpInfoWref[0]
		CHECK_EQUAL_WAVES(tpInfo0, tpResultsRef[i])
		WAVE tpDAC0 = tpDACs[0]
		CHECK_EQUAL_WAVES(tpDAC0, tpDACsRef[i])
		i += 1
	endfor
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function TPDuringDAQwithPS([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                      + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:TestPulse:"      + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

// The general checks are done in test case TPDuringDAQ, this test case only checks the difference when power spectrum is enabled
static Function TPDuringDAQwithPS_REENTRY([str])
	string str

	variable daGain, sweepNo
	variable tpAmp = 0 // tpAmp is zero when power spectrum is enabled

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z stimScale = GetLastSetting(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
	daGain = DAG_GetNumericalValue(str, GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE), index = 0)

	CHECK_EQUAL_WAVES(stimScale, {tpAmp, daGain, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

// UTF_TD_GENERATOR v0:SingleMultiDeviceDAQ
// UTF_TD_GENERATOR s0:DeviceNameGenerator
static Function TPZerosDAC([STRUCT IUTF_MDATA &md])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD" + num2str(md.v0) + "_RA1_I0_L0_BKG1_TP1" + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	AcquireData_NG(s, md.s0)

	CtrlNamedBackGround StopTPAfterFiveSeconds, start=(ticks + TP_DURATION_S * 60), period=1, proc=StopTPAfterFiveSeconds_IGNORE
End

static Function TPZerosDAC_REENTRY([STRUCT IUTF_MDATA &md])

	variable deviceID, hardwareType, sweepNo, index, ADC
	string device

	device = md.s0

	CHECK_EQUAL_VAR(ROVar(GetDataAcqRunMode(device)), DAQ_NOT_RUNNING)
	CHECK_EQUAL_VAR(ROVar(GetTestpulseRunMode(device)), TEST_PULSE_NOT_RUNNING)

	sweepNo = AFH_GetLastSweepAcquired(device)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE numericalValues = GetLBNumericalValues(device)

	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, "ADC", 0, XOP_CHANNEL_TYPE_ADC, TEST_PULSE_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)

	deviceID     = ROVar(GetDAQDeviceID(device))
	hardwareType = GetHardwareType(device)
	ADC          = settings[index]

	CHECK_LE_VAR(HW_ReadADC(hardwareType, deviceID, ADC), 0.01)
End

/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function TestTPPublishing([str])
	string str

	TUFXOP_Clear/Z/N=(ZMQ_FILTER_TPRESULT_1S)
	TUFXOP_Clear/Z/N=(ZMQ_FILTER_TPRESULT_5S)
	TUFXOP_Clear/Z/N=(ZMQ_FILTER_TPRESULT_10S)

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_STP1_TP1"        + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:TestPulse:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:TestPulse:")

	AcquireData_NG(s, str)

	PrepareForPublishTest()

	CtrlNamedBackGround StopTPAfterFiveSeconds, start=(ticks + TP_DURATION_S * 60), period=1, proc=StopTPAfterFiveSeconds_IGNORE
End

static Function TestTPPublishing_REENTRY([str])
	string str
	variable sweepNo, jsonId, var, index, dimMarker, headstage
	string msg, filter, stv, adUnit, daUnit

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WaitAndCheckStoredTPs_IGNORE(str, 2)

	WAVE tpStorage = GetTPStorage(str)
	dimMarker = FindDimLabel(tpStorage, LAYERS, "TPMarker")

	WAVE/T filters = DataGenerators#PUB_TPFilters()
	for(filter : filters)
		msg    = FetchPublishedMessage(filter)
		jsonId = JSON_Parse(msg)

		var = JSON_GetVariable(jsonID, "/properties/tp marker")
		CHECK_NEQ_VAR(var, NaN)

		FindValue/RMD=[][0][dimMarker]/V=(var) tpStorage
		ASSERT(V_row >= 0, "Inconsistent TP data")
		index = V_row

		var = JSON_GetVariable(jsonID, "/properties/headstage")
		CHECK_GE_VAR(var, 0)
		CHECK_LE_VAR(var, 1)
		headstage = var

		stv = JSON_GetString(jsonID, "/properties/device")
		CHECK_EQUAL_STR(stv, str)
		var = JSON_GetVariable(jsonID, "/properties/clamp mode")
		CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%ClampMode])
		daUnit = GetDAChannelUnit(var)
		adUnit = GetADChannelUnit(var)

		var = JSON_GetVariable(jsonID, "/properties/time of tp acquisition/value")
		CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%TimeInSeconds])
		stv = JSON_GetString(jsonID, "/properties/time of tp acquisition/unit")
		CHECK_EQUAL_STR(stv, "s")
		var = JSON_GetVariable(jsonID, "/properties/clamp amplitude/value")
		CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%CLAMPAMP])
		stv = JSON_GetString(jsonID, "/properties/clamp amplitude/unit")
		CHECK_EQUAL_STR(stv, daUnit)
		var = JSON_GetVariable(jsonID, "/properties/tp length ADC/value")
		CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%TPLENGTHPOINTSADC])
		stv = JSON_GetString(jsonID, "/properties/tp length ADC/unit")
		CHECK_EQUAL_STR(stv, "points")
		var = JSON_GetVariable(jsonID, "/properties/pulse duration ADC/value")
		CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%PULSELENGTHPOINTSADC])
		stv = JSON_GetString(jsonID, "/properties/pulse duration ADC/unit")
		CHECK_EQUAL_STR(stv, "points")
		var = JSON_GetVariable(jsonID, "/properties/pulse start point ADC/value")
		CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%PULSESTARTPOINTSADC])
		stv = JSON_GetString(jsonID, "/properties/pulse start point ADC/unit")
		CHECK_EQUAL_STR(stv, "point")
		var = JSON_GetVariable(jsonID, "/properties/sample interval ADC/value")
		CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%SAMPLINGINTERVALADC])
		stv = JSON_GetString(jsonID, "/properties/sample interval ADC/unit")
		CHECK_EQUAL_STR(stv, "ms")
		var = JSON_GetVariable(jsonID, "/properties/tp length DAC/value")
		CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%TPLENGTHPOINTSDAC])
		stv = JSON_GetString(jsonID, "/properties/tp length DAC/unit")
		CHECK_EQUAL_STR(stv, "points")
		var = JSON_GetVariable(jsonID, "/properties/pulse duration DAC/value")
		CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%PULSELENGTHPOINTSDAC])
		stv = JSON_GetString(jsonID, "/properties/pulse duration DAC/unit")
		CHECK_EQUAL_STR(stv, "points")
		var = JSON_GetVariable(jsonID, "/properties/pulse start point DAC/value")
		CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%PULSESTARTPOINTSDAC])
		stv = JSON_GetString(jsonID, "/properties/pulse start point DAC/unit")
		CHECK_EQUAL_STR(stv, "point")
		var = JSON_GetVariable(jsonID, "/properties/sample interval DAC/value")
		CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%SAMPLINGINTERVALDAC])
		stv = JSON_GetString(jsonID, "/properties/sample interval DAC/unit")
		CHECK_EQUAL_STR(stv, "ms")
		var = JSON_GetVariable(jsonID, "/properties/baseline fraction/value")
		CHECK_EQUAL_VAR(var, 35)
		stv = JSON_GetString(jsonID, "/properties/baseline fraction/unit")
		CHECK_EQUAL_STR(stv, "%")
		var = JSON_GetVariable(jsonID, "/properties/timestamp/value")
		CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%TimeStamp])
		stv = JSON_GetString(jsonID, "/properties/timestamp/unit")
		CHECK_EQUAL_STR(stv, "s")
		var = JSON_GetVariable(jsonID, "/properties/timestampUTC/value")
		CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%TimeStampSinceIgorEpochUTC])
		stv = JSON_GetString(jsonID, "/properties/timestampUTC/unit")
		CHECK_EQUAL_STR(stv, "s")

		var = JSON_GetVariable(jsonID, "/properties/tp cycle id")
		CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%TPCycleID])

		var = JSON_GetVariable(jsonID, "/results/average baseline steady state/value")
		if(tpStorage[index][headstage][%ClampMode] == V_CLAMP_MODE)
			CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%Baseline_VC])
		else
			CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%Baseline_IC])
		endif
		stv = JSON_GetString(jsonID, "/results/average baseline steady state/unit")
		CHECK_EQUAL_STR(stv, adUnit)
		var = JSON_GetVariable(jsonID, "/results/average tp steady state/value")
		CHECK_NEQ_VAR(var, NaN)
		stv = JSON_GetString(jsonID, "/results/average tp steady state/unit")
		CHECK_EQUAL_STR(stv, adUnit)
		var = JSON_GetVariable(jsonID, "/results/instantaneous/value")
		CHECK_NEQ_VAR(var, NaN)
		stv = JSON_GetString(jsonID, "/results/instantaneous/unit")
		CHECK_EQUAL_STR(stv, adUnit)
		var = JSON_GetVariable(jsonID, "/results/steady state resistance/value")
		CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%SteadyStateResistance])
		stv = JSON_GetString(jsonID, "/results/steady state resistance/unit")
		CHECK_EQUAL_STR(stv, "MΩ")
		var = JSON_GetVariable(jsonID, "/results/instantaneous resistance/value")
		CHECK_EQUAL_VAR(var, tpStorage[index][headstage][%PeakResistance])
		stv = JSON_GetString(jsonID, "/results/instantaneous resistance/unit")
		CHECK_EQUAL_STR(stv, "MΩ")
	endfor
End
