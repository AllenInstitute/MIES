#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=Epochs

// Check the root datafolder for waves which might be present and could help debugging

static Constant OODDAQ_PRECISION       = 0.001
static Constant OTHER_EPOCHS_PRECISION = 0.050
static Constant MAX_ITERATIONS = 100000

static Function GlobalPreAcq(string device)

	PASS()
End

static Function GlobalPreInit(string device)

	PASS()
End

/// @brief Tests if the 2D text wave e is tightly packed each row in all cols from top
static Function TestEpochChannelTight(e)
	WAVE/T e

	variable i,j, numCols, numRows, emptyFlag
	string s

	numRows = DimSize(e, ROWS)
	numCols = DimSize(e, COLS)
	CHECK_GT_VAR(numRows, 0)
	CHECK_GT_VAR(numCols, 0)
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

	WAVE/Z indizes = FindIndizes(description_sub, prop = PROP_NON_EMPTY)
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
	CHECK_EQUAL_WAVES(startT, description, mode = DIMENSION_SIZES)

	epochCnt = DimSize(levels, ROWS)

	for(i = 0; i < epochCnt; i += 1)
		level = levels[i]

		// find all epochs which have level + 1
		WAVE/Z matches = FindIndizes(levels, var = level + 1)

		if(!WaveExists(matches))
			continue
		endif

		// find a number of epochs larger than zero from "matches" which completely cover the current epoch
		// without gaps and without overlap or only touch it at the borders
		ret = CheckFaithfullCoverage(startT, endT, matches, i)

		CHECK_GE_VAR(ret, 1)
		CHECK_LE_VAR(ret, 2)
		if(!ret)
			printf "Could not find coverage epochs for %g (desc: %s, level %d)\r", i, description[i], level
			print matches
			return NaN
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
	REQUIRE_GT_VAR(epochCnt, 0)

	Make/FREE/D/N=(epochCnt) startT, endT, levels, isOodDAQ
	startT[] = str2num(e[p][0])
	endT[] = str2num(e[p][1])
	CHECK_GE_VAR(WaveMin(startT), 0)
	CHECK_GE_VAR(WaveMin(endT), 0)
	isOodDAQ[] = strsearch(e[p][2], EPOCH_OODDAQ_REGION_KEY, 0) != -1
	levels[] = str2num(e[p][3])
	CHECK_EQUAL_VAR(WaveMin(startT), 0)

	Make/T/N=(epochCnt)/FREE description = e[p][2]

	// check that start times are monotonously increasing
	if(epochCnt > 1)
		for(i = 1; i < epochCnt; i += 1)
			CHECK_LE_VAR(startT[i - 1], startT[i])
		endfor
	endif

	// check for valid level
	for(i = 0; i < epochCnt; i += 1)
		CHECK(IsInteger(levels[i]))
		if(levels[i] != EPOCH_USER_LEVEL)
			CHECK_GE_VAR(levels[i], 0)
		endif
	endfor

	// check that a subset of epochs in level x fully cover exactly one epoch in level x - 1
	TestEpochOverlap(startT, endT, isOodDAQ, levels, description)

	// check that we don't have any gaps in treelevel 0
	TestEpochGaps(startT, endT, isOodDAQ, levels, DAChannel, 0)

	for(i = 0; i < epochCnt; i += 1)
		name  = e[i][2]
		level = str2num(e[i][3])
		first = startT[i] * ONE_TO_MILLI + OTHER_EPOCHS_PRECISION
		last  = endT[i] * ONE_TO_MILLI - OTHER_EPOCHS_PRECISION
		range = last - first

		if(range <= 0)
			PASS()
			continue
		endif

		// check amplitudes
		if(strsearch(name, "SubType=Pulse", 0) > 0)

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
			CHECK_EQUAL_VAR(V_max, 0)
		endif
	endfor
End

