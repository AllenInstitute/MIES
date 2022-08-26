#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=PatchSeqAccessResistanceSmoke

/// Test matrix
/// @rst
///
/// .. Column order: test overrides, analysis parameters
///
/// =========== ==================== ================= =================== ========================= ========================= ============================== ========================== ======================= ====================== =================== ============================ =======================
///  Test case   Baseline chunk0 QC   Leak Current QC   Access Resistance   Steady State Resistance   Async channels QC         Max Access Resistance [MOhm]   Max Resistance Ratio [%]   Baseline Chunk Length   NumberOfFailedSweeps   NextStimSetName     NextIndexingEndStimSetName   Sampling Frequency QC
/// =========== ==================== ================= =================== ========================= ========================= ============================== ========================== ======================= ====================== =================== ============================ =======================
///  PS_AR1      -                    -                 20                  25                        -                         10                             50                         500                     3                      StimulusSetA_DA_0   StimulusSetB_DA_0            1
///  PS_AR2      ✓                    ✓                 5                   6                         ✓                         10                             90                         500                     3                      StimulusSetA_DA_0   StimulusSetB_DA_0            1
///  PS_AR3      ✓                    ✓                 5                   6                         ✓                          4                             90                         500                     3                      StimulusSetA_DA_0   StimulusSetB_DA_0            1
///  PS_AR4      ✓                    ✓                 5                   6                         ✓                         10                             50                         500                     3                      StimulusSetA_DA_0   StimulusSetB_DA_0            1
///  PS_AR5      ✓                    -                 5                   6                         ✓                         10                             90                         500                     3                      StimulusSetA_DA_0   StimulusSetB_DA_0            1
///  PS_AR6      [-,✓,✓,✓ ]           [-,✓,✓,✓ ]        [5, 15, 5, 5]       [6, 18, 3, 6]             ✓                         10                             90                         500                     5                      StimulusSetA_DA_0   StimulusSetB_DA_0            1
///  PS_AR6a     ✓                    ✓                 5                   6                         -                         10                             90                         500                     3                      StimulusSetA_DA_0   StimulusSetB_DA_0            1
///  PS_AR7      ✓                    ✓                 5                   6                         ✓                         10                             90                         600                     3                      StimulusSetA_DA_0   StimulusSetB_DA_0            1
///  PS_AR8      ✓                    ✓                 5                   6                         ✓                         10                             90                         500                     3                      StimulusSetA_DA_0   StimulusSetB_DA_0            0
/// =========== ==================== ================= =================== ========================= ========================= ============================== ========================== ======================= ====================== =================== ============================ =======================
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

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(V_CLAMP_MODE, PSQ_TEST_HEADSTAGE), val=1)

	DoUpdate/W=$device

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = 25)

	PGC_SetAndActivateControl(device, "Popup_Settings_VC_DA", str = "0")
	PGC_SetAndActivateControl(device, "Popup_Settings_IC_DA", str = "0")
	PGC_SetAndActivateControl(device, "Popup_Settings_VC_AD", str = "1")
	PGC_SetAndActivateControl(device, "Popup_Settings_IC_AD", str = "1")

	PGC_SetAndActivateControl(device, "button_Hardware_AutoGainAndUnit")

	PGC_SetAndActivateControl(device, GetPanelControl(PSQ_TEST_HEADSTAGE, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)

	stimset = "PSQ_QC_stimsets_DA_0"
	AdjustAnalysisParamsForPSQ(device, stimset)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = stimset)

	ST_SetStimsetParameter(stimset, "Analysis function (generic)", str = "PSQ_AccessResistanceSmoke")

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
	PrepareForPublishTest()

	PGC_SetAndActivateControl(device, "DataAcquireButton")
End

