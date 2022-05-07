#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=PatchSeqTrueRestMembranePot

/// Test matrix
/// @rst
///
/// .. Column order: test overrides, analysis parameters
///
/// =========== ===================== =================== =================== ================== ====================== ===================== ===================== ===================== ====================== =================== ============================
///  Test case   Baseline QC chunk 0   Average V chunk 0   Average V chunk 1   Number of Spikes   NumberOfFailedSweeps   BaselineChunkLength   AbsoluteVoltageDiff   RelativeVoltageDiff   Sampling Interval QC   NextStimSetName     NextIndexingEndStimSetName
/// =========== ===================== =================== =================== ================== ====================== ===================== ===================== ===================== ====================== =================== ============================
///  PS_VM1      0                     [12,13,14]          [16,17,18]          [1,2,3]            3                      500                   0                     0                     1                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM2      1                     [12,13,14]          [12,13,14]          0                  3                      500                   0                     0                     1                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM3      0                     [12,13,14]          [12,13,14]          0                  3                      500                   0                     0                     1                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM4      1                     [12,13,14]          [16,17,18]          0                  3                      500                   inf                   0                     1                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM5      1                     [12,13,14]          [16,17,18]          0                  3                      500                   0                     inf                   1                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM5a     1                     [10,0.1,1]          [11,0.15,1.05]      0                  3                      500                   0.1                   10                    1                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM5b     1                     [12,13,14]          [12,13,14]          0                  3                      500                   0                     0                     1                      StimulusSetA_DA_0   (none)
///  PS_VM6      1                     [12,13,14]          [12,13,14]          0                  3                      600                   0                     0                     1                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM7      1                     [12,13,14]          [12,13,14]          1                  1                      500                   0                     inf                   1                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM7a     1                     [12,13,14]          [12,13,14]          [1, 0]             3                      500                   0                     0                     1                      StimulusSetA_DA_0   StimulusSetB_DA_0
///  PS_VM8      1                     [12,13,14]          [12,13,14]          0                  3                      500                   0                     0                     1                      StimulusSetA_DA_0   StimulusSetB_DA_0
/// =========== ===================== =================== =================== ================== ====================== ===================== ===================== ===================== ====================== =================== ============================
///
/// @endrst

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(STRUCT DAQSettings& s, string device, [FUNCREF CALLABLE_PROTO postInitializeFunc, FUNCREF CALLABLE_PROTO preAcquireFunc])
	string stimset

	if(!ParamIsDefault(postInitializeFunc))
		postInitializeFunc(device)
	endif

	EnsureMCCIsOpen()

	string unlockedDevice = DAP_CreateDAEphysPanel()

	PGC_SetAndActivateControl(unlockedDevice, "popup_MoreSettings_Devices", str=device)
	PGC_SetAndActivateControl(unlockedDevice, "button_SettingsPlus_LockDevice")

	REQUIRE(WindowExists(device))

	PGC_SetAndActivateControl(device, "ADC", val=0)
	DoUpdate/W=$device

	PGC_SetAndActivateControl(device, "Popup_Settings_HEADSTAGE", val = 0)
	PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")

	PGC_SetAndActivateControl(device, "Popup_Settings_HEADSTAGE", val = 1)
	PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")

	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = PSQ_TEST_HEADSTAGE)
	PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", val = 1)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, PSQ_TEST_HEADSTAGE), val=1)

	DoUpdate/W=$device

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = 25)

	PGC_SetAndActivateControl(device, "Popup_Settings_VC_DA", str = "0")
	PGC_SetAndActivateControl(device, "Popup_Settings_IC_DA", str = "0")
	PGC_SetAndActivateControl(device, "Popup_Settings_VC_AD", str = "1")
	PGC_SetAndActivateControl(device, "Popup_Settings_IC_AD", str = "1")

	PGC_SetAndActivateControl(device, "button_Hardware_AutoGainAndUnit")

	PGC_SetAndActivateControl(device, GetPanelControl(PSQ_TEST_HEADSTAGE, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)

	stimset = "PSQ_TrueRest_DA_0"
	AdjustAnalysisParamsForPSQ(device, stimset)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = stimset)

	PGC_SetAndActivateControl(device, "check_Settings_MD", val = s.MD)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = s.RA)
	PGC_SetAndActivateControl(device, "Check_DataAcq_Indexing", val = s.IDX)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_IndexingLocked", val = s.LIDX)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_SetRepeats", val = s.RES)
	PGC_SetAndActivateControl(device, "Check_Settings_SkipAnalysFuncs", val = 0)

	if(!s.MD)
		PGC_SetAndActivateControl(device, "Check_Settings_BackgrndDataAcq", val = s.BKG_DAQ)
	else
		CHECK_EQUAL_VAR(s.BKG_DAQ, 1)
	endif

	DoUpdate/W=$device

	if(!ParamIsDefault(preAcquireFunc))
		preAcquireFunc(device)
	endif

	OpenDatabrowser()

	StartZeroMQSockets(forceRestart = 1)

	zeromq_sub_add_filter("")
	zeromq_sub_connect("tcp://127.0.0.1:" + num2str(ZEROMQ_BIND_PUB_PORT))

	WaitForPubSubHeartbeat()

	PGC_SetAndActivateControl(device, "DataAcquireButton")
