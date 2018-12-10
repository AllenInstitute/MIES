#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file UTF_BasicHardWareTests.ipf Implement some basic tests using the ITC hardware.

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
static Function AcquireData(s, [postInitializeFunc, preAcquireFunc, setAnalysisFuncs])
	STRUCT DAQSettings& s
	FUNCREF CALLABLE_PROTO postInitializeFunc, preAcquireFunc
	variable setAnalysisFuncs

	string unlockedPanelTitle, devices, device
	variable i, numEntries

	KillOrMoveToTrash(wv = GetTrackSweepCounts())
	KillOrMoveToTrash(wv = GetTrackActiveSetCount())
	Initialize_IGNORE()

	if(!ParamIsDefault(postInitializeFunc))
		postInitializeFunc()
	endif

	if(ParamIsDefault(setAnalysisFuncs))
		setAnalysisFuncs = 0
	else
		setAnalysisFuncs = !!setAnalysisFuncs
	endif

	if(setAnalysisFuncs)
		SetAnalysisFunctions_IGNORE()
	endif

	devices = GetDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devices)

		unlockedPanelTitle = DAP_CreateDAEphysPanel()

#ifdef TESTS_WITH_YOKING
		PGC_SetAndActivateControl(unlockedPanelTitle, "popup_MoreSettings_DeviceType", val=2)
		PGC_SetAndActivateControl(unlockedPanelTitle, "popup_moreSettings_DeviceNo", val=i)
#else
		ChooseCorrectDevice(unlockedPanelTitle, device)
#endif
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

		CHECK_EQUAL_VAR(DimSize(ampMCC, ROWS), 2)
		CHECK_EQUAL_VAR(DimSize(ampTel, ROWS), 2)

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

		CtrlNamedBackGround DAQWatchdog, start, period=120, proc=WaitUntilDAQDone_IGNORE
	endfor

	device = GetSingleDevice()

#ifdef TESTS_WITH_YOKING
	PGC_SetAndActivateControl(device, "button_Hardware_Lead1600")
	PGC_SetAndActivateControl(device, "popup_Hardware_AvailITC1600s", val=0)
	PGC_SetAndActivateControl(device, "button_Hardware_AddFollower")

	ARDLaunchSeqPanel()
	PGC_SetAndActivateControl("ArduinoSeq_Panel", "SendSequenceButton")
#endif

	if(!ParamIsDefault(preAcquireFunc))
		preAcquireFunc()
	endif

	PGC_SetAndActivateControl(device, "DataAcquireButton")
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
EndStructure

static Function InitTestStructure(t)
	STRUCT TestSettings &t

	REQUIRE(t.numSweeps > 0)
	Make/T/FREE/N=(t.numSweeps) t.acquiredStimSets_HS0, t.acquiredStimSets_HS1
	Make/FREE/N=(t.numSweeps) t.sweepCount_HS0, t.sweepCount_HS1
	Make/FREE/N=(t.numSweeps) t.setCycleCount_HS0, t.setCycleCount_HS1
	Make/FREE/N=(t.numSweeps) t.stimsetCycleID_HS0, t.stimsetCycleID_HS1
	Make/FREE/N=(t.numSweeps, TOTAL_NUM_EVENTS) t.events_HS0 = NaN, t.events_HS1 = NaN
End

