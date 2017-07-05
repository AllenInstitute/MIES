#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=zmq_test_serializeWave

Function ComplainsWithWaveRefWave()

	variable err

	try
		Make/FREE/WAVE wv
		zeromq_test_serializeWave(wv); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		PASS()
	endtry
End

Function ComplainsWithDFRefWave()

	variable err

	try
		Make/FREE/DF wv
		zeromq_test_serializeWave(wv); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		PASS()
	endtry
End

Function WorksWithInvalidRef()

	string actual, expected
	actual   = zeromq_test_serializeWave($"")
	expected = "null"
	CHECK_EQUAL_STR(actual, expected)
End

Function WorksWithEmptyFreeWave()

	string actual
	Make/FREE/N=0 wv
	actual = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)
End

Function WorksWithEmptyFreeTextWave()

	string actual
	Make/FREE/T/N=0 wv
	actual = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)
End

Function WorksWithEmptyPermWave()

	string actual, expected
	Make/N=0/D wv = p
	actual = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)
End

Function WorksWithNonEmptyDoubleWave()

	string actual
	Make/N=(1, 2, 3, 4)/D wv = q * r * t
	actual = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)
End

Function WorksWithNonEmptyFloatWave()

	string actual
	Make/N=(1, 2, 3, 4)/R wv = q * r * t
	actual = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)
End

Function WorksWithNonEmptyIntegerWaves()

	string actual
	variable i, numEntries

	Make/FREE/I types = {INT8_WAVE, INT16_WAVE, INT32_WAVE, INT64_WAVE, INT8_WAVE | UNSIGNED_WAVE, INT16_WAVE | UNSIGNED_WAVE, INT32_WAVE | UNSIGNED_WAVE, INT64_WAVE | UNSIGNED_WAVE}

	numEntries = DimSize(types, 0)
	for(i = 0; i < numEntries; i++)
		Make/FREE/Y=(types[i])/N=(2, 3, 4, 5)/R wv = p * q * r * t
		actual = zeromq_test_serializeWave(wv)

		STRUCT WaveProperties s
		ParseSerializedWave(actual, s)
		CompareWaveWithSerialized(wv, s)
		WaveClear wv
	endfor
End

Function WorksWithInt64AndLargeValues()

	string actual
	Make/N=(5)/L wv = floor(2^(32+p))
	actual = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)
End

Function WorksWithDoubleAndHighPrec()

	string actual
	Make/N=(5)/D wv = 1.23456789101112
	actual = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)
End

Function WorksWithDoubleNonNormal()

	string actual
	Make/D wv = {1, 2, NaN, Inf, -Inf, 6}
	actual = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)
End

Function WorksWithFloatNonNormal()

	string actual
	Make/R wv = {1, 2, NaN, Inf, -Inf, 6}
	actual = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)
End

Function WorksWithTextWave()

	string actual
	Make/FREE/T wv = {"Hallo", "Welt"}
	actual = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)
End

Function WorksWithTextWaveQuoting()

	string actual
	Make/FREE/T wv = {"Hallo", "Welt", "\"!"}
	actual = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)
End

Function WorksWithTextWaveUTF8()

	string actual
	Make/FREE/T wv = {"Hallöäüß", "\u2622"}
	actual = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)
End

Function WorksWithTextWaveConversion()

	string actual, expected, path
	string actualLine, expectedLine
	variable encoding = 120

	path = ParseFilePath(1, FunctionPath(""), ":", 1, 0) + "saved-on-ip6-and-german-windows.itx"

	LoadWave/T/O/Q path
	WAVE/T wv = $StringFromList(0, S_wavenames)

	actual = zeromq_test_serializeWave(wv)
	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)
End

Function WorksWithComplexInt()

	string actual
	Make/C/N=(1)/I wv = cmplx(1,2)
	actual = zeromq_test_serializeWave(wv)
	print actual
	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)
End

Function WorksWithCmplxIntUnsigned()

	string actual
	Make/I/U/C/N=(1)/I wv = cmplx(1,2)
	actual = zeromq_test_serializeWave(wv)
	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)
End

Function DoesNotIncludeDefaultProperties()

	string actual
	Make/FREE/N=(1)/R wv = 4711
	actual = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)

	Wave/T T_TokenText
	FindValue/TXOP=4/TEXT="unit" T_TokenText
	CHECK_EQUAL_VAR(V_Value, -1)

	FindValue/TXOP=4/TEXT="label" T_TokenText
	CHECK_EQUAL_VAR(V_Value, -1)

	FindValue/TXOP=4/TEXT="fullScale" T_TokenText
	CHECK_EQUAL_VAR(V_Value, -1)

	FindValue/TXOP=4/TEXT="note" T_TokenText
	CHECK_EQUAL_VAR(V_Value, -1)
End

Function DoesIncludeDataUnitsAndFull()

	string actual, expected
	string fullScaleMin = "123"
	string fullScaleMax = "456"

	Make/FREE/N=(1)/R wv = 4711
	SetScale d, str2num(fullScaleMin), str2num(fullScaleMax), "myUnit", wv
	actual = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)

	Wave/T T_TokenText
	FindValue/TXOP=4/TEXT="unit" T_TokenText
	CHECK_NEQ_VAR(V_Value, -1)
	expected = "myUnit"
	actual   = T_TokenText[V_Value + 1]
	CHECK_EQUAL_STR(expected, actual)

	Wave/T T_TokenText
	FindValue/TXOP=4/TEXT="fullScale" T_TokenText
	CHECK_NEQ_VAR(V_Value, -1)
	actual = T_TokenText[V_value + 2]
	CHECK_EQUAL_STR(fullScaleMin, actual)
	actual = T_TokenText[V_value + 3]
	CHECK_EQUAL_STR(fullScaleMax, actual)
