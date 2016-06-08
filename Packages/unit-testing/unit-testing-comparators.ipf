#pragma rtGlobals=3
#pragma version=1.03

// Author: Thomas Braun (c) 2015
// Email: thomas dot braun at byte-physics dott de

// documentation guidelines:
// -document the _WRAPPER function using "@class *_DOCU" without the flags parameter
// -use "copydoc *_DOCU" for the CHECK_* function and don't document the other functions

/// @class CDF_EMPTY_DOCU
/// Tests if the current data folder is empty
///
/// Counted are objects with type waves, strings, variables and folders
static Function CDF_EMPTY_WRAPPER(flags)
	variable flags

	incrAssert()

	if(shouldDoAbort())
		return NaN
	endif

	string folder = ":"
	variable result = (CountObjects(folder, 1) + CountObjects(folder, 2) + CountObjects(folder, 3) + CountObjects(folder, 4)  == 0)

	if(!result)
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
	endif

	DebugOutput("Assumption that the current data folder is empty is", result)
End

/// @class TRUE_DOCU
/// Tests if var is true (1).
/// @param var    variable to test
static Function TRUE_WRAPPER(var, flags)
	variable var
	variable flags

	incrAssert()

	if(shouldDoAbort())
		return NaN
	endif

	variable result = (var == 1)
	DebugOutput(num2istr(var), result)

	if(!result)
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
	endif
End

/// @class NULL_STR_DOCU
/// Tests if str is null.
///
/// An empty string is never null.
/// @param str    string to test
static Function NULL_STR_WRAPPER(str, flags)
	string &str
	variable flags

	incrAssert()

	if(shouldDoAbort())
		return NaN
	endif

	if(!NULL_STR(str))
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
	endif
End

/// @class EMPTY_STR_DOCU
/// Tests if str is empty.
///
/// A null string is never empty.
/// @param str  string to test
static Function EMPTY_STR_WRAPPER(str, flags)
	string &str
	variable flags

	incrAssert()

	if(shouldDoAbort())
		return NaN
	endif

	variable result = (strlen(str) == 0)
	DebugOutput("Assumption that the string is empty is", result)

	if(!result)
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
	endif
End

/// @class NEQ_VAR_DOCU
/// Tests two variables for inequality
/// @param var1    first variable
/// @param var2    second variable
static Function NEQ_VAR_WRAPPER(var1, var2, flags)
	variable var1, var2
	variable flags

	incrAssert()

	if(shouldDoAbort())
		return NaN
	endif

	if(EQUAL_VAR(var1, var2))
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
	endif
End

/// @class NEQ_STR_DOCU
/// Compares two strings for unequality
/// @param str1            first string
/// @param str2            second string
/// @param case_sensitive  (optional) should the comparison be done case sensitive (1) or case insensitive (0, the default)
static Function NEQ_STR_WRAPPER(str1, str2, flags, [case_sensitive])
	string &str1, &str2
	variable case_sensitive
	variable flags

	incrAssert()

	if(shouldDoAbort())
		return NaN
	endif

	if(ParamIsDefault(case_sensitive))
		case_sensitive = 0
	endif

	if(EQUAL_STR(str1, str2, case_sensitive))
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
	endif
End

/// @class CLOSE_VAR_DOCU
/// Compares two variables and determines if they are close.
///
/// Based on the implementation of "Floating-point comparison algorithms" in the C++ Boost unit testing framework.
///
/// Literature:<br>
/// The art of computer programming (Vol II). Donald. E. Knuth. 0-201-89684-2. Addison-Wesley Professional;
/// 3 edition, page 234 equation (34) and (35).
///
/// @param var1            first variable
/// @param var2            second variable
/// @param tol             (optional) tolerance, defaults to 1e-8
/// @param strong_or_weak  (optional) type of condition, can be 0 for weak or 1 for strong (default)
static Function CLOSE_VAR_WRAPPER(var1, var2, flags, [tol, strong_or_weak])
	variable var1, var2
	variable flags
	variable tol
	variable strong_or_weak

	incrAssert()

	if(shouldDoAbort())
		return NaN
	endif

	if(ParamIsDefault(strong_or_weak))
		strong_or_weak  = CLOSE_COMPARE_STRONG_OR_WEAK
	endif

	if(ParamIsDefault(tol))
		tol = DEFAULT_TOLERANCE
	endif

	if(!CLOSE_VAR(var1, var2, tol, strong_or_weak))
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
	endif
