#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

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
	CHECK(!WaveExists(matches))
End

Function ReturnsInvalidWaveRefWOMatches2()

	Make/Free/D data1
	Make/Free/D/N=0 data2

	WAVE matches = GetSetIntersection(data1, data2)
	CHECK(!WaveExists(matches))
End

Function ReturnsInvalidWaveRefWOMatches3()

	Make/Free/D data1 = p
	Make/Free/D data2 = -1

	WAVE matches = GetSetIntersection(data1, data2)
	CHECK(!WaveExists(matches))
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

	rngSeed = 1
	Make/FREE/N=1024/L dataInt = MIES_DAP#DAP_GetRAAcquisitionCycleID(device)
	CHECK_EQUAL_VAR(998651135, WaveCRC(0, dataInt))

	rngSeed = 1
	Make/FREE/N=1024/D dataDouble = MIES_DAP#DAP_GetRAAcquisitionCycleID(device)

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
	CHECK(IsValidConfigWave(config))

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
End

Function ITCC_WorksVersion1()

	variable type, i
	string actual, expected

	WAVE/SDFR=root:ITCWaves config = ITCChanConfigWave_Version1
	CHECK(IsValidConfigWave(config))

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
	CHECK(!WaveExists(indizes))
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
	CHECK(!WaveExists(indizes))
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

	DFREF dfr = root:oodDAQ

	WAVE singleStimset = stimset[0]
	Duplicate/O singleStimset, dfr:$("stimset_oodDAQ_" + num2str(index) + "_0")

	WAVE singleStimset = stimset[1]
	Duplicate/O singleStimset, dfr:$("stimset_oodDAQ_" + num2str(index) + "_1")

	Duplicate/O offsets, dfr:$("offsets_" + num2str(index))
	Duplicate/O regions, dfr:$("regions_" + num2str(index))
End

static Function/WAVE GetoodDAQ_RefWaves_IGNORE(index)
	variable index

	Make/FREE/WAVE/N=4 wv
	DFREF dfr = root:oodDAQ

	WAVE/Z/SDFR=dfr ref_stimset_0 = $("stimset_oodDAQ_" + num2str(index) + "_0")
	WAVE/Z/SDFR=dfr ref_stimset_1 = $("stimset_oodDAQ_" + num2str(index) + "_1")
	WAVE/Z/SDFR=dfr ref_offsets   = $("offsets_" + num2str(index))
	WAVE/Z/SDFR=dfr ref_regions   = $("regions_" + num2str(index))

	wv[0] = ref_stimset_0
	wv[1] = ref_stimset_1
	wv[2] = ref_offsets
	wv[3] = ref_regions

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
	InitOOdDAQParams(params, stimSet, {0, 0}, 0, 0, 1)
	// END CHANGE ME

	OOD_CalculateOffsetsYoked(panelTitle, params)
	WAVE/WAVE stimSet = OOD_CreateStimSet(params)

//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1], stimset[1])
	CHECK_EQUAL_WAVES(refWave[2], params.offsets)
	CHECK_EQUAL_WAVES(refWave[3], params.regions)
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
	InitOOdDAQParams(params, stimSet, {1, 0}, 0, 0, 1)
	// END CHANGE ME

	OOD_CalculateOffsetsYoked(panelTitle, params)
	WAVE/WAVE stimSet = OOD_CreateStimSet(params)

//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1], stimset[1])
	CHECK_EQUAL_WAVES(refWave[2], params.offsets)
	CHECK_EQUAL_WAVES(refWave[3], params.regions)
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
	InitOOdDAQParams(params, stimSet, {0, 1}, 0, 0, 1)
	// END CHANGE ME

	OOD_CalculateOffsetsYoked(panelTitle, params)
	WAVE/WAVE stimSet = OOD_CreateStimSet(params)

//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1], stimset[1])
	CHECK_EQUAL_WAVES(refWave[2], params.offsets)
	CHECK_EQUAL_WAVES(refWave[3], params.regions)
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
	InitOOdDAQParams(params, stimSet, {0, 0}, 20, 0, 1)
	// END CHANGE ME

	OOD_CalculateOffsetsYoked(panelTitle, params)
	WAVE/WAVE stimSet = OOD_CreateStimSet(params)

//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1], stimset[1])
	CHECK_EQUAL_WAVES(refWave[2], params.offsets)
	CHECK_EQUAL_WAVES(refWave[3], params.regions)
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
	InitOOdDAQParams(params, stimSet, {0, 0}, 0, 20, 1)
	// END CHANGE ME

	OOD_CalculateOffsetsYoked(panelTitle, params)
	WAVE/WAVE stimSet = OOD_CreateStimSet(params)

//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1], stimset[1])
	CHECK_EQUAL_WAVES(refWave[2], params.offsets)
	CHECK_EQUAL_WAVES(refWave[3], params.regions)
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
	InitOOdDAQParams(params, stimSet, {0, 0}, 0, 0, 10)
	// END CHANGE ME

	OOD_CalculateOffsetsYoked(panelTitle, params)
	WAVE/WAVE stimSet = OOD_CreateStimSet(params)

//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1], stimset[1])
	CHECK_EQUAL_WAVES(refWave[2], params.offsets)
	CHECK_EQUAL_WAVES(refWave[3], params.regions)
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
	InitOOdDAQParams(params, stimSet, {0, 1}, 20, 30, 10)
	// END CHANGE ME

	OOD_CalculateOffsetsYoked(panelTitle, params)
	WAVE/WAVE stimSet = OOD_CreateStimSet(params)

//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1], stimset[1])
	CHECK_EQUAL_WAVES(refWave[2], params.offsets)
	CHECK_EQUAL_WAVES(refWave[3], params.regions)
End

/// @}
