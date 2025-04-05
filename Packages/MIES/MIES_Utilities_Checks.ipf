#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_UTILS_CHECKS
#endif // AUTOMATED_TESTING

/// @file MIES_Utilities_Checks.ipf
/// @brief Utility functions that check for certain properties and return either 1 (TRUE) or 0 (FALSE)

/// @brief Returns 1 if var is a finite/normal number, 0 otherwise
///
/// @hidecallgraph
/// @hidecallergraph
/// UTF_NOINSTRUMENTATION
threadsafe Function IsFinite(variable var)

	return numType(var) == 0
End

/// @brief Returns 1 if var is a NaN, 0 otherwise
///
/// @hidecallgraph
/// @hidecallergraph
/// UTF_NOINSTRUMENTATION
threadsafe Function IsNaN(variable var)

	return numType(var) == 2
End

/// @brief Returns 1 if var is +/- inf, 0 otherwise
///
/// @hidecallgraph
/// @hidecallergraph
/// UTF_NOINSTRUMENTATION
threadsafe Function IsInf(variable var)

	return numType(var) == 1
End

/// @brief Returns 1 if str is null, 0 otherwise
/// @param str must not be a SVAR
///
/// @hidecallgraph
/// @hidecallergraph
/// UTF_NOINSTRUMENTATION
threadsafe Function IsNull(string &str)

	variable len = strlen(str)
	return numtype(len) == 2
End

/// @brief Returns one if str is empty, zero otherwise.
/// @param str any non-null string variable or text wave element
///
/// @hidecallgraph
/// @hidecallergraph
/// UTF_NOINSTRUMENTATION
threadsafe Function IsEmpty(string str)

	return !(strlen(str) > 0)
End

/// @brief Checks if the given name exists as window
///
/// @hidecallgraph
/// @hidecallergraph
/// UTF_NOINSTRUMENTATION
Function WindowExists(string win)

	return WinType(win) != 0
End

/// @brief Check that the given value can be stored in the wave
///
/// Does currently ignore floating point precision and ranges for integer waves
threadsafe Function ValueCanBeWritten(WAVE/Z wv, variable value)

	variable type

	if(!WaveExists(wv))
		return 0
	endif

	if(!IsNumericWave(wv))
		return 0
	endif

	type = WaveType(wv)

	// non-finite values must have a float wave
	if(!IsFinite(value))
		return (type & IGOR_TYPE_32BIT_FLOAT) || (type & IGOR_TYPE_64BIT_FLOAT)
	endif

	return 1
End

/// @brief Returns one if var is an integer and zero otherwise
/// UTF_NOINSTRUMENTATION
threadsafe Function IsInteger(variable var)

	return IsFinite(var) && trunc(var) == var
End

/// UTF_NOINSTRUMENTATION
threadsafe Function IsEven(variable var)

	return IsInteger(var) && mod(var, 2) == 0
End

/// UTF_NOINSTRUMENTATION
threadsafe Function IsOdd(variable var)

	return IsInteger(var) && mod(var, 2) != 0
End

/// @brief Check wether the function reference points to
/// the prototype function or to an assigned function
///
/// Due to Igor Pro limitations you need to pass the function
/// info from `FuncRefInfo` and not the function reference itself.
///
/// @return 1 if pointing to prototype function, 0 otherwise
///
/// UTF_NOINSTRUMENTATION
threadsafe Function FuncRefIsAssigned(string funcInfo)

	variable result

	ASSERT_TS(!isEmpty(funcInfo), "Empty function info")
	result = NumberByKey("ISPROTO", funcInfo)
	ASSERT_TS(IsFinite(result), "funcInfo does not look like a FuncRefInfo string")

	return result == 0
End

/// @brief Compare two variables and determines if they are close.
///
/// Based on the implementation of "Floating-point comparison algorithms" in the C++ Boost unit testing framework.
///
/// Literature:<br>
/// The art of computer programming (Vol II). Donald. E. Knuth. 0-201-89684-2. Addison-Wesley Professional;
/// 3 edition, page 234 equation (34) and (35).
///
/// @param var1            first variable
/// @param var2            second variable
/// @param tol             [optional, defaults to 1e-8] tolerance
/// @param strong_or_weak  [optional, defaults to strong] type of condition, can be zero for weak or 1 for strong
///
/// UTF_NOINSTRUMENTATION
Function CheckIfClose(variable var1, variable var2, [variable tol, variable strong_or_weak])

	if(ParamIsDefault(tol))
		tol = 1e-8
	endif

	if(ParamIsDefault(strong_or_weak))
		strong_or_weak = 1
	endif

	variable diff = abs(var1 - var2)
	variable d1   = diff / abs(var1)
	variable d2   = diff / abs(var2)

	if(strong_or_weak)
		return d1 <= tol && d2 <= tol
	endif

	return d1 <= tol || d2 <= tol
