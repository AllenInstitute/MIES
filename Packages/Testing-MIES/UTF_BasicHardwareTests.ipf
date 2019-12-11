#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma ModuleName=BasicHardwareTests

/// @file UTF_BasicHardWareTests.ipf Implement some basic tests using the ITC hardware.

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

		PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), val = GetStimSet("StimulusSetA_DA_0") + 1)
		PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), val = GetStimSet("StimulusSetB_DA_0") + 1)
		PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), val = GetStimSet("StimulusSetC_DA_0") + 1)
		PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), val = GetStimSet("StimulusSetD_DA_0") + 1)

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
		PGC_SetAndActivateControl(device, "Check_Settings_BackgrndDataAcq", val = s.BKG_DAQ)

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
			CHECK_EQUAL_VAR(config[0][0], ITC_XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_VAR(config[1][0], ITC_XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_VAR(config[2][0], ITC_XOP_CHANNEL_TYPE_ADC)
			CHECK_EQUAL_VAR(config[3][0], ITC_XOP_CHANNEL_TYPE_ADC)

			// check channel numbers
			WAVE DACs = GetDACListFromConfig(config)
			CHECK_EQUAL_WAVES(DACs, {0, 1}, mode = WAVE_DATA)

			WAVE ADCs = GetADCListFromConfig(config)
			CHECK_EQUAL_WAVES(ADCs, {0, 1}, mode = WAVE_DATA)

			WAVE TTLs = GetTTLListFromConfig(config)
			CHECK_EQUAL_VAR(DimSize(TTLs, ROWS), 0)

			// check channel units
			unit = AFH_GetChannelUnit(config, 0, ITC_XOP_CHANNEL_TYPE_DAC)
			CHECK_PROPER_STR(unit)

			unit = AFH_GetChannelUnit(config, 1, ITC_XOP_CHANNEL_TYPE_DAC)
			CHECK_PROPER_STR(unit)

			unit = AFH_GetChannelUnit(config, 0, ITC_XOP_CHANNEL_TYPE_ADC)
			CHECK_PROPER_STR(unit)

			unit = AFH_GetChannelUnit(config, 1, ITC_XOP_CHANNEL_TYPE_ADC)
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
		endfor
	endfor

	TestNwbExport()
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
	t.events_HS0[][PRE_SWEEP_EVENT] = p
	t.events_HS1[][PRE_SWEEP_EVENT] = p

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

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), val = GetStimSet("StimulusSetA_DA_0") + 1)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Wave), val = GetStimSet("StimulusSetB_DA_0") + 1)
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), val = GetStimSet("StimulusSetC_DA_0") + 1)
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Wave), val = GetStimSet("StimulusSetD_DA_0") + 1)
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
	t.setCycleCount_HS1         = {0, 0, 0, 0}
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
	t.setCycleCount_HS1         = {0, 0, 0, 0}
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
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD0
Function SkipSweepsDuringITI_SD([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA1_I0_L0_BKG_1_RES_5")
	AcquireData(s, str)

	CtrlNamedBackGround ExecuteDuringITI, start, period=30, proc=ExecuteDuringITI_IGNORE

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

	CtrlNamedBackGround ExecuteDuringITI, start, period=30, proc=ExecuteDuringITI_IGNORE

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

static Function CheckLastLBNEntryFromTP_IGNORE(device)
	string device

	variable index

	// last LBN entry is from TP
	WAVE numericalValues = GetLBNumericalValues(device)
	index = GetNumberFromWaveNote(numericalValues, NOTE_INDEX)
	CHECK(index >= 1)
	CHECK_EQUAL_VAR(numericalValues[index - 1][%EntrySourceType], TEST_PULSE_MODE)
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

	// check that TP after DAQ really ran
	CheckLastLBNEntryFromTP_IGNORE(str)
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

	// check that TP after DAQ really ran
	CheckLastLBNEntryFromTP_IGNORE(str)
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

Function Abort_ITI_TP_A_Acq_SD_REENTRY([str])
	string str

	NVAR runModeDAQ = $GetDataAcqRunMode(str)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(str)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	// check that TP after DAQ really ran
	CheckLastLBNEntryFromTP_IGNORE(str)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function Abort_ITI_TP_A_Acq_MD([str])
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

Function Abort_ITI_TP_A_Acq_MD_REENTRY([str])
	string str

	NVAR runModeDAQ = $GetDataAcqRunMode(str)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(str)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	// check that TP after DAQ really ran
	CheckLastLBNEntryFromTP_IGNORE(str)
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

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function ChangeStimSetDuringDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_1")
	AcquireData(s, str)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 600), period=60, proc=StopTP_IGNORE
	CtrlNamedBackGround ChangeStimsetDuringDAQ, start=180, period=30, proc=ChangeStimSet_IGNORE
	PGC_SetAndActivateControl(str, "check_Settings_TPAfterDAQ", val = 1)
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
Function UnassociatedChannels([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, preAcquireFunc = EnableUnassocChannels_IGNORE)
End

Function UnassociatedChannels_REENTRY([str])
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
			CHECK_EQUAL_VAR(config[0][0], ITC_XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_VAR(config[1][0], ITC_XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_VAR(config[2][0], ITC_XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_VAR(config[3][0], ITC_XOP_CHANNEL_TYPE_ADC)
			CHECK_EQUAL_VAR(config[4][0], ITC_XOP_CHANNEL_TYPE_ADC)
			CHECK_EQUAL_VAR(config[5][0], ITC_XOP_CHANNEL_TYPE_ADC)
			CHECK_EQUAL_VAR(config[6][0], ITC_XOP_CHANNEL_TYPE_TTL)

			// check channel numbers
			WAVE DACs = GetDACListFromConfig(config)
			CHECK_EQUAL_WAVES(DACs, {0, 1, 2}, mode = WAVE_DATA)

			WAVE ADCs = GetADCListFromConfig(config)
			CHECK_EQUAL_WAVES(ADCs, {0, 1, 2}, mode = WAVE_DATA)

			WAVE TTLs = GetTTLListFromConfig(config)

			WAVE/Z ttlStimSets = GetTTLstimSets(numericalValues, textualValues, j)
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
					break
				case HARDWARE_NI_DAC:
					CHECK_EQUAL_WAVES(TTLs, {1, 3}, mode = WAVE_DATA)

					WAVE/T/Z channelsTxT = GetLastSetting(textualValues, j, "TTL channels", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(channelsTxT, {"", "", "", "", "", "", "", "", ";1;;3;;;;;"}, mode = WAVE_DATA)

					WAVE/T/Z foundStimSets = GetLastSetting(textualValues, j, "TTL stim sets", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(foundStimSets, {"", "", "", "", "", "", "", "", ";StimulusSetA_TTL_0;;StimulusSetB_TTL_0;;;;;"})

					WAVE/T/Z sweepCounts = GetLastSetting(textualValues, j, "TTL set sweep counts", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(sweepCounts, {"", "", "", "", "", "", "", "", ";0;;0;;;;;"})
					break
			endswitch

			WAVE/Z settings
			Variable index

			// fetch some labnotebook entries, the last channel is unassociated
			for(k = 0; k < DimSize(ADCs, ROWS); k += 1)
				[settings, index] = GetLastSettingChannel(numericalValues, $"", j, "AD ChannelType", ADCs[k], ITC_XOP_CHANNEL_TYPE_ADC, DATA_ACQUISITION_MODE)
				CHECK_EQUAL_VAR(settings[index], DAQ_CHANNEL_TYPE_DAQ)

				[settings, index] = GetLastSettingChannel(numericalValues, textualValues, j, "AD Unit", ADCs[k], ITC_XOP_CHANNEL_TYPE_ADC, DATA_ACQUISITION_MODE)
				WAVE/T settingsText = settings
				str = settingsText[index]
				expectedStr= "pA"
				CHECK_EQUAL_STR(str, expectedStr)
			endfor

			for(k = 0; k < DimSize(DACs, ROWS); k += 1)
				[settings, index] = GetLastSettingChannel(numericalValues, $"", j, "DA ChannelType", DACs[k], ITC_XOP_CHANNEL_TYPE_DAC, DATA_ACQUISITION_MODE)
				CHECK_EQUAL_VAR(settings[index], DAQ_CHANNEL_TYPE_DAQ)

				[settings, index] = GetLastSettingChannel(numericalValues, textualValues, j, "DA Unit", DACs[k], ITC_XOP_CHANNEL_TYPE_DAC, DATA_ACQUISITION_MODE)
				WAVE/T settingsText = settings
				str = settingsText[index]
				expectedStr= "mV"
				CHECK_EQUAL_STR(str, expectedStr)
			endfor
		endfor
	endfor

	TestNwbExport()
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
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode=1)

	WAVE clampMode = GetLastSetting(numericalValues, 1, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode=1)

	WAVE clampMode = GetLastSetting(numericalValues, 2, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode=1)
End

Function EnableApplyOnModeSwitch_IGNORE(device)
	string device

	string ctrl

	ctrl = GetPanelControl(CHANNEL_INDEX_ALL_I_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	PGC_SetAndActivateControl(device, ctrl, str = "StimulusSetA_DA_0")

	ctrl = GetPanelControl(CHANNEL_INDEX_ALL_V_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	PGC_SetAndActivateControl(device, ctrl, str = "StimulusSetA_DA_0")

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
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode=1)

	WAVE clampMode = GetLastSetting(numericalValues, 1, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode=1)

	WAVE clampMode = GetLastSetting(numericalValues, 2, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode=1)
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
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode=1)
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
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode=1)

	WAVE clampMode = GetLastSetting(numericalValues, 1, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode=1)

	WAVE clampMode = GetLastSetting(numericalValues, 2, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode=1)
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
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode=1)

	WAVE clampMode = GetLastSetting(numericalValues, 1, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode=1)

	WAVE clampMode = GetLastSetting(numericalValues, 2, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode=1)
End

Function TPDuringDAQOnlyTP_IGNORE(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
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

	WAVE DAChannelTypes = GetLastSetting(numericalValues, sweepNo, "DA ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(DAChannelTypes, {DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE ADChannelTypes = GetLastSetting(numericalValues, sweepNo, "AD ChannelType", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(ADChannelTypes, {DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	key = CreateLBNUnassocKey("DA ChannelType", 1, ITC_XOP_CHANNEL_TYPE_DAC)
	channelTypeUnassoc = GetLastSettingIndep(numericalValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(channelTypeUnassoc, DAQ_CHANNEL_TYPE_TP)

	key = CreateLBNUnassocKey("AD ChannelType", 1, ITC_XOP_CHANNEL_TYPE_ADC)
	channelTypeUnassoc = GetLastSettingIndep(numericalValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(channelTypeUnassoc, DAQ_CHANNEL_TYPE_DAQ)

	WAVE/Z stimScale = GetLastSetting(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
	tpAmplitude = GetLastSettingIndep(numericalValues, sweepNo, "TP Amplitude VC", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {tpAmplitude, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	key = CreateLBNUnassocKey(STIMSET_SCALE_FACTOR_KEY, 1, ITC_XOP_CHANNEL_TYPE_DAC)
	stimScaleUnassoc = GetLastSettingIndep(numericalValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(stimScaleUnassoc, 0.0)

	WAVE/Z/T stimsets = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_TEXTWAVES(stimsets, {"TestPulse", "", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	key = CreateLBNUnassocKey(STIM_WAVE_NAME_KEY, 1, ITC_XOP_CHANNEL_TYPE_DAC)
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

Function TPWaitForAsync_IGNORE(TPStorage, storedTP)
	WAVE TPStorage
	WAVE storedTP
	variable timeOut

	variable sizeAsyncOut, sizeMainThread, endTime

	sizeMainThread = GetNumberFromWaveNote(storedTP, NOTE_INDEX)
	endTime = DateTime + TP_WAIT_TIMEOUT
	do
		ASYNC_ThreadReadOut()
		sizeAsyncOut = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)
		if(sizeMainThread == sizeAsyncOut)
			return NaN
		endif
	while(DateTime < endTime)
	FAIL() // TimeOut for TP data was reached
End

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

	if(numTP != numStored)
		TPWaitForAsync_IGNORE(TPStorage, storedTestPulses)
	endif

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
End

// check default values for data when aborting DAQ
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function HasNaNAsDefaultWhenAborted([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AcquireData(s, str, preAcquireFunc=HasNaNAsDefaultWhenAborted_IGNORE)
	CtrlNamedBackGround Abort_ITI_PressAcq, start=(ticks + 3), period=30, proc=StopAcq_IGNORE
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
	CHECK(V_row > 0)

	// check that we have NaNs for all columns starting from the first unacquired point
	Duplicate/FREE/RMD=[V_row,][] sweepWave, unacquiredData
	WaveStats/M=1 unacquiredData
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

	[data, fName] = LoadTextFile(REF_DAEPHYS_CONFIG_FILE)

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
	MIES_CONF#CONF_SaveDAEphys(REF_TMP1_CONFIG_FILE)

	CONF_RestoreDAEphys(jsonID, rewrittenConfigPath, middleOfExperiment = 1)
	MIES_CONF#CONF_SaveDAEphys(REF_TMP1_CONFIG_FILE)
End
