#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTILSTEST_CONVERSIONS

// Missing Tests for:
// ConvertFromBytesToMiB
// str2numSafe
// ToPassFail
// ToTrueFalse
// ToOnOff
// DAQRunModeToString
// TestPulseRunModeToString
// ConvertToUniqueNumber
// GetCodeForWaveContents
// WaveTypeStringToNumber
// UTF8StringToTextWave

/// ConvertSamplingIntervalToRate
/// @{

Function CRTSI_Works()

	CHECK_CLOSE_VAR(ConvertSamplingIntervalToRate(5), 200)
End

/// @}

/// ConvertRateToSamplingInterval
/// @{

Function CSIR_Works()

	CHECK_CLOSE_VAR(ConvertRateToSamplingInterval(200), 5)
End

/// @}

/// TextWaveToList
/// @{

static Function/S AddTrailingSepIfReq(variable var, string sep)

	return SelectString(var, "", sep)
End

Function TWTLChecksParams()

	Make/FREE/T/N=1 w
	string list

	try
		Make/FREE invalidWaveType
		list = TextWaveToList(invalidWaveType, ";")
		FAIL()
	catch
		PASS()
	endtry

	// empty separators
	try
		list = TextWaveToList(w, "")
		FAIL()
	catch
		PASS()
	endtry

	try
		list = TextWaveToList(w, ";", colSep = "")
		FAIL()
	catch
		PASS()
	endtry

	try
		list = TextWaveToList(w, ";", layerSep = "")
		FAIL()
	catch
		PASS()
	endtry

	try
		list = TextWaveToList(w, ";", chunkSep = "")
		FAIL()
	catch
		PASS()
	endtry

	// invalid max elements
	try
		list = TextWaveToList(w, ";", maxElements = -1)
		FAIL()
	catch
		PASS()
	endtry

	try
		list = TextWaveToList(w, ";", maxElements = NaN)
		FAIL()
	catch
		PASS()
	endtry

	try
		list = TextWaveToList(w, ";", maxElements = 1.5)
		FAIL()
	catch
		PASS()
	endtry
End

// UTF_TD_GENERATOR TrailSepOptions
Function TWTLOddCases([variable var])

	Make/FREE/T/N=0 w
	string list, result, expected

	list = TextWaveToList(w, ";", trailSep = var)
	CHECK_EMPTY_STR(list)

	list = TextWaveToList($"", ";", trailSep = var)
	CHECK_EMPTY_STR(list)

	// check default value of trailSep
	Make/FREE/T data = {"a"}
	result   = TextWaveToList(data, ";")
	expected = "a;"
	CHECK_EQUAL_STR(result, expected)
End

// UTF_TD_GENERATOR TrailSepOptions
Function TWTL1D([variable var])

	Make/FREE/T/N=3 w = {"1", "2", "3"}

	string list
	string refList

	refList  = "1;2;3"
	refList += AddTrailingSepIfReq(var, ";")
	list     = TextWaveToList(w, ";", trailSep = var)
	CHECK_EQUAL_STR(list, refList)
End

// UTF_TD_GENERATOR TrailSepOptions
Function TWTL2D([variable var])

	Make/FREE/T/N=(3, 3) w = {{"1", "2", "3"}, {"4", "5", "6"}, {"7", "8", "9"}}

	string list
	string refList

	refList  = "1,4,7,;2,5,8,;3,6,9"
	refList += AddTrailingSepIfReq(var, ",;")
	list     = TextWaveToList(w, ";", trailSep = var)
	CHECK_EQUAL_STR(list, refList)
End

// UTF_TD_GENERATOR TrailSepOptions
Function TWTL3D([variable var])

	Make/FREE/T/N=(2, 2, 2) w = {{{"1", "2"}, {"3", "4"}}, {{"5", "6"}, {"7", "8"}}}

	string list
	string refList

	refList  = "1:5:,3:7:,;2:6:,4:8"
	refList += AddTrailingSepIfReq(var, ":,;")
	list     = TextWaveToList(w, ";", trailSep = var)
	CHECK_EQUAL_STR(list, refList)
