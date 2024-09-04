#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_UTILS_WAVEHANDLING
#endif

/// @file MIES_Utilities_WaveHandling.ipf
/// @brief utility functions for wave handling

/// @brief Redimension the wave to at least the given size.
///
/// The redimensioning is only done if it is required.
///
/// Can be used to fill a wave one at a time with the minimum number of
/// redimensions. In the following example `NOTE_INDEX` is the index of the
/// next free row *and* the total number of rows filled with data.
///
/// \rst
/// .. code-block:: igorpro
///
/// 	Make/FREE/N=(MINIMUM_WAVE_SIZE) data
/// 	SetNumberInWaveNote(data, NOTE_INDEX, 0)
/// 	// ...
/// 	for(...)
/// 		index = GetNumberFromWaveNote(data, NOTE_INDEX)
/// 		// ...
/// 		EnsureLargeEnoughWave(data, dimension = ROWS, indexShouldExist = index)
/// 		data[index] = ...
/// 		// ...
/// 	    SetNumberInWaveNote(data, NOTE_INDEX, ++index)
/// 	endfor
/// \endrst
///
/// @param wv               wave to redimension
/// @param indexShouldExist [optional, default is implementation defined] the minimum size of the wave.
///                         The actual size of the wave after the function returns might be larger.
/// @param dimension        [optional, defaults to ROWS] dimension to resize, all other dimensions are left untouched.
/// @param initialValue     [optional, defaults to zero] initialValue of the new wave points
/// @param checkFreeMemory  [optional, defaults to false] check if the free memory is enough for increasing the size
///
/// @return 0 on success, (only for checkFreeMemory = True) 1 if increasing the wave's size would fail due to out of memory
threadsafe Function EnsureLargeEnoughWave(WAVE wv, [variable indexShouldExist, variable dimension, variable initialValue, variable checkFreeMemory])

	if(ParamIsDefault(dimension))
		dimension = ROWS
	endif

	if(ParamIsDefault(checkFreeMemory))
		checkFreeMemory = 0
	else
		checkFreeMemory = !!checkFreeMemory
	endif

	ASSERT_TS(dimension == ROWS || dimension == COLS || dimension == LAYERS || dimension == CHUNKS, "Invalid dimension")
	ASSERT_TS(WaveExists(wv), "Wave does not exist")
	ASSERT_TS(IsFinite(indexShouldExist) && indexShouldExist >= 0, "Invalid minimum size")

	if(ParamIsDefault(indexShouldExist))
		indexShouldExist = MINIMUM_WAVE_SIZE - 1
	else
		indexShouldExist = max(MINIMUM_WAVE_SIZE - 1, indexShouldExist)
	endif

	if(indexShouldExist < DimSize(wv, dimension))
		return 0
	endif

	indexShouldExist *= 2

	if(checkFreeMemory)
		if(GetWaveSize(wv) * (indexShouldExist / DimSize(wv, dimension)) / 1024 / 1024 / 1024 >= GetFreeMemory())
			return 1
		endif
	endif

	Make/FREE/L/N=(MAX_DIMENSION_COUNT) targetSizes = -1
	targetSizes[dimension] = indexShouldExist

	WAVE oldSizes = GetWaveDimensions(wv)

	Redimension/N=(targetSizes[ROWS], targetSizes[COLS], targetSizes[LAYERS], targetSizes[CHUNKS]) wv

	if(!ParamIsDefault(initialValue))
		ASSERT_TS(ValueCanBeWritten(wv, initialValue), "initialValue can not be stored in wv")
		switch(dimension)
			case ROWS:
				wv[oldSizes[ROWS],][][][] = initialValue
				break
			case COLS:
				wv[][oldSizes[COLS],][][] = initialValue
				break
			case LAYERS:
				wv[][][oldSizes[LAYERS],][] = initialValue
				break
			case CHUNKS:
				wv[][][][oldSizes[CHUNKS],] = initialValue
				break
		endswitch
	endif

	return 0
End

/// @brief Resize the number of rows to maximumSize if it is larger than that
///
/// @param wv          wave to redimension
/// @param maximumSize maximum number of the rows, defaults to MAXIMUM_SIZE
Function EnsureSmallEnoughWave(wv, [maximumSize])
	WAVE     wv
	variable maximumSize

	if(ParamIsDefault(maximumSize))
		maximumSize = MAXIMUM_WAVE_SIZE
	endif

	WAVE oldSizes = GetWaveDimensions(wv)

	if(oldSizes[ROWS] > maximumSize)
		Redimension/N=(maximumSize, -1, -1, -1) wv
	endif
End

/// @brief Return a wave with `MAX_DIMENSION_COUNT` entries with the size of each dimension
threadsafe Function/WAVE GetWaveDimensions(WAVE wv)

	ASSERT_TS(WaveExists(wv), "Missing wave")
	Make/FREE/D/N=(MAX_DIMENSION_COUNT) sizes = DimSize(wv, p)

	return sizes
End

/// @brief Returns the size of the wave in bytes
threadsafe static Function GetWaveSizeImplementation(wv)
	WAVE wv

	return NumberByKey("SizeInBytes", WaveInfo(wv, 0))
End

/// @brief Return the size in bytes of a given type
///
/// Inspired by http://www.igorexchange.com/node/1845
threadsafe Function GetSizeOfType(WAVE wv)
	variable type, size

	type = WaveType(wv)

	if(type == 0)
		// text waves, wave reference wave, dfref wave
		// we just return the size of a pointer on 64bit as
		// everything else would be too expensive to calculate
		return 8
	endif

	size = 1

	if(type & IGOR_TYPE_COMPLEX)
		size *= 2
	endif

	if(type & IGOR_TYPE_32BIT_FLOAT)
		size *= 4
	elseif(type & IGOR_TYPE_64BIT_FLOAT)
		size *= 8
	elseif(type & IGOR_TYPE_8BIT_INT)
		// do nothing
	elseif(type & IGOR_TYPE_16BIT_INT)
		size *= 2
	elseif(type & IGOR_TYPE_32BIT_INT)
		size *= 4
	elseif(type & IGOR_TYPE_64BIT_INT)
		size *= 8
	else
		ASSERT_TS(0, "Unexpected type")
	endif

	return size
