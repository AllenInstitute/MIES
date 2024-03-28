#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=PatchSeqTestDAScaleSub

// This file also holds the test for the baseline evaluation for all PSQ analysis functions

static Function [STRUCT DAQSettings s] PS_GetDAQSettings(string device)

	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_DB1"                                                       + \
	                             "__HS" + num2str(PSQ_TEST_HEADSTAGE) + "_DA0_AD0_CM:IC:_ST:PSQ_DaScale_Sub_DA_0:")

	AdjustAnalysisParamsForPSQ(device, "PSQ_DaScale_Sub_DA_0")

	return [s]
End

static Function GlobalPreAcq(string device)
	variable ret

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = 70)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = 25)
End

static Function GlobalPreInit(string device)

	PrepareForPublishTest()

	// Ensure that PSQ_DS_GetDAScaleOffset already sees the test override as enabled
	ResetOverrideResults()
End

static Function/WAVE GetLBNEntries_IGNORE(device, sweepNo, name, [chunk])
	string device
	variable sweepNo, chunk
	string name

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	if(ParamIsDefault(chunk))
		key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, name, query = 1)
	else
		key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, name, query = 1, chunk = chunk)
	endif

	strswitch(name)
		case PSQ_FMT_LBN_SET_PASS:
			Make/D/N=1/FREE val = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
			return val
		case PSQ_FMT_LBN_SWEEP_PASS:
		case PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS:
		case PSQ_FMT_LBN_CHUNK_PASS:
		case PSQ_FMT_LBN_SAMPLING_PASS:
		case PSQ_FMT_LBN_ASYNC_PASS:
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
			break
		case PSQ_FMT_LBN_DA_OPMODE:
			return GetLastSettingTextIndepEachSCI(numericalValues, textualValues, sweepNo, PSQ_TEST_HEADSTAGE, key, UNKNOWN_MODE)
			break
		case PSQ_FMT_LBN_BL_QC_PASS:
		case PSQ_FMT_LBN_DA_fI_SLOPE:
		case PSQ_FMT_LBN_PULSE_DUR:
		case PSQ_FMT_LBN_RMS_LONG_PASS:
		case PSQ_FMT_LBN_RMS_SHORT_PASS:
		case PSQ_FMT_LBN_SPIKE_DETECT:
		case PSQ_FMT_LBN_SPIKE_COUNT:
		case PSQ_FMT_LBN_TARGETV_PASS:
		case PSQ_FMT_LBN_TARGETV:
		case PSQ_FMT_LBN_LEAKCUR:
		case PSQ_FMT_LBN_LEAKCUR_PASS:
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
			break
		case PSQ_FMT_LBN_RMS_SHORT_THRESHOLD:
		case PSQ_FMT_LBN_RMS_LONG_THRESHOLD:
		case PSQ_FMT_LBN_TARGETV_THRESHOLD:
			WAVE/Z values = GetLastSettingSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
			if(!WaveExists(values))
				return $""
			endif

			Make/D/N=1/FREE val = {values[PSQ_TEST_HEADSTAGE]}

			return val
			break
		case LBN_DELTA_I:
		case LBN_DELTA_V:
		case LBN_RESISTANCE_FIT:
		case LBN_RESISTANCE_FIT_ERR:
			return GetLastSettingEachSCI(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + name, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
			break
		case STIMSET_SCALE_FACTOR_KEY:
			return GetLastSettingEachRAC(numericalValues, sweepNo, name, PSQ_TEST_HEADSTAGE, DATA_ACQUISITION_MODE)
			break
		default:
			FAIL()
	endswitch
End

static Function PS_DS_Sub1_preAcq(string device)
	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Sub1([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUB)
	// all tests fail
	wv = 0
End

static Function PS_DS_Sub1_REENTRY([str])
	string str

	variable sweepNo, numEntries

	sweepNo = 4

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SET_PASS)
	CHECK_EQUAL_WAVES(setPassed, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z samplingPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	CHECK_EQUAL_WAVES(samplingPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)
	CHECK_EQUAL_WAVES(asyncPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineTargetVThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineTargetVThreshold, {PSQ_TARGETV_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	// we only test-override chunk passed, so for the others we can just check if they exist or not

	// chunk 0
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSLongPassed, NULL_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 0)
	CHECK_WAVE(baselineTargetVPassed, NULL_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 0)
	CHECK_WAVE(targetV, NULL_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 0)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 0)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 1 does not exist
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 1)
	CHECK_WAVE(baselineChunkPassed, NULL_WAVE)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSShortPassed, NULL_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSLongPassed, NULL_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 1)
	CHECK_WAVE(baselineTargetVPassed, NULL_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 1)
	CHECK_WAVE(targetV, NULL_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 1)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 1)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000, 1000, 1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_I)
	CHECK_WAVE(deltaI, NULL_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_V)
	CHECK_WAVE(deltaV, NULL_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT)
	CHECK_WAVE(resistance, NULL_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT_ERR)
	CHECK_WAVE(resistanceErr, NULL_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	Make/FREE/D/N=(numEntries) stimScaleRef = -30

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520})
End

