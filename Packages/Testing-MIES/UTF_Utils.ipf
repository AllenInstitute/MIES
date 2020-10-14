#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UtilsTest

static Function TEST_CASE_BEGIN_OVERRIDE(name)
	string name

	AdditionalExperimentCleanupAfterTest()

	CA_FlushCache()
End

Function AssertionWorksWithPassingOne()

	PASS()
	ASSERT(1, "Nothing to see here")
End

Function AssertionFiresWithPassingZero()

	try
		ASSERT(0, "Kaboom")
		FAIL()
	catch
		CHECK_EQUAL_VAR(V_AbortCode, -3)
	endtry
End

Function AssertionThreadsafeWorksWithPassingOne()

	PASS()
	ASSERT_TS(1, "Nothing to see here")
End

Function AssertionThreadsafeFiresWithPassingZero()

	try
		ASSERT_TS(0, "Kaboom")
		FAIL()
	catch
		CHECK(V_AbortCode >= 1)
	endtry
End

/// RemoveAllEmptyDataFolders
/// @{
Function RemoveAllEmpty_init_IGNORE()

	NewDataFolder/O root:removeMe
	NewDataFolder/O root:removeMe:X1
	NewDataFolder/O root:removeMe:X2
	NewDataFolder/O root:removeMe:X3
	NewDataFolder/O root:removeMe:X4
	NewDataFolder/O root:removeMe:X4:data
	NewDataFolder/O root:removeMe:X5
	variable/G      root:removeMe:X5:data
	NewDataFolder/O root:removeMe:X6
	string/G        root:removeMe:X6:data
	NewDataFolder/O root:removeMe:X7
	Make/O          root:removeMe:X7:data
	NewDataFolder/O root:removeMe:X8
	NewDataFolder/O root:removeMe:x8
End

Function RemoveAllEmpty_Works1()

	RemoveAllEmptyDataFolders($"")
	PASS()
End

Function RemoveAllEmpty_Works2()

	DFREF dfr = NewFreeDataFolder()
	RemoveAllEmptyDataFolders(dfr)
	PASS()
End

Function RemoveAllEmpty_Works3()

	NewDataFolder ttest
	string folder = GetDataFolder(1) + "ttest"
	RemoveAllEmptyDataFolders($folder)
	CHECK(DataFolderExists(folder))
End

Function RemoveAllEmpty_Works4()

	RemoveAllEmpty_init_IGNORE()

	DFREF dfr = root:removeMe
	RemoveAllEmptyDataFolders(dfr)
	CHECK_EQUAL_VAR(CountObjectsDFR(dfr, 4), 4)
End
/// @}

/// ReplaceWordInString
/// @{
Function AbortsEmptyFirstArg()

	try
		ReplaceWordInString("", "abcd", "abcde")
		FAIL()
	catch
		PASS()
	endtry
End

Function ReturnsUnchangedString()

	string expected = "123"
	string actual   = ReplaceWordInString("ABCD", "123", "abcd")
	CHECK_EQUAL_STR(actual, expected)
End

Function SearchesForARealWord()

	string expected = "abcd"
	string actual   = ReplaceWordInString("abc", "abcd", "123")
	CHECK_EQUAL_STR(actual, expected)
End

Function WorksWithSameWordAndRepl()

	string expected = "abcd"
	string actual   = ReplaceWordInString("abc", "abcd", "abc")
	CHECK_EQUAL_STR(actual, expected)
End

Function ReplacesOneOccurrence()

	string expected = "1 2 3"
	string actual   = ReplaceWordInString("a", "1 a 3", "2")
	CHECK_EQUAL_STR(actual, expected)
End

Function ReplacesAllOccurences()

	string expected = "1 2 3 2 5"
	string actual   = ReplaceWordInString("a", "1 a 3 a 5", "2")
	CHECK_EQUAL_STR(actual, expected)
End

Function DoesNotIgnoreCase()

	string expected = "1 2 3 A 5"
	string actual   = ReplaceWordInString("a", "1 a 3 A 5", "2")
	CHECK_EQUAL_STR(actual, expected)
End

Function ReplacesWithEmptyString()

	string expected = "b"
	string actual   = ReplaceWordInString("a ", "a b", "")
	CHECK_EQUAL_STR(actual, expected)
End
/// @}

/// ParseISO8601TimeStamp
/// @{
Function ReturnsNaNOnInvalid1()

	variable expected = NaN
	variable actual   = ParseISO8601TimeStamp("")
	CHECK_EQUAL_VAR(actual, expected)
End

Function ReturnsNaNOnInvalid2()

	variable expected = NaN
	variable actual   = ParseISO8601TimeStamp("asdklajsd")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid1()

	variable expected = 3578412052
	variable actual   = ParseISO8601TimeStamp("2017-05-23 19:20:52Z")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid2()

	variable expected = 3578412052
	variable actual   = ParseISO8601TimeStamp("2017-05-23 19:20:52")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid3()

	variable expected = 3578412052
	variable actual   = ParseISO8601TimeStamp("2017-05-23T19:20:52")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid4()

	variable expected = 3578412052
	variable actual   = ParseISO8601TimeStamp("2017-05-23T19:20:52Z")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid5()

	variable expected = 3578412052.12345678910
	variable actual   = ParseISO8601TimeStamp("2017-05-23 19:20:52.12345678910")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid6()

	variable expected = 3578412052.12345678910
	variable actual   = ParseISO8601TimeStamp("2017-05-23T19:20:52.12345678910")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid7()

	variable expected = 3578412052.12345678910
	variable actual   = ParseISO8601TimeStamp("2017-05-23T19:20:52.12345678910Z")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid8()

	variable expected = 3578412052.12345678910
	// ISO 8601 does not define decimal separator, so comma is also okay
	variable actual   = ParseISO8601TimeStamp("2017-05-23T19:20:52,12345678910")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid9()

	variable now      = DateTimeInUTC()
	variable expected = trunc(now)
	variable actual   = ParseISO8601TimeStamp(GetIso8601TimeStamp(secondsSinceIgorEpoch = now))
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid10()

	variable now      = DateTimeInUTC()
	variable expected = now
	// DateTime currently returns three digits of precision
	variable actual   = ParseISO8601TimeStamp(GetIso8601TimeStamp(secondsSinceIgorEpoch = now, numFracSecondsDigits = 3))
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid11()

	variable now = DateTime
	string actual   = GetIso8601TimeStamp(secondsSinceIgorEpoch = now, localTimeZone = 1)
	string expected = GetIso8601TimeStamp(secondsSinceIgorEpoch = now  - Date2Secs(-1, -1, -1))

	CHECK_EQUAL_VAR(ParseISO8601TimeStamp(actual), ParseISO8601TimeStamp(expected))
End

Function AcceptsValid12()

	variable now      = DateTime
	variable expected = trunc(now) - Date2Secs(-1, -1, -1)
	variable actual   = ParseISO8601TimeStamp(GetIso8601TimeStamp(secondsSinceIgorEpoch = now, localTimeZone = 1))

	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid13()

	variable expected = ParseISO8601TimeStamp("2017-05-23T9:20:52-08:00")
	variable actual   = ParseISO8601TimeStamp("2017-05-23T18:20:52+01:00")
	CHECK_EQUAL_VAR(actual, expected)

	expected = ParseISO8601TimeStamp("2017-05-23T09:20:52-08:00")
	actual   = ParseISO8601TimeStamp("2017-05-23T17:20:52Z")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid14()

	variable expected = 1
	variable actual

	actual = ParseISO8601Timestamp("1904-01-1T00:00:01")
	CHECK_EQUAL_VAR(actual, expected)
	actual = ParseISO8601Timestamp("1904-01-1T00:00:01Z")
	CHECK_EQUAL_VAR(actual, expected)
	actual = ParseISO8601Timestamp("1904-01-1T00:00:01+00:00")
	CHECK_EQUAL_VAR(actual, expected)
	actual = ParseISO8601Timestamp("1904-01-1T01:00:01+01:00")
	CHECK_EQUAL_VAR(actual, expected)
End

/// @}

/// ISO8601Tests
/// @{

Function/WAVE ISO8601_timestamps()

	Make/FREE/T wv = {\
		GetIso8601TimeStamp(), \
		GetIso8601TimeStamp(localTimeZone = 0), \
		GetIso8601TimeStamp(localTimeZone = 1), \
		GetIso8601TimeStamp(numFracSecondsDigits = 1), \
		GetIso8601TimeStamp(numFracSecondsDigits = 2), \
		GetIso8601TimeStamp(numFracSecondsDigits = 2, localTimeZone = 1), \
		"2007-08-31T16:47+00:00", \
		"2007-12-24T18:21Z", \
		"2008-02-01T09:00:22+05", \
		"2009-01-01T12:00:00+01:00", \
		"2009-06-30T18:30:00+02:00" \
		}

	return wv
End

// UTF_TD_GENERATOR ISO8601_timestamps
Function ISO8601_teststamps([str])
	string str

	variable secondsSinceIgorEpoch

	secondsSinceIgorEpoch = ParseISO8601TimeStamp(str)
	REQUIRE_NEQ_VAR(NaN, secondsSinceIgorEpoch)
End

/// @}

/// GetSetDifference
/// @{
Function GSD_ExpectsSameWaveType()

	Make/Free/D data1
	Make/Free/R data2

	try
		WAVE/Z matches = GetSetDifference(data1, data2)
		FAIL()
	catch
		PASS()
	endtry
End

Function GSD_ExpectsFPWaveType()

	Make/Free/D data1
	Make/Free/T data2

	try
		WAVE/Z matches = GetSetDifference(data1, data2)
		FAIL()
	catch
		PASS()
	endtry
End

Function GSD_Works1()

	Make/Free data1 = {1, 2, 3, 4}
	Make/Free data2 = {4, 5, 6}

	WAVE/Z matches = GetSetDifference(data1, data2)
	CHECK_EQUAL_WAVES(matches, {1, 2, 3})
End

Function GSD_Works2()

	Make/Free data1 = {1, 2, 3, 4}
	Make/Free data2 = {5, 6, 7}

	WAVE/Z matches = GetSetDifference(data1, data2)
	CHECK_EQUAL_WAVES(matches, {1, 2, 3, 4})
End

Function GSD_Works3()

	Make/Free data1 = {1, 2, 3, 4}
	Make/Free data2 = {4, 3, 2}

	WAVE/Z matches = GetSetDifference(data1, data2)
	CHECK_EQUAL_WAVES(matches, {1})
End

Function GSD_Works4()

	Make/Free/D data1
	Make/Free/D data2

	WAVE/Z matches = GetSetDifference(data1, data2)
	CHECK_WAVE(matches, NULL_WAVE)
End

Function GSD_Works5()

	Make/Free/D data1
	Make/Free/D/N=0 data2

	WAVE matches = GetSetDifference(data1, data2)
	CHECK_EQUAL_WAVES(matches, data1)
End

Function GSD_Works6()

	Make/Free/D data1 = p
	Make/Free/D data2 = -1

	WAVE matches = GetSetDifference(data1, data2)
	CHECK_EQUAL_WAVES(matches, data1)
End

Function GSD_ReturnsInvalidWaveRefWOMatches()

	Make/Free/D/N=0 data1
	Make/Free/D data2

	WAVE/Z matches = GetSetDifference(data1, data2)
	CHECK_WAVE(matches, NULL_WAVE)
End
/// @}

/// GetSetIntersection
/// @{
Function ExpectsSameWaveType()

	Make/Free/D data1
	Make/Free/R data2

	try
		WAVE/Z matches = GetSetIntersection(data1, data2)
		FAIL()
	catch
		PASS()
	endtry
End

Function Works1()

	Make/Free data1 = {1, 2, 3, 4}
	Make/Free data2 = {4, 5, 6}

	WAVE/Z matches = GetSetIntersection(data1, data2)
	CHECK_EQUAL_WAVES(matches, {4})
End

Function ReturnsCorrectType()

	Make/Free/D data1
	Make/Free/D data2

	WAVE matches = GetSetIntersection(data1, data2)
	CHECK_EQUAL_WAVES(data1, matches)
End

Function ReturnsInvalidWaveRefWOMatches1()

	Make/Free/D/N=0 data1
	Make/Free/D data2

	WAVE/Z matches = GetSetIntersection(data1, data2)
	CHECK_WAVE(matches, NULL_WAVE)
End

Function ReturnsInvalidWaveRefWOMatches2()

	Make/Free/D data1
	Make/Free/D/N=0 data2

	WAVE matches = GetSetIntersection(data1, data2)
	CHECK_WAVE(matches, NULL_WAVE)
End

Function ReturnsInvalidWaveRefWOMatches3()

	Make/Free/D data1 = p
	Make/Free/D data2 = -1

	WAVE matches = GetSetIntersection(data1, data2)
	CHECK_WAVE(matches, NULL_WAVE)
End
/// @}

/// DAP_GetRAAcquisitionCycleID
/// @{

static StrConstant device = "ITC18USB_DEV_0"

Function AssertOnInvalidSeed()
	NVAR rngSeed = $GetRNGSeed(device)
	rngSeed = NaN

	try
		MIES_DAP#DAP_GetRAAcquisitionCycleID(device)
		FAIL()
	catch
		PASS()
	endtry
End

Function CreatesReproducibleResults()
	NVAR rngSeed = $GetRNGSeed(device)

	// Use GetNextRandomNumberForDevice directly
	// as we don't have a locked device

	rngSeed = 1
	Make/FREE/N=1024/L dataInt = GetNextRandomNumberForDevice(device)
	CHECK_EQUAL_VAR(998651135, WaveCRC(0, dataInt))

	rngSeed = 1
	Make/FREE/N=1024/D dataDouble = GetNextRandomNumberForDevice(device)

	// EqualWaves is currently (7.0.5.1) broken for different data types
	Make/FREE/B/N=1024 equal = dataInt[p] - dataDouble[p]
	CHECK_EQUAL_VAR(WaveMax(equal), 0)
	CHECK_EQUAL_VAR(WaveMin(equal), 0)
End
/// @}

/// EnsureLargeEnoughWave
/// @{
Function ELE_AbortsWOWave()

	try
		EnsureLargeEnoughWave($"")
		FAIL()
	catch
		PASS()
	endtry
End

Function ELE_AbortsInvalidDim()

	try
		Make/FREE wv
		EnsureLargeEnoughWave(wv, dimension = -1)
		FAIL()
	catch
		PASS()
	endtry
End

Function ELE_HasMinimumSize()

	Make/FREE/N=0 wv
	EnsureLargeEnoughWave(wv)
	CHECK(DimSize(wv, ROWS) > 0)
	CHECK(DimSize(wv, COLS) == 0)
End

Function ELE_InitsToZero()

	Make/FREE/N=0 wv
	EnsureLargeEnoughWave(wv)
	CHECK_EQUAL_VAR(WaveMax(wv), 0)
	CHECK_EQUAL_VAR(WaveMin(wv), 0)
End

