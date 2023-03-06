#pragma TextEncoding = "UTF-8"
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

	JWN_SetNumberInWaveNote(wv, "NotANumber", NaN);
	val = JWN_GetNumberFromWaveNote(wv, "NotANumber")
	CHECK_EQUAL_VAR(NaN, val)

	JWN_SetNumberInWaveNote(wv, "Infinity", Inf);
	val = JWN_GetNumberFromWaveNote(wv, "Infinity")
	CHECK_EQUAL_VAR(Inf, val)

	JWN_SetNumberInWaveNote(wv, "negInfinity", -Inf);
	val = JWN_GetNumberFromWaveNote(wv, "negInfinity")
	CHECK_EQUAL_VAR(-Inf, val)

	JWN_SetNumberInWaveNote(wv, "number", -10);
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
	JWN_SetStringInWaveNote(wv, "string", strRef);
	strData = JWN_GetStringFromWaveNote(wv, "string")
	CHECK_EQUAL_STR(strRef, strData)

	strRef = "string"
	JWN_SetStringInWaveNote(wv, "string", strRef);
	strData = JWN_GetStringFromWaveNote(wv, "string")
	CHECK_EQUAL_STR(strRef, strData)

	strRef = ";,.:|~^@$🍉#🫃🏿"
	JWN_SetStringInWaveNote(wv, "string", strRef);
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

	JWN_SetWaveInWaveNote(wv, "wave", wvData);
	WAVE data = JWN_GetNumericWaveFromWaveNote(wv, "wave")
	CHECK_EQUAL_WAVES(wvData, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/T/N=10 wvText = num2istr(p)
	wvText[0] = ";,.:|~^@$🍉#🫃🏿"
	JWN_SetWaveInWaveNote(wv, "wave", wvText);
	WAVE data = JWN_GetTextWaveFromWaveNote(wv, "wave")
	CHECK_EQUAL_WAVES(wvText, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/D/N=0 wvDataDP
	JWN_SetWaveInWaveNote(wv, "wave", wvDataDP);
	WAVE data = JWN_GetNumericWaveFromWaveNote(wv, "wave")
	CHECK_EQUAL_WAVES(wvDataDP, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/T/N=0 wvTData
	JWN_SetWaveInWaveNote(wv, "wave", wvDataDP);
	WAVE dataT = JWN_GetTextWaveFromWaveNote(wv, "wave")
	CHECK_EQUAL_WAVES(wvTData, dataT, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/L wvDataI64 = -p
	JWN_SetWaveInWaveNote(wv, "wave", wvDataI64);
	WAVE data = JWN_GetNumericWaveFromWaveNote(wv, "wave")
	CHECK_EQUAL_WAVES(wvDataI64, data, mode = WAVE_DATA | DIMENSION_SIZES)

#if (IgorVersion() >= 9.00) && (NumberByKey("BUILD", IgorInfo(0)) >= 39150)
	Make/FREE/L/U wvDataUI64 = p
	JWN_SetWaveInWaveNote(wv, "wave", wvDataUI64);
	WAVE data = JWN_GetNumericWaveFromWaveNote(wv, "wave")
	CHECK_EQUAL_WAVES(wvDataUI64, data, mode = WAVE_DATA | DIMENSION_SIZES)
#endif

	WAVE/Z data = JWN_GetNumericWaveFromWaveNote(wv, "does_not_exist")
	CHECK_WAVE(data, NULL_WAVE)

	WAVE/Z data = JWN_GetTextWaveFromWaveNote(wv, "does_not_exist")
	CHECK_WAVE(data, NULL_WAVE)
End

static Function TestJSONWaveNoteCombinations()

	string str
	string str1 = "t-1000"
	string str2 = "t-800"

	Make/FREE wv
	Make/FREE/T wvText = {"string:" + str2}
	SetStringInWaveNote(wv, "string", str1)
	JWN_SetWaveInWaveNote(wv, "wave", wvText);
	str = GetStringFromWaveNote(wv, "string")
	CHECK_EQUAL_STR(str1, str)
End

static Function TestWaveNoteFromJSON()

	variable jsonID = JSON_PARSE("{ \"abcd\" : [1, 2]}")
	CHECK_GE_VAR(jsonID, 0)

	Make/FREE wv
	Note/K wv, "efgh\rJSON_BEGIN\r"
	JWN_SetWaveNoteFromJSON(wv, jsonID)
	CHECK_EQUAL_VAR(NaN, JSON_Release(jsonID, ignoreErr =  1))

	// existing wave note is preserved
	CHECK_EQUAL_VAR(strsearch(note(wv), "efgh", 0), 0)

	WAVE/Z data = JWN_GetNumericWaveFromWaveNote(wv, "/abcd")
	CHECK_EQUAL_WAVES(data, {1, 2}, mode = WAVE_DATA)
End