static Function PS_DS_Sub2_preAcq(string device)
	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Sub2([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUB)
	// only pre pulse chunk pass, async QC passes, others fail
	wv[]      = 0
	wv[0][]   = 1
	wv[][][3] = 1
End

static Function PS_DS_Sub2_REENTRY([str])
	string str

	variable sweepNo, numEntries

	sweepNo = 4

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SET_PASS)
	CHECK_EQUAL_WAVES(setPassed, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z samplingPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	CHECK_EQUAL_WAVES(samplingPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)
	CHECK_EQUAL_WAVES(asyncPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineTargetVThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineTargetVThreshold, {PSQ_TARGETV_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	// we only test-override chunk passed, so for the others we can just check if they exist or not

	// chunk 0
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 0)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 0)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	// chunk 1
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 1)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 1)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 1)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 1)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 1)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 2
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 2)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 2)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 2)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 2)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 2)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 2)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 2)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 3
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 3)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 3)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 3)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 3)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 3)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 3)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 3)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 4 does not exist
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 4)
	CHECK_WAVE(baselineChunkPassed, NULL_WAVE)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 4)
	CHECK_WAVE(baselineRMSShortPassed, NULL_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 4)
	CHECK_WAVE(baselineRMSLongPassed, NULL_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 4)
	CHECK_WAVE(baselineTargetVPassed, NULL_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 4)
	CHECK_WAVE(targetV, NULL_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 4)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 4)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000, 1000, 1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	Make/FREE/D/N=(numEntries) stimScaleRef = -30

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520, 2520, 3020, 3020, 3520})
End

static Function PS_DS_Sub3_preAcq(string device)
	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Sub3([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUB)
	// pre pulse chunk pass
	// first post pulse chunk pass
	// async QC passes
	wv[]       = 0
	wv[0, 1][] = 1
	wv[][][3]  = 1
End

static Function PS_DS_Sub3_REENTRY([str])
	string str

	variable sweepNo, numEntries

	sweepNo = 4

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SET_PASS)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z samplingPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	CHECK_EQUAL_WAVES(samplingPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)
	CHECK_EQUAL_WAVES(asyncPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineTargetVThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineTargetVThreshold, {PSQ_TARGETV_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	// we only test-override chunk passed, so for the others we can just check if they exist or not

	// chunk 0
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 0)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 0)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineLeakCurPassed, {-1, -1, -1, -1, -1}, mode = WAVE_DATA)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 0)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 1
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 1)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 1)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 1)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 1)
	CHECK_EQUAL_WAVES(baselineLeakCurPassed, {-1, -1, -1, -1, -1}, mode = WAVE_DATA)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 1)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 2 does not exist
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 2)
	CHECK_WAVE(baselineChunkPassed, NULL_WAVE)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 2)
	CHECK_WAVE(baselineRMSShortPassed, NULL_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 2)
	CHECK_WAVE(baselineRMSLongPassed, NULL_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 2)
	CHECK_WAVE(baselineTargetVPassed, NULL_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 2)
	CHECK_WAVE(targetV, NULL_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 2)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 2)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000, 1000, 1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_I)
	CHECK_WAVE(deltaI, NUMERIC_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_V)
	CHECK_WAVE(deltaV, NUMERIC_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT)
	CHECK_WAVE(resistance, NUMERIC_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT_ERR)
	CHECK_WAVE(resistanceErr, NUMERIC_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -50, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), 4)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End

