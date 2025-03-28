#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=MultiPatchSeqSpikeControl

static Constant INDEP_EACH_SCI   = 0x01
static Constant EACH_SCI         = 0x02
static Constant INDEP            = 0x04
static Constant SINGLE_SCI       = 0x08
static Constant INDEP_SINGLE_SCI = 0x10

static Function [STRUCT DAQSettings s] MSQ_GetDAQSettings(string device)

	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_DB1"                        + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:SC_SpikeControl_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:SC_SpikeControl_DA_0:")

	return [s]
End

static Function GlobalPreAcq(string device)

	PASS()
End

static Function GlobalPreInit(string device)

	PASS()
End

static Function/WAVE GetLBNSingleEntry_IGNORE(string device, variable sweepNo, string str, variable headstage, variable mode, [variable textualEntry])

	string key

	if(ParamIsDefault(textualEntry))
		textualEntry = 0
	else
		textualEntry = !!textualEntry
	endif

	WAVE   numericalValues = GetLBNumericalValues(device)
	WAVE/T textualValues   = GetLBTextualValues(device)

	key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, str, query = 1)

	switch(mode)
		case INDEP_EACH_SCI:
			if(textualEntry)
				return GetLastSettingTextIndepEachSCI(numericalValues, textualValues, sweepNo, headstage, key, UNKNOWN_MODE)
			endif

			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
		case EACH_SCI:
			if(textualEntry)
				return GetLastSettingTextEachSCI(numericalValues, textualValues, sweepNo, key, headstage, UNKNOWN_MODE)
			endif

			return GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
		case INDEP:
			CHECK_EQUAL_VAR(numtype(headstage), 2)
			if(textualEntry)
				Make/T/N=1/FREE valText = GetLastSettingTextIndep(textualValues, sweepNo, key, UNKNOWN_MODE)
				return valText
			endif

			Make/D/N=1/FREE val = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
			return val
		case SINGLE_SCI:
			return GetLastSettingSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
		case INDEP_SINGLE_SCI:
			Make/D/N=1/FREE val = GetLastSettingIndepSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
			return val
		default:
			INFO("Invalid mode %g", n0 = mode)
			FAIL()
	endswitch
End

static Function/WAVE GetLBNEntriesWave_IGNORE()

	string list = "sweepPass;setPass;failedPulseLevel;idealSpikeCounts;"                                                               \
	              + "setSweepCount_HS0;setSweepCount_HS1;"                                                                             \
	              + "headstagePass_HS0;headstagePass_HS1;stimScale_HS0;stimScale_HS1;"                                                 \
	              + "rerunTrials_HS0;rerunTrials_HS1;rerunTrialsExceeded_HS0;rerunTrialsExceeded_HS1;"                                 \
	              + "spikeCounts_HS0;spikeCounts_HS1;spikeCountsState_HS0;spikeCountsState_HS1;"                                       \
	              + "spikePositions_HS0;spikePositions_HS1;spikePositionQC_HS0;spikePositionQC_HS1;spontSpikeQC_HS0;spontSpikeQC_HS1;" \
	              + "autoBiasV_HS0;autoBiasV_HS1;DAScaleOutOfRange_HS0;DAScaleOutOfRange_HS1;"

	Make/FREE/WAVE/N=(ItemsInList(list)) wv
	SetDimensionLabels(wv, list, ROWS)

	return wv
End

// @todo use functions like this one here for all future analysis function tests
// as that ensure that we don't forget anything and avoid code duplication
static Function/WAVE GetLBNEntries_IGNORE(string device, variable sweepNo)

	WAVE numericalValues = GetLBNumericalValues(device)

	WAVE/WAVE wv = GetLBNEntriesWave_IGNORE()

	wv[%sweepPass]        = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	wv[%setPass]          = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	wv[%failedPulseLevel] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_FAILED_PULSE_LEVEL, 0, INDEP_SINGLE_SCI)
	wv[%idealSpikeCounts] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_IDEAL_SPIKE_COUNTS, 0, INDEP_SINGLE_SCI)

	wv[%headstagePass_HS0] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	wv[%headstagePass_HS1] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)

	wv[%setSweepCount_HS0] = GetLastSettingEachSCI(numericalValues, sweepNo, "Set Sweep Count", 0, DATA_ACQUISITION_MODE)
	wv[%setSweepCount_HS1] = GetLastSettingEachSCI(numericalValues, sweepNo, "Set Sweep Count", 1, DATA_ACQUISITION_MODE)

	wv[%rerunTrials_HS0] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_RERUN_TRIAL, 0, EACH_SCI)
	wv[%rerunTrials_HS1] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_RERUN_TRIAL, 1, EACH_SCI)

	wv[%rerunTrialsExceeded_HS0] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_RERUN_TRIAL_EXC, 0, EACH_SCI)
	wv[%rerunTrialsExceeded_HS1] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_RERUN_TRIAL_EXC, 1, EACH_SCI)

	wv[%spikeCounts_HS0] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_SPIKE_COUNTS, 0, EACH_SCI, textualEntry = 1)
	wv[%spikeCounts_HS1] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_SPIKE_COUNTS, 1, EACH_SCI, textualEntry = 1)

	wv[%spikeCountsState_HS0] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_SPIKE_COUNTS_STATE, 0, EACH_SCI, textualEntry = 1)
	wv[%spikeCountsState_HS1] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_SPIKE_COUNTS_STATE, 1, EACH_SCI, textualEntry = 1)

	wv[%spikePositionQC_HS0] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_SPIKE_POSITION_PASS, 0, EACH_SCI)
	wv[%spikePositionQC_HS1] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_SPIKE_POSITION_PASS, 1, EACH_SCI)

	wv[%spikePositions_HS0] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_SPIKE_POSITIONS, 0, EACH_SCI, textualEntry = 1)
	wv[%spikePositions_HS1] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_SPIKE_POSITIONs, 1, EACH_SCI, textualEntry = 1)

	wv[%spontSpikeQC_HS0] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_SPONT_SPIKE_PASS, 0, EACH_SCI)
	wv[%spontSpikeQC_HS1] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_SPONT_SPIKE_PASS, 1, EACH_SCI)

	wv[%stimScale_HS0] = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	wv[%stimScale_HS1] = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)

	wv[%autoBiasV_HS0] = GetLastSettingEachSCI(numericalValues, sweepNo, "Autobias Vcom", 0, DATA_ACQUISITION_MODE)
	wv[%autoBiasV_HS1] = GetLastSettingEachSCI(numericalValues, sweepNo, "Autobias Vcom", 1, DATA_ACQUISITION_MODE)

	wv[%DAScaleOutOfRange_HS0] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 0, EACH_SCI)
	wv[%DAScaleOutOfRange_HS1] = GetLBNSingleEntry_IGNORE(device, sweepNo, MSQ_FMT_LBN_DASCALE_OOR, 1, EACH_SCI)

	return wv