End

static Function/WAVE GetLBNSingleEntry_IGNORE(device, sweepNo, name, [chunk])
	string device
	variable sweepNo, chunk
	string name

	variable val, type
	string key

	CHECK(IsValidSweepNumber(sweepNo))
	CHECK_LE_VAR(sweepNo, AFH_GetLastSweepAcquired(device))

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues = GetLBTextualValues(device)

	type = PSQ_TRUE_REST_VM

	strswitch(name)
		case PSQ_FMT_LBN_SWEEP_PASS:
		case PSQ_FMT_LBN_SAMPLING_PASS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_BL_QC_PASS:
		case PSQ_FMT_LBN_SPIKE_PASS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_SET_PASS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			val = GetLastSettingIndepSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
			Make/D/FREE wv = {val}
			return wv
		case PSQ_FMT_LBN_VM_FULL_AVG:
		case PSQ_FMT_LBN_VM_FULL_AVG_ADIFF:
		case PSQ_FMT_LBN_VM_FULL_AVG_ADIFF_PASS:
		case PSQ_FMT_LBN_VM_FULL_AVG_RDIFF:
		case PSQ_FMT_LBN_VM_FULL_AVG_RDIFF_PASS:
		case PSQ_FMT_LBN_VM_FULL_AVG_PASS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_SPIKE_POSITIONS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			return GetLastSettingTextEachSCI(numericalValues, textualValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_CHUNK_PASS:
			key = CreateAnaFuncLBNKey(type, name, chunk = chunk, query = 1)
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_RMS_SHORT_PASS:
		case PSQ_FMT_LBN_RMS_LONG_PASS:
		case PSQ_FMT_LBN_AVERAGEV:
			key = CreateAnaFuncLBNKey(type, name, chunk = chunk, query = 1)
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case "Autobias Vcom":
		case "Autobias":
			return GetLastSettingEachSCI(numericalValues, sweepNo, name, PSQ_TEST_HEADSTAGE, DATA_ACQUISITION_MODE)
		case "Inter-trial interval":
		case "Get/Set Inter-trial interval":
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, name, PSQ_TEST_HEADSTAGE, DATA_ACQUISITION_MODE)
		default:
			FAIL()
	endswitch
End

