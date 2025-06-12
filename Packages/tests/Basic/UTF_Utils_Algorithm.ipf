#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_ALGORITHM

// Missing Tests for:
// Downsample
// CalculateLCMOfWave
// CallFunctionForEachListItem
// InPlaceRandomShuffle
// ExtractFromSubrange
// GrepWave
// GrepTextWave
// DoPowerSpectrum
// DoFFT

/// GetUniqueEntries*
/// @{

Function GUE_WorksWithEmpty()

	Make/N=0/FREE wv

	WAVE/Z result = GetUniqueEntries(wv)
	CHECK_WAVE(result, NUMERIC_WAVE, minorType = FLOAT_WAVE)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 0)
End

Function GUE_WorksWithOne()

	Make/N=1/FREE wv

	WAVE/Z result = GetUniqueEntries(wv)
	CHECK_EQUAL_WAVES(result, wv)
End

static Function GUE_WorksWithOneNoDuplicate()

	Make/N=1/FREE wv

	WAVE/Z result = GetUniqueEntries(wv, dontDuplicate = 1)
	CHECK(WaveRefsEqual(result, wv))
End

Function GUE_BailsOutWith2D()

	Make/N=(1, 2)/FREE wv

	try
		WAVE/Z result = GetUniqueEntries(wv)
		FAIL()
	catch
		PASS()
	endtry
End

Function GUE_WorksWithTextEmpty()

	Make/T/N=0/FREE wv

	WAVE/Z result = GetUniqueEntries(wv)
	CHECK_WAVE(result, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 0)
End

Function GUE_WorksWithTextOne()

	Make/T/N=1/FREE wv

	WAVE/Z result = GetUniqueEntries(wv)
	CHECK_EQUAL_WAVES(result, wv)
End

static Function GUE_WorksWithTextOneNoDuplicate()

	Make/T/N=1/FREE wv

	WAVE/Z result = GetUniqueEntries(wv, dontDuplicate = 1)
	CHECK(WaveRefsEqual(result, wv))
End

Function GUE_IgnoresCase()

	Make/T/FREE wv = {"a", "A"}

	WAVE/Z result = GetUniqueEntries(wv, caseSensitive = 0)
	CHECK_EQUAL_TEXTWAVES(result, {"a"})
End

Function GUE_HandlesCase()

	Make/T/FREE wv = {"a", "A"}

	WAVE/Z result = GetUniqueEntries(wv, caseSensitive = 1)
	CHECK_EQUAL_TEXTWAVES(result, {"a", "A"})
End

Function GUE_BailsOutWithText2D()

	Make/FREE/T/N=(1, 2) wv

	try
		WAVE/Z result = GetUniqueEntries(wv)
		FAIL()
	catch
		PASS()
	endtry
End

Function GUE_ListWorks1()

	string input, expected, result

	input    = "a;A;"
	expected = "a;"

	result = GetUniqueTextEntriesFromList(input, caseSensitive = 0)
	CHECK_EQUAL_STR(result, expected)
End

Function GUE_ListWorks2()

	string input, expected, result

	input    = "a;A;"
	expected = input

	result = GetUniqueTextEntriesFromList(input, caseSensitive = 1)
	CHECK_EQUAL_STR(result, expected)
End

Function GUE_ListWorksWithSep()

	string input, expected, result

	input    = "a-A-a"
	expected = "a-A-"

	result = GetUniqueTextEntriesFromList(input, caseSensitive = 1, sep = "-")
	CHECK_EQUAL_STR(result, expected)
End

static Function GUTE_WorksWithOneNoDuplicate()

	Make/T/N=1/FREE wv

	WAVE/Z result = MIES_UTILS_ALGORITHM#GetUniqueTextEntries(wv, dontDuplicate = 1)
	CHECK(WaveRefsEqual(result, wv))
End

/// @}

// GetRowIndex
/// @{