End

Function DoesIncludeWaveNote()

	string actual, expected
	string waveNote = "Hi there! I'm using \"quotations\" here and with fancy äßü."

	Make/FREE/N=(1)/R wv = 4711
	Note/K wv, waveNote

	actual = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)

	Wave/T T_TokenText
	FindValue/TXOP=4/TEXT="note" T_TokenText
	CHECK_NEQ_VAR(V_Value, -1)
	actual = T_TokenText[V_value + 1]
	actual = ReplaceString("\\", actual, "")
	CHECK_EQUAL_STR(waveNote, actual)
End

Function DoesIncludeDimensionUnit()

	string actual, expected
	string unit = "myUnit"

	Make/FREE/N=(1, 2)/R wv = 4711
	SetScale/P y, 0, 1, unit, wv

	actual = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(actual, s)
	CompareWaveWithSerialized(wv, s)

	Wave/T T_TokenText
	FindValue/TXOP=4/TEXT="unit" T_TokenText
	CHECK_NEQ_VAR(V_Value, -1)
	// no x units
	actual = T_TokenText[V_value + 2]
	CHECK_EMPTY_STR(actual)
	actual = T_TokenText[V_value + 3]
	CHECK_EQUAL_STR(unit, actual)

	FindValue/TXOP=4/TEXT="delta" T_TokenText
	CHECK_EQUAL_VAR(V_Value, -1)

	FindValue/TXOP=4/TEXT="offset" T_TokenText
	CHECK_EQUAL_VAR(V_Value, -1)
End

Function DoesIncludeDimensionScaling()

	variable actual, expected
	string replyMessage

	Make/FREE/N=(1, 2)/R wv = 4711
	SetScale/P y, 3, 4, "", wv

	replyMessage = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(replyMessage, s)
	CompareWaveWithSerialized(wv, s)

	Wave/T T_TokenText
	FindValue/TXOP=4/TEXT="offset" T_TokenText
	CHECK_NEQ_VAR(V_Value, -1)

	// x has default offset
	actual = str2num(T_TokenText[V_value + 2])
	CHECK_EQUAL_VAR(actual, 0)
	actual = str2num(T_TokenText[V_value + 3])
	CHECK_EQUAL_VAR(actual, 3)

	FindValue/TXOP=4/TEXT="delta" T_TokenText
	CHECK_NEQ_VAR(V_Value, -1)

	// x has default delta
	actual = str2num(T_TokenText[V_value + 2])
	CHECK_EQUAL_VAR(actual, 1)
	actual = str2num(T_TokenText[V_value + 3])
	CHECK_EQUAL_VAR(actual, 4)
End

Function DoesIncludeDimensionLabelFull()

	string actual, expected
	string replyMessage
	string lbl = "myLabel"

	Make/FREE/N=(1, 2)/R wv = 4711
	SetDimLabel 1, -1, $lbl, wv
	replyMessage = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(replyMessage, s)
	CompareWaveWithSerialized(wv, s)

	Wave/T T_TokenText

	FindValue/TXOP=4/TEXT="each" T_TokenText
	CHECK_EQUAL_VAR(V_Value, -1)

	FindValue/TXOP=4/TEXT="full" T_TokenText
	CHECK_NEQ_VAR(V_Value, -1)

	// x has default label ""
	actual = T_TokenText[V_value + 2]
	CHECK_EMPTY_STR(actual)
	actual = T_TokenText[V_value + 3]
	CHECK_EQUAL_STR(actual, lbl)
End

Function DoesIncludeDimensionLabelEach()

	string actual, expected
	string replyMessage
	Make/FREE/T lbls = { "myLabel00", "myLabel10", "myLabel01", "myLabel11" }

	Make/O/T wv = {"00", "10", "01", "11"}
	Redimension/N=(2, 2) wv
	SetDimLabel 0, 0, $(lbls[0]), wv
	SetDimLabel 0, 1, $(lbls[1]), wv
	SetDimLabel 1, 0, $(lbls[2]), wv
	SetDimLabel 1, 1, $(lbls[3]), wv

	replyMessage = zeromq_test_serializeWave(wv)

	STRUCT WaveProperties s
	ParseSerializedWave(replyMessage, s)
	CompareWaveWithSerialized(wv, s)

	Wave/T T_TokenText

	FindValue/TXOP=4/TEXT="full" T_TokenText
	CHECK_EQUAL_VAR(V_Value, -1)

	FindValue/TXOP=4/TEXT="each" T_TokenText
	CHECK_NEQ_VAR(V_Value, -1)

	actual   = T_TokenText[V_value + 2]
	expected = lbls[0]
	CHECK_EQUAL_STR(actual, expected)

	actual = T_TokenText[V_value + 3]
	expected = lbls[1]
	CHECK_EQUAL_STR(actual, expected)

	actual = T_TokenText[V_value + 4]
	expected = lbls[2]
	CHECK_EQUAL_STR(actual, expected)

	actual = T_TokenText[V_value + 5]
	expected = lbls[3]
	CHECK_EQUAL_STR(actual, expected)
End
