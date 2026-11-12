#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_MIES_ALGORITHM

// Missing Tests for:
// CalculateAverage
// CalculateTPLikePropsFromSweep

/// DecimateWithMethod
/// @{

Function TestDecimateWithMethodInvalid()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 2
	method           = DECIMATION_MINMAX
	Make/FREE/N=(DimSize(data, ROWS) / 2) output

	try
		DecimateWithMethod(data, output, 1, method)
		FAIL()
	catch
		PASS()
	endtry

	try
		DecimateWithMethod(data, $"", decimationFactor, method); AbortOnRTE
		FAIL()
	catch
		CHECK_RTE(2)
	endtry

	try
		DecimateWithMethod($"", output, decimationFactor, method); AbortOnRTE
		FAIL()
	catch
		CHECK_RTE(2)
	endtry

	try
		DecimateWithMethod(data, output, 0, method)
		FAIL()
	catch
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, Inf, method)
		FAIL()
	catch
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, -5)
		FAIL()
	catch
		PASS()
	endtry

	try
		Duplicate/FREE output, outputWrong
		Redimension/N=(5) outputWrong
		DecimateWithMethod(data, outputWrong, decimationFactor, method)
		FAIL()
	catch
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, firstRowInp = -1)
		FAIL()
	catch
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, firstRowInp = 100)
		FAIL()
	catch
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastRowInp = -1)
		FAIL()
	catch
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastRowInp = 100)
		FAIL()
	catch
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastRowInp = -1)
		FAIL()
	catch
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastRowInp = 100)
		FAIL()
	catch
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, firstColInp = -1)
		FAIL()
	catch
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, firstColInp = 100)
		FAIL()
	catch
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastColInp = -1)
		FAIL()
	catch
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastColInp = 100)
		FAIL()
	catch
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, factor = $"")
		FAIL()
	catch
		PASS()
	endtry

	try
		Make/N=(100)/FREE factor
		DecimateWithMethod(data, output, decimationFactor, method, factor = factor)
		FAIL()
	catch
		PASS()
	endtry
End

Function TestDecimateWithMethodDec1()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 8
	method           = DECIMATION_MINMAX
	newSize          = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 2)
	Make/FREE/D/N=(newSize) output

	Make/FREE refOutput = {10, 800}
	Make/N=(1)/FREE factor = {100}

	DecimateWithMethod(data, output, decimationFactor, method, firstRowInp = 1, lastRowInp = 15, firstColInp = 0, lastColInp = 0, factor = factor)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

Function TestDecimateWithMethodDec2()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 2
	method           = DECIMATION_MINMAX
	newSize          = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 8)
	Make/FREE/D/N=(newSize) output
	Make/D/FREE refOutput = {0.1, 2, 0.3, 4, 0.5, 6, 0.7, 8}

	DecimateWithMethod(data, output, decimationFactor, method)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

Function TestDecimateWithMethodDec3()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 4
	method           = DECIMATION_MINMAX
	newSize          = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 4)
	Make/FREE/D/N=(newSize) output
	Make/D/FREE refOutput = {0.1, 4, 0.5, 8}

	DecimateWithMethod(data, output, decimationFactor, method)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

// decimation does not give a nice new size but it still works
Function TestDecimateWithMethodDec4()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 3
	method           = DECIMATION_MINMAX
	newSize          = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 6)
	Make/FREE/D/N=(newSize) output
	Make/D/FREE refOutput = {0.1, 3, 0.4, 6, 0.7, 8}

	DecimateWithMethod(data, output, decimationFactor, method)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

// decimation so large that only two points remain
Function TestDecimateWithMethodDec5()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 1000
	method           = DECIMATION_MINMAX
	newSize          = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 2)
	Make/FREE/D/N=(newSize) output
	Make/D/FREE refOutput = {0.1, 8}

	DecimateWithMethod(data, output, decimationFactor, method)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

// respects columns
Function TestDecimateWithMethodDec6()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 4
	method           = DECIMATION_MINMAX
	newSize          = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 4)
	Make/D/FREE/N=(newSize, 2) output
	Make/D/FREE refOutput = {{0, 0, 0, 0}, {0.1, 4, 0.5, 8}}

	DecimateWithMethod(data, output, decimationFactor, method, firstColInp = 1)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