static Function/WAVE GetResultsSingleEntry_IGNORE(string name)
	WAVE/T textualResultsValues = GetTextualResultsValues()

	WAVE/Z indizesName = GetNonEmptyLBNRows(textualResultsValues, name)
	WAVE/Z indizesType = GetNonEmptyLBNRows(textualResultsValues, "EntrySourceType")

	if(!WaveExists(indizesName) || !WaveExists(indizesType))
		return $""
	endif

	indizesType[] = (str2numSafe(textualResultsValues[indizesType[p]][%$"EntrySourceType"][INDEP_HEADSTAGE]) == SWEEP_FORMULA_RESULT) ? indizesType[p] : NaN

	WAVE/Z indizesTypeClean = ZapNaNs(indizesType)

	if(!WaveExists(indizesTypeClean))
		return $""
	endif

	WAVE/Z indizes = GetSetIntersection(indizesName, indizesTypeClean)

	if(!WaveExists(indizes))
		return $""
	endif

	Make/FREE/T/N=(DimSize(indizes, ROWS)) entries = textualResultsValues[indizes[p]][%$name][INDEP_HEADSTAGE]

	return entries
End

static Function/WAVE GetLBNSingleEntry_IGNORE(device, sweepNo, name)
	string device
	variable sweepNo
	string name

	variable val, type
	string key

	CHECK(IsValidSweepNumber(sweepNo))
	CHECK_LE_VAR(sweepNo, AFH_GetLastSweepAcquired(device))

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues = GetLBTextualValues(device)

	type = PSQ_ACC_RES_SMOKE

	strswitch(name)
		case PSQ_FMT_LBN_AR_RESISTANCE_RATIO:
		case PSQ_FMT_LBN_AR_RESISTANCE_RATIO_PASS:
		case PSQ_FMT_LBN_AR_ACCESS_RESISTANCE:
		case PSQ_FMT_LBN_AR_ACCESS_RESISTANCE_PASS:
		case PSQ_FMT_LBN_AR_STEADY_STATE_RESISTANCE:
		case PSQ_FMT_LBN_SWEEP_PASS:
		case PSQ_FMT_LBN_SAMPLING_PASS:
		case PSQ_FMT_LBN_ASYNC_PASS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_BL_QC_PASS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_SET_PASS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			val = GetLastSettingIndepSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
			Make/D/FREE wv = {val}
			return wv
		case PSQ_FMT_LBN_RMS_SHORT_PASS:
		case PSQ_FMT_LBN_RMS_LONG_PASS:
		case PSQ_FMT_LBN_LEAKCUR_PASS:
		case PSQ_FMT_LBN_LEAKCUR:
			key = CreateAnaFuncLBNKey(type, name, chunk = 0, query = 1)
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		default:
			FAIL()
	endswitch
End

static Function/WAVE GetWave_IGNORE()

	string list = "sweepPass;setPass;rmsShortPass;rmsLongPass;leakCur;leakCurPass;baselinePass;" + \
	              "samplingPass;"                                                                + \
	              "accResistance;accResistancePass;"                                             + \
	              "ssResistance;resistanceRatio;resistanceRatioPass;"                            + \
	              "resultsSweep;resultsPeakResistance;resultsSSResistance;asyncPass"

	Make/FREE/WAVE/N=(ItemsInList(list)) wv
	SetDimensionLabels(wv, list, ROWS)

	return wv
End

static Function/WAVE GetEntries_IGNORE(string device, variable sweepNo)

	WAVE numericalValues = GetLBNumericalValues(device)

	WAVE/WAVE wv = GetWave_IGNORE()

	wv[%sweepPass]    = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	wv[%setPass]      = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SET_PASS)
	wv[%samplingPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)

	wv[%rmsShortPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS)
	wv[%rmsLongPass]  = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS)
	wv[%leakCur]      = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_LEAKCUR)
	wv[%leakCurPass]  = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_LEAKCUR_PASS)
	wv[%baselinePass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)

	wv[%accResistance]       = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_AR_ACCESS_RESISTANCE)
	wv[%accResistancePass]   = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_AR_ACCESS_RESISTANCE_PASS)
	wv[%ssResistance]        = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_AR_STEADY_STATE_RESISTANCE)
	wv[%resistanceRatio]     = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_AR_RESISTANCE_RATIO)
	wv[%resistanceRatioPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_AR_RESISTANCE_RATIO_PASS)
	wv[%asyncPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)

	wv[%resultsSweep] = ExtractSweepsFromSFPairs(GetResultsSingleEntry_IGNORE("Sweep Formula sweeps/channels"))
	wv[%resultsSSResistance] = GetResultsSingleEntry_IGNORE("Sweep Formula store [Steady state resistance]")
	wv[%resultsPeakResistance] = GetResultsSingleEntry_IGNORE("Sweep Formula store [Peak resistance]")

	return wv