static Function TestEpochGaps(WAVE startTall, WAVE endTall, WAVE isOodDAQ, WAVE levels, WAVE DAChannel, variable level)

	variable epochCnt, i, lastx

	Extract/FREE startTall, startT, isOodDAQ == 0 && levels == level
	Extract/FREE endTall, endT, isOodDAQ == 0 && levels == level
	CHECK_EQUAL_WAVES(startT, endT, mode = DIMENSION_SIZES)

	lastx = IndexToScale(DAchannel, DimSize(DAchannel, ROWS) - 1, ROWS) * MILLI_TO_ONE
	CHECK_GT_VAR(lastx, 0.0)

	epochCnt = DimSize(startT, ROWS)
	for(i = 0; i < epochCnt; i += 1)

		// first starts at 0.0
		if(i == 0)
			CHECK_EQUAL_VAR(startT[i], 0.0)
		endif

		// last has the x-coordinate as the last point in the DA wave
		if(i == epochCnt - 1)
			CHECK_CLOSE_VAR(lastx, endT[i], tol = 1e-10)
		endif

		// and in between no gaps
		if(i > 0)
			CHECK_EQUAL_VAR(startT[i], endT[i - 1])
		endif
	endfor
End

static Function TestEpochsGeneric(device)
	string device

	variable numEntries, endTimeDAC, endTimeEpochs, samplingInterval
	variable i, lastPoint
	string list, epochStr

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
	CHECK_GE_VAR(sweepNo, 0)

	WAVE/Z config = $StringFromList(0, configs)
	CHECK_WAVE(config, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(config, ROWS), DimSize(sweep, COLS))
	WAVE DACs = GetDACListFromConfig(config)
	CHECK_GT_VAR(DimSize(DACs, ROWS), 0)

	WAVE/T textualValues   = GetLBTextualValues(device)
	WAVE   numericalValues = GetLBNumericalValues(device)

	// basic check of internal epoch wave
	WAVE/T epochs = GetEpochsWave(device)
	CHECK_EQUAL_VAR(DimSize(epochs, COLS), 4)
	CHECK_EQUAL_VAR(DimSize(epochs, LAYERS), NUM_DA_TTL_CHANNELS)
	numEntries = DimSize(DACs, ROWS)
	CHECK_GT_VAR(numEntries, 0)
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
	CHECK_WAVE(samplInt, NUMERIC_WAVE)
	samplingInterval = samplInt[INDEP_HEADSTAGE] * MICRO_TO_MILLI

	lastPoint = DimSize(sweep, ROWS)
	endTimeDAC = samplingInterval * lastPoint

	WAVE/T epochLBEntries = GetLastSetting(textualValues, sweepNo, EPOCHS_ENTRY_KEY, DATA_ACQUISITION_MODE)
	WAVE/T setNameLBEntries = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)

	for(i = 0; i < numEntries; i += 1)
		epochStr = epochLBEntries[i]
		if(WB_StimsetIsFromThirdParty(setNameLBEntries[i]) || !cmpstr(setNameLBEntries[i], STIMSET_TP_WHILE_DAQ))
			CHECK_EMPTY_STR(epochStr)
			continue
		endif

		WAVE/T epochChannel = EP_EpochStrToWave(epochStr)
		Make/FREE/D/N=(DimSize(epochChannel, ROWS)) endT

		// preserve epochs wave in CDF
		Duplicate epochChannel, $("epochChannel" + num2str(i))

		// does the latest end time exceed the 'acquiring part of the' DA wave?
		endT[] = str2num(epochChannel[p][1])
		endTimeEpochs = WaveMax(endT)
		// allow endTimeEpochs to exceed range by less than one sample point
		CHECK_LE_VAR(endTimeEpochs, endTimeDAC + samplingInterval)
		Duplicate/FREE/RMD=[][i] sweep, DAchannel
		Redimension/N=(-1, 0) DAchannel

		TestEpochsMonotony(epochChannel, DAchannel, i)

		TestUnacquiredEpoch(sweep, epochChannel)

		TestNaming(epochChannel)

		TestTrigonometricEpochs(sweep, epochChannel, DAChannel)
	endfor
End