// respects factor and has different output column
Function TestDecimateWithMethodDec7()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 4
	method           = DECIMATION_MINMAX
	newSize          = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 4)
	Make/D/N=(newSize, 2)/FREE output = {{-10, -400, -50, -800}, {2, 2, 2, 2}}
	// factor leaves first column untouched
	Make/D/FREE refOutput = {{-10, -400, -50, -800}, {2, 2, 2, 2}}
	Make/N=(1)/FREE factor = {-100}

	DecimateWithMethod(data, output, decimationFactor, method, factor = factor, firstColInp = 1, firstColOut = 0, lastColOut = 0)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

// works with doing it in chunks
Function TestDecimateWithMethodDec8()

	variable newSize, numRows, decimationFactor, method, i

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 4
	method           = DECIMATION_MINMAX
	newSize          = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 4)
	Make/FREE/D/N=(newSize) output
	Make/D/FREE refOutput = {0.1, 4, 0.5, 8}

	Make/FREE chunks = {{0, 2}, {3, 8}, {9, 15}}

	for(i = 0; i < DimSize(chunks, COLS); i += 1)
		DecimateWithMethod(data, output, decimationFactor, method, firstRowInp = chunks[0][i], lastRowInp = chunks[1][i])
		switch(i)
			case 0:
				CHECK_EQUAL_WAVES(output, {0.1, 1, 0, 0}, mode = WAVE_DATA, tol = 1e-10)
				break
			case 1:
				CHECK_EQUAL_WAVES(output, {0.1, 4, 0.5, 0.5}, mode = WAVE_DATA, tol = 1e-10)
				break
			case 2:
				CHECK_EQUAL_WAVES(output, {0.1, 4, 0.5, 8}, mode = WAVE_DATA, tol = 1e-10)
				break
			default:
				FAIL()
		endswitch
	endfor

	CHECK_EQUAL_VAR(i, DimSize(chunks, COLS))
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

/// @}

/// FindIndizes
/// @{

static Function FI_NumSearchWithCol1()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, var = 1)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithCol1Inverted()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, var = 1, prop = PROP_NOT)
	CHECK_EQUAL_WAVES(indizes, {3, 4}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithColAndLayer1()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, var = 1, startLayer = 0, endLayer = 1)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2, 3, 4}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithColAndLayer2()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, var = 1, startLayer = 1, endLayer = 1)
	CHECK_EQUAL_WAVES(indizes, {3, 4}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithCol2()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, str = "2")
	CHECK_EQUAL_WAVES(indizes, {1, 2}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithCol3()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 2, var = 4711)
	CHECK_WAVE(indizes, NULL_WAVE)
End

static Function FI_NumSearchWithColLabel()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, colLabel = "abcd", var = 1)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithColAndStr()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, colLabel = "abcd", str = "1")
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithColAndProp1()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, colLabel = "abcd", prop = PROP_EMPTY | PROP_NOT)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithColAndProp2()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, colLabel = "abcd", prop = PROP_EMPTY)
	CHECK_EQUAL_WAVES(indizes, {3, 4}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithColAndProp3()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, var = 2, prop = PROP_MATCHES_VAR_BIT_MASK)
	CHECK_EQUAL_WAVES(indizes, {1, 2, 3, 4}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithColAndProp4()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, var = 2, prop = PROP_MATCHES_VAR_BIT_MASK | PROP_NOT)
	CHECK_EQUAL_WAVES(indizes, {0}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithColAndProp5()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, str = "6+", prop = PROP_GREP)
	CHECK_EQUAL_WAVES(indizes, {3}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithColAndProp5Inverted()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, str = "6+", prop = PROP_GREP | PROP_NOT)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2, 4}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithColAndProp6()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, str = "6*", prop = PROP_WILDCARD)
	CHECK_EQUAL_WAVES(indizes, {3}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithColAndProp6Inverted()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, str = "6*", prop = PROP_WILDCARD | PROP_NOT)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2, 4}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithColAndProp6a()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, str = "!*2.00000", prop = PROP_WILDCARD)
	CHECK_EQUAL_WAVES(indizes, {0, 3, 4}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithRestRows()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, var = 2, startRow = 2, endRow = 3)
	CHECK_EQUAL_WAVES(indizes, {2}, mode = WAVE_DATA)