End

static Function CheckBaselineChunks(string device, WAVE chunkTimes, [variable sweepNo])

	if(ParamIsDefault(sweepNo))
		CheckUserEpochs(device, {20, 520}, EPOCH_SHORTNAME_USER_PREFIX + "BLS%d")
		CheckPSQChunkTimes(device, chunkTimes)
	else
		CheckUserEpochs(device, {20, 520}, EPOCH_SHORTNAME_USER_PREFIX + "BLS%d", sweep = sweepNo)
		CheckPSQChunkTimes(device, chunkTimes, sweep = sweepNo)
	endif
End

static Function CheckTestPulseLikeEpochs(string device,[variable incomplete, variable sweep])

	if(ParamIsDefault(incomplete))
		incomplete = 0
	else
		incomplete = !!incomplete
	endif

	if(ParamIsDefault(sweep))
		sweep = NaN
	endif

	// user epochs are the same for all sweeps, so we only check the first sweep

	if(!incomplete)
		CheckUserEpochs(device, {520, 1030, 1030, 1540, 1540, 2050}, EPOCH_SHORTNAME_USER_PREFIX + "TP%d", sweep = sweep)
		CheckUserEpochs(device, {520, 770, 1030, 1280, 1540, 1790}, EPOCH_SHORTNAME_USER_PREFIX + "TP%d_B0", sweep = sweep)
		CheckUserEpochs(device, {770, 780, 1280, 1290, 1790, 1800}, EPOCH_SHORTNAME_USER_PREFIX + "TP%d_P", sweep = sweep)
		CheckUserEpochs(device, {780, 1030, 1290, 1540, 1800, 2050}, EPOCH_SHORTNAME_USER_PREFIX + "TP%d_B1", sweep = sweep)
	else
		// due to timing issues on failed sets/sweeps we don't know how many and what epochs we have
		Make/FREE/N=0 times
		CheckUserEpochs(device, times, "TP%d", ignoreIncomplete = 1, sweep = sweep)
		CheckUserEpochs(device, times, "TP%d_B0", ignoreIncomplete = 1, sweep = sweep)
		CheckUserEpochs(device, times, "TP%d_P", ignoreIncomplete = 1, sweep = sweep)
		CheckUserEpochs(device, times, "TP%d_B1", ignoreIncomplete = 1, sweep = sweep)
	endif
End