End

// UTF_TD_GENERATOR SpikeCountsStateValues
static Function TestSpikeCounts([WAVE vals])

	CHECK_EQUAL_VAR(MIES_SC#SC_SpikeCountsCalcDetail(vals[%minimum], vals[%maximum], vals[%idealNumber]), vals[%expectedState])
End

static Function SC_Test1_preInit(string device)

	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleModifier", var = 1.5)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleOperator", str = "+")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MaxTrials", var = 2)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionModifier", var = 2.5)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionOperator", str = "+")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MinimumSpikePosition", var = 50)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "AutoBiasBaselineModifier", var = 10)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "FailedPulseLevel", var = 1)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "IdealNumberOfSpikesPerPulse", var = 1)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_Test1([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE/T wv = MSQ_CreateOverrideResults(str, 0, SC_SPIKE_CONTROL)

	// no spikes each for each pulse (1 requested)
	//
	// [sweep][headstage][pulse][region]
	wv[][][0][0, 1] += ""
	wv[][][][]      += "SpontaneousSpikeMax:0.5"
End

static Function SC_Test1_REENTRY([string str])

	variable sweepNo, autobiasV
	string lbl, failedPulses, spikeCounts

	sweepNo = 3

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%idealSpikeCounts], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%failedPulseLevel], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS0], {0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS1], {0, 0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS0], {0, 0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS1], {0, 0, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS0], {0, 1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS1], {0, 1, 0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS0], {0, 1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS1], {0, 1, 0, 1}, mode = WAVE_DATA)

	spikeCounts = "P0_R0:0,;P1_R0:0,;P2_R0:0,;P3_R0:0,;P4_R0:0,;P5_R0:0,;P6_R0:0,;P7_R0:0,;P8_R0:0,;P9_R0:0,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS0], {spikeCounts, spikeCounts, spikeCounts, spikeCounts}, mode = WAVE_DATA)

	spikeCounts = "P0_R1:0,;P1_R1:0,;P2_R1:0,;P3_R1:0,;P4_R1:0,;P5_R1:0,;P6_R1:0,;P7_R1:0,;P8_R1:0,;P9_R1:0,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS1], {spikeCounts, spikeCounts, spikeCounts, spikeCounts}, mode = WAVE_DATA)

	CHECK_WAVE(lbnEntries[%spikePositions_HS0], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%spikePositions_HS1], NULL_WAVE)

	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS0], {SC_SPIKE_COUNT_STATE_STR_TOO_FEW, SC_SPIKE_COUNT_STATE_STR_TOO_FEW, SC_SPIKE_COUNT_STATE_STR_TOO_FEW, SC_SPIKE_COUNT_STATE_STR_TOO_FEW}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS1], {SC_SPIKE_COUNT_STATE_STR_TOO_FEW, SC_SPIKE_COUNT_STATE_STR_TOO_FEW, SC_SPIKE_COUNT_STATE_STR_TOO_FEW, SC_SPIKE_COUNT_STATE_STR_TOO_FEW}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS0], {0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS1], {0, 0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS0], {1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS1], {1, 1, 1, 1}, mode = WAVE_DATA)

	// all pulses fail, so we always add 1.5 at each step
	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS0], {1, 2.5, 4, 5.5}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS1], {1, 2.5, 4, 5.5}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS0], {0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS1], {0, 0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%DAScaleOutOfRange_HS0], {0, 0, 0, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScaleOutOfRange_HS1], {0, 0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {0, 0})
End

static Function SC_Test2_preInit(string device)

	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleModifier", var = 1.5)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleOperator", str = "+")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MaxTrials", var = 2)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionModifier", var = 2.5)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionOperator", str = "+")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MinimumSpikePosition", var = 50)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "AutoBiasBaselineModifier", var = 10)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "FailedPulseLevel", var = 1)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "IdealNumberOfSpikesPerPulse", var = 1)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_Test2([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE/T wv = MSQ_CreateOverrideResults(str, 0, SC_SPIKE_CONTROL)

	// one spike each for each pulse (1 requested)
	// spike position fails
	//
	// [sweep][headstage][pulse][region]
	wv[][][0, 9][0, 1] += "SpikePosition_ms:3;"
	wv[][][][]         += "SpontaneousSpikeMax:0.5"
End

static Function SC_Test2_REENTRY([string str])

	variable sweepNo, autobiasV
	string lbl, failedPulses, spikeCounts, spikePos

	sweepNo = 1

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%idealSpikeCounts], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%failedPulseLevel], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS1], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS0], {0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS1], {0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS1], {0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS1], {0, 0}, mode = WAVE_DATA)

	spikeCounts = "P0_R0:1,;P1_R0:1,;P2_R0:1,;P3_R0:1,;P4_R0:1,;P5_R0:1,;P6_R0:1,;P7_R0:1,;P8_R0:1,;P9_R0:1,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS0], {spikeCounts, spikeCounts}, mode = WAVE_DATA)

	spikeCounts = "P0_R1:1,;P1_R1:1,;P2_R1:1,;P3_R1:1,;P4_R1:1,;P5_R1:1,;P6_R1:1,;P7_R1:1,;P8_R1:1,;P9_R1:1,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS1], {spikeCounts, spikeCounts}, mode = WAVE_DATA)

	spikePos = "P0_R0:30,;P1_R0:30,;P2_R0:30,;P3_R0:30,;P4_R0:30,;P5_R0:30,;P6_R0:30,;P7_R0:30,;P8_R0:30,;P9_R0:30,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikePositions_HS0], {spikePos, spikePos}, mode = WAVE_DATA)

	spikePos = "P0_R1:30,;P1_R1:30,;P2_R1:30,;P3_R1:30,;P4_R1:30,;P5_R1:30,;P6_R1:30,;P7_R1:30,;P8_R1:30,;P9_R1:30,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikePositions_HS1], {spikePos, spikePos}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS0], {SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_GOOD}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS1], {SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_GOOD}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS1], {0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS1], {1, 1}, mode = WAVE_DATA)

	// spike position modifier kicks in
	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS0], {1, 3.5}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS1], {1, 3.5}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS1], {0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%DAScaleOutOfRange_HS0], {0, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScaleOutOfRange_HS1], {0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {1, 1})