static Function/WAVE GetWave_IGNORE()

	string list = "sweepPass;setPass;baselinePass;spikePass;samplingPass;" + \
	              "spikePositions;autobiasVCom;autobias;"                  + \
	              "fullAvg;fullAvgPass;"                                   + \
	              "fullAvgADiff;fullAvgADiffPass;"                         + \
	              "fullAvgRDiff;fullAvgRDiffPass;"                         + \
	              "baselineQCChunk0;baselineQCChunk1;"                     + \
	              "rmsShortQCChunk0;rmsShortQCChunk1;"                     + \
	              "rmsLongQCChunk0;rmsLongQCChunk1;"                       + \
	              "averageVChunk0;averageVChunk1;"                         + \
	              "iti;getsetiti"

	Make/FREE/WAVE/N=(ItemsInList(list)) wv
	SetDimensionLabels(wv, list, ROWS)

	return wv
End

static Function/WAVE GetEntries_IGNORE(string device, variable sweepNo)

	WAVE numericalValues = GetLBNumericalValues(device)

	WAVE/WAVE wv = GetWave_IGNORE()

	wv[%sweepPass]    = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	wv[%setPass]      = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SET_PASS)
	wv[%baselinePass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	wv[%spikePass]    = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SPIKE_PASS)
	wv[%samplingPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)

	wv[%spikePositions] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SPIKE_POSITIONS)

	wv[%autobiasVcom] = GetLBNSingleEntry_IGNORE(device, sweepNo, "Autobias Vcom")
	wv[%autobias]     = GetLBNSingleEntry_IGNORE(device, sweepNo, "Autobias")
	wv[%iti]          = GetLBNSingleEntry_IGNORE(device, sweepNo, "Inter-trial interval")
	wv[%getsetiti]    = GetLBNSingleEntry_IGNORE(device, sweepNo, "Get/Set Inter-trial interval")

	wv[%fullAvg]      = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_VM_FULL_AVG)
	wv[%fullAvgADiff]     = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_VM_FULL_AVG_ADIFF)
	wv[%fullAvgADiffPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_VM_FULL_AVG_ADIFF_PASS)
	wv[%fullAvgRDiff]     = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_VM_FULL_AVG_RDIFF)
	wv[%fullAvgRDiffPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_VM_FULL_AVG_RDIFF_PASS)

	wv[%fullAvgPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_VM_FULL_AVG_PASS)

	wv[%baselineQCChunk0] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 0)
	wv[%baselineQCChunk1] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_CHUNK_PASS, chunk = 1)
	wv[%rmsShortQCChunk0] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 0)
	wv[%rmsShortQCChunk1] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 1)
	wv[%rmsLongQCChunk0]  = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 0)
	wv[%rmsLongQCChunk1]  = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 1)
	wv[%averageVChunk0]   = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_AVERAGEV, chunk = 0)
	wv[%averageVChunk1]   = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_AVERAGEV, chunk = 1)

	REQUIRE_EQUAL_VAR(GetRTerror(1), 0)

	return wv
End

static Function [string stimset, string stimsetIndexEnd] GetStimsets_IGNORE(string device)
	variable DAC
	string ctrl0, ctrl1

	DAC   = AFH_GetDACFromHeadstage(device, PSQ_TEST_HEADSTAGE)
	ctrl0 = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	ctrl1 = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)

	return [DAG_GetTextualValue(device, ctrl0, index = DAC), DAG_GetTextualValue(device, ctrl1, index = DAC)]
End

Function CheckBaselineChunks(string device, WAVE chunkTimes)

	CheckUserEpochs(device, {20, 520, 625, 1125}, EPOCH_SHORTNAME_USER_PREFIX + "BLS%d", sweep = 0)
	CheckPSQChunkTimes(device, chunkTimes)
End

static Function PS_VM1_IGNORE(device)
	string device

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var=0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var=1)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var=10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var=5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var=-3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var=0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var=0)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_VM1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_VM1_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// all tests fail
	wv[][][0] = 0

	// number of spikes
	wv[][][1] = 1 + q

	// average baseline voltages
	// chunk 0
	wv[0][0][0][4] = 12
	wv[0][1][0][4] = 13
	wv[0][2][0][4] = 14

	// chunk 1
	wv[1][0][0][4] = 16
	wv[1][1][0][4] = 17
	wv[1][2][0][4] = 18
