#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=TrackSweepCounts

static Function [STRUCT DAQSettings s] GetDAQSettings([string overrideConfig])

	if(ParamIsDefault(overrideConfig))
		// get name of caller which are the required DAQSettings in string form
		overrideConfig = GetRTStackInfo(2)
	endif

	InitDAQSettingsFromString(s, overrideConfig                                                      + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:_IST:StimulusSetB_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:_IST:StimulusSetD_DA_0:")
End

static Function GlobalPreInit(string device)
	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "TrackSweepCount_V3")
	ST_SetStimsetParameter("StimulusSetB_DA_0", "Analysis function (generic)", str = "TrackSweepCount_V3")
	ST_SetStimsetParameter("StimulusSetC_DA_0", "Analysis function (generic)", str = "TrackSweepCount_V3")
	ST_SetStimsetParameter("StimulusSetD_DA_0", "Analysis function (generic)", str = "TrackSweepCount_V3")
End

static Function GlobalPreAcq(string device)

	PASS()
End

static Structure TestSettings
	variable numSweeps
	variable sweepWaveType
	WAVE/T acquiredStimSets_HS0, acquiredStimSets_HS1 // including repetitions
	WAVE sweepCount_HS0, sweepCount_HS1
	WAVE setCycleCount_HS0, setCycleCount_HS1
	WAVE stimsetCycleID_HS0, stimsetCycleID_HS1
	// store the sweep count where a event was fired
	WAVE events_HS0, events_HS1
	WAVE DAQChannelTypeAD, DAQChannelTypeDA
EndStructure