End

static Function SC_Test3_preInit(string device)

	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleModifier", var = 1.5)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleOperator", str = "+")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MaxTrials", var = 2)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionModifier", var = 2.5)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionOperator", str = "+")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MinimumSpikePosition", var = 50)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "AutoBiasBaselineModifier", var = 10)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "FailedPulseLevel", var = 1)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "IdealNumberOfSpikesPerPulse", var = 1)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_Test3([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE/T wv = MSQ_CreateOverrideResults(str, 0, SC_SPIKE_CONTROL)

	// We have one spike each (required 1)
	// spike position is also correct due to spike pos > minimum spike pos
	//
	// [sweep][headstage][pulse][region]
	wv[][][0, 9][0, 1] += "SpikePosition_ms:7;"
	wv[][][][]         += "SpontaneousSpikeMax:0.5"
End

static Function SC_Test3_REENTRY([string str])

	variable sweepNo, autobiasV, hwType
	string lbl, failedPulses, spikeCounts, spikePos

	hwType = GetHardwareType(str)

	sweepNo = 1

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%idealSpikeCounts], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%failedPulseLevel], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS1], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS0], {0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS1], {0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS1], {0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS1], {0, 0}, mode = WAVE_DATA)

	spikeCounts = "P0_R0:1,;P1_R0:1,;P2_R0:1,;P3_R0:1,;P4_R0:1,;P5_R0:1,;P6_R0:1,;P7_R0:1,;P8_R0:1,;P9_R0:1,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS0], {spikeCounts, spikeCounts}, mode = WAVE_DATA)

	spikeCounts = "P0_R1:1,;P1_R1:1,;P2_R1:1,;P3_R1:1,;P4_R1:1,;P5_R1:1,;P6_R1:1,;P7_R1:1,;P8_R1:1,;P9_R1:1,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS1], {spikeCounts, spikeCounts}, mode = WAVE_DATA)

	if(hwType == HARDWARE_ITC_DAC)
		spikePos = "P0_R0:69.9,;P1_R0:69.9,;P2_R0:69.9,;P3_R0:69.9,;P4_R0:69.9,;P5_R0:69.9,;P6_R0:69.9,;P7_R0:69.9,;P8_R0:69.9,;P9_R0:70.1,;"
	elseif(hwType == HARDWARE_NI_DAC)
		spikePos = "P0_R0:70,;P1_R0:70,;P2_R0:70,;P3_R0:70,;P4_R0:70,;P5_R0:70,;P6_R0:70,;P7_R0:70,;P8_R0:70,;P9_R0:70,;"
	endif
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikePositions_HS0], {spikePos, spikePos}, mode = WAVE_DATA)

	if(hwType == HARDWARE_ITC_DAC)
		spikePos = "P0_R1:70,;P1_R1:70,;P2_R1:70,;P3_R1:70,;P4_R1:70,;P5_R1:70,;P6_R1:70,;P7_R1:70,;P8_R1:70,;P9_R1:70.1,;"
	elseif(hwType == HARDWARE_NI_DAC)
		spikePos = "P0_R1:70,;P1_R1:70,;P2_R1:70,;P3_R1:70,;P4_R1:70,;P5_R1:70,;P6_R1:70,;P7_R1:70,;P8_R1:70,;P9_R1:70,;"
	endif
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikePositions_HS1], {spikePos, spikePos}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS0], {SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_GOOD}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS1], {SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_GOOD}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS1], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS1], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS1], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS1], {0, 0}, mode = WAVE_DATA)

	CHECK_WAVE(lbnEntries[%DAScaleOutOfRange_HS0], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%DAScaleOutOfRange_HS1], NULL_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, {1, 1})
End

static Function SC_Test4_preInit(string device)

	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleModifier", var = 1.5)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleOperator", str = "+")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MaxTrials", var = 2)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionModifier", var = 2.5)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionOperator", str = "+")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MinimumSpikePosition", var = 60)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "AutoBiasBaselineModifier", var = 10)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "FailedPulseLevel", var = 1)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "IdealNumberOfSpikesPerPulse", var = 2)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_Test4([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE/T wv = MSQ_CreateOverrideResults(str, 0, SC_SPIKE_CONTROL)

	// We have two spikes each (2 required)
	// and good spike pos with average spike pos > minimum spike pos
	//
	// [sweep][headstage][pulse][region]
	wv[][][0, 9][0, 1] += "SpikePosition_ms:1,11.5;"
	wv[][][][]         += "SpontaneousSpikeMax:0.5"
End

static Function SC_Test4_REENTRY([string str])

	variable sweepNo, autobiasV, hwType
	string lbl, failedPulses, spikeCounts, spikePos

	hwType = GetHardwareType(str)

	sweepNo = 1

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%idealSpikeCounts], {2}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%failedPulseLevel], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS1], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS0], {0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS1], {0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS1], {0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS1], {0, 0}, mode = WAVE_DATA)

	spikeCounts = "P0_R0:2,;P1_R0:2,;P2_R0:2,;P3_R0:2,;P4_R0:2,;P5_R0:2,;P6_R0:2,;P7_R0:2,;P8_R0:2,;P9_R0:2,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS0], {spikeCounts, spikeCounts}, mode = WAVE_DATA)

	spikeCounts = "P0_R1:2,;P1_R1:2,;P2_R1:2,;P3_R1:2,;P4_R1:2,;P5_R1:2,;P6_R1:2,;P7_R1:2,;P8_R1:2,;P9_R1:2,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS1], {spikeCounts, spikeCounts}, mode = WAVE_DATA)

	if(hwType == HARDWARE_ITC_DAC)
		spikePos = "P0_R0:10,114.9,;P1_R0:10,114.9,;P2_R0:10,114.9,;P3_R0:10,114.9,;P4_R0:10,114.9,;P5_R0:10,114.9,;P6_R0:10,114.9,;P7_R0:10,114.9,;P8_R0:10,114.9,;P9_R0:10,115.1,;"
	elseif(hwType == HARDWARE_NI_DAC)
		spikePos = "P0_R0:10,115,;P1_R0:10,115,;P2_R0:10,115,;P3_R0:10,115,;P4_R0:10,115,;P5_R0:10,115,;P6_R0:10,115,;P7_R0:10,115,;P8_R0:10,115,;P9_R0:10,115,;"
	endif
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikePositions_HS0], {spikePos, spikePos}, mode = WAVE_DATA)

	if(hwType == HARDWARE_ITC_DAC)
		spikePos = "P0_R1:10,115,;P1_R1:10,115,;P2_R1:10,115,;P3_R1:10,115,;P4_R1:10,115,;P5_R1:10,115,;P6_R1:10,115,;P7_R1:10,115,;P8_R1:10,115,;P9_R1:10,115.1,;"
	elseif(hwType == HARDWARE_NI_DAC)
		spikePos = "P0_R1:10,115,;P1_R1:10,115,;P2_R1:10,115,;P3_R1:10,115,;P4_R1:10,115,;P5_R1:10,115,;P6_R1:10,115,;P7_R1:10,115,;P8_R1:10,115,;P9_R1:10,115,;"
	endif
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikePositions_HS1], {spikePos, spikePos}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS0], {SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_GOOD}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS1], {SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_GOOD}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS1], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS1], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS1], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS1], {0, 0}, mode = WAVE_DATA)

	CHECK_WAVE(lbnEntries[%DAScaleOutOfRange_HS0], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%DAScaleOutOfRange_HS1], NULL_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, {1, 1})