static Function PS_DS_Sub4_preAcq(string device)
	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Sub4([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUB)
	// pre pulse chunk pass
	// last post pulse chunk pass
	// async QC passes
	wv[]                        = 0
	wv[0][]                     = 1
	wv[DimSize(wv, ROWS) - 1][] = 1
	wv[][][3]                   = 1
End

static Function PS_DS_Sub4_REENTRY([str])
	string str

	variable sweepNo, numEntries

	sweepNo = 4

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SET_PASS)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z samplingPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	CHECK_EQUAL_WAVES(samplingPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)
	CHECK_EQUAL_WAVES(asyncPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineTargetVThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineTargetVThreshold, {PSQ_TARGETV_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	// we only test-override chunk passed, so for the others we can just check if they exist or not

	// chunk 0
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 0)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 0)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineLeakCurPassed, {-1, -1, -1, -1, -1}, mode = WAVE_DATA)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 0)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 1
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 1)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 1)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 1)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 1)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 1)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 2
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 2)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 2)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 2)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 2)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 2)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 2)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 2)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 3
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 3)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 3)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 3)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 3)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 3)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 3)
	CHECK_EQUAL_WAVES(baselineLeakCurPassed, {-1, -1, -1, -1, -1}, mode = WAVE_DATA)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 3)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 4 does not exist
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 4)
	CHECK_WAVE(baselineChunkPassed, NULL_WAVE)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 4)
	CHECK_WAVE(baselineRMSShortPassed, NULL_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 4)
	CHECK_WAVE(baselineRMSLongPassed, NULL_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 4)
	CHECK_WAVE(baselineTargetVPassed, NULL_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 4)
	CHECK_WAVE(targetV, NULL_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 4)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 4)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000, 1000, 1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_I)
	CHECK_WAVE(deltaI, NUMERIC_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_V)
	CHECK_WAVE(deltaV, NUMERIC_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT)
	CHECK_WAVE(resistance, NUMERIC_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT_ERR)
	CHECK_WAVE(resistanceErr, NUMERIC_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -50, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), 4)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520, 2520, 3020, 3020, 3520})
End

static Function PS_DS_Sub5_preAcq(string device)
	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Sub5([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUB)
	// pre pulse chunk fails
	// all post pulse chunk pass
	// async QC passes
	wv[]      = 1
	wv[0][]   = 0
	wv[][][3] = 1
End

static Function PS_DS_Sub5_REENTRY([str])
	string str

	variable sweepNo, numEntries

	sweepNo = 4

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SET_PASS)
	CHECK_EQUAL_WAVES(setPassed, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z samplingPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	CHECK_EQUAL_WAVES(samplingPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)
	CHECK_EQUAL_WAVES(asyncPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineTargetVThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineTargetVThreshold, {PSQ_TARGETV_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	// we only test-override chunk passed, so for the others we can just check if they exist or not

	// chunk 0
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSLongPassed, NULL_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 0)
	CHECK_WAVE(baselineTargetVPassed, NULL_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 0)
	CHECK_WAVE(targetV, NULL_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 0)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 0)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 1 does not exist due to early abort
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 1)
	CHECK_WAVE(baselineChunkPassed, NULL_WAVE)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSShortPassed, NULL_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSLongPassed, NULL_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 1)
	CHECK_WAVE(baselineTargetVPassed, NULL_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 1)
	CHECK_WAVE(targetV, NULL_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 1)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 1)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000, 1000, 1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_I)
	CHECK_WAVE(deltaI, NULL_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_V)
	CHECK_WAVE(deltaV, NULL_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT)
	CHECK_WAVE(resistance, NULL_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT_ERR)
	CHECK_WAVE(resistanceErr, NULL_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	Make/FREE/D/N=(numEntries) stimScaleRef = -30

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520})
End

