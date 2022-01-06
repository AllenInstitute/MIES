#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_Labnotebook
#endif

/// @brief Set column dimension labels from the first row of the key wave
Function LBN_SetDimensionLabels(keys, values)
	Wave/T keys
	Wave values

	variable i, numCols
	string text

	numCols = DimSize(values, COLS)
	ASSERT(DimSize(keys, COLS) == numCols, "Mismatched column sizes")
	ASSERT(DimSize(keys, ROWS) > 0 , "Expected at least one row in the key wave")

	for(i = 0; i < numCols; i += 1)
		text = keys[0][i]
		text = text[0,MAX_OBJECT_NAME_LENGTH_IN_BYTES - 1]
		ASSERT(!isEmpty(text), "Empty key")
		SetDimLabel COLS, i, $text, keys, values
	endfor
End