Function ELE_KeepsExistingData()

	Make/FREE/N=(1, 2) wv
	wv[0][0] = 4711
	EnsureLargeEnoughWave(wv)
	CHECK_EQUAL_VAR(wv[0], 4711)
	CHECK_EQUAL_VAR(Sum(wv), 4711) // others default to zero
End

Function ELE_HandlesCustomInitVal()

	Make/FREE/N=0 wv
	EnsureLargeEnoughWave(wv, initialValue = NaN)
	WaveStats/M=2/Q wv
	CHECK_EQUAL_VAR(V_npnts, 0)
End

Function ELE_HandlesCustomInitValCol()

	Make/FREE/N=(1, 2, 3) wv = NaN
	EnsureLargeEnoughWave(wv, dimension = COLS, initialValue = NaN)
	WaveStats/M=2/Q wv
	CHECK_EQUAL_VAR(V_npnts, 0)
End

Function ELE_WorksForColsAsWell()

	Make/FREE/N=1 wv
	EnsureLargeEnoughWave(wv, dimension = COLS)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 1)
	CHECK(DimSize(wv, COLS) > 0)
End

Function ELE_MinimumSize1()

	Make/FREE/N=100 wv
	EnsureLargeEnoughWave(wv, minimumSize = 1)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 100)
End

Function ELE_MinimumSize2()

	Make/FREE/N=100 wv
	EnsureLargeEnoughWave(wv, minimumSize = 100)
	CHECK(DimSize(wv, ROWS) > 100)
End

Function ELE_KeepsMinimumWaveSize1()

	Make/FREE/N=(MINIMUM_WAVE_SIZE) wv
	Duplicate/FREE wv, refWave
	EnsureLargeEnoughWave(wv)
	CHECK_EQUAL_WAVES(wv, refWave)
End

Function ELE_KeepsMinimumWaveSize2()

	Make/FREE/N=(MINIMUM_WAVE_SIZE) wv
	Duplicate/FREE wv, refWave
	EnsureLargeEnoughWave(wv, minimumSize = 1)
	CHECK_EQUAL_WAVES(wv, refWave)
End

Function ELE_KeepsMinimumWaveSize3()
	// need to check that the index MINIMUM_WAVE_SIZE is now accessible
	Make/FREE/N=(MINIMUM_WAVE_SIZE) wv
	EnsureLargeEnoughWave(wv, minimumSize = MINIMUM_WAVE_SIZE)
	CHECK(DimSize(wv, ROWS) > MINIMUM_WAVE_SIZE)
End

Function ELE_Returns1WithCheckMem()
	Make/FREE/N=(MINIMUM_WAVE_SIZE) wv
	CHECK_EQUAL_VAR(EnsureLargeEnoughWave(wv, minimumSize = 2^50, checkFreeMemory = 1), 1)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), MINIMUM_WAVE_SIZE)
End

Function ELE_AbortsWithTooLargeValue()
	Make/FREE/N=(MINIMUM_WAVE_SIZE) wv

	variable err

	try
		EnsureLargeEnoughWave(wv, minimumSize = 2^50); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		PASS()
	endtry
End

/// @}

/// RemoveUnusedRows
/// @{

Function RUR_ChecksNote()

	Make/FREE wv
	try
		RemoveUnusedRows(wv); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

Function RUR_ReturnsInvalidWaveRef()

	Make/FREE wv
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	WAVE/Z dup = RemoveUnusedRows(wv)
	CHECK_WAVE(dup, NULL_WAVE)
End

Function RUR_Works()

	Make/FREE/N=(10, 3, 2) wv
	SetNumberInWaveNote(wv, NOTE_INDEX, 4)

	WAVE dup = RemoveUnusedRows(wv)

	Make/FREE/N=(MAX_DIMENSION_COUNT) dims = DimSize(dup, p)
	CHECK_EQUAL_WAVES(dims, {4, 3, 2, 0}, mode = WAVE_DATA)
	CHECK(!WaveRefsEqual(wv, dup))
End
/// @}

/// DoAbortNow
/// @{

Function DON_WorksWithDefault()

	NVAR interactiveMode = $GetInteractiveMode()
	CHECK_EQUAL_VAR(interactiveMode, 1)

	try
		DoAbortNow("")
		FAIL()
	catch
		PASS()
	endtry
End

Function DON_WorksWithNoMsgAndInterMode()

	NVAR interactiveMode = $GetInteractiveMode()
	interactiveMode = 1

	try
		DoAbortNow("")
		FAIL()
	catch
		PASS()
	endtry
End

Function DON_WorksWithNoMsgAndNInterMode()

	NVAR interactiveMode = $GetInteractiveMode()
	interactiveMode = 0

	try
		DoAbortNow("")
		FAIL()
	catch
		PASS()
	endtry
End

Function DON_WorksWithMsgAndNInterMode()

	NVAR interactiveMode = $GetInteractiveMode()
	interactiveMode = 0

	try
		DoAbortNow("MyMessage")
		FAIL()
	catch
		PASS()
	endtry
End

// we can't test with message and interactive abort as that
// will trigger a dialog ...

/// @}

/// FloatWithMinSigDigits
/// @{
Function FMS_Aborts()

	try
		FloatWithMinSigDigits(1, numMinSignDigits = -1)
		FAIL()
	catch
		PASS()
	endtry
End

Function FMS_Works1()

	string result
	string expected

	result   = FloatWithMinSigDigits(1.23456, numMinSignDigits = 2)
	expected = "1.2"

	CHECK_EQUAL_STR(result, expected)
End

Function FMS_Works2()

	string result
	string expected

	result   = FloatWithMinSigDigits(12.3456, numMinSignDigits = 2)
	expected = "12"

	CHECK_EQUAL_STR(result, expected)
End

Function FMS_Works3()

	string result
	string expected

	result   = FloatWithMinSigDigits(12.3456, numMinSignDigits = 1)
	expected = "12"

	CHECK_EQUAL_STR(result, expected)
End
/// @}

/// NormalizeToEOL
/// @{

Function NTE_AbortsWithUnknownEOL()

	try
		NormalizeToEOL("", "a")
		FAIL()
	catch
		PASS()
	endtry
End

Function NTE_Works1()

	string eol      = "\r"
	string input    = "hi there!\r"

	string output   = NormalizeToEOL(input, eol)
	string expected = input
	CHECK_EQUAL_STR(output, expected)
End

Function NTE_Works2()

	string eol      = "\r"
	string input    = "hi there!\n\n\r"

	string output   = NormalizeToEOL(input, eol)
	string expected = "hi there!\r\r\r"
	CHECK_EQUAL_STR(output, expected)
End

Function NTE_Works3()

	string eol      = "\r"
	string input    = "hi there!\r\n\r" // CR+LF -> CR

	string output   = NormalizeToEOL(input, eol)
	string expected = "hi there!\r\r"
	CHECK_EQUAL_STR(output, expected)
End

Function NTE_Works4()

	string eol      = "\n"
	string input    = "hi there!\r\n\r" // CR+LF -> CR

	string output   = NormalizeToEOL(input, eol)
	string expected = "hi there!\n\n"
	CHECK_EQUAL_STR(output, expected)
End

/// @}

/// SearchForDuplicates
/// @{

Function SFD_AbortsWithNull()

	try
		SearchForDuplicates($"")
		FAIL()
	catch
		PASS()
	endtry
End

Function SFD_WorksWithEmptyWave()

	Make/FREE/N=0 data
	CHECK(!SearchForDuplicates(data))
End

Function SFD_WorksWithSingleEntryWave()

	Make/FREE/N=1 data = 0
	CHECK(!SearchForDuplicates(data))
End

Function SFD_Works()

	Make/FREE data = {0, 1, 2, 4, 5, 0}
	CHECK(SearchForDuplicates(data))
End

/// @}

/// ITCConfig Wave querying
/// @{

Function ITCC_WorksLegacy()

	variable type, i
	string actual, expected

	WAVE/SDFR=root:ITCWaves config = ITCChanConfigWave_legacy
	CHECK(IsValidConfigWave(config, version=0))

	WAVE/T/Z units = AFH_GetChannelUnits(config)
	CHECK_WAVE(units, TEXT_WAVE)
	// we have one TTL channel which does not have a unit
	CHECK_EQUAL_VAR(DimSize(units, ROWS) + 1, DimSize(config, ROWS))
	CHECK_EQUAL_TEXTWAVES(units, {"DA0", "DA1", "DA2", "AD0", "AD1", "AD2"})

	for(i = 0; i < 3; i += 1)
		type = ITC_XOP_CHANNEL_TYPE_DAC
		expected = StringFromList(type, ITC_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)

		type = ITC_XOP_CHANNEL_TYPE_ADC
		expected = StringFromList(type, ITC_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)
	endfor

	WAVE/Z DACs = GetDACListFromConfig(config)
	CHECK_WAVE(DACs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(DACs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z ADCs = GetADCListFromConfig(config)
	CHECK_WAVE(ADCs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(ADCs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z TTLs = GetTTLListFromConfig(config)
	CHECK_WAVE(TTLs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(TTLS, {1}, mode = WAVE_DATA)
End

Function ITCC_WorksVersion1()

	variable type, i
	string actual, expected

	WAVE/SDFR=root:ITCWaves config = ITCChanConfigWave_Version1
	CHECK(IsValidConfigWave(config, version=1))

	WAVE/T/Z units = AFH_GetChannelUnits(config)
	CHECK_WAVE(units, TEXT_WAVE)
	// we have one TTL channel which does not have a unit
	CHECK_EQUAL_VAR(DimSize(units, ROWS) + 1, DimSize(config, ROWS))
	CHECK_EQUAL_TEXTWAVES(units, {"DA0", "DA1", "DA2", "AD0", "AD1", "AD2"})

	for(i = 0; i < 3; i += 1)
		type = ITC_XOP_CHANNEL_TYPE_DAC
		expected = StringFromList(type, ITC_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)

		type = ITC_XOP_CHANNEL_TYPE_ADC
		expected = StringFromList(type, ITC_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)
	endfor

	WAVE/Z DACs = GetDACListFromConfig(config)
	CHECK_WAVE(DACs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(DACs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z ADCs = GetADCListFromConfig(config)
	CHECK_WAVE(ADCs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(ADCs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z TTLs = GetTTLListFromConfig(config)
	CHECK_WAVE(TTLs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(TTLS, {1}, mode = WAVE_DATA)
End

Function ITCC_WorksVersion2()

	variable type, i
	string actual, expected

	WAVE/SDFR=root:ITCWaves config = ITCChanConfigWave_Version2
	CHECK(IsValidConfigWave(config, version=2))

	WAVE/T/Z units = AFH_GetChannelUnits(config)
	CHECK(WaveExists(units))
	// we have one TTL channel which does not have a unit
	CHECK_EQUAL_VAR(DimSize(units, ROWS) + 1, DimSize(config, ROWS))
	CHECK_EQUAL_TEXTWAVES(units, {"DA0", "DA1", "DA2", "AD0", "AD1", "AD2"})

	for(i = 0; i < 3; i += 1)
		type = ITC_XOP_CHANNEL_TYPE_DAC
		expected = StringFromList(type, ITC_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)

		type = ITC_XOP_CHANNEL_TYPE_ADC
		expected = StringFromList(type, ITC_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)
	endfor

	WAVE/Z DACs = GetDACListFromConfig(config)
	CHECK_WAVE(DACs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(DACs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z ADCs = GetADCListFromConfig(config)
	CHECK_WAVE(ADCs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(ADCs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z TTLs = GetTTLListFromConfig(config)
	CHECK_WAVE(TTLs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(TTLS, {1}, mode = WAVE_DATA)

	WAVE/Z DACmode = GetDACTypesFromConfig(config)
	CHECK_WAVE(DACmode, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(DACmode, {1, 2, 2}, mode = WAVE_DATA)

	WAVE/Z ADCmode = GetADCTypesFromConfig(config)
	CHECK_WAVE(ADCmode, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(ADCmode, {2, 1, 2}, mode = WAVE_DATA)
End

/// @}

/// FindIndizes
/// @{

Function FI_NumSearchWithCol1()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 0, var = 1)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndLayer1()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 0, var = 1, startLayer = 0, endLayer = 1)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2, 3, 4}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndLayer2()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 0, var = 1, startLayer = 1, endLayer = 1)
	CHECK_EQUAL_WAVES(indizes, {3, 4}, mode = WAVE_DATA)
End

Function FI_NumSearchWithCol2()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, str = "2")
	CHECK_EQUAL_WAVES(indizes, {1, 2}, mode = WAVE_DATA)
End

Function FI_NumSearchWithCol3()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 2, var = 4711)
	CHECK_WAVE(indizes, NULL_WAVE)
End

Function FI_NumSearchWithColLabel()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, colLabel = "abcd", var = 1)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndStr()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, colLabel = "abcd", str = "1")
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndProp1()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, colLabel = "abcd", prop = PROP_NON_EMPTY)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndProp2()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, colLabel = "abcd", prop = PROP_EMPTY)
	CHECK_EQUAL_WAVES(indizes, {3, 4}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndProp3()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, var = 2, prop = PROP_MATCHES_VAR_BIT_MASK)
	CHECK_EQUAL_WAVES(indizes, {1, 2, 3, 4}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndProp4()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, var = 2, prop = PROP_NOT_MATCHES_VAR_BIT_MASK)
	CHECK_EQUAL_WAVES(indizes, {0}, mode = WAVE_DATA)
End

Function FI_NumSearchWithRestRows()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, var = 2, startRow = 2, endRow = 3)
	CHECK_EQUAL_WAVES(indizes, {2}, mode = WAVE_DATA)
End

Function FI_TextSearchWithCol1()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 0, str = "text123")
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

Function FI_TextSearchWithColAndLayer1()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 0, str = "text123", startLayer = 0, endLayer = 1)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2, 3, 4}, mode = WAVE_DATA)
End

Function FI_TextSearchWithColAndLayer2()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 0, str = "text123", startLayer = 1, endLayer = 1)
	CHECK_EQUAL_WAVES(indizes, {3, 4}, mode = WAVE_DATA)
End

Function FI_TextSearchWithCol2()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "2")
	CHECK_EQUAL_WAVES(indizes, {1, 2}, mode = WAVE_DATA)
End

Function FI_TextSearchWithCol3()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 2, str = "4711")
	CHECK_WAVE(indizes, NULL_WAVE)
End

Function FI_TextSearchWithColLabel()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, colLabel = "efgh", str = "text123")
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

Function FI_TextSearchWithColAndVar()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, var = 2)
	CHECK_EQUAL_WAVES(indizes, {1, 2}, mode = WAVE_DATA)
End

Function FI_TextSearchIgnoresCase()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, colLabel = "efgh", str = "TEXT123")
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

Function FI_TextSearchWithColAndProp1()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, colLabel = "efgh", prop = PROP_NON_EMPTY)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

Function FI_TextSearchWithColAndProp2()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, colLabel = "efgh", prop = PROP_EMPTY)
	CHECK_EQUAL_WAVES(indizes, {3, 4}, mode = WAVE_DATA)