End

static Function PS_VM1_REENTRY([string str])
	variable sweepNo
	string stimset, stimsetIndexEnd, expected

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%baselineQCChunk1], NULL_WAVE)

	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%rmsShortQCChunk1], NULL_WAVE)

	CHECK_WAVE(entries[%rmsLongQCChunk0], NULL_WAVE)
	CHECK_WAVE(entries[%rmsLongQCChunk1], NULL_WAVE)

	CHECK_WAVE(entries[%averageVChunk0], NULL_WAVE)
	CHECK_WAVE(entries[%averageVChunk1], NULL_WAVE)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%fullAvg], NULL_WAVE)
	CHECK_WAVE(entries[%fullAvgADiff], NULL_WAVE)
	CHECK_WAVE(entries[%fullAvgRDiff], NULL_WAVE)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(entries[%spikePositions], {"1;", "2;2;", "3;3;3;"}, mode = WAVE_DATA)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Indexing"), 0)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0, 11, 12}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 13)

	CHECK_EQUAL_WAVES(entries[%autobias], {0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 1)

	CHECK_EQUAL_WAVES(entries[%iti], {0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 1)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	[stimset, stimsetIndexEnd]  = GetStimsets_IGNORE(str)
	expected = "PSQ_TrueRest_DA_0"
	CHECK_EQUAL_STR(stimset, expected)
	expected = NONE
	CHECK_EQUAL_STR(stimsetIndexEnd, expected)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
End

static Function PS_VM2_IGNORE(device)
	string device

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var=0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var=0)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var=10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var=5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var=-3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var=0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var=0)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_VM2([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_VM2_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// all tests pass
	wv[][][0] = 1

	// number of spikes
	wv[][][1] = 0

	// average baseline voltages
	// chunk 0
	wv[0][0][0][4] = 12
	wv[0][1][0][4] = 13
	wv[0][2][0][4] = 14

	// chunk 1
	wv[1][0][0][4] = 12
	wv[1][1][0][4] = 13
	wv[1][2][0][4] = 14
End

static Function PS_VM2_REENTRY([string str])
	variable sweepNo
	string stimset, stimsetIndexEnd, expected

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineQCChunk1], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk1], {-1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk1], {-1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {12e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {12e-3}, mode = WAVE_DATA, tol = 1e-12)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)

	Make/D/FREE fullAvg = {12e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {0}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA)

	Make/D/FREE fullAvgRDiff = {0}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%spikePositions], NULL_WAVE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Indexing"), 1)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 12)

	CHECK_EQUAL_WAVES(entries[%autobias], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 1)

	CHECK_EQUAL_WAVES(entries[%iti], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 0)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	[stimset, stimsetIndexEnd] = GetStimsets_IGNORE(str)
	expected = "StimulusSetA_DA_0"
	CHECK_EQUAL_STR(stimset, expected)
	expected = "StimulusSetB_DA_0"
	CHECK_EQUAL_STR(stimsetIndexEnd, expected)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520, 625, 1125})
End

