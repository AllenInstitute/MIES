#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=Epochs

// Check the root datafolder for waves which might be present and could help debugging

static Constant OODDAQ_PRECISION       = 0.001
static Constant OTHER_EPOCHS_PRECISION = 0.050
static Constant MAX_ITERATIONS = 100000

/// @brief Acquire data with the given DAQSettings on two headstages
static Function AcquireData(s, devices, stimSetName1, stimSetName2[, dDAQ, oodDAQ, onsetDelayUser, terminationDelay])
	STRUCT DAQSettings& s
	string devices
	string stimSetName1, stimSetName2
	variable dDAQ, oodDAQ, onsetDelayUser, terminationDelay

	string unlockedPanelTitle, device
	variable i, numEntries

	dDAQ = ParamIsDefault(dDAQ) ? 0 : !!dDAQ
	oodDAQ = ParamIsDefault(oodDAQ) ? 0 : !!oodDAQ

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = stringFromList(i, devices)

		unlockedPanelTitle = DAP_CreateDAEphysPanel()

		PGC_SetAndActivateControl(unlockedPanelTitle, "popup_MoreSettings_Devices", str=device)
		PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")

		REQUIRE(WindowExists(device))

		PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1, switchTab = 1)
		PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)

		PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = stimSetName1)
		PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = stimSetName2)

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

		PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = dDAQ)
		PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = oodDAQ)

		PGC_SetAndActivateControl(device, "setvar_DataAcq_OnsetDelayUser", val = onsetDelayUser)
		PGC_SetAndActivateControl(device, "setvar_DataAcq_TerminationDelay", val = terminationDelay)

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

	PGC_SetAndActivateControl(device, "DataAcquireButton")
End

/// @brief Tests if the 2D text wave e is tightly packed each row in all cols from top
static Function TestEpochChannelTight(e)
	WAVE/T e

	variable i,j, numCols, numRows, emptyFlag
	string s

	numRows = DimSize(e, ROWS)
	numCols = DimSize(e, COLS)
	CHECK(numRows > 0)
	CHECK(numCols > 0)
	for(i = 0; i < numRows; i += 1)
		for(j = 0; j < numCols; j += 1)
			s = e[i][j]
			if(isEmpty(s) && !emptyFlag)
				// col 0 must be first empty
				CHECK_EQUAL_VAR(j, 0)
				emptyFlag = 1
			elseif(emptyFlag)
				// all remaining entries must be empty
				CHECK_EMPTY_STR(s)
			endif
		endfor
	endfor
End

static Function [WAVE startT, WAVE endT, WAVE levels, WAVE/T description] RemoveOodDAQEntries(WAVE startT_all, WAVE endT_all, WAVE isOodDAQ_all, WAVE levels_all, WAVE/T description_all)

	Duplicate/FREE startT_all, startT_sub
	Duplicate/FREE endT_all, endT_sub
	Duplicate/FREE levels_all, levels_sub
	Duplicate/FREE/T description_all, description_sub

	startT_sub[] = isOodDAQ_all[p] ? NaN : startT_all[p]
	endT_sub[] = isOodDAQ_all[p] ? NaN : endT_all[p]
	levels_sub[] = isOodDAQ_all[p] ? NaN : levels_all[p]
	description_sub[] = SelectString(isOodDAQ_all[p], description_sub[p], "")

	WAVE/Z startT = ZapNaNs(startT_sub)
	CHECK_WAVE(startT, NUMERIC_WAVE)

	WAVE/Z endT = ZapNaNs(endT_sub)
	CHECK_WAVE(endT, NUMERIC_WAVE)

	WAVE/Z levels = ZapNans(levels_sub)
	CHECK_WAVE(levels, NUMERIC_WAVE)

	WAVE/Z indizes = FindIndizes(description_sub, col = 0, prop = PROP_NON_EMPTY)
	if(WaveExists(indizes))
		Make/N=(DimSize(indizes, ROWS))/T/FREE description = description_sub[indizes[p]]
	endif

	return [startT, endT, levels, description]
End