End

/// @class CLOSE_CMPLX_DOCU
/// @copydoc CLOSE_VAR_DOCU
///
/// Variant for complex numbers.
static Function CLOSE_CMPLX_WRAPPER(var1, var2, flags, [tol, strong_or_weak])
	variable/C var1, var2
	variable flags
	variable tol
	variable strong_or_weak

	incrAssert()

	if(shouldDoAbort())
		return NaN
	endif

	if(ParamIsDefault(strong_or_weak))
		strong_or_weak  = CLOSE_COMPARE_STRONG_OR_WEAK
	endif

	if(ParamIsDefault(tol))
		tol = DEFAULT_TOLERANCE
	endif

	if(!CLOSE_VAR(real(var1), real(var2), tol, strong_or_weak) || !CLOSE_VAR(imag(var1), imag(var2), tol, strong_or_weak))
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
	endif
End

/// @class SMALL_VAR_DOCU
/// Tests if a variable is small using the inequality @f$  | var | < | tol |  @f$
/// @param var        variable
/// @param tol        (optional) tolerance, defaults to 1e-8
static Function SMALL_VAR_WRAPPER(var, flags, [tol])
	variable var
	variable flags
	variable tol

	incrAssert()

	if(shouldDoAbort())
		return NaN
	endif

	if(ParamIsDefault(tol))
		tol = DEFAULT_TOLERANCE
	endif

	if(!SMALL_VAR(var, tol))
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
	endif
End

/// @class SMALL_CMPLX_DOCU
/// @copydoc SMALL_VAR_DOCU
///
/// Variant for complex numbers
static Function SMALL_CMPLX_WRAPPER(var, flags, [tol])
	variable/C var
	variable flags
	variable tol

	incrAssert()

	if(shouldDoAbort())
		return NaN
	endif

	if(ParamIsDefault(tol))
		tol = DEFAULT_TOLERANCE
	endif

	if(!SMALL_VAR(cabs(var), tol))
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
	endif
End

/// @class EQUAL_STR_DOCU
/// Compares two strings for equality.
/// @param str1           first string
/// @param str2           second string
/// @param case_sensitive (optional) should the comparison be done case sensitive (1) or case insensitive (0, the default)
static Function EQUAL_STR_WRAPPER(str1, str2, flags, [case_sensitive])
	string &str1, &str2
	variable case_sensitive
	variable flags

	incrAssert()

	if(shouldDoAbort())
		return NaN
	endif

	if(ParamIsDefault(case_sensitive))
		case_sensitive = 0
	endif

	if(!EQUAL_STR(str1, str2, case_sensitive))
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
	endif
End

/// @class WAVE_DOCU
/// Tests a wave for existence and its type
/// @param wv         wave reference
/// @param majorType  major wave type
/// @param minorType  (optional) minor wave type
/// @see testWaveFlags
static Function TEST_WAVE_WRAPPER(wv, flags, majorType, [minorType])
	Wave/Z wv
	variable majorType, minorType
	variable flags

	incrAssert()

	if(shouldDoAbort())
		return NaN
	endif

	variable result = WaveExists(wv)
	DebugOutput("Assumption that the wave exists", result)

	if(!result)
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
	endif

	result = (WaveType(wv, 1) != majorType)
	string str
	sprintf str, "Assumption that the wave's main type is %d", majorType
	DebugOutput(str, result)

	if(!result)
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
	endif

	if(!ParamIsDefault(minorType))
		result = WaveType(wv, 0) & minorType

		sprintf str, "Assumption that the wave's sub type is %d", minorType
		DebugOutput(str, result)

		if(!result)
			if(flags & OUTPUT_MESSAGE)
				printFailInfo()
			endif
			if(flags & INCREASE_ERROR)
				incrError()
			endif
			if(flags & ABORT_FUNCTION)
				abortNow()
			endif
		endif
	endif
End

/// @class EQUAL_VAR_DOCU
/// Tests two variables for equality.
///
/// For variables holding floating point values it is often more desirable use CHECK_CLOSE_VAR instead. To fullfill semantic correctness this assertion treats two variables with both holding NaN as equal.
/// @param var1   first variable
/// @param var2   second variable
static Function EQUAL_VAR_WRAPPER(var1, var2, flags)
	variable var1, var2
	variable flags

	incrAssert()

	if(shouldDoAbort())
		return NaN
	endif

	if(!EQUAL_VAR(var1, var2))
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
	endif