static Function AllTests(t)
	STRUCT TestSettings &t

	string sweeps, configs, stimset, foundStimSet, devices, device, unit
	variable i, j, sweepNo, numEntries

	devices = GetDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devices)

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

			WAVE sciSweeps = AFH_GetSweepsFromSameSCI(numericalValues, j, 0)
			Extract/FREE/INDX t.stimsetCycleID_HS0, indizes, t.stimsetCycleID_HS0 == t.stimsetCycleID_HS0[j]
			CHECK_EQUAL_WAVES(sciSweeps, indizes, mode = WAVE_DATA)

			WAVE sciSweeps = AFH_GetSweepsFromSameSCI(numericalValues, j, 1)
			Extract/FREE/INDX t.stimsetCycleID_HS1, indizes, t.stimsetCycleID_HS1 == t.stimsetCycleID_HS1[j]
			CHECK_EQUAL_WAVES(sciSweeps, indizes, mode = WAVE_DATA)

			Duplicate/FREE/RMD=[j][][0] anaFuncSweepTracker, actualEvents_HS0
			Duplicate/FREE/RMD=[j][] t.events_HS0, refEvents_HS0
			Redimension/E=1/N=(TOTAL_NUM_EVENTS) refEvents_HS0, actualEvents_HS0

			CHECK_EQUAL_WAVES(refEvents_HS0, actualEvents_HS0, mode = WAVE_DATA)

			Duplicate/FREE/RMD=[j][][1] anaFuncSweepTracker, actualEvents_HS1
			Duplicate/FREE/RMD=[j][] t.events_HS1, refEvents_HS1
			Redimension/E=1/N=(TOTAL_NUM_EVENTS) refEvents_HS1, actualEvents_HS1

			CHECK_EQUAL_WAVES(refEvents_HS1, actualEvents_HS1, mode = WAVE_DATA)
		endfor
	endfor
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

Function Events_MD0_RA0_IDX0_LIDX0_BKG_0(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]    = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT]   = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]    = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT]   = NaN
End

Function DAQ_MD0_RA0_IDX0_LIDX0_BKG_0()

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s, setAnalysisFuncs = 1)
End

Function Test_MD0_RA0_IDX0_LIDX0_BKG_0()

	STRUCT TestSettings t

	t.numSweeps        = 1
	t.sweepWaveType    = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD0_RA0_IDX0_LIDX0_BKG_0(t)

	t.acquiredStimSets_HS0[] = "StimulusSetA_DA_0"
	t.sweepCount_HS0[]       = 0
	t.setCycleCount_HS0[]    = 0
	t.stimsetCycleID_HS0[]   = 0

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1[]       = 0
	t.setCycleCount_HS1[]    = 0
	t.stimsetCycleID_HS1[]   = 0

	AllTests(t)
End

Function Events_MD1_RA0_IDX0_LIDX0_BKG_1(t)
	STRUCT TestSettings &t

	Events_MD0_RA0_IDX0_LIDX0_BKG_0(t)
End

Function DAQ_MD1_RA0_IDX0_LIDX0_BKG_1()

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s, setAnalysisFuncs = 1)
End

Function Test_MD1_RA0_IDX0_LIDX0_BKG_1()

	STRUCT TestSettings t

	t.numSweeps = 1
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD1_RA0_IDX0_LIDX0_BKG_1(t)

	t.acquiredStimSets_HS0[] = "StimulusSetA_DA_0"
	t.sweepCount_HS0[]       = 0
	t.setCycleCount_HS0[]    = 0
	t.stimsetCycleID_HS0[]   = 0

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1[]       = 0
	t.setCycleCount_HS1[]    = 0
	t.stimsetCycleID_HS1[]   = 0

	AllTests(t)
End

Function Events_MD0_RA1_IDX0_LIDX0_BKG_1(t)
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

Function DAQ_MD0_RA1_IDX0_LIDX0_BKG_0()

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s, setAnalysisFuncs = 1)
End

Function Test_MD0_RA1_IDX0_LIDX0_BKG_0()

	STRUCT TestSettings t

	t.numSweeps              = 3
	t.sweepWaveType          = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD0_RA1_IDX0_LIDX0_BKG_1(t)

	t.acquiredStimSets_HS0[] = "StimulusSetA_DA_0"
	t.sweepCount_HS0         = {0, 1, 2}
	t.setCycleCount_HS0[]    = 0
	t.stimsetCycleID_HS0[]   = 0

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1[]       = {0, 1, 0}
	t.setCycleCount_HS1[]    = {0, 0, 1}
	t.stimsetCycleID_HS1[]   = {0, 0, 1}

	AllTests(t)
End

Function Events_MD1_RA1_IDX0_LIDX0_BKG_1(t)
	STRUCT TestSettings &t

	Events_MD0_RA1_IDX0_LIDX0_BKG_1(t)
End

Function DAQ_MD1_RA1_IDX0_LIDX0_BKG_1()

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s, setAnalysisFuncs = 1)
End