End

static Function SC_Test5_preInit(string device)

	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleModifier", var = 1.5)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleOperator", str = "+")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MaxTrials", var = 2)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionModifier", var = 2.5)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionOperator", str = "+")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MinimumSpikePosition", var = 50)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "AutoBiasBaselineModifier", var = 10)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "FailedPulseLevel", var = 1)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "IdealNumberOfSpikesPerPulse", var = 2)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_Test5([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE/T wv = MSQ_CreateOverrideResults(str, 0, SC_SPIKE_CONTROL)

	// We have two spikes each (2 required)
	// and good spike pos with average spike pos > minimum spike pos
	// but we have spontaneous spiking
	//
	// [sweep][headstage][pulse][region]
	wv[][][0, 9][0, 1] += "SpikePosition_ms:7,9;"
	wv[][][][]         += "SpontaneousSpikeMax:1.5"
End

static Function SC_Test5_REENTRY([string str])

	variable sweepNo, autobiasV, hwType
	string lbl, failedPulses, spikeCounts, spikePos

	hwType = GetHardwareType(str)

	sweepNo = 3

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%idealSpikeCounts], {2}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%failedPulseLevel], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS0], {0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS1], {0, 0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS0], {0, 0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS1], {0, 0, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS0], {0, 1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS1], {0, 1, 0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS0], {0, 1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS1], {0, 1, 0, 1}, mode = WAVE_DATA)

	spikeCounts = "P0_R0:2,;P1_R0:2,;P2_R0:2,;P3_R0:2,;P4_R0:2,;P5_R0:2,;P6_R0:2,;P7_R0:2,;P8_R0:2,;P9_R0:2,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS0], {spikeCounts, spikeCounts, spikeCounts, spikeCounts}, mode = WAVE_DATA)

	spikeCounts = "P0_R1:2,;P1_R1:2,;P2_R1:2,;P3_R1:2,;P4_R1:2,;P5_R1:2,;P6_R1:2,;P7_R1:2,;P8_R1:2,;P9_R1:2,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS1], {spikeCounts, spikeCounts, spikeCounts, spikeCounts}, mode = WAVE_DATA)

	if(hwType == HARDWARE_ITC_DAC)
		spikePos = "P0_R0:69.9,89.9,;P1_R0:69.9,89.9,;P2_R0:69.9,89.9,;P3_R0:69.9,89.9,;P4_R0:69.9,89.9,;P5_R0:69.9,89.9,;P6_R0:69.9,89.9,;P7_R0:69.9,89.9,;P8_R0:69.9,89.9,;P9_R0:70.1,90.1,;"
	elseif(hwType == HARDWARE_NI_DAC)
		spikePos = "P0_R0:70,90,;P1_R0:70,90,;P2_R0:70,90,;P3_R0:70,90,;P4_R0:70,90,;P5_R0:70,90,;P6_R0:70,90,;P7_R0:70,90,;P8_R0:70,90,;P9_R0:70,90,;"
	endif
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikePositions_HS0], {spikePos, spikePos, spikePos, spikePos}, mode = WAVE_DATA)

	if(hwType == HARDWARE_ITC_DAC)
		spikePos = "P0_R1:70,90,;P1_R1:70,90,;P2_R1:70,90,;P3_R1:70,90,;P4_R1:70,90,;P5_R1:70,90,;P6_R1:70,90,;P7_R1:70,90,;P8_R1:70,90,;P9_R1:70.1,90.1,;"
	elseif(hwType == HARDWARE_NI_DAC)
		spikePos = "P0_R1:70,90,;P1_R1:70,90,;P2_R1:70,90,;P3_R1:70,90,;P4_R1:70,90,;P5_R1:70,90,;P6_R1:70,90,;P7_R1:70,90,;P8_R1:70,90,;P9_R1:70,90,;"
	endif
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikePositions_HS1], {spikePos, spikePos, spikePos, spikePos}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS0], {SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_GOOD}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS1], {SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_GOOD}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS0], {1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS1], {1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS0], {0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS1], {0, 0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS0], {1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS1], {1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS0], {0, 10, 20, 30}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS1], {0, 10, 20, 30}, mode = WAVE_DATA)

	CHECK_WAVE(lbnEntries[%DAScaleOutOfRange_HS0], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%DAScaleOutOfRange_HS1], NULL_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, {0, 0})
End

