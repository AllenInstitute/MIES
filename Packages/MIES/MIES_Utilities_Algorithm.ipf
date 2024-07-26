#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_UTILS_ALGORITHM
#endif

/// @file MIES_Utilities_Algorithm.ipf
/// @brief utility functions for common algorithms

/// @brief Downsample data
///
/// Downsampling is performed on each @b column of the input wave.
/// Edge-points of the output wave are by default set to zero.
/// @param wv numeric wave, its row must hold more points than downsampleFactor.
///           Will hold the downsampled data on successfull return, in the
///           error case the contents are undetermined
/// @param downsampleFactor positive non-zero integer by which the wave should
///                         be downsampled
/// @param upsampleFactor   positive non-zero integer by which the wave should
///                         be upsampled
/// @param mode 			decimation mode, one of @ref DECIMATION_BY_OMISSION,
///                         @ref DECIMATION_BY_AVERAGING
///                         or @ref DECIMATION_BY_SMOOTHING.
/// @param winFunction 		Windowing function for @ref DECIMATION_BY_SMOOTHING mode,
///                    		must be one of @ref FFT_WINF.
/// @returns One on error, zero otherwise
Function Downsample(wv, downsampleFactor, upsampleFactor, mode, [winFunction])
	WAVE/Z wv
	variable downsampleFactor, upsampleFactor, mode
	string winFunction

	variable numReconstructionSamples = -1

	// parameter checking
	if(!WaveExists(wv))
		print "Wave wv does not exist"
		ControlWindowToFront()
		return 1
	elseif(downsampleFactor <= 0 || downsampleFactor >= DimSize(wv, ROWS))
		print "Parameter downsampleFactor must be strictly positive and strictly smaller than the number of rows in wv."
		ControlWindowToFront()
		return 1
	elseif(!IsInteger(downsampleFactor))
		print "Parameter downsampleFactor must be an integer."
		ControlWindowToFront()
		return 1
	elseif(upsampleFactor <= 0)
		print "Parameter upsampleFactor must be strictly positive."
		ControlWindowToFront()
		return 1
	elseif(!IsInteger(upsampleFactor))
		print "Parameter upsampleFactor must be an integer."
		ControlWindowToFront()
		return 1
	elseif(mode != DECIMATION_BY_SMOOTHING && !ParamIsDefault(winFunction))
		print "Invalid combination of a window function and mode."
		ControlWindowToFront()
		return 1
	elseif(!ParamIsDefault(winFunction) && FindListItem(winFunction, FFT_WINF) == -1)
		print "Unknown windowing function: " + winFunction
		ControlWindowToFront()
		return 1
	endif

	switch(mode)
		case DECIMATION_BY_OMISSION:
			// N=3 is compatible with pre IP 6.01 versions and current versions
			// In principle we want to use N=1 here, which is equivalent with N=3 for the default windowing function
			// See also the Igor Manual page III-141
			numReconstructionSamples = 3
			Resample/DOWN=(downsampleFactor)/UP=(upsampleFactor)/N=(numReconstructionSamples) wv
			break
		case DECIMATION_BY_SMOOTHING:
			numReconstructionSamples = 21 // empirically determined
			if(ParamIsDefault(winFunction))
				Resample/DOWN=(downsampleFactor)/UP=(upsampleFactor)/N=(numReconstructionSamples) wv
			else
				Resample/DOWN=(downsampleFactor)/UP=(upsampleFactor)/N=(numReconstructionSamples)/WINF=$winFunction wv
			endif
			break
		case DECIMATION_BY_AVERAGING:
			// See again the Igor Manual page III-141
			// take the next odd number
			numReconstructionSamples = mod(downSampleFactor, 2) == 0 ? downSampleFactor + 1 : downSampleFactor
			Resample/DOWN=(downsampleFactor)/UP=(upsampleFactor)/N=(numReconstructionSamples)/WINF=None wv
			break
		default:
			print "Invalid mode: " + num2str(mode)
			ControlWindowToFront()
			return 1
	endswitch

	return 0
End

/// @brief Compute the least common multiplier of all entries in the 1D-wave
Function CalculateLCMOfWave(wv)
	WAVE wv

	variable i, result
	variable numRows = DimSize(wv, ROWS)
	if(numRows <= 1)
		return NaN
	endif

	result = CalculateLCM(wv[0], wv[1])
	for(i = 2; i < numRows; i += 1)
		result = CalculateLCM(result, wv[i])
	endfor

	return result
End