static Function CheckFaithfullCoverage(WAVE startT_all, WAVE endT_all, WAVE matches, variable refEpoch)

	variable refStart, refEnd, numMatches, smallestStart, highestEnd
	variable rangeStart, rangeEnd, idx, i

	refStart = startT_all[refEpoch]
	refEnd = endT_all[refEpoch]

	numMatches = DimSize(matches, ROWS)
	Make/FREE/D/N=(numMatches) outside
	Make/FREE/D/N=(numMatches) startT = startT_all[matches[p]]
	Make/FREE/D/N=(numMatches) endT = endT_all[matches[p]]

	// check if we don't overlap with anything at all
	outside[] = (endT[p] <= refStart || startT[p] >= refEnd) && (startT[p] < endT[p])

	if(Sum(outside) == numMatches)
		// completely outside, they are allowed to touch though
		return 1
	endif

	rangeStart = refStart

	for(;i < MAX_ITERATIONS;)
		idx = GetRowIndex(startT, val = rangeStart)
		if(IsNaN(idx))
			// broken chain
			Duplicate/O outside, root:outside
			Duplicate/O startT, root:startT
			Duplicate/O endT, root:endT
			Debugger
			return 0
		endif

		rangeEnd = endT[idx]
		if(rangeEnd == refEnd)
			// done, full coverage
			return 2
		endif

		rangeStart = rangeEnd
	endfor

	FAIL()
End

static Function TestEpochOverlap(WAVE startT_all, WAVE endT_all, WAVE isOodDAQ_all, WAVE levels_all, WAVE/T description_all)
	variable i, level, epochCnt, ret, refStart, refEnd

	WAVE/Z startT, endT, levels
	WAVE/T/Z description
	[startT, endT, levels, description] = RemoveOodDAQEntries(startT_all, endT_all, isOodDAQ_all, levels_all, description_all)

	CHECK_EQUAL_WAVES(startT, endT, mode = DIMENSION_SIZES)
	CHECK_EQUAL_WAVES(startT, levels, mode = DIMENSION_SIZES)
	// workaround UTF issue: https://github.com/byte-physics/igor-unit-testing-framework/issues/199
	CHECK_EQUAL_VAR(DimSize(startT, ROWS), DimSize(description, ROWS))

	epochCnt = DimSize(levels, ROWS)

	for(i = 0; i < epochCnt; i += 1)
		level = levels[i]

		// find all epochs which have level + 1
		WAVE/Z matches = FindIndizes(levels, col = 0, var = level + 1)

		if(!WaveExists(matches))
			continue
		endif

		// find a number of epochs larger than zero from "matches" which completely cover the current epoch
		// without gaps and without overlap or only touch it at the borders
		ret = CheckFaithfullCoverage(startT, endT, matches, i)

		CHECK(ret == 1 || ret == 2)
		if(!ret)
			printf "Could not find coverage epochs for %g (desc: %s, level %d)\r", i, description[i], level
			print matches
			return 1
		endif
	endfor

	// check also that we don't have overlap in the same level
	Make/FREE/N=(epochCnt) disjunct, sameLevel
	for(i = 0; i < epochCnt; i += 1)
		level = levels[i]
		refStart = startT[i]
		refEnd   = endT[i]

		sameLevel[] = (level == levels[p])
		disjunct[]  = sameLevel[p] && ((startT[p] <= refStart && endT[p] <= refStart) || (startT[p] >= refEnd && endT[p] >= refEnd))

		// ignore current epoch
		sameLevel[i] = NaN
		disjunct[i]  = NaN

		CHECK_EQUAL_WAVES(sameLevel, disjunct)
	endfor

	return 0
End