Function Test_MD1_RA1_IDX0_LIDX0_BKG_1()

	STRUCT TestSettings t

	t.numSweeps              = 3
	t.sweepWaveType          = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD1_RA1_IDX0_LIDX0_BKG_1(t)

	t.acquiredStimSets_HS0[] = "StimulusSetA_DA_0"
	t.sweepCount_HS0         = {0, 1, 2}
	t.setCycleCount_HS0[]    = 0
	t.stimsetCycleID_HS0[]   = 0

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1[]       = {0, 1, 0}
	t.setCycleCount_HS1[]    = {0, 0, 1}
	t.stimsetCycleID_HS1[]   = {0, 0, 1}

	AllTests(t)
End

Function Events_MD1_RA1_IDX1_LIDX0_BKG_1(t)
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

Function DAQ_MD1_RA1_IDX1_LIDX0_BKG_1()

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s, setAnalysisFuncs = 1)
End

Function Test_MD1_RA1_IDX1_LIDX0_BKG_1()

	STRUCT TestSettings t

	t.numSweeps     = 5
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD1_RA1_IDX1_LIDX0_BKG_1(t)

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

	AllTests(t)
End

Function Events_MD0_RA1_IDX1_LIDX0_BKG_0(t)
	STRUCT TestSettings &t

	Events_MD1_RA1_IDX1_LIDX0_BKG_1(t)
End

Function DAQ_MD0_RA1_IDX1_LIDX0_BKG_0()

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s, setAnalysisFuncs = 1)
End

Function Test_MD0_RA1_IDX1_LIDX0_BKG_0()

	STRUCT TestSettings t

	t.numSweeps     = 5
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD0_RA1_IDX1_LIDX0_BKG_0(t)

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

	AllTests(t)
End

Function Events_MD1_RA1_IDX1_LIDX1_BKG_1(t)
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

Function DAQ_MD1_RA1_IDX1_LIDX1_BKG_1()

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s, setAnalysisFuncs = 1)
End

Function Test_MD1_RA1_IDX1_LIDX1_BKG_1()

	STRUCT TestSettings t

	t.numSweeps     = 6
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD1_RA1_IDX1_LIDX1_BKG_1(t)

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

	AllTests(t)
End

Function Events_MD0_RA1_IDX1_LIDX1_BKG_0(t)
	STRUCT TestSettings &t

	Events_MD1_RA1_IDX1_LIDX1_BKG_1(t)
End

Function DAQ_MD0_RA1_IDX1_LIDX1_BKG_0()

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s, setAnalysisFuncs = 1)
End

Function Test_MD0_RA1_IDX1_LIDX1_BKG_0()

	STRUCT TestSettings t

	t.numSweeps     = 6
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD0_RA1_IDX1_LIDX1_BKG_0(t)

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

	AllTests(t)
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

Function DAQ_RepeatSets_1()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1_RES_2")
	AcquireData(s, setAnalysisFuncs = 1)
End

Function Test_RepeatSets_1()

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

	AllTests(t)
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

Function DAQ_RepeatSets_2()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX1_LIDX0_BKG_1_RES_2")
	AcquireData(s, setAnalysisFuncs = 1)
End

Function Test_RepeatSets_2()

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

	AllTests(t)
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

Function DAQ_RepeatSets_3()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX1_LIDX1_BKG_1_RES_2")
	AcquireData(s, setAnalysisFuncs = 1)
End

Function Test_RepeatSets_3()

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

	AllTests(t)
End

Function SwitchIndexingOrder()
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), val = GetStimSet("StimulusSetA_DA_0") + 1)
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Wave), val = GetStimSet("StimulusSetB_DA_0") + 1)
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), val = GetStimSet("StimulusSetC_DA_0") + 1)
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Wave), val = GetStimSet("StimulusSetD_DA_0") + 1)
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

Function DAQ_RepeatSets_4()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX1_LIDX1_BKG_1_RES_2")
	AcquireData(s, preAcquireFunc = SwitchIndexingOrder, setAnalysisFuncs = 1)
End

Function Test_RepeatSets_4()

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

	AllTests(t)
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