/// @brief Returns an unsorted free wave with all unique entries from wv
///        If dontDuplicate is set, then for a single element input wave no new free wave is created but the input wave is returned.
///
/// uses built-in igor function FindDuplicates. Entries are deleted from left to right.
///
/// @param wv             wave reference, can be numeric or text
/// @param caseSensitive  [optional, default = 1] Indicates whether comparison should be case sensitive. Applies only if the input wave is a text wave
/// @param dontDuplicate  [optional, default = 0] for a single element input wave no new free wave is created but the input wave is returned.
threadsafe Function/WAVE GetUniqueEntries(WAVE wv, [variable caseSensitive, variable dontDuplicate])

	variable numRows

	ASSERT_TS(WaveExists(wv), "Wave must exist")

	numRows = DimSize(wv, ROWS)
	ASSERT_TS(numRows == numpnts(wv), "Wave must be 1D")

	dontDuplicate = ParamIsDefault(dontDuplicate) ? 0 : !!dontDuplicate

	if(numRows <= 1)
		if(dontDuplicate)
			return wv
		endif

		Duplicate/FREE wv, result
		return result
	endif

	if(IsTextWave(wv))
		caseSensitive = ParamIsDefault(caseSensitive) ? 1 : !!caseSensitive

		return GetUniqueTextEntries(wv, caseSensitive = caseSensitive)
	endif

	FindDuplicates/FREE/RN=result wv

	return result
End

/// @brief Convenience wrapper around GetUniqueTextEntries() for string lists
threadsafe Function/S GetUniqueTextEntriesFromList(list, [sep, caseSensitive])
	string list, sep
	variable caseSensitive

	if(ParamIsDefault(sep))
		sep = ";"
	else
		ASSERT_TS(strlen(sep) == 1, "Separator should be one byte long")
	endif

	if(ParamIsDefault(caseSensitive))
		caseSensitive = 1
	else
		caseSensitive = !!caseSensitive
	endif

	WAVE/T wv     = ListToTextWave(list, sep)
	WAVE/T unique = GetUniqueTextEntries(wv, caseSensitive = caseSensitive)

	return TextWaveToList(unique, sep)
End

/// @brief Search and Remove Duplicates from Text Wave wv
///
/// Duplicates are removed from left to right
///
/// @param wv             text wave reference
/// @param caseSensitive  [optional, default = 1] Indicates whether comparison should be case sensitive.
/// @param dontDuplicate  [optional, default = 0] for a single element input wave no new free wave is created but the input wave is returned.
///
/// @return free wave with unique entries
threadsafe static Function/WAVE GetUniqueTextEntries(WAVE/T wv, [variable caseSensitive, variable dontDuplicate])

	variable numEntries, numDuplicates, i

	dontDuplicate = ParamIsDefault(dontDuplicate) ? 0 : !!dontDuplicate
	caseSensitive = ParamIsDefault(caseSensitive) ? 1 : !!caseSensitive

	numEntries = DimSize(wv, ROWS)
	ASSERT_TS(numEntries == numpnts(wv), "Wave must be 1D.")

	if(numEntries <= 1)
		if(dontDuplicate)
			return wv
		endif
		Duplicate/T/FREE wv, result
		return result
	endif

	if(caseSensitive)
		FindDuplicates/FREE/RT=result wv
	else
		FindDuplicates/FREE/CI/RT=result wv
	endif

	return result
End

/// @brief Function prototype for use with #CallFunctionForEachListItem
Function CALL_FUNCTION_LIST_PROTOTYPE(str)
	string str
End

/// @brief Function prototype for use with #CallFunctionForEachListItem
threadsafe Function CALL_FUNCTION_LIST_PROTOTYPE_TS(str)
	string str
End

/// @brief Convenience function to call the function f with each list item
///
/// The function's type must be #CALL_FUNCTION_LIST_PROTOTYPE where the return
/// type is ignored.
Function CallFunctionForEachListItem(f, list, [sep])
	FUNCREF CALL_FUNCTION_LIST_PROTOTYPE f
	string list, sep

	variable i, numEntries
	string entry

	if(ParamIsDefault(sep))
		sep = ";"
	endif

	numEntries = ItemsInList(list, sep)
	for(i = 0; i < numEntries; i += 1)
		entry = StringFromList(i, list, sep)

		f(entry)
	endfor
End

/// Compatibility wrapper for threadsafe functions `f`
///
/// @see CallFunctionForEachListItem()
threadsafe Function CallFunctionForEachListItem_TS(f, list, [sep])
	FUNCREF CALL_FUNCTION_LIST_PROTOTYPE_TS f
	string list, sep

	variable i, numEntries
	string entry

	if(ParamIsDefault(sep))
		sep = ";"
	endif

	numEntries = ItemsInList(list, sep)
	for(i = 0; i < numEntries; i += 1)
		entry = StringFromList(i, list, sep)

		f(entry)
	endfor
End