static Function SC_Test6_preInit(string device)

	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleModifier", var = 1.5)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleOperator", str = "+")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MaxTrials", var = 2)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionModifier", var = 3)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionOperator", str = "*")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MinimumSpikePosition", var = 50)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "AutoBiasBaselineModifier", var = 10)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "FailedPulseLevel", var = 1)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "IdealNumberOfSpikesPerPulse", var = 1)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_Test6([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE/T wv = MSQ_CreateOverrideResults(str, 0, SC_SPIKE_CONTROL)

	// one spike each for each pulse (1 requested)
	// spike position fails with * as spike position operator
	//
	// [sweep][headstage][pulse][region]
	wv[][][0, 9][0, 1] += "SpikePosition_ms:3;"
	wv[][][][]         += "SpontaneousSpikeMax:0.5"
End

static Function SC_Test6_REENTRY([string str])

	variable sweepNo, autobiasV
	string lbl, failedPulses, spikeCounts, spikePos

	sweepNo = 1

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%idealSpikeCounts], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%failedPulseLevel], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS1], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS0], {0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS1], {0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS1], {0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS1], {0, 0}, mode = WAVE_DATA)

	spikeCounts = "P0_R0:1,;P1_R0:1,;P2_R0:1,;P3_R0:1,;P4_R0:1,;P5_R0:1,;P6_R0:1,;P7_R0:1,;P8_R0:1,;P9_R0:1,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS0], {spikeCounts, spikeCounts}, mode = WAVE_DATA)

	spikeCounts = "P0_R1:1,;P1_R1:1,;P2_R1:1,;P3_R1:1,;P4_R1:1,;P5_R1:1,;P6_R1:1,;P7_R1:1,;P8_R1:1,;P9_R1:1,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS1], {spikeCounts, spikeCounts}, mode = WAVE_DATA)

	spikePos = "P0_R0:30,;P1_R0:30,;P2_R0:30,;P3_R0:30,;P4_R0:30,;P5_R0:30,;P6_R0:30,;P7_R0:30,;P8_R0:30,;P9_R0:30,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikePositions_HS0], {spikePos, spikePos}, mode = WAVE_DATA)

	spikePos = "P0_R1:30,;P1_R1:30,;P2_R1:30,;P3_R1:30,;P4_R1:30,;P5_R1:30,;P6_R1:30,;P7_R1:30,;P8_R1:30,;P9_R1:30,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikePositions_HS1], {spikePos, spikePos}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS0], {SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_GOOD}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS1], {SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_GOOD}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS1], {0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS1], {1, 1}, mode = WAVE_DATA)

	// spike position modifier kicks in
	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS0], {1, 3}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS1], {1, 3}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS1], {0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%DAScaleOutOfRange_HS0], {0, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScaleOutOfRange_HS1], {0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {1, 1})
End

static Function SC_Test7_preInit(string device)

	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleModifier", var = 1.5)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleOperator", str = "+")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MaxTrials", var = 2)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionModifier", var = 2.5)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionOperator", str = "+")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MinimumSpikePosition", var = 90)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "AutoBiasBaselineModifier", var = 10)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "FailedPulseLevel", var = 1)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "IdealNumberOfSpikesPerPulse", var = 2)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_Test7([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE/T wv = MSQ_CreateOverrideResults(str, 0, SC_SPIKE_CONTROL)

	// HS0: Mixed on HS1
	//
	// HS1: Too few, Too many, Good, Mixed
	//
	// [sweep][headstage][pulse][region]
	wv[][0][][0, 1]  = "SpikePosition_ms:4,6"
	wv[][0][0][0, 1] = ""                       // no spike
	wv[][0][1][0, 1] = "SpikePosition_ms:4,6,8" // three spikes

	wv[0][1][][0, 1] = "SpikePosition_ms:4"
	wv[1][1][][0, 1] = "SpikePosition_ms:4,6,8"
	wv[2][1][][0, 1] = "SpikePosition_ms:7,9"

	wv[3][1][][0, 1]  = "SpikePosition_ms:4,6"
	wv[3][1][0][0, 1] = ""                          // no spike
	wv[3][1][2][0, 1] = "SpikePosition_ms:4,6,8,10" // four spikes

	wv[][][][] += ";SpontaneousSpikeMax:0.5"
End

static Function SC_Test7_REENTRY([string str])

	variable sweepNo, hwType
	string spikeCounts, spikePos
	string spikeCounts_sweep0, spikeCounts_sweep1, spikeCounts_sweep2, spikeCounts_sweep3
	string spikePos_sweep0, spikePos_sweep1, spikePos_sweep2, spikePos_sweep3

	hwType = GetHardwareType(str)

	sweepNo = 3

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS0], {0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS1], {0, 0, 1, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS0], {0, 0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS1], {0, 0, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS0], {0, 1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS1], {0, 1, 0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS0], {0, 1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS1], {0, 1, 0, 1}, mode = WAVE_DATA)

	spikeCounts = "P0_R0:0,;P1_R0:3,;P2_R0:2,;P3_R0:2,;P4_R0:2,;P5_R0:2,;P6_R0:2,;P7_R0:2,;P8_R0:2,;P9_R0:2,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS0], {spikeCounts, spikeCounts, spikeCounts, spikeCounts}, mode = WAVE_DATA)

	spikeCounts_sweep0 = "P0_R1:1,;P1_R1:1,;P2_R1:1,;P3_R1:1,;P4_R1:1,;P5_R1:1,;P6_R1:1,;P7_R1:1,;P8_R1:1,;P9_R1:1,;"
	spikeCounts_sweep1 = "P0_R1:3,;P1_R1:3,;P2_R1:3,;P3_R1:3,;P4_R1:3,;P5_R1:3,;P6_R1:3,;P7_R1:3,;P8_R1:3,;P9_R1:3,;"
	spikeCounts_sweep2 = "P0_R1:2,;P1_R1:2,;P2_R1:2,;P3_R1:2,;P4_R1:2,;P5_R1:2,;P6_R1:2,;P7_R1:2,;P8_R1:2,;P9_R1:2,;"
	spikeCounts_sweep3 = "P0_R1:0,;P1_R1:2,;P2_R1:4,;P3_R1:2,;P4_R1:2,;P5_R1:2,;P6_R1:2,;P7_R1:2,;P8_R1:2,;P9_R1:2,;"

	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS1], {spikeCounts_sweep0, spikeCounts_sweep1, spikeCounts_sweep2, spikeCounts_sweep3}, mode = WAVE_DATA)

	if(hwType == HARDWARE_ITC_DAC)
		spikePos = "P1_R0:40,59.9,79.9,;P2_R0:40,59.9,;P3_R0:40,59.9,;P4_R0:40,59.9,;P5_R0:40,59.9,;P6_R0:40,59.9,;P7_R0:40,59.9,;P8_R0:40,59.9,;P9_R0:40,60.1,;"
	elseif(hwType == HARDWARE_NI_DAC)
		spikePos = "P1_R0:40,60,80,;P2_R0:40,60,;P3_R0:40,60,;P4_R0:40,60,;P5_R0:40,60,;P6_R0:40,60,;P7_R0:40,60,;P8_R0:40,60,;P9_R0:40,60,;"
	endif
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikePositions_HS0], {spikePos, spikePos, spikePos, spikePos}, mode = WAVE_DATA)

	if(hwType == HARDWARE_ITC_DAC)
		spikePos_sweep0 = "P0_R1:40,;P1_R1:40,;P2_R1:40,;P3_R1:40,;P4_R1:40,;P5_R1:40,;P6_R1:40,;P7_R1:40,;P8_R1:40,;P9_R1:40,;"
		spikePos_sweep1 = "P0_R1:40,60,80,;P1_R1:40,60,80,;P2_R1:40,60,80,;P3_R1:40,60,80,;P4_R1:40,60,80,;P5_R1:40,60,80,;P6_R1:40,60,80,;P7_R1:40,60,80,;P8_R1:40,60,80,;P9_R1:40,60.1,80.1,;"
		spikePos_sweep2 = "P0_R1:70,90,;P1_R1:70,90,;P2_R1:70,90,;P3_R1:70,90,;P4_R1:70,90,;P5_R1:70,90,;P6_R1:70,90,;P7_R1:70,90,;P8_R1:70,90,;P9_R1:70.1,90.1,;"
		spikePos_sweep3 = "P1_R1:40,60,;P2_R1:40,60,80,100,;P3_R1:40,60,;P4_R1:40,60,;P5_R1:40,60,;P6_R1:40,60,;P7_R1:40,60,;P8_R1:40,60,;P9_R1:40,60.1,;"
	elseif(hwType == HARDWARE_NI_DAC)
		spikePos_sweep0 = "P0_R1:40,;P1_R1:40,;P2_R1:40,;P3_R1:40,;P4_R1:40,;P5_R1:40,;P6_R1:40,;P7_R1:40,;P8_R1:40,;P9_R1:40,;"
		spikePos_sweep1 = "P0_R1:40,60,80,;P1_R1:40,60,80,;P2_R1:40,60,80,;P3_R1:40,60,80,;P4_R1:40,60,80,;P5_R1:40,60,80,;P6_R1:40,60,80,;P7_R1:40,60,80,;P8_R1:40,60,80,;P9_R1:40,60,80,;"
		spikePos_sweep2 = "P0_R1:70,90,;P1_R1:70,90,;P2_R1:70,90,;P3_R1:70,90,;P4_R1:70,90,;P5_R1:70,90,;P6_R1:70,90,;P7_R1:70,90,;P8_R1:70,90,;P9_R1:70,90,;"
		spikePos_sweep3 = "P1_R1:40,60,;P2_R1:40,60,80,100,;P3_R1:40,60,;P4_R1:40,60,;P5_R1:40,60,;P6_R1:40,60,;P7_R1:40,60,;P8_R1:40,60,;P9_R1:40,60,;"
	endif
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikePositions_HS1], {spikePos_sweep0, spikePos_sweep1, spikePos_sweep2, spikePos_sweep3}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS0], {SC_SPIKE_COUNT_STATE_STR_MIXED, SC_SPIKE_COUNT_STATE_STR_MIXED, SC_SPIKE_COUNT_STATE_STR_MIXED, SC_SPIKE_COUNT_STATE_STR_MIXED}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS1], {SC_SPIKE_COUNT_STATE_STR_TOO_FEW, SC_SPIKE_COUNT_STATE_STR_TOO_MANY, SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_MIXED}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS0], {0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS1], {0, 0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS0], {1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS1], {1, 1, 1, 1}, mode = WAVE_DATA)

	//	spike position modifier kicks in the third sweep of HS1
	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS0], {1, 2.5, 4, 5.5}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS1], {1, 2.5, -1, 1.5}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS0], {0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS1], {0, 0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%DAScaleOutOfRange_HS0], {0, 0, 0, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScaleOutOfRange_HS1], {0, 0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {0, 0})
