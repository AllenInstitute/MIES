#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=SweepSkipping

static Function SkipAhead_IGNORE(string device)

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_skipAhead", val = 2)
	// redo so that the limits that the now updated limits are used
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_skipAhead", val = 2)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
static Function SkipAhead([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1")
	AcquireData_BHT(s, str, preAcquireFunc = SkipAhead_IGNORE)
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

Function SkipSweepsStimsetsP_IGNORE(device)
	string device

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "SkipSweeps")
	ST_SetStimsetParameter("StimulusSetB_DA_0", "Analysis function (generic)", str = "SkipSweeps")
	ST_SetStimsetParameter("StimulusSetC_DA_0", "Analysis function (generic)", str = "SkipSweeps")
	ST_SetStimsetParameter("StimulusSetD_DA_0", "Analysis function (generic)", str = "SkipSweeps")
End

static Function SkipSweepsStimsets_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetA_*")
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), str = "StimulusSetD_*")
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function SweepSkipping([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L0_BKG1")
	AcquireData_BHT(s, str, postInitializeFunc = SkipSweepsStimsetsP_IGNORE, preAcquireFunc = SkipSweepsStimsets_IGNORE)
End

Function SweepSkipping_REENTRY([str])
	string str

	variable numSweeps = 4
	variable sweepNo   = 0
	variable headstage = 0

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), numSweeps)

	WAVE/T textualValues   = GetLBTextualValues(str)
	WAVE   numericalValues = GetLBNumericalValues(str)

	WAVE/T/Z foundStimSets = GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, STIM_WAVE_NAME_KEY, headstage, DATA_ACQUISITION_MODE)
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

Function SkipSweepsStimsetsAdvancedP_IGNORE(device)
	string device

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "SkipSweepsAdvanced")
	ST_SetStimsetParameter("StimulusSetB_DA_0", "Analysis function (generic)", str = "SkipSweepsAdvanced")
	ST_SetStimsetParameter("StimulusSetC_DA_0", "Analysis function (generic)", str = "SkipSweepsAdvanced")
	ST_SetStimsetParameter("StimulusSetD_DA_0", "Analysis function (generic)", str = "SkipSweepsAdvanced")
End

static Function SkipSweepsStimsetsAdvanced_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetA_*")
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function SweepSkippingAdvanced([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1")
	AcquireData_BHT(s, str, postInitializeFunc = SkipSweepsStimsetsAdvancedP_IGNORE, preAcquireFunc = SkipSweepsStimsetsAdvanced_IGNORE)
End

Function SweepSkippingAdvanced_REENTRY([str])
	string str

	variable numSweeps = 4
	variable sweepNo   = 0
	variable headstage = 0

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), numSweeps)

	WAVE/T textualValues   = GetLBTextualValues(str)
	WAVE   numericalValues = GetLBNumericalValues(str)

	WAVE/T/Z foundStimSets = GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, STIM_WAVE_NAME_KEY, headstage, DATA_ACQUISITION_MODE)
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

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD0
Function SkipSweepsDuringITI_SD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA1_I0_L0_BKG1_RES5")
	AcquireData_BHT(s, str)

	CtrlNamedBackGround ExecuteDuringITI, start, period=30, proc=SkipToEndDuringITI_IGNORE

	PGC_SetAndActivateControl(str, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(str, "SetVar_DataAcq_ITI", val = 5)
End

Function SkipSweepsDuringITI_SD_REENTRY([str])
	string str

	string device
	variable numEntries, i

	numEntries = ItemsInList(str)
	for(i = 0; i < numEntries; i += 1)
		device = stringFromList(i, str)
		NVAR runMode = $GetDataAcqRunMode(device)

		CHECK_EQUAL_VAR(runMode, DAQ_NOT_RUNNING)
	endfor
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function SkipSweepsDuringITI_MD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES5")
	AcquireData_BHT(s, str)

	CtrlNamedBackGround ExecuteDuringITI, start, period=30, proc=SkipToEndDuringITI_IGNORE

	PGC_SetAndActivateControl(str, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(str, "SetVar_DataAcq_ITI", val = 5)
End

Function SkipSweepsDuringITI_MD_REENTRY([str])
	string str

	string device
	variable numEntries, i

	numEntries = ItemsInList(str)
	for(i = 0; i < numEntries; i += 1)
		device = stringFromList(i, str)
		NVAR runMode = $GetDataAcqRunMode(device)

		CHECK_EQUAL_VAR(runMode, DAQ_NOT_RUNNING)
	endfor
End

Function SkipSweepsBackDuringITIAnaFuncs_IGNORE(device)
	string device

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "TrackActiveSetCountsAndEvents")
	ST_SetStimsetParameter("StimulusSetB_DA_0", "Analysis function (generic)", str = "TrackActiveSetCountsAndEvents")
	ST_SetStimsetParameter("StimulusSetC_DA_0", "Analysis function (generic)", str = "TrackActiveSetCountsAndEvents")
	ST_SetStimsetParameter("StimulusSetD_DA_0", "Analysis function (generic)", str = "TrackActiveSetCountsAndEvents")
End

static Function SkipSweepsBackDuringITIStimsets_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetA_*")
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), str = "StimulusSetD_*")
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function SkipSweepsBackDuringITI([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES0")
	AcquireData_BHT(s, str, postInitializeFunc = SkipSweepsBackDuringITIAnaFuncs_IGNORE, preAcquireFunc = SkipSweepsBackDuringITIStimsets_IGNORE)

	CtrlNamedBackGround ExecuteDuringITI, start, period=30, proc=SkipSweepBackDuringITI_IGNORE

	PGC_SetAndActivateControl(str, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(str, "SetVar_DataAcq_ITI", val = 5)
End

Function SkipSweepsBackDuringITI_REENTRY([str])
	string str

	variable numSweeps = 4
	variable sweepNo   = 0
	variable headstage = 0

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), numSweeps)

	WAVE/T textualValues   = GetLBTextualValues(str)
	WAVE   numericalValues = GetLBNumericalValues(str)

	WAVE/T/Z foundStimSets = GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, STIM_WAVE_NAME_KEY, headstage, DATA_ACQUISITION_MODE)
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