End

/// @brief Returns the size of the wave in bytes.
threadsafe Function GetWaveSize(wv, [recursive])
	WAVE/Z   wv
	variable recursive

	if(ParamIsDefault(recursive))
		recursive = 0
	else
		recursive = !!recursive
	endif

	if(!WaveExists(wv))
		return 0
	endif

	if(!recursive || !IsWaveRefWave(wv))
		return GetWaveSizeImplementation(wv)
	endif

	WAVE/WAVE waveRefs = wv

	Make/FREE/L/U/N=(DimSize(wv, ROWS)) sizes = GetWaveSize(waveRefs[p], recursive = 1)

	return GetWaveSize(wv, recursive = 0) + Sum(sizes)
End

/// @brief Return the lock state of the passed wave
threadsafe Function GetLockState(WAVE wv)

	ASSERT_TS(WaveExists(wv), "Invalid wave")

	return NumberByKey("LOCK", WaveInfo(wv, 0))
End

/// @brief Returns the numeric value of `key` found in the wave note,
/// returns NaN if it could not be found
///
/// The expected wave note format is: `key1:val1;key2:val2;`
/// UTF_NOINSTRUMENTATION
threadsafe Function GetNumberFromWaveNote(wv, key)
	WAVE   wv
	string key

	ASSERT_TS(WaveExists(wv), "Missing wave")
	ASSERT_TS(!IsEmpty(key), "Empty key")

	return NumberByKey(key, note(wv))
End

/// @brief Updates the numeric value of `key` found in the wave note to `val`
///
/// @param wv     wave
/// @param key    key of the Key/Value pair
/// @param val    value of the Key/Value pair
/// @param format [optional] printf compatible format string to set
///               the conversion to string for `val`
///
/// The expected wave note format is: `key1:val1;key2:val2;`
threadsafe Function SetNumberInWaveNote(wv, key, val, [format])
	WAVE     wv
	string   key
	variable val
	string   format

	string str

	ASSERT_TS(WaveExists(wv), "Missing wave")
	ASSERT_TS(!IsEmpty(key), "Empty key")

	if(!ParamIsDefault(format))
		ASSERT_TS(!IsEmpty(format), "Empty format")
		sprintf str, format, val
		Note/K wv, ReplaceStringByKey(key, note(wv), str)
	else
		Note/K wv, ReplaceNumberByKey(key, note(wv), val)
	endif
End

/// @brief Return the string value of `key` found in the wave note
/// default expected wave note format: `key1:val1;key2:str2;`
/// counterpart of AddEntryIntoWaveNoteAsList when supplied with keySep = "="
///
/// @param wv   wave reference where the WaveNote is taken from
/// @param key  search for the value at key:value;
/// @param keySep  [optional, defaults to #DEFAULT_KEY_SEP] separation character for (key, value) pairs
/// @param listSep [optional, defaults to #DEFAULT_LIST_SEP] list separation character
/// @param recursive [optional, defaults to false] checks all wave notes in referenced waves from wave reference waves
///
/// @returns the value on success. An empty string is returned if it could not be found
threadsafe Function/S GetStringFromWaveNote(WAVE wv, string key, [string keySep, string listSep, variable recursive])
	variable numEntries = numpnts(wv)
	string result

	if(ParamIsDefault(recursive))
		recursive = 0
	else
		recursive = !!recursive
	endif

	if(ParamIsDefault(keySep))
		keySep = DEFAULT_KEY_SEP
	endif

	if(ParamIsDefault(listSep))
		listSep = DEFAULT_LIST_SEP
	endif

	result = ExtractStringFromPair(note(wv), key, keySep = keySep, listSep = listSep)

	if(!recursive || !IsWaveRefWave(wv) || numEntries == 0)
		return result
	endif

	Make/FREE/T/N=(numEntries) notes = ExtractStringFromPair(note(WaveRef(wv, row = p)), key, keySep = keySep, listSep = listSep)

	WAVE/T/Z uniqueEntries = GetUniqueEntries(notes)
	ASSERT_TS(WaveExists(uniqueEntries), "Missing unique entries")

	if(DimSize(uniqueEntries, ROWS) == 1 && !cmpstr(uniqueEntries[0], result))
		return result
	endif

	return ""
End

/// @brief Update the string value of `key` found in the wave note to `str`
///
/// The expected wave note format is: `key1:val1;key2:str2;`
threadsafe Function SetStringInWaveNote(WAVE wv, string key, string str, [variable recursive, string keySep, string listSep])

	variable numEntries

	if(ParamIsDefault(recursive))
		recursive = 0
	else
		recursive = !!recursive
	endif
	if(ParamIsDefault(keySep))
		keySep = ":"
	else
		ASSERT_TS(!IsEmpty(keySep), "key separator can not be empty")
	endif
	if(ParamIsDefault(listSep))
		listSep = ";"
	else
		ASSERT_TS(!IsEmpty(listSep), "list separator can not be empty")
	endif

	ASSERT_TS(WaveExists(wv), "Missing wave")
	ASSERT_TS(!IsEmpty(key), "Empty key")

	Note/K wv, ReplaceStringByKey(key, note(wv), str, keySep, listSep)

	numEntries = numpnts(wv)
	if(!recursive || !IsWaveRefWave(wv) || numEntries == 0)
		return NaN
	endif

	Make/FREE/N=(numEntries) junk = SetStringInWaveNote(WaveRef(wv, row = p), key, str, recursive = 1)
End

