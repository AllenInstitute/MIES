#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=AnalysisFuncParamTesting

static Function TEST_SUITE_BEGIN_OVERRIDE(string name)

	LoadStimsetsIfRequired()

	TestBeginCommon()
End

static Function TEST_CASE_BEGIN_OVERRIDE(string name)

	TestCaseBeginCommon()

	MoveStimsetsIntoPlace()
End

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
	CHECK_GE_VAR(GetWaveVersion(WPT), 10)

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
		AFH_AddAnalysisParameter(stimSet, "", var = 123); AbortOnRTE
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
		AFH_AddAnalysisParameter(stimSet, "123", var = 123); AbortOnRTE
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
		AFH_AddAnalysisParameter(stimSet, "a b", var = 123); AbortOnRTE
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
		AFH_AddAnalysisParameter(stimSet, "ab"); AbortOnRTE
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
		AFH_AddAnalysisParameter(stimSet, "ab", var = 123, str = "hi there!"); AbortOnRTE
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
		AFH_AddAnalysisParameter(stimSet, "ab", var = 123, wv = {1, 2}); AbortOnRTE
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
		AFH_AddAnalysisParameter(stimSet, "ab", str = "hi there", wv = {1, 2}); AbortOnRTE
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
		AFH_AddAnalysisParameter(stimSet, "ab", str = "hi there", wv = {1, 2}); AbortOnRTE
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
	AFH_AddAnalysisParameter(stimSet, "ab", str = input)

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
		AFH_AddAnalysisParameter(stimSet, "ab", wv = wv); AbortOnRTE
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
		AFH_AddAnalysisParameter(stimSet, "ab", wv = wv); AbortOnRTE
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

	AFH_AddAnalysisParameter(stimSet, refName, wv = refData)
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

	AFH_AddAnalysisParameter(stimSet, refName, var = refValue)
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

	AFH_AddAnalysisParameter(stimSet, refName, str = refString)
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

	AFH_AddAnalysisParameter(stimSet, refName, wv = refData)
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

	AFH_AddAnalysisParameter(stimSet, refName, wv = refData)
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

	AFH_AddAnalysisParameter(stimSet, "a1", str = "a1")
	AFH_AddAnalysisParameter(stimSet, "a2", str = "a2")
	AFH_AddAnalysisParameter(stimSet, "a1", str = "a11")

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

static Function EnsureCorrectUserAnalysis()

	REQUIRE_EQUAL_VAR(ItemsInList(FunctionList("InvalidSignature", ";", "WIN:UserAnalysisFunctions.ipf")), 1)
End

static Function/WAVE GetAnalysisFunctions()
	string funcs

	funcs = AFH_GetAnalysisFunctions(ANALYSIS_FUNCTION_VERSION_V3, includeUserFunctions = 0)

	// remove our test help functions which do nasty things
	funcs = GrepList(funcs, ".*_V3", 1)
	funcs = GrepList(funcs, ".*_.*")

	WAVE/T wv = ListToTextWave(funcs, ";")

	SetDimensionLabels(wv, funcs, ROWS)

	return wv
End

Function CheckHelpStringsOfAllAnalysisFunctions()
	string genericFunc, params, names, name, help
	variable j, numParams

	for(genericFunc : GetAnalysisFunctions())
		params = AFH_GetListOfAnalysisParams(genericFunc, REQUIRED_PARAMS | OPTIONAL_PARAMS)

		names = AFH_GetListOfAnalysisParamNames(params)
		numParams = ItemsInList(names)
		for(j = 0; j < numParams; j += 1)
			name = StringFromList(j, names)
			help = AFH_GetHelpForAnalysisParameter(genericFunc, name)
			CHECK_PROPER_STR(help)
		endfor
	endfor
End

/// UTF_TD_GENERATOR GetAnalysisFunctions
static Function CheckAbbrevName([string func])

	string abbrev

	abbrev = GetAbbreviationForAnalysisFunction(func)
	CHECK_PROPER_STR(func)
End

static Function [WAVE/T required, WAVE/T optional, WAVE/T mixed] GetAllAnalysisParameters_IGNORE(WAVE/T funcs)
	variable numFuncs

	numFuncs = DimSize(funcs, ROWS)
	CHECK_GT_VAR(numFuncs, 0)

	Make/N=(numFuncs)/FREE/WAVE requiredParams = ListToTextWave(AFH_GetListOfAnalysisParamNames(AFH_GetListOfAnalysisParams(funcs[p], REQUIRED_PARAMS)), ";")
	Make/N=(numFuncs)/FREE/WAVE optParams      = ListToTextWave(AFH_GetListOfAnalysisParamNames(AFH_GetListOfAnalysisParams(funcs[p], OPTIONAL_PARAMS)), ";")

	Concatenate/NP/FREE {requiredParams}, allRequiredParams
	Concatenate/NP/FREE {optParams}, allOptParams

	WAVE/Z allRequiredParamsUnique = GetUniqueEntries(allRequiredParams)
	CHECK_WAVE(allRequiredParamsUnique, TEXT_WAVE)

	WAVE/Z allOptParamsUnique = GetUniqueEntries(allOptParams)
	CHECK_WAVE(allOptParamsUnique, TEXT_WAVE)

	WAVE/Z mixedRequiredAndOptional = GetSetIntersection(allRequiredParamsUnique, allOptParamsUnique)
	CHECK_WAVE(mixedRequiredAndOptional, TEXT_WAVE)

	WAVE/T/Z allRequiredParamsUniqueNoMixed = GetSetDifference(allRequiredParamsUnique, mixedRequiredAndOptional)
	CHECK_WAVE(allRequiredParamsUniqueNoMixed, TEXT_WAVE)

	WAVE/T/Z allOptParamsUniqueNoMixed = GetSetDifference(allOptParamsUnique, mixedRequiredAndOptional)
	CHECK_WAVE(allOptParamsUniqueNoMixed, TEXT_WAVE)

	ChangeFreeWaveName(allRequiredParamsUniqueNoMixed, "required")
	ChangeFreeWaveName(allOptParamsUniqueNoMixed, "optional")
	ChangeFreeWaveName(mixedRequiredAndOptional, "mixed")

	return [allRequiredParamsUniqueNoMixed, allOptParamsUniqueNoMixed, mixedRequiredAndOptional]
