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

static Function SetAnalysisFunctions_IGNORE()

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetA_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "TrackSweepCount_V3"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetB_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "TrackSweepCount_V3"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetC_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "TrackSweepCount_V3"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetD_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "TrackSweepCount_V3"
End

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(s, devices, [postInitializeFunc, preAcquireFunc, setAnalysisFuncs, startTPInstead])
	STRUCT DAQSettings& s
	string devices
	FUNCREF CALLABLE_PROTO postInitializeFunc, preAcquireFunc
	variable setAnalysisFuncs, startTPInstead

	string unlockedPanelTitle, device
	variable i, numEntries

	KillOrMoveToTrash(wv = GetTrackSweepCounts())
	KillOrMoveToTrash(wv = GetTrackActiveSetCount())
	KillOrMoveToTrash(wv = TrackAnalysisFunctionCalls())

	if(!ParamIsDefault(postInitializeFunc))
		postInitializeFunc(devices)
	endif

	if(ParamIsDefault(startTPInstead))
		startTPInstead = 0
	else
		startTPInstead = !!startTPInstead
	endif

	if(ParamIsDefault(setAnalysisFuncs))
		setAnalysisFuncs = 0
	else
		setAnalysisFuncs = !!setAnalysisFuncs
	endif

	if(setAnalysisFuncs)
		SetAnalysisFunctions_IGNORE()
	endif

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = stringFromList(i, devices)

		unlockedPanelTitle = DAP_CreateDAEphysPanel()

		PGC_SetAndActivateControl(unlockedPanelTitle, "popup_MoreSettings_Devices", str=device)
		PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")

		REQUIRE(WindowExists(device))

		PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1, switchTab = 1)
		PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)

		PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetA_DA_0")
		PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), str = "StimulusSetB_DA_0")
		PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetC_DA_0")
		PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), str = "StimulusSetD_DA_0")

		WAVE ampMCC = GetAmplifierMultiClamps()
		WAVE ampTel = GetAmplifierTelegraphServers()

		REQUIRE_EQUAL_VAR(DimSize(ampMCC, ROWS), 2)
		REQUIRE_EQUAL_VAR(DimSize(ampTel, ROWS), 2)

		// HS 0 with Amp
		PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = 0)
		PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", val = 1)

		// HS 1 with Amp
		PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = 1)
		PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", val = 2)

		PGC_SetAndActivateControl(device, DAP_GetClampModeControl(V_CLAMP_MODE, 0), val=1)
		PGC_SetAndActivateControl(device, DAP_GetClampModeControl(V_CLAMP_MODE, 1), val=1)
		DoUpdate/W=$device

		PGC_SetAndActivateControl(device, "button_Hardware_AutoGainAndUnit")

		PGC_SetAndActivateControl(device, "check_Settings_MD", val = s.MD)
		PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = s.RA)
		PGC_SetAndActivateControl(device, "Check_DataAcq_Indexing", val = s.IDX)
		PGC_SetAndActivateControl(device, "Check_DataAcq1_IndexingLocked", val = s.LIDX)

		if(!s.MD)
			PGC_SetAndActivateControl(device, "Check_Settings_BackgrndDataAcq", val = s.BKG_DAQ)
		else
			CHECK_EQUAL_VAR(s.BKG_DAQ, 1)
		endif

		PGC_SetAndActivateControl(device, "SetVar_DataAcq_SetRepeats", val = s.RES)

		PASS()
	endfor

	device = devices

#ifdef TESTS_WITH_YOKING
	PGC_SetAndActivateControl(device, "button_Hardware_Lead1600")
	PGC_SetAndActivateControl(device, "popup_Hardware_AvailITC1600s", val=0)
	PGC_SetAndActivateControl(device, "button_Hardware_AddFollower")

	ARDLaunchSeqPanel()
	PGC_SetAndActivateControl("ArduinoSeq_Panel", "SendSequenceButton")
#endif

	if(!ParamIsDefault(preAcquireFunc))
		preAcquireFunc(device)
	endif

	if(startTPInstead)
		PGC_SetAndActivateControl(device, "StartTestPulseButton")
	else
		PGC_SetAndActivateControl(device, "DataAcquireButton")
	endif
End

static Structure TestSettings
	variable numSweeps
	variable sweepWaveType
	WAVE/T   acquiredStimSets_HS0, acquiredStimSets_HS1 // including repetitions
	WAVE sweepCount_HS0, sweepCount_HS1
	WAVE setCycleCount_HS0, setCycleCount_HS1
	WAVE stimsetCycleID_HS0, stimsetCycleID_HS1
	// store the sweep count where a event was fired
	WAVE events_HS0, events_HS1
	WAVE DAQChannelTypeAD, DAQChannelTypeDA
EndStructure

static Function InitTestStructure(t)
	STRUCT TestSettings &t

	REQUIRE(t.numSweeps > 0)
	Make/T/FREE/N=(t.numSweeps) t.acquiredStimSets_HS0, t.acquiredStimSets_HS1
	Make/FREE/N=(t.numSweeps) t.sweepCount_HS0, t.sweepCount_HS1
	Make/FREE/N=(t.numSweeps) t.setCycleCount_HS0, t.setCycleCount_HS1
	Make/FREE/N=(t.numSweeps) t.stimsetCycleID_HS0, t.stimsetCycleID_HS1
	Make/FREE/N=(t.numSweeps, TOTAL_NUM_EVENTS) t.events_HS0 = NaN, t.events_HS1 = NaN
	Make/FREE t.DAQChannelTypeAD = {DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_DAQ, NaN, NaN, NaN, NaN, NaN, NaN, NaN}
	Make/FREE t.DAQChannelTypeDA = {DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_DAQ, NaN, NaN, NaN, NaN, NaN, NaN, NaN}
End