/// @brief Structured writing of numerical values with names into wave notes
///
/// The general layout is `key1 = var;key2 = str;` and the note is never
/// prefixed with a carriage return ("\r").
/// @param wv            wave to add the wave note to
/// @param key           string identifier
/// @param var           variable to output
/// @param str           string to output
/// @param appendCR      0 (default) or 1, should a carriage return ("\r") be appended to the note
/// @param replaceEntry  0 (default) or 1, should existing keys named `key` be replaced (does only work reliable
///                      in wave note lists without carriage returns).
/// @param format        [optional, defaults to `%g`] format string used for converting `var` to `str`
Function AddEntryIntoWaveNoteAsList(wv, key, [var, str, appendCR, replaceEntry, format])
	WAVE     wv
	string   key
	variable var
	string   str
	variable appendCR, replaceEntry
	string format

	string formattedString, formatString

	ASSERT(WaveExists(wv), "missing wave")
	ASSERT(!IsEmpty(key), "empty key")
	ASSERT(strsearch(key, ";", 0) == -1, "key can not contain a semicolon")

	if(ParamIsDefault(format))
		formatString = "%s = %g;"
	else
		ASSERT(strsearch(format, ";", 0) == -1, "format can not contain a semicolon")
		formatString = "%s = " + format + ";"
	endif

	if(!ParamIsDefault(var))
		sprintf formattedString, formatString, key, var
	elseif(!ParamIsDefault(str))
		ASSERT(strsearch(str, ";", 0) == -1, "str can not contain a semicolon")
		formattedString = key + " = " + str + ";"
	else
		formattedString = key + ";"
	endif

	appendCR     = ParamIsDefault(appendCR) ? 0 : appendCR
	replaceEntry = ParamIsDefault(replaceEntry) ? 0 : replaceEntry

	if(replaceEntry)
		Note/K wv, RemoveByKey(key + " ", note(wv), "=")
	endif

	if(appendCR)
		Note/NOCR wv, formattedString + "\r"
	else
		Note/NOCR wv, formattedString
	endif
End

/// @brief Checks if `key = value;` can be found in the wave note
///
/// Ignores spaces around the equal ("=") sign.
///
/// @sa AddEntryIntoWaveNoteAsList()
Function HasEntryInWaveNoteList(wv, key, value)
	WAVE wv
	string key, value

	return GrepString(note(wv), "\\Q" + key + "\\E\\s*=\\s*\\Q" + value + "\\E\\s*;")
End

/// @brief Returns a wave name not used in the given datafolder
///
/// Basically a datafolder aware version of UniqueName for datafolders
///
/// @param dfr 	    datafolder reference where the new datafolder should be created
/// @param baseName first part of the wave name
threadsafe Function/S UniqueWaveName(DFREF dfr, string baseName)

	ASSERT_TS(!isEmpty(baseName), "baseName must not be empty")
	ASSERT_TS(DataFolderExistsDFR(dfr), "dfr does not exist")

	return CreateDataObjectName(dfr, basename, 1, 0, 0)
End

/// @brief Return a new wave from the subrange of the given 1D wave
Function/WAVE DuplicateSubRange(wv, first, last)
	WAVE wv
	variable first, last

	ASSERT(DimSize(wv, COLS) == 0, "Requires 1D wave")

	Duplicate/RMD=[first, last]/FREE wv, result

	return result
End

/// @brief Search the row in refWave which has the same contents as the given row in the sourceWave
Function GetRowWithSameContent(refWave, sourceWave, row)
	WAVE/T refWave, sourceWave
	variable row

	variable i, j, numRows, numCols
	numRows = DimSize(refWave, ROWS)
	numCols = DimSize(refWave, COLS)

	ASSERT(numCOLS == DimSize(sourceWave, COLS), "mismatched column sizes")

	for(i = 0; i < numRows; i += 1)
		for(j = 0; j < numCols; j += 1)
			if(!cmpstr(refWave[i][j], sourceWave[row][j]))
				if(j == numCols - 1)
					return i
				endif

				continue
			endif

			break
		endfor
	endfor

	return NaN
End

/// @brief Returns the column from a multidimensional wave using the dimlabel
Function/WAVE GetColfromWavewithDimLabel(wv, dimLabel)
	WAVE   wv
	string dimLabel

	variable column = FindDimLabel(wv, COLS, dimLabel)
	ASSERT(column != -2, "dimLabel:" + dimLabel + "cannot be found")
	matrixOp/FREE OneDWv = col(wv, column)
	return OneDWv
End

/// @brief Turn a persistent wave into a free wave
Function/WAVE MakeWaveFree(wv)
	WAVE/Z wv

	if(!WaveExists(wv))
		return $""
	endif

	DFREF dfr = NewFreeDataFolder()

	MoveWave wv, dfr

	return wv
End

#if IgorVersion() >= 10

/// @brief Turn a persistent datafolder into a free datafolder
Function/DF MakeDataFolderFree(DFREF dfr)

	if(!DataFolderExistsDFR(dfr))
		return $""
	endif

	DFREF target = NewFreeDataFolder()

	MoveDataFolder dfr, target
	ASSERT(!V_flag, "MoveDataFolder error")

	return dfr
End

#endif

/// @brief Sets the dimension labels of a wave
///
/// @param wv       Wave to add dim labels
/// @param list     List of dimension labels, semicolon separated.
/// @param dim      Wave dimension, see, @ref WaveDimensions
/// @param startPos [optional, defaults to 0] First dimLabel index
threadsafe Function SetDimensionLabels(wv, list, dim, [startPos])
	WAVE     wv
	string   list
	variable dim
	variable startPos

	string   labelName
	variable i
	variable dimlabelCount = ItemsInlist(list)

	if(ParamIsDefault(startPos))
		startPos = 0
	endif

	ASSERT_TS(startPos >= 0, "Illegal negative startPos")
	ASSERT_TS(dimlabelCount <= DimSize(wv, dim) + startPos, "Dimension label count exceeds dimension size")
	for(i = 0; i < dimlabelCount; i += 1)
		labelName = StringFromList(i, list)
		SetDimLabel dim, i + startPos, $labelName, Wv
	endfor
End

