#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTILSTEST_CHECKS

// Missing Tests for:
// IsFinite
// IsNaN
// IsInf
// IsNull
// IsEmpty
// WindowExists
// ValueCanBeWritten
// IsInteger
// FuncRefIsAssigned
// CheckIfClose
// CheckIfSmall
// IsTextWave
// IsNumericWave
// IsWaveRefWave
// IsFloatingPointWave
// IsDoubleFloatingPointWave
// IsSingleFloatingPointWave
// IsGlobalWave
// IsComplexWave
// IsFreeWave
// StringEndsWith
// ListHasOnlyOneUniqueEntry

/// IsEven
/// @{

Function IE_Works()

	CHECK(IsEven(0))
	CHECK(!IsEven(-1))
	CHECK(IsEven(-2))
	CHECK(IsEven(2))
	CHECK(!IsEven(1.5))
End

// UTF_TD_GENERATOR DataGenerators#NonFiniteValues
Function IE_FalseWithNonFiniteValues([variable var])

	CHECK(!IsEven(var))
End

/// @}

/// IsOdd
/// @{

Function IO_Works()

	CHECK(!IsOdd(0))
	CHECK(!IsOdd(-2))
	CHECK(IsOdd(-1))
	CHECK(IsOdd(1))
	CHECK(!IsOdd(1.5))
End

// UTF_TD_GENERATOR DataGenerators#NonFiniteValues
Function IO_FalseWithNonFiniteValues([variable var])

	CHECK(!IsOdd(var))
End

/// @}

/// HasOneValidEntry
/// @{

Function HOV_AssertsOnInvalidType()

	Make/B/FREE wv
	try
		HasOneValidEntry(wv)
		FAIL()
	catch
		PASS()
	endtry
End

Function HOV_AssertsOnEmptyWave()

	Make/FREE/D/N=0 wv
	try
		HasOneValidEntry(wv)
		FAIL()
	catch
		PASS()
	endtry
End

Function HOV_Works1()

	Make/FREE/D/N=10 wv = NaN
	CHECK(!HasOneValidEntry(wv))
End

Function HOV_Works2()

	Make/FREE/D/N=10 wv = NaN
	wv[9] = 1
	CHECK(HasOneValidEntry(wv))
End

Function HOV_Works3()

	Make/FREE/D/N=10 wv = NaN
	wv[9] = Inf
	CHECK(HasOneValidEntry(wv))
End

Function HOV_Works4()

	Make/FREE/D/N=10 wv = NaN
	wv[9] = -Inf
	CHECK(HasOneValidEntry(wv))
End

Function HOV_WorksWithReal()

	Make/FREE/R/N=10 wv = NaN
	wv[9] = -Inf
	CHECK(HasOneValidEntry(wv))
End

Function HOV_WorksWith2D()

	Make/FREE/R/N=(10, 9) wv = NaN
	wv[2, 3] = 4711
	CHECK(HasOneValidEntry(wv))
End

Function HOV_WorksWithText1()

	Make/FREE/T/N=(2) wv = ""
	CHECK(!HasOneValidEntry(wv))
End

Function HOV_WorksWithText2()

	Make/FREE/T/N=(2) wv = ""
	wv[0] = "a"
	CHECK(HasOneValidEntry(wv))
End

/// @}

/// HasOneFiniteEntry
/// @{

static Function HasOneFiniteEntry_AssertsOnInvalidType()

	Make/B/FREE wv
	try
		HasOneFiniteEntry(wv)
		FAIL()
	catch
		PASS()
	endtry
End

static Function HasOneFiniteEntry_Works1()

	Make/FREE/D wv = {Inf, -Inf, NaN}
	CHECK(!HasOneFiniteEntry(wv))
End

static Function HasOneFiniteEntry_Works2()

	Make/FREE/D wv = {Inf, -Inf, NaN, 0}
	CHECK(HasOneFiniteEntry(wv))
End

static Function HasOneFiniteEntry_Works3()

	Make/FREE/D/N=0 wv
	CHECK(!HasOneFiniteEntry(wv))
End

/// @}

/// HasOneNonFiniteEntry
/// @{

static Function HasOneNonFiniteEntry_AssertsOnInvalidType()

	Make/B/FREE wv
	try
		HasOneNonFiniteEntry(wv)
		FAIL()
	catch
		PASS()
	endtry