/// @brief Return the row index of the given value, string converted to a variable, or wv
///
/// Assumes wv being one dimensional and does not use any tolerance for numerical values.
threadsafe Function GetRowIndex(wv, [val, str, refWave, reverseSearch])
	WAVE     wv
	variable val
	string   str
	WAVE/Z   refWave
	variable reverseSearch

	variable numEntries, i

	ASSERT_TS(ParamIsDefault(val) + ParamIsDefault(str) + ParamIsDefault(refWave) == 2, "Expected exactly one argument")

	if(ParamIsDefault(reverseSearch))
		reverseSearch = 0
	else
		reverseSearch = !!reverseSearch
	endif

	if(!ParamIsDefault(refWave))
		ASSERT_TS(IsWaveRefWave(wv), "wv must be a wave holding wave references")
		numEntries = DimSize(wv, ROWS)
		WAVE/WAVE cmpWave = wv

		if(!reverseSearch)
			for(i = 0; i < numEntries; i += 1)
				if(WaveRefsEqual(cmpWave[i], refWave)                  \
				   || (!WaveExists(cmpWave[i]) && !WaveExists(refWave)))
					return i
				endif
			endfor
		else
			for(i = numEntries - 1; i >= 0; i -= 1)
				if(WaveRefsEqual(cmpWave[i], refWave)                  \
				   || (!WaveExists(cmpWave[i]) && !WaveExists(refWave)))
					return i
				endif
			endfor
		endif
	else
		if(IsNumericWave(wv))
			if(!ParamIsDefault(str))
				val = str2num(str)
			endif

			if(!reverseSearch)
				if(IsNaN(val))
					FindValue/FNAN wv
				else
					FindValue/V=(val)/T=(0) wv
				endif
			else
				if(IsNaN(val))
					FindValue/FNAN/R wv
				else
					FindValue/V=(val)/R/T=(0) wv
				endif
			endif

			if(V_Value >= 0)
				return V_Value
			endif
		elseif(IsTextWave(wv))
			if(!ParamIsDefault(val))
				str = num2str(val)
			endif

			if(!reverseSearch)
				FindValue/TEXT=(str)/TXOP=4 wv
			else
				FindValue/TEXT=(str)/TXOP=4/R wv
			endif

			if(V_Value >= 0)
				return V_Value
			endif
		endif
	endif

	return NaN
End

/// @brief calculates the relative complement of list2 in list1
///
/// Every list item of `list2` must be in `list1`.
///
/// also called the set-theoretic difference of list1 and list2
/// @returns difference as list
Function/S GetListDifference(string list1, string list2, [variable caseSensitive])

	variable i, numList1
	string item
	string result = ""

	caseSensitive = ParamIsDefault(caseSensitive) ? 1 : !!caseSensitive

	numList1 = ItemsInList(list1)
	for(i = 0; i < numList1; i += 1)
		item = StringFromList(i, list1)
		if(WhichlistItem(item, list2, ";", 0, caseSensitive) == -1)
			result = AddListItem(item, result)
		endif
	endfor

	return result
End

/// @brief Random shuffle of the wave contents
///
/// Function was taken from: http://www.igorexchange.com/node/1614
/// author s.r.chinn
///
/// @param inwave The wave that will have its rows shuffled.
/// @param noiseGenMode [optional, defaults to #NOISE_GEN_XOSHIRO] type of RNG to use
Function InPlaceRandomShuffle(inwave, [noiseGenMode])
	WAVE     inwave
	variable noiseGenMode

	variable i, j, emax, temp
	variable N = DimSize(inwave, ROWS)

	if(ParamIsDefault(noiseGenMode))
		noiseGenMode = NOISE_GEN_XOSHIRO
	endif

	for(i = N; i > 1; i -= 1)
		emax = i / 2
		j    = floor(emax + enoise(emax, noiseGenMode)) //	random index
		// 		emax + enoise(emax) ranges in random value from 0 to 2*emax = i
		temp          = inwave[j]
		inwave[j]     = inwave[i - 1]
		inwave[i - 1] = temp
	endfor
End

/// @brief Extract the values of a list of subrange specifications
/// See also DisplayHelpTopic "Subrange Display"
///
/// Example invocations:
/// \rst
/// .. code-block:: igorpro
///
/// 	WAVE ranges = ExtractFromSubrange("[3,4]_[*]_[1, *;4]_[]_[5][]", 0)
/// \endrst
///
/// @param listOfRanges list of subrange specifications separated by **_**
/// @param dim          dimension to extract
///
/// @returns 2-dim wave with the start, stop, step as columns and rows as
///          number of elements. Returns -1 instead of `*` or ``. An invalid
///          wave reference is returned on parsing errors.
Function/WAVE ExtractFromSubrange(listOfRanges, dim)
	string   listOfRanges
	variable dim

	variable numElements, i, start, stop, step
	string str, rdSpec, stopStr

	numElements = ItemsInList(listOfRanges, "_")

	Make/FREE/I/N=(numElements, 3) ranges

	for(i = 0; i < numElements; i += 1)
		str = StringFromList(i, listOfRanges, "_")
		str = ReplaceString(" ", str, "")
		str = ReplaceString("\t", str, "")
		str = ReplaceString("][", str, "#")
		str = ReplaceString("[", str, "#")
		str = ReplaceString("]", str, "#")

		rdSpec = StringFromList(dim + 1, str, "#")

		// possible options:
		// 1: "" (empty)
		// 2: *
		// 3: $index
		// 4: $start, *
		// 5: $start, $stop
		// 6: $start, $stop;$step

		if(isEmpty(rdSpec) || !cmpstr(rdSpec, "*")) // case 1 & 2
			ranges[i][0] = -1
			ranges[i][1] = -1
		else
			sscanf rdSpec, "%d,%[*0-9];%d ", start, stopStr, step

			if(V_Flag == 1) // case 3
				ranges[i][0] = start
				ranges[i][1] = start
				ranges[i][2] = 1
			elseif(V_Flag == 2)
				if(!cmpstr(stopstr, "*")) // case 4
					ranges[i][0] = start
					ranges[i][1] = -1
					ranges[i][2] = 1
				else
					stop = str2num(stopStr) // case 5
					ASSERT(IsFinite(stop), "stop is not finite")
					ranges[i][0] = start
					ranges[i][1] = stop
					ranges[i][2] = 1
				endif
			elseif(V_Flag == 3) // case 6
				stop         = str2num(stopStr)           // case 5
				ranges[i][0] = start
				ranges[i][1] = IsFinite(stop) ? stop : -1
				ranges[i][2] = step
			else
				return $""
			endif
		endif
	endfor

	return ranges