/// @brief Return a wave with deep copies of all referenced waves
///
/// The deep copied waves will be free waves.
/// Does not allow invalid wave references in `src`.
///
/// @param src       wave reference wave
/// @param dimension [optional] copy only a single dimension, requires `index` or
///                  `indexWave` as well
/// @param index     [optional] specifies the index into `dimension`, index is not checked
/// @param indexWave [optional] specifies the indizes into `dimension`, allows for
///                  differing indizes per `src` entry, indices are not checked
threadsafe Function/WAVE DeepCopyWaveRefWave(WAVE/WAVE src, [variable dimension, variable index, WAVE indexWave])

	variable i, numEntries

	ASSERT_TS(IsWaveRefWave(src), "Expected wave ref wave")
	ASSERT_TS(DimSize(src, COLS) <= 1, "Expected a 1D wave for src")

	if(!ParamIsDefault(dimension))
		ASSERT_TS(dimension >= ROWS && dimension <= CHUNKS, "Invalid dimension")
		ASSERT_TS(ParamIsDefault(index) + ParamIsDefault(indexWave) == 1, "Need exactly one of parameter of type index or indexWave")
	endif

	if(!ParamIsDefault(indexWave) || !ParamIsDefault(index))
		ASSERT_TS(!ParamIsDefault(dimension), "Missing optional parameter dimension")
	endif

	Duplicate/WAVE/FREE src, dst

	numEntries = DimSize(src, ROWS)

	if(!ParamIsDefault(indexWave))
		ASSERT_TS(IsNumericWave(indexWave), "Expected numeric wave")
		ASSERT_TS(numEntries == numpnts(indexWave), "indexWave and src must have the same number of points")
	endif

	for(i = 0; i < numEntries; i += 1)
		WAVE/Z srcWave = dst[i]
		ASSERT_TS(WaveExists(srcWave), "Missing wave at linear index: " + num2str(i))

		if(!ParamIsDefault(indexWave))
			index = indexWave[i]
		endif

		if(ParamIsDefault(dimension))
			Duplicate/FREE srcWave, dstWave
		else
			switch(dimension)
				case ROWS:
					Duplicate/FREE/R=[index][][][] srcWave, dstWave
					break
				case COLS:
					Duplicate/FREE/R=[][index][][] srcWave, dstWave
					break
				case LAYERS:
					Duplicate/FREE/R=[][][index][] srcWave, dstWave
					break
				case CHUNKS:
					Duplicate/FREE/R=[][][][index] srcWave, dstWave
					break
			endswitch
			ReduceWaveDimensionality(dstWave, minDimension = dimension)
		endif

		dst[i] = dstWave
	endfor

	return dst
End

/// @brief Shrinks a waves dimensionality if higher dimensions have size 1
///
/// @param wv           Wave that should be shrinked
/// @param minDimension [optional, default COLS] shrinks a wave only up to this dimension, e.g. with minDimension = LAYERS
///                     a wave of size (1,1,1,1) is shrinked to (1,1,1,0).
threadsafe Function ReduceWaveDimensionality(WAVE/Z wv, [variable minDimension])

	variable i, shrink

	if(!WaveExists(wv))
		return NaN
	endif

	if(!numpnts(wv))
		return NaN
	endif

	minDimension = ParamIsDefault(minDimension) ? COLS : minDimension
	ASSERT_TS(IsInteger(minDimension) && minDimension >= ROWS && minDimension < MAX_DIMENSION_COUNT, "Invalid minDimension")
	minDimension = limit(minDimension, COLS, MAX_DIMENSION_COUNT - 1)
	WAVE waveSize = GetWaveDimensions(wv)
	for(i = MAX_DIMENSION_COUNT - 1; i >= minDimension; i -= 1)
		if(waveSize[i] == 1)
			waveSize[i] = 0
			shrink      = 1
		elseif(waveSize[i] > 1)
			break
		endif
	endfor
	if(shrink)
		Redimension/N=(waveSize[0], waveSize[1], waveSize[2], waveSize[3]) wv
	endif
End

/// @brief Remove the dimlabels of all dimensions with data
///
/// Due to no better solutions the dim labels are actually overwritten with an empty string
Function RemoveAllDimLabels(wv)
	WAVE/Z wv

	variable dims, i, j, numEntries

	dims = WaveDims(wv)

	for(i = 0; i < dims; i += 1)
		numEntries = DimSize(wv, i)
		for(j = -1; j < numEntries; j += 1)
			SetDimLabel i, j, $"", wv
		endfor
	endfor
End

/// @brief Return the modification count of the (permanent) wave
///
/// Returns NaN when running in a preemptive thread
///
/// UTF_NOINSTRUMENTATION
threadsafe Function WaveModCountWrapper(WAVE wv)

	if(MU_RunningInMainThread())
		ASSERT_TS(!IsFreeWave(wv), "Can not work with free waves")

		return WaveModCount(wv)
	else
		ASSERT_TS(IsFreeWave(wv), "Can only work with free waves")

		return NaN
	endif
End

/// @brief Merge two floating point waves labnotebook waves
///
/// The result will hold the finite row entry of either `wv1` or `wv2`.
Function/WAVE MergeTwoWaves(wv1, wv2)
	WAVE wv1, wv2

	variable numEntries, i, validEntryOne, validEntryTwo

	ASSERT(EqualWaves(wv1, wv2, EQWAVES_DIMSIZE), "Non matching wave dim sizes")
	ASSERT(EqualWaves(wv1, wv2, EQWAVES_DATATYPE), "Non matching wave types")
	ASSERT(IsFloatingPointWave(wv1), "Expected floating point wave")
	ASSERT(DimSize(wv1, COLS) <= 1, "Expected 1D wave")

	Make/FREE/Y=(WaveType(wv1)) result = NaN

	numEntries = DimSize(wv1, ROWS)
	for(i = 0; i < numEntries; i += 1)

		validEntryOne = IsFinite(wv1[i])
		validEntryTwo = IsFinite(wv2[i])

		if(!validEntryOne && !validEntryTwo)
			continue
		elseif(validEntryOne)
			result[i] = wv1[i]
		elseif(validEntryTwo)
			result[i] = wv2[i]
		else
			ASSERT(0, "Both entries can not be valid.")
		endif
	endfor

	return result