static Function PS_DS_Sub5a_preAcq(string device)
	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Sub5a([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUB)
	// pre pulse chunk fails due to targetV
	// all post pulse chunk pass
	// async QC passes
	wv[]          = 1
	wv[0][][0][2] = 0
	wv[][][3]     = 1
End

static Function PS_DS_Sub5a_REENTRY([str])
	string str

	variable sweepNo, numEntries

	sweepNo = 4

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SET_PASS)
	CHECK_EQUAL_WAVES(setPassed, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z samplingPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	CHECK_EQUAL_WAVES(samplingPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)
	CHECK_EQUAL_WAVES(asyncPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineTargetVThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineTargetVThreshold, {PSQ_TARGETV_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	// we only test-override chunk passed, so for the others we can just check if they exist or not

	// chunk 0
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineRMSShortPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineRMSLongPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineTargetVPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 0)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 0)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 0)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 1 does not exist due to early abort
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 1)
	CHECK_WAVE(baselineChunkPassed, NULL_WAVE)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSShortPassed, NULL_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSLongPassed, NULL_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 1)
	CHECK_WAVE(baselineTargetVPassed, NULL_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 1)
	CHECK_WAVE(targetV, NULL_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 1)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 1)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000, 1000, 1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_I)
	CHECK_WAVE(deltaI, NULL_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_V)
	CHECK_WAVE(deltaV, NULL_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT)
	CHECK_WAVE(resistance, NULL_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT_ERR)
	CHECK_WAVE(resistanceErr, NULL_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	Make/FREE/D/N=(numEntries) stimScaleRef = -30

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520})
End

static Function PS_DS_Sub6_preAcq(string device)
	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Sub6([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUB)
	// pre pulse chunk pass
	// second post pulse chunk pass
	// async QC passes
	wv[]      = 0
	wv[0][]   = 1
	wv[2][]   = 1
	wv[][][3] = 1
End

static Function PS_DS_Sub6_REENTRY([str])
	string str

	variable sweepNo, numEntries
	string key

	sweepNo = 4

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SET_PASS)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z samplingPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	CHECK_EQUAL_WAVES(samplingPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)
	CHECK_EQUAL_WAVES(asyncPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineTargetVThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineTargetVThreshold, {PSQ_TARGETV_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	// we only test-override chunk passed, so for the others we can just check if they exist or not

	// chunk 0
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 0)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 0)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineLeakCurPassed, {-1, -1, -1, -1, -1}, mode = WAVE_DATA)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 0)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 1
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 1)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 1)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 1)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 1)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 1)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 2
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 2)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 2)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 2)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 2)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 2)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 2)
	CHECK_EQUAL_WAVES(baselineLeakCurPassed, {-1, -1, -1, -1, -1}, mode = WAVE_DATA)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 2)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 3
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 3)
	CHECK_WAVE(baselineChunkPassed, NULL_WAVE)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 3)
	CHECK_WAVE(baselineRMSShortPassed, NULL_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 3)
	CHECK_WAVE(baselineRMSLongPassed, NULL_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 3)
	CHECK_WAVE(baselineTargetVPassed, NULL_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 3)
	CHECK_WAVE(targetV, NULL_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 3)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 3)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 4 does not exist
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 4)
	CHECK_WAVE(baselineChunkPassed, NULL_WAVE)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 4)
	CHECK_WAVE(baselineRMSShortPassed, NULL_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 4)
	CHECK_WAVE(baselineRMSLongPassed, NULL_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 4)
	CHECK_WAVE(baselineTargetVPassed, NULL_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 4)
	CHECK_WAVE(targetV, NULL_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 4)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 4)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000, 1000, 1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_I)
	CHECK_WAVE(deltaI, NUMERIC_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_V)
	CHECK_WAVE(deltaV, NUMERIC_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT)
	CHECK_WAVE(resistance, NUMERIC_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT_ERR)
	CHECK_WAVE(resistanceErr, NUMERIC_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -50, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), 4)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520, 2520, 3020})
End

