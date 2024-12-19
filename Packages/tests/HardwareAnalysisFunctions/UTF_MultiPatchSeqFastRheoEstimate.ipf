#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=MultiPatchSeqFastRheoEstimate

static Constant INDEP_EACH_SCI = 0x01
static Constant EACH_SCI       = 0x02
static Constant INDEP          = 0x04
static Constant SINGLE_SCI     = 0x08

static Function [STRUCT DAQSettings s] MSQ_GetDAQSettings(string device)

	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_DB1_SIM4"                   + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:MSQ_FastRheoEst_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:MSQ_FastRheoEst_DA_0:")

	return [s]
End

static Function GlobalPreAcq(string device)

	PASS()
End

static Function GlobalPreInit(string device)

	PASS()
End

static Function MSQ_FRE10_PreAcq(string device)
End

static Function/WAVE GetLBNSingleEntry_IGNORE(string device, variable sweepNo, string str, variable headstage, variable mode)

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, str, query = 1)

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
static Function MSQ_FRE1([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = MSQ_CreateOverrideResults(str, 0, MSQ_FAST_RHEO_EST)
	// all tests fail
	wv = 0
End

static Function MSQ_FRE1_REENTRY([string str])

	variable sweepNo
	string   lbl

	sweepNo = 19

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(str, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	CHECK_CLOSE_VAR(DAG_GetNumericalValue(str, lbl, index = 0), 2100)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	CHECK_CLOSE_VAR(DAG_GetNumericalValue(str, lbl, index = 1), 2100)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {0, 0})
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function MSQ_FRE2([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = MSQ_CreateOverrideResults(str, 0, MSQ_FAST_RHEO_EST)
	// all tests fail
	// spike before pulse, does not count
	wv = 2.5
End

static Function MSQ_FRE2_REENTRY([string str])

	variable sweepNo
	string   lbl

	sweepNo = 19

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(str, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_CLOSE_VAR(DAG_GetNumericalValue(str, lbl, index = 0), 2100)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_CLOSE_VAR(DAG_GetNumericalValue(str, lbl, index = 1), 2100)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {0, 0})
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function MSQ_FRE3([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = MSQ_CreateOverrideResults(str, 0, MSQ_FAST_RHEO_EST)
	// spike detected on second sweep, but never again
	wv[]    = 0
	wv[1][] = 1
End

static Function MSQ_FRE3_REENTRY([string str])

	variable sweepNo
	string   lbl

	sweepNo = 19

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, -50, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, -50, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(str, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	CHECK_CLOSE_VAR(DAG_GetNumericalValue(str, lbl, index = 0), 330)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	CHECK_CLOSE_VAR(DAG_GetNumericalValue(str, lbl, index = 1), 330)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {0, 0})
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function MSQ_FRE4([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = MSQ_CreateOverrideResults(str, 0, MSQ_FAST_RHEO_EST)
	// HS0: no spikes
	// HS1: spike on second and fourth sweep
	// -> HS1 passes, but the sweep does not
	wv[]     = 0
	wv[1][1] = 1
	wv[3][1] = 1
End

static Function MSQ_FRE4_REENTRY([string str])

	variable sweepNo
	string   lbl

	sweepNo = 19

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 0, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, -50, 10, 10, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(str, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_CLOSE_VAR(DAG_GetNumericalValue(str, lbl, index = 0), 2100)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, lbl, index = 1), 0)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {0, 0})
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function MSQ_FRE5([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = MSQ_CreateOverrideResults(str, 0, MSQ_FAST_RHEO_EST)

	// HS0: spike on fifth and seventh sweep
	// HS1: spike on second and fourth sweep
	// -> Sweep and Set passes
	wv[]     = 0
	wv[5][0] = 1
	wv[7][0] = 1
	wv[1][1] = 1
	wv[3][1] = 1
End

static Function MSQ_FRE5_REENTRY([string str])

	variable sweepNo
	string   lbl

	sweepNo = 7

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 1, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 1, 0, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 0, 1, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 550, 560}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 160, 0, 0, 0, 0}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, -50, 10, 10}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, -50, 10, 10, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(str, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(finalDAScale, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, 560e-12}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(finalDAScale, {NaN, NaN, NaN, 160e-12, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-14)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, lbl, index = 0), 0)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, lbl, index = 1), 0)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {1, 1})
End

static Function MSQ_FRE6_PreAcq(string device)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(V_CLAMP_MODE, 1), val = 1)
End

// only one IC and one VC headstage
// check that VC is on again in the end
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function MSQ_FRE6([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = MSQ_CreateOverrideResults(str, 0, MSQ_FAST_RHEO_EST)

	// HS0: spike on fifth and seventh sweep
	wv[]     = 0
	wv[5][0] = 1
	wv[7][0] = 1
End

static Function MSQ_FRE6_REENTRY([string str])

	variable sweepNo
	string   lbl

	sweepNo = 7

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_WAVE(sweepPass, NULL_WAVE)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_WAVE(headstagePass, NULL_WAVE)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 1, 0, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_WAVE(spikeDetectionWave, NULL_WAVE)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 550, 560}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_WAVE(stimScale, NULL_WAVE)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, -50, 10, 10}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	CHECK_WAVE(stepsizes, NULL_WAVE)

	WAVE/Z activeHS = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(str, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_WAVE(rangeExceeded, NULL_WAVE)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(finalDAScale, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, 560e-12}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 1, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, lbl, index = 0), 0)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 1, EACH_SCI)
	CHECK_WAVE(oorDAScale, NULL_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, {1, 1})
