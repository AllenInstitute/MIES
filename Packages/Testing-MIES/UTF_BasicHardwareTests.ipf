#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file UTF_BasicHardWareTests.ipf Implement some basic tests using the ITC hardware.

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(s)
	STRUCT DAQSettings& s

	string unlockedPanelTitle, devices, device
	variable i, numEntries

	Initialize_IGNORE()

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

	PGC_SetAndActivateControl(device, "DataAcquireButton")
End

static Structure TestSettings
	variable numSweeps
	variable sweepWaveType
	WAVE/T   acquiredStimSets_HS0, acquiredStimSets_HS1 // including repetitions
	WAVE sweepCount_HS0, sweepCount_HS1
EndStructure

static Function InitTestStructure(t)
	STRUCT TestSettings &t

	REQUIRE(t.numSweeps > 0)
	Make/T/FREE/N=(t.numSweeps) t.acquiredStimSets_HS0, t.acquiredStimSets_HS1
	Make/FREE/N=(t.numSweeps) t.sweepCount_HS0, t.sweepCount_HS1
End

static Function AllTests(t)
	STRUCT TestSettings &t

	string sweeps, configs, stimset, foundStimSet, devices, device
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

			sweepNo = ExtractSweepNumber(NameOfWave(sweep))
			CHECK(sweepNo >= 0)
			WAVE/T/Z foundStimSets = GetLastSettingText(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
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

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1[]       = 0

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

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1[]       = 0

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

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1[]       = {0, 1, 0}

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

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1[]       = {0, 1, 0}

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

	t.acquiredStimSets_HS1[0,1] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[2,4] = "StimulusSetD_DA_0"
	t.sweepCount_HS1            = {0, 1, 0, 1, 2}

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

	t.acquiredStimSets_HS1[0,1] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[2,4] = "StimulusSetD_DA_0"
	t.sweepCount_HS1            = {0, 1, 0, 1, 2}

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

	t.acquiredStimSets_HS1[0,2] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[3,5] = "StimulusSetD_DA_0"
	t.sweepCount_HS1            = {0, 1, 0, 0, 1, 2}

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

	t.acquiredStimSets_HS1[0,2] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[3,5] = "StimulusSetD_DA_0"
	t.sweepCount_HS1            = {0, 1, 0, 0, 1, 2}

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

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1         = {0, 1, 0, 1, 0, 1}

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

	t.acquiredStimSets_HS1[0,1] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[2,4] = "StimulusSetD_DA_0"
	t.acquiredStimSets_HS1[5,6] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[7,9] = "StimulusSetD_DA_0"
	t.sweepCount_HS1            = {0, 1, 0, 1, 2, 0, 1, 0, 1, 2}

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

	t.acquiredStimSets_HS1[0,5]  = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[6,11] = "StimulusSetD_DA_0"
	t.sweepCount_HS1             = {0, 1, 0, 1, 0, 1, 0, 1, 2, 0, 1, 2}

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