End

static Function AnalysisParamsMustHaveSameOptionality()

	WAVE/T funcs = GetAnalysisFunctions()

	[WAVE/T required, WAVE/T optional, WAVE/T mixed] = GetAllAnalysisParameters_IGNORE(funcs)

	// these parameters are expected to have different optionality
	CHECK(!RemoveTextWaveEntry1D(mixed, "DAScaleModifier"))
	CHECK(!RemoveTextWaveEntry1D(mixed, "DAScaleOperator"))
	CHECK(!RemoveTextWaveEntry1D(mixed, "FailedLevel"))

	CHECK_EQUAL_VAR(DimSize(mixed, ROWS), 0)
End

static Function [WAVE/T matchingFunctions, string type, string help] GetAnalysisFunctionsForParameter_IGNORE(WAVE/T funcs, string name)

	string func, namesAndTypes, names, currentType, currentHelp
	variable idx

	type = ""
	help = ""

	Make/FREE/T/N=(DimSize(funcs, ROWS)) matchingFunctions

	for(func : funcs)
		namesAndTypes = AFH_GetListOfAnalysisParams(func, REQUIRED_PARAMS | OPTIONAL_PARAMS)
		names = AFH_GetListOfAnalysisParamNames(namesAndTypes)

		if(WhichListItem(name, names, ";", 0, 0) != -1)
			matchingFunctions[idx] = GetAbbreviationForAnalysisFunction(func)
			idx++

			currentHelp = AFH_GetHelpForAnalysisParameter(func, name)
			currentType = AFH_GetAnalysisParamType(name, namesAndTypes)

			if(IsEmpty(type))
				type = currentType
			else
				CHECK_EQUAL_STR(type, currentType)
			endif

			if(IsEmpty(help))
				help = currentHelp
			elseif(cmpstr(help, currentHelp))
				// if the help is different we concatenate it
				help += "\r" + currentHelp
			endif
		endif
	endfor

	if(!idx)
		FAIL()
	endif

	Redimension/N=(idx) matchingFunctions

	Sort matchingFunctions, matchingFunctions

	return [matchingFunctions, type, help]
End

static Function GenerateAnalysisFunctionTable()

	string type, param, help
	variable idx

	WAVE/T funcs = GetAnalysisFunctions()

	[WAVE/T required, WAVE/T optional, WAVE/T mixed] = GetAllAnalysisParameters_IGNORE(funcs)

	Make/FREE/WAVE all = {required, optional, mixed}

	Make/T/FREE/N=(MINIMUM_WAVE_SIZE, 5) output

	SetDimensionLabels(output, "Name;Type;Optionality;Used by;Help", COLS)

	for(WAVE/T wv : all)
		for(param : wv)
			[WAVE/T funcsWithParam, type, help] = GetAnalysisFunctionsForParameter_IGNORE(funcs, param)

			EnsureLargeEnoughWave(output, indexShouldExist = idx, dimension = ROWS)
			output[idx][%Name]        = param
			output[idx][%Type]        = type
			output[idx][%Optionality] = NameOfWave(wv)
			output[idx][%$"Used by"]  = RemoveEnding(TextWaveToList(funcsWithParam, ", "), ", ")
			output[idx][%Help]        = help
			idx++
		endfor
	endfor

	Redimension/N=(idx, -1) output

	SortColumns/KNDX={0} sortWaves=output

	// header
	InsertPoints/M=(ROWS) 0, 1, output
	output[0][] = GetDimLabel(output, COLS, q)

	// if this test fails and the CRC changes
	// commit the file `Packages/MIES/analysis_function_parameters.itx`
	// and check that the changes therein are intentional
	CHECK_EQUAL_VAR(WaveCRC(0, output, 0), 303837295)
	StoreWaveOnDisk(output, "analysis_function_parameters")
End

static Function GenerateAnalysisFunctionLegend()

	string func

	WAVE/T funcs = GetAnalysisFunctions()

	Make/FREE/T/N=(DimSize(funcs, ROWS), 2) output

	SetDimensionLabels(output, "Abbreviation;Name", COLS)

	output[][0] = GetAbbreviationForAnalysisFunction(funcs[p])
	output[][1] = ":cpp:func:`" + funcs[p] + "`"

	SortColumns/KNDX={0} sortWaves=output

	// header
	InsertPoints/M=(ROWS) 0, 1, output
	output[0][] = GetDimLabel(output, COLS, q)

	// if this test fails and the CRC changes
	// commit the file `Packages/MIES/analysis_function_abrev_legend.itx`
	// and check that the changes therein are intentional
	CHECK_EQUAL_VAR(WaveCRC(0, output, 0), 2579934075)
	StoreWaveOnDisk(output, "analysis_function_abrev_legend")
End