End

// UTF_TD_GENERATOR TrailSepOptions
Function TWTL4D([variable var])

	Make/FREE/T/N=(2, 2, 2, 2) w = {{{{"1", "2"}, {"3", "4"}}, {{"5", "6"}, {"7", "8"}}}, {{{"9", "10"}, {"11", "12"}}, {{"13", "14"}, {"15", "16"}}}}

	string list
	string refList

	refList  = "1/9/:5/13/:,3/11/:7/15/:,;2/10/:6/14/:,4/12/:8/16" // NOLINT
	refList += AddTrailingSepIfReq(var, "/:,;")
	list     = TextWaveToList(w, ";", trailSep = var)
	CHECK_EQUAL_STR(list, refList)
End

// UTF_TD_GENERATOR TrailSepOptions
Function TWTLCustomSepators([variable var])

	Make/FREE/T/N=(2, 2, 2, 2) w = {{{{"1", "2"}, {"3", "4"}}, {{"5", "6"}, {"7", "8"}}}, {{{"9", "10"}, {"11", "12"}}, {{"13", "14"}, {"15", "16"}}}}

	string list
	string refList

	refList  = "1d9dc5d13dcb3d11dc7d15dcba2d10dc6d14dcb4d12dc8d16"
	refList += AddTrailingSepIfReq(var, "dcba")
	list     = TextWaveToList(w, "a", colSep = "b", layerSep = "c", chunkSep = "d", trailSep = var)
	CHECK_EQUAL_STR(list, refList)
End

// UTF_TD_GENERATOR TrailSepOptions
Function TWTLStopOnEmpty([variable var])

	Make/FREE/T/N=(3, 3) w = {{"", "2", "3"}, {"4", "5", "6"}, {"7", "8", "9"}}

	string list
	string refList

	// stop at first element
	refList = ""
	list    = TextWaveToList(w, ";", stopOnEmpty = 1, trailSep = var)
	CHECK_EQUAL_STR(list, refList)

	// stop in the middle
	w        = {"1", "", "3"}
	refList  = "1"
	refList += AddTrailingSepIfReq(var, ";")
	list     = TextWaveToList(w, ";", stopOnEmpty = 1, trailSep = var)
	CHECK_EQUAL_STR(list, refList)

	// stop at last element with partial filling
	w        = {{"1", "2", "3"}, {"4", "5", "6"}, {"7", "8", ""}}
	refList  = "1,4,7,;2,5,8,;3,6"
	refList += AddTrailingSepIfReq(var, ",;")
	list     = TextWaveToList(w, ";", stopOnEmpty = 1, trailSep = var)
	CHECK_EQUAL_STR(list, refList)

	// stop at new row
	w        = {{"1", "", "3"}, {"4", "5", "6"}, {"7", "8", "9"}}
	refList  = "1,4,7"
	refList += AddTrailingSepIfReq(var, ",;")
	list     = TextWaveToList(w, ";", stopOnEmpty = 1, trailSep = var)
	CHECK_EQUAL_STR(list, refList)
End

// UTF_TD_GENERATOR TrailSepOptions
Function TWTLMaxElements([variable var])

	Make/FREE/T/N=(3, 3) w = {{"1", "2", "3"}, {"4", "5", "6"}, {"7", "8", "9"}}

	string list
	string refList

	// empty result
	list = TextWaveToList(w, ";", maxElements = 0, trailSep = var)
	CHECK_EMPTY_STR(list)

	// Only first row
	refList  = "1,4,7"
	refList += AddTrailingSepIfReq(var, ",;")
	list     = TextWaveToList(w, ";", maxElements = 3, trailSep = var)
	CHECK_EQUAL_STR(list, refList)

	// stops in the middle of column
	refList  = "1,4,7,;2"
	refList += AddTrailingSepIfReq(var, ",;")
	list     = TextWaveToList(w, ";", maxElements = 4, trailSep = var)
	CHECK_EQUAL_STR(list, refList)

	// inf is the same as not giving it
	refList  = "1,4,7,;2,5,8,;3,6,9"
	refList += AddTrailingSepIfReq(var, ",;")
	list     = TextWaveToList(w, ";", maxElements = Inf, trailSep = var)
	CHECK_EQUAL_STR(list, refList)
