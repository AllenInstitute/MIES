#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=PatchSeqTestDAScaleSupra

static Function [STRUCT DAQSettings s] PS_GetDAQSettings(string device, string stimset)

	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_DB1"                                                  + \
	                             "__HS" + num2str(PSQ_TEST_HEADSTAGE) + "_DA0_AD0_CM:IC:_ST:" + stimset + ":")

	AdjustAnalysisParamsForPSQ(device, stimset)

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
		case STIMSET_SCALE_FACTOR_KEY:
			return GetLastSettingEachRAC(numericalValues, sweepNo, name, PSQ_TEST_HEADSTAGE, DATA_ACQUISITION_MODE)
			break
		default:
			FAIL()
	endswitch
End

static Function PS_DS_Supra1_preAcq(string device)
	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PSQ_DaScale_Supr_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// The decision logic *without* FinalSlopePercent is the same as for Sub, only the plotting is different
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Supra1([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str, "PSQ_DaScale_Supr_DA_0")
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUPRA)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv         = 0
	wv[0][][0] = 1
	wv[1][][0] = 1
	// all sweeps spike
	wv[0][][1] = 1
	// increasing number of spikes
	wv[0][][2] = 1 + q
	// async QC passes
	wv[][][3] = 1
End

static Function PS_DS_Supra1_REENTRY([str])
	string str

	variable sweepNo, numEntries
	string key

	sweepNo = 1

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SET_PASS)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1}, mode = WAVE_DATA)

	WAVE/Z samplingPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	CHECK_EQUAL_WAVES(samplingPassed, {1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)
	CHECK_EQUAL_WAVES(asyncPassed, {1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_EQUAL_WAVES(spikeDetection, {1, 1}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_EQUAL_WAVES(spikeCount, {1, 2}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE spikeFreq = GetAnalysisFuncDAScaleSpikeFreq(str, PSQ_TEST_HEADSTAGE)
	CHECK_EQUAL_WAVES(spikeFreq, {1, 2}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_EQUAL_WAVES(fISlope, {0, 5}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUPRA, PSQ_DS_SUPRA}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 2)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	Make/FREE/D/N=(numEntries) stimScaleRef = {PSQ_DS_OFFSETSCALE_FAKE + 20, PSQ_DS_OFFSETSCALE_FAKE + 40}
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End

static Function PS_DS_Supra2_preAcq(string device)
	AFH_AddAnalysisParameter("PSQ_DaScale_Supr_DA_0", "OffsetOperator", str = "*")

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter("PSQ_DaScale_Supr_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// Different to PS_DS_Supra1 is that the second does not spike and a different offset operator
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Supra2([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str, "PSQ_DaScale_Supr_DA_0")
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUPRA)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv         = 0
	wv[0][][0] = 1
	wv[1][][0] = 1
	// Spike and non-spiking
	wv[0][][1] = mod(q, 2) == 0
	// increasing number of spikes
	wv[0][][2] = q + 1
	// async QC passes
	wv[][][3] = 1
End

static Function PS_DS_Supra2_REENTRY([str])
	string str

	variable sweepNo, numEntries

	sweepNo = 1

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SET_PASS)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1}, mode = WAVE_DATA)

	WAVE/Z samplingPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	CHECK_EQUAL_WAVES(samplingPassed, {1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)
	CHECK_EQUAL_WAVES(asyncPassed, {1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_EQUAL_WAVES(spikeDetection, {1, 0}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_EQUAL_WAVES(spikeCount, {1, 0}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE spikeFreq = GetAnalysisFuncDAScaleSpikeFreq(str, PSQ_TEST_HEADSTAGE)
	CHECK_EQUAL_WAVES(spikeFreq, {1, 0}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_EQUAL_WAVES(fISlope, {0, -0.21739}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUPRA, PSQ_DS_SUPRA}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 2)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	Make/FREE/D/N=(numEntries) stimScaleRef = {PSQ_DS_OFFSETSCALE_FAKE * 20, PSQ_DS_OFFSETSCALE_FAKE * 40}
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End

// FinalSlopePercent present but not reached
static Function PS_DS_Supra3_preAcq(device)
	string device

	string stimSet = "PSQ_DS_SupraLong_DA_0"
	AFH_AddAnalysisParameter(stimSet, "FinalSlopePercent", var = 100)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter(stimSet, "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Supra3([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str, "PSQ_DS_SupraLong_DA_0")
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUPRA)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv         = 0
	wv[0][][0] = 1
	wv[1][][0] = 1
	// Spike and non-spiking
	wv[0][][1] = mod(q, 2) == 0
	// increasing number of spikes
	wv[0][][2] = q + 1
	// async QC passes
	wv[][][3] = 1
End

static Function PS_DS_Supra3_REENTRY([str])
	string str

	variable sweepNo, numEntries

	sweepNo = 4

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SET_PASS)
	CHECK_EQUAL_WAVES(setPassed, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z samplingPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	CHECK_EQUAL_WAVES(samplingPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z asyncPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)
	CHECK_EQUAL_WAVES(asyncPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_EQUAL_WAVES(spikeDetection, {1, 0, 1, 0, 1}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_EQUAL_WAVES(spikeCount, {1, 0, 3, 0, 5}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000, 1000, 1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE spikeFreq = GetAnalysisFuncDAScaleSpikeFreq(str, PSQ_TEST_HEADSTAGE)
	CHECK_EQUAL_WAVES(spikeFreq, {1, 0, 3, 0, 5}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_EQUAL_WAVES(fISlope, {0, -5, 5, -1.90e-14, 4}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	Make/FREE/D/N=(numEntries) stimScaleRef = {PSQ_DS_OFFSETSCALE_FAKE + 20, PSQ_DS_OFFSETSCALE_FAKE + 40, PSQ_DS_OFFSETSCALE_FAKE + 60, PSQ_DS_OFFSETSCALE_FAKE + 80, PSQ_DS_OFFSETSCALE_FAKE + 100}
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End

// FinalSlopePercent present and reached
static Function PS_DS_Supra4_preAcq(device)
	string device

	string stimSet = "PSQ_DS_SupraLong_DA_0"
	AFH_AddAnalysisParameter(stimSet, "FinalSlopePercent", var = 60)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter(stimSet, "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Supra4([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str, "PSQ_DS_SupraLong_DA_0")
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUPRA)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv         = 0
	wv[0][][0] = 1
	wv[1][][0] = 1
	// Spike and non-spiking
	wv[0][][1] = mod(q, 2) == 0
	// increasing number of spikes
	wv[0][][2] = q^3 + 1
	// async QC passes
	wv[][][3] = 1
End

static Function PS_DS_Supra4_REENTRY([str])
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

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_EQUAL_WAVES(spikeDetection, {1, 0, 1, 0, 1}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_EQUAL_WAVES(spikeCount, {1, 0, 9, 0, 65}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000, 1000, 1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE spikeFreq = GetAnalysisFuncDAScaleSpikeFreq(str, PSQ_TEST_HEADSTAGE)
	CHECK_EQUAL_WAVES(spikeFreq, {1, 0, 9, 0, 65}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_EQUAL_WAVES(fISlope, {0, -5, 20, 3, 64}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	Make/FREE/D/N=(numEntries) stimScaleRef = {PSQ_DS_OFFSETSCALE_FAKE + 20, PSQ_DS_OFFSETSCALE_FAKE + 40, PSQ_DS_OFFSETSCALE_FAKE + 60, PSQ_DS_OFFSETSCALE_FAKE + 80, PSQ_DS_OFFSETSCALE_FAKE + 100}
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End

static Constant DAScaleModifierPerc = 25

// MinimumSpikeCount, MaximumSpikeCount, DAScaleModifier present
static Function PS_DS_Supra5_preAcq(device)
	string device

	string stimSet = "PSQ_DS_SupraLong_DA_0"
	AFH_AddAnalysisParameter(stimSet, "MinimumSpikeCount", var = 3)
	AFH_AddAnalysisParameter(stimSet, "MaximumSpikeCount", var = 6)
	AFH_AddAnalysisParameter(stimSet, "DAScaleModifier", var = DAScaleModifierPerc)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter(stimSet, "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Supra5([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str, "PSQ_DS_SupraLong_DA_0")
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUPRA)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv         = 0
	wv[0][][0] = 1
	wv[1][][0] = 1
	// Spiking
	wv[0][][1] = 1
	// increasing number of spikes
	wv[0][][2] = q^2 + 1
	// async QC passes
	wv[][][3] = 1
End

static Function PS_DS_Supra5_REENTRY([str])
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

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_EQUAL_WAVES(spikeDetection, {1, 1, 1, 1, 1}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_EQUAL_WAVES(spikeCount, {1, 2, 5, 10, 17}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000, 1000, 1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z spikeFreq = GetAnalysisFuncDAScaleSpikeFreq(str, PSQ_TEST_HEADSTAGE)
	CHECK_EQUAL_WAVES(spikeFreq, {1, 2, 5, 10, 17}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_EQUAL_WAVES(fISlope, {0, 3.33333333333334, 7.14285714285714, 12.4517906336088, 18.4313725490196}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)

	Make/FREE/D/N=(numEntries) stimScaleRef = {20 + PSQ_DS_OFFSETSCALE_FAKE,                                              \
	                                           40 * (1 + DAScaleModifierPerc * PERCENT_TO_ONE) + PSQ_DS_OFFSETSCALE_FAKE, \
	                                           60 * (1 + DAScaleModifierPerc * PERCENT_TO_ONE) + PSQ_DS_OFFSETSCALE_FAKE, \
	                                           80 + PSQ_DS_OFFSETSCALE_FAKE,                                              \
	                                           100 * (1 - DAScaleModifierPerc * PERCENT_TO_ONE) + PSQ_DS_OFFSETSCALE_FAKE}

	// Explanations for the stimscale:
	// 1. initial
	// 2. last below min
	// 3. last below min again
	// 4. last inside
	// 5. last above
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End

// MinimumSpikeCount, MaximumSpikeCount, DAScaleModifier present
// async QC fails
static Function PS_DS_Supra6_preAcq(device)
	string device

	string stimSet = "PSQ_DS_SupraLong_DA_0"
	AFH_AddAnalysisParameter(stimSet, "MinimumSpikeCount", var = 3)
	AFH_AddAnalysisParameter(stimSet, "MaximumSpikeCount", var = 6)
	AFH_AddAnalysisParameter(stimSet, "DAScaleModifier", var = DAScaleModifierPerc)

	Make/FREE asyncChannels = {2, 3}
	AFH_AddAnalysisParameter(stimSet, "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_Supra6([str])
	string str

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str, "PSQ_DS_SupraLong_DA_0")
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_SUPRA)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv         = 0
	wv[0][][0] = 1
	wv[1][][0] = 1
	// no spikes
	wv[0][][1] = 0
	// async QC fails
	wv[][][3] = 0
End

static Function PS_DS_Supra6_REENTRY([str])
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

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000, 1000, 1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z spikeFreq = GetAnalysisFuncDAScaleSpikeFreq(str, PSQ_TEST_HEADSTAGE)
	Make/D/FREE/N=0 spikeFreqRef
	CHECK_EQUAL_WAVES(spikeFreq, spikeFreqRef, mode = WAVE_DATA)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	WAVE/Z stimScale = GetLBNEntries_IGNORE(str, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	CHECK_EQUAL_WAVES(stimScale, {43, 43, 43, 43, 43}, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScale(str, PSQ_TEST_HEADSTAGE, PSQ_DS_SUB), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End