static Function AllTests(t, devices)
	STRUCT TestSettings &t
	string devices

	string sweeps, configs, stimset, foundStimSet, device, unit
	variable i, j, sweepNo, numEntries

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = stringFromList(i, devices)

		CHECK_EQUAL_VAR(GetSetVariable(device, "SetVar_Sweep"), t.numSweeps)
		sweeps  = GetListOfObjects(GetDeviceDataPath(device), DATA_SWEEP_REGEXP, fullPath = 1)
		configs = GetListOfObjects(GetDeviceDataPath(device), DATA_CONFIG_REGEXP, fullPath = 1)

		CHECK_EQUAL_VAR(ItemsInList(sweeps), t.numSweeps)
		CHECK_EQUAL_VAR(ItemsInList(configs), t.numSweeps)

		WAVE/T textualValues   = GetLBTextualValues(device)
		WAVE   numericalValues = GetLBNumericalValues(device)
		WAVE anaFuncSweepTracker = GetTrackSweepCounts()

		for(j = 0; j < t.numSweeps; j += 1)
			WAVE/Z sweep  = $StringFromList(j, sweeps)
			CHECK_WAVE(sweep, NUMERIC_WAVE, minorType = t.sweepWaveType)

			WaveStats/M=1/Q sweep
			CHECK_EQUAL_VAR(V_numNaNs, 0)
			CHECK_EQUAL_VAR(V_numInfs, 0)

			WAVE/Z config = $StringFromList(j, configs)
			CHECK_WAVE(config, NUMERIC_WAVE)

			CHECK_EQUAL_VAR(DimSize(config, ROWS), DimSize(sweep, COLS))

			CHECK_EQUAL_VAR(DimSize(config, ROWS), 4)

			// check channel types
			CHECK_EQUAL_VAR(config[0][0], XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_VAR(config[1][0], XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_VAR(config[2][0], XOP_CHANNEL_TYPE_ADC)
			CHECK_EQUAL_VAR(config[3][0], XOP_CHANNEL_TYPE_ADC)

			// check channel numbers
			WAVE DACs = GetDACListFromConfig(config)
			CHECK_EQUAL_WAVES(DACs, {0, 1}, mode = WAVE_DATA)

			WAVE ADCs = GetADCListFromConfig(config)
			CHECK_EQUAL_WAVES(ADCs, {0, 1}, mode = WAVE_DATA)

			WAVE TTLs = GetTTLListFromConfig(config)
			CHECK_EQUAL_VAR(DimSize(TTLs, ROWS), 0)

			// check channel units
			unit = AFH_GetChannelUnit(config, 0, XOP_CHANNEL_TYPE_DAC)
			CHECK_PROPER_STR(unit)

			unit = AFH_GetChannelUnit(config, 1, XOP_CHANNEL_TYPE_DAC)
			CHECK_PROPER_STR(unit)

			unit = AFH_GetChannelUnit(config, 0, XOP_CHANNEL_TYPE_ADC)
			CHECK_PROPER_STR(unit)

			unit = AFH_GetChannelUnit(config, 1, XOP_CHANNEL_TYPE_ADC)
			CHECK_PROPER_STR(unit)

			sweepNo = ExtractSweepNumber(NameOfWave(sweep))
			CHECK(sweepNo >= 0)
			WAVE/T/Z foundStimSets = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
			REQUIRE_WAVE(foundStimSets, TEXT_WAVE)

			// HS 0
			foundStimSet = foundStimSets[0]
			stimSet      = t.acquiredStimSets_HS0[j]
			CHECK_EQUAL_STR(foundStimSet, stimSet)

			// HS 1
			foundStimSet = foundStimSets[1]
			stimSet      = t.acquiredStimSets_HS1[j]
			CHECK_EQUAL_STR(foundStimSet, stimSet)

			WAVE/Z sweepCounts = GetLastSetting(numericalValues, sweepNo, "Set Sweep Count", DATA_ACQUISITION_MODE)
			REQUIRE_WAVE(sweepCounts, NUMERIC_WAVE)
			CHECK_EQUAL_VAR(sweepCounts[0], t.sweepCount_HS0[j])
			CHECK_EQUAL_VAR(sweepCounts[1], t.sweepCount_HS1[j])

			WAVE/Z setCycleCounts = GetLastSetting(numericalValues, sweepNo, "Set Cycle Count", DATA_ACQUISITION_MODE)
			REQUIRE_WAVE(setCycleCounts, NUMERIC_WAVE)
			CHECK_EQUAL_VAR(setCycleCounts[0], t.setCycleCount_HS0[j])
			CHECK_EQUAL_VAR(setCycleCounts[1], t.setCycleCount_HS1[j])

			WAVE/Z sciSweeps = AFH_GetSweepsFromSameSCI(numericalValues, j, 0)
			if(WaveExists(sciSweeps))
				Extract/FREE/INDX t.stimsetCycleID_HS0, indizes, t.stimsetCycleID_HS0 == t.stimsetCycleID_HS0[j]
				CHECK_EQUAL_WAVES(sciSweeps, indizes, mode = WAVE_DATA)
			else
				CHECK_WAVE(t.stimsetCycleID_HS0, NULL_WAVE)
			endif

			WAVE/Z sciSweeps = AFH_GetSweepsFromSameSCI(numericalValues, j, 1)
			if(WaveExists(sciSweeps))
				Extract/FREE/INDX t.stimsetCycleID_HS1, indizes, t.stimsetCycleID_HS1 == t.stimsetCycleID_HS1[j]
				CHECK_EQUAL_WAVES(sciSweeps, indizes, mode = WAVE_DATA)
			else
				CHECK_WAVE(t.stimsetCycleID_HS1, NULL_WAVE)
			endif

			Duplicate/FREE/RMD=[j][][0] anaFuncSweepTracker, actualEvents_HS0
			Duplicate/FREE/RMD=[j][] t.events_HS0, refEvents_HS0
			Redimension/E=1/N=(TOTAL_NUM_EVENTS) refEvents_HS0, actualEvents_HS0

			CHECK_EQUAL_WAVES(refEvents_HS0, actualEvents_HS0, mode = WAVE_DATA)

			Duplicate/FREE/RMD=[j][][1] anaFuncSweepTracker, actualEvents_HS1
			Duplicate/FREE/RMD=[j][] t.events_HS1, refEvents_HS1
			Redimension/E=1/N=(TOTAL_NUM_EVENTS) refEvents_HS1, actualEvents_HS1

			CHECK_EQUAL_WAVES(refEvents_HS1, actualEvents_HS1, mode = WAVE_DATA)

			WAVE DAChannelTypes = GetLastSetting(numericalValues, sweepNo, "DA ChannelType", DATA_ACQUISITION_MODE)
			CHECK_EQUAL_WAVES(DAChannelTypes, t.DAQChannelTypeDA, mode = WAVE_DATA)

			WAVE ADChannelTypes = GetLastSetting(numericalValues, sweepNo, "AD ChannelType", DATA_ACQUISITION_MODE)
			CHECK_EQUAL_WAVES(ADChannelTypes, t.DAQChannelTypeAD, mode = WAVE_DATA)

			WAVE/T indexEndStimsetsGUI = DAG_GetChannelTextual(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
			Redimension/N=(2) indexEndStimsetsGUI

			WAVE/T indexEndStimsetsLBN = GetLastSetting(textualValues, sweepNo, "Indexing End Stimset", DATA_ACQUISITION_MODE)
			Redimension/N=(2) indexEndStimsetsLBN
			CHECK_EQUAL_TEXTWAVES(indexEndStimsetsGUI, indexEndStimsetsLBN)
		endfor
	endfor

	CheckDAQStopReason(device, DQ_STOP_REASON_FINISHED)

	TestNwbExportV1()
	TestNwbExportV2()
End

Function/WAVE GetTrackActiveSetCount()

	DFREF dfr = root:
	WAVE/Z/SDFR=dfr wv = anaFuncActiveSetCount

	if(WaveExists(wv))
		return wv
	else
		Make/N=(100) dfr:anaFuncActiveSetCount/WAVE=wv
	endif

	wv = NaN

	return wv
End

/// @brief Track at which sweep count an analysis function was called.
Function/WAVE GetTrackSweepCounts()

	variable i

	DFREF dfr = root:
	WAVE/Z/SDFR=dfr wv = anaFuncSweepTracker

	if(WaveExists(wv))
		return wv
	else
		Make/N=(100, TOTAL_NUM_EVENTS, 2) dfr:anaFuncSweepTracker/WAVE=wv
	endif

	for(i = 0; i < TOTAL_NUM_EVENTS; i += 1)
		SetDimLabel COLS, i, $StringFromList(i, EVENT_NAME_LIST), wv
	endfor

	wv = NaN

	return wv
End

Function Events_Common(t)
	STRUCT TestSettings &t

	// pre DAQ at sweep 0
	t.events_HS0[0][PRE_DAQ_EVENT] = 0
	t.events_HS1[0][PRE_DAQ_EVENT] = 0

	// post DAQ at the last sweep
	t.events_HS0[t.numSweeps - 1][POST_DAQ_EVENT] = t.numSweeps - 1
	t.events_HS1[t.numSweeps - 1][POST_DAQ_EVENT] = t.numSweeps - 1

	// pre/post sweep always
	t.events_HS0[][PRE_SWEEP_CONFIG_EVENT] = p
	t.events_HS1[][PRE_SWEEP_CONFIG_EVENT] = p

	t.events_HS0[][POST_SWEEP_EVENT] = p
	t.events_HS1[][POST_SWEEP_EVENT] = p
End

Function Events_MD0_RA0_I0_L0_BKG_0(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]    = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT]   = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]    = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT]   = NaN
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD0
Function MD0_RA0_I0_L0_BKG_0([str])
	string str

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s, str, setAnalysisFuncs = 1)
End