End

Function FI_TextSearchWithColAndProp3()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "2", prop = PROP_MATCHES_VAR_BIT_MASK)
	CHECK_EQUAL_WAVES(indizes, {1, 2, 3, 4}, mode = WAVE_DATA)
End

Function FI_TextSearchWithColAndProp4()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "2", prop = PROP_NOT_MATCHES_VAR_BIT_MASK)
	CHECK_EQUAL_WAVES(indizes, {0}, mode = WAVE_DATA)
End

Function FI_TextSearchWithRestRows()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "2", startRow = 2, endRow = 3)
	CHECK_EQUAL_WAVES(indizes, {2}, mode = WAVE_DATA)
End

Function FI_AbortsWithInvalidParams1()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams2()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, col = 0, var = 1, str = "123")
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams3()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, col = 0, prop = 4711)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams4()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, col = 0, colLabel = "dup")
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams5()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, col = 0, var = 0, startRow = 100)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams6()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, col = 0, var = 0, endRow = 100)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams7()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, col = 0, var = 0, startRow = 3, endRow = 2)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams8()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, col = 0, var = NaN)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams9()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, col = 0, str = "NaN")
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams10()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, col = 0, var = 1, startLayer = 1)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams11()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, col = 0, var = 1, startLayer = 100, endLayer = 100)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams12()

	Make/FREE/N=(1, 2, 3, 4) data
	try
		WAVE/Z indizes = FindIndizes(data, col = 0, var = 0)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidWave()

	try
		FindIndizes($"", col = 0, var = 0)
		FAIL()
	catch
		PASS()
	endtry
End

/// @}

/// @{
/// GetMachineEpsilon

Function EPS_WorksWithDouble()

	variable eps, type

	type = IGOR_TYPE_64BIT_FLOAT
	eps  = GetMachineEpsilon(type)
	Make/FREE/Y=(type)/N=1 ref = 1
	Make/FREE/Y=(type)/N=1 val

	val = ref[0] + eps
	CHECK_NEQ_VAR(ref[0], val[0])

	val = ref[0] + eps/2.0
	CHECK_EQUAL_VAR(ref[0], val[0])
End

Function EPS_WorksWithFloat()

	variable eps, type

	type = IGOR_TYPE_32BIT_FLOAT
	eps  = GetMachineEpsilon(type)
	Make/FREE/Y=(type)/N=1 ref = 1
	Make/FREE/Y=(type)/N=1 val

	val = ref[0] + eps
	CHECK_NEQ_VAR(ref[0], val[0])

	val = ref[0] + eps/2.0
	CHECK_EQUAL_VAR(ref[0], val[0])
End
/// @}

/// @{
/// oodDAQ regression tests

static Function oodDAQStore_IGNORE(stimset, offsets, regions, index)
	WAVE/WAVE stimset
	WAVE offsets, regions
	variable index

	variable i

	DFREF dfr = root:oodDAQ

	for(i = 0; i < DimSize(stimset, ROWS); i += 1)
		WAVE singleStimset = stimset[i]
		Duplicate/O singleStimset, dfr:$("stimset_oodDAQ_" + num2str(index) + "_" + num2str(i))
	endfor

	Duplicate/O offsets, dfr:$("offsets_" + num2str(index))
	Duplicate/O regions, dfr:$("regions_" + num2str(index))
End

static Function/WAVE GetoodDAQ_RefWaves_IGNORE(index)
	variable index

	variable i

	Make/FREE/WAVE/N=(64, 3) wv

	SetDimLabel COLS, 0, stimset, wv
	SetDimLabel COLS, 1, offset,  wv
	SetDimLabel COLS, 2, region,  wv

	DFREF dfr = root:oodDAQ

	for(i = 0; i < DimSize(wv, ROWS); i += 1)
		WAVE/Z/SDFR=dfr ref_stimset = $("stimset_oodDAQ_" + num2str(index) + "_" + num2str(i))

		if(!WaveExists(ref_stimset))
			break
		endif

		wv[i][%stimset] = ref_stimset
	endfor

	WAVE/Z/SDFR=dfr ref_offsets   = $("offsets_" + num2str(index))
	WAVE/Z/SDFR=dfr ref_regions   = $("regions_" + num2str(index))

	wv[0][%offset] = ref_offsets
	wv[0][%region] = ref_regions

	return wv
End