End

/// @brief Adapt the wave lock status on the wave and its contained waves
threadsafe Function ChangeWaveLock(wv, val)
	WAVE/WAVE wv
	variable  val

	variable numEntries, i

	val = !!val

	SetWaveLock val, wv

	if(!IsWaveRefWave(wv))
		return NaN
	endif

	ASSERT_TS(DimSize(wv, ROWS) == numpnts(wv), "Expected a 1D wave")
	numEntries = DimSize(wv, ROWS)

	for(i = 0; i < numEntries; i += 1)
		WAVE/Z subWave = wv[i]

		if(WaveExists(subWave))
			ChangeWaveLock(subWave, val)
		endif
	endfor
End

/// @brief Deletes one row, column, layer or chunk from a wave
/// Advantages over DeletePoints:
/// Keeps the dimensionality of the wave when deleting the last row, column, layer or chunk in a wave
/// Implements range check
/// Advantages over DeletePoints + KillWaves:
/// The wave reference stays valid
///
/// @param wv wave where the row, column, layer or chunk should be deleted
///
/// @param dim dimension 0 - rows, 1 - column, 2 - layer, 3 - chunk
///
/// @param index   [optional, default n/a] index where one point in the given dimension is deleted
/// @param indices [optional, default n/a] 1d numerical wave with indices of points to delete
Function DeleteWavePoint(WAVE wv, variable dim, [variable index, WAVE indices])

	variable size

	ASSERT(ParamIsDefault(index) + ParamIsDefault(indices) == 1, "One of index or indices wave must be given as argument")
	ASSERT(WaveExists(wv), "wave does not exist")
	ASSERT(dim >= 0 && dim < 4, "dim must be 0, 1, 2 or 3")
	if(!ParamIsDefault(indices))
		ASSERT(WaveExists(indices), "indices wave is null")
		ASSERT(IsNumericWave(indices), "indices wave must be numeric")
		ASSERT(DimSize(indices, ROWS), "indices wave must have at least one element")
		Sort/R {indices}, indices
		for(index : indices)
			DeleteWavePoint(wv, dim, index = index)
		endfor
		return NaN
	endif
	size = DimSize(wv, dim)
	if(index >= 0 && index < size)
		if(size > 1)
			DeletePoints/M=(dim) index, 1, wv
		else
			switch(dim)
				case 0:
					Redimension/N=(0, -1, -1, -1) wv
					break
				case 1:
					Redimension/N=(-1, 0, -1, -1) wv
					break
				case 2:
					Redimension/N=(-1, -1, 0, -1) wv
					break
				case 3:
					Redimension/N=(-1, -1, -1, 0) wv
					break
			endswitch
		endif
	else
		ASSERT(0, "index out of range")
	endif
End

/// @brief Removes found entry from a text wave
///
/// @param w       text wave
/// @param entry   element content to compare
/// @param options [optional, defaults to "whole wave element"] FindValue/TXOP options
/// @param all     [optional, defaults to false] removes all entries
///
/// @return 0 if at least one entry was found, 1 otherwise
threadsafe Function RemoveTextWaveEntry1D(WAVE/T w, string entry, [variable options, variable all])
	ASSERT_TS(IsTextWave(w), "Input wave must be a text wave")

	variable start, foundOnce

	if(ParamIsDefault(options))
		options = 4
	endif

	if(ParamIsDefault(all))
		all = 0
	else
		all = !!all
	endif

	for(;;)
		if(start >= DimSize(w, ROWS))
			break
		endif

		FindValue/S=(start)/TXOP=(options)/TEXT=entry/RMD=[][0][0][0] w

		if(V_Value >= 0)
			DeletePoints V_Value, 1, w

			if(all)
				start     = V_Value
				foundOnce = 1
				continue
			endif

			return 0
		endif

		break
	endfor

	return foundOnce ? 0 : 1
End

/// @brief Splits a 1d text wave into two waves. The first contains elements with a suffix, the second elements without.
///
/// @param[in] source 1d text wave
/// @param[in] suffix string suffix to distinguish elements
/// @returns two 1d text waves, the first contains all elements with the suffix, the second all elements without
Function [WAVE/T withSuffix, WAVE/T woSuffix] SplitTextWaveBySuffix(WAVE/T source, string suffix)

	variable i, numElems

	if(IsNull(suffix))
		Make/FREE/T woSuffix = {""}
		return [source, woSuffix]
	endif

	Duplicate/FREE/T source, withSuffix, woSuffix

	numElems = DimSize(source, ROWS)
	for(i = numElems - 1; i >= 0; i -= 1)
		if(!StringEndsWith(withSuffix[i], suffix))
			DeletePoints i, 1, withSuffix
		endif
		if(StringEndsWith(woSuffix[i], suffix))
			DeletePoints i, 1, woSuffix
		endif
	endfor

	return [withSuffix, woSuffix]
End