End

// UTF_TD_GENERATOR TrailSepOptions
static Function TWTLSingleElementNDSeparators([variable var])

	string list
	string refList

	Make/FREE/T/N=(1, 1, 1, 1) wt = "test"
	list     = TextWaveToList(wt, ";", trailSep = var)
	refList  = "test"
	refList += AddTrailingSepIfReq(var, "/:,;")
	CHECK_EQUAL_STR(list, refList)

	Make/FREE/T/N=(1, 1, 1) wt = "test"
	list     = TextWaveToList(wt, ";", trailSep = var)
	refList  = "test"
	refList += AddTrailingSepIfReq(var, ":,;")
	CHECK_EQUAL_STR(list, refList)

	Make/FREE/T/N=(1, 1) wt = "test"
	list     = TextWaveToList(wt, ";", trailSep = var)
	refList  = "test"
	refList += AddTrailingSepIfReq(var, ",;")
	CHECK_EQUAL_STR(list, refList)

	Make/FREE/T/N=(1) wt = "test"
	list     = TextWaveToList(wt, ";", trailSep = var)
	refList  = "test"
	refList += AddTrailingSepIfReq(var, ";")
	CHECK_EQUAL_STR(list, refList)
End

Function/WAVE SomeTextWaves()

	Make/WAVE/FREE/N=5 all

	Make/FREE/T/N=0 wv1

	// both empty and null roundtrip to an empty wave
	all[0] = wv1
	all[1] = $""

	Make/FREE/T/N=(3, 3) wv2 = {{"1", "2", "3"}, {"4", "5", "6"}, {"7", "8", "9"}}
	all[2] = wv2

	Make/FREE/T/N=(2, 2, 2) wv3 = {{{"1", "2"}, {"3", "4"}}, {{"5", "6"}, {"7", "8"}}}
	all[3] = wv3

	Make/FREE/T/N=(2, 2, 2, 2) wv4 = {{{{"1", "2"}, {"3", "4"}}, {{"5", "6"}, {"7", "8"}}}, {{{"9", "10"}, {"11", "12"}}, {{"13", "14"}, {"15", "16"}}}}
	all[4] = wv4

	return all
End

// UTF_TD_GENERATOR w0:SomeTextWaves
// UTF_TD_GENERATOR v0:TrailSepOptions
Function TWTLRoundTrips([STRUCT IUTF_MDATA &md])

	string list
	variable dims, trailSep

	WAVE wv = md.w0
	trailSep = md.v0

	dims = WaveExists(wv) ? max(1, WaveDims(wv)) : 1
	list = TextWaveToList(wv, ";", trailSep = trailSep)
	WAVE/T result = ListToTextWaveMD(list, dims)

	if(WaveExists(wv))
		CHECK_EQUAL_TEXTWAVES(result, wv)
	else
		CHECK_EQUAL_VAR(DimSize(result, ROWS), 0)
	endif
End

/// @}

/// ListToTextWaveMD
/// @{