End

static Function AddAnalysisParamsDAScale_IGNORE(string device)

	AFH_AddAnalysisParameter("MSQ_FastRheoEst_DA_0", "PostDAQDAScale", var = 1)
	AFH_AddAnalysisParameter("MSQ_FastRheoEst_DA_0", "PostDAQDAScaleFactor", var = 1.5)
End

static Function MSQ_FRE7_PreInit(string device)

	AddAnalysisParamsDAScale_IGNORE(device)
End

// one test with PostDAQDAScale and PostDAQDAScaleFactor analysis parameters
// check dascale after DAQ
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function MSQ_FRE7([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = MSQ_CreateOverrideResults(str, 0, MSQ_FAST_RHEO_EST)

	// HS0: spike on fifth and seventh sweep
	// HS1: spike on second and fourth sweep
	// -> Sweep and Set passes
	wv[]     = 0
	wv[5][0] = 1
	wv[7][0] = 1
	wv[1][1] = 1
	wv[3][1] = 1
End

static Function MSQ_FRE7_REENTRY([string str])

	variable sweepNo
	string   lbl

	sweepNo = 7

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 1, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 1, 0, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 0, 1, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 550, 560}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 160, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, -50, 10, 10}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, -50, 10, 10, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(str, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(finalDAScale, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, 560e-12}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(finalDAScale, {NaN, NaN, NaN, 160e-12, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-14)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_CLOSE_VAR(DAG_GetNumericalValue(str, lbl, index = 0), 560 * 1.5)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, lbl, index = 1), 160 * 1.5)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {1, 1})
End

static Function MSQ_FRE8_PreInit(string device)

	AddAnalysisParamsDAScale_IGNORE(device)
End

// one test with PostDAQDAScale and PostDAQDAScaleFactor analysis parameters
// check dascale after DAQ and one headstage failed
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function MSQ_FRE8([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = MSQ_CreateOverrideResults(str, 0, MSQ_FAST_RHEO_EST)

	// HS0: spike on fifth and seventh sweep
	// -> Sweep and Set failed
	wv[]     = 0
	wv[5][0] = 1
	wv[7][0] = 1
End

static Function MSQ_FRE8_REENTRY([string str])

	variable sweepNo
	string   lbl

	sweepNo = 19

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 1, 0, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 550, 560, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, -50, 10, 10, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(str, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(finalDAScale, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, 560e-12, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 1, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_CLOSE_VAR(DAG_GetNumericalValue(str, lbl, index = 0), 560 * 1.5)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, lbl, index = 1), 1250)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {0, 0})
End

static Function MSQ_FRE9_PreInit(string device)

	AFH_AddAnalysisParameter("MSQ_FastRheoEst_DA_0", "MaximumDAScale", var = 205)
End

// one test with range exceeded and MaximumDAScale analysis parameter
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function MSQ_FRE9([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = MSQ_CreateOverrideResults(str, 0, MSQ_FAST_RHEO_EST)

	// all fail
	wv[] = 0
End

static Function MSQ_FRE9_REENTRY([string str])

	variable sweepNo
	string   lbl

	sweepNo = 1

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, 100}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, 100}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(str, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, 1}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, 1}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 1, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, lbl, index = 0), 200)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, lbl, index = 1), 200)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, NaN}, mode = WAVE_DATA)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {0, 0})
End