Function DAQ_RepeatSets_5()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX1_LIDX0_BKG_1_RES_2")
	AcquireData(s, preAcquireFunc = SwitchIndexingOrder, setAnalysisFuncs = 1)
End

Function Test_RepeatSets_5()

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

	AllTests(t)
End

Function ChangeStimSets()

	PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Wave), str = "StimulusSetA_DA_0")
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), str = "StimulusSetB_DA_0")
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Wave), str = "StimulusSetE_DA_0")
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), str = "StimulusSetF_DA_0")
End

// test that locked indexing works when the maximum number of sweeps is
// not in the first stimset
Function DAQ_RepeatSets_6()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX1_LIDX1_BKG_1_RES_1")
	AcquireData(s, preAcquireFunc = ChangeStimSets)
End

Function Test_RepeatSets_6()

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

	AllTests(t)
End

Function ActiveSetCountStimsets()

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

static Function ActiveSetCount_IGNORE()

	PGC_SetAndActivateControl(DEVICE, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetC*")
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), str = "StimulusSetD*")
End

Function DAQ_CheckActiveSetCountU()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX1_LIDX0_BKG_1")
	AcquireData(s, postInitializeFunc = ActiveSetCountStimsets, preAcquireFunc = ActiveSetCount_IGNORE)
End

Function Test_CheckActiveSetCountU()

	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	WaveTransform/O zapNans, anaFuncActiveSetCount
	CHECK_EQUAL_WAVES(anaFuncActiveSetCount, {2, 1, 3, 2, 1})
End

Function DAQ_CheckActiveSetCountL()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX1_LIDX1_BKG_1")
	AcquireData(s, postInitializeFunc = ActiveSetCountStimsets, preAcquireFunc = ActiveSetCount_IGNORE)
End

Function Test_CheckActiveSetCountL()

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

static Function RepeatSets7_IGNORE()

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 3)
	PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = 1)
End

// test that all events are fired, even with TP during ITI
Function DAQ_RepeatSets_7()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1_RES_1")
	AcquireData(s, setAnalysisFuncs = 1, preAcquireFunc = RepeatSets7_IGNORE)
End

Function Test_RepeatSets_7()

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

	AllTests(t)
End

Function SkipSweepsStimsets()

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

static Function SkipSweepsStimsets_IGNORE()

	PGC_SetAndActivateControl(DEVICE, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetA_*")
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), str = "StimulusSetD_*")
End

Function DAQ_SweepSkipping()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX1_LIDX0_BKG_1")
	AcquireData(s, postInitializeFunc = SkipSweepsStimsets, preAcquireFunc = SkipSweepsStimsets_IGNORE)
End

Function Test_SweepSkipping()

	variable numSweeps = 4
	variable sweepNo   = 0
	variable headstage = 0

	CHECK_EQUAL_VAR(GetSetVariable(device, "SetVar_Sweep"), numSweeps)

	WAVE/T textualValues   = GetLBTextualValues(device)
	WAVE   numericalValues = GetLBNumericalValues(device)

	WAVE/T/Z foundStimSets = GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, STIM_WAVE_NAME_KEY, headstage, DATA_ACQUISITION_MODE)
	REQUIRE_WAVE(foundStimSets, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(foundStimSets, {"StimulusSetA_DA_0", "StimulusSetB_DA_0", "StimulusSetC_DA_0", "StimulusSetD_DA_0"})

	WAVE/Z sweepCounts = GetLastSettingEachRAC(numericalValues, sweepNo, "Set Sweep Count", headstage, DATA_ACQUISITION_MODE)
	REQUIRE_WAVE(sweepCounts, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(sweepCounts, {0, 0, 0, 0}, mode = WAVE_DATA)
End

Function DAQ_SkipSweepsDuringITI_SD()

	string device

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD0_RA1_IDX0_LIDX0_BKG_1_RES_5")
	AcquireData(s)

	device = GetSingleDevice()

	CtrlNamedBackGround ExecuteDuringITI, start, period=30, proc=ExecuteDuringITI_IGNORE

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 5)
End

Function Test_SkipSweepsDuringITI_SD()

	string devices, device
	variable numEntries, i

	devices = GetDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devices)
		NVAR runMode = $GetDataAcqRunMode(device)

		CHECK_EQUAL_VAR(runMode, DAQ_NOT_RUNNING)
	endfor
