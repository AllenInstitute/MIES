#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_Labnotebook
#endif

/// @brief Set column dimension labels from the first row of the key wave
Function LBN_SetDimensionLabels(WAVE/T keys, WAVE values, [variable start])

	variable i, numCols
	string text

	numCols = DimSize(values, COLS)

	if(ParamIsDefault(start))
		start = 0
	else
		ASSERT(start < numCols && IsInteger(start), "start is too large or not an integer")
	endif

	ASSERT(DimSize(keys, COLS) == numCols, "Mismatched column sizes")
	ASSERT(DimSize(keys, ROWS) > 0, "Expected at least one row in the key wave")

	for(i = start; i < numCols; i += 1)
		text = keys[0][i]
		text = text[0, MAX_OBJECT_NAME_LENGTH_IN_BYTES - 1]
		ASSERT(!isEmpty(text), "Empty key")
		SetDimLabel COLS, i, $text, keys, values
	endfor
End

/// @brief Queries the unit and column from the key wave
///
/// @param keyWave labnotebook key wave
/// @param key     key to look for
///
/// @retval result one on error, zero otherwise
/// @retval unit   unit of the result [empty if not found]
/// @retval col    column of the result into the keyWave [NaN if not found]
threadsafe Function [variable result, string unit, variable col] LBN_GetEntryProperties(WAVE/Z/T keyWave, string key)

	variable row

	unit   = ""
	col    = NaN
	result = NaN

	if(!WaveExists(keyWave))
		return [1, unit, col]
	endif

	row = FindDimLabel(keyWave, ROWS, "Parameter")
	FindValue/TXOP=4/TEXT=key/RMD=[row] keyWave

	if(!(V_col >= 0))
		return [1, unit, col]
	endif

	col  = V_col
	unit = keyWave[%Units][col]

	return [0, unit, col]
End

/// @brief Return a wave suitable for consumption by #ED_AddEntryToLabnotebook()
threadsafe Function/WAVE LBN_GetNumericWave([variable defValue])

	if(ParamIsDefault(defValue))
		defValue = NaN
	endif

	MAKE/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) data = defValue

	return data
End

/// @brief Return a wave suitable for consumption by #ED_AddEntryToLabnotebook()
threadsafe Function/WAVE LBN_GetTextWave([string defValue])

	if(ParamIsDefault(defValue))
		MAKE/FREE/T/N=(LABNOTEBOOK_LAYER_COUNT) data
	else
		MAKE/FREE/T/N=(LABNOTEBOOK_LAYER_COUNT) data = defValue
	endif

	return data
End

/// @brief Return all labnotebook entries which are at least written once
threadsafe Function/WAVE LBV_GetFilledLabnotebookEntries(WAVE/Z values)

	if(!WaveExists(values))
		return $""
	endif

	Make/FREE/N=(DimSize(values, COLS))/T keys

	Multithread keys[] = LBV_IsLabnotebookColumnFilled(values, p)

	RemoveTextWaveEntry1D(keys, "", all = 1)

	if(DimSize(keys, ROWS) == 0)
		return $""
	endif

	return keys
End

/// @brief Return the name of the given labnotebook column if it was written into
/// at least once, an empty string otherwise
threadsafe static Function/S LBV_IsLabnotebookColumnFilled(WAVE values, variable col)

	WAVE/Z indizes = FindIndizes(values, col = col, prop = PROP_EMPTY | PROP_NOT, startLayer = 0, endLayer = LABNOTEBOOK_LAYER_COUNT - 1)

	if(WaveExists(indizes))
		return GetDimLabel(values, COLS, col)
	endif

	return ""
End
