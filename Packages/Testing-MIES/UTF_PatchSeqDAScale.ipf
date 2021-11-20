#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=PatchSeqTestDAScale

// This file also holds the test for the baseline evaluation for all PSQ analysis functions

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(s, stimset, device, [postInitializeFunc, preAcquireFunc])
	STRUCT DAQSettings& s
	string stimset
	string device
	FUNCREF CALLABLE_PROTO postInitializeFunc, preAcquireFunc

	Make/O/N=(0) root:overrideResults/Wave=overrideResults
	Note/K overrideResults

	if(!ParamIsDefault(postInitializeFunc))
		postInitializeFunc(device)
	endif
	string unlockedDevice = DAP_CreateDAEphysPanel()

	PGC_SetAndActivateControl(unlockedDevice, "popup_MoreSettings_Devices", str=device)
	PGC_SetAndActivateControl(unlockedDevice, "button_SettingsPlus_LockDevice")

	REQUIRE(WindowExists(device))

	PGC_SetAndActivateControl(device, "ADC", val=0)
	DoUpdate/W=$device

	WAVE ampMCC = GetAmplifierMultiClamps()
	WAVE ampTel = GetAmplifierTelegraphServers()

	REQUIRE_EQUAL_VAR(DimSize(ampMCC, ROWS), 2)
	REQUIRE_EQUAL_VAR(DimSize(ampTel, ROWS), 2)

	PGC_SetAndActivateControl(device, "Popup_Settings_HEADSTAGE", val = 0)
	PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")

	PGC_SetAndActivateControl(device, "Popup_Settings_HEADSTAGE", val = 1)
	PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")

	PGC_SetAndActivateControl(device, "Popup_Settings_HEADSTAGE", val = PSQ_TEST_HEADSTAGE)
	PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", val = 1)

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, PSQ_TEST_HEADSTAGE), val=1)
	DoUpdate/W=$device

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = 25)

	PGC_SetAndActivateControl(device, "Popup_Settings_VC_DA", str = "0")
	PGC_SetAndActivateControl(device, "Popup_Settings_IC_DA", str = "0")
	PGC_SetAndActivateControl(device, "Popup_Settings_VC_AD", str = "1")
	PGC_SetAndActivateControl(device, "Popup_Settings_IC_AD", str = "1")

	PGC_SetAndActivateControl(device, "button_Hardware_AutoGainAndUnit")

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = 70)
	PGC_SetAndActivateControl(device, GetPanelControl(PSQ_TEST_HEADSTAGE, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)

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

	PGC_SetAndActivateControl(device, "DataAcquireButton")
	DB_OpenDatabrowser()
End

Function/WAVE GetLBNEntries_IGNORE(device, sweepNo, name, [chunk])
	string device
	variable sweepNo, chunk
	string name

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues = GetLBTextualValues(device)

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
		case PSQ_FMT_LBN_DA_fI_SLOPE_REACHED:
		case PSQ_FMT_LBN_CHUNK_PASS:
		case PSQ_FMT_LBN_SAMPLING_PASS:
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
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
			break
		case PSQ_FMT_LBN_RMS_SHORT_THRESHOLD:
		case PSQ_FMT_LBN_RMS_LONG_THRESHOLD:
			WAVE/Z values = GetLastSettingSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
			if(!WaveExists(values))
				return $""
			endif

			Make/D/N=1/FREE val = {values[PSQ_TEST_HEADSTAGE]}

			return val
			break
		case "Delta I":
		case "Delta V":
		case "ResistanceFromFit":
		case "ResistanceFromFit_Err":
			return GetLastSettingEachSCI(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + name, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
			break
		default:
			FAIL()
	endswitch
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE)
	// all tests fail
	wv = 0
End

Function PS_DS_Sub1_REENTRY([str])
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

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

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

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_WAVE(pulseDuration, NULL_WAVE)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, "Delta I")
	CHECK_WAVE(deltaI, NULL_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, "Delta V")
	CHECK_WAVE(deltaV, NULL_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit")
	CHECK_WAVE(resistance, NULL_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit_Err")
	CHECK_WAVE(resistanceErr, NULL_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[PSQ_TEST_HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = -30

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScaleSub(str, PSQ_TEST_HEADSTAGE), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520})
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub2([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE)
	// only pre pulse chunk pass, others fail
	wv[]    = 0
	wv[0][] = 1
End

Function PS_DS_Sub2_REENTRY([str])
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

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

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

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_WAVE(pulseDuration, NULL_WAVE)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[PSQ_TEST_HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = -30

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScaleSub(str, PSQ_TEST_HEADSTAGE), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520, 2520, 3020, 3020, 3520})
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub3([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// first post pulse chunk pass
	wv[]      = 0
	wv[0,1][] = 1
End

Function PS_DS_Sub3_REENTRY([str])
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

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

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
	CHECK_EQUAL_WAVES(baselineChunkPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineRMSShortPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSShortPassed, NUMERIC_WAVE)

	WAVE/Z baselineRMSLongPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = 1)
	CHECK_WAVE(baselineRMSLongPassed, NUMERIC_WAVE)

	WAVE/Z baselineTargetVPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV_PASS, chunk = 1)
	CHECK_WAVE(baselineTargetVPassed, NUMERIC_WAVE)

	WAVE/Z targetV = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_TARGETV, chunk = 1)
	CHECK_WAVE(targetV, NUMERIC_WAVE)

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

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_WAVE(pulseDuration, NULL_WAVE)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, "Delta I")
	CHECK_WAVE(deltaI, NUMERIC_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, "Delta V")
	CHECK_WAVE(deltaV, NUMERIC_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit")
	CHECK_WAVE(resistance, NUMERIC_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit_Err")
	CHECK_WAVE(resistanceErr, NUMERIC_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[PSQ_TEST_HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -50, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScaleSub(str, PSQ_TEST_HEADSTAGE), 4)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub4([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// last post pulse chunk pass
	wv[] = 0
	wv[0][] = 1
	wv[DimSize(wv, ROWS) - 1][] = 1
End

Function PS_DS_Sub4_REENTRY([str])
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

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

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

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_WAVE(pulseDuration, NULL_WAVE)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, "Delta I")
	CHECK_WAVE(deltaI, NUMERIC_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, "Delta V")
	CHECK_WAVE(deltaV, NUMERIC_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit")
	CHECK_WAVE(resistance, NUMERIC_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit_Err")
	CHECK_WAVE(resistanceErr, NUMERIC_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[PSQ_TEST_HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -50, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScaleSub(str, PSQ_TEST_HEADSTAGE), 4)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520, 2520, 3020, 3020, 3520})
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub5([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk fails
	// all post pulse chunk pass
	wv[]    = 1
	wv[0][] = 0
End

Function PS_DS_Sub5_REENTRY([str])
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

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

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

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_WAVE(pulseDuration, NULL_WAVE)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, "Delta I")
	CHECK_WAVE(deltaI, NULL_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, "Delta V")
	CHECK_WAVE(deltaV, NULL_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit")
	CHECK_WAVE(resistance, NULL_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit_Err")
	CHECK_WAVE(resistanceErr, NULL_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[PSQ_TEST_HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = -30

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScaleSub(str, PSQ_TEST_HEADSTAGE), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520})
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub6([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv[]    = 0
	wv[0][] = 1
	wv[2][] = 1
End

Function PS_DS_Sub6_REENTRY([str])
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

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

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

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_WAVE(pulseDuration, NULL_WAVE)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, "Delta I")
	CHECK_WAVE(deltaI, NUMERIC_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, "Delta V")
	CHECK_WAVE(deltaV, NUMERIC_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit")
	CHECK_WAVE(resistance, NUMERIC_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit_Err")
	CHECK_WAVE(resistanceErr, NUMERIC_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[PSQ_TEST_HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -50, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScaleSub(str, PSQ_TEST_HEADSTAGE), 4)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520, 2520, 3020})
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub7([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// first post pulse chunk pass
	// of sweeps 2-6
	wv[]          = 0
	wv[0, 1][2,6] = 1
End

Function PS_DS_Sub7_REENTRY([str])
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

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

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

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_WAVE(pulseDuration, NULL_WAVE)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, "Delta I")
	CHECK_WAVE(deltaI, NUMERIC_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, "Delta V")
	CHECK_WAVE(deltaV, NUMERIC_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit")
	CHECK_WAVE(resistance, NUMERIC_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit_Err")
	CHECK_WAVE(resistanceErr, NUMERIC_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 7)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[PSQ_TEST_HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -30, -30, -50, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScaleSub(str, PSQ_TEST_HEADSTAGE), 6)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 0)
	CheckPSQChunkTimes(str, {20, 520}, sweep = 1)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 2)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 3)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 4)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 5)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520}, sweep = 6)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub8([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// first post pulse chunk pass
	// of sweep 0, 3, 6, 7 , 8
	wv[]        = 0
	wv[0, 1][0] = 1
	wv[0, 1][3] = 1
	wv[0, 1][6] = 1
	wv[0, 1][7] = 1
	wv[0, 1][8] = 1
End

Function PS_DS_Sub8_REENTRY([str])
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

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

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

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_WAVE(pulseDuration, NULL_WAVE)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, "Delta I")
	CHECK_WAVE(deltaI, NUMERIC_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, "Delta V")
	CHECK_WAVE(deltaV, NUMERIC_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit")
	CHECK_WAVE(resistance, NUMERIC_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit_Err")
	CHECK_WAVE(resistanceErr, NUMERIC_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 9)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[PSQ_TEST_HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30, -50, -50, -50, -70, -70, -70, -110, -130}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScaleSub(str, PSQ_TEST_HEADSTAGE), 8)

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

Function PS_DS_Sub9_Ignore(device)
	string device

	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "BaselineRMSShortThreshold", var = 0.150)
	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "BaselineRMSLongThreshold", var = 0.250)
End

// Same as PS_DS_Sub1 but with custom RMS short/long thresholds
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub9([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str, preAcquireFunc = PS_DS_Sub9_Ignore)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE)
	// all tests fail
	wv = 0
End

Function PS_DS_Sub9_REENTRY([str])
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

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, baselineQCPassed)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {0.150 * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {0.250 * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

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

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_WAVE(pulseDuration, NULL_WAVE)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB, PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, "Delta I")
	CHECK_WAVE(deltaI, NULL_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, "Delta V")
	CHECK_WAVE(deltaV, NULL_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit")
	CHECK_WAVE(resistance, NULL_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit_Err")
	CHECK_WAVE(resistanceErr, NULL_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[PSQ_TEST_HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = -30

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScaleSub(str, PSQ_TEST_HEADSTAGE), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
End

Function PS_DS_Sub10_Ignore(device)
	string device

	AFH_AddAnalysisParameter("PSQ_DaScale_Sub_DA_0", "SamplingFrequency", var = 10)
End

// Same as PS_DS_Sub3, but with non-matching sampling interval
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Sub10([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Sub_DA_0", str, preAcquireFunc = PS_DS_Sub10_Ignore)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// first post pulse chunk pass
	wv[]      = 0
	wv[0,1][] = 1
End

Function PS_DS_Sub10_REENTRY([str])
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

	// BEGIN baseline QC

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {1}, mode = WAVE_DATA)

	WAVE/Z baselineShortThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineShortThreshold, {PSQ_RMS_SHORT_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

	WAVE/Z baselineLongThreshold = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	CHECK_EQUAL_WAVES(baselineLongThreshold, {PSQ_RMS_LONG_THRESHOLD * 1e-3}, mode = WAVE_DATA, tol = 1e-6)

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

	// END baseline QC

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_WAVE(spikeDetection, NULL_WAVE)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_WAVE(spikeCount, NULL_WAVE)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_WAVE(pulseDuration, NULL_WAVE)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_WAVE(fISlope, NULL_WAVE)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED)
	CHECK_EQUAL_WAVES(fISlopeReached, {0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUB}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, "Delta I")
	CHECK_WAVE(deltaI, NULL_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, "Delta V")
	CHECK_WAVE(deltaV, NULL_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit")
	CHECK_WAVE(resistance, NULL_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit_Err")
	CHECK_WAVE(resistanceErr, NULL_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 1)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[PSQ_TEST_HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {-30}

	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScaleSub(str, PSQ_TEST_HEADSTAGE), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End

// no baseline checks for supra

// The decision logic *without* FinalSlopePercent is the same as for Sub, only the plotting is different
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Supra1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Supr_DA_0", str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv = 0
	wv[0][][0] = 1
	wv[1][][0] = 1
	// all sweeps spike
	wv[0][][1] = 1
	// increasing number of spikes
	wv[0][][2] = 1 + q
End

Function PS_DS_Supra1_REENTRY([str])
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

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUPRA, PSQ_DS_SUPRA}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, "Delta I")
	CHECK_WAVE(deltaI, NULL_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, "Delta V")
	CHECK_WAVE(deltaV, NULL_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit")
	CHECK_WAVE(resistance, NULL_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit_Err")
	CHECK_WAVE(resistanceErr, NULL_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 2)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[PSQ_TEST_HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {PSQ_DS_OFFSETSCALE_FAKE + 20, PSQ_DS_OFFSETSCALE_FAKE + 40}
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScaleSub(str, PSQ_TEST_HEADSTAGE), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End

Function PS_SetOffsetOp_IGNORE(device)
	string device

	AFH_AddAnalysisParameter("PSQ_DaScale_Supr_DA_0", "OffsetOperator", str="*")
End

// Different to PS_DS_Supra1 is that the second does not spike and a different offset operator
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Supra2([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DaScale_Supr_DA_0", str, postInitializeFunc = PS_SetOffsetOp_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv = 0
	wv[0][][0] = 1
	wv[1][][0] = 1
	// Spike and non-spiking
	wv[0][][1] = mod(q, 2) == 0
	// increasing number of spikes
	wv[0][][2] = q + 1
End

Function PS_DS_Supra2_REENTRY([str])
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

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUPRA, PSQ_DS_SUPRA}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, "Delta I")
	CHECK_WAVE(deltaI, NULL_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, "Delta V")
	CHECK_WAVE(deltaV, NULL_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit")
	CHECK_WAVE(resistance, NULL_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit_Err")
	CHECK_WAVE(resistanceErr, NULL_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 2)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[PSQ_TEST_HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {PSQ_DS_OFFSETSCALE_FAKE * 20, PSQ_DS_OFFSETSCALE_FAKE * 40}
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScaleSub(str, PSQ_TEST_HEADSTAGE), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End

// FinalSlopePercent present but not reached
static Function PS_DS_Supra3_IGNORE(device)
	string device

	string stimSet = "PSQ_DS_SupraLong_DA_0"
	AFH_AddAnalysisParameter(stimSet, "FinalSlopePercent", var = 100)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Supra3([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DS_SupraLong_DA_0", str, preAcquireFunc = PS_DS_Supra3_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv = 0
	wv[0][][0] = 1
	wv[1][][0] = 1
	// Spike and non-spiking
	wv[0][][1] = mod(q, 2) == 0
	// increasing number of spikes
	wv[0][][2] = q + 1
End

Function PS_DS_Supra3_REENTRY([str])
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

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, "Delta I")
	CHECK_WAVE(deltaI, NULL_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, "Delta V")
	CHECK_WAVE(deltaV, NULL_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit")
	CHECK_WAVE(resistance, NULL_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit_Err")
	CHECK_WAVE(resistanceErr, NULL_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[PSQ_TEST_HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {PSQ_DS_OFFSETSCALE_FAKE + 20, PSQ_DS_OFFSETSCALE_FAKE + 40, PSQ_DS_OFFSETSCALE_FAKE + 60, PSQ_DS_OFFSETSCALE_FAKE + 80, PSQ_DS_OFFSETSCALE_FAKE + 100}
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScaleSub(str, PSQ_TEST_HEADSTAGE), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End

// FinalSlopePercent present and reached
static Function PS_DS_Supra4_IGNORE(device)
	string device

	string stimSet = "PSQ_DS_SupraLong_DA_0"
	AFH_AddAnalysisParameter(stimSet, "FinalSlopePercent", var = 60)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Supra4([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DS_SupraLong_DA_0", str, preAcquireFunc = PS_DS_Supra4_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv = 0
	wv[0][][0] = 1
	wv[1][][0] = 1
	// Spike and non-spiking
	wv[0][][1] = mod(q, 2) == 0
	// increasing number of spikes
	wv[0][][2] = q^3 + 1
End

Function PS_DS_Supra4_REENTRY([str])
	string str

	variable sweepNo,  numEntries

	sweepNo = 4

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SET_PASS)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z samplingPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	CHECK_EQUAL_WAVES(samplingPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

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

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, "Delta I")
	CHECK_WAVE(deltaI, NULL_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, "Delta V")
	CHECK_WAVE(deltaV, NULL_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit")
	CHECK_WAVE(resistance, NULL_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit_Err")
	CHECK_WAVE(resistanceErr, NULL_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[PSQ_TEST_HEADSTAGE]
	Make/FREE/D/N=(numEntries) stimScaleRef = {PSQ_DS_OFFSETSCALE_FAKE + 20, PSQ_DS_OFFSETSCALE_FAKE + 40, PSQ_DS_OFFSETSCALE_FAKE + 60, PSQ_DS_OFFSETSCALE_FAKE + 80, PSQ_DS_OFFSETSCALE_FAKE + 100}
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScaleSub(str, PSQ_TEST_HEADSTAGE), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End

static Constant DAScaleModifierPerc = 25

// MinimumSpikeCount, MaximumSpikeCount, DAScaleModifier present
static Function PS_DS_Supra5_IGNORE(device)
	string device

	string stimSet = "PSQ_DS_SupraLong_DA_0"
	AFH_AddAnalysisParameter(stimSet, "MinimumSpikeCount", var = 3)
	AFH_AddAnalysisParameter(stimSet, "MaximumSpikeCount", var = 6)
	AFH_AddAnalysisParameter(stimSet, "DAScaleModifier", var = DAScaleModifierPerc)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function PS_DS_Supra5([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, "PSQ_DS_SupraLong_DA_0", str, preAcquireFunc = PS_DS_Supra5_IGNORE)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv = 0
	wv[0][][0] = 1
	wv[1][][0] = 1
	// Spiking
	wv[0][][1] = 1
	// increasing number of spikes
	wv[0][][2] = q^2 + 1
End

Function PS_DS_Supra5_REENTRY([str])
	string str

	variable sweepNo,  numEntries

	sweepNo = 4

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z setPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SET_PASS)
	CHECK_EQUAL_WAVES(setPassed, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z samplingPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	CHECK_EQUAL_WAVES(samplingPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z baselineQCPassed = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)
	CHECK_EQUAL_WAVES(baselineQCPassed, {1, 1, 1, 1, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetection = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_DETECT)
	CHECK_EQUAL_WAVES(spikeDetection, {1, 1, 1, 1, 1}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z spikeCount = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_SPIKE_COUNT)
	CHECK_EQUAL_WAVES(spikeCount, {1 ,2, 5, 10, 17}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z pulseDuration = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_PULSE_DUR)
	CHECK_EQUAL_WAVES(pulseDuration, {1000, 1000, 1000, 1000, 1000}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z spikeFreq = GetAnalysisFuncDAScaleSpikeFreq(str, PSQ_TEST_HEADSTAGE)
	CHECK_EQUAL_WAVES(spikeFreq, {1 ,2, 5, 10, 17}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlope = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE)
	CHECK_EQUAL_WAVES(fISlope, {0,3.33333333333334,7.14285714285714,12.4517906336088,18.4313725490196}, mode = WAVE_DATA, tol = 1e-3)

	WAVE/Z fISlopeReached = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED)
	CHECK_EQUAL_WAVES(fISlopeReached, {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/T/Z opMode = GetLBNEntries_IGNORE(str, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	CHECK_EQUAL_TEXTWAVES(opMode, {PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA, PSQ_DS_SUPRA}, mode = WAVE_DATA)

	WAVE/Z deltaI = GetLBNEntries_IGNORE(str, sweepNo, "Delta I")
	CHECK_WAVE(deltaI, NULL_WAVE)

	WAVE/Z deltaV = GetLBNEntries_IGNORE(str, sweepNo, "Delta V")
	CHECK_WAVE(deltaV, NULL_WAVE)

	WAVE/Z resistance = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit")
	CHECK_WAVE(resistance, NULL_WAVE)

	WAVE/Z resistanceErr = GetLBNEntries_IGNORE(str, sweepNo, "ResistanceFromFit_Err")
	CHECK_WAVE(resistanceErr, NULL_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	numEntries = DimSize(sweeps, ROWS)
	CHECK_EQUAL_VAR(numEntries, 5)

	numEntries = DimSize(sweepPassed, ROWS)
	Make/FREE/D/N=(numEntries) stimScale = GetLastSetting(numericalValues, sweeps[p], STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)[PSQ_TEST_HEADSTAGE]


	Make/FREE/D/N=(numEntries) stimScaleRef = {20 + PSQ_DS_OFFSETSCALE_FAKE,                                 \
														 40 * (1 + DAScaleModifierPerc/100) + PSQ_DS_OFFSETSCALE_FAKE, \
														 60 * (1 + DAScaleModifierPerc/100) + PSQ_DS_OFFSETSCALE_FAKE, \
														 80 + PSQ_DS_OFFSETSCALE_FAKE,                                 \
														 100 * (1 - DAScaleModifierPerc/100) + PSQ_DS_OFFSETSCALE_FAKE}

	// Explanations for the stimscale:
	// 1. initial
	// 2. last below min
	// 3. last below min again
	// 4. last inside
	// 5. last above
	CHECK_EQUAL_WAVES(stimScale, stimScaleRef, mode = WAVE_DATA, tol = 1e-14)

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_GetLastPassingDAScaleSub(str, PSQ_TEST_HEADSTAGE), -1)

	CommonAnalysisFunctionChecks(str, sweepNo, setPassed)
	CheckPSQChunkTimes(str, {20, 520, 2020, 2520})
End