static Function PS_VM3_IGNORE(device)
	string device

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var=0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var=0)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var=10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var=5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var=-3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var=0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var=0)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_VM3([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_VM3_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// tests pass, except BL QC in chunk0
	wv[][][0]  = 1
	wv[0][][0] = 0

	// number of spikes
	wv[][][1] = 0

	// average baseline voltages
	// chunk 0
	wv[0][0][0][4] = 12
	wv[0][1][0][4] = 13
	wv[0][2][0][4] = 14

	// chunk 1
	wv[1][0][0][4] = 12
	wv[1][1][0][4] = 13
	wv[1][2][0][4] = 14
End

static Function PS_VM3_REENTRY([string str])
	variable sweepNo
	string stimset, stimsetIndexEnd, expected

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%baselineQCChunk1], NULL_WAVE)

	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%rmsShortQCChunk1], NULL_WAVE)

	CHECK_WAVE(entries[%rmsLongQCChunk0], NULL_WAVE)
	CHECK_WAVE(entries[%rmsLongQCChunk1], NULL_WAVE)

	CHECK_WAVE(entries[%averageVChunk0], NULL_WAVE)
	CHECK_WAVE(entries[%averageVChunk1], NULL_WAVE)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%fullAvg], NULL_WAVE)
	CHECK_WAVE(entries[%fullAvgADiff], NULL_WAVE)
	CHECK_WAVE(entries[%fullAvgRDiff], NULL_WAVE)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%spikePositions], NULL_WAVE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Indexing"), 0)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 0)

	CHECK_EQUAL_WAVES(entries[%autobias], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 0)

	CHECK_EQUAL_WAVES(entries[%iti], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 0)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	[stimset, stimsetIndexEnd]  = GetStimsets_IGNORE(str)
	expected = "PSQ_TrueRest_DA_0"
	CHECK_EQUAL_STR(stimset, expected)
	expected = NONE
	CHECK_EQUAL_STR(stimsetIndexEnd, expected)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
End

static Function PS_VM4_IGNORE(device)
	string device

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var=0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var=0)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var=10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var=5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var=-3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var=inf)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var=0)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_VM4([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_VM4_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// tests pass, except relative average voltage diff
	wv[][][0]  = 1

	// number of spikes
	wv[][][1] = 0

	// average baseline voltages
	// chunk 0
	wv[0][0][0][4] = 12
	wv[0][1][0][4] = 13
	wv[0][2][0][4] = 14

	// chunk 1
	wv[1][0][0][4] = 16
	wv[1][1][0][4] = 17
	wv[1][2][0][4] = 18
End

static Function PS_VM4_REENTRY([string str])
	variable sweepNo
	string stimset, stimsetIndexEnd, expected

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineQCChunk1], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk1], {-1, -1, -1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk1], {-1, -1, -1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {12e-3, 13e-3, 14e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {16e-3, 17e-3, 18e-3}, mode = WAVE_DATA, tol = 1e-12)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	Make/D/FREE fullAvg = {14e-3, 15e-3, 16e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {-4e-3, -4e-3, -4e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgRDiff = {-0.33, -0.30, -0.28}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA, tol = 1e-2)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%spikePositions], NULL_WAVE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Indexing"), 0)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 0)

	CHECK_EQUAL_WAVES(entries[%autobias], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 0)

	CHECK_EQUAL_WAVES(entries[%iti], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 0)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	[stimset, stimsetIndexEnd]  = GetStimsets_IGNORE(str)
	expected = "PSQ_TrueRest_DA_0"
	CHECK_EQUAL_STR(stimset, expected)
	expected = NONE
	CHECK_EQUAL_STR(stimsetIndexEnd, expected)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520, 625, 1125})
End

static Function PS_VM5_IGNORE(device)
	string device

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var=0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var=0)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var=10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var=5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var=-3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var=0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var=inf)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_VM5([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_VM5_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// tests pass, except absolute average voltage diff
	wv[][][0]  = 1

	// number of spikes
	wv[][][1] = 0

	// average baseline voltages
	// chunk 0
	wv[0][0][0][4] = 12
	wv[0][1][0][4] = 13
	wv[0][2][0][4] = 14

	// chunk 1
	wv[1][0][0][4] = 16
	wv[1][1][0][4] = 17
	wv[1][2][0][4] = 18
End

static Function PS_VM5_REENTRY([string str])
	variable sweepNo
	string stimset, stimsetIndexEnd, expected

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineQCChunk1], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk1], {-1, -1, -1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk1], {-1, -1, -1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {12e-3, 13e-3, 14e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {16e-3, 17e-3, 18e-3}, mode = WAVE_DATA, tol = 1e-12)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	Make/D/FREE fullAvg = {14e-3, 15e-3, 16e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {-4e-3, -4e-3, -4e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgRDiff = {-0.33, -0.30, -0.28}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA, tol = 1e-2)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%spikePositions], NULL_WAVE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Indexing"), 0)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 0)

	CHECK_EQUAL_WAVES(entries[%autobias], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 0)

	CHECK_EQUAL_WAVES(entries[%iti], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 0)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	[stimset, stimsetIndexEnd]  = GetStimsets_IGNORE(str)
	expected = "PSQ_TrueRest_DA_0"
	CHECK_EQUAL_STR(stimset, expected)
	expected = NONE
	CHECK_EQUAL_STR(stimsetIndexEnd, expected)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520, 625, 1125})