End

static Function HasOneNonFiniteEntry_Works1()

	Make/FREE/D wv = {1, 2, 3}
	CHECK(!HasOneNonFiniteEntry(wv))
End

static Function HasOneNonFiniteEntry_Works2()

	Make/FREE/D wv = {Inf, 0}
	CHECK(HasOneNonFiniteEntry(wv))

	Make/FREE/D wv = {-Inf, 1}
	CHECK(HasOneNonFiniteEntry(wv))

	Make/FREE/D wv = {NaN, 3}
	CHECK(HasOneNonFiniteEntry(wv))
End

static Function HasOneNonFiniteEntry_Works3()

	Make/FREE/D/N=0 wv
	CHECK(!HasOneNonFiniteEntry(wv))
End

/// @}

/// EqualValuesOrBothNaN
/// @{

Function EVOB_Works()

	CHECK(!EqualValuesOrBothNaN(0, 1))
	CHECK(EqualValuesOrBothNaN(0, 0))
	CHECK(!EqualValuesOrBothNaN(0, NaN))
	CHECK(!EqualValuesOrBothNaN(NaN, 0))
	CHECK(!EqualValuesOrBothNaN(Inf, NaN))
	CHECK(!EqualValuesOrBothNaN(NaN, Inf))
	CHECK(EqualValuesOrBothNaN(NaN, NaN))
End

/// @}

/// IsConstant
/// @{

Function IC_Works()

	CHECK_EQUAL_VAR(IsConstant({1, 1, 1}, 1), 1)
	CHECK_EQUAL_VAR(IsConstant({-1, 2, 3}, 0), 0)
End

// UTF_TD_GENERATOR InfiniteValues
Function IC_WorksSpecialValues([variable val])

	Make/FREE/N=0 empty
	CHECK_EQUAL_VAR(IsConstant(empty, val, ignoreNaN = 0), NaN)
	CHECK_EQUAL_VAR(IsConstant(empty, val, ignoreNaN = 1), NaN)

	CHECK_EQUAL_VAR(IsConstant({1, val, 1}, 0), 0)
	CHECK_EQUAL_VAR(IsConstant({val, val}, val), SelectNumber(IsNaN(val), 1, NaN))
	CHECK_EQUAL_VAR(IsConstant({val, val}, 0), SelectNumber(IsNaN(val), 0, NaN))
	CHECK_EQUAL_VAR(IsConstant({val, -val}, 0), SelectNumber(IsNaN(val), 0, NaN))
End

Function IC_CheckNaNInInputWave()

	// default is to ignore NaNs
	CHECK_EQUAL_VAR(IsConstant({NaN, 0}, 0), 1)
	CHECK_EQUAL_VAR(IsConstant({NaN, 0}, 0, ignoreNaN = 1), 1)

	CHECK_EQUAL_VAR(IsConstant({NaN, 0}, 0, ignoreNaN = 0), 0)
	CHECK_EQUAL_VAR(IsConstant({NaN, -Inf}, NaN, ignoreNaN = 0), 0)
	CHECK_EQUAL_VAR(IsConstant({NaN, Inf}, NaN, ignoreNaN = 0), 0)

	// it can only be true if all are NaN
	CHECK_EQUAL_VAR(IsConstant({NaN, NaN}, NaN, ignoreNaN = 0), 1)

	// and if all are NaN and we ignore NaN we actually have an empty wave and get NaN as result
	CHECK_EQUAL_VAR(IsConstant({NaN, NaN}, NaN, ignoreNaN = 1), NaN)
End

/// @}

/// IsValidRegexp
/// @{

Function IVR_Works()

	string null

	CHECK(IsValidRegexp(".*"))
	CHECK(IsValidRegexp("(.*)"))

	CHECK(!IsValidRegexp("*"))
	CHECK(!IsValidRegexp(""))
End

/// @}

/// AreIntervalsIntersecting
/// @{