static Function PS_AR1_IGNORE(string device)

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSShortThreshold", var=0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxLeakCurrent", var=2)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessResistance", var=10)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessToSteadyStateResistanceRatio", var=50)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfTestpulses", var=3)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
static Function PS_AR1([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_AR1_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_ACC_RES_SMOKE)

	// all tests fail
	wv[][][0] = 0
	wv[][][1] = 20
	wv[][][2] = 25
End

static Function PS_AR1_REENTRY([string str])
	variable sweepNo
	string stimset, expected, stimsetIndexEnd

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%leakCurPass], NULL_WAVE)
	CHECK_WAVE(entries[%leakCur], NULL_WAVE)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%accResistance], NULL_WAVE)
	CHECK_EQUAL_WAVES(entries[%accResistancePass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%ssResistance], NULL_WAVE)

	CHECK_WAVE(entries[%resistanceRatio], NULL_WAVE)
	CHECK_EQUAL_WAVES(entries[%resistanceRatioPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%resultsSweep], NULL_WAVE)
	CHECK_WAVE(entries[%resultsPeakResistance], NULL_WAVE)
	CHECK_WAVE(entries[%resultsSSResistance], NULL_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
	CheckTestPulseLikeEpochs(str, incomplete = 1)
End

static Function PS_AR2_IGNORE(string device)

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSShortThreshold", var=0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxLeakCurrent", var=2)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessResistance", var=10)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessToSteadyStateResistanceRatio", var=90)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfTestpulses", var=3)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
static Function PS_AR2([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_AR2_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_ACC_RES_SMOKE)

	// all tests pass
	wv[][][0] = 1
	wv[][][1] = 5
	wv[][][2] = 6
	wv[][][3] = 1
End

static Function PS_AR2_REENTRY([string str])
	variable sweepNo
	string stimset, expected, stimsetIndexEnd

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%leakCurPass], {1}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%leakCur], NUMERIC_WAVE)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)

	Make/FREE/D accResistanceRef = {5e6}
	CHECK_EQUAL_WAVES(entries[%accResistance], accResistanceRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%accResistancePass], {1}, mode = WAVE_DATA)

	Make/FREE/D ssResistanceRef = {6e6}
	CHECK_EQUAL_WAVES(entries[%ssResistance], ssResistanceRef, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%resistanceRatio], {0.83}, mode = WAVE_DATA, tol = 1e-2)
	CHECK_EQUAL_WAVES(entries[%resistanceRatioPass], {1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%resultsSweep], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsPeakResistance], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsSSResistance], TEXT_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
	CheckTestPulseLikeEpochs(str)
End

static Function PS_AR3_IGNORE(string device)

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSShortThreshold", var=0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxLeakCurrent", var=2)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessResistance", var=4)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessToSteadyStateResistanceRatio", var=90)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfTestpulses", var=3)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
static Function PS_AR3([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_AR3_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_ACC_RES_SMOKE)

	// tests pass, except access resistance
	wv[][][0] = 1
	wv[][][1] = 5
	wv[][][2] = 6
	wv[][][3] = 1
End

static Function PS_AR3_REENTRY([string str])
	variable sweepNo
	string stimset, expected, stimsetIndexEnd

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%leakCurPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%leakCur], NUMERIC_WAVE)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	Make/FREE/D accResistanceRef = {5e6, 5e6, 5e6}
	CHECK_EQUAL_WAVES(entries[%accResistance], accResistanceRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%accResistancePass], {0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D ssResistanceRef = {6e6, 6e6, 6e6}
	CHECK_EQUAL_WAVES(entries[%ssResistance], ssResistanceRef, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%resistanceRatio], {0.83, 0.83, 0.83}, mode = WAVE_DATA, tol = 1e-2)
	CHECK_EQUAL_WAVES(entries[%resistanceRatioPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%resultsSweep], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsPeakResistance], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsSSResistance], TEXT_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
	CheckTestPulseLikeEpochs(str)
End

static Function PS_AR4_IGNORE(string device)

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSShortThreshold", var=0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxLeakCurrent", var=2)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessResistance", var=10)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessToSteadyStateResistanceRatio", var=50)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfTestpulses", var=3)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
static Function PS_AR4([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_AR4_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_ACC_RES_SMOKE)

	// tests pass, except resistance ratio
	wv[][][0] = 1
	wv[][][1] = 5
	wv[][][2] = 6
	wv[][][3] = 1
End

static Function PS_AR4_REENTRY([string str])
	variable sweepNo
	string stimset, expected, stimsetIndexEnd

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%leakCurPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%leakCur], NUMERIC_WAVE)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	Make/FREE/D accResistanceRef = {5e6, 5e6, 5e6}
	CHECK_EQUAL_WAVES(entries[%accResistance], accResistanceRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%accResistancePass], {1, 1, 1}, mode = WAVE_DATA)

	Make/FREE/D ssResistanceRef = {6e6, 6e6, 6e6}
	CHECK_EQUAL_WAVES(entries[%ssResistance], ssResistanceRef, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%resistanceRatio], {0.83, 0.83, 0.83}, mode = WAVE_DATA, tol = 1e-2)
	CHECK_EQUAL_WAVES(entries[%resistanceRatioPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%resultsSweep], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsPeakResistance], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsSSResistance], TEXT_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
	CheckTestPulseLikeEpochs(str)