End

/// @brief Return a wave of the union of all entries from both waves with duplicates removed.
///
/// Given {1, 2, 10} and {2, 5, 11} this will return {1, 2, 5, 10, 11}.
/// The order of the returned entries is not defined.
threadsafe Function/WAVE GetSetUnion(WAVE wave1, WAVE wave2)
	variable type, wave1Points, wave2Points, totalPoints

	ASSERT_TS((IsNumericWave(wave1) && IsNumericWave(wave2))                  \
	          || (IsTextWave(wave1) && IsTextWave(wave2)), "Invalid wave type")

	type = WaveType(wave1)
	ASSERT_TS(type == WaveType(wave2), "Wave type mismatch")

	wave1Points = numpnts(wave1)
	wave2Points = numpnts(wave2)

	totalPoints = wave1Points + wave2Points

	if(totalPoints == 0)
		return $""
	endif

	if(WaveRefsEqual(wave1, wave2))
		Duplicate/FREE wave1, result
		return GetUniqueEntries(result)
	endif

	if(IsNumericWave(wave1))
		Concatenate/NP/FREE {wave1, wave2}, result
	else
		WAVE/T wave1Text = wave1
		WAVE/T wave2Text = wave2

		Make/T/N=(totalPoints)/FREE resultText

		if(wave1Points > 0)
			Multithread/NT=(totalPoints < 1024) resultText[0, wave1Points - 1] = wave1Text[p]
		endif

		if(wave2Points > 0)
			Multithread/NT=(totalPoints < 1024) resultText[wave1Points, Inf] = wave2Text[p - wave1Points]
		endif

		WAVE result = resultText
	endif

	return GetUniqueEntries(result)
End

/// @brief Return a wave were all elements which are in both wave1 and wave2 have been removed from wave1
///
///        The text comparison is case insensitive.
///        wave1 must be 1d, the returned wave is 1d.
///        Waves can be text or numeric, both waves must have the same type
///
/// @sa GetListDifference for string lists
///
/// @param wave1      first wave
/// @param wave2      second wave
/// @param getIndices [optional, default 0] when this flag is set instead of the values the indices in wave1 are returned
///
/// @returns Wave with partial values from wave1 or numeric wave with indices of elements in wave1
threadsafe Function/WAVE GetSetDifference(WAVE wave1, WAVE wave2, [variable getIndices])

	variable isText, index

	getIndices = ParamIsDefault(getIndices) ? 0 : !!getIndices
	isText     = (IsTextWave(wave1) && IsTextWave(wave2))

	ASSERT_TS((IsFloatingPointWave(wave1) && IsFloatingPointWave(wave2)) || isText, "Non matching wave types (both float or both text).")
	ASSERT_TS(WaveType(wave1) == WaveType(wave2), "Wave type mismatch")
	ASSERT_TS(!DimSize(wave1, COLS), "input wave1 must be 1d")

	WAVE/Z result

	if(isText)
		[result, index] = GetSetDifferenceText(wave1, wave2, getIndices)
	else
		[result, index] = GetSetDifferenceNumeric(wave1, wave2, getIndices)
	endif

	if(index == 0)
		return $""
	endif

	Redimension/N=(index) result

	return result
End

threadsafe static Function [WAVE result, variable index] GetSetDifferenceNumeric(WAVE wave1, WAVE wave2, variable getIndices)

	variable numEntries, i, j, value

	Duplicate/FREE wave1, result

	numEntries = DimSize(wave1, ROWS)
	if(getIndices)
		for(i = 0; i < numEntries; i += 1)
			value = wave1[i]

			FindValue/UOFV/V=(value) wave2
			if(V_Value == -1)
				result[j++] = i
			endif
		endfor
	else
		for(value : wave1)
			FindValue/UOFV/V=(value) wave2
			if(V_Value == -1)
				result[j++] = value
			endif
		endfor
	endif

	return [result, j]
End

threadsafe static Function [WAVE result, variable index] GetSetDifferenceText(WAVE/T wave1, WAVE/T wave2, variable getIndices)

	variable numEntries, i, j
	string str

	numEntries = DimSize(wave1, ROWS)
	if(getIndices)
		Make/FREE/D/N=(numEntries) resultIndices
		for(i = 0; i < numEntries; i += 1)
			FindValue/UOFV/TEXT=(wave1[i])/TXOP=4 wave2
			if(V_Value == -1)
				resultIndices[j++] = i
			endif
		endfor
		WAVE result = resultIndices
	else
		Duplicate/FREE/T wave1, resultTxT
		for(str : wave1)
			FindValue/UOFV/TEXT=(str)/TXOP=4 wave2
			if(V_Value == -1)
				resultTxT[j++] = str
			endif
		endfor
		WAVE result = resultTxT
	endif

	return [result, j]