End

static Function FI_TextSearchWithCol1()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, str = "text123")
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

static Function FI_TextSearchWithColAndLayer1()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, str = "text123", startLayer = 0, endLayer = 1)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2, 3, 4}, mode = WAVE_DATA)
End

static Function FI_TextSearchWithColAndLayer2()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, str = "text123", startLayer = 1, endLayer = 1)
	CHECK_EQUAL_WAVES(indizes, {3, 4}, mode = WAVE_DATA)
End

static Function FI_TextSearchWithCol2()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "2")
	CHECK_EQUAL_WAVES(indizes, {1, 2}, mode = WAVE_DATA)
End

static Function FI_TextSearchWithCol3()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 2, str = "4711")
	CHECK_WAVE(indizes, NULL_WAVE)
End

static Function FI_TextSearchWithColLabel()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, colLabel = "efgh", str = "text123")
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

static Function FI_TextSearchWithColAndVar()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, var = 2)
	CHECK_EQUAL_WAVES(indizes, {1, 2}, mode = WAVE_DATA)
End

static Function FI_TextSearchWithVarAndNot()

	Make/FREE/T text = {"1", "2", "1"}

	WAVE/Z indizes = FindIndizes(text, var = 1, prop = PROP_NOT)
	CHECK_NO_RTE()
	CHECK_EQUAL_WAVES(indizes, {1}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithStrAndNot()

	Make/FREE/D numeric = {1, 2, 0}

	WAVE/Z indizes = FindIndizes(numeric, str = "1", prop = PROP_NOT)
	CHECK_EQUAL_WAVES(indizes, {1, 2}, mode = WAVE_DATA)
End

static Function FI_TextSearchBitMaskIgnoresNonNumbers()

	Make/FREE/T text = {"1", "abc", "3", ""}

	WAVE/Z indizes = FindIndizes(text, var = 1, prop = PROP_MATCHES_VAR_BIT_MASK)
	CHECK_NO_RTE()
	CHECK_EQUAL_WAVES(indizes, {0, 2}, mode = WAVE_DATA)
End

static Function FI_TextSearchIgnoresCase()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, colLabel = "efgh", str = "TEXT123")
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

static Function FI_TextSearchWithColAndProp1()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, colLabel = "efgh", prop = PROP_EMPTY | PROP_NOT)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

static Function FI_TextSearchWithColAndProp2()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, colLabel = "efgh", prop = PROP_EMPTY)
	CHECK_EQUAL_WAVES(indizes, {3, 4}, mode = WAVE_DATA)
End

static Function FI_TextSearchWithColAndProp3()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "2", prop = PROP_MATCHES_VAR_BIT_MASK)
	CHECK_EQUAL_WAVES(indizes, {1, 2, 3, 4}, mode = WAVE_DATA)
End

static Function FI_TextSearchWithColAndProp4()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "2", prop = PROP_MATCHES_VAR_BIT_MASK | PROP_NOT)
	CHECK_EQUAL_WAVES(indizes, {0}, mode = WAVE_DATA)
End

static Function FI_TextSearchWithColAndProp5()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "^1.*$", prop = PROP_GREP, startLayer = 1, endLayer = 1)
	CHECK_EQUAL_WAVES(indizes, {0, 3, 4}, mode = WAVE_DATA)
End

static Function FI_TextSearchWithColAndProp6()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "1*", prop = PROP_WILDCARD, startLayer = 1, endLayer = 1)
	CHECK_EQUAL_WAVES(indizes, {0, 3, 4}, mode = WAVE_DATA)
End

static Function FI_TextSearchWithRestRows()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "2", startRow = 2, endRow = 3)
	CHECK_EQUAL_WAVES(indizes, {2}, mode = WAVE_DATA)
End

static Function FI_EmptyWave()

	Make/FREE/N=0 emptyWave
	WAVE/Z indizes = FindIndizes(emptyWave, var = NaN)
	CHECK_WAVE(indizes, NULL_WAVE)
End

static Function FI_AbortsWithInvalidParams1()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric)
		FAIL()
	catch
		PASS()
	endtry