/// @brief Helper function to be able to index waves stored in wave reference
/// waves in wave assignment statements.
///
/// The case where wv contains wave references is also covered by the optional parameters.
/// While returned regular waves can be indexed within the assignment as shown in the first example,
/// this does not work for wave reference waves. Thus, the parameters allow to index through the function call.
///
/// Example for source containing regular waves:
/// \rst
/// .. code-block:: igorpro
///
/// Make/FREE data1 = p
/// Make/FREE data2 = p^2
/// Make/FREE/WAVE source = {data1, data2}
///
/// Make/FREE dest
/// dest[] = WaveRef(source[0])[p] + WaveRef(source[1])[p] // note the direct indexing [p] following WaveRef(...) here
///
/// \endrst
///
/// Example for source containing wave ref waves:
/// \rst
/// .. code-block:: igorpro
///
/// Make/FREE data1 = p
/// Make/FREE/WAVE interm = {data1, data1}
/// Make/FREE/WAVE source = {interm, interm}
///
/// Make/FREE/WAVE/N=2 dest
/// dest[] = WaveRef(source[p], row = 0) // direct indexing does not work here, so we index through the optional function parameter
///
/// \endrst
///
/// row, col, layer, chunk are evaluated in this order until one argument is not given.
///
/// @param w input wave ref wave
/// @param row [optional, default = n/a] when param set returns wv[row] typed
/// @param col [optional, default = n/a] when param row and this set returns wv[row][col] typed
/// @param layer [optional, default = n/a] when param row, col and this set returns wv[row][col][layer] typed
/// @param chunk [optional, default = n/a] when param row, col, layer and this set returns wv[row][layer][chunk] typed
/// @returns untyped waveref of wv or typed wave ref of wv when indexed
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/WAVE WaveRef(WAVE/Z w, [variable row, variable col, variable layer, variable chunk])

	if(!WaveExists(w))
		return $""
	endif

	WAVE/WAVE wv = w

	if(ParamIsDefault(row))
		return wv
	elseif(ParamIsDefault(col))
		return wv[row]
	elseif(ParamIsDefault(layer))
		return wv[row][col]
	elseif(ParamIsDefault(chunk))
		return wv[row][col][layer]
	else
		return wv[row][col][layer][chunk]
	endif
End

/// @brief Compensate IP not having a way to dynamically extract a string from an untyped, i.e. numeric, wave
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/S WaveText(WAVE/Z w, [variable row, variable col, variable layer, variable chunk])

	if(!WaveExists(w))
		return ""
	endif

	WAVE/T wv = w

	if(ParamIsDefault(row))
		ASSERT_TS(0, "Missing row parameter")
	elseif(ParamIsDefault(col))
		return wv[row]
	elseif(ParamIsDefault(layer))
		return wv[row][col]
	elseif(ParamIsDefault(chunk))
		return wv[row][col][layer]
	else
		return wv[row][col][layer][chunk]
	endif
End

/// @brief Helper function for multithread statements where `? :` does not work with wave references
///
/// The order of arguments is modelled after SelectString/SelectNumber.
threadsafe Function/WAVE SelectWave(variable condition, WAVE/Z waveIfFalse, WAVE/Z waveIfTrue)
	if(!!condition != 0)
		return waveIfTrue
	else
		return waveIfFalse
	endif
End

/// @brief Remove unused rows from the passed wave and return a copy of it.
///
/// If the wave is empty with index being zero, we return a wave with one point
/// so that we:
/// - can store something non-empty
/// - preserve the dimension labels (this can get lost for empty waves when duplication/saving)
///
/// @see EnsureLargeEnoughWave()
threadsafe Function/WAVE RemoveUnusedRows(WAVE wv)

	variable index

	index = GetNumberFromWaveNote(wv, NOTE_INDEX)

	if(IsNaN(index))
		return wv
	endif

	ASSERT_TS(IsInteger(index) && index >= 0, "Expected non-negative and integer NOTE_INDEX")

	Duplicate/FREE/RMD=[0, max(0, index - 1)] wv, dup

	return dup
End

/// @brief Duplicates the input wave to a free wave and returns the free wave reference.
threadsafe Function/WAVE DuplicateWaveToFree(WAVE w)

	Duplicate/FREE w, wFree

	return wFree
End

/// @brief Removes all NaNs from the input wave
threadsafe Function/WAVE ZapNaNs(WAVE data)

	ASSERT_TS(IsFloatingPointWave(data), "Can only work with floating point waves")

	if(DimSize(data, ROWS) == 0)
		return $""
	endif

	MatrixOP/FREE dup = zapNans(data)

	if(DimSize(dup, ROWS) == 0)
		return $""
	endif

	return dup
End

/// @brief Give the free wave `wv` the name `name`
threadsafe Function ChangeFreeWaveName(WAVE wv, string name)

	ASSERT_TS(IsFreeWave(wv), "Only works with free waves")
	ASSERT_TS(IsValidObjectName(name), "name is not a valid object name")

	DFREF dfr = NewFreeDataFolder()

	MoveWave wv, dfr:$name
End

Function/WAVE ZapNullRefs(WAVE/WAVE input)

	variable numEntries, i, idx

	ASSERT(IsWaveRefWave(input), "input must be a wave reference wave")

	ASSERT(Dimsize(input, COLS) == 0, "input must be 1D")
	numEntries = Dimsize(input, ROWS)

	if(!numEntries)
		return $""
	endif

	Duplicate/FREE/WAVE input, result

	for(i = 0; i < numEntries; i += 1)
		WAVE/Z wv = input[i]

		if(!WaveExists(wv))
			continue
		endif

		result[idx] = wv
		idx        += 1
	endfor

	if(!idx)
		return $""
	endif

	Redimension/N=(idx) result

	return result
End

/// @brief Split multidimensional waves inside input to the given dimension
///
/// @param input wave reference wave
/// @param sdim  [optional, defaults to 1] dimensionality to split to
Function/WAVE SplitWavesToDimension(WAVE/WAVE input, [variable sdim])

	ASSERT_TS(IsWaveRefWave(input), "Expected a wave reference wave")

	if(ParamIsDefault(sdim))
		sdim = 1
	else
		ASSERT_TS(IsInteger(sdim) && sdim >= 1 && sdim <= MAX_DIMENSION_COUNT, "Invalid sdim parameter")
	endif

	Make/FREE/WAVE/N=(0) output, singleWaves

	for(WAVE/Z wv : input)
		ASSERT_TS(WaveExists(wv), "Invalid contained wv")

		if(DimSize(wv, COLS) > 1)
			/// @todo workaround IP issue 4979 (singleWaves is not a free wave)
			SplitWave/NOTE/O/FREE/OREF=singleWaves/SDIM=(sdim) wv
		else
			Make/WAVE/FREE singleWaves = {wv}
		endif

		Concatenate/NP {singleWaves}, output
	endfor

	return output