/// @brief Fail due to null string
Function ListToTextWaveMDFail0()

	string   uninitialized
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

	Make/FREE/T ref = {{"1", "3"}, {"2", "4"}}
	WAVE/T t = ListToTextWaveMD("1,2,;3,4,;", 2)
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 2D list, default sep, short sub list 0
Function ListToTextWaveMDWorks9()

	Make/FREE/T ref = {{"1", "3"}, {"2", ""}}
	WAVE/T t = ListToTextWaveMD("1,2,;3,;", 2)
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 3D list, default sep
Function ListToTextWaveMDWorks2()

	Make/FREE/T ref = {{{"1", "5"}, {"3", "7"}}, {{"2", "6"}, {"4", "8"}}}
	WAVE/T t = ListToTextWaveMD("1:2:,3:4:,;5:6:,7:8:,;", 3)
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 3D list, default sep, short sub list 0
Function ListToTextWaveMDWorks7()

	Make/FREE/T ref = {{{"1", "5"}, {"3", ""}}, {{"2", "6"}, {"4", ""}}}
	WAVE/T t = ListToTextWaveMD("1:2:,3:4:,;5:6:,;", 3)
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 3D list, default sep, short sub list 1
Function ListToTextWaveMDWorks8()

	Make/FREE/T ref = {{{"1", "5"}, {"3", "7"}}, {{"2", "6"}, {"4", ""}}}
	WAVE/T t = ListToTextWaveMD("1:2:,3:4:,;5:6:,7:,;", 3)
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 4D list, default sep
Function ListToTextWaveMDWorks3()

	Make/FREE/T ref = {{{{"1", "9"}, {"5", "13"}}, {{"3", "11"}, {"7", "15"}}}, {{{"2", "10"}, {"6", "14"}}, {{"4", "12"}, {"8", "16"}}}}
	WAVE/T t = ListToTextWaveMD("1/2/:3/4/:,5/6/:7/8/:,;9/10/:11/12/:,13/14/:15/16/:,;", 4) // NOLINT
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 4D list, default sep, short sub list 0
Function ListToTextWaveMDWorks4()

	Make/FREE/T ref = {{{{"1", "9"}, {"5", ""}}, {{"3", "11"}, {"7", ""}}}, {{{"2", "10"}, {"6", ""}}, {{"4", "12"}, {"8", ""}}}}
	WAVE/T t = ListToTextWaveMD("1/2/:3/4/:,5/6/:7/8/:,;9/10/:11/12/:;", 4) // NOLINT
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 4D list, default sep, short sub list 1
Function ListToTextWaveMDWorks5()

	Make/FREE/T ref = {{{{"1", "9"}, {"5", "13"}}, {{"3", "11"}, {"7", ""}}}, {{{"2", "10"}, {"6", "14"}}, {{"4", "12"}, {"8", ""}}}}
	WAVE/T t = ListToTextWaveMD("1/2/:3/4/:,5/6/:7/8/:,;9/10/:11/12/:,13/14/:,;", 4) // NOLINT
	CHECK_EQUAL_WAVES(t, ref)
End

/// @brief 4D list, default sep, short sub list 2
Function ListToTextWaveMDWorks6()

	Make/FREE/T ref = {{{{"1", "9"}, {"5", "13"}}, {{"3", "11"}, {"7", "15"}}}, {{{"2", "10"}, {"6", "14"}}, {{"4", "12"}, {"8", ""}}}}
	WAVE/T t = ListToTextWaveMD("1/2/:3/4/:,5/6/:7/8/:,;9/10/:11/12/:,13/14/:15/:,;", 4) // NOLINT
	CHECK_EQUAL_WAVES(t, ref)
End

/// @}

/// NumericWaveToList
/// @{

// UTF_TD_GENERATOR TrailSepOptions
Function NWLWorks([variable var])

	string expected, result

	Make/FREE dataFP = {1, 1e6, -Inf, 1.5, NaN}
	result    = NumericWaveToList(dataFP, ";", trailSep = var)
	expected  = "1;1e+06;-inf;1.5;nan"
	expected += AddTrailingSepIfReq(var, ";")
	CHECK_EQUAL_STR(result, expected)

	Make/FREE dataFP = {1, 1e6, -100}
	result    = NumericWaveToList(dataFP, ";", format = "%d", trailSep = var)
	expected  = "1;1000000;-100"
	expected += AddTrailingSepIfReq(var, ";")
	CHECK_EQUAL_STR(result, expected)

	Make/FREE dataFP = {{1, 2, 3}, {4, 5, 6}}
	result    = NumericWaveToList(dataFP, ";", trailSep = var)
	expected  = "1,4,;2,5,;3,6"
	expected += AddTrailingSepIfReq(var, ",;")
	CHECK_EQUAL_STR(result, expected)

	Make/FREE/N=0 dataEmpty
	result = NumericWaveToList(dataEmpty, ";", trailSep = var)
	CHECK_EMPTY_STR(result)

	result = NumericWaveToList($"", ";", trailSep = var)
	CHECK_EMPTY_STR(result)

	// check default value of trailSep
	Make/FREE data = {1}
	result   = NumericWaveToList(data, ";")
	expected = "1;"
	CHECK_EQUAL_STR(result, expected)
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
		Make/FREE/D/N=(2, 2, 3) ThreeDWave
		NumericWaveToList(ThreeDWave, ";"); AbortONRTE
		FAIL()
	catch
		PASS()
	endtry

	try
		Make/FREE/D/N=(2, 2) TwoDWave
		NumericWaveToList(TwoDWave, ";", colSep = ""); AbortONRTE
		FAIL()
	catch
		PASS()
	endtry