End

static Function FI_AbortsWithInvalidParams2()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, var = 1, str = "123")
		FAIL()
	catch
		PASS()
	endtry
End

static Function FI_AbortsWithInvalidParams3()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, prop = 4711)
		FAIL()
	catch
		PASS()
	endtry
End

static Function FI_AbortsWithInvalidParams4()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, col = 0, colLabel = "dup")
		FAIL()
	catch
		PASS()
	endtry
End

static Function FI_AbortsWithInvalidParams5()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, var = 0, startRow = 100)
		FAIL()
	catch
		PASS()
	endtry
End

static Function FI_AbortsWithInvalidParams6()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, var = 0, endRow = 100)
		FAIL()
	catch
		PASS()
	endtry
End

static Function FI_AbortsWithInvalidParams7()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, var = 0, startRow = 3, endRow = 2)
		FAIL()
	catch
		PASS()
	endtry
End

static Function FI_AbortsWithInvalidParams8()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, var = NaN)
		FAIL()
	catch
		PASS()
	endtry
End

static Function FI_AbortsWithInvalidParams9()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, str = "NaN")
		FAIL()
	catch
		PASS()
	endtry
End

static Function FI_AbortsWithInvalidParams10()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, var = 1, startLayer = 1)
		FAIL()
	catch
		PASS()
	endtry
End

static Function FI_AbortsWithInvalidParams11()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, var = 1, startLayer = 100, endLayer = 100)
		FAIL()
	catch
		PASS()
	endtry
End