Function oodDAQRegTests_0()

	variable index
	STRUCT OOdDAQParams params
	DFREF dfr = root:oodDAQ
	string panelTitle = "ITC18USB_Dev_0"
	WAVE singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 0
	InitOOdDAQParams(params, stimSet, {0, 0}, 0, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(panelTitle,params)

//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_1()

	variable index
	STRUCT OOdDAQParams params
	DFREF dfr = root:oodDAQ
	string panelTitle = "ITC18USB_Dev_0"
	WAVE singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 1
	InitOOdDAQParams(params, stimSet, {1, 0}, 0, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(panelTitle,params)

//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_2()

	variable index
	STRUCT OOdDAQParams params
	DFREF dfr = root:oodDAQ
	string panelTitle = "ITC18USB_Dev_0"
	WAVE singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 2
	InitOOdDAQParams(params, stimSet, {0, 1}, 0, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(panelTitle,params)

//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_3()

	variable index
	STRUCT OOdDAQParams params
	DFREF dfr = root:oodDAQ
	string panelTitle = "ITC18USB_Dev_0"
	WAVE singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 3
	InitOOdDAQParams(params, stimSet, {0, 0}, 20, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(panelTitle,params)

//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_4()

	variable index
	STRUCT OOdDAQParams params
	DFREF dfr = root:oodDAQ
	string panelTitle = "ITC18USB_Dev_0"
	WAVE singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 4
	InitOOdDAQParams(params, stimSet, {0, 0}, 0, 20)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(panelTitle,params)

//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_5()

	variable index
	STRUCT OOdDAQParams params
	DFREF dfr = root:oodDAQ
	string panelTitle = "ITC18USB_Dev_0"
	WAVE singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 5
	InitOOdDAQParams(params, stimSet, {0, 0}, 0, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(panelTitle,params)

//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_6()

	variable index
	STRUCT OOdDAQParams params
	DFREF dfr = root:oodDAQ
	string panelTitle = "ITC18USB_Dev_0"
	WAVE singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 6
	InitOOdDAQParams(params, stimSet, {0, 1}, 20, 30)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(panelTitle,params)

//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_7()

	variable index
	STRUCT OOdDAQParams params
	DFREF dfr = root:oodDAQ
	string panelTitle = "ITC18USB_Dev_0"
	WAVE singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=3/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 7
	InitOOdDAQParams(params, stimSet, {0, 0, 0}, 0, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(panelTitle,params)

//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[2][%stimset], stimset[2])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

/// @}

/// @name CheckActiveHeadstages
/// @{
Function HAH_ReturnsNaN()

	string panelTitle = "IGNORE"
	Make/O/N=(NUM_HEADSTAGES) statusHS = 0
	Make/O/N=(NUM_HEADSTAGES) clampModes = NaN

	CHECK_EQUAL_VAR(DAP_GetHighestActiveHeadstage(panelTitle), NaN)
End

Function HAH_Works1()

	string panelTitle = "IGNORE"
	Make/O/N=(NUM_HEADSTAGES) statusHS = 0
	Make/O/N=(NUM_HEADSTAGES) clampModes = NaN

	statusHS[0] = 1

	CHECK_EQUAL_VAR(DAP_GetHighestActiveHeadstage(panelTitle), 0)
End

Function HAH_Works2()

	string panelTitle = "IGNORE"
	Make/O/N=(NUM_HEADSTAGES) statusHS = 0
	Make/O/N=(NUM_HEADSTAGES) clampModes = NaN

	statusHS[6] = 1

	CHECK_EQUAL_VAR(DAP_GetHighestActiveHeadstage(panelTitle), 6)
End

Function HAH_ChecksClampMode()

	string panelTitle = "IGNORE"
	Make/O/N=(NUM_HEADSTAGES) statusHS = 1
	Make/O/N=(NUM_HEADSTAGES) clampModes = NaN

	try
		DAP_GetHighestActiveHeadstage(panelTitle, clampMode = NaN); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

Function HAH_ReturnsNaNWithClampMode()

	string panelTitle = "IGNORE"
	Make/O/N=(NUM_HEADSTAGES) statusHS = 0
	Make/O/N=(NUM_HEADSTAGES) clampModes = NaN

	CHECK_EQUAL_VAR(DAP_GetHighestActiveHeadstage(panelTitle, clampMode = I_CLAMP_MODE), NaN)
End

Function HAH_WorksWithClampMode1()

	string panelTitle = "IGNORE"
	Make/O/N=(NUM_HEADSTAGES) statusHS = 0
	Make/O/N=(NUM_HEADSTAGES) clampModes = NaN

	statusHS[1, 2] = 1
	clampModes[1] = I_CLAMP_MODE
	CHECK_EQUAL_VAR(DAP_GetHighestActiveHeadstage(panelTitle, clampMode = I_CLAMP_MODE), 1)
End

Function HAH_WorksWithClampMode2()

	string panelTitle = "IGNORE"
	Make/O/N=(NUM_HEADSTAGES) statusHS = 0
	Make/O/N=(NUM_HEADSTAGES) clampModes = NaN

	statusHS[1, 6] = 1
	clampModes[] = I_CLAMP_MODE
	clampModes[6] = V_CLAMP_MODE

	CHECK_EQUAL_VAR(DAP_GetHighestActiveHeadstage(panelTitle, clampMode = V_CLAMP_MODE), 6)
End
/// @}

/// @{
/// HasOneValidEntry

Function HOV_AssertsInvalidType()

	Make/B wv
	try
		HasOneValidEntry(wv)
		FAIL()
	catch
		PASS()
	endtry
End

Function HOV_AssertsOnInvalidType()

	Make/B wv
	try
		HasOneValidEntry(wv)
		FAIL()
	catch
		PASS()
	endtry
End

Function HOV_AssertsOnEmptyWave()

	Make/D/N=0 wv
	try
		HasOneValidEntry(wv)
		FAIL()
	catch
		PASS()
	endtry
End

Function HOV_Works1()

	Make/D/N=10 wv = NaN
	CHECK(!HasOneValidEntry(wv))
End

Function HOV_Works2()

	Make/D/N=10 wv = NaN
	wv[9] = 1
	CHECK(HasOneValidEntry(wv))
End

Function HOV_Works3()

	Make/D/N=10 wv = NaN
	wv[9] = inf
	CHECK(HasOneValidEntry(wv))
End

Function HOV_Works4()

	Make/D/N=10 wv = NaN
	wv[9] = -inf
	CHECK(HasOneValidEntry(wv))
End

Function HOV_WorksWithReal()

	Make/R/N=10 wv = NaN
	wv[9] = -inf
	CHECK(HasOneValidEntry(wv))
End

Function HOV_WorksWith2D()

	Make/R/N=(10, 9) wv = NaN
	wv[2, 3] = 4711
	CHECK(HasOneValidEntry(wv))
End

/// @}

/// @{
/// GetNumFromModifyStr
/// Example string
///
/// AXTYPE:left;AXFLAG:/L=row0_col0_AD_0;CWAVE:trace1;UNITS:pA;CWAVEDF:root:MIES:HardwareDevices:ITC18USB:Device0:Data:X_3:;ISCAT:0;CATWAVE:;CATWAVEDF:;ISTFREE:0;MASTERAXIS:;HOOK:;
/// SETAXISFLAGS:/A=2/E=0/N=0;SETAXISCMD:SetAxis/A=2 row0_col0_AD_0;FONT:Arial;FONTSIZE:10;FONTSTYLE:0;RECREATION:catGap(x)=0.1;barGap(x)=0.1;grid(x)=0;log(x)=0;tick(x)=0;zero(x)=0;mirror(x)=0;
/// nticks(x)=5;font(x)="default";minor(x)=0;sep(x)=5;noLabel(x)=0;fSize(x)=0;fStyle(x)=0;highTrip(x)=10000;lowTrip(x)=0.1;logLabel(x)=3;lblMargin(x)=0;standoff(x)=0;axOffset(x)=0;axThick(x)=1;
/// gridRGB(x)=(24576,24576,65535);notation(x)=0;logTicks(x)=0;logHTrip(x)=10000;logLTrip(x)=0.0001;axRGB(x)=(0,0,0);tlblRGB(x)=(0,0,0);alblRGB(x)=(0,0,0);gridStyle(x)=0;gridHair(x)=2;zeroThick(x)=0;
/// lblPosMode(x)=1;lblPos(x)=0;lblLatPos(x)=0;lblRot(x)=0;lblLineSpacing(x)=0;tkLblRot(x)=0;useTSep(x)=0;ZisZ(x)=0;zapTZ(x)=0;zapLZ(x)=0;loglinear(x)=0;btLen(x)=0;btThick(x)=0;stLen(x)=0;stThick(x)=0;
/// ttLen(x)=0;ttThick(x)=0;ftLen(x)=0;ftThick(x)=0;tlOffset(x)=0;tlLatOffset(x)=0;freePos(x)=0;tickEnab(x)={-inf,inf};tickZap(x)={};axisEnab(x)={0.4478,0.8656};manTick(x)=0;userticks(x)=0;
/// dateInfo(x)={0,0,0};prescaleExp(x)=0;tickExp(x)=0;tickUnit(x)=1;linTkLabel(x)=0;axisOnTop(x)=0;axisEnab(x)={0.447778,0.865556};gridEnab(x)={0,1};mirrorPos(x)=1;
Function GNMS_Works1()

	string str = "abcd(efgh)={123.456}"

	CHECK_EQUAL_VAR(MIES_UTILS#GetNumFromModifyStr(str, "abcd", "{", 0), 123.456)
End

Function GNMS_Works2()

	string str = "abcd(efgh)=(123.456, 789.10)"

	CHECK_EQUAL_VAR(MIES_UTILS#GetNumFromModifyStr(str, "abcd", "(", 1), 789.10)
End

/// @}

/// @{
/// SetNumberInWaveNote
Function SNWN_AbortsOnInvalidWave()

	Wave/Z wv = $""

	try
		SetNumberInWaveNote(wv, "key", 123)
		FAIL()
	catch
		PASS()
	endtry
End

Function SNWN_AbortsOnInvalidKey()

	Make/FREE wv

	try
		SetNumberInWaveNote(wv, "", 123)
		FAIL()
	catch
		PASS()
	endtry
End

Function SNWN_ComplainsOnEmptyFormat()

	Make/FREE wv

	try
		SetNumberInWaveNote(wv, "key", 123, format="")
		FAIL()
	catch
		PASS()
	endtry
End

Function SNWN_Works()

	string expected, actual

	Make/FREE wv
	SetNumberInWaveNote(wv, "key", 123)
	expected = "key:123;"
	actual   = note(wv)
	CHECK_EQUAL_STR(expected, actual)
End

Function SNWN_WorksWithNaN()

	string expected, actual

	Make/FREE wv
	SetNumberInWaveNote(wv, "key", NaN)
	expected = "key:nan;"
	actual   = note(wv)
	CHECK_EQUAL_STR(expected, actual)
End

Function SNWN_LeavesOldEntries()

	string expected, actual, oldEntry

	Make/FREE wv
	// existing entry
	SetNumberInWaveNote(wv, "otherkey", 456)
	oldEntry = note(wv)

	SetNumberInWaveNote(wv, "key", 123)
	expected = oldEntry + "key:123;"
	actual   = note(wv)
	CHECK_EQUAL_STR(expected, actual)
End

Function SNWN_IntegerFormat()

	string expected, actual

	Make/FREE wv
	SetNumberInWaveNote(wv, "key", 123.456, format="%d")
	expected = "key:123;"
	actual   = note(wv)
	CHECK_EQUAL_STR(expected, actual)
End

Function SNWN_FloatFormat()

	string expected, actual

	Make/FREE wv
	SetNumberInWaveNote(wv, "key", 123.456, format="%.1f")
	// %f rounds
	expected = "key:123.5;"
	actual   = note(wv)
	CHECK_EQUAL_STR(expected, actual)
End

Function SNWN_FloatFormatWithZeros()

	string expected, actual

	Make/FREE wv
	SetNumberInWaveNote(wv, "key", 123.1, format="%.06f")
	// %f rounds
	expected = "key:123.100000;"
	actual   = note(wv)
	CHECK_EQUAL_STR(expected, actual)
End

/// @}

/// GetUniqueEntries*
/// @{

Function GUE_WorksWithEmpty()

	Make/N=0 wv

	WAVE/Z result = GetUniqueEntries(wv)
	CHECK_WAVE(result, NUMERIC_WAVE, minorType=FLOAT_WAVE)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 0)
End

Function GUE_WorksWithOne()

	Make/N=1 wv

	WAVE/Z result = GetUniqueEntries(wv)
	CHECK_EQUAL_WAVES(result, wv)
End

Function GUE_RemovesSpecialValues()

	Make/N=3 wv

	wv[1] = Inf
	wv[2] = NaN

	WAVE/Z result = GetUniqueEntries(wv)
	CHECK_WAVE(result, NUMERIC_WAVE, minorType=FLOAT_WAVE)
	CHECK_EQUAL_WAVES(wv, {0})
End

Function GUE_BailsOutWith2D()

	Make/N=(1, 2) wv

	try
		WAVE/Z result = GetUniqueEntries(wv)
		FAIL()
	catch
		PASS()
	endtry
End

Function GUE_WorksWithTextEmpty()

	Make/T/N=0 wv

	WAVE/Z result = GetUniqueEntries(wv)
	CHECK_WAVE(result, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 0)
End

Function GUE_WorksWithTextOne()

	Make/T/N=1 wv

	WAVE/Z result = GetUniqueEntries(wv)
	CHECK_EQUAL_WAVES(result, wv)
End

Function GUE_IgnoresCase()

	Make/T wv = {"a", "A"}

	WAVE/Z result = GetUniqueEntries(wv, caseSensitive=0)
	CHECK_EQUAL_TEXTWAVES(result, {"a"})
End

Function GUE_HandlesCase()

	Make/T wv = {"a", "A"}

	WAVE/Z result = GetUniqueEntries(wv, caseSensitive=1)
	CHECK_EQUAL_TEXTWAVES(result, {"a", "A"})
End

Function GUE_BailsOutWithText2D()

	Make/T/N=(1, 2) wv

	try
		WAVE/Z result = GetUniqueEntries(wv)
		FAIL()
	catch
		PASS()
	endtry
End

Function GUE_ListWorks1()

	string input, expected, result

	input = "a;A;"
	expected = "a;"

	result = GetUniqueTextEntriesFromList(input, caseSensitive=0)
	CHECK_EQUAL_STR(result, expected)
End

Function GUE_ListWorks2()

	string input, expected, result

	input = "a;A;"
	expected = input

	result = GetUniqueTextEntriesFromList(input, caseSensitive=1)
	CHECK_EQUAL_STR(result, expected)
End

Function GUE_ListWorksWithSep()

	string input, expected, result

	input = "a-A-a"
	expected = "a-A-"

	result = GetUniqueTextEntriesFromList(input, caseSensitive=1, sep="-")
	CHECK_EQUAL_STR(result, expected)
End

/// @}

/// GetListOfObjects
/// @{

// This cuts away the temporary folder in which the tests runs
Function/S TrimVolatileFolderName_IGNORE(list)
	string list

	variable pos, i, numEntries
	string str
	string result = ""

	if(strlen(list) == 0)
		return list
	endif

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		str = StringFromList(i, list)

		pos = strsearch(str, ":test", 0)

		if(pos >= 0)
			str = str[pos,inf]
		endif

		result = AddListItem(str, result, ";", inf)
	endfor

	return result
End

Function GetListOfObjectsWorksRE()

	string result, expected

	NewDataFolder/O test

	DFREF dfr = $"test"
	Make dfr:abcd
	Make dfr:efgh

	result = GetListOfObjects(dfr, "a.*", recursive = 0, fullpath = 0)
	result = TrimVolatileFolderName_IGNORE(result)
	expected = "abcd;"
	CHECK_EQUAL_STR(result, expected)

	result = GetListOfObjects(dfr, "a.*", recursive = 1, fullpath = 0)
	result = TrimVolatileFolderName_IGNORE(result)
	expected = "abcd;"
	CHECK_EQUAL_STR(result, expected)

	result = GetListOfObjects(dfr, "a.*", recursive = 1, fullpath = 1)
	result = TrimVolatileFolderName_IGNORE(result)
	expected = ":test:abcd;"
	CHECK_EQUAL_STR(result, expected)

	result = GetListOfObjects(dfr, "a.*", recursive = 0, fullpath = 1)
	result = TrimVolatileFolderName_IGNORE(result)
	expected = ":test:abcd;"
	CHECK_EQUAL_STR(result, expected)
End

Function GetListOfObjectsWorksWC()

	string result, expected

	NewDataFolder/O test
	DFREF dfr = $"test"
	Make dfr:abcd
	Make dfr:efgh

	result = GetListOfObjects(dfr, "a*", recursive = 0, fullpath = 0, exprType = MATCH_WILDCARD)
	result = TrimVolatileFolderName_IGNORE(result)
	expected = "abcd;"
	CHECK_EQUAL_STR(result, expected)

	result = GetListOfObjects(dfr, "a*", recursive = 1, fullpath = 0, exprType = MATCH_WILDCARD)
	result = TrimVolatileFolderName_IGNORE(result)
	expected = "abcd;"
	CHECK_EQUAL_STR(result, expected)

	result = GetListOfObjects(dfr, "a*", recursive = 1, fullpath = 1, exprType = MATCH_WILDCARD)
	result = TrimVolatileFolderName_IGNORE(result)
	expected = ":test:abcd;"
	CHECK_EQUAL_STR(result, expected)

	result = GetListOfObjects(dfr, "a*", recursive = 0, fullpath = 1, exprType = MATCH_WILDCARD)
	result = TrimVolatileFolderName_IGNORE(result)
	expected = ":test:abcd;"
	CHECK_EQUAL_STR(result, expected)
End

Function GetListOfObjectsWorks2()

	string result, expected

	NewDataFolder/O test
	NewDataFolder/O :test:test2

	DFREF dfr = $":test"
	CHECK(DataFolderExistsDFR(dfr))

	Make dfr:wv1
	Make dfr:wv2

	DFREF dfrDeep = $":test:test2"
	CHECK(DataFolderExistsDFR(dfrDeep))

	Make dfrDeep:wv3
	Make dfrDeep:wv4

	result = GetListOfObjects(dfr, ".*", recursive = 0, fullpath = 0)
	result = TrimVolatileFolderName_IGNORE(result)
	expected = "wv1;wv2;"
	CHECK_EQUAL_STR(result, expected)

	result = GetListOfObjects(dfr, ".*", recursive = 1, fullpath = 0)
	result = TrimVolatileFolderName_IGNORE(result)
	expected = "wv1;wv2;wv3;wv4"
	// sort order is implementation defined
	result = SortList(result)
	expected = SortList(expected)
	CHECK_EQUAL_STR(result, expected)

	result = GetListOfObjects(dfr, ".*", recursive = 1, fullpath = 1)
	result = TrimVolatileFolderName_IGNORE(result)
	expected = ":test:wv1;:test:wv2;:test:test2:wv3;:test:test2:wv4;"
	// sort order is implementation defined
	result = SortList(result)
	expected = SortList(expected)
	CHECK_EQUAL_STR(result, expected)

	result = GetListOfObjects(dfr, ".*", recursive = 0, fullpath = 1)
	result = TrimVolatileFolderName_IGNORE(result)
	expected = ":test:wv1;:test:wv2;"
	CHECK_EQUAL_STR(result, expected)
End

Function GetListOfObjectsWorksWithFolder()

	string result, expected

	NewDataFolder/O test1
	NewDataFolder/O :test1:test2
	NewDataFolder/O :test1:test2:test3

	DFREF dfr = $":test1"
	CHECK(DataFolderExistsDFR(dfr))

	DFREF dfrDeep = $":test1:test2"
	CHECK(DataFolderExistsDFR(dfrDeep))

	result = GetListOfObjects(dfr, ".*", recursive = 0, fullpath = 0, typeFlag = COUNTOBJECTS_DATAFOLDER)
	expected = "test2"
	result = SortList(result)
	expected = SortList(expected)
	CHECK_EQUAL_STR(result, expected)

	result = GetListOfObjects(dfr, ".*", recursive = 1, fullpath = 0, typeFlag = COUNTOBJECTS_DATAFOLDER)
	expected = "test2;test3"
	result = SortList(result)
	expected = SortList(expected)
	CHECK_EQUAL_STR(result, expected)

	result = GetListOfObjects(dfr, ".*", recursive = 1, fullpath = 1, typeFlag = COUNTOBJECTS_DATAFOLDER)
	result = TrimVolatileFolderName_IGNORE(result)
	expected = ":test1:test2;:test1:test2:test3"
	result = SortList(result)
	expected = SortList(expected)
	CHECK_EQUAL_STR(result, expected)
End

// Not checked: typeFlag
/// @}

/// @{
/// DeleteWavePoint
Function DWP_InvalidWave()

	WAVE/Z wv = $""
	try
		DeleteWavePoint(wv, ROWS, 0)
		FAIL()
	catch
		PASS()
	endtry
End

Function DWP_InvalidDim()

	variable i

	Make/FREE/N=1 wv
	Make/FREE/N=4 fDims = {-1, 1, 2, 3, 5, NaN, Inf}

	for(i = 0; i < numpnts(fDims); i += 1)
		try
			DeleteWavePoint(wv, fDims[i], 0)
			FAIL()
		catch
			PASS()
		endtry
	endfor
End

Function DWP_InvalidIndex()

	variable i

	Make/FREE/N=1 wv
	Make/FREE/N=4 fInd = {-1, 2, NaN, Inf}

	for(i = 0; i < numpnts(fInd); i += 1)
		try
			DeleteWavePoint(wv, ROWS, fInd[i])
			FAIL()
		catch
			PASS()
		endtry
	endfor
End

Function DWP_DeleteFromEmpty()

	variable i

	Make/FREE/N=0 wv

	try
		DeleteWavePoint(wv, ROWS, 0)
		FAIL()
	catch
		PASS()
	endtry
End

Function DWP_Check1D()

	Make/FREE/N=3 wv = {0, 1, 2}
	DeleteWavePoint(wv, ROWS, 1)
	CHECK_EQUAL_WAVES(wv, {0, 2})
	DeleteWavePoint(wv, ROWS, 1)
	CHECK_EQUAL_WAVES(wv, {0})
	DeleteWavePoint(wv, ROWS, 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 0)
End

Function DWP_Check2D()

	Make/FREE/N=(3, 3) wv
	wv = p + DimSize(wv, COLS) * q
	DeleteWavePoint(wv, ROWS, 1)
	CHECK_EQUAL_WAVES(wv, {{0, 2}, {3, 5}, {6, 8}})
	DeleteWavePoint(wv, ROWS, 1)
	CHECK_EQUAL_WAVES(wv, {{0}, {3}, {6}})
	DeleteWavePoint(wv, ROWS, 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 0)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 3)

	Make/O/FREE/N=(3, 3) wv
	wv = p + DimSize(wv, COLS) * q
	DeleteWavePoint(wv, COLS, 1)
	CHECK_EQUAL_WAVES(wv, {{0, 1, 2}, {6, 7, 8}})
	DeleteWavePoint(wv, COLS, 1)
	CHECK_EQUAL_WAVES(wv, {{0, 1, 2}})
	DeleteWavePoint(wv, COLS, 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 0)
End

Function DWP_Check3D()

	Make/FREE/N=(3, 3, 3) wv
	wv = p + DimSize(wv, COLS) * q + DimSize(wv, COLS) * DimSize(wv, LAYERS) * r
	DeleteWavePoint(wv, ROWS, 1)
	CHECK_EQUAL_WAVES(wv, {{{0, 2}, {3, 5}, {6, 8}}, {{9, 11}, {12, 14}, {15, 17}}, {{18, 20}, {21, 23}, {24, 26}}})
	DeleteWavePoint(wv, ROWS, 1)
	CHECK_EQUAL_WAVES(wv, {{{0}, {3}, {6}}, {{9}, {12}, {15}}, {{18}, {21}, {24}}})
	DeleteWavePoint(wv, ROWS, 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 0)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, LAYERS), 3)

	Make/O/FREE/N=(3, 3, 3) wv
	wv = p + DimSize(wv, COLS) * q + DimSize(wv, COLS) * DimSize(wv, LAYERS) * r
	DeleteWavePoint(wv, COLS, 1)
	CHECK_EQUAL_WAVES(wv, {{{0, 1, 2}, {6, 7, 8}}, {{9, 10, 11}, {15, 16, 17}}, {{18, 19, 20}, {24, 25, 26}}})
	DeleteWavePoint(wv, COLS, 1)
	CHECK_EQUAL_WAVES(wv, {{{0, 1, 2}}, {{9, 10, 11}}, {{18, 19, 20}}})
	DeleteWavePoint(wv, COLS, 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 0)
	CHECK_EQUAL_VAR(DimSize(wv, LAYERS), 3)

	Make/O/FREE/N=(3, 3, 3) wv
	wv = p + DimSize(wv, COLS) * q + DimSize(wv, COLS) * DimSize(wv, LAYERS) * r
	DeleteWavePoint(wv, LAYERS, 1)
	CHECK_EQUAL_WAVES(wv, {{{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}, {{18, 19, 20}, {21, 22, 23}, {24, 25, 26}}})
	DeleteWavePoint(wv, LAYERS, 1)
	CHECK_EQUAL_WAVES(wv, {{{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}})
	DeleteWavePoint(wv, LAYERS, 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, LAYERS), 0)
End

Function DWP_Check4D()

	Make/FREE/N=(3, 3, 3, 3) wv
	wv = p + DimSize(wv, COLS) * q + DimSize(wv, COLS) * DimSize(wv, LAYERS) * r +  + DimSize(wv, COLS) * DimSize(wv, LAYERS) * DimSize(wv, CHUNKS) * s

	DeleteWavePoint(wv, ROWS, 1)
	Make/FREE/N=(2, 3, 3, 3) comp
	comp[][][][0] = {{{0, 2}, {3, 5}, {6, 8}}, {{9, 11}, {12, 14}, {15, 17}}, {{18, 20}, {21, 23}, {24, 26}}}
	comp[][][][1] = {{{27, 29}, {30, 32}, {33, 35}}, {{36, 38}, {39, 41}, {42, 44}}, {{45, 47}, {48, 50}, {51, 53}}}
	comp[][][][2] = {{{54, 56}, {57, 59}, {60, 62}}, {{63, 65}, {66, 68}, {69, 71}}, {{72, 74}, {75, 77}, {78, 80}}}
	CHECK_EQUAL_WAVES(wv, comp)

	DeleteWavePoint(wv, ROWS, 1)
	Make/O/FREE/N=(1, 3, 3, 3) comp
	comp[][][][0] = {{{0}, {3}, {6}}, {{9}, {12}, {15}}, {{18}, {21}, {24}}}
	comp[][][][1] = {{{27}, {30}, {33}}, {{36}, {39}, {42}}, {{45}, {48}, {51}}}
	comp[][][][2] = {{{54}, {57}, {60}}, {{63}, {66}, {69}}, {{72}, {75}, {78}}}
	CHECK_EQUAL_WAVES(wv, comp)

	DeleteWavePoint(wv, ROWS, 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 0)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, LAYERS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, CHUNKS), 3)

	Make/O/FREE/N=(3, 3, 3, 3) wv
	wv = p + DimSize(wv, COLS) * q + DimSize(wv, COLS) * DimSize(wv, LAYERS) * r +  + DimSize(wv, COLS) * DimSize(wv, LAYERS) * DimSize(wv, CHUNKS) * s

	DeleteWavePoint(wv, COLS, 1)
	Make/O/FREE/N=(3, 2, 3, 3) comp
	comp[][][][0] = {{{0, 1, 2}, {6, 7, 8}}, {{9, 10, 11}, {15, 16, 17}}, {{18, 19, 20}, {24, 25, 26}}}
	comp[][][][1] = {{{27, 28, 29}, {33, 34, 35}}, {{36, 37, 38}, {42, 43, 44}}, {{45, 46, 47}, {51, 52, 53}}}
	comp[][][][2] = {{{54, 55, 56}, {60, 61, 62}}, {{63, 64, 65}, {69, 70, 71}}, {{72, 73, 74}, {78, 79, 80}}}
	CHECK_EQUAL_WAVES(wv, comp)

	DeleteWavePoint(wv, COLS, 1)
	Make/O/FREE/N=(3, 1, 3, 3) comp
	comp[][][][0] = {{{0 , 1, 2}}, {{9, 10, 11}}, {{18, 19, 20}}}
	comp[][][][1] = {{{27, 28, 29}}, {{36, 37, 38}}, {{45, 46, 47}}}
	comp[][][][2] = {{{54, 55, 56}}, {{63, 64, 65}}, {{72, 73, 74}}}
	CHECK_EQUAL_WAVES(wv, comp)

	DeleteWavePoint(wv, COLS, 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 0)
	CHECK_EQUAL_VAR(DimSize(wv, LAYERS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, CHUNKS), 3)

	Make/O/FREE/N=(3, 3, 3, 3) wv
	wv = p + DimSize(wv, COLS) * q + DimSize(wv, COLS) * DimSize(wv, LAYERS) * r +  + DimSize(wv, COLS) * DimSize(wv, LAYERS) * DimSize(wv, CHUNKS) * s

	DeleteWavePoint(wv, LAYERS, 1)
	Make/O/FREE/N=(3, 3, 2, 3) comp
	comp[][][][0] = {{{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}, {{18, 19, 20}, {21, 22, 23}, {24, 25, 26}}}
	comp[][][][1] = {{{27, 28, 29}, {30, 31, 32}, {33, 34, 35}}, {{45, 46, 47}, {48, 49, 50}, {51, 52, 53}}}
	comp[][][][2] = {{{54, 55, 56}, {57, 58, 59}, {60, 61, 62}}, {{72, 73, 74}, {75, 76, 77}, {78, 79, 80}}}
	CHECK_EQUAL_WAVES(wv, comp)

	DeleteWavePoint(wv, LAYERS, 1)
	Make/O/FREE/N=(3, 3, 1, 3) comp
	comp[][][][0] = {{{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}}
	comp[][][][1] = {{{27, 28, 29}, {30, 31, 32}, {33, 34, 35}}}
	comp[][][][2] = {{{54, 55, 56}, {57, 58, 59}, {60, 61, 62}}}
	CHECK_EQUAL_WAVES(wv, comp)

	DeleteWavePoint(wv, LAYERS, 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, LAYERS), 0)
	CHECK_EQUAL_VAR(DimSize(wv, CHUNKS), 3)

	Make/O/FREE/N=(3, 3, 3, 3) wv
	wv = p + DimSize(wv, COLS) * q + DimSize(wv, COLS) * DimSize(wv, LAYERS) * r +  + DimSize(wv, COLS) * DimSize(wv, LAYERS) * DimSize(wv, CHUNKS) * s

	DeleteWavePoint(wv, CHUNKS, 1)
	Make/O/FREE/N=(3, 3, 3, 2) comp
	comp[][][][0] = {{{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}, {{9, 10, 11}, {12, 13, 14}, {15, 16, 17}}, {{18, 19, 20}, {21, 22, 23}, {24, 25, 26}}}
	comp[][][][1] = {{{54, 55, 56}, {57, 58, 59}, {60, 61, 62}}, {{63, 64, 65}, {66, 67, 68}, {69, 70, 71}}, {{72, 73, 74}, {75, 76, 77}, {78, 79, 80}}}
	CHECK_EQUAL_WAVES(wv, comp)

	DeleteWavePoint(wv, CHUNKS, 1)
	Make/O/FREE/N=(3, 3, 3, 1) comp
	comp[][][][0] = {{{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}, {{9, 10, 11}, {12, 13, 14}, {15, 16, 17}}, {{18, 19, 20}, {21, 22, 23}, {24, 25, 26}}}
	CHECK_EQUAL_WAVES(wv, comp)

	DeleteWavePoint(wv, CHUNKS, 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, LAYERS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, CHUNKS), 0)
End
/// @}

/// TextWaveToList
/// @{

/// @brief Fail due to null wave
Function TextWaveToListFail0()

	WAVE/T w=$""
	string list

	try
		list = TextWaveToList(w, ";")
		FAIL()
	catch
		PASS()
	endtry
End

/// @brief Fail due to numeric wave
Function TextWaveToListFail1()

	Make/FREE/N=1 w
	string list

	try
		list = TextWaveToList(w, ";")
		FAIL()
	catch
		PASS()
	endtry
End

/// @brief Fail due to 3D+ wave
Function TextWaveToListFail2()

	Make/FREE/T/N=(1,1,1) w
	string list

	try
		list = TextWaveToList(w, ";")
		FAIL()
	catch
		PASS()
	endtry
End

/// @brief Fail due to empty row separator
Function TextWaveToListFail3()

	Make/FREE/T/N=1 w
	string list

	try
		list = TextWaveToList(w, "")
		FAIL()
	catch
		PASS()
	endtry
End

/// @brief Fail due to empty column separator
Function TextWaveToListFail4()

	Make/FREE/T/N=1 w
	string list

	try
		list = TextWaveToList(w, ";", colSep = "")
		FAIL()
	catch
		PASS()
	endtry
End

/// @brief 1D wave zero elements
Function TextWaveToListWorks0()

	Make/FREE/T/N=0 w
	string list
	string refList = ""

	list = TextWaveToList(w, ";")
	CHECK_EQUAL_STR(list, refList)
End

/// @brief 1D wave 3 elements
Function TextWaveToListWorks1()

	Make/FREE/T/N=3 w = {"1", "2", "3"}

	string list
	string refList

	refList = "1;2;3;"
	list = TextWaveToList(w, ";")
	CHECK_EQUAL_STR(list, refList)
End

/// @brief 1D wave 3 elements, stopOnEmpty
Function TextWaveToListWorks2()

	Make/FREE/T/N=3 w = {"1", "", "3"}

	string list
	string refList

	refList = "1;"
	list = TextWaveToList(w, ";", stopOnEmpty = 1)
	CHECK_EQUAL_STR(list, refList)
End

/// @brief 2D wave 3x3 elements
Function TextWaveToListWorks3()

	Make/FREE/T/N=(3,3) w = {{"1", "2", "3"} , {"4", "5", "6"}, {"7", "8", "9"}}

	string list
	string refList

	refList = "1,4,7,;2,5,8,;3,6,9,;"
	list = TextWaveToList(w, ";")
	CHECK_EQUAL_STR(list, refList)
End

/// @brief 2D wave 3x3 elements, own column separator
Function TextWaveToListWorks4()

	Make/FREE/T/N=(3,3) w = {{"1", "2", "3"} , {"4", "5", "6"}, {"7", "8", "9"}}

	string list
	string refList

	refList = "1:4:7:;2:5:8:;3:6:9:;"
	list = TextWaveToList(w, ";", colSep = ":")
	CHECK_EQUAL_STR(list, refList)
End

/// @brief 2D wave 3x3 elements, stopOnEmpty
Function TextWaveToListWorks5()

	Make/FREE/T/N=(3,3) w = {{"", "2", "3"} , {"4", "5", "6"}, {"7", "8", "9"}}

	string list
	string refList

	// stop at first element
	refList = ""
	list = TextWaveToList(w, ";", stopOnEmpty = 1)
	CHECK_EQUAL_STR(list, refList)
	// stop at last element with partial filling
	w = {{"1", "2", "3"} , {"4", "5", "6"}, {"7", "8", ""}}
	refList = "1,4,7,;2,5,8,;3,6,;"
	list = TextWaveToList(w, ";", stopOnEmpty = 1)
	CHECK_EQUAL_STR(list, refList)
   // stop at new row
	w = {{"1", "", "3"} , {"4", "5", "6"}, {"7", "8", "9"}}
	refList = "1,4,7,;"
	list = TextWaveToList(w, ";", stopOnEmpty = 1)
	CHECK_EQUAL_STR(list, refList)
End
/// @}

/// num2strHighPrec
/// @{

/// @brief Fail due to negative precision
Function num2strHighPrecFail0()

	variable err

	try
		num2strHighPrec(NaN, precision = -1)
		FAIL()
	catch
		err = getRTError(1)
		PASS()
	endtry
End

/// @brief Fail due to too high precision
Function num2strHighPrecFail1()

	variable err

	try
		num2strHighPrec(NaN, precision = 16)
		FAIL()
	catch
		err = getRTError(1)
		PASS()
	endtry
End

/// @brief default
Function num2strHighPrecWorks0()

	string sref = "1.66667"
	string s = num2strHighPrec(1.6666666)
	CHECK_EQUAL_STR(s, sref)
End

/// @brief precision 0
Function num2strHighPrecWorks1()

	string sref = "2"
	string s = num2strHighPrec(1.6666666, precision = 0)
	CHECK_EQUAL_STR(s, sref)
End

/// @brief precision 15
Function num2strHighPrecWorks2()

//                  123456789012345
	string sref = "1.666666666666667"
//                              1234567890123456
	string s = num2strHighPrec(1.6666666666666666, precision = 15)
	CHECK_EQUAL_STR(s, sref)
End

/// @brief correct rounding of 1.5 -> 2 and 2.5 -> 2 with precision 0
Function num2strHighPrecWorks3()

	string sref = "2"
	string s = num2strHighPrec(1.5, precision = 0)
	CHECK_EQUAL_STR(s, sref)

	s = num2strHighPrec(2.5, precision = 0)
	CHECK_EQUAL_STR(s, sref)

	sref = "-2"
	s = num2strHighPrec(-2.5, precision = 0)
	CHECK_EQUAL_STR(s, sref)
	s = num2strHighPrec(-1.5, precision = 0)
	CHECK_EQUAL_STR(s, sref)
End

/// @brief special cases nan, inf, -inf
Function num2strHighPrecWorks4()

	string sref = "nan"
	string s = num2strHighPrec(NaN)
	CHECK_EQUAL_STR(s, sref)

	sref = "inf"
	s = num2strHighPrec(Inf)
	CHECK_EQUAL_STR(s, sref)

	sref = "-inf"
	s = num2strHighPrec(-Inf)
	CHECK_EQUAL_STR(s, sref)
End

/// @brief Only real part of complex is returned
Function num2strHighPrecWorks5()

	variable/C c = cmplx(Inf, NaN)
	string sref = "inf"
	string s = num2strHighPrec(c)
	CHECK_EQUAL_STR(s, sref)
End
/// @}

/// ListToTextWaveMD
/// @{

/// @brief Fail due to null string
Function ListToTextWaveMDFail0()
	string uninitialized
	variable err

	try
		WAVE/T t = ListToTextWaveMD(uninitialized, 1)
		FAIL()
	catch
		err = getRTError(1)
		PASS()
	endtry
End

/// @brief Fail due to wrong dims
Function ListToTextWaveMDFail1()
	try
		WAVE/T t = ListToTextWaveMD("", 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		WAVE/T t = ListToTextWaveMD("", 5)
		FAIL()
	catch
		PASS()
	endtry
End

/// @brief empty list to empty wave
Function ListToTextWaveMDWorks10()

	Make/FREE/T/N=0 ref
	WAVE/T t = ListToTextWaveMD("", 1)
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 1D list, default sep
Function ListToTextWaveMDWorks0()

	Make/FREE/T ref = {"1", "2"}
	WAVE/T t = ListToTextWaveMD("1;2;", 1)
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 2D list, default sep
Function ListToTextWaveMDWorks1()

	Make/FREE/T ref = {{"1", "3"} , {"2", "4"}}
	WAVE/T t = ListToTextWaveMD("1,2,;3,4,;", 2)
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 2D list, default sep, short sub list 0
Function ListToTextWaveMDWorks9()

	Make/FREE/T ref = {{"1", "3"} , {"2", ""}}
	WAVE/T t = ListToTextWaveMD("1,2,;3,;", 2)
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 3D list, default sep
Function ListToTextWaveMDWorks2()

	Make/FREE/T ref = {{{"1", "5"} , {"3", "7"}}, {{"2", "6"} , {"4", "8"}}}
	WAVE/T t = ListToTextWaveMD("1:2:,3:4:,;5:6:,7:8:,;", 3)
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 3D list, default sep, short sub list 0
Function ListToTextWaveMDWorks7()

	Make/FREE/T ref = {{{"1", "5"} , {"3", ""}}, {{"2", "6"} , {"4", ""}}}
	WAVE/T t = ListToTextWaveMD("1:2:,3:4:,;5:6:,;", 3)
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 3D list, default sep, short sub list 1
Function ListToTextWaveMDWorks8()

	Make/FREE/T ref = {{{"1", "5"} , {"3", "7"}}, {{"2", "6"} , {"4", ""}}}
	WAVE/T t = ListToTextWaveMD("1:2:,3:4:,;5:6:,7:,;", 3)
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 4D list, default sep
Function ListToTextWaveMDWorks3()

	Make/FREE/T ref = {{{{"1", "9"} , {"5", "13"}}, {{"3", "11"} , {"7", "15"}}}, {{{"2", "10"} , {"6", "14"}}, {{"4", "12"} , {"8", "16"}}}}
	WAVE/T t = ListToTextWaveMD("1/2/:3/4/:,5/6/:7/8/:,;9/10/:11/12/:,13/14/:15/16/:,;", 4)
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 4D list, default sep, short sub list 0
Function ListToTextWaveMDWorks4()

	Make/FREE/T ref = {{{{"1", "9"} , {"5", ""}}, {{"3", "11"} , {"7", ""}}}, {{{"2", "10"} , {"6", ""}}, {{"4", "12"} , {"8", ""}}}}
	WAVE/T t = ListToTextWaveMD("1/2/:3/4/:,5/6/:7/8/:,;9/10/:11/12/:;", 4)
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 4D list, default sep, short sub list 1
Function ListToTextWaveMDWorks5()

	Make/FREE/T ref = {{{{"1", "9"} , {"5", "13"}}, {{"3", "11"} , {"7", ""}}}, {{{"2", "10"} , {"6", "14"}}, {{"4", "12"} , {"8", ""}}}}
	WAVE/T t = ListToTextWaveMD("1/2/:3/4/:,5/6/:7/8/:,;9/10/:11/12/:,13/14/:,;", 4)
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 4D list, default sep, short sub list 2
Function ListToTextWaveMDWorks6()

	Make/FREE/T ref = {{{{"1", "9"} , {"5", "13"}}, {{"3", "11"} , {"7", "15"}}}, {{{"2", "10"} , {"6", "14"}}, {{"4", "12"} , {"8", ""}}}}
	WAVE/T t = ListToTextWaveMD("1/2/:3/4/:,5/6/:7/8/:,;9/10/:11/12/:,13/14/:15/:,;", 4)
	CHECK_EQUAL_WAVES(t, ref)
End
/// @}

/// FloatWithMinSigDigits
/// @{

Function/WAVE InvalidSignDigits()

	Make/FREE digits = {-1, NaN, Inf, -Inf}

	return digits
End

// UTF_TD_GENERATOR InvalidSignDigits
Function FloatWithMinSigDigitsAborts([var])
	variable var
	try
		FloatWithMinSigDigits(1.234, numMinSignDigits = var)
		FAIL()
	catch
		PASS()
	endtry
End

Function FloatWithMinSigDigitsWorks()

	string result, expected

	result = FloatWithMinSigDigits(1.234, numMinSignDigits = 0)
	expected = "1"
	CHECK_EQUAL_STR(result, expected)

	result = FloatWithMinSigDigits(-1.234, numMinSignDigits = 0)
	expected = "-1"
	CHECK_EQUAL_STR(result, expected)

	result = FloatWithMinSigDigits(1e-2, numMinSignDigits = 2)
	expected = "0.01"
	CHECK_EQUAL_STR(result, expected)
End

/// @}

/// DecimateWithMethod
/// @{

Function TestDecimateWithMethodInvalid()

	variable newSize, numRows, decimationFactor, method, err

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows = DimSize(data, ROWS)
	decimationFactor = 2
	method = DECIMATION_MINMAX
	Make/FREE/N=(DimSize(data, ROWS)/2) output

	try
		DecimateWithMethod(data, output, 1, method); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, $"", decimationFactor, method); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod($"", output, decimationFactor, method); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, 0, method); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, inf, method); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, -5); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		Duplicate/FREE output, outputWrong
		Redimension/N=(5) outputWrong
		DecimateWithMethod(data, outputWrong, decimationFactor, method); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, firstRowInp = -1); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, firstRowInp = 100); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastRowInp = -1); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastRowInp = 100); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastRowInp = -1); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastRowInp = 100); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, firstColInp = -1); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, firstColInp = 100); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastColInp = -1); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastColInp = 100); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, factor=$""); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		Make/N=(100) factor
		DecimateWithMethod(data, output, decimationFactor, method, factor=factor); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry
End

Function TestDecimateWithMethodDec1()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows = DimSize(data, ROWS)
	decimationFactor = 8
	method = DECIMATION_MINMAX
	newSize = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 2)
	Make/FREE/D/N=(newSize) output

	Make/FREE refOutput = {10, 800}
	Make/N=(1) factor = {100}

	DecimateWithMethod(data, output, decimationFactor, method, firstRowInp = 1, lastRowInp = 15, firstColInp = 0, lastColInp = 0, factor = factor)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
	print output
	print refoutput
End

Function TestDecimateWithMethodDec2()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows = DimSize(data, ROWS)
	decimationFactor = 2
	method = DECIMATION_MINMAX
	newSize = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 8)
	Make/FREE/D/N=(newSize) output
	Make/D/FREE refOutput = {0.1, 2, 0.3, 4, 0.5, 6, 0.7, 8}

	DecimateWithMethod(data, output, decimationFactor, method)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

Function TestDecimateWithMethodDec3()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows = DimSize(data, ROWS)
	decimationFactor = 4
	method = DECIMATION_MINMAX
	newSize = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 4)
	Make/FREE/D/N=(newSize) output
	Make/D/FREE refOutput = {0.1, 4, 0.5, 8}

	DecimateWithMethod(data, output, decimationFactor, method)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