static Function TestAreIntervalsIntersecting()

	// wrong wave type
	try
		Make/FREE/T wvText
		AreIntervalsIntersecting(wvText)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// 1D wave
	try
		Make/FREE wv
		AreIntervalsIntersecting(wv)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// trivial case #1: empty
	Make/FREE/N=(0, 2) empty
	CHECK_EQUAL_VAR(0, AreIntervalsIntersecting(empty))

	// trivial case #2: only one interval
	Make/FREE single = {{1}, {2}}
	CHECK_EQUAL_VAR(0, AreIntervalsIntersecting(single))

	// contains NaN values (start)
	Make/FREE infValues = {{1, Inf}, {2, 4}}

	try
		AreIntervalsIntersecting(infValues)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// contains NaN values (end)
	Make/FREE infValues = {{1, 3}, {2, NaN}}

	try
		AreIntervalsIntersecting(infValues)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// invalid ordering
	Make/FREE invalidOrder = {{2, 3}, {1, 4}}

	try
		AreIntervalsIntersecting(invalidOrder)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// works
	Make/FREE data = {{1, 3}, {2, 4}}
	CHECK(!AreIntervalsIntersecting(data))

	// intervals which have start == end are okay
	Make/FREE data = {{1, 2}, {2, 3}}
	CHECK(!AreIntervalsIntersecting(data))

	Make/FREE data = {{2.5, 1, 2.7}, {2.6, 2.4, 4}}
	CHECK(!AreIntervalsIntersecting(data))

	Make/FREE data = {{2, 1}, {3, 4}}
	CHECK(AreIntervalsIntersecting(data))

	// works also with infinite
	Make/FREE data = {{-Inf, 3}, {2, Inf}}
	CHECK(!AreIntervalsIntersecting(data))
End

/// @}

/// HasWildcardSyntax
/// @{

static Function HWS_Works()

	CHECK_EQUAL_VAR(HasWildcardSyntax(""), 0)
	CHECK_EQUAL_VAR(HasWildcardSyntax("a"), 0)
	CHECK_EQUAL_VAR(HasWildcardSyntax("1"), 0)
	CHECK_EQUAL_VAR(HasWildcardSyntax("!"), 1)
	CHECK_EQUAL_VAR(HasWildcardSyntax("!a"), 1)
	CHECK_EQUAL_VAR(HasWildcardSyntax("a*b"), 1)
End

/// @}

/// MatchAgainstWildCardPatterns
/// @{

static Function CheckMatchAgainstWildCardPatterns()

	string str

	Make/FREE/T/N=0 wv
	CHECK(!MatchAgainstWildCardPatterns(wv, ""))
	Make/FREE/T wv = {"*"}
	CHECK(MatchAgainstWildCardPatterns(wv, ""))
	CHECK(MatchAgainstWildCardPatterns(wv, "abc"))
	Make/FREE/T wv = {"abc"}
	CHECK(!MatchAgainstWildCardPatterns(wv, "def"))
	CHECK(MatchAgainstWildCardPatterns(wv, "abc"))
	Make/FREE/T wv = {"*abc", "def*"}
	CHECK(MatchAgainstWildCardPatterns(wv, "defabc"))
	CHECK(MatchAgainstWildCardPatterns(wv, "abc"))
	CHECK(MatchAgainstWildCardPatterns(wv, "def"))
	CHECK(!MatchAgainstWildCardPatterns(wv, "abcdef"))
	CHECK(!MatchAgainstWildCardPatterns(wv, "123"))
	Make/FREE/T wv = {{"abc", "def"}, {"hij", "klm"}}
	CHECK(MatchAgainstWildCardPatterns(wv, "klm"))
	CHECK(!MatchAgainstWildCardPatterns(wv, "*"))

	Make/FREE wn
	try
		MatchAgainstWildCardPatterns(wn, "")
		FAIL()
	catch
		PASS()
	endtry

	WAVE wn = $""
	try
		MatchAgainstWildCardPatterns(wn, "")
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE/T wv = {"*"}
	try
		MatchAgainstWildCardPatterns(wv, str)
		FAIL()
	catch
		ClearRTError()
		PASS()
	endtry
End

/// @}

static Function TestIsValidHeadstageWorking()

	CHECK_EQUAL_VAR(IsValidHeadstage(0), 1)
	CHECK_EQUAL_VAR(IsValidHeadstage(1), 1)
	CHECK_EQUAL_VAR(IsValidHeadstage(NUM_HEADSTAGES - 1), 1)
	CHECK_EQUAL_VAR(IsValidHeadstage(NaN), 0)
	CHECK_EQUAL_VAR(IsValidHeadstage(1.5), 0)
End
