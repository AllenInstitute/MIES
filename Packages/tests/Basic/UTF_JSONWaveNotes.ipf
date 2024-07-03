#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=TstJSONWaveNote

static Function TestSetNumberInJSONWaveNote()

	variable val

	WAVE/Z wv = $""
	try
		JWN_SetNumberInWaveNote(wv, "path", NaN); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE wv
	try
		JWN_SetNumberInWaveNote(wv, "", NaN); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	JWN_SetNumberInWaveNote(wv, "NotANumber", NaN)
	val = JWN_GetNumberFromWaveNote(wv, "NotANumber")
	CHECK_EQUAL_VAR(NaN, val)

	JWN_SetNumberInWaveNote(wv, "Infinity", Inf)
	val = JWN_GetNumberFromWaveNote(wv, "Infinity")
	CHECK_EQUAL_VAR(Inf, val)

	JWN_SetNumberInWaveNote(wv, "negInfinity", -Inf)
	val = JWN_GetNumberFromWaveNote(wv, "negInfinity")
	CHECK_EQUAL_VAR(-Inf, val)

	JWN_SetNumberInWaveNote(wv, "number", -10)
	val = JWN_GetNumberFromWaveNote(wv, "number")
	CHECK_EQUAL_VAR(-10, val)

	val = JWN_GetNumberFromWaveNote(wv, "does_not_exist")
	CHECK_EQUAL_VAR(val, NaN)
End

static Function TestSetStringInJSONWaveNote()

	string nullStr, strRef, strData
	variable err

	WAVE/Z wv = $""
	try
		JWN_SetStringInWaveNote(wv, "path", ""); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE wv
	try
		JWN_SetStringInWaveNote(wv, "", ""); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	try
		JWN_SetStringInWaveNote(wv, "nullStr", nullStr); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		PASS()
	endtry

	strRef = ""
	JWN_SetStringInWaveNote(wv, "string", strRef)
	strData = JWN_GetStringFromWaveNote(wv, "string")
	CHECK_EQUAL_STR(strRef, strData)

	strRef = "string"
	JWN_SetStringInWaveNote(wv, "string", strRef)
	strData = JWN_GetStringFromWaveNote(wv, "string")
	CHECK_EQUAL_STR(strRef, strData)

	strRef = ";,.:|~^@$🍉#🫃🏿"
	JWN_SetStringInWaveNote(wv, "string", strRef)
	strData = JWN_GetStringFromWaveNote(wv, "string")
	CHECK_EQUAL_STR(strRef, strData)

	strData = JWN_GetStringFromWaveNote(wv, "does_not_exist")
	CHECK_EMPTY_STR(strData)
End