// decimation does not give a nice new size but it still works
Function TestDecimateWithMethodDec4()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows = DimSize(data, ROWS)
	decimationFactor = 3
	method = DECIMATION_MINMAX
	newSize = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 6)
	Make/FREE/D/N=(newSize) output
	Make/D/FREE refOutput = {0.1, 3, 0.4, 6, 0.7, 8}

	DecimateWithMethod(data, output, decimationFactor, method)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

// decimation so large that only two points remain
Function TestDecimateWithMethodDec5()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows = DimSize(data, ROWS)
	decimationFactor = 1000
	method = DECIMATION_MINMAX
	newSize = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 2)
	Make/FREE/D/N=(newSize) output
	Make/D/FREE refOutput = {0.1, 8}

	DecimateWithMethod(data, output, decimationFactor, method)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

// respects columns
Function TestDecimateWithMethodDec6()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}}
	numRows = DimSize(data, ROWS)
	decimationFactor = 4
	method = DECIMATION_MINMAX
	newSize = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 4)
	Make/D/N=(newSize, 2) output
	Make/D/FREE refOutput = {{0, 0, 0, 0}, {0.1, 4, 0.5, 8}}

	DecimateWithMethod(data, output, decimationFactor, method, firstColInp = 1)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

// respects factor and has different output column
Function TestDecimateWithMethodDec7()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}}
	numRows = DimSize(data, ROWS)
	decimationFactor = 4
	method = DECIMATION_MINMAX
	newSize = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 4)
	Make/D/N=(newSize, 2) output = {{-10, -400, -50, -800}, {2, 2, 2, 2}}
	// factor leaves first column untouched
	Make/D/FREE refOutput = {{-10, -400, -50, -800}, {2, 2, 2, 2}}
	Make/N=(1) factor = {-100}

	DecimateWithMethod(data, output, decimationFactor, method, factor=factor, firstColInp = 1, firstColOut = 0, lastColOut = 0)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

// works with doing it in chunks
Function TestDecimateWithMethodDec8()

	variable newSize, numRows, decimationFactor, method, i

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows = DimSize(data, ROWS)
	decimationFactor = 4
	method = DECIMATION_MINMAX
	newSize = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 4)
	Make/FREE/D/N=(newSize) output
	Make/D/FREE refOutput = {0.1, 4, 0.5, 8}

	Make/FREE chunks = {{0, 2}, {3, 8}, {9, 15}}

	for(i = 0; i < DimSize(chunks, COLS); i += 1)
		DecimateWithMethod(data, output, decimationFactor, method, firstRowInp = chunks[0][i], lastRowInp = chunks[1][i])
		switch(i)
			case 0:
				CHECK_EQUAL_WAVES(output, {0.1, 1, 0, 0}, mode = WAVE_DATA, tol=1e-10)
				break
			case 1:
				CHECK_EQUAL_WAVES(output, {0.1, 4, 0.5, 0.5}, mode = WAVE_DATA, tol=1e-10)
				break
			case 2:
				CHECK_EQUAL_WAVES(output, {0.1, 4, 0.5, 8}, mode = WAVE_DATA, tol=1e-10)
				break
			default:
				FAIL()
		endswitch
	endfor

	CHECK_EQUAL_VAR(i, DimSize(chunks, COLS))
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

/// @}

/// GetNotebookText/ReplaceNotebookText
/// @{

Function GNT_Works()

	string expected, result
	string win = "nb0"
	expected = "abcd 123"

	KillWindow/Z $win

	NewNotebook/N=$win/F=0
	Notebook $win, setData=expected

	result = GetNotebookText("nb0")
	CHECK_EQUAL_STR(expected, result)

	expected = "hi there!"
	ReplaceNotebookText(win, expected)
	result = GetNotebookText("nb0")
	CHECK_EQUAL_STR(expected, result)
End

/// @}

/// RestoreCursors
/// @{

Function RC_WorksWithReplacementTrace()

	string info, graph

	Make data

	Display data
	graph = S_name

	Cursor A, data, 30
	WAVE/T cursorInfos = GetCursorInfos(graph)

	RemoveTracesFromGraph(graph)

	AppendToGraph data/TN=abcd
	RestoreCursors(graph, cursorInfos)

	info = CsrInfo(A, graph)
	CHECK_PROPER_STR(info)
End

/// @}

/// MoveWaveWithOverwrite
/// @{

Function MWWO_RequiresPermanentDestWave()

	variable err

	Make/FREE dest, src

	try
		MoveWaveWithOverwrite(dest, src)
		FAIL()
	catch
		err = GetRtError(1)
		PASS()
	endtry
End

Function MWWO_RequiresDistinctWaves()

	variable err

	Make wv

	try
		MoveWaveWithOverwrite(wv, wv)
		FAIL()
	catch
		err = GetRtError(1)
		PASS()
	endtry
End

Function MWWO_Works()

	Make dest = p
	Make src = 0

	MoveWaveWithOverwrite(dest, src)

	WAVE dest
	CHECK_EQUAL_VAR(Sum(dest), 0)
	WAVE/Z src
	CHECK_WAVE(src, NULL_WAVE)
End

Function MWWO_WorksWithFreeSource()

	Make dest = p
	Make/FREE src = 0

	MoveWaveWithOverwrite(dest, src)

	WAVE dest
	CHECK_EQUAL_VAR(Sum(dest), 0)
	WAVE/Z src
	CHECK_WAVE(src, NULL_WAVE)
End

Function MWWO_HandlesLockedDest()

	Make dest = p
	Make src = 0

	Display dest

	MoveWaveWithOverwrite(dest, src)

	WAVE dest
	CHECK_EQUAL_VAR(Sum(dest), 0)
	WAVE/Z src
	CHECK_WAVE(src, NULL_WAVE)
End

Function MWWO_RecursiveWorks()
	variable err

	Make/WAVE/N=2 dest
	Make/D dest0 =   p
	Make/D dest1 = 2*p

	dest[0] = dest0
	dest[1] = dest1

	Make/WAVE/N=2 src
	Make src0 = -1
	Make src1 = -2

	src[0] = src0
	src[1] = src1

	MoveWaveWithOverwrite(dest, src, recursive = 1)

	// now we have the waves referenced in src
	// at the same locations as they were in dest
	WAVE/Z src, src0, src1
	CHECK_WAVE(src, NULL_WAVE)
	CHECK_WAVE(src0, NULL_WAVE)
	CHECK_WAVE(src1, NULL_WAVE)

	WAVE/Z dest, dest0, dest1
	CHECK_WAVE(dest, WAVE_WAVE | NORMAL_WAVE)
	CHECK_WAVE(dest0, NORMAL_WAVE, minorType = FLOAT_WAVE)
	CHECK_WAVE(dest1, NORMAL_WAVE, minorType = FLOAT_WAVE)

	CHECK_EQUAL_VAR(Sum(dest0), -128)
	CHECK_EQUAL_VAR(Sum(dest1), -256)
End

/// @}

/// FindLevelWrapper
/// @{

Function FLW_RequiresNumericWave()

	try
		Make/T/FREE data
		FindLevelWrapper(data, FINDLEVEL_EDGE_BOTH, 0.1, FINDLEVEL_MODE_SINGLE)
		FAIL()
	catch
		PASS()
	endtry
End

Function/WAVE InfiniteValues()

	Make/FREE wv = {NaN, Inf, -Inf}

	SetDimLabel ROWS, 0, $"NaN", wv
	SetDimLabel ROWS, 1, $"Inf", wv
	SetDimLabel ROWS, 2, $"-Inf", wv

	return wv
End

// UTF_TD_GENERATOR InfiniteValues
Function FLW_RequiresFiniteLevel([var])
	variable var

	try
		Make/FREE data
		FindLevelWrapper(data, FINDLEVEL_EDGE_BOTH, var, FINDLEVEL_MODE_SINGLE)
		FAIL()
	catch
		PASS()
	endtry
End

Function FLW_Requires2DWave()

	try
		Make/FREE/N=(10, 20, 30) data
		FindLevelWrapper(data, FINDLEVEL_EDGE_BOTH, 0.1, FINDLEVEL_MODE_SINGLE)
		FAIL()
	catch
		PASS()
	endtry
End

Function FLW_RequiresBigEnoughWave()

	try
		Make/FREE/N=(1) data
		FindLevelWrapper(data, FINDLEVEL_EDGE_BOTH, 0.1, FINDLEVEL_MODE_SINGLE)
		FAIL()
	catch
		PASS()
	endtry
End