Function MD0_RA0_I0_L0_BKG_0_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps        = 1
	t.sweepWaveType    = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD0_RA0_I0_L0_BKG_0(t)

	t.acquiredStimSets_HS0[] = "StimulusSetA_DA_0"
	t.sweepCount_HS0[]       = 0
	t.setCycleCount_HS0[]    = 0
	t.stimsetCycleID_HS0[]   = 0

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1[]       = 0
	t.setCycleCount_HS1[]    = 0
	t.stimsetCycleID_HS1[]   = 0

	AllTests(t, str)
End

Function Events_MD1_RA0_I0_L0_BKG_1(t)
	STRUCT TestSettings &t

	Events_MD0_RA0_I0_L0_BKG_0(t)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function MD1_RA0_I0_L0_BKG_1([str])
	string str

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s, str, setAnalysisFuncs = 1)
End

Function MD1_RA0_I0_L0_BKG_1_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps = 1
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD1_RA0_I0_L0_BKG_1(t)

	t.acquiredStimSets_HS0[] = "StimulusSetA_DA_0"
	t.sweepCount_HS0[]       = 0
	t.setCycleCount_HS0[]    = 0
	t.stimsetCycleID_HS0[]   = 0

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1[]       = 0
	t.setCycleCount_HS1[]    = 0
	t.stimsetCycleID_HS1[]   = 0

	AllTests(t, str)
End

Function Events_MD0_RA1_I0_L0_BKG_1(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD0
Function MD0_RA1_I0_L0_BKG_0([str])
	string str

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s, str, setAnalysisFuncs = 1)
End

Function MD0_RA1_I0_L0_BKG_0_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps              = 3
	t.sweepWaveType          = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD0_RA1_I0_L0_BKG_1(t)

	t.acquiredStimSets_HS0[] = "StimulusSetA_DA_0"
	t.sweepCount_HS0         = {0, 1, 2}
	t.setCycleCount_HS0[]    = 0
	t.stimsetCycleID_HS0[]   = 0

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1[]       = {0, 1, 0}
	t.setCycleCount_HS1[]    = {0, 0, 1}
	t.stimsetCycleID_HS1[]   = {0, 0, 1}

	AllTests(t, str)
End

Function Events_MD1_RA1_I0_L0_BKG_1(t)
	STRUCT TestSettings &t

	Events_MD0_RA1_I0_L0_BKG_1(t)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function MD1_RA1_I0_L0_BKG_1([str])
	string str

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s, str, setAnalysisFuncs = 1)
End

Function MD1_RA1_I0_L0_BKG_1_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps              = 3
	t.sweepWaveType          = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD1_RA1_I0_L0_BKG_1(t)

	t.acquiredStimSets_HS0[] = "StimulusSetA_DA_0"
	t.sweepCount_HS0         = {0, 1, 2}
	t.setCycleCount_HS0[]    = 0
	t.stimsetCycleID_HS0[]   = 0

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1[]       = {0, 1, 0}
	t.setCycleCount_HS1[]    = {0, 0, 1}
	t.stimsetCycleID_HS1[]   = {0, 0, 1}

	AllTests(t, str)
End

Function Events_MD1_RA1_I1_L0_BKG_1(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 3
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 4
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function MD1_RA1_I1_L0_BKG_1([str])
	string str

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s, str, setAnalysisFuncs = 1)
End

Function MD1_RA1_I1_L0_BKG_1_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 5
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD1_RA1_I1_L0_BKG_1(t)

	t.acquiredStimSets_HS0[0,2] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[3]   = "StimulusSetB_DA_0"
	t.acquiredStimSets_HS0[4]   = "StimulusSetA_DA_0"
	t.sweepCount_HS0            = {0, 1, 2, 0, 0}
	t.setCycleCount_HS0         = 0
	t.stimsetCycleID_HS0[]      = {0, 0, 0, 1, 2}

	t.acquiredStimSets_HS1[0,1] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[2,4] = "StimulusSetD_DA_0"
	t.sweepCount_HS1            = {0, 1, 0, 1, 2}
	t.setCycleCount_HS1         = 0
	t.stimsetCycleID_HS1[]      = {0, 0, 1, 1, 1}

	AllTests(t, str)
End

Function Events_MD0_RA1_I1_L0_BKG_0(t)
	STRUCT TestSettings &t

	Events_MD1_RA1_I1_L0_BKG_1(t)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD0
Function MD0_RA1_I1_L0_BKG_0([str])
	string str

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s, str, setAnalysisFuncs = 1)
End

Function MD0_RA1_I1_L0_BKG_0_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 5
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD0_RA1_I1_L0_BKG_0(t)

	t.acquiredStimSets_HS0[0,2] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[3]   = "StimulusSetB_DA_0"
	t.acquiredStimSets_HS0[4]   = "StimulusSetA_DA_0"
	t.sweepCount_HS0            = {0, 1, 2, 0, 0}
	t.setCycleCount_HS0         = 0
	t.stimsetCycleID_HS0[]      = {0, 0, 0, 1, 2}

	t.acquiredStimSets_HS1[0,1] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[2,4] = "StimulusSetD_DA_0"
	t.sweepCount_HS1            = {0, 1, 0, 1, 2}
	t.setCycleCount_HS1         = 0
	t.stimsetCycleID_HS1[]      = {0, 0, 1, 1, 1}

	AllTests(t, str)
End

Function Events_MD1_RA1_I1_L1_BKG_1(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 3
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 4
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 5
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function MD1_RA1_I1_L1_BKG_1([str])
	string str

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s, str, setAnalysisFuncs = 1)
End

Function MD1_RA1_I1_L1_BKG_1_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 6
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD1_RA1_I1_L1_BKG_1(t)

	t.acquiredStimSets_HS0[0,2] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[3,5] = "StimulusSetB_DA_0"
	t.sweepCount_HS0            = {0, 1, 2, 0, 0, 0}
	t.setCycleCount_HS0         = {0, 0, 0, 0, 1, 2}
	t.stimsetCycleID_HS0[]      = {0, 0, 0, 1, 2, 3}

	t.acquiredStimSets_HS1[0,2] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[3,5] = "StimulusSetD_DA_0"
	t.sweepCount_HS1            = {0, 1, 0, 0, 1, 2}
	t.setCycleCount_HS1         = {0, 0, 1, 0, 0, 0}
	t.stimsetCycleID_HS1[]      = {0, 0, 1, 2, 2, 2}

	AllTests(t, str)
End

Function Events_MD0_RA1_I1_L1_BKG_0(t)
	STRUCT TestSettings &t

	Events_MD1_RA1_I1_L1_BKG_1(t)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD0
