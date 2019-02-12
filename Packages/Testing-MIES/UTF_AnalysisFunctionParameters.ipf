#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=AnalysisFuncParamTesting

static Function TEST_CASE_BEGIN_OVERRIDE(testCase)
	string testCase

	Initialize_IGNORE()
End

static Function AbortsWithEmptyName()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "", var = 123); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithInvalidName1()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "123", var = 123); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithInvalidName2()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "a b", var = 123); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithNoData()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "ab"); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithInvalidDataComb1()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "ab", var = 123, str = "hi there!"); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithInvalidDataComb2()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "ab", var = 123, wv = {1, 2}); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithInvalidDataComb3()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "ab", str = "hi there", wv = {1, 2}); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithInvalidDataComb4()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "ab", str = "hi there", wv = {1, 2}); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithInvalidContents()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		WBP_AddAnalysisParameter(stimSet, "ab", str = "; , = :"); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithInvalidWaveType()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		Make/WAVE wv
		WBP_AddAnalysisParameter(stimSet, "ab", wv = wv); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End

static Function AbortsWithEmptyWave()

	string params
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	try
		Make/N=0 wv
		WBP_AddAnalysisParameter(stimSet, "ab", wv = wv); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)
End


static Function AbortsWithInvalidTextWaveCont()

	string params, names, refNames, name, type, refType
	string refName
	string refString, val
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	Make/T/FREE refData = {"1", "2", "3", "|"}
	refName   = "abcd"

	try

		WBP_AddAnalysisParameter(stimSet, refName, wv = refData); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

static Function WorksWithVariable()

	string params, names, refNames, name, type, refType
	string refName
	variable refValue, val
	string stimSet = "AnaFuncParams1_DA_0"

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	CHECK_WAVE(WPT, TEXT_WAVE)

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	refValue = 123
	refName  = "ab"

	WBP_AddAnalysisParameter(stimSet, refName, var = refValue)
	params = WPT[10][%Set][INDEP_EPOCH_TYPE]

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

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	refString = "hi there"
	refName   = "abc"

	WBP_AddAnalysisParameter(stimSet, refName, str = refString)
	params = WPT[10][%Set][INDEP_EPOCH_TYPE]

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

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	Make/D/FREE refData = {1, 2, 3, 4}
	refName   = "abcde"

	WBP_AddAnalysisParameter(stimSet, refName, wv = refData)
	params = WPT[10][%Set][INDEP_EPOCH_TYPE]

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

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	Make/T/FREE refData = {"1", "2", "3", "hi there"}
	refName   = "abcdef"

	WBP_AddAnalysisParameter(stimSet, refName, wv = refData)
	params = WPT[10][%Set][INDEP_EPOCH_TYPE]

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

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	WBP_AddAnalysisParameter(stimSet, "a1", str = "a1")
	WBP_AddAnalysisParameter(stimSet, "a2", str = "a2")
	WBP_AddAnalysisParameter(stimSet, "a1", str = "a11")

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]

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

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]
	CHECK_EMPTY_STR(params)

	CHECK_WAVE(AFH_GetAnalysisParamWave("I_DONT_EXIST", params), NULL_WAVE)
	CHECK_WAVE(AFH_GetAnalysisParamTextWave("I_DONT_EXIST", params), NULL_WAVE)
End