Function/WAVE FLW_SampleData()

	Make/FREE data1 = {10, 20, 30, 40}
	SetScale/P x, 4, 0.5, data1
	SetNumberInWaveNote(data1, "edge", FINDLEVEL_EDGE_INCREASING)
	SetNumberInWaveNote(data1, "level", 15)

	Make/FREE data2 = {10, 20, 30, 10}
	SetScale/P x, -4, 0.5, data2
	SetNumberInWaveNote(data2, "edge", FINDLEVEL_EDGE_DECREASING)
	SetNumberInWaveNote(data2, "level", 11)

	Make/FREE data3 = {{10, 20}, {10, 15}, {10, 5}}
	SetScale/P x, 4, -0.5, data3
	SetNumberInWaveNote(data3, "edge", FINDLEVEL_EDGE_INCREASING)
	SetNumberInWaveNote(data3, "level", 14)

	Make/FREE data4 = {{10, 20}, {10, 15}, {10, 5}}
	SetScale/P x, 4, -0.5, data4
	SetNumberInWaveNote(data4, "edge", FINDLEVEL_EDGE_DECREASING)
	SetNumberInWaveNote(data4, "level", 11)

	Make/FREE data5 = {{10, 20}, {10, 15}, {10, 5}}
	SetScale/P x, 4, -0.5, data5
	SetNumberInWaveNote(data5, "edge", FINDLEVEL_EDGE_BOTH)
	SetNumberInWaveNote(data5, "level", 11)

	Make/FREE data6 = {{10, 20, 30, 40, 50, 60}, {10, 15, 10, 15, 10, 15}, {10, 5, 10, 5, 10, 5}}
	SetScale/P x, 4, -0.5, data6
	SetNumberInWaveNote(data6, "edge", FINDLEVEL_EDGE_BOTH)
	SetNumberInWaveNote(data6, "level", 11)

	Make/WAVE/FREE result = {data1, data2, data3, data4, data5, data6}

	return result
End

// UTF_TD_GENERATOR FLW_SampleData
Function FLW_SameResultsAsFindLevelSingle([wv])
	WAVE wv

	variable i, edge, level, numCols

	edge = GetNumberFromWaveNote(wv, "edge")
	level = GetNumberFromWaveNote(wv, "level")

	numCols = max(1, DimSize(wv, COLS))

	Duplicate/FREE wv, wvCopy

	WAVE result = FindLevelWrapper(wv, level, edge, FINDLEVEL_MODE_SINGLE)
	CHECK_EQUAL_WAVES(wv, wvCopy)

	for(i = 0; i < numCols; i += 1)
		Duplicate/FREE/RMD=[][i, i] wv, singleColum

		FindLevel/Q/EDGE=(edge) singleColum, level
		CHECK_EQUAL_VAR(result[i], V_LevelX)
		CHECK_EQUAL_VAR(str2num(GetDimLabel(result, ROWS, i)), 1)
	endfor
End

// Returns a wave reference wave with each entry holding a wave reference wave
Function/WAVE FLW_SampleDataMulti()

	WAVE/WAVE sampleData = FLW_SampleData()

	// Attach the results
	Make/FREE/D result1 = {4.25}
	SetDimLabel ROWS, 0, $"1", result1

	Make/FREE/D result2 = {-2.525}
	SetDimLabel ROWS, 0, $"1", result2

	Make/FREE/D result3 = {3.8, 3.6, NaN}
	SetDimLabel ROWS, 0, $"1", result3
	SetDimLabel ROWS, 1, $"1", result3
	SetDimLabel ROWS, 2, $"0", result3

	Make/FREE/D result4 = {NaN,NaN,NaN}
	SetDimLabel ROWS, 0, $"0", result4
	SetDimLabel ROWS, 1, $"0", result4
	SetDimLabel ROWS, 2, $"0", result4

	Make/FREE/D result5 = {3.95,3.9,NaN}
	SetDimLabel ROWS, 0, $"1", result5
	SetDimLabel ROWS, 1, $"1", result5
	SetDimLabel ROWS, 2, $"0", result5

	Make/FREE/D/N=(3, 5) result6
	result6[0][0]= {3.95,3.9,NaN}
	result6[0][1]= {NaN,3.1,NaN}
	result6[0][2]= {NaN,2.9,NaN}
	result6[0][3]= {NaN,2.1,NaN}
	result6[0][4]= {NaN,1.9,NaN}
	SetDimLabel ROWS, 0, $"1", result6
	SetDimLabel ROWS, 1, $"5", result6
	SetDimLabel ROWS, 2, $"0", result6

	Make/FREE/WAVE pairs1 = {sampleData[0], result1}
	Make/FREE/WAVE pairs2 = {sampleData[1], result2}
	Make/FREE/WAVE pairs3 = {sampleData[2], result3}
	Make/FREE/WAVE pairs4 = {sampleData[3], result4}
	Make/FREE/WAVE pairs5 = {sampleData[4], result5}
	Make/FREE/WAVE pairs6 = {sampleData[5], result6}

	Make/FREE/WAVE sampleDataMulti = {pairs1, pairs2, pairs3, pairs4, pairs5, pairs6}

	return sampleDataMulti
End

// UTF_TD_GENERATOR FLW_SampleDataMulti
Function FLW_MultiWorks([wv])
	WAVE wv

	variable i, edge, level

	WAVE/WAVE wvWave = wv

	WAVE data      = wvWave[0]
	WAVE resultRef = wvWave[1]

	edge = GetNumberFromWaveNote(data, "edge")
	level = GetNumberFromWaveNote(data, "level")

	Duplicate/FREE data, dataCopy

	WAVE result = FindLevelWrapper(data, level, edge, FINDLEVEL_MODE_MULTI)
	CHECK_EQUAL_WAVES(data, dataCopy)
	CHECK_EQUAL_WAVES(result, resultRef, tol=1e-8)
End

/// @}

// FileRoutines
/// @{

Function FR_FileExistsWorks()

	CHECK(FileExists(FunctionPath("")))
	CHECK(!FileExists("C:\\I_DON_EXIST"))
	CHECK(!FileExists("C:\\"))
End

Function FR_FolderExistsWorks()

	CHECK(!FolderExists(FunctionPath("")))
	CHECK(!FolderExists("C:\\I_DON_EXIST"))
	CHECK(FolderExists("C:\\"))
End

Function FR_WorksWithAliasFiles()

	string target, alias
	string expected, ref

	// alias is a folder
	target = 	GetFolder(FunctionPath(""))
	alias  = GetFolder(target) + "alias"
	CreateAliasShortCut target as alias
	CHECK(!V_flag)
	CHECK(!FileExists(S_path))
	CHECK(FolderExists(S_path))

	expected = target
	ref = ResolveAlias(S_path)
	CHECK_EQUAL_STR(expected, ref)

	// alias is a file
	target = 	FunctionPath("")
	alias  = GetFolder(target) + "alias.ipf"
	CreateAliasShortCut/Z target as alias
	CHECK(!V_flag)
	CHECK(FileExists(S_path))
	CHECK(!FolderExists(S_path))

	expected = target
	ref = ResolveAlias(S_path)
	CHECK_EQUAL_STR(expected, ref)
End

/// @}

/// ScaleToIndexWrapper
/// @{

Function STIW_TestDimensions()
	Make testwave

	SetScale/P x, 0, 0.1, testwave
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testwave, 0, ROWS), ScaleToIndex(testWave, 0, ROWS))
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testwave, 1, ROWS), ScaleToIndex(testWave, 1, ROWS))
	SetScale/P y, 0, 0.01, testwave
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testwave, 0, COLS), ScaleToIndex(testWave, 0, COLS))
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testwave, 1, COLS), ScaleToIndex(testWave, 1, COLS))
	SetScale/P z, 0, 0.001, testwave
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testwave, 0, LAYERS), ScaleToIndex(testWave, 0, LAYERS))
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testwave, 1, LAYERS), ScaleToIndex(testWave, 1, LAYERS))
	SetScale/P t, 0, 0.0001, testwave
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testwave, 0, CHUNKS), ScaleToIndex(testWave, 0, CHUNKS))
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testwave, 0.1, CHUNKS), ScaleToIndex(testWave, 0.1, CHUNKS))

	REQUIRE_EQUAL_VAR(ScaleToIndex(testWave, -1, ROWS), DimOffset(testwave, ROWS) - 1 / DimDelta(testwave, ROWS))
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testWave, -1, ROWS), 0)
#if (NumberByKey("BUILD", IgorInfo(0)) < 36039)
	REQUIRE_EQUAL_VAR(ScaleToIndex(testWave, -inf, ROWS), DimSize(testwave, ROWS) - 1)
#else
	REQUIRE_EQUAL_VAR(ScaleToIndex(testWave, -inf, ROWS), NaN)
#endif
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testWave, -inf, ROWS), 0)

	REQUIRE_EQUAL_VAR(ScaleToIndex(testWave, 1e3, ROWS), DimOffset(testwave, ROWS) + 1e3 / DimDelta(testwave, ROWS))
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testWave, 1e3, ROWS), DimSize(testwave, ROWS) - 1)
	REQUIRE_EQUAL_VAR(ScaleToIndex(testWave, inf, ROWS), ScaleToIndexWrapper(testWave, inf, ROWS))

	SetScale/P x, 0, -0.1, testwave
	REQUIRE_EQUAL_VAR(ScaleToIndex(testWave, -1, ROWS), DimOffset(testwave, ROWS) - 1 / DimDelta(testwave, ROWS))
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testWave, 1, ROWS), 0)
#if (NumberByKey("BUILD", IgorInfo(0)) < 36039)
	REQUIRE_EQUAL_VAR(ScaleToIndex(testWave, -inf, ROWS), ScaleToIndexWrapper(testWave, -inf, ROWS))
#endif
	REQUIRE_EQUAL_VAR(ScaleToIndex(testWave, 1, ROWS), DimOffset(testwave, ROWS) + 1 / DimDelta(testwave, ROWS))
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testWave, 1, ROWS), 0)
	REQUIRE_EQUAL_VAR(ScaleToIndex(testWave, inf, ROWS), DimSize(testwave, ROWS) - 1)
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testWave, inf, ROWS), 0)
End

Function/WAVE STIW_TestAbortGetter()
	Make/D/FREE data = {4, -1, 0.1, NaN, Inf, -Inf}
	return data
End

// UTF_TD_GENERATOR STIW_TestAbortGetter
Function STIW_TestAbort([var])
	variable var

	variable err

	Make testwave
	SetScale/P x, 0, 0.1, testwave

	try
		ScaleToIndexWrapper(testwave, 0, var); AbortOnRTE
		FAIL()
	catch
		err = GetRtError(1)
		PASS()
	endtry
End

/// @}

/// MiesUtils XOP functions
/// @{

Function RunningInMainThread_Thread()

	make/FREE data
	multithread data = MU_RunningInMainThread()
	CHECK_EQUAL_VAR(Sum(data), 0)
End

Function RunningInMainThread_Main()

	make/FREE data
	data = MU_RunningInMainThread()
	CHECK_EQUAL_VAR(Sum(data), 128)
End

/// @}

/// HexToNumber, NumberToHex, HexToBinary
/// @{

Function HexAndNumbersWorks()
	string str, expected

	CHECK_EQUAL_VAR(HexToNumber("0a"), 10)
	CHECK_EQUAL_VAR(HexToNumber("0f"), 15)
	CHECK_EQUAL_VAR(HexToNumber("00"), 0)
	CHECK_EQUAL_VAR(HexToNumber("ff"), 255)

	str = NumberToHex(0)
	expected = "00"
	CHECK_EQUAL_STR(str, expected)

	str = NumberToHex(10)
	expected = "0a"
	CHECK_EQUAL_STR(str, expected)

	str = NumberToHex(15)
	expected = "0f"
	CHECK_EQUAL_STR(str, expected)

	str = NumberToHex(255)
	expected = "ff"
	CHECK_EQUAL_STR(str, expected)

	CHECK_EQUAL_WAVES(HexToBinary("ff000110"), {255, 0, 16, 1}, mode=WAVE_DATA)
End