Function MD0_RA1_I1_L1_BKG_0([str])
	string str

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s, str, setAnalysisFuncs = 1)
End

Function MD0_RA1_I1_L1_BKG_0_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 6
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD0_RA1_I1_L1_BKG_0(t)

	t.acquiredStimSets_HS0[0,2] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[3,5] = "StimulusSetB_DA_0"
	t.sweepCount_HS0            = {0, 1, 2, 0, 0, 0}
	t.setCycleCount_HS0         = {0, 0, 0, 0, 1, 2}
	t.stimsetCycleID_HS0[]      = {0, 0, 0, 1, 2, 3}

	t.acquiredStimSets_HS1[0,2] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[3,5] = "StimulusSetD_DA_0"
	t.sweepCount_HS1            = {0, 1, 0, 0, 1, 2}
	t.setCycleCount_HS1         = {0, 0, 1, 0, 0, 0}
	t.stimsetCycleID_HS1[]      = {0, 0, 1, 2, 2, 2}

	AllTests(t, str)
End

Function Events_RepeatSets_1(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 3
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 4
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 5
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function RepeatSets_1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_2")
	AcquireData(s, str, setAnalysisFuncs = 1)
End

Function RepeatSets_1_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 6
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_RepeatSets_1(t)

	t.acquiredStimSets_HS0[] = "StimulusSetA_DA_0"
	t.sweepCount_HS0         = {0, 1, 2, 0, 1, 2}
	t.setCycleCount_HS0      = {0, 0, 0, 1, 1, 1}
	t.stimsetCycleID_HS0[]   = {0, 0, 0, 1, 1, 1}

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1         = {0, 1, 0, 1, 0, 1}
	t.setCycleCount_HS1      = {0, 0, 1, 1, 2, 2}
	t.stimsetCycleID_HS1[]   = {0, 0, 1, 1, 2, 2}

	AllTests(t, str)
End

Function Events_RepeatSets_2(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 3
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 4
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 5
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 6
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 7
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 8
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 9
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function RepeatSets_2([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L0_BKG_1_RES_2")
	AcquireData(s, str, setAnalysisFuncs = 1)
End

Function RepeatSets_2_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 10
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_RepeatSets_2(t)

	t.acquiredStimSets_HS0[0,2] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[3]   = "StimulusSetB_DA_0"
	t.acquiredStimSets_HS0[4,6] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[7]   = "StimulusSetB_DA_0"
	t.acquiredStimSets_HS0[8,9] = "StimulusSetA_DA_0"
	t.sweepCount_HS0            = {0, 1, 2, 0, 0, 1, 2, 0, 0, 1}
	t.setCycleCount_HS0         = 0
	t.stimsetCycleID_HS0[]      = {0, 0, 0, 1, 2, 2, 2, 3, 4, 4}

	t.acquiredStimSets_HS1[0,1] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[2,4] = "StimulusSetD_DA_0"
	t.acquiredStimSets_HS1[5,6] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[7,9] = "StimulusSetD_DA_0"
	t.sweepCount_HS1            = {0, 1, 0, 1, 2, 0, 1, 0, 1, 2}
	t.setCycleCount_HS1         = 0
	t.stimsetCycleID_HS1[]      = {0, 0, 1, 1, 1, 2, 2, 3, 3, 3}

	AllTests(t, str)
End

Function Events_RepeatSets_3(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 3
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 4
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 5
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 6
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 7
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 8
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 9
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 10
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 11
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function RepeatSets_3([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L1_BKG_1_RES_2")
	AcquireData(s, str, setAnalysisFuncs = 1)
End

Function RepeatSets_3_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 12
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_RepeatSets_3(t)

	t.acquiredStimSets_HS0[0,5]  = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[6,11] = "StimulusSetB_DA_0"
	t.sweepCount_HS0             = {0, 1, 2, 0, 1, 2, 0, 0, 0, 0, 0, 0}
	t.setCycleCount_HS0          = {0, 0, 0, 1, 1, 1, 0, 1, 2, 3, 4, 5}
	t.stimsetCycleID_HS0[]       = {0, 0, 0, 1, 1, 1, 2, 3, 4, 5, 6, 7}

	t.acquiredStimSets_HS1[0,5]  = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[6,11] = "StimulusSetD_DA_0"
	t.sweepCount_HS1             = {0, 1, 0, 1, 0, 1, 0, 1, 2, 0, 1, 2}
	t.setCycleCount_HS1          = {0, 0, 1, 1, 2, 2, 0, 0, 0, 1, 1, 1}
	t.stimsetCycleID_HS1[]       = {0, 0, 1, 1, 2, 2, 3, 3, 3, 4, 4, 4}

	AllTests(t, str)
End

Function SwitchIndexingOrder_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), str = "StimulusSetA_DA_0")
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Wave), str = "StimulusSetB_DA_0")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), str = "StimulusSetC_DA_0")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Wave), str = "StimulusSetD_DA_0")
End

Function Events_RepeatSets_4(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 3
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 4
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 5
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 6
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 7
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 8
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 9
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 10
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 11
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function RepeatSets_4([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L1_BKG_1_RES_2")
	AcquireData(s, str, preAcquireFunc = SwitchIndexingOrder_IGNORE, setAnalysisFuncs = 1)
End

Function RepeatSets_4_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 12
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_RepeatSets_4(t)

	t.acquiredStimSets_HS0[0,5]  = "StimulusSetB_DA_0"
	t.acquiredStimSets_HS0[6,11] = "StimulusSetA_DA_0"
	t.sweepCount_HS0             = {0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 1, 2}
	t.setCycleCount_HS0          = {0, 1, 2, 3, 4, 5, 0, 0, 0, 1, 1, 1}
	t.stimsetCycleID_HS0         = {2, 3, 4, 5, 6, 7, 0, 0, 0, 1, 1, 1}

	t.acquiredStimSets_HS1[0,5]  = "StimulusSetD_DA_0"
	t.acquiredStimSets_HS1[6,11] = "StimulusSetC_DA_0"
	t.sweepCount_HS1             = {0, 1, 2, 0, 1, 2, 0, 1, 0, 1, 0, 1}
	t.setCycleCount_HS1          = {0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 2, 2}
	t.stimsetCycleID_HS1         = {3, 3, 3, 4, 4, 4, 0, 0, 1, 1, 2, 2}

	AllTests(t, str)
End

Function Events_RepeatSets_5(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 3
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 4
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 5
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 6
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 7
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 8
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 9
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function RepeatSets_5([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L0_BKG_1_RES_2")
	AcquireData(s, str, preAcquireFunc = SwitchIndexingOrder_IGNORE, setAnalysisFuncs = 1)
End

Function RepeatSets_5_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 10
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_RepeatSets_5(t)

	t.acquiredStimSets_HS0[0]   = "StimulusSetB_DA_0"
	t.acquiredStimSets_HS0[1,3] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[4]   = "StimulusSetB_DA_0"
	t.acquiredStimSets_HS0[5,7] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[8]   = "StimulusSetB_DA_0"
	t.acquiredStimSets_HS0[9]   = "StimulusSetA_DA_0"
	t.sweepCount_HS0            = {0, 0, 1, 2, 0, 0, 1, 2, 0, 0}
	t.setCycleCount_HS0         = 0
	t.stimsetCycleID_HS0[]      = {0, 1, 1, 1, 2, 3, 3, 3, 4, 5}

	t.acquiredStimSets_HS1[0,2] = "StimulusSetD_DA_0"
	t.acquiredStimSets_HS1[3,4] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[5,7] = "StimulusSetD_DA_0"
	t.acquiredStimSets_HS1[8,9] = "StimulusSetC_DA_0"
	t.sweepCount_HS1            = {0, 1, 2, 0, 1, 0, 1, 2, 0, 1}
	t.setCycleCount_HS1         = 0
	t.stimsetCycleID_HS1[]      = {0, 0, 0, 1, 1, 2, 2, 2, 3, 3}

	AllTests(t, str)
End

Function ChangeStimSets_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Wave), str = "StimulusSetA_DA_0")
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), str = "StimulusSetB_DA_0")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Wave), str = "StimulusSetE_DA_0")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), str = "StimulusSetF_DA_0")
End