End

Function DAQ_SkipSweepsDuringITI_MD()

	string device

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1_RES_5")
	AcquireData(s)

	device = GetSingleDevice()

	CtrlNamedBackGround ExecuteDuringITI, start, period=30, proc=ExecuteDuringITI_IGNORE

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 5)
End

Function Test_SkipSweepsDuringITI_MD()

	string devices, device
	variable numEntries, i

	devices = GetDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devices)
		NVAR runMode = $GetDataAcqRunMode(device)

		CHECK_EQUAL_VAR(runMode, DAQ_NOT_RUNNING)
	endfor
End

Function DAQ_Abort_ITI_PressTP_SD()

	string device

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD0_RA1_IDX0_LIDX0_BKG_1_RES_5")
	AcquireData(s)

	device = GetSingleDevice()

	CtrlNamedBackGround Abort_ITI_PressTP, start, period=30, proc=StartTPDuringITI_IGNORE

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 5)
End

Function Test_Abort_ITI_PressTP_SD()

	string devices, device
	variable numEntries, i

	devices = GetDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devices)

		NVAR runModeDAQ = $GetDataAcqRunMode(device)
		CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

		NVAR runModeTP = $GetTestpulseRunMode(device)
		CHECK(runModeTP != TEST_PULSE_NOT_RUNNING)
		CHECK(!(runModeTP & TEST_PULSE_DURING_RA_MOD))
	endfor
End

Function DAQ_Abort_ITI_PressTP_MD()

	string device

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1_RES_5")
	AcquireData(s)

	device = GetSingleDevice()

	CtrlNamedBackGround Abort_ITI_PressTP, start, period=30, proc=StartTPDuringITI_IGNORE

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 5)
End

Function Test_Abort_ITI_PressTP_MD()

	string devices, device
	variable numEntries, i

	devices = GetDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devices)

		NVAR runModeDAQ = $GetDataAcqRunMode(device)
		CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

		NVAR runModeTP = $GetTestpulseRunMode(device)
		CHECK(runModeTP != TEST_PULSE_NOT_RUNNING)
		CHECK(!(runModeTP & TEST_PULSE_DURING_RA_MOD))
	endfor
End

Function DAQ_Abort_ITI_TP_A_PressTP_SD()

	string device

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD0_RA1_IDX0_LIDX0_BKG_1_RES_5")
	AcquireData(s)

	device = GetSingleDevice()

	CtrlNamedBackGround Abort_ITI_PressTP, start, period=30, proc=StartTPDuringITI_IGNORE

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 5)
	PGC_SetAndActivateControl(device, "check_Settings_TPAfterDAQ", val = 1)
End

Function Test_Abort_ITI_TP_A_PressTP_SD()

	string devices, device
	variable numEntries, i

	devices = GetDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devices)

		NVAR runModeDAQ = $GetDataAcqRunMode(device)

		CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

		NVAR runModeTP = $GetTestpulseRunMode(device)
		CHECK(runModeTP != TEST_PULSE_NOT_RUNNING)
		CHECK(!(runModeTP & TEST_PULSE_DURING_RA_MOD))
	endfor
End

Function DAQ_Abort_ITI_TP_A_PressTP_MD()

	string device

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1_RES_5")
	AcquireData(s)

	device = GetSingleDevice()

	CtrlNamedBackGround Abort_ITI_PressTP, start, period=30, proc=StartTPDuringITI_IGNORE

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 5)
	PGC_SetAndActivateControl(device, "check_Settings_TPAfterDAQ", val = 1)
End

Function Test_Abort_ITI_TP_A_PressTP_MD()

	string devices, device
	variable numEntries, i

	devices = GetDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devices)

		NVAR runModeDAQ = $GetDataAcqRunMode(device)

		CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

		NVAR runModeTP = $GetTestpulseRunMode(device)
		CHECK(runModeTP != TEST_PULSE_NOT_RUNNING)
		CHECK(!(runModeTP & TEST_PULSE_DURING_RA_MOD))
	endfor