static Function TestSetWaveInJSONWaveNote()

	string nullStr, strRef, strData

	Make/FREE/N=10 wvData
	WAVE/Z wv = $""
	try
		JWN_SetWaveInWaveNote(wv, "path", wvData); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE wv
	try
		JWN_SetWaveInWaveNote(wv, "", wvData); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	try
		JWN_SetWaveInWaveNote(wv, "nullWave", $""); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE/WAVE wvRef
	try
		JWN_SetWaveInWaveNote(wv, "refWave", wvRef); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	wvData[0] = NaN
	wvData[1] = Inf
	wvData[2] = -Inf
	wvData[3] = -10

	JWN_SetWaveInWaveNote(wv, "wave", wvData)
	WAVE data = JWN_GetNumericWaveFromWaveNote(wv, "wave")
	CHECK_EQUAL_WAVES(wvData, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/T/N=10 wvText = num2istr(p)
	wvText[0] = ";,.:|~^@$🍉#🫃🏿"
	JWN_SetWaveInWaveNote(wv, "wave", wvText)
	WAVE data = JWN_GetTextWaveFromWaveNote(wv, "wave")
	CHECK_EQUAL_WAVES(wvText, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/D/N=0 wvDataDP
	JWN_SetWaveInWaveNote(wv, "wave", wvDataDP)
	WAVE data = JWN_GetNumericWaveFromWaveNote(wv, "wave")
	CHECK_EQUAL_WAVES(wvDataDP, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/T/N=0 wvTData
	JWN_SetWaveInWaveNote(wv, "wave", wvDataDP)
	WAVE dataT = JWN_GetTextWaveFromWaveNote(wv, "wave")
	CHECK_EQUAL_WAVES(wvTData, dataT, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/L wvDataI64 = -p
	JWN_SetWaveInWaveNote(wv, "wave", wvDataI64)
	WAVE data = JWN_GetNumericWaveFromWaveNote(wv, "wave")
	CHECK_EQUAL_WAVES(wvDataI64, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/L/U wvDataUI64 = p
	JWN_SetWaveInWaveNote(wv, "wave", wvDataUI64)
	WAVE data = JWN_GetNumericWaveFromWaveNote(wv, "wave")
	CHECK_EQUAL_WAVES(wvDataUI64, data, mode = WAVE_DATA | DIMENSION_SIZES)

	WAVE/Z data = JWN_GetNumericWaveFromWaveNote(wv, "does_not_exist")
	CHECK_WAVE(data, NULL_WAVE)

	WAVE/Z data = JWN_GetTextWaveFromWaveNote(wv, "does_not_exist")
	CHECK_WAVE(data, NULL_WAVE)

	// return $"" for non-numeric data
	Make/FREE/T wvDataText = {"a", "b", "c"}
	JWN_SetWaveInWaveNote(wv, "waveText", wvDataText)
	WAVE/Z data = JWN_GetNumericWaveFromWaveNote(wv, "waveText")
	CHECK_WAVE(data, NULL_WAVE)
End

static Function Test_WaveRefNumeric()

	Make/FREE wv
	Make/FREE/N=10 wvData0

	wvData0[0] = NaN
	wvData0[1] = Inf
	wvData0[2] = -Inf
	wvData0[3] = -10

	Make/FREE wvData1 = {1, 2, 3, 4}
	Make/FREE/N=0 wvData2
	Make/N=(2, 3)/FREE wvData3 = p * 2 + q
	Make/FREE/WAVE wvRef = {wvData0, wvData1, wvData2, wvData3}
	JWN_SetWaveInWaveNote(wv, "refWave", wvRef)

	WAVE/Z data = JWN_GetNumericWaveFromWaveNote(wv, "refWave/0")
	CHECK_EQUAL_WAVES(data, wvData0, mode = WAVE_DATA | DIMENSION_SIZES)

	WAVE/Z data = JWN_GetNumericWaveFromWaveNote(wv, "refWave/1")
	CHECK_EQUAL_WAVES(data, wvData1, mode = WAVE_DATA | DIMENSION_SIZES)

	WAVE/Z data = JWN_GetNumericWaveFromWaveNote(wv, "refWave/2")
	CHECK_EQUAL_WAVES(data, wvData2, mode = WAVE_DATA | DIMENSION_SIZES)

	WAVE/Z data = JWN_GetNumericWaveFromWaveNote(wv, "refWave/3")
	CHECK_EQUAL_WAVES(data, wvData3, mode = WAVE_DATA | DIMENSION_SIZES)

	WAVE/WAVE/Z container = JWN_GetWaveRefNumericFromWaveNote(wv, "refWave")
	CHECK_EQUAL_VAR(DimSize(container, ROWS), 4)
	CHECK_EQUAL_VAR(DimSize(container, COLS), 0)

	CHECK_EQUAL_WAVES(wvRef[0], container[0], mode = WAVE_DATA | DIMENSION_SIZES)
	CHECK_EQUAL_WAVES(wvRef[1], container[1], mode = WAVE_DATA | DIMENSION_SIZES)
	CHECK_EQUAL_WAVES(wvRef[2], container[2], mode = WAVE_DATA | DIMENSION_SIZES)
	CHECK_EQUAL_WAVES(wvRef[3], container[3], mode = WAVE_DATA | DIMENSION_SIZES)

	// empty wave ref wave
	Note/K wv
	Make/FREE/WAVE/N=0 wvRef
	JWN_SetWaveInWaveNote(wv, "refWave", wvRef)
	WAVE/Z container = JWN_GetWaveRefTextFromWaveNote(wv, "refWave")
	CHECK_WAVE(container, NULL_WAVE)

	Note/K wv
	Make/FREE/WAVE wvRef = {wvData0}
	JWN_SetWaveInWaveNote(wv, "refWave", wvRef)

	WAVE/Z data = JWN_GetNumericWaveFromWaveNote(wv, "refWave/0")
	CHECK_EQUAL_WAVES(data, wvData0, mode = WAVE_DATA)

	// no array
	Note/K wv
	JWN_SetNumberInWaveNote(wv, "num", 123)

	try
		WAVE/Z container = JWN_GetWaveRefNumericFromWaveNote(wv, "num")
		FAIL()
	catch
		PASS()
	endtry

	// null wave
	Note/K wv
	Make/FREE/WAVE/N=1 wvRef

	try
		JWN_SetWaveInWaveNote(wv, "refWave", wvRef)
		FAIL()
	catch
		PASS()
	endtry

	// wrong type
	Note/K wv
	Make/FREE/N=1/T txtWave = "abcd"
	Make/FREE/WAVE/N=1 wvRef = {txtWave}
	JWN_SetWaveInWaveNote(wv, "refWave", wvRef)

	try
		WAVE/Z container = JWN_GetWaveRefNumericFromWaveNote(wv, "refWave")
		FAIL()
	catch
		PASS()
	endtry
End

static Function Test_WaveRefText()

	Make/FREE wv
	Make/FREE/N=10/T wvData0

	wvData0[0] = "abcd"
	wvData0[1] = "efg"
	wvData0[2] = "1234"

	Make/FREE/T wvData1 = {"a", "b", "c", "d"}
	Make/FREE/N=0 wvData2
	Make/N=(1, 2)/FREE/T wvData3 = num2str(p + q)
	Make/FREE/WAVE wvRef = {wvData0, wvData1, wvData2, wvData3}
	JWN_SetWaveInWaveNote(wv, "refWave", wvRef)

	WAVE/Z data = JWN_GetTextWaveFromWaveNote(wv, "refWave/0")
	CHECK_EQUAL_WAVES(data, wvData0, mode = WAVE_DATA)

	WAVE/Z data = JWN_GetTextWaveFromWaveNote(wv, "refWave/1")
	CHECK_EQUAL_WAVES(data, wvData1, mode = WAVE_DATA)

	WAVE/Z data = JWN_GetTextWaveFromWaveNote(wv, "refWave/2")
	CHECK_EQUAL_WAVES(data, wvData2, mode = WAVE_DATA)

	WAVE/Z data = JWN_GetTextWaveFromWaveNote(wv, "refWave/3")
	CHECK_EQUAL_WAVES(data, wvData3, mode = WAVE_DATA)

	WAVE/WAVE/Z container = JWN_GetWaveRefTextFromWaveNote(wv, "refWave")
	CHECK_EQUAL_VAR(DimSize(container, ROWS), 4)
	CHECK_EQUAL_VAR(DimSize(container, COLS), 0)

	CHECK_EQUAL_WAVES(wvRef[0], container[0], mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(wvRef[1], container[1], mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(wvRef[2], container[2], mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(wvRef[3], container[3], mode = WAVE_DATA)

	// empty wave ref wave
	Note/K wv
	Make/FREE/WAVE/N=0 wvRef
	JWN_SetWaveInWaveNote(wv, "refWave", wvRef)
	WAVE/Z container = JWN_GetWaveRefTextFromWaveNote(wv, "refWave")
	CHECK_WAVE(container, NULL_WAVE)

	// no array
	Note/K wv
	JWN_SetNumberInWaveNote(wv, "num", 123)

	try
		WAVE/Z container = JWN_GetWaveRefTextFromWaveNote(wv, "num")
		FAIL()
	catch
		PASS()
	endtry

	// null wave
	Note/K wv
	Make/FREE/WAVE/N=1 wvRef

	try
		JWN_SetWaveInWaveNote(wv, "refWave", wvRef)
		FAIL()
	catch
		PASS()
	endtry

	// wrong type
	Note/K wv
	Make/FREE/N=1 waveDataNum = 1
	Make/FREE/WAVE/N=1 wvRef = {waveDataNum}
	JWN_SetWaveInWaveNote(wv, "refWave", wvRef)

	try
		WAVE/Z container = JWN_GetWaveRefTextFromWaveNote(wv, "refWave")
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestJSONWaveNoteCombinations()

	string str
	string str1 = "t-1000"
	string str2 = "t-800"

	Make/FREE wv
	Make/FREE/T wvText = {"string:" + str2}
	SetStringInWaveNote(wv, "string", str1)
	JWN_SetWaveInWaveNote(wv, "wave", wvText)
	str = GetStringFromWaveNote(wv, "string")
	CHECK_EQUAL_STR(str1, str)
End

static Function TestWaveNoteFromJSON()

	variable jsonID = JSON_Parse("{ \"abcd\" : [1, 2]}")
	CHECK_GE_VAR(jsonID, 0)

	Make/FREE wv
	Note/K wv, ("efgh" + WAVE_NOTE_JSON_SEPARATOR)
	JWN_SetWaveNoteFromJSON(wv, jsonID)

	// releases by default
	CHECK(!JSON_IsValid(jsonID))

	// existing wave note is preserved
	CHECK_EQUAL_VAR(strsearch(note(wv), "efgh", 0), 0)

	WAVE/Z data = JWN_GetNumericWaveFromWaveNote(wv, "/abcd")
	CHECK_EQUAL_WAVES(data, {1, 2}, mode = WAVE_DATA)

	// but we can also not release
	jsonID = JSON_Parse("{ \"efgh\" : [3, 4]}")
	JWN_SetWaveNoteFromJSON(wv, jsonID, release = 0)
	CHECK(JSON_IsValid(jsonID))
End

static Function TestCreatePath()

	variable jsonID

	Make/FREE wv
	JWN_CreatePath(wv, "/a/b/c")

	jsonID = JWN_GetWaveNoteAsJSON(wv)
	CHECK_GE_VAR(jsonID, 0)

	CHECK_EQUAL_VAR(JSON_GetType(jsonID, "/a"), JSON_OBJECT)
	CHECK_EQUAL_VAR(JSON_GetType(jsonID, "/a/b"), JSON_OBJECT)
	CHECK_EQUAL_VAR(JSON_GetType(jsonID, "/a/b/c"), JSON_OBJECT)

	JSON_Release(jsonID)
End