// test that locked indexing works when the maximum number of sweeps is
// not in the first stimset
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function RepeatSets_6([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L1_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc = ChangeStimSets_IGNORE)
End

Function RepeatSets_6_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 7
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)

	t.acquiredStimSets_HS0[0,2] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[3,6] = "StimulusSetB_DA_0"
	t.sweepCount_HS0            = {0, 1, 2, 0, 0, 0, 0}
	t.setCycleCount_HS0         = {0, 0, 0, 0, 1, 2, 3}
	t.stimsetCycleID_HS0[]      = {0, 0, 0, 1, 2, 3, 4}

	t.acquiredStimSets_HS1[0,2] = "StimulusSetE_DA_0"
	t.acquiredStimSets_HS1[3,6] = "StimulusSetF_DA_0"
	t.sweepCount_HS1            = {0, 1, 0, 0, 1, 2, 3}
	t.setCycleCount_HS1         = {0, 0, 1, 0, 0, 0, 0}
	t.stimsetCycleID_HS1[]      = {0, 0, 1, 2, 2, 2, 2}

	AllTests(t, str)
End

Function ActiveSetCountStimsets_IGNORE(device)
	string device

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetA_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "TrackActiveSetCount"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetB_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "TrackActiveSetCount"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetC_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "TrackActiveSetCount"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetD_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "TrackActiveSetCount"
End

static Function ActiveSetCount_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetC*")
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), str = "StimulusSetD*")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function CheckActiveSetCountU([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = ActiveSetCountStimsets_IGNORE, preAcquireFunc = ActiveSetCount_IGNORE)
End

Function CheckActiveSetCountU_REENTRY([str])
	string str

	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	WaveTransform/O zapNans, anaFuncActiveSetCount
	CHECK_EQUAL_WAVES(anaFuncActiveSetCount, {2, 1, 3, 2, 1})
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function CheckActiveSetCountL([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L1_BKG_1")
	AcquireData(s, str, postInitializeFunc = ActiveSetCountStimsets_IGNORE, preAcquireFunc = ActiveSetCount_IGNORE)
End

Function CheckActiveSetCountL_REENTRY([str])
	string str

	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	WaveTransform/O zapNans, anaFuncActiveSetCount
	CHECK_EQUAL_WAVES(anaFuncActiveSetCount, {2, 1, 3, 2, 1})
End

Function Events_RepeatSets_7(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN
End

static Function RepeatSets7_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 3)
	PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = 1)
End

// test that all events are fired, even with TP during ITI
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function RepeatSets_7([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, setAnalysisFuncs = 1, preAcquireFunc = RepeatSets7_IGNORE)
End

Function RepeatSets_7_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 3
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_RepeatSets_7(t)

	t.acquiredStimSets_HS0[] = "StimulusSetA_DA_0"
	t.sweepCount_HS0         = {0, 1, 2}
	t.setCycleCount_HS0      = 0
	t.stimsetCycleID_HS0[]   = {0, 0, 0}

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1         = {0, 1, 0}
	t.setCycleCount_HS1      = {0, 0, 1}
	t.stimsetCycleID_HS1[]   = {0, 0, 1}

	AllTests(t, str)
End

Function RepeatSets_8_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), str = NONE)
End

// Locked Indexing with TP during DAQ
//
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function RepeatSets_8([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L1_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc = RepeatSets_8_IGNORE)
End

Function RepeatSets_8_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 4
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)

	t.acquiredStimSets_HS0[0,2] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[3]   = "StimulusSetB_DA_0"
	t.sweepCount_HS0            = {0, 1, 2, 0}
	t.setCycleCount_HS0         = {0, 0, 0, 0}
	t.stimsetCycleID_HS0[]      = {0, 0, 0, 1}

	t.acquiredStimSets_HS1      = "Testpulse"
	t.sweepCount_HS1            = {0, 0, 0, 0}
	t.setCycleCount_HS1         = {NaN, NaN, NaN, NaN}
	WAVEClear t.stimsetCycleID_HS1

	t.DAQChannelTypeDA = {DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN}
	t.DAQChannelTypeAD = {DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN}

	AllTests(t, str)
End

Function RepeatSets_9_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), str = NONE)
End

// Unlocked Indexing with TP during DAQ
//
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function RepeatSets_9([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc = RepeatSets_9_IGNORE)
End

Function RepeatSets_9_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 4
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)

	t.acquiredStimSets_HS0[0,2] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[3]   = "StimulusSetB_DA_0"
	t.sweepCount_HS0            = {0, 1, 2, 0}
	t.setCycleCount_HS0         = {0, 0, 0, 0}
	t.stimsetCycleID_HS0[]      = {0, 0, 0, 1}

	t.acquiredStimSets_HS1      = "Testpulse"
	t.sweepCount_HS1            = {0, 0, 0, 0}
	t.setCycleCount_HS1         = {NaN, NaN, NaN, NaN}
	WAVEClear t.stimsetCycleID_HS1

	t.DAQChannelTypeDA = {DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN}
	t.DAQChannelTypeAD = {DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN}

	AllTests(t, str)
End

Function SkipSweepsStimsetsP_IGNORE(device)
	string device

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetA_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "SkipSweeps"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetB_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "SkipSweeps"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetC_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "SkipSweeps"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetD_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "SkipSweeps"
End

static Function SkipSweepsStimsets_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetA_*")
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), str = "StimulusSetD_*")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function SweepSkipping([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = SkipSweepsStimsetsP_IGNORE, preAcquireFunc = SkipSweepsStimsets_IGNORE)
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
End

Function SkipSweepsStimsetsAdvancedP_IGNORE(device)
	string device

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetA_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "SkipSweepsAdvanced"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetB_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "SkipSweepsAdvanced"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetC_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "SkipSweepsAdvanced"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetD_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "SkipSweepsAdvanced"
End

static Function SkipSweepsStimsetsAdvanced_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetA_*")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function SweepSkippingAdvanced([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")
	AcquireData(s, str, postInitializeFunc = SkipSweepsStimsetsAdvancedP_IGNORE, preAcquireFunc = SkipSweepsStimsetsAdvanced_IGNORE)
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
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 4)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 2)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	WaveTransform/O zapNans, anaFuncActiveSetCount
	CHECK_EQUAL_WAVES(anaFuncActiveSetCount, {3, 3, 1, 1})
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD0
Function SkipSweepsDuringITI_SD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA1_I0_L0_BKG_1_RES_5")
	AcquireData(s, str)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function SkipSweepsDuringITI_MD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_5")
	AcquireData(s, str)

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

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetA_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "TrackActiveSetCountsAndEvents"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetB_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "TrackActiveSetCountsAndEvents"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetC_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "TrackActiveSetCountsAndEvents"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetD_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "TrackActiveSetCountsAndEvents"
End

