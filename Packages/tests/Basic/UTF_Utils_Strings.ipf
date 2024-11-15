#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTILSTEST_STRINGS

// Missing Tests for:
// SearchStringBase
// CountSubstrings
// GetDecimalMultiplierValue
// ReplaceRegexInString
// NumBytesInUTF8Character
// UTF8CharactersInString
// UTF8CharacterAtPosition

/// ExtractStringFromPair
/// @{

Function ESFP_CheckParams()

	try
		ExtractStringFromPair("abcd", "")
		FAIL()
	catch
		PASS()
	endtry
End

// These tests also cover GetStringFromWaveNote()
Function ESFP_Works()

	string ref, str

	ref = "123"
	str = ExtractStringFromPair("abcd:123;abcde:456", "abcd")
	CHECK_EQUAL_STR(ref, str)

	// ignores case
	ref = "123"
	str = ExtractStringFromPair("abcd:123;abcde:456", "ABCD")
	CHECK_EQUAL_STR(ref, str)

	// ignores space from AddEntryIntoWaveNoteAsList
	ref = "123"
	str = ExtractStringFromPair("abcd : 123;abcde : 456", "ABCD")
	CHECK_EQUAL_STR(ref, str)

	// supports custom separators
	ref = "456"
	str = ExtractStringFromPair("abcd=123|abcde=456|", "abcde", keySep = "=", listSep = "|")
	CHECK_EQUAL_STR(ref, str)

	// no match
	str = ExtractStringFromPair("abcd:123;abcde:456", "abcdef")
	CHECK_EMPTY_STR(str)

	// empty string
	str = ExtractStringFromPair("", "abcdef")
	CHECK_EMPTY_STR(str)
End

/// @}

/// PossiblyUnquoteName
/// @{

Function PUN_Works()

	string str, ref

	str = PossiblyUnquoteName("", "'")
	CHECK_EMPTY_STR(str)

	str = PossiblyUnquoteName("'a", "'")
	ref = "'a"
	CHECK_EQUAL_STR(str, ref)

	str = PossiblyUnquoteName("'a'", "'")
	ref = "a"
	CHECK_EQUAL_STR(str, ref)
End

Function PUN_ChecksParams()

	try
		PossiblyUnquoteName("abcd", "")
		FAIL()
	catch
		PASS()
	endtry

	try
		PossiblyUnquoteName("abcd", "''")
		FAIL()
	catch
		PASS()
	endtry

	try
		PossiblyUnquoteName("a", "a")
		FAIL()
	catch
		PASS()
	endtry
End

/// @}

/// LineBreakingIntoPar
/// @{

// UTF_TD_GENERATOR DataGenerators#NonFiniteValues
Function LBP_Aborts([variable var])

	try
		LineBreakingIntoPar("", minimumWidth = var); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

Function LBP_Works()

	string str, expected

	str      = LineBreakingIntoPar("abcd efgh 123 one two\tfour")
	expected = "abcd\refgh 123\rone\rtwo\rfour"
	CHECK_EQUAL_STR(str, expected)

	str      = LineBreakingIntoPar("abcd efgh 123 one two\tfour", minimumWidth = 10)
	expected = "abcd efgh 123\rone two\tfour"
	CHECK_EQUAL_STR(str, expected)
End

/// @}

/// RemovePrefix
/// @{

Function RP_Works()

	string ref, str

	str = RemovePrefix("")
	CHECK_EMPTY_STR(str)

	str = RemovePrefix("abcd")
	ref = "bcd"
	CHECK_EQUAL_STR(ref, str)

	str = RemovePrefix("abcd", start = "ab")
	ref = "cd"
	CHECK_EQUAL_STR(ref, str)

	// no match, wrong
	str = RemovePrefix("abcd", start = "123")
	ref = "abcd"
	CHECK_EQUAL_STR(ref, str)

	// no match, too long
	str = RemovePrefix("abcd", start = "abcde")
	ref = "abcd"
	CHECK_EQUAL_STR(ref, str)

	// regexp
	str = RemovePrefix("abcd123", start = "[a-z]*", regexp = 1)
	ref = "123"
	CHECK_EQUAL_STR(ref, str)

	// regexp, no match
	str = RemovePrefix("abcd", start = "[0-9]*", regexp = 1)
	ref = "abcd"
	CHECK_EQUAL_STR(ref, str)

	// invalid regexp
	str = RemovePrefix("abcd", start = "[::I_DONT_EXIST::]*", regexp = 1)
	ref = "abcd"
	CHECK_EQUAL_STR(ref, str)
End

/// @}

/// RemoveEndingRegExp
/// @{