static Function TestGetRowIndex()

	variable valueToSearch
	string   strToSearch

	Make/N=0/FREE emptyWave

	// check number of opt parameters #1
	try
		GetRowIndex(emptyWave)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// check number of opt parameters #2
	try
		GetRowIndex(emptyWave, val = 1, str = "", refWave = $"")
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// invalid refWave type
	try
		GetRowIndex(emptyWave, refWave = $"")
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	CHECK_EQUAL_VAR(GetRowIndex(emptyWave, val = 1), NaN)
	CHECK_EQUAL_VAR(GetRowIndex(emptyWave, str = "1"), NaN)

	// numeric waves
	Make/FREE floatWave = {3, 1, 2, NaN, Inf, -Inf}
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, val = 3), 0)
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, str = "3"), 0)
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, val = Inf), 4)
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, val = -Inf), 5)
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, val = NaN), 3)
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, str = ""), 3)
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, str = "inf"), 4)
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, str = "-inf"), 5)
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, val = 123), NaN)

	// text waves
	Make/FREE/T textWave = {"a", "b", "c", "d", "1"}
	CHECK_EQUAL_VAR(GetRowIndex(textWave, val = 1), 4)
	CHECK_EQUAL_VAR(GetRowIndex(textWave, str = "b"), 1)
	CHECK_EQUAL_VAR(GetRowIndex(textWave, val = 123), NaN)

	// text waves with textOp
	Make/FREE/T textWave = {"a1", "b2", "c", "d", "1", "2"}
	CHECK_EQUAL_VAR(GetRowIndex(textWave, val = 1), 4)
	CHECK_EQUAL_VAR(GetRowIndex(textWave, val = 1, textOp = 4), 4)
	CHECK_EQUAL_VAR(GetRowIndex(textWave, val = 1, textOp = 0), 0)
	CHECK_EQUAL_VAR(GetRowIndex(textWave, str = "2"), 5)
	CHECK_EQUAL_VAR(GetRowIndex(textWave, str = "2", textOp = 4), 5)
	CHECK_EQUAL_VAR(GetRowIndex(textWave, str = "2", textOp = 0), 1)

	// wave ref waves
	Make/FREE/WAVE/N=2 waveRefWave
	Make/FREE content
	waveRefWave[1] = content
	CHECK_EQUAL_VAR(GetRowIndex(waveRefWave, refWave = content), 1)
	CHECK_EQUAL_VAR(GetRowIndex(waveRefWave, refWave = $""), 0)
	CHECK_EQUAL_VAR(GetRowIndex(waveRefWave, refWave = waveRefWave), NaN)

	Make/FREE/WAVE/N=0 emptyWaveRefWave
	CHECK_EQUAL_VAR(GetRowIndex(emptyWaveRefWave, refWave = content), NaN)

	// reverse numeric
	Make/FREE floatWave = {3, 1, 2, NaN, Inf, NaN, Inf, 1, 2, 3, -Inf, -Inf}
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, val = 3, reverseSearch = 1), 9)
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, str = "3", reverseSearch = 1), 9)
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, val = NaN, reverseSearch = 1), 5)
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, val = Inf, reverseSearch = 1), 6)
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, val = -Inf, reverseSearch = 1), 11)
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, str = "", reverseSearch = 1), 5)
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, str = "Inf", reverseSearch = 1), 6)
	CHECK_EQUAL_VAR(GetRowIndex(floatWave, str = "-Inf", reverseSearch = 1), 11)

	// reverse text waves
	Make/FREE/T textWave = {"a", "b", "c", "d", "1", "a", "b", "c", "d", "1"}
	CHECK_EQUAL_VAR(GetRowIndex(textWave, val = 1, reverseSearch = 1), 9)
	CHECK_EQUAL_VAR(GetRowIndex(textWave, str = "b", reverseSearch = 1), 6)

	// reverse wave ref waves
	Make/FREE/WAVE/N=4 waveRefWave
	Make/FREE content
	waveRefWave[1, 2] = content
	CHECK_EQUAL_VAR(GetRowIndex(waveRefWave, refWave = content, reverseSearch = 1), 2)
	CHECK_EQUAL_VAR(GetRowIndex(waveRefWave, refWave = $"", reverseSearch = 1), 3)

	Make/FREE/WAVE/N=0 emptyWaveRefWave
	CHECK_EQUAL_VAR(GetRowIndex(emptyWaveRefWave, refWave = content, reverseSearch = 1), NaN)

	// no tolerance
	Make/FREE/D doubleWave = {1}
	valueToSearch = 1 + 1e-12
	strToSearch   = num2str(valueToSearch, "%.15g")
	CHECK_EQUAL_VAR(GetRowIndex(doubleWave, val = valueToSearch), NaN)
	CHECK_EQUAL_VAR(GetRowIndex(doubleWave, str = strToSearch), NaN)
	CHECK_EQUAL_VAR(GetRowIndex(doubleWave, val = valueToSearch, reverseSearch = 1), NaN)
	CHECK_EQUAL_VAR(GetRowIndex(doubleWave, str = strToSearch, reverseSearch = 1), NaN)

	// unsupported wave type
	try
		Make/FREE/DF wv
		GetRowIndex(wv, val = 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

/// @}

// GetListDifference
/// @{

static Function TestGetListDifference()

	string result

	result = GetListDifference("", "")
	CHECK_EQUAL_STR("", result)

	result = GetListDifference("1;", "")
	CHECK_EQUAL_STR("1;", result)

	result = GetListDifference("1;2;", "1;")
	CHECK_EQUAL_STR("2;", result)

	result = GetListDifference("1;2;", "1;2;")
	CHECK_EQUAL_STR("", result)

	result = GetListDifference("a;A;", "a;")
	CHECK_EQUAL_STR("A;", result)

	result = GetListDifference("a;A;b;", "a;", caseSensitive = 0)
	CHECK_EQUAL_STR("b;", result)
End

/// @}

/// GetSetUnion
/// @{
Function GSU_ExpectsSameWaveType()

	Make/FREE/D data1
	Make/FREE/R data2

	try
		WAVE/Z matches = GetSetIntersection(data1, data2)
		FAIL()
	catch
		PASS()
	endtry
End

Function GSU_WorksWithFloat()

	Make/FREE data1 = {1, 4.5, Inf, -Inf}
	Make/FREE data2 = {1, 5, NaN, Inf}

	WAVE/Z union = GetSetUnion(data1, data2)
	CHECK_WAVE(union, NUMERIC_WAVE)
	Sort union, union

	CHECK_EQUAL_WAVES({-Inf, 1, 4.5, 5, Inf, NaN}, union)
End

Function GSU_WorksWithTextAndIsCaseSensitiveByDefault()

	Make/FREE/T data1 = {"ab", "cd", "ef"}
	Make/FREE/T data2 = {"ab", "11", "", "", "CD"}

	WAVE/Z union = GetSetUnion(data1, data2)
	CHECK_WAVE(union, TEXT_WAVE)
	Sort union, union

	CHECK_EQUAL_TEXTWAVES({"", "11", "ab", "CD", "cd", "ef"}, union)
End

Function GSU_WorksWithFirstEmpty()

	Make/FREE/N=0 data1
	Make/FREE data2 = {1, 1, 5, NaN, Inf}

	WAVE/Z union = GetSetUnion(data1, data2)
	CHECK_WAVE(union, NUMERIC_WAVE)
	Sort union, union

	CHECK_EQUAL_WAVES({1, 5, Inf, NaN}, union)
End

Function GSU_WorksWithSecondEmpty()

	Make/FREE data1 = {1, 1, 5, NaN, Inf}
	Make/FREE/N=0 data2

	WAVE/Z union = GetSetUnion(data1, data2)
	CHECK_WAVE(union, NUMERIC_WAVE)
	Sort union, union

	CHECK_EQUAL_WAVES({1, 5, Inf, NaN}, union)
End

Function GSU_WorksWithFirstEmptyText()

	Make/FREE/N=0/T data1
	Make/FREE/T data2 = {"ab", "cd", "ef", "ef"}

	WAVE/Z union = GetSetUnion(data1, data2)
	CHECK_WAVE(union, TEXT_WAVE)
	Sort union, union

	CHECK_EQUAL_TextWAVES({"ab", "cd", "ef"}, union)
End

Function GSU_WorksWithSecondEmptyText()

	Make/FREE/T data1 = {"ab", "cd", "ef", "ef"}
	Make/FREE/N=0/T data2

	WAVE/Z union = GetSetUnion(data1, data2)
	CHECK_WAVE(union, TEXT_WAVE)
	Sort union, union

	CHECK_EQUAL_TextWAVES({"ab", "cd", "ef"}, union)
End

Function GSU_WorksWithBothEqual()

	Make/FREE data = {1, 5, Inf, NaN}

	WAVE/Z union = GetSetUnion(data, data)
	CHECK_WAVE(union, NUMERIC_WAVE)

	Sort union, union

	CHECK_EQUAL_WAVES(data, union)
End

Function GSU_WorksWithBothEmptyAndEqual()

	Make/FREE/N=0 data

	WAVE/Z union = GetSetUnion(data, data)
	CHECK_WAVE(union, NULL_WAVE)
End

Function GSU_WorksWithBothEmpty()

	Make/FREE/N=0 data1, data2

	WAVE/Z union = GetSetUnion(data1, data2)
	CHECK_WAVE(union, NULL_WAVE)
End

/// @}

/// GetSetDifference
/// @{
Function GSD_ExpectsSameWaveType()

	Make/FREE/D data1
	Make/FREE/R data2

	try
		WAVE/Z matches = GetSetDifference(data1, data2)
		FAIL()
	catch
		PASS()
	endtry
End

static Function GSD_Expects1dWave1()

	Make/FREE/D/N=(1, 10) data1
	Make/FREE/D data2

	try
		WAVE/Z matches = GetSetDifference(data1, data2)
		FAIL()
	catch
		PASS()
	endtry
End

static Function GSD_WorksWithNdWave2()

	Make/FREE/D/N=5 data1 = p
	Make/FREE/D/N=(1, 3) data2 = q

	WAVE/Z matches = GetSetDifference(data1, data2)
	CHECK_EQUAL_WAVES(matches, {3, 4}, mode = WAVE_DATA | DIMENSION_SIZES)
End

Function GSD_ExpectsFPWaveType()

	Make/FREE/D data1
	Make/FREE/T data2

	try
		WAVE/Z matches = GetSetDifference(data1, data2)
		FAIL()
	catch
		PASS()
	endtry
End

Function GSD_Works1()

	Make/FREE data1 = {1, 2, 3, 4}
	Make/FREE data2 = {4, 5, 6}

	WAVE/Z matches = GetSetDifference(data1, data2)
	CHECK_EQUAL_WAVES(matches, {1, 2, 3})
End

Function GSD_Works2()

	Make/FREE data1 = {1, 2, 3, 4}
	Make/FREE data2 = {5, 6, 7}

	WAVE/Z matches = GetSetDifference(data1, data2)
	CHECK_EQUAL_WAVES(matches, {1, 2, 3, 4})
End

Function GSD_Works3()

	Make/FREE data1 = {1, 2, 3, 4}
	Make/FREE data2 = {4, 3, 2}

	WAVE/Z matches = GetSetDifference(data1, data2)
	CHECK_EQUAL_WAVES(matches, {1})
End

Function GSD_Works4()

	Make/FREE/D data1
	Make/FREE/D data2

	WAVE/Z matches = GetSetDifference(data1, data2)
	CHECK_WAVE(matches, NULL_WAVE)
End

Function GSD_Works5()

	Make/FREE/D data1
	Make/FREE/D/N=0 data2

	WAVE matches = GetSetDifference(data1, data2)
	CHECK_EQUAL_WAVES(matches, data1)
End

Function GSD_Works6()

	Make/FREE/D data1 = p
	Make/FREE/D data2 = -1

	WAVE matches = GetSetDifference(data1, data2)
	CHECK_EQUAL_WAVES(matches, data1)
End

Function GSD_WorksText1()

	Make/FREE/T data1 = {"1", "2", "3", "4"}
	Make/FREE/T data2 = {"4", "5", "6"}

	WAVE/Z matches = GetSetDifference(data1, data2)
	CHECK_EQUAL_TEXTWAVES(matches, {"1", "2", "3"})
End

Function GSD_WorksText2()

	Make/FREE/T data1 = {"1", "2", "3", "4"}
	Make/FREE/T data2 = {"5", "6", "7"}

	WAVE/Z matches = GetSetDifference(data1, data2)
	CHECK_EQUAL_TEXTWAVES(matches, {"1", "2", "3", "4"})
End

Function GSD_WorksText3()

	Make/FREE/T data1 = {"1", "2", "3", "4"}
	Make/FREE/T data2 = {"4", "3", "2"}

	WAVE/Z matches = GetSetDifference(data1, data2)
	CHECK_EQUAL_TEXTWAVES(matches, {"1"})
End

Function GSD_WorksText4()

	Make/FREE/T data1
	Make/FREE/T data2

	WAVE/Z matches = GetSetDifference(data1, data2)
	CHECK_WAVE(matches, NULL_WAVE)
End

Function GSD_WorksText5()

	Make/FREE/T data1
	Make/FREE/T/N=0 data2

	WAVE matches = GetSetDifference(data1, data2)
	CHECK_EQUAL_TEXTWAVES(matches, data1)
End

Function GSD_WorksText6()

	Make/FREE/T data1 = num2str(p)
	Make/FREE/T data2 = num2str(-1)

	WAVE matches = GetSetDifference(data1, data2)
	CHECK_EQUAL_TEXTWAVES(matches, data1)
End

Function GSD_ReturnsInvalidWaveRefWOMatches()

	Make/FREE/D/N=0 data1
	Make/FREE/D data2

	WAVE/Z matches = GetSetDifference(data1, data2)
	CHECK_WAVE(matches, NULL_WAVE)
End

Function GSD_Works_Indices()

	Make/FREE data1 = {1, 2, 3, 4}
	Make/FREE data2 = {4, 5, 6}

	WAVE/Z matches = GetSetDifference(data1, data2, getIndices = 1)
	CHECK_EQUAL_WAVES(matches, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z matches = GetSetDifference(data2, data1, getIndices = 1)
	CHECK_EQUAL_WAVES(matches, {1, 2}, mode = WAVE_DATA)

	Make/FREE data1 = {1, 4, 2, 3, 4}
	Make/FREE data2 = {4, 5, 4, 6}

	WAVE/Z matches = GetSetDifference(data1, data2, getIndices = 1)
	CHECK_EQUAL_WAVES(matches, {0, 2, 3}, mode = WAVE_DATA)

	WAVE/Z matches = GetSetDifference(data2, data1, getIndices = 1)
	CHECK_EQUAL_WAVES(matches, {1, 3}, mode = WAVE_DATA)
End

Function GSD_WorksText_Indices()

	Make/FREE/T data1 = {"a", "b", "c", "D"}
	Make/FREE/T data2 = {"c", "d", "e"}

	WAVE/Z matches = GetSetDifference(data1, data2, getIndices = 1)
	CHECK_EQUAL_WAVES(matches, {0, 1}, mode = WAVE_DATA)

	WAVE/Z matches = GetSetDifference(data2, data1, getIndices = 1)
	CHECK_EQUAL_WAVES(matches, {2}, mode = WAVE_DATA)

	Make/FREE/T data1 = {"a", "b", "c", "D", "c"}
	Make/FREE/T data2 = {"c", "d", "c", "e"}

	WAVE/Z matches = GetSetDifference(data1, data2, getIndices = 1)
	CHECK_EQUAL_WAVES(matches, {0, 1}, mode = WAVE_DATA)

	WAVE/Z matches = GetSetDifference(data2, data1, getIndices = 1)
	CHECK_EQUAL_WAVES(matches, {3}, mode = WAVE_DATA)
End

Function GSD_ReturnsInvalidWaveRefWOMatches1_indices()

	Make/FREE/D/N=0 data1
	Make/FREE/D data2

	WAVE/Z matches = GetSetDifference(data1, data2, getIndices = 1)
	CHECK_WAVE(matches, NULL_WAVE)
End

Function GSD_ReturnsInvalidWaveRefWOMatches2_indices()

	Make/FREE/D/N=0 data1
	Make/FREE/D/N=0 data2

	WAVE/Z matches = GetSetDifference(data1, data2, getIndices = 1)
	CHECK_WAVE(matches, NULL_WAVE)
End

Function GSD_ReturnsInvalidWaveRefWOMatches3_indices()

	Make/FREE/D data1 = p
	Make/FREE/D data2 = p

	WAVE/Z matches = GetSetDifference(data1, data2, getIndices = 1)
	CHECK_WAVE(matches, NULL_WAVE)
End
/// @}

/// GetSetIntersection
/// @{
Function GSI_ExpectsSameWaveType()

	Make/FREE/D data1
	Make/FREE/R data2

	try
		WAVE/Z matches = GetSetIntersection(data1, data2)
		FAIL()
	catch
		PASS()
	endtry
End

static Function GSI_Expects1dWave()

	Make/FREE/D/N=(1, 10) data1
	Make/FREE/D data2

	try
		WAVE/Z matches = GetSetIntersection(data1, data2)
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE/D data1
	Make/FREE/D/N=(1, 10) data2

	try
		WAVE/Z matches = GetSetIntersection(data1, data2)
		FAIL()
	catch
		PASS()
	endtry
End

Function GSI_Works()

	Make/FREE data1 = {1, 2, 3, 4}
	Make/FREE data2 = {4, 5, 6}

	WAVE/Z matches = GetSetIntersection(data1, data2)
	CHECK_EQUAL_WAVES(matches, {4})
End

Function GSI_WorksText()

	Make/FREE/T data1 = {"a", "b", "c", "D"}
	Make/FREE/T data2 = {"c", "d", "e"}

	WAVE/Z/T matches = GetSetIntersection(data1, data2)
	CHECK_EQUAL_TEXTWAVES(matches, {"c"})
End

Function GSI_ReturnsCorrectType()

	Make/FREE/D data1
	Make/FREE/D data2

	WAVE matches = GetSetIntersection(data1, data2)
	CHECK_EQUAL_WAVES(data1, matches)
End

Function GSI_WorksWithTheSameWaves()

	Make/FREE/D data = p

	WAVE matches = GetSetIntersection(data, data)
	CHECK_EQUAL_WAVES(data, matches)
	CHECK(!WaveRefsEqual(data, matches))
End

Function GSI_ReturnsInvalidWaveRefWOMatches1()

	Make/FREE/D/N=0 data1
	Make/FREE/D data2

	WAVE/Z matches = GetSetIntersection(data1, data2)
	CHECK_WAVE(matches, NULL_WAVE)
End

Function GSI_ReturnsInvalidWaveRefWOMatches2()

	Make/FREE/D data1
	Make/FREE/D/N=0 data2

	WAVE/Z matches = GetSetIntersection(data1, data2)
	CHECK_WAVE(matches, NULL_WAVE)
End

Function GSI_ReturnsInvalidWaveRefWOMatches3()

	Make/FREE/D data1 = p
	Make/FREE/D data2 = -1

	WAVE/Z matches = GetSetIntersection(data1, data2)
	CHECK_WAVE(matches, NULL_WAVE)
End

Function GSI_Works_Indices()

	Make/FREE data1 = {1, 2, 3, 4}
	Make/FREE data2 = {4, 5, 6}

	WAVE/Z matches = GetSetIntersection(data1, data2, getIndices = 1)
	CHECK_EQUAL_WAVES(matches, {3}, mode = WAVE_DATA)

	WAVE/Z matches = GetSetIntersection(data2, data1, getIndices = 1)
	CHECK_EQUAL_WAVES(matches, {0}, mode = WAVE_DATA)

	Make/FREE data1 = {1, 4, 2, 3, 4}
	Make/FREE data2 = {4, 5, 4, 6}

	WAVE/Z matches = GetSetIntersection(data1, data2, getIndices = 1)
	CHECK_EQUAL_WAVES(matches, {1, 4}, mode = WAVE_DATA)

	WAVE/Z matches = GetSetIntersection(data2, data1, getIndices = 1)
	CHECK_EQUAL_WAVES(matches, {0, 2}, mode = WAVE_DATA)
End

Function GSI_WorksText_Indices()

	Make/FREE/T data1 = {"a", "b", "c", "D"}
	Make/FREE/T data2 = {"c", "d", "e"}

	WAVE/Z matches = GetSetIntersection(data1, data2, getIndices = 1)
	CHECK_EQUAL_WAVES(matches, {2}, mode = WAVE_DATA)

	WAVE/Z matches = GetSetIntersection(data2, data1, getIndices = 1)
	CHECK_EQUAL_WAVES(matches, {0}, mode = WAVE_DATA)

	Make/FREE/T data1 = {"a", "b", "c", "D", "c"}
	Make/FREE/T data2 = {"c", "d", "c", "e"}

	WAVE/Z matches = GetSetIntersection(data1, data2, getIndices = 1)
	CHECK_EQUAL_WAVES(matches, {2, 4}, mode = WAVE_DATA)

	WAVE/Z matches = GetSetIntersection(data2, data1, getIndices = 1)
	CHECK_EQUAL_WAVES(matches, {0, 2}, mode = WAVE_DATA)
End

Function GSI_ReturnsInvalidWaveRefWOMatches1_indices()

	Make/FREE/D/N=0 data1
	Make/FREE/D data2

	WAVE/Z matches = GetSetIntersection(data1, data2, getIndices = 1)
	CHECK_WAVE(matches, NULL_WAVE)
End

Function GSI_ReturnsInvalidWaveRefWOMatches2_indices()

	Make/FREE/D data1
	Make/FREE/D/N=0 data2

	WAVE/Z matches = GetSetIntersection(data1, data2, getIndices = 1)
	CHECK_WAVE(matches, NULL_WAVE)
End

Function GSI_ReturnsInvalidWaveRefWOMatches3_indices()

	Make/FREE/D data1 = p
	Make/FREE/D data2 = -1

	WAVE/Z matches = GetSetIntersection(data1, data2, getIndices = 1)
	CHECK_WAVE(matches, NULL_WAVE)
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

// UTF_TD_GENERATOR InfiniteValues
Function FLW_RequiresFiniteLevel([variable var])

	try
		Make/FREE data
		FindLevelWrapper(data, var, FINDLEVEL_EDGE_BOTH, FINDLEVEL_MODE_SINGLE)
		FAIL()
	catch
		PASS()
	endtry
End

Function FLW_Requires2DWave()

	try
		Make/FREE/N=(10, 20, 30) data
		FindLevelWrapper(data, 0.1, FINDLEVEL_EDGE_BOTH, FINDLEVEL_MODE_SINGLE)
		FAIL()
	catch
		PASS()
	endtry
End

Function FLW_PreservesWaveLayout()

	Make/FREE/N=(10, 20, 1) data
	Duplicate/FREE data, dataOrig

	FindLevelWrapper(data, 0.1, FINDLEVEL_EDGE_BOTH, FINDLEVEL_MODE_SINGLE)

	CHECK_EQUAL_WAVES(data, dataOrig)
End

Function FLW_RequiresBigEnoughWave()

	try
		Make/FREE/N=(1) data
		FindLevelWrapper(data, 0.1, FINDLEVEL_EDGE_BOTH, FINDLEVEL_MODE_SINGLE)
		FAIL()
	catch
		PASS()
	endtry
End

// UTF_TD_GENERATOR DataGenerators#FLW_SampleData
Function FLW_SameResultsAsFindLevelSingle([WAVE wv])

	variable i, edge, level, numCols

	edge  = GetNumberFromWaveNote(wv, "edge")
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

// UTF_TD_GENERATOR DataGenerators#FLW_SampleDataMulti
Function FLW_MultiWorks([WAVE wv])

	variable i, edge, level

	WAVE/WAVE wvWave = wv

	WAVE data      = wvWave[0]
	WAVE resultRef = wvWave[1]

	edge  = GetNumberFromWaveNote(data, "edge")
	level = GetNumberFromWaveNote(data, "level")

	Duplicate/FREE data, dataCopy

	WAVE result = FindLevelWrapper(data, level, edge, FINDLEVEL_MODE_MULTI)
	CHECK_EQUAL_WAVES(data, dataCopy)
	CHECK_EQUAL_WAVES(result, resultRef, tol = 1e-8)
End

Function FLW_MaxNumberOfLevelsWorks()

	Make/FREE data = {10, 20, 10, 20, 10, 20}

	WAVE/Z result = FindLevelWrapper(data, 15, FINDLEVEL_EDGE_INCREASING, FINDLEVEL_MODE_MULTI)
	CHECK_WAVE(result, NUMERIC_WAVE)
	Redimension/N=(numpnts(result))/E=1 result
	CHECK_EQUAL_WAVES(result, {0.5, 2.5, 4.5}, mode = WAVE_DATA)

	WAVE/Z result = FindLevelWrapper(data, 15, FINDLEVEL_EDGE_INCREASING, FINDLEVEL_MODE_MULTI, maxNumLevels = 2)
	CHECK_WAVE(result, NUMERIC_WAVE)
	Redimension/N=(numpnts(result))/E=1 result
	CHECK_EQUAL_WAVES(result, {0.5, 2.5}, mode = WAVE_DATA)
End

/// @}

/// DistributeElements
/// @{

Function DE_Basics()

	[WAVE start, WAVE stop] = DistributeElements(2)
	CHECK_WAVE(start, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK_WAVE(stop, NUMERIC_WAVE, minorType = DOUBLE_WAVE)

	CHECK_EQUAL_WAVES(start, {0.0, 0.515}, mode = WAVE_DATA, tol = 1e-8)
	CHECK_EQUAL_WAVES(stop, {0.485, 1.0}, mode = WAVE_DATA, tol = 1e-8)
End

Function DE_OffsetWorks()

	variable offset = 0.01

	[WAVE start, WAVE stop] = DistributeElements(2, offset = offset)
	CHECK_WAVE(start, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK_WAVE(stop, NUMERIC_WAVE, minorType = DOUBLE_WAVE)

	CHECK_EQUAL_WAVES(start, {0.01, 0.52}, mode = WAVE_DATA, tol = 1e-8)
	CHECK_EQUAL_WAVES(stop, {0.49, 1.0}, mode = WAVE_DATA, tol = 1e-8)
End

Function DE_ManyElements()

	[WAVE start, WAVE stop] = DistributeElements(10)
	CHECK_WAVE(start, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK_WAVE(stop, NUMERIC_WAVE, minorType = DOUBLE_WAVE)

	Make/FREE/D refStart = {0, 0.102222222222222, 0.204444444444444, 0.306666666666667, 0.408888888888889, 0.511111111111111, 0.613333333333333, 0.715555555555556, 0.817777777777778, 0.92}
	Make/FREE/D refStop = {0.08, 0.182222222222222, 0.284444444444444, 0.386666666666667, 0.488888888888889, 0.591111111111111, 0.693333333333333, 0.795555555555556, 0.897777777777778, 1}

	CHECK_EQUAL_WAVES(start, refStart, mode = WAVE_DATA, tol = 1e-8)
	CHECK_EQUAL_WAVES(stop, refStop, mode = WAVE_DATA, tol = 1e-8)
End

/// @}

/// CalculateNiceLength
/// @{

Function CNL_Works()

	variable fraction = 0.1

	CHECK_EQUAL_VAR(CalculateNiceLength(fraction * 90, 5), 10)
	CHECK_EQUAL_VAR(CalculateNiceLength(fraction * 60, 5), 5)
	CHECK_EQUAL_VAR(CalculateNiceLength(fraction * 20, 5), 5)
	CHECK_EQUAL_VAR(CalculateNiceLength(fraction * 2, 5), 0.5)
	CHECK_EQUAL_VAR(CalculateNiceLength(fraction * 1, 5), 0.05)
	CHECK_EQUAL_VAR(CalculateNiceLength(fraction * 0.5, 5), 0.05)
End

/// @}

// BinarySearchText
/// @{

Function BST_ErrorChecking()

	try
		Make/FREE/D wvDouble
		WAVE/T wv = wvDouble
		BinarySearchText(wv, "a")
		FAIL()
	catch
		PASS()
	endtry

	try
		Make/FREE/T/N=(2, 2) wv
		BinarySearchText(wv, "a")
		FAIL()
	catch
		PASS()
	endtry

	try
		Make/FREE/T wv = {"a"}
		BinarySearchText(wv, "a", startPos = -1, endPos = 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		Make/FREE/T wv = {"a"}
		BinarySearchText(wv, "a", startPos = 0, endPos = -1)
		FAIL()
	catch
		PASS()
	endtry

	try
		Make/FREE/T wv = {"a"}
		BinarySearchText(wv, "a", startPos = NaN, endPos = 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		Make/FREE/T wv = {"a"}
		BinarySearchText(wv, "a", startPos = 0, endPos = NaN)
		FAIL()
	catch
		PASS()
	endtry

	try
		Make/FREE/T wv = {"a"}
		BinarySearchText(wv, "a", startPos = 1, endPos = 2)
		FAIL()
	catch
		PASS()
	endtry

	try
		Make/FREE/T wv = {"a", "a"}
		BinarySearchText(wv, "a", startPos = 1, endPos = 0)
		FAIL()
	catch
		PASS()
	endtry
End

Function BST_Works()

	Make/T/FREE/N=0 wv
	CHECK_EQUAL_VAR(BinarySearchText(wv, "a"), NaN) // no match by definition

	Make/T/FREE wv = {"a"}
	CHECK_EQUAL_VAR(BinarySearchText(wv, "a"), 0)
	CHECK_EQUAL_VAR(BinarySearchText(wv, "a", startPos = 0, endPos = 0), 0)

	Make/T/FREE wv = {"a", "a", "a"}
	CHECK_EQUAL_VAR(BinarySearchText(wv, "a"), 0)

	Make/T/FREE wv = {"a", "a", "a"}
	CHECK_EQUAL_VAR(BinarySearchText(wv, "A"), 0) // matches case insensitive

	Make/T/FREE wv = {"a", "a", "a"}
	CHECK_EQUAL_VAR(BinarySearchText(wv, "b"), NaN) // no match

	Make/T/FREE wv = {"a", "b", "c"}
	CHECK_EQUAL_VAR(BinarySearchText(wv, "c"), 2)

	Make/T/FREE wv = {"B", "a", "b"}
	CHECK_EQUAL_VAR(BinarySearchText(wv, "B", caseSensitive = 1), 0)
End

/// @}

// CompressNumericalList
/// @{

static Function CompressNumericalList()

	string list, ref

	list = "1,2"
	ref  = "1-2"
	list = MIES_UTILS_ALGORITHM#CompressNumericalList(list, ",")
	CHECK_EQUAL_STR(list, ref)

	list = "-1,0,1"
	ref  = "-1-1"
	list = MIES_UTILS_ALGORITHM#CompressNumericalList(list, ",")
	CHECK_EQUAL_STR(list, ref)

	list = "1,2,3,5,6,7"
	ref  = "1-3,5-7"
	list = MIES_UTILS_ALGORITHM#CompressNumericalList(list, ",")
	CHECK_EQUAL_STR(list, ref)

	list = ""
	ref  = ""
	list = MIES_UTILS_ALGORITHM#CompressNumericalList(list, ",")
	CHECK_EQUAL_STR(list, ref)

	list = "1,2,2,3,3,4,6"
	ref  = "1-4,6"
	list = MIES_UTILS_ALGORITHM#CompressNumericalList(list, ",")
	CHECK_EQUAL_STR(list, ref)

	list = "6,4,3,3,2,2,1"
	ref  = "1-4,6"
	list = MIES_UTILS_ALGORITHM#CompressNumericalList(list, ",")
	CHECK_EQUAL_STR(list, ref)

	list = "string"
	try
		list = MIES_UTILS_ALGORITHM#CompressNumericalList(list, ",")
		FAIL()
	catch
		PASS()
	endtry

	list = "1,1.5,2"
	try
		list = MIES_UTILS_ALGORITHM#CompressNumericalList(list, ",")
		FAIL()
	catch
		PASS()
	endtry

	list = "1,2"
	try
		list = MIES_UTILS_ALGORITHM#CompressNumericalList(list, "")
		FAIL()
	catch
		PASS()
	endtry
End

/// @}

// SplitLogDataBySize
/// @{

static Function TestSplitLogDataBySize()

	string str = PadString("", 10, 0x41)

	Make/FREE/T logData = {str, str, str}

	try
		WAVE/WAVE result = SplitLogDataBySize(logData, "", 1)
		FAIL()
	catch
		PASS()
	endtry

	try
		WAVE/WAVE result = SplitLogDataBySize(logData, "\n", strlen(str))
		FAIL()
	catch
		PASS()
	endtry

	try
		WAVE/WAVE result = SplitLogDataBySize(logData, "", strlen(str), firstPartSize = 1)
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE/T strData = {str}
	Make/FREE/WAVE ref = {strData, strData, strData}
	WAVE/WAVE result = SplitLogDataBySize(logData, "", 10)
	CHECK_EQUAL_WAVES(result, ref, mode = -1 %^ WAVE_DATA)
	for(resultContent : result)
		CHECK_EQUAL_WAVES(resultContent, strData, mode = -1 %^ WAVE_SCALING)
	endfor

	Make/FREE/T strData = {str}
	Make/FREE/T strData2 = {str, str}
	Make/FREE/WAVE ref = {strData2, strData}
	WAVE/WAVE result = SplitLogDataBySize(logData, "", 20)
	CHECK_EQUAL_WAVES(result, ref, mode = -1 %^ WAVE_DATA)
	CHECK_EQUAL_WAVES(result[0], ref[0], mode = -1 %^ WAVE_SCALING)
	CHECK_EQUAL_WAVES(result[1], ref[1], mode = -1 %^ WAVE_SCALING)

	Make/FREE/T strData = {str, str, str}
	Make/FREE/WAVE ref = {strData}
	WAVE/WAVE result = SplitLogDataBySize(logData, "", 30)
	CHECK_EQUAL_WAVES(result, ref, mode = -1 %^ WAVE_DATA)
	CHECK_EQUAL_WAVES(result[0], strData)

	Make/FREE/T strData = {str}
	Make/FREE/WAVE ref = {strData, strData, strData}
	WAVE/WAVE result = SplitLogDataBySize(logData, "\n", 11)
	CHECK_EQUAL_WAVES(result, ref, mode = -1 %^ WAVE_DATA)
	for(resultContent : result)
		CHECK_EQUAL_WAVES(resultContent, strData, mode = -1 %^ WAVE_SCALING)
	endfor

	Make/FREE/T strData = {str}
	Make/FREE/WAVE ref = {strData, strData}
	WAVE/WAVE result = SplitLogDataBySize(logData, "", 10, lastIndex = 1)
	CHECK_EQUAL_WAVES(result, ref, mode = -1 %^ WAVE_DATA)
	for(resultContent : result)
		CHECK_EQUAL_WAVES(resultContent, strData, mode = -1 %^ WAVE_SCALING)
	endfor

	Make/FREE/T strData = {str}
	Make/FREE/WAVE ref = {strData}
	WAVE/WAVE result = SplitLogDataBySize(logData, "", 10, lastIndex = -1)
	CHECK_EQUAL_WAVES(result, ref, mode = -1 %^ WAVE_DATA)
	for(resultContent : result)
		CHECK_EQUAL_WAVES(resultContent, strData, mode = -1 %^ WAVE_SCALING)
	endfor

	Make/FREE/T strData = {str}
	Make/FREE/WAVE ref = {strData, strData, strData}
	WAVE/WAVE result = SplitLogDataBySize(logData, "", 10, lastIndex = Inf)
	CHECK_EQUAL_WAVES(result, ref, mode = -1 %^ WAVE_DATA)
	for(resultContent : result)
		CHECK_EQUAL_WAVES(resultContent, strData, mode = -1 %^ WAVE_SCALING)
	endfor

	Make/FREE/T strData = {str}
	Make/FREE/T strData2 = {str, str}
	Make/FREE/WAVE ref = {strData, strData2}
	WAVE/WAVE result = SplitLogDataBySize(logData, "", 20, firstPartSize = 10)
	CHECK_EQUAL_WAVES(result, ref, mode = -1 %^ WAVE_DATA)
	WAVE data = result[0]
	CHECK_EQUAL_WAVES(result[0], ref[0], mode = -1 %^ WAVE_SCALING)
	WAVE data = result[1]
	CHECK_EQUAL_WAVES(result[1], ref[1], mode = -1 %^ WAVE_SCALING)
End

/// @}

// MergeSortStableInplace
/// @{

static Function TestMergeSortStableInPlace()

	Make/FREE data = {4, 6, 1, -5, 10, 5}
	MergeSortStableInplace(data)
	CHECK_EQUAL_WAVES(data, {-5, 1, 4, 5, 6, 10})

	Make/FREE data = {1}
	MergeSortStableInplace(data)
	CHECK_EQUAL_WAVES(data, {1})

	Make/FREE/N=0 empty
	MergeSortStableInplace(data)
	Make/FREE/N=0 emptyRef
	CHECK_EQUAL_WAVES(empty, emptyRef)

	// maintains the order of neighbouring elements with the same keys

	Make/FREE data = {{4, 6, 5, 5, 10, 5}, {0, 1, 2, 3, 4, 5}}
	MergeSortStableInplace(data, col = 0)
	CHECK_EQUAL_WAVES(data, {{4, 5, 5, 5, 6, 10}, {0, 2, 3, 5, 1, 4}})

	// different column
	Make/FREE data = {{0, 1, 2, 3, 4, 5}, {4, 6, 5, 5, 10, 5}}
	MergeSortStableInplace(data, col = 1)
	CHECK_EQUAL_WAVES(data, {{0, 2, 3, 5, 1, 4}, {4, 5, 5, 5, 6, 10}})

End

/// @}

static Function TestSortKeyAndData()

	Make/FREE key = {3, 1, 2}
	Make/FREE data = {-1, -2, -3}
	[WAVE keySorted, WAVE dataSorted] = SortKeyAndData(key, data)

	CHECK_EQUAL_WAVES(keySorted, {1, 2, 3})
	CHECK_EQUAL_VAR(DimSize(KeySorted, COLS), 0)
	CHECK_EQUAL_WAVES(dataSorted, {-2, -3, -1})
	CHECK_EQUAL_VAR(DimSize(dataSorted, COLS), 0)
End

// FindSequenceReverseWrapper
/// @{

static Function TestFindSequenceReverseWrapper()

	variable idx

	// works
	Make/FREE/D seq = {0, 1}
	Make/FREE/D source = {0, 1, 0, 1}
	idx = FindSequenceReverseWrapper(seq, source)
	CHECK_EQUAL_VAR(idx, 2)

	// no match
	Make/FREE/D seq = {0, 0}
	Make/FREE/D source = {0, 1, 0, 1}
	idx = FindSequenceReverseWrapper(seq, source)
	CHECK_EQUAL_VAR(idx, -1)
End

/// @}