static Function MSQ_FRE10_PreInit(string device)

	AFH_AddAnalysisParameter("MSQ_FastRheoEst_DA_0", "PostDAQDAScale", var = 1)
	AFH_AddAnalysisParameter("MSQ_FastRheoEst_DA_0", "PostDAQDAScaleMinOffset", var = 100)
	AFH_AddAnalysisParameter("MSQ_FastRheoEst_DA_0", "PostDAQDAScaleFactor", var = 1.5)
End

// Using MinOffset and a scale factor
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function MSQ_FRE10([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = MSQ_CreateOverrideResults(str, 0, MSQ_FAST_RHEO_EST)

	// HS0: spike on fifth and seventh sweep
	// HS1: spike on second and fourth sweep
	// -> Sweep and Set passes
	wv[]     = 0
	wv[5][0] = 1
	wv[7][0] = 1
	wv[1][1] = 1
	wv[3][1] = 1
End

static Function MSQ_FRE10_REENTRY([string str])

	variable sweepNo
	string   lbl

	sweepNo = 7

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 1, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 1, 0, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 0, 1, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 550, 560}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 160, 0, 0, 0, 0}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, -50, 10, 10}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, {100, -50, 10, 10, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(str, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(finalDAScale, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, 560e-12}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(finalDAScale, {NaN, NaN, NaN, 160e-12, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-14)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_CLOSE_VAR(DAG_GetNumericalValue(str, lbl, index = 0), 560 * 1.5)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, lbl, index = 1), 160 + 100)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, {0, 0, 0, 0, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {1, 1})
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function MSQ_FRE11([string str])

	ST_SetStimsetParameter("MSQ_FastRheoEst_DA_0", "Total number of steps", var = 50)

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = MSQ_CreateOverrideResults(str, 0, MSQ_FAST_RHEO_EST)
	// all tests fail
	wv = 0
End

static Function MSQ_FRE11_REENTRY([string str])

	variable sweepNo, numEntries
	string lbl

#ifdef TESTS_WITH_NI_HARDWARE
	sweepNo = 38
#else
	sweepNo = 39
#endif

	numEntries = sweepNo + 1

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {0}, mode = WAVE_DATA)

	Make/FREE/D/N=(numEntries) sweepPassRef = 0

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, sweepPassRef, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, sweepPassRef, mode = WAVE_DATA)

	Make/FREE/D/N=(numEntries) headstagePassRef = 0

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, headstagePassRef, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, headstagePassRef, mode = WAVE_DATA)

	Make/FREE/D/N=(numEntries) spikeDetectionWaveRef = 0

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, spikeDetectionWaveRef, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, spikeDetectionWaveRef, mode = WAVE_DATA)

	Make/FREE/D/N=(numEntries) stimScaleRef = 100 * (p + 1)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-10)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-10)

	Make/FREE/D/N=(numEntries) stepSizesRef = 100

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, stepSizesRef, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= ONE_TO_PICO
	CHECK_EQUAL_WAVES(stepsizes, stepSizesRef, mode = WAVE_DATA)

	WAVE/Z activeHS = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(str, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	Make/FREE/D/N=(numEntries) rangeExceededRef = NaN

	rangeExceededRef[0] = 0

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, rangeExceededRef, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, rangeExceededRef, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	CHECK_CLOSE_VAR(DAG_GetNumericalValue(str, lbl, index = 0), Sum(stepSizesRef))

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	CHECK_CLOSE_VAR(DAG_GetNumericalValue(str, lbl, index = 1), Sum(stepSizesRef))

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z pulseDuration = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	Make/FREE/D/N=(numEntries) oorDAScaleRef = 0

	oorDAScaleRef[numEntries - 1] = 1

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, oorDAScaleRef, mode = WAVE_DATA)

	WAVE/Z oorDAScale = GetLBNSingleEntry_IGNORE(str, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(oorDAScale, oorDAScaleRef, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {0, 0})
End