End

/// @class EQUAL_WAVE_DOCU
/// Tests two waves for equality
/// @param wv1    first wave
/// @param wv2    second wave
/// @param mode   (optional) features of the waves to compare, defaults to all modes, defined at @ref equalWaveFlags
/// @param tol    (optional) tolerance for comparison, by default 0.0 which does byte-by-byte comparison (relevant only for mode=WAVE_DATA)
static Function EQUAL_WAVE_WRAPPER(wv1, wv2, flags, [mode, tol])
	Wave/Z wv1, wv2
	variable flags
	variable mode, tol

	incrAssert()

	if(shouldDoAbort())
		return NaN
	endif

	variable result = WaveExists(wv1)
	DebugOutput("Assumption that the first wave (wv1) exists", result)

	if(!result)
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
		return NaN
	endif

	result = WaveExists(wv2)
	DebugOutput("Assumption that the second wave (wv2) exists", result)

	if(!result)
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
		return NaN
	endif

	result = !WaveRefsEqual(wv1, wv2)
	DebugOutput("Assumption that both waves are distinct", result)

	if(!result)
		if(flags & OUTPUT_MESSAGE)
			printFailInfo()
		endif
		if(flags & INCREASE_ERROR)
			incrError()
		endif
		if(flags & ABORT_FUNCTION)
			abortNow()
		endif
		return NaN
	endif

	if(ParamIsDefault(mode))
		Make/U/I/FREE modes = { WAVE_DATA, WAVE_DATA_TYPE, WAVE_SCALING, DATA_UNITS, DIMENSION_UNITS, DIMENSION_LABELS, WAVE_NOTE, WAVE_LOCK_STATE, DATA_FULL_SCALE, DIMENSION_SIZES}
	else
		Make/U/I/FREE modes = { mode }
	endif

	if(ParamIsDefault(tol))
		tol = 0.0
	endif

	variable i
	for(i = 0; i < DimSize(modes, 0); i += 1)
		mode = modes[i]
		result = EqualWaves(wv1, wv2, mode, tol)
		string str
		sprintf str, "Assuming equality using mode %03d for waves %s and %s", mode, NameOfWave(wv1), NameOfWave(wv2)
		DebugOutput(str, result)

		if(!result)
			if(flags & OUTPUT_MESSAGE)
				printFailInfo()
			endif
			if(flags & INCREASE_ERROR)
				incrError()
			endif
			if(flags & ABORT_FUNCTION)
				abortNow()
			endif
		endif
	endfor
End

static Function NULL_STR(str)
	string &str

	variable result = (numtype(strlen(str)) == 2)

	DebugOutput("Assumption of str being null is ", result)
	return result
End

static Function EQUAL_VAR(var1, var2)
	variable var1, var2

	variable result
	variable type1 = numType(var1)
	variable type2 = numType(var2)

	if(type1 == type2 && type1 == 2) // both variables being NaN is also true
		result = 1
	else
		result = (var1 == var2)
	endif

	string str
	sprintf str, "%g == %g", var1, var2
	DebugOutput(str, result)
	return result
End

static Function SMALL_VAR(var, tol)
	variable var
	variable tol

	variable result = (abs(var) < abs(tol))

	string str
	sprintf str, "%g ~ 0 with tol %g", var, tol
	DebugOutput(str, result)
	return result
End

static Function CLOSE_VAR(var1, var2, tol, strong_or_weak)
	variable var1, var2
	variable tol
	variable strong_or_weak

	variable diff = abs(var1 - var2)
	variable d1   = diff / abs(var1)
	variable d2   = diff / abs(var2)

	variable result
	if(strong_or_weak == 1)
		result = (d1 <= tol && d2 <= tol)
	elseif(strong_or_weak == 0)
		result = (d1 <= tol || d2 <= tol)
	else
		printf "Unknown mode %d\r", strong_or_weak
	endif

	string str
	sprintf str, "%g ~ %g with %s check and tol %g", var1, var2, SelectString(strong_or_weak, "weak", "strong"), tol
	DebugOutput(str, result)
	return result