Function CheckUUIDs()

	Make/FREE/T/N=128 data = GenerateRFC4122UUID()

	// check correct size
	Make/FREE/N=128 sizes = strlen(data[p])
	Make/FREE/N=128 refSizes = 36
	CHECK_EQUAL_WAVES(sizes, refSizes)

	// no duplicates
	FindDuplicates/Z/DT=dups/FREE data
	CHECK_EQUAL_VAR(DimSize(dups, ROWS), 0)

	// correct format
	Make/FREE/N=128 checkFormat = GrepString(data[p], "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
	CHECK_EQUAL_VAR(Sum(checkFormat), 128)
End

/// @}

/// LineBreakingIntoPar
/// @{

Function/WAVE LBP_NonFiniteValues()
	Make/D/FREE data = {NaN, Inf, -Inf}
	return data
End

// UTF_TD_GENERATOR LBP_NonFiniteValues
Function LBP_Aborts([var])
	variable var

	try
		LineBreakingIntoPar("", minimumWidth=var); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

Function LBP_Works()
	string str, expected

	str = LineBreakingIntoPar("abcd efgh 123 one two\tfour")
	expected = "abcd\refgh 123\rone\rtwo\rfour"
	CHECK_EQUAL_STR(str, expected)

	str = LineBreakingIntoPar("abcd efgh 123 one two\tfour", minimumWidth = 10)
	expected = "abcd efgh 123\rone two\tfour"
	CHECK_EQUAL_STR(str, expected)
End

/// @}

/// GetSettingsJSONid
/// @{

Function GSJIWorks()

	NVAR/Z jsonID = $GetSettingsJSONid()
	CHECK(NVAR_Exists(jsonID))
	CHECK(JSON_Exists(jsonID, ""))
End

Function GSJIWorksWithCorruptID()

	NVAR/Z jsonID = $GetSettingsJSONid()
	CHECK(NVAR_Exists(jsonID))

	// close the JSON document to fake an invalid ID
	JSON_Release(jsonID)

	// fetching again now returns a valid ID again
	NVAR/Z jsonID = $GetSettingsJSONid()
	CHECK(NVAR_Exists(jsonID))
	CHECK(JSON_Exists(jsonID, ""))
End

/// @}

/// NumericWaveToList
/// @{

Function NWLWorks()

	string expected, result

	Make/FREE dataFP = {1, 1e6, -inf, 1.5, NaN}
	result = NumericWaveToList(dataFP, ";")
	expected = "1;1e+06;-inf;1.5;nan;"
	CHECK_EQUAL_STR(result, expected)

	Make/FREE/I dataInt = {1, 1e6, -100}
	result = NumericWaveToList(dataInt, ";", format="%d")
	expected = "1;1000000;-100;"
	CHECK_EQUAL_STR(result, expected)

	Make/FREE/N=0 dataEmpty
	result = NumericWaveToList(dataEmpty, ";")
	CHECK_EMPTY_STR(result)
End

Function NWLChecksInput()

	try
		Make/FREE/DF wrongWaveType
		NumericWaveToList(wrongWaveType, ";"); AbortONRTE
		FAIL()
	catch
		PASS()
	endtry

	try
		Make/FREE/D/N=(2, 2) TwoDWave
		NumericWaveToList(TwoDWave, ";"); AbortONRTE
		FAIL()
	catch
		PASS()
	endtry

	// asserts out when triggering IP bug
	try
		Make/D/N=(2) input
		NumericWaveToList(input, ";", format="%d"); AbortONRTE
		FAIL()
	catch
		PASS()
	endtry
End

/// @}

/// Backup functions
/// - CreateBackupWave
/// - CreateBackupWavesForAll
/// - GetBackupWave
/// - ReplaceWaveWithBackup
/// - ReplaceWaveWithBackupForAll
/// @{

Function CreateBackupWaveChecksArgs()

	// asserts out when passing a free wave
	try
		Make/FREE wv
		CreateBackupWave(wv)
		FAIL()
	catch
		PASS()
	endtry
End

Function CreateBackupWaveBasics()
	Make data
	WAVE/Z bak = CreateBackupWave(data)
	CHECK_WAVE(bak, NORMAL_WAVE)
	CHECK_EQUAL_WAVES(bak, data)
End

Function CreateBackupWaveCorrectNaming()

	string actual, expected

	Make data
	WAVE/Z bak = CreateBackupWave(data)

	// naming is correct
	actual   = NameOfWave(bak)
	expected = "data_bak"
	CHECK_EQUAL_STR(actual, expected)
End

Function CreateBackupWaveNoUnwantedRecreation()

	variable modCount

	// does not recreate it when called again
	Make data
	WAVE/Z bak = CreateBackupWave(data)
	modCount = WaveModCount(bak)

	WAVE/Z bakAgain = CreateBackupWave(data)

	CHECK_WAVE(bakAgain, NORMAL_WAVE)
	CHECK(WaveRefsEqual(bak, bakAgain))
	CHECK_EQUAL_VAR(modCount, WaveModCount(bakAgain))
End

Function CreateBackupWaveAllowsForcingRecreation()

	variable modCount

	// except when we force it
	Make data
	WAVE/Z bak = CreateBackupWave(data)
	modCount = WaveModCount(bak)

	WAVE/Z bakAgain = CreateBackupWave(data, forceCreation = 1)

	CHECK(WaveModCount(bakAgain) > modCount)
End

Function/DF PrepareFolderForBackup_IGNORE()

	variable numElements
	NewDataFolder folder
	Make :folder:data1 = p
	Make :folder:data2 = P^2
	string/G :folder:str
	variable/G :folder:var
	NewDataFolder :folder:test

	DFREF dfr = $"folder"
	return dfr
End

Function CountElementsInFolder_IGNORE(DFREF dfr)
	return CountObjectsDFR(dfr, COUNTOBJECTS_WAVES) + CountObjectsDFR(dfr, COUNTOBJECTS_VAR)        \
		   + CountObjectsDFR(dfr, COUNTOBJECTS_STR) + CountObjectsDFR(dfr, COUNTOBJECTS_DATAFOLDER)
End

Function CreateBackupWaveForAllWorks()

	DFREF dfr = PrepareFolderForBackup_IGNORE()
	variable numElements = CountElementsInFolder_IGNORE(dfr)

	CreateBackupWavesForAll(dfr)

	CHECK_EQUAL_VAR(CountElementsInFolder_IGNORE(dfr), numElements + 2)

	WAVE/Z/SDFR=folder data1_bak
	WAVE/Z/SDFR=folder data2_bak
	CHECK_WAVE(data1_bak, NORMAL_WAVE)
	CHECK_WAVE(data2_bak, NORMAL_WAVE)
End

Function GetBackupWaveChecksArgs()

	// asserts out when passing a free wave
	try
		Make/FREE wv
		GetBackupWave(wv)
		FAIL()
	catch
		PASS()
	endtry
End

Function GetBackupWaveMightReturnNull()

	Make data
	WAVE/Z bak = GetBackupWave(data)
	CHECK_WAVE(bak, NULL_WAVE)
End

Function GetBackupWaveWorks()

	Make data
	WAVE/Z bak1 = CreateBackupWave(data)
	WAVE/Z bak2 = GetBackupWave(data)

	CHECK_WAVE(bak1, NORMAL_WAVE)
	CHECK_WAVE(bak2, NORMAL_WAVE)
	CHECK(WaveRefsEqual(bak1, bak2))
End

Function ReplaceWaveWithBackupWorks()

	variable originalSum

	Make data = p
	CreateBackupWave(data)
	originalSum = Sum(data)
	data = 0

	CHECK_EQUAL_VAR(Sum(data), 0)

	WAVE/Z dataOrig = ReplaceWaveWithBackup(data)
	CHECK_WAVE(dataOrig, NORMAL_WAVE)
	CHECK_EQUAL_VAR(Sum(dataOrig), originalSum)
	CHECK(WaveRefsEqual(data, dataOrig))
End

Function ReplaceWaveWithBackupNonExistingBackupIsFatal()

	// backups are required by default
	try
		Make data
		ReplaceWaveWithBackup(data)
		FAIL()
	catch
		PASS()
	endtry
End

Function 	ReplaceWaveWithBackupNonExistingBackupIsOkay()

	// but that can be turned off
	Make data
	WAVE/Z bak = ReplaceWaveWithBackup(data, nonExistingBackupIsFatal = 0)
	CHECK_WAVE(bak, NULL_WAVE)
End

Function ReplaceWaveWithBackupRemoval()

	Make data
	CreateBackupWave(data)
	ReplaceWaveWithBackup(data)

	// by default the backup is removed
	WAVE/Z bak = GetBackupWave(data)
	CHECK_WAVE(bak, NULL_WAVE)
End

Function ReplaceWaveWithBackupKeeping()

	Make data

	// but that can be turned off
	CreateBackupWave(data)
	ReplaceWaveWithBackup(data, keepBackup = 1)
	WAVE/Z bak = GetBackupWave(data)
	CHECK_WAVE(bak, NORMAL_WAVE)
End

Function ReplaceWaveWithBackupForAllNonFatal()

	DFREF dfr = PrepareFolderForBackup_IGNORE()
	variable numElements = CountElementsInFolder_IGNORE(dfr)
	ReplaceWaveWithBackupForAll(dfr)
	CHECK_EQUAL_VAR(CountElementsInFolder_IGNORE(dfr), numElements)
End

Function ReplaceWaveWithBackupForAllWorks()

	variable originalSum1, originalSum2

	DFREF dfr = PrepareFolderForBackup_IGNORE()
	variable numElements = CountElementsInFolder_IGNORE(dfr)

	WAVE/SDFR=dfr data1

	WAVE/SDFR=dfr data1
	originalSum1	= Sum(data1)

	WAVE/SDFR=dfr data2
	originalSum2	= Sum(data2)

	CreateBackupWavesForAll(dfr)

	data1 = 0
	data2 = 0
	CHECK_EQUAL_VAR(Sum(data1), 0)
	CHECK_EQUAL_VAR(Sum(data2), 0)

	ReplaceWaveWithBackupForAll(dfr)

	WAVE/SDFR=dfr data1_restored = data1
	WAVE/SDFR=dfr data2_restored = data2
	CHECK_EQUAL_VAR(Sum(data1_restored), originalSum1)
	CHECK_EQUAL_VAR(Sum(data2_restored), originalSum2)

	// backup waves are kept
	CHECK_EQUAL_VAR(CountElementsInFolder_IGNORE(dfr), numElements + 2)
End

/// @}

/// SelectWave
/// @{

Function/WAVE SW_TrueValues()
	Make/D/FREE data = {1, Inf, -Inf, 1e-15, -1, NaN}
	return data
End

Function/WAVE SW_FalseValues()
	Make/D/FREE data = {0}
	return data
End

// UTF_TD_GENERATOR SW_TrueValues
Function SW_WorksWithTrue([var])
	variable var

	Make/FREE a, b
	WAVE/Z trueWave = SelectWave(var, a, b)
	CHECK_WAVE(trueWave, FREE_WAVE)
	CHECK(WaveRefsEqual(trueWave, b))
End

// UTF_TD_GENERATOR SW_FalseValues
Function SW_WorksWithFalse([var])
	variable var

	Make/FREE a, b
	WAVE/Z falseWave = SelectWave(var, a, b)
	CHECK_WAVE(falseWave, FREE_WAVE)
	CHECK(WaveRefsEqual(falseWave, a))
End

/// @}

/// DistributeElements
/// @{

Function DE_Basics()

	WAVE/Z start, stop
	[start, stop] = DistributeElements(2)
	CHECK_WAVE(start, NUMERIC_WAVE, minorType=DOUBLE_WAVE)
	CHECK_WAVE(stop, NUMERIC_WAVE, minorType=DOUBLE_WAVE)

	CHECK_EQUAL_WAVES(start, {0.0, 0.515}, mode = WAVE_DATA, tol=1e-8)
	CHECK_EQUAL_WAVES(stop,  {0.485, 1.0}, mode = WAVE_DATA, tol=1e-8)
End

Function DE_OffsetWorks()

	variable offset = 0.01

	WAVE/Z start, stop
	[start, stop] = DistributeElements(2, offset = offset)
	CHECK_WAVE(start, NUMERIC_WAVE, minorType=DOUBLE_WAVE)
	CHECK_WAVE(stop, NUMERIC_WAVE, minorType=DOUBLE_WAVE)

	CHECK_EQUAL_WAVES(start, {0.01, 0.52}, mode = WAVE_DATA, tol=1e-8)
	CHECK_EQUAL_WAVES(stop,  {0.49, 1.0}, mode = WAVE_DATA, tol=1e-8)
End

Function DE_ManyElements()

	WAVE/Z start, stop
	[start, stop] = DistributeElements(10)
	CHECK_WAVE(start, NUMERIC_WAVE, minorType=DOUBLE_WAVE)
	CHECK_WAVE(stop, NUMERIC_WAVE, minorType=DOUBLE_WAVE)

	Make/FREE/D refStart = {0,0.102222222222222,0.204444444444444,0.306666666666667,0.408888888888889,0.511111111111111,0.613333333333333,0.715555555555556,0.817777777777778,0.92}
	Make/FREE/D refStop = {0.08,0.182222222222222,0.284444444444444,0.386666666666667,0.488888888888889,0.591111111111111,0.693333333333333,0.795555555555556,0.897777777777778,1}

	CHECK_EQUAL_WAVES(start, refStart, mode = WAVE_DATA, tol=1e-8)
	CHECK_EQUAL_WAVES(stop,  refStop, mode = WAVE_DATA, tol=1e-8)
End

/// @}

/// CalculateNiceLength
/// @{

Function CNL_Works()

	variable fraction = 0.1

	CHECK_EQUAL_VAR(CalculateNiceLength(fraction * 90, 5), 10)
	CHECK_EQUAL_VAR(CalculateNiceLength(fraction * 60, 5), 5)
	CHECK_EQUAL_VAR(CalculateNiceLength(fraction * 20, 5), 5)
	CHECK_EQUAL_VAR(CalculateNiceLength(fraction *  2, 5), 0.5)
	CHECK_EQUAL_VAR(CalculateNiceLength(fraction *  1, 5), 0.05)
	CHECK_EQUAL_VAR(CalculateNiceLength(fraction *  0.5, 5), 0.05)
End

/// @}

/// IsConstant
/// @{

Function IC_Works()

	CHECK_EQUAL_VAR(IsConstant({1, 1, 1}, 1), 1)
	CHECK_EQUAL_VAR(IsConstant({-1, 2, 3}, 0), 0)
End

// UTF_TD_GENERATOR InfiniteValues
Function IC_WorksSpecialValues([val])
	variable val

	CHECK_EQUAL_VAR(IsConstant({1, val, 1}, 0), 0)
	CHECK_EQUAL_VAR(IsConstant({val, val}, val), 1)
	CHECK_EQUAL_VAR(IsConstant({val, val}, 0), 0)
	CHECK_EQUAL_VAR(IsConstant({val, -val}, 0), 0)
End

/// @}

/// DataFolderExistsDFR
/// @{

static structure dfrTest
	DFREF structDFR
endstructure

Function DFED_WorksRegular1()

	STRUCT dfrTest s
	Make/FREE/DF/N=1 wDfr

	NewDataFolder test
	DFREF dfr = test
	s.structDFR = test
	wDfr[0] = test

	CHECK(DataFolderExistsDFR(dfr))
	CHECK(DataFolderExistsDFR(s.structDFR))
	CHECK(DataFolderExistsDFR(wDfr[0]))
End

Function DFED_WorksRegular2()

	STRUCT dfrTest s
	Make/FREE/DF/N=1 wDfr

	NewDataFolder test
	DFREF dfr = test
	s.structDFR = test
	wDfr[0] = test

	NewDataFolder test1
	MoveDataFolder test, test1

	CHECK(DataFolderExistsDFR(dfr))
	CHECK(DataFolderExistsDFR(s.structDFR))
	CHECK(DataFolderExistsDFR(wDfr[0]))
End

Function DFED_WorksRegular3()

	STRUCT dfrTest s
	Make/FREE/DF/N=1 wDfr

	DFREF dfr = NewFreeDataFolder()
	s.structDFR = dfr
	wDfr[0] = dfr

	NewDataFolder test
	MoveDataFolder dfr, test

	CHECK(DataFolderExistsDFR(dfr))
	CHECK(DataFolderExistsDFR(s.structDFR))
	CHECK(DataFolderExistsDFR(wDfr[0]))
End

Function DFED_WorksRegular4()

	STRUCT dfrTest s
	Make/FREE/DF/N=1 wDfr

	DFREF dfr = NewFreeDataFolder()
	s.structDFR = dfr
	wDfr[0] = dfr

	RenameDataFolder dfr, test1234

	CHECK(DataFolderExistsDFR(dfr))
	CHECK(DataFolderExistsDFR(s.structDFR))
	CHECK(DataFolderExistsDFR(wDfr[0]))
End

Function DFED_FailsRegular1()

	STRUCT dfrTest s
	Make/FREE/DF/N=1 wDfr

	DFREF dfr = $""
	s.structDFR = $""
	wDfr[0] = $""

	CHECK(!DataFolderExistsDFR(dfr))
	CHECK(!DataFolderExistsDFR(s.structDFR))
	CHECK(!DataFolderExistsDFR(wDfr[0]))
End

Function DFED_FailsRegular2()

	STRUCT dfrTest s
	Make/FREE/DF/N=1 wDfr

	NewDataFolder test

	DFREF dfr = test
	s.structDFR = test
	wDfr[0] = test

	KillDataFolder test

	CHECK(!DataFolderExistsDFR(dfr))
	CHECK(!DataFolderExistsDFR(s.structDFR))
	CHECK(!DataFolderExistsDFR(wDfr[0]))
End

Function DFED_FailsRegular3()

	DFREF dfr = NewFreeDataFolder()
	Make/DF/N=1 dfr:wDfr/Wave=wDfr
	wDfr[0] = dfr
	CHECK(DataFolderExistsDFR(wDfr[0]))

	dfr = NewFreeDataFolder()
	CHECK(DataFolderExistsDFR(wDfr[0]))

	dfr = GetWavesDataFolderDFR(wDfr)
	CHECK(DataFolderExistsDFR(dfr))


	wDfr[0] = root:

	dfr = GetWavesDataFolderDFR(wDfr)
	CHECK(DataFolderExistsDFR(dfr))

	dfr = NewFreeDataFolder()
	dfr = GetWavesDataFolderDFR(wDfr)
	CHECK(!DataFolderExistsDFR(dfr))
End

/// @}