End

static Function PS_AR5_IGNORE(string device)

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSShortThreshold", var=0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxLeakCurrent", var=2)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessResistance", var=10)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessToSteadyStateResistanceRatio", var=90)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfTestpulses", var=3)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
static Function PS_AR5([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_AR5_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_ACC_RES_SMOKE)

	// tests pass, except baseline QC via leak current QC
	wv[][][0][]  = 1
	wv[][][0][3] = 0
	wv[][][1] = 5
	wv[][][2] = 6
	wv[][][3] = 1
End

static Function PS_AR5_REENTRY([string str])
	variable sweepNo
	string stimset, expected, stimsetIndexEnd

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%leakCurPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%leakCur], NUMERIC_WAVE)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%accResistance], NULL_WAVE)
	CHECK_EQUAL_WAVES(entries[%accResistancePass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%ssResistance], NULL_WAVE)

	CHECK_WAVE(entries[%resistanceRatio], NULL_WAVE)
	CHECK_EQUAL_WAVES(entries[%resistanceRatioPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%resultsSweep], NULL_WAVE)
	CHECK_WAVE(entries[%resultsPeakResistance], NULL_WAVE)
	CHECK_WAVE(entries[%resultsSSResistance], NULL_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
	CheckTestPulseLikeEpochs(str, incomplete = 1)
End

static Function PS_AR6_IGNORE(string device)

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSShortThreshold", var=0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxLeakCurrent", var=2)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessResistance", var=10)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessToSteadyStateResistanceRatio", var=90)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfFailedSweeps", var=4)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	// not supplied: NextIndexingEndStimSetName
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfTestpulses", var=3)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
static Function PS_AR6([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_AR6_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_ACC_RES_SMOKE)

	// sweep 0:
	// BL QC fails, rest passes
	wv[][0][0][]  = 1
	wv[][0][0][3] = 0
	wv[][0][1]    = 5
	wv[][0][2]    = 6
	wv[][0][3]    = 1

	// sweep 1:
	// accessResistance fails, rest passes
	wv[][1][0][] = 1
	wv[][1][1]   = 15
	wv[][1][2]   = 18
	wv[][1][3]   = 1

	// sweep 2:
	// resistance ratio fails, rest passes
	wv[][2][0][] = 1
	wv[][2][1]   = 5
	wv[][2][2]   = 3
	wv[][2][3]   = 1

	// sweep 3:
	// everything passes
	wv[][3][0][] = 1
	wv[][3][1]   = 5
	wv[][3][2]   = 6
	wv[][3][3]   = 1
End

static Function PS_AR6_REENTRY([string str])
	variable sweepNo
	string stimset, expected, stimsetIndexEnd

	sweepNo = 3

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%leakCurPass], {0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%leakCur], NUMERIC_WAVE)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1, 1}, mode = WAVE_DATA)

	Make/FREE/D accResistanceRef = {NaN, 15e6, 5e6, 5e6}
	CHECK_EQUAL_WAVES(entries[%accResistance], accResistanceRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%accResistancePass], {0, 0, 1, 1}, mode = WAVE_DATA)

	Make/FREE/D ssResistanceRef = {NaN, 18e6, 3e6, 6e6}
	CHECK_EQUAL_WAVES(entries[%ssResistance], ssResistanceRef, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%resistanceRatio], {NaN, 0.83, 1.66, 0.83}, mode = WAVE_DATA, tol = 1e-2)
	CHECK_EQUAL_WAVES(entries[%resistanceRatioPass], {0, 1, 0, 1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%resultsSweep], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsPeakResistance], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsSSResistance], TEXT_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
	CheckTestPulseLikeEpochs(str, sweep = 0, incomplete = 1)
	CheckTestPulseLikeEpochs(str, sweep = 1)
	CheckTestPulseLikeEpochs(str, sweep = 2)
	CheckTestPulseLikeEpochs(str, sweep = 3)
End

