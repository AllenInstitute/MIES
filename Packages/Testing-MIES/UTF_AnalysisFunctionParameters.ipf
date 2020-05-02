#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=AnalysisFuncParamTesting

static Function UpgradeToEncodedAnalysisParamsWorks()

	string params, actual, expected
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	// force a wave upgrade
	Note/K WPT

	// reset to old format
	WPT[29][%Set][INDEP_EPOCH_TYPE] = ""
	WPT[10][%Set][INDEP_EPOCH_TYPE] = "a:variable=1.234,b:string=hi there,c:textwave= |zz|,d:wave=1|2|3|,"

	// force wave upgrade
	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)
	CHECK(GetWaveVersion(WPT) >= 10)

	expected = ""
	actual = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EQUAL_STR(expected, actual)

	// URL encoded text values
	expected = "a:variable=1.234,b:string=hi%20there,c:textwave=%20|zz|,d:wave=1|2|3|,"
	actual = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EQUAL_STR(expected, actual)
End

static Function AbortsWithEmptyName()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "", var = 123); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithInvalidName1()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "123", var = 123); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithInvalidName2()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "a b", var = 123); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithNoData()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "ab"); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithInvalidDataComb1()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "ab", var = 123, str = "hi there!"); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithInvalidDataComb2()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "ab", var = 123, wv = {1, 2}); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithInvalidDataComb3()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "ab", str = "hi there", wv = {1, 2}); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithInvalidDataComb4()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "ab", str = "hi there", wv = {1, 2}); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function WorksWithPreviouslyInvalidContents()

	string params, input, reference, expected
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	input = "; , = :|"
	WBP_AddAnalysisParameter(stimSet, "ab", str = input)

	reference = WPT[29][%Set][INDEP_EPOCH_TYPE]
	// URL encoded
	expected = "ab=textwave:%3B%20%2C%20%3D%20%3A%7C"
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithInvalidWaveType()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		Make/WAVE wv
		WBP_AddAnalysisParameter(stimSet, "ab", wv = wv); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithEmptyWave()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		Make/N=0 wv
		WBP_AddAnalysisParameter(stimSet, "ab", wv = wv); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AcceptsAllTextWaveContents()

	string params, names, refNames, name, type, refType
	string refName
	string refString, val
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	Make/T/FREE refData = {"1", "2", "3", "|"}
	refName   = "abcd"

	WBP_AddAnalysisParameter(stimSet, refName, wv = refData)
End

static Function WorksWithVariable()

	string params, names, refNames, name, type, refType
	string refName
	variable refValue, val
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	refValue = 123
	refName  = "ab"

	WBP_AddAnalysisParameter(stimSet, refName, var = refValue)
	params = WPT[29][%Set][INDEP_EPOCH_TYPE]

	refNames = refName + ";"
	names = AFH_GetListOfAnalysisParamNames(params)
	CHECK_EQUAL_STR(names, refNames)

	refType = "variable"
	type = AFH_GetAnalysisParamType(refName, params)
	CHECK_EQUAL_STR(refType, type)

	val = AFH_GetAnalysisParamNumerical(refName, params)
	CHECK_EQUAL_VAR(refValue, val)
End

static Function WorksWithString()

	string params, names, refNames, name, type, refType
	string refName
	string refString, val
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	refString = "hi there"
	refName   = "abc"

	WBP_AddAnalysisParameter(stimSet, refName, str = refString)
	params = WPT[29][%Set][INDEP_EPOCH_TYPE]

	refNames = refName + ";"
	names = AFH_GetListOfAnalysisParamNames(params)
	CHECK_EQUAL_STR(names, refNames)

	refType = "string"
	type = AFH_GetAnalysisParamType(refName, params)
	CHECK_EQUAL_STR(refType, type)

	val = AFH_GetAnalysisParamTextual(refName, params)
	CHECK_EQUAL_STR(refString, val)
End

static Function WorksWithNumericWave()

	string params, names, refNames, name, type, refType
	string refName
	string refString, val
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	Make/D/FREE refData = {1, 2, 3, 4}
	refName   = "abcde"

	WBP_AddAnalysisParameter(stimSet, refName, wv = refData)
	params = WPT[29][%Set][INDEP_EPOCH_TYPE]

	refNames = refName + ";"
	names = AFH_GetListOfAnalysisParamNames(params)
	CHECK_EQUAL_STR(names, refNames)

	refType = "wave"
	type = AFH_GetAnalysisParamType(refName, params)
	CHECK_EQUAL_STR(refType, type)

	WAVE data = AFH_GetAnalysisParamWave(refName, params)
	CHECK_EQUAL_WAVES(refData, data)
	CHECK_EQUAL_VAR(WaveType(data, 2), 2)