End

/// @brief Test if a variable is small using the inequality @f$  | var | < | tol |  @f$
///
/// @param var  variable
/// @param tol  [optional, defaults to 1e-8] tolerance
Function CheckIfSmall(variable var, [variable tol])

	if(ParamIsDefault(tol))
		tol = 1e-8
	endif

	return abs(var) < abs(tol)
End

/// @brief Return 1 if the wave is a text wave, zero otherwise
/// UTF_NOINSTRUMENTATION
threadsafe Function IsTextWave(WAVE wv)

	return WaveType(wv, 1) == 2
End

/// @brief Return 1 if the wave is a numeric wave, zero otherwise
/// UTF_NOINSTRUMENTATION
threadsafe Function IsNumericWave(WAVE wv)

	return WaveType(wv, 1) == 1
End

/// @brief Return 1 if the wave is a wave reference wave, zero otherwise
/// UTF_NOINSTRUMENTATION
threadsafe Function IsWaveRefWave(WAVE wv)

	return WaveType(wv, 1) == IGOR_TYPE_WAVEREF_WAVE
End

/// @brief Return 1 if the wave is a floating point wave
/// UTF_NOINSTRUMENTATION
threadsafe Function IsFloatingPointWave(WAVE wv)

	variable type = WaveType(wv)

	return (type & IGOR_TYPE_32BIT_FLOAT) || (type & IGOR_TYPE_64BIT_FLOAT)
End

/// @brief Return 1 if the wave is a double (64bit) precision floating point wave
///
/// UTF_NOINSTRUMENTATION
threadsafe Function IsDoubleFloatingPointWave(WAVE wv)

	return WaveType(wv) & IGOR_TYPE_64BIT_FLOAT
End

/// @brief Return 1 if the wave is a single (32bit) precision floating point wave
///
/// UTF_NOINSTRUMENTATION
threadsafe Function IsSingleFloatingPointWave(WAVE wv)

	return WaveType(wv) & IGOR_TYPE_32BIT_FLOAT
End

/// @brief Return 1 if the wave is a global wave (not a null wave and not a free wave)
threadsafe Function IsGlobalWave(WAVE wv)

	return WaveType(wv, 2) == 1
End

/// @brief Return 1 if the wave is a complex wave
threadsafe Function IsComplexWave(WAVE wv)

	return WaveType(wv) & IGOR_TYPE_COMPLEX
End

/// @brief Return true if wv is a free wave, false otherwise
///
/// UTF_NOINSTRUMENTATION
threadsafe Function IsFreeWave(WAVE wv)

	return WaveType(wv, 2) == 2
End

/// @brief Return true if not all wave entries are NaN, false otherwise.
///
/// UTF_NOINSTRUMENTATION
threadsafe Function HasOneValidEntry(WAVE wv)

	string   str
	variable val

	ASSERT_TS(numpnts(wv) > 0, "Expected non-empty wave")

	if(IsFloatingPointWave(wv))
		return numType(WaveMin(wv)) != 2
	endif

	if(IsTextWave(wv))
		WAVE/T wvText = wv

		for(str : wvText)
			if(strlen(str) > 0)
				return 1
			endif
		endfor
	else
		ASSERT_TS(0, "Unsupported wave type")
	endif

	return 0
End

/// @brief Return true if wave has one finite entry (not Inf, -Inf or NaN)
threadsafe Function HasOneFiniteEntry(WAVE wv)

	if(IsFloatingPointWave(wv))
		if(!numpnts(wv))
			return 0
		endif
		WaveStats/Q/M=1 wv
		return !!V_npnts
	endif

	ASSERT_TS(0, "Unsupported wave type")
End

/// @brief Return true if wave has one infinite entry (Inf, -Inf or NaN)
threadsafe Function HasOneNonFiniteEntry(WAVE wv)

	if(IsFloatingPointWave(wv))
		if(!numpnts(wv))
			return 0
		endif

		WaveStats/Q/M=1 wv
		return V_numNaNs != 0 || V_numINFs != 0
	endif

	ASSERT_TS(0, "Unsupported wave type")
End

/// @brief Checks if a string ends with a specific suffix. The check is case-insensitive.
///
/// @param[in] str string to check for suffix
/// @param[in] suffix to check for
/// @returns 1 if str ends with suffix, 0 otherwise. If str and/or suffix are empty or null 0 is returned.
Function StringEndsWith(string str, string suffix)

	variable pos

	if(IsNull(str) || IsNull(suffix))
		return 0
	endif

	pos = strsearch(str, suffix, Inf, 1)
	if(pos == -1)
		return 0
	endif

	if(pos == (strlen(str) - strlen(suffix)))
		return 1
	endif

	return 0
End

