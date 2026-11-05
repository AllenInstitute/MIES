#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_UTILS_GENERATORS
#endif // AUTOMATED_TESTING

/// @file MIES_Utilities_Generators.ipf
/// @brief utility functions that generate code

/// @brief Print the constants for converting between the decimal (SI) prefixes, see MIES_ConversionConstants.ipf
Function GenerateMultiplierConstants()

	GenerateMultiplierConstantsImpl(PREFIX_LONG_LIST, PREFIX_VALUE_LIST, "%.0e")
End

/// @brief Print the constants for converting between the binary prefixes, see MIES_ConversionConstants.ipf
Function GenerateBinaryMultiplierConstants()

	// powers of two need all digits
	GenerateMultiplierConstantsImpl(PREFIX_BINARY_LONG_LIST, PREFIX_BINARY_VALUE_LIST, "%.17g")
End

static Function GenerateMultiplierConstantsImpl(string prefixList, string valueList, string valueFormat)

	variable numElements, i, j, maxLength
	string str, format

	WAVE/T prefixes = ListToTextWave(prefixList, ";")
	WAVE/D values   = ListToNumericWave(valueList, ";")

	format = "Constant %*s_TO_%-*s = " + valueFormat

	numElements = DimSize(prefixes, ROWS)
	ASSERT(DimSize(values, ROWS) == numElements, "Non matching list sizes")

	Make/FREE/N=(numElements) lengths = strlen(prefixes[p])
	maxLength = WaveMax(lengths)

	for(i = 0; i < numElements; i += 1)
		for(j = 0; j < numElements; j += 1)
			if(i == j)
				continue
			endif

			sprintf str, format, maxLength, UpperStr(prefixes[i]), maxLength, UpperStr(prefixes[j]), (values[i] / values[j])
			print str
		endfor
	endfor
End