End

/// @brief Return a wave with the set theory style intersection of wave1 and wave2
///
/// Given {1, 2, 4, 10} and {2, 5, 11} this will return {2}.
/// Given {10, 2, 4, 2, 1} and {11, 5, 2} with getIndices = 1 this will return {1, 3}.
///
/// Inspired by http://www.igorexchange.com/node/366 but adapted to modern Igor Pro
/// It does work with text waves as well, there it performs case sensitive comparisons
///
/// For wave1 and wave2 numerical and text waves are allowed, wave1 and wave2 must have the same type.
///
/// @param wave1      first wave
/// @param wave2      second wave
/// @param getIndices [optional, default 0] when this flag is set then the index positions of the
///                   intersecting elements in the first wave are returned.
/// @return free wave with the set intersection or an null wave reference
/// if the intersection is an empty set
threadsafe Function/WAVE GetSetIntersection(WAVE wave1, WAVE wave2, [variable getIndices])

	variable type, wave1Rows, wave2Rows
	variable longRows, shortRows, entry
	variable i, j, longWaveRow
	string strEntry

	ASSERT_TS((IsNumericWave(wave1) && IsNumericWave(wave2))                  \
	          || (IsTextWave(wave1) && IsTextWave(wave2)), "Invalid wave type")
	ASSERT_TS(!DimSize(wave1, COLS) && !DimSize(wave2, COLS), "input waves must be 1d")

	getIndices = ParamIsDefault(getIndices) ? 0 : !!getIndices

	type = WaveType(wave1)
	ASSERT_TS(type == WaveType(wave2), "Wave type mismatch")

	wave1Rows = DimSize(wave1, ROWS)
	wave2Rows = DimSize(wave2, ROWS)

	if(wave1Rows == 0 || wave2Rows == 0)
		return $""
	elseif(WaveRefsEqual(wave1, wave2))
		Duplicate/FREE wave1, matches
		return matches
	endif

	if(wave1Rows > wave2Rows && !getIndices)
		Duplicate/FREE wave1, longWave
		WAVE shortWave = wave2
		longRows  = wave1Rows
		shortRows = wave2Rows
	else
		Duplicate/FREE wave2, longWave
		WAVE shortWave = wave1
		longRows  = wave2Rows
		shortRows = wave1Rows
	endif

	// Sort values in longWave
	Sort/C longWave, longWave
	if(getIndices)
		Make/FREE/D/N=(shortRows) indicesWave
	else
		Make/FREE/N=(shortRows)/Y=(type) resultWave
	endif

	if(type == 0)
		WAVE/T shortWaveText = shortWave
		WAVE/T longWaveText  = longWave
		if(getIndices)
			for(i = 0; i < shortRows; i += 1)
				strEntry    = shortWaveText[i]
				longWaveRow = BinarySearchText(longWave, strEntry, caseSensitive = 1)
				if(longWaveRow >= 0)
					indicesWave[j++] = i
				endif
			endfor
		else
			WAVE/T resultWaveText = resultWave
			for(strEntry : shortWaveText)
				longWaveRow = BinarySearchText(longWave, strEntry, caseSensitive = 1)
				if(longWaveRow >= 0)
					resultWaveText[j++] = strEntry
				endif
			endfor
		endif
	else
		if(getIndices)
			for(i = 0; i < shortRows; i += 1)
				entry       = shortWave[i]
				longWaveRow = BinarySearch(longWave, entry)
				if(longWaveRow >= 0 && longWave[longWaveRow] == entry)
					indicesWave[j++] = i
				endif
			endfor
		else
			for(entry : shortWave)
				longWaveRow = BinarySearch(longWave, entry)
				if(longWaveRow >= 0 && longWave[longWaveRow] == entry)
					resultWave[j++] = entry
				endif
			endfor
		endif
	endif

	if(j == 0)
		return $""
	endif

	if(getIndices)
		Redimension/N=(j) indicesWave
		return indicesWave
	endif

	Redimension/N=(j) resultWave

	return resultWave
End

threadsafe static Function FindLevelSingle(WAVE data, variable level, variable edge, variable first, variable last)

	variable found, numLevels

	FindLevel/Q/EDGE=(edge)/R=[first, last] data, level
	found = !V_flag

	if(!found)
		return NaN
	endif

	return V_LevelX - DimDelta(data, ROWS) * first
End

threadsafe static Function/WAVE FindLevelsMult(WAVE data, variable level, variable edge, variable first, variable last, variable maxNumLevels)
	variable found, numLevels

	Make/FREE/D/N=0 levels
	FindLevels/Q/DEST=levels/EDGE=(edge)/R=[first, last]/N=(maxNumLevels) data, level
	found     = V_flag != 2
	numLevels = found ? DimSize(levels, ROWS) : 0

	Redimension/N=(numLevels) levels

	if(numLevels > 0)
		levels[] = levels[p] - DimDelta(data, ROWS) * first
	endif

	return levels