End

/// @return 1 if both strings are equal and zero otherwise
static Function EQUAL_STR(str1, str2, case_sensitive)
	string &str1, &str2
	variable case_sensitive

	variable result
	if(NULL_STR(str1) && NULL_STR(str2))
		result = 1
	elseif(NULL_STR(str1) || NULL_STR(str2))
		result = 0
	else
		result = (cmpstr(str1, str2, case_sensitive) == 0)
	endif

	string str
	sprintf str, "\"%s\" == \"%s\" %s case", SelectString(NULL_STR(str1), str1, "(null)"), SelectString(NULL_STR(str2), str2, "(null)"), SelectString(case_sensitive, "not respecting", "respecting")
	DebugOutput(str, result)

	return result
End

/// @addtogroup Assertions
/// @{

/// Increase the assertion counter only
Function PASS()
	TRUE_WRAPPER(1, REQUIRE_MODE)
End

/// Force the test case to fail
Function FAIL()
	TRUE_WRAPPER(0, REQUIRE_MODE)
End

Function WARN(var)
	variable var

	TRUE_WRAPPER(var, WARN_MODE)
End

/// @copydoc TRUE_DOCU
Function CHECK(var)
	variable var

	TRUE_WRAPPER(var, CHECK_MODE)
End

Function REQUIRE(var)
	variable var

	TRUE_WRAPPER(var, REQUIRE_MODE)
End

Function WARN_EQUAL_VAR(var1, var2)
	variable var1, var2

	EQUAL_VAR_WRAPPER(var1, var2, WARN_MODE)
End

/// @copydoc EQUAL_VAR_DOCU
Function CHECK_EQUAL_VAR(var1, var2)
	variable var1, var2

	EQUAL_VAR_WRAPPER(var1, var2, CHECK_MODE)
End

Function REQUIRE_EQUAL_VAR(var1, var2)
	variable var1, var2

	EQUAL_VAR_WRAPPER(var1, var2, REQUIRE_MODE)
End

Function WARN_NEQ_VAR(var1, var2)
	variable var1, var2

	NEQ_VAR_WRAPPER(var1, var2, WARN_MODE)
End

/// @copydoc NEQ_VAR_DOCU
Function CHECK_NEQ_VAR(var1, var2)
	variable var1, var2

	NEQ_VAR_WRAPPER(var1, var2, CHECK_MODE)
End

Function REQUIRE_NEQ_VAR(var1, var2)
	variable var1, var2

	NEQ_VAR_WRAPPER(var1, var2, REQUIRE_MODE)
End

Function WARN_CLOSE_VAR(var1, var2, [tol, strong_or_weak])
	variable var1, var2
	variable tol
	variable strong_or_weak

	if(ParamIsDefault(tol) && ParamIsDefault(strong_or_weak))
		CLOSE_VAR_WRAPPER(var1, var2, WARN_MODE)
	elseif(ParamIsDefault(tol))
		CLOSE_VAR_WRAPPER(var1, var2, WARN_MODE, strong_or_weak=strong_or_weak)
	elseif(ParamIsDefault(strong_or_weak))
		CLOSE_VAR_WRAPPER(var1, var2, WARN_MODE, tol=tol)
	else
		CLOSE_VAR_WRAPPER(var1, var2, WARN_MODE, tol=tol, strong_or_weak=strong_or_weak)
	endif
End

/// @copydoc CLOSE_VAR_DOCU
Function CHECK_CLOSE_VAR(var1, var2, [tol, strong_or_weak])
	variable var1, var2
	variable tol
	variable strong_or_weak

	if(ParamIsDefault(tol) && ParamIsDefault(strong_or_weak))
		CLOSE_VAR_WRAPPER(var1, var2, CHECK_MODE)
	elseif(ParamIsDefault(tol))
		CLOSE_VAR_WRAPPER(var1, var2, CHECK_MODE, strong_or_weak=strong_or_weak)
	elseif(ParamIsDefault(strong_or_weak))
		CLOSE_VAR_WRAPPER(var1, var2, CHECK_MODE, tol=tol)
	else
		CLOSE_VAR_WRAPPER(var1, var2, CHECK_MODE, tol=tol, strong_or_weak=strong_or_weak)
	endif
End