static Function TestUnacquiredEpoch(WAVE sweep, WAVE epochChannel)

	FindValue/FNAN sweep

	if(V_row == -1)
		return NaN
	endif

	FindValue/TEXT="Type=Unacquired" epochChannel
	CHECK_GE_VAR(V_row, 0)
	CHECK_EQUAL_VAR(V_col, 2)
End

static Function TestNaming(WAVE/T epochChannel)

	variable numRows, numEntries, i, j
	string tags, entry

	numRows = DimSize(epochChannel, ROWS)
	for(i = 0; i < numRows; i += 1)
		tags = epochChannel[i][EPOCH_COL_TAGS]

		numEntries = ItemsInList(tags, ";")
		CHECK_GT_VAR(numEntries, 0)
		for(j = 0; j < numEntries; j += 1)
			entry = StringFromList(j, tags)
			CHECK_GT_VAR(strsearch(entry, "=", 0), 0)
		endfor
	endfor

	// check that shortnames are unique
	Make/FREE/T/N=(numRows) shortnames = EP_GetShortName(epochChannel[p][EPOCH_COL_TAGS])
	CHECK(HasOneValidEntry(shortnames))

	Sort shortnames, shortnames
	WAVE/Z uniqueShortNames = GetUniqueEntries(shortnames)
	CHECK_EQUAL_WAVES(shortnames, uniqueShortNames)
End