End

static Function WorksWithTextWave()

	string params, names, refNames, name, type, refType
	string refName
	string refString, val
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	Make/T/FREE refData = {"1", "2", "3", "hi_there"}
	refName   = "abcdef"

	WBP_AddAnalysisParameter(stimSet, refName, wv = refData)
	params = WPT[29][%Set][INDEP_EPOCH_TYPE]

	refNames = refName + ";"
	names = AFH_GetListOfAnalysisParamNames(params)
	CHECK_EQUAL_STR(names, refNames)

	refType = "textwave"
	type = AFH_GetAnalysisParamType(refName, params)
	CHECK_EQUAL_STR(refType, type)

	WAVE/T data = AFH_GetAnalysisParamTextWave(refName, params)
	CHECK_EQUAL_TEXTWAVES(refData, data)
	CHECK_EQUAL_VAR(WaveType(data, 2), 2)
End

static Function ReplacesDuplicateEntries()

	string params, names, refNames, name, type, refType
	string refName
	string refString, val
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	WBP_AddAnalysisParameter(stimSet, "a1", str = "a1")
	WBP_AddAnalysisParameter(stimSet, "a2", str = "a2")
	WBP_AddAnalysisParameter(stimSet, "a1", str = "a11")

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]

	refNames = "a1;a2;"
	names = AFH_GetListOfAnalysisParamNames(params)
	CHECK_EQUAL_STR(names, refNames)

	refString = "a11"
	val       = AFH_GetAnalysisParamTextual("a1", params)
	CHECK_EQUAL_STR(refString, val)

	refString = "a2"
	val       = AFH_GetAnalysisParamTextual("a2", params)
	CHECK_EQUAL_STR(refString, val)
End

