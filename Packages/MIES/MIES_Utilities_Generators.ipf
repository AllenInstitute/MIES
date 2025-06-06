#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_UTILS_GENERATORS
#endif // AUTOMATED_TESTING

/// @file MIES_Utilities_Generators.ipf
/// @brief utility functions that generate code

Function GenerateMultiplierConstants()

	variable numElements, i, j, maxLength
	string str

	WAVE/T prefixes = ListToTextWave(PREFIX_LONG_LIST, ";")
	WAVE/D values   = ListToNumericWave(PREFIX_VALUE_LIST, ";")

	numElements = DimSize(prefixes, ROWS)
	ASSERT(DimSize(values, ROWS) == numElements, "Non matching list sizes")

	Make/FREE/N=(numElements) lengths = strlen(prefixes[p])
	maxLength = WaveMax(lengths)

	for(i = 0; i < numElements; i += 1)
		for(j = 0; j < numElements; j += 1)
			if(i == j)
				continue
			endif

			sprintf str, "Constant %*s_TO_%-*s = %.0e", maxLength, UpperStr(prefixes[i]), maxLength, UpperStr(prefixes[j]), (values[i] / values[j])
			print str
		endfor
	endfor
End