End

Function DAQ_Abort_ITI_PressAcq_SD()

	string device

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD0_RA1_IDX0_LIDX0_BKG_1_RES_5")
	AcquireData(s)

	device = GetSingleDevice()

	CtrlNamedBackGround Abort_ITI_PressAcq, start, period=30, proc=StopAcqDuringITI_IGNORE

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 5)
End

Function Test_Abort_ITI_PressAcq_SD()

	string devices, device
	variable numEntries, i

	devices = GetDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devices)

		NVAR runModeDAQ = $GetDataAcqRunMode(device)
		CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

		NVAR runModeTP = $GetTestpulseRunMode(device)
		CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)
	endfor
End

Function DAQ_Abort_ITI_PressAcq_MD()

	string device

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1_RES_5")
	AcquireData(s)

	device = GetSingleDevice()

	CtrlNamedBackGround Abort_ITI_PressAcq, start, period=30, proc=StopAcqDuringITI_IGNORE

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 5)
End

Function Test_Abort_ITI_PressAcq_MD()

	string devices, device
	variable numEntries, i

	devices = GetDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devices)

		NVAR runModeDAQ = $GetDataAcqRunMode(device)
		CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

		NVAR runModeTP = $GetTestpulseRunMode(device)
		CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)
	endfor
End

Function DAQ_Abort_ITI_TP_A_PressAcq_SD()

	string device

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD0_RA1_IDX0_LIDX0_BKG_1_RES_5")
	AcquireData(s)

	device = GetSingleDevice()

	CtrlNamedBackGround Abort_ITI_PressAcq, start, period=30, proc=StopAcqDuringITI_IGNORE

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 5)
	PGC_SetAndActivateControl(device, "check_Settings_TPAfterDAQ", val = 1)
End

Function Test_Abort_ITI_TP_A_PressAcq_SD()

	string devices, device
	variable numEntries, i

	devices = GetDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devices)

		NVAR runModeDAQ = $GetDataAcqRunMode(device)

		CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

		NVAR runModeTP = $GetTestpulseRunMode(device)
		CHECK(runModeTP != TEST_PULSE_NOT_RUNNING)
		CHECK(!(runModeTP & TEST_PULSE_DURING_RA_MOD))
	endfor
End

Function DAQ_Abort_ITI_TP_A_PressAcq_MD()

	string device

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1_RES_5")
	AcquireData(s)

	device = GetSingleDevice()

	CtrlNamedBackGround Abort_ITI_PressAcq, start, period=30, proc=StopAcqDuringITI_IGNORE

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 5)
	PGC_SetAndActivateControl(device, "check_Settings_TPAfterDAQ", val = 1)
End

Function Test_Abort_ITI_TP_A_PressAcq_MD()

	string devices, device
	variable numEntries, i

	devices = GetDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devices)

		NVAR runModeDAQ = $GetDataAcqRunMode(device)

		CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

		NVAR runModeTP = $GetTestpulseRunMode(device)
		CHECK(runModeTP != TEST_PULSE_NOT_RUNNING)
		CHECK(!(runModeTP & TEST_PULSE_DURING_RA_MOD))
	endfor
End

static Function SetSingleDeviceDAQ_IGNORE()
	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetA_DA_0
	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set] = "ChangeToSingleDeviceDAQ"
End

Function DAQ_ChangeToSingleDeviceDAQ()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1_RES_1")
	AcquireData(s, postInitializeFunc=SetSingleDeviceDAQ_IGNORE)
End

Function Test_ChangeToSingleDeviceDAQ()
	string device
	variable sweepNo, multiDeviceMode

	device = GetSingleDevice()

	CHECK_EQUAL_VAR(GetCheckBoxState(device, "check_Settings_MD"), CHECKBOX_UNSELECTED)

	sweepNo = AFH_GetLastSweepAcquired(device)
	WAVE numericalValues = GetLBNumericalValues(device)
	multiDeviceMode = GetLastSettingIndep(numericalValues, sweepNo, "Multi device mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(multiDeviceMode, 0)
End

static Function SetMultiDeviceDAQ_IGNORE()
	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetA_DA_0
	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set] = "ChangeToMultiDeviceDAQ"
