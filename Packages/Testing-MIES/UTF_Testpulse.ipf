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

static Function FetchingTestpulsesWorks()
	string device = "myDevice"

	// emty stored TPs
	WAVE/Z result = TP_GetStoredTPs(device, 0xA, 1)
	CHECK_WAVE(result, NULL_WAVE)

	TP_StoreTP(device, {1}, 0xA, "I_DONT_CARE")

	// not found
	WAVE/Z result = TP_GetStoredTPs(device, 0xB, 1)
	CHECK_WAVE(result, NULL_WAVE)

	// requested too many
	WAVE/Z result = TP_GetStoredTPs(device, 0xA, 2)
	CHECK_WAVE(result, NULL_WAVE)

	TP_StoreTP(device, {2}, 0xB, "I_DONT_CARE")

	// works with fetching one TP
	WAVE/WAVE/Z result = TP_GetStoredTPs(device, 0xA, 1)
	CHECK_WAVE(result, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(result, ROWS), 1)
	CHECK_EQUAL_WAVES(WaveRef(result, row=0), {{1}}, mode = WAVE_DATA)

	// works with fetching two TPs
	WAVE/WAVE/Z result = TP_GetStoredTPs(device, 0xB, 2)
	CHECK_WAVE(result, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(result, ROWS), 2)
	CHECK_EQUAL_WAVES(WaveRef(result, row=0), {{1}}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(WaveRef(result, row=1), {{2}}, mode = WAVE_DATA)

	// does respect cycle ID
	TP_StoreTP(device, {3}, 0xC, "I_DONT_CARE")

	WAVE/WAVE storedTPs = GetStoredTestPulseWave(device)
	SetNumberInWaveNote(storedTPs[2], "TPCycleID", 4711)

	// fetching one works
	WAVE/WAVE/Z result = TP_GetStoredTPs(device, 0xC, 1)
	CHECK_WAVE(result, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(result, ROWS), 1)
	CHECK_EQUAL_WAVES(WaveRef(result, row=0), {{3}}, mode = WAVE_DATA)

	// but two not because 0xB has a different cycle id
	WAVE/WAVE/Z result = TP_GetStoredTPs(device, 0xC, 2)
	CHECK_WAVE(result, NULL_WAVE)
End