End

static Function PS_VM5a_IGNORE(device)
	string device

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var=0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var=10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var=5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var=-3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var=0.1)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var=10)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_VM5a([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_VM5a_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// sweep 0:
	// fail due to abs avg diff
	// sweep 1:
	// fail due to rel avg diff
	// sweep 2:
	// pass

	// BL QC passes
	wv[][][0] = 1

	// number of spikes
	wv[][][1] = 0

	// average baseline voltages
	// chunk 0
	wv[0][0][0][4] = 10
	wv[0][1][0][4] = 0.1
	wv[0][2][0][4] = 1

	// chunk 1
	wv[1][0][0][4] = 11
	wv[1][1][0][4] = 0.15
	wv[1][2][0][4] = 1.05
End

static Function PS_VM5a_REENTRY([string str])
	variable sweepNo
	string stimset, stimsetIndexEnd, expected

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineQCChunk1], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk1], {-1, -1, -1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk0], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk1], {-1, -1, -1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {10e-3, 0.1e-3, 1e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {11e-3, 0.15e-3, 1.05e-3}, mode = WAVE_DATA, tol = 1e-12)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	Make/D/FREE fullAvg = {10.5e-3, 0.125e-3, 1.025e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {-1e-3, -0.05e-3, -0.05e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgRDiff = {-0.1, -0.5, -0.05}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA, tol = 1e-3)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {0, 0, 1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%spikePositions], NULL_WAVE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Indexing"), 1)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_CLOSE_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 1.025, tol=1e-6)

	CHECK_EQUAL_WAVES(entries[%autobias], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 1)

	CHECK_EQUAL_WAVES(entries[%iti], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 0)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	[stimset, stimsetIndexEnd] = GetStimsets_IGNORE(str)
	expected = "StimulusSetA_DA_0"
	CHECK_EQUAL_STR(stimset, expected)
	expected = "StimulusSetB_DA_0"
	CHECK_EQUAL_STR(stimsetIndexEnd, expected)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520, 625, 1125})
End

static Function PS_VM5b_IGNORE(device)
	string device

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var=0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var=0)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	// NextIndexingEndStimSetName not set
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var=10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var=5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var=-3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var=0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var=0)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_VM5b([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_VM5b_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// all tests pass
	wv[][][0] = 1

	// number of spikes
	wv[][][1] = 0

	// average baseline voltages
	// chunk 0
	wv[0][0][0][4] = 12
	wv[0][1][0][4] = 13
	wv[0][2][0][4] = 14

	// chunk 1
	wv[1][0][0][4] = 12
	wv[1][1][0][4] = 13
	wv[1][2][0][4] = 14
End

static Function PS_VM5b_REENTRY([string str])
	variable sweepNo
	string stimset, stimsetIndexEnd, expected

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineQCChunk1], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk1], {-1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk1], {-1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {12e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {12e-3}, mode = WAVE_DATA, tol = 1e-12)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)

	Make/D/FREE fullAvg = {12e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {0}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA)

	Make/D/FREE fullAvgRDiff = {0}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%spikePositions], NULL_WAVE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Indexing"), 0)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 12)

	CHECK_EQUAL_WAVES(entries[%autobias], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 1)

	CHECK_EQUAL_WAVES(entries[%iti], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 0)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	[stimset, stimsetIndexEnd] = GetStimsets_IGNORE(str)
	expected = "StimulusSetA_DA_0"
	CHECK_EQUAL_STR(stimset, expected)
	expected = NONE
	CHECK_EQUAL_STR(stimsetIndexEnd, expected)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520, 625, 1125})