End

/// @}

/// ListToNumericWave
/// @{

Function LTNWWorks()

	WAVE wv = ListToNumericWave("1;1e6;-inf;1.5;NaN;", ";")

	CHECK_WAVE(wv, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK_EQUAL_WAVES(wv, {1, 1e6, -Inf, 1.5, NaN}, mode = WAVE_DATA)
End

Function LTNWWorksWithCustomSepAndFloatType()

	WAVE wv = ListToNumericWave("1|1e6|-inf|1.5|NaN|", "|", type = IGOR_TYPE_32BIT_FLOAT)

	CHECK_WAVE(wv, NUMERIC_WAVE, minorType = FLOAT_WAVE)
	CHECK_EQUAL_WAVES(wv, {1, 1e6, -Inf, 1.5, NaN}, mode = WAVE_DATA)
End

Function LTNWWorksWithIntegerType()

	WAVE wv = ListToNumericWave("1;-1;", ";", type = IGOR_TYPE_32BIT_INT)

	CHECK_WAVE(wv, NUMERIC_WAVE, minorType = INT32_WAVE)
	CHECK_EQUAL_WAVES(wv, {1, -1}, mode = WAVE_DATA)
End

Function LTNWWorksWithOnlySeps()

	WAVE wv = ListToNumericWave(";;;", ";")

	CHECK_WAVE(wv, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK_EQUAL_WAVES(wv, {NaN, NaN, NaN}, mode = WAVE_DATA)
End

Function LTNWRoundtripsWithNumericWaveToList()

	string list

	Make/FREE expected = {1, 1e6, -Inf, 1.5, NaN}

	list = NumericWaveToList(expected, ";")

	WAVE actual = ListToNumericWave(list, ";")

	CHECK_WAVE(expected, NUMERIC_WAVE, minorType = FLOAT_WAVE)
	CHECK_EQUAL_WAVES(expected, actual, mode = WAVE_DATA)
End

static Function LTNInvalidInput()

	if(QueryIgorOption("DisableThreadsafe") == 1)
		WAVE wv = ListToNumericWave("1;totallyLegitNumber;1;", ";")
		CHECK_RTE(1001) // Str2num;expected number
		CHECK_WAVE(wv, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
		CHECK_EQUAL_WAVES(wv, {1, NaN, 1}, mode = WAVE_DATA)
	else
		PASS()
	endif
End

static Function LTNInvalidInputIgnored()

	if(QueryIgorOption("DisableThreadsafe") == 1)
		WAVE wv = ListToNumericWave("1;totallyLegitNumber;1;", ";", ignoreErr = 1)
		CHECK_NO_RTE()
		CHECK_WAVE(wv, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
		CHECK_EQUAL_WAVES(wv, {1, NaN, 1}, mode = WAVE_DATA)
	else
		PASS()
	endif
End

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
	string s    = num2strHighPrec(1.6666666)
	CHECK_EQUAL_STR(s, sref)
End

/// @brief precision 0
Function num2strHighPrecWorks1()

	string sref = "2"
	string s    = num2strHighPrec(1.6666666, precision = 0)
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
	string s    = num2strHighPrec(1.5, precision = 0)
	CHECK_EQUAL_STR(s, sref)

	s = num2strHighPrec(2.5, precision = 0)
	CHECK_EQUAL_STR(s, sref)

	sref = "-2"
	s    = num2strHighPrec(-2.5, precision = 0)
	CHECK_EQUAL_STR(s, sref)
	s = num2strHighPrec(-1.5, precision = 0)
	CHECK_EQUAL_STR(s, sref)
End

/// @brief special cases nan, inf, -inf
Function num2strHighPrecWorks4()

	string sref = "nan"
	string s    = num2strHighPrec(NaN)
	CHECK_EQUAL_STR(s, sref)

	sref = "inf"
	s    = num2strHighPrec(Inf)
	CHECK_EQUAL_STR(s, sref)

	sref = "-inf"
	s    = num2strHighPrec(-Inf)
	CHECK_EQUAL_STR(s, sref)
End

/// @brief Only real part of complex is returned
Function num2strHighPrecWorks5()

	variable/C c    = cmplx(Inf, NaN)
	string     sref = "inf"
	string     s    = num2strHighPrec(c)
	CHECK_EQUAL_STR(s, sref)
End

Function num2strHighPrecShortenWorks1()

	string sref = "1.234"
	string s    = num2strHighPrec(1.2340, precision = MAX_DOUBLE_PRECISION, shorten = 1)
	CHECK_EQUAL_STR(s, sref)
End

Function num2strHighPrecShortenWorks2()

	string sref = "1"
	string s    = num2strHighPrec(1.0, precision = MAX_DOUBLE_PRECISION, shorten = 1)
	CHECK_EQUAL_STR(s, sref)
End

Function num2strHighPrecShortenDoesNotEatAllZeroes()

	string sref = "10"
	string s    = num2strHighPrec(10.00, precision = MAX_DOUBLE_PRECISION, shorten = 1)
	CHECK_EQUAL_STR(s, sref)
End

/// @}

/// ScaleToIndexWrapper
/// @{

Function STIW_TestDimensions()

	Make/FREE testwave

	SetScale/P x, 0, 0.1, testwave
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testwave, 0, ROWS), ScaleToIndex(testWave, 0, ROWS))
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testwave, 1, ROWS), ScaleToIndex(testWave, 1, ROWS))
	SetScale/P y, 0, 0.01, testwave
	SetScale/P z, 0, 0.001, testwave
	SetScale/P t, 0, 0.0001, testwave

	REQUIRE_EQUAL_VAR(ScaleToIndex(testWave, -1, ROWS), DimOffset(testwave, ROWS) - 1 / DimDelta(testwave, ROWS))
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testWave, -1, ROWS), 0)
	REQUIRE_EQUAL_VAR(ScaleToIndex(testWave, -Inf, ROWS), NaN)
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testWave, -Inf, ROWS), 0)

	REQUIRE_EQUAL_VAR(ScaleToIndex(testWave, 1e3, ROWS), DimOffset(testwave, ROWS) + 1e3 / DimDelta(testwave, ROWS))
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testWave, 1e3, ROWS), DimSize(testwave, ROWS) - 1)

	SetScale/P x, 0, -0.1, testwave
	REQUIRE_EQUAL_VAR(ScaleToIndex(testWave, -1, ROWS), DimOffset(testwave, ROWS) - 1 / DimDelta(testwave, ROWS))
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testWave, 1, ROWS), 0)
	REQUIRE_EQUAL_VAR(ScaleToIndex(testWave, 1, ROWS), DimOffset(testwave, ROWS) + 1 / DimDelta(testwave, ROWS))
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testWave, 1, ROWS), 0)
	REQUIRE_EQUAL_VAR(ScaleToIndexWrapper(testWave, Inf, ROWS), 0)