static Function InitTestStructure(t)
	STRUCT TestSettings &t

	REQUIRE_GT_VAR(t.numSweeps, 0)
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
	string               devices

	string sweeps, configs, stimset, foundStimSet, device, unit
	variable i, j, k, sweepNo, numEntries, numChannels

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = stringFromList(i, devices)

		CHECK_EQUAL_VAR(GetSetVariable(device, "SetVar_Sweep"), t.numSweeps)
		sweeps  = GetListOfObjects(GetDeviceDataPath(device), DATA_SWEEP_REGEXP, fullPath = 1)
		configs = GetListOfObjects(GetDeviceDataPath(device), DATA_CONFIG_REGEXP, fullPath = 1)

		CHECK_EQUAL_VAR(ItemsInList(sweeps), t.numSweeps)
		CHECK_EQUAL_VAR(ItemsInList(configs), t.numSweeps)

		WAVE/T textualValues       = GetLBTextualValues(device)
		WAVE   numericalValues     = GetLBNumericalValues(device)
		WAVE   anaFuncSweepTracker = GetTrackSweepCounts()

		for(j = 0; j < t.numSweeps; j += 1)
			WAVE/Z sweep = $StringFromList(j, sweeps)
			CHECK_WAVE(sweep, TEXT_WAVE)

			WAVE/Z config = $StringFromList(j, configs)
			CHECK_WAVE(config, NUMERIC_WAVE)
			CHECK_EQUAL_VAR(DimSize(config, ROWS), DimSize(sweep, ROWS))

			CHECK_EQUAL_VAR(DimSize(config, ROWS), 4)

			numChannels = DimSize(config, ROWS)

			for(k = 0; k < numChannels; k += 1)

				WAVE channel = ResolveSweepChannel(sweep, k)
				WaveStats/M=1/Q channel
				if(config[k][%ChannelType] == XOP_CHANNEL_TYPE_ADC)
					CHECK_EQUAL_VAR(V_numNaNs, 0)
				endif
				CHECK_EQUAL_VAR(V_numInfs, 0)
				CHECK_WAVE(channel, NUMERIC_WAVE, minorType = t.sweepWaveType)
			endfor

			// check channel types
			CHECK_EQUAL_VAR(config[0][%ChannelType], XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_VAR(config[1][%ChannelType], XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_VAR(config[2][%ChannelType], XOP_CHANNEL_TYPE_ADC)
			CHECK_EQUAL_VAR(config[3][%ChannelType], XOP_CHANNEL_TYPE_ADC)

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
			CHECK_GE_VAR(sweepNo, 0)
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

	if(DoExpensiveChecks())
		TestNwbExportV1()
		TestNwbExportV2()
	endif
End

static Function Events_Common(t)
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

static Function Events_MD0_RA0_I0_L0_BKG0(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo                               = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD0
static Function MD0_RA0_I0_L0_BKG0([str])
	string str

	PrepareForPublishTest()

	[STRUCT DAQSettings s] = GetDAQSettings()

	AcquireData_NG(s, str)
End

static Function MD0_RA0_I0_L0_BKG0_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 1
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD0_RA0_I0_L0_BKG0(t)

	t.acquiredStimSets_HS0[] = "StimulusSetA_DA_0"
	t.sweepCount_HS0[]       = 0
	t.setCycleCount_HS0[]    = 0
	t.stimsetCycleID_HS0[]   = 0

	t.acquiredStimSets_HS1[] = "StimulusSetC_DA_0"
	t.sweepCount_HS1[]       = 0
	t.setCycleCount_HS1[]    = 0
	t.stimsetCycleID_HS1[]   = 0

	CheckStartStopMessages("daq", "starting")
	CheckStartStopMessages("daq", "stopping")

	AllTests(t, str)
End

static Function Events_MD1_RA0_I0_L0_BKG1(t)
	STRUCT TestSettings &t

	Events_MD0_RA0_I0_L0_BKG0(t)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function MD1_RA0_I0_L0_BKG1([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings()
	AcquireData_NG(s, str)
End

static Function MD1_RA0_I0_L0_BKG1_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 1
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD1_RA0_I0_L0_BKG1(t)

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

static Function Events_MD0_RA1_I0_L0_BKG1(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo                               = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD0
static Function MD0_RA1_I0_L0_BKG0([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings()
	AcquireData_NG(s, str)
End

static Function MD0_RA1_I0_L0_BKG0_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 3
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD0_RA1_I0_L0_BKG1(t)

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

static Function Events_MD1_RA1_I0_L0_BKG1(t)
	STRUCT TestSettings &t

	Events_MD0_RA1_I0_L0_BKG1(t)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function MD1_RA1_I0_L0_BKG1([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings()
	AcquireData_NG(s, str)
End

static Function MD1_RA1_I0_L0_BKG1_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 3
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD1_RA1_I0_L0_BKG1(t)

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

static Function Events_MD1_RA1_I1_L0_BKG1(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo                               = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 3
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 4
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function MD1_RA1_I1_L0_BKG1([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings()
	AcquireData_NG(s, str)
End

static Function MD1_RA1_I1_L0_BKG1_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 5
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD1_RA1_I1_L0_BKG1(t)

	t.acquiredStimSets_HS0[0, 2] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[3]    = "StimulusSetB_DA_0"
	t.acquiredStimSets_HS0[4]    = "StimulusSetA_DA_0"
	t.sweepCount_HS0             = {0, 1, 2, 0, 0}
	t.setCycleCount_HS0          = 0
	t.stimsetCycleID_HS0[]       = {0, 0, 0, 1, 2}

	t.acquiredStimSets_HS1[0, 1] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[2, 4] = "StimulusSetD_DA_0"
	t.sweepCount_HS1             = {0, 1, 0, 1, 2}
	t.setCycleCount_HS1          = 0
	t.stimsetCycleID_HS1[]       = {0, 0, 1, 1, 1}

	AllTests(t, str)
End

static Function Events_MD0_RA1_I1_L0_BKG0(t)
	STRUCT TestSettings &t

	Events_MD1_RA1_I1_L0_BKG1(t)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD0
static Function MD0_RA1_I1_L0_BKG0([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings()
	AcquireData_NG(s, str)
End

static Function MD0_RA1_I1_L0_BKG0_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 5
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD0_RA1_I1_L0_BKG0(t)

	t.acquiredStimSets_HS0[0, 2] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[3]    = "StimulusSetB_DA_0"
	t.acquiredStimSets_HS0[4]    = "StimulusSetA_DA_0"
	t.sweepCount_HS0             = {0, 1, 2, 0, 0}
	t.setCycleCount_HS0          = 0
	t.stimsetCycleID_HS0[]       = {0, 0, 0, 1, 2}

	t.acquiredStimSets_HS1[0, 1] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[2, 4] = "StimulusSetD_DA_0"
	t.sweepCount_HS1             = {0, 1, 0, 1, 2}
	t.setCycleCount_HS1          = 0
	t.stimsetCycleID_HS1[]       = {0, 0, 1, 1, 1}

	AllTests(t, str)
End

static Function Events_MD1_RA1_I1_L1_BKG1(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo                               = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 3
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 4
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 5
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function MD1_RA1_I1_L1_BKG1([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings()
	AcquireData_NG(s, str)
End

static Function MD1_RA1_I1_L1_BKG1_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 6
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD1_RA1_I1_L1_BKG1(t)

	t.acquiredStimSets_HS0[0, 2] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[3, 5] = "StimulusSetB_DA_0"
	t.sweepCount_HS0             = {0, 1, 2, 0, 0, 0}
	t.setCycleCount_HS0          = {0, 0, 0, 0, 1, 2}
	t.stimsetCycleID_HS0[]       = {0, 0, 0, 1, 2, 3}

	t.acquiredStimSets_HS1[0, 2] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[3, 5] = "StimulusSetD_DA_0"
	t.sweepCount_HS1             = {0, 1, 0, 0, 1, 2}
	t.setCycleCount_HS1          = {0, 0, 1, 0, 0, 0}
	t.stimsetCycleID_HS1[]       = {0, 0, 1, 2, 2, 2}

	AllTests(t, str)
End

static Function Events_MD0_RA1_I1_L1_BKG0(t)
	STRUCT TestSettings &t

	Events_MD1_RA1_I1_L1_BKG1(t)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD0
static Function MD0_RA1_I1_L1_BKG0([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings()
	AcquireData_NG(s, str)
End

static Function MD0_RA1_I1_L1_BKG0_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 6
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD0_RA1_I1_L1_BKG0(t)

	t.acquiredStimSets_HS0[0, 2] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[3, 5] = "StimulusSetB_DA_0"
	t.sweepCount_HS0             = {0, 1, 2, 0, 0, 0}
	t.setCycleCount_HS0          = {0, 0, 0, 0, 1, 2}
	t.stimsetCycleID_HS0[]       = {0, 0, 0, 1, 2, 3}

	t.acquiredStimSets_HS1[0, 2] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[3, 5] = "StimulusSetD_DA_0"
	t.sweepCount_HS1             = {0, 1, 0, 0, 1, 2}
	t.setCycleCount_HS1          = {0, 0, 1, 0, 0, 0}
	t.stimsetCycleID_HS1[]       = {0, 0, 1, 2, 2, 2}

	AllTests(t, str)
End

static Function Events_RepeatSets_1(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo                               = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 3
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 4
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 5
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function RepeatSets_1([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings(overrideConfig = "MD1_RA1_I0_L0_BKG1_RES2")
	AcquireData_NG(s, str)
End

static Function RepeatSets_1_REENTRY([str])
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

static Function Events_RepeatSets_2(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo                               = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 3
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 4
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 5
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 6
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 7
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 8
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 9
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function RepeatSets_2([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings(overrideConfig = "MD1_RA1_I1_L0_BKG1_RES2")
	AcquireData_NG(s, str)
End

static Function RepeatSets_2_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 10
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_RepeatSets_2(t)

	t.acquiredStimSets_HS0[0, 2] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[3]    = "StimulusSetB_DA_0"
	t.acquiredStimSets_HS0[4, 6] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[7]    = "StimulusSetB_DA_0"
	t.acquiredStimSets_HS0[8, 9] = "StimulusSetA_DA_0"
	t.sweepCount_HS0             = {0, 1, 2, 0, 0, 1, 2, 0, 0, 1}
	t.setCycleCount_HS0          = 0
	t.stimsetCycleID_HS0[]       = {0, 0, 0, 1, 2, 2, 2, 3, 4, 4}

	t.acquiredStimSets_HS1[0, 1] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[2, 4] = "StimulusSetD_DA_0"
	t.acquiredStimSets_HS1[5, 6] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[7, 9] = "StimulusSetD_DA_0"
	t.sweepCount_HS1             = {0, 1, 0, 1, 2, 0, 1, 0, 1, 2}
	t.setCycleCount_HS1          = 0
	t.stimsetCycleID_HS1[]       = {0, 0, 1, 1, 1, 2, 2, 3, 3, 3}

	AllTests(t, str)
End

static Function Events_RepeatSets_3(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo                               = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 3
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 4
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 5
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 6
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 7
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 8
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 9
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 10
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 11
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function RepeatSets_3([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings(overrideConfig = "MD1_RA1_I1_L1_BKG1_RES2")
	AcquireData_NG(s, str)
End

static Function RepeatSets_3_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 12
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_RepeatSets_3(t)

	t.acquiredStimSets_HS0[0, 5]  = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[6, 11] = "StimulusSetB_DA_0"
	t.sweepCount_HS0              = {0, 1, 2, 0, 1, 2, 0, 0, 0, 0, 0, 0}
	t.setCycleCount_HS0           = {0, 0, 0, 1, 1, 1, 0, 1, 2, 3, 4, 5}
	t.stimsetCycleID_HS0[]        = {0, 0, 0, 1, 1, 1, 2, 3, 4, 5, 6, 7}

	t.acquiredStimSets_HS1[0, 5]  = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[6, 11] = "StimulusSetD_DA_0"
	t.sweepCount_HS1              = {0, 1, 0, 1, 0, 1, 0, 1, 2, 0, 1, 2}
	t.setCycleCount_HS1           = {0, 0, 1, 1, 2, 2, 0, 0, 0, 1, 1, 1}
	t.stimsetCycleID_HS1[]        = {0, 0, 1, 1, 2, 2, 3, 3, 3, 4, 4, 4}

	AllTests(t, str)
End

static Function Events_RepeatSets_4(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo                               = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 3
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 4
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 5
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 6
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 7
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 8
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 9
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 10
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 11
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo
End

static Function SwitchIndexingOrder_IGNORE(string device)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), str = "StimulusSetA_DA_0")
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Wave), str = "StimulusSetB_DA_0")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), str = "StimulusSetC_DA_0")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Wave), str = "StimulusSetD_DA_0")
End

static Function RepeatSets_4_PreAcq(string device)

	SwitchIndexingOrder_IGNORE(device)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function RepeatSets_4([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings(overrideConfig = "MD1_RA1_I1_L1_BKG1_RES2")
	AcquireData_NG(s, str)
End

static Function RepeatSets_4_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 12
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_RepeatSets_4(t)

	t.acquiredStimSets_HS0[0, 5]  = "StimulusSetB_DA_0"
	t.acquiredStimSets_HS0[6, 11] = "StimulusSetA_DA_0"
	t.sweepCount_HS0              = {0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 1, 2}
	t.setCycleCount_HS0           = {0, 1, 2, 3, 4, 5, 0, 0, 0, 1, 1, 1}
	t.stimsetCycleID_HS0          = {2, 3, 4, 5, 6, 7, 0, 0, 0, 1, 1, 1}

	t.acquiredStimSets_HS1[0, 5]  = "StimulusSetD_DA_0"
	t.acquiredStimSets_HS1[6, 11] = "StimulusSetC_DA_0"
	t.sweepCount_HS1              = {0, 1, 2, 0, 1, 2, 0, 1, 0, 1, 0, 1}
	t.setCycleCount_HS1           = {0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 2, 2}
	t.stimsetCycleID_HS1          = {3, 3, 3, 4, 4, 4, 0, 0, 1, 1, 2, 2}

	AllTests(t, str)
End

static Function Events_RepeatSets_5(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo                               = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 3
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 4
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 5
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 6
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 7
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 8
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 9
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo
End

static Function RepeatSets_5_PreAcq(string device)

	SwitchIndexingOrder_IGNORE(device)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function RepeatSets_5([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings(overrideConfig = "MD1_RA1_I1_L0_BKG1_RES2")
	AcquireData_NG(s, str)
End

static Function RepeatSets_5_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 10
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_RepeatSets_5(t)

	t.acquiredStimSets_HS0[0]    = "StimulusSetB_DA_0"
	t.acquiredStimSets_HS0[1, 3] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[4]    = "StimulusSetB_DA_0"
	t.acquiredStimSets_HS0[5, 7] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[8]    = "StimulusSetB_DA_0"
	t.acquiredStimSets_HS0[9]    = "StimulusSetA_DA_0"
	t.sweepCount_HS0             = {0, 0, 1, 2, 0, 0, 1, 2, 0, 0}
	t.setCycleCount_HS0          = 0
	t.stimsetCycleID_HS0[]       = {0, 1, 1, 1, 2, 3, 3, 3, 4, 5}

	t.acquiredStimSets_HS1[0, 2] = "StimulusSetD_DA_0"
	t.acquiredStimSets_HS1[3, 4] = "StimulusSetC_DA_0"
	t.acquiredStimSets_HS1[5, 7] = "StimulusSetD_DA_0"
	t.acquiredStimSets_HS1[8, 9] = "StimulusSetC_DA_0"
	t.sweepCount_HS1             = {0, 1, 2, 0, 1, 0, 1, 2, 0, 1}
	t.setCycleCount_HS1          = 0
	t.stimsetCycleID_HS1[]       = {0, 0, 0, 1, 1, 2, 2, 2, 3, 3}

	AllTests(t, str)
End

static Function RepeatSets_6_PreAcq(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Wave), str = "StimulusSetA_DA_0")
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), str = "StimulusSetB_DA_0")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Wave), str = "StimulusSetE_DA_0")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_Index_End), str = "StimulusSetF_DA_0")

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "")
	ST_SetStimsetParameter("StimulusSetB_DA_0", "Analysis function (generic)", str = "")
	ST_SetStimsetParameter("StimulusSetE_DA_0", "Analysis function (generic)", str = "")
	ST_SetStimsetParameter("StimulusSetF_DA_0", "Analysis function (generic)", str = "")
End

// test that locked indexing works when the maximum number of sweeps is
// not in the first stimset
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function RepeatSets_6([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings(overrideConfig = "MD1_RA1_I1_L1_BKG1_RES1")
	AcquireData_NG(s, str)
End

static Function RepeatSets_6_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 7
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)

	t.acquiredStimSets_HS0[0, 2] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[3, 6] = "StimulusSetB_DA_0"
	t.sweepCount_HS0             = {0, 1, 2, 0, 0, 0, 0}
	t.setCycleCount_HS0          = {0, 0, 0, 0, 1, 2, 3}
	t.stimsetCycleID_HS0[]       = {0, 0, 0, 1, 2, 3, 4}

	t.acquiredStimSets_HS1[0, 2] = "StimulusSetE_DA_0"
	t.acquiredStimSets_HS1[3, 6] = "StimulusSetF_DA_0"
	t.sweepCount_HS1             = {0, 1, 0, 0, 1, 2, 3}
	t.setCycleCount_HS1          = {0, 0, 1, 0, 0, 0, 0}
	t.stimsetCycleID_HS1[]       = {0, 0, 1, 2, 2, 2, 2}

	AllTests(t, str)
End

static Function CheckIZeroClampMode_PreAcq(device)
	string device

	PGC_SetAndActivateControl(device, "Radio_ClampMode_1IZ", val = 1)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckIZeroClampMode([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings(overrideConfig = "MD1_RA0_I0_L0_BKG1_RES1")
	AcquireData_NG(s, str)
End

static Function CheckIZeroClampMode_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 1
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)
	Events_MD1_RA0_I0_L0_BKG1(t)

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

	WAVE clampMode = GetLastSetting(numericalValues, 0, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {I_EQUAL_ZERO_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

static Function Events_RepeatSets_7(t)
	STRUCT TestSettings &t

	variable sweepNo

	Events_Common(t)

	sweepNo                               = 0
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN

	sweepNo                               = 1
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = NaN

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS1[sweepNo][POST_SET_EVENT] = sweepNo

	sweepNo                               = 2
	t.events_HS0[sweepNo][PRE_SET_EVENT]  = NaN
	t.events_HS0[sweepNo][POST_SET_EVENT] = sweepNo

	t.events_HS1[sweepNo][PRE_SET_EVENT]  = sweepNo
	t.events_HS1[sweepNo][POST_SET_EVENT] = NaN
End

// test that all events are fired, even with TP during ITI
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function RepeatSets_7([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings(overrideConfig = "MD1_RA1_I0_L0_BKG1_RES1_ITI3_TPI1")
	AcquireData_NG(s, str)
End

static Function RepeatSets_7_REENTRY([str])
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

static Function RepeatSets_8_PreAcq(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), str = NONE)

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "")
	ST_SetStimsetParameter("StimulusSetB_DA_0", "Analysis function (generic)", str = "")
End

// Locked Indexing with TP during DAQ
//
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function RepeatSets_8([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings(overrideConfig = "MD1_RA1_I1_L1_BKG1_RES1")
	AcquireData_NG(s, str)
End

static Function RepeatSets_8_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 4
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)

	t.acquiredStimSets_HS0[0, 2] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[3]    = "StimulusSetB_DA_0"
	t.sweepCount_HS0             = {0, 1, 2, 0}
	t.setCycleCount_HS0          = {0, 0, 0, 0}
	t.stimsetCycleID_HS0[]       = {0, 0, 0, 1}

	t.acquiredStimSets_HS1 = "TestPulse"
	t.sweepCount_HS1       = {0, 0, 0, 0}
	t.setCycleCount_HS1    = {NaN, NaN, NaN, NaN}
	WAVEClear t.stimsetCycleID_HS1

	t.DAQChannelTypeDA = {DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN}
	t.DAQChannelTypeAD = {DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN}

	AllTests(t, str)
End

static Function RepeatSets_9_PreAcq(device)
	string device

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "TestPulse")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), str = NONE)

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "")
	ST_SetStimsetParameter("StimulusSetB_DA_0", "Analysis function (generic)", str = "")
End

// Unlocked Indexing with TP during DAQ
//
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function RepeatSets_9([str])
	string str

	[STRUCT DAQSettings s] = GetDAQSettings(overrideConfig = "MD1_RA1_I1_L0_BKG1_RES1")
	AcquireData_NG(s, str)
End

static Function RepeatSets_9_REENTRY([str])
	string str

	STRUCT TestSettings t

	t.numSweeps     = 4
	t.sweepWaveType = FLOAT_WAVE

	InitTestStructure(t)

	t.acquiredStimSets_HS0[0, 2] = "StimulusSetA_DA_0"
	t.acquiredStimSets_HS0[3]    = "StimulusSetB_DA_0"
	t.sweepCount_HS0             = {0, 1, 2, 0}
	t.setCycleCount_HS0          = {0, 0, 0, 0}
	t.stimsetCycleID_HS0[]       = {0, 0, 0, 1}

	t.acquiredStimSets_HS1 = "TestPulse"
	t.sweepCount_HS1       = {0, 0, 0, 0}
	t.setCycleCount_HS1    = {NaN, NaN, NaN, NaN}
	WAVEClear t.stimsetCycleID_HS1

	t.DAQChannelTypeDA = {DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN}
	t.DAQChannelTypeAD = {DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_TP, NaN, NaN, NaN, NaN, NaN, NaN, NaN}

	AllTests(t, str)
End