End

static Function SC_Test8_preInit(string device)

	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleModifier", var = 2)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleOperator", str = "*")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MaxTrials", var = 2)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionModifier", var = 3)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionOperator", str = "*")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MinimumSpikePosition", var = 50)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "AutoBiasBaselineModifier", var = 10)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "FailedPulseLevel", var = 2)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "IdealNumberOfSpikesPerPulse", var = 1)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_Test8([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE/T wv = MSQ_CreateOverrideResults(str, 0, SC_SPIKE_CONTROL)

	// SPF: spike position fails

	// [sweep][headstage][pulse][region]

	// sweep 0, HS0: Too few (SPF)
	// sweep 0, HS1: Good (SPF)

	wv[0][0][][0, 1] = "" // no spike
	wv[0][1][][0, 1] = "SpikePosition_ms:4"

	// sweep 1, HS0: Good (SPF)
	// sweep 1, HS1: Too Many

	wv[1][0][][0, 1] = "SpikePosition_ms:3"
	wv[1][1][][0, 1] = "SpikePosition_ms:6,8"

	// sweep 2, HS0: Too Many (SPF)
	// sweep 2, HS1: Good

	wv[2][0][][0, 1] = "SpikePosition_ms:3,4"
	wv[2][1][][0, 1] = "SpikePosition_ms:6"

	// sweep 3, HS0: Good
	// sweep 3, HS1: Too Few (SPF)

	wv[3][0][][0, 1] = "SpikePosition_ms:6.5"
	wv[3][1][][0, 1] = "" // no spike

	wv[][][][] += ";SpontaneousSpikeMax:0.5"
End

static Function SC_Test8_REENTRY([string str])

	variable sweepNo, hwType
	string spikeCounts, spikePos
	string spikeCounts_sweep0, spikeCounts_sweep1, spikeCounts_sweep2, spikeCounts_sweep3
	string spikePos_sweep0, spikePos_sweep1, spikePos_sweep2, spikePos_sweep3

	hwType = GetHardwareType(str)

	sweepNo = 3

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 1, 0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS0], {0, 1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS1], {1, 0, 1, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS0], {0, 0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS1], {0, 0, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS0], {0, 1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS1], {0, 1, 0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS0], {0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS1], {0, 0, 0, 0}, mode = WAVE_DATA)

	spikeCounts_sweep0 = "P0_R0:0,;P1_R0:0,;P2_R0:0,;P3_R0:0,;P4_R0:0,;P5_R0:0,;P6_R0:0,;P7_R0:0,;P8_R0:0,;P9_R0:0,;"
	spikeCounts_sweep1 = "P0_R0:1,;P1_R0:1,;P2_R0:1,;P3_R0:1,;P4_R0:1,;P5_R0:1,;P6_R0:1,;P7_R0:1,;P8_R0:1,;P9_R0:1,;"
	spikeCounts_sweep2 = "P0_R0:2,;P1_R0:2,;P2_R0:2,;P3_R0:2,;P4_R0:2,;P5_R0:2,;P6_R0:2,;P7_R0:2,;P8_R0:2,;P9_R0:2,;"
	spikeCounts_sweep3 = "P0_R0:1,;P1_R0:1,;P2_R0:1,;P3_R0:1,;P4_R0:1,;P5_R0:1,;P6_R0:1,;P7_R0:1,;P8_R0:1,;P9_R0:1,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS0], {spikeCounts_sweep0, spikeCounts_sweep1, spikeCounts_sweep2, spikeCounts_sweep3}, mode = WAVE_DATA)

	spikeCounts_sweep0 = "P0_R1:1,;P1_R1:1,;P2_R1:1,;P3_R1:1,;P4_R1:1,;P5_R1:1,;P6_R1:1,;P7_R1:1,;P8_R1:1,;P9_R1:1,;"
	spikeCounts_sweep1 = "P0_R1:2,;P1_R1:2,;P2_R1:2,;P3_R1:2,;P4_R1:2,;P5_R1:2,;P6_R1:2,;P7_R1:2,;P8_R1:2,;P9_R1:2,;"
	spikeCounts_sweep2 = "P0_R1:1,;P1_R1:1,;P2_R1:1,;P3_R1:1,;P4_R1:1,;P5_R1:1,;P6_R1:1,;P7_R1:1,;P8_R1:1,;P9_R1:1,;"
	spikeCounts_sweep3 = "P0_R1:0,;P1_R1:0,;P2_R1:0,;P3_R1:0,;P4_R1:0,;P5_R1:0,;P6_R1:0,;P7_R1:0,;P8_R1:0,;P9_R1:0,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS1], {spikeCounts_sweep0, spikeCounts_sweep1, spikeCounts_sweep2, spikeCounts_sweep3}, mode = WAVE_DATA)

	if(hwType == HARDWARE_ITC_DAC)
		spikePos_sweep0 = ""
		spikePos_sweep1 = "P0_R0:30,;P1_R0:30,;P2_R0:30,;P3_R0:30,;P4_R0:30,;P5_R0:30,;P6_R0:30,;P7_R0:30,;P8_R0:30,;P9_R0:30,;"
		spikePos_sweep2 = "P0_R0:30,40,;P1_R0:30,40,;P2_R0:30,40,;P3_R0:30,40,;P4_R0:30,40,;P5_R0:30,40,;P6_R0:30,40,;P7_R0:30,40,;P8_R0:30,40,;P9_R0:30,40,;"
		spikePos_sweep3 = "P0_R0:64.9,;P1_R0:64.9,;P2_R0:64.9,;P3_R0:64.9,;P4_R0:64.9,;P5_R0:64.9,;P6_R0:64.9,;P7_R0:64.9,;P8_R0:64.9,;P9_R0:65.1,;"
	elseif(hwType == HARDWARE_NI_DAC)
		spikePos_sweep0 = ""
		spikePos_sweep1 = "P0_R0:30,;P1_R0:30,;P2_R0:30,;P3_R0:30,;P4_R0:30,;P5_R0:30,;P6_R0:30,;P7_R0:30,;P8_R0:30,;P9_R0:30,;"
		spikePos_sweep2 = "P0_R0:30,40,;P1_R0:30,40,;P2_R0:30,40,;P3_R0:30,40,;P4_R0:30,40,;P5_R0:30,40,;P6_R0:30,40,;P7_R0:30,40,;P8_R0:30,40,;P9_R0:30,40,;"
		spikePos_sweep3 = "P0_R0:65,;P1_R0:65,;P2_R0:65,;P3_R0:65,;P4_R0:65,;P5_R0:65,;P6_R0:65,;P7_R0:65,;P8_R0:65,;P9_R0:65,;"
	endif
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikePositions_HS0], {spikePos_sweep0, spikePos_sweep1, spikePos_sweep2, spikePos_sweep3}, mode = WAVE_DATA)

	if(hwType == HARDWARE_ITC_DAC)
		spikePos_sweep0 = "P0_R1:40,;P1_R1:40,;P2_R1:40,;P3_R1:40,;P4_R1:40,;P5_R1:40,;P6_R1:40,;P7_R1:40,;P8_R1:40,;P9_R1:40,;"
		spikePos_sweep1 = "P0_R1:60,80,;P1_R1:60,80,;P2_R1:60,80,;P3_R1:60,80,;P4_R1:60,80,;P5_R1:60,80,;P6_R1:60,80,;P7_R1:60,80,;P8_R1:60,80,;P9_R1:60.1,80.1,;"
		spikePos_sweep2 = "P0_R1:60,;P1_R1:60,;P2_R1:60,;P3_R1:60,;P4_R1:60,;P5_R1:60,;P6_R1:60,;P7_R1:60,;P8_R1:60,;P9_R1:60.1,;"
		spikePos_sweep3 = ""
	elseif(hwType == HARDWARE_NI_DAC)
		spikePos_sweep0 = "P0_R1:40,;P1_R1:40,;P2_R1:40,;P3_R1:40,;P4_R1:40,;P5_R1:40,;P6_R1:40,;P7_R1:40,;P8_R1:40,;P9_R1:40,;"
		spikePos_sweep1 = "P0_R1:60,80,;P1_R1:60,80,;P2_R1:60,80,;P3_R1:60,80,;P4_R1:60,80,;P5_R1:60,80,;P6_R1:60,80,;P7_R1:60,80,;P8_R1:60,80,;P9_R1:60,80,;"
		spikePos_sweep2 = "P0_R1:60,;P1_R1:60,;P2_R1:60,;P3_R1:60,;P4_R1:60,;P5_R1:60,;P6_R1:60,;P7_R1:60,;P8_R1:60,;P9_R1:60,;"
		spikePos_sweep3 = ""
	endif
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikePositions_HS1], {spikePos_sweep0, spikePos_sweep1, spikePos_sweep2, spikePos_sweep3}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS0], {SC_SPIKE_COUNT_STATE_STR_TOO_FEW, SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_TOO_MANY, SC_SPIKE_COUNT_STATE_STR_GOOD}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS1], {SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_TOO_MANY, SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_TOO_FEW}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS0], {0, 0, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS1], {0, 1, 1, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS0], {1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS1], {1, 1, 1, 1}, mode = WAVE_DATA)

	//	spike position modifier kicks in the third sweep of HS1
	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS0], {1, 2, 6, 2.5}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS1], {1, 3, -0.5, -0.5}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS0], {0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS1], {0, 0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%DAScaleOutOfRange_HS0], {0, 0, 0, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%DAScaleOutOfRange_HS1], {0, 0, NaN, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, {1, 1})
