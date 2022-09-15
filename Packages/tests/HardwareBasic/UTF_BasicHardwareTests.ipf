#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=BasicHardwareTests

/// @file UTF_BasicHardWareTests.ipf Implement some basic tests using the DAQ hardware.

/// Test matrix for DQ_STOP_REASON_XXX
///
/// DQ_STOP_REASON_DAQ_BUTTON
/// - Abort_ITI_TP_A_PressAcq_MD
/// - Abort_ITI_TP_A_PressAcq_SD
/// - Abort_ITI_PressAcq_MD
/// - Abort_ITI_PressAcq_SD
///
/// DQ_STOP_REASON_CONFIG_FAILED
/// - ConfigureFails
///
/// DQ_STOP_REASON_FINISHED
/// - AllTests(...)
///
/// DQ_STOP_REASON_UNCOMPILED
/// - StopDAQDueToUncompiled
///
/// DQ_STOP_REASON_TP_STARTED
/// - Abort_ITI_TP_A_TP_MD
/// - Abort_ITI_TP_A_TP_SD
/// - Abort_ITI_TP_MD
/// - Abort_ITI_TP_SD
///
/// DQ_STOP_REASON_STIMSET_SELECTION
/// - ChangeStimSetDuringDAQ
///
/// DQ_STOP_REASON_UNLOCKED_DEVICE
/// - StopDAQDueToUnlocking
///
/// DQ_STOP_REASON_OUT_OF_MEMORY
/// DQ_STOP_REASON_HW_ERROR
/// DQ_STOP_REASON_ESCAPE_KEY
/// - not tested

static StrConstant REF_DAEPHYS_CONFIG_FILE = "DA_Ephys.json"
static StrConstant REF_TMP1_CONFIG_FILE = "UserConfigTemplate_Temp1.txt"

Function ActiveSetCountStimsets_IGNORE(device)
	string device

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "TrackActiveSetCount")
	ST_SetStimsetParameter("StimulusSetB_DA_0", "Analysis function (generic)", str = "TrackActiveSetCount")
	ST_SetStimsetParameter("StimulusSetC_DA_0", "Analysis function (generic)", str = "TrackActiveSetCount")
	ST_SetStimsetParameter("StimulusSetD_DA_0", "Analysis function (generic)", str = "TrackActiveSetCount")
End

