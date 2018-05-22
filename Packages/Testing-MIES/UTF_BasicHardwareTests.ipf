#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file UTF_BasicHardWareTests.ipf Implement some basic tests using the ITC hardware.

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(s, [postInitializeFunc, preAcquireFunc])
	STRUCT DAQSettings& s
	FUNCREF CALLABLE_PROTO postInitializeFunc, preAcquireFunc

	string unlockedPanelTitle, devices, device
	variable i, numEntries

	Initialize_IGNORE()

	if(!ParamIsDefault(postInitializeFunc))
		postInitializeFunc()
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
		PGC_SetAndActivateControl(unlockedPanelTitle, "popup_MoreSettings_DeviceType", val=5)
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
EndStructure

static Function InitTestStructure(t)
	STRUCT TestSettings &t

	REQUIRE(t.numSweeps > 0)
	Make/T/FREE/N=(t.numSweeps) t.acquiredStimSets_HS0, t.acquiredStimSets_HS1
	Make/FREE/N=(t.numSweeps) t.sweepCount_HS0, t.sweepCount_HS1
	Make/FREE/N=(t.numSweeps) t.setCycleCount_HS0, t.setCycleCount_HS1
	Make/FREE/N=(t.numSweeps) t.stimsetCycleID_HS0, t.stimsetCycleID_HS1
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
		endfor
	endfor
End

Function DAQ_MD0_RA0_IDX0_LIDX0_BKG_0()

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s)
End

Function Test_MD0_RA0_IDX0_LIDX0_BKG_0()

	STRUCT TestSettings t

	t.numSweeps        = 1
	t.sweepWaveType    = FLOAT_WAVE

	InitTestStructure(t)

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

Function DAQ_MD1_RA0_IDX0_LIDX0_BKG_1()

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s)
End

Function Test_MD1_RA0_IDX0_LIDX0_BKG_1()

	STRUCT TestSettings t

	t.numSweeps = 1
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)

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

Function DAQ_MD0_RA1_IDX0_LIDX0_BKG_0()

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s)
End

Function Test_MD0_RA1_IDX0_LIDX0_BKG_0()

	STRUCT TestSettings t

	t.numSweeps              = 3
	t.sweepWaveType          = FLOAT_WAVE

	InitTestStructure(t)

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

Function DAQ_MD1_RA1_IDX0_LIDX0_BKG_1()

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s)
End

Function Test_MD1_RA1_IDX0_LIDX0_BKG_1()

	STRUCT TestSettings t

	t.numSweeps              = 3
	t.sweepWaveType          = FLOAT_WAVE

	InitTestStructure(t)

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

Function DAQ_MD1_RA1_IDX1_LIDX0_BKG_1()

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s)
End

Function Test_MD1_RA1_IDX1_LIDX0_BKG_1()

	STRUCT TestSettings t

	t.numSweeps     = 5
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)

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

Function DAQ_MD0_RA1_IDX1_LIDX0_BKG_0()

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s)
End

Function Test_MD0_RA1_IDX1_LIDX0_BKG_0()

	STRUCT TestSettings t

	t.numSweeps     = 5
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)

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

Function DAQ_MD1_RA1_IDX1_LIDX1_BKG_1()

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s)
End

Function Test_MD1_RA1_IDX1_LIDX1_BKG_1()

	STRUCT TestSettings t

	t.numSweeps     = 6
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)

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

Function DAQ_MD0_RA1_IDX1_LIDX1_BKG_0()

	STRUCT DAQSettings s
	InitSettings(s)
	AcquireData(s)
End

Function Test_MD0_RA1_IDX1_LIDX1_BKG_0()

	STRUCT TestSettings t

	t.numSweeps     = 6
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)

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

Function DAQ_RepeatSets_1()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1_RES_2")
	AcquireData(s)
End

Function Test_RepeatSets_1()

	STRUCT TestSettings t

	t.numSweeps     = 6
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)

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

Function DAQ_RepeatSets_2()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX1_LIDX0_BKG_1_RES_2")
	AcquireData(s)
End

Function Test_RepeatSets_2()

	STRUCT TestSettings t

	t.numSweeps     = 10
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)

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

Function DAQ_RepeatSets_3()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX1_LIDX1_BKG_1_RES_2")
	AcquireData(s)
End

Function Test_RepeatSets_3()

	STRUCT TestSettings t

	t.numSweeps     = 12
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)

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

	string device

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1_RES_1")
	AcquireData(s, preAcquireFunc = EnableUnassocChannels_IGNORE)

	device = GetSingleDevice()
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

			CHECK_EQUAL_VAR(DimSize(config, ROWS), 7)

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
			CHECK_EQUAL_WAVES(TTLs, {HW_ITC_GetITCXOPChannelForRack(device, RACK_ZERO)}, mode = WAVE_DATA)
		endfor
	endfor
End