static Function FI_AbortsWithInvalidParams12()

	Make/FREE/N=(1, 2, 3, 4) data
	try
		WAVE/Z indizes = FindIndizes(data, var = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function FI_AbortsWithInvalidParams13()

	Make/FREE data
	try
		WAVE/Z indizes = FindIndizes(data, prop = PROP_NOT)
		FAIL()
	catch
		PASS()
	endtry
End

static Function FI_AbortsWithInvalidParams14()

	Make/FREE data
	try
		WAVE/Z indizes = FindIndizes(data, var = 0, prop = PROP_EMPTY)
		FAIL()
	catch
		PASS()
	endtry

	try
		WAVE/Z indizes = FindIndizes(data, str = "", prop = PROP_EMPTY)
		FAIL()
	catch
		PASS()
	endtry
End

static Function FI_AbortsWithInvalidWave()

	try
		FindIndizes($"", var = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function FI_AbortsWithInvalidRegExp()

	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		FindIndizes(numeric, str = "*", prop = PROP_GREP)
		FAIL()
	catch
		PASS()
	endtry
End

/// UTF_TD_GENERATOR DataGenerators#FindIndizesStringProps
static Function FI_TextSearchMultiThreaded([variable var])

	variable numRows, invert
	string str

	numRows = 100000
	CHECK_GT_VAR(GetNumberOfUsefulThreads({numRows}), 1)

	invert = !!(var & PROP_NOT)
	if(var & PROP_GREP)
		str = "3$"
	elseif(var & PROP_WILDCARD)
		str = "*3"
	else
		str = "abc3"
	endif

	Make/FREE/T/N=(numRows, 2, 2) text = "abc" + num2istr(mod(p + r, 7))

	if(var)
		WAVE/Z indizes       = FindIndizes(text, str = str, prop = var)
		WAVE/Z indizesLayers = FindIndizes(text, str = str, prop = var, startRow = 10, endLayer = 1)
	else
		WAVE/Z indizes       = FindIndizes(text, str = str)
		WAVE/Z indizesLayers = FindIndizes(text, str = str, startRow = 10, endLayer = 1)
	endif

	Make/FREE/D/N=(numRows) ref = ((mod(p, 7) == 3) != invert) ? p : NaN
	WaveTransform/O zapNaNs, ref
	CHECK_EQUAL_WAVES(indizes, ref, mode = WAVE_DATA)

	Make/FREE/D/N=(numRows) refLayers = (p >= 10 && (((mod(p, 7) == 3) != invert) || ((mod(p + 1, 7) == 3) != invert))) ? p : NaN
	WaveTransform/O zapNaNs, refLayers
	CHECK_EQUAL_WAVES(indizesLayers, refLayers, mode = WAVE_DATA)
End

/// UTF_TD_GENERATOR DataGenerators#FindIndizesStringProps
static Function FI_NumSearchMultiThreaded([variable var])

	variable numRows, invert
	string str

	numRows = 100000
	CHECK_GT_VAR(GetNumberOfUsefulThreads({numRows}), 1)

	invert = !!(var & PROP_NOT)
	if(var & PROP_GREP)
		str = "^3\\."
	elseif(var & PROP_WILDCARD)
		str = "3.*"
	else
		str = "3"
	endif

	Make/FREE/D/N=(numRows, 2, 2) numeric = mod(p + r, 7)

	if(var)
		WAVE/Z indizes       = FindIndizes(numeric, str = str, prop = var)
		WAVE/Z indizesLayers = FindIndizes(numeric, str = str, prop = var, startRow = 10, endLayer = 1)
	else
		WAVE/Z indizes       = FindIndizes(numeric, str = str)
		WAVE/Z indizesLayers = FindIndizes(numeric, str = str, startRow = 10, endLayer = 1)
	endif

	Make/FREE/D/N=(numRows) ref = ((mod(p, 7) == 3) != invert) ? p : NaN
	WaveTransform/O zapNaNs, ref
	CHECK_EQUAL_WAVES(indizes, ref, mode = WAVE_DATA)

	Make/FREE/D/N=(numRows) refLayers = (p >= 10 && (((mod(p, 7) == 3) != invert) || ((mod(p + 1, 7) == 3) != invert))) ? p : NaN
	WaveTransform/O zapNaNs, refLayers
	CHECK_EQUAL_WAVES(indizesLayers, refLayers, mode = WAVE_DATA)
End

static Function FI_RowIndizesRestrictsSearch()

	Make/FREE/D numeric = {1, 2, 1, 1, 3}
	Make/FREE/D rowIndizes = {0, 1, 3, 4}

	WAVE/Z indizes = FindIndizes(numeric, var = 1, rowIndizes = rowIndizes)
	CHECK_EQUAL_WAVES(indizes, {0, 3}, mode = WAVE_DATA)
End

static Function FI_RowIndizesWithTextColumnAndLayers()

	Make/FREE/T/N=(4, 2, 2) text = "a"
	text[1][1][1] = "b"
	text[2][1][0] = "b"
	text[3][1][1] = "b"

	Make/FREE/D rowIndizes = {0, 1, 3}

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "b", startLayer = 0, endLayer = 1, rowIndizes = rowIndizes)
	CHECK_EQUAL_WAVES(indizes, {1, 3}, mode = WAVE_DATA)

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "b", rowIndizes = rowIndizes)
	CHECK_WAVE(indizes, NULL_WAVE)
End

static Function FI_RowIndizesWithRowRange()

	Make/FREE/D numeric = {1, 1, 1, 1, 1}

	Make/FREE/D rowIndizes = {0, 2, 3, 4}
	WAVE/Z indizes = FindIndizes(numeric, var = 1, startRow = 1, endRow = 3, rowIndizes = rowIndizes)
	CHECK_EQUAL_WAVES(indizes, {2, 3}, mode = WAVE_DATA)

	Make/FREE/D rowIndizes = {0, 2}
	WAVE/Z indizes = FindIndizes(numeric, var = 1, startRow = 1, endRow = 1, rowIndizes = rowIndizes)
	CHECK_WAVE(indizes, NULL_WAVE)
End

static Function FI_RowIndizesInvalidWaveRefFindsNothing()

	Make/FREE/D numeric = {1, 2}

	WAVE/Z indizes = FindIndizes(numeric, var = 1, rowIndizes = $"")
	CHECK_WAVE(indizes, NULL_WAVE)
End

static Function FI_RowIndizesChainsSearches()

	Make/FREE/T/N=(6, 2) text
	text[][0] = num2str(mod(p, 2))
	text[][1] = num2str(mod(p, 3))

	WAVE/Z indizes = FindIndizes(text, col = 0, var = 0)
	CHECK_EQUAL_WAVES(indizes, {0, 2, 4}, mode = WAVE_DATA)

	WAVE/Z indizesBoth = FindIndizes(text, col = 1, str = "1", rowIndizes = indizes)
	CHECK_EQUAL_WAVES(indizesBoth, {4}, mode = WAVE_DATA)