End

Function/WAVE STIW_TestAbortGetter()

	Make/D/FREE data = {4, -1, 0.1, NaN, Inf, -Inf}
	return data
End

// UTF_TD_GENERATOR STIW_TestAbortGetter
Function STIW_TestAbort([variable var])

	variable err

	Make/FREE testwave
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

/// HexToNumber, NumberToHex, HexToBinary
/// @{

Function HexAndNumbersWorks()

	string str, expected

	CHECK_EQUAL_VAR(HexToNumber("0a"), 10)
	CHECK_EQUAL_VAR(HexToNumber("0f"), 15)
	CHECK_EQUAL_VAR(HexToNumber("00"), 0)
	CHECK_EQUAL_VAR(HexToNumber("ff"), 255)

	str      = NumberToHex(0)
	expected = "00"
	CHECK_EQUAL_STR(str, expected)

	str      = NumberToHex(10)
	expected = "0a"
	CHECK_EQUAL_STR(str, expected)

	str      = NumberToHex(15)
	expected = "0f"
	CHECK_EQUAL_STR(str, expected)

	str      = NumberToHex(255)
	expected = "ff"
	CHECK_EQUAL_STR(str, expected)

	CHECK_EQUAL_WAVES(HexToBinary("ff000110"), {255, 0, 16, 1}, mode = WAVE_DATA)