static Function ReturnsInvalidWaveRef()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[29][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	CHECK_WAVE(AFH_GetAnalysisParamWave("I_DONT_EXIST", params), NULL_WAVE)
	CHECK_WAVE(AFH_GetAnalysisParamTextWave("I_DONT_EXIST", params), NULL_WAVE)
End

/// @name AFH_GetAnalysisParamNumerical
/// @{
Function GAPN_AbortsWithEmptyName()

	try
		AFH_GetAnalysisParamNumerical("", "name:variable=0")
		FAIL()
	catch
		PASS()
	endtry
End

Function GAPN_AbortsWithIllegalName()

	try
		AFH_GetAnalysisParamNumerical("123", "name:variable=0")
		FAIL()
	catch
		PASS()
	endtry
End

Function GAPN_AbortsWithIllegalType()

	try
		AFH_GetAnalysisParamNumerical("name", "name:invalidType=0")
		FAIL()
	catch
		PASS()
	endtry
End

Function GAPN_AbortsWithWrongType()

	try
		AFH_GetAnalysisParamNumerical("name", "name:string=0")
		FAIL()
	catch
		PASS()
	endtry
End

Function GAPN_ReturnsNanForNonExisting()

	variable result = AFH_GetAnalysisParamNumerical("name", "otherName:variable=0")
	CHECK_EQUAL_VAR(result, NaN)
End

Function GAPN_Works()

	variable result = AFH_GetAnalysisParamNumerical("name", "name:variable=123")
	CHECK_EQUAL_VAR(result, 123)
End

Function GAPN_WorksWithDefault()

	variable result = AFH_GetAnalysisParamNumerical("name", "", defValue = 123)
	CHECK_EQUAL_VAR(result, 123)
End

/// @}

/// @name AFH_GetAnalysisParamTextual
/// @{
Function GAPT_AbortsWithEmptyName()

	try
		AFH_GetAnalysisparamTextual("", "name:string=0")
		FAIL()
	catch
		PASS()
	endtry
End

Function GAPT_AbortsWithIllegalName()

	try
		AFH_GetAnalysisparamTextual("123", "name:string=0")
		FAIL()
	catch
		PASS()
	endtry
End

Function GAPT_AbortsWithIllegalType()

	try
		AFH_GetAnalysisparamTextual("name", "name:invalidType=0")
		FAIL()
	catch
		PASS()
	endtry
End

Function GAPT_AbortsWithWrongType()

	try
		AFH_GetAnalysisparamTextual("name", "name:variable=0")
		FAIL()
	catch
		PASS()
	endtry
End

Function GAPT_ReturnsEmptyForNonExisting()

	string result = AFH_GetAnalysisparamTextual("name", "otherName:string=0")
	string expected = ""
	CHECK_EQUAL_STR(result, expected)
End

Function GAPT_Works()

	string result = AFH_GetAnalysisparamTextual("name", "name:string=abcd")
	string expected = "abcd"
	CHECK_EQUAL_STR(result, expected)
End

Function GAPT_WorksWithURLEncoded()

	string result = AFH_GetAnalysisparamTextual("name", "name:string=%20")
	string expected = " "
	CHECK_EQUAL_STR(result, expected)
End

Function GAPT_WorksWithDefault()

	string result = AFH_GetAnalysisparamTextual("name", "", defValue = "abcd")
	string expected = "abcd"
	CHECK_EQUAL_STR(result, expected)
End

/// @}

/// @name AFH_GetAnalysisParamWave
/// @{
Function GAPW_AbortsWithEmptyName()

	try
		AFH_GetAnalysisParamWave("", "name:wave=0")
		FAIL()
	catch
		PASS()
	endtry
End

Function GAPW_AbortsWithIllegalName()

	try
		AFH_GetAnalysisParamWave("123", "name:wave=0")
		FAIL()
	catch
		PASS()
	endtry
End

Function GAPW_AbortsWithIllegalType()

	try
		AFH_GetAnalysisParamWave("name", "name:invalidType=0")
		FAIL()
	catch
		PASS()
	endtry
End

Function GAPW_AbortsWithWrongType()

	try
		AFH_GetAnalysisParamWave("name", "name:variable=0")
		FAIL()
	catch
		PASS()
	endtry
End

Function GAPW_ReturnsNonExisting()

	WAVE/Z result = AFH_GetAnalysisParamWave("name", "otherName:wave=1|2|3")
	CHECK_WAVE(result, NULL_WAVE)
End

Function GAPW_Works()

	WAVE/Z result = AFH_GetAnalysisParamWave("name", "name:wave=1|2|3")
	CHECK_EQUAL_WAVES(result, {1, 2, 3}, mode = WAVE_DATA)
End

Function GAPW_WorksWithDefault()

	WAVE/Z result = AFH_GetAnalysisParamWave("name", "", defValue = {1, 2, 3})
	CHECK_EQUAL_WAVES(result, {1, 2, 3}, mode = WAVE_DATA)
End

/// @}

/// @name AFH_GetAnalysisParamTextWave
/// @{
Function GAPTW_AbortsWithEmptyName()

	try
		AFH_GetAnalysisParamTextWave("", "name:textwave=0")
		FAIL()
	catch
		PASS()
	endtry
End

Function GAPTW_AbortsWithIllegalName()

	try
		AFH_GetAnalysisParamTextWave("123", "name:textwave=0")
		FAIL()
	catch
		PASS()
	endtry
End

Function GAPTW_AbortsWithIllegalType()

	try
		AFH_GetAnalysisParamTextWave("name", "name:invalidType=0")
		FAIL()
	catch
		PASS()
	endtry
End

Function GAPTW_AbortsWithWrongType()

	try
		AFH_GetAnalysisParamTextWave("name", "name:variable=0")
		FAIL()
	catch
		PASS()
	endtry
End

Function GAPTW_ReturnsNonExisting()

	WAVE/Z result = AFH_GetAnalysisParamTextWave("name", "otherName:textwave=1|2|3")
	CHECK_WAVE(result, NULL_WAVE)
End

Function GAPTW_Works()

	WAVE/Z result = AFH_GetAnalysisParamTextWave("name", "name:textwave=a|b|c|d")
	CHECK_EQUAL_TEXTWAVES(result, {"a", "b", "c", "d"}, mode = WAVE_DATA)
End

Function GAPTW_WorksWithURLEncoded()

	WAVE/Z result = AFH_GetAnalysisParamTextWave("name", "name:textwave=%20|%7C")
	CHECK_EQUAL_TEXTWAVES(result, {" ", "|"}, mode = WAVE_DATA)
End

Function GAPTW_WorksWithDefault()

	Make/T/FREE input = {"a", "b", "c", "d"}
	WAVE/Z result = AFH_GetAnalysisParamTextWave("name", "", defValue = input)
	CHECK_EQUAL_TEXTWAVES(result, {"a", "b", "c", "d"}, mode = WAVE_DATA)
End

/// @}