End

/// @brief Returns the first row index that is NaN from the floating point wave wv, NaN if no index is NaN
threadsafe Function FindFirstNaNIndex(WAVE wv)

	ASSERT_TS(IsFloatingPointWave(wv), "input wave must be floating point")

	FindValue/FNAN wv
	if(V_row < 0)
		return NaN
	endif

	return V_row
End

/// @brief Sets the DimLabels for elements of a 1d numerical or text wave based on the content of the wave
///        For numerical waves the wave element is treated as integer
///        For textual waves the elements must translate to a valid DimLabel.
///
/// @param wv input wave
/// @param prefix [optional: default "" for numerical waves and NUM_ for textual waves] prefix of the dimlabel
///               For numerical waves it is recommended to provide an own prefix.
/// @param suffix [optional: default ""] suffix of the dimlabel
/// @param strict [optional: default 0] When this flag is set then each constructed DimLabels for text wave elements are checked
///               if it results in a valid DimLabel, it is also checked if duplicate Dimlabels would be created.
threadsafe Function SetDimensionLabelsFromWaveContents(WAVE wv, [string prefix, string suffix, variable strict])

	variable idx, num
	string str

	ASSERT_TS(IsTextWave(wv) || IsNumericWave(wv), "Wave must be text or numeric")
	if(!DimSize(wv, ROWS))
		return NaN
	endif
	ASSERT_TS(!DimSize(wv, COLS), "Wave must be 1d")

	if(ParamIsDefault(prefix))
		prefix = SelectString(IsTextWave(wv), "NUM_", "")
	else
		ASSERT_TS(IsValidObjectName(prefix), "Prefix " + prefix + " must be a valid object name")
	endif
	str = SelectString(IsTextWave(wv), "0", "A")
	if(ParamIsDefault(suffix))
		suffix = ""
	endif
	ASSERT_TS(IsValidObjectName(prefix + str + suffix), "The combination of Prefix " + prefix + " and Suffix " + suffix + " must be a valid object name")

	strict = ParamIsDefault(strict) ? 0 : !!strict

	if(IsTextWave(wv))
		WAVE/T wt = wv
		if(strict)
			FindDuplicates/FREE/DT=textDups wv
			ASSERT_TS(!DimSize(textDups, ROWS), "Input would result in duplicate DimLabels")
			for(str : wt)
				str = prefix + str + suffix
				ASSERT_TS(IsValidObjectName(str), "Element at " + num2istr(idx) + " results in ivnalid DimLabel " + str)
				SetDimLabel ROWS, idx++, $str, wv
			endfor
		else
			for(str : wt)
				str = prefix + str + suffix
				SetDimLabel ROWS, idx++, $str, wv
			endfor
		endif

		return NaN
	endif

	if(strict)
		Make/FREE/T/N=(DimSize(wv, ROWS)) labels
		for(num : wv)
			sprintf str, "%s%d%s", prefix, num, suffix
			labels[idx++] = str
		endfor
		FindDuplicates/FREE/DT=textDups labels
		ASSERT_TS(!DimSize(textDups, ROWS), "Input would result in duplicate DimLabels")
		idx = 0
	endif

	for(num : wv)
		sprintf str, "%s%d%s", prefix, num, suffix
		SetDimLabel ROWS, idx++, $str, wv
	endfor
End

/// @brief Converts a free wave to a permanent wave with Overwrite
/// @param[in] freeWave wave that should be converted to a permanent wave
/// @param[in] dfr data folder where permanent wave is stored
/// @param[in] wName name of permanent wave that is created
/// @returns wave reference to the permanent wave
Function/WAVE ConvertFreeWaveToPermanent(WAVE freeWave, DFREF dfr, string wName)

	Duplicate/O freeWave, dfr:$wName/WAVE=permWave
	return permWave
End

Function/WAVE MoveFreeWaveToPermanent(WAVE freeWave, DFREF dfr, string wvName)

	wvName = UniqueWaveName(dfr, wvName)
	MoveWave freeWave, dfr:$wvName
	WAVE/SDFR=dfr permWave = $wvName

	return permWave
End

/// @brief Duplicate a source wave to a target wave and keep the target wave reference intact. Use with free/local waves.
///        For global waves use "Duplicate/O source, target".
///
/// @param source source wave
/// @param target target wave
Function DuplicateWaveAndKeepTargetRef(WAVE/Z source, WAVE/Z target)

	variable wTypeSrc, wTypeTgt

	wTypeSrc = WaveType(source, 1)
	wTypeTgt = WaveType(target, 1)
	ASSERT(wTypeSrc != IGOR_TYPE_NULL_WAVE, "Source wave is null")
	ASSERT(wTypeTgt != IGOR_TYPE_NULL_WAVE, "Target wave is null")
	if(WaveRefsEqual(source, target))
		return NaN
	endif
	ASSERT(wTypeTgt == wTypeSrc, "Source and Target wave have different base types")

	switch(WaveDims(source))
		case 0: // intended drop through
		case 1:
			Redimension/N=(DimSize(source, ROWS)) target
			break
		case 2:
			Redimension/N=(DimSize(source, ROWS), DimSize(source, COLS)) target
			break
		case 3:
			Redimension/N=(DimSize(source, ROWS), DimSize(source, COLS), DimSize(source, LAYERS)) target
			break
		case 4:
			Redimension/N=(DimSize(source, ROWS), DimSize(source, COLS), DimSize(source, LAYERS), DimSize(source, CHUNKS)) target
			break
	endswitch

	switch(wTypeSrc)
		case IGOR_TYPE_TEXT_WAVE:
			WAVE/T sourceT = source
			WAVE/T targetT = target
			Multithread targetT[][][][] = sourceT[p][q][r][s]
			break
		case IGOR_TYPE_NUMERIC_WAVE:
			Multithread target[][][][] = source[p][q][r][s]
			break
		case IGOR_TYPE_DFREF_WAVE:
			WAVE/DF sourceDF = source
			WAVE/DF targetDF = target
			Multithread targetDF[][][][] = sourceDF[p][q][r][s]
			break
		case IGOR_TYPE_WAVEREF_WAVE:
			WAVE/WAVE sourceW = source
			WAVE/WAVE targetW = target
			Multithread targetW[][][][] = sourceW[p][q][r][s]
			break
		default:
			ASSERT(0, "Unknown wave type")
	endswitch

	CopyScales source, target
	CopyDimLabels source, target
	note/K target, note(source)