End

static Function PS_VM6_IGNORE(device)
	string device

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var=0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var=0)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var=600)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var=10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var=5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var=-3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var=0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var=0)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_VM6([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_VM6_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// all tests pass, but see below
	wv[][][0]  = 1

	// number of spikes
	wv[][][1] = 0

	// average baseline voltages
	// chunk 0
	wv[0][0][0][4] = 12
	wv[0][1][0][4] = 13
	wv[0][2][0][4] = 14

	// chunk 1
	wv[1][0][0][4] = 12
	wv[1][1][0][4] = 13
	wv[1][2][0][4] = 14

	// DAQ is not started as PRE_SWEEP_CONFIG_EVENT fails due to non-matching BaselineChunkLength
	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)
	CHECK_EQUAL_VAR(AFH_GetlastSweepAcquired(str), NaN)
End

static Function PS_VM7_IGNORE(device)
	string device

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var=0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var=1)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var=1)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var=10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var=5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var=-3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var=0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var=0)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_VM7([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_VM7_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// tests pass, except for 1 spike
	wv[][][0]  = 1

	// number of spikes
	wv[][][1] = 1

	// average baseline voltages
	// chunk 0
	wv[0][0][0][4] = 12
	wv[0][1][0][4] = 13
	wv[0][2][0][4] = 14

	// chunk 1
	wv[1][0][0][4] = 12
	wv[1][1][0][4] = 13
	wv[1][2][0][4] = 14
End

static Function PS_VM7_REENTRY([string str])
	variable sweepNo
	string stimset, stimsetIndexEnd, expected

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineQCChunk1], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk1], {-1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk1], {-1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {12e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {12e-3}, mode = WAVE_DATA, tol = 1e-12)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)

	Make/D/FREE fullAvg = {12e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {0}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgRDiff = {0}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA, tol = 1e-2)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(entries[%spikePositions], {"1;"}, mode = WAVE_DATA)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Indexing"), 0)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 6 + 3)

	CHECK_EQUAL_WAVES(entries[%autobias], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 1)

	CHECK_EQUAL_WAVES(entries[%iti], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 1)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	[stimset, stimsetIndexEnd]  = GetStimsets_IGNORE(str)
	expected = "PSQ_TrueRest_DA_0"
	CHECK_EQUAL_STR(stimset, expected)
	expected = NONE
	CHECK_EQUAL_STR(stimsetIndexEnd, expected)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520, 625, 1125})
End

static Function PS_VM7a_IGNORE(device)
	string device

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var=0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var=1)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var=10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var=5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var=-3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var=0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var=0)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_VM7a([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_VM7a_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// tests pass, except for 1 spike
	wv[][][0]  = 1

	// number of spikes [1, 0]
	wv[][][1]  = 0
	wv[][0][1] = 1

	// average baseline voltages
	// chunk 0
	wv[0][0][0][4] = 12
	wv[0][1][0][4] = 13
	wv[0][2][0][4] = 14

	// chunk 1
	wv[1][0][0][4] = 12
	wv[1][1][0][4] = 13
	wv[1][2][0][4] = 14
End

static Function PS_VM7a_REENTRY([string str])
	variable sweepNo
	string stimset, stimsetIndexEnd, expected

	sweepNo = 1

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineQCChunk1], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk1], {-1, -1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk0], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk1], {-1, -1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {12e-3, 13e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {12e-3, 13e-3}, mode = WAVE_DATA, tol = 1e-12)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1}, mode = WAVE_DATA)

	Make/D/FREE fullAvg = {12e-3, 13e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {0, 0}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgRDiff = {0, 0}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA, tol = 1e-2)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_TEXTWAVES(entries[%spikePositions], {"1;", ""}, mode = WAVE_DATA)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Indexing"), 1)

	// first sweep does not have autobias enabled
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0, 6 + 3}, mode = WAVE_DATA)
	CHECK_CLOSE_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 13, tol = 1e-12)

	CHECK_EQUAL_WAVES(entries[%autobias], {0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 1)

	CHECK_EQUAL_WAVES(entries[%iti], {0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 1)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	[stimset, stimsetIndexEnd] = GetStimsets_IGNORE(str)
	expected = "StimulusSetA_DA_0"
	CHECK_EQUAL_STR(stimset, expected)
	expected = "StimulusSetB_DA_0"
	CHECK_EQUAL_STR(stimsetIndexEnd, expected)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520, 625, 1125})