End

/// @brief FindLevel wrapper which handles 2D data without copying data
///
/// @param data         input data, can be either 1D or 2D
/// @param level        level to search
/// @param edge         type of the edge, one of @ref FindLevelEdgeTypes
/// @param mode         mode, one of @ref FindLevelModes
/// @param maxNumLevels [optional, defaults to number of points/rows] maximum number of levels to find
///
/// The returned levels are in the wave's row units.
///
/// FINDLEVEL_MODE_SINGLE:
/// - Return a 1D wave with as many rows as columns in the input data
/// - Contents are the x values of the first level or NaN if none could be found
///
/// FINDLEVEL_MODE_MULTI:
/// - Returns a 2D WAVE rows being the number of columns in the input
///   data and columns holding all found x values of the levels per data column.
///
/// In both cases the dimension label of the each column holds the number of found levels
/// in each data colum. This will be always 1 for FINDLEVEL_MODE_SINGLE.
threadsafe Function/WAVE FindLevelWrapper(WAVE data, variable level, variable edge, variable mode, [variable maxNumLevels])
	variable numCols, numColsFixed, numRows, numLayers, xDelta, maxLevels, numLevels
	variable first, last, i, xLevel, found, columnOffset

	numCols      = DimSize(data, COLS)
	numRows      = DimSize(data, ROWS)
	numLayers    = DimSize(data, LAYERS)
	numColsFixed = max(1, numCols)
	xDelta       = DimDelta(data, ROWS)

	if(ParamIsDefault(maxNumLevels))
		maxNumLevels = numRows
	else
		ASSERT_TS(IsInteger(maxNumLevels) && maxNumLevels > 0, "maxNumLevels has to be a positive integer")
		ASSERT_TS(mode == FINDLEVEL_MODE_MULTI, "maxNumLevels can only be combined with FINDLEVEL_MODE_MULTI mode")
	endif

	ASSERT_TS(IsNumericWave(data), "Expected numeric wave")
	ASSERT_TS(numRows >= 2, "Expected wave with more than two rows")
	ASSERT_TS(IsFinite(level), "Expected finite level")
	ASSERT_TS(edge == FINDLEVEL_EDGE_INCREASING || edge == FINDLEVEL_EDGE_DECREASING || edge == FINDLEVEL_EDGE_BOTH, "Invalid edge type")
	ASSERT_TS(mode == FINDLEVEL_MODE_SINGLE || mode == FINDLEVEL_MODE_MULTI, "Invalid mode type")

	ASSERT_TS(numLayers <= 1, "Unexpected input dimension")

	Redimension/N=(numColsFixed * numRows)/E=1 data

	// Algorithm:
	//
	// Both:
	// - Find the linearized slice of data which represents one column in the input wave
	//   and run a multi threaded function on it.
	//
	// FINDLEVEL_MODE_SINGLE:
	// - Run FindLevel on that slice
	//
	// FINDLEVEL_MODE_MULTI:
	// - Run FindLevels on that slice

	if(mode == FINDLEVEL_MODE_SINGLE)
		Make/D/FREE/N=(numColsFixed) resultSingle
		Multithread resultSingle[] = FindLevelSingle(data, level, edge, p * numRows, (p + 1) * numRows - 1)
	elseif(mode == FINDLEVEL_MODE_MULTI)
		Make/WAVE/FREE/N=(numColsFixed) allLevels
		Multithread allLevels[] = FindLevelsMult(data, level, edge, p * numRows, (p + 1) * numRows - 1, maxNumLevels)

		Make/D/FREE/N=(numColsFixed) numMaxLevels = DimSize(allLevels[p], ROWS)

		maxLevels = WaveMax(numMaxLevels)
		Make/D/FREE/N=(numColsFixed, maxLevels) resultMulti

		resultMulti[][] = q < numMaxLevels[p] ? WaveRef(allLevels[p])[q] : NaN
	endif

	// don't use numColsFixed here as we want to have the original shape
	Redimension/N=(numRows, numCols, numLayers)/E=1 data

	switch(mode)
		case FINDLEVEL_MODE_SINGLE:
			Make/D/FREE/N=(DimSize(resultSingle, ROWS)) numMaxLevels = 1
			SetDimensionLabels(resultSingle, NumericWaveToList(numMaxLevels, ";"), ROWS)
			return resultSingle
		case FINDLEVEL_MODE_MULTI:
			SetDimensionLabels(resultMulti, NumericWaveToList(numMaxLevels, ";"), ROWS)

			// avoid single column waves
			if(DimSize(resultMulti, COLS) == 1)
				Redimension/N=(-1, 0) resultMulti
			endif

			return resultMulti
		default:
			ASSERT_TS(0, "Impossible case")
	endswitch
End

/// @brief Wrapper for `Grep` which uses a textwave for input and ouput
Function/WAVE GrepWave(WAVE/T wv, string regex)

	Make/FREE/T/N=0 result
	Grep/E=regex wv as result

	if(DimSize(result, ROWS) == 0)
		return $""
	endif

	return result
End