End

/// @brief Detects duplicate values in a 1d wave.
///
/// @return one if duplicates could be found, zero otherwise
Function SearchForDuplicates(wv)
	WAVE wv

	ASSERT(WaveExists(wv), "Missing wave")

	FindDuplicates/FREE/Z/INDX=idx wv

	return WaveExists(idx) && DimSize(idx, ROWS) > 0
End

/// @brief Return the indizes of elements which need to be dropped so that no two neighbouring points are equal/both NaN
Function/WAVE FindNeighbourDuplicates(WAVE wv)

	variable numPoints, i, numDuplicates, idx

	numPoints = DimSize(wv, ROWS)
	ASSERT_TS(numPoints == numpnts(wv), "Wave must be 1D")

	if(numPoints < 2)
		return $""
	endif

	Make/FREE/D/N=(numPoints) indizes

	FastOp indizes = (NaN)

	for(i = 1; i < numPoints; i += 1)
		if(EqualValuesOrBothNaN(wv[i - 1], wv[i]))
			indizes[idx++] = i
		endif
	endfor

	if(idx == 0)
		return $""
	endif

	WAVE indizesClean = ZapNaNs(indizes)

	return indizesClean
End

/// @brief Move the source wave to the location of the given destination wave.
///        The destination wave must be a permanent wave.
///
///        Workaround for `MoveWave` having no `/O` flag.
///
/// @param dest permanent wave
/// @param src  wave (free or permanent)
/// @param recursive [optional, defaults to false] Overwrite referenced waves
///                                                in dest with the ones from src
///                                                (wave reference waves only with matching sizes)
///
/// @return new wave reference to dest wave
Function/WAVE MoveWaveWithOverwrite(dest, src, [recursive])
	WAVE dest, src
	variable recursive

	string   path
	variable numEntries

	recursive = ParamIsDefault(recursive) ? 0 : !!recursive

	ASSERT(!WaveRefsEqual(dest, src), "dest and src must be distinct waves")
	ASSERT(!IsFreeWave(dest), "dest must be a global/permanent wave")

	if(IsWaveRefWave(dest) && IsWaveRefWave(src) && recursive)
		numEntries = numpnts(dest)
		ASSERT(numEntries == numpnts(src), "Unmatched sizes")
		Make/N=(numEntries)/FREE/WAVE entries

		WAVE/WAVE destWaveRef = dest
		WAVE/WAVE srcWaveRef  = src

		entries[] = MoveWaveWithOverWrite(destWaveRef[p], srcWaveRef[p], recursive = 1)
	endif

	path = GetWavesDataFolder(dest, 2)

	KillOrMoveToTrash(wv = dest)
	MoveWave src, $path

	WAVE dest = $path

	return dest
End

/// @brief Zero the wave using differentiation and integration
///
/// Overwrites the input wave
/// Preserves the WaveNote and adds the entry NOTE_KEY_ZEROED
///
/// 2D waves are zeroed along each row
///
/// @return 0 if nothing was done, 1 if zeroed
threadsafe Function ZeroWave(wv)
	WAVE wv

	if(GetNumberFromWaveNote(wv, NOTE_KEY_ZEROED) == 1)
		return 0
	endif

	ZeroWaveImpl(wv)

	SetNumberInWaveNote(wv, NOTE_KEY_ZEROED, 1)

	return 1
End

/// @brief Zeroes a wave in place
threadsafe Function ZeroWaveImpl(WAVE wv)

	variable numRows, offset

	numRows = DimSize(wv, ROWS)

	if(numRows == 0)
		return NaN
	endif

	ASSERT_TS(IsFloatingPointWave(wv), "Can only work with floating point waves")

	offset = wv[0]
	Multithread wv = wv - offset
End

/// @brief Return the size of the decimated wave
///
/// Query that to create the output wave before calling DecimateWithMethod().
///
/// @param numRows 			number of rows in the input wave
/// @param decimationFactor decimation factor, must be an integer and larger than 1
/// @param method      	    one of @ref DecimationMethods
Function GetDecimatedWaveSize(numRows, decimationFactor, method)
	variable numRows, decimationFactor, method

	variable decimatedSize

	ASSERT(IsInteger(decimationFactor) && decimationFactor > 1, "decimationFactor must be an integer and larger as 1.")

	switch(method)
		case DECIMATION_NONE:
			return numRows
		case DECIMATION_MINMAX:
			decimatedSize = ceil(numRows / decimationFactor)
			// make it even
			decimatedSize = IsEven(decimatedSize) ? decimatedSize : ++decimatedSize
			return decimatedSize
		default:
			ASSERT(0, "Invalid method")
			break
	endswitch
End

/// @brief Searches the column colLabel in wv for an non-empty
/// entry with a row number smaller or equal to endRow
///
/// Return an empty string if nothing could be found.
///
/// @param wv         text wave to search in
/// @param colLabel   column label from wv
/// @param endRow     maximum row index to consider
Function/S GetLastNonEmptyEntry(wv, colLabel, endRow)
	WAVE/T   wv
	string   colLabel
	variable endRow

	WAVE/Z indizes = FindIndizes(wv, colLabel = colLabel, prop = PROP_EMPTY | PROP_NOT, endRow = endRow)

	if(!WaveExists(indizes))
		return ""
	endif

	return wv[indizes[DimSize(indizes, ROWS) - 1]][%$colLabel]
End