static Function PS_DS_Sub7_preAcq(string device)
	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Sub7([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUB)
	// pre pulse chunk pass
	// first post pulse chunk pass
	// of sweeps 2-6
	// async QC passes
	wv[]           = 0
	wv[0, 1][2, 6] = 1
	wv[][][3]      = 1
End

static Function PS_DS_Sub7_REENTRY([str])
	string str

	variable sweepNo, numEntries
	string key

	sweepNo = 6

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SET_PASS)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z samplingPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	CHECK_EQUAL_WAVES(samplingPassed, {1, 1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)
	CHECK_EQUAL_WAVES(asyncPassed, {1, 1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineTargetVThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineTargetVThreshold, {PSQ_TARGETV_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	// we only test-override chunk passed, so for the others we can just check if they exist or not

	// chunk 0
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {0, 0, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 0)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 0)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineLeakCurPassed, {NaN, NaN, -1, -1, -1, -1, -1}, mode = WAVE_DATA)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 0)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 1
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 1)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {NaN, NaN, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 1)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 1)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 1)
	CHECK_EQUAL_WAVES(baselineLeakCurPassed, {NaN, NaN, -1, -1, -1, -1, -1}, mode = WAVE_DATA)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 1)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 2 does not exist
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 2)
	CHECK_WAVE(baselineChunkPassed, NULL_WAVE)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 2)
	CHECK_WAVE(baselineRMSShortPassed, NULL_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 2)
	CHECK_WAVE(baselineRMSLongPassed, NULL_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 2)
	CHECK_WAVE(baselineTargetVPassed, NULL_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 2)
	CHECK_WAVE(targetV, NULL_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 2)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 2)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000, 1000, 1000, 1000, 1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_I)
	CHECK_WAVE(deltaI, NUMERIC_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_V)
	CHECK_WAVE(deltaV, NUMERIC_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT)
	CHECK_WAVE(resistance, NUMERIC_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT_ERR)
	CHECK_WAVE(resistanceErr, NUMERIC_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 7)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -30, -30, -50, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), 6)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 2)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 3)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 4)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 5)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 6)
End

static Function PS_DS_Sub8_preAcq(string device)
	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Sub8([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUB)
	// pre pulse chunk pass
	// first post pulse chunk pass
	// of sweep 0, 3, 6, 7 , 8
	// async QC passes
	wv[]        = 0
	wv[0, 1][0] = 1
	wv[0, 1][3] = 1
	wv[0, 1][6] = 1
	wv[0, 1][7] = 1
	wv[0, 1][8] = 1
	wv[][][3]   = 1
End

static Function PS_DS_Sub8_REENTRY([str])
	string str

	variable sweepNo, numEntries
	string key

	sweepNo = 8

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SET_PASS)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 0, 0, 1, 0, 0, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z samplingPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	CHECK_EQUAL_WAVES(samplingPassed, {1, 1, 1, 1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)
	CHECK_EQUAL_WAVES(asyncPassed, {1, 1, 1, 1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineTargetVThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineTargetVThreshold, {PSQ_TARGETV_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	// we only test-override chunk passed, so for the others we can just check if they exist or not

	// chunk 0
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {1, 0, 0, 1, 0, 0, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 0)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 0)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineLeakCurPassed, {-1, NaN, NaN, -1, NaN, NaN, -1, -1, -1}, mode = WAVE_DATA)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 0)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 1
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 1)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {1, NaN, NaN, 1, NaN, NaN, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 1)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 1)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 1)
	CHECK_EQUAL_WAVES(baselineLeakCurPassed, {-1, NaN, NaN, -1, NaN, NaN, -1, -1, -1}, mode = WAVE_DATA)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 1)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 2 does not exist
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 2)
	CHECK_WAVE(baselineChunkPassed, NULL_WAVE)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 2)
	CHECK_WAVE(baselineRMSShortPassed, NULL_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 2)
	CHECK_WAVE(baselineRMSLongPassed, NULL_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 2)
	CHECK_WAVE(baselineTargetVPassed, NULL_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 2)
	CHECK_WAVE(targetV, NULL_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 2)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 2)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_I)
	CHECK_WAVE(deltaI, NUMERIC_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_V)
	CHECK_WAVE(deltaV, NUMERIC_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT)
	CHECK_WAVE(resistance, NUMERIC_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT_ERR)
	CHECK_WAVE(resistanceErr, NUMERIC_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 9)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -50, -50, -50, -70, -70, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), 8)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 2)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 3)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 4)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 5)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 6)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 7)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 8)
End