/// @brief Grep the given regular expression in the text wave
Function/WAVE GrepTextWave(WAVE/T in, string regexp, [variable invert])

	if(ParamIsDefault(invert))
		invert = 0
	else
		invert = !!invert
	endif

	Make/FREE/T/N=0 result
	Grep/E={regexp, invert} in as result

	if(DimSize(result, ROWS) == 0)
		return $""
	endif

	return result
End

/// @brief Distribute N elements over a range from 0.0 to 1.0 with spacing
Function [WAVE/D start, WAVE/D stop] DistributeElements(variable numElements, [variable offset])

	variable elementLength, spacing

	ASSERT(numElements > 0, "Invalid number of elements")

	if(!ParamIsDefault(offset))
		ASSERT(IsFinite(offset) && offset >= 0.0 && offset < 1.0, "Invalid offset")
	endif

	// limit the spacing for a lot of entries
	// we only want to use 20% for spacing in total
	if((numElements - 1) * GRAPH_DIV_SPACING > 0.20)
		spacing = 0.20 / (numElements - 1)
	else
		spacing = GRAPH_DIV_SPACING
	endif

	elementLength = (1.0 - offset - (numElements - 1) * spacing) / numElements

	Make/FREE/D/N=(numElements) start, stop

	start[] = limit(offset + p * (elementLength + spacing), 0.0, 1.0)
	stop[]  = limit(start[p] + elementLength, 0.0, 1.0)

	return [start, stop]
End

/// @brief Calculate a nice length which is an integer number of `multiple` long
///
/// For small values @f$ 10^{-x} @f$ times `multiple` are returned
Function CalculateNiceLength(variable range, variable multiple)

	variable div, numDigits

	div       = range / multiple
	numDigits = log(div)

	if(numDigits > 0)
		return round(div) * multiple
	endif

	return multiple * 10^(round(numDigits)) // NOLINT
End

/// @brief Finds the first occurrence of a text within a range of points in a SORTED text wave
///
/// From https://www.wavemetrics.com/code-snippet/binary-search-pre-sorted-text-waves by Jamie Boyd
/// Completely reworked, fixed and removed unused features
threadsafe Function BinarySearchText(WAVE/T theWave, string theText, [variable caseSensitive, variable startPos, variable endPos])
	variable iPos    // the point to be compared
	variable theCmp  // the result of the comparison
	variable firstPt
	variable lastPt
	variable i
	variable numRows

	numRows = DimSize(theWave, ROWS)

	ASSERT_TS(DimSize(theWave, COLS) <= 1, "Only works with 1D waves")
	ASSERT_TS(IsTextWave(theWave), "Only works with text waves")

	if(numRows == 0)
		// always no match
		return NaN
	endif

	if(ParamIsDefault(caseSensitive))
		caseSensitive = 0
	else
		caseSensitive = !!caseSensitive
	endif

	if(ParamIsDefault(startPos))
		startPos = 0
	else
		ASSERT_TS(startPos >= 0 && startPos < numRows, "Invalid startPos")
	endif

	if(ParamIsDefault(endPos))
		endPos = numRows - 1
	else
		ASSERT_TS(endPos >= 0 && endPos < numRows, "Invalid endPos")
	endif

	ASSERT_TS(startPos <= endPos, "startPos is larger than endPos")

	firstPt = startPos
	lastPt  = endPos

	for(i = 0; firstPt <= lastPt; i += 1)
		iPos   = trunc((firstPt + lastPt) / 2)
		theCmp = cmpstr(thetext, theWave[iPos], caseSensitive)

		if(theCmp == 0) //thetext is the same as theWave [iPos]
			if((iPos == startPos) || (cmpstr(theText, theWave[iPos - 1], caseSensitive) == 1))
				// then iPos is the first occurence of thetext in theWave from startPos to endPos
				return iPos
			else //  there are more copies of theText in theWave before iPos
				lastPt = iPos - 1
			endif
		elseif(theCmp == 1) //thetext is alphabetically after theWave [iPos]
			firstPt = iPos + 1
		else // thetext is alphabetically before theWave [iPos]
			lastPt = iPos - 1
		endif
	endfor

	return NaN
End

/// @brief Calculate PowerSpectrum on a per column basis on each input[][col]
///        and write the result into output[][col]. The result is capped to the output rows.
///        No window function is applied.
threadsafe Function DoPowerSpectrum(WAVE input, WAVE output, variable col)
	variable numRows = DimSize(input, ROWS)

	Duplicate/FREE/RMD=[*][col] input, slice
	Redimension/N=(numRows) slice

	WAVE powerSpectrum = DoFFT(slice, winFunc = FFT_WINF_DEFAULT)

	output[][col] = magsqr(powerSpectrum[p])
End

