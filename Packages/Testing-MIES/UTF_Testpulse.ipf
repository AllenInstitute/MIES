#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTF_Testpulse

static Function AveragingWorks()
	// rows: values
	// cols: headstages
	// layers: buffered entries
	Make/FREE/N=(2, 1, 3) buffer = NaN
	SetNumberInWaveNote(buffer, NOTE_INDEX, 0)

	Make/FREE results = {1, 2}

	MIES_TP#TP_CalculateAverage(buffer, results)
	CHECK_EQUAL_WAVES({{{1, 2}}, {{NaN, NaN}}, {{NaN, NaN}}}, buffer, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES({1, 2}, results, mode = WAVE_DATA)

	results = {3, 4}
	MIES_TP#TP_CalculateAverage(buffer, results)

	CHECK_EQUAL_WAVES({{{3, 4}}, {{1, 2}}, {{NaN, NaN}}}, buffer, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES({2, 3}, results, mode = WAVE_DATA)

	results = {5, 6}
	MIES_TP#TP_CalculateAverage(buffer, results)

	CHECK_EQUAL_WAVES({{{5, 6}}, {{3, 4}}, {{1, 2}}}, buffer, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES({3, 4}, results, mode = WAVE_DATA)

	results = {7, 8}
	MIES_TP#TP_CalculateAverage(buffer, results)

	CHECK_EQUAL_WAVES({{{7, 8}}, {{5, 6}}, {{3, 4}}}, buffer, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES({5, 6}, results, mode = WAVE_DATA)
End
