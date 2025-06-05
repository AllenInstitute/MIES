#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = SweepSkipping

static Function [STRUCT DAQSettings s] GetDAQSettings(string mandConfig)

	InitDAQSettingsFromString(s, mandConfig                                                          + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:_IST:StimulusSetB_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:_IST:StimulusSetD_DA_0:")
End

static Function GlobalPreInit(string device)

	PASS()
End

static Function GlobalPreAcq(string device)

	PASS()
End

static Function SkipAhead_PreAcq(string device)

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_skipAhead", val = 2)
	// redo so that the limits that the now updated limits are used
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_skipAhead", val = 2)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SkipAhead([string str])

	[STRUCT DAQSettings s] = GetDAQSettings("MD1_RA1_I0_L0_BKG1")
	AcquireData_NG(s, str)
End

static Function SkipAhead_REENTRY([string str])

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	WAVE numericalValues = GetLBNumericalValues(str)
	sweepNo = 0

	WAVE/Z setSweepCount = GetLastSetting(numericalValues, sweepNo, "Set sweep count", DATA_ACQUISITION_MODE)

	CHECK_EQUAL_WAVES(setSweepCount, {2, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z skipAhead = GetLastSetting(numericalValues, sweepNo, "Skip Ahead", DATA_ACQUISITION_MODE)

	CHECK_EQUAL_WAVES(skipAhead, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 2}, mode = WAVE_DATA)
End

static Function SweepSkipping_PreAcq(string device)

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "SkipSweeps")
	ST_SetStimsetParameter("StimulusSetB_DA_0", "Analysis function (generic)", str = "SkipSweeps")
	ST_SetStimsetParameter("StimulusSetC_DA_0", "Analysis function (generic)", str = "SkipSweeps")
	ST_SetStimsetParameter("StimulusSetD_DA_0", "Analysis function (generic)", str = "SkipSweeps")

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetA_*")
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), str = "StimulusSetD_*")
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SweepSkipping([string str])

	[STRUCT DAQSettings s] = GetDAQSettings("MD1_RA1_I1_L0_BKG1")
	AcquireData_NG(s, str)
End