End

static Function PS_VM8_IGNORE(device)
	string device

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineRMSShortThreshold", var=0.07)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "InterTrialInterval", var=0)

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SamplingFrequency", var=10)
	// SamplingMultiplier use defaults

	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NumberOfFailedSweeps", var=1)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "SpikeFailureIgnoredTime", var=10)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "FailedLevel", var=5)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "UserOffsetTargetVAutobias", var=-3)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "AbsoluteVoltageDiff", var=0)
	AFH_AddAnalysisParameter("PSQ_TrueRest_DA_0", "RelativeVoltageDiff", var=100)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function PS_VM8([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_VM8_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_TRUE_REST_VM)

	// tests pass, except sampling QC fails
	wv[][][0]  = 1

	// number of spikes
	wv[][][1] = 0

	// average baseline voltages
	// chunk 0
	wv[0][0][0][4] = 12
	wv[0][1][0][4] = 13
	wv[0][2][0][4] = 14

	// chunk 1
	wv[1][0][0][4] = 12
	wv[1][1][0][4] = 13
	wv[1][2][0][4] = 14
End

static Function PS_VM8_REENTRY([string str])
	variable sweepNo
	string stimset, stimsetIndexEnd, expected

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselineQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselineQCChunk1], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsShortQCChunk1], {-1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongQCChunk1], {-1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%averageVChunk0], {12e-3}, mode = WAVE_DATA, tol = 1e-12)
	CHECK_EQUAL_WAVES(entries[%averageVChunk1], {12e-3}, mode = WAVE_DATA, tol = 1e-12)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {0}, mode = WAVE_DATA)

	Make/D/FREE fullAvg = {12e-3}
	CHECK_EQUAL_WAVES(entries[%fullAvg], fullAvg, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgADiff = {0}
	CHECK_EQUAL_WAVES(entries[%fullAvgADiff], fullAvgADiff, mode = WAVE_DATA, tol = 1e-12)

	Make/D/FREE fullAvgRDiff = {0}
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiff], fullAvgRDiff, mode = WAVE_DATA, tol = 1e-2)

	CHECK_EQUAL_WAVES(entries[%fullAvgADiffPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgRDiffPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fullAvgPass], {1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%spikePositions], NULL_WAVE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Indexing"), 0)

	// first sweep does not have autobias enabled
	// and the last sweep's setting is only available in the GUI
	CHECK_EQUAL_WAVES(entries[%autobiasVcom], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_AutoBiasV"), 0)

	CHECK_EQUAL_WAVES(entries[%autobias], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DataAcq_AutoBias"), 0)

	CHECK_EQUAL_WAVES(entries[%iti], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "SetVar_DataAcq_ITI"), 0)

	CHECK_EQUAL_WAVES(entries[%getsetiti], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "Check_DataAcq_Get_Set_ITI"), 1)

	[stimset, stimsetIndexEnd]  = GetStimsets_IGNORE(str)
	expected = "PSQ_TrueRest_DA_0"
	CHECK_EQUAL_STR(stimset, expected)
	expected = NONE
	CHECK_EQUAL_STR(stimsetIndexEnd, expected)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520, 625, 1125})
End