static Function TestTrigonometricEpochs(WAVE sweep, WAVE/T epochChannel, WAVE DAchannel)
	variable numRows, i, num, epochBegin, epochEnd
	string shortname, epochType, levelTwoType, levelTwoNumber, levelThreeType, levelThreeNumber, refEpochType

	numRows = DimSize(epochChannel, ROWS)

	Make/FREE/T/N=(numRows) shortnames = EP_GetShortName(epochChannel[p][EPOCH_COL_TAGS])

	refEpochType = "TG"

	for(i = 0; i < numRows; i += 1)
		shortname = shortnames[i]

		SplitString/E="(?i)E[[:digit:]]+_([a-z]+)(_I|_C)([[:digit:]]+)(_H)?([[:digit:]]+)?" shortname, epochType, levelTwoType, levelTwoNumber, levelThreeType, levelThreeNumber

		if(V_Flag < 2)
			CHECK_NEQ_STR(epochType, refEpochType)
			continue
		endif

		CHECK_EQUAL_STR(epochType, refEpochType)

		if(!cmpstr(levelTwoType, "_C") && !cmpstr(levelThreeType, "_H"))
			num = str2num(levelThreeNumber)
			CHECK(IsInteger(num))
			CHECK_GE_VAR(num, 0)
			CHECK_LE_VAR(num, 1)
		elseif(!cmpstr(levelTwoType, "_C"))
			num = str2num(levelTwoNumber)
			CHECK(IsInteger(num))
			CHECK_GE_VAR(num, 0)

			FindValue/TEXT=(shortname + "_H0") shortnames
			CHECK_GE_VAR(V_Value, 0)

			FindValue/TEXT=(shortname + "_H1") shortnames
			CHECK_GE_VAR(V_Value, 0)
		elseif(!cmpstr(levelTwoType, "_I"))
			num = str2num(levelTwoNumber)
			CHECK_GE_VAR(num, 0)
			CHECK_LE_VAR(num, 1)
			continue
		else
			FAIL()
		endif

		// check amplitude at begin/end
		epochBegin = str2num(epochChannel[i][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI
		epochEnd = str2num(epochChannel[i][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI

		Duplicate/FREE/R=(epochBegin - OTHER_EPOCHS_PRECISION / 2, epochBegin + OTHER_EPOCHS_PRECISION / 2) DAchannel, slice
		if(GetRowIndex(slice, val = 0) == 0)
			// one of the points was zero
			PASS()
		else
			// if not we need at least a zero crossing
			FindLevel/Q slice, 0
			CHECK_EQUAL_VAR(V_flag, 0)
		endif

		Duplicate/FREE/R=(epochEnd - OTHER_EPOCHS_PRECISION / 2, epochEnd + OTHER_EPOCHS_PRECISION / 2) DAchannel, slice
		if(GetRowIndex(slice, val = 0) == 0)
			// one of the points was zero
			PASS()
		else
			// if not we need at least a zero crossing
			FindLevel/Q slice, 0
			CHECK_EQUAL_VAR(V_flag, 0)
		endif
	endfor
End

/// <------------- TESTS FOLLOW HERE ---------------------->

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_EpochTest1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                      + \
								 "__HS0_DA0_AD0_CM:VC:_ST:EpochTest0_DA_0:" + \
								 "__HS1_DA1_AD1_CM:VC:_ST:EpochTest0_DA_0:")

	AcquireData_NG(s, str)
End

static Function EP_EpochTest1_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_EpochTest2([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                      + \
								 "__HS0_DA0_AD0_CM:VC:_ST:EpochTest1_DA_0:" + \
								 "__HS1_DA1_AD1_CM:VC:_ST:EpochTest1_DA_0:")

	AcquireData_NG(s, str)
End

static Function EP_EpochTest2_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_EpochTest3([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                      + \
								 "__HS0_DA0_AD0_CM:VC:_ST:EpochTest2_DA_0:" + \
								 "__HS1_DA1_AD1_CM:VC:_ST:EpochTest2_DA_0:")

	AcquireData_NG(s, str)
End

static Function EP_EpochTest3_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_EpochTest4([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_dDAQ1"                + \
								 "__HS0_DA0_AD0_CM:VC:_ST:EpochTest2_DA_0:" + \
								 "__HS1_DA1_AD1_CM:VC:_ST:EpochTest2_DA_0:")

	AcquireData_NG(s, str)
End

static Function EP_EpochTest4_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_EpochTest4a([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_dDAQ1_DDL10"      + \
								 "__HS0_DA0_AD0_CM:VC:_ST:EpochTest2_DA_0:" + \
								 "__HS1_DA1_AD1_CM:VC:_ST:EpochTest2_DA_0:")

	AcquireData_NG(s, str)
End

static Function EP_EpochTest4a_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_EpochTest5([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_oodDAQ1"              + \
								 "__HS0_DA0_AD0_CM:VC:_ST:EpochTest2_DA_0:" + \
								 "__HS1_DA1_AD1_CM:VC:_ST:EpochTest2_DA_0:")

	AcquireData_NG(s, str)
End

static Function EP_EpochTest5_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_EpochTest6([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_oodDAQ1"              + \
								 "__HS0_DA0_AD0_CM:VC:_ST:EpochTest2_DA_0:" + \
								 "__HS1_DA1_AD1_CM:VC:_ST:EpochTest3_DA_0:")

	AcquireData_NG(s, str)
End

static Function EP_EpochTest6_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_EpochTest7([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_oodDAQ1"              + \
								 "__HS0_DA0_AD0_CM:VC:_ST:EpochTest4_DA_0:" + \
								 "__HS1_DA1_AD1_CM:VC:_ST:EpochTest4_DA_0:")

	AcquireData_NG(s, str)
End

static Function EP_EpochTest7_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_EpochTest8([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_OD50_TD100"            + \
								 "__HS0_DA0_AD0_CM:VC:_ST:EpochTest5_DA_0:" + \
								 "__HS1_DA1_AD1_CM:VC:_ST:EpochTest5_DA_0:")

	AcquireData_NG(s, str)
End

static Function EP_EpochTest8_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_EpochTest9([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_OD50_TD100"           + \
								 "__HS0_DA0_AD0_CM:VC:_ST:EpochTest6_DA_0:" + \
								 "__HS1_DA1_AD1_CM:VC:_ST:EpochTest6_DA_0:")

	AcquireData_NG(s, str)
End

static Function EP_EpochTest9_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_EpochTest10([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L1_BKG1"                         + \
								 "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
								 "__HS1_DA1_AD1_CM:VC:_ST:TestPulse:")

	AcquireData_NG(s, str)
End

static Function EP_EpochTest10_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

static Function EP_EpochTest11_preInit(string device)

	WB_MakeStimsetThirdParty("StimulusSetB_DA_0")
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_EpochTest11([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L1_BKG1"                        + \
								 "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
								 "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetB_DA_0:")

	AcquireData_NG(s, str)
End

static Function EP_EpochTest11_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_EpochTest12([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                                             + \
								 "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:_AF:StopMidSweep_V3:" + \
								 "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetA_DA_0:_AF:StopMidSweep_V3:")

	AcquireData_NG(s, str)
End

static Function EP_EpochTest12_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_EpochTest13([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                                                     + \
								 "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:_AF:AddTooLargeUserEpoch_V3:" + \
								 "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetA_DA_0:_AF:AddTooLargeUserEpoch_V3:")

	AcquireData_NG(s, str)
End

static Function EP_EpochTest13_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_TestUserEpochs([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                                             + \
								 "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:_AF:AddUserEpoch_V3:" + \
								 "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetA_DA_0:_AF:AddUserEpoch_V3:")

	AcquireData_NG(s, str)
End

static Function EP_TestUserEpochs_REENTRY([str])
	string str

	variable i, j, k, nextSweep, DAC
	string tags, shortName

	WAVE/T textualValues = GetLBTextualValues(str)

	nextSweep = GetSetVariable(str, "SetVar_Sweep")

	for(i = 0; i < nextSweep; i += 1)
		WAVE/T/Z epochLBN = GetLastSetting(textualValues, i, EPOCHS_ENTRY_KEY, DATA_ACQUISITION_MODE)
		CHECK_WAVE(epochLBN, TEXT_WAVE)

		for(j = 0; j < 2; j += 1)
			WAVE/T/Z epochWave = EP_EpochStrToWave(epochLBN[j])
			CHECK_WAVE(epochWave, TEXT_WAVE)

			DAC = AFH_GetDACFromHeadstage(str, j)

			// now check that we can find epochs from the expected events
			for(k = 0; k < TOTAL_NUM_EVENTS; k += 1)
				sprintf tags, "HS=%d;eventType=%d;", j, k
				// not using /TXOP=4 here as we have an unknown short name as well
				FindValue/TEXT=tags/RMD=[][EPOCH_COL_TAGS][DAC] epochWave

				switch(k)
					case PRE_SET_EVENT:
					case POST_SET_EVENT:
					case PRE_SWEEP_CONFIG_EVENT:
					case MID_SWEEP_EVENT:
					case POST_SWEEP_EVENT:
						if((k == PRE_SET_EVENT && i == 0)  ||         \
						   (k == POST_SET_EVENT && i == 2) ||         \
						   (k != PRE_SET_EVENT && k != POST_SET_EVENT))
							// user epoch was added
							CHECK_GE_VAR(V_row, 0)
							tags = epochWave[V_row][EPOCH_COL_TAGS]
							shortName = EP_GetShortName(tags)
							CHECK(GrepString(shortName, "^U_"))
							break
						endif
					default:
						// no user epochs for all other events
						CHECK_LT_VAR(V_row, 0)
						break
				endswitch
			endfor
		endfor
	endfor
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_EpochTest14([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                              + \
								 "__HS0_DA0_AD0_CM:VC:_ST:EpochTest_Trig_DA_0:"    + \
								 "__HS1_DA1_AD1_CM:VC:_ST:EpochTest_TrigFl_DA_0:")

	AcquireData_NG(s, str)
End

static Function EP_EpochTest14_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End

static Function EP_EpochTest15_PreAcq(string device)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPDuration", val =10)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EP_EpochTest15([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_TBP43.59"                + \
	       						   "__HS0_DA0_AD0_CM:VC:_ST:EpochTest0_DA_0:")

	AcquireData_NG(s, str)
End

static Function EP_EpochTest15_REENTRY([str])
	string str

	TestEpochsGeneric(str)
End