static Function PS_AR6a_IGNORE(string device)

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSShortThreshold", var=0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxLeakCurrent", var=2)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessResistance", var=10)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessToSteadyStateResistanceRatio", var=90)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfTestpulses", var=3)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
static Function PS_AR6a([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_AR6a_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_ACC_RES_SMOKE)

	// tests pass, except async QC
	wv[][][0] = 1
	wv[][][1] = 5
	wv[][][2] = 6
	wv[][][3] = 0
End

static Function PS_AR6a_REENTRY([string str])
	variable sweepNo
	string stimset, expected, stimsetIndexEnd

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%leakCurPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%leakCur], NUMERIC_WAVE)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)

	Make/FREE/D accResistanceRef = {5e6, 5e6, 5e6}
	CHECK_EQUAL_WAVES(entries[%accResistance], accResistanceRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%accResistancePass], {1, 1, 1}, mode = WAVE_DATA)

	Make/FREE/D ssResistanceRef = {6e6, 6e6, 6e6}
	CHECK_EQUAL_WAVES(entries[%ssResistance], ssResistanceRef, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%resistanceRatio], {0.83, 0.83, 0.83}, mode = WAVE_DATA, tol = 1e-2)
	CHECK_EQUAL_WAVES(entries[%resistanceRatioPass], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%resultsSweep], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsPeakResistance], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsSSResistance], TEXT_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
	CheckTestPulseLikeEpochs(str)
End

static Function PS_AR7_IGNORE(string device)

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSShortThreshold", var=0.07)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineChunkLength", var=600)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxLeakCurrent", var=2)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessResistance", var=10)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessToSteadyStateResistanceRatio", var=90)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfTestpulses", var=3)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
static Function PS_AR7([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_AR7_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_ACC_RES_SMOKE)

	// DAQ is not started as PRE_SWEEP_CONFIG_EVENT fails due to non-matching BaselineChunkLength
	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)
	CHECK_EQUAL_VAR(AFH_GetlastSweepAcquired(str), NaN)
End

static Function PS_AR8_IGNORE(string device)

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSLongThreshold", var=0.5)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineRMSShortThreshold", var=0.07)

	// SamplingMultiplier uses default
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "SamplingFrequency", var=10)

	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "BaselineChunkLength", var=500)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxLeakCurrent", var=2)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessResistance", var=10)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "MaxAccessToSteadyStateResistanceRatio", var=90)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfFailedSweeps", var=3)
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextStimSetName", str="StimulusSetA_DA_0")
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NextIndexingEndStimSetName", str="StimulusSetB_DA_0")
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "NumberOfTestpulses", var=3)

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_QC_Stimsets_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
static Function PS_AR8([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=PS_AR8_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_ACC_RES_SMOKE)

	// all tests pass but sampling QC check fails
	wv[][][0] = 1
	wv[][][1] = 5
	wv[][][2] = 6
	wv[][][3] = 1
End

static Function PS_AR8_REENTRY([string str])
	variable sweepNo
	string stimset, expected, stimsetIndexEnd

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%leakCurPass], {1}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%leakCur], NUMERIC_WAVE)

	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%samplingPass], {0}, mode = WAVE_DATA)

	Make/FREE/D accResistanceRef = {5e6}
	CHECK_EQUAL_WAVES(entries[%accResistance], accResistanceRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%accResistancePass], {1}, mode = WAVE_DATA)

	Make/FREE/D ssResistanceRef = {6e6}
	CHECK_EQUAL_WAVES(entries[%ssResistance], ssResistanceRef, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%resistanceRatio], {0.83}, mode = WAVE_DATA, tol = 1e-2)
	CHECK_EQUAL_WAVES(entries[%resistanceRatioPass], {1}, mode = WAVE_DATA)

	CHECK_WAVE(entries[%resultsSweep], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsPeakResistance], TEXT_WAVE)
	CHECK_WAVE(entries[%resultsSSResistance], TEXT_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckBaselineChunks(str, {20, 520})
	CheckTestPulseLikeEpochs(str)
End