End

static Function SC_Test9_preInit(string device)

	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleModifier", var = 1.5)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleOperator", str = "+")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MaxTrials", var = 2)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionModifier", var = 3)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionOperator", str = "*")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MinimumSpikePosition", var = 50)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "AutoBiasBaselineModifier", var = 10)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "FailedPulseLevel", var = 1)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "IdealNumberOfSpikesPerPulse", var = 1)
End

static Function SC_Test9_preAcq(string device)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(V_CLAMP_MODE, 1), val = 1)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_Test9([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE/T wv = MSQ_CreateOverrideResults(str, 0, SC_SPIKE_CONTROL)

	// one spike each for each pulse (1 requested)
	// spike position fails with * as spike position operator
	// second headstage is VC
	//
	// [sweep][headstage][pulse][region]
	wv[][0][0, 9][0, 1] += "SpikePosition_ms:3;"
	wv[][0][][]         += "SpontaneousSpikeMax:0.5"
End

static Function SC_Test9_REENTRY([string str])

	variable sweepNo, autobiasV
	string lbl, failedPulses, spikeCounts, spikePos

	sweepNo = 1

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%idealSpikeCounts], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%failedPulseLevel], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS0], {1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%headstagePass_HS1], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS0], {0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS1], {0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%rerunTrials_HS1], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%rerunTrialsExceeded_HS1], NULL_WAVE)

	spikeCounts = "P0_R0:1,;P1_R0:1,;P2_R0:1,;P3_R0:1,;P4_R0:1,;P5_R0:1,;P6_R0:1,;P7_R0:1,;P8_R0:1,;P9_R0:1,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS0], {spikeCounts, spikeCounts}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikeCounts_HS1], NULL_WAVE)

	spikePos = "P0_R0:30,;P1_R0:30,;P2_R0:30,;P3_R0:30,;P4_R0:30,;P5_R0:30,;P6_R0:30,;P7_R0:30,;P8_R0:30,;P9_R0:30,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikePositions_HS0], {spikePos, spikePos}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePositions_HS1], NULL_WAVE)

	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS0], {SC_SPIKE_COUNT_STATE_STR_GOOD, SC_SPIKE_COUNT_STATE_STR_GOOD}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikeCountsState_HS1], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePositionQC_HS1], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS0], {1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spontSpikeQC_HS1], NULL_WAVE)

	// spike position modifier kicks in
	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS0], {1, 3}, mode = WAVE_DATA)
	// but not here as this HS is in VC
	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS1], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%autoBiasV_HS1], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%DAScaleOutOfRange_HS0], {0, NaN}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%DAScaleOutOfRange_HS1], NULL_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, {1, 1})