Function REQUIRE_CLOSE_VAR(var1, var2, [tol, strong_or_weak])
	variable var1, var2
	variable tol
	variable strong_or_weak

	if(ParamIsDefault(tol) && ParamIsDefault(strong_or_weak))
		CLOSE_VAR_WRAPPER(var1, var2, REQUIRE_MODE)
	elseif(ParamIsDefault(tol))
		CLOSE_VAR_WRAPPER(var1, var2, REQUIRE_MODE, strong_or_weak=strong_or_weak)
	elseif(ParamIsDefault(strong_or_weak))
		CLOSE_VAR_WRAPPER(var1, var2, REQUIRE_MODE, tol=tol)
	else
		CLOSE_VAR_WRAPPER(var1, var2, REQUIRE_MODE, tol=tol, strong_or_weak=strong_or_weak)
	endif
End

Function WARN_CLOSE_CMPLX(var1, var2 [tol, strong_or_weak])
	variable/C var1, var2
	variable tol, strong_or_weak

	if(ParamIsDefault(tol) && ParamIsDefault(strong_or_weak))
		CLOSE_CMPLX_WRAPPER(var1, var2, WARN_MODE)
	elseif(ParamIsDefault(tol))
		CLOSE_CMPLX_WRAPPER(var1, var2, WARN_MODE, strong_or_weak=strong_or_weak)
	elseif(ParamIsDefault(strong_or_weak))
		CLOSE_CMPLX_WRAPPER(var1, var2, WARN_MODE, tol=tol)
	else
		CLOSE_CMPLX_WRAPPER(var1, var2, WARN_MODE, tol=tol, strong_or_weak=strong_or_weak)
	endif
End

/// @copydoc CLOSE_CMPLX_DOCU
Function CHECK_CLOSE_CMPLX(var1, var2 [tol, strong_or_weak])
	variable/C var1, var2
	variable tol, strong_or_weak

	if(ParamIsDefault(tol) && ParamIsDefault(strong_or_weak))
		CLOSE_CMPLX_WRAPPER(var1, var2, CHECK_MODE)
	elseif(ParamIsDefault(tol))
		CLOSE_CMPLX_WRAPPER(var1, var2, CHECK_MODE, strong_or_weak=strong_or_weak)
	elseif(ParamIsDefault(strong_or_weak))
		CLOSE_CMPLX_WRAPPER(var1, var2, CHECK_MODE, tol=tol)
	else
		CLOSE_CMPLX_WRAPPER(var1, var2, CHECK_MODE, tol=tol, strong_or_weak=strong_or_weak)
	endif
End

Function REQUIRE_CLOSE_CMPLX(var1, var2 [tol, strong_or_weak])
	variable/C var1, var2
	variable tol, strong_or_weak

	if(ParamIsDefault(tol) && ParamIsDefault(strong_or_weak))
		CLOSE_CMPLX_WRAPPER(var1, var2, REQUIRE_MODE)
	elseif(ParamIsDefault(tol))
		CLOSE_CMPLX_WRAPPER(var1, var2, REQUIRE_MODE, strong_or_weak=strong_or_weak)
	elseif(ParamIsDefault(strong_or_weak))
		CLOSE_CMPLX_WRAPPER(var1, var2, REQUIRE_MODE, tol=tol)
	else
		CLOSE_CMPLX_WRAPPER(var1, var2, REQUIRE_MODE, tol=tol, strong_or_weak=strong_or_weak)
	endif
End

Function WARN_SMALL_VAR(var, [tol])
	variable var
	variable tol

	if(ParamIsDefault(tol))
		SMALL_VAR_WRAPPER(var, WARN_MODE)
	else
		SMALL_VAR_WRAPPER(var, WARN_MODE, tol=tol)
	endif
End

/// @copydoc SMALL_VAR_DOCU
Function CHECK_SMALL_VAR(var, [tol])
	variable var
	variable tol

	if(ParamIsDefault(tol))
		SMALL_VAR_WRAPPER(var, CHECK_MODE)
	else
		SMALL_VAR_WRAPPER(var, CHECK_MODE, tol=tol)
	endif
End

Function REQUIRE_SMALL_VAR(var, [tol])
	variable var
	variable tol

	if(ParamIsDefault(tol))
		SMALL_VAR_WRAPPER(var, REQUIRE_MODE)
	else
		SMALL_VAR_WRAPPER(var, REQUIRE_MODE, tol=tol)
	endif