End

static Function FI_RowIndizesIgnoresRowsOutsideAndRounds()

	Make/FREE/D numeric = {1, 2, 1, 1, 3}

	Make/FREE/D rowIndizes = {-1, 5, NaN, Inf, -Inf, 0.4, 2.6}
	WAVE/Z indizes = FindIndizes(numeric, var = 1, rowIndizes = rowIndizes)
	CHECK_EQUAL_WAVES(indizes, {0, 3}, mode = WAVE_DATA)

	Make/FREE/D rowIndizes = {-1, 5, NaN}
	WAVE/Z indizes = FindIndizes(numeric, var = 1, rowIndizes = rowIndizes)
	CHECK_WAVE(indizes, NULL_WAVE)
End

// covers the MatrixOP code path on IP10
static Function FI_RowIndizesWithManyRows()

	Make/FREE/D/N=1000 numeric = mod(p, 2)

	// 600 row indizes from -99.7 to 1098.3
	Make/FREE/D/N=600 rowIndizes = 2 * p - 99.7

	WAVE/Z indizes = FindIndizes(numeric, var = 0, rowIndizes = rowIndizes)
	Make/FREE/D/N=500 expected = 2 * p
	CHECK_EQUAL_WAVES(indizes, expected, mode = WAVE_DATA)

	WAVE/Z indizes = FindIndizes(numeric, var = 0, startRow = 10, endRow = 20, rowIndizes = rowIndizes)
	CHECK_EQUAL_WAVES(indizes, {10, 12, 14, 16, 18, 20}, mode = WAVE_DATA)

	WAVE/Z indizes = FindIndizes(numeric, var = 0, startRow = 4, endRow = 4, rowIndizes = rowIndizes)
	CHECK_EQUAL_WAVES(indizes, {4}, mode = WAVE_DATA)

	WAVE/Z indizes = FindIndizes(numeric, var = 1, rowIndizes = rowIndizes)
	CHECK_WAVE(indizes, NULL_WAVE)
End

// UTF_TD_GENERATOR DataGenerators#InvalidRowIndizes
static Function FI_AbortsWithInvalidRowIndizes([WAVE wv])

	Make/FREE/D numeric = {1, 2, 1, 1, 3}

	try
		FindIndizes(numeric, var = 1, rowIndizes = wv)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End
/// @}

/// GetNumberOfUsefulThreads
/// @{

Function GNOT_Works()

	REQUIRE_GE_VAR(ThreadProcessorCount, 2)

	Make/FREE/N=(0) empty
	CHECK_EQUAL_VAR(GetNumberOfUsefulThreads(empty), 1)
	CHECK_EQUAL_VAR(GetNumberOfUsefulThreads({0}), 1)
	CHECK_EQUAL_VAR(GetNumberOfUsefulThreads({1000}), 1)
	CHECK_EQUAL_VAR(GetNumberOfUsefulThreads({4096}), 1)
	CHECK_EQUAL_VAR(GetNumberOfUsefulThreads({4097}), 2)
	CHECK_EQUAL_VAR(GetNumberOfUsefulThreads({1000, 8}), 2)

	CHECK_EQUAL_VAR(GetNumberOfUsefulThreads({1000}, pointsPerThread = 1000), 1)
	CHECK_EQUAL_VAR(GetNumberOfUsefulThreads({1000}, pointsPerThread = 500), 2)

	// limited to ThreadProcessorCount
	CHECK_EQUAL_VAR(GetNumberOfUsefulThreads({1000, 1000, 1000, 1000}), ThreadProcessorCount)
End

Function GNOT_ChecksParameters()

	try
		Make/FREE/N=(2, 2) dims
		GetNumberOfUsefulThreads(dims)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	try
		Make/FREE/T dimsText
		GetNumberOfUsefulThreads(dimsText)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	try
		Make/FREE dimsTooLarge
		GetNumberOfUsefulThreads(dimsTooLarge)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	try
		GetNumberOfUsefulThreads({1000}, pointsPerThread = 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	try
		GetNumberOfUsefulThreads({1000}, pointsPerThread = 1.5)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

/// @}