End

/// @}

/// ConvertListToRegexpWithAlternations
/// @{

static Function ConvertListToRegexpWithAlternations_Test()

	string str, ref

	str = ConvertListToRegexpWithAlternations("1;2;")
	ref = "(?:\\Q1\\E|\\Q2\\E)"
	CHECK_EQUAL_STR(ref, str)

	str = ConvertListToRegexpWithAlternations("1;2;", literal = 0)
	ref = "(?:1|2)"
	CHECK_EQUAL_STR(ref, str)

	str = ConvertListToRegexpWithAlternations("1#2#", literal = 0, sep = "#")
	ref = "(?:1|2)"
	CHECK_EQUAL_STR(ref, str)

	try
		str = ConvertListToRegexpWithAlternations("1#2#", sep = "")
		FAIL()
	catch
		PASS()
	endtry
End

/// @}

/// WaveToJSON, JSONToWave
/// @{

Function/WAVE GetTestWaveForSerialization()

	Make/FREE/D wv = {{1, 2, 3}, {4, 5, 6}}
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 2)

	Note wv, "abcd"

	SetScale/P x, 0, 1, "1122", wv
	SetScale/P y, 2, 3, "3344", wv

	SetScale d, 7, 8, "efgh", wv

	SetDimLabel ROWS, -1, $"ijkl", wv
	SetDimLabel COLS, -1, $"mnop", wv

	SetDimLabel ROWS, 0, $"qrst", wv
	SetDimLabel COLS, 1, $"uvwx", wv
	SetDimLabel ROWS, 2, $"yz", wv

	return wv
End

Function JSONWaveSerializationWorks()

	string str

	WAVE wv = GetTestWaveForSerialization()

	str = WaveToJSON(wv)
	CHECK_PROPER_STR(str)

	WAVE/Z serialized = JSONToWave(str)
	CHECK_WAVE(serialized, NUMERIC_WAVE | FREE_WAVE, minorType = DOUBLE_WAVE)

	CHECK_EQUAL_WAVES(wv, serialized)
End

Function JSONWaveSerializationWorksText()

	string str

	Make/FREE/T wv = {{"1", "2", "3"}, {"4", "5", "6"}}
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 2)

	SetScale/P x, 0, 1, "1122", wv

	str = WaveToJSON(wv)
	CHECK_PROPER_STR(str)

	WAVE/Z serialized = JSONToWave(str)
	CHECK_WAVE(serialized, TEXT_WAVE | FREE_WAVE)

	CHECK_EQUAL_WAVES(wv, serialized)
End

Function JSONWaveSerializationWorksOnlyOneRow()

	string str

	WAVE wv = GetTestWaveForSerialization()
	Redimension/N=(1, -1) wv

	str = WaveToJSON(wv)
	CHECK_PROPER_STR(str)

	WAVE/Z serialized = JSONToWave(str)
	CHECK_WAVE(serialized, NUMERIC_WAVE | FREE_WAVE, minorType = DOUBLE_WAVE)

	CHECK_EQUAL_WAVES(wv, serialized)