End

static Function SC_Test10_preInit(string device)

	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleModifier", var = 2500)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleOperator", str = "+")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MaxTrials", var = 3)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionModifier", var = 3)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "DAScaleSpikePositionOperator", str = "*")
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "MinimumSpikePosition", var = 50)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "AutoBiasBaselineModifier", var = 10)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "FailedPulseLevel", var = 1)
	AFH_AddAnalysisParameter("SC_SpikeControl_DA_0", "IdealNumberOfSpikesPerPulse", var = 1)
End

static Function SC_Test10_preAcq(string device)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(V_CLAMP_MODE, 1), val = 1)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_Test10([string str])

	[STRUCT DAQSettings s] = MSQ_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE/T wv = MSQ_CreateOverrideResults(str, 0, SC_SPIKE_CONTROL)

	// SPF: spike position fails

	// [sweep][headstage][pulse][region]

	// all sweeps, HS0: Too few (SPF)
	// all sweeps, HS1: Good (SPF)

	wv[][0][][0, 1] = "" // no spike
	wv[][1][][0, 1] = "SpikePosition_ms:4"
End

static Function SC_Test10_REENTRY([string str])

	variable sweepNo, autobiasV
	string lbl, failedPulses, spikeCounts, spikePos

	sweepNo = 1

	WAVE/WAVE lbnEntries = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(lbnEntries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%sweepPass], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%idealSpikeCounts], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%failedPulseLevel], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%headstagePass_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%headstagePass_HS1], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%setSweepCount_HS1], {0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrials_HS0], {0, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%rerunTrials_HS1], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%rerunTrialsExceeded_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%rerunTrialsExceeded_HS1], NULL_WAVE)

	spikeCounts = "P0_R0:0,;P1_R0:0,;P2_R0:0,;P3_R0:0,;P4_R0:0,;P5_R0:0,;P6_R0:0,;P7_R0:0,;P8_R0:0,;P9_R0:0,;"
	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCounts_HS0], {spikeCounts, spikeCounts}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikeCounts_HS1], NULL_WAVE)

	CHECK_WAVE(lbnEntries[%spikePositions_HS0], NULL_WAVE)
	CHECK_WAVE(lbnEntries[%spikePositions_HS1], NULL_WAVE)

	CHECK_EQUAL_TEXTWAVES(lbnEntries[%spikeCountsState_HS0], {SC_SPIKE_COUNT_STATE_STR_TOO_FEW, SC_SPIKE_COUNT_STATE_STR_TOO_FEW}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikeCountsState_HS1], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%spikePositionQC_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spikePositionQC_HS1], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%spontSpikeQC_HS0], {0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%spontSpikeQC_HS1], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS0], {1, 2501}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(lbnEntries[%stimScale_HS1], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(lbnEntries[%autoBiasV_HS0], {0, 10}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%autoBiasV_HS1], NULL_WAVE)

	CHECK_EQUAL_WAVES(lbnEntries[%DAScaleOutOfRange_HS0], {0, 1}, mode = WAVE_DATA)
	CHECK_WAVE(lbnEntries[%DAScaleOutOfRange_HS1], NULL_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, {0, 0})
End