End

Function DAQ_ChangeToMultiDeviceDAQ()
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD0_RA0_IDX0_LIDX0_BKG_1_RES_1")
	AcquireData(s, postInitializeFunc=SetMultiDeviceDAQ_IGNORE)
End

Function Test_ChangeToMultiDeviceDAQ()
	string device
	variable sweepNo, multiDeviceMode

	device = GetSingleDevice()

	CHECK_EQUAL_VAR(GetCheckBoxState(device, "check_Settings_MD"), CHECKBOX_SELECTED)

	sweepNo = AFH_GetLastSweepAcquired(device)
	WAVE numericalValues = GetLBNumericalValues(device)
	multiDeviceMode = GetLastSettingIndep(numericalValues, sweepNo, "Multi device mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(multiDeviceMode, 1)
End

Function DAQ_ChangeStimSetDuringDAQ()

	string device

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1_RES_1")
	AcquireData(s)

	device = GetSingleDevice()

	CtrlNamedBackGround ChangeStimsetDuringDAQ, start=180, period=30, proc=ChangeStimSet_IGNORE
	PGC_SetAndActivateControl(device, "check_Settings_TPAfterDAQ", val = 1)
End

Function Test_ChangeStimSetDuringDAQ()

	string devices, device
	variable numEntries, i

	devices = GetDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devices)

		NVAR runModeDAQ = $GetDataAcqRunMode(device)
		CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

		NVAR runModeTP = $GetTestpulseRunMode(device)
		CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_BG_MULTI_DEVICE)
	endfor
End

Function EnableUnassocChannels_IGNORE()

	string device = GetSingleDevice()

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
End

// Using unassociated channels works
Function DAQ_UnassociatedChannels()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1_RES_1")
	AcquireData(s, preAcquireFunc = EnableUnassocChannels_IGNORE)
End