static Function TestEpochsMonotony(e, DAChannel, activeDAChannel)
	WAVE/T e
	WAVE DAChannel
	variable activeDAChannel

	variable i, j, epochCnt, rowCnt, beginInt, endInt, epochNr, amplitude, center, DAAmp
	variable first, last, level, range, ret
	string s, name

	rowCnt = DimSize(e, ROWS)

	for(epochCnt = 0; epochCnt < rowCnt; epochCnt += 1)
		s = e[epochCnt][0]
		if(isEmpty(s))
			break
		endif
	endfor
	REQUIRE(epochCnt > 0)

	Make/FREE/D/N=(epochCnt) startT, endT, levels, isOodDAQ
	startT[] = str2num(e[p][0])
	endT[] = str2num(e[p][1])
	CHECK(WaveMin(startT) >= 0)
	CHECK(WaveMin(endT) >= 0)
	isOodDAQ[] = strsearch(e[p][2], EPOCH_OODDAQ_REGION_KEY, 0) != -1
	levels[] = str2num(e[p][3])
	CHECK_EQUAL_VAR(WaveMin(startT), 0)

	Make/T/N=(epochCnt)/FREE description = e[p][2]

	// check that start times are monotonously increasing
	if(epochCnt > 1)
		for(i = 1; i < epochCnt; i += 1)
			CHECK(startT[i - 1] <= startT[i])
		endfor
	endif

	// check for valid level
	for(i = 0; i < epochCnt; i += 1)
		CHECK(IsInteger(levels[i]) && levels[i] >= 0)
	endfor

	// check that a subset of epochs in level x fully cover exactly one epoch in level x - 1
	ret = TestEpochOverlap(startT, endT, isOodDAQ, levels, description)

	if(ret != 0)
		printf "ActiveDAC: %d\r", activeDAChannel
		Duplicate/O e, root:epochs
	endif

	for(i = 0; i < epochCnt; i += 1)
		name  = e[i][2]
		level = str2num(e[i][3])
		first = startT[i] * 1000 + OTHER_EPOCHS_PRECISION
		last  = endT[i] * 1000 - OTHER_EPOCHS_PRECISION
		range = last - first

		if(range <= 0)
			PASS()
			continue
		endif

		// check amplitudes
		if(strsearch(name, "Amplitude", 0) > 0)

			amplitude = NumberByKey("Amplitude", name, "=")
			CHECK(IsFinite(amplitude))

			WaveStats/R=(first, last)/Q/M=1 DAChannel
			CHECK_EQUAL_VAR(V_max, amplitude)

			// check that the level 3 pulse epoch is really only the pulse
			if(level == 3)
				WaveStats/R=(first, last)/Q/M=1 DAChannel
				CHECK_EQUAL_VAR(V_min, amplitude)
			endif
		endif

		// check baseline
		if(strsearch(name, "Baseline", 0) > 0)
			WaveStats/R=(first, last)/Q/M=1 DAChannel
			CHECK_EQUAL_VAR(V_min, 0)

			// take something around the egdes due to decimation
			// offsets are in ms
			WaveStats/R=(first, last)/Q/M=1 DAChannel
			CHECK_EQUAL_VAR(V_max, 0)
		endif
	endfor
End