End

Function WARN_SMALL_CMPLX(var, [tol])
	variable/C var
	variable tol

	if(ParamIsDefault(tol))
		SMALL_CMPLX_WRAPPER(var, WARN_MODE)
	else
		SMALL_CMPLX_WRAPPER(var, WARN_MODE, tol=tol)
	endif
End

/// @copydoc SMALL_CMPLX_DOCU
Function CHECK_SMALL_CMPLX(var, [tol])
	variable/C var
	variable tol

	if(ParamIsDefault(tol))
		SMALL_CMPLX_WRAPPER(var, CHECK_MODE)
	else
		SMALL_CMPLX_WRAPPER(var, CHECK_MODE, tol=tol)
	endif
End

Function REQUIRE_SMALL_CMPLX(var, [tol])
	variable/C var
	variable tol

	if(ParamIsDefault(tol))
		SMALL_CMPLX_WRAPPER(var, REQUIRE_MODE)
	else
		SMALL_CMPLX_WRAPPER(var, REQUIRE_MODE, tol=tol)
	endif
End

Function WARN_EMPTY_STR(str)
	string &str

	EMPTY_STR_WRAPPER(str, WARN_MODE)
End

/// @copydoc EMPTY_STR_DOCU
Function CHECK_EMPTY_STR(str)
	string &str

	EMPTY_STR_WRAPPER(str, CHECK_MODE)
End

Function REQUIRE_EMPTY_STR(str)
	string &str

	EMPTY_STR_WRAPPER(str, REQUIRE_MODE)
End

Function WARN_NULL_STR(str)
	string &str

	NULL_STR_WRAPPER(str, WARN_MODE)
End

/// @copydoc NULL_STR_DOCU
Function CHECK_NULL_STR(str)
	string &str

	NULL_STR_WRAPPER(str, CHECK_MODE)
End

Function REQUIRE_NULL_STR(str)
	string &str

	NULL_STR_WRAPPER(str, REQUIRE_MODE)
End

Function WARN_EQUAL_STR(str1, str2, [case_sensitive])
	string &str1, &str2
	variable case_sensitive

	if(ParamIsDefault(case_sensitive))
		EQUAL_STR_WRAPPER(str1, str2, WARN_MODE)
	else
		EQUAL_STR_WRAPPER(str1, str2, WARN_MODE, case_sensitive=case_sensitive)
	endif
End

/// @copydoc EQUAL_STR_DOCU
Function CHECK_EQUAL_STR(str1, str2, [case_sensitive])
	string &str1, &str2
	variable case_sensitive

	if(ParamIsDefault(case_sensitive))
		EQUAL_STR_WRAPPER(str1, str2, CHECK_MODE)
	else
		EQUAL_STR_WRAPPER(str1, str2, CHECK_MODE, case_sensitive=case_sensitive)
	endif
End

Function REQUIRE_EQUAL_STR(str1, str2, [case_sensitive])
	string &str1, &str2
	variable case_sensitive

	if(ParamIsDefault(case_sensitive))
		EQUAL_STR_WRAPPER(str1, str2, REQUIRE_MODE)
	else
		EQUAL_STR_WRAPPER(str1, str2, REQUIRE_MODE, case_sensitive=case_sensitive)
	endif
End

Function WARN_NEQ_STR(str1, str2, [case_sensitive])
	string &str1, &str2
	variable case_sensitive

	if(ParamIsDefault(case_sensitive))
		NEQ_STR_WRAPPER(str1, str2, WARN_MODE)
	else
		NEQ_STR_WRAPPER(str1, str2, WARN_MODE, case_sensitive=case_sensitive)
	endif
End

/// @copydoc NEQ_STR_DOCU
Function CHECK_NEQ_STR(str1, str2, [case_sensitive])
	string &str1, &str2
	variable case_sensitive

	if(ParamIsDefault(case_sensitive))
		NEQ_STR_WRAPPER(str1, str2, CHECK_MODE)
	else
		NEQ_STR_WRAPPER(str1, str2, CHECK_MODE, case_sensitive=case_sensitive)
	endif
End