static Function PS_DS_Sub9_preAcq(device)
	string device

	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "BaselineRMSShortThreshold", var = 0.150)
	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "BaselineRMSLongThreshold", var = 0.250)
	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "baselineTargetVThreshold", var = 0.350)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// Same as PS_DS_Sub1 but with custom RMS short/long and target V thresholds
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Sub9([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUB)
	// all tests fail
	wv = 0
End

static Function PS_DS_Sub9_REENTRY([str])
	string str

	variable sweepNo, numEntries

	sweepNo = 4

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SET_PASS)
	CHECK_EQUAL_WAVES(setPassed, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z samplingPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	CHECK_EQUAL_WAVES(samplingPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)
	CHECK_EQUAL_WAVES(asyncPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {0.150 * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {0.250 * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineTargetVThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineTargetVThreshold, {0.350 * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	// we only test-override chunk passed, so for the others we can just check if they exist or not

	// chunk 0
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSLongPassed, NULL_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 0)
	CHECK_WAVE(baselineTargetVPassed, NULL_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 0)
	CHECK_WAVE(targetV, NULL_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 0)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 0)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 1 does not exist
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 1)
	CHECK_WAVE(baselineChunkPassed, NULL_WAVE)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSShortPassed, NULL_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSLongPassed, NULL_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 1)
	CHECK_WAVE(baselineTargetVPassed, NULL_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 1)
	CHECK_WAVE(targetV, NULL_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 1)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 1)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000, 1000, 1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_I)
	CHECK_WAVE(deltaI, NULL_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_V)
	CHECK_WAVE(deltaV, NULL_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT)
	CHECK_WAVE(resistance, NULL_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT_ERR)
	CHECK_WAVE(resistanceErr, NULL_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	Make/FREE/D/N=(numEntries) stimScaleRef = -30

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
End

static Function PS_DS_Sub10_preAcq(device)
	string device

	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "SamplingFrequency", var = 10)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// Same as PS_DS_Sub3, but with non-matching sampling interval
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Sub10([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUB)
	// pre pulse chunk pass
	// first post pulse chunk pass
	// async QC passes
	wv[]       = 0
	wv[0, 1][] = 1
	wv[][][3]  = 1
End

static Function PS_DS_Sub10_REENTRY([str])
	string str

	variable sweepNo, numEntries

	sweepNo = 0

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SET_PASS)
	CHECK_EQUAL_WAVES(setPassed, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {0}, mode = WAVE_DATA)

	WAVE/Z samplingPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	CHECK_EQUAL_WAVES(samplingPassed, {0}, mode = WAVE_DATA)

	WAVE/Z asyncPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)
	CHECK_EQUAL_WAVES(asyncPassed, {1}, mode = WAVE_DATA)

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {1}, mode = WAVE_DATA)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineTargetVThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineTargetVThreshold, {PSQ_TARGETV_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	// we only test-override chunk passed, so for the others we can just check if they exist or not

	// chunk 0
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {1}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 0)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 0)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 0)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 0)
	CHECK_EQUAL_WAVES(baselineLeakCurPassed, {-1}, mode = WAVE_DATA)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 0)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 1
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 1)
	CHECK_EQUAL_WAVES(baselineChunkPassed, {1}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 1)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 1)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 1)
	CHECK_EQUAL_WAVES(baselineLeakCurPassed, {-1}, mode = WAVE_DATA)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 1)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// chunk 2 does not exist
	WAVE/Z baselineChunkPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 2)
	CHECK_WAVE(baselineChunkPassed, NULL_WAVE)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 2)
	CHECK_WAVE(baselineRMSShortPassed, NULL_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 2)
	CHECK_WAVE(baselineRMSLongPassed, NULL_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 2)
	CHECK_WAVE(baselineTargetVPassed, NULL_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 2)
	CHECK_WAVE(targetV, NULL_WAVE)

	WAVE/Z baselineLeakCurPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 2)
	CHECK_WAVE(baselineLeakCurPassed, NULL_WAVE)

	WAVE/Z leakCur = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_LEAKCUR, chunk = 2)
	CHECK_WAVE(leakCur, NULL_WAVE)

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_I)
	CHECK_WAVE(deltaI, NULL_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, LBN_DELTA_V)
	CHECK_WAVE(deltaV, NULL_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT)
	CHECK_WAVE(resistance, NULL_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, LBN_RESISTANCE_FIT_ERR)
	CHECK_WAVE(resistanceErr, NULL_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 1)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End