static Function TestEpochsGeneric(device)
	string device

	variable numEntries, endTimeDAC, endTimeEpochs, samplingInterval
	variable i
	string list

	string sweeps, configs
	variable sweepNo

	Make/FREE/N=(NUM_DA_TTL_CHANNELS) chanMarker

	// retrieve generic information
	sweeps  = GetListOfObjects(GetDeviceDataPath(device), DATA_SWEEP_REGEXP, fullPath = 1)
	configs = GetListOfObjects(GetDeviceDataPath(device), DATA_CONFIG_REGEXP, fullPath = 1)

	CHECK_EQUAL_VAR(ItemsInList(sweeps), 1)
	CHECK_EQUAL_VAR(ItemsInList(configs), 1)
	WAVE/Z sweep  = $StringFromList(0, sweeps)
	CHECK_WAVE(sweep, NUMERIC_WAVE, minorType = FLOAT_WAVE)
	sweepNo = ExtractSweepNumber(NameOfWave(sweep))
	CHECK(sweepNo >= 0)

	WAVE/Z config = $StringFromList(0, configs)
	CHECK_WAVE(config, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(config, ROWS), DimSize(sweep, COLS))
	CHECK_EQUAL_VAR(DimSize(config, ROWS), 4)
	WAVE DACs = GetDACListFromConfig(config)
	CHECK_EQUAL_WAVES(DACs, {0, 1}, mode = WAVE_DATA)

	WAVE/T textualValues   = GetLBTextualValues(device)
	WAVE   numericalValues = GetLBNumericalValues(device)

	// basic check of internal epoch wave
	WAVE/T epochs = GetEpochsWave(device)
	CHECK_EQUAL_VAR(DimSize(epochs, COLS), 4)
	CHECK_EQUAL_VAR(DimSize(epochs, LAYERS), NUM_DA_TTL_CHANNELS)
	numEntries = DimSize(DACs, ROWS)
	CHECK_EQUAL_VAR(numEntries, 2)
	for(i = 0; i < numEntries; i += 1)
		Duplicate/FREE/T/RMD=[][][DACs[i]] epochs, epochChannel
		Redimension/N=(-1, -1, 0) epochChannel
		TestEpochChannelTight(epochChannel)
		chanMarker[i] = 1
	endfor
	// all other channels must have empty epochs list
	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		if(!chanMarker[i])
			Duplicate/FREE/T/RMD=[][][i] epochs, epochChannel
			Redimension/N=(-1, -1, 0) epochChannel
			Duplicate/T/FREE epochChannel, refChannel
			refChannel = ""
			CHECK_EQUAL_WAVES(epochChannel, refChannel)
		endif
	endfor

	// further checks of data from LabNotebook Entries
	WAVE/Z samplInt = GetLastSetting(numericalValues, sweepNo, "Sampling interval", DATA_ACQUISITION_MODE)
	samplingInterval = samplInt[INDEP_HEADSTAGE] * 1000
	endTimeDAC = samplingInterval * DimSize(sweep, ROWS) / 1E6

	WAVE/T epochLBEntries = GetLastSetting(textualValues, sweepNo, EPOCHS_ENTRY_KEY, DATA_ACQUISITION_MODE)

	for(i = 0; i < numEntries; i += 1)
		WAVE/T epochChannel = ListToTextWaveMD(epochLBEntries[i], 2, rowSep = ":", colSep = ",")
		Make/FREE/D/N=(DimSize(epochChannel, ROWS)) endT

		// does the latest end time exceed the 'acquiring part of the' DA wave?
		endT[] = str2num(epochChannel[p][1])
		// allow epochEnd to exceed range by less than one sample point
		endTimeEpochs = trunc(WaveMax(endT) / samplingInterval) * samplingInterval
		CHECK(endTimeEpochs <= endTimeDAC)
		Duplicate/FREE/RMD=[][i] sweep, DAchannel
		Redimension/N=(-1, 0) DAchannel

		TestEpochsMonotony(epochChannel, DAchannel, i)
	endfor

End

/// <------------- TESTS FOLLOW HERE ---------------------->

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function EP_EpochTest1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, "EpochTest0_DA_0", "EpochTest0_DA_0")
End

Function EP_EpochTest1_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function EP_EpochTest2([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, "EpochTest1_DA_0", "EpochTest1_DA_0")
End

Function EP_EpochTest2_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function EP_EpochTest3([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, "EpochTest2_DA_0", "EpochTest2_DA_0")
End

Function EP_EpochTest3_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function EP_EpochTest4([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, "EpochTest2_DA_0", "EpochTest2_DA_0", dDAQ = 1)
End

Function EP_EpochTest4_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function EP_EpochTest5([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, "EpochTest2_DA_0", "EpochTest2_DA_0", oodDAQ = 1)
End

Function EP_EpochTest5_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function EP_EpochTest6([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, "EpochTest2_DA_0", "EpochTest3_DA_0", oodDAQ = 1)
End

Function EP_EpochTest6_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function EP_EpochTest7([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, "EpochTest4_DA_0", "EpochTest4_DA_0", oodDAQ = 1)
End

Function EP_EpochTest7_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
Function EP_EpochTest8([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1_RES_1")
	AcquireData(s, str, "EpochTest5_DA_0", "EpochTest5_DA_0", onsetDelayUser = 50, terminationDelay = 100)
End

Function EP_EpochTest8_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End