Function Test_UnassociatedChannels()

	string devices, device, sweeps, configs, unit
	variable numEntries, i, j, numSweeps

	numSweeps = 1
	devices = GetDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devices)

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

			switch(GetHardwareType(device))
				case HARDWARE_ITC_DAC:
					// check TTL LBN keys
					CHECK_EQUAL_WAVES(TTLs, {HW_ITC_GetITCXOPChannelForRack(device, RACK_ZERO)}, mode = WAVE_DATA)
					WAVE/T/Z foundStimSets = GetLastSetting(textualValues, j, "TTL rack zero stim sets", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(foundStimSets, {"", "", "", "", "", "", "", "", ";StimulusSetA_TTL_0;;StimulusSetB_TTL_0;"})
					WAVE/T/Z foundStimSets = GetLastSetting(textualValues, j, "TTL rack one stim sets", DATA_ACQUISITION_MODE)
					CHECK(!WaveExists(foundStimSets))

					WAVE/Z bits = GetLastSetting(numericalValues, j, "TTL rack zero bits", DATA_ACQUISITION_MODE)
					// TTL 1 and 3 are active -> 2^1 + 2^3 = 10
					CHECK_EQUAL_WAVES(bits, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 10}, mode = WAVE_DATA)
					WAVE/Z bits = GetLastSetting(numericalValues, j, "TTL rack one bits", DATA_ACQUISITION_MODE)
					CHECK(!WaveExists(bits))

					WAVE/Z channels = GetLastSetting(numericalValues, j, "TTL rack zero channel", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_VAR(DimSize(TTLs, ROWS), 1)
					CHECK_EQUAL_WAVES(channels, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, TTLs[0]}, mode = WAVE_DATA)
					WAVE/Z channels = GetLastSetting(numericalValues, j, "TTL rack one channel", DATA_ACQUISITION_MODE)
					CHECK(!WaveExists(bits))

					// set sweep count
					WAVE/T/Z sweepCounts = GetLastSetting(textualValues, j, "TTL rack zero set sweep counts", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(sweepCounts, {"", "", "", "", "", "", "", "", ";0;;0;"})
					WAVE/T/Z sweepCounts = GetLastSetting(textualValues, j, "TTL rack one set sweep counts", DATA_ACQUISITION_MODE)
					CHECK(!WaveExists(sweepCounts))
					break
				case HARDWARE_NI_DAC:
					CHECK_EQUAL_WAVES(TTLs, {1, 3}, mode = WAVE_DATA)
					break
			endswitch
		endfor
	endfor
End

static Function GetMinSampInt([unit])
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
	return factor * HARDWARE_NI6343_MIN_SAMPINT
#else
	return factor * HARDWARE_ITC_MIN_SAMPINT
#endif

End

static Function DisableSecondHeadstage_IGNORE()

	PGC_SetAndActivateControl(DEVICE, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=0)
End

Function DAQ_CheckSamplingInterval1()
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1_RES_1")
	AcquireData(s, preAcquireFunc=DisableSecondHeadstage_IGNORE)
End

Function Test_CheckSamplingInterval1()

	variable sweepNo, sampInt, sampIntMult, fixedFreqAcq, expectedSampInt

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(device, sweepNo)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NORMAL_WAVE)

	sampInt = GetSamplingInterval(configWave)
	CHECK_CLOSE_VAR(sampInt, GetMinSampInt(unit="µs"), tol=1e-6)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	sampInt = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval", DATA_ACQUISITION_MODE)
	expectedSampInt = GetMinSampInt(unit="ms")
	CHECK_CLOSE_VAR(sampInt, expectedSampInt, tol=1e-6)

	sampIntMult = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval multiplier", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(sampIntMult, 1)

	fixedFreqAcq = GetLastSettingIndep(numericalValues, sweepNo, "Fixed frequency acquisition", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(fixedFreqAcq, NaN)

	CHECK_EQUAL_VAR(DimOffset(sweepWave, ROWS), 0)
	CHECK_CLOSE_VAR(DimDelta(sweepWave, ROWS), expectedSampInt, tol=1e-6)
End

Function UseSamplingInterval_IGNORE()

	PGC_SetAndActivateControl(DEVICE, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=0)
	PGC_SetAndActivateControl(DEVICE, "Popup_Settings_SampIntMult", str="8")
End

Function DAQ_CheckSamplingInterval2()
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1_RES_1")
	AcquireData(s, preAcquireFunc=UseSamplingInterval_IGNORE)
End

Function Test_CheckSamplingInterval2()

	variable sweepNo, sampInt, sampIntMult, fixedFreqAcq, expectedSampInt

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(device, sweepNo)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NORMAL_WAVE)

	sampInt = GetSamplingInterval(configWave)
	CHECK_CLOSE_VAR(sampInt, GetMinSampInt(unit="µs") * 8, tol=1e-6)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	sampInt = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval", DATA_ACQUISITION_MODE)
	expectedSampInt = GetMinSampInt(unit="ms") * 8
	CHECK_CLOSE_VAR(sampInt, expectedSampInt, tol=1e-6)

	sampIntMult = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval multiplier", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(sampIntMult, 8)

	fixedFreqAcq = GetLastSettingIndep(numericalValues, sweepNo, "Fixed frequency acquisition", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(fixedFreqAcq, NaN)

	CHECK_EQUAL_VAR(DimOffset(sweepWave, ROWS), 0)
	CHECK_CLOSE_VAR(DimDelta(sweepWave, ROWS), expectedSampInt, tol=1e-6)
End

static Function UseFixedFrequency_IGNORE()

	PGC_SetAndActivateControl(DEVICE, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=0)
	PGC_SetAndActivateControl(DEVICE, "Popup_Settings_FixedFreq", str="100")
End

Function DAQ_CheckSamplingInterval3()
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1_RES_1")
	AcquireData(s, preAcquireFunc=UseFixedFrequency_IGNORE)
End

Function Test_CheckSamplingInterval3()

	variable sweepNo, sampInt, sampIntMult, fixedFreqAcq, expectedSampInt

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(device, sweepNo)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NORMAL_WAVE)

	sampInt = GetSamplingInterval(configWave)
	CHECK_CLOSE_VAR(sampInt, 10, tol=1e-6)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

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
