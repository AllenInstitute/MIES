#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3	 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTF_WaveAveraging

static Function/WAVE SupportedTypeGetter()

	Make/FREE result = {IGOR_TYPE_32BIT_FLOAT, IGOR_TYPE_64BIT_FLOAT}

	SetDimLabel 0, 0, $"float", result
	SetDimLabel 0, 1, $"double", result

	return result
End

static Function IgorTypeToUTFType_IGNORE(variable igor_type)

	switch(igor_type)
		case IGOR_TYPE_32BIT_FLOAT:
			return FLOAT_WAVE
		case IGOR_TYPE_64BIT_FLOAT:
			return DOUBLE_WAVE
		default:
			FAIL()
	endswitch
End

Function CheckWaveScaling_IGNORE(WAVE result)

	string unit, unitRef
	unit = WaveUnits(result, ROWS)
	unitRef = "m"
	CHECK_EQUAL_STR(unit, unitRef)
	CHECK_SMALL_VAR(DimOffset(result, ROWS))
	CHECK_CLOSE_VAR(DimDelta(result, ROWS), 1)
End

Function AVE_ReturnsWaveRefWave()

	Make/FREE/N=0/WAVE input
	WAVE/WAVE result = MIES_fWaveAverage(input, NaN, NaN)
	CHECK_WAVE(result, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(result, ROWS), 3)
End

Function DoesNothingWithEmptyWave()

	Make/FREE/N=0/WAVE input
	WAVE/WAVE result = MIES_fWaveAverage(input, NaN, NaN)
	CHECK_WAVE(result[0], NULL_WAVE)
End

Function DoesNothingWithInvalidWave()

	WAVE/WAVE result = MIES_fWaveAverage($"", NaN, NaN)
	CHECK_WAVE(result[0], NULL_WAVE)
End

/// UTF_TD_GENERATOR SupportedTypeGetter
Function ReturnsCorrectResultWithOneWave([var])
	variable var

	Make/D/FREE data = {1, 2, 3, 4}
	SetScale/P x, 0, 1, "m", data
	Make/FREE/WAVE input = {data}

	WAVE/WAVE result = MIES_fWaveAverage(input, 1, var)
	CHECK_WAVE(result[0], NUMERIC_WAVE, minorType = IgorTypeToUTFType_IGNORE(var))
	CHECK_EQUAL_WAVES(result[0], {1, 2, 3, 4}, mode = WAVE_DATA)
	CheckWaveScaling_IGNORE(result[0])

	WAVE/WAVE result = MIES_fWaveAverage(input, 0, var)
	CHECK_WAVE(result[0], NUMERIC_WAVE, minorType = IgorTypeToUTFType_IGNORE(var))
	CHECK_EQUAL_WAVES(result[0], {1, 2, 3, 4}, mode = WAVE_DATA)
	CheckWaveScaling_IGNORE(result[0])
End

/// UTF_TD_GENERATOR SupportedTypeGetter
Function PointForPointNoNans([var])
	variable var

	Make/D/FREE data1 = {1, 2, 3, 4}
	Make/D/FREE data2 = {3, 4, 5, 6}
	SetScale/P x, 0, 1, "m", data1, data2

	Make/FREE/WAVE input = {data1, data2}

	WAVE/WAVE result = MIES_fWaveAverage(input, 0, var)
	CHECK_WAVE(result[0], NUMERIC_WAVE, minorType = IgorTypeToUTFType_IGNORE(var))
	CHECK_EQUAL_WAVES(result[0], {2, 3, 4, 5}, mode = WAVE_DATA)
	CheckWaveScaling_IGNORE(result[0])

	WAVE/WAVE result = MIES_fWaveAverage(input, 1, var)
	CHECK_WAVE(result[0], NUMERIC_WAVE, minorType = IgorTypeToUTFType_IGNORE(var))
	CHECK_EQUAL_WAVES(result[0], {2, 3, 4, 5}, mode = WAVE_DATA)
	CheckWaveScaling_IGNORE(result[0])
End

/// UTF_TD_GENERATOR SupportedTypeGetter
Function PointForPointWithNaNs([var])
	variable var

	Make/D/FREE data1 = {1, 2, NaN, 4}
	Make/D/FREE data2 = {3, 4, 5  , 6}
	SetScale/P x, 0, 1, "m", data1, data2

	Make/FREE/WAVE input = {data1, data2}

	WAVE/WAVE result = MIES_fWaveAverage(input, 0, var)
	CHECK_WAVE(result[0], NUMERIC_WAVE, minorType = IgorTypeToUTFType_IGNORE(var))
	CHECK_EQUAL_WAVES(result[0], {2, 3, NaN, 5}, mode = WAVE_DATA)
	CheckWaveScaling_IGNORE(result[0])

	WAVE/WAVE result = MIES_fWaveAverage(input, 1, var)
	CHECK_WAVE(result[0], NUMERIC_WAVE, minorType = IgorTypeToUTFType_IGNORE(var))
	CHECK_EQUAL_WAVES(result[0], {2, 3, 5, 5}, mode = WAVE_DATA)
	CheckWaveScaling_IGNORE(result[0])
End

/// UTF_TD_GENERATOR SupportedTypeGetter
Function NonPointForPointNoNans([var])
	variable var

	Make/D/FREE data1 = {1, 2, 3, 4}
	Make/D/FREE data2 = {3, 4, 5, 6, 7}
	SetScale/P x, 0, 1, "m", data1, data2

	Make/FREE/WAVE input = {data1, data2}

	WAVE/WAVE result = MIES_fWaveAverage(input, 0, var)
	CHECK_WAVE(result[0], NUMERIC_WAVE, minorType = IgorTypeToUTFType_IGNORE(var))
	CHECK_EQUAL_WAVES(result[0], {2, 3, 4, 5, 7}, mode = WAVE_DATA, tol = 1e-14)
	CheckWaveScaling_IGNORE(result[0])

	WAVE/WAVE result = MIES_fWaveAverage(input, 1, var)
	CHECK_WAVE(result[0], NUMERIC_WAVE, minorType = IgorTypeToUTFType_IGNORE(var))
	CHECK_EQUAL_WAVES(result[0], {2, 3, 4, 5, 7}, mode = WAVE_DATA, tol = 1e-14)
	CheckWaveScaling_IGNORE(result[0])
End

/// UTF_TD_GENERATOR SupportedTypeGetter
Function NonPointForPointWithNans([var])
	variable var

	Make/D/FREE data1 = {1, 2, NaN, 4}
	Make/D/FREE data2 = {3, 4, 5, 6, NaN}
	SetScale/P x, 0, 1, "m", data1, data2

	Make/FREE/WAVE input = {data1, data2}

	WAVE/WAVE result = MIES_fWaveAverage(input, 0, var)
	CHECK_WAVE(result[0], NUMERIC_WAVE, minorType = IgorTypeToUTFType_IGNORE(var))
	CHECK_EQUAL_WAVES(result[0], {2, 3, NaN, 5, NaN}, mode = WAVE_DATA, tol = 1e-14)
	CheckWaveScaling_IGNORE(result[0])

	WAVE/WAVE result = MIES_fWaveAverage(input, 1, var)
	CHECK_WAVE(result[0], NUMERIC_WAVE, minorType = IgorTypeToUTFType_IGNORE(var))
	CHECK_EQUAL_WAVES(result[0], {2, 3, 5, 5, NaN}, mode = WAVE_DATA, tol = 1e-14)
	CheckWaveScaling_IGNORE(result[0])
End