static Function SweepSkipping_REENTRY([string str])

	variable numSweeps = 4
	variable sweepNo   = 0
	variable headstage = 0

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), numSweeps)

	WAVE/T textualValues   = GetLBTextualValues(str)
	WAVE   numericalValues = GetLBNumericalValues(str)

	WAVE/Z/T foundStimSets = GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, STIM_WAVE_NAME_KEY, headstage, DATA_ACQUISITION_MODE)
	REQUIRE_WAVE(foundStimSets, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(foundStimSets, {"StimulusSetA_DA_0", "StimulusSetB_DA_0", "StimulusSetC_DA_0", "StimulusSetD_DA_0"})

	WAVE/Z sweepCounts = GetLastSettingEachRAC(numericalValues, sweepNo, "Set Sweep Count", headstage, DATA_ACQUISITION_MODE)
	REQUIRE_WAVE(sweepCounts, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(sweepCounts, {0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z skippingSweeps = GetLastSettingIndepEachRAC(numericalValues, sweepNo, SKIP_SWEEPS_KEY, UNKNOWN_MODE)
	REQUIRE_WAVE(skippingSweeps, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(skippingSweeps, {2, 0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z skipSweepsSource = GetLastSettingIndepEachRAC(numericalValues, sweepNo, SKIP_SWEEPS_SOURCE_KEY, UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(skipSweepsSource, {SWEEP_SKIP_AUTO, SWEEP_SKIP_AUTO, SWEEP_SKIP_AUTO, SWEEP_SKIP_AUTO}, mode = WAVE_DATA)
End

static Function SweepSkippingAdvanced_PreAcq(string device)

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "SkipSweepsAdvanced")
	ST_SetStimsetParameter("StimulusSetB_DA_0", "Analysis function (generic)", str = "SkipSweepsAdvanced")
	ST_SetStimsetParameter("StimulusSetC_DA_0", "Analysis function (generic)", str = "SkipSweepsAdvanced")
	ST_SetStimsetParameter("StimulusSetD_DA_0", "Analysis function (generic)", str = "SkipSweepsAdvanced")

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetA_*")
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SweepSkippingAdvanced([string str])

	[STRUCT DAQSettings s] = GetDAQSettings("MD1_RA1_I0_L0_BKG1")
	AcquireData_NG(s, str)
End

static Function SweepSkippingAdvanced_REENTRY([string str])

	variable numSweeps = 4
	variable sweepNo   = 0
	variable headstage = 0

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), numSweeps)

	WAVE/T textualValues   = GetLBTextualValues(str)
	WAVE   numericalValues = GetLBNumericalValues(str)

	WAVE/Z/T foundStimSets = GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, STIM_WAVE_NAME_KEY, headstage, DATA_ACQUISITION_MODE)
	REQUIRE_WAVE(foundStimSets, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(foundStimSets, {"StimulusSetA_DA_0", "StimulusSetA_DA_0", "StimulusSetA_DA_0", "StimulusSetA_DA_0"})

	WAVE/Z sweepCounts = GetLastSettingEachRAC(numericalValues, sweepNo, "Set Sweep Count", headstage, DATA_ACQUISITION_MODE)
	REQUIRE_WAVE(sweepCounts, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(sweepCounts, {0, 0, 2, 2}, mode = WAVE_DATA)

	// XXX_SET_EVENT counts are subject to change with sweep skipping
	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 2)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 4)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 4)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 2)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	WaveTransform/O zapNans, anaFuncActiveSetCount
	CHECK_EQUAL_WAVES(anaFuncActiveSetCount, {3, 3, 1, 1})

	WAVE/Z skipSweepsSource = GetLastSettingIndepEachRAC(numericalValues, sweepNo, SKIP_SWEEPS_SOURCE_KEY, UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(skipSweepsSource, {SWEEP_SKIP_AUTO, SWEEP_SKIP_AUTO, SWEEP_SKIP_AUTO, NaN}, mode = WAVE_DATA)
End

// UTF_TD_GENERATOR v0:SingleMultiDeviceDAQ
// UTF_TD_GENERATOR s0:DeviceNameGenerator
static Function SkipSweepsDuringITI([STRUCT IUTF_MDATA &md])

	[STRUCT DAQSettings s] = GetDAQSettings("MD" + num2str(md.v0) + "_RA1_I0_L0_BKG1_RES5_GSI0_ITI5")
	AcquireData_NG(s, md.s0)

	CtrlNamedBackGround ExecuteDuringITI, start, period=30, proc=SkipToEndDuringITI_IGNORE
End

static Function SkipSweepsDuringITI_REENTRY([STRUCT IUTF_MDATA &md])

	string device
	variable numEntries, i

	numEntries = ItemsInList(md.s0)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, md.s0)
		NVAR runMode = $GetDataAcqRunMode(device)

		CHECK_EQUAL_VAR(runMode, DAQ_NOT_RUNNING)
	endfor
End

static Function SkipSweepsBackDuringITI_PreAcq(string device)

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "TrackActiveSetCountsAndEvents")
	ST_SetStimsetParameter("StimulusSetB_DA_0", "Analysis function (generic)", str = "TrackActiveSetCountsAndEvents")
	ST_SetStimsetParameter("StimulusSetC_DA_0", "Analysis function (generic)", str = "TrackActiveSetCountsAndEvents")
	ST_SetStimsetParameter("StimulusSetD_DA_0", "Analysis function (generic)", str = "TrackActiveSetCountsAndEvents")

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetA_*")
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), str = "StimulusSetD_*")
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SkipSweepsBackDuringITI([string str])

	[STRUCT DAQSettings s] = GetDAQSettings("MD1_RA1_I0_L0_BKG1_RES0_GSI0_ITI5")
	AcquireData_NG(s, str)

	CtrlNamedBackGround ExecuteDuringITI, start, period=30, proc=SkipSweepBackDuringITI_IGNORE
End

static Function SkipSweepsBackDuringITI_REENTRY([string str])

	variable numSweeps = 4
	variable sweepNo   = 0
	variable headstage = 0

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), numSweeps)

	WAVE/T textualValues   = GetLBTextualValues(str)
	WAVE   numericalValues = GetLBNumericalValues(str)

	WAVE/Z/T foundStimSets = GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, STIM_WAVE_NAME_KEY, headstage, DATA_ACQUISITION_MODE)
	REQUIRE_WAVE(foundStimSets, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(foundStimSets, {"StimulusSetA_DA_0", "StimulusSetA_DA_0", "StimulusSetA_DA_0", "StimulusSetA_DA_0"})

	WAVE/Z sweepCounts = GetLastSettingEachRAC(numericalValues, sweepNo, "Set Sweep Count", headstage, DATA_ACQUISITION_MODE)
	REQUIRE_WAVE(sweepCounts, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(sweepCounts, {0, 0, 1, 2}, mode = WAVE_DATA)

	// XXX_SET_EVENT counts are subject to change with sweep skipping
	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 4)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 4)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	WaveTransform/O zapNans, anaFuncActiveSetCount
	CHECK_EQUAL_WAVES(anaFuncActiveSetCount, {3, 3, 2, 1})
End