Function REQUIRE_NEQ_STR(str1, str2, [case_sensitive])
	string &str1, &str2
	variable case_sensitive

	if(ParamIsDefault(case_sensitive))
		NEQ_STR_WRAPPER(str1, str2, REQUIRE_MODE)
	else
		NEQ_STR_WRAPPER(str1, str2, REQUIRE_MODE, case_sensitive=case_sensitive)
	endif
End

Function WARN_WAVE(wv, majorType, [minorType])
	Wave/Z wv
	variable majorType, minorType

	if(ParamIsDefault(minorType))
		TEST_WAVE_WRAPPER(wv, majorType, WARN_MODE)
	else
		TEST_WAVE_WRAPPER(wv, majorType, WARN_MODE, minorType=minorType)
	endif
End

/// @copydoc WAVE_DOCU
Function CHECK_WAVE(wv, majorType, [minorType])
	Wave/Z wv
	variable majorType, minorType

	if(ParamIsDefault(minorType))
		TEST_WAVE_WRAPPER(wv, majorType, CHECK_MODE)
	else
		TEST_WAVE_WRAPPER(wv, majorType, CHECK_MODE, minorType=minorType)
	endif
End

Function REQUIRE_WAVE(wv, majorType, [minorType])
	Wave/Z wv
	variable majorType, minorType

	if(ParamIsDefault(minorType))
		TEST_WAVE_WRAPPER(wv, majorType, REQUIRE_MODE)
	else
		TEST_WAVE_WRAPPER(wv, majorType, REQUIRE_MODE, minorType=minorType)
	endif
End

Function WARN_EQUAL_WAVES(wv1, wv2, [mode, tol])
	Wave/Z wv1, wv2
	variable mode, tol

	if(ParamIsDefault(mode) && ParamIsDefault(tol))
		EQUAL_WAVE_WRAPPER(wv1, wv2, WARN_MODE)
	elseif(ParamIsDefault(tol))
		EQUAL_WAVE_WRAPPER(wv1, wv2, WARN_MODE, mode=mode)
	elseif(ParamIsDefault(mode))
		EQUAL_WAVE_WRAPPER(wv1, wv2, WARN_MODE, tol=tol)
	else
		EQUAL_WAVE_WRAPPER(wv1, wv2, WARN_MODE, tol=tol, mode=mode)
	endif
End

/// @copydoc EQUAL_WAVE_DOCU
Function CHECK_EQUAL_WAVES(wv1, wv2, [mode, tol])
	Wave/Z wv1, wv2
	variable mode, tol

	if(ParamIsDefault(mode) && ParamIsDefault(tol))
		EQUAL_WAVE_WRAPPER(wv1, wv2, CHECK_MODE)
	elseif(ParamIsDefault(tol))
		EQUAL_WAVE_WRAPPER(wv1, wv2, CHECK_MODE, mode=mode)
	elseif(ParamIsDefault(mode))
		EQUAL_WAVE_WRAPPER(wv1, wv2, CHECK_MODE, tol=tol)
	else
		EQUAL_WAVE_WRAPPER(wv1, wv2, CHECK_MODE, tol=tol, mode=mode)
	endif
End

Function REQUIRE_EQUAL_WAVES(wv1, wv2, [mode, tol])
	Wave/Z wv1, wv2
	variable mode, tol

	if(ParamIsDefault(mode) && ParamIsDefault(tol))
		EQUAL_WAVE_WRAPPER(wv1, wv2, REQUIRE_MODE)
	elseif(ParamIsDefault(tol))
		EQUAL_WAVE_WRAPPER(wv1, wv2, REQUIRE_MODE, mode=mode)
	elseif(ParamIsDefault(mode))
		EQUAL_WAVE_WRAPPER(wv1, wv2, REQUIRE_MODE, tol=tol)
	else
		EQUAL_WAVE_WRAPPER(wv1, wv2, REQUIRE_MODE, tol=tol, mode=mode)
	endif
End

Function WARN_EMPTY_FOLDER()
	CDF_EMPTY_WRAPPER(WARN_MODE)
End

/// @copydoc CDF_EMPTY_DOCU
Function CHECK_EMPTY_FOLDER()
	CDF_EMPTY_WRAPPER(CHECK_MODE)
End

Function REQUIRE_EMPTY_FOLDER()
	CDF_EMPTY_WRAPPER(REQUIRE_MODE)
End

///@}