End

Function JSONWaveSerializationWorksNoDimLabels()

	string str

	Make/D/N=1/FREE wv

	str = WaveToJSON(wv)
	CHECK_PROPER_STR(str)

	WAVE/Z serialized = JSONToWave(str)
	CHECK_WAVE(serialized, NUMERIC_WAVE | FREE_WAVE, minorType = DOUBLE_WAVE)

	CHECK_EQUAL_WAVES(wv, serialized)
End

Function JSONWaveInvalidWaveRefRoundTrips()

	string str

	WAVE/Z input
	str = WaveToJSON(input)
	WAVE/Z result = JSONToWave(str)
	CHECK_WAVE(result, NULL_WAVE)
End

Function JSONWaveSerializationWorksWithPath()

	string str, path
	variable childID, jsonID

	WAVE wv = GetTestWaveForSerialization()

	str = WaveToJSON(wv)
	CHECK_PROPER_STR(str)

	childID = JSON_Parse(str)
	CHECK_GE_VAR(childID, 0)

	jsonID = JSON_New()
	CHECK_GE_VAR(jsonID, 0)
	path = "/abcd/efgh"
	JSON_AddTreeObject(jsonID, path)

	JSON_SetJSON(jsonID, path, childID)
	JSON_Release(childID)
	str = JSON_Dump(jsonID)
	JSON_Release(jsonID)

	WAVE/Z serialized = JSONToWave(str, path = path)
	CHECK_WAVE(serialized, NUMERIC_WAVE | FREE_WAVE, minorType = DOUBLE_WAVE)

	CHECK_EQUAL_WAVES(wv, serialized)
End

/// UTF_TD_GENERATOR s0:DataGenerators#GetSupportedWaveTypes
Function JSONWaveCreatesCorrectWaveTypes([STRUCT IUTF_mData &m])

	string str, typeStr
	variable type

	typeStr = m.s0

	strswitch(typeStr)
		case "TEXT_WAVE":
			Make/FREE/T dataText
			WAVE data = dataText
			break
		case "WAVE_WAVE":
			Make/FREE/WAVE dataWave
			WAVE data = dataWave
			break
		default:
			type = WaveTypeStringToNumber(typeStr)
			Make/FREE/Y=(type) data
			break
	endswitch

	str = WaveToJSON(data)
	WAVE/Z result = JSONToWave(str)
	CHECK_EQUAL_WAVES(data, result, mode = WAVE_DATA | WAVE_DATA_TYPE)
End

/// @}

/// FloatWithMinSigDigits
/// @{

// UTF_TD_GENERATOR DataGenerators#InvalidSignDigits
Function FloatWithMinSigDigitsAborts([variable var])

	try
		FloatWithMinSigDigits(1.234, numMinSignDigits = var)
		FAIL()
	catch
		PASS()
	endtry
End

Function FloatWithMinSigDigitsWorks()

	string result, expected

	result   = FloatWithMinSigDigits(1.234, numMinSignDigits = 0)
	expected = "1"
	CHECK_EQUAL_STR(result, expected)

	result   = FloatWithMinSigDigits(-1.234, numMinSignDigits = 0)
	expected = "-1"
	CHECK_EQUAL_STR(result, expected)

	result   = FloatWithMinSigDigits(1e-2, numMinSignDigits = 2)
	expected = "0.01"
	CHECK_EQUAL_STR(result, expected)
End

/// @}

/// @brief Generic test against the generated conversion constants
Function GMC_SomeVariants()

	// 1 mA -> 1e-3A
	CHECK_EQUAL_VAR(MILLI_TO_ONE, 1e-3)

	// 1 MA -> 1e9 mA
	CHECK_EQUAL_VAR(MEGA_TO_MILLI, 1e9)

	CHECK_EQUAL_VAR(PETA_TO_FEMTO, 1e30)

	CHECK_EQUAL_VAR(MICRO_TO_TERA, 1e-18)
End