static Function ActiveSetCount_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetC*")
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), str = "StimulusSetD*")
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function CheckActiveSetCountU([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L0_BKG1")
	AcquireData_BHT(s, str, postInitializeFunc = ActiveSetCountStimsets_IGNORE, preAcquireFunc = ActiveSetCount_IGNORE)
End

Function CheckActiveSetCountU_REENTRY([str])
	string str

	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	WaveTransform/O zapNans, anaFuncActiveSetCount
	CHECK_EQUAL_WAVES(anaFuncActiveSetCount, {2, 1, 3, 2, 1})
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function CheckActiveSetCountL([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L1_BKG1")
	AcquireData_BHT(s, str, postInitializeFunc = ActiveSetCountStimsets_IGNORE, preAcquireFunc = ActiveSetCount_IGNORE)
End

Function CheckActiveSetCountL_REENTRY([str])
	string str

	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	WaveTransform/O zapNans, anaFuncActiveSetCount
	CHECK_EQUAL_WAVES(anaFuncActiveSetCount, {2, 1, 3, 2, 1})
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

static Function CheckLastLBNEntryFromTP_IGNORE(device)
	string device

	variable index

	// last LBN entry is from TP
	WAVE numericalValues = GetLBNumericalValues(device)
	index = GetNumberFromWaveNote(numericalValues, NOTE_INDEX)
	CHECK_GE_VAR(index, 1)
	CHECK_EQUAL_VAR(numericalValues[index - 1][%EntrySourceType], TEST_PULSE_MODE)
End

static Function CheckThatTestpulseRan_IGNORE(device)
	string device
	variable sweepNo

	WAVE numericalValues = GetLBNumericalValues(device)
	sweepNo = AFH_GetLastSweepAcquired(device)
	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "ADC", TEST_PULSE_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD0
Function Abort_ITI_TP_SD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA1_I0_L0_BKG1_RES5")
	AcquireData_BHT(s, str)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
	CtrlNamedBackGround Abort_ITI_TP, start, period=30, proc=StartTPDuringITI_IGNORE

	PGC_SetAndActivateControl(str, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(str, "SetVar_DataAcq_ITI", val = 5)
End

Function Abort_ITI_TP_SD_REENTRY([str])
	string str

	NVAR runModeDAQ = $GetDataAcqRunMode(str)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(str)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	// check that TP after DAQ really ran
	CheckLastLBNEntryFromTP_IGNORE(str)

	CheckDAQStopReason(str, DQ_STOP_REASON_TP_STARTED)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function Abort_ITI_TP_MD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES5")
	AcquireData_BHT(s, str)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
	CtrlNamedBackGround Abort_ITI_TP, start, period=30, proc=StartTPDuringITI_IGNORE

	PGC_SetAndActivateControl(str, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(str, "SetVar_DataAcq_ITI", val = 5)
End

Function Abort_ITI_TP_MD_REENTRY([str])
	string str

	NVAR runModeDAQ = $GetDataAcqRunMode(str)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(str)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	// check that TP after DAQ really ran
	CheckLastLBNEntryFromTP_IGNORE(str)

	CheckDAQStopReason(str, DQ_STOP_REASON_TP_STARTED)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD0
Function Abort_ITI_TP_A_TP_SD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA1_I0_L0_BKG1_RES5")
	AcquireData_BHT(s, str)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
	CtrlNamedBackGround Abort_ITI_TP, start, period=30, proc=StartTPDuringITI_IGNORE

	PGC_SetAndActivateControl(str, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(str, "SetVar_DataAcq_ITI", val = 5)
	PGC_SetAndActivateControl(str, "check_Settings_TPAfterDAQ", val = 1)
End

Function Abort_ITI_TP_A_TP_SD_REENTRY([str])
	string str

	NVAR runModeDAQ = $GetDataAcqRunMode(str)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(str)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	// check that TP after DAQ really ran
	CheckLastLBNEntryFromTP_IGNORE(str)

	CheckDAQStopReason(str, DQ_STOP_REASON_TP_STARTED)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function Abort_ITI_TP_A_TP_MD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES5")
	AcquireData_BHT(s, str)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
	CtrlNamedBackGround Abort_ITI_TP, start, period=30, proc=StartTPDuringITI_IGNORE

	PGC_SetAndActivateControl(str, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(str, "SetVar_DataAcq_ITI", val = 5)
	PGC_SetAndActivateControl(str, "check_Settings_TPAfterDAQ", val = 1)
End

Function Abort_ITI_TP_A_TP_MD_REENTRY([str])
	string str

	NVAR runModeDAQ = $GetDataAcqRunMode(str)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(str)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	// check that TP after DAQ really ran
	CheckLastLBNEntryFromTP_IGNORE(str)

	CheckDAQStopReason(str, DQ_STOP_REASON_TP_STARTED)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function AbortTP([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES0")
	AcquireData_BHT(s, str, startTPInstead=1)

	CtrlNamedBackGround DelayReentry, start=(ticks + 300), period=60, proc=JustDelay_IGNORE
	RegisterUTFMonitor("DelayReentry", BACKGROUNDMONMODE_AND, "AbortTP_REENTRY", timeout = 600, failOnTimeout = 1)
End

Function AbortTP_REENTRY([str])
	string str

	string device
	variable aborted, err

	device = StringFromList(0, str)

	KillWindow $device
	try
		ASYNC_STOP(timeout = 5)
	catch
		err = getRTError(1)
		aborted = 1
	endtry

	ASYNC_Start(threadprocessorCount, disableTask=1)

	if(aborted)
		FAIL()
	else
		PASS()
	endif
End

Function StartDAQDuringTP_IGNORE(device)
	string device

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "WriteIntoLBNOnPreDAQ")
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD0
Function StartDAQDuringTP([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA0_I0_L0_BKG1_RES0")
	AcquireData_BHT(s, str, startTPInstead=1, postInitializeFunc=StartDAQDuringTP_IGNORE)

	CtrlNamedBackGround StartDAQDuringTP, start=(ticks + 600), period=100, proc=StartAcq_IGNORE
End

Function StartDAQDuringTP_REENTRY([str])
	string str

	variable sweepNo
	string device

	device = StringFromList(0, str)

	NVAR runModeDAQ = $GetDataAcqRunMode(device)

	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(device)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	sweepNo = AFH_GetLastSweepAcquired(device)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "USER_GARBAGE", UNKNOWN_MODE)
	CHECK_WAVE(settings, FREE_WAVE)
	CHECK_EQUAL_WAVES(settings, {0, 1, 2, 3, 4, 5, 6, 7, NaN}, mode = WAVE_DATA)

	// ascending sweep numbers are checked in TEST_CASE_BEGIN_OVERRIDE()
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD0
Function Abort_ITI_PressAcq_SD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA1_I0_L0_BKG1_RES5")
	AcquireData_BHT(s, str)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
	CtrlNamedBackGround Abort_ITI_PressAcq, start, period=30, proc=StopAcqDuringITI_IGNORE

	PGC_SetAndActivateControl(str, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(str, "SetVar_DataAcq_ITI", val = 5)
End

Function Abort_ITI_PressAcq_SD_REENTRY([str])
	string str

	NVAR runModeDAQ = $GetDataAcqRunMode(str)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(str)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	CheckThatTestpulseRan_IGNORE(str)

	CheckDAQStopReason(str, DQ_STOP_REASON_DAQ_BUTTON)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function Abort_ITI_PressAcq_MD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES5")
	AcquireData_BHT(s, str)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
	CtrlNamedBackGround Abort_ITI_PressAcq, start, period=30, proc=StopAcqDuringITI_IGNORE

	PGC_SetAndActivateControl(str, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(str, "SetVar_DataAcq_ITI", val = 5)
End

Function Abort_ITI_PressAcq_MD_REENTRY([str])
	string str

	NVAR runModeDAQ = $GetDataAcqRunMode(str)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(str)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	CheckThatTestpulseRan_IGNORE(str)

	CheckDAQStopReason(str, DQ_STOP_REASON_DAQ_BUTTON)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD0
Function Abort_ITI_TP_A_PressAcq_SD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA1_I0_L0_BKG1_RES5")
	AcquireData_BHT(s, str)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
	CtrlNamedBackGround Abort_ITI_PressAcq, start, period=30, proc=StopAcqDuringITI_IGNORE

	PGC_SetAndActivateControl(str, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(str, "SetVar_DataAcq_ITI", val = 5)
	PGC_SetAndActivateControl(str, "check_Settings_TPAfterDAQ", val = 1)
End

Function Abort_ITI_TP_A_PressAcq_SD_REENTRY([str])
	string str

	NVAR runModeDAQ = $GetDataAcqRunMode(str)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(str)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	// check that TP after DAQ really ran
	CheckLastLBNEntryFromTP_IGNORE(str)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function Abort_ITI_TP_A_PressAcq_MD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES5")
	AcquireData_BHT(s, str)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
	CtrlNamedBackGround Abort_ITI_Acq, start, period=30, proc=StopAcqDuringITI_IGNORE

	PGC_SetAndActivateControl(str, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(str, "SetVar_DataAcq_ITI", val = 5)
	PGC_SetAndActivateControl(str, "check_Settings_TPAfterDAQ", val = 1)
End

Function Abort_ITI_TP_A_PressAcq_MD_REENTRY([str])
	string str

	NVAR runModeDAQ = $GetDataAcqRunMode(str)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(str)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	// check that TP after DAQ really ran
	CheckLastLBNEntryFromTP_IGNORE(str)

	CheckDAQStopReason(str, DQ_STOP_REASON_DAQ_BUTTON)
End

static Function SetSingleDeviceDAQ_IGNORE(device)
	string device

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetA_DA_0
	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set] = "ChangeToSingleDeviceDAQAF"
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD0
Function ChangeToSingleDeviceDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, postInitializeFunc=SetSingleDeviceDAQ_IGNORE)
End

Function ChangeToSingleDeviceDAQ_REENTRY([str])
	string str

	string device
	variable sweepNo, multiDeviceMode

	device = StringFromList(0, str)

	CHECK_EQUAL_VAR(GetCheckBoxState(device, "check_Settings_MD"), CHECKBOX_UNSELECTED)

	sweepNo = AFH_GetLastSweepAcquired(device)
	WAVE numericalValues = GetLBNumericalValues(device)
	multiDeviceMode = GetLastSettingIndep(numericalValues, sweepNo, "Multi device mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(multiDeviceMode, 0)
End

static Function SetMultiDeviceDAQ_IGNORE(device)
	string device

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetA_DA_0
	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set] = "ChangeToMultiDeviceDAQAF"
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function ChangeToMultiDeviceDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA0_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, postInitializeFunc=SetMultiDeviceDAQ_IGNORE)
End

Function ChangeToMultiDeviceDAQ_REENTRY([str])
	string str
	string device
	variable sweepNo, multiDeviceMode

	device = StringFromList(0, str)

	CHECK_EQUAL_VAR(GetCheckBoxState(device, "check_Settings_MD"), CHECKBOX_SELECTED)

	sweepNo = AFH_GetLastSweepAcquired(device)
	WAVE numericalValues = GetLBNumericalValues(device)
	multiDeviceMode = GetLastSettingIndep(numericalValues, sweepNo, "Multi device mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(multiDeviceMode, 1)
End

Function ChangeStimSetDuringDAQ_IGNORE(string device)

	PGC_SetAndActivateControl(device, "check_Settings_TPAfterDAQ", val = 1)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 600), period=60, proc=StopTP_IGNORE
	CtrlNamedBackGround ChangeStimsetDuringDAQ, start, period=30, proc=ChangeStimSet_IGNORE
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function ChangeStimSetDuringDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc = ChangeStimSetDuringDAQ_IGNORE)
End

Function ChangeStimSetDuringDAQ_REENTRY([str])
	string str

	string device
	variable numEntries, i

	numEntries = ItemsInList(str)
	for(i = 0; i < numEntries; i += 1)
		device = stringFromList(i, str)

		NVAR runModeDAQ = $GetDataAcqRunMode(device)
		CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

		NVAR runModeTP = $GetTestpulseRunMode(device)
		CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)
	endfor

	CheckDAQStopReason(str, DQ_STOP_REASON_STIMSET_SELECTION)

	// even with TP after DAQ we have "finished" as reason
	CheckDAQStopReason(str, DQ_STOP_REASON_FINISHED, sweepNo = 2)
End

Function EnableUnassocChannels_IGNORE(device)
	string device

	// enable HS2 with associated DA/AD channels
	PGC_SetAndActivateControl(device, GetPanelControl(2, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)

	// cut assocication
	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", str = "2")
	PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")

	// disable HS2
	PGC_SetAndActivateControl(device, GetPanelControl(2, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=0)

	PGC_SetAndActivateControl(device, GetPanelControl(2, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetA*")

	// enable TTL1
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK), val=1)
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE), str="StimulusSetA*")

	// enable TTL3
	PGC_SetAndActivateControl(device, GetPanelControl(3, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK), val=1)
	PGC_SetAndActivateControl(device, GetPanelControl(3, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE), str="StimulusSetB*")

	if(HW_ITC_GetNumberOfRacks(device) > 1)
		// enable TTL channels on rack two

		// enable TTL5
		PGC_SetAndActivateControl(device, GetPanelControl(5, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK), val=1)
		PGC_SetAndActivateControl(device, GetPanelControl(5, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE), str="StimulusSetA*")

		// enable TTL7
		PGC_SetAndActivateControl(device, GetPanelControl(7, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK), val=1)
		PGC_SetAndActivateControl(device, GetPanelControl(7, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE), str="StimulusSetB*")
	endif
End

// Using unassociated channels works
// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function UnassociatedChannelsAndTTLs([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc = EnableUnassocChannels_IGNORE)
End

Function UnassociatedChannelsAndTTLs_REENTRY([str])
	string str

	string device, sweeps, configs, unit, expectedStr
	variable numEntries, i, j, k, numSweeps

	numSweeps = 1

	numEntries = ItemsInList(str)
	for(i = 0; i < numEntries; i += 1)
		device = stringFromList(i, str)

		CHECK_EQUAL_VAR(GetSetVariable(device, "SetVar_Sweep"), numSweeps)
		sweeps  = GetListOfObjects(GetDeviceDataPath(device), DATA_SWEEP_REGEXP, fullPath = 1)
		configs = GetListOfObjects(GetDeviceDataPath(device), DATA_CONFIG_REGEXP, fullPath = 1)

		CHECK_EQUAL_VAR(ItemsInList(sweeps), numSweeps)
		CHECK_EQUAL_VAR(ItemsInList(configs), numSweeps)

		WAVE/T textualValues   = GetLBTextualValues(device)
		WAVE   numericalValues = GetLBNumericalValues(device)

		for(j = 0; j < numSweeps; j += 1)
			WAVE/Z sweep  = $StringFromList(j, sweeps)
			CHECK_WAVE(sweep, NUMERIC_WAVE, minorType = IGOR_TYPE_32bit_FLOAT)

			WAVE/Z config = $StringFromList(j, configs)
			CHECK_WAVE(config, NUMERIC_WAVE)

			CHECK_EQUAL_VAR(DimSize(config, ROWS), DimSize(sweep, COLS))

			switch(GetHardwareType(device))
				case HARDWARE_ITC_DAC:
					CHECK_EQUAL_VAR(DimSize(config, ROWS), 7)
					break
				case HARDWARE_NI_DAC:
					CHECK_EQUAL_VAR(DimSize(config, ROWS), 8)
					break
			endswitch

			// check channel types
			CHECK_EQUAL_VAR(config[0][0], XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_VAR(config[1][0], XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_VAR(config[2][0], XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_VAR(config[3][0], XOP_CHANNEL_TYPE_ADC)
			CHECK_EQUAL_VAR(config[4][0], XOP_CHANNEL_TYPE_ADC)
			CHECK_EQUAL_VAR(config[5][0], XOP_CHANNEL_TYPE_ADC)
			CHECK_EQUAL_VAR(config[6][0], XOP_CHANNEL_TYPE_TTL)

			// check channel numbers
			WAVE DACs = GetDACListFromConfig(config)
			CHECK_EQUAL_WAVES(DACs, {0, 1, 2}, mode = WAVE_DATA)

			WAVE ADCs = GetADCListFromConfig(config)
			CHECK_EQUAL_WAVES(ADCs, {0, 1, 2}, mode = WAVE_DATA)

			WAVE TTLs = GetTTLListFromConfig(config)

			WAVE/Z ttlStimSets = GetTTLLabnotebookEntry(textualValues, LABNOTEBOOK_TTL_STIMSETS, j)
			CHECK_EQUAL_TEXTWAVES(ttlStimSets, {"", "StimulusSetA_TTL_0", "", "StimulusSetB_TTL_0", "", "", "", ""})

			switch(GetHardwareType(device))
				case HARDWARE_ITC_DAC:
					// check TTL LBN keys
					if(HW_ITC_GetNumberOfRacks(device) > 1)
						CHECK_EQUAL_WAVES(TTLs, {HW_ITC_GetITCXOPChannelForRack(device, RACK_ZERO), \
												 HW_ITC_GetITCXOPChannelForRack(device, RACK_ONE)}, mode = WAVE_DATA)
					else
						CHECK_EQUAL_WAVES(TTLs, {HW_ITC_GetITCXOPChannelForRack(device, RACK_ZERO)}, mode = WAVE_DATA)
					endif

					WAVE/T/Z foundStimSets = GetLastSetting(textualValues, j, "TTL rack zero stim sets", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(foundStimSets, {"", "", "", "", "", "", "", "", ";StimulusSetA_TTL_0;;StimulusSetB_TTL_0;"})
					WAVE/T/Z foundStimSets = GetLastSetting(textualValues, j, "TTL rack one stim sets", DATA_ACQUISITION_MODE)

					if(HW_ITC_GetNumberOfRacks(device) > 1)
						CHECK_EQUAL_TEXTWAVES(foundStimSets, {"", "", "", "", "", "", "", "", ";StimulusSetA_TTL_0;;StimulusSetB_TTL_0;"})
					else
						CHECK_WAVE(foundStimSets, NULL_WAVE)
					endif

					CHECK_EQUAL_VAR(NUM_ITC_TTL_BITS_PER_RACK, 4)

					WAVE/Z bits = GetLastSetting(numericalValues, j, "TTL rack zero bits", DATA_ACQUISITION_MODE)
					// TTL 1 and 3 are active -> 2^1 + 2^3 = 10
					CHECK_EQUAL_WAVES(bits, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 10}, mode = WAVE_DATA)
					WAVE/Z bits = GetLastSetting(numericalValues, j, "TTL rack one bits", DATA_ACQUISITION_MODE)

					if(HW_ITC_GetNumberOfRacks(device) > 1)
						// TTL 5 and 7 are active -> 2^(5 - 4) + 2^(7 - 4) = 10
						CHECK_EQUAL_WAVES(bits, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 10}, mode = WAVE_DATA)
					else
						CHECK_WAVE(bits, NULL_WAVE)
					endif

					WAVE/Z channels = GetLastSetting(numericalValues, j, "TTL rack zero channel", DATA_ACQUISITION_MODE)

					if(HW_ITC_GetNumberOfRacks(device) > 1)
						CHECK_EQUAL_VAR(DimSize(TTLs, ROWS), 2)
					else
						CHECK_EQUAL_VAR(DimSize(TTLs, ROWS), 1)
					endif

					CHECK_EQUAL_WAVES(channels, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, TTLs[0]}, mode = WAVE_DATA)
					WAVE/Z channels = GetLastSetting(numericalValues, j, "TTL rack one channel", DATA_ACQUISITION_MODE)
					if(HW_ITC_GetNumberOfRacks(device) > 1)
						CHECK_EQUAL_WAVES(channels, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, TTLs[1]}, mode = WAVE_DATA)
					else
						CHECK_WAVE(channels, NULL_WAVE)
					endif

					// set sweep count
					WAVE/T/Z sweepCounts = GetLastSetting(textualValues, j, "TTL rack zero set sweep counts", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(sweepCounts, {"", "", "", "", "", "", "", "", ";0;;0;"})
					WAVE/T/Z sweepCounts = GetLastSetting(textualValues, j, "TTL rack one set sweep counts", DATA_ACQUISITION_MODE)
					if(HW_ITC_GetNumberOfRacks(device) > 1)
						CHECK_EQUAL_TEXTWAVES(sweepCounts, {"", "", "", "", "", "", "", "", ";0;;0;"})
					else
						CHECK_WAVE(sweepCounts, NULL_WAVE)
					endif

					// set cycle count
					WAVE/T/Z cycleCounts = GetLastSetting(textualValues, j, "TTL rack zero set cycle counts", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(cycleCounts, {"", "", "", "", "", "", "", "", ";0;;0;"})
					WAVE/T/Z cycleCounts = GetLastSetting(textualValues, j, "TTL rack one set cycle counts", DATA_ACQUISITION_MODE)
					if(HW_ITC_GetNumberOfRacks(device) > 1)
						CHECK_EQUAL_TEXTWAVES(cycleCounts, {"", "", "", "", "", "", "", "", ";0;;0;"})
					else
						CHECK_WAVE(cycleCounts, NULL_WAVE)
					endif

					break
				case HARDWARE_NI_DAC:
					CHECK_EQUAL_WAVES(TTLs, {1, 3}, mode = WAVE_DATA)

					WAVE/T/Z channelsTxT = GetLastSetting(textualValues, j, "TTL channels", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(channelsTxT, {"", "", "", "", "", "", "", "", ";1;;3;;;;;"}, mode = WAVE_DATA)

					WAVE/T/Z foundStimSets = GetLastSetting(textualValues, j, "TTL stim sets", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(foundStimSets, {"", "", "", "", "", "", "", "", ";StimulusSetA_TTL_0;;StimulusSetB_TTL_0;;;;;"})

					WAVE/T/Z sweepCounts = GetLastSetting(textualValues, j, "TTL set sweep counts", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(sweepCounts, {"", "", "", "", "", "", "", "", ";0;;0;;;;;"})

					WAVE/T/Z cycleCounts = GetLastSetting(textualValues, j, "TTL set cycle counts", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(cycleCounts, {"", "", "", "", "", "", "", "", ";0;;0;;;;;"})

					break
			endswitch

			// hardware agnostic TTL entries
			WAVE/T/Z foundIndexingEndStimSets = GetLastSetting(textualValues, j, "TTL Indexing End stimset", DATA_ACQUISITION_MODE)
			CHECK_EQUAL_TEXTWAVES(foundIndexingEndStimSets, {"", "", "", "", "", "", "", "", ";- none -;;- none -;;;;;"})

			WAVE/Z settings = GetLastSetting(textualValues, j, "TTL Stimset wave note", DATA_ACQUISITION_MODE)
			CHECK_WAVE(settings, TEXT_WAVE)

			WAVE/T/Z stimWaveChecksums = GetLastSetting(textualValues, j, "TTL Stim Wave Checksum", DATA_ACQUISITION_MODE)
			CHECK(GrepString(stimWaveChecksums[INDEP_HEADSTAGE], ";[[:digit:]]+;;[[:digit:]]+;;;;;"))

			WAVE/Z stimSetLengths = GetLastSetting(textualValues, j, "TTL Stim set length", DATA_ACQUISITION_MODE)
			CHECK_EQUAL_TEXTWAVES(stimSetLengths, {"", "", "", "", "", "", "", "", ";190001;;185001;;;;;"})

			Variable index

			// fetch some labnotebook entries, the last channel is unassociated
			for(k = 0; k < DimSize(ADCs, ROWS); k += 1)
				[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", j, "AD ChannelType", ADCs[k], XOP_CHANNEL_TYPE_ADC, DATA_ACQUISITION_MODE)
				CHECK_EQUAL_VAR(settings[index], DAQ_CHANNEL_TYPE_DAQ)

				[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, j, "AD Unit", ADCs[k], XOP_CHANNEL_TYPE_ADC, DATA_ACQUISITION_MODE)
				WAVE/T settingsText = settings
				str = settingsText[index]
				expectedStr= "pA"
				CHECK_EQUAL_STR(str, expectedStr)
			endfor

			for(k = 0; k < DimSize(DACs, ROWS); k += 1)
				[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", j, "DA ChannelType", DACs[k], XOP_CHANNEL_TYPE_DAC, DATA_ACQUISITION_MODE)
				CHECK_EQUAL_VAR(settings[index], DAQ_CHANNEL_TYPE_DAQ)

				[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, j, "DA Unit", DACs[k], XOP_CHANNEL_TYPE_DAC, DATA_ACQUISITION_MODE)
				WAVE/T settingsText = settings
				str = settingsText[index]
				expectedStr= "mV"
				CHECK_EQUAL_STR(str, expectedStr)
			endfor

			// test GetActiveChannels
			WAVE DA  = GetActiveChannels(numericalValues, textualValues, j, XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_WAVES(DA, {0, 1, 2, NaN, NaN, NaN, NaN, NaN})

			WAVE AD  = GetActiveChannels(numericalValues, textualValues, j, XOP_CHANNEL_TYPE_ADC)
			CHECK_EQUAL_WAVES(AD, {0, 1, 2, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN})

			WAVE TTL = GetActiveChannels(numericalValues, textualValues, j, XOP_CHANNEL_TYPE_TTL, TTLmode = TTL_DAEPHYS_CHANNEL)
			CHECK_EQUAL_WAVES(TTL, {NaN, 1, NaN, 3, NaN, NaN, NaN, NaN})

			WAVE TTL = GetActiveChannels(numericalValues, textualValues, j, XOP_CHANNEL_TYPE_TTL, TTLmode = TTL_HARDWARE_CHANNEL)

			if(GetHardwareType(device) == HARDWARE_NI_DAC)
				Make/FREE/D TTLRef = {NaN, 1, NaN, 3, NaN, NaN, NaN, NaN}
			else
				Make/FREE/D/N=(NUM_DA_TTL_CHANNELS) TTLRef = NaN
				index = HW_ITC_GetITCXOPChannelForRack(device, RACK_ZERO)
				TTLRef[index] = index
			endif

			CHECK_EQUAL_WAVES(TTL, TTLRef)
		endfor
	endfor

	if(DoExpensiveChecks())
		TestNwbExportV1()
		TestNwbExportV2()
	endif
End

static Function GetMinSampInt_IGNORE([unit])
	string unit

	variable factor

	if(ParamIsDefault(unit))
		FAIL()
	elseif(cmpstr(unit, "µs"))
		factor = 1
	elseif(cmpstr(unit, "ms"))
		factor = 1000
	else
		FAIL()
	endif

#ifdef TESTS_WITH_NI_HARDWARE
	return factor * HARDWARE_NI_DAC_MIN_SAMPINT
#else
	return factor * HARDWARE_ITC_MIN_SAMPINT
#endif
End

static Function DisableSecondHeadstage_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=0)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function CheckSamplingInterval1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc=DisableSecondHeadstage_IGNORE)
End

Function CheckSamplingInterval1_REENTRY([str])
	string str

	variable sweepNo, sampInt, sampIntMult, fixedFreqAcq, expectedSampInt

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, sweepNo)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NORMAL_WAVE)

	sampInt = GetSamplingInterval(configWave)
	CHECK_CLOSE_VAR(sampInt, GetMinSampInt_IGNORE(unit="µs"), tol=1e-6)

	WAVE numericalValues = GetLBNumericalValues(str)

	sampInt = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval", DATA_ACQUISITION_MODE)
	expectedSampInt = GetMinSampInt_IGNORE(unit="ms")
	CHECK_CLOSE_VAR(sampInt, expectedSampInt, tol=1e-6)

	sampIntMult = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval multiplier", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(sampIntMult, 1)

	fixedFreqAcq = GetLastSettingIndep(numericalValues, sweepNo, "Fixed frequency acquisition", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(fixedFreqAcq, NaN)

	CHECK_EQUAL_VAR(DimOffset(sweepWave, ROWS), 0)
	CHECK_CLOSE_VAR(DimDelta(sweepWave, ROWS), expectedSampInt, tol=1e-6)
End

Function UseSamplingInterval_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=0)
	PGC_SetAndActivateControl(device, "Popup_Settings_SampIntMult", str="8")
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function CheckSamplingInterval2([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc=UseSamplingInterval_IGNORE)
End

Function CheckSamplingInterval2_REENTRY([str])
	string str

	variable sweepNo, sampInt, sampIntMult, fixedFreqAcq, expectedSampInt

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, sweepNo)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NORMAL_WAVE)

	sampInt = GetSamplingInterval(configWave)
	CHECK_CLOSE_VAR(sampInt, GetMinSampInt_IGNORE(unit="µs") * 8, tol=1e-6)

	WAVE numericalValues = GetLBNumericalValues(str)

	sampInt = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval", DATA_ACQUISITION_MODE)
	expectedSampInt = GetMinSampInt_IGNORE(unit="ms") * 8
	CHECK_CLOSE_VAR(sampInt, expectedSampInt, tol=1e-6)

	sampIntMult = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval multiplier", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(sampIntMult, 8)

	fixedFreqAcq = GetLastSettingIndep(numericalValues, sweepNo, "Fixed frequency acquisition", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(fixedFreqAcq, NaN)

	CHECK_EQUAL_VAR(DimOffset(sweepWave, ROWS), 0)
	CHECK_CLOSE_VAR(DimDelta(sweepWave, ROWS), expectedSampInt, tol=1e-6)
End

static Function UseFixedFrequency_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=0)
	PGC_SetAndActivateControl(device, "Popup_Settings_FixedFreq", str="100")
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function CheckSamplingInterval3([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc=UseFixedFrequency_IGNORE)
End

Function CheckSamplingInterval3_REENTRY([str])
	string str

	variable sweepNo, sampInt, sampIntMult, fixedFreqAcq, expectedSampInt

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, sweepNo)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NORMAL_WAVE)

	sampInt = GetSamplingInterval(configWave)
	CHECK_CLOSE_VAR(sampInt, 10, tol=1e-6)

	WAVE numericalValues = GetLBNumericalValues(str)

	sampInt = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval", DATA_ACQUISITION_MODE)
	expectedSampInt = 0.010
	CHECK_CLOSE_VAR(sampInt, expectedSampInt, tol=1e-6)

	sampIntMult = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval multiplier", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(sampIntMult, 1)

	fixedFreqAcq = GetLastSettingIndep(numericalValues, sweepNo, "Fixed frequency acquisition", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(fixedFreqAcq, 100)

	CHECK_EQUAL_VAR(DimOffset(sweepWave, ROWS), 0)
	CHECK_CLOSE_VAR(DimDelta(sweepWave, ROWS), expectedSampInt, tol=1e-6)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function ChangeCMDuringSweep([str])
	string str

	string ctrl

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 1)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	CtrlNamedBackGround ChangeClampModeDuringSweep, start, period=30, proc=ClampModeDuringSweep_IGNORE
End

Function ChangeCMDuringSweep_REENTRY([str])
	string str

	variable sweepNo
	string ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	ctrl = DAP_GetClampModeControl(I_CLAMP_MODE, 1)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE clampMode = GetLastSetting(numericalValues, 0, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 1, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 2, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

Function EnableApplyOnModeSwitch_IGNORE(device)
	string device

	string ctrl

	ctrl = GetPanelControl(CHANNEL_INDEX_ALL_I_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	PGC_SetAndActivateControl(device, ctrl, str = "StimulusSetE_DA_0")

	ctrl = GetPanelControl(CHANNEL_INDEX_ALL_V_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	PGC_SetAndActivateControl(device, ctrl, str = "StimulusSetF_DA_0")

	ctrl = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	PGC_SetAndActivateControl(device, ctrl, str = "StimulusSetA_DA_0")

	ctrl = GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	PGC_SetAndActivateControl(device, ctrl, str = "StimulusSetC_DA_0")

	PGC_SetAndActivateControl(device, "check_DA_applyOnModeSwitch", val=1)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function ChangeCMDuringSweepWMS([str])
	string str

	string ctrl

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc=EnableApplyOnModeSwitch_IGNORE)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 1)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	CtrlNamedBackGround ChangeClampModeDuringSweep, start, period=30, proc=ClampModeDuringSweep_IGNORE
End

Function ChangeCMDuringSweepWMS_REENTRY([str])
	string str

	variable sweepNo
	string ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	ctrl = DAP_GetClampModeControl(I_CLAMP_MODE, 1)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE clampMode = GetLastSetting(numericalValues, 0, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode= WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 1, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 2, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/T textualValues   = GetLBTextualValues(str)
	WAVE   numericalValues = GetLBNumericalValues(str)

	// the stimsets are not changed as this is delayed clamp mode change in action
	WAVE/T/Z foundStimSets = GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, STIM_WAVE_NAME_KEY, 0, DATA_ACQUISITION_MODE)
	REQUIRE_WAVE(foundStimSets, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(foundStimSets, {"StimulusSetA_DA_0", "StimulusSetA_DA_0", "StimulusSetA_DA_0"})

	WAVE/T/Z foundStimSets = GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, STIM_WAVE_NAME_KEY, 1, DATA_ACQUISITION_MODE)
	REQUIRE_WAVE(foundStimSets, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(foundStimSets, {"StimulusSetC_DA_0", "StimulusSetC_DA_0", "StimulusSetC_DA_0"})
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function ChangeCMDuringSweepNoRA([str])
	string str

	string ctrl

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 1)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	CtrlNamedBackGround ChangeClampModeDuringSweep, start, period=30, proc=ClampModeDuringSweep_IGNORE
End

Function ChangeCMDuringSweepNoRA_REENTRY([str])
	string str

	variable sweepNo
	string ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	ctrl = DAP_GetClampModeControl(I_CLAMP_MODE, 1)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE clampMode = GetLastSetting(numericalValues, 0, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

Function ITISetupNoTP_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val=0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val=5)
	PGC_SetAndActivateControl(device, "check_Settings_ITITP", val=0)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function ChangeCMDuringITI([str])
	string str

	string ctrl

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc=ITISetupNoTP_IGNORE)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 1)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	CtrlNamedBackGround ChangeClampModeDuringSweep, start, period=30, proc=ClampModeDuringITI_IGNORE
End

Function ChangeCMDuringITI_REENTRY([str])
	string str

	variable sweepNo
	string ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	ctrl = DAP_GetClampModeControl(I_CLAMP_MODE, 1)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE clampMode = GetLastSetting(numericalValues, 0, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 1, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 2, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

Function ITISetupWithTP_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val=0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val=5)
	PGC_SetAndActivateControl(device, "check_Settings_ITITP", val=1)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function ChangeCMDuringITIWithTP([str])
	string str

	string ctrl

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc=ITISetupWithTP_IGNORE)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 1)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	RegisterUTFMonitor(TASKNAMES + "DAQWatchdog;TPWatchdog;ChangeClampModeDuringSweep", BACKGROUNDMONMODE_AND, \
					   "ChangeCMDuringITIWithTP_REENTRY", timeout = 600)

	CtrlNamedBackGround ChangeClampModeDuringSweep, start, period=10, proc=ClampModeDuringITI_IGNORE
End

Function ChangeCMDuringITIWithTP_REENTRY([str])
	string str

	variable sweepNo
	string ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	ctrl = DAP_GetClampModeControl(I_CLAMP_MODE, 1)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE clampMode = GetLastSetting(numericalValues, 0, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 1, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 2, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

Function TPDuringDAQOnlyTP_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function AutoPipetteOffsetIgnoresApplyOnModeSwitch([str])
	string str

	string ctrl

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc=EnableApplyOnModeSwitch_IGNORE, startTPInstead = 1)

	CtrlNamedBackGround DelayReentry, start=(ticks + 300), period=60, proc=AutoPipetteOffsetAndStopTP_IGNORE
	RegisterUTFMonitor("DelayReentry", BACKGROUNDMONMODE_AND, "AutoPipetteOffsetIgnoresApplyOnModeSwitch_REENTRY", timeout = 600, failOnTimeout = 1)
End

Function AutoPipetteOffsetIgnoresApplyOnModeSwitch_REENTRY([str])
	string str

	variable sweepNo
	string ctrl, stimset, expected

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	CHECK_EQUAL_VAR(GetCheckBoxState(str, "check_DA_applyOnModeSwitch"), 1)

	ctrl = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	stimset = GetPopupMenuString(str, ctrl)
	expected = "StimulusSetA_DA_0"
	CHECK_EQUAL_STR(stimset, expected)

	ctrl = GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	stimset = GetPopupMenuString(str, ctrl)
	expected = "StimulusSetC_DA_0"
	CHECK_EQUAL_STR(stimset, expected)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function TPDuringDAQOnlyTP([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc=TPDuringDAQOnlyTP_IGNORE)
End

Function TPDuringDAQOnlyTP_REENTRY([str])
	string str

	variable sweepNo, col
	string ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, 0)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	CHECK_EQUAL_VAR(GetMinSampInt_IGNORE(unit = "ms"), DimDelta(sweepWave, ROWS))
	CHECK_EQUAL_VAR(DimSize(sweepWave, ROWS) * DimDelta(sweepWave, ROWS) / 1000, TIME_TP_ONLY_ON_DAQ)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NORMAL_WAVE)
	CHECK_EQUAL_VAR(DimSize(configWave, ROWS), 2)
	CHECK_EQUAL_VAR(DimSize(configWave, COLS), 6)

	col = FindDimLabel(configWave, COLS, "DAQChannelType")
	Duplicate/FREE/R=[][col] configWave, channelTypes
	Redimension/N=-1 channelTypes
	CHECK_EQUAL_WAVES(channelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_TP}, mode = WAVE_DATA)

	WAVE/T units = AFH_GetChannelUnits(configWave)
	CHECK_EQUAL_TEXTWAVES(units, {"mV", "pA"}, mode = WAVE_DATA)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues = GetLBTextualValues(str)

	WAVE DAChannelTypes = GetLastSetting(numericalValues, sweepNo, "DA ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(DAChannelTypes, {DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE ADChannelTypes = GetLastSetting(numericalValues, sweepNo, "AD ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(ADChannelTypes, {DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSetting(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
	WAVE/Z tpAmplitude = GetLastSetting(numericalValues, sweepNo, TP_AMPLITUDE_VC_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_WAVE(tpAmplitude, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(stimScale, {tpAmplitude[0], NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z/T stimsets = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_TEXTWAVES(stimsets, {"TestPulse", "", "", "", "", "", "", "", ""}, mode = WAVE_DATA)
End

Function TPDuringDAQOnlyTPWithLockedIndexing_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), str = NONE)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SEARCH), str = "Test*")

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function TPDuringDAQOnlyTPWithLockedIndexing([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L0_BKG1_RES3")
	AcquireData_BHT(s, str, preAcquireFunc=TPDuringDAQOnlyTPWithLockedIndexing_IGNORE)
End

Function TPDuringDAQOnlyTPWithLockedIndexing_REENTRY([str])
	string str

	variable sweepNo, col, tpAmplitude
	string ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	// generic properties are checked in TPDuringDAQOnlyTP
End

Function TPDuringDAQTPAndAssoc_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")

	// cut association
	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", str = "1")
	PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")

	// disable HS1
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function TPDuringDAQTPAndAssoc([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc=TPDuringDAQTPAndAssoc_IGNORE)
End

Function TPDuringDAQTPAndAssoc_REENTRY([str])
	string str

	variable sweepNo, col, channelTypeUnassoc, stimScaleUnassoc
	string ctrl, stimsetUnassoc, stimsetUnassocRef, key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, 0)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	CHECK_EQUAL_VAR(2 * GetMinSampInt_IGNORE(unit = "ms"), DimDelta(sweepWave, ROWS))
	CHECK_EQUAL_VAR(DimSize(sweepWave, ROWS) * DimDelta(sweepWave, ROWS) / 1000, TIME_TP_ONLY_ON_DAQ)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NORMAL_WAVE)
	CHECK_EQUAL_VAR(DimSize(configWave, ROWS), 4)
	CHECK_EQUAL_VAR(DimSize(configWave, COLS), 6)

	col = FindDimLabel(configWave, COLS, "DAQChannelType")
	Duplicate/FREE/R=[][col] configWave, channelTypes
	Redimension/N=-1 channelTypes

	// the unassociated AD channel is in DAQ mode
	CHECK_EQUAL_WAVES(channelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ}, mode = WAVE_DATA)

	WAVE/T units = AFH_GetChannelUnits(configWave)
	CHECK_EQUAL_TEXTWAVES(units, {"mV", "mV", "pA", "pA"}, mode = WAVE_DATA)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues = GetLBTextualValues(str)

	WAVE/Z setCycleCount = GetLastSetting(numericalValues, sweepNo, "Set Cycle Count", DATA_ACQUISITION_MODE)
	CHECK_WAVE(setCycleCount, NULL_WAVE)

	WAVE DAChannelTypes = GetLastSetting(numericalValues, sweepNo, "DA ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(DAChannelTypes, {DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE ADChannelTypes = GetLastSetting(numericalValues, sweepNo, "AD ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(ADChannelTypes, {DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	key = CreateLBNUnassocKey("DA ChannelType", 1, XOP_CHANNEL_TYPE_DAC)
	channelTypeUnassoc = GetLastSettingIndep(numericalValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(channelTypeUnassoc, DAQ_CHANNEL_TYPE_TP)

	key = CreateLBNUnassocKey("AD ChannelType", 1, XOP_CHANNEL_TYPE_ADC)
	channelTypeUnassoc = GetLastSettingIndep(numericalValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(channelTypeUnassoc, DAQ_CHANNEL_TYPE_DAQ)

	WAVE/Z stimScale = GetLastSetting(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
	WAVE/Z tpAmplitude = GetLastSetting(numericalValues, sweepNo, TP_AMPLITUDE_VC_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_WAVE(tpAmplitude, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(stimScale, {tpAmplitude[0], NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	key = CreateLBNUnassocKey(STIMSET_SCALE_FACTOR_KEY, 1, XOP_CHANNEL_TYPE_DAC)
	stimScaleUnassoc = GetLastSettingIndep(numericalValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(stimScaleUnassoc, 0.0)

	WAVE/Z/T stimsets = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_TEXTWAVES(stimsets, {"TestPulse", "", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	key = CreateLBNUnassocKey(STIM_WAVE_NAME_KEY, 1, XOP_CHANNEL_TYPE_DAC)
	stimsetUnassoc = GetLastSettingTextIndep(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	stimsetUnassocRef = "TestPulse"
	CHECK_EQUAL_STR(stimsetUnassoc, stimsetUnassocRef)
End

Function TPDuringDAQ_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function TPDuringDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc=TPDuringDAQ_IGNORE)
End

Function TPDuringDAQ_REENTRY([str])
	string str

	variable sweepNo, col, daGain
	string ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, 0)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	CHECK_EQUAL_VAR(2 * GetMinSampInt_IGNORE(unit = "ms"), DimDelta(sweepWave, ROWS))

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NORMAL_WAVE)
	CHECK_EQUAL_VAR(DimSize(configWave, ROWS), 4)
	CHECK_EQUAL_VAR(DimSize(configWave, COLS), 6)

	col = FindDimLabel(configWave, COLS, "DAQChannelType")
	Duplicate/FREE/R=[][col] configWave, channelTypes
	Redimension/N=-1 channelTypes

	CHECK_EQUAL_WAVES(channelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ}, mode = WAVE_DATA)

	WAVE/T units = AFH_GetChannelUnits(configWave)
	CHECK_EQUAL_TEXTWAVES(units, {"mV", "mV", "pA", "pA"}, mode = WAVE_DATA)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues = GetLBTextualValues(str)

	WAVE setCycleCount = GetLastSetting(numericalValues, sweepNo, "Set Cycle Count", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(setCycleCount, {NaN, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE DAChannelTypes = GetLastSetting(numericalValues, sweepNo, "DA ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(DAChannelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE ADChannelTypes = GetLastSetting(numericalValues, sweepNo, "AD ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(ADChannelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSetting(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
	WAVE/Z tpAmplitude = GetLastSetting(numericalValues, sweepNo, TP_AMPLITUDE_VC_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_WAVE(tpAmplitude, NUMERIC_WAVE)
	daGain = DAG_GetNumericalValue(str, GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE), index = 0)

	CHECK_EQUAL_WAVES(stimScale, {tpAmplitude[0], daGain, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z/T stimsets = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_TEXTWAVES(stimsets, {"TestPulse", "StimulusSetC_DA_0", "", "", "", "", "", "", ""}, mode = WAVE_DATA)
End

Function TPDuringDAQWithoodDAQ_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")
	PGC_SetAndActivateControl(device, "check_Settings_RequireAmpConn", val = 0)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 1)

	PGC_SetAndActivateControl(device, GetPanelControl(2, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 1)
	PGC_SetAndActivateControl(device, GetPanelControl(2, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetC_DA_0")
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function TPDuringDAQWithoodDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc=TPDuringDAQWithoodDAQ_IGNORE)
End

Function TPDuringDAQWithoodDAQ_REENTRY([str])
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
	CHECK_EQUAL_VAR(DimSize(configWave, COLS), 6)

	col = FindDimLabel(configWave, COLS, "DAQChannelType")
	Duplicate/FREE/R=[][col] configWave, channelTypes
	Redimension/N=-1 channelTypes

	CHECK_EQUAL_WAVES(channelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_DAQ}, mode = WAVE_DATA)

	WAVE/T units = AFH_GetChannelUnits(configWave)
	CHECK_EQUAL_TEXTWAVES(units, {"mV", "mV", "mV", "pA", "pA", "pA"}, mode = WAVE_DATA)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues = GetLBTextualValues(str)

	WAVE DAChannelTypes = GetLastSetting(numericalValues, sweepNo, "DA ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(DAChannelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_DAQ, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE ADChannelTypes = GetLastSetting(numericalValues, sweepNo, "AD ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(ADChannelTypes, {DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_DAQ, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSetting(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
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

Function TPDuringDAQTPStoreCheck_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, "check_Settings_RequireAmpConn", val = 0)

	PGC_SetAndActivateControl(device, "check_Settings_TP_SaveTP", val = 1)

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 1)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 1)
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "PulseTrain_10Hz_DA_0")

	PGC_SetAndActivateControl(device, GetPanelControl(2, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 1)
	PGC_SetAndActivateControl(device, GetPanelControl(2, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")
End

static Constant TP_WAIT_TIMEOUT = 5

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function TPDuringDAQTPStoreCheck([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc=TPDuringDAQTPStoreCheck_IGNORE)
End

Function TPDuringDAQTPStoreCheck_REENTRY([str])
	string str

	WaitAndCheckStoredTPs_IGNORE(str, 2)
End

Function WaitAndCheckStoredTPs_IGNORE(device, expectedNumTPchannels)
	string device
	variable expectedNumTPchannels

	variable i, channel, numTPChan, numStored, numTP
	variable tresh, m, tpLength, pulseLengthMS

	WAVE/Z TPStorage = GetTPStorage(device)
	CHECK_WAVE(TPStorage, NORMAL_WAVE)
	numStored = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)
	CHECK_GT_VAR(numStored, 0)

	WAVE/Z/WAVE storedTestPulses = GetStoredTestPulseWave(device)
	CHECK_WAVE(storedTestPulses, WAVE_WAVE)
	numTP = GetNumberFromWaveNote(storedTestPulses, NOTE_INDEX)

	CHECK(!ASYNC_WaitForWLCToFinishAndRemove(WORKLOADCLASS_TP + device, TP_WAIT_TIMEOUT))

	WAVE TPSettingsCalculated = GetTPsettingsCalculated(device)

	tpLength = TPSettingsCalculated[%totalLengthPointsDAQ]
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

static Constant TP_DURATION_S = 5

Function CheckThatTPsCanBeFound_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, "check_Settings_TP_SaveTP", val = 1)

	PrepareForPublishTest()
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function CheckThatTPsCanBeFound([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, startTPInstead=1, preAcquireFunc=CheckThatTPsCanBeFound_IGNORE)

	CtrlNamedBackGround StopTPAfterFiveSeconds, start=(ticks + TP_DURATION_S * 60), period=1, proc=StopTPAfterFiveSeconds_IGNORE
End

Function CheckThatTPsCanBeFound_REENTRY([str])
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

	FindDuplicates/RT=HeadstagesNoDups Headstages
	CHECK_EQUAL_TEXTWAVES(HeadstagesNoDups, {"0,1,"}, mode = WAVE_DATA)

	Sort/A TPMarkerTestpulses, TPMarkerTestpulses
	Sort/A TPMarker, TPMarker

	CHECK_EQUAL_WAVES(TPMarkerTestpulses, TPMarker, mode = WAVE_DATA)

	FindDuplicates/DN=dups TPMarkerTestpulses
	CHECK_EQUAL_VAR(DimSize(dups, ROWS), 0)

	FindDuplicates/DN=dups TPMarker
	CHECK_EQUAL_VAR(DimSize(dups, ROWS), 0)

	CheckStartStopMessages("tp", "starting")
	CheckStartStopMessages("tp", "stopping")
End

Function TPDuringDAQWithTTL_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK), val = 0)

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK), val = 1)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE), str = "StimulusSetA_TTL_0")
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = 25)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function TPDuringDAQWithTTL([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc=TPDuringDAQWithTTL_IGNORE)
End

Function TPDuringDAQWithTTL_REENTRY([str])
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
		CHECK(!V_flag)

		// hardcode values for 10ms pulse and 25% baseline
		CHECK_CLOSE_VAR(W_FindLevels[0], 5, tol = 0.1)
		CHECK_CLOSE_VAR(W_FindLevels[1], 15, tol = 0.1)
	endfor
End

Function RunPowerSpectrum_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, "check_settings_show_power", val = 1)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function RunPowerSpectrum([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc=RunPowerSpectrum_IGNORE, startTPInstead = 1)

	CtrlNamedBackGround StopTPAfterFiveSeconds, start=(ticks + TP_DURATION_S * 60), period=1, proc=StopTPAfterFiveSeconds_IGNORE
End

Function RunPowerSpectrum_REENTRY([str])
	string str

	variable sweepNo, col, tpAmplitude, daGain, i
	string ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

Function HasNaNAsDefaultWhenAborted_IGNORE(device)
	string device

	// enable TTL1
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK), val=1)
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE), str="StimulusSetA*")
	CtrlNamedBackGround Abort_ITI_PressAcq, start, period=30, proc=StopAcq_IGNORE
End

// check default values for data when aborting DAQ
// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function HasNaNAsDefaultWhenAborted([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1")

	AcquireData_BHT(s, str, preAcquireFunc=HasNaNAsDefaultWhenAborted_IGNORE)
End

Function HasNaNAsDefaultWhenAborted_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, sweepNo)
	CHECK_WAVE(sweepWave, NUMERIC_WAVE)

	FindValue/FNAN/RMD=[][0] sweepWave
	CHECK_GE_VAR(V_row, 0)

	// check that we have NaNs for all columns starting from the first unacquired point
	Duplicate/FREE/RMD=[V_row,][] sweepWave, unacquiredData
	WaveStats/Q/M=1 unacquiredData
	CHECK_EQUAL_VAR(V_numNans, DimSize(unacquiredData, ROWS) * DimSize(unacquiredData, COLS))
	CHECK_EQUAL_VAR(V_npnts, 0)
End

Function TestPulseCachingWorks_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 3)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function TestPulseCachingWorks([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA3_I0_L0_BKG1")

	AcquireData_BHT(s, str, preAcquireFunc=TestPulseCachingWorks_IGNORE)
End

Function TestPulseCachingWorks_REENTRY([str])
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

Function UnassocChannelsDuplicatedEntry_IGNORE(device)
	string device

	// enable HS1 with associated DA/AD channels
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)

	// cut assocication
	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", str = "1")
	PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")

	// disable HS1
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=0)

	// enable HS2 with associated DA/AD channels
	PGC_SetAndActivateControl(device, GetPanelControl(2, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)

	// cut assocication
	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", str = "2")
	PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")

	// disable HS2
	PGC_SetAndActivateControl(device, GetPanelControl(2, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=0)

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetA*")

	// disable AD1
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK), val = 0)

	// disable DA2
	PGC_SetAndActivateControl(device, GetPanelControl(2, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK), val = 0)
End

// Check that unassociated LBN entries for DA/AD don't overlap
//
// 1 HS
// DA1 unassociated
// AD2 unsassociated
//
// Now we should not find any unassoc labnotebook keys which only differ in the channel number.
//
// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function UnassocChannelsDuplicatedEntry([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc = UnassocChannelsDuplicatedEntry_IGNORE)
End

Function UnassocChannelsDuplicatedEntry_REENTRY([str])
	string str

	variable sweepNo, i, numEntries
	string unassoc

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	Make/WAVE/FREE keys = {GetLBNumericalKeys(str), GetLBTextualKeys(str)}

	numEntries = DimSize(keys, ROWS)
	for(i = 0; i < numEntries; i += 1)
		WAVE/T wv = keys[i]
		Duplicate/T/RMD=[0]/FREE wv, singleRow
		Redimension/N=(DimSize(singleRow, ROWS) * DimSize(singleRow, COLS))/E=1 singleRow
		Make/FREE/T unassocEntries
		Grep/E=".* u_(AD|DA)\d$" singleRow as unassocEntries
		CHECK(!V_Flag)
		CHECK_GT_VAR(V_Value, 0)

		unassocEntries[] = RemoveTrailingNumber_IGNORE(unassocEntries[p])

		FindDuplicates/FREE/Z/DT=dups unassocEntries
		CHECK_EQUAL_VAR(DimSize(dups, ROWS), 0)
	endfor
End

Function/S RemoveTrailingNumber_IGNORE(str)
	string str

	CHECK_EQUAL_VAR(ItemsInList(str, "_"), 2)

	return StringFromList(0, str, "_")
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function RestoreDAEphysPanel([str])
	string str

	variable jsonID, serialNum
	string stimSetPath, jPath, data, fName, rewrittenConfigPath, serialNumStr

	fName = PrependExperimentFolder_IGNORE(REF_DAEPHYS_CONFIG_FILE)

	[data, fName] = LoadTextFile(fname)

	jsonID = JSON_Parse(data)
	PathInfo home
	jPath = MIES_CONF#CONF_FindControl(jsonID, "popup_MoreSettings_Devices")
	JSON_SetString(jsonID, jPath + "/StrValue", str)
	JSON_SetString(jsonID, "/Common configuration data/Save data to", S_path)
	stimSetPath = S_path + ":_2017_09_01_192934-compressed.nwb"
	JSON_SetString(jsonID, "/Common configuration data/Stim set file name", stimSetPath)

	// replace stored serial number with present serial number
	AI_FindConnectedAmps()
	WAVE ampMCC = GetAmplifierMultiClamps()

	CHECK_GT_VAR(DimSize(ampMCC, ROWS), 0)
	serialNumStr = GetDimLabel(ampMCC, ROWS, 0)
	if(!cmpstr(serialNumStr, "Demo"))
		serialNum = 0
	else
		serialNum = str2num(serialNumStr)
	endif

	JSON_SetVariable(jsonID, "/Common configuration data/Headstage Association/0/Amplifier/Serial", serialNum)
	JSON_SetVariable(jsonID, "/Common configuration data/Headstage Association/1/Amplifier/Serial", serialNum)

	rewrittenConfigPath = S_Path + "rewritten_config.json"
	SaveTextFile(JSON_Dump(jsonID), rewrittenConfigPath)

	CONF_RestoreDAEphys(jsonID, rewrittenConfigPath)
	MIES_CONF#CONF_SaveDAEphys(fname)

	CONF_RestoreDAEphys(jsonID, rewrittenConfigPath, middleOfExperiment = 1)
	MIES_CONF#CONF_SaveDAEphys(fname)
End

static Function CheckLabnotebookKeys_IGNORE(keys, values)
	WAVE/T keys
	WAVE values

	string lblKeys, lblValues, entry
	variable i, numKeys

	numKeys = DimSize(keys, COLS)
	for(i = 0; i < numKeys; i += 1)
		entry = keys[0][i]
		lblKeys = GetDimLabel(keys, COLS, i)
		lblValues = GetDimLabel(values, COLS, i)
		CHECK_EQUAL_STR(entry, lblValues)
		CHECK_EQUAL_STR(entry, lblKeys)
	endfor
end

Function LabnotebookEntriesCanBeQueried_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val = 1)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function LabnotebookEntriesCanBeQueried([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1")

	AcquireData_BHT(s, str, preAcquireFunc = LabnotebookEntriesCanBeQueried_IGNORE)
End

Function LabnotebookEntriesCanBeQueried_REENTRY([str])
	string str

	variable sweepNo, numKeys, i, j

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE numericalKeys = GetLBNumericalKeys(str)
	WAVE numericalValues = GetLBNumericalValues(str)

	CheckLabnotebookKeys_IGNORE(numericalKeys, numericalValues)

	WAVE textualKeys = GetLBTextualKeys(str)
	WAVE textualValues = GetLBTextualValues(str)

	CheckLabnotebookKeys_IGNORE(textualKeys, textualValues)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function DataBrowserCreatesBackupsByDefault([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1")

	AcquireData_BHT(s, str)
End

Function DataBrowserCreatesBackupsByDefault_REENTRY([str])
	string str

	variable sweepNo, numEntries, i
	string list, name

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	OpenDatabrowser()

	WAVE sweepWave = GetSweepWave(str, 0)
	DFREF sweepFolder = GetWavesDataFolderDFR(sweepWave)
	DFREF singleSweepFolder = GetSingleSweepFolder(sweepFolder, 0)

	// check that all non-backup waves in singleSweepFolder have a backup
	list = GetListOfObjects(singleSweepFolder, "^[A-Za-z]{1,}_[0-9]$")
	numEntries = ItemsInList(list)
	CHECK_GT_VAR(numEntries, 0)

	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, list)
		WAVE/SDFR=singleSweepFolder/Z wv = $name
		CHECK_WAVE(wv, NORMAL_WAVE)
		WAVE/Z bak = GetBackupWave(wv)
		CHECK_WAVE(bak, NORMAL_WAVE)
	endfor
End

Function ILCUSetup_IGNORE(device)
	string device

	// disable HS1
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=0)

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "IncLabCacheUpdat*")
End

/// Test incremental labnotebook cache updates
/// We have two sweeps in total. After the first sweeps we query LBN settings
/// for the next sweep, we get all no-matches. But some of these no-matches are stored in
/// the LBN cache waves. After the second sweep these LBN entries can now be queried thus "proving"
/// that the LBN caches were successfully updated.
///
/// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function IncrementalLabnotebookCacheUpdate([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1")

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	KillOrMoveToTrash(wv = anaFuncTracker)

	AcquireData_BHT(s, str, preAcquireFunc = ILCUSetup_IGNORE)
End

Function IncrementalLabnotebookCacheUpdate_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 2)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 1)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 2)
End

Function ILCUCheck_IGNORE(string device, STRUCT AnalysisFunction_V3& s)

	variable nonExistingSweep

	WAVE/T textualValues = GetLBTextualValues(device)
	WAVE numericalValues = GetLBNumericalValues(device)

	// fetch some existing entries from the LBN
	WAVE/Z sweepCounts = GetLastSetting(numericalValues, s.sweepNo, "Set Sweep Count", DATA_ACQUISITION_MODE)
	CHECK_WAVE(sweepCounts, NUMERIC_WAVE)

	WAVE/T/Z foundStimSets = GetLastSetting(textualValues, s.sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	CHECK_WAVE(foundStimSets, TEXT_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, s.sweepNo, 0)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(sweeps, ROWS), s.sweepNo + 1)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, s.sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(sweeps, ROWS), s.sweepNo + 1)

	if(s.sweepNo == 0)
		// now fetch non-existing ones from the next sweep
		// this adds "missing" entries to the LBN cache
		// our wave cache updating results in these missing values being move to uncached on the cache update
		nonExistingSweep = s.sweepNo + 1
		WAVE/Z sweepCounts = GetLastSetting(numericalValues, nonExistingSweep, "Set Sweep Count", DATA_ACQUISITION_MODE)
		CHECK_WAVE(sweepCounts, NULL_WAVE)

		WAVE/T/Z foundStimSets = GetLastSetting(textualValues, nonExistingSweep, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
		CHECK_WAVE(foundStimSets, NULL_WAVE)

		WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, nonExistingSweep, 0)
		CHECK_WAVE(sweeps, NULL_WAVE)

		WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, nonExistingSweep)
		CHECK_WAVE(sweeps, NULL_WAVE)
	else
		CHECK_EQUAL_VAR(s.sweepNo, 1)
	endif
End

Function TestSweepRollbackPostInit_IGNORE(device)
	string device

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "SweepRollbackChecker")
End

Function TestSweepRollbackPreAcquire_IGNORE(device)
	string device

	// disable HS1
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=0)
End

/// Testing sweep rollback approach:
/// - Test case "TestSweepRollback" acquires 3 sweeps
/// - First reentry function, "TestSweepRollback_REENTRY", checks that these are acquired correctly.
///   Rolls back to sweep 1, does more checks, adds analysis function, "SweepRollbackChecker",
///   setups next reentry function and starts DAQ again
/// - "SweepRollbackChecker" checks in PRE_DAQ_EVENT that all sweeps except 0 are really removed.
/// - Second reentry function, "TestSweepRollback_REENTRY_REENTRY" checks sweep 0 from the first acquistion is still there
///   and three new sweeps, and also checks that "SweepRollbackChecker" was called
///
/// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function TestSweepRollback([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1")

	AcquireData_BHT(s, str, preAcquireFunc = TestSweepRollbackPreAcquire_IGNORE)
End

Function TestSweepRollback_REENTRY([str])
	string str

	variable sweepNo, sweepRollback
	string list, refList

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE/Z sweepCounts = GetLastSettingEachRAC(numericalValues, sweepNo, "Set Sweep Count", 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(sweepCounts, {0, 1, 2}, mode = WAVE_DATA)

	// rollback to sweep 1
	PGC_SetAndActivateControl(str, "SetVar_Sweep", val = 1)

	// check LBN entry
	sweepRollback = GetLastSettingIndep(numericalValues, sweepNo, SWEEP_ROLLBACK_KEY, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(sweepRollback, 1)

	// setvariable is already updated
	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	// but nothing deleted yet
	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	DFREF dfr = GetDevicedataPath(str)
	list    = SortList(GetListOfObjects(dfr, ".*"))
	refList = SortList("Config_Sweep_0;Sweep_0;Config_Sweep_1;Sweep_1;Config_Sweep_2;Sweep_2;")
	CHECK_EQUAL_STR(refList, list)

	TestSweepRollbackPostInit_IGNORE(str)

	PGC_SetAndActivateControl(str, "DataAcquireButton")

	RegisterReentryFunction(GetRTStackInfo(1))
End

Function TestSweepRollback_REENTRY_REENTRY([str])
	string str

	variable sweepNo
	string list, refList

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 4)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 3)

	// we want to be sure that "SweepRollbackChecker" was called
	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)

	// the non overwritten sweep
	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE/Z sweepCounts = GetLastSetting(numericalValues, 0, "Set Sweep Count", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(sweepCounts, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// new sweeps
	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE/Z sweepCounts = GetLastSettingEachRAC(numericalValues, sweepNo, "Set Sweep Count", 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(sweepCounts, {0, 1, 2}, mode = WAVE_DATA)

	DFREF dfr = GetDevicedataPath(str)
	list    = SortList(GetListOfObjects(dfr, ".*"))
	refList = SortList("Config_Sweep_0;Sweep_0;Config_Sweep_1;Sweep_1;Config_Sweep_2;Sweep_2;Config_Sweep_3;Sweep_3;")
	CHECK_EQUAL_STR(refList, list)
End

/// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function TestAcquiringNewDataOnOldData([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1")

	AcquireData_BHT(s, str)
End

Function TestAcquiringNewDataOnOldData_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	KillWindow $str

	// restart data acquisition
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1")

	AcquireData_BHT(s, str)

	RegisterReentryFunction(GetRTStackInfo(1))
End

Function TestAcquiringNewDataOnOldData_REENTRY_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 6)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 5)
End

Function AsyncAcquisitionLBN_IGNORE(string device)

	string ctrl
	variable channel = 2

	ctrl = GetPanelControl(channel, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_CHECK)
	PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_SELECTED)

	ctrl = GetPanelControl(channel, CHANNEL_TYPE_ALARM, CHANNEL_CONTROL_CHECK)
	PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_SELECTED)

	ctrl = GetPanelControl(channel, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN)
	PGC_SetAndActivateControl(device, ctrl, val = 5)

	ctrl = GetPanelControl(channel, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN)
	PGC_SetAndActivateControl(device, ctrl, val = 0.1)

	ctrl = GetPanelControl(channel, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX)
	PGC_SetAndActivateControl(device, ctrl, val = 0.5)

	ctrl = GetPanelControl(channel, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_TITLE)
	PGC_SetAndActivateControl(device, ctrl, str = "myTitle")

	ctrl = GetPanelControl(channel, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_UNIT)
	PGC_SetAndActivateControl(device, ctrl, str = "myUnit")
End

/// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function AsyncAcquisitionLBN([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1")

	AcquireData_BHT(s, str, preAcquireFunc = AsyncAcquisitionLBN_IGNORE)
End

Function AsyncAcquisitionLBN_REENTRY([str])
	string str

	variable sweepNo, var
	string refStr, readStr

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues = GetLBTextualValues(str)

	var = GetLastSettingIndep(numericalValues, 0, "Async 2 On/Off", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(var, CHECKBOX_SELECTED)

	var = GetLastSettingIndep(numericalValues, 0, "Async 2 Gain", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(var, 5)

	var = GetLastSettingIndep(numericalValues, 0, "Async Alarm 2 On/Off", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(var, CHECKBOX_SELECTED)

	var = GetLastSettingIndep(numericalValues, 0, "Async Alarm 2 Min", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(var, 0.1)

	var = GetLastSettingIndep(numericalValues, 0, "Async Alarm  2 Max", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(var, 0.5)

	var = GetLastSettingIndep(numericalValues, 0, "Async Alarm 2 State", DATA_ACQUISITION_MODE)
	CHECK(IsFinite(var))

	var = GetLastSettingIndep(numericalValues, 0, "Async AD 2 [myTitle]", DATA_ACQUISITION_MODE)
	// we don't know if the alarm was triggered or not
	// but we also only care that the value is finite
	CHECK(IsFinite(var))

	readStr = GetLastSettingTextIndep(textualValues, 0, "Async AD2 Title", DATA_ACQUISITION_MODE)
	refStr = "myTitle"
	CHECK_EQUAL_STR(refStr, readStr)

	readStr = GetLastSettingTextIndep(textualValues, 0, "Async AD2 Unit", DATA_ACQUISITION_MODE)
	refStr = "myUnit"
	CHECK_EQUAL_STR(refStr, readStr)
End

Function CheckSettingsFails_IGNORE(string device)

	string ctrl

	ctrl = GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
	PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_UNSELECTED)

	ctrl = GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
	PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_UNSELECTED)
End

/// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function CheckSettingsFails([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1")

	try
		AcquireData_BHT(s, str, preAcquireFunc = CheckSettingsFails_IGNORE)
	catch
		// do nothing
	endtry
End

Function CheckSettingsFails_REENTRY([str])
	string str
	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function CheckAcquisitionStates_IGNORE(device)
	string device

	string ctrl

	ctrl = GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
	PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_UNSELECTED)

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetC*")

	ST_SetStimsetParameter("StimulusSetC_DA_0", "Analysis function (generic)", str = "AcquisitionStateTrackingFunc")

	CtrlNamedBackGround ExecuteDuringITI, start, period=30, proc=AddLabnotebookEntries_IGNORE

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 5)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function CheckAcquisitionStates_MD([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc=CheckAcquisitionStates_IGNORE)
End

Function CheckAcquisitionStates_MD_REENTRY([string str])
	CheckAcquisitionStates(str)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD0
Function CheckAcquisitionStates_SD([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA1_I0_L0_BKG1_RES1")
	AcquireData_BHT(s, str, preAcquireFunc=CheckAcquisitionStates_IGNORE)
End

Function CheckAcquisitionStates_SD_REENTRY([string str])
	CheckAcquisitionStates(str)
End

static Function CheckLBNEntries_IGNORE(string device, variable sweepNo, variable acqState, [variable missing])

	string name
	variable i, numEntries

	name = "USER_AcqStateTrackingValue_" + AS_StateToString(acqState)

	WAVE/T textualValues = GetLBTextualValues(device)
	WAVE numericalValues = GetLBNumericalValues(device)

	WAVE/Z entry = GetLastSetting(numericalValues, sweepNo, name, UNKNOWN_MODE)
	WAVE/Z entryText = GetLastSetting(textualValues, sweepNo, name, UNKNOWN_MODE)

	if(!ParamIsDefault(missing) && missing == 1)
		CHECK_WAVE(entry, NULL_WAVE)
		CHECK_WAVE(entryText, NULL_WAVE)
		return NaN
	endif

	CHECK_WAVE(entry, NUMERIC_WAVE)
	CHECK_WAVE(entryText, TEXT_WAVE)

	CHECK_EQUAL_WAVES(entry, {acqState, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(entryText, {AS_StateToString(acqState), "", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// check that the written entries have the correct acquisition state in the new AcquisitionState column
	Make/FREE/WAVE waves = {numericalValues, textualValues}

	numEntries = DimSize(waves, ROWS)
	for(i = 0; i < 2; i += 1)
		WAVE wv = waves[i]

		WAVE/Z indizesSweeps = FindIndizes(wv, colLabel = "SweepNum", var = sweepNo)
		CHECK_WAVE(indizesSweeps, FREE_WAVE)

		if(IsNumericWave(wv))
			WAVE/Z indizesEntry = FindIndizes(wv, colLabel = name, var = acqState)
		else
			WAVE/Z indizesEntry = FindIndizes(wv, colLabel = name, str = AS_StateToString(acqState))
		endif

		CHECK_WAVE(indizesEntry, FREE_WAVE)
		WAVE indizesEntryOneSweep = GetSetIntersection(indizesSweeps, indizesEntry)
		CHECK_GT_VAR(DimSize(indizesEntryOneSweep, ROWS), 0)

		// all entries in indizesEntryOneSweep must be in indizesAcqState
		WAVE/Z indizesAcqState = FindIndizes(wv, colLabel = "AcquisitionState", var = acqState)

		CHECK_WAVE(indizesAcqState, FREE_WAVE)
		WAVE/Z matches = GetSetIntersection(indizesEntryOneSweep, indizesAcqState)

		CHECK_EQUAL_WAVES(indizesEntryOneSweep, matches)
	endfor
End

Function CheckAcquisitionStates(string str)
	variable sweepNo, i

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 2)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 1)

	// add entry for AS_INACTIVE
	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values     = NaN
	Make/T/FREE/N=(LABNOTEBOOK_LAYER_COUNT) valuesText = ""
	values[0] = AS_INACTIVE
	ED_AddEntryToLabnotebook(str, "AcqStateTrackingValue_AS_INACTIVE", values)
	valuesText[0] = AS_StateToString(AS_INACTIVE)
	ED_AddEntryToLabnotebook(str, "AcqStateTrackingValue_AS_INACTIVE", valuesText)

	for(i = 0; i < AS_NUM_STATES; i += 1)
		switch(i)
			case AS_INACTIVE:
				CheckLBNEntries_IGNORE(str, 0, i, missing = 1)
				CheckLBNEntries_IGNORE(str, 1, i)
				break
			case AS_EARLY_CHECK:
				// no check possible for AS_EARLY_CHECK
				break
			case AS_PRE_DAQ:
				CheckLBNEntries_IGNORE(str, 0, i)
				CheckLBNEntries_IGNORE(str, 1, i, missing = 1)
				break
			case AS_PRE_SWEEP_CONFIG:
				CheckLBNEntries_IGNORE(str, 0, i)
				CheckLBNEntries_IGNORE(str, 1, i)
				break
			case AS_PRE_SWEEP:
				CheckLBNEntries_IGNORE(str, 0, i, missing = 1)
				CheckLBNEntries_IGNORE(str, 1, i, missing = 1)
				break
			case AS_MID_SWEEP:
				CheckLBNEntries_IGNORE(str, 0, i)
				CheckLBNEntries_IGNORE(str, 1, i)
				break
			case AS_POST_SWEEP:
				CheckLBNEntries_IGNORE(str, 0, i)
				CheckLBNEntries_IGNORE(str, 1, i)
				break
			case AS_ITI:
				CheckLBNEntries_IGNORE(str, 0, i)
				CheckLBNEntries_IGNORE(str, 1, i, missing = 1)
				break
			case AS_POST_DAQ:
				CheckLBNEntries_IGNORE(str, 0, i, missing = 1)
				CheckLBNEntries_IGNORE(str, 1, i)
				break
			default:
				FAIL()
		endswitch
	endfor

	CHECK_EQUAL_VAR(ROVar(GetAcquisitionState(str)), AS_INACTIVE)
	CHECK_EQUAL_VAR(AS_GetSweepNumber(str), NaN)
	CHECK_EQUAL_VAR(AS_GetSweepNumber(str, allowFallback = 1), sweepNo)
End

Function ConfigureFails_IGNORE(string device)

	string ctrl

	ctrl = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	PGC_SetAndActivateControl(device, ctrl, val = 10000)
End

/// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function ConfigureFails([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1")

	try
		AcquireData_BHT(s, str, preAcquireFunc = ConfigureFails_IGNORE)
	catch
		// do nothing
	endtry
End

Function ConfigureFails_REENTRY([str])
	string str
	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	CheckDAQStopReason(str, DQ_STOP_REASON_CONFIG_FAILED)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function StopDAQDueToUnlocking([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES5")
	AcquireData_BHT(s, str)

	CtrlNamedBackGround UnlockDevice, start, period=30, proc=StopAcqByUnlocking_IGNORE

	PGC_SetAndActivateControl(str, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(str, "SetVar_DataAcq_ITI", val = 5)
End

Function StopDAQDueToUnlocking_REENTRY([str])
	string str

	NVAR runModeDAQ = $GetDataAcqRunMode(str)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(str)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	CheckThatTestpulseRan_IGNORE(str)

	CheckDAQStopReason(str, DQ_STOP_REASON_UNLOCKED_DEVICE)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function StopDAQDueToUncompiled([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES5")
	AcquireData_BHT(s, str)

	CtrlNamedBackGround UncompileProcedures, start, period=30, proc=StopAcqByUncompiled_IGNORE

	PGC_SetAndActivateControl(str, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(str, "SetVar_DataAcq_ITI", val = 5)
End

Function StopDAQDueToUncompiled_REENTRY([str])
	string str

	NVAR runModeDAQ = $GetDataAcqRunMode(str)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(str)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	CheckThatTestpulseRan_IGNORE(str)

	CheckDAQStopReason(str, DQ_STOP_REASON_UNCOMPILED)
End

// Roundtrip stimsets, this also leaves the NWBv2 file lying around
// for later validation.
//
// UTF_TD_GENERATOR HardwareHelperFunctions#MajorNWBVersions
Function ExportStimsetsAndRoundtripThem([variable var])

	string baseFolder, nwbFile, discLocation
	variable numEntries, i

	[baseFolder, nwbFile] = GetUniqueNWBFileForExport(var)
	discLocation = baseFolder + nwbFile

	NWB_ExportAllStimsets(var, overrideFilePath = discLocation)

	GetFileFolderInfo/Q/Z discLocation
	REQUIRE(V_IsFile)

	DFREF dfr = GetWaveBuilderPath()
	MoveDataFolder dfr, :
	RenameDataFolder WaveBuilder, old

	KillOrMoveToTrash(dfr = GetMiesPath())

	NWB_LoadAllStimsets(filename = discLocation)

	DFREF dfr = GetWaveBuilderPath()
	MoveDataFolder dfr, :
	RenameDataFolder WaveBuilder, new

	WAVE/T oldWaves = ListToTextWave(GetListOfObjects(old, ".*", recursive = 1, fullPath = 1), ";")
	WAVE/T newWaves =  ListToTextWave(GetListOfObjects(new, ".*", recursive = 1, fullPath = 1), ";")
	CHECK_EQUAL_VAR(DimSize(oldWaves, ROWS), DimSize(newWaves, ROWS))

	numEntries = DimSize(oldWaves, ROWS)
	CHECK_GT_VAR(numEntries, 0)

	for(i = 0; i < numEntries; i += 1)
		WAVE oldWave = $oldWaves[i]
		WAVE newWave = $newWaves[i]

		CHECK_EQUAL_WAVES(oldWave, newWave)
	endfor
End

/// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function ExportIntoNWB([str])
	string str

	string filePathExport, experimentName

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1")

	AcquireData_BHT(s, str, startTPInstead = 1)

	CtrlNamedBackGround StopTPAfterFiveSeconds, start=(ticks + TP_DURATION_S * 60), period=1, proc=StopTPAfterFiveSeconds_IGNORE
End

Function ExportIntoNWB_REENTRY([str])
	string str
	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	RegisterReentryFunction(GetRTStackInfo(1))

	PGC_SetAndActivateControl(str, "Check_Settings_NwbExport", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(str, "StartTestPulseButton")

	CtrlNamedBackGround StopTPAfterFiveSeconds, start=(ticks + TP_DURATION_S * 60), period=1, proc=StopTPAfterFiveSeconds_IGNORE
End

Function ExportIntoNWB_REENTRY_REENTRY([str])
	string str
	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

Function ExportIntoNWBSweepBySweep_IGNORE(string device)

	CHECK_EQUAL_VAR(GetCheckBoxState(device, "Check_Settings_NwbExport"), CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(device, "Check_Settings_NwbExport", val = CHECKBOX_SELECTED)
End

/// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function ExportIntoNWBSweepBySweep([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1")

	AcquireData_BHT(s, str, preAcquireFunc = ExportIntoNWBSweepBySweep_IGNORE)
End

Function ExportIntoNWBSweepBySweep_REENTRY([str])
	string str

	string experimentNwbFile, stimsets, acquisition, stimulus
	variable fileID, nwbVersion

	CloseNwbFile()
	experimentNwbFile = GetExperimentNWBFileForExport()
	REQUIRE(FileExists(experimentNwbFile))

	fileID = H5_OpenFile(experimentNWBFile)
	nwbVersion = GetNWBMajorVersion(ReadNWBVersion(fileID))
	CHECK_EQUAL_VAR(nwbVersion, 2)

	stimsets = ReadStimsets(fileID)
	CHECK_PROPER_STR(stimsets)

	acquisition = ReadAcquisition(fileID, nwbVersion)
	CHECK_PROPER_STR(acquisition)

	stimulus = ReadStimulus(fileID)
	CHECK_PROPER_STR(stimulus)
	HDF5CloseFile fileID
End

Function ExportOnlyCommentsIntoNWB_IGNORE(string device)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_Comment", str = "abcdefgh ijjkl")

	// don't start TP/DAQ at all
	Abort
End

/// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function ExportOnlyCommentsIntoNWB([string str])

	string discLocation, userComment, userCommentRef
	variable fileID

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1")

	try
		AcquireData_BHT(s, str, preAcquireFunc = ExportOnlyCommentsIntoNWB_IGNORE)
	catch
		CHECK_EQUAL_VAR(V_AbortCode, -3)
	endtry

	discLocation = TestNWBExportV2#TestFileExport()
	REQUIRE(FileExists(discLocation))

	fileID = H5_OpenFile(discLocation)
	userComment = TestNWBExportV2#TestUserComment(fileID, str)
	userCommentRef = "abcdefgh ijjkl"
	CHECK_GE_VAR(strsearch(userComment, userCommentRef, 0), 0)

	H5_CloseFile(fileID)
End

Function CheckPulseInfoGathering_IGNORE(string device)
	string ctrl

	ctrl = GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
	PGC_SetAndActivateControl(device, ctrl, val=0)

	ctrl = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	PGC_SetAndActivateControl(device, ctrl, str = "Y4_SRecovery_50H*")
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = 25)
End

/// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function CheckPulseInfoGathering([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1")

	AcquireData_BHT(s, str, preAcquireFunc = CheckPulseInfoGathering_IGNORE)
End

Function CheckPulseInfoGathering_REENTRY([string str])
	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/T textualValues = GetLBTextualValues(str)
	WAVE/T/Z epochs = GetLastSetting(textualValues, sweepNo, EPOCHS_ENTRY_KEY, DATA_ACQUISITION_MODE)

	WAVE/Z pulseInfos = MIES_PA#PA_RetrievePulseInfosFromEpochs(epochs[0])
	CHECK_WAVE(pulseInfos, NUMERIC_WAVE)

	// no zeros
	FindValue/V=0 pulseInfos
	CHECK_EQUAL_VAR(V_Value, -1)

	// no infinite values
	Wavestats/Q/M=1 pulseInfos
	CHECK_EQUAL_VAR(V_numInfs, 0)
	CHECK_EQUAL_VAR(V_numNaNs, 0)

	// check some values
	Duplicate/FREE/RMD=[9][] pulseInfos, pulseInfo_row9
	Redimension/N=(numpnts(pulseInfo_row9)) pulseInfo_row9
	CHECK_EQUAL_WAVES(pulseInfo_row9, {20, 826.505, 828.005}, mode = WAVE_DATA, tol = 1e-4)

	Duplicate/FREE/RMD=[25][] pulseInfos, pulseInfo_row25
	Redimension/N=(numpnts(pulseInfo_row25)) pulseInfo_row25
	CHECK_EQUAL_WAVES(pulseInfo_row25, {26.5433, 1373.55, 1375.05}, mode = WAVE_DATA, tol = 1e-4)

	Duplicate/FREE/RMD=[55][] pulseInfos, pulseInfo_row55
	Redimension/N=(numpnts(pulseInfo_row55)) pulseInfo_row55
	CHECK_EQUAL_WAVES(pulseInfo_row55, {29.6455, 2505.13, 2506.63}, mode = WAVE_DATA, tol = 1e-4)

	// check total number of pulses
	CHECK_EQUAL_VAR(DimSize(pulseInfos, ROWS), 60)
End

Function CheckCalculatedTPEntries_IGNORE(string device)
	PGC_SetAndActivateControl(device, "Popup_Settings_SampIntMult", str = "2")
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = 25)
End

/// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function CheckCalculatedTPEntries([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1")

	AcquireData_BHT(s, str, preAcquireFunc = CheckCalculatedTPEntries_IGNORE)
End

Function CheckCalculatedTPEntries_REENTRY([string str])
	variable samplingInterval, samplingIntervalMult, sweepNo

	WAVE numericalValues = GetLBNumericalValues(str)

	sweepNo = 0
	samplingInterval = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval", DATA_ACQUISITION_MODE)
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
End

static Function/WAVE GenerateBaselineValues()

	WAVE/T/Z devices = DeviceNameGeneratorMD1()

	Make/FREE/WAVE/N=(2) wvInner1, wvInner2, wvInner3

	Make/FREE wv1 = {25}
	Make/FREE wv2 = {35}
	Make/FREE wv3 = {45}

	wvInner1[] = {wv1, devices}
	wvInner2[] = {wv2, devices}
	wvInner3[] = {wv3, devices}

	Make/FREE/WAVE/N=(3) wvOuter = {wvInner1, wvInner2, wvInner3}

	return wvOuter
End

Function CheckTPBaseline_IGNORE(string device)
	NVAR/Z TPBaseline
	CHECK(NVAR_Exists(TPBaseline))

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = TPBaseline)
	PGC_SetAndActivateControl(device, "check_Settings_TP_SaveTP", val = 1)

	CtrlNamedBackGround StopTP, start=(ticks + 100), period=1, proc=StopTPWhenWeHaveOne
End

/// UTF_TD_GENERATOR GenerateBaselineValues
Function CheckTPBaseline([WAVE/WAVE pair])
	string device

	WAVE/T devices = pair[1]
	CHECK_WAVE(devices, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(devices, ROWS), 1)
	device = devices[0]

	WAVE/Z baselines = pair[0]
	variable/G TPbaseline = baselines[0]

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1")

	AcquireData_BHT(s, device, startTPInstead = 1, preAcquireFunc = CheckTPBaseline_IGNORE)
End

Function CheckTPBaseline_REENTRY([WAVE/WAVE pair])
	string device
	variable i, numEntries, baselineFraction, pulseDuration, tpLength, samplingInterval

	WAVE/T devices = pair[1]
	CHECK_WAVE(devices, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(devices, ROWS), 1)
	device = devices[0]

	WAVE/Z baselineRef = pair[0]

	WAVE/T textualValues   = GetLBTextualValues(device)
	WAVE   numericalValues = GetLBNumericalValues(device)

	baselineFraction = GetLastSettingIndep(numericalValues, NaN, "TP Baseline Fraction", TEST_PULSE_MODE)
	CHECK_CLOSE_VAR(baselineFraction, baselineRef[0] / 100)

	pulseDuration = GetLastSettingIndep(numericalValues, NaN, "TP Pulse Duration", TEST_PULSE_MODE)
	CHECK_CLOSE_VAR(pulseDuration, 10)

	WAVE/WAVE storedTPs = GetStoredTestPulseWave(device)
	CHECK_WAVE(storedTPs, WAVE_WAVE)

	numEntries = GetNumberFromWaveNote(storedTPs, NOTE_INDEX)
	CHECK_GT_VAR(numEntries, 0)

	for(i = 0; i < numEntries; i += 1)
		WAVE/Z singleTP = storedTPs[i]
		CHECK_WAVE(singleTP, NUMERIC_WAVE)

		samplingInterval = GetValDisplayAsNum(device, "ValDisp_DataAcq_SamplingInt")

		CHECK_CLOSE_VAR(DimSize(singleTP, ROWS), (MIES_TP#TP_CalculateTestPulseLength(pulseDuration, baselineFraction) * MILLI_TO_MICRO) / samplingInterval, tol = 0.1)
	endfor
End

Function CheckTPEntriesFromLBN_IGNORE(string device)

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 3)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPDuration", val = 15)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = 30)

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
/// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function CheckTPEntriesFromLBN([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1")

	AcquireData_BHT(s, str, preAcquireFunc = CheckTPEntriesFromLBN_IGNORE)
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

Function CheckTPEntriesFromLBN_REENTRY([string str])
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

	Make/N=(DimSize(entries_S2_TP, ROWS)) validWaves = WaveExists(entries_S2_TP[p])
	CHECK_EQUAL_VAR(Sum(validWaves), 0)
End

Function TPCachingWorks_IGNORE(string device)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val=3)
	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val=CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(device, "check_Settings_TP_SaveTP", val=CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(device, "Popup_Settings_SampIntMult", str="4")
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function TPCachingWorks([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES0")
	AcquireData_BHT(s, str, startTPInstead=1, preAcquireFunc=TPCachingWorks_IGNORE)

	CtrlNamedBackGround StartDAQDuringTP, start=(ticks + 600), period=100, proc=StartAcq_IGNORE
End

Function TPCachingWorks_REENTRY([string str])
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
	samplingInterval = GetLastSettingIndep(numericalValues, sweepNo, "Sampling Interval", DATA_ACQUISITION_MODE)
	samplingIntervalMultiplier = GetLastSettingIndep(numericalValues, sweepNo, "Sampling Interval Multiplier", DATA_ACQUISITION_MODE)

	CHECK_EQUAL_VAR(DimSize(dimDeltasUnique, ROWS), 1)
	CHECK_CLOSE_VAR(samplingInterval / samplingIntervalMultiplier, dimDeltasUnique[0], tol = 1e-3)
End

static Function RepeatedAcquisitionWithOneSweepStimsets_IGNORE(string device)

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Total number of steps", var = 1)
End

static Function RepeatedAcquisitionWithOneSweep_IGNORE(string device)

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function RepeatedAcquisitionWithOneSweepMD([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1")
	AcquireData_BHT(s, str, postInitializeFunc = RepeatedAcquisitionWithOneSweepStimsets_IGNORE, preAcquireFunc = RepeatedAcquisitionWithOneSweep_IGNORE)
End

Function RepeatedAcquisitionWithOneSweepMD_REENTRY([string str])

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD0
Function RepeatedAcquisitionWithOneSweepSD([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA1_I0_L0_BKG1")
	AcquireData_BHT(s, str, postInitializeFunc = RepeatedAcquisitionWithOneSweepStimsets_IGNORE, preAcquireFunc = RepeatedAcquisitionWithOneSweep_IGNORE)
End

Function RepeatedAcquisitionWithOneSweepSD_REENTRY([string str])

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)
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
	CHECK_WAVE(values,NULL_WAVE)

	WAVE/Z values = ExtractvalidValues(TPStorage, 1, entry)
	CHECK_WAVE(values, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	WaveStats/M=0/Q values
	CHECK_LT_VAR(V_avg, 100)

	entry = "baseline_VC"
	WAVE/Z values = ExtractvalidValues(TPStorage, 0, entry)
	WaveStats/M=0/Q values
	CHECK_LT_VAR(V_avg, 100)

	WAVE/Z values = ExtractvalidValues(TPStorage, 1, entry)
	CHECK_WAVE(values,NULL_WAVE)
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

Function CheckTPStorage1_IGNORE(string device)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val=1)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitude", val = 15)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val = -75)

	EnsureUnityGain(device, 0)
	EnsureUnityGain(device, 1)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
End

/// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function CheckTPStorage1([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1")

	AcquireData_BHT(s, str, preAcquireFunc = CheckTPStorage1_IGNORE, startTPinstead = 1)
End

Function CheckTPStorage1_REENTRY([string str])
	CheckTPStorage(str)
End

Function CheckTPStorage2_IGNORE(string device)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val=1)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitude", val = 37)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val = -150)

	EnsureUnityGain(device, 0)
	EnsureUnityGain(device, 1)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
End

/// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function CheckTPStorage2([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1")

	AcquireData_BHT(s, str, preAcquireFunc = CheckTPStorage2_IGNORE, startTPinstead = 1)
End

Function CheckTPStorage2_REENTRY([string str])
	CheckTPStorage(str)
End

Function CheckTPStorage3_IGNORE(string device)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val=1)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitude", val = -15)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val = 50)

	EnsureUnityGain(device, 0)
	EnsureUnityGain(device, 1)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
End

/// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function CheckTPStorage3([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1")

	AcquireData_BHT(s, str, preAcquireFunc = CheckTPStorage3_IGNORE, startTPinstead = 1)
End

Function CheckTPStorage3_REENTRY([string str])
	CheckTPStorage(str)
End

static Function EnableIndexingInPostDAQStimsets_IGNORE(string device)

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "EnableIndexing")
End

static Function EnableIndexingInPostDAQ_IGNORE(string device)

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetA_DA_0")
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function EnableIndexingInPostDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1")
	AcquireData_BHT(s, str, postInitializeFunc = EnableIndexingInPostDAQStimsets_IGNORE, preAcquireFunc = EnableIndexingInPostDAQ_IGNORE)
End

Function EnableIndexingInPostDAQ_REENTRY([string str])
	string ctrl, stimset, expected

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	ctrl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)

	stimset = DAG_GetTextualValue(str, ctrl, index = 0)
	expected = "StimulusSetA_DA_0"
	CHECK_EQUAL_STR(stimset, expected)
End

static Function ScaleZeroWithCycling_IGNORE(string device)

	PGC_SetAndActivateControl(device, "check_Settings_ScalingZero", val = CHECKBOX_SELECTED)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
static Function ScaleZeroWithCycling([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES2")
	AcquireData_BHT(s, str, preAcquireFunc = ScaleZeroWithCycling_IGNORE)
End

static Function ScaleZeroWithCycling_REENTRY([string str])
	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 6)

	WAVE numericalValues = GetLBNumericalValues(str)
	sweepNo = 0

	WAVE/Z stimScale_HS0 = GetLastSettingEachRAC(numericalValues, sweepNo, "Stim Scale Factor", 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale_HS0, {1, 1, 1, 0, 0, 0}, mode = WAVE_DATA)
	WAVE/Z stimScale_HS1 = GetLastSettingEachRAC(numericalValues, sweepNo, "Stim Scale Factor", 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale_HS1, {1, 1, 0, 0, 0, 0}, mode = WAVE_DATA)
End

static Function AcquireWithoutAmplifier_IGNORE(string device)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(V_CLAMP_MODE, 0), val=1)
	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val=1)

	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = 0)

	PGC_SetAndActivateControl(device, "setvar_Settings_VC_DAgain", val = 11)
	PGC_SetAndActivateControl(device, "setvar_Settings_VC_ADgain", val = 21e-5)
	PGC_SetAndActivateControl(device, "setvar_Settings_IC_DAgain", val = 31)
	PGC_SetAndActivateControl(device, "setvar_Settings_IC_ADgain", val = 41e-5)

	// toggle headstage to use the newly changed gains
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=0)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)

	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = 1)

	PGC_SetAndActivateControl(device, "setvar_Settings_VC_DAgain", val = 10)
	PGC_SetAndActivateControl(device, "setvar_Settings_VC_ADgain", val = 20e-5)
	PGC_SetAndActivateControl(device, "setvar_Settings_IC_DAgain", val = 30)
	PGC_SetAndActivateControl(device, "setvar_Settings_IC_ADgain", val = 40e-5)

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=0)
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
static Function AcquireWithoutAmplifier([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES0")
	AcquireData_BHT(s, str, useAmplifier = 0, preAcquireFunc = AcquireWithoutAmplifier_IGNORE)
End

static Function AcquireWithoutAmplifier_REENTRY([string str])
	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	WAVE numericalValues = GetLBNumericalValues(str)
	sweepNo = 0

	WAVE/Z DAGain = GetLastSetting(numericalValues, sweepNo, "DA Gain", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(DAGain, {11, 30, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z ADGain = GetLastSetting(numericalValues, sweepNo, "AD Gain", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(ADGain, {21e-5, 40e-5, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z operationMode = GetLastSetting(numericalValues, sweepNo, "Operating Mode", DATA_ACQUISITION_MODE)
	CHECK_WAVE(operationMode, NULL_WAVE)

	WAVE/Z requireAmplifier = GetLastSetting(numericalValues, sweepNo, "Require amplifier", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(requireAmplifier, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, CHECKBOX_UNSELECTED}, mode = WAVE_DATA)

	WAVE/Z saveAmpSettings = GetLastSetting(numericalValues, sweepNo, "Save amplifier settings", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(saveAmpSettings, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, CHECKBOX_UNSELECTED}, mode = WAVE_DATA)
End

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