/// @brief Perform FFT on input with optionally given window function
///
/// @param input   Wave to perform FFT on
/// @param winFunc [optional, defaults to NONE] FFT window function
/// @param padSize [optional, defaults to the next power of 2 of the input wave row size] Target size used for padding
threadsafe Function/WAVE DoFFT(WAVE input, [string winFunc, variable padSize])

	if(ParamIsDefault(padSize))
		padSize = TP_GetPowerSpectrumLength(DimSize(input, ROWS))
	else
		ASSERT_TS(IsFinite(padSize) && padSize >= DimSize(input, ROWS), "padSize must be finite and larger as the input row size")
	endif

	if(ParamIsDefault(winFunc))
		FFT/PAD={padSize}/DEST=result/FREE input
	else
		ASSERT_TS(WhichListItem(winFunc, FFT_WINF) >= 0, "Invalid window function for FFT")
		FFT/PAD={padSize}/WINF=$winFunc/DEST=result/FREE input
	endif

	return result
End

/// @brief Convert a numerical integer list seperated by sepChar to a list including a range sign ("-")
/// e. g. 1,2,3,4 -> 1-4
/// 1,2,4,5,6 -> 1-2,4-6
/// 1,1,1,2 -> 1-2
/// the input list does not have to be sorted
Function/S CompressNumericalList(string list, string sepChar)

	variable i, nextEntry, entry, nextEntryMinusOne, numItems
	variable firstConsecutiveEntry = NaN
	string   resultList            = ""

	ASSERT(!IsEmpty(sepChar), "Seperation character is empty.")

	if(IsEmpty(list))
		return ""
	endif

	list     = SortList(list, sepChar, 2)
	numItems = ItemsInList(list, sepChar)

	for(i = 0; i < numItems; i += 1)

		entry = str2numSafe(StringFromList(i, list, sepChar))
		ASSERT(IsInteger(entry), "Number from list item must be integer")
		nextEntry = str2numSafe(StringFromList(i + 1, list, sepChar))

		if(entry == nextEntry)
			continue
		endif

		nextEntryMinusOne = str2numSafe(StringFromList(i + 1, list, sepChar)) - 1

		if(IsNaN(entry))
			continue
		endif

		// different entries and no range in progress
		if(entry != nextEntryMinusOne && IsNaN(firstConsecutiveEntry))
			resultList = AddListItem(num2istr(entry), resultList, sepChar, Inf)
			// different entries but we have to finalize the last range
		elseif(entry != nextEntryMinusOne && !IsNaN(firstConsecutiveEntry))
			resultList           += "-" + num2istr(entry) + sepChar
			firstConsecutiveEntry = NaN
			// same entries and we have to start a range
		elseif(entry == nextEntryMinusOne && IsNaN(firstConsecutiveEntry))
			resultList           += num2istr(entry)
			firstConsecutiveEntry = entry
			// else
			// same entries and a range is in progress
		endif
	endfor

	return RemoveEnding(resultList, sepChar)
End

/// @brief Splits a text wave (with e.g. log entries) into parts. The parts are limited by a size in bytes such that each part
///        contains only complete lines and is smaller than the given size limit. A possible separator for line endings
///        is considered in the size calculation.
///
/// @param logData       text wave
/// @param sep           separator string that is considered in the length calculation. This is useful if the resulting waves are later converted
///                      to strings with TextWaveToList, where the size grows by lines * separatorLength.
/// @param lim           size limit for each part in bytes
/// @param lastIndex     [optional, default DimSize(logData, ROWS) - 1] When set, only elements in logData from index 0 to lastIndex are considered. lastIndex is included.
///                      lastIndex is limited between 0 and DimSize(logData, ROWS) - 1.
/// @param firstPartSize [optional, default lim] When set then the first parts size limit is firstPartSize instead of lim
/// @returns wave reference wave containing text waves that are consecutive and sequential parts of logdata
Function/WAVE SplitLogDataBySize(WAVE/T logData, string sep, variable lim, [variable lastIndex, variable firstPartSize])

	variable lineCnt, sepLen, i, size, elemSize
	variable first, sizeLimit, resultCnt

	lineCnt       = DimSize(logData, ROWS)
	firstPartSize = ParamIsDefault(firstPartSize) ? lim : firstPartSize
	lastIndex     = ParamIsDefault(lastIndex) ? lineCnt - 1 : limit(lastIndex, 0, lineCnt - 1)
	sepLen        = strlen(sep)
	Make/FREE/D/N=(lastIndex + 1) logSizes
	MultiThread logSizes[0, lastIndex] = strlen(logData[p])

	Make/FREE/WAVE/N=(MINIMUM_WAVE_SIZE) result

	sizeLimit = firstPartSize
	for(i = 0; i <= lastIndex; i += 1)
		elemSize = logSizes[i] + sepLen
		ASSERT(elemSize <= sizeLimit, "input element larger than size limit " + num2istr(elemSize) + " / " + num2istr(sizeLimit))
		size += elemSize
		if(size > sizeLimit)

			Duplicate/FREE/T/RMD=[first, i - 1] logData, logPart
			EnsureLargeEnoughWave(result, indexShouldExist = resultCnt)
			result[resultCnt] = logPart
			resultCnt        += 1

			sizeLimit = lim
			first     = i
			size      = elemSize
		endif
	endfor

	Duplicate/FREE/T/RMD=[first, i - 1] logData, logPart
	EnsureLargeEnoughWave(result, indexShouldExist = resultCnt)
	result[resultCnt] = logPart
	resultCnt        += 1

	Redimension/N=(resultCnt) result

	return result
End