static Function TestRemoveEndingRegex()

	string result

	// does nothing with empty string
	result = RemoveEndingRegExp("", ".*")
	CHECK_EMPTY_STR(result)

	// does nothing with empty regex
	result = RemoveEndingRegExp("abcd", "")
	CHECK_EQUAL_STR(result, "abcd")

	// complains with invalid regex
	try
		RemoveEndingRegExp("abcd", "*")
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// matches
	result = RemoveEndingRegExp("abcdd", "d*")
	CHECK_EQUAL_STR(result, "abc")

	// no match
	result = RemoveEndingRegExp("abcd", "efgh")
	CHECK_EQUAL_STR(result, "abcd")

	// too many matches
	try
		RemoveEndingRegExp("abcd", "ab)(cd")
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

/// @}

/// SearchWordInString
/// @{

Function TestSearchWordInString()

	variable ret
	string prefix, suffix

	ret = SearchWordInString("ab cd efgh", "ijk")
	CHECK_EQUAL_VAR(ret, 0)

	// no match as no word boundary after "c"
	ret = SearchWordInString("ab cd efgh", "c")
	CHECK_EQUAL_VAR(ret, 0)

	// match
	ret = SearchWordInString("ab cd efgh", "cd")
	CHECK_EQUAL_VAR(ret, 1)

	// match with prefix and suffix
	ret = SearchWordInString("ab#cd?efgh", "cd", prefix = prefix, suffix = suffix)
	CHECK_EQUAL_VAR(ret, 1)
	CHECK_EQUAL_STR(prefix, "ab#")
	CHECK_EQUAL_STR(suffix, "?efgh")
End

/// @}

/// ParseUnit
/// @{

// UTF_TD_GENERATOR DataGenerators#InvalidUnits
Function PU_Fails([string str])

	string unit, prefix
	variable numPrefix = NaN

	try
		ParseUnit(str, prefix, numPrefix, unit)
		FAIL()
	catch
		PASS()
	endtry

	CHECK_EMPTY_STR(prefix)
	CHECK_EQUAL_VAR(numPrefix, NaN)
	CHECK_EMPTY_STR(unit)
End

// UTF_TD_GENERATOR DataGenerators#ValidUnits
Function PU_Works([WAVE/T wv])

	string unit, prefix, unitWithPrefix
	string refUnit, refPrefix
	variable numPrefix, refNumPrefix

	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 4)

	unitWithPrefix = wv[0]
	refPrefix      = wv[1]
	refNumPrefix   = str2num(wv[2])
	refUnit        = wv[3]

	ParseUnit(unitWithPrefix, prefix, numPrefix, unit)
	CHECK_EQUAL_STR(prefix, refPrefix)
	CHECK_EQUAL_VAR(numPrefix, numPrefix)
	CHECK_EQUAL_STR(unit, unit)
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

	string eol   = "\r"
	string input = "hi there!\r"

	string output   = NormalizeToEOL(input, eol)
	string expected = input
	CHECK_EQUAL_STR(output, expected)
End

Function NTE_Works2()

	string eol   = "\r"
	string input = "hi there!\n\n\r"

	string output   = NormalizeToEOL(input, eol)
	string expected = "hi there!\r\r\r"
	CHECK_EQUAL_STR(output, expected)
End

Function NTE_Works3()

	string eol   = "\r"
	string input = "hi there!\r\n\r" // CR+LF -> CR

	string output   = NormalizeToEOL(input, eol)
	string expected = "hi there!\r\r"
	CHECK_EQUAL_STR(output, expected)
End

Function NTE_Works4()

	string eol   = "\n"
	string input = "hi there!\r\n\r" // CR+LF -> CR

	string output   = NormalizeToEOL(input, eol)
	string expected = "hi there!\n\n"
	CHECK_EQUAL_STR(output, expected)
End

/// @}

/// ElideText
/// @{

// UTF_TD_GENERATOR DataGenerators#ETValidInput
Function ET_Works([WAVE/T wv])

	string ref, str, result
	variable length

	str    = wv[0]
	ref    = wv[1]
	length = str2num(wv[2])

	result = ElideText(str, length)
	CHECK_EQUAL_STR(ref, result)
	CHECK_LE_VAR(strlen(ref), length)
End

// UTF_TD_GENERATOR DataGenerators#ETInvalidInput
Function ET_Fails([WAVE/T wv])

	string   str
	variable length

	str    = wv[0]
	length = str2num(wv[1])

	try
		ElideText(str, length)
		FAIL()
	catch
		PASS()
	endtry
End

/// @}

/// UpperCaseFirstChar
/// @{

static Function TestUpperCaseFirstChar()

	string ret = UpperCaseFirstChar("")
	CHECK_EMPTY_STR(ret)
	CHECK_EQUAL_STR(UpperCaseFirstChar("1a"), "1a")
	CHECK_EQUAL_STR(UpperCaseFirstChar("a1a"), "A1a")
	CHECK_EQUAL_STR(UpperCaseFirstChar("b"), "B")
End

/// @}