static Function SkipSweepsBackDuringITIStimsets_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetA_*")
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), str = "StimulusSetD_*")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function SkipSweepsBackDuringITI([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_0")
	AcquireData(s, str, postInitializeFunc = SkipSweepsBackDuringITIAnaFuncs_IGNORE, preAcquireFunc = SkipSweepsBackDuringITIStimsets_IGNORE)

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
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
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
	CHECK(index >= 1)
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

static Function CheckDAQStopReason(string device, variable stopReason)
	string key
	variable sweepNo

	key = "DAQ stop reason"

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE/Z sweeps = GetSweepsWithSetting(numericalValues, key)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	CHECK(DimSize(sweeps, ROWS) >= 1)

	sweepNo = sweeps[0]
	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(settings[INDEP_HEADSTAGE], stopReason)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD0
Function Abort_ITI_TP_SD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA1_I0_L0_BKG_1_RES_5")
	AcquireData(s, str)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function Abort_ITI_TP_MD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_5")
	AcquireData(s, str)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD0
Function Abort_ITI_TP_A_TP_SD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA1_I0_L0_BKG_1_RES_5")
	AcquireData(s, str)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function Abort_ITI_TP_A_TP_MD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_5")
	AcquireData(s, str)

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

Function StartDAQDuringTP_IGNORE(device)
	string device

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetA_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "WriteIntoLBNOnPreDAQ"
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function AbortTP([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_0")
	AcquireData(s, str, startTPInstead=1)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD0
Function StartDAQDuringTP([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA0_I0_L0_BKG_1_RES_0")
	AcquireData(s, str, startTPInstead=1, postInitializeFunc=StartDAQDuringTP_IGNORE)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD0
Function Abort_ITI_PressAcq_SD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA1_I0_L0_BKG_1_RES_5")
	AcquireData(s, str)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function Abort_ITI_PressAcq_MD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_5")
	AcquireData(s, str)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD0
Function Abort_ITI_TP_A_PressAcq_SD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA1_I0_L0_BKG_1_RES_5")
	AcquireData(s, str)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function Abort_ITI_TP_A_PressAcq_MD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_5")
	AcquireData(s, str)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD0
Function ChangeToSingleDeviceDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, postInitializeFunc=SetSingleDeviceDAQ_IGNORE)
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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function ChangeToMultiDeviceDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, postInitializeFunc=SetMultiDeviceDAQ_IGNORE)
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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function ChangeStimSetDuringDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc = ChangeStimSetDuringDAQ_IGNORE)
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
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function UnassociatedChannelsAndTTLs([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc = EnableUnassocChannels_IGNORE)
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

			WAVE/Z settings
			Variable index

			// fetch some labnotebook entries, the last channel is unassociated
			for(k = 0; k < DimSize(ADCs, ROWS); k += 1)
				[settings, index] = GetLastSettingChannel(numericalValues, $"", j, "AD ChannelType", ADCs[k], XOP_CHANNEL_TYPE_ADC, DATA_ACQUISITION_MODE)
				CHECK_EQUAL_VAR(settings[index], DAQ_CHANNEL_TYPE_DAQ)

				[settings, index] = GetLastSettingChannel(numericalValues, textualValues, j, "AD Unit", ADCs[k], XOP_CHANNEL_TYPE_ADC, DATA_ACQUISITION_MODE)
				WAVE/T settingsText = settings
				str = settingsText[index]
				expectedStr= "pA"
				CHECK_EQUAL_STR(str, expectedStr)
			endfor

			for(k = 0; k < DimSize(DACs, ROWS); k += 1)
				[settings, index] = GetLastSettingChannel(numericalValues, $"", j, "DA ChannelType", DACs[k], XOP_CHANNEL_TYPE_DAC, DATA_ACQUISITION_MODE)
				CHECK_EQUAL_VAR(settings[index], DAQ_CHANNEL_TYPE_DAQ)

				[settings, index] = GetLastSettingChannel(numericalValues, textualValues, j, "DA Unit", DACs[k], XOP_CHANNEL_TYPE_DAC, DATA_ACQUISITION_MODE)
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

	TestNwbExportV1()
	TestNwbExportV2()
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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function CheckSamplingInterval1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc=DisableSecondHeadstage_IGNORE)
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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function CheckSamplingInterval2([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc=UseSamplingInterval_IGNORE)
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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function CheckSamplingInterval3([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc=UseFixedFrequency_IGNORE)
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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function ChangeCMDuringSweep([str])
	string str

	string ctrl

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_1")
	AcquireData(s, str)

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

	WAVE clampMode = GetLastSetting(numericalValues, 0, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 1, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 2, "Clamp Mode", DATA_ACQUISITION_MODE)
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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function ChangeCMDuringSweepWMS([str])
	string str

	string ctrl

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc=EnableApplyOnModeSwitch_IGNORE)

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

	WAVE clampMode = GetLastSetting(numericalValues, 0, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode= WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 1, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 2, "Clamp Mode", DATA_ACQUISITION_MODE)
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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function ChangeCMDuringSweepNoRA([str])
	string str

	string ctrl

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str)

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

	WAVE clampMode = GetLastSetting(numericalValues, 0, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

Function ITISetupNoTP_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val=0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val=5)
	PGC_SetAndActivateControl(device, "check_Settings_ITITP", val=0)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function ChangeCMDuringITI([str])
	string str

	string ctrl

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc=ITISetupNoTP_IGNORE)

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

	WAVE clampMode = GetLastSetting(numericalValues, 0, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 1, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 2, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

Function ITISetupWithTP_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val=0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val=5)
	PGC_SetAndActivateControl(device, "check_Settings_ITITP", val=1)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function ChangeCMDuringITIWithTP([str])
	string str

	string ctrl

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc=ITISetupWithTP_IGNORE)

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

	WAVE clampMode = GetLastSetting(numericalValues, 0, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 1, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 2, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

Function TPDuringDAQOnlyTP_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function AutoPipetteOffsetIgnoresApplyOnModeSwitch([str])
	string str

	string ctrl

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc=EnableApplyOnModeSwitch_IGNORE, startTPInstead = 1)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function TPDuringDAQOnlyTP([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc=TPDuringDAQOnlyTP_IGNORE)
End

Function TPDuringDAQOnlyTP_REENTRY([str])
	string str

	variable sweepNo, col, tpAmplitude
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
	tpAmplitude = GetLastSettingIndep(numericalValues, sweepNo, "TP Amplitude VC", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {tpAmplitude, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z/T stimsets = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_TEXTWAVES(stimsets, {"TestPulse", "", "", "", "", "", "", "", ""}, mode = WAVE_DATA)
End

Function TPDuringDAQOnlyTPWithLockedIndexing_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function TPDuringDAQOnlyTPWithLockedIndexing([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_3")
	AcquireData(s, str, preAcquireFunc=TPDuringDAQOnlyTPWithLockedIndexing_IGNORE)

	PGC_SetAndActivateControl(str, "Check_DataAcq_Indexing", val = 1)
	PGC_SetAndActivateControl(str, "Check_DataAcq1_IndexingLocked", val = 0)
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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function TPDuringDAQTPAndAssoc([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc=TPDuringDAQTPAndAssoc_IGNORE)
End

Function TPDuringDAQTPAndAssoc_REENTRY([str])
	string str

	variable sweepNo, col, channelTypeUnassoc, tpAmplitude, stimScaleUnassoc
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
	tpAmplitude = GetLastSettingIndep(numericalValues, sweepNo, "TP Amplitude VC", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {tpAmplitude, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function TPDuringDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc=TPDuringDAQ_IGNORE)
End

Function TPDuringDAQ_REENTRY([str])
	string str

	variable sweepNo, col, tpAmplitude, daGain
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
	tpAmplitude = GetLastSettingIndep(numericalValues, sweepNo, "TP Amplitude VC", DATA_ACQUISITION_MODE)
	daGain = DAG_GetNumericalValue(str, GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE), index = 0)

	CHECK_EQUAL_WAVES(stimScale, {tpAmplitude, daGain, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function TPDuringDAQWithoodDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc=TPDuringDAQWithoodDAQ_IGNORE)
End

Function TPDuringDAQWithoodDAQ_REENTRY([str])
	string str

	variable sweepNo, col, tpAmplitude, daGain, oodDAQ
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
	tpAmplitude = GetLastSettingIndep(numericalValues, sweepNo, "TP Amplitude VC", DATA_ACQUISITION_MODE)
	daGain = DAG_GetNumericalValue(str, GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE), index = 0)

	oodDAQ = GetLastSettingIndep(numericalValues, sweepNo, "Optimized Overlap dDAQ", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(oodDAQ, 1)

	WAVE/Z oodDAQMembers = GetLastSetting(numericalValues, sweepNo, "oodDAQ member", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(oodDAQMembers, {0, 1, 1, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(stimScale, {tpAmplitude, daGain, daGain, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

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

static Constant TP_WIDTH_EPSILON = 1
static Constant TP_DYN_PERC_TRESHOLD = 0.2
static Constant TP_EDGE_EPSILON = 0.2
static Constant TP_SKIP_NUM_TPS_START = 1

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function TPDuringDAQTPStoreCheck([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc=TPDuringDAQTPStoreCheck_IGNORE)
End

Function TPDuringDAQTPStoreCheck_REENTRY([str])
	string str

	WaitAndCheckStoredTPs_IGNORE(str, 2)
End

Function WaitAndCheckStoredTPs_IGNORE(device, expectedNumTPchannels)
	string device
	variable expectedNumTPchannels

	variable i, channel, numTPChan, numStored, numTP, tpLength
	variable tresh, m, tpWidthInMS

	WAVE/Z TPStorage = GetTPStorage(device)
	CHECK_WAVE(TPStorage, NORMAL_WAVE)
	numStored = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)
	CHECK(numStored > TP_SKIP_NUM_TPS_START)

	WAVE/Z/WAVE storedTestPulses = GetStoredTestPulseWave(device)
	CHECK_WAVE(storedTestPulses, WAVE_WAVE)
	numTP = GetNumberFromWaveNote(storedTestPulses, NOTE_INDEX)

	CHECK(!ASYNC_WaitForWLCToFinishAndRemove(WORKLOADCLASS_TP + device, TP_WAIT_TIMEOUT))

	tpLength = TP_GetTestPulseLengthInPoints(device, DATA_ACQUISITION_MODE)

	NVAR duration = $GetTestpulseDuration(device)

	for(i = TP_SKIP_NUM_TPS_START; i < numTP; i += 1)

		WAVE/Z singleTPs = storedTestPulses[i]
		CHECK_WAVE(singleTPs, NUMERIC_WAVE)

		CHECK_EQUAL_VAR(tpLength, DimSize(singleTPs, ROWS))
		numTPChan = DimSize(singleTPs, COLS)
		CHECK_EQUAL_VAR(expectedNumTPchannels, numTPChan)

		for(channel = 0; channel < numTPChan; channel += 1)

			Duplicate/FREE/RMD=[][channel] singleTPs, singleTP
			Redimension/N=(tpLength) singleTP

			m = WaveMin(singleTP)
			tresh = m + TP_DYN_PERC_TRESHOLD * (WaveMax(singleTP) - m)
			FindLevels/Q/D=levels/M=(TP_EDGE_EPSILON) singleTP, tresh

			CHECK_EQUAL_VAR(2, V_LevelsFound)
			tpWidthInMS = duration * DimDelta(singleTP, ROWS)

			CHECK(abs(tpWidthInMS - levels[1] + levels[0]) < TP_WIDTH_EPSILON)

		endfor
	endfor
End

static Constant TP_DURATION_S = 5

Function CheckThatTPsCanBeFound_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, "check_Settings_TP_SaveTP", val = 1)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function CheckThatTPsCanBeFound([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, startTPInstead=1, preAcquireFunc=CheckThatTPsCanBeFound_IGNORE)

	CtrlNamedBackGround StopTPAfterFiveSeconds, start=(ticks + TP_DURATION_S * 60), period=1, proc=StopTPAfterFiveSeconds_IGNORE
End

Function CheckThatTPsCanBeFound_REENTRY([str])
	string str

	variable duration, index, col, i

	// check that we have at least 4.5 seconds of data
	WAVE/Z TPStorage = GetTPStorage(str)
	CHECK_WAVE(TPStorage, NORMAL_WAVE)

	index = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)
	CHECK(index > 0)
	duration = TPStorage[index - 1][0][%DeltaTimeInSeconds]
	CHECK(duration > TP_DURATION_S * 0.9)

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
End

Function TPDuringDAQWithTTL_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK), val = 0)

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK), val = 1)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE), str = "StimulusSetA_TTL_0")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function TPDuringDAQWithTTL([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc=TPDuringDAQWithTTL_IGNORE)
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

	// correct test pulse lengths calculated for both modes
#if defined(TESTS_WITH_ITC18USB_HARDWARE)
	CHECK_EQUAL_VAR(ROVar(GetTestpulseLengthInPoints(str, DATA_ACQUISITION_MODE)), 1000)
	CHECK_EQUAL_VAR(ROVar(GetTestpulseLengthInPoints(str, TEST_PULSE_MODE)), 2000)
#elif defined(TESTS_WITH_ITC1600_HARDWARE)
	CHECK_EQUAL_VAR(ROVar(GetTestpulseLengthInPoints(str, DATA_ACQUISITION_MODE)), 1000)
	CHECK_EQUAL_VAR(ROVar(GetTestpulseLengthInPoints(str, TEST_PULSE_MODE)), 2000)
#elif defined(TESTS_WITH_NI_HARDWARE)
	CHECK_EQUAL_VAR(ROVar(GetTestpulseLengthInPoints(str, DATA_ACQUISITION_MODE)), 5000)
	CHECK_EQUAL_VAR(ROVar(GetTestpulseLengthInPoints(str, TEST_PULSE_MODE)), 5000)
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

Function CheckIZeroClampMode_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, "Radio_ClampMode_1IZ", val = 1)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function CheckIZeroClampMode([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, setAnalysisFuncs = 1, preAcquireFunc=CheckIZeroClampMode_IGNORE)
End

Function CheckIZeroClampMode_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps = 1
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD1_RA0_I0_L0_BKG_1(t)

	t.acquiredStimSets_HS0[] = "StimulusSetA_DA_0"
	t.sweepCount_HS0[]       = 0
	t.setCycleCount_HS0[]    = 0
	t.stimsetCycleID_HS0[]   = 0

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1[]       = 0
	t.setCycleCount_HS1[]    = 0
	t.stimsetCycleID_HS1[]   = 0

	AllTests(t, str)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE clampMode = GetLastSetting(numericalValues, 0, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {I_EQUAL_ZERO_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode=WAVE_DATA)
End

Function HasNaNAsDefaultWhenAborted_IGNORE(device)
	string device

	// enable TTL1
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK), val=1)
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE), str="StimulusSetA*")
	CtrlNamedBackGround Abort_ITI_PressAcq, start, period=30, proc=StopAcq_IGNORE
End

// check default values for data when aborting DAQ
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function HasNaNAsDefaultWhenAborted([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=HasNaNAsDefaultWhenAborted_IGNORE)
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
	CHECK(V_row >= 0)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function TestPulseCachingWorks([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA3_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=TestPulseCachingWorks_IGNORE)
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
	CHECK(V_Value >= 0)

	WAVE stats = GetCacheStatsWave()
	CHECK(stats[V_Value][%Hits] >= 1)
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
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function UnassocChannelsDuplicatedEntry([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc = UnassocChannelsDuplicatedEntry_IGNORE)
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
		CHECK(V_Value > 0)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function RestoreDAEphysPanel([str])
	string str

	variable jsonID
	string stimSetPath, jPath, data, fName, rewrittenConfigPath

	fName = PrependExperimentFolder_IGNORE(REF_DAEPHYS_CONFIG_FILE)

	[data, fName] = LoadTextFile(fname)

	jsonID = JSON_Parse(data)
	PathInfo home
	jPath = MIES_CONF#CONF_FindControl(jsonID, "popup_MoreSettings_Devices")
	JSON_SetString(jsonID, jPath + "/StrValue", str)
	JSON_SetString(jsonID, "/Common configuration data/Save data to", S_path)
	stimSetPath = S_path + "..:..:Packages:Testing-MIES:_2017_09_01_192934-compressed.nwb"
	JSON_SetString(jsonID, "/Common configuration data/Stim set file name", stimSetPath)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function LabnotebookEntriesCanBeQueried([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc = LabnotebookEntriesCanBeQueried_IGNORE)
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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function DataBrowserCreatesBackupsByDefault([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	AcquireData(s, str)
End

Function DataBrowserCreatesBackupsByDefault_REENTRY([str])
	string str

	variable sweepNo, numEntries, i
	string list, name

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	DB_OpenDataBrowser()

	WAVE sweepWave = GetSweepWave(str, 0)
	DFREF sweepFolder = GetWavesDataFolderDFR(sweepWave)
	DFREF singleSweepFolder = GetSingleSweepFolder(sweepFolder, 0)

	// check that all non-backup waves in singleSweepFolder have a backup
	list = GetListOfObjects(singleSweepFolder, "^[A-Za-z]{1,}_[0-9]$")
	numEntries = ItemsInList(list)
	CHECK(numEntries > 0)

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
/// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function IncrementalLabnotebookCacheUpdate([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	KillOrMoveToTrash(wv = anaFuncTracker)

	AcquireData(s, str, preAcquireFunc = ILCUSetup_IGNORE)
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

Function ILCUCheck_IGNORE(string panelTitle, STRUCT AnalysisFunction_V3& s)

	variable nonExistingSweep

	WAVE/T textualValues = GetLBTextualValues(panelTitle)
	WAVE numericalValues = GetLBNumericalValues(panelTitle)

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

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetA_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "SweepRollbackChecker"
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
/// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function TestSweepRollback([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc = TestSweepRollbackPreAcquire_IGNORE)
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

/// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function TestAcquiringNewDataOnOldData([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str)
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
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str)

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
	PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_UNSELECTED)

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

/// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function AsyncAcquisitionLBN([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc = AsyncAcquisitionLBN_IGNORE)
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
	CHECK_EQUAL_VAR(var, CHECKBOX_UNSELECTED)

	var = GetLastSettingIndep(numericalValues, 0, "Async Alarm 2 Min", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(var, 0.1)

	var = GetLastSettingIndep(numericalValues, 0, "Async Alarm  2 Max", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(var, 0.5)

	var = GetLastSettingIndep(numericalValues, 0, "Async AD 2 [myTitle]", DATA_ACQUISITION_MODE)
	CHECK(var >= 0)

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

/// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function CheckSettingsFails([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	try
		AcquireData(s, str, preAcquireFunc = CheckSettingsFails_IGNORE)
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

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetC_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "AcquisitionStateTrackingFunc"

	CtrlNamedBackGround ExecuteDuringITI, start, period=30, proc=AddLabnotebookEntries_IGNORE

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 5)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function CheckAcquisitionStates_MD([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc=CheckAcquisitionStates_IGNORE)
End

Function CheckAcquisitionStates_MD_REENTRY([string str])
	CheckAcquisitionStates(str)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD0
Function CheckAcquisitionStates_SD([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA1_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc=CheckAcquisitionStates_IGNORE)
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
		CHECK(DimSize(indizesEntryOneSweep, ROWS) > 0)

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
End

Function ConfigureFails_IGNORE(string device)

	string ctrl

	ctrl = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	PGC_SetAndActivateControl(device, ctrl, val = 10000)
End

/// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function ConfigureFails([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	try
		AcquireData(s, str, preAcquireFunc = ConfigureFails_IGNORE)
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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function StopDAQDueToUnlocking([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_5")
	AcquireData(s, str)

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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function StopDAQDueToUncompiled([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_5")
	AcquireData(s, str)

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
// UTF_TD_GENERATOR HardwareMain#MajorNWBVersions
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
	CHECK(numEntries > 0)

	for(i = 0; i < numEntries; i += 1)
		WAVE oldWave = $oldWaves[i]
		WAVE newWave = $newWaves[i]

		CHECK_EQUAL_WAVES(oldWave, newWave)
	endfor
End

/// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function ExportIntoNWB([str])
	string str

	string filePathExport, experimentName

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	AcquireData(s, str, startTPInstead = 1)

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

/// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function ExportIntoNWBSweepBySweep([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc = ExportIntoNWBSweepBySweep_IGNORE)
End

Function ExportIntoNWBSweepBySweep_REENTRY([str])
	string str

	string experimentNwbFile, stimsets, acquisition, stimulus
	variable fileID, nwbVersion

	CloseNwbFile()
	experimentNwbFile = GetExperimentNWBFileForExport()
	CHECK(FileExists(experimentNwbFile))

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

/// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function ExportOnlyCommentsIntoNWB([string str])

	string discLocation, userComment, userCommentRef
	variable fileID

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	try
		AcquireData(s, str, preAcquireFunc = ExportOnlyCommentsIntoNWB_IGNORE)
	catch
		CHECK_EQUAL_VAR(V_AbortCode, -3)
	endtry

	discLocation = TestNWBExportV2#TestFileExport()
	CHECK(FileExists(discLocation))

	fileID = H5_OpenFile(discLocation)
	userComment = TestNWBExportV2#TestUserComment(fileID, str)
	userCommentRef = "abcdefgh ijjkl"
	CHECK(strsearch(userComment, userCommentRef, 0) >= 0)

	H5_CloseFile(fileID)
End

Function CheckPulseInfoGathering_IGNORE(string device)
	string ctrl

	ctrl = GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
	PGC_SetAndActivateControl(device, ctrl, val=0)

	ctrl = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	PGC_SetAndActivateControl(device, ctrl, str = "Y4_SRecovery_50H*")
End

/// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function CheckPulseInfoGathering([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc = CheckPulseInfoGathering_IGNORE)
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