/// @brief Check wether `val1` and `val2` are equal or both NaN
///
/// UTF_NOINSTRUMENTATION
threadsafe Function EqualValuesOrBothNaN(variable left, variable right)

	return (IsNaN(left) && IsNaN(right)) || (left == right)
End

/// @brief Checks wether `wv` is constant and has the value `val`
///
/// @param wv        wave to check
/// @param val       value to check
/// @param ignoreNaN [optional, defaults to true] ignore NaN in wv
///
/// UTF_NOINSTRUMENTATION
threadsafe Function IsConstant(WAVE wv, variable val, [variable ignoreNaN])

	variable minimum, maximum

	if(ParamIsDefault(ignoreNaN))
		ignoreNaN = 1
	else
		ignoreNaN = !!ignoreNaN
	endif

	if(DimSize(wv, ROWS) == 0)
		return NaN
	endif

	WaveStats/M=1/Q wv

	if(V_npnts == 0 && V_numInfs == 0)
		// complete input wave is NaN

		if(ignoreNaN)
			return NaN
		endif

		return IsNaN(val)
	endif

	if(V_numNans > 0)
		// we have some NaNs
		if(!ignoreNaN)
			// and don't ignore them, this is always false
			return 0
		endif
	endif

	[minimum, maximum] = WaveMinAndMax(wv)

	return minimum == val && maximum == val
End

/// @brief Return true if the passed regular expression is well-formed
threadsafe Function IsValidRegexp(string regexp)

	variable err, result

	// GrepString and friends treat an empty regular expression as *valid*
	// although this seems to be standard behaviour, we don't allow that shortcut
	if(IsEmpty(regexp))
		return 0
	endif

	AssertOnAndClearRTError()
	result = GrepString("", regexp); err = GetRTError(1)

	return err == 0
End

threadsafe static Function AreIntervalsIntersectingImpl(variable index, WAVE intervals)

	ASSERT_TS(!IsNaN(intervals[index][0]) && !IsNaN(intervals[index][1]), "Expected finite entries")
	ASSERT_TS(intervals[index][0] < intervals[index][1], "Expected interval start < end")

	if(index == 0)
		return 0
	endif

	// check that every interval, starting from the second interval
	// starts later than the previous one ends
	return (intervals[index][0] < intervals[index - 1][1])
End

/// @brief Return the truth if any of the given intervals ]A, B[ intersect.
///
/// @param intervalsParam Nx2 wave with the intervals
threadsafe Function AreIntervalsIntersecting(WAVE intervalsParam)

	variable numRows, i

	ASSERT_TS(IsNumericWave(intervalsParam), "Expected a numeric wave")

	numRows = DimSize(intervalsParam, ROWS)
	// two columns: start, end
	ASSERT_TS(DimSize(intervalsParam, COLS) == 2, "Expected exactly two columns")

	if(numRows <= 1)
		return 0
	endif

	// sort start column in ascending order
	Duplicate/FREE intervalsParam, intervals
	WaveClear intervalsParam
	SortColumns/KNDX={0} sortWaves=intervals

	Make/FREE/R/N=(numRows) result = NaN

	Multithread result = AreIntervalsIntersectingImpl(p, intervals)

	ASSERT_TS(IsNaN(GetRowIndex(result, val = NaN)), "Error evaluating intervals")

	return IsFinite(GetRowIndex(result, val = 1))
End

/// @brief Return true if `str` is in wildcard syntax, false if not
Function HasWildcardSyntax(string str)

	if(strlen(str) == 0)
		return 0
	endif

	return strsearch(str, "*", 0) >= 0 || !cmpstr(str[0], "!")
End

/// @brief Attempts matching against a number of wildcard patterns
///
/// @param patterns  text wave with wildcard patterns to match against
/// @param matchThis string that is matched
/// @returns Returns 1 if matchThis was successfully matches, 0 otherwise
Function MatchAgainstWildCardPatterns(WAVE/T patterns, string matchThis)

	string pattern

	ASSERT(IsTextWave(patterns), "argument must be text wave")
	ASSERT(!IsNull(matchThis), "argument must not be a null tring")
	for(pattern : patterns)
		if(stringmatch(matchThis, pattern))
			return 1
		endif
	endfor

	return 0
End

/// @brief Check if all elements of the string list are the same
///
/// Returns true for lists with less than one element
Function ListHasOnlyOneUniqueEntry(string list, [string sep])

	variable numElements, i
	string element, refElement

	if(ParamIsDefault(sep))
		sep = ";"
	else
		ASSERT(strlen(sep) == 1, "sep must be only one character")
	endif

	numElements = ItemsInList(list, sep)

	if(numElements <= 1)
		return 1
	endif

	refElement = StringFromList(0, list, sep)

	for(i = 1; i < numElements; i += 1)
		element = StringFromList(i, list, sep)
		if(cmpstr(refElement, element))
			return 0
		endif
	endfor

	return 1
End
