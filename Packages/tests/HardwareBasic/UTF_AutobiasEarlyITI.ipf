#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = AutobiasEarlyITI

/// @file UTF_AutobiasEarlyITI.ipf
/// @brief Ending the ITI early once autobias reached the target voltage, see ANALYSIS_FUNC_RET_AUTOBIAS
///
/// StopFirstSweepForAutobias_V3 stops the first sweep right away, the second sweep acquires
/// regularly. The checks look at the ITI after the first sweep.

static StrConstant STIMSET = "StimulusSetA_DA_0"

/// The autobias range of every headstage contains any baseline voltage
static StrConstant AUTOBIAS_IN_RANGE = "_AB1_ABV-70_ABR1000"
/// The autobias range of every headstage contains no baseline voltage
static StrConstant AUTOBIAS_NOT_IN_RANGE = "_AB1_ABV99_ABR0"

static Function [STRUCT ACD_DAQSettings s] GetDAQSettings(variable ITI, string autobias)

	string str

	sprintf str, "MD1_RA1_I0_L0_BKG1_GSI0_TPI1_ITI%g__HS0_DA0_AD0_CM:IC:%s_ST:%s:_AF:StopFirstSweepForAutobias_V3:", ITI, autobias, STIMSET
	[s] = ACD_InitDAQSettingsFromString(str)

	return [s]
End

static Function GlobalPreInit(string device)

	ST_SetStimsetParameter(STIMSET, "Total number of steps", var = 2)
End

static Function GlobalPreAcq(string device)

	PASS()
End

static Function SetAnalysisParameters(variable midSweepReturnValue, variable repurposedTime)

	AFH_AddAnalysisParameter(STIMSET, "MidSweepReturnValue", var = midSweepReturnValue)
	AFH_AddAnalysisParameter(STIMSET, "RepurposedTime", var = repurposedTime)
End

static Function [variable ITI, variable finishedEarly] GetITIOfFirstSweep(string device)

	variable sweepNo

	sweepNo = AFH_GetLastSweepAcquired(device)
	CHECK_EQUAL_VAR(sweepNo, 1)

	WAVE numericalValues = GetLBNumericalValues(device)

	ITI           = GetLastSettingIndep(numericalValues, 0, "Inter-trial interval (effective)", UNKNOWN_MODE)
	finishedEarly = GetLastSettingIndep(numericalValues, 0, ITI_FINISHED_EARLY_KEY, UNKNOWN_MODE)

	return [ITI, finishedEarly]
End

static Function EarlyEnd_PreAcq(string device)

	SetAnalysisParameters(ANALYSIS_FUNC_RET_AUTOBIAS, 30)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function EarlyEnd([string str])

	[STRUCT ACD_DAQSettings s] = GetDAQSettings(1, AUTOBIAS_IN_RANGE)
	ACD_AcquireData(s, str)
End

static Function EarlyEnd_REENTRY([string str])

	variable ITI, finishedEarly

	[ITI, finishedEarly] = GetITIOfFirstSweep(str)

	CHECK_EQUAL_VAR(finishedEarly, 1)
	// AUTOBIAS_EARLY_ITI_NUM_PASSES autobias checks, one per second, instead of more than 30 s
	CHECK_LT_VAR(ITI, 15)
End

static Function EarliestEndIsRegularITI_PreAcq(string device)

	SetAnalysisParameters(ANALYSIS_FUNC_RET_AUTOBIAS, 30)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function EarliestEndIsRegularITI([string str])

	[STRUCT ACD_DAQSettings s] = GetDAQSettings(8, AUTOBIAS_IN_RANGE)
	ACD_AcquireData(s, str)
End

static Function EarliestEndIsRegularITI_REENTRY([string str])

	variable ITI, finishedEarly

	[ITI, finishedEarly] = GetITIOfFirstSweep(str)

	CHECK_EQUAL_VAR(finishedEarly, 1)
	// regular ITI of 8 s minus the short acquisition time of the stopped sweep
	CHECK_GE_VAR(ITI, 7)
	CHECK_LT_VAR(ITI, 20)
End

static Function TargetNotReached_PreAcq(string device)

	SetAnalysisParameters(ANALYSIS_FUNC_RET_AUTOBIAS, 4)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function TargetNotReached([string str])

	[STRUCT ACD_DAQSettings s] = GetDAQSettings(1, AUTOBIAS_NOT_IN_RANGE)
	ACD_AcquireData(s, str)
End

static Function TargetNotReached_REENTRY([string str])

	variable ITI, finishedEarly

	[ITI, finishedEarly] = GetITIOfFirstSweep(str)

	CHECK_EQUAL_VAR(finishedEarly, 0)
	CHECK_GE_VAR(ITI, 4)
End

static Function NoEarlyEndWithRepurposedTime_PreAcq(string device)

	SetAnalysisParameters(ANALYSIS_FUNC_RET_REPURP_TIME, 4)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function NoEarlyEndWithRepurposedTime([string str])

	[STRUCT ACD_DAQSettings s] = GetDAQSettings(1, AUTOBIAS_IN_RANGE)
	ACD_AcquireData(s, str)
End

static Function NoEarlyEndWithRepurposedTime_REENTRY([string str])

	variable ITI, finishedEarly

	[ITI, finishedEarly] = GetITIOfFirstSweep(str)

	CHECK_EQUAL_VAR(finishedEarly, NaN)
	CHECK_GE_VAR(ITI, 4)
End
